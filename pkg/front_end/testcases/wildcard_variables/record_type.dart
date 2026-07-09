// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef R = (String _, String _);
(int _, int _) record = (1, 2);

main() {
  (int _, int _) localRecord = (1, 2);
  print(localRecord.$1);
  print(record.$1);
}
