// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  void fn(_, _) {
    print(_);
  }

  fn(1, 2);

  try {
    throw '!';
  } on Exception catch (_, _) {
    print(_);
  } catch (_, _) {
    print(_);
  }
}
