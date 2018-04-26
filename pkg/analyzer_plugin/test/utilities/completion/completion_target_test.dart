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
    final snippet = wrapForCompliance(parseDanglingDart('identifier'));
    final completionTarget =
        new CompletionTarget.forOffset(null, 1, entryPoint: snippet);
    expect(completionTarget.offset, 1);
    final replacementRange = completionTarget.computeReplacementRange(1);
    expect(replacementRange.offset, 0);
    expect(replacementRange.length, 'identifier'.length);
  }

  /// Parse a dangling expression (no parent node). The angular plugin, for
  /// instance, does this.
  Expression parseDanglingDart(String code) {
    final reader = new CharSequenceReader(code);
    final scanner = new Scanner(null, reader, null);
    return new Parser(null, null).parseExpression(scanner.tokenize());
  }

  Expression wrapForCompliance(Expression expression) {
    // TODO(mfairhurst) This should be performed for clients or the need should
    // be dropped. It's a fairly valid invariant that all autocompletion target
    // expressions should have parents, and one we can enforce via synthetics.
    // But clients should not be doing this ideally.
    return astFactory.parenthesizedExpression(
        new SyntheticBeginToken(TokenType.OPEN_PAREN, expression.offset)
          ..next = expression.beginToken,
        expression,
        new SyntheticToken(TokenType.CLOSE_PAREN, expression.end));
  }
}
