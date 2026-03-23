// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetPreviewsWidgetPreviewsLibrary = MockLibraryUnit(
  'lib/src/widget_previews/widget_previews.dart',
  r'''
import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart' show Brightness, ThemeData;
import 'package:flutter/widgets.dart';

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

  @mustCallSuper
  Preview transform() => this;

  PreviewBuilder toBuilder() => PreviewBuilder._fromPreview(this);
}

abstract base class MultiPreview {
  const MultiPreview();

  List<Preview> get previews;

  @mustCallSuper
  List<Preview> transform() => previews.map((Preview e) => e.transform()).toList();
}

final class PreviewBuilder {
  PreviewBuilder();

  PreviewBuilder._fromPreview(Preview preview)
    : group = preview.group,
      name = preview.name,
      size = preview.size,
      textScaleFactor = preview.textScaleFactor,
      wrapper = preview.wrapper,
      theme = preview.theme,
      brightness = preview.brightness,
      localizations = preview.localizations;

  String? group;

  String? name;

  Size? size;

  double? textScaleFactor;

  WidgetWrapper? wrapper;

  void addWrapper(WidgetWrapper newWrapper) {
    final WidgetWrapper? wrapperLocal = wrapper;
    if (wrapperLocal != null) {
      wrapper = (Widget widget) => newWrapper(wrapperLocal(widget));
      return;
    }
    wrapper = newWrapper;
  }

  PreviewTheme? theme;

  Brightness? brightness;

  PreviewLocalizations? localizations;

  Preview build() {
    return Preview._required(
      group: group ?? 'Default',
      name: name,
      size: size,
      textScaleFactor: textScaleFactor,
      wrapper: wrapper,
      theme: theme,
      brightness: brightness,
      localizations: localizations,
    );
  }
}

base class PreviewLocalizationsData {
  const PreviewLocalizationsData({
    this.locale,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
  });

  final Locale? locale;

  final Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates;

  final LocaleListResolutionCallback? localeListResolutionCallback;

  final LocaleResolutionCallback? localeResolutionCallback;
}

base class PreviewThemeData {
  const PreviewThemeData({
    this.materialLight,
    this.materialDark,
    this.cupertinoLight,
    this.cupertinoDark,
  });

  final ThemeData? materialLight;
  final ThemeData? materialDark;

  final CupertinoThemeData? cupertinoLight;
  final CupertinoThemeData? cupertinoDark;

  (ThemeData?, CupertinoThemeData?) themeForBrightness(Brightness brightness) {
    if (brightness == Brightness.light) {
      return (materialLight, cupertinoLight);
    }
    return (materialDark, cupertinoDark);
  }
}
''',
);
