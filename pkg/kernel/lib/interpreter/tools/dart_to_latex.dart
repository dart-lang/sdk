// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*LATEX
\documentclass[a4paper,12pt,oneside]{article}

\usepackage[utf8]{inputenc}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{listings}

\lstset{basicstyle=\footnotesize\ttfamily\bf}

\begin{document}

\title{dart\_to\_latex.dart}
\author{The Dart project authors}
\date{}

\maketitle

\section*{Introduction}

The purpose of this program is to extract comments of a special form from Dart
programs and put them into a .tex file in the order of their appearance in the
Dart program.
It allows writing elaborate documentation in the comments using formulas and
also use custom formatting commands.

The comments that are put into the output .tex file are of the form
\lstinline!/*LATEX ... */!.
Additionally, all Dart lines marked with one-line comment \lstinline!//LATEX!
are also included to the output file and are put into \lstinline!verbatim!
environment.
Using \lstinline!//LATEX! sometimes conflicts with the default behavior of
\lstinline!dartfmt! formatting utility that may put the one-line comment to the
following line.
To address this issue one can use \lstinline!//LATEX-NEXT! comment right before
the line that should be inserted into the output.
 */

/*LATEX
\section{Implementation Overview}

First, the libraries for working with files and strings are imported.
 */
import "dart:io"; //LATEX
import "dart:core"; //LATEX

/*LATEX
Most of the work is done in the Extractor class.
 */

//LATEX-NEXT
class Extractor {
  /*LATEX
  There are some string constants that are used for text parsing.
   */
  static final String latexMarker = "LATEX"; //LATEX
  static final String latexNextMarker = "LATEX-NEXT"; //LATEX
  static final String commentBegin = "/*"; //LATEX
  static final String commentEnd = "*/"; //LATEX
  static final String oneLineCommentBegin = "//"; //LATEX

  final String inputFilename;
  final String outputFilename;

  final File inputFile;
  final File outputFile;

  String input;

  /*LATEX
  The actual parsing is done in the following methods.
   */

  //LATEX-NEXT
  Extractor(this.inputFilename, this.outputFilename)
      : inputFile = new File(inputFilename),
        outputFile = new File(outputFilename) {
    // Clear the output file at start.
    outputFile.writeAsStringSync("", mode: FileMode.WRITE, flush: true);
  }

  //LATEX-NEXT
  int findCommentEnd(int start) {
    assert(start <= input.length);
    assert(input.startsWith(commentBegin, start));

    int balance = 1;
    int i = start + commentBegin.length;
    while (i < input.length && balance > 0) {
      if (input.startsWith(commentBegin, i)) {
        balance++;
        i += commentBegin.length;
      } else if (input.startsWith(commentEnd, i)) {
        balance--;
        i += commentEnd.length;
      } else {
        i++;
      }
    }

    if (balance > 0) {
      return -1;
    }

    return i;
  }

  //LATEX-NEXT
  void extractOneLineCommentsFrom(String text) {
    List<String> lines = text.split("\n");
    List<String> outputLines = new List<String>();
    int i = 0;
    while (i < lines.length) {
      String line = lines[i];
      if (line.endsWith(oneLineCommentBegin + latexMarker)) {
        outputLines.add(line.substring(
            0, line.length - (oneLineCommentBegin + latexMarker).length));
        i++;
      } else if (line.endsWith(oneLineCommentBegin + latexNextMarker) &&
          i + 1 < lines.length) {
        outputLines.add(lines[i + 1]);
        i += 2;
      } else {
        i++;
      }
    }
    if (outputLines.length > 0) {
      outputLines.insert(0, r"\begin{verbatim}");
      outputLines.add(r"\end{verbatim}");
    }
    for (String line in outputLines) {
      outputFile.writeAsStringSync("$line\n", mode: FileMode.APPEND);
    }
  }

  //LATEX-NEXT
  void extractOneLineComments() {
    int endIndex = input.indexOf(commentBegin);
    while (endIndex != -1 &&
        !input.startsWith(commentBegin + latexMarker, endIndex)) {
      endIndex = findCommentEnd(endIndex);
      if (endIndex != -1) {
        endIndex = input.indexOf(commentBegin, endIndex);
      }
    }
    if (endIndex == -1) {
      endIndex = input.length;
    }
    extractOneLineCommentsFrom(input.substring(0, endIndex));
    input = input.substring(endIndex);
  }

  //LATEX-NEXT
  void extractBlock() {
    int startIndex = input.indexOf(commentBegin);
    while (startIndex != -1 &&
        !input.startsWith(commentBegin + latexMarker, startIndex)) {
      startIndex = findCommentEnd(startIndex);
      if (startIndex != -1) {
        startIndex = input.indexOf(commentBegin, startIndex);
      }
    }
    if (startIndex == -1) {
      startIndex = input.length;
    }
    input = input.substring(startIndex);

    if (input.startsWith(commentBegin + latexMarker)) {
      int endIndex = findCommentEnd(0);
      if (endIndex == -1) {
        endIndex = input.length;
      }
      int latexBeginIndex = (commentBegin + latexMarker).length;
      int latexEndIndex = input.substring(0, endIndex).endsWith(commentEnd)
          ? endIndex - commentEnd.length
          : endIndex;
      outputFile.writeAsStringSync(
          input.substring(latexBeginIndex, latexEndIndex) + "\n",
          mode: FileMode.APPEND);
      input = input.substring(endIndex);
    }
  }

  //LATEX-NEXT
  void run() {
    input = inputFile.readAsStringSync();
    while (input.length > 0) {
      extractOneLineComments();
      if (input.length > 0) extractBlock();
    }
  }
} // class Extractor //LATEX

/*LATEX
Finally, the entrance point of the program is defined.
After some trivial arguments check it creates an extractor instance and runs the
extraction.
 */
//LATEX-NEXT
main(List<String> arguments) {
  // Arguments checks... //LATEX
  if (arguments.length != 2) {
    stderr.writeln("usage: dart dart_to_latex.dart input.dart output.tex");
    exit(1);
  }
  String inputFilename = arguments[0];
  String outputFilename = arguments[1];

  Extractor parser = new Extractor(inputFilename, outputFilename); //LATEX
  parser.run(); //LATEX
} //LATEX

/*LATEX
\section{User Manual}

\begin{enumerate}
\item \lstinline!dart dart_to_latex.dart input.dart output.tex!
\item \lstinline!pdflatex output.tex!
\end{enumerate}
 */

/*LATEX
\section*{Conclusion}

The presented program may have been written better.
It reads the entire input file into a \lstinline!String! variable and creates
sub-strings of the input during extraction.
A better approach would be to read the input program partially into a buffer,
maintain a set of indexes on it, and analyze it on the fly.

The \LaTeX{} part of the program can also be improved.
For example, there is probably a better way to format the code fragmeents
inlined into paragraphs than using \lstinline1\lstinline!...!1.

As a side note, one may use this tool to extract \LaTeX{} comments from programs
in some other languages like C++ and Java.
 */

/*LATEX
\end{document}
 */
