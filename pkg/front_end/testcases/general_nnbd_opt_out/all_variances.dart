// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The test checks how type parameters of different variances are serialized.

typedef F<W, X, Y, Z> = X Function(Y, Z Function(Z));

main() {}
