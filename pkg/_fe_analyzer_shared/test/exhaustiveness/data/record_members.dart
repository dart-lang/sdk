// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Typedef = (int, String);

membersMethod(o) {
  return /*
   fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
   subtypes={Object,Null},
   type=Object?
  */switch (o) {
    Typedef(:var hashCode) /*space=($1: int, $2: String)*/=> hashCode,
    Typedef(:var runtimeType) /*space=($1: int, $2: String)*/=> runtimeType,
    Typedef(:var toString) /*space=($1: int, $2: String)*/=> toString(),
    Typedef(:var noSuchMethod) /*space=($1: int, $2: String)*/=> noSuchMethod,
    _ /*space=()*/=> null,
  };
}

exhaustiveHashCode(Typedef o) {
  return /*
   error=non-exhaustive:(hashCode: Object),
   fields={hashCode:-},
   type=(int, String)
  */switch (o) {
    Typedef(:int hashCode) /*space=($1: int, $2: String)*/=> hashCode,
  };
}

exhaustiveRuntimeType(Typedef o) {
  return /*
   error=non-exhaustive:(runtimeType: Object),
   fields={runtimeType:-},
   type=(int, String)
  */switch (o) {
    Typedef(:Type runtimeType) /*space=($1: int, $2: String)*/=> runtimeType,
  };
}

exhaustiveToString(Typedef o) {
  return /*
   error=non-exhaustive:(toString: Object),
   fields={toString:-},
   type=(int, String)
  */switch (o) {
    Typedef(:String Function() toString) /*space=($1: int, $2: String)*/=> toString,
  };
}

exhaustiveNoSuchMethod(Typedef o) {
  return /*
   error=non-exhaustive:(noSuchMethod: Object),
   fields={noSuchMethod:-},
   type=(int, String)
  */switch (o) {
    Typedef(:dynamic Function(Invocation) noSuchMethod) /*space=($1: int, $2: String)*/=> noSuchMethod,
  };
}

nonExhaustiveRestrictedValue(Typedef o) {
  return /*
   error=non-exhaustive:(hashCode: Object),
   fields={hashCode:-},
   type=(int, String)
  */switch (o) {
    Typedef(hashCode: 5) /*space=($1: int, $2: String)*/=> 5,
  };
}

nonExhaustiveRestrictedType(Typedef o) {
  return /*
   error=non-exhaustive:(noSuchMethod: Object),
   fields={noSuchMethod:-},
   type=(int, String)
  */switch (o) {
    Typedef(:int Function(Invocation) noSuchMethod) /*space=($1: int, $2: String)*/=> noSuchMethod,
  };
}

unreachableMethod(Typedef o) {
  return /*
   error=non-exhaustive:(hashCode: Object, noSuchMethod: Object, runtimeType: Object, toString: Object),
   fields={hashCode:-,noSuchMethod:-,runtimeType:-,toString:-},
   type=(int, String)
  */switch (o) {
    Typedef(:var hashCode) /*space=($1: int, $2: String)*/=> hashCode,
    Typedef(:var runtimeType) /*space=($1: int, $2: String)*/=> runtimeType,
    Typedef(:var toString) /*space=($1: int, $2: String)*/=> toString(),
    Typedef(:var noSuchMethod) /*space=($1: int, $2: String)*/=> noSuchMethod,
  };
}
