// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST = r'''
class A {
  var field = 42;
}
main() {
  var a = new A();
  var b = [42, -1];
  // Force a setter on [field].
  if (false) a.field = 12;
  var c = a.field;
  print(b[0] ~/ b[1]);
  return c + a.field;
}
''';

void main() {
  asyncTest(() => compileAll(TEST).then((generated) {
    Expect.isTrue(generated.contains('return c + c;'));
  }));  
}
