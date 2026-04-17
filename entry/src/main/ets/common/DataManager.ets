import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import {
  BookmarkItem, HistoryItem, SearchEngine, SEARCH_ENGINES,
  TabItem, ThemeConfig, ThemeMode, THEME_PRESETS,
  PasswordItem, AdBlockRule, BUILT_IN_AD_RULES
} from '../model/BrowserData';

const PREFS_NAME = 'browser_data';
const KEY_BOOKMARKS = 'bookmarks';
const KEY_HISTORY = 'history';
const KEY_SEARCH_ENGINE = 'search_engine';
const KEY_TABS = 'tabs';
const KEY_ACTIVE_TAB = 'active_tab';
const KEY_THEME = 'theme';
const KEY_PASSWORDS = 'passwords';
const KEY_ADBLOCK_ENABLED = 'adblock_enabled';
const KEY_ADBLOCK_RULES = 'adblock_rules';
const KEY_AUTOFILL_ENABLED = 'autofill_enabled';

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
    const existing = list.find(h => h.url === url);
    if (existing) {
      existing.visitTime = Date.now();
      existing.visitCount += 1;
      existing.title = title || existing.title;
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

  // ======================== 搜索引擎 ========================

  async getSearchEngine(): Promise<SearchEngine> {
    const id = await this.prefs?.get(KEY_SEARCH_ENGINE, 'bing') as string;
    return SEARCH_ENGINES.find(e => e.id === id) || SEARCH_ENGINES[0];
  }

  async setSearchEngine(engineId: string): Promise<void> {
    await this.prefs?.put(KEY_SEARCH_ENGINE, engineId);
    await this.prefs?.flush();
  }

  async buildSearchUrl(query: string): Promise<string> {
    const engine = await this.getSearchEngine();
    return engine.searchUrl.replace('{query}', encodeURIComponent(query));
  }

  async getSearchEngineHomeUrl(): Promise<string> {
    const engine = await this.getSearchEngine();
    return engine.homeUrl;
  }

  // ======================== 标签页管理 ========================

  async getTabs(): Promise<TabItem[]> {
    const raw = await this.prefs?.get(KEY_TABS, '[]') as string;
    return JSON.parse(raw) as TabItem[];
  }

  async saveTabs(tabs: TabItem[]): Promise<void> {
    await this.prefs?.put(KEY_TABS, JSON.stringify(tabs));
    await this.prefs?.flush();
  }

  async getActiveTabId(): Promise<string> {
    return await this.prefs?.get(KEY_ACTIVE_TAB, '') as string;
  }

  async setActiveTabId(tabId: string): Promise<void> {
    await this.prefs?.put(KEY_ACTIVE_TAB, tabId);
    await this.prefs?.flush();
  }

  async addTab(url: string, title: string): Promise<TabItem> {
    const tabs = await this.getTabs();
    // 将所有标签设为非活跃
    tabs.forEach(t => t.isActive = false);
    const tab: TabItem = {
      id: generateId(),
      url,
      title: title || '新标签页',
      isActive: true,
      createdAt: Date.now(),
    };
    tabs.push(tab);
    await this.saveTabs(tabs);
    await this.setActiveTabId(tab.id);
    return tab;
  }

  async removeTab(tabId: string): Promise<TabItem | null> {
    const tabs = await this.getTabs();
    if (tabs.length <= 1) return tabs[0]; // 至少保留一个标签
    const idx = tabs.findIndex(t => t.id === tabId);
    if (idx === -1) return tabs[0];
    tabs.splice(idx, 1);
    // 如果关闭的是当前标签，激活相邻标签
    let activeTab = tabs.find(t => t.isActive);
    if (!activeTab) {
      const nextIdx = Math.min(idx, tabs.length - 1);
      tabs[nextIdx].isActive = true;
      activeTab = tabs[nextIdx];
    }
    await this.saveTabs(tabs);
    await this.setActiveTabId(activeTab!.id);
    return activeTab!;
  }

  async updateTab(tabId: string, updates: Partial<TabItem>): Promise<void> {
    const tabs = await this.getTabs();
    const tab = tabs.find(t => t.id === tabId);
    if (tab) {
      Object.assign(tab, updates);
      await this.saveTabs(tabs);
    }
  }

  async switchTab(tabId: string): Promise<TabItem | null> {
    const tabs = await this.getTabs();
    tabs.forEach(t => t.isActive = (t.id === tabId));
    await this.saveTabs(tabs);
    await this.setActiveTabId(tabId);
    return tabs.find(t => t.id === tabId) || null;
  }

  async clearAllTabs(): Promise<TabItem> {
    const newTab: TabItem = {
      id: generateId(),
      url: '',
      title: '新标签页',
      isActive: true,
      createdAt: Date.now(),
    };
    await this.saveTabs([newTab]);
    await this.setActiveTabId(newTab.id);
    return newTab;
  }

  // ======================== 主题/夜间模式 ========================

  async getTheme(): Promise<ThemeConfig> {
    const themeName = await this.prefs?.get(KEY_THEME, 'light') as string;
    return THEME_PRESETS[themeName] || THEME_PRESETS['light'];
  }

  async setTheme(themeName: string): Promise<void> {
    await this.prefs?.put(KEY_THEME, themeName);
    await this.prefs?.flush();
  }

  async getThemeName(): Promise<string> {
    return await this.prefs?.get(KEY_THEME, 'light') as string;
  }

  // ======================== 密码管理 ========================

  async getPasswords(): Promise<PasswordItem[]> {
    const raw = await this.prefs?.get(KEY_PASSWORDS, '[]') as string;
    return JSON.parse(raw) as PasswordItem[];
  }

  async savePassword(url: string, title: string, username: string, password: string): Promise<PasswordItem> {
    const list = await this.getPasswords();
    // 检查是否已存在该网站的密码
    const domain = this.extractDomain(url);
    const existing = list.find(p => this.extractDomain(p.url) === domain && p.username === username);

    if (existing) {
      existing.password = password;
      existing.updatedAt = Date.now();
      existing.title = title || existing.title;
      await this.prefs?.put(KEY_PASSWORDS, JSON.stringify(list));
      await this.prefs?.flush();
      return existing;
    }

    const item: PasswordItem = {
      id: generateId(),
      url,
      username,
      password,
      title: title || domain,
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };
    list.push(item);
    await this.prefs?.put(KEY_PASSWORDS, JSON.stringify(list));
    await this.prefs?.flush();
    return item;
  }

  async removePassword(id: string): Promise<void> {
    const list = await this.getPasswords();
    const filtered = list.filter(p => p.id !== id);
    await this.prefs?.put(KEY_PASSWORDS, JSON.stringify(filtered));
    await this.prefs?.flush();
  }

  async getPasswordForUrl(url: string): Promise<PasswordItem | null> {
    const list = await this.getPasswords();
    const domain = this.extractDomain(url);
    return list.find(p => this.extractDomain(p.url) === domain) || null;
  }

  async isAutoFillEnabled(): Promise<boolean> {
    return await this.prefs?.get(KEY_AUTOFILL_ENABLED, true) as boolean;
  }

  async setAutoFillEnabled(enabled: boolean): Promise<void> {
    await this.prefs?.put(KEY_AUTOFILL_ENABLED, enabled);
    await this.prefs?.flush();
  }

  private extractDomain(url: string): string {
    try {
      const u = url.startsWith('http') ? url : 'https://' + url;
      const match = u.match(/https?:\/\/([^/]+)/);
      return match ? match[1] : url;
    } catch {
      return url;
    }
  }

  // ======================== 广告拦截 ========================

  async isAdBlockEnabled(): Promise<boolean> {
    return await this.prefs?.get(KEY_ADBLOCK_ENABLED, true) as boolean;
  }

  async setAdBlockEnabled(enabled: boolean): Promise<void> {
    await this.prefs?.put(KEY_ADBLOCK_ENABLED, enabled);
    await this.prefs?.flush();
  }

  async getAdBlockRules(): Promise<AdBlockRule[]> {
    // 合并内置规则和用户自定义规则
    const raw = await this.prefs?.get(KEY_ADBLOCK_RULES, '[]') as string;
    const customRules = JSON.parse(raw) as AdBlockRule[];
    // 更新内置规则的 enabled 状态
    return [...BUILT_IN_AD_RULES, ...customRules];
  }

  async toggleAdBlockRule(ruleId: string): Promise<void> {
    const rules = await this.getAdBlockRules();
    const rule = rules.find(r => r.id === ruleId);
    if (rule) {
      rule.enabled = !rule.enabled;
    }
    // 只保存非内置规则和内置规则的状态覆盖
    const customRules = rules.filter(r => !r.isBuiltIn);
    await this.prefs?.put(KEY_ADBLOCK_RULES, JSON.stringify(customRules));
    await this.prefs?.flush();
  }

  // 检查 URL 是否应被拦截
  shouldBlockUrl(url: string, rules: AdBlockRule[]): boolean {
    for (const rule of rules) {
      if (!rule.enabled) continue;
      if (this.matchPattern(url, rule.pattern)) {
        return true;
      }
    }
    return false;
  }

  private matchPattern(url: string, pattern: string): boolean {
    // 将通配符模式转换为正则
    const regexStr = pattern
      .replace(/[.+^${}()|[\]\\]/g, '\\$&')
      .replace(/\*/g, '.*')
      .replace(/\?/g, '.');
    try {
      const regex = new RegExp(regexStr, 'i');
      return regex.test(url);
    } catch {
      return false;
    }
  }
}
