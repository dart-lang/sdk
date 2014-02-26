// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.event_path_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

@CustomTag("x-selector")
class XSelector extends PolymerElement {
  XSelector.created() : super.created();
}

@CustomTag("x-overlay")
class XOverlay extends PolymerElement {
  XOverlay.created() : super.created();
}

@CustomTag("x-menu")
class XMenu extends PolymerElement {
  XMenu.created() : super.created();
}

@CustomTag("x-menu-button")
class XMenuButton extends PolymerElement {
  XMenuButton.created() : super.created();
}

main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('bubbling in the right order', () {
    var item1 = querySelector('#item1');
    var menuButton = querySelector('#menuButton');
    // Note: polymer uses automatic node finding (menuButton.$.menu)
    // also note that their node finding code also reachs into the ids
    // from the parent shadow (menu.$.selectorContent instead of
    // menu.$.menuShadow.$.selectorContent)
    var menu = menuButton.shadowRoot.querySelector('#menu');
    var overlay = menuButton.shadowRoot.querySelector('#overlay');
    var expectedPath = <Node>[
        item1,
        menuButton.shadowRoot.querySelector('#menuButtonContent'),
        menu.shadowRoot.olderShadowRoot.querySelector('#selectorContent'),
        menu.shadowRoot.olderShadowRoot.querySelector('#selectorDiv'),
        menu.shadowRoot.olderShadowRoot,
        menu.shadowRoot.querySelector('#menuShadow'),
        menu.shadowRoot.querySelector('#menuDiv'),
        menu.shadowRoot,
        menu,
        menuButton.shadowRoot.querySelector('#menuButtonDiv'),
        // TODO(sigmund): this test is currently broken because currently
        // registerElement is sensitive to the order in which each custom
        // element is registered. When fixed, we should be able to add the
        // following three targets:
        //   overlay.shadowRoot.query('#overlayContent'),
        //   overlay.shadowRoot,
        //   overlay,
        menuButton.shadowRoot,
        menuButton
    ];
    var x = 0;
    for (int i = 0; i < expectedPath.length; i++) {
      var node = expectedPath[i];
      expect(node, isNotNull, reason: "Should not be null at $i");
      node.on['x'].listen(expectAsync((e) {
        expect(e.currentTarget, node);
        expect(x++, i);
      }));
    }

    item1.dispatchEvent(new Event('x', canBubble: true));
  });
}
