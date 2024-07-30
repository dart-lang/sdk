// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DOMWindow {}

class Window extends DOMWindow native "*Window" {}
//                             ^^^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.NATIVE_CLAUSE_IN_NON_SDK_CODE
// [cfe] expect cfe to report an error here

class Console native "=(typeof console == 'undefined' ? {} : console)" {}
//            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.NATIVE_CLAUSE_IN_NON_SDK_CODE
// [cfe] expect cfe to report an error here

class NativeClass native "FooBar" {}
//                ^^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.NATIVE_CLAUSE_IN_NON_SDK_CODE
// [cfe] expect cfe to report an error here

abstract class Fisk {}

class BoolImplementation implements Fisk native "Boolean" {}
//                                       ^^^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.NATIVE_CLAUSE_IN_NON_SDK_CODE
// [cfe] expect cfe to report an error here

class _JSON native 'JSON' {}
//          ^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.NATIVE_CLAUSE_IN_NON_SDK_CODE
// [cfe] expect cfe to report an error here

class ListFactory<E> implements List<E> native "Array" {
//                                      ^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.NATIVE_CLAUSE_IN_NON_SDK_CODE
// [cfe] expect cfe to report an error here
  noSuchMethod(_) => null; // Allow unimplemented methods
}

main() {
  try {
    new Window();
    new Console();
    new NativeClass();
    new BoolImplementation();
    new _JSON();
    new ListFactory();
    new ListFactory<Object>();
  } catch (ex) {
    // Swallowing exceptions. Any error should be a compile-time error
    // which kills the current isolate.
  }
  throw 'This test should fail to compile, not throw a run-time error.';
}
