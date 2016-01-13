// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.elements;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/name_filter.dart';

/**
 * Serialize all the elements in [lib] to a summary using [ctx] as the context
 * for building the summary, and using [typeProvider] to find built-in types.
 */
LibrarySerializationResult serializeLibrary(
    LibraryElement lib, TypeProvider typeProvider) {
  var serializer = new _LibrarySerializer(lib, typeProvider);
  PrelinkedLibraryBuilder prelinked = serializer.serializeLibrary();
  return new LibrarySerializationResult(
      prelinked, serializer.unlinkedUnits, serializer.unitUris);
}

/**
 * Data structure holding the result of serializing a [LibraryElement].
 */
class LibrarySerializationResult {
  /**
   * Pre-linked information the given library.
   */
  final PrelinkedLibraryBuilder prelinked;

  /**
   * Unlinked information for the compilation units constituting the library.
   * The zeroth entry in the list is the defining compilation unit; the
   * remaining entries are the parts, in the order listed in the defining
   * compilation unit's part declarations.
   */
  final List<UnlinkedUnitBuilder> unlinkedUnits;

  /**
   * Absolute URI of each compilation unit appearing in the library.
   */
  final List<String> unitUris;

  LibrarySerializationResult(this.prelinked, this.unlinkedUnits, this.unitUris);
}

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single library.`
 */
class _LibrarySerializer {
  /**
   * The library to be serialized.
   */
  final LibraryElement libraryElement;

  /**
   * The type provider.  This is used to locate the library for `dart:core`.
   */
  final TypeProvider typeProvider;

  /**
   * List of objects which should be written to [PrelinkedLibrary.units].
   */
  final List<PrelinkedUnitBuilder> prelinkedUnits = <PrelinkedUnitBuilder>[];

  /**
   * List of unlinked units corresponding to the pre-linked units in
   * [prelinkedUnits],
   */
  final List<UnlinkedUnitBuilder> unlinkedUnits = <UnlinkedUnitBuilder>[];

  /**
   * List of absolute URIs of the compilation units in the library.
   */
  final List<String> unitUris = <String>[];

  /**
   * Map from [LibraryElement] to the index of the entry in the "dependency
   * table" that refers to it.
   */
  final Map<LibraryElement, int> dependencyMap = <LibraryElement, int>{};

  /**
   * The "dependency table".  This is the list of objects which should be
   * written to [PrelinkedLibrary.dependencies].
   */
  final List<PrelinkedDependencyBuilder> dependencies =
      <PrelinkedDependencyBuilder>[];

  /**
   * The prelinked portion of the "imports table".  This is the list of ints
   * which should be written to [PrelinkedLibrary.imports].
   */
  final List<int> prelinkedImports = <int>[];

  /**
   * Map from [Element] to the index of the entry in the "references table"
   * that refers to it.
   */
  final Map<Element, int> referenceMap = <Element, int>{};

  /**
   * The unlinked portion of the "references table".  This is the list of
   * objects which should be written to [UnlinkedUnit.references].
   */
  List<UnlinkedReferenceBuilder> unlinkedReferences;

  /**
   * The prelinked portion of the "references table".  This is the list of
   * objects which should be written to [PrelinkedUnit.references].
   */
  List<PrelinkedReferenceBuilder> prelinkedReferences;

  //final Map<String, int> prefixIndices = <String, int>{};

  /**
   * Index into the "references table" representing an unresolved reference, if
   * such an index exists.  `null` if no such entry has been made in the
   * references table yet.
   */
  int unresolvedReferenceIndex = null;

  /**
   * Set of libraries which have been seen so far while visiting the transitive
   * closure of exports.
   */
  final Set<LibraryElement> librariesAddedToTransitiveExportClosure =
      new Set<LibraryElement>();

  /**
   * Map from imported element to the prefix which may be used to refer to that
   * element; elements for which no prefix is needed are absent from this map.
   */
  final Map<Element, PrefixElement> prefixMap = <Element, PrefixElement>{};

  _LibrarySerializer(this.libraryElement, this.typeProvider) {
    dependencies.add(encodePrelinkedDependency());
    dependencyMap[libraryElement] = 0;
  }

  /**
   * Retrieve the library element for `dart:core`.
   */
  LibraryElement get coreLibrary => typeProvider.objectType.element.library;

  /**
   * Add all classes, enums, typedefs, executables, and top level variables
   * from the given compilation unit [element] to the library summary.
   * [unitNum] indicates the ordinal position of this compilation unit in the
   * library.
   */
  void addCompilationUnitElements(CompilationUnitElement element, int unitNum) {
    UnlinkedUnitBuilder b = new UnlinkedUnitBuilder();
    referenceMap.clear();
    unlinkedReferences = <UnlinkedReferenceBuilder>[encodeUnlinkedReference()];
    prelinkedReferences = <PrelinkedReferenceBuilder>[
      encodePrelinkedReference(kind: PrelinkedReferenceKind.classOrEnum)
    ];
    List<UnlinkedPublicNameBuilder> names = <UnlinkedPublicNameBuilder>[];
    for (PropertyAccessorElement accessor in element.accessors) {
      if (accessor.isPublic) {
        names.add(encodeUnlinkedPublicName(
            kind: PrelinkedReferenceKind.topLevelPropertyAccessor,
            name: accessor.name,
            numTypeParameters: accessor.typeParameters.length));
      }
    }
    for (ClassElement cls in element.types) {
      if (cls.isPublic) {
        names.add(encodeUnlinkedPublicName(
            kind: PrelinkedReferenceKind.classOrEnum,
            name: cls.name,
            numTypeParameters: cls.typeParameters.length));
      }
    }
    for (ClassElement enm in element.enums) {
      if (enm.isPublic) {
        names.add(encodeUnlinkedPublicName(
            kind: PrelinkedReferenceKind.classOrEnum, name: enm.name));
      }
    }
    for (FunctionElement function in element.functions) {
      if (function.isPublic) {
        names.add(encodeUnlinkedPublicName(
            kind: PrelinkedReferenceKind.topLevelFunction,
            name: function.name,
            numTypeParameters: function.typeParameters.length));
      }
    }
    for (FunctionTypeAliasElement typedef in element.functionTypeAliases) {
      if (typedef.isPublic) {
        names.add(encodeUnlinkedPublicName(
            kind: PrelinkedReferenceKind.typedef,
            name: typedef.name,
            numTypeParameters: typedef.typeParameters.length));
      }
    }
    if (unitNum == 0) {
      if (libraryElement.name.isNotEmpty) {
        b.libraryName = libraryElement.name;
        b.libraryNameOffset = libraryElement.nameOffset;
        b.libraryNameLength = libraryElement.nameLength;
        b.libraryDocumentationComment = serializeDocumentation(libraryElement);
      }
      b.publicNamespace = encodeUnlinkedPublicNamespace(
          exports: libraryElement.exports.map(serializeExportPublic).toList(),
          parts: libraryElement.parts
              .map((CompilationUnitElement e) => e.uri)
              .toList(),
          names: names);
      b.exports = libraryElement.exports.map(serializeExportNonPublic).toList();
      b.imports = libraryElement.imports.map(serializeImport).toList();
      b.parts = libraryElement.parts
          .map((CompilationUnitElement e) =>
              encodeUnlinkedPart(uriOffset: e.uriOffset, uriEnd: e.uriEnd))
          .toList();
    } else {
      // TODO(paulberry): we need to figure out a way to record library, part,
      // import, and export declarations that appear in non-defining
      // compilation units (even though such declarations are prohibited by the
      // language), so that if the user makes code changes that cause a
      // non-defining compilation unit to become a defining compilation unit,
      // we can create a correct summary by simply re-linking.
      b.publicNamespace = encodeUnlinkedPublicNamespace(names: names);
    }
    b.classes = element.types.map(serializeClass).toList();
    b.enums = element.enums.map(serializeEnum).toList();
    b.typedefs = element.functionTypeAliases.map(serializeTypedef).toList();
    List<UnlinkedExecutableBuilder> executables =
        element.functions.map(serializeExecutable).toList();
    for (PropertyAccessorElement accessor in element.accessors) {
      if (!accessor.isSynthetic) {
        executables.add(serializeExecutable(accessor));
      }
    }
    b.executables = executables;
    List<UnlinkedVariableBuilder> variables = <UnlinkedVariableBuilder>[];
    for (PropertyAccessorElement accessor in element.accessors) {
      if (accessor.isSynthetic && accessor.isGetter) {
        PropertyInducingElement variable = accessor.variable;
        if (variable != null) {
          assert(!variable.isSynthetic);
          variables.add(serializeVariable(variable));
        }
      }
    }
    b.variables = variables;
    b.references = unlinkedReferences;
    unlinkedUnits.add(b);
    prelinkedUnits.add(encodePrelinkedUnit(references: prelinkedReferences));
    unitUris.add(element.source.uri.toString());
    unlinkedReferences = null;
    prelinkedReferences = null;
  }

  /**
   * Add [exportedLibrary] (and the transitive closure of all libraries it
   * exports) to the dependency table ([PrelinkedLibrary.dependencies]).
   */
  void addTransitiveExportClosure(LibraryElement exportedLibrary) {
    if (librariesAddedToTransitiveExportClosure.add(exportedLibrary)) {
      serializeDependency(exportedLibrary);
      for (LibraryElement transitiveExport
          in exportedLibrary.exportedLibraries) {
        addTransitiveExportClosure(transitiveExport);
      }
    }
  }

  /**
   * Fill in [prefixMap] using information from [libraryElement.imports].
   */
  void computePrefixMap() {
    for (ImportElement import in libraryElement.imports) {
      if (import.prefix == null) {
        continue;
      }
      import.importedLibrary.exportNamespace.definedNames
          .forEach((String name, Element e) {
        if (new NameFilter.forNamespaceCombinators(import.combinators)
            .accepts(name)) {
          prefixMap[e] = import.prefix;
        }
      });
    }
  }

  /**
   * Compute the appropriate De Bruijn index to represent the given type
   * parameter [type].
   */
  int findTypeParameterIndex(TypeParameterType type, Element context) {
    int index = 0;
    while (context != null) {
      List<TypeParameterElement> typeParameters;
      if (context is ClassElement) {
        typeParameters = context.typeParameters;
      } else if (context is FunctionTypeAliasElement) {
        typeParameters = context.typeParameters;
      } else if (context is ExecutableElement) {
        typeParameters = context.typeParameters;
      }
      if (typeParameters != null) {
        for (int i = 0; i < typeParameters.length; i++) {
          TypeParameterElement param = typeParameters[i];
          if (param == type.element) {
            return index + typeParameters.length - i;
          }
        }
        index += typeParameters.length;
      }
      context = context.enclosingElement;
    }
    throw new StateError('Unbound type parameter $type');
  }

  /**
   * Serialize the given [classElement], creating an [UnlinkedClass].
   */
  UnlinkedClassBuilder serializeClass(ClassElement classElement) {
    UnlinkedClassBuilder b = new UnlinkedClassBuilder();
    b.name = classElement.name;
    b.nameOffset = classElement.nameOffset;
    b.typeParameters =
        classElement.typeParameters.map(serializeTypeParam).toList();
    if (classElement.supertype == null) {
      b.hasNoSupertype = true;
    } else if (!classElement.supertype.isObject) {
      b.supertype = serializeTypeRef(classElement.supertype, classElement);
    }
    b.mixins = classElement.mixins
        .map((InterfaceType t) => serializeTypeRef(t, classElement))
        .toList();
    b.interfaces = classElement.interfaces
        .map((InterfaceType t) => serializeTypeRef(t, classElement))
        .toList();
    List<UnlinkedVariableBuilder> fields = <UnlinkedVariableBuilder>[];
    List<UnlinkedExecutableBuilder> executables = <UnlinkedExecutableBuilder>[];
    for (ConstructorElement executable in classElement.constructors) {
      if (!executable.isSynthetic) {
        executables.add(serializeExecutable(executable));
      }
    }
    for (MethodElement executable in classElement.methods) {
      executables.add(serializeExecutable(executable));
    }
    for (PropertyAccessorElement accessor in classElement.accessors) {
      if (!accessor.isSynthetic) {
        executables.add(serializeExecutable(accessor));
      } else if (accessor.isGetter) {
        PropertyInducingElement field = accessor.variable;
        if (field != null && !field.isSynthetic) {
          fields.add(serializeVariable(field));
        }
      }
    }
    b.fields = fields;
    b.executables = executables;
    b.isAbstract = classElement.isAbstract;
    b.isMixinApplication = classElement.isMixinApplication;
    b.documentationComment = serializeDocumentation(classElement);
    return b;
  }

  /**
   * Serialize the given [combinator] into an [UnlinkedCombinator].
   */
  UnlinkedCombinatorBuilder serializeCombinator(
      NamespaceCombinator combinator) {
    UnlinkedCombinatorBuilder b = new UnlinkedCombinatorBuilder();
    if (combinator is ShowElementCombinator) {
      b.shows = combinator.shownNames;
    } else if (combinator is HideElementCombinator) {
      b.hides = combinator.hiddenNames;
    }
    return b;
  }

  /**
   * Return the index of the entry in the dependency table
   * ([PrelinkedLibrary.dependencies]) for the given [dependentLibrary].  A new
   * entry is added to the table if necessary to satisfy the request.
   */
  int serializeDependency(LibraryElement dependentLibrary) {
    return dependencyMap.putIfAbsent(dependentLibrary, () {
      int index = dependencies.length;
      List<String> parts = dependentLibrary.parts
          .map((CompilationUnitElement e) => e.source.uri.toString())
          .toList();
      dependencies.add(encodePrelinkedDependency(
          uri: dependentLibrary.source.uri.toString(), parts: parts));
      return index;
    });
  }

  /**
   * Serialize documentation from the given [element], creating an
   * [UnlinkedDocumentationComment].
   *
   * If [element] has no documentation, `null` is returned.
   */
  UnlinkedDocumentationCommentBuilder serializeDocumentation(Element element) {
    if (element.documentationComment == null) {
      return null;
    }
    return encodeUnlinkedDocumentationComment(
        text: element.documentationComment,
        offset: element.docRange.offset,
        length: element.docRange.length);
  }

  /**
   * Return the index of the entry in the references table
   * ([UnlinkedLibrary.references] and [PrelinkedLibrary.references])
   * representing the pseudo-type `dynamic`.
   */
  int serializeDynamicReference() => 0;

  /**
   * Serialize the given [enumElement], creating an [UnlinkedEnum].
   */
  UnlinkedEnumBuilder serializeEnum(ClassElement enumElement) {
    UnlinkedEnumBuilder b = new UnlinkedEnumBuilder();
    b.name = enumElement.name;
    b.nameOffset = enumElement.nameOffset;
    List<UnlinkedEnumValueBuilder> values = <UnlinkedEnumValueBuilder>[];
    for (FieldElement field in enumElement.fields) {
      if (field.isConst && field.type.element == enumElement) {
        values.add(encodeUnlinkedEnumValue(
            name: field.name,
            nameOffset: field.nameOffset,
            documentationComment: serializeDocumentation(field)));
      }
    }
    b.values = values;
    b.documentationComment = serializeDocumentation(enumElement);
    return b;
  }

  /**
   * Serialize the given [executableElement], creating an [UnlinkedExecutable].
   */
  UnlinkedExecutableBuilder serializeExecutable(
      ExecutableElement executableElement) {
    UnlinkedExecutableBuilder b = new UnlinkedExecutableBuilder();
    b.name = executableElement.name;
    b.nameOffset = executableElement.nameOffset;
    if (executableElement is! ConstructorElement &&
        !executableElement.type.returnType.isVoid) {
      b.returnType = serializeTypeRef(
          executableElement.type.returnType, executableElement);
    }
    b.typeParameters =
        executableElement.typeParameters.map(serializeTypeParam).toList();
    b.parameters =
        executableElement.type.parameters.map(serializeParam).toList();
    if (executableElement is PropertyAccessorElement) {
      if (executableElement.isGetter) {
        b.kind = UnlinkedExecutableKind.getter;
      } else {
        b.kind = UnlinkedExecutableKind.setter;
      }
    } else if (executableElement is ConstructorElement) {
      b.kind = UnlinkedExecutableKind.constructor;
      b.isConst = executableElement.isConst;
      b.isFactory = executableElement.isFactory;
    } else {
      b.kind = UnlinkedExecutableKind.functionOrMethod;
    }
    b.isAbstract = executableElement.isAbstract;
    b.isStatic = executableElement.isStatic &&
        executableElement.enclosingElement is ClassElement;
    b.hasImplicitReturnType = executableElement.hasImplicitReturnType;
    b.isExternal = executableElement.isExternal;
    b.documentationComment = serializeDocumentation(executableElement);
    return b;
  }

  /**
   * Serialize the given [exportElement] into an [UnlinkedExportNonPublic].
   */
  UnlinkedExportNonPublicBuilder serializeExportNonPublic(
      ExportElement exportElement) {
    UnlinkedExportNonPublicBuilder b = new UnlinkedExportNonPublicBuilder();
    b.offset = exportElement.nameOffset;
    b.uriOffset = exportElement.uriOffset;
    b.uriEnd = exportElement.uriEnd;
    return b;
  }

  /**
   * Serialize the given [exportElement] into an [UnlinkedExportPublic].
   */
  UnlinkedExportPublicBuilder serializeExportPublic(
      ExportElement exportElement) {
    addTransitiveExportClosure(exportElement.exportedLibrary);
    UnlinkedExportPublicBuilder b = new UnlinkedExportPublicBuilder();
    b.uri = exportElement.uri;
    b.combinators = exportElement.combinators.map(serializeCombinator).toList();
    return b;
  }

  /**
   * Serialize the given [importElement] yielding an [UnlinkedImportBuilder].
   * Also, add pre-linked information about it to the [prelinkedImports] list.
   */
  UnlinkedImportBuilder serializeImport(ImportElement importElement) {
    UnlinkedImportBuilder b = new UnlinkedImportBuilder();
    b.isDeferred = importElement.isDeferred;
    b.offset = importElement.nameOffset;
    b.combinators = importElement.combinators.map(serializeCombinator).toList();
    if (importElement.prefix != null) {
      b.prefixReference = serializePrefix(importElement.prefix);
      b.prefixOffset = importElement.prefix.nameOffset;
    }
    if (importElement.isSynthetic) {
      b.isImplicit = true;
    } else {
      b.uri = importElement.uri;
      b.uriOffset = importElement.uriOffset;
      b.uriEnd = importElement.uriEnd;
    }
    addTransitiveExportClosure(importElement.importedLibrary);
    prelinkedImports.add(serializeDependency(importElement.importedLibrary));
    return b;
  }

  /**
   * Serialize the whole library element into a [PrelinkedLibrary].  Should be
   * called exactly once for each instance of [_LibrarySerializer].
   *
   * The unlinked compilation units are stored in [unlinkedUnits], and their
   * absolute URIs are stored in [unitUris].
   */
  PrelinkedLibraryBuilder serializeLibrary() {
    computePrefixMap();
    PrelinkedLibraryBuilder pb = new PrelinkedLibraryBuilder();
    addCompilationUnitElements(libraryElement.definingCompilationUnit, 0);
    for (int i = 0; i < libraryElement.parts.length; i++) {
      addCompilationUnitElements(libraryElement.parts[i], i + 1);
    }
    pb.units = prelinkedUnits;
    pb.dependencies = dependencies;
    pb.importDependencies = prelinkedImports;
    List<String> exportedNames =
        libraryElement.exportNamespace.definedNames.keys.toList();
    exportedNames.sort();
    List<PrelinkedExportNameBuilder> exportNames =
        <PrelinkedExportNameBuilder>[];
    for (String name in exportedNames) {
      if (libraryElement.publicNamespace.definedNames.containsKey(name)) {
        continue;
      }
      Element element = libraryElement.exportNamespace.get(name);
      LibraryElement dependentLibrary = element.library;
      CompilationUnitElement unitElement =
          element.getAncestor((Element e) => e is CompilationUnitElement);
      int unit = dependentLibrary.units.indexOf(unitElement);
      assert(unit != -1);
      PrelinkedReferenceKind kind;
      if (element is PropertyAccessorElement) {
        kind = PrelinkedReferenceKind.topLevelPropertyAccessor;
      } else if (element is FunctionTypeAliasElement) {
        kind = PrelinkedReferenceKind.typedef;
      } else if (element is ClassElement) {
        kind = PrelinkedReferenceKind.classOrEnum;
      } else if (element is FunctionElement) {
        kind = PrelinkedReferenceKind.topLevelFunction;
      } else {
        throw new Exception('Unexpected element kind: ${element.runtimeType}');
      }
      exportNames.add(encodePrelinkedExportName(
          name: name,
          dependency: serializeDependency(dependentLibrary),
          unit: unit,
          kind: kind));
    }
    pb.exportNames = exportNames;
    return pb;
  }

  /**
   * Serialize the given [parameter] into an [UnlinkedParam].
   */
  UnlinkedParamBuilder serializeParam(ParameterElement parameter,
      [Element context]) {
    context ??= parameter;
    UnlinkedParamBuilder b = new UnlinkedParamBuilder();
    b.name = parameter.name;
    b.nameOffset = parameter.nameOffset;
    switch (parameter.parameterKind) {
      case ParameterKind.REQUIRED:
        b.kind = UnlinkedParamKind.required;
        break;
      case ParameterKind.POSITIONAL:
        b.kind = UnlinkedParamKind.positional;
        break;
      case ParameterKind.NAMED:
        b.kind = UnlinkedParamKind.named;
        break;
    }
    b.isInitializingFormal = parameter.isInitializingFormal;
    DartType type = parameter.type;
    if (type is FunctionType) {
      b.isFunctionTyped = true;
      if (!type.returnType.isVoid) {
        b.type = serializeTypeRef(type.returnType, parameter);
      }
      b.parameters = type.parameters
          .map((parameter) => serializeParam(parameter, context))
          .toList();
    } else {
      b.type = serializeTypeRef(type, context);
      b.hasImplicitType = parameter.hasImplicitType;
    }
    return b;
  }

  /**
   * Serialize the given [prefix] into an index into the references table.
   */
  int serializePrefix(PrefixElement element) {
    return referenceMap.putIfAbsent(element, () {
      assert(unlinkedReferences.length == prelinkedReferences.length);
      int index = unlinkedReferences.length;
      unlinkedReferences.add(encodeUnlinkedReference(name: element.name));
      prelinkedReferences
          .add(encodePrelinkedReference(kind: PrelinkedReferenceKind.prefix));
      return index;
    });
  }

  /**
   * Serialize the given [typedefElement], creating an [UnlinkedTypedef].
   */
  UnlinkedTypedefBuilder serializeTypedef(
      FunctionTypeAliasElement typedefElement) {
    UnlinkedTypedefBuilder b = new UnlinkedTypedefBuilder();
    b.name = typedefElement.name;
    b.nameOffset = typedefElement.nameOffset;
    b.typeParameters =
        typedefElement.typeParameters.map(serializeTypeParam).toList();
    if (!typedefElement.returnType.isVoid) {
      b.returnType =
          serializeTypeRef(typedefElement.returnType, typedefElement);
    }
    b.parameters = typedefElement.parameters.map(serializeParam).toList();
    b.documentationComment = serializeDocumentation(typedefElement);
    return b;
  }

  /**
   * Serialize the given [typeParameter] into an [UnlinkedTypeParam].
   */
  UnlinkedTypeParamBuilder serializeTypeParam(
      TypeParameterElement typeParameter) {
    UnlinkedTypeParamBuilder b = new UnlinkedTypeParamBuilder();
    b.name = typeParameter.name;
    b.nameOffset = typeParameter.nameOffset;
    if (typeParameter.bound != null) {
      b.bound = serializeTypeRef(typeParameter.bound, typeParameter);
    }
    return b;
  }

  /**
   * Serialize the given [type] into an [UnlinkedTypeRef].
   */
  UnlinkedTypeRefBuilder serializeTypeRef(DartType type, Element context) {
    UnlinkedTypeRefBuilder b = new UnlinkedTypeRefBuilder();
    if (type is TypeParameterType) {
      b.paramReference = findTypeParameterIndex(type, context);
    } else {
      Element element = type.element;
      LibraryElement dependentLibrary = element.library;
      if (dependentLibrary == null) {
        assert(type.isDynamic);
        if (type is UndefinedTypeImpl) {
          b.reference = serializeUnresolvedReference();
        } else {
          b.reference = serializeDynamicReference();
        }
      } else {
        b.reference = referenceMap.putIfAbsent(element, () {
          assert(unlinkedReferences.length == prelinkedReferences.length);
          CompilationUnitElement unitElement =
              element.getAncestor((Element e) => e is CompilationUnitElement);
          int unit = dependentLibrary.units.indexOf(unitElement);
          assert(unit != -1);
          int numTypeParameters = 0;
          if (element is TypeParameterizedElement) {
            numTypeParameters = element.typeParameters.length;
          }
          // Figure out a prefix that may be used to refer to the given type.
          // TODO(paulberry): to avoid subtle relinking inconsistencies we
          // should use the actual prefix from the AST (a given type may be
          // reachable via multiple prefixes), but sadly, this information is
          // not recorded in the element model.
          int prefixReference = 0;
          PrefixElement prefix = prefixMap[element];
          if (prefix != null) {
            prefixReference = serializePrefix(prefix);
          }
          int index = unlinkedReferences.length;
          unlinkedReferences.add(encodeUnlinkedReference(
              name: element.name, prefixReference: prefixReference));
          prelinkedReferences.add(encodePrelinkedReference(
              dependency: serializeDependency(dependentLibrary),
              kind: element is FunctionTypeAliasElement
                  ? PrelinkedReferenceKind.typedef
                  : PrelinkedReferenceKind.classOrEnum,
              unit: unit,
              numTypeParameters: numTypeParameters));
          return index;
        });
      }
      List<DartType> typeArguments;
      if (type is InterfaceType) {
        typeArguments = type.typeArguments;
      } else if (type is FunctionType) {
        typeArguments = type.typeArguments;
      }
      if (typeArguments != null &&
          typeArguments.any((DartType argument) => !argument.isDynamic)) {
        b.typeArguments = typeArguments
            .map((DartType t) => serializeTypeRef(t, context))
            .toList();
      }
    }
    return b;
  }

  /**
   * Return the index of the entry in the references table
   * ([UnlinkedLibrary.references] and [PrelinkedLibrary.references]) used for
   * unresolved references.  A new entry is added to the table if necessary to
   * satisfy the request.
   */
  int serializeUnresolvedReference() {
    // TODO(paulberry): in order for relinking to work, we need to record the
    // name and prefix of the unresolved symbol.  This is not (yet) encoded in
    // the element model.  For the moment we use a name that can't possibly
    // ever exist.
    if (unresolvedReferenceIndex == null) {
      assert(unlinkedReferences.length == prelinkedReferences.length);
      unresolvedReferenceIndex = unlinkedReferences.length;
      unlinkedReferences.add(encodeUnlinkedReference(name: '*unresolved*'));
      prelinkedReferences.add(
          encodePrelinkedReference(kind: PrelinkedReferenceKind.unresolved));
    }
    return unresolvedReferenceIndex;
  }

  /**
   * Serialize the given [variable], creating an [UnlinkedVariable].
   */
  UnlinkedVariableBuilder serializeVariable(PropertyInducingElement variable) {
    UnlinkedVariableBuilder b = new UnlinkedVariableBuilder();
    b.name = variable.name;
    b.nameOffset = variable.nameOffset;
    b.type = serializeTypeRef(variable.type, variable);
    b.isStatic = variable.isStatic && variable.enclosingElement is ClassElement;
    b.isFinal = variable.isFinal;
    b.isConst = variable.isConst;
    b.hasImplicitType = variable.hasImplicitType;
    b.documentationComment = serializeDocumentation(variable);
    return b;
  }
}
