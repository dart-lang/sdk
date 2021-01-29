// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

num numTopLevel = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
int intTopLevel = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
dynamic dynamicTopLevel = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;

testTopLevel() {
  /*cfe.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe.num*/
  /*cfe:nnbd.num!*/
  numTopLevel
      /*cfe.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe.num*/
  /*cfe:nnbd.num!*/
  numTopLevel
      /*cfe.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe.num*/
      /*cfe:nnbd.num!*/
      numTopLevel;

  /*cfe.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe.num*/
      /*cfe:nnbd.num!*/
      numTopLevel;

  /*cfe.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  intTopLevel
      /*cfe.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  intTopLevel
      /*cfe.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      intTopLevel;

  /*cfe.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      intTopLevel;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;
}

class Class {
  num numInstance = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  int intInstance = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;
  dynamic dynamicInstance = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;

  testInstance() {
    /*cfe.update: num*/
    /*cfe:nnbd.update: num!*/
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    numInstance
        /*cfe.invoke: num*/
        /*cfe:nnbd.invoke: num!*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        ++;

    /*cfe.update: num*/
    /*cfe:nnbd.update: num!*/
    /*cfe.num*/
    /*cfe:nnbd.num!*/
    numInstance
        /*cfe.invoke: num*/
        /*cfe:nnbd.invoke: num!*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        --;

    /*cfe.invoke: num*/
    /*cfe:nnbd.invoke: num!*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    ++
        /*cfe.update: num*/
        /*cfe:nnbd.update: num!*/
        /*cfe.num*/
        /*cfe:nnbd.num!*/
        numInstance;

    /*cfe.invoke: num*/
    /*cfe:nnbd.invoke: num!*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    --
        /*cfe.update: num*/
        /*cfe:nnbd.update: num!*/
        /*cfe.num*/
        /*cfe:nnbd.num!*/
        numInstance;

    /*cfe.update: int*/
    /*cfe:nnbd.update: int!*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    intInstance
        /*cfe.invoke: int*/
        /*cfe:nnbd.invoke: int!*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        ++;

    /*cfe.update: int*/
    /*cfe:nnbd.update: int!*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    intInstance
        /*cfe.invoke: int*/
        /*cfe:nnbd.invoke: int!*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        --;

    /*cfe.invoke: int*/
    /*cfe:nnbd.invoke: int!*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    ++
        /*cfe.update: int*/
        /*cfe:nnbd.update: int!*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        intInstance;

    /*cfe.invoke: int*/
    /*cfe:nnbd.invoke: int!*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    --
        /*cfe.update: int*/
        /*cfe:nnbd.update: int!*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        intInstance;

    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        ++;
    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/
        /*cfe.int*/
        /*cfe:nnbd.int!*/
        --;
    /*invoke: dynamic*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    ++
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
    /*invoke: dynamic*/
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    --
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
  }
}

testInstanceOnClass(Class c) {
  /*cfe.Class*/
  /*cfe:nnbd.Class!*/
  c. /*cfe.update: num*/
          /*cfe:nnbd.update: num!*/
          /*cfe.num*/
          /*cfe:nnbd.num!*/
          numInstance
      /*cfe.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe.Class*/
  /*cfe:nnbd.Class!*/
  c. /*cfe.update: num*/
          /*cfe:nnbd.update: num!*/
          /*cfe.num*/
          /*cfe:nnbd.num!*/
          numInstance
      /*cfe.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe.Class*/
      /*cfe:nnbd.Class!*/
      c. /*cfe.update: num*/
          /*cfe:nnbd.update: num!*/
          /*cfe.num*/
          /*cfe:nnbd.num!*/
          numInstance;
  /*cfe.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe.Class*/
      /*cfe:nnbd.Class!*/
      c. /*cfe.update: num*/
          /*cfe:nnbd.update: num!*/
          /*cfe.num*/
          /*cfe:nnbd.num!*/
          numInstance;

  /*cfe.Class*/
  /*cfe:nnbd.Class!*/
  c.
          /*cfe.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe.int*/
          /*cfe:nnbd.int!*/
          intInstance
      /*cfe.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe.Class*/
  /*cfe:nnbd.Class!*/
  c.
          /*cfe.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe.int*/
          /*cfe:nnbd.int!*/
          intInstance
      /*cfe.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe.Class*/
      /*cfe:nnbd.Class!*/
      c.
          /*cfe.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe.int*/
          /*cfe:nnbd.int!*/
          intInstance;

  /*cfe.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe.Class*/
      /*cfe:nnbd.Class!*/
      c.
          /*cfe.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe.int*/
          /*cfe:nnbd.int!*/
          intInstance;

  /*cfe.Class*/
  /*cfe:nnbd.Class!*/
  c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe.Class*/
  /*cfe:nnbd.Class!*/
  c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

testInstanceOnDynamic(dynamic c) {
  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

main() {
  /// ignore: unused_local_variable
  num numLocal = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;

  /// ignore: unused_local_variable
  int intLocal = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;

  /// ignore: unused_local_variable
  dynamic dynamicLocal = /*cfe.int*/ /*cfe:nnbd.int!*/ 0;

  /*cfe.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe.num*/
  /*cfe:nnbd.num!*/
  numLocal
      /*cfe.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe.num*/
  /*cfe:nnbd.num!*/
  numLocal
      /*cfe.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe.num*/
      /*cfe:nnbd.num!*/
      numLocal;

  /*cfe.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe.num*/
      /*cfe:nnbd.num!*/
      numLocal;

  /*cfe.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  intLocal
      /*cfe.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  intLocal
      /*cfe.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      intLocal;

  /*cfe.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      intLocal;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal
      /*invoke: dynamic*/
      /*cfe.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  ++
      /*update: dynamic*/ /*dynamic*/ dynamicLocal;

  /*invoke: dynamic*/
  /*cfe.int*/
  /*cfe:nnbd.int!*/
  --
      /*update: dynamic*/ /*dynamic*/ dynamicLocal;
}
