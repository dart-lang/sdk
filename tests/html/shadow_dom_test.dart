// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ShadowDOMTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

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
      [paragraph1, paragraph2].forEach((p) { p.classes.add('foo');});
      div1 = new DivElement();
      div2 = new DivElement();
      div1.classes.add('foo');
      shadowRoot = div2.createShadowRoot();
      shadowRoot.nodes.add(paragraph1);
      shadowRoot.nodes.add(new ContentElement());
      div2.nodes.add(paragraph2);
      document.body.nodes.add(div1);
      document.body.nodes.add(div2);
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
  });
}
