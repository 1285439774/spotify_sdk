import 'package:flutter/material.dart';
import 'package:spotify_sdk/models/list_item.dart';
import 'package:spotify_sdk/models/list_items.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk_example/queue_content_page.dart';

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


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return  Scaffold(
      appBar: AppBar(title: Text('Recommended Content')),
      body: ListView.separated(
        itemCount: contentItems.items.length,
        itemBuilder: (context, index) {
          final item = contentItems.items[index];
          return ListTile(
            title: Text("${item.title}"),
            onTap: () => _onItemTap(context, item),
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