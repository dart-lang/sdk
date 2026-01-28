// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

import 'foundation/assertions.dart';
import 'foundation/change_notifier.dart';
import 'foundation/constants.dart';
import 'foundation/diagnostics.dart';
import 'foundation/key.dart';
import 'foundation/print.dart';

/// The set of compilation units that make up the mock 'foundation' component of
/// the 'flutter' package.
final List<MockLibraryUnit> units = [
  _foundationLibrary,
  foundationAssertionsLibrary,
  foundationChangeNotifierLibrary,
  foundationConstantsLibrary,
  foundationDiagnosticsLibrary,
  foundationKeyLibrary,
  foundationPrintLibrary,
];

final _foundationLibrary = MockLibraryUnit('lib/foundation.dart', r'''
export 'package:meta/meta.dart'
    show
        immutable,
        mustCallSuper,
        optionalTypeArgs,
        protected,
        required,
        visibleForTesting;

export 'src/foundation/assertions.dart';
export 'src/foundation/change_notifier.dart';
export 'src/foundation/constants.dart';
export 'src/foundation/diagnostics.dart';
export 'src/foundation/key.dart';
export 'src/foundation/print.dart';
''');
