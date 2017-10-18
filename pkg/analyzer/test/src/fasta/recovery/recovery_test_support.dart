// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:test/test.dart';

import '../../../generated/parser_fasta_test.dart';

/**
 * The base class for tests that test how well the parser recovers from various
 * syntactic errors.
 */
abstract class AbstractRecoveryTest extends FastaParserTestCase {
  void testRecovery(
      String invalidCode, List<ErrorCode> errorCodes, String validCode,
      {CompilationUnit adjustValidUnitBeforeComparison(CompilationUnit unit)}) {
    CompilationUnit invalidUnit = parseCompilationUnit(invalidCode, errorCodes);
    CompilationUnit validUnit = parseCompilationUnit(validCode);
    if (adjustValidUnitBeforeComparison != null) {
      validUnit = adjustValidUnitBeforeComparison(validUnit);
    }
    ResultComparator.compare(invalidUnit, validUnit);
  }
}

/**
 * An object used to compare to AST structures and cause the test to fail if
 * they differ in any important ways.
 */
class ResultComparator extends AstComparator {
  bool failDifferentLength(List first, List second) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Expected a list of length ');
    buffer.write(second.length);
    buffer.write('; found a list of length ');
    buffer.writeln(first.length);
    if (first is NodeList) {
      _safelyWriteNodePath(buffer, first.owner);
    }
    fail(buffer.toString());
    return false;
  }

  @override
  bool failIfNotNull(Object first, Object second) {
    if (second != null) {
      StringBuffer buffer = new StringBuffer();
      buffer.write('Expected null; found a ');
      buffer.writeln(second.runtimeType);
      if (second is AstNode) {
        _safelyWriteNodePath(buffer, second);
      }
      fail(buffer.toString());
    }
    return true;
  }

  @override
  bool failIsNull(Object first, Object second) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Expected a ');
    buffer.write(first.runtimeType);
    buffer.writeln('; found null');
    if (first is AstNode) {
      _safelyWriteNodePath(buffer, first);
    }
    fail(buffer.toString());
    return false;
  }

  @override
  bool failRuntimeType(Object first, Object second) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Expected a ');
    buffer.writeln(second.runtimeType);
    buffer.write('; found ');
    buffer.writeln(first.runtimeType);
    if (first is AstNode) {
      _safelyWriteNodePath(buffer, first);
    }
    fail(buffer.toString());
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
      (first.isSynthetic && first.type == second.type) ||
      (first.length == second.length && first.lexeme == second.lexeme);

  void _safelyWriteNodePath(StringBuffer buffer, AstNode node) {
    buffer.write('  path: ');
    if (node == null) {
      buffer.write(' null');
    } else {
      _writeNodePath(buffer, node);
    }
  }

  void _writeNodePath(StringBuffer buffer, AstNode node) {
    AstNode parent = node.parent;
    if (parent != null) {
      _writeNodePath(buffer, parent);
      buffer.write(', ');
    }
    buffer.write(node.runtimeType);
  }

  /**
   * Compare the [actual] and [expected] nodes, failing the test if they are
   * different.
   */
  static void compare(AstNode actual, AstNode expected) {
    ResultComparator comparator = new ResultComparator();
    if (!comparator.isEqualNodes(actual, expected)) {
      fail('Expected: $expected\n   Found: $actual');
    }
  }
}
