// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<X> = X;
typedef F2<X> = F<F<X>>;
extension type E<X>(F2<X> it) {}

typedef F3<X> = F4<X>;
typedef F4<X> = F4<X>; // Error.
extension type E2<X>(F3<X> it) {}
