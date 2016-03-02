// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.diff_view;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/io/position_information.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js/js_debug.dart';

import 'diff.dart';
import 'html_parts.dart';
import 'js_tracer.dart';
import 'output_structure.dart';
import 'sourcemap_helper.dart';
import 'sourcemap_html_helper.dart';
import 'trace_graph.dart';

const String WITH_SOURCE_INFO_STYLE = 'border: solid 1px #FF8080;';
const String WITHOUT_SOURCE_INFO_STYLE = 'background-color: #8080FF;';
const String ADDITIONAL_SOURCE_INFO_STYLE = 'border: solid 1px #80FF80;';
const String UNUSED_SOURCE_INFO_STYLE = 'border: solid 1px #8080FF;';

main(List<String> args) async {
  DEBUG_MODE = true;
  String out = 'out.js.diff_view.html';
  String filename;
  List<String> currentOptions = [];
  List<List<String>> optionSegments = [currentOptions];
  Map<int, String> loadFrom = {};
  Map<int, String> saveTo = {};
  int argGroup = 0;
  bool addAnnotations = true;
  for (String arg in args) {
    if (arg == '--') {
      currentOptions = [];
      optionSegments.add(currentOptions);
      argGroup++;
    } else if (arg == '-h') {
      addAnnotations = false;
      print('Hiding annotations');
    } else if (arg == '-l') {
      loadFrom[argGroup] = 'out.js.diff$argGroup.json';
    } else if (arg.startsWith('--load=')) {
      loadFrom[argGroup] = arg.substring('--load='.length);
    } else if (arg == '-s') {
      saveTo[argGroup] = 'out.js.diff$argGroup.json';
    } else if (arg.startsWith('--save=')) {
      saveTo[argGroup] = arg.substring('--save='.length);
    } else if (arg.startsWith('-o')) {
      out = arg.substring('-o'.length);
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
    } else if (arg.startsWith('-')) {
      currentOptions.add(arg);
    } else {
      filename = arg;
    }
  }
  List<String> commonArguments = optionSegments[0];
  List<List<String>> options = <List<String>>[];
  if (optionSegments.length == 1) {
    // Use default options; comparing SSA and CPS output using the new
    // source information strategy.
    options.add([Flags.useNewSourceInfo]..addAll(commonArguments));
    options.add(
        [Flags.useNewSourceInfo, Flags.useCpsIr]..addAll(commonArguments));
  } else if (optionSegments.length == 2) {
    // Use alternative options for the second output column.
    options.add(commonArguments);
    options.add(optionSegments[1]..addAll(commonArguments));
  } else {
    // Use specific options for both output columns.
    options.add(optionSegments[1]..addAll(commonArguments));
    options.add(optionSegments[2]..addAll(commonArguments));
  }

  SourceFileManager sourceFileManager = new IOSourceFileManager(Uri.base);
  List<AnnotatedOutput> outputs = <AnnotatedOutput>[];
  for (int i = 0; i < 2; i++) {
    AnnotatedOutput output;
    if (loadFrom.containsKey(i)) {
      output = AnnotatedOutput.loadOutput(loadFrom[i]);
    } else {
      print('Compiling ${options[i].join(' ')} $filename');
      CodeLinesResult result = await computeCodeLines(
          options[i], filename, addAnnotations: addAnnotations);
      OutputStructure structure = OutputStructure.parse(result.codeLines);
      computeEntityCodeSources(result, structure);
      output = new AnnotatedOutput(
          filename,
          options[i],
          structure,
          result.coverage.getCoverageReport());
    }
    if (saveTo.containsKey(i)) {
      AnnotatedOutput.saveOutput(output, saveTo[i]);
    }
    outputs.add(output);
  }

  List<DiffBlock> blocks = createDiffBlocks(
      outputs.map((o) => o.structure).toList(),
      sourceFileManager);

  outputDiffView(
      out, outputs, blocks, addAnnotations: addAnnotations);
}

/// Attaches [CodeSource]s to the entities in [structure] using the
/// element-to-offset in [result].
void computeEntityCodeSources(
    CodeLinesResult result, OutputStructure structure) {
  result.elementMap.forEach((int line, Element element) {
    OutputEntity entity = structure.getEntityForLine(line);
    if (entity != null) {
      entity.codeSource = codeSourceFromElement(element);
    }
  });
}

/// The structured output of a compilation.
class AnnotatedOutput {
  final String filename;
  final List<String> options;
  final OutputStructure structure;
  final String coverage;

  AnnotatedOutput(this.filename, this.options, this.structure, this.coverage);

  List<CodeLine> get codeLines => structure.lines;

  Map toJson() {
    return {
      'filename': filename,
      'options': options,
      'structure': structure.toJson(),
      'coverage': coverage,
    };
  }

  static AnnotatedOutput fromJson(Map json) {
    String filename = json['filename'];
    List<String> options = json['options'];
    OutputStructure structure = OutputStructure.fromJson(json['structure']);
    String coverage = json['coverage'];
    return new AnnotatedOutput(filename, options, structure, coverage);
  }

  static AnnotatedOutput loadOutput(filename) {
    AnnotatedOutput output = AnnotatedOutput.fromJson(
        JSON.decode(new File(filename).readAsStringSync()));
    print('Output loaded from $filename');
    return output;
  }

  static void saveOutput(AnnotatedOutput output, String filename) {
    if (filename != null) {
      new File(filename).writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(output.toJson()));
      print('Output saved in $filename');
    }
  }
}

void outputDiffView(
    String out,
    List<AnnotatedOutput> outputs,
    List<DiffBlock> blocks,
    {bool addAnnotations: true}) {
  assert(outputs[0].filename == outputs[1].filename);
  bool usePre = true;

  StringBuffer sb = new StringBuffer();
  sb.write('''
<html>
<head>
<title>Diff for ${outputs[0].filename}</title>
<style>
.lineNumber {
  font-size: smaller;
  color: #888;
}
.comment {
  font-size: smaller;
  color: #888;
  font-family: initial;
}
.header {
  position: fixed;
  width: 100%;
  background-color: #FFFFFF;
  left: 0px;
  top: 0px;
  height: 42px;
  z-index: 1000;
}
.header-table {
  width: 100%;
  background-color: #400000;
  color: #FFFFFF;
  border-spacing: 0px;
}
.header-column {
  width: 34%;
}
.legend {
  padding: 2px;
}
.table {
  position: absolute;
  left: 0px;
  top: 42px;
  width: 100%;
  border-spacing: 0px;
}
.cell {
  max-width: 500px;
  overflow-y: hidden;
  vertical-align: top;
  border-top: 1px solid #F0F0F0;
  border-left: 1px solid #F0F0F0;
''');
  if (usePre) {
    sb.write('''
  overflow-x: hidden;
  white-space: pre-wrap;
''');
  } else {
    sb.write('''
  overflow-x: hidden;
  padding-left: 100px;
  text-indent: -100px;
''');
  }
  sb.write('''
  font-family: monospace;
  padding: 0px;
}
.corresponding1 {
  background-color: #FFFFE0;
}
.corresponding2 {
  background-color: #EFEFD0;
}
.identical1 {
  background-color: #E0F0E0;
}
.identical2 {
  background-color: #C0E0C0;
}
.line {
  padding-left: 7em;
  text-indent: -7em;
  margin: 0px;
}
.column0 {
}
.column1 {
}
.column2 {
}
</style>
</head>
<body>''');

  sb.write('''
<div class="header">
<table class="header-table"><tr>
<td class="header-column">[${outputs[0].options.join(',')}]</td>
<td class="header-column">[${outputs[1].options.join(',')}]</td>
<td class="header-column">Dart code</td>
</tr></table>
<div class="legend">
  <span class="identical1">&nbsp;&nbsp;&nbsp;</span> 
  <span class="identical2">&nbsp;&nbsp;&nbsp;</span>
  identical blocks
  <span class="corresponding1">&nbsp;&nbsp;&nbsp;</span>
  <span class="corresponding2">&nbsp;&nbsp;&nbsp;</span> 
  corresponding blocks
''');

  if (addAnnotations) {
    sb.write('''
  <span style="$WITH_SOURCE_INFO_STYLE">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset with source information' means that source information 
is available for an offset which is expected to have a source location 
attached. This offset has source information as intended.">
  offset with source information</span>
  <span style="$WITHOUT_SOURCE_INFO_STYLE">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset without source information' means that _no_ source 
information is available for an offset which was expected to have a source 
location attached. Source information must be found for this offset.">
  offset without source information</span>
  <span style="$ADDITIONAL_SOURCE_INFO_STYLE">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset with unneeded source information' means that a source 
location was attached to an offset which was _not_ expected to have a source
location attached. The source location should be removed from this offset.">
  offset with unneeded source information</span>
  <span style="$UNUSED_SOURCE_INFO_STYLE">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset with unused source information' means that source 
information is available for an offset which is _not_ expected to have a source
location attached. This source information _could_ be used by a parent AST node
offset that is an 'offset without source information'."> 
  offset with unused source information</span>
''');
  }

  sb.write('''
</div></div>
<table class="table">
''');

  void addCell(String content) {
    sb.write('''
<td class="cell"><pre>
''');
    sb.write(content);
    sb.write('''
</pre></td>
''');
  }

  /// Marker to alternate output colors.
  bool alternating = false;

  List<HtmlPrintContext> printContexts = <HtmlPrintContext>[];
  for (int i = 0; i < 2; i++) {
    int lineNoWidth;
    if (outputs[i].codeLines.isNotEmpty) {
      lineNoWidth = '${outputs[i].codeLines.last.lineNo + 1}'.length;
    }
    printContexts.add(new HtmlPrintContext(lineNoWidth: lineNoWidth));
  }

  for (DiffBlock block in blocks) {
    String className;
    switch (block.kind) {
      case DiffKind.UNMATCHED:
        className = 'cell';
        break;
      case DiffKind.MATCHING:
        className = 'cell corresponding${alternating ? '1' : '2'}';
        alternating = !alternating;
        break;
      case DiffKind.IDENTICAL:
        className = 'cell identical${alternating ? '1' : '2'}';
        alternating = !alternating;
        break;
    }
    sb.write('<tr>');
    for (int index = 0; index < 3; index++) {
      sb.write('''<td class="$className column$index">''');
      List<HtmlPart> lines = block.getColumn(index);
      if (lines.isNotEmpty) {
        for (HtmlPart line in lines) {
          sb.write('<p class="line">');
          if (index < printContexts.length) {
            line.printHtmlOn(sb, printContexts[index]);
          } else {
            line.printHtmlOn(sb, new HtmlPrintContext());
          }
          sb.write('</p>');
        }
      }
      sb.write('''</td>''');
    }
    sb.write('</tr>');
  }

  sb.write('''</tr><tr>''');

  addCell(outputs[0].coverage);
  addCell(outputs[1].coverage);

  sb.write('''
</table>
</body>
</html>
''');

  new File(out).writeAsStringSync(sb.toString());
  print('Diff generated in $out');
}

class CodeLinesResult {
  final List<CodeLine> codeLines;
  final Coverage coverage;
  final Map<int, Element> elementMap;
  final SourceFileManager sourceFileManager;

  CodeLinesResult(this.codeLines, this.coverage,
      this.elementMap, this.sourceFileManager);
}

/// Compute [CodeLine]s and [Coverage] for [filename] using the given [options].
Future<CodeLinesResult> computeCodeLines(
    List<String> options,
    String filename,
    {bool addAnnotations: true}) async {
  SourceMapProcessor processor = new SourceMapProcessor(filename);
  SourceMaps sourceMaps =
      await processor.process(options, perElement: true, forMain: true);

  const int WITH_SOURCE_INFO = 0;
  const int WITHOUT_SOURCE_INFO = 1;
  const int ADDITIONAL_SOURCE_INFO = 2;
  const int UNUSED_SOURCE_INFO = 3;

  SourceMapInfo info = sourceMaps.mainSourceMapInfo;

  List<CodeLine> codeLines;
  Coverage coverage = new Coverage();
  List<Annotation> annotations = <Annotation>[];

  void addAnnotation(int id, int offset, String title) {
    annotations.add(new Annotation(id, offset, title));
  }

  String code = info.code;
  TraceGraph graph = createTraceGraph(info, coverage);
  if (addAnnotations) {
    Set<js.Node> mappedNodes = new Set<js.Node>();

    void addSourceLocations(
        int kind, int offset, List<SourceLocation> locations, String prefix) {

      addAnnotation(kind, offset,
          '${prefix}${locations
              .where((l) => l != null)
              .map((l) => l.shortText)
              .join('\n')}');
    }

    bool addSourceLocationsForNode(int kind, js.Node node, String prefix) {
      Map<int, List<SourceLocation>> locations = info.nodeMap[node];
      if (locations == null || locations.isEmpty) {
        return false;
      }
      locations.forEach(
          (int offset, List<SourceLocation> locations) {
        addSourceLocations(kind, offset, locations,
            '${prefix}\n${truncate(nodeToString(node), 80)}\n');
      });
      mappedNodes.add(node);
      return true;
    }


    for (TraceStep step in graph.steps) {
      String title = '${step.id}:${step.kind}:${step.offset}';
      if (!addSourceLocationsForNode(WITH_SOURCE_INFO, step.node, title)) {
        int offset;
        if (options.contains(Flags.useNewSourceInfo)) {
          offset = step.offset.subexpressionOffset;
        } else {
          offset = info.jsCodePositions[step.node].startPosition;
        }
        if (offset != null) {
          addAnnotation(WITHOUT_SOURCE_INFO, offset, title);
        }
      }
    }
    for (js.Node node in info.nodeMap.nodes) {
      if (!mappedNodes.contains(node)) {
        addSourceLocationsForNode(ADDITIONAL_SOURCE_INFO, node, '');
      }
    }
    SourceLocationCollector collector = new SourceLocationCollector();
    info.node.accept(collector);
    collector.sourceLocations.forEach(
        (js.Node node, List<SourceLocation> locations) {
      if (!mappedNodes.contains(node)) {
        int offset = info.jsCodePositions[node].startPosition;
        addSourceLocations(UNUSED_SOURCE_INFO, offset, locations, '');
      }
    });
  }

  StringSourceFile sourceFile = new StringSourceFile.fromName(filename, code);
  Map<int, Element> elementMap = <int, Element>{};
  sourceMaps.elementSourceMapInfos.forEach(
      (Element element, SourceMapInfo info) {
    CodePosition position = info.jsCodePositions[info.node];
    elementMap[sourceFile.getLine(position.startPosition)] = element;
  });

  codeLines = convertAnnotatedCodeToCodeLines(
      code,
      annotations,
      colorScheme: new CustomColorScheme(
        single: (int id) {
          if (id == WITH_SOURCE_INFO) {
            return WITH_SOURCE_INFO_STYLE;
          } else if (id == ADDITIONAL_SOURCE_INFO) {
            return ADDITIONAL_SOURCE_INFO_STYLE;
          } else if (id == UNUSED_SOURCE_INFO) {
            return UNUSED_SOURCE_INFO_STYLE;
          }
          return WITHOUT_SOURCE_INFO_STYLE;
        },
        multi: (List ids) {
          if (ids.contains(WITH_SOURCE_INFO)) {
            return WITH_SOURCE_INFO_STYLE;
          } else if (ids.contains(ADDITIONAL_SOURCE_INFO)) {
            return ADDITIONAL_SOURCE_INFO_STYLE;
          } else if (ids.contains(UNUSED_SOURCE_INFO)) {
            return UNUSED_SOURCE_INFO_STYLE;
          }
          return WITHOUT_SOURCE_INFO_STYLE;
        }
      ));
  return new CodeLinesResult(codeLines, coverage, elementMap,
      sourceMaps.sourceFileManager);
}

/// Visitor that computes a map from [js.Node]s to all attached source
/// locations.
class SourceLocationCollector extends js.BaseVisitor {
  Map<js.Node, List<SourceLocation>> sourceLocations =
      <js.Node, List<SourceLocation>>{};

  @override
  visitNode(js.Node node) {
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      sourceLocations[node] = sourceInformation.sourceLocations;
    }
    node.visitChildren(this);
  }
}

/// Compute a [CodeSource] for source span of [element].
CodeSource codeSourceFromElement(Element element) {
  CodeKind kind;
  Uri uri;
  String name;
  int begin;
  int end;
  if (element.isLibrary) {
    LibraryElement library = element;
    kind = CodeKind.LIBRARY;
    name = library.libraryOrScriptName;
    uri = library.entryCompilationUnit.script.resourceUri;
  } else if (element.isClass) {
    kind = CodeKind.CLASS;
    name = element.name;
    uri = element.compilationUnit.script.resourceUri;
  } else {
    AstElement astElement = element.implementation;
    kind = CodeKind.MEMBER;
    uri = astElement.compilationUnit.script.resourceUri;
    name = computeElementNameForSourceMaps(astElement);
    if (astElement.hasNode) {
      begin = astElement.node.getBeginToken().charOffset;
      end = astElement.node.getEndToken().charEnd;
    }
  }
  return new CodeSource(kind, uri, name, begin, end);
}