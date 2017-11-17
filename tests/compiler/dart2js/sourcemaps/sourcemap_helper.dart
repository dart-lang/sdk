// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.helper;

import 'dart:async';
import 'dart:io';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/apiimpl.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/io/code_output.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/io/position_information.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js/js_debug.dart';
import 'package:compiler/src/js/js_source_mapping.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/source_file_provider.dart';
import '../memory_compiler.dart';
import '../output_collector.dart';

class SourceFileSink implements OutputSink {
  final String filename;
  StringBuffer sb = new StringBuffer();
  SourceFile sourceFile;

  SourceFileSink(this.filename);

  @override
  void add(String event) {
    sb.write(event);
  }

  @override
  void close() {
    sourceFile = new StringSourceFile.fromName(filename, sb.toString());
  }
}

class OutputProvider implements CompilerOutput {
  Map<Uri, SourceFileSink> outputMap = <Uri, SourceFileSink>{};

  SourceFile getSourceFile(Uri uri) {
    SourceFileSink sink = outputMap[uri];
    if (sink != null) {
      return sink.sourceFile;
    }
    return null;
  }

  SourceFileSink createSourceFileSink(
      String name, String extension, OutputType type) {
    String filename = '$name.$extension';
    SourceFileSink sink = new SourceFileSink(filename);
    Uri uri = Uri.parse(filename);
    outputMap[uri] = sink;
    return sink;
  }

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    return createSourceFileSink(name, extension, type);
  }
}

class CloningOutputProvider extends OutputProvider {
  RandomAccessFileOutputProvider outputProvider;

  CloningOutputProvider(Uri jsUri, Uri jsMapUri)
      : outputProvider = new RandomAccessFileOutputProvider(jsUri, jsMapUri);

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    OutputSink output = outputProvider.createOutputSink(name, extension, type);
    return new CloningOutputSink(
        [output, createSourceFileSink(name, extension, type)]);
  }
}

abstract class SourceFileManager {
  SourceFile getSourceFile(var uri);
}

class ProviderSourceFileManager implements SourceFileManager {
  final SourceFileProvider sourceFileProvider;
  final OutputProvider outputProvider;

  ProviderSourceFileManager(this.sourceFileProvider, this.outputProvider);

  @override
  SourceFile getSourceFile(uri) {
    SourceFile sourceFile = sourceFileProvider.getUtf8SourceFile(uri);
    sourceFile ??= sourceFileProvider.autoReadFromFile(uri);
    if (sourceFile == null) {
      sourceFile = outputProvider.getSourceFile(uri);
    }
    return sourceFile;
  }
}

class RecordingPrintingContext extends LenientPrintingContext {
  CodePositionListener listener;
  Map<js.Node, CodePosition> codePositions = <js.Node, CodePosition>{};

  RecordingPrintingContext(this.listener);

  @override
  void exitNode(
      js.Node node, int startPosition, int endPosition, int closingPosition) {
    codePositions[node] =
        new CodePosition(startPosition, endPosition, closingPosition);
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
    return new RecordingSourceMapper(
        sourceMapperProvider.createSourceMapper(name),
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
      js.Node node, int startPosition, int endPosition, int closingPosition) {
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
  final Map<js.Node, RecordedSourceInformationProcess> nodeMap =
      <js.Node, RecordedSourceInformationProcess>{};

  RecordingSourceInformationStrategy(this.strategy);

  @override
  SourceInformationBuilder createBuilderForContext(MemberEntity member) {
    return strategy.createBuilderForContext(member);
  }

  @override
  SourceInformationProcessor createProcessor(
      SourceMapperProvider provider, SourceInformationReader reader) {
    LocationMap nodeToSourceLocationsMap = new _LocationRecorder();
    CodePositionRecorder codePositions = new CodePositionRecorder();
    return new RecordingSourceInformationProcessor(
        this,
        strategy.createProcessor(
            new RecordingSourceMapperProvider(
                provider, nodeToSourceLocationsMap),
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
        new RecordedSourceInformationProcess(
            root, code.getText(), codePositions, nodeToSourceLocationsMap);
    processMap[subProcess] = root;
  }

  RecordedSourceInformationProcess subProcessForNode(js.Node node) {
    return nodeMap.putIfAbsent(node, () {
      for (RecordedSourceInformationProcess subProcess in processMap.keys) {
        js.Node root = processMap[subProcess];
        FindVisitor visitor = new FindVisitor(node);
        root.accept(visitor);
        if (visitor.found) {
          return new RecordedSourceInformationProcess(
              node,
              subProcess.code,
              subProcess.codePositions,
              new _FilteredLocationMap(
                  visitor.nodes, subProcess.nodeToSourceLocationsMap));
        }
        return null;
      }
    });
  }
}

/// Visitor that collects all nodes that are within a function. Used by the
/// [RecordingSourceInformationStrategy] to filter what is recorded in a
/// [RecordedSourceInformationProcess].
class FindVisitor extends js.BaseVisitor {
  final js.Node soughtNode;
  bool found = false;
  bool add = false;
  final Set<js.Node> nodes = new Set<js.Node>();

  FindVisitor(this.soughtNode);

  visitNode(js.Node node) {
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
  SourceFileManager sourceFileManager;

  /// Creates a processor for the Dart file [filename].
  SourceMapProcessor(String filename, {this.outputToFile: false}) {
    inputUri = Uri.base.resolve(nativeToUriPath(filename));
    jsPath = 'out.js';
    targetUri = Uri.base.resolve(jsPath);
    sourceMapFileUri = Uri.base.resolve('${jsPath}.map');
  }

  /// Computes the [SourceMapInfo] for the compiled elements.
  Future<SourceMaps> process(List<String> options,
      {bool verbose: true, bool perElement: true, bool forMain: false}) async {
    OutputProvider outputProvider = outputToFile
        ? new CloningOutputProvider(targetUri, sourceMapFileUri)
        : new OutputProvider();
    if (options.contains(Flags.useNewSourceInfo)) {
      if (verbose) print('Using the new source information system.');
    }
    if (options.contains(Flags.disableInlining)) {
      if (verbose) print('Inlining disabled');
    }
    api.CompilerImpl compiler = await compilerFor(
        outputProvider: outputProvider,
        // TODO(johnniwinther): Use [verbose] to avoid showing diagnostics.
        options: ['--out=$targetUri', '--source-map=$sourceMapFileUri']
          ..addAll(options));

    JavaScriptBackend backend = compiler.backend;
    dynamic handler = compiler.handler;
    SourceFileProvider sourceFileProvider = handler.provider;
    sourceFileManager =
        new ProviderSourceFileManager(sourceFileProvider, outputProvider);
    RecordingSourceInformationStrategy strategy =
        new RecordingSourceInformationStrategy(
            backend.sourceInformationStrategy);
    backend.sourceInformationStrategy = strategy;
    await compiler.run(inputUri);
    if (compiler.compilationFailed) {
      throw "Compilation failed.";
    }

    SourceMapInfo mainSourceMapInfo;
    Map<MemberEntity, SourceMapInfo> elementSourceMapInfos =
        <MemberEntity, SourceMapInfo>{};
    if (perElement) {
      backend.generatedCode.forEach((_element, js.Expression node) {
        MemberEntity element = _element;
        RecordedSourceInformationProcess subProcess =
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
            new CodePointComputer(sourceFileManager, code, nodeMap);
        new JavaScriptTracer(
                codePositions, const SourceInformationReader(), [visitor])
            .apply(node);
        List<CodePoint> codePoints = visitor.codePoints;
        elementSourceMapInfos[element] = new SourceMapInfo(
            element, code, node, codePoints, codePositions, nodeMap);
      });
    }
    if (forMain) {
      // TODO(johnniwinther): Supported multiple output units.
      RecordedSourceInformationProcess process = strategy.processMap.keys.first;
      js.Node node = strategy.processMap[process];
      String code;
      LocationMap nodeMap;
      CodePositionRecorder codePositions;
      nodeMap = process.nodeToSourceLocationsMap;
      code = process.code;
      codePositions = process.codePositions;
      CodePointComputer visitor =
          new CodePointComputer(sourceFileManager, code, nodeMap);
      new JavaScriptTracer(
              codePositions, const SourceInformationReader(), [visitor])
          .apply(node);
      List<CodePoint> codePoints = visitor.codePoints;
      mainSourceMapInfo = new SourceMapInfo(
          null, code, node, codePoints, codePositions, nodeMap);
    }

    return new SourceMaps(
        compiler, sourceFileManager, mainSourceMapInfo, elementSourceMapInfos);
  }
}

class SourceMaps {
  final api.CompilerImpl compiler;
  final SourceFileManager sourceFileManager;
  // TODO(johnniwinther): Supported multiple output units.
  final SourceMapInfo mainSourceMapInfo;
  final Map<MemberEntity, SourceMapInfo> elementSourceMapInfos;

  SourceMaps(this.compiler, this.sourceFileManager, this.mainSourceMapInfo,
      this.elementSourceMapInfos);
}

/// Source mapping information for the JavaScript code of an [Element].
class SourceMapInfo {
  final String name;
  final MemberEntity element;
  final String code;
  final js.Node node;
  final List<CodePoint> codePoints;
  final CodePositionMap jsCodePositions;
  final LocationMap nodeMap;

  SourceMapInfo(MemberEntity element, this.code, this.node, this.codePoints,
      this.jsCodePositions, this.nodeMap)
      : this.name =
            element != null ? computeElementNameForSourceMaps(element) : '',
        this.element = element;

  String toString() {
    return '$name:$element';
  }
}

/// Collection of JavaScript nodes with their source mapped target offsets
/// and source locations.
abstract class LocationMap {
  Iterable<js.Node> get nodes;

  Map<int, List<SourceLocation>> operator [](js.Node node);

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

  Iterable<js.Node> get nodes => _nodeMap.keys;

  Map<int, List<SourceLocation>> operator [](js.Node node) {
    return _nodeMap[node];
  }
}

class _FilteredLocationMap implements LocationMap {
  final Set<js.Node> _nodes;
  final LocationMap map;

  _FilteredLocationMap(this._nodes, this.map);

  Iterable<js.Node> get nodes => map.nodes.where((n) => _nodes.contains(n));

  Map<int, List<SourceLocation>> operator [](js.Node node) {
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
    js.JavaScriptPrintingOptions options = new js.JavaScriptPrintingOptions(
        shouldCompressOutput: true,
        preferSemicolonToNewlineInMinifiedOutput: true);
    LenientPrintingContext printingContext = new LenientPrintingContext();
    new js.Printer(options, printingContext).visit(node);
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
  void onStep(js.Node node, Offset offset, StepKind kind) {
    register(kind, node);
  }

  void register(StepKind kind, js.Node node, {bool expectInfo: true}) {
    String dartCodeFromSourceLocation(SourceLocation sourceLocation) {
      SourceFile sourceFile =
          sourceFileManager.getSourceFile(sourceLocation.sourceUri);
      if (sourceFile == null) {
        return sourceLocation.shortText;
      }
      return sourceFile.kernelSource
          .getTextLine(sourceLocation.line)
          .substring(sourceLocation.column - 1)
          .trim();
    }

    void addLocation(SourceLocation sourceLocation, String jsCode) {
      if (sourceLocation == null) {
        if (expectInfo) {
          SourceInformation sourceInformation = node.sourceInformation;
          SourceLocation sourceLocation;
          String dartCode;
          if (sourceInformation != null) {
            sourceLocation = sourceInformation.sourceLocations.first;
            dartCode = dartCodeFromSourceLocation(sourceLocation);
          }
          codePoints.add(new CodePoint(kind, jsCode, sourceLocation, dartCode,
              isMissing: true));
        }
      } else {
        codePoints.add(new CodePoint(kind, jsCode, sourceLocation,
            dartCodeFromSourceLocation(sourceLocation)));
      }
    }

    Map<int, List<SourceLocation>> locationMap = nodeMap[node];
    if (locationMap == null) {
      addLocation(null, nodeToString(node));
    } else {
      locationMap.forEach((int targetOffset, List<SourceLocation> locations) {
        String jsCode = nodeToString(node);
        for (SourceLocation location in locations) {
          addLocation(location, jsCode);
        }
      });
    }
  }
}

/// A JavaScript code point and its mapped dart source location.
class CodePoint {
  final StepKind kind;
  final String jsCode;
  final SourceLocation sourceLocation;
  final String dartCode;
  final bool isMissing;

  CodePoint(this.kind, this.jsCode, this.sourceLocation, this.dartCode,
      {this.isMissing: false});

  String toString() {
    return 'CodePoint[kind=$kind,js=$jsCode,dart=$dartCode,'
        'location=$sourceLocation]';
  }
}

class IOSourceFileManager implements SourceFileManager {
  final Uri base;

  Map<Uri, SourceFile> sourceFiles = <Uri, SourceFile>{};

  IOSourceFileManager(this.base);

  SourceFile getSourceFile(var uri) {
    Uri absoluteUri;
    if (uri is Uri) {
      absoluteUri = base.resolveUri(uri);
    } else {
      absoluteUri = base.resolve(uri);
    }
    return sourceFiles.putIfAbsent(absoluteUri, () {
      String text = new File.fromUri(absoluteUri).readAsStringSync();
      return new StringSourceFile.fromUri(absoluteUri, text);
    });
  }
}
