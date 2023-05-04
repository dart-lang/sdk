// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = void;

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    Typedef(:var hashCode) /*space=void(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=void(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=void(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=void(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*cfe.
   checkingOrder={void,void,Null},
   fields={hashCode:int},
   subtypes={void,Null},
   type=void
  */ /*analyzer.
   fields={hashCode:int},
   type=void
  */
      switch (o) {
    Typedef(:int hashCode) /*space=void(hashCode: int)*/ => hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*cfe.
   checkingOrder={void,void,Null},
   fields={runtimeType:Type},
   subtypes={void,Null},
   type=void
  */ /*analyzer.
   fields={runtimeType:Type},
   type=void
  */
      switch (o) {
    Typedef(:Type runtimeType) /*space=void(runtimeType: Type)*/ => runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*cfe.
   checkingOrder={void,void,Null},
   fields={toString:String Function()},
   subtypes={void,Null},
   type=void
  */ /*analyzer.
   fields={toString:String Function()},
   type=void
  */
      switch (o) {
    Typedef(
      :String Function() toString
    ) /*space=void(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*cfe.
   checkingOrder={void,void,Null},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={void,Null},
   type=void
  */ /*analyzer.
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void
  */
      switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod
    ) /*space=void(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*cfe.
   checkingOrder={void,void,Null},
   error=non-exhaustive:void(hashCode: int())/void(),
   fields={hashCode:int},
   subtypes={void,Null},
   type=void
  */ /*analyzer.
   error=non-exhaustive:void(hashCode: int())/void(),
   fields={hashCode:int},
   type=void
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=void(hashCode: 5)*/ => 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*cfe.
   checkingOrder={void,void,Null},
   error=non-exhaustive:void(noSuchMethod: dynamic Function(Invocation) _)/void(),
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={void,Null},
   type=void
  */ /*analyzer.
   error=non-exhaustive:void(noSuchMethod: dynamic Function(Invocation) _)/void(),
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=void(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*cfe.
   checkingOrder={void,void,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={void,Null},
   type=void
  */ /*analyzer.
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=void
  */
      switch (o) {
    Typedef(:var hashCode) /*space=void(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=void(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=void(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=void(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
  };
}
