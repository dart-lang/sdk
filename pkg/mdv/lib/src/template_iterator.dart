// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

// This code is a port of Model-Driven-Views:
// https://github.com/polymer-project/mdv
// The code mostly comes from src/template_element.js

// TODO(jmesserly): not sure what kind of boolean conversion rules to
// apply for template data-binding. HTML attributes are true if they're
// present. However Dart only treats "true" as true. Since this is HTML we'll
// use something closer to the HTML rules: null (missing) and false are false,
// everything else is true. See: https://github.com/polymer-project/mdv/issues/59
bool _toBoolean(value) => null != value && false != value;

Node _createDeepCloneAndDecorateTemplates(Node node, String syntax) {
  var clone = node.clone(false); // Shallow clone.
  if (clone is Element && clone.isTemplate) {
    TemplateElement.decorate(clone, node);
    if (syntax != null) {
      clone.attributes.putIfAbsent('syntax', () => syntax);
    }
  }

  for (var c = node.firstChild; c != null; c = c.nextNode) {
    clone.append(_createDeepCloneAndDecorateTemplates(c, syntax));
  }
  return clone;
}

void _addBindings(Node node, model, [CustomBindingSyntax delegate]) {
  if (node is Element) {
    _addAttributeBindings(node, model, delegate);
  } else if (node is Text) {
    _parseAndBind(node, 'text', node.text, model, delegate);
  }

  for (var c = node.firstChild; c != null; c = c.nextNode) {
    _addBindings(c, model, delegate);
  }
}

void _addAttributeBindings(Element element, model, delegate) {
  element.attributes.forEach((name, value) {
    if (value == '' && (name == 'bind' || name == 'repeat')) {
      value = '{{}}';
    }
    _parseAndBind(element, name, value, model, delegate);
  });
}

void _parseAndBind(Node node, String name, String text, model,
    CustomBindingSyntax delegate) {

  var tokens = _parseMustacheTokens(text);
  if (tokens.length == 0 || (tokens.length == 1 && tokens[0].isText)) {
    return;
  }

  // If this is a custom element, give the .xtag a change to bind.
  node = _nodeOrCustom(node);

  if (tokens.length == 1 && tokens[0].isBinding) {
    _bindOrDelegate(node, name, model, tokens[0].value, delegate);
    return;
  }

  var replacementBinding = new CompoundBinding();
  for (var i = 0; i < tokens.length; i++) {
    var token = tokens[i];
    if (token.isBinding) {
      _bindOrDelegate(replacementBinding, i, model, token.value, delegate);
    }
  }

  replacementBinding.combinator = (values) {
    var newValue = new StringBuffer();

    for (var i = 0; i < tokens.length; i++) {
      var token = tokens[i];
      if (token.isText) {
        newValue.write(token.value);
      } else {
        var value = values[i];
        if (value != null) {
          newValue.write(value);
        }
      }
    }

    return newValue.toString();
  };

  node.bind(name, replacementBinding, 'value');
}

void _bindOrDelegate(node, name, model, String path,
    CustomBindingSyntax delegate) {

  if (delegate != null) {
    var delegateBinding = delegate.getBinding(model, path, name, node);
    if (delegateBinding != null) {
      model = delegateBinding;
      path = 'value';
    }
  }

  node.bind(name, model, path);
}

/**
 * Gets the [node]'s custom [Element.xtag] if present, otherwise returns
 * the node. This is used so nodes can override [Node.bind], [Node.unbind],
 * and [Node.unbindAll] like InputElement does.
 */
// TODO(jmesserly): remove this when we can extend Element for real.
_nodeOrCustom(node) => node is Element ? node.xtag : node;

List<_BindingToken> _parseMustacheTokens(String s) {
  var result = [];
  var length = s.length;
  var index = 0, lastIndex = 0;
  while (lastIndex < length) {
    index = s.indexOf('{{', lastIndex);
    if (index < 0) {
      result.add(new _BindingToken(s.substring(lastIndex)));
      break;
    } else {
      // There is a non-empty text run before the next path token.
      if (index > 0 && lastIndex < index) {
        result.add(new _BindingToken(s.substring(lastIndex, index)));
      }
      lastIndex = index + 2;
      index = s.indexOf('}}', lastIndex);
      if (index < 0) {
        var text = s.substring(lastIndex - 2);
        if (result.length > 0 && result.last.isText) {
          result.last.value += text;
        } else {
          result.add(new _BindingToken(text));
        }
        break;
      }

      var value = s.substring(lastIndex, index).trim();
      result.add(new _BindingToken(value, isBinding: true));
      lastIndex = index + 2;
    }
  }
  return result;
}

void _addTemplateInstanceRecord(fragment, model) {
  if (fragment.firstChild == null) {
    return;
  }

  var instanceRecord = new TemplateInstance(
      fragment.firstChild, fragment.lastChild, model);

  var node = instanceRecord.firstNode;
  while (node != null) {
    _mdv(node)._templateInstance = instanceRecord;
    node = node.nextNode;
  }
}

class _BindingToken {
  final String value;
  final bool isBinding;

  _BindingToken(this.value, {this.isBinding: false});

  bool get isText => !isBinding;
}

class _TemplateIterator {
  final Element _templateElement;
  final List<Node> terminators = [];
  final CompoundBinding inputs;
  List iteratedValue;
  Object _lastValue;

  StreamSubscription _sub;
  StreamSubscription _valueBinding;

  _TemplateIterator(this._templateElement)
      : inputs = new CompoundBinding(resolveInputs) {

    _valueBinding = new PathObserver(inputs, 'value').bindSync(valueChanged);
  }

  static Object resolveInputs(Map values) {
    if (values.containsKey('if') && !_toBoolean(values['if'])) {
      return null;
    }

    if (values.containsKey('repeat')) {
      return values['repeat'];
    }

    if (values.containsKey('bind')) {
      return [values['bind']];
    }

    return null;
  }

  void valueChanged(value) {
    // TODO(jmesserly): should PathObserver do this for us?
    var oldValue = _lastValue;
    _lastValue = value;

    if (value is! List) {
      value = [];
    }

    unobserve();
    iteratedValue = value;

    if (value is Observable) {
      _sub = value.changes.listen(_handleChanges);
    }

    int addedCount = iteratedValue.length;
    var removedCount = oldValue is List ? (oldValue as List).length : 0;
    if (addedCount == 0 && removedCount == 0) return; // nothing to do.

    _handleChanges([new ListChangeRecord(0, addedCount: addedCount,
        removedCount: removedCount)]);
  }

  Node getTerminatorAt(int index) {
    if (index == -1) return _templateElement;
    var terminator = terminators[index];
    if (terminator is Element && (terminator as Element).isTemplate) {
      var subIterator = _mdv(terminator)._templateIterator;
      if (subIterator != null) {
        return subIterator.getTerminatorAt(subIterator.terminators.length - 1);
      }
    }

    return terminator;
  }

  void insertInstanceAt(int index, List<Node> instanceNodes) {
    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = instanceNodes.length > 0 ? instanceNodes.last
        : previousTerminator;

    terminators.insert(index, terminator);

    var parent = _templateElement.parentNode;
    var insertBeforeNode = previousTerminator.nextNode;
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
      var node = terminator;
      terminator = node.previousNode;
      node.remove();
      instanceNodes.add(node);
    }
    return instanceNodes;
  }

  getInstanceModel(model, String syntax) {
    var delegate = TemplateElement.syntax[syntax];
    if (delegate != null) {
      return delegate.getInstanceModel(_templateElement, model);
    }
    return model;
  }

  List<Node> getInstanceNodes(model, String syntax, IdentityMap instanceCache) {
    var instanceNodes = instanceCache.remove(model);
    if (instanceNodes != null) return instanceNodes;

    var fragment = _templateElement.createInstance(model, syntax);
    instanceNodes = fragment.nodes.toList();
    fragment.nodes.clear();
    return instanceNodes;
  }

  void _handleChanges(Iterable<ChangeRecord> splices) {
    splices = splices.where((s) => s is ListChangeRecord);

    var template = _templateElement;
    var syntax = template.attributes['syntax'];

    if (template.parentNode == null || template.document.window == null) {
      abandon();
      // TODO(jmesserly): MDV calls templateIteratorTable.delete(this) here,
      // but I think that's a no-op because only nodes are used as keys.
      // See https://github.com/Polymer/mdv/pull/114.
      return;
    }

    // TODO(jmesserly): IdentityMap matches JS semantics, but it's O(N) right
    // now. See http://dartbug.com/4161.
    var instanceCache = new IdentityMap();
    var removeDelta = 0;
    for (var splice in splices) {
      for (int i = 0; i < splice.removedCount; i++) {
        var instanceNodes = extractInstanceAt(splice.index + removeDelta);
        var model = _mdv(instanceNodes.first)._templateInstance.model;
        instanceCache[model] = instanceNodes;
      }

      removeDelta -= splice.addedCount;
    }

    for (var splice in splices) {
      for (var addIndex = splice.index;
          addIndex < splice.index + splice.addedCount;
          addIndex++) {

        var model = getInstanceModel(iteratedValue[addIndex], syntax);

        var instanceNodes = getInstanceNodes(model, syntax, instanceCache);
        insertInstanceAt(addIndex, instanceNodes);
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

  void abandon() {
    unobserve();
    _valueBinding.cancel();
    terminators.clear();
    inputs.dispose();
  }

  static void _unbindAllRecursively(Node node) {
    var nodeExt = _mdv(node);
    nodeExt._templateInstance = null;
    if (node is Element && (node as Element).isTemplate) {
      // Make sure we stop observing when we remove an element.
      var templateIterator = nodeExt._templateIterator;
      if (templateIterator != null) {
        templateIterator.abandon();
        nodeExt._templateIterator = null;
      }
    }

    _nodeOrCustom(node).unbindAll();
    for (var c = node.firstChild; c != null; c = c.nextNode) {
      _unbindAllRecursively(c);
    }
  }
}
