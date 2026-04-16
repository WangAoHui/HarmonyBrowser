import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { BookmarkItem, HistoryItem } from '../model/BrowserData';

const PREFS_NAME = 'browser_data';
const KEY_BOOKMARKS = 'bookmarks';
const KEY_HISTORY = 'history';

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
}

// ============================================================
// 数据管理器 — 使用用户首选项（Preferences）持久化
// ============================================================
export class DataManager {
  private prefs: preferences.Preferences | null = null;
  private static instance: DataManager;

  static getInstance(): DataManager {
    if (!DataManager.instance) {
      DataManager.instance = new DataManager();
    }
    return DataManager.instance;
  }

  // 初始化，在 EntryAbility.onCreate 或页面 aboutToAppear 中调用
  async init(context: Context): Promise<void> {
    if (this.prefs) return;
    this.prefs = await preferences.getPreferences(context, PREFS_NAME);
  }

  // ======================== 书签 ========================

  async getBookmarks(): Promise<BookmarkItem[]> {
    const raw = await this.prefs?.get(KEY_BOOKMARKS, '[]') as string;
    return JSON.parse(raw) as BookmarkItem[];
  }

  async addBookmark(title: string, url: string): Promise<BookmarkItem> {
    const list = await this.getBookmarks();
    const item: BookmarkItem = {
      id: generateId(),
      title,
      url,
      createdAt: Date.now(),
    };
    list.unshift(item);
    await this.prefs?.put(KEY_BOOKMARKS, JSON.stringify(list));
    await this.prefs?.flush();
    return item;
  }

  async removeBookmark(id: string): Promise<void> {
    const list = await this.getBookmarks();
    const filtered = list.filter(b => b.id !== id);
    await this.prefs?.put(KEY_BOOKMARKS, JSON.stringify(filtered));
    await this.prefs?.flush();
  }

  async isBookmarked(url: string): Promise<boolean> {
    const list = await this.getBookmarks();
    return list.some(b => b.url === url);
  }

  // ======================== 历史记录 ========================

  async getHistory(): Promise<HistoryItem[]> {
    const raw = await this.prefs?.get(KEY_HISTORY, '[]') as string;
    return JSON.parse(raw) as HistoryItem[];
  }

  async addHistory(title: string, url: string): Promise<void> {
    const list = await this.getHistory();
    // 如果同一 URL 已存在，更新访问次数和时间
    const existing = list.find(h => h.url === url);
    if (existing) {
      existing.visitTime = Date.now();
      existing.visitCount += 1;
      existing.title = title || existing.title;
      // 移到最前面
      const idx = list.indexOf(existing);
      list.splice(idx, 1);
      list.unshift(existing);
    } else {
      const item: HistoryItem = {
        id: generateId(),
        title,
        url,
        visitTime: Date.now(),
        visitCount: 1,
      };
      list.unshift(item);
    }
    // 最多保留 500 条
    if (list.length > 500) list.length = 500;
    await this.prefs?.put(KEY_HISTORY, JSON.stringify(list));
    await this.prefs?.flush();
  }

  async removeHistory(id: string): Promise<void> {
    const list = await this.getHistory();
    const filtered = list.filter(h => h.id !== id);
    await this.prefs?.put(KEY_HISTORY, JSON.stringify(filtered));
    await this.prefs?.flush();
  }

  async clearAllHistory(): Promise<void> {
    await this.prefs?.put(KEY_HISTORY, '[]');
    await this.prefs?.flush();
  }

  // ======================== 清除数据 ========================

  async clearAllData(): Promise<void> {
    await this.prefs?.clear();
    await this.prefs?.flush();
  }
}
