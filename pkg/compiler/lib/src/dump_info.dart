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
import 'compiler.dart' show Compiler;
import 'constants/values.dart' show ConstantValue, InterceptorConstantValue;
import 'deferred_load.dart' show OutputUnit;
import 'elements/elements.dart';
import 'elements/entities.dart';
import 'elements/visitor.dart';
import 'js/js.dart' as jsAst;
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'types/types.dart' show TypeMask;
import 'universe/world_builder.dart' show ReceiverConstraint;
import 'universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitorImpl;
import 'world.dart' show ClosedWorld;

class ElementInfoCollector extends BaseElementVisitor<Info, dynamic> {
  final Compiler compiler;
  final ClosedWorld closedWorld;

  final AllInfo result = new AllInfo();
  final Map<Entity, Info> _elementToInfo = <Entity, Info>{};
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
    (compiler.libraryLoader.libraries as Iterable<LibraryElement>)
        .forEach(visit);
  }

  Info visit(Element e, [_]) => e.accept(this, null);

  /// Whether to emit information about [element].
  ///
  /// By default we emit information for any element that contributes to the
  /// output size. Either because the it is a function being emitted or inlined,
  /// or because it is an element that holds dependencies to other elements.
  bool shouldKeep(Element element) {
    return compiler.dumpInfoTask.impacts.containsKey(element) ||
        compiler.dumpInfoTask.inlineCount.containsKey(element);
  }

  /// Visits [element] and produces it's corresponding info.
  Info process(Entity element) {
    // TODO(sigmund): change the visit order to eliminate the need to check
    // whether or not an element has been processed.
    return _elementToInfo.putIfAbsent(element, () => visit(element));
  }

  Info visitElement(Element element, _) => null;

  FunctionInfo visitConstructorBodyElement(ConstructorBodyElement e, _) {
    return visitFunctionElement(e.constructor, _);
  }

  LibraryInfo visitLibraryElement(LibraryElement element, _) {
    String libname = element.hasLibraryName ? element.libraryName : "<unnamed>";
    int size = compiler.dumpInfoTask.sizeOf(element);
    LibraryInfo info =
        new LibraryInfo(libname, element.canonicalUri, null, size);
    _elementToInfo[element] = info;

    LibraryElement realElement = element.isPatched ? element.patch : element;
    realElement.forEachLocalMember((Element member) {
      Info child = this.process(member);
      if (child is ClassInfo) {
        info.classes.add(child);
        child.parent = info;
      } else if (child is FunctionInfo) {
        info.topLevelFunctions.add(child);
        child.parent = info;
      } else if (child is FieldInfo) {
        info.topLevelVariables.add(child);
        child.parent = info;
      } else if (child is TypedefInfo) {
        info.typedefs.add(child);
        child.parent = info;
      } else if (child != null) {
        print('unexpected child of $info: $child ==> ${child.runtimeType}');
        assert(false);
      }
    });

    if (info.isEmpty && !shouldKeep(element)) return null;
    result.libraries.add(info);
    return info;
  }

  TypedefInfo visitTypedefElement(TypedefElement element, _) {
    if (!element.isResolved) return null;
    TypedefInfo info = new TypedefInfo(
        element.name, '${element.alias}', _unitInfoForElement(element));
    _elementToInfo[element] = info;
    result.typedefs.add(info);
    return info;
  }

  _resultOfMember(MemberElement e) =>
      compiler.globalInference.results.resultOfMember(e);

  _resultOfParameter(ParameterElement e) =>
      compiler.globalInference.results.resultOfParameter(e);

  @deprecated
  _resultOfElement(AstElement e) =>
      compiler.globalInference.results.resultOfElement(e);

  FieldInfo visitFieldElement(FieldElement element, _) {
    TypeMask inferredType = _resultOfMember(element).type;
    // If a field has an empty inferred type it is never used.
    if (inferredType == null || inferredType.isEmpty) return null;

    int size = compiler.dumpInfoTask.sizeOf(element);
    String code = compiler.dumpInfoTask.codeOf(element);
    if (code != null) size += code.length;

    FieldInfo info = new FieldInfo(
        name: element.name,
        type: '${element.type}',
        inferredType: '$inferredType',
        code: code,
        outputUnit: _unitInfoForElement(element),
        isConst: element.isConst);
    _elementToInfo[element] = info;
    if (element.isConst) {
      var value = compiler.backend.constantCompilerTask
          .getConstantValue(element.constant);
      if (value != null) {
        info.initializer = _constantToInfo[value];
      }
    }

    if (JavaScriptBackend.TRACE_METHOD == 'post') {
      // We use element.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${element.hashCode}';
    }

    int closureSize = _addClosureInfo(info, element);
    info.size = size + closureSize;

    result.fields.add(info);
    return info;
  }

  ClassInfo visitClassElement(ClassElement element, _) {
    ClassInfo classInfo = new ClassInfo(
        name: element.name,
        isAbstract: element.isAbstract,
        outputUnit: _unitInfoForElement(element));
    _elementToInfo[element] = classInfo;

    int size = compiler.dumpInfoTask.sizeOf(element);
    element.forEachLocalMember((Element member) {
      Info info = this.process(member);
      if (info == null) return;
      if (info is FieldInfo) {
        classInfo.fields.add(info);
        info.parent = classInfo;
        for (ClosureInfo closureInfo in info.closures) {
          size += closureInfo.size;
        }
      } else {
        assert(info is FunctionInfo);
        classInfo.functions.add(info);
        info.parent = classInfo;
        for (ClosureInfo closureInfo in (info as FunctionInfo).closures) {
          size += closureInfo.size;
        }
      }
    });

    classInfo.size = size;

    // Omit element if it is not needed.
    JavaScriptBackend backend = compiler.backend;
    if (!backend.emitter.neededClasses.contains(element) &&
        classInfo.fields.isEmpty &&
        classInfo.functions.isEmpty) {
      return null;
    }
    result.classes.add(classInfo);
    return classInfo;
  }

  ClosureInfo visitClosureClassElement(ClosureClassElement element, _) {
    ClosureInfo closureInfo = new ClosureInfo(
        name: element.name,
        outputUnit: _unitInfoForElement(element),
        size: compiler.dumpInfoTask.sizeOf(element));
    _elementToInfo[element] = closureInfo;

    ClosureRepresentationInfo closureRepresentation = compiler.closureDataLookup
        .getClosureRepresentationInfo(element.methodElement);
    assert(closureRepresentation.closureClassEntity == element);

    FunctionInfo functionInfo = this.process(closureRepresentation.callMethod);
    if (functionInfo == null) return null;
    closureInfo.function = functionInfo;
    functionInfo.parent = closureInfo;

    result.closures.add(closureInfo);
    return closureInfo;
  }

  FunctionInfo visitFunctionElement(FunctionElement element, _) {
    int size = compiler.dumpInfoTask.sizeOf(element);
    // TODO(sigmund): consider adding a small info to represent unreachable
    // code here.
    if (size == 0 && !shouldKeep(element)) return null;

    String name = element.name;
    int kind = FunctionInfo.TOP_LEVEL_FUNCTION_KIND;
    var enclosingElement = element.enclosingElement;
    if (enclosingElement.isField ||
        enclosingElement.isFunction ||
        element.isClosure ||
        enclosingElement.isConstructor) {
      kind = FunctionInfo.CLOSURE_FUNCTION_KIND;
      name = "<unnamed>";
    } else if (element.isStatic) {
      kind = FunctionInfo.TOP_LEVEL_FUNCTION_KIND;
    } else if (enclosingElement.isClass) {
      kind = FunctionInfo.METHOD_FUNCTION_KIND;
    }

    if (element.isConstructor) {
      name = name == ""
          ? "${element.enclosingElement.name}"
          : "${element.enclosingElement.name}.${element.name}";
      kind = FunctionInfo.CONSTRUCTOR_FUNCTION_KIND;
    }

    FunctionModifiers modifiers = new FunctionModifiers(
        isStatic: element.isStatic,
        isConst: element.isConst,
        isFactory: element.isFactoryConstructor,
        isExternal: element.isPatched);
    String code = compiler.dumpInfoTask.codeOf(element);

    String returnType = null;
    List<ParameterInfo> parameters = <ParameterInfo>[];
    if (element.hasFunctionSignature) {
      FunctionSignature signature = element.functionSignature;
      signature.forEachParameter((parameter) {
        parameters.add(new ParameterInfo(parameter.name,
            '${_resultOfParameter(parameter).type}', '${parameter.node.type}'));
      });
      returnType = '${element.type.returnType}';
    }

    String inferredReturnType = '${_resultOfElement(element).returnType}';
    String sideEffects = '${closedWorld.getSideEffectsOfElement(element)}';

    int inlinedCount = compiler.dumpInfoTask.inlineCount[element];
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
        type: element.type.toString(),
        outputUnit: _unitInfoForElement(element));
    _elementToInfo[element] = info;

    if (element is MemberElement) {
      int closureSize = _addClosureInfo(info, element as MemberElement);
      size += closureSize;
    } else {
      info.closures = <ClosureInfo>[];
    }

    if (JavaScriptBackend.TRACE_METHOD == 'post') {
      // We use element.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${element.hashCode}';
    }

    info.size = size;

    result.functions.add(info);
    return info;
  }

  /// Adds closure information to [info], using all nested closures in [member].
  ///
  /// Returns the total size of the nested closures, to add to the info size.
  int _addClosureInfo(Info info, MemberElement member) {
    assert(info is FunctionInfo || info is FieldInfo);
    int size = 0;
    List<ClosureInfo> nestedClosures = <ClosureInfo>[];
    for (Element function in member.nestedClosures) {
      assert(function is SynthesizedCallMethodElementX);
      SynthesizedCallMethodElementX callMethod = function;
      ClosureInfo closure = this.process(callMethod.closureClass);
      if (closure != null) {
        closure.parent = info;
        nestedClosures.add(closure);
        size += closure.size;
      }
    }
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
      info.imports.addAll(outputUnit.imports
          .map((d) => compiler.deferredLoadTask.importDeferName[d]));
      result.outputUnits.add(info);
      return info;
    });
  }

  OutputUnitInfo _unitInfoForElement(Element element) {
    return _infoFromOutputUnit(
        compiler.deferredLoadTask.outputUnitForElement(element));
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
}

class Selection {
  final Entity selectedElement;
  final ReceiverConstraint mask;
  Selection(this.selectedElement, this.mask);
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
  // This set is automatically populated when registerElementAst()
  // is called.
  final Set<jsAst.Node> _tracking = new Set<jsAst.Node>();
  // A mapping from Dart Elements to Javascript AST Nodes.
  final Map<Entity, List<jsAst.Node>> _elementToNodes =
      <Entity, List<jsAst.Node>>{};
  final Map<ConstantValue, jsAst.Node> _constantToNode =
      <ConstantValue, jsAst.Node>{};
  // A mapping from Javascript AST Nodes to the size of their
  // pretty-printed contents.
  final Map<jsAst.Node, int> _nodeToSize = <jsAst.Node, int>{};

  final Map<Element, int> inlineCount = <Element, int>{};
  // A mapping from an element to a list of elements that are
  // inlined inside of it.
  final Map<Element, List<Element>> inlineMap = <Element, List<Element>>{};

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

  void registerImpact(MemberEntity element, WorldImpact impact) {
    if (compiler.options.dumpInfo) {
      impacts[element] = impact;
    }
  }

  void unregisterImpact(var impactSource) {
    impacts.remove(impactSource);
  }

  /**
   * Returns an iterable of [Selection]s that are used by
   * [element].  Each [Selection] contains an element that is
   * used and the selector that selected the element.
   */
  Iterable<Selection> getRetaining(Element element, ClosedWorld closedWorld) {
    WorldImpact impact = impacts[element];
    if (impact == null) return const <Selection>[];

    var selections = <Selection>[];
    compiler.impactStrategy.visitImpact(
        element,
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

  // Registers that a javascript AST node `code` was produced by the
  // dart Element `element`.
  void registerElementAst(Entity element, jsAst.Node code) {
    if (compiler.options.dumpInfo) {
      _elementToNodes
          .putIfAbsent(element, () => new List<jsAst.Node>())
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

  // Records the size of a dart AST node after it has been
  // pretty-printed into the output buffer.
  void recordAstSize(jsAst.Node node, int size) {
    if (isTracking(node)) {
      //TODO: should I be incrementing here instead?
      _nodeToSize[node] = size;
    }
  }

  // Returns the size of the source code that
  // was generated for an element.  If no source
  // code was produced, return 0.
  int sizeOf(Element element) {
    if (_elementToNodes.containsKey(element)) {
      return _elementToNodes[element].map(sizeOfNode).fold(0, (a, b) => a + b);
    } else {
      return 0;
    }
  }

  int sizeOfNode(jsAst.Node node) {
    // TODO(sigmund): switch back to null aware operators (issue #24136)
    var size = _nodeToSize[node];
    return size == null ? 0 : size;
  }

  String codeOf(Element element) {
    List<jsAst.Node> code = _elementToNodes[element];
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
      compiler.outputProvider(compiler.options.outputUri.pathSegments.last,
          'info.json', OutputType.info)
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
    Iterable<Entity> functionElements =
        infoCollector._elementToInfo.keys.where((k) => k is FunctionElement);
    for (FunctionElement element in functionElements) {
      FunctionInfo info = infoCollector._elementToInfo[element];
      Iterable<Selection> uses = getRetaining(element, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        // Don't register dart2js builtin functions that are not recorded.
        Info useInfo = infoCollector._elementToInfo[selection.selectedElement];
        if (useInfo == null) continue;
        info.uses.add(new DependencyInfo(useInfo, '${selection.mask}'));
      }
    }

    // Recursively build links to field uses
    Iterable<Entity> fieldElements =
        infoCollector._elementToInfo.keys.where((k) => k is FieldElement);
    for (FieldElement element in fieldElements) {
      FieldInfo info = infoCollector._elementToInfo[element];
      Iterable<Selection> uses = getRetaining(element, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        Info useInfo = infoCollector._elementToInfo[selection.selectedElement];
        if (useInfo == null) continue;
        info.uses.add(new DependencyInfo(useInfo, '${selection.mask}'));
      }
    }

    // Notify the impact strategy impacts are no longer needed for dump info.
    compiler.impactStrategy.onImpactUsed(IMPACT_USE);

    // Track dependencies that come from inlining.
    for (Element element in inlineMap.keys) {
      CodeInfo outerInfo = infoCollector._elementToInfo[element];
      if (outerInfo == null) continue;
      for (Element inlined in inlineMap[element]) {
        Info inlinedInfo = infoCollector._elementToInfo[inlined];
        if (inlinedInfo == null) continue;
        outerInfo.uses.add(new DependencyInfo(inlinedInfo, 'inlined'));
      }
    }

    result.deferredFiles = compiler.deferredLoadTask.computeDeferredMap();
    stopwatch.stop();
    result.program = new ProgramInfo(
        entrypoint: infoCollector
            ._elementToInfo[closedWorld.elementEnvironment.mainFunction],
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
