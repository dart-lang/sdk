// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that code loaded via deferred imports uses the same nonce value as the
// main page.

import "deferred_with_csp_nonce_lib.dart" deferred as lib;
import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import "dart:html";

import "../csp_helper.dart";

main() {
  asyncStart();

  var scripts = document
      .querySelectorAll<ScriptElement>('script')
      .where((s) => s.src.contains("generated_compilations"))
      .toList();
  Expect.equals(1, scripts.length);
  Expect.equals('', scripts.first.nonce ?? '');
  Expect.equals('', scripts.first.getAttribute('nonce') ?? '');
  scripts.first.nonce = "an-example-nonce-string";

  lib.loadLibrary().then((_) {
    print(lib.foo());
    var scripts = document
        .querySelectorAll<ScriptElement>('script')
        .where((s) => s.src.contains(".part.js"))
        .toList();
    Expect.equals(1, scripts.length);
    for (var script in scripts) {
      Expect.equals("an-example-nonce-string", script.nonce);
      // nonce attribute not copied through to script when csp enabled.
      Expect.equals(
        isCspEnabled ? "" : "an-example-nonce-string",
        script.getAttribute('nonce'),
      );
    }
    asyncEnd();
  });
}
