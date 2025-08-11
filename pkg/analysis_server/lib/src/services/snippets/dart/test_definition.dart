// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/// Produces a [Snippet] that creates a `test()` block.
class TestDefinition extends DartSnippetProducer with TestSnippetMixin {
  static const prefix = 'test';
  static const label = 'test';

  TestDefinition(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    var builder = ChangeBuilder(
      session: request.analysisSession,
      eol: utils.endOfLine,
    );
    var indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) async {
      await addRequiredImports(builder);
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write("test('");
        builder.addSimpleLinkedEdit('testName', 'test name');
        builder.writeln("', () {");
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('});');
      });
    });

    return Snippet(prefix, label, 'Insert a test block.', builder.sourceChange);
  }

  @override
  Future<bool> isValid() async {
    return await super.isValid() && isInTestDirectory;
  }
}

mixin TestSnippetMixin {
  final _flutterTestUri = Uri.parse('package:flutter_test/flutter_test.dart');

  final _dartTestUri = Uri.parse('package:test/test.dart');

  AnalysisSessionHelper get sessionHelper;

  /// Adds imports for `test`/`group` if required.
  ///
  /// Both 'package:test' and 'package:flutter_test' are checked because Flutter
  /// projects can use either and we don't want to add the other.
  Future<void> addRequiredImports(DartFileEditBuilder builder) async {
    if (builder.importsLibrary(_dartTestUri) ||
        builder.importsLibrary(_flutterTestUri)) {
      return;
    }

    var testUri = await getTestLibraryUri();
    builder.importLibrary(testUri);
  }

  /// Gets the URI for the test library to import depending on whether
  /// flutter_test is available or not.
  Future<Uri> getTestLibraryUri() async {
    var flutterTest = await sessionHelper.session.getLibraryByUri(
      _flutterTestUri.toString(),
    );

    return flutterTest is LibraryElementResult ? _flutterTestUri : _dartTestUri;
  }
}
