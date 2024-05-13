// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/
class Class<T> {
  var property;

  method(T o) {
    if (/*T%*/ o is Class) {
      /*T% & Class<dynamic>!*/
      o. /*invoke: dynamic*/ method(/*Null*/ null);
      /*T% & Class<dynamic>!|dynamic*/ o
          ?. /*invoke: dynamic*/ method(/*Null*/ null);
      /*T% & Class<dynamic>!|dynamic*/ o
          ?. /*dynamic*/ property;
    }
  }
}

method<T>(T o) {
  if (/*T%*/ o is Class) {
    /*T% & Class<dynamic>!*/
    o. /*invoke: dynamic*/ method(/*Null*/ null);
    /*T% & Class<dynamic>!|dynamic*/ o
        ?. /*invoke: dynamic*/ method(/*Null*/ null);
    /*T% & Class<dynamic>!|dynamic*/ o
        ?. /*dynamic*/ property;
  }
}

main() {
  var c = new
      /*Class<dynamic>!*/
      Class/*<dynamic>*/();
  /*Class<dynamic>!*/ c
      . /*invoke: dynamic*/ method(
          /*Class<dynamic>!*/ c);
  /*invoke: dynamic*/ method
      /*<Class<dynamic>!>*/ (
          /*Class<dynamic>!*/ c);
}
