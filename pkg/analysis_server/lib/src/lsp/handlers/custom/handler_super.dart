// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/custom/abstract_go_to.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class SuperHandler extends AbstractGoToHandler {
  SuperHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.super_;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Element? findRelatedElement(Element element) {
    return _SuperComputer().computeSuper(element);
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
