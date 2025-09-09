import '../enums/content_type_enum.dart';

/**
 *@date 2025/9/8
 *@author kuang
 */
extension ContentTypeExtension on ContentType{
  static const values = {
    ContentType.autoMotive: "automotive",
    ContentType.defaultValue: "default",
    ContentType.navigation: "navigation",
    ContentType.fitness: "fitness",
    ContentType.wake: "wake",
    ContentType.sleep: "sleep",
  };

  /// returns the value
  ///@nodoc
  String get value => values[this]!;
}