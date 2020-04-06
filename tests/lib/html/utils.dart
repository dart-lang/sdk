// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The test runner for DDC does not handle tests that import files using
/// relative imports that reach outside of the directory containing the test
/// (i.e. "../" imports). Since tests both in this directory and in "custom/"
/// use utils.dart, it needs to be accessible from both places.
///
/// We could have every test outside of "custom/" import "custom/utils.dart",
/// but that feels weird since "utils.dart" doesn't have anything to do with
/// custom elements.
///
/// Instead, it lives there, but is exported from here for the tests in this
/// directory to import.
// TODO(rnystrom): If the DDC test runner is fixed to use a different module
// root that handles "../" imports, move "custom/utils.dart" to here.
export 'custom/utils.dart';
