// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "deferred_multi_app_lib.dart" deferred as lib;
import "dart:async";
import "dart:html";
import "package:expect/expect.dart";

main() {
  Element state = querySelector("#state");
  if (state.text == "1") {
    lib.loadLibrary().then((_) {
      var a = lib.one();
      Expect.equals("one", a);
      window.postMessage(a, '*');
    });
    state.text = "2";
  } else {
    new Timer(new Duration(milliseconds: 100), () {
      lib.loadLibrary().then((_) {
        var a = lib.two();
        Expect.equals("two", a);
        window.postMessage(a, '*');
      });
    });
  }
}
