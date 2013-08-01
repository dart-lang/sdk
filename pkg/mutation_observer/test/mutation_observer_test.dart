// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mutation_observer_test;

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() {
  useHtmlConfiguration();

  // Load the MutationObserver polyfill.
  HttpRequest.getString('/root_dart/pkg/mutation_observer/lib/'
      'mutation_observer.min.js').then((code) {

    // Force MutationObserver polyfill to be used so we can test it, even in
    // browsers with native support.
    document.head.children.add(new ScriptElement()
        ..text = 'window.MutationObserver = void 0;'
                 'window.WebKitMutationObserver = void 0;'
                 '$code');

    testMutationObserver();
  });
}

/**
 * Test suite for Mutation Observers. This is just a small set of sanity
 * checks, not a complete test suite.
 */
testMutationObserver() {
  group('supported', () {
    test('supported', () {
      expect(MutationObserver.supported, true, reason: 'polyfill loaded.');
    });
  });

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

      return expectAsyncUntil2(callback, () => done);
    }

    test('empty options is syntax error', () {
      var mutationObserver = new MutationObserver(
          (mutations, observer) { expect(false, isTrue,
              reason: 'Should not be reached'); });
      expect(() { mutationObserver.observe(document, {}); },
             throws);
    });

    test('direct-parallel options-named', () {
      var container = new DivElement();
      var div1 = new DivElement();
      var div2 = new DivElement();
      var mutationObserver = new MutationObserver(
          mutationCallback(2, orderedEquals([div1, div2])));
      mutationObserver.observe(container, childList: true);

      container.append(div1);
      container.append(div2);
    });

    test('direct-nested options-named', () {
      var container = new DivElement();
      var div1 = new DivElement();
      var div2 = new DivElement();
      var mutationObserver =
          new MutationObserver(mutationCallback(1, orderedEquals([div1])));
      mutationObserver.observe(container, childList: true);

      container.append(div1);
      div1.append(div2);
    });

    test('subtree options-named', () {
      var container = new DivElement();
      var div1 = new DivElement();
      var div2 = new DivElement();
      var mutationObserver = new MutationObserver(
          mutationCallback(2, orderedEquals([div1, div2])));
      mutationObserver.observe(container, childList: true, subtree: true);

      container.append(div1);
      div1.append(div2);
    });

    test('mutation event', () {
      var event = new MutationEvent('something', prevValue: 'prev',
          newValue: 'new', attrName: 'attr');
      expect(event is MutationEvent, isTrue);
      expect(event.prevValue, 'prev');
      expect(event.newValue, 'new');
      expect(event.attrName, 'attr');
    });
  });
}
