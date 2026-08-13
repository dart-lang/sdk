// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

import 'animation/animation.dart';
import 'animation/animation_controller.dart';

/// The set of compilation units that make up the mock 'animation' component of
/// the 'flutter' package.
final List<MockLibraryUnit> units = [
  _animationLibrary,
  animationAnimationLibrary,
  animationAnimationControllerLibrary,
];

final _animationLibrary = MockLibraryUnit('lib/animation.dart', r'''
export 'src/animation/animation_controller.dart';
''');
