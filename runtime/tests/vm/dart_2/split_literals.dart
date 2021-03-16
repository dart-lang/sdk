// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "split_literals_deferred.dart" deferred as lib;

class Box {
  final contents;
  const Box(this.contents);
  String toString() => "Box($contents)";
}

main() async {
  print("Root literal!");
  print(const <String>["Root literal in a list!"]);
  print(const <String, String>{"key": "Root literal in a map!"});
  print(const Box("Root literal in a box!"));

  await lib.loadLibrary();
  lib.foo();
}
