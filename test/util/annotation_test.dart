// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:test/test.dart';

import 'annotation.dart';
import 'annotation_matcher.dart';

void main() {
  test('extraction', () {
    expect(extractAnnotation(1, 'int x; // LINT [1:3]'), isNotNull);
    expect(extractAnnotation(1, 'int x; //LINT'), isNotNull);
    expect(extractAnnotation(1, 'int x; // OK'), isNull);
    expect(extractAnnotation(1, 'int x;'), isNull);
    expect(extractAnnotation(1, 'dynamic x; // LINT dynamic is bad').message,
        'dynamic is bad');
    expect(extractAnnotation(1, 'dynamic x; // LINT dynamic is bad').lineNumber,
        1);
    expect(
        extractAnnotation(1, 'dynamic x; // LINT [1:3] dynamic is bad').message,
        'dynamic is bad');
    expect(
        extractAnnotation(1, 'dynamic x; // LINT [1:3] dynamic is bad').column,
        1);
    expect(
        extractAnnotation(1, 'dynamic x; // LINT [1:3] dynamic is bad').length,
        3);
    expect(extractAnnotation(1, 'dynamic x; //LINT').message, isNull);
    expect(extractAnnotation(1, 'dynamic x; //LINT ').message, isNull);
    // Commented out lines shouldn't get linted.
    expect(extractAnnotation(1, '// dynamic x; //LINT '), isNull);
    expect(extractAnnotation(1, 'int x; // LINT [2:3]').lineNumber, 1);
    expect(extractAnnotation(1, 'int x; // LINT [2:3]').column, 2);
    expect(extractAnnotation(1, 'int x; // LINT [2:3]').length, 3);
    expect(extractAnnotation(1, 'int x; // LINT [+2]').lineNumber, 3);
    expect(extractAnnotation(1, 'int x; // LINT [+2]').column, isNull);
    expect(extractAnnotation(1, 'int x; // LINT [+2]').length, isNull);
    expect(extractAnnotation(1, 'int x; // LINT [+2,4:5]').lineNumber, 3);
    expect(extractAnnotation(1, 'int x; // LINT [+2,4:5]').column, 4);
    expect(extractAnnotation(1, 'int x; // LINT [+2,4:5]').length, 5);
    expect(extractAnnotation(10, 'int x; // LINT [-2]').lineNumber, 8);
  });

  test('equality', () {
    expect(Annotation('Actual message (to be ignored)', ErrorType.LINT, 1),
        matchesAnnotation(null, ErrorType.LINT, 1));
    expect(Annotation('Message', ErrorType.LINT, 1),
        matchesAnnotation('Message', ErrorType.LINT, 1));
  });

  test('inequality', () {
    expect(
        () => expect(Annotation('Message', ErrorType.LINT, 1),
            matchesAnnotation('Message', ErrorType.HINT, 1)),
        throwsA(TypeMatcher<TestFailure>()));
    expect(
        () => expect(Annotation('Message', ErrorType.LINT, 1),
            matchesAnnotation('Message2', ErrorType.LINT, 1)),
        throwsA(TypeMatcher<TestFailure>()));
    expect(
        () => expect(Annotation('Message', ErrorType.LINT, 1),
            matchesAnnotation('Message', ErrorType.LINT, 2)),
        throwsA(TypeMatcher<TestFailure>()));
  });
}
