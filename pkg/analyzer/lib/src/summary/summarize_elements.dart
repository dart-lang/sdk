// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.elements;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/builder.dart';
import 'package:analyzer/src/summary/format.dart';

/**
 * Serialize all the elements in [lib] to a summary using [ctx] as the context
 * for building the summary, and using [typeProvider] to find built-in types.
 *
 * Return an object which may safely be passed to [BuilderContext.getBuffer] or
 * included in an aggregate summary.
 */
Object serializeLibrary(
    BuilderContext ctx, LibraryElement lib, TypeProvider typeProvider) {
  return new _LibrarySerializer(ctx, lib, typeProvider).serializeLibrary();
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
   * List of objects which should be written to [UnlinkedLibrary.classes].
   */
  final List<Object> classes = <Object>[];

  /**
   * List of objects which should be written to [UnlinkedLibrary.enums].
   */
  final List<Object> enums = <Object>[];

  /**
   * List of objects which should be written to [UnlinkedLibrary.executables].
   */
  final List<Object> executables = <Object>[];

  /**
   * List of objects which should be written to [UnlinkedLibrary.typedefs].
   */
  final List<Object> typedefs = <Object>[];

  /**
   * List of objects which should be written to [UnlinkedLibrary.units].
   */
  final List<Object> units = <Object>[];

  /**
   * List of objects which should be written to [UnlinkedLibrary.variables].
   */
  final List<Object> variables = <Object>[];

  /**
   * Map from [LibraryElement] to the index of the entry in the "dependency
   * table" that refers to it.
   */
  final Map<LibraryElement, int> dependencyMap = <LibraryElement, int>{};

  /**
   * The "dependency table".  This is the list of objects which should be
   * written to [PrelinkedLibrary.dependencies].
   */
  final List<Object> dependencies = <Object>[];

  /**
   * The unlinked portion of the "imports table".  This is the list of objects
   * which should be written to [UnlinkedLibrary.imports].
   */
  final List<Object> unlinkedImports = <Object>[];

  /**
   * The prelinked portion of the "imports table".  This is the list of ints
   * which should be written to [PrelinkedLibrary.imports].
   */
  final List<Object> prelinkedImports = <int>[];

  /**
   * Map from prefix [String] to the index of the entry in the "prefix" table
   * that refers to it.  The empty prefix is not included in this map.
   */
  final Map<String, int> prefixMap = <String, int>{};

  /**
   * The "prefix table".  This is the list of objects which should be written
   * to [UnlinkedLibrary.prefixes].
   */
  final List<Object> prefixes = <Object>[];

  /**
   * Map from [Element] to the index of the entry in the "references table"
   * that refers to it.
   */
  final Map<Element, int> referenceMap = <Element, int>{};

  /**
   * The unlinked portion of the "references table".  This is the list of
   * objects which should be written to [UnlinkedLibrary.references].
   */
  final List<Object> unlinkedReferences = <Object>[];

  /**
   * The prelinked portion of the "references table".  This is the list of
   * objects which should be written to [PrelinkedLibrary.references].
   */
  final List<Object> prelinkedReferences = <Object>[];

  //final Map<String, int> prefixIndices = <String, int>{};

  /**
   * Index into the "references table" representing `dynamic`, if such an index
   * exists.  `null` if no such entry has been made in the references table
   * yet.
   */
  int dynamicReferenceIndex = null;

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
   * [BuilderContext] used to serialize the output summary.
   */
  final BuilderContext ctx;

  _LibrarySerializer(this.ctx, this.libraryElement, this.typeProvider) {
    dependencies.add(encodePrelinkedDependency(ctx));
    dependencyMap[libraryElement] = 0;
    prefixes.add(encodeUnlinkedPrefix(ctx));
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
    UnlinkedUnitBuilder b = new UnlinkedUnitBuilder(ctx);
    if (element.uri != null) {
      b.uri = element.uri;
    }
    units.add(b.finish());
    for (ClassElement cls in element.types) {
      classes.add(serializeClass(cls, unitNum));
    }
    for (ClassElement e in element.enums) {
      enums.add(serializeEnum(e, unitNum));
    }
    for (FunctionTypeAliasElement type in element.functionTypeAliases) {
      typedefs.add(serializeTypedef(type, unitNum));
    }
    for (FunctionElement executable in element.functions) {
      executables.add(serializeExecutable(executable, unitNum));
    }
    for (PropertyAccessorElement accessor in element.accessors) {
      if (!accessor.isSynthetic) {
        executables.add(serializeExecutable(accessor, unitNum));
      } else if (accessor.isGetter) {
        PropertyInducingElement variable = accessor.variable;
        if (variable != null) {
          assert(!variable.isSynthetic);
          variables.add(serializeVariable(variable, unitNum));
        }
      }
    }
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
   * Compute the appropriate De Bruijn index to represent the given type
   * parameter [type].
   */
  int findTypeParameterIndex(TypeParameterType type) {
    int index = 0;
    Element enclosingElement = type.element.enclosingElement;
    while (enclosingElement != null) {
      List<TypeParameterElement> typeParameters;
      if (enclosingElement is ClassElement) {
        typeParameters = enclosingElement.typeParameters;
      } else if (enclosingElement is FunctionTypeAliasElement) {
        // TODO(paulberry): test this.
        typeParameters = enclosingElement.typeParameters;
      }
      for (int i = 0; i < typeParameters.length; i++) {
        TypeParameterElement param = typeParameters[i];
        if (param == type.element) {
          return index + typeParameters.length - i;
        }
      }
      index += typeParameters.length;
      enclosingElement = enclosingElement.enclosingElement;
    }
    throw new StateError('Unbound type parameter $type');
  }

  /**
   * Serialize the given [classElement], which exists in the unit numbered
   * [unitNum], creating an [UnlinkedClass].
   */
  Object serializeClass(ClassElement classElement, int unitNum) {
    UnlinkedClassBuilder b = new UnlinkedClassBuilder(ctx);
    b.name = classElement.name;
    b.unit = unitNum;
    b.typeParameters =
        classElement.typeParameters.map(serializeTypeParam).toList();
    if (classElement.supertype != null && !classElement.supertype.isObject) {
      b.supertype = serializeTypeRef(classElement.supertype);
    }
    b.mixins = classElement.mixins.map(serializeTypeRef).toList();
    b.interfaces = classElement.interfaces.map(serializeTypeRef).toList();
    List<Object> fields = <Object>[];
    List<Object> executables = <Object>[];
    for (ConstructorElement executable in classElement.constructors) {
      if (!executable.isSynthetic) {
        executables.add(serializeExecutable(executable, 0));
      }
    }
    for (MethodElement executable in classElement.methods) {
      executables.add(serializeExecutable(executable, 0));
    }
    for (PropertyAccessorElement accessor in classElement.accessors) {
      if (!accessor.isSynthetic) {
        executables.add(serializeExecutable(accessor, 0));
      } else if (accessor.isGetter) {
        PropertyInducingElement field = accessor.variable;
        if (field != null && !field.isSynthetic) {
          fields.add(serializeVariable(field, 0));
        }
      }
    }
    b.fields = fields;
    b.executables = executables;
    b.isAbstract = classElement.isAbstract;
    b.isMixinApplication = classElement.isMixinApplication;
    return b.finish();
  }

  /**
   * Serialize the given [combinator] into an [UnlinkedCombinator].
   */
  Object serializeCombinator(NamespaceCombinator combinator) {
    UnlinkedCombinatorBuilder b = new UnlinkedCombinatorBuilder(ctx);
    if (combinator is ShowElementCombinator) {
      b.shows = combinator.shownNames.map(serializeCombinatorName).toList();
    } else if (combinator is HideElementCombinator) {
      b.hides = combinator.hiddenNames.map(serializeCombinatorName).toList();
    }
    return b.finish();
  }

  /**
   * Serialize the given [name] into an [UnlinkedCombinatorName].
   */
  Object serializeCombinatorName(String name) {
    return encodeUnlinkedCombinatorName(ctx, name: name);
  }

  /**
   * Return the index of the entry in the dependency table
   * ([PrelinkedLibrary.dependencies]) for the given [dependentLibrary].  A new
   * entry is added to the table if necessary to satisfy the request.
   */
  int serializeDependency(LibraryElement dependentLibrary) {
    return dependencyMap.putIfAbsent(dependentLibrary, () {
      int index = dependencies.length;
      dependencies.add(encodePrelinkedDependency(ctx,
          uri: dependentLibrary.source.uri.toString()));
      return index;
    });
  }

  /**
   * Return the index of the entry in the references table
   * ([UnlinkedLibrary.references] and [PrelinkedLibrary.references])
   * representing the pseudo-type `dynamic`.  A new entry is added to the table
   * if necessary to satisfy the request.
   */
  int serializeDynamicReference() {
    if (dynamicReferenceIndex == null) {
      assert(unlinkedReferences.length == prelinkedReferences.length);
      dynamicReferenceIndex = unlinkedReferences.length;
      unlinkedReferences.add(encodeUnlinkedReference(ctx));
      prelinkedReferences.add(encodePrelinkedReference(ctx,
          kind: PrelinkedReferenceKind.classOrEnum));
    }
    return dynamicReferenceIndex;
  }

  /**
   * Serialize the given [enumElement], which exists in the unit numbered
   * [unitNum], creating an [UnlinkedEnum].
   */
  Object serializeEnum(ClassElement enumElement, int unitNum) {
    UnlinkedEnumBuilder b = new UnlinkedEnumBuilder(ctx);
    b.name = enumElement.name;
    List<Object> values = <Object>[];
    for (FieldElement field in enumElement.fields) {
      if (field.isConst && field.type.element == enumElement) {
        values.add(encodeUnlinkedEnumValue(ctx, name: field.name));
      }
    }
    b.values = values;
    b.unit = unitNum;
    return b.finish();
  }

  /**
   * Serialize the given [executableElement], which exists in the unit numbered
   * [unitNum], creating an [UnlinkedExecutable].  For elements declared inside
   * a class, [unitNum] should be zero.
   */
  Object serializeExecutable(ExecutableElement executableElement, int unitNum) {
    if (executableElement.enclosingElement is ClassElement) {
      assert(unitNum == 0);
    }
    UnlinkedExecutableBuilder b = new UnlinkedExecutableBuilder(ctx);
    b.name = executableElement.name;
    b.unit = unitNum;
    if (!executableElement.type.returnType.isVoid) {
      b.returnType = serializeTypeRef(executableElement.type.returnType);
    }
    // TODO(paulberry): serialize type parameters.
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
    return b.finish();
  }

  /**
   * Serialize the given [exportElement] into an [UnlinkedExport].
   */
  Object serializeExport(ExportElement exportElement) {
    UnlinkedExportBuilder b = new UnlinkedExportBuilder(ctx);
    b.uri = exportElement.uri;
    b.combinators = exportElement.combinators.map(serializeCombinator).toList();
    return b.finish();
  }

  /**
   * Serialize the given [importElement], adding information about it to
   * the [unlinkedImports] and [prelinkedImports] lists.
   */
  void serializeImport(ImportElement importElement) {
    assert(unlinkedImports.length == prelinkedImports.length);
    UnlinkedImportBuilder b = new UnlinkedImportBuilder(ctx);
    b.isDeferred = importElement.isDeferred;
    b.offset = importElement.nameOffset;
    b.combinators = importElement.combinators.map(serializeCombinator).toList();
    if (importElement.prefix != null) {
      b.prefix = prefixMap.putIfAbsent(importElement.prefix.name, () {
        int index = prefixes.length;
        prefixes
            .add(encodeUnlinkedPrefix(ctx, name: importElement.prefix.name));
        return index;
      });
    }
    if (importElement.isSynthetic) {
      b.isImplicit = true;
    } else {
      b.uri = importElement.uri;
    }
    addTransitiveExportClosure(importElement.importedLibrary);
    unlinkedImports.add(b.finish());
    prelinkedImports.add(serializeDependency(importElement.importedLibrary));
  }

  /**
   * Serialize the whole library element into a [PrelinkedLibrary].  Should be
   * called exactly once for each instance of [_LibrarySerializer].
   */
  Object serializeLibrary() {
    UnlinkedLibraryBuilder ub = new UnlinkedLibraryBuilder(ctx);
    PrelinkedLibraryBuilder pb = new PrelinkedLibraryBuilder(ctx);
    if (libraryElement.name.isNotEmpty) {
      ub.name = libraryElement.name;
    }
    for (ImportElement importElement in libraryElement.imports) {
      serializeImport(importElement);
    }
    ub.exports = libraryElement.exports.map(serializeExport).toList();
    addCompilationUnitElements(libraryElement.definingCompilationUnit, 0);
    for (int i = 0; i < libraryElement.parts.length; i++) {
      addCompilationUnitElements(libraryElement.parts[i], i + 1);
    }
    ub.classes = classes;
    ub.enums = enums;
    ub.executables = executables;
    ub.imports = unlinkedImports;
    ub.prefixes = prefixes;
    ub.references = unlinkedReferences;
    ub.typedefs = typedefs;
    ub.units = units;
    ub.variables = variables;
    pb.unlinked = ub.finish();
    pb.dependencies = dependencies;
    pb.importDependencies = prelinkedImports;
    pb.references = prelinkedReferences;
    return pb.finish();
  }

  /**
   * Serialize the given [parameter] into an [UnlinkedParam].
   */
  Object serializeParam(ParameterElement parameter) {
    UnlinkedParamBuilder b = new UnlinkedParamBuilder(ctx);
    b.name = parameter.name;
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
        b.type = serializeTypeRef(type.returnType);
      }
      b.parameters = type.parameters.map(serializeParam).toList();
    } else {
      b.type = serializeTypeRef(type);
    }
    return b.finish();
  }

  /**
   * Serialize the given [typedefElement], which exists in the unit numbered
   * [unitNum], creating an [UnlinkedTypedef].
   */
  Object serializeTypedef(
      FunctionTypeAliasElement typedefElement, int unitNum) {
    UnlinkedTypedefBuilder b = new UnlinkedTypedefBuilder(ctx);
    b.name = typedefElement.name;
    b.unit = unitNum;
    b.typeParameters =
        typedefElement.typeParameters.map(serializeTypeParam).toList();
    if (!typedefElement.returnType.isVoid) {
      b.returnType = serializeTypeRef(typedefElement.returnType);
    }
    b.parameters = typedefElement.parameters.map(serializeParam).toList();
    return b.finish();
  }

  /**
   * Serialize the given [typeParameter] into an [UnlinkedTypeParam].
   */
  Object serializeTypeParam(TypeParameterElement typeParameter) {
    UnlinkedTypeParamBuilder b = new UnlinkedTypeParamBuilder(ctx);
    b.name = typeParameter.name;
    if (typeParameter.bound != null) {
      b.bound = serializeTypeRef(typeParameter.bound);
    }
    return b.finish();
  }

  /**
   * Serialize the given [type] into an [UnlinkedTypeRef].
   */
  Object serializeTypeRef(DartType type) {
    UnlinkedTypeRefBuilder b = new UnlinkedTypeRefBuilder(ctx);
    if (type is TypeParameterType) {
      Element enclosingElement = type.element.enclosingElement;
      b.paramReference = findTypeParameterIndex(type);
    } else {
      Element element = type.element;
      CompilationUnitElement dependentCompilationUnit =
          element.getAncestor((Element e) => e is CompilationUnitElement);
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
          int index = unlinkedReferences.length;
          // TODO(paulberry): set UnlinkedReference.prefix.
          unlinkedReferences
              .add(encodeUnlinkedReference(ctx, name: element.name));
          prelinkedReferences.add(encodePrelinkedReference(ctx,
              dependency: serializeDependency(dependentLibrary),
              kind: element is FunctionTypeAliasElement
                  ? PrelinkedReferenceKind.typedef
                  : PrelinkedReferenceKind.classOrEnum));
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
        b.typeArguments = typeArguments.map(serializeTypeRef).toList();
      }
    }
    return b.finish();
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
    // the element model.
    if (unresolvedReferenceIndex == null) {
      assert(unlinkedReferences.length == prelinkedReferences.length);
      unresolvedReferenceIndex = unlinkedReferences.length;
      unlinkedReferences.add(encodeUnlinkedReference(ctx));
      prelinkedReferences.add(encodePrelinkedReference(ctx,
          kind: PrelinkedReferenceKind.unresolved));
    }
    return unresolvedReferenceIndex;
  }

  /**
   * Serialize the given [variable], which exists in the unit numbered
   * [unitNum], creating an [UnlinkedVariable].  For variables declared inside
   * a class (i.e. fields), [unitNum] should be zero.
   */
  Object serializeVariable(PropertyInducingElement variable, int unitNum) {
    if (variable.enclosingElement is ClassElement) {
      assert(unitNum == 0);
    }
    UnlinkedVariableBuilder b = new UnlinkedVariableBuilder(ctx);
    b.name = variable.name;
    b.unit = unitNum;
    b.type = serializeTypeRef(variable.type);
    b.isStatic = variable.isStatic && variable.enclosingElement is ClassElement;
    b.isFinal = variable.isFinal;
    b.isConst = variable.isConst;
    return b.finish();
  }
}
