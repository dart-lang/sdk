// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type N(Future<int> _) {}
extension type F(Future<int> _) implements Future<int> {}

void test<X, XN extends N, XF extends F>(
    N n, F f, X x, XN xn, XF xf, N? nq, F? fq, XN? xnq, XF? xfq) async {
  await n; // Error.
  await f; // OK, type `int`.
  await x; // OK, type `X`.
  await xn; // Error.
  await xf; // OK, type `int`.
  await nq; // Error.
  await fq; // OK, type `int?`.
  await xnq; // Error.
  await xfq; // OK, type `int?`.
  if (x is N) await x; // Error.
  if (x is N?) await x; // Error.
  if (x is XN) await x; // Error.
  if (x is XN?) await x; // Error.
  if (x is F) await x; // OK, type `int`.
  if (x is F?) await x; // OK, type `int?`.
  if (x is XF) await x; // OK, type `int`.
  if (x is XF?) await x; // OK, type `int?`.
}
