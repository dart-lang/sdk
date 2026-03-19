// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import 'native_bindings.dart';

/// Implementations of RPCs specific to the VM service that are not handled
/// in runtime/vm/service.cc.
final class DartRuntimeServiceVmRpcs {
  final _logger = Logger('$DartRuntimeServiceVmRpcs');
  final _nativeBindings = NativeBindings();

  late final rpcs = UnmodifiableListView<ServiceRpcHandler>([
    ('getSupportedProtocols', getSupportedProtocols),
  ]);

  /// Returns the list of protocols implemented by the service.
  ///
  /// VM service middleware like DDS should intercept this RPC and add their
  /// own information to the response.
  Future<RpcResponse> getSupportedProtocols() async {
    final version = Version.parse(
      await _nativeBindings.sendToVM(method: 'getVersion', params: const {}),
    );
    if (version == null) {
      _logger.warning('Unable to retrieve version for getSupportedProtocols.');
      RpcException.internalError.throwException();
    }

    return ProtocolList(
      protocols: [
        Protocol(
          protocolName: 'VM Service',
          major: version.major,
          minor: version.minor,
        ),
      ],
    ).toJson();
  }
}
