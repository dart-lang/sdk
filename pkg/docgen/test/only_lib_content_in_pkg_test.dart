// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.test.only_lib_content_in_pkg;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import '../lib/docgen.dart' as dg;
import 'util.dart';

void main() {

  setUp(() {
    scheduleTempDir();
  });

  test('exclude non-lib code from package docs', () {
    schedule(() {
      var thisScript = Platform.script;
      var thisPath = p.fromUri(thisScript);
      expect(p.basename(thisPath), 'only_lib_content_in_pkg_test.dart');
      expect(p.dirname(thisPath), endsWith('test'));

      var packageRoot = Platform.packageRoot;
      if (packageRoot == '') packageRoot = null;

      var codeDir = p.normalize(p.join(thisPath, '..', '..'));
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen(['$codeDir/'], out: p.join(d.defaultRoot, 'docs'),
          packageRoot: packageRoot);
    });

    d.dir('docs', [
        d.dir('docgen', [
          d.matcherFile('docgen.json',  isJsonMap)
        ]),
        d.matcherFile('index.json', isJsonMap),
        d.matcherFile('index.txt', hasSortedLines),
        d.matcherFile('library_list.json', isJsonMap),
        d.nothing('test_lib.json'),
        d.nothing('test_lib-bar.json'),
        d.nothing('test_lib-foo.json')
    ]).validate();

  });
}
