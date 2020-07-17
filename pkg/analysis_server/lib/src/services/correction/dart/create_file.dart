// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateFile extends CorrectionProducer {
  String _fileName;

  @override
  List<Object> get fixArguments => [_fileName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_FILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    if (node is SimpleStringLiteral) {
      var parent = node.parent;
      if (parent is ImportDirective) {
        // TODO(brianwilkerson) Support the case where the node's parent is a
        //  Configuration.
        var source = parent.uriSource;
        if (source != null) {
          var fullName = source.fullName;
          if (resourceProvider.pathContext.isAbsolute(fullName) &&
              AnalysisEngine.isDartFileName(fullName)) {
            await builder.addDartFileEdit(fullName, (builder) {
              builder.addSimpleInsertion(0, '// TODO Implement this library.');
            });
            _fileName = source.shortName;
          }
        }
      } else if (parent is PartDirective) {
        var source = parent.uriSource;
        if (source != null) {
          var libName = resolvedResult.libraryElement.name;
          await builder.addDartFileEdit(source.fullName, (builder) {
            // TODO(brianwilkerson) Consider using the URI rather than name.
            builder.addSimpleInsertion(0, 'part of $libName;$eol$eol');
          });
          _fileName = source.shortName;
        }
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateFile newInstance() => CreateFile();
}
