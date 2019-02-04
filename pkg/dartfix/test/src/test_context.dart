// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartfix/src/context.dart';

class TestContext with ResourceProviderMixin implements Context {
  @override
  String get workingDir => convertPath('/usr/some/non/existing/directory');

  @override
  bool exists(String filePath) => true;

  @override
  void exit(int code) {
    throw TestExit(code);
  }

  @override
  bool isDirectory(String filePath) => !filePath.endsWith('.dart');
}

class TestExit {
  final int code;

  TestExit(this.code);

  @override
  String toString() => 'TestExit($code)';
}

class TestLogger implements Logger {
  final Ansi ansi;
  final stdoutBuffer = new StringBuffer();
  final stderrBuffer = new StringBuffer();

  TestLogger() : this.ansi = new Ansi(false);

  @override
  void flush() {}

  @override
  bool get isVerbose => false;

  @override
  Progress progress(String message) {
    return new SimpleProgress(this, message);
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
  void trace(String message) {}
}
