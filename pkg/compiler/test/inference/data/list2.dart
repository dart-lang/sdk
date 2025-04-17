// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  boolFlag = !boolFlag;
  data. /*invoke: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSInt|powerset={I}], length: null, powerset: {I})*/ add(
    100,
  );

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
    listGenerateBigClosure,
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

/*member: boolFlag:[exact=JSBool|powerset={I}]*/
bool boolFlag = true;

/*member: data:Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSInt|powerset={I}], length: null, powerset: {I})*/
List<int> data = [-1, 1];

// -------- List.empty --------

/*member: listEmptyDefault:Container([exact=JSFixedArray|powerset={I}], element: [empty|powerset=empty], length: 0, powerset: {I})*/
get listEmptyDefault => List<int>.empty();

/*member: listEmptyGrowable:Container([exact=JSExtendableArray|powerset={I}], element: [empty|powerset=empty], length: 0, powerset: {I})*/
get listEmptyGrowable => List<int>.empty(growable: true);

/*member: listEmptyFixed:Container([exact=JSFixedArray|powerset={I}], element: [empty|powerset=empty], length: 0, powerset: {I})*/
get listEmptyFixed => List<int>.empty(growable: false);

/*member: listEmptyEither:Container([subclass=JSMutableArray|powerset={I}], element: [empty|powerset=empty], length: 0, powerset: {I})*/
get listEmptyEither => List<int>.empty(growable: boolFlag);

// -------- List.filled --------

/*member: listFilledDefault:Container([exact=JSFixedArray|powerset={I}], element: Value([exact=JSString|powerset={I}], value: "x", powerset: {I}), length: 5, powerset: {I})*/
get listFilledDefault => List.filled(5, 'x');

/*member: listFilledGrowable:Container([exact=JSExtendableArray|powerset={I}], element: Value([exact=JSString|powerset={I}], value: "g", powerset: {I}), length: 5, powerset: {I})*/
get listFilledGrowable => List.filled(5, 'g', growable: true);

/*member: listFilledFixed:Container([exact=JSFixedArray|powerset={I}], element: Value([exact=JSString|powerset={I}], value: "f", powerset: {I}), length: 5, powerset: {I})*/
get listFilledFixed => List.filled(5, 'f', growable: false);

/*member: listFilledEither:Container([subclass=JSMutableArray|powerset={I}], element: Value([exact=JSString|powerset={I}], value: "e", powerset: {I}), length: 5, powerset: {I})*/
get listFilledEither => List.filled(5, 'e', growable: boolFlag);

// -------- List.generate --------

/*member: listGenerateDefault:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/
get listGenerateDefault =>
    List. /*update: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/ generate(
      8,
      (i) => 'x$i',
    );

/*member: listGenerateGrowable:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/
get listGenerateGrowable =>
    List. /*update: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/ generate(
      8,
      (i) => 'g$i',
      growable: true,
    );

/*member: listGenerateFixed:Container([exact=JSFixedArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/
get listGenerateFixed =>
    List. /*update: Container([exact=JSFixedArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/ generate(
      8,
      (i) => 'f$i',
      growable: false,
    );

/*member: listGenerateEither:Container([subclass=JSMutableArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/
get listGenerateEither => List.generate(
  8,
  /*[exact=JSString|powerset={I}]*/ (
    /*[subclass=JSPositiveInt|powerset={I}]*/ i,
  ) => 'e$i',
  growable: boolFlag,
);

/*member: listGenerateBigClosure:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSString|powerset={I}], length: 8, powerset: {I})*/
get listGenerateBigClosure => List.generate(
  8,
  /*[exact=JSString|powerset={I}]*/ (
    /*[subclass=JSPositiveInt|powerset={I}]*/ i,
  ) {
    if (i /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ == 1) return 'one';
    if (i /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ == 2) return 'two';
    return '$i';
  },
);

// -------- List.of --------

/*member: listOfDefault:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listOfDefault => List.of(data);

/*member: listOfGrowable:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listOfGrowable => List.of(data, growable: true);

/*member: listOfFixed:Container([exact=JSFixedArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listOfFixed => List.of(data, growable: false);

/*member: listOfEither:Container([subclass=JSMutableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listOfEither => List.of(data, growable: boolFlag);

// -------- List.from --------

/*member: listFromDefault:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listFromDefault => List.from(data);

/*member: listFromGrowable:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listFromGrowable => List.from(data, growable: true);

/*member: listFromFixed:Container([exact=JSFixedArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listFromFixed => List.from(data, growable: false);

/*member: listFromEither:Container([subclass=JSMutableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
get listFromEither => List.from(data, growable: boolFlag);

// -------- List.unmodifiable --------

/*member: listUnmodifiable:[exact=JSUnmodifiableArray|powerset={I}]*/
get listUnmodifiable => List.unmodifiable(data);
