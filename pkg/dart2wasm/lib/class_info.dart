// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'dynamic_modules.dart';
import 'serialization.dart';
import 'translator.dart';

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
  static const asyncSuspendStateFuture = 5;
  static const asyncSuspendStateCurrentException = 6;
  static const asyncSuspendStateCurrentExceptionStackTrace = 7;
  static const asyncSuspendStateCurrentReturnValue = 8;

  static const classId = 0;
  static const boxValue = 1;
  static const identityHash = 1;
  static const objectFieldBase = 2;
  static const stringArray = 2;
  static const listLength = 3;
  static const listArray = 4;
  static const hashBaseIndex = 2;
  static const hashBaseData = 4;
  static const closureContext = 2;
  static const closureVtable = 3;
  static const closureRuntimeType = 4;
  static const instantiationContextInner = 0;
  static const instantiationContextTypeArgumentsBase = 1;
  static const typeIsDeclaredNullable = 2;
  static const interfaceTypeClassId = 3;
  static const interfaceTypeTypeArguments = 4;
  static const functionTypeNamedParameters = 9;
  static const recordTypeNames = 3;
  static const recordTypeFieldTypes = 4;
  static const suspendStateIterator = 4;
  static const suspendStateContext = 5;
  static const suspendStateTargetIndex = 6;
  static const suspendStateCurrentException = 7;
  static const suspendStateCurrentExceptionStackTrace = 8;
  static const syncStarIteratorCurrent = 3;
  static const syncStarIteratorYieldStarIterable = 4;
  static const recordFieldBase = 2;
  static const jsStringImplRef = 2;
  static const ffiPointerAddress = 3;

  static void validate(Translator translator) {
    void check(Class cls, String name, int expectedIndex) {
      Field? field;

      for (Field clsField in cls.fields) {
        if (clsField.name.text == name) {
          field = clsField;
          break;
        }
      }

      if (field == null) {
        throw AssertionError("$cls doesn't have field $name");
      }

      final actualIndex = translator.fieldIndex[field];

      if (actualIndex == null) {
        throw AssertionError("$cls field $name doesn't have an index assigned");
      }

      if (actualIndex != expectedIndex) {
        throw AssertionError(
            "$cls field $name expected index = $expectedIndex, "
            "actual index = $actualIndex");
      }
    }

    check(translator.asyncSuspendStateClass, "_resume",
        FieldIndex.asyncSuspendStateResume);
    check(translator.asyncSuspendStateClass, "_context",
        FieldIndex.asyncSuspendStateContext);
    check(translator.asyncSuspendStateClass, "_targetIndex",
        FieldIndex.asyncSuspendStateTargetIndex);
    check(translator.asyncSuspendStateClass, "_future",
        FieldIndex.asyncSuspendStateFuture);
    check(translator.asyncSuspendStateClass, "_currentException",
        FieldIndex.asyncSuspendStateCurrentException);
    check(translator.asyncSuspendStateClass, "_currentExceptionStackTrace",
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
    check(translator.asyncSuspendStateClass, "_currentReturnValue",
        FieldIndex.asyncSuspendStateCurrentReturnValue);

    check(translator.boxedBoolClass, "value", FieldIndex.boxValue);
    check(translator.boxedIntClass, "value", FieldIndex.boxValue);
    check(translator.boxedDoubleClass, "value", FieldIndex.boxValue);
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
    check(translator.suspendStateClass, "_currentException",
        FieldIndex.suspendStateCurrentException);
    check(translator.suspendStateClass, "_currentExceptionStackTrace",
        FieldIndex.suspendStateCurrentExceptionStackTrace);
    check(translator.syncStarIteratorClass, "_current",
        FieldIndex.syncStarIteratorCurrent);
    check(translator.syncStarIteratorClass, "_yieldStarIterable",
        FieldIndex.syncStarIteratorYieldStarIterable);
    check(translator.ffiPointerClass, "_address", FieldIndex.ffiPointerAddress);
  }
}

/// Initial value for the hash code field of objects. This value is recognized
/// by `Object._objectHashCode` wich updates the field first time it's read.
const int initialIdentityHash = 0;

/// We do not assign real class ids to anonymous mixin classes.
const int anonymousMixinClassId = -1;

/// Information about the Wasm representation for a class.
class ClassInfo {
  /// The Dart class that this info corresponds to. The top type does not have
  /// an associated Dart class.
  final Class? cls;

  /// The Class ID of this class, stored in every instance of the class.
  ClassId get classId {
    if (_classId._localValue == anonymousMixinClassId) {
      throw 'Tried to access class ID of anonymous mixin $cls';
    }
    return _classId;
  }

  final ClassId _classId;

  /// Depth of this class in the Wasm type hierarchy.
  final int depth;

  /// The Wasm struct used to represent instances of this class. A class will
  /// sometimes use the same struct as its superclass.
  final w.StructType struct;

  /// The superclass for this class. This will usually be the Dart superclass,
  /// but there are a few exceptions, where the Wasm type hierarchy does not
  /// follow the Dart class hierarchy.
  final ClassInfo? superInfo;

  /// For every type parameter which is directly mapped to a type parameter in
  /// the superclass, this contains the corresponding superclass type
  /// parameter. These will reuse the corresponding type parameter field of
  /// the superclass.
  final Map<TypeParameter, TypeParameter> typeParameterMatch;

  /// The Wasm type used to represent values of a Dart interface type of this
  /// class.
  w.RefType get repr => _repr!;

  w.RefType? _repr;

  /// Nullabe Wasm ref type for this class.
  final w.RefType nullableType;

  /// Non-nullable Wasm ref type for this class.
  final w.RefType nonNullableType;

  /// Get Wasm ref type for this class with given nullability.
  w.RefType typeWithNullability(bool nullable) =>
      nullable ? nullableType : nonNullableType;

  ClassInfo(this.cls, this._classId, this.depth, this.struct, this.superInfo,
      {this.typeParameterMatch = const {}})
      : nullableType = w.RefType.def(struct, nullable: true),
        nonNullableType = w.RefType.def(struct, nullable: false);

  void _addField(w.FieldType fieldType,
      {int? expectedIndex, String? fieldName}) {
    assert(expectedIndex == null || expectedIndex == struct.fields.length);
    struct.fields.add(fieldType);
    if (fieldName != null && fieldName.isNotEmpty) {
      final fieldIndex = struct.fields.length - 1;
      struct.fieldNames[fieldIndex] = fieldName;
    }
  }

  // This returns the types of all the class's fields (including
  // superclass fields), except for the class id and the identity hash
  List<w.ValueType> getClassFieldTypes() => [
        for (var fieldType in struct.fields.skip(FieldIndex.objectFieldBase))
          fieldType.type.unpacked
      ];

  void forEachClassFieldIndex(void Function(int index, w.FieldType type) f) {
    for (int i = FieldIndex.objectFieldBase; i < struct.fields.length; i++) {
      f(i, struct.fields[i]);
    }
  }
}

ClassInfo _upperBound(ClassInfo a, ClassInfo b) {
  if (a.depth < b.depth) {
    while (b.depth > a.depth) {
      b = b.superInfo!;
    }
  } else {
    while (a.depth > b.depth) {
      a = a.superInfo!;
    }
  }
  assert(a.depth == b.depth);
  while (a != b) {
    a = a.superInfo!;
    b = b.superInfo!;
  }
  return a;
}

/// Constructs the Wasm type hierarchy.
class ClassInfoCollector {
  final Translator translator;
  late final ClassInfo topInfo;

  /// Maps number of record fields to the struct type to be used for a record
  /// shape class with that many fields.
  final Map<int, w.StructType> _recordStructs = {};

  /// Any subtype of these needs to masqueraded (modulo special js-compatibility
  /// mode semantics) or specially treated due to being from a different type
  /// (e.g. record, closure)
  late final Set<Class> masqueraded = _computeMasquerades();

  Set<Class> _computeMasquerades() {
    final values = {
      translator.coreTypes.boolClass,
      translator.coreTypes.intClass,
      translator.coreTypes.doubleClass,
      translator.coreTypes.stringClass,
      translator.coreTypes.functionClass,
      translator.coreTypes.recordClass,
      translator.index.getClass("dart:core", "_Type"),
      translator.index.getClass("dart:_list", "WasmListBase"),
      translator.index.getClass("dart:_string", "JSStringImpl"),
    };
    for (final name in const <String>[
      "ByteBuffer",
      "ByteData",
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
      if (cls != null) values.add(cls);
    }
    return values;
  }

  /// Wasm field type for fields with type [_Type]. Fields of this type are
  /// added to classes for type parameters.
  ///
  /// This field is initialized when a class with a type parameter is first
  /// encountered. Initialization depends on [Translator] visiting the [_Type]
  /// class first and creating a [ClassInfo] for it.
  late final w.FieldType typeType = w.FieldType(
      translator.classInfo[translator.typeClass]!.nonNullableType,
      mutable: false);

  ClassInfoCollector(this.translator);

  TranslatorOptions get options => translator.options;

  void _createStructForClassTop() {
    final w.StructType struct = translator.typesBuilder.defineStruct("#Top");
    topInfo = ClassInfo(null, AbsoluteClassId(0), 0, struct, null);
    translator.classForHeapType[struct] = topInfo;
  }

  void _createStructForClass(Map<Class, ClassId> classIds, Class cls) {
    ClassInfo? info = translator.classInfo[cls];
    if (info != null) return;

    final classId = classIds[cls]!;
    Class? superclass = cls.superclass;
    if (superclass == null) {
      ClassInfo superInfo = topInfo;
      final w.StructType struct = translator.typesBuilder
          .defineStruct(cls.name, superType: superInfo.struct);
      info = ClassInfo(cls, classId, superInfo.depth + 1, struct, superInfo);
      // Mark Top type as implementing Object to force the representation
      // type of Object to be Top.
    } else {
      // Recursively initialize all supertypes before initializing this class.
      _createStructForClass(classIds, superclass);
      for (Supertype interface in cls.implementedTypes) {
        _createStructForClass(classIds, interface.classNode);
      }

      // In the Wasm type hierarchy, Object, bool and num sit directly below
      // the Top type. The implementation classes of _Type sit directly below
      // the public classes they implement. All other classes sit below their
      // superclass.
      ClassInfo superInfo = cls == translator.coreTypes.boolClass ||
              cls == translator.coreTypes.numClass ||
              cls == translator.boxedIntClass ||
              cls == translator.boxedDoubleClass
          ? topInfo
          : cls == translator.typeClass
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
            DartType superTypeArg = supertype.typeArguments[i];
            if (superTypeArg is TypeParameterType &&
                superTypeArg.parameter == parameter &&
                superTypeArg.nullability != Nullability.nullable) {
              typeParameterMatch[parameter] = superInfo.cls!.typeParameters[i];
              break;
            }
          }
        }
      }
      final hasFields =
          _requiresSubclassFields(superInfo, typeParameterMatch, cls);

      w.StructType struct = hasFields
          ? translator.typesBuilder
              .defineStruct(cls.name, superType: superInfo.struct)
          : superInfo.struct;
      info = ClassInfo(cls, classId, superInfo.depth + 1, struct, superInfo,
          typeParameterMatch: typeParameterMatch);
      if (translator.dynamicModuleSupportEnabled &&
          cls.isDynamicSubmoduleExtendable(translator.coreTypes)) {
        // If a class is extendable in a submodule then we have to be
        // conservative and mark it as not being final.
        struct.hasAnySubtypes = true;
      }

      if (translator.isDynamicSubmodule) {
        final brandIndex = translator
            .dynamicModuleInfo!.metadata.classMetadata[cls]?.brandIndex;
        if (brandIndex != null) {
          translator.typesBuilder.addBrandTypeAssignment(struct, brandIndex);
        }
      }
    }
    translator.classesSupersFirst.add(info);
    translator.classInfo[cls] = info;
    translator.classForHeapType.putIfAbsent(info.struct, () => info!);
    if (classId._localValue != anonymousMixinClassId) {
      translator.classes[classId._localValue] = info;
    }
  }

  void _createStructForRecordClass(Map<Class, ClassId> classIds, Class cls) {
    final numFields = cls.fields.length;

    final struct = _recordStructs.putIfAbsent(
        numFields,
        () => translator.typesBuilder.defineStruct(
              'Record$numFields',
              superType: translator.recordInfo.struct,
            ));

    final ClassInfo superInfo = translator.recordInfo;

    final classId = classIds[cls]!;
    final info =
        ClassInfo(cls, classId, superInfo.depth + 1, struct, superInfo);

    translator.classesSupersFirst.add(info);
    translator.classes[classId._localValue] = info;
    translator.classInfo[cls] = info;
    translator.classForHeapType.putIfAbsent(info.struct, () => info);
  }

  void _generateFields(ClassInfo info) {
    assert(_requiresSubclassFields(
        info.superInfo, info.typeParameterMatch, info.cls));
    ClassInfo? superInfo = info.superInfo;
    if (superInfo == null) {
      // Top - add class id field
      info._addField(w.FieldType(w.NumType.i32, mutable: false),
          expectedIndex: FieldIndex.classId);
      return;
    }

    // Copy fields from superclass
    int superFieldIndex = 0;
    for (w.FieldType fieldType in superInfo.struct.fields) {
      info._addField(fieldType,
          fieldName: superInfo.struct.fieldNames[superFieldIndex]);
      superFieldIndex += 1;
    }

    final cls = info.cls!;
    if (cls == translator.coreTypes.objectClass) {
      assert(cls.superclass == null);
      // Object - add identity hash code field
      info._addField(w.FieldType(w.NumType.i32),
          expectedIndex: FieldIndex.identityHash);

      assert(cls.typeParameters.isEmpty);
      assert(!cls.fields.any((field) => field.isInstanceMember));
      return;
    }

    // Add fields for type variables
    for (TypeParameter parameter in cls.typeParameters) {
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
    for (Field field in cls.fields) {
      if (field.isInstanceMember) {
        final w.ValueType wasmType = translator.translateTypeOfField(field);
        translator.fieldIndex[field] = info.struct.fields.length;
        info._addField(w.FieldType(wasmType, mutable: !field.isFinal),
            fieldName: field.name.text);
      }
    }
  }

  bool _requiresSubclassFields(ClassInfo? superInfo,
      Map<TypeParameter, TypeParameter> reuseTypeParameter, Class? cls) {
    if (superInfo == null) {
      // Top class, requires class-id field.
      return true;
    }

    if (cls! == translator.coreTypes.objectClass) {
      // Object class, requires identity hash code field.
      return true;
    }

    if (cls.typeParameters.isNotEmpty) {
      for (final param in cls.typeParameters) {
        if (!reuseTypeParameter.containsKey(param)) {
          // Requires field for value of type parameter.
          return true;
        }
      }
    }

    return cls.fields.any((field) => field.isInstanceMember);
  }

  void _generateRecordFields(ClassInfo info) {
    final struct = info.struct;
    final ClassInfo superInfo = info.superInfo!;
    assert(identical(superInfo, translator.recordInfo));

    // Different record classes can share the same struct, check if the struct
    // is already initialized
    if (struct.fields.isEmpty) {
      // Copy fields from superclass
      int superFieldIndex = 0;
      for (w.FieldType fieldType in superInfo.struct.fields) {
        info._addField(fieldType,
            fieldName: superInfo.struct.fieldNames[superFieldIndex]);
        superFieldIndex += 1;
      }

      for (Field field in info.cls!.fields) {
        info._addField(w.FieldType(translator.topType),
            fieldName: field.name.text);
      }
    }

    int fieldIdx = superInfo.struct.fields.length;
    for (Field field in info.cls!.fields) {
      translator.fieldIndex[field] = fieldIdx++;
    }
  }

  /// Create class info and Wasm struct for all classes.
  void collect() {
    // `0` is occupied by artificial non-Dart top class.
    const int firstClassId = 1;

    final classIdNumbering = translator.classIdNumbering =
        ClassIdNumbering._number(translator, masqueraded, firstClassId);
    final classIds = translator.classIdNumbering.classIds;
    final dfsOrder = translator.classIdNumbering.dfsOrder;

    _createStructForClassTop();

    // Class infos by class-id, will be populated by the calls to
    // [_createStructForClass] and [_createStructForRecordClass] below.
    translator.classes = List<ClassInfo>.filled(
        (classIdNumbering.maxDynamicSubmoduleClassId ??
                classIdNumbering.maxClassId) +
            1,
        topInfo);

    // Class infos in different order: Infos of super class and super interfaces
    // before own info.
    translator.classesSupersFirst = [topInfo];

    // Subclasses of the `_Closure` class are generated on the fly as fields
    // with function types are encountered. Therefore, `_Closure` class must
    // be early in the initialization order.
    _createStructForClass(classIds, translator.closureClass);

    // Similarly `_Type` is needed for type parameter fields in classes and
    // needs to be initialized before we encounter a class with type
    // parameters.
    _createStructForClass(classIds, translator.typeClass);

    // Similarly the `Record` class needs to be handled before the loop below as
    // the [_createStructForRecordClass] needs it.
    _createStructForClass(classIds, translator.coreTypes.recordClass);

    for (final cls in dfsOrder) {
      if (cls.superclass == translator.coreTypes.recordClass) {
        _createStructForRecordClass(classIds, cls);
      } else {
        _createStructForClass(classIds, cls);
      }
    }

    // Create representations of the classes (i.e. Wasm representation used to
    // represent objects of that Dart type).
    for (final cls in dfsOrder) {
      ClassInfo? representation;
      if (translator.dynamicModuleSupportEnabled &&
          cls.isDynamicSubmoduleExtendable(translator.coreTypes)) {
        assert(!translator.builtinTypes.containsKey(cls));

        // If a class is extendable in a dynamic submodule then we have to be
        // conservative and assume it might be a subclass of Object. The Object
        // class maps to topInfo because boxed values are a subtype of Object in
        // Dart but not of the object struct.
        representation = cls == translator.coreTypes.objectClass
            ? topInfo
            : translator.objectInfo;
      } else {
        void addRanges(List<Range> ranges) {
          for (final range in ranges) {
            for (int classId = range.start; classId <= range.end; ++classId) {
              final current = translator.classes[classId];
              if (representation == null) {
                representation = current;
                continue;
              }
              representation = _upperBound(representation!, current);
            }
          }
        }

        final mainModuleConcreteRange =
            classIdNumbering.getConcreteClassIdRangeForMainModule(cls);
        // Only non-extendable classes can get here so they should only have
        // concrete implementations in either the main module or the submodule,
        // not both.
        if (translator.isDynamicSubmodule && mainModuleConcreteRange.isEmpty) {
          final submoduleConcreteRange =
              classIdNumbering.getConcreteClassIdRangeForDynamicSubmodule(cls);
          addRanges(submoduleConcreteRange);
        } else {
          assert(classIdNumbering
              .getConcreteClassIdRangeForDynamicSubmodule(cls)
              .isEmpty);
          addRanges(mainModuleConcreteRange);
        }
      }
      final info = translator.classInfo[cls]!;
      representation ??= info;

      if (representation == topInfo) {
        info._repr = translator.topTypeNonNullable;
      } else {
        info._repr = representation!.nonNullableType;
      }
    }

    // Now that the representation types for all classes have been computed,
    // fill in the types of the fields in the generated Wasm structs.
    for (final info in translator.classesSupersFirst) {
      final superInfo = info.superInfo;
      if (superInfo == translator.recordInfo) {
        _generateRecordFields(info);
        continue;
      }

      if (superInfo != null && info.struct == superInfo.struct) {
        // We re-use the wasm struct of the base class. That implies this class
        // has no instance fields and we can re-use (if any) type parameter
        // slots from base classes.
        final cls = info.cls!;
        assert(!cls.fields.any((field) => field.isInstanceMember));
        for (final param in cls.typeParameters) {
          final match = info.typeParameterMatch[param];
          translator.typeParameterIndex[param] =
              translator.typeParameterIndex[match]!;
        }
      } else {
        _generateFields(info);
        // If this struct had the same number of fields as the base struct, we'd
        // re-use the wasm struct of the base class. So this struct must have
        // more fields.
        assert(superInfo == null ||
            superInfo.struct.fields.length < info.struct.fields.length);
      }
    }

    // Validate that all internally used fields have the expected indices.
    assert((() {
      FieldIndex.validate(translator);
      return true;
    })());
  }
}

class ClassIdNumbering {
  final Translator translator;
  final Map<Class, List<Class>> _subclasses;
  final Map<Class, List<Class>> _implementors;
  final Map<Class, List<Range>> _concreteSubclassIdRange;
  final Map<Class, List<Range>> _concreteSubclassIdRangeForDynamicSubmodule;
  final Set<Class> _masqueraded;

  final List<Class> dfsOrder;
  final Map<Class, ClassId> classIds;
  final int maxConcreteClassId;
  final int maxClassId;
  final int? maxDynamicSubmoduleConcreteClassId;
  final int? maxDynamicSubmoduleClassId;

  int get firstDynamicSubmoduleClassId => maxClassId + 1;

  ClassIdNumbering._(
      this.translator,
      this._subclasses,
      this._implementors,
      this._concreteSubclassIdRange,
      this._concreteSubclassIdRangeForDynamicSubmodule,
      this._masqueraded,
      this.dfsOrder,
      this.classIds,
      this.maxConcreteClassId,
      this.maxClassId,
      this.maxDynamicSubmoduleConcreteClassId,
      this.maxDynamicSubmoduleClassId);

  final Map<Class, Set<Class>> _transitiveImplementors = {};
  Set<Class> _getTransitiveImplementors(Class klass) {
    var transitiveImplementors = _transitiveImplementors[klass];
    if (transitiveImplementors != null) return transitiveImplementors;

    transitiveImplementors = {};

    List<Class>? classes = _subclasses[klass];
    if (classes != null) {
      for (final cls in classes) {
        transitiveImplementors.addAll(_getTransitiveImplementors(cls));
      }
    }
    classes = _implementors[klass];
    if (classes != null) {
      for (final cls in classes) {
        transitiveImplementors.add(cls);
        transitiveImplementors.addAll(_getTransitiveImplementors(cls));
      }
    }

    return _transitiveImplementors[klass] = transitiveImplementors;
  }

  /// Maps a class to a list of class id ranges that implement/extend the given
  /// class directly or transitively.
  ///
  /// If this function is invoked from a dynamic module enabled build then it
  /// should be wrapped with [DynamicModuleInfo.callClassIdBranch] so that the
  /// checked range will be updated.
  final Map<Class, List<Range>> _concreteClassIdRanges = {};
  List<Range> getConcreteClassIdRangeForMainModule(Class klass) {
    return _getConcreteClassIdRange(
        klass, _concreteClassIdRanges, _concreteSubclassIdRange);
  }

  final Map<Class, List<Range>> _concreteClassIdRangesForDynamicSubmodule = {};
  List<Range> getConcreteClassIdRangeForDynamicSubmodule(Class klass) {
    return _getConcreteClassIdRange(
        klass,
        _concreteClassIdRangesForDynamicSubmodule,
        _concreteSubclassIdRangeForDynamicSubmodule);
  }

  /// In case the [klass] is from a dynamic module the returned class id
  /// ranges may be relative. The caller has to ensure to use them
  /// appropriately.
  List<Range> getConcreteClassIdRangeForClass(Class klass) {
    // We cannot return class id ranges for [klass] if there can be more
    // classes in future dynamic module compilations.
    assert(!klass.isDynamicSubmoduleExtendable(translator.coreTypes));

    return !translator.isDynamicSubmodule ||
            klass.enclosingLibrary.isFromMainModule(translator.coreTypes)
        ? getConcreteClassIdRangeForMainModule(klass)
        : getConcreteClassIdRangeForDynamicSubmodule(klass);
  }

  List<Range> _getConcreteClassIdRange(Class klass,
      Map<Class, List<Range>> cache, Map<Class, List<Range>> subclasses) {
    var ranges = cache[klass];
    if (ranges != null) return ranges;

    ranges = [];
    final transitiveImplementors = _getTransitiveImplementors(klass);
    final subclassRanges = subclasses[klass] ?? const [];
    for (final range in subclassRanges) {
      ranges.add(range);
    }
    for (final implementor in transitiveImplementors) {
      final implementorRanges = subclasses[implementor] ?? const [];
      for (final range in implementorRanges) {
        ranges.add(range);
      }
    }
    ranges.normalize();

    return cache[klass] = ranges;
  }

  late final int firstNonMasqueradedInterfaceClassCid = (() {
    int lastMasqueradedClassId = 0;
    for (final cls in _masqueraded) {
      final ranges = getConcreteClassIdRangeForMainModule(cls);
      if (ranges.isNotEmpty) {
        lastMasqueradedClassId = max(lastMasqueradedClassId, ranges.last.end);
      }
    }
    return lastMasqueradedClassId + 1;
  })();

  static ClassIdNumbering _number(
      Translator translator, Set<Class> masqueraded, int firstClassId) {
    // Make graph from class to its subclasses.
    late final Class root;
    int? savedMaxConcreteClassId;
    int? savedMaxClassId;
    final subclasses = <Class, List<Class>>{};
    final implementors = <Class, List<Class>>{};
    final classIds = <Class, ClassId>{};

    if (translator.isDynamicSubmodule) {
      final savedMapping = translator.dynamicModuleInfo!.metadata.classMetadata;
      savedMapping.forEach((cls, metadata) {
        final classId = metadata.classId;
        classIds[cls] = AbsoluteClassId(classId);
        savedMaxClassId = max(savedMaxClassId ?? -2, classId);
        if (!cls.isAbstract && !cls.isAnonymousMixin) {
          savedMaxConcreteClassId = max(savedMaxConcreteClassId ?? -2, classId);
        }
      });
    }

    int concreteClassCount = 0;
    int abstractClassCount = 0;
    int anonymousMixinClassCount = 0;
    int alreadyAssignedCount = 0;
    for (final library in translator.component.libraries) {
      for (final cls in library.classes) {
        if (!classIds.containsKey(cls)) {
          if (cls.isAnonymousMixin) {
            assert(cls.isAbstract);
            anonymousMixinClassCount++;
          } else if (cls.isAbstract) {
            abstractClassCount++;
          } else {
            concreteClassCount++;
          }
        } else {
          alreadyAssignedCount++;
        }
        final superClass = cls.superclass;
        if (superClass == null) {
          root = cls;
        } else {
          subclasses.putIfAbsent(superClass, () => []).add(cls);
        }
        for (final interface in cls.implementedTypes) {
          implementors.putIfAbsent(interface.classNode, () => []).add(cls);
        }
      }
    }

    // We have a preference in which order we explore the direct subclasses of
    // `Object` as that allows us to keep class ids of certain hierarchies
    // low.
    // TODO: If we had statistics (e.g. number of class allocations, number of
    // times class is mentioned in type, ...) we'd have an estimate of how often
    // we have to encode a class-id. Then we could reorder the subclasses
    // depending on usage count of the subclass trees.
    final fixedOrder = <Class, int>{
      translator.coreTypes.boolClass: -9,
      translator.coreTypes.numClass: -8,
      translator.jsStringClass: -7,
      translator.typeClass: -6,
      translator.listBaseClass: -5,
      translator.hashFieldBaseClass: -4,
    };
    int order(Class klass) {
      final order = fixedOrder[klass];
      if (order != null) return order;

      final importUri = klass.enclosingLibrary.importUri.toString();
      if (importUri.startsWith('dart:')) {
        if (masqueraded.contains(klass)) return -1;
        // Bundle the typed data and collection together, they may not have
        // common base class except for `Object` but most of them have similar
        // selectors.
        if (importUri.startsWith('dart:typed_data')) return 0;
        if (importUri.startsWith('dart:collection')) return 1;
        if (importUri.startsWith('dart:core')) return 2;

        // The dart:wasm classes are marked as entrypoints, therefore retained by
        // TFA but they can never be instantiated, as they represent raw Wasm
        // types that aren't part of the Dart object hierarchy.
        // Move them to the very end of the class table.
        if (klass.name.startsWith('_WasmBase')) return 0xffffff;
        return 3;
      }
      return 10;
    }

    subclasses[root]!.sort((Class a, Class b) => order(a).compareTo(order(b)));

    // Traverse class inheritence graph in depth-first pre-order.
    void dfs(
        Class root, int Function(Class) pre, void Function(Class, int) post) {
      final classId = pre(root);
      final children = subclasses[root];
      if (children != null) {
        for (final sub in children) {
          dfs(sub, pre, post);
        }
      }
      post(root, classId);
    }

    // Make a list of the depth-first pre-order traversal.
    final dfsOrder = [
      ...?translator.dynamicModuleInfo?.metadata.dfsOrderClassIds
    ];
    final inDfsOrder = {...dfsOrder};

    // Maps any class to a dense range of concrete class ids that are subclasses
    // of that class.
    final concreteSubclassRanges = <Class, List<Range>>{};
    final concreteSubclassRangesForDynamicSubmodule = <Class, List<Range>>{};

    int nextConcreteClassId = (savedMaxClassId ?? (firstClassId - 1)) + 1;
    int nextAbstractClassId = nextConcreteClassId + concreteClassCount;

    if (classIds.isNotEmpty) {
      // Assumes that saved IDs form a contiguous region at the top of the
      // subclass tree. So if we encounter a node without a saved ID, then we do
      // not need to explore its children for saved IDs.
      Range? addSavedRanges(Class cls) {
        final savedClassId = classIds[cls];
        if (savedClassId == null) return null;
        final children = subclasses[cls] ?? const [];
        final isConcrete = !cls.isAbstract && !cls.isAnonymousMixin;
        Range? savedRange = isConcrete
            ? Range(savedClassId._localValue, savedClassId._localValue)
            : null;
        for (final child in children) {
          final childRange = addSavedRanges(child);
          if (childRange != null) {
            savedRange = savedRange == null
                ? Range(childRange.start, childRange.end)
                : Range(savedRange.start, max(savedRange.end, childRange.end));
          }
        }
        if (savedRange != null) {
          (concreteSubclassRanges[cls] ??= []).add(savedRange);
        }
        return savedRange;
      }

      addSavedRanges(root);
    }

    final subclassesRangesToBuild = savedMaxClassId != null
        ? concreteSubclassRangesForDynamicSubmodule
        : concreteSubclassRanges;

    dfs(root, (Class cls) {
      if (!inDfsOrder.contains(cls)) {
        dfsOrder.add(cls);
      }
      if (classIds.containsKey(cls)) return nextConcreteClassId;
      if (cls.isAnonymousMixin) {
        classIds[cls] = AbsoluteClassId(anonymousMixinClassId);
        return nextConcreteClassId;
      }
      if (cls.isAbstract) {
        var classId = classIds[cls];
        if (classId == null) {
          classIds[cls] = AbsoluteClassId(nextAbstractClassId++);
        }
        return nextConcreteClassId;
      }

      assert(classIds[cls] == null);
      final classId = nextConcreteClassId++;
      classIds[cls] = savedMaxClassId != null
          ? RelativeClassId(classId)
          : AbsoluteClassId(classId);
      return nextConcreteClassId - 1;
    }, (Class cls, int firstClassId) {
      final range = Range(firstClassId, nextConcreteClassId - 1);
      if (!range.isEmpty) {
        (subclassesRangesToBuild[cls] ??= []).add(range);
      }
    });

    assert(dfsOrder.length ==
        (concreteClassCount +
            abstractClassCount +
            anonymousMixinClassCount +
            alreadyAssignedCount));

    return ClassIdNumbering._(
        translator,
        subclasses,
        implementors,
        concreteSubclassRanges,
        concreteSubclassRangesForDynamicSubmodule,
        masqueraded,
        dfsOrder,
        classIds,
        savedMaxConcreteClassId ?? nextConcreteClassId - 1,
        savedMaxClassId ?? nextAbstractClassId - 1,
        savedMaxConcreteClassId == null ? null : nextConcreteClassId - 1,
        savedMaxClassId == null ? null : nextAbstractClassId - 1);
  }

  List<Range> getConcreteSubclassRanges(Class klass) =>
      _concreteSubclassIdRange[klass] ?? const [];
}

sealed class ClassId {
  int get _localValue;
}

final class AbsoluteClassId extends ClassId {
  final int value;

  @override
  int get _localValue => value;

  AbsoluteClassId(this.value);

  @override
  String toString() => 'Absolute($value)';
}

final class RelativeClassId extends ClassId {
  final int relativeValue;
  @override
  int get _localValue => relativeValue;

  RelativeClassId(this.relativeValue);

  @override
  String toString() => 'Relative($relativeValue)';
}

// A range of class ids, both ends inclusive.
class Range {
  final int start;
  final int end;

  Range._(this.start, this.end) : assert(start <= end);
  const Range.empty()
      : start = 0,
        end = -1;
  factory Range(int start, int end) {
    if (end < start) return Range.empty();
    return Range._(start, end);
  }

  void serialize(DataSerializer sink) {
    sink.writeInt(start);
    sink.writeInt(end);
  }

  factory Range.deserialize(DataDeserializer source) {
    final start = source.readInt();
    final end = source.readInt();
    return Range(start, end);
  }

  int get length => 1 + (end - start);
  bool get isEmpty => length == 0;

  bool contains(int id) => start <= id && id <= end;
  bool containsRange(Range other) => start <= other.start && other.end <= end;

  Range shiftBy(int offset) {
    if (isEmpty) return this;
    return Range(start + offset, end + offset);
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  bool operator ==(other) =>
      other is Range && other.start == start && other.end == end;

  @override
  String toString() => isEmpty ? '[]' : '[$start, $end]';
}

extension RangeListExtention on List<Range> {
  void normalize() {
    if (isEmpty) return;

    // Ensure we sort ranges by start of the range.
    sort((a, b) => a.start.compareTo(b.start));

    int current = 0;
    Range currentRange = this[0];
    for (int read = 1; read < length; ++read) {
      final nextRange = this[read];
      if (currentRange.isEmpty) {
        currentRange = nextRange;
        continue;
      }
      if (nextRange.isEmpty) continue;
      if (currentRange.containsRange(nextRange)) continue;
      if (currentRange.contains(nextRange.start) ||
          (currentRange.end + 1) == nextRange.start) {
        currentRange = Range(currentRange.start, nextRange.end);
        continue;
      }

      this[current++] = currentRange;
      currentRange = nextRange;
    }
    this[current++] = currentRange;
    length = current;
  }
}
