// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_interface_type_builder;

import 'package:kernel/ast.dart' show DartType, DynamicType, Supertype;

import '../messages.dart' show deprecated_warning;

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeVariableBuilder;

class KernelNamedTypeBuilder
    extends NamedTypeBuilder<KernelTypeBuilder, DartType>
    implements KernelTypeBuilder {
  KernelNamedTypeBuilder(String name, List<KernelTypeBuilder> arguments,
      int charOffset, Uri fileUri)
      : super(name, arguments, charOffset, fileUri);

  KernelInvalidTypeBuilder buildInvalidType(String name) {
    // TODO(ahe): Record error instead of printing.
    deprecated_warning(fileUri, charOffset, "Type not found: '$name'.");
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri);
  }

  DartType handleMissingType() {
    // TODO(ahe): Record error instead of printing.
    deprecated_warning(fileUri, charOffset, "No type for: '$name'.");
    return const DynamicType();
  }

  Supertype handleMissingSupertype() {
    deprecated_warning(fileUri, charOffset, "No type for: '$name'.");
    return null;
  }

  Supertype handleInvalidSupertype(LibraryBuilder library) {
    String message = builder.isTypeVariable
        ? "The type variable '$name' can't be used as supertype."
        : "The type '$name' can't be used as supertype.";
    library.deprecated_addCompileTimeError(charOffset, message,
        fileUri: fileUri);
    return null;
  }

  DartType build(LibraryBuilder library) {
    if (builder == null) return handleMissingType();
    return builder.buildType(library, arguments);
  }

  Supertype buildSupertype(LibraryBuilder library) {
    if (builder == null) return handleMissingSupertype();
    if (builder is KernelClassBuilder) {
      KernelClassBuilder builder = this.builder;
      return builder.buildSupertype(library, arguments);
    } else {
      return handleInvalidSupertype(library);
    }
  }

  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) {
    TypeBuilder result = substitution[builder];
    if (result != null) {
      assert(builder is TypeVariableBuilder);
      return result;
    } else if (arguments != null) {
      List<KernelTypeBuilder> arguments;
      int i = 0;
      for (KernelTypeBuilder argument in this.arguments) {
        KernelTypeBuilder type = argument.subst(substitution);
        if (type != argument) {
          arguments ??= this.arguments.toList();
          arguments[i] = type;
        }
        i++;
      }
      if (arguments != null) {
        return new KernelNamedTypeBuilder(name, arguments, charOffset, fileUri)
          ..builder = builder;
      }
    }
    return this;
  }
}
