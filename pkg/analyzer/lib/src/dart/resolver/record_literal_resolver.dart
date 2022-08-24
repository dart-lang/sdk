// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [RecordLiteral]s.
class RecordLiteralResolver {
  final ResolverVisitor _resolver;

  RecordLiteralResolver({
    required ResolverVisitor resolver,
  }) : _resolver = resolver;

  ErrorReporter get errorReporter => _resolver.errorReporter;

  /// Report any named fields in the record literal [node] that use a previously
  /// defined name.
  void reportDuplicateFieldDefinitions(RecordLiteralImpl node) {
    var fields = node.fields;
    var usedNames = <String, NamedExpression>{};
    for (var field in fields) {
      if (field is NamedExpression) {
        var nameNode = field.name.label;
        var name = nameNode.name;
        var previousField = usedNames[name];
        if (previousField != null) {
          errorReporter.reportError(DiagnosticFactory()
              .duplicateFieldDefinition(
                  errorReporter.source, field, previousField));
        } else {
          usedNames[name] = field;
        }
      }
    }
  }

  void resolve(RecordLiteralImpl node, {required DartType? contextType}) {
    // TODO(brianwilkerson) Move resolution from the `visitRecordLiteral`
    //  methods of `ResolverVisitor` and `StaticTypeAnalyzer` to this class.
  }
}
