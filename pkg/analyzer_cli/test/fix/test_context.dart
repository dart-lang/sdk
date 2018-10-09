// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_cli/src/fix/context.dart';

class TestContext with ResourceProviderMixin implements Context {
  final StreamController<List<int>> stdinController =
      new StreamController<List<int>>();

  @override
  final stdout = new StringBuffer();

  @override
  final stderr = new StringBuffer();

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

  void print([String text = '']) {
    stdout.writeln(text);
  }
}

class TestExit {
  final int code;

  TestExit(this.code);
}
