// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Wasm struct field indices for fields that are accessed explicitly from Wasm
/// code, e.g. in intrinsics.
///
/// The values are validated by asserts, typically either through
/// [ClassInfo.addField] (for manually added fields) or by a line in
/// [FieldIndex.validate] (for fields declared in Dart code).
class FieldIndex {
  static const classId = 0;
  static const boxValue = 1;
  static const identityHash = 1;
  static const stringArray = 2;
  static const closureContext = 2;
  static const closureFunction = 3;
  static const typedListBaseLength = 2;
  static const typedListArray = 3;
  static const typedListViewTypedData = 3;
  static const typedListViewOffsetInBytes = 4;
  static const byteDataViewLength = 2;
  static const byteDataViewTypedData = 3;
  static const byteDataViewOffsetInBytes = 4;

  static void validate(Translator translator) {
    void check(Class cls, String name, int expectedIndex) {
      assert(
          translator.fieldIndex[
                  cls.fields.firstWhere((f) => f.name.text == name)] ==
              expectedIndex,
          "Unexpected field index for ${cls.name}.$name");
    }

    check(translator.boxedBoolClass, "value", FieldIndex.boxValue);
    check(translator.boxedIntClass, "value", FieldIndex.boxValue);
    check(translator.boxedDoubleClass, "value", FieldIndex.boxValue);
    check(translator.oneByteStringClass, "_array", FieldIndex.stringArray);
    check(translator.twoByteStringClass, "_array", FieldIndex.stringArray);
    check(translator.functionClass, "context", FieldIndex.closureContext);
  }
}

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

  /// Wasm global containing the RTT for this class.
  late final w.DefinedGlobal rtt;

  /// The superclass for this class. This will usually be the Dart superclass,
  /// but there are a few exceptions, where the Wasm type hierarchy does not
  /// follow the Dart class hierarchy.
  final ClassInfo? superInfo;

  /// For every type parameter which is directly mapped to a type parameter in
  /// the superclass, this contains the corresponding superclass type
  /// parameter. These will reuse the corresponding type parameter field of
  /// the superclass.
  final Map<TypeParameter, TypeParameter> typeParameterMatch;

  /// The class whose struct is used as the type for variables of this type.
  /// This is a type which is a superclass of all subtypes of this type.
  late ClassInfo repr;

  /// All classes which implement this class. This is used to compute `repr`.
  final List<ClassInfo> implementedBy = [];

  late final w.RefType nullableType = w.RefType.def(struct, nullable: true);
  late final w.RefType nonNullableType = w.RefType.def(struct, nullable: false);

  w.RefType typeWithNullability(bool nullable) =>
      nullable ? nullableType : nonNullableType;

  ClassInfo(this.cls, this.classId, this.depth, this.struct, this.superInfo,
      ClassInfoCollector collector,
      {this.typeParameterMatch = const {}}) {
    if (collector.options.useRttGlobals) {
      rtt = collector.makeRtt(struct, superInfo);
    }
    implementedBy.add(this);
  }

  void addField(w.FieldType fieldType, [int? expectedIndex]) {
    assert(expectedIndex == null || expectedIndex == struct.fields.length);
    struct.fields.add(fieldType);
  }
}

ClassInfo upperBound(Iterable<ClassInfo> classes) {
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
  int nextClassId = 0;
  late final ClassInfo topInfo;

  late final w.FieldType typeType =
      w.FieldType(translator.classInfo[translator.typeClass]!.nullableType);

  ClassInfoCollector(this.translator);

  w.Module get m => translator.m;

  TranslatorOptions get options => translator.options;

  w.DefinedGlobal makeRtt(w.StructType struct, ClassInfo? superInfo) {
    assert(options.useRttGlobals);
    int depth = superInfo != null ? superInfo.depth + 1 : 0;
    final w.DefinedGlobal rtt =
        m.addGlobal(w.GlobalType(w.Rtt(struct, depth), mutable: false));
    final w.Instructions b = rtt.initializer;
    if (superInfo != null) {
      b.global_get(superInfo.rtt);
      b.rtt_sub(struct);
    } else {
      b.rtt_canon(struct);
    }
    b.end();
    return rtt;
  }

  void initializeTop() {
    final w.StructType struct = translator.structType("#Top");
    topInfo = ClassInfo(null, nextClassId++, 0, struct, null, this);
    translator.classes.add(topInfo);
    translator.classForHeapType[struct] = topInfo;
  }

  void initialize(Class cls) {
    ClassInfo? info = translator.classInfo[cls];
    if (info == null) {
      Class? superclass = cls.superclass;
      if (superclass == null) {
        ClassInfo superInfo = topInfo;
        final w.StructType struct =
            translator.structType(cls.name, superType: superInfo.struct);
        info = ClassInfo(
            cls, nextClassId++, superInfo.depth + 1, struct, superInfo, this);
        // Mark Top type as implementing Object to force the representation
        // type of Object to be Top.
        info.implementedBy.add(topInfo);
      } else {
        // Recursively initialize all supertypes before initializing this class.
        initialize(superclass);
        for (Supertype interface in cls.implementedTypes) {
          initialize(interface.classNode);
        }

        // In the Wasm type hierarchy, Object, bool and num sit directly below
        // the Top type. The implementation classes (_StringBase, _Type and the
        // box classes) sit directly below the public classes they implement.
        // All other classes sit below their superclass.
        ClassInfo superInfo = cls == translator.coreTypes.boolClass ||
                cls == translator.coreTypes.numClass
            ? topInfo
            : cls == translator.stringBaseClass ||
                    cls == translator.typeClass ||
                    translator.boxedClasses.values.contains(cls)
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
                typeParameterMatch[parameter] =
                    superInfo.cls!.typeParameters[i];
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
                cls.fields.where((f) => f.isInstanceMember).isEmpty &&
                cls != translator.typedListBaseClass &&
                cls != translator.typedListClass &&
                cls != translator.typedListViewClass &&
                cls != translator.byteDataViewClass;
        w.StructType struct = canReuseSuperStruct
            ? superInfo.struct
            : translator.structType(cls.name, superType: superInfo.struct);
        info = ClassInfo(
            cls, nextClassId++, superInfo.depth + 1, struct, superInfo, this,
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
    }
  }

  void computeRepresentation(ClassInfo info) {
    info.repr = upperBound(info.implementedBy);
  }

  void generateFields(ClassInfo info) {
    ClassInfo? superInfo = info.superInfo;
    if (superInfo == null) {
      // Top - add class id field
      info.addField(w.FieldType(w.NumType.i32), FieldIndex.classId);
    } else if (info.struct != superInfo.struct) {
      // Copy fields from superclass
      for (w.FieldType fieldType in superInfo.struct.fields) {
        info.addField(fieldType);
      }
      if (info.cls!.superclass == null) {
        // Object - add identity hash code field
        info.addField(w.FieldType(w.NumType.i32), FieldIndex.identityHash);
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
          info.addField(typeType);
        }
      }
      // Add fields for Dart instance fields
      for (Field field in info.cls!.fields) {
        if (field.isInstanceMember) {
          w.ValueType wasmType = translator.translateType(field.type);
          // TODO(askesc): Generalize this check for finer nullability control
          if (wasmType != w.RefType.data()) {
            wasmType = wasmType.withNullability(true);
          }
          translator.fieldIndex[field] = info.struct.fields.length;
          info.addField(w.FieldType(wasmType));
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

  void collect() {
    // Create class info and Wasm structs for all classes.
    initializeTop();
    for (Library library in translator.component.libraries) {
      for (Class cls in library.classes) {
        initialize(cls);
      }
    }

    // For each class, compute which Wasm struct should be used for the type of
    // variables bearing that class as their Dart type. This is the struct
    // corresponding to the least common supertype of all Dart classes
    // implementing this class.
    for (ClassInfo info in translator.classes) {
      computeRepresentation(info);
    }

    // Now that the representation types for all classes have been computed,
    // fill in the types of the fields in the generated Wasm structs.
    for (ClassInfo info in translator.classes) {
      generateFields(info);
    }

    // Add hidden fields of typed_data classes.
    addTypedDataFields();

    // Validate that all internally used fields have the expected indices.
    FieldIndex.validate(translator);
  }

  void addTypedDataFields() {
    ClassInfo typedListBaseInfo =
        translator.classInfo[translator.typedListBaseClass]!;
    typedListBaseInfo.addField(w.FieldType(w.NumType.i32, mutable: false),
        FieldIndex.typedListBaseLength);

    ClassInfo typedListInfo = translator.classInfo[translator.typedListClass]!;
    typedListInfo.addField(w.FieldType(w.NumType.i32, mutable: false),
        FieldIndex.typedListBaseLength);
    w.RefType bytesArrayType = w.RefType.def(
        translator.wasmArrayType(w.PackedType.i8, "i8"),
        nullable: false);
    typedListInfo.addField(
        w.FieldType(bytesArrayType, mutable: false), FieldIndex.typedListArray);

    w.RefType typedListType =
        w.RefType.def(typedListInfo.struct, nullable: false);

    ClassInfo typedListViewInfo =
        translator.classInfo[translator.typedListViewClass]!;
    typedListViewInfo.addField(w.FieldType(w.NumType.i32, mutable: false),
        FieldIndex.typedListBaseLength);
    typedListViewInfo.addField(w.FieldType(typedListType, mutable: false),
        FieldIndex.typedListViewTypedData);
    typedListViewInfo.addField(w.FieldType(w.NumType.i32, mutable: false),
        FieldIndex.typedListViewOffsetInBytes);

    ClassInfo byteDataViewInfo =
        translator.classInfo[translator.byteDataViewClass]!;
    byteDataViewInfo.addField(w.FieldType(w.NumType.i32, mutable: false),
        FieldIndex.byteDataViewLength);
    byteDataViewInfo.addField(w.FieldType(typedListType, mutable: false),
        FieldIndex.byteDataViewTypedData);
    byteDataViewInfo.addField(w.FieldType(w.NumType.i32, mutable: false),
        FieldIndex.byteDataViewOffsetInBytes);
  }
}
