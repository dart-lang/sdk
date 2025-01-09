// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure backends handle nested scopes with VariableDeclaration nodes that
// have the same 'name'.

void main() {
  for (final thing in [42.42, 'foo', Object()]) {
    if (thing case final double thing) {
      print('$thing is double');
    } else if (thing case final String thing) {
      print('$thing is String');
    } else if (thing case final Object thing) {
      print('$thing is Object');
    } else {
      throw '$thing is unknown ${thing.runtimeType}';
    }
  }
}
