// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

class ClassElementParser extends PartialParser {
  ClassElementParser(Listener listener) : super(listener);

  Token parseClassBody(Token token) => fullParseClassBody(token);
}

class PartialClassElement extends ClassElementX with PartialElement {
  ClassNode cachedNode;

  PartialClassElement(String name,
                      Token beginToken,
                      Token endToken,
                      Element enclosing,
                      int id)
      : super(name, enclosing, id, STATE_NOT_STARTED) {
    this.beginToken = beginToken;
    this.endToken = endToken;
  }

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

  bool get hasNode => cachedNode != null;

  ClassNode get node {
    assert(invariant(this, cachedNode != null,
        message: "Node has not been computed for $this."));
    return cachedNode;
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
        assert(invariant(beginToken, listener.nodes.isEmpty,
            message: "Non-empty listener stack: ${listener.nodes}"));
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

  Token get position => beginToken;

  // TODO(johnniwinther): Ensure that modifiers are always available.
  Modifiers get modifiers =>
      cachedNode != null ? cachedNode.modifiers : Modifiers.EMPTY;

  accept(ElementVisitor visitor) => visitor.visitClassElement(this);

  PartialClassElement copyWithEnclosing(CompilationUnitElement enclosing) {
    return new PartialClassElement(name, beginToken, endToken, enclosing, id);
  }
}

class MemberListener extends NodeListener {
  final ClassElement enclosingElement;

  MemberListener(DiagnosticListener listener,
                 Element enclosingElement)
      : this.enclosingElement = enclosingElement,
        super(listener, enclosingElement.compilationUnit);

  bool isConstructorName(Node nameNode) {
    if (enclosingElement == null ||
        enclosingElement.kind != ElementKind.CLASS) {
      return false;
    }
    String name;
    if (nameNode.asIdentifier() != null) {
      name = nameNode.asIdentifier().source;
    } else {
      Send send = nameNode.asSend();
      name = send.receiver.asIdentifier().source;
    }
    return enclosingElement.name == name;
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
      if (receiver == null || receiver.source != enclosingElement.name) {
        listener.reportError(send.receiver,
                                 MessageKind.INVALID_CONSTRUCTOR_NAME,
                                 {'name': enclosingElement.name});
      }
      return selector.source;
    }
  }

  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    super.endMethod(getOrSet, beginToken, endToken);
    FunctionExpression method = popNode();
    pushNode(null);
    bool isConstructor = isConstructorName(method.name);
    String name = getMethodNameHack(method.name);
    Element memberElement;
    if (isConstructor) {
      if (getOrSet != null) {
        recoverableError(getOrSet, 'illegal modifier');
      }
      memberElement = new PartialConstructorElement(
          name, beginToken, endToken,
          ElementKind.GENERATIVE_CONSTRUCTOR,
          method.modifiers,
          enclosingElement);
    } else {
      ElementKind kind = ElementKind.FUNCTION;
      if (getOrSet != null) {
        kind = (identical(getOrSet.stringValue, 'get'))
               ? ElementKind.GETTER : ElementKind.SETTER;
      }
      memberElement =
          new PartialFunctionElement(name, beginToken, getOrSet, endToken,
                                     kind, method.modifiers, enclosingElement,
                                     !method.hasBody());
    }
    addMember(memberElement);
  }

  void endFactoryMethod(Token beginToken, Token endToken) {
    super.endFactoryMethod(beginToken, endToken);
    FunctionExpression method = popNode();
    pushNode(null);
    String name = getMethodNameHack(method.name);
    Identifier singleIdentifierName = method.name.asIdentifier();
    if (singleIdentifierName != null && singleIdentifierName.source == name) {
      if (name != enclosingElement.name) {
        listener.reportError(singleIdentifierName,
                                 MessageKind.INVALID_UNNAMED_CONSTRUCTOR_NAME,
                                 {'name': enclosingElement.name});
      }
    }
    ElementKind kind = ElementKind.FUNCTION;
    Element memberElement = new PartialConstructorElement(
        name, beginToken, endToken,
        ElementKind.FUNCTION,
        method.modifiers,
        enclosingElement);
    addMember(memberElement);
  }

  void endFields(int count, Token beginToken, Token endToken) {
    bool hasParseError = memberErrors.head;
    super.endFields(count, beginToken, endToken);
    VariableDefinitions variableDefinitions = popNode();
    Modifiers modifiers = variableDefinitions.modifiers;
    pushNode(null);
    void buildFieldElement(Identifier name, VariableList fields) {
      Element element =
          new FieldElementX(name, enclosingElement, fields);
      addMember(element);
    }
    buildFieldElements(modifiers, variableDefinitions.definitions,
                       enclosingElement,
                       buildFieldElement, beginToken, endToken,
                       hasParseError);
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

  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    popNode(); // Discard arguments.
    if (periodBeforeName != null) {
      popNode(); // Discard name.
    }
    popNode(); // Discard node (Send or Identifier).
    pushMetadata(new PartialMetadataAnnotation(beginToken, endToken));
  }
}
