// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Class next;
}

class GenericClass<T> {
  GenericClass next;
}

main() {
  while1(null);
  while2(null);
  whileNext(null);
  whileNextGeneric(null);
  new Class1<int>()
    .. /*invoke: [Class1<int>]->dynamic*/ whileNext1()
    .. /*invoke: [Class1<int>]->dynamic*/ whileNext2()
    .. /*invoke: [Class1<int>]->dynamic*/ whileNext3();
}

while1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    while (/*dynamic*/ c /*invoke: [dynamic]->bool*/ != null) {
      /*dynamic*/ c.next;
      if (/*dynamic*/ c is Class) {
        /*Class*/ c.next;
      }
      c = 0;
    }
    /*dynamic*/ c.next;
  }
}

while2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    while (/*Class*/ c /*invoke: [Class]->bool*/ != null) {
      /*Class*/ c.next;
    }
    /*Class*/ c.next;
  }
}

whileNext(Class c) {
  while (/*Class*/ c /*invoke: [Class]->bool*/ != null) {
    c = /*Class*/ c.next;
  }
  return /*Class*/ c;
}

whileNextGeneric(GenericClass<int> c) {
  while (
      /*GenericClass<int>*/ c /*invoke: [GenericClass<int>]->bool*/ != null) {
    c = /*GenericClass<int>*/ c.next;
  }
  return /*GenericClass<int>*/ c;
}

class Class1<T> {
  whileNext1() {
    bool b;
    GenericClass<T> c;
    while (/*bool*/ b) {
      if (/*bool*/ b) {
        GenericClass<T> next = /*GenericClass<T>*/ c.next;
        c = /*GenericClass<T>*/ next;
      } else {
        c = /*GenericClass<T>*/ c.next;
      }
    }
    return /*GenericClass<T>*/ c;
  }

  whileNext2() {
    bool b;
    GenericClass<T> c;
    while (/*GenericClass<T>*/ c /*invoke: [GenericClass<T>]->bool*/ != null) {
      if (/*bool*/ b) {
        GenericClass<T> next = /*GenericClass<T>*/ c.next;
        c = /*GenericClass<T>*/ next;
      } else {
        c = /*GenericClass<T>*/ c.next;
      }
    }
    return /*GenericClass<T>*/ c;
  }

  whileNext3() {
    bool b;
    GenericClass<T> c;
    while (/*GenericClass<T>*/ c /*invoke: [GenericClass<T>]->bool*/ == null) {
      if (/*bool*/ b) {
        GenericClass<T> next = /*Null*/ c.next;
        c = /*GenericClass<T>*/ next;
      } else {
        c = /*Null*/ c.next;
      }
    }
    return /*GenericClass<T>*/ c;
  }
}
