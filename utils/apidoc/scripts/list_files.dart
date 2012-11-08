// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Traverses apidoc and dartdoc and lists all possible input files that are
 * used when building API documentation. Used by gyp to determine when apidocs
 * need to be regenerated (see `apidoc.gyp`).
 */
#library('list_files');

#import('dart:io');

const allowedExtensions = const [
  '.css', '.dart', '.ico', '.js', '.json', '.png', '.sh', '.txt'
];

void main() {
  final scriptDir = new File(new Options().script).directorySync().path;
  final dartDir = '$scriptDir/../../../';
  listFiles('$dartDir/utils/apidoc');
  listFiles('$dartDir/sdk/lib/_internal/dartdoc');
}

void listFiles(String dirPath) {
  final dir = new Directory(dirPath);

  dir.onFile = (path) {
    if (allowedExtensions.indexOf(extension(path)) != -1) {
      print(path);
    }
  };

  dir.list(recursive: true);
}

String extension(String path) {
  int lastDot = path.lastIndexOf('.');
  if (lastDot == -1) return '';

  return path.substring(lastDot);
}
