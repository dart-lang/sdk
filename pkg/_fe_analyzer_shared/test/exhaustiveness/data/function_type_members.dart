// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = void Function();

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    Typedef(:var hashCode) /*space=void Function()(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=void Function()(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=void Function()(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=void Function()(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*
   fields={hashCode:int},
   type=void Function()
  */
      switch (o) {
    Typedef(:int hashCode) /*space=void Function()(hashCode: int)*/ => hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*
   fields={runtimeType:Type},
   type=void Function()
  */
      switch (o) {
    Typedef(:Type runtimeType) /*space=void Function()(runtimeType: Type)*/ =>
      runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*
   fields={toString:String Function()},
   type=void Function()
  */
      switch (o) {
    Typedef(
      :String Function() toString
    ) /*space=void Function()(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void Function()
  */
      switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod
    ) /*space=void Function()(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*
   error=non-exhaustive:void Function() _ && Object(hashCode: int())/void Function() _,
   fields={hashCode:int},
   type=void Function()
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=void Function()(hashCode: 5)*/ => 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*
   error=non-exhaustive:void Function() _ && Object(noSuchMethod: dynamic Function(Invocation) _)/void Function() _,
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void Function()
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=void Function()(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=void Function()
  */
      switch (o) {
    Typedef(:var hashCode) /*space=void Function()(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=void Function()(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=void Function()(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=void Function()(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
  };
}
