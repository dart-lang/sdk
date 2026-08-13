// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import 'api.dart';
import 'impl/insert_unit_header_comment.dart';
import 'impl/remove_last_formal_parameter.dart';
import 'impl/rename_local_variable.dart';
import 'impl/swap_top_level_functions.dart';
import 'impl/toggle_return_type_nullability.dart';
import 'kinds.dart';

/// Enumerate sites for a given [kind] in [filePath] using [unit].
/// Enumeration is deterministic (source order).
List<Mutation> discoverMutationsFor(
  MutationKind kind,
  String filePath,
  CompilationUnit unit,
) {
  switch (kind) {
    case MutationKind.insertUnitHeaderComment:
      return InsertUnitHeaderCommentMutation.discover(filePath, unit);
    case MutationKind.renameLocalVariable:
      return RenameLocalVariableMutation.discover(filePath, unit);
    case MutationKind.removeLastFormalParameter:
      return RemoveLastFormalParameterMutation.discover(filePath, unit);
    case MutationKind.swapTopLevelFunctions:
      return SwapTopLevelFunctionsMutation.discover(filePath, unit);
    case MutationKind.toggleReturnTypeNullability:
      return ToggleReturnTypeNullabilityMutation.discover(filePath, unit);
  }
}
