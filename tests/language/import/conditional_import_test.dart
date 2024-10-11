// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

import "default.dart"
    if (dart.library.io) "io.dart"
    if (dart.library.html) "html.dart" deferred as d show value;

void main() async {
  asyncStart();
  final io = const bool.fromEnvironment("dart.library.io");
  final html = const bool.fromEnvironment("dart.library.html");
  await d.loadLibrary().timeout(const Duration(seconds: 5));
  if (io) {
    Expect.equals("io", d.value);
  } else if (html) {
    Expect.equals("html", d.value);
  } else {
    Expect.equals("default", d.value);
  }
  asyncEnd();
}
