// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

num numTopLevel = /*int*/ 0;
int intTopLevel = /*int*/ 0;
dynamic dynamicTopLevel = /*int*/ 0;

testTopLevel() {
  /*update: num*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numTopLevel /*invoke: num*/ /*int*/ ++;

  /*update: num*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numTopLevel /*invoke: num*/ /*int*/ --;

  /*invoke: num*/ /*int*/ ++ /*update: num*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numTopLevel;

  /*invoke: num*/ /*int*/ -- /*update: num*/
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
      /*int*/ ++;

  /*cfe|dart2js.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  intTopLevel
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*int*/ --;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*int*/ ++
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intTopLevel;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*int*/ --
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intTopLevel;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ /*int*/ ++;

  /*update: dynamic*/ /*dynamic*/ dynamicTopLevel
      /*invoke: dynamic*/ /*int*/ --;

  /*invoke: dynamic*/ /*int*/ ++
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;

  /*invoke: dynamic*/ /*int*/ --
      /*update: dynamic*/ /*dynamic*/ dynamicTopLevel;
}

class Class {
  num numInstance = /*int*/ 0;
  int intInstance = /*int*/ 0;
  dynamic dynamicInstance = /*int*/ 0;

  testInstance() {
    /*update: num*/
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    numInstance /*invoke: num*/ /*int*/ ++;

    /*update: num*/
    /*cfe|dart2js.num*/
    /*cfe:nnbd.num!*/
    numInstance /*invoke: num*/ /*int*/ --;

    /*invoke: num*/ /*int*/ ++ /*update: num*/
        /*cfe|dart2js.num*/
        /*cfe:nnbd.num!*/
        numInstance;

    /*invoke: num*/ /*int*/ -- /*update: num*/
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
        /*int*/ ++;

    /*cfe|dart2js.update: int*/
    /*cfe:nnbd.update: int!*/
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    intInstance
        /*cfe|dart2js.invoke: int*/
        /*cfe:nnbd.invoke: int!*/
        /*int*/ --;

    /*cfe|dart2js.invoke: int*/
    /*cfe:nnbd.invoke: int!*/
    /*int*/ ++
        /*cfe|dart2js.update: int*/
        /*cfe:nnbd.update: int!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        intInstance;

    /*cfe|dart2js.invoke: int*/
    /*cfe:nnbd.invoke: int!*/
    /*int*/ --
        /*cfe|dart2js.update: int*/
        /*cfe:nnbd.update: int!*/
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        intInstance;

    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/ /*int*/ ++;
    /*update: dynamic*/ /*dynamic*/ dynamicInstance
        /*invoke: dynamic*/ /*int*/ --;
    /*invoke: dynamic*/ /*int*/ ++
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
    /*invoke: dynamic*/ /*int*/ --
        /*update: dynamic*/ /*dynamic*/ dynamicInstance;
  }
}

testInstanceOnClass(Class c) {
  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c. /*update: num*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numInstance /*invoke: num*/ /*int*/ ++;
  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c. /*update: num*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numInstance /*invoke: num*/ /*int*/ --;
  /*invoke: num*/ /*int*/ ++
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: num*/
          /*cfe|dart2js.num*/
          /*cfe:nnbd.num!*/
          numInstance;
  /*invoke: num*/ /*int*/ --
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: num*/
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
      /*int*/ ++;

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
      /*int*/ --;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*int*/ ++
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
  /*int*/ --
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
      /*invoke: dynamic*/ /*int*/ ++;

  /*cfe|dart2js.Class*/
  /*cfe:nnbd.Class!*/
  c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/ /*int*/ --;

  /*invoke: dynamic*/ /*int*/ ++
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;

  /*invoke: dynamic*/ /*int*/ --
      /*cfe|dart2js.Class*/
      /*cfe:nnbd.Class!*/
      c. /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

testInstanceOnDynamic(dynamic c) {
  /*dynamic*/ c. /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/ /*int*/ ++;
  /*dynamic*/ c. /*update: dynamic*/ /*dynamic*/ numInstance
      /*invoke: dynamic*/ /*int*/ --;
  /*invoke: dynamic*/ /*int*/ ++ /*dynamic*/ c
      . /*update: dynamic*/ /*dynamic*/ numInstance;
  /*invoke: dynamic*/ /*int*/ -- /*dynamic*/ c
      . /*update: dynamic*/ /*dynamic*/ numInstance;

  /*dynamic*/ c. /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/ /*int*/ ++;
  /*dynamic*/ c. /*update: dynamic*/ /*dynamic*/ intInstance
      /*invoke: dynamic*/ /*int*/ --;
  /*invoke: dynamic*/ /*int*/ ++ /*dynamic*/ c
      . /*update: dynamic*/ /*dynamic*/ intInstance;
  /*invoke: dynamic*/ /*int*/ -- /*dynamic*/ c
      . /*update: dynamic*/ /*dynamic*/ intInstance;

  /*dynamic*/ c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/ /*int*/ ++;
  /*dynamic*/ c. /*update: dynamic*/ /*dynamic*/ dynamicInstance
      /*invoke: dynamic*/ /*int*/ --;
  /*invoke: dynamic*/ /*int*/ ++ /*dynamic*/ c
      . /*update: dynamic*/ /*dynamic*/ dynamicInstance;
  /*invoke: dynamic*/ /*int*/ -- /*dynamic*/ c
      . /*update: dynamic*/ /*dynamic*/ dynamicInstance;
}

main() {
  /// ignore: unused_local_variable
  num numLocal = /*int*/ 0;

  /// ignore: unused_local_variable
  int intLocal = /*int*/ 0;

  /// ignore: unused_local_variable
  dynamic dynamicLocal = /*int*/ 0;

  /*update: num*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numLocal /*invoke: num*/ /*int*/ ++;

  /*update: num*/
  /*cfe|dart2js.num*/
  /*cfe:nnbd.num!*/
  numLocal /*invoke: num*/ /*int*/ --;

  /*invoke: num*/ /*int*/ ++ /*update: num*/
      /*cfe|dart2js.num*/
      /*cfe:nnbd.num!*/
      numLocal;

  /*invoke: num*/ /*int*/ -- /*update: num*/
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
      /*int*/ ++;

  /*cfe|dart2js.update: int*/
  /*cfe:nnbd.update: int!*/
  /*cfe|dart2js.int*/
  /*cfe:nnbd.int!*/
  intLocal
      /*cfe|dart2js.invoke: int*/
      /*cfe:nnbd.invoke: int!*/
      /*int*/ --;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*int*/ ++
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intLocal;

  /*cfe|dart2js.invoke: int*/
  /*cfe:nnbd.invoke: int!*/
  /*int*/ --
      /*cfe|dart2js.update: int*/
      /*cfe:nnbd.update: int!*/
      /*cfe|dart2js.int*/
      /*cfe:nnbd.int!*/
      intLocal;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal /*invoke: dynamic*/ /*int*/ ++;

  /*update: dynamic*/ /*dynamic*/ dynamicLocal /*invoke: dynamic*/ /*int*/ --;

  /*invoke: dynamic*/ /*int*/ ++ /*update: dynamic*/ /*dynamic*/ dynamicLocal;

  /*invoke: dynamic*/ /*int*/ -- /*update: dynamic*/ /*dynamic*/ dynamicLocal;
}
