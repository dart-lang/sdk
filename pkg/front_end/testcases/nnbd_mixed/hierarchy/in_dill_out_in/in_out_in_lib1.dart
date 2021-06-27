// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  int nullabilityMethod(int i, {required int j}) => i;
  int get nullabilityGetter => 0;
  void set nullabilitySetter(int value) {}
  int optionalArgumentsMethod(int i) => i;
}

abstract class SuperExtra {
  int optionalArgumentsMethod(int i, [int? j]) => i;
}

abstract class SuperQ {
  int? nullabilityMethod(int? i, {int? j}) => i;
  int? get nullabilityGetter => null;
  void set nullabilitySetter(int? value) {}
  int? optionalArgumentsMethod(int? i) => i;
}
