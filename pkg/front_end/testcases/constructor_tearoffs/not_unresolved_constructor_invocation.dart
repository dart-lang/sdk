// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for expression that could be unresolved constructor invocations but
// are actually valid instantiation expressions.

class ResolvedClass<T> {
  ResolvedClass.named();

  static unresolvedConstructor() {}
}

UnresolvedClass<T>() {}

extension Extension on Function {
  unresolvedConstructor() {}
}

class unresolved_prefix {
  static UnresolvedClass<T>() {}
}

class resolved_prefix {
  static UnresolvedClass<T>() {}
}

main() {
  UnresolvedClass();

  UnresolvedClass.unresolvedConstructor();
  UnresolvedClass/**/ .unresolvedConstructor();

  unresolved_prefix.UnresolvedClass();
  unresolved_prefix. /**/ UnresolvedClass();

  unresolved_prefix.UnresolvedClass.unresolvedConstructor();
  unresolved_prefix/**/ .UnresolvedClass.unresolvedConstructor();

  UnresolvedClass<int>();
  UnresolvedClass /**/ <int>();

  UnresolvedClass<int>.unresolvedConstructor();
  UnresolvedClass /**/ <int>.unresolvedConstructor();

  unresolved_prefix.UnresolvedClass<int>();
  unresolved_prefix/**/ .UnresolvedClass<int>();

  unresolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  unresolved_prefix/**/ .UnresolvedClass<int>.unresolvedConstructor();

  ResolvedClass.unresolvedConstructor();
  ResolvedClass/**/ .unresolvedConstructor();

  resolved_prefix.UnresolvedClass();
  resolved_prefix. /**/ UnresolvedClass();

  resolved_prefix.UnresolvedClass.unresolvedConstructor();
  resolved_prefix/**/ .UnresolvedClass.unresolvedConstructor();

  resolved_prefix.UnresolvedClass<int>();
  resolved_prefix. /**/ UnresolvedClass<int>();

  resolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  resolved_prefix/**/ .UnresolvedClass<int>.unresolvedConstructor();
}
