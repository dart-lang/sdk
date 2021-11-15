// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class ColorSwatch<T> extends Color {
  const ColorSwatch(int primary, this._swatch) : super(primary);

  @protected
  final Map<T, Color> _swatch;

  Color operator [](T index) => _swatch[index];
}
