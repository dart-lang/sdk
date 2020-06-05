// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// All three libraries have an HttpRequest class.
import "conditional_import_test.dart"
    if (dart.library.io) "dart:io"
    if (dart.library.html) "dart:html" deferred as d show HttpRequest;

class HttpRequest {}

void main() {
  asyncStart();
  var io = const bool.fromEnvironment("dart.library.io");
  var html = const bool.fromEnvironment("dart.library.html");
  () async {
    // Shouldn't fail. Shouldn't time out.
    await d.loadLibrary().timeout(const Duration(seconds: 5));
    if (io) {
      print("io");
      Expect.throws(() => new d.HttpRequest()); // Class is abstract in dart:io
    } else if (html) {
      print("html");
      dynamic r = new d.HttpRequest(); // Shouldn't throw
      var o = r.open; // Shouldn't fail, the open method is there.
    } else {
      print("none");
      dynamic r = new d.HttpRequest();
      Expect.isTrue(r is HttpRequest);
    }
    asyncEnd();
  }();
}
