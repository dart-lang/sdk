// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library UnknownElementTest;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isUnknownElement =
      predicate((x) => x is UnknownElement, 'is an UnknownELement');

  var foo = new Element.tag('foo');
  foo.id = 'foo';
  var bar = new Element.tag('bar');
  bar.id = 'bar';
  document.body.nodes.addAll([foo, bar]);

  test('type-check', () {
      expect(foo, isUnknownElement);
      expect(bar, isUnknownElement);
      expect(query('#foo'), equals(foo));
      expect(query('#bar'), equals(bar));
    });

  test('dispatch-fail', () {
      expect(() => foo.method1(), throwsNoSuchMethodError);
      expect(() => foo.field1, throwsNoSuchMethodError);
      expect(() { foo.field1 = 42; }, throwsNoSuchMethodError);
    });
}
