// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

num numTopLevel = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;
int intTopLevel = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;
dynamic dynamicTopLevel = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;

testTopLevel() {
  /*cfe|dart2js.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numTopLevel
      /*cfe|dart2js.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe|dart2js.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numTopLevel
      /*cfe|dart2js.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe|dart2js.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe|dart2js.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numTopLevel;

  /*cfe|dart2js.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe|dart2js.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numTopLevel;

  /*cfe|dart2js.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  intTopLevel
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe|dart2js.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  intTopLevel
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intTopLevel;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intTopLevel;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;
}

class Class {
  num numInstance = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;
  int intInstance = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;
  dynamic dynamicInstance = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;

  testInstance() {
    /*cfe|dart2js.update: num*/
    /*cfe:nnbd.update: num!*/
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    numInstance
        /*cfe|dart2js.invoke: num*/
        /*cfe:nnbd.invoke: num!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        ++;

    /*cfe|dart2js.update: num*/
    /*cfe:nnbd.update: num!*/
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    numInstance
        /*cfe|dart2js.invoke: num*/
        /*cfe:nnbd.invoke: num!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        --;

    /*cfe|dart2js.invoke: num*/
    /*cfe:nnbd.invoke: num!*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    ++
        /*cfe|dart2js.update: num*/
        /*cfe:nnbd.update: num!*/
        /*cfe|dart2js.num*/
        /*cfe:nnbd.num!*/
        numInstance;

    /*cfe|dart2js.invoke: num*/
    /*cfe:nnbd.invoke: num!*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    --
        /*cfe|dart2js.update: num*/
        /*cfe:nnbd.update: num!*/
        /*cfe|dart2js.num*/
        /*cfe:nnbd.num!*/
        numInstance;

    /*cfe|dart2js.update: int*/
    /*cfe:nnbd.update: int!*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    intInstance
        /*cfe|dart2js.invoke: int*/
        /*cfe:nnbd.invoke: int!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        ++;

    /*cfe|dart2js.update: int*/
    /*cfe:nnbd.update: int!*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    intInstance
        /*cfe|dart2js.invoke: int*/
        /*cfe:nnbd.invoke: int!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        --;

    /*cfe|dart2js.invoke: int*/
    /*cfe:nnbd.invoke: int!*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    ++
        /*cfe|dart2js.update: int*/
        /*cfe:nnbd.update: int!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        intInstance;

    /*cfe|dart2js.invoke: int*/
    /*cfe:nnbd.invoke: int!*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    --
        /*cfe|dart2js.update: int*/
        /*cfe:nnbd.update: int!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        intInstance;

    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        ++;
    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        --;
    /*invoke: dynamic*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    ++
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
    /*invoke: dynamic*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    --
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
  }
}

testInstanceOnClass(Class c) {
  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c. /*cfe|dart2js.update: num*/ /*cfe:nnbd.update: num!*/
          /*cfe|dart2js.num*/
          /*cfe:nnbd.num!*/
          numInstance
      /*cfe|dart2js.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c. /*cfe|dart2js.update: num*/ /*cfe:nnbd.update: num!*/
          /*cfe|dart2js.num*/
          /*cfe:nnbd.num!*/
          numInstance
      /*cfe|dart2js.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe|dart2js.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*cfe|dart2js.update: num*/
          /*cfe:nnbd.update: num!*/
          /*cfe|dart2js.num*/
          /*cfe:nnbd.num!*/
          numInstance;
  /*cfe|dart2js.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*cfe|dart2js.update: num*/
          /*cfe:nnbd.update: num!*/
          /*cfe|dart2js.num*/
          /*cfe:nnbd.num!*/
          numInstance;

  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c.
          /*cfe|dart2js.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe|dart2js.int*/
          /*cfe:nnbd.int!*/
          intInstance
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c.
          /*cfe|dart2js.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe|dart2js.int*/
          /*cfe:nnbd.int!*/
          intInstance
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c.
          /*cfe|dart2js.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe|dart2js.int*/
          /*cfe:nnbd.int!*/
          intInstance;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c.
          /*cfe|dart2js.update: int*/
          /*cfe:nnbd.update: int!*/
          /*cfe|dart2js.int*/
          /*cfe:nnbd.int!*/
          intInstance;

  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

testInstanceOnDynamic(dynamic c) {
  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ numInstance;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ intInstance;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*dynamic*/ c.
          /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

main() {
  /// ignore: unused_local_variable
  num numLocal = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;

  /// ignore: unused_local_variable
  int intLocal = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;

  /// ignore: unused_local_variable
  dynamic dynamicLocal = /*cfe|dart2js.int*/ /*cfe:nnbd.int!*/ 0;

  /*cfe|dart2js.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numLocal
      /*cfe|dart2js.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe|dart2js.update: num*/
  /*cfe:nnbd.update: num!*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numLocal
      /*cfe|dart2js.invoke: num*/
      /*cfe:nnbd.invoke: num!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe|dart2js.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe|dart2js.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numLocal;

  /*cfe|dart2js.invoke: num*/
  /*cfe:nnbd.invoke: num!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe|dart2js.update: num*/
      /*cfe:nnbd.update: num!*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numLocal;

  /*cfe|dart2js.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  intLocal
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*cfe|dart2js.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  intLocal
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intLocal;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intLocal;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      ++;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal
      /*invoke: dynamic*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      --;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  ++
      /*update: dynamic*/ /*dynamic*/ dynamicLocal;

  /*invoke: dynamic*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  --
      /*update: dynamic*/ /*dynamic*/ dynamicLocal;
}
