// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method(o) {
  switch (o) {
    case [var /*
     joinedIntermediate,
     name=a
    */a] when a > 5:
    case [_, var /*
     joinedIntermediate,
     name=a
    */a] when a < 5:
      print(a);
  }
}