// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.event_path_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

@initMethod _main() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('bubbling in the right order', () {
    var item1 = query('#item1');
    var menuButton = query('#menuButton');
    // Note: polymer uses automatic node finding (menuButton.$.menu)
    // also note that their node finding code also reachs into the ids
    // from the parent shadow (menu.$.selectorContent instead of
    // menu.$.menuShadow.$.selectorContent)
    var menu = menuButton.shadowRoot.query('#menu');
    var overlay = menuButton.shadowRoot.query('#overlay');
    var expectedPath = <Node>[
        item1,
        menuButton.shadowRoot.query('#menuButtonContent'),
        menu.shadowRoot.olderShadowRoot.query('#selectorContent'),
        menu.shadowRoot.olderShadowRoot.query('#selectorDiv'),
        menu.shadowRoot.olderShadowRoot,
        menu.shadowRoot.query('#menuShadow'),
        menu.shadowRoot.query('#menuDiv'),
        menu.shadowRoot,
        menu,
        menuButton.shadowRoot.query('#menuButtonDiv'),
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
      node.on['x'].listen(expectAsync1((e) {
        expect(e.currentTarget, node);
        expect(x++, i);
      }));
    }

    item1.dispatchEvent(new Event('x', canBubble: true));
  });
}
