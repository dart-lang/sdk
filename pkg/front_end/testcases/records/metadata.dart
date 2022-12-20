// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class metadata<T> {
  const metadata();
}

// This is a syntax error because the <int> means there must be an argument list
// after it, but the NO_SPACE in metadatum prevents it from being parsed as such
// and the result is an error.

@metadata<int> (int, int) a = (42, 42);