// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ErrorToken, ScannerConfiguration, StringScanner;

import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show BeginToken, SimpleToken, Token, TokenType;

class Duplicate {
  final List<FromToUri> where;
  final String example;

  Duplicate(this.where, this.example);

  @override
  String toString() => "Duplicate[$example]";
}

class FromToUri {
  final Uri uri;
  final int startOffset;
  final int endOffset;

  FromToUri(this.uri, this.startOffset, this.endOffset);
}

class Line {
  String content;
  Uri uri;
  int startOffset;
  int endOffset;
  Line? previous;
  Line? next;

  Line(
      this.content, this.uri, this.startOffset, this.endOffset, this.previous) {
    if (previous != null) {
      previous!.next = this;
    }
  }
}

class ExtendedLines {
  List<Line> startLines;
  int lineCount;

  ExtendedLines(this.startLines, this.lineCount);
}

class MultiMap<K, V> {
  Map<K, List<V>> data = {};

  void operator []=(K key, V value) {
    List<V>? lookup = data[key];
    if (lookup != null) {
      lookup.add(value);
    } else {
      data[key] = [value];
    }
  }
}

void _indexLines(MultiMap<String, Line> mapped, Set<String> denyListed,
    String data, Uri uri) {
  // TODO(jensj): Work directly on scanned tokens, or use parser as well?
  // * Should probably only operate on body content, and then not cross bracket
  //   boundaries in that it should suggest that "foo; } } bar;" is a duplicate
  //   -- while it might be duplicate, we can't replace that with a function
  //   call (to get rid of duplicate code).
  // * If something is a string we could perhaps ignore the content so that
/*
    assert(declaration.parent == _libraryTypeParameterScopeBuilder);
    Map<String, Builder> members = declaration.members!;
    Map<String, MemberBuilder> constructors = declaration.constructors!;
    Map<String, MemberBuilder> setters = declaration.setters!;

    Scope classScope = new Scope(
        local: members,
        setters: setters,
        parent: scope.withTypeVariables(typeVariables),
        debugName: "class $className",
        isModifiable: false);
*/
  //   and
/*
    assert(declaration.parent == _libraryTypeParameterScopeBuilder);
    Map<String, Builder> members = declaration.members!;
    Map<String, MemberBuilder> constructors = declaration.constructors!;
    Map<String, MemberBuilder> setters = declaration.setters!;

    Scope classScope = new Scope(
        local: members,
        setters: setters,
        parent: scope.withTypeVariables(typeVariables),
        debugName: "extension $extensionName",
        isModifiable: false);
*/
  //   could match.
  Token scannedToken = _scan(data);
  if (scannedToken is ErrorToken) throw "Can't operate on erroneous data";
  Token token = scannedToken;
  StringBuffer sb = new StringBuffer();
  String space = "";
  int? startOffset;

  List<Token> endGroups = [];
  Line? previousLine;

  void endLine(Token lastToken) {
    String s = sb.toString();
    int lineStart = startOffset!;
    sb.clear();
    space = "";
    startOffset = null;

    Line line = new Line(s, uri, lineStart, lastToken.charEnd, previousLine);
    previousLine = line;
    if (!denyListed.contains(s)) mapped[s] = line;
  }

  while (true) {
    sb.write(space);
    sb.write(token.lexeme);
    space = " ";
    startOffset ??= token.charOffset;

    if (endGroups.isNotEmpty && endGroups.last == token) {
      endLine(token);
      endGroups.removeLast();
    } else if (token is BeginToken &&
        token.type == TokenType.OPEN_CURLY_BRACKET &&
        token.endGroup != null) {
      // End line on a "{".
      endLine(token);
      endGroups.add(token.endGroup!);
    } else if (token is SimpleToken && token.type == TokenType.SEMICOLON) {
      // End line on a ";".
      endLine(token);
    } else if (token.next!.isEof) {
      endLine(token);
      break;
    }

    token = token.next!;
  }
}

void _extendIndexedLines(List<Line> lines, Set<Line> alreadyIncluded,
    List<Duplicate> foundDuplicates, Set<String> denyListed) {
  int length = lines.length;

  if (length == 1) {
    // The indexed line was only seen once. That's not a duplicate!
    return;
  }

  // We move forward in the data, and if having found a -> b -> c
  // after having processed 'a' we shouldn't process from 'b' too. We thus
  // remove already included lines here.
  for (Line line in lines) {
    if (alreadyIncluded.contains(line)) {
      length--;
    }
  }
  if (length <= 1) {
    // We've seen this line before, but all duplicates was included in another
    // actual duplicate find. Don't process and report again!
    return;
  }

  // Can this potential duplicate be extended?
  List<ExtendedLines>? extended = _extend(lines,
      existingMatchCount: 1, leastMatches: 3, denyListed: denyListed);
  if (extended == null || extended.isEmpty) return;
  for (ExtendedLines extendedLine in extended) {
    for (Line line in extendedLine.startLines) {
      int left = extendedLine.lineCount - 1;
      Line l = line;
      while (left > 0) {
        alreadyIncluded.add(l);
        left--;
        l = l.next!;
      }
    }
    List<FromToUri> where = [];
    StringBuffer sb = new StringBuffer();
    String? example;
    for (Line firstLine in extendedLine.startLines) {
      int left = extendedLine.lineCount - 1;
      Line lastLine = firstLine;
      if (example == null) sb.writeln(lastLine.content);
      while (left > 0) {
        left--;
        lastLine = lastLine.next!;
        if (example == null) sb.writeln(lastLine.content);
      }
      where.add(new FromToUri(
          firstLine.uri, firstLine.startOffset, lastLine.endOffset));
      example ??= sb.toString();
    }
    foundDuplicates.add(new Duplicate(where, example!));
  }
}

List<Duplicate> findDuplicates(Map<Uri, String> data, {bool verbose = false}) {
  MultiMap<String, Line> indexedLines = new MultiMap();
  const Set<String> denyListed = const {"}", "return ;", ";", ") ;", "else {"};

  for (MapEntry<Uri, String> entry in data.entries) {
    _indexLines(indexedLines, denyListed, entry.value, entry.key);
  }

  // TODO(jensj): The already included approach is too simple. E.g.
  /*
match1;
nomatch;

match0;
match1;
match2;
match3;

vs

match1;
nomatchX;

match0;
match1;
match2;
match3;

would first find match1 match2 match3 --- then match0 match1 match2 match3.
*/

  Set<Line> alreadyIncluded = {};
  List<Duplicate> result = [];
  for (MapEntry<String, List<Line>> entry in indexedLines.data.entries) {
    _extendIndexedLines(entry.value, alreadyIncluded, result, denyListed);
  }

  if (verbose) {
    if (result.length == 0) {
      print("Didn't find any duplicates.");
    } else if (result.length == 1) {
      print("Found 1 duplicate:");
    } else {
      print("Found ${result.length} duplicates:");
    }
    for (Duplicate duplicate in result) {
      print("Found '${duplicate.example}' at:");
      for (FromToUri where in duplicate.where) {
        print("${where.uri}: ${where.startOffset} -> ${where.endOffset}");
      }
      print("----\n\n");
    }
  }

  return result;
}

/// Given a list of lines that match, find duplicates that match on more lines,
/// thereby extending and possibly splitting the match.
List<ExtendedLines>? _extend(List<Line> lines,
    {required int existingMatchCount,
    required int leastMatches,
    required Set<String> denyListed}) {
  MultiMap<String, Line> mapped = new MultiMap();

  // E.g. for this input
  // a -> b1 -> c1 -> d1
  // a -> b1 -> c1 -> d2
  // a -> b2 -> c2 -> d1
  // a -> b2 -> c2 -> d2
  // a -> b3 -> c2 -> d1
  // we'd like it to be split into
  // [a, b1, c1] and [a, b2, c2]

  for (Line line in lines) {
    Line? next = line.next;
    if (next != null) {
      mapped[next.content] = next;
    }
  }

  List<ExtendedLines>? result;

  for (MapEntry<String, List<Line>> entry in mapped.data.entries) {
    if (entry.value.length == 1) {
      continue;
    }

    int newMatchCount = existingMatchCount + 1;
    // Don't count e.g. '}' as an actual match -> require one additional match.
    // Notice that we can't just not count it as that would destroy the count
    // which we use to go back and forth between first and last matched line.
    if (denyListed.contains(entry.key)) {
      leastMatches++;
    }

    List<ExtendedLines>? extended = _extend(entry.value,
        existingMatchCount: newMatchCount,
        leastMatches: leastMatches,
        denyListed: denyListed);
    if (extended != null) {
      // Was extended further.
      (result ??= []).addAll(extended);
    } else if (newMatchCount >= leastMatches) {
      // Couldn't be extended further, but this was far enough.
      (result ??= []).add(new ExtendedLines(
          entry.value.map((Line endLine) {
            Line line = endLine;
            int back = existingMatchCount;
            while (back > 0) {
              line = line.previous!;
              back--;
            }
            return line;
          }).toList(),
          newMatchCount));
    }
  }

  return result;
}

Token _scan(String data) {
  ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
      enableTripleShift: true,
      enableExtensionMethods: true,
      enableNonNullable: true,
      forAugmentationLibrary: false);

  StringScanner scanner =
      new StringScanner(data, configuration: scannerConfiguration);
  Token firstToken = scanner.tokenize();
  return firstToken;
}

void main(List<String> args) {
  if (args.isEmpty) {
    args = [
      Platform.script
          .resolve("../lib/src/source/source_library_builder.dart")
          .toFilePath()
    ];
  }
  bool printed = false;
  for (String s in args) {
    File f = new File(s);
    if (!f.existsSync()) continue;
    String data = f.readAsStringSync();

    if (printed) print("\n\n=============\n\n");
    print("Output on $s:");
    findDuplicates({Uri.parse(s): data}, verbose: true);
    printed = true;
  }
}
