// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() // LINE_A
{
  final bar = Bar();
  print(bar.barXYZ1());
  print(bar.barXYZ2(4, 2));
  print(bar.barXYZ3());
  print(bar.barXYZ4(4, 2));
  print(fooXYZ1());
  print(fooXYZ2(4, 2));
  print(fooXYZ3());
  print(fooXYZ4(4, 2));
}

String fooXYZ1 /**/ () => 'fooXYZ';
String fooXYZ2 /**/ (int i, int j) => 'fooXYZ$i$j';
String fooXYZ3 /**/ () {
  return 'fooXYZ';
}

String fooXYZ4 /**/ (int i, int j) {
  return 'fooXYZ$i$j';
}

class Bar {
  String barXYZ1 /**/ () => 'barXYZ';
  String barXYZ2 /**/ (int i, int j) => 'barXYZ$i$j';
  String barXYZ3 /**/ () {
    return 'barXYZ';
  }

  String barXYZ4 /**/ (int i, int j) {
    return 'barXYZ$i$j';
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
