// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/formatter_options.dart'
    hide TrailingCommas;
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

extension FormatterOptionsExtension on FormatterOptions {
  /// The trailing commas preference converted from the analyzer enum to the
  /// dart_style enum.
  TrailingCommas? get dartStyleTrailingCommas {
    return switch (trailingCommas) {
      var trailingCommas? => TrailingCommas.values.firstWhereOrNull(
        (item) => item.name == trailingCommas.name,
      ),
      null => null,
    };
  }
}
