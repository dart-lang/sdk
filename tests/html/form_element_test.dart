// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library FormElementTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

void main() {
  useHtmlConfiguration();

  var isFormElement = predicate((x) => x is FormElement, 'is a FormElement');

  test('constructorTest1', () {
    var form = new FormElement();
    expect(form, isNotNull);
    expect(form, isFormElement);
  });

  test('checkValidityTest', () {
    var form = new FormElement();
    form.innerHtml = '<label>Google: <input type="search" name="q"></label> '
        '<input type="submit" value="Search...">';
    expect(form.checkValidity(), isTrue);
    // TODO(efortuna): Issue 4832.
    form.innerHtml = '<input type="email" value="notemail" blaber="test"'
        ' required>';
    expect(form.checkValidity(), isFalse);
  });

  var form = new FormElement();
  test('acceptCharsetTest', () {
    var charset = 'abc';
    form.acceptCharset = charset;
    expect(form.acceptCharset, charset);
  });

  test('actionTest', () {
    var action = 'http://dartlang.org/';
    form.action = action;
    expect(form.action, action);
  });

  test('autocompleteTest', () {
    var auto = 'on';
    form.autocomplete = auto;
    expect(form.autocomplete, auto);
  });

  test('encodingAndEnctypeTest', () {
    expect(form.enctype, form.encoding);
  });

  test('lengthTest', () {
    expect(form.length, 0);
    form.innerHtml = '<label>Google: <input type="search" name="q"></label> '
        '<input type="submit" value="Search...">';
    expect(form.length, 2);
  });

  test('methodTest', () {
    var method = 'post';
    form.method = method;
    expect(form.method, method);
  });

  test('nameTest', () {
    var name = 'aname';
    form.name = name;
    expect(form.name, name);
  });

  test('noValidateTest', () {
    form.noValidate = true;
    expect(form.noValidate, true);
  });

  test('targetTest', () {
    var target = 'target';
    form.target = target;
    expect(form.target, target);
  });
}
