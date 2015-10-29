// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.helper;

import 'dart:async';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/apiimpl.dart' as api;
import 'package:compiler/src/null_compiler_output.dart' show NullSink;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/helpers/helpers.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js/js_debug.dart';
import 'package:compiler/src/js/js_source_mapping.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/source_file_provider.dart';
import '../memory_compiler.dart';
import '../output_collector.dart';

class OutputProvider implements CompilerOutput {
  BufferedEventSink jsMapOutput;

  @override
  EventSink<String> createEventSink(String name, String extension) {
    if (extension == 'js.map') {
      return jsMapOutput = new BufferedEventSink();
    }
    return new NullSink('$name.$extension');
  }
}

class CloningOutputProvider extends OutputProvider {
  RandomAccessFileOutputProvider outputProvider;

  CloningOutputProvider(Uri jsUri, Uri jsMapUri)
    : outputProvider = new RandomAccessFileOutputProvider(jsUri, jsMapUri);

  @override
  EventSink<String> createEventSink(String name, String extension) {
    EventSink<String> output = outputProvider(name, extension);
    if (extension == 'js.map') {
      output = new CloningEventSink(
          [output, jsMapOutput = new BufferedEventSink()]);
    }
    return output;
  }
}

abstract class SourceFileManager {
  SourceFile getSourceFile(var uri);
}

class ProviderSourceFileManager implements SourceFileManager {
  final SourceFileProvider sourceFileProvider;

  ProviderSourceFileManager(this.sourceFileProvider);

  @override
  SourceFile getSourceFile(uri) {
    return sourceFileProvider.getSourceFile(uri);
  }
}

class RecordingPrintingContext extends LenientPrintingContext {
  CodePositionListener listener;

  RecordingPrintingContext(this.listener);

  @override
  void exitNode(js.Node node,
                int startPosition,
                int endPosition,
                int closingPosition) {
    listener.onPositions(
        node, startPosition, endPosition, closingPosition);
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
  Future<List<SourceMapInfo>> process(
      List<String> options,
      {bool verbose: true}) async {
    OutputProvider outputProvider = outputToFile
        ? new OutputProvider()
        : new CloningOutputProvider(targetUri, sourceMapFileUri);
    if (options.contains('--use-new-source-info')) {
      if (verbose) print('Using the new source information system.');
      useNewSourceInfo = true;
    }
    api.CompilerImpl compiler = await compilerFor(
        outputProvider: outputProvider,
        // TODO(johnniwinther): Use [verbose] to avoid showing diagnostics.
        options: ['--out=$targetUri', '--source-map=$sourceMapFileUri']
            ..addAll(options));
    if (options.contains('--disable-inlining')) {
      if (verbose) print('Inlining disabled');
      compiler.disableInlining = true;
    }

    JavaScriptBackend backend = compiler.backend;
    var handler = compiler.handler;
    SourceFileProvider sourceFileProvider = handler.provider;
    sourceFileManager = new ProviderSourceFileManager(sourceFileProvider);
    await compiler.run(inputUri);

    List<SourceMapInfo> infoList = <SourceMapInfo>[];
    backend.generatedCode.forEach((Element element, js.Expression node) {
      js.JavaScriptPrintingOptions options =
          new js.JavaScriptPrintingOptions();
      JavaScriptSourceInformationStrategy sourceInformationStrategy =
          compiler.backend.sourceInformationStrategy;
      NodeToSourceLocationsMap nodeMap = new NodeToSourceLocationsMap();
      SourceInformationProcessor sourceInformationProcessor =
          sourceInformationStrategy.createProcessor(nodeMap);
      RecordingPrintingContext printingContext =
          new RecordingPrintingContext(sourceInformationProcessor);
      new js.Printer(options, printingContext).visit(node);
      sourceInformationProcessor.process(node);

      String code = printingContext.getText();
      CodePointComputer visitor =
          new CodePointComputer(sourceFileManager, code, nodeMap);
      visitor.apply(node);
      List<CodePoint> codePoints = visitor.codePoints;
      infoList.add(new SourceMapInfo(element, code, node, codePoints, nodeMap));
    });

    return infoList;
  }
}

/// Source mapping information for the JavaScript code of an [Element].
class SourceMapInfo {
  final String name;
  final Element element;
  final String code;
  final js.Expression node;
  final List<CodePoint> codePoints;
  final NodeToSourceLocationsMap nodeMap;

  SourceMapInfo(
      Element element, this.code, this.node, this.codePoints, this.nodeMap)
      : this.name = computeElementNameForSourceMaps(element),
        this.element = element;
}

/// Collection of JavaScript nodes with their source mapped target offsets
/// and source locations.
class NodeToSourceLocationsMap implements SourceMapper {
  final Map<js.Node, Map<int, List<SourceLocation>>> _nodeMap = {};

  @override
  void register(js.Node node, int codeOffset, SourceLocation sourceLocation) {
    _nodeMap.putIfAbsent(node, () => {})
        .putIfAbsent(codeOffset, () => [])
        .add(sourceLocation);
  }

  Iterable<js.Node> get nodes => _nodeMap.keys;

  Map<int, List<SourceLocation>> operator[] (js.Node node) {
    return _nodeMap[node];
  }
}

/// Visitor that computes the [CodePoint]s for source mapping locations.
class CodePointComputer extends js.BaseVisitor {
  final SourceFileManager sourceFileManager;
  final String code;
  final NodeToSourceLocationsMap nodeMap;
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

  void register(String kind, js.Node node, {bool expectInfo: true}) {

    String dartCodeFromSourceLocation(SourceLocation sourceLocation) {
      SourceFile sourceFile =
           sourceFileManager.getSourceFile(sourceLocation.sourceUri);
      return sourceFile.getLineText(sourceLocation.line)
          .substring(sourceLocation.column).trim();
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
          codePoints.add(new CodePoint(
              kind, jsCode, sourceLocation, dartCode, isMissing: true));
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

  void apply(js.Node node) {
    node.accept(this);
  }

  void visitNode(js.Node node) {
    register('${node.runtimeType}', node, expectInfo: false);
    super.visitNode(node);
  }

  @override
  void visitNew(js.New node) {
    node.arguments.forEach(apply);
    register('New', node);
  }

  @override
  void visitReturn(js.Return node) {
    if (node.value != null) {
      apply(node.value);
    }
    register('Return', node);
  }

  @override
  void visitCall(js.Call node) {
    apply(node.target);
    node.arguments.forEach(apply);
    register('Call (${node.target.runtimeType})', node);
  }

  @override
  void visitFun(js.Fun node) {
    node.visitChildren(this);
    register('Fun', node);
  }

  @override
  visitExpressionStatement(js.ExpressionStatement node) {
    node.visitChildren(this);
  }

  @override
  visitBinary(js.Binary node) {
    node.visitChildren(this);
  }

  @override
  visitAccess(js.PropertyAccess node) {
    node.visitChildren(this);
  }
}

/// A JavaScript code point and its mapped dart source location.
class CodePoint {
  final String kind;
  final String jsCode;
  final SourceLocation sourceLocation;
  final String dartCode;
  final bool isMissing;

  CodePoint(
      this.kind,
      this.jsCode,
      this.sourceLocation,
      this.dartCode,
      {this.isMissing: false});

  String toString() {
    return 'CodePoint[kind=$kind,js=$jsCode,dart=$dartCode,'
                     'location=$sourceLocation]';
  }
}
