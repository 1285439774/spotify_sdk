// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListItems _$ListItemsFromJson(Map<String, dynamic> json) => ListItems(
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ListItemsToJson(ListItems instance) => <String, dynamic>{
      'limit': instance.limit,
      'offset': instance.offset,
      'total': instance.total,
      'items': instance.items,
    };
