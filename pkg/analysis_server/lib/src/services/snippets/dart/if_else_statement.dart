// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates an if/else statement.
class IfElseStatement extends DartSnippetProducer {
  static const prefix = 'ife';
  static const label = 'ife';

  IfElseStatement(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    var builder = ChangeBuilder(session: request.analysisSession);
    var indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        void writeIndentedln(String string) =>
            builder.writeln('$indent$string');
        builder.write('if (');
        builder.addSimpleLinkedEdit('condition', 'condition');
        builder.writeln(') {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndentedln('} else {');
        writeIndentedln('  ');
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert an if/else statement.',
      builder.sourceChange,
    );
  }
}
