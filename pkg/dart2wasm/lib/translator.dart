// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/constants.dart';
import 'package:dart2wasm/dispatch_table.dart';
import 'package:dart2wasm/dynamic_dispatch.dart';
import 'package:dart2wasm/functions.dart';
import 'package:dart2wasm/globals.dart';
import 'package:dart2wasm/param_info.dart';
import 'package:dart2wasm/reference_extensions.dart';
import 'package:dart2wasm/types.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchySubtypes, ClosedWorldClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/type_environment.dart';
import 'package:vm/metadata/direct_call.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Options controlling the translation.
class TranslatorOptions {
  bool exportAll = false;
  bool importSharedMemory = false;
  bool inlining = false;
  int inliningLimit = 3;
  bool nameSection = true;
  bool polymorphicSpecialization = false;
  bool printKernel = false;
  bool printWasm = false;
  int? sharedMemoryMaxPages;
  bool stringDataSegments = false;
  List<int>? watchPoints = null;
}

typedef CodeGenCallback = void Function(w.Instructions);

/// The main entry point for the translation from kernel to Wasm and the hub for
/// all global state in the compiler.
///
/// This class also contains utility methods for types and code generation used
/// throughout the compiler.
class Translator {
  // Options for the translation.
  final TranslatorOptions options;

  // Kernel input and context.
  final Component component;
  final List<Library> libraries;
  final CoreTypes coreTypes;
  final TypeEnvironment typeEnvironment;
  final ClosedWorldClassHierarchy hierarchy;
  late final ClassHierarchySubtypes subtypes;

  // Classes and members referenced specifically by the compiler.
  late final Class wasmTypesBaseClass;
  late final Class wasmArrayBaseClass;
  late final Class wasmAnyRefClass;
  late final Class wasmExternRefClass;
  late final Class wasmFuncRefClass;
  late final Class wasmEqRefClass;
  late final Class wasmDataRefClass;
  late final Class wasmFunctionClass;
  late final Class wasmTableClass;
  late final Class boxedBoolClass;
  late final Class boxedIntClass;
  late final Class boxedDoubleClass;
  late final Class functionClass;
  late final Class listBaseClass;
  late final Class fixedLengthListClass;
  late final Class growableListClass;
  late final Class immutableListClass;
  late final Class immutableMapClass;
  late final Class immutableSetClass;
  late final Class hashFieldBaseClass;
  late final Class stringBaseClass;
  late final Class oneByteStringClass;
  late final Class twoByteStringClass;
  late final Class typeClass;
  late final Class neverTypeClass;
  late final Class dynamicTypeClass;
  late final Class voidTypeClass;
  late final Class nullTypeClass;
  late final Class futureOrTypeClass;
  late final Class interfaceTypeClass;
  late final Class functionTypeClass;
  late final Class genericFunctionTypeClass;
  late final Class interfaceTypeParameterTypeClass;
  late final Class genericFunctionTypeParameterTypeClass;
  late final Class namedParameterClass;
  late final Class stackTraceClass;
  late final Class ffiCompoundClass;
  late final Class ffiPointerClass;
  late final Class typedListBaseClass;
  late final Class typedListClass;
  late final Class typedListViewClass;
  late final Class byteDataViewClass;
  late final Class typeErrorClass;
  late final Class typeUniverseClass;
  late final Class symbolClass;
  late final Class invocationClass;
  late final Procedure wasmFunctionCall;
  late final Procedure wasmTableCallIndirect;
  late final Procedure stackTraceCurrent;
  late final Procedure asyncHelper;
  late final Procedure awaitHelper;
  late final Procedure stringEquals;
  late final Procedure stringInterpolate;
  late final Procedure throwNullCheckError;
  late final Procedure throwThrowNullError;
  late final Procedure throwAsCheckError;
  late final Procedure throwWasmRefError;
  late final Procedure mapFactory;
  late final Procedure mapPut;
  late final Procedure setFactory;
  late final Procedure setAdd;
  late final Procedure hashImmutableIndexNullable;
  late final Procedure isSubtype;
  late final Procedure objectRuntimeType;
  late final Procedure typeAsNullable;
  late final Procedure objectNoSuchMethod;
  late final Procedure invocationGetterFactory;
  late final Procedure invocationSetterFactory;
  late final Procedure invocationMethodFactory;
  late final Procedure invocationGenericMethodFactory;
  late final Procedure nullToString;
  late final Procedure nullNoSuchMethod;
  late final Procedure createNormalizedFutureOrType;
  late final Map<Class, w.StorageType> builtinTypes;
  late final Map<w.ValueType, Class> boxedClasses;

  // Other parts of the global compiler state.
  late final ClosureLayouter closureLayouter;
  late final ClassInfoCollector classInfoCollector;
  late final DispatchTable dispatchTable;
  late final Globals globals;
  late final Constants constants;
  late final Types types;
  late final FunctionCollector functions;
  late final DynamicDispatcher dynamics;

  // Information about the program used and updated by the various phases.
  final List<ClassInfo> classes = [];
  final Map<Class, ClassInfo> classInfo = {};
  final Map<w.HeapType, ClassInfo> classForHeapType = {};
  final Map<Field, int> fieldIndex = {};
  final Map<TypeParameter, int> typeParameterIndex = {};
  final Map<Reference, ParameterInfo> staticParamInfo = {};
  final Map<Field, w.DefinedTable> declaredTables = {};
  late Procedure mainFunction;
  late final w.Module m;
  late final w.DefinedFunction initFunction;
  late final w.ValueType voidMarker;
  // Lazily create exception tag if used.
  late final w.Tag exceptionTag = createExceptionTag();
  // Lazily import FFI memory if used.
  late final w.Memory ffiMemory = m.importMemory("ffi", "memory",
      options.importSharedMemory, 0, options.sharedMemoryMaxPages);

  // Caches for when identical source constructs need a common representation.
  final Map<w.StorageType, w.ArrayType> arrayTypeCache = {};
  final Map<w.BaseFunction, w.DefinedGlobal> functionRefCache = {};
  final Map<Procedure, ClosureImplementation> tearOffFunctionCache = {};

  ClassInfo get topInfo => classes[0];
  ClassInfo get objectInfo => classInfo[coreTypes.objectClass]!;
  ClassInfo get stackTraceInfo => classInfo[stackTraceClass]!;

  Translator(this.component, this.coreTypes, this.typeEnvironment, this.options)
      : libraries = component.libraries,
        hierarchy =
            ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy {
    subtypes = hierarchy.computeSubtypesInformation();
    closureLayouter = ClosureLayouter(this);
    classInfoCollector = ClassInfoCollector(this);
    dispatchTable = DispatchTable(this);
    functions = FunctionCollector(this);
    types = Types(this);
    dynamics = DynamicDispatcher(this);

    Library lookupLibrary(String importUriString) => component.libraries
        .firstWhere((l) => l.importUri == Uri.parse(importUriString));

    Class Function(String) makeLookup(String importUriString) {
      return (name) => lookupLibrary(importUriString)
          .classes
          .firstWhere((c) => c.name == name);
    }

    Class Function(String) lookupCore = makeLookup("dart:core");
    Class Function(String) lookupCollection = makeLookup("dart:collection");
    Class Function(String) lookupFfi = makeLookup("dart:ffi");
    Class Function(String) lookupInternal = makeLookup("dart:_internal");
    Class Function(String) lookupTypedData = makeLookup("dart:typed_data");
    Class Function(String) lookupWasm = makeLookup("dart:wasm");

    wasmTypesBaseClass = lookupWasm("_WasmBase");
    wasmArrayBaseClass = lookupWasm("_WasmArray");
    wasmAnyRefClass = lookupWasm("WasmAnyRef");
    wasmExternRefClass = lookupWasm("WasmExternRef");
    wasmFuncRefClass = lookupWasm("WasmFuncRef");
    wasmEqRefClass = lookupWasm("WasmEqRef");
    wasmDataRefClass = lookupWasm("WasmDataRef");
    wasmFunctionClass = lookupWasm("WasmFunction");
    wasmTableClass = lookupWasm("WasmTable");
    boxedBoolClass = lookupCore("_BoxedBool");
    boxedIntClass = lookupCore("_BoxedInt");
    boxedDoubleClass = lookupCore("_BoxedDouble");
    functionClass = lookupCore("_Function");
    fixedLengthListClass = lookupCore("_List");
    listBaseClass = lookupCore("_ListBase");
    growableListClass = lookupCore("_GrowableList");
    immutableListClass = lookupCore("_ImmutableList");
    immutableMapClass = lookupCollection("_WasmImmutableLinkedHashMap");
    immutableSetClass = lookupCollection("_WasmImmutableLinkedHashSet");
    hashFieldBaseClass = lookupCollection("_HashFieldBase");
    stringBaseClass = lookupCore("_StringBase");
    oneByteStringClass = lookupCore("_OneByteString");
    twoByteStringClass = lookupCore("_TwoByteString");
    typeClass = lookupCore("_Type");
    neverTypeClass = lookupCore("_NeverType");
    dynamicTypeClass = lookupCore("_DynamicType");
    voidTypeClass = lookupCore("_VoidType");
    nullTypeClass = lookupCore("_NullType");
    futureOrTypeClass = lookupCore("_FutureOrType");
    interfaceTypeClass = lookupCore("_InterfaceType");
    functionTypeClass = lookupCore("_FunctionType");
    genericFunctionTypeClass = lookupCore("_GenericFunctionType");
    interfaceTypeParameterTypeClass = lookupCore("_InterfaceTypeParameterType");
    genericFunctionTypeParameterTypeClass =
        lookupCore("_GenericFunctionTypeParameterType");
    namedParameterClass = lookupCore("_NamedParameter");
    stackTraceClass = lookupCore("StackTrace");
    typeUniverseClass = lookupCore("_TypeUniverse");
    ffiCompoundClass = lookupFfi("_Compound");
    ffiPointerClass = lookupFfi("Pointer");
    typeErrorClass = lookupCore("_TypeError");
    typedListBaseClass = lookupTypedData("_TypedListBase");
    typedListClass = lookupTypedData("_TypedList");
    typedListViewClass = lookupTypedData("_TypedListView");
    byteDataViewClass = lookupTypedData("_ByteDataView");
    symbolClass = lookupInternal("Symbol");
    wasmFunctionCall =
        wasmFunctionClass.procedures.firstWhere((p) => p.name.text == "call");
    wasmTableCallIndirect = wasmTableClass.procedures
        .firstWhere((p) => p.name.text == "callIndirect");
    stackTraceCurrent =
        stackTraceClass.procedures.firstWhere((p) => p.name.text == "current");
    asyncHelper = lookupLibrary("dart:async")
        .procedures
        .firstWhere((p) => p.name.text == "_asyncHelper");
    awaitHelper = lookupLibrary("dart:async")
        .procedures
        .firstWhere((p) => p.name.text == "_awaitHelper");
    stringEquals =
        stringBaseClass.procedures.firstWhere((p) => p.name.text == "==");
    stringInterpolate = stringBaseClass.procedures
        .firstWhere((p) => p.name.text == "_interpolate");
    throwNullCheckError = typeErrorClass.procedures
        .firstWhere((p) => p.name.text == "_throwNullCheckError");
    throwThrowNullError = typeErrorClass.procedures
        .firstWhere((p) => p.name.text == "_throwThrowNullError");
    throwAsCheckError = typeErrorClass.procedures
        .firstWhere((p) => p.name.text == "_throwAsCheckError");
    throwWasmRefError = typeErrorClass.procedures
        .firstWhere((p) => p.name.text == "_throwWasmRefError");
    mapFactory = lookupCollection("LinkedHashMap").procedures.firstWhere(
        (p) => p.kind == ProcedureKind.Factory && p.name.text == "_default");
    mapPut = lookupCollection("_CompactLinkedCustomHashMap")
        .superclass! // _LinkedHashMapMixin<K, V>
        .procedures
        .firstWhere((p) => p.name.text == "[]=");
    setFactory = lookupCollection("LinkedHashSet").procedures.firstWhere(
        (p) => p.kind == ProcedureKind.Factory && p.name.text == "_default");
    setAdd = lookupCollection("_CompactLinkedCustomHashSet")
        .superclass! // _LinkedHashSetMixin<K, V>
        .procedures
        .firstWhere((p) => p.name.text == "add");
    hashImmutableIndexNullable = lookupCollection("_HashAbstractImmutableBase")
        .procedures
        .firstWhere((p) => p.name.text == "_indexNullable");
    isSubtype = lookupLibrary("dart:core")
        .procedures
        .firstWhere((p) => p.name.text == "_isSubtype");
    objectRuntimeType = lookupCore("Object")
        .procedures
        .firstWhere((p) => p.name.text == "_runtimeType");
    typeAsNullable = lookupCore("_Type")
        .procedures
        .firstWhere((p) => p.name.text == "asNullable");
    objectNoSuchMethod = lookupCore("Object")
        .procedures
        .firstWhere((p) => p.name.text == "noSuchMethod");
    invocationClass = lookupCore('Invocation');
    invocationGetterFactory =
        invocationClass.procedures.firstWhere((p) => p.name.text == "getter");
    invocationSetterFactory =
        invocationClass.procedures.firstWhere((p) => p.name.text == "setter");
    invocationMethodFactory =
        invocationClass.procedures.firstWhere((p) => p.name.text == "method");
    invocationGenericMethodFactory = invocationClass.procedures
        .firstWhere((p) => p.name.text == "genericMethod");
    nullToString = lookupCore("Object")
        .procedures
        .firstWhere((p) => p.name.text == "_nullToString");
    nullNoSuchMethod = lookupCore("Object")
        .procedures
        .firstWhere((p) => p.name.text == "_nullNoSuchMethod");
    createNormalizedFutureOrType = typeUniverseClass.procedures
        .firstWhere((p) => p.name.text == "createNormalizedFutureOrType");
    builtinTypes = {
      coreTypes.boolClass: w.NumType.i32,
      coreTypes.intClass: w.NumType.i64,
      coreTypes.doubleClass: w.NumType.f64,
      wasmAnyRefClass: const w.RefType.any(nullable: false),
      wasmExternRefClass: const w.RefType.extern(nullable: false),
      wasmFuncRefClass: const w.RefType.func(nullable: false),
      wasmEqRefClass: const w.RefType.eq(nullable: false),
      wasmDataRefClass: const w.RefType.data(nullable: false),
      boxedBoolClass: w.NumType.i32,
      boxedIntClass: w.NumType.i64,
      boxedDoubleClass: w.NumType.f64,
      lookupWasm("WasmI8"): w.PackedType.i8,
      lookupWasm("WasmI16"): w.PackedType.i16,
      lookupWasm("WasmI32"): w.NumType.i32,
      lookupWasm("WasmI64"): w.NumType.i64,
      lookupWasm("WasmF32"): w.NumType.f32,
      lookupWasm("WasmF64"): w.NumType.f64,
      ffiPointerClass: w.NumType.i32,
    };
    boxedClasses = {
      w.NumType.i32: boxedBoolClass,
      w.NumType.i64: boxedIntClass,
      w.NumType.f64: boxedDoubleClass,
    };
  }

  // Finds the `main` method for a given library which is assumed to contain
  // `main`, either directly or indirectly.
  Procedure _findMainMethod(Library entryLibrary) {
    // First check to see if the library itself contains main.
    for (final procedure in entryLibrary.procedures) {
      if (procedure.name.text == 'main') {
        return procedure;
      }
    }

    // In some cases, a main method is defined in another file, and then
    // exported. In these cases, we search for the main method in
    // [additionalExports].
    for (final export in entryLibrary.additionalExports) {
      if (export.node is Procedure && export.asProcedure.name.text == 'main') {
        return export.asProcedure;
      }
    }
    throw ArgumentError(
        'Entry uri ${entryLibrary.fileUri} has no main method.');
  }

  Uint8List translate() {
    m = w.Module(watchPoints: options.watchPoints);
    voidMarker = w.RefType.def(w.StructType("void"), nullable: true);

    dynamics.collect();
    closureLayouter.collect();
    classInfoCollector.collect();

    functions.collectImportsAndExports();
    mainFunction = _findMainMethod(libraries.first);

    initFunction =
        m.addFunction(m.addFunctionType(const [], const []), "#init");
    m.startFunction = initFunction;

    globals = Globals(this);
    constants = Constants(this);

    dispatchTable.build();

    m.exportFunction("\$main", generateEntryFunction(mainFunction.reference));
    functions.initialize();
    while (functions.worklist.isNotEmpty) {
      Reference reference = functions.worklist.removeLast();
      Member member = reference.asMember;
      var function =
          functions.getExistingFunction(reference) as w.DefinedFunction;

      String canonicalName = "$member";
      if (reference.isSetter) {
        canonicalName = "$canonicalName=";
      } else if (reference.isGetter || reference.isTearOffReference) {
        int dot = canonicalName.indexOf('.');
        canonicalName = canonicalName.substring(0, dot + 1) +
            '=' +
            canonicalName.substring(dot + 1);
      }
      canonicalName = member.enclosingLibrary == libraries.first
          ? canonicalName
          : "${member.enclosingLibrary.importUri} $canonicalName";

      String? exportName = functions.exports[reference];

      if (options.printKernel || options.printWasm) {
        if (exportName != null) {
          print("#${function.index}: $canonicalName (exported as $exportName)");
        } else {
          print("#${function.index}: $canonicalName");
        }
        print(member.function
            ?.computeFunctionType(Nullability.nonNullable)
            .toStringInternal());
      }
      if (options.printKernel) {
        if (member is Constructor) {
          Class cls = member.enclosingClass;
          for (Field field in cls.fields) {
            if (field.isInstanceMember && field.initializer != null) {
              print("${field.name}: ${field.initializer}");
            }
          }
          for (Initializer initializer in member.initializers) {
            print(initializer);
          }
        }
        Statement? body = member.function?.body;
        if (body != null) {
          print(body);
        }
        if (!options.printWasm) print("");
      }

      if (options.exportAll && exportName == null) {
        m.exportFunction(canonicalName, function);
      }
      var codeGen = CodeGenerator(this, function, reference);
      codeGen.generate();

      if (options.printWasm) {
        print(function.type);
        print(function.body.trace);
      }

      for (Lambda lambda in codeGen.closures.lambdas.values) {
        w.DefinedFunction lambdaFunction =
            CodeGenerator(this, lambda.function, reference)
                .generateLambda(lambda, codeGen.closures);
        _printFunction(lambdaFunction, "$canonicalName (closure)");
      }
    }

    dispatchTable.output();
    initFunction.body.end();

    for (ConstantInfo info in constants.constantInfo.values) {
      w.DefinedFunction? function = info.function;
      if (function != null) {
        _printFunction(function, info.constant);
      } else {
        if (options.printWasm) {
          print("Global #${info.global.index}: ${info.constant}");
          print(info.global.initializer.trace);
        }
      }
    }
    _printFunction(initFunction, "init");

    return m.encode(emitNameSection: options.nameSection);
  }

  void _printFunction(w.DefinedFunction function, Object name) {
    if (options.printWasm) {
      print("#${function.index}: $name");
      print(function.body.trace);
    }
  }

  w.DefinedFunction generateEntryFunction(Reference mainReference) {
    final ParameterInfo paramInfo = paramInfoFor(mainReference);
    assert(paramInfo.typeParamCount == 0);
    final w.BaseFunction mainFunction = functions.getFunction(mainReference);
    final w.DefinedFunction entry =
        m.addFunction(m.addFunctionType(const [], const []), "\$main");
    final w.Instructions b = entry.body;

    if (paramInfo.positional.isNotEmpty) {
      // Supply dummy commandline arguments
      constants.instantiateConstant(
          entry,
          b,
          ListConstant(coreTypes.stringNonNullableRawType, const []),
          mainFunction.type.inputs[0]);
    }
    if (paramInfo.positional.length > 1) {
      // Supply dummy isolate
      constants.instantiateConstant(
          entry, b, NullConstant(), mainFunction.type.inputs[1]);
    }
    for (int i = 2; i < paramInfo.positional.length; i++) {
      // Supply default values for positional parameters
      constants.instantiateConstant(
          entry, b, paramInfo.positional[i]!, mainFunction.type.inputs[i]);
    }
    for (String name in paramInfo.names) {
      // Supply default values for named parameters
      constants.instantiateConstant(entry, b, paramInfo.named[name]!,
          mainFunction.type.inputs[paramInfo.nameIndex[name]!]);
    }
    b.call(mainFunction);
    convertType(entry, outputOrVoid(mainFunction.type.outputs), voidMarker);
    b.end();

    return entry;
  }

  Class classForType(DartType type) {
    return type is InterfaceType
        ? type.classNode
        : type is TypeParameterType
            ? classForType(type.bound)
            : coreTypes.objectClass;
  }

  /// Creates a [Tag] for a void [FunctionType] with two parameters,
  /// a [topInfo.nonNullableType] parameter to hold an exception, and a
  /// [stackTraceInfo.nonNullableType] to hold a stack trace. This single
  /// exception tag is used to throw and catch all Dart exceptions.
  w.Tag createExceptionTag() {
    w.FunctionType tagType = m.addFunctionType(
        [topInfo.nonNullableType, stackTraceInfo.nonNullableType], const []);
    w.Tag tag = m.addTag(tagType);
    return tag;
  }

  w.ValueType translateType(DartType type) {
    w.StorageType wasmType = translateStorageType(type);
    if (wasmType is w.ValueType) return wasmType;
    throw "Packed types are only allowed in arrays and fields";
  }

  bool _hasSuperclass(Class cls, Class superclass) {
    while (cls.superclass != null) {
      cls = cls.superclass!;
      if (cls == superclass) return true;
    }
    return false;
  }

  bool isWasmType(Class cls) => _hasSuperclass(cls, wasmTypesBaseClass);

  bool isFfiCompound(Class cls) => _hasSuperclass(cls, ffiCompoundClass);

  w.StorageType typeForInfo(ClassInfo info, bool nullable,
      {bool ensureBoxed = false}) {
    Class? cls = info.cls;
    if (cls != null) {
      w.StorageType? builtin = builtinTypes[cls];
      if (builtin != null) {
        if (!nullable && (!ensureBoxed || cls == ffiPointerClass)) {
          return builtin;
        }
        if (isWasmType(cls)) {
          if (builtin.isPrimitive) throw "Wasm numeric types can't be nullable";
          return (builtin as w.RefType).withNullability(nullable);
        }
        if (cls == ffiPointerClass) throw "FFI types can't be nullable";
        Class? boxedClass = boxedClasses[builtin];
        if (boxedClass != null) {
          info = classInfo[boxedClass]!;
        }
      } else if (isFfiCompound(cls)) {
        if (nullable) throw "FFI types can't be nullable";
        return w.NumType.i32;
      }
    }
    return w.RefType.def(info.repr.struct, nullable: nullable);
  }

  w.StorageType translateStorageType(DartType type) {
    if (type is InterfaceType) {
      if (type.classNode.superclass == wasmArrayBaseClass) {
        DartType elementType = type.typeArguments.single;
        return w.RefType.def(arrayTypeForDartType(elementType),
            nullable: false);
      }
      if (type.classNode == wasmFunctionClass) {
        DartType functionType = type.typeArguments.single;
        if (functionType is! FunctionType) {
          throw "The type argument of a WasmFunction must be a function type";
        }
        if (functionType.typeParameters.isNotEmpty ||
            functionType.namedParameters.isNotEmpty ||
            functionType.requiredParameterCount !=
                functionType.positionalParameters.length) {
          throw "A WasmFunction can't have optional/type parameters";
        }
        List<w.ValueType> inputs = [
          for (DartType type in functionType.positionalParameters)
            translateType(type)
        ];
        List<w.ValueType> outputs = [
          if (functionType.returnType != const VoidType())
            translateType(functionType.returnType)
        ];
        w.FunctionType wasmType = m.addFunctionType(inputs, outputs);
        return w.RefType.def(wasmType, nullable: type.isPotentiallyNullable);
      }
      return typeForInfo(
          classInfo[type.classNode]!, type.isPotentiallyNullable);
    }
    if (type is DynamicType || type is VoidType) {
      return topInfo.nullableType;
    }
    // TODO(joshualitt): When we add support to `wasm_builder` for bottom heap
    // types, we should return bottom heap type here.
    if (type is NullType || type is NeverType) {
      return topInfo.nullableType;
    }
    if (type is TypeParameterType) {
      return translateStorageType(type.isPotentiallyNullable
          ? type.bound.withDeclaredNullability(type.nullability)
          : type.bound);
    }
    if (type is IntersectionType) {
      return translateStorageType(type.left);
    }
    if (type is FutureOrType) {
      return topInfo.typeWithNullability(type.isPotentiallyNullable);
    }
    if (type is FunctionType) {
      ClosureRepresentation? representation =
          closureLayouter.getClosureRepresentation(
              type.typeParameters.length,
              type.positionalParameters.length,
              type.namedParameters.map((p) => p.name).toList());
      return w.RefType.def(
          representation != null
              ? representation.closureStruct
              : classInfo[typeClass]!.struct,
          nullable: type.isPotentiallyNullable);
    }
    throw "Unsupported type ${type.runtimeType}";
  }

  w.ArrayType arrayTypeForDartType(DartType type) {
    while (type is TypeParameterType) {
      type = type.bound;
    }
    return wasmArrayType(
        translateStorageType(type), type.toText(defaultAstTextStrategy));
  }

  w.ArrayType wasmArrayType(w.StorageType type, String name) {
    return arrayTypeCache.putIfAbsent(type,
        () => m.addArrayType("Array<$name>", elementType: w.FieldType(type)));
  }

  w.DefinedGlobal makeFunctionRef(w.BaseFunction f) {
    return functionRefCache.putIfAbsent(f, () {
      w.DefinedGlobal global = m.addGlobal(
          w.GlobalType(w.RefType.def(f.type, nullable: false), mutable: false));
      global.initializer.ref_func(f);
      global.initializer.end();
      return global;
    });
  }

  ClosureImplementation getTearOffClosure(Procedure member) {
    return tearOffFunctionCache.putIfAbsent(member, () {
      assert(member.kind == ProcedureKind.Method);
      w.BaseFunction target = functions.getFunction(member.reference);
      return getClosure(member.function, target, paramInfoFor(member.reference),
          "$member tear-off");
    });
  }

  ClosureImplementation getClosure(FunctionNode functionNode,
      w.BaseFunction target, ParameterInfo paramInfo, String name) {
    // The target function takes an extra initial parameter if it's a function
    // expression / local function (which takes a context) or a tear-off of an
    // instance method (which takes a receiver).
    bool takesContextOrReceiver =
        paramInfo.member == null || paramInfo.member!.isInstanceMember;

    // Look up the closure representation for the signature.
    int typeCount = functionNode.typeParameters.length;
    int positionalCount = functionNode.positionalParameters.length;
    List<String> names =
        functionNode.namedParameters.map((p) => p.name!).toList();
    assert(typeCount == paramInfo.typeParamCount);
    assert(positionalCount <= paramInfo.positional.length);
    assert(names.length <= paramInfo.named.length);
    assert(target.type.inputs.length ==
        (takesContextOrReceiver ? 1 : 0) +
            paramInfo.typeParamCount +
            paramInfo.positional.length +
            paramInfo.named.length);
    ClosureRepresentation representation = closureLayouter
        .getClosureRepresentation(typeCount, positionalCount, names)!;
    assert(representation.vtableStruct.fields.length ==
        representation.vtableBaseIndex +
            (1 + positionalCount) +
            representation.nameCombinations.length);

    List<w.DefinedFunction> functions = [];

    bool canBeCalledWith(int posArgCount, List<String> argNames) {
      if (posArgCount < functionNode.requiredParameterCount) {
        return false;
      }
      int i = 0, j = 0;
      while (i < argNames.length && j < functionNode.namedParameters.length) {
        int comp = argNames[i].compareTo(functionNode.namedParameters[j].name!);
        if (comp < 0) return false;
        if (comp > 0) {
          if (functionNode.namedParameters[j++].isRequired) return false;
          continue;
        }
        i++;
        j++;
      }
      if (i < argNames.length) return false;
      while (j < functionNode.namedParameters.length) {
        if (functionNode.namedParameters[j++].isRequired) return false;
      }
      return true;
    }

    w.DefinedFunction makeTrampoline(
        w.FunctionType signature, int posArgCount, List<String> argNames) {
      w.DefinedFunction function = m.addFunction(signature, name);
      w.Instructions b = function.body;
      int targetIndex = 0;
      if (takesContextOrReceiver) {
        w.Local receiver = function.locals[0];
        b.local_get(receiver);
        convertType(function, receiver.type, target.type.inputs[targetIndex++]);
      }
      int argIndex = 1;
      for (int i = 0; i < typeCount; i++) {
        b.local_get(function.locals[argIndex++]);
        targetIndex++;
      }
      for (int i = 0; i < paramInfo.positional.length; i++) {
        if (i < posArgCount) {
          w.Local arg = function.locals[argIndex++];
          b.local_get(arg);
          convertType(function, arg.type, target.type.inputs[targetIndex++]);
        } else {
          constants.instantiateConstant(function, b, paramInfo.positional[i]!,
              target.type.inputs[targetIndex++]);
        }
      }
      int argNameIndex = 0;
      for (int i = 0; i < paramInfo.names.length; i++) {
        String argName = paramInfo.names[i];
        if (argNameIndex < argNames.length &&
            argNames[argNameIndex] == argName) {
          w.Local arg = function.locals[argIndex++];
          b.local_get(arg);
          convertType(function, arg.type, target.type.inputs[targetIndex++]);
          argNameIndex++;
        } else {
          constants.instantiateConstant(function, b, paramInfo.named[argName]!,
              target.type.inputs[targetIndex++]);
        }
      }
      assert(argIndex == signature.inputs.length);
      assert(targetIndex == target.type.inputs.length);
      assert(argNameIndex == argNames.length);

      b.call(target);

      convertType(function, outputOrVoid(target.type.outputs),
          outputOrVoid(signature.outputs));
      b.end();

      return function;
    }

    void fillVtableEntry(
        w.Instructions ib, int posArgCount, List<String> argNames) {
      int fieldIndex = representation.vtableBaseIndex + functions.length;
      assert(fieldIndex ==
          representation.fieldIndexForSignature(posArgCount, argNames));
      w.FunctionType signature =
          (representation.vtableStruct.fields[fieldIndex].type as w.RefType)
              .heapType as w.FunctionType;
      w.DefinedFunction function = canBeCalledWith(posArgCount, argNames)
          ? makeTrampoline(signature, posArgCount, argNames)
          : globals.getDummyFunction(signature);
      functions.add(function);
      ib.ref_func(function);
    }

    w.DefinedGlobal vtable = m.addGlobal(w.GlobalType(
        w.RefType.def(representation.vtableStruct, nullable: false),
        mutable: false));
    w.Instructions ib = vtable.initializer;
    if (representation.isGeneric) {
      ib.ref_func(representation.instantiationFunction);
    }
    for (int posArgCount = 0; posArgCount <= positionalCount; posArgCount++) {
      fillVtableEntry(ib, posArgCount, const []);
    }
    for (NameCombination nameCombination in representation.nameCombinations) {
      fillVtableEntry(ib, positionalCount, nameCombination.names);
    }
    ib.struct_new(representation.vtableStruct);
    ib.end();

    return ClosureImplementation(representation, functions, vtable);
  }

  w.ValueType outputOrVoid(List<w.ValueType> outputs) {
    return outputs.isEmpty ? voidMarker : outputs.single;
  }

  bool needsConversion(w.ValueType from, w.ValueType to) {
    return (from == voidMarker) ^ (to == voidMarker) || !from.isSubtypeOf(to);
  }

  void convertType(
      w.DefinedFunction function, w.ValueType from, w.ValueType to) {
    w.Instructions b = function.body;
    if (from == voidMarker || to == voidMarker) {
      if (from != voidMarker) {
        b.drop();
        return;
      }
      if (to != voidMarker) {
        if (to is w.RefType && to.nullable) {
          // This can happen when a void method has its return type overridden
          // to return a value, in which case the selector signature will have a
          // non-void return type to encompass all possible return values.
          b.ref_null(to.heapType);
        } else {
          // This only happens in invalid but unreachable code produced by the
          // TFA dead-code elimination.
          b.comment("Non-nullable void conversion");
          b.unreachable();
        }
        return;
      }
    }

    bool fromIsExtern = from.isSubtypeOf(w.RefType.extern(nullable: true));
    bool toIsExtern = to.isSubtypeOf(w.RefType.extern(nullable: true));
    if (fromIsExtern && !toIsExtern) {
      b.extern_internalize();
      from = w.RefType.any(nullable: from.nullable);
    }
    if (!fromIsExtern && toIsExtern) {
      to = w.RefType.any(nullable: to.nullable);
    }

    if (!from.isSubtypeOf(to)) {
      if (from is! w.RefType && to is w.RefType) {
        // Boxing
        ClassInfo info = classInfo[boxedClasses[from]!]!;
        assert(info.struct.isSubtypeOf(to.heapType));
        w.Local temp = function.addLocal(from);
        b.local_set(temp);
        b.i32_const(info.classId);
        b.local_get(temp);
        b.struct_new(info.struct);
      } else if (from is w.RefType && to is! w.RefType) {
        // Unboxing
        ClassInfo info = classInfo[boxedClasses[to]!]!;
        if (!from.heapType.isSubtypeOf(info.struct)) {
          // Cast to box type
          if (!from.heapType.isSubtypeOf(w.HeapType.data)) {
            b.ref_as_data();
          }
          b.ref_cast(info.struct);
        }
        b.struct_get(info.struct, FieldIndex.boxValue);
      } else if (from.withNullability(false).isSubtypeOf(to)) {
        // Null check
        b.ref_as_non_null();
      } else {
        // Downcast
        if (from.nullable && !to.nullable) {
          b.ref_as_non_null();
        }
        var heapType = (to as w.RefType).heapType;
        if (heapType is w.FunctionType) {
          b.ref_cast(heapType);
          return;
        }
        w.Label? nullLabel = null;
        if (!(from as w.RefType).heapType.isSubtypeOf(w.HeapType.data)) {
          if (from.nullable && to.nullable) {
            // Nullable cast from above dataref. Since ref.as_data is not
            // null-polymorphic, we need to check explicitly for null.
            w.Local temp = function.addLocal(from);
            b.local_set(temp);
            nullLabel = b.block(const [], [to]);
            w.Label nonNullLabel =
                b.block(const [], [from.withNullability(false)]);
            b.local_get(temp);
            b.br_on_non_null(nonNullLabel);
            b.ref_null(to.heapType);
            b.br(nullLabel);
            b.end(); // nonNullLabel
          }
          b.ref_as_data();
        }
        if (heapType is w.DefType) {
          b.ref_cast(heapType);
        }
        if (nullLabel != null) {
          b.end(); // nullLabel
        }
      }
    }

    if (!fromIsExtern && toIsExtern) {
      b.extern_externalize();
    }
  }

  w.FunctionType signatureFor(Reference target) {
    Member member = target.asMember;
    if (member.isInstanceMember) {
      return dispatchTable.selectorForTarget(target).signature;
    } else {
      return functions.getFunction(target).type;
    }
  }

  ParameterInfo paramInfoFor(Reference target) {
    Member member = target.asMember;
    if (member.isInstanceMember) {
      return dispatchTable.selectorForTarget(target).paramInfo;
    } else {
      return staticParamInfo.putIfAbsent(
          target, () => ParameterInfo.fromMember(target));
    }
  }

  /// Get the Wasm table declared by [field], or `null` if [field] is not a
  /// declaration of a Wasm table.
  ///
  /// This function participates in tree shaking in the sense that if it's
  /// never called for a particular table declaration, that table is not added
  /// to the output module.
  w.DefinedTable? getTable(Field field) {
    w.DefinedTable? table = declaredTables[field];
    if (table != null) return table;
    DartType fieldType = field.type;
    if (fieldType is InterfaceType && fieldType.classNode == wasmTableClass) {
      w.RefType elementType =
          translateType(fieldType.typeArguments.single) as w.RefType;
      Expression sizeExp = (field.initializer as ConstructorInvocation)
          .arguments
          .positional
          .single;
      if (sizeExp is StaticGet && sizeExp.target is Field) {
        sizeExp = (sizeExp.target as Field).initializer!;
      }
      int size = sizeExp is ConstantExpression
          ? (sizeExp.constant as IntConstant).value
          : (sizeExp as IntLiteral).value;
      return declaredTables[field] = m.addTable(elementType, size);
    }
    return null;
  }

  Member? singleTarget(TreeNode node) {
    DirectCallMetadataRepository metadata =
        component.metadata[DirectCallMetadataRepository.repositoryTag]
            as DirectCallMetadataRepository;
    return metadata.mapping[node]?.target;
  }

  bool shouldInline(Reference target) {
    if (!options.inlining) return false;
    Member member = target.asMember;
    if (member is Field) return true;
    Statement? body = member.function!.body;
    return body != null &&
        NodeCounter().countNodes(body) <= options.inliningLimit;
  }

  T? getPragma<T>(Annotatable node, String name, [T? defaultvalue]) {
    for (Expression annotation in node.annotations) {
      if (annotation is ConstantExpression) {
        Constant constant = annotation.constant;
        if (constant is InstanceConstant) {
          if (constant.classNode == coreTypes.pragmaClass) {
            Constant? nameConstant =
                constant.fieldValues[coreTypes.pragmaName.fieldReference];
            if (nameConstant is StringConstant && nameConstant.value == name) {
              Object? value =
                  constant.fieldValues[coreTypes.pragmaOptions.fieldReference];
              if (value is PrimitiveConstant<T>) {
                return value.value;
              }
              return value as T? ?? defaultvalue;
            }
          }
        }
      }
    }
    return null;
  }
}

class NodeCounter extends Visitor<void> with VisitorVoidMixin {
  int count = 0;

  int countNodes(Node node) {
    count = 0;
    node.accept(this);
    return count;
  }

  @override
  void defaultNode(Node node) {
    count++;
    node.visitChildren(this);
  }
}
