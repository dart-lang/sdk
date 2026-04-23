// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:js_interop';

@JS('console.log')
external void log(String _);

// We use this to test whether a hot restart or a full reload occurred. In the
// former, we should see the old log, but in the latter, we should not.
@JS('\$previousLog')
external String? previousLog;

void main() {
  var count = 0;
  // For setting breakpoints.
  Timer.periodic(const Duration(seconds: 1), (_) {
    print('Count is: ${++count}'); // Breakpoint: printCount
  });

  var logMessage = 'Hello World!';
  // Note that we concatenate instead of logging each one separately to avoid
  // possibly mixing up logs with a previous call to `main`.
  if (previousLog != null) logMessage = '$previousLog $logMessage';
  log(logMessage);
  previousLog = logMessage;

  registerExtension('ext.flutter.disassemble', (_, __) async {
    log('start disassemble');
    await Future.delayed(const Duration(seconds: 1));
    log('end disassemble');
    return ServiceExtensionResponse.result('{}');
  });
}
