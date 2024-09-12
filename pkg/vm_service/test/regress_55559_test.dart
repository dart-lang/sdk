// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/55559.
//
// Ensures that the `VmService` instance calls `dispose()` automatically if the
// VM service connection goes down. Without the `dispose()` call, outstanding
// requests won't complete unless the developer registered a callback for
// `VmService.onDone` that calls `dispose()`.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/utils.dart';

void main() {
  (Process, Uri)? state;

  void killProcess() {
    if (state != null) {
      final (process, _) = state!;
      process.kill();
      state = null;
    }
  }

  setUp(() async {
    state = await spawnDartProcess(
      'regress_55559_script.dart',
      pauseOnStart: false,
    );
  });

  tearDown(() {
    killProcess();
  });

  test(
    'Regress 55559: VmService closes outstanding requests on service disconnect',
    () async {
      final (_, uri) = state!;
      final wsUri = uri.replace(
        scheme: 'ws',
        pathSegments: [
          // The path will have a trailing '/', so the last path segment is the
          // empty string and should be removed.
          ...[...uri.pathSegments]..removeLast(),
          'ws',
        ],
      );
      final service = await vmServiceConnectUri(wsUri.toString());
      final vm = await service.getVM();
      final isolate = vm.isolates!.first;
      final errorCompleter = Completer<RPCError>();
      final stackTraceCompleter = Completer<StackTrace>();
      unawaited(
        service.getIsolate(isolate.id!).then(
          (_) => fail('Future should throw'),
          onError: (e, st) {
            errorCompleter.complete(e);
            stackTraceCompleter.complete(st);
          },
        ),
      );
      killProcess();

      // Wait for the process to exit and the service connection to close.
      await service.onDone;

      // The outstanding getIsolate request should be completed with an error.
      final error = await errorCompleter.future;
      expect(error.code, RPCErrorKind.kServerError.code);
      expect(error.message, 'Service connection disposed');

      // Confirm that a stack trace was included and that it contains the actual
      // invocation path.
      final stackTrace = await stackTraceCompleter.future;
      final stack = stackTrace.toString().split('\n');
      expect(
        stack.where((e) => e.contains('VmService.getIsolate')).length,
        1,
      );
      expect(
        stack.where((e) => e.contains('test/regress_55559_test.dart')).length,
        1,
      );
    },
  );
}
