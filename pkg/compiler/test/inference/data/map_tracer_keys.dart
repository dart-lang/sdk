// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}

/*member: aDouble1:[null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]*/
dynamic aDouble1 = 42.5;

/*member: aList1:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
dynamic aList1 = [42];

/*member: consume1:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
consume1(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/ x,
) => x;

/*member: test1:[null|powerset={null}]*/
test1() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/
      ['d'] =
      5.5;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}{O}{N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/
          keys) {
    aDouble1 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume1(aList1);
}

/*member: aDouble2:[null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]*/
dynamic aDouble2 = 42.5;

/*member: aList2:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
dynamic aList2 = [42];

/*member: consume2:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
consume2(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/ x,
) => x;

/*member: test2:[null|powerset={null}]*/
test2() {
  dynamic theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
      [aList2] =
      5.5;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}{O}{N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  for (var key
      in theMap
          .
          /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
          keys) {
    aDouble2 =
        theMap
        /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume2(aList2);
}

/*member: aDouble3:Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN})*/
dynamic aDouble3 = 42.5;

/*member: aList3:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
dynamic aList3 = [42];

/*member: consume3:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
consume3(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/ x,
) => x;

/*member: test3:[null|powerset={null}]*/
test3() {
  dynamic theMap = <dynamic, dynamic>{'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN}), map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {null}{I}{G}{M})}, powerset: {N}{O}{N})*/
      ['d'] =
      aList3;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}{O}{N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN}), map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {null}{I}{G}{M})}, powerset: {N}{O}{N})*/
          keys) {
    aDouble3 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN}), map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {null}{I}{G}{M})}, powerset: {N}{O}{N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume3(aList3);
}

/*member: aDouble4:[null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]*/
dynamic aDouble4 = 42.5;

/*member: aList4:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
dynamic aList4 = [42];

/*member: consume4:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
consume4(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/ x,
) => x;

/*member: test4:[null|powerset={null}]*/
test4() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': 5.5};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}{O}{N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: [exact=JSNumNotInt|powerset={I}{O}{N}]}, powerset: {N}{O}{N})*/
          keys) {
    aDouble4 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: [exact=JSNumNotInt|powerset={I}{O}{N}]}, powerset: {N}{O}{N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume4(aList4);
}

/*member: aDouble5:[null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]*/
dynamic aDouble5 = 42.5;

/*member: aList5:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
dynamic aList5 = [42];

/*member: consume5:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
consume5(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/ x,
) => x;

/*member: test5:[null|powerset={null}]*/
test5() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, aList5: 5.5};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}{O}{N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  for (var key
      in theMap
          .
          /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{GO}{IM}), value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
          keys) {
    aDouble5 =
        theMap
        /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{GO}{IM}), value: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume5(aList5);
}

/*member: aDouble6:Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN})*/
dynamic aDouble6 = 42.5;
/*member: aList6:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
dynamic aList6 = [42];

/*member: consume6:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
consume6(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/ x,
) => x;

/*member: test6:[null|powerset={null}]*/
test6() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': aList6};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}{O}{N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}{O}{N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN}), map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
          keys) {
    aDouble6 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN}), map: {a: [exact=JSNumNotInt|powerset={I}{O}{N}], b: [exact=JSNumNotInt|powerset={I}{O}{N}], c: [exact=JSNumNotInt|powerset={I}{O}{N}], d: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume6(aList6);
}
