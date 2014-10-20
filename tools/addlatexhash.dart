// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// ----------------------------------------------------------------------
// This is a very specialized tool which was created in order to support
// adding hash values used as location markers in the LaTeX source of the
// language specification.  It is intended to take its input file as the
// first argument and the output file name as the second argument. From
// docs/language a typical usage would be as follows:
//
//   dart ../../tools/addlatexhash.dart dartLangSpec.tex tmp.tex
//
// This will yield a normalized variant tmp.tex of the language
// specification with hash values filled in.  For more details, please
// check the language specification source itself.
//
// NB: This utility assumes UN*X style line endings, \n, in the LaTeX
// source file receieved as input; it will not work with other styles.
//
// TODO: The current version does not fill in hash values, it only
// standardizes the LaTeX source by removing comments and normalizing
// white space.

import 'dart:io';
import 'dart:convert';
import '../pkg/crypto/lib/crypto.dart';

// Normalization of the text, i.e., removal or normalization
// of elements that do not affect the output from latex

final commentRE = new RegExp(r"[^\\]%.*"); // NB: . does not match \n
final whitespaceAllRE = new RegExp(r"^\s+$");
final whitespaceRE = new RegExp(r"[ \t]{2,}");

// normalization steps

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
                  startOffset: startOffset,
                  endOffset: endOffset,
                  glue: glue);
}

cutFromMatch(line, match, {offset: 0, glue: ""}) {
  if (match == null) return line;
  return line.substring(0, match.start + offset) + glue;
}

cutFromRegexp(line, re, {offset: 0, glue: ""}) {
  return cutFromMatch(line, re.firstMatch(line), offset: offset, glue: glue);
}

isWsOnly(line) => whitespaceAllRE.firstMatch(line) != null;
isCommentOnly(line) => line.startsWith("%");

justEol(line) {
  return line.endsWith("\n") ? "\n" : "";
}

stripComment(line) {
  // NB: it is tempting to remove everything from the '%' and out,
  // including the final newline, if any, but this does not work.
  // The problem is that TeX will do exactly this, but then it will
  // add back a character that depends on its state (S, M, or N),
  // and it is tricky to maintain a similar state that matches the
  // state of TeX faithfully.  Hence, we remove the content of
  // comments but do not remove the comments themselves, we just
  // leave the '%' at the end of the line and let TeX manage its
  // states in a way that does not differ from the file from before
  // stripComment
  if (isCommentOnly(line)) return "%\n";
  return cutRegexp(line, commentRE, startOffset: 2);
}

// Reduce a wsOnly line to its eol, remove leading ws
// entirely, and reduce multiple ws chars to one
normalizeWhitespace(line) {
  var trimLine = line.trimLeft();
  if (trimLine.isEmpty) return justEol(line);
  return trimLine.replaceAll(whitespaceRE, " ");
}

// Reduce sequences of >1 wsOnly lines to 1, and sequences of >1
// commentOnly lines to 1; moreover, treat commentOnly lines as
// wsOnly when occurring in wsOnly line blocks
multilineNormalize(lines) {
  var afterBlankLines = false; // does 'line' succeed >0 empty lines?
  var afterCommentLines = false; // .. succeed >0 commentOnly lines?
  var newLines = new List();
  for (var line in lines) {
    if (afterBlankLines && afterCommentLines) {
      // can never happen
      throw "Bug, please report to eernst@";
    } else if (afterBlankLines && !afterCommentLines) {
      // at least one line before 'line' is wsOnly
      if (!isWsOnly(line)) {
        // blank line block ended
        afterCommentLines = isCommentOnly(line);
        // special case: it seems to be safe to remove commentOnly lines
        // after wsOnly lines, so the TeX state must be predictably right;
        // next line will then be afterCommentLines and be dropped, so
        // we drop the entire comment block---which is very useful; we can
        // also consider this comment line to be an empty line, such that
        // subsequent empty lines can be considered to be in a block of
        // empty lines; note that almost all variants of this will break..
        if (afterCommentLines) {
          // _current_ 'line' a commentOnly here
          afterBlankLines = true;
          afterCommentLines = false;
          // and do not add 'line'
        } else {
          // after blanks, but current 'line' is neither blank nor comment
          afterBlankLines = false;
          newLines.add(line);
        }
      } else {
        // blank line block continues, do not add 'line'
      }
    } else if (!afterBlankLines && afterCommentLines) {
      // at least one line before 'line' is commentOnly
      if (!isCommentOnly(line)) {
        // comment line block ended
        afterBlankLines = isWsOnly(line);
        afterCommentLines = false;
        newLines.add(line);
      } else {
        // comment line block continues, do not add 'line'
      }
    } else {
      assert(!afterBlankLines && !afterCommentLines);
      // no wsOnly or commentOnly lines preceed 'line'
      afterBlankLines = isWsOnly(line);
      afterCommentLines = isCommentOnly(line);
      if (!afterCommentLines) newLines.add(line);
      // else skipping commentOnly line after nonWs, nonComment text
    }
  }
  return newLines;
}

// Selecting the elements in the pipeline

normalize(line) => normalizeWhitespace(stripComment(line));
sispNormalize(line) => stripComment(line);

// Managing fragments with significant spacing

final dartCodeBeginRE = new RegExp(r"^\s*\\begin\{dartCode\}");
final dartCodeEndRE = new RegExp (r"^\s*\\end\{dartCode\}");

sispIs(line, targetRE) {
  return targetRE.firstMatch(line) != null;
}

sispIsDartBegin(line) => sispIs(line, dartCodeBeginRE);
sispIsDartEnd(line) => sispIs(line, dartCodeEndRE);

// Transform input file into output file

main ([args]) {
  if (args.length != 2) {
    print("Usage: addlatexhash.dart <input-file> <output-file>");
    throw "Received ${args.length} arguments, expected two";
  }

  var inputFile = new File(args[0]);
  var outputFile = new File(args[1]);
  assert(inputFile.existsSync());

  var lines = inputFile.readAsLinesSync();
  // single-line normalization
  var inDartCode = false;
  var newLines = new List();

  for (var line in lines) {
    if (sispIsDartBegin(line)) {
      inDartCode = true;
    } else if (sispIsDartEnd(line)) {
      inDartCode = false;
    }
    if (inDartCode) {
      newLines.add(sispNormalize(line + "\n"));
    } else {
      newLines.add(normalize(line + "\n"));
    }
  }

  // multi-line normalization
  newLines = multilineNormalize(newLines);

  // output result
  outputFile.writeAsStringSync(newLines.join());
}
