// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks for compile-time errors and their absence for cases involving
// fields of potentially non-nullable types.

int x; // Error.
int? y; // Ok: it's nullable.
late int z; // Ok: it's late.

class A<T extends Object?> {
  static int x; // Error.
  static int? y; // Ok: it's nullable.
  static late int z; // Ok: it's late. 

  int lx; // Error.
  int? ly; // Ok: it's nullable.
  late int? lz; // Ok: it's late.
  int lv; // Ok: initialized in an initializing formal.
  int lu; // Ok: initialized in an initializer list entry.

  T lt; // Error.
  T? ls; // Ok: it's nullable.
  late T lr; // Ok: it's late.
  T lp; // Ok: initialized in an initializing formal.
  T lq; // Ok: initialized in an initializer list entry.

  A(this.lv, this.lp, T t) : this.lu = 42, this.lq = t;
}

main() {}
