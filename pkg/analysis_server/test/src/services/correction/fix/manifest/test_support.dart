// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/protocol_server.dart' show SourceEdit;
import 'package:analysis_server/src/services/correction/fix/manifest/fix_generator.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/manifest/manifest_values.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

/// A base class providing utility methods for tests of fixes associated with
/// errors in Android manifest files.
class ManifestFixTest with ResourceProviderMixin {
  Future<void> assertHasFix(
      String initialContent, String expectedContent) async {
    List<Fix> fixes = await _getFixes(initialContent);
    expect(fixes, hasLength(1));
    List<SourceFileEdit> fileEdits = fixes[0].change.edits;
    expect(fileEdits, hasLength(1));

    String actualContent =
        SourceEdit.applySequence(initialContent, fileEdits[0].edits);
    expect(actualContent, expectedContent);
  }

  Future<void> assertHasNoFix(String initialContent) async {
    List<Fix> fixes = await _getFixes(initialContent);
    expect(fixes, hasLength(0));
  }

  Future<List<Fix>> _getFixes(String content) {
    File manifestFile = getFile('/package/AndroidManifest.xml');
    DocumentFragment document =
        parseFragment(content, container: MANIFEST_TAG, generateSpans: true);
    expect(document, isNotNull);
    ManifestValidator validator =
        ManifestValidator(manifestFile.createSource());
    List<engine.AnalysisError> errors = validator.validate(content, true);
    expect(errors, hasLength(1));
    engine.AnalysisError error = errors[0];
    ManifestFixGenerator generator =
        ManifestFixGenerator(error, content, document);
    return generator.computeFixes();
  }
}
