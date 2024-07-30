// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

num numTopLevel = /*int!*/ 0;
int intTopLevel = /*int!*/ 0;
dynamic dynamicTopLevel = /*int!*/ 0;

testTopLevel() {
  /*update: num!*/
  /*num!*/
  numTopLevel
      /*invoke: num!*/
      /*int!*/
      ++;

  /*update: num!*/
  /*num!*/
  numTopLevel
      /*invoke: num!*/
      /*int!*/
      --;

  /*invoke: num!*/
  /*int!*/
  ++
      /*update: num!*/
      /*num!*/
      numTopLevel;

  /*invoke: num!*/
  /*int!*/
  --
      /*update: num!*/
      /*num!*/
      numTopLevel;

  /*update: int!*/
  /*int!*/
  intTopLevel
      /*invoke: int!*/
      /*int!*/
      ++;

  /*update: int!*/
  /*int!*/
  intTopLevel
      /*invoke: int!*/
      /*int!*/
      --;

  /*invoke: int!*/
  /*int!*/
  ++
      /*update: int!*/
      /*int!*/
      intTopLevel;

  /*invoke: int!*/
  /*int!*/
  --
      /*update: int!*/
      /*int!*/
      intTopLevel;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/
      /*int!*/
      ++;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/
      /*int!*/
      --;

  /*invoke: dynamic*/
  /*int!*/
  ++
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;

  /*invoke: dynamic*/
  /*int!*/
  --
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;
}

class Class {
  num numInstance = /*int!*/ 0;
  int intInstance = /*int!*/ 0;
  dynamic dynamicInstance = /*int!*/ 0;

  testInstance() {
    /*update: num!*/
    /*num!*/
    numInstance
        /*invoke: num!*/
        /*int!*/
        ++;

    /*update: num!*/
    /*num!*/
    numInstance
        /*invoke: num!*/
        /*int!*/
        --;

    /*invoke: num!*/
    /*int!*/
    ++
        /*update: num!*/
        /*num!*/
        numInstance;

    /*invoke: num!*/
    /*int!*/
    --
        /*update: num!*/
        /*num!*/
        numInstance;

    /*update: int!*/
    /*int!*/
    intInstance
        /*invoke: int!*/
        /*int!*/
        ++;

    /*update: int!*/
    /*int!*/
    intInstance
        /*invoke: int!*/
        /*int!*/
        --;

    /*invoke: int!*/
    /*int!*/
    ++
        /*update: int!*/
        /*int!*/
        intInstance;

    /*invoke: int!*/
    /*int!*/
    --
        /*update: int!*/
        /*int!*/
        intInstance;

    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/
        /*int!*/
        ++;
    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/
        /*int!*/
        --;
    /*invoke: dynamic*/
    /*int!*/
    ++
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
    /*invoke: dynamic*/
    /*int!*/
    --
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
  }
}

testInstanceOnClass(Class c) {
  /*Class!*/
  c. /*update: num!*/
          /*num!*/
          numInstance
      /*invoke: num!*/
      /*int!*/
      ++;

  /*Class!*/
  c. /*update: num!*/
          /*num!*/
          numInstance
      /*invoke: num!*/
      /*int!*/
      --;

  /*invoke: num!*/
  /*int!*/
  ++
      /*Class!*/
      c. /*update: num!*/
          /*num!*/
          numInstance;
  /*invoke: num!*/
  /*int!*/
  --
      /*Class!*/
      c. /*update: num!*/
          /*num!*/
          numInstance;

  /*Class!*/
  c.
          /*update: int!*/
          /*int!*/
          intInstance
      /*invoke: int!*/
      /*int!*/
      ++;

  /*Class!*/
  c.
          /*update: int!*/
          /*int!*/
          intInstance
      /*invoke: int!*/
      /*int!*/
      --;

  /*invoke: int!*/
  /*int!*/
  ++
      /*Class!*/
      c.
          /*update: int!*/
          /*int!*/
          intInstance;

  /*invoke: int!*/
  /*int!*/
  --
      /*Class!*/
      c.
          /*update: int!*/
          /*int!*/
          intInstance;

  /*Class!*/
  c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*int!*/
      ++;

  /*Class!*/
  c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*int!*/
      --;

  /*invoke: dynamic*/
  /*int!*/
  ++
      /*Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;

  /*invoke: dynamic*/
  /*int!*/
  --
      /*Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

testInstanceOnDynamic(dynamic c) {
  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/
      /*int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/
      /*int!*/
      --;

  /*invoke: dynamic*/
  /*int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance;

  /*invoke: dynamic*/
  /*int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/
      /*int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/
      /*int!*/
      --;

  /*invoke: dynamic*/
  /*int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance;

  /*invoke: dynamic*/
  /*int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*int!*/
      --;

  /*invoke: dynamic*/
  /*int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance;

  /*invoke: dynamic*/
  /*int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

main() {
  /// ignore: unused_local_variable
  num numLocal = /*int!*/ 0;

  /// ignore: unused_local_variable
  int intLocal = /*int!*/ 0;

  /// ignore: unused_local_variable
  dynamic dynamicLocal = /*int!*/ 0;

  /*update: num!*/
  /*num!*/
  numLocal
      /*invoke: num!*/
      /*int!*/
      ++;

  /*update: num!*/
  /*num!*/
  numLocal
      /*invoke: num!*/
      /*int!*/
      --;

  /*invoke: num!*/
  /*int!*/
  ++
      /*update: num!*/
      /*num!*/
      numLocal;

  /*invoke: num!*/
  /*int!*/
  --
      /*update: num!*/
      /*num!*/
      numLocal;

  /*update: int!*/
  /*int!*/
  intLocal
      /*invoke: int!*/
      /*int!*/
      ++;

  /*update: int!*/
  /*int!*/
  intLocal
      /*invoke: int!*/
      /*int!*/
      --;

  /*invoke: int!*/
  /*int!*/
  ++
      /*update: int!*/
      /*int!*/
      intLocal;

  /*invoke: int!*/
  /*int!*/
  --
      /*update: int!*/
      /*int!*/
      intLocal;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal
      /*invoke: dynamic*/
      /*int!*/
      ++;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal
      /*invoke: dynamic*/
      /*int!*/
      --;

  /*invoke: dynamic*/
  /*int!*/
  ++
      /*update: dynamic*/ /*dynamic*/ dynamicLocal;

  /*invoke: dynamic*/
  /*int!*/
  --
      /*update: dynamic*/ /*dynamic*/ dynamicLocal;
}
