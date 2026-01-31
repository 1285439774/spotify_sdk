import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/models/list_item.dart';
import 'package:spotify_sdk/models/list_items.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class QueueContentPage extends StatelessWidget {
  final ListItems contentItems; // 根据实际类型调整
  final ListItem? currentContentItem;
  final String title;
  final Logger _logger = Logger(
    //filter: CustomLogFilter(), // custom logfilter can be used to have logs in release mode
    printer: PrettyPrinter(
      methodCount: 2, // number of method calls to be displayed
      errorMethodCount: 8, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
    ),
  );
   QueueContentPage({Key? key, required this.contentItems,this.title = 'Queue Content' , this.currentContentItem}) : super(key: key);
  final Map<int, Widget> _widgetCache = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recommended Content')),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 每行两个元素
          childAspectRatio: 0.8, // 调整宽高比以适应上图下字布局
          crossAxisSpacing: 8, // 列间距
          mainAxisSpacing: 8, // 行间距
        ),
        itemCount: contentItems.items.length,
        itemBuilder: (context, index) {
          // 检查缓存中是否已存在该 widget
          if (_widgetCache.containsKey(index)) {
            return _widgetCache[index]!;
          }

          // 创建新的 widget 并缓存
          final item = contentItems.items[index];
          final widgetItem = _buildGridItem(context,item, index);
          _widgetCache[index] = widgetItem;
          return widgetItem;
        },
      )
      ,
    );
  }
  Widget _buildGridItem(BuildContext context,ListItem item, int index) {
    return GestureDetector(
      onTap: () => _onItemTap(context,item),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图片部分
            Expanded(
              child: spotifyImageWidget(item),
            ),
            // 文字部分
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.title ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _onItemTap(BuildContext context,ListItem item)async {
    // 根据点击的项目类型跳转到不同页面
    _logger.d("item:${item.toJson()}");
    if (item.playable) {
      // 播放内容页
      await SpotifySdk.playContentItem(contentItem: item);
    }

    if(item.hasChildren || !item.id.contains("track")) {
      var childrenItems = await SpotifySdk.getChildrenOfItem(
          contentItem: item, perpage: 50,offset: 0);
      if (childrenItems != null) {
        print("childrenItems.total:${childrenItems.total}");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QueueContentPage(
                  contentItems: childrenItems,
                  title: item.title,
                ),
          ),
        );
      }
    }
  }

  Widget spotifyImageWidget(ListItem item) {
    return FutureBuilder(
        future: Platform.isAndroid ?SpotifySdk.getImage2(
          raw: item.imageId!.raw,
          dimension: ImageDimension.large,
        ) : SpotifySdk.getImageForContentItem(
          spotifyContentItemId: item.id,
          spotifyUri: item.uri,
          dimension: ImageDimension.large,
        ) ,
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!);
          } else if (snapshot.hasError) {
            return SizedBox(
              width: ImageDimension.large.value.toDouble(),
              height: ImageDimension.large.value.toDouble(),
              child: const Center(child: Text('Error getting image')),
            );
          } else {
            return SizedBox(
              width: ImageDimension.large.value.toDouble(),
              height: ImageDimension.large.value.toDouble(),
              child: const Center(child: Text('Getting image...')),
            );
          }
        });
  }
}
