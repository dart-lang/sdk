// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/elements.dart';
import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('simple default constructor', () {
    String code = '''
class A {
}

main() {
  var a = new A();
  return a;
}''';
    return check(code, lookup: defaultConstructorFor('A'));
  });

  test('simple default constructor with field', () {
    String code = '''
class A {
  int x = 1;
}

main() {
  var a = new A();
  return a;
}''';
    return check(code, lookup: defaultConstructorFor('A'));
  });
}

defaultConstructorFor(String className) => (Compiler compiler) {
      ClassElement clazz = compiler.mainApp.find(className);
      return clazz.lookupDefaultConstructor();
    };
