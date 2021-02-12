// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.ffi_definitions;

import 'dart:math' as math;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        templateFfiEmptyStruct,
        templateFfiFieldAnnotation,
        templateFfiFieldCyclic,
        templateFfiFieldNoAnnotation,
        templateFfiTypeMismatch,
        templateFfiFieldInitializer,
        templateFfiStructGeneric;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;
import 'package:kernel/util/graph.dart';

import 'ffi.dart';

/// Checks and elaborates the dart:ffi structs and fields.
///
/// Input:
/// class Coord extends Struct {
///   @Double()
///   double x;
///
///   @Double()
///   double y;
///
///   Coord next;
/// }
///
/// Output:
/// class Coord extends Struct {
///   Coord.#fromTypedDataBase(Pointer<Coord> coord) : super._(coord);
///
///   Pointer<Double> get _xPtr => addressOf.cast();
///   set x(double v) => _xPtr.store(v);
///   double get x => _xPtr.load();
///
///   Pointer<Double> get _yPtr => addressOf.offsetBy(...).cast();
///   set y(double v) => _yPtr.store(v);
///   double get y => _yPtr.load();
///
///   ffi.Pointer<Coordinate> get _nextPtr => addressof.offsetBy(...).cast();
///   set next(Coordinate v) => _nextPtr.store(v);
///   Coordinate get next => _nextPtr.load();
///
///   static final int #sizeOf = 24;
/// }
FfiTransformerData transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex referenceFromIndex,
    ChangedStructureNotifier changedStructureNotifier) {
  final LibraryIndex index = LibraryIndex(component,
      const ["dart:core", "dart:ffi", "dart:_internal", "dart:typed_data"]);
  if (!index.containsLibrary("dart:ffi")) {
    // TODO: This check doesn't make sense: "dart:ffi" is always loaded/created
    // for the VM target.
    // If dart:ffi is not loaded, do not do the transformation.
    return FfiTransformerData({}, {}, {});
  }
  if (index.tryGetClass('dart:ffi', 'NativeFunction') == null) {
    // If dart:ffi is not loaded (for real): do not do the transformation.
    return FfiTransformerData({}, {}, {});
  }
  final transformer = new _FfiDefinitionTransformer(index, coreTypes, hierarchy,
      diagnosticReporter, referenceFromIndex, changedStructureNotifier);
  libraries.forEach(transformer.visitLibrary);
  transformer.manualVisitInTopologicalOrder();
  return FfiTransformerData(transformer.replacedGetters,
      transformer.replacedSetters, transformer.emptyStructs);
}

class StructDependencyGraph<T> implements Graph<T> {
  final Map<T, Iterable<T>> map;
  StructDependencyGraph(this.map);

  Iterable<T> get vertices => map.keys;
  Iterable<T> neighborsOf(T vertex) => map[vertex];
}

/// Checks and elaborates the dart:ffi structs and fields.
class _FfiDefinitionTransformer extends FfiTransformer {
  final LibraryIndex index;

  // Data structures for topological navigation.
  Map<Class, IndexedClass> indexedStructClasses = {};
  Map<Class, Set<Class>> structClassDependencies = {};
  Map<Class, bool> fieldsValid = {};
  Map<Class, StructNativeTypeCfe> structCache = {};

  Map<Field, Procedure> replacedGetters = {};
  Map<Field, Procedure> replacedSetters = {};
  Set<Class> emptyStructs = {};

  ChangedStructureNotifier changedStructureNotifier;

  IndexedLibrary currentLibraryIndex;

  _FfiDefinitionTransformer(
      this.index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex referenceFromIndex,
      this.changedStructureNotifier)
      : super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex) {}

  void manualVisitInTopologicalOrder() {
    final connectedComponents =
        computeStrongComponents(StructDependencyGraph(structClassDependencies));

    connectedComponents.forEach((List<Class> component) {
      bool report = false;
      if (component.length > 1) {
        // Indirect cycle.
        report = true;
      }
      if (component.length == 1) {
        if (structClassDependencies[component.single]
            .contains(component.single)) {
          // Direct cycle.
          report = true;
        }
      }
      if (report) {
        component.forEach((Class e) {
          diagnosticReporter.report(
              templateFfiFieldCyclic.withArguments(
                  e.name, component.map((e) => e.name).toList()),
              e.fileOffset,
              e.name.length,
              e.fileUri);
        });
      } else {
        // Only visit the ones without cycles.
        visitClassInTopologicalOrder(component.single);
      }
    });
  }

  @override
  visitLibrary(Library node) {
    currentLibraryIndex = referenceFromIndex?.lookupLibrary(node);
    return super.visitLibrary(node);
  }

  @override
  visitExtension(Extension node) {
    // The extension and it's members are only metadata.
    return node;
  }

  @override
  visitClass(Class node) {
    if (!hierarchy.isSubclassOf(node, structClass) || node == structClass) {
      return node;
    }

    _checkStructClass(node);

    // Struct objects are manufactured in the VM by 'allocate' and 'load'.
    _makeEntryPoint(node);

    final indexedClass = currentLibraryIndex?.lookupIndexedClass(node.name);
    _checkConstructors(node, indexedClass);
    indexedStructClasses[node] = indexedClass;

    fieldsValid[node] = _checkFieldAnnotations(node);

    return node;
  }

  void visitClassInTopologicalOrder(Class node) {
    final indexedClass = indexedStructClasses[node];
    if (fieldsValid[node]) {
      final structSize = _replaceFields(node, indexedClass);
      _replaceSizeOfMethod(node, structSize, indexedClass);
      changedStructureNotifier?.registerClassMemberChange(node);
    }
  }

  void _checkStructClass(Class node) {
    if (node.typeParameters.length > 0) {
      diagnosticReporter.report(
          templateFfiStructGeneric.withArguments(node.name),
          node.fileOffset,
          1,
          node.location.file);
    }

    if (node.supertype?.classNode != structClass) {
      // Not a struct, but extends a struct. The error will be emitted by
      // _FfiUseSiteTransformer.
      return;
    }
  }

  bool _isPointerType(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    return env.isSubtypeOf(
        type,
        InterfaceType(pointerClass, Nullability.legacy, [
          InterfaceType(nativeTypesClasses[NativeType.kNativeType.index],
              Nullability.legacy)
        ]),
        SubtypeCheckMode.ignoringNullabilities);
  }

  bool _isStructSubtype(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    return env.isSubtypeOf(type, InterfaceType(structClass, Nullability.legacy),
        SubtypeCheckMode.ignoringNullabilities);
  }

  /// Returns members of [node] that correspond to struct fields.
  ///
  /// Note that getters and setters that originate from an external field have
  /// the same `fileOffset`, we always returns getters first.
  List<Member> _structFieldMembers(Class node) {
    final externalGetterSetters = [...node.procedures]
      ..retainWhere((p) => p.isExternal && (p.isGetter || p.isSetter));
    final structMembers = [...node.fields, ...externalGetterSetters]
      ..sort((m1, m2) {
        if (m1.fileOffset == m2.fileOffset) {
          // Getter and setter have same offset, getter comes first.
          return (m1 as Procedure).isGetter ? -1 : 1;
        }
        return m1.fileOffset - m2.fileOffset;
      });
    return structMembers;
  }

  DartType _structFieldMemberType(Member member) {
    if (member is Field) {
      return member.type;
    }
    final Procedure p = member;
    if (p.isGetter) {
      return p.function.returnType;
    }
    return p.function.positionalParameters.single.type;
  }

  bool _checkFieldAnnotations(Class node) {
    bool success = true;
    structClassDependencies[node] = {};
    final membersWithAnnotations = _structFieldMembers(node)
      ..retainWhere((m) => (m is Field) || (m is Procedure && m.isGetter));
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
      final type = _structFieldMemberType(f);
      if (_isPointerType(type) || _isStructSubtype(type)) {
        if (nativeTypeAnnos.length != 0) {
          diagnosticReporter.report(
              templateFfiFieldNoAnnotation.withArguments(f.name.text),
              f.fileOffset,
              f.name.text.length,
              f.fileUri);
          // This class is invalid, but continue reporting other errors on it.
          success = false;
        }
        if (_isStructSubtype(type)) {
          final clazz = (type as InterfaceType).classNode;
          structClassDependencies[node].add(clazz);
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
            nativeTypesClasses[_getFieldType(nativeTypeAnnos.first).index],
            Nullability.legacy);
        final DartType shouldBeDartType = convertNativeTypeToDartType(
            nativeType,
            allowStructs: true,
            allowHandle: false);
        if (shouldBeDartType == null ||
            !env.isSubtypeOf(type, shouldBeDartType,
                SubtypeCheckMode.ignoringNullabilities)) {
          diagnosticReporter.report(
              templateFfiTypeMismatch.withArguments(type, shouldBeDartType,
                  nativeType, node.enclosingLibrary.isNonNullableByDefault),
              f.fileOffset,
              1,
              f.location.file);
          // This class is invalid, but continue reporting other errors on it.
          success = false;
        }
      }
    }
    return success;
  }

  void _checkConstructors(Class node, IndexedClass indexedClass) {
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
              i.location.file);
        }
      }
    }
    // Remove initializers referring to fields to prevent cascading errors.
    for (final Initializer i in toRemove) {
      i.remove();
    }

    // Add a constructor which 'load' can use.
    // C.#fromTypedDataBase(Object address) : super.fromPointer(address);
    final VariableDeclaration pointer = new VariableDeclaration("#pointer");
    final name = Name("#fromTypedDataBase");
    final referenceFrom = indexedClass?.lookupConstructor(name);
    final Constructor ctor = Constructor(
        FunctionNode(EmptyStatement(), positionalParameters: [pointer]),
        name: name,
        initializers: [
          SuperInitializer(structFromPointer, Arguments([VariableGet(pointer)]))
        ],
        fileUri: node.fileUri,
        reference: referenceFrom?.reference)
      ..fileOffset = node.fileOffset
      ..isNonNullableByDefault = node.enclosingLibrary.isNonNullableByDefault;
    _makeEntryPoint(ctor);
    node.addConstructor(ctor);
  }

  /// Computes the field offsets (for all ABIs) in the struct and replaces the
  /// fields with getters and setters using these offsets.
  ///
  /// Returns the total size of the struct (for all ABIs).
  Map<Abi, int> _replaceFields(Class node, IndexedClass indexedClass) {
    final types = <NativeTypeCfe>[];
    final fields = <int, Field>{};
    final getters = <int, Procedure>{};
    final setters = <int, Procedure>{};

    int i = 0;
    for (final Member m in _structFieldMembers(node)) {
      final dartType = _structFieldMemberType(m);

      NativeTypeCfe type;
      if (_isPointerType(dartType)) {
        type = PointerNativeTypeCfe();
      } else if (_isStructSubtype(dartType)) {
        final clazz = (dartType as InterfaceType).classNode;
        type = structCache[clazz];
        if (emptyStructs.contains(clazz)) {
          diagnosticReporter.report(
              templateFfiEmptyStruct.withArguments(clazz.name),
              m.fileOffset,
              1,
              m.location.file);
        }
      } else {
        final nativeTypeAnnos = _getNativeTypeAnnotations(m).toList();
        if (nativeTypeAnnos.length == 1) {
          final clazz = nativeTypeAnnos.first;
          final nativeType = _getFieldType(clazz);
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
        if (getters.containsKey(index)) {
          setters[i - 1] = m;
        }
      }
    }

    _annoteStructWithFields(node, types);
    if (types.isEmpty) {
      diagnosticReporter.report(templateFfiEmptyStruct.withArguments(node.name),
          node.fileOffset, node.name.length, node.location.file);
      emptyStructs.add(node);
    }

    final structType = StructNativeTypeCfe(node, types);
    structCache[node] = structType;
    final structLayout = structType.layout;

    for (final i in fields.keys) {
      final fieldOffsets = structLayout
          .map((Abi abi, StructLayout v) => MapEntry(abi, v.offsets[i]));
      final methods = _generateMethodsForField(
          fields[i], types[i], fieldOffsets, indexedClass);
      methods.forEach((p) => node.addProcedure(p));
    }

    for (final Field f in fields.values) {
      f.remove();
    }

    for (final i in getters.keys) {
      final fieldOffsets = structLayout
          .map((Abi abi, StructLayout v) => MapEntry(abi, v.offsets[i]));
      Procedure getter = getters[i];
      getter.function.body = types[i].generateGetterStatement(
          getter.function.returnType, getter.fileOffset, fieldOffsets, this);
      getter.isExternal = false;
    }

    for (final i in setters.keys) {
      final fieldOffsets = structLayout
          .map((Abi abi, StructLayout v) => MapEntry(abi, v.offsets[i]));
      Procedure setter = setters[i];
      setter.function.body = types[i].generateSetterStatement(
          setter.function.positionalParameters.single.type,
          setter.fileOffset,
          fieldOffsets,
          setter.function.positionalParameters.single,
          this);
      setter.isExternal = false;
    }

    return structLayout.map((k, v) => MapEntry(k, v.size));
  }

  void _annoteStructWithFields(Class node, List<NativeTypeCfe> types) {
    List<Constant> constants =
        types.map((t) => t.generateConstant(this)).toList();

    node.addAnnotation(ConstantExpression(
        InstanceConstant(pragmaClass.reference, [], {
          pragmaName.getterReference: StringConstant("vm:ffi:struct-fields"),
          pragmaOptions.getterReference:
              InstanceConstant(ffiStructLayoutClass.reference, [], {
            ffiStructLayoutTypesField.getterReference: ListConstant(
                InterfaceType(typeClass, Nullability.nonNullable), constants)
          })
        }),
        InterfaceType(pragmaClass, Nullability.nonNullable, [])));
  }

  List<Procedure> _generateMethodsForField(Field field, NativeTypeCfe type,
      Map<Abi, int> offsets, IndexedClass indexedClass) {
    final getterStatement = type.generateGetterStatement(
        field.type, field.fileOffset, offsets, this);
    final Procedure getter = Procedure(field.name, ProcedureKind.Getter,
        FunctionNode(getterStatement, returnType: field.type),
        fileUri: field.fileUri,
        reference: indexedClass?.lookupGetterReference(field.name))
      ..fileOffset = field.fileOffset
      ..isNonNullableByDefault = field.isNonNullableByDefault;

    Procedure setter = null;
    if (!field.isFinal) {
      final VariableDeclaration argument =
          VariableDeclaration('#v', type: field.type)
            ..fileOffset = field.fileOffset;
      final setterStatement = type.generateSetterStatement(
          field.type, field.fileOffset, offsets, argument, this);
      setter = Procedure(
          field.name,
          ProcedureKind.Setter,
          FunctionNode(setterStatement,
              returnType: VoidType(), positionalParameters: [argument]),
          fileUri: field.fileUri,
          reference: indexedClass?.lookupSetterReference(field.name))
        ..fileOffset = field.fileOffset
        ..isNonNullableByDefault = field.isNonNullableByDefault;
    }

    replacedGetters[field] = getter;
    replacedSetters[field] = setter;

    return [getter, if (setter != null) setter];
  }

  /// Sample output:
  /// int #sizeOf => [24,24,16][_abi()];
  void _replaceSizeOfMethod(
      Class struct, Map<Abi, int> sizes, IndexedClass indexedClass) {
    var name = Name("#sizeOf");
    var getterReference = indexedClass?.lookupGetterReference(name);
    final Field sizeOf = Field.immutable(name,
        isStatic: true,
        isFinal: true,
        initializer: runtimeBranchOnLayout(sizes),
        type: InterfaceType(intClass, Nullability.legacy),
        fileUri: struct.fileUri,
        getterReference: getterReference)
      ..fileOffset = struct.fileOffset;
    _makeEntryPoint(sizeOf);
    struct.addField(sizeOf);
  }

  void _makeEntryPoint(Annotatable node) {
    node.addAnnotation(ConstantExpression(
        InstanceConstant(pragmaClass.reference, [], {
          pragmaName.getterReference: StringConstant("vm:entry-point"),
          pragmaOptions.getterReference: NullConstant()
        }),
        InterfaceType(pragmaClass, Nullability.legacy, [])));
  }

  NativeType _getFieldType(Class c) {
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
}

/// The layout of a `Struct` in one [Abi].
class StructLayout {
  /// Size of the entire struct.
  final int size;

  /// Alignment of struct when nested in other struct.
  final int alignment;

  /// Offset in bytes for each field, indexed by field number.
  final List<int> offsets;

  StructLayout(this.size, this.alignment, this.offsets);
}

/// AST node wrapper for native types.
///
/// This algebraic data structure does not stand on its own but refers
/// intimately to AST nodes such as [Class].
abstract class NativeTypeCfe {
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

  /// Generates the return statement for a struct field getter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, FfiTransformer transformer);

  /// Generates the return statement for a struct field setter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateSetterStatement(
      DartType dartType,
      int fileOffset,
      Map<Abi, int> offsets,
      VariableDeclaration argument,
      FfiTransformer transformer);
}

class PrimitiveNativeTypeCfe implements NativeTypeCfe {
  final NativeType nativeType;

  final Class clazz;

  PrimitiveNativeTypeCfe(this.nativeType, this.clazz);

  @override
  Map<Abi, int> get size {
    final int size = nativeTypeSizes[nativeType.index];
    if (size == WORD_SIZE) {
      return wordSize;
    }
    return Map.fromEntries(Abi.values.map((abi) => MapEntry(abi, size)));
  }

  @override
  Map<Abi, int> get alignment => Map.fromEntries(Abi.values.map(
      (abi) => MapEntry(abi, nonSizeAlignment[abi][nativeType] ?? size[abi])));

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));

  /// Sample output for `int get x =>`:
  ///
  /// ```
  /// _loadInt8(_addressOf, offset);
  /// ```
  @override
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
          Map<Abi, int> offsets, FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.loadMethods[nativeType],
          Arguments([
            PropertyGet(ThisExpression(), transformer.addressOfField.name,
                transformer.addressOfField)
              ..fileOffset = fileOffset,
            transformer.runtimeBranchOnLayout(offsets)
          ]))
        ..fileOffset = fileOffset);

  /// Sample output for `set x(int #v) =>`:
  ///
  /// ```
  /// _storeInt8(_addressOf, offset, #v);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.storeMethods[nativeType],
          Arguments([
            PropertyGet(ThisExpression(), transformer.addressOfField.name,
                transformer.addressOfField)
              ..fileOffset = fileOffset,
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
            transformer.pointerClass.superclass, Nullability.nonNullable)
      ]));

  /// Sample output for `Pointer<Int8> get x =>`:
  ///
  /// ```
  /// _fromAddress<Int8>(_loadIntPtr(_addressOf, offset));
  /// ```
  @override
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
          Map<Abi, int> offsets, FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.fromAddressInternal,
          Arguments([
            StaticInvocation(
                transformer.loadMethods[NativeType.kIntptr],
                Arguments([
                  PropertyGet(ThisExpression(), transformer.addressOfField.name,
                      transformer.addressOfField)
                    ..fileOffset = fileOffset,
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
  /// _storeIntPtr(_addressOf, offset, (#v as Pointer<Int8>).address);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.storeMethods[NativeType.kIntptr],
          Arguments([
            PropertyGet(ThisExpression(), transformer.addressOfField.name,
                transformer.addressOfField)
              ..fileOffset = fileOffset,
            transformer.runtimeBranchOnLayout(offsets),
            PropertyGet(VariableGet(argument), transformer.addressGetter.name,
                transformer.addressGetter)
              ..fileOffset = fileOffset
          ]))
        ..fileOffset = fileOffset);
}

class StructNativeTypeCfe implements NativeTypeCfe {
  final Class clazz;

  final List<NativeTypeCfe> members;

  final Map<Abi, StructLayout> layout;

  factory StructNativeTypeCfe(Class clazz, List<NativeTypeCfe> members) {
    final layout = Map.fromEntries(
        Abi.values.map((abi) => MapEntry(abi, _calculateLayout(members, abi))));
    return StructNativeTypeCfe._(clazz, members, layout);
  }

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeCompoundType::FromNativeTypes.
  static StructLayout _calculateLayout(List<NativeTypeCfe> types, Abi abi) {
    int offset = 0;
    final offsets = <int>[];
    int structAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int size = types[i].size[abi];
      final int alignment = types[i].alignment[abi];
      offset = _alignOffset(offset, alignment);
      offsets.add(offset);
      offset += size;
      structAlignment = math.max(structAlignment, alignment);
    }
    final int size = _alignOffset(offset, structAlignment);
    return StructLayout(size, structAlignment, offsets);
  }

  StructNativeTypeCfe._(this.clazz, this.members, this.layout);

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
  ///   typedDataBaseOffset(_addressOf, offset, size, dartType)
  /// );
  /// ```
  @override
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, FfiTransformer transformer) {
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));

    return ReturnStatement(ConstructorInvocation(
        constructor,
        Arguments([
          transformer.typedDataBaseOffset(
              PropertyGet(ThisExpression(), transformer.addressOfField.name,
                  transformer.addressOfField)
                ..fileOffset = fileOffset,
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
  /// _memCopy(_addressOf, offset, #v._addressOf, 0, size);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.memCopy,
          Arguments([
            PropertyGet(ThisExpression(), transformer.addressOfField.name,
                transformer.addressOfField)
              ..fileOffset = fileOffset,
            transformer.runtimeBranchOnLayout(offsets),
            PropertyGet(VariableGet(argument), transformer.addressOfField.name,
                transformer.addressOfField)
              ..fileOffset = fileOffset,
            ConstantExpression(IntConstant(0)),
            transformer.runtimeBranchOnLayout(size),
          ]))
        ..fileOffset = fileOffset);
}

int _alignOffset(int offset, int alignment) =>
    ((offset + alignment - 1) ~/ alignment) * alignment;
