// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MySet<T>(Set<T> it) implements Set<T> {}

extension type MyMap<K, V>(Map<K, V> it) implements Map<K, V> {}

main() {
  MyList<int> list = [];
  //                 ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'List<dynamic>' can't be assigned to a variable of type 'MyList<int>'.
  MySet<String> set = {};
  //                  ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Map<dynamic, dynamic>' can't be assigned to a variable of type 'MySet<String>'.
  MyMap<String, bool> map = {};
  //                        ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Map<dynamic, dynamic>' can't be assigned to a variable of type 'MyMap<String, bool>'.
}
