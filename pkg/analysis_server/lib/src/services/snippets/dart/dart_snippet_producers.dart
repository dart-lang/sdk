// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/lint/linter.dart' show LinterContextImpl;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a top-level `main` function.
///
/// A `List<String> args` parameter will be included when generating inside a
/// file in `bin` or `tool` folders.
class DartMainFunctionSnippetProducer extends DartSnippetProducer {
  static const prefix = 'main';
  static const label = 'main()';

  DartMainFunctionSnippetProducer(DartSnippetRequest request) : super(request);

  /// Whether to insert a `List<String> args` parameter in the generated
  /// function.
  ///
  /// The parameter is suppressed for any known test directories.
  bool get _insertArgsParameter {
    final path = request.unit.path;
    return !LinterContextImpl.testDirectories
        .any((testDir) => path.contains(testDir));
  }

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);

    final typeProvider = request.unit.typeProvider;
    final listString = typeProvider.listType(typeProvider.stringType);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        builder.writeFunctionDeclaration(
          'main',
          returnType: VoidTypeImpl.instance,
          parameterWriter: _insertArgsParameter
              ? () => builder.writeParameter('args', type: listString)
              : null,
          bodyWriter: () {
            builder.writeln('{');
            builder.write('  ');
            builder.selectHere();
            builder.writeln();
            builder.write('}');
          },
        );
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a main function, used as an entry point.',
      builder.sourceChange,
    );
  }

  static DartMainFunctionSnippetProducer newInstance(
          DartSnippetRequest request) =>
      DartMainFunctionSnippetProducer(request);
}

abstract class DartSnippetProducer extends SnippetProducer {
  final AnalysisSessionHelper sessionHelper;

  DartSnippetProducer(DartSnippetRequest request)
      : sessionHelper = AnalysisSessionHelper(request.analysisSession),
        super(request);
}
