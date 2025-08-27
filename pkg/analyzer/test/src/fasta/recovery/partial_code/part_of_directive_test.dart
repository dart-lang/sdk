// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  PartOfDirectivesTest().buildAll();
}

class PartOfDirectivesTest extends PartialCodeTest {
  buildAll() {
    List<String> identifiers = const [
      'typedef',
      'functionNonVoid',
      'getter',
      'setter',
    ];
    List<TestSuffix> identifierSuffixes = PartialCodeTest.declarationSuffixes
        .where((t) => identifiers.contains(t.name))
        .toList();
    List<TestSuffix> nonIdentifierSuffixes = PartialCodeTest.declarationSuffixes
        .where((t) => !identifiers.contains(t.name))
        .toList();
    buildTests('part_of_directive', [
      TestDescriptor(
        'keyword',
        'part of',
        [ParserErrorCode.expectedStringLiteral, ParserErrorCode.expectedToken],
        'part of "";',
        failing: ['mixin'],
      ),
    ], nonIdentifierSuffixes);
    buildTests(
      'part_of_directive',
      [
        TestDescriptor(
          'keyword',
          'part of',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'part of _s_;',
          failing: ['functionNonVoid', 'getter'],
        ),
      ],
      identifierSuffixes,
      includeEof: false,
    );
    buildTests('part_of_directive', [
      TestDescriptor(
        'name',
        'part of lib',
        [ParserErrorCode.expectedToken],
        'library lib;',
        allFailing: true,
      ),
      TestDescriptor(
        'nameDot',
        'part of lib.',
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
        'part of lib._s_;',
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('nameDotName', 'part of lib.a', [
        ParserErrorCode.expectedToken,
      ], 'part of lib.a;'),
      TestDescriptor('emptyUri', "part of ''", [
        ParserErrorCode.expectedToken,
      ], "part of '';"),
      TestDescriptor('uri', "part of 'a.dart'", [
        ParserErrorCode.expectedToken,
      ], "part of 'a.dart';"),
    ], PartialCodeTest.declarationSuffixes);
  }
}
