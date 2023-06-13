// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/refactoring/convert_formal_parameters.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';

/// A function that can be executed to create a refactoring producer.
typedef ProducerGenerator = RefactoringProducer Function(RefactoringContext);

class RefactoringProcessor {
  /// A list of the generators used to produce refactorings.
  static const Map<String, ProducerGenerator> generators = {
    ConvertFormalParametersToNamed.commandName:
        ConvertFormalParametersToNamed.new,
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

      if (producer.isExperimental && !context.includeExperimental) {
        continue;
      }

      final isAvailable = await producer.isAvailable();
      if (!isAvailable) {
        continue;
      }

      var parameters = producer.parameters;
      // In debug mode, throw if we produced a refactoring that has parameters
      // without default values that are not supported by the client.
      assert(
        () {
          return parameters.every((parameter) =>
              parameter.defaultValue != null ||
              producer.supportsCommandParameter(parameter.kind));
        }(),
        '${producer.title} refactor returned parameters without defaults '
        'that are not supported by the client',
      );

      refactorings.add(
        CodeAction(
            title: producer.title,
            kind: producer.kind,
            command: Command(
              command: entry.key,
              title: producer.title,
              arguments: [
                {
                  'filePath': context.resolvedUnitResult.path,
                  'selectionOffset': context.selectionOffset,
                  'selectionLength': context.selectionLength,
                  'arguments':
                      parameters.map((param) => param.defaultValue).toList(),
                }
              ],
            ),
            data: {
              'parameters': parameters,
            }),
      );
    }
    return refactorings;
  }
}
