// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const dynamic a = (1, 2);
const dynamic b1 = (a: 1, b: 2);
const dynamic b2 = (b: 2, a: 1);
const dynamic b3 = (b: 2, 1);
const dynamic c1 = (a: a, b: b1);
const dynamic c2 = (b: b2, a: a);
const dynamic c3 = (b: b3, a);
const dynamic d = (c1, (1, 2));

dynamic e = const (1, 2);
dynamic f1 = const (a: 1, b: 2);
dynamic f2 = const (b: 2, a: 1);
dynamic f3 = const (b: 2, 1);
dynamic g1 = const (a: a, b: b1);
dynamic g2 = const (b: b2, a: a);
dynamic g3 = const (b: b3, a);
dynamic h = const (c1, (1, 2));
