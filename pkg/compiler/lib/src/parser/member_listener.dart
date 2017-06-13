// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.member_listener;

import '../common.dart';
import '../elements/elements.dart' show Element, ElementKind, Elements;
import '../elements/modelx.dart'
    show ClassElementX, ElementX, FieldElementX, VariableList;
import 'package:front_end/src/fasta/scanner.dart' show Token;
import '../tree/tree.dart';
import 'element_listener.dart' show ScannerOptions;
import 'node_listener.dart' show NodeListener;
import 'partial_elements.dart'
    show
        PartialConstructorElement,
        PartialFunctionElement,
        PartialMetadataAnnotation;

class MemberListener extends NodeListener {
  final ClassElementX enclosingClass;

  MemberListener(ScannerOptions scannerOptions, DiagnosticReporter listener,
      ClassElementX enclosingElement)
      : this.enclosingClass = enclosingElement,
        super(scannerOptions, listener, enclosingElement.compilationUnit);

  bool isConstructorName(Node nameNode) {
    if (enclosingClass == null || enclosingClass.kind != ElementKind.CLASS) {
      return false;
    }
    String name;
    if (nameNode.asIdentifier() != null) {
      name = nameNode.asIdentifier().source;
    } else {
      Send send = nameNode.asSend();
      name = send.receiver.asIdentifier().source;
    }
    return enclosingClass.name == name;
  }

  // TODO(johnniwinther): Remove this method.
  String getMethodNameHack(Node methodName) {
    Send send = methodName.asSend();
    if (send == null) {
      if (isConstructorName(methodName)) return '';
      return methodName.asIdentifier().source;
    }
    Identifier receiver = send.receiver.asIdentifier();
    Identifier selector = send.selector.asIdentifier();
    Operator operator = selector.asOperator();
    if (operator != null) {
      assert(identical(receiver.source, 'operator'));
      // TODO(ahe): It is a hack to compare to ')', but it beats
      // parsing the node.
      bool isUnary = identical(operator.token.next.next.stringValue, ')');
      return Elements.constructOperatorName(operator.source, isUnary);
    } else {
      if (receiver == null || receiver.source != enclosingClass.name) {
        reporter.reportErrorMessage(
            send.receiver,
            MessageKind.INVALID_CONSTRUCTOR_NAME,
            {'name': enclosingClass.name});
      }
      return selector.source;
    }
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    super.endMethod(getOrSet, beginToken, endToken);
    FunctionExpression method = popNode();
    pushNode(null);
    bool isConstructor = isConstructorName(method.name);
    String name = getMethodNameHack(method.name);
    Element memberElement;
    if (isConstructor) {
      if (getOrSet != null) {
        recoverableError(reporter.spanFromToken(getOrSet), 'illegal modifier');
      }
      memberElement = new PartialConstructorElement(name, beginToken, endToken,
          ElementKind.GENERATIVE_CONSTRUCTOR, method.modifiers, enclosingClass);
    } else {
      memberElement = new PartialFunctionElement(name, beginToken, getOrSet,
          endToken, method.modifiers, enclosingClass,
          hasBody: method.hasBody);
    }
    addMember(memberElement);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    super.endFactoryMethod(beginToken, factoryKeyword, endToken);
    FunctionExpression method = popNode();
    pushNode(null);
    String name = getMethodNameHack(method.name);
    Identifier singleIdentifierName = method.name.asIdentifier();
    if (singleIdentifierName != null && singleIdentifierName.source == name) {
      if (name != enclosingClass.name) {
        reporter.reportErrorMessage(
            singleIdentifierName,
            MessageKind.INVALID_UNNAMED_CONSTRUCTOR_NAME,
            {'name': enclosingClass.name});
      }
    }
    Element memberElement = new PartialConstructorElement(
        name,
        beginToken,
        endToken,
        ElementKind.FACTORY_CONSTRUCTOR,
        method.modifiers,
        enclosingClass);
    addMember(memberElement);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    bool hasParseError = memberErrors.head;
    super.endFields(count, beginToken, endToken);
    VariableDefinitions variableDefinitions = popNode();
    Modifiers modifiers = variableDefinitions.modifiers;
    pushNode(null);
    void buildFieldElement(Identifier name, VariableList fields) {
      Element element = new FieldElementX(name, enclosingClass, fields);
      addMember(element);
    }

    buildFieldElements(modifiers, variableDefinitions.definitions,
        enclosingClass, buildFieldElement, beginToken, endToken, hasParseError);
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    pushNode(null); // Super expects an expression, but
    // ClassElementParser just skips expressions.
    super.endFieldInitializer(assignmentOperator, token);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    pushNode(null);
  }

  void addMetadata(ElementX memberElement) {
    memberElement.metadata = metadata.toList();
  }

  void addMember(ElementX memberElement) {
    addMetadata(memberElement);
    enclosingClass.addMember(memberElement, reporter);
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    super.endMetadata(beginToken, periodBeforeName, endToken);
    // TODO(paulberry,ahe): type variable metadata should not be ignored.  See
    // dartbug.com/5841.
    if (!inTypeVariable) {
      pushMetadata(new PartialMetadataAnnotation(beginToken, endToken));
    }
  }
}
