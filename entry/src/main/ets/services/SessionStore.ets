import { util } from '@kit.ArkTS';
import { asset } from '@kit.AssetStoreKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface StoredSession {
  base: string;
  token: string;
}

export class SessionStore {
  private static alias(): asset.AssetMap {
    const tags: asset.AssetMap = new Map();
    tags.set(asset.Tag.ALIAS, new util.TextEncoder().encodeInto('pulseplan-session-v1'));
    return tags;
  }

  static async read(): Promise<StoredSession | undefined> {
    const tags = SessionStore.alias();
    tags.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    try {
      const rows = await asset.query(tags);
      if (rows.length === 0) {
        return undefined;
      }
      const secret = rows[0].get(asset.Tag.SECRET) as Uint8Array;
      return JSON.parse(util.TextDecoder.create('utf-8').decodeToString(secret)) as StoredSession;
    } catch (error) {
      if ((error as BusinessError).code === asset.ErrorCode.NOT_FOUND) {
        return undefined;
      }
      throw error as Error;
    }
  }

  static async save(session: StoredSession): Promise<void> {
    const tags = SessionStore.alias();
    tags.set(asset.Tag.SECRET, new util.TextEncoder().encodeInto(JSON.stringify(session)));
    tags.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_UNLOCKED);
    tags.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
    await asset.add(tags);
  }

  static async clear(): Promise<void> {
    try {
      await asset.remove(SessionStore.alias());
    } catch (error) {
      if ((error as BusinessError).code !== asset.ErrorCode.NOT_FOUND) {
        throw error as Error;
      }
    }
  }
}
