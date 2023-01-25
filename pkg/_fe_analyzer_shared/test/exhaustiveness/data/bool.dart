// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void exhaustiveSwitch(bool b) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=true
    */
    case true:
      print('true');
      break;
    /*
     remaining=false,
     space=false
    */
    case false:
      print('false');
      break;
  }
}

const t1 = true;
const f1 = false;

void exhaustiveSwitchAliasedBefore(bool b) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=true
    */
    case t1:
      print('true');
      break;
    /*
     remaining=false,
     space=false
    */
    case f1:
      print('false');
      break;
  }
}

void exhaustiveSwitchAliasedAfter(bool b) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=true
    */
    case t2:
      print('true');
      break;
    /*
     remaining=false,
     space=false
    */
    case f2:
      print('false');
      break;
  }
}

const t2 = true;
const f2 = false;

void nonExhaustiveSwitch1(bool b) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=false,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=true
    */
    case true:
      print('true');
      break;
  }
}

void nonExhaustiveSwitch2(bool b) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=true,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=false
    */
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(bool b) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=false,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=true
    */
    case true:
      print('true');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(bool? b) {
  /*
   fields={},
   remaining=∅,
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*
     remaining=bool?,
     space=true
    */
    case true:
      print('true');
      break;
    /*
     remaining=false?,
     space=false
    */
    case false:
      print('false');
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

void nonExhaustiveNullableSwitch1(bool? b) {
  /*
   fields={},
   remaining=Null,
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*
     remaining=bool?,
     space=true
    */
    case true:
      print('true');
      break;
    /*
     remaining=false?,
     space=false
    */
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveNullableSwitch2(bool? b) {
  /*
   fields={},
   remaining=false,
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*
     remaining=bool?,
     space=true
    */
    case true:
      print('true');
      break;
    /*
     remaining=false?,
     space=Null
    */
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(bool b) {
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=true
    */
    case true:
      print('true1');
      break;
    /*
     remaining=false,
     space=false
    */
    case false:
      print('false');
      break;
    /*
     remaining=∅,
     space=true
    */
    case true: // Unreachable
      print('true2');
      break;
  }
}

void unreachableCase2(bool b) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={hashCode:int,runtimeType:Type},
   remaining=∅,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*
     remaining=bool,
     space=true
    */
    case true:
      print('true');
      break;
    /*
     remaining=false,
     space=false
    */
    case false:
      print('false');
      break;
    /*
     remaining=∅,
     space=Null
    */
    case null:
      print('null');
      break;
  }
}

void unreachableCase3(bool? b) {
  /*
   fields={},
   remaining=∅,
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*
     remaining=bool?,
     space=true
    */
    case true:
      print('true');
      break;
    /*
     remaining=false?,
     space=false
    */
    case false:
      print('false');
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
