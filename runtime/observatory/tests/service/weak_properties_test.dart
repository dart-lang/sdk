// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

library vm_references_test;

import 'dart:mirrors';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Foo {}

class Bar {}

var expando;
var key;
var value;
var weak_property;

void script() {
  expando = new Expando('some debug name');
  key = new Foo();
  value = new Bar();
  expando[key] = value;

  InstanceMirror expandoMirror = reflect(expando);
  LibraryMirror libcore = expandoMirror.type.owner;

  var entries = expandoMirror
      .getField(MirrorSystem.getSymbol('_data', libcore))
      .reflectee;
  weak_property = entries.singleWhere((e) => e != null);
  print(weak_property);
}

var tests = [
  (Isolate isolate) async {
    var lib = await isolate.rootLibrary.load();
    Field keyField = lib.variables.singleWhere((v) => v.name == 'key');
    await keyField.load();
    Instance key = keyField.staticValue;
    Field valueField = lib.variables.singleWhere((v) => v.name == 'value');
    await valueField.load();
    Instance value = valueField.staticValue;
    Field propField =
        lib.variables.singleWhere((v) => v.name == 'weak_property');
    await propField.load();
    Instance prop = propField.staticValue;

    expect(key.isWeakProperty, isFalse);
    expect(value.isWeakProperty, isFalse);
    expect(prop.isWeakProperty, isTrue);
    expect(prop.key, isNull);
    expect(prop.value, isNull);
    Instance loadedProp = await prop.load();
    // Object ids are not canonicalized, so we rely on the key and value
    // being the sole instances of their classes to test we got the objects
    // we expect.
    expect(loadedProp.key, isNotNull);
    expect(loadedProp.key.clazz, equals(key.clazz));
    expect(loadedProp.value, isNotNull);
    expect(loadedProp.value.clazz, equals(value.clazz));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
