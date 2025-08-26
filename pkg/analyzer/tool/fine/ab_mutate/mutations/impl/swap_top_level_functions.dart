// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import '../../models.dart';
import '../api.dart';
import '../kinds.dart';

/// Swap the first and last top-level function declarations in a file.
/// Preserves each function's raw text (comments/metadata travel with it).
class SwapTopLevelFunctionsMutation extends Mutation {
  SwapTopLevelFunctionsMutation({required super.path});

  @override
  MutationKind get kind => MutationKind.swapTopLevelFunctions;

  @override
  MutationResult apply(CompilationUnit unit, String content) {
    var functions = unit.declarations.whereType<FunctionDeclaration>().toList();
    if (functions.length < 2) {
      throw StateError('Expected at least two functions to swap.');
    }

    var a = functions.first;
    var b = functions.last;

    var aStart = a.offset;
    var aEnd = a.endToken.end;
    var bStart = b.offset;
    var bEnd = b.endToken.end;

    var aText = content.substring(aStart, aEnd);
    var bText = content.substring(bStart, bEnd);

    String newContent;
    if (aStart < bStart) {
      newContent =
          content.substring(0, aStart) +
          bText +
          content.substring(aEnd, bStart) +
          aText +
          content.substring(bEnd);
    } else {
      newContent =
          content.substring(0, bStart) +
          aText +
          content.substring(bEnd, aStart) +
          bText +
          content.substring(aEnd);
    }

    return MutationResult(MutationEdit(0, content.length, newContent), {
      'a': a.name.lexeme,
      'b': b.name.lexeme,
    });
  }

  @override
  Map<String, Object?> toJson() {
    return {};
  }

  static List<Mutation> discover(String filePath, CompilationUnit unit) {
    var mutations = <Mutation>[];
    var functions = unit.declarations.whereType<FunctionDeclaration>().toList();
    if (functions.length >= 2) {
      mutations.add(SwapTopLevelFunctionsMutation(path: filePath));
    }
    return mutations;
  }
}
