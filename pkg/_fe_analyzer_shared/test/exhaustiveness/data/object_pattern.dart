// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum {a, b}

sealed class A {
  final Enum a;
  bool get b;
  A(this.a);
}

class B extends A {
  final bool b;
  B(super.a, this.b);
}

void exhaustiveSwitch1(A r) {
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={B},
   type=A
  */switch (r) {
    /*
     remaining=A,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true),
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|B(a: Enum, b: true),
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: true),
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void exhaustiveSwitch2(A r) {
      /*
       fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
       remaining=∅,
       subtypes={B},
       type=A
      */switch (r) {
    /*
     remaining=A,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true),
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(b: true, a: Enum.b),
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: true),
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1(A r) {
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   remaining=B(a: Enum.b, b: false),
   subtypes={B},
   type=A
  */switch (r) {
    /*
     remaining=A,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true),
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(b: true, a: Enum.b),
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2(A r) {
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   remaining=B(a: Enum.a, b: false),
   subtypes={B},
   type=A
  */switch (r) {
    /*
     remaining=A,
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.a, b: bool)|B(a: Enum, b: true),
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.a, b: false)|B(b: true, a: Enum.b),
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A r) {
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true),
   subtypes={B},
   type=A
  */switch (r) {
    /*
     remaining=A,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? r) {
  /*
   fields={},
   remaining=∅,
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*
     remaining=A?,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true)|Null,
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|B(a: Enum, b: true)|Null,
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|Null,
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*
     remaining=Null,
     space=Null
    */case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? r) {
  /*
   fields={},
   remaining=Null,
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*
     remaining=A?,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true)|Null,
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|B(a: Enum, b: true)|Null,
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|Null,
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? r) {
  /*
   fields={},
   remaining=B(a: Enum.b, b: false),
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*
     remaining=A?,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true)|Null,
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(b: true, a: Enum.b)|Null,
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: false)|Null,
     space=Null
    */case null:
      print('null');
      break;
  }
}

void unreachableCase1(A r) {
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={B},
   type=A
  */switch (r) {
    /*
     remaining=A,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false) #1');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true),
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|B(a: Enum, b: true),
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: true),
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*
     remaining=∅,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2(A r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={B},
   type=A
  */switch (r) {
    /*
     remaining=A,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true),
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|B(a: Enum, b: true),
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: true),
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*
     remaining=∅,
     space=Null
    */case null:
      print('null');
      break;
  }
}

void unreachableCase3(A? r) {
  /*
   fields={},
   remaining=∅,
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*
     remaining=A?,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: bool)|B(a: Enum, b: true)|Null,
     space=A(a: Enum.b, b: false)
    */case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|B(a: Enum, b: true)|Null,
     space=A(a: Enum.a, b: true)
    */case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*
     remaining=B(a: Enum.b, b: true)|Null,
     space=A(a: Enum.b, b: true)
    */case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*
     remaining=Null,
     space=Null
    */case null:
      print('null #1');
      break;
    /*
     remaining=∅,
     space=Null
    */case null:
      print('null #2');
      break;
  }
}
