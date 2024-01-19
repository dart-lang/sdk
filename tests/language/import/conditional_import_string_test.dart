// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

import "default.dart"
    if (dart.library.io) "io.dart"
    if (dart.library.html) "html.dart" deferred as d show value;

void main() async {
  asyncStart();
  final io = const String.fromEnvironment("dart.library.io") == "true";
  final html = const String.fromEnvironment("dart.library.html") == "true";
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
