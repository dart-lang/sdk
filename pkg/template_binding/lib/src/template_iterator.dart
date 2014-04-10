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

// Dart note: this was added to decouple the MustacheTokens.parse function from
// the rest of template_binding.
_getDelegateFactory(name, node, delegate) {
  if (delegate == null) return null;
  return (pathString) => delegate.prepareBinding(pathString, name, node);
}

_InstanceBindingMap _getBindings(Node node, BindingDelegate delegate) {
  if (node is Element) {
    return _parseAttributeBindings(node, delegate);
  }

  if (node is Text) {
    var tokens = MustacheTokens.parse(node.text,
        _getDelegateFactory('text', node, delegate));
    if (tokens != null) return new _InstanceBindingMap(['text', tokens]);
  }

  return null;
}

void _addBindings(Node node, model, [BindingDelegate delegate]) {
  final bindings = _getBindings(node, delegate);
  if (bindings != null) {
    _processBindings(node, bindings, model);
  }

  for (var c = node.firstChild; c != null; c = c.nextNode) {
    _addBindings(c, model, delegate);
  }
}

MustacheTokens _parseWithDefault(Element element, String name,
    BindingDelegate delegate) {

  var v = element.attributes[name];
  if (v == '') v = '{{}}';
  return MustacheTokens.parse(v, _getDelegateFactory(name, element, delegate));
}

_InstanceBindingMap _parseAttributeBindings(Element element,
    BindingDelegate delegate) {

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

    if (isTemplateNode &&
        (name == 'bind' || name == 'if' || name == 'repeat')) {
      return;
    }

    var tokens = MustacheTokens.parse(value,
        _getDelegateFactory(name, element, delegate));
    if (tokens != null) {
      if (bindings == null) bindings = [];
      bindings..add(name)..add(tokens);
    }
  });

  if (isTemplateNode) {
    if (bindings == null) bindings = [];
    var result = new _TemplateBindingMap(bindings)
        .._if = _parseWithDefault(element, 'if', delegate)
        .._bind = _parseWithDefault(element, 'bind', delegate)
        .._repeat = _parseWithDefault(element, 'repeat', delegate);

    // Treat <template if> as <template bind if>
    if (result._if != null && result._bind == null && result._repeat == null) {
      result._bind = MustacheTokens.parse('{{}}',
          _getDelegateFactory('bind', element, delegate));
    }

    return result;
  }

  return bindings == null ? null : new _InstanceBindingMap(bindings);
}

_processOneTimeBinding(String name, MustacheTokens tokens, Node node, model) {

  if (tokens.hasOnePath) {
    var delegateFn = tokens.getPrepareBinding(0);
    var value = delegateFn != null ? delegateFn(model, node, true) :
        tokens.getPath(0).getValueFrom(model);
    return tokens.isSimplePath ? value : tokens.combinator(value);
  }

  // Tokens uses a striding scheme to essentially store a sequence of structs in
  // the list. See _MustacheTokens for more information.
  var values = new List(tokens.length);
  for (int i = 0; i < tokens.length; i++) {
    Function delegateFn = tokens.getPrepareBinding(i);
    values[i] = delegateFn != null ?
        delegateFn(model, node, false) :
        tokens.getPath(i).getValueFrom(model);
  }
  return tokens.combinator(values);
}

_processSinglePathBinding(String name, MustacheTokens tokens, Node node,
    model) {
  Function delegateFn = tokens.getPrepareBinding(0);
  var observer = delegateFn != null ?
      delegateFn(model, node, false) :
      new PathObserver(model, tokens.getPath(0));

  return tokens.isSimplePath ? observer :
      new ObserverTransform(observer, tokens.combinator);
}

_processBinding(String name, MustacheTokens tokens, Node node, model) {
  if (tokens.onlyOneTime) {
    return _processOneTimeBinding(name, tokens, node, model);
  }
  if (tokens.hasOnePath) {
    return _processSinglePathBinding(name, tokens, node, model);
  }

  var observer = new CompoundObserver();

  for (int i = 0; i < tokens.length; i++) {
    bool oneTime = tokens.getOneTime(i);
    Function delegateFn = tokens.getPrepareBinding(i);

    if (delegateFn != null) {
      var value = delegateFn(model, node, oneTime);
      if (oneTime) {
        observer.addPath(value);
      } else {
        observer.addObserver(value);
      }
      continue;
    }

    PropertyPath path = tokens.getPath(i);
    if (oneTime) {
      observer.addPath(path.getValueFrom(model));
    } else {
      observer.addPath(model, path);
    }
  }

  return new ObserverTransform(observer, tokens.combinator);
}

void _processBindings(Node node, _InstanceBindingMap map, model,
    [List<Bindable> instanceBindings]) {

  final bindings = map.bindings;
  for (var i = 0; i < bindings.length; i += 2) {
    var name = bindings[i];
    var tokens = bindings[i + 1];

    var value = _processBinding(name, tokens, node, model);
    var binding = nodeBind(node).bind(name, value, oneTime: tokens.onlyOneTime);
    if (binding != null && instanceBindings != null) {
      instanceBindings.add(binding);
    }
  }

  if (map is! _TemplateBindingMap) return;

  final templateExt = nodeBindFallback(node);
  templateExt._model = model;

  var iter = templateExt._processBindingDirectives(map);
  if (iter != null && instanceBindings != null) {
    instanceBindings.add(iter);
  }
}


// Note: this doesn't really implement most of Bindable. See:
// https://github.com/Polymer/TemplateBinding/issues/147
class _TemplateIterator extends Bindable {
  final TemplateBindExtension _templateExt;

  /**
   * Flattened array of tuples:
   * <instanceTerminatorNode, [bindingsSetupByInstance]>
   */
  final List _terminators = [];

  /** A copy of the last rendered [_presentValue] list state. */
  final List _iteratedValue = [];

  List _presentValue;

  bool _closed = false;

  // Dart note: instead of storing these in a Map like JS, or using a separate
  // object (extra memory overhead) we just inline the fields.
  var _ifValue, _value;

  // TODO(jmesserly): lots of booleans in this object. Bitmask?
  bool _hasIf, _hasRepeat;
  bool _ifOneTime, _oneTime;

  StreamSubscription _listSub;

  bool _initPrepareFunctions = false;
  PrepareInstanceModelFunction _instanceModelFn;
  PrepareInstancePositionChangedFunction _instancePositionChangedFn;

  _TemplateIterator(this._templateExt);

  open(callback) => throw new StateError('binding already opened');
  get value => _value;

  Element get _templateElement => _templateExt._node;

  void _closeDependencies() {
    if (_ifValue is Bindable) {
      _ifValue.close();
      _ifValue = null;
    }
    if (_value is Bindable) {
      _value.close();
      _value = null;
    }
  }

  void _updateDependencies(_TemplateBindingMap directives, model) {
    _closeDependencies();

    final template = _templateElement;

    _hasIf = directives._if != null;
    _hasRepeat = directives._repeat != null;

    if (_hasIf) {
      _ifOneTime = directives._if.onlyOneTime;
      _ifValue = _processBinding('if', directives._if, template, model);

      // oneTime if & predicate is false. nothing else to do.
      if (_ifOneTime) {
        if (!_toBoolean(_ifValue)) {
          _updateIteratedValue(null);
          return;
        }
      } else {
        (_ifValue as Bindable).open(_updateIteratedValue);
      }
    }

    if (_hasRepeat) {
      _oneTime = directives._repeat.onlyOneTime;
      _value = _processBinding('repeat', directives._repeat, template, model);
    } else {
      _oneTime = directives._bind.onlyOneTime;
      _value = _processBinding('bind', directives._bind, template, model);
    }

    if (!_oneTime) _value.open(_updateIteratedValue);

    _updateIteratedValue(null);
  }

  void _updateIteratedValue(_) {
    if (_hasIf) {
      var ifValue = _ifValue;
      if (!_ifOneTime) ifValue = (ifValue as Bindable).value;
      if (!_toBoolean(ifValue)) {
        _valueChanged([]);
        return;
      }
    }

    var value = _value;
    if (!_oneTime) value = (value as Bindable).value;
    if (!_hasRepeat) value = [value];
    _valueChanged(value);
  }

  void _valueChanged(Object value) {
    if (value is! List) {
      if (value is Iterable) {
        // Dart note: we support Iterable by calling toList.
        // But we need to be careful to observe the original iterator if it
        // supports that.
        value = (value as Iterable).toList();
      } else {
        value = [];
      }
    }

    if (identical(value, _iteratedValue)) return;

    _unobserve();
    _presentValue = value;

    if (value is ObservableList && _hasRepeat && !_oneTime) {
      // Make sure any pending changes aren't delivered, since we're getting
      // a snapshot at this point in time.
      value.discardListChages();
      _listSub = value.listChanges.listen(_handleSplices);
    }

    _handleSplices(ObservableList.calculateChangeRecords(
        _iteratedValue != null ? _iteratedValue : [],
        _presentValue != null ? _presentValue : []));
  }

  Node _getTerminatorAt(int index) {
    if (index == -1) return _templateElement;
    var terminator = _terminators[index * 2];
    if (!isSemanticTemplate(terminator) ||
        identical(terminator, _templateElement)) {
      return terminator;
    }

    var subIter = templateBindFallback(terminator)._iterator;
    if (subIter == null) return terminator;

    return subIter._getTerminatorAt(subIter._terminators.length ~/ 2 - 1);
  }

  // TODO(rafaelw): If we inserting sequences of instances we can probably
  // avoid lots of calls to _getTerminatorAt(), or cache its result.
  void _insertInstanceAt(int index, DocumentFragment fragment,
        List<Node> instanceNodes, List<Bindable> instanceBindings) {

    var previousTerminator = _getTerminatorAt(index - 1);
    var terminator = null;
    if (fragment != null) {
      terminator = fragment.lastChild;
    } else if (instanceNodes != null && instanceNodes.isNotEmpty) {
      terminator = instanceNodes.last;
    }
    if (terminator == null) terminator = previousTerminator;

    _terminators.insertAll(index * 2, [terminator, instanceBindings]);
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

  _BoundNodes _extractInstanceAt(int index) {
    var instanceNodes = <Node>[];
    var previousTerminator = _getTerminatorAt(index - 1);
    var terminator = _getTerminatorAt(index);
    var instanceBindings = _terminators[index * 2 + 1];
    _terminators.removeRange(index * 2, index * 2 + 2);

    var parent = _templateElement.parentNode;
    while (terminator != previousTerminator) {
      var node = previousTerminator.nextNode;
      if (node == terminator) terminator = previousTerminator;
      node.remove();
      instanceNodes.add(node);
    }
    return new _BoundNodes(instanceNodes, instanceBindings);
  }

  void _handleSplices(List<ListChangeRecord> splices) {
    if (_closed || splices.isEmpty) return;

    final template = _templateElement;

    if (template.parentNode == null) {
      close();
      return;
    }

    ObservableList.applyChangeRecords(_iteratedValue, _presentValue, splices);

    final delegate = _templateExt.bindingDelegate;

    // Dart note: the JavaScript code relies on the distinction between null
    // and undefined to track whether the functions are prepared. We use a bool.
    if (!_initPrepareFunctions) {
      _initPrepareFunctions = true;
      final delegate = _templateExt._self.bindingDelegate;
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
        instanceCache[model] = _extractInstanceAt(splice.index + removeDelta);
      }

      removeDelta -= splice.addedCount;
    }

    for (var splice in splices) {
      for (var addIndex = splice.index;
          addIndex < splice.index + splice.addedCount;
          addIndex++) {

        var model = _iteratedValue[addIndex];
        var fragment = null;
        var instance = instanceCache.remove(model);
        List instanceBindings;
        List instanceNodes = null;
        if (instance != null && instance.nodes.isNotEmpty) {
          instanceBindings = instance.instanceBindings;
          instanceNodes = instance.nodes;
        } else {
          try {
            instanceBindings = [];
            if (_instanceModelFn != null) {
              model = _instanceModelFn(model);
            }
            if (model != null) {
              fragment = _templateExt.createInstance(model, delegate,
                  instanceBindings);
            }
          } catch (e, s) {
            // Dart note: we propagate errors asynchronously here to avoid
            // disrupting the rendering flow. This is different than in the JS
            // implementation but it should probably be fixed there too. Dart
            // hits this case more because non-existing properties in
            // [PropertyPath] are treated as errors, while JS treats them as
            // null/undefined.
            // TODO(sigmund): this should be a synchronous throw when this is
            // called from createInstance, but that requires enough refactoring
            // that it should be done upstream first. See dartbug.com/17789.
            new Completer().completeError(e, s);
          }
        }

        _insertInstanceAt(addIndex, fragment, instanceNodes, instanceBindings);
      }
    }

    for (var instance in instanceCache.values) {
      _closeInstanceBindings(instance.instanceBindings);
    }

    if (_instancePositionChangedFn != null) _reportInstancesMoved(splices);
  }

  void _reportInstanceMoved(int index) {
    var previousTerminator = _getTerminatorAt(index - 1);
    var terminator = _getTerminatorAt(index);
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

  void _reportInstancesMoved(List<ListChangeRecord> splices) {
    var index = 0;
    var offset = 0;
    for (var splice in splices) {
      if (offset != 0) {
        while (index < splice.index) {
          _reportInstanceMoved(index);
          index++;
        }
      } else {
        index = splice.index;
      }

      while (index < splice.index + splice.addedCount) {
        _reportInstanceMoved(index);
        index++;
      }

      offset += splice.addedCount - splice.removed.length;
    }

    if (offset == 0) return;

    var length = _terminators.length ~/ 2;
    while (index < length) {
      _reportInstanceMoved(index);
      index++;
    }
  }

  void _closeInstanceBindings(List<Bindable> instanceBindings) {
    for (var binding in instanceBindings) binding.close();
  }

  void _unobserve() {
    if (_listSub == null) return;
    _listSub.cancel();
    _listSub = null;
  }

  void close() {
    if (_closed) return;

    _unobserve();
    for (var i = 1; i < _terminators.length; i += 2) {
      _closeInstanceBindings(_terminators[i]);
    }

    _terminators.clear();
    _closeDependencies();
    _templateExt._iterator = null;
    _closed = true;
  }
}

// Dart note: the JavaScript version just puts an expando on the array.
class _BoundNodes {
  final List<Node> nodes;
  final List<Bindable> instanceBindings;
  _BoundNodes(this.nodes, this.instanceBindings);
}
