// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';

checkConsistency(Uri outUri) {
  print('Accessing $outUri');
  File sourceFile = new File.fromUri(outUri);
  Expect.isTrue(sourceFile.existsSync());
  String mapName = getMapReferenceFromJsOutput(sourceFile.readAsStringSync());
  Uri mapUri = outUri.resolve(mapName);
  print('Accessing $mapUri');
  File mapFile = new File.fromUri(mapUri);
  Expect.isTrue(mapFile.existsSync());
  SingleMapping sourceMap = new SingleMapping.fromJson(
      JSON.decode(mapFile.readAsStringSync()));
  Expect.equals(outUri, mapUri.resolve(sourceMap.targetUrl));
  print('Checking sources');
  sourceMap.urls.forEach((String url) {
    Expect.isTrue(new File.fromUri(mapUri.resolve(url)).existsSync());
  });
}

String getMapReferenceFromJsOutput(String file) {
  List<String> out = file.split('\n');
  String mapReference = out[out.length - 3]; // #sourceMappingURL=<url>
  Expect.isTrue(mapReference.startsWith('//# sourceMappingURL='));
  return mapReference.substring(mapReference.indexOf('=') + 1);
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