// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that instantiate to bound leaves typedef types that have
// their arguments defined by the programmer intact in cases when those typedef
// types are used as type arguments of literal lists.

typedef A<T>(T p);

class B<S> {
  final List<A<S>> foo = <A<S>>[];
  final List<A<num>> bar = <A<num>>[];
}

main() {}
