// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(ShadowRoot.supported, true);
    });
  });

  group('ShadowDOM_tests', () {
    var div1, div2, shadowRoot, paragraph1, paragraph2;

    init() {
      paragraph1 = new ParagraphElement();
      paragraph2 = new ParagraphElement();
      [paragraph1, paragraph2].forEach((p) {
        p.classes.add('foo');
      });
      div1 = new DivElement();
      div2 = new DivElement();
      div1.classes.add('foo');
      shadowRoot = div2.createShadowRoot();
      shadowRoot.append(paragraph1);
      shadowRoot.append(new ContentElement());
      div2.append(paragraph2);
      document.body.append(div1);
      document.body.append(div2);
    }

    var expectation = ShadowRoot.supported ? returnsNormally : throws;

    test("Shadowed nodes aren't visible to queries from outside ShadowDOM", () {
      expect(() {
        init();

        expect(queryAll('.foo'), equals([div1, paragraph2]));
      }, expectation);
    });

    test('Parent node of a shadow root must be null.', () {
      expect(() {
        init();

        expect(shadowRoot.parent, isNull);
      }, expectation);
    });

    // TODO(samhop): test that <content> and <content select="foo"> and
    // <shadow>
    // work properly. This is blocked on having a good way to do browser
    // rendering tests.

    test('Querying in shadowed fragment respects the shadow boundary.', () {
      expect(() {
        init();

        expect(shadowRoot.queryAll('.foo'), equals([paragraph1]));
      }, expectation);
    });

    if (ShadowRoot.supported) {
      test('Shadowroot contents are distributed', () {
        var div = new DivElement();

        var box1 = new DivElement()..classes.add('foo');
        div.append(box1);

        var box2 = new DivElement();
        div.append(box2);

        var sRoot = div.createShadowRoot();
        var content1 = new ContentElement()..select = ".foo";
        sRoot.append(content1);

        var content2 = new ContentElement();
        sRoot.append(content2);

        expect(content1.getDistributedNodes(), [box1]);
        expect(content2.getDistributedNodes(), [box2]);
      });
    }
  });
}
