// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionStatus _$ConnectionStatusFromJson(Map<String, dynamic> json) {
  if (kReleaseMode) {
    return ConnectionStatus(
      json['b'] as String?,
      json['c'] as String?,
      json['d'] as String?,
      connected: json['a'] as bool,
    );
  } else {
    return ConnectionStatus(
      json['message'] as String?,
      json['errorCode'] as String?,
      json['errorDetails'] as String?,
      connected: json['connected'] as bool,
    );
  }
}

Map<String, dynamic> _$ConnectionStatusToJson(ConnectionStatus instance) =>
    <String, dynamic>{
      'connected': instance.connected,
      'message': instance.message,
      'errorCode': instance.errorCode,
      'errorDetails': instance.errorDetails,
    };
