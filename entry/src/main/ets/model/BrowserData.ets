// 书签数据模型
export interface BookmarkItem {
  id: string
  title: string
  url: string
  icon?: string
  createdAt: number
}

// 历史记录数据模型
export interface HistoryItem {
  id: string
  title: string
  url: string
  visitTime: number
  visitCount: number
}
