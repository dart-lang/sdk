// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test creates a scenario to simulate what happens if hunks are loaded
/// out of order and library loads are interleaved. The compiler should
/// initialize hunks in order and should only request each part file once
/// waiting on an in flight requests to resolve shared part files.
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
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:async';

import 'dart:_foreign_helper' show JS;

import 'load_in_correct_order_lib1.dart' deferred as d1;
import 'load_in_correct_order_lib2.dart' deferred as d2;
import 'load_in_correct_order_lib3.dart' deferred as d3;
// Load the same library three times to ensure we have coverage of the path
// where all parts are 1) in-flight and 2) already loaded.
import 'load_in_correct_order_lib3.dart' deferred as d4;
import 'load_in_correct_order_lib3.dart' deferred as d5;

main() {
  asyncStart();
  runTest().then((_) => asyncEnd());
}

runTest() async {
  setup();
  final loadD1 = d1.loadLibrary();
  final loadD2 = d2.loadLibrary();
  final loadD3 = d3.loadLibrary();
  // Now that d3 is loading, load d4 to ensure we cover the case where all parts
  // are already loading.
  final loadD4 = d4.loadLibrary();

  await Future.wait([loadD1, loadD2, loadD3, loadD4]);
  // Now that d3 and d4 are loaded, load d5 to ensure we cover the case where
  // all parts are already loaded.
  await d5.loadLibrary();

  Expect.equals(499, d1.c1.a.value);
  Expect.equals(500, d2.c2.c.value);
  Expect.equals(501, d3.c3.f.value);
  Expect.equals(501, d4.c3.f.value);
  Expect.equals(501, d5.c3.f.value);
}

void setup() {
  JS('', r"""
(function() {
// In d8 we don't have any way to load the content of the file via XHR, but we
// can use the "load" instruction. A hook is already defined in d8 for this
// reason.
self.isD8 = !!self.dartDeferredLibraryLoader;

// This test has 3 loadLibrary calls, this array contains how many hunks will be
// loaded by each call.
self.filesPerLoadLibraryCall = null;
// Number of parts for which a download has been "started" keyed by load ID.
self.incrementCounts = {};
// Number of parts for which we have loaded the JS keyed by load ID.
self.loadedCounts = {};
// Success callback for a library load keyed by load ID.
self.successCallbacks = {};
// URIs passed to the deferred load hook. Used to check there aren't duplicates.
self.providedUris = [];
// JS contents per URI.
self.content = {};

function equal(a, b) {
  return a.length === b.length &&
      a.every(function (value, index) {
        return value === b[index];
      });
}

self.initFilesPerLoadLibraryCall = function() {
  // We assume we load d1, then d2, then d3. However, we may have integer load
  // ids instead of the full load id.
  var loadOrder = Object.keys(init.deferredLibraryParts);
  var expectedLoadOrder = equal(loadOrder, ['d1', 'd2', 'd3', 'd4', 'd5']) ||
      equal(loadOrder, ['1', '2', '3', '4', '5']);
  if (!expectedLoadOrder) {
    throw 'Unexpected load order ' + loadOrder;
  }
  var uniques = {};
  self.filesPerLoadLibraryCall = {};
  for (var i = 0; i < loadOrder.length; i++) {
    var filesToLoad = 0;
    var parts = init.deferredLibraryParts[loadOrder[i]];
    for (var j = 0; j < parts.length; j++) {
      if (!uniques.hasOwnProperty(parts[j])) {
        uniques[parts[j]] = true;
        filesToLoad++;
      }
    }
    self.filesPerLoadLibraryCall[loadOrder[i]] = filesToLoad;
  }
};

// Download uri via an XHR
self.download = function(uris, uri, loadId) {
  var req = new XMLHttpRequest();
  req.addEventListener("load", function() {
    self.content[uri] = this.responseText;
    self.increment(uris, loadId);
  });
  req.open("GET", uri);
  req.send();
};

// Note that a new hunk is already available to be loaded, wait until all
// expected hunks are available and then evaluate their contents to actually
// load them.
self.increment = function(uris, loadId) {
  var count = self.incrementCounts[loadId] = self.incrementCounts[loadId] + 1;
  if (count == self.filesPerLoadLibraryCall[loadId]) {
    self.doActualLoads(uris, loadId);
  }
};

// Hook to control how we load hunks in bulk (we force them to be out of order).
self.dartDeferredLibraryMultiLoader = function(uris, success, error, loadId) {
  if (self.filesPerLoadLibraryCall == null) {
    self.initFilesPerLoadLibraryCall();
  }
  self.incrementCounts[loadId] = 0;
  self.loadedCounts[loadId] = 0;
  self.successCallbacks[loadId] = success;
  for (var i = 0; i < uris.length; i++) {
    var uri = uris[i];
    if (providedUris.some((u) => uri === u)) {
      throw 'Requested duplicate uri: ' + uri;
    }
    providedUris.push(uri);
    if (isD8) {
      self.increment(uris, loadId);
    } else {
      self.download(uris, uri, loadId);
    }
  }
};

// Do the actual load of the hunk and call the corresponding success callback if
// all loads are complete for the provided load ID.
self.doLoad = function(uris, i, loadId) {
  self.setTimeout(function () {
    var uri = uris[i];
    if (self.isD8) {
      load(uri);
    } else {
      eval(self.content[uri]);
    }
    var loadCount = self.loadedCounts[loadId] + 1;
    self.loadedCounts[loadId] = loadCount;
    var filesToLoad = self.filesPerLoadLibraryCall[loadId];
    if (loadCount == filesToLoad) {
      (self.successCallbacks[loadId])();
    }
  }, 0);
};

// Do all the loads for a load library call. On the first load library call,
// purposely load the hunks out of order.
self.doActualLoads = function(uris, loadId) {
  var total = self.incrementCounts[loadId];
  if (total >= 1) {
    // Load out of order, last first.
    self.doLoad(uris, total - 1, loadId);
    for (var i = 0; i < total - 1; i++) {
      self.doLoad(uris, i, loadId);
    }
  }
};
})()
""");
}
