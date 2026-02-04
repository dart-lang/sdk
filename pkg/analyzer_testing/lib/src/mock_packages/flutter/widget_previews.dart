// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

import 'widget_previews/widget_previews.dart';

/// The set of compilation units that make up the mock 'widget_previews' package.
final List<MockLibraryUnit> units = [
  _widgetPreviewsLibrary,
  widgetPreviewsWidgetPreviewsLibrary,
];

final _widgetPreviewsLibrary = MockLibraryUnit('lib/widget_previews.dart', r'''
export 'src/widget_previews/widget_previews.dart';
''');
