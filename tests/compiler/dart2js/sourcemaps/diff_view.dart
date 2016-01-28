// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.diff_view;

import 'dart:async';
import 'dart:io';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/io/position_information.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'sourcemap_helper.dart';
import 'sourcemap_html_helper.dart';
import 'trace_graph.dart';
import 'js_tracer.dart';

const String WITH_SOURCE_INFO_STYLE = 'background-color:#FF8080;';
const String WITHOUT_SOURCE_INFO_STYLE = 'border: solid 1px #FF8080;';
const String ADDITIONAL_SOURCE_INFO_STYLE = 'border: solid 1px #8080FF;';

main(List<String> args) async {
  DEBUG_MODE = true;
  String out = 'out.js.diff_view.html';
  String filename;
  List<String> currentOptions = [];
  List<List<String>> options = [currentOptions];
  int argGroup = 0;
  for (String arg in args) {
    if (arg == '--') {
      currentOptions = [];
      options.add(currentOptions);
      argGroup++;
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
  List<String> commonArguments = options[0];
  List<String> options1;
  List<String> options2;
  if (options.length == 1) {
    // Use default options; comparing SSA and CPS output using the new
    // source information strategy.
    options1 = [USE_NEW_SOURCE_INFO]..addAll(commonArguments);
    options2 = [USE_NEW_SOURCE_INFO, Flags.useCpsIr]..addAll(commonArguments);
  } else if (options.length == 2) {
    // Use alternative options for the second output column.
    options1 = commonArguments;
    options2 = options[1]..addAll(commonArguments);
  } else {
    // Use specific options for both output columns.
    options1 = options[1]..addAll(commonArguments);
    options2 = options[2]..addAll(commonArguments);
  }

  print('Compiling ${options1.join(' ')} $filename');
  CodeLinesResult result1 = await computeCodeLines(options1, filename);
  print('Compiling ${options2.join(' ')} $filename');
  CodeLinesResult result2 = await computeCodeLines(options2, filename);

  StringBuffer sb = new StringBuffer();
  sb.write('''
<html>
<head>
<title>Diff for $filename</title>
<style>
.lineNumber {
  font-size: smaller;
  color: #888;
}
.header {
  position: fixed;
  width: 50%;
  background-color: #400000;
  color: #FFFFFF;
  height: 20px;
  top: 0px;
  z-index: 1000;
}
.cell {
  max-width:500px;
  overflow-x:auto;
  vertical-align:top;
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
</style>
</head>
<body>''');

  sb.write('''
<div class="header" style="left: 0px;">[${options1.join(',')}]</div>
<div class="header" style="right: 0px;">[${options2.join(',')}]</div>
<div style="position:absolute;top:22px;width:100%;height:18px;">
  <span class="identical1">&nbsp;&nbsp;&nbsp;</span> 
  <span class="identical2">&nbsp;&nbsp;&nbsp;</span>
  identical blocks
  <span class="corresponding1">&nbsp;&nbsp;&nbsp;</span>
  <span class="corresponding2">&nbsp;&nbsp;&nbsp;</span> 
  corresponding blocks
  <span style="$WITH_SOURCE_INFO_STYLE">&nbsp;&nbsp;&nbsp;</span>
  offset with source information
  <span style="$WITHOUT_SOURCE_INFO_STYLE">&nbsp;&nbsp;&nbsp;</span>
  offset without source information
  <span style="$ADDITIONAL_SOURCE_INFO_STYLE">&nbsp;&nbsp;&nbsp;</span>
  offset with unneeded source information
</div>
<table style="position:absolute;top:40px;width:100%;"><tr>
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

  List<OutputStructure> structures = [
      OutputStructure.parse(result1.codeLines),
      OutputStructure.parse(result2.codeLines)];
  List<List<CodeLine>> inputLines = [result1.codeLines, result2.codeLines];
  List<List<HtmlPart>> outputLines = [<HtmlPart>[], <HtmlPart>[]];

  /// Marker to alternate output colors.
  bool alternating = false;

  /// Enable 'corresponding' background colors for [f].
  void withMatching(f()) {
    HtmlPart start = new ConstHtmlPart(
        '<div class="corresponding${alternating ? '1' : '2'}">');
    HtmlPart end = new ConstHtmlPart('</div>');
    alternating = !alternating;
    outputLines[0].add(start);
    outputLines[1].add(start);
    f();
    outputLines[0].add(end);
    outputLines[1].add(end);
  }

  /// Enable 'identical' background colors for [f].
  void withIdentical(f()) {
    HtmlPart start = new ConstHtmlPart(
        '<div class="identical${alternating ? '1' : '2'}">');
    HtmlPart end = new ConstHtmlPart('</div>');
    alternating = !alternating;
    outputLines[0].add(start);
    outputLines[1].add(start);
    f();
    outputLines[0].add(end);
    outputLines[1].add(end);
  }

  /// Output code lines in [range] from input number [index], padding the other
  /// column with empty lines.
  void handleSkew(int index, Interval range) {
    int from = range.from;
    while (from < range.to) {
      outputLines[1 - index].add(const ConstHtmlPart('\n'));
      outputLines[index].add(
          new CodeLineHtmlPart(inputLines[index][from++]));
    }
  }

  /// Output code lines of the [indices] from the corresponding inputs.
  void addBoth(List<int> indices) {
    outputLines[0].add(new CodeLineHtmlPart(inputLines[0][indices[0]]));
    outputLines[1].add(new CodeLineHtmlPart(inputLines[1][indices[1]]));
  }

  /// Output code lines of the [ranges] from the corresponding inputs.
  void addBothLines(List<Interval> ranges) {
    Interval range1 = ranges[0];
    Interval range2 = ranges[1];
    int offset = 0;
    while (range1.from + offset < range1.to &&
           range2.from + offset < range2.to) {
      addBoth([range1.from + offset, range2.from + offset]);
      offset++;
    }
    if (range1.from + offset < range1.to) {
      handleSkew(0, new Interval(range1.from + offset, range1.to));
    }
    if (range2.from + offset < range2.to) {
      handleSkew(1, new Interval(range2.from + offset, range2.to));
    }
  }

  /// Merge the code lines in [range1] and [range2] of the corresponding input.
  void addRaw(Interval range1, Interval range2) {
    match(a, b) => a.code == b.code;

    List<Interval> currentMatchedIntervals;

    void flushMatching() {
      if (currentMatchedIntervals != null) {
        withIdentical(() {
          addBothLines(currentMatchedIntervals);
        });
      }
      currentMatchedIntervals = null;
    }

    align(
        inputLines[0],
        inputLines[1],
        range1: range1,
        range2: range2,
        match: match,
        handleSkew: (int listIndex, Interval range) {
          flushMatching();
          handleSkew(listIndex, range);
        },
        handleMatched: (List<int> indices) {
          if (currentMatchedIntervals == null) {
            currentMatchedIntervals = [
              new Interval(indices[0], indices[0] + 1),
              new Interval(indices[1], indices[1] + 1)];
          } else {
            currentMatchedIntervals[0] =
                new Interval(currentMatchedIntervals[0].from, indices[0] + 1);
            currentMatchedIntervals[1] =
                new Interval(currentMatchedIntervals[1].from, indices[1] + 1);
          }
        },
        handleUnmatched: (List<int> indices) {
          flushMatching();
          addBoth(indices);
        });

    flushMatching();
  }

  /// Output the lines of the library blocks in [childRange] in
  /// `structures[index]`, padding the other column with empty lines.
  void addBlock(int index, Interval childRange) {
    handleSkew(index, structures[index].getChildInterval(childRange));
  }

  /// Output the members of the [classes] aligned.
  void addMatchingClasses(List<LibraryClass> classes) {
    withMatching(() {
      addBothLines(classes.map((c) => c.header).toList());
    });
    align(classes[0].children, classes[1].children,
        match: (a, b) => a.name == b.name,
        handleSkew: (int listIndex, Interval childRange) {
          handleSkew(listIndex,
              classes[listIndex].getChildInterval(childRange));
        },
        handleMatched: (List<int> indices) {
          List<Interval> intervals =  [
              classes[0].getChild(indices[0]).interval,
              classes[1].getChild(indices[1]).interval];
          withMatching(() {
            addBothLines(intervals);
          });
        },
        handleUnmatched: (List<int> indices) {
          List<Interval> intervals =  [
              classes[0].getChild(indices[0]).interval,
              classes[1].getChild(indices[1]).interval];
          addBothLines(intervals);
        });
    withMatching(() {
      addBothLines(classes.map((c) => c.footer).toList());
    });
  }

  /// Output the library blocks in [indices] from the corresponding
  /// [OutputStructure]s, aligning their content.
  void addMatchingBlocks(List<int> indices) {
    List<LibraryBlock> blocks = [
      structures[0].getChild(indices[0]),
      structures[1].getChild(indices[1])];

    withMatching(() {
      addBothLines(blocks.map((b) => b.header).toList());
    });
    align(blocks[0].children, blocks[1].children,
        match: (a, b) => a.name == b.name,
        handleSkew: (int listIndex, Interval childRange) {
          handleSkew(listIndex, blocks[listIndex].getChildInterval(childRange));
        },
        handleMatched: (List<int> indices) {
          List<BasicEntity> entities =  [
              blocks[0].getChild(indices[0]),
              blocks[1].getChild(indices[1])];
          if (entities.every((e) => e is LibraryClass)) {
            addMatchingClasses(entities);
          } else {
            withMatching(() {
              addBothLines(entities.map((e) => e.interval).toList());
            });
          }
        },
        handleUnmatched: (List<int> indices) {
          List<Interval> intervals =  [
              blocks[0].getChild(indices[0]).interval,
              blocks[1].getChild(indices[1]).interval];
          addBothLines(intervals);
        });
    withMatching(() {
      addBothLines(blocks.map((b) => b.footer).toList());
    });
  }

  /// Output the lines of the blocks in [indices] from the corresponding
  /// [OutputStructure]s.
  void addUnmatchedBlocks(List<int> indices) {
    List<LibraryBlock> blocks = [
       structures[0].getChild(indices[0]),
       structures[1].getChild(indices[1])];
    addBothLines([blocks[0].interval, blocks[1].interval]);
  }


  addRaw(structures[0].header, structures[1].header);

  align(structures[0].children,
        structures[1].children,
        match: (a, b) => a.name == b.name,
        handleSkew: addBlock,
        handleMatched: addMatchingBlocks,
        handleUnmatched: addUnmatchedBlocks);

  addRaw(structures[0].footer, structures[1].footer);

  addCell(htmlPartsToString(outputLines[0], inputLines[0]));
  addCell(htmlPartsToString(outputLines[1], inputLines[1]));

  sb.write('''</tr><tr>''');
  addCell(result1.coverage.getCoverageReport());
  addCell(result2.coverage.getCoverageReport());

  sb.write('''
</tr></table>
</body>
</html>
''');

  new File(out).writeAsStringSync(sb.toString());
  print('Diff generated in $out');
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
void align(List list1,
           List list2,
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

  Interval findInOther(
      List thisLines, Interval thisRange,
      List otherLines, Interval otherRange) {
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

// Constants used to identify the subsection of the JavaScript output. These
// are specifically for the unminified full_emitter output.
const String HEAD = '  var dart = [';
const String TAIL = '  }], ';
const String END = '  setupProgram(dart';

final RegExp TOP_LEVEL_VALUE = new RegExp(r'^    (".+?"):');
final RegExp TOP_LEVEL_FUNCTION =
    new RegExp(r'^    ([a-zA-Z0-9_$]+): \[?function');
final RegExp TOP_LEVEL_CLASS = new RegExp(r'^    ([a-zA-Z0-9_$]+): \[?\{');

final RegExp MEMBER_VALUE = new RegExp(r'^      (".+?"):');
final RegExp MEMBER_FUNCTION =
    new RegExp(r'^      ([a-zA-Z0-9_$]+): \[?function');
final RegExp MEMBER_OBJECT = new RegExp(r'^      ([a-zA-Z0-9_$]+): \[?\{');

/// Subrange of the JavaScript output.
abstract class OutputEntity {
  Interval get interval;
  Interval get header;
  Interval get footer;

  List<OutputEntity> get children;

  Interval getChildInterval(Interval childIndex) {
    return new Interval(
        children[childIndex.from].interval.from,
        children[childIndex.to - 1].interval.to);

  }

  OutputEntity getChild(int index) {
    return children[index];
  }
}

/// The whole JavaScript output.
class OutputStructure extends OutputEntity {
  final List<CodeLine> lines;
  final int headerEnd;
  final int footerStart;
  final List<LibraryBlock> children;

  OutputStructure(
      this.lines,
      this.headerEnd,
      this.footerStart,
      this.children);

  Interval get interval => new Interval(0, lines.length);

  Interval get header => new Interval(0, headerEnd);

  Interval get footer => new Interval(footerStart, lines.length);

  /// Compute the structure of the JavaScript [lines].
  static OutputStructure parse(List<CodeLine> lines) {

    int findHeaderStart(List<CodeLine> lines) {
      int index = 0;
      for (CodeLine line in lines) {
        if (line.code.startsWith(HEAD)) {
          return index;
        }
        index++;
      }
      return lines.length;
    }

    int findHeaderEnd(int start, List<CodeLine> lines) {
      int index = start;
      for (CodeLine line in lines.skip(start)) {
        if (line.code.startsWith(END)) {
          return index;
        }
        index++;
      }
      return lines.length;
    }

    String readHeader(CodeLine line) {
      String code = line.code;
      String ssaLineHeader;
      if (code.startsWith(HEAD)) {
        return code.substring(HEAD.length);
      } else if (code.startsWith(TAIL)) {
        return code.substring(TAIL.length);
      }
      return null;
    }

    List<LibraryBlock> computeHeaderMap(
        List<CodeLine> lines, int start, int end) {
      List<LibraryBlock> libraryBlocks = <LibraryBlock>[];
      LibraryBlock current;
      for (int index = start; index < end; index++) {
        String header = readHeader(lines[index]);
        if (header != null) {
          if (current != null) {
            current.to = index;
          }
          libraryBlocks.add(current = new LibraryBlock(header, index));
        }
      }
      if (current != null) {
        current.to = end;
      }
      return libraryBlocks;
    }

    int headerEnd = findHeaderStart(lines);
    int footerStart = findHeaderEnd(headerEnd, lines);
    List<LibraryBlock> libraryBlocks =
        computeHeaderMap(lines, headerEnd, footerStart);
    for (LibraryBlock block in libraryBlocks) {
      block.preprocess(lines);
    }

    return new OutputStructure(
        lines, headerEnd, footerStart, libraryBlocks);
  }
}

abstract class AbstractEntity extends OutputEntity {
  final String name;
  final int from;
  int to;

  AbstractEntity(this.name, this.from);

  Interval get interval => new Interval(from, to);
}

/// A block defining the content of a Dart library.
class LibraryBlock extends AbstractEntity {
  List<BasicEntity> children = <BasicEntity>[];
  int get headerEnd => from + 2;
  int get footerStart => to - 1;

  LibraryBlock(String name, int from) : super(name, from);

  Interval get header => new Interval(from, headerEnd);

  Interval get footer => new Interval(footerStart, to);

  void preprocess(List<CodeLine> lines) {
    int index = headerEnd;
    BasicEntity current;
    while (index < footerStart) {
      String line = lines[index].code;
      BasicEntity next;
      Match matchFunction = TOP_LEVEL_FUNCTION.firstMatch(line);
      if (matchFunction != null) {
        next = new BasicEntity(matchFunction.group(1), index);
      } else {
        Match matchClass = TOP_LEVEL_CLASS.firstMatch(line);
        if (matchClass != null) {
          next = new LibraryClass(matchClass.group(1), index);
        } else {
          Match matchValue = TOP_LEVEL_VALUE.firstMatch(line);
          if (matchValue != null) {
            next = new BasicEntity(matchValue.group(1), index);
          }
        }
      }
      if (next != null) {
        if (current != null) {
          current.to = index;
        }
        children.add(current = next);
      } else if (index == headerEnd) {
        throw 'Failed to match first library block line:\n$line';
      }

      index++;
    }
    if (current != null) {
      current.to = footerStart;
    }

    for (BasicEntity entity in children) {
      entity.preprocess(lines);
    }
  }
}

/// A simple member of a library or class.
class BasicEntity extends AbstractEntity {
  BasicEntity(String name, int from) : super(name, from);

  Interval get header => new Interval(from, to);

  Interval get footer => new Interval(to, to);

  List<OutputEntity> get children => const <OutputEntity>[];

  void preprocess(List<CodeLine> lines) {}
}

/// A block defining a Dart class.
class LibraryClass extends BasicEntity {
  List<BasicEntity> children = <BasicEntity>[];
  int get headerEnd => from + 1;
  int get footerStart => to - 1;

  LibraryClass(String name, int from) : super(name, from);

  Interval get header => new Interval(from, headerEnd);

  Interval get footer => new Interval(footerStart, to);

  void preprocess(List<CodeLine> lines) {
    int index = headerEnd;
    BasicEntity current;
    while (index < footerStart) {
      String line = lines[index].code;
      BasicEntity next;
      Match matchFunction = MEMBER_FUNCTION.firstMatch(line);
      if (matchFunction != null) {
        next = new BasicEntity(matchFunction.group(1), index);
      } else {
        Match matchClass = MEMBER_OBJECT.firstMatch(line);
        if (matchClass != null) {
          next = new BasicEntity(matchClass.group(1), index);
        } else {
          Match matchValue = MEMBER_VALUE.firstMatch(line);
          if (matchValue != null) {
            next = new BasicEntity(matchValue.group(1), index);
          }
        }
      }
      if (next != null) {
        if (current != null) {
          current.to = index;
        }
        children.add(current = next);
      } else if (index == headerEnd) {
        throw 'Failed to match first library block line:\n$line';
      }

      index++;
    }
    if (current != null) {
      current.to = footerStart;
    }
  }
}

class Interval {
  final int from;
  final int to;

  const Interval(this.from, this.to);

  int get length => to - from;
}

class HtmlPart {
  void printHtmlOn(StringBuffer buffer) {}
}

class ConstHtmlPart implements HtmlPart {
  final String html;

  const ConstHtmlPart(this.html);

  @override
  void printHtmlOn(StringBuffer buffer) {
    buffer.write(html);
  }
}

class CodeLineHtmlPart implements HtmlPart {
  final CodeLine line;

  CodeLineHtmlPart(this.line);

  @override
  void printHtmlOn(StringBuffer buffer, [int lineNoWidth]) {
    line.printHtmlOn(buffer, lineNoWidth);
  }
}

/// Convert [parts] to an HTML string while checking invariants for [lines].
String htmlPartsToString(List<HtmlPart> parts, List<CodeLine> lines) {
  int lineNoWidth;
  if (lines.isNotEmpty) {
    lineNoWidth = '${lines.last.lineNo + 1}'.length;
  }
  StringBuffer buffer = new StringBuffer();
  int expectedLineNo = 0;
  for (HtmlPart part in parts) {
    if (part is CodeLineHtmlPart) {
      if (part.line.lineNo != expectedLineNo) {
        print('Expected line no $expectedLineNo, found ${part.line.lineNo}');
        if (part.line.lineNo < expectedLineNo) {
          print('Duplicate lines:');
          int index = part.line.lineNo;
          while (index <= expectedLineNo) {
            print(lines[index++].code);
          }
        } else {
          print('Missing lines:');
          int index = expectedLineNo;
          while (index <= part.line.lineNo) {
            print(lines[index++].code);
          }
        }
        expectedLineNo = part.line.lineNo;
      }
      expectedLineNo++;
      part.printHtmlOn(buffer, lineNoWidth);
    } else {
      part.printHtmlOn(buffer);
    }
  }
  return buffer.toString();
}

class CodeLinesResult {
  final List<CodeLine> codeLines;
  final Coverage coverage;

  CodeLinesResult(this.codeLines, this.coverage);
}

/// Compute [CodeLine]s and [Coverage] for [filename] using the given [options].
Future<CodeLinesResult> computeCodeLines(
    List<String> options,
    String filename) async {
  SourceMapProcessor processor = new SourceMapProcessor(filename);
  List<SourceMapInfo> sourceMapInfoList =
      await processor.process(options, perElement: false);

  const int WITH_SOURCE_INFO = 0;
  const int WITHOUT_SOURCE_INFO = 1;
  const int ADDITIONAL_SOURCE_INFO = 2;

  for (SourceMapInfo info in sourceMapInfoList) {
    if (info.element != null) continue;

    List<CodeLine> codeLines;
    Coverage coverage = new Coverage();
    List<Annotation> annotations = <Annotation>[];
    String code = info.code;
    TraceGraph graph = createTraceGraph(info, coverage);
    Set<js.Node> mappedNodes = new Set<js.Node>();
    for (TraceStep step in graph.steps) {
      int offset;
      if (options.contains(USE_NEW_SOURCE_INFO)) {
        offset = step.offset.subexpressionOffset;
      } else {
        offset = info.jsCodePositions[step.node].startPosition;
      }
      if (offset != null) {
        int id = step.sourceLocation != null
            ? WITH_SOURCE_INFO : WITHOUT_SOURCE_INFO;
        annotations.add(
            new Annotation(id, offset, null));
      }
    }
    if (!options.contains(USE_NEW_SOURCE_INFO)) {
      for (js.Node node in info.nodeMap.nodes) {
        if (!mappedNodes.contains(node)) {
          int offset = info.jsCodePositions[node].startPosition;
          annotations.add(
                      new Annotation(ADDITIONAL_SOURCE_INFO, offset, null));
        }
      }
    }
    codeLines = convertAnnotatedCodeToCodeLines(
        code,
        annotations,
        colorScheme: new CustomColorScheme(
          single: (int id) {
            if (id == WITH_SOURCE_INFO) {
              return WITH_SOURCE_INFO_STYLE;
            } else if (id == ADDITIONAL_SOURCE_INFO) {
              return ADDITIONAL_SOURCE_INFO_STYLE;
            }
            return WITHOUT_SOURCE_INFO_STYLE;
          },
          multi: (List ids) {
            if (ids.contains(WITH_SOURCE_INFO)) {
              return WITH_SOURCE_INFO_STYLE;
            } else if (ids.contains(ADDITIONAL_SOURCE_INFO)) {
              return ADDITIONAL_SOURCE_INFO_STYLE;
            }
            return WITHOUT_SOURCE_INFO_STYLE;
          }
        ));
    return new CodeLinesResult(codeLines, coverage);
  }
}
