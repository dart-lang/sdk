// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_library_builder;

import 'package:front_end/src/fasta/scanner/token.dart' show Token;

import 'package:kernel/ast.dart';

import 'package:kernel/clone.dart' show CloneVisitor;

import '../errors.dart' show internalError;

import '../loader.dart' show Loader;

import '../modifier.dart' show abstractMask, staticMask;

import '../source/source_library_builder.dart'
    show DeclarationBuilder, SourceLibraryBuilder;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../util/relativize.dart' show relativizeUri;

import 'kernel_builder.dart'
    show
        AccessErrorBuilder,
        Builder,
        BuiltinTypeBuilder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        FormalParameterBuilder,
        FunctionTypeAliasBuilder,
        InvalidTypeBuilder,
        KernelConstructorBuilder,
        KernelEnumBuilder,
        KernelFieldBuilder,
        KernelFormalParameterBuilder,
        KernelFunctionTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        KernelInvalidTypeBuilder,
        KernelMixinApplicationBuilder,
        KernelNamedMixinApplicationBuilder,
        KernelNamedTypeBuilder,
        KernelProcedureBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        NamedMixinApplicationBuilder,
        PrefixBuilder,
        ProcedureBuilder,
        Scope,
        TypeBuilder,
        TypeVariableBuilder,
        compareProcedures;

class KernelLibraryBuilder
    extends SourceLibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  final Map<String, SourceClassBuilder> mixinApplicationClasses =
      <String, SourceClassBuilder>{};

  final List<List> argumentsWithMissingDefaultValues = <List>[];

  final List<KernelProcedureBuilder> nativeMethods = <KernelProcedureBuilder>[];

  final List<KernelTypeVariableBuilder> boundlessTypeVariables =
      <KernelTypeVariableBuilder>[];

  KernelLibraryBuilder(Uri uri, Uri fileUri, Loader loader)
      : library = new Library(uri, fileUri: relativizeUri(fileUri)),
        super(loader, fileUri);

  Library get target => library;

  Uri get uri => library.importUri;

  KernelTypeBuilder addNamedType(
      String name, List<KernelTypeBuilder> arguments, int charOffset) {
    return addType(
        new KernelNamedTypeBuilder(name, arguments, charOffset, fileUri));
  }

  KernelTypeBuilder addMixinApplication(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins, int charOffset) {
    KernelTypeBuilder type = new KernelMixinApplicationBuilder(
        supertype, mixins, this, charOffset, fileUri);
    return addType(type);
  }

  KernelTypeBuilder addVoidType(int charOffset) {
    return addNamedType("void", null, charOffset);
  }

  void addClass(
      List<MetadataBuilder> metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      int charOffset) {
    assert(currentDeclaration.parent == libraryDeclaration);
    Map<String, MemberBuilder> members = currentDeclaration.members;
    Map<String, MemberBuilder> constructors = currentDeclaration.constructors;
    Map<String, MemberBuilder> setters = currentDeclaration.setters;

    Scope classScope = new Scope(
        members, setters, scope.withTypeVariables(typeVariables),
        isModifiable: false);

    // When looking up a constructor, we don't consider type variables or the
    // library scope.
    Scope constructorScope =
        new Scope(constructors, null, null, isModifiable: false);
    ClassBuilder cls = new SourceClassBuilder(
        metadata,
        modifiers,
        className,
        typeVariables,
        supertype,
        interfaces,
        classScope,
        constructorScope,
        this,
        new List<ConstructorReferenceBuilder>.from(constructorReferences),
        charOffset);
    constructorReferences.clear();
    void setParent(String name, MemberBuilder member) {
      while (member != null) {
        member.parent = cls;
        member = member.next;
      }
    }

    members.forEach(setParent);
    constructors.forEach(setParent);
    setters.forEach(setParent);
    // Nested declaration began in `OutlineBuilder.beginClassDeclaration`.
    endNestedDeclaration().resolveTypes(typeVariables, this);
    addBuilder(className, cls, charOffset);
  }

  void addNamedMixinApplication(
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      KernelTypeBuilder mixinApplication,
      List<KernelTypeBuilder> interfaces,
      int charOffset) {
    NamedMixinApplicationBuilder builder =
        new KernelNamedMixinApplicationBuilder(metadata, name, typeVariables,
            modifiers, mixinApplication, interfaces, this, charOffset);
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedDeclaration().resolveTypes(typeVariables, this);
    addBuilder(name, builder, charOffset);
  }

  void addField(List<MetadataBuilder> metadata, int modifiers,
      KernelTypeBuilder type, String name, int charOffset, Token initializer) {
    addBuilder(
        name,
        new KernelFieldBuilder(loader.astFactory, loader.topLevelTypeInferrer,
            metadata, type, name, modifiers, this, charOffset, initializer),
        charOffset);
  }

  String computeAndValidateConstructorName(String name, int charOffset) {
    String className = currentDeclaration.name;
    bool startsWithClassName = name.startsWith(className);
    if (startsWithClassName && name.length == className.length) {
      // Unnamed constructor or factory.
      return "";
    }
    int index = name.indexOf(".");
    if (startsWithClassName && index == className.length) {
      // Named constructor or factory.
      return name.substring(index + 1);
    }
    if (index == -1) {
      // A legal name for a regular method, but not for a constructor.
      return null;
    }
    String suffix = name.substring(index + 1);
    addCompileTimeError(
        charOffset,
        "'$name' isn't a legal method name.\n"
        "Did you mean '$className.$suffix'?");
    return suffix;
  }

  void addProcedure(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      AsyncMarker asyncModifier,
      ProcedureKind kind,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      {bool isTopLevel}) {
    // Nested declaration began in `OutlineBuilder.beginMethod` or
    // `OutlineBuilder.beginTopLevelMethod`.
    endNestedDeclaration().resolveTypes(typeVariables, this);
    ProcedureBuilder procedure;
    String constructorName =
        isTopLevel ? null : computeAndValidateConstructorName(name, charOffset);
    if (constructorName != null) {
      name = constructorName;
      procedure = new KernelConstructorBuilder(
          metadata,
          modifiers & ~abstractMask,
          returnType,
          name,
          typeVariables,
          formals,
          this,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          nativeMethodName);
    } else {
      procedure = new KernelProcedureBuilder(
          metadata,
          modifiers,
          returnType,
          name,
          typeVariables,
          formals,
          asyncModifier,
          kind,
          this,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          nativeMethodName);
    }
    addBuilder(name, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
  }

  void addFactoryMethod(
      List<MetadataBuilder> metadata,
      int modifiers,
      ConstructorReferenceBuilder constructorNameReference,
      List<FormalParameterBuilder> formals,
      AsyncMarker asyncModifier,
      ConstructorReferenceBuilder redirectionTarget,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName) {
    // Nested declaration began in `OutlineBuilder.beginFactoryMethod`.
    DeclarationBuilder<KernelTypeBuilder> factoryDeclaration =
        endNestedDeclaration();
    String name = constructorNameReference.name;
    String constructorName =
        computeAndValidateConstructorName(name, charOffset);
    if (constructorName != null) {
      name = constructorName;
    }
    assert(constructorNameReference.suffix == null);
    KernelProcedureBuilder procedure = new KernelProcedureBuilder(
        metadata,
        staticMask | modifiers,
        null,
        name,
        <TypeVariableBuilder>[],
        formals,
        asyncModifier,
        ProcedureKind.Factory,
        this,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        nativeMethodName,
        redirectionTarget);
    currentDeclaration.addFactoryDeclaration(procedure, factoryDeclaration);
    addBuilder(name, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
  }

  void addEnum(List<MetadataBuilder> metadata, String name,
      List<Object> constantNamesAndOffsets, int charOffset, int charEndOffset) {
    addBuilder(
        name,
        new KernelEnumBuilder(loader.astFactory, metadata, name,
            constantNamesAndOffsets, this, charOffset, charEndOffset),
        charOffset);
  }

  void addFunctionTypeAlias(
      List<MetadataBuilder> metadata,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int charOffset) {
    FunctionTypeAliasBuilder typedef = new KernelFunctionTypeAliasBuilder(
        metadata, returnType, name, typeVariables, formals, this, charOffset);
    // Nested declaration began in `OutlineBuilder.beginFunctionTypeAlias`.
    endNestedDeclaration().resolveTypes(typeVariables, this);
    addBuilder(name, typedef, charOffset);
  }

  KernelFunctionTypeBuilder addFunctionType(
      KernelTypeBuilder returnType,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int charOffset) {
    return new KernelFunctionTypeBuilder(
        charOffset, fileUri, returnType, typeVariables, formals);
  }

  KernelFormalParameterBuilder addFormalParameter(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      bool hasThis,
      int charOffset) {
    return new KernelFormalParameterBuilder(
        metadata, modifiers, type, name, hasThis, this, charOffset);
  }

  KernelTypeVariableBuilder addTypeVariable(
      String name, KernelTypeBuilder bound, int charOffset) {
    var builder = new KernelTypeVariableBuilder(name, this, charOffset, bound);
    boundlessTypeVariables.add(builder);
    return builder;
  }

  @override
  void buildBuilder(Builder builder, LibraryBuilder coreLibrary) {
    if (builder is SourceClassBuilder) {
      Class cls = builder.build(this, coreLibrary);
      library.addClass(cls);
    } else if (builder is KernelFieldBuilder) {
      library.addMember(builder.build(this)..isStatic = true);
    } else if (builder is KernelProcedureBuilder) {
      library.addMember(builder.build(this)..isStatic = true);
    } else if (builder is FunctionTypeAliasBuilder) {
      // Kernel discard typedefs and use their corresponding function types
      // directly.
    } else if (builder is KernelEnumBuilder) {
      library.addClass(builder.build(this, coreLibrary));
    } else if (builder is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
    } else if (builder is BuiltinTypeBuilder) {
      // Nothing needed.
    } else {
      internalError("Unhandled builder: ${builder.runtimeType}");
    }
  }

  @override
  Library build(LibraryBuilder coreLibrary) {
    super.build(coreLibrary);
    library.name = name;
    library.procedures.sort(compareProcedures);
    return library;
  }

  @override
  Builder buildAmbiguousBuilder(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    // TODO(ahe): Can I move this to Scope or Prefix?
    if (builder == other) return builder;
    if (builder is InvalidTypeBuilder) return builder;
    if (other is InvalidTypeBuilder) return other;
    if (builder is AccessErrorBuilder) {
      AccessErrorBuilder error = builder;
      builder = error.builder;
    }
    if (other is AccessErrorBuilder) {
      AccessErrorBuilder error = other;
      other = error.builder;
    }
    bool isLocal = false;
    Builder preferred;
    Uri uri;
    Uri otherUri;
    Uri preferredUri;
    Uri hiddenUri;
    if (scope.local[name] == builder) {
      isLocal = true;
      preferred = builder;
      hiddenUri = other.computeLibraryUri();
    } else {
      uri = builder.computeLibraryUri();
      otherUri = other.computeLibraryUri();
      if (otherUri?.scheme == "dart" && uri?.scheme != "dart") {
        preferred = builder;
        preferredUri = uri;
        hiddenUri = otherUri;
      } else if (uri?.scheme == "dart" && otherUri?.scheme != "dart") {
        preferred = other;
        preferredUri = otherUri;
        hiddenUri = uri;
      }
    }
    if (preferred != null) {
      if (isLocal) {
        if (isExport) {
          addNit(charOffset,
              "Local definition of '$name' hides export from '${hiddenUri}'.");
        } else {
          addNit(charOffset,
              "Local definition of '$name' hides import from '${hiddenUri}'.");
        }
      } else {
        if (isExport) {
          addNit(
              charOffset,
              "Export of '$name' (from '${preferredUri}') hides export from "
              "'${hiddenUri}'.");
        } else {
          addNit(
              charOffset,
              "Import of '$name' (from '${preferredUri}') hides import from "
              "'${hiddenUri}'.");
        }
      }
      return preferred;
    }
    if (builder.next == null && other.next == null) {
      if (isImport && builder is PrefixBuilder && other is PrefixBuilder) {
        // Handles the case where the same prefix is used for different
        // imports.
        return builder
          ..exports.merge(other.exports,
              (String name, Builder existing, Builder member) {
            return buildAmbiguousBuilder(name, existing, member, charOffset,
                isExport: isExport, isImport: isImport);
          });
      }
    }
    if (isExport) {
      addNit(charOffset,
          "'$name' is exported from both '${uri}' and '${otherUri}'.");
    } else {
      addNit(charOffset,
          "'$name' is imported from both '${uri}' and '${otherUri}'.");
    }
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri);
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

  void addNativeMethod(KernelProcedureBuilder method) {
    nativeMethods.add(method);
  }

  int finishNativeMethods() {
    for (KernelProcedureBuilder method in nativeMethods) {
      method.becomeNative(loader);
    }
    return nativeMethods.length;
  }

  List<TypeVariableBuilder> copyTypeVariables(
      List<TypeVariableBuilder> original) {
    List<TypeVariableBuilder> copy = <TypeVariableBuilder>[];
    for (KernelTypeVariableBuilder variable in original) {
      var newVariable = new KernelTypeVariableBuilder(
          variable.name, this, variable.charOffset);
      copy.add(newVariable);
      boundlessTypeVariables.add(newVariable);
    }
    Map<TypeVariableBuilder, TypeBuilder> substitution =
        <TypeVariableBuilder, TypeBuilder>{};
    int i = 0;
    for (KernelTypeVariableBuilder variable in original) {
      substitution[variable] = copy[i++].asTypeBuilder();
    }
    i = 0;
    for (KernelTypeVariableBuilder variable in original) {
      copy[i++].bound = variable.bound?.subst(substitution);
    }
    return copy;
  }

  int finishTypeVariables(ClassBuilder object) {
    int count = boundlessTypeVariables.length;
    for (KernelTypeVariableBuilder builder in boundlessTypeVariables) {
      builder.finish(this, object);
    }
    boundlessTypeVariables.clear();
    return count;
  }

  @override
  void includePart(covariant KernelLibraryBuilder part) {
    super.includePart(part);
    nativeMethods.addAll(part.nativeMethods);
    boundlessTypeVariables.addAll(part.boundlessTypeVariables);
    assert(mixinApplicationClasses.isEmpty);
  }
}
