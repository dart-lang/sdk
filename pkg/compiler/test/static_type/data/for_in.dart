// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Iterable<Class> next;
}

abstract class Class2<E> implements Iterable<E> {
  @override
  Iterator<E> iterator;
}

main() {
  forIn1(null);
  forIn2(null);
  forIn3(null);
  forIn4(null);
  forIn5(null);
}

forIn1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    // ignore: unused_local_variable
    for (var b in /*Class*/ c.next) {
      /*dynamic*/ c.next;
      if (/*dynamic*/ c is Class) {
        /*Class*/ c.next;
      }
      c = 0;
    }
    /*dynamic*/ c.next;
  }
}

forIn2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    // ignore: unused_local_variable
    for (var b in /*Class*/ c.next) {
      /*Class*/ c.next;
    }
    /*Class*/ c.next;
  }
}

forIn3(o) {
  /*dynamic*/ o;
  for (var e in /*dynamic*/ o) {
    /*dynamic*/ e;
    /*dynamic*/ o;
  }
  /*dynamic*/ o;
}

forIn4(o) {
  /*dynamic*/ o;
  for (int e in /*dynamic*/ o) {
    /*int*/ e;
    /*dynamic*/ o;
  }
  /*dynamic*/ o;
}

forIn5(Class2<int> o) {
  /*Class2<int>*/ o;
  for (var e in /*Class2<int>*/ o) {
    /*int*/ e;
    /*Class2<int>*/ o;
  }
  /*Class2<int>*/ o;
}
