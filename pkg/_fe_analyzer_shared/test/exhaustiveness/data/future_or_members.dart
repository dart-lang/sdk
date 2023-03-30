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
    Typedef(
      :var hashCode
    ) /*cfe.space=FutureOr<dynamic>?(hashCode: int)*/ /*analyzer.space=FutureOr<dynamic>(hashCode: int)*/ =>
      hashCode,
    Typedef(
      :var runtimeType
    ) /*cfe.
     error=unreachable,
     space=FutureOr<dynamic>?(runtimeType: Type)
    */ /*analyzer.
     error=unreachable,
     space=FutureOr<dynamic>(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*cfe.
     error=unreachable,
     space=FutureOr<dynamic>?(toString: String Function())
    */ /*analyzer.
     error=unreachable,
     space=FutureOr<dynamic>(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*cfe.
     error=unreachable,
     space=FutureOr<dynamic>?(noSuchMethod: dynamic Function(Invocation))
    */ /*analyzer.
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
   checkingOrder={FutureOr<dynamic>?,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>?
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      :int hashCode
    ) /*cfe.space=FutureOr<dynamic>?(hashCode: int)*/ /*analyzer.space=FutureOr<dynamic>(hashCode: int)*/ =>
      hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>?,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={runtimeType:Type},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>?
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={runtimeType:Type},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      :Type runtimeType
    ) /*cfe.space=FutureOr<dynamic>?(runtimeType: Type)*/ /*analyzer.space=FutureOr<dynamic>(runtimeType: Type)*/ =>
      runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>?,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={toString:String Function()},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>?
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
    ) /*cfe.space=FutureOr<dynamic>?(toString: String Function())*/ /*analyzer.space=FutureOr<dynamic>(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>?,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>?
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
    ) /*cfe.space=FutureOr<dynamic>?(noSuchMethod: dynamic Function(Invocation))*/ /*analyzer.space=FutureOr<dynamic>(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>?,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Null(hashCode: int()),
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>?
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Future<dynamic>(hashCode: int()),
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      hashCode: 5
    ) /*cfe.space=FutureOr<dynamic>?(hashCode: 5)*/ /*analyzer.space=FutureOr<dynamic>(hashCode: 5)*/ =>
      5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>?,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Null(noSuchMethod: dynamic Function(Invocation) _),
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>?
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   error=non-exhaustive:Future<dynamic>(noSuchMethod: dynamic Function(Invocation) _),
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*cfe.space=FutureOr<dynamic>?(noSuchMethod: int Function(Invocation))*/ /*analyzer.space=FutureOr<dynamic>(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*cfe.
   checkingOrder={FutureOr<dynamic>?,FutureOr<dynamic>,Null,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={FutureOr<dynamic>,Null},
   type=FutureOr<dynamic>?
  */ /*analyzer.
   checkingOrder={FutureOr<dynamic>,Object?,Future<dynamic>,Object,Null},
   expandedSubtypes={Object,Null,Future<dynamic>},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object?,Future<dynamic>},
   type=FutureOr<dynamic>
  */
      switch (o) {
    Typedef(
      :var hashCode
    ) /*cfe.space=FutureOr<dynamic>?(hashCode: int)*/ /*analyzer.space=FutureOr<dynamic>(hashCode: int)*/ =>
      hashCode,
    Typedef(
      :var runtimeType
    ) /*cfe.
     error=unreachable,
     space=FutureOr<dynamic>?(runtimeType: Type)
    */ /*analyzer.
     error=unreachable,
     space=FutureOr<dynamic>(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*cfe.
     error=unreachable,
     space=FutureOr<dynamic>?(toString: String Function())
    */ /*analyzer.
     error=unreachable,
     space=FutureOr<dynamic>(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*cfe.
     error=unreachable,
     space=FutureOr<dynamic>?(noSuchMethod: dynamic Function(Invocation))
    */ /*analyzer.
     error=unreachable,
     space=FutureOr<dynamic>(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
  };
}
