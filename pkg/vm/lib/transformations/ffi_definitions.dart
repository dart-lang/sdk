// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiPackedAnnotationAlignment,
        messageNonPositiveArrayDimensions,
        templateFfiEmptyStruct,
        templateFfiFieldAnnotation,
        templateFfiFieldNull,
        templateFfiFieldCyclic,
        templateFfiFieldNoAnnotation,
        templateFfiTypeMismatch,
        templateFfiFieldInitializer,
        templateFfiPackedAnnotation,
        templateFfiPackedNestingNonPacked,
        templateFfiSizeAnnotation,
        templateFfiSizeAnnotationDimensions,
        templateFfiStructGeneric;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;
import 'package:kernel/util/graph.dart';

import 'ffi.dart';

/// Checks and elaborates the dart:ffi compounds and their fields.
///
/// Input:
/// class Coord extends Struct {
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
/// class Coord extends Struct {
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

    // Non-tranformed classes.
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
          if (isCompoundSubtype(singleElementType)) {
            final clazz = (singleElementType as InterfaceType).classNode;
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

  @override
  visitClass(Class node) {
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
    if (node.typeParameters.length > 0) {
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
      if (type is NullType) {
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
        if (nativeTypeAnnos.length != 0) {
          diagnosticReporter.report(
              templateFfiFieldNoAnnotation.withArguments(f.name.text),
              f.fileOffset,
              f.name.text.length,
              f.fileUri);
          // This class is invalid, but continue reporting other errors on it.
          success = false;
        }
        if (isCompoundSubtype(type)) {
          final clazz = (type as InterfaceType).classNode;
          _checkPacking(node, packing, clazz, f);
        } else if (isArrayType(type)) {
          final sizeAnnotations = _getArraySizeAnnotations(f);
          if (sizeAnnotations.length == 1) {
            final singleElementType = arraySingleElementType(type);
            if (isCompoundSubtype(singleElementType)) {
              final clazz = (singleElementType as InterfaceType).classNode;
              _checkPacking(node, packing, clazz, f);
            }
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
              if (dimension < 0) {
                diagnosticReporter.report(messageNonPositiveArrayDimensions,
                    f.fileOffset, f.name.text.length, f.fileUri);
                success = false;
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
        final DartType nativeType = InterfaceType(
            nativeTypesClasses[_getFieldType(nativeTypeAnnos.first)!]!,
            Nullability.legacy);
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

  void _checkPacking(Class outerClass, int? outerClassPacking, Class fieldClass,
      Member errorNode) {
    if (outerClassPacking == null) {
      // Outer struct has no packing, nesting anything is fine.
      return;
    }

    final fieldPackingAnnotations = _getPackedAnnotations(fieldClass);
    bool error = false;
    if (fieldPackingAnnotations.isEmpty) {
      // Outer struct has packing but inner one doesn't.
      error = true;
    } else {
      final fieldPacking = fieldPackingAnnotations.first;
      if (fieldPacking > outerClassPacking) {
        // Outer struct has stricter packing than the inner.
        error = true;
      }
    }
    if (error) {
      diagnosticReporter.report(
          templateFfiPackedNestingNonPacked.withArguments(
              fieldClass.name, outerClass.name),
          errorNode.fileOffset,
          errorNode.name.text.length,
          errorNode.fileUri);
    }
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
        type: coreTypes.objectNonNullableRawType);
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
            type = NativeTypeCfe(this, dartType,
                compoundCache: compoundCache, arrayDimensions: arrayDimensions);
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
          final nativeType = _getFieldType(clazz)!;
          type = PrimitiveNativeTypeCfe(nativeType, clazz);
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
        (!packingAnnotations.isEmpty) ? packingAnnotations.first : null;

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

  // return value is nullable.
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

  /// Must only be called if all the depencies are already in the cache.
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

  // packing is `int?`.
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

  void _generateMethodsForField(Class node, Field field, NativeTypeCfe type,
      Map<Abi, int> offsets, bool unalignedAccess, IndexedClass? indexedClass) {
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
          VariableDeclaration('#v', type: field.type)
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
      [Map<Abi, int>? sizes = null]) {
    if (sizes == null) {
      sizes = Map.fromEntries(Abi.values.map((abi) => MapEntry(abi, 0)));
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
        .where((klass) => _getFieldType(klass) != null);
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

/// The layout of a `Struct` or `Union` in one [Abi].
class CompoundLayout {
  /// Size of the entire struct or union.
  final int size;

  /// Alignment of struct or union when nested in a struct.
  final int alignment;

  /// Offset in bytes for each field, indexed by field number.
  ///
  /// Always 0 for unions.
  final List<int> offsets;

  CompoundLayout(this.size, this.alignment, this.offsets);
}

/// AST node wrapper for native types.
///
/// This algebraic data structure does not stand on its own but refers
/// intimately to AST nodes such as [Class].
abstract class NativeTypeCfe {
  factory NativeTypeCfe(FfiTransformer transformer, DartType dartType,
      {List<int>? arrayDimensions,
      Map<Class, NativeTypeCfe> compoundCache = const {}}) {
    if (transformer.isPrimitiveType(dartType)) {
      final clazz = (dartType as InterfaceType).classNode;
      final nativeType = transformer.getType(clazz)!;
      return PrimitiveNativeTypeCfe(nativeType, clazz);
    }
    if (transformer.isPointerType(dartType)) {
      return PointerNativeTypeCfe();
    }
    if (transformer.isCompoundSubtype(dartType)) {
      final clazz = (dartType as InterfaceType).classNode;
      if (compoundCache.containsKey(clazz)) {
        return compoundCache[clazz]!;
      } else {
        throw "Class '$clazz' not found in compoundCache.";
      }
    }
    if (transformer.isArrayType(dartType)) {
      if (arrayDimensions == null) {
        throw "Must have array dimensions for ArrayType.";
      }
      if (arrayDimensions.length == 0) {
        throw "Must have a size for this array dimension.";
      }
      final elementType = transformer.arraySingleElementType(dartType);
      final elementCfeType =
          NativeTypeCfe(transformer, elementType, compoundCache: compoundCache);
      if (elementCfeType is InvalidNativeTypeCfe) {
        return elementCfeType;
      }
      return ArrayNativeTypeCfe.multi(elementCfeType, arrayDimensions);
    }
    throw "Invalid type $dartType";
  }

  /// The size in bytes per [Abi].
  Map<Abi, int> get size;

  /// The alignment inside structs in bytes per [Abi].
  ///
  /// This is not the alignment on stack, this is only calculated in the VM.
  Map<Abi, int> get alignment;

  /// Generates a Constant representing the type which is consumed by the VM.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ///
  /// See runtime/vm/compiler/ffi/native_type.cc:NativeType::FromAbstractType.
  Constant generateConstant(FfiTransformer transformer);

  /// Generates the return statement for a compound field getter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, bool unalignedAccess, FfiTransformer transformer);

  /// Generates the return statement for a compound field setter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateSetterStatement(
      DartType dartType,
      int fileOffset,
      Map<Abi, int> offsets,
      bool unalignedAccess,
      VariableDeclaration argument,
      FfiTransformer transformer);
}

class InvalidNativeTypeCfe implements NativeTypeCfe {
  final String reason;

  InvalidNativeTypeCfe(this.reason);

  @override
  Map<Abi, int> get alignment => throw reason;

  @override
  Constant generateConstant(FfiTransformer transformer) => throw reason;

  @override
  ReturnStatement generateGetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          FfiTransformer transformer) =>
      throw reason;

  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      throw reason;

  @override
  Map<Abi, int> get size => throw reason;
}

class PrimitiveNativeTypeCfe implements NativeTypeCfe {
  final NativeType nativeType;

  final Class clazz;

  PrimitiveNativeTypeCfe(this.nativeType, this.clazz);

  @override
  Map<Abi, int> get size {
    final int size = nativeTypeSizes[nativeType]!;
    if (size == WORD_SIZE) {
      return wordSize;
    }
    return Map.fromEntries(Abi.values.map((abi) => MapEntry(abi, size)));
  }

  @override
  Map<Abi, int> get alignment => Map.fromEntries(Abi.values.map((abi) =>
      MapEntry(abi, nonSizeAlignment[abi]![nativeType] ?? size[abi]!)));

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));

  bool get isFloat =>
      nativeType == NativeType.kFloat || nativeType == NativeType.kDouble;

  bool isUnaligned(Map<Abi, int> offsets) {
    final alignments = alignment;
    for (final abi in offsets.keys) {
      final offset = offsets[abi]!;
      final alignment = alignments[abi]!;
      if (offset % alignment != 0) {
        return true;
      }
    }
    return false;
  }

  /// Sample output for `int get x =>`:
  ///
  /// ```
  /// _loadInt8(_typedDataBase, offset);
  /// ```
  @override
  ReturnStatement generateGetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          (unalignedAccess && isFloat
              ? transformer.loadUnalignedMethods
              : transformer.loadMethods)[nativeType]!,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets)
          ]))
        ..fileOffset = fileOffset);

  /// Sample output for `set x(int #v) =>`:
  ///
  /// ```
  /// _storeInt8(_typedDataBase, offset, #v);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          (unalignedAccess && isFloat
              ? transformer.storeUnalignedMethods
              : transformer.storeMethods)[nativeType]!,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            VariableGet(argument)
          ]))
        ..fileOffset = fileOffset);
}

class PointerNativeTypeCfe implements NativeTypeCfe {
  @override
  Map<Abi, int> get size => wordSize;

  @override
  Map<Abi, int> get alignment => wordSize;

  @override
  Constant generateConstant(FfiTransformer transformer) => TypeLiteralConstant(
          InterfaceType(transformer.pointerClass, Nullability.nonNullable, [
        InterfaceType(
            transformer.pointerClass.superclass!, Nullability.nonNullable)
      ]));

  /// Sample output for `Pointer<Int8> get x =>`:
  ///
  /// ```
  /// _fromAddress<Int8>(_loadIntPtr(_typedDataBase, offset));
  /// ```
  @override
  ReturnStatement generateGetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.fromAddressInternal,
          Arguments([
            StaticInvocation(
                transformer.loadMethods[NativeType.kIntptr]!,
                Arguments([
                  transformer.getCompoundTypedDataBaseField(
                      ThisExpression(), fileOffset),
                  transformer.runtimeBranchOnLayout(offsets)
                ]))
              ..fileOffset = fileOffset
          ], types: [
            (dartType as InterfaceType).typeArguments.single
          ]))
        ..fileOffset = fileOffset);

  /// Sample output for `set x(Pointer<Int8> #v) =>`:
  ///
  /// ```
  /// _storeIntPtr(_typedDataBase, offset, (#v as Pointer<Int8>).address);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.storeMethods[NativeType.kIntptr]!,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            InstanceGet(InstanceAccessKind.Instance, VariableGet(argument),
                transformer.addressGetter.name,
                interfaceTarget: transformer.addressGetter,
                resultType: transformer.addressGetter.getterType)
              ..fileOffset = fileOffset
          ]))
        ..fileOffset = fileOffset);
}

abstract class CompoundNativeTypeCfe implements NativeTypeCfe {
  final Class clazz;

  final List<NativeTypeCfe> members;

  final Map<Abi, CompoundLayout> layout;

  CompoundNativeTypeCfe._(this.clazz, this.members, this.layout);

  @override
  Map<Abi, int> get size =>
      layout.map((abi, layout) => MapEntry(abi, layout.size));

  @override
  Map<Abi, int> get alignment =>
      layout.map((abi, layout) => MapEntry(abi, layout.alignment));

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));

  /// Sample output for `MyStruct get x =>`:
  ///
  /// ```
  /// MyStruct.#fromTypedDataBase(
  ///   typedDataBaseOffset(_typedDataBase, offset, size, dartType)
  /// );
  /// ```
  @override
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, bool unalignedAccess, FfiTransformer transformer) {
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));

    return ReturnStatement(ConstructorInvocation(
        constructor,
        Arguments([
          transformer.typedDataBaseOffset(
              transformer.getCompoundTypedDataBaseField(
                  ThisExpression(), fileOffset),
              transformer.runtimeBranchOnLayout(offsets),
              transformer.runtimeBranchOnLayout(size),
              dartType,
              fileOffset)
        ]))
      ..fileOffset = fileOffset);
  }

  /// Sample output for `set x(MyStruct #v) =>`:
  ///
  /// ```
  /// _memCopy(_typedDataBase, offset, #v._typedDataBase, 0, size);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.memCopy,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            transformer.getCompoundTypedDataBaseField(
                VariableGet(argument), fileOffset),
            ConstantExpression(IntConstant(0)),
            transformer.runtimeBranchOnLayout(size),
          ]))
        ..fileOffset = fileOffset);
}

class StructNativeTypeCfe extends CompoundNativeTypeCfe {
  // Nullable int.
  final int? packing;

  factory StructNativeTypeCfe(Class clazz, List<NativeTypeCfe> members,
      {int? packing}) {
    final layout = Map.fromEntries(Abi.values
        .map((abi) => MapEntry(abi, _calculateLayout(members, packing, abi))));
    return StructNativeTypeCfe._(clazz, members, packing, layout);
  }

  StructNativeTypeCfe._(Class clazz, List<NativeTypeCfe> members, this.packing,
      Map<Abi, CompoundLayout> layout)
      : super._(clazz, members, layout);

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeStructType::FromNativeTypes.
  static CompoundLayout _calculateLayout(
      List<NativeTypeCfe> types, int? packing, Abi abi) {
    int offset = 0;
    final offsets = <int>[];
    int structAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int size = types[i].size[abi]!;
      int alignment = types[i].alignment[abi]!;
      if (packing != null && packing < alignment) {
        alignment = packing;
      }
      if (alignment > 0) {
        offset = _alignOffset(offset, alignment);
      }
      offsets.add(offset);
      offset += size;
      structAlignment = math.max(structAlignment, alignment);
    }
    final int size = _alignOffset(offset, structAlignment);
    return CompoundLayout(size, structAlignment, offsets);
  }
}

class UnionNativeTypeCfe extends CompoundNativeTypeCfe {
  factory UnionNativeTypeCfe(Class clazz, List<NativeTypeCfe> members) {
    final layout = Map.fromEntries(
        Abi.values.map((abi) => MapEntry(abi, _calculateLayout(members, abi))));
    return UnionNativeTypeCfe._(clazz, members, layout);
  }

  UnionNativeTypeCfe._(
      Class clazz, List<NativeTypeCfe> members, Map<Abi, CompoundLayout> layout)
      : super._(clazz, members, layout);

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeUnionType::FromNativeTypes.
  static CompoundLayout _calculateLayout(List<NativeTypeCfe> types, Abi abi) {
    int unionSize = 1;
    int unionAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int size = types[i].size[abi]!;
      int alignment = types[i].alignment[abi]!;
      unionSize = math.max(unionSize, size);
      unionAlignment = math.max(unionAlignment, alignment);
    }
    final int size = _alignOffset(unionSize, unionAlignment);
    return CompoundLayout(size, unionAlignment, List.filled(types.length, 0));
  }
}

class ArrayNativeTypeCfe implements NativeTypeCfe {
  final NativeTypeCfe elementType;
  final int length;

  ArrayNativeTypeCfe(this.elementType, this.length);

  factory ArrayNativeTypeCfe.multi(
      NativeTypeCfe elementType, List<int> dimensions) {
    if (dimensions.length == 1) {
      return ArrayNativeTypeCfe(elementType, dimensions.single);
    }
    return ArrayNativeTypeCfe(
        ArrayNativeTypeCfe.multi(elementType, dimensions.sublist(1)),
        dimensions.first);
  }

  List<int> get dimensions {
    final elementType = this.elementType;
    if (elementType is ArrayNativeTypeCfe) {
      return [length, ...elementType.dimensions];
    }
    return [length];
  }

  List<int> get nestedDimensions => dimensions.sublist(1);

  int get dimensionsFlattened =>
      dimensions.fold(1, (accumulator, element) => accumulator * element);

  NativeTypeCfe get singleElementType {
    final elementType = this.elementType;
    if (elementType is ArrayNativeTypeCfe) {
      return elementType.singleElementType;
    }
    return elementType;
  }

  @override
  Map<Abi, int> get size =>
      elementType.size.map((abi, size) => MapEntry(abi, size * length));

  @override
  Map<Abi, int> get alignment => elementType.alignment;

  // Note that we flatten multi dimensional arrays.
  @override
  Constant generateConstant(FfiTransformer transformer) =>
      InstanceConstant(transformer.ffiInlineArrayClass.reference, [], {
        transformer.ffiInlineArrayElementTypeField.fieldReference:
            singleElementType.generateConstant(transformer),
        transformer.ffiInlineArrayLengthField.fieldReference:
            IntConstant(dimensionsFlattened)
      });

  /// Sample output for `Array<Int8> get x =>`:
  ///
  /// ```
  /// Array<Int8>._(
  ///   typedDataBaseOffset(_typedDataBase, offset, size, typeArgument)
  /// );
  /// ```
  @override
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, bool unalignedAccess, FfiTransformer transformer) {
    InterfaceType typeArgument =
        (dartType as InterfaceType).typeArguments.single as InterfaceType;
    return ReturnStatement(ConstructorInvocation(
        transformer.arrayConstructor,
        Arguments([
          transformer.typedDataBaseOffset(
              transformer.getCompoundTypedDataBaseField(
                  ThisExpression(), fileOffset),
              transformer.runtimeBranchOnLayout(offsets),
              transformer.runtimeBranchOnLayout(size),
              typeArgument,
              fileOffset),
          ConstantExpression(IntConstant(length)),
          transformer.intListConstantExpression(nestedDimensions)
        ], types: [
          typeArgument
        ]))
      ..fileOffset = fileOffset);
  }

  /// Sample output for `set x(Array #v) =>`:
  ///
  /// ```
  /// _memCopy(_typedDataBase, offset, #v._typedDataBase, 0, size);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.memCopy,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            transformer.getArrayTypedDataBaseField(
                VariableGet(argument), fileOffset),
            ConstantExpression(IntConstant(0)),
            transformer.runtimeBranchOnLayout(size),
          ]))
        ..fileOffset = fileOffset);
}

int _alignOffset(int offset, int alignment) =>
    ((offset + alignment - 1) ~/ alignment) * alignment;
