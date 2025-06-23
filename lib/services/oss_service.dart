import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

class OSSService {
  static const String _accessKeyId = 'YOUR_ACCESS_KEY_ID';
  static const String _accessKeySecret = 'YOUR_ACCESS_KEY_SECRET';
  static const String _endpoint = 'oss-cn-shanghai.aliyuncs.com';
  static const String _bucketName = 'outin-f07b6cbb3ad911f0947a00163e14b633';

  static Future<void> initialize() async {
    try {
      // 使用tokenGetter方式初始化（适配2.0.3版本）
      Client.init(
        ossEndpoint: _endpoint,
        bucketName: _bucketName,
        tokenGetter: _tokenGetter,
      );
      
      print('OSS初始化成功');
    } catch (e) {
      print('OSS初始化失败: $e');
    }
  }

  // 返回JSON格式的token信息
  static Future<String> _tokenGetter() async {
    return '''
    {
      "AccessKeyId": "$_accessKeyId",
      "AccessKeySecret": "$_accessKeySecret",
      "SecurityToken": "",
      "Expiration": "2025-12-31T23:59:59Z"
    }
    ''';
  }

  static Future<List<Map<String, dynamic>>> getVideoList() async {
    try {
      return [
        {
          'id': '1',
          'title': '美丽的日落',
          'url': 'https://$_bucketName.$_endpoint/videos/sunset.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=1',
          'duration': '2:30',
          'views': '1.2万',
        },
        {
          'id': '2',
          'title': '城市夜景',
          'url': 'https://$_bucketName.$_endpoint/videos/city_night.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=2',
          'duration': '1:45',
          'views': '8.5千',
        },
        {
          'id': '3',
          'title': '自然风光',
          'url': 'https://$_bucketName.$_endpoint/videos/nature.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=3',
          'duration': '3:15',
          'views': '2.1万',
        },
        {
          'id': '4',
          'title': '海边漫步',
          'url': 'https://$_bucketName.$_endpoint/videos/beach.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=4',
          'duration': '2:00',
          'views': '5.8千',
        },
        {
          'id': '5',
          'title': '山间小径',
          'url': 'https://$_bucketName.$_endpoint/videos/mountain.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=5',
          'duration': '4:20',
          'views': '3.7万',
        },
        {
          'id': '6',
          'title': '花园美景',
          'url': 'https://$_bucketName.$_endpoint/videos/garden.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=6',
          'duration': '1:30',
          'views': '9.2千',
        },
      ];
    } catch (e) {
      print('获取视频列表失败: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchVideos(String keyword) async {
    try {
      final allVideos = await getVideoList();
      return allVideos.where((video) => 
        video['title'].toString().toLowerCase().contains(keyword.toLowerCase())
      ).toList();
    } catch (e) {
      print('搜索视频失败: $e');
      return [];
    }
  }

  // 从OSS获取实际文件列表（功能待实现）
  // 注意：当前版本的flutter_oss_aliyun可能不支持listFiles方法
  // 实际项目中可以通过服务器API或其他方式获取视频列表
  static Future<List<Map<String, dynamic>>> getVideoListFromOSS() async {
    try {
      // TODO: 实现真实的OSS文件列表获取
      // 可以通过服务器端API获取文件列表，或使用其他OSS SDK版本
      
      print('从OSS获取文件列表功能待实现');
      return getVideoList(); // 暂时返回示例数据
    } catch (e) {
      print('从OSS获取视频列表失败: $e');
      return getVideoList();
    }
  }
}