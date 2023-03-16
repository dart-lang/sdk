// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = void Function();

membersMethod(o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:var hashCode) /*space=void Function()(hashCode: int)*/=> hashCode,
    Typedef(:var runtimeType) /*cfe.
     error=unreachable,
     space=void Function()(runtimeType: Type)
    *//*analyzer.space=void Function()(runtimeType: Type)*/=> runtimeType,
    Typedef(:var toString) /*cfe.
     error=unreachable,
     space=void Function()(toString: String Function())
    *//*analyzer.space=void Function()(toString: String Function())*/=> toString(),
    Typedef(:var noSuchMethod) /*cfe.
     error=unreachable,
     space=void Function()(noSuchMethod: dynamic Function(Invocation))
    *//*analyzer.space=void Function()(noSuchMethod: dynamic Function(Invocation))*/=> noSuchMethod,
    _ /*space=()*/=> null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*cfe.
   fields={hashCode:int},
   type=void Function()
  *//*analyzer.
   error=non-exhaustive:void Function()(hashCode: Object),
   fields={hashCode:-},
   type=void Function()
  */switch (o) {
    Typedef(:int hashCode) /*space=void Function()(hashCode: int)*/=> hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*cfe.
   fields={runtimeType:Type},
   type=void Function()
  *//*analyzer.
   error=non-exhaustive:void Function()(runtimeType: Object),
   fields={runtimeType:-},
   type=void Function()
  */switch (o) {
    Typedef(:Type runtimeType) /*space=void Function()(runtimeType: Type)*/=> runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*cfe.
   fields={toString:String Function()},
   type=void Function()
  *//*analyzer.
   error=non-exhaustive:void Function()(toString: Object),
   fields={toString:-},
   type=void Function()
  */switch (o) {
    Typedef(:String Function() toString) /*space=void Function()(toString: String Function())*/=> toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*cfe.
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void Function()
  *//*analyzer.
   error=non-exhaustive:void Function()(noSuchMethod: Object),
   fields={noSuchMethod:-},
   type=void Function()
  */switch (o) {
    Typedef(:dynamic Function(Invocation) noSuchMethod) /*space=void Function()(noSuchMethod: dynamic Function(Invocation))*/=> noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*cfe.
   error=non-exhaustive:void Function()(hashCode: int),
   fields={hashCode:int},
   type=void Function()
  *//*analyzer.
   error=non-exhaustive:void Function()(hashCode: Object),
   fields={hashCode:-},
   type=void Function()
  */switch (o) {
    Typedef(hashCode: 5) /*space=void Function()(hashCode: 5)*/=> 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*cfe.
   error=non-exhaustive:void Function()(noSuchMethod: dynamic Function(Invocation)),
   fields={noSuchMethod:dynamic Function(Invocation)},
   type=void Function()
  *//*analyzer.
   error=non-exhaustive:void Function()(noSuchMethod: Object),
   fields={noSuchMethod:-},
   type=void Function()
  */switch (o) {
    Typedef(:int Function(Invocation) noSuchMethod) /*space=void Function()(noSuchMethod: int Function(Invocation))*/=> noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*cfe.
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   type=void Function()
  *//*analyzer.
   error=non-exhaustive:void Function()(hashCode: Object, noSuchMethod: Object, runtimeType: Object, toString: Object),
   fields={hashCode:-,noSuchMethod:-,runtimeType:-,toString:-},
   type=void Function()
  */switch (o) {
    Typedef(:var hashCode) /*space=void Function()(hashCode: int)*/=> hashCode,
    Typedef(:var runtimeType) /*cfe.
     error=unreachable,
     space=void Function()(runtimeType: Type)
    *//*analyzer.space=void Function()(runtimeType: Type)*/=> runtimeType,
    Typedef(:var toString) /*cfe.
     error=unreachable,
     space=void Function()(toString: String Function())
    *//*analyzer.space=void Function()(toString: String Function())*/=> toString(),
    Typedef(:var noSuchMethod) /*cfe.
     error=unreachable,
     space=void Function()(noSuchMethod: dynamic Function(Invocation))
    *//*analyzer.space=void Function()(noSuchMethod: dynamic Function(Invocation))*/=> noSuchMethod,
  };
}
