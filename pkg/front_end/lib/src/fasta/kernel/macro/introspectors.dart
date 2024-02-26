// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/exception_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:kernel/ast.dart';

import '../../builder/builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/library_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/type_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_factory_builder.dart';
import '../../source/source_field_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_procedure_builder.dart';
import '../hierarchy/hierarchy_builder.dart';
import 'identifiers.dart';
import 'types.dart';

class MacroIntrospection {
  final SourceLoader _sourceLoader;
  final MacroTypes types;
  late final ClassHierarchyBuilder _classHierarchy;

  late final macro.TypePhaseIntrospector typePhaseIntrospector;
  late final macro.DeclarationPhaseIntrospector declarationPhaseIntrospector;
  late final macro.DefinitionPhaseIntrospector definitionPhaseIntrospector;

  Map<ClassBuilder, macro.ParameterizedTypeDeclaration> _classDeclarations = {};
  Map<macro.ParameterizedTypeDeclaration, ClassBuilder> _classBuilders = {};
  Map<NominalVariableBuilder, macro.TypeParameterDeclarationImpl>
      _typeParameters = {};
  Map<TypeAliasBuilder, macro.TypeAliasDeclaration> _typeAliasDeclarations = {};
  Map<MemberBuilder, macro.Declaration?> _memberDeclarations = {};
  Map<LibraryBuilder, macro.LibraryImpl> _libraries = {};

  MacroIntrospection(this._sourceLoader)
      : types = new MacroTypes(_sourceLoader);

  void enterTypeMacroPhase() {
    typePhaseIntrospector = new _TypePhaseIntrospector(_sourceLoader);
  }

  void enterDeclarationsMacroPhase(ClassHierarchyBuilder classHierarchy) {
    _classHierarchy = classHierarchy;
    declarationPhaseIntrospector =
        new _DeclarationPhaseIntrospector(this, _classHierarchy, _sourceLoader);
    types.enterDeclarationsMacroPhase(classHierarchy);
  }

  void enterDefinitionMacroPhase() {
    definitionPhaseIntrospector =
        new _DefinitionPhaseIntrospector(this, _classHierarchy, _sourceLoader);
  }

  void clear() {
    types.clear();
  }

  macro.Declaration getMemberDeclaration(MemberBuilder memberBuilder) {
    memberBuilder = memberBuilder.origin as MemberBuilder;
    return _memberDeclarations[memberBuilder] ??=
        _createMemberDeclaration(memberBuilder);
  }

  macro.ParameterizedTypeDeclaration getClassDeclaration(ClassBuilder builder) {
    builder = builder.origin;
    return _classDeclarations[builder] ??= _createClassDeclaration(builder);
  }

  macro.TypeAliasDeclaration getTypeAliasDeclaration(TypeAliasBuilder builder) {
    return _typeAliasDeclarations[builder] ??=
        _createTypeAliasDeclaration(builder);
  }

  ClassBuilder _getClassBuilder(
      macro.ParameterizedTypeDeclaration declaration) {
    return _classBuilders[declaration]!;
  }

  macro.Declaration _createMemberDeclaration(MemberBuilder memberBuilder) {
    if (memberBuilder is SourceProcedureBuilder) {
      return _createFunctionDeclaration(memberBuilder);
    } else if (memberBuilder is SourceFieldBuilder) {
      return _createVariableDeclaration(memberBuilder);
    } else if (memberBuilder is SourceConstructorBuilder) {
      return _createConstructorDeclaration(memberBuilder);
    } else if (memberBuilder is SourceFactoryBuilder) {
      return _createFactoryDeclaration(memberBuilder);
    } else {
      // TODO(johnniwinther): Throw when all members are supported.
      throw new UnimplementedError(
          'Unsupported member ${memberBuilder} (${memberBuilder.runtimeType})');
    }
  }

  macro.TypeDeclaration resolveDeclaration(macro.Identifier identifier) {
    if (identifier is MemberBuilderIdentifier) {
      return getClassDeclaration(identifier.memberBuilder.classBuilder!);
    } else if (identifier is TypeDeclarationBuilderIdentifier) {
      final TypeDeclarationBuilder typeDeclarationBuilder =
          identifier.typeDeclarationBuilder;
      switch (typeDeclarationBuilder) {
        case ClassBuilder():
          return getClassDeclaration(typeDeclarationBuilder);
        case TypeAliasBuilder():
        case NominalVariableBuilder():
        case StructuralVariableBuilder():
        case ExtensionBuilder():
        case ExtensionTypeDeclarationBuilder():
        case InvalidTypeDeclarationBuilder():
        case BuiltinTypeDeclarationBuilder():
        // TODO(johnniwinther): How should we handle this case?
        case OmittedTypeDeclarationBuilder():
      }
      throw new UnimplementedError(
          'Resolving declarations is only supported for classes');
    } else {
      throw new UnimplementedError(
          'Resolving declarations not supported for $identifier');
    }
  }

  macro.ResolvedIdentifier resolveIdentifier(macro.Identifier identifier) {
    if (identifier is IdentifierImpl) {
      return identifier.resolveIdentifier();
    } else {
      throw new UnsupportedError(
          'Unsupported identifier ${identifier} (${identifier.runtimeType})');
    }
  }

  macro.LibraryImpl getLibrary(LibraryBuilder builder) {
    return _libraries[builder] ??= () {
      final Version version = builder.library.languageVersion;
      return new macro.LibraryImpl(
          id: macro.RemoteInstance.uniqueId,
          uri: builder.importUri,
          languageVersion:
              new macro.LanguageVersionImpl(version.major, version.minor),
          // TODO: Provide metadata annotations.
          metadata: const []);
    }();
  }

  macro.ParameterizedTypeDeclaration _createClassDeclaration(
      ClassBuilder builder) {
    assert(
        !builder.isAnonymousMixinApplication,
        "Trying to create a ClassDeclaration for the mixin application "
        "${builder}.");
    TypeBuilder? supertypeBuilder = builder.supertypeBuilder;
    List<TypeBuilder>? mixins;
    while (supertypeBuilder != null) {
      TypeDeclarationBuilder? declaration = supertypeBuilder.declaration;
      if (declaration is ClassBuilder &&
          declaration.isAnonymousMixinApplication) {
        (mixins ??= []).add(declaration.mixedInTypeBuilder!);
        supertypeBuilder = declaration.supertypeBuilder;
      } else {
        break;
      }
    }
    if (mixins != null) {
      mixins = mixins.reversed.toList();
    }
    final TypeDeclarationBuilderIdentifier identifier =
        new TypeDeclarationBuilderIdentifier(
            typeDeclarationBuilder: builder,
            libraryBuilder: builder.libraryBuilder,
            id: macro.RemoteInstance.uniqueId,
            name: builder.name);
    final List<macro.TypeParameterDeclarationImpl> typeParameters =
        _nominalVariableBuildersToDeclarations(
            builder.libraryBuilder, builder.typeVariables);
    final List<macro.NamedTypeAnnotationImpl> interfaces =
        types.typeBuildersToAnnotations(
            builder.libraryBuilder, builder.interfaceBuilders);
    final macro.LibraryImpl library = getLibrary(builder.libraryBuilder);

    macro.ParameterizedTypeDeclaration declaration = builder.isMixinDeclaration
        ? new macro.MixinDeclarationImpl(
                id: macro.RemoteInstance.uniqueId,
                identifier: identifier,
                library: library,
                // TODO: Provide metadata annotations.
                metadata: const [],
                typeParameters: typeParameters,
                hasBase: builder.isBase,
                interfaces: interfaces,
                superclassConstraints: types.typeBuildersToAnnotations(
                    builder.libraryBuilder, builder.onTypes))
            // This cast is not necessary but LUB doesn't give the desired type
            // without it.
            as macro.ParameterizedTypeDeclaration
        : new macro.ClassDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            library: library,
            // TODO: Provide metadata annotations.
            metadata: const [],
            typeParameters: typeParameters,
            interfaces: interfaces,
            hasAbstract: builder.isAbstract,
            hasBase: builder.isBase,
            hasExternal: builder.isExternal,
            hasFinal: builder.isFinal,
            hasInterface: builder.isInterface,
            hasMixin: builder.isMixinClass,
            hasSealed: builder.isSealed,
            mixins:
                types.typeBuildersToAnnotations(builder.libraryBuilder, mixins),
            superclass: supertypeBuilder != null
                ? types.computeTypeAnnotation(
                        builder.libraryBuilder, supertypeBuilder)
                    as macro.NamedTypeAnnotationImpl
                : null);
    _classBuilders[declaration] = builder;
    return declaration;
  }

  macro.TypeAliasDeclaration _createTypeAliasDeclaration(
      TypeAliasBuilder builder) {
    final macro.LibraryImpl library = getLibrary(builder.libraryBuilder);
    List<macro.TypeParameterDeclarationImpl> typeParameters =
        _nominalVariableBuildersToDeclarations(
            builder.libraryBuilder, builder.typeVariables);
    macro.TypeAliasDeclaration declaration = new macro.TypeAliasDeclarationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: new TypeDeclarationBuilderIdentifier(
            typeDeclarationBuilder: builder,
            libraryBuilder: builder.libraryBuilder,
            id: macro.RemoteInstance.uniqueId,
            name: builder.name),
        library: library,
        // TODO: Provide metadata annotations.
        metadata: const [],
        typeParameters: typeParameters,
        aliasedType:
            types.computeTypeAnnotation(builder.libraryBuilder, builder.type));
    return declaration;
  }

  List<List<macro.FormalParameterDeclarationImpl>> _createParameters(
      MemberBuilder builder, List<FormalParameterBuilder>? formals) {
    List<macro.FormalParameterDeclarationImpl>? positionalParameters;
    List<macro.FormalParameterDeclarationImpl>? namedParameters;
    if (formals == null) {
      positionalParameters = namedParameters = const [];
    } else {
      positionalParameters = [];
      namedParameters = [];
      final macro.LibraryImpl library = getLibrary(builder.libraryBuilder);
      for (FormalParameterBuilder formal in formals) {
        macro.TypeAnnotationImpl type =
            types.computeTypeAnnotation(builder.libraryBuilder, formal.type);
        macro.IdentifierImpl identifier = new FormalParameterBuilderIdentifier(
            id: macro.RemoteInstance.uniqueId,
            name: formal.name,
            parameterBuilder: formal,
            libraryBuilder: builder.libraryBuilder);
        if (formal.isNamed) {
          namedParameters.add(new macro.FormalParameterDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            library: library,
            // TODO: Provide metadata annotations.
            metadata: const [],
            isRequired: formal.isRequiredNamed,
            isNamed: true,
            type: type,
          ));
        } else {
          positionalParameters.add(new macro.FormalParameterDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            library: library,
            // TODO: Provide metadata annotations.
            metadata: const [],
            isRequired: formal.isRequiredPositional,
            isNamed: false,
            type: type,
          ));
        }
      }
    }
    return [positionalParameters, namedParameters];
  }

  macro.ConstructorDeclaration _createConstructorDeclaration(
      SourceConstructorBuilder builder) {
    List<FormalParameterBuilder>? formals = null;
    // TODO(johnniwinther): Support formals for other constructors.
    if (builder is DeclaredSourceConstructorBuilder) {
      formals = builder.formals;
    }
    List<List<macro.FormalParameterDeclarationImpl>> parameters =
        _createParameters(builder, formals);
    macro.ParameterizedTypeDeclaration definingClass =
        getClassDeclaration(builder.classBuilder!);
    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: builder.name),
      library: getLibrary(builder.libraryBuilder),
      // TODO: Provide metadata annotations.
      metadata: const [],
      definingType: definingClass.identifier as macro.IdentifierImpl,
      isFactory: builder.isFactory,
      // TODO(johnniwinther): Real implementation of hasBody.
      hasBody: true,
      hasExternal: builder.isExternal,
      positionalParameters: parameters[0],
      namedParameters: parameters[1],
      // TODO(johnniwinther): Support constructor return type.
      returnType: types.computeTypeAnnotation(builder.libraryBuilder, null),
      // TODO(johnniwinther): Support typeParameters
      typeParameters: const [],
    );
  }

  macro.ConstructorDeclaration _createFactoryDeclaration(
      SourceFactoryBuilder builder) {
    List<List<macro.FormalParameterDeclarationImpl>> parameters =
        _createParameters(builder, builder.formals);
    macro.ParameterizedTypeDeclaration definingClass =
        // TODO(johnniwinther): Support extension type factories.
        getClassDeclaration(builder.classBuilder!);

    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: builder.name),
      library: getLibrary(builder.libraryBuilder),
      // TODO: Provide metadata annotations.
      metadata: const [],
      definingType: definingClass.identifier as macro.IdentifierImpl,
      isFactory: builder.isFactory,
      // TODO(johnniwinther): Real implementation of hasBody.
      hasBody: true,
      hasExternal: builder.isExternal,
      positionalParameters: parameters[0],
      namedParameters: parameters[1],
      // TODO(johnniwinther): Support constructor return type.
      returnType: types.computeTypeAnnotation(builder.libraryBuilder, null),
      // TODO(johnniwinther): Support typeParameters
      typeParameters: const [],
    );
  }

  macro.FunctionDeclaration _createFunctionDeclaration(
      SourceProcedureBuilder builder) {
    List<List<macro.FormalParameterDeclarationImpl>> parameters =
        _createParameters(builder, builder.formals);

    macro.ParameterizedTypeDeclaration? definingClass = null;
    if (builder.classBuilder != null) {
      definingClass = getClassDeclaration(builder.classBuilder!);
    }
    final macro.LibraryImpl library = getLibrary(builder.libraryBuilder);
    if (definingClass != null) {
      // TODO(johnniwinther): Should static fields be field or variable
      //  declarations?
      return new macro.MethodDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          library: library,
          // TODO: Provide metadata annotations.
          metadata: const [],
          definingType: definingClass.identifier as macro.IdentifierImpl,
          // TODO(johnniwinther): Real implementation of hasBody.
          hasBody: true,
          hasExternal: builder.isExternal,
          isGetter: builder.isGetter,
          isOperator: builder.isOperator,
          isSetter: builder.isSetter,
          hasStatic: builder.isStatic,
          positionalParameters: parameters[0],
          namedParameters: parameters[1],
          returnType: types.computeTypeAnnotation(
              builder.libraryBuilder, builder.returnType),
          // TODO(johnniwinther): Support typeParameters
          typeParameters: const []);
    } else {
      return new macro.FunctionDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          library: library,
          // TODO(johnniwinther): Provide metadata annotations.
          metadata: const [],
          // TODO(johnniwinther): Real implementation of hasBody.
          hasBody: true,
          hasExternal: builder.isExternal,
          isGetter: builder.isGetter,
          isOperator: builder.isOperator,
          isSetter: builder.isSetter,
          positionalParameters: parameters[0],
          namedParameters: parameters[1],
          returnType: types.computeTypeAnnotation(
              builder.libraryBuilder, builder.returnType),
          // TODO(johnniwinther): Support typeParameters
          typeParameters: const []);
    }
  }

  macro.VariableDeclaration _createVariableDeclaration(
      SourceFieldBuilder builder) {
    macro.ParameterizedTypeDeclaration? definingClass = null;
    if (builder.classBuilder != null) {
      definingClass = getClassDeclaration(builder.classBuilder!);
    }
    final macro.LibraryImpl library = getLibrary(builder.libraryBuilder);
    if (definingClass != null) {
      // TODO(johnniwinther): Should static fields be field or variable
      //  declarations?
      return new macro.FieldDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          library: library,
          // TODO: Provide metadata annotations.
          metadata: const [],
          definingType: definingClass.identifier as macro.IdentifierImpl,
          hasAbstract: builder.isAbstract,
          hasConst: builder.isConst,
          hasExternal: builder.isExternal,
          hasFinal: builder.isFinal,
          hasInitializer: builder.hasInitializer,
          hasLate: builder.isLate,
          hasStatic: builder.isStatic,
          type: types.computeTypeAnnotation(
              builder.libraryBuilder, builder.type));
    } else {
      return new macro.VariableDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          library: library,
          // TODO: Provide metadata annotations.
          metadata: const [],
          hasConst: builder.isConst,
          hasExternal: builder.isExternal,
          hasFinal: builder.isFinal,
          hasInitializer: builder.hasInitializer,
          hasLate: builder.isLate,
          type: types.computeTypeAnnotation(
              builder.libraryBuilder, builder.type));
    }
  }

  macro.TypeParameterDeclarationImpl _createTypeParameterDeclaration(
      LibraryBuilder libraryBuilder,
      NominalVariableBuilder nominalVariableBuilder) {
    final macro.LibraryImpl library = getLibrary(libraryBuilder);
    return new macro.TypeParameterDeclarationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: new TypeDeclarationBuilderIdentifier(
            typeDeclarationBuilder: nominalVariableBuilder,
            libraryBuilder: libraryBuilder,
            id: macro.RemoteInstance.uniqueId,
            name: nominalVariableBuilder.name),
        library: library,
        // TODO: Provide metadata annotations.
        metadata: const [],
        bound: types.computeTypeAnnotation(
            libraryBuilder, nominalVariableBuilder.bound));
  }

  macro.TypeParameterDeclarationImpl _getTypeParameterDeclaration(
      LibraryBuilder libraryBuilder,
      NominalVariableBuilder nominalVariableBuilder) {
    return _typeParameters[nominalVariableBuilder] ??=
        _createTypeParameterDeclaration(libraryBuilder, nominalVariableBuilder);
  }

  List<macro.TypeParameterDeclarationImpl>
      _nominalVariableBuildersToDeclarations(LibraryBuilder libraryBuilder,
          List<NominalVariableBuilder>? typeParameterBuilders) {
    return typeParameterBuilders == null
        ? []
        : typeParameterBuilders
            .map((NominalVariableBuilder typeBuilder) =>
                _getTypeParameterDeclaration(libraryBuilder, typeBuilder))
            .toList();
  }
}

class _TypePhaseIntrospector implements macro.TypePhaseIntrospector {
  final SourceLoader sourceLoader;

  _TypePhaseIntrospector(this.sourceLoader);

  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) {
    LibraryBuilder? libraryBuilder = sourceLoader.lookupLibraryBuilder(library);
    if (libraryBuilder == null) {
      return new Future.error(
          new macro.MacroImplementationExceptionImpl(
              'Library at uri $library could not be resolved.'),
          StackTrace.current);
    }
    bool isSetter = false;
    String memberName = name;
    if (name.endsWith('=')) {
      memberName = name.substring(0, name.length - 1);
      isSetter = true;
    }
    Builder? builder =
        libraryBuilder.scope.lookupLocalMember(memberName, setter: isSetter);
    if (builder == null) {
      return new Future.error(
          new macro.MacroImplementationExceptionImpl(
              'Unable to find top level identifier "$name" in $library'),
          StackTrace.current);
    } else if (builder is TypeDeclarationBuilder) {
      return new Future.value(new TypeDeclarationBuilderIdentifier(
          typeDeclarationBuilder: builder,
          libraryBuilder: libraryBuilder,
          id: macro.RemoteInstance.uniqueId,
          name: name));
    } else if (builder is MemberBuilder) {
      return new Future.value(new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: name));
    } else {
      return new Future.error(
          new UnsupportedError('Unsupported identifier kind $builder'),
          StackTrace.current);
    }
  }
}

class _DeclarationPhaseIntrospector extends _TypePhaseIntrospector
    implements macro.DeclarationPhaseIntrospector {
  final ClassHierarchyBuilder classHierarchy;
  final MacroIntrospection _introspection;

  _DeclarationPhaseIntrospector(
      this._introspection, this.classHierarchy, super.sourceLoader);

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(macro.Identifier identifier) {
    if (identifier is IdentifierImpl) {
      return identifier.resolveTypeDeclaration(_introspection);
    }
    throw new UnsupportedError(
        'Unsupported identifier $identifier (${identifier.runtimeType})');
  }

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
      macro.TypeDeclaration type) {
    if (type is! macro.ClassDeclaration) {
      throw new UnsupportedError('Only introspection on classes is supported');
    }
    ClassBuilder classBuilder = _introspection
        ._getClassBuilder(type as macro.ParameterizedTypeDeclaration);
    List<macro.ConstructorDeclaration> result = [];
    Iterator<MemberBuilder> iterator = classBuilder.fullConstructorIterator();
    while (iterator.moveNext()) {
      MemberBuilder memberBuilder = iterator.current;
      if (memberBuilder is DeclaredSourceConstructorBuilder) {
        // TODO(johnniwinther): Should we support synthesized constructors?
        result.add(_introspection.getMemberDeclaration(memberBuilder)
            as macro.ConstructorDeclaration);
      } else if (memberBuilder is SourceFactoryBuilder) {
        result.add(_introspection.getMemberDeclaration(memberBuilder)
            as macro.ConstructorDeclaration);
      }
    }
    return new Future.value(result);
  }

  @override
  Future<List<macro.EnumValueDeclaration>> valuesOf(
      covariant macro.EnumDeclaration enumType) {
    // TODO: implement valuesOf
    throw new UnimplementedError();
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(macro.TypeDeclaration type) {
    if (type is! macro.ClassDeclaration) {
      throw new UnsupportedError('Only introspection on classes is supported');
    }
    ClassBuilder classBuilder = _introspection._getClassBuilder(type);
    List<macro.FieldDeclaration> result = [];
    Iterator<SourceFieldBuilder> iterator =
        classBuilder.fullMemberIterator<SourceFieldBuilder>();
    while (iterator.moveNext()) {
      result.add(_introspection.getMemberDeclaration(iterator.current)
          as macro.FieldDeclaration);
    }
    return new Future.value(result);
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(macro.TypeDeclaration type) {
    if (type is! macro.ClassDeclaration && type is! macro.MixinDeclaration) {
      throw new UnsupportedError(
          'Only introspection on classes and mixins is supported');
    }
    ClassBuilder classBuilder = _introspection
        ._getClassBuilder(type as macro.ParameterizedTypeDeclaration);
    List<macro.MethodDeclaration> result = [];
    Iterator<SourceProcedureBuilder> iterator =
        classBuilder.fullMemberIterator<SourceProcedureBuilder>();
    while (iterator.moveNext()) {
      result.add(_introspection.getMemberDeclaration(iterator.current)
          as macro.MethodDeclaration);
    }
    return new Future.value(result);
  }

  @override
  Future<List<macro.TypeDeclaration>> typesOf(covariant macro.Library library) {
    // TODO: implement typesOf
    throw new UnimplementedError();
  }

  @override
  Future<macro.StaticType> resolve(macro.TypeAnnotationCode typeAnnotation) {
    return new Future.value(
        _introspection.types.resolveTypeAnnotation(typeAnnotation));
  }
}

class _DefinitionPhaseIntrospector extends _DeclarationPhaseIntrospector
    implements macro.DefinitionPhaseIntrospector {
  _DefinitionPhaseIntrospector(
      super.macroIntrospection, super.classHierarchy, super.sourceLoader);

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
          macro.Identifier identifier) async =>
      (await super.typeDeclarationOf(identifier));

  @override
  Future<macro.TypeAnnotation> inferType(
          macro.OmittedTypeAnnotation omittedType) =>
      new Future.value(_introspection.types.inferOmittedType(omittedType)!);

  @override
  Future<List<macro.Declaration>> topLevelDeclarationsOf(
      macro.Library library) {
    // TODO: implement topLevelDeclarationsOf
    throw new UnimplementedError();
  }

  @override
  Future<macro.Declaration> declarationOf(
      covariant macro.Identifier identifier) {
    if (identifier is IdentifierImpl) {
      return new Future.value(identifier.resolveDeclaration(_introspection));
    } else {
      throw new UnsupportedError(
          'Unsupported identifier ${identifier} (${identifier.runtimeType})');
    }
  }
}
