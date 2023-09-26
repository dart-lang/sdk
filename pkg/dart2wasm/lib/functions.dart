// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/dispatch_table.dart';
import 'package:dart2wasm/reference_extensions.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// This class is responsible for collecting import and export annotations.
/// It also creates Wasm functions for Dart members and manages the worklist
/// used to achieve tree shaking.
class FunctionCollector {
  final Translator translator;

  // Wasm function for each Dart function
  final Map<Reference, w.BaseFunction> _functions = {};
  // Names of exported functions
  final Map<Reference, String> _exports = {};
  // Functions for which code has not yet been generated
  final List<Reference> _worklist = [];
  // Class IDs for classes that are allocated somewhere in the program
  final Set<int> _allocatedClasses = {};
  // For each class ID, which functions should be added to the worklist if an
  // allocation of that class is encountered
  final Map<int, List<Reference>> _pendingAllocation = {};

  FunctionCollector(this.translator);

  w.ModuleBuilder get m => translator.m;

  void collectImportsAndExports() {
    for (Library library in translator.libraries) {
      library.procedures.forEach(_importOrExport);
      library.fields.forEach(_importOrExport);
      for (Class cls in library.classes) {
        cls.procedures.forEach(_importOrExport);
      }
    }
  }

  bool isWorkListEmpty() => _worklist.isEmpty;

  Reference popWorkList() => _worklist.removeLast();

  void _importOrExport(Member member) {
    String? importName =
        translator.getPragma(member, "wasm:import", member.name.text);
    if (importName != null) {
      int dot = importName.indexOf('.');
      if (dot != -1) {
        assert(!member.isInstanceMember);
        String module = importName.substring(0, dot);
        String name = importName.substring(dot + 1);
        if (member is Procedure) {
          // Define the function type in a singular recursion group to enable it
          // to be unified with function types defined in FFI modules or using
          // `WebAssembly.Function`.
          m.types.splitRecursionGroup();
          w.FunctionType ftype = _makeFunctionType(
              translator, member.reference, [member.function.returnType], null,
              isImportOrExport: true);
          m.types.splitRecursionGroup();
          _functions[member.reference] =
              m.functions.import(module, name, ftype, "$importName (import)");
        }
      }
    }
    String? exportName =
        translator.getPragma(member, "wasm:export", member.name.text);
    if (exportName != null) {
      if (member is Procedure) {
        // Although we don't need type unification for the types of exported
        // functions, we still place these types in singleton recursion groups,
        // since Binaryen's `--closed-world` optimization mode requires all
        // publicly exposed types to be defined in separate recursion groups
        // from GC types.
        m.types.splitRecursionGroup();
        _makeFunctionType(
            translator, member.reference, [member.function.returnType], null,
            isImportOrExport: true);
        m.types.splitRecursionGroup();
      }
      addExport(member.reference, exportName);
    }
  }

  void addExport(Reference target, String exportName) {
    _exports[target] = exportName;
  }

  String? getExport(Reference target) => _exports[target];

  void initialize() {
    // Add exports to the module and add exported functions to the worklist
    for (var export in _exports.entries) {
      Reference target = export.key;
      Member node = target.asMember;
      if (node is Procedure) {
        _worklist.add(target);
        assert(!node.isInstanceMember);
        assert(!node.isGetter);
        w.FunctionType ftype = _makeFunctionType(
            translator, target, [node.function.returnType], null,
            isImportOrExport: true);
        w.BaseFunction function = m.functions.define(ftype, "$node");
        _functions[target] = function;
        m.exports.export(export.value, function);
      } else if (node is Field) {
        w.Table? table = translator.getTable(node);
        if (table != null) {
          m.exports.export(export.value, table);
        }
      }
    }

    // Value classes are always implicitly allocated.
    allocateClass(translator.classInfo[translator.boxedBoolClass]!.classId);
    allocateClass(translator.classInfo[translator.boxedIntClass]!.classId);
    allocateClass(translator.classInfo[translator.boxedDoubleClass]!.classId);
  }

  w.BaseFunction? getExistingFunction(Reference target) {
    return _functions[target];
  }

  w.BaseFunction getFunction(Reference target) {
    return _functions.putIfAbsent(target, () {
      _worklist.add(target);
      return _getFunctionTypeAndName(target, m.functions.define);
    });
  }

  w.FunctionType getFunctionType(Reference target) {
    return _getFunctionTypeAndName(target, (ftype, name) => ftype);
  }

  T _getFunctionTypeAndName<T>(
      Reference target, T Function(w.FunctionType, String) action) {
    if (target.isTypeCheckerReference) {
      Member member = target.asMember;
      if (member is Field || (member is Procedure && member.isSetter)) {
        return action(translator.dynamicSetForwarderFunctionType,
            '${target.asMember} setter type checker');
      } else {
        return action(translator.dynamicInvocationForwarderFunctionType,
            '${target.asMember} invocation type checker');
      }
    }

    if (target.isTearOffReference) {
      return action(
          translator.dispatchTable.selectorForTarget(target).signature,
          "${target.asMember} tear-off");
    }

    Member member = target.asMember;
    final ftype = member.accept1(_FunctionTypeGenerator(translator), target);

    if (target.isInitializerReference) {
      return action(ftype, '${member} initializer');
    } else if (target.isConstructorBodyReference) {
      return action(ftype, '${member} constructor body');
    }

    return action(ftype, "${target.asMember}");
  }

  void activateSelector(SelectorInfo selector) {
    selector.targets.forEach((classId, target) {
      if (!target.asMember.isAbstract) {
        if (_allocatedClasses.contains(classId)) {
          // Class declaring or inheriting member is allocated somewhere.
          getFunction(target);
        } else {
          // Remember the member in case an allocation is encountered later.
          _pendingAllocation.putIfAbsent(classId, () => []).add(target);
        }
      }
    });
  }

  void allocateClass(int classId) {
    if (_allocatedClasses.add(classId)) {
      // Schedule all members that were pending allocation of this class.
      for (Reference target in _pendingAllocation[classId] ?? const []) {
        getFunction(target);
      }
    }
  }

  /// Returns an iterable of translated procedures.
  Iterable<Procedure> get translatedProcedures =>
      _functions.keys.map((k) => k.node).whereType<Procedure>();
}

class _FunctionTypeGenerator extends MemberVisitor1<w.FunctionType, Reference> {
  final Translator translator;

  _FunctionTypeGenerator(this.translator);

  @override
  w.FunctionType visitField(Field node, Reference target) {
    if (!node.isInstanceMember) {
      if (target == node.fieldReference) {
        // Static field initializer function
        return _makeFunctionType(translator, target, [node.type], null);
      }
      String kind = target == node.setterReference ? "setter" : "getter";
      throw "No implicit $kind function for static field: $node";
    }
    return translator.dispatchTable.selectorForTarget(target).signature;
  }

  @override
  w.FunctionType visitProcedure(Procedure node, Reference target) {
    assert(!node.isAbstract);
    return node.isInstanceMember
        ? translator.dispatchTable.selectorForTarget(node.reference).signature
        : _makeFunctionType(
            translator, target, [node.function.returnType], null);
  }

  @override
  w.FunctionType visitConstructor(Constructor node, Reference target) {
    // Get this constructor's argument types
    List<w.ValueType> arguments = _getInputTypes(
        translator, target, null, false, translator.translateType);

    if (translator.constructorClosures[node.reference] == null) {
      // We need the contexts of the constructor before generating the
      // initializer and constructor body functions, as these functions will
      // return/take a context argument if context must be shared between them.
      // Generate the contexts the first time we visit a constructor.
      Closures closures = Closures(translator, node);

      closures.findCaptures(node);
      closures.collectContexts(node);
      closures.buildContexts();

      translator.constructorClosures[node.reference] = closures;
    }

    if (target.isInitializerReference) {
      return _getInitializerType(node, target, arguments);
    }

    if (target.isConstructorBodyReference) {
      return _getConstructorBodyType(node, arguments);
    }

    return _getConstructorAllocatorType(node, arguments);
  }

  w.FunctionType _getConstructorAllocatorType(
      Constructor node, List<w.ValueType> arguments) {
    return translator.m.types.defineFunction(arguments,
        [translator.classInfo[node.enclosingClass]!.nonNullableType.unpacked]);
  }

  w.FunctionType _getInitializerType(
      Constructor node, Reference target, List<w.ValueType> arguments) {
    final ClassInfo info = translator.classInfo[node.enclosingClass]!;
    assert(translator.constructorClosures.containsKey(node.reference));
    Closures closures = translator.constructorClosures[node.reference]!;

    List<w.ValueType> superOrRedirectedInitializerArgs = [];

    for (Initializer initializer in node.initializers) {
      if (initializer is SuperInitializer) {
        Supertype? supersupertype = initializer.target.enclosingClass.supertype;

        if (supersupertype != null) {
          ClassInfo superInfo = info.superInfo!;
          w.FunctionType superInitializer = translator.functions
              .getFunctionType(initializer.target.initializerReference);

          final int numSuperclassFields = superInfo.getClassFieldTypes().length;
          final int numSuperContextAndConstructorArgs =
              superInitializer.outputs.length - numSuperclassFields;

          // get types of super initializer outputs, ignoring the superclass
          // fields
          superOrRedirectedInitializerArgs = superInitializer.outputs
              .sublist(0, numSuperContextAndConstructorArgs);
        }
      } else if (initializer is RedirectingInitializer) {
        Supertype? supersupertype = initializer.target.enclosingClass.supertype;

        if (supersupertype != null) {
          w.FunctionType redirectedInitializer = translator.functions
              .getFunctionType(initializer.target.initializerReference);

          final int numClassFields = info.getClassFieldTypes().length;
          final int numRedirectedContextAndConstructorArgs =
              redirectedInitializer.outputs.length - numClassFields;

          // get types of redirecting initializer outputs, ignoring the class
          // fields
          superOrRedirectedInitializerArgs = redirectedInitializer.outputs
              .sublist(0, numRedirectedContextAndConstructorArgs);
        }
      }
    }

    // Get this classes's field types
    final List<w.ValueType> fieldTypes = info.getClassFieldTypes();

    // Add nullable context reference for when the constructor has a non-empty
    // context
    Context? context = closures.contexts[node];
    w.ValueType? contextRef = null;

    if (context != null) {
      assert(!context.isEmpty);
      contextRef = w.RefType.struct(nullable: true);
    }

    final List<w.ValueType> outputs = superOrRedirectedInitializerArgs +
        arguments.reversed.toList() +
        (contextRef != null ? [contextRef] : []) +
        fieldTypes;

    return translator.m.types.defineFunction(arguments, outputs);
  }

  w.FunctionType _getConstructorBodyType(
      Constructor node, List<w.ValueType> arguments) {
    assert(translator.constructorClosures.containsKey(node.reference));
    Closures closures = translator.constructorClosures[node.reference]!;
    Context? context = closures.contexts[node];

    List<w.ValueType> inputs = [
      translator.classInfo[node.enclosingClass]!.nonNullableType.unpacked
    ];

    if (context != null) {
      assert(!context.isEmpty);
      // Nullable context reference for when the constructor has a non-empty
      // context
      w.ValueType contextRef = w.RefType.struct(nullable: true);
      inputs.add(contextRef);
    }

    inputs += arguments;

    for (Initializer initializer in node.initializers) {
      if (initializer is SuperInitializer ||
          initializer is RedirectingInitializer) {
        Constructor target = initializer is SuperInitializer
            ? initializer.target
            : (initializer as RedirectingInitializer).target;

        Supertype? supersupertype = target.enclosingClass.supertype;

        if (supersupertype != null) {
          w.FunctionType superOrRedirectedConstructorBodyType = translator
              .functions
              .getFunctionType(target.constructorBodyReference);

          // drop receiver param
          inputs += superOrRedirectedConstructorBodyType.inputs.sublist(1);
        }
      }
    }

    return translator.m.types.defineFunction(inputs, []);
  }
}

List<w.ValueType> _getInputTypes(
    Translator translator,
    Reference target,
    w.ValueType? receiverType,
    bool isImportOrExport,
    w.ValueType Function(DartType) translateType) {
  Member member = target.asMember;
  int typeParamCount = 0;
  Iterable<DartType> params;
  if (member is Field) {
    params = [if (target.isImplicitSetter) member.setterType];
  } else {
    FunctionNode function = member.function!;
    typeParamCount = (member is Constructor
            ? member.enclosingClass.typeParameters
            : function.typeParameters)
        .length;
    List<String> names = [for (var p in function.namedParameters) p.name!]
      ..sort();
    Map<String, DartType> nameTypes = {
      for (var p in function.namedParameters) p.name!: p.type
    };
    params = [
      for (var p in function.positionalParameters) p.type,
      for (String name in names) nameTypes[name]!
    ];
    function.positionalParameters.map((p) => p.type);
  }

  final List<w.ValueType> typeParameters = List.filled(
      typeParamCount,
      translateType(
          InterfaceType(translator.typeClass, Nullability.nonNullable)));

  final List<w.ValueType> inputs = [];

  if (receiverType != null) {
    assert(!isImportOrExport);
    inputs.add(receiverType);
  }

  inputs.addAll(typeParameters);
  inputs.addAll(params.map(translateType));

  return inputs;
}

w.FunctionType _makeFunctionType(Translator translator, Reference target,
    List<DartType> returnTypes, w.ValueType? receiverType,
    {bool isImportOrExport = false}) {
  Member member = target.asMember;

  // Translate types differently for imports and exports.
  w.ValueType translateType(DartType type) => isImportOrExport
      ? translator.translateExternalType(type)
      : translator.translateType(type);

  final List<w.ValueType> inputs = _getInputTypes(
      translator, target, receiverType, isImportOrExport, translateType);

  // Mutable fields have initializer setters with a non-empty output list,
  // so check that the member is a Procedure
  final bool emptyOutputList = member is Procedure && member.isSetter;

  bool isVoidType(DartType t) =>
      (isImportOrExport && t is VoidType) ||
      (t is InterfaceType && t.classNode == translator.wasmVoidClass);

  final List<w.ValueType> outputs = emptyOutputList
      ? const []
      : returnTypes
          .where((t) => !isVoidType(t))
          .map((t) => translateType(t))
          .toList();

  return translator.m.types.defineFunction(inputs, outputs);
}
