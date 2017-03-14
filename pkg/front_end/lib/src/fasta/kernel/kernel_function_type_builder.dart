// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_function_type_builder;

import 'package:kernel/ast.dart' show DartType, DynamicType, Supertype;

import 'kernel_builder.dart'
    show FunctionTypeBuilder, KernelTypeBuilder, LibraryBuilder;

class KernelFunctionTypeBuilder extends FunctionTypeBuilder
    implements KernelTypeBuilder {
  KernelFunctionTypeBuilder(int charOffset, Uri fileUri,
      KernelTypeBuilder returnType, List typeVariables, List formals)
      : super(charOffset, fileUri, returnType, typeVariables, formals);

  // TODO(ahe): Return a proper function type.
  DartType build(LibraryBuilder library) => const DynamicType();

  Supertype buildSupertype(LibraryBuilder library) {
    library.addCompileTimeError(
        charOffset, "Can't use a function type as supertype.",
        fileUri: fileUri);
    return null;
  }
}
