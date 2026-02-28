class ApiConfig {
  static const String baseUrl = 'https://ik.tiwat.cn';
  static const Duration timeout = Duration(seconds: 60);
  static const int defaultPageSize = 20;
  
  // 网站基础URL，用于生成分享链接
  // 生产环境使用实际域名，开发/测试环境可以修改为本地地址
  static const String webBaseUrl = 'https://tiwat.cn';
}
