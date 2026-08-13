// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.14

import 'unresolved_constructor_invocation.dart' as resolved_prefix;

class Super {
  Super.named();
}

class Class extends Super {
  Class.constructor1() : super();
  Class.constructor2() : super.unresolved();
  Class.constructor3() : this();
  Class.constructor4() : this.unresolved();
}

class ResolvedClass<T> {
  ResolvedClass.named();
}

test() {
  UnresolvedClass();
  new UnresolvedClass();
  const UnresolvedClass();

  UnresolvedClass.unresolvedConstructor();
  new UnresolvedClass.unresolvedConstructor();
  const UnresolvedClass.unresolvedConstructor();
  UnresolvedClass /**/ .unresolvedConstructor();
  new UnresolvedClass. /**/ unresolvedConstructor();
  const UnresolvedClass /**/ .unresolvedConstructor();

  unresolved_prefix.UnresolvedClass();
  new unresolved_prefix.UnresolvedClass();
  const unresolved_prefix.UnresolvedClass();
  unresolved_prefix. /**/ UnresolvedClass();
  new unresolved_prefix /**/ .UnresolvedClass();
  const unresolved_prefix. /**/ UnresolvedClass();

  unresolved_prefix.UnresolvedClass.unresolvedConstructor();
  new unresolved_prefix.UnresolvedClass.unresolvedConstructor();
  const unresolved_prefix.UnresolvedClass.unresolvedConstructor();
  unresolved_prefix /**/ .UnresolvedClass.unresolvedConstructor();
  new unresolved_prefix.UnresolvedClass /**/ .unresolvedConstructor();
  const unresolved_prefix. /**/ UnresolvedClass. /**/ unresolvedConstructor();

  UnresolvedClass<int>();
  new UnresolvedClass<int>();
  const UnresolvedClass<int>();
  UnresolvedClass /**/ <int>();
  new UnresolvedClass<int> /**/ ();
  const UnresolvedClass /**/ <int>();

  UnresolvedClass<int>.unresolvedConstructor();
  new UnresolvedClass<int>.unresolvedConstructor();
  const UnresolvedClass<int>.unresolvedConstructor();
  UnresolvedClass /**/ <int>.unresolvedConstructor();
  new UnresolvedClass<int> /**/ .unresolvedConstructor();
  const UnresolvedClass<int>. /**/ unresolvedConstructor();

  unresolved_prefix.UnresolvedClass<int>();
  new unresolved_prefix.UnresolvedClass<int>();
  const unresolved_prefix.UnresolvedClass<int>();
  unresolved_prefix /**/ .UnresolvedClass<int>();
  new unresolved_prefix.UnresolvedClass /**/ <int>();
  const unresolved_prefix.UnresolvedClass<int> /**/ ();

  unresolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  new unresolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  const unresolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  unresolved_prefix /**/ .UnresolvedClass<int>.unresolvedConstructor();
  new unresolved_prefix.UnresolvedClass /**/ <int>.unresolvedConstructor();
  const unresolved_prefix.UnresolvedClass<int>. /**/ unresolvedConstructor();

  ResolvedClass();
  new ResolvedClass();
  const ResolvedClass();

  ResolvedClass.unresolvedConstructor();
  new ResolvedClass.unresolvedConstructor();
  const ResolvedClass.unresolvedConstructor();
  ResolvedClass /**/ .unresolvedConstructor();
  new ResolvedClass. /**/ unresolvedConstructor();
  const ResolvedClass /**/ .unresolvedConstructor();

  resolved_prefix.UnresolvedClass();
  new resolved_prefix.UnresolvedClass();
  const resolved_prefix.UnresolvedClass();
  resolved_prefix. /**/ UnresolvedClass();
  new resolved_prefix /**/ .UnresolvedClass();
  const resolved_prefix. /**/ UnresolvedClass();

  resolved_prefix.ResolvedClass();
  new resolved_prefix.ResolvedClass();
  const resolved_prefix.ResolvedClass();
  resolved_prefix. /**/ ResolvedClass();
  new resolved_prefix /**/ .ResolvedClass();
  const resolved_prefix. /**/ ResolvedClass();

  resolved_prefix.UnresolvedClass.unresolvedConstructor();
  new resolved_prefix.UnresolvedClass.unresolvedConstructor();
  const resolved_prefix.UnresolvedClass.unresolvedConstructor();
  resolved_prefix /**/ .UnresolvedClass.unresolvedConstructor();
  new resolved_prefix.UnresolvedClass /**/ .unresolvedConstructor();
  const resolved_prefix. /**/ UnresolvedClass. /**/ unresolvedConstructor();

  resolved_prefix.ResolvedClass.unresolvedConstructor();
  new resolved_prefix.ResolvedClass.unresolvedConstructor();
  const resolved_prefix.ResolvedClass.unresolvedConstructor();
  resolved_prefix /**/ .ResolvedClass.unresolvedConstructor();
  new resolved_prefix.ResolvedClass /**/ .unresolvedConstructor();
  const resolved_prefix. /**/ ResolvedClass. /**/ unresolvedConstructor();

  ResolvedClass<int>();
  new ResolvedClass<int>();
  const ResolvedClass<int>();
  ResolvedClass /**/ <int>();
  new ResolvedClass /**/ <int>();
  const ResolvedClass /**/ <int>();

  ResolvedClass<int>.unresolvedConstructor();
  new ResolvedClass<int>.unresolvedConstructor();
  const ResolvedClass<int>.unresolvedConstructor();
  ResolvedClass<int> /**/ .unresolvedConstructor();
  new ResolvedClass<int>. /**/ unresolvedConstructor();
  const ResolvedClass /**/ <int>.unresolvedConstructor();

  resolved_prefix.UnresolvedClass<int>();
  new resolved_prefix.UnresolvedClass<int>();
  const resolved_prefix.UnresolvedClass<int>();
  resolved_prefix. /**/ UnresolvedClass<int>();
  new resolved_prefix.UnresolvedClass /**/ <int>();
  const resolved_prefix.UnresolvedClass<int> /**/ ();

  resolved_prefix.ResolvedClass<int>();
  new resolved_prefix.ResolvedClass<int>();
  const resolved_prefix.ResolvedClass<int>();
  resolved_prefix. /**/ ResolvedClass<int>();
  new resolved_prefix.ResolvedClass /**/ <int>();
  const resolved_prefix.ResolvedClass<int> /**/ ();

  resolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  new resolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  const resolved_prefix.UnresolvedClass<int>.unresolvedConstructor();
  resolved_prefix /**/ .UnresolvedClass<int>.unresolvedConstructor();
  new resolved_prefix.UnresolvedClass<int> /**/ .unresolvedConstructor();
  const resolved_prefix
      . /**/ UnresolvedClass<int>. /**/ unresolvedConstructor();

  resolved_prefix.ResolvedClass<int>.unresolvedConstructor();
  new resolved_prefix.ResolvedClass<int>.unresolvedConstructor();
  const resolved_prefix.ResolvedClass<int>.unresolvedConstructor();
  resolved_prefix /**/ .ResolvedClass<int>.unresolvedConstructor();
  new resolved_prefix.ResolvedClass<int> /**/ .unresolvedConstructor();
  const resolved_prefix. /**/ ResolvedClass<int>. /**/ unresolvedConstructor();
}

main() {}
