// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Exception thrown by a debug adapter when a request is not valid, either
/// because the inputs are not correct or the adapter is not in the correct
/// state.
class DebugAdapterException implements Exception {
  final String message;

  /// Whether or not to show the error to the user as a notification.
  final bool showToUser;

  DebugAdapterException(this.message, {this.showToUser = false});

  @override
  String toString() => 'DebugAdapterException: $message';
}

/// Exception thrown when failing to read arguments supplied by the user because
/// they are not the correct type.
///
/// This is usually because a user customised their launch configuration (for
/// example in `.vscode/launch.json` for VS Code) with values that are not
/// valid, such as putting a `String` in a field intended to be a `Map`:
///
/// ```
///     // Bad.
///     "env": "foo"
///
///     // Good.
///     "env": {
///         "FLUTTER_ROOT": "foo",
///     }
/// ```
class DebugAdapterInvalidArgumentException implements DebugAdapterException {
  final String requestName;
  final String argumentName;
  final Type expectedType;
  final Type actualType;
  final Object? actualValue;

  @override
  final bool showToUser;

  DebugAdapterInvalidArgumentException({
    required this.requestName,
    required this.argumentName,
    required this.expectedType,
    required this.actualType,
    required this.actualValue,
    this.showToUser = false,
  });

  @override
  String get message =>
      '"$argumentName" argument in $requestName configuration must be a '
      '$expectedType but provided value was a $actualType ($actualValue)';

  @override
  String toString() => 'DebugAdapterInvalidArgumentException: $message';
}
