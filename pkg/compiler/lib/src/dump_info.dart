// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dump_info;

import 'dart:convert'
    show ChunkedConversionSink, JsonEncoder, StringConversionSink;

import 'package:dart2js_info/info.dart';

import '../compiler_new.dart';
import 'closure.dart';
import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'common_elements.dart';
import 'compiler.dart' show Compiler;
import 'constants/values.dart' show ConstantValue, InterceptorConstantValue;
import 'deferred_load.dart' show OutputUnit;
import 'elements/elements.dart';
import 'elements/entities.dart';
import 'js/js.dart' as jsAst;
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'types/types.dart'
    show
        GlobalTypeInferenceElementResult,
        GlobalTypeInferenceMemberResult,
        TypeMask;
import 'universe/world_builder.dart'
    show CodegenWorldBuilder, ReceiverConstraint;
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import 'world.dart' show ClosedWorld;

class ElementInfoCollector {
  final Compiler compiler;
  final ClosedWorld closedWorld;

  ElementEnvironment get environment => closedWorld.elementEnvironment;
  CodegenWorldBuilder get codegenWorldBuilder => compiler.codegenWorldBuilder;

  final AllInfo result = new AllInfo();
  final Map<Entity, Info> _entityToInfo = <Entity, Info>{};
  final Map<ConstantValue, Info> _constantToInfo = <ConstantValue, Info>{};
  final Map<OutputUnit, OutputUnitInfo> _outputToInfo = {};

  ElementInfoCollector(this.compiler, this.closedWorld);

  void run() {
    compiler.dumpInfoTask._constantToNode.forEach((constant, node) {
      // TODO(sigmund): add dependencies on other constants
      var size = compiler.dumpInfoTask._nodeToSize[node];
      var code = jsAst.prettyPrint(node, compiler.options);
      var info = new ConstantInfo(
          size: size, code: code, outputUnit: _unitInfoForConstant(constant));
      _constantToInfo[constant] = info;
      result.constants.add(info);
    });
    environment.libraries.forEach(visitLibrary);
    closedWorld.allTypedefs.forEach(visitTypedef);
  }

  /// Whether to emit information about [entity].
  ///
  /// By default we emit information for any entity that contributes to the
  /// output size. Either because it is a function being emitted or inlined,
  /// or because it is an entity that holds dependencies to other entities.
  bool shouldKeep(Entity entity) {
    return compiler.dumpInfoTask.impacts.containsKey(entity) ||
        compiler.dumpInfoTask.inlineCount.containsKey(entity);
  }

  LibraryInfo visitLibrary(LibraryEntity lib) {
    String libname = environment.getLibraryName(lib);
    if (libname.isEmpty) {
      libname = '<unnamed>';
    }
    int size = compiler.dumpInfoTask.sizeOf(lib);
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

  TypedefInfo visitTypedef(TypedefEntity typdef) {
    var type = environment.getFunctionTypeOfTypedef(typdef);
    TypedefInfo info =
        new TypedefInfo(typdef.name, '$type', _unitInfoForEntity(typdef));
    _entityToInfo[typdef] = info;
    LibraryInfo lib = _entityToInfo[typdef.library];
    lib.typedefs.add(info);
    info.parent = lib;
    result.typedefs.add(info);
    return info;
  }

  GlobalTypeInferenceMemberResult _resultOfMember(MemberEntity e) =>
      compiler.globalInference.results.resultOfMember(e);

  GlobalTypeInferenceElementResult _resultOfParameter(Local e) =>
      compiler.globalInference.results.resultOfParameter(e);

  FieldInfo visitField(FieldEntity field) {
    if (!_hasBeenResolved(field)) return null;
    TypeMask inferredType = _resultOfMember(field).type;
    // If a field has an empty inferred type it is never used.
    if (inferredType == null || inferredType.isEmpty) return null;

    int size = compiler.dumpInfoTask.sizeOf(field);
    String code = compiler.dumpInfoTask.codeOf(field);
    if (code != null) size += code.length;

    FieldInfo info = new FieldInfo(
        name: field.name,
        type: '${environment.getFieldType(field)}',
        inferredType: '$inferredType',
        code: code,
        outputUnit: _unitInfoForEntity(field),
        isConst: field.isConst);
    _entityToInfo[field] = info;
    if (codegenWorldBuilder.hasConstantFieldInitializer(field)) {
      info.initializer = _constantToInfo[
          codegenWorldBuilder.getConstantFieldInitializer(field)];
    }

    if (JavaScriptBackend.TRACE_METHOD == 'post') {
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
    if (!_hasClassBeenResolved(clazz)) return null;

    ClassInfo classInfo = new ClassInfo(
        name: clazz.name,
        isAbstract: clazz.isAbstract,
        outputUnit: _unitInfoForEntity(clazz));
    _entityToInfo[clazz] = classInfo;

    int size = compiler.dumpInfoTask.sizeOf(clazz);
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
        FieldInfo fieldInfo = visitField(member);
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
    }, ensureResolved: false);

    classInfo.size = size;

    if (!compiler.backend.emitter.neededClasses.contains(clazz) &&
        classInfo.fields.isEmpty &&
        classInfo.functions.isEmpty) {
      return null;
    }

    result.classes.add(classInfo);
    return classInfo;
  }

  ClosureInfo visitClosureClass(ClosureClassElement element) {
    ClosureInfo closureInfo = new ClosureInfo(
        name: element.name,
        outputUnit: _unitInfoForEntity(element),
        size: compiler.dumpInfoTask.sizeOf(element));
    _entityToInfo[element] = closureInfo;

    ClosureRepresentationInfo closureRepresentation =
        compiler.backendStrategy.closureDataLookup.getClosureInfo(element.node);
    assert(closureRepresentation.closureClassEntity == element);

    FunctionInfo functionInfo = visitFunction(closureRepresentation.callMethod);
    if (functionInfo == null) return null;
    closureInfo.function = functionInfo;
    functionInfo.parent = closureInfo;

    result.closures.add(closureInfo);
    return closureInfo;
  }

  FunctionInfo visitFunction(FunctionEntity function) {
    int size = compiler.dumpInfoTask.sizeOf(function);
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
    String code = compiler.dumpInfoTask.codeOf(function);

    List<ParameterInfo> parameters = <ParameterInfo>[];
    List<String> inferredParameterTypes = <String>[];
    codegenWorldBuilder.forEachParameterAsLocal(function, (parameter) {
      inferredParameterTypes.add('${_resultOfParameter(parameter).type}');
    });
    int parameterIndex = 0;
    codegenWorldBuilder.forEachParameter(function, (type, name, _) {
      parameters.add(new ParameterInfo(
          name, inferredParameterTypes[parameterIndex++], '$type'));
    });

    var functionType = environment.getFunctionType(function);
    String returnType = '${functionType.returnType}';

    String inferredReturnType = '${_resultOfMember(function).returnType}';
    String sideEffects = '${closedWorld.getSideEffectsOfElement(function)}';

    int inlinedCount = compiler.dumpInfoTask.inlineCount[function];
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
        outputUnit: _unitInfoForEntity(function));
    _entityToInfo[function] = info;

    int closureSize = _addClosureInfo(info, function);
    size += closureSize;

    if (JavaScriptBackend.TRACE_METHOD == 'post') {
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
      JavaScriptBackend backend = compiler.backend;
      assert(outputUnit.name != null || outputUnit.isMainOutput);
      OutputUnitInfo info = new OutputUnitInfo(
          outputUnit.name, backend.emitter.emitter.generatedSize(outputUnit));
      info.imports.addAll(compiler.deferredLoadTask.getImportNames(outputUnit));
      result.outputUnits.add(info);
      return info;
    });
  }

  OutputUnitInfo _unitInfoForEntity(Entity entity) {
    return _infoFromOutputUnit(
        compiler.deferredLoadTask.outputUnitForEntity(entity));
  }

  OutputUnitInfo _unitInfoForConstant(ConstantValue constant) {
    OutputUnit outputUnit =
        compiler.deferredLoadTask.outputUnitForConstant(constant);
    if (outputUnit == null) {
      assert(constant is InterceptorConstantValue);
      return null;
    }
    return _infoFromOutputUnit(outputUnit);
  }

  bool _hasBeenResolved(Entity entity) {
    return compiler.enqueuer.codegenEnqueuerForTesting.processedEntities
        .contains(entity);
  }

  bool _hasClassBeenResolved(ClassEntity cls) {
    return compiler.backend.mirrorsData.isClassResolved(cls);
  }
}

class Selection {
  final Entity selectedEntity;
  final ReceiverConstraint mask;
  Selection(this.selectedEntity, this.mask);
}

/// Interface used to record information from different parts of the compiler so
/// we can emit them in the dump-info task.
// TODO(sigmund,het): move more features here. Ideally the dump-info task
// shouldn't reach into internals of other parts of the compiler. For example,
// we currently reach into the full emitter and as a result we don't support
// dump-info when using the startup-emitter (issue #24190).
abstract class InfoReporter {
  void reportInlined(Element element, Element inlinedFrom);
}

class DumpInfoTask extends CompilerTask implements InfoReporter {
  static const ImpactUseCase IMPACT_USE = const ImpactUseCase('Dump info');
  final Compiler compiler;

  DumpInfoTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  String get name => "Dump Info";

  ElementInfoCollector infoCollector;

  /// The size of the generated output.
  int _programSize;

  // A set of javascript AST nodes that we care about the size of.
  // This set is automatically populated when registerEntityAst()
  // is called.
  final Set<jsAst.Node> _tracking = new Set<jsAst.Node>();

  // A mapping from Dart Entities to Javascript AST Nodes.
  final Map<Entity, List<jsAst.Node>> _entityToNodes =
      <Entity, List<jsAst.Node>>{};
  final Map<ConstantValue, jsAst.Node> _constantToNode =
      <ConstantValue, jsAst.Node>{};

  // A mapping from Javascript AST Nodes to the size of their
  // pretty-printed contents.
  final Map<jsAst.Node, int> _nodeToSize = <jsAst.Node, int>{};

  final Map<Entity, int> inlineCount = <Entity, int>{};

  // A mapping from an entity to a list of entities that are
  // inlined inside of it.
  final Map<Entity, List<Entity>> inlineMap = <Entity, List<Entity>>{};

  final Map<MemberEntity, WorldImpact> impacts = <MemberEntity, WorldImpact>{};

  /// Register the size of the generated output.
  void reportSize(int programSize) {
    _programSize = programSize;
  }

  void reportInlined(Element element, Element inlinedFrom) {
    element = element.declaration;
    inlinedFrom = inlinedFrom.declaration;

    inlineCount.putIfAbsent(element, () => 0);
    inlineCount[element] += 1;
    inlineMap.putIfAbsent(inlinedFrom, () => new List<Element>());
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
  Iterable<Selection> getRetaining(Entity entity, ClosedWorld closedWorld) {
    WorldImpact impact = impacts[entity];
    if (impact == null) return const <Selection>[];

    var selections = <Selection>[];
    compiler.impactStrategy.visitImpact(
        entity,
        impact,
        new WorldImpactVisitorImpl(visitDynamicUse: (dynamicUse) {
          selections.addAll(closedWorld
              .locateMembers(dynamicUse.selector, dynamicUse.mask)
              .map((MemberEntity e) => new Selection(e, dynamicUse.mask)));
        }, visitStaticUse: (staticUse) {
          selections.add(new Selection(staticUse.element, null));
        }),
        IMPACT_USE);
    return selections;
  }

  // Returns true if we care about tracking the size of
  // this node.
  bool isTracking(jsAst.Node code) {
    if (compiler.options.dumpInfo) {
      return _tracking.contains(code);
    } else {
      return false;
    }
  }

  /// Registers that a javascript AST node [code] was produced by the dart
  /// Entity [entity].
  void registerEntityAst(Entity entity, jsAst.Node code) {
    if (compiler.options.dumpInfo) {
      _entityToNodes
          .putIfAbsent(entity, () => new List<jsAst.Node>())
          .add(code);
      _tracking.add(code);
    }
  }

  void registerConstantAst(ConstantValue constant, jsAst.Node code) {
    if (compiler.options.dumpInfo) {
      assert(_constantToNode[constant] == null ||
          _constantToNode[constant] == code);
      _constantToNode[constant] = code;
      _tracking.add(code);
    }
  }

  /// Records the size of a dart AST node after it has been pretty-printed into
  /// the output buffer.
  void recordAstSize(jsAst.Node node, int size) {
    if (isTracking(node)) {
      //TODO: should I be incrementing here instead?
      _nodeToSize[node] = size;
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
    // TODO(sigmund): switch back to null aware operators (issue #24136)
    var size = _nodeToSize[node];
    return size == null ? 0 : size;
  }

  String codeOf(Entity entity) {
    List<jsAst.Node> code = _entityToNodes[entity];
    if (code == null) return null;
    // Concatenate rendered ASTs.
    StringBuffer sb = new StringBuffer();
    for (jsAst.Node ast in code) {
      sb.writeln(jsAst.prettyPrint(ast, compiler.options));
    }
    return sb.toString();
  }

  void dumpInfo(ClosedWorld closedWorld) {
    measure(() {
      infoCollector = new ElementInfoCollector(compiler, closedWorld)..run();
      StringBuffer jsonBuffer = new StringBuffer();
      dumpInfoJson(jsonBuffer, closedWorld);
      compiler.outputProvider.createOutputSink(
          compiler.options.outputUri.pathSegments.last,
          'info.json',
          OutputType.info)
        ..add(jsonBuffer.toString())
        ..close();
    });
  }

  void dumpInfoJson(StringSink buffer, ClosedWorld closedWorld) {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
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
        info.uses.add(new DependencyInfo(useInfo, '${selection.mask}'));
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
        info.uses.add(new DependencyInfo(useInfo, '${selection.mask}'));
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

    result.deferredFiles = compiler.deferredLoadTask.computeDeferredMap();
    stopwatch.stop();
    result.program = new ProgramInfo(
        entrypoint: infoCollector
            ._entityToInfo[closedWorld.elementEnvironment.mainFunction],
        size: _programSize,
        dart2jsVersion:
            compiler.options.hasBuildId ? compiler.options.buildId : null,
        compilationMoment: new DateTime.now(),
        compilationDuration: compiler.measurer.wallClock.elapsed,
        toJsonDuration:
            new Duration(milliseconds: stopwatch.elapsedMilliseconds),
        dumpInfoDuration: new Duration(milliseconds: this.timing),
        noSuchMethodEnabled: closedWorld.backendUsage.isNoSuchMethodUsed,
        minified: compiler.options.enableMinification);

    ChunkedConversionSink<Object> sink = encoder.startChunkedConversion(
        new StringConversionSink.fromStringSink(buffer));
    sink.add(new AllInfoJsonCodec().encode(result));
    compiler.reporter.reportInfo(NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {
      'text': "View the dumped .info.json file at "
          "https://dart-lang.github.io/dump-info-visualizer"
    });
  }
}
