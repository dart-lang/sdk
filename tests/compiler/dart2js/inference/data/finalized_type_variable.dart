// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: AppView.:[subclass=AppView]*/
abstract class AppView<T> {
  /*element: AppView.ctx:Union([exact=CardComponent2], [null|exact=CardComponent])*/
  T ctx;
}

/*element: CardComponent.:[exact=CardComponent]*/
class CardComponent {
  /*element: CardComponent.title:Value([null|exact=JSString], value: "foo")*/
  String title;
}

/*element: ViewCardComponent.:[exact=ViewCardComponent]*/
class ViewCardComponent extends AppView<CardComponent> {
  /*element: ViewCardComponent._title:Value([null|exact=JSString], value: "foo")*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(String /*Value([exact=JSString], value: "foo")*/ value) {
    if (/*invoke: [exact=ViewCardComponent]*/ checkBinding(
        /*[exact=ViewCardComponent]*/ _title,
        value)) {
      /*[exact=ViewCardComponent]*/ ctx
          . /*update: [null|exact=CardComponent]*/ title = value;
      /*update: [exact=ViewCardComponent]*/ _title = value;
    }
  }

  /*element: ViewCardComponent.checkBinding:Value([exact=JSBool], value: true)*/
  checkBinding(
          /*Value([null|exact=JSString], value: "foo")*/ a,
          /*Value([exact=JSString], value: "foo")*/ b) =>
      true;
}

/*element: CardComponent2.:[exact=CardComponent2]*/
class CardComponent2 {
  /*element: CardComponent2.title:Value([null|exact=JSString], value: "bar")*/
  String title;
}

/*element: ViewCardComponent2.:[exact=ViewCardComponent2]*/
class ViewCardComponent2 extends AppView<CardComponent2> {
  /*element: ViewCardComponent2._title:Value([null|exact=JSString], value: "bar")*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(String /*Value([exact=JSString], value: "bar")*/ value) {
    if (/*invoke: [exact=ViewCardComponent2]*/ checkBinding(
        /*[exact=ViewCardComponent2]*/ _title,
        value)) {
      /*[exact=ViewCardComponent2]*/ ctx
          . /*update: [null|exact=CardComponent2]*/ title = value;
      /*update: [exact=ViewCardComponent2]*/ _title = value;
    }
  }

  /*element: ViewCardComponent2.checkBinding:Value([exact=JSBool], value: true)*/
  checkBinding(
          /*Value([null|exact=JSString], value: "bar")*/ a,
          /*Value([exact=JSString], value: "bar")*/ b) =>
      true;
}

/*element: main:[null]*/
main() {
  var c1 = new ViewCardComponent();
  c1. /*update: [exact=ViewCardComponent]*/ ctx = new CardComponent();
  c1. /*update: [exact=ViewCardComponent]*/ ng_title = 'foo';
  var c2 = new ViewCardComponent2();
  c2. /*update: [exact=ViewCardComponent2]*/ ctx = new CardComponent2();
  c2. /*update: [exact=ViewCardComponent2]*/ ng_title = 'bar';
}
