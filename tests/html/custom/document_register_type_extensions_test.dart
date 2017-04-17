// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library document_register_type_extensions_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import '../utils.dart';

class Foo extends HtmlElement {
  static const tag = 'x-foo';
  static final List outerHtmlStrings = [
    '<x-foo></x-foo>',
    '<?XML:NAMESPACE PREFIX = PUBLIC NS = "URN:COMPONENT" /><x-foo></x-foo>'
  ];
  factory Foo() => new Element.tag(tag);
  Foo.created() : super.created();
}

class Bar extends InputElement {
  static const tag = 'x-bar';
  static const outerHtmlString = '<input is="x-bar">';
  factory Bar() => new Element.tag('input', tag);
  Bar.created() : super.created();
}

class Baz extends Foo {
  static const tag = 'x-baz';
  static final List outerHtmlStrings = [
    '<x-baz></x-baz>',
    '<?XML:NAMESPACE PREFIX = PUBLIC NS = "URN:COMPONENT" /><x-baz></x-baz>'
  ];
  factory Baz() => new Element.tag(tag);
  Baz.created() : super.created();
}

class Qux extends Bar {
  static const tag = 'x-qux';
  factory Qux() => new Element.tag('input', tag);
  Qux.created() : super.created();
}

class FooBad extends DivElement {
  static const tag = 'x-foo';
  factory FooBad() => new Element.tag('div', tag);
  FooBad.created() : super.created();
}

class MyCanvas extends CanvasElement {
  static const tag = 'my-canvas';
  factory MyCanvas() => new Element.tag('canvas', tag);

  MyCanvas.created() : super.created();

  void fillAsRed() {
    width = 100;
    height = 100;

    var context = this.getContext('2d');
    context.fillStyle = 'red';
    context.fillRect(0, 0, width, height);
    context.fill();

    var data = context.getImageData(0, 0, 1, 1).data;
    expect(data, [255, 0, 0, 255]);
  }
}

class CustomDiv extends DivElement {
  CustomDiv.created() : super.created();
}

class CustomCustomDiv extends CustomDiv {
  static const tag = 'custom-custom';
  CustomCustomDiv.created() : super.created();
}

main() {
  useHtmlIndividualConfiguration();

  // Adapted from Blink's fast/dom/custom/document-register-type-extension test.

  var testForm = new FormElement()..id = 'testForm';
  document.body.append(testForm);

  var isFormControl = (element) {
    testForm.append(element);
    return element.form == testForm;
  };

  var registeredTypes = false;
  void registerTypes() {
    if (registeredTypes) {
      return;
    }
    registeredTypes = true;
    document.registerElement(Foo.tag, Foo);
    document.registerElement(Bar.tag, Bar, extendsTag: 'input');
    document.registerElement(Baz.tag, Baz);
    document.registerElement(Qux.tag, Qux, extendsTag: 'input');
    document.registerElement(MyCanvas.tag, MyCanvas, extendsTag: 'canvas');
    document.registerElement(CustomCustomDiv.tag, CustomCustomDiv,
        extendsTag: 'div');
  }

  setUp(() => customElementsReady);

  group('registration', () {
    setUp(registerTypes);

    test('cannot register twice', () {
      expect(() => document.registerElement(FooBad.tag, Foo, extendsTag: 'div'),
          throws);
    });

    test('cannot register for non-matching tag', () {
      expect(() {
        document.registerElement('x-input-div', Bar, extendsTag: 'div');
      }, throws);
    });

    test('cannot register type extension for custom tag', () {
      expect(() {
        document.registerElement('x-custom-tag', CustomCustomDiv);
      }, throws);
    });
  });

  group('construction', () {
    setUp(registerTypes);

    group('constructors', () {
      test('custom tag', () {
        var fooNewed = new Foo();
        expect(fooNewed.outerHtml, anyOf(Foo.outerHtmlStrings));
        expect(fooNewed is Foo, isTrue);
        expect(fooNewed is HtmlElement, isTrue);
        expect(fooNewed is UnknownElement, isFalse);
      });

      test('type extension', () {
        var barNewed = new Bar();
        expect(barNewed.outerHtml, Bar.outerHtmlString);
        expect(barNewed is Bar, isTrue);
        expect(barNewed is InputElement, isTrue);
        expect(isFormControl(barNewed), isTrue);
      });

      test('custom tag deriving from custom tag', () {
        var bazNewed = new Baz();
        expect(bazNewed.outerHtml, anyOf(Baz.outerHtmlStrings));
        expect(bazNewed is Baz, isTrue);
        expect(bazNewed is HtmlElement, isTrue);
        expect(bazNewed is UnknownElement, isFalse);
      });

      test('type extension deriving from custom tag', () {
        var quxNewed = new Qux();
        var quxOuterHtml = '<input is="x-qux">';
        expect(quxNewed.outerHtml, quxOuterHtml);
        expect(quxNewed is Qux, isTrue);
        expect(quxNewed is InputElement, isTrue);
        expect(isFormControl(quxNewed), isTrue);
      });
    });

    group('single-parameter createElement', () {
      test('custom tag', () {
        var fooCreated = new Element.tag('x-foo');
        expect(fooCreated.outerHtml, anyOf(Foo.outerHtmlStrings));
        expect(fooCreated is Foo, isTrue);
      });

      test('does not upgrade type extension', () {
        var barCreated = new Element.tag('x-bar');
        expect(barCreated is Bar, isFalse);
        expect(barCreated.outerHtml, "<x-bar></x-bar>");
        expect(barCreated is UnknownElement, isFalse);
        expect(barCreated is HtmlElement, isTrue);
      });

      test('custom tag deriving from custom tag', () {
        var bazCreated = new Element.tag('x-baz');
        expect(bazCreated.outerHtml, anyOf(Baz.outerHtmlStrings));
        expect(bazCreated is Baz, isTrue);
        expect(bazCreated is UnknownElement, isFalse);
      });

      test('type extension deriving from custom tag', () {
        var quxCreated = new Element.tag('x-qux');
        expect(quxCreated.outerHtml, "<x-qux></x-qux>");
        expect(quxCreated is Qux, isFalse);
        expect(quxCreated is UnknownElement, isFalse);
        expect(quxCreated is HtmlElement, isTrue);
      });
    });

    group('createElement with type extension', () {
      test('does not upgrade extension of custom tag', () {
        var divFooCreated = new Element.tag("div", Foo.tag);
        expect(divFooCreated.outerHtml, '<div is="x-foo"></div>');
        expect(divFooCreated is Foo, isFalse);
        expect(divFooCreated is DivElement, isTrue);
      });

      test('upgrades valid extension', () {
        var inputBarCreated = new Element.tag("input", Bar.tag);
        expect(inputBarCreated.outerHtml, Bar.outerHtmlString);
        expect(inputBarCreated is Bar, isTrue);
        expect(inputBarCreated is UnknownElement, isFalse);
        expect(isFormControl(inputBarCreated), isTrue);
      });

      test('type extension of incorrect tag', () {
        var divBarCreated = new Element.tag("div", Bar.tag);
        expect(divBarCreated.outerHtml, '<div is="x-bar"></div>');
        expect(divBarCreated is Bar, isFalse);
        expect(divBarCreated is DivElement, isTrue);
      });

      test('incorrect extension of custom tag', () {
        var fooBarCreated = new Element.tag(Foo.tag, Bar.tag);
        expect(
            fooBarCreated.outerHtml,
            anyOf(
                '<x-foo is="x-bar"></x-foo>',
                '<?XML:NAMESPACE PREFIX = PUBLIC NS = "URN:COMPONENT" />'
                '<x-foo is="x-bar"></x-foo>'));
        expect(fooBarCreated is Foo, isTrue);
      });

      test('incorrect extension of type extension', () {
        var barFooCreated = new Element.tag(Bar.tag, Foo.tag);
        expect(barFooCreated.outerHtml, '<x-bar is="x-foo"></x-bar>');
        expect(barFooCreated is UnknownElement, isFalse);
        expect(barFooCreated is HtmlElement, isTrue);
      });

      test('null type extension', () {
        var fooCreatedNull = new Element.tag(Foo.tag, null);
        expect(fooCreatedNull.outerHtml, anyOf(Foo.outerHtmlStrings));
        expect(fooCreatedNull is Foo, isTrue);
      });

      test('empty type extension', () {
        var fooCreatedEmpty = new Element.tag(Foo.tag, "");
        expect(fooCreatedEmpty.outerHtml, anyOf(Foo.outerHtmlStrings));
        expect(fooCreatedEmpty is Foo, isTrue);
      });
    });
  });

  group('namespaces', () {
    setUp(registerTypes);

    test('createElementNS', () {
      var fooCreatedNS = document.createElementNS(
          "http://www.w3.org/1999/xhtml", Foo.tag, null);
      expect(fooCreatedNS.outerHtml, anyOf(Foo.outerHtmlStrings));
      expect(fooCreatedNS is Foo, isTrue);

      var barCreatedNS = document.createElementNS(
          "http://www.w3.org/1999/xhtml", "input", Bar.tag);
      expect(barCreatedNS.outerHtml, Bar.outerHtmlString);
      expect(barCreatedNS is Bar, isTrue);
      expect(isFormControl(barCreatedNS), isTrue);

      expect(
          () => document.createElementNS(
              'http://example.com/2013/no-such-namespace', 'xml:lang', 'x-bar'),
          throws);
    });
  });

  group('parsing', () {
    setUp(registerTypes);

    test('parsing', () {
      createElementFromHtml(html) {
        var container = new DivElement()
          ..setInnerHtml(html, treeSanitizer: new NullTreeSanitizer());
        upgradeCustomElements(container);
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
      // Polyfill does not convert parsed unregistered custom elements to
      // HtmlElement.
      // expect(namedBarParsed is UnknownElement, isFalse);
      expect(namedBarParsed is HtmlElement, isTrue);

      var divBarParsed = createElementFromHtml('<div is=x-bar>');
      expect(divBarParsed is Bar, isFalse);
      expect(divBarParsed is DivElement, isTrue);
    });
  });

  group('functional', () {
    setUp(registerTypes);

    test('canvas', () {
      var canvas = new MyCanvas();
      canvas.fillAsRed();
    });
  });
}
