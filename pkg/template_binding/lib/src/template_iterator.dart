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

Node _createDeepCloneAndDecorateTemplates(Node node, BindingDelegate delegate) {
  var clone = node.clone(false); // Shallow clone.
  if (isSemanticTemplate(clone)) {
    TemplateBindExtension.decorate(clone, node);
    if (delegate != null) {
      templateBindFallback(clone)._bindingDelegate = delegate;
    }
  }

  for (var c = node.firstChild; c != null; c = c.nextNode) {
    clone.append(_createDeepCloneAndDecorateTemplates(c, delegate));
  }
  return clone;
}

void _addBindings(Node node, model, [BindingDelegate delegate]) {
  List bindings = null;
  if (node is Element) {
    bindings = _parseAttributeBindings(node);
  } else if (node is Text) {
    var tokens = _parseMustacheTokens(node.text);
    if (tokens != null) bindings = ['text', tokens];
  }

  if (bindings != null) {
    _processBindings(bindings, node, model, delegate);
  }

  for (var c = node.firstChild; c != null; c = c.nextNode) {
    _addBindings(c, model, delegate);
  }
}

List _parseAttributeBindings(Element element) {
  var bindings = null;
  var ifFound = false;
  var bindFound = false;
  var isTemplateNode = isSemanticTemplate(element);

  element.attributes.forEach((name, value) {
    if (isTemplateNode) {
      if (name == 'if') {
        ifFound = true;
      } else if (name == 'bind' || name == 'repeat') {
        bindFound = true;
        if (value == '') value = '{{}}';
      }
    }

    var tokens = _parseMustacheTokens(value);
    if (tokens != null) {
      if (bindings == null) bindings = [];
      bindings..add(name)..add(tokens);
    }
  });

  // Treat <template if> as <template bind if>
  if (ifFound && !bindFound) {
    if (bindings == null) bindings = [];
    bindings..add('bind')..add(_parseMustacheTokens('{{}}'));
  }

  return bindings;
}

void _processBindings(List bindings, Node node, model,
    BindingDelegate delegate) {

  for (var i = 0; i < bindings.length; i += 2) {
    _setupBinding(node, bindings[i], bindings[i + 1], model, delegate);
  }
}

void _setupBinding(Node node, String name, List tokens, model,
    BindingDelegate delegate) {

  if (_isSimpleBinding(tokens)) {
    _bindOrDelegate(node, name, model, tokens[1], delegate);
    return;
  }

  // TODO(jmesserly): MDV caches the closure on the tokens, but I'm not sure
  // why they do that instead of just caching the entire CompoundBinding object
  // and unbindAll then bind to the new model.
  var replacementBinding = new CompoundBinding()
      ..scheduled = true
      ..combinator = (values) {
    var newValue = new StringBuffer();

    for (var i = 0, text = true; i < tokens.length; i++, text = !text) {
      if (text) {
        newValue.write(tokens[i]);
      } else {
        var value = values[i];
        if (value != null) {
          newValue.write(value);
        }
      }
    }

    return newValue.toString();
  };

  for (var i = 1; i < tokens.length; i += 2) {
    // TODO(jmesserly): not sure if this index is correct. See my comment here:
    // https://github.com/Polymer/mdv/commit/f1af6fe683fd06eed2a7a7849f01c227db12cda3#L0L1035
    _bindOrDelegate(replacementBinding, i, model, tokens[i], delegate);
  }

  replacementBinding.resolve();

  nodeBind(node).bind(name, replacementBinding, 'value');
}

void _bindOrDelegate(node, name, model, String path,
    BindingDelegate delegate) {

  if (delegate != null) {
    var delegateBinding = delegate.getBinding(model, path, name, node);
    if (delegateBinding != null) {
      model = delegateBinding;
      path = 'value';
    }
  }

  if (node is CompoundBinding) {
    node.bind(name, model, path);
  } else {
    nodeBind(node).bind(name, model, path);
  }
}

/** True if and only if [tokens] is of the form `['', path, '']`. */
bool _isSimpleBinding(List<String> tokens) =>
    tokens.length == 3 && tokens[0].isEmpty && tokens[2].isEmpty;

/**
 * Parses {{ mustache }} bindings.
 *
 * Returns null if there are no matches. Otherwise returns
 * [TEXT, (PATH, TEXT)+] if there is at least one mustache.
 */
List<String> _parseMustacheTokens(String s) {
  if (s.isEmpty) return null;

  var tokens = null;
  var length = s.length;
  var startIndex = 0, lastIndex = 0, endIndex = 0;
  while (lastIndex < length) {
    startIndex = s.indexOf('{{', lastIndex);
    endIndex = startIndex < 0 ? -1 : s.indexOf('}}', startIndex + 2);

    if (endIndex < 0) {
      if (tokens == null) return null;

      tokens.add(s.substring(lastIndex));
      break;
    }

    if (tokens == null) tokens = <String>[];
    tokens.add(s.substring(lastIndex, startIndex)); // TEXT
    tokens.add(s.substring(startIndex + 2, endIndex).trim()); // PATH
    lastIndex = endIndex + 2;
  }

  if (lastIndex == length) tokens.add('');
  return tokens;
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
  final Element _templateElement;
  final List<Node> terminators = [];
  CompoundBinding inputs;
  List iteratedValue;
  bool closed = false;

  StreamSubscription _sub;

  _TemplateIterator(this._templateElement) {
    inputs = new CompoundBinding(resolveInputs);
  }

  resolveInputs(Map values) {
    if (closed) return;

    if (values.containsKey('if') && !_toBoolean(values['if'])) {
      valueChanged(null);
    } else if (values.containsKey('repeat')) {
      valueChanged(values['repeat']);
    } else if (values.containsKey('bind') || values.containsKey('if')) {
      valueChanged([values['bind']]);
    } else {
      valueChanged(null);
    }
    // We don't return a value to the CompoundBinding; instead we skip a hop and
    // call valueChanged directly.
    return null;
  }

  void valueChanged(value) {
    if (value is! List) value = null;

    var oldValue = iteratedValue;
    unobserve();
    iteratedValue = value;

    if (iteratedValue is Observable) {
      _sub = (iteratedValue as Observable).changes.listen(_handleChanges);
    }

    var splices = calculateSplices(
        iteratedValue != null ? iteratedValue : [],
        oldValue != null ? oldValue : []);

    if (splices.length > 0) _handleChanges(splices);

    if (inputs.length == 0) {
      close();
      templateBindFallback(_templateElement)._templateIterator = null;
    }
  }

  Node getTerminatorAt(int index) {
    if (index == -1) return _templateElement;
    var terminator = terminators[index];
    if (isSemanticTemplate(terminator) &&
        !identical(terminator, _templateElement)) {
      var subIterator = templateBindFallback(terminator)._templateIterator;
      if (subIterator != null) {
        return subIterator.getTerminatorAt(subIterator.terminators.length - 1);
      }
    }

    return terminator;
  }

  void insertInstanceAt(int index, DocumentFragment fragment,
        List<Node> instanceNodes) {

    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = null;
    if (fragment != null) {
      terminator = fragment.lastChild;
    } else if (instanceNodes.length > 0) {
      terminator = instanceNodes.last;
    }
    if (terminator == null) terminator = previousTerminator;

    terminators.insert(index, terminator);

    var parent = _templateElement.parentNode;
    var insertBeforeNode = previousTerminator.nextNode;

    if (fragment != null) {
      parent.insertBefore(fragment, insertBeforeNode);
      return;
    }

    for (var node in instanceNodes) {
      parent.insertBefore(node, insertBeforeNode);
    }
  }

  List<Node> extractInstanceAt(int index) {
    var instanceNodes = <Node>[];
    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = getTerminatorAt(index);
    terminators.removeAt(index);

    var parent = _templateElement.parentNode;
    while (terminator != previousTerminator) {
      var node = previousTerminator.nextNode;
      if (node == terminator) terminator = previousTerminator;
      node.remove();
      instanceNodes.add(node);
    }
    return instanceNodes;
  }

  getInstanceModel(model, BindingDelegate delegate) {
    if (delegate != null) {
      return delegate.getInstanceModel(_templateElement, model);
    }
    return model;
  }

  DocumentFragment getInstanceFragment(model, BindingDelegate delegate) {
    return templateBind(_templateElement).createInstance(model, delegate);
  }

  void _handleChanges(Iterable<ChangeRecord> splices) {
    if (closed) return;

    splices = splices.where((s) => s is ListChangeRecord);

    var template = _templateElement;
    var delegate = templateBind(template).bindingDelegate;

    if (template.parentNode == null || template.ownerDocument.window == null) {
      close();
      // TODO(jmesserly): MDV calls templateIteratorTable.delete(this) here,
      // but I think that's a no-op because only nodes are used as keys.
      // See https://github.com/Polymer/mdv/pull/114.
      return;
    }

    var instanceCache = new HashMap(equals: identical);
    var removeDelta = 0;
    for (var splice in splices) {
      for (int i = 0; i < splice.removedCount; i++) {
        var instanceNodes = extractInstanceAt(splice.index + removeDelta);
        if (instanceNodes.length == 0) continue;
        var model = nodeBindFallback(instanceNodes.first)
            ._templateInstance.model;
        instanceCache[model] = instanceNodes;
      }

      removeDelta -= splice.addedCount;
    }

    for (var splice in splices) {
      for (var addIndex = splice.index;
          addIndex < splice.index + splice.addedCount;
          addIndex++) {

        var model = iteratedValue[addIndex];
        var fragment = null;
        var instanceNodes = instanceCache.remove(model);
        if (instanceNodes == null) {
          var actualModel = getInstanceModel(model, delegate);
          fragment = getInstanceFragment(actualModel, delegate);
        }

        insertInstanceAt(addIndex, fragment, instanceNodes);
      }
    }

    for (var instanceNodes in instanceCache.values) {
      instanceNodes.forEach(_unbindAllRecursively);
    }
  }

  void unobserve() {
    if (_sub == null) return;
    _sub.cancel();
    _sub = null;
  }

  void close() {
    if (closed) return;

    unobserve();
    inputs.close();
    terminators.clear();
    closed = true;
  }

  static void _unbindAllRecursively(Node node) {
    var nodeExt = nodeBindFallback(node);
    nodeExt._templateInstance = null;
    if (isSemanticTemplate(node)) {
      // Make sure we stop observing when we remove an element.
      var templateIterator = nodeExt._templateIterator;
      if (templateIterator != null) {
        templateIterator.close();
        nodeExt._templateIterator = null;
      }
    }

    nodeBind(node).unbindAll();
    for (var c = node.firstChild; c != null; c = c.nextNode) {
      _unbindAllRecursively(c);
    }
  }
}
