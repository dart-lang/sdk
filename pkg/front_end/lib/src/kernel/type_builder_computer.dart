// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder_computer;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;
import 'package:kernel/ast.dart';

import '../base/loader.dart' show Loader;
import '../base/uris.dart' show missingUri;
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

class TypeBuilderComputer {
  final _TypeBuilderComputerHelper _typeBuilderComputerHelper;

  TypeBuilderComputer(Loader loader)
      : _typeBuilderComputerHelper = new _TypeBuilderComputerHelper(loader);

  TypeBuilder visit(DartType type) => _typeBuilderComputerHelper.visit(type);
}

class _TypeBuilderComputerHelper
    implements
        DartTypeVisitor1<TypeBuilder,
            Map<TypeParameter, NominalVariableBuilder>> {
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

  _TypeBuilderComputerHelper(this.loader);

  final Map<StructuralParameter, StructuralVariableBuilder>
      structuralTypeParameters =
      <StructuralParameter, StructuralVariableBuilder>{};

  final Map<TypeParameter, NominalVariableBuilder>
      computedNominalTypeParameters = <TypeParameter, NominalVariableBuilder>{};

  TypeBuilder visit(DartType type) {
    TypeBuilder typeBuilder =
        type.accept1(this, <TypeParameter, NominalVariableBuilder>{});
    structuralTypeParameters.clear();
    computedNominalTypeParameters.clear();
    return typeBuilder;
  }

  @override
  TypeBuilder visitInvalidType(InvalidType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    return new FixedTypeBuilderImpl(
        node, /* fileUri = */ null, /* charOffset = */ null);
  }

  @override
  TypeBuilder visitDynamicType(DynamicType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    // 'dynamic' is always nullable.
    return new NamedTypeBuilderImpl.forDartType(
        node, dynamicDeclaration, const NullabilityBuilder.inherent());
  }

  @override
  TypeBuilder visitVoidType(VoidType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    // 'void' is always nullable.
    return new NamedTypeBuilderImpl.forDartType(
        node, voidDeclaration, const NullabilityBuilder.inherent());
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder visitNeverType(NeverType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    return new NamedTypeBuilderImpl.forDartType(node, neverDeclaration,
        new NullabilityBuilder.fromNullability(node.nullability));
  }

  @override
  TypeBuilder visitNullType(NullType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    return new NamedTypeBuilderImpl.forDartType(
        node, nullDeclaration, const NullabilityBuilder.inherent());
  }

  @override
  TypeBuilder visitInterfaceType(InterfaceType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    ClassBuilder cls =
        loader.computeClassBuilderFromTargetClass(node.classNode);
    List<TypeBuilder>? arguments;
    List<DartType> kernelArguments = node.typeArguments;
    if (kernelArguments.isNotEmpty) {
      arguments = new List<TypeBuilder>.generate(kernelArguments.length,
          (int i) => kernelArguments[i].accept1(this, pendingNominalVariables),
          growable: false);
    }
    return new NamedTypeBuilderImpl.forDartType(
        node, cls, new NullabilityBuilder.fromNullability(node.nullability),
        arguments: arguments);
  }

  @override
  TypeBuilder visitExtensionType(ExtensionType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    ExtensionTypeDeclarationBuilder extensionTypeDeclaration =
        loader.computeExtensionTypeBuilderFromTargetExtensionType(
            node.extensionTypeDeclaration);
    List<TypeBuilder>? arguments;
    List<DartType> kernelArguments = node.typeArguments;
    if (kernelArguments.isNotEmpty) {
      arguments = new List<TypeBuilder>.generate(kernelArguments.length,
          (int i) => kernelArguments[i].accept1(this, pendingNominalVariables),
          growable: false);
    }
    return new NamedTypeBuilderImpl.forDartType(node, extensionTypeDeclaration,
        new NullabilityBuilder.fromNullability(node.nullability),
        arguments: arguments);
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder visitFutureOrType(FutureOrType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    TypeBuilder argument =
        node.typeArgument.accept1(this, pendingNominalVariables);
    return new NamedTypeBuilderImpl.forDartType(node, futureOrDeclaration,
        new NullabilityBuilder.fromNullability(node.nullability),
        arguments: [argument]);
  }

  @override
  TypeBuilder visitFunctionType(FunctionType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    List<StructuralVariableBuilder>? typeVariables = null;
    if (node.typeParameters.isNotEmpty) {
      typeVariables = <StructuralVariableBuilder>[
        for (StructuralParameter structuralParameter in node.typeParameters)
          structuralTypeParameters[structuralParameter] =
              new StructuralVariableBuilder.fromKernel(structuralParameter)
      ];
    }

    TypeBuilder returnType =
        node.returnType.accept1(this, pendingNominalVariables);

    List<DartType> positionalParameters = node.positionalParameters;
    List<NamedType> namedParameters = node.namedParameters;
    List<ParameterBuilder> formals = new List<ParameterBuilder>.filled(
        positionalParameters.length + namedParameters.length,
        dummyFormalParameterBuilder);
    for (int i = 0; i < positionalParameters.length; i++) {
      TypeBuilder type =
          positionalParameters[i].accept1(this, pendingNominalVariables);
      FormalParameterKind kind = FormalParameterKind.requiredPositional;
      if (i >= node.requiredParameterCount) {
        kind = FormalParameterKind.optionalPositional;
      }
      formals[i] =
          new FunctionTypeParameterBuilder(kind, type, /* name = */ null);
    }
    for (int i = 0; i < namedParameters.length; i++) {
      NamedType parameter = namedParameters[i];
      TypeBuilder type = parameter.type.accept1(this, pendingNominalVariables);
      FormalParameterKind kind = parameter.isRequired
          ? FormalParameterKind.requiredNamed
          : FormalParameterKind.optionalNamed;
      formals[i + positionalParameters.length] =
          new FunctionTypeParameterBuilder(kind, type, parameter.name);
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
  TypeBuilder visitTypeParameterType(TypeParameterType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    NominalVariableBuilder nominalVariableBuilder;
    if (pendingNominalVariables.containsKey(node.parameter)) {
      nominalVariableBuilder = pendingNominalVariables[node.parameter]!;
    } else if (computedNominalTypeParameters.containsKey(node.parameter)) {
      nominalVariableBuilder = computedNominalTypeParameters[node.parameter]!;
    } else {
      nominalVariableBuilder =
          new NominalVariableBuilder.fromKernel(node.parameter, loader: null);
      nominalVariableBuilder.bound = node.parameter.bound.accept1(this,
          {...pendingNominalVariables, node.parameter: nominalVariableBuilder});
      nominalVariableBuilder.defaultType = node.parameter.defaultType.accept1(
          this,
          {...pendingNominalVariables, node.parameter: nominalVariableBuilder});
      computedNominalTypeParameters[node.parameter] = nominalVariableBuilder;
    }
    return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        nominalVariableBuilder,
        new NullabilityBuilder.fromNullability(node.nullability),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Allowed,
        type: node);
  }

  @override
  TypeBuilder visitStructuralParameterType(StructuralParameterType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    assert(structuralTypeParameters.containsKey(node.parameter));
    return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        structuralTypeParameters[node.parameter]!,
        new NullabilityBuilder.fromNullability(node.nullability),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Allowed,
        type: node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder visitIntersectionType(IntersectionType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    throw "Not implemented";
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder visitTypedefType(TypedefType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    throw "Not implemented";
  }

  @override
  TypeBuilder visitRecordType(RecordType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    List<RecordTypeFieldBuilder>? positionalBuilders;
    List<DartType> positional = node.positional;
    if (positional.isNotEmpty) {
      positionalBuilders = new List<RecordTypeFieldBuilder>.generate(
          positional.length,
          (int i) => new RecordTypeFieldBuilder(
              null,
              positional[i].accept1(this, pendingNominalVariables),
              null,
              TreeNode.noOffset),
          growable: false);
    }

    List<RecordTypeFieldBuilder>? namedBuilders;
    List<NamedType> named = node.named;
    if (named.isNotEmpty) {
      namedBuilders = new List<RecordTypeFieldBuilder>.generate(
          named.length,
          (int i) => new RecordTypeFieldBuilder(
              null,
              named[i].type.accept1(this, pendingNominalVariables),
              named[i].name,
              TreeNode.noOffset),
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
  TypeBuilder visitAuxiliaryType(AuxiliaryType node,
      Map<TypeParameter, NominalVariableBuilder> pendingNominalVariables) {
    throw new UnsupportedError(
        "Unsupported auxiliary type ${node} (${node.runtimeType}).");
  }
}
