import { webview } from '@kit.ArkWeb';
import { router } from '@kit.ArkUI';
import { DataManager } from '../common/DataManager';
import { CookieManager } from '../common/CookieManager';
import { SearchEngine, SEARCH_ENGINES } from '../model/BrowserData';

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
  @State currentSearchEngine: SearchEngine = SEARCH_ENGINES[0]; // 默认 Bing
  // 底部菜单
  @State showMenu: boolean = false;
  // 是否编辑模式（地址栏获焦）
  @State isUrlFocused: boolean = false;

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    this.dataManager.init(getContext(this));
    this.loadSearchEngine();
  }

  private async loadSearchEngine(): Promise<void> {
    const engine = await this.dataManager.getSearchEngine();
    this.currentSearchEngine = engine;
    this.homeUrl = engine.homeUrl;
    this.currentUrl = engine.homeUrl;
    this.urlInput = engine.homeUrl;
  }

  // ==================== URL 处理 ====================

  private normalizeUrl(input: string): string {
    let url = input.trim();
    if (!url) return this.homeUrl;
    // 判断是否像 URL（包含 . 或以 / 结尾）
    if (url.includes('.') && !url.includes(' ')) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://' + url;
      }
      return url;
    }
    // 否则当搜索关键词处理 — 使用用户选择的搜索引擎
    return this.currentSearchEngine.searchUrl.replace('{query}', encodeURIComponent(url));
  }

  private navigateTo(url: string): void {
    const finalUrl = this.normalizeUrl(url);
    this.currentUrl = finalUrl;
    this.urlInput = finalUrl;
    this.isLoading = true;
    this.progress = 0;
  }

  private checkBookmarkStatus(): void {
    this.dataManager.isBookmarked(this.currentUrl).then((bookmarked: boolean) => {
      this.isBookmarked = bookmarked;
    });
  }

  // ==================== 构建界面 ====================

  build() {
    Column() {
      // ======== 顶部地址栏 ========
      this.TopBar();

      // ======== 加载进度条 ========
      if (this.isLoading) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color('#3B82F6')
      } else {
        Divider().width('100%').height(0.5).color('#E5E7EB')
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
          }
        })
        // 页面结束加载
        .onPageEnd((event) => {
          if (event) {
            this.isLoading = false;
            // 保存到历史记录
            this.dataManager.addHistory(this.pageTitle, event.url);
          }
        })
        // 新窗口请求
        .onNewPush((event) => {
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // ==================== 顶部地址栏 ====================

  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(20).height(20)
          .fillColor('#333333')
      }
      .width(36).height(36)
      .backgroundColor(Color.Transparent)
      .borderRadius(18)
      .onClick(() => {
        try {
          this.controller.backward();
        } catch (e) {
          // 已经是第一页
        }
      })

      // URL 输入框
      Row() {
        Image($r('sys.media.ohos_ic_public_lock'))
          .width(14).height(14)
          .fillColor('#999999')
          .margin({ right: 6 })
          .visibility(this.currentUrl.startsWith('https') ? Visibility.Visible : Visibility.Hidden)

        TextInput({ text: this.urlInput, placeholder: `${this.currentSearchEngine.name} 搜索或输入网址` })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .placeholderColor('#BBBBBB')
          .caretColor('#3B82F6')
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
      .backgroundColor('#F3F4F6')
      .alignItems(VerticalAlign.Center)

      // 刷新 / 停止按钮
      Button() {
        if (this.isLoading) {
          // 停止图标 X
          Text('✕').fontSize(16).fontColor('#333333');
        } else {
          // 刷新图标
          Text('↻').fontSize(20).fontColor('#333333');
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
    .backgroundColor('#FFFFFF')
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
      // 书签（收藏/取消）
      this.ToolBtn(this.isBookmarked ? '★' : '☆', '书签', () => {
        if (this.isBookmarked) {
          // 取消收藏 — 需要先查找书签 ID
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
      // 主页
      this.ToolBtn('⌂', '主页', () => {
        this.navigateTo(this.homeUrl);
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
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 0.5 }, color: '#E5E7EB' })
  }

  @Builder
  ToolBtn(icon: string, label: string, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(20)
        .fontColor('#333333')
        .lineHeight(24)
      Text(label)
        .fontSize(9)
        .fontColor('#888888')
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
    // 半透明遮罩
    Column()
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .backgroundColor('rgba(0,0,0,0.3)')
      .onClick(() => { this.showMenu = false; })

    // 菜单内容
    Column() {
      this.MenuItem('📑  书签管理', () => {
        this.showMenu = false;
        router.pushUrl({ url: 'pages/BookmarkPage' });
      })
      Divider().color('#F0F0F0')
      this.MenuItem('🕐  历史记录', () => {
        this.showMenu = false;
        router.pushUrl({ url: 'pages/HistoryPage' });
      })
      Divider().color('#F0F0F0')
      this.MenuItem('⬇  添加到桌面', () => {
        this.showMenu = false;
        // TODO: 添加快捷方式到桌面
      })
      Divider().color('#F0F0F0')
      this.MenuItem('⚙  设置', () => {
        this.showMenu = false;
        router.pushUrl({
          url: 'pages/SettingsPage',
          params: { webControllerId: 'main' }
        });
      })
    }
    .width('200')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.1)', offsetY: 4 })
    .position({ x: '55%', y: '75%' })
    .zIndex(100)
  }

  @Builder
  MenuItem(text: string, action: () => void) {
    Row() {
      Text(text)
        .fontSize(15)
        .fontColor('#333333')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(action)
  }
}
