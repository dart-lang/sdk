// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.test.inherited_comments;

import 'dart:convert';
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

  test('inherited comments', () {
    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen([codeDir], out: p.join(d.defaultRoot, 'docs'));
    });

    schedule(() {
      var path = p.join(d.defaultRoot, 'docs', 'dart:core.Set.json');
      var dartCoreSetJson = new File(path).readAsStringSync();

      var dartCoreSet = JSON.decode(dartCoreSetJson) as Map<String, dynamic>;

      var toListDetails = dartCoreSet['inheritedMethods']['methods']['toList']
          as Map<String, dynamic>;

      expect(toListDetails, containsPair('comment', _TO_LIST_COMMENT));
      expect(toListDetails, containsPair('commentFrom', _TO_LIST_COMMENT_FROM));
    });
  });
}

const _TO_LIST_COMMENT = "<p>Creates a <a>dart:core.List</a> containing the "
    "elements of this <a>dart:core.Iterable</a>.</p>\n<p>The elements are in "
    "iteration order. The list is fixed-length\nif "
    "<a>dart:core.Set.toList.growable</a> is false.</p>";
const _TO_LIST_COMMENT_FROM = "dart:core.Iterable.toList";
