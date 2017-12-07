// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  document.createElement(CustomElement.tag);
  newCustom();
  newCustomCreated();
  newNormal();
  newNormalCreated();
}

////////////////////////////////////////////////////////////////////////////////
// Create a custom element. The factory is inlined but the generative
// constructor isn't.
////////////////////////////////////////////////////////////////////////////////

/*element: newCustom:[]*/
@NoInline()
newCustom() {
  new CustomElement();
}

/*element: newCustomCreated:[]*/
@NoInline()
newCustomCreated() {
  new CustomElement.created();
}

class CustomElement extends HtmlElement {
  static final tag = 'x-foo';

  /*element: CustomElement.:[newCustom]*/
  factory CustomElement() => new Element.tag(tag);

  /*element: CustomElement.created:[]*/
  CustomElement.created() : super.created() {
    print('boo');
  }
}

////////////////////////////////////////////////////////////////////////////////
// Create a normal class, similar to a custom element. Both the factory and
// the generative constructor are inlined.
////////////////////////////////////////////////////////////////////////////////

/*element: newNormal:[]*/
@NoInline()
newNormal() {
  new NormalElement();
}

/*element: newNormalCreated:[]*/
@NoInline()
newNormalCreated() {
  new NormalElement.created();
}

class NormalElement {
  /*element: NormalElement.:[newNormal]*/
  factory NormalElement() => null;

  /*element: NormalElement.created:[newNormalCreated,newNormalCreated+]*/
  NormalElement.created() {
    print('foo');
  }
}
