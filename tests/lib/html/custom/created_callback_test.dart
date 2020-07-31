// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library created_callback_test;

import 'dart:html';
import 'dart:js' as js;

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag) as A;
  A.created() : super.created() {
    createdInvocations++;
  }

  static int createdInvocations = 0;
}

class B extends HtmlElement {
  static final tag = 'x-b';
  factory B() => new Element.tag(tag) as B;
  B.created() : super.created();
}

class C extends HtmlElement {
  static final tag = 'x-c';
  factory C() => new Element.tag(tag) as C;
  C.created() : super.created() {
    createdInvocations++;

    if (this.id != 'u') {
      return;
    }

    var t = div.querySelector('#t');
    var v = div.querySelector('#v');
    var w = div.querySelector('#w');

    expect(querySelector('x-b:not(:unresolved)'), this);
    expect(querySelectorAll(':unresolved'), [v, w]);

    // As per:
    // http://www.w3.org/TR/2013/WD-custom-elements-20130514/#serializing-and-parsing
    // creation order is t, u, v, w (postorder).
    expect(t is C, isTrue);
    // Note, this is different from JavaScript where this would be false.
    expect(v is C, isTrue);
  }

  static int createdInvocations = 0;
  static var div;
}

main() async {
  // Adapted from Blink's
  // fast/dom/custom/created-callback test.

  await customElementsReady;
  document.registerElement2(B.tag, {'prototype': B});
  document.registerElement2(C.tag, {'prototype': C});
  ErrorConstructorElement.register();

  test('transfer created callback', () {
    document.registerElement2(A.tag, {'prototype': A as dynamic});
    var x = new A();
    expect(A.createdInvocations, 1);
  });

  test('unresolved and created callback timing', () {
    var div = new DivElement();
    C.div = div;
    div.setInnerHtml("""
<x-c id="t"></x-c>
<x-b id="u"></x-b>
<x-c id="v"></x-c>
<x-b id="w"></x-b>
""", treeSanitizer: NodeTreeSanitizer.trusted);

    upgradeCustomElements(div);

    expect(C.createdInvocations, 2);
    expect(div.querySelector('#w') is B, isTrue);
  });

  test('nesting of constructors', NestedElement.test);

  test('access while upgrading gets unupgraded element',
      AccessWhileUpgradingElement.test);

  test('cannot call created constructor', () {
    expect(() {
      new B.created();
    }, throws);
  });

  test('cannot register without created', () {
    expect(() {
      document.registerElement2(
          MissingCreatedElement.tag, {'prototype': MissingCreatedElement});
    }, throws);
  });

  test('throw on createElement does not upgrade', () {
    ErrorConstructorElement.callCount = 0;

    var e;
    expectGlobalError(() {
      e = new Element.tag(ErrorConstructorElement.tag);
    });
    expect(ErrorConstructorElement.callCount, 1);
    expect(e is HtmlElement, isTrue);
    expect(e is ErrorConstructorElement, isFalse);

    var dummy = new DivElement();
    dummy.append(e);
    e = dummy.firstChild;
    expect(ErrorConstructorElement.callCount, 1);
  });

  test('throw on innerHtml does not upgrade', () {
    ErrorConstructorElement.callCount = 0;

    var dummy = new DivElement();
    var tag = ErrorConstructorElement.tag;
    expectGlobalError(() {
      dummy.setInnerHtml('<$tag></$tag>',
          treeSanitizer: NodeTreeSanitizer.trusted);
    });

    expect(ErrorConstructorElement.callCount, 1);

    var e = dummy.firstChild;
    // Accessing should not re-run the constructor.
    expect(ErrorConstructorElement.callCount, 1);
    expect(e is HtmlElement, isTrue);
    expect(e is ErrorConstructorElement, isFalse);
  });

  test('cannot register created with params', () {
    expect(() {
      document.registerElement2(
          'x-created-with-params', {'prototype': CreatedWithParametersElement});
    }, throws);
  });

  test('created cannot be called from nested constructor',
      NestedCreatedConstructorElement.test);

  // TODO(vsm): Port additional test from upstream here:
  // http://src.chromium.org/viewvc/blink/trunk/LayoutTests/fast/dom/custom/created-callback.html?r1=156141&r2=156185
}

class NestedElement extends HtmlElement {
  static final tag = 'x-nested';

  final Element b = new B();

  factory NestedElement() => new Element.tag(tag) as NestedElement;
  NestedElement.created() : super.created();

  static void register() {
    document.registerElement2(tag, {'prototype': NestedElement});
  }

  static void test() {
    register();

    var e = new NestedElement();
    expect(e.b, isNotNull);
    expect(e.b is B, isTrue);
    expect(e is NestedElement, isTrue);
  }
}

class AccessWhileUpgradingElement extends HtmlElement {
  static final tag = 'x-access-while-upgrading';

  static late Element upgradingContext;
  static late Element upgradingContextChild;

  final foo = runInitializerCode();

  factory AccessWhileUpgradingElement() =>
      new Element.tag(tag) as AccessWhileUpgradingElement;
  AccessWhileUpgradingElement.created() : super.created();

  static runInitializerCode() {
    upgradingContextChild = upgradingContext.firstChild as Element;

    return 666;
  }

  static void register() {
    document.registerElement2(tag, {'prototype': AccessWhileUpgradingElement});
  }

  static void test() {
    register();

    upgradingContext = new DivElement();
    upgradingContext.setInnerHtml('<$tag></$tag>',
        treeSanitizer: new NullTreeSanitizer());
    dynamic child = upgradingContext.firstChild;

    expect(child.foo, 666);
    expect(upgradingContextChild is HtmlElement, isFalse);
    expect(upgradingContextChild is AccessWhileUpgradingElement, isFalse,
        reason: 'Elements accessed while upgrading should not be upgraded.');
  }
}

class MissingCreatedElement extends HtmlElement {
  static final tag = 'x-missing-created';

  factory MissingCreatedElement() =>
      new Element.tag(tag) as MissingCreatedElement;
}

class ErrorConstructorElement extends HtmlElement {
  static final tag = 'x-throws-in-constructor';
  static int callCount = 0;

  factory ErrorConstructorElement() =>
      new Element.tag(tag) as ErrorConstructorElement;

  ErrorConstructorElement.created() : super.created() {
    ++callCount;
    throw new Exception('Just messin with ya');
  }

  static void register() {
    document.registerElement2(tag, {'prototype': ErrorConstructorElement});
  }
}

class NestedCreatedConstructorElement extends HtmlElement {
  static final tag = 'x-nested-created-constructor';

  // Should not be able to call this here.
  final B b = constructB();
  static B? constructedB;

  factory NestedCreatedConstructorElement() =>
      new Element.tag(tag) as NestedCreatedConstructorElement;
  NestedCreatedConstructorElement.created() : super.created();

  static void register() {
    document
        .registerElement2(tag, {'prototype': NestedCreatedConstructorElement});
  }

  // Try to run the created constructor, and record the results.
  static constructB() {
    // This should throw an exception.
    constructedB = new B.created();
    return constructedB;
  }

  static void test() {
    register();

    // Exception should have occurred on upgrade.
    var e;
    expectGlobalError(() {
      e = new Element.tag(tag);
    });
    expect(e is NestedCreatedConstructorElement, isFalse);
    expect(e is HtmlElement, isTrue);
    // Should not have been set.
    expect(constructedB, isNull);
  }
}

class CreatedWithParametersElement extends HtmlElement {
  CreatedWithParametersElement.created(ignoredParam) : super.created();
}

void expectGlobalError(Function test) {
  js.context['testExpectsGlobalError'] = true;
  try {
    test();
  } catch (e) {
    rethrow;
  } finally {
    js.context['testExpectsGlobalError'] = false;
  }
  var errors = js.context['testSuppressedGlobalErrors'];
  expect(errors['length'], 1);
  // Clear out the errors;
  js.context['testSuppressedGlobalErrors']['length'] = 0;
}
