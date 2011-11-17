// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check compile-time constant library references with prefixes

#import("CTConst4Lib.dart", prefix:"mylib");

final A = mylib.B;

main() {
  Expect.equals(1, A);
}

