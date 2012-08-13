// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ClassElementParser extends PartialParser {
  ClassElementParser(Listener listener) : super(listener);

  Token parseClassBody(Token token) => fullParseClassBody(token);
}

class PartialClassElement extends ClassElement {
  final Token beginToken;
  final Token endToken;
  Node cachedNode;

  PartialClassElement(SourceString name,
                      Token this.beginToken,
                      Token this.endToken,
                      Element enclosing,
                      int id)
      : super(name, enclosing, id);

  ClassNode parseNode(DiagnosticListener diagnosticListener) {
    if (cachedNode != null) return cachedNode;
    MemberListener listener = new MemberListener(diagnosticListener, this);
    Parser parser = new ClassElementParser(listener);
    Token token = parser.parseTopLevelDeclaration(beginToken);
    assert(token === endToken.next);
    cachedNode = listener.popNode();
    assert(listener.nodes.isEmpty());
    return cachedNode;
  }

  Token position() => beginToken;

  bool isInterface() => beginToken.stringValue === "interface";

  PartialClassElement cloneTo(Element enclosing, DiagnosticListener listener) {
    parseNode(listener);
    PartialClassElement result =
        new PartialClassElement(name, beginToken, endToken, enclosing, id);
    cloneMembersTo(result, listener);
    result.cachedNode = cachedNode;
    return result;
  }
}

class MemberListener extends NodeListener {
  final ClassElement enclosingElement;

  MemberListener(DiagnosticListener listener,
                 Element enclosingElement)
      : this.enclosingElement = enclosingElement,
        super(listener, enclosingElement.getCompilationUnit());

  bool isConstructorName(Node nameNode) {
    if (enclosingElement === null ||
        enclosingElement.kind != ElementKind.CLASS) {
      return false;
    }
    SourceString name;
    if (nameNode.asIdentifier() !== null) {
      name = nameNode.asIdentifier().source;
    } else {
      Send send = nameNode.asSend();
      name = send.receiver.asIdentifier().source;
    }
    return enclosingElement.name == name;
  }

  SourceString getMethodNameHack(Node methodName) {
    Send send = methodName.asSend();
    if (send === null) return methodName.asIdentifier().source;
    Identifier receiver = send.receiver.asIdentifier();
    Identifier selector = send.selector.asIdentifier();
    if (selector.asOperator() !== null) {
      return Elements.constructOperatorName(receiver.source, selector.source);
    } else {
      return Elements.constructConstructorName(receiver.source,
                                               selector.source);
    }
  }

  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    super.endMethod(getOrSet, beginToken, endToken);
    FunctionExpression method = popNode();
    pushNode(null);
    bool isConstructor = isConstructorName(method.name);
    SourceString name = getMethodNameHack(method.name);
    ElementKind kind = ElementKind.FUNCTION;
    if (isConstructor) {
      if (getOrSet !== null) {
        recoverableError('illegal modifier', token: getOrSet);
      }
      kind = ElementKind.GENERATIVE_CONSTRUCTOR;
    } else if (getOrSet !== null) {
      kind = (getOrSet.stringValue === 'get')
             ? ElementKind.GETTER : ElementKind.SETTER;
    }
    Element memberElement =
        new PartialFunctionElement(name, beginToken, getOrSet, endToken,
                                   kind, method.modifiers, enclosingElement);
    addMember(memberElement);
  }

  void endFactoryMethod(Token factoryKeyword, Token periodBeforeName,
                        Token endToken) {
    super.endFactoryMethod(factoryKeyword, periodBeforeName, endToken);
    FunctionExpression method = popNode();
    pushNode(null);
    SourceString name = getMethodNameHack(method.name);
    ElementKind kind = ElementKind.FUNCTION;
    Element memberElement =
        new PartialFunctionElement(name, factoryKeyword, null, endToken,
                                   kind, method.modifiers, enclosingElement);
    addMember(memberElement);
  }

  void endFields(int count, Token beginToken, Token endToken) {
    super.endFields(count, beginToken, endToken);
    VariableDefinitions variableDefinitions = popNode();
    Modifiers modifiers = variableDefinitions.modifiers;
    pushNode(null);
    void buildFieldElement(SourceString name, Element fields) {
      Element element = new VariableElement(
          name, fields, ElementKind.FIELD, enclosingElement);
      addMember(element);
    }
    buildFieldElements(modifiers, variableDefinitions.definitions,
                       enclosingElement,
                       buildFieldElement, beginToken, endToken);
  }

  void endInitializer(Token assignmentOperator) {
    pushNode(null); // Super expects an expression, but
                    // ClassElementParser just skips expressions.
    super.endInitializer(assignmentOperator);
  }

  void endInitializers(int count, Token beginToken, Token endToken) {
    pushNode(null);
  }

  void addMember(Element memberElement) {
    enclosingElement.addMember(memberElement, listener);
  }
}
