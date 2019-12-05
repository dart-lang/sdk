// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:test/test.dart';

import 'annotation.dart';
import 'annotation_matcher.dart';

void main() {
  test('extraction', () {
    expect(extractAnnotation('int x; // LINT [1:3]'), isNotNull);
    expect(extractAnnotation('int x; //LINT'), isNotNull);
    expect(extractAnnotation('int x; // OK'), isNull);
    expect(extractAnnotation('int x;'), isNull);
    expect(extractAnnotation('dynamic x; // LINT dynamic is bad').message,
        'dynamic is bad');
    expect(extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad').message,
        'dynamic is bad');
    expect(
        extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad').column, 1);
    expect(
        extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad').length, 3);
    expect(extractAnnotation('dynamic x; //LINT').message, isNull);
    expect(extractAnnotation('dynamic x; //LINT ').message, isNull);
    // Commented out lines shouldn't get linted.
    expect(extractAnnotation('// dynamic x; //LINT '), isNull);
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
