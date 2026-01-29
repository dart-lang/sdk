// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/flutter/cupertino/colors.dart';
import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of compilation units that make up the mock 'cupertino' component of
/// the 'flutter' package.
final List<MockLibraryUnit> units = [cupertinoLibrary, cupertinoColorsLibrary];

final cupertinoLibrary = MockLibraryUnit('lib/cupertino.dart', r'''
export 'src/cupertino/colors.dart';
''');
