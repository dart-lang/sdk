// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';
// TODO: https://github.com/dart-lang/webdev/issues/2508
// ignore: deprecated_member_use
import 'dart:html';

import 'package:_test_parts/library.dart';

void main() {
  // For setting breakpoints.
  Timer.periodic(const Duration(seconds: 1), (_) {
    concatenate1('hello', 'world');
    concatenate2(2, 3);
    concatenate3('hello', 36.42);
    concatenate4(['hello', 'world'], {'foo': 'bar'});
  });

  document.body!.appendText(concatenate1('Program', ' is running!'));
}
