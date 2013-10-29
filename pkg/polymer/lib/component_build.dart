// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** This library is deprecated. Please use `builder.dart` instead. */
@deprecated
library build_utils;

import 'dart:async';
import 'package:meta/meta.dart';

import 'builder.dart' as builder;

/**
 * This function is deprecated. Please use `build` from `builder.dart`
 * instead.
 */
@deprecated
Future build(List<String> arguments, List<String> entryPoints,
    {bool printTime: true, bool shouldPrint: true}) {
  return builder.build(
      entryPoints: entryPoints, options: builder.parseOptions(arguments));
}
