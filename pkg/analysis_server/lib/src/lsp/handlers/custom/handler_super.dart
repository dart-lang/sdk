// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';

class SuperHandler
    extends SharedMessageHandler<TextDocumentPositionParams, Location?> {
  SuperHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.super_;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<Location?>> handle(
    TextDocumentPositionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));

    return (unit, offset).mapResultsSync((unit, offset) {
      // Find the nearest node that could have a super.
      var node = unit.unit
          .nodeCovering(offset: offset)
          ?.thisOrAncestorMatching(_canHaveSuper);
      if (node == null) {
        return success(null);
      }

      var element = ElementLocator.locate2(node);
      if (element == null) {
        return success(null);
      }

      var targetFragment = _SuperComputer().computeSuper(element);
      var location = fragmentToLocation(uriConverter, targetFragment);
      return success(location);
    });
  }

  /// Returns whether [node] is something that can be considered to have a
  /// "super" (a class or a class member).
  bool _canHaveSuper(AstNode node) =>
      node is ClassDeclaration || node is ClassMember;
}

class _SuperComputer {
  Fragment? computeSuper(Element2 element) {
    return switch (element) {
      ConstructorElement2 element => _findSuperConstructor(element),
      InterfaceElement2 element => _findSuperClass(element),
      _ => _findSuperMember(element),
    };
  }

  Fragment? _findSuperClass(InterfaceElement2 element) {
    // For super classes, we use the first fragment (the original declaration).
    // This differs from methods/getters because we jump to the end of the
    // augmentation chain for those.
    return element.supertype?.element3.firstFragment;
  }

  Fragment? _findSuperConstructor(ConstructorElement2 element) {
    return _lastFragment(element.superConstructor2);
  }

  Fragment? _findSuperMember(Element2 element) {
    var session = element.session;
    if (session is! AnalysisSessionImpl) {
      return null;
    }

    var inheritanceManager = session.inheritanceManager;

    if (element is! ExecutableElement2) {
      return null;
    }

    var name = Name.forElement(element);
    if (name == null) {
      return null;
    }

    var interfaceElement = element.thisOrAncestorOfType2<InterfaceElement2>();
    if (interfaceElement == null) {
      return null;
    }

    var member = inheritanceManager.getInherited4(interfaceElement, name);
    return _lastFragment(member);
  }

  Fragment? _lastFragment(Element2? element) {
    Fragment? fragment = element?.firstFragment;
    while (fragment?.nextFragment != null) {
      fragment = fragment?.nextFragment;
    }
    return fragment;
  }
}
