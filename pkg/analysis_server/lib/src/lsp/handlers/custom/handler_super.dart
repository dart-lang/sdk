// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';

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

      var element = ElementLocator.locate(node);
      if (element == null) {
        return success(null);
      }

      // For PrimaryConstructorDeclarations, ElementLocator will return the
      // class element (unless we're on a constructor name), but we want to
      // treat a position within parameters as the constructor element, not the
      // class element.
      //
      //   class Fo^o() extends X {}       // navigate to super class
      //   class Foo(^) extends X {}       // navigate to super constructor
      //   class Foo.na^med() extends X {} // navigate to super constructor
      if (node is PrimaryConstructorDeclaration &&
          element is ClassElement &&
          offset > node.typeName.end) {
        if (element.primaryConstructor case var constructor?) {
          element = constructor;
        }
      }

      var targetFragment = _SuperComputer().computeSuper(element);
      var location = fragmentToLocation(uriConverter, targetFragment);
      return success(location);
    });
  }

  /// Returns whether [node] is something that can be considered to have a
  /// "super" (a class or a class member).
  bool _canHaveSuper(AstNode node) {
    AstNode? testNode = node;
    if (testNode
        case VariableDeclaration(parent: VariableDeclarationList list) ||
            VariableDeclarationList list) {
      // This says if the variable is a field or null if it isn't.
      testNode = list.parent;
    }

    return testNode is ClassDeclaration ||
        testNode is ClassMember ||
        testNode is PrimaryConstructorDeclaration;
  }
}

class _SuperComputer {
  Fragment? computeSuper(Element element) {
    return switch (element) {
      ConstructorElement element => _findSuperConstructor(element),
      InterfaceElement element => _findSuperClass(element),
      _ => _findSuperMember(element),
    };
  }

  Fragment? _findSuperClass(InterfaceElement element) {
    // For super classes, we use the first fragment (the original declaration).
    // This differs from methods/getters because we jump to the end of the
    // augmentation chain for those.
    return element.supertype?.element.firstFragment;
  }

  Fragment? _findSuperConstructor(ConstructorElement element) {
    return _lastFragment(element.superConstructor);
  }

  Fragment? _findSuperMember(Element element) {
    var session = element.session;
    if (session is! AnalysisSessionImpl) {
      return null;
    }

    var inheritanceManager = session.inheritanceManager;

    if (element is! ExecutableElement && element is! FieldElement) {
      return null;
    }

    var name = Name.forElement(element);
    if (name == null) {
      return null;
    }

    var interfaceElement = element.thisOrAncestorOfType<InterfaceElement>();
    if (interfaceElement == null) {
      return null;
    }

    var member = inheritanceManager.getInherited(interfaceElement, name);
    return _lastFragment(member);
  }

  Fragment? _lastFragment(Element? element) {
    Fragment? fragment = element?.firstFragment;
    while (fragment?.nextFragment != null) {
      fragment = fragment?.nextFragment;
    }
    return fragment;
  }
}
