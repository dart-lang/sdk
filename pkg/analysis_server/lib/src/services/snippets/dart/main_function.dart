// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a top-level `main` function.
///
/// A `List<String> args` parameter will be included when generating inside a
/// file in `bin` or `tool` folders.
class MainFunction extends DartSnippetProducer {
  static const prefix = 'main';
  static const label = 'main()';

  MainFunction(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  /// Whether to insert a `List<String> args` parameter in the generated
  /// function.
  ///
  /// The parameter is suppressed for any known test directories.
  bool get _insertArgsParameter => !isInTestDirectory;

  @override
  Future<Snippet> compute() async {
    var builder = ChangeBuilder(session: request.analysisSession);

    var typeProvider = request.unit.typeProvider;
    var listString = typeProvider.listType(typeProvider.stringType);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        builder.writeFunctionDeclaration(
          'main',
          returnType: VoidTypeImpl.instance,
          parameterWriter:
              _insertArgsParameter
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
}
