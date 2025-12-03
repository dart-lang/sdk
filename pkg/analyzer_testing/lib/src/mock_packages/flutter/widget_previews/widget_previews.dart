// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetPreviewsWidgetPreviewsLibrary = MockLibraryUnit(
  'lib/src/widget_previews/widget_previews.dart',
  r'''
import 'package:flutter/material.dart' show Brightness;
import 'package:flutter/widgets.dart';

base class Preview {
  const Preview({
    this.name,
    Size? size,
    this.textScaleFactor,
    this.wrapper,
    this.theme,
    this.brightness,
  });

  final String? name;

  final double? textScaleFactor;

  final Widget Function(Widget)? wrapper;

  final PreviewThemeData Function()? theme;

  final Brightness? brightness;
}

base class PreviewThemeData {}
''',
);
