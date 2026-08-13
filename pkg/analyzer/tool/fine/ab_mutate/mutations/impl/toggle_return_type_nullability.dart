// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import '../../models.dart';
import '../api.dart';
import '../executable_declarations.dart';
import '../kinds.dart';

/// Toggle a trailing `?` on named return types (e.g., `Foo` <-> `Foo?`).
/// Does not attempt nullability propagation or call-site changes.
class ToggleReturnTypeNullabilityMutation extends Mutation {
  final int retOffset;
  final int retLength;

  ToggleReturnTypeNullabilityMutation({
    required super.path,
    required this.retOffset,
    required this.retLength,
  });

  @override
  MutationKind get kind => MutationKind.toggleReturnTypeNullability;

  @override
  MutationResult apply(CompilationUnit unit, String content) {
    var offset = retOffset;
    var length = retLength;

    var original = content.substring(offset, offset + length);
    var replacement = original.endsWith('?')
        ? original.substring(0, original.length - 1)
        : '$original?';
    return MutationResult(MutationEdit(offset, length, replacement), {
      'from': original,
      'to': replacement,
    });
  }

  @override
  Map<String, Object?> toJson() {
    return {'ret_offset': retOffset, 'ret_length': retLength};
  }

  static List<Mutation> discover(String filePath, CompilationUnit unit) {
    var mutations = <Mutation>[];
    var executables = CollectExecutablesVisitor.collectFrom(unit);
    for (var executable in executables) {
      var returnType = executable.returnType;
      if (returnType is NamedType && returnType.name.lexeme != 'void') {
        mutations.add(
          ToggleReturnTypeNullabilityMutation(
            path: filePath,
            retOffset: returnType.offset,
            retLength: returnType.length,
          ),
        );
      }
    }
    return mutations;
  }
}
