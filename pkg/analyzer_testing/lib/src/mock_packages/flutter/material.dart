// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final materialLibrary = MockLibraryUnit('lib/material.dart', r'''
export 'src/material/app_bar.dart';
export 'src/material/colors.dart';
export 'src/material/icons.dart';
export 'src/material/ink_well.dart';
export 'src/material/scaffold.dart';
export 'widgets.dart';
''');
