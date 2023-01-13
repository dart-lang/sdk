// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  final x = (1,2);
  print(switch (x) { var _ => 1 });

  print(switch ((1, 2)) { var _ => 1});
}
