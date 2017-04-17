// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library attribute_changed_callback_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';
import '../utils.dart';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);
  A.created() : super.created();

  static var attributeChangedInvocations = 0;

  void attributeChanged(name, oldValue, newValue) {
    attributeChangedInvocations++;
  }
}

class B extends HtmlElement {
  static final tag = 'x-b';
  factory B() => new Element.tag(tag);
  B.created() : super.created() {
    invocations.add('created');
  }

  static var invocations = [];

  Completer completer;

  void attributeChanged(name, oldValue, newValue) {
    invocations.add('$name: $oldValue => $newValue');
    if (completer != null) {
      completer.complete('value changed to $newValue');
      completer = null;
    }
  }
}

// Pump custom events polyfill events.
void customElementsTakeRecords() {
  if (js.context.hasProperty('CustomElements')) {
    js.context['CustomElements'].callMethod('takeRecords');
  }
}

main() {
  useHtmlIndividualConfiguration();

  // Adapted from Blink's fast/dom/custom/attribute-changed-callback test.

  var registered = false;
  setUp(() => customElementsReady.then((_) {
        if (!registered) {
          registered = true;
          document.registerElement(A.tag, A);
          document.registerElement(B.tag, B);
        }
      }));

  group('fully_supported', () {
    test('transfer attribute changed callback', () {
      var element = new A();

      element.attributes['a'] = 'b';
      expect(A.attributeChangedInvocations, 1);
    });

    test('add, change and remove an attribute', () {
      var b = new B();

      B.invocations = [];
      b.attributes['data-s'] = 't';
      expect(B.invocations, ['data-s: null => t']);

      b.attributes['data-v'] = 'w';
      B.invocations = [];
      b.attributes['data-v'] = 'x';
      expect(B.invocations, ['data-v: w => x']);

      B.invocations = [];
      b.attributes['data-v'] = 'x';
      expect(B.invocations, []);

      b.attributes.remove('data-v');
      expect(B.invocations, ['data-v: x => null']);
    });

    test('add, change ID', () {
      B.invocations = [];

      var b = new B();
      var completer = new Completer();
      b.completer = completer;
      b.id = 'x';
      return completer.future
          .then((_) => expect(B.invocations, ['created', 'id: null => x']))
          .then((_) {
        B.invocations = [];
        var secondCompleter = new Completer();
        b.completer = secondCompleter;
        b.attributes.remove('id');
        return secondCompleter.future;
      }).then((_) => expect(B.invocations, ['id: x => null']));
    });
  });

  group('unsupported_on_polyfill', () {
    // If these tests start passing, don't remove the status suppression. Move
    // the tests to the fullYy_supported group.

    test('add, change classes', () {
      var b = new B();

      B.invocations = [];
      b.classes.toggle('u');
      expect(B.invocations, ['class: null => u']);
    });
  });
}
