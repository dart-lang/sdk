// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../../models.dart';
import '../api.dart';
import '../executable_declarations.dart';
import '../kinds.dart';

/// Remove the last formal parameter in the declaration's parameter list (by
/// source order). Fails if the list is empty. This intentionally does *not*
/// update call sites; diagnostics will increase.
class RemoveLastFormalParameterMutation extends Mutation {
  final int targetDeclarationOffset;

  RemoveLastFormalParameterMutation({
    required super.path,
    required this.targetDeclarationOffset,
  });

  @override
  MutationKind get kind => MutationKind.removeLastFormalParameter;

  @override
  MutationResult apply(CompilationUnit unit, String content) {
    var executables = CollectExecutablesVisitor.collectFrom(unit);

    var owner = executables.singleWhere((executable) {
      return executable.declarationOffset == targetDeclarationOffset;
    });

    var formalParameterList = owner.formalParameters!;
    var (deleteStart, deleteEnd) = _deletionForLast(formalParameterList);

    return MutationResult(
      MutationEdit(deleteStart, deleteEnd - deleteStart, ''),
      {'kind': 'remove_last_formal_parameter'},
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {'target_declaration_offset': targetDeclarationOffset};
  }

  /// Compute the exact deletion range to remove the *last* formal parameter
  /// while keeping the formal parameter list syntactically valid.
  ///
  /// Handles:
  /// - trailing comma after the last formal parameter: delete "last,"
  /// - no trailing comma: delete ",last" using the comma after the previous
  ///   formal parameter
  /// - if the last formal parameter is the only one inside `{}` or `[]`,
  ///   delete the whole optional group, including a preceding separator comma
  ///   (if any) and a top-level trailing comma right after the closing `}` or
  ///   `]` (if any).
  ///
  /// Order matters: handle the "only param inside optional group" case first,
  /// then the trailing-comma fast path, then the generic comma-before-last case.
  (int start, int end) _deletionForLast(
    FormalParameterList formalParameterList,
  ) {
    var formalParameters = formalParameterList.parameters;
    var last = formalParameters.last;

    // If the last formal parameter is the only one inside an optional group
    // ({...} or [...]), delete the whole group, including a preceding
    // separator comma (if any) and a top-level trailing comma right after
    // the group (if any).
    var ld = formalParameterList.leftDelimiter;
    var rd = formalParameterList.rightDelimiter;
    if (ld != null && rd != null) {
      bool insideGroup(FormalParameter p) {
        return p.beginToken.offset >= ld.end && p.end <= rd.offset;
      }

      var firstInGroup = formalParameters.indexWhere(insideGroup);
      var lastInGroup = formalParameters.lastIndexWhere(insideGroup);
      var onlyInGroup =
          firstInGroup != -1 &&
          firstInGroup == lastInGroup &&
          identical(formalParameters[lastInGroup], last);

      if (onlyInGroup) {
        // Include the separator comma before the group if there are formal
        // parameters before it.
        Token? sepComma;
        if (firstInGroup > 0) {
          var prev = formalParameters[firstInGroup - 1];
          var comma = prev.endToken.next;
          if (comma != null && comma.type == TokenType.COMMA) {
            sepComma = comma;
          }
        }
        var start = sepComma?.offset ?? ld.offset;

        // Also remove a top-level trailing comma after '}' or ']' if present.
        Token endTok = rd;
        var afterGroup = rd.next;
        if (afterGroup != null && afterGroup.type == TokenType.COMMA) {
          endTok = afterGroup;
        }
        return (start, endTok.end);
      }
    }

    // Trailing comma after the last param -> delete "last,"
    var afterLast = last.endToken.next;
    if (afterLast != null && afterLast.type == TokenType.COMMA) {
      return (last.beginToken.offset, afterLast.end);
    }

    // No trailing comma: delete ",last" using the comma after the previous.
    if (formalParameters.length >= 2) {
      var prev = formalParameters[formalParameters.length - 2];
      var comma = prev.endToken.next;
      if (comma != null && comma.type == TokenType.COMMA) {
        return (comma.offset, last.end);
      }
    }

    // Single, non-delimited param.
    return (last.beginToken.offset, last.end);
  }

  static List<Mutation> discover(String filePath, CompilationUnit unit) {
    var mutations = <Mutation>[];
    var executables = CollectExecutablesVisitor.collectFrom(unit);
    for (var executable in executables) {
      var formalParameters = executable.formalParameters;
      if (formalParameters == null || formalParameters.parameters.isEmpty) {
        continue;
      }
      mutations.add(
        RemoveLastFormalParameterMutation(
          path: filePath,
          targetDeclarationOffset: executable.declarationOffset,
        ),
      );
    }
    return mutations;
  }
}
