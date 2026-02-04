// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/flutter/material/app_bar.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/material/button.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/material/colors.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/material/icons.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/material/ink_well.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/material/scaffold.dart';
import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of compilation units that make up the mock 'material' component of
/// the 'flutter' package.
final List<MockLibraryUnit> units = [
  materialLibrary,
  materialAppBarLibrary,
  materialButtonLibrary,
  materialColorsLibrary,
  materialIconsLibrary,
  materialInkWellLibrary,
  materialScaffoldLibrary,
];

final materialLibrary = MockLibraryUnit('lib/material.dart', r'''
export 'src/material/app_bar.dart';
export 'src/material/button.dart';
export 'src/material/colors.dart';
export 'src/material/icons.dart';
export 'src/material/ink_well.dart';
export 'src/material/scaffold.dart';
export 'widgets.dart';
''');
