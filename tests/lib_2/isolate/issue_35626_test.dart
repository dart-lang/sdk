// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Tests that sets of enums can be set through ports.
// https://github.com/dart-lang/sdk/issues/35626

library spawn_tests;

import "dart:io";
import "dart:isolate";
import "package:expect/expect.dart";

enum MyEnum { foo, bar, baz }

void sendSetOfEnums(SendPort port) {
  Set<MyEnum> remoteSet = Set()..add(MyEnum.bar);
  port.send(remoteSet);
}

void main() async {
  Set<MyEnum> localSet = Set()..add(MyEnum.foo)..add(MyEnum.bar);
  localSet.lookup(MyEnum.foo);

  final port = ReceivePort();
  await Isolate.spawn(sendSetOfEnums, port.sendPort);
  Set<MyEnum> remoteSet = await port.first;

  print(localSet);
  print(remoteSet);
  Expect.setEquals([MyEnum.bar], localSet.intersection(remoteSet));
  Expect.setEquals([MyEnum.bar], remoteSet.intersection(localSet));
}
