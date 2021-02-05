// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/30002.
///
/// The compiler used to keep all metadata (other than type information) in one
/// global table that was shipped with the main output unit.  For most metadata
/// this was OK because it was refering to strings and other simple constants.
/// However, we also allow to refer to tear-offs of top-level functions. When
/// that top-level function was assigned to a deferred fragment, the metadata
/// initialization would simply fail.
import 'default_arg_is_tearoff_lib.dart' deferred as lib;

main() => lib.loadLibrary().then((_) {
      // Call via Function.apply to ensure he metadata is generated
      Function.apply(lib.myFunction, []);
    });
