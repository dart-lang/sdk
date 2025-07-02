// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../kernel/type_algorithms.dart';
import 'source_library_builder.dart';

abstract class SourceDeclarationBuilder implements IDeclarationBuilder {
  void buildScopes(LibraryBuilder coreLibrary);

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  int resolveConstructors(SourceLibraryBuilder library);

  @override
  SourceLibraryBuilder get libraryBuilder;
}
