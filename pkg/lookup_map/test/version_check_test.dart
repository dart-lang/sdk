// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:mirrors';
import 'package:lookup_map/lookup_map.dart'; // accessed via mirrors;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// This dartdoc helps remove a warning for the unused import on [LookupMap].
main() {
  test('validate version number matches', () {
    var pubspec = Platform.script.resolve('../pubspec.yaml');
    var yaml = loadYaml(new File.fromUri(pubspec).readAsStringSync());
    var version1 = yaml['version'];
    var library = currentMirrorSystem().findLibrary(#lookup_map);
    var version2 = library.getField(new Symbol('_version')).reflectee;
    expect(version1, version2);
  });
}
