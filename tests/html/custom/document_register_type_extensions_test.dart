// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library document_register_type_extensions_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

class Foo extends HtmlElement {
  static final tag = 'x-foo';
  factory Foo() => new Element.tag(tag);
}

class Bar extends InputElement {
  static final tag = 'x-bar';
  factory Bar() => document.$dom_createElement('input', tag);
}

class Baz extends Foo {
  static final tag = 'x-baz';
  factory Baz() => new Element.tag(tag);
}

class Qux extends Bar {
  static final tag = 'x-qux';
  factory Qux() => document.$dom_createElement('input', tag);
}

class FooBad extends DivElement {
  static final tag = 'x-foo';
  factory FooBad() => document.$dom_createElement('div', tag);
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's fast/dom/custom/document-register-type-extension test.

  var testForm = new FormElement()..id = 'testForm';
  document.body.append(testForm);

  var isFormControl = (element) {
    testForm.append(element);
    return element.form == testForm;
  };

  test('construction', () {
    document.register(Foo.tag, Foo);
    document.register(Bar.tag, Bar);
    document.register(Baz.tag, Baz);
    document.register(Qux.tag, Qux);

    expect(() => document.register(FooBad.tag, Foo), throws);

    // Constructors

    var fooNewed = new Foo();
    var fooOuterHtml = "<x-foo></x-foo>";
    expect(fooNewed.outerHtml, fooOuterHtml);
    expect(fooNewed is Foo, isTrue);
    expect(fooNewed is HtmlElement, isTrue);
    expect(fooNewed is UnknownElement, isFalse);

    var barNewed = new Bar();
    var barOuterHtml = '<input is="x-bar">';
    expect(barNewed.outerHtml, barOuterHtml);
    expect(barNewed is Bar, isTrue);
    expect(barNewed is InputElement, isTrue);
    expect(isFormControl(barNewed), isTrue);

    var bazNewed = new Baz();
    var bazOuterHtml = "<x-baz></x-baz>";
    expect(bazNewed.outerHtml, bazOuterHtml);
    expect(bazNewed is Baz, isTrue);
    expect(bazNewed is HtmlElement, isTrue);
    expect(bazNewed is UnknownElement, isFalse);

    var quxNewed = new Qux();
    var quxOuterHtml = '<input is="x-qux">';
    expect(quxNewed.outerHtml, quxOuterHtml);
    expect(quxNewed is Qux, isTrue);
    expect(quxNewed is InputElement, isTrue);
    expect(isFormControl(quxNewed), isTrue);

    // new Element.tag

    var fooCreated = new Element.tag('x-foo');
    expect(fooCreated.outerHtml, fooOuterHtml);
    expect(fooCreated is Foo, isTrue);

    var barCreated = new Element.tag('x-bar');
    expect(barCreated.outerHtml, "<x-bar></x-bar>");
    expect(barCreated is Bar, isFalse);
    expect(barCreated is UnknownElement, isFalse);
    expect(barCreated is HtmlElement, isTrue);

    var bazCreated = new Element.tag('x-baz');
    expect(bazCreated.outerHtml, bazOuterHtml);
    expect(bazCreated is Baz, isTrue);
    expect(bazCreated is UnknownElement, isFalse);

    var quxCreated = new Element.tag('x-qux');
    expect(quxCreated.outerHtml, "<x-qux></x-qux>");
    expect(quxCreated is Qux, isFalse);
    expect(quxCreated is UnknownElement, isFalse);
    expect(quxCreated is HtmlElement, isTrue);

    // create with type extensions
    // TODO(vsm): How should we expose this?

    var divFooCreated = document.$dom_createElement("div", Foo.tag);
    expect(divFooCreated.outerHtml, '<div is="x-foo"></div>');
    expect(divFooCreated is Foo, isFalse);
    expect(divFooCreated is DivElement, isTrue);

    var inputBarCreated =
	document.$dom_createElement("input", Bar.tag);
    expect(inputBarCreated.outerHtml, barOuterHtml);
    expect(inputBarCreated is Bar, isTrue);
    expect(inputBarCreated is UnknownElement, isFalse);
    expect(isFormControl(inputBarCreated), isTrue);

    var divBarCreated = document.$dom_createElement("div", Bar.tag);
    expect(divBarCreated.outerHtml, '<div is="x-bar"></div>');
    expect(divBarCreated is Bar, isFalse);
    expect(divBarCreated is DivElement, isTrue);

    var fooBarCreated =
	document.$dom_createElement(Foo.tag, Bar.tag);
    expect(fooBarCreated.outerHtml, '<x-foo is="x-bar"></x-foo>');
    expect(fooBarCreated is Foo, isTrue);

    var barFooCreated = document.$dom_createElement(Bar.tag,
						      Foo.tag);
    expect(barFooCreated.outerHtml, '<x-bar is="x-foo"></x-bar>');
    expect(barFooCreated is UnknownElement, isFalse);
    expect(barFooCreated is HtmlElement, isTrue);

    var fooCreatedNull = document.$dom_createElement(Foo.tag, null);
    expect(fooCreatedNull.outerHtml, fooOuterHtml);
    expect(fooCreatedNull is Foo, isTrue);

    var fooCreatedEmpty = document.$dom_createElement(Foo.tag, "");
    expect(fooCreatedEmpty.outerHtml, fooOuterHtml);
    expect(fooCreatedEmpty is Foo, isTrue);

    expect(() => document.$dom_createElement('@invalid', 'x-bar'), throws);

    // Create NS with type extensions

    var fooCreatedNS =
	document.$dom_createElementNS("http://www.w3.org/1999/xhtml",
				      Foo.tag, null);
    expect(fooCreatedNS.outerHtml, fooOuterHtml);
    expect(fooCreatedNS is Foo, isTrue);

    var barCreatedNS =
	document.$dom_createElementNS("http://www.w3.org/1999/xhtml", "input",
				      Bar.tag);
    expect(barCreatedNS.outerHtml, barOuterHtml);
    expect(barCreatedNS is Bar, isTrue);
    expect(isFormControl(barCreatedNS), isTrue);

    expect(() =>
	     document.$dom_createElementNS(
	         'http://example.com/2013/no-such-namespace',
		 'xml:lang', 'x-bar'), throws);

    // Parser

    createElementFromHtml(html) {
	var container = new DivElement()..innerHtml = html;
	return container.firstChild;
    }

    var fooParsed = createElementFromHtml('<x-foo>');
    expect(fooParsed is Foo, isTrue);

    var barParsed = createElementFromHtml('<input is=x-bar>');
    expect(barParsed is Bar, isTrue);
    expect(isFormControl(barParsed), isTrue);

    var divFooParsed = createElementFromHtml('<div is=x-foo>');
    expect(divFooParsed is Foo, isFalse);
    expect(divFooParsed is DivElement, isTrue);

    var namedBarParsed = createElementFromHtml('<x-bar>');
    expect(namedBarParsed is Bar, isFalse);
    expect(namedBarParsed is UnknownElement, isFalse);
    expect(namedBarParsed is HtmlElement, isTrue);

    var divBarParsed = createElementFromHtml('<div is=x-bar>');
    expect(divBarParsed is Bar, isFalse);
    expect(divBarParsed is DivElement, isTrue);
  });
}
