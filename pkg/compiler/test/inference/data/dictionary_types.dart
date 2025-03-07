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
}

/*member: dictionaryA1:Map([exact=JsLinkedHashMap|powerset=0], key: [null|subclass=Object|powerset=1], value: [null|subclass=Object|powerset=1], powerset: 0)*/
dynamic dictionaryA1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: dictionaryB1:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0), stringTwo: Value([null|exact=JSString|powerset=1], value: "anotherString", powerset: 1), intTwo: [null|exact=JSUInt31|powerset=1]}, powerset: 0)*/
dynamic dictionaryB1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: otherDict1:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {stringTwo: Value([exact=JSString|powerset=0], value: "anotherString", powerset: 0), intTwo: [exact=JSUInt31|powerset=0]}, powerset: 0)*/
dynamic otherDict1 = {'stringTwo': "anotherString", 'intTwo': 84};

/*member: int1:[exact=JSUInt31|powerset=0]*/
dynamic int1 = 0;

/*member: anotherInt1:[exact=JSUInt31|powerset=0]*/
dynamic anotherInt1 = 0;

/*member: nullOrInt1:[null|exact=JSUInt31|powerset=1]*/
dynamic nullOrInt1 = 0;

/*member: dynamic1:[null|subclass=Object|powerset=1]*/
dynamic dynamic1 = 0;

/*member: test1:[null|powerset=1]*/
test1() {
  dictionaryA1
      . /*invoke: Map([exact=JsLinkedHashMap|powerset=0], key: [null|subclass=Object|powerset=1], value: [null|subclass=Object|powerset=1], powerset: 0)*/ addAll(
        otherDict1,
      );
  dictionaryB1
      . /*invoke: Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0), stringTwo: Value([null|exact=JSString|powerset=1], value: "anotherString", powerset: 1), intTwo: [null|exact=JSUInt31|powerset=1]}, powerset: 0)*/ addAll(
        {'stringTwo': "anotherString", 'intTwo': 84},
      );
  int1 =
      dictionaryB1
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0), stringTwo: Value([null|exact=JSString|powerset=1], value: "anotherString", powerset: 1), intTwo: [null|exact=JSUInt31|powerset=1]}, powerset: 0)*/
      ['int'];
  anotherInt1 =
      otherDict1
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {stringTwo: Value([exact=JSString|powerset=0], value: "anotherString", powerset: 0), intTwo: [exact=JSUInt31|powerset=0]}, powerset: 0)*/
      ['intTwo'];
  dynamic1 =
      dictionaryA1 /*Map([exact=JsLinkedHashMap|powerset=0], key: [null|subclass=Object|powerset=1], value: [null|subclass=Object|powerset=1], powerset: 0)*/ ['int'];
  nullOrInt1 =
      dictionaryB1
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0), stringTwo: Value([null|exact=JSString|powerset=1], value: "anotherString", powerset: 1), intTwo: [null|exact=JSUInt31|powerset=1]}, powerset: 0)*/
      ['intTwo'];
}

/*member: dictionaryA2:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
dynamic dictionaryA2 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: dictionaryB2:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), intTwo: [exact=JSUInt31|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
dynamic dictionaryB2 = {'string': "aString", 'intTwo': 42, 'list': []};

/*member: nullOrInt2:[null|exact=JSUInt31|powerset=1]*/
dynamic nullOrInt2 = 0;

/*member: aString2:[exact=JSString|powerset=0]*/
dynamic aString2 = "";

/*member: doubleOrNull2:[null|exact=JSNumNotInt|powerset=1]*/
dynamic doubleOrNull2 = 22.2;

/*member: test2:[null|powerset=1]*/
test2() {
  var union =
      dictionaryA2
          /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
          ['foo']
          ? dictionaryA2
          : dictionaryB2;
  nullOrInt2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {int: [null|exact=JSUInt31|powerset=1], double: [null|exact=JSNumNotInt|powerset=1], string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), intTwo: [null|exact=JSUInt31|powerset=1], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
      ['intTwo'];
  aString2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {int: [null|exact=JSUInt31|powerset=1], double: [null|exact=JSNumNotInt|powerset=1], string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), intTwo: [null|exact=JSUInt31|powerset=1], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
      ['string'];
  doubleOrNull2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {int: [null|exact=JSUInt31|powerset=1], double: [null|exact=JSNumNotInt|powerset=1], string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), intTwo: [null|exact=JSUInt31|powerset=1], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
      ['double'];
}

/*member: dictionary3:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
dynamic dictionary3 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};
/*member: keyD3:Value([exact=JSString|powerset=0], value: "double", powerset: 0)*/
dynamic keyD3 = 'double';

/*member: keyI3:Value([exact=JSString|powerset=0], value: "int", powerset: 0)*/
dynamic keyI3 = 'int';

/*member: keyN3:Value([exact=JSString|powerset=0], value: "notFoundInMap", powerset: 0)*/
dynamic keyN3 = 'notFoundInMap';

/*member: knownDouble3:[exact=JSNumNotInt|powerset=0]*/
dynamic knownDouble3 = 42.2;

/*member: intOrNull3:[null|exact=JSUInt31|powerset=1]*/
dynamic intOrNull3 =
    dictionary3
    /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
    [keyI3];

/*member: justNull3:[null|powerset=1]*/
dynamic justNull3 =
    dictionary3
    /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
    [keyN3];

/*member: test3:[null|powerset=1]*/
test3() {
  knownDouble3 =
      dictionary3
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {string: Value([exact=JSString|powerset=0], value: "aString", powerset: 0), int: [exact=JSUInt31|powerset=0], double: [exact=JSNumNotInt|powerset=0], list: Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)}, powerset: 0)*/
      [keyD3];
  // ignore: unused_local_variable
  var x = [intOrNull3, justNull3];
}

class A4 {
  /*member: A4.:[exact=A4|powerset=0]*/
  A4();
  /*member: A4.foo4:[exact=JSUInt31|powerset=0]*/
  foo4(
    /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {anInt: [exact=JSUInt31|powerset=0], aString: Value([exact=JSString|powerset=0], value: "theString", powerset: 0)}, powerset: 0)*/ value,
  ) {
    return value /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {anInt: [exact=JSUInt31|powerset=0], aString: Value([exact=JSString|powerset=0], value: "theString", powerset: 0)}, powerset: 0)*/ ['anInt'];
  }
}

class B4 {
  /*member: B4.:[exact=B4|powerset=0]*/
  B4();

  /*member: B4.foo4:[exact=JSUInt31|powerset=0]*/
  foo4(
    /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {anInt: [exact=JSUInt31|powerset=0], aString: Value([exact=JSString|powerset=0], value: "theString", powerset: 0)}, powerset: 0)*/ value,
  ) {
    return 0;
  }
}

/*member: test4:[null|powerset=1]*/
test4() {
  var dictionary = {'anInt': 42, 'aString': "theString"};
  var it;
  if ([true, false]
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSBool|powerset=0], length: 2, powerset: 0)*/
  [0]) {
    it = A4();
  } else {
    it = B4();
  }
  print(
    it. /*invoke: Union([exact=A4|powerset=0], [exact=B4|powerset=0], powerset: 0)*/ foo4(
          dictionary,
        ) /*invoke: [exact=JSUInt31|powerset=0]*/ +
        2,
  );
}

/*member: dict5:Map([null|exact=JsLinkedHashMap|powerset=1], key: [exact=JSString|powerset=0], value: [null|subclass=Object|powerset=1], powerset: 1)*/
dynamic dict5 = makeMap5([1, 2]);

/*member: notInt5:[null|subclass=Object|powerset=1]*/
dynamic notInt5 = 0;

/*member: alsoNotInt5:[null|subclass=Object|powerset=1]*/
dynamic alsoNotInt5 = 0;

/*member: makeMap5:Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|subclass=Object|powerset=1], powerset: 0)*/
makeMap5(
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/ values,
) {
  return {
    'moo':
        values
        /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/
        [0],
    'boo':
        values
        /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/
        [1],
  };
}

/*member: test5:[null|powerset=1]*/
test5() {
  dict5
      /*update: Map([null|exact=JsLinkedHashMap|powerset=1], key: [exact=JSString|powerset=0], value: [null|subclass=Object|powerset=1], powerset: 1)*/
      ['goo'] =
      42;
  var closure =
      /*Map([null|exact=JsLinkedHashMap|powerset=1], key: [exact=JSString|powerset=0], value: [null|subclass=Object|powerset=1], powerset: 1)*/
      () => dict5;
  notInt5 = closure()['boo'];
  alsoNotInt5 =
      dict5
      /*Map([null|exact=JsLinkedHashMap|powerset=1], key: [exact=JSString|powerset=0], value: [null|subclass=Object|powerset=1], powerset: 1)*/
      ['goo'];
  print("$notInt5 and $alsoNotInt5.");
}
