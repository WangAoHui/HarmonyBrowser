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

// 搜索引擎数据模型
export interface SearchEngine {
  id: string          // 唯一标识
  name: string        // 显示名称
  searchUrl: string   // 搜索 URL 模板，{query} 为占位符
  homeUrl: string     // 首页 URL
  icon: string        // 显示图标（emoji 或文字）
  suggestUrl?: string // 搜索建议 URL（可选）
}

// 预置搜索引擎列表
export const SEARCH_ENGINES: SearchEngine[] = [
  {
    id: 'bing',
    name: 'Bing',
    searchUrl: 'https://www.bing.com/search?q={query}',
    homeUrl: 'https://www.bing.com',
    icon: '🔍',
    suggestUrl: 'https://www.bing.com/osjson.aspx?query={query}'
  },
  {
    id: 'baidu',
    name: '百度',
    searchUrl: 'https://www.baidu.com/s?wd={query}',
    homeUrl: 'https://www.baidu.com',
    icon: '🐾',
    suggestUrl: 'https://suggestion.baidu.com/su?wd={query}'
  },
  {
    id: 'google',
    name: 'Google',
    searchUrl: 'https://www.google.com/search?q={query}',
    homeUrl: 'https://www.google.com',
    icon: '🌐'
  },
  {
    id: 'sogou',
    name: '搜狗',
    searchUrl: 'https://www.sogou.com/web?query={query}',
    homeUrl: 'https://www.sogou.com',
    icon: '🐕'
  },
  {
    id: 'duckduckgo',
    name: 'DuckDuckGo',
    searchUrl: 'https://duckduckgo.com/?q={query}',
    homeUrl: 'https://duckduckgo.com',
    icon: '🦆'
  },
  {
    id: 'toutiao',
    name: '头条搜索',
    searchUrl: 'https://so.toutiao.com/search?keyword={query}',
    homeUrl: 'https://so.toutiao.com',
    icon: '📰'
  }
]
