import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ConstructorTest().buildAll();
}

class ConstructorTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'constructor',
        [
          new TestDescriptor(
            'colon',
            'C() :',
            [
              ParserErrorCode.MISSING_INITIALIZER,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() {}',
            adjustValidUnitBeforeComparison: setSeparator,
            failing: ['methodNonVoid', 'getter', 'setter'],
          ),
          new TestDescriptor(
            'colon_block',
            'C() : {}',
            [ParserErrorCode.MISSING_INITIALIZER],
            'C() {}',
            adjustValidUnitBeforeComparison: setSeparator,
          ),
          new TestDescriptor(
            'colon_semicolon',
            'C() : ;',
            [ParserErrorCode.MISSING_INITIALIZER],
            'C();',
            adjustValidUnitBeforeComparison: setSeparator,
          ),
          new TestDescriptor(
            'super',
            'C() : super',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : super() {}',
          ),
          new TestDescriptor(
            'super_dot',
            'C() : super.',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : super._s_() {}',
            failing: ['fieldConst', 'methodNonVoid', 'getter', 'setter'],
          ),
          new TestDescriptor(
            'super_qdot',
            'C() : super?.',
            [
              ParserErrorCode.INVALID_OPERATOR_FOR_SUPER,
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_FUNCTION_BODY,
            ],
            'C() : super?._s_() {}',
            expectedErrorsInValidCode: [
              ParserErrorCode.INVALID_OPERATOR_FOR_SUPER
            ],
            failing: ['methodNonVoid', 'getter', 'setter'],
          ),
        ],
        PartialCodeTest.classMemberSuffixes,
        head: 'class C {',
        tail: '}');
  }

  CompilationUnit setSeparator(CompilationUnit unit) {
    ClassDeclaration declaration = unit.declarations[0];
    ConstructorDeclaration member = declaration.members[0];
    member.separator =
        new Token(TokenType.COLON, member.parameters.endToken.charOffset + 1);
    return unit;
  }
}
