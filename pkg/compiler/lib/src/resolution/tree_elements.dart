// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

abstract class TreeElements {
  AnalyzableElement get analyzedElement;
  Iterable<Node> get superUses;

  /// Iterables of the dependencies that this [TreeElement] records of
  /// [analyzedElement].
  Iterable<Element> get allElements;

  void forEachConstantNode(f(Node n, ConstantExpression c));
  void forEachType(f(Node n, DartType t));

  /// A set of additional dependencies.  See [registerDependency] below.
  Iterable<Element> get otherDependencies;

  Element operator[](Node node);

  SendStructure getSendStructure(Send send);

  // TODO(johnniwinther): Investigate whether [Node] could be a [Send].
  Selector getSelector(Node node);
  Selector getGetterSelectorInComplexSendSet(SendSet node);
  Selector getOperatorSelectorInComplexSendSet(SendSet node);
  DartType getType(Node node);
  TypeMask getTypeMask(Node node);
  TypeMask getGetterTypeMaskInComplexSendSet(SendSet node);
  TypeMask getOperatorTypeMaskInComplexSendSet(SendSet node);
  void setTypeMask(Node node, TypeMask mask);
  void setGetterTypeMaskInComplexSendSet(SendSet node, TypeMask mask);
  void setOperatorTypeMaskInComplexSendSet(SendSet node, TypeMask mask);

  /// Returns the for-in loop variable for [node].
  Element getForInVariable(ForIn node);
  Selector getIteratorSelector(ForIn node);
  Selector getMoveNextSelector(ForIn node);
  Selector getCurrentSelector(ForIn node);
  TypeMask getIteratorTypeMask(ForIn node);
  TypeMask getMoveNextTypeMask(ForIn node);
  TypeMask getCurrentTypeMask(ForIn node);
  void setIteratorTypeMask(ForIn node, TypeMask mask);
  void setMoveNextTypeMask(ForIn node, TypeMask mask);
  void setCurrentTypeMask(ForIn node, TypeMask mask);
  void setConstant(Node node, ConstantExpression constant);
  ConstantExpression getConstant(Node node);
  bool isAssert(Send send);

  /// Returns the [FunctionElement] defined by [node].
  FunctionElement getFunctionDefinition(FunctionExpression node);

  /// Returns target constructor for the redirecting factory body [node].
  ConstructorElement getRedirectingTargetConstructor(
      RedirectingFactoryBody node);

  /**
   * Returns [:true:] if [node] is a type literal.
   *
   * Resolution marks this by setting the type on the node to be the
   * type that the literal refers to.
   */
  bool isTypeLiteral(Send node);

  /// Returns the type that the type literal [node] refers to.
  DartType getTypeLiteralType(Send node);

  /// Register additional dependencies required by [analyzedElement].
  /// For example, elements that are used by a backend.
  void registerDependency(Element element);

  /// Returns a list of nodes that potentially mutate [element] anywhere in its
  /// scope.
  List<Node> getPotentialMutations(VariableElement element);

  /// Returns a list of nodes that potentially mutate [element] in [node].
  List<Node> getPotentialMutationsIn(Node node, VariableElement element);

  /// Returns a list of nodes that potentially mutate [element] in a closure.
  List<Node> getPotentialMutationsInClosure(VariableElement element);

  /// Returns a list of nodes that access [element] within a closure in [node].
  List<Node> getAccessesByClosureIn(Node node, VariableElement element);

  /// Returns the jump target defined by [node].
  JumpTarget getTargetDefinition(Node node);

  /// Returns the jump target of the [node].
  JumpTarget getTargetOf(GotoStatement node);

  /// Returns the label defined by [node].
  LabelDefinition getLabelDefinition(Label node);

  /// Returns the label that [node] targets.
  LabelDefinition getTargetLabel(GotoStatement node);
}

class TreeElementMapping extends TreeElements {
  final AnalyzableElement analyzedElement;
  Map<Spannable, Selector> _selectors;
  Map<Spannable, TypeMask> _typeMasks;
  Map<Node, DartType> _types;
  Setlet<Node> _superUses;
  Setlet<Element> _otherDependencies;
  Map<Node, ConstantExpression> _constants;
  Map<VariableElement, List<Node>> _potentiallyMutated;
  Map<Node, Map<VariableElement, List<Node>>> _potentiallyMutatedIn;
  Map<VariableElement, List<Node>> _potentiallyMutatedInClosure;
  Map<Node, Map<VariableElement, List<Node>>> _accessedByClosureIn;
  Setlet<Element> _elements;
  Setlet<Send> _asserts;
  Maplet<Send, SendStructure> _sendStructureMap;

  /// Map from nodes to the targets they define.
  Map<Node, JumpTarget> _definedTargets;

  /// Map from goto statements to their targets.
  Map<GotoStatement, JumpTarget> _usedTargets;

  /// Map from labels to their label definition.
  Map<Label, LabelDefinition> _definedLabels;

  /// Map from labeled goto statements to the labels they target.
  Map<GotoStatement, LabelDefinition> _targetLabels;

  final int hashCode = ++_hashCodeCounter;
  static int _hashCodeCounter = 0;

  TreeElementMapping(this.analyzedElement);

  operator []=(Node node, Element element) {
    // TODO(johnniwinther): Simplify this invariant to use only declarations in
    // [TreeElements].
    assert(invariant(node, () {
      if (!element.isErroneous && analyzedElement != null && element.isPatch) {
        return analyzedElement.implementationLibrary.isPatch;
      }
      return true;
    }));
    // TODO(ahe): Investigate why the invariant below doesn't hold.
    // assert(invariant(node,
    //                  getTreeElement(node) == element ||
    //                  getTreeElement(node) == null,
    //                  message: '${getTreeElement(node)}; $element'));

    if (_elements == null) {
      _elements = new Setlet<Element>();
    }
    _elements.add(element);
    setTreeElement(node, element);
  }

  operator [](Node node) => getTreeElement(node);

  SendStructure getSendStructure(Send send) {
    if (_sendStructureMap == null) return null;
    return _sendStructureMap[send];
  }

  void setSendStructure(Send send, SendStructure sendStructure) {
    if (_sendStructureMap == null) {
      _sendStructureMap = new Maplet<Send, SendStructure>();
    }
    _sendStructureMap[send] = sendStructure;
  }

  void setType(Node node, DartType type) {
    if (_types == null) {
      _types = new Maplet<Node, DartType>();
    }
    _types[node] = type;
  }

  DartType getType(Node node) => _types != null ? _types[node] : null;

  void forEachType(f(Node n, DartType t)) {
    if (_types != null) {
      _types.forEach(f);
    }
  }

  Iterable<Node> get superUses {
    return _superUses != null ? _superUses : const <Node>[];
  }

  void addSuperUse(Node node) {
    if (_superUses == null) {
      _superUses = new Setlet<Node>();
    }
    _superUses.add(node);
  }

  Selector _getSelector(Spannable node) {
    return _selectors != null ? _selectors[node] : null;
  }

  void _setSelector(Spannable node, Selector selector) {
    if (_selectors == null) {
      _selectors = new Maplet<Spannable, Selector>();
    }
    _selectors[node] = selector;
  }

  void setSelector(Node node, Selector selector) {
    _setSelector(node, selector);
  }

  Selector getSelector(Node node) => _getSelector(node);

  int getSelectorCount() => _selectors == null ? 0 : _selectors.length;

  void setGetterSelectorInComplexSendSet(SendSet node, Selector selector) {
    _setSelector(node.selector, selector);
  }

  Selector getGetterSelectorInComplexSendSet(SendSet node) {
    return _getSelector(node.selector);
  }

  void setOperatorSelectorInComplexSendSet(SendSet node, Selector selector) {
    _setSelector(node.assignmentOperator, selector);
  }

  Selector getOperatorSelectorInComplexSendSet(SendSet node) {
    return _getSelector(node.assignmentOperator);
  }

  // The following methods set selectors on the "for in" node. Since
  // we're using three selectors, we need to use children of the node,
  // and we arbitrarily choose which ones.

  void setIteratorSelector(ForIn node, Selector selector) {
    _setSelector(node, selector);
  }

  Selector getIteratorSelector(ForIn node) {
    return _getSelector(node);
  }

  void setMoveNextSelector(ForIn node, Selector selector) {
    _setSelector(node.forToken, selector);
  }

  Selector getMoveNextSelector(ForIn node) {
    return _getSelector(node.forToken);
  }

  void setCurrentSelector(ForIn node, Selector selector) {
    _setSelector(node.inToken, selector);
  }

  Selector getCurrentSelector(ForIn node) {
    return _getSelector(node.inToken);
  }

  Element getForInVariable(ForIn node) {
    return this[node];
  }

  void setConstant(Node node, ConstantExpression constant) {
    if (_constants == null) {
      _constants = new Maplet<Node, ConstantExpression>();
    }
    _constants[node] = constant;
  }

  ConstantExpression getConstant(Node node) {
    return _constants != null ? _constants[node] : null;
  }

  bool isTypeLiteral(Send node) {
    return getType(node) != null;
  }

  DartType getTypeLiteralType(Send node) {
    return getType(node);
  }

  void registerDependency(Element element) {
    if (element == null) return;
    if (_otherDependencies == null) {
      _otherDependencies = new Setlet<Element>();
    }
    _otherDependencies.add(element.implementation);
  }

  Iterable<Element> get otherDependencies {
    return _otherDependencies != null ? _otherDependencies : const <Element>[];
  }

  List<Node> getPotentialMutations(VariableElement element) {
    if (_potentiallyMutated == null) return const <Node>[];
    List<Node> mutations = _potentiallyMutated[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentialMutation(VariableElement element, Node mutationNode) {
    if (_potentiallyMutated == null) {
      _potentiallyMutated = new Maplet<VariableElement, List<Node>>();
    }
    _potentiallyMutated.putIfAbsent(element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getPotentialMutationsIn(Node node, VariableElement element) {
    if (_potentiallyMutatedIn == null) return const <Node>[];
    Map<VariableElement, List<Node>> mutationsIn = _potentiallyMutatedIn[node];
    if (mutationsIn == null) return const <Node>[];
    List<Node> mutations = mutationsIn[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentialMutationIn(Node contextNode, VariableElement element,
                                    Node mutationNode) {
    if (_potentiallyMutatedIn == null) {
      _potentiallyMutatedIn =
          new Maplet<Node, Map<VariableElement, List<Node>>>();
    }
    Map<VariableElement, List<Node>> mutationMap =
        _potentiallyMutatedIn.putIfAbsent(contextNode,
          () => new Maplet<VariableElement, List<Node>>());
    mutationMap.putIfAbsent(element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getPotentialMutationsInClosure(VariableElement element) {
    if (_potentiallyMutatedInClosure == null) return const <Node>[];
    List<Node> mutations = _potentiallyMutatedInClosure[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentialMutationInClosure(VariableElement element,
                                          Node mutationNode) {
    if (_potentiallyMutatedInClosure == null) {
      _potentiallyMutatedInClosure = new Maplet<VariableElement, List<Node>>();
    }
    _potentiallyMutatedInClosure.putIfAbsent(
        element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getAccessesByClosureIn(Node node, VariableElement element) {
    if (_accessedByClosureIn == null) return const <Node>[];
    Map<VariableElement, List<Node>> accessesIn = _accessedByClosureIn[node];
    if (accessesIn == null) return const <Node>[];
    List<Node> accesses = accessesIn[element];
    if (accesses == null) return const <Node>[];
    return accesses;
  }

  void setAccessedByClosureIn(Node contextNode, VariableElement element,
                              Node accessNode) {
    if (_accessedByClosureIn == null) {
      _accessedByClosureIn = new Map<Node, Map<VariableElement, List<Node>>>();
    }
    Map<VariableElement, List<Node>> accessMap =
        _accessedByClosureIn.putIfAbsent(contextNode,
          () => new Maplet<VariableElement, List<Node>>());
    accessMap.putIfAbsent(element, () => <Node>[]).add(accessNode);
  }

  String toString() => 'TreeElementMapping($analyzedElement)';

  Iterable<Element> get allElements {
    return _elements != null ? _elements : const <Element>[];
  }

  void forEachConstantNode(f(Node n, ConstantExpression c)) {
    if (_constants != null) {
      _constants.forEach(f);
    }
  }

  void setAssert(Send node) {
    if (_asserts == null) {
      _asserts = new Setlet<Send>();
    }
    _asserts.add(node);
  }

  bool isAssert(Send node) {
    return _asserts != null && _asserts.contains(node);
  }

  FunctionElement getFunctionDefinition(FunctionExpression node) {
    return this[node];
  }

  ConstructorElement getRedirectingTargetConstructor(
      RedirectingFactoryBody node) {
    return this[node];
  }

  void defineTarget(Node node, JumpTarget target) {
    if (_definedTargets == null) {
      _definedTargets = new Maplet<Node, JumpTarget>();
    }
    _definedTargets[node] = target;
  }

  void undefineTarget(Node node) {
    if (_definedTargets != null) {
      _definedTargets.remove(node);
      if (_definedTargets.isEmpty) {
        _definedTargets = null;
      }
    }
  }

  JumpTarget getTargetDefinition(Node node) {
    return _definedTargets != null ? _definedTargets[node] : null;
  }

  void registerTargetOf(GotoStatement node, JumpTarget target) {
    if (_usedTargets == null) {
      _usedTargets = new Maplet<GotoStatement, JumpTarget>();
    }
    _usedTargets[node] = target;
  }

  JumpTarget getTargetOf(GotoStatement node) {
    return _usedTargets != null ? _usedTargets[node] : null;
  }

  void defineLabel(Label label, LabelDefinition target) {
    if (_definedLabels == null) {
      _definedLabels = new Maplet<Label, LabelDefinition>();
    }
    _definedLabels[label] = target;
  }

  void undefineLabel(Label label) {
    if (_definedLabels != null) {
      _definedLabels.remove(label);
      if (_definedLabels.isEmpty) {
        _definedLabels = null;
      }
    }
  }

  LabelDefinition getLabelDefinition(Label label) {
    return _definedLabels != null ? _definedLabels[label] : null;
  }

  void registerTargetLabel(GotoStatement node, LabelDefinition label) {
    assert(node.target != null);
    if (_targetLabels == null) {
      _targetLabels = new Maplet<GotoStatement, LabelDefinition>();
    }
    _targetLabels[node] = label;
  }

  LabelDefinition getTargetLabel(GotoStatement node) {
    assert(node.target != null);
    return _targetLabels != null ? _targetLabels[node] : null;
  }

  TypeMask _getTypeMask(Spannable node) {
    return _typeMasks != null ? _typeMasks[node] : null;
  }

  void _setTypeMask(Spannable node, TypeMask mask) {
    if (_typeMasks == null) {
      _typeMasks = new Maplet<Spannable, TypeMask>();
    }
    _typeMasks[node] = mask;
  }

  void setTypeMask(Node node, TypeMask mask) {
    _setTypeMask(node, mask);
  }

  TypeMask getTypeMask(Node node) => _getTypeMask(node);

  void setGetterTypeMaskInComplexSendSet(SendSet node, TypeMask mask) {
    _setTypeMask(node.selector, mask);
  }

  TypeMask getGetterTypeMaskInComplexSendSet(SendSet node) {
    return _getTypeMask(node.selector);
  }

  void setOperatorTypeMaskInComplexSendSet(SendSet node, TypeMask mask) {
    _setTypeMask(node.assignmentOperator, mask);
  }

  TypeMask getOperatorTypeMaskInComplexSendSet(SendSet node) {
    return _getTypeMask(node.assignmentOperator);
  }

  // The following methods set selectors on the "for in" node. Since
  // we're using three selectors, we need to use children of the node,
  // and we arbitrarily choose which ones.

  void setIteratorTypeMask(ForIn node, TypeMask mask) {
    _setTypeMask(node, mask);
  }

  TypeMask getIteratorTypeMask(ForIn node) {
    return _getTypeMask(node);
  }

  void setMoveNextTypeMask(ForIn node, TypeMask mask) {
    _setTypeMask(node.forToken, mask);
  }

  TypeMask getMoveNextTypeMask(ForIn node) {
    return _getTypeMask(node.forToken);
  }

  void setCurrentTypeMask(ForIn node, TypeMask mask) {
    _setTypeMask(node.inToken, mask);
  }

  TypeMask getCurrentTypeMask(ForIn node) {
    return _getTypeMask(node.inToken);
  }
}

TreeElements _ensureTreeElements(AnalyzableElementX element) {
  if (element._treeElements == null) {
    element._treeElements = new TreeElementMapping(element);
  }
  return element._treeElements;
}

abstract class AnalyzableElementX implements AnalyzableElement {
  TreeElements _treeElements;

  bool get hasTreeElements => _treeElements != null;

  TreeElements get treeElements {
    assert(invariant(this, _treeElements !=null,
        message: "TreeElements have not been computed for $this."));
    return _treeElements;
  }

  void reuseElement() {
    _treeElements = null;
  }
}
