/**
 *@date 2025/9/8
 *@author kuang
 */
import 'package:json_annotation/json_annotation.dart';

part 'list_item.g.dart';

@JsonSerializable()
class ListItem {
  ListItem({
    required this.hasChildren,
    required this.id,
    this.imageId,
    required this.playable,
    required this.subtitle,
    required this.title,
    required this.uri,
     this.pinnned,
     this.description,
  });

  @JsonKey(name: 'has_children')
  final bool hasChildren;

  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'image_id')
  final ImageId? imageId;

  @JsonKey(name: 'playable')
  final bool playable;

  @JsonKey(name: 'subtitle')
  final String subtitle;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'uri')
  final String uri;

  @JsonKey(name: 'is_pinned')
  final bool? pinnned;

  @JsonKey(name: 'description')
  final String? description;


  factory ListItem.fromJson(Map<String, dynamic> json) =>
      _$ListItemFromJson(json);

  Map<String, dynamic> toJson() => _$ListItemToJson(this);
}

@JsonSerializable()
class ImageId {
  ImageId({
    required this.raw,
  });

  @JsonKey(name: 'raw')
  final String raw;

  factory ImageId.fromJson(Map<String, dynamic> json) =>
      _$ImageIdFromJson(json);

  Map<String, dynamic> toJson() => _$ImageIdToJson(this);

  @override
  String toString() {
    // TODO: implement toString
    return "raw:$raw";
  }
}
