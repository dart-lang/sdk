// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E { a, b }

method(E e) {
  switch (e) {
    case E.a:
      return 0;
    case E.b:
      return 1;
  }
}
