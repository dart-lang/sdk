// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  if (x case == 1) {}
  if (x case == null) {}
  if (x case == 'foo'.length) {}
  if (x case != 1) {}
  if (x case != null) {}
  if (x case < 1) {}
  if (x case <= 1) {}
  if (x case > 1) {}
  if (x case >= 1) {}
}

main() {}
