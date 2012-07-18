// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:uri');

#import("../../../lib/compiler/implementation/leg.dart");
#import('../../../lib/compiler/implementation/source_file.dart');
#import("mock_compiler.dart");
#import('parser_helper.dart');

List compileAll(SourceFile sourceFile) {
  MockCompiler compiler = new MockCompiler();
  Uri uri = new Uri(sourceFile.filename);
  compiler.sourceFiles[uri.toString()] = sourceFile;
  compiler.runCompiler(uri);
  return compiler.backend.emitter.sourceMapBuilder.entries;
}

void testSourceMapLocations(String codeWithMarkers) {
  List<int> expectedLocations = new List<int>();
  for (int i = 0; i < codeWithMarkers.length; ++i) {
    if (codeWithMarkers[i] == '@') {
      expectedLocations.add(i - expectedLocations.length);
    }
  }
  String code = codeWithMarkers.replaceAll('@', '');

  SourceFile sourceFile = new SourceFile('<test script>', code);
  List entries = compileAll(sourceFile);
  Set<int> locations = new Set<int>();
  for (var entry in entries) {
    if (entry.sourceFile == sourceFile) {
      locations.add(entry.sourceOffset);
    }
  }

  for (int i = 0; i < expectedLocations.length; ++i) {
    int expectedLocation = expectedLocations[i];
    if (!locations.contains(expectedLocation)) {
      int originalLocation = expectedLocation + i;
      SourceFile sourceFileWithMarkers = new SourceFile('<test script>',
                                                        codeWithMarkers);
      String message = sourceFileWithMarkers.getLocationMessage(
          'Missing location', originalLocation, originalLocation + 1, true,
          (s) => s);
      Expect.fail(message);
    }
  }
}

String FUNCTIONS_TEST = '''
@void main() { print(test(15)); @}
@int test(int x) { return x; @}''';

main() {
  // These tests are fragile, since mappings for specific source locations
  // could disappear due to various optimizations like code elimination,
  // function inlining, etc. If you broke the test, please try to rewrite it
  // so that the new code is not optimized, otherwise just remove the marker
  // from problematic location.
  testSourceMapLocations(FUNCTIONS_TEST);
}
