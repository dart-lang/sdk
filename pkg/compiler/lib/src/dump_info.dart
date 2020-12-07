// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dump_info;

import 'dart:convert'
    show ChunkedConversionSink, JsonEncoder, StringConversionSink;

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/binary_serialization.dart' as dump_info;

import '../compiler_new.dart';
import 'backend_strategy.dart';
import 'common/names.dart';
import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'common_elements.dart' show JElementEnvironment;
import 'compiler.dart' show Compiler;
import 'constants/values.dart' show ConstantValue, InterceptorConstantValue;
import 'deferred_load.dart' show OutputUnit, deferredPartFileName;
import 'elements/entities.dart';
import 'inferrer/abstract_value_domain.dart';
import 'inferrer/types.dart'
    show GlobalTypeInferenceMemberResult, GlobalTypeInferenceResults;
import 'js/js.dart' as jsAst;
import 'js_backend/field_analysis.dart';
import 'universe/codegen_world_builder.dart';
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import 'util/sink_adapter.dart';
import 'world.dart' show JClosedWorld;

class ElementInfoCollector {
  final Compiler compiler;
  final JClosedWorld closedWorld;
  final GlobalTypeInferenceResults _globalInferenceResults;
  final DumpInfoTask dumpInfoTask;

  JElementEnvironment get environment => closedWorld.elementEnvironment;
  CodegenWorldBuilder get codegenWorldBuilder => compiler.codegenWorldBuilder;

  final AllInfo result = new AllInfo();
  final Map<Entity, Info> _entityToInfo = <Entity, Info>{};
  final Map<ConstantValue, Info> _constantToInfo = <ConstantValue, Info>{};
  final Map<OutputUnit, OutputUnitInfo> _outputToInfo = {};

  ElementInfoCollector(this.compiler, this.dumpInfoTask, this.closedWorld,
      this._globalInferenceResults);

  void run() {
    dumpInfoTask._constantToNode.forEach((constant, node) {
      // TODO(sigmund): add dependencies on other constants
      var span = dumpInfoTask._nodeData[node];
      var info = new ConstantInfo(
          size: span.end - span.start,
          code: [span],
          outputUnit: _unitInfoForConstant(constant));
      _constantToInfo[constant] = info;
      result.constants.add(info);
    });
    environment.libraries.forEach(visitLibrary);
  }

  /// Whether to emit information about [entity].
  ///
  /// By default we emit information for any entity that contributes to the
  /// output size. Either because it is a function being emitted or inlined,
  /// or because it is an entity that holds dependencies to other entities.
  bool shouldKeep(Entity entity) {
    return dumpInfoTask.impacts.containsKey(entity) ||
        dumpInfoTask.inlineCount.containsKey(entity);
  }

  LibraryInfo visitLibrary(LibraryEntity lib) {
    String libname = environment.getLibraryName(lib);
    if (libname.isEmpty) {
      libname = '<unnamed>';
    }
    int size = dumpInfoTask.sizeOf(lib);
    LibraryInfo info = new LibraryInfo(libname, lib.canonicalUri, null, size);
    _entityToInfo[lib] = info;

    environment.forEachLibraryMember(lib, (MemberEntity member) {
      if (member.isFunction || member.isGetter || member.isSetter) {
        FunctionInfo functionInfo = visitFunction(member);
        if (functionInfo != null) {
          info.topLevelFunctions.add(functionInfo);
          functionInfo.parent = info;
        }
      } else if (member.isField) {
        FieldInfo fieldInfo = visitField(member);
        if (fieldInfo != null) {
          info.topLevelVariables.add(fieldInfo);
          fieldInfo.parent = info;
        }
      }
    });

    environment.forEachClass(lib, (ClassEntity clazz) {
      ClassInfo classInfo = visitClass(clazz);
      if (classInfo != null) {
        info.classes.add(classInfo);
        classInfo.parent = info;
      }
    });

    if (info.isEmpty && !shouldKeep(lib)) return null;
    result.libraries.add(info);
    return info;
  }

  GlobalTypeInferenceMemberResult _resultOfMember(MemberEntity e) =>
      _globalInferenceResults.resultOfMember(e);

  AbstractValue _resultOfParameter(Local e) =>
      _globalInferenceResults.resultOfParameter(e);

  FieldInfo visitField(FieldEntity field, {ClassEntity containingClass}) {
    AbstractValue inferredType = _resultOfMember(field).type;
    // If a field has an empty inferred type it is never used.
    if (inferredType == null ||
        closedWorld.abstractValueDomain
            .isEmpty(inferredType)
            .isDefinitelyTrue) {
      return null;
    }

    int size = dumpInfoTask.sizeOf(field);
    List<CodeSpan> code = dumpInfoTask.codeOf(field);

    // TODO(het): Why doesn't `size` account for the code size already?
    if (code != null) size += code.length;

    FieldInfo info = new FieldInfo(
        name: field.name,
        type: '${environment.getFieldType(field)}',
        inferredType: '$inferredType',
        code: code,
        outputUnit: _unitInfoForMember(field),
        isConst: field.isConst);
    _entityToInfo[field] = info;
    FieldAnalysisData fieldData = closedWorld.fieldAnalysis.getFieldData(field);
    if (fieldData.initialValue != null) {
      info.initializer = _constantToInfo[fieldData.initialValue];
    }

    if (compiler.options.experimentCallInstrumentation) {
      // We use field.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${field.hashCode}';
    }

    int closureSize = _addClosureInfo(info, field);
    info.size = size + closureSize;

    result.fields.add(info);
    return info;
  }

  ClassInfo visitClass(ClassEntity clazz) {
    // Omit class if it is not needed.
    ClassInfo classInfo = new ClassInfo(
        name: clazz.name,
        isAbstract: clazz.isAbstract,
        outputUnit: _unitInfoForClass(clazz));
    _entityToInfo[clazz] = classInfo;

    int size = dumpInfoTask.sizeOf(clazz);
    environment.forEachLocalClassMember(clazz, (member) {
      if (member.isFunction || member.isGetter || member.isSetter) {
        FunctionInfo functionInfo = visitFunction(member);
        if (functionInfo != null) {
          classInfo.functions.add(functionInfo);
          functionInfo.parent = classInfo;
          for (var closureInfo in functionInfo.closures) {
            size += closureInfo.size;
          }
        }
      } else if (member.isField) {
        FieldInfo fieldInfo = visitField(member, containingClass: clazz);
        if (fieldInfo != null) {
          classInfo.fields.add(fieldInfo);
          fieldInfo.parent = classInfo;
          for (var closureInfo in fieldInfo.closures) {
            size += closureInfo.size;
          }
        }
      } else {
        throw new StateError('Class member not a function or field');
      }
    });
    environment.forEachConstructor(clazz, (constructor) {
      FunctionInfo functionInfo = visitFunction(constructor);
      if (functionInfo != null) {
        classInfo.functions.add(functionInfo);
        functionInfo.parent = classInfo;
        for (var closureInfo in functionInfo.closures) {
          size += closureInfo.size;
        }
      }
    });

    classInfo.size = size;

    if (!compiler.backendStrategy.emitterTask.neededClasses.contains(clazz) &&
        classInfo.fields.isEmpty &&
        classInfo.functions.isEmpty) {
      return null;
    }

    result.classes.add(classInfo);
    return classInfo;
  }

  ClosureInfo visitClosureClass(ClassEntity element) {
    ClosureInfo closureInfo = new ClosureInfo(
        name: element.name,
        outputUnit: _unitInfoForClass(element),
        size: dumpInfoTask.sizeOf(element));
    _entityToInfo[element] = closureInfo;

    FunctionEntity callMethod = closedWorld.elementEnvironment
        .lookupClassMember(element, Identifiers.call);

    FunctionInfo functionInfo = visitFunction(callMethod);
    if (functionInfo == null) return null;
    closureInfo.function = functionInfo;
    functionInfo.parent = closureInfo;

    result.closures.add(closureInfo);
    return closureInfo;
  }

  FunctionInfo visitFunction(FunctionEntity function) {
    int size = dumpInfoTask.sizeOf(function);
    // TODO(sigmund): consider adding a small info to represent unreachable
    // code here.
    if (size == 0 && !shouldKeep(function)) return null;

    // TODO(het): use 'toString' instead of 'text'? It will add '=' for setters
    String name = function.memberName.text;
    int kind;
    if (function.isStatic || function.isTopLevel) {
      kind = FunctionInfo.TOP_LEVEL_FUNCTION_KIND;
    } else if (function.enclosingClass != null) {
      kind = FunctionInfo.METHOD_FUNCTION_KIND;
    }

    if (function.isConstructor) {
      name = name == ""
          ? "${function.enclosingClass.name}"
          : "${function.enclosingClass.name}.${function.name}";
      kind = FunctionInfo.CONSTRUCTOR_FUNCTION_KIND;
    }

    assert(kind != null);

    FunctionModifiers modifiers = new FunctionModifiers(
      isStatic: function.isStatic,
      isConst: function.isConst,
      isFactory: function.isConstructor
          ? (function as ConstructorEntity).isFactoryConstructor
          : false,
      isExternal: function.isExternal,
    );
    List<CodeSpan> code = dumpInfoTask.codeOf(function);

    List<ParameterInfo> parameters = <ParameterInfo>[];
    List<String> inferredParameterTypes = <String>[];

    closedWorld.elementEnvironment.forEachParameterAsLocal(
        closedWorld.globalLocalsMap, function, (parameter) {
      inferredParameterTypes.add('${_resultOfParameter(parameter)}');
    });
    int parameterIndex = 0;
    closedWorld.elementEnvironment.forEachParameter(function, (type, name, _) {
      // Synthesized parameters have no name. This can happen on parameters of
      // setters derived from lowering late fields.
      parameters.add(new ParameterInfo(name ?? '#t${parameterIndex}',
          inferredParameterTypes[parameterIndex++], '$type'));
    });

    var functionType = environment.getFunctionType(function);
    String returnType = '${functionType.returnType}';

    String inferredReturnType = '${_resultOfMember(function).returnType}';
    String sideEffects =
        '${_globalInferenceResults.inferredData.getSideEffectsOfElement(function)}';

    int inlinedCount = dumpInfoTask.inlineCount[function];
    if (inlinedCount == null) inlinedCount = 0;

    FunctionInfo info = new FunctionInfo(
        name: name,
        functionKind: kind,
        modifiers: modifiers,
        returnType: returnType,
        inferredReturnType: inferredReturnType,
        parameters: parameters,
        sideEffects: sideEffects,
        inlinedCount: inlinedCount,
        code: code,
        type: functionType.toString(),
        outputUnit: _unitInfoForMember(function));
    _entityToInfo[function] = info;

    int closureSize = _addClosureInfo(info, function);
    size += closureSize;

    if (compiler.options.experimentCallInstrumentation) {
      // We use function.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${function.hashCode}';
    }

    info.size = size;

    result.functions.add(info);
    return info;
  }

  /// Adds closure information to [info], using all nested closures in [member].
  ///
  /// Returns the total size of the nested closures, to add to the info size.
  int _addClosureInfo(Info info, MemberEntity member) {
    assert(info is FunctionInfo || info is FieldInfo);
    int size = 0;
    List<ClosureInfo> nestedClosures = <ClosureInfo>[];
    environment.forEachNestedClosure(member, (closure) {
      ClosureInfo closureInfo = visitClosureClass(closure.enclosingClass);
      if (closureInfo != null) {
        closureInfo.parent = info;
        nestedClosures.add(closureInfo);
        size += closureInfo.size;
      }
    });
    if (info is FunctionInfo) info.closures = nestedClosures;
    if (info is FieldInfo) info.closures = nestedClosures;

    return size;
  }

  OutputUnitInfo _infoFromOutputUnit(OutputUnit outputUnit) {
    return _outputToInfo.putIfAbsent(outputUnit, () {
      // Dump-info currently only works with the full emitter. If another
      // emitter is used it will fail here.
      BackendStrategy backendStrategy = compiler.backendStrategy;
      assert(outputUnit.name != null || outputUnit.isMainOutput);
      var filename = outputUnit.isMainOutput
          ? compiler.options.outputUri.pathSegments.last
          : deferredPartFileName(compiler.options, outputUnit.name);
      OutputUnitInfo info = new OutputUnitInfo(filename, outputUnit.name,
          backendStrategy.emitterTask.emitter.generatedSize(outputUnit));
      info.imports
          .addAll(closedWorld.outputUnitData.getImportNames(outputUnit));
      result.outputUnits.add(info);
      return info;
    });
  }

  OutputUnitInfo _unitInfoForMember(MemberEntity entity) {
    return _infoFromOutputUnit(
        closedWorld.outputUnitData.outputUnitForMember(entity));
  }

  OutputUnitInfo _unitInfoForClass(ClassEntity entity) {
    return _infoFromOutputUnit(
        closedWorld.outputUnitData.outputUnitForClass(entity, allowNull: true));
  }

  OutputUnitInfo _unitInfoForConstant(ConstantValue constant) {
    OutputUnit outputUnit =
        closedWorld.outputUnitData.outputUnitForConstant(constant);
    if (outputUnit == null) {
      assert(constant is InterceptorConstantValue);
      return null;
    }
    return _infoFromOutputUnit(outputUnit);
  }
}

class Selection {
  final Entity selectedEntity;
  final Object receiverConstraint;
  Selection(this.selectedEntity, this.receiverConstraint);
}

/// Interface used to record information from different parts of the compiler so
/// we can emit them in the dump-info task.
// TODO(sigmund,het): move more features here. Ideally the dump-info task
// shouldn't reach into internals of other parts of the compiler. For example,
// we currently reach into the full emitter and as a result we don't support
// dump-info when using the startup-emitter (issue #24190).
abstract class InfoReporter {
  void reportInlined(FunctionEntity element, MemberEntity inlinedFrom);
}

class DumpInfoTask extends CompilerTask implements InfoReporter {
  static const ImpactUseCase IMPACT_USE = const ImpactUseCase('Dump info');
  final Compiler compiler;
  final bool useBinaryFormat;

  DumpInfoTask(this.compiler)
      : useBinaryFormat = compiler.options.useDumpInfoBinaryFormat,
        super(compiler.measurer);

  @override
  String get name => "Dump Info";

  ElementInfoCollector infoCollector;

  /// The size of the generated output.
  int _programSize;

  /// Data associated with javascript AST nodes. The map only contains keys for
  /// nodes that we care about.  Keys are automatically added when
  /// [registerEntityAst] is called.
  final Map<jsAst.Node, CodeSpan> _nodeData = <jsAst.Node, CodeSpan>{};

  // A mapping from Dart Entities to Javascript AST Nodes.
  final Map<Entity, List<jsAst.Node>> _entityToNodes =
      <Entity, List<jsAst.Node>>{};
  final Map<ConstantValue, jsAst.Node> _constantToNode =
      <ConstantValue, jsAst.Node>{};

  final Map<Entity, int> inlineCount = <Entity, int>{};

  // A mapping from an entity to a list of entities that are
  // inlined inside of it.
  final Map<Entity, List<Entity>> inlineMap = <Entity, List<Entity>>{};

  final Map<MemberEntity, WorldImpact> impacts = <MemberEntity, WorldImpact>{};

  /// Register the size of the generated output.
  void reportSize(int programSize) {
    _programSize = programSize;
  }

  @override
  void reportInlined(FunctionEntity element, MemberEntity inlinedFrom) {
    inlineCount.putIfAbsent(element, () => 0);
    inlineCount[element] += 1;
    inlineMap.putIfAbsent(inlinedFrom, () => <Entity>[]);
    inlineMap[inlinedFrom].add(element);
  }

  void registerImpact(MemberEntity member, WorldImpact impact) {
    if (compiler.options.dumpInfo) {
      impacts[member] = impact;
    }
  }

  void unregisterImpact(var impactSource) {
    impacts.remove(impactSource);
  }

  /// Returns an iterable of [Selection]s that are used by [entity]. Each
  /// [Selection] contains an entity that is used and the selector that
  /// selected the entity.
  Iterable<Selection> getRetaining(Entity entity, JClosedWorld closedWorld) {
    WorldImpact impact = impacts[entity];
    if (impact == null) return const <Selection>[];

    var selections = <Selection>[];
    compiler.impactStrategy.visitImpact(
        entity,
        impact,
        new WorldImpactVisitorImpl(visitDynamicUse: (member, dynamicUse) {
          AbstractValue mask = dynamicUse.receiverConstraint;
          selections.addAll(closedWorld
              // TODO(het): Handle `call` on `Closure` through
              // `world.includesClosureCall`.
              .locateMembers(dynamicUse.selector, mask)
              .map((MemberEntity e) => new Selection(e, mask)));
        }, visitStaticUse: (member, staticUse) {
          selections.add(new Selection(staticUse.element, null));
        }),
        IMPACT_USE);
    return selections;
  }

  /// Registers that a javascript AST node [code] was produced by the dart
  /// Entity [entity].
  void registerEntityAst(Entity entity, jsAst.Node code,
      {LibraryEntity library}) {
    if (compiler.options.dumpInfo) {
      _entityToNodes.putIfAbsent(entity, () => <jsAst.Node>[]).add(code);
      _nodeData[code] ??= useBinaryFormat ? new CodeSpan() : new _CodeData();
    }
  }

  void registerConstantAst(ConstantValue constant, jsAst.Node code) {
    if (compiler.options.dumpInfo) {
      assert(_constantToNode[constant] == null ||
          _constantToNode[constant] == code);
      _constantToNode[constant] = code;
      _nodeData[code] ??= useBinaryFormat ? new CodeSpan() : new _CodeData();
    }
  }

  bool get shouldEmitText => !useBinaryFormat;
  // TODO(sigmund): delete the stack once we stop emitting the source text.
  List<_CodeData> _stack = [];
  void enterNode(jsAst.Node node, int start) {
    var data = _nodeData[node];
    data?.start = start;

    if (shouldEmitText && data != null) {
      _stack.add(data);
    }
  }

  void emit(String string) {
    if (shouldEmitText) {
      // Note: historically we emitted the full body of classes and methods, so
      // instance methods ended up emitted twice.  Once we use a different
      // encoding of dump info, we also plan to remove this duplication.
      _stack.forEach((f) => f._text.write(string));
    }
  }

  void exitNode(jsAst.Node node, int start, int end, int closing) {
    var data = _nodeData[node];
    data?.end = end;
    if (shouldEmitText && data != null) {
      var last = _stack.removeLast();
      assert(data == last);
      assert(data.start == start);
    }
  }

  /// Returns the size of the source code that was generated for an entity.
  /// If no source code was produced, return 0.
  int sizeOf(Entity entity) {
    if (_entityToNodes.containsKey(entity)) {
      return _entityToNodes[entity].map(sizeOfNode).fold(0, (a, b) => a + b);
    } else {
      return 0;
    }
  }

  int sizeOfNode(jsAst.Node node) {
    CodeSpan span = _nodeData[node];
    if (span == null) return 0;
    return span.end - span.start;
  }

  List<CodeSpan> codeOf(MemberEntity entity) {
    List<jsAst.Node> code = _entityToNodes[entity];
    if (code == null) return const [];
    return code.map((ast) => _nodeData[ast]).toList();
  }

  void dumpInfo(JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) {
    measure(() {
      infoCollector = new ElementInfoCollector(
          compiler, this, closedWorld, globalInferenceResults)
        ..run();

      var allInfo = buildDumpInfoData(closedWorld);
      if (useBinaryFormat) {
        dumpInfoBinary(allInfo);
      } else {
        dumpInfoJson(allInfo);
      }
    });
  }

  void dumpInfoJson(AllInfo data) {
    StringBuffer jsonBuffer = new StringBuffer();
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    ChunkedConversionSink<Object> sink = encoder.startChunkedConversion(
        new StringConversionSink.fromStringSink(jsonBuffer));
    sink.add(new AllInfoJsonCodec(isBackwardCompatible: true).encode(data));
    compiler.outputProvider.createOutputSink(
        compiler.options.outputUri.pathSegments.last,
        'info.json',
        OutputType.dumpInfo)
      ..add(jsonBuffer.toString())
      ..close();
    compiler.reporter.reportInfo(NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {
      'text': "View the dumped .info.json file at "
          "https://dart-lang.github.io/dump-info-visualizer"
    });
  }

  void dumpInfoBinary(AllInfo data) {
    var name = compiler.options.outputUri.pathSegments.last + ".info.data";
    Sink<List<int>> sink = new BinaryOutputSinkAdapter(compiler.outputProvider
        .createBinarySink(compiler.options.outputUri.resolve(name)));
    dump_info.encode(data, sink);
    compiler.reporter.reportInfo(NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {
      'text': "Use `package:dart2js_info` to parse and process the dumped "
          ".info.data file."
    });
  }

  AllInfo buildDumpInfoData(JClosedWorld closedWorld) {
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();

    AllInfo result = infoCollector.result;

    // Recursively build links to function uses
    Iterable<Entity> functionEntities =
        infoCollector._entityToInfo.keys.where((k) => k is FunctionEntity);
    for (FunctionEntity entity in functionEntities) {
      FunctionInfo info = infoCollector._entityToInfo[entity];
      Iterable<Selection> uses = getRetaining(entity, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        // Don't register dart2js builtin functions that are not recorded.
        Info useInfo = infoCollector._entityToInfo[selection.selectedEntity];
        if (useInfo == null) continue;
        info.uses.add(new DependencyInfo(
            useInfo, selection.receiverConstraint?.toString()));
      }
    }

    // Recursively build links to field uses
    Iterable<Entity> fieldEntity =
        infoCollector._entityToInfo.keys.where((k) => k is FieldEntity);
    for (FieldEntity entity in fieldEntity) {
      FieldInfo info = infoCollector._entityToInfo[entity];
      Iterable<Selection> uses = getRetaining(entity, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        Info useInfo = infoCollector._entityToInfo[selection.selectedEntity];
        if (useInfo == null) continue;
        info.uses.add(new DependencyInfo(
            useInfo, selection.receiverConstraint?.toString()));
      }
    }

    // Notify the impact strategy impacts are no longer needed for dump info.
    compiler.impactStrategy.onImpactUsed(IMPACT_USE);

    // Track dependencies that come from inlining.
    for (Entity entity in inlineMap.keys) {
      CodeInfo outerInfo = infoCollector._entityToInfo[entity];
      if (outerInfo == null) continue;
      for (Entity inlined in inlineMap[entity]) {
        Info inlinedInfo = infoCollector._entityToInfo[inlined];
        if (inlinedInfo == null) continue;
        outerInfo.uses.add(new DependencyInfo(inlinedInfo, 'inlined'));
      }
    }

    result.deferredFiles = closedWorld.outputUnitData
        .computeDeferredMap(compiler.options, closedWorld.elementEnvironment);
    stopwatch.stop();

    result.program = new ProgramInfo(
        entrypoint: infoCollector
            ._entityToInfo[closedWorld.elementEnvironment.mainFunction],
        size: _programSize,
        dart2jsVersion:
            compiler.options.hasBuildId ? compiler.options.buildId : null,
        compilationMoment: new DateTime.now(),
        compilationDuration: compiler.measurer.elapsedWallClock,
        toJsonDuration:
            new Duration(milliseconds: stopwatch.elapsedMilliseconds),
        dumpInfoDuration: new Duration(milliseconds: this.timing),
        noSuchMethodEnabled: closedWorld.backendUsage.isNoSuchMethodUsed,
        isRuntimeTypeUsed: closedWorld.backendUsage.isRuntimeTypeUsed,
        isIsolateInUse: false,
        isFunctionApplyUsed: closedWorld.backendUsage.isFunctionApplyUsed,
        isMirrorsUsed: closedWorld.backendUsage.isMirrorsUsed,
        minified: compiler.options.enableMinification);

    return result;
  }
}

/// Helper class to store what dump-info will show for a piece of code.
// TODO(sigmund): delete once we no longer emit text by default.
class _CodeData extends CodeSpan {
  StringBuffer _text = new StringBuffer();
  @override
  String get text => '$_text';
  int get length => end - start;
}
