// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    hide Element, TypeHierarchyItem;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class SuperHandler
    extends LspMessageHandler<TextDocumentPositionParams, Location?> {
  SuperHandler(super.server);
  @override
  Method get handlesMessage => CustomMethods.super_;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<Location?>> handle(TextDocumentPositionParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    var offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) async {
      var node = NodeLocator(offset).searchWithin(unit.result.unit);
      if (node == null) {
        return success(null);
      }

      // Walk up the nodes until we find one that has an element so we can support
      // finding supers even if the cursor location was inside a method or on its
      // return type.
      var element = server.getElementOfNode(node);
      while (element == null && node?.parent != null) {
        node = node?.parent;
        element = server.getElementOfNode(node);
      }
      if (element == null) {
        return success(null);
      }

      var superElement = _SuperComputer().computeSuper(element)?.nonSynthetic;
      var sourcePath = superElement?.declaration?.source?.fullName;

      if (superElement == null || sourcePath == null) {
        return success(null);
      }

      var locationLineInfo = server.getLineInfo(sourcePath);
      if (locationLineInfo == null) {
        return success(null);
      }

      return success(Location(
        uri: uriConverter.toClientUri(sourcePath),
        range: toRange(
          locationLineInfo,
          superElement.nameOffset,
          superElement.nameLength,
        ),
      ));
    });
  }
}

class _SuperComputer {
  Element? computeSuper(Element element) {
    return switch (element) {
      ConstructorElement element => _findSuperConstructor(element),
      InterfaceElement element => _findSuperClass(element),
      _ => _findSuperMember(element),
    };
  }

  Element? _findSuperClass(InterfaceElement element) {
    return element.supertype?.element;
  }

  Element? _findSuperConstructor(ConstructorElement element) {
    return element.superConstructor?.withAugmentations.last;
  }

  Element? _findSuperMember(Element element) {
    var session = element.session;
    if (session is! AnalysisSessionImpl) {
      return null;
    }

    var inheritanceManager = session.inheritanceManager;
    var elementName = element.name;
    var interfaceElement = element.thisOrAncestorOfType<InterfaceElement>();

    if (elementName == null || interfaceElement == null) {
      return null;
    }

    var name = Name(interfaceElement.library.source.uri, elementName);
    var member = inheritanceManager.getInherited2(interfaceElement, name);

    return member;
  }
}
