// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

class Foo {}

class Bar {}

var expando;
var key;
var value;
var weak_property;

void script() {
  expando = Expando('some debug name');
  key = Foo();
  value = Bar();
  expando[key] = value;

  final expandoMirror = reflect(expando);
  final libcore = expandoMirror.type.owner as LibraryMirror;

  final entries = expandoMirror
      .getField(MirrorSystem.getSymbol('_data', libcore))
      .reflectee;
  weak_property = entries.singleWhere((e) => e != null);
  print(weak_property);
}

Future<Instance> getFieldValue(VmService service, String isolateId,
    List<FieldRef> variables, String name) async {
  final fieldRef = variables.singleWhere((v) => v.name == name);
  final field = await service.getObject(
    isolateId,
    fieldRef.id!,
  ) as Field;
  return await service.getObject(
    isolateId,
    (field.staticValue as InstanceRef).id!,
  ) as Instance;
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final lib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
    ) as Library;
    final variables = lib.variables!;

    final key = await getFieldValue(
      service,
      isolateId,
      variables,
      'key',
    );
    final value = await getFieldValue(
      service,
      isolateId,
      variables,
      'value',
    );
    final prop = await getFieldValue(
      service,
      isolateId,
      variables,
      'weak_property',
    );

    expect(key.kind, isNot(InstanceKind.kWeakProperty));
    expect(value.kind, isNot(InstanceKind.kWeakProperty));

    // Object ids are not canonicalized, so we rely on the key and value
    // being the sole instances of their classes to test we got the objects
    // we expect.
    expect(prop.kind, InstanceKind.kWeakProperty);
    expect(prop.propertyKey, isNotNull);
    expect((prop.propertyKey! as InstanceRef).classRef, key.classRef);
    expect(prop.propertyValue, isNotNull);
    expect((prop.propertyValue! as InstanceRef).classRef, value.classRef);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'weak_properties_test.dart',
      testeeBefore: script,
    );
