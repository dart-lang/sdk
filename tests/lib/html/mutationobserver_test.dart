// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mutationobserver_test;

import 'dart:async';
import 'dart:html';

import 'package:expect/minitest.dart';

// Due to https://code.google.com/p/chromium/issues/detail?id=329103
// mutationObservers sometimes do not fire if the node being observed is GCed
// so we keep around references to all nodes we have created mutation
// observers for.
var keepAlive = [];

void testSupported() {
  expect(MutationObserver.supported, true);
}

mutationCallback(Completer done, int count, expectation) {
  final nodes = [];

  callback(mutations, observer) {
    for (MutationRecord mutation in mutations) {
      for (Node node in mutation.addedNodes) {
        nodes.add(node);
      }
    }
    if (nodes.length >= count) {
      expect(nodes.length, count);
      expect(nodes, expectation);
      done.complete();
    }
  }

  // If it's not supported, don't block waiting for it.
  if (!MutationObserver.supported) {
    done.complete();
    return (mutations, observer) {};
  }

  return callback;
}

void testEmptyOptionsIsSyntaxError(expectation) {
  expect(() {
    var mutationObserver = new MutationObserver((mutations, observer) {
      expect(false, isTrue, reason: 'Should not be reached');
    });
    expect(() {
      mutationObserver.observe(document);
    }, throws);
  }, expectation);
}

Future<Null> testDirectParallelOptionsNamed(expectation) {
  final done = new Completer<Null>();
  expect(() {
    var container = new DivElement();
    keepAlive.add(container);
    var div1 = new DivElement();
    var div2 = new DivElement();
    var mutationObserver =
        new MutationObserver(mutationCallback(done, 2, equals([div1, div2])));
    mutationObserver.observe(container, childList: true);

    container.append(div1);
    container.append(div2);
  }, expectation);
  return done.future;
}

Future<Null> testDirectNestedOptionsNamed(expectation) {
  final done = new Completer<Null>();
  expect(() {
    var container = new DivElement();
    keepAlive.add(container);
    var div1 = new DivElement();
    var div2 = new DivElement();
    var mutationObserver =
        new MutationObserver(mutationCallback(done, 1, equals([div1])));
    mutationObserver.observe(container, childList: true);

    container.append(div1);
    div1.append(div2);
  }, expectation);
  return done.future;
}

Future<Null> testSubtreeOptionsNamed(expectation) {
  final done = new Completer<Null>();
  expect(() {
    var container = new DivElement();
    keepAlive.add(container);
    var div1 = new DivElement();
    var div2 = new DivElement();
    var mutationObserver =
        new MutationObserver(mutationCallback(done, 2, equals([div1, div2])));
    mutationObserver.observe(container, childList: true, subtree: true);

    container.append(div1);
    div1.append(div2);
  }, expectation);
  return done.future;
}

/**
 * Test suite for Mutation Observers. This is just a small set of sanity
 * checks, not a complete test suite.
 */
main() async {
  testSupported();

  final expectation = MutationObserver.supported ? returnsNormally : throws;
  testEmptyOptionsIsSyntaxError(expectation);
  await testDirectParallelOptionsNamed(expectation);
  await testDirectNestedOptionsNamed(expectation);
  await testSubtreeOptionsNamed(expectation);
}
