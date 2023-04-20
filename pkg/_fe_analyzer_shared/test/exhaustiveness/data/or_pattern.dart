// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

or(bool b1, bool? b2) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (b1) {
    /*space=true|false*/
    case true || false:
  }

  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=Null*/
    case null:
    /*space=true|false*/
    case true || false:
  }

  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=true*/
    case true:
    /*space=false?*/
    case false || null:
  }

  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=false*/
    case false:
    /*space=true?*/
    case null || true:
  }

  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=true|false|Null*/
    case true || false || null:
  }

  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=true|false|Null*/
    case true || false || Null _:
  }

  /*
   checkingOrder={bool?,bool,Null,true,false},
   error=non-exhaustive:false,
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=true?*/
    case true || Null _:
  }

  /*
   checkingOrder={bool?,bool,Null,true,false},
   error=non-exhaustive:true,
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=false?*/
    case null || false:
  }
}

inRecord((bool, bool?) r) {
  /*
   fields={$1:bool,$2:bool?},
   type=(bool, bool?)
  */
  switch (r) {
    /*space=(true|false, true|false|Null)*/
    case (true || false, true || false || null):
  }
  /*
   fields={$1:bool,$2:bool?},
   type=(bool, bool?)
  */
  switch (r) {
    /*space=(true, true|false|Null)*/
    case (true, true || false || null):
    /*space=(false, true|false)*/
    case (false, true || false):
    /*space=(false, Null)*/
    case (false, null):
  }

  /*
   error=non-exhaustive:(false, null),
   fields={$1:bool,$2:bool?},
   type=(bool, bool?)
  */
  switch (r) {
    /*space=(true, true|false|Null)*/
    case (true, true || false || null):
    /*space=(false, true|false)*/
    case (false, true || false):
  }

  /*
   error=non-exhaustive:(true, false),
   fields={$1:bool,$2:bool?},
   type=(bool, bool?)
  */
  switch (r) {
    /*space=(true|false, true?)*/
    case (true || false, true || null):
  }
}
