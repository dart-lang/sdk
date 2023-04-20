// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E { a, b, c }

typedef Typedef = E;

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    Typedef(:var hashCode) /*space=E(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
   error=unreachable,
   space=E(runtimeType: Type)
  */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
   error=unreachable,
   space=E(toString: String Function())
  */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
   error=unreachable,
   space=E(noSuchMethod: dynamic Function(Invocation))
  */
      =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   fields={hashCode:int},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(:int hashCode) /*space=E(hashCode: int)*/ => hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   fields={runtimeType:Type},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(:Type runtimeType) /*space=E(runtimeType: Type)*/ => runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   fields={toString:String Function()},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(
      :String Function() toString
    ) /*space=E(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod
    ) /*space=E(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   error=non-exhaustive:E.a && Object(hashCode: int())/E.a,
   fields={hashCode:int},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=E(hashCode: 5)*/ => 5,
  };
}

exhaustiveRestrictedValue(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   error=non-exhaustive:E.b && Object(hashCode: int())/E.b,
   fields={hashCode:int},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=E(hashCode: 5)*/ => 5,
    E.a && Object(hashCode: int()) /*space=E.a(hashCode: int)*/ => null,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   error=non-exhaustive:E.a && Object(noSuchMethod: dynamic Function(Invocation) _)/E.a,
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=E(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

exhaustiveRestrictedType(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   error=non-exhaustive:E.b && Object(noSuchMethod: dynamic Function(Invocation) _)/E.b,
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=E(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
    E.a &&
          Object(
            noSuchMethod: dynamic Function(Invocation) _
          ) /*space=E.a(noSuchMethod: dynamic Function(Invocation))*/ =>
      null,
  };
}

unreachableMethod(Typedef o) {
  return /*
   checkingOrder={E,E.a,E.b,E.c},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={E.a,E.b,E.c},
   type=E
  */
      switch (o) {
    Typedef(:var hashCode) /*space=E(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
   error=unreachable,
   space=E(runtimeType: Type)
  */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
   error=unreachable,
   space=E(toString: String Function())
  */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
   error=unreachable,
   space=E(noSuchMethod: dynamic Function(Invocation))
  */
      =>
      noSuchMethod,
  };
}
