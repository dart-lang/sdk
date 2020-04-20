// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

class Class<T> {
  var property;

  method(T o) {
    if (/*cfe.T*/ /*cfe:nnbd.T%*/ o is Class) {
      /*cfe.T & Class<dynamic>*/
      /*cfe:nnbd.T! & Class<dynamic>!*/
      o. /*invoke: dynamic*/ method(/*Null*/ null);
      /*cfe.T & Class<dynamic>*/ /*cfe:nnbd.T! & Class<dynamic>!*/ o
          ?. /*invoke: dynamic*/ method(/*Null*/ null);
      /*cfe.T & Class<dynamic>*/ /*cfe:nnbd.T! & Class<dynamic>!*/ o
          ?. /*dynamic*/ property;
    }
  }
}

method<T>(T o) {
  if (/*cfe.T*/ /*cfe:nnbd.T%*/ o is Class) {
    /*cfe.T & Class<dynamic>*/
    /*cfe:nnbd.T! & Class<dynamic>!*/
    o. /*invoke: dynamic*/ method(/*Null*/ null);
    /*cfe.T & Class<dynamic>*/ /*cfe:nnbd.T! & Class<dynamic>!*/ o
        ?. /*invoke: dynamic*/ method(/*Null*/ null);
    /*cfe.T & Class<dynamic>*/ /*cfe:nnbd.T! & Class<dynamic>!*/ o
        ?. /*dynamic*/ property;
  }
}

main() {
  var c = new
      /*cfe.Class<dynamic>*/
      /*cfe:nnbd.Class<dynamic>!*/
      Class/*<dynamic>*/();
  /*cfe.Class<dynamic>*/ /*cfe:nnbd.Class<dynamic>!*/ c
      . /*invoke: dynamic*/ method(
          /*cfe.Class<dynamic>*/ /*cfe:nnbd.Class<dynamic>!*/ c);
  /*invoke: dynamic*/ method
      /*cfe.<Class<dynamic>>*/ /*cfe:nnbd.<Class<dynamic>!>*/ (
          /*cfe.Class<dynamic>*/ /*cfe:nnbd.Class<dynamic>!*/ c);
}
