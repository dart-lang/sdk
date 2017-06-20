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

import 'diff.dart';
import 'html_parts.dart';
import 'js_tracer.dart';
import 'output_structure.dart';
import 'sourcemap_helper.dart';
import 'sourcemap_html_helper.dart';
import 'trace_graph.dart';

main(List<String> args) async {
  DEBUG_MODE = true;
  String out = 'out.js.diff_view.html';
  String filename;
  List<String> currentOptions = [];
  List<List<String>> optionSegments = [currentOptions];
  Map<int, String> loadFrom = {};
  Map<int, String> saveTo = {};
  int argGroup = 0;
  bool showAnnotations = true;
  for (String arg in args) {
    if (arg == '--') {
      currentOptions = [];
      optionSegments.add(currentOptions);
      argGroup++;
    } else if (arg == '-h') {
      showAnnotations = false;
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
    // TODO(sigmund, johnniwinther): change default options now that CPS is
    // deleted.
    // Use default options; comparing SSA and CPS output using the new
    // source information strategy.
    options.add(commonArguments);
    options.add([Flags.useNewSourceInfo]..addAll(commonArguments));
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
      CodeLinesResult result = await computeCodeLines(options[i], filename);
      OutputStructure structure = OutputStructure.parse(result.codeLines);
      computeEntityCodeSources(result, structure);
      output = new AnnotatedOutput(
          filename, options[i], structure, result.coverage.getCoverageReport());
    }
    if (saveTo.containsKey(i)) {
      AnnotatedOutput.saveOutput(output, saveTo[i]);
    }
    outputs.add(output);
  }

  List<DiffBlock> blocks = createDiffBlocks(
      outputs.map((o) => o.structure).toList(), sourceFileManager);

  outputDiffView(out, outputs, blocks,
      showMarkers: showAnnotations, showSourceMapped: showAnnotations);
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

class CodeLineAnnotationJsonStrategy implements JsonStrategy {
  const CodeLineAnnotationJsonStrategy();

  Map encodeAnnotation(Annotation annotation) {
    CodeLineAnnotation data = annotation.data;
    return {
      'id': annotation.id,
      'codeOffset': annotation.codeOffset,
      'title': annotation.title,
      'data': data.toJson(this),
    };
  }

  Annotation decodeAnnotation(Map json) {
    return new Annotation(json['id'], json['codeOffset'], json['title'],
        data: CodeLineAnnotation.fromJson(json['data'], this));
  }

  @override
  decodeLineAnnotation(json) {
    if (json != null) {
      return CodeSource.fromJson(json);
    }
    return null;
  }

  @override
  encodeLineAnnotation(covariant CodeSource lineAnnotation) {
    if (lineAnnotation != null) {
      return lineAnnotation.toJson();
    }
    return null;
  }
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
      'structure': structure.toJson(const CodeLineAnnotationJsonStrategy()),
      'coverage': coverage,
    };
  }

  static AnnotatedOutput fromJson(Map json) {
    String filename = json['filename'];
    List<String> options = json['options'];
    OutputStructure structure = OutputStructure.fromJson(
        json['structure'], const CodeLineAnnotationJsonStrategy());
    String coverage = json['coverage'];
    return new AnnotatedOutput(filename, options, structure, coverage);
  }

  static AnnotatedOutput loadOutput(filename) {
    AnnotatedOutput output = AnnotatedOutput
        .fromJson(JSON.decode(new File(filename).readAsStringSync()));
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
    String out, List<AnnotatedOutput> outputs, List<DiffBlock> blocks,
    {bool showMarkers: true, bool showSourceMapped: true}) {
  assert(outputs[0].filename == outputs[1].filename);
  bool usePre = true;

  StringBuffer sb = new StringBuffer();
  sb.write('''
<html>
<head>
<title>Diff for ${outputs[0].filename}</title>
<style>
.${ClassNames.lineNumber} {
  font-size: smaller;
  color: #888;
}
.${ClassNames.comment} {
  font-size: smaller;
  color: #888;
  font-family: initial;
}
.${ClassNames.header} {
  position: fixed;
  width: 100%;
  background-color: #FFFFFF;
  left: 0px;
  top: 0px;
  height: 42px;
  z-index: 1000;
}
.${ClassNames.headerTable} {
  width: 100%;
  background-color: #400000;
  color: #FFFFFF;
  border-spacing: 0px;
}
.${ClassNames.headerColumn} {
}
.${ClassNames.legend} {
  padding: 2px;
}
.${ClassNames.buttons} {
  position: fixed;
  right: 0px;
  top: 0px;
  width: 220px;
  background-color: #FFFFFF;
  border: 1px solid #C0C0C0;
  z-index: 2000;
}
.${ClassNames.table} {
  position: absolute;
  left: 0px;
  top: 42px;
  width: 100%;
  border-spacing: 0px;
}
.${ClassNames.cell}, 
.${ClassNames.innerCell}, 
.${ClassNames.originalDart}, 
.${ClassNames.inlinedDart} {
  overflow-y: hidden;
  vertical-align: top;
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
.${ClassNames.cell} {
  border-top: 1px solid #F0F0F0;
  border-left: 1px solid #C0C0C0;
}
.${ClassNames.innerCell} {
  /*border-top: 1px solid #F8F8F8;*/
  width: 50%;
  max-width: 250px;
}
.${ClassNames.corresponding(false)} {
  background-color: #FFFFE0;
}
.${ClassNames.corresponding(true)} {
  background-color: #EFEFD0;
}
.${ClassNames.identical(false)} {
  background-color: #E0F0E0;
}
.${ClassNames.identical(true)} {
  background-color: #C0E0C0;
}
.${ClassNames.line} {
  padding-left: 7em;
  text-indent: -7em;
  margin: 0px;
}
.${ClassNames.column(column_js0)} {
  max-width: 500px;
  width: 500px;
}
.${ClassNames.column(column_js1)} {
  max-width: 500px;
  width: 500px;
}
.${ClassNames.column(column_dart)} {
  max-width: 300px;
  width: 300px;
}
.${ClassNames.colored(0)} {
  color: #FF0000;
}
.${ClassNames.colored(1)} {
  color: #C0C000;
}
.${ClassNames.colored(2)} {
  color: #008000;
}
.${ClassNames.colored(3)} {
  color: #00C0C0;
}
.${ClassNames.withSourceInfo} {
  border: solid 1px #FF8080;
}
.${ClassNames.withoutSourceInfo} {
  background-color: #8080FF;
}
.${ClassNames.additionalSourceInfo} {
  border: solid 1px #80FF80;
}
.${ClassNames.unusedSourceInfo} {
  border: solid 1px #8080FF;
}
.${ClassNames.originalDart} {
}
.${ClassNames.inlinedDart} {
}
''');
  for (int i = 0; i < HUE_COUNT; i++) {
    sb.write('''
.${ClassNames.sourceMappingIndex(i)} {
  background-color: ${toColorCss(i)};
}
''');
  }
  sb.write('''
.${ClassNames.sourceMapped} {
  ${showSourceMapped ? '' : 'display: none;'}
}
.${ClassNames.sourceMapping} {
  ${showSourceMapped ? '' : 'border: 0px;'}
  ${showSourceMapped ? '' : 'background-color: transparent;'}
}
.${ClassNames.markers} {
  ${showMarkers ? '' : 'display: none;'}
}
.${ClassNames.marker} {
  ${showMarkers ? '' : 'border: 0px;'}
  ${showMarkers ? '' : 'background-color: transparent;'}
}
</style>
<script>
function isChecked(name) {
  var box = document.getElementById('box-' + name);
  return box.checked;
}
function toggleDisplay(name) {
  var checked = isChecked(name);
  var styleSheet = document.styleSheets[0];
  for (var index = 0; index < styleSheet.cssRules.length; index++) {
    var cssRule = styleSheet.cssRules[index];
    if (cssRule.selectorText == '.' + name) {
      if (checked) {
        cssRule.style.removeProperty('display');
      } else {
        cssRule.style.display = 'none';
      }
    }
  }
  return checked;
}
function toggle${ClassNames.sourceMapped}() {
  var checked = toggleDisplay('${ClassNames.sourceMapped}');
  toggleAnnotations(checked, '${ClassNames.sourceMapping}');
}
function toggle${ClassNames.markers}() {
  var checked = toggleDisplay('${ClassNames.markers}');
  toggleAnnotations(checked, '${ClassNames.marker}');
}
function toggleAnnotations(show, name) {
  var styleSheet = document.styleSheets[0];
  for (var index = 0; index < styleSheet.cssRules.length; index++) {
    var cssRule = styleSheet.cssRules[index];
    if (cssRule.selectorText == '.' + name) {
      if (show) {
        cssRule.style.removeProperty('border');
        cssRule.style.removeProperty('background-color');
      } else {
        cssRule.style.border = '0px';
        cssRule.style.backgroundColor = 'transparent';
      }
    }
  }
} 
</script>
</head>
<body>''');

  sb.write('''
<div class="${ClassNames.header}">
<div class="${ClassNames.legend}">
  <span class="${ClassNames.identical(false)}">&nbsp;&nbsp;&nbsp;</span> 
  <span class="${ClassNames.identical(true)}">&nbsp;&nbsp;&nbsp;</span>
  identical blocks
  <span class="${ClassNames.corresponding(false)}">&nbsp;&nbsp;&nbsp;</span>
  <span class="${ClassNames.corresponding(true)}">&nbsp;&nbsp;&nbsp;</span> 
  corresponding blocks
''');

  sb.write('''
  <span class="${ClassNames.markers}">
  <span class="${ClassNames.withSourceInfo}">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset with source information' means that source information 
is available for an offset which is expected to have a source location 
attached. This offset has source information as intended.">
  offset with source information</span>
  <span class="${ClassNames.withoutSourceInfo}">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset without source information' means that _no_ source 
information is available for an offset which was expected to have a source 
location attached. Source information must be found for this offset.">
  offset without source information</span>
  <span class="${ClassNames.additionalSourceInfo}">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset with unneeded source information' means that a source 
location was attached to an offset which was _not_ expected to have a source
location attached. The source location should be removed from this offset.">
  offset with unneeded source information</span>
  <span class="${ClassNames.unusedSourceInfo}">&nbsp;&nbsp;&nbsp;</span>
  <span title="'offset with unused source information' means that source 
information is available for an offset which is _not_ expected to have a source
location attached. This source information _could_ be used by a parent AST node
offset that is an 'offset without source information'."> 
  offset with unused source information</span>
  </span>
  <span class="${ClassNames.sourceMapped}">
''');
  for (int i = 0; i < HUE_COUNT; i++) {
    sb.write('''
<span class="${ClassNames.sourceMappingIndex(i)}">&nbsp;&nbsp;</span>''');
  }
  sb.write('''
  <span title="JavaScript offsets and their corresponding Dart Code offset 
as mapped through source-maps.">
  mapped source locations</span>
  </span>
''');

  /// Marker to alternate output colors.
  bool alternating = false;

  List<HtmlPrintContext> printContexts = <HtmlPrintContext>[];
  for (int i = 0; i < 2; i++) {
    int lineNoWidth;
    if (outputs[i].codeLines.isNotEmpty) {
      lineNoWidth = '${outputs[i].codeLines.last.lineNo + 1}'.length;
    }
    printContexts.add(new HtmlPrintContext(
        lineNoWidth: lineNoWidth,
        getAnnotationData: getAnnotationData,
        getLineData: getLineData));
  }

  Set<DiffColumn> allColumns = new Set<DiffColumn>();
  for (DiffBlock block in blocks) {
    allColumns.addAll(block.columns);
  }

  List<DiffColumn> columns = [column_js0, column_js1, column_dart]
      .where((c) => allColumns.contains(c))
      .toList();

  sb.write('''
</div>
<table class="${ClassNames.headerTable}"><tr>''');
  for (DiffColumn column in columns) {
    sb.write('''
<td class="${ClassNames.headerColumn} ${ClassNames.column(column)}">''');
    if (column.type == 'js') {
      sb.write('''[${outputs[column.index].options.join(',')}]''');
    } else {
      sb.write('''Dart code''');
    }
    sb.write('''</td>''');
  }

  sb.write('''
</tr></table>
</div>
<table class="${ClassNames.table}">
''');

  for (DiffBlock block in blocks) {
    String className;
    switch (block.kind) {
      case DiffKind.UNMATCHED:
        className = '${ClassNames.cell}';
        break;
      case DiffKind.MATCHING:
        className =
            '${ClassNames.cell} ${ClassNames.corresponding(alternating)}';
        alternating = !alternating;
        break;
      case DiffKind.IDENTICAL:
        className = '${ClassNames.cell} ${ClassNames.identical(alternating)}';
        alternating = !alternating;
        break;
    }
    sb.write('<tr>');
    for (DiffColumn column in columns) {
      sb.write('''<td class="$className ${ClassNames.column(column)}">''');
      HtmlPrintContext context = new HtmlPrintContext(
          lineNoWidth: 4,
          includeAnnotation: (Annotation annotation) {
            CodeLineAnnotation data = annotation.data;
            return data.annotationType == AnnotationType.WITH_SOURCE_INFO ||
                data.annotationType == AnnotationType.ADDITIONAL_SOURCE_INFO;
          },
          getAnnotationData: getAnnotationData,
          getLineData: getLineData);
      if (column.type == 'js') {
        context = printContexts[column.index];
      }
      block.printHtmlOn(column, sb, context);
      sb.write('''</td>''');
    }
    sb.write('</tr>');
  }

  sb.write('''</tr><tr>''');

  for (DiffColumn column in columns) {
    sb.write('''
<td class="${ClassNames.cell} ${ClassNames.column(column)}"><pre>''');
    if (column.type == 'js') {
      sb.write(outputs[column.index].coverage);
    }
    sb.write('''</td>''');
  }

  sb.write('''
</table>
<div class="${ClassNames.buttons}">
<input type="checkbox" id="box-${ClassNames.column(column_js0)}" 
  onclick="javascript:toggleDisplay('${ClassNames.column(column_js0)}')" 
  checked>
Left JavaScript code<br/>

<input type="checkbox" id="box-${ClassNames.column(column_js1)}" 
  onclick="javascript:toggleDisplay('${ClassNames.column(column_js1)}')" 
  checked>
Right JavaScript code<br/>

<input type="checkbox" id="box-${ClassNames.column(column_dart)}" 
  onclick="javascript:toggleDisplay('${ClassNames.column(column_dart)}')" 
  checked>
<span title="Show column with Dart code corresponding to the block.">
Dart code</span><br/>

<input type="checkbox" id="box-${ClassNames.inlinedDart}" 
  onclick="javascript:toggleDisplay('${ClassNames.inlinedDart}')" checked>
<span title="Show Dart code inlined into the block.">
Inlined Dart code</span><br/>

<input type="checkbox" id="box-${ClassNames.markers}" 
  onclick="javascript:toggle${ClassNames.markers}()" 
  ${showMarkers ? 'checked' : ''}>
<span title="Show markers for JavaScript offsets with source information.">
Source information markers</span><br/>

<input type="checkbox" id="box-${ClassNames.sourceMapped}" 
  onclick="javascript:toggle${ClassNames.sourceMapped}()" 
  ${showSourceMapped ? 'checked' : ''}>
<span title="Show line-per-line mappings of JavaScript to Dart code.">
Source mapped Dart code</span><br/>
</div>
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
  final CodeSources codeSources;

  CodeLinesResult(this.codeLines, this.coverage, this.elementMap,
      this.sourceFileManager, this.codeSources);
}

class CodeSources {
  Map<Element, CodeSource> codeSourceMap = <Element, CodeSource>{};
  Map<Uri, Map<Interval, CodeSource>> uriCodeSourceMap =
      <Uri, Map<Interval, CodeSource>>{};

  CodeSources(SourceMapProcessor processor, SourceMaps sourceMaps) {
    CodeSource computeCodeSource(Element element) {
      return codeSourceMap.putIfAbsent(element, () {
        CodeSource codeSource = codeSourceFromElement(element);
        if (codeSource.begin != null) {
          Interval interval = new Interval(codeSource.begin, codeSource.end);
          Map<Interval, CodeSource> intervals =
              uriCodeSourceMap[codeSource.uri];
          if (intervals == null) {
            intervals = <Interval, CodeSource>{};
            uriCodeSourceMap[codeSource.uri] = intervals;
          } else {
            for (Interval existingInterval in intervals.keys.toList()) {
              if (existingInterval.contains(interval.from)) {
                CodeSource existingCodeSource = intervals[existingInterval];
                intervals.remove(existingInterval);
                if (existingInterval.from < interval.from) {
                  Interval preInterval =
                      new Interval(existingInterval.from, interval.from);
                  intervals[preInterval] = existingCodeSource;
                }
                if (interval.to < existingInterval.to) {
                  Interval postInterval =
                      new Interval(interval.to, existingInterval.to);
                  intervals[postInterval] = existingCodeSource;
                }
              }
            }
          }
          intervals[interval] = codeSource;
        }
        if (element is ClassElement) {
          element.forEachLocalMember((Element member) {
            codeSource.members.add(computeCodeSource(member));
          });
          element.implementation.forEachLocalMember((Element member) {
            codeSource.members.add(computeCodeSource(member));
          });
        } else if (element is MemberElement) {
          element.nestedClosures.forEach((Element closure) {
            codeSource.members.add(computeCodeSource(closure));
          });
        }
        return codeSource;
      });
    }

    for (LibraryElement library
        in sourceMaps.compiler.libraryLoader.libraries) {
      library.forEachLocalMember(computeCodeSource);
      library.implementation.forEachLocalMember(computeCodeSource);
    }

    uriCodeSourceMap.forEach((Uri uri, Map<Interval, CodeSource> intervals) {
      List<Interval> sortedKeys = intervals.keys.toList()
        ..sort((i1, i2) => i1.from.compareTo(i2.from));
      Map<Interval, CodeSource> sortedintervals = <Interval, CodeSource>{};
      sortedKeys.forEach((Interval interval) {
        sortedintervals[interval] = intervals[interval];
      });
      uriCodeSourceMap[uri] = sortedintervals;
    });
  }

  CodeSource sourceLocationToCodeSource(SourceLocation sourceLocation) {
    Map<Interval, CodeSource> intervals =
        uriCodeSourceMap[sourceLocation.sourceUri];
    if (intervals == null) {
      print('No code source for $sourceLocation(${sourceLocation.offset})');
      print(' -- no intervals for ${sourceLocation.sourceUri}');
      return null;
    }
    for (Interval interval in intervals.keys) {
      if (interval.contains(sourceLocation.offset)) {
        return intervals[interval];
      }
    }
    print('No code source for $sourceLocation(${sourceLocation.offset})');
    intervals.forEach((k, v) => print(' $k: ${v.name}'));
    return null;
  }
}

/// Compute [CodeLine]s and [Coverage] for [filename] using the given [options].
Future<CodeLinesResult> computeCodeLines(
    List<String> options, String filename) async {
  SourceMapProcessor processor = new SourceMapProcessor(filename);
  SourceMaps sourceMaps =
      await processor.process(options, perElement: true, forMain: true);

  CodeSources codeSources = new CodeSources(processor, sourceMaps);

  SourceMapInfo info = sourceMaps.mainSourceMapInfo;

  int nextAnnotationId = 0;
  List<CodeLine> codeLines;
  Coverage coverage = new Coverage();
  Map<int, List<CodeLineAnnotation>> codeLineAnnotationMap =
      <int, List<CodeLineAnnotation>>{};

  /// Create a [CodeLineAnnotation] for [codeOffset].
  void addCodeLineAnnotation(
      {AnnotationType annotationType,
      int codeOffset,
      List<SourceLocation> locations: const <SourceLocation>[],
      String stepInfo}) {
    if (annotationType == AnnotationType.WITHOUT_SOURCE_INFO ||
        annotationType == AnnotationType.UNUSED_SOURCE_INFO) {
      locations = [];
    }
    List<CodeLocation> codeLocations = locations
        .map((l) => new CodeLocation(l.sourceUri, l.sourceName, l.offset))
        .toList();
    List<CodeSource> codeSourceList = locations
        .map(codeSources.sourceLocationToCodeSource)
        .where((c) => c != null)
        .toList();
    CodeLineAnnotation data = new CodeLineAnnotation(
        annotationId: nextAnnotationId++,
        annotationType: annotationType,
        codeLocations: codeLocations,
        codeSources: codeSourceList,
        stepInfo: stepInfo);
    codeLineAnnotationMap
        .putIfAbsent(codeOffset, () => <CodeLineAnnotation>[])
        .add(data);
  }

  String code = info.code;
  TraceGraph graph = createTraceGraph(info, coverage);

  Set<js.Node> mappedNodes = new Set<js.Node>();

  /// Add an annotation for [codeOffset] pointing to [locations].
  void addSourceLocations(
      {AnnotationType annotationType,
      int codeOffset,
      List<SourceLocation> locations,
      String stepInfo}) {
    locations = locations.where((l) => l != null).toList();
    addCodeLineAnnotation(
        annotationType: annotationType,
        codeOffset: codeOffset,
        stepInfo: stepInfo,
        locations: locations);
  }

  /// Add annotations for all mappings created for [node].
  bool addSourceLocationsForNode(
      {AnnotationType annotationType, js.Node node, String stepInfo}) {
    Map<int, List<SourceLocation>> locations = info.nodeMap[node];
    if (locations == null || locations.isEmpty) {
      return false;
    }
    locations.forEach((int offset, List<SourceLocation> locations) {
      addSourceLocations(
          annotationType: annotationType,
          codeOffset: offset,
          locations: locations,
          stepInfo: stepInfo);
    });
    mappedNodes.add(node);
    return true;
  }

  // Add annotations based on trace steps.
  for (TraceStep step in graph.steps) {
    String stepInfo = '${step.id}:${step.kind}:${step.offset}';
    bool added = addSourceLocationsForNode(
        annotationType: AnnotationType.WITH_SOURCE_INFO,
        node: step.node,
        stepInfo: stepInfo);
    if (!added) {
      int offset;
      if (options.contains(Flags.useNewSourceInfo)) {
        offset = step.offset.value;
      } else {
        offset = info.jsCodePositions[step.node].startPosition;
      }
      if (offset != null) {
        addCodeLineAnnotation(
            annotationType: AnnotationType.WITHOUT_SOURCE_INFO,
            codeOffset: offset,
            stepInfo: stepInfo);
      }
    }
  }

  // Add additional annotations for mappings created for particular nodes.
  for (js.Node node in info.nodeMap.nodes) {
    if (!mappedNodes.contains(node)) {
      addSourceLocationsForNode(
          annotationType: AnnotationType.ADDITIONAL_SOURCE_INFO, node: node);
    }
  }

  // Add annotations for unused source information associated with nodes.
  SourceLocationCollector collector = new SourceLocationCollector();
  info.node.accept(collector);
  collector.sourceLocations
      .forEach((js.Node node, List<SourceLocation> locations) {
    if (!mappedNodes.contains(node)) {
      int offset = info.jsCodePositions[node].startPosition;
      addSourceLocations(
          annotationType: AnnotationType.UNUSED_SOURCE_INFO,
          codeOffset: offset,
          locations: locations);
    }
  });

  // Assign consecutive ids to source mappings.
  int nextSourceMappedLocationIndex = 0;
  List<Annotation> annotations = <Annotation>[];
  for (int codeOffset in codeLineAnnotationMap.keys.toList()..sort()) {
    bool hasSourceMappedLocation = false;
    for (CodeLineAnnotation data in codeLineAnnotationMap[codeOffset]) {
      if (data.annotationType.isSourceMapped) {
        data.sourceMappingIndex = nextSourceMappedLocationIndex;
        hasSourceMappedLocation = true;
      }
      annotations.add(new Annotation(
          data.annotationType.index, codeOffset, 'id=${data.annotationId}',
          data: data));
    }
    if (hasSourceMappedLocation) {
      nextSourceMappedLocationIndex++;
    }
  }

  // Associate JavaScript offsets with [Element]s.
  StringSourceFile sourceFile = new StringSourceFile.fromName(filename, code);
  Map<int, Element> elementMap = <int, Element>{};
  sourceMaps.elementSourceMapInfos
      .forEach((Element element, SourceMapInfo info) {
    CodePosition position = info.jsCodePositions[info.node];
    elementMap[sourceFile.getLocation(position.startPosition).line - 1] =
        element;
  });

  codeLines = convertAnnotatedCodeToCodeLines(code, annotations);
  return new CodeLinesResult(codeLines, coverage, elementMap,
      sourceMaps.sourceFileManager, codeSources);
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
    name = library.name;
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

/// Create [LineData] that colors line numbers according to the [CodeSource]s
/// origin if available.
LineData getLineData(CodeSource lineAnnotation) {
  if (lineAnnotation != null) {
    return new LineData(
        lineClass: ClassNames.line,
        lineNumberClass: '${ClassNames.lineNumber} '
            '${ClassNames.colored(lineAnnotation.hashCode % 4)}');
  }
  return new LineData(
      lineClass: ClassNames.line, lineNumberClass: ClassNames.lineNumber);
}

AnnotationData getAnnotationData(Iterable<Annotation> annotations,
    {bool forSpan}) {
  for (Annotation annotation in annotations) {
    CodeLineAnnotation data = annotation.data;
    if (data.annotationType.isSourceMapped) {
      if (forSpan) {
        int index = data.sourceMappingIndex;
        return new AnnotationData(tag: 'span', properties: {
          'class': '${ClassNames.sourceMapping} '
              '${ClassNames.sourceMappingIndex(index % HUE_COUNT)}',
          'title': 'index=$index',
        });
      } else {
        return new AnnotationData(tag: 'span', properties: {
          'title': annotation.title,
          'class': '${ClassNames.marker} '
              '${data.annotationType.className}'
        });
      }
    }
  }
  if (forSpan) return null;
  for (Annotation annotation in annotations) {
    CodeLineAnnotation data = annotation.data;
    if (data.annotationType == AnnotationType.UNUSED_SOURCE_INFO) {
      return new AnnotationData(tag: 'span', properties: {
        'title': annotation.title,
        'class': '${ClassNames.marker} '
            '${data.annotationType.className}'
      });
    }
  }
  for (Annotation annotation in annotations) {
    CodeLineAnnotation data = annotation.data;
    if (data.annotationType == AnnotationType.WITHOUT_SOURCE_INFO) {
      return new AnnotationData(tag: 'span', properties: {
        'title': annotation.title,
        'class': '${ClassNames.marker} '
            '${data.annotationType.className}'
      });
    }
  }
  return null;
}
