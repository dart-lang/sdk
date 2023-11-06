// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

class Foo {}

dynamic /*Foo*/ foo;
dynamic /*MirrorReference*/ ref;

void script() {
  foo = Foo();
  ClassMirror fooClassMirror = reflectClass(Foo);
  InstanceMirror fooClassMirrorMirror = reflect(fooClassMirror);
  LibraryMirror libmirrors = fooClassMirrorMirror.type.owner as LibraryMirror;
  ref = reflect(fooClassMirror)
      .getField(MirrorSystem.getSymbol('_reflectee', libmirrors))
      .reflectee;
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
    ) as Library;

    final variables = rootLib.variables!;
    final fooFieldRef = variables.singleWhere((v) => v.name == 'foo');
    final fooField = await service.getObject(
      isolateId,
      fooFieldRef.id!,
    ) as Field;
    final foo = fooField.staticValue as InstanceRef;

    final refFieldRef = variables.singleWhere((v) => v.name == 'ref');
    final refField = await service.getObject(
      isolateId,
      refFieldRef.id!,
    ) as Field;
    final refRef = refField.staticValue as InstanceRef;
    final ref = await service.getObject(isolateId, refRef.id!) as Instance;

    expect(foo.kind, InstanceKind.kPlainInstance);
    expect(ref.kind, InstanceKind.kMirrorReference);
    expect((ref.mirrorReferent! as ClassRef).name, 'Foo');
    expect(ref.mirrorReferent, foo.classRef);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'mirror_references_test.dart',
      testeeBefore: script,
    );
