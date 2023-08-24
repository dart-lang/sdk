// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class Foo {}

code() {
  Foo();
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  // Load the isolate's libraries
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);

    ClassRef? fooCls;
    libLoop:
    for (final libRef in isolate.libraries!) {
      final lib = await service.getObject(isolateId, libRef.id!) as Library;
      for (final cls in lib.classes!) {
        if (cls.name == 'Foo') {
          fooCls = cls;
          break libLoop;
        }
      }
    }

    if (fooCls == null) {
      throw StateError('Could not find ClassRef for Foo!');
    }
    final cls = await service.getObject(isolateId, fooCls.id!) as Class;
    FuncRef? fooFunc;
    for (final func in cls.functions!) {
      if (func.name == 'Foo') {
        fooFunc = func;
        break;
      }
    }

    if (fooFunc == null) {
      throw StateError('Could not find FuncRef for Foo.Foo!');
    }

    try {
      await service.addBreakpointAtEntry(isolateId, fooFunc.id!);
      fail('Successfully added breakpoint at an invalid location!');
    } on RPCError catch (e) {
      // TODO(bkonyi): add this error code to package:vm_service
      expect(e.code, 102);
      expect(e.message, 'Cannot add breakpoint');
      expect(e.details, contains('Cannot add breakpoint at function'));
    }

    await service.resume(isolateId);
  },
];

void main(List<String> args) {
  runIsolateTestsSynchronous(
    args,
    tests,
    'break_on_default_constructor_test.dart',
    testeeConcurrent: code,
    pause_on_start: true,
    pause_on_exit: true,
  );
}
