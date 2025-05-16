// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/declaration_builders.dart';
import 'source_library_builder.dart';

/// Common interface for builders for a class declarations in source code, such
/// as a regular class declaration and an extension type declaration.
// TODO(johnniwinther): Should this be renamed now that inline classes are
//  renamed to extension type declarations?
// TODO(johnniwinther): Merge this with [IDeclarationBuilder]? Extensions are
// the only declarations without constructors, this might come with the static
// extension feature.
abstract class ClassDeclarationBuilder implements IDeclarationBuilder {
  @override
  SourceLibraryBuilder get libraryBuilder;

  int resolveConstructors(SourceLibraryBuilder library);
}
