import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class AliyunVodService {
  // 你的阿里云配置
  static const String _accessKeyId = 'YOUR_ACCESS_KEY_ID';
  static const String _accessKeySecret = 'YOUR_ACCESS_KEY_SECRET';
  static const String _regionId = 'cn-shanghai';
  
  static final Dio _dio = Dio();

  // 获取视频播放凭证
  static Future<String?> getVideoPlayAuth(String videoId) async {
    try {
      print('正在获取视频播放凭证...');
      print('VideoId: $videoId');

      // 构建请求参数
      final params = <String, String>{
        'Action': 'GetVideoPlayAuth',
        'VideoId': videoId,
        'AccessKeyId': _accessKeyId,
        'SignatureMethod': 'HMAC-SHA1',
        'Timestamp': _getTimestamp(),
        'SignatureVersion': '1.0',
        'SignatureNonce': _generateNonce(),
        'Version': '2017-03-21',
        'Format': 'JSON',
      };

      // 生成签名
      final signature = _generateSignature(params, 'GET');
      params['Signature'] = signature;

      // 构建请求URL
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final url = 'https://vod.$_regionId.aliyuncs.com/?$queryString';
      
      print('请求URL: $url');

      final response = await _dio.get(url);
      
      print('API响应状态: ${response.statusCode}');
      print('API响应数据: ${response.data}');

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        
        if (data.containsKey('PlayAuth')) {
          print('获取PlayAuth成功');
          return data['PlayAuth'];
        } else if (data.containsKey('Code')) {
          print('API错误: ${data['Code']} - ${data['Message']}');
          return null;
        }
      }
      
      return null;
    } catch (e) {
      print('获取视频播放凭证失败: $e');
      return null;
    }
  }

  // 获取视频播放信息
  static Future<Map<String, dynamic>?> getVideoPlayInfo(String videoId) async {
    try {
      print('正在获取视频播放信息...');

      // 构建请求参数
      final params = <String, String>{
        'Action': 'GetPlayInfo',
        'VideoId': videoId,
        'AccessKeyId': _accessKeyId,
        'SignatureMethod': 'HMAC-SHA1',
        'Timestamp': _getTimestamp(),
        'SignatureVersion': '1.0',
        'SignatureNonce': _generateNonce(),
        'Version': '2017-03-21',
        'Format': 'JSON',
        'Formats': 'mp4',
        'AuthTimeout': '3600', // 1小时有效期
      };

      // 生成签名
      final signature = _generateSignature(params, 'GET');
      params['Signature'] = signature;

      // 构建请求URL
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final url = 'https://vod.$_regionId.aliyuncs.com/?$queryString';
      
      print('请求URL: $url');

      final response = await _dio.get(url);
      
      print('API响应状态: ${response.statusCode}');
      print('API响应数据: ${response.data}');

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        
        if (data.containsKey('PlayInfoList') && data['PlayInfoList']['PlayInfo'] != null) {
          final playInfos = data['PlayInfoList']['PlayInfo'] as List;
          if (playInfos.isNotEmpty) {
            // 返回第一个播放信息（通常是最高质量的）
            return playInfos.first as Map<String, dynamic>;
          }
        } else if (data.containsKey('Code')) {
          print('API错误: ${data['Code']} - ${data['Message']}');
        }
      }
      
      return null;
    } catch (e) {
      print('获取视频播放信息失败: $e');
      return null;
    }
  }

  // 获取视频播放URL
  static Future<String?> getVideoPlayUrl(String videoId) async {
    try {
      // 首先尝试获取播放信息
      final playInfo = await getVideoPlayInfo(videoId);
      
      if (playInfo != null && playInfo.containsKey('PlayURL')) {
        final playUrl = playInfo['PlayURL'] as String;
        print('获取到播放URL: $playUrl');
        return playUrl;
      }

      // 如果播放信息获取失败，尝试获取播放凭证
      final playAuth = await getVideoPlayAuth(videoId);
      if (playAuth != null) {
        print('获取到PlayAuth，需要在客户端解析播放地址');
        // 注意：PlayAuth需要使用阿里云播放器SDK来解析实际播放地址
        // 在web环境中比较复杂，这里返回null
        return null;
      }

      return null;
    } catch (e) {
      print('获取视频播放URL失败: $e');
      return null;
    }
  }

  // 生成时间戳
  static String _getTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // 生成随机数
  static String _generateNonce() {
    final random = Random();
    return random.nextInt(1000000).toString() + DateTime.now().millisecondsSinceEpoch.toString();
  }

  // 生成阿里云API签名
  static String _generateSignature(Map<String, String> params, String method) {
    // 移除Signature参数（如果存在）
    final sortedParams = Map<String, String>.from(params);
    sortedParams.remove('Signature');

    // 按参数名排序
    final sortedEntries = sortedParams.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // 构建查询字符串
    final queryString = sortedEntries
        .map((e) => '${_percentEncode(e.key)}=${_percentEncode(e.value)}')
        .join('&');

    // 构建待签名字符串
    final stringToSign = '$method&${_percentEncode('/')}&${_percentEncode(queryString)}';
    
    print('待签名字符串: $stringToSign');

    // 计算签名
    final key = utf8.encode('${_accessKeySecret}&');
    final bytes = utf8.encode(stringToSign);
    final hmacSha1 = Hmac(sha1, key);
    final digest = hmacSha1.convert(bytes);

    return base64.encode(digest.bytes);
  }

  // URL编码
  static String _percentEncode(String value) {
    return Uri.encodeComponent(value)
        .replaceAll('+', '%20')
        .replaceAll('*', '%2A')
        .replaceAll('%7E', '~');
  }

  // 测试API连接
  static Future<bool> testConnection() async {
    try {
      print('测试阿里云点播API连接...');
      
      // 使用DescribePlayVideoStatis来测试连接（这个API对所有用户开放）
      final params = <String, String>{
        'Action': 'DescribePlayVideoStatis',
        'AccessKeyId': _accessKeyId,
        'SignatureMethod': 'HMAC-SHA1',
        'Timestamp': _getTimestamp(),
        'SignatureVersion': '1.0',
        'SignatureNonce': _generateNonce(),
        'Version': '2017-03-21',
        'Format': 'JSON',
        'StartTime': DateTime.now().subtract(Duration(days: 1)).toUtc().toIso8601String(),
        'EndTime': DateTime.now().toUtc().toIso8601String(),
      };

      final signature = _generateSignature(params, 'GET');
      params['Signature'] = signature;

      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final url = 'https://vod.$_regionId.aliyuncs.com/?$queryString';

      final response = await _dio.get(url);
      
      print('测试API响应: ${response.statusCode}');
      print('测试API数据: ${response.data}');

      return response.statusCode == 200;
    } catch (e) {
      print('API连接测试失败: $e');
      return false;
    }
  }
}