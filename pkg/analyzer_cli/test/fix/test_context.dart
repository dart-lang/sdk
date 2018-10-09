// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer_cli/src/fix/context.dart';
import 'package:path/path.dart' as pathos;

/// Convert the given posix [path] to conform to the current OS context.
String p(String path) {
  if (pathos.style == pathos.windows.style) {
    if (path.startsWith(pathos.posix.separator)) {
      path = r'C:' + path;
    }
    path = path.replaceAll(pathos.posix.separator, pathos.windows.separator);
  }
  return path;
}

class TestContext implements Context {
  final StreamController<List<int>> stdinController =
      new StreamController<List<int>>();

  @override
  final stdout = new StringBuffer();

  @override
  final stderr = new StringBuffer();

  @override
  Stream<List<int>> get stdin => stdinController.stream;

  @override
  String get workingDir => p('/usr/some/non/existing/directory');

  @override
  bool exists(String target) => true;

  @override
  void exit(int code) {
    throw TestExit(code);
  }

  void print([String text = '']) {
    stdout.writeln(text);
  }
}

class TestExit {
  final int code;

  TestExit(this.code);
}
