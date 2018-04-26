import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart'
    show SyntheticBeginToken, SyntheticToken;
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTargetTest);
  });
}

@reflectiveTest
class CompletionTargetTest {
  test_danglingExpressionCompletionIsValid() {
    // Test that users can parse dangling expressions of dart and autocomplete
    // them without crash/with the correct offset information.
    final snippet = parseDanglingDart('identifier');
    final completionTarget = new CompletionTarget.forOffset(snippet, 1);
    expect(completionTarget.offset, 1);
    final replacementRange = completionTarget.computeReplacementRange(1);
    expect(replacementRange.offset, 0);
    expect(replacementRange.length, 'identifier'.length);
  }

  test_danglingExpressionCompletionIsValid_deprecatedApi() {
    // Test that we support an older form of API, where the first argument was
    // a [CompilationUnit] and there was an optional [AstNode] [entryPoint] arg,
    // and clients wrapped the entry point.
    final snippet = wrapAsIfOlderClient(parseDanglingDart('identifier'));
    final completionTarget =
        // ignore: deprecated_member_use
        new CompletionTarget.forOffset(null, 1, entryPoint: snippet);
    expect(completionTarget.offset, 1);
    final replacementRange = completionTarget.computeReplacementRange(1);
    expect(replacementRange.offset, 0);
    expect(replacementRange.length, 'identifier'.length);
  }

  test_danglingExpressionCompletion_invalidOffset_gracefulFailure() {
    // Test an edge case where an invariant can be broken in the algorithm when
    // we modify the root. Here, the root is selected, and must be consistent
    // with the snippet. Very much a white-box as opposed to black-box test.
    final snippet = parseDanglingDart('a');
    final completionTarget = new CompletionTarget.forOffset(snippet, 9999);
    expect(completionTarget.offset, 9999);
    final replacementRange = completionTarget.computeReplacementRange(1);
    expect(replacementRange.offset, 1);
    expect(replacementRange.length, 0);
  }

  /// Parse a dangling expression (no parent node). The angular plugin, for
  /// instance, does this.
  Expression parseDanglingDart(String code) {
    final reader = new CharSequenceReader(code);
    final scanner = new Scanner(null, reader, null);
    return new Parser(null, null).parseExpression(scanner.tokenize());
  }

  Expression wrapAsIfOlderClient(Expression expression) {
    // TODO(mfairhurst) remove this, this is only for testing backwards
    // compatibility.
    return astFactory.parenthesizedExpression(
        new SyntheticBeginToken(TokenType.OPEN_PAREN, expression.offset)
          ..next = expression.beginToken,
        expression,
        new SyntheticToken(TokenType.CLOSE_PAREN, expression.end));
  }
}
