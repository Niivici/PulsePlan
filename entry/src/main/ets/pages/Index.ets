import { SessionStore } from '../services/SessionStore';
import { PulsePlanHome } from '../prototype/PulsePlanHome';
import { Credentials, PulsePlanApi, SessionExpiredError } from '../services/PulsePlanApi';
import { PulsePalette } from '../common/PulsePlanTheme';

@Entry
@Component
struct Index {
  @State serverAddress: string = '';
  @State username: string = '';
  @State password: string = '';
  @State connected: boolean = false;
  @State demo: boolean = false;
  @State busy: boolean = false;
  @State message: string = '';
  private api: PulsePlanApi = new PulsePlanApi('');

  aboutToAppear(): void {
    this.restoreSession();
  }

  private async restoreSession(): Promise<void> {
    this.busy = true;
    try {
      const stored = await SessionStore.read();
      if (!stored) {
        return;
      }
      this.serverAddress = stored.base;
      const api = new PulsePlanApi(stored.base, stored.token);
      const profile = await api.profile();
      this.username = profile.username;
      this.api = api;
      this.connected = true;
    } catch (error) {
      if (error instanceof SessionExpiredError) {
        await this.clearSession();
      } else {
        this.message = '无法恢复登录，请检查服务地址后重新登录。';
      }
    } finally {
      this.busy = false;
    }
  }

  private async clearSession(): Promise<void> {
    try {
      await SessionStore.clear();
    } catch (error) {
      this.message = '无法清理本机登录记录。';
    } finally {
      this.connected = false;
    }
  }

  private async signIn(register: boolean): Promise<void> {
    if (this.busy) {
      return;
    }
    const address = this.serverAddress.trim();
    if (!/^https?:\/\/[^\s/?#@]+\/?$/i.test(address)) {
      this.message = '请输入完整的服务地址，例如 http://192.168.1.10:8080。';
      return;
    }
    this.busy = true;
    this.message = '';
    const api = new PulsePlanApi(address);
    const credentials: Credentials = { username: this.username, password: this.password };
    try {
      if (register) {
        await api.register(credentials);
      }
      const session = await api.login(credentials);
      try {
        await SessionStore.save({ base: address, token: session.token });
      } catch (error) {
        this.message = '本机无法保存登录记录，重启后需重新登录。';
      }
      this.api = api;
      this.password = '';
      this.connected = true;
    } catch (error) {
      this.message = (error as Error).message;
    } finally {
      this.busy = false;
    }
  }

  build() {
    Column() {
      if (this.connected) {
        PulsePlanHome({
          api: this.api,
          onExit: () => {
            this.clearSession();
          }
        })
      } else if (this.demo) {
        PulsePlanHome({
          onExit: () => {
            this.demo = false;
          }
        })
      } else {
        Column({ space: 14 }) {
          Text('PulsePlan')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('登录日程助手')
            .fontSize(18)
            .fontColor(Color.White)
          TextInput({ placeholder: '后端服务地址', text: this.serverAddress })
            .backgroundColor(PulsePalette.surfaceRaised)
            .fontColor(PulsePalette.textPrimary)
            .placeholderColor(PulsePalette.textSecondary)
            .caretColor(PulsePalette.accentSky)
            .border({ width: 1, color: PulsePalette.borderStrong })
            .onChange((value: string) => { this.serverAddress = value; })
          TextInput({ placeholder: '用户名', text: this.username })
            .backgroundColor(PulsePalette.surfaceRaised)
            .fontColor(PulsePalette.textPrimary)
            .placeholderColor(PulsePalette.textSecondary)
            .caretColor(PulsePalette.accentSky)
            .border({ width: 1, color: PulsePalette.borderStrong })
            .onChange((value: string) => { this.username = value; })
          TextInput({ placeholder: '密码', text: this.password })
            .backgroundColor(PulsePalette.surfaceRaised)
            .fontColor(PulsePalette.textPrimary)
            .placeholderColor(PulsePalette.textSecondary)
            .caretColor(PulsePalette.accentSky)
            .border({ width: 1, color: PulsePalette.borderStrong })
            .type(InputType.Password)
            .onChange((value: string) => { this.password = value; })
          if (this.message.length > 0) {
            Text(this.message).fontColor(Color.White)
          }
          Row({ space: 12 }) {
            Button('登录').enabled(!this.busy).onClick(() => { this.signIn(false); })
            Button('注册并登录').enabled(!this.busy).onClick(() => { this.signIn(true); })
          }
          Button('体验本地演示').enabled(!this.busy).onClick(() => { this.demo = true; })
        }
        .width('100%')
        .padding(24)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(this.connected || this.demo ? FlexAlign.Start : FlexAlign.Center)
    .backgroundColor(PulsePalette.background)
  }
}
