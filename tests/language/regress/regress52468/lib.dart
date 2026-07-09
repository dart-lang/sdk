// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const list = <(int, int)>[(0, unevaluated)];
const unevaluated = const bool.fromEnvironment('a.b.c') ? 1 : 2;
