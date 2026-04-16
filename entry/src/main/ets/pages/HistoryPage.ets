import { router } from '@kit.ArkUI';
import { DataManager } from '../common/DataManager';
import { HistoryItem } from '../model/BrowserData';

@Entry
@Component
struct HistoryPage {
  private dataManager: DataManager = DataManager.getInstance();
  @State historyList: HistoryItem[] = [];
  @State searchKeyword: string = '';
  @State showClearConfirm: boolean = false;

  aboutToAppear(): void {
    this.loadHistory();
  }

  private async loadHistory(): Promise<void> {
    this.historyList = await this.dataManager.getHistory();
  }

  private get filteredHistory(): HistoryItem[] {
    if (!this.searchKeyword) return this.historyList;
    const kw = this.searchKeyword.toLowerCase();
    return this.historyList.filter(h =>
      h.title.toLowerCase().includes(kw) || h.url.toLowerCase().includes(kw)
    );
  }

  // 按日期分组
  private get groupedHistory(): Map<string, HistoryItem[]> {
    const map = new Map<string, HistoryItem[]>();
    const list = this.filteredHistory;
    for (const item of list) {
      const d = new Date(item.visitTime);
      const key = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
      if (!map.has(key)) {
        map.set(key, []);
      }
      map.get(key)!.push(item);
    }
    return map;
  }

  private formatTime(timestamp: number): string {
    const d = new Date(timestamp);
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
  }

  private formatDateLabel(dateStr: string): string {
    const today = new Date();
    const todayStr = `${today.getFullYear()}-${(today.getMonth() + 1).toString().padStart(2, '0')}-${today.getDate().toString().padStart(2, '0')}`;
    if (dateStr === todayStr) return '今天';
    const yesterday = new Date(today.getTime() - 86400000);
    const ydStr = `${yesterday.getFullYear()}-${(yesterday.getMonth() + 1).toString().padStart(2, '0')}-${yesterday.getDate().toString().padStart(2, '0')}`;
    if (dateStr === ydStr) return '昨天';
    return dateStr;
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

        Text('历史记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 清空按钮
        Button('清空')
          .height(32)
          .fontSize(13)
          .fontColor(this.historyList.length > 0 ? '#EF4444' : '#CCCCCC')
          .backgroundColor(Color.Transparent)
          .enabled(this.historyList.length > 0)
          .onClick(() => { this.showClearConfirm = true; })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)

      // ======== 搜索栏 ========
      Row() {
        Text('🔍').fontSize(14).margin({ right: 8 })
        TextInput({ text: this.searchKeyword, placeholder: '搜索历史记录...' })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .placeholderColor('#BBBBBB')
          .onChange((value: string) => { this.searchKeyword = value; })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .borderRadius(22)
      .backgroundColor('#F3F4F6')
      .margin({ left: 16, right: 16, bottom: 8 })

      // ======== 历史列表 ========
      if (this.filteredHistory.length === 0) {
        Column() {
          Text('📭').fontSize(48).margin({ bottom: 16 })
          Text(this.searchKeyword ? '未找到匹配的记录' : '暂无浏览记录')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          // 按日期分组渲染
          ForEach(Array.from(this.groupedHistory.entries()), ([date, items]: [string, HistoryItem[]]) => {
            ListItemGroup({ header: this.DateHeader(date) }) {
              ForEach(items, (item: HistoryItem) => {
                ListItem() {
                  Row() {
                    // 时间
                    Text(this.formatTime(item.visitTime))
                      .fontSize(12)
                      .fontColor('#999999')
                      .width(44)

                    // 标题和 URL
                    Column() {
                      Text(item.title || '无标题')
                        .fontSize(14)
                        .fontColor('#333333')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(item.url)
                        .fontSize(11)
                        .fontColor('#AAAAAA')
                        .margin({ top: 3 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 8 })

                    // 访问次数
                    if (item.visitCount > 1) {
                      Text(`${item.visitCount}次`)
                        .fontSize(10)
                        .fontColor('#CCCCCC')
                        .margin({ left: 4, right: 4 })
                    }

                    // 删除
                    Button() {
                      Text('✕').fontSize(14).fontColor('#CCCCCC');
                    }
                    .width(32).height(32)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      this.dataManager.removeHistory(item.id).then(() => this.loadHistory());
                    })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .alignItems(VerticalAlign.Center)
                }
                .onClick(() => {
                  router.back();
                  AppStorage.setOrCreate<string>('navUrl', item.url);
                })
              }, (item: HistoryItem) => item.id)
            }
          }, ([date]: [string, HistoryItem[]]) => date)
        }
        .layoutWeight(1)
        .width('100%')
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 68, endMargin: 16 })
      }

      // ======== 清空确认弹窗 ========
      if (this.showClearConfirm) {
        this.ClearConfirmDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  DateHeader(date: string) {
    Row() {
      Text(this.formatDateLabel(date))
        .fontSize(13)
        .fontColor('#666666')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ left: 16, top: 12, bottom: 4 })
    .backgroundColor('#FAFAFA')
  }

  @Builder
  ClearConfirmDialog() {
    Column() {
      Column() {
        Text('清空历史记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })
        Text('确定要清空所有浏览记录吗？此操作不可恢复。')
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
            .onClick(() => { this.showClearConfirm = false; })

          Button('清空')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#EF4444')
            .borderRadius(20)
            .margin({ left: 12 })
            .onClick(() => {
              this.dataManager.clearAllHistory().then(() => {
                this.showClearConfirm = false;
                this.loadHistory();
              });
            })
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
    .onClick(() => { this.showClearConfirm = false; })
  }
}
