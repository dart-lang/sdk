// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Work-around for `<pattern>?` vs `<type>?` conflict which favors the former.
typedef Nullable<T> = T?;

exhaustiveNonNullableTypeVariable<T extends Object>(
        int?
            o) => /*
 checkingOrder={int?,int,Null},
 subtypes={int,Null},
 type=int?
*/
    switch (o) {
      int() as T /*space=int?*/ => 0,
    };

nonExhaustiveNullableTypeVariable<T>(
        int?
            o) => /*
 checkingOrder={int?,int,Null},
 error=non-exhaustive:null,
 subtypes={int,Null},
 type=int?
*/
    switch (o) {
      int() as T /*space=int*/ => 0,
    };

exhaustiveNonNullableType(
        int?
            o) => /*
 checkingOrder={int?,int,Null},
 subtypes={int,Null},
 type=int?
*/
    switch (o) {
      int() as int /*space=int?*/ => 0,
    };

exhaustiveNonNullableSuperType(
        int?
            o) => /*
 checkingOrder={int?,int,Null},
 subtypes={int,Null},
 type=int?
*/
    switch (o) {
      int() as num /*space=int?*/ => 0,
    };

nonExhaustiveNonNullableType(
        int?
            o) => /*
 checkingOrder={int?,int,Null},
 error=non-exhaustive:null,
 subtypes={int,Null},
 type=int?
*/
    switch (o) {
      int() as Nullable<int> /*space=int*/ => 0,
    };

exhaustiveNonNullableFutureOr1(
        FutureOr<int>?
            o) => /*
 checkingOrder={FutureOr<int>?,FutureOr<int>,Null,int,Future<int>},
 expandedSubtypes={int,Future<int>,Null},
 subtypes={FutureOr<int>,Null},
 type=FutureOr<int>?
*/
    switch (o) {
      FutureOr<int>() as FutureOr<int> /*space=FutureOr<int>?*/ => 0,
    };

exhaustiveNonNullableFutureOr2(
        FutureOr<int?>
            o) => /*
 checkingOrder={FutureOr<int?>,int?,Future<int?>,int,Null},
 expandedSubtypes={int,Null,Future<int?>},
 subtypes={int?,Future<int?>},
 type=FutureOr<int?>
*/
    switch (o) {
      FutureOr<int>() as FutureOr<int> /*space=FutureOr<int?>*/ => 0,
    };

nonExhaustiveNonNullableFutureOr1(
        FutureOr<int>?
            o) => /*
 checkingOrder={FutureOr<int>?,FutureOr<int>,Null,int,Future<int>},
 error=non-exhaustive:null,
 expandedSubtypes={int,Future<int>,Null},
 subtypes={FutureOr<int>,Null},
 type=FutureOr<int>?
*/
    switch (o) {
      FutureOr<int>() as Nullable<FutureOr<int>> /*space=FutureOr<int>*/ => 0,
    };

nonExhaustiveNonNullableFutureOr2(
        FutureOr<int?>
            o) => /*
             checkingOrder={FutureOr<int?>,int?,Future<int?>,int,Null},
             error=non-exhaustive:Future<int?>();null,
             expandedSubtypes={int,Null,Future<int?>},
             subtypes={int?,Future<int?>},
             type=FutureOr<int?>
            */
    switch (o) {
      FutureOr<int>() as FutureOr<int?> /*space=FutureOr<int>*/ => 0,
    };

exhaustiveNonNullableFutureOrTypeVariable1<T extends Object>(
        FutureOr<T>?
            o) => /*
 checkingOrder={FutureOr<T>?,FutureOr<T>,Null,Object,Future<T>},
 expandedSubtypes={Object,Future<T>,Null},
 subtypes={FutureOr<T>,Null},
 type=FutureOr<T>?
*/
    switch (o) {
      FutureOr<T>() as FutureOr<T> /*space=FutureOr<T>?*/ => 0,
    };

exhaustiveNonNullableFutureOrTypeVariable2<T extends Object>(
        FutureOr<T?>
            o) => /*
 checkingOrder={FutureOr<T?>,Object?,Future<T?>,Object,Null},
 expandedSubtypes={Object,Null,Future<T?>},
 subtypes={Object?,Future<T?>},
 type=FutureOr<T?>
*/
    switch (o) {
      FutureOr<T>() as FutureOr<T> /*space=FutureOr<T?>*/ => 0,
    };

nonExhaustiveNonNullableFutureOrTypeVariable1<T extends Object>(
        FutureOr<T>?
            o) => /*
 checkingOrder={FutureOr<T>?,FutureOr<T>,Null,Object,Future<T>},
 error=non-exhaustive:null,
 expandedSubtypes={Object,Future<T>,Null},
 subtypes={FutureOr<T>,Null},
 type=FutureOr<T>?
*/
    switch (o) {
      FutureOr<T>() as Nullable<FutureOr<T>> /*space=FutureOr<T>*/ => 0,
    };

nonExhaustiveNonNullableFutureOrTypeVariable2<T extends Object>(
        FutureOr<T?>
            o) => /*
             checkingOrder={FutureOr<T?>,Object?,Future<T?>,Object,Null},
             error=non-exhaustive:Future<T?>();null,
             expandedSubtypes={Object,Null,Future<T?>},
             subtypes={Object?,Future<T?>},
             type=FutureOr<T?>
            */
    switch (o) {
      FutureOr<T>() as FutureOr<T?> /*space=FutureOr<T>*/ => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable1<T>(
        FutureOr<T>?
            o) => /*
 checkingOrder={FutureOr<T>?,FutureOr<T>,Null,Object?,Future<T>,Object,Null},
 expandedSubtypes={Object,Null,Future<T>,Null},
 subtypes={FutureOr<T>,Null},
 type=FutureOr<T>?
*/
    switch (o) {
      FutureOr<T>() as FutureOr<T> /*space=FutureOr<T>?*/ => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable2<T>(
        FutureOr<T?>
            o) => /*
 checkingOrder={FutureOr<T?>,Object?,Future<T?>,Object,Null},
 expandedSubtypes={Object,Null,Future<T?>},
 subtypes={Object?,Future<T?>},
 type=FutureOr<T?>
*/
    switch (o) {
      FutureOr<T>() as FutureOr<T> /*space=FutureOr<T?>*/ => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable3<T>(
        FutureOr<T>?
            o) => /*
 checkingOrder={FutureOr<T>?,FutureOr<T>,Null,Object?,Future<T>,Object,Null},
 error=non-exhaustive:null,
 expandedSubtypes={Object,Null,Future<T>,Null},
 subtypes={FutureOr<T>,Null},
 type=FutureOr<T>?
*/
    switch (o) {
      FutureOr<T>() as Nullable<FutureOr<T>> /*space=FutureOr<T>*/ => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable4<T>(
        FutureOr<T?>
            o) => /*
             checkingOrder={FutureOr<T?>,Object?,Future<T?>,Object,Null},
             error=non-exhaustive:Future<T?>();null,
             expandedSubtypes={Object,Null,Future<T?>},
             subtypes={Object?,Future<T?>},
             type=FutureOr<T?>
            */
    switch (o) {
      FutureOr<T>() as FutureOr<T?> /*space=FutureOr<T>*/ => 0,
    };
