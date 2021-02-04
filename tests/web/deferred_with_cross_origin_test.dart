// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that code loaded via deferred imports uses the same crossorigin value as
// the main page.

import "deferred_with_cross_origin_lib.dart" deferred as lib;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:html";

main() {
  asyncStart();

  var scripts = document
      .querySelectorAll<ScriptElement>('script')
      .where((s) => s.src.contains("generated_compilations"))
      .toList();
  Expect.equals(1, scripts.length);
  Expect.equals(null, scripts.first.crossOrigin);
  scripts.first.crossOrigin = "anonymous";

  lib.loadLibrary().then((_) {
    print(lib.foo());
    var scripts = document
        .querySelectorAll<ScriptElement>('script')
        .where((s) => s.src.contains("generated_compilations"))
        .toList();
    Expect.equals(2, scripts.length);
    for (var script in scripts) {
      Expect.equals("anonymous", script.crossOrigin);
    }
    asyncEnd();
  });
}
