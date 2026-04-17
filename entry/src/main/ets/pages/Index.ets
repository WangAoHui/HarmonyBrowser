import { webview } from '@kit.ArkWeb';
import { router } from '@kit.ArkUI';
import { DataManager } from '../common/DataManager';
import { CookieManager } from '../common/CookieManager';
import {
  SearchEngine, SEARCH_ENGINES,
  TabItem, ThemeConfig, THEME_PRESETS,
  PasswordItem, AdBlockRule
} from '../model/BrowserData';

@Entry
@Component
struct Index {
  // Web 控制器
  controller: webview.WebviewController = new webview.WebviewController();
  // 数据管理
  private dataManager: DataManager = DataManager.getInstance();
  // URL 输入
  @State homeUrl: string = 'https://www.bing.com';
  @State urlInput: string = '';
  @State currentUrl: string = '';
  @State pageTitle: string = '首页';
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State isBookmarked: boolean = false;
  // 当前搜索引擎
  @State currentSearchEngine: SearchEngine = SEARCH_ENGINES[0];
  // 底部菜单
  @State showMenu: boolean = false;
  // 是否编辑模式
  @State isUrlFocused: boolean = false;

  // ====== 新功能状态 ======
  // 标签页
  @State tabs: TabItem[] = [];
  @State activeTabId: string = '';
  @State showTabOverview: boolean = false;

  // 主题
  @State currentTheme: ThemeConfig = THEME_PRESETS['light'];
  @State currentThemeName: string = 'light';

  // 广告拦截
  @State adBlockEnabled: boolean = true;
  private adBlockRules: AdBlockRule[] = [];

  // 密码自动填充
  @State autoFillEnabled: boolean = true;
  @State showPasswordSave: boolean = false;
  @State pendingPassword: PasswordItem | null = null;
  @State detectedUsername: string = '';
  @State detectedPassword: string = '';

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    this.dataManager.init(getContext(this));
    this.loadInitialData();
  }

  private async loadInitialData(): Promise<void> {
    // 加载搜索引擎
    const engine = await this.dataManager.getSearchEngine();
    this.currentSearchEngine = engine;
    this.homeUrl = engine.homeUrl;

    // 加载主题
    this.currentThemeName = await this.dataManager.getThemeName();
    this.currentTheme = await this.dataManager.getTheme();

    // 加载广告拦截设置
    this.adBlockEnabled = await this.dataManager.isAdBlockEnabled();
    this.adBlockRules = await this.dataManager.getAdBlockRules();

    // 加载密码自动填充设置
    this.autoFillEnabled = await this.dataManager.isAutoFillEnabled();

    // 加载标签页
    const tabs = await this.dataManager.getTabs();
    if (tabs.length > 0) {
      this.tabs = tabs;
      const activeTab = tabs.find(t => t.isActive) || tabs[0];
      this.activeTabId = activeTab.id;
      this.currentUrl = activeTab.url || this.homeUrl;
      this.urlInput = this.currentUrl;
      this.pageTitle = activeTab.title || '首页';
    } else {
      // 创建第一个标签
      const tab = await this.dataManager.addTab(this.homeUrl, '首页');
      this.tabs = [tab];
      this.activeTabId = tab.id;
      this.currentUrl = this.homeUrl;
      this.urlInput = this.homeUrl;
    }
  }

  // ==================== URL 处理 ====================

  private normalizeUrl(input: string): string {
    let url = input.trim();
    if (!url) return this.homeUrl;
    if (url.includes('.') && !url.includes(' ')) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://' + url;
      }
      return url;
    }
    return this.currentSearchEngine.searchUrl.replace('{query}', encodeURIComponent(url));
  }

  private navigateTo(url: string): void {
    const finalUrl = this.normalizeUrl(url);
    this.currentUrl = finalUrl;
    this.urlInput = finalUrl;
    this.isLoading = true;
    this.progress = 0;
    // 更新标签页数据
    this.dataManager.updateTab(this.activeTabId, { url: finalUrl, title: this.pageTitle });
    this.updateTabInList(this.activeTabId, { url: finalUrl });
  }

  private checkBookmarkStatus(): void {
    this.dataManager.isBookmarked(this.currentUrl).then((bookmarked: boolean) => {
      this.isBookmarked = bookmarked;
    });
  }

  // ==================== 标签页操作 ====================

  private async addNewTab(url?: string): Promise<void> {
    const targetUrl = url || this.homeUrl;
    const tab = await this.dataManager.addTab(targetUrl, '新标签页');
    const tabs = await this.dataManager.getTabs();
    this.tabs = tabs;
    this.activeTabId = tab.id;
    this.currentUrl = targetUrl;
    this.urlInput = targetUrl;
    this.pageTitle = '新标签页';
    this.isBookmarked = false;
    this.showTabOverview = false;
  }

  private async closeTab(tabId: string): Promise<void> {
    const activeTab = await this.dataManager.removeTab(tabId);
    const tabs = await this.dataManager.getTabs();
    this.tabs = tabs;
    if (activeTab) {
      this.activeTabId = activeTab.id;
      this.currentUrl = activeTab.url || this.homeUrl;
      this.urlInput = this.currentUrl;
      this.pageTitle = activeTab.title || '首页';
    }
  }

  private async switchToTab(tabId: string): Promise<void> {
    const tab = await this.dataManager.switchTab(tabId);
    if (tab) {
      this.activeTabId = tab.id;
      this.currentUrl = tab.url || this.homeUrl;
      this.urlInput = this.currentUrl;
      this.pageTitle = tab.title || '首页';
      this.checkBookmarkStatus();
      this.showTabOverview = false;
    }
  }

  private updateTabInList(tabId: string, updates: Partial<TabItem>): void {
    const tab = this.tabs.find(t => t.id === tabId);
    if (tab) {
      Object.assign(tab, updates);
    }
  }

  // ==================== 广告拦截 ====================

  private shouldBlockRequest(url: string): boolean {
    if (!this.adBlockEnabled) return false;
    return this.dataManager.shouldBlockUrl(url, this.adBlockRules);
  }

  // ==================== 密码自动填充 ====================

  private injectAutoFillScript(): void {
    if (!this.autoFillEnabled) return;
    // 查找当前网站的已保存密码
    this.dataManager.getPasswordForUrl(this.currentUrl).then((saved: PasswordItem | null) => {
      if (saved && this.controller) {
        try {
          const js = `
            (function() {
              var inputs = document.querySelectorAll('input[type="password"]');
              if (inputs.length > 0) {
                var form = inputs[0].form || inputs[0].closest('form');
                if (form) {
                  var userInput = form.querySelector('input[type="email"], input[type="text"][name*="user"], input[type="text"][name*="email"], input[name*="login"]');
                  if (userInput && '${saved.username}') {
                    userInput.value = '${saved.username}';
                  }
                }
              }
            })()
          `;
          this.controller.runJavaScript(js);
        } catch (e) {
          // 自动填充失败不影响浏览
        }
      }
    });
  }

  // 检测登录表单提交，提示保存密码
  private checkForLoginForm(): void {
    if (!this.autoFillEnabled) return;
    try {
      const js = `
        (function() {
          var forms = document.querySelectorAll('form');
          for (var i = 0; i < forms.length; i++) {
            var form = forms[i];
            var pwdInput = form.querySelector('input[type="password"]');
            if (pwdInput) {
              form.addEventListener('submit', function() {
                var userField = form.querySelector('input[type="email"], input[type="text"][name*="user"], input[type="text"][name*="email"]');
                var username = userField ? userField.value : '';
                var password = pwdInput.value;
                if (username && password) {
                  window.harmonyBrowserBridge.postMessage(JSON.stringify({
                    type: 'password_submit',
                    username: username,
                    password: password
                  }));
                }
              });
            }
          }
        })()
      `;
      this.controller.runJavaScript(js);
    } catch (e) {
      // 注入失败不影响浏览
    }
  }

  // ==================== 构建界面 ====================

  build() {
    Column() {
      // ======== 顶部地址栏 ========
      this.TopBar();

      // ======== 标签页栏 ========
      this.TabBar();

      // ======== 加载进度条 ========
      if (this.isLoading) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color(this.currentTheme.primaryColor)
      } else {
        Divider().width('100%').height(0.5).color(this.currentTheme.borderColor)
      }

      // ======== Web 内容区 ========
      Web({ src: this.currentUrl, controller: this.controller })
        .layoutWeight(1)
        .width('100%')
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .databaseAccess(true)
        .cacheMode(CacheMode.Default)
        .textZoomAtAccess(true)
        .mixedMode(MixedMode.All)
        .onlineImageAccess(true)
        .zoomAccess(true)
        .overviewModeAccess(true)
        .verticalScrollBarAccess(false)
        .horizontalScrollBarAccess(false)
        // 夜间模式：深色方案强制
        .darkMode(this.currentTheme.mode === 'dark' ? WebDarkMode.On : WebDarkMode.Off)
        .forceDarkAccess(this.currentTheme.mode === 'dark')
        // 广告拦截：通过 onInterceptRequest 拦截
        .onInterceptRequest((event) => {
          if (event && event.request) {
            const reqUrl = event.request.getUrl();
            if (reqUrl && this.shouldBlockRequest(reqUrl)) {
              return new WebResourceResponse('text/plain', 'UTF-8', 200, '');
            }
          }
          return null;
        })
        // 页面加载进度
        .onProgressChange((event) => {
          if (event) {
            this.progress = event.newProgress;
            if (event.newProgress >= 100) {
              this.isLoading = false;
            }
          }
        })
        // 页面标题更新
        .onTitleReceive((event) => {
          if (event && event.title) {
            this.pageTitle = event.title;
            this.updateTabInList(this.activeTabId, { title: event.title });
            this.dataManager.updateTab(this.activeTabId, { title: event.title });
          }
        })
        // 页面开始加载
        .onPageBegin((event) => {
          if (event) {
            this.isLoading = true;
            this.progress = 0;
            this.urlInput = event.url;
            this.currentUrl = event.url;
            this.checkBookmarkStatus();
            // 注入密码自动填充
            this.injectAutoFillScript();
          }
        })
        // 页面结束加载
        .onPageEnd((event) => {
          if (event) {
            this.isLoading = false;
            this.dataManager.addHistory(this.pageTitle, event.url);
            // 检测登录表单
            this.checkForLoginForm();
          }
        })
        // 新窗口请求
        .onNewWindow((event) => {
          if (event) {
            this.navigateTo(event.url);
          }
        })

      // ======== 底部工具栏 ========
      this.BottomBar();

      // ======== 菜单面板 ========
      if (this.showMenu) {
        this.MenuPanel();
      }

      // ======== 标签页总览 ========
      if (this.showTabOverview) {
        this.TabOverviewPanel();
      }

      // ======== 密码保存提示 ========
      if (this.showPasswordSave && this.pendingPassword) {
        this.PasswordSaveDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentTheme.backgroundColor)
  }

  // ==================== 标签页栏 ====================

  @Builder
  TabBar() {
    Scroll() {
      Row() {
        ForEach(this.tabs, (tab: TabItem) => {
          Row() {
            Text(tab.title.length > 10 ? tab.title.substring(0, 10) + '…' : tab.title)
              .fontSize(12)
              .fontColor(this.activeTabId === tab.id ? this.currentTheme.primaryColor : this.currentTheme.textColor)
              .maxLines(1)
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            // 关闭按钮
            if (this.tabs.length > 1) {
              Text('✕')
                .fontSize(10)
                .fontColor(this.currentTheme.subTextColor)
                .margin({ left: 4 })
                .onClick(() => {
                  this.closeTab(tab.id);
                })
            }
          }
          .height(32)
          .padding({ left: 12, right: 8 })
          .borderRadius(8)
          .backgroundColor(this.activeTabId === tab.id ? this.currentTheme.surfaceColor : Color.Transparent)
          .border({
            width: this.activeTabId === tab.id ? 1 : 0,
            color: this.currentTheme.primaryColor
          })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.switchToTab(tab.id);
          })
        }, (tab: TabItem) => tab.id)

        // 新建标签按钮
        Row() {
          Text('+')
            .fontSize(18)
            .fontColor(this.currentTheme.primaryColor)
            .fontWeight(FontWeight.Bold)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor(this.currentTheme.surfaceColor)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 4 })
        .onClick(() => {
          this.addNewTab();
        })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(40)
    .padding({ left: 8, right: 8 })
    .backgroundColor(this.currentTheme.backgroundColor)
  }

  // ==================== 顶部地址栏 ====================

  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(20).height(20)
          .fillColor(this.currentTheme.textColor)
      }
      .width(36).height(36)
      .backgroundColor(Color.Transparent)
      .borderRadius(18)
      .onClick(() => {
        try {
          this.controller.backward();
        } catch (e) {}
      })

      // URL 输入框
      Row() {
        Image($r('sys.media.ohos_ic_public_lock'))
          .width(14).height(14)
          .fillColor(this.currentTheme.subTextColor)
          .margin({ right: 6 })
          .visibility(this.currentUrl.startsWith('https') ? Visibility.Visible : Visibility.Hidden)

        TextInput({ text: this.urlInput, placeholder: `${this.currentSearchEngine.name} 搜索或输入网址` })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .placeholderColor(this.currentTheme.subTextColor)
          .caretColor(this.currentTheme.primaryColor)
          .fontColor(this.currentTheme.textColor)
          .border({ width: 0 })
          .onChange((value: string) => {
            this.urlInput = value;
          })
          .onSubmit(() => {
            this.navigateTo(this.urlInput);
          })
      }
      .layoutWeight(1)
      .height(40)
      .borderRadius(20)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.currentTheme.surfaceColor)
      .alignItems(VerticalAlign.Center)

      // 刷新 / 停止按钮
      Button() {
        if (this.isLoading) {
          Text('✕').fontSize(16).fontColor(this.currentTheme.textColor);
        } else {
          Text('↻').fontSize(20).fontColor(this.currentTheme.textColor);
        }
      }
      .width(36).height(36)
      .backgroundColor(Color.Transparent)
      .borderRadius(18)
      .onClick(() => {
        if (this.isLoading) {
          this.controller.stop();
          this.isLoading = false;
        } else {
          this.controller.refresh();
        }
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.currentTheme.backgroundColor)
  }

  // ==================== 底部工具栏 ====================

  @Builder
  BottomBar() {
    Row() {
      // 后退
      this.ToolBtn('◁', '后退', () => {
        try { this.controller.backward(); } catch (e) {}
      })
      // 前进
      this.ToolBtn('▷', '前进', () => {
        try { this.controller.forward(); } catch (e) {}
      })
      // 书签
      this.ToolBtn(this.isBookmarked ? '★' : '☆', '书签', () => {
        if (this.isBookmarked) {
          this.dataManager.getBookmarks().then((list) => {
            const found = list.find((b) => b.url === this.currentUrl);
            if (found) {
              this.dataManager.removeBookmark(found.id);
              this.isBookmarked = false;
            }
          });
        } else {
          this.dataManager.addBookmark(this.pageTitle, this.currentUrl);
          this.isBookmarked = true;
        }
      })
      // 标签页
      this.ToolBtn(`${this.tabs.length}`, '标签', () => {
        this.showTabOverview = !this.showTabOverview;
      })
      // 菜单
      this.ToolBtn('☰', '菜单', () => {
        this.showMenu = !this.showMenu;
      })
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.currentTheme.backgroundColor)
    .border({ width: { top: 0.5 }, color: this.currentTheme.borderColor })
  }

  @Builder
  ToolBtn(icon: string, label: string, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(20)
        .fontColor(this.currentTheme.textColor)
        .lineHeight(24)
      Text(label)
        .fontSize(9)
        .fontColor(this.currentTheme.subTextColor)
        .margin({ top: 2 })
    }
    .width(48)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(8)
    .onClick(action)
  }

  // ==================== 菜单面板 ====================

  @Builder
  MenuPanel() {
    Column()
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .backgroundColor('rgba(0,0,0,0.3)')
      .onClick(() => { this.showMenu = false; })

    Column() {
      this.MenuItem('📑  书签管理', () => {
        this.showMenu = false;
        router.pushUrl({ url: 'pages/BookmarkPage' });
      })
      Divider().color(this.currentTheme.borderColor)
      this.MenuItem('🕐  历史记录', () => {
        this.showMenu = false;
        router.pushUrl({ url: 'pages/HistoryPage' });
      })
      Divider().color(this.currentTheme.borderColor)
      this.MenuItem('🌙  夜间模式: ' + (this.currentTheme.mode === 'dark' ? '开' : '关'), () => {
        this.showMenu = false;
        const newTheme = this.currentTheme.mode === 'dark' ? 'light' : 'dark';
        this.currentThemeName = newTheme;
        this.currentTheme = THEME_PRESETS[newTheme];
        this.dataManager.setTheme(newTheme);
      })
      Divider().color(this.currentTheme.borderColor)
      this.MenuItem('🛡️  广告拦截: ' + (this.adBlockEnabled ? '开' : '关'), () => {
        this.showMenu = false;
        this.adBlockEnabled = !this.adBlockEnabled;
        this.dataManager.setAdBlockEnabled(this.adBlockEnabled);
      })
      Divider().color(this.currentTheme.borderColor)
      this.MenuItem('🔑  密码填充: ' + (this.autoFillEnabled ? '开' : '关'), () => {
        this.showMenu = false;
        this.autoFillEnabled = !this.autoFillEnabled;
        this.dataManager.setAutoFillEnabled(this.autoFillEnabled);
      })
      Divider().color(this.currentTheme.borderColor)
      this.MenuItem('⬇  添加到桌面', () => {
        this.showMenu = false;
      })
      Divider().color(this.currentTheme.borderColor)
      this.MenuItem('⚙  设置', () => {
        this.showMenu = false;
        router.pushUrl({ url: 'pages/SettingsPage' });
      })
    }
    .width('240')
    .backgroundColor(this.currentTheme.backgroundColor)
    .borderRadius(12)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.1)', offsetY: 4 })
    .position({ x: '50%', y: '70%' })
    .zIndex(100)
  }

  @Builder
  MenuItem(text: string, action: () => void) {
    Row() {
      Text(text)
        .fontSize(15)
        .fontColor(this.currentTheme.textColor)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(action)
  }

  // ==================== 标签页总览面板 ====================

  @Builder
  TabOverviewPanel() {
    Column() {
      // 标题
      Row() {
        Text(`标签页 (${this.tabs.length})`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)
          .layoutWeight(1)

        Text('关闭全部')
          .fontSize(14)
          .fontColor('#EF4444')
          .onClick(async () => {
            const newTab = await this.dataManager.clearAllTabs();
            this.tabs = [newTab];
            this.activeTabId = newTab.id;
            this.currentUrl = this.homeUrl;
            this.urlInput = this.homeUrl;
            this.pageTitle = '新标签页';
            this.showTabOverview = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 标签列表
      Scroll() {
        Column() {
          ForEach(this.tabs, (tab: TabItem) => {
            Row() {
              // 标题和 URL
              Column() {
                Text(tab.title || '新标签页')
                  .fontSize(15)
                  .fontColor(this.currentTheme.textColor)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(tab.url ? (tab.url.length > 50 ? tab.url.substring(0, 50) + '…' : tab.url) : '空白页')
                  .fontSize(11)
                  .fontColor(this.currentTheme.subTextColor)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 关闭按钮
              Button() {
                Text('✕').fontSize(14).fontColor(this.currentTheme.subTextColor)
              }
              .width(28).height(28)
              .backgroundColor(Color.Transparent)
              .borderRadius(14)
              .margin({ left: 8 })
              .onClick(() => {
                this.closeTab(tab.id);
              })
            }
            .width('100%')
            .height(64)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .borderRadius(8)
            .backgroundColor(this.activeTabId === tab.id ? this.currentTheme.surfaceColor : Color.Transparent)
            .border({
              width: this.activeTabId === tab.id ? 1.5 : 0,
              color: this.currentTheme.primaryColor
            })
            .margin({ bottom: 4 })
            .onClick(() => {
              this.switchToTab(tab.id);
            })
          }, (tab: TabItem) => tab.id)
        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)

      // 新建标签按钮
      Button('新建标签页')
        .width('90%')
        .height(44)
        .fontSize(15)
        .fontColor(Color.White)
        .backgroundColor(this.currentTheme.primaryColor)
        .borderRadius(22)
        .margin({ top: 12, bottom: 16 })
        .onClick(() => {
          this.addNewTab();
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(150)
    .backgroundColor(this.currentTheme.backgroundColor)
  }

  // ==================== 密码保存弹窗 ====================

  @Builder
  PasswordSaveDialog() {
    Column() {
      Column() {
        Text('保存密码？')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })
          .fontColor(this.currentTheme.textColor)
        Text(`是否为 ${this.pendingPassword?.title || '此网站'} 保存登录信息？`)
          .fontSize(14)
          .fontColor(this.currentTheme.subTextColor)
          .textAlign(TextAlign.Center)

        Row() {
          Button('不保存')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor(this.currentTheme.subTextColor)
            .backgroundColor(this.currentTheme.surfaceColor)
            .borderRadius(20)
            .onClick(() => {
              this.showPasswordSave = false;
              this.pendingPassword = null;
            })

          Button('保存')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor(this.currentTheme.primaryColor)
            .borderRadius(20)
            .margin({ left: 12 })
            .onClick(() => {
              if (this.pendingPassword) {
                this.dataManager.savePassword(
                  this.pendingPassword.url,
                  this.pendingPassword.title,
                  this.pendingPassword.username,
                  this.pendingPassword.password
                );
              }
              this.showPasswordSave = false;
              this.pendingPassword = null;
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .width('280')
      .padding(24)
      .backgroundColor(this.currentTheme.backgroundColor)
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .position({ x: 0, y: 0 })
    .zIndex(200)
    .onClick(() => {
      this.showPasswordSave = false;
      this.pendingPassword = null;
    })
  }
}
