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
  checkRedundancy(sourceMap);
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
