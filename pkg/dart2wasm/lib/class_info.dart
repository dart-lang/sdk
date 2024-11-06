// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

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
  static const asyncSuspendStateCompleter = 5;
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
  static const vtableDynamicCallEntry = 0;
  static const vtableInstantiationTypeComparisonFunction = 1;
  static const vtableInstantiationTypeHashFunction = 2;
  static const vtableInstantiationFunction = 3;
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
  static const suspendStateCurrentException = 7;
  static const suspendStateCurrentExceptionStackTrace = 8;
  static const syncStarIteratorCurrent = 3;
  static const syncStarIteratorYieldStarIterable = 4;
  static const recordFieldBase = 2;
  static const jsStringImplRef = 2;
  static const ffiPointerAddress = 3;

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
    if (!translator.options.jsCompatibility) {
      check(translator.oneByteStringClass, "_array", FieldIndex.stringArray);
      check(translator.twoByteStringClass, "_array", FieldIndex.stringArray);
    }
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
  int get classId {
    if (_classId == anonymousMixinClassId) {
      throw 'Tried to access class ID of anonymous mixin $cls';
    }
    return _classId;
  }

  final int _classId;

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
  ClassInfo? masquerade;

  /// For every type parameter which is directly mapped to a type parameter in
  /// the superclass, this contains the corresponding superclass type
  /// parameter. These will reuse the corresponding type parameter field of
  /// the superclass.
  final Map<TypeParameter, TypeParameter> typeParameterMatch;

  /// The class whose struct is used as the type for variables of this type.
  /// This is a type which is a superclass of all subtypes of this type.
  ClassInfo get repr => _repr!;

  ClassInfo? _repr;

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

  void _addField(w.FieldType fieldType, [int? expectedIndex]) {
    assert(expectedIndex == null || expectedIndex == struct.fields.length);
    struct.fields.add(fieldType);
  }

  // This returns the types of all the class's fields (including
  // superclass fields), except for the class id and the identity hash
  List<w.ValueType> getClassFieldTypes() => [
        for (var fieldType in struct.fields.skip(FieldIndex.objectFieldBase))
          fieldType.type.unpacked
      ];
}

ClassInfo upperBound(ClassInfo a, ClassInfo b) {
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

  void _createStructForClassTop(int classCount) {
    final w.StructType struct = translator.typesBuilder.defineStruct("#Top");
    topInfo = ClassInfo(null, 0, 0, struct, null);
    translator.classForHeapType[struct] = topInfo;
  }

  void _createStructForClass(Map<Class, int> classIds, Class cls) {
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
      // the Top type. The implementation classes WasmStringBase and _Type sit
      // directly below the public classes they implement.
      // All other classes sit below their superclass.
      ClassInfo superInfo = cls == translator.coreTypes.boolClass ||
              cls == translator.coreTypes.numClass ||
              cls == translator.boxedIntClass ||
              cls == translator.boxedDoubleClass
          ? topInfo
          : (!translator.options.jsCompatibility &&
                      cls == translator.wasmStringBaseClass) ||
                  cls == translator.typeClass
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

      w.StructType struct = translator.typesBuilder
          .defineStruct(cls.name, superType: superInfo.struct);
      info = ClassInfo(cls, classId, superInfo.depth + 1, struct, superInfo,
          typeParameterMatch: typeParameterMatch);
    }
    translator.classesSupersFirst.add(info);
    translator.classInfo[cls] = info;
    translator.classForHeapType.putIfAbsent(info.struct, () => info!);
    if (classId != anonymousMixinClassId) {
      translator.classes[classId] = info;
    }
  }

  void _createStructForRecordClass(Map<Class, int> classIds, Class cls) {
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
    translator.classes[classId] = info;
    translator.classInfo[cls] = info;
    translator.classForHeapType.putIfAbsent(info.struct, () => info);
  }

  void _generateFields(ClassInfo info) {
    ClassInfo? superInfo = info.superInfo;
    if (superInfo == null) {
      // Top - add class id field
      info._addField(
          w.FieldType(w.NumType.i32, mutable: false), FieldIndex.classId);
    } else {
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
          final w.ValueType wasmType = translator.translateTypeOfField(field);
          translator.fieldIndex[field] = info.struct.fields.length;
          info._addField(w.FieldType(wasmType, mutable: !field.isFinal));
        }
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
    // `0` is occupied by artificial non-Dart top class.
    const int firstClassId = 1;

    final classIdNumbering = translator.classIdNumbering =
        ClassIdNumbering._number(translator, masqueraded, firstClassId);
    final classIds = translator.classIdNumbering.classIds;
    final dfsOrder = translator.classIdNumbering.dfsOrder;

    _createStructForClassTop(dfsOrder.length);

    // Class infos by class-id, will be populated by the calls to
    // [_createStructForClass] and [_createStructForRecordClass] below.
    translator.classes =
        List<ClassInfo>.filled(classIdNumbering.maxClassId + 1, topInfo);

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

    // Create representations of the classes (i.e. wasm representation used to
    // represent objects of that dart type).
    for (final cls in dfsOrder) {
      ClassInfo? representation;
      for (final range in classIdNumbering.getConcreteClassIdRanges(cls)) {
        for (int classId = range.start; classId <= range.end; ++classId) {
          final current = translator.classes[classId];
          if (representation == null) {
            representation = current;
            continue;
          }
          representation = upperBound(representation, current);
        }
      }
      final info = translator.classInfo[cls]!;
      info._repr = representation ?? info;
    }

    // Now that the representation types for all classes have been computed,
    // fill in the types of the fields in the generated Wasm structs.
    for (final info in translator.classesSupersFirst) {
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

class ClassIdNumbering {
  final Map<Class, List<Class>> _subclasses;
  final Map<Class, List<Class>> _implementors;
  final Map<Class, Range> _concreteSubclassIdRange;
  final Set<Class> _masqueraded;

  final List<Class> dfsOrder;
  final Map<Class, int> classIds;
  final int maxConcreteClassId;
  final int maxClassId;

  ClassIdNumbering._(
      this._subclasses,
      this._implementors,
      this._concreteSubclassIdRange,
      this._masqueraded,
      this.dfsOrder,
      this.classIds,
      this.maxConcreteClassId,
      this.maxClassId);

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

  // Maps a class to a list of class id ranges that implement/extend the given
  // class directly or transitively.
  final Map<Class, List<Range>> _concreteClassIdRanges = {};
  List<Range> getConcreteClassIdRanges(Class klass) {
    var ranges = _concreteClassIdRanges[klass];
    if (ranges != null) return ranges;

    ranges = [];
    final transitiveImplementors = _getTransitiveImplementors(klass);
    final range = _concreteSubclassIdRange[klass]!;
    if (!range.isEmpty) ranges.add(range);
    for (final implementor in transitiveImplementors) {
      final range = _concreteSubclassIdRange[implementor]!;
      if (!range.isEmpty) ranges.add(range);
    }
    ranges.normalize();

    return _concreteClassIdRanges[klass] = ranges;
  }

  late final int firstNonMasqueradedInterfaceClassCid = (() {
    int lastMasqueradedClassId = 0;
    for (final cls in _masqueraded) {
      final ranges = getConcreteClassIdRanges(cls);
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
    final subclasses = <Class, List<Class>>{};
    final implementors = <Class, List<Class>>{};
    int concreteClassCount = 0;
    int abstractClassCount = 0;
    int anonymousMixinClassCount = 0;
    for (final library in translator.component.libraries) {
      for (final cls in library.classes) {
        if (cls.isAnonymousMixin) {
          assert(cls.isAbstract);
          anonymousMixinClassCount++;
        } else if (cls.isAbstract) {
          abstractClassCount++;
        } else {
          concreteClassCount++;
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
      translator.coreTypes.boolClass: -10,
      translator.coreTypes.numClass: -9,
      if (!translator.options.jsCompatibility)
        translator.wasmStringBaseClass: -8,
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
        // TFA but they can never be instantiated, as they represent raw wasm
        // types that aren't part of the dart object hierarchy.
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
    final dfsOrder = <Class>[];
    final classIds = <Class, int>{};

    // Maps any class to a dense range of concrete class ids that are subclasses
    // of that class.
    final concreteSubclassRange = <Class, Range>{};

    int nextConcreteClassId = firstClassId;
    int nextAbstractClassId = firstClassId + concreteClassCount;
    dfs(root, (Class cls) {
      dfsOrder.add(cls);
      if (cls.isAnonymousMixin) {
        classIds[cls] = anonymousMixinClassId;
        return nextConcreteClassId;
      }
      if (cls.isAbstract) {
        var classId = classIds[cls];
        if (classId == null) classIds[cls] = nextAbstractClassId++;
        return nextConcreteClassId;
      }

      assert(classIds[cls] == null);
      classIds[cls] = nextConcreteClassId++;
      return nextConcreteClassId - 1;
    }, (Class cls, int firstClassId) {
      final range = Range(firstClassId, nextConcreteClassId - 1);
      concreteSubclassRange[cls] = range;
    });

    assert(dfsOrder.length ==
        (concreteClassCount + abstractClassCount + anonymousMixinClassCount));

    return ClassIdNumbering._(
        subclasses,
        implementors,
        concreteSubclassRange,
        masqueraded,
        dfsOrder,
        classIds,
        firstClassId + concreteClassCount - 1,
        firstClassId + concreteClassCount + abstractClassCount - 1);
  }

  Range getConcreteSubclassRange(Class klass) =>
      _concreteSubclassIdRange[klass]!;
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
