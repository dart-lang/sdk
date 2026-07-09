// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/expected_diagnostics.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../util/diff.dart';
import '../dart/resolution/node_text_expectations.dart';

class PubspecDiagnosticTest with ResourceProviderMixin {
  /// Assert that pubspec validator diagnostics match the inline diagnostic
  /// markers in [content].
  void assertDiagnostics(String content) {
    var cleanContent = removeDiagnosticExpectations(content);
    var diagnostics = _validate(cleanContent);
    var actual = updateExpectedDiagnostics(
      content: cleanContent,
      actualDiagnostics: diagnostics,
    );
    if (actual != content) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(content, actual);
      }
      fail('See the difference above.');
    }
  }

  List<Diagnostic> _validate(String content) {
    var pubspecFile = newFile('/sample/pubspec.yaml', content);
    var source = FileSource(pubspecFile);
    YamlNode node = loadYamlNode(content);
    return validatePubspec(
      contents: node,
      source: source,
      provider: resourceProvider,
      // TODO(sigurdm): Can/should we pass analysisOptions here?
    );
  }
}
