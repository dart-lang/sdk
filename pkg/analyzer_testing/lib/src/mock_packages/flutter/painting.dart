// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingLibrary = MockLibraryUnit('lib/painting.dart', r'''
export 'src/painting/alignment.dart';
export 'src/painting/basic_types.dart';
export 'src/painting/border_radius.dart';
export 'src/painting/borders.dart';
export 'src/painting/box_border.dart';
export 'src/painting/box_decoration.dart';
export 'src/painting/colors.dart';
export 'src/painting/decoration.dart';
export 'src/painting/edge_insets.dart';
export 'src/painting/text_painter.dart';
export 'src/painting/text_style.dart';
''');
