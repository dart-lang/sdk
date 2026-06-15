// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  final i = 42.42; // LINE_A
  final hex = 0x42;
  if (i is int) {
    print('i is int');
    final int x = i as int;
    if (x.isEven) {
      print("it's even even!");
    } else {
      print("but it's not even even!");
    }
  }
  if (i is! int) {
    print('i is not int');
  }
  // ignore: unnecessary_type_check_true
  if (hex is int) {
    print('hex is int');
    final int x = hex as dynamic;
    if (x.isEven) {
      print("it's even even!");
    } else {
      print("but it's not even even!");
    }
  }
  // ignore: unnecessary_type_check_false
  if (hex is! int) {
    print('hex is not int');
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
