import 'dart:io';

import 'package:flutter/material.dart';
import 'package:spotify_sdk/models/list_item.dart';
import 'package:spotify_sdk/models/list_items.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk_example/queue_content_page.dart';
import 'package:logger/logger.dart';
/**
 *@date 2025/9/8
 *@author kuang
 */
class RecommendedContentItems extends StatelessWidget{
  final ListItems contentItems; // 根据实际类型调整
  final ListItem? currentContentItem;
  RecommendedContentItems({
    required this.contentItems,
    this.currentContentItem,
  });

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


  @override
  Widget build(BuildContext context) {

    return  Scaffold(
      appBar: AppBar(title: Text('Recommended Content')),
      body: ListView.separated(
        itemCount: contentItems.items.length,
        itemBuilder: (context, index) {
          final item = contentItems.items[index];
          // _logger.d("RecommendedContentItems.item:${item.toJson()}");

          return Column(
            children: [
              ListTile(
                title: Text("${item.title}"),
                onTap: () => _onItemTap(context, item),
              )
            ],
          );
        },
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
        ),
      ),
    );
  }


  void _onItemTap(BuildContext context,ListItem item)async {
    // if (item.hasChildren) {
      var childrenItems = await SpotifySdk.getChildrenOfItem(contentItem: item, perpage: 50, offset: 0);
      if (childrenItems != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QueueContentPage(
                  contentItems: childrenItems,
                  title: item.title,
                  currentContentItem: item,
                ),
          ),
        );
      }
    // }
  }
}