// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {}

mixin class B<T> implements A<T> {}

class C<T> implements A<T> {}

class D implements B<String>, C<int> {} // Error

class E<T> extends B<T> implements C<int> {} // Error

class F<T> with B<String> implements C<T> {} // Error
