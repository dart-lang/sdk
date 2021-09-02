// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart = 2.9

// This is a work-around for the automagically selecting weak/strong mode.
// By marking this file (the entry) as non-nnbd, it becomes weak mode which
// is required because many of the imports are not (yet) nnbd.

import 'unit_test_suites_impl.dart' as impl;

/// Work around https://github.com/dart-lang/sdk/issues/45192.
///
/// TODO(paulberry): once #45192 is fixed, we can switch the `import` directive
/// above to an `export` and remove this method, and this file will still be
/// considered by the analysis server to be runnable.
void main(List<String> args) {
  impl.main(args);
}
