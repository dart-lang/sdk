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

export 'kernel_prefix_builder.dart' show KernelPrefixBuilder;

export 'kernel_named_type_builder.dart' show KernelNamedTypeBuilder;

export 'kernel_library_builder.dart' show KernelLibraryBuilder;

export 'kernel_mixin_application_builder.dart'
    show KernelMixinApplicationBuilder;

export 'kernel_procedure_builder.dart'
    show
        KernelConstructorBuilder,
        KernelFunctionBuilder,
        KernelRedirectingFactoryBuilder,
        KernelProcedureBuilder;

export 'kernel_type_builder.dart' show KernelTypeBuilder;

export 'kernel_type_variable_builder.dart' show KernelTypeVariableBuilder;

export '../builder/builder.dart';

export 'kernel_variable_builder.dart' show KernelVariableBuilder;

export 'kernel_invalid_type_builder.dart' show KernelInvalidTypeBuilder;

export 'load_library_builder.dart' show LoadLibraryBuilder;

import 'package:kernel/ast.dart'
    show
        Combinator,
        Constructor,
        DartType,
        DynamicType,
        Initializer,
        Procedure,
        RedirectingInitializer,
        TypeParameter;

import '../builder/builder.dart' show LibraryBuilder;

import '../combinator.dart' as fasta;

List<DartType> computeDefaultTypeArguments(LibraryBuilder library,
    List<TypeParameter> typeParameters, List<DartType> arguments) {
  // TODO(scheglov): Use TypeSchemaEnvironment.instantiateToBounds
  if (arguments == null || arguments.length != typeParameters.length) {
    // TODO(scheglov): Check that we report a warning.
    return new List<DartType>.filled(
        typeParameters.length, const DynamicType());
  }
  return arguments;
}

int compareProcedures(Procedure a, Procedure b) {
  int i = "${a.fileUri}".compareTo("${b.fileUri}");
  if (i != 0) return i;
  return a.fileOffset.compareTo(b.fileOffset);
}

bool isRedirectingGenerativeConstructorImplementation(Constructor constructor) {
  List<Initializer> initializers = constructor.initializers;
  return initializers.length == 1 &&
      initializers.single is RedirectingInitializer;
}

List<Combinator> toKernelCombinators(List<fasta.Combinator> fastaCombinators) {
  if (fastaCombinators == null) {
    // Note: it's safe to return null here as Kernel's LibraryDependency will
    // convert null to an empty list.
    return null;
  }

  List<Combinator> result = new List<Combinator>.filled(
      fastaCombinators.length, null,
      growable: true);
  for (int i = 0; i < fastaCombinators.length; i++) {
    fasta.Combinator combinator = fastaCombinators[i];
    List<String> nameList = combinator.names.toList();
    result[i] = combinator.isShow
        ? new Combinator.show(nameList)
        : new Combinator.hide(nameList);
  }
  return result;
}
