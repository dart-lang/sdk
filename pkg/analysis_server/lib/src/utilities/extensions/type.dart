// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Extensions for [DartType]s.
extension DartTypeExtensions on DartType {
  /// Return `true` if this type represents the class `Iterable` from
  /// `dart:core`.
  bool get isDartCoreIterable =>
      this is InterfaceType &&
      (this as InterfaceType).element.isDartCoreIterable;
}
