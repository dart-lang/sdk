#!/usr/bin/env dart
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// ----------------------------------------------------------------------
// This is a very specialized tool which was created in order to support
// adding hash values used as location markers in the LaTeX source of the
// language specification.  It is intended to take its input file as the
// first argument, an output file name as the second argument, and a
// hash listing file name as the third argument. From docs/language a
// typical usage would be as follows:
//
// dart ../../tools/addlatexhash.dart dartLangSpec.tex out.tex hash.txt
//
// This will produce a normalized variant out.tex of the language
// specification with hash values filled in, and a listing hash.txt of
// all the hash values along with the label of their textual context
// (section, subsection, subsubsection, paragraph) .  For more details,
// please check the language specification source itself.
//
// NB: This utility assumes UN*X style line endings, \n, in the LaTeX
// source file received as input; it will not work with other styles.

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:utf/utf.dart';

// ----------------------------------------------------------------------
// Normalization of the text: removal or normalization of parts that
// do not affect the output from latex, such as white space.

final commentRE = new RegExp(r"[^\\]%.*"); // NB: . does not match \n.
final whitespaceAllRE = new RegExp(r"^\s+$");
final whitespaceRE = new RegExp(r"(?:(?=\s).){2,}"); // \s except end-of-line

/// Removes [match]ing part of [line], adjusting that part with the
/// given [startOffset] and [endOffset], bounded to be valid indices
/// into the string if needed, then inserts [glue] where text was
/// removed.  If there is no match then [line] is returned.
cutMatch(line, match, {startOffset: 0, endOffset: 0, glue: ""}) {
  if (match == null) return line;
  var start = match.start + startOffset;
  var end = match.end + endOffset;
  var len = line.length;
  if (start < 0) start = 0;
  if (end > len) end = len;
  return line.substring(0, start) + glue + line.substring(end);
}

cutRegexp(line, re, {startOffset: 0, endOffset: 0, glue: ""}) {
  return cutMatch(line, re.firstMatch(line),
      startOffset: startOffset, endOffset: endOffset, glue: glue);
}

/// Removes the rest of [line] starting from the beginning of the
/// given [match], and adjusting with the given [offset].  If there
/// is no match then [line] is returned.
cutFromMatch(line, match, {offset: 0, glue: ""}) {
  if (match == null) return line;
  return line.substring(0, match.start + offset) + glue;
}

cutFromRegexp(line, re, {offset: 0, glue: ""}) {
  return cutFromMatch(line, re.firstMatch(line), offset: offset, glue: glue);
}

isWsOnly(line) => line.contains(whitespaceAllRE);
isCommentOnly(line) => line.startsWith("%");

/// Returns the end-of-line character at the end of [line], if any,
/// otherwise returns the empty string.
justEol(line) {
  return line.endsWith("\n") ? "\n" : "";
}

/// Removes the contents of the comment at the end of [line],
/// leaving the "%" in place.  If no comment is present,
/// return [line].
///
/// NB: it is tempting to remove everything from the '%' and out,
/// including the final newline, if any, but this does not work.
/// The problem is that TeX will do exactly this, but then it will
/// add back a character that depends on its state (S, M, or N),
/// and it is tricky to maintain a similar state that matches the
/// state of TeX faithfully.  Hence, we remove the content of
/// comments but do not remove the comments themselves, we just
/// leave the '%' at the end of the line and let TeX manage its
/// states in a way that does not differ from the file from before
/// stripComment.
stripComment(line) {
  if (isCommentOnly(line)) return "%\n";
  return cutRegexp(line, commentRE, startOffset: 2);
}

/// Reduces a white-space-only [line] to its eol character,
/// removes leading ws entirely, and reduces multiple
/// white-space chars to one.
normalizeWhitespace(line) {
  var trimLine = line.trimLeft();
  if (trimLine.isEmpty) return justEol(line);
  return trimLine.replaceAll(whitespaceRE, " ");
}

/// Reduces sequences of >1 white-space-only lines in [lines] to 1,
/// and sequences of >1 comment-only lines to 1.  Treats comment-only
/// lines as white-space-only when they occur in white-space-only
/// line blocks.
multilineNormalize(lines) {
  var afterBlankLines = false; // Does [line] succeed >0 empty lines?
  var afterCommentLines = false; // Does [line] succeed >0 commentOnly lines?
  var newLines = new List();
  for (var line in lines) {
    if (afterBlankLines && afterCommentLines) {
      // Previous line was both blank and a comment: not possible.
      throw "Bug, please report to eernst@";
    } else if (afterBlankLines && !afterCommentLines) {
      // At least one line before [line] is wsOnly.
      if (!isWsOnly(line)) {
        // Blank line block ended.
        afterCommentLines = isCommentOnly(line);
        // Special case: It seems to be safe to remove commentOnly lines
        // after wsOnly lines, so the TeX state must be predictably right;
        // next line will then be afterCommentLines and be dropped, so
        // we drop the entire comment block---which is very useful.  We can
        // also consider this comment line to be an empty line, such that
        // subsequent empty lines can be considered to be in a block of
        // empty lines.  Note that almost all variants of this breaks.
        if (afterCommentLines) {
          // _Current_ 'line' is a commentOnly here.
          afterBlankLines = true;
          afterCommentLines = false;
          // Omit addition of [line].
        } else {
          // After blanks, but current 'line' is neither blank nor comment.
          afterBlankLines = false;
          newLines.add(line);
        }
      } else {
        // Blank line block continues, omit addition of [line].
      }
    } else if (!afterBlankLines && afterCommentLines) {
      // At least one line before [line] is commentOnly.
      if (!isCommentOnly(line)) {
        // Comment block ended.
        afterBlankLines = isWsOnly(line);
        afterCommentLines = false;
        newLines.add(line);
      } else {
        // Comment block continues, do not add [line].
      }
    } else {
      assert(!afterBlankLines && !afterCommentLines);
      // No wsOnly or commentOnly lines precede [line].
      afterBlankLines = isWsOnly(line);
      afterCommentLines = isCommentOnly(line);
      if (!afterCommentLines) {
        newLines.add(line);
      } else {
        // skip commentOnly line after nonWs/nonComment text.
      }
    }
  }
  return newLines;
}

/// Selects the elements in the normalization pipeline.
normalize(line) => normalizeWhitespace(stripComment(line));

/// Selects the elements in the significant-spacing block
/// normalization pipeline.
sispNormalize(line) => stripComment(line);

// Managing fragments with significant spacing.

final dartCodeBeginRE = new RegExp(r"^\s*\\begin\s*\{dartCode\}");
final dartCodeEndRE = new RegExp(r"^\s*\\end\s*\{dartCode\}");

/// Recognizes beginning of dartCode block.
sispIsDartBegin(line) => line.contains(dartCodeBeginRE);

/// Recognizes end of dartCode block.
sispIsDartEnd(line) => line.contains(dartCodeEndRE);

// ----------------------------------------------------------------------
// Analyzing the input to point out "interesting" lines

/// Returns the event information for [lines] as determined by the
/// given [analyzer].  The method [analyzer.analyze] indicates that a
/// line is "uninteresting" by returning null (i.e., no events here),
/// and "interesting" lines may be characterized by [analysisFunc] via
/// the returned event object.
findEvents(lines, analyzer) {
  var events = new List();
  for (var line in lines) {
    var event = analyzer.analyze(line);
    if (event != null) events.add(event);
  }
  return events;
}

/// Returns RegExp text for recognizing a command occupying a line
/// of its own, given the part of the RegExp that recognizes the
/// command name, [cmdNameRE]
lineCommandRE(cmdNameRE) =>
    new RegExp(r"^\s*\\" + cmdNameRE + r"\s*\{.*\}%?\s*$");

final hashLabelStartRE = new RegExp(r"^\s*\\LMLabel\s*\{");
final hashLabelEndRE = new RegExp(r"\}\s*$");

final hashMarkRE = lineCommandRE("LMHash");
final hashLabelRE = lineCommandRE("LMLabel");
final sectioningRE = lineCommandRE("((|sub(|sub))section|paragraph)");
final sectionRE = lineCommandRE("section");
final subsectionRE = lineCommandRE("subsection");
final subsubsectionRE = lineCommandRE("subsubsection");
final paragraphRE = lineCommandRE("paragraph");

/// Returns true iff [line] begins a block of lines that gets a hash value.
isHashMarker(line) => line.contains(hashMarkRE);

/// Returns true iff [line] defines a sectioning label.
isHashLabel(line) => line.contains(hashLabelRE);

/// Returns true iff [line] is a sectioning command resp. one of its
/// more specific forms; note that it is assumed that sectioning commands
/// do not contain a newline between the command name and the '{'.
isSectioningCommand(line) => line.contains(sectioningRE);
isSectionCommand(line) => line.contains(sectionRE);
isSubsectionCommand(line) => line.contains(subsectionRE);
isSubsubsectionCommand(line) => line.contains(subsubsectionRE);
isParagraphCommand(line) => line.contains(paragraphRE);

/// Returns true iff [line] does not end a block of lines that gets
/// a hash value.
bool isntHashBlockTerminator(line) => !isSectioningCommand(line);

/// Returns the label text part from [line], based on the assumption
/// that isHashLabel(line) returns true.
extractHashLabel(line) {
  var startMatch = hashLabelStartRE.firstMatch(line);
  var endMatch = hashLabelEndRE.firstMatch(line);
  assert(startMatch != null && endMatch != null);
  return line.substring(startMatch.end, endMatch.start);
}

// Event classes: Keep track of relevant information about the LaTeX
// source code lines, such as where \LMHash and \LMLabel commands are
// used, and how they are embedded in the sectioning structure.

/// Abstract events, enabling us to [setEndLineNumber] on all events.
abstract class HashEvent {
  /// For events that have an endLineNumber, set it; otherwise ignore.
  /// The endLineNumber specifies the end of the block of lines
  /// associated with a given event, for event types concerned with
  /// blocks of lines rather than single lines.
  setEndLineNumber(n) {}

  /// Returns null except for \LMHash{} events, where it returns
  /// the startLineNumber.  This serves to specify a boundary because
  /// the preceding \LMHash{} block should stop before the line of
  /// this \LMHash{} command.  Note that hash blocks may stop earlier,
  /// because they cannot contain sectioning commands.
  getStartLineNumber() => null;
}

class HashMarkerEvent extends HashEvent {
  // Line number of first line in block that gets hashed.
  var startLineNumber;

  // Highest possible number of first line after block that gets
  // hashed (where the next \LMHash{} occurs).  Note that this value
  // is not known initially (because that line has not yet been
  // reached), so [endLineNumber] will be initialized in a separate
  // scan.  Also note that the block may end earlier, because a block
  // ends if it would otherwise include a sectioning command.
  var endLineNumber;

  HashMarkerEvent(this.startLineNumber);

  setEndLineNumber(n) {
    endLineNumber = n;
  }

  getStartLineNumber() => startLineNumber;
}

class HashLabelEvent extends HashEvent {
  var labelText;
  HashLabelEvent(this.labelText);
}

class HashAnalyzer {
  // List of kinds of pending (= most recently seen) sectioning command.
  // When updating this list, also update sectioningPrefix below.
  static const PENDING_IS_NONE = 0;
  static const PENDING_IS_SECTION = 1;
  static const PENDING_IS_SUBSECTION = 2;
  static const PENDING_IS_SUBSUBSECTION = 3;
  static const PENDING_IS_PARAGRAPH = 1;

  var lineNumber = 0;
  var pendingSectioning = PENDING_IS_NONE;

  HashAnalyzer();

  setPendingToSection() {
    pendingSectioning = PENDING_IS_SECTION;
  }

  setPendingToSubsection() {
    pendingSectioning = PENDING_IS_SUBSECTION;
  }

  setPendingToSubsubsection() {
    pendingSectioning = PENDING_IS_SUBSUBSECTION;
  }

  setPendingToParagraph() {
    pendingSectioning = PENDING_IS_PARAGRAPH;
  }

  clearPending() {
    pendingSectioning = PENDING_IS_NONE;
  }

  sectioningPrefix() {
    switch (pendingSectioning) {
      case PENDING_IS_SECTION:
        return "sec:";
      case PENDING_IS_SUBSECTION:
        return "subsec:";
      case PENDING_IS_SUBSUBSECTION:
        return "subsubsec:";
      case PENDING_IS_PARAGRAPH:
        return "par:";
      case PENDING_IS_NONE:
        throw "\\LMHash{..} should only be used after a sectioning command " +
            "(\\section, \\subsection, \\subsubsection, \\paragraph)";
      default:
        // set of PENDING_IS_.. was extended, but updates here omitted
        throw "Bug, please report to eernst@";
    }
  }

  analyze(line) {
    var currentLineNumber = lineNumber++;
    if (isHashMarker(line)) {
      return new HashMarkerEvent(currentLineNumber);
    } else if (isHashLabel(line)) {
      var labelText = sectioningPrefix() + extractHashLabel(line);
      return new HashLabelEvent(labelText);
    } else {
      // No events to emit, but we may need to note state changes
      if (isSectionCommand(line)) {
        setPendingToSection();
      } else if (isSubsectionCommand(line)) {
        setPendingToSubsection();
      } else if (isSubsubsectionCommand(line)) {
        setPendingToSubsubsection();
      } else if (isParagraphCommand(line)) {
        setPendingToParagraph();
      } else {
        // No state changes.
      }
      return null;
    }
  }
}

findHashEvents(lines) {
  // Create the list of events, omitting endLineNumbers.
  var events = findEvents(lines, new HashAnalyzer());
  // Set the endLineNumbers.
  var currentEndLineNumber = lines.length;
  for (var event in events.reversed) {
    event.setEndLineNumber(currentEndLineNumber);
    var nextEndLineNumber = event.getStartLineNumber();
    if (nextEndLineNumber != null) currentEndLineNumber = nextEndLineNumber;
  }
  return events;
}

// ----------------------------------------------------------------------
// Removal of non-normative elements of the text (rationale, commentary).

/// Returns [line] without the command [cmdName] (based on a match
/// on "\\cmdName\s*{..}") starting at [startIndex]; note that it is
/// assumed but not checked that [line] contains "\\cmdType\s*{..",
/// and note that the end of the {..} block is found via brace matching
/// (i.e., nested {..} blocks are handled), but it may break if '{' is
/// made an active character etc.etc.
removeCommand(line, cmdName, startIndex) {
  const BACKSLASH = 92; // char code for '\\'.
  const BRACE_BEGIN = 123; // char code for '{'.
  const BRACE_END = 125; // char code for '}'.

  var blockStartIndex = startIndex + cmdName.length + 1;
  while (blockStartIndex < line.length &&
      line.codeUnitAt(blockStartIndex) != BRACE_BEGIN) {
    blockStartIndex++;
  }
  blockStartIndex++;
  if (blockStartIndex > line.length) {
    throw "Bug, please report to eernst@";
  }
  // [blockStartIndex] has index just after '{'.

  var afterEscape = false; // Is true iff [index] is just after '{'.
  var braceLevel = 1; // Have seen so many '{'s minus so many '}'s.

  for (var index = blockStartIndex; index < line.length; index++) {
    switch (line.codeUnitAt(index)) {
      case BRACE_BEGIN:
        if (afterEscape) {
          afterEscape = false;
        } else {
          braceLevel++;
        }
        break;
      case BRACE_END:
        if (afterEscape) {
          afterEscape = false;
        } else {
          braceLevel--;
        }
        break;
      case BACKSLASH:
        afterEscape = true;
        break;
      default:
        afterEscape = false;
    }
    if (braceLevel == 0) {
      return line.substring(0, startIndex) + line.substring(index + 1);
    }
  }
  // Removal failed; we consider this to mean that the input is ill-formed.
  throw "Unmatched braces";
}

final commentaryRE = new RegExp(r"\\commentary\s*\{");
final rationaleRE = new RegExp(r"\\rationale\s*\{");

/// Removes {}-balanced '\commentary{..}' commands from [line].
removeCommentary(line) {
  var match = commentaryRE.firstMatch(line);
  if (match == null) return line;
  return removeCommentary(removeCommand(line, r"commentary", match.start));
}

/// Removes {}-balanced '\rationale{..}' commands from [line].
removeRationale(line) {
  var match = rationaleRE.firstMatch(line);
  if (match == null) return line;
  return removeRationale(removeCommand(line, r"rationale", match.start));
}

/// Removes {}-balanced '\commentary{..}' and '\rationale{..}'
/// commands from [line], then normalizes its white-space.
simplifyLine(line) {
  var simplerLine = removeCommentary(line);
  simplerLine = removeRationale(simplerLine);
  simplerLine = normalizeWhitespace(simplerLine);
  return simplerLine;
}

// ----------------------------------------------------------------------
// Recognition of line blocks, insertion of block hash into \LMHash{}.

final latexArgumentRE = new RegExp(r"\{.*\}");

cleanupLine(line) => cutRegexp(line, commentRE, startOffset: 1).trimRight();

/// Returns concatenation of all lines from [startIndex] in [lines] until
/// a hash block terminator is encountered or [nextIndex] reached (if so,
/// the line lines[nextIndex] itself is not included); each line is cleaned
/// up using [cleanupLine], and " " is inserted between the lines gathered.
gatherLines(lines, startIndex, nextIndex) => lines
    .getRange(startIndex, nextIndex)
    .takeWhile(isntHashBlockTerminator)
    .map(cleanupLine)
    .join(" ");

/// Computes the hash value for the line block starting at [startIndex]
/// in [lines], stopping just before [nextIndex].  SIDE EFFECT:
/// Outputs the simplified text and its hash value to [listSink].
computeHashValue(lines, startIndex, nextIndex, listSink) {
  final gatheredLine = gatherLines(lines, startIndex, nextIndex);
  final simplifiedLine = simplifyLine(gatheredLine);
  listSink.write("  % $simplifiedLine\n");
  var digest = sha1.convert(encodeUtf8(simplifiedLine));
  return digest.bytes;
}

computeHashString(lines, startIndex, nextIndex, listSink) =>
    hex.encode(computeHashValue(lines, startIndex, nextIndex, listSink));

/// Computes and adds hashes to \LMHash{} lines in [lines] (which
/// must be on the line numbers specified in [hashEvents]), and emits
/// sectioning markers and hash values to [listSink], along with
/// "comments" containing the simplified text (using the format
/// '  % <text>', where the text is one, long line, for easy grepping
/// etc.).
addHashMarks(lines, hashEvents, listSink) {
  for (var hashEvent in hashEvents) {
    if (hashEvent is HashMarkerEvent) {
      var start = hashEvent.startLineNumber;
      var end = hashEvent.endLineNumber;
      final hashValue = computeHashString(lines, start + 1, end, listSink);
      lines[start] =
          lines[start].replaceAll(latexArgumentRE, "{" + hashValue + "}");
      listSink.write("  $hashValue\n");
    } else if (hashEvent is HashLabelEvent) {
      listSink.write("${hashEvent.labelText}\n");
    }
  }
}

/// Transforms LaTeX input to LaTeX output plus hash value list file.
main([args]) {
  if (args.length != 3) {
    print("Usage: addlatexhash.dart <input-file> <output-file> <list-file>");
    throw "Received ${args.length} arguments, expected three";
  }

  // Get LaTeX source.
  var inputFile = new File(args[0]);
  assert(inputFile.existsSync());
  var lines = inputFile.readAsLinesSync();

  // Will hold LaTeX source with normalized spacing etc., plus hash values.
  var outputFile = new File(args[1]);

  // Will hold hierarchical list of hash values.
  var listFile = new File(args[2]);
  var listSink = listFile.openWrite();

  // Perform single-line normalization.
  var inDartCode = false;
  var normalizedLines = new List();

  for (var line in lines) {
    if (sispIsDartBegin(line)) {
      inDartCode = true;
    } else if (sispIsDartEnd(line)) {
      inDartCode = false;
    }
    if (inDartCode) {
      normalizedLines.add(sispNormalize(line + "\n"));
    } else {
      normalizedLines.add(normalize(line + "\n"));
    }
  }

  // Perform multi-line normalization.
  normalizedLines = multilineNormalize(normalizedLines);

  // Insert hash values.
  var hashEvents = findHashEvents(normalizedLines);
  addHashMarks(normalizedLines, hashEvents, listSink);

  // Produce/finalize output.
  outputFile.writeAsStringSync(normalizedLines.join());
  listSink.close();
}
