// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E1<X>(X it) {}
typedef F<X> = X;
extension type E2<X>(E1<F<E1<X>>> it) {}
