// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

// This code is a port of Model-Driven-Views:
// https://github.com/polymer-project/mdv
// The code mostly comes from src/template_element.js

typedef void _ChangeHandler(value);

/**
 * Model-Driven Views (MDV)'s native features enables a wide-range of use cases,
 * but (by design) don't attempt to implement a wide array of specialized
 * behaviors.
 *
 * Enabling these features in MDV is a matter of implementing and registering an
 * MDV Custom Syntax. A Custom Syntax is an object which contains one or more
 * delegation functions which implement specialized behavior. This object is
 * registered with MDV via [TemplateElement.syntax]:
 *
 *
 * HTML:
 *     <template bind syntax="MySyntax">
 *       {{ What!Ever('crazy')->thing^^^I+Want(data) }}
 *     </template>
 *
 * Dart:
 *     class MySyntax extends CustomBindingSyntax {
 *       getBinding(model, path, name, node) {
 *         // The magic happens here!
 *       }
 *     }
 *
 *     ...
 *
 *     TemplateElement.syntax['MySyntax'] = new MySyntax();
 *
 * See <https://github.com/polymer-project/mdv/blob/master/docs/syntax.md> for more
 * information about Custom Syntax.
 */
// TODO(jmesserly): if this is just one method, a function type would make it
// more Dart-friendly.
@Experimental
abstract class CustomBindingSyntax {
  /**
   * This syntax method allows for a custom interpretation of the contents of
   * mustaches (`{{` ... `}}`).
   *
   * When a template is inserting an instance, it will invoke this method for
   * each mustache which is encountered. The function is invoked with four
   * arguments:
   *
   * - [model]: The data context for which this instance is being created.
   * - [path]: The text contents (trimmed of outer whitespace) of the mustache.
   * - [name]: The context in which the mustache occurs. Within element
   *   attributes, this will be the name of the attribute. Within text,
   *   this will be 'text'.
   * - [node]: A reference to the node to which this binding will be created.
   *
   * If the method wishes to handle binding, it is required to return an object
   * which has at least a `value` property that can be observed. If it does,
   * then MDV will call [Node.bind on the node:
   *
   *     node.bind(name, retval, 'value');
   *
   * If the 'getBinding' does not wish to override the binding, it should return
   * null.
   */
  // TODO(jmesserly): I had to remove type annotations from "name" and "node"
  // Normally they are String and Node respectively. But sometimes it will pass
  // (int name, CompoundBinding node). That seems very confusing; we may want
  // to change this API.
  getBinding(model, String path, name, node) => null;

  /**
   * This syntax method allows a syntax to provide an alterate model than the
   * one the template would otherwise use when producing an instance.
   *
   * When a template is about to create an instance, it will invoke this method
   * The function is invoked with two arguments:
   *
   * - [template]: The template element which is about to create and insert an
   *   instance.
   * - [model]: The data context for which this instance is being created.
   *
   * The template element will always use the return value of `getInstanceModel`
   * as the model for the new instance. If the syntax does not wish to override
   * the value, it should simply return the `model` value it was passed.
   */
  getInstanceModel(Element template, model) => model;

  /**
   * This syntax method allows a syntax to provide an alterate expansion of
   * the [template] contents. When the template wants to create an instance,
   * it will call this method with the template element.
   *
   * By default this will call `template.createInstance()`.
   */
  getInstanceFragment(Element template) => template.createInstance();
}

/** The callback used in the [CompoundBinding.combinator] field. */
@Experimental
typedef Object CompoundBindingCombinator(Map objects);

/** Information about the instantiated template. */
@Experimental
class TemplateInstance {
  // TODO(rafaelw): firstNode & lastNode should be read-synchronous
  // in cases where script has modified the template instance boundary.

  /** The first node of this template instantiation. */
  final Node firstNode;

  /**
   * The last node of this template instantiation.
   * This could be identical to [firstNode] if the template only expanded to a
   * single node.
   */
  final Node lastNode;

  /** The model used to instantiate the template. */
  final model;

  TemplateInstance(this.firstNode, this.lastNode, this.model);
}

/**
 * Model-Driven Views contains a helper object which is useful for the
 * implementation of a Custom Syntax.
 *
 *     var binding = new CompoundBinding((values) {
 *       var combinedValue;
 *       // compute combinedValue based on the current values which are provided
 *       return combinedValue;
 *     });
 *     binding.bind('name1', obj1, path1);
 *     binding.bind('name2', obj2, path2);
 *     //...
 *     binding.bind('nameN', objN, pathN);
 *
 * CompoundBinding is an object which knows how to listen to multiple path
 * values (registered via [bind]) and invoke its [combinator] when one or more
 * of the values have changed and set its [value] property to the return value
 * of the function. When any value has changed, all current values are provided
 * to the [combinator] in the single `values` argument.
 *
 * See [CustomBindingSyntax] for more information.
 */
// TODO(jmesserly): what is the public API surface here? I just guessed;
// most of it seemed non-public.
@Experimental
class CompoundBinding extends ObservableBase {
  CompoundBindingCombinator _combinator;

  // TODO(jmesserly): ideally these would be String keys, but sometimes we
  // use integers.
  Map<dynamic, StreamSubscription> _bindings = new Map();
  Map _values = new Map();
  bool _scheduled = false;
  bool _disposed = false;
  Object _value;

  CompoundBinding([CompoundBindingCombinator combinator]) {
    // TODO(jmesserly): this is a tweak to the original code, it seemed to me
    // that passing the combinator to the constructor should be equivalent to
    // setting it via the property.
    // I also added a null check to the combinator setter.
    this.combinator = combinator;
  }

  CompoundBindingCombinator get combinator => _combinator;

  set combinator(CompoundBindingCombinator combinator) {
    _combinator = combinator;
    if (combinator != null) _scheduleResolve();
  }

  static const _VALUE = const Symbol('value');

  get value => _value;

  void set value(newValue) {
    _value = notifyPropertyChange(_VALUE, _value, newValue);
  }

  // TODO(jmesserly): remove these workarounds when dart2js supports mirrors!
  getValueWorkaround(key) {
    if (key == _VALUE) return value;
    return null;
  }
  setValueWorkaround(key, val) {
    if (key == _VALUE) value = val;
  }

  void bind(name, model, String path) {
    unbind(name);

    _bindings[name] = new PathObserver(model, path).bindSync((value) {
      _values[name] = value;
      _scheduleResolve();
    });
  }

  void unbind(name, {bool suppressResolve: false}) {
    var binding = _bindings.remove(name);
    if (binding == null) return;

    binding.cancel();
    _values.remove(name);
    if (!suppressResolve) _scheduleResolve();
  }

  // TODO(rafaelw): Is this the right processing model?
  // TODO(rafaelw): Consider having a seperate ChangeSummary for
  // CompoundBindings so to excess dirtyChecks.
  void _scheduleResolve() {
    if (_scheduled) return;
    _scheduled = true;
    queueChangeRecords(resolve);
  }

  void resolve() {
    if (_disposed) return;
    _scheduled = false;

    if (_combinator == null) {
      throw new StateError(
          'CompoundBinding attempted to resolve without a combinator');
    }

    value = _combinator(_values);
  }

  void dispose() {
    for (var binding in _bindings.values) {
      binding.cancel();
    }
    _bindings.clear();
    _values.clear();

    _disposed = true;
    value = null;
  }
}

abstract class _InputBinding {
  final InputElement element;
  PathObserver binding;
  StreamSubscription _pathSub;
  StreamSubscription _eventSub;

  _InputBinding(this.element, model, String path) {
    binding = new PathObserver(model, path);
    _pathSub = binding.bindSync(valueChanged);
    _eventSub = _getStreamForInputType(element).listen(updateBinding);
  }

  void valueChanged(newValue);

  void updateBinding(e);

  void unbind() {
    binding = null;
    _pathSub.cancel();
    _eventSub.cancel();
  }


  static Stream<Event> _getStreamForInputType(InputElement element) {
    switch (element.type) {
      case 'checkbox':
        return element.onClick;
      case 'radio':
      case 'select-multiple':
      case 'select-one':
        return element.onChange;
      default:
        return element.onInput;
    }
  }
}

class _ValueBinding extends _InputBinding {
  _ValueBinding(element, model, path) : super(element, model, path);

  void valueChanged(value) {
    element.value = value == null ? '' : '$value';
  }

  void updateBinding(e) {
    binding.value = element.value;
  }
}

class _CheckedBinding extends _InputBinding {
  _CheckedBinding(element, model, path) : super(element, model, path);

  void valueChanged(value) {
    element.checked = _Bindings._toBoolean(value);
  }

  void updateBinding(e) {
    binding.value = element.checked;

    // Only the radio button that is getting checked gets an event. We
    // therefore find all the associated radio buttons and update their
    // CheckedBinding manually.
    if (element is InputElement && element.type == 'radio') {
      for (var r in _getAssociatedRadioButtons(element)) {
        var checkedBinding = r._checkedBinding;
        if (checkedBinding != null) {
          // Set the value directly to avoid an infinite call stack.
          checkedBinding.binding.value = false;
        }
      }
    }
  }

  // |element| is assumed to be an HTMLInputElement with |type| == 'radio'.
  // Returns an array containing all radio buttons other than |element| that
  // have the same |name|, either in the form that |element| belongs to or,
  // if no form, in the document tree to which |element| belongs.
  //
  // This implementation is based upon the HTML spec definition of a
  // "radio button group":
  //   http://www.whatwg.org/specs/web-apps/current-work/multipage/number-state.html#radio-button-group
  //
  static Iterable _getAssociatedRadioButtons(element) {
    if (!_isNodeInDocument(element)) return [];
    if (element.form != null) {
      return element.form.nodes.where((el) {
        return el != element &&
            el is InputElement &&
            el.type == 'radio' &&
            el.name == element.name;
      });
    } else {
      var radios = element.document.queryAll(
          'input[type="radio"][name="${element.name}"]');
      return radios.where((el) => el != element && el.form == null);
    }
  }

  // TODO(jmesserly): polyfill document.contains API instead of doing it here
  static bool _isNodeInDocument(Node node) {
    // On non-IE this works:
    // return node.document.contains(node);
    var document = node.document;
    if (node == document || node.parentNode == document) return true;
    return document.documentElement.contains(node);
  }
}

class _Bindings {
  // TODO(jmesserly): not sure what kind of boolean conversion rules to
  // apply for template data-binding. HTML attributes are true if they're
  // present. However Dart only treats "true" as true. Since this is HTML we'll
  // use something closer to the HTML rules: null (missing) and false are false,
  // everything else is true. See: https://github.com/polymer-project/mdv/issues/59
  static bool _toBoolean(value) => null != value && false != value;

  static Node _createDeepCloneAndDecorateTemplates(Node node, String syntax) {
    var clone = node.clone(false); // Shallow clone.
    if (clone is Element && clone.isTemplate) {
      TemplateElement.decorate(clone, node);
      if (syntax != null) {
        clone.attributes.putIfAbsent('syntax', () => syntax);
      }
    }

    for (var c = node.$dom_firstChild; c != null; c = c.nextNode) {
      clone.append(_createDeepCloneAndDecorateTemplates(c, syntax));
    }
    return clone;
  }

  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#dfn-template-contents-owner
  static Document _getTemplateContentsOwner(HtmlDocument doc) {
    if (doc.window == null) {
      return doc;
    }
    var d = doc._templateContentsOwner;
    if (d == null) {
      // TODO(arv): This should either be a Document or HTMLDocument depending
      // on doc.
      d = doc.implementation.createHtmlDocument('');
      while (d.$dom_lastChild != null) {
        d.$dom_lastChild.remove();
      }
      doc._templateContentsOwner = d;
    }
    return d;
  }

  static Element _cloneAndSeperateAttributeTemplate(Element templateElement) {
    var clone = templateElement.clone(false);
    var attributes = templateElement.attributes;
    for (var name in attributes.keys.toList()) {
      switch (name) {
        case 'template':
        case 'repeat':
        case 'bind':
        case 'ref':
          clone.attributes.remove(name);
          break;
        default:
          attributes.remove(name);
          break;
      }
    }

    return clone;
  }

  static void _liftNonNativeChildrenIntoContent(Element templateElement) {
    var content = templateElement.content;

    if (!templateElement._isAttributeTemplate) {
      var child;
      while ((child = templateElement.$dom_firstChild) != null) {
        content.append(child);
      }
      return;
    }

    // For attribute templates we copy the whole thing into the content and
    // we move the non template attributes into the content.
    //
    //   <tr foo template>
    //
    // becomes
    //
    //   <tr template>
    //   + #document-fragment
    //     + <tr foo>
    //
    var newRoot = _cloneAndSeperateAttributeTemplate(templateElement);
    var child;
    while ((child = templateElement.$dom_firstChild) != null) {
      newRoot.append(child);
    }
    content.append(newRoot);
  }

  static void _bootstrapTemplatesRecursivelyFrom(Node node) {
    void bootstrap(template) {
      if (!TemplateElement.decorate(template)) {
        _bootstrapTemplatesRecursivelyFrom(template.content);
      }
    }

    // Need to do this first as the contents may get lifted if |node| is
    // template.
    // TODO(jmesserly): node is DocumentFragment or Element
    var descendents = (node as dynamic).queryAll(_allTemplatesSelectors);
    if (node is Element && (node as Element).isTemplate) bootstrap(node);

    descendents.forEach(bootstrap);
  }

  static final String _allTemplatesSelectors = 'template, option[template], ' +
      Element._TABLE_TAGS.keys.map((k) => "$k[template]").join(", ");

  static void _addBindings(Node node, model, [CustomBindingSyntax syntax]) {
    if (node is Element) {
      _addAttributeBindings(node, model, syntax);
    } else if (node is Text) {
      _parseAndBind(node, 'text', node.text, model, syntax);
    }

    for (var c = node.$dom_firstChild; c != null; c = c.nextNode) {
      _addBindings(c, model, syntax);
    }
  }

  static void _addAttributeBindings(Element element, model, syntax) {
    element.attributes.forEach((name, value) {
      if (value == '' && (name == 'bind' || name == 'repeat')) {
        value = '{{}}';
      }
      _parseAndBind(element, name, value, model, syntax);
    });
  }

  static void _parseAndBind(Node node, String name, String text, model,
      CustomBindingSyntax syntax) {

    var tokens = _parseMustacheTokens(text);
    if (tokens.length == 0 || (tokens.length == 1 && tokens[0].isText)) {
      return;
    }

    // If this is a custom element, give the .xtag a change to bind.
    node = _nodeOrCustom(node);

    if (tokens.length == 1 && tokens[0].isBinding) {
      _bindOrDelegate(node, name, model, tokens[0].value, syntax);
      return;
    }

    var replacementBinding = new CompoundBinding();
    for (var i = 0; i < tokens.length; i++) {
      var token = tokens[i];
      if (token.isBinding) {
        _bindOrDelegate(replacementBinding, i, model, token.value, syntax);
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

  static void _bindOrDelegate(node, name, model, String path,
      CustomBindingSyntax syntax) {

    if (syntax != null) {
      var delegateBinding = syntax.getBinding(model, path, name, node);
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
  static _nodeOrCustom(node) => node is Element ? node.xtag : node;

  static List<_BindingToken> _parseMustacheTokens(String s) {
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

  static void _addTemplateInstanceRecord(fragment, model) {
    if (fragment.$dom_firstChild == null) {
      return;
    }

    var instanceRecord = new TemplateInstance(
        fragment.$dom_firstChild, fragment.$dom_lastChild, model);

    var node = instanceRecord.firstNode;
    while (node != null) {
      node._templateInstance = instanceRecord;
      node = node.nextNode;
    }
  }

  static void _removeAllBindingsRecursively(Node node) {
    _nodeOrCustom(node).unbindAll();
    for (var c = node.$dom_firstChild; c != null; c = c.nextNode) {
      _removeAllBindingsRecursively(c);
    }
  }

  static void _removeChild(Node parent, Node child) {
    child._templateInstance = null;
    if (child is Element && (child as Element).isTemplate) {
      Element childElement = child;
      // Make sure we stop observing when we remove an element.
      var templateIterator = childElement._templateIterator;
      if (templateIterator != null) {
        templateIterator.abandon();
        childElement._templateIterator = null;
      }
    }
    child.remove();
    _removeAllBindingsRecursively(child);
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

  StreamSubscription _sub;
  StreamSubscription _valueBinding;

  _TemplateIterator(this._templateElement)
    : inputs = new CompoundBinding(resolveInputs) {

    _valueBinding = new PathObserver(inputs, 'value').bindSync(valueChanged);
  }

  static Object resolveInputs(Map values) {
    if (values.containsKey('if') && !_Bindings._toBoolean(values['if'])) {
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
    clear();
    if (value is! List) return;

    iteratedValue = value;

    if (value is Observable) {
      _sub = value.changes.listen(_handleChanges);
    }

    int len = iteratedValue.length;
    if (len > 0) {
      _handleChanges([new ListChangeRecord(0, addedCount: len)]);
    }
  }

  Node getTerminatorAt(int index) {
    if (index == -1) return _templateElement;
    var terminator = terminators[index];
    if (terminator is! Element) return terminator;

    var subIterator = terminator._templateIterator;
    if (subIterator == null) return terminator;

    return subIterator.getTerminatorAt(subIterator.terminators.length - 1);
  }

  void insertInstanceAt(int index, Node fragment) {
    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = fragment.$dom_lastChild;
    if (terminator == null) terminator = previousTerminator;

    terminators.insert(index, terminator);
    var parent = _templateElement.parentNode;
    parent.insertBefore(fragment, previousTerminator.nextNode);
  }

  void removeInstanceAt(int index) {
    var previousTerminator = getTerminatorAt(index - 1);
    var terminator = getTerminatorAt(index);
    terminators.removeAt(index);

    var parent = _templateElement.parentNode;
    while (terminator != previousTerminator) {
      var node = terminator;
      terminator = node.previousNode;
      _Bindings._removeChild(parent, node);
    }
  }

  void removeAllInstances() {
    if (terminators.length == 0) return;

    var previousTerminator = _templateElement;
    var terminator = getTerminatorAt(terminators.length - 1);
    terminators.length = 0;

    var parent = _templateElement.parentNode;
    while (terminator != previousTerminator) {
      var node = terminator;
      terminator = node.previousNode;
      _Bindings._removeChild(parent, node);
    }
  }

  void clear() {
    unobserve();
    removeAllInstances();
    iteratedValue = null;
  }

  getInstanceModel(model, syntax) {
    if (syntax != null) {
      return syntax.getInstanceModel(_templateElement, model);
    }
    return model;
  }

  getInstanceFragment(syntax) {
    if (syntax != null) {
      return syntax.getInstanceFragment(_templateElement);
    }
    return _templateElement.createInstance();
  }

  void _handleChanges(List<ListChangeRecord> splices) {
    var syntax = TemplateElement.syntax[_templateElement.attributes['syntax']];

    for (var splice in splices) {
      if (splice is! ListChangeRecord) continue;

      for (int i = 0; i < splice.removedCount; i++) {
        removeInstanceAt(splice.index);
      }

      for (var addIndex = splice.index;
          addIndex < splice.index + splice.addedCount;
          addIndex++) {

        var model = getInstanceModel(iteratedValue[addIndex], syntax);

        var fragment = getInstanceFragment(syntax);

        _Bindings._addBindings(fragment, model, syntax);
        _Bindings._addTemplateInstanceRecord(fragment, model);

        insertInstanceAt(addIndex, fragment);
      }
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
    inputs.dispose();
  }
}
