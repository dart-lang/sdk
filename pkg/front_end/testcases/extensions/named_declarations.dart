// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {}

extension A2 on A1 {}

class B1<T> {}

extension B2<T> on B1<T> {}

extension B3 on B1<A1> {}

extension B4<T extends A1> on B1<T> {}

main() {}
