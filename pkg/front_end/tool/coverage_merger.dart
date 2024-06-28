// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $SPACE, $CARET, $LF, $CR;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/util/parser_ast.dart';
import 'package:front_end/src/util/parser_ast_helper.dart';
import 'package:kernel/ast.dart';
import 'package:package_config/package_config.dart';

import '../test/coverage_helper.dart';
import 'interval_list.dart';
import 'parser_ast_indexer.dart';
import 'utils.dart';

void main(List<String> arguments) {
  Uri? coverageUri;
  Uri? packagesUri;
  bool addCommentsToFiles = false;
  bool removeCommentsFromFiles = false;

  for (String argument in arguments) {
    const String coverage = "--coverage=";
    const String packages = "--packages=";
    const String comment = "--comment";
    const String removeComments = "--remove-comments";
    if (argument.startsWith(coverage)) {
      coverageUri =
          Uri.base.resolveUri(Uri.file(argument.substring(coverage.length)));
    } else if (argument.startsWith(packages)) {
      packagesUri =
          Uri.base.resolveUri(Uri.file(argument.substring(packages.length)));
    } else if (argument == comment) {
      addCommentsToFiles = true;
    } else if (argument == removeComments) {
      removeCommentsFromFiles = true;
    } else {
      throw "Unsupported argument: $argument";
    }
  }
  if (coverageUri == null) {
    throw "Need --coverage=<dir>/ argument";
  }
  if (packagesUri == null) {
    throw "Need --packages=<path/to/package_config.json> argument";
  }

  Stopwatch stopwatch = new Stopwatch()..start();
  mergeFromDirUri(
    packagesUri,
    coverageUri,
    silent: false,
    extraCoverageIgnores: ["coverage-ignore(suite):"],
    extraCoverageBlockIgnores: ["coverage-ignore-block(suite):"],
    addCommentsToFiles: addCommentsToFiles,
    removeCommentsFromFiles: removeCommentsFromFiles,
  );
  print("Done in ${stopwatch.elapsed}");
}

Map<Uri, CoverageInfo>? mergeFromDirUri(
  Uri packagesUri,
  Uri coverageUri, {
  required bool silent,
  required List<String> extraCoverageIgnores,
  required List<String> extraCoverageBlockIgnores,
  bool addCommentsToFiles = false,
  bool removeCommentsFromFiles = false,
}) {
  void output(Object? object) {
    if (silent) return;
    print(object);
  }

  PackageConfig packageConfig;
  try {
    packageConfig = PackageConfig.parseBytes(
        File.fromUri(packagesUri).readAsBytesSync(), packagesUri);
  } catch (e) {
    // When will we want to catch this?
    output("Error trying to read package config: $e");
    return null;
  }

  // TODO(jensj): We should allow for comments to "excuse" something from not
  // being covered. E.g. sometimes we throw after a number of if's saying
  // something like "this can probably never happen", and thus we can't expect
  // to test that.

  // TODO(jensj): We should be able to extract the "coverable" offsets from
  // source/dill, thus avoiding asking the VM to do it and basically we would
  // then be able to just ignore the uncompiled stuff from the VM. It could
  // probably also be used for speeding up doing coverage in flutter. We need to
  // be "sharp" about what the VM includes and what the VM doesn't include
  // though. I assume it doesn't include everything, but really I don't know.

  // TODO(jensj): Things that are not covered by one of our suites should
  // probably be marked specifically as we generally want tests "close".

  // Merge the data:
  //  * combine hits, and keep track of where they come from (display name)
  //  * combine misses, but remove misses that are hits
  //  * ignore not compiled regions.
  Map<Uri, Hit> hits = {};
  Map<Uri, Set<int>> misses = {};

  for (FileSystemEntity entry
      in Directory.fromUri(coverageUri).listSync(recursive: true)) {
    if (entry is! File) continue;
    try {
      Coverage coverage = Coverage.loadFromFile(entry);
      output("Loaded $entry as coverage file.");
      _mergeCoverageInto(coverage, misses, hits);
    } catch (e) {
      output("Couldn't load $entry as coverage file.");
    }
  }
  output("");

  Set<Uri> knownUris = {};
  knownUris.addAll(hits.keys);
  knownUris.addAll(misses.keys);

  int filesCount = 0;
  int allCoveredCount = 0;
  int hitsTotal = 0;
  int missesTotal = 0;
  int errorsCount = 0;

  Map<Uri, CoverageInfo> result = {};

  for (Uri uri in knownUris.toList()
    ..sort(((a, b) => a.toString().compareTo(b.toString())))) {
    // Don't care about coverage for testing stuff.
    String uriString = uri.toString();
    if (uriString.startsWith("package:front_end/src/testing/")) continue;
    if (uriString == "package:front_end/src/util/parser_ast_helper.dart" ||
        uriString ==
            "package:front_end/src/api_prototype/experimental_flags_generated.dart" ||
        uriString == "package:front_end/src/codes/cfe_codes_generated.dart") {
      continue;
    }

    Hit? hit = hits[uri];
    Set<int>? miss = misses[uri];
    List<int> hitsSorted =
        hit == null ? const [] : (hit._data.keys.toList()..sort());

    CoverageInfo processInfo = process(
      packageConfig,
      uri,
      miss ?? const {},
      hitsSorted,
      extraCoverageIgnores,
      extraCoverageBlockIgnores,
      addCommentsToFiles: addCommentsToFiles,
      removeCommentsFromFiles: removeCommentsFromFiles,
    );
    if (processInfo.visualization.trim().isNotEmpty) {
      output(processInfo.visualization);
      output("");
    }
    result[uri] = processInfo;
    filesCount++;
    if (processInfo.error) {
      errorsCount++;
    } else {
      if (processInfo.allCovered) {
        allCoveredCount++;
      }
      hitsTotal += processInfo.hitCount;
      missesTotal += processInfo.missCount;
    }
  }

  output("Processed $filesCount files with $errorsCount error(s) and "
      "$allCoveredCount files being covered 100%.");
  int percentHit = (hitsTotal * 100) ~/ (hitsTotal + missesTotal);
  output("All-in-all $hitsTotal hits and $missesTotal misses ($percentHit%).");

  return result;
}

class CoverageInfo {
  final bool error;
  final bool allCovered;
  final int missCount;
  final int hitCount;
  final String visualization;

  CoverageInfo.error(this.visualization)
      : error = true,
        allCovered = false,
        missCount = 0,
        hitCount = 0;

  CoverageInfo(
      {required this.allCovered,
      required this.missCount,
      required this.hitCount,
      required this.visualization})
      : error = false;
}

CoverageInfo process(
  PackageConfig packageConfig,
  Uri uri,
  Set<int> untrimmedMisses,
  List<int> hitsSorted,
  List<String> extraCoverageIgnores,
  List<String> extraCoverageBlockIgnores, {
  bool addCommentsToFiles = false,
  bool removeCommentsFromFiles = false,
}) {
  Uri? fileUri = packageConfig.resolve(uri);
  if (fileUri == null) {
    return new CoverageInfo.error("Couldn't find file uri for $uri");
  }
  File f = new File.fromUri(fileUri);
  Uint8List rawBytes;
  try {
    rawBytes = f.readAsBytesSync();
  } catch (e) {
    return new CoverageInfo.error("Error reading file $f");
  }

  List<int> lineStarts = [];
  // TODO(jensj): "allowPatterns" for instance should use data from the package
  // config to be set correctly.
  CompilationUnitEnd ast = getAST(
    rawBytes,
    includeComments: true,
    enableExtensionMethods: true,
    enableNonNullable: true,
    enableTripleShift: true,
    allowPatterns: true,
    lineStarts: lineStarts,
  );

  Source source = new Source(lineStarts, rawBytes, uri, fileUri);

  if (removeCommentsFromFiles) {
    CompilationUnitBegin unitBegin =
        ast.children!.first as CompilationUnitBegin;
    Token? token = unitBegin.token;
    List<Token> removeComments = [];
    while (token != null && !token.isEof) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        String message = comment.lexeme.trim().toLowerCase();
        while (message.startsWith("//") || message.startsWith("/*")) {
          message = message.substring(2).trim();
        }
        for (String coverageIgnoreString in const [
          "coverage-ignore(suite): not run.",
          "coverage-ignore-block(suite): not run.",
        ]) {
          if (message.startsWith(coverageIgnoreString)) {
            removeComments.add(comment);
          }
        }
        comment = comment.next;
      }
      token = token.next;
    }
    String sourceText = source.text;
    StringBuffer sb = new StringBuffer();
    int from = 0;
    for (Token token in removeComments) {
      String substring = sourceText.substring(from, token.charOffset);
      sb.write(substring);
      from = token.charEnd;
      // Remove whitespace after too.
      while (sourceText.length > from &&
          (sourceText.codeUnitAt(from) == $SPACE ||
              sourceText.codeUnitAt(from) == $LF ||
              sourceText.codeUnitAt(from) == $CR)) {
        from++;
      }
    }
    sb.write(sourceText.substring(from));
    f.writeAsStringSync(sb.toString());
    print("Removed ${removeComments.length} in $uri");

    // Return a fake result.
    return new CoverageInfo(
        allCovered: true, missCount: -1, hitCount: -1, visualization: "fake 2");
  }

  List<int> allSorted = [...hitsSorted, ...untrimmedMisses]..sort();
  AstIndexerAndIgnoreCollector astIndexer =
      AstIndexerAndIgnoreCollector.collect(
          ast, extraCoverageIgnores, extraCoverageBlockIgnores,
          hitsSorted: hitsSorted, allSorted: allSorted);

  IntervalList ignoredIntervals =
      astIndexer.ignoredStartEnd.buildIntervalList();

  if (addCommentsToFiles) {
    String sourceText = source.text;
    StringBuffer sb = new StringBuffer();
    int from = 0;
    astIndexer.potentiallyAddCommentTokens.sort();
    List<_CommentOn> processed = [];
    for (_CommentOn commentOn in astIndexer.potentiallyAddCommentTokens) {
      bool doAdd = true;
      if (processed.isNotEmpty) {
        _CommentOn prevAdded = processed.last;

        if (prevAdded.beginToken.charOffset <=
                commentOn.beginToken.charOffset &&
            prevAdded.endToken.charEnd >= commentOn.endToken.charEnd) {
          // The previous added "block" contain this one.
          doAdd = false;

          if (commentOn.commentOnToken.lexeme == "." ||
              commentOn.commentOnToken.lexeme == "?.") {
            // A comment on the actual call isn't pretty.
            // Allow the "bigger one".
          } else if (prevAdded.canBeReplaced) {
            // Though if there aren't any possible extra coverage in the
            // previous block compared to this one, we do prefer the smaller
            // one.
            int allSortedIndex =
                binarySearch(allSorted, commentOn.beginToken.charOffset);
            if (allSortedIndex < allSorted.length &&
                allSorted[allSortedIndex] < commentOn.beginToken.charOffset) {
              allSortedIndex++;
            }
            if (allSortedIndex > 0 &&
                allSorted[allSortedIndex - 1] <
                    prevAdded.beginToken.charOffset) {
              // The block before this can't have any coverage.
              // Now find the first point outside this range.
              int i = binarySearch(allSorted, commentOn.endToken.charEnd) + 1;
              if (i < allSorted.length &&
                  allSorted[i] > prevAdded.endToken.charEnd) {
                // The previous one doesn't have any possible coverage points
                // that this one doesn't. We prefer the smaller one and will
                // therefore replace it.
                processed.removeLast();
                doAdd = true;
              }
            }
          }
        }
      }
      if (doAdd) {
        processed.add(commentOn);
      }
    }
    for (_CommentOn entry in processed) {
      // If - on a file without ignore comments - an ignore comment is
      // pushed down (say inside an if instead of outside it), on a subsequent
      // run, because now that ignore inside the if is already present there's
      // nothing to push down and the one outside the if will be added.
      // We don't want that, so verify that a new comment will actually ignore
      // possible coverage points that wasn't covered/ignored before.
      int sortedIndex = binarySearch(allSorted, entry.beginToken.charOffset);
      if (sortedIndex < allSorted.length &&
          allSorted[sortedIndex] < entry.beginToken.charOffset) {
        sortedIndex++;
      }
      bool doAdd = false;
      while (sortedIndex < allSorted.length &&
          allSorted[sortedIndex] <= entry.endToken.charEnd) {
        if (!ignoredIntervals.contains(allSorted[sortedIndex])) {
          doAdd = true;
          break;
        }
        sortedIndex++;
      }

      if (!doAdd) {
        continue;
      }

      Token token = entry.commentOnToken;
      String extra = "";
      if (token.previous?.lexeme == "&&" ||
          token.previous?.lexeme == "||" ||
          token.previous?.lexeme == "(" ||
          token.previous?.lexeme == ")" ||
          token.previous?.lexeme == "}" ||
          token.previous?.lexeme == "?" ||
          token.previous?.lexeme == ":" ||
          token.previous?.lexeme == ";" ||
          token.previous?.lexeme == "=" ||
          token.lexeme == "?.") {
        extra = "\n  ";
        // If adding an extra linebreak would introduce an empty line we won't
        // add it.
        for (int i = token.charOffset - 1; i >= token.previous!.charEnd; i--) {
          int codeUnit = sourceText.codeUnitAt(i);
          if (codeUnit == $SPACE) {
            // We ignore spaces.
          } else if (codeUnit == $LF || codeUnit == $CR) {
            // Found linebreak: Adding a linebreak would add an empty line.
            extra = "";
            break;
          } else {
            // We found a non-space before a linebreak.
            // Let's just add the linebreak.
            break;
          }
        }
      }
      if (token.precedingComments != null) {
        token = token.precedingComments!;
      }
      String substring = sourceText.substring(from, token.charOffset);
      sb.write(substring);

      // The extra spaces at the end makes the formatter format better if for
      // instance there's comments after this.
      if (entry.isBlock) {
        sb.write("$extra// Coverage-ignore-block(suite): Not run.\n  ");
      } else {
        sb.write("$extra// Coverage-ignore(suite): Not run.\n  ");
      }
      from = token.charOffset;
    }
    sb.write(sourceText.substring(from));
    f.writeAsStringSync(sb.toString());

    // Return a fake result.
    return new CoverageInfo(
        allCovered: true, missCount: -1, hitCount: -1, visualization: "fake");
  }

  // TODO(jensj): Extract all comments and use those as well here.
  // TODO(jensj): Should some comment throw/report and error if covered?
  // E.g. "we expect this to be dead code, if it isn't we want to know."

  StringBuffer visualization = new StringBuffer();

  var (:bool allCovered, :Set<int> trimmedMisses) =
      _trimIgnoredAndPrintPercentages(
          visualization, ignoredIntervals, untrimmedMisses, hitsSorted, uri);

  if (allCovered) {
    return new CoverageInfo(
        allCovered: allCovered,
        missCount: trimmedMisses.length,
        hitCount: hitsSorted.length,
        visualization: visualization.toString());
  }

  CompilationUnitBegin unitBegin = ast.children!.first as CompilationUnitBegin;
  Token firstToken = unitBegin.token;

  List<int> sortedMisses = trimmedMisses.toList()..sort();

  int lastLine = -1;
  int lastOffset = -1;
  Uint8List? indentation;
  String? line;
  Token token = firstToken;
  int? latestNodeIndex;
  int nextHitIndexToCheck = 0;

  void printFinishedLine() {
    if (indentation != null) {
      String? name = astIndexer.nameOfEntitySpanning(lastOffset);
      String pointer = new String.fromCharCodes(indentation!);
      if (name != null) {
        visualization.writeln("$uri:$lastLine:\nIn '$name':\n$line\n$pointer");
      } else {
        visualization.writeln("$uri:$lastLine:\n$line\n$pointer");
      }
      line = null;
      indentation = null;
    }
  }

  int nextOffsetIndex = 0;
  while (nextOffsetIndex < sortedMisses.length) {
    int offset = sortedMisses[nextOffsetIndex];
    nextOffsetIndex++;
    while (offset > token.charOffset) {
      token = token.next!;
      if (token.isEof) break;
    }

    int? thisNodeIndex = astIndexer.findNodeIndexSpanningPosition(offset);
    if (thisNodeIndex != null && thisNodeIndex != latestNodeIndex) {
      // First miss in this entity: Does it have any hits?
      latestNodeIndex = thisNodeIndex;
      printFinishedLine();
      bool foundHit = false;
      int first = astIndexer.moveNodeIndexToFirstMetadataIfAny(thisNodeIndex)!;
      int last = astIndexer.moveNodeIndexPastMetadata(
              astIndexer.findNodeIndexSpanningPosition(offset)) ??
          thisNodeIndex;
      int beginOffset = astIndexer.positionStartEndIndex[first * 2 + 0];
      int endOffset = astIndexer.positionStartEndIndex[last * 2 + 1];
      for (; nextHitIndexToCheck < hitsSorted.length; nextHitIndexToCheck++) {
        int hit = hitsSorted[nextHitIndexToCheck];
        if (hit >= beginOffset && hit <= endOffset) {
          foundHit = true;
          break;
        } else if (hit > endOffset) {
          break;
        }
      }
      if (!foundHit) {
        // Don't show a line with only metadata.
        offset = astIndexer.positionStartEndIndex[last * 2];
        Location location = source.getLocation(uri, offset);
        String line = source.getTextLine(location.line)!;
        String? name = astIndexer.nameOfEntitySpanning(offset);

        if (name != null) {
          visualization.writeln("$uri:${location.line}: "
              "No coverage for '$name' ($offset).\n$line\n");
          // TODO(jensj): Squiggly line under the identifier of the entity?
        } else {
          visualization.writeln(
              "$uri:${location.line}: No coverage for entity.\n$line\n");
        }

        // Skip the rest of the miss points inside the entity.
        while (nextOffsetIndex < sortedMisses.length) {
          offset = sortedMisses[nextOffsetIndex];
          if (offset > endOffset) break;
          nextOffsetIndex++;
        }

        continue;
      }
    }

    Location location = source.getLocation(uri, offset);
    if (location.line != lastLine) {
      printFinishedLine();
      lastLine = location.line;
      line = source.getTextLine(location.line)!;
      indentation = new Uint8List(line!.length)
        ..fillRange(0, line!.length, $SPACE);
    }

    try {
      if (offset == token.charOffset) {
        for (int i = 0; i < token.length; i++) {
          indentation![location.column - 1 + i] = $CARET;
        }
      } else {
        indentation![location.column - 1] = $CARET;
      }
      lastOffset = offset;
    } catch (e) {
      visualization.writeln("Error on offset $offset --- $location: $e");
      visualization.writeln(
          "Maybe the coverage data is not up to date with the source?");
      return new CoverageInfo.error(visualization.toString());
    }
  }
  printFinishedLine();

  return new CoverageInfo(
      allCovered: allCovered,
      missCount: trimmedMisses.length,
      hitCount: hitsSorted.length,
      visualization: visualization.toString());
}

({bool allCovered, Set<int> trimmedMisses}) _trimIgnoredAndPrintPercentages(
    StringBuffer visualization,
    IntervalList ignoredIntervals,
    Set<int> untrimmedMisses,
    List<int> hitsSorted,
    Uri uri) {
  int missCount = untrimmedMisses.length;
  int hitCount = hitsSorted.length;
  Set<int> trimmedMisses;
  if (hitCount + missCount == 0) {
    visualization.writeln("$uri");
    return (allCovered: true, trimmedMisses: untrimmedMisses);
  } else {
    if (!ignoredIntervals.isEmpty) {
      trimmedMisses = {};
      for (int position in untrimmedMisses) {
        if (ignoredIntervals.contains(position)) {
          // Ignored position!
        } else {
          trimmedMisses.add(position);
        }
      }
      missCount = trimmedMisses.length;
    } else {
      trimmedMisses = untrimmedMisses;
    }

    if (missCount > 0) {
      visualization.writeln(
          "$uri: ${(hitCount / (hitCount + missCount) * 100).round()}% "
          "($missCount misses)");
      return (allCovered: false, trimmedMisses: trimmedMisses);
    } else {
      // visualization.writeln("$uri: 100% (OK)");
      return (allCovered: true, trimmedMisses: trimmedMisses);
    }
  }
}

void _mergeCoverageInto(
    Coverage coverage, Map<Uri, Set<int>> misses, Map<Uri, Hit> hits) {
  for (FileCoverage fileCoverage in coverage.getAllFileCoverages()) {
    if (fileCoverage.uri.isScheme("package") &&
        fileCoverage.uri.pathSegments.first != "front_end") continue;
    if (fileCoverage.misses.isNotEmpty) {
      Set<int> miss = misses[fileCoverage.uri] ??= {};
      miss.addAll(fileCoverage.misses);
    }

    if (fileCoverage.hits.isNotEmpty) {
      Hit hit = hits[fileCoverage.uri] ??= new Hit();
      for (int fileHit in fileCoverage.hits) {
        hit.addHit(fileHit, coverage.displayName);
      }
    }
  }

  // Now remove any misses that are actually hits.
  for (MapEntry<Uri, Set<int>> entry in misses.entries) {
    Hit? hit = hits[entry.key];
    if (hit == null) continue;
    entry.value.removeAll(hit._data.keys);
  }
}

class Hit {
  Map<int, List<String>> _data = {};

  void addHit(int offset, String displayName) {
    (_data[offset] ??= []).add(displayName);
  }
}

class AstIndexerAndIgnoreCollector extends AstIndexer {
  final Set<String> topLevelMethodNamesToIgnore = {
    "debug",
    "debugString",
  };
  final Set<String> classMethodNamesToIgnore = {
    "debug",
    "debugString",
    "toString",
    "hashCode",
    "==",
    "debugName",
    "writeNullabilityOn",
  };
  final List<String> _coverageIgnores = [
    "coverage-ignore:",
  ];
  final List<String> _coverageBlockIgnores = [
    "coverage-ignore-block:",
  ];

  final IntervalListBuilder ignoredStartEnd = new IntervalListBuilder();

  final List<int> hitsSorted;
  int hitsSortedIndex = 0;
  final List<int> allSorted;
  int allSortedIndex = 0;

  final List<_CommentOn> potentiallyAddCommentTokens = [];

  late final _AstIndexerAndIgnoreCollectorBody _collectorBody =
      new _AstIndexerAndIgnoreCollectorBody(this);

  static AstIndexerAndIgnoreCollector collect(ParserAstNode ast,
      List<String> extraCoverageIgnores, List<String> extraCoverageBlockIgnores,
      {required List<int> hitsSorted, required List<int> allSorted}) {
    AstIndexerAndIgnoreCollector collector =
        new AstIndexerAndIgnoreCollector._(hitsSorted, allSorted);
    collector._coverageIgnores.addAll(extraCoverageIgnores);
    collector._coverageBlockIgnores.addAll(extraCoverageBlockIgnores);
    ast.accept(collector);

    assert(collector.positionNodeIndex.length ==
        collector.positionNodeName.length);
    assert(collector.positionNodeIndex.length * 2 ==
        collector.positionStartEndIndex.length);

    return collector;
  }

  AstIndexerAndIgnoreCollector._(this.hitsSorted, this.allSorted) {}

  bool _hasIgnoreComment(Token tokenWithPossibleComment,
      {required bool isBlock}) {
    List<String> coverageIgnores = _coverageIgnores;
    if (isBlock) {
      coverageIgnores = _coverageBlockIgnores;
    }
    Token? comment = tokenWithPossibleComment.precedingComments;
    while (comment != null) {
      String message = comment.lexeme.trim().toLowerCase();
      while (message.startsWith("//") || message.startsWith("/*")) {
        message = message.substring(2).trim();
      }
      for (String coverageIgnoreString in coverageIgnores) {
        if (message.startsWith(coverageIgnoreString)) {
          return true;
        }
      }
      comment = comment.next;
    }
    return false;
  }

  /// Check if there is an ignore comment on [tokenWithPossibleComment] and
  /// returns true if there is.
  ///
  /// If there is not it will add a note to add one if that makes sense (in that
  /// there is possible coverage but no actual coverage).
  bool _checkCommentAndIgnoreCoverage(
      Token tokenWithPossibleComment, BeginAndEndTokenParserAstNode ignoreRange,
      {required bool allowReplace}) {
    return _checkCommentAndIgnoreCoverageWithBeginAndEnd(
        tokenWithPossibleComment, ignoreRange.beginToken, ignoreRange.endToken,
        allowReplace: allowReplace);
  }

  /// Check if there is an ignore comment on [tokenWithPossibleComment] and
  /// returns true if there is.
  ///
  /// If there is not it will add a note to add one if that makes sense (in that
  /// there is possible coverage but no actual coverage).
  bool _checkCommentAndIgnoreCoverageWithBeginAndEnd(
      Token tokenWithPossibleComment, Token beginToken, Token endToken,
      {required bool allowReplace,
      bool isBlock = false,
      bool allowOnBraceStart = false}) {
    if (_hasIgnoreComment(tokenWithPossibleComment, isBlock: isBlock)) {
      ignoredStartEnd.addIntervalIncludingEnd(
          beginToken.charOffset, endToken.charEnd);
      return true;
    }

    // Should a comment be added here?
    if (tokenWithPossibleComment.lexeme == "{" && !allowOnBraceStart) {
      // We don't want to add it "outside" the block, but inside it,
      // so we just return here.
      return false;
    }
    if (tokenWithPossibleComment.lexeme == "else" &&
        tokenWithPossibleComment.next!.lexeme == "{") {
      // An else with a block, prefer it directly inside the block instead.
      return false;
    }
    // Because of (at least) `visitEndingBinaryExpressionHandle` we can get
    // events out of order. Go back here if needed...
    if (allSorted.isNotEmpty) {
      if (allSorted.length >= allSortedIndex) {
        allSortedIndex = allSorted.length - 1;
      }
      while (allSortedIndex > 0 &&
          allSorted[allSortedIndex] > beginToken.charOffset) {
        allSortedIndex--;
      }
      // ...then go forward if needed (e.g. when it does come in order).
      while (allSortedIndex < allSorted.length &&
          allSorted[allSortedIndex] < beginToken.charOffset) {
        allSortedIndex++;
      }
    }

    if (allSortedIndex >= allSorted.length ||
        // We use >= here because e.g. "assert(a, 'msg')" has `a.charEnd` and
        // `,.charOffset` to be equal but it logically belongs to the comma
        //(which for whatever reason can a possible coverage point).
        allSorted[allSortedIndex] >= endToken.charEnd) {
      // Nothing inside this block can be covered by the VM anyway.
      return false;
    }

    // As before: Make work when events arrive out of order.
    if (hitsSorted.isNotEmpty) {
      if (hitsSorted.length >= hitsSortedIndex) {
        hitsSortedIndex = hitsSorted.length - 1;
      }
      while (hitsSortedIndex > 0 &&
          hitsSorted[hitsSortedIndex] > beginToken.charOffset) {
        hitsSortedIndex--;
      }
      while (hitsSortedIndex < hitsSorted.length &&
          hitsSorted[hitsSortedIndex] < beginToken.charOffset) {
        hitsSortedIndex++;
      }
    }

    if (hitsSortedIndex >= hitsSorted.length ||
        // We use >= here because e.g. "assert(a, 'msg')" has `a.charEnd` and
        // `,.charOffset` to be equal but it logically belongs to the comma
        //(which for whatever reason can a possible coverage point).
        hitsSorted[hitsSortedIndex] >= endToken.charEnd) {
      // No hits at all or next hit is after this "block".
      potentiallyAddCommentTokens.add(new _CommentOn(
        commentOnToken: tokenWithPossibleComment,
        beginToken: beginToken,
        endToken: endToken,
        canBeReplaced: allowReplace,
        isBlock: isBlock,
      ));
    }

    return false;
  }

  /// Check if there is an ignore comment on [tokenWithPossibleComment] and
  /// returns true if there is.
  ///
  /// If there is not it will add a note to add one if that makes sense (in that
  /// there is possible coverage but no actual coverage).
  ///
  /// This method in particular will try to ignore from
  /// [tokenWithPossibleComment] until the end of the block that it's inside,
  /// but fall back to the original range if that's not possible.
  /// Two different comments are used to distinguish these cases.
  bool _checkCommentAndIgnoreCoverageUntilEndOfBlockOrEnd(
      Token tokenWithPossibleComment,
      Token beginToken,
      ParserAstNode node,
      Token endToken,
      {required bool allowReplace}) {
    ParserAstNode? parent = node.parent;
    if ((parent is BlockFunctionBodyEnd || parent is BlockEnd)) {
      if (_checkCommentAndIgnoreCoverageWithBeginAndEnd(
          tokenWithPossibleComment,
          beginToken,
          (parent as BeginAndEndTokenParserAstNode).endToken,
          allowReplace: allowReplace,
          isBlock: true)) {
        return true;
      }
    }
    return _checkCommentAndIgnoreCoverageWithBeginAndEnd(
        tokenWithPossibleComment, beginToken, endToken,
        allowReplace: allowReplace);
  }

  bool _ignoreIfChildrenIsThrow(BeginAndEndTokenParserAstNode node) {
    List<ParserAstNode>? children = node.children;
    if (children == null) return false;
    if (children.length >= 4 &&
        children[1] is NewExpressionEnd &&
        children[2] is ThrowExpressionHandle &&
        children[3] is ExpressionStatementHandle) {
      ignoredStartEnd.addIntervalIncludingEnd(
          node.beginToken.charOffset, node.endToken.charEnd);
      return true;
    }
    return false;
  }

  @override
  void visitClassDeclarationEnd(ClassDeclarationEnd node) {
    // Note that this stops recursing meaning there'll be stuff we can't look
    // up. If that turns out to be a problem we can likely just not return,
    // possible "double-ignored" coverages should still work fine because of the
    // interval list.
    if (_checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: false)) return;
    super.visitClassDeclarationEnd(node);
  }

  @override
  void visitExtensionDeclarationEnd(ExtensionDeclarationEnd node) {
    // Note that this stops recursing meaning there'll be stuff we can't look
    // up. If that turns out to be a problem we can likely just not return,
    // possible "double-ignored" coverages should still work fine because of the
    // interval list.
    if (_checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: false)) return;
    super.visitExtensionDeclarationEnd(node);
  }

  @override
  void visitExtensionTypeDeclarationEnd(ExtensionTypeDeclarationEnd node) {
    // Note that this stops recursing meaning there'll be stuff we can't look
    // up. If that turns out to be a problem we can likely just not return,
    // possible "double-ignored" coverages should still work fine because of the
    // interval list.
    if (_checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: false)) return;
    super.visitExtensionTypeDeclarationEnd(node);
  }

  @override
  void visitTopLevelFieldsEnd(TopLevelFieldsEnd node) {
    super.visitTopLevelFieldsEnd(node);
    assert(positionNodeIndex.last == node);
    assert(positionStartEndIndex.last == node.endToken.charEnd);
    int index = positionNodeIndex.length - 1;
    int firstIndex = moveNodeIndexToFirstMetadataIfAny(index)!;
    Token beginToken = node.beginToken;
    if (firstIndex < index) {
      MetadataEnd metadata = positionNodeIndex[firstIndex] as MetadataEnd;
      beginToken = metadata.beginToken;
    }

    if (_checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.beginToken, beginToken, node.endToken,
        allowReplace: false)) {
      // Ignore these class fields including metadata.
      ignoredStartEnd.addIntervalIncludingEnd(
          positionStartEndIndex[firstIndex * 2 + 0], node.endToken.charEnd);
    }
  }

  @override
  void visitTopLevelMethodEnd(TopLevelMethodEnd node) {
    if (_checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: false)) return;
    super.visitTopLevelMethodEnd(node);
    String name = node.getNameIdentifier().token.lexeme;
    if (topLevelMethodNamesToIgnore.contains(name)) {
      // Ignore this method including metadata.
      assert(positionNodeIndex.last == node);
      assert(positionStartEndIndex.last == node.endToken.charEnd);
      int index = positionNodeIndex.length - 1;
      int firstIndex = moveNodeIndexToFirstMetadataIfAny(index)!;
      ignoredStartEnd.addIntervalIncludingEnd(
          positionStartEndIndex[firstIndex * 2 + 0], node.endToken.charEnd);
    } else {
      node.accept(_collectorBody);
    }
  }

  /// This method will try to recognize entities (think methods) that just
  /// throws. If it finds [node] to be this, it will add it to the ignore list
  /// and return true.
  bool _ignoreIfEntityWithThrowBody(BeginAndEndTokenParserAstNode node) {
    List<ParserAstNode>? children = node.children;
    if (children == null) return false;
    for (ParserAstNode child in children) {
      if (child is BlockFunctionBodyEnd && _ignoreIfChildrenIsThrow(child)) {
        return true;
      }
    }
    return false;
  }

  @override
  void containerFields(
      BeginAndEndTokenParserAstNode node, List<IdentifierHandle> names) {
    super.containerFields(node, names);
    assert(positionNodeIndex.last == node);
    assert(positionStartEndIndex.last == node.endToken.charEnd);
    int index = positionNodeIndex.length - 1;
    int firstIndex = moveNodeIndexToFirstMetadataIfAny(index)!;
    Token beginToken = node.beginToken;
    if (firstIndex < index) {
      MetadataEnd metadata = positionNodeIndex[firstIndex] as MetadataEnd;
      beginToken = metadata.beginToken;
    }

    if (_checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.beginToken, beginToken, node.endToken,
        allowReplace: false)) {
      // Ignore these class fields including metadata.
      ignoredStartEnd.addIntervalIncludingEnd(
          positionStartEndIndex[firstIndex * 2 + 0], node.endToken.charEnd);
    }
  }

  @override
  void containerMethod(BeginAndEndTokenParserAstNode node, String name) {
    super.containerMethod(node, name);
    assert(positionNodeIndex.last == node);
    assert(positionStartEndIndex.last == node.endToken.charEnd);
    int index = positionNodeIndex.length - 1;
    int firstIndex = moveNodeIndexToFirstMetadataIfAny(index)!;
    Token beginToken = node.beginToken;
    if (firstIndex < index) {
      MetadataEnd metadata = positionNodeIndex[firstIndex] as MetadataEnd;
      beginToken = metadata.beginToken;
    }

    if (_ignoreIfEntityWithThrowBody(node) ||
        classMethodNamesToIgnore.contains(name) ||
        _checkCommentAndIgnoreCoverageWithBeginAndEnd(
            node.beginToken, beginToken, node.endToken,
            allowReplace: false)) {
      // Ignore this class method including metadata.

      ignoredStartEnd.addIntervalIncludingEnd(
          positionStartEndIndex[firstIndex * 2 + 0], node.endToken.charEnd);
    } else {
      node.accept(_collectorBody);
    }
  }
}

class _AstIndexerAndIgnoreCollectorBody extends RecursiveParserAstVisitor {
  final AstIndexerAndIgnoreCollector _collector;

  _AstIndexerAndIgnoreCollectorBody(this._collector);

  bool _recordIfIsCallToNotExpectedCoverage(
      BeginAndEndTokenParserAstNode node) {
    List<ParserAstNode>? children = node.children;
    if (children != null &&
        children.length >= 5 &&
        children[1] is IdentifierHandle) {
      IdentifierHandle identifier = children[1] as IdentifierHandle;
      if ((identifier.token.lexeme == "internalProblem" ||
              identifier.token.lexeme == "unimplemented" ||
              identifier.token.lexeme == "unhandled" ||
              identifier.token.lexeme == "unexpected" ||
              identifier.token.lexeme == "unsupported") &&
          children[2] is NoTypeArgumentsHandle &&
          children[3] is ArgumentsEnd &&
          children[4] is SendHandle) {
        // This is (probably) a call to `internalProblem`/`unimplemented`/etc
        // inside an if block --- we don't expect these to happen
        // so we'll ignore them.
        _collector.ignoredStartEnd.addIntervalIncludingEnd(
            node.beginToken.charOffset, node.endToken.charEnd);
        return true;
      }
    }
    if (_collector._ignoreIfChildrenIsThrow(node)) return true;
    return false;
  }

  @override
  void visitReturnStatementEnd(ReturnStatementEnd node) {
    if (_recordIfIsCallToNotExpectedCoverage(node)) return;
    if (_collector._checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: false)) {
      return;
    }
    super.visitReturnStatementEnd(node);
  }

  @override
  void visitBlockEnd(BlockEnd node) {
    if (_recordIfIsCallToNotExpectedCoverage(node)) return;
    if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.beginToken.next!, node.beginToken, node.endToken,
        allowReplace: false, isBlock: true)) {
      return;
    }
    super.visitBlockEnd(node);
  }

  @override
  void visitBlockFunctionBodyEnd(BlockFunctionBodyEnd node) {
    if (_recordIfIsCallToNotExpectedCoverage(node)) return;
    if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.beginToken.next!, node.beginToken, node.endToken,
        allowReplace: false, isBlock: true)) {
      return;
    }
    super.visitBlockFunctionBodyEnd(node);
  }

  @override
  void visitFunctionExpressionEnd(FunctionExpressionEnd node) {
    if (_collector._checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: true)) {
      return;
    }
    super.visitFunctionExpressionEnd(node);
  }

  @override
  void visitLocalFunctionDeclarationEnd(LocalFunctionDeclarationEnd node) {
    ParserAstNode? beginNode = node.children?.firstOrNull;
    if (beginNode is LocalFunctionDeclarationBegin) {
      if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
          beginNode.token, beginNode.token, node.endToken,
          allowReplace: true)) {
        return;
      }
    }
    super.visitLocalFunctionDeclarationEnd(node);
  }

  @override
  void visitSwitchCaseEnd(SwitchCaseEnd node) {
    if (_collector._checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: false)) {
      return;
    }
    super.visitSwitchCaseEnd(node);
  }

  @override
  void visitCaseExpressionEnd(CaseExpressionEnd node) {
    if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.caseKeyword, node.caseKeyword, node.colon,
        allowReplace: false)) {
      return;
    }
    super.visitCaseExpressionEnd(node);
  }

  @override
  void visitThrowExpressionHandle(ThrowExpressionHandle node) {
    if (_collector._checkCommentAndIgnoreCoverageUntilEndOfBlockOrEnd(
        node.throwToken, node.throwToken, node, node.endToken,
        allowReplace: true)) {
      return;
    }
    super.visitThrowExpressionHandle(node);
  }

  @override
  void visitElseStatementEnd(ElseStatementEnd node) {
    if (_collector._checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: false)) {
      return;
    }
    super.visitElseStatementEnd(node);
  }

  @override
  void visitThenStatementEnd(ThenStatementEnd node) {
    if (_collector._checkCommentAndIgnoreCoverage(node.beginToken, node,
        allowReplace: true)) {
      return;
    }
    super.visitThenStatementEnd(node);
  }

  @override
  void visitIfStatementEnd(IfStatementEnd node) {
    if (_collector._checkCommentAndIgnoreCoverageUntilEndOfBlockOrEnd(
        node.ifToken, node.ifToken, node, node.endToken,
        allowReplace: true)) {
      return;
    }
    super.visitIfStatementEnd(node);
  }

  @override
  void visitTryStatementEnd(TryStatementEnd node) {
    if (_collector._checkCommentAndIgnoreCoverageUntilEndOfBlockOrEnd(
        node.tryKeyword, node.tryKeyword, node, node.endToken,
        allowReplace: true)) {
      return;
    }
    super.visitTryStatementEnd(node);
  }

  @override
  void visitBinaryExpressionEnd(BinaryExpressionEnd node) {
    if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.token.next!, node.token, node.endToken,
        allowReplace: false)) {
      return;
    }
    super.visitBinaryExpressionEnd(node);
  }

  @override
  void visitEndingBinaryExpressionHandle(EndingBinaryExpressionHandle node) {
    // Given `a?.b` if `a` is null `b` won't execute.
    // Having the comment before the `?.` formats prettier.
    if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.token, node.token, node.endToken,
        allowReplace: true)) {
      return;
    }
    super.visitEndingBinaryExpressionHandle(node);
  }

  @override
  void visitThenControlFlowHandle(ThenControlFlowHandle node) {
    ParserAstNode? parent = node.parent;
    if (parent is IfControlFlowEnd) {
      if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
          node.token.next!, node.token.next!, parent.token,
          allowReplace: false)) {
        return;
      }
    }
    super.visitThenControlFlowHandle(node);
  }

  @override
  void visitConditionalExpressionEnd(ConditionalExpressionEnd node) {
    // Visiting `foo ? bar : baz`:

    // Check the comment on the `bar` part (i.e. between ? and :).
    _collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.question.next!, node.question.next!, node.colon,
        allowReplace: false);

    // Check the comment on the `baz` part (i.e. between : and end).
    _collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.colon.next!, node.colon.next!, node.endToken,
        allowReplace: false);

    super.visitConditionalExpressionEnd(node);
  }

  @override
  void visitForLoopPartsHandle(ForLoopPartsHandle node) {
    // Given `for(a; b; c)` --- the `c` part could be uncovered.
    _collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.rightSeparator.next!,
        node.rightSeparator.next!,
        node.leftParen.endGroup!,
        allowReplace: false);
    super.visitForLoopPartsHandle(node);
  }

  @override
  void visitForInBodyEnd(ForInBodyEnd node) {
    ParserAstNode? beginNode = node.children?.firstOrNull;
    if (beginNode is ForInBodyBegin) {
      if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
          beginNode.token, beginNode.token, node.endToken,
          allowReplace: true, allowOnBraceStart: true)) {
        return;
      }
    }
    super.visitForInBodyEnd(node);
  }

  @override
  void visitExpressionStatementHandle(ExpressionStatementHandle node) {
    // TODO(jensj): allowReplace should depend upon if there's anything
    // coverable in this statement. If there isn't it should certainly be
    // replaceable.
    if (_collector._checkCommentAndIgnoreCoverageUntilEndOfBlockOrEnd(
        node.beginToken, node.beginToken, node, node.endToken,
        allowReplace: false)) {
      return;
    }
    super.visitExpressionStatementHandle(node);
  }

  @override
  void visitVariablesDeclarationEnd(VariablesDeclarationEnd node) {
    // TODO(jensj): allowReplace should depend upon if there's anything
    // coverable in this statement. If there isn't it should certainly be
    // replaceable.
    if (node.endToken != null) {
      List<ParserAstNode> parentChildren = node.parent!.children!;
      int thisIndex = parentChildren.indexOf(node);
      if (thisIndex - 1 >= 0 && parentChildren[thisIndex - 1] is TypeHandle) {
        TypeHandle type = parentChildren[thisIndex - 1] as TypeHandle;
        if (_collector._checkCommentAndIgnoreCoverageUntilEndOfBlockOrEnd(
            type.beginToken, type.beginToken, node, node.endToken!,
            allowReplace: false)) {
          return;
        }
      }
    }
    super.visitVariablesDeclarationEnd(node);
  }

  @override
  void visitAssertEnd(AssertEnd node) {
    if (_collector._checkCommentAndIgnoreCoverageUntilEndOfBlockOrEnd(
        node.assertKeyword, node.assertKeyword, node, node.endToken,
        allowReplace: true)) {
      return;
    }

    if (node.commaToken != null) {
      _collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
          node.commaToken!.next!, node.commaToken!, node.endToken,
          allowReplace: false);
    }
    super.visitAssertEnd(node);
  }

  @override
  void visitCatchBlockHandle(CatchBlockHandle node) {
    // TODO(jensj): allowReplace should depend upon if there's anything
    // coverable in this statement. If there isn't it should certainly be
    // replaceable.
    if (node.onKeyword != null) {
      List<ParserAstNode> parentChildren = node.parent!.children!;
      int thisIndex = parentChildren.indexOf(node);
      if (thisIndex - 1 >= 0 && parentChildren[thisIndex - 1] is BlockEnd) {
        BlockEnd block = parentChildren[thisIndex - 1] as BlockEnd;
        if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
            node.onKeyword!, node.onKeyword!, block.endToken,
            allowReplace: false)) {
          return;
        }
      }
    }
    super.visitCatchBlockHandle(node);
  }

  @override
  void visitPatternEnd(PatternEnd node) {
    ParserAstNode? beginNode = node.children?.firstOrNull;
    if (beginNode is PatternBegin) {
      Token begin = beginNode.token;
      if (begin.lexeme != ":") {
        begin = begin.next!;
      }
      if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
          begin, begin, node.token,
          allowReplace: true)) {
        return;
      }
    }
    super.visitPatternEnd(node);
  }

  @override
  void visitSwitchExpressionCaseEnd(SwitchExpressionCaseEnd node) {
    // The entire thing?
    if (_collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.beginToken, node.beginToken, node.endToken,
        allowReplace: true)) {
      return;
    }

    // The if-matched part?
    _collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.arrow.next!, node.arrow.next!, node.endToken,
        allowReplace: true);

    super.visitSwitchExpressionCaseEnd(node);
  }

  @override
  void visitAssignmentExpressionHandle(AssignmentExpressionHandle node) {
    _collector._checkCommentAndIgnoreCoverageWithBeginAndEnd(
        node.token.next!, node.token.next!, node.endToken,
        allowReplace: true, allowOnBraceStart: true);
    super.visitAssignmentExpressionHandle(node);
  }
}

class _CommentOn implements Comparable<_CommentOn> {
  final Token commentOnToken;
  final Token beginToken;
  final Token endToken;
  final bool canBeReplaced;
  final bool isBlock;

  _CommentOn({
    required this.commentOnToken,
    required this.beginToken,
    required this.endToken,
    required this.canBeReplaced,
    required this.isBlock,
  });

  @override
  int compareTo(_CommentOn other) {
    // Small to big.
    int result = beginToken.charOffset.compareTo(other.beginToken.charOffset);
    if (result != 0) return result;
    // Big to small.
    return other.endToken.charOffset.compareTo(endToken.charOffset);
  }
}
