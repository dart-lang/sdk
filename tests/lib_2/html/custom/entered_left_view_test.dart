// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entered_left_view_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'package:test/test.dart';
import '../utils.dart';

var invocations = [];

class Foo extends HtmlElement {
  factory Foo() => null;
  Foo.created() : super.created() {
    invocations.add('created');
  }

  void attached() {
    invocations.add('attached');
  }

  void enteredView() {
    // Deprecated name. Should never be called since we override "attached".
    invocations.add('enteredView');
  }

  void detached() {
    invocations.add('detached');
  }

  void leftView() {
    // Deprecated name. Should never be called since we override "detached".
    invocations.add('leftView');
  }

  void attributeChanged(String name, String oldValue, String newValue) {
    invocations.add('attribute changed');
  }
}

// Test that the deprecated callbacks still work.
class FooOldCallbacks extends HtmlElement {
  factory FooOldCallbacks() => null;
  FooOldCallbacks.created() : super.created() {
    invocations.add('created');
  }

  void enteredView() {
    invocations.add('enteredView');
  }

  void leftView() {
    invocations.add('leftView');
  }

  void attributeChanged(String name, String oldValue, String newValue) {
    invocations.add('attribute changed');
  }
}

main() {
  // Adapted from Blink's
  // fast/dom/custom/attached-detached-document.html test.

  var docA = document;
  var docB = document.implementation.createHtmlDocument('');

  var nullSanitizer = new NullTreeSanitizer();

  var registeredTypes = false;
  setUp(() => customElementsReady.then((_) {
        if (registeredTypes) return;
        registeredTypes = true;
        document.registerElement('x-a', Foo);
        document.registerElement('x-a-old', FooOldCallbacks);
      }));

  group('standard_events', () {
    var a;
    setUp(() {
      invocations = [];
    });

    test('Created', () {
      a = new Element.tag('x-a');
      expect(invocations, ['created']);
    });

    test('attached', () {
      document.body.append(a);
      customElementsTakeRecords();
      expect(invocations, ['attached']);
    });

    test('detached', () {
      a.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached']);
    });

    var div = new DivElement();
    test('nesting does not trigger attached', () {
      div.append(a);
      customElementsTakeRecords();
      expect(invocations, []);
    });

    test('nested entering triggers attached', () {
      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['attached']);
    });

    test('nested leaving triggers detached', () {
      div.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached']);
    });
  });

  // TODO(jmesserly): remove after deprecation period.
  group('standard_events_old_callback_names', () {
    var a;
    setUp(() {
      invocations = [];
    });

    test('Created', () {
      a = new Element.tag('x-a-old');
      expect(invocations, ['created']);
    });

    test('enteredView', () {
      document.body.append(a);
      customElementsTakeRecords();
      expect(invocations, ['enteredView']);
    });

    test('leftView', () {
      a.remove();
      customElementsTakeRecords();
      expect(invocations, ['leftView']);
    });

    var div = new DivElement();
    test('nesting does not trigger enteredView', () {
      div.append(a);
      customElementsTakeRecords();
      expect(invocations, []);
    });

    test('nested entering triggers enteredView', () {
      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['enteredView']);
    });

    test('nested leaving triggers leftView', () {
      div.remove();
      customElementsTakeRecords();
      expect(invocations, ['leftView']);
    });
  });

  group('viewless_document', () {
    var a;
    setUp(() {
      invocations = [];
    });

    test('Created, owned by a document without a view', () {
      a = docB.createElement('x-a');
      expect(a.ownerDocument, docB,
          reason: 'new instance should be owned by the document the definition '
              'was registered with');
      expect(invocations, ['created'],
          reason: 'calling the constructor should invoke the created callback');
    });

    test('Entered document without a view', () {
      docB.body.append(a);
      expect(invocations, [],
          reason: 'attached callback should not be invoked when entering a '
              'document without a view');
    });

    test('Attribute changed in document without a view', () {
      a.setAttribute('data-foo', 'bar');
      expect(invocations, ['attribute changed'],
          reason: 'changing an attribute should invoke the callback, even in a '
              'document without a view');
    });

    test('Entered document with a view', () {
      document.body.append(a);
      customElementsTakeRecords();
      expect(invocations, ['attached'],
          reason:
              'attached callback should be invoked when entering a document '
              'with a view');
    });

    test('Left document with a view', () {
      a.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached'],
          reason: 'detached callback should be invoked when leaving a document '
              'with a view');
    });

    test('Created in a document without a view', () {
      docB.body.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(docB.body);

      expect(invocations, ['created'],
          reason: 'only created callback should be invoked when parsing a '
              'custom element in a document without a view');
    });
  });

  group('shadow_dom', () {
    var div;
    var s;
    setUp(() {
      invocations = [];
      div = new DivElement();
      s = div.createShadowRoot();
    });

    tearDown(() {
      customElementsTakeRecords();
    });

    test('Created in Shadow DOM that is not in a document', () {
      s.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(s);

      expect(invocations, ['created'],
          reason: 'the attached callback should not be invoked when entering a '
              'Shadow DOM subtree not in the document');
    });

    test('Leaves Shadow DOM that is not in a document', () {
      s.innerHtml = '';
      expect(invocations, [],
          reason: 'the detached callback should not be invoked when leaving a '
              'Shadow DOM subtree not in the document');
    });

    test('Enters a document with a view as a constituent of Shadow DOM', () {
      s.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(s);

      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['created', 'attached'],
          reason: 'the attached callback should be invoked when inserted into '
              'a document with a view as part of Shadow DOM');

      div.remove();
      customElementsTakeRecords();

      expect(invocations, ['created', 'attached', 'detached'],
          reason: 'the detached callback should be invoked when removed from a '
              'document with a view as part of Shadow DOM');
    });
  });

  group('disconnected_subtree', () {
    var div = new DivElement();

    setUp(() {
      invocations = [];
    });

    test('Enters a disconnected subtree of DOM', () {
      div.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(div);

      expect(invocations, ['created'],
          reason: 'the attached callback should not be invoked when inserted '
              'into a disconnected subtree');
    });

    test('Leaves a disconnected subtree of DOM', () {
      div.innerHtml = '';
      expect(invocations, [],
          reason:
              'the detached callback should not be invoked when removed from a '
              'disconnected subtree');
    });

    test('Enters a document with a view as a constituent of a subtree', () {
      div.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(div);
      invocations = [];
      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['attached'],
          reason:
              'the attached callback should be invoked when inserted into a '
              'document with a view as part of a subtree');
    });
  });
}
