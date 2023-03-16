// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = Void;

membersMethod(o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:var hashCode) /*cfe.space=<invalid>(hashCode: int)*//*analyzer.space=Object?(hashCode: int)*/=> hashCode,
    Typedef(:var runtimeType) /*cfe.
     error=unreachable,
     space=<invalid>(runtimeType: Type)
    *//*analyzer.
     error=unreachable,
     space=Object?(runtimeType: Type)
    */=> runtimeType,
    Typedef(:var toString) /*cfe.
     error=unreachable,
     space=<invalid>(toString: String Function())
    *//*analyzer.
     error=unreachable,
     space=Object?(toString: String Function())
    */=> toString(),
    Typedef(:var noSuchMethod) /*cfe.
     error=unreachable,
     space=<invalid>(noSuchMethod: dynamic Function(Invocation))
    *//*analyzer.
     error=unreachable,
     space=Object?(noSuchMethod: dynamic Function(Invocation))
    */=> noSuchMethod,
    _ /*cfe.space=()*//*analyzer.
     error=unreachable,
     space=()
    */=> null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*cfe.
   fields={hashCode:int},
   type=<invalid>
  *//*analyzer.
   fields={hashCode:int},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:int hashCode) /*cfe.space=<invalid>(hashCode: int)*//*analyzer.space=Object?(hashCode: int)*/=> hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*cfe.
   fields={runtimeType:Type},
   type=<invalid>
  *//*analyzer.
   fields={runtimeType:Type},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:Type runtimeType) /*cfe.space=<invalid>(runtimeType: Type)*//*analyzer.space=Object?(runtimeType: Type)*/=> runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*cfe.
   fields={toString:String Function()},
   type=<invalid>
  *//*analyzer.
   fields={toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:String Function() toString) /*cfe.space=<invalid>(toString: String Function())*//*analyzer.space=Object?(toString: String Function())*/=> toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*cfe.
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=<invalid>
  *//*analyzer.
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:dynamic Function(Invocation) noSuchMethod) /*cfe.space=<invalid>(noSuchMethod: dynamic Function(Invocation))*//*analyzer.space=Object?(noSuchMethod: dynamic Function(Invocation))*/=> noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*cfe.
   error=non-exhaustive:<invalid>(hashCode: int),
   fields={hashCode:int},
   type=<invalid>
  *//*analyzer.
   error=non-exhaustive:Object(hashCode: int),
   fields={hashCode:int},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(hashCode: 5) /*cfe.space=<invalid>(hashCode: 5)*//*analyzer.space=Object?(hashCode: 5)*/=> 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*cfe.
   error=non-exhaustive:<invalid>(noSuchMethod: dynamic Function(Invocation)),
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=<invalid>
  *//*analyzer.
   error=non-exhaustive:Object(noSuchMethod: dynamic Function(Invocation)),
   fields={noSuchMethod:dynamic Function(Invocation)},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:int Function(Invocation) noSuchMethod) /*cfe.space=<invalid>(noSuchMethod: int Function(Invocation))*//*analyzer.space=Object?(noSuchMethod: int Function(Invocation))*/=> noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*cfe.
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=<invalid>
  *//*analyzer.
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:var hashCode) /*cfe.space=<invalid>(hashCode: int)*//*analyzer.space=Object?(hashCode: int)*/=> hashCode,
    Typedef(:var runtimeType) /*cfe.
     error=unreachable,
     space=<invalid>(runtimeType: Type)
    *//*analyzer.
     error=unreachable,
     space=Object?(runtimeType: Type)
    */=> runtimeType,
    Typedef(:var toString) /*cfe.
     error=unreachable,
     space=<invalid>(toString: String Function())
    *//*analyzer.
     error=unreachable,
     space=Object?(toString: String Function())
    */=> toString(),
    Typedef(:var noSuchMethod) /*cfe.
     error=unreachable,
     space=<invalid>(noSuchMethod: dynamic Function(Invocation))
    *//*analyzer.
     error=unreachable,
     space=Object?(noSuchMethod: dynamic Function(Invocation))
    */=> noSuchMethod,
  };
}
