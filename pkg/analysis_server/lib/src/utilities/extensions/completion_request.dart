// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

extension DartCompletionRequestExtensions on DartCompletionRequest {
  /// Return `true` if the constructor tear-offs feature is enabled, and the
  /// context type is a function type that matches an instantiation of the
  /// [element].
  ///
  // TODO(scheglov): Validate that suggesting a tear-off instead of invocation
  // is statistically a good choice.
  bool shouldSuggestTearOff(InterfaceElement2 element) {
    if (!libraryElement.featureSet.isEnabled(Feature.constructor_tearoffs)) {
      return false;
    }

    var contextType = this.contextType;
    if (contextType is! FunctionType) {
      return false;
    }

    var bottomInstance = element.instantiate(
      typeArguments: List.filled(
        element.typeParameters2.length,
        libraryElement.typeProvider.neverType,
      ),
      nullabilitySuffix: NullabilitySuffix.none,
    );

    return libraryElement.typeSystem.isSubtypeOf(
      bottomInstance,
      contextType.returnType,
    );
  }

  /// Return `true` if the constructor tear-offs feature is enabled, and the
  /// context type is a function type that matches an instantiation of the
  /// [element].
  ///
  // TODO(scheglov): Validate that suggesting a tear-off instead of invocation
  // is statistically a good choice.
  bool shouldSuggestTearOff2(InterfaceElement2 element) =>
      shouldSuggestTearOff(element);
}
