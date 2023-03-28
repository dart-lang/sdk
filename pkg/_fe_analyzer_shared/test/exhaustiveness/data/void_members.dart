// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = void;

membersMethod(o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:var hashCode) /*cfe.space=void?(hashCode: int)*//*analyzer.space=void(hashCode: int)*/=> hashCode,
    Typedef(:var runtimeType) /*cfe.
     error=unreachable,
     space=void?(runtimeType: Type)
    *//*analyzer.
     error=unreachable,
     space=void(runtimeType: Type)
    */=> runtimeType,
    Typedef(:var toString) /*cfe.
     error=unreachable,
     space=void?(toString: String Function())
    *//*analyzer.
     error=unreachable,
     space=void(toString: String Function())
    */=> toString(),
    Typedef(:var noSuchMethod) /*cfe.
     error=unreachable,
     space=void?(noSuchMethod: dynamic Function(Invocation))
    *//*analyzer.
     error=unreachable,
     space=void(noSuchMethod: dynamic Function(Invocation))
    */=> noSuchMethod,
    _ /*space=()*/=> null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*cfe.
   fields={hashCode:int},
   subtypes={void,Null},
   type=void?
  *//*analyzer.
   fields={hashCode:int},
   type=void
  */switch (o) {
    Typedef(:int hashCode) /*cfe.space=void?(hashCode: int)*//*analyzer.space=void(hashCode: int)*/=> hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*cfe.
   fields={runtimeType:Type},
   subtypes={void,Null},
   type=void?
  *//*analyzer.
   fields={runtimeType:Type},
   type=void
  */switch (o) {
    Typedef(:Type runtimeType) /*cfe.space=void?(runtimeType: Type)*//*analyzer.space=void(runtimeType: Type)*/=> runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*cfe.
   fields={toString:String Function()},
   subtypes={void,Null},
   type=void?
  *//*analyzer.
   fields={toString:String Function()},
   type=void
  */switch (o) {
    Typedef(:String Function() toString) /*cfe.space=void?(toString: String Function())*//*analyzer.space=void(toString: String Function())*/=> toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*cfe.
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={void,Null},
   type=void?
  *//*analyzer.
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void
  */switch (o) {
    Typedef(:dynamic Function(Invocation) noSuchMethod) /*cfe.space=void?(noSuchMethod: dynamic Function(Invocation))*//*analyzer.space=void(noSuchMethod: dynamic Function(Invocation))*/=> noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*cfe.
   error=non-exhaustive:void(hashCode: int()),
   fields={hashCode:int},
   subtypes={void,Null},
   type=void?
  *//*analyzer.
   error=non-exhaustive:void(hashCode: int()),
   fields={hashCode:int},
   type=void
  */switch (o) {
    Typedef(hashCode: 5) /*cfe.space=void?(hashCode: 5)*//*analyzer.space=void(hashCode: 5)*/=> 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*cfe.
   error=non-exhaustive:void(noSuchMethod: dynamic Function(Invocation) _),
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={void,Null},
   type=void?
  *//*analyzer.
   error=non-exhaustive:void(noSuchMethod: dynamic Function(Invocation) _),
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void
  */switch (o) {
    Typedef(:int Function(Invocation) noSuchMethod) /*cfe.space=void?(noSuchMethod: int Function(Invocation))*//*analyzer.space=void(noSuchMethod: int Function(Invocation))*/=> noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*cfe.
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={void,Null},
   type=void?
  *//*analyzer.
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=void
  */switch (o) {
    Typedef(:var hashCode) /*cfe.space=void?(hashCode: int)*//*analyzer.space=void(hashCode: int)*/=> hashCode,
    Typedef(:var runtimeType) /*cfe.
     error=unreachable,
     space=void?(runtimeType: Type)
    *//*analyzer.
     error=unreachable,
     space=void(runtimeType: Type)
    */=> runtimeType,
    Typedef(:var toString) /*cfe.
     error=unreachable,
     space=void?(toString: String Function())
    *//*analyzer.
     error=unreachable,
     space=void(toString: String Function())
    */=> toString(),
    Typedef(:var noSuchMethod) /*cfe.
     error=unreachable,
     space=void?(noSuchMethod: dynamic Function(Invocation))
    *//*analyzer.
     error=unreachable,
     space=void(noSuchMethod: dynamic Function(Invocation))
    */=> noSuchMethod,
  };
}
