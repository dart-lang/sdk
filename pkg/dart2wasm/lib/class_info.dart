// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Wasm struct field indices for fields that are accessed explicitly from Wasm
/// code, e.g. in intrinsics.
///
/// The values are validated by asserts, typically either through
/// [ClassInfo._addField] (for manually added fields) or by a line in
/// [FieldIndex.validate] (for fields declared in Dart code).
class FieldIndex {
  static const asyncSuspendStateResume = 2;
  static const asyncSuspendStateContext = 3;
  static const asyncSuspendStateTargetIndex = 4;
  static const asyncSuspendStateCompleter = 5;
  static const asyncSuspendStateCurrentException = 6;
  static const asyncSuspendStateCurrentExceptionStackTrace = 7;
  static const asyncSuspendStateCurrentReturnValue = 8;

  static const classId = 0;
  static const boxValue = 1;
  static const identityHash = 1;
  static const stringArray = 2;
  static const listLength = 3;
  static const listArray = 4;
  static const hashBaseIndex = 2;
  static const hashBaseData = 4;
  static const closureContext = 2;
  static const closureVtable = 3;
  static const closureRuntimeType = 4;
  static const vtableDynamicCallEntry = 0;
  static const vtableInstantiationTypeComparisonFunction = 1;
  static const vtableInstantiationFunction = 2;
  static const instantiationContextInner = 0;
  static const instantiationContextTypeArgumentsBase = 1;
  static const typeIsDeclaredNullable = 2;
  static const interfaceTypeTypeArguments = 4;
  static const functionTypeNamedParameters = 9;
  static const recordTypeNames = 3;
  static const recordTypeFieldTypes = 4;
  static const suspendStateIterator = 4;
  static const suspendStateContext = 5;
  static const suspendStateTargetIndex = 6;
  static const syncStarIteratorCurrent = 3;
  static const syncStarIteratorYieldStarIterable = 4;
  static const recordFieldBase = 2;

  static void validate(Translator translator) {
    void check(Class cls, String name, int expectedIndex) {
      assert(
          translator.fieldIndex[
                  cls.fields.firstWhere((f) => f.name.text == name)] ==
              expectedIndex,
          "Unexpected field index for ${cls.name}.$name");
    }

    check(translator.asyncSuspendStateClass, "_resume",
        FieldIndex.asyncSuspendStateResume);
    check(translator.asyncSuspendStateClass, "_context",
        FieldIndex.asyncSuspendStateContext);
    check(translator.asyncSuspendStateClass, "_targetIndex",
        FieldIndex.asyncSuspendStateTargetIndex);
    check(translator.asyncSuspendStateClass, "_completer",
        FieldIndex.asyncSuspendStateCompleter);
    check(translator.asyncSuspendStateClass, "_currentException",
        FieldIndex.asyncSuspendStateCurrentException);
    check(translator.asyncSuspendStateClass, "_currentExceptionStackTrace",
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
    check(translator.asyncSuspendStateClass, "_currentReturnValue",
        FieldIndex.asyncSuspendStateCurrentReturnValue);

    check(translator.boxedBoolClass, "value", FieldIndex.boxValue);
    check(translator.boxedIntClass, "value", FieldIndex.boxValue);
    check(translator.boxedDoubleClass, "value", FieldIndex.boxValue);
    check(translator.oneByteStringClass, "_array", FieldIndex.stringArray);
    check(translator.twoByteStringClass, "_array", FieldIndex.stringArray);
    check(translator.listBaseClass, "_length", FieldIndex.listLength);
    check(translator.listBaseClass, "_data", FieldIndex.listArray);
    check(translator.hashFieldBaseClass, "_index", FieldIndex.hashBaseIndex);
    check(translator.hashFieldBaseClass, "_data", FieldIndex.hashBaseData);
    check(translator.closureClass, "context", FieldIndex.closureContext);
    check(translator.typeClass, "isDeclaredNullable",
        FieldIndex.typeIsDeclaredNullable);
    check(translator.interfaceTypeClass, "typeArguments",
        FieldIndex.interfaceTypeTypeArguments);
    check(translator.functionTypeClass, "namedParameters",
        FieldIndex.functionTypeNamedParameters);
    check(translator.recordTypeClass, "names", FieldIndex.recordTypeNames);
    check(translator.recordTypeClass, "fieldTypes",
        FieldIndex.recordTypeFieldTypes);
    check(translator.suspendStateClass, "_iterator",
        FieldIndex.suspendStateIterator);
    check(translator.suspendStateClass, "_context",
        FieldIndex.suspendStateContext);
    check(translator.suspendStateClass, "_targetIndex",
        FieldIndex.suspendStateTargetIndex);
    check(translator.syncStarIteratorClass, "_current",
        FieldIndex.syncStarIteratorCurrent);
    check(translator.syncStarIteratorClass, "_yieldStarIterable",
        FieldIndex.syncStarIteratorYieldStarIterable);
  }
}

/// Initial value for the hash code field of objects. This value is recognized
/// by `Object._objectHashCode` wich updates the field first time it's read.
const int initialIdentityHash = 0;

/// Information about the Wasm representation for a class.
class ClassInfo {
  /// The Dart class that this info corresponds to. The top type does not have
  /// an associated Dart class.
  final Class? cls;

  /// The Class ID of this class, stored in every instance of the class.
  final int classId;

  /// Depth of this class in the Wasm type hierarchy.
  final int depth;

  /// The Wasm struct used to represent instances of this class. A class will
  /// sometimes use the same struct as its superclass.
  final w.StructType struct;

  /// The superclass for this class. This will usually be the Dart superclass,
  /// but there are a few exceptions, where the Wasm type hierarchy does not
  /// follow the Dart class hierarchy.
  final ClassInfo? superInfo;

  /// The class that this class masquerades as via `runtimeType`, if any.
  ClassInfo? masquerade = null;

  /// For every type parameter which is directly mapped to a type parameter in
  /// the superclass, this contains the corresponding superclass type
  /// parameter. These will reuse the corresponding type parameter field of
  /// the superclass.
  final Map<TypeParameter, TypeParameter> typeParameterMatch;

  /// The class whose struct is used as the type for variables of this type.
  /// This is a type which is a superclass of all subtypes of this type.
  late final ClassInfo repr = upperBound(
      implementedBy.map((c) => identical(c, this) ? this : c.repr).toSet());

  /// All classes which implement this class. This is used to compute `repr`.
  final List<ClassInfo> implementedBy = [];

  /// Nullabe Wasm ref type for this class.
  final w.RefType nullableType;

  /// Non-nullable Wasm ref type for this class.
  final w.RefType nonNullableType;

  /// Get Wasm ref type for this class with given nullability.
  w.RefType typeWithNullability(bool nullable) =>
      nullable ? nullableType : nonNullableType;

  ClassInfo(this.cls, this.classId, this.depth, this.struct, this.superInfo,
      {this.typeParameterMatch = const {}})
      : nullableType = w.RefType.def(struct, nullable: true),
        nonNullableType = w.RefType.def(struct, nullable: false) {
    implementedBy.add(this);
  }

  void _addField(w.FieldType fieldType, [int? expectedIndex]) {
    assert(expectedIndex == null || expectedIndex == struct.fields.length);
    struct.fields.add(fieldType);
  }
}

ClassInfo upperBound(Set<ClassInfo> classes) {
  while (classes.length > 1) {
    Set<ClassInfo> newClasses = {};
    int minDepth = 999999999;
    int maxDepth = 0;
    for (ClassInfo info in classes) {
      minDepth = min(minDepth, info.depth);
      maxDepth = max(maxDepth, info.depth);
    }
    int targetDepth = minDepth == maxDepth ? minDepth - 1 : minDepth;
    for (ClassInfo info in classes) {
      while (info.depth > targetDepth) {
        info = info.superInfo!;
      }
      newClasses.add(info);
    }
    classes = newClasses;
  }
  return classes.single;
}

/// Constructs the Wasm type hierarchy.
class ClassInfoCollector {
  final Translator translator;
  int _nextClassId = 0;
  late final ClassInfo topInfo;

  /// Maps number of record fields to the struct type to be used for a record
  /// shape class with that many fields.
  final Map<int, w.StructType> _recordStructs = {};

  /// Masquerades for implementation classes. For each entry of the map, all
  /// subtypes of the key masquerade as the value.
  late final Map<Class, Class> _masquerades = _computeMasquerades();

  Map<Class, Class> _computeMasquerades() {
    final map = {
      translator.coreTypes.boolClass: translator.coreTypes.boolClass,
      translator.coreTypes.intClass: translator.coreTypes.intClass,
      translator.coreTypes.doubleClass: translator.coreTypes.doubleClass,
      translator.coreTypes.stringClass: translator.coreTypes.stringClass,
      translator.index.getClass("dart:core", "_Type"):
          translator.coreTypes.typeClass,
      translator.index.getClass("dart:core", "_ListBase"):
          translator.coreTypes.listClass
    };
    for (final name in const <String>[
      "Int8List",
      "Uint8List",
      "Uint8ClampedList",
      "Int16List",
      "Uint16List",
      "Int32List",
      "Uint32List",
      "Int64List",
      "Uint64List",
      "Float32List",
      "Float64List",
      "Int32x4List",
      "Float32x4List",
      "Float64x2List",
    ]) {
      final Class? cls = translator.index.tryGetClass("dart:typed_data", name);
      if (cls != null) {
        map[cls] = cls;
      }
    }
    return map;
  }

  late final Set<Class> _neverMasquerades = _computeNeverMasquerades();

  /// These types switch from properly reified non-masquerading types in regular
  /// Dart2Wasm mode to masquerading types in js compatibility mode.
  final Set<String> jsCompatibilityTypes = {
    "JSArrayBufferImpl",
    "JSArrayBufferViewImpl",
    "JSDataViewImpl",
    "JSInt8ArrayImpl",
    "JSUint8ArrayImpl",
    "JSUint8ClampedArrayImpl",
    "JSInt16ArrayImpl",
    "JSUint16ArrayImpl",
    "JSInt32ArrayImpl",
    "JSInt32x4ArrayImpl",
    "JSUint32ArrayImpl",
    "JSBigUint64ArrayImpl",
    "JSBigInt64ArrayImpl",
    "JSFloat32ArrayImpl",
    "JSFloat32x4ArrayImpl",
    "JSFloat64ArrayImpl",
    "JSFloat64x2ArrayImpl",
  };

  Set<Class> _computeNeverMasquerades() {
    // The JS types do not masquerade in regular Dart2Wasm, but they aren't
    // always used so we have to construct this set programmatically.
    final jsTypesLibraryIndex =
        LibraryIndex(translator.component, ["dart:_js_types"]);
    final neverMasquerades = [
      "JSStringImpl",
      if (!translator.options.jsCompatibility) ...jsCompatibilityTypes,
    ]
        .map((name) => jsTypesLibraryIndex.tryGetClass("dart:_js_types", name))
        .toSet();
    neverMasquerades.removeWhere((c) => c == null);
    return neverMasquerades.cast<Class>();
  }

  /// Wasm field type for fields with type [_Type]. Fields of this type are
  /// added to classes for type parameters.
  ///
  /// This field is initialized when a class with a type parameter is first
  /// encountered. Initialization depends on [Translator] visiting the [_Type]
  /// class first and creating a [ClassInfo] for it.
  late final w.FieldType typeType =
      w.FieldType(translator.classInfo[translator.typeClass]!.nullableType);

  ClassInfoCollector(this.translator);

  w.Module get m => translator.m;

  TranslatorOptions get options => translator.options;

  void _initializeTop() {
    final w.StructType struct = m.addStructType("#Top");
    topInfo = ClassInfo(null, _nextClassId++, 0, struct, null);
    translator.classes.add(topInfo);
    translator.classForHeapType[struct] = topInfo;
  }

  void _initialize(Class cls) {
    ClassInfo? info = translator.classInfo[cls];
    if (info != null) return;

    Class? superclass = cls.superclass;
    if (superclass == null) {
      ClassInfo superInfo = topInfo;
      final w.StructType struct =
          m.addStructType(cls.name, superType: superInfo.struct);
      info = ClassInfo(
          cls, _nextClassId++, superInfo.depth + 1, struct, superInfo);
      // Mark Top type as implementing Object to force the representation
      // type of Object to be Top.
      info.implementedBy.add(topInfo);
    } else {
      // Recursively initialize all supertypes before initializing this class.
      _initialize(superclass);
      for (Supertype interface in cls.implementedTypes) {
        _initialize(interface.classNode);
      }

      // In the Wasm type hierarchy, Object, bool and num sit directly below
      // the Top type. The implementation classes _StringBase and _Type sit
      // directly below the public classes they implement.
      // All other classes sit below their superclass.
      ClassInfo superInfo = cls == translator.coreTypes.boolClass ||
              cls == translator.coreTypes.numClass
          ? topInfo
          : cls == translator.stringBaseClass || cls == translator.typeClass
              ? translator.classInfo[cls.implementedTypes.single.classNode]!
              : translator.classInfo[superclass]!;

      // Figure out which type parameters can reuse a type parameter field of
      // the superclass.
      Map<TypeParameter, TypeParameter> typeParameterMatch = {};
      if (cls.typeParameters.isNotEmpty) {
        Supertype supertype = cls.superclass == superInfo.cls
            ? cls.supertype!
            : cls.implementedTypes.single;
        for (TypeParameter parameter in cls.typeParameters) {
          for (int i = 0; i < supertype.typeArguments.length; i++) {
            DartType arg = supertype.typeArguments[i];
            if (arg is TypeParameterType && arg.parameter == parameter) {
              typeParameterMatch[parameter] = superInfo.cls!.typeParameters[i];
              break;
            }
          }
        }
      }

      // A class can reuse the Wasm struct of the superclass if it doesn't
      // declare any Wasm fields of its own. This is the case when three
      // conditions are met:
      //   1. All type parameters can reuse a type parameter field of the
      //      superclass.
      //   2. The class declares no Dart fields of its own.
      //   3. The class is not a special class that contains hidden fields.
      bool canReuseSuperStruct =
          typeParameterMatch.length == cls.typeParameters.length &&
              cls.fields.where((f) => f.isInstanceMember).isEmpty;
      w.StructType struct = canReuseSuperStruct
          ? superInfo.struct
          : m.addStructType(cls.name, superType: superInfo.struct);
      info = ClassInfo(
          cls, _nextClassId++, superInfo.depth + 1, struct, superInfo,
          typeParameterMatch: typeParameterMatch);

      // Mark all interfaces as being implemented by this class. This is
      // needed to calculate representation types.
      for (Supertype interface in cls.implementedTypes) {
        ClassInfo? interfaceInfo = translator.classInfo[interface.classNode];
        while (interfaceInfo != null) {
          interfaceInfo.implementedBy.add(info);
          interfaceInfo = interfaceInfo.superInfo;
        }
      }
    }
    translator.classes.add(info);
    translator.classInfo[cls] = info;
    translator.classForHeapType.putIfAbsent(info.struct, () => info!);

    ClassInfo? computeMasquerade() {
      if (_neverMasquerades.contains(cls)) {
        return null;
      }
      if (info!.superInfo?.masquerade != null) {
        return info.superInfo!.masquerade;
      }
      for (Supertype implemented in cls.implementedTypes) {
        ClassInfo? implementedMasquerade =
            translator.classInfo[implemented.classNode]!.masquerade;
        if (implementedMasquerade != null) {
          return implementedMasquerade;
        }
      }
      Class? selfMasquerade = _masquerades[cls];
      if (selfMasquerade != null) {
        return translator.classInfo[selfMasquerade]!;
      }
      return null;
    }

    info.masquerade = computeMasquerade();
  }

  void _initializeRecordClass(Class cls) {
    final numFields = cls.fields.length;

    final struct = _recordStructs.putIfAbsent(
        numFields,
        () => m.addStructType(
              'Record$numFields',
              superType: translator.recordInfo.struct,
            ));

    final ClassInfo superInfo = translator.recordInfo;

    final info =
        ClassInfo(cls, _nextClassId++, superInfo.depth + 1, struct, superInfo);

    translator.classes.add(info);
    translator.classInfo[cls] = info;
    translator.classForHeapType.putIfAbsent(info.struct, () => info);
  }

  void _generateFields(ClassInfo info) {
    ClassInfo? superInfo = info.superInfo;
    if (superInfo == null) {
      // Top - add class id field
      info._addField(w.FieldType(w.NumType.i32), FieldIndex.classId);
    } else if (info.struct != superInfo.struct) {
      // Copy fields from superclass
      for (w.FieldType fieldType in superInfo.struct.fields) {
        info._addField(fieldType);
      }
      if (info.cls!.superclass == null) {
        // Object - add identity hash code field
        info._addField(w.FieldType(w.NumType.i32), FieldIndex.identityHash);
      }
      // Add fields for type variables
      for (TypeParameter parameter in info.cls!.typeParameters) {
        TypeParameter? match = info.typeParameterMatch[parameter];
        if (match != null) {
          // Reuse supertype type variable
          translator.typeParameterIndex[parameter] =
              translator.typeParameterIndex[match]!;
        } else {
          translator.typeParameterIndex[parameter] = info.struct.fields.length;
          info._addField(typeType);
        }
      }
      // Add fields for Dart instance fields
      for (Field field in info.cls!.fields) {
        if (field.isInstanceMember) {
          w.ValueType wasmType = translator.translateType(field.type);
          // TODO(askesc): Generalize this check for finer nullability control
          if (wasmType != w.RefType.struct(nullable: false)) {
            wasmType = wasmType.withNullability(true);
          }
          translator.fieldIndex[field] = info.struct.fields.length;
          info._addField(w.FieldType(wasmType));
        }
      }
    } else {
      for (TypeParameter parameter in info.cls!.typeParameters) {
        // Reuse supertype type variable
        translator.typeParameterIndex[parameter] =
            translator.typeParameterIndex[info.typeParameterMatch[parameter]]!;
      }
    }
  }

  void _generateRecordFields(ClassInfo info) {
    final struct = info.struct;
    final ClassInfo superInfo = info.superInfo!;
    assert(identical(superInfo, translator.recordInfo));

    // Different record classes can share the same struct, check if the struct
    // is already initialized
    if (struct.fields.isEmpty) {
      // Copy fields from superclass
      for (w.FieldType fieldType in superInfo.struct.fields) {
        info._addField(fieldType);
      }

      for (Field _ in info.cls!.fields) {
        info._addField(w.FieldType(topInfo.nullableType));
      }
    }

    int fieldIdx = superInfo.struct.fields.length;
    for (Field field in info.cls!.fields) {
      translator.fieldIndex[field] = fieldIdx++;
    }
  }

  /// Create class info and Wasm struct for all classes.
  void collect() {
    _initializeTop();

    // Subclasses of the `_Closure` class are generated on the fly as fields
    // with function types are encountered. Therefore, `_Closure` class must
    // be early in the initialization order.
    _initialize(translator.closureClass);

    // Similarly `_Type` is needed for type parameter fields in classes and
    // needs to be initialized before we encounter a class with type
    // parameters.
    _initialize(translator.typeClass);

    // Initialize value classes to make sure they have low class IDs.
    for (Class cls in translator.valueClasses.keys) {
      _initialize(cls);
    }

    // Initialize masquerade classes to make sure they have low class IDs.
    for (Class cls in _masquerades.values) {
      _initialize(cls);
    }

    // Initialize the record base class if we have record classes.
    if (translator.recordClasses.isNotEmpty) {
      _initialize(translator.coreTypes.recordClass);
    }

    for (Library library in translator.component.libraries) {
      for (Class cls in library.classes) {
        if (cls.superclass == translator.coreTypes.recordClass) {
          _initializeRecordClass(cls);
        } else {
          _initialize(cls);
        }
      }
    }

    // Now that the representation types for all classes have been computed,
    // fill in the types of the fields in the generated Wasm structs.
    for (ClassInfo info in translator.classes) {
      if (info.superInfo == translator.recordInfo) {
        _generateRecordFields(info);
      } else {
        _generateFields(info);
      }
    }

    // Validate that all internally used fields have the expected indices.
    FieldIndex.validate(translator);
  }
}
