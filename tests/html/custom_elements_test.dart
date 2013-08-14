// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library custom_elements_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

class CustomType extends Element {
  factory CustomType() => null;

  bool onCreatedCalled = false;
  void onCreated() {
    onCreatedCalled = true;
    customCreatedCount++;
  }
}

int customCreatedCount = 0;

class NotAnElement {}

main() {
  useHtmlIndividualConfiguration();

  group('register', () {
    test('register', () {
      document.register('x-type1', CustomType);

      var element = new Element.tag('x-type1');
      expect(element, isNotNull);
      expect(element is CustomType, isTrue);
      expect(element.onCreatedCalled, isTrue);
    });

    test('register twice', () {
      document.register('x-type2', CustomType);
      expect(() {
        document.register('x-type2', CustomType);
      }, throws, reason: 'Cannot register a tag more than once.');

      document.register('x-type3', CustomType);

      var element = new Element.tag('x-type3');
      expect(element, isNotNull);
      expect(element is CustomType, isTrue);
    });

    test('register null', () {
      expect(() {
        document.register('x-type4', null);
      }, throws, reason: 'Cannot register a null type.');
    });

    test('register native', () {
      expect(() {
        document.register('x-type5', BodyElement);
      }, throws, reason: 'Cannot register a native element.');
    });

    test('register non-element', () {
      expect(() {
        document.register('x-type6', NotAnElement);
      }, throws, reason: 'Cannot register a non-element.');
    });
  });

  group('preregister', () {
    // TODO(vsm): Modify this test once we agree on the proper semantics.
    test('pre-registration construction', () {
      var dom = new Element.html('<div><x-type7></x-type7></div>');
      var preElement = dom.children[0];
      expect(preElement, isNotNull);
      expect(preElement is UnknownElement, isTrue);
      var firedOnPre = false;
      preElement.onFocus.listen((_) {
        firedOnPre = true;
      });

      document.register('x-type7', CustomType);

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
      document.register('x-type8', CustomType);
      var element = new DivElement();
      element.innerHtml = '<x-type8></x-type8>';
      document.body.nodes.add(element);
      var queried = query('x-type8');

      expect(queried, isNotNull);
      expect(queried is CustomType, isTrue);
      expect(queried.onCreatedCalled, isTrue);
    });
  });

  group('lifecycle', () {
    test('onCreated', () {
      int oldCount = customCreatedCount;

      document.register('x-type9', CustomType);
      var element = new DivElement();
      element.innerHtml = '<x-type9></x-type9>';
      document.body.nodes.add(element);
      expect(customCreatedCount, oldCount + 1);
    });
  });
}
