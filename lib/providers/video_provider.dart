import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // API基础URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  List<Map<String, dynamic>> get videos => _videos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // 从API获取视频列表
  Future<void> fetchVideos({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _currentPage = 1;
      _videos.clear();
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos?page=$_currentPage&limit=20&sort=view_count'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 修改这里：直接处理数组响应
        if (data is List) {
          // 后端直接返回数组
          final List<dynamic> newVideos = data;

          // 转换API数据格式为前端需要的格式
          List<Map<String, dynamic>> formattedVideos = newVideos.map((video) {
            return {
              'id': video['id'],
              'title': video['title'] ?? '未知标题',
              'thumbnail': video['thumbnail_url'] ?? 'https://via.placeholder.com/320x180?text=Live1973',
              'videoUrl': video['video_url'] ?? '',
              'duration': _formatDuration(video['duration'] ?? 0),
              'views': _formatViewCount(video['view_count'] ?? 0),
              'viewCount': video['view_count'] ?? 0,
              'isRealVideo': video['video_url']?.isNotEmpty ?? false,
              'description': video['description'] ?? '',
              'status': video['status'] ?? 'active',
            };
          }).toList();

          if (refresh) {
            _videos = formattedVideos;
          } else {
            _videos.addAll(formattedVideos);
          }

          _currentPage++;
          // 由于后端直接返回数组，我们假设如果返回的视频少于limit，就没有更多了
          _hasMore = newVideos.length >= 20;
        } else if (data is Map && data['success'] == true) {
          // 如果后端返回的是包装格式（兼容性处理）
          final List<dynamic> newVideos = data['data']['videos'];
          final pagination = data['data']['pagination'];

          List<Map<String, dynamic>> formattedVideos = newVideos.map((video) {
            return {
              'id': video['id'],
              'title': video['title'] ?? '未知标题',
              'thumbnail': video['thumbnail_url'] ?? 'https://via.placeholder.com/320x180?text=Live1973',
              'videoUrl': video['video_url'] ?? '',
              'duration': _formatDuration(video['duration'] ?? 0),
              'views': _formatViewCount(video['view_count'] ?? 0),
              'viewCount': video['view_count'] ?? 0,
              'isRealVideo': video['video_url']?.isNotEmpty ?? false,
              'description': video['description'] ?? '',
              'status': video['status'] ?? 'active',
            };
          }).toList();

          if (refresh) {
            _videos = formattedVideos;
          } else {
            _videos.addAll(formattedVideos);
          }

          _currentPage++;
          _hasMore = _currentPage <= pagination['total_pages'];
        } else {
          _error = data['error'] ?? '获取视频列表失败';
        }
      } else {
        _error = '服务器错误 (${response.statusCode})';
      }
    } catch (e) {
      _error = '网络连接失败: $e';
      print('获取视频列表错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取单个视频详情
  Future<Map<String, dynamic>?> getVideoDetail(int videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      print('获取视频详情错误: $e');
    }
    return null;
  }

  // 记录播放数
  Future<void> recordView(dynamic videoId) async {
    try {
      print('🎬 recordView被调用 - videoId: $videoId (类型: ${videoId.runtimeType})');
      
      if (videoId == null) {
        print('❌ videoId 为 null，无法记录播放');
        return;
      }
      
      final String id = videoId.toString();
      final url = '$baseUrl/videos/$id/views';
      
      print('📡 发送PATCH请求到: $url');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 响应状态码: ${response.statusCode}');
      print('📊 响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 播放数更新成功!');
        
        if (data['data'] != null) {
          final responseData = data['data'];
          print('📈 播放数变化: ${responseData['oldViewCount']} → ${responseData['newViewCount']}');
          
          // 更新本地数据
          _updateLocalViewCount(id, responseData['newViewCount']);
        }
        
        // 通知UI更新
        notifyListeners();
        
      } else {
        print('❌ 播放数更新失败: ${response.statusCode}');
        print('❌ 错误内容: ${response.body}');
      }
    } catch (error) {
      print('❌ recordView发生异常: $error');
      print('❌ 异常类型: ${error.runtimeType}');
    }
  }
  
  // 更新本地视频列表中的播放数
  void _updateLocalViewCount(String videoId, int newViewCount) {
    try {
      print('🔄 更新本地播放数 - videoId: $videoId, newCount: $newViewCount');
      
      for (int i = 0; i < _videos.length; i++) {
        final video = _videos[i];
        if (video['id'].toString() == videoId) {
          print('📝 找到视频，更新播放数: ${video['title'] ?? video['Title']}');
          
          // 创建新的视频对象以触发UI更新
          Map<String, dynamic> updatedVideo = Map<String, dynamic>.from(video);
          updatedVideo['view_count'] = newViewCount;
          updatedVideo['views'] = newViewCount.toString();
          
          _videos[i] = updatedVideo;
          print('✅ 本地播放数已更新');
          break;
        }
      }
    } catch (error) {
      print('❌ 更新本地播放数失败: $error');
    }
  }
  
  // 刷新单个视频的播放数（从服务器获取最新数据）
  Future<void> refreshVideoViewCount(dynamic videoId) async {
    try {
      print('🔄 刷新视频播放数: $videoId');
      
      final String id = videoId.toString();
      final url = '$baseUrl/videos/$id/views';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final viewCount = data['data']['viewCount'];
          print('📊 从服务器获取的最新播放数: $viewCount');
          
          _updateLocalViewCount(id, viewCount);
          notifyListeners();
        }
      } else {
        print('❌ 刷新播放数失败: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ 刷新播放数异常: $error');
    }
  }

  // 搜索视频
  Future<List<Map<String, dynamic>>> searchVideos(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/search/$keyword'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> searchResults = data['data']['videos'];
          return searchResults.map((video) {
            return {
              'id': video['id'],
              'title': video['title'] ?? '未知标题',
              'thumbnail': video['thumbnail_url'] ?? 'https://via.placeholder.com/320x180?text=Live1973',
              'videoUrl': video['video_url'] ?? '',
              'duration': _formatDuration(video['duration'] ?? 0),
              'views': _formatViewCount(video['view_count'] ?? 0),
              'viewCount': video['view_count'] ?? 0,
              'isRealVideo': video['video_url']?.isNotEmpty ?? false,
            };
          }).toList();
        }
      }
    } catch (e) {
      print('搜索视频错误: $e');
    }
    return [];
  }

  // 格式化时长（秒 -> mm:ss）
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 格式化播放量显示
  String _formatViewCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  // 刷新数据
  Future<void> refresh() async {
    await fetchVideos(refresh: true);
  }

  // 加载更多数据
  Future<void> loadMore() async {
    if (_hasMore && !_isLoading) {
      await fetchVideos(refresh: false);
    }
  }

  // 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 重置状态
  void reset() {
    _videos.clear();
    _currentPage = 1;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}