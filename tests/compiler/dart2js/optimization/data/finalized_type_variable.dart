// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class AppView<T> {
  T ctx;
}

class CardComponent {
  String title;
}

class ViewCardComponent extends AppView<CardComponent> {
  /*element: ViewCardComponent.method1:
   FieldGet=[name=AppView.ctx],
   FieldSet=[name=CardComponent.title]
  */
  @pragma('dart2js:noInline')
  method1(String value) {
    ctx.title = value;
  }

  /*element: ViewCardComponent.method2:
   FieldGet=[name=AppView.ctx,name=CardComponent.title]
  */
  @pragma('dart2js:noInline')
  method2() {
    return ctx.title;
  }
}

class CardComponent2 {
  String title;
}

class ViewCardComponent2 extends AppView<CardComponent2> {
  /*element: ViewCardComponent2.method1:
   FieldGet=[name=AppView.ctx],
   FieldSet=[name=CardComponent2.title]
  */
  @pragma('dart2js:noInline')
  method1(String value) {
    ctx.title = value;
  }

  /*element: ViewCardComponent2.method2:
   FieldGet=[name=AppView.ctx,name=CardComponent2.title]
  */
  @pragma('dart2js:noInline')
  method2() {
    return ctx.title;
  }
}

/*strong.element: main:*/
/*omit.element: main:FieldSet=[name=AppView.ctx,name=AppView.ctx]*/
main() {
  var c1 = new ViewCardComponent();
  c1.ctx = new CardComponent();
  c1.method1('foo');
  c1.method2();
  var c2 = new ViewCardComponent2();
  c2.ctx = new CardComponent2();
  c2.method1('bar');
  c2.method2();
}
