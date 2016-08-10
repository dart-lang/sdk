// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.elements;

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/name_filter.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_const_expr.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/**
 * Serialize all the elements in [lib] to a summary using [ctx] as the context
 * for building the summary, and using [typeProvider] to find built-in types.
 */
LibrarySerializationResult serializeLibrary(
    LibraryElement lib, TypeProvider typeProvider, bool strongMode) {
  _LibrarySerializer serializer =
      new _LibrarySerializer(lib, typeProvider, strongMode);
  LinkedLibraryBuilder linked = serializer.serializeLibrary();
  return new LibrarySerializationResult(linked, serializer.unlinkedUnits,
      serializer.unitUris, serializer.unitSources);
}

ReferenceKind _getReferenceKind(Element element) {
  if (element == null ||
      element is ClassElement ||
      element is DynamicElementImpl) {
    return ReferenceKind.classOrEnum;
  } else if (element is ConstructorElement) {
    return ReferenceKind.constructor;
  } else if (element is FunctionElement) {
    if (element.enclosingElement is CompilationUnitElement) {
      return ReferenceKind.topLevelFunction;
    }
    return ReferenceKind.function;
  } else if (element is FunctionTypeAliasElement) {
    return ReferenceKind.typedef;
  } else if (element is PropertyAccessorElement) {
    if (element.enclosingElement is ClassElement) {
      return ReferenceKind.propertyAccessor;
    }
    return ReferenceKind.topLevelPropertyAccessor;
  } else if (element is MethodElement) {
    return ReferenceKind.method;
  } else if (element is TopLevelVariableElement) {
    // Summaries don't need to distinguish between references to a variable and
    // references to its getter.
    return ReferenceKind.topLevelPropertyAccessor;
  } else if (element is LocalVariableElement) {
    return ReferenceKind.variable;
  } else if (element is FieldElement) {
    // Summaries don't need to distinguish between references to a field and
    // references to its getter.
    return ReferenceKind.propertyAccessor;
  } else {
    throw new Exception('Unexpected element kind: ${element.runtimeType}');
  }
}

/**
 * Type of closures used by [_LibrarySerializer] to defer generation of
 * [EntityRefBuilder] objects until the end of serialization of a
 * compilation unit.
 */
typedef EntityRefBuilder _SerializeTypeRef();

/**
 * Data structure holding the result of serializing a [LibraryElement].
 */
class LibrarySerializationResult {
  /**
   * Linked information the given library.
   */
  final LinkedLibraryBuilder linked;

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

  /**
   * Source object corresponding to each compilation unit appearing in the
   * library.
   */
  final List<Source> unitSources;

  LibrarySerializationResult(
      this.linked, this.unlinkedUnits, this.unitUris, this.unitSources);
}

/**
 * Object that gathers information uses it to assemble a new
 * [PackageBundleBuilder].
 */
class PackageBundleAssembler {
  /**
   * Value that will be stored in [PackageBundle.majorVersion] for any summaries
   * created by this code.  When making a breaking change to the summary format,
   * this value should be incremented by 1 and [currentMinorVersion] should be
   * reset to zero.
   */
  static const int currentMajorVersion = 1;

  /**
   * Value that will be stored in [PackageBundle.minorVersion] for any summaries
   * created by this code.  When making a non-breaking change to the summary
   * format that clients might need to be aware of (such as adding a kind of
   * data that was previously not summarized), this value should be incremented
   * by 1.
   */
  static const int currentMinorVersion = 0;

  final List<String> _linkedLibraryUris = <String>[];
  final List<LinkedLibraryBuilder> _linkedLibraries = <LinkedLibraryBuilder>[];
  final List<String> _unlinkedUnitUris = <String>[];
  final List<UnlinkedUnitBuilder> _unlinkedUnits = <UnlinkedUnitBuilder>[];
  final Map<String, UnlinkedUnitBuilder> _unlinkedUnitMap =
      <String, UnlinkedUnitBuilder>{};
  final List<String> _unlinkedUnitHashes;
  final List<PackageDependencyInfoBuilder> _dependencies =
      <PackageDependencyInfoBuilder>[];
  final bool _excludeHashes;

  /**
   * Create a [PackageBundleAssembler].  If [excludeHashes] is `true`, hash
   * computation will be skipped.
   */
  PackageBundleAssembler({bool excludeHashes: false})
      : _excludeHashes = excludeHashes,
        _unlinkedUnitHashes = excludeHashes ? null : <String>[];

  /**
   * Add a fallback library to the package bundle, corresponding to the library
   * whose defining compilation unit is located at [source].  Caller must also
   * call [addFallbackUnit] for all compilation units contained in the library
   * (including the defining compilation unit).
   */
  void addFallbackLibrary(Source source) {
    String uri = source.uri.toString();
    _linkedLibraryUris.add(uri);
    _linkedLibraries.add(new LinkedLibraryBuilder(fallbackMode: true));
  }

  /**
   * Add a fallback compilation unit to the package bundle, corresponding to
   * the compilation unit located at [source].
   */
  void addFallbackUnit(Source source) {
    String uri = source.uri.toString();
    UnlinkedUnitBuilder unit = new UnlinkedUnitBuilder(
        fallbackModePath: path.relative(source.fullName));
    _unlinkedUnitUris.add(uri);
    _unlinkedUnits.add(unit);
    _unlinkedUnitMap[uri] = unit;
  }

  void addLinkedLibrary(String uri, LinkedLibraryBuilder library) {
    _linkedLibraries.add(library);
    _linkedLibraryUris.add(uri);
  }

  void addUnlinkedUnit(Source source, UnlinkedUnitBuilder unit) {
    addUnlinkedUnitWithHash(source.uri.toString(), unit,
        _excludeHashes ? null : _hash(source.contents.data));
  }

  void addUnlinkedUnitWithHash(
      String uri, UnlinkedUnitBuilder unit, String hash) {
    _unlinkedUnitUris.add(uri);
    _unlinkedUnits.add(unit);
    _unlinkedUnitMap[uri] = unit;
    _unlinkedUnitHashes?.add(hash);
  }

  /**
   * Assemble a new [PackageBundleBuilder] using the gathered information.
   */
  PackageBundleBuilder assemble() {
    return new PackageBundleBuilder(
        linkedLibraryUris: _linkedLibraryUris,
        linkedLibraries: _linkedLibraries,
        unlinkedUnitUris: _unlinkedUnitUris,
        unlinkedUnits: _unlinkedUnits,
        unlinkedUnitHashes: _unlinkedUnitHashes,
        majorVersion: currentMajorVersion,
        minorVersion: currentMinorVersion,
        dependencies: _dependencies,
        apiSignature: _computeApiSignature());
  }

  /**
   * Use the dependency information in [summaryDataStore] to populate the
   * dependencies in the package bundle being assembled.
   */
  void recordDependencies(SummaryDataStore summaryDataStore) {
    _dependencies.addAll(summaryDataStore.dependencies);
  }

  /**
   * Serialize the library with the given [element].
   */
  void serializeLibraryElement(LibraryElement element) {
    String uri = element.source.uri.toString();
    LibrarySerializationResult libraryResult = serializeLibrary(
        element,
        element.context.typeProvider,
        element.context.analysisOptions.strongMode);
    _linkedLibraryUris.add(uri);
    _linkedLibraries.add(libraryResult.linked);
    _unlinkedUnitUris.addAll(libraryResult.unitUris);
    _unlinkedUnits.addAll(libraryResult.unlinkedUnits);
    for (int i = 0; i < libraryResult.unitUris.length; i++) {
      _unlinkedUnitMap[libraryResult.unitUris[i]] =
          libraryResult.unlinkedUnits[i];
    }
    for (Source source in libraryResult.unitSources) {
      _unlinkedUnitHashes?.add(_hash(source.contents.data));
    }
  }

  /**
   * Compute the API signature for this package bundle.
   */
  String _computeApiSignature() {
    ApiSignature apiSignature = new ApiSignature();
    for (String unitUri in _unlinkedUnitMap.keys.toList()..sort()) {
      apiSignature.addString(unitUri);
      _unlinkedUnitMap[unitUri].collectApiSignature(apiSignature);
    }
    return apiSignature.toHex();
  }

  /**
   * Compute a hash of the given file contents.
   */
  String _hash(String contents) {
    return hex.encode(md5.convert(UTF8.encode(contents)).bytes);
  }
}

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single compilation unit.
 */
class _CompilationUnitSerializer {
  /**
   * The [_LibrarySerializer] which is serializing the library of which
   * [compilationUnit] is a part.
   */
  final _LibrarySerializer librarySerializer;

  /**
   * The [CompilationUnitElement] being serialized.
   */
  final CompilationUnitElement compilationUnit;

  /**
   * The ordinal index of [compilationUnit] within the library, where 0
   * represents the defining compilation unit.
   */
  final int unitNum;

  /**
   * The final linked summary of the compilation unit.
   */
  final LinkedUnitBuilder linkedUnit = new LinkedUnitBuilder();

  /**
   * The final unlinked summary of the compilation unit.
   */
  final UnlinkedUnitBuilder unlinkedUnit = new UnlinkedUnitBuilder();

  /**
   * Absolute URI of the compilation unit.
   */
  String unitUri;

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
   * The linked portion of the "references table".  This is the list of
   * objects which should be written to [LinkedUnit.references].
   */
  List<LinkedReferenceBuilder> linkedReferences;

  /**
   * The number of slot ids which have been assigned to this compilation unit.
   */
  int numSlots = 0;

  /**
   * List of closures which should be invoked at the end of serialization of a
   * compilation unit, to produce [LinkedUnit.types].
   */
  final List<_SerializeTypeRef> deferredLinkedTypes = <_SerializeTypeRef>[];

  /**
   * List which should be stored in [LinkedUnit.constCycles].
   */
  final List<int> constCycles = <int>[];

  /**
   * Index into the "references table" representing an unresolved reference, if
   * such an index exists.  `null` if no such entry has been made in the
   * references table yet.
   */
  int unresolvedReferenceIndex = null;

  /**
   * Index into the "references table" representing the "bottom" type, if such
   * an index exists.  `null` if no such entry has been made in the references
   * table yet.
   */
  int bottomReferenceIndex = null;

  /**
   * If `true`, we are currently generating linked references, so new
   * references will be not stored in [unlinkedReferences].
   */
  bool buildingLinkedReferences = false;

  _CompilationUnitSerializer(
      this.librarySerializer, this.compilationUnit, this.unitNum);

  /**
   * Source object for the compilation unit.
   */
  Source get unitSource => compilationUnit.source;

  /**
   * Add all classes, enums, typedefs, executables, and top level variables
   * from the given compilation unit [element] to the compilation unit summary.
   * [unitNum] indicates the ordinal position of this compilation unit in the
   * library.
   */
  void addCompilationUnitElements() {
    unlinkedReferences = <UnlinkedReferenceBuilder>[
      new UnlinkedReferenceBuilder()
    ];
    linkedReferences = <LinkedReferenceBuilder>[
      new LinkedReferenceBuilder(kind: ReferenceKind.unresolved)
    ];
    List<UnlinkedPublicNameBuilder> names = <UnlinkedPublicNameBuilder>[];
    for (PropertyAccessorElement accessor in compilationUnit.accessors) {
      if (accessor.isPublic) {
        names.add(new UnlinkedPublicNameBuilder(
            kind: ReferenceKind.topLevelPropertyAccessor,
            name: accessor.name,
            numTypeParameters: accessor.typeParameters.length));
      }
    }
    for (ClassElement cls in compilationUnit.types) {
      if (cls.isPublic) {
        names.add(new UnlinkedPublicNameBuilder(
            kind: ReferenceKind.classOrEnum,
            name: cls.name,
            numTypeParameters: cls.typeParameters.length,
            members: serializeClassStaticMembers(cls)));
      }
    }
    for (ClassElement enm in compilationUnit.enums) {
      if (enm.isPublic) {
        names.add(new UnlinkedPublicNameBuilder(
            kind: ReferenceKind.classOrEnum,
            name: enm.name,
            members: serializeClassStaticMembers(enm)));
      }
    }
    for (FunctionElement function in compilationUnit.functions) {
      if (function.isPublic) {
        names.add(new UnlinkedPublicNameBuilder(
            kind: ReferenceKind.topLevelFunction,
            name: function.name,
            numTypeParameters: function.typeParameters.length));
      }
    }
    for (FunctionTypeAliasElement typedef
        in compilationUnit.functionTypeAliases) {
      if (typedef.isPublic) {
        names.add(new UnlinkedPublicNameBuilder(
            kind: ReferenceKind.typedef,
            name: typedef.name,
            numTypeParameters: typedef.typeParameters.length));
      }
    }
    if (unitNum == 0) {
      LibraryElement libraryElement = librarySerializer.libraryElement;
      if (libraryElement.name.isNotEmpty) {
        LibraryElement libraryElement = librarySerializer.libraryElement;
        unlinkedUnit.libraryName = libraryElement.name;
        unlinkedUnit.libraryNameOffset = libraryElement.nameOffset;
        unlinkedUnit.libraryNameLength = libraryElement.nameLength;
        unlinkedUnit.libraryDocumentationComment =
            serializeDocumentation(libraryElement);
        unlinkedUnit.libraryAnnotations = serializeAnnotations(libraryElement);
      }
      unlinkedUnit.publicNamespace = new UnlinkedPublicNamespaceBuilder(
          exports: libraryElement.exports.map(serializeExportPublic).toList(),
          parts: libraryElement.parts
              .map((CompilationUnitElement e) => e.uri)
              .toList(),
          names: names);
      unlinkedUnit.exports =
          libraryElement.exports.map(serializeExportNonPublic).toList();
      unlinkedUnit.imports =
          libraryElement.imports.map(serializeImport).toList();
      unlinkedUnit.parts = libraryElement.parts
          .map((CompilationUnitElement e) => new UnlinkedPartBuilder(
              uriOffset: e.uriOffset,
              uriEnd: e.uriEnd,
              annotations: serializeAnnotations(e)))
          .toList();
    } else {
      // TODO(paulberry): we need to figure out a way to record library, part,
      // import, and export declarations that appear in non-defining
      // compilation units (even though such declarations are prohibited by the
      // language), so that if the user makes code changes that cause a
      // non-defining compilation unit to become a defining compilation unit,
      // we can create a correct summary by simply re-linking.
      unlinkedUnit.publicNamespace =
          new UnlinkedPublicNamespaceBuilder(names: names);
    }
    unlinkedUnit.codeRange = serializeCodeRange(compilationUnit);
    unlinkedUnit.classes = compilationUnit.types.map(serializeClass).toList();
    unlinkedUnit.enums = compilationUnit.enums.map(serializeEnum).toList();
    unlinkedUnit.typedefs =
        compilationUnit.functionTypeAliases.map(serializeTypedef).toList();
    List<UnlinkedExecutableBuilder> executables =
        compilationUnit.functions.map(serializeExecutable).toList();
    for (PropertyAccessorElement accessor in compilationUnit.accessors) {
      if (!accessor.isSynthetic) {
        executables.add(serializeExecutable(accessor));
      }
    }
    unlinkedUnit.executables = executables;
    List<UnlinkedVariableBuilder> variables = <UnlinkedVariableBuilder>[];
    for (PropertyAccessorElement accessor in compilationUnit.accessors) {
      if (accessor.isSynthetic && accessor.isGetter) {
        PropertyInducingElement variable = accessor.variable;
        if (variable != null) {
          assert(!variable.isSynthetic);
          variables.add(serializeVariable(variable));
        }
      }
    }
    unlinkedUnit.variables = variables;
    unlinkedUnit.references = unlinkedReferences;
    unlinkedUnit.lineStarts =
        compilationUnit.context?.computeLineInfo(unitSource)?.lineStarts;
    linkedUnit.references = linkedReferences;
    unitUri = compilationUnit.source.uri.toString();
  }

  /**
   * Create the [LinkedUnit.types] table based on deferred types that were
   * found during [addCompilationUnitElements].  Also populate
   * [LinkedUnit.constCycles].
   */
  void createLinkedInfo() {
    buildingLinkedReferences = true;
    linkedUnit.types = deferredLinkedTypes
        .map((_SerializeTypeRef closure) => closure())
        .toList();
    linkedUnit.constCycles = constCycles;
    buildingLinkedReferences = false;
  }

  /**
   * Compute the appropriate De Bruijn index to represent the given type
   * parameter [type], or return `null` if the type parameter is not in scope.
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
    return null;
  }

  /**
   * Get the type arguments for the given [type], or `null` if the type has no
   * type arguments.
   *
   * TODO(paulberry): consider adding an abstract getter to [DartType] to do
   * this.
   */
  List<DartType> getTypeArguments(DartType type) {
    if (type is InterfaceType) {
      return type.typeArguments;
    } else if (type is FunctionType) {
      return type.typeArguments;
    } else {
      return null;
    }
  }

  /**
   * Serialize annotations from the given [element].  If [element] has no
   * annotations, the empty list is returned.
   */
  List<UnlinkedConstBuilder> serializeAnnotations(Element element) {
    if (element.metadata.isEmpty) {
      return const <UnlinkedConstBuilder>[];
    }
    return element.metadata.map((ElementAnnotation a) {
      _ConstExprSerializer serializer =
          new _ConstExprSerializer(this, element, null, null);
      serializer
          .serializeAnnotation((a as ElementAnnotationImpl).annotationAst);
      return serializer.toBuilder();
    }).toList();
  }

  /**
   * Return the index of the entry in the references table
   * ([LinkedLibrary.references]) used for the "bottom" type.  A new entry is
   * added to the table if necessary to satisfy the request.
   */
  int serializeBottomReference() {
    if (bottomReferenceIndex == null) {
      // References to the "bottom" type are always implicit, since there is no
      // way to explicitly refer to the "bottom" type.  Therefore they should
      // be stored only in the linked references table.
      bottomReferenceIndex = linkedReferences.length;
      linkedReferences.add(new LinkedReferenceBuilder(
          name: '*bottom*', kind: ReferenceKind.classOrEnum));
    }
    return bottomReferenceIndex;
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
    b.annotations = serializeAnnotations(classElement);
    b.codeRange = serializeCodeRange(classElement);
    return b;
  }

  /**
   * If [cls] is a class, return the list of its static members - static
   * constant fields, static methods and constructors.  Otherwise return `null`.
   */
  List<UnlinkedPublicNameBuilder> serializeClassStaticMembers(
      ClassElement cls) {
    if (cls.isMixinApplication) {
      // Mixin application members can't be determined directly from the AST so
      // we can't store them in UnlinkedPublicName.
      // TODO(paulberry): find somewhere else to store them.
      return null;
    }
    if (cls.kind == ElementKind.CLASS) {
      List<UnlinkedPublicNameBuilder> bs = <UnlinkedPublicNameBuilder>[];
      for (MethodElement method in cls.methods) {
        if (method.isStatic && method.isPublic) {
          // TODO(paulberry): should numTypeParameters include class params?
          bs.add(new UnlinkedPublicNameBuilder(
              name: method.name,
              kind: ReferenceKind.method,
              numTypeParameters: method.typeParameters.length));
        }
      }
      for (PropertyAccessorElement accessor in cls.accessors) {
        if (accessor.isStatic && accessor.isGetter && accessor.isPublic) {
          // TODO(paulberry): should numTypeParameters include class params?
          bs.add(new UnlinkedPublicNameBuilder(
              name: accessor.name, kind: ReferenceKind.propertyAccessor));
        }
      }
      for (ConstructorElement constructor in cls.constructors) {
        if (constructor.isPublic && constructor.name.isNotEmpty) {
          // TODO(paulberry): should numTypeParameters include class params?
          bs.add(new UnlinkedPublicNameBuilder(
              name: constructor.name,
              kind: ReferenceKind.constructor,
              numTypeParameters: 0));
        }
      }
      return bs;
    }
    return null;
  }

  CodeRangeBuilder serializeCodeRange(Element element) {
    if (element is ElementImpl && element.codeOffset != null) {
      return new CodeRangeBuilder(
          offset: element.codeOffset, length: element.codeLength);
    }
    return null;
  }

  /**
   * Serialize the given [combinator] into an [UnlinkedCombinator].
   */
  UnlinkedCombinatorBuilder serializeCombinator(
      NamespaceCombinator combinator) {
    UnlinkedCombinatorBuilder b = new UnlinkedCombinatorBuilder();
    if (combinator is ShowElementCombinator) {
      b.shows = combinator.shownNames;
      b.offset = combinator.offset;
      b.end = combinator.end;
    } else if (combinator is HideElementCombinator) {
      b.hides = combinator.hiddenNames;
    }
    return b;
  }

  /**
   * Serialize the given [expression], creating an [UnlinkedConstBuilder].
   */
  UnlinkedConstBuilder serializeConstExpr(Element context,
      ExecutableElement executableContext, Expression expression,
      [Set<String> constructorParameterNames]) {
    _ConstExprSerializer serializer = new _ConstExprSerializer(
        this, context, executableContext, constructorParameterNames);
    serializer.serialize(expression);
    return serializer.toBuilder();
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
    return new UnlinkedDocumentationCommentBuilder(
        text: element.documentationComment,
        offset: element.docRange.offset,
        length: element.docRange.length);
  }

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
        values.add(new UnlinkedEnumValueBuilder(
            name: field.name,
            nameOffset: field.nameOffset,
            documentationComment: serializeDocumentation(field)));
      }
    }
    b.values = values;
    b.documentationComment = serializeDocumentation(enumElement);
    b.annotations = serializeAnnotations(enumElement);
    b.codeRange = serializeCodeRange(enumElement);
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
    if (executableElement is ConstructorElement) {
      if (executableElement.name.isNotEmpty) {
        b.nameEnd = executableElement.nameEnd;
        b.periodOffset = executableElement.periodOffset;
      }
    } else {
      if (!executableElement.hasImplicitReturnType) {
        b.returnType = serializeTypeRef(
            executableElement.type.returnType, executableElement);
      } else if (!executableElement.isStatic) {
        b.inferredReturnTypeSlot =
            storeInferredType(executableElement.returnType, executableElement);
      }
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
    } else if (executableElement is ConstructorElementImpl) {
      b.kind = UnlinkedExecutableKind.constructor;
      b.isConst = executableElement.isConst;
      b.isFactory = executableElement.isFactory;
      ConstructorElement redirectedConstructor =
          executableElement.redirectedConstructor;
      if (redirectedConstructor != null) {
        b.isRedirectedConstructor = true;
        if (executableElement.isFactory) {
          InterfaceType returnType = redirectedConstructor is ConstructorMember
              ? redirectedConstructor.definingType
              : redirectedConstructor.enclosingElement.type;
          EntityRefBuilder typeRef =
              serializeTypeRef(returnType, executableElement);
          if (redirectedConstructor.name.isNotEmpty) {
            String name = redirectedConstructor.name;
            int typeId = typeRef.reference;
            LinkedReference typeLinkedRef = linkedReferences[typeId];
            int refId = serializeUnlinkedReference(
                name, ReferenceKind.constructor,
                unit: typeLinkedRef.unit, prefixReference: typeId);
            b.redirectedConstructor = new EntityRefBuilder(
                reference: refId, typeArguments: typeRef.typeArguments);
          } else {
            b.redirectedConstructor = typeRef;
          }
        } else {
          b.redirectedConstructorName = redirectedConstructor.name;
        }
      }
      if (executableElement.isConst) {
        b.constCycleSlot = storeConstCycle(!executableElement.isCycleFree);
        if (executableElement.constantInitializers != null) {
          Set<String> constructorParameterNames =
              executableElement.parameters.map((p) => p.name).toSet();
          b.constantInitializers = executableElement.constantInitializers
              .map((ConstructorInitializer initializer) =>
                  serializeConstructorInitializer(
                      initializer,
                      (expr) => serializeConstExpr(executableElement,
                          executableElement, expr, constructorParameterNames)))
              .toList();
        }
      }
    } else {
      b.kind = UnlinkedExecutableKind.functionOrMethod;
    }
    b.isAbstract = executableElement.isAbstract;
    b.isAsynchronous = executableElement.isAsynchronous;
    b.isGenerator = executableElement.isGenerator;
    b.isStatic = executableElement.isStatic &&
        executableElement.enclosingElement is ClassElement;
    b.isExternal = executableElement.isExternal;
    b.documentationComment = serializeDocumentation(executableElement);
    b.annotations = serializeAnnotations(executableElement);
    b.codeRange = serializeCodeRange(executableElement);
    if (executableElement is FunctionElement) {
      SourceRange visibleRange = executableElement.visibleRange;
      if (visibleRange != null) {
        b.visibleOffset = visibleRange.offset;
        b.visibleLength = visibleRange.length;
      }
    }
    b.localFunctions =
        executableElement.functions.map(serializeExecutable).toList();
    b.localLabels = executableElement.labels.map(serializeLabel).toList();
    b.localVariables =
        executableElement.localVariables.map(serializeVariable).toList();
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
    b.annotations = serializeAnnotations(exportElement);
    return b;
  }

  /**
   * Serialize the given [exportElement] into an [UnlinkedExportPublic].
   */
  UnlinkedExportPublicBuilder serializeExportPublic(
      ExportElement exportElement) {
    UnlinkedExportPublicBuilder b = new UnlinkedExportPublicBuilder();
    b.uri = exportElement.uri;
    b.combinators = exportElement.combinators.map(serializeCombinator).toList();
    return b;
  }

  /**
   * Serialize the given [importElement] yielding an [UnlinkedImportBuilder].
   * Also, add linked information about it to the [linkedImports] list.
   */
  UnlinkedImportBuilder serializeImport(ImportElement importElement) {
    UnlinkedImportBuilder b = new UnlinkedImportBuilder();
    b.annotations = serializeAnnotations(importElement);
    b.isDeferred = importElement.isDeferred;
    b.combinators = importElement.combinators.map(serializeCombinator).toList();
    if (importElement.prefix != null) {
      b.prefixReference = serializePrefix(importElement.prefix);
      b.prefixOffset = importElement.prefix.nameOffset;
    }
    if (importElement.isSynthetic) {
      b.isImplicit = true;
    } else {
      b.offset = importElement.nameOffset;
      b.uri = importElement.uri;
      b.uriOffset = importElement.uriOffset;
      b.uriEnd = importElement.uriEnd;
    }
    return b;
  }

  /**
   * Serialize the given [label], creating an [UnlinkedLabelBuilder].
   */
  UnlinkedLabelBuilder serializeLabel(LabelElement label) {
    LabelElementImpl labelImpl = label as LabelElementImpl;
    UnlinkedLabelBuilder b = new UnlinkedLabelBuilder();
    b.name = labelImpl.name;
    b.nameOffset = labelImpl.nameOffset;
    b.isOnSwitchMember = labelImpl.isOnSwitchMember;
    b.isOnSwitchStatement = labelImpl.isOnSwitchStatement;
    return b;
  }

  /**
   * Serialize the given [parameter] into an [UnlinkedParam].
   */
  UnlinkedParamBuilder serializeParam(ParameterElement parameter,
      [Element context]) {
    context ??= parameter;
    UnlinkedParamBuilder b = new UnlinkedParamBuilder();
    b.name = parameter.name;
    b.nameOffset = parameter.nameOffset >= 0 ? parameter.nameOffset : 0;
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
    b.annotations = serializeAnnotations(parameter);
    b.codeRange = serializeCodeRange(parameter);
    b.isInitializingFormal = parameter.isInitializingFormal;
    DartType type = parameter.type;
    if (parameter.hasImplicitType) {
      Element contextParent = context.enclosingElement;
      if (!parameter.isInitializingFormal &&
          contextParent is ExecutableElement &&
          !contextParent.isStatic &&
          contextParent is! ConstructorElement) {
        b.inferredTypeSlot = storeInferredType(type, context);
      }
    } else {
      if (type is FunctionType && type.element.isSynthetic) {
        b.isFunctionTyped = true;
        b.type = serializeTypeRef(type.returnType, parameter);
        b.parameters = type.parameters
            .map((parameter) => serializeParam(parameter, context))
            .toList();
      } else {
        b.type = serializeTypeRef(type, context);
      }
    }
    // TODO(scheglov) VariableMember.initializer is not implemented
    if (parameter is! VariableMember && parameter.initializer != null) {
      b.initializer = serializeExecutable(parameter.initializer);
    }
    if (parameter is ConstVariableElement) {
      ConstVariableElement constParameter = parameter as ConstVariableElement;
      Expression initializer = constParameter.constantInitializer;
      if (initializer != null) {
        b.initializer?.bodyExpr = serializeConstExpr(
            parameter,
            parameter.getAncestor((Element e) => e is ExecutableElement),
            initializer);
        b.defaultValueCode = parameter.defaultValueCode;
      }
    }
    {
      SourceRange visibleRange = parameter.visibleRange;
      if (visibleRange != null) {
        b.visibleOffset = visibleRange.offset;
        b.visibleLength = visibleRange.length;
      }
    }
    return b;
  }

  /**
   * Serialize the given [prefix] into an index into the references table.
   */
  int serializePrefix(PrefixElement element) {
    return referenceMap.putIfAbsent(element,
        () => serializeUnlinkedReference(element.name, ReferenceKind.prefix));
  }

  /**
   * Compute the reference index which should be stored in a [EntityRef].
   */
  int serializeReferenceForType(DartType type) {
    Element element = type.element;
    LibraryElement dependentLibrary = element?.library;
    if (dependentLibrary == null) {
      if (type.isBottom) {
        // References to the "bottom" type are always implicit, since there is
        // no way to explicitly refer to the "bottom" type.  Therefore they
        // should always be linked.
        assert(buildingLinkedReferences);
        return serializeBottomReference();
      }
      assert(type.isDynamic || type.isVoid);
      if (type is UndefinedTypeImpl) {
        return serializeUnresolvedReference();
      }
      // Note: for a type which is truly `dynamic` or `void`, fall through to
      // use [_getElementReferenceId].
    }
    return _getElementReferenceId(element);
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
    b.returnType = serializeTypeRef(typedefElement.returnType, typedefElement);
    b.parameters = typedefElement.parameters.map(serializeParam).toList();
    b.documentationComment = serializeDocumentation(typedefElement);
    b.annotations = serializeAnnotations(typedefElement);
    b.codeRange = serializeCodeRange(typedefElement);
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
    b.annotations = serializeAnnotations(typeParameter);
    b.codeRange = serializeCodeRange(typeParameter);
    return b;
  }

  /**
   * Serialize the given [type] into a [EntityRef].  If [slot] is provided,
   * it should be included in the [EntityRef].
   *
   * [context] is the element within which the [EntityRef] will be
   * interpreted; this is used to serialize type parameters.
   */
  EntityRefBuilder serializeTypeRef(DartType type, Element context,
      {int slot}) {
    if (slot != null) {
      assert(buildingLinkedReferences);
    }
    EntityRefBuilder b = new EntityRefBuilder(slot: slot);
    Element typeElement = type.element;
    if (type is TypeParameterType) {
      int typeParameterIndex = findTypeParameterIndex(type, context);
      if (typeParameterIndex != null) {
        b.paramReference = typeParameterIndex;
      } else {
        // Out-of-scope type parameters only occur in circumstances where they
        // are irrelevant (i.e. when a type parameter is unused).  So we can
        // safely convert them to `dynamic`.
        b.reference = serializeReferenceForType(DynamicTypeImpl.instance);
      }
    } else if (type is FunctionType &&
        typeElement is FunctionElement &&
        typeElement.enclosingElement == null) {
      b.syntheticReturnType =
          serializeTypeRef(typeElement.returnType, typeElement);
      b.syntheticParams = typeElement.parameters
          .map((ParameterElement param) => serializeParam(param, context))
          .toList();
    } else {
      if (type is FunctionType &&
          typeElement.enclosingElement is ParameterElement) {
        // Code cannot refer to function types implicitly defined by parameters
        // directly, so if we get here, we must be serializing a linked
        // reference from type inference.
        assert(buildingLinkedReferences);
        ParameterElement parameterElement = typeElement.enclosingElement;
        while (true) {
          Element parent = parameterElement.enclosingElement;
          if (parent is ParameterElement) {
            // Function-typed parameter inside a function-typed parameter.
            b.implicitFunctionTypeIndices
                .insert(0, parent.parameters.indexOf(parameterElement));
            parameterElement = parent;
            continue;
          } else if (parent is FunctionTypedElement) {
            b.implicitFunctionTypeIndices
                .insert(0, parent.parameters.indexOf(parameterElement));
            // Function-typed parameter inside a top level function, method, or
            // typedef.
            b.reference = _getElementReferenceId(parent);
            break;
          } else {
            throw new StateError(
                'Unexpected element enclosing parameter: ${parent.runtimeType}');
          }
        }
      } else {
        b.reference = serializeReferenceForType(type);
      }
      List<DartType> typeArguments = getTypeArguments(type);
      if (typeArguments != null) {
        b.typeArguments = typeArguments
            .map((typeArgument) => serializeTypeRef(typeArgument, context))
            .toList();
      }
    }
    return b;
  }

  /**
   * Create a new entry in the references table ([UnlinkedUnit.references]
   * and [LinkedUnit.references]) representing an entity having the given
   * [name] and [kind].  If [unit] is given, it is the index of the compilation
   * unit containing the entity being referred to.  If [prefixReference] is
   * given, it indicates the entry in the references table for the prefix.
   */
  int serializeUnlinkedReference(String name, ReferenceKind kind,
      {int unit: 0, int prefixReference: 0}) {
    assert(unlinkedReferences.length == linkedReferences.length);
    int index = unlinkedReferences.length;
    unlinkedReferences.add(new UnlinkedReferenceBuilder(
        name: name, prefixReference: prefixReference));
    linkedReferences.add(new LinkedReferenceBuilder(kind: kind, unit: unit));
    return index;
  }

  /**
   * Return the index of the entry in the references table
   * ([UnlinkedLibrary.references] and [LinkedLibrary.references]) used for
   * unresolved references.  A new entry is added to the table if necessary to
   * satisfy the request.
   */
  int serializeUnresolvedReference() {
    // TODO(paulberry): in order for relinking to work, we need to record the
    // name and prefix of the unresolved symbol.  This is not (yet) encoded in
    // the element model.  For the moment we use a name that can't possibly
    // ever exist.
    if (unresolvedReferenceIndex == null) {
      unresolvedReferenceIndex =
          serializeUnlinkedReference('*unresolved*', ReferenceKind.unresolved);
    }
    return unresolvedReferenceIndex;
  }

  /**
   * Serialize the given [variable], creating an [UnlinkedVariable].
   */
  UnlinkedVariableBuilder serializeVariable(VariableElement variable) {
    UnlinkedVariableBuilder b = new UnlinkedVariableBuilder();
    b.name = variable.name;
    b.nameOffset = variable.nameOffset;
    if (!variable.hasImplicitType) {
      b.type = serializeTypeRef(variable.type, variable);
    }
    b.isStatic = variable.isStatic && variable.enclosingElement is ClassElement;
    b.isFinal = variable.isFinal;
    b.isConst = variable.isConst;
    b.documentationComment = serializeDocumentation(variable);
    b.annotations = serializeAnnotations(variable);
    // TODO(scheglov) VariableMember.initializer is not implemented
    if (variable is! VariableMember && variable.initializer != null) {
      b.initializer = serializeExecutable(variable.initializer);
    }
    if (variable is ConstVariableElement) {
      ConstVariableElement constVariable = variable as ConstVariableElement;
      Expression initializer = constVariable.constantInitializer;
      if (initializer != null) {
        b.initializer?.bodyExpr =
            serializeConstExpr(variable, variable.initializer, initializer);
      }
    }
    if (variable is PropertyInducingElement) {
      if (b.isFinal || b.isConst) {
        b.propagatedTypeSlot =
            storeLinkedType(variable.propagatedType, variable);
      } else {
        // Variable is not propagable.
        assert(variable.propagatedType == null);
      }
    }
    if (variable.hasImplicitType &&
        (variable.initializer != null || !variable.isStatic)) {
      b.inferredTypeSlot = storeInferredType(variable.type, variable);
    }
    b.codeRange = serializeCodeRange(variable);
    if (variable is LocalVariableElement) {
      SourceRange visibleRange = variable.visibleRange;
      if (visibleRange != null) {
        b.visibleOffset = visibleRange.offset;
        b.visibleLength = visibleRange.length;
      }
    }
    return b;
  }

  /**
   * Create a new slot id and return it.  If [hasCycle] is `true`, arrange for
   * the slot id to be included in [LinkedUnit.constCycles].
   */
  int storeConstCycle(bool hasCycle) {
    int slot = ++numSlots;
    if (hasCycle) {
      constCycles.add(slot);
    }
    return slot;
  }

  /**
   * Create a slot id for the given [type] (which is an inferred type).  If
   * [type] is not `dynamic`, it is stored in [linkedTypes] so that once the
   * compilation unit has been fully visited, it will be serialized into
   * [LinkedUnit.types].
   *
   * [context] is the element within which the slot id will appear; this is
   * used to serialize type parameters.
   */
  int storeInferredType(DartType type, Element context) {
    return storeLinkedType(type.isDynamic ? null : type, context);
  }

  /**
   * Create a slot id for the given [type] (which may be either a propagated
   * type or an inferred type).  If [type] is not `null`, it is stored in
   * [linkedTypes] so that once the compilation unit has been fully visited,
   * it will be serialized to [LinkedUnit.types].
   *
   * [context] is the element within which the slot id will appear; this is
   * used to serialize type parameters.
   */
  int storeLinkedType(DartType type, Element context) {
    int slot = ++numSlots;
    if (type != null) {
      deferredLinkedTypes
          .add(() => serializeTypeRef(type, context, slot: slot));
    }
    return slot;
  }

  int _getElementReferenceId(Element element) {
    return referenceMap.putIfAbsent(element, () {
      LibraryElement dependentLibrary = librarySerializer.libraryElement;
      int unit = 0;
      Element enclosingElement;
      if (element != null) {
        enclosingElement = element.enclosingElement;
        if (enclosingElement is CompilationUnitElement) {
          dependentLibrary = enclosingElement.library;
          unit = dependentLibrary.units.indexOf(enclosingElement);
          assert(unit != -1);
        }
      }
      ReferenceKind kind = _getReferenceKind(element);
      String name = element == null ? 'void' : element.name;
      int index;
      LinkedReferenceBuilder linkedReference;
      if (buildingLinkedReferences) {
        linkedReference =
            new LinkedReferenceBuilder(kind: kind, unit: unit, name: name);
        if (enclosingElement != null &&
            enclosingElement is! CompilationUnitElement) {
          linkedReference.containingReference =
              _getElementReferenceId(enclosingElement);
          if (enclosingElement is ClassElement) {
            // Nothing to do.
          } else if (enclosingElement is ExecutableElement) {
            if (element is FunctionElement) {
              assert(enclosingElement.functions.contains(element));
              linkedReference.localIndex =
                  enclosingElement.functions.indexOf(element);
            } else if (element is LocalVariableElement) {
              assert(enclosingElement.localVariables.contains(element));
              linkedReference.localIndex =
                  enclosingElement.localVariables.indexOf(element);
            } else {
              throw new StateError(
                  'Unexpected enclosed element type: ${element.runtimeType}');
            }
          } else if (enclosingElement is VariableElement) {
            assert(identical(enclosingElement.initializer, element));
          } else {
            throw new StateError(
                'Unexpected enclosing element type: ${enclosingElement.runtimeType}');
          }
        }
        index = linkedReferences.length;
        linkedReferences.add(linkedReference);
      } else {
        assert(unlinkedReferences.length == linkedReferences.length);
        int prefixReference = 0;
        Element enclosing = element?.enclosingElement;
        if (enclosing == null || enclosing is CompilationUnitElement) {
          // Figure out a prefix that may be used to refer to the given element.
          // TODO(paulberry): to avoid subtle relinking inconsistencies we
          // should use the actual prefix from the AST (a given type may be
          // reachable via multiple prefixes), but sadly, this information is
          // not recorded in the element model.
          PrefixElement prefix = librarySerializer.prefixMap[element];
          if (prefix != null) {
            prefixReference = serializePrefix(prefix);
          }
        } else {
          prefixReference = _getElementReferenceId(enclosing);
        }
        index = serializeUnlinkedReference(name, kind,
            prefixReference: prefixReference, unit: unit);
        linkedReference = linkedReferences[index];
      }
      linkedReference.dependency =
          librarySerializer.serializeDependency(dependentLibrary);
      if (element is TypeParameterizedElement) {
        linkedReference.numTypeParameters += element.typeParameters.length;
      }
      return index;
    });
  }
}

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single constant [Expression].
 */
class _ConstExprSerializer extends AbstractConstExprSerializer {
  final _CompilationUnitSerializer serializer;
  final Element context;
  final ExecutableElement executableContext;

  /**
   * If a constructor initializer expression is being serialized, the names of
   * the constructor parameters.  Otherwise `null`.
   */
  final Set<String> constructorParameterNames;

  _ConstExprSerializer(this.serializer, this.context, this.executableContext,
      this.constructorParameterNames);

  @override
  bool isParameterName(String name) {
    return constructorParameterNames?.contains(name) ?? false;
  }

  @override
  void serializeAnnotation(Annotation annotation) {
    if (annotation.arguments == null) {
      assert(annotation.constructorName == null);
      serialize(annotation.name);
    } else {
      Identifier name = annotation.name;
      Element nameElement = name.staticElement;
      EntityRefBuilder constructor;
      if (nameElement is ConstructorElement && name is PrefixedIdentifier) {
        assert(annotation.constructorName == null);
        constructor = serializeConstructorRef(
            nameElement.returnType, name.prefix, null, name.identifier);
      } else if (nameElement is TypeDefiningElement) {
        constructor = serializeConstructorRef(nameElement.type, annotation.name,
            null, annotation.constructorName);
      } else if (nameElement == null) {
        // Unresolved annotation.
        if (name is PrefixedIdentifier && annotation.constructorName == null) {
          constructor =
              serializeConstructorRef(null, name.prefix, null, name.identifier);
        } else {
          constructor = serializeConstructorRef(
              null, annotation.name, null, annotation.constructorName);
        }
      } else {
        throw new StateError('Unexpected annotation nameElement type:'
            ' ${nameElement.runtimeType}');
      }
      serializeInstanceCreation(constructor, annotation.arguments);
    }
  }

  @override
  EntityRefBuilder serializeConstructorRef(DartType type, Identifier typeName,
      TypeArgumentList typeArguments, SimpleIdentifier name) {
    EntityRefBuilder typeRef = serializeType(type, typeName, typeArguments);
    if (name == null) {
      return typeRef;
    } else {
      LinkedReference typeLinkedRef =
          serializer.linkedReferences[typeRef.reference];
      int refId = serializer.serializeUnlinkedReference(
          name.name,
          name.staticElement != null
              ? ReferenceKind.constructor
              : ReferenceKind.unresolved,
          prefixReference: typeRef.reference,
          unit: typeLinkedRef.unit);
      return new EntityRefBuilder(
          reference: refId, typeArguments: typeRef.typeArguments);
    }
  }

  @override
  List<int> serializeFunctionExpression(FunctionExpression functionExpression) {
    if (executableContext == null) {
      return null;
    }
    ExecutableElement functionElement = functionExpression.element;
    // TOOD(paulberry): handle the situation where [functionExpression] is not
    // an immediate child of [executableContext].
    assert(functionElement.enclosingElement == executableContext);
    int popCount = 0;
    int localIndex = executableContext.functions.indexOf(functionElement);
    assert(localIndex != -1);
    return <int>[popCount, localIndex];
  }

  EntityRefBuilder serializeIdentifier(Identifier identifier,
      {int prefixReference: 0}) {
    if (identifier is SimpleIdentifier) {
      Element element = identifier.staticElement;
      if (element is TypeParameterElement) {
        int typeParameterIndex =
            serializer.findTypeParameterIndex(element.type, context);
        return new EntityRefBuilder(paramReference: typeParameterIndex);
      } else if (_isPrelinkResolvableElement(element)) {
        int ref = serializer._getElementReferenceId(element);
        return new EntityRefBuilder(reference: ref);
      } else {
        int ref = serializer.serializeUnlinkedReference(
            identifier.name, ReferenceKind.unresolved);
        return new EntityRefBuilder(reference: ref);
      }
    } else if (identifier is PrefixedIdentifier) {
      Element element = identifier.staticElement;
      if (_isPrelinkResolvableElement(element)) {
        int ref = serializer._getElementReferenceId(element);
        return new EntityRefBuilder(reference: ref);
      } else {
        int prefixRef = serializeIdentifier(identifier.prefix).reference;
        int ref = serializer.serializeUnlinkedReference(
            identifier.identifier.name, ReferenceKind.unresolved,
            prefixReference: prefixRef);
        return new EntityRefBuilder(reference: ref);
      }
    } else {
      throw new StateError(
          'Unexpected identifier type: ${identifier.runtimeType}');
    }
  }

  @override
  EntityRefBuilder serializeIdentifierSequence(Expression expr) {
    if (expr is Identifier) {
      return serializeIdentifier(expr);
    }
    if (expr is PropertyAccess) {
      Element element = expr.propertyName.staticElement;
      if (_isPrelinkResolvableElement(element)) {
        int ref = serializer._getElementReferenceId(element);
        return new EntityRefBuilder(reference: ref);
      } else {
        int targetRef = serializeIdentifierSequence(expr.target).reference;
        int ref = serializer.serializeUnlinkedReference(
            expr.propertyName.name, ReferenceKind.unresolved,
            prefixReference: targetRef);
        return new EntityRefBuilder(reference: ref);
      }
    } else {
      throw new StateError('Unexpected node type: ${expr.runtimeType}');
    }
  }

  @override
  EntityRefBuilder serializeType(
      DartType type, Identifier name, TypeArgumentList arguments) {
    if (name != null) {
      if (type == null || type.isUndefined) {
        return serializeIdentifier(name);
      }
    }
    DartType typeOrDynamic = type ?? DynamicTypeImpl.instance;
    return serializer.serializeTypeRef(typeOrDynamic, context);
  }

  /**
   * Return `true` if the given [element] can be resolved at prelink step.
   */
  static bool _isPrelinkResolvableElement(Element element) {
    if (element == null) {
      return false;
    }
    if (element == DynamicTypeImpl.instance.element) {
      return true;
    }
    if (element is PrefixElement) {
      return true;
    }
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is CompilationUnitElement) {
      return true;
    }
    if (enclosingElement is ClassElement) {
      return element is ConstructorElement ||
          element is ClassMemberElement && element.isStatic ||
          element is PropertyAccessorElement && element.isStatic;
    }
    return false;
  }
}

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single library.
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
   * Indicates whether the element model being serialized was analyzed using
   * strong mode.
   */
  final bool strongMode;

  /**
   * Map from [LibraryElement] to the index of the entry in the "dependency
   * table" that refers to it.
   */
  final Map<LibraryElement, int> dependencyMap = <LibraryElement, int>{};

  /**
   * The "dependency table".  This is the list of objects which should be
   * written to [LinkedLibrary.dependencies].
   */
  final List<LinkedDependencyBuilder> dependencies =
      <LinkedDependencyBuilder>[];

  /**
   * The linked portion of the "imports table".  This is the list of ints
   * which should be written to [LinkedLibrary.imports].
   */
  final List<int> linkedImports = <int>[];

  /**
   * The linked portion of the "exports table".  This is the list of ints
   * which should be written to [LinkedLibrary.exports].
   */
  final List<int> linkedExports = <int>[];

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

  /**
   * List of serializers for the compilation units constituting this library.
   */
  final List<_CompilationUnitSerializer> compilationUnitSerializers =
      <_CompilationUnitSerializer>[];

  _LibrarySerializer(this.libraryElement, this.typeProvider, this.strongMode) {
    dependencies.add(new LinkedDependencyBuilder());
    dependencyMap[libraryElement] = 0;
  }

  /**
   * Retrieve a list of the Sources for the compilation units in the library.
   */
  List<Source> get unitSources => compilationUnitSerializers
      .map((_CompilationUnitSerializer s) => s.unitSource)
      .toList();

  /**
   * Retrieve a list of the URIs for the compilation units in the library.
   */
  List<String> get unitUris => compilationUnitSerializers
      .map((_CompilationUnitSerializer s) => s.unitUri)
      .toList();

  /**
   * Retrieve a list of the [UnlinkedUnitBuilder]s for the compilation units in
   * the library.
   */
  List<UnlinkedUnitBuilder> get unlinkedUnits => compilationUnitSerializers
      .map((_CompilationUnitSerializer s) => s.unlinkedUnit)
      .toList();

  /**
   * Add [exportedLibrary] (and the transitive closure of all libraries it
   * exports) to the dependency table ([LinkedLibrary.dependencies]).
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
   * Return the index of the entry in the dependency table
   * ([LinkedLibrary.dependencies]) for the given [dependentLibrary].  A new
   * entry is added to the table if necessary to satisfy the request.
   */
  int serializeDependency(LibraryElement dependentLibrary) {
    return dependencyMap.putIfAbsent(dependentLibrary, () {
      int index = dependencies.length;
      List<String> parts = dependentLibrary.parts
          .map((CompilationUnitElement e) => e.source.uri.toString())
          .toList();
      dependencies.add(new LinkedDependencyBuilder(
          uri: dependentLibrary.source.uri.toString(), parts: parts));
      return index;
    });
  }

  /**
   * Serialize the whole library element into a [LinkedLibrary].  Should be
   * called exactly once for each instance of [_LibrarySerializer].
   *
   * The unlinked compilation units are stored in [unlinkedUnits], and their
   * absolute URIs are stored in [unitUris].
   */
  LinkedLibraryBuilder serializeLibrary() {
    computePrefixMap();
    LinkedLibraryBuilder pb = new LinkedLibraryBuilder();
    for (ExportElement exportElement in libraryElement.exports) {
      addTransitiveExportClosure(exportElement.exportedLibrary);
      linkedExports.add(serializeDependency(exportElement.exportedLibrary));
    }
    for (ImportElement importElement in libraryElement.imports) {
      addTransitiveExportClosure(importElement.importedLibrary);
      linkedImports.add(serializeDependency(importElement.importedLibrary));
    }
    compilationUnitSerializers.add(new _CompilationUnitSerializer(
        this, libraryElement.definingCompilationUnit, 0));
    for (int i = 0; i < libraryElement.parts.length; i++) {
      compilationUnitSerializers.add(
          new _CompilationUnitSerializer(this, libraryElement.parts[i], i + 1));
    }
    for (_CompilationUnitSerializer compilationUnitSerializer
        in compilationUnitSerializers) {
      compilationUnitSerializer.addCompilationUnitElements();
    }
    pb.units = compilationUnitSerializers
        .map((_CompilationUnitSerializer s) => s.linkedUnit)
        .toList();
    pb.dependencies = dependencies;
    pb.numPrelinkedDependencies = dependencies.length;
    for (_CompilationUnitSerializer compilationUnitSerializer
        in compilationUnitSerializers) {
      compilationUnitSerializer.createLinkedInfo();
    }
    pb.importDependencies = linkedImports;
    pb.exportDependencies = linkedExports;
    List<String> exportedNames =
        libraryElement.exportNamespace.definedNames.keys.toList();
    exportedNames.sort();
    List<LinkedExportNameBuilder> exportNames = <LinkedExportNameBuilder>[];
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
      ReferenceKind kind = _getReferenceKind(element);
      exportNames.add(new LinkedExportNameBuilder(
          name: name,
          dependency: serializeDependency(dependentLibrary),
          unit: unit,
          kind: kind));
    }
    pb.exportNames = exportNames;
    return pb;
  }
}
