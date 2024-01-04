// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

exhaustiveDynamicAsStringOrInt(
        o) => /*
         checkingOrder={Object?,Object,Null},
         subtypes={Object,Null},
         type=Object?
        */
    switch (o) {
      final String value /*space=String*/ => value,
      final value as int /*space=()*/ => '$value',
    };

exhaustiveDynamicAsStringOrIntAnd(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      final String value /*space=String*/ => value,
      (final value && final value2) as int /*space=()*/ => '$value$value2',
    };

exhaustiveDynamicAsStringOrNum(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      final String value /*space=String*/ => value,
      final num value as int /*space=()*/ => '$value',
    };

nonExhaustiveDynamicAsStringOrDouble(
        o) => /*
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      final String value /*space=String*/ => value,
      final double value as num /*space=double?*/ => '$value',
    };

exhaustiveDynamicAsStringOrIntUnrestricted(
        o) => /*
         checkingOrder={Object?,Object,Null},
         subtypes={Object,Null},
         type=Object?
        */
    switch (o) {
      final String value /*space=String*/ => value,
      int(:bool isEven) as int /*space=()*/ => '$isEven',
    };

nonExhaustiveDynamicAsStringOrIntRestricted(
        o) => /*
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 fields={isEven:-},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      final String value /*space=String*/ => value,
      int(isEven: true) as int /*space=int(isEven: true)|Null*/ => '',
    };

sealed class M {}

class A extends M {}

class B extends M {}

class C extends M {}

exhaustiveMAsM(
        M m) => /*
 checkingOrder={M,A,B,C},
 subtypes={A,B,C},
 type=M
*/
    switch (m) {
      (A() || B() || C()) as M /*space=M?*/ => 0,
    };

exhaustiveDynamicAsM(
        dynamic
            m) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (m) {
      (A() || B() || C()) as M /*space=()*/ => 0,
    };

exhaustiveDynamicAsMUnrestricted(
        dynamic
            m) => /*
             checkingOrder={Object?,Object,Null},
             subtypes={Object,Null},
             type=Object?
            */
    switch (m) {
      (A() || B() || C(hashCode: int())) as M /*space=()*/ => 0,
    };

nonExhaustiveDynamicAsMRestricted(
        dynamic
            m) => /*
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 fields={hashCode:int},
 subtypes={Object,Null},
 type=Object?
*/
    switch (m) {
      (A() || B() || C(hashCode: 5)) as M /*space=A|B|C(hashCode: 5)|Null*/ =>
        0,
    };

exhaustiveDynamicAsMSeeminglyRestricted(
        dynamic
            m) => /*
     checkingOrder={Object?,Object,Null},
     subtypes={Object,Null},
     type=Object?
    */
    switch (m) {
      (A() || B() || C(hashCode: 5)) as A /*space=()*/ => 0,
    };

exhaustiveList(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      [_] /*space=<[()]>*/ => 1,
      [...] as List /*space=()*/ => 0,
    };

nonExhaustiveList(
        o) => /*
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      [] as List /*space=<[]?>*/ => 0,
    };
