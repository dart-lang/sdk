// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:test/test.dart';

import '../../../generated/parser_test_base.dart';
import '../../../generated/test_support.dart';

/// The base class for tests that test how well the parser recovers from various
/// syntactic errors.
abstract class AbstractRecoveryTest extends FastaParserTestCase {
  void testRecovery(
    String invalidCode,
    List<DiagnosticCode>? diagnosticCodes,
    String validCode, {
    CompilationUnitImpl Function(CompilationUnitImpl unit)?
    adjustValidUnitBeforeComparison,
    List<DiagnosticCode>? expectedDiagnosticsInValidCode,
    FeatureSet? featureSet,
  }) {
    CompilationUnitImpl validUnit;

    // Assert that the valid code is indeed valid.
    try {
      validUnit = parseCompilationUnit(
        validCode,
        codes: expectedDiagnosticsInValidCode,
        featureSet: featureSet,
      );
      validateTokenStream(validUnit.beginToken);
    } catch (e) {
      //      print('');
      //      print('  Errors in valid code.');
      //      print('    Error: $e');
      //      print('    Code: $validCode');
      //      print('');
      rethrow;
    }

    // Compare the structures before asserting valid errors.
    GatheringDiagnosticListener listener = GatheringDiagnosticListener();
    var invalidUnit = parseCompilationUnit2(
      invalidCode,
      listener,
      featureSet: featureSet,
    );
    validateTokenStream(invalidUnit.beginToken);
    if (adjustValidUnitBeforeComparison != null) {
      validUnit = adjustValidUnitBeforeComparison(validUnit);
    }
    ResultComparator.compare(invalidUnit, validUnit);

    // Assert valid errors.
    if (diagnosticCodes != null) {
      listener.assertErrorsWithCodes(diagnosticCodes);
    } else {
      listener.assertNoErrors();
    }
  }

  void validateTokenStream(Token token) {
    while (!token.isEof) {
      Token next = token.next!;
      expect(token.end, lessThanOrEqualTo(next.offset));
      if (next.isSynthetic) {
        if (const [')', ']', '}'].contains(next.lexeme)) {
          expect(next.beforeSynthetic, token);
        }
      }
      token = next;
    }
  }
}

/// An object used to compare to AST structures and cause the test to fail if
/// they differ in any important ways.
class ResultComparator {
  /// Compares two lists in a syntax tree, and if they don't match, returns a
  /// description of how they fail to match.
  ///
  /// The two lists being compared might be lists of AST nodes or lists of
  /// tokens.
  _Mismatch? _compareLists({
    required List<Object?> actual,
    required List<Object?> expected,
  }) {
    int length = actual.length;
    if (expected.length != length) {
      return _failDifferentLength(actual: actual, expected: expected);
    }
    for (int i = 0; i < length; i++) {
      if (_compareTreeParts(actual: actual[i], expected: expected[i])
          case var mismatch?) {
        mismatch.reversePath.add(_IndexPathSegment(i));
        return mismatch;
      }
    }
    return null;
  }

  /// Compares two [AstNode]s in a syntax tree, and if they don't match, returns
  /// a description of how they fail to match. The caller should have already
  /// checked that the two nodes have the same [runtimeType].
  ///
  /// The nodes are compared by using [AstNodeImpl.namedChildEntities] to
  /// convert them each into a `Map<String, Object>`, whose keys typically match
  /// the names of syntactic getters, and whose values typically match the
  /// values returned by those getters. These maps are then compared using
  /// [_compareTreeParts].
  _Mismatch? _compareNodesWithMatchingTypes({
    required AstNodeImpl actual,
    required AstNodeImpl expected,
  }) {
    var allKeys = <String>{};
    var actualChildEntities = _computeChildEntitiesMap(
      actual,
      keyAccumulator: allKeys,
    );
    var expectedChildEntities = _computeChildEntitiesMap(
      expected,
      keyAccumulator: allKeys,
    );
    for (var key in allKeys) {
      var actualChild = actualChildEntities[key];
      var expectedChild = expectedChildEntities[key];
      if (_compareTreeParts(actual: actualChild, expected: expectedChild)
          case var mismatch?) {
        mismatch.reversePath.add(_GetterPathSegment(key));
        return mismatch;
      }
    }
    return null;
  }

  /// Compares two [Token]s in a syntax tree, and if they don't match, returns
  /// a description of how they fail to match.
  _Mismatch? _compareTokens({required Token actual, required Token expected}) {
    StringBuffer buffer;
    if (expected.lexeme == '_k_') {
      // '_k_' matches a keyword.
      if (actual.isKeyword) {
        return null;
      } else {
        buffer = StringBuffer();
        buffer.writeln('Expected a keyword');
      }
    } else if (expected.lexeme == '_s_') {
      // '_s_' matches a synthetic identifier.
      if (actual.isSynthetic && actual.type == expected.type) {
        return null;
      } else {
        buffer = StringBuffer();
        buffer.writeln('Expected a synthetic identifier');
      }
    } else {
      if (actual.type == expected.type) {
        if (actual.isSynthetic) {
          if (expected.isSynthetic) {
            // Synthetic tokens match each other regardless of their lexeme and
            // length
            return null;
          } else {
            // An actual synthetic token matches an expected non-synthetic token
            // if the lexemes match. The lengths do not need to match because
            // the length of a synthetic token is zero.
            assert(
              actual.length == 0,
              'Length is expected to be zero because token is synthetic',
            );
            if (actual.lexeme == expected.lexeme) return null;
            // Also, an actual synthetic empty string matches an expected empty
            // string, even if the strings are quotated differently.
            if (_isEmptyStringToken(actual) && _isEmptyStringToken(expected)) {
              return null;
            }
          }
        } else {
          // An actual non-synthetic token only matches an expected token with
          // the same length and lexeme.
          if (actual.length == expected.length &&
              actual.lexeme == expected.lexeme) {
            return null;
          }
        }
      }
      buffer = StringBuffer();
      buffer.write('Expected ');
      _describeToken(expected, buffer);
    }
    buffer.write('But found ');
    _describeToken(actual, buffer);
    return _Mismatch(buffer.toString());
  }

  /// Compares two parts of a syntax tree, and if they don't match, returns a
  /// description of how they fail to match.
  ///
  /// The two parts being compared might be AST nodes, AST node lists, tokens,
  /// or token lists.
  _Mismatch? _compareTreeParts({
    required Object? actual,
    required Object? expected,
  }) {
    if (identical(actual, expected)) {
      return null;
    }
    if (actual == null) {
      return _failIfExpectingNonNull(expected: expected);
    }
    if (expected == null) {
      return _failBecauseUnexpected(actual: actual);
    }
    if (actual is List<Object?> && expected is List<Object?>) {
      return _compareLists(actual: actual, expected: expected);
    }
    if (actual is Token && expected is Token) {
      return _compareTokens(actual: actual, expected: expected);
    }
    if (actual.runtimeType != expected.runtimeType) {
      return _failBecauseUnexpectedType(actual: actual, expected: expected);
    }
    if (_compareNodesWithMatchingTypes(
          actual: actual as AstNodeImpl,
          expected: expected as AstNodeImpl,
        )
        case var mismatch?) {
      var typeName = actual.runtimeType.toString();
      if (typeName.endsWith('Impl')) {
        typeName = typeName.substring(0, typeName.length - 4);
      }
      mismatch.reversePath.add(_CastPathSegment(typeName));
      return mismatch;
    }
    return null;
  }

  /// Computes a map whose values are the [AstNode]s, [Token]s, and
  /// [NodeList]s pointed to by [node], and whose keys are the names of the
  /// getters that return those values.
  ///
  /// This information is derived from the [ChildEntity] objects returned by
  /// [AstNodeImpl.namedChildEntities].
  Map<String, Object> _computeChildEntitiesMap(
    AstNodeImpl node, {
    required Set<String> keyAccumulator,
  }) {
    var result = <String, Object>{};
    for (var ChildEntity(:name, :value) in node.namedChildEntities) {
      if (node is FormalParameterListImpl && name == 'parameter') {
        // FormalParameterListImpl.namedChildEntities splits up the parameter
        // list into individual `parameter` entitites so that it can insert
        // `leftDelimiter` in the middle of the list (see
        // https://github.com/dart-lang/sdk/issues/60445 for details). To
        // compensate for this, we need to reassemble the individual `parameter`
        // entities back into a single list.
        keyAccumulator.add('parameters');
        ((result['parameters'] ??= <AstNode>[]) as List<AstNode>).add(
          value as AstNode,
        );
      } else {
        assert(
          !result.containsKey(name),
          'Unexpected duplicate name in $runtimeType.childEntities: $name',
        );
        keyAccumulator.add(name);
        result[name] = value;
      }
    }
    return result;
  }

  /// Writes a human-readable description of [token] to [buffer].
  void _describeToken(Token token, StringBuffer buffer) {
    if (token.isSynthetic) buffer.write('synthetic ');
    buffer.write('token ');
    buffer.writeln(json.encode(token.lexeme));
    buffer.write('  type=');
    buffer.write(token.type.name);
    buffer.write(', length=');
    buffer.writeln(token.length);
  }

  /// Creates a [_Mismatch] representing a piece of syntax that was unexpected
  /// (the corresponding part of the `expected` AST is `null`).
  _Mismatch _failBecauseUnexpected({required Object actual}) {
    StringBuffer buffer = StringBuffer();
    buffer.write('Unexpected ');
    buffer.writeln(actual.runtimeType);
    return _Mismatch(buffer.toString());
  }

  /// Creates a [_Mismatch] representing a piece of syntax that has the wrong
  /// runtime type.
  _Mismatch _failBecauseUnexpectedType({
    required Object actual,
    required Object expected,
  }) {
    StringBuffer buffer = StringBuffer();
    buffer.write('Expected a ');
    buffer.write(expected.runtimeType);
    buffer.write('; found ');
    buffer.writeln(actual.runtimeType);
    return _Mismatch(buffer.toString());
  }

  /// Creates a [_Mismatch] representing a piece of syntax that is a list with
  /// an unexpected length.
  _Mismatch _failDifferentLength({
    required List<Object?> actual,
    required List<Object?> expected,
  }) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Expected a list of length ${expected.length}');
    buffer.writeln('  $expected');
    buffer.writeln('But found a list of length ${actual.length}');
    buffer.writeln('  $actual');
    return _Mismatch(buffer.toString());
  }

  /// Handles the situation where a slot in the `actual` AST is `null`.
  ///
  /// If the corresponding slot in the `expected` AST is also `null`, then there
  /// is no mismatch. Otherwise, a [_Mismatch] is created to describe the
  /// problem.
  _Mismatch? _failIfExpectingNonNull({required Object? expected}) {
    if (expected != null) {
      StringBuffer buffer = StringBuffer();
      buffer.write('Expected a ');
      buffer.write(expected.runtimeType);
      buffer.writeln('; found nothing');
      return _Mismatch(buffer.toString());
    }
    return null;
  }

  bool _isEmptyStringToken(Token token) => const [
    '""',
    "''",
    '""""""',
    "''''''",
    'r""',
    "r''",
    'r""""""',
    "r''''''",
  ].contains(token.lexeme);

  /// Compares the [actual] and [expected] nodes, failing the test if they are
  /// different.
  static void compare(AstNode actual, AstNode expected) {
    ResultComparator comparator = ResultComparator();
    if (comparator._compareTreeParts(actual: actual, expected: expected)
        case _Mismatch(:var message, :var reversePath)) {
      if (reversePath.isNotEmpty) {
        var path = reversePath.reversed.fold(
          'root',
          (p, seg) => seg.combinePath(p),
        );
        fail('$message  path: $path\n');
      } else {
        fail(message);
      }
    }
  }
}

/// A [_PathSegment] representing a cast to a specific AST node type.
class _CastPathSegment extends _PathSegment {
  final String typeName;

  _CastPathSegment(this.typeName);

  @override
  String combinePath(String path) => '($path as $typeName)';
}

/// A [_PathSegment] representing a getter invocation.
class _GetterPathSegment extends _PathSegment {
  final String getterName;

  _GetterPathSegment(this.getterName);

  @override
  String combinePath(String path) => '$path.$getterName';
}

/// A [_PathSegment] representing the operation of indexing into a list.
class _IndexPathSegment extends _PathSegment {
  final int index;

  _IndexPathSegment(this.index);

  @override
  String combinePath(String path) => '$path[$index]';
}

/// A description of a mismatch between two ASTs.
///
/// Part of the implementation of [ResultComparator.compare].
class _Mismatch {
  /// Description of the mismatch, followed by `\n`.
  final String message;

  /// A list of [_PathSegment] objects which, when taken in revers order,
  /// describe the path from the AST nodes passed to [ResultComparator.compare]
  /// to the point where the mismatch occurred.
  final reversePath = <_PathSegment>[];

  _Mismatch(this.message) : assert(message.endsWith('\n'));
}

/// A single step in the path from the root of an AST to a particular point in
/// the AST.
sealed class _PathSegment {
  /// Combines this path segment with [path].
  ///
  /// If [path] represents a particular AST (or a part of an AST), then the
  /// returned string represents the particular substructure of that AST
  /// selected by this path segment. For example, if `path` is `foo`, and `this`
  /// is a [_GetterPathSegment] representing invocation of the getter
  /// `.operand`, then the resulting string will be `foo.operand`.
  String combinePath(String path);
}
