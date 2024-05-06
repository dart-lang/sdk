// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  const Chk(true & false, id: false);
  const Chk(true | false, id: true);
  const Chk(true ^ false, id: true);
  const Chk(2 < 2, id: false);
  const Chk(2 <= 2, id: true);
  const Chk(2 > 2, id: false);
  const Chk(2 >= 2, id: true);
}
class Chk {
  const Chk(Object? v, {required Object? id}) :
    assert(identical(v, id), "Not identical${(v, id: id)}");
}
