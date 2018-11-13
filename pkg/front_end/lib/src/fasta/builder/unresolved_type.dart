// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.unresolved_type;

import 'builder.dart' show LibraryBuilder, Scope, TypeBuilder;

/// A wrapper around a type that is yet to be resolved.
class UnresolvedType<T extends TypeBuilder> {
  final T builder;
  final int charOffset;
  final Uri fileUri;

  UnresolvedType(this.builder, this.charOffset, this.fileUri);

  void resolveIn(Scope scope, LibraryBuilder library) =>
      builder.resolveIn(scope, charOffset, fileUri, library);

  /// Performs checks on the type after it's resolved.
  void checkType() => builder.check(charOffset, fileUri);

  /// Normalizes the type arguments in accordance with Dart 1 semantics.
  void normalizeType() => builder.normalize(charOffset, fileUri);

  String toString() => "UnresolvedType(@$charOffset, $builder)";
}
