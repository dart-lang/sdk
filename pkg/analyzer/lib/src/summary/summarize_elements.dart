// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.elements;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/builder.dart';
import 'package:analyzer/src/summary/format.dart';

/**
 * Serialize all the elements in [lib] to a summary using [ctx] as the context
 * for building the summary, and using [typeProvider] to find built-in types.
 */
PrelinkedLibraryBuilder serializeLibrary(
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
   * List of objects which should be written to [PrelinkedLibrary.units].
   */
  final List<PrelinkedUnitBuilder> units = <PrelinkedUnitBuilder>[];

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
   * [BuilderContext] used to serialize the output summary.
   */
  final BuilderContext ctx;

  _LibrarySerializer(this.ctx, this.libraryElement, this.typeProvider) {
    dependencies.add(encodePrelinkedDependency(ctx));
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
    UnlinkedUnitBuilder b = new UnlinkedUnitBuilder(ctx);
    unlinkedReferences = <UnlinkedReferenceBuilder>[
      encodeUnlinkedReference(ctx)
    ];
    prelinkedReferences = <PrelinkedReferenceBuilder>[
      encodePrelinkedReference(ctx, kind: PrelinkedReferenceKind.classOrEnum)
    ];
    if (unitNum == 0) {
      // TODO(paulberry): we need to figure out a way to record library, part,
      // import, and export declarations that appear in non-defining
      // compilation units (even though such declarations are prohibited by the
      // language), so that if the user makes code changes that cause a
      // non-defining compilation unit to become a defining compilation unit,
      // we can create a correct summary by simply re-linking.
      if (libraryElement.name.isNotEmpty) {
        b.libraryName = libraryElement.name;
      }
      b.exports = libraryElement.exports.map(serializeExport).toList();
      b.imports = libraryElement.imports.map(serializeImport).toList();
      b.parts = libraryElement.parts
          .map(
              (CompilationUnitElement e) => encodeUnlinkedPart(ctx, uri: e.uri))
          .toList();
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
    units.add(
        encodePrelinkedUnit(ctx, unlinked: b, references: prelinkedReferences));
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
    UnlinkedClassBuilder b = new UnlinkedClassBuilder(ctx);
    b.name = classElement.name;
    b.typeParameters =
        classElement.typeParameters.map(serializeTypeParam).toList();
    if (classElement.supertype != null && !classElement.supertype.isObject) {
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
    return b;
  }

  /**
   * Serialize the given [combinator] into an [UnlinkedCombinator].
   */
  UnlinkedCombinatorBuilder serializeCombinator(
      NamespaceCombinator combinator) {
    UnlinkedCombinatorBuilder b = new UnlinkedCombinatorBuilder(ctx);
    if (combinator is ShowElementCombinator) {
      b.shows = combinator.shownNames.map(serializeCombinatorName).toList();
    } else if (combinator is HideElementCombinator) {
      b.hides = combinator.hiddenNames.map(serializeCombinatorName).toList();
    }
    return b;
  }

  /**
   * Serialize the given [name] into an [UnlinkedCombinatorName].
   */
  UnlinkedCombinatorNameBuilder serializeCombinatorName(String name) {
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
   * representing the pseudo-type `dynamic`.
   */
  int serializeDynamicReference() => 0;

  /**
   * Serialize the given [enumElement], creating an [UnlinkedEnum].
   */
  UnlinkedEnumBuilder serializeEnum(ClassElement enumElement) {
    UnlinkedEnumBuilder b = new UnlinkedEnumBuilder(ctx);
    b.name = enumElement.name;
    List<UnlinkedEnumValueBuilder> values = <UnlinkedEnumValueBuilder>[];
    for (FieldElement field in enumElement.fields) {
      if (field.isConst && field.type.element == enumElement) {
        values.add(encodeUnlinkedEnumValue(ctx, name: field.name));
      }
    }
    b.values = values;
    return b;
  }

  /**
   * Serialize the given [executableElement], creating an [UnlinkedExecutable].
   */
  UnlinkedExecutableBuilder serializeExecutable(
      ExecutableElement executableElement) {
    UnlinkedExecutableBuilder b = new UnlinkedExecutableBuilder(ctx);
    b.name = executableElement.name;
    if (!executableElement.type.returnType.isVoid) {
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
    return b;
  }

  /**
   * Serialize the given [exportElement] into an [UnlinkedExport].
   */
  UnlinkedExportBuilder serializeExport(ExportElement exportElement) {
    UnlinkedExportBuilder b = new UnlinkedExportBuilder(ctx);
    b.uri = exportElement.uri;
    b.combinators = exportElement.combinators.map(serializeCombinator).toList();
    return b;
  }

  /**
   * Serialize the given [importElement] yielding an [UnlinkedImportBuilder].
   * Also, add pre-linked information about it to the [prelinkedImports] list.
   */
  UnlinkedImportBuilder serializeImport(ImportElement importElement) {
    UnlinkedImportBuilder b = new UnlinkedImportBuilder(ctx);
    b.isDeferred = importElement.isDeferred;
    b.offset = importElement.nameOffset;
    b.combinators = importElement.combinators.map(serializeCombinator).toList();
    if (importElement.prefix != null) {
      b.prefixReference = serializePrefix(importElement.prefix);
    }
    if (importElement.isSynthetic) {
      b.isImplicit = true;
    } else {
      b.uri = importElement.uri;
    }
    addTransitiveExportClosure(importElement.importedLibrary);
    prelinkedImports.add(serializeDependency(importElement.importedLibrary));
    return b;
  }

  /**
   * Serialize the whole library element into a [PrelinkedLibrary].  Should be
   * called exactly once for each instance of [_LibrarySerializer].
   */
  PrelinkedLibraryBuilder serializeLibrary() {
    PrelinkedLibraryBuilder pb = new PrelinkedLibraryBuilder(ctx);
    addCompilationUnitElements(libraryElement.definingCompilationUnit, 0);
    for (int i = 0; i < libraryElement.parts.length; i++) {
      addCompilationUnitElements(libraryElement.parts[i], i + 1);
    }
    pb.units = units;
    pb.dependencies = dependencies;
    pb.importDependencies = prelinkedImports;
    return pb;
  }

  /**
   * Serialize the given [parameter] into an [UnlinkedParam].
   */
  UnlinkedParamBuilder serializeParam(ParameterElement parameter) {
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
        b.type = serializeTypeRef(type.returnType, parameter);
      }
      b.parameters = type.parameters.map(serializeParam).toList();
    } else {
      b.type = serializeTypeRef(type, parameter);
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
      unlinkedReferences.add(encodeUnlinkedReference(ctx, name: element.name));
      prelinkedReferences.add(
          encodePrelinkedReference(ctx, kind: PrelinkedReferenceKind.prefix));
      return index;
    });
  }

  /**
   * Serialize the given [typedefElement], creating an [UnlinkedTypedef].
   */
  UnlinkedTypedefBuilder serializeTypedef(
      FunctionTypeAliasElement typedefElement) {
    UnlinkedTypedefBuilder b = new UnlinkedTypedefBuilder(ctx);
    b.name = typedefElement.name;
    b.typeParameters =
        typedefElement.typeParameters.map(serializeTypeParam).toList();
    if (!typedefElement.returnType.isVoid) {
      b.returnType =
          serializeTypeRef(typedefElement.returnType, typedefElement);
    }
    b.parameters = typedefElement.parameters.map(serializeParam).toList();
    return b;
  }

  /**
   * Serialize the given [typeParameter] into an [UnlinkedTypeParam].
   */
  UnlinkedTypeParamBuilder serializeTypeParam(
      TypeParameterElement typeParameter) {
    UnlinkedTypeParamBuilder b = new UnlinkedTypeParamBuilder(ctx);
    b.name = typeParameter.name;
    if (typeParameter.bound != null) {
      b.bound = serializeTypeRef(typeParameter.bound, typeParameter);
    }
    return b;
  }

  /**
   * Serialize the given [type] into an [UnlinkedTypeRef].
   */
  UnlinkedTypeRefBuilder serializeTypeRef(DartType type, Element context) {
    UnlinkedTypeRefBuilder b = new UnlinkedTypeRefBuilder(ctx);
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
          int index = unlinkedReferences.length;
          // TODO(paulberry): set UnlinkedReference.prefix.
          unlinkedReferences
              .add(encodeUnlinkedReference(ctx, name: element.name));
          prelinkedReferences.add(encodePrelinkedReference(ctx,
              dependency: serializeDependency(dependentLibrary),
              kind: element is FunctionTypeAliasElement
                  ? PrelinkedReferenceKind.typedef
                  : PrelinkedReferenceKind.classOrEnum,
              unit: unit));
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
   * Serialize the given [variable], creating an [UnlinkedVariable].
   */
  UnlinkedVariableBuilder serializeVariable(PropertyInducingElement variable) {
    UnlinkedVariableBuilder b = new UnlinkedVariableBuilder(ctx);
    b.name = variable.name;
    b.type = serializeTypeRef(variable.type, variable);
    b.isStatic = variable.isStatic && variable.enclosingElement is ClassElement;
    b.isFinal = variable.isFinal;
    b.isConst = variable.isConst;
    b.hasImplicitType = variable.hasImplicitType;
    return b;
  }
}
