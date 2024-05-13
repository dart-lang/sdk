// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $SPACE, $CARET;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/fasta/util/parser_ast.dart';
import 'package:front_end/src/fasta/util/parser_ast_helper.dart';
import 'package:kernel/ast.dart';
import 'package:package_config/package_config.dart';

import '../test/coverage_helper.dart';
import 'interval_list.dart';
import 'parser_ast_indexer.dart';

void main(List<String> arguments) {
  Uri? coverageUri;
  Uri? packagesUri;

  for (String argument in arguments) {
    const String coverage = "--coverage=";
    const String packages = "--packages=";
    if (argument.startsWith(coverage)) {
      coverageUri =
          Uri.base.resolveUri(Uri.file(argument.substring(coverage.length)));
    } else if (argument.startsWith(packages)) {
      packagesUri =
          Uri.base.resolveUri(Uri.file(argument.substring(packages.length)));
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
  mergeFromDirUri(packagesUri, coverageUri);
  print("Done in ${stopwatch.elapsed}");
}

void mergeFromDirUri(Uri packagesUri, Uri coverageUri) {
  PackageConfig packageConfig;
  try {
    packageConfig = PackageConfig.parseBytes(
        File.fromUri(packagesUri).readAsBytesSync(), packagesUri);
  } catch (e) {
    // When will we want to catch this?
    print("Error trying to read package config: $e");
    return;
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
      print("Loaded $entry as coverage file.");
      _mergeCoverageInto(coverage, misses, hits);
    } catch (e) {
      print("Couldn't load $entry as coverage file.");
    }
  }
  print("");

  Set<Uri> knownUris = {};
  knownUris.addAll(hits.keys);
  knownUris.addAll(misses.keys);

  int filesCount = 0;
  int allCoveredCount = 0;
  int hitsTotal = 0;
  int missesTotal = 0;
  int errorsCount = 0;

  for (Uri uri in knownUris.toList()
    ..sort(((a, b) => a.toString().compareTo(b.toString())))) {
    // Don't care about coverage for testing stuff.
    if (uri.toString().startsWith("package:front_end/src/testing/")) continue;

    Hit? hit = hits[uri];
    Set<int>? miss = misses[uri];
    List<int> hitsSorted =
        hit == null ? const [] : (hit._data.keys.toList()..sort());

    ProcessInfo processInfo = process(
        packageConfig, uri, miss ?? const {}, hitsSorted,
        visualize: true);
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

    print("");
  }

  print("Processed $filesCount files with $errorsCount error(s) and "
      "$allCoveredCount files being covered 100%.");
  int percentHit = (hitsTotal * 100) ~/ (hitsTotal + missesTotal);
  print("All-in-all $hitsTotal hits and $missesTotal misses ($percentHit%).");
}

class ProcessInfo {
  final bool error;
  final bool allCovered;
  final int missCount;
  final int hitCount;

  ProcessInfo.error()
      : error = true,
        allCovered = false,
        missCount = 0,
        hitCount = 0;

  ProcessInfo(
      {required this.allCovered,
      required this.missCount,
      required this.hitCount})
      : error = false;
}

ProcessInfo process(PackageConfig packageConfig, Uri uri,
    Set<int> untrimmedMisses, List<int> hitsSorted,
    {required bool visualize}) {
  Uri? fileUri = packageConfig.resolve(uri);
  if (fileUri == null) {
    print("Couldn't find file uri for $uri");
    return new ProcessInfo.error();
  }
  File f = new File.fromUri(fileUri);
  Uint8List rawBytes;
  try {
    rawBytes = f.readAsBytesSync();
  } catch (e) {
    print("Error reading file $f");
    return new ProcessInfo.error();
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
    lineStarts: lineStarts,
  );

  AstIndexerAndIgnoreCollector astIndexer =
      AstIndexerAndIgnoreCollector.collect(ast);

  // TODO(jensj): Extract all comments and use those as well here.
  // TODO(jensj): Should some comment throw/report and error if covered?
  // E.g. "we expect this to be dead code, if it isn't we want to know."

  IntervalList ignoredIntervals =
      astIndexer.ignoredStartEnd.buildIntervalList();
  var (:bool allCovered, :Set<int> trimmedMisses) =
      _trimIgnoredAndPrintPercentages(
          ignoredIntervals, untrimmedMisses, hitsSorted, uri);

  if (!visualize || allCovered) {
    return new ProcessInfo(
        allCovered: allCovered,
        missCount: trimmedMisses.length,
        hitCount: hitsSorted.length);
  }

  CompilationUnitBegin unitBegin = ast.children!.first as CompilationUnitBegin;
  Token firstToken = unitBegin.token;
  Source source = new Source(lineStarts, rawBytes, uri, fileUri);

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
        print("$uri:$lastLine:\nIn '$name':\n$line\n$pointer");
      } else {
        print("$uri:$lastLine:\n$line\n$pointer");
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
          print("$uri:${location.line}: No coverage for '$name'.\n$line\n");
          // TODO(jensj): Squiggly line under the identifier of the entity?
        } else {
          print("$uri:${location.line}: No coverage for entity.\n$line\n");
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
      print("Error on offset $offset --- $location: $e");
      print("Maybe the coverage data is not up to date with the source?");
      rethrow;
    }
  }
  printFinishedLine();

  return new ProcessInfo(
      allCovered: allCovered,
      missCount: trimmedMisses.length,
      hitCount: hitsSorted.length);
}

({bool allCovered, Set<int> trimmedMisses}) _trimIgnoredAndPrintPercentages(
    IntervalList ignoredIntervals,
    Set<int> untrimmedMisses,
    List<int> hitsSorted,
    Uri uri) {
  int missCount = untrimmedMisses.length;
  int hitCount = hitsSorted.length;
  Set<int> trimmedMisses;
  if (hitCount + missCount == 0) {
    print("$uri");
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
      print("$uri: ${(hitCount / (hitCount + missCount) * 100).round()}% "
          "($missCount misses)");
      return (allCovered: false, trimmedMisses: trimmedMisses);
    } else {
      print("$uri: 100% (OK)");
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
    "debugName",
    "writeNullabilityOn",
  };

  final IntervalListBuilder ignoredStartEnd = new IntervalListBuilder();

  late final _AstIndexerAndIgnoreCollectorBody _collectorBody =
      new _AstIndexerAndIgnoreCollectorBody(this);

  static AstIndexerAndIgnoreCollector collect(ParserAstNode ast) {
    AstIndexerAndIgnoreCollector collector =
        new AstIndexerAndIgnoreCollector._();
    ast.accept(collector);

    assert(collector.positionNodeIndex.length ==
        collector.positionNodeName.length);
    assert(collector.positionNodeIndex.length * 2 ==
        collector.positionStartEndIndex.length);

    return collector;
  }

  AstIndexerAndIgnoreCollector._() {}

  @override
  void visitTopLevelMethodEnd(TopLevelMethodEnd node) {
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

  @override
  void containerMethod(BeginAndEndTokenParserAstNode node, String name) {
    super.containerMethod(node, name);
    if (classMethodNamesToIgnore.contains(name)) {
      // Ignore this class method including metadata.
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
    return false;
  }

  @override
  void visitReturnStatementEnd(ReturnStatementEnd node) {
    if (_recordIfIsCallToNotExpectedCoverage(node)) return;
    super.visitReturnStatementEnd(node);
  }

  @override
  void visitBlockEnd(BlockEnd node) {
    if (_recordIfIsCallToNotExpectedCoverage(node)) return;
    super.visitBlockEnd(node);
  }
}
