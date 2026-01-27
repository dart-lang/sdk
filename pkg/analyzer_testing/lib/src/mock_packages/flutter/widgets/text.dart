// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsTextLibrary = MockLibraryUnit('lib/src/widgets/text.dart', r'''
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'basic.dart';
import 'framework.dart';
import 'inherited_theme.dart';

class DefaultTextStyle extends InheritedTheme {
  const DefaultTextStyle({
    super.key,
    required TextStyle style,
    ui.TextAlign? textAlign,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    int? maxLines,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
    required super.child,
  }) : assert(maxLines == null || maxLines > 0);
}

class Text extends StatelessWidget {
  /// The text to display.
  final String? data;

  final TextStyle? style;

  final ui.TextAlign? textAlign;

  final ui.TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  final bool? softWrap;

  final TextOverflow? overflow;

  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  final double? textScaleFactor;

  final int? maxLines;

  final String? semanticsLabel;

  final TextWidthBasis? textWidthBasis;

  const Text(
    String this.data, {
    super.key,
    this.style,
    ui.StrutStyle? strutStyle,
    this.textAlign,
    this.textDirection,
    ui.Locale? locale,
    this.softWrap,
    this.overflow,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    this.textScaleFactor,
    TextScaler? textScaler,
    this.maxLines,
    this.semanticsLabel,
    String? semanticsIdentifier,
    this.textWidthBasis,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.Color? selectionColor,
  }) : textSpan = null,
       assert(
         textScaler == null || textScaleFactor == null,
         'textScaleFactor is deprecated and cannot be specified when textScaler is specified.',
       );
}
''');
