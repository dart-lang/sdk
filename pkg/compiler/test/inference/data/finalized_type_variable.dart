// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: AppView.:[subclass=AppView|powerset={N}{O}]*/
abstract class AppView<T> {
  /*member: AppView.ctx:Union(null, [exact=CardComponent2|powerset={N}{O}], [exact=CardComponent|powerset={N}{O}], powerset: {null}{N}{O})*/
  T? ctx;
}

/*member: CardComponent.:[exact=CardComponent|powerset={N}{O}]*/
class CardComponent {
  /*member: CardComponent.title:Value([null|exact=JSString|powerset={null}{I}{O}], value: "foo", powerset: {null}{I}{O})*/
  String? title;
}

/*member: ViewCardComponent.:[exact=ViewCardComponent|powerset={N}{O}]*/
class ViewCardComponent extends AppView<CardComponent> {
  /*member: ViewCardComponent._title:Value([null|exact=JSString|powerset={null}{I}{O}], value: "foo", powerset: {null}{I}{O})*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(
    String /*Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O})*/
    value,
  ) {
    if ( /*invoke: [exact=ViewCardComponent|powerset={N}{O}]*/ checkBinding(
      /*[exact=ViewCardComponent|powerset={N}{O}]*/ _title,
      value,
    )) {
      /*[exact=ViewCardComponent|powerset={N}{O}]*/
      ctx!. /*update: [exact=CardComponent|powerset={N}{O}]*/ title = value;
      /*update: [exact=ViewCardComponent|powerset={N}{O}]*/
      _title = value;
    }
  }

  /*member: ViewCardComponent.checkBinding:Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O})*/
  checkBinding(
    /*Value([null|exact=JSString|powerset={null}{I}{O}], value: "foo", powerset: {null}{I}{O})*/ a,
    /*Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O})*/ b,
  ) => true;
}

/*member: CardComponent2.:[exact=CardComponent2|powerset={N}{O}]*/
class CardComponent2 {
  /*member: CardComponent2.title:Value([null|exact=JSString|powerset={null}{I}{O}], value: "bar", powerset: {null}{I}{O})*/
  String? title;
}

/*member: ViewCardComponent2.:[exact=ViewCardComponent2|powerset={N}{O}]*/
class ViewCardComponent2 extends AppView<CardComponent2> {
  /*member: ViewCardComponent2._title:Value([null|exact=JSString|powerset={null}{I}{O}], value: "bar", powerset: {null}{I}{O})*/
  var _title;

  @pragma('dart2js:noInline')
  set ng_title(
    String /*Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O})*/
    value,
  ) {
    if ( /*invoke: [exact=ViewCardComponent2|powerset={N}{O}]*/ checkBinding(
      /*[exact=ViewCardComponent2|powerset={N}{O}]*/ _title,
      value,
    )) {
      /*[exact=ViewCardComponent2|powerset={N}{O}]*/
      ctx!. /*update: [exact=CardComponent2|powerset={N}{O}]*/ title = value;
      /*update: [exact=ViewCardComponent2|powerset={N}{O}]*/
      _title = value;
    }
  }

  /*member: ViewCardComponent2.checkBinding:Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O})*/
  checkBinding(
    /*Value([null|exact=JSString|powerset={null}{I}{O}], value: "bar", powerset: {null}{I}{O})*/ a,
    /*Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O})*/ b,
  ) => true;
}

/*member: main:[null|powerset={null}]*/
main() {
  var c1 = ViewCardComponent();
  c1. /*update: [exact=ViewCardComponent|powerset={N}{O}]*/ ctx =
      CardComponent();
  c1. /*update: [exact=ViewCardComponent|powerset={N}{O}]*/ ng_title = 'foo';
  var c2 = ViewCardComponent2();
  c2. /*update: [exact=ViewCardComponent2|powerset={N}{O}]*/ ctx =
      CardComponent2();
  c2. /*update: [exact=ViewCardComponent2|powerset={N}{O}]*/ ng_title = 'bar';
}
