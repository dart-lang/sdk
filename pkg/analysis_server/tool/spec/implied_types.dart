// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for enumerating the set of types implied by the API.
 */
library html.tools;

import 'api.dart';
import 'codegen_tools.dart';

class ImpliedType {
  final String camelName;
  final String humanReadableName;
  final TypeDecl type;

  /**
   * Kind of implied type this is.  One of:
   * - 'requestParams'
   * - 'requestResult'
   * - 'notificationParams'
   * - 'refactoringFeedback'
   * - 'refactoringOptions'
   * - 'typeDefinition'
   */
  final String kind;

  /**
   * API node from which this type was inferred.
   */
  final ApiNode apiNode;

  ImpliedType(this.camelName, this.humanReadableName, this.type, this.kind, this.apiNode);
}

Map<String, ImpliedType> computeImpliedTypes(Api api) {
  _ImpliedTypesVisitor visitor = new _ImpliedTypesVisitor(api);
  visitor.visitApi();
  return visitor.impliedTypes;
}

class _ImpliedTypesVisitor extends HierarchicalApiVisitor {
  Map<String, ImpliedType> impliedTypes = <String, ImpliedType> {};

  _ImpliedTypesVisitor(Api api) : super(api);

  void storeType(String name, String nameSuffix, TypeDecl type, String
      kind, ApiNode apiNode) {
    String humanReadableName = name;
    List<String> camelNameParts = name.split('.');
    if (nameSuffix != null) {
      humanReadableName += ' $nameSuffix';
      camelNameParts.add(nameSuffix);
    }
    String camelName = camelJoin(camelNameParts);
    impliedTypes[camelName] = new ImpliedType(camelName, humanReadableName,
        type, kind, apiNode);
  }

  @override
  visitNotification(Notification notification) {
    storeType(notification.longEvent, 'params', notification.params,
        'notificationParams', notification);
  }

  @override
  visitRequest(Request request) {
    storeType(request.longMethod, 'params', request.params, 'requestParams',
        request);
    storeType(request.longMethod, 'result', request.result, 'requestResult',
        request);
  }

  @override
  visitRefactoring(Refactoring refactoring) {
    String camelKind = camelJoin(refactoring.kind.toLowerCase().split('_'));
    storeType(camelKind, 'feedback', refactoring.feedback,
        'refactoringFeedback', refactoring);
    storeType(camelKind, 'options', refactoring.options, 'refactoringOptions',
        refactoring);
  }

  @override
  visitTypeDefinition(TypeDefinition typeDefinition) {
    storeType(typeDefinition.name, null, typeDefinition.type, 'typeDefinition',
        typeDefinition);
  }

}
