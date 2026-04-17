import { router } from '@kit.ArkUI';
import { DataManager } from '../common/DataManager';
import { CookieManager, WebDataCleaner } from '../common/CookieManager';
import { webview } from '@kit.ArkWeb';
import { promptAction } from '@kit.ArkUI';
import {
  SearchEngine, SEARCH_ENGINES,
  ThemeConfig, THEME_PRESETS, PasswordItem
} from '../model/BrowserData';

@Entry
@Component
struct SettingsPage {
  private dataManager: DataManager = DataManager.getInstance();
  private cookieManager: CookieManager = CookieManager.getInstance();
  @State showClearDataConfirm: boolean = false;
  @State showClearCookieConfirm: boolean = false;
  @State clearDataOption: number = 0;
  @State bookmarkCount: number = 0;
  @State historyCount: number = 0;
  @State tabCount: number = 0;
  // 搜索引擎
  @State currentEngineId: string = 'bing';
  @State showEnginePicker: boolean = false;
  // 主题
  @State currentThemeName: string = 'light';
  @State currentTheme: ThemeConfig = THEME_PRESETS['light'];
  @State showThemePicker: boolean = false;
  // 广告拦截
  @State adBlockEnabled: boolean = true;
  // 密码
  @State autoFillEnabled: boolean = true;
  @State savedPasswords: PasswordItem[] = [];
  @State showPasswordList: boolean = false;
  @State showDeletePasswordConfirm: boolean = false;
  @State deletingPasswordId: string = '';

  aboutToAppear(): void {
    this.loadCounts();
    this.loadSearchEngine();
    this.loadTheme();
    this.loadAdBlock();
    this.loadAutoFill();
    this.loadPasswords();
  }

  private async loadCounts(): Promise<void> {
    const bookmarks = await this.dataManager.getBookmarks();
    const history = await this.dataManager.getHistory();
    const tabs = await this.dataManager.getTabs();
    this.bookmarkCount = bookmarks.length;
    this.historyCount = history.length;
    this.tabCount = tabs.length;
  }

  private async loadSearchEngine(): Promise<void> {
    const engine = await this.dataManager.getSearchEngine();
    this.currentEngineId = engine.id;
  }

  private async loadTheme(): Promise<void> {
    this.currentThemeName = await this.dataManager.getThemeName();
    this.currentTheme = THEME_PRESETS[this.currentThemeName] || THEME_PRESETS['light'];
  }

  private async loadAdBlock(): Promise<void> {
    this.adBlockEnabled = await this.dataManager.isAdBlockEnabled();
  }

  private async loadAutoFill(): Promise<void> {
    this.autoFillEnabled = await this.dataManager.isAutoFillEnabled();
  }

  private async loadPasswords(): Promise<void> {
    this.savedPasswords = await this.dataManager.getPasswords();
  }

  private showToast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000 });
  }

  build() {
    Column() {
      // ======== 标题栏 ========
      Row() {
        Button() {
          Text('←').fontSize(22).fontColor(this.currentTheme.textColor);
        }
        .width(40).height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => router.back())

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(40);
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.currentTheme.backgroundColor)

      Scroll() {
        Column() {
          // ======== 数据统计 ========
          Row() {
            Column() {
              Text(`${this.tabCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentTheme.primaryColor)
              Text('标签页')
                .fontSize(12)
                .fontColor(this.currentTheme.subTextColor)
                .margin({ top: 4 })
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.bookmarkCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentTheme.primaryColor)
              Text('书签')
                .fontSize(12)
                .fontColor(this.currentTheme.subTextColor)
                .margin({ top: 4 })
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.historyCount}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentTheme.primaryColor)
              Text('历史记录')
                .fontSize(12)
                .fontColor(this.currentTheme.subTextColor)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding(24)
          .margin({ top: 8, left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor(this.currentTheme.mode === 'dark' ? '#1E293B' : '#F0F7FF')

          // ======== 外观与主题 ========
          Text('外观与主题')
            .fontSize(13)
            .fontColor(this.currentTheme.subTextColor)
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            this.SettingItem('主题模式', this.getThemeDisplayName(), this.currentTheme.primaryColor, () => {
              this.showThemePicker = true;
            })

            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })

            // 主题预览快捷切换
            Row() {
              ForEach(Object.keys(THEME_PRESETS), (name: string) => {
                Column() {
                  Row()
                    .width(32)
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor(THEME_PRESETS[name].backgroundColor)
                    .border({
                      width: this.currentThemeName === name ? 2 : 1,
                      color: this.currentThemeName === name ? this.currentTheme.primaryColor : '#CCCCCC'
                    })
                  Text(this.getThemeDisplayName(name))
                    .fontSize(10)
                    .fontColor(this.currentThemeName === name ? this.currentTheme.primaryColor : this.currentTheme.subTextColor)
                    .margin({ top: 4 })
                }
                .width(56)
                .height(56)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderRadius(10)
                .backgroundColor(this.currentThemeName === name ? (this.currentTheme.mode === 'dark' ? '#1E293B' : '#EBF3FF') : Color.Transparent)
                .onClick(async () => {
                  this.currentThemeName = name;
                  this.currentTheme = THEME_PRESETS[name];
                  await this.dataManager.setTheme(name);
                  this.showToast(`已切换为${this.getThemeDisplayName(name)}`);
                })
              }, (name: string) => name)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor(this.currentTheme.backgroundColor)
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // ======== 广告拦截 ========
          Text('广告拦截')
            .fontSize(13)
            .fontColor(this.currentTheme.subTextColor)
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            Row() {
              Column() {
                Text('广告拦截')
                  .fontSize(15)
                  .fontColor(this.currentTheme.textColor)
                Text('拦截横幅、弹窗和跟踪器')
                  .fontSize(12)
                  .fontColor(this.currentTheme.subTextColor)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.adBlockEnabled })
                .onChange(async (isOn: boolean) => {
                  this.adBlockEnabled = isOn;
                  await this.dataManager.setAdBlockEnabled(isOn);
                  this.showToast(isOn ? '广告拦截已开启' : '广告拦截已关闭');
                })
                .selectedColor(this.currentTheme.primaryColor)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor(this.currentTheme.backgroundColor)
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // ======== 密码与自动填充 ========
          Text('密码与自动填充')
            .fontSize(13)
            .fontColor(this.currentTheme.subTextColor)
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            Row() {
              Column() {
                Text('自动填充密码')
                  .fontSize(15)
                  .fontColor(this.currentTheme.textColor)
                Text('自动填充已保存的登录信息')
                  .fontSize(12)
                  .fontColor(this.currentTheme.subTextColor)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.autoFillEnabled })
                .onChange(async (isOn: boolean) => {
                  this.autoFillEnabled = isOn;
                  await this.dataManager.setAutoFillEnabled(isOn);
                  this.showToast(isOn ? '自动填充已开启' : '自动填充已关闭');
                })
                .selectedColor(this.currentTheme.primaryColor)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .alignItems(VerticalAlign.Center)

            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })

            this.SettingItem('已保存密码', `${this.savedPasswords.length} 个`, this.currentTheme.primaryColor, () => {
              this.showPasswordList = true;
            })
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor(this.currentTheme.backgroundColor)
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // ======== 隐私与数据 ========
          Text('隐私与数据')
            .fontSize(13)
            .fontColor(this.currentTheme.subTextColor)
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            this.SettingItem('清除浏览数据', '清除缓存、历史记录、书签等所有本地数据', '#EF4444', () => {
              this.clearDataOption = 0;
              this.showClearDataConfirm = true;
            })
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('清除网页缓存', '清除浏览器缓存和离线数据', '#F59E0B', () => {
              this.clearDataOption = 1;
              this.showClearDataConfirm = true;
            })
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('清除 Cookie', '清除所有网站的 Cookie 和网站数据', '#F59E0B', () => {
              this.showClearCookieConfirm = true;
            })
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('清除历史记录', `清除全部 ${this.historyCount} 条浏览记录`, '#F59E0B', () => {
              this.clearDataOption = 3;
              this.showClearDataConfirm = true;
            })
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('清除所有书签', `清除全部 ${this.bookmarkCount} 个书签`, '#F59E0B', () => {
              this.clearDataOption = 4;
              this.showClearDataConfirm = true;
            })
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor(this.currentTheme.backgroundColor)
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // ======== 搜索引擎设置 ========
          Text('搜索引擎')
            .fontSize(13)
            .fontColor(this.currentTheme.subTextColor)
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            this.SettingItem('默认搜索引擎', this.getCurrentEngineName(), this.currentTheme.primaryColor, () => {
              this.showEnginePicker = true;
            })
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })

            Row() {
              ForEach(SEARCH_ENGINES, (engine: SearchEngine) => {
                Column() {
                  Text(engine.icon)
                    .fontSize(22)
                    .lineHeight(28)
                  Text(engine.name)
                    .fontSize(10)
                    .fontColor(this.currentEngineId === engine.id ? this.currentTheme.primaryColor : this.currentTheme.subTextColor)
                    .margin({ top: 2 })
                }
                .width(48)
                .height(56)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderRadius(10)
                .backgroundColor(this.currentEngineId === engine.id ?
                  (this.currentTheme.mode === 'dark' ? '#1E293B' : '#EBF3FF') : this.currentTheme.surfaceColor)
                .border({
                  width: this.currentEngineId === engine.id ? 2 : 0,
                  color: this.currentTheme.primaryColor
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
          .backgroundColor(this.currentTheme.backgroundColor)
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          // ======== 关于 ========
          Text('关于')
            .fontSize(13)
            .fontColor(this.currentTheme.subTextColor)
            .margin({ top: 24, left: 16, bottom: 8 })

          Column() {
            this.SettingItem('应用名称', 'HarmonyBrowser', '#333333', () => {})
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('版本', '3.0.0 (API 20)', '#333333', () => {})
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('内核', 'ArkWeb (HarmonyOS 6.0.1)', '#333333', () => {})
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('开发者', 'WangAoHui', '#333333', () => {})
            Divider().color(this.currentTheme.borderColor).margin({ left: 16 })
            this.SettingItem('开源地址', 'github.com/WangAoHui/HarmonyBrowser', this.currentTheme.primaryColor, () => {})
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .borderRadius(12)
          .backgroundColor(this.currentTheme.backgroundColor)
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })

          Row().height(40)
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentTheme.mode === 'dark' ? '#0F172A' : '#F5F5F5')

    // ======== 弹窗们 ========
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

    if (this.showEnginePicker) {
      this.SearchEnginePickerDialog();
    }

    if (this.showThemePicker) {
      this.ThemePickerDialog();
    }

    if (this.showPasswordList) {
      this.PasswordListPanel();
    }

    if (this.showDeletePasswordConfirm) {
      this.ConfirmDialog(
        '删除密码',
        '确定要删除此网站的登录信息吗？',
        async () => {
          await this.dataManager.removePassword(this.deletingPasswordId);
          this.showDeletePasswordConfirm = false;
          this.loadPasswords();
          this.showToast('密码已删除');
        },
        () => { this.showDeletePasswordConfirm = false; }
      );
    }
  }

  private getCurrentEngineName(): string {
    const engine = SEARCH_ENGINES.find(e => e.id === this.currentEngineId);
    return engine ? `${engine.icon} ${engine.name}` : 'Bing';
  }

  private getThemeDisplayName(name?: string): string {
    const n = name || this.currentThemeName;
    const map: Record<string, string> = {
      'light': '☀️ 日间',
      'dark': '🌙 夜间',
      'midnight': '🌃 午夜',
      'ocean': '🌊 深海'
    };
    return map[n] || n;
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
      case 0:
        await this.dataManager.clearAllData();
        this.cookieManager.clearAllCookies();
        this.cookieManager.saveCookies();
        this.showToast('所有数据已清除');
        break;
      case 1:
        this.showToast('网页缓存已清除');
        break;
      case 3:
        await this.dataManager.clearAllHistory();
        this.showToast('历史记录已清除');
        break;
      case 4:
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
          .fontColor(this.currentTheme.textColor)
        if (subtitle !== title) {
          Text(subtitle)
            .fontSize(12)
            .fontColor(accentColor === '#333333' ? this.currentTheme.subTextColor : accentColor)
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
          .fontColor(this.currentTheme.textColor)
          .margin({ bottom: 12 })
        Text(message)
          .fontSize(14)
          .fontColor(this.currentTheme.subTextColor)
          .textAlign(TextAlign.Center)

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor(this.currentTheme.subTextColor)
            .backgroundColor(this.currentTheme.surfaceColor)
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
      .backgroundColor(this.currentTheme.backgroundColor)
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
        Text('选择搜索引擎')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)
          .margin({ bottom: 16 })

        Column() {
          ForEach(SEARCH_ENGINES, (engine: SearchEngine, index: number) => {
            Row() {
              Text(engine.icon)
                .fontSize(24)
                .width(40)
                .textAlign(TextAlign.Center)

              Column() {
                Text(engine.name)
                  .fontSize(15)
                  .fontColor(this.currentTheme.textColor)
                  .fontWeight(this.currentEngineId === engine.id ? FontWeight.Bold : FontWeight.Normal)
                Text(engine.homeUrl.replace('https://', ''))
                  .fontSize(11)
                  .fontColor(this.currentTheme.subTextColor)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 8 })

              if (this.currentEngineId === engine.id) {
                Text('✓')
                  .fontSize(18)
                  .fontColor(this.currentTheme.primaryColor)
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
            .backgroundColor(this.currentEngineId === engine.id ?
              (this.currentTheme.mode === 'dark' ? '#1E293B' : '#EBF3FF') : Color.Transparent)
            .onClick(async () => {
              this.currentEngineId = engine.id;
              await this.dataManager.setSearchEngine(engine.id);
              this.showToast(`已切换为 ${engine.name}`);
              this.showEnginePicker = false;
            })

            if (index < SEARCH_ENGINES.length - 1) {
              Divider().color(this.currentTheme.borderColor).margin({ left: 64 })
            }
          }, (engine: SearchEngine) => engine.id)
        }
        .width('100%')
        .borderRadius(12)
        .backgroundColor(this.currentTheme.surfaceColor)

        Button('关闭')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontColor(this.currentTheme.subTextColor)
          .backgroundColor(this.currentTheme.surfaceColor)
          .borderRadius(22)
          .margin({ top: 16 })
          .onClick(() => { this.showEnginePicker = false; })
      }
      .width('320')
      .padding(20)
      .backgroundColor(this.currentTheme.backgroundColor)
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

  // ======== 主题选择弹窗 ========
  @Builder
  ThemePickerDialog() {
    Column() {
      Column() {
        Text('选择主题')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)
          .margin({ bottom: 16 })

        Column() {
          ForEach(Object.keys(THEME_PRESETS), (name: string, index: number) => {
            Row() {
              // 颜色预览圆
              Row() {
                Row()
                  .width(16)
                  .height(16)
                  .borderRadius(8)
                  .backgroundColor(THEME_PRESETS[name].backgroundColor)
                  .border({ width: 1, color: '#666' })
                Row()
                  .width(16)
                  .height(16)
                  .borderRadius(8)
                  .backgroundColor(THEME_PRESETS[name].surfaceColor)
                  .margin({ left: 4 })
                Row()
                  .width(16)
                  .height(16)
                  .borderRadius(8)
                  .backgroundColor(THEME_PRESETS[name].primaryColor)
                  .margin({ left: 4 })
              }
              .width(60)
              .justifyContent(FlexAlign.Center)

              Text(this.getThemeDisplayName(name))
                .fontSize(15)
                .fontColor(this.currentTheme.textColor)
                .layoutWeight(1)
                .margin({ left: 8 })
                .fontWeight(this.currentThemeName === name ? FontWeight.Bold : FontWeight.Normal)

              if (this.currentThemeName === name) {
                Text('✓')
                  .fontSize(18)
                  .fontColor(this.currentTheme.primaryColor)
                  .fontWeight(FontWeight.Bold)
              }
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .borderRadius(this.currentThemeName === name ? 8 : 0)
            .backgroundColor(this.currentThemeName === name ?
              (this.currentTheme.mode === 'dark' ? '#1E293B' : '#EBF3FF') : Color.Transparent)
            .onClick(async () => {
              this.currentThemeName = name;
              this.currentTheme = THEME_PRESETS[name];
              await this.dataManager.setTheme(name);
              this.showToast(`已切换为${this.getThemeDisplayName(name)}`);
              this.showThemePicker = false;
            })

            if (index < Object.keys(THEME_PRESETS).length - 1) {
              Divider().color(this.currentTheme.borderColor).margin({ left: 76 })
            }
          }, (name: string) => name)
        }
        .width('100%')
        .borderRadius(12)
        .backgroundColor(this.currentTheme.surfaceColor)

        Button('关闭')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontColor(this.currentTheme.subTextColor)
          .backgroundColor(this.currentTheme.surfaceColor)
          .borderRadius(22)
          .margin({ top: 16 })
          .onClick(() => { this.showThemePicker = false; })
      }
      .width('320')
      .padding(20)
      .backgroundColor(this.currentTheme.backgroundColor)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .position({ x: 0, y: 0 })
    .zIndex(200)
    .onClick(() => { this.showThemePicker = false; })
  }

  // ======== 密码列表面板 ========
  @Builder
  PasswordListPanel() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('←').fontSize(22).fontColor(this.currentTheme.textColor);
        }
        .width(40).height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.showPasswordList = false; })

        Text('已保存密码')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(40);
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.currentTheme.backgroundColor)

      if (this.savedPasswords.length === 0) {
        Column() {
          Text('🔐')
            .fontSize(48)
            .margin({ bottom: 12 })
          Text('暂无保存的密码')
            .fontSize(16)
            .fontColor(this.currentTheme.subTextColor)
          Text('登录网站时可选择保存密码')
            .fontSize(13)
            .fontColor(this.currentTheme.subTextColor)
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.savedPasswords, (item: PasswordItem) => {
              Row() {
                Column() {
                  Text(item.title)
                    .fontSize(15)
                    .fontColor(this.currentTheme.textColor)
                    .fontWeight(FontWeight.Medium)
                  Text(item.username)
                    .fontSize(12)
                    .fontColor(this.currentTheme.subTextColor)
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Button() {
                  Text('🗑️').fontSize(16)
                }
                .width(36).height(36)
                .backgroundColor(Color.Transparent)
                .borderRadius(18)
                .onClick(() => {
                  this.deletingPasswordId = item.id;
                  this.showDeletePasswordConfirm = true;
                })
              }
              .width('100%')
              .height(64)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)
              .borderRadius(8)
              .backgroundColor(this.currentTheme.surfaceColor)
              .margin({ bottom: 4 })
            }, (item: PasswordItem) => item.id)
          }
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(300)
    .backgroundColor(this.currentTheme.mode === 'dark' ? '#0F172A' : '#F5F5F5')
  }
}
