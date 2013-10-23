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
 */
abstract class Polymer implements Element, Observable {
  // Fully ported from revision:
  // https://github.com/Polymer/polymer/blob/4dc481c11505991a7c43228d3797d28f21267779
  //
  //   src/instance/attributes.js
  //   src/instance/base.js
  //   src/instance/events.js
  //   src/instance/mdv.js
  //   src/instance/properties.js
  //   src/instance/utils.js
  //
  // Not yet ported:
  //   src/instance/style.js -- blocked on ShadowCSS.shimPolyfillDirectives

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
  static final BindingDelegate _polymerSyntax = new PolymerExpressions();

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

  Map<String, StreamSubscription> _elementObservers;
  bool _unbound; // lazy-initialized
  Job _unbindAllJob;

  bool get _elementPrepared => _declaration != null;

  bool get applyAuthorStyles => false;
  bool get resetStyleInheritance => false;
  bool get alwaysPrepare => false;

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
  // For now I picked the most performant choice: non-live HashMap.
  final Map<String, Element> $ = new HashMap<String, Element>();

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
   * Invoke [callback] in [wait], unless the job is re-registered,
   * which resets the timer. For example:
   *
   *     _myJob = job(_myJob, callback, const Duration(milliseconds: 100));
   *
   * Returns a job handle which can be used to re-register a job.
   */
  Job job(Job job, void callback(), Duration wait) =>
      runJob(job, callback, wait);

  void polymerCreated() {
    if (this.ownerDocument.window != null || alwaysPrepare ||
        _preparingElements > 0) {
      prepareElement();
    }
  }

  void prepareElement() {
    // Dart note: get the _declaration, which also marks _elementPrepared
    _declaration = _getDeclaration(this.runtimeType);
    // do this first so we can observe changes during initialization
    observeProperties();
    // install boilerplate attributes
    copyInstanceAttributes();
    // process input attributes
    takeAttributes();
    // add event listeners
    addHostListeners();
    // guarantees that while preparing, any sub-elements will also be prepared
    _preparingElements++;
    // process declarative resources
    parseDeclarations(_declaration);
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
    asyncUnbindAll();
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
    var root = shadowFromTemplate(fetchTemplate(elementElement));

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
    // add local events of interest...
    addInstanceListeners(root, template);
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

  // TODO(jmesserly): use stream or future here?
  /**
   * Run the `listener` callback *once*
   * when `node` changes, or when its children or subtree changes.
   *
   *
   * See [MutationObserver] if you want to listen to a stream of
   * changes.
   */
  void onMutation(Node node, void listener(MutationObserver obs)) {
    new MutationObserver((records, MutationObserver observer) {
      listener(observer);
      observer.disconnect();
    })..observe(node, childList: true, subtree: true);
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
    final defaultValue = self.getField(property.simpleName).reflectee;

    // deserialize Boolean or Number values from attribute
    final newValue = deserializeValue(value, defaultValue,
        _inferPropertyType(defaultValue, property));

    // only act if the value has changed
    if (!identical(newValue, defaultValue)) {
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
   * Convert representation of [value] based on [type] and [defaultValue].
   */
  // TODO(jmesserly): this should probably take a ClassMirror instead of
  // TypeMirror, but it is currently impossible to get from a TypeMirror to a
  // ClassMirror.
  Object deserializeValue(String value, Object defaultValue, TypeMirror type) =>
      deserialize.deserializeValue(value, defaultValue, type);

  String serializeValue(Object value) {
    if (value == null) return null;

    if (value is bool) {
      return _toBoolean(value) ? '' : null;
    } else if (value is String || value is int || value is double) {
      return '$value';
    }
    return null;
  }

  void reflectPropertyToAttribute(String name) {
    // TODO(sjmiles): consider memoizing this
    final self = reflect(this);
    // try to intelligently serialize property value
    // TODO(jmesserly): cache symbol?
    final propValue = self.getField(new Symbol(name)).reflectee;
    final serializedValue = serializeValue(propValue);
    // boolean properties must reflect as boolean attributes
    if (serializedValue != null) {
      attributes[name] = serializedValue;
      // TODO(sorvell): we should remove attr for all properties
      // that have undefined serialization; however, we will need to
      // refine the attr reflection system to achieve this; pica, for example,
      // relies on having inferredType object properties not removed as
      // attrs.
    } else if (propValue is bool) {
      attributes.remove(name);
    }
  }

  /**
   * Creates the document fragment to use for each instance of the custom
   * element, given the `<template>` node. By default this is equivalent to:
   *
   *     template.createInstance(this, polymerSyntax);
   *
   * Where polymerSyntax is a singleton `PolymerExpressions` instance from the
   * [polymer_expressions](https://pub.dartlang.org/packages/polymer_expressions)
   * package.
   *
   * You can override this method to change the instantiation behavior of the
   * template, for example to use a different data-binding syntax.
   */
  DocumentFragment instanceTemplate(Element template) =>
      template.createInstance(this, _polymerSyntax);

  NodeBinding bind(String name, model, String path) {
    // note: binding is a prepare signal. This allows us to be sure that any
    // property changes that occur as a result of binding will be observed.
    if (!_elementPrepared) prepareElement();

    var property = propertyForAttribute(name);
    if (property != null) {
      unbind(name);
      // use n-way Polymer binding
      var observer = bindProperty(property.simpleName, model, path);
      // reflect bound property to attribute when binding
      // to ensure binding is not left on attribute if property
      // does not update due to not changing.
      // Dart note: we include this patch:
      // https://github.com/Polymer/polymer/pull/319
      reflectPropertyToAttribute(MirrorSystem.getName(property.simpleName));
      return bindings[name] = observer;
    } else {
      // Cannot call super.bind because of
      // https://code.google.com/p/dart/issues/detail?id=13156
      // https://code.google.com/p/dart/issues/detail?id=12456
      return TemplateElement.mdvPackage(this).bind(name, model, path);
    }
  }

  void asyncUnbindAll() {
    if (_unbound == true) return;
    _unbindLog.fine('[$localName] asyncUnbindAll');
    _unbindAllJob = job(_unbindAllJob, unbindAll, const Duration(seconds: 0));
  }

  void unbindAll() {
    if (_unbound == true) return;

    unbindAllProperties();
    // Cannot call super.bind because of
    // https://code.google.com/p/dart/issues/detail?id=13156
    // https://code.google.com/p/dart/issues/detail?id=12456
    TemplateElement.mdvPackage(this).unbindAll();

    _unbindNodeTree(shadowRoot);
    // TODO(sjmiles): must also unbind inherited shadow roots
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
    _forNodeTree(node, (node) => node.unbindAll());
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
    // TODO(sjmiles):
    // we observe published properties so we can reflect them to attributes
    // ~100% of our team's applications would work without this reflection,
    // perhaps we can make it optional somehow
    //
    // add user's observers
    final observe = _declaration._observe;
    final publish = _declaration._publish;
    if (observe != null) {
      observe.forEach((name, value) {
        if (publish != null && publish.containsKey(name)) {
          observeBoth(name, value);
        } else {
          observeProperty(name, value);
        }
      });
    }
    // add observers for published properties
    if (publish != null) {
      publish.forEach((name, value) {
        if (observe == null || !observe.containsKey(name)) {
          observeAttributeProperty(name);
        }
      });
    }
  }

  void _observe(String name, void callback(newValue, oldValue)) {
    _observeLog.fine('[$localName] watching [$name]');
    // TODO(jmesserly): this is a little different than the JS version so we
    // can pass the oldValue, which is missing from Dart's PathObserver.
    // This probably gives us worse performance.
    var path = new PathObserver(this, name);
    Object oldValue = null;
    _registerObserver(name, path.changes.listen((_) {
      final newValue = path.value;
      final old = oldValue;
      oldValue = newValue;
      callback(newValue, old);
    }));
  }

  void _registerObserver(String name, StreamSubscription sub) {
    if (_elementObservers == null) {
      _elementObservers = new Map<String, StreamSubscription>();
    }
    _elementObservers[name] = sub;
  }

  void observeAttributeProperty(String name) {
    _observe(name, (value, old) => reflectPropertyToAttribute(name));
  }

  void observeProperty(String name, Symbol method) {
    final self = reflect(this);
    _observe(name, (value, old) => self.invoke(method, [old]));
  }

  void observeBoth(String name, Symbol methodName) {
    final self = reflect(this);
    _observe(name, (value, old) {
      reflectPropertyToAttribute(name);
      self.invoke(methodName, [old]);
    });
  }

  void unbindProperty(String name) {
    if (_elementObservers == null) return;
    var sub = _elementObservers.remove(name);
    if (sub != null) sub.cancel();
  }

  void unbindAllProperties() {
    if (_elementObservers == null) return;
    for (var sub in _elementObservers.values) sub.cancel();
    _elementObservers.clear();
  }

  /**
   * Bind a [property] in this object to a [path] in model. *Note* in Dart it
   * is necessary to also define the field:
   *
   *     var myProperty;
   *
   *     created() {
   *       super.created();
   *       bindProperty(#myProperty, this, 'myModel.path.to.otherProp');
   *     }
   */
  // TODO(jmesserly): replace with something more localized, like:
  // @ComputedField('myModel.path.to.otherProp');
  NodeBinding bindProperty(Symbol name, Object model, String path) =>
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

  /** Attach event listeners inside a shadow [root]. */
  void addInstanceListeners(Node root, Element template) {
    var templateDelegates = _declaration._templateDelegates;
    if (templateDelegates == null) return;
    var events = templateDelegates[template];
    if (events == null) return;

    if (_eventsLog.isLoggable(Level.FINE)) {
      _eventsLog.fine('[$localName] addInstanceListeners: $events');
    }
    addNodeListeners(root, events, instanceEventListener);
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
      dispatchMethod(new Symbol(h), [event, detail, this]);
    }

    if (log) {
      _eventsLog.fine('<<< [$localName]: hostEventListener(${event.type})');
    }
  }

  String findEventDelegate(Event event) =>
      _declaration._eventDelegates[_eventNameFromType(event.type)];

  /** Call [methodName] method on [this] with [args], if the method exists. */
  // TODO(jmesserly): I removed the [node] argument as it was unused. Reconcile.
  void dispatchMethod(Symbol methodName, List args) {
    bool log = _eventsLog.isLoggable(Level.FINE);
    if (log) _eventsLog.fine('>>> [$localName]: dispatch $methodName');

    // TODO(sigmund): consider making event listeners list all arguments
    // explicitly. Unless VM mirrors are optimized first, this reflectClass call
    // will be expensive once custom elements extend directly from Element (see
    // dartbug.com/11108).
    var self = reflect(this);
    var method = self.type.methods[methodName];
    if (method != null) {
      // This will either truncate the argument list or extend it with extra
      // null arguments, so it will match the signature.
      // TODO(sigmund): consider accepting optional arguments when we can tell
      // them appart from named arguments (see http://dartbug.com/11334)
      args.length = method.parameters.where((p) => !p.isOptional).length;
    }
    self.invoke(methodName, args);

    if (log) _eventsLog.fine('<<< [$localName]: dispatch $methodName');
  }

  void instanceEventListener(Event event) {
    _listenLocal(this, event);
  }

  // TODO(sjmiles): much of the below privatized only because of the vague
  // notion this code is too fiddly and we need to revisit the core feature
  void _listenLocal(Polymer host, Event event) {
    // TODO(jmesserly): do we need this check? It was using cancelBubble, see:
    // https://github.com/Polymer/polymer/issues/292
    if (!event.bubbles) return;

    bool log = _eventsLog.isLoggable(Level.FINE);
    if (log) _eventsLog.fine('>>> [$localName]: listenLocal [${event.type}]');

    final eventOn = '$_EVENT_PREFIX${_eventNameFromType(event.type)}';
    if (event.path == null) {
      _listenLocalNoEventPath(host, event, eventOn);
    } else {
      _listenLocalEventPath(host, event, eventOn);
    }

    if (log) _eventsLog.fine('<<< [$localName]: listenLocal [${event.type}]');
  }

  static void _listenLocalEventPath(Polymer host, Event event, String eventOn) {
    var c = null;
    for (var target in event.path) {
      // if we hit host, stop
      if (identical(target, host)) return;

      // find a controller for the target, unless we already found `host`
      // as a controller
      c = identical(c, host) ? c : _findController(target);

      // if we have a controller, dispatch the event, and stop if the handler
      // returns true
      if (c != null && _handleEvent(c, target, event, eventOn)) {
        return;
      }
    }
  }

  // TODO(sorvell): remove when ShadowDOM polyfill supports event path.
  // Note that _findController will not return the expected controller when the
  // event target is a distributed node.  This is because we cannot traverse
  // from a composed node to a node in shadowRoot.
  // This will be addressed via an event path api
  // https://www.w3.org/Bugs/Public/show_bug.cgi?id=21066
  static void _listenLocalNoEventPath(Polymer host, Event event,
      String eventOn) {

    if (_eventsLog.isLoggable(Level.FINE)) {
      _eventsLog.fine('event.path() not supported for ${event.type}');
    }

    var target = event.target;
    var c = null;
    // if we hit dirt or host, stop
    while (target != null && target != host) {
      // find a controller for target `t`, unless we already found `host`
      // as a controller
      c = identical(c, host) ? c : _findController(target);

      // if we have a controller, dispatch the event, return 'true' if
      // handler returns true
      if (c != null && _handleEvent(c, target, event, eventOn)) {
        return;
      }
      target = target.parent;
    }
  }

  // TODO(jmesserly): this won't find the correct host unless the ShadowRoot
  // was created on a PolymerElement.
  static Polymer _findController(Node node) {
    while (node.parentNode != null) {
      node = node.parentNode;
    }
    return _shadowHost[node];
  }

  static bool _handleEvent(Polymer ctrlr, Node node, Event event,
      String eventOn) {

    // Note: local events are listened only in the shadow root. This dynamic
    // lookup is used to distinguish determine whether the target actually has a
    // listener, and if so, to determine lazily what's the target method.
    var name = node is Element ? (node as Element).attributes[eventOn] : null;
    if (name != null && _handleIfNotHandled(node, event)) {
      if (_eventsLog.isLoggable(Level.FINE)) {
        _eventsLog.fine('[${ctrlr.localName}] found handler name [$name]');
      }
      var detail = event is CustomEvent ?
          (event as CustomEvent).detail : null;

      if (node != null) {
        // TODO(jmesserly): cache symbols?
        ctrlr.dispatchMethod(new Symbol(name), [event, detail, node]);
      }
    }

    // TODO(jmesserly): do we need this? It was using cancelBubble, see:
    // https://github.com/Polymer/polymer/issues/292
    return !event.bubbles;
  }

  // TODO(jmesserly): I don't understand this bit. It seems to be a duplicate
  // delivery prevention mechanism?
  static bool _handleIfNotHandled(Node node, Event event) {
    var list = _eventHandledTable[event];
    if (list == null) _eventHandledTable[event] = list = new Set<Node>();
    if (!list.contains(node)) {
      list.add(node);
      return true;
    }
    return false;
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
    platform.flush();
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
    platform.flush();
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

  void boundValueChanged(newValue) {
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
