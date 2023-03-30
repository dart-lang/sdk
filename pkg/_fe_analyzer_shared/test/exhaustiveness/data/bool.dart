// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void exhaustiveSwitch(bool b) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
  }
}

const t1 = true;
const f1 = false;

void exhaustiveSwitchAliasedBefore(bool b) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=true*/
    case t1:
      print('true');
      break;
    /*space=false*/
    case f1:
      print('false');
      break;
  }
}

void exhaustiveSwitchAliasedAfter(bool b) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=true*/
    case t2:
      print('true');
      break;
    /*space=false*/
    case f2:
      print('false');
      break;
  }
}

const t2 = true;
const f2 = false;

void nonExhaustiveSwitch1(bool b) {
  /*
   checkingOrder={bool,true,false},
   error=non-exhaustive:false,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true');
      break;
  }
}

void nonExhaustiveSwitch2(bool b) {
  /*
   checkingOrder={bool,true,false},
   error=non-exhaustive:true,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=false*/
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(bool b) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=true*/
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
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(bool? b) {
  /*
   checkingOrder={bool?,bool,Null,true,false},
   error=non-exhaustive:null,
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveNullableSwitch2(bool? b) {
  /*
   checkingOrder={bool?,bool,Null,true,false},
   error=non-exhaustive:false,
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(bool b) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true1');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*
     error=unreachable,
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
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase3(bool? b) {
  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
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
