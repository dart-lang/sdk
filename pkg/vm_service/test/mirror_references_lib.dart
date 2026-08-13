// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'common/test_helper.dart';

class Foo {}

dynamic /*Foo*/ foo;
dynamic /*MirrorReference*/ ref;

void script() {
  foo = Foo();
  final ClassMirror fooClassMirror = reflectClass(Foo);
  final InstanceMirror fooClassMirrorMirror = reflect(fooClassMirror);
  final LibraryMirror libmirrors =
      fooClassMirrorMirror.type.owner as LibraryMirror;
  ref = reflect(fooClassMirror)
      .getField(MirrorSystem.getSymbol('_reflectee', libmirrors))
      .reflectee;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
