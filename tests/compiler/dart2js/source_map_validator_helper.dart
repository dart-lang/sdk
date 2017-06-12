// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/elements/elements.dart'
    show
        AstElement,
        ClassElement,
        CompilationUnitElement,
        Element,
        FunctionElement,
        LibraryElement,
        MemberElement;
import 'package:compiler/src/io/source_file.dart' show SourceFile;
import 'package:compiler/src/io/source_information.dart'
    show computeElementNameForSourceMaps;
import 'package:kernel/ast.dart' show Location;

validateSourceMap(Uri targetUri,
    {Uri mainUri, Position mainPosition, CompilerImpl compiler}) {
  Uri mapUri = getMapUri(targetUri);
  List<String> targetLines = new File.fromUri(targetUri).readAsLinesSync();
  SingleMapping sourceMap = getSourceMap(mapUri);
  checkFileReferences(targetUri, mapUri, sourceMap);
  checkIndexReferences(targetLines, mapUri, sourceMap);
  checkRedundancy(sourceMap);
  if (compiler != null) {
    checkNames(targetUri, mapUri, sourceMap, compiler);
  }
  if (mainUri != null && mainPosition != null) {
    checkMainPosition(targetUri, targetLines, sourceMap, mainUri, mainPosition);
  }
}

checkIndexReferences(
    List<String> targetLines, Uri mapUri, SingleMapping sourceMap) {
  int urlsLength = sourceMap.urls.length;
  List<List<String>> sources = new List(urlsLength);
  print('Reading sources');
  for (int i = 0; i < urlsLength; i++) {
    sources[i] = new File.fromUri(mapUri.resolve(sourceMap.urls[i]))
        .readAsStringSync()
        .split('\n');
  }

  sourceMap.lines.forEach((TargetLineEntry line) {
    Expect.isTrue(line.line >= 0);
    Expect.isTrue(line.line < targetLines.length);
    for (TargetEntry entry in line.entries) {
      int urlIndex = entry.sourceUrlId;

      // TODO(zarah): Entry columns sometimes point one or more characters too
      // far. Incomment this check when this is fixed.
      //
      // Expect.isTrue(entry.column < target[line.line].length);
      Expect.isTrue(entry.column >= 0);
      Expect
          .isTrue(urlIndex == null || (urlIndex >= 0 && urlIndex < urlsLength));
      Expect.isTrue(entry.sourceLine == null ||
          (entry.sourceLine >= 0 &&
              entry.sourceLine < sources[urlIndex].length));
      Expect.isTrue(entry.sourceColumn == null ||
          (entry.sourceColumn >= 0 &&
              entry.sourceColumn < sources[urlIndex][entry.sourceLine].length));
      Expect.isTrue(entry.sourceNameId == null ||
          (entry.sourceNameId >= 0 &&
              entry.sourceNameId < sourceMap.names.length));
    }
  });
}

checkFileReferences(Uri targetUri, Uri mapUri, SingleMapping sourceMap) {
  Expect.equals(targetUri, mapUri.resolve(sourceMap.targetUrl));
  print('Checking sources');
  sourceMap.urls.forEach((String url) {
    Expect.isTrue(new File.fromUri(mapUri.resolve(url)).existsSync());
  });
}

checkRedundancy(SingleMapping sourceMap) {
  sourceMap.lines.forEach((TargetLineEntry line) {
    TargetEntry previous = null;
    for (TargetEntry next in line.entries) {
      if (previous != null) {
        Expect.isFalse(
            sameSourcePoint(previous, next),
            '$previous and $next are consecutive entries on line $line in the '
            'source map but point to same source locations');
      }
      previous = next;
    }
  });
}

checkNames(
    Uri targetUri, Uri mapUri, SingleMapping sourceMap, CompilerImpl compiler) {
  Map<Uri, CompilationUnitElement> compilationUnitMap = {};

  void mapCompilationUnits(LibraryElement library) {
    library.compilationUnits.forEach((CompilationUnitElement compilationUnit) {
      compilationUnitMap[compilationUnit.script.readableUri] = compilationUnit;
    });
  }

  compiler.libraryLoader.libraries.forEach((LibraryElement library) {
    mapCompilationUnits(library);
    if (library.patch != null) {
      mapCompilationUnits(library.patch);
    }
  });

  sourceMap.lines.forEach((TargetLineEntry line) {
    for (TargetEntry entry in line.entries) {
      if (entry.sourceNameId != null) {
        Uri uri = mapUri.resolve(sourceMap.urls[entry.sourceUrlId]);
        Position targetPosition = new Position(line.line, entry.column);
        Position sourcePosition =
            new Position(entry.sourceLine, entry.sourceColumn);
        String name = sourceMap.names[entry.sourceNameId];

        CompilationUnitElement compilationUnit = compilationUnitMap[uri];
        Expect.isNotNull(
            compilationUnit, "No compilation unit found for $uri.");

        SourceFile sourceFile = compilationUnit.script.file;

        Position positionFromOffset(int offset) {
          Location location = sourceFile.getLocation(offset);
          int line = location.line - 1;
          int column = location.column - 1;
          return new Position(line, column);
        }

        Interval intervalFromElement(AstElement element) {
          if (!element.hasNode) return null;

          var begin = element.node.getBeginToken().charOffset;
          var end = element.node.getEndToken();
          end = end.charOffset + end.charCount;
          return new Interval(
              positionFromOffset(begin), positionFromOffset(end));
        }

        AstElement findInnermost(AstElement element) {
          bool isInsideElement(FunctionElement closure) {
            Element enclosing = closure;
            while (enclosing != null) {
              if (enclosing == element) return true;
              enclosing = enclosing.enclosingElement;
            }
            return false;
          }

          if (element is MemberElement) {
            MemberElement member = element;
            member.nestedClosures.forEach((closure) {
              var localFunction = closure.expression;
              Interval interval = intervalFromElement(localFunction);
              if (interval != null &&
                  interval.contains(sourcePosition) &&
                  isInsideElement(localFunction)) {
                element = localFunction;
              }
            });
          }
          return element;
        }

        void match(AstElement element) {
          Interval interval = intervalFromElement(element);
          if (interval != null && interval.contains(sourcePosition)) {
            AstElement innerElement = findInnermost(element);
            String expectedName = computeElementNameForSourceMaps(innerElement);
            if (name != expectedName) {
              // For the code
              //    (){}();
              //    ^
              // the indicated position is within the scope of the local
              // function but it is also the position for the invocation of it.
              // Allow name to be either from the local or from its calling
              // context.
              if (innerElement.isLocal && innerElement.isFunction) {
                var enclosingElement = innerElement.enclosingElement;
                String expectedName2 =
                    computeElementNameForSourceMaps(enclosingElement);
                Expect.isTrue(
                    name == expectedName2,
                    "Unexpected name '${name}', "
                    "expected '${expectedName}' for $innerElement "
                    "or '${expectedName2}' for $enclosingElement.");
              } else {
                Expect.equals(
                    expectedName,
                    name,
                    "Unexpected name '${name}', "
                    "expected '${expectedName}' or for $innerElement.");
              }
            }
          }
        }

        compilationUnit.forEachLocalMember((AstElement element) {
          if (element.isClass) {
            ClassElement classElement = element;
            classElement.forEachLocalMember(match);
          } else {
            match(element);
          }
        });
      }
    }
  });
}

RegExp mainSignaturePrefix = new RegExp(r'main: \[?function\(');

// Check that the line pointing to by [mainPosition] in [mainUri] contains
// the main function signature.
checkMainPosition(Uri targetUri, List<String> targetLines,
    SingleMapping sourceMap, Uri mainUri, Position mainPosition) {
  bool mainPositionFound = false;
  sourceMap.lines.forEach((TargetLineEntry lineEntry) {
    lineEntry.entries.forEach((TargetEntry entry) {
      if (entry.sourceLine == null || entry.sourceUrlId == null) return;
      Uri sourceUri = targetUri.resolve(sourceMap.urls[entry.sourceUrlId]);
      if (sourceUri != mainUri) return;
      if (entry.sourceLine + 1 == mainPosition.line &&
          entry.sourceColumn + 1 == mainPosition.column) {
        Expect.isNotNull(entry.sourceNameId, "Main position has no name.");
        String name = sourceMap.names[entry.sourceNameId];
        Expect.equals(
            'main', name, "Main position name is not '$name', not 'main'.");
        String line = targetLines[lineEntry.line];
        Expect.isTrue(
            line.contains(mainSignaturePrefix),
            "Line mapped to main position "
            "([${lineEntry.line + 1},${entry.column + 1}]) "
            "expected to contain '${mainSignaturePrefix.pattern}':\n$line\n");
        mainPositionFound = true;
      }
    });
  });
  Expect.isTrue(
      mainPositionFound, 'No main position $mainPosition found in $mainUri');
}

sameSourcePoint(TargetEntry entry, TargetEntry otherEntry) {
  return (entry.sourceUrlId == otherEntry.sourceUrlId) &&
      (entry.sourceLine == otherEntry.sourceLine) &&
      (entry.sourceColumn == otherEntry.sourceColumn) &&
      (entry.sourceNameId == otherEntry.sourceNameId);
}

Uri getMapUri(Uri targetUri) {
  print('Accessing $targetUri');
  File targetFile = new File.fromUri(targetUri);
  Expect.isTrue(targetFile.existsSync(), "File '$targetUri' doesn't exist.");
  List<String> target = targetFile.readAsStringSync().split('\n');
  String mapReference = target[target.length - 2]; // #sourceMappingURL=<url>
  Expect.isTrue(mapReference.startsWith('//# sourceMappingURL='));
  String mapName = mapReference.substring(mapReference.indexOf('=') + 1);
  return targetUri.resolve(mapName);
}

SingleMapping getSourceMap(Uri mapUri) {
  print('Accessing $mapUri');
  File mapFile = new File.fromUri(mapUri);
  Expect.isTrue(mapFile.existsSync());
  return new SingleMapping.fromJson(JSON.decode(mapFile.readAsStringSync()));
}

copyDirectory(Directory sourceDir, Directory destinationDir) {
  sourceDir.listSync().forEach((FileSystemEntity element) {
    String newPath =
        path.join(destinationDir.path, path.basename(element.path));
    if (element is File) {
      element.copySync(newPath);
    } else if (element is Directory) {
      Directory newDestinationDir = new Directory(newPath);
      newDestinationDir.createSync();
      copyDirectory(element, newDestinationDir);
    }
  });
}

Future<Directory> createTempDir() {
  return Directory.systemTemp
      .createTemp('sourceMap_test-')
      .then((Directory dir) {
    return dir;
  });
}

class Position {
  final int line;
  final int column;

  const Position(this.line, this.column);

  bool operator <=(Position other) {
    return line < other.line || line == other.line && column <= other.column;
  }

  String toString() => '[${line + 1},${column + 1}]';
}

class Interval {
  final Position begin;
  final Position end;

  Interval(this.begin, this.end);

  bool contains(Position other) {
    return begin <= other && other <= end;
  }

  String toString() => '$begin-$end';
}
