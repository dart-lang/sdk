// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Code for enumerating the set of types implied by the API.
import 'package:analyzer_utilities/tools.dart';

import 'api.dart';

Map<String, ImpliedType> computeImpliedTypes(Api api) {
  var visitor = _ImpliedTypesVisitor(api);
  visitor.visitApi();
  return visitor.impliedTypes;
}

class ImpliedType {
  final String camelName;
  final String humanReadableName;
  final TypeDecl type;

  /// Kind of implied type this is.  One of:
  /// - 'requestParams'
  /// - 'requestResult'
  /// - 'notificationParams'
  /// - 'refactoringFeedback'
  /// - 'refactoringOptions'
  /// - 'typeDefinition'
  final String kind;

  /// API node from which this type was inferred.
  final ApiNode apiNode;

  ImpliedType(this.camelName, this.humanReadableName, this.type, this.kind,
      this.apiNode);
}

class _ImpliedTypesVisitor extends HierarchicalApiVisitor {
  Map<String, ImpliedType> impliedTypes = <String, ImpliedType>{};

  _ImpliedTypesVisitor(Api api) : super(api);

  void storeType(String name, String nameSuffix, TypeDecl type, String kind,
      ApiNode apiNode) {
    var humanReadableName = name;
    var camelNameParts = name.split('.');
    if (nameSuffix != null) {
      humanReadableName += ' $nameSuffix';
      camelNameParts.add(nameSuffix);
    }
    var camelName = camelJoin(camelNameParts);
    impliedTypes[camelName] =
        ImpliedType(camelName, humanReadableName, type, kind, apiNode);
  }

  @override
  void visitNotification(Notification notification) {
    storeType(notification.longEvent, 'params', notification.params,
        'notificationParams', notification);
  }

  @override
  void visitRefactoring(Refactoring refactoring) {
    var camelKind = camelJoin(refactoring.kind.toLowerCase().split('_'));
    storeType(camelKind, 'feedback', refactoring.feedback,
        'refactoringFeedback', refactoring);
    storeType(camelKind, 'options', refactoring.options, 'refactoringOptions',
        refactoring);
  }

  @override
  void visitRequest(Request request) {
    storeType(
        request.longMethod, 'params', request.params, 'requestParams', request);
    storeType(
        request.longMethod, 'result', request.result, 'requestResult', request);
  }

  @override
  void visitTypeDefinition(TypeDefinition typeDefinition) {
    storeType(typeDefinition.name, null, typeDefinition.type, 'typeDefinition',
        typeDefinition);
  }
}
