// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library custom_element.test.custom_element_test;

import 'dart:async';
import 'dart:html';
import 'package:custom_element/custom_element.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useHtmlConfiguration();

  setUp(() {
    // Load the MutationObserver polyfill if needed.
    if (!MutationObserver.supported) {
      var script = new ScriptElement()
          ..src =  '/packages/mutation_observer/mutation_observer.js';
      document.head.append(script);
      return script.onLoad.first;
    }
  });

  test('register creates the element and calls lifecycle methods', () {
    // Add element to the page.
    var element = new Element.html('<fancy-button>foo bar</fancy-button>',
        treeSanitizer: new NullTreeSanitizer());
    document.body.nodes.add(element);

    var xtag = null;
    registerCustomElement('fancy-button', () => xtag = new FancyButton());
    expect(xtag, isNotNull, reason: 'FancyButton was created');
    expect(element.xtag, xtag, reason: 'xtag pointer should be set');
    expect(xtag.host, element, reason: 'host pointer should be set');
    expect(xtag.lifecycle, ['created']);
    return new Future(() {
      expect(xtag.lifecycle, ['created', 'inserted']);
      element.remove();
      // TODO(jmesserly): the extra future here is to give IE9 time to deliver
      // its event. This seems wrong. We'll probably need some cooperation
      // between Dart and the polyfill to coordinate the microtask event loop.
      return new Future(() => new Future(() {
        expect(xtag.lifecycle, ['created', 'inserted', 'removed']);
      }));
    });
  });

  test('create a component in code', () {
    var element = createElement('super-button');
    expect(element.xtag, element, reason: 'element not registered');

    var xtag = null;
    registerCustomElement('super-button', () => xtag = new FancyButton());

    element = createElement('super-button');
    expect(xtag, isNotNull, reason: 'FancyButton was created');
    expect(element.xtag, xtag, reason: 'xtag pointer should be set');
    expect(xtag.host, element, reason: 'host pointer should be set');
    expect(xtag.lifecycle, ['created']);
    return new Future(() {
      expect(xtag.lifecycle, ['created'], reason: 'not inserted into document');

      document.body.nodes.add(element);
      return new Future(() {
        expect(xtag.lifecycle, ['created'],
            reason: 'mutation observer not implemented yet');

        element.remove();
        return new Future(() {
          expect(xtag.lifecycle, ['created'],
              reason: 'mutation observer not implemented yet');
        });
      });
    });
  });
}

class FancyButton extends CustomElement {
  final lifecycle = [];
  created() {
    super.created();
    lifecycle.add('created');
  }
  inserted() {
    super.inserted();
    lifecycle.add('inserted');
  }
  removed() {
    super.removed();
    lifecycle.add('removed');
  }
}

/**
 * Sanitizer which does nothing.
 */
class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}
