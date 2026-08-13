// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

extension TypeParametersInScopeExtension on DartType? {
  /// Finds the type parameter declaration that [other] is bound to within this
  /// type when other is a [TypeParameterType].
  ///
  /// For example, given:
  /// ```dart
  /// class A<T> {}
  /// class B<S> {
  ///   void foo(A<S> a) {}
  /// }
  /// ```
  ///
  /// Then if we look for the type parameter corresponding to `S` within
  /// `A<S>`, we will find `T` from `A<T>`.
  ///
  /// If no corresponding type parameter can be found, `null` is returned.
  ///
  /// If two or more type arguments correspond to the same type parameter,
  /// `null` is also returned.
  TypeParameterType? typeParameterCorrespondingTo(DartType? other) {
    var self = this;
    if (self is! InterfaceType || other is! TypeParameterType) {
      return null;
    }
    int? parameterIndex;
    for (var (index, current) in self.typeArguments.indexed) {
      if (other.element == current.element) {
        if (parameterIndex != null) {
          // More than one match.
          return null;
        }
        parameterIndex = index;
      }
    }
    if (parameterIndex == null) return null;
    return self.element.typeParameters[parameterIndex].instantiate(
      nullabilitySuffix: other.nullabilitySuffix,
    );
  }
}
