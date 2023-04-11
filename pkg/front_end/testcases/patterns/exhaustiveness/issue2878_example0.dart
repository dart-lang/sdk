// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  List<int> list = [1, 2, 3];

  (switch (list) {
    [...] => 1,
  });

  (switch (list) {
    [] => 1,
    [_, ...] => 2,
  });

  (switch (list) {
    [] => 1,
    [_] => 2,
    [_, ..., _] => 3,
  });
}
