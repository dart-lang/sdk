// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests for comment map.
library commentMapTests;

import 'dart:uri';
import 'dart:mirrors';

import '../../compiler/implementation/scanner/scannerlib.dart' as dart2js;

// TODO(rnystrom): Better path to unittest.
import '../../../../../pkg/unittest/lib/unittest.dart';

// TODO(rnystrom): Use "package:" URL (#4968).
part '../lib/src/dartdoc/comment_map.dart';

class FakeSourceLocation implements SourceLocation {
  Uri get sourceUri => new Uri('file:///tmp/test.dart');
  int get offset => 69;
  String get sourceText => """
    /// Testing
    ///     var testing = 'this is source code';
    get foo => 'bar';
  """;
}

main() {
  test('triple slashed comments retain newlines', () {
    Commentmap cm = new CommentMap();
    var comment = cm.find(new FakeSourceLocation());
    expect(
      comment,
      equals("Testing\n    var testing = 'this is source code';")
    );
  });
}
