// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  boolFlag = !boolFlag;
  data. /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/ add(
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

/*member: boolFlag:[exact=JSBool|powerset={I}{O}{N}]*/
bool boolFlag = true;

/*member: data:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSInt|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/
List<int> data = [-1, 1];

// -------- List.empty --------

/*member: listEmptyDefault:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{F}{M})*/
get listEmptyDefault => List<int>.empty();

/*member: listEmptyGrowable:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{G}{M})*/
get listEmptyGrowable => List<int>.empty(growable: true);

/*member: listEmptyFixed:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{F}{M})*/
get listEmptyFixed => List<int>.empty(growable: false);

/*member: listEmptyEither:Container([subclass=JSMutableArray|powerset={I}{GF}{M}], element: [empty|powerset=empty], length: 0, powerset: {I}{GF}{M})*/
get listEmptyEither => List<int>.empty(growable: boolFlag);

// -------- List.filled --------

/*member: listFilledDefault:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: Value([exact=JSString|powerset={I}{O}{I}], value: "x", powerset: {I}{O}{I}), length: 5, powerset: {I}{F}{M})*/
get listFilledDefault => List.filled(5, 'x');

/*member: listFilledGrowable:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Value([exact=JSString|powerset={I}{O}{I}], value: "g", powerset: {I}{O}{I}), length: 5, powerset: {I}{G}{M})*/
get listFilledGrowable => List.filled(5, 'g', growable: true);

/*member: listFilledFixed:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: Value([exact=JSString|powerset={I}{O}{I}], value: "f", powerset: {I}{O}{I}), length: 5, powerset: {I}{F}{M})*/
get listFilledFixed => List.filled(5, 'f', growable: false);

/*member: listFilledEither:Container([subclass=JSMutableArray|powerset={I}{GF}{M}], element: Value([exact=JSString|powerset={I}{O}{I}], value: "e", powerset: {I}{O}{I}), length: 5, powerset: {I}{GF}{M})*/
get listFilledEither => List.filled(5, 'e', growable: boolFlag);

// -------- List.generate --------

/*member: listGenerateDefault:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{G}{M})*/
get listGenerateDefault =>
    List. /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{G}{M})*/ generate(
      8,
      (i) => 'x$i',
    );

/*member: listGenerateGrowable:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{G}{M})*/
get listGenerateGrowable =>
    List. /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{G}{M})*/ generate(
      8,
      (i) => 'g$i',
      growable: true,
    );

/*member: listGenerateFixed:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{F}{M})*/
get listGenerateFixed =>
    List. /*update: Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{F}{M})*/ generate(
      8,
      (i) => 'f$i',
      growable: false,
    );

/*member: listGenerateEither:Container([subclass=JSMutableArray|powerset={I}{GF}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{GF}{M})*/
get listGenerateEither => List.generate(
  8,
  /*[exact=JSString|powerset={I}{O}{I}]*/ (
    /*[subclass=JSPositiveInt|powerset={I}{O}{N}]*/ i,
  ) => 'e$i',
  growable: boolFlag,
);

/*member: listGenerateBigClosure:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSString|powerset={I}{O}{I}], length: 8, powerset: {I}{G}{M})*/
get listGenerateBigClosure =>
    List.generate(8, /*[exact=JSString|powerset={I}{O}{I}]*/ (
      /*[subclass=JSPositiveInt|powerset={I}{O}{N}]*/ i,
    ) {
      if (i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ == 1)
        return 'one';
      if (i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ == 2)
        return 'two';
      return '$i';
    });

// -------- List.of --------

/*member: listOfDefault:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
get listOfDefault => List.of(data);

/*member: listOfGrowable:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
get listOfGrowable => List.of(data, growable: true);

/*member: listOfFixed:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{F}{M})*/
get listOfFixed => List.of(data, growable: false);

/*member: listOfEither:Container([subclass=JSMutableArray|powerset={I}{GF}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{GF}{M})*/
get listOfEither => List.of(data, growable: boolFlag);

// -------- List.from --------

/*member: listFromDefault:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
get listFromDefault => List.from(data);

/*member: listFromGrowable:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/
get listFromGrowable => List.from(data, growable: true);

/*member: listFromFixed:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{F}{M})*/
get listFromFixed => List.from(data, growable: false);

/*member: listFromEither:Container([subclass=JSMutableArray|powerset={I}{GF}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{GF}{M})*/
get listFromEither => List.from(data, growable: boolFlag);

// -------- List.unmodifiable --------

/*member: listUnmodifiable:[exact=JSUnmodifiableArray|powerset={I}{U}{I}]*/
get listUnmodifiable => List.unmodifiable(data);
