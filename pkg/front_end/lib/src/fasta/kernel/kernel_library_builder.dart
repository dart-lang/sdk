// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_library_builder;

import 'package:kernel/ast.dart';

import 'package:kernel/clone.dart' show
    CloneVisitor;

import '../errors.dart' show
    internalError;

import '../loader.dart' show
    Loader;

import '../modifier.dart' show
    staticMask;

import '../source/source_library_builder.dart' show
    SourceLibraryBuilder;

import '../source/source_class_builder.dart' show
    SourceClassBuilder;

import 'kernel_builder.dart' show
    Builder,
    ClassBuilder,
    ConstructorReferenceBuilder,
    DynamicTypeBuilder,
    EnumBuilder,
    FieldBuilder,
    FormalParameterBuilder,
    FunctionTypeAliasBuilder,
    KernelEnumBuilder,
    KernelFieldBuilder,
    KernelFormalParameterBuilder,
    KernelFunctionTypeAliasBuilder,
    KernelInterfaceTypeBuilder,
    KernelInvalidTypeBuilder,
    KernelMixinApplicationBuilder,
    KernelNamedMixinApplicationBuilder,
    KernelProcedureBuilder,
    KernelTypeBuilder,
    KernelTypeVariableBuilder,
    MemberBuilder,
    MetadataBuilder,
    MixedAccessor,
    NamedMixinApplicationBuilder,
    PrefixBuilder,
    ProcedureBuilder,
    TypeVariableBuilder;

class KernelLibraryBuilder
    extends SourceLibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  final List<Class> mixinApplicationClasses = <Class>[];

  final List<List> argumentsWithMissingDefaultValues = <List>[];

  KernelLibraryBuilder(Uri uri, Uri fileUri, Loader loader)
      : library = new Library(uri),
        super(loader, fileUri);

  Uri get uri => library.importUri;

  KernelTypeBuilder addInterfaceType(String name,
      List<KernelTypeBuilder> arguments) {
    KernelInterfaceTypeBuilder type =
        new KernelInterfaceTypeBuilder(name, arguments);
    if (identical(name, "dynamic")) {
      // TODO(ahe): Make const.
      type.builder = new DynamicTypeBuilder(const DynamicType());
    } else {
      addType(type);
    }
    return type;
  }

  KernelTypeBuilder addMixinApplication(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins) {
    KernelTypeBuilder type =
        new KernelMixinApplicationBuilder(supertype, mixins);
    return addType(type);
  }

  KernelTypeBuilder addVoidType() {
    return new KernelInterfaceTypeBuilder("void", null);
  }

  ClassBuilder addClass(List<MetadataBuilder> metadata,
      int modifiers, String className,
      List<TypeVariableBuilder> typeVariables, KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces) {
    ClassBuilder cls = new SourceClassBuilder(metadata, modifiers, className,
        typeVariables, supertype, interfaces, classMembers, declarationTypes,
        this,
        new List<ConstructorReferenceBuilder>.from(constructorReferences));
    constructorReferences.clear();
    classMembers.forEach((String name, MemberBuilder builder) {
      while (builder != null) {
        builder.parent = cls;
        builder = builder.next;
      }
    });
    // Nested scope began in `OutlineBuilder.beginClassDeclaration`.
    endNestedScope();
    return addBuilder(className, cls);
  }

  NamedMixinApplicationBuilder addNamedMixinApplication(
      List<MetadataBuilder> metadata, String name,
      List<TypeVariableBuilder> typeVariables, int modifiers,
      KernelTypeBuilder mixinApplication, List<KernelTypeBuilder> interfaces) {
    NamedMixinApplicationBuilder builder =
        new KernelNamedMixinApplicationBuilder(metadata, name, typeVariables,
            modifiers, mixinApplication, interfaces, declarationTypes, this);
    // Nested scope began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedScope();
    return addBuilder(name, builder);
  }

  FieldBuilder addField(List<MetadataBuilder> metadata,
      int modifiers, KernelTypeBuilder type, String name) {
    return addBuilder(name,
        new KernelFieldBuilder(metadata, type, name, modifiers));
  }

  ProcedureBuilder addProcedure(List<MetadataBuilder> metadata,
      int modifiers, KernelTypeBuilder returnType, String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals, AsyncMarker asyncModifier,
      ProcedureKind kind) {
    // Nested scope began in `OutlineBuilder.beginMethod` or
    // `OutlineBuilder.beginTopLevelMethod`.
    endNestedScope().resolveTypes(typeVariables);
    return addBuilder(name,
        new KernelProcedureBuilder(metadata, modifiers, returnType, name,
            typeVariables, formals, asyncModifier, kind));
  }

  void addFactoryMethod(List<MetadataBuilder> metadata,
      ConstructorReferenceBuilder constructorName,
      List<FormalParameterBuilder> formals, AsyncMarker asyncModifier,
      ConstructorReferenceBuilder redirectionTarget) {
    String name = constructorName.name;
    assert(constructorName.suffix == null);
    addBuilder(name,
        new KernelProcedureBuilder(metadata, staticMask, null, name, null,
            formals, asyncModifier, ProcedureKind.Factory, redirectionTarget));
  }

  EnumBuilder addEnum(List<MetadataBuilder> metadata, String name,
      List<String> constants) {
    return addBuilder(name,
        new KernelEnumBuilder(metadata, name, constants, this));
  }

  FunctionTypeAliasBuilder addFunctionTypeAlias(List<MetadataBuilder> metadata,
      KernelTypeBuilder returnType, String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals) {
    FunctionTypeAliasBuilder typedef = new KernelFunctionTypeAliasBuilder(
        metadata, returnType, name, typeVariables, formals, declarationTypes,
        this);
    // Nested scope began in `OutlineBuilder.beginFunctionTypeAlias`.
    endNestedScope();
    return addBuilder(name, typedef);
  }

  KernelFormalParameterBuilder addFormalParameter(
      List<MetadataBuilder> metadata, int modifiers,
      KernelTypeBuilder type, String name, bool hasThis) {
    return new KernelFormalParameterBuilder(
        metadata, modifiers, type, name, hasThis);
  }

  KernelTypeVariableBuilder addTypeVariable(String name,
      KernelTypeBuilder bound) {
    return new KernelTypeVariableBuilder(name, bound);
  }

  void buildBuilder(Builder builder) {
    if (builder is SourceClassBuilder) {
      Class cls = builder.build(this);
      library.addClass(cls);
      Class superclass = cls.superclass;
      if (superclass != null && superclass.isMixinApplication) {
        List<Class> mixinApplications = <Class>[];
        mixinApplicationClasses.add(cls);
        while (superclass != null && superclass.isMixinApplication) {
          if (superclass.parent == null) {
            mixinApplications.add(superclass);
          }
          superclass = superclass.superclass;
        }
        for (Class cls in mixinApplications.reversed) {
          // TODO(ahe): Should be able to move this into the above loop as long
          // as we don't care about matching dartk perfectly.
          library.addClass(cls);
          mixinApplicationClasses.add(cls);
        }
      }
    } else if (builder is KernelFieldBuilder) {
      library.addMember(builder.build(library)..isStatic = true);
    } else if (builder is KernelProcedureBuilder) {
      library.addMember(builder.build(library)..isStatic = true);
    } else if (builder is FunctionTypeAliasBuilder) {
      // Kernel discard typedefs and use their corresponding function types
      // directly.
    } else if (builder is KernelEnumBuilder) {
      library.addClass(builder.build(this));
    } else if (builder is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
    } else {
      internalError("Unhandled builder: ${builder.runtimeType}");
    }
  }

  Library build() {
    super.build();
    library.name = name;
    return library;
  }

  Builder buildAmbiguousBuilder(
      String name, Builder builder, Builder other) {
    if (builder.next == null && other.next == null) {
      if (builder.isGetter && other.isSetter) {
        return new MixedAccessor(builder, other);
      } else if (builder.isSetter && other.isGetter) {
        return new MixedAccessor(other, builder);
      }
    }
    return new KernelInvalidTypeBuilder(name, this);
  }

  void addArgumentsWithMissingDefaultValues(Arguments arguments,
      FunctionNode function) {
    assert(partOfLibrary == null);
    argumentsWithMissingDefaultValues.add([arguments, function]);
  }

  int finishStaticInvocations() {
    CloneVisitor cloner;
    for (var list in argumentsWithMissingDefaultValues) {
      final Arguments arguments = list[0];
      final FunctionNode function = list[1];

      Expression defaultArgumentFrom(Expression expression) {
        if (expression == null) {
          return new NullLiteral();
        }
        cloner ??= new CloneVisitor();
        return cloner.clone(expression);
      }

      for (int i = function.requiredParameterCount;
           i < function.positionalParameters.length;
           i++) {
        arguments.positional[i] ??=
            defaultArgumentFrom(function.positionalParameters[i].initializer)
            ..parent = arguments;
      }
      Map<String, VariableDeclaration> names;
      for (NamedExpression expression in arguments.named) {
        if (expression.value == null) {
          if (names == null) {
            names = <String, VariableDeclaration>{};
            for (VariableDeclaration parameter in function.namedParameters) {
              names[parameter.name] = parameter;
            }
          }
          expression.value =
              defaultArgumentFrom(names[expression.name].initializer)
              ..parent = expression;
        }
      }
    }
    return argumentsWithMissingDefaultValues.length;
  }
}
