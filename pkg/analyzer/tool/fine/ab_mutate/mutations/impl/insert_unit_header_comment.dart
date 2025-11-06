// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import '../../models.dart';
import '../api.dart';
import '../kinds.dart';

/// Insert a harmless line comment at unit start. Pure trivia; never breaks AST.
class InsertUnitHeaderCommentMutation extends Mutation {
  InsertUnitHeaderCommentMutation({required super.path});

  @override
  MutationKind get kind => MutationKind.insertUnitHeaderComment;

  @override
  MutationResult apply(CompilationUnit unit, String content) {
    var insertAt = unit.beginToken.offset;
    // For strict determinism, a seed-derived nonce could replace timestamp.
    var ins = '// ab_mutate: noop ${DateTime.now().millisecondsSinceEpoch}\n';
    return MutationResult(MutationEdit(insertAt, 0, ins), {
      'insert_at': insertAt,
    });
  }

  @override
  Map<String, Object?> toJson() {
    return {};
  }

  static List<Mutation> discover(String filePath, CompilationUnit unit) {
    var mutations = <Mutation>[];
    if (unit.declarations.isNotEmpty) {
      mutations.add(InsertUnitHeaderCommentMutation(path: filePath));
    }
    return mutations;
  }
}
