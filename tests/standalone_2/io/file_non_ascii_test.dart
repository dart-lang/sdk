// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() {
  asyncStart();

  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);

  Directory.systemTemp.createTemp('dart_file_non_ascii').then((tempDir) {
    Directory nonAsciiDir = new Directory('${tempDir.path}/æøå');
    nonAsciiDir.create().then((nonAsciiDir) {
      nonAsciiDir.exists().then((result) {
        Expect.isTrue(result);
        File nonAsciiFile = new File('${nonAsciiDir.path}/æøå.txt');
        nonAsciiFile.writeAsString('æøå').then((_) {
          nonAsciiFile.exists().then((result) {
            Expect.isTrue(result);
            nonAsciiFile.readAsString().then((contents) {
              // The contents of the file is precomposed utf8.
              Expect.equals(precomposed, contents);
              nonAsciiFile.create().then((_) {
                var d = nonAsciiFile.parent;
                Expect.isTrue(d.path.endsWith(precomposed) ||
                    d.path.endsWith(decomposed));
                nonAsciiFile.length().then((length) {
                  Expect.equals(6, length);
                  nonAsciiFile.lastModified().then((_) {
                    nonAsciiFile.resolveSymbolicLinks().then((path) {
                      Expect.isTrue(path.endsWith('${precomposed}.txt') ||
                          path.endsWith('${decomposed}.txt'));
                      tempDir.delete(recursive: true).then((_) {
                        asyncEnd();
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
  }).catchError((e) {
    Expect.fail("File not found");
  });
}
