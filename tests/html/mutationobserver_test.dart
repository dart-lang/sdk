// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mutationobserver_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

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

      return expectAsyncUntil2(callback, () => done);
    }

    test('empty options is syntax error', () {
      expect(() {
        var mutationObserver = new MutationObserver(
            (mutations, observer) { expect(false, isTrue,
                reason: 'Should not be reached'); });
        expect(() { mutationObserver.observe(document, {}); },
               throws);
      }, expectation);
    });

    test('direct-parallel options-map', () {
      expect(() {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, options: {'childList': true});

        container.nodes.add(div1);
        container.nodes.add(div2);
      }, expectation);
    });

    test('direct-parallel options-named', () {
      expect(() {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, childList: true);

        container.nodes.add(div1);
        container.nodes.add(div2);
      }, expectation);
    });

    test('direct-nested options-named', () {
      expect(() {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver =
            new MutationObserver(mutationCallback(1, orderedEquals([div1])));
        mutationObserver.observe(container, childList: true);

        container.nodes.add(div1);
        div1.nodes.add(div2);
      }, expectation);
    });


    test('subtree options-map', () {
      expect(() {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container,
                                 options: {'childList': true, 'subtree': true});

        container.nodes.add(div1);
        div1.nodes.add(div2);
      }, expectation);
    });

    test('subtree options-named', () {
      expect(() {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, childList: true, subtree: true);

        container.nodes.add(div1);
        div1.nodes.add(div2);
      }, expectation);
    });

    test('mutation event', () {
      // Bug 8076 that not all optional params are optional in Dartium.
      var event = new MutationEvent('something', prevValue: 'prev',
          newValue: 'new', attrName: 'attr');
      expect(event is MutationEvent, isTrue);
      expect(event.prevValue, 'prev');
      expect(event.newValue, 'new');
      expect(event.attrName, 'attr');
    });
  });
}
