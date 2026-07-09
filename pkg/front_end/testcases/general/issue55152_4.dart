// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A();
  const factory A.redir() = A;
}

typedef TA = A;

const List<A> test1 = const [TA.redir()];
const List<A> test2 = const [A.redir()];
const List<A> test3 = const [TA()];
