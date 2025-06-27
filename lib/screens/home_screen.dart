import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🔧 搜索功能开关 - 改为true可恢复搜索功能
  static const bool _enableSearch = false;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 初始化时获取视频数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().fetchVideos(refresh: true);
    });
    
    // 监听滚动，实现分页加载
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // 距离底部200像素时加载更多
      context.read<VideoProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Live1973',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 🔧 条件显示搜索按钮
          if (_enableSearch) 
            IconButton(
              onPressed: () => _showSearch(context),
              icon: const Icon(Icons.search, color: Colors.white),
            ),
          IconButton(
            onPressed: () {
              context.read<VideoProvider>().refresh();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          // 显示错误信息
          if (videoProvider.error != null && videoProvider.videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    videoProvider.error!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      videoProvider.clearError();
                      videoProvider.fetchVideos(refresh: true);
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          // 首次加载中
          if (videoProvider.isLoading && videoProvider.videos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    '正在加载视频...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 显示视频列表
          return RefreshIndicator(
            onRefresh: () => videoProvider.refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: videoProvider.videos.length + 
                         (videoProvider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // 加载更多指示器
                if (index == videoProvider.videos.length) {
                  if (videoProvider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    );
                  } else if (!videoProvider.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          '已加载全部视频',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final video = videoProvider.videos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: VideoCard(
                    videoId: video['id'], // 🔧 添加这一行
                    title: video['title'] ?? '未知标题',
                    thumbnail: video['thumbnail'] ?? '',
                    videoUrl: video['videoUrl'] ?? '',
                    duration: video['duration'] ?? '00:00',
                    views: video['views'] ?? '0',
                    isRealVideo: video['isRealVideo'] ?? true,
                    onTap: () {
                      // 记录播放
                      if (video['id'] != null) {
                        videoProvider.recordView(video['id']);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showSearch(BuildContext context) {
    // 🔧 只有启用搜索时才显示搜索界面
    if (_enableSearch) {
      showSearch(
        context: context,
        delegate: VideoSearchDelegate(),
      );
    }
  }
}

// 🔧 搜索代理类保留，但只在启用搜索时生效
class VideoSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => '搜索视频...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          '请输入搜索关键词',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<VideoProvider>().searchVideos(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '搜索出错: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(
              child: Text(
                '没有找到相关视频',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: VideoCard(
                  videoId: video['id'], // 🔧 添加这一行
                  title: video['title'] ?? '未知标题',
                  thumbnail: video['thumbnail'] ?? '',
                  videoUrl: video['videoUrl'] ?? '',
                  duration: video['duration'] ?? '00:00',
                  views: video['views'] ?? '0',
                  isRealVideo: video['isRealVideo'] ?? true,
                  onTap: () {
                    close(context, video['title']);
                    if (video['id'] != null) {
                      context.read<VideoProvider>().recordView(video['id']);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          '输入关键词搜索视频',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}