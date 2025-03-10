// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: AppView.:[subclass=AppView|powerset=0]*/
abstract class AppView<T> {
  /*member: AppView.ctx:Union(null, [exact=CardComponent2|powerset=0], [exact=CardComponent|powerset=0], powerset: 1)*/
  T? ctx;
}

/*member: CardComponent.:[exact=CardComponent|powerset=0]*/
class CardComponent {
  /*member: CardComponent.title:Value([null|exact=JSString|powerset=1], value: "foo", powerset: 1)*/
  String? title;
}

/*member: ViewCardComponent.:[exact=ViewCardComponent|powerset=0]*/
class ViewCardComponent extends AppView<CardComponent> {
  /*member: ViewCardComponent._title:Value([null|exact=JSString|powerset=1], value: "foo", powerset: 1)*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(
    String /*Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/
    value,
  ) {
    if ( /*invoke: [exact=ViewCardComponent|powerset=0]*/ checkBinding(
      /*[exact=ViewCardComponent|powerset=0]*/ _title,
      value,
    )) {
      /*[exact=ViewCardComponent|powerset=0]*/
      ctx!. /*update: [exact=CardComponent|powerset=0]*/ title = value;
      /*update: [exact=ViewCardComponent|powerset=0]*/
      _title = value;
    }
  }

  /*member: ViewCardComponent.checkBinding:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  checkBinding(
    /*Value([null|exact=JSString|powerset=1], value: "foo", powerset: 1)*/ a,
    /*Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ b,
  ) => true;
}

/*member: CardComponent2.:[exact=CardComponent2|powerset=0]*/
class CardComponent2 {
  /*member: CardComponent2.title:Value([null|exact=JSString|powerset=1], value: "bar", powerset: 1)*/
  String? title;
}

/*member: ViewCardComponent2.:[exact=ViewCardComponent2|powerset=0]*/
class ViewCardComponent2 extends AppView<CardComponent2> {
  /*member: ViewCardComponent2._title:Value([null|exact=JSString|powerset=1], value: "bar", powerset: 1)*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(
    String /*Value([exact=JSString|powerset=0], value: "bar", powerset: 0)*/
    value,
  ) {
    if ( /*invoke: [exact=ViewCardComponent2|powerset=0]*/ checkBinding(
      /*[exact=ViewCardComponent2|powerset=0]*/ _title,
      value,
    )) {
      /*[exact=ViewCardComponent2|powerset=0]*/
      ctx!. /*update: [exact=CardComponent2|powerset=0]*/ title = value;
      /*update: [exact=ViewCardComponent2|powerset=0]*/
      _title = value;
    }
  }

  /*member: ViewCardComponent2.checkBinding:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  checkBinding(
    /*Value([null|exact=JSString|powerset=1], value: "bar", powerset: 1)*/ a,
    /*Value([exact=JSString|powerset=0], value: "bar", powerset: 0)*/ b,
  ) => true;
}

/*member: main:[null|powerset=1]*/
main() {
  var c1 = ViewCardComponent();
  c1. /*update: [exact=ViewCardComponent|powerset=0]*/ ctx = CardComponent();
  c1. /*update: [exact=ViewCardComponent|powerset=0]*/ ng_title = 'foo';
  var c2 = ViewCardComponent2();
  c2. /*update: [exact=ViewCardComponent2|powerset=0]*/ ctx = CardComponent2();
  c2. /*update: [exact=ViewCardComponent2|powerset=0]*/ ng_title = 'bar';
}
