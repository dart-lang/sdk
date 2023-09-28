// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: avoid_annotating_with_dynamic
typedef F = int Function(dynamic s);

void main() {
  final List<String> finalList = [];

  // Linted because parameter is final.
  finalList.where((final e) =>
      ((a) => e.contains(a))(e)); // LINT
  finalList.where((final e) =>
      (e.contains)(e)); // OK
  finalList.where((e) =>
      ((a) => e.contains(a))(e)); // OK

  finalList.where((e) => // OK
      ((a) => e?.contains(a) ?? false)(e)); // OK

  var deeplyNestedVariable = (a, b) { // OK
    foo(foo(b)).foo(a, b);
  };
}

foo(a) {}

void method() {
  List<List> names = [];
  names.add(names);

  var a = names.where((e) => ((e) => e.contains(e))(e)); // LINT
  var b = names.where((e) => // LINT
      ((e) => e?.contains(e))(e));
  names.where((e) => e?.contains(e) ?? false); // OK

  var c = names.where((e) { // LINT
    return ((e) {
      return e.contains(e);
    })(e);
  });
}
