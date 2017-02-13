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

import '../util/relativize.dart' show
    relativizeUri;

import 'kernel_builder.dart' show
    Builder,
    ClassBuilder,
    ConstructorReferenceBuilder,
    DynamicTypeBuilder,
    FormalParameterBuilder,
    FunctionTypeAliasBuilder,
    KernelEnumBuilder,
    KernelFieldBuilder,
    KernelFormalParameterBuilder,
    KernelFunctionTypeAliasBuilder,
    KernelInvalidTypeBuilder,
    KernelMixinApplicationBuilder,
    KernelNamedMixinApplicationBuilder,
    KernelNamedTypeBuilder,
    KernelProcedureBuilder,
    KernelTypeBuilder,
    KernelTypeVariableBuilder,
    MemberBuilder,
    MetadataBuilder,
    MixedAccessor,
    NamedMixinApplicationBuilder,
    PrefixBuilder,
    TypeVariableBuilder;

class KernelLibraryBuilder
    extends SourceLibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  final List<Class> mixinApplicationClasses = <Class>[];

  final List<List> argumentsWithMissingDefaultValues = <List>[];

  KernelLibraryBuilder(Uri uri, Uri fileUri, Loader loader)
      : library = new Library(uri, fileUri: relativizeUri(fileUri)),
        super(loader, fileUri);

  Uri get uri => library.importUri;

  KernelTypeBuilder addNamedType(String name,
      List<KernelTypeBuilder> arguments, int charOffset) {
    KernelNamedTypeBuilder type =
        new KernelNamedTypeBuilder(name, arguments, charOffset, fileUri);
    if (identical(name, "dynamic")) {
      type.builder =
          new DynamicTypeBuilder(const DynamicType(), this, charOffset);
    } else {
      addType(type);
    }
    return type;
  }

  KernelTypeBuilder addMixinApplication(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins, int charOffset) {
    KernelTypeBuilder type = new KernelMixinApplicationBuilder(
        supertype, mixins, charOffset, fileUri);
    return addType(type);
  }

  KernelTypeBuilder addVoidType(int charOffset) {
    return new KernelNamedTypeBuilder("void", null, charOffset, fileUri);
  }

  void addClass(List<MetadataBuilder> metadata,
      int modifiers, String className,
      List<TypeVariableBuilder> typeVariables, KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces, int charOffset) {
    ClassBuilder cls = new SourceClassBuilder(metadata, modifiers, className,
        typeVariables, supertype, interfaces, classMembers, declarationTypes,
        this,
        new List<ConstructorReferenceBuilder>.from(constructorReferences),
        charOffset);
    constructorReferences.clear();
    classMembers.forEach((String name, MemberBuilder builder) {
      while (builder != null) {
        builder.parent = cls;
        builder = builder.next;
      }
    });
    // Nested declaration began in `OutlineBuilder.beginClassDeclaration`.
    endNestedDeclaration();
    addBuilder(className, cls, charOffset);
  }

  void addNamedMixinApplication(
      List<MetadataBuilder> metadata, String name,
      List<TypeVariableBuilder> typeVariables, int modifiers,
      KernelTypeBuilder mixinApplication, List<KernelTypeBuilder> interfaces,
      int charOffset) {
    NamedMixinApplicationBuilder builder =
        new KernelNamedMixinApplicationBuilder(metadata, name, typeVariables,
            modifiers, mixinApplication, interfaces, declarationTypes, this,
            charOffset);
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedDeclaration();
    addBuilder(name, builder, charOffset);
  }

  void addField(List<MetadataBuilder> metadata,
      int modifiers, KernelTypeBuilder type, String name, int charOffset) {
    addBuilder(name, new KernelFieldBuilder(
            metadata, type, name, modifiers, this, charOffset), charOffset);
  }

  void addProcedure(List<MetadataBuilder> metadata,
      int modifiers, KernelTypeBuilder returnType, String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals, AsyncMarker asyncModifier,
      ProcedureKind kind, int charOffset, {bool isTopLevel}) {
    // Nested declaration began in `OutlineBuilder.beginMethod` or
    // `OutlineBuilder.beginTopLevelMethod`.
    endNestedDeclaration().resolveTypes(typeVariables);
    addBuilder(name,
        new KernelProcedureBuilder(metadata, modifiers, returnType, name,
            typeVariables, formals, asyncModifier, kind, this, charOffset),
        charOffset);
  }

  void addFactoryMethod(List<MetadataBuilder> metadata,
      ConstructorReferenceBuilder constructorName,
      List<FormalParameterBuilder> formals, AsyncMarker asyncModifier,
      ConstructorReferenceBuilder redirectionTarget, int charOffset) {
    String name = constructorName.name;
    assert(constructorName.suffix == null);
    addBuilder(name,
        new KernelProcedureBuilder(metadata, staticMask, null, name, null,
            formals, asyncModifier, ProcedureKind.Factory, this, charOffset,
            redirectionTarget), charOffset);
  }

  void addEnum(List<MetadataBuilder> metadata, String name,
      List<String> constants, int charOffset) {
    addBuilder(name,
        new KernelEnumBuilder(metadata, name, constants, this, charOffset),
        charOffset);
  }

  void addFunctionTypeAlias(List<MetadataBuilder> metadata,
      KernelTypeBuilder returnType, String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals, int charOffset) {
    FunctionTypeAliasBuilder typedef = new KernelFunctionTypeAliasBuilder(
        metadata, returnType, name, typeVariables, formals, declarationTypes,
        this, charOffset);
    // Nested declaration began in `OutlineBuilder.beginFunctionTypeAlias`.
    endNestedDeclaration();
    addBuilder(name, typedef, charOffset);
  }

  KernelFormalParameterBuilder addFormalParameter(
      List<MetadataBuilder> metadata, int modifiers,
      KernelTypeBuilder type, String name, bool hasThis, int charOffset) {
    return new KernelFormalParameterBuilder(
        metadata, modifiers, type, name, hasThis, this, charOffset);
  }

  KernelTypeVariableBuilder addTypeVariable(String name,
      KernelTypeBuilder bound, int charOffset) {
    return new KernelTypeVariableBuilder(name, this, charOffset, bound);
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
      String name, Builder builder, Builder other, int charOffset) {
    if (builder.next == null && other.next == null) {
      if (builder.isGetter && other.isSetter) {
        return new MixedAccessor(builder, other, this);
      } else if (builder.isSetter && other.isGetter) {
        return new MixedAccessor(other, builder, this);
      }
    }
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri);
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
