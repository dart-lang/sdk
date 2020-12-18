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
  Map<Class, Map<Abi, StructLayout>> structLayouts = {};

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
      }
    });

    final structClassesSorted = connectedComponents.expand((i) => i).toList();

    structClassesSorted.forEach(visitClassInTopologicalOrder);
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
    return env.isSubtypeOf(
        type,
        InterfaceType(pointerClass, Nullability.legacy, [
          InterfaceType(nativeTypesClasses[NativeType.kNativeType.index],
              Nullability.legacy)
        ]),
        SubtypeCheckMode.ignoringNullabilities);
  }

  bool _isStructSubtype(DartType type) {
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
    final referenceFrom = indexedClass?.lookupConstructor(name.text);
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
    final classes = <Class>[];
    final types = <NativeType>[];
    final fields = <int, Field>{};
    final getters = <int, Procedure>{};
    final setters = <int, Procedure>{};

    int i = 0;
    for (final Member m in _structFieldMembers(node)) {
      final dartType = _structFieldMemberType(m);

      NativeType nativeType;
      Class clazz;
      if (_isPointerType(dartType)) {
        nativeType = NativeType.kPointer;
        clazz = pointerClass;
      } else if (_isStructSubtype(dartType)) {
        nativeType = NativeType.kStruct;
        clazz = (dartType as InterfaceType).classNode;
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
          clazz = nativeTypeAnnos.first;
          nativeType = _getFieldType(clazz);
        }
      }

      if ((m is Field || (m is Procedure && m.isGetter)) &&
          nativeType != null) {
        types.add(nativeType);
        classes.add(clazz);
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

    _annoteStructWithFields(node, classes);
    if (classes.isEmpty) {
      emptyStructs.add(node);
    }

    final structLayout = <Abi, StructLayout>{};
    for (final Abi abi in Abi.values) {
      structLayout[abi] = _calculateStructLayout(types, classes, abi);
    }
    structLayouts[node] = structLayout;

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
      getter.function.body = _generateGetterStatement(
          getter.function.returnType,
          types[i],
          getter.fileOffset,
          fieldOffsets);
      getter.isExternal = false;
    }

    for (final i in setters.keys) {
      final fieldOffsets = structLayout
          .map((Abi abi, StructLayout v) => MapEntry(abi, v.offsets[i]));
      Procedure setter = setters[i];
      setter.function.body = _generateSetterStatement(
          setter.function.positionalParameters.single.type,
          types[i],
          setter.fileOffset,
          fieldOffsets,
          setter.function.positionalParameters.single);
      setter.isExternal = false;
    }

    return structLayout.map((k, v) => MapEntry(k, v.size));
  }

  void _annoteStructWithFields(Class node, List<Class> fieldTypes) {
    final types = fieldTypes.map((Class c) {
      List<DartType> typeArg = const [];
      if (c == pointerClass) {
        typeArg = [
          InterfaceType(pointerClass.superclass, Nullability.nonNullable)
        ];
      }
      return TypeLiteralConstant(
          InterfaceType(c, Nullability.nonNullable, typeArg));
    }).toList();

    node.addAnnotation(ConstantExpression(
        InstanceConstant(pragmaClass.reference, [], {
          pragmaName.getterReference: StringConstant("vm:ffi:struct-fields"),
          // TODO(dartbug.com/38158): Wrap list in class to be able to encode
          // more information when needed.
          pragmaOptions.getterReference: ListConstant(
              InterfaceType(typeClass, Nullability.nonNullable), types)
        }),
        InterfaceType(pragmaClass, Nullability.nonNullable, [])));
  }

  /// Expression that queries VM internals at runtime to figure out on which ABI
  /// we are.
  Expression _runtimeBranchOnLayout(Map<Abi, int> values) {
    return MethodInvocation(
        ConstantExpression(
            ListConstant(InterfaceType(intClass, Nullability.legacy), [
              IntConstant(values[Abi.wordSize64]),
              IntConstant(values[Abi.wordSize32Align32]),
              IntConstant(values[Abi.wordSize32Align64])
            ]),
            InterfaceType(listClass, Nullability.legacy,
                [InterfaceType(intClass, Nullability.legacy)])),
        Name("[]"),
        Arguments([StaticInvocation(abiMethod, Arguments([]))]),
        listElementAt);
  }

  Statement _generateGetterStatement(DartType dartType, NativeType type,
      int fileOffset, Map<Abi, int> offsets) {
    final bool isPointer = type == NativeType.kPointer;
    final bool isStruct = type == NativeType.kStruct;

    // Sample output:
    // int get x => _loadInt8(pointer, offset);
    //
    // Treat Pointer fields different to get correct behavior without casts:
    // Pointer<Int8> get x =>
    //   _fromAddress<Int8>(_loadIntPtr(pointer, offset));
    //
    // Nested structs:
    // MyStruct get x =>
    //   MyStruct.#fromTypedDataBase(
    //     _addressOf is Pointer ?
    //       _fromAddress<MyStruct>((_addressOf as Pointer).address + offset) :
    //       (_addressOf as TypedData).buffer.asInt8List(
    //         (_addressOf as TypedData).offsetInBytes + offset,
    //         size
    //       )
    //   );
    if (isStruct) {
      final clazz = (dartType as InterfaceType).classNode;
      final constructor = clazz.constructors
          .firstWhere((c) => c.name == Name("#fromTypedDataBase"));
      final lengths =
          structLayouts[clazz].map((key, value) => MapEntry(key, value.size));
      Expression thisDotAddressOf() =>
          PropertyGet(ThisExpression(), addressOfField.name, addressOfField)
            ..fileOffset = fileOffset;
      return ReturnStatement(ConstructorInvocation(
          constructor,
          Arguments([
            ConditionalExpression(
                IsExpression(thisDotAddressOf(),
                    InterfaceType(pointerClass, Nullability.legacy)),
                StaticInvocation(
                    fromAddressInternal,
                    Arguments([
                      MethodInvocation(
                          PropertyGet(thisDotAddressOf(), addressGetter.name,
                              addressGetter)
                            ..fileOffset = fileOffset,
                          numAddition.name,
                          Arguments([_runtimeBranchOnLayout(offsets)]),
                          numAddition)
                    ], types: [
                      dartType
                    ]))
                  ..fileOffset = fileOffset,
                MethodInvocation(
                    PropertyGet(
                        StaticInvocation(
                            unsafeCastMethod,
                            Arguments([
                              thisDotAddressOf()
                            ], types: [
                              InterfaceType(typedDataClass, Nullability.legacy)
                            ]))
                          ..fileOffset = fileOffset,
                        typedDataBufferGetter.name,
                        typedDataBufferGetter)
                      ..fileOffset = fileOffset,
                    byteBufferAsUint8List.name,
                    Arguments([
                      MethodInvocation(
                          PropertyGet(
                              StaticInvocation(
                                  unsafeCastMethod,
                                  Arguments([
                                    thisDotAddressOf()
                                  ], types: [
                                    InterfaceType(
                                        typedDataClass, Nullability.legacy)
                                  ]))
                                ..fileOffset = fileOffset,
                              typedDataOffsetInBytesGetter.name,
                              typedDataOffsetInBytesGetter)
                            ..fileOffset = fileOffset,
                          numAddition.name,
                          Arguments([_runtimeBranchOnLayout(offsets)]),
                          numAddition),
                      _runtimeBranchOnLayout(lengths)
                    ]),
                    byteBufferAsUint8List),
                InterfaceType(objectClass, Nullability.nonNullable))
          ]))
        ..fileOffset = fileOffset);
    }
    final loadMethod =
        isPointer ? loadMethods[NativeType.kIntptr] : loadMethods[type];
    Expression getterReturnValue = StaticInvocation(
        loadMethod,
        Arguments([
          PropertyGet(ThisExpression(), addressOfField.name, addressOfField)
            ..fileOffset = fileOffset,
          _runtimeBranchOnLayout(offsets)
        ]))
      ..fileOffset = fileOffset;
    if (isPointer) {
      final typeArg = (dartType as InterfaceType).typeArguments.single;
      getterReturnValue = StaticInvocation(
          fromAddressInternal, Arguments([getterReturnValue], types: [typeArg]))
        ..fileOffset = fileOffset;
    }
    return ReturnStatement(getterReturnValue);
  }

  Statement _generateSetterStatement(DartType dartType, NativeType type,
      int fileOffset, Map<Abi, int> offsets, VariableDeclaration argument) {
    final bool isPointer = type == NativeType.kPointer;
    final bool isStruct = type == NativeType.kStruct;

    // Sample output:
    // set x(int v) => _storeInt8(pointer, offset, v);
    //
    // Treat Pointer fields different to get correct behavior without casts:
    // set x(Pointer<Int8> v) =>
    //   _storeIntPtr(pointer, offset, (v as Pointer<Int8>).address);
    //
    // Nested structs:
    // set x(MyStruct v) =>
    //   _memCopy(this._address, offset, v._address, 0, size);
    if (isStruct) {
      final clazz = (dartType as InterfaceType).classNode;
      final lengths =
          structLayouts[clazz].map((key, value) => MapEntry(key, value.size));
      return ReturnStatement(StaticInvocation(
          memCopy,
          Arguments([
            PropertyGet(ThisExpression(), addressOfField.name, addressOfField)
              ..fileOffset = fileOffset,
            _runtimeBranchOnLayout(offsets),
            PropertyGet(
                VariableGet(argument), addressOfField.name, addressOfField)
              ..fileOffset = fileOffset,
            ConstantExpression(IntConstant(0)),
            _runtimeBranchOnLayout(lengths),
          ]))
        ..fileOffset = fileOffset);
    }
    final storeMethod =
        isPointer ? storeMethods[NativeType.kIntptr] : storeMethods[type];
    Expression argumentExpression = VariableGet(argument)
      ..fileOffset = fileOffset;
    if (isPointer) {
      argumentExpression =
          PropertyGet(argumentExpression, addressGetter.name, addressGetter)
            ..fileOffset = fileOffset;
    }
    return ReturnStatement(StaticInvocation(
        storeMethod,
        Arguments([
          PropertyGet(ThisExpression(), addressOfField.name, addressOfField)
            ..fileOffset = fileOffset,
          _runtimeBranchOnLayout(offsets),
          argumentExpression
        ]))
      ..fileOffset = fileOffset);
  }

  List<Procedure> _generateMethodsForField(Field field, NativeType type,
      Map<Abi, int> offsets, IndexedClass indexedClass) {
    final getterStatement =
        _generateGetterStatement(field.type, type, field.fileOffset, offsets);
    final Procedure getter = Procedure(field.name, ProcedureKind.Getter,
        FunctionNode(getterStatement, returnType: field.type),
        fileUri: field.fileUri,
        reference:
            indexedClass?.lookupProcedureNotSetter(field.name.text)?.reference)
      ..fileOffset = field.fileOffset
      ..isNonNullableByDefault = field.isNonNullableByDefault;

    Procedure setter = null;
    if (!field.isFinal) {
      final VariableDeclaration argument =
          VariableDeclaration('#v', type: field.type)
            ..fileOffset = field.fileOffset;
      final setterStatement = _generateSetterStatement(
          field.type, type, field.fileOffset, offsets, argument);
      setter = Procedure(
          field.name,
          ProcedureKind.Setter,
          FunctionNode(setterStatement,
              returnType: VoidType(), positionalParameters: [argument]),
          fileUri: field.fileUri,
          reference:
              indexedClass?.lookupProcedureSetter(field.name.text)?.reference)
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
    var lookupField = indexedClass?.lookupField(name.text);
    final Field sizeOf = Field(name,
        isStatic: true,
        isFinal: true,
        initializer: _runtimeBranchOnLayout(sizes),
        type: InterfaceType(intClass, Nullability.legacy),
        fileUri: struct.fileUri,
        getterReference: lookupField?.getterReference,
        setterReference: lookupField?.setterReference)
      ..fileOffset = struct.fileOffset;
    _makeEntryPoint(sizeOf);
    struct.addField(sizeOf);
  }

  int _sizeInBytes(NativeType type, Class clazz, Abi abi) {
    if (type == NativeType.kStruct) {
      final structLayout = structLayouts[clazz];
      if (structLayout == null) {
        // We have a cycle, so we don't know the size.
        return 0;
      }
      return structLayout[abi].size;
    }
    final int size = nativeTypeSizes[type.index];
    if (size == WORD_SIZE) {
      return wordSize[abi];
    }
    return size;
  }

  int _alignmentOf(NativeType type, Class clazz, Abi abi) {
    if (type == NativeType.kStruct) {
      final structLayout = structLayouts[clazz];
      if (structLayout == null) {
        // We have a cycle, so we don't know the size.
        return 0;
      }
      return structLayout[abi].alignment;
    }
    final int alignment = nonSizeAlignment[abi][type];
    if (alignment != null) return alignment;
    return _sizeInBytes(type, clazz, abi);
  }

  int _alignOffset(int offset, int alignment) {
    final int remainder = offset % alignment;
    if (remainder != 0) {
      offset -= remainder;
      offset += alignment;
    }
    return offset;
  }

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeCompoundType::FromNativeTypes.
  StructLayout _calculateStructLayout(
      List<NativeType> types, List<Class> classes, Abi abi) {
    int offset = 0;
    final offsets = <int>[];
    int structAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int size = _sizeInBytes(types[i], classes[i], abi);
      final int alignment = _alignmentOf(types[i], classes[i], abi);
      offset = _alignOffset(offset, alignment);
      offsets.add(offset);
      offset += size;
      structAlignment = math.max(structAlignment, alignment);
    }
    final int size = _alignOffset(offset, structAlignment);
    return StructLayout(size, structAlignment, offsets);
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
