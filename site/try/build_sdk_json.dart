// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'package:compiler/src/util/uri_extras.dart' show relativize;

main(List<String> arguments) async {
  if (arguments.length == 0) {
    print('usage: build_sdk_json.dart <out-path>');
    exit(1);
  }

  var out = arguments[0];
  List<Uri> sdkFiles = await collectSdkFiles();
  new File(out).writeAsStringSync(emitSdkAsJson(sdkFiles));
}

Uri sdkRoot = Uri.base.resolveUri(Platform.script).resolve('../../');

/// Collects a list of files that are part of the SDK.
List<Uri> collectSdkFiles() {
  var files = <Uri>[];
  var sdkDir = new Directory.fromUri(sdkRoot.resolve('sdk/lib/'));
  for (var entity in sdkDir.listSync(recursive: true)) {
    if (entity is File &&
        (entity.path.endsWith('.dart') || entity.path.endsWith('.platform'))) {
      files.add(entity.uri);
    }
  }
  return files;
}

/// Creates a string that encodes the contents of the sdk libraries in json.
///
/// The keys of the json file are sdk-relative paths to source files, and the
/// values are the contents of the file.
String emitSdkAsJson(List<Uri> paths) {
  var map = <String, String>{};
  for (var uri in paths) {
    String filename = relativize(sdkRoot, uri, false);
    var contents = new File.fromUri(uri).readAsStringSync();
    map['sdk:/$filename'] = contents;
  }
  return JSON.encode(map);
}
