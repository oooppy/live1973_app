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

  // 记录播放
  Future<void> recordView(int videoId, {int durationWatched = 0}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/view'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'device_type': 'mobile',
          'duration_watched': durationWatched,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // 更新本地播放次数
          final videoIndex = _videos.indexWhere((v) => v['id'] == videoId);
          if (videoIndex != -1) {
            _videos[videoIndex]['viewCount'] = data['data']['new_view_count'];
            _videos[videoIndex]['views'] = _formatViewCount(data['data']['new_view_count']);
            notifyListeners();
          }
          print('播放记录成功: ${data['message']}');
        }
      }
    } catch (e) {
      print('记录播放失败: $e');
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