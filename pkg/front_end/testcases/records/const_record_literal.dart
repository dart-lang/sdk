// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const dynamic a = (1, 2);
const dynamic b = (a: 1, b: 2);
const dynamic c = (a: a, b: b);
const dynamic d = (c, (1, 2));

dynamic e = const (1, 2);
dynamic f = const (a: 1, b: 2);
dynamic g = const (a: a, b: b);
dynamic h = const (c, (1, 2));
