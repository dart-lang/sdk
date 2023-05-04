// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef NullableObject = Object?;

object(o) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    NullableObject()? /*space=Object*/ => 0,
    _ /*space=()*/ => 1,
  };
  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:null,
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    NullableObject()? /*space=Object*/ => 0,
  };
}

wildcard(o) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    _? /*space=Object*/ => 0,
    _ /*space=()*/ => 1,
  };
  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:null,
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    _? /*space=Object*/ => 0,
  };
}

or(o) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    (NullableObject() || _)? /*space=Object*/ => 0,
    _ /*space=()*/ => 1,
  };
  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:null,
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    (NullableObject() || _)? /*space=Object*/ => 0,
  };
}

typedVariable(o) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    NullableObject n? /*space=Object*/ => 0,
    _ /*space=()*/ => 1,
  };
  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:null,
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    _? /*space=Object*/ => 0,
  };
}

untypedVariable(o) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    var n? /*space=Object*/ => 0,
    _ /*space=()*/ => 1,
  };
  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:null,
   subtypes={Object,Null},
   type=Object?
  */
      switch (o) {
    _? /*space=Object*/ => 0,
  };
}
