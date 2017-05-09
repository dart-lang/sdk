// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_builder;

export 'kernel_class_builder.dart' show KernelClassBuilder;

export 'kernel_enum_builder.dart' show KernelEnumBuilder;

export 'kernel_field_builder.dart' show KernelFieldBuilder;

export 'kernel_formal_parameter_builder.dart' show KernelFormalParameterBuilder;

export 'kernel_function_type_builder.dart' show KernelFunctionTypeBuilder;

export 'kernel_function_type_alias_builder.dart'
    show KernelFunctionTypeAliasBuilder;

export 'kernel_named_type_builder.dart' show KernelNamedTypeBuilder;

export 'kernel_library_builder.dart' show KernelLibraryBuilder;

export 'kernel_mixin_application_builder.dart'
    show KernelMixinApplicationBuilder;

export 'kernel_procedure_builder.dart'
    show
        KernelConstructorBuilder,
        KernelFunctionBuilder,
        KernelProcedureBuilder;

export 'kernel_type_builder.dart' show KernelTypeBuilder;

export 'kernel_type_variable_builder.dart' show KernelTypeVariableBuilder;

export '../builder/builder.dart';

export 'kernel_variable_builder.dart' show KernelVariableBuilder;

export 'kernel_invalid_type_builder.dart' show KernelInvalidTypeBuilder;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:kernel/ast.dart'
    show
        Class,
        Constructor,
        DartType,
        DynamicType,
        Field,
        Initializer,
        Library,
        Member,
        Procedure,
        RedirectingInitializer,
        TypeParameter;

import '../errors.dart' show inputError;

import '../builder/builder.dart' show LibraryBuilder;

List<DartType> computeDefaultTypeArguments(LibraryBuilder library,
    List<TypeParameter> typeParameters, List<DartType> arguments) {
  // TODO(ahe): Not sure what to do if `arguments.length !=
  // cls.typeParameters.length`.
  if (arguments == null) {
    return new List<DartType>.filled(
        typeParameters.length, const DynamicType());
  }
  if (arguments.length < typeParameters.length) {
    arguments = new List<DartType>.from(arguments);
    for (int i = arguments.length; i < typeParameters.length; i++) {
      arguments.add(const DynamicType());
    }
  } else if (arguments.length > typeParameters.length) {
    return arguments.sublist(0, typeParameters.length);
  }
  return arguments;
}

dynamic memberError(Member member, Object error, [int charOffset]) {
  String name = member.name?.name;
  if (name == "") {
    name = Printer.emptyNameString;
  } else if (name == null) {
    name = "<anon>";
  }
  Library library = member.enclosingLibrary;
  Class cls = member.enclosingClass;
  String fileUri;
  if (member is Procedure) {
    fileUri = member.fileUri;
  } else if (member is Field) {
    fileUri = member.fileUri;
  }
  fileUri ??= cls?.fileUri ?? library.fileUri;
  Uri uri = fileUri == null ? library.importUri : Uri.base.resolve(fileUri);
  charOffset ??= -1;
  if (charOffset == -1) {
    charOffset = member.fileOffset ?? -1;
  }
  if (charOffset == -1) {
    charOffset = cls?.fileOffset ?? -1;
  }
  name = (cls == null ? "" : "${cls.name}::") + name;
  return inputError(uri, charOffset, "Error in $name: $error");
}

int compareProcedures(Procedure a, Procedure b) {
  int i = a.fileUri.compareTo(b.fileUri);
  if (i != 0) return i;
  return a.fileOffset.compareTo(b.fileOffset);
}

bool isRedirectingGenerativeConstructorImplementation(Constructor constructor) {
  List<Initializer> initializers = constructor.initializers;
  return initializers.length == 1 &&
      initializers.single is RedirectingInitializer;
}
