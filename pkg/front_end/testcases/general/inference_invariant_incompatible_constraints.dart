// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Invariant<X> = X Function(X x);
X inferable<X>() => throw 0;
void context<X>(Invariant<X> Function() g) => g();
test() => context(() => inferable());
