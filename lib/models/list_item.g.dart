// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListItem _$ListItemFromJson(Map<String, dynamic> json) => ListItem(
      hasChildren: json['has_children'] as bool,
      id: json['id'] as String,
      imageId: json['image_id'] == null
          ? null
          : ImageId.fromJson(json['image_id'] as Map<String, dynamic>),
      playable: json['playable'] as bool,
      subtitle: json['subtitle'] as String,
      title: json['title'] as String,
      uri: json['uri'] as String,
      pinnned: json['is_pinned'] as bool?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ListItemToJson(ListItem instance) => <String, dynamic>{
      'has_children': instance.hasChildren,
      'id': instance.id,
      'image_id': instance.imageId,
      'playable': instance.playable,
      'subtitle': instance.subtitle,
      'title': instance.title,
      'uri': instance.uri,
      'is_pinned': instance.pinnned,
      'description': instance.description,
    };

ImageId _$ImageIdFromJson(Map<String, dynamic> json) => ImageId(
      raw: json['raw'] as String,
    );

Map<String, dynamic> _$ImageIdToJson(ImageId instance) => <String, dynamic>{
      'raw': instance.raw,
    };
