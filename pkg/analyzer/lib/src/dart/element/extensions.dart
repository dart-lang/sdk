// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

extension ParameterElementExtensions on ParameterElement {
  /// Return [ParameterElement] with the specified properties replaced.
  ParameterElement copyWith({DartType type, ParameterKind kind}) {
    return ParameterElementImpl.synthetic(
      name,
      type ?? this.type,
      // ignore: deprecated_member_use_from_same_package
      kind ?? this.parameterKind,
    )..isExplicitlyCovariant = isCovariant;
  }
}
