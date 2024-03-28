// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';

class CompletionResponseForTesting {
  final int requestOffset;
  final String? requestLocationName;
  // TODO(scheglov): remove it when removing `OpType`.
  final String? opTypeLocationName;
  final int replacementOffset;
  final int replacementLength;
  final bool isIncomplete;
  final List<CompletionSuggestion> suggestions;

  CompletionResponseForTesting({
    required this.requestOffset,
    required this.requestLocationName,
    required this.opTypeLocationName,
    required this.replacementOffset,
    required this.replacementLength,
    required this.isIncomplete,
    required this.suggestions,
  });
}
