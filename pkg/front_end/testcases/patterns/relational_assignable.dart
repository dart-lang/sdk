// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method(int i) {
  const dynamic d = 0;
  const dynamic s = '';
  return switch (i) {
    < d => 0,
    > s => 1,
    _ => 2,
  };
}
