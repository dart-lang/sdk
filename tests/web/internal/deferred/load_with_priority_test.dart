// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:async';

import 'dart:_foreign_helper' show JS;

@pragma('dart2js:load-priority:high')
import 'load_with_priority_lib.dart' deferred as highLib;
@pragma('dart2js:load-priority:normal')
import 'load_with_priority_lib.dart' deferred as normalExplicitLib;
import 'load_with_priority_lib.dart' deferred as normalImplicitLib;
import 'load_with_priority_lib.dart' deferred as highLocalLib;
import 'load_with_priority_lib.dart' deferred as normalLocalLib;
import 'load_with_priority_lib.dart' deferred as highMemberLib;
import 'load_with_priority_lib.dart' deferred as normalMemberLib;

main() {
  asyncStart();
  runTest().then((_) => asyncEnd());
}

@pragma('dart2js:load-priority:normal')
Future<void> testNormalLoad() async {
  await normalMemberLib.loadLibrary();
  Expect.equals(6, normalMemberLib.f);
}

@pragma('dart2js:load-priority:high')
Future<void> testHighLoad() async {
  await highMemberLib.loadLibrary();
  Expect.equals(7, highMemberLib.g);
}

runTest() async {
  setup();
  await highLib.loadLibrary();
  Expect.equals(1, highLib.a);

  await normalExplicitLib.loadLibrary();
  Expect.equals(2, normalExplicitLib.b);

  await normalImplicitLib.loadLibrary();
  Expect.equals(3, normalImplicitLib.c);

  @pragma('dart2js:load-priority:high')
  final unused1 = await highLocalLib.loadLibrary();
  Expect.equals(4, highLocalLib.d);

  @pragma('dart2js:load-priority:normal')
  final unused2 = await normalLocalLib.loadLibrary();
  Expect.equals(5, normalLocalLib.e);

  await testNormalLoad();
  await testHighLoad();
  tearDown();
}

void tearDown() {
  // `wasCalled` will be false for DDC since there is no deferred load hook.
  if (JS('bool', 'self.wasCalled')) {
    Expect.equals(7, JS('', 'self.index'));
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
self.expectedPriorities = [1, 0, 0, 1, 0, 0, 1];

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
