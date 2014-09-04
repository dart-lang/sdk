// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_references_test;

import 'dart:async';
import 'dart:mirrors';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Foo { }

Foo foo;
var /*MirrorReference*/ ref;

void script() {
  foo = new Foo();
  ClassMirror fooClassMirror = reflectClass(Foo);
  InstanceMirror fooClassMirrorMirror = reflect(fooClassMirror);
  LibraryMirror libmirrors = fooClassMirrorMirror.type.owner;
  ref = reflect(fooClassMirror).getField(MirrorSystem.getSymbol('_reflectee', libmirrors)).reflectee;
}

var tests = [

(Isolate isolate) =>
  isolate.rootLib.load().then((Library lib) {
    ServiceMap fooField = lib.variables.singleWhere((v) => v.name == 'foo');
    Instance foo = fooField['value'];
    ServiceMap refField = lib.variables.singleWhere((v) => v.name == 'ref');
    Instance ref = refField['value'];

    expect(foo.isMirrorReference, isFalse);
    expect(ref.isMirrorReference, isTrue);
    expect(ref.referent, isNull);
    return ref.load().then((Instance loadedRef) {
      expect(loadedRef.referent, isNotNull);
      expect(loadedRef.referent.name, equals('Foo'));
      expect(loadedRef.referent, equals(foo.clazz));
    });
  }),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
