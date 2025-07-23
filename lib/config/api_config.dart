// lib/config/api_config.dart - 确保生产配置正确
class ApiConfig {
  // 🚀 发布时确保设置为 false！
  static const bool isDebug = false;
  
  // 环境配置
  static const String _localBaseUrl = 'http://localhost:3000/api';
  static const String _productionBaseUrl = '/api'; 
  
  static String get baseUrl {
    final url = isDebug ? _localBaseUrl : _productionBaseUrl;
    // 🔧 生产环境移除调试日志
    if (isDebug) {
      print('🌐 当前使用的API地址: $url');
    }
    return url;
  }
  
  // API端点
  static String get videosUrl => '$baseUrl/videos';
  static String videoPlayUrl(int videoId) => '$baseUrl/videos/$videoId/play';
  static String videoViewsUrl(int videoId) => '$baseUrl/videos/$videoId/views';
  static String searchUrl(String keyword) => '$baseUrl/videos/search/$keyword';
  
  // 生产配置优化
  static const int timeoutSeconds = 15; // 减少超时时间
  static const int defaultPageSize = 20;
  static const int maxRetries = 2; // 减少重试次数
  
  // 应用信息
  static const String appName = 'Live1973';
  static const String appVersion = '1.0.0';
  static const String userAgent = '$appName/$appVersion (Android)';
}