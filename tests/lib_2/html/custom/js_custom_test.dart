// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:mirrors';

import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);
  A.created() : super.created() {
    ncallbacks++;
  }

  static int ncallbacks = 0;
}

main() {
  useHtmlIndividualConfiguration();

  // Adapted from Blink's
  // fast/dom/custom/constructor-calls-created-synchronously test.

  var registered = false;
  setUp(() {
    return customElementsReady.then((_) {
      if (!registered) {
        registered = true;
        document.registerElement2(A.tag, {'prototype': A});
      }
    });
  });

  test('accessing custom Dart element from JS', () {
    var a = new A();
    a.id = 'a';
    document.body.append(a);

    var script = '''
      document.querySelector('#a').setAttribute('fromJS', 'true');
    ''';
    document.body.append(new ScriptElement()..text = script);

    expect(a.attributes['fromJS'], 'true');
  });

  test('accessing custom JS element from Dart', () {
    var script = '''
    var Foo = document.registerElement2('x-foo', {
      prototype: Object.create(HTMLElement.prototype, {
        createdCallback: {
          value: function() {
            this.setAttribute('fromJS', 'true');
          }
        }
      })});
    var foo = new Foo();
    foo.id = 'b';
    document.body.appendChild(foo);
    ''';

    document.body.append(new ScriptElement()..text = script);
    var custom = document.querySelector('#b');
    expect(custom is HtmlElement, isTrue);
    expect(custom.attributes['fromJS'], 'true');
  });
}
