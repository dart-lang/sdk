// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library created_callback_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import '../utils.dart';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);

  static int createdInvocations = 0;

  void created() {
    createdInvocations++;
  }
}

class B extends HtmlElement {
  static final tag = 'x-b';
  factory B() => new Element.tag(tag);
}

class C extends HtmlElement {
  static final tag = 'x-c';
  factory C() => new Element.tag(tag);

  static int createdInvocations = 0;
  static var div;

  void created() {
    createdInvocations++;

    if (this.id != 'u') {
      return;
    }

    var t = div.query('#t');
    var v = div.query('#v');
    var w = div.query('#w');

    expect(query('x-b:not(:unresolved)'), this);
    expect(queryAll(':unresolved'), [v, w]);

    // As per:
    // http://www.w3.org/TR/2013/WD-custom-elements-20130514/#serializing-and-parsing
    // creation order is t, u, v, w (postorder).
    expect(t is C, isTrue);
    // Note, this is different from JavaScript where this would be false.
    expect(v is C, isTrue);
  }
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's
  // fast/dom/custom/created-callback test.

  setUp(loadPolyfills);

  test('transfer created callback', () {
    document.register(A.tag, A);
    var x = new A();
    expect(A.createdInvocations, 1);
  });

  test(':unresolved and created callback timing', () {
    document.register(B.tag, B);
    document.register(C.tag, C);

    var div = new DivElement();
    C.div = div;
    div.setInnerHtml("""
<x-c id="t"></x-c>
<x-b id="u"></x-b>
<x-c id="v"></x-c>
<x-b id="w"></x-b>
""", treeSanitizer: new NullTreeSanitizer());

    Platform.upgradeCustomElements(div);

    expect(C.createdInvocations, 2);
    expect(div.query('#w') is B, isTrue);
  });

  // TODO(vsm): Port additional test from upstream here:
  // http://src.chromium.org/viewvc/blink/trunk/LayoutTests/fast/dom/custom/created-callback.html?r1=156141&r2=156185
}
