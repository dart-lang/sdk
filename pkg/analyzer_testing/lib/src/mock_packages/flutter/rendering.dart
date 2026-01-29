// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final renderingLibrary = MockLibraryUnit('lib/rendering.dart', r'''
export 'package:vector_math/vector_math.dart';

export 'painting.dart';
export 'src/rendering/box.dart';
export 'src/rendering/flex.dart';
export 'src/rendering/object.dart';
''');
