// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import 'type_test_helper.dart';

main() {
  asyncTest(() async {
    await runTest(CompileMode.memory);
    await runTest(CompileMode.dill);
  });
}

Future runTest(CompileMode mode) async {
  var env = await TypeEnvironment.create("""
    class A {
      call() {}
    }
    class B {
    }
    class C extends B {
      call() {}
    }
    """, mainSource: """
    main() {
      (new A())();
      new B();
      (new C())();
      localFunction() {}
      () {};
    }
    """, compileMode: mode, testBackendWorld: true);

  Map<String, String> expectedMap = const {
    'A': '[exact=A]',
    'B': '[exact=C]',
    'C': '[exact=C]',
  };

  ClosedWorld closedWorld = env.closedWorld;
  int closureCount = 0;
  Selector callSelector = new Selector.callClosure(0);
  closedWorld.forEachStrictSubclassOf(closedWorld.commonElements.objectClass,
      (ClassEntity cls) {
    if (cls.library.canonicalUri.scheme != 'memory') return;

    TypeMask mask = new TypeMask.nonNullSubclass(cls, closedWorld);
    TypeMask receiverType = closedWorld.computeReceiverType(callSelector, mask);
    if (cls.isClosure) {
      String expected = '$mask';
      Expect.equals(expected, '${receiverType}',
          "Unexpected receiver type for $callSelector on $mask");
      closureCount++;
    } else {
      String expected = expectedMap[cls.name];
      Expect.equals(expected, '$receiverType',
          "Unexpected receiver type for $callSelector on $mask");
    }
  });

  Expect.equals(2, closureCount);
}
