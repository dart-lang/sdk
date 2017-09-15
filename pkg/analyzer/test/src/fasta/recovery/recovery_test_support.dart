// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:test/test.dart';

import '../../../generated/parser_fasta_test.dart';

/**
 * The base class for tests that test how well Fasta recovers from various
 * syntactic errors.
 */
abstract class AbstractRecoveryTest extends FastaParserTestCase {
  void testRecovery(
      String invalidCode, List<ParserErrorCode> errorCodes, String validCode) {
    CompilationUnit invalidUnit = parseCompilationUnit(invalidCode, errorCodes);
    CompilationUnit validUnit = parseCompilationUnit(validCode);
    ResultComparator.compare(invalidUnit, validUnit);
  }
}

class ResultComparator extends AstComparator {
  bool failDifferentLength(List first, List second) {
    // TODO(brianwilkerson) Provide context for where the lists are located.
    fail(
        'Expected a list of length ${second.length}; found a list of length ${first.length}');
    return false;
  }

  @override
  bool failIfNotNull(Object first, Object second) {
    if (second != null) {
      // TODO(brianwilkerson) Provide context for where the nodes are located.
      fail('Expected null; found a ${first.runtimeType}');
    }
    return true;
  }

  @override
  bool failIsNull(Object first, Object second) {
    // TODO(brianwilkerson) Provide context for where the nodes are located.
    fail('Expected a ${second.runtimeType}; found null');
    return false;
  }

  @override
  bool failRuntimeType(Object first, Object second) {
    // TODO(brianwilkerson) Provide context for where the nodes are located.
    fail('Expected a ${second.runtimeType}; found ${first.runtimeType}');
    return false;
  }

  /**
   * Overridden to allow the valid code to contain an explicit identifier where
   * a synthetic identifier is expected to be inserted by recovery.
   */
  @override
  bool isEqualNodes(AstNode first, AstNode second) {
    if (first is SimpleIdentifier && second is SimpleIdentifier) {
      if (first.isSynthetic && second.name == '_s_') {
        return true;
      }
    }
    return super.isEqualNodes(first, second);
  }

  /**
   * Overridden to ignore the offsets of tokens because these can legitimately
   * be different.
   */
  @override
  bool isEqualTokensNotNull(Token first, Token second) =>
      first.length == second.length && first.lexeme == second.lexeme;

  /**
   * Compare the [first] and [second] nodes, failing the test if they are
   * different.
   */
  static void compare(AstNode first, AstNode second) {
    ResultComparator comparator = new ResultComparator();
    comparator.isEqualNodes(first, second);
  }
}
