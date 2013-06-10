// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/services/formatter.dart';
import 'package:analyzer_experimental/src/services/formatter_impl.dart';
import 'package:unittest/unittest.dart';

main() {

  /// Edit recorder tests
  group('edit recorder', () {

    test('countWhitespace', (){
      expect(newRecorder('   ').countWhitespace(), equals(3));
      expect(newRecorder('').countWhitespace(), equals(0));
      expect(newRecorder('  foo').countWhitespace(), equals(2));
    });

    test('indent', (){
      var recorder = newRecorder('');
      expect(recorder.indentationLevel, equals(0));
      expect(recorder.options.indentPerLevel, equals(2));
      recorder.indent();
      expect(recorder.indentationLevel, equals(2));
      expect(recorder.numberOfIndentations, equals(1));
    });

    test('isNewlineAt', (){
      expect(newRecorder('012\n').isNewlineAt(3), isTrue);
      expect(newRecorder('012\n3456').isNewlineAt(3), isTrue);
      expect(newRecorder('\n').isNewlineAt(0), isTrue);
    });

  });


  /// Formatter tests
  group('formatter', () {

    test('failedParse', () {
      var formatter = new CodeFormatter();
      expect(() => formatter.format(CodeKind.COMPILATION_UNIT, "~"),
                   throwsA(new isInstanceOf<FormatterException>('FE')));
    });

//    test('initialIndent', () {
//      var formatter = new CodeFormatter(new Options(initialIndentationLevel:2));
//      var formattedSource = formatter.format(CodeKind.STATEMENT, 'var x;');
//      expect(formattedSource, startsWith('  '));
//    });

  });

}

EditRecorder newRecorder(String source) {
  var recorder = new EditRecorder(new FormatterOptions());
  recorder.source = source;
  return recorder;
}
