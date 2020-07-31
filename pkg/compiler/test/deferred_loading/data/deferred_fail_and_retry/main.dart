// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that when a deferred import fails to load, it is possible to retry.

import 'lib.dart' deferred as lib;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:js" as js;

/*member: main:OutputUnit(main, {})*/
main() {
  // We patch document.body.appendChild to change the script src on first
  // invocation.
  js.context.callMethod("eval", [
    """
    if (self.document) {
      oldAppendChild = document.body.appendChild;
      document.body.appendChild = function(element) {
        element.src = "non_existing.js";
        document.body.appendChild = oldAppendChild;
        document.body.appendChild(element);
      }
    }
    if (self.load) {
      oldLoad = load;
      load = function(uri) {
        load = oldLoad;
        load("non_existing.js");
      }
    }
  """
  ]);

  asyncStart();
  lib.loadLibrary().then(/*OutputUnit(main, {})*/ (_) {
    Expect.fail("Library should not have loaded");
  }, onError: /*OutputUnit(main, {})*/ (error) {
    lib.loadLibrary().then(/*OutputUnit(main, {})*/ (_) {
      Expect.equals("loaded", lib.foo());
    }, onError: /*OutputUnit(main, {})*/ (error) {
      Expect.fail("Library should have loaded this time");
    }).whenComplete(/*OutputUnit(main, {})*/ () {
      asyncEnd();
    });
  });
}
