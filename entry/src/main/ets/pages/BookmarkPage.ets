import { router } from '@kit.ArkUI';
import { DataManager } from '../common/DataManager';
import { BookmarkItem } from '../model/BrowserData';

@Entry
@Component
struct BookmarkPage {
  private dataManager: DataManager = DataManager.getInstance();
  @State bookmarks: BookmarkItem[] = [];
  @State searchKeyword: string = '';
  @State showDeleteConfirm: boolean = false;
  @State deleteTargetId: string = '';

  aboutToAppear(): void {
    this.loadBookmarks();
  }

  private async loadBookmarks(): Promise<void> {
    this.bookmarks = await this.dataManager.getBookmarks();
  }

  private get filteredBookmarks(): BookmarkItem[] {
    if (!this.searchKeyword) return this.bookmarks;
    const kw = this.searchKeyword.toLowerCase();
    return this.bookmarks.filter(b =>
      b.title.toLowerCase().includes(kw) || b.url.toLowerCase().includes(kw)
    );
  }

  private formatTime(timestamp: number): string {
    const d = new Date(timestamp);
    return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours()}:${d.getMinutes().toString().padStart(2, '0')}`;
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

        Text('书签管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 书签数量
        Text(`${this.bookmarks.length}`)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 16 })
        // 占位对齐
        Row().width(40);
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)

      // ======== 搜索栏 ========
      Row() {
        Text('🔍').fontSize(14).margin({ right: 8 })
        TextInput({ text: this.searchKeyword, placeholder: '搜索书签...' })
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
      .margin({ bottom: 8 })
      .borderRadius(22)
      .backgroundColor('#F3F4F6')
      .margin({ left: 16, right: 16 })

      // ======== 书签列表 ========
      if (this.filteredBookmarks.length === 0) {
        // 空状态
        Column() {
          Text('📭').fontSize(48).margin({ bottom: 16 })
          Text(this.searchKeyword ? '未找到匹配的书签' : '暂无书签')
            .fontSize(16)
            .fontColor('#999999')
          Text('浏览网页时点击 ☆ 即可收藏')
            .fontSize(13)
            .fontColor('#BBBBBB')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.filteredBookmarks, (item: BookmarkItem) => {
            ListItem() {
              Row() {
                // 网站图标首字母
                Column() {
                  Text(item.title ? item.title.charAt(0).toUpperCase() : '🔗')
                    .fontSize(18)
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Bold)
                }
                .width(40).height(40)
                .borderRadius(8)
                .backgroundColor('#3B82F6')
                .justifyContent(FlexAlign.Center)
                .margin({ right: 12 })

                // 标题和 URL
                Column() {
                  Text(item.title || '无标题')
                    .fontSize(14)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.url)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // 时间
                Text(this.formatTime(item.createdAt))
                  .fontSize(11)
                  .fontColor('#CCCCCC')
                  .margin({ left: 8 })

                // 删除按钮
                Button() {
                  Text('✕').fontSize(14).fontColor('#CCCCCC');
                }
                .width(32).height(32)
                .backgroundColor(Color.Transparent)
                .borderRadius(16)
                .margin({ left: 4 })
                .onClick(() => {
                  this.dataManager.removeBookmark(item.id).then(() => this.loadBookmarks());
                })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .alignItems(VerticalAlign.Center)
            }
            .onClick(() => {
              // 跳转到浏览器并加载此 URL
              router.back();
              // 通过 AppStorage 传递 URL
              AppStorage.setOrCreate<string>('navUrl', item.url);
            })
          }, (item: BookmarkItem) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 68, endMargin: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
