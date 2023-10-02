// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "split_literals.dart";

@pragma("vm:never-inline")
void foo() {
  print("Deferred literal!");
  print(const <String>["Deferred literal in a list!"]);
  print(const <String, String>{"key": "Deferred literal in a map!"});
  print(const Box("Deferred literal in a box!"));
}
