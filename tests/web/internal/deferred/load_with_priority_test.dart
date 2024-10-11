// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:async';

import 'dart:_foreign_helper' show JS;

@pragma('dart2js:load-priority', 'someArg1')
import 'load_with_priority_lib.dart' deferred as lib1;
@pragma('dart2js:load-priority', 'someArg2')
import 'load_with_priority_lib.dart' deferred as lib2;
@pragma('dart2js:load-priority', 'ignored1')
import 'load_with_priority_lib.dart' deferred as lib3;
@pragma('dart2js:load-priority', 'ignored2')
import 'load_with_priority_lib.dart' deferred as lib4;

main() {
  asyncStart();
  runTest().then((_) => asyncEnd());
}

@pragma('dart2js:load-priority', 'someArg4')
Future<void> testLoadOverride() async {
  await lib4.loadLibrary();
  Expect.equals(4, lib4.d);
}

runTest() async {
  setup();
  await lib1.loadLibrary();
  Expect.equals(1, lib1.a);

  await lib2.loadLibrary();
  Expect.equals(2, lib2.b);

  @pragma('dart2js:load-priority', 'someArg3')
  final unused1 = await lib3.loadLibrary();
  Expect.equals(3, lib3.c);

  await testLoadOverride();
  tearDown();
}

void tearDown() {
  // `wasCalled` will be false for DDC since there is no deferred load hook.
  if (JS('bool', 'self.wasCalled')) {
    Expect.equals(4, JS('', 'self.index'));
  }
}

void setup() {
  JS('', r"""
(function() {
// In d8 we don't have any way to load the content of the file via XHR, but we
// can use the "load" instruction. A hook is already defined in d8 for this
// reason.
self.isD8 = !!self.dartDeferredLibraryLoader;
self.index = 0;
self.wasCalled = false;
self.expectedPriorities = ['someArg1', 'someArg2', 'someArg3', 'someArg4'];

// Download uri via an XHR
self.download = function(uri, success) {
  var req = new XMLHttpRequest();
  req.addEventListener("load", function() {
    eval(this.responseText);
    success();
  });
  req.open("GET", uri);
  req.send();
};

self.checkPriority = function(priority) {
  if (priority !== self.expectedPriorities[self.index]) {
    throw 'Unexpected priority from load index ' + self.index;
  }
  self.index++;
};

self.dartDeferredLibraryLoader = function(uri, success, error, loadId, priority) {
  self.checkPriority(priority);
  self.wasCalled = true;
  if (self.isD8) {
    load(uri);
    success();
  } else {
    self.download(uri, success);
  }
};
})()
""");
}
