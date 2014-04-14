// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';

validateSourceMap(Uri targetUri) {
  Uri mapUri = getMapUri(targetUri);
  SingleMapping sourceMap = getSourceMap(mapUri);
  checkFileReferences(targetUri, mapUri, sourceMap);
  checkIndexReferences(targetUri, mapUri, sourceMap);
  checkRedundancy(sourceMap);
}

checkIndexReferences(Uri targetUri, Uri mapUri, SingleMapping sourceMap) {
  List<String> target =
      new File.fromUri(targetUri).readAsStringSync().split('\n');
  int urlsLength = sourceMap.urls.length;
  List<List<String>> sources = new List(urlsLength);
  print('Reading sources');
  for (int i = 0; i < urlsLength; i++) {
    sources[i] = new File.fromUri(mapUri.resolve(sourceMap.urls[i])).
        readAsStringSync().split('\n');
  }

  sourceMap.lines.forEach((TargetLineEntry line) {
    Expect.isTrue(line.line >= 0);
    Expect.isTrue(line.line < target.length);
    for (TargetEntry entry in line.entries) {
      int urlIndex = entry.sourceUrlId;

      // TODO(zarah): Entry columns sometimes point one or more characters too
      // far. Incomment this check when this is fixed.
      //
      // Expect.isTrue(entry.column < target[line.line].length);
      Expect.isTrue(entry.column >= 0);
      Expect.isTrue(urlIndex == null ||
          (urlIndex >= 0 && urlIndex < urlsLength));
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
        Expect.isFalse(sameSourcePoint(previous, next),
            '$previous and $next are consecutive entries on line $line in the '
            'source map but point to same source locations');
      }
      previous = next;
    }
  });
}

sameSourcePoint(TargetEntry entry, TargetEntry otherEntry) {
  return
      (entry.sourceUrlId == otherEntry.sourceUrlId) &&
      (entry.sourceLine == otherEntry.sourceLine) &&
      (entry.sourceColumn == otherEntry.sourceColumn) &&
      (entry.sourceNameId == otherEntry.sourceNameId);
}

Uri getMapUri(Uri targetUri) {
  print('Accessing $targetUri');
  File targetFile = new File.fromUri(targetUri);
  Expect.isTrue(targetFile.existsSync());
  List<String> target = targetFile.readAsStringSync().split('\n');
  String mapReference = target[target.length - 3]; // #sourceMappingURL=<url>
  Expect.isTrue(mapReference.startsWith('//# sourceMappingURL='));
  String mapName = mapReference.substring(mapReference.indexOf('=') + 1);
  return targetUri.resolve(mapName);
}

SingleMapping getSourceMap(Uri mapUri) {
  print('Accessing $mapUri');
  File mapFile = new File.fromUri(mapUri);
  Expect.isTrue(mapFile.existsSync());
  return new SingleMapping.fromJson(
      JSON.decode(mapFile.readAsStringSync()));
}

copyDirectory(Directory sourceDir, Directory destinationDir) {
  sourceDir.listSync().forEach((FileSystemEntity element) {
    String newPath = path.join(destinationDir.path,
                               path.basename(element.path));
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
