import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/hint_codes.g.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/task/inference_error.dart';

/// A listener which can receive various inference errors.
///
/// This is separate from [ErrorReporter] for the case of discovering inference
/// errors during AST resolution, which happens far before type analysis and
/// most static error reporting.
abstract class InferenceErrorListener {
  final bool _isNonNullableByDefault;
  final bool _isGenericMetadataEnabled;

  InferenceErrorListener({
    required bool isNonNullableByDefault,
    required bool isGenericMetadataEnabled,
  })  : _isNonNullableByDefault = isNonNullableByDefault,
        _isGenericMetadataEnabled = isGenericMetadataEnabled;

  void addCouldNotInferError(AstNode node, List<String> arguments);

  void addInferenceFailureOnFunctionInvocationError(
      AstNode node, List<String> arguments);

  void addInferenceFailureOnGenericInvocationError(
      AstNode node, List<String> arguments);

  void addInferenceFailureOnInstanceCreationError(
      AstNode node, List<String> arguments);

  /// Reports an inference failure on [errorNode] according to its type.
  void reportInferenceFailure(AstNode errorNode) {
    if (errorNode.parent is InvocationExpression &&
        errorNode.parent?.parent is AsExpression) {
      // Casts via `as` do not play a part in downward inference. We allow an
      // exception when inference has "failed" but the return value is
      // immediately cast with `as`.
      return;
    }
    if (errorNode is ConstructorName &&
        !(errorNode.type.type as InterfaceType).element.hasOptionalTypeArgs) {
      String constructorName = errorNode.name == null
          ? errorNode.type.name.name
          : '${errorNode.type}.${errorNode.name}';
      addInferenceFailureOnInstanceCreationError(errorNode, [constructorName]);
    } else if (errorNode is Annotation) {
      if (_isGenericMetadataEnabled) {
        // Only report an error if generic metadata is valid syntax.
        var element = errorNode.name.staticElement;
        if (element != null && !element.hasOptionalTypeArgs) {
          String constructorName = errorNode.constructorName == null
              ? errorNode.name.name
              : '${errorNode.name.name}.${errorNode.constructorName}';
          addInferenceFailureOnInstanceCreationError(
              errorNode, [constructorName]);
        }
      }
    } else if (errorNode is SimpleIdentifier) {
      var element = errorNode.staticElement;
      if (element == null) {
        return;
      }
      if (element is VariableElement) {
        // For variable elements, we check their type and possible alias type.
        var type = element.type;
        final typeElement = type is InterfaceType ? type.element : null;
        if (typeElement != null && typeElement.hasOptionalTypeArgs) {
          return;
        }
        var typeAliasElement = type.alias?.element;
        if (typeAliasElement != null && typeAliasElement.hasOptionalTypeArgs) {
          return;
        }
      }
      if (!element.hasOptionalTypeArgs) {
        addInferenceFailureOnFunctionInvocationError(
            errorNode, [errorNode.name]);
      }
    } else if (errorNode is Expression) {
      var type = errorNode.staticType;
      if (type != null) {
        var typeDisplayString =
            type.getDisplayString(withNullability: _isNonNullableByDefault);
        addInferenceFailureOnGenericInvocationError(
            errorNode, [typeDisplayString]);
      }
    }
  }
}

class InferenceErrorRecorder extends InferenceErrorListener {
  final Set<TopLevelInferenceError> errors = {};

  InferenceErrorRecorder({
    required super.isNonNullableByDefault,
    required super.isGenericMetadataEnabled,
  });

  @override
  void addCouldNotInferError(AstNode node, List<String> arguments) {
    errors.add(TopLevelInferenceError(
      kind: TopLevelInferenceErrorKind.couldNotInfer,
      arguments: arguments,
    ));
  }

  @override
  void addInferenceFailureOnFunctionInvocationError(
      AstNode node, List<String> arguments) {
    // This error is re-discovered and reported during type analysis.
  }

  @override
  void addInferenceFailureOnGenericInvocationError(
      AstNode node, List<String> arguments) {
    // This error is re-discovered and reported during type analysis.
  }

  @override
  void addInferenceFailureOnInstanceCreationError(
      AstNode node, List<String> arguments) {
    errors.add(TopLevelInferenceError(
      kind: TopLevelInferenceErrorKind.inferenceFailureOnInstanceCreation,
      arguments: arguments,
    ));
  }
}

class InferenceErrorReporter extends InferenceErrorListener {
  final ErrorReporter _errorReporter;

  InferenceErrorReporter(
    this._errorReporter, {
    required super.isNonNullableByDefault,
    required super.isGenericMetadataEnabled,
  });

  @override
  void addCouldNotInferError(AstNode node, List<String> arguments) =>
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.COULD_NOT_INFER, node, arguments);

  @override
  void addInferenceFailureOnFunctionInvocationError(
          AstNode node, List<String> arguments) =>
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION, node, arguments);

  @override
  void addInferenceFailureOnGenericInvocationError(
          AstNode node, List<String> arguments) =>
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION, node, arguments);

  @override
  void addInferenceFailureOnInstanceCreationError(
          AstNode node, List<String> arguments) =>
      _errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, node, arguments);
}
