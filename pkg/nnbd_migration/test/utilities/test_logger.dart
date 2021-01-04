// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cli_util/cli_logging.dart';

/// TODO(paulberry): move into cli_util
class TestLogger implements Logger {
  final stderrBuffer = StringBuffer();

  final stdoutBuffer = StringBuffer();

  final bool isVerbose;

  TestLogger(this.isVerbose);

  @override
  Ansi get ansi => Ansi(false);

  @override
  void flush() {}

  @override
  Progress progress(String message) {
    return SimpleProgress(this, message);
  }

  @override
  void stderr(String message) {
    stderrBuffer.writeln(message);
  }

  @override
  void stdout(String message) {
    stdoutBuffer.writeln(message);
  }

  @override
  void trace(String message) {
    if (isVerbose) {
      stdoutBuffer.writeln(message);
    }
  }

  @override
  void write(String message) {
    stdoutBuffer.write(message);
  }

  @override
  void writeCharCode(int charCode) {
    stdoutBuffer.writeCharCode(charCode);
  }
}
