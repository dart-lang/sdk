// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';

import '../../generated/test_support.dart';

class ParserDiagnosticsTest {
  ExpectedError error(
    ErrorCode code,
    int offset,
    int length, {
    Pattern? correctionContains,
    String? text,
    List<Pattern> messageContains = const [],
    List<ExpectedContextMessage> contextMessages = const [],
  }) {
    return ExpectedError(
      code,
      offset,
      length,
      correctionContains: correctionContains,
      message: text,
      messageContains: messageContains,
      expectedContextMessages: contextMessages,
    );
  }

  ParseStringResult parseStringWithErrors(String content) {
    return parseString(
      content: content,
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: ExperimentStatus.currentVersion,
        flags: [
          Feature.enhanced_enums.enableString,
          Feature.super_parameters.enableString,
        ],
      ),
      throwIfDiagnostics: false,
    );
  }
}

extension ParseStringResultExtension on ParseStringResult {
  FindNode get findNode {
    return FindNode(content, unit);
  }

  void assertErrors(List<ExpectedError> expectedErrors) {
    var errorListener = GatheringErrorListener();
    errorListener.addAll(errors);
    errorListener.assertErrors(expectedErrors);
  }

  void assertNoErrors() {
    assertErrors(const []);
  }
}
