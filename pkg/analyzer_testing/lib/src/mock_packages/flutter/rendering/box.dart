// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final renderingBoxLibrary = MockLibraryUnit('lib/src/rendering/box.dart', r'''
import 'object.dart';

class BoxConstraints extends Constraints {}
''');
