// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {}

class E {}

class F {}

class B extends A<E> {}

class C extends A<F> {}

class D extends C {}
