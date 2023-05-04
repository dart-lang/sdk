// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = Never;

membersMethod(o) {
  return /*
   checkingOrder={Object?,Object,Null},
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    Typedef(:var hashCode) /*space=Never(hashCode: ∅)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=Never(runtimeType: ∅)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=Never(toString: ∅)
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=Never(noSuchMethod: ∅)
    */
      =>
      noSuchMethod,
    _ /*space=()*/ => null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*
   fields={hashCode:int},
   type=Never
  */
      switch (o) {
    Typedef(:int hashCode) /*space=Never(hashCode: int)*/ => hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*
   fields={runtimeType:Type},
   type=Never
  */
      switch (o) {
    Typedef(:Type runtimeType) /*space=Never(runtimeType: Type)*/ =>
      runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*
   fields={toString:String Function()},
   type=Never
  */
      switch (o) {
    Typedef(
      :String Function() toString
    ) /*space=Never(toString: String Function())*/ =>
      toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=Never
  */
      switch (o) {
    Typedef(
      :dynamic Function(Invocation) noSuchMethod
    ) /*space=Never(noSuchMethod: dynamic Function(Invocation))*/ =>
      noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*
   fields={hashCode:int},
   type=Never
  */
      switch (o) {
    Typedef(hashCode: 5) /*space=Never(hashCode: 5)*/ => 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=Never
  */
      switch (o) {
    Typedef(
      :int Function(Invocation) noSuchMethod
    ) /*space=Never(noSuchMethod: int Function(Invocation))*/ =>
      noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=Never
  */
      switch (o) {
    Typedef(:var hashCode) /*space=Never(hashCode: ∅)*/ => hashCode,
    Typedef(
      :var runtimeType
    ) /*
     error=unreachable,
     space=Never(runtimeType: ∅)
    */
      =>
      runtimeType,
    Typedef(
      :var toString
    ) /*
     error=unreachable,
     space=Never(toString: ∅)
    */
      =>
      toString(),
    Typedef(
      :var noSuchMethod
    ) /*
     error=unreachable,
     space=Never(noSuchMethod: ∅)
    */
      =>
      noSuchMethod,
  };
}
