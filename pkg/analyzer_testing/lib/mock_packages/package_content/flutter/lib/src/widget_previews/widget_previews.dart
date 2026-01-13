// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' show Brightness;
import 'package:flutter/widgets.dart';

typedef PreviewTheme = PreviewThemeData Function();

typedef WidgetWrapper = Widget Function(Widget);

typedef PreviewLocalizations = PreviewLocalizationsData Function();

base class Preview {
  const Preview({
    String group = 'Default',
    String? name,
    Size? size,
    double? textScaleFactor,
    WidgetWrapper? wrapper,
    PreviewTheme? theme,
    Brightness? brightness,
    PreviewLocalizations? localizations,
  }) : this._required(
         group: group,
         name: name,
         size: size,
         textScaleFactor: textScaleFactor,
         wrapper: wrapper,
         theme: theme,
         brightness: brightness,
         localizations: localizations,
       );

  const Preview._required({
    required this.group,
    required this.name,
    required this.size,
    required this.textScaleFactor,
    required this.wrapper,
    required this.theme,
    required this.brightness,
    required this.localizations,
  });

  final String group;
  final String? name;
  final Size? size;
  final double? textScaleFactor;
  final WidgetWrapper? wrapper;
  final PreviewTheme? theme;
  final Brightness? brightness;
  final PreviewLocalizations? localizations;
}

base class PreviewThemeData {}
