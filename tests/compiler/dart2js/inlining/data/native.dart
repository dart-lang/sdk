// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:html';

/*member: main:[]*/
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

/*member: newCustom:[]*/
@pragma('dart2js:noInline')
newCustom() {
  new CustomElement();
}

/*member: newCustomCreated:[]*/
@pragma('dart2js:noInline')
newCustomCreated() {
  new CustomElement.created();
}

class CustomElement extends HtmlElement {
  static final tag = 'x-foo';

  /*member: CustomElement.:[newCustom:CustomElement]*/
  factory CustomElement() => new Element.tag(tag);

  /*member: CustomElement.created:[]*/
  CustomElement.created() : super.created() {
    print('boo');
  }
}

////////////////////////////////////////////////////////////////////////////////
// Create a normal class, similar to a custom element. Both the factory and
// the generative constructor are inlined.
////////////////////////////////////////////////////////////////////////////////

/*member: newNormal:[]*/
@pragma('dart2js:noInline')
newNormal() {
  new NormalElement();
}

/*member: newNormalCreated:[]*/
@pragma('dart2js:noInline')
newNormalCreated() {
  new NormalElement.created();
}

class NormalElement {
  /*member: NormalElement.:[newNormal:NormalElement]*/
  factory NormalElement() => null;

  /*member: NormalElement.created:[newNormalCreated+,newNormalCreated:NormalElement]*/
  NormalElement.created() {
    print('foo');
  }
}
