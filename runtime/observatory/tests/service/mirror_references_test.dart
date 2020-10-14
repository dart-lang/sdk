// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_references_test;

import 'dart:mirrors';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

class Foo {}

dynamic /*Foo*/ foo;
dynamic /*MirrorReference*/ ref;

void script() {
  foo = new Foo();
  ClassMirror fooClassMirror = reflectClass(Foo);
  InstanceMirror fooClassMirrorMirror = reflect(fooClassMirror);
  LibraryMirror libmirrors = fooClassMirrorMirror.type.owner as LibraryMirror;
  ref = reflect(fooClassMirror)
      .getField(MirrorSystem.getSymbol('_reflectee', libmirrors))
      .reflectee;
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load() as Library;
    Field fooField = lib.variables.singleWhere((v) => v.name == 'foo');
    await fooField.load();
    Instance foo = fooField.staticValue as Instance;
    Field refField = lib.variables.singleWhere((v) => v.name == 'ref');
    await refField.load();
    Instance ref = refField.staticValue as Instance;

    expect(foo.isMirrorReference, isFalse);
    expect(ref.isMirrorReference, isTrue);
    expect(ref.referent, isNull);
    Instance loadedRef = await ref.load() as Instance;
    expect(loadedRef.referent, isNotNull);
    expect(loadedRef.referent!.name, equals('Foo'));
    expect(loadedRef.referent, equals(foo.clazz));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
