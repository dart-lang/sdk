// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int f<A>() => switch (unknownName) {
      <A>[] => 1,
      <A>[var x, ...var xs] => 2,
    };

void main() {}
