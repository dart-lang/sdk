// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library custom_elements_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

class CustomMixin {
  var mixinMethodCalled;

  void mixinMethod() {
    mixinMethodCalled = true;
  }
}

class CustomType extends HtmlElement with CustomMixin {
  bool createdCalled = false;

  factory CustomType() => null;
  CustomType.created() : super.created() {
    createdCalled = true;
    customCreatedCount++;
  }

  void invokeMixinMethod() {
    mixinMethod();
  }
}

int customCreatedCount = 0;

int nextTagId = 0;
String get nextTag => 'x-type${nextTagId++}';

class NotAnElement {}

main() {
  useHtmlIndividualConfiguration();

  setUp(() => customElementsReady);

  group('register', () {
    test('register', () {
      var tag = nextTag;
      document.registerElement(tag, CustomType);

      var element = new Element.tag(tag) as CustomType;
      expect(element, isNotNull);
      expect(element is CustomType, isTrue);
      expect(element.createdCalled, isTrue);
    });

    test('register twice', () {
      var tag = nextTag;
      document.registerElement(tag, CustomType);
      expect(() {
        document.registerElement(tag, CustomType);
      }, throws, reason: 'Cannot register a tag more than once.');

      var newTag = nextTag;
      document.registerElement(newTag, CustomType);

      var element = new Element.tag(newTag) as CustomType;
      expect(element, isNotNull);
      expect(element is CustomType, isTrue);
    });

    test('register null', () {
      expect(() {
        document.registerElement(nextTag, null);
      }, throws, reason: 'Cannot register a null type.');
    });

    test('register native', () {
      expect(() {
        document.registerElement(nextTag, BodyElement);
      }, throws, reason: 'Cannot register a native element.');
    });

    test('register non-element', () {
      expect(() {
        document.registerElement(nextTag, NotAnElement);
      }, throws, reason: 'Cannot register a non-element.');
    });
  });

  // TODO(vsm): Modify this test once we agree on the proper semantics.
  /*
  group('preregister', () {

    test('pre-registration construction', () {
      var tag = nextTag;
      var dom = new Element.html('<div><$tag></$tag></div>');

      var preElement = dom.children[0];
      expect(preElement, isNotNull);
      expect(preElement is HtmlElement, isTrue);
      expect(preElement is CustomType, isFalse);
      var firedOnPre = false;
      preElement.onFocus.listen((_) {
        firedOnPre = true;
      });

      document.registerElement(tag, CustomType);
      upgradeCustomElements(dom);

      var postElement = dom.children[0];
      expect(postElement, isNotNull);
      expect(postElement is CustomType, isTrue);
      expect(postElement.createdCalled, isTrue);

      // Element from first query remains an UnknownElement.
      expect(preElement is HtmlElement, isTrue);
      expect(preElement.parent, dom);
      expect(dom.children.length, 1);

      var firedOnPost = false;
      postElement.onFocus.listen((_) {
        firedOnPost = true;
      });
      // Event handlers persist on old and new element.
      postElement.dispatchEvent(new Event('focus'));
      expect(firedOnPre, isTrue);
      expect(firedOnPost, isTrue);
    });
  });*/

  group('innerHtml', () {
    test('query', () {
      var tag = nextTag;
      document.registerElement(tag, CustomType);
      var element = new DivElement();
      element.setInnerHtml('<$tag></$tag>',
          treeSanitizer: new NullTreeSanitizer());
      upgradeCustomElements(element);
      document.body.nodes.add(element);
      var queried = query(tag) as CustomType;

      expect(queried, isNotNull);
      expect(queried is CustomType, isTrue);
      expect(queried.createdCalled, isTrue);
    });

    test('query id', () {
      var tag = nextTag;
      document.registerElement(tag, CustomType);
      var element = new DivElement();
      element.setInnerHtml('<$tag id="someid"></$tag>',
          treeSanitizer: new NullTreeSanitizer());
      upgradeCustomElements(element);
      document.body.nodes.add(element);
      var queried = query('#someid') as CustomType;

      expect(queried, isNotNull);
      expect(queried is CustomType, isTrue);
      expect(queried.id, "someid");
    });
  });

  group('lifecycle', () {
    test('created', () {
      int oldCount = customCreatedCount;
      var tag = nextTag;
      document.registerElement(tag, CustomType);
      var element = new DivElement();
      element.setInnerHtml('<$tag></$tag>',
          treeSanitizer: new NullTreeSanitizer());
      upgradeCustomElements(element);
      document.body.nodes.add(element);
      expect(customCreatedCount, oldCount + 1);
    });
  });

  group('mixins', () {
    test('can invoke mixin methods', () {
      var tag = nextTag;
      document.registerElement(tag, CustomType);

      var element = new Element.tag(tag) as CustomType;
      element.invokeMixinMethod();
      expect(element.mixinMethodCalled, isTrue);
    });
  });
}
