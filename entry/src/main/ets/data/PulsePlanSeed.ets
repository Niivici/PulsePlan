import {
  BOARD_END_MINUTE,
  BOARD_START_MINUTE,
  PulsePalette,
  SNAP_MINUTES
} from '../common/PulsePlanTheme';
import {
  EventBlock,
  GeneratedPlan,
  ReminderItem,
  ScheduleItem
} from '../common/PulsePlanModels';
import {
  addDays,
  clampMinute,
  getDateKey,
  getWeekStart,
  sortSchedules
} from '../common/PulsePlanUtils';

function nextId(): number {
  return Number(`${Date.now()}${Math.floor(Math.random() * 100)}`);
}

function findEventColor(eventBlocks: EventBlock[], eventBlockId: number): string {
  const matched: EventBlock | undefined = eventBlocks.find((item: EventBlock) => item.id === eventBlockId);
  return matched ? matched.color : PulsePalette.accentBlue;
}

function findFirstAvailableStart(dayKey: string, scheduleItems: ScheduleItem[], duration: number): number {
  const dayItems: ScheduleItem[] = sortSchedules(scheduleItems.filter((item: ScheduleItem) => item.dayKey === dayKey));
  let cursor: number = BOARD_START_MINUTE;
  for (let index: number = 0; index < dayItems.length; index++) {
    const current: ScheduleItem = dayItems[index];
    if (current.startMinute - cursor >= duration + SNAP_MINUTES) {
      return cursor;
    }
    cursor = Math.max(cursor, current.endMinute + SNAP_MINUTES);
  }
  return clampMinute(cursor, BOARD_START_MINUTE, BOARD_END_MINUTE - duration - SNAP_MINUTES);
}

export function createSeedEventBlocks(): EventBlock[] {
  return [
    {
      id: 101,
      title: '季度汇报冲刺',
      scene: '工作',
      preference: '先收敛结论，再补材料细节',
      habitHint: '上午更适合做高密度输出任务',
      aiHint: '根据你近期的会议表现，建议演练与材料拆分执行。',
      color: PulsePalette.accentBlue,
      quickLaunch: '打开汇报文档'
    },
    {
      id: 102,
      title: '考研数学周推进',
      scene: '学习',
      preference: '90 分钟深度专注 + 错题复盘',
      habitHint: '晚间 19:00 后最适合沉浸学习',
      aiHint: '系统将自动预留 20 分钟错题整理和情绪回落时间。',
      color: PulsePalette.accentLeaf,
      quickLaunch: '打开刷题平台'
    },
    {
      id: 103,
      title: '晚间运动与恢复',
      scene: '生活',
      preference: '轻计划 + 强反馈',
      habitHint: '运动结束后更愿意记录生活感受',
      aiHint: '手表数据会反向影响第二天的体能型任务排布。',
      color: PulsePalette.accentCoral,
      quickLaunch: '打开运动记录'
    },
    {
      id: 104,
      title: '周末生活记录',
      scene: '记录',
      preference: '短时高频记录，不打断主流程',
      habitHint: '适合在晚上做 10 分钟回顾',
      aiHint: '推荐把生活片段与成就反馈绑定，提升连续记录率。',
      color: PulsePalette.accentGold,
      quickLaunch: '打开生活日志'
    }
  ];
}

export function createSeedSchedules(eventBlocks: EventBlock[]): ScheduleItem[] {
  const weekStart: string = getWeekStart(getDateKey(new Date()));
  return sortSchedules([
    {
      id: 201,
      eventBlockId: 101,
      title: '汇报素材收束',
      scene: '工作',
      dayKey: addDays(weekStart, 0),
      startMinute: 9 * 60,
      endMinute: 10 * 60 + 10,
      color: findEventColor(eventBlocks, 101),
      modeName: '写作模式',
      quickLaunch: '打开汇报文档',
      aiSuggestion: '先整理业务线结论，再补数字证据，避免陷入细节。',
      flexibility: '刚性',
      completed: true
    },
    {
      id: 202,
      eventBlockId: 102,
      title: '数学题型扫描',
      scene: '学习',
      dayKey: addDays(weekStart, 1),
      startMinute: 19 * 60,
      endMinute: 20 * 60,
      color: findEventColor(eventBlocks, 102),
      modeName: '学习模式',
      quickLaunch: '打开刷题平台',
      aiSuggestion: '先做知识扫描，再决定是否进入长时间专注块。',
      flexibility: '弹性',
      completed: false
    },
    {
      id: 203,
      eventBlockId: 101,
      title: '汇报结构重排',
      scene: '工作',
      dayKey: addDays(weekStart, 2),
      startMinute: 14 * 60,
      endMinute: 15 * 60 + 20,
      color: findEventColor(eventBlocks, 101),
      modeName: '会议模式',
      quickLaunch: '打开重点看板',
      aiSuggestion: '把高层问题预先转成三张备用页，减少临场压力。',
      flexibility: '弹性',
      completed: false
    },
    {
      id: 204,
      eventBlockId: 102,
      title: '数学深度专注',
      scene: '学习',
      dayKey: addDays(weekStart, 4),
      startMinute: 19 * 60,
      endMinute: 20 * 60 + 30,
      color: findEventColor(eventBlocks, 102),
      modeName: '学习模式',
      quickLaunch: '打开刷题平台',
      aiSuggestion: '40 分钟限时训练后，马上整理错题触发条件。',
      flexibility: '刚性',
      completed: false
    },
    {
      id: 205,
      eventBlockId: 103,
      title: '晚间跑步',
      scene: '生活',
      dayKey: addDays(weekStart, 5),
      startMinute: 18 * 60 + 30,
      endMinute: 19 * 60 + 20,
      color: findEventColor(eventBlocks, 103),
      modeName: '专注模式',
      quickLaunch: '打开运动记录',
      aiSuggestion: '跑后 15 分钟内补水并同步心率，便于恢复模型学习。',
      flexibility: '宽松',
      completed: false
    },
    {
      id: 206,
      eventBlockId: 104,
      title: '周末复盘记录',
      scene: '记录',
      dayKey: addDays(weekStart, 6),
      startMinute: 21 * 60,
      endMinute: 21 * 60 + 30,
      color: findEventColor(eventBlocks, 104),
      modeName: '记录模式',
      quickLaunch: '打开生活日志',
      aiSuggestion: '用三句结构记录：成就、波动、明日启动动作。',
      flexibility: '宽松',
      completed: false
    }
  ]);
}

export function createSeedReminders(scheduleItems: ScheduleItem[]): ReminderItem[] {
  return [
    {
      id: 301,
      scheduleItemId: 201,
      title: '开始前 15 分钟确认汇报资料是否齐全',
      dayKey: scheduleItems[0].dayKey,
      minute: scheduleItems[0].startMinute - 15,
      intensity: '高提醒'
    },
    {
      id: 302,
      scheduleItemId: 204,
      title: '学习模式会在开始前 10 分钟预热',
      dayKey: scheduleItems[3].dayKey,
      minute: scheduleItems[3].startMinute - 10,
      intensity: '中提醒'
    },
    {
      id: 303,
      scheduleItemId: 205,
      title: '运动结束后补水并同步手表数据',
      dayKey: scheduleItems[4].dayKey,
      minute: scheduleItems[4].endMinute + 10,
      intensity: '高提醒'
    }
  ];
}

export function createPlanFromPrompt(prompt: string, dateKey: string, scheduleItems: ScheduleItem[]): GeneratedPlan {
  const normalizedPrompt: string = prompt.trim();
  const lowerPrompt: string = normalizedPrompt.toLowerCase();
  let scene: string = '生活';
  let color: string = PulsePalette.accentCoral;
  let modeName: string = '专注模式';
  let quickLaunch: string = '打开生活日志';
  let aiHint: string = '系统会按任务量拆成可执行的短块，并给你留出缓冲。';
  let titles: string[] = ['目标澄清', '核心执行', '复盘记录'];
  let durations: number[] = [30, 70, 20];

  if (lowerPrompt.includes('报告') || lowerPrompt.includes('会议') || lowerPrompt.includes('汇报')) {
    scene = '工作';
    color = PulsePalette.accentBlue;
    modeName = '会议模式';
    quickLaunch = '打开汇报文档';
    aiHint = '系统会先按材料、逻辑和演练三段拆分，再插入回顾提醒。';
    titles = ['材料整理', '逻辑搭建', '会前演练'];
    durations = [45, 70, 30];
  } else if (lowerPrompt.includes('学习') || lowerPrompt.includes('复习') || lowerPrompt.includes('考试') ||
  lowerPrompt.includes('题')) {
    scene = '学习';
    color = PulsePalette.accentLeaf;
    modeName = '学习模式';
    quickLaunch = '打开刷题平台';
    aiHint = '系统会按知识扫描、主攻和错题复盘自动安排。';
    titles = ['知识扫描', '深度专注', '错题回收'];
    durations = [25, 90, 30];
  } else if (lowerPrompt.includes('运动') || lowerPrompt.includes('跑步') || lowerPrompt.includes('锻炼')) {
    scene = '生活';
    color = PulsePalette.accentCoral;
    modeName = '运动模式';
    quickLaunch = '打开运动记录';
    aiHint = '系统会补齐热身和恢复记录时间，避免计划只剩主体动作。';
    titles = ['热身准备', '主体运动', '恢复记录'];
    durations = [15, 45, 15];
  }

  const eventBlockId: number = nextId();
  const eventBlock: EventBlock = {
    id: eventBlockId,
    title: normalizedPrompt,
    scene: scene,
    preference: scene === '学习' ? '深度专注 + 复盘串联' :
      scene === '工作' ? '结构先行 + 会前演练' : '轻量开始 + 稳定反馈',
    habitHint: scene === '学习' ? '晚间可拉长专注窗口' :
      scene === '工作' ? '上午适合输出型任务' : '低压时段更易持续执行',
    aiHint: aiHint,
    color: color,
    quickLaunch: quickLaunch
  };

  const scheduleList: ScheduleItem[] = [];
  const reminderList: ReminderItem[] = [];
  let anchorMinute: number =
    findFirstAvailableStart(dateKey, scheduleItems, durations[0] + durations[1] + durations[2] + 20);
  for (let index: number = 0; index < titles.length; index++) {
    const duration: number = durations[index];
    const startMinute: number = clampMinute(anchorMinute, BOARD_START_MINUTE, BOARD_END_MINUTE - duration);
    const endMinute: number = startMinute + duration;
    const scheduleId: number = nextId();
    scheduleList.push({
      id: scheduleId,
      eventBlockId: eventBlockId,
      title: `${titles[index]} · ${normalizedPrompt}`,
      scene: scene,
      dayKey: dateKey,
      startMinute: startMinute,
      endMinute: endMinute,
      color: color,
      modeName: modeName,
      quickLaunch: quickLaunch,
      aiSuggestion: index === 0 ? '先明确边界和完成标准，后续排程会更稳定。'
        : index === 1 ? '这是主执行块，建议直接切入对应场景模式。'
          : '结束后立刻记录阻塞点，方便模型学习下次排法。',
      flexibility: index === 1 ? '刚性' : '弹性',
      completed: false
    });
    reminderList.push({
      id: nextId(),
      scheduleItemId: scheduleId,
      title: `${titles[index]} 即将开始`,
      dayKey: dateKey,
      minute: clampMinute(startMinute - 10, BOARD_START_MINUTE, BOARD_END_MINUTE),
      intensity: index === 1 ? '中提醒' : '高提醒'
    });
    anchorMinute = endMinute + 10;
  }

  return {
    eventBlock: eventBlock,
    scheduleItems: scheduleList,
    reminders: reminderList,
    bufferMinutes: 20
  };
}

export function rebalanceDaySchedules(scheduleItems: ScheduleItem[], dayKey: string): ScheduleItem[] {
  const items: ScheduleItem[] = sortSchedules(scheduleItems);
  const result: ScheduleItem[] = [];
  const dayItems: ScheduleItem[] = sortSchedules(items.filter((item: ScheduleItem) => item.dayKey === dayKey));
  const otherItems: ScheduleItem[] = items.filter((item: ScheduleItem) => item.dayKey !== dayKey);
  let cursor: number = BOARD_START_MINUTE;
  for (let index: number = 0; index < dayItems.length; index++) {
    const current: ScheduleItem = dayItems[index];
    const duration: number = current.endMinute - current.startMinute;
    const startMinute: number = clampMinute(Math.max(cursor, current.startMinute), BOARD_START_MINUTE,
      BOARD_END_MINUTE - duration);
    const endMinute: number = startMinute + duration;
    result.push({
      id: current.id,
      eventBlockId: current.eventBlockId,
      title: current.title,
      scene: current.scene,
      dayKey: current.dayKey,
      startMinute: startMinute,
      endMinute: endMinute,
      color: current.color,
      modeName: current.modeName,
      quickLaunch: current.quickLaunch,
      aiSuggestion: current.aiSuggestion,
      flexibility: current.flexibility,
      completed: current.completed
    });
    cursor = endMinute + 10;
  }
  return sortSchedules([...otherItems, ...result]);
}
