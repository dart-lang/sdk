// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<X> = X Function(X);

class A<T> {}

class Class<T extends A<T>> {}

method(Class c1, Class<dynamic> c2) {}

main() {}
