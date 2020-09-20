// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*member: main:[null]*/
main() {
  boolFlag = !boolFlag;
  data. /*invoke: Container([exact=JSExtendableArray], element: [subclass=JSInt], length: null)*/ add(
      100);

  var lists = [
    listEmptyDefault,
    listEmptyGrowable,
    listEmptyFixed,
    listEmptyEither,
    listFilledDefault,
    listFilledGrowable,
    listFilledFixed,
    listFilledEither,
    listGenerateDefault,
    listGenerateGrowable,
    listGenerateFixed,
    listGenerateEither,
    listOfDefault,
    listOfGrowable,
    listOfFixed,
    listOfEither,
    listFromDefault,
    listFromGrowable,
    listFromFixed,
    listFromEither,
    listUnmodifiable,
  ];
}

/*member: boolFlag:[exact=JSBool]*/
bool boolFlag = true;

/*member: data:Container([exact=JSExtendableArray], element: [subclass=JSInt], length: null)*/
List<int> data = [/*invoke: [exact=JSUInt31]*/ -1, 1];

// -------- List.empty --------

/*member: listEmptyDefault:Container([exact=JSFixedArray], element: [empty], length: 0)*/
get listEmptyDefault => List<int>.empty();

/*member: listEmptyGrowable:Container([exact=JSExtendableArray], element: [empty], length: 0)*/
get listEmptyGrowable => List<int>.empty(growable: true);

/*member: listEmptyFixed:Container([exact=JSFixedArray], element: [empty], length: 0)*/
get listEmptyFixed => List<int>.empty(growable: false);

/*member: listEmptyEither:Container([subclass=JSMutableArray], element: [empty], length: 0)*/
get listEmptyEither => List<int>.empty(growable: boolFlag);

// -------- List.filled --------

/*member: listFilledDefault:Container([exact=JSFixedArray], element: Value([exact=JSString], value: "x"), length: 5)*/
get listFilledDefault => List.filled(5, 'x');

/*member: listFilledGrowable:Container([exact=JSExtendableArray], element: Value([exact=JSString], value: "g"), length: 5)*/
get listFilledGrowable => List.filled(5, 'g', growable: true);

/*member: listFilledFixed:Container([exact=JSFixedArray], element: Value([exact=JSString], value: "f"), length: 5)*/
get listFilledFixed => List.filled(5, 'f', growable: false);

/*member: listFilledEither:Container([subclass=JSMutableArray], element: Value([exact=JSString], value: "e"), length: 5)*/
get listFilledEither => List.filled(5, 'e', growable: boolFlag);

// -------- List.generate --------

/*member: listGenerateDefault:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: 8)*/
get listGenerateDefault => List.generate(
    8, /*[exact=JSString]*/ (/*[subclass=JSPositiveInt]*/ i) => 'x$i');

/*member: listGenerateGrowable:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: 8)*/
get listGenerateGrowable => List.generate(
    8, /*[exact=JSString]*/ (/*[subclass=JSPositiveInt]*/ i) => 'g$i',
    growable: true);

/*member: listGenerateFixed:Container([exact=JSFixedArray], element: [null|subclass=Object], length: 8)*/
get listGenerateFixed => List.generate(
    8, /*[exact=JSString]*/ (/*[subclass=JSPositiveInt]*/ i) => 'f$i',
    growable: false);

/*member: listGenerateEither:Container([subclass=JSMutableArray], element: [null|subclass=Object], length: 8)*/
get listGenerateEither => List.generate(
    8, /*[exact=JSString]*/ (/*[subclass=JSPositiveInt]*/ i) => 'e$i',
    growable: boolFlag);

// -------- List.of --------

/*member: listOfDefault:[exact=JSExtendableArray]*/
get listOfDefault => List.of(data);

/*member: listOfGrowable:[exact=JSExtendableArray]*/
get listOfGrowable => List.of(data, growable: true);

/*member: listOfFixed:[exact=JSFixedArray]*/
get listOfFixed => List.of(data, growable: false);

/*member: listOfEither:[subclass=JSMutableArray]*/
get listOfEither => List.of(data, growable: boolFlag);

// -------- List.from --------

/*member: listFromDefault:[exact=JSExtendableArray]*/
get listFromDefault => List.from(data);

/*member: listFromGrowable:[exact=JSExtendableArray]*/
get listFromGrowable => List.from(data, growable: true);

/*member: listFromFixed:[exact=JSFixedArray]*/
get listFromFixed => List.from(data, growable: false);

/*member: listFromEither:[subclass=JSMutableArray]*/
get listFromEither => List.from(data, growable: boolFlag);

// -------- List.unmodifiable --------

/*member: listUnmodifiable:[exact=JSUnmodifiableArray]*/
get listUnmodifiable => List.unmodifiable(data);
