// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';
import 'common/test_helper.dart';

int thing1;
int thing2;

testeeMain() {
  thing1 = 3;
  thing2 = 4;
}

Future evaluate(VmService service, isolate, target, x, y) async => await service
    .evaluate(isolate.id, target.id, 'x + y', scope: {'x': x.id, 'y': y.id});

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id);
    final Library lib = await service.getObject(isolate.id, isolate.rootLib.id);

    final Field field1 = await service.getObject(
        isolate.id, lib.variables.singleWhere((v) => v.name == 'thing1').id);
    final thing1 = (await service.getObject(isolate.id, field1.staticValue.id));

    final Field field2 = await service.getObject(
        isolate.id, lib.variables.singleWhere((v) => v.name == 'thing2').id);
    final thing2 = (await service.getObject(isolate.id, field2.staticValue.id));

    var result = await evaluate(service, isolate, lib, thing1, thing2);
    expect(result.valueAsString, equals('7'));

    bool didThrow = false;
    try {
      result = await evaluate(service, isolate, lib, lib, lib);
      print(result);
    } catch (e) {
      didThrow = true;
      expect(e.toString(),
          contains("Cannot evaluate against a VM-internal object"));
    }
    expect(didThrow, isTrue);

    didThrow = false;
    try {
      result = await service.evaluate(isolate.id, lib.id, "x + y",
          scope: <String, String>{"not&an&identifier": thing1.id});
      print(result);
    } catch (e) {
      didThrow = true;
      expect(e.toString(), contains("invalid 'scope' parameter"));
    }
    expect(didThrow, isTrue);
  }
];

main([args = const <String>[]]) =>
    runIsolateTests(args, tests, testeeBefore: testeeMain);
