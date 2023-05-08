// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class InlineTypedef extends CorrectionProducer {
  String _name = '';

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  List<Object> get fixArguments => [_name];

  @override
  FixKind get fixKind => DartFixKind.INLINE_TYPEDEF;

  @override
  FixKind get multiFixKind => DartFixKind.INLINE_TYPEDEF_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;

    //
    // Extract the information needed to build the edit.
    //
    TypeAnnotation? returnType;
    TypeParameterList? typeParameters;
    List<FormalParameter> parameters;
    if (node is FunctionTypeAlias) {
      returnType = node.returnType;
      _name = node.name.lexeme;
      typeParameters = node.typeParameters;
      parameters = node.parameters.parameters;
    } else if (node is GenericTypeAlias) {
      if (node.typeParameters != null) {
        return;
      }
      var functionType = node.functionType;
      if (functionType == null) {
        return;
      }
      returnType = functionType.returnType;
      _name = node.name.lexeme;
      typeParameters = functionType.typeParameters;
      parameters = functionType.parameters.parameters;
    } else {
      return;
    }
    // TODO(brianwilkerson) Handle parts.
    var finder = _ReferenceFinder(_name);
    unit.accept(finder);
    var reference = finder.reference;
    if (reference == null || finder.count != 1) {
      return;
    }
    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(utils.getLinesRange(range.node(node)));
      builder.addReplacement(range.node(reference), (builder) {
        if (returnType != null) {
          builder.write(utils.getNodeText(returnType));
          builder.write(' ');
        }
        builder.write('Function');
        if (typeParameters != null) {
          builder.write(utils.getNodeText(typeParameters));
        }
        String? groupEnd;
        builder.write('(');
        for (var i = 0; i < parameters.length; i++) {
          var parameter = parameters[i];
          if (i > 0) {
            // This intentionally drops any trailing comma in order to improve
            // formatting.
            builder.write(', ');
          }
          if (parameter is DefaultFormalParameter) {
            if (groupEnd == null) {
              if (parameter.isNamed) {
                groupEnd = '}';
                builder.write('{');
              } else {
                groupEnd = ']';
                builder.write('[');
              }
            }
            parameter = parameter.parameter;
          }
          if (parameter is FunctionTypedFormalParameter) {
            builder.write(utils.getNodeText(parameter));
          } else if (parameter is SimpleFormalParameter) {
            if (parameter.metadata.isNotEmpty) {
              builder
                  .write(utils.getRangeText(range.nodes(parameter.metadata)));
            }
            if (parameter.requiredKeyword != null) {
              builder.write('required ');
            }
            if (parameter.covariantKeyword != null) {
              builder.write('covariant ');
            }
            var keyword = parameter.keyword;
            if (keyword != null && keyword.type != Keyword.VAR) {
              builder.write(keyword.lexeme);
            }
            var typeAnnotation = parameter.type;
            if (typeAnnotation == null) {
              builder.write('dynamic');
            } else {
              builder.write(utils.getNodeText(typeAnnotation));
            }
            if (parameter.isNamed) {
              var identifier = parameter.name;
              if (identifier != null) {
                builder.write(' ');
                builder.write(identifier.lexeme);
              }
            }
          }
        }
        if (groupEnd != null) {
          builder.write(groupEnd);
        }
        builder.write(')');
      });
    });
  }
}

class _ReferenceFinder extends RecursiveAstVisitor<void> {
  final String typeName;

  NamedType? reference;

  int count = 0;

  _ReferenceFinder(this.typeName);

  @override
  void visitNamedType(NamedType node) {
    if (node.name2.lexeme == typeName) {
      reference ??= node;
      count++;
    }
    super.visitNamedType(node);
  }
}
