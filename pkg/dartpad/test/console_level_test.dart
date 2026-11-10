// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checks/checks.dart';
import 'package:dartpad/src/worker_client.dart';
import 'package:test/test.dart';

void main() {
  test('ConsoleLevel ordering and protocolName', () {
    check(ConsoleLevel.debug < .log).isTrue;
    check(ConsoleLevel.log < .info).isTrue;
    check(ConsoleLevel.info < .warn).isTrue;
    check(ConsoleLevel.warn < .error).isTrue;
    check(ConsoleLevel.error >= .warn).isTrue;
    check(ConsoleLevel.debug <= .debug).isTrue;
    check(ConsoleLevel.error > .debug).isTrue;

    final sorted = <ConsoleLevel>[.error, .info, .debug, .warn, .log]..sort();
    check(sorted).deepEquals(ConsoleLevel.values);

    check(ConsoleLevel.debug.protocolName).equals('debug');
    check(ConsoleLevel.log.protocolName).equals('log');
    check(ConsoleLevel.info.protocolName).equals('info');
    check(ConsoleLevel.warn.protocolName).equals('warn');
    check(ConsoleLevel.error.protocolName).equals('error');
  });
}
