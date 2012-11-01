// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mutationobserver_test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

/**
 * Test suite for Mutation Observers. This is just a small set of sanity
 * checks, not a complete test suite.
 */
main() {
  useHtmlConfiguration();

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

    test('direct-parallel options-map', () {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, options: {'childList': true});

        container.nodes.add(div1);
        container.nodes.add(div2);
      });

    test('direct-parallel options-named', () {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, childList: true);

        container.nodes.add(div1);
        container.nodes.add(div2);
      });

    test('direct-nested options-named', () {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver =
            new MutationObserver(mutationCallback(1, orderedEquals([div1])));
        mutationObserver.observe(container, childList: true);

        container.nodes.add(div1);
        div1.nodes.add(div2);
      });


    test('subtree options-map', () {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container,
                                 options: {'childList': true, 'subtree': true});

        container.nodes.add(div1);
        div1.nodes.add(div2);
      });

    test('subtree options-named', () {
        var container = new DivElement();
        var div1 = new DivElement();
        var div2 = new DivElement();
        var mutationObserver = new MutationObserver(
            mutationCallback(2, orderedEquals([div1, div2])));
        mutationObserver.observe(container, childList: true, subtree: true);

        container.nodes.add(div1);
        div1.nodes.add(div2);
      });
  });
}
