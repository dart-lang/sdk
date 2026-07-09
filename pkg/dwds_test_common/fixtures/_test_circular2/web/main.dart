// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';
// TODO: https://github.com/dart-lang/webdev/issues/2508
// ignore: deprecated_member_use
import 'dart:html';

import 'package:_test_circular1/library1.dart';
import 'package:_test_circular2/library2.dart';

void main() {
  // For setting breakpoints.
  Timer.periodic(const Duration(seconds: 1), (_) {
    testCircularDependencies();
  });

  document.body!.appendText(concatenate('Program', ' is running!'));
}
