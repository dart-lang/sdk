// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

Future runTest() async {
  var env = await TypeEnvironment.create("""
    class A {
      call() {}
    }
    class B {
    }
    class C extends B {
      call() {}
    }

    main() {
      (new A())();
      new B();
      (new C())();
      localFunction() {}
      () {};
    }
    """, testBackendWorld: true);

  Map<String, String> expectedMap = const {
    'A': '[exact=A]',
    'B': '[exact=C]',
    'C': '[exact=C]',
  };

  JClosedWorld closedWorld = env.jClosedWorld;
  int closureCount = 0;
  Selector callSelector = new Selector.callClosure(0);
  closedWorld.classHierarchy.forEachStrictSubclassOf(
      closedWorld.commonElements.objectClass, (ClassEntity cls) {
    if (cls.library.canonicalUri.scheme != 'memory')
      return IterationStep.CONTINUE;

    TypeMask mask = new TypeMask.nonNullSubclass(cls, closedWorld);
    TypeMask receiverType = closedWorld.computeReceiverType(callSelector, mask);
    if (cls.isClosure) {
      // TODO(johnniwinther): Expect mask based on 'cls' when all synthesized
      // call methods are registered.
      String expected = '[empty]'; //'$mask';
      Expect.equals(expected, '${receiverType}',
          "Unexpected receiver type for $callSelector on $mask");
      closureCount++;
    } else {
      String expected = expectedMap[cls.name];
      Expect.equals(expected, '$receiverType',
          "Unexpected receiver type for $callSelector on $mask");
    }
    return IterationStep.CONTINUE;
  });

  Expect.equals(2, closureCount);
}
