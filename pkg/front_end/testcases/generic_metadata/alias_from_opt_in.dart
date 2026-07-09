// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

import 'alias_from_opt_in_lib.dart';

test(
  T1 t1a, // Ok
  List<T1> t1b, // Error
  void Function(T1) t1c, // Ok
  void Function(List<T1>) t1d, // Error
  T2 t2a, // Ok
  List<T2> t2b, // // Ok
  void Function(T2) t2c, // Ok
  void Function(List<T2>) t2d, // // Ok
  T3 t3a, // Error
  List<T3> t3b, // Error
  void Function(T3) t3c, // Error
  void Function(List<T3>) t3d, // Error
  T4 t4a, // Error,
  List<T4> t4b, // Error,
  void Function(T4) t4c, // Error
  void Function(List<T4>) t4d, // Error
  T5 t5a, // Ok,
  List<T5> t5b, // Ok,
  void Function(T5) t5c, // Ok
  void Function(List<T5>) t5d, // Ok
  T6 t6a, // Ok,
  List<T6> t6b, // Ok,
  void Function(T6) t6c, // Ok
  void Function(List<T6>) t6d, // Ok
  T7 t7a, // Error,
  List<T7> t7b, // Error,
  void Function(T7) t7c, // Error
  void Function(List<T7>) t7d, // Error
  T8 t8a, // Error,
  List<T8> t8b, // Error,
  void Function(T8) t8c, // Error
  void Function(List<T8>) t8d, // Error
  T9 t9a, // Error,
  List<T9> t9b, // Error,
  void Function(T9) t9c, // Error
  void Function(List<T9>) t9d, // Error
  T10 t10a, // Error,
  List<T10> t10b, // Error,
  void Function(T10) t10c, // Error
  void Function(List<T10>) t10d, // Error
  T11 t11a, // Ok,
  List<T11> t11b, // Ok,
  void Function(T11) t11c, // Ok
  void Function(List<T11>) t11d, // Ok
  T12 t12a, // Error,
  List<T12> t12b, // Error,
  void Function(T12) t12c, // Error
  void Function(List<T12>) t12d, // Error
) {
  new T4(); // Error
  <T4>[]; // Error
  <void Function(T4)>[]; // Error
  <void Function(List<T4>)>[]; // Error
  new T7(0); // Error
  <T7>[]; // Error
  <void Function(T7)>[]; // Error
  <void Function(List<T7>)>[]; // Error
}

main() {}
