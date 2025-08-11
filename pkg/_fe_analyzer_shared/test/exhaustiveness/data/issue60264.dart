// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class Option<T> {
  const Option();
}

class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);
}

class None extends Option<Never> {
  // T can be any type
  const None();

  /// Placeholder get, to use it in switch in this example
  bool get noneProp => false;
}

/// Global const.
const none = None();

/// Works as expected
void fun<T>(Option<T> option) {
  /*
   checkingOrder={Option<T>,Some<T>,None},
   subtypes={Some<T>,None},
   type=Option<T>
  */
  switch (option) {
    /*space=Some<T>*/
    case Some():
      final _ = option.value;
    /*space=None*/
    case None():
      final _ = option.noneProp;
  }
}

/// Works as expected
class MyClass {
  void fun<T>(Option<T> option) {
    /*
     checkingOrder={Option<T>,Some<T>,None},
     subtypes={Some<T>,None},
     type=Option<T>
    */
    switch (option) {
      /*space=Some<T>*/
      case Some():
        final _ = option.value;
      /*space=None*/
      case None():
        final _ = option.noneProp;
    }
  }
}

void globalFunWithNestedFun() {
  void fun<T>(Option<T> option) {
    /*
     checkingOrder={Option<T>,Some<T>,None},
     subtypes={Some<T>,None},
     type=Option<T>
    */
    switch (option) {
      /*space=Some<T>*/
      case Some():
        final _ = option.value;
      /*space=None*/
      case None():
        final _ = option.noneProp;
    }
  }

  var f = <T>(Option<T> option) {
    /*
     checkingOrder={Option<T>,Some<T>,None},
     subtypes={Some<T>,None},
     type=Option<T>
    */
    switch (option) {
      /*space=Some<T>*/
      case Some():
        final _ = option.value;
      /*space=None*/
      case None():
        final _ = option.noneProp;
    }
  };
}
