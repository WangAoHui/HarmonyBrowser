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

// 标签页数据模型
export interface TabItem {
  id: string
  url: string
  title: string
  isActive: boolean
  createdAt: number
}

// 主题模式
export type ThemeMode = 'light' | 'dark' | 'system'

// 主题配置
export interface ThemeConfig {
  mode: ThemeMode
  primaryColor: string      // 主色调
  backgroundColor: string   // 背景色
  surfaceColor: string       // 卡片/面板色
  textColor: string          // 主文字色
  subTextColor: string       // 次文字色
  borderColor: string        // 边框色
}

// 密码记录数据模型
export interface PasswordItem {
  id: string
  url: string
  username: string
  password: string
  title: string
  createdAt: number
  updatedAt: number
}

// 广告拦截规则
export interface AdBlockRule {
  id: string
  pattern: string       // URL 匹配模式（支持 * 通配符）
  enabled: boolean
  isBuiltIn: boolean    // 是否内置规则
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

// 预置主题
export const THEME_PRESETS: Record<string, ThemeConfig> = {
  light: {
    mode: 'light',
    primaryColor: '#3B82F6',
    backgroundColor: '#FFFFFF',
    surfaceColor: '#F3F4F6',
    textColor: '#333333',
    subTextColor: '#888888',
    borderColor: '#E5E7EB'
  },
  dark: {
    mode: 'dark',
    primaryColor: '#60A5FA',
    backgroundColor: '#1A1A2E',
    surfaceColor: '#25253E',
    textColor: '#E5E7EB',
    subTextColor: '#9CA3AF',
    borderColor: '#374151'
  },
  midnight: {
    mode: 'dark',
    primaryColor: '#818CF8',
    backgroundColor: '#0F0F1A',
    surfaceColor: '#1E1E30',
    textColor: '#E2E8F0',
    subTextColor: '#94A3B8',
    borderColor: '#334155'
  },
  ocean: {
    mode: 'dark',
    primaryColor: '#22D3EE',
    backgroundColor: '#0C1222',
    surfaceColor: '#162032',
    textColor: '#E0F2FE',
    subTextColor: '#7DD3FC',
    borderColor: '#1E3A5F'
  }
}

// 内置广告拦截规则
export const BUILT_IN_AD_RULES: AdBlockRule[] = [
  { id: 'doubleclick', pattern: '*doubleclick.net*', enabled: true, isBuiltIn: true },
  { id: 'googleads', pattern: '*googlesyndication.com*', enabled: true, isBuiltIn: true },
  { id: 'googleadservices', pattern: '*googleadservices.com*', enabled: true, isBuiltIn: true },
  { id: 'adnxs', pattern: '*adnxs.com*', enabled: true, isBuiltIn: true },
  { id: 'adsrvr', pattern: '*adsrvr.org*', enabled: true, isBuiltIn: true },
  { id: 'taboola', pattern: '*taboola.com*', enabled: true, isBuiltIn: true },
  { id: 'outbrain', pattern: '*outbrain.com*', enabled: true, isBuiltIn: true },
  { id: 'popads', pattern: '*popads.net*', enabled: true, isBuiltIn: true },
  { id: 'adroll', pattern: '*adroll.com*', enabled: true, isBuiltIn: true },
  { id: 'criteo', pattern: '*criteo.com*', enabled: true, isBuiltIn: true },
  { id: 'baidu_ads', pattern: '*pos.baidu.com*', enabled: true, isBuiltIn: true },
  { id: 'baidu_ads2', pattern: '*cbjs.baidu.com*', enabled: true, isBuiltIn: true },
  { id: 'baidu_ads3', pattern: '*cpro.baidu.com*', enabled: true, isBuiltIn: true },
  { id: 'tanx', pattern: '*tanx.com*', enabled: true, isBuiltIn: true },
  { id: 'mmstat', pattern: '*mmstat.com*', enabled: true, isBuiltIn: true },
  { id: 'umeng', pattern: '*umeng.com*', enabled: true, isBuiltIn: true },
  { id: 'cnzz', pattern: '*cnzz.com*', enabled: true, isBuiltIn: true },
  { id: 'ads_js', pattern: '*/ad.js*', enabled: true, isBuiltIn: true },
  { id: 'ads_banner', pattern: '*/banner*.js*', enabled: true, isBuiltIn: true },
  { id: 'ads_popup', pattern: '*/popup*.js*', enabled: true, isBuiltIn: true },
]
