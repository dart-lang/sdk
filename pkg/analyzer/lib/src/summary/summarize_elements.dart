// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.elements;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/name_filter.dart';
import 'package:analyzer/src/summary/summarize_const_expr.dart';

/**
 * Serialize all the elements in [lib] to a summary using [ctx] as the context
 * for building the summary, and using [typeProvider] to find built-in types.
 */
LibrarySerializationResult serializeLibrary(
    LibraryElement lib, TypeProvider typeProvider) {
  var serializer = new _LibrarySerializer(lib, typeProvider);
  LinkedLibraryBuilder linked = serializer.serializeLibrary();
  return new LibrarySerializationResult(
      linked, serializer.unlinkedUnits, serializer.unitUris);
}

ReferenceKind _getReferenceKind(Element element) {
  ReferenceKind kind;
  if (element is PropertyAccessorElement) {
    kind = ReferenceKind.topLevelPropertyAccessor;
  } else if (element is FunctionTypeAliasElement) {
    kind = ReferenceKind.typedef;
  } else if (element is ClassElement || element is DynamicElementImpl) {
    kind = ReferenceKind.classOrEnum;
  } else if (element is FunctionElement) {
    kind = ReferenceKind.topLevelFunction;
  } else {
    throw new Exception('Unexpected element kind: ${element.runtimeType}');
  }
  return kind;
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

  LibrarySerializationResult(this.linked, this.unlinkedUnits, this.unitUris);
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
   * Index into the "references table" representing an unresolved reference, if
   * such an index exists.  `null` if no such entry has been made in the
   * references table yet.
   */
  int unresolvedReferenceIndex = null;

  _CompilationUnitSerializer(
      this.librarySerializer, this.compilationUnit, this.unitNum);

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
      new LinkedReferenceBuilder(kind: ReferenceKind.classOrEnum)
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
            numTypeParameters: cls.typeParameters.length));
      }
    }
    for (ClassElement enm in compilationUnit.enums) {
      if (enm.isPublic) {
        names.add(new UnlinkedPublicNameBuilder(
            kind: ReferenceKind.classOrEnum, name: enm.name));
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
          .map((CompilationUnitElement e) =>
              new UnlinkedPartBuilder(uriOffset: e.uriOffset, uriEnd: e.uriEnd))
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
    linkedUnit.references = linkedReferences;
    unitUri = compilationUnit.source.uri.toString();
  }

  /**
   * Create the [LinkedUnit.types] table based on deferred types that were
   * found during [addCompilationUnitElements].
   */
  void createLinkedTypes() {
    linkedUnit.types = deferredLinkedTypes
        .map((_SerializeTypeRef closure) => closure())
        .toList();
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
   * Serialize the given [expression], creating an [UnlinkedConstBuilder].
   */
  UnlinkedConstBuilder serializeConstExpr(Expression expression) {
    _ConstExprSerializer serializer = new _ConstExprSerializer(this);
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
    if (executableElement is! ConstructorElement) {
      if (executableElement.hasImplicitReturnType) {
        // In strong mode, the variable's static type may have been overwritten
        // by an inferred type.  In this part of the summary we want to store
        // the weak mode static type (which is `dynamic`), since the strong
        // mode static type is fully linked information.
        b.returnType = serializeTypeRef(
            librarySerializer.typeProvider.dynamicType, executableElement);
      } else if (!executableElement.type.returnType.isVoid) {
        b.returnType = serializeTypeRef(
            executableElement.type.returnType, executableElement);
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
    if (parameter.isInitializingFormal && parameter.hasImplicitType) {
      b.hasImplicitType = true;
      // We don't store the type of initializing formals that have an implicit
      // type, because the type is inherited from the field.
    } else {
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
    }
    return b;
  }

  /**
   * Serialize the given [prefix] into an index into the references table.
   */
  int serializePrefix(PrefixElement element) {
    return referenceMap.putIfAbsent(element, () {
      assert(unlinkedReferences.length == linkedReferences.length);
      int index = unlinkedReferences.length;
      unlinkedReferences.add(new UnlinkedReferenceBuilder(name: element.name));
      linkedReferences
          .add(new LinkedReferenceBuilder(kind: ReferenceKind.prefix));
      return index;
    });
  }

  /**
   * Compute the reference index which should be stored in a [EntityRef].
   *
   * If [linked] is true, and a new reference has to be created, the reference
   * will only be stored in [linkedReferences].
   */
  int serializeReferenceForType(DartType type, bool linked) {
    Element element = type.element;
    LibraryElement dependentLibrary = element.library;
    if (dependentLibrary == null) {
      assert(type.isDynamic);
      if (type is UndefinedTypeImpl) {
        return serializeUnresolvedReference();
      }
      // Note: for a type which is truly `dynamic`, fall through to use
      // [_getElementReferenceId].
    }
    return _getElementReferenceId(element, linked: linked);
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
   * Serialize the given [type] into a [EntityRef].  If [slot] is provided,
   * it should be included in the [EntityRef].  If [linked] is true, any
   * references that are created will be populated into [linkedReferences] but
   * [not [unlinkedReferences].
   *
   * [context] is the element within which the [EntityRef] will be
   * interpreted; this is used to serialize type parameters.
   */
  EntityRefBuilder serializeTypeRef(DartType type, Element context,
      {bool linked: false, int slot}) {
    EntityRefBuilder b = new EntityRefBuilder(slot: slot);
    if (type is TypeParameterType) {
      b.paramReference = findTypeParameterIndex(type, context);
    } else {
      b.reference = serializeReferenceForType(type, linked);
      List<DartType> typeArguments = getTypeArguments(type);
      if (typeArguments != null) {
        // Trailing type arguments of type 'dynamic' should be omitted.
        int numArgsToSerialize = typeArguments.length;
        while (numArgsToSerialize > 0 &&
            typeArguments[numArgsToSerialize - 1].isDynamic) {
          --numArgsToSerialize;
        }
        if (numArgsToSerialize > 0) {
          List<EntityRefBuilder> serializedArguments = <EntityRefBuilder>[];
          for (int i = 0; i < numArgsToSerialize; i++) {
            serializedArguments.add(
                serializeTypeRef(typeArguments[i], context, linked: linked));
          }
          b.typeArguments = serializedArguments;
        }
      }
    }
    return b;
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
      assert(unlinkedReferences.length == linkedReferences.length);
      unresolvedReferenceIndex = unlinkedReferences.length;
      unlinkedReferences
          .add(new UnlinkedReferenceBuilder(name: '*unresolved*'));
      linkedReferences
          .add(new LinkedReferenceBuilder(kind: ReferenceKind.unresolved));
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
    if (variable.hasImplicitType) {
      // In strong mode, the variable's static type may have been overwritten
      // by an inferred type.  In this part of the summary we want to store the
      // weak mode static type (which is `dynamic`), since the strong mode
      // static type is fully linked information.
      b.type = serializeTypeRef(
          librarySerializer.typeProvider.dynamicType, variable);
    } else {
      b.type = serializeTypeRef(variable.type, variable);
    }
    b.isStatic = variable.isStatic && variable.enclosingElement is ClassElement;
    b.isFinal = variable.isFinal;
    b.isConst = variable.isConst;
    b.hasImplicitType = variable.hasImplicitType;
    b.documentationComment = serializeDocumentation(variable);
    if (variable.isConst && variable is ConstVariableElement) {
      ConstVariableElement constVariable = variable as ConstVariableElement;
      Expression initializer = constVariable.constantInitializer;
      if (initializer != null) {
        b.constExpr = serializeConstExpr(initializer);
      }
    }
    if (b.isFinal || b.isConst) {
      b.propagatedTypeSlot = storeLinkedType(variable.propagatedType, variable);
    } else {
      // Variable is not propagable.
      assert(variable.propagatedType == null);
    }
    return b;
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
          .add(() => serializeTypeRef(type, context, linked: true, slot: slot));
    }
    return slot;
  }

  int _getElementReferenceId(Element element, {bool linked: false}) {
    return referenceMap.putIfAbsent(element, () {
      LibraryElement dependentLibrary = element.library;
      int unit;
      if (element.library == null) {
        assert(element == librarySerializer.typeProvider.dynamicType.element);
        unit = 0;
        dependentLibrary = librarySerializer.libraryElement;
      } else {
        CompilationUnitElement unitElement =
        element.getAncestor((Element e) => e is CompilationUnitElement);
        unit = dependentLibrary.units.indexOf(unitElement);
        assert(unit != -1);
      }
      int numTypeParameters = 0;
      if (element is TypeParameterizedElement) {
        numTypeParameters = element.typeParameters.length;
      }
      LinkedReferenceBuilder linkedReference = new LinkedReferenceBuilder(
          dependency: librarySerializer.serializeDependency(dependentLibrary),
          kind: _getReferenceKind(element),
          unit: unit,
          numTypeParameters: numTypeParameters);
      if (linked) {
        linkedReference.name = element.name;
      } else {
        assert(unlinkedReferences.length == linkedReferences.length);
        // Figure out a prefix that may be used to refer to the given type.
        // TODO(paulberry): to avoid subtle relinking inconsistencies we
        // should use the actual prefix from the AST (a given type may be
        // reachable via multiple prefixes), but sadly, this information is
        // not recorded in the element model.
        int prefixReference = 0;
        PrefixElement prefix = librarySerializer.prefixMap[element];
        if (prefix != null) {
          prefixReference = serializePrefix(prefix);
        }
        unlinkedReferences.add(new UnlinkedReferenceBuilder(
            name: element.name, prefixReference: prefixReference));
      }
      int index = linkedReferences.length;
      linkedReferences.add(linkedReference);
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

  _ConstExprSerializer(this.serializer);

  EntityRefBuilder serializeIdentifier(Identifier identifier) {
    Element element = identifier.staticElement;
    assert(element != null);
    // TODO(scheglov) how to serialize element references?
    return new EntityRefBuilder(
        reference: serializer._getElementReferenceId(element));
  }

  @override
  EntityRefBuilder serializeType(TypeName typeName) {
    DartType type = typeName != null ? typeName.type : DynamicTypeImpl.instance;
    return serializer.serializeTypeRef(type, null);
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

  _LibrarySerializer(this.libraryElement, this.typeProvider) {
    dependencies.add(new LinkedDependencyBuilder());
    dependencyMap[libraryElement] = 0;
  }

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
      compilationUnitSerializer.createLinkedTypes();
    }
    pb.importDependencies = linkedImports;
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
