// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test() {
  // Zero parameters.
  1.() {};

  // Multiple parameters.
  1.(a, b) {};

  // An optional positional parameter.
  1.([a]) {};

  // An optional named parameter.
  1.({a}) {};

  // A required named parameter.
  1.({required a}) {};

  // Zero parameters.
  1.() => 0;

  // Multiple parameters.
  1.(a, b) => 0;

  // An optional positional parameter.
  1.([a]) => 0;

  // An optional named parameter.
  1.({a}) => 0;

  // A required named parameter.
  1.({required a}) => 0;
}
