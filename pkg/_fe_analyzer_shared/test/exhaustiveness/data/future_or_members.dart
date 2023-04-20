// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

typedef Typedef = FutureOr;

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    Typedef(:var hashCode) /*space=FutureOr<dynamic>(hashCode: int)*/ =>
      hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=FutureOr<dynamic>(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=FutureOr<dynamic>(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=FutureOr<dynamic>(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(:int hashCode) /*space=FutureOr<dynamic>(hashCode: int)*/ =>
      hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={runtimeType:Type},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={runtimeType:Type},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(:Type runtimeType) /*space=FutureOr<dynamic>(runtimeType: Type)*/ =>
      runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={toString:String Function()},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={toString:String Function()},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      :String Function() toString
    ) /*space=FutureOr<dynamic>(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod
    ) /*space=FutureOr<dynamic>(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Null(hashCode: int())/null,
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Future<dynamic>(hashCode: int())/Future<dynamic>(),
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=FutureOr<dynamic>(hashCode: 5)*/ => 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Null(noSuchMethod: dynamic Function(Invocation) _)/null,
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Future<dynamic>(noSuchMethod: dynamic Function(Invocation) _)/Future<dynamic>(),
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=FutureOr<dynamic>(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(:var hashCode) /*space=FutureOr<dynamic>(hashCode: int)*/ =>
      hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=FutureOr<dynamic>(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=FutureOr<dynamic>(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=FutureOr<dynamic>(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
  };
}
