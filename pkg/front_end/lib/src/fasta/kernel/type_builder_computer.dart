// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder_computer;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;

import 'package:kernel/ast.dart';

import '../builder/declaration_builders.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/future_or_type_declaration_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/null_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../builder/void_type_declaration_builder.dart';

import '../kernel/utils.dart';

import '../loader.dart' show Loader;
import '../uris.dart' show missingUri;

class TypeBuilderComputer implements DartTypeVisitor<TypeBuilder> {
  final Loader loader;

  late final DynamicTypeDeclarationBuilder dynamicDeclaration =
      new DynamicTypeDeclarationBuilder(
          const DynamicType(), loader.coreLibrary, -1);

  late final VoidTypeDeclarationBuilder voidDeclaration =
      new VoidTypeDeclarationBuilder(const VoidType(), loader.coreLibrary, -1);

  late final NeverTypeDeclarationBuilder neverDeclaration =
      new NeverTypeDeclarationBuilder(
          const NeverType.nonNullable(), loader.coreLibrary, -1);

  late final NullTypeDeclarationBuilder nullDeclaration =
      new NullTypeDeclarationBuilder(const NullType(), loader.coreLibrary, -1);

  late final FutureOrTypeDeclarationBuilder futureOrDeclaration =
      new FutureOrTypeDeclarationBuilder(
          new FutureOrType(const DynamicType(), Nullability.nonNullable),
          loader.coreLibrary,
          -1);

  TypeBuilderComputer(this.loader);

  final Map<TypeParameter, TypeVariableBuilder> functionTypeParameters = {};

  @override
  TypeBuilder visitInvalidType(InvalidType node) {
    return new FixedTypeBuilderImpl(
        node, /* fileUri = */ null, /* charOffset = */ null);
  }

  @override
  TypeBuilder visitDynamicType(DynamicType node) {
    // 'dynamic' is always nullable.
    return new NamedTypeBuilderImpl.forDartType(
        node, dynamicDeclaration, const NullabilityBuilder.inherent());
  }

  @override
  TypeBuilder visitVoidType(VoidType node) {
    // 'void' is always nullable.
    return new NamedTypeBuilderImpl.forDartType(
        node, voidDeclaration, const NullabilityBuilder.inherent());
  }

  @override
  TypeBuilder visitNeverType(NeverType node) {
    return new NamedTypeBuilderImpl.forDartType(node, neverDeclaration,
        new NullabilityBuilder.fromNullability(node.nullability));
  }

  @override
  TypeBuilder visitNullType(NullType node) {
    return new NamedTypeBuilderImpl.forDartType(
        node, nullDeclaration, const NullabilityBuilder.inherent());
  }

  @override
  TypeBuilder visitInterfaceType(InterfaceType node) {
    ClassBuilder cls =
        loader.computeClassBuilderFromTargetClass(node.classNode);
    List<TypeBuilder>? arguments;
    List<DartType> kernelArguments = node.typeArguments;
    if (kernelArguments.isNotEmpty) {
      arguments = new List<TypeBuilder>.generate(
          kernelArguments.length, (int i) => kernelArguments[i].accept(this),
          growable: false);
    }
    return new NamedTypeBuilderImpl.forDartType(
        node, cls, new NullabilityBuilder.fromNullability(node.nullability),
        arguments: arguments);
  }

  @override
  TypeBuilder visitExtensionType(ExtensionType node) {
    ExtensionTypeDeclarationBuilder extensionTypeDeclaration =
        loader.computeExtensionTypeBuilderFromTargetExtensionType(
            node.extensionTypeDeclaration);
    List<TypeBuilder>? arguments;
    List<DartType> kernelArguments = node.typeArguments;
    if (kernelArguments.isNotEmpty) {
      arguments = new List<TypeBuilder>.generate(
          kernelArguments.length, (int i) => kernelArguments[i].accept(this),
          growable: false);
    }
    return new NamedTypeBuilderImpl.forDartType(node, extensionTypeDeclaration,
        new NullabilityBuilder.fromNullability(node.nullability),
        arguments: arguments);
  }

  @override
  TypeBuilder visitFutureOrType(FutureOrType node) {
    TypeBuilder argument = node.typeArgument.accept(this);
    return new NamedTypeBuilderImpl.forDartType(node, futureOrDeclaration,
        new NullabilityBuilder.fromNullability(node.nullability),
        arguments: [argument]);
  }

  @override
  TypeBuilder visitFunctionType(FunctionType node) {
    TypeBuilder returnType = node.returnType.accept(this);
    // We could compute the type variables here. However, the current
    // implementation of [visitTypeParameterType] is sufficient.
    List<StructuralVariableBuilder>? typeVariables = null;
    List<DartType> positionalParameters = node.positionalParameters;
    List<NamedType> namedParameters = node.namedParameters;
    List<ParameterBuilder> formals = new List<ParameterBuilder>.filled(
        positionalParameters.length + namedParameters.length,
        dummyFormalParameterBuilder);
    for (int i = 0; i < positionalParameters.length; i++) {
      TypeBuilder type = positionalParameters[i].accept(this);
      FormalParameterKind kind = FormalParameterKind.requiredPositional;
      if (i >= node.requiredParameterCount) {
        kind = FormalParameterKind.optionalPositional;
      }
      formals[i] = new FunctionTypeParameterBuilder(
          /* metadata = */ null, kind, type, /* name = */ null);
    }
    for (int i = 0; i < namedParameters.length; i++) {
      NamedType parameter = namedParameters[i];
      TypeBuilder type = parameter.type.accept(this);
      FormalParameterKind kind = parameter.isRequired
          ? FormalParameterKind.requiredNamed
          : FormalParameterKind.optionalNamed;
      formals[i + positionalParameters.length] =
          new FunctionTypeParameterBuilder(
              /* metadata = */ null, kind, type, parameter.name);
    }
    return new FunctionTypeBuilderImpl(
        returnType,
        typeVariables,
        formals,
        new NullabilityBuilder.fromNullability(node.nullability),
        /* fileUri = */ null,
        /* charOffset = */ TreeNode.noOffset);
  }

  @override
  TypeBuilder visitTypeParameterType(TypeParameterType node) {
    TypeParameter parameter = node.parameter;
    return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        new TypeVariableBuilder.fromKernel(parameter),
        new NullabilityBuilder.fromNullability(node.nullability),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Allowed,
        type: node);
  }

  @override
  TypeBuilder visitStructuralParameterType(StructuralParameterType node) {
    StructuralParameter parameter = node.parameter;
    return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        new StructuralVariableBuilder.fromKernel(parameter),
        new NullabilityBuilder.fromNullability(node.nullability),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Allowed,
        type: node);
  }

  @override
  TypeBuilder visitIntersectionType(IntersectionType node) {
    throw "Not implemented";
  }

  @override
  TypeBuilder visitTypedefType(TypedefType node) {
    throw "Not implemented";
  }

  @override
  TypeBuilder visitRecordType(RecordType node) {
    List<RecordTypeFieldBuilder>? positionalBuilders;
    List<DartType> positional = node.positional;
    if (positional.isNotEmpty) {
      positionalBuilders = new List<RecordTypeFieldBuilder>.generate(
          positional.length,
          (int i) => new RecordTypeFieldBuilder(
              null, positional[i].accept(this), null, TreeNode.noOffset),
          growable: false);
    }

    List<RecordTypeFieldBuilder>? namedBuilders;
    List<NamedType> named = node.named;
    if (named.isNotEmpty) {
      namedBuilders = new List<RecordTypeFieldBuilder>.generate(
          named.length,
          (int i) => new RecordTypeFieldBuilder(null,
              named[i].type.accept(this), named[i].name, TreeNode.noOffset),
          growable: false);
    }

    return new RecordTypeBuilderImpl(
        positionalBuilders,
        namedBuilders,
        new NullabilityBuilder.fromNullability(node.nullability),
        missingUri,
        TreeNode.noOffset);
  }

  @override
  TypeBuilder visitAuxiliaryType(AuxiliaryType node) {
    throw new UnsupportedError(
        "Unsupported auxiliary type ${node} (${node.runtimeType}).");
  }
}
