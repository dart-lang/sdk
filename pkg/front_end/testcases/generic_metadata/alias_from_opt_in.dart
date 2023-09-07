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
  T5 t5a, // Error,
  List<T5> t5b, // Error,
  void Function(T5) t5c, // Error
  void Function(List<T5>) t5d, // Error
  T6 t6a, // Error,
  List<T6> t6b, // Error,
  void Function(T6) t6c, // Error
  void Function(List<T6>) t6d, // Error
  T7 t7a, // Error,
  List<T7> t7b, // Error,
  void Function(T7) t7c, // Error
  void Function(List<T7>) t7d, // Error
  T8 t8a, // Error,
  List<T8> t8b, // Error,
  void Function(T8) t8c, // Error
  void Function(List<T8>) t8d, // Error
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
