// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.too_many_open_files_test;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();

  test("handles many simultaneous asset read() calls", () {
    runOnManyFiles((asset) => asset.read().toList());
  });

  test("handles many simultaneous asset readToString() calls", () {
    runOnManyFiles((asset) => asset.readAsString());
  });
}

runOnManyFiles(Future assetHandler(Asset asset)) {
  // Make a text file in a temp directory.
  var tempDir = Directory.systemTemp.createTempSync("barback").path;
  var filePath = pathos.join(tempDir, "out.txt");

  // Make sure it's large enough to not be read in a single chunk.
  var contents = new StringBuffer();
  for (var i = 0; i < 1024; i++) {
    contents.write(
        "this is a sixty four character long string that describes itself");
  }

  new File(filePath).writeAsStringSync(contents.toString());

  var id = new AssetId("myapp", "out.txt");

  // Create a large number of assets, larger than the file descriptor limit
  // of most machines and start reading from all of them.
  var futures = [];
  for (var i = 0; i < 1000; i++) {
    var asset = new Asset.fromPath(id, filePath);
    futures.add(assetHandler(asset));
  }

  expect(Future.wait(futures).whenComplete(() {
    new Directory(tempDir).delete(recursive: true);
  }), completes);
}