// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_backend.patch_resolver;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart';
import '../tree/tree.dart';

class PatchResolverTask extends CompilerTask {
  final Compiler compiler;
  PatchResolverTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  DiagnosticReporter get reporter => compiler.reporter;

  Resolution get resolution => compiler.resolution;

  String get name => 'JavaScript patch resolver';

  FunctionElement resolveExternalFunction(FunctionElementX element) {
    if (element.isPatched) {
      FunctionElementX patch = element.patch;
      reporter.withCurrentElement(patch, () {
        patch.computeType(resolution);
      });
      checkMatchingPatchSignatures(element, patch);
      element = patch;
    } else {
      if (element.isConstructor) {
        // Note: currently we allow a couple external methods without a patch,
        // namely the *.fromEnvironment const constructors in int, bool, and
        // String.  In the future we might also represent native DOM methods in
        // dart:html this way.
        ConstructorElementX constructor = element;
        if (constructor.isFromEnvironmentConstructor) return element;
      }
      reporter.reportErrorMessage(
          element, MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION);
    }
    return element;
  }

  void checkMatchingPatchParameters(FunctionElement origin,
      List<Element> originParameters, List<Element> patchParameters) {
    bool isUnnamedListConstructor = origin is ConstructorElement &&
        compiler.commonElements.isUnnamedListConstructor(origin);

    assert(originParameters.length == patchParameters.length);
    for (int index = 0; index < originParameters.length; index++) {
      ParameterElementX originParameter = originParameters[index];
      ParameterElementX patchParameter = patchParameters[index];
      // TODO(johnniwinther): Remove the conditional patching when we never
      // resolve the same method twice.
      if (!originParameter.isPatched) {
        originParameter.applyPatch(patchParameter);
      } else {
        assert(originParameter.patch == patchParameter,
            failedAt(origin, "Inconsistent repatch of $originParameter."));
      }
      ResolutionDartType originParameterType =
          originParameter.computeType(resolution);
      ResolutionDartType patchParameterType =
          patchParameter.computeType(resolution);
      if (originParameterType != patchParameterType) {
        reporter.reportError(
            reporter.createMessage(
                originParameter, MessageKind.PATCH_PARAMETER_TYPE_MISMATCH, {
              'methodName': origin.name,
              'parameterName': originParameter.name,
              'originParameterType': originParameterType,
              'patchParameterType': patchParameterType
            }),
            <DiagnosticMessage>[
              reporter.createMessage(
                  patchParameter,
                  MessageKind.PATCH_POINT_TO_PARAMETER,
                  {'parameterName': patchParameter.name}),
            ]);
      } else {
        // Hack: Use unparser to test parameter equality. This only works
        // because we are restricting patch uses and the approach cannot be used
        // elsewhere.

        // The node contains the type, so there is a potential overlap.
        // Therefore we only check the text if the types are identical.
        String originParameterText = originParameter.node.toString();
        String patchParameterText = patchParameter.node.toString();
        if (originParameterText != patchParameterText
            // We special case the list constructor because of the
            // optional parameter.
            &&
            !isUnnamedListConstructor) {
          reporter.reportError(
              reporter.createMessage(
                  originParameter, MessageKind.PATCH_PARAMETER_MISMATCH, {
                'methodName': origin.name,
                'originParameter': originParameterText,
                'patchParameter': patchParameterText
              }),
              <DiagnosticMessage>[
                reporter.createMessage(
                    patchParameter,
                    MessageKind.PATCH_POINT_TO_PARAMETER,
                    {'parameterName': patchParameter.name}),
              ]);
        }
      }
    }
  }

  void checkMatchingPatchSignatures(
      FunctionElement origin, FunctionElement patch) {
    // TODO(johnniwinther): Show both origin and patch locations on errors.
    FunctionExpression originTree = origin.node;
    FunctionSignature originSignature = origin.functionSignature;
    FunctionExpression patchTree = patch.node;
    FunctionSignature patchSignature = patch.functionSignature;

    if ('${originTree.typeVariables}' != '${patchTree.typeVariables}') {
      reporter.withCurrentElement(patch, () {
        Node errorNode = patchTree.typeVariables != null
            ? patchTree.typeVariables
            : patchTree;
        reporter.reportError(
            reporter.createMessage(
                errorNode,
                MessageKind.PATCH_TYPE_VARIABLES_MISMATCH,
                {'methodName': origin.name}),
            [reporter.createMessage(origin, MessageKind.THIS_IS_THE_METHOD)]);
      });
    }
    if (originSignature.type.returnType != patchSignature.type.returnType) {
      reporter.withCurrentElement(patch, () {
        Node errorNode =
            patchTree.returnType != null ? patchTree.returnType : patchTree;
        reporter.reportErrorMessage(
            errorNode, MessageKind.PATCH_RETURN_TYPE_MISMATCH, {
          'methodName': origin.name,
          'originReturnType': originSignature.type.returnType,
          'patchReturnType': patchSignature.type.returnType
        });
      });
    }
    if (originSignature.requiredParameterCount !=
        patchSignature.requiredParameterCount) {
      reporter.withCurrentElement(patch, () {
        reporter.reportErrorMessage(
            patchTree, MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH, {
          'methodName': origin.name,
          'originParameterCount': originSignature.requiredParameterCount,
          'patchParameterCount': patchSignature.requiredParameterCount
        });
      });
    } else {
      checkMatchingPatchParameters(origin, originSignature.requiredParameters,
          patchSignature.requiredParameters);
    }
    if (originSignature.optionalParameterCount != 0 &&
        patchSignature.optionalParameterCount != 0) {
      if (originSignature.optionalParametersAreNamed !=
          patchSignature.optionalParametersAreNamed) {
        reporter.withCurrentElement(patch, () {
          reporter.reportErrorMessage(
              patchTree,
              MessageKind.PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH,
              {'methodName': origin.name});
        });
      }
    }
    if (originSignature.optionalParameterCount !=
        patchSignature.optionalParameterCount) {
      reporter.withCurrentElement(patch, () {
        reporter.reportErrorMessage(
            patchTree, MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH, {
          'methodName': origin.name,
          'originParameterCount': originSignature.optionalParameterCount,
          'patchParameterCount': patchSignature.optionalParameterCount
        });
      });
    } else {
      checkMatchingPatchParameters(origin, originSignature.optionalParameters,
          patchSignature.optionalParameters);
    }
  }
}
