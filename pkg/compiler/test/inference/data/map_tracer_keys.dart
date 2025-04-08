// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}

/*member: aDouble1:[null|exact=JSNumNotInt|powerset=1]*/
dynamic aDouble1 = 42.5;

/*member: aList1:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
dynamic aList1 = [42];

/*member: consume1:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
consume1(
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/ x,
) => x;

/*member: test1:[null|powerset=1]*/
test1() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: [null|exact=JSNumNotInt|powerset=1]}, powerset: 0)*/
      ['d'] =
      5.5;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset=0]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: [null|exact=JSNumNotInt|powerset=1]}, powerset: 0)*/
          keys) {
    aDouble1 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: [null|exact=JSNumNotInt|powerset=1]}, powerset: 0)*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume1(aList1);
}

/*member: aDouble2:[null|exact=JSNumNotInt|powerset=1]*/
dynamic aDouble2 = 42.5;

/*member: aList2:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
dynamic aList2 = [42];

/*member: consume2:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
consume2(
  /*Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/ x,
) => x;

/*member: test2:[null|powerset=1]*/
test2() {
  dynamic theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], powerset: 0)*/
      [aList2] =
      5.5;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset=0]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  for (var key
      in theMap
          .
          /*Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], powerset: 0)*/
          keys) {
    aDouble2 =
        theMap
        /*Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], powerset: 0)*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume2(aList2);
}

/*member: aDouble3:Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], powerset: 1)*/
dynamic aDouble3 = 42.5;

/*member: aList3:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
dynamic aList3 = [42];

/*member: consume3:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
consume3(
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/ x,
) => x;

/*member: test3:[null|powerset=1]*/
test3() {
  dynamic theMap = <dynamic, dynamic>{'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], powerset: 1), map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: Container([null|exact=JSExtendableArray|powerset=1], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 1)}, powerset: 0)*/
      ['d'] =
      aList3;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset=0]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], powerset: 1), map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: Container([null|exact=JSExtendableArray|powerset=1], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 1)}, powerset: 0)*/
          keys) {
    aDouble3 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], powerset: 1), map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: Container([null|exact=JSExtendableArray|powerset=1], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 1)}, powerset: 0)*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume3(aList3);
}

/*member: aDouble4:[null|exact=JSNumNotInt|powerset=1]*/
dynamic aDouble4 = 42.5;

/*member: aList4:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
dynamic aList4 = [42];

/*member: consume4:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
consume4(
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/ x,
) => x;

/*member: test4:[null|powerset=1]*/
test4() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': 5.5};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset=0]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: [exact=JSNumNotInt|powerset=0]}, powerset: 0)*/
          keys) {
    aDouble4 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSNumNotInt|powerset=1], map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: [exact=JSNumNotInt|powerset=0]}, powerset: 0)*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume4(aList4);
}

/*member: aDouble5:[null|exact=JSNumNotInt|powerset=1]*/
dynamic aDouble5 = 42.5;

/*member: aList5:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
dynamic aList5 = [42];

/*member: consume5:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
consume5(
  /*Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/ x,
) => x;

/*member: test5:[null|powerset=1]*/
test5() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, aList5: 5.5};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset=0]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  for (var key
      in theMap
          .
          /*Map([exact=JsLinkedHashMap|powerset=0], key: Union([exact=JSExtendableArray|powerset=0], [exact=JSString|powerset=0], powerset: 0), value: [null|exact=JSNumNotInt|powerset=1], powerset: 0)*/
          keys) {
    aDouble5 =
        theMap
        /*Map([exact=JsLinkedHashMap|powerset=0], key: Union([exact=JSExtendableArray|powerset=0], [exact=JSString|powerset=0], powerset: 0), value: [null|exact=JSNumNotInt|powerset=1], powerset: 0)*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume5(aList5);
}

/*member: aDouble6:Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], powerset: 1)*/
dynamic aDouble6 = 42.5;
/*member: aList6:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
dynamic aList6 = [42];

/*member: consume6:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
consume6(
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/ x,
) => x;

/*member: test6:[null|powerset=1]*/
test6() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': aList6};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset=0]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset=0]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], powerset: 1), map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)}, powerset: 0)*/
          keys) {
    aDouble6 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], powerset: 1), map: {a: [exact=JSNumNotInt|powerset=0], b: [exact=JSNumNotInt|powerset=0], c: [exact=JSNumNotInt|powerset=0], d: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)}, powerset: 0)*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume6(aList6);
}
