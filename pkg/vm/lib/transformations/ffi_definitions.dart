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
        templateFfiStructGeneric,
        templateFfiWrongStructInheritance;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;

import 'ffi.dart';

/// Checks and elaborates the dart:ffi structs and fields.
///
/// Input:
/// class Coord extends Struct<Coord> {
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
/// class Coord extends Struct<Coord> {
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
    DiagnosticReporter diagnosticReporter) {
  final LibraryIndex index =
      LibraryIndex(component, const ["dart:ffi", "dart:core"]);
  if (!index.containsLibrary("dart:ffi")) {
    // If dart:ffi is not loaded, do not do the transformation.
    return ReplacedMembers({}, {});
  }
  final transformer = new _FfiDefinitionTransformer(
      index, coreTypes, hierarchy, diagnosticReporter);
  libraries.forEach(transformer.visitLibrary);
  return ReplacedMembers(
      transformer.replacedGetters, transformer.replacedSetters);
}

/// Checks and elaborates the dart:ffi structs and fields.
class _FfiDefinitionTransformer extends FfiTransformer {
  final LibraryIndex index;

  Map<Field, Procedure> replacedGetters = {};
  Map<Field, Procedure> replacedSetters = {};

  _FfiDefinitionTransformer(this.index, CoreTypes coreTypes,
      ClassHierarchy hierarchy, DiagnosticReporter diagnosticReporter)
      : super(index, coreTypes, hierarchy, diagnosticReporter) {}

  @override
  visitClass(Class node) {
    if (!hierarchy.isSubclassOf(node, structClass) || node == structClass) {
      return node;
    }

    _checkStructClass(node);

    // Struct objects are manufactured in the VM by 'allocate' and 'load'.
    _makeEntryPoint(node);

    _checkConstructors(node);
    final bool fieldsValid = _checkFieldAnnotations(node);

    if (fieldsValid) {
      final structSize = _replaceFields(node);
      _replaceSizeOfMethod(node, structSize);
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

    // A struct classes "C" must extend "Struct<C>".
    DartType structTypeArg = node.supertype.typeArguments[0];
    if (structTypeArg != InterfaceType(node)) {
      diagnosticReporter.report(
          templateFfiWrongStructInheritance.withArguments(node.name),
          node.fileOffset,
          1,
          node.location.file);
    }
  }

  bool _isPointerType(Field field) {
    return env.isSubtypeOf(
        field.type,
        InterfaceType(pointerClass,
            [InterfaceType(nativeTypesClasses[NativeType.kNativeType.index])]));
  }

  bool _checkFieldAnnotations(Class node) {
    bool success = true;
    for (Field f in node.fields) {
      if (f.initializer is! NullLiteral) {
        diagnosticReporter.report(
            templateFfiFieldInitializer.withArguments(f.name.name),
            f.fileOffset,
            f.name.name.length,
            f.fileUri);
      }
      final nativeTypeAnnos = _getNativeTypeAnnotations(f).toList();
      if (_isPointerType(f)) {
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
        final DartType dartType = f.type;
        final DartType nativeType =
            InterfaceType(nativeTypesClasses[nativeTypeAnnos.first.index]);
        // TODO(36730): Support structs inside structs.
        final DartType shouldBeDartType =
            convertNativeTypeToDartType(nativeType, /*allowStructs=*/ false);
        if (shouldBeDartType == null ||
            !env.isSubtypeOf(dartType, shouldBeDartType)) {
          diagnosticReporter.report(
              templateFfiTypeMismatch.withArguments(
                  dartType, shouldBeDartType, nativeType),
              f.fileOffset,
              1,
              f.location.file);
          success = false;
        }
      }
    }
    return success;
  }

  void _checkConstructors(Class node) {
    final toRemove = <Initializer>[];

    // Constructors cannot have initializers because initializers refer to
    // fields, and the fields were replaced with getter/setter pairs.
    for (Constructor c in node.constructors) {
      for (Initializer i in c.initializers) {
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
    for (Initializer i in toRemove) {
      i.remove();
    }

    // Add a constructor which 'load' can use.
    // C.#fromPointer(Pointer<Void> address) : super.fromPointer(address);
    final VariableDeclaration pointer = new VariableDeclaration("#pointer");
    final Constructor ctor = Constructor(
        FunctionNode(EmptyStatement(), positionalParameters: [pointer]),
        name: Name("#fromPointer"),
        initializers: [
          SuperInitializer(structFromPointer, Arguments([VariableGet(pointer)]))
        ]);
    _makeEntryPoint(ctor);
    node.addMember(ctor);
  }

  /// Computes the field offsets (for all ABIs) in the struct and replaces the
  /// fields with getters and setters using these offsets.
  ///
  /// Returns the total size of the struct (for all ABIs).
  Map<Abi, int> _replaceFields(Class node) {
    final fields = <Field>[];
    final types = <NativeType>[];

    for (Field f in node.fields) {
      if (_isPointerType(f)) {
        fields.add(f);
        types.add(NativeType.kPointer);
      } else {
        final nativeTypeAnnos = _getNativeTypeAnnotations(f).toList();
        if (nativeTypeAnnos.length == 1) {
          NativeType t = nativeTypeAnnos.first;
          fields.add(f);
          types.add(t);
        }
      }
    }

    final sizeAndOffsets = <Abi, SizeAndOffsets>{};
    for (Abi abi in Abi.values) {
      sizeAndOffsets[abi] = _calculateSizeAndOffsets(types, abi);
    }

    for (int i = 0; i < fields.length; i++) {
      final fieldOffsets = sizeAndOffsets
          .map((Abi abi, SizeAndOffsets v) => MapEntry(abi, v.offsets[i]));
      final methods =
          _generateMethodsForField(fields[i], types[i], fieldOffsets);
      methods.forEach((p) => node.addMember(p));
    }

    for (Field f in fields) {
      f.remove();
    }

    return sizeAndOffsets.map((k, v) => MapEntry(k, v.size));
  }

  /// Expression that queries VM internals at runtime to figure out on which ABI
  /// we are.
  Expression _runtimeBranchOnLayout(Map<Abi, int> values) {
    return MethodInvocation(
        ConstantExpression(
            ListConstant(InterfaceType(intClass), [
              IntConstant(values[Abi.wordSize64]),
              IntConstant(values[Abi.wordSize32Align32]),
              IntConstant(values[Abi.wordSize32Align64])
            ]),
            InterfaceType(intClass)),
        Name("[]"),
        Arguments([StaticInvocation(abiMethod, Arguments([]))]),
        listElementAt);
  }

  /// Sample output:
  /// ffi.Pointer<ffi.Double> get _xPtr => addressOf.cast();
  /// double get x => _xPtr.load();
  /// set x(double v) => _xPtr.store(v);
  List<Procedure> _generateMethodsForField(
      Field field, NativeType type, Map<Abi, int> offsets) {
    final DartType nativeType = type == NativeType.kPointer
        ? field.type
        : InterfaceType(nativeTypesClasses[type.index]);
    final DartType pointerType = InterfaceType(pointerClass, [nativeType]);
    final Name pointerName = Name('#_ptr_${field.name.name}');

    // Sample output:
    // ffi.Pointer<ffi.Double> get _xPtr => addressOf.offsetBy(...).cast<ffi.Pointer<ffi.Double>>();
    Expression pointer =
        PropertyGet(ThisExpression(), addressOfField.name, addressOfField);
    final hasNonZero = offsets.values.skipWhile((i) => i == 0).isNotEmpty;
    if (hasNonZero) {
      pointer = MethodInvocation(pointer, offsetByMethod.name,
          Arguments([_runtimeBranchOnLayout(offsets)]), offsetByMethod);
    }
    final Procedure pointerGetter = Procedure(
        pointerName,
        ProcedureKind.Getter,
        FunctionNode(
            ReturnStatement(MethodInvocation(pointer, castMethod.name,
                Arguments([], types: [nativeType]), castMethod)),
            returnType: pointerType));

    // Sample output:
    // double get x => _xPtr.load<double>();
    final Procedure getter = Procedure(
        field.name,
        ProcedureKind.Getter,
        FunctionNode(
            ReturnStatement(MethodInvocation(
                PropertyGet(ThisExpression(), pointerName, pointerGetter),
                loadMethod.name,
                Arguments([], types: [field.type]),
                loadMethod)),
            returnType: field.type));

    // Sample output:
    // set x(double v) => _xPtr.store(v);
    Procedure setter = null;
    if (!field.isFinal) {
      final VariableDeclaration argument =
          VariableDeclaration('#v', type: field.type);
      setter = Procedure(
          field.name,
          ProcedureKind.Setter,
          FunctionNode(
              ReturnStatement(MethodInvocation(
                  PropertyGet(ThisExpression(), pointerName, pointerGetter),
                  storeMethod.name,
                  Arguments([VariableGet(argument)]),
                  storeMethod)),
              returnType: VoidType(),
              positionalParameters: [argument]));
    }

    replacedGetters[field] = getter;
    replacedSetters[field] = setter;

    return [pointerGetter, getter, if (setter != null) setter];
  }

  /// Sample output:
  /// static int #sizeOf() => 24;
  void _replaceSizeOfMethod(Class struct, Map<Abi, int> sizes) {
    final Field sizeOf = Field(Name("#sizeOf"),
        isStatic: true,
        isFinal: true,
        initializer: _runtimeBranchOnLayout(sizes),
        type: InterfaceType(intClass));
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
    for (NativeType t in types) {
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
    node.addAnnotation(ConstructorInvocation(
        pragmaConstructor, Arguments([StringLiteral("vm:entry-point")])));
  }

  NativeType _getFieldType(Class c) {
    final fieldType = getType(c);

    if (fieldType == NativeType.kVoid) {
      // Fields cannot have Void types.
      return null;
    }
    return fieldType;
  }

  Iterable<NativeType> _getNativeTypeAnnotations(Field node) {
    final Iterable<NativeType> preConstant2018 = node.annotations
        .whereType<ConstructorInvocation>()
        .map((expr) => expr.target.parent)
        .map((klass) => _getFieldType(klass))
        .where((type) => type != null);
    final Iterable<NativeType> postConstant2018 = node.annotations
        .whereType<ConstantExpression>()
        .map((expr) => expr.constant)
        .whereType<InstanceConstant>()
        .map((constant) => constant.classNode)
        .map((klass) => _getFieldType(klass))
        .where((type) => type != null);
    // TODO(dacoharkes): Remove preConstant2018 after constants change landed.
    return postConstant2018.followedBy(preConstant2018);
  }
}

class SizeAndOffsets {
  /// Size of the entire struct.
  final int size;

  /// Offset in bytes for each field, indexed by field number.
  final List<int> offsets;

  SizeAndOffsets(this.size, this.offsets);
}
