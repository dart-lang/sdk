// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/class_builder.dart';
import '../builder/declaration_builder.dart';
import 'source_library_builder.dart';

/// Common interface for builders for a class declarations in source code, such
/// as a regular class declaration and an inline class declaration.
abstract class ClassDeclaration
    implements DeclarationBuilder, ClassMemberAccess {
  @override
  SourceLibraryBuilder get libraryBuilder;

  bool get isMixinDeclaration;

  /// Returns `true` if this class declaration has a generative constructor,
  /// either explicitly or implicitly through a no-name default constructor.
  bool get hasGenerativeConstructor;
}
