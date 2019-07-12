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

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;

import 'ffi.dart'
    show
        ReplacedMembers,
        NativeType,
        FfiTransformer,
        nativeTypeSizes,
        WORD_SIZE;

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
  final LibraryIndex index = LibraryIndex(
      component, const ["dart:ffi", "dart:_internal", "dart:core"]);
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
  final Field _internalIs64Bit;
  final Constructor _unimplementedErrorCtor;
  static const String _errorOn32BitMessage =
      "Code-gen for FFI structs is not supported on 32-bit platforms.";

  Map<Field, Procedure> replacedGetters = {};
  Map<Field, Procedure> replacedSetters = {};

  _FfiDefinitionTransformer(this.index, CoreTypes coreTypes,
      ClassHierarchy hierarchy, DiagnosticReporter diagnosticReporter)
      : _internalIs64Bit = index.getTopLevelMember('dart:_internal', 'is64Bit'),
        _unimplementedErrorCtor =
            index.getMember('dart:core', 'UnimplementedError', ''),
        super(index, coreTypes, hierarchy, diagnosticReporter) {}

  Statement guardOn32Bit(Statement body) {
    final Throw error = Throw(ConstructorInvocation(_unimplementedErrorCtor,
        Arguments([StringLiteral(_errorOn32BitMessage)])));
    return IfStatement(
        StaticGet(_internalIs64Bit), body, ExpressionStatement(error));
  }

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
      int size = _replaceFields(node);
      _replaceSizeOfMethod(node, size);
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
      List<NativeType> annos = _getAnnotations(f).toList();
      if (_isPointerType(f)) {
        if (annos.length != 0) {
          diagnosticReporter.report(
              templateFfiFieldNoAnnotation.withArguments(f.name.name),
              f.fileOffset,
              f.name.name.length,
              f.fileUri);
        }
      } else if (annos.length != 1) {
        diagnosticReporter.report(
            templateFfiFieldAnnotation.withArguments(f.name.name),
            f.fileOffset,
            f.name.name.length,
            f.fileUri);
      } else {
        DartType dartType = f.type;
        DartType nativeType =
            InterfaceType(nativeTypesClasses[annos.first.index]);
        // TODO(36730): Support structs inside structs.
        DartType shouldBeDartType =
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
    List<Initializer> toRemove = [];

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

  /// Computes the field offsets in the struct and replaces the fields with
  /// getters and setters using these offsets.
  ///
  /// Returns the total size of the struct.
  int _replaceFields(Class node) {
    List<Field> fields = [];
    List<NativeType> types = [];

    for (Field f in node.fields) {
      if (_isPointerType(f)) {
        fields.add(f);
        types.add(NativeType.kPointer);
      } else {
        List<NativeType> annos = _getAnnotations(f).toList();
        if (annos.length == 1) {
          NativeType t = annos.first;
          fields.add(f);
          types.add(t);
        }
      }
    }

    List<int> offsets = _calculateOffsets(types);
    int size = _calculateSize(offsets, types);

    for (int i = 0; i < fields.length; i++) {
      List<Procedure> methods =
          _generateMethodsForField(fields[i], types[i], offsets[i]);
      for (Procedure p in methods) {
        node.addMember(p);
      }
    }

    for (Field f in fields) {
      f.remove();
    }

    return size;
  }

  /// Sample output:
  /// ffi.Pointer<ffi.Double> get _xPtr => addressOf.cast();
  /// double get x => _xPtr.load();
  /// set x(double v) => _xPtr.store(v);
  List<Procedure> _generateMethodsForField(
      Field field, NativeType type, int offset) {
    DartType nativeType = type == NativeType.kPointer
        ? field.type
        : InterfaceType(nativeTypesClasses[type.index]);
    DartType pointerType = InterfaceType(pointerClass, [nativeType]);
    Name pointerName = Name('#_ptr_${field.name.name}');

    // Sample output:
    // ffi.Pointer<ffi.Double> get _xPtr => addressOf.offsetBy(...).cast<ffi.Pointer<ffi.Double>>();
    Expression pointer =
        PropertyGet(ThisExpression(), addressOfField.name, addressOfField);
    if (offset != 0) {
      pointer = MethodInvocation(pointer, offsetByMethod.name,
          Arguments([IntLiteral(offset)]), offsetByMethod);
    }
    Procedure pointerGetter = Procedure(
        pointerName,
        ProcedureKind.Getter,
        FunctionNode(
            guardOn32Bit(ReturnStatement(MethodInvocation(
                pointer,
                castMethod.name,
                Arguments([], types: [nativeType]),
                castMethod))),
            returnType: pointerType));

    // Sample output:
    // double get x => _xPtr.load<double>();
    Procedure getter = Procedure(
        field.name,
        ProcedureKind.Getter,
        FunctionNode(
            guardOn32Bit(ReturnStatement(MethodInvocation(
                PropertyGet(ThisExpression(), pointerName, pointerGetter),
                loadMethod.name,
                Arguments([], types: [field.type]),
                loadMethod))),
            returnType: field.type));

    // Sample output:
    // set x(double v) => _xPtr.store(v);
    Procedure setter = null;
    if (!field.isFinal) {
      VariableDeclaration argument =
          VariableDeclaration('#v', type: field.type);
      setter = Procedure(
          field.name,
          ProcedureKind.Setter,
          FunctionNode(
              guardOn32Bit(ReturnStatement(MethodInvocation(
                  PropertyGet(ThisExpression(), pointerName, pointerGetter),
                  storeMethod.name,
                  Arguments([VariableGet(argument)]),
                  storeMethod))),
              returnType: VoidType(),
              positionalParameters: [argument]));
    }

    replacedGetters[field] = getter;
    replacedSetters[field] = setter;

    if (setter != null) {
      return [pointerGetter, getter, setter];
    } else {
      return [pointerGetter, getter];
    }
  }

  /// Sample output:
  /// static int #sizeOf() => 24;
  void _replaceSizeOfMethod(Class struct, int size) {
    final Field sizeOf = Field(Name("#sizeOf"),
        isStatic: true, isFinal: true, initializer: IntLiteral(size));
    _makeEntryPoint(sizeOf);
    struct.addMember(sizeOf);
  }

  // TODO(dacoharkes): move to VM, take into account architecture
  // https://github.com/dart-lang/sdk/issues/35768
  int _sizeInBytes(NativeType t) {
    int size = nativeTypeSizes[t.index];
    if (size == WORD_SIZE) {
      size = 8;
    }
    return size;
  }

  int _align(int offset, int size) {
    int remainder = offset % size;
    if (remainder != 0) {
      offset -= remainder;
      offset += size;
    }
    return offset;
  }

  // TODO(dacoharkes): move to VM, take into account architecture
  // https://github.com/dart-lang/sdk/issues/35768
  List<int> _calculateOffsets(List<NativeType> types) {
    int offset = 0;
    List<int> offsets = [];
    for (NativeType t in types) {
      int size = _sizeInBytes(t);
      offset = _align(offset, size);
      offsets.add(offset);
      offset += size;
    }
    return offsets;
  }

  // TODO(dacoharkes): move to VM, take into account architecture
  // https://github.com/dart-lang/sdk/issues/35768
  int _calculateSize(List<int> offsets, List<NativeType> types) {
    if (offsets.isEmpty) {
      return 0;
    }
    int largestElement = types.map((e) => _sizeInBytes(e)).reduce(math.max);
    int highestOffsetIndex = types.length - 1;
    int highestOffset = offsets[highestOffsetIndex];
    int highestOffsetSize = _sizeInBytes(types[highestOffsetIndex]);
    return _align(highestOffset + highestOffsetSize, largestElement);
  }

  void _makeEntryPoint(Annotatable node) {
    node.addAnnotation(ConstructorInvocation(
        pragmaConstructor, Arguments([StringLiteral("vm:entry-point")])));
  }

  NativeType _getFieldType(Class c) {
    NativeType fieldType = getType(c);

    if (fieldType == NativeType.kVoid) {
      // Fields cannot have Void types.
      return null;
    }
    return fieldType;
  }

  Iterable<NativeType> _getAnnotations(Field node) {
    Iterable<NativeType> preConstant2018 = node.annotations
        .whereType<ConstructorInvocation>()
        .map((expr) => expr.target.parent)
        .map((klass) => _getFieldType(klass))
        .where((type) => type != null);
    Iterable<NativeType> postConstant2018 = node.annotations
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
