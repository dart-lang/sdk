// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a switch expression.
class SwitchExpression extends DartSnippetProducer {
  static const prefix = 'switch';
  static const label = 'switch expression';

  SwitchExpression(super.request, {required super.elementImportCache});

  @override
  String get snippetPrefix => prefix;

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write('switch (');
        builder.addSimpleLinkedEdit('expression', 'expression');
        builder.writeln(') {');
        writeIndented('  ');
        builder.addSimpleLinkedEdit('pattern', 'pattern');
        builder.write(' => ');
        builder.addSimpleLinkedEdit('value', 'value');
        builder.write(',');
        builder.selectHere();
        builder.writeln();
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a switch expression.',
      builder.sourceChange,
    );
  }
}
