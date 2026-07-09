// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../dart_tooling_daemon.dart';

part '_connected_app.dart';
part '_file_system.dart';

/// A DTD response that indicates success.
class Success extends _SuccessResponse<Null> {
  const Success();

  factory Success.fromDTDResponse(DTDResponse response) {
    _SuccessResponse._checkResponseType(response, expectedType: _type);
    return const Success();
  }

  @override
  String get type => _type;

  static const _type = 'Success';
}

/// A DTD response that indicates success and contains a single String value.
class StringResponse extends _SuccessResponse<String> {
  const StringResponse(String value) : super(value: value);

  factory StringResponse.fromDTDResponse(DTDResponse response) {
    _SuccessResponse._checkResponseType(response, expectedType: _type);
    final value = response.result[_SuccessResponse._kValue] as String;
    return StringResponse(value);
  }

  @override
  String get type => _type;

  static const _type = 'StringResponse';
}

/// A DTD response that indicates success and contains a single boolean value.
class BoolResponse extends _SuccessResponse<bool> {
  const BoolResponse(bool value) : super(value: value);

  factory BoolResponse.fromDTDResponse(DTDResponse response) {
    _SuccessResponse._checkResponseType(response, expectedType: _type);
    final value = response.result[_SuccessResponse._kValue] as bool;
    return BoolResponse(value);
  }

  @override
  String get type => _type;

  static const _type = 'BoolResponse';
}

/// A DTD response that indicates success and contains a single [List] of
/// [String]s as its value.
class StringListResponse extends _SuccessResponse<List<String>> {
  const StringListResponse(List<String> value) : super(value: value);

  factory StringListResponse.fromDTDResponse(DTDResponse response) {
    _SuccessResponse._checkResponseType(response, expectedType: _type);
    final value =
        (response.result[_SuccessResponse._kValue] as List).cast<String>();
    return StringListResponse(value);
  }

  @override
  String get type => _type;

  static const _type = 'ListResponse';
}

/// A DTD response that indicates success and contains a single optional value
/// with type [T].
abstract class _SuccessResponse<T> {
  const _SuccessResponse({this.value});

  static void _checkResponseType(
    DTDResponse response, {
    required String expectedType,
  }) {
    if (response.result[_SuccessResponse._kType] != expectedType) {
      throw json_rpc.RpcException.invalidParams(
        'Expected ${_SuccessResponse._kType} param to be $expectedType, got: '
        '${response.result[_SuccessResponse._kType]}',
      );
    }
  }

  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the value parameter.
  static const String _kValue = 'value';

  /// The optional value for this response.
  final T? value;

  String get type;

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        _kValue: value,
      };

  @override
  String toString() => '[$type value: $value]';
}

/// A DTD response that contains information about all the registered services
/// available on the Dart Tooling Daemon, including services provided by DTD
/// itself as well as services registered by DTD clients.
class RegisteredServicesResponse {
  const RegisteredServicesResponse({
    required this.dtdServices,
    required this.clientServices,
  });

  factory RegisteredServicesResponse.fromDTDResponse(DTDResponse response) {
    if (response.result[_kType] != type) {
      throw json_rpc.RpcException.invalidParams(
        'Expected $_kType param to be $type, got: ${response.result[_kType]}',
      );
    }
    return RegisteredServicesResponse._fromDTDResponse(response);
  }

  RegisteredServicesResponse._fromDTDResponse(DTDResponse response)
      : dtdServices = List<String>.from(
          (response.result[_kDtdServices] as List).cast<String>(),
        ),
        clientServices = List<Map<String, Object?>>.from(
          (response.result[_kClientServices] as List)
              .cast<Map<String, Object?>>(),
        ).map(ClientServiceInfo.fromJson).toList();

  /// The key for the type parameter.
  static const String _kType = 'type';

  /// The key for the DTD services parameter.
  static const String _kDtdServices = 'dtdServices';

  /// The key for the client services parameter.
  static const String _kClientServices = 'clientServices';

  /// A list of DTD services.
  final List<String> dtdServices;

  /// A list of DTD client services.
  final List<ClientServiceInfo> clientServices;

  static String get type => 'RegisteredServicesResponse';

  Map<String, Object?> toJson() => <String, Object?>{
        _kType: type,
        _kDtdServices: dtdServices,
        _kClientServices:
            clientServices.map((service) => service.toJson()).toList(),
      };

  @override
  String toString() => '['
      '$type '
      'dtdServices: ${dtdServices.toString()}, '
      'clientServices: '
      '${clientServices.map((service) => service.display).toList().toString()}'
      ']';
}

extension on ClientServiceInfo {
  String get display {
    final sb = StringBuffer()
      ..write('$name (')
      ..write(
        methods.values.map((method) {
          final capabilities = method.capabilities != null
              ? ' ${method.capabilities.toString()}'
              : '';
          return '${method.name}$capabilities';
        }).join(', '),
      )
      ..write(')');
    return sb.toString();
  }
}
