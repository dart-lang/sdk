// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

import '../models.dart';
import 'kinds.dart';

/// Contract for a concrete mutation.
abstract class Mutation {
  final String path;

  Mutation({required this.path});

  MutationKind get kind;

  /// Implementations must:
  /// - verify that their captured preconditions still hold for the given [unit]
  ///   (e.g. the target node/offset still points to the same syntax/element).
  /// - produce a single-file [MutationEdit] for [unit].
  ///
  /// If preconditions don't hold, this is a programmer error (the mutation was
  /// constructed from a different state) and should throw.
  MutationResult apply(CompilationUnit unit, String content);

  Map<String, Object?> selectionJson(String repo) => {
    'file': p.relative(path, from: repo),
    ...toJson(),
  };

  Map<String, Object?> toJson();
}
