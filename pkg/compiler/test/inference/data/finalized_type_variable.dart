// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: AppView.:[subclass=AppView|powerset={N}]*/
abstract class AppView<T> {
  /*member: AppView.ctx:Union(null, [exact=CardComponent2|powerset={N}], [exact=CardComponent|powerset={N}], powerset: {null}{N})*/
  T? ctx;
}

/*member: CardComponent.:[exact=CardComponent|powerset={N}]*/
class CardComponent {
  /*member: CardComponent.title:Value([null|exact=JSString|powerset={null}{I}], value: "foo", powerset: {null}{I})*/
  String? title;
}

/*member: ViewCardComponent.:[exact=ViewCardComponent|powerset={N}]*/
class ViewCardComponent extends AppView<CardComponent> {
  /*member: ViewCardComponent._title:Value([null|exact=JSString|powerset={null}{I}], value: "foo", powerset: {null}{I})*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(
    String /*Value([exact=JSString|powerset={I}], value: "foo", powerset: {I})*/
    value,
  ) {
    if ( /*invoke: [exact=ViewCardComponent|powerset={N}]*/ checkBinding(
      /*[exact=ViewCardComponent|powerset={N}]*/ _title,
      value,
    )) {
      /*[exact=ViewCardComponent|powerset={N}]*/
      ctx!. /*update: [exact=CardComponent|powerset={N}]*/ title = value;
      /*update: [exact=ViewCardComponent|powerset={N}]*/
      _title = value;
    }
  }

  /*member: ViewCardComponent.checkBinding:Value([exact=JSBool|powerset={I}], value: true, powerset: {I})*/
  checkBinding(
    /*Value([null|exact=JSString|powerset={null}{I}], value: "foo", powerset: {null}{I})*/ a,
    /*Value([exact=JSString|powerset={I}], value: "foo", powerset: {I})*/ b,
  ) => true;
}

/*member: CardComponent2.:[exact=CardComponent2|powerset={N}]*/
class CardComponent2 {
  /*member: CardComponent2.title:Value([null|exact=JSString|powerset={null}{I}], value: "bar", powerset: {null}{I})*/
  String? title;
}

/*member: ViewCardComponent2.:[exact=ViewCardComponent2|powerset={N}]*/
class ViewCardComponent2 extends AppView<CardComponent2> {
  /*member: ViewCardComponent2._title:Value([null|exact=JSString|powerset={null}{I}], value: "bar", powerset: {null}{I})*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(
    String /*Value([exact=JSString|powerset={I}], value: "bar", powerset: {I})*/
    value,
  ) {
    if ( /*invoke: [exact=ViewCardComponent2|powerset={N}]*/ checkBinding(
      /*[exact=ViewCardComponent2|powerset={N}]*/ _title,
      value,
    )) {
      /*[exact=ViewCardComponent2|powerset={N}]*/
      ctx!. /*update: [exact=CardComponent2|powerset={N}]*/ title = value;
      /*update: [exact=ViewCardComponent2|powerset={N}]*/
      _title = value;
    }
  }

  /*member: ViewCardComponent2.checkBinding:Value([exact=JSBool|powerset={I}], value: true, powerset: {I})*/
  checkBinding(
    /*Value([null|exact=JSString|powerset={null}{I}], value: "bar", powerset: {null}{I})*/ a,
    /*Value([exact=JSString|powerset={I}], value: "bar", powerset: {I})*/ b,
  ) => true;
}

/*member: main:[null|powerset={null}]*/
main() {
  var c1 = ViewCardComponent();
  c1. /*update: [exact=ViewCardComponent|powerset={N}]*/ ctx = CardComponent();
  c1. /*update: [exact=ViewCardComponent|powerset={N}]*/ ng_title = 'foo';
  var c2 = ViewCardComponent2();
  c2. /*update: [exact=ViewCardComponent2|powerset={N}]*/ ctx =
      CardComponent2();
  c2. /*update: [exact=ViewCardComponent2|powerset={N}]*/ ng_title = 'bar';
}
