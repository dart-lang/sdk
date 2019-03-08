// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.ffi_definitions;

import 'dart:math' as math;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        templateFfiFieldAnnotation,
        templateFfiStructAnnotation,
        templateFfiTypeMismatch,
        templateFfiFieldInitializer;

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

/// Checks and expands the dart:ffi @struct and field annotations.
///
/// Sample input:
/// @ffi.struct
/// class Coord extends ffi.Pointer<Void> {
///   @ffi.Double()
///   double x;
///
///   @ffi.Double()
///   double y;
///
///   @ffi.Pointer()
///   Coord next;
///
///   external static int sizeOf();
/// }
///
/// Sample output:
/// class Coordinate extends ffi.Pointer<ffi.Void> {
///   ffi.Pointer<ffi.Double> get _xPtr => cast();
///   set x(double v) => _xPtr.store(v);
///   double get x => _xPtr.load();
///
///   ffi.Pointer<ffi.Double> get _yPtr =>
///       offsetBy(ffi.sizeOf<ffi.Double>() * 1).cast();
///   set y(double v) => _yPtr.store(v);
///   double get y => _yPtr.load();
///
///   ffi.Pointer<Coordinate> get _nextPtr =>
///       offsetBy(ffi.sizeOf<ffi.Double>() * 2).cast();
///   set next(Coordinate v) => _nextPtr.store(v);
///   Coordinate get next => _nextPtr.load();
///
///   static int sizeOf() => 24;
/// }
ReplacedMembers transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter) {
  final index = new LibraryIndex(component, ["dart:ffi"]);
  if (!index.containsLibrary("dart:ffi")) {
    // if dart:ffi is not loaded, do not do the transformation
    return ReplacedMembers({}, {});
  }
  final transformer = new _FfiDefinitionTransformer(
      index, coreTypes, hierarchy, diagnosticReporter);
  libraries.forEach(transformer.visitLibrary);
  return ReplacedMembers(
      transformer.replacedGetters, transformer.replacedSetters);
}

/// Checks and expands the dart:ffi @struct and field annotations.
class _FfiDefinitionTransformer extends FfiTransformer {
  Map<Field, Procedure> replacedGetters = {};
  Map<Field, Procedure> replacedSetters = {};

  _FfiDefinitionTransformer(LibraryIndex index, CoreTypes coreTypes,
      ClassHierarchy hierarchy, DiagnosticReporter diagnosticReporter)
      : super(index, coreTypes, hierarchy, diagnosticReporter) {}

  @override
  visitClass(Class node) {
    if (node == pointerClass || !hierarchy.isSubtypeOf(node, pointerClass)) {
      return node;
    }

    // Because subtypes of Pointer are only allocated by allocate<Pointer<..>>()
    // and fromAddress<Pointer<..>>() which are not recognized as constructor
    // calls, we need to prevent these classes from being tree shaken out.
    _preventTreeShaking(node);

    _checkFieldAnnotations(node);
    _checkConstructors(node);

    bool isStruct = _checkStructAnnotation(node);
    if (isStruct) {
      int size = _replaceFields(node);
      _replaceSizeOfMethod(node, size);
    }

    return node;
  }

  bool _checkStructAnnotation(Class node) {
    bool isStruct = _hasAnnotation(node);
    if (!isStruct && node.fields.isNotEmpty) {
      diagnosticReporter.report(
          templateFfiStructAnnotation.withArguments(node.name),
          node.fileOffset,
          1,
          node.fileUri);
    }
    return isStruct;
  }

  void _checkFieldAnnotations(Class node) {
    for (Field f in node.fields) {
      if (f.initializer is! NullLiteral) {
        diagnosticReporter.report(
            templateFfiFieldInitializer.withArguments(f.name.name),
            f.fileOffset,
            f.name.name.length,
            f.fileUri);
      }
      List<NativeType> annos = _getAnnotations(f).toList();
      if (annos.length != 1) {
        diagnosticReporter.report(
            templateFfiFieldAnnotation.withArguments(f.name.name),
            f.fileOffset,
            f.name.name.length,
            f.fileUri);
      } else {
        DartType dartType = f.type;
        DartType nativeType =
            InterfaceType(nativeTypesClasses[annos.first.index]);
        DartType shouldBeDartType = convertNativeTypeToDartType(nativeType);
        if (!env.isSubtypeOf(dartType, shouldBeDartType)) {
          diagnosticReporter.report(
              templateFfiTypeMismatch.withArguments(
                  dartType, shouldBeDartType, nativeType),
              f.fileOffset,
              1,
              f.location.file);
        }
      }
    }
  }

  void _checkConstructors(Class node) {
    List<Initializer> toRemove = [];
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
  }

  /// Computes the field offsets in the struct and replaces the fields with
  /// getters and setters using these offsets.
  ///
  /// Returns the total size of the struct.
  int _replaceFields(Class node) {
    List<Field> fields = [];
    List<NativeType> types = [];

    for (Field f in node.fields) {
      List<NativeType> annos = _getAnnotations(f).toList();
      if (annos.length == 1) {
        NativeType t = annos.first;
        fields.add(f);
        types.add(t);
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
  /// ffi.Pointer<ffi.Double> get _xPtr => cast();
  /// double get x => _xPtr.load();
  /// set x(double v) => _xPtr.store(v);
  List<Procedure> _generateMethodsForField(
      Field field, NativeType type, int offset) {
    DartType nativeType = type == NativeType.kPointer
        ? field.type
        : InterfaceType(nativeTypesClasses[type.index]);
    DartType pointerType = InterfaceType(pointerClass, [nativeType]);
    Name pointerName = Name('#_ptr_${field.name.name}');

    // Sample output for primitives:
    // ffi.Pointer<ffi.Double> get _xPtr => cast<ffi.Pointer<ffi.Double>>();
    // Sample output for structs:
    // ffi.Pointer<Coordinate> get _xPtr => offsetBy(16).cast<...>();
    Expression offsetExpression = ThisExpression();
    if (offset != 0) {
      offsetExpression = MethodInvocation(offsetExpression, offsetByMethod.name,
          Arguments([IntLiteral(offset)]), offsetByMethod);
    }
    Procedure pointerGetter = Procedure(
        pointerName,
        ProcedureKind.Getter,
        FunctionNode(
            ReturnStatement(MethodInvocation(offsetExpression, castMethod.name,
                Arguments([], types: [pointerType]), castMethod)),
            returnType: pointerType));

    // Sample output:
    // double get x => _xPtr.load<double>();
    Procedure getter = Procedure(
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
    VariableDeclaration argument = VariableDeclaration('#v', type: field.type);
    Procedure setter = Procedure(
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

    replacedGetters[field] = getter;
    replacedSetters[field] = setter;

    return [pointerGetter, getter, setter];
  }

  /// Sample input:
  /// external static int sizeOf();
  ///
  /// Sample output:
  /// static int sizeOf() => 24;
  void _replaceSizeOfMethod(Class struct, int size) {
    Procedure sizeOf = _findProcedure(struct, 'sizeOf');
    if (sizeOf == null || !sizeOf.isExternal || !sizeOf.isStatic) {
      return;
    }

    // replace in place to avoid going over use sites
    sizeOf.function = FunctionNode(ReturnStatement(IntLiteral(size)),
        returnType: InterfaceType(intClass));
    sizeOf.isExternal = false;
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

  bool _hasAnnotation(Class node) {
    for (Expression e in node.annotations) {
      if (e is StaticGet) {
        if (e.target == structField) {
          return true;
        }
      }
    }
    return false;
  }

  void _preventTreeShaking(Class node) {
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
    return node.annotations
        .whereType<ConstructorInvocation>()
        .map((expr) => expr.target.parent)
        .map((klass) => _getFieldType(klass))
        .where((type) => type != null);
  }
}

/// Finds procedure with name, otherwise returns null.
Procedure _findProcedure(Class c, String name) =>
    c.procedures.firstWhere((p) => p.name.name == name, orElse: () => null);
