// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

class PubspecDiagnosticTest with ResourceProviderMixin {
  late Source _source;

  /// Assert that when the validator is used on the given [content] the
  /// [expectedErrorCodes] are produced.
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    YamlNode node = loadYamlNode(content);
    if (node is! YamlMap) {
      // The file is empty.
      node = YamlMap();
    }
    GatheringErrorListener listener = GatheringErrorListener();
    listener.addAll(validatePubspec(
      contents: node.nodes,
      source: _source,
      provider: resourceProvider,
    ));
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(String content) {
    assertErrors(content, []);
  }

  @mustCallSuper
  void setUp() {
    _source = getFile('/sample/pubspec.yaml').createSource();
  }
}
