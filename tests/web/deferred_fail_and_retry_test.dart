// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that when a deferred import fails to load, it is possible to retry.

import "deferred_fail_and_retry_lib.dart" deferred as lib;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:js" as js;

main() {
  // We patch document.body.appendChild to change the script src on first
  // invocation.
  js.context.callMethod("eval", [
    """
    retryCount = 0;
    if (self.document && self.document.body) {
      oldAppendChild = document.body.appendChild;
      replacement = function(element) {
        element.src = "non_existing.js";
        document.body.appendChild = oldAppendChild;
        document.body.appendChild(element);
        if (retryCount < 3) {
          retryCount++;
          document.body.appendChild = replacement;
        }
      }
      document.body.appendChild = replacement;
    }
    if (self.load) {
      oldLoad = load;
      replacement = function(uri) {
        load = oldLoad;
        load("non_existing.js");
        if (retryCount < 3) {
          retryCount++;
          load = replacement;
        }
      }
      load = replacement;
    }
  """
  ]);

  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.fail("Library should not have loaded");
  }, onError: (error) {
    lib.loadLibrary().then((_) {
      Expect.equals("loaded", lib.foo());
    }, onError: (error) {
      Expect.fail("Library should have loaded this time");
    }).whenComplete(() {
      asyncEnd();
    });
  });
}
