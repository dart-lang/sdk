// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library hierarchy_test;

@MirrorsUsed(targets: 'hierarchy_test, Object')
import 'dart:mirrors';

import 'package:expect/expect.dart';

class FooMixin {
  foo() => print('foo');
}

class Qux {
  qux() => print('qux');
}

class Bar extends Qux implements FooMixin {
  bar() => print('bar');
  foo() => print('foo');
}

class Baz extends Qux with FooMixin {
  bar() => print('bar');
}

stringifyHierarchy(mirror) {
  var sb = new StringBuffer();
  for (var type = mirror.type; type != null; type = type.superclass) {
    sb.write('> ${MirrorSystem.getName(type.qualifiedName)}\n');
    for (var i in type.superinterfaces) {
      sb.write('  + ${MirrorSystem.getName(i.qualifiedName)}\n');
    }
  }
  return '$sb';
}

main() {
  Expect.stringEquals('''
> hierarchy_test.Bar
  + hierarchy_test.FooMixin
> hierarchy_test.Qux
> dart.core.Object
''', stringifyHierarchy(reflect(new Bar()..foo()..bar()..qux())));

  Expect.stringEquals('''
> hierarchy_test.Baz
> hierarchy_test.Qux with hierarchy_test.FooMixin
  + hierarchy_test.FooMixin
> hierarchy_test.Qux
> dart.core.Object
''', stringifyHierarchy(reflect(new Baz()..foo()..bar()..qux())));
}
