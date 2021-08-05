// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_runtime_metrics;

import 'dart:_js_helper' show fillLiteralMap, rawStartupMetrics;

/// A collection of metrics for events that happen before `main()` is entered.
///
/// The contents of the map depend on the platform. The map values are simple
/// objects (strings, numbers, Booleans). There is always an entry for the key
/// `'runtime'` with a [String] value.
///
/// This implementation for dart2js has the content (subject to change):
///
/// - `runtime`: `'dart2js'`
///
/// - `firstMs`: First `performance.now()` reading taken from the main.dart.js
///   file. This is the earliest time that the script is executing. The script
///   has already been loaded and parsed (otherwise the script load would fail)
///   and these earier events may be available from the `performance` API.
///
/// - `dartProgramMs`: `performance.now()` immediately inside the large function
///   with the name 'dartProgram' that wraps all the Dart code, before doing any
///   program setup actions.
///
/// - `callMainMs`: performance.now() just before calling main(), after doing
///   all program setup actions.
///
/// The injected code uses `Date.now()` if `performance.now()` is not defined.
Map<String, Object> get startupMetrics {
  final Map<String, Object> result = {'runtime': 'dart2js'};
  final raw = rawStartupMetrics();
  fillLiteralMap(raw, result);
  return result;
}
