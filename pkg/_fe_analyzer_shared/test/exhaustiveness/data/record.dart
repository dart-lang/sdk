// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a, b }

const r0 = (Enum.a, false);
const r1 = (Enum.b, false);
const r2 = (Enum.a, true);
const r3 = (Enum.b, true);

void exhaustiveSwitch((Enum, bool) r) {
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    /*space=(Enum.b, false)*/
    case r1:
      print('(b, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum.b, false),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum.a, false),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */
  switch (r) {
    /*space=(Enum.b, false)*/
    case r1:
      print('(b, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault((Enum, bool) r) {
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch((Enum, bool)? r) {
  /*
   checkingOrder={(Enum, bool)?,(Enum, bool),Null},
   fields={$1:-,$2:-},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    /*space=(Enum.b, false)*/
    case r1:
      print('(b, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1((Enum, bool)? r) {
  /*
   checkingOrder={(Enum, bool)?,(Enum, bool),Null},
   error=non-exhaustive:null,
   fields={$1:-,$2:-},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    /*space=(Enum.b, false)*/
    case r1:
      print('(b, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2((Enum, bool)? r) {
  /*
   checkingOrder={(Enum, bool)?,(Enum, bool),Null},
   error=non-exhaustive:(Enum.b, false),
   fields={$1:-,$2:-},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase1((Enum, bool) r) {
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false) #1');
      break;
    /*space=(Enum.b, false)*/
    case r1:
      print('(b, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
    /*
     error=unreachable,
     space=(Enum.a, false)
    */
    case r0:
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2((Enum, bool) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    /*space=(Enum.b, false)*/
    case r1:
      print('(b, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase3((Enum, bool)? r) {
  /*
   checkingOrder={(Enum, bool)?,(Enum, bool),Null},
   fields={$1:-,$2:-},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */
  switch (r) {
    /*space=(Enum.a, false)*/
    case r0:
      print('(a, false)');
      break;
    /*space=(Enum.b, false)*/
    case r1:
      print('(b, false)');
      break;
    /*space=(Enum.a, true)*/
    case r2:
      print('(a, true)');
      break;
    /*space=(Enum.b, true)*/
    case r3:
      print('(b, true)');
      break;
    /*space=Null*/
    case null:
      print('null1');
      break;
    /*
     error=unreachable,
     space=Null
    */
    case null:
      print('null2');
      break;
  }
}
