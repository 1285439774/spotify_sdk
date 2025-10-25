/**
 *@date 2025/9/8
 *@author kuang
 */
import 'package:json_annotation/json_annotation.dart';

import 'list_item.dart';

part 'list_items.g.dart';

@JsonSerializable()
class ListItems {
  ListItems({
    required this.limit,
    required this.offset,
    required this.total,
    required this.items,
  });

  @JsonKey(name: 'limit')
  final int limit;

  @JsonKey(name: 'offset')
  final int offset;

  @JsonKey(name: 'total')
  final int total;

  @JsonKey(name: 'items')
  final List<ListItem> items;


  factory ListItems.fromJson(Map<String, dynamic> json) =>
      _$ListItemsFromJson(json);

  Map<String, dynamic> toJson() => _$ListItemsToJson(this);

  factory ListItems.empty() => ListItems(limit: 0, offset: 0, total: 0, items: []);

}
