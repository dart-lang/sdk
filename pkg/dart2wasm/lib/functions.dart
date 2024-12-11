// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'dispatch_table.dart';
import 'reference_extensions.dart';
import 'translator.dart';

/// This class is responsible for collecting import and export annotations.
/// It also creates Wasm functions for Dart members and manages the compilation
/// queue used to achieve tree shaking.
class FunctionCollector {
  final Translator translator;

  // Wasm function for each Dart function
  final Map<Reference, w.BaseFunction> _functions = {};
  // Wasm function for each function expression and local function.
  final Map<Lambda, w.BaseFunction> _lambdas = {};
  // Names of exported functions
  final Map<Reference, String> _exports = {};
  // Selector IDs that are invoked via GDT.
  final Set<int> _calledSelectors = {};
  // Class IDs for classes that are allocated somewhere in the program
  final Set<int> _allocatedClasses = {};
  // For each class ID, which functions should be added to the compilation queue
  // if an allocation of that class is encountered
  final Map<int, List<Reference>> _pendingAllocation = {};

  FunctionCollector(this.translator);

  void _collectImportsAndExports() {
    for (Library library in translator.libraries) {
      library.procedures.forEach(_importOrExport);
      library.fields.forEach(_importOrExport);
      for (Class cls in library.classes) {
        cls.procedures.forEach(_importOrExport);
      }
    }
  }

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
          w.FunctionType ftype = _makeFunctionType(
              translator, member.reference, null,
              isImportOrExport: true);
          _functions[member.reference] = translator
              .moduleForReference(member.reference)
              .functions
              .import(module, name, ftype, "$importName (import)");
        }
      }
    }
    String? exportName =
        translator.getPragma(member, "wasm:export", member.name.text);
    if (exportName != null) {
      if (member is Procedure) {
        _makeFunctionType(translator, member.reference, null,
            isImportOrExport: true);
      }
      _exports[member.reference] = exportName;
    }
  }

  /// If the member with the reference [target] is exported, get the export
  /// name.
  String? getExportName(Reference target) => _exports[target];

  void initialize() {
    _collectImportsAndExports();

    // Add exports to the module and add exported functions to the
    // compilationQueue.
    for (var export in _exports.entries) {
      Reference target = export.key;
      Member node = target.asMember;
      if (node is Procedure) {
        assert(!node.isInstanceMember);
        assert(!node.isGetter);
        w.FunctionType ftype =
            _makeFunctionType(translator, target, null, isImportOrExport: true);
        final module = translator.moduleForReference(target);
        w.FunctionBuilder function = module.functions.define(ftype, "$node");
        _functions[target] = function;
        module.exports.export(export.value, function);
        translator.compilationQueue.add(AstCompilationTask(function,
            getMemberCodeGenerator(translator, function, target), target));
      } else if (node is Field) {
        final module = translator.moduleForReference(target);
        w.Table? table = translator.getTable(module, node);
        if (table != null) {
          module.exports.export(export.value, table);
        }
      }
    }

    // Value classes are always implicitly allocated.
    recordClassAllocation(
        translator.classInfo[translator.boxedBoolClass]!.classId);
    recordClassAllocation(
        translator.classInfo[translator.boxedIntClass]!.classId);
    recordClassAllocation(
        translator.classInfo[translator.boxedDoubleClass]!.classId);
  }

  w.BaseFunction? getExistingFunction(Reference target) {
    return _functions[target];
  }

  w.BaseFunction getFunction(Reference target) {
    return _functions.putIfAbsent(target, () {
      final module = translator.moduleForReference(target);
      final function = module.functions.define(
          translator.signatureForDirectCall(target), getFunctionName(target));
      translator.compilationQueue.add(AstCompilationTask(function,
          getMemberCodeGenerator(translator, function, target), target));
      return function;
    });
  }

  w.BaseFunction getLambdaFunction(
      Lambda lambda, Member enclosingMember, Closures enclosingMemberClosures) {
    return _lambdas.putIfAbsent(lambda, () {
      translator.compilationQueue.add(CompilationTask(
          lambda.function,
          getLambdaCodeGenerator(
              translator, lambda, enclosingMember, enclosingMemberClosures)));
      return lambda.function;
    });
  }

  w.FunctionType getFunctionType(Reference target) {
    // We first try to get the function type by seeing if we already
    // compiled the [target] function.
    //
    // We do that because [target] may refer to a imported/exported function
    // which get their function type translated differently (it would be
    // incorrect to use [_getFunctionType]).
    final existingFunction = getExistingFunction(target);
    if (existingFunction != null) return existingFunction.type;

    return _getFunctionType(target);
  }

  w.FunctionType _getFunctionType(Reference target) {
    final Member member = target.asMember;
    if (target.isTypeCheckerReference) {
      if (member is Field || (member is Procedure && member.isSetter)) {
        return translator.dynamicSetForwarderFunctionType;
      } else {
        return translator.dynamicInvocationForwarderFunctionType;
      }
    }

    if (target.isTearOffReference) {
      assert(!translator.dispatchTable
          .selectorForTarget(target)
          .targetSet
          .contains(target));
      return translator.signatureForDirectCall(target);
    }

    return member.accept1(_FunctionTypeGenerator(translator), target);
  }

  String getFunctionName(Reference target) {
    if (target.isTearOffReference) {
      return "${target.asMember} tear-off";
    }

    final Member member = target.asMember;
    String memberName = member.toString();
    if (memberName.endsWith('.')) {
      memberName = memberName.substring(0, memberName.length - 1);
    }

    if (target.isTypeCheckerReference) {
      if (member is Field || (member is Procedure && member.isSetter)) {
        return '$memberName setter type checker';
      } else {
        return '$memberName invocation type checker';
      }
    }

    if (member is Field) {
      return '$memberName initializer';
    }

    if (target.isInitializerReference) {
      return 'new $memberName (initializer)';
    } else if (target.isConstructorBodyReference) {
      return 'new $memberName (constructor body)';
    } else if (member is Procedure && member.isFactory) {
      return 'new $memberName';
    } else {
      return memberName;
    }
  }

  void recordSelectorUse(SelectorInfo selector) {
    if (_calledSelectors.add(selector.id)) {
      for (final (:range, :target) in selector.targetRanges) {
        for (int classId = range.start; classId <= range.end; ++classId) {
          if (_allocatedClasses.contains(classId)) {
            // Class declaring or inheriting member is allocated somewhere.
            getFunction(target);
          } else {
            // Remember the member in case an allocation is encountered later.
            _pendingAllocation.putIfAbsent(classId, () => []).add(target);
          }
        }
      }
    }
  }

  void recordClassAllocation(int classId) {
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
      // Static field initializer function or implicit getter/setter.
      return _makeFunctionType(translator, target, null);
    }
    assert(!translator.dispatchTable
        .selectorForTarget(target)
        .targetSet
        .contains(target));

    final receiverType = target.asMember.enclosingClass!
        .getThisType(translator.coreTypes, Nullability.nonNullable);
    return _makeFunctionType(
        translator, target, translator.translateType(receiverType));
  }

  @override
  w.FunctionType visitProcedure(Procedure node, Reference target) {
    assert(!node.isAbstract);
    if (!node.isInstanceMember) {
      return _makeFunctionType(translator, target, null);
    }

    assert(!translator.dispatchTable
        .selectorForTarget(target)
        .targetSet
        .contains(target));

    final receiverType = target.asMember.enclosingClass!
        .getThisType(translator.coreTypes, Nullability.nonNullable);
    return _makeFunctionType(
        translator, target, translator.translateType(receiverType));
  }

  @override
  w.FunctionType visitConstructor(Constructor node, Reference target) {
    // Get this constructor's argument types
    List<w.ValueType> arguments = _getInputTypes(
        translator, target, null, false, translator.translateType);

    // We need the contexts of the constructor before generating the initializer
    // and constructor body functions, as these functions will return/take a
    // context argument if context must be shared between them. Generate the
    // contexts the first time we visit a constructor.
    translator.constructorClosures[node.reference] ??=
        translator.getClosures(node);

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
    return translator.typesBuilder.defineFunction(arguments,
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
          w.FunctionType superInitializer = translator
              .signatureForDirectCall(initializer.target.initializerReference);

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
          w.FunctionType redirectedInitializer = translator
              .signatureForDirectCall(initializer.target.initializerReference);

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
    w.ValueType? contextRef;

    if (context != null) {
      assert(!context.isEmpty);
      contextRef = w.RefType.struct(nullable: true);
    }

    final List<w.ValueType> outputs = superOrRedirectedInitializerArgs +
        arguments.reversed.toList() +
        (contextRef != null ? [contextRef] : []) +
        fieldTypes;

    return translator.typesBuilder.defineFunction(arguments, outputs);
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
              .signatureForDirectCall(target.constructorBodyReference);

          // drop receiver param
          inputs += superOrRedirectedConstructorBodyType.inputs.sublist(1);
        }
      }
    }

    return translator.typesBuilder.defineFunction(inputs, []);
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
    final typeForParam = translator.typeOfParameterVariable;
    Map<String, DartType> nameTypes = {
      for (var p in function.namedParameters)
        p.name!: typeForParam(p, p.isRequired)
    };
    final positionals = function.positionalParameters;
    params = [
      for (int i = 0; i < positionals.length; ++i)
        typeForParam(positionals[i], i < function.requiredParameterCount),
      for (String name in names) nameTypes[name]!
    ];
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

w.FunctionType _makeFunctionType(
    Translator translator, Reference target, w.ValueType? receiverType,
    {bool isImportOrExport = false}) {
  Member member = target.asMember;

  if (member is Field && !member.isInstanceMember) {
    final isGetter = target.isImplicitGetter;
    final isSetter = target.isImplicitSetter;
    if (isGetter || isSetter) {
      final global = translator.globals.getGlobalForStaticField(member);
      final globalType = global.type.type;
      if (isGetter) {
        return translator.typesBuilder.defineFunction(const [], [globalType]);
      }
      return translator.typesBuilder.defineFunction([globalType], const []);
    }
  }

  // Translate types differently for imports and exports.
  w.ValueType translateType(DartType type) => isImportOrExport
      ? translator.translateExternalType(type)
      : translator.translateType(type);

  final List<w.ValueType> inputs = _getInputTypes(
      translator, target, receiverType, isImportOrExport, translateType);

  // Setters don't have an output with the exception of static implicit setters.
  final bool emptyOutputList =
      (member is Field && member.setterReference == target) ||
          (member is Procedure && member.isSetter);

  bool isVoidType(DartType t) =>
      (isImportOrExport && t is VoidType) ||
      (t is InterfaceType && t.classNode == translator.wasmVoidClass);

  final List<w.ValueType> outputs;
  if (emptyOutputList) {
    outputs = const [];
  } else {
    final DartType returnType = translator.typeOfReturnValue(member);
    outputs = !isVoidType(returnType) ? [translateType(returnType)] : const [];
  }

  return translator.typesBuilder.defineFunction(inputs, outputs);
}
