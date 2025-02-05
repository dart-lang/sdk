// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart' show vmServiceConnectUri;

import 'common/service_test_common.dart';

final tests = <IsolateTest>[
  hasStoppedAtExit,
  (VmService primaryClient, IsolateRef isolateRef) async {
    const expressionCompilationFailedMessage = 'Expresion compilation failed';

    final secondaryClient = await vmServiceConnectUri(primaryClient.wsUri!);
    secondaryClient.registerServiceCallback('compileExpression',
        (params) async {
      return {
        'jsonrpc': '2.0',
        'id': 0,
        'error': {
          'code': RPCErrorKind.kExpressionCompilationError.code,
          'message': expressionCompilationFailedMessage,
          'data': {'details': expressionCompilationFailedMessage},
        },
      };
    });
    await secondaryClient.registerService(
      'compileExpression',
      'Custom Expression Compilation',
    );

    final isolateId = isolateRef.id!;
    try {
      final isolate = await primaryClient.getIsolate(isolateId);
      await primaryClient.evaluate(isolateId, isolate.rootLib!.id!, '123');
      fail('Expected to catch an RPCError');
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
      // [e.details] used to be the string
      // "{code: 113, message: Expresion compilation failed, data: ...}", so we
      // want to avoid regressing to that behaviour.
      expect(e.details, expressionCompilationFailedMessage);
    }
  },
];
