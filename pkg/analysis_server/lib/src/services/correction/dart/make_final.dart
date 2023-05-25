// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeFinal extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.MAKE_FINAL;

  @override
  FixKind get multiFixKind => DartFixKind.MAKE_FINAL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    final parent = node.parent;

    if (node is DeclaredIdentifier && parent is ForEachPartsWithDeclaration) {
      await builder.addDartFileEdit(file, (builder) {
        var keyword = node.keyword;
        if (keyword != null && keyword.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        } else if (keyword == null) {
          builder.addSimpleInsertion(node.offset, 'final ');
        }
      });
      return;
    }

    if (node is SimpleFormalParameter) {
      await builder.addDartFileEdit(file, (builder) {
        final keyword = node.keyword;
        if (keyword != null && keyword.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        } else {
          final type = node.type;
          if (type != null) {
            builder.addSimpleInsertion(type.offset, 'final ');
            return;
          }
          final identifier = node.name;
          if (identifier != null) {
            builder.addSimpleInsertion(identifier.offset, 'final ');
          } else {
            builder.addSimpleInsertion(node.offset, 'final ');
          }
        }
      });
      return;
    }

    if (node is PatternVariableDeclaration) {
      await builder.addDartFileEdit(file, (builder) {
        var keyword = node.keyword;
        if (keyword.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        }
      });
      return;
    }

    if (node is DartPattern) {
      var parent = node.parent;
      if (parent is ForEachPartsWithPattern) {
        await builder.addDartFileEdit(file, (builder) {
          var keyword = parent.keyword;
          if (keyword.keyword == Keyword.VAR) {
            builder.addSimpleReplacement(range.token(keyword), 'final');
          }
        });
        return;
      }
    }

    if (node is DeclaredVariablePattern) {
      var keyword = node.keyword;
      if (keyword == null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(node.offset, 'final ');
        });
      } else if (node.type == null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        });
      }
      return;
    }

    final list = _getVariableDeclarationList(node);
    if (list != null && list.variables.length == 1) {
      await builder.addDartFileEdit(file, (builder) {
        var keyword = list.keyword;
        var lateKeyword = list.lateKeyword;
        if (keyword != null && keyword.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        } else if (lateKeyword != null) {
          builder.addSimpleInsertion(lateKeyword.end, ' final');
        } else if (keyword == null) {
          builder.addSimpleInsertion(list.offset, 'final ');
        }
      });
    }
  }

  static VariableDeclarationList? _getVariableDeclarationList(AstNode node) {
    if (node is VariableDeclarationList) {
      return node;
    }

    final parent = node.parent;
    if (node is VariableDeclaration && parent is VariableDeclarationList) {
      return parent;
    }

    if (node is NamedType && parent is VariableDeclarationList) {
      return parent;
    }

    final parent2 = parent?.parent;
    if (parent is NamedType && parent2 is VariableDeclarationList) {
      return parent2;
    }

    return null;
  }
}
