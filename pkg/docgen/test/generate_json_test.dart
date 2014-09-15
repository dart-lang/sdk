// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.generate_json_test;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'util.dart';
import '../lib/docgen.dart' as dg;

void main() {

  setUp(() {
    scheduleTempDir();
  });

  test('json output', () {
    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen([codeDir], out: p.join(d.defaultRoot, 'docs'));
    });

    d.dir('docs', [
        d.matcherFile('index.json', isJsonMap),
        d.matcherFile('index.txt', hasSortedLines),
        d.matcherFile('library_list.json', isJsonMap),
        d.matcherFile('library_list.json',
            startsWith(_LIBRARY_LIST_UNINDENT_START)),
        d.matcherFile('sub_lib.json', isJsonMap),
        d.matcherFile('sub_lib.SubLibClass.json', isJsonMap),
        d.matcherFile('sub_lib.SubLibPart.json', isJsonMap),
        d.matcherFile('test_lib-bar.C.json', isJsonMap),
        d.matcherFile('test_lib-bar.json', isJsonMap),
        d.matcherFile('test_lib-foo.B.json', isJsonMap),
        d.matcherFile('test_lib-foo.json', isJsonMap),
        d.matcherFile('test_lib.A.json', isJsonMap),
        d.matcherFile('test_lib.B.json', isJsonMap),
        d.matcherFile('test_lib.C.json', isJsonMap),
        d.matcherFile('test_lib.json', isJsonMap),
    ]).validate();
  });
}

const _LIBRARY_LIST_UNINDENT_START = '{"libraries":[{"packageName":""';
