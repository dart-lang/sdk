// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';

/// A function that can be executed to create a refactoring producer.
typedef ProducerGenerator = RefactoringProducer Function(RefactoringContext);

class RefactoringProcessor {
  /// A list of the generators used to produce refactorings.
  static const Map<String, ProducerGenerator> generators = {
    MoveTopLevelToFile.commandName: MoveTopLevelToFile.new,
  };

  /// The context in which the refactorings could be applied.
  final RefactoringContext context;

  RefactoringProcessor(this.context);

  /// Return a list containing one code action for each of the refactorings that
  /// are available in the current context.
  Future<List<CodeAction>> compute() async {
    var refactorings = <CodeAction>[];
    for (var entry in RefactoringProcessor.generators.entries) {
      var generator = entry.value;
      var producer = generator(context);
      if (producer.isAvailable()) {
        refactorings.add(
          CodeAction(
              title: producer.title,
              kind: producer.kind,
              command: Command(
                command: entry.key,
                title: producer.title,
                arguments: [
                  {
                    'filePath': context.resolvedResult.path,
                    'selectionOffset': context.selectionOffset,
                    'selectionLength': context.selectionLength,
                    'arguments': producer.parameters
                        // Use toJson() to ensure values are always valid for
                        // JSON. Without this, defaultValues that are URIs will
                        // fail.
                        .map((param) => param.toJson())
                        .map((json) => json['defaultValue'])
                        .toList(),
                  }
                ],
              ),
              data: {
                'parameters': producer.parameters,
              }),
        );
      }
    }
    return refactorings;
  }
}
