// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart';

import 'message_port.dart';

extension ParametersExt on Parameters {
  /// Read the `'bytes'` key as [Uint8List].
  ///
  /// The `'bytes'` key is the only one allowed to be a `Uint8Array`,
  /// see `pkg/dartpad/doc/worker-protocol.md`.
  Uint8List get bytesAsUint8List {
    final value = this['bytes'].value;
    if (value is Uint8List) {
      return value;
    }

    throw RpcException.invalidParams(
      'Parameter "bytes" for method "$method" must be a Uint8Array',
    );
  }

  /// Read the `'port'` key as [MessagePort].
  ///
  /// The `'port'` key is the only one allowed to be a [MessagePort],
  /// see `pkg/dartpad/doc/worker-protocol.md`.
  MessagePort get portAsMessagePort {
    final value = this['port'].value;
    if (value is MessagePort) {
      return value;
    }
    throw RpcException.invalidParams(
      'Parameter "port" for method "$method" must be a MessagePort',
    );
  }
}
