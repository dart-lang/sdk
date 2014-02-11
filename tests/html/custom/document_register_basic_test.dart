// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library document_register_basic_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import '../utils.dart';

class Foo extends HtmlElement {
  static final tag = 'x-foo';
  factory Foo() => new Element.tag(tag);
  Foo.created() : super.created();

  get thisIsACustomClass => true;
}

class Bar extends HtmlElement {
  static final tag = 'x-bar';
  factory Bar() => new Element.tag(tag);
  Bar.created() : super.created();

  get thisIsACustomClass => true;
}

class Baz extends Foo {
  static final tag = 'x-baz';
  factory Baz() => new Element.tag(tag);
  Baz.created() : super.created();

  get thisIsAlsoACustomClass => true;
}

class BadB {
}

class BadE implements HtmlElement {
  static final tag = 'x-tag-e';
  factory BadE() => new Element.tag(tag);
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's fast/dom/custom/document-register-basic test.

  setUp(() => customElementsReady);

  test('Testing document.register() basic behaviors', () {
    document.register(Foo.tag, Foo);

    // Cannot register an existing dart:html type.
    expect(() => document.register('x-bad-a', HtmlElement), throws);

    // Invalid user type.  Doesn't inherit from HtmlElement.
    expect(() => document.register('x-bad-b', BadB), throws);

    // Not a type.
    expect(() => document.register('x-bad-c', null), throws);

    // Cannot register system type.
    expect(() => document.register('x-bad-d', Object), throws);

    // Must extend HtmlElement, not just implement it.
    expect(() => document.register(BadE.tag, BadE), throws);

    // Constructor initiated instantiation
    var createdFoo = new Foo();
    expect(createdFoo.thisIsACustomClass, isTrue);

    // Dart type correctness
    expect(createdFoo is HtmlElement, isTrue);
    expect(createdFoo is Foo, isTrue);
    expect(createdFoo.runtimeType, Foo);

    // Native getter
    expect(createdFoo.tagName, "X-FOO");

    // Native setter
    createdFoo.innerHtml = "Hello";
    expect(createdFoo.text, "Hello");

    // Native method
    var childDiv = new DivElement();
    createdFoo.append(childDiv);
    expect(createdFoo.lastChild, childDiv);

    // Parser initiated instantiation
    var container = new DivElement()..id = "container";
    document.body.append(container);
    container.setInnerHtml("<x-foo></x-foo>",
        treeSanitizer: new NullTreeSanitizer());
    upgradeCustomElements(container);
    var parsedFoo = container.firstChild;

    expect(parsedFoo is Foo, isTrue);
    expect(parsedFoo.tagName, "X-FOO");

    // Ensuring the wrapper is retained
    var someProperty = new Expando();
    someProperty[parsedFoo] = "hello";
    expect(container.firstChild, parsedFoo);
    expect(someProperty[container.firstChild], someProperty[parsedFoo]);

    // Having another constructor
    document.register(Bar.tag, Bar);
    var createdBar = new Bar();
    expect(createdBar is Bar, isTrue);
    expect(createdBar is Foo, isFalse);
    expect(createdBar.tagName, "X-BAR");

    // Having a subclass
    document.register(Baz.tag, Baz);
    var createdBaz = new Baz();
    expect(createdBaz.tagName, "X-BAZ");
    expect(createdBaz.thisIsACustomClass, isTrue);
    expect(createdBaz.thisIsAlsoACustomClass, isTrue);

    // With irregular cases
    var createdUpperBar = new Element.tag("X-BAR");
    var createdMixedBar = new Element.tag("X-Bar");
    expect(createdUpperBar is Bar, isTrue);
    expect(createdUpperBar.tagName, "X-BAR");
    expect(createdMixedBar is Bar, isTrue);
    expect(createdMixedBar.tagName, "X-BAR");

    container.setInnerHtml("<X-BAR></X-BAR><X-Bar></X-Bar>",
        treeSanitizer: new NullTreeSanitizer());
    upgradeCustomElements(container);
    expect(container.firstChild is Bar, isTrue);
    expect(container.firstChild.tagName, "X-BAR");
    expect(container.lastChild is Bar, isTrue);
    expect(container.lastChild.tagName, "X-BAR");

    // Constructors shouldn't interfere with each other
    expect((new Foo()).tagName, "X-FOO");
    expect((new Bar()).tagName, "X-BAR");
    expect((new Baz()).tagName, "X-BAZ");
  });
}
