// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:test/test.dart';

import '../recovery_test_support.dart';

/**
 * A base class that adds support for tests that test how well the parser
 * recovers when the user has entered an incomplete (but otherwise correct)
 * construct (such as a top-level declaration, class member, or statement).
 *
 * Because users often add new constructs between two existing constructs, these
 * tests effectively test whether the parser is able to recognize where the
 * partially entered construct ends and where the next fully entered construct
 * begins. (The preceding construct is irrelevant.) Given the large number of
 * following constructs the are valid in most contexts, these tests are designed
 * to programmatically generate tests based on a list of possible following
 * constructs.
 */
abstract class PartialCodeTest extends AbstractRecoveryTest {
  /**
   * A list of suffixes that can be used by tests of class members.
   */
  static final List<TestSuffix> classMemberSuffixes = <TestSuffix>[
    new TestSuffix('field', 'var f;'),
    new TestSuffix('fieldConst', 'const f;'),
    new TestSuffix('fieldFinal', 'final f;'),
    new TestSuffix('methodNonVoid', 'int a(b) => 0;'),
    new TestSuffix('methodVoid', 'void a(b) {}'),
    new TestSuffix('getter', 'int get a => 0;'),
    new TestSuffix('setter', 'set a(b) {}')
  ];

  /**
   * A list of suffixes that can be used by tests of top-level constructs that
   * can validly be followed by any declaration.
   */
  static final List<TestSuffix> declarationSuffixes = <TestSuffix>[
    new TestSuffix('class', 'class A {}'),
    new TestSuffix('typedef', 'typedef A = B Function(C, D);'),
    new TestSuffix('functionVoid', 'void f() {}'),
    new TestSuffix('functionNonVoid', 'int f() {}'),
    new TestSuffix('var', 'var a;'),
    new TestSuffix('const', 'const a;'),
    new TestSuffix('final', 'final a;'),
    new TestSuffix('getter', 'int get a => 0;'),
    new TestSuffix('setter', 'set a(b) {}')
  ];

  /**
   * A list of suffixes that can be used by tests of top-level constructs that
   * can validly be followed by anything that is valid after a part directive.
   */
  static final List<TestSuffix> postPartSuffixes = <TestSuffix>[
    new TestSuffix('part', "part 'a.dart';")
  ]..addAll(declarationSuffixes);

  /**
   * A list of suffixes that can be used by tests of top-level constructs that
   * can validly be followed by any directive or declaration other than a
   * library directive.
   */
  static final List<TestSuffix> prePartSuffixes = <TestSuffix>[
    new TestSuffix('import', "import 'a.dart';"),
    new TestSuffix('export', "export 'a.dart';")
  ]..addAll(postPartSuffixes);

  /**
   * A list of suffixes that can be used by tests of statements.
   */
  static final List<TestSuffix> statementSuffixes = <TestSuffix>[
    new TestSuffix('assert', "assert (true);"),
    new TestSuffix('block', "{}"),
    new TestSuffix('break', "break;"),
    new TestSuffix('continue', "continue;"),
    new TestSuffix('do', "do {} while (true);"),
    new TestSuffix('if', "if (true) {}"),
    new TestSuffix('for', "for (var x in y) {}"),
    new TestSuffix('labeled', "l: {}"),
    new TestSuffix('localFunctionNonVoid', "int f() {}"),
    new TestSuffix('localFunctionVoid', "void f() {}"),
    new TestSuffix('localVariable', "var x;"),
    new TestSuffix('switch', "switch (x) {}"),
    new TestSuffix('try', "try {} finally {}"),
    new TestSuffix('return', "return;"),
    new TestSuffix('while', "while (true) {}"),
  ];

  /**
   * Build a group of tests with the given [groupName]. There will be one test
   * for every combination of elements in the cross-product of the lists of
   * [descriptors] and [suffixes], and one additional test for every descriptor
   * where the suffix is the empty string (to test partial declarations at the
   * end of the file). In total, there will be
   * `descriptors.length * (suffixes.length + 1)` tests generated.
   */
  buildTests(String groupName, List<TestDescriptor> descriptors,
      List<TestSuffix> suffixes,
      {String head, String tail}) {
    group(groupName, () {
      for (TestDescriptor descriptor in descriptors) {
        _buildTestForDescriptorAndSuffix(
            descriptor, TestSuffix.eof, 0, head, tail);
        for (int i = 0; i < suffixes.length; i++) {
          _buildTestForDescriptorAndSuffix(
              descriptor, suffixes[i], i + 1, head, tail);
        }
      }
    });
  }

  /**
   * Build a single test based on the given [descriptor] and [suffix].
   */
  _buildTestForDescriptorAndSuffix(TestDescriptor descriptor, TestSuffix suffix,
      int suffixIndex, String head, String tail) {
    test('${descriptor.name}_${suffix.name}', () {
      //
      // Compose the invalid and valid pieces of code.
      //
      StringBuffer invalid = new StringBuffer();
      StringBuffer valid = new StringBuffer();
      if (head != null) {
        invalid.write(head);
        valid.write(head);
      }
      invalid.write(descriptor.invalid);
      valid.write(descriptor.valid);
      if (suffix.text.isNotEmpty) {
        invalid.write(' ');
        invalid.write(suffix.text);
        valid.write(' ');
        valid.write(suffix.text);
      }
      if (tail != null) {
        invalid.write(tail);
        valid.write(tail);
      }
      //
      // Run the test.
      //
      List<bool> failing = descriptor.failing;
      if (descriptor.allFailing || (failing != null && failing[suffixIndex])) {
        bool failed = false;
        try {
          testRecovery(
              invalid.toString(), descriptor.errorCodes, valid.toString());
          failed = true;
        } catch (e) {
          // Expected to fail.
        }
        if (failed) {
          fail('Expected to fail, but passed');
        }
      } else {
        testRecovery(
            invalid.toString(), descriptor.errorCodes, valid.toString());
      }
    });
  }
}

/**
 * A description of a set of tests that are to be built.
 */
class TestDescriptor {
  /**
   * The name of the test.
   */
  final String name;

  /**
   * Invalid code that the parser is expected to recover from.
   */
  final String invalid;

  /**
   * Error codes that the parser is expected to produce.
   */
  final List<ErrorCode> errorCodes;

  /**
   * Valid code that is equivalent to what the parser should produce as part of
   * recovering from the invalid code.
   */
  final String valid;

  /**
   * A flag indicating whether all of the tests are expected to fail.
   */
  final bool allFailing;

  /**
   * A list containing one flag per expected test that indicates whether that
   * specific test is expected to fail.
   */
  final List<bool> failing;

  /**
   * Initialize a newly created test descriptor.
   */
  TestDescriptor(this.name, this.invalid, this.errorCodes, this.valid,
      {this.allFailing: false, this.failing});
}

/**
 * A description of a set of suffixes that are to be used to construct tests.
 */
class TestSuffix {
  static final TestSuffix eof = new TestSuffix('eof', '');

  /**
   * The name of the suffix.
   */
  final String name;

  /**
   * The code to be appended to the test code.
   */
  final String text;

  /**
   * Initialize a newly created suffix.
   */
  TestSuffix(this.name, this.text);
}
