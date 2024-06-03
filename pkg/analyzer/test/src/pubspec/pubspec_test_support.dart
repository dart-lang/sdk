// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

class PubspecDiagnosticTest with ResourceProviderMixin {
  /// Assert that when the validator is used on the given [content] the
  /// [expectedErrorCodes] are produced.
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    var pubspecFile = newFile('/sample/pubspec.yaml', content);
    var source = FileSource(pubspecFile);
    YamlNode node = loadYamlNode(content);
    GatheringErrorListener listener = GatheringErrorListener();
    listener.addAll(validatePubspec(
      contents: node,
      source: source,
      provider: resourceProvider,
      // TODO(sigurdm): Can/should we pass analysisOptions here?
    ));
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(String content) {
    assertErrors(content, []);
  }
}
