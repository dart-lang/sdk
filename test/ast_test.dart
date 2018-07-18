import 'package:analyzer/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:test/test.dart';

main() {
  group('HasConstErrorListener', () {
    test('has hasConstError false by default', () {
      final listener = new HasConstErrorListener();
      expect(listener.hasConstError, isFalse);
    });
    test('has hasConstError true with a tracked const error', () {
      final listener = new HasConstErrorListener();
      listener.onError(new AnalysisError(
          null, null, null, CompileTimeErrorCode.CONST_WITH_NON_CONST));
      expect(listener.hasConstError, isTrue);
    });
    test('has hasConstError true even if last error is not related to const',
        () {
      final listener = new HasConstErrorListener();
      listener.onError(new AnalysisError(
          null, null, null, CompileTimeErrorCode.CONST_WITH_NON_CONST));
      listener.onError(new AnalysisError(
          null, null, null, CompileTimeErrorCode.ACCESS_PRIVATE_ENUM_FIELD));
      expect(listener.hasConstError, isTrue);
    });
  });
}
