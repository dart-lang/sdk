// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.unresolved_type;

import '../scope.dart';

import 'library_builder.dart';
import 'type_builder.dart';

/// A wrapper around a type that is yet to be resolved.
class UnresolvedType {
  final TypeBuilder builder;
  final int charOffset;
  final Uri fileUri;

  UnresolvedType(this.builder, this.charOffset, this.fileUri);

  void resolveIn(Scope scope, LibraryBuilder library) =>
      builder.resolveIn(scope, charOffset, fileUri, library);

  /// Performs checks on the type after it's resolved.
  void checkType(LibraryBuilder library) {
    return builder.check(library, charOffset, fileUri);
  }

  String toString() => "UnresolvedType(@$charOffset, $builder)";
}
