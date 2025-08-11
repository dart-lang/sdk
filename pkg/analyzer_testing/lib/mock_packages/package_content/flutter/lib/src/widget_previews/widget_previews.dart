// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' show Brightness;
import 'package:flutter/widgets.dart';

base class Preview {
  const Preview({
    this.name,
    this.width,
    this.height,
    this.textScaleFactor,
    this.wrapper,
    this.theme,
    this.brightness,
  });

  final String? name;
  final double? width;
  final double? height;
  final double? textScaleFactor;
  final Widget Function(Widget)? wrapper;
  final PreviewThemeData Function()? theme;
  final Brightness? brightness;
}

base class PreviewThemeData {}
