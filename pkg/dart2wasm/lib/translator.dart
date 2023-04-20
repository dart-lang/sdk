// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/constants.dart';
import 'package:dart2wasm/dispatch_table.dart';
import 'package:dart2wasm/dynamic_forwarders.dart';
import 'package:dart2wasm/functions.dart';
import 'package:dart2wasm/globals.dart';
import 'package:dart2wasm/kernel_nodes.dart';
import 'package:dart2wasm/param_info.dart';
import 'package:dart2wasm/records.dart';
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
  bool enableAsserts = false;
  bool exportAll = false;
  bool importSharedMemory = false;
  bool inlining = true;
  bool nameSection = true;
  bool omitTypeChecks = false;
  bool polymorphicSpecialization = false;
  bool printKernel = false;
  bool printWasm = false;
  int inliningLimit = 0;
  int? sharedMemoryMaxPages;
  List<int>? watchPoints = null;
}

/// The main entry point for the translation from kernel to Wasm and the hub for
/// all global state in the compiler.
///
/// This class also contains utility methods for types and code generation used
/// throughout the compiler.
class Translator with KernelNodes {
  // Options for the translation.
  final TranslatorOptions options;

  // Kernel input and context.
  final Component component;
  final List<Library> libraries;
  final CoreTypes coreTypes;
  late final TypeEnvironment typeEnvironment;
  final ClosedWorldClassHierarchy hierarchy;
  late final ClassHierarchySubtypes subtypes;

  // Other parts of the global compiler state.
  late final ClosureLayouter closureLayouter;
  late final ClassInfoCollector classInfoCollector;
  late final DispatchTable dispatchTable;
  late final Globals globals;
  late final Constants constants;
  late final Types types;
  late final FunctionCollector functions;
  late final DynamicForwarders dynamicForwarders;

  // Information about the program used and updated by the various phases.

  /// [ClassInfo]s of classes in the compilation unit and the [ClassInfo] for
  /// the `#Top` struct. Indexed by class ID. Entries added by
  /// [ClassInfoCollector].
  final List<ClassInfo> classes = [];

  /// [ClassInfo]s of classes in the compilation unit. Entries added by
  /// [ClassInfoCollector].
  final Map<Class, ClassInfo> classInfo = {};

  final Map<w.HeapType, ClassInfo> classForHeapType = {};
  final Map<Field, int> fieldIndex = {};
  final Map<TypeParameter, int> typeParameterIndex = {};
  final Map<Reference, ParameterInfo> staticParamInfo = {};
  final Map<Field, w.DefinedTable> declaredTables = {};
  final Set<Member> membersContainingInnerFunctions = {};
  final Set<Member> membersBeingGenerated = {};
  final List<_FunctionGenerator> _pendingFunctions = [];
  late final Procedure mainFunction;
  late final w.Module m;
  late final w.DefinedFunction initFunction;
  late final w.ValueType voidMarker;
  // Lazily create exception tag if used.
  late final w.Tag exceptionTag = createExceptionTag();
  // Lazily import FFI memory if used.
  late final w.Memory ffiMemory = m.importMemory("ffi", "memory",
      options.importSharedMemory, 0, options.sharedMemoryMaxPages);

  /// Maps record shapes to the record class for the shape. Classes generated
  /// by `record_class_generator` library.
  final Map<RecordShape, Class> recordClasses;

  // Caches for when identical source constructs need a common representation.
  final Map<w.StorageType, w.ArrayType> arrayTypeCache = {};
  final Map<w.BaseFunction, w.DefinedGlobal> functionRefCache = {};
  final Map<Procedure, ClosureImplementation> tearOffFunctionCache = {};

  // Some convenience accessors for commonly used values.
  late final ClassInfo topInfo = classes[0];
  late final ClassInfo objectInfo = classInfo[coreTypes.objectClass]!;
  late final ClassInfo closureInfo = classInfo[closureClass]!;
  late final ClassInfo stackTraceInfo = classInfo[stackTraceClass]!;
  late final ClassInfo recordInfo = classInfo[coreTypes.recordClass]!;
  late final w.ArrayType listArrayType = (classInfo[listBaseClass]!
          .struct
          .fields[FieldIndex.listArray]
          .type as w.RefType)
      .heapType as w.ArrayType;

  /// Dart types that have specialized Wasm representations.
  late final Map<Class, w.StorageType> builtinTypes = {
    coreTypes.boolClass: w.NumType.i32,
    coreTypes.intClass: w.NumType.i64,
    coreTypes.doubleClass: w.NumType.f64,
    boxedBoolClass: w.NumType.i32,
    boxedIntClass: w.NumType.i64,
    boxedDoubleClass: w.NumType.f64,
    ffiPointerClass: w.NumType.i32,
    wasmI8Class: w.PackedType.i8,
    wasmI16Class: w.PackedType.i16,
    wasmI32Class: w.NumType.i32,
    wasmI64Class: w.NumType.i64,
    wasmF32Class: w.NumType.f32,
    wasmF64Class: w.NumType.f64,
    wasmAnyRefClass: const w.RefType.any(nullable: false),
    wasmExternRefClass: const w.RefType.extern(nullable: false),
    wasmFuncRefClass: const w.RefType.func(nullable: false),
    wasmEqRefClass: const w.RefType.eq(nullable: false),
    wasmStructRefClass: const w.RefType.struct(nullable: false),
    wasmArrayRefClass: const w.RefType.array(nullable: false),
  };

  /// The box classes corresponding to each of the value types.
  late final Map<w.ValueType, Class> boxedClasses = {
    w.NumType.i32: boxedBoolClass,
    w.NumType.i64: boxedIntClass,
    w.NumType.f64: boxedDoubleClass,
  };

  /// Classes whose identity hash code is their hash code rather than the
  /// identity hash code field in the struct. Each implementation class maps to
  /// the class containing the implementation of its `hashCode` getter.
  late final Map<Class, Class> valueClasses = {
    boxedIntClass: boxedIntClass,
    boxedDoubleClass: boxedDoubleClass,
    boxedBoolClass: coreTypes.boolClass,
    oneByteStringClass: stringBaseClass,
    twoByteStringClass: stringBaseClass,
  };

  /// Type for vtable entries for dynamic calls. These entries are used in
  /// dynamic invocations and `Function.apply`.
  late final w.FunctionType dynamicCallVtableEntryFunctionType =
      m.addFunctionType([
    // Closure
    w.RefType.def(closureLayouter.closureBaseStruct, nullable: false),

    // Type arguments
    classInfo[fixedLengthListClass]!.nonNullableType,

    // Positional arguments
    classInfo[fixedLengthListClass]!.nonNullableType,

    // Named arguments, represented as array of symbol and object pairs
    classInfo[fixedLengthListClass]!.nonNullableType,
  ], [
    topInfo.nullableType
  ]);

  /// Type of a dynamic invocation forwarder function.
  late final w.FunctionType dynamicInvocationForwarderFunctionType =
      m.addFunctionType([
    // Receiver
    topInfo.nonNullableType,

    // Type arguments
    classInfo[fixedLengthListClass]!.nonNullableType,

    // Positional arguments
    classInfo[fixedLengthListClass]!.nonNullableType,

    // Named arguments, represented as array of symbol and object pairs
    classInfo[fixedLengthListClass]!.nonNullableType,
  ], [
    topInfo.nullableType
  ]);

  /// Type of a dynamic get forwarder function.
  late final w.FunctionType dynamicGetForwarderFunctionType =
      m.addFunctionType([
    // Receiver
    topInfo.nonNullableType,
  ], [
    topInfo.nullableType
  ]);

  /// Type of a dynamic set forwarder function.
  late final w.FunctionType dynamicSetForwarderFunctionType =
      m.addFunctionType([
    // Receiver
    topInfo.nonNullableType,

    // Positional argument
    topInfo.nullableType,
  ], [
    topInfo.nullableType
  ]);

  Translator(this.component, this.coreTypes, this.recordClasses, this.options)
      : libraries = component.libraries,
        hierarchy =
            ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy {
    typeEnvironment = TypeEnvironment(coreTypes, hierarchy);
    subtypes = hierarchy.computeSubtypesInformation();
    closureLayouter = ClosureLayouter(this);
    classInfoCollector = ClassInfoCollector(this);
    dispatchTable = DispatchTable(this);
    functions = FunctionCollector(this);
    types = Types(this);
    dynamicForwarders = DynamicForwarders(this);
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
    mainFunction = _findMainMethod(libraries.first);

    // Collect imports and exports as the very first thing so the function types
    // for the imports can be places in singleton recursion groups.
    functions.collectImportsAndExports();

    closureLayouter.collect([mainFunction.function]);
    classInfoCollector.collect();

    initFunction =
        m.addFunction(m.addFunctionType(const [], const []), "#init");
    m.startFunction = initFunction;

    globals = Globals(this);
    constants = Constants(this);

    dispatchTable.build();

    m.exportFunction("\$getMain", generateGetMain(mainFunction));

    functions.initialize();
    while (!functions.isWorkListEmpty()) {
      Reference reference = functions.popWorkList();
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

      String? exportName = functions.getExport(reference);

      if (options.printKernel || options.printWasm) {
        String header = "#${function.index}: $canonicalName";
        if (exportName != null) {
          header = "$header (exported as $exportName)";
        }
        if (reference.isTypeCheckerReference) {
          header = "$header (type checker)";
        }
        print(header);
        print(member.function
            ?.computeFunctionType(Nullability.nonNullable)
            .toStringInternal());
      }
      if (options.printKernel && !reference.isTypeCheckerReference) {
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

      final CodeGenerator codeGen =
          CodeGenerator.forFunction(this, member.function, function, reference);
      codeGen.generate();

      if (options.printWasm) {
        print(codeGen.function.type);
        print(codeGen.function.body.trace);
      }

      for (Lambda lambda in codeGen.closures.lambdas.values) {
        w.DefinedFunction lambdaFunction = CodeGenerator.forFunction(
                this, lambda.functionNode, lambda.function, reference)
            .generateLambda(lambda, codeGen.closures);
        _printFunction(lambdaFunction, "$canonicalName (closure)");
      }

      // Use an indexed loop to handle pending closure trampolines, since new
      // entries might be added during iteration.
      for (int i = 0; i < _pendingFunctions.length; i++) {
        _pendingFunctions[i].generate(this);
      }
      _pendingFunctions.clear();
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

  w.DefinedFunction generateGetMain(Procedure mainFunction) {
    w.DefinedFunction getMain = m.addFunction(
        m.addFunctionType(const [], const [w.RefType.any(nullable: true)]));
    constants.instantiateConstant(getMain, getMain.body,
        StaticTearOffConstant(mainFunction), getMain.type.outputs.single);
    getMain.body.end();

    return getMain;
  }

  Class classForType(DartType type) {
    return type is InterfaceType
        ? type.classNode
        : type is TypeParameterType
            ? classForType(type.bound)
            : coreTypes.objectClass;
  }

  /// Compute the runtime type of a tear-off. This is the signature of the
  /// method with the types of all covariant parameters replaced by `Object?`.
  FunctionType getTearOffType(Procedure method) {
    assert(method.kind == ProcedureKind.Method);
    final FunctionType staticType = method.getterType as FunctionType;

    final positionalParameters = List.of(staticType.positionalParameters);
    assert(positionalParameters.length ==
        method.function.positionalParameters.length);

    final namedParameters = List.of(staticType.namedParameters);
    assert(namedParameters.length == method.function.namedParameters.length);

    if (!options.omitTypeChecks) {
      for (int i = 0; i < positionalParameters.length; i++) {
        final param = method.function.positionalParameters[i];
        if (param.isCovariantByDeclaration || param.isCovariantByClass) {
          positionalParameters[i] = coreTypes.objectNullableRawType;
        }
      }

      for (int i = 0; i < namedParameters.length; i++) {
        final param = method.function.namedParameters[i];
        if (param.isCovariantByDeclaration || param.isCovariantByClass) {
          namedParameters[i] = NamedType(
              namedParameters[i].name, coreTypes.objectNullableRawType,
              isRequired: namedParameters[i].isRequired);
        }
      }
    }

    return FunctionType(
        positionalParameters, staticType.returnType, Nullability.nonNullable,
        namedParameters: namedParameters,
        typeParameters: staticType.typeParameters,
        requiredParameterCount: staticType.requiredParameterCount);
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

  bool isWasmType(Class cls) =>
      cls == wasmTypesBaseClass || _hasSuperclass(cls, wasmTypesBaseClass);

  bool isFfiCompound(Class cls) => _hasSuperclass(cls, ffiCompoundClass);

  w.StorageType translateStorageType(DartType type) {
    bool nullable = type.isPotentiallyNullable;
    if (type is InterfaceType) {
      Class cls = type.classNode;

      // Abstract `Function`?
      if (cls == coreTypes.functionClass) {
        return w.RefType.def(closureLayouter.closureBaseStruct,
            nullable: nullable);
      }

      // Wasm array?
      if (cls.superclass == wasmArrayRefClass) {
        DartType elementType = type.typeArguments.single;
        return w.RefType.def(arrayTypeForDartType(elementType),
            nullable: nullable);
      }

      // Wasm function?
      if (cls == wasmFunctionClass) {
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
        DartType returnType = functionType.returnType;
        bool voidReturn = returnType is InterfaceType &&
            returnType.classNode == wasmVoidClass;
        List<w.ValueType> inputs = [
          for (DartType type in functionType.positionalParameters)
            translateType(type)
        ];
        List<w.ValueType> outputs = [
          if (!voidReturn) translateType(functionType.returnType)
        ];
        w.FunctionType wasmType = m.addFunctionType(inputs, outputs);
        return w.RefType.def(wasmType, nullable: nullable);
      }

      // FFI compound?
      if (isFfiCompound(cls)) {
        if (nullable) throw "FFI types can't be nullable";
        return w.NumType.i32;
      }

      // Other built-in type?
      w.StorageType? builtin = builtinTypes[cls];
      if (builtin != null) {
        if (!nullable) {
          return builtin;
        }
        if (isWasmType(cls)) {
          if (builtin.isPrimitive) throw "Wasm numeric types can't be nullable";
          return (builtin as w.RefType).withNullability(nullable);
        }
        if (cls == ffiPointerClass) throw "FFI types can't be nullable";
        return classInfo[boxedClasses[builtin]!]!.nullableType;
      }

      // Regular class.
      return classInfo[cls]!.repr.typeWithNullability(nullable);
    }
    if (type is DynamicType || type is VoidType) {
      return topInfo.nullableType;
    }
    if (type is NullType || type is NeverType) {
      return const w.RefType.none(nullable: true);
    }
    if (type is TypeParameterType) {
      return translateStorageType(nullable
          ? type.bound.withDeclaredNullability(type.nullability)
          : type.bound);
    }
    if (type is IntersectionType) {
      return translateStorageType(type.left);
    }
    if (type is FutureOrType) {
      return topInfo.typeWithNullability(nullable);
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
          nullable: nullable);
    }
    if (type is InlineType) {
      return translateStorageType(type.instantiatedRepresentationType);
    }
    if (type is RecordType) {
      return getRecordClassInfo(type).typeWithNullability(nullable);
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

  w.ArrayType wasmArrayType(w.StorageType type, String name,
      {bool mutable = true}) {
    return arrayTypeCache.putIfAbsent(
        type,
        () => m.addArrayType("Array<$name>",
            elementType: w.FieldType(type, mutable: mutable)));
  }

  /// Translate a Dart type as it should appear on parameters and returns of
  /// imported and exported functions. All wasm types are allowed on the interop
  /// boundary, but in order to be compatible with the `--closed-world` mode of
  /// Binaryen, we coerce all reference types to abstract reference types
  /// (`anyref`, `funcref` or `externref`).
  /// This function can be called before the class info is built.
  w.ValueType translateExternalType(DartType type) {
    bool isPotentiallyNullable = type.isPotentiallyNullable;
    if (type is InterfaceType) {
      Class cls = type.classNode;
      if (cls == wasmFuncRefClass || cls == wasmFunctionClass) {
        return w.RefType.func(nullable: isPotentiallyNullable);
      }
      if (cls == wasmExternRefClass) {
        return w.RefType.extern(nullable: isPotentiallyNullable);
      }
      if (!isPotentiallyNullable) {
        w.StorageType? builtin = builtinTypes[cls];
        if (builtin != null && builtin.isPrimitive) {
          return builtin as w.ValueType;
        }
        if (isFfiCompound(cls)) {
          return w.NumType.i32;
        }
      }
    }
    // TODO(joshualitt): We'd like to use the potential nullability here too,
    // but unfortunately this seems to break things.
    return w.RefType.any(nullable: true);
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
    final List<VariableDeclaration> namedParamsSorted =
        functionNode.namedParameters.toList()
          ..sort((p1, p2) => p1.name!.compareTo(p2.name!));
    List<String> names = namedParamsSorted.map((p) => p.name!).toList();
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

      int namedArgIdx = 0, namedParamIdx = 0;
      while (namedArgIdx < argNames.length &&
          namedParamIdx < namedParamsSorted.length) {
        int comp = argNames[namedArgIdx]
            .compareTo(namedParamsSorted[namedParamIdx].name!);
        if (comp < 0) {
          // Unexpected named argument passed
          return false;
        } else if (comp > 0) {
          if (namedParamsSorted[namedParamIdx].isRequired) {
            // Required named parameter not passed
            return false;
          } else {
            // Optional named parameter not passed
            namedParamIdx++;
            continue;
          }
        } else {
          // Expected required or optional named parameter passed
          namedArgIdx++;
          namedParamIdx++;
        }
      }

      if (namedArgIdx < argNames.length) {
        // Unexpected named argument(s) passed
        return false;
      }

      while (namedParamIdx < namedParamsSorted.length) {
        if (namedParamsSorted[namedParamIdx++].isRequired) {
          // Required named parameter not passed
          return false;
        }
      }

      return true;
    }

    w.DefinedFunction makeTrampoline(
        w.FunctionType signature, int posArgCount, List<String> argNames) {
      w.DefinedFunction trampoline = m.addFunction(signature, name);

      // Defer generation of the trampoline body to avoid cyclic dependency
      // when a tear-off constant is used as default value in the torn-off
      // function.
      _pendingFunctions.add(_ClosureTrampolineGenerator(trampoline, target,
          typeCount, posArgCount, argNames, paramInfo, takesContextOrReceiver));

      return trampoline;
    }

    w.DefinedFunction makeDynamicCallEntry() {
      final w.DefinedFunction function = m.addFunction(
          dynamicCallVtableEntryFunctionType, "dynamic call entry");

      // Defer generation of the trampoline body to avoid cyclic dependency
      // when a tear-off constant is used as default value in the torn-off
      // function.
      _pendingFunctions.add(_ClosureDynamicEntryGenerator(
          functionNode, target, paramInfo, name, function));

      return function;
    }

    void fillVtableEntry(
        w.Instructions ib, int posArgCount, List<String> argNames) {
      int fieldIndex = representation.vtableBaseIndex + functions.length;
      assert(fieldIndex ==
          representation.fieldIndexForSignature(posArgCount, argNames));
      w.FunctionType signature = representation.getVtableFieldType(fieldIndex);
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
    final dynamicCallEntry = makeDynamicCallEntry();
    ib.ref_func(dynamicCallEntry);
    if (representation.isGeneric) {
      ib.ref_func(representation.instantiationTypeComparisonFunction);
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

    return ClosureImplementation(
        representation, functions, dynamicCallEntry, vtable);
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
        assert(to is w.RefType && to.nullable);
        // This can happen when a void method has its return type overridden
        // to return a value, in which case the selector signature will have a
        // non-void return type to encompass all possible return values.
        b.ref_null((to as w.RefType).heapType.bottomType);
        return;
      }
    }

    if (!from.isSubtypeOf(to)) {
      if (from is w.RefType && to is w.RefType) {
        if (from.withNullability(false).isSubtypeOf(to)) {
          // Null check
          b.ref_as_non_null();
        } else {
          // Downcast
          b.ref_cast(to);
        }
      } else if (to is w.RefType) {
        // Boxing
        ClassInfo info = classInfo[boxedClasses[from]!]!;
        assert(info.struct.isSubtypeOf(to.heapType));
        w.Local temp = function.addLocal(from);
        b.local_set(temp);
        b.i32_const(info.classId);
        b.local_get(temp);
        b.struct_new(info.struct);
      } else if (from is w.RefType) {
        // Unboxing
        ClassInfo info = classInfo[boxedClasses[to]!]!;
        if (!from.heapType.isSubtypeOf(info.struct)) {
          // Cast to box type
          b.ref_cast(info.nonNullableType);
        }
        b.struct_get(info.struct, FieldIndex.boxValue);
      } else {
        throw "Conversion between non-reference types";
      }
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
    if (member.function?.asyncMarker == AsyncMarker.SyncStar) return false;
    if (membersContainingInnerFunctions.contains(member)) return false;
    if (membersBeingGenerated.contains(member)) return false;
    if (member is Field) return true;
    if (getPragma<Constant>(member, "wasm:prefer-inline") != null) return true;
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
              Constant? value =
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

  w.ValueType makeList(
      w.DefinedFunction function,
      void generateType(w.Instructions b),
      int length,
      void Function(w.ValueType, int) generateItem,
      {bool isGrowable = false}) {
    final w.Instructions b = function.body;

    final Class cls = isGrowable ? growableListClass : fixedLengthListClass;
    final ClassInfo info = classInfo[cls]!;
    functions.allocateClass(info.classId);
    final w.ArrayType arrayType = listArrayType;
    final w.ValueType elementType = arrayType.elementType.type.unpacked;

    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    generateType(b);
    b.i64_const(length);
    if (length > maxArrayNewFixedLength) {
      // Too long for `array.new_fixed`. Set elements individually.
      b.i32_const(length);
      b.array_new_default(arrayType);
      if (length > 0) {
        final w.Local arrayLocal =
            function.addLocal(w.RefType.def(arrayType, nullable: false));
        b.local_set(arrayLocal);
        for (int i = 0; i < length; i++) {
          b.local_get(arrayLocal);
          b.i32_const(i);
          generateItem(elementType, i);
          b.array_set(arrayType);
        }
        b.local_get(arrayLocal);
      }
    } else {
      for (int i = 0; i < length; i++) {
        generateItem(elementType, i);
      }
      b.array_new_fixed(arrayType, length);
    }
    b.struct_new(info.struct);

    return info.nonNullableType;
  }

  /// Indexes a Dart `List` on the stack.
  void indexList(w.Instructions b, void pushIndex(w.Instructions b)) {
    ClassInfo info = classInfo[listBaseClass]!;
    w.ArrayType arrayType =
        (info.struct.fields[FieldIndex.listArray].type as w.RefType).heapType
            as w.ArrayType;
    b.struct_get(info.struct, FieldIndex.listArray);
    pushIndex(b);
    b.array_get(arrayType);
  }

  /// Pushes a Dart `List`'s length onto the stack as `i32`.
  void getListLength(w.Instructions b) {
    ClassInfo info = classInfo[listBaseClass]!;
    b.struct_get(info.struct, FieldIndex.listLength);
    b.i32_wrap_i64();
  }

  ClassInfo getRecordClassInfo(RecordType recordType) =>
      classInfo[recordClasses[RecordShape.fromType(recordType)]!]!;
}

abstract class _FunctionGenerator {
  void generate(Translator translator);
}

class _ClosureTrampolineGenerator implements _FunctionGenerator {
  final w.DefinedFunction trampoline;
  final w.BaseFunction target;
  final int typeCount;
  final int posArgCount;
  final List<String> argNames;
  final ParameterInfo paramInfo;
  final bool takesContextOrReceiver;

  _ClosureTrampolineGenerator(
      this.trampoline,
      this.target,
      this.typeCount,
      this.posArgCount,
      this.argNames,
      this.paramInfo,
      this.takesContextOrReceiver);

  void generate(Translator translator) {
    w.Instructions b = trampoline.body;
    int targetIndex = 0;
    if (takesContextOrReceiver) {
      w.Local receiver = trampoline.locals[0];
      b.local_get(receiver);
      translator.convertType(
          trampoline, receiver.type, target.type.inputs[targetIndex++]);
    }
    int argIndex = 1;
    for (int i = 0; i < typeCount; i++) {
      b.local_get(trampoline.locals[argIndex++]);
      targetIndex++;
    }
    for (int i = 0; i < paramInfo.positional.length; i++) {
      if (i < posArgCount) {
        w.Local arg = trampoline.locals[argIndex++];
        b.local_get(arg);
        translator.convertType(
            trampoline, arg.type, target.type.inputs[targetIndex++]);
      } else {
        translator.constants.instantiateConstant(trampoline, b,
            paramInfo.positional[i]!, target.type.inputs[targetIndex++]);
      }
    }
    int argNameIndex = 0;
    for (int i = 0; i < paramInfo.names.length; i++) {
      String argName = paramInfo.names[i];
      if (argNameIndex < argNames.length && argNames[argNameIndex] == argName) {
        w.Local arg = trampoline.locals[argIndex++];
        b.local_get(arg);
        translator.convertType(
            trampoline, arg.type, target.type.inputs[targetIndex++]);
        argNameIndex++;
      } else {
        translator.constants.instantiateConstant(trampoline, b,
            paramInfo.named[argName]!, target.type.inputs[targetIndex++]);
      }
    }
    assert(argIndex == trampoline.type.inputs.length);
    assert(targetIndex == target.type.inputs.length);
    assert(argNameIndex == argNames.length);

    b.call(target);

    translator.convertType(
        trampoline,
        translator.outputOrVoid(target.type.outputs),
        translator.outputOrVoid(trampoline.type.outputs));
    b.end();
  }
}

/// Similar to [_ClosureTrampolineGenerator], but generates dynamic call
/// entries.
class _ClosureDynamicEntryGenerator implements _FunctionGenerator {
  final FunctionNode functionNode;
  final w.BaseFunction target;
  final ParameterInfo paramInfo;
  final String name;
  final w.DefinedFunction function;

  _ClosureDynamicEntryGenerator(
      this.functionNode, this.target, this.paramInfo, this.name, this.function);

  void generate(Translator translator) {
    final w.Instructions b = function.body;

    final bool takesContextOrReceiver =
        paramInfo.member == null || paramInfo.member!.isInstanceMember;

    final int typeCount = functionNode.typeParameters.length;

    final closureLocal = function.locals[0];
    final typeArgsListLocal = function.locals[1];
    final posArgsListLocal = function.locals[2];
    final namedArgsListLocal = function.locals[3];

    final positionalRequired =
        paramInfo.positional.where((arg) => arg == null).length;
    final positionalTotal = paramInfo.positional.length;

    // At this point the shape and type checks passed. We have right number
    // of type arguments in the list, but optional positional and named
    // parameters may be missing.

    final targetInputs = target.type.inputs;
    int inputIdx = 0;

    // Push context or receiver
    if (takesContextOrReceiver) {
      final closureBaseType = w.RefType.def(
          translator.closureLayouter.closureBaseStruct,
          nullable: false);
      final closureContextType = w.RefType.struct(nullable: false);

      // Get context, downcast it to expected type
      b.local_get(closureLocal);
      translator.convertType(function, closureLocal.type, closureBaseType);
      b.struct_get(translator.closureLayouter.closureBaseStruct,
          FieldIndex.closureContext);
      translator.convertType(
          function, closureContextType, targetInputs[inputIdx]);
      inputIdx += 1;
    }

    // Push type arguments
    for (int typeIdx = 0; typeIdx < typeCount; typeIdx += 1) {
      b.local_get(typeArgsListLocal);
      translator.indexList(b, (b) => b.i32_const(typeIdx));
      translator.convertType(
          function, translator.topInfo.nullableType, targetInputs[inputIdx]);
      inputIdx += 1;
    }

    // Push positional arguments
    for (int posIdx = 0; posIdx < positionalTotal; posIdx += 1) {
      if (posIdx < positionalRequired) {
        // Shape check passed, argument must be passed
        b.local_get(posArgsListLocal);
        translator.indexList(b, (b) => b.i32_const(posIdx));
      } else {
        // Argument may be missing
        b.i32_const(posIdx);
        b.local_get(posArgsListLocal);
        translator.getListLength(b);
        b.i32_lt_u();
        b.if_([], [translator.topInfo.nullableType]);
        b.local_get(posArgsListLocal);
        translator.indexList(b, (b) => b.i32_const(posIdx));
        b.else_();
        translator.constants.instantiateConstant(function, b,
            paramInfo.positional[posIdx]!, translator.topInfo.nullableType);
        b.end();
      }
      translator.convertType(
          function, translator.topInfo.nullableType, targetInputs[inputIdx]);
      inputIdx += 1;
    }

    // Push named arguments

    Expression? initializerForNamedParamInMember(String paramName) {
      for (int i = 0; i < functionNode.namedParameters.length; i += 1) {
        if (functionNode.namedParameters[i].name == paramName) {
          return functionNode.namedParameters[i].initializer;
        }
      }
      return null;
    }

    final namedArgValueIndexLocal = function
        .addLocal(translator.classInfo[translator.boxedIntClass]!.nullableType);

    for (String paramName in paramInfo.names) {
      final Constant? paramInfoDefaultValue = paramInfo.named[paramName]!;
      final Expression? functionNodeDefaultValue =
          initializerForNamedParamInMember(paramName);

      // Get passed value
      b.local_get(namedArgsListLocal);
      translator.constants.instantiateConstant(
          function,
          b,
          SymbolConstant(paramName, null),
          translator.classInfo[translator.symbolClass]!.nonNullableType);
      b.call(translator.functions
          .getFunction(translator.getNamedParameterIndex.reference));
      b.local_set(namedArgValueIndexLocal);

      if (functionNodeDefaultValue == null && paramInfoDefaultValue == null) {
        // Shape check passed, parameter must be passed
        b.local_get(namedArgsListLocal);
        translator.indexList(b, (b) {
          b.local_get(namedArgValueIndexLocal);
          translator.convertType(
              function, namedArgValueIndexLocal.type, w.NumType.i64);
          b.i32_wrap_i64();
        });
      } else {
        // Parameter may not be passed.
        b.local_get(namedArgValueIndexLocal);
        b.ref_is_null();
        b.if_([], [translator.topInfo.nullableType]);
        if (functionNodeDefaultValue != null) {
          // Used by the member, has a default value
          translator.constants.instantiateConstant(
              function,
              b,
              (functionNodeDefaultValue as ConstantExpression).constant,
              translator.topInfo.nullableType);
        } else {
          // Not used by the member
          translator.constants.instantiateConstant(
            function,
            b,
            paramInfoDefaultValue!,
            translator.topInfo.nullableType,
          );
        }
        b.else_(); // value index not null
        b.local_get(namedArgsListLocal);
        translator.indexList(b, (b) {
          b.local_get(namedArgValueIndexLocal);
          translator.convertType(
              function, namedArgValueIndexLocal.type, w.NumType.i64);
          b.i32_wrap_i64();
        });
        b.end();
        translator.convertType(
            function, translator.topInfo.nullableType, targetInputs[inputIdx]);
      }
      inputIdx += 1;
    }

    b.call(target);

    translator.convertType(
        function,
        translator.outputOrVoid(target.type.outputs),
        translator.outputOrVoid(function.type.outputs));

    b.end(); // end function
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
