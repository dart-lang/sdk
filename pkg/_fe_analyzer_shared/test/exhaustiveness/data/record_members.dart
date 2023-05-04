// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = (int, String);

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    Typedef(:var hashCode) /*space=(int, String)(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=(int, String)(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=(int, String)(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=(int, String)(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*
   fields={hashCode:int},
   type=(int, String)
  */
      switch (o) {
    Typedef(:int hashCode) /*space=(int, String)(hashCode: int)*/ => hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*
   fields={runtimeType:Type},
   type=(int, String)
  */
      switch (o) {
    Typedef(:Type runtimeType) /*space=(int, String)(runtimeType: Type)*/ =>
      runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*
   fields={toString:String Function()},
   type=(int, String)
  */
      switch (o) {
    Typedef(
      :String Function() toString
    ) /*space=(int, String)(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=(int, String)
  */
      switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod
    ) /*space=(int, String)(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*
   error=non-exhaustive:(_, _) && Object(hashCode: int())/(_, _),
   fields={hashCode:int},
   type=(int, String)
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=(int, String)(hashCode: 5)*/ => 5,
  };
}

exhaustiveRestrictedValue(Typedef o) {
  return /*
   fields={$1:int,$2:String,hashCode:int},
   type=(int, String)
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=(int, String)(hashCode: 5)*/ => 5,
    (_, _) && Object(hashCode: int()) /*space=(int, String)(hashCode: int)*/ =>
      0,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*
   fields={$1:int,$2:String,noSuchMethod:dynamic Function(Invocation)},
   type=(int, String)
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=(int, String)(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
    (_, _) &&
          Object(
            noSuchMethod: dynamic Function(Invocation) _
          ) /*space=(int, String)(noSuchMethod: dynamic Function(Invocation))*/ =>
      null,
  };
}

exhaustiveRestrictedType(Typedef o) {
  return /*
   fields={$1:int,$2:String,noSuchMethod:dynamic Function(Invocation)},
   type=(int, String)
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=(int, String)(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
    (_, _) &&
          Object(
            noSuchMethod: dynamic Function(Invocation) _
          ) /*space=(int, String)(noSuchMethod: dynamic Function(Invocation))*/ =>
      null,
  };
}

unreachableMethod(Typedef o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=(int, String)
  */
      switch (o) {
    Typedef(:var hashCode) /*space=(int, String)(hashCode: int)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=(int, String)(runtimeType: Type)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=(int, String)(toString: String Function())
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=(int, String)(noSuchMethod: dynamic Function(Invocation))
    */
      =>
      noSuchMethod,
  };
}
