// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:nativewrappers';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'send_unsupported_objects_init_isolate_test.dart';

class Foo {
  int i = 42;
}

class Bar {
  Foo foo = Foo();
}

class NativeClass extends NativeFieldWrapperClass1 {}

class Baz {
  @pragma('vm:entry-point') // prevent tree-shaking of the field.
  NativeClass nativeClass;
  Baz();
}

class Fu {
  String label;
  Bar bar = Bar();
  Baz baz = Baz();

  Fu(this.label);
  Fu.unsendable(this.label) {
    baz.nativeClass = NativeClass();
  }
}

@pragma("vm:isolate-unsendable")
class Locked {}

class ExtendsLocked extends Locked {}

class ImplementsLocked implements Locked {}

bool checkForRetainingPath(Object e, List<String> list) {
  if (e is! ArgumentError) {
    return false;
  }
  final msg = e.toString();
  return list.every((s) => msg.contains(s));
}

main() async {
  asyncStart();
  final rp = ReceivePort();

  for (final pair in [
    [
      () => Fu.unsendable('fu'),
      ["NativeClass", "Baz", "Fu"]
    ],
    [
      () => Future.value(123),
      ["Future"]
    ],
    [
      () => Locked(),
      ["Locked"]
    ],
    [
      () => ExtendsLocked(),
      ["ExtendsLocked"]
    ],
    [
      () => ImplementsLocked(),
      ["ImplementsLocked"]
    ]
  ]) {
    Expect.throws(() => rp.sendPort.send((pair[0] as Function)()),
        (e) => checkForRetainingPath(e, pair[1] as List<String>));
  }

  try {
    await Isolate.spawn((_) {}, Locked());
    Expect.fail('spawn should have failed');
  } catch (e) {
    Expect.isTrue(e is ArgumentError && e.toString().contains("Locked"));
  }

  runZoned(() {
    Expect.throws(() {
      final z = Zone.current;
      rp.sendPort.send(Zone.current);
    }, (e) => checkForRetainingPath(e, <String>['Zone']));
  }, zoneValues: {0: 1});

  rp.close();
  asyncEnd();
}
