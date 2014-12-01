// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_backend.patch_resolver;

import '../dart2jslib.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart';
import '../resolution/resolution.dart';
import '../tree/tree.dart';
import '../util/util.dart';

class PatchResolverTask extends CompilerTask {
  PatchResolverTask(Compiler compiler) : super(compiler);

  String get name => 'JavaScript patch resolver';

  FunctionElement resolveExternalFunction(FunctionElementX element) {
    if (element.isPatched) {
      FunctionElementX patch = element.patch;
      compiler.withCurrentElement(patch, () {
        patch.parseNode(compiler);
        patch.computeType(compiler);
      });
      checkMatchingPatchSignatures(element, patch);
      element = patch;
      ResolverTask.processAsyncMarker(compiler, element);
    } else {
      compiler.reportError(
         element, MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION);
    }
    return element;
  }

  void checkMatchingPatchParameters(FunctionElement origin,
                                    Link<Element> originParameters,
                                    Link<Element> patchParameters) {
    while (!originParameters.isEmpty) {
      ParameterElementX originParameter = originParameters.head;
      ParameterElementX patchParameter = patchParameters.head;
      // TODO(johnniwinther): Remove the conditional patching when we never
      // resolve the same method twice.
      if (!originParameter.isPatched) {
        originParameter.applyPatch(patchParameter);
      } else {
        assert(invariant(origin, originParameter.patch == patchParameter,
               message: "Inconsistent repatch of $originParameter."));
      }
      DartType originParameterType = originParameter.computeType(compiler);
      DartType patchParameterType = patchParameter.computeType(compiler);
      if (originParameterType != patchParameterType) {
        compiler.reportError(
            originParameter.parseNode(compiler),
            MessageKind.PATCH_PARAMETER_TYPE_MISMATCH,
            {'methodName': origin.name,
             'parameterName': originParameter.name,
             'originParameterType': originParameterType,
             'patchParameterType': patchParameterType});
        compiler.reportInfo(patchParameter,
            MessageKind.PATCH_POINT_TO_PARAMETER,
            {'parameterName': patchParameter.name});
      } else {
        // Hack: Use unparser to test parameter equality. This only works
        // because we are restricting patch uses and the approach cannot be used
        // elsewhere.

        // The node contains the type, so there is a potential overlap.
        // Therefore we only check the text if the types are identical.
        String originParameterText =
            originParameter.parseNode(compiler).toString();
        String patchParameterText =
            patchParameter.parseNode(compiler).toString();
        if (originParameterText != patchParameterText
            // We special case the list constructor because of the
            // optional parameter.
            && origin != compiler.unnamedListConstructor) {
          compiler.reportError(
              originParameter.parseNode(compiler),
              MessageKind.PATCH_PARAMETER_MISMATCH,
              {'methodName': origin.name,
               'originParameter': originParameterText,
               'patchParameter': patchParameterText});
          compiler.reportInfo(patchParameter,
              MessageKind.PATCH_POINT_TO_PARAMETER,
              {'parameterName': patchParameter.name});
        }
      }

      originParameters = originParameters.tail;
      patchParameters = patchParameters.tail;
    }
  }

  void checkMatchingPatchSignatures(FunctionElement origin,
                                    FunctionElement patch) {
    // TODO(johnniwinther): Show both origin and patch locations on errors.
    FunctionExpression originTree = origin.node;
    FunctionSignature originSignature = origin.functionSignature;
    FunctionExpression patchTree = patch.node;
    FunctionSignature patchSignature = patch.functionSignature;

    if (originSignature.type.returnType != patchSignature.type.returnType) {
      compiler.withCurrentElement(patch, () {
        Node errorNode =
            patchTree.returnType != null ? patchTree.returnType : patchTree;
        compiler.reportError(
            errorNode, MessageKind.PATCH_RETURN_TYPE_MISMATCH,
            {'methodName': origin.name,
             'originReturnType': originSignature.type.returnType,
             'patchReturnType': patchSignature.type.returnType});
      });
    }
    if (originSignature.requiredParameterCount !=
        patchSignature.requiredParameterCount) {
      compiler.withCurrentElement(patch, () {
        compiler.reportError(
            patchTree,
            MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH,
            {'methodName': origin.name,
             'originParameterCount': originSignature.requiredParameterCount,
             'patchParameterCount': patchSignature.requiredParameterCount});
      });
    } else {
      checkMatchingPatchParameters(origin,
                                   originSignature.requiredParameters,
                                   patchSignature.requiredParameters);
    }
    if (originSignature.optionalParameterCount != 0 &&
        patchSignature.optionalParameterCount != 0) {
      if (originSignature.optionalParametersAreNamed !=
          patchSignature.optionalParametersAreNamed) {
        compiler.withCurrentElement(patch, () {
          compiler.reportError(
              patchTree,
              MessageKind.PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH,
              {'methodName': origin.name});
        });
      }
    }
    if (originSignature.optionalParameterCount !=
        patchSignature.optionalParameterCount) {
      compiler.withCurrentElement(patch, () {
        compiler.reportError(
            patchTree,
            MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH,
            {'methodName': origin.name,
             'originParameterCount': originSignature.optionalParameterCount,
             'patchParameterCount': patchSignature.optionalParameterCount});
      });
    } else {
      checkMatchingPatchParameters(origin,
                                   originSignature.optionalParameters,
                                   patchSignature.optionalParameters);
    }
  }

}