// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.ffi_definitions;

import 'dart:math' as math;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        templateFfiFieldAnnotation,
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
///   Coord.#fromPointer(Pointer<Coord> coord) : super._(coord);
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
ReplacedMembers transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex referenceFromIndex,
    ChangedStructureNotifier changedStructureNotifier) {
  final LibraryIndex index =
      LibraryIndex(component, const ["dart:ffi", "dart:core"]);
  if (!index.containsLibrary("dart:ffi")) {
    // TODO: This check doesn't make sense: "dart:ffi" is always loaded/created
    // for the VM target.
    // If dart:ffi is not loaded, do not do the transformation.
    return ReplacedMembers({}, {});
  }
  if (index.tryGetClass('dart:ffi', 'NativeFunction') == null) {
    // If dart:ffi is not loaded (for real): do not do the transformation.
    return ReplacedMembers({}, {});
  }
  final transformer = new _FfiDefinitionTransformer(index, coreTypes, hierarchy,
      diagnosticReporter, referenceFromIndex, changedStructureNotifier);
  libraries.forEach(transformer.visitLibrary);
  return ReplacedMembers(
      transformer.replacedGetters, transformer.replacedSetters);
}

/// Checks and elaborates the dart:ffi structs and fields.
class _FfiDefinitionTransformer extends FfiTransformer {
  final LibraryIndex index;

  Map<Field, Procedure> replacedGetters = {};
  Map<Field, Procedure> replacedSetters = {};

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

    var indexedClass = currentLibraryIndex?.lookupIndexedClass(node.name);
    _checkConstructors(node, indexedClass);
    final bool fieldsValid = _checkFieldAnnotations(node);

    if (fieldsValid) {
      final structSize = _replaceFields(node, indexedClass);
      _replaceSizeOfMethod(node, structSize, indexedClass);
      changedStructureNotifier?.registerClassMemberChange(node);
    }

    return node;
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
    final membersWithAnnotations = _structFieldMembers(node)
      ..retainWhere((m) => (m is Field) || (m is Procedure && m.isGetter));
    for (final Member f in membersWithAnnotations) {
      if (f is Field) {
        if (f.initializer is! NullLiteral) {
          diagnosticReporter.report(
              templateFfiFieldInitializer.withArguments(f.name.name),
              f.fileOffset,
              f.name.name.length,
              f.fileUri);
        }
      }
      final nativeTypeAnnos = _getNativeTypeAnnotations(f).toList();
      final type = _structFieldMemberType(f);
      if (_isPointerType(type)) {
        if (nativeTypeAnnos.length != 0) {
          diagnosticReporter.report(
              templateFfiFieldNoAnnotation.withArguments(f.name.name),
              f.fileOffset,
              f.name.name.length,
              f.fileUri);
        }
      } else if (nativeTypeAnnos.length != 1) {
        diagnosticReporter.report(
            templateFfiFieldAnnotation.withArguments(f.name.name),
            f.fileOffset,
            f.name.name.length,
            f.fileUri);
      } else {
        final DartType nativeType = InterfaceType(
            nativeTypesClasses[nativeTypeAnnos.first.index],
            Nullability.legacy);
        // TODO(36730): Support structs inside structs.
        final DartType shouldBeDartType = convertNativeTypeToDartType(
            nativeType, /*allowStructs=*/ false, /*allowHandle=*/ false);
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
              templateFfiFieldInitializer.withArguments(i.field.name.name),
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
    // C.#fromPointer(Pointer<Void> address) : super.fromPointer(address);
    final VariableDeclaration pointer = new VariableDeclaration("#pointer");
    final name = Name("#fromPointer");
    final referenceFrom = indexedClass?.lookupConstructor(name.name);
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
    node.addMember(ctor);
  }

  /// Computes the field offsets (for all ABIs) in the struct and replaces the
  /// fields with getters and setters using these offsets.
  ///
  /// Returns the total size of the struct (for all ABIs).
  Map<Abi, int> _replaceFields(Class node, IndexedClass indexedClass) {
    final types = <NativeType>[];
    final fields = <int, Field>{};
    final getters = <int, Procedure>{};
    final setters = <int, Procedure>{};

    int i = 0;
    for (final Member m in _structFieldMembers(node)) {
      final dartType = _structFieldMemberType(m);

      NativeType nativeType;
      if (_isPointerType(dartType)) {
        nativeType = NativeType.kPointer;
      } else {
        final nativeTypeAnnos = _getNativeTypeAnnotations(m).toList();
        if (nativeTypeAnnos.length == 1) {
          nativeType = nativeTypeAnnos.first;
        }
      }

      if ((m is Field || (m is Procedure && m.isGetter)) &&
          nativeType != null) {
        types.add(nativeType);
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

    final sizeAndOffsets = <Abi, SizeAndOffsets>{};
    for (final Abi abi in Abi.values) {
      sizeAndOffsets[abi] = _calculateSizeAndOffsets(types, abi);
    }

    for (final i in fields.keys) {
      final fieldOffsets = sizeAndOffsets
          .map((Abi abi, SizeAndOffsets v) => MapEntry(abi, v.offsets[i]));
      final methods = _generateMethodsForField(
          fields[i], types[i], fieldOffsets, indexedClass);
      methods.forEach((p) => node.addMember(p));
    }

    for (final Field f in fields.values) {
      f.remove();
    }

    for (final i in getters.keys) {
      final fieldOffsets = sizeAndOffsets
          .map((Abi abi, SizeAndOffsets v) => MapEntry(abi, v.offsets[i]));
      Procedure getter = getters[i];
      getter.function.body = _generateGetterStatement(
          getter.function.returnType,
          types[i],
          getter.fileOffset,
          fieldOffsets);
      getter.isExternal = false;
    }

    for (final i in setters.keys) {
      final fieldOffsets = sizeAndOffsets
          .map((Abi abi, SizeAndOffsets v) => MapEntry(abi, v.offsets[i]));
      Procedure setter = setters[i];
      setter.function.body = _generateSetterStatement(
          setter.function.positionalParameters.single.type,
          types[i],
          setter.fileOffset,
          fieldOffsets,
          setter.function.positionalParameters.single);
      setter.isExternal = false;
    }

    return sizeAndOffsets.map((k, v) => MapEntry(k, v.size));
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

    // Sample output:
    // int get x => _loadInt8(pointer, offset);
    //
    // Treat Pointer fields different to get correct behavior without casts:
    // Pointer<Int8> get x =>
    //   _fromAddress<Int8>(_loadIntPtr(pointer, offset));
    final loadMethod = isPointer
        ? loadMethods[NativeType.kIntptr]
        : optimizedTypes.contains(type) ? loadMethods[type] : loadStructMethod;
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

    // Sample output:
    // set x(int v) => _storeInt8(pointer, offset, v);
    //
    // Treat Pointer fields different to get correct behavior without casts:
    // set x(Pointer<Int8> v) =>
    //   _storeIntPtr(pointer, offset, (v as Pointer<Int8>).address);
    final storeMethod =
        isPointer ? storeMethods[NativeType.kIntptr] : storeMethods[type];
    Expression argumentExpression = VariableGet(argument)
      ..fileOffset = fileOffset;
    if (isPointer) {
      argumentExpression = DirectPropertyGet(argumentExpression, addressGetter)
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
            indexedClass?.lookupProcedureNotSetter(field.name.name)?.reference)
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
              indexedClass?.lookupProcedureSetter(field.name.name)?.reference)
        ..fileOffset = field.fileOffset
        ..isNonNullableByDefault = field.isNonNullableByDefault;
    }

    replacedGetters[field] = getter;
    replacedSetters[field] = setter;

    return [getter, if (setter != null) setter];
  }

  /// Sample output:
  /// static int #sizeOf() => 24;
  void _replaceSizeOfMethod(
      Class struct, Map<Abi, int> sizes, IndexedClass indexedClass) {
    var name = Name("#sizeOf");
    final Field sizeOf = Field(name,
        isStatic: true,
        isFinal: true,
        initializer: _runtimeBranchOnLayout(sizes),
        type: InterfaceType(intClass, Nullability.legacy),
        fileUri: struct.fileUri,
        reference: indexedClass?.lookupField(name.name)?.reference)
      ..fileOffset = struct.fileOffset;
    _makeEntryPoint(sizeOf);
    struct.addMember(sizeOf);
  }

  int _sizeInBytes(NativeType type, Abi abi) {
    final int size = nativeTypeSizes[type.index];
    if (size == WORD_SIZE) {
      return wordSize[abi];
    }
    return size;
  }

  int _alignmentOf(NativeType type, Abi abi) {
    final int alignment = nonSizeAlignment[abi][type];
    if (alignment != null) return alignment;
    return _sizeInBytes(type, abi);
  }

  int _alignOffset(int offset, int alignment) {
    final int remainder = offset % alignment;
    if (remainder != 0) {
      offset -= remainder;
      offset += alignment;
    }
    return offset;
  }

  // TODO(37271): Support nested structs.
  SizeAndOffsets _calculateSizeAndOffsets(List<NativeType> types, Abi abi) {
    int offset = 0;
    final offsets = <int>[];
    for (final NativeType t in types) {
      final int size = _sizeInBytes(t, abi);
      final int alignment = _alignmentOf(t, abi);
      offset = _alignOffset(offset, alignment);
      offsets.add(offset);
      offset += size;
    }
    final int minimumAlignment = 1;
    final sizeAlignment = types
        .map((t) => _alignmentOf(t, abi))
        .followedBy([minimumAlignment]).reduce(math.max);
    final int size = _alignOffset(offset, sizeAlignment);
    return SizeAndOffsets(size, offsets);
  }

  void _makeEntryPoint(Annotatable node) {
    node.addAnnotation(ConstantExpression(
        InstanceConstant(pragmaClass.reference, [], {
          pragmaName.reference: StringConstant("vm:entry-point"),
          pragmaOptions.reference: NullConstant()
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

  Iterable<NativeType> _getNativeTypeAnnotations(Member node) {
    return node.annotations
        .whereType<ConstantExpression>()
        .map((expr) => expr.constant)
        .whereType<InstanceConstant>()
        .map((constant) => constant.classNode)
        .map((klass) => _getFieldType(klass))
        .where((type) => type != null);
  }
}

class SizeAndOffsets {
  /// Size of the entire struct.
  final int size;

  /// Offset in bytes for each field, indexed by field number.
  final List<int> offsets;

  SizeAndOffsets(this.size, this.offsets);
}
