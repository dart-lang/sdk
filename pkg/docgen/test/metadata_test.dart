// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_await_test;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../lib/src/exports/mirrors_util.dart' as dart2js_util;
import '../lib/src/models/annotation.dart';
import '../lib/docgen.dart';

const Map<String, String> SOURCES = const <String, String>{
  'main.dart': '''
import 'lib.dart' as lib;

@lib.Annotation("foo", 42)
main() {
}
''',
  'lib.dart': '''
class Annotation {
  final String arg1;
  final int arg2;
  const Annotation(this.arg1, this.arg2);
}
'''};

main() {
  group('Generate docs for', () {
    test('files with annotations', () {
      var temporaryDir = Directory.systemTemp.createTempSync('metadata_');
      var uris = <Uri>[];
      SOURCES.forEach((name, code) {
        var fileName = path.join(temporaryDir.path, name);
        var file = new File(fileName);
        file.writeAsStringSync(code);
        uris.add(new Uri.file(fileName));
      });

      return getMirrorSystem(uris, false).then((mirrorSystem) {
        var library = new Library(mirrorSystem.libraries[uris[0]]);
        expect(library is Library, isTrue);

        var main = library.functions['main'];
        expect(main is Method, isTrue);

        var annotations = main.annotations;
        expect(annotations.length, equals(1));

        var annotation = annotations[0];
        expect(annotation is Annotation, isTrue);

        var map = annotation.toMap();
        expect(map['name'], equals('lib-dart.Annotation.Annotation-'));
        expect(map['parameters'].length, equals(2));
        expect(map['parameters'][0], equals('"foo"'));
        expect(map['parameters'][1], equals('42'));
      }).whenComplete(() => temporaryDir.deleteSync(recursive: true));
    });
  });
}
