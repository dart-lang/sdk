// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}
class B extends A {}
class C extends A {}
class D extends A {}

enum Enum {a, b}

void exhaustiveSwitch1(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=B
    */case B b:
      print('B');
      break;
    /*
     remaining=C|D,
     space=C
    */case C c:
      print('C');
      break;
    /*
     remaining=D,
     space=D
    */case D d:
      print('D');
      break;
  }
}

void exhaustiveSwitch2(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=B
    */case B b:
      print('B');
      break;
    /*
     remaining=C|D,
     space=A
    */case A a:
      print('A');
      break;
  }
}

void nonExhaustiveSwitch1(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=D,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=B
    */case B b:
      print('B');
      break;
    /*
     remaining=C|D,
     space=C
    */case C c:
      print('C');
      break;
  }
}

void nonExhaustiveSwitch2(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=B,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=C
    */case C c:
      print('C');
      break;
    /*
     remaining=B|D,
     space=D
    */case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitch3(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=C,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=B
    */case B b:
      print('B');
      break;
    /*
     remaining=C|D,
     space=D
    */case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=C|D,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=B
    */case B b:
      print('B');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? a) {
  /*
   fields={},
   remaining=∅,
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*
     remaining=A?,
     space=B
    */case B b:
      print('B');
      break;
    /*
     remaining=C|D|Null,
     space=C
    */case C c:
      print('C');
      break;
    /*
     remaining=D?,
     space=D
    */case D d:
      print('D');
      break;
    /*
     remaining=Null,
     space=Null
    */case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? a) {
  /*
   fields={},
   remaining=Null,
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*
     remaining=A?,
     space=A
    */case A a:
      print('A');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? a) {
  /*
   fields={},
   remaining=D,
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*
     remaining=A?,
     space=B
    */case B b:
      print('B');
      break;
    /*
     remaining=C|D|Null,
     space=C
    */case C c:
      print('C');
      break;
    /*
     remaining=D?,
     space=Null
    */case null:
      print('null');
      break;
  }
}

void unreachableCase1(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=B
    */case B b:
      print('B');
      break;
    /*
     remaining=C|D,
     space=C
    */case C c:
      print('C');
      break;
    /*
     remaining=D,
     space=D
    */case D d:
      print('D');
      break;
    /*
     remaining=∅,
     space=A
    */case A a:
      print('A');
      break;
  }
}

void unreachableCase2(A a) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*
     remaining=A,
     space=A
    */case A a:
      print('A');
      break;
    /*
     remaining=∅,
     space=Null
    */case null:
      print('null');
      break;
  }
}

void unreachableCase3(A? a) {
  /*
   fields={},
   remaining=∅,
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*
     remaining=A?,
     space=A
    */case A a:
      print('A');
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
