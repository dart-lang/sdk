// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [FunctionExpressionInvocation]s.
class FunctionExpressionInvocationResolver {
  final ResolverVisitor _resolver;
  final ElementTypeProvider _elementTypeProvider;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;

  FunctionExpressionInvocationResolver({
    @required ResolverVisitor resolver,
    @required ElementTypeProvider elementTypeProvider,
  })  : _resolver = resolver,
        _elementTypeProvider = elementTypeProvider,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(FunctionExpressionInvocationImpl node) {
    _visitFunctionExpressionInvocation1(node);
    resolve2(node);
  }

  /// Continues resolution of the [FunctionExpressionInvocation] node after
  /// resolving its function.
  void resolve2(FunctionExpressionInvocationImpl node) {
    _inferenceHelper.inferArgumentTypesForInvocation(node);
    node.argumentList?.accept(_resolver);
    _visitFunctionExpressionInvocation3(node);
  }

  /**
   * Given an [argumentList] and the executable [element] that  will be invoked
   * using those arguments, compute the list of parameters that correspond to
   * the list of arguments. Return the parameters that correspond to the
   * arguments, or `null` if no correspondence could be computed.
   */
  List<ParameterElement> _computeCorrespondingParameters(
      FunctionExpressionInvocation invocation, DartType type) {
    ArgumentList argumentList = invocation.argumentList;
    if (type is InterfaceType) {
      MethodElement callMethod = invocation.staticElement;
      if (callMethod != null) {
        return _resolveArgumentsToFunction(argumentList, callMethod);
      }
    } else if (type is FunctionType) {
      return _resolveArgumentsToParameters(argumentList, type.parameters);
    }
    return null;
  }

  /**
   * Check for a generic method & apply type arguments if any were passed.
   */
  DartType _instantiateGenericMethod(DartType invokeType,
      TypeArgumentList typeArguments, FunctionExpressionInvocation invocation) {
    DartType parameterizableType;
    List<TypeParameterElement> parameters;
    if (invokeType is FunctionType) {
      parameterizableType = invokeType;
      parameters = invokeType.typeFormals;
    } else if (invokeType is InterfaceType) {
      var result = _typePropertyResolver.resolve(
        receiver: invocation.function,
        receiverType: invokeType,
        name: FunctionElement.CALL_METHOD_NAME,
        receiverErrorNode: invocation.function,
        nameErrorNode: invocation.function,
      );
      var callMethod = result.getter;

      invocation.staticElement = callMethod;
      parameterizableType = _elementTypeProvider.safeExecutableType(callMethod);
      parameters = (parameterizableType as FunctionType)?.typeFormals;
    }

    if (parameterizableType is FunctionType) {
      NodeList<TypeAnnotation> arguments = typeArguments?.arguments;
      if (arguments != null && arguments.length != parameters.length) {
        _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
            invocation,
            [parameterizableType, parameters.length, arguments?.length ?? 0]);
        // Wrong number of type arguments. Ignore them.
        arguments = null;
      }
      if (parameters.isNotEmpty) {
        if (arguments == null) {
          return _typeSystem.instantiateToBounds(parameterizableType);
        } else {
          return parameterizableType
              .instantiate(arguments.map((n) => n.type).toList());
        }
      }

      return parameterizableType;
    }
    return invokeType;
  }

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  ///
  /// TODO(scheglov) this is duplicate
  List<ParameterElement> _resolveArgumentsToFunction(
      ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters =
        _elementTypeProvider.getExecutableParameters(executableElement);
    return _resolveArgumentsToParameters(argumentList, parameters);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments. An error will be reported if any of
  /// the arguments cannot be matched to a parameter. Return the parameters that
  /// correspond to the arguments.
  ///
  /// TODO(scheglov) this is duplicate
  List<ParameterElement> _resolveArgumentsToParameters(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _errorReporter.reportErrorForNode);
  }

  void _visitFunctionExpressionInvocation1(FunctionExpressionInvocation node) {
    Expression function = node.function;
    DartType functionType;
    if (function is ExtensionOverride) {
      var result = _extensionResolver.getOverrideMember(function, 'call');
      var member = result.getter;
      if (member == null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INVOCATION_OF_EXTENSION_WITHOUT_CALL,
            function,
            [function.extensionName.name]);
        functionType = _typeProvider.dynamicType;
      } else {
        if (member.isStatic) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
              node.argumentList);
        }
        node.staticElement = member;
        functionType = _elementTypeProvider.getExecutableType(member);
      }
    } else {
      functionType = function.staticType;
    }

    DartType staticInvokeType =
        _instantiateGenericMethod(functionType, node.typeArguments, node);

    node.staticInvokeType = staticInvokeType;

    List<ParameterElement> parameters =
        _computeCorrespondingParameters(node, staticInvokeType);
    if (parameters != null) {
      node.argumentList.correspondingStaticParameters = parameters;
    }
  }

  void _visitFunctionExpressionInvocation3(FunctionExpressionInvocation node) {
    _resolver.inferenceHelper.inferGenericInvocationExpression(node);
    DartType staticType = _resolver.inferenceHelper
        .computeInvokeReturnType(node.staticInvokeType, isNullAware: false);
    _inferenceHelper.recordStaticType(node, staticType);
  }
}
