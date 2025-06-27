import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/video_player_screen.dart';

// 🔧 改为 StatefulWidget 来支持 setState
class VideoCard extends StatefulWidget {
  final int? videoId; // 视频数据库ID
  final String title;
  final String thumbnail;
  final String videoUrl;
  final String duration;
  final String views;
  final bool isRealVideo;
  final VoidCallback? onTap;

  const VideoCard({
    super.key,
    this.videoId,
    required this.title,
    required this.thumbnail,
    required this.videoUrl,
    required this.duration,
    required this.views,
    this.isRealVideo = true,
    this.onTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

// 🔧 添加 State 类
class _VideoCardState extends State<VideoCard> {
  bool isLoading = false; // 🔧 添加 loading 状态
  DateTime? _lastTapTime; // 🔧 添加防重复点击时间记录

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
        _handleVideoTap(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图部分
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildThumbnail(),
                  ),
                ),
                // 播放按钮和加载状态
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : const Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 50,
                            ),
                    ),
                  ),
                ),
                // 时长标签
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // VOD视频标签
                if (widget.videoId != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VOD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 视频信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.views} 次播放',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (widget.videoId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            '云端',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (widget.thumbnail.isNotEmpty && 
        (widget.thumbnail.startsWith('http') || widget.thumbnail.startsWith('https'))) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnail,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.red,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Live1973',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 修复后的视频点击处理方法
  void _handleVideoTap(BuildContext context) async {
    // 🔧 防重复点击检查
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 1000) {
      print('🚫 防重复点击：忽略快速连续点击');
      return;
    }
    _lastTapTime = now;
    
    print('🎬 VideoCard被点击，videoId: ${widget.videoId}');
    
    if (isLoading) {
      print('🚫 正在处理中，忽略重复点击');
      return;
    }
    
    setState(() {
      isLoading = true;
    });

    try {
      String? actualPlayUrl;
      
      // 🔧 检查是否是VOD视频（有videoId）
      if (widget.videoId != null) {
        print('🎯 VOD视频，使用API获取播放地址...');
        actualPlayUrl = await _getVodPlayUrl(widget.videoId!);
      } else {
        print('🎯 本地视频，直接使用URL');
        actualPlayUrl = widget.videoUrl;
      }

      if (actualPlayUrl != null && actualPlayUrl.isNotEmpty) {
        print('🚀 准备导航到播放器');
        print('🎬 videoId: ${widget.videoId}');
        print('🎬 playUrl: $actualPlayUrl');
        
        // 🔧 删除重复的播放数记录，让VideoProvider处理
        // if (widget.videoId != null) {
        //   print('📞 记录播放数...');
        //   await _recordView(widget.videoId!);
        //   print('✅ 播放数记录完成');
        // }
        
        // 导航到播放器
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: actualPlayUrl!,
              title: widget.title,
              thumbnail: widget.thumbnail,
              videoId: widget.videoId,
            ),
          ),
        );
        
        print('🔙 从播放器返回');
        
      } else {
        print('❌ 无法获取播放地址');
        _showErrorSnackBar(context, '无法获取视频播放地址');
      }
    } catch (e) {
      print('❌ 处理视频点击失败: $e');
      _showErrorSnackBar(context, '播放视频时出错: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 🔧 获取VOD播放地址
  Future<String?> _getVodPlayUrl(int videoId) async {
    try {
      print('📡 请求VOD播放地址: http://localhost:3000/api/videos/$videoId/play');
      
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/videos/$videoId/play'),
      );
      
      print('📊 VOD API响应状态: ${response.statusCode}');
      print('📊 VOD API响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // 🔧 正确解析嵌套的JSON结构
        if (responseData['success'] == true && responseData['data'] != null) {
          final playUrl = responseData['data']['playUrl'];
          print('✅ 获取到VOD播放地址: $playUrl');
          return playUrl;
        } else {
          print('❌ API返回格式错误或success不为true');
          print('❌ 响应数据: $responseData');
          return null;
        }
      } else {
        print('❌ 获取播放地址失败: ${response.statusCode}');
        print('❌ 错误响应: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 获取播放地址异常: $e');
      print('❌ 异常类型: ${e.runtimeType}');
      return null;
    }
  }

  // 🔧 记录播放数
  Future<void> _recordView(int videoId) async {
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:3000/api/videos/$videoId/views'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 播放数更新成功: ${data['message']}');
      } else {
        print('❌ 播放数更新失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 记录播放数异常: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}