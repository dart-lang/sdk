// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

/// The result of attempting to resolve an identifier to a element.
class ResolutionResult {
  /// An instance that can be used anywhere that no element was found.
  static const ResolutionResult none =
      ResolutionResult._(_ResolutionResultState.none);

  /// An instance that can be used anywhere that multiple elements were found.
  static const ResolutionResult ambiguous =
      ResolutionResult._(_ResolutionResultState.ambiguous);

  /// The state of the result.
  final _ResolutionResultState state;

  /// The element that was found, or `null` if the [state] is not
  /// [_ResolutionResultState.single].
  final ExecutableElement element;

  /// Initialize a newly created result to represent resolving to a single
  /// [element].
  const ResolutionResult(this.element) : state = _ResolutionResultState.single;

  /// Initialize a newly created result with no element and the given [state].
  const ResolutionResult._(this.state) : element = null;

  /// Return `true` if this result represents the case where multiple ambiguous
  /// elements were found.
  bool get isAmbiguous => state == _ResolutionResultState.ambiguous;

  /// Return `true` if this result represents the case where no element was
  /// found.
  bool get isNone => state == _ResolutionResultState.none;

  /// Return `true` if this result represents the case where a single element
  /// was found.
  bool get isSingle => state == _ResolutionResultState.single;
}

/// The state of a [ResolutionResult].
enum _ResolutionResultState {
  /// Indicates that no element was found.
  none,

  /// Indicates that a single element was found.
  single,

  /// Indicates that multiple ambiguous elements were found.
  ambiguous
}
