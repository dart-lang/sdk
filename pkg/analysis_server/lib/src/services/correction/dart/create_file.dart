// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateFile extends CorrectionProducer {
  String _fileName = '';

  @override
  List<Object> get fixArguments => [_fileName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_FILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    if (node is SimpleStringLiteral) {
      var parent = node.parent;
      if (parent is NamespaceDirective) {
        // TODO(brianwilkerson) Support the case where the node's parent is a
        //  Configuration.
        var source = parent.referencedSource;
        if (source != null) {
          var fullName = source.fullName;
          var pathContext = resourceProvider.pathContext;
          if (pathContext.isAbsolute(fullName) &&
              file_paths.isDart(pathContext, fullName)) {
            await builder.addDartFileEdit(fullName, (builder) {
              builder.addSimpleInsertion(0, '// TODO Implement this library.');
            });
            _fileName = source.shortName;
          }
        }
      } else if (parent is PartDirective) {
        var source = parent.referencedSource;
        if (source != null) {
          var pathContext = resourceProvider.pathContext;
          var relativePath = pathContext.relative(
              unitResult.libraryElement.source.fullName,
              from: pathContext.dirname(source.fullName));

          // URIs always use forward slashes regardless of platform.
          var relativeUri = pathContext.split(relativePath).join('/');

          await builder.addDartFileEdit(source.fullName, (builder) {
            builder.addSimpleInsertion(0, "part of '$relativeUri';$eol$eol");
          });
          _fileName = source.shortName;
        }
      }
    }
  }
}
