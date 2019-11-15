// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

part of dart.io;

@pragma('vm:entry-point')
abstract class _NetworkProfiling {
  static const _kGetHttpProfileRPC = 'ext.dart.io.getHttpProfile';
  static const _kGetSocketProfileRPC = 'ext.dart.io.getSocketProfile';

  @pragma('vm:entry-point')
  static void _registerServiceExtension() {
    registerExtension(_kGetHttpProfileRPC, _serviceExtensionHandler);
    registerExtension(_kGetSocketProfileRPC, _serviceExtensionHandler);
  }

  static Future<ServiceExtensionResponse> _serviceExtensionHandler(
      String method, Map<String, String> parameters) {
    String responseJson;
    switch (method) {
      case _kGetHttpProfileRPC:
        responseJson = _HttpProfile.toJSON();
        break;
      case _kGetSocketProfileRPC:
        responseJson = _SocketProfile.toJSON();
        break;
      default:
        return Future.value(ServiceExtensionResponse.error(
            ServiceExtensionResponse.extensionError,
            'Method $method does not exist'));
    }
    return Future.value(ServiceExtensionResponse.result(responseJson));
  }
}

abstract class _HttpProfile {
  static const _kType = 'HttpProfile';
  // TODO(bkonyi): implement.
  static String toJSON() {
    final response = <String, dynamic>{
      'type': _kType,
    };
    return json.encode(response);
  }
}

abstract class _SocketProfile {
  static const _kType = 'SocketProfile';
  // TODO(bkonyi): implement.
  static String toJSON() {
    final response = <String, dynamic>{
      'type': _kType,
    };
    return json.encode(response);
  }
}
