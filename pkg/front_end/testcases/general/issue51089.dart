// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X, Y> { A(X x, Y y); }
typedef F<X> = A<X, X Function()>;

void main() => F<int>(0, () => 1);
