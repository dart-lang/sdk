// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';

class CompletionState {
  /// The time budget for a completion request.
  Duration budgetDuration = CompletionBudget.defaultDuration;

  /// The next completion response id.
  int nextCompletionId = 0;

  /// The current request being processed or `null` if none.
  DartCompletionRequest? currentRequest;
}
