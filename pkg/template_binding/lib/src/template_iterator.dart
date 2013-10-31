// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

// This code is a port of what was formerly known as Model-Driven-Views, now
// located at:
//     https://github.com/polymer/TemplateBinding
//     https://github.com/polymer/NodeBind

// TODO(jmesserly): not sure what kind of boolean conversion rules to
// apply for template data-binding. HTML attributes are true if they're
// present. However Dart only treats "true" as true. Since this is HTML we'll
// use something closer to the HTML rules: null (missing) and false are false,
// everything else is true.
// See: https://github.com/polymer/TemplateBinding/issues/59
bool _toBoolean(value) => null != value && false != value;

List _getBindings(Node node, BindingDelegate delegate) {
  if (node is Element) {
    return _parseAttributeBindings(node, delegate);
  }

  if (node is Text) {
    var tokens = _parseMustaches(node.text, 'text', node, delegate);
    if (tokens != null) return ['text', tokens];
  }

  return null;
}

void _addBindings(Node node, model, [BindingDelegate delegate]) {
  var bindings = _getBindings(node, delegate);
  if (bindings != null) {
    _processBindings(bindings, node, model);
  }

  for (var c = node.firstChild; c != null; c = c.nextNode) {
    _addBindings(c, model, delegate);
  }
}


List _parseAttributeBindings(Element element, BindingDelegate delegate) {
  var bindings = null;
  var ifFound = false;
  var bindFound = false;
  var isTemplateNode = isSemanticTemplate(element);

  element.attributes.forEach((name, value) {
    // Allow bindings expressed in attributes to be prefixed with underbars.
    // We do this to allow correct semantics for browsers that don't implement
    // <template> where certain attributes might trigger side-effects -- and
    // for IE which sanitizes certain attributes, disallowing mustache
    // replacements in their text.
    while (name[0] == '_') {
      name = name.substring(1);
    }

    if (isTemplateNode) {
      if (name == 'if') {
        ifFound = true;
        if (value == '') value = '{{}}'; // Accept 'naked' if.
      } else if (name == 'bind' || name == 'repeat') {
        bindFound = true;
        if (value == '') value = '{{}}'; // Accept 'naked' bind & repeat.
      }
    }

    var tokens = _parseMustaches(value, name, element, delegate);
    if (tokens != null) {
      if (bindings == null) bindings = [];
      bindings..add(name)..add(tokens);
    }
  });

  // Treat <template if> as <template bind if>
  if (ifFound && !bindFound) {
    if (bindings == null) bindings = [];
    bindings..add('bind')
        ..add(_parseMustaches('{{}}', 'bind', element, delegate));
  }

  return bindings;
}

void _processBindings(List bindings, Node node, model,
    [List<NodeBinding> bound]) {

  for (var i = 0; i < bindings.length; i += 2) {
    var name = bindings[i];
    var tokens = bindings[i + 1];
    var bindingModel = model;
    var bindingPath = tokens.tokens[1];
    if (tokens.hasOnePath) {
      var delegateFn = tokens.tokens[2];
      if (delegateFn != null) {
        var delegateBinding = delegateFn(model, node);
        if (delegateBinding != null) {
          bindingModel = delegateBinding;
          bindingPath = 'value';
        }
      }

      if (!tokens.isSimplePath) {
        bindingModel = new PathObserver(bindingModel, bindingPath,
            computeValue: tokens.combinator);
        bindingPath = 'value';
      }
    } else {
      var observer = new CompoundPathObserver(computeValue: tokens.combinator);
      for (var j = 1; j < tokens.tokens.length; j += 3) {
        var subModel = model;
        var subPath = tokens.tokens[j];
        var delegateFn = tokens.tokens[j + 1];
        var delegateBinding = delegateFn != null ?
            delegateFn(subModel, node) : null;

        if (delegateBinding != null) {
          subModel = delegateBinding;
          subPath = 'value';
        }

        observer.addPath(subModel, subPath);
      }

      observer.start();
      bindingModel = observer;
      bindingPath = 'value';
    }

    var binding = nodeBind(node).bind(name, bindingModel, bindingPath);
    if (bound != null) bound.add(binding);
  }
}

/**
 * Parses {{ mustache }} bindings.
 *
 * Returns null if there are no matches. Otherwise returns the parsed tokens.
 */
_MustacheTokens _parseMustaches(String s, String name, Node node,
    BindingDelegate delegate) {
  if (s.isEmpty) return null;

  var tokens = null;
  var length = s.length;
  var startIndex = 0, lastIndex = 0, endIndex = 0;
  while (lastIndex < length) {
    startIndex = s.indexOf('{{', lastIndex);
    endIndex = startIndex < 0 ? -1 : s.indexOf('}}', startIndex + 2);

    if (endIndex < 0) {
      if (tokens == null) return null;

      tokens.add(s.substring(lastIndex)); // TEXT
      break;
    }

    if (tokens == null) tokens = [];
    tokens.add(s.substring(lastIndex, startIndex)); // TEXT
    var pathString = s.substring(startIndex + 2, endIndex).trim();
    tokens.add(pathString); // PATH
    var delegateFn = delegate == null ? null :
        delegate.prepareBinding(pathString, name, node);
    tokens.add(delegateFn);

    lastIndex = endIndex + 2;
  }

  if (lastIndex == length) tokens.add('');

  return new _MustacheTokens(tokens);
}

class _MustacheTokens {
  bool get hasOnePath => tokens.length == 4;
  bool get isSimplePath => hasOnePath && tokens[0] == '' && tokens[3] == '';

  /** [TEXT, (PATH, TEXT, DELEGATE_FN)+] if there is at least one mustache. */
  // TODO(jmesserly): clean up the type here?
  final List tokens;

  // Dart note: I think this is cached in JavaScript to avoid an extra
  // allocation per template instance. Seems reasonable, so we do the same.
  Function _combinator;
  Function get combinator => _combinator;

  _MustacheTokens(this.tokens) {
    // Should be: [TEXT, (PATH, TEXT, DELEGATE_FN)+].
    assert((tokens.length + 2) % 3 == 0);

    _combinator = hasOnePath ? _singleCombinator : _listCombinator;
  }

  // Dart note: split "combinator" into the single/list variants, so the
  // argument can be typed.
  String _singleCombinator(Object value) {
    if (value == null) value = '';
    return '${tokens[0]}$value${tokens[3]}';
  }

  String _listCombinator(List<Object> values) {
    var newValue = new StringBuffer(tokens[0]);
    for (var i = 1; i < tokens.length; i += 3) {
      var value = values[(i - 1) ~/ 3];
      if (value != null) newValue.write(value);
      newValue.write(tokens[i + 2]);
    }

    return newValue.toString();
  }
}

void _addTemplateInstanceRecord(fragment, model) {
  if (fragment.firstChild == null) {
    return;
  }

  var instanceRecord = new TemplateInstance(
      fragment.firstChild, fragment.lastChild, model);

  var node = instanceRecord.firstNode;
  while (node != null) {
    nodeBindFallback(node)._templateInstance = instanceRecord;
    node = node.nextNode;
  }
}

class _TemplateIterator {
  final TemplateBindExtension _templateExt;

  /**
   * Flattened array of tuples:
   * <instanceTerminatorNode, [bindingsSetupByInstance]>
   */
  final List terminators = [];
  List iteratedValue;
  bool closed = false;
  bool depsChanging = false;

  bool hasRepeat = false, hasBind = false, hasIf = false;
  Object repeatModel, bindModel, ifModel;
  String repeatPath, bindPath, ifPath;

  StreamSubscription _valueSub, _listSub;

  bool _initPrepareFunctions = false;
  PrepareInstanceModelFunction _instanceModelFn;
  PrepareInstancePositionChangedFunction _instancePositionChangedFn;

  _TemplateIterator(this._templateExt);

  Element get _templateElement => _templateExt._node;

  resolve() {
    depsChanging = false;

    if (_valueSub != null) {
      _valueSub.cancel();
      _valueSub = null;
    }

    if (!hasRepeat && !hasBind) {
      _valueChanged(null);
      return;
    }

    final model = hasRepeat ? repeatModel : bindModel;
    final path = hasRepeat ? repeatPath : bindPath;

    var valueObserver;
    if (!hasIf) {
      valueObserver = new PathObserver(model, path,
          computeValue: hasRepeat ? null : (x) => [x]);
    } else {
      // TODO(jmesserly): I'm not sure if closing over this is necessary for
      // correctness. It does seem useful if the valueObserver gets fired after
      // hasRepeat has changed, due to async nature of things.
      final isRepeat = hasRepeat;

      valueFn(List values) {
        var modelValue = values[0];
        var ifValue = values[1];
        if (!_toBoolean(ifValue)) return null;
        return isRepeat ? modelValue : [ modelValue ];
      }

      valueObserver = new CompoundPathObserver(computeValue: valueFn)
          ..addPath(model, path)
          ..addPath(ifModel, ifPath)
          ..start();
    }

    _valueSub = valueObserver.changes.listen(
        (r) => _valueChanged(r.last.newValue));
    _valueChanged(valueObserver.value);
  }

  void _valueChanged(newValue) {
    var oldValue = iteratedValue;
    unobserve();

    if (newValue is List) {
      iteratedValue = newValue;
    } else if (newValue is Iterable) {
      // Dart note: we support Iterable by calling toList.
      // But we need to be careful to observe the original iterator if it
      // supports that.
      iteratedValue = (newValue as Iterable).toList();
    } else {
      iteratedValue = null;
    }

    if (iteratedValue != null && newValue is ObservableList) {
      _listSub = newValue.listChanges.listen(_handleSplices);
    }

    var splices = ObservableList.calculateChangeRecords(
        oldValue != null ? oldValue : [],
        iteratedValue != null ? iteratedValue : []);

    if (splices.isNotEmpty) _handleSplices(splices);
  }

  Node getTerminatorAt(int index) {
    if (index == -1) return _templateElement;
    var terminator = terminators[index * 2];
    if (!isSemanticTemplate(terminator) ||
        identical(terminator, _templateElement)) {
      return terminator;
    }

    var subIter = templateBindFallback(terminator)._iterator;
    if (subIter == null) return terminator;

    return subIter.getTerminatorAt(subIter.terminators.length ~/ 2 - 1);
  }

  // TODO(rafaelw): If we inserting sequences of instances we can probably
  // avoid lots of calls to getTerminatorAt(), or cache its result.
  void insertInstanceAt(int index, DocumentFragment fragment,
        List<Node> instanceNodes, List<NodeBinding> bound) {

    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = null;
    if (fragment != null) {
      terminator = fragment.lastChild;
    } else if (instanceNodes != null && instanceNodes.isNotEmpty) {
      terminator = instanceNodes.last;
    }
    if (terminator == null) terminator = previousTerminator;

    terminators.insertAll(index * 2, [terminator, bound]);
    var parent = _templateElement.parentNode;
    var insertBeforeNode = previousTerminator.nextNode;

    if (fragment != null) {
      parent.insertBefore(fragment, insertBeforeNode);
    } else if (instanceNodes != null) {
      for (var node in instanceNodes) {
        parent.insertBefore(node, insertBeforeNode);
      }
    }
  }

  _BoundNodes extractInstanceAt(int index) {
    var instanceNodes = <Node>[];
    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = getTerminatorAt(index);
    var bound = terminators[index * 2 + 1];
    terminators.removeRange(index * 2, index * 2 + 2);

    var parent = _templateElement.parentNode;
    while (terminator != previousTerminator) {
      var node = previousTerminator.nextNode;
      if (node == terminator) terminator = previousTerminator;
      node.remove();
      instanceNodes.add(node);
    }
    return new _BoundNodes(instanceNodes, bound);
  }

  void _handleSplices(List<ListChangeRecord> splices) {
    if (closed) return;

    final template = _templateElement;
    final delegate = _templateExt._self.bindingDelegate;

    if (template.parentNode == null || template.ownerDocument.window == null) {
      close();
      return;
    }

    // Dart note: the JavaScript code relies on the distinction between null
    // and undefined to track whether the functions are prepared. We use a bool.
    if (!_initPrepareFunctions) {
      _initPrepareFunctions = true;
      if (delegate != null) {
        _instanceModelFn = delegate.prepareInstanceModel(template);
        _instancePositionChangedFn =
            delegate.prepareInstancePositionChanged(template);
      }
    }

    var instanceCache = new HashMap<Object, _BoundNodes>(equals: identical);
    var removeDelta = 0;
    for (var splice in splices) {
      for (var model in splice.removed) {
        instanceCache[model] = extractInstanceAt(splice.index + removeDelta);
      }

      removeDelta -= splice.addedCount;
    }

    for (var splice in splices) {
      for (var addIndex = splice.index;
          addIndex < splice.index + splice.addedCount;
          addIndex++) {

        var model = iteratedValue[addIndex];
        var fragment = null;
        var instance = instanceCache.remove(model);
        List bound;
        List instanceNodes = null;
        if (instance != null && instance.nodes.isNotEmpty) {
          bound = instance.bound;
          instanceNodes = instance.nodes;
        } else {
          bound = [];
          if (_instanceModelFn != null) {
            model = _instanceModelFn(model);
          }
          if (model != null) {
            fragment = _templateExt.createInstance(model, delegate, bound);
          }
        }

        insertInstanceAt(addIndex, fragment, instanceNodes, bound);
      }
    }

    for (var instance in instanceCache.values) {
      closeInstanceBindings(instance.bound);
    }

    if (_instancePositionChangedFn != null) reportInstancesMoved(splices);
  }

  void reportInstanceMoved(int index) {
    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = getTerminatorAt(index);
    if (identical(previousTerminator, terminator)) {
      return; // instance has zero nodes.
    }

    // We must use the first node of the instance, because any subsequent
    // nodes may have been generated by sub-templates.
    // TODO(rafaelw): This is brittle WRT instance mutation -- e.g. if the
    // first node was removed by script.
    var instance = nodeBind(previousTerminator.nextNode).templateInstance;
    _instancePositionChangedFn(instance, index);
  }

  void reportInstancesMoved(List<ListChangeRecord> splices) {
    var index = 0;
    var offset = 0;
    for (var splice in splices) {
      if (offset != 0) {
        while (index < splice.index) {
          reportInstanceMoved(index);
          index++;
        }
      } else {
        index = splice.index;
      }

      while (index < splice.index + splice.addedCount) {
        reportInstanceMoved(index);
        index++;
      }

      offset += splice.addedCount - splice.removed.length;
    }

    if (offset == 0) return;

    var length = terminators.length ~/ 2;
    while (index < length) {
      reportInstanceMoved(index);
      index++;
    }
  }

  void closeInstanceBindings(List<NodeBinding> bound) {
    for (var binding in bound) binding.close();
  }

  void unobserve() {
    if (_listSub == null) return;
    _listSub.cancel();
    _listSub = null;
  }

  void close() {
    if (closed) return;

    unobserve();
    for (var i = 1; i < terminators.length; i += 2) {
      closeInstanceBindings(terminators[i]);
    }

    terminators.clear();
    if (_valueSub != null) {
      _valueSub.cancel();
      _valueSub = null;
    }
    _templateExt._iterator = null;
    closed = true;
  }
}

// Dart note: the JavaScript version just puts an expando on the array.
class _BoundNodes {
  final List<Node> nodes;
  final List<NodeBinding> bound;
  _BoundNodes(this.nodes, this.bound);
}
