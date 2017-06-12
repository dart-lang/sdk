// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  print("" as String);
  print(1 as int);
  print(1.0 as double);

  print("" is String);
  print("" is int);
  print("" is double);

  print(1 is String);
  print(1 is int);
  print(1 is double);

  print(1.0 is String);
  print(1.0 is int);
  print(1.0 is double);
}
