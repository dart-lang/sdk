// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test creates a scenario to simulate what happens if hunks are loaded
/// out of order. The compiler should initialize hunks in order regardless, but
/// may do so in parallel while some hunks are not loaded yet.
///
/// To create a good number of hunks we created an import graph with 3 deferred
/// imports and 7 libraries, we made pair-wise dependencies to be able to create
/// 2^3 (8) partitions of the program (including the main hunk) that end up
/// corresponding to the libraries themselves. In particular, the import graph
/// looks like this:
///
///   main ---> 1, 2, 3  (deferred)
///      1 --->         4, 5,    7
///      2 --->            5, 6, 7
///      3 --->         4,    6, 7
///
/// So each library maps to a deferred hunk:
///   library 1 = hunk of code only used by 1
///   library 2 = hunk of code only used by 2
///   library 3 = hunk of code only used by 3
///   library 4 = hunk of code shared by 1 & 3
///   library 5 = hunk of code shared by 1 & 2
///   library 6 = hunk of code shared by 2 & 3
///   library 7 = hunk of shared by 1, 2 & 3
///
/// In the future we may optimize and combine hunks, at that point this test
/// needs to be rewritten.
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:async';

import 'dart:_foreign_helper' show JS;

import 'load_in_correct_order_lib1.dart' deferred as d1;
import 'load_in_correct_order_lib2.dart' deferred as d2;
import 'load_in_correct_order_lib3.dart' deferred as d3;

main() {
  asyncStart();
  runTest().then((_) => asyncEnd());
}

runTest() async {
  setup();
  await d1.loadLibrary();
  Expect.equals(499, d1.c1.a.value);

  // The logic below expects loadLibrary calls to happen on a new microtask.
  await new Future(() {});
  await d2.loadLibrary();
  Expect.equals(500, d2.c2.c.value);

  await new Future(() {});
  await d3.loadLibrary();
  Expect.equals(501, d3.c3.f.value);
}

void setup() {
  JS('', r"""
(function() {
// In d8 we don't have any way to load the content of the file via XHR, but we
// can use the "load" instruction. A hook is already defined in d8 for this
// reason.
self.isD8 = !!self.dartDeferredLibraryLoader;

self.uris = [];
self.successCallbacks = [];
self.total = 0;
self.content = {};

// This test has 3 loadLibrary calls, this array contains how many hunks will be
// loaded by each call.
self.currentLoadLibraryCall = 0;
self.filesPerLoadLibraryCall = [4, 2, 1];

// Download uri via an XHR
self.download = function(uri) {
  var req = new XMLHttpRequest();
  req.addEventListener("load", function() {
    self.content[uri] = this.responseText;
    self.increment();
  });
  req.open("GET", uri);
  req.send();
};

// Note that a new hunk is already avaiable to be loaded, wait until all
// expected hunks are available and then evaluate their contents to actually
// load them.
self.increment = function() {
  self.total++;
  if (self.total == self.filesPerLoadLibraryCall[self.currentLoadLibraryCall]) {
    self.doActualLoads();
  }
};

// Hook to control how we load hunks (we force them to be out of order).
self.dartDeferredLibraryLoader = function(uri, success, error) {
  self.uris.push(uri);
  self.successCallbacks.push(success);
  if (isD8) {
    self.increment();
  } else {
    self.download(uri);
  }
};

// Do the actual load of the hunk and call the corresponding success callback.
self.doLoad = function(i) {
  self.setTimeout(function () {
  var uri = self.uris[i];
  if (self.isD8) {
    load(uri);
  } else {
    eval(self.content[uri]);
  }
  (self.successCallbacks[i])();
  }, 0);
};

// Do all the loads for a load library call. On the first load library call,
// purposely load the hunks out of order.
self.doActualLoads = function() {
  self.currentLoadLibraryCall++;
  if (self.total == 4) {
    self.doLoad(3); // load purposely out of order!
    self.doLoad(0);
    self.doLoad(1);
    self.doLoad(2);
  } else {
    for (var i = 0; i < self.total; i++) {
      self.doLoad(i);
    }
  }
  setTimeout(self.reset, 0);
};

/// Reset the internal state to prepare for a new load library call.
self.reset = function() {
  self.total = 0;
  self.uris = [];
  self.successCallbacks = [];
};
})()
""");
}
