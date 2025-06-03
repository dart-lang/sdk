// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void index_reachable(List<int>? f()) {
  f()?[throw ''];
  0;
}

/*member: index_unreachable:doesNotComplete*/
void index_unreachable(List<int> f()) {
  // Unreachable since Dart 3.9.
  f()?[throw ''];
  /*stmt: unreachable*/
  0;
}

void cascaded_index_reachable(List<int>? f()) {
  f()?..[throw ''];
  0;
}

/*member: cascaded_index_unreachable:doesNotComplete*/
void cascaded_index_unreachable(List<int> f()) {
  // Unreachable since Dart 3.9.
  f()?..[throw ''];
  /*stmt: unreachable*/
  0;
}

void method_invocation_reachable(int? f()) {
  f()?.remainder(throw '');
  0;
}

/*member: method_invocation_unreachable:doesNotComplete*/
void method_invocation_unreachable(int f()) {
  // Unreachable since Dart 3.9.
  f()?.remainder(throw '');
  /*stmt: unreachable*/
  0;
}

void cascaded_method_invocation_reachable(int? f()) {
  f()?..remainder(throw '');
  0;
}

/*member: cascaded_method_invocation_unreachable:doesNotComplete*/
void cascaded_method_invocation_unreachable(int f()) {
  // Unreachable since Dart 3.9.
  f()?..remainder(throw '');
  /*stmt: unreachable*/
  0;
}

void property_get_reachable(int? f()) {
  f()?.hashCode.remainder(throw '');
  0;
}

/*member: property_get_unreachable:doesNotComplete*/
void property_get_unreachable(int f()) {
  // Unreachable since Dart 3.9.
  f()?.hashCode.remainder(throw '');
  /*stmt: unreachable*/
  0;
}

void cascaded_property_get_reachable(int? f()) {
  f()?..hashCode.remainder(throw '');
  0;
}

/*member: cascaded_property_get_unreachable:doesNotComplete*/
void cascaded_property_get_unreachable(int f()) {
  // Unreachable since Dart 3.9.
  f()?..hashCode.remainder(throw '');
  /*stmt: unreachable*/
  0;
}

void property_get_invocation_reachable(List<void Function(dynamic)>? f()) {
  // We need a special test case for this because it parses like a method
  // invocation but the analyzer rewrites it as a property access followed by a
  // function expression invocation.
  f()?.first(throw '');
  0;
}

/*member: property_get_invocation_unreachable:doesNotComplete*/
void property_get_invocation_unreachable(List<void Function(dynamic)> f()) {
  // Unreachable since Dart 3.9.
  // We need a special test case for this because it parses like a method
  // invocation but the analyzer rewrites it as a property access followed by a
  // function expression invocation.
  f()?.first(throw '');
  /*stmt: unreachable*/
  0;
}

void cascaded_property_get_invocation_reachable(
  List<void Function(dynamic)>? f(),
) {
  // We need a special test case for this because it parses like a method
  // invocation but the analyzer rewrites it as a property access followed by a
  // function expression invocation.
  f()?..first(throw '');
  0;
}

/*member: cascaded_property_get_invocation_unreachable:doesNotComplete*/
void cascaded_property_get_invocation_unreachable(
  List<void Function(dynamic)> f(),
) {
  // Unreachable since Dart 3.9.
  // We need a special test case for this because it parses like a method
  // invocation but the analyzer rewrites it as a property access followed by a
  // function expression invocation.
  f()?..first(throw '');
  /*stmt: unreachable*/
  0;
}

class C {
  int field = 0;
}

void property_set_reachable(C? f()) {
  f()?.field = throw '';
  0;
}

/*member: property_set_unreachable:doesNotComplete*/
void property_set_unreachable(C f()) {
  // Unreachable since Dart 3.9.
  f()?.field = throw '';
  /*stmt: unreachable*/
  0;
}

void cascaded_property_set_reachable(C? f()) {
  f()?..field = throw '';
  0;
}

/*member: cascaded_property_set_unreachable:doesNotComplete*/
void cascaded_property_set_unreachable(C f()) {
  // Unreachable since Dart 3.9.
  f()?..field = throw '';
  /*stmt: unreachable*/
  0;
}
