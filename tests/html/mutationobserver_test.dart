// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mutationobserver_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

// Due to https://code.google.com/p/chromium/issues/detail?id=329103
// mutationObservers sometimes do not fire if the node being observed is GCed
// so we keep around references to all nodes we have created mutation
// observers for.
var keepAlive = [];

/**
 * Test suite for Mutation Observers. This is just a small set of sanity
 * checks, not a complete test suite.
 */
main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(MutationObserver.supported, true);
    });
  });

  var expectation = MutationObserver.supported ? returnsNormally : throws;

  group('childList', () {
    mutationCallback(count, expectation) {
      var done = false;
      var nodes = [];

      callback(mutations, observer) {
        for (MutationRecord mutation in mutations) {
          for (Node node in mutation.addedNodes) {
            nodes.add(node);
          }
        }
        if (nodes.length >= count) {
          done = true;
          expect(nodes.length, count);
          expect(nodes, expectation);
        }
      }

      // If it's not supported, don't block waiting for it.
      if (!MutationObserver.supported) {
        return () => done;
      }

      return expectAsyncUntil(callback, () => done);
    }

    test('empty options is syntax error', () {
      expect(() {
        var mutationObserver = new MutationObserver((mutations, observer) {
          expect(false, isTrue, reason: 'Should not be reached');
        });
        expect(() {
          mutationObserver.observe(document, {});
        }, throws);
      }, expectation);
    });

    test('direct-parallel options-named', () {
      expect(() {
        var container = new DivElement();
        keepAlive.add(container);
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, childList: true);

        container.append(div1);
        container.append(div2);
      }, expectation);
    });

    test('direct-nested options-named', () {
      expect(() {
        var container = new DivElement();
        keepAlive.add(container);
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver =
            new MutationObserver(mutationCallback(1, orderedEquals([div1])));
        mutationObserver.observe(container, childList: true);

        container.append(div1);
        div1.append(div2);
      }, expectation);
    });

    test('subtree options-named', () {
      expect(() {
        var container = new DivElement();
        keepAlive.add(container);
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, childList: true, subtree: true);

        container.append(div1);
        div1.append(div2);
      }, expectation);
    });
  });
}
