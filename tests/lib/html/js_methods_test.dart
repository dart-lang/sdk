// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:indexed_db' show IdbFactory, KeyRange;
import 'dart:typed_data' show Int32List;
import 'dart:js';

import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

import 'js_test_util.dart';

main() {
  injectJs();

  test('hashCode and ==', () {
    final o1 = context['Object'];
    final o2 = context['Object'];
    expect(o1 == o2, isTrue);
    expect(o1.hashCode == o2.hashCode, isTrue);
    final d = context['document'];
    expect(o1 == d, isFalse);
  });

  test('toString', () {
    var foo = new JsObject(context['Foo'], [42]);
    expect(foo.toString(), equals("I'm a Foo a=42"));
    var container = context['container'];
    expect(container.toString(), equals("[object Object]"));
  });

  test('toString returns a String even if the JS object does not', () {
    var foo = new JsObject(context['Liar']);
    expect(foo.callMethod('toString'), 1);
    expect(foo.toString(), '1');
  });

  test('instanceof', () {
    var foo = new JsObject(context['Foo'], [1]);
    expect(foo.instanceof(context['Foo']), isTrue);
    expect(foo.instanceof(context['Object']), isTrue);
    expect(foo.instanceof(context['String']), isFalse);
  });

  test('deleteProperty', () {
    var object = new JsObject.jsify({});
    object['a'] = 1;
    expect(context['Object'].callMethod('keys', [object])['length'], 1);
    expect(context['Object'].callMethod('keys', [object])[0], "a");
    object.deleteProperty("a");
    expect(context['Object'].callMethod('keys', [object])['length'], 0);
  });

/* TODO(jacobr): this is another test that is inconsistent with JS semantics.
  test('deleteProperty throws if name is not a String or num', () {
    var object = new JsObject.jsify({});
    expect(() => object.deleteProperty(true),
        throwsArgumentError);
  });
*/

  test('hasProperty', () {
    var object = new JsObject.jsify({});
    object['a'] = 1;
    expect(object.hasProperty('a'), isTrue);
    expect(object.hasProperty('b'), isFalse);
  });

/* TODO(jacobr): is this really the correct unchecked mode behavior?
  test('hasProperty throws if name is not a String or num', () {
    var object = new JsObject.jsify({});
    expect(() => object.hasProperty(true),
        throwsArgumentError);
  });
*/

  test('[] and []=', () {
    final myArray = context['myArray'];
    expect(myArray['length'], equals(1));
    expect(myArray[0], equals("value1"));
    myArray[0] = "value2";
    expect(myArray['length'], equals(1));
    expect(myArray[0], equals("value2"));

    final foo = new JsObject(context['Foo'], [1]);
    foo["getAge"] = () => 10;
    expect(foo.callMethod('getAge'), equals(10));
  });

/* TODO(jacobr): remove as we should only throw this in checked mode.
  test('[] and []= throw if name is not a String or num', () {
    var object = new JsObject.jsify({});
    expect(() => object[true],
        throwsArgumentError);
    expect(() => object[true] = 1,
        throwsArgumentError);
  });
*/
}
