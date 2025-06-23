import 'package:video_app/services/aliyun_vod_service.dart';

class VodService {
  // 获取视频列表（包含你的真实视频）
  static Future<List<Map<String, dynamic>>> getVideoList() async {
    try {
      print('开始加载视频列表...');
      
      // 测试阿里云API连接
      final isConnected = await AliyunVodService.testConnection();
      print('阿里云API连接状态: $isConnected');
      
      List<Map<String, dynamic>> videoList = [];
      
      // 添加你的真实阿里云视频
      String? realVideoUrl = await AliyunVodService.getVideoPlayUrl('10db3c3c3add71f0bfed6733a68f0102');
      
      videoList.add({
        'id': '1',
        'videoId': '10db3c3c3add71f0bfed6733a68f0102',
        'title': '我的阿里云视频',
        'url': realVideoUrl ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4', // 如果获取失败使用备用视频
        'thumbnail': 'https://picsum.photos/300/200?random=1',
        'duration': '2:30',
        'views': '1.2万',
        'description': realVideoUrl != null ? '成功加载阿里云视频' : '阿里云视频加载失败，显示测试视频',
        'isRealVideo': realVideoUrl != null,
      });
      
      // 添加其他测试视频
      videoList.addAll([
        {
          'id': '2',
          'videoId': 'demo_video_2',
          'title': 'Flutter官方测试视频',
          'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=2',
          'duration': '0:10',
          'views': '8.5千',
          'description': 'Flutter官方测试视频 - 蜜蜂采蜜',
          'isRealVideo': false,
        },
        {
          'id': '3',
          'videoId': 'demo_video_3',
          'title': '样例视频3',
          'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=3',
          'duration': '0:15',
          'views': '2.1万',
          'description': 'Flutter官方测试视频 - 蝴蝶',
          'isRealVideo': false,
        },
        {
          'id': '4',
          'videoId': 'demo_video_4',
          'title': '网络测试视频',
          'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_360x240_1mb.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=4',
          'duration': '0:30',
          'views': '5.8千',
          'description': '网络测试视频 - 低分辨率',
          'isRealVideo': false,
        },
        {
          'id': '5',
          'videoId': 'demo_video_5',
          'title': '高清测试视频',
          'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_640x360_1mb.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=5',
          'duration': '0:30',
          'views': '3.7万',
          'description': '网络测试视频 - 标清分辨率',
          'isRealVideo': false,
        },
        {
          'id': '6',
          'videoId': 'demo_video_6',
          'title': '备用测试视频',
          'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=6',
          'duration': '0:30',
          'views': '9.2千',
          'description': '网络测试视频 - 高清分辨率',
          'isRealVideo': false,
        },
      ]);
      
      print('视频列表加载完成，共${videoList.length}个视频');
      return videoList;
    } catch (e) {
      print('获取视频列表失败: $e');
      
      // 如果完全失败，返回基础测试视频
      return [
        {
          'id': '1',
          'videoId': '10db3c3c3add71f0bfed6733a68f0102',
          'title': '我的阿里云视频（加载失败）',
          'url': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          'thumbnail': 'https://picsum.photos/300/200?random=1',
          'duration': '2:30',
          'views': '1.2万',
          'description': '阿里云视频服务暂时不可用，显示测试视频',
          'isRealVideo': false,
        },
      ];
    }
  }

  // 搜索视频
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

  // 获取单个视频的播放信息
  static Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      print('获取视频信息: $videoId');
      
      if (videoId == '10db3c3c3add71f0bfed6733a68f0102') {
        // 这是你的真实阿里云视频
        final playUrl = await AliyunVodService.getVideoPlayUrl(videoId);
        final playAuth = await AliyunVodService.getVideoPlayAuth(videoId);
        
        return {
          'videoId': videoId,
          'playUrl': playUrl,
          'playAuth': playAuth,
          'hasRealUrl': playUrl != null,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      
      return null;
    } catch (e) {
      print('获取视频信息失败: $e');
      return null;
    }
  }

  // 测试阿里云连接
  static Future<bool> testAliyunConnection() async {
    try {
      return await AliyunVodService.testConnection();
    } catch (e) {
      print('测试连接失败: $e');
      return false;
    }
  }
}