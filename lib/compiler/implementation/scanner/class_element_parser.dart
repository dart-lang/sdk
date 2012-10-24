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
  ClassNode cachedNode;

  PartialClassElement(SourceString name,
                      Token this.beginToken,
                      Token this.endToken,
                      Element enclosing,
                      int id)
      : super(name, enclosing, id, STATE_NOT_STARTED);

  void set supertypeLoadState(int state) {
    assert(state == supertypeLoadState + 1);
    assert(state <= STATE_DONE);
    super.supertypeLoadState = state;
  }

  void set resolutionState(int state) {
    assert(state == resolutionState + 1);
    assert(state <= STATE_DONE);
    super.resolutionState = state;
  }

  ClassNode parseNode(Compiler compiler) {
    if (cachedNode != null) return cachedNode;
    compiler.withCurrentElement(this, () {
      compiler.parser.measure(() {
        MemberListener listener = new MemberListener(compiler, this);
        Parser parser = new ClassElementParser(listener);
        Token token = parser.parseTopLevelDeclaration(beginToken);
        assert(identical(token, endToken.next));
        cachedNode = listener.popNode();
        assert(listener.nodes.isEmpty);
      });
      compiler.patchParser.measure(() {
        if (isPatched) {
          // TODO(lrn): Perhaps extract functionality so it doesn't
          // need compiler.
          compiler.patchParser.parsePatchClassNode(patch);
        }
      });
    });
    return cachedNode;
  }

  Token position() => beginToken;

  // TODO(johnniwinther): Ensure that modifiers are always available.
  Modifiers get modifiers =>
      cachedNode != null ? cachedNode.modifiers : Modifiers.EMPTY;

  bool isInterface() => identical(beginToken.stringValue, "interface");
}

class MemberListener extends NodeListener {
  final ClassElement enclosingElement;

  MemberListener(DiagnosticListener listener,
                 Element enclosingElement)
      : this.enclosingElement = enclosingElement,
        super(listener, enclosingElement.getCompilationUnit());

  bool isConstructorName(Node nameNode) {
    if (enclosingElement == null ||
        enclosingElement.kind != ElementKind.CLASS) {
      return false;
    }
    SourceString name;
    if (nameNode.asIdentifier() != null) {
      name = nameNode.asIdentifier().source;
    } else {
      Send send = nameNode.asSend();
      name = send.receiver.asIdentifier().source;
    }
    return enclosingElement.name == name;
  }

  SourceString getMethodNameHack(Node methodName) {
    Send send = methodName.asSend();
    if (send == null) return methodName.asIdentifier().source;
    Identifier receiver = send.receiver.asIdentifier();
    Identifier selector = send.selector.asIdentifier();
    Operator operator = selector.asOperator();
    if (operator != null) {
      assert(identical(receiver.source.stringValue, 'operator'));
      // TODO(ahe): It is a hack to compare to ')', but it beats
      // parsing the node.
      bool isUnary = identical(operator.token.next.next.stringValue, ')');
      return Elements.constructOperatorName(operator.source, isUnary);
    } else {
      if (receiver == null) {
        listener.cancel('library prefix in named factory constructor not '
                        'implemented', node: send.receiver);
      }
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
      if (getOrSet != null) {
        recoverableError('illegal modifier', token: getOrSet);
      }
      kind = ElementKind.GENERATIVE_CONSTRUCTOR;
    } else if (getOrSet != null) {
      kind = (identical(getOrSet.stringValue, 'get'))
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
      Element element =
          new VariableElement(name, fields, ElementKind.FIELD, null);
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
    for (Link link = metadata; !link.isEmpty; link = link.tail) {
      memberElement.addMetadata(link.head);
    }
    metadata = const Link<MetadataAnnotation>();
    enclosingElement.addMember(memberElement, listener);
  }
}
