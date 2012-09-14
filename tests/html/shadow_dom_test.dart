// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('ShadowDOMTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  group('ShadowDOM tests', () {

    var div1, div2, shadowRoot, paragraph1, paragraph2;

    setUp(() {
      paragraph1 = new ParagraphElement();
      paragraph2 = new ParagraphElement();
      [paragraph1, paragraph2].forEach((p) { p.classes.add('foo');});
      div1 = new DivElement();
      div2 = new DivElement();
      div1.classes.add('foo');
      shadowRoot = new ShadowRoot(div2);
      shadowRoot.nodes.add(paragraph1);
      // No constructor for ContentElement exists yet.
      // See http://code.google.com/p/dart/issues/detail?id=3870.
      shadowRoot.nodes.add(new Element.tag('content'));
      div2.nodes.add(paragraph2);
      document.body.nodes.add(div1);
      document.body.nodes.add(div2);
    });

    test("Shadowed nodes aren't visible to queries from outside ShadowDOM", () {
      expect(queryAll('.foo'), equals([div1, paragraph2]));
    });

    test('Parent node of a shadow root must be null.', () {
      expect(shadowRoot.parent, isNull);
    });


    // TODO(samhop): test that <content> and <content select="foo"> and
    // <shadow>
    // work properly. This is blocked on having a good way to do browser
    // rendering tests.

    test('Querying in shadowed fragment respects the shadow boundary.', () {
      expect(shadowRoot.queryAll('.foo'), equals([paragraph1]));
    });
  });
}
