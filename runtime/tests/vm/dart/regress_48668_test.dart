// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--deterministic

import "dart:io";
import "dart:isolate";
import "package:expect/expect.dart";

void main(List<String> args) async {
  if (!args.contains("--child")) {
    for (var i = 0; i < 4; i++) {
      Isolate.spawn(main, ["--child"]);
    }
  }

  for (var i = 0; i < 10000; i++) {
    final d = Directory("does-not-exist");
    Expect.throws(() => d.listSync(), (e) => e is FileSystemException);
  }
}
