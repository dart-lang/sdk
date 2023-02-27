// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

or(bool b1, bool? b2) {
  /*
   fields={hashCode:int,runtimeType:Type},
   subtypes={true,false},
   type=bool
  */
  switch (b1) {
    /*space=true|false*/
    case true || false:
  }

  /*
   expandedSubtypes={true,false,Null},
   fields={},
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
   expandedSubtypes={true,false,Null},
   fields={},
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
   expandedSubtypes={true,false,Null},
   fields={},
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
   expandedSubtypes={true,false,Null},
   fields={},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=true|false|Null*/
    case true || false || null:
  }

  /*
   expandedSubtypes={true,false,Null},
   fields={},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=true|false|Null*/
    case true || false || Null _:
  }

  /*
   error=non-exhaustive:false,
   expandedSubtypes={true,false,Null},
   fields={},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
  /*space=true?*/
    case true || Null _:
  }

  /*
   error=non-exhaustive:true,
   expandedSubtypes={true,false,Null},
   fields={},
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
  */switch (r) {
    /*space=($1: true|false, $2: true|false|Null)*/
    case (true || false, true || false || null):
  }
  /*
   fields={$1:bool,$2:bool?},
   type=(bool, bool?)
  */switch (r) {
    /*space=($1: true, $2: true|false|Null)*/
    case (true, true || false || null):
    /*space=($1: false, $2: true|false)*/
    case (false, true || false):
    /*space=($1: false, $2: Null)*/
    case (false, null):
  }

  /*
   error=non-exhaustive:($1: false, $2: Null),
   fields={$1:bool,$2:bool?},
   type=(bool, bool?)
  */switch (r) {
    /*space=($1: true, $2: true|false|Null)*/
    case (true, true || false || null):
    /*space=($1: false, $2: true|false)*/
    case (false, true || false):
  }

  /*
   error=non-exhaustive:($1: true, $2: false),
   fields={$1:bool,$2:bool?},
   type=(bool, bool?)
  */
  switch (r) {
    /*space=($1: true|false, $2: true?)*/
    case (true || false, true || null):
  }
}