// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Tests for [PathMapper]. */
library path_info_test;

import 'package:path/path.dart' as path;
import 'package:polymer/src/info.dart';
import 'package:polymer/src/paths.dart';
import 'package:polymer/src/utils.dart' as utils;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useCompactVMConfiguration();
  group('outdir == basedir:', () {
    setUp(() {
      utils.path = new path.Builder(style: path.Style.posix);
    });

    tearDown(() {
      utils.path = new path.Builder();
    });

    group('outputPath', () {
      test('mangle automatic', () {
        var pathMapper = _newPathMapper('a', 'a', false);
        var file = _mockFile('a/b.dart', pathMapper);
        expect(file.dartCodeUrl.resolvedPath, 'a/b.dart');
        expect(pathMapper.outputPath(file.dartCodeUrl.resolvedPath, '.dart'),
            'a/_b.dart.dart');
      });

      test('within packages/', () {
        var pathMapper = _newPathMapper('a', 'a', false);
        var file = _mockFile('a/packages/b.dart', pathMapper);
        expect(file.dartCodeUrl.resolvedPath, 'a/packages/b.dart');
        expect(pathMapper.outputPath(file.dartCodeUrl.resolvedPath, '.dart'),
            'a/_from_packages/_b.dart.dart');
      });
    });

    group('importUrlFor', () {
      test('simple pathMapper', () {
        var pathMapper = _newPathMapper('a', 'a', false);
        var file1 = _mockFile('a/b.dart', pathMapper);
        var file2 = _mockFile('a/c/d.dart', pathMapper);
        var file3 = _mockFile('a/e/f.dart', pathMapper);
        expect(pathMapper.importUrlFor(file1, file2), 'c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file1, file3), 'e/_f.dart.dart');
        expect(pathMapper.importUrlFor(file2, file1), '../_b.dart.dart');
        expect(pathMapper.importUrlFor(file2, file3), '../e/_f.dart.dart');
        expect(pathMapper.importUrlFor(file3, file2), '../c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file3, file1), '../_b.dart.dart');
      });

      test('include packages/', () {
        var pathMapper = _newPathMapper('a', 'a', false);
        var file1 = _mockFile('a/b.dart', pathMapper);
        var file2 = _mockFile('a/c/d.dart', pathMapper);
        var file3 = _mockFile('a/packages/f.dart', pathMapper);
        expect(pathMapper.importUrlFor(file1, file2), 'c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file1, file3),
            '_from_packages/_f.dart.dart');
        expect(pathMapper.importUrlFor(file2, file1), '../_b.dart.dart');
        expect(pathMapper.importUrlFor(file2, file3),
            '../_from_packages/_f.dart.dart');
        expect(pathMapper.importUrlFor(file3, file2), '../c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file3, file1), '../_b.dart.dart');
      });

      test('packages, but no rewrite', () {
        var pathMapper = _newPathMapper('a', 'a', false, rewriteUrls: false);
        var file1 = _mockFile('a/b.dart', pathMapper);
        var file2 = _mockFile('a/c/d.dart', pathMapper);
        var file3 = _mockFile('a/packages/c/f.dart', pathMapper,
            url: 'package:e/f.dart');
        expect(pathMapper.importUrlFor(file1, file2), 'c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file1, file3),
          'package:e/_f.dart.dart');
        expect(pathMapper.importUrlFor(file2, file1), '../_b.dart.dart');
        expect(pathMapper.importUrlFor(file2, file3),
            'package:e/_f.dart.dart');
      });

      test('windows paths', () {
        try {
          utils.path = new path.Builder(style: path.Style.windows);
          var pathMapper = _newPathMapper('a', 'a', false);
          var file1 = _mockFile('a\\b.dart', pathMapper);
          var file2 = _mockFile('a\\c\\d.dart', pathMapper);
          var file3 = _mockFile('a\\packages\\f.dart', pathMapper);
          expect(pathMapper.importUrlFor(file1, file2), 'c/_d.dart.dart');
          expect(pathMapper.importUrlFor(file1, file3),
              '_from_packages/_f.dart.dart');
          expect(pathMapper.importUrlFor(file2, file1), '../_b.dart.dart');
          expect(pathMapper.importUrlFor(file2, file3),
              '../_from_packages/_f.dart.dart');
          expect(pathMapper.importUrlFor(file3, file2), '../c/_d.dart.dart');
          expect(pathMapper.importUrlFor(file3, file1), '../_b.dart.dart');
        } finally {
          utils.path = new path.Builder();
        }
      });
    });

    test('transformUrl simple paths', () {
      var pathMapper = _newPathMapper('a', 'a', false);
      var file1 = 'a/b.dart';
      var file2 = 'a/c/d.html';
      // when the output == input directory, no paths should be rewritten
      expect(pathMapper.transformUrl(file1, '/a.dart'), '/a.dart');
      expect(pathMapper.transformUrl(file1, 'c.dart'), 'c.dart');
      expect(pathMapper.transformUrl(file1, '../c/d.dart'), '../c/d.dart');
      expect(pathMapper.transformUrl(file1, 'packages/c.dart'),
          'packages/c.dart');
      expect(pathMapper.transformUrl(file2, 'e.css'), 'e.css');
      expect(pathMapper.transformUrl(file2, '../c/e.css'), 'e.css');
      expect(pathMapper.transformUrl(file2, '../q/e.css'), '../q/e.css');
      expect(pathMapper.transformUrl(file2, 'packages/c.css'),
          'packages/c.css');
      expect(pathMapper.transformUrl(file2, '../packages/c.css'),
          '../packages/c.css');
    });

    test('transformUrl with source in packages/', () {
      var pathMapper = _newPathMapper('a', 'a', false);
      var file = 'a/packages/e.html';
      // Even when output == base, files under packages/ are moved to
      // _from_packages, so all imports are affected:
      expect(pathMapper.transformUrl(file, 'e.css'), '../packages/e.css');
      expect(pathMapper.transformUrl(file, '../packages/e.css'),
          '../packages/e.css');
      expect(pathMapper.transformUrl(file, '../q/e.css'), '../q/e.css');
      expect(pathMapper.transformUrl(file, 'packages/c.css'),
          '../packages/packages/c.css');
    });
  });

  group('outdir != basedir:', () {
    group('outputPath', (){
      test('no force mangle', () {
        var pathMapper = _newPathMapper('a', 'out', false);
        var file = _mockFile('a/b.dart', pathMapper);
        expect(file.dartCodeUrl.resolvedPath, 'a/b.dart');
        expect(pathMapper.outputPath(file.dartCodeUrl.resolvedPath, '.dart'),
            'out/b.dart');
      });

      test('force mangling', () {
        var pathMapper = _newPathMapper('a', 'out', true);
        var file = _mockFile('a/b.dart', pathMapper);
        expect(file.dartCodeUrl.resolvedPath, 'a/b.dart');
        expect(pathMapper.outputPath(file.dartCodeUrl.resolvedPath, '.dart'),
            'out/_b.dart.dart');
      });

      test('within packages/, no mangle', () {
        var pathMapper = _newPathMapper('a', 'out', false);
        var file = _mockFile('a/packages/b.dart', pathMapper);
        expect(file.dartCodeUrl.resolvedPath, 'a/packages/b.dart');
        expect(pathMapper.outputPath(file.dartCodeUrl.resolvedPath, '.dart'),
            'out/_from_packages/b.dart');
      });

      test('within packages/, mangle', () {
        var pathMapper = _newPathMapper('a', 'out', true);
        var file = _mockFile('a/packages/b.dart', pathMapper);
        expect(file.dartCodeUrl.resolvedPath, 'a/packages/b.dart');
        expect(pathMapper.outputPath(file.dartCodeUrl.resolvedPath, '.dart'),
            'out/_from_packages/_b.dart.dart');
      });
    });

    group('importUrlFor', (){
      test('simple paths, no mangle', () {
        var pathMapper = _newPathMapper('a', 'out', false);
        var file1 = _mockFile('a/b.dart', pathMapper);
        var file2 = _mockFile('a/c/d.dart', pathMapper);
        var file3 = _mockFile('a/e/f.dart', pathMapper);
        expect(pathMapper.importUrlFor(file1, file2), 'c/d.dart');
        expect(pathMapper.importUrlFor(file1, file3), 'e/f.dart');
        expect(pathMapper.importUrlFor(file2, file1), '../b.dart');
        expect(pathMapper.importUrlFor(file2, file3), '../e/f.dart');
        expect(pathMapper.importUrlFor(file3, file2), '../c/d.dart');
        expect(pathMapper.importUrlFor(file3, file1), '../b.dart');
      });

      test('simple paths, mangle', () {
        var pathMapper = _newPathMapper('a', 'out', true);
        var file1 = _mockFile('a/b.dart', pathMapper);
        var file2 = _mockFile('a/c/d.dart', pathMapper);
        var file3 = _mockFile('a/e/f.dart', pathMapper);
        expect(pathMapper.importUrlFor(file1, file2), 'c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file1, file3), 'e/_f.dart.dart');
        expect(pathMapper.importUrlFor(file2, file1), '../_b.dart.dart');
        expect(pathMapper.importUrlFor(file2, file3), '../e/_f.dart.dart');
        expect(pathMapper.importUrlFor(file3, file2), '../c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file3, file1), '../_b.dart.dart');
      });

      test('include packages/, no mangle', () {
        var pathMapper = _newPathMapper('a', 'out', false);
        var file1 = _mockFile('a/b.dart', pathMapper);
        var file2 = _mockFile('a/c/d.dart', pathMapper);
        var file3 = _mockFile('a/packages/e/f.dart', pathMapper,
            url: 'package:e/f.dart');
        expect(pathMapper.importUrlFor(file1, file2), 'c/d.dart');
        expect(pathMapper.importUrlFor(file1, file3),
            '_from_packages/e/f.dart');
        expect(pathMapper.importUrlFor(file2, file1), '../b.dart');
        expect(pathMapper.importUrlFor(file2, file3),
            '../_from_packages/e/f.dart');
        expect(pathMapper.importUrlFor(file3, file2), '../../c/d.dart');
        expect(pathMapper.importUrlFor(file3, file1), '../../b.dart');
      });

      test('include packages/, mangle', () {
        var pathMapper = _newPathMapper('a', 'out', true);
        var file1 = _mockFile('a/b.dart', pathMapper);
        var file2 = _mockFile('a/c/d.dart', pathMapper);
        var file3 = _mockFile('a/packages/e/f.dart', pathMapper,
            url: 'package:e/f.dart');
        expect(pathMapper.importUrlFor(file1, file2), 'c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file1, file3),
          '_from_packages/e/_f.dart.dart');
        expect(pathMapper.importUrlFor(file2, file1), '../_b.dart.dart');
        expect(pathMapper.importUrlFor(file2, file3),
            '../_from_packages/e/_f.dart.dart');
        expect(pathMapper.importUrlFor(file3, file2), '../../c/_d.dart.dart');
        expect(pathMapper.importUrlFor(file3, file1), '../../_b.dart.dart');
      });

      test('windows paths', () {
        try {
          utils.path = new path.Builder(style: path.Style.windows);
          var pathMapper = _newPathMapper('a', 'out', true);
          var file1 = _mockFile('a\\b.dart', pathMapper);
          var file2 = _mockFile('a\\c\\d.dart', pathMapper);
          var file3 = _mockFile('a\\packages\\f.dart', pathMapper);
          expect(pathMapper.importUrlFor(file1, file2), 'c/_d.dart.dart');
          expect(pathMapper.importUrlFor(file1, file3),
              '_from_packages/_f.dart.dart');
          expect(pathMapper.importUrlFor(file2, file1), '../_b.dart.dart');
          expect(pathMapper.importUrlFor(file2, file3),
              '../_from_packages/_f.dart.dart');
          expect(pathMapper.importUrlFor(file3, file2), '../c/_d.dart.dart');
          expect(pathMapper.importUrlFor(file3, file1), '../_b.dart.dart');
        } finally {
          utils.path = new path.Builder();
        }
      });
    });

    group('transformUrl', () {
      test('simple source, not in packages/', () {
        var pathMapper = _newPathMapper('a', 'out', false);
        var file1 = 'a/b.dart';
        var file2 = 'a/c/d.html';
        // when the output == input directory, no paths should be rewritten
        expect(pathMapper.transformUrl(file1, '/a.dart'), '/a.dart');
        expect(pathMapper.transformUrl(file1, 'c.dart'), '../a/c.dart');

        // reach out from basedir:
        expect(pathMapper.transformUrl(file1, '../c/d.dart'), '../c/d.dart');

        // reach into packages dir:
        expect(pathMapper.transformUrl(file1, 'packages/c.dart'),
            '../a/packages/c.dart');

        expect(pathMapper.transformUrl(file2, 'e.css'), '../../a/c/e.css');

        _checkPath('../../a/c/../c/e.css', '../../a/c/e.css');
        expect(pathMapper.transformUrl(file2, '../c/e.css'), '../../a/c/e.css');

        _checkPath('../../a/c/../q/e.css', '../../a/q/e.css');
        expect(pathMapper.transformUrl(file2, '../q/e.css'), '../../a/q/e.css');

        expect(pathMapper.transformUrl(file2, 'packages/c.css'),
            '../../a/c/packages/c.css');
        _checkPath('../../a/c/../packages/c.css', '../../a/packages/c.css');
        expect(pathMapper.transformUrl(file2, '../packages/c.css'),
            '../../a/packages/c.css');
      });

      test('input in packages/', () {
        var pathMapper = _newPathMapper('a', 'out', true);
        var file = 'a/packages/e.html';
        expect(pathMapper.transformUrl(file, 'e.css'),
            '../../a/packages/e.css');
        expect(pathMapper.transformUrl(file, '../packages/e.css'),
            '../../a/packages/e.css');
        expect(pathMapper.transformUrl(file, '../q/e.css'), '../../a/q/e.css');
        expect(pathMapper.transformUrl(file, 'packages/c.css'),
            '../../a/packages/packages/c.css');
      });

      test('src fragments', () {
        var pathMapper = _newPathMapper('a', 'out', false);
        var file1 = 'a/b.dart';
        var file2 = 'a/c/html.html';
        // when the output == input directory, no paths should be rewritten
        expect(pathMapper.transformUrl(file1, '#tips'), '#tips');
        expect(pathMapper.transformUrl(file1,
            'http://www.w3schools.com/html_links.htm#tips'),
            'http://www.w3schools.com/html_links.htm#tips');
        expect(pathMapper.transformUrl(file2,
          'html_links.html'),
          '../../a/c/html_links.html');
        expect(pathMapper.transformUrl(file2,
            'html_links.html#tips'),
            '../../a/c/html_links.html#tips');
      });
    });
  });
}

_newPathMapper(String baseDir, String outDir, bool forceMangle,
    {bool rewriteUrls: true}) =>
  new PathMapper(baseDir, outDir, 'packages', forceMangle, rewriteUrls);

_mockFile(String filePath, PathMapper pathMapper, {String url}) {
  var file = new FileInfo(new UrlInfo(
        url == null ? filePath : url, filePath, null));
  file.outputFilename = pathMapper.mangle(
      utils.path.basename(filePath), '.dart', false);
  return file;
}

_checkPath(String filePath, String expected) {
  expect(utils.path.normalize(filePath), expected);
}
