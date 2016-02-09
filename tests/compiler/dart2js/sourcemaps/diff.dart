// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.diff;

import 'package:compiler/src/io/source_file.dart';

import 'html_parts.dart';
import 'output_structure.dart';
import 'sourcemap_helper.dart';

enum DiffKind {
  UNMATCHED,
  MATCHING,
  IDENTICAL,
}

/// A list of columns that should align in output.
class DiffBlock {
  final DiffKind kind;
  List<List<HtmlPart>> columns = <List<HtmlPart>>[];

  DiffBlock(this.kind);

  void addColumn(int index, List<HtmlPart> lines) {
    if (index >= columns.length) {
      columns.length = index + 1;
    }
    columns[index] = lines;
  }

  List<HtmlPart> getColumn(int index) {
    List<HtmlPart> lines;
    if (index < columns.length) {
      lines = columns[index];
    }
    return lines != null ? lines : const <HtmlPart>[];
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

/// Create a list of blocks containing the diff of the two output [structures]
/// and the corresponding Dart code.
List<DiffBlock> createDiffBlocks(
    List<OutputStructure> structures,
    SourceFileManager sourceFileManager) {
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

  CodeSource codeSourceFromEntities(Iterable<OutputEntity> entities) {
    for (OutputEntity entity in entities) {
      if (entity.codeSource != null) {
        return entity.codeSource;
      }
    }
    return null;
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
  void handleSkew(int index, Interval range, [CodeSource codeSource]) {
    DiffBlock block = new DiffBlock(DiffKind.UNMATCHED);
    checkLineInvariant(index, range);
    block.addColumn(index, inputLines[index].sublist(range.from, range.to));
    if (codeSource != null) {
      block.addColumn(2,
          codeLinesFromCodeSource(sourceFileManager, codeSource));
    }
    blocks.add(block);
  }

  /// Create a block containing the code lines in [ranges] from the
  /// corresponding JavaScript inputs. If [codeSource] is provided, the block
  /// will contain a corresponding Dart code column.
  void addLines(DiffKind kind, List<Interval> ranges, [CodeSource codeSource]) {
    DiffBlock block = new DiffBlock(kind);
    for (int i = 0; i < ranges.length; i++) {
      checkLineInvariant(i, ranges[i]);
      block.addColumn(i, inputLines[i].sublist(ranges[i].from, ranges[i].to));
    }
    if (codeSource != null) {
      block.addColumn(2,
          codeLinesFromCodeSource(sourceFileManager, codeSource));
    }
    blocks.add(block);
  }

  /// Merge the code lines in [range1] and [range2] of the corresponding input.
  void addRaw(Interval range1, Interval range2) {
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
          new Interval(indices[1], indices[1] + 1)];
      } else {
        current[0] =
            new Interval(current[0].from, indices[0] + 1);
        current[1] =
            new Interval(current[1].from, indices[1] + 1);
        return current;
      }
    }

    align(
        inputLines[0],
        inputLines[1],
        range1: range1,
        range2: range2,
        match: match,
        handleSkew: (int listIndex, Interval range) {
          flushMatching();
          flushUnmatched();
          handleSkew(listIndex, range);
        },
        handleMatched: (List<int> indices) {
          flushUnmatched();
          currentMatchedIntervals =
              updateIntervals(currentMatchedIntervals, indices);
        },
        handleUnmatched: (List<int> indices) {
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
      addSkewedChildren(
          index, entity, new Interval(0, entity.children.length));
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
          List<BasicEntity> entities =  [
              classes[0].getChild(indices[0]),
              classes[1].getChild(indices[1])];
          if (entities.every((e) => e is Statics)) {
            addMatchingContainers(entities);
          } else {
            addLines(DiffKind.MATCHING,
                     entities.map((e) => e.interval).toList(),
                     codeSourceFromEntities(entities));
          }
        },
        handleUnmatched: (List<int> indices) {
          List<Interval> intervals =  [
              classes[0].getChild(indices[0]).interval,
              classes[1].getChild(indices[1]).interval];
          addLines(DiffKind.UNMATCHED, intervals);
        });
    addLines(DiffKind.MATCHING, classes.map((c) => c.footer).toList());
  }

  /// Adds the library blocks in [indices] from the corresponding
  /// [OutputStructure]s, aligning their content.
  void addMatchingBlocks(List<int> indices) {
    List<LibraryBlock> blocks = [
      structures[0].getChild(indices[0]),
      structures[1].getChild(indices[1])];

    addLines(DiffKind.MATCHING, blocks.map((b) => b.header).toList());
    align(blocks[0].children, blocks[1].children,
        match: (a, b) => a.name == b.name,
        handleSkew: (int listIndex, Interval childRange) {
          addSkewedChildren(
              listIndex, blocks[listIndex], childRange);
        },
        handleMatched: (List<int> indices) {
          List<BasicEntity> entities =  [
              blocks[0].getChild(indices[0]),
              blocks[1].getChild(indices[1])];
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
          List<Interval> intervals =  [
              blocks[0].getChild(indices[0]).interval,
              blocks[1].getChild(indices[1]).interval];
          addLines(DiffKind.UNMATCHED, intervals);
        });
    addLines(DiffKind.MATCHING, blocks.map((b) => b.footer).toList());
  }

  /// Adds the lines of the blocks in [indices] from the corresponding
  /// [OutputStructure]s.
  void addUnmatchedBlocks(List<int> indices) {
    List<LibraryBlock> blocks = [
       structures[0].getChild(indices[0]),
       structures[1].getChild(indices[1])];
    addLines(DiffKind.UNMATCHED, [blocks[0].interval, blocks[1].interval]);
  }

  /// Computes the diff blocks for [OutputStructure]s.
  List<DiffBlock> computeBlocks() {
    addRaw(structures[0].header, structures[1].header);

    align(structures[0].children,
          structures[1].children,
          match: (a, b) => a.name == b.name,
          handleSkew: addBlock,
          handleMatched: addMatchingBlocks,
          handleUnmatched: addUnmatchedBlocks);

    addRaw(structures[0].footer, structures[1].footer);

    return blocks;
  }
}

/// Creates html lines for code lines in [codeSource]. [sourceFileManager] is
/// used to read that text from the source URIs.
List<HtmlPart> codeLinesFromCodeSource(
    SourceFileManager sourceFileManager,
    CodeSource codeSource) {
  List<HtmlPart> lines = <HtmlPart>[];
  SourceFile sourceFile = sourceFileManager.getSourceFile(codeSource.uri);
  String elementName = codeSource.name;
  HtmlLine line = new HtmlLine();
  line.htmlParts.add(new ConstHtmlPart('<span class="comment">'));
  line.htmlParts.add(new HtmlText(
      '${elementName}: ${sourceFile.filename}'));
  line.htmlParts.add(new ConstHtmlPart('</span>'));
  lines.add(line);
  if (codeSource.begin != null) {
    int startLine = sourceFile.getLine(codeSource.begin);
    int endLine = sourceFile.getLine(codeSource.end);
    for (int lineNo = startLine; lineNo <= endLine; lineNo++) {
      String text = sourceFile.getLineText(lineNo);
      CodeLine codeLine = new CodeLine(lineNo, sourceFile.getOffset(lineNo, 0));
      codeLine.codeBuffer.write(text);
      codeLine.htmlParts.add(new HtmlText(text));
      lines.add(codeLine);
    }
  }
  return lines;
}
