// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void cfeAwait<XF extends F>(XF xf) async {
  (await xf).st<E<int>>();
  (await xf).st<E<int>>;

  var v1 = await xf;
  v1.toRadixString(16);
  int v2 = v1;

  int? v3 = v1;
  v1 = v3;
}

extension type F(Future<int> _) implements Future<int> {}

void main() {
  cfeAwait<F>(F(Future<int>.value(1)));
}

extension Est<T> on T {
  void st<X extends E<T>>() {}
}

typedef E<S> = S Function(S);
