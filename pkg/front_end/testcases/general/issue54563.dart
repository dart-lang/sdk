// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test<X, Y>(int? Function(X)? f1, int? Function(Y) f2) => f1 ?? f2;
