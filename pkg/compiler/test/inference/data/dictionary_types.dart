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
}

/*member: dictionaryA1:Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {N}{O}{N})*/
dynamic dictionaryA1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: dictionaryB1:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "anotherString", powerset: {null}{I}{O}{I}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/
dynamic dictionaryB1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: otherDict1:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN}), map: {stringTwo: Value([exact=JSString|powerset={I}{O}{I}], value: "anotherString", powerset: {I}{O}{I}), intTwo: [exact=JSUInt31|powerset={I}{O}{N}]}, powerset: {N}{O}{N})*/
dynamic otherDict1 = {'stringTwo': "anotherString", 'intTwo': 84};

/*member: int1:[exact=JSUInt31|powerset={I}{O}{N}]*/
dynamic int1 = 0;

/*member: anotherInt1:[exact=JSUInt31|powerset={I}{O}{N}]*/
dynamic anotherInt1 = 0;

/*member: nullOrInt1:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
dynamic nullOrInt1 = 0;

/*member: dynamic1:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
dynamic dynamic1 = 0;

/*member: test1:[null|powerset={null}]*/
test1() {
  dictionaryA1
      . /*invoke: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {N}{O}{N})*/ addAll(
        otherDict1,
      );
  dictionaryB1
      . /*invoke: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "anotherString", powerset: {null}{I}{O}{I}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/ addAll(
        {'stringTwo': "anotherString", 'intTwo': 84},
      );
  int1 =
      dictionaryB1
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "anotherString", powerset: {null}{I}{O}{I}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/
      ['int'];
  anotherInt1 =
      otherDict1
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN}), map: {stringTwo: Value([exact=JSString|powerset={I}{O}{I}], value: "anotherString", powerset: {I}{O}{I}), intTwo: [exact=JSUInt31|powerset={I}{O}{N}]}, powerset: {N}{O}{N})*/
      ['intTwo'];
  dynamic1 =
      dictionaryA1 /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {N}{O}{N})*/ ['int'];
  nullOrInt1 =
      dictionaryB1
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "anotherString", powerset: {null}{I}{O}{I}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/
      ['intTwo'];
}

/*member: dictionaryA2:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
dynamic dictionaryA2 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: dictionaryB2:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), intTwo: [exact=JSUInt31|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
dynamic dictionaryB2 = {'string': "aString", 'intTwo': 42, 'list': []};

/*member: nullOrInt2:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
dynamic nullOrInt2 = 0;

/*member: aString2:[exact=JSString|powerset={I}{O}{I}]*/
dynamic aString2 = "";

/*member: doubleOrNull2:[null|exact=JSNumNotInt|powerset={null}{I}{O}{N}]*/
dynamic doubleOrNull2 = 22.2;

/*member: test2:[null|powerset={null}]*/
test2() {
  var union =
      dictionaryA2
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
      ['foo']
      ? dictionaryA2
      : dictionaryB2;
  nullOrInt2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {int: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], double: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
      ['intTwo'];
  aString2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {int: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], double: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
      ['string'];
  doubleOrNull2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {int: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], double: [null|exact=JSNumNotInt|powerset={null}{I}{O}{N}], string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
      ['double'];
}

/*member: dictionary3:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
dynamic dictionary3 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};
/*member: keyD3:Value([exact=JSString|powerset={I}{O}{I}], value: "double", powerset: {I}{O}{I})*/
dynamic keyD3 = 'double';

/*member: keyI3:Value([exact=JSString|powerset={I}{O}{I}], value: "int", powerset: {I}{O}{I})*/
dynamic keyI3 = 'int';

/*member: keyN3:Value([exact=JSString|powerset={I}{O}{I}], value: "notFoundInMap", powerset: {I}{O}{I})*/
dynamic keyN3 = 'notFoundInMap';

/*member: knownDouble3:[exact=JSNumNotInt|powerset={I}{O}{N}]*/
dynamic knownDouble3 = 42.2;

/*member: intOrNull3:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
dynamic intOrNull3 =
    dictionary3
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
    [keyI3];

/*member: justNull3:[null|powerset={null}]*/
dynamic justNull3 =
    dictionary3
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
    [keyN3];

/*member: test3:[null|powerset={null}]*/
test3() {
  knownDouble3 =
      dictionary3
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{IMN}), map: {string: Value([exact=JSString|powerset={I}{O}{I}], value: "aString", powerset: {I}{O}{I}), int: [exact=JSUInt31|powerset={I}{O}{N}], double: [exact=JSNumNotInt|powerset={I}{O}{N}], list: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/
      [keyD3];
  // ignore: unused_local_variable
  var x = [intOrNull3, justNull3];
}

class A4 {
  /*member: A4.:[exact=A4|powerset={N}{O}{N}]*/
  A4();
  /*member: A4.foo4:[exact=JSUInt31|powerset={I}{O}{N}]*/
  foo4(
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN}), map: {anInt: [exact=JSUInt31|powerset={I}{O}{N}], aString: Value([exact=JSString|powerset={I}{O}{I}], value: "theString", powerset: {I}{O}{I})}, powerset: {N}{O}{N})*/ value,
  ) {
    return value /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN}), map: {anInt: [exact=JSUInt31|powerset={I}{O}{N}], aString: Value([exact=JSString|powerset={I}{O}{I}], value: "theString", powerset: {I}{O}{I})}, powerset: {N}{O}{N})*/ ['anInt'];
  }
}

class B4 {
  /*member: B4.:[exact=B4|powerset={N}{O}{N}]*/
  B4();

  /*member: B4.foo4:[exact=JSUInt31|powerset={I}{O}{N}]*/
  foo4(
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN}), map: {anInt: [exact=JSUInt31|powerset={I}{O}{N}], aString: Value([exact=JSString|powerset={I}{O}{I}], value: "theString", powerset: {I}{O}{I})}, powerset: {N}{O}{N})*/ value,
  ) {
    return 0;
  }
}

/*member: test4:[null|powerset={null}]*/
test4() {
  var dictionary = {'anInt': 42, 'aString': "theString"};
  var it;
  if ([true, false]
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSBool|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/
  [0]) {
    it = A4();
  } else {
    it = B4();
  }
  print(
    it. /*invoke: Union([exact=A4|powerset={N}{O}{N}], [exact=B4|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ foo4(
          dictionary,
        ) /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +
        2,
  );
}

/*member: dict5:Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {null}{N}{O}{N})*/
dynamic dict5 = makeMap5([1, 2]);

/*member: notInt5:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
dynamic notInt5 = 0;

/*member: alsoNotInt5:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
dynamic alsoNotInt5 = 0;

/*member: makeMap5:Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {N}{O}{N})*/
makeMap5(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/ values,
) {
  return {
    'moo':
        values
        /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/
        [0],
    'boo':
        values
        /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/
        [1],
  };
}

/*member: test5:[null|powerset={null}]*/
test5() {
  dict5
      /*update: Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {null}{N}{O}{N})*/
      ['goo'] =
      42;
  var closure =
      /*Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {null}{N}{O}{N})*/
      () => dict5;
  notInt5 = closure()['boo'];
  alsoNotInt5 =
      dict5
      /*Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], powerset: {null}{N}{O}{N})*/
      ['goo'];
  print("$notInt5 and $alsoNotInt5.");
}
