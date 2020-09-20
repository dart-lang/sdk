// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that the default comparable function in JSArray.sort has a valid
/// strong-mode type.
void main() {
  new List<dynamic>.from(['1', '2']).sort();
}
