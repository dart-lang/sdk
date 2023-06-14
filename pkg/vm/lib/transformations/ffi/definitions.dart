// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiAbiSpecificIntegerInvalid,
        messageFfiAbiSpecificIntegerMappingInvalid,
        messageFfiPackedAnnotationAlignment,
        messageNonPositiveArrayDimensions,
        templateFfiCompoundImplementsFinalizable,
        templateFfiEmptyStruct,
        templateFfiFieldAnnotation,
        templateFfiFieldCyclic,
        templateFfiFieldInitializer,
        templateFfiFieldNoAnnotation,
        templateFfiFieldNull,
        templateFfiPackedAnnotation,
        templateFfiSizeAnnotation,
        templateFfiSizeAnnotationDimensions,
        templateFfiStructGeneric,
        templateFfiTypeMismatch;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;
import 'package:kernel/util/graph.dart';

import 'abi.dart';
import 'common.dart';
import 'native_type_cfe.dart';

/// Checks and elaborates the dart:ffi compounds and their fields.
///
/// Input:
/// final class Coord extends Struct {
///   @Double()
///   double x;
///
///   @Double()
///   double y;
///
///   Pointer<Coord> next;
/// }
///
/// Output:
/// final class Coord extends Struct {
///   Coord.#fromTypedDataBase(Pointer<Coord> coord) : super._(coord);
///
///   set x(double v) => ...;
///   double get x => ...;
///
///   set y(double v) => ...;
///   double get y => ...;
///
///   set next(Pointer<Coord> v) => ...;
///   Pointer<Coord> get next => ...;
///
///   static int get #sizeOf => (const [24, 20, 24])[_abi()];
/// }
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex,
    ChangedStructureNotifier? changedStructureNotifier) {
  final LibraryIndex index = LibraryIndex(component, const [
    'dart:core',
    'dart:ffi',
    'dart:_internal',
    'dart:typed_data',
    'dart:nativewrappers'
  ]);
  if (!index.containsLibrary('dart:ffi')) {
    // TODO: This check doesn't make sense: "dart:ffi" is always loaded/created
    // for the VM target.
    // If dart:ffi is not loaded, do not do the transformation.
    return;
  }
  if (index.tryGetClass('dart:ffi', 'NativeFunction') == null) {
    // If dart:ffi is not loaded (for real): do not do the transformation.
    return;
  }
  final transformer = new _FfiDefinitionTransformer(index, coreTypes, hierarchy,
      diagnosticReporter, referenceFromIndex, changedStructureNotifier);
  libraries.forEach(transformer.visitLibrary);
  transformer.manualVisitInTopologicalOrder();
}

class CompoundDependencyGraph<T> implements Graph<T> {
  final Map<T, Iterable<T>> map;
  CompoundDependencyGraph(this.map);

  Iterable<T> get vertices => map.keys;
  Iterable<T> neighborsOf(T vertex) => map[vertex]!;
}

/// Checks and elaborates the dart:ffi compounds and their fields.
class _FfiDefinitionTransformer extends FfiTransformer {
  final LibraryIndex index;

  // Data structures for topological navigation.
  Map<Class, IndexedClass> indexedCompoundClasses = {};
  Set<Class> transformCompounds = {};
  Set<Class> transformCompoundsInvalid = {};
  Map<Class, NativeTypeCfe> compoundCache = {};

  ChangedStructureNotifier? changedStructureNotifier;

  _FfiDefinitionTransformer(
      this.index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex,
      this.changedStructureNotifier)
      : super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex) {}

  /// Finds all compound class dependencies.
  ///
  /// Works both for transformed and non-transformed compound classes.
  Set<Class> _compoundClassDependencies(Class node) {
    final fieldTypes = _compoundAnnotatedFields(node);
    if (fieldTypes != null) {
      // Transformed classes.
      return _compoundAnnotatedDependencies(fieldTypes);
    }

    // Non-transformed classes.
    final dependencies = <Class>{};
    final membersWithAnnotations =
        _compoundFieldMembers(node, includeSetters: false);
    for (final Member f in membersWithAnnotations) {
      final type = _compoundMemberType(f);
      if (isCompoundSubtype(type)) {
        final clazz = (type as InterfaceType).classNode;
        dependencies.add(clazz);
      } else if (isArrayType(type)) {
        final sizeAnnotations = _getArraySizeAnnotations(f);
        if (sizeAnnotations.length == 1) {
          final singleElementType = arraySingleElementType(type);
          if (singleElementType is InterfaceType &&
              isCompoundSubtype(singleElementType)) {
            final clazz = singleElementType.classNode;
            dependencies.add(clazz);
          }
        }
      }
    }
    return dependencies;
  }

  /// Creates a dependency graph containing all compounds being compiled
  /// in this compilation, and their transitive dependencies.
  CompoundDependencyGraph<Class> _compoundDependencyGraph() {
    Map<Class, Set<Class>> compoundClassDependencies = {};
    final toProcess = [...transformCompounds, ...transformCompoundsInvalid];

    while (toProcess.isNotEmpty) {
      final clazz = toProcess.removeLast();
      if (!compoundClassDependencies.containsKey(clazz)) {
        final dependencies = _compoundClassDependencies(clazz);
        compoundClassDependencies[clazz] = dependencies;
        toProcess.addAll(dependencies);
      }
    }

    return CompoundDependencyGraph(compoundClassDependencies);
  }

  void manualVisitInTopologicalOrder() {
    final dependencyGraph = _compoundDependencyGraph();
    final connectedComponents = computeStrongComponents(dependencyGraph);

    connectedComponents.forEach((List<Class> component) {
      bool report = false;
      if (component.length > 1) {
        // Indirect cycle.
        report = true;
      }
      if (component.length == 1) {
        if (dependencyGraph.map[component.single]!.contains(component.single)) {
          // Direct cycle.
          report = true;
        }
      }
      if (report) {
        component.forEach((Class e) {
          diagnosticReporter.report(
              templateFfiFieldCyclic.withArguments(e.superclass!.name, e.name,
                  component.map((e) => e.name).toList()),
              e.fileOffset,
              e.name.length,
              e.fileUri);
          compoundCache[e] = InvalidNativeTypeCfe("Cyclic members.");
          if (transformCompoundsInvalid.contains(e) ||
              transformCompounds.contains(e)) {
            final indexedClass = indexedCompoundClasses[e];
            _addSizeOfField(e, indexedClass);
          }
        });
      } else {
        // Only visit the ones without cycles.
        final clazz = component.single;
        final mustBeTransformed = (transformCompoundsInvalid.contains(clazz) ||
            transformCompounds.contains(clazz));
        if (!mustBeTransformed) {
          compoundCache[clazz] = _compoundAnnotatedNativeTypeCfe(clazz);
        } else {
          final compoundData = _findFields(clazz);
          final compoundType = compoundData.compoundType;
          compoundCache[clazz] = compoundType;
          final indexedClass = indexedCompoundClasses[clazz];
          if (transformCompounds.contains(clazz) &&
              compoundType is! InvalidNativeTypeCfe) {
            // Only replace fields if valid.
            _replaceFields(clazz, indexedClass, compoundData);
            _addSizeOfField(clazz, indexedClass, compoundType.size);
          } else {
            // Do add a sizeOf field even if invalid.
            _addSizeOfField(clazz, indexedClass);
          }
          changedStructureNotifier?.registerClassMemberChange(clazz);
        }
      }
    });
  }

  @override
  visitExtension(Extension node) {
    // The extension and it's members are only metadata.
    return node;
  }

  bool _isUserCompound(Class node) {
    if (!hierarchy.isSubclassOf(node, compoundClass) ||
        node == compoundClass ||
        node == structClass ||
        node == unionClass) {
      return false;
    }
    return true;
  }

  bool _isUserAbiSpecificInteger(Class node) =>
      hierarchy.isSubclassOf(node, abiSpecificIntegerClass) &&
      node != abiSpecificIntegerClass;

  @override
  visitClass(Class node) {
    if (_isUserAbiSpecificInteger(node)) {
      final nativeTypeCfe = NativeTypeCfe(
              this, node.getThisType(coreTypes, Nullability.nonNullable))
          as AbiSpecificNativeTypeCfe;
      if (nativeTypeCfe.abiSpecificTypes.isEmpty) {
        // Annotation missing, multiple annotations, or invalid mapping.
        diagnosticReporter.report(messageFfiAbiSpecificIntegerMappingInvalid,
            node.fileOffset, node.name.length, node.location!.file);
      }
      if (node.typeParameters.isNotEmpty ||
          node.procedures.where((Procedure e) => !e.isSynthetic).isNotEmpty ||
          node.fields.isNotEmpty ||
          node.constructors.length != 1 ||
          !node.constructors.single.isConst) {
        // We want exactly one constructor, no other members and no type arguments.
        diagnosticReporter.report(messageFfiAbiSpecificIntegerInvalid,
            node.fileOffset, node.name.length, node.location!.file);
      }
      final IndexedClass? indexedClass =
          currentLibraryIndex?.lookupIndexedClass(node.name);
      _addSizeOfField(node, indexedClass, nativeTypeCfe.size);
      _annotateAbiSpecificTypeWithMapping(node, nativeTypeCfe);
    }
    if (!_isUserCompound(node)) {
      return node;
    }

    final packing = _checkCompoundClass(node);

    final IndexedClass? indexedClass =
        currentLibraryIndex?.lookupIndexedClass(node.name);
    _checkConstructors(node, indexedClass);
    if (indexedClass != null) {
      indexedCompoundClasses[node] = indexedClass;
    }

    final fieldsValid = _checkFieldAnnotations(node, packing);
    if (fieldsValid) {
      // Only do the transformation if the compound is valid.
      transformCompounds.add(node);
    } else {
      transformCompoundsInvalid.add(node);
    }

    return node;
  }

  /// Returns packing if any.
  int? _checkCompoundClass(Class node) {
    if (node.typeParameters.isNotEmpty) {
      diagnosticReporter.report(
          templateFfiStructGeneric.withArguments(
              node.superclass!.name, node.name),
          node.fileOffset,
          1,
          node.location!.file);
    }

    if (node.superclass != structClass && node.superclass != unionClass) {
      // Not a struct or union, but extends a struct or union.
      // The error will be emitted by _FfiUseSiteTransformer.
      return null;
    }

    final finalizableType = FutureOrType(
        InterfaceType(finalizableClass, Nullability.nullable),
        Nullability.nullable);
    if (env.isSubtypeOf(InterfaceType(node, Nullability.nonNullable),
        finalizableType, SubtypeCheckMode.ignoringNullabilities)) {
      diagnosticReporter.report(
          templateFfiCompoundImplementsFinalizable.withArguments(
              node.superclass!.name, node.name),
          node.fileOffset,
          1,
          node.location!.file);
    }

    if (node.superclass == structClass) {
      final packingAnnotations = _getPackedAnnotations(node);
      if (packingAnnotations.length > 1) {
        diagnosticReporter.report(
            templateFfiPackedAnnotation.withArguments(node.name),
            node.fileOffset,
            node.name.length,
            node.location!.file);
      }
      if (packingAnnotations.isNotEmpty) {
        final packing = packingAnnotations.first;
        if (!(packing == 1 ||
            packing == 2 ||
            packing == 4 ||
            packing == 8 ||
            packing == 16)) {
          diagnosticReporter.report(messageFfiPackedAnnotationAlignment,
              node.fileOffset, node.name.length, node.location!.file);
        }
        return packing;
      }
    }
    return null;
  }

  /// Returns members of [node] that possibly correspond to compound fields.
  ///
  /// Note that getters and setters that originate from an external field have
  /// the same `fileOffset`, we always returns getters first.
  ///
  /// This works only for non-transformed compounds.
  List<Member> _compoundFieldMembers(Class node, {bool includeSetters = true}) {
    assert(_compoundAnnotatedFields(node) == null);
    final getterSetters = node.procedures.where((p) {
      if (!p.isExternal) {
        // Getters and setters corresponding to native fields are external.
        return false;
      }
      if (p.isSetter && includeSetters) {
        return true;
      }
      return p.isGetter;
    });
    final compoundMembers = [...node.fields, ...getterSetters]..sort((m1, m2) {
        if (m1.fileOffset == m2.fileOffset) {
          // Getter and setter have same offset, getter comes first.
          if (m1 is Procedure) {
            return m1.isGetter ? -1 : 1;
          }
          // Generated fields with fileOffset identical to class, fallthrough.
        }
        return m1.fileOffset - m2.fileOffset;
      });
    return compoundMembers;
  }

  DartType _compoundMemberType(Member member) {
    if (member is Field) {
      return member.type;
    }
    final p = member as Procedure;
    if (p.isGetter) {
      return p.function.returnType;
    }
    return p.function.positionalParameters.single.type;
  }

  bool _checkFieldAnnotations(Class node, int? packing) {
    bool success = true;
    final membersWithAnnotations =
        _compoundFieldMembers(node, includeSetters: false);
    for (final Member f in membersWithAnnotations) {
      if (f is Field) {
        if (f.initializer is! NullLiteral) {
          diagnosticReporter.report(
              templateFfiFieldInitializer.withArguments(f.name.text),
              f.fileOffset,
              f.name.text.length,
              f.fileUri);
          // This class is invalid, but continue reporting other errors on it.
          success = false;
        }
      }
      final nativeTypeAnnos = _getNativeTypeAnnotations(f).toList();
      final type = _compoundMemberType(f);
      if (type is NullType ||
          type.declaredNullability == Nullability.nullable ||
          type.declaredNullability == Nullability.undetermined) {
        diagnosticReporter.report(
            templateFfiFieldNull.withArguments(f.name.text),
            f.fileOffset,
            f.name.text.length,
            f.fileUri);
        // This class is invalid, but continue reporting other errors on it.
        success = false;
      } else if (isPointerType(type) ||
          isCompoundSubtype(type) ||
          isArrayType(type)) {
        if (nativeTypeAnnos.isNotEmpty) {
          diagnosticReporter.report(
              templateFfiFieldNoAnnotation.withArguments(f.name.text),
              f.fileOffset,
              f.name.text.length,
              f.fileUri);
          // This class is invalid, but continue reporting other errors on it.
          success = false;
        }
        if (isArrayType(type)) {
          try {
            ensureNativeTypeValid(type, f, allowInlineArray: true);
          } on FfiStaticTypeError {
            // It's OK to swallow the exception because the diagnostics issued will
            // cause compilation to fail. By continuing, we can report more
            // diagnostics before compilation ends.
            success = false;
          }
          final sizeAnnotations = _getArraySizeAnnotations(f);
          if (sizeAnnotations.length == 1) {
            final singleElementType = arraySingleElementType(type);
            if (singleElementType is! InterfaceType) {
              assert(singleElementType is InvalidType);
              // This class is invalid, but continue reporting other errors on it.
              // An error on the type will already have been reported.
              success = false;
            } else {
              final dimensions = sizeAnnotations.single;
              if (arrayDimensions(type) != dimensions.length) {
                diagnosticReporter.report(
                    templateFfiSizeAnnotationDimensions
                        .withArguments(f.name.text),
                    f.fileOffset,
                    f.name.text.length,
                    f.fileUri);
              }
              for (var dimension in dimensions) {
                if (dimension <= 0) {
                  diagnosticReporter.report(messageNonPositiveArrayDimensions,
                      f.fileOffset, f.name.text.length, f.fileUri);
                  success = false;
                }
              }
            }
          } else {
            diagnosticReporter.report(
                templateFfiSizeAnnotation.withArguments(f.name.text),
                f.fileOffset,
                f.name.text.length,
                f.fileUri);
            success = false;
          }
        }
      } else if (nativeTypeAnnos.length != 1) {
        diagnosticReporter.report(
            templateFfiFieldAnnotation.withArguments(f.name.text),
            f.fileOffset,
            f.name.text.length,
            f.fileUri);
        // This class is invalid, but continue reporting other errors on it.
        success = false;
      } else {
        final DartType nativeType =
            InterfaceType(nativeTypeAnnos.first, Nullability.legacy);
        final DartType? shouldBeDartType = convertNativeTypeToDartType(
            nativeType,
            allowCompounds: true,
            allowHandle: false);
        if (shouldBeDartType == null ||
            !env.isSubtypeOf(type, shouldBeDartType,
                SubtypeCheckMode.ignoringNullabilities)) {
          diagnosticReporter.report(
              templateFfiTypeMismatch.withArguments(type, shouldBeDartType!,
                  nativeType, node.enclosingLibrary.isNonNullableByDefault),
              f.fileOffset,
              1,
              f.location!.file);
          // This class is invalid, but continue reporting other errors on it.
          success = false;
        }
      }
    }
    return success;
  }

  void _checkConstructors(Class node, IndexedClass? indexedClass) {
    final toRemove = <Initializer>[];

    // Constructors cannot have initializers because initializers refer to
    // fields, and the fields were replaced with getter/setter pairs.
    for (final Constructor c in node.constructors) {
      for (final Initializer i in c.initializers) {
        if (i is FieldInitializer) {
          toRemove.add(i);
          diagnosticReporter.report(
              templateFfiFieldInitializer.withArguments(i.field.name.text),
              i.fileOffset,
              1,
              i.location!.file);
        }
      }
    }
    // Remove initializers referring to fields to prevent cascading errors.
    for (final Initializer i in toRemove) {
      final c = i.parent as Constructor;
      c.initializers.remove(i);
    }

    /// Add a constructor which 'load' can use.
    ///
    /// ```dart
    /// #fromTypedDataBase(Object #typedDataBase) :
    ///   super._fromTypedDataBase(#typedDataBase);
    /// ```
    final VariableDeclaration typedDataBase = new VariableDeclaration(
        "#typedDataBase",
        type: coreTypes.objectNonNullableRawType,
        isSynthesized: true);
    final name = Name("#fromTypedDataBase");
    final reference = indexedClass?.lookupConstructorReference(name);
    final Constructor ctor = Constructor(
        FunctionNode(EmptyStatement(),
            positionalParameters: [typedDataBase],
            returnType: InterfaceType(node, Nullability.nonNullable)),
        name: name,
        initializers: [
          SuperInitializer(
              node.superclass == structClass
                  ? structFromTypedDataBase
                  : unionFromTypedDataBase,
              Arguments([VariableGet(typedDataBase)]))
        ],
        fileUri: node.fileUri,
        reference: reference)
      ..fileOffset = node.fileOffset
      ..isNonNullableByDefault = node.enclosingLibrary.isNonNullableByDefault;

    // Struct objects are manufactured in the VM by being passed by value
    // in return position in FFI calls, and by value in arguments in FFI
    // callbacks.
    node.addConstructor(ctor);
  }

  // Works only for non-transformed classes.
  CompoundData _findFields(Class node) {
    final types = <NativeTypeCfe>[];
    final fields = <int, Field>{};
    final getters = <int, Procedure>{};
    final setters = <int, Procedure>{};
    int i = 0;
    for (final Member m in _compoundFieldMembers(node)) {
      final dartType = _compoundMemberType(m);

      // Nullable.
      NativeTypeCfe? type;
      if (isArrayType(dartType)) {
        final sizeAnnotations = _getArraySizeAnnotations(m).toList();
        if (sizeAnnotations.length == 1) {
          final arrayDimensions = sizeAnnotations.single;
          if (this.arrayDimensions(dartType) == arrayDimensions.length) {
            final elementType = arraySingleElementType(dartType);
            if (elementType is! InterfaceType) {
              assert(elementType is InvalidType);
              type = InvalidNativeTypeCfe("Invalid element type.");
            } else {
              type = NativeTypeCfe(this, dartType,
                  compoundCache: compoundCache,
                  arrayDimensions: arrayDimensions);
            }
          } else {
            type = InvalidNativeTypeCfe("Invalid array dimensions.");
          }
        }
      } else if (isPointerType(dartType) || isCompoundSubtype(dartType)) {
        type = NativeTypeCfe(this, dartType, compoundCache: compoundCache);
      } else {
        // The C type is in the annotation, not the field type itself.
        final nativeTypeAnnos = _getNativeTypeAnnotations(m).toList();
        if (nativeTypeAnnos.length == 1) {
          final clazz = nativeTypeAnnos.first;
          if (_isUserAbiSpecificInteger(clazz)) {
            type = NativeTypeCfe(
                this, clazz.getThisType(coreTypes, Nullability.nonNullable));
          } else {
            final nativeType = _getFieldType(clazz)!;
            type = PrimitiveNativeTypeCfe(nativeType, clazz);
          }
        }
      }

      if ((m is Field || (m is Procedure && m.isGetter)) && type != null) {
        types.add(type);
        if (m is Field) {
          fields[i] = m;
        }
        if (m is Procedure) {
          getters[i] = m;
        }
        i++;
      }
      if (m is Procedure && m.isSetter) {
        final index = i - 1; // The corresponding getter's index.
        final getter = getters[index];
        if (getter != null && getter.name == m.name) {
          setters[i - 1] = m;
        }
      }
    }

    final packingAnnotations = _getPackedAnnotations(node);
    final packing =
        (packingAnnotations.isNotEmpty) ? packingAnnotations.first : null;

    final compoundType = () {
      if (types.whereType<InvalidNativeTypeCfe>().isNotEmpty) {
        return InvalidNativeTypeCfe("Nested member invalid.");
      }
      if (node.superclass == structClass) {
        return StructNativeTypeCfe(node, types, packing: packing);
      }
      return UnionNativeTypeCfe(node, types);
    }();

    List<CompoundField> fieldsFound = [];
    for (int j = 0; j < i; j++) {
      fieldsFound
          .add(CompoundField(types[j], fields[j], getters[j], setters[j]));
    }
    return CompoundData(fieldsFound, packing, compoundType);
  }

  /// Computes the field offsets (for all ABIs) in the compound and replaces
  /// the fields with getters and setters using these offsets.
  ///
  /// Returns the total size of the compound (for all ABIs).
  void _replaceFields(
      Class node, IndexedClass? indexedClass, CompoundData compoundData) {
    final compoundType = compoundData.compoundType as CompoundNativeTypeCfe;
    final compoundLayout = compoundType.layout;

    _annoteCompoundWithFields(node, compoundType.members, compoundData.packing);
    if (compoundType.members.isEmpty) {
      diagnosticReporter.report(
          templateFfiEmptyStruct.withArguments(
              node.superclass!.name, node.name),
          node.fileOffset,
          node.name.length,
          node.location!.file);
    }

    final unalignedAccess = compoundData.packing != null;

    int i = 0;
    for (final compoundField in compoundData.compoundFields) {
      NativeTypeCfe type = compoundField.type;
      Field? field = compoundField.field;
      Procedure? getter = compoundField.getter;
      Procedure? setter = compoundField.setter;

      final fieldOffsets = compoundLayout
          .map((Abi abi, CompoundLayout v) => MapEntry(abi, v.offsets[i]));

      if (field != null) {
        _generateMethodsForField(
            node, field, type, fieldOffsets, unalignedAccess, indexedClass);
      }

      if (getter != null) {
        getter.function.body = type.generateGetterStatement(
            getter.function.returnType,
            getter.fileOffset,
            fieldOffsets,
            unalignedAccess,
            this);
        getter.isExternal = false;
      }

      if (setter != null) {
        setter.function.body = type.generateSetterStatement(
            setter.function.positionalParameters.single.type,
            setter.fileOffset,
            fieldOffsets,
            unalignedAccess,
            setter.function.positionalParameters.single,
            this);
        setter.isExternal = false;
      }

      i++;
    }
  }

  static const vmFfiStructFields = "vm:ffi:struct-fields";

  InstanceConstant? _compoundAnnotatedFields(Class node) {
    for (final annotation in node.annotations) {
      if (annotation is ConstantExpression) {
        final constant = annotation.constant;
        if (constant is InstanceConstant &&
            constant.classNode == pragmaClass &&
            constant.fieldValues[pragmaName.fieldReference] ==
                StringConstant(vmFfiStructFields)) {
          return constant.fieldValues[pragmaOptions.fieldReference]
              as InstanceConstant?;
        }
      }
    }
    return null;
  }

  Set<Class> _compoundAnnotatedDependencies(InstanceConstant layoutConstant) {
    final fieldTypes = layoutConstant
        .fieldValues[ffiStructLayoutTypesField.fieldReference] as ListConstant;
    final result = <Class>{};
    for (final fieldType in fieldTypes.entries) {
      if (fieldType is TypeLiteralConstant) {
        final type = fieldType.type;
        if (isCompoundSubtype(type)) {
          final clazz = (type as InterfaceType).classNode;
          result.add(clazz);
        }
      }
    }
    return result;
  }

  /// Must only be called if all the dependencies are already in the cache.
  CompoundNativeTypeCfe _compoundAnnotatedNativeTypeCfe(Class compoundClass) {
    final layoutConstant = _compoundAnnotatedFields(compoundClass)!;
    final fieldTypes = layoutConstant
        .fieldValues[ffiStructLayoutTypesField.fieldReference] as ListConstant;
    final members = <NativeTypeCfe>[];
    for (final fieldType in fieldTypes.entries) {
      if (fieldType is TypeLiteralConstant) {
        final dartType = fieldType.type;
        members
            .add(NativeTypeCfe(this, dartType, compoundCache: compoundCache));
      } else if (fieldType is InstanceConstant) {
        final singleElementConstant =
            fieldType.fieldValues[ffiInlineArrayElementTypeField.fieldReference]
                as TypeLiteralConstant;
        final singleElementType = NativeTypeCfe(
            this, singleElementConstant.type,
            compoundCache: compoundCache);
        final arrayLengthConstant =
            fieldType.fieldValues[ffiInlineArrayLengthField.fieldReference]
                as IntConstant;
        final arrayLength = arrayLengthConstant.value;
        members.add(ArrayNativeTypeCfe(singleElementType, arrayLength));
      }
    }
    if (compoundClass.superclass == structClass) {
      final packingConstant = layoutConstant
          .fieldValues[ffiStructLayoutPackingField.fieldReference];
      if (packingConstant is IntConstant) {
        return StructNativeTypeCfe(compoundClass, members,
            packing: packingConstant.value);
      }
      return StructNativeTypeCfe(compoundClass, members);
    }
    return UnionNativeTypeCfe(compoundClass, members);
  }

  void _annoteCompoundWithFields(
      Class node, List<NativeTypeCfe> types, int? packing) {
    List<Constant> constants =
        types.map((t) => t.generateConstant(this)).toList();

    node.addAnnotation(ConstantExpression(
        InstanceConstant(pragmaClass.reference, [], {
          pragmaName.fieldReference: StringConstant(vmFfiStructFields),
          pragmaOptions.fieldReference:
              InstanceConstant(ffiStructLayoutClass.reference, [], {
            ffiStructLayoutTypesField.fieldReference: ListConstant(
                InterfaceType(typeClass, Nullability.nonNullable), constants),
            ffiStructLayoutPackingField.fieldReference:
                packing == null ? NullConstant() : IntConstant(packing)
          })
        }),
        InterfaceType(pragmaClass, Nullability.nonNullable, [])));
  }

  static const vmFfiAbiSpecificIntMapping = 'vm:ffi:abi-specific-mapping';

  void _annotateAbiSpecificTypeWithMapping(
      Class node, AbiSpecificNativeTypeCfe nativeTypeCfe) {
    final constants = [
      for (final abi in Abi.values)
        nativeTypeCfe.abiSpecificTypes[abi]?.generateConstant(this) ??
            NullConstant()
    ];
    node.addAnnotation(ConstantExpression(
        InstanceConstant(pragmaClass.reference, [], {
          pragmaName.fieldReference: StringConstant(vmFfiAbiSpecificIntMapping),
          pragmaOptions.fieldReference: InstanceConstant(
            ffiAbiSpecificMappingClass.reference,
            [],
            {
              ffiAbiSpecificMappingNativeTypesField.fieldReference:
                  ListConstant(
                InterfaceType(typeClass, Nullability.nullable),
                constants,
              ),
            },
          )
        }),
        InterfaceType(pragmaClass, Nullability.nonNullable, [])));
  }

  void _generateMethodsForField(
      Class node,
      Field field,
      NativeTypeCfe type,
      Map<Abi, int?> offsets,
      bool unalignedAccess,
      IndexedClass? indexedClass) {
    // TODO(johnniwinther): Avoid passing [indexedClass]. When compiling
    // incrementally, [field] should already carry the references from
    // [indexedClass].
    final getterStatement = type.generateGetterStatement(
        field.type, field.fileOffset, offsets, unalignedAccess, this);
    Reference getterReference =
        indexedClass?.lookupGetterReference(field.name) ??
            field.getterReference;
    assert(getterReference == field.getterReference,
        "Unexpected getter reference for ${field}, found $getterReference.");
    final Procedure getter = Procedure(field.name, ProcedureKind.Getter,
        FunctionNode(getterStatement, returnType: field.type),
        fileUri: field.fileUri, reference: getterReference)
      ..fileOffset = field.fileOffset
      ..isNonNullableByDefault = field.isNonNullableByDefault
      ..annotations = field.annotations;
    node.addProcedure(getter);

    if (!field.isFinal) {
      Reference? setterReference =
          indexedClass?.lookupSetterReference(field.name) ??
              field.setterReference;
      assert(setterReference == field.setterReference,
          "Unexpected setter reference for ${field}, found $setterReference.");
      final VariableDeclaration argument =
          VariableDeclaration('#v', type: field.type, isSynthesized: true)
            ..fileOffset = field.fileOffset;
      final setterStatement = type.generateSetterStatement(field.type,
          field.fileOffset, offsets, unalignedAccess, argument, this);
      final setter = Procedure(
          field.name,
          ProcedureKind.Setter,
          FunctionNode(setterStatement,
              returnType: VoidType(), positionalParameters: [argument]),
          fileUri: field.fileUri,
          reference: setterReference)
        ..fileOffset = field.fileOffset
        ..isNonNullableByDefault = field.isNonNullableByDefault;
      node.addProcedure(setter);
    }

    node.fields.remove(field);
  }

  /// Sample output:
  /// int get #sizeOf => (const [24,24,16])[_abi()];
  ///
  /// If sizes are not supplied still emits a field so that the use site
  /// transformer can still rewrite to it.
  void _addSizeOfField(Class compound, IndexedClass? indexedClass,
      [Map<Abi, int?>? sizes = null]) {
    if (sizes == null) {
      sizes = {for (var abi in Abi.values) abi: 0};
    }
    final name = Name("#sizeOf");
    final getterReference = indexedClass?.lookupGetterReference(name);

    final Procedure getter = Procedure(
        name,
        ProcedureKind.Getter,
        FunctionNode(ReturnStatement(runtimeBranchOnLayout(sizes)),
            returnType: InterfaceType(intClass, Nullability.legacy)),
        fileUri: compound.fileUri,
        reference: getterReference,
        isStatic: true)
      ..fileOffset = compound.fileOffset
      ..isNonNullableByDefault = true
      ..addAnnotation(ConstantExpression(
          InstanceConstant(pragmaClass.reference, /*type_arguments=*/ [], {
        pragmaName.fieldReference: StringConstant("vm:prefer-inline"),
        pragmaOptions.fieldReference: NullConstant(),
      })));

    compound.addProcedure(getter);
  }

  NativeType? _getFieldType(Class c) {
    final fieldType = getType(c);

    if (fieldType == NativeType.kVoid) {
      // Fields cannot have Void types.
      return null;
    }
    return fieldType;
  }

  Iterable<Class> _getNativeTypeAnnotations(Member node) {
    return node.annotations
        .whereType<ConstantExpression>()
        .map((expr) => expr.constant)
        .whereType<InstanceConstant>()
        .map((constant) => constant.classNode)
        .where((klass) =>
            _getFieldType(klass) != null || _isUserAbiSpecificInteger(klass));
  }

  Iterable<List<int>> _getArraySizeAnnotations(Member node) {
    return node.annotations
        .whereType<ConstantExpression>()
        .map((e) => e.constant)
        .whereType<InstanceConstant>()
        .where((e) => e.classNode == arraySizeClass)
        .map(_arraySize);
  }

  List<int> _arraySize(InstanceConstant constant) {
    final dimensions =
        constant.fieldValues[arraySizeDimensionsField.fieldReference];
    if (dimensions != null) {
      if (dimensions is ListConstant) {
        final result = dimensions.entries
            .whereType<IntConstant>()
            .map((e) => e.value)
            .toList();
        return result;
      }
    }
    final dimensionFields = [
      arraySizeDimension1Field,
      arraySizeDimension2Field,
      arraySizeDimension3Field,
      arraySizeDimension4Field,
      arraySizeDimension5Field
    ];
    final result = dimensionFields
        .map((f) => constant.fieldValues[f.fieldReference])
        .whereType<IntConstant>()
        .map((c) => c.value)
        .toList();
    return result;
  }

  Iterable<int> _getPackedAnnotations(Class node) {
    return node.annotations
        .whereType<ConstantExpression>()
        .map((expr) => expr.constant)
        .whereType<InstanceConstant>()
        .where((e) => e.classNode == packedClass)
        .map((e) => e.fieldValues.values.single)
        .whereType<IntConstant>()
        .map((e) => e.value);
  }
}

class CompoundData {
  final List<CompoundField> compoundFields;
  final int? packing;
  final NativeTypeCfe compoundType;

  CompoundData(this.compoundFields, this.packing, this.compoundType);
}

class CompoundField {
  final NativeTypeCfe type;
  final Field? field;
  final Procedure? getter;
  final Procedure? setter;

  CompoundField(this.type, this.field, this.getter, this.setter);
}
