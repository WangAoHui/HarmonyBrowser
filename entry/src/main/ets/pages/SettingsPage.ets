import { router } from '@kit.ArkUI';
import { DataManager } from '../common/DataManager';
import { CookieManager, WebDataCleaner } from '../common/CookieManager';
import { webview } from '@kit.ArkWeb';
import { promptAction } from '@kit.ArkUI';
import { SearchEngine, SEARCH_ENGINES } from '../model/BrowserData';

@Entry
@Component
struct SettingsPage {
  private dataManager: DataManager = DataManager.getInstance();
  private cookieManager: CookieManager = CookieManager.getInstance();
  @State showClearDataConfirm: boolean = false;
  @State showClearCookieConfirm: boolean = false;
  @State clearDataOption: number = 0; // 0=全部, 1=缓存, 2=Cookie, 3=历史+书签
  @State bookmarkCount: number = 0;
  @State historyCount: number = 0;
  // 搜索引擎相关
  @State currentEngineId: string = 'bing';
  @State showEnginePicker: boolean = false;

  aboutToAppear(): void {
    this.loadCounts();
    this.loadSearchEngine();
  }

  private async loadCounts(): Promise<void> {
    const bookmarks = await this.dataManager.getBookmarks();
    const history = await this.dataManager.getHistory();
    this.bookmarkCount = bookmarks.length;
    this.historyCount = history.length;
  }

  private async loadSearchEngine(): Promise<void> {
    const engine = await this.dataManager.getSearchEngine();
    this.currentEngineId = engine.id;
  }

  private showToast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000 });
  }

  build() {
    Column() {
      // ======== 标题栏 ========
      Row() {
        Button() {
          Text('←').fontSize(22).fontColor('#333333');
        }
        .width(40).height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => router.back())

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(40);
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // ======== 数据统计 ========
          Row() {
            Column() {
              Text(`${this.bookmarkCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#3B82F6')
              Text('书签')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.historyCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#3B82F6')
              Text('历史记录')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding(24)
          .margin({ top: 8, left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor('#F0F7FF')

          // ======== 隐私与数据 ========
          Text('隐私与数据')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            // 清除浏览数据
            this.SettingItem('清除浏览数据', '清除缓存、历史记录、书签等所有本地数据', '#EF4444', () => {
              this.clearDataOption = 0;
              this.showClearDataConfirm = true;
            })

            Divider().color('#F5F5F5').margin({ left: 16 })

            // 清除缓存
            this.SettingItem('清除网页缓存', '清除浏览器缓存和离线数据', '#F59E0B', () => {
              this.clearDataOption = 1;
              this.showClearDataConfirm = true;
            })

            Divider().color('#F5F5F5').margin({ left: 16 })

            // 清除 Cookie
            this.SettingItem('清除 Cookie', '清除所有网站的 Cookie 和网站数据', '#F59E0B', () => {
              this.showClearCookieConfirm = true;
            })

            Divider().color('#F5F5F5').margin({ left: 16 })

            // 清除历史记录
            this.SettingItem('清除历史记录', `清除全部 ${this.historyCount} 条浏览记录`, '#F59E0B', () => {
              this.clearDataOption = 3;
              this.showClearDataConfirm = true;
            })

            Divider().color('#F5F5F5').margin({ left: 16 })

            // 清除书签
            this.SettingItem('清除所有书签', `清除全部 ${this.bookmarkCount} 个书签`, '#F59E0B', () => {
              this.clearDataOption = 4;
              this.showClearDataConfirm = true;
            })
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // ======== 搜索引擎设置 ========
          Text('搜索引擎')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            // 当前搜索引擎
            this.SettingItem('默认搜索引擎', this.getCurrentEngineName(), '#3B82F6', () => {
              this.showEnginePicker = true;
            })

            Divider().color('#F5F5F5').margin({ left: 16 })

            // 快捷切换
            Row() {
              ForEach(SEARCH_ENGINES, (engine: SearchEngine) => {
                Column() {
                  Text(engine.icon)
                    .fontSize(22)
                    .lineHeight(28)
                  Text(engine.name)
                    .fontSize(10)
                    .fontColor(this.currentEngineId === engine.id ? '#3B82F6' : '#888888')
                    .margin({ top: 2 })
                }
                .width(48)
                .height(56)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderRadius(10)
                .backgroundColor(this.currentEngineId === engine.id ? '#EBF3FF' : '#F8F8F8')
                .border({
                  width: this.currentEngineId === engine.id ? 2 : 0,
                  color: '#3B82F6'
                })
                .onClick(async () => {
                  this.currentEngineId = engine.id;
                  await this.dataManager.setSearchEngine(engine.id);
                  this.showToast(`已切换为 ${engine.name}`);
                })
              }, (engine: SearchEngine) => engine.id)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // ======== 关于 ========
          Text('关于')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            this.SettingItem('应用名称', 'HarmonyBrowser', '#333333', () => {})
            Divider().color('#F5F5F5').margin({ left: 16 })
            this.SettingItem('版本', '1.0.0', '#333333', () => {})
            Divider().color('#F5F5F5').margin({ left: 16 })
            this.SettingItem('内核', 'ArkWeb (HarmonyOS)', '#333333', () => {})
            Divider().color('#F5F5F5').margin({ left: 16 })
            this.SettingItem('开发者', 'HarmonyOS Developer', '#333333', () => {})
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // 底部间距
          Row().height(40)
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')

    // ======== 清除数据确认弹窗 ========
    if (this.showClearDataConfirm) {
      this.ConfirmDialog(
        '清除数据',
        this.getClearDataMessage(),
        () => {
          this.executeClear();
          this.showClearDataConfirm = false;
        },
        () => { this.showClearDataConfirm = false; }
      );
    }

    // ======== 清除 Cookie 确认弹窗 ========
    if (this.showClearCookieConfirm) {
      this.ConfirmDialog(
        '清除 Cookie',
        '确定要清除所有网站的 Cookie 吗？你可能会退出已登录的网站。',
        () => {
          this.cookieManager.clearAllCookies();
          this.cookieManager.saveCookies();
          this.showToast('Cookie 已清除');
          this.showClearCookieConfirm = false;
        },
        () => { this.showClearCookieConfirm = false; }
      );
    }

    // ======== 搜索引擎选择弹窗 ========
    if (this.showEnginePicker) {
      this.SearchEnginePickerDialog();
    }
  }

  private getCurrentEngineName(): string {
    const engine = SEARCH_ENGINES.find(e => e.id === this.currentEngineId);
    return engine ? `${engine.icon} ${engine.name}` : 'Bing';
  }

  private getClearDataMessage(): string {
    switch (this.clearDataOption) {
      case 0: return '确定要清除所有浏览数据吗？包括缓存、历史记录和书签。此操作不可恢复。';
      case 1: return '确定要清除网页缓存吗？';
      case 3: return '确定要清除所有浏览历史记录吗？此操作不可恢复。';
      case 4: return '确定要清除所有书签吗？此操作不可恢复。';
      default: return '确定要执行此操作吗？';
    }
  }

  private async executeClear(): Promise<void> {
    switch (this.clearDataOption) {
      case 0: // 全部
        await this.dataManager.clearAllData();
        this.cookieManager.clearAllCookies();
        this.cookieManager.saveCookies();
        this.showToast('所有数据已清除');
        break;
      case 1: // 仅缓存
        this.showToast('网页缓存已清除');
        break;
      case 3: // 历史记录
        await this.dataManager.clearAllHistory();
        this.showToast('历史记录已清除');
        break;
      case 4: // 书签
        await this.dataManager.clearAllData();
        this.showToast('书签已清除');
        break;
    }
    this.loadCounts();
  }

  @Builder
  SettingItem(title: string, subtitle: string, accentColor: string, action: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
        if (subtitle !== title) {
          Text(subtitle)
            .fontSize(12)
            .fontColor(accentColor === '#333333' ? '#999999' : accentColor)
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›').fontSize(18).fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
    .onClick(action)
  }

  @Builder
  ConfirmDialog(title: string, message: string, onConfirm: () => void, onCancel: () => void) {
    Column() {
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })
        Text(message)
          .fontSize(14)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor('#666666')
            .backgroundColor('#F3F4F6')
            .borderRadius(20)
            .onClick(onCancel)

          Button('确定')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#EF4444')
            .borderRadius(20)
            .margin({ left: 12 })
            .onClick(onConfirm)
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .width('280')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .position({ x: 0, y: 0 })
    .zIndex(200)
    .onClick(onCancel)
  }

  // ======== 搜索引擎选择弹窗 ========
  @Builder
  SearchEnginePickerDialog() {
    Column() {
      Column() {
        // 标题
        Text('选择搜索引擎')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        // 搜索引擎列表
        Column() {
          ForEach(SEARCH_ENGINES, (engine: SearchEngine, index: number) => {
            Row() {
              // 图标
              Text(engine.icon)
                .fontSize(24)
                .width(40)
                .textAlign(TextAlign.Center)

              // 名称和描述
              Column() {
                Text(engine.name)
                  .fontSize(15)
                  .fontColor('#333333')
                  .fontWeight(this.currentEngineId === engine.id ? FontWeight.Bold : FontWeight.Normal)
                Text(engine.homeUrl.replace('https://', ''))
                  .fontSize(11)
                  .fontColor('#999999')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 8 })

              // 选中指示器
              if (this.currentEngineId === engine.id) {
                Text('✓')
                  .fontSize(18)
                  .fontColor('#3B82F6')
                  .fontWeight(FontWeight.Bold)
              } else {
                Row()
                  .width(20)
                  .height(20)
                  .borderRadius(10)
                  .border({ width: 1.5, color: '#CCCCCC' })
              }
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .borderRadius(this.currentEngineId === engine.id ? 8 : 0)
            .backgroundColor(this.currentEngineId === engine.id ? '#EBF3FF' : Color.Transparent)
            .onClick(async () => {
              this.currentEngineId = engine.id;
              await this.dataManager.setSearchEngine(engine.id);
              this.showToast(`已切换为 ${engine.name}`);
              this.showEnginePicker = false;
            })

            // 分割线（最后一项不显示）
            if (index < SEARCH_ENGINES.length - 1) {
              Divider().color('#F0F0F0').margin({ left: 64 })
            }
          }, (engine: SearchEngine) => engine.id)
        }
        .width('100%')
        .borderRadius(12)
        .backgroundColor('#F8F9FA')

        // 关闭按钮
        Button('关闭')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontColor('#666666')
          .backgroundColor('#F3F4F6')
          .borderRadius(22)
          .margin({ top: 16 })
          .onClick(() => { this.showEnginePicker = false; })
      }
      .width('320')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .position({ x: 0, y: 0 })
    .zIndex(200)
    .onClick(() => { this.showEnginePicker = false; })
  }
}
