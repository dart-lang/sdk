// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = Object;

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */ switch (o) {
    Typedef(:var hashCode) /*space=Object(hashCode: int)*/ => hashCode,
    Typedef(:var runtimeType) /*
     error=unreachable,
     space=Object(runtimeType: Type)
    */ =>
      runtimeType,
    Typedef(:var toString) /*
     error=unreachable,
     space=Object(toString: String Function())
    */ =>
      toString(),
    Typedef(:var noSuchMethod) /*
     error=unreachable,
     space=Object(noSuchMethod: dynamic Function(Invocation))
    */ =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*
   fields={hashCode:int},
   type=Object
  */ switch (o) {
    Typedef(:int hashCode) /*space=Object(hashCode: int)*/ => hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*
   fields={runtimeType:Type},
   type=Object
  */ switch (o) {
    Typedef(:Type runtimeType) /*space=Object(runtimeType: Type)*/ =>
      runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*
   fields={toString:String Function()},
   type=Object
  */ switch (o) {
    Typedef(
      :String Function() toString,
    ) /*space=Object(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=Object
  */ switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod,
    ) /*space=Object(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*
   error=non-exhaustive:Object(hashCode: int())/Object(),
   fields={hashCode:int},
   type=Object
  */ switch (o) {
    Typedef(hashCode: 5) /*space=Object(hashCode: 5)*/ => 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*
   error=non-exhaustive:Object(noSuchMethod: dynamic Function(Invocation) _)/Object(),
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=Object
  */ switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod,
    ) /*space=Object(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=Object
  */ switch (o) {
    Typedef(:var hashCode) /*space=Object(hashCode: int)*/ => hashCode,
    Typedef(:var runtimeType) /*
     error=unreachable,
     space=Object(runtimeType: Type)
    */ =>
      runtimeType,
    Typedef(:var toString) /*
     error=unreachable,
     space=Object(toString: String Function())
    */ =>
      toString(),
    Typedef(:var noSuchMethod) /*
     error=unreachable,
     space=Object(noSuchMethod: dynamic Function(Invocation))
    */ =>
      noSuchMethod,
  };
}
