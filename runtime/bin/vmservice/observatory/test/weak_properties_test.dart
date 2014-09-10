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
class Bar { }

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

  var entries = expandoMirror.getField(MirrorSystem.getSymbol('_data', libcore)).reflectee;
  weak_property = entries.singleWhere((e) => e != null);
  print(weak_property);
}

var tests = [

(Isolate isolate) =>
  isolate.rootLib.load().then((Library lib) {
    ServiceMap keyField = lib.variables.singleWhere((v) => v.name == 'key');
    Instance key = keyField['value'];
    ServiceMap valueField = lib.variables.singleWhere((v) => v.name == 'value');
    Instance value = valueField['value'];
    ServiceMap propField = lib.variables.singleWhere((v) => v.name == 'weak_property');
    Instance prop = propField['value'];

    expect(key.isWeakProperty, isFalse);
    expect(value.isWeakProperty, isFalse);
    expect(prop.isWeakProperty, isTrue);
    expect(prop.key, isNull);
    expect(prop.value, isNull);
    return prop.load().then((Instance loadedProp) {
      // Object ids are not cannonicalized, so we rely on the key and value
      // being the sole instances of their classes to test we got the objects
      // we expect.
      expect(loadedProp.key, isNotNull);
      expect(loadedProp.key.clazz, equals(key.clazz));
      expect(loadedProp.value, isNotNull);
      expect(loadedProp.value.clazz, equals(value.clazz));
    });
  }),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
