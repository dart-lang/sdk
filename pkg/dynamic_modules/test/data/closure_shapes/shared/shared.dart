// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int f1(int i) => i + 1;
int f2(int i, {int j = 2, int k = 3}) => i + j + k;

final c1 = f1;
final c2 = f2;
