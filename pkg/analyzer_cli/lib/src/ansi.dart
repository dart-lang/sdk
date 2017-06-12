// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Public for testing.
bool runningTests = false;

bool terminalSupportsAnsi() {
  return !runningTests &&
      !Platform.isWindows &&
      stdioType(stdout) == StdioType.TERMINAL;
}

class AnsiLogger {
  final bool useAnsi;

  AnsiLogger(this.useAnsi);
  String get blue => _code('\u001b[34m');
  String get bold => _code('\u001b[1m');
  String get bullet => (runningTests || !Platform.isWindows) ? '•' : '-';
  String get cyan => _code('\u001b[36m');
  String get gray => _code('\u001b[1;30m');
  String get green => _code('\u001b[32m');
  String get magenta => _code('\u001b[35m');
  String get noColor => _code('\u001b[39m');
  String get none => _code('\u001b[0m');

  String get red => _code('\u001b[31m');

  String get yellow => _code('\u001b[33m');

  String _code(String ansiCode) => useAnsi ? ansiCode : '';
}
