// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a, b, c }

void exhaustiveSwitch(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=∅,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.c,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
  }
}

const a1 = Enum.a;
const b1 = Enum.b;
const c1 = Enum.c;

void exhaustiveSwitchAliasedBefore(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=∅,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case a1:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case b1:
      print('b');
      break;
    /*
     remaining=Enum.c,
     space=Enum.c
    */
    case c1:
      print('c');
      break;
  }
}

void exhaustiveSwitchAliasedAfter(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=∅,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case a2:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case b2:
      print('b');
      break;
    /*
     remaining=Enum.c,
     space=Enum.c
    */
    case c2:
      print('c');
      break;
  }
}

const a2 = Enum.a;
const b2 = Enum.b;
const c2 = Enum.c;

void nonExhaustiveSwitch1(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=Enum.c,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitch2(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=Enum.b,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch3(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=Enum.a,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.a|Enum.c,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch4(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=Enum.a|Enum.c,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=Enum.a|Enum.c,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    default:
      print('a|c');
      break;
  }
}

void exhaustiveNullableSwitch(Enum? e) {
  /*
   fields={},
   remaining=∅,
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*
     remaining=Enum?,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c|Null,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.c?,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
    /*
     remaining=Null,
     space=Null
    */
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(Enum? e) {
  /*
   fields={},
   remaining=Null,
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*
     remaining=Enum?,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c|Null,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.c?,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveNullableSwitch2(Enum? e) {
  /*
   fields={},
   remaining=Enum.b,
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*
     remaining=Enum?,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c|Null,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
    /*
     remaining=Enum.b?,
     space=Null
    */
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=∅,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case Enum.a:
      print('a1');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.c,
     space=Enum.a
    */
    case Enum.a:
      print('a2');
      break;
    /*
     remaining=Enum.c,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
  }
}

void unreachableCase2(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=Enum.c,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case Enum.a:
      print('a1');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.c,
     space=Enum.a
    */
    case Enum.a:
      print('a2');
      break;
  }
}

void unreachableCase3(Enum e) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=∅,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.c,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
    /*
     remaining=∅,
     space=Null
    */
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase4(Enum? e) {
  /*
   fields={},
   remaining=∅,
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*
     remaining=Enum?,
     space=Enum.a
    */
    case Enum.a:
      print('a');
      break;
    /*
     remaining=Enum.b|Enum.c|Null,
     space=Enum.b
    */
    case Enum.b:
      print('b');
      break;
    /*
     remaining=Enum.c?,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
    /*
     remaining=Null,
     space=Null
    */
    case null:
      print('null1');
      break;
    /*
     remaining=∅,
     space=Null
    */
    case null:
      print('null2');
      break;
  }
}

void unreachableCase5(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   remaining=∅,
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*
     remaining=Enum,
     space=Enum.a
    */
    case Enum.a:
      print('a1');
      break;
    /*
     remaining=Enum.b|Enum.c,
     space=Enum.b
    */
    case Enum.b:
    /*
     remaining=Enum.c,
     space=Enum.a
    */
    case Enum.a:
    /*
     remaining=Enum.c,
     space=Enum.c
    */
    case Enum.c:
      print('c');
      break;
  }
}
