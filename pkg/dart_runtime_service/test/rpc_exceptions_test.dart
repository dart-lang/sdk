// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/src/rpc_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('RpcException:', () {
    test(
      'standard RPC exception messages do not end with trailing periods',
      () {
        final exceptionsWithNoTrailingPeriod = [
          RpcException.invalidParams,
          RpcException.serverError,
          RpcException.methodNotFound,
          RpcException.internalError,
          RpcException.connectionDisposed,
          RpcException.featureDisabled,
          RpcException.streamAlreadySubscribed,
          RpcException.streamNotSubscribed,
          RpcException.serviceAlreadyRegistered,
          RpcException.serviceDisappeared,
          RpcException.expressionCompilationError,
        ];

        for (final exception in exceptionsWithNoTrailingPeriod) {
          expect(
            exception.message.endsWith('.'),
            isFalse,
            reason:
                '${exception.name} message "${exception.message}" '
                'should not end with a period.',
          );
        }
      },
    );
  });
}
