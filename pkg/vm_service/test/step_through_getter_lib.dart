// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() // LINE_A
{
  final bar = Bar();
  print(bar.barXYZ);
  print(bar.barXYZ2);
  print(fooXYZ);
  print(fooXYZ2);
}

String get fooXYZ => 'fooXYZ';

String get fooXYZ2 {
  final i = 42;
  return 'Hello, $i!';
}

class Bar {
  String get barXYZ => 'barXYZ';

  String get barXYZ2 {
    final i = 42;
    return 'Hello, $i!';
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
