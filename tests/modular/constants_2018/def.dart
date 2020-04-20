// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const val = 5;
const set1 = {if (val % 2 == 1) 0, if (val % 2 == 0) 1};
const set2 = {
  1,
  ...[2, 3],
  4
};
