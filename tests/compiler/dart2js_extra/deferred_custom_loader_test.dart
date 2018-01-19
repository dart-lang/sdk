// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:_foreign_helper' show JS;

import 'deferred_custom_loader_lib.dart' deferred as def;

void setup() {
  JS('', r"""
(function(){
  // In d8 we don't have any way to load the content of the file, so just use
  // the preamble's loader.
  if (!self.dartDeferredLibraryLoader) {
    self.dartDeferredLibraryLoader = function(uri, success, error) {
      var req = new XMLHttpRequest();
      req.addEventListener("load", function() {
        eval(this.responseText);
        success();
      });
      req.open("GET", uri);
      req.send();
    };
 }
})()
""");
}

runTest() async {
  setup();
  await def.loadLibrary();
  Expect.equals(499, def.foo());
}

main() {
  asyncStart();
  runTest().then((_) => asyncEnd());
}
