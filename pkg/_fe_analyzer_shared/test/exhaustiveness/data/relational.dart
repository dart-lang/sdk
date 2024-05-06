// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

equals(o1, o2) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o1) {
    == 0 /*space=?*/ => 0,
    _ /*space=()*/ => 1
  };

  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:Object();null,
   subtypes={Object,Null},
   type=Object?
  */
      switch (o2) {
    == 0 /*space=?*/ => 0,
  };
}

greaterThan(o1, o2) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o1) {
    >= 0 /*space=?*/ => 0,
    _ /*space=()*/ => 1
  };

  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:Object();null,
   subtypes={Object,Null},
   type=Object?
  */
      switch (o2) {
    >= 0 /*space=?*/ => 0,
  };
}
