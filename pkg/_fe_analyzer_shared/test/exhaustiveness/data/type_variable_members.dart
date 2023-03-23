// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<Typedef> {
  membersMethod(o) {
    return /*
     fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
     subtypes={Object,Null},
     type=Object?
    */switch (o) {
      Typedef(:var hashCode) /*cfe.space=(Typedef & Object)(hashCode: int)*//*analyzer.space=Typedef & Object(hashCode: int)*/=> hashCode,
      Typedef(:var runtimeType) /*cfe.
       error=unreachable,
       space=(Typedef & Object)(runtimeType: Type)
      *//*analyzer.
       error=unreachable,
       space=Typedef & Object(runtimeType: Type)
      */=> runtimeType,
      Typedef(:var toString) /*cfe.
       error=unreachable,
       space=(Typedef & Object)(toString: String Function())
      *//*analyzer.
       error=unreachable,
       space=Typedef & Object(toString: String Function())
      */=> toString(),
      Typedef(:var noSuchMethod) /*cfe.
       error=unreachable,
       space=(Typedef & Object)(noSuchMethod: dynamic Function(Invocation))
      *//*analyzer.
       error=unreachable,
       space=Typedef & Object(noSuchMethod: dynamic Function(Invocation))
      */=> noSuchMethod,
      _ /*space=()*/=> null,
    };
  }

  exhaustiveHashCode(Typedef o) {
    return /*cfe.
     fields={hashCode:int},
     type=(Typedef & Object)
    *//*analyzer.
     fields={hashCode:int},
     type=Typedef & Object
    */switch (o) {
      Typedef(:int hashCode) /*cfe.space=(Typedef & Object)(hashCode: int)*//*analyzer.space=Typedef & Object(hashCode: int)*/=> hashCode,
    };
  }

  exhaustiveRuntimeType(Typedef o) {
    return /*cfe.
     fields={runtimeType:Type},
     type=(Typedef & Object)
    *//*analyzer.
     fields={runtimeType:Type},
     type=Typedef & Object
    */switch (o) {
      Typedef(:Type runtimeType) /*cfe.space=(Typedef & Object)(runtimeType: Type)*//*analyzer.space=Typedef & Object(runtimeType: Type)*/=> runtimeType,
    };
  }

  exhaustiveToString(Typedef o) {
    return /*cfe.
     fields={toString:String Function()},
     type=(Typedef & Object)
    *//*analyzer.
     fields={toString:String Function()},
     type=Typedef & Object
    */switch (o) {
      Typedef(:String Function() toString) /*cfe.space=(Typedef & Object)(toString: String Function())*//*analyzer.space=Typedef & Object(toString: String Function())*/=> toString,
    };
  }

  exhaustiveNoSuchMethod(Typedef o) {
    return /*cfe.
     fields={noSuchMethod:dynamic Function(Invocation)},
     type=(Typedef & Object)
    *//*analyzer.
     fields={noSuchMethod:dynamic Function(Invocation)},
     type=Typedef & Object
    */switch (o) {
      Typedef(:dynamic Function(Invocation) noSuchMethod) /*cfe.space=(Typedef & Object)(noSuchMethod: dynamic Function(Invocation))*//*analyzer.space=Typedef & Object(noSuchMethod: dynamic Function(Invocation))*/=> noSuchMethod,
    };
  }

  nonExhaustiveRestrictedValue(Typedef o) {
    return /*cfe.
     error=non-exhaustive:(Typedef & Object) _ && Object(hashCode: int()),
     fields={hashCode:int},
     type=(Typedef & Object)
    *//*analyzer.
     error=non-exhaustive:Typedef & Object(hashCode: int()),
     fields={hashCode:int},
     type=Typedef & Object
    */switch (o) {
      Typedef(hashCode: 5) /*cfe.space=(Typedef & Object)(hashCode: 5)*//*analyzer.space=Typedef & Object(hashCode: 5)*/=> 5,
    };
  }

  nonExhaustiveRestrictedType(Typedef o) {
    return /*cfe.
     error=non-exhaustive:(Typedef & Object) _ && Object(noSuchMethod: dynamic Function(Invocation) _),
     fields={noSuchMethod:dynamic Function(Invocation)},
     type=(Typedef & Object)
    *//*analyzer.
     error=non-exhaustive:Typedef & Object(noSuchMethod: dynamic Function(Invocation) _),
     fields={noSuchMethod:dynamic Function(Invocation)},
     type=Typedef & Object
    */switch (o) {
      Typedef(:int Function(Invocation) noSuchMethod) /*cfe.space=(Typedef & Object)(noSuchMethod: int Function(Invocation))*//*analyzer.space=Typedef & Object(noSuchMethod: int Function(Invocation))*/=> noSuchMethod,
    };
  }

  unreachableMethod(Typedef o) {
    return /*cfe.
     fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
     type=(Typedef & Object)
    *//*analyzer.
     fields={hashCode:int,noSuchMethod:dynamic Function(Invocation),runtimeType:Type,toString:String Function()},
     type=Typedef & Object
    */switch (o) {
      Typedef(:var hashCode) /*cfe.space=(Typedef & Object)(hashCode: int)*//*analyzer.space=Typedef & Object(hashCode: int)*/=> hashCode,
      Typedef(:var runtimeType) /*cfe.
       error=unreachable,
       space=(Typedef & Object)(runtimeType: Type)
      *//*analyzer.
       error=unreachable,
       space=Typedef & Object(runtimeType: Type)
      */=> runtimeType,
      Typedef(:var toString) /*cfe.
       error=unreachable,
       space=(Typedef & Object)(toString: String Function())
      *//*analyzer.
       error=unreachable,
       space=Typedef & Object(toString: String Function())
      */=> toString(),
      Typedef(:var noSuchMethod) /*cfe.
       error=unreachable,
       space=(Typedef & Object)(noSuchMethod: dynamic Function(Invocation))
      *//*analyzer.
       error=unreachable,
       space=Typedef & Object(noSuchMethod: dynamic Function(Invocation))
      */=> noSuchMethod,
    };
  }
}