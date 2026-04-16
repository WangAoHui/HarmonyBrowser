import { webview } from '@kit.ArkWeb';
import { Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// ============================================================
// Cookie 管理器 — 封装 web_webview Cookie 操作
// ============================================================
export class CookieManager {
  private static instance: CookieManager;
  private cookieMgr: webview.WebCookieManager | null = null;

  static getInstance(): CookieManager {
    if (!CookieManager.instance) {
      CookieManager.instance = new CookieManager();
    }
    return CookieManager.instance;
  }

  init(): void {
    this.cookieMgr = webview.WebCookieManager.getInstance();
  }

  // 获取某 URL 的 Cookie
  getCookies(url: string): string {
    if (!this.cookieMgr) this.init();
    return this.cookieMgr!.getCookie(url) ?? '';
  }

  // 设置 Cookie
  setCookie(url: string, value: string): void {
    if (!this.cookieMgr) this.init();
    this.cookieMgr!.setCookie(url, value);
  }

  // 清除所有 Cookie
  clearAllCookies(): void {
    if (!this.cookieMgr) this.init();
    this.cookieMgr!.deleteEntireCookie();
    console.info('[CookieManager] All cookies cleared');
  }

  // 清除某个 URL 的 Cookie
  clearCookiesForUrl(url: string): void {
    if (!this.cookieMgr) this.init();
    // 返回某 url 关联的 cookie 是否被删除
    this.cookieMgr!.deleteEntireCookie();
  }

  // 保存 Cookie（flush 到磁盘）
  saveCookies(): void {
    if (!this.cookieMgr) this.init();
    this.cookieMgr!.saveCookieAsync();
  }
}

// ============================================================
// Web 数据清除工具
// ============================================================
export class WebDataCleaner {
  // 清除 Web 组件的缓存
  static clearCache(controller: webview.WebviewController): void {
    try {
      controller.clearCache();
      console.info('[WebDataCleaner] Cache cleared');
    } catch (err) {
      const e = err as BusinessError;
      console.error(`[WebDataCleaner] clearCache error: ${e.code} - ${e.message}`);
    }
  }

  // 清除 Web 组件的历史记录（导航记录）
  static clearHistory(controller: webview.WebviewController): void {
    try {
      controller.clearHistory();
      console.info('[WebDataCleaner] History cleared');
    } catch (err) {
      const e = err as BusinessError;
      console.error(`[WebDataCleaner] clearHistory error: ${e.code} - ${e.message}`);
    }
  }
}
