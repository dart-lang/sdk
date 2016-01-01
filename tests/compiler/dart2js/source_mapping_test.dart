// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/io/code_output.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/js_emitter/full_emitter/emitter.dart'
    as full show Emitter;

import 'mock_compiler.dart';

Future<CodeBuffer> compileAll(SourceFile sourceFile) {
  MockCompiler compiler = new MockCompiler.internal();
  Uri uri = new Uri(path: sourceFile.filename);
  compiler.sourceFiles[uri.toString()] = sourceFile;
  JavaScriptBackend backend = compiler.backend;
  return compiler.run(uri).then((_) {
    // TODO(floitsch): the outputBuffers are only accessible in the full
    // emitter.
    full.Emitter fullEmitter = backend.emitter.emitter;
    return fullEmitter
        .outputBuffers[compiler.deferredLoadTask.mainOutputUnit];
  });
}

void testSourceMapLocations(String codeWithMarkers) {
  List<int> expectedLocations = new List<int>();
  for (int i = 0; i < codeWithMarkers.length; ++i) {
    if (codeWithMarkers[i] == '@') {
      expectedLocations.add(i - expectedLocations.length);
    }
  }
  String code = codeWithMarkers.replaceAll('@', '');

  SourceFile sourceFile = new StringSourceFile.fromName('<test script>', code);
  asyncTest(() => compileAll(sourceFile).then((CodeOutput output) {
    Set<int> locations = new Set<int>();
    output.forEachSourceLocation((int offset, SourceLocation sourcePosition) {
      if (sourcePosition != null &&
          sourcePosition.sourceUri == sourceFile.uri) {
        locations.add(sourcePosition.offset);
      }
    });

    for (int i = 0; i < expectedLocations.length; ++i) {
      int expectedLocation = expectedLocations[i];
      if (!locations.contains(expectedLocation)) {
        int originalLocation = expectedLocation + i;
        SourceFile sourceFileWithMarkers =
            new StringSourceFile.fromName('<test script>', codeWithMarkers);
        String message = sourceFileWithMarkers.getLocationMessage(
            'Missing location', originalLocation, originalLocation + 1);
        Expect.fail(message);
      }
    }
  }));
}

String FUNCTIONS_TEST = '''
@void main() { print(test(15)); @}
// The 'if' has been added to avoid inlining of 'test'.
@int test(int x) { if (x != null) return x; else return null; @}''';

String RETURN_TEST = 'void main() { print(((x) { @return x; })(0)); }';

String NOT_TEST = 'void main() { ((x) { if (@!x) print(x); })(1==2); }';

String UNARY_TEST = 'void main() { ((x, y) { print(@-x + @~y); })(1,2); }';

String BINARY_TEST = 'void main() { ((x, y) { if (x @!= y) print(x @* y); })(1,2); }';

String SEND_TEST = '''
void main() {
  @staticSend(0);
  NewSend o = @new NewSend();
  @o.dynamicSend(0);
  var closureSend = (x) { print(x); };
  @closureSend(0);
}
// The 'if' has been added to avoid inlining of 'staticSend'.
void staticSend(x) { if (x == null) return; print(x); }
class NewSend { void dynamicSend(x) { print(x); } }
''';

String SEND_SET_TEST = '''
String global;
void main() { @global = ''; print(new A().foo()); }
class A { int x; foo() { @x = 3; } }''';

String LOOP_TEST = '''
void main() {
  @for (int i = 0; i < 100; ++i) { print(test(13)); @}
}
int test(int x) {
  int result = 1; @while (result < x) { result <<= 1; @} return result;
}''';

String INTERCEPTOR_TEST = '''void main() { var l = []; @l.add(0); print(l); }
''';

main() {
  // These tests are fragile, since mappings for specific source locations
  // could disappear due to various optimizations like code elimination,
  // function inlining, etc. If you broke the test, please try to rewrite it
  // so that the new code is not optimized, otherwise just remove the marker
  // from problematic location.
  testSourceMapLocations(FUNCTIONS_TEST);
  testSourceMapLocations(RETURN_TEST);
  testSourceMapLocations(NOT_TEST);
  testSourceMapLocations(UNARY_TEST);
  testSourceMapLocations(BINARY_TEST);
  testSourceMapLocations(SEND_TEST);
  testSourceMapLocations(SEND_SET_TEST);
  testSourceMapLocations(LOOP_TEST);
  testSourceMapLocations(INTERCEPTOR_TEST);
}
