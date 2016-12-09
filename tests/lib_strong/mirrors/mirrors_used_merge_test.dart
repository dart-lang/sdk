// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that two MirrorsUsed annotations can be merged with out crashing
/// dart2js.

@MirrorsUsed(symbols: const ['foo'])
@MirrorsUsed(symbols: const ['bar'])
import 'dart:mirrors';

main() {
  // Do nothing, just make sure that merging the annotations doesn't crash
  // dart2js.
}
