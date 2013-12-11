// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/**
 * Use this annotation to publish a field as an attribute. For example:
 *
 *     class MyPlaybackElement extends PolymerElement {
 *       // This will be available as an HTML attribute, for example:
 *       //     <my-playback volume="11">
 *       @published double volume;
 *     }
 */
// TODO(jmesserly): does @published imply @observable or vice versa?
const published = const PublishedProperty();

/** An annotation used to publish a field as an attribute. See [published]. */
class PublishedProperty extends ObservableProperty {
  const PublishedProperty();
}

/**
 * The mixin class for Polymer elements. It provides convenience features on top
 * of the custom elements web standard.
 *
 * If this class is used as a mixin,
 * you must call `polymerCreated()` from the body of your constructor.
 */
abstract class Polymer implements Element, Observable, NodeBindExtension {
  // Fully ported from revision:
  // https://github.com/Polymer/polymer/blob/b7200854b2441a22ce89f6563963f36c50f5150d
  //
  //   src/boot.js (static APIs on "Polymer" object)
  //   src/instance/attributes.js
  //   src/instance/base.js
  //   src/instance/events.js
  //   src/instance/mdv.js
  //   src/instance/properties.js
  //   src/instance/style.js
  //   src/instance/utils.js

  // TODO(jmesserly): should this really be public?
  /** Regular expression that matches data-bindings. */
  static final bindPattern = new RegExp(r'\{\{([^{}]*)}}');

  /**
   * Like [document.register] but for Polymer elements.
   *
   * Use the [name] to specify custom elment's tag name, for example:
   * "fancy-button" if the tag is used as `<fancy-button>`.
   *
   * The [type] is the type to construct. If not supplied, it defaults to
   * [PolymerElement].
   */
  // NOTE: this is called "element" in src/declaration/polymer-element.js, and
  // exported as "Polymer".
  static void register(String name, [Type type]) {
    //console.log('registering [' + name + ']');
    if (type == null) type = PolymerElement;

    _typesByName[name] = type;
    // notify the registrar waiting for 'name', if any
    _notifyType(name);
  }

  /// The one syntax to rule them all.
  static final BindingDelegate _polymerSyntax =
      new _PolymerExpressionsWithEventDelegate();

  static int _preparingElements = 0;

  static final Completer _ready = new Completer();

  /**
   * Future indicating that the Polymer library has been loaded and is ready
   * for use.
   */
  static Future get onReady => _ready.future;

  PolymerDeclaration _declaration;

  /** The most derived `<polymer-element>` declaration for this element. */
  PolymerDeclaration get declaration => _declaration;

  Map<String, StreamSubscription> _observers;
  bool _unbound; // lazy-initialized
  _Job _unbindAllJob;

  StreamSubscription _propertyObserver;

  bool get _elementPrepared => _declaration != null;

  bool get applyAuthorStyles => false;
  bool get resetStyleInheritance => false;
  bool get alwaysPrepare => false;
  bool get preventDispose => false;

  BindingDelegate syntax = _polymerSyntax;

  /**
   * Shadow roots created by [parseElement]. See [getShadowRoot].
   */
  final _shadowRoots = new HashMap<String, ShadowRoot>();

  /** Map of items in the shadow root(s) by their [Element.id]. */
  // TODO(jmesserly): various issues:
  // * wrap in UnmodifiableMapView?
  // * should we have an object that implements noSuchMethod?
  // * should the map have a key order (e.g. LinkedHash or SplayTree)?
  // * should this be a live list? Polymer doesn't, maybe due to JS limitations?
  // Note: this is observable to support $['someId'] being used in templates.
  // The template is stamped before $ is populated, so we need observation if
  // we want it to be usable in bindings.
  @reflectable final Map<String, Element> $ =
      new ObservableMap<String, Element>();

  /**
   * Gets the shadow root associated with the corresponding custom element.
   *
   * This is identical to [shadowRoot], unless there are multiple levels of
   * inheritance and they each have their own shadow root. For example,
   * this can happen if the base class and subclass both have `<template>` tags
   * in their `<polymer-element>` tags.
   */
  // TODO(jmesserly): Polymer does not have this feature. Reconcile.
  ShadowRoot getShadowRoot(String customTagName) => _shadowRoots[customTagName];

  /**
   * If this class is used as a mixin, this method must be called from inside
   * of the `created()` constructor.
   *
   * If this class is a superclass, calling `super.created()` is sufficient.
   */
  void polymerCreated() {
    if (this.ownerDocument.window != null || alwaysPrepare ||
        _preparingElements > 0) {
      prepareElement();
    }
  }

  /** Retrieves the custom element name by inspecting the host node. */
  String get _customTagName {
    var isAttr = attributes['is'];
    return (isAttr == null || isAttr == '') ? localName : isAttr;
  }

  void prepareElement() {
    // Dart note: get the _declaration, which also marks _elementPrepared
    _declaration = _getDeclaration(_customTagName);
    // do this first so we can observe changes during initialization
    observeProperties();
    // install boilerplate attributes
    copyInstanceAttributes();
    // process input attributes
    takeAttributes();
    // add event listeners
    addHostListeners();
    // guarantees that while preparing, any
    // sub-elements are also prepared
    _preparingElements++;
    // process declarative resources
    parseDeclarations(_declaration);
    // decrement semaphore
    _preparingElements--;
    // user entry point
    ready();
  }

  /** Called when [prepareElement] is finished. */
  void ready() {}

  void enteredView() {
    if (!_elementPrepared) {
      prepareElement();
    }
    cancelUnbindAll(preventCascade: true);
  }

  void leftView() {
    if (!preventDispose) asyncUnbindAll();
  }

  /** Recursive ancestral <element> initialization, oldest first. */
  void parseDeclarations(PolymerDeclaration declaration) {
    if (declaration != null) {
      parseDeclarations(declaration.superDeclaration);
      parseDeclaration(declaration);
    }
  }

  /**
   * Parse input `<polymer-element>` as needed, override for custom behavior.
   */
  void parseDeclaration(Element elementElement) {
    var template = fetchTemplate(elementElement);

    var root = null;
    if (template != null) {
      if (_declaration.attributes.containsKey('lightdom')) {
        lightFromTemplate(template);
      } else {
        root = shadowFromTemplate(template);
      }
    }

    // Dart note: the following code is to support the getShadowRoot method.
    if (root is! ShadowRoot) return;

    var name = elementElement.attributes['name'];
    if (name == null) return;
    _shadowRoots[name] = root;
  }

  /**
   * Return a shadow-root template (if desired), override for custom behavior.
   */
  Element fetchTemplate(Element elementElement) =>
      elementElement.query('template');

  /**
   * Utility function that stamps a `<template>` into light-dom.
   */
  Node lightFromTemplate(Element template) {
    if (template == null) return null;
    // stamp template
    // which includes parsing and applying MDV bindings before being
    // inserted (to avoid {{}} in attribute values)
    // e.g. to prevent <img src="images/{{icon}}"> from generating a 404.
    var dom = instanceTemplate(template);
    // append to shadow dom
    append(dom);
    // perform post-construction initialization tasks on shadow root
    shadowRootReady(this, template);
    // return the created shadow root
    return dom;
  }

  /**
   * Utility function that creates a shadow root from a `<template>`.
   *
   * The base implementation will return a [ShadowRoot], but you can replace it
   * with your own code and skip ShadowRoot creation. In that case, you should
   * return `null`.
   *
   * In your overridden method, you can use [instanceTemplate] to stamp the
   * template and initialize data binding, and [shadowRootReady] to intialize
   * other Polymer features like event handlers. It is fine to call
   * shadowRootReady with a node something other than a ShadowRoot; for example,
   * with this Node.
   */
  ShadowRoot shadowFromTemplate(Element template) {
    if (template == null) return null;
    // cache elder shadow root (if any)
    var elderRoot = this.shadowRoot;
    // make a shadow root
    var root = createShadowRoot();

    // Provides ability to traverse from ShadowRoot to the host.
    // TODO(jmessery): remove once we have this ability on the DOM.
    _shadowHost[root] = this;

    // migrate flag(s)(
    root.applyAuthorStyles = applyAuthorStyles;
    root.resetStyleInheritance = resetStyleInheritance;
    // stamp template
    // which includes parsing and applying MDV bindings before being
    // inserted (to avoid {{}} in attribute values)
    // e.g. to prevent <img src="images/{{icon}}"> from generating a 404.
    var dom = instanceTemplate(template);
    // append to shadow dom
    root.append(dom);
    // perform post-construction initialization tasks on shadow root
    shadowRootReady(root, template);
    // return the created shadow root
    return root;
  }

  void shadowRootReady(Node root, Element template) {
    // locate nodes with id and store references to them in this.$ hash
    marshalNodeReferences(root);
    // TODO(jmesserly): port this
    // set up pointer gestures
    // PointerGestures.register(root);
  }

  /** Locate nodes with id and store references to them in [$] hash. */
  void marshalNodeReferences(Node root) {
    if (root == null) return;
    for (var n in (root as dynamic).queryAll('[id]')) {
      $[n.id] = n;
    }
  }

  void attributeChanged(String name, String oldValue, String newValue) {
    if (name != 'class' && name != 'style') {
      attributeToProperty(name, newValue);
    }
  }

  // TODO(jmesserly): this could be a top level method.
  /**
   * Returns a future when `node` changes, or when its children or subtree
   * changes.
   *
   * Use [MutationObserver] if you want to listen to a stream of changes.
   */
  Future<List<MutationRecord>> onMutation(Node node) {
    var completer = new Completer();
    new MutationObserver((mutations, observer) {
      observer.disconnect();
      completer.complete(mutations);
    })..observe(node, childList: true, subtree: true);
    return completer.future;
  }

  void copyInstanceAttributes() {
    _declaration._instanceAttributes.forEach((name, value) {
      attributes.putIfAbsent(name, () => value);
    });
  }

  void takeAttributes() {
    if (_declaration._publishLC == null) return;
    attributes.forEach(attributeToProperty);
  }

  /**
   * If attribute [name] is mapped to a property, deserialize
   * [value] into that property.
   */
  void attributeToProperty(String name, String value) {
    // try to match this attribute to a property (attributes are
    // all lower-case, so this is case-insensitive search)
    var property = propertyForAttribute(name);
    if (property == null) return;

    // filter out 'mustached' values, these are to be
    // replaced with bound-data and are not yet values
    // themselves.
    if (value == null || value.contains(Polymer.bindPattern)) return;

    // get original value
    final self = reflect(this);
    final currentValue = self.getField(property.simpleName).reflectee;

    // deserialize Boolean or Number values from attribute
    final newValue = deserializeValue(value, currentValue,
        _inferPropertyType(currentValue, property));

    // only act if the value has changed
    if (!identical(newValue, currentValue)) {
      // install new value (has side-effects)
      self.setField(property.simpleName, newValue);
    }
  }

  /** Return the published property matching name, or null. */
  // TODO(jmesserly): should we just return Symbol here?
  DeclarationMirror propertyForAttribute(String name) {
    final publishLC = _declaration._publishLC;
    if (publishLC == null) return null;
    //console.log('propertyForAttribute:', name, 'matches', match);
    return publishLC[name];
  }

  /**
   * Convert representation of [value] based on [type] and [currentValue].
   */
  // TODO(jmesserly): this should probably take a ClassMirror instead of
  // TypeMirror, but it is currently impossible to get from a TypeMirror to a
  // ClassMirror.
  Object deserializeValue(String value, Object currentValue, TypeMirror type) =>
      deserialize.deserializeValue(value, currentValue, type);

  String serializeValue(Object value) {
    if (value == null) return null;

    if (value is bool) {
      return _toBoolean(value) ? '' : null;
    } else if (value is String || value is int || value is double) {
      return '$value';
    }
    return null;
  }

  void reflectPropertyToAttribute(Symbol name) {
    // TODO(sjmiles): consider memoizing this
    final self = reflect(this);
    // try to intelligently serialize property value
    // TODO(jmesserly): cache symbol?
    final propValue = self.getField(name).reflectee;
    final serializedValue = serializeValue(propValue);
    // boolean properties must reflect as boolean attributes
    if (serializedValue != null) {
      attributes[MirrorSystem.getName(name)] = serializedValue;
      // TODO(sorvell): we should remove attr for all properties
      // that have undefined serialization; however, we will need to
      // refine the attr reflection system to achieve this; pica, for example,
      // relies on having inferredType object properties not removed as
      // attrs.
    } else if (propValue is bool) {
      attributes.remove(MirrorSystem.getName(name));
    }
  }

  /**
   * Creates the document fragment to use for each instance of the custom
   * element, given the `<template>` node. By default this is equivalent to:
   *
   *     templateBind(template).createInstance(this, polymerSyntax);
   *
   * Where polymerSyntax is a singleton `PolymerExpressions` instance from the
   * [polymer_expressions](https://pub.dartlang.org/packages/polymer_expressions)
   * package.
   *
   * You can override this method to change the instantiation behavior of the
   * template, for example to use a different data-binding syntax.
   */
  DocumentFragment instanceTemplate(Element template) =>
      templateBind(template).createInstance(this, syntax);

  NodeBinding bind(String name, model, [String path]) {
    // note: binding is a prepare signal. This allows us to be sure that any
    // property changes that occur as a result of binding will be observed.
    if (!_elementPrepared) prepareElement();

    var property = propertyForAttribute(name);
    if (property == null) {
      // Cannot call super.bind because template_binding is its own package
      return nodeBindFallback(this).bind(name, model, path);
    } else {
      // clean out the closets
      unbind(name);
      // use n-way Polymer binding
      var observer = bindProperty(property.simpleName, model, path);
      // reflect bound property to attribute when binding
      // to ensure binding is not left on attribute if property
      // does not update due to not changing.
      // Dart note: we include this patch:
      // https://github.com/Polymer/polymer/pull/319
      reflectPropertyToAttribute(property.simpleName);
      return bindings[name] = observer;
    }
  }

  Map<String, NodeBinding> get bindings => nodeBindFallback(this).bindings;
  TemplateInstance get templateInstance =>
      nodeBindFallback(this).templateInstance;

  void unbind(String name) => nodeBindFallback(this).unbind(name);

  void asyncUnbindAll() {
    if (_unbound == true) return;
    _unbindLog.fine('[$localName] asyncUnbindAll');
    _unbindAllJob = _runJob(_unbindAllJob, unbindAll, Duration.ZERO);
  }

  void unbindAll() {
    if (_unbound == true) return;

    unbindAllProperties();
    nodeBindFallback(this).unbindAll();

    var root = shadowRoot;
    while (root != null) {
      _unbindNodeTree(root);
      root = root.olderShadowRoot;
    }
    _unbound = true;
  }

  void cancelUnbindAll({bool preventCascade}) {
    if (_unbound == true) {
      _unbindLog.warning(
          '[$localName] already unbound, cannot cancel unbindAll');
      return;
    }
    _unbindLog.fine('[$localName] cancelUnbindAll');
    if (_unbindAllJob != null) {
      _unbindAllJob.stop();
      _unbindAllJob = null;
    }

    // cancel unbinding our shadow tree iff we're not in the process of
    // cascading our tree (as we do, for example, when the element is inserted).
    if (preventCascade == true) return;
    _forNodeTree(shadowRoot, (n) {
      if (n is Polymer) {
        (n as Polymer).cancelUnbindAll();
      }
    });
  }

  static void _unbindNodeTree(Node node) {
    _forNodeTree(node, (node) => nodeBind(node).unbindAll());
  }

  static void _forNodeTree(Node node, void callback(Node node)) {
    if (node == null) return;

    callback(node);
    for (var child = node.firstChild; child != null; child = child.nextNode) {
      _forNodeTree(child, callback);
    }
  }

  /** Set up property observers. */
  void observeProperties() {
    // TODO(jmesserly): we don't have CompoundPathObserver, so this
    // implementation is a little bit different. We also don't expose the
    // "generateCompoundPathObserver" method.
    final observe = _declaration._observe;
    final publish = _declaration._publish;

    if (observe != null) {
      for (var name in observe.keys) {
        observeArrayValue(name, reflect(this).getField(name), null);
      }
    }
    if (observe != null || publish != null) {
      // Instead of using CompoundPathObserver, set up a binding using normal
      // change records.
      _propertyObserver = changes.listen(notifyPropertyChanges);
    }
  }

  /** Responds to property changes on this element. */
  // Dart note: this takes a list of changes rather than trying to deal with
  // what CompoundPathObserver would give us. Simpler and probably faster too.
  void notifyPropertyChanges(Iterable<ChangeRecord> changes) {
    final observe = _declaration._observe;
    final publish = _declaration._publish;

    // Summarize old and new values, so we only handle each change once.
    final valuePairs = new Map<Symbol, _PropertyValue>();
    for (var c in changes) {
      if (c is! PropertyChangeRecord) continue;

      valuePairs.putIfAbsent(c.name, () => new _PropertyValue(c.oldValue))
          .newValue = c.newValue;
    }

    valuePairs.forEach((name, pair) {
      if (publish != null && publish.containsKey(name)) {
        reflectPropertyToAttribute(name);
      }
      if (observe == null) return;

      var method = observe[name];
      if (method != null) {
        // observes the value if it is an array
        observeArrayValue(name, pair.newValue, pair.oldValue);
        // TODO(jmesserly): the JS code tries to avoid calling the same method
        // twice, but I don't see how that is possible.
        // Dart note: JS also passes "arguments", so we pass all change records.
        invokeMethod(method, [pair.oldValue, pair.newValue, changes]);
      }
    });
  }

  void observeArrayValue(Symbol name, Object value, Object old) {
    final observe = _declaration._observe;
    if (observe == null) return;

    // we only care if there are registered side-effects
    var callbackName = observe[name];
    if (callbackName == null) return;

    // if we are observing the previous value, stop
    if (old is ObservableList) {
      if (_observeLog.isLoggable(Level.FINE)) {
        _observeLog.fine('[$localName] observeArrayValue: unregister observer '
            '$name');
      }

      unregisterObserver('${MirrorSystem.getName(name)}__array');
    }
    // if the new value is an array, being observing it
    if (value is ObservableList) {
      if (_observeLog.isLoggable(Level.FINE)) {
        _observeLog.fine('[$localName] observeArrayValue: register observer '
            '$name');
      }
      var sub = value.listChanges.listen((changes) {
        invokeMethod(callbackName, [old]);
      });
      registerObserver('${MirrorSystem.getName(name)}__array', sub);
    }
  }

  bool unbindProperty(String name) => unregisterObserver(name);

  void unbindAllProperties() {
    if (_propertyObserver != null) {
      _propertyObserver.cancel();
      _propertyObserver = null;
    }
    unregisterObservers();
  }

  /** Bookkeeping observers for memory management. */
  void registerObserver(String name, StreamSubscription sub) {
    if (_observers == null) {
      _observers = new Map<String, StreamSubscription>();
    }
    _observers[name] = sub;
  }

  bool unregisterObserver(String name) {
    var sub = _observers.remove(name);
    if (sub == null) return false;
    sub.cancel();
    return true;
  }

  void unregisterObservers() {
    if (_observers == null) return;
    for (var sub in _observers.values) sub.cancel();
    _observers.clear();
    _observers = null;
  }

  /**
   * Bind a [property] in this object to a [path] in model. *Note* in Dart it
   * is necessary to also define the field:
   *
   *     var myProperty;
   *
   *     ready() {
   *       super.ready();
   *       bindProperty(#myProperty, this, 'myModel.path.to.otherProp');
   *     }
   */
  // TODO(jmesserly): replace with something more localized, like:
  // @ComputedField('myModel.path.to.otherProp');
  NodeBinding bindProperty(Symbol name, Object model, [String path]) =>
      // apply Polymer two-way reference binding
      _bindProperties(this, name, model, path);

  /**
   * bind a property in A to a path in B by converting A[property] to a
   * getter/setter pair that accesses B[...path...]
   */
  static NodeBinding _bindProperties(Polymer inA, Symbol inProperty,
        Object inB, String inPath) {

    if (_bindLog.isLoggable(Level.FINE)) {
      _bindLog.fine('[$inB]: bindProperties: [$inPath] to '
          '[${inA.localName}].[$inProperty]');
    }

    // Dart note: normally we only reach this code when we know it's a
    // property, but if someone uses bindProperty directly they might get a
    // NoSuchMethodError either from the getField below, or from the setField
    // inside PolymerBinding. That doesn't seem unreasonable, but it's a slight
    // difference from Polymer.js behavior.

    // capture A's value if B's value is null or undefined,
    // otherwise use B's value
    var path = new PathObserver(inB, inPath);
    if (path.value == null) {
      path.value = reflect(inA).getField(inProperty).reflectee;
    }
    return new _PolymerBinding(inA, inProperty, inB, inPath);
  }

  /** Attach event listeners on the host (this) element. */
  void addHostListeners() {
    var events = _declaration._eventDelegates;
    if (events.isEmpty) return;

    if (_eventsLog.isLoggable(Level.FINE)) {
      _eventsLog.fine('[$localName] addHostListeners: $events');
    }
    addNodeListeners(this, events.keys, hostEventListener);
  }

  void addNodeListeners(Node node, Iterable<String> events,
      void listener(Event e)) {

    for (var name in events) {
      addNodeListener(node, name, listener);
    }
  }

  void addNodeListener(Node node, String event, void listener(Event e)) {
    node.on[event].listen(listener);
  }

  void hostEventListener(Event event) {
    // TODO(jmesserly): do we need this check? It was using cancelBubble, see:
    // https://github.com/Polymer/polymer/issues/292
    if (!event.bubbles) return;

    bool log = _eventsLog.isLoggable(Level.FINE);
    if (log) {
      _eventsLog.fine('>>> [$localName]: hostEventListener(${event.type})');
    }

    var h = findEventDelegate(event);
    if (h != null) {
      if (log) _eventsLog.fine('[$localName] found host handler name [$h]');
      var detail = event is CustomEvent ?
          (event as CustomEvent).detail : null;
      // TODO(jmesserly): cache the symbols?
      dispatchMethod(this, h, [event, detail, this]);
    }

    if (log) {
      _eventsLog.fine('<<< [$localName]: hostEventListener(${event.type})');
    }
  }

  String findEventDelegate(Event event) =>
      _declaration._eventDelegates[_eventNameFromType(event.type)];

  /**
   * Calls [methodOrCallback] with [args] if it is a closure, otherwise, treat
   * it as a method name in [object], and invoke it.
   */
  void dispatchMethod(object, callbackOrMethod, List args) {
    bool log = _eventsLog.isLoggable(Level.FINE);
    if (log) _eventsLog.fine('>>> [$localName]: dispatch $callbackOrMethod');

    if (callbackOrMethod is Function) {
      Function.apply(callbackOrMethod, args);
    } else if (callbackOrMethod is String) {
      _invokeMethod(object, new Symbol(callbackOrMethod), args);
    } else {
      _eventsLog.warning('invalid callback');
    }

    if (log) _eventsLog.info('<<< [$localName]: dispatch $callbackOrMethod');
  }

  /**
   * Bind events via attributes of the form `on-eventName`. This method can be
   * use to hooks into the model syntax and adds event listeners as needed. By
   * default, binding paths are always method names on the root model, the
   * custom element in which the node exists. Adding a '@' in the path directs
   * the event binding to use the model path as the event listener.  In both
   * cases, the actual listener is attached to a generic method which evaluates
   * the bound path at event execution time.
   */
  // from src/instance/event.js#prepareBinding
  // TODO(sorvell): we're patching the syntax while evaluating
  // event bindings. we'll move this to a better spot when that's done
  static PrepareBindingFunction prepareBinding(String path, String name, node,
      originalPrepareBinding) {

    // if lhs an event prefix,
    if (!_hasEventPrefix(name)) return originalPrepareBinding(path, name, node);

    // provide an event-binding callback.
    return (model, node) {
      if (_eventsLog.isLoggable(Level.FINE)) {
        _eventsLog.fine('event: [$node].$name => [$model].$path())');
      }
      var eventName = _removeEventPrefix(name);
      // TODO(sigmund): polymer.js dropped event translations. reconcile?
      var translated = _eventTranslations[eventName];
      eventName = translated != null ? translated : eventName;

      // TODO(jmesserly): we need a place to unregister this. See:
      // https://code.google.com/p/dart/issues/detail?id=15574
      node.on[eventName].listen((event) {
        var ctrlr = _findController(node);
        if (ctrlr is! Polymer) return;
        var obj = ctrlr;
        var method = path;
        if (path[0] == '@') {
          obj = model;
          method = new PathObserver(model, path.substring(1)).value;
        }
        var detail = event is CustomEvent ?
            (event as CustomEvent).detail : null;
        ctrlr.dispatchMethod(obj, method, [event, detail, node]);
      });

      // TODO(jmesserly): this return value is bogus. Returning null here causes
      // the wrong thing to happen in template_binding.
      return new ObservableBox();
    };
  }

  // TODO(jmesserly): this won't find the correct host unless the ShadowRoot
  // was created on a PolymerElement.
  static Polymer _findController(Node node) {
    while (node.parentNode != null) {
      node = node.parentNode;
    }
    return _shadowHost[node];
  }

  /** Call [methodName] method on this object with [args]. */
  invokeMethod(Symbol methodName, List args) =>
      _invokeMethod(this, methodName, args);

  /** Call [methodName] method on [receiver] with [args]. */
  static _invokeMethod(receiver, Symbol methodName, List args) {
    // TODO(sigmund): consider making callbacks list all arguments
    // explicitly. Unless VM mirrors are optimized first, this will be expensive
    // once custom elements extend directly from Element (see issue 11108).
    var receiverMirror = reflect(receiver);
    var method = _findMethod(receiverMirror.type, methodName);
    if (method != null) {
      // This will either truncate the argument list or extend it with extra
      // null arguments, so it will match the signature.
      // TODO(sigmund): consider accepting optional arguments when we can tell
      // them appart from named arguments (see http://dartbug.com/11334)
      args.length = method.parameters.where((p) => !p.isOptional).length;
    }
    return receiverMirror.invoke(methodName, args).reflectee;
  }

  static MethodMirror _findMethod(ClassMirror type, Symbol name) {
    do {
      var member = type.declarations[name];
      if (member is MethodMirror) return member;
      type = type.superclass;
    } while (type != null);
  }

  /**
   * Invokes a function asynchronously.
   * This will call `Platform.flush()` and then return a `new Timer`
   * with the provided [method] and [timeout].
   *
   * If you would prefer to run the callback using
   * [window.requestAnimationFrame], see the [async] method.
   */
  // Dart note: "async" is split into 2 methods so it can have a sensible type
  // signatures. Also removed the various features that don't make sense in a
  // Dart world, like binding to "this" and taking arguments list.
  Timer asyncTimer(void method(), Duration timeout) {
    // when polyfilling Object.observe, ensure changes
    // propagate before executing the async method
    scheduleMicrotask(Observable.dirtyCheck);
    return new Timer(timeout, method);
  }

  /**
   * Invokes a function asynchronously.
   * This will call `Platform.flush()` and then call
   * [window.requestAnimationFrame] with the provided [method] and return the
   * result.
   *
   * If you would prefer to run the callback after a given duration, see
   * the [asyncTimer] method.
   */
  int async(RequestAnimationFrameCallback method) {
    // when polyfilling Object.observe, ensure changes
    // propagate before executing the async method
    scheduleMicrotask(Observable.dirtyCheck);
    return window.requestAnimationFrame(method);
  }

  /**
   * Fire a [CustomEvent] targeting [toNode], or this if toNode is not
   * supplied. Returns the [detail] object.
   */
  Object fire(String type, {Object detail, Node toNode, bool canBubble}) {
    var node = toNode != null ? toNode : this;
    //log.events && console.log('[%s]: sending [%s]', node.localName, inType);
    node.dispatchEvent(new CustomEvent(
      type,
      canBubble: canBubble != null ? canBubble : true,
      detail: detail
    ));
    return detail;
  }

  /**
   * Fire an event asynchronously. See [async] and [fire].
   */
  asyncFire(String type, {Object detail, Node toNode, bool canBubble}) {
    // TODO(jmesserly): I'm not sure this method adds much in Dart, it's easy to
    // add "() =>"
    async((x) => fire(
        type, detail: detail, toNode: toNode, canBubble: canBubble));
  }

  /**
   * Remove [className] from [old], add class to [anew], if they exist.
   */
  void classFollows(Element anew, Element old, String className) {
    if (old != null) {
      old.classes.remove(className);
    }
    if (anew != null) {
      anew.classes.add(className);
    }
  }

  /**
   * Installs external stylesheets and <style> elements with the attribute
   * polymer-scope='controller' into the scope of element. This is intended
   * to be a called during custom element construction. Note, this incurs a
   * per instance cost and should be used sparingly.
   *
   * The need for this type of styling should go away when the shadowDOM spec
   * addresses these issues:
   *
   * https://www.w3.org/Bugs/Public/show_bug.cgi?id=21391
   * https://www.w3.org/Bugs/Public/show_bug.cgi?id=21390
   * https://www.w3.org/Bugs/Public/show_bug.cgi?id=21389
   *
   * @param element The custom element instance into whose controller (parent)
   * scope styles will be installed.
   * @param elementElement The <element> containing controller styles.
   */
  // TODO(sorvell): remove when spec issues are addressed
  void installControllerStyles() {
    var scope = findStyleController();
    if (scope != null && scopeHasElementStyle(scope, _STYLE_CONTROLLER_SCOPE)) {
      // allow inherited controller styles
      var decl = _declaration;
      var cssText = new StringBuffer();
      while (decl != null) {
        cssText.write(decl.cssTextForScope(_STYLE_CONTROLLER_SCOPE));
        decl = decl.superDeclaration;
      }
      if (cssText.length > 0) {
        var style = decl.cssTextToScopeStyle(cssText.toString(),
              _STYLE_CONTROLLER_SCOPE);
        // TODO(sorvell): for now these styles are not shimmed
        // but we may need to shim them
        Polymer.applyStyleToScope(style, scope);
      }
    }
  }

  Node findStyleController() {
    if (js.context != null && js.context['ShadowDOMPolyfill'] != null) {
      return document.querySelector('head'); // get wrapped <head>.
    } else {
      // find the shadow root that contains this element
      var n = this;
      while (n.parentNode != null) {
        n = n.parentNode;
      }
      return identical(n, document) ? document.head : n;
    }
  }

  bool scopeHasElementStyle(scope, descriptor) {
    var rule = '$_STYLE_SCOPE_ATTRIBUTE=$localName-$descriptor';
    return scope.querySelector('style[$rule]') != null;
  }

  static void applyStyleToScope(StyleElement style, Node scope) {
    if (style == null) return;

    // TODO(sorvell): necessary for IE
    // see https://connect.microsoft.com/IE/feedback/details/790212/
    // cloning-a-style-element-and-adding-to-document-produces
    // -unexpected-result#details
    // var clone = style.cloneNode(true);
    var clone = new StyleElement()..text = style.text;

    var attr = style.attributes[_STYLE_SCOPE_ATTRIBUTE];
    if (attr != null) {
      clone.attributes[_STYLE_SCOPE_ATTRIBUTE] = attr;
    }

    scope.append(clone);
  }

  /**
   * Prevents flash of unstyled content
   * This is the list of selectors for veiled elements
   */
  static List<Element> veiledElements = ['body'];

  /** Apply unveil class. */
  static void unveilElements() {
    window.requestAnimationFrame((_) {
      var nodes = document.querySelectorAll('.$_VEILED_CLASS');
      for (var node in nodes) {
        (node.classes)..add(_UNVEIL_CLASS)..remove(_VEILED_CLASS);
      }
      // NOTE: depends on transition end event to remove 'unveil' class.
      if (nodes.isNotEmpty) {
        window.onTransitionEnd.first.then((_) {
          for (var node in nodes) {
            node.classes.remove(_UNVEIL_CLASS);
          }
        });
      }
    });
  }
}

// Dart note: Polymer addresses n-way bindings by metaprogramming: redefine
// the property on the PolymerElement instance to always get its value from the
// model@path. We can't replicate this in Dart so we do the next best thing:
// listen to changes on both sides and update the values.
// TODO(jmesserly): our approach leads to race conditions in the bindings.
// See http://code.google.com/p/dart/issues/detail?id=13567
class _PolymerBinding extends NodeBinding {
  final InstanceMirror _target;
  final Symbol _property;
  StreamSubscription _sub;
  Object _lastValue;

  _PolymerBinding(Polymer node, Symbol property, model, path)
      : _target = reflect(node),
        _property = property,
        super(node, MirrorSystem.getName(property), model, path) {

    _sub = node.changes.listen(_propertyValueChanged);
  }

  void close() {
    if (closed) return;
    _sub.cancel();
    super.close();
  }

  void valueChanged(newValue) {
    _lastValue = newValue;
    _target.setField(_property, newValue);
  }

  void _propertyValueChanged(List<ChangeRecord> records) {
    for (var record in records) {
      if (record is PropertyChangeRecord && record.name == _property) {
        final newValue = _target.getField(_property).reflectee;
        if (!identical(_lastValue, newValue)) {
          value = newValue;
        }
        return;
      }
    }
  }
}

bool _toBoolean(value) => null != value && false != value;

TypeMirror _propertyType(DeclarationMirror property) =>
    property is VariableMirror
        ? (property as VariableMirror).type
        : (property as MethodMirror).returnType;

TypeMirror _inferPropertyType(Object value, DeclarationMirror property) {
  var type = _propertyType(property);
  if (type.qualifiedName == #dart.core.Object ||
      type.qualifiedName == #dynamic) {
    // Attempt to infer field type from the default value.
    if (value != null) {
      Type t = _getCoreType(value);
      if (t != null) return reflectClass(t);
      return reflect(value).type;
    }
  }
  return type;
}

Type _getCoreType(Object value) {
  if (value == null) return Null;
  if (value is int) return int;
  // Avoid "is double" to prevent warning that it won't work in dart2js.
  if (value is num) return double;
  if (value is bool) return bool;
  if (value is String) return String;
  if (value is DateTime) return DateTime;
  return null;
}

final Logger _observeLog = new Logger('polymer.observe');
final Logger _eventsLog = new Logger('polymer.events');
final Logger _unbindLog = new Logger('polymer.unbind');
final Logger _bindLog = new Logger('polymer.bind');

final Expando _shadowHost = new Expando<Polymer>();

final Expando _eventHandledTable = new Expando<Set<Node>>();

/**
 * Base class for PolymerElements deriving from HtmlElement.
 *
 * See [Polymer].
 */
class PolymerElement extends HtmlElement with Polymer, Observable {
  PolymerElement.created() : super.created() {
    polymerCreated();
  }
}

class _PropertyValue {
  Object oldValue, newValue;
  _PropertyValue(this.oldValue);
}

class _PolymerExpressionsWithEventDelegate extends PolymerExpressions {
  prepareBinding(String path, name, node) =>
      Polymer.prepareBinding(path, name, node, super.prepareBinding);
}
