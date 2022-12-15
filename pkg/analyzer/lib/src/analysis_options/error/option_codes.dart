// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

export 'package:analyzer/src/analysis_options/error/option_codes.g.dart';

class AnalysisOptionsHintCode extends ErrorCode {
  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsHintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'AnalysisOptionsHintCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.HINT;
}
