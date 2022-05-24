// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ExecutionContext {
  /// The next execution context identifier to be returned.
  int nextContextId = 0;

  /// A table mapping execution context id's to the root of the context.
  final Map<String, String> contextMap = {};

  /// Initialize a newly created execution context.
  ExecutionContext();
}
