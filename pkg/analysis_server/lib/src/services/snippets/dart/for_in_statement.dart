// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a `for in` loop.
class ForInStatement extends DartSnippetProducer {
  static const prefix = 'forin';
  static const label = 'for in';

  ForInStatement(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    var builder = ChangeBuilder(
      session: request.analysisSession,
      eol: utils.endOfLine,
    );
    var indent = utils.getLinePrefix(request.offset);
    var varOrFinal = codeStyleOptions.makeLocalsFinal ? 'final' : 'var';

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write('for ($varOrFinal ');
        builder.addSimpleLinkedEdit('elementName', 'element');
        builder.write(' in ');
        builder.addSimpleLinkedEdit('collectionName', 'collection');
        builder.writeln(') {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a for-in loop.',
      builder.sourceChange,
    );
  }
}
