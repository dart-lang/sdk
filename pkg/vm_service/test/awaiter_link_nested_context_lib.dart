// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'common/test_helper.dart';

@pragma('vm:never-inline')
void use(Object? o) {}

String doThrow() {
  throw 'TheException';
}

Future<void> asyncThrower() async {
  // ignore: await_only_futures
  await 0; // force async gap
  doThrow();
}

// The awaiter link variable is declared in a nested closure's context, so
// the registered callback must walk up the right number of contexts from its
// own context to find it.
ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  R Function(T) f,
) {
  final obj = Object();
  ZoneUnaryCallback<R, T> nested() {
    final obj2 = Object();
    final obj3 = Object();
    @pragma('vm:awaiter-link')
    final R Function(T) g = f;
    ZoneUnaryCallback<R, T> register() {
      use(self);
      use(obj);
      use(obj2);
      use(obj3);
      return parent.registerUnaryCallback(zone, (T v) => g(v));
    }

    return register();
  }

  return nested();
}

Future<void> testeeMain() async {
  await runZoned(
    () async {
      await asyncThrower(); // LINE_A
    },
    zoneSpecification:
        ZoneSpecification(registerUnaryCallback: registerUnaryCallback),
  );
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
