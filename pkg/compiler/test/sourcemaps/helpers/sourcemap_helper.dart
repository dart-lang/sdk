// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.helper;

import 'dart:async';
import 'dart:io';
import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/io/code_output.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/io/position_information.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js/js_debug.dart';
import 'package:compiler/src/js/js_source_mapping.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/util/memory_compiler.dart';

class SourceFileSink implements api.OutputSink {
  final String filename;
  StringBuffer sb = StringBuffer();
  late final SourceFile sourceFile;

  SourceFileSink(this.filename);

  @override
  void add(String event) {
    sb.write(event);
  }

  @override
  void close() {
    sourceFile = StringSourceFile.fromName(filename, sb.toString());
  }
}

class OutputProvider implements api.CompilerOutput {
  Map<Uri, SourceFileSink> outputMap = <Uri, SourceFileSink>{};

  SourceFile? getSourceFile(Uri uri) {
    SourceFileSink? sink = outputMap[uri];
    return sink?.sourceFile;
  }

  SourceFileSink createSourceFileSink(
      String name, String extension, api.OutputType type) {
    String filename = '$name.$extension';
    SourceFileSink sink = SourceFileSink(filename);
    Uri uri = Uri.parse(filename);
    outputMap[uri] = sink;
    return sink;
  }

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    return createSourceFileSink(name, extension, type);
  }

  @override
  api.BinaryOutputSink createBinarySink(Uri uri) =>
      throw UnsupportedError("OutputProvider.createBinarySink");
}

class CloningOutputProvider extends OutputProvider {
  RandomAccessFileOutputProvider outputProvider;

  CloningOutputProvider(Uri jsUri, Uri jsMapUri)
      : outputProvider = RandomAccessFileOutputProvider(jsUri, jsMapUri);

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    api.OutputSink output =
        outputProvider.createOutputSink(name, extension, type);
    return CloningOutputSink(
        [output, createSourceFileSink(name, extension, type)]);
  }

  @override
  api.BinaryOutputSink createBinarySink(Uri uri) =>
      throw UnsupportedError("CloningOutputProvider.createBinarySink");
}

abstract class SourceFileManager {
  SourceFile? getSourceFile(Object? uri);
}

class ProviderSourceFileManager implements SourceFileManager {
  final SourceFileProvider sourceFileProvider;
  final OutputProvider outputProvider;

  ProviderSourceFileManager(this.sourceFileProvider, this.outputProvider);

  @override
  SourceFile? getSourceFile(covariant Uri? uri) {
    if (uri == null) return null;
    return (sourceFileProvider.readUtf8FromFileSyncForTesting(uri) ??
        outputProvider.getSourceFile(uri)) as SourceFile?;
  }
}

class RecordingPrintingContext extends LenientPrintingContext {
  CodePositionListener listener;
  Map<js.Node, CodePosition> codePositions = <js.Node, CodePosition>{};

  RecordingPrintingContext(this.listener);

  @override
  void exitNode(
      js.Node node, int startPosition, int endPosition, int? closingPosition) {
    codePositions[node] =
        CodePosition(startPosition, endPosition, closingPosition);
    listener.onPositions(node, startPosition, endPosition, closingPosition);
  }
}

/// A [SourceMapper] that records the source locations on each node.
class RecordingSourceMapperProvider implements SourceMapperProvider {
  final SourceMapperProvider sourceMapperProvider;
  final _LocationRecorder nodeToSourceLocationsMap;

  RecordingSourceMapperProvider(
      this.sourceMapperProvider, this.nodeToSourceLocationsMap);

  @override
  SourceMapper createSourceMapper(String name) {
    return RecordingSourceMapper(sourceMapperProvider.createSourceMapper(name),
        nodeToSourceLocationsMap);
  }
}

/// A [SourceMapper] that records the source locations on each node.
class RecordingSourceMapper implements SourceMapper {
  final SourceMapper sourceMapper;
  final _LocationRecorder nodeToSourceLocationsMap;

  RecordingSourceMapper(this.sourceMapper, this.nodeToSourceLocationsMap);

  @override
  void register(js.Node node, int codeOffset, SourceLocation sourceLocation) {
    nodeToSourceLocationsMap.register(node, codeOffset, sourceLocation);
    sourceMapper.register(node, codeOffset, sourceLocation);
  }

  @override
  void registerPush(int codeOffset, SourceLocation? sourceLocation,
      String inlinedMethodName) {
    sourceMapper.registerPush(codeOffset, sourceLocation, inlinedMethodName);
  }

  @override
  void registerPop(int codeOffset, {bool isEmpty = false}) {
    sourceMapper.registerPop(codeOffset, isEmpty: isEmpty);
  }
}

/// A wrapper of [SourceInformationProcessor] that records source locations and
/// code positions.
class RecordingSourceInformationProcessor extends SourceInformationProcessor {
  final RecordingSourceInformationStrategy wrapper;
  final SourceInformationProcessor processor;
  final CodePositionRecorder codePositions;
  final LocationMap nodeToSourceLocationsMap;

  RecordingSourceInformationProcessor(this.wrapper, this.processor,
      this.codePositions, this.nodeToSourceLocationsMap);

  @override
  void onPositions(
      js.Node node, int startPosition, int endPosition, int? closingPosition) {
    codePositions.registerPositions(
        node, startPosition, endPosition, closingPosition);
    processor.onPositions(node, startPosition, endPosition, closingPosition);
  }

  @override
  void process(js.Node node, BufferedCodeOutput code) {
    processor.process(node, code);
    wrapper.registerProcess(
        node, code, codePositions, nodeToSourceLocationsMap);
  }
}

/// Information recording for a use of [SourceInformationProcessor].
class RecordedSourceInformationProcess {
  final js.Node root;
  final String code;
  final CodePositionRecorder codePositions;
  final LocationMap nodeToSourceLocationsMap;

  RecordedSourceInformationProcess(
      this.root, this.code, this.codePositions, this.nodeToSourceLocationsMap);
}

/// A wrapper of [JavaScriptSourceInformationStrategy] that records
/// [RecordedSourceInformationProcess].
class RecordingSourceInformationStrategy
    extends JavaScriptSourceInformationStrategy {
  final JavaScriptSourceInformationStrategy strategy;
  final Map<RecordedSourceInformationProcess, js.Node> processMap =
      <RecordedSourceInformationProcess, js.Node>{};
  final Map<js.Node, RecordedSourceInformationProcess?> nodeMap = {};

  RecordingSourceInformationStrategy(this.strategy);

  @override
  void onElementMapAvailable(JsToElementMap elementMap) {
    strategy.onElementMapAvailable(elementMap);
  }

  @override
  SourceInformationBuilder createBuilderForContext(MemberEntity member) {
    return strategy.createBuilderForContext(member);
  }

  @override
  SourceInformationProcessor createProcessor(
      SourceMapperProvider provider, SourceInformationReader reader) {
    final nodeToSourceLocationsMap = _LocationRecorder();
    final codePositions = CodePositionRecorder();
    return RecordingSourceInformationProcessor(
        this,
        strategy.createProcessor(
            RecordingSourceMapperProvider(provider, nodeToSourceLocationsMap),
            reader),
        codePositions,
        nodeToSourceLocationsMap);
  }

  void registerProcess(
      js.Node root,
      BufferedCodeOutput code,
      CodePositionRecorder codePositions,
      LocationMap nodeToSourceLocationsMap) {
    RecordedSourceInformationProcess subProcess =
        RecordedSourceInformationProcess(
            root, code.getText(), codePositions, nodeToSourceLocationsMap);
    processMap[subProcess] = root;
  }

  RecordedSourceInformationProcess? subProcessForNode(js.Node node) {
    return nodeMap.putIfAbsent(node, () {
      for (RecordedSourceInformationProcess subProcess in processMap.keys) {
        js.Node root = processMap[subProcess]!;
        FindVisitor visitor = FindVisitor(node);
        root.accept(visitor);
        if (visitor.found) {
          return RecordedSourceInformationProcess(
              node,
              subProcess.code,
              subProcess.codePositions,
              _FilteredLocationMap(
                  visitor.nodes, subProcess.nodeToSourceLocationsMap));
        }
        return null;
      }
      return null;
    });
  }
}

/// Visitor that collects all nodes that are within a function. Used by the
/// [RecordingSourceInformationStrategy] to filter what is recorded in a
/// [RecordedSourceInformationProcess].
class FindVisitor extends js.BaseVisitorVoid {
  final js.Node soughtNode;
  bool found = false;
  bool add = false;
  final Set<js.Node> nodes = Set<js.Node>();

  FindVisitor(this.soughtNode);

  @override
  void visitNode(js.Node node) {
    if (node == soughtNode) {
      found = true;
      add = true;
    }
    if (add) {
      nodes.add(node);
    }
    node.visitChildren(this);
    if (node == soughtNode) {
      add = false;
    }
  }
}

/// Processor that computes [SourceMapInfo] for the JavaScript compiled for a
/// given Dart file.
class SourceMapProcessor {
  /// If `true` the output from the compilation is written to files.
  final bool outputToFile;

  /// The [Uri] of the Dart entrypoint.
  Uri inputUri;

  /// The name of the JavaScript output file.
  String jsPath;

  /// The [Uri] of the JavaScript output file.
  Uri targetUri;

  /// The [Uri] of the JavaScript source map file.
  Uri sourceMapFileUri;

  /// The [SourceFileManager] created for the processing.
  late final SourceFileManager sourceFileManager;

  /// Creates a processor for the Dart file [uri].
  SourceMapProcessor(Uri uri, {this.outputToFile = false})
      : inputUri = Uri.base.resolveUri(uri),
        jsPath = 'out.js',
        targetUri = Uri.base.resolve('out.js'),
        sourceMapFileUri = Uri.base.resolve('out.js.map');

  /// Computes the [SourceMapInfo] for the compiled elements.
  Future<SourceMaps> process(List<String> options,
      {bool verbose = true,
      bool perElement = true,
      bool forMain = false}) async {
    OutputProvider outputProvider = outputToFile
        ? CloningOutputProvider(targetUri, sourceMapFileUri)
        : OutputProvider();
    if (options.contains(Flags.useNewSourceInfo)) {
      if (verbose) print('Using the source information system.');
    }
    if (options.contains(Flags.disableInlining)) {
      if (verbose) print('Inlining disabled');
    }
    CompilationResult result = await runCompiler(
        entryPoint: inputUri,
        outputProvider: outputProvider,
        // TODO(johnniwinther): Use [verbose] to avoid showing diagnostics.
        options: ['--out=$targetUri', '--source-map=$sourceMapFileUri']
          ..addAll(options),
        beforeRun: (compiler) {
          JsBackendStrategy backendStrategy = compiler.backendStrategy;
          dynamic handler = compiler.handler;
          SourceFileProvider sourceFileProvider = handler.provider;
          sourceFileManager =
              ProviderSourceFileManager(sourceFileProvider, outputProvider);
          RecordingSourceInformationStrategy strategy =
              RecordingSourceInformationStrategy(
                  backendStrategy.sourceInformationStrategy
                      as JavaScriptSourceInformationStrategy);
          backendStrategy.sourceInformationStrategy = strategy;
        });
    if (!result.isSuccess) {
      throw "Compilation failed.";
    }

    var compiler = result.compiler;
    JsBackendStrategy backendStrategy = compiler.backendStrategy;
    final strategy = backendStrategy.sourceInformationStrategy
        as RecordingSourceInformationStrategy;
    SourceMapInfo? mainSourceMapInfo;
    Map<MemberEntity, SourceMapInfo> elementSourceMapInfos =
        <MemberEntity, SourceMapInfo>{};
    if (perElement) {
      backendStrategy.generatedCode.forEach((_element, js.Expression node) {
        MemberEntity element = _element;
        RecordedSourceInformationProcess? subProcess =
            strategy.subProcessForNode(node);
        if (subProcess == null) {
          // TODO(johnniwinther): Find out when this is happening and if it
          // is benign. (Known to happen for `bool#fromString`)
          print('No subProcess found for $element');
          return;
        }
        LocationMap nodeMap = subProcess.nodeToSourceLocationsMap;
        String code = subProcess.code;
        CodePositionRecorder codePositions = subProcess.codePositions;
        CodePointComputer visitor =
            CodePointComputer(sourceFileManager, code, nodeMap);
        JavaScriptTracer(
                codePositions, const SourceInformationReader(), [visitor])
            .apply(node);
        List<CodePoint> codePoints = visitor.codePoints;
        elementSourceMapInfos[element] = SourceMapInfo(
            element, code, node, codePoints, codePositions, nodeMap);
      });
    }
    if (forMain) {
      // TODO(johnniwinther): Supported multiple output units.
      RecordedSourceInformationProcess process = strategy.processMap.keys.first;
      js.Node node = strategy.processMap[process]!;
      String code;
      LocationMap nodeMap;
      CodePositionRecorder codePositions;
      nodeMap = process.nodeToSourceLocationsMap;
      code = process.code;
      codePositions = process.codePositions;
      CodePointComputer visitor =
          CodePointComputer(sourceFileManager, code, nodeMap);
      JavaScriptTracer(
              codePositions, const SourceInformationReader(), [visitor])
          .apply(node);
      List<CodePoint> codePoints = visitor.codePoints;
      mainSourceMapInfo =
          SourceMapInfo(null, code, node, codePoints, codePositions, nodeMap);
    }

    return SourceMaps(
        compiler, sourceFileManager, mainSourceMapInfo, elementSourceMapInfos);
  }
}

class SourceMaps {
  final Compiler compiler;
  final SourceFileManager sourceFileManager;
  // TODO(johnniwinther): Supported multiple output units.
  final SourceMapInfo? mainSourceMapInfo;
  final Map<MemberEntity, SourceMapInfo> elementSourceMapInfos;

  SourceMaps(this.compiler, this.sourceFileManager, this.mainSourceMapInfo,
      this.elementSourceMapInfos);
}

/// Source mapping information for the JavaScript code of an [Element].
class SourceMapInfo {
  final String? name;
  final MemberEntity? element;
  final String code;
  final js.Node node;
  final List<CodePoint> codePoints;
  final CodePositionMap jsCodePositions;
  final LocationMap nodeMap;

  SourceMapInfo(this.element, this.code, this.node, this.codePoints,
      this.jsCodePositions, this.nodeMap)
      : this.name =
            element != null ? computeElementNameForSourceMaps(element) : '';

  @override
  String toString() {
    return '$name:$element';
  }
}

/// Collection of JavaScript nodes with their source mapped target offsets
/// and source locations.
abstract class LocationMap {
  Iterable<js.Node> get nodes;

  Map<int, List<SourceLocation>>? operator [](js.Node node);

  factory LocationMap.recorder() = _LocationRecorder;

  factory LocationMap.filter(Set<js.Node> nodes, LocationMap map) =
      _FilteredLocationMap;
}

class _LocationRecorder implements SourceMapper, LocationMap {
  final Map<js.Node, Map<int, List<SourceLocation>>> _nodeMap = {};

  @override
  void register(js.Node node, int codeOffset, SourceLocation sourceLocation) {
    _nodeMap
        .putIfAbsent(node, () => {})
        .putIfAbsent(codeOffset, () => [])
        .add(sourceLocation);
  }

  @override
  void registerPush(int codeOffset, SourceLocation? sourceLocation,
      String inlinedMethodName) {}

  @override
  void registerPop(int codeOffset, {bool isEmpty = false}) {}

  @override
  Iterable<js.Node> get nodes => _nodeMap.keys;

  @override
  Map<int, List<SourceLocation>>? operator [](js.Node node) {
    return _nodeMap[node];
  }
}

class _FilteredLocationMap implements LocationMap {
  final Set<js.Node> _nodes;
  final LocationMap map;

  _FilteredLocationMap(this._nodes, this.map);

  @override
  Iterable<js.Node> get nodes => map.nodes.where((n) => _nodes.contains(n));

  @override
  Map<int, List<SourceLocation>>? operator [](js.Node node) {
    return map[node];
  }
}

/// Visitor that computes the [CodePoint]s for source mapping locations.
class CodePointComputer extends TraceListener {
  final SourceFileManager sourceFileManager;
  final String code;
  final LocationMap nodeMap;
  List<CodePoint> codePoints = [];

  CodePointComputer(this.sourceFileManager, this.code, this.nodeMap);

  String nodeToString(js.Node node) {
    js.JavaScriptPrintingOptions options = js.JavaScriptPrintingOptions(
        shouldCompressOutput: true,
        preferSemicolonToNewlineInMinifiedOutput: true);
    LenientPrintingContext printingContext = LenientPrintingContext();
    js.Printer(options, printingContext).visit(node);
    return printingContext.buffer.toString();
  }

  String positionToString(int position) {
    String line = code.substring(position);
    int nl = line.indexOf('\n');
    if (nl != -1) {
      line = line.substring(0, nl);
    }
    return line;
  }

  /// Called when [node] defines a step of the given [kind] at the given
  /// [offset] when the generated JavaScript code.
  @override
  void onStep(js.Node node, Offset offset, StepKind kind) {
    if (kind == StepKind.ACCESS) return;
    register(kind, node);
  }

  void register(StepKind kind, js.Node node, {bool expectInfo = true}) {
    String dartCodeFromSourceLocation(SourceLocation sourceLocation) {
      SourceFile? sourceFile =
          sourceFileManager.getSourceFile(sourceLocation.sourceUri);
      if (sourceFile == null) {
        return sourceLocation.shortText;
      }
      return sourceFile.kernelSource
          .getTextLine(sourceLocation.line)!
          .substring(sourceLocation.column - 1)
          .trim();
    }

    void addLocation(
        SourceLocation? sourceLocation, String jsCode, int? targetOffset) {
      if (sourceLocation == null) {
        if (expectInfo) {
          final sourceInformation =
              node.sourceInformation as SourceInformation?;
          SourceLocation? sourceLocation;
          String? dartCode;
          if (sourceInformation != null) {
            sourceLocation = sourceInformation.sourceLocations.first;
            dartCode = dartCodeFromSourceLocation(sourceLocation);
          }
          codePoints.add(new CodePoint(
              kind, jsCode, targetOffset, sourceLocation, dartCode,
              isMissing: true));
        }
      } else {
        codePoints.add(new CodePoint(kind, jsCode, targetOffset, sourceLocation,
            dartCodeFromSourceLocation(sourceLocation)));
      }
    }

    Map<int, List<SourceLocation>>? locationMap = nodeMap[node];
    if (locationMap == null) {
      addLocation(null, nodeToString(node), null);
    } else {
      locationMap.forEach((int targetOffset, List<SourceLocation> locations) {
        String jsCode = nodeToString(node);
        for (SourceLocation location in locations) {
          addLocation(location, jsCode, targetOffset);
        }
      });
    }
  }
}

/// A JavaScript code point and its mapped dart source location.
class CodePoint {
  final StepKind kind;
  final String jsCode;
  final int? targetOffset;
  final SourceLocation? sourceLocation;
  final String? dartCode;
  final bool isMissing;

  CodePoint(this.kind, this.jsCode, this.targetOffset, this.sourceLocation,
      this.dartCode,
      {this.isMissing = false});

  @override
  String toString() {
    return 'CodePoint[kind=$kind,js=$jsCode,dart=$dartCode,'
        'location=$sourceLocation]';
  }
}

class IOSourceFileManager implements SourceFileManager {
  final Uri base;

  Map<Uri, SourceFile> sourceFiles = <Uri, SourceFile>{};

  IOSourceFileManager(this.base);

  @override
  SourceFile getSourceFile(Object? uri) {
    Uri absoluteUri;
    if (uri is Uri) {
      absoluteUri = base.resolveUri(uri);
    } else {
      absoluteUri = base.resolve(uri as String);
    }
    return sourceFiles.putIfAbsent(absoluteUri, () {
      String text = File.fromUri(absoluteUri).readAsStringSync();
      return StringSourceFile.fromUri(absoluteUri, text);
    });
  }
}
