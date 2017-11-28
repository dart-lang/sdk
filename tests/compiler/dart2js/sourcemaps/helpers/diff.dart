// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.diff;

import 'package:compiler/src/io/source_file.dart';

import 'html_parts.dart';
import 'output_structure.dart';
import 'sourcemap_helper.dart';
import 'sourcemap_html_helper.dart';

enum DiffKind {
  UNMATCHED,
  MATCHING,
  IDENTICAL,
}

/// Id for an output column.
class DiffColumn {
  final String type;
  final int index;

  const DiffColumn(this.type, [this.index]);

  int get hashCode => type.hashCode * 19 + index.hashCode * 23;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! DiffColumn) return false;
    return type == other.type && index == other.index;
  }

  String toString() => '$type${index != null ? index : ''}';
}

/// A block of code in an output column.
abstract class DiffColumnBlock {
  void printHtmlOn(StringBuffer htmlBuffer, HtmlPrintContext context);
}

/// A block consisting of pure HTML parts.
class PartsColumnBlock extends DiffColumnBlock {
  final List<HtmlPart> parts;

  PartsColumnBlock(this.parts);

  void printHtmlOn(StringBuffer htmlBuffer, HtmlPrintContext context) {
    if (parts.isNotEmpty) {
      for (HtmlPart part in parts) {
        part.printHtmlOn(htmlBuffer, context);
      }
    }
  }
}

/// A block consisting of line-per-line JavaScript and source mapped Dart code.
class CodeLinesColumnBlock extends DiffColumnBlock {
  final List<CodeLine> jsCodeLines;
  final Map<CodeLine, List<CodeLine>> jsToDartMap;

  CodeLinesColumnBlock(this.jsCodeLines, this.jsToDartMap);

  void printHtmlOn(StringBuffer htmlBuffer, HtmlPrintContext context) {
    if (jsCodeLines.isNotEmpty) {
      htmlBuffer.write('<table style="width:100%">');
      for (CodeLine codeLine in jsCodeLines) {
        htmlBuffer.write('<tr><td class="${ClassNames.innerCell}">');
        codeLine.printHtmlOn(htmlBuffer, context);
        htmlBuffer.write('</td><td '
            'class="${ClassNames.innerCell} ${ClassNames.sourceMapped}">');
        List<CodeLine> lines = jsToDartMap[codeLine];
        if (lines != null) {
          for (CodeLine line in lines) {
            line.printHtmlOn(htmlBuffer, context.from(includeAnnotation: (a) {
              CodeLineAnnotation annotation = a.data;
              return annotation.annotationType.isSourceMapped;
            }));
          }
        }
        htmlBuffer.write('</td></tr>');
      }
      htmlBuffer.write('</table>');
    }
  }
}

/// A list of columns that should align in output.
class DiffBlock {
  final DiffKind kind;
  Map<DiffColumn, DiffColumnBlock> _columns = <DiffColumn, DiffColumnBlock>{};

  DiffBlock(this.kind);

  void addColumnBlock(DiffColumn column, DiffColumnBlock block) {
    _columns[column] = block;
  }

  Iterable<DiffColumn> get columns => _columns.keys;

  void printHtmlOn(
      DiffColumn column, StringBuffer htmlBuffer, HtmlPrintContext context) {
    DiffColumnBlock block = _columns[column];
    if (block != null) {
      block.printHtmlOn(htmlBuffer, context);
    }
  }
}

/// Align the content of [list1] and [list2].
///
/// If provided, [range1] and [range2] aligned the subranges of [list1] and
/// [list2], otherwise the whole lists are aligned.
///
/// If provided, [match] determines the equality between members of [list1] and
/// [list2], otherwise `==` is used.
///
/// [handleSkew] is called when a subrange of one list is not found in the
/// other.
///
/// [handleMatched] is called when two indices match up.
///
/// [handleUnmatched] is called when two indices don't match up (none are found
/// in the other list).
void align(List list1, List list2,
    {Interval range1,
    Interval range2,
    bool match(a, b),
    void handleSkew(int listIndex, Interval range),
    void handleMatched(List<int> indices),
    void handleUnmatched(List<int> indices)}) {
  if (match == null) {
    match = (a, b) => a == b;
  }

  if (range1 == null) {
    range1 = new Interval(0, list1.length);
  }
  if (range2 == null) {
    range2 = new Interval(0, list2.length);
  }

  Interval findInOther(List thisLines, Interval thisRange, List otherLines,
      Interval otherRange) {
    for (int index = otherRange.from; index < otherRange.to; index++) {
      if (match(thisLines[thisRange.from], otherLines[index])) {
        int offset = 1;
        while (thisRange.from + offset < thisRange.to &&
            otherRange.from + offset < otherRange.to &&
            match(thisLines[thisRange.from + offset],
                otherLines[otherRange.from + offset])) {
          offset++;
        }
        return new Interval(index, index + offset);
      }
    }
    return null;
  }

  int start1 = range1.from;
  int end1 = range1.to;
  int start2 = range2.from;
  int end2 = range2.to;

  const int ALIGN1 = -1;
  const int UNMATCHED = 0;
  const int ALIGN2 = 1;

  while (start1 < end1 && start2 < end2) {
    if (match(list1[start1], list2[start2])) {
      handleMatched([start1++, start2++]);
    } else {
      Interval subrange1 = new Interval(start1, end1);
      Interval subrange2 = new Interval(start2, end2);
      Interval element2inList1 =
          findInOther(list1, subrange1, list2, subrange2);
      Interval element1inList2 =
          findInOther(list2, subrange2, list1, subrange1);
      int choice = 0;
      if (element2inList1 != null) {
        if (element1inList2 != null) {
          if (element1inList2.length > 1 && element2inList1.length > 1) {
            choice =
                element2inList1.from < element1inList2.from ? ALIGN2 : ALIGN1;
          } else if (element2inList1.length > 1) {
            choice = ALIGN2;
          } else if (element1inList2.length > 1) {
            choice = ALIGN1;
          } else {
            choice =
                element2inList1.from < element1inList2.from ? ALIGN2 : ALIGN1;
          }
        } else {
          choice = ALIGN2;
        }
      } else if (element1inList2 != null) {
        choice = ALIGN1;
      }
      switch (choice) {
        case ALIGN1:
          handleSkew(0, new Interval(start1, element1inList2.from));
          start1 = element1inList2.from;
          break;
        case ALIGN2:
          handleSkew(1, new Interval(start2, element2inList1.from));
          start2 = element2inList1.from;
          break;
        case UNMATCHED:
          handleUnmatched([start1++, start2++]);
          break;
      }
    }
  }
  if (start1 < end1) {
    handleSkew(0, new Interval(start1, end1));
  }
  if (start2 < end2) {
    handleSkew(1, new Interval(start2, end2));
  }
}

/// Create a list of blocks containing the diff of the two output [structures]
/// and the corresponding Dart code.
List<DiffBlock> createDiffBlocks(
    List<OutputStructure> structures, SourceFileManager sourceFileManager) {
  return new DiffCreator(structures, sourceFileManager).computeBlocks();
}

class DiffCreator {
  final List<OutputStructure> structures;
  final SourceFileManager sourceFileManager;

  List<List<CodeLine>> inputLines;

  List<int> nextInputLine = [0, 0];

  List<DiffBlock> blocks = <DiffBlock>[];

  DiffCreator(List<OutputStructure> structures, this.sourceFileManager)
      : this.structures = structures,
        this.inputLines = structures.map((s) => s.lines).toList();

  /// Compute [CodeSource]s defined by [entities].
  Iterable<CodeSource> codeSourceFromEntities(Iterable<OutputEntity> entities) {
    Set<CodeSource> sources = new Set<CodeSource>();
    for (OutputEntity entity in entities) {
      if (entity.codeSource != null) {
        sources.add(entity.codeSource);
      }
    }
    return sources;
  }

  /// Create a block with the code from [codeSources]. The [CodeSource]s in
  /// [mainSources] are tagged as original code sources, the rest as inlined
  /// code sources.
  DiffColumnBlock codeLinesFromCodeSources(
      Iterable<CodeSource> mainSources, Iterable<CodeSource> codeSources) {
    List<HtmlPart> parts = <HtmlPart>[];
    for (CodeSource codeSource in codeSources) {
      //parts.addAll(codeLinesFromCodeSource(codeSource));
      String className = mainSources.contains(codeSource)
          ? ClassNames.originalDart
          : ClassNames.inlinedDart;
      parts.add(new TagPart('div',
          properties: {'class': className},
          content: codeLinesFromCodeSource(codeSource)));
    }
    return new PartsColumnBlock(parts);
  }

  /// Adds all [CodeSource]s used in [dartCodeLines] to [codeSourceSet].
  void collectCodeSources(Set<CodeSource> codeSourceSet,
      Map<CodeLine, List<CodeLine>> dartCodeLines) {
    for (List<CodeLine> codeLines in dartCodeLines.values) {
      for (CodeLine dartCodeLine in codeLines) {
        if (dartCodeLine.lineAnnotation != null) {
          codeSourceSet.add(dartCodeLine.lineAnnotation);
        }
      }
    }
  }

  /// Checks that lines are added in sequence without gaps or duplicates.
  void checkLineInvariant(int index, Interval range) {
    int expectedLineNo = nextInputLine[index];
    if (range.from != expectedLineNo) {
      print('Expected line no $expectedLineNo, found ${range.from}');
      if (range.from < expectedLineNo) {
        print('Duplicate lines:');
        int i = range.from;
        while (i <= expectedLineNo) {
          print(inputLines[index][i++].code);
        }
      } else {
        print('Missing lines:');
        int i = expectedLineNo;
        while (i <= range.from) {
          print(inputLines[index][i++].code);
        }
      }
    }
    nextInputLine[index] = range.to;
  }

  /// Creates a block containing the code lines in [range] from input number
  /// [index]. If [codeSource] is provided, the block will contain a
  /// corresponding Dart code column.
  void handleSkew(int index, Interval range,
      [Iterable<CodeSource> mainCodeSources = const <CodeSource>[]]) {
    if (range.isEmpty) return;

    Set<CodeSource> codeSources = new Set<CodeSource>();
    codeSources.addAll(mainCodeSources);

    DiffBlock block = new DiffBlock(DiffKind.UNMATCHED);
    checkLineInvariant(index, range);
    List<CodeLine> jsCodeLines =
        inputLines[index].sublist(range.from, range.to);
    Map<CodeLine, List<CodeLine>> dartCodeLines =
        dartCodeLinesFromJsCodeLines(jsCodeLines);
    block.addColumnBlock(new DiffColumn('js', index),
        new CodeLinesColumnBlock(jsCodeLines, dartCodeLines));
    collectCodeSources(codeSources, dartCodeLines);

    if (codeSources.isNotEmpty) {
      block.addColumnBlock(const DiffColumn('dart'),
          codeLinesFromCodeSources(mainCodeSources, codeSources));
    }
    blocks.add(block);
  }

  /// Create a block containing the code lines in [ranges] from the
  /// corresponding JavaScript inputs. If [codeSource] is provided, the block
  /// will contain a corresponding Dart code column.
  void addLines(DiffKind kind, List<Interval> ranges,
      [Iterable<CodeSource> mainCodeSources = const <CodeSource>[]]) {
    if (ranges.every((range) => range.isEmpty)) return;

    Set<CodeSource> codeSources = new Set<CodeSource>();
    codeSources.addAll(mainCodeSources);

    DiffBlock block = new DiffBlock(kind);
    for (int i = 0; i < ranges.length; i++) {
      checkLineInvariant(i, ranges[i]);
      List<CodeLine> jsCodeLines =
          inputLines[i].sublist(ranges[i].from, ranges[i].to);
      Map<CodeLine, List<CodeLine>> dartCodeLines =
          dartCodeLinesFromJsCodeLines(jsCodeLines);
      block.addColumnBlock(new DiffColumn('js', i),
          new CodeLinesColumnBlock(jsCodeLines, dartCodeLines));
      collectCodeSources(codeSources, dartCodeLines);
    }
    if (codeSources.isNotEmpty) {
      block.addColumnBlock(const DiffColumn('dart'),
          codeLinesFromCodeSources(mainCodeSources, codeSources));
    }
    blocks.add(block);
  }

  /// Merge the code lines in [range1] and [range2] of the corresponding input.
  void addRaw(Interval range1, Interval range2) {
    if (range1.isEmpty && range2.isEmpty) return;

    match(a, b) => a.code == b.code;

    List<Interval> currentMatchedIntervals;
    List<Interval> currentUnmatchedIntervals;

    void flushMatching() {
      if (currentMatchedIntervals != null) {
        addLines(DiffKind.IDENTICAL, currentMatchedIntervals);
      }
      currentMatchedIntervals = null;
    }

    void flushUnmatched() {
      if (currentUnmatchedIntervals != null) {
        addLines(DiffKind.UNMATCHED, currentUnmatchedIntervals);
      }
      currentUnmatchedIntervals = null;
    }

    List<Interval> updateIntervals(List<Interval> current, List<int> indices) {
      if (current == null) {
        return [
          new Interval(indices[0], indices[0] + 1),
          new Interval(indices[1], indices[1] + 1)
        ];
      } else {
        current[0] = new Interval(current[0].from, indices[0] + 1);
        current[1] = new Interval(current[1].from, indices[1] + 1);
        return current;
      }
    }

    align(inputLines[0], inputLines[1],
        range1: range1,
        range2: range2,
        match: match, handleSkew: (int listIndex, Interval range) {
      flushMatching();
      flushUnmatched();
      handleSkew(listIndex, range);
    }, handleMatched: (List<int> indices) {
      flushUnmatched();
      currentMatchedIntervals =
          updateIntervals(currentMatchedIntervals, indices);
    }, handleUnmatched: (List<int> indices) {
      flushMatching();
      currentUnmatchedIntervals =
          updateIntervals(currentUnmatchedIntervals, indices);
    });

    flushMatching();
    flushUnmatched();
  }

  /// Adds the top level blocks in [childRange] for structure [index].
  void addBlock(int index, Interval childRange) {
    addSkewedChildren(index, structures[index], childRange);
  }

  /// Adds the [entity] from structure [index]. If the [entity] supports child
  /// entities, these are process individually. Otherwise the lines from
  /// [entity] are added directly.
  void addSkewedEntity(int index, OutputEntity entity) {
    if (entity.canHaveChildren) {
      handleSkew(index, entity.header);
      addSkewedChildren(index, entity, new Interval(0, entity.children.length));
      handleSkew(index, entity.footer);
    } else {
      handleSkew(index, entity.interval, codeSourceFromEntities([entity]));
    }
  }

  /// Adds the children of [parent] in [childRange] from structure [index].
  void addSkewedChildren(int index, OutputEntity parent, Interval childRange) {
    for (int i = childRange.from; i < childRange.to; i++) {
      addSkewedEntity(index, parent.getChild(i));
    }
  }

  /// Adds the members of the [classes] aligned.
  void addMatchingContainers(List<OutputEntity> classes) {
    addLines(DiffKind.MATCHING, classes.map((c) => c.header).toList());
    align(classes[0].children, classes[1].children,
        match: (a, b) => a.name == b.name,
        handleSkew: (int listIndex, Interval childRange) {
          addSkewedChildren(listIndex, classes[listIndex], childRange);
        },
        handleMatched: (List<int> indices) {
          List<BasicEntity> entities = [
            classes[0].getChild(indices[0]),
            classes[1].getChild(indices[1])
          ];
          if (entities.every((e) => e is Statics)) {
            addMatchingContainers(entities);
          } else {
            addLines(
                DiffKind.MATCHING,
                entities.map((e) => e.interval).toList(),
                codeSourceFromEntities(entities));
          }
        },
        handleUnmatched: (List<int> indices) {
          List<Interval> intervals = [
            classes[0].getChild(indices[0]).interval,
            classes[1].getChild(indices[1]).interval
          ];
          addLines(DiffKind.UNMATCHED, intervals);
        });
    addLines(DiffKind.MATCHING, classes.map((c) => c.footer).toList());
  }

  /// Adds the library blocks in [indices] from the corresponding
  /// [OutputStructure]s, aligning their content.
  void addMatchingBlocks(List<int> indices) {
    List<LibraryBlock> blocks = [
      structures[0].getChild(indices[0]),
      structures[1].getChild(indices[1])
    ];

    addLines(DiffKind.MATCHING, blocks.map((b) => b.header).toList());
    align(blocks[0].children, blocks[1].children,
        match: (a, b) => a.name == b.name,
        handleSkew: (int listIndex, Interval childRange) {
          addSkewedChildren(listIndex, blocks[listIndex], childRange);
        },
        handleMatched: (List<int> indices) {
          List<BasicEntity> entities = [
            blocks[0].getChild(indices[0]),
            blocks[1].getChild(indices[1])
          ];
          if (entities.every((e) => e is LibraryClass)) {
            addMatchingContainers(entities);
          } else {
            addLines(
                DiffKind.MATCHING,
                entities.map((e) => e.interval).toList(),
                codeSourceFromEntities(entities));
          }
        },
        handleUnmatched: (List<int> indices) {
          List<Interval> intervals = [
            blocks[0].getChild(indices[0]).interval,
            blocks[1].getChild(indices[1]).interval
          ];
          addLines(DiffKind.UNMATCHED, intervals);
        });
    addLines(DiffKind.MATCHING, blocks.map((b) => b.footer).toList());
  }

  /// Adds the lines of the blocks in [indices] from the corresponding
  /// [OutputStructure]s.
  void addUnmatchedBlocks(List<int> indices) {
    List<LibraryBlock> blocks = [
      structures[0].getChild(indices[0]),
      structures[1].getChild(indices[1])
    ];
    addLines(DiffKind.UNMATCHED, [blocks[0].interval, blocks[1].interval]);
  }

  /// Computes the diff blocks for [OutputStructure]s.
  List<DiffBlock> computeBlocks() {
    addRaw(structures[0].header, structures[1].header);

    align(structures[0].children, structures[1].children,
        match: (a, b) => a.name == b.name,
        handleSkew: addBlock,
        handleMatched: addMatchingBlocks,
        handleUnmatched: addUnmatchedBlocks);

    addRaw(structures[0].footer, structures[1].footer);

    return blocks;
  }

  /// Creates html lines for code lines in [codeSource]. The [sourceFileManager]
  /// is used to read that text from the source URIs.
  List<HtmlPart> codeLinesFromCodeSource(CodeSource codeSource) {
    List<HtmlPart> lines = <HtmlPart>[];
    SourceFile sourceFile = sourceFileManager.getSourceFile(codeSource.uri);
    String elementName = codeSource.name;
    HtmlLine line = new HtmlLine();
    line.htmlParts.add(new ConstHtmlPart('<span class="comment">'));
    line.htmlParts.add(new HtmlText('${elementName}: ${sourceFile.filename}'));
    line.htmlParts.add(new ConstHtmlPart('</span>'));
    lines.add(line);
    if (codeSource.begin != null) {
      int startLine = sourceFile.getLocation(codeSource.begin).line - 1;
      int endLine = sourceFile.getLocation(codeSource.end).line;
      for (CodeLine codeLine in convertAnnotatedCodeToCodeLines(
          sourceFile.slowText(), const <Annotation>[],
          startLine: startLine, endLine: endLine)) {
        codeLine.lineAnnotation = codeSource;
        lines.add(codeLine);
      }
    }
    return lines;
  }

  /// Creates a map from JavaScript [CodeLine]s in [jsCodeLines] to the Dart
  /// [CodeLine]s references in the source information.
  Map<CodeLine, List<CodeLine>> dartCodeLinesFromJsCodeLines(
      List<CodeLine> jsCodeLines) {
    Map<CodeLine, Interval> codeLineInterval = <CodeLine, Interval>{};
    Map<CodeLine, List<CodeLine>> jsToDartMap = <CodeLine, List<CodeLine>>{};
    List<Annotation> annotations = <Annotation>[];
    Uri currentUri;
    Interval interval;

    Map<Uri, Set<CodeSource>> codeSourceMap = <Uri, Set<CodeSource>>{};

    for (CodeLine jsCodeLine in jsCodeLines) {
      for (Annotation annotation in jsCodeLine.annotations) {
        CodeLineAnnotation codeLineAnnotation = annotation.data;
        for (CodeSource codeSource in codeLineAnnotation.codeSources) {
          codeSourceMap
              .putIfAbsent(codeSource.uri, () => new Set<CodeSource>())
              .add(codeSource);
        }
      }
    }

    void flush() {
      if (currentUri == null) return;

      Set<CodeSource> codeSources = codeSourceMap[currentUri];
      SourceFile sourceFile = sourceFileManager.getSourceFile(currentUri);
      List<CodeLine> annotatedDartCodeLines = convertAnnotatedCodeToCodeLines(
          sourceFile.slowText(), annotations,
          startLine: interval.from, endLine: interval.to, uri: currentUri);
      if (codeSources != null) {
        CodeSource currentCodeSource;
        Interval currentLineInterval;
        for (CodeLine dartCodeLine in annotatedDartCodeLines) {
          if (currentCodeSource == null ||
              !currentLineInterval.contains(dartCodeLine.lineNo)) {
            currentCodeSource = null;
            for (CodeSource codeSource in codeSources) {
              Interval interval = new Interval(
                  sourceFile.getLocation(codeSource.begin).line - 1,
                  sourceFile.getLocation(codeSource.end).line);
              if (interval.contains(dartCodeLine.lineNo)) {
                currentCodeSource = codeSource;
                currentLineInterval = interval;
                break;
              }
            }
          }
          if (currentCodeSource != null) {
            dartCodeLine.lineAnnotation = currentCodeSource;
          }
        }
      }

      int index = 0;
      for (CodeLine jsCodeLine in codeLineInterval.keys) {
        List<CodeLine> dartCodeLines =
            jsToDartMap.putIfAbsent(jsCodeLine, () => <CodeLine>[]);
        if (dartCodeLines.isEmpty && index < annotatedDartCodeLines.length) {
          dartCodeLines.add(annotatedDartCodeLines[index++]);
        }
      }
      while (index < annotatedDartCodeLines.length) {
        jsToDartMap[codeLineInterval.keys.last]
            .add(annotatedDartCodeLines[index++]);
      }

      currentUri = null;
    }

    void restart(CodeLine codeLine, CodeLocation codeLocation, int line) {
      flush();

      currentUri = codeLocation.uri;
      interval = new Interval(line, line + 1);
      annotations = <Annotation>[];
      codeLineInterval.clear();
      codeLineInterval[codeLine] = interval;
    }

    for (CodeLine jsCodeLine in jsCodeLines) {
      for (Annotation annotation in jsCodeLine.annotations) {
        CodeLineAnnotation codeLineAnnotation = annotation.data;

        for (CodeLocation location in codeLineAnnotation.codeLocations) {
          SourceFile sourceFile = sourceFileManager.getSourceFile(location.uri);
          int line = sourceFile.getLocation(location.offset).line - 1;
          if (currentUri != location.uri) {
            restart(jsCodeLine, location, line);
          } else if (interval.inWindow(line, windowSize: 2)) {
            interval = interval.include(line);
            codeLineInterval[jsCodeLine] = interval;
          } else {
            restart(jsCodeLine, location, line);
          }

          annotations.add(new Annotation(codeLineAnnotation.annotationType,
              location.offset, 'id=${codeLineAnnotation.annotationId}',
              data: codeLineAnnotation));
        }
      }
    }
    flush();
    return jsToDartMap;
  }
}

const DiffColumn column_js0 = const DiffColumn('js', 0);
const DiffColumn column_js1 = const DiffColumn('js', 1);
const DiffColumn column_dart = const DiffColumn('dart');

class ClassNames {
  static String column(DiffColumn column) => 'column_${column}';
  static String identical(bool alternate) =>
      'identical${alternate ? '1' : '2'}';
  static String corresponding(bool alternate) =>
      'corresponding${alternate ? '1' : '2'}';

  static const String buttons = 'buttons';
  static const String comment = 'comment';
  static const String header = 'header';
  static const String headerTable = 'header_table';
  static const String headerColumn = 'header_column';
  static const String legend = 'legend';
  static const String table = 'table';

  static const String cell = 'cell';
  static const String innerCell = 'inner_cell';

  static const String originalDart = 'main_dart';
  static const String inlinedDart = 'inlined_dart';

  static const String line = 'line';
  static const String lineNumber = 'line_number';
  static String colored(int index) => 'colored${index}';

  static const String withSourceInfo = 'with_source_info';
  static const String withoutSourceInfo = 'without_source_info';
  static const String additionalSourceInfo = 'additional_source_info';
  static const String unusedSourceInfo = 'unused_source_info';

  static const String sourceMapped = 'source_mapped';
  static const String sourceMapping = 'source_mapping';
  static String sourceMappingIndex(int index) => 'source_mapping${index}';

  static const String markers = 'markers';
  static const String marker = 'marker';
}

class AnnotationType {
  static const WITH_SOURCE_INFO =
      const AnnotationType(0, ClassNames.withSourceInfo, true);
  static const WITHOUT_SOURCE_INFO =
      const AnnotationType(1, ClassNames.withoutSourceInfo, false);
  static const ADDITIONAL_SOURCE_INFO =
      const AnnotationType(2, ClassNames.additionalSourceInfo, true);
  static const UNUSED_SOURCE_INFO =
      const AnnotationType(3, ClassNames.unusedSourceInfo, false);

  final int index;
  final String className;
  final bool isSourceMapped;

  const AnnotationType(this.index, this.className, this.isSourceMapped);

  static const List<AnnotationType> values = const <AnnotationType>[
    WITH_SOURCE_INFO,
    WITHOUT_SOURCE_INFO,
    ADDITIONAL_SOURCE_INFO,
    UNUSED_SOURCE_INFO
  ];
}

class CodeLineAnnotation {
  final int annotationId;
  final AnnotationType annotationType;
  final List<CodeLocation> codeLocations;
  final List<CodeSource> codeSources;
  final String stepInfo;
  int sourceMappingIndex;

  CodeLineAnnotation(
      {this.annotationId,
      this.annotationType,
      this.codeLocations,
      this.codeSources,
      this.stepInfo,
      this.sourceMappingIndex});

  Map toJson(JsonStrategy strategy) {
    return {
      'annotationId': annotationId,
      'annotationType': annotationType.index,
      'codeLocations': codeLocations.map((l) => l.toJson(strategy)).toList(),
      'codeSources': codeSources.map((c) => c.toJson()).toList(),
      'stepInfo': stepInfo,
      'sourceMappingIndex': sourceMappingIndex,
    };
  }

  static fromJson(Map json, JsonStrategy strategy) {
    return new CodeLineAnnotation(
        annotationId: json['id'],
        annotationType: AnnotationType.values[json['annotationType']],
        codeLocations: json['codeLocations']
            .map((j) => CodeLocation.fromJson(j, strategy))
            .toList(),
        codeSources:
            json['codeSources'].map((j) => CodeSource.fromJson(j)).toList(),
        stepInfo: json['stepInfo'],
        sourceMappingIndex: json['sourceMappingIndex']);
  }
}
