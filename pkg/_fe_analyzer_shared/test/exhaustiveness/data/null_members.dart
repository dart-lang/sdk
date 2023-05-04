// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = Null;

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    Typedef(:var hashCode) /*space=Null(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=Null(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=Null(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=Null(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*
   fields={hashCode:int},
   type=Null
  */
      switch (o) {
    Typedef(:int hashCode) /*space=Null(hashCode: int)*/ => hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*
   fields={runtimeType:Type},
   type=Null
  */
      switch (o) {
    Typedef(:Type runtimeType) /*space=Null(runtimeType: Type)*/ => runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*
   fields={toString:String Function()},
   type=Null
  */
      switch (o) {
    Typedef(
      :String Function() toString
    ) /*space=Null(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=Null
  */
      switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod
    ) /*space=Null(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*
   error=non-exhaustive:Null(hashCode: int())/null,
   fields={hashCode:int},
   type=Null
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=Null(hashCode: 5)*/ => 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*
   error=non-exhaustive:Null(noSuchMethod: dynamic Function(Invocation) _)/null,
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=Null
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=Null(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=Null
  */
      switch (o) {
    Typedef(:var hashCode) /*space=Null(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=Null(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=Null(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=Null(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
  };
}
