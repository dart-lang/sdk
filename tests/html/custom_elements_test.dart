// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library custom_elements_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

class CustomMixin {
  var mixinMethodCalled;

  void mixinMethod() {
    mixinMethodCalled = true;
  }
}

class CustomType extends HtmlElement with CustomMixin{
  factory CustomType() => null;
  bool onCreatedCalled; // = false;
  void onCreated() {
    onCreatedCalled = true;
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

  group('register', () {
    test('register', () {
      var tag = nextTag;
      document.register(tag, CustomType);

      var element = new Element.tag(tag);
      expect(element, isNotNull);
      expect(element is CustomType, isTrue);
      expect(element.onCreatedCalled, isTrue);
    });

    test('register twice', () {
      var tag = nextTag;
      document.register(tag, CustomType);
      expect(() {
        document.register(tag, CustomType);
      }, throws, reason: 'Cannot register a tag more than once.');

      var newTag = nextTag;
      document.register(newTag, CustomType);

      var element = new Element.tag(newTag);
      expect(element, isNotNull);
      expect(element is CustomType, isTrue);
    });

    test('register null', () {
      expect(() {
        document.register(nextTag, null);
      }, throws, reason: 'Cannot register a null type.');
    });

    test('register native', () {
      expect(() {
        document.register(nextTag, BodyElement);
      }, throws, reason: 'Cannot register a native element.');
    });

    test('register non-element', () {
      expect(() {
        document.register(nextTag, NotAnElement);
      }, throws, reason: 'Cannot register a non-element.');
    });
  });

  group('preregister', () {
    // TODO(vsm): Modify this test once we agree on the proper semantics.
    test('pre-registration construction', () {
      var tag = nextTag;
      var dom = new Element.html('<div><$tag></$tag></div>');
      var preElement = dom.children[0];
      expect(preElement, isNotNull);
      expect(preElement is UnknownElement, isTrue);
      var firedOnPre = false;
      preElement.onFocus.listen((_) {
        firedOnPre = true;
      });

      document.register(tag, CustomType);

      var postElement = dom.children[0];
      expect(postElement, isNotNull);
      expect(postElement is CustomType, isTrue);
      expect(postElement.onCreatedCalled, isTrue);

      // Element from first query remains an UnknownElement.
      expect(preElement is UnknownElement, isTrue);
      expect(preElement.parent, isNull);
      expect(dom.children.length, 1);

      var firedOnPost = false;
      postElement.onFocus.listen((_) {
        firedOnPost = true;
      });
      // Event handlers should not persist to new element.
      postElement.dispatchEvent(new Event('focus'));
      expect(firedOnPre, isFalse);
      expect(firedOnPost, isTrue);
    });
  });

  group('innerHtml', () {
    test('query', () {
      var tag = nextTag;
      document.register(tag, CustomType);
      var element = new DivElement();
      element.innerHtml = '<$tag></$tag>';
      document.body.nodes.add(element);
      var queried = query(tag);

      expect(queried, isNotNull);
      expect(queried is CustomType, isTrue);
      expect(queried.onCreatedCalled, isTrue);
    });

    test('query id', () {
      var tag = nextTag;
      document.register(tag, CustomType);
      var element = new DivElement();
      element.innerHtml = '<$tag id="someid"></$tag>';
      document.body.nodes.add(element);
      var queried = query('#someid');

      expect(queried, isNotNull);
      expect(queried is CustomType, isTrue);
      expect(queried.id, "someid");
    });
  });

  group('lifecycle', () {
    test('onCreated', () {
      int oldCount = customCreatedCount;
      var tag = nextTag;
      document.register(tag, CustomType);
      var element = new DivElement();
      element.innerHtml = '<$tag></$tag>';
      document.body.nodes.add(element);
      expect(customCreatedCount, oldCount + 1);
    });
  });

  group('mixins', () {
    test('can invoke mixin methods', () {
      var tag = nextTag;
      document.register(tag, CustomType);

      var element = new Element.tag(tag);
      element.invokeMixinMethod();
      expect(element.mixinMethodCalled, isTrue);
    });
  });
}
