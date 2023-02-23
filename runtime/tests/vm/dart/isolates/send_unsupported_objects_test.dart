// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  NativeClass? nativeClass;
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

void checkForRetainingPath(Object? e, List<String> list) {
  Expect.isTrue(e is ArgumentError);
  final msg = e.toString();
  list.forEach((s) {
    Expect.contains(s, msg);
  });
}

main() async {
  asyncStart();
  final rp = ReceivePort();
  try {
    rp.sendPort.send(Fu.unsendable('fu'));
  } catch (e) {
    checkForRetainingPath(e, <String>[
      'NativeWrapper',
      'Baz',
      'Fu',
    ]);
  }
  rp.close();
  asyncEnd();
}
