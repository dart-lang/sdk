// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library document_register_basic_test;

import 'dart:html';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

class Foo extends HtmlElement {
  static final tag = 'x-foo';
  factory Foo() => new Element.tag(tag) as Foo;
  Foo.created() : super.created();

  get thisIsACustomClass => true;
}

class Bar extends HtmlElement {
  static final tag = 'x-bar';
  factory Bar() => new Element.tag(tag) as Bar;
  Bar.created() : super.created();

  get thisIsACustomClass => true;
}

class Baz extends Foo {
  static final tag = 'x-baz';
  factory Baz() => new Element.tag(tag) as Baz;
  Baz.created() : super.created();

  get thisIsAlsoACustomClass => true;
}

class BadB {}

abstract class BadC extends HtmlElement {
  BadC.created() : super.created();
}

main() async {
  // Adapted from Blink's fast/dom/custom/document-register-basic test.

  await customElementsReady;

  test('Testing document.registerElement2() basic behaviors', () {
    document.registerElement2(Foo.tag, {'prototype': Foo});

    // Cannot register an existing dart:html type.
    expect(
        () => document.registerElement2('x-bad-a', {'prototype': HtmlElement}),
        throws);

    // Invalid user type.  Doesn't inherit from HtmlElement.
    expect(() => document.registerElement2('x-bad-b', {'prototype': BadB}),
        throws);

    // Cannot register abstract class.
    expect(() => document.registerElement2('x-bad-c', {'prototype': BadC}),
        throws);

    // Not a type.
    expect(() => document.registerElement2('x-bad-d', {'prototype': null}),
        throws);

    // Cannot register system type.
    expect(() => document.registerElement2('x-bad-e', {'prototype': Object}),
        throws);

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
    document.body!.append(container);
    container.setInnerHtml("<x-foo></x-foo>",
        treeSanitizer: new NullTreeSanitizer());
    upgradeCustomElements(container);
    var parsedFoo = container.firstChild;

    expect(parsedFoo is Foo, isTrue);
    expect((parsedFoo as Foo).tagName, "X-FOO");

    // Ensuring the wrapper is retained
    var someProperty = new Expando();
    someProperty[parsedFoo] = "hello";
    expect(container.firstChild, parsedFoo);
    expect(someProperty[container.firstChild!], someProperty[parsedFoo]);

    // Having another constructor
    document.registerElement2(Bar.tag, {'prototype': Bar});
    var createdBar = new Bar();
    expect(createdBar is Bar, isTrue);
    expect(createdBar is Foo, isFalse);
    expect(createdBar.tagName, "X-BAR");

    // Having a subclass
    document.registerElement2(Baz.tag, {'prototype': Baz});
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
    expect((container.firstChild as Bar).tagName, "X-BAR");
    expect(container.lastChild is Bar, isTrue);
    expect((container.lastChild as Bar).tagName, "X-BAR");

    // Constructors shouldn't interfere with each other
    expect((new Foo()).tagName, "X-FOO");
    expect((new Bar()).tagName, "X-BAR");
    expect((new Baz()).tagName, "X-BAZ");
  });
}
