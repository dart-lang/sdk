// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

/// The set of compilation units that make up the mock 'vector_math' package.
final List<MockLibraryUnit> units = [_vectorMath64Unit, _matrix4Unit];

final _matrix4Unit = MockLibraryUnit('lib/matrix4.dart', r'''
part of 'vector_math_64.dart';

class Matrix4 {}
''');

final _vectorMath64Unit = MockLibraryUnit('lib/vector_math_64.dart', r'''
library vector_math_64;

part 'matrix4.dart';
''');
