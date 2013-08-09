if ((!HTMLElement.prototype.createShadowRoot &&
    !HTMLElement.prototype.webkitCreateShadowRoot) ||
    window.__forceShadowDomPolyfill) {

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function() {
  // TODO(jmesserly): fix dart:html to use unprefixed name
  if (Element.prototype.webkitCreateShadowRoot) {
    Element.prototype.webkitCreateShadowRoot = function() {
      return window.ShadowDOMPolyfill.wrapIfNeeded(this).createShadowRoot();
    };
  }
})();

/*
 * Copyright 2012 The Polymer Authors. All rights reserved.
 * Use of this source code is goverened by a BSD-style
 * license that can be found in the LICENSE file.
 */

// SideTable is a weak map where possible. If WeakMap is not available the
// association is stored as an expando property.
var SideTable;
// TODO(arv): WeakMap does not allow for Node etc to be keys in Firefox
if (typeof WeakMap !== 'undefined' && navigator.userAgent.indexOf('Firefox/') < 0) {
  SideTable = WeakMap;
} else {
  (function() {
    var defineProperty = Object.defineProperty;
    var hasOwnProperty = Object.hasOwnProperty;
    var counter = new Date().getTime() % 1e9;

    SideTable = function() {
      this.name = '__st' + (Math.random() * 1e9 >>> 0) + (counter++ + '__');
    };

    SideTable.prototype = {
      set: function(key, value) {
        defineProperty(key, this.name, {value: value, writable: true});
      },
      get: function(key) {
        return hasOwnProperty.call(key, this.name) ? key[this.name] : undefined;
      },
      delete: function(key) {
        this.set(key, undefined);
      }
    }
  })();
}

// Copyright 2012 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

var ShadowDOMPolyfill = {};

(function(scope) {
  'use strict';

  var wrapperTable = new SideTable();
  var constructorTable = new SideTable();
  var wrappers = Object.create(null);

  function assert(b) {
    if (!b)
      throw new Error('Assertion failed');
  };

  function mixin(to, from) {
    Object.getOwnPropertyNames(from).forEach(function(name) {
      Object.defineProperty(to, name,
                            Object.getOwnPropertyDescriptor(from, name));
    });
    return to;
  };

  function mixinStatics(to, from) {
    Object.getOwnPropertyNames(from).forEach(function(name) {
      switch (name) {
        case 'arguments':
        case 'caller':
        case 'length':
        case 'name':
        case 'prototype':
        case 'toString':
          return;
      }
      Object.defineProperty(to, name,
                            Object.getOwnPropertyDescriptor(from, name));
    });
    return to;
  };

  // Mozilla's old DOM bindings are bretty busted:
  // https://bugzilla.mozilla.org/show_bug.cgi?id=855844
  // Make sure they are create before we start modifying things.
  Object.getOwnPropertyNames(window);

  function getWrapperConstructor(node) {
    var nativePrototype = node.__proto__ || Object.getPrototypeOf(node);
    var wrapperConstructor = constructorTable.get(nativePrototype);
    if (wrapperConstructor)
      return wrapperConstructor;

    var parentWrapperConstructor = getWrapperConstructor(nativePrototype);

    var GeneratedWrapper = createWrapperConstructor(parentWrapperConstructor);
    registerInternal(nativePrototype, GeneratedWrapper, node);

    return GeneratedWrapper;
  }

  function addForwardingProperties(nativePrototype, wrapperPrototype) {
    installProperty(nativePrototype, wrapperPrototype, true);
  }

  function registerInstanceProperties(wrapperPrototype, instanceObject) {
    installProperty(instanceObject, wrapperPrototype, false);
  }

  var isFirefox = /Firefox/.test(navigator.userAgent);

  // This is used as a fallback when getting the descriptor fails in
  // installProperty.
  var dummyDescriptor = {
    get: function() {},
    set: function(v) {},
    configurable: true,
    enumerable: true
  };

  function installProperty(source, target, allowMethod) {
    Object.getOwnPropertyNames(source).forEach(function(name) {
      if (name in target)
        return;

      if (isFirefox) {
        // Tickle Firefox's old bindings.
        source.__lookupGetter__(name);
      }
      var descriptor;
      try {
        descriptor = Object.getOwnPropertyDescriptor(source, name);
      } catch (ex) {
        // JSC and V8 both use data properties instead accessors which can cause
        // getting the property desciptor throw an exception.
        // https://bugs.webkit.org/show_bug.cgi?id=49739
        descriptor = dummyDescriptor;
      }
      var getter, setter;
      if (allowMethod && typeof descriptor.value === 'function') {
        target[name] = function() {
          return this.impl[name].apply(this.impl, arguments);
        };
        return;
      }

      getter = function() {
        return this.impl[name];
      };

      if (descriptor.writable || descriptor.set) {
        setter = function(value) {
          this.impl[name] = value;
        };
      }

      Object.defineProperty(target, name, {
        get: getter,
        set: setter,
        configurable: descriptor.configurable,
        enumerable: descriptor.enumerable
      });
    });
  }

  /**
   * @param {Function} nativeConstructor
   * @param {Function} wrapperConstructor
   * @param {string|Object=} opt_instance If present, this is used to extract
   *     properties from an instance object. If this is a string
   *     |document.createElement| is used to create an instance.
   */
  function register(nativeConstructor, wrapperConstructor, opt_instance) {
    var nativePrototype = nativeConstructor.prototype;
    registerInternal(nativePrototype, wrapperConstructor, opt_instance);
    mixinStatics(wrapperConstructor, nativeConstructor);
  }

  function registerInternal(nativePrototype, wrapperConstructor, opt_instance) {
    var wrapperPrototype = wrapperConstructor.prototype;
    assert(constructorTable.get(nativePrototype) === undefined);
    constructorTable.set(nativePrototype, wrapperConstructor);
    addForwardingProperties(nativePrototype, wrapperPrototype);
    if (opt_instance)
      registerInstanceProperties(wrapperPrototype, opt_instance);
  }

  function isWrapperFor(wrapperConstructor, nativeConstructor) {
    return constructorTable.get(nativeConstructor.prototype) ===
        wrapperConstructor;
  }

  /**
   * Creates a generic wrapper constructor based on |object| and its
   * constructor.
   * Sometimes the constructor does not have an associated instance
   * (CharacterData for example). In that case you can pass the constructor that
   * you want to map the object to using |opt_nativeConstructor|.
   * @param {Node} object
   * @param {Function=} opt_nativeConstructor
   * @return {Function} The generated constructor.
   */
  function registerObject(object) {
    var nativePrototype = Object.getPrototypeOf(object);

    var superWrapperConstructor = getWrapperConstructor(nativePrototype);
    var GeneratedWrapper = createWrapperConstructor(superWrapperConstructor);
    registerInternal(nativePrototype, GeneratedWrapper, object);

    return GeneratedWrapper;
  }

  function createWrapperConstructor(superWrapperConstructor) {
    function GeneratedWrapper(node) {
      superWrapperConstructor.call(this, node);
    }
    GeneratedWrapper.prototype =
        Object.create(superWrapperConstructor.prototype);
    GeneratedWrapper.prototype.constructor = GeneratedWrapper;
    // We add this property to work around a Firefox bug where HTMLFormElement
    // and HTMLInputElements sometimes have their constructor incorrectly
    // attached to GeneratedWrapper. See lib/patches-shadowdom-polyfill.js
    GeneratedWrapper._ShadowDOMPolyfill$isGeneratedWrapper = true;

    return GeneratedWrapper;
  }

  var OriginalDOMImplementation = DOMImplementation;
  var OriginalEvent = Event;
  var OriginalNode = Node;
  var OriginalWindow = Window;

  function isWrapper(object) {
    return object instanceof wrappers.EventTarget ||
           object instanceof wrappers.Event ||
           object instanceof wrappers.DOMImplementation;
  }

  function isNative(object) {
    return object instanceof OriginalNode ||
           object instanceof OriginalEvent ||
           object instanceof OriginalWindow ||
           object instanceof OriginalDOMImplementation;
  }

  /**
   * Wraps a node in a WrapperNode. If there already exists a wrapper for the
   * |node| that wrapper is returned instead.
   * @param {Node} node
   * @return {WrapperNode}
   */
  function wrap(impl) {
    if (impl === null)
      return null;

    assert(isNative(impl));
    var wrapper = wrapperTable.get(impl);
    if (!wrapper) {
      var wrapperConstructor = getWrapperConstructor(impl);
      wrapper = new wrapperConstructor(impl);
      wrapperTable.set(impl, wrapper);
    }
    return wrapper;
  }

  /**
   * Unwraps a wrapper and returns the node it is wrapping.
   * @param {WrapperNode} wrapper
   * @return {Node}
   */
  function unwrap(wrapper) {
    if (wrapper === null)
      return null;
    assert(isWrapper(wrapper));
    return wrapper.impl;
  }

  /**
   * Unwraps object if it is a wrapper.
   * @param {Object} object
   * @return {Object} The native implementation object.
   */
  function unwrapIfNeeded(object) {
    return object && isWrapper(object) ? unwrap(object) : object;
  }

  /**
   * Wraps object if it is not a wrapper.
   * @param {Object} object
   * @return {Object} The wrapper for object.
   */
  function wrapIfNeeded(object) {
    return object && !isWrapper(object) ? wrap(object) : object;
  }

  /**
   * Overrides the current wrapper (if any) for node.
   * @param {Node} node
   * @param {WrapperNode=} wrapper If left out the wrapper will be created as
   *     needed next time someone wraps the node.
   */
  function rewrap(node, wrapper) {
    if (wrapper === null)
      return;
    assert(isNative(node));
    assert(wrapper === undefined || isWrapper(wrapper));
    wrapperTable.set(node, wrapper);
  }

  function defineGetter(constructor, name, getter) {
    Object.defineProperty(constructor.prototype, name, {
      get: getter,
      configurable: true,
      enumerable: true
    });
  }

  function defineWrapGetter(constructor, name) {
    defineGetter(constructor, name, function() {
      return wrap(this.impl[name]);
    });
  }

  /**
   * Forwards existing methods on the native object to the wrapper methods.
   * This does not wrap any of the arguments or the return value since the
   * wrapper implementation already takes care of that.
   * @param {Array.<Function>} constructors
   * @parem {Array.<string>} names
   */
  function forwardMethodsToWrapper(constructors, names) {
    constructors.forEach(function(constructor) {
      names.forEach(function(name) {
        constructor.prototype[name] = function() {
          var w = wrap(this);
          return w[name].apply(w, arguments);
        };
      });
    });
  }

  scope.assert = assert;
  scope.defineGetter = defineGetter;
  scope.defineWrapGetter = defineWrapGetter;
  scope.forwardMethodsToWrapper = forwardMethodsToWrapper;
  scope.isWrapper = isWrapper;
  scope.isWrapperFor = isWrapperFor;
  scope.mixin = mixin;
  scope.registerObject = registerObject;
  scope.registerWrapper = register;
  scope.rewrap = rewrap;
  scope.unwrap = unwrap;
  scope.unwrapIfNeeded = unwrapIfNeeded;
  scope.wrap = wrap;
  scope.wrapIfNeeded = wrapIfNeeded;
  scope.wrappers = wrappers;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var forwardMethodsToWrapper = scope.forwardMethodsToWrapper;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;
  var wrappers = scope.wrappers;

  var wrappedFuns = new SideTable();
  var listenersTable = new SideTable();
  var handledEventsTable = new SideTable();
  var targetTable = new SideTable();
  var currentTargetTable = new SideTable();
  var relatedTargetTable = new SideTable();
  var eventPhaseTable = new SideTable();
  var stopPropagationTable = new SideTable();
  var stopImmediatePropagationTable = new SideTable();

  function isShadowRoot(node) {
    return node instanceof wrappers.ShadowRoot;
  }

  function isInsertionPoint(node) {
    var localName = node.localName;
    return localName === 'content' || localName === 'shadow';
  }

  function isShadowHost(node) {
    return !!node.shadowRoot;
  }

  function getEventParent(node) {
    var dv;
    return node.parentNode || (dv = node.defaultView) && wrap(dv) || null;
  }

  // https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#dfn-adjusted-parent
  function calculateParents(node, context, ancestors) {
    if (ancestors.length)
      return ancestors.shift();

    // 1.
    if (isShadowRoot(node))
      return node.insertionParent || scope.getHostForShadowRoot(node);

    // 2.
    var eventParents = scope.eventParentsTable.get(node);
    if (eventParents) {
      // Copy over the remaining event parents for next iteration.
      for (var i = 1; i < eventParents.length; i++) {
        ancestors[i - 1] = eventParents[i];
      }
      return eventParents[0];
    }

    // 3.
    if (context && isInsertionPoint(node)) {
      var parentNode = node.parentNode;
      if (parentNode && isShadowHost(parentNode)) {
        var trees = scope.getShadowTrees(parentNode);
        var p = context.insertionParent;
        for (var i = 0; i < trees.length; i++) {
          if (trees[i].contains(p))
            return p;
        }
      }
    }

    return getEventParent(node);
  }

  // https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#event-retargeting
  function retarget(node) {
    var stack = [];  // 1.
    var ancestor = node;  // 2.
    var targets = [];
    var ancestors = [];
    while (ancestor) {  // 3.
      var context = null;  // 3.2.
      // TODO(arv): Change order of these. If the stack is empty we always end
      // up pushing ancestor, no matter what.
      if (isInsertionPoint(ancestor)) {  // 3.1.
        context = topMostNotInsertionPoint(stack);  // 3.1.1.
        var top = stack[stack.length - 1] || ancestor;  // 3.1.2.
        stack.push(top);
      } else if (!stack.length) {
        stack.push(ancestor);  // 3.3.
      }
      var target = stack[stack.length - 1];  // 3.4.
      targets.push({target: target, currentTarget: ancestor});  // 3.5.
      if (isShadowRoot(ancestor))  // 3.6.
        stack.pop();  // 3.6.1.

      ancestor = calculateParents(ancestor, context, ancestors);  // 3.7.
    }
    return targets;
  }

  function topMostNotInsertionPoint(stack) {
    for (var i = stack.length - 1; i >= 0; i--) {
      if (!isInsertionPoint(stack[i]))
        return stack[i];
    }
    return null;
  }

  // https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#dfn-adjusted-related-target
  function adjustRelatedTarget(target, related) {
    var ancestors = [];
    while (target) {  // 3.
      var stack = [];  // 3.1.
      var ancestor = related;  // 3.2.
      var last = undefined;  // 3.3. Needs to be reset every iteration.
      while (ancestor) {
        var context = null;
        if (!stack.length) {
          stack.push(ancestor);
        } else {
          if (isInsertionPoint(ancestor)) {  // 3.4.3.
            context = topMostNotInsertionPoint(stack);
            // isDistributed is more general than checking whether last is
            // assigned into ancestor.
            if (isDistributed(last)) {  // 3.4.3.2.
              var head = stack[stack.length - 1];
              stack.push(head);
            }
          }
        }

        if (inSameTree(ancestor, target))  // 3.4.4.
          return stack[stack.length - 1];

        if (isShadowRoot(ancestor))  // 3.4.5.
          stack.pop();

        last = ancestor;  // 3.4.6.
        ancestor = calculateParents(ancestor, context, ancestors);  // 3.4.7.
      }
      if (isShadowRoot(target))  // 3.5.
        target = scope.getHostForShadowRoot(target);
      else
        target = target.parentNode;  // 3.6.
    }
  }

  function isDistributed(node) {
    return node.insertionParent;
  }

  function rootOfNode(node) {
    var p;
    while (p = node.parentNode) {
      node = p;
    }
    return node;
  }

  function inSameTree(a, b) {
    return rootOfNode(a) === rootOfNode(b);
  }

  function isMutationEvent(type) {
    switch (type) {
      case 'DOMAttrModified':
      case 'DOMAttributeNameChanged':
      case 'DOMCharacterDataModified':
      case 'DOMElementNameChanged':
      case 'DOMNodeInserted':
      case 'DOMNodeInsertedIntoDocument':
      case 'DOMNodeRemoved':
      case 'DOMNodeRemovedFromDocument':
      case 'DOMSubtreeModified':
        return true;
    }
    return false;
  }

  function dispatchOriginalEvent(originalEvent) {
    // Make sure this event is only dispatched once.
    if (handledEventsTable.get(originalEvent))
      return;
    handledEventsTable.set(originalEvent, true);

    // Don't do rendering if this is a mutation event since rendering might
    // mutate the DOM which would fire more events and we would most likely
    // just iloop.
    if (!isMutationEvent(originalEvent.type))
      scope.renderAllPending();

    var target = wrap(originalEvent.target);
    var event = wrap(originalEvent);
    return dispatchEvent(event, target);
  }

  function dispatchEvent(event, originalWrapperTarget) {
    var eventPath = retarget(originalWrapperTarget);

    // For window load events the load event is dispatched at the window but
    // the target is set to the document.
    //
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#the-end
    //
    // TODO(arv): Find a loess hacky way to do this.
    if (event.type === 'load' &&
        eventPath.length === 2 &&
        eventPath[0].target instanceof wrappers.Document) {
      eventPath.shift();
    }

    if (dispatchCapturing(event, eventPath)) {
      if (dispatchAtTarget(event, eventPath)) {
        dispatchBubbling(event, eventPath);
      }
    }

    eventPhaseTable.set(event, Event.NONE);
    currentTargetTable.set(event, null);

    return event.defaultPrevented;
  }

  function dispatchCapturing(event, eventPath) {
    var phase;

    for (var i = eventPath.length - 1; i > 0; i--) {
      var target = eventPath[i].target;
      var currentTarget = eventPath[i].currentTarget;
      if (target === currentTarget)
        continue;

      phase = Event.CAPTURING_PHASE;
      if (!invoke(eventPath[i], event, phase))
        return false;
    }

    return true;
  }

  function dispatchAtTarget(event, eventPath) {
    var phase = Event.AT_TARGET;
    return invoke(eventPath[0], event, phase);
  }

  function dispatchBubbling(event, eventPath) {
    var bubbles = event.bubbles;
    var phase;

    for (var i = 1; i < eventPath.length; i++) {
      var target = eventPath[i].target;
      var currentTarget = eventPath[i].currentTarget;
      if (target === currentTarget)
        phase = Event.AT_TARGET;
      else if (bubbles && !stopImmediatePropagationTable.get(event))
        phase = Event.BUBBLING_PHASE;
      else
        continue;

      if (!invoke(eventPath[i], event, phase))
        return;
    }
  }

  function invoke(tuple, event, phase) {
    var target = tuple.target;
    var currentTarget = tuple.currentTarget;

    var listeners = listenersTable.get(currentTarget);
    if (!listeners)
      return true;

    if ('relatedTarget' in event) {
      var originalEvent = unwrap(event);
      var relatedTarget = wrap(originalEvent.relatedTarget);

      var adjusted = adjustRelatedTarget(currentTarget, relatedTarget);
      if (adjusted === target)
        return true;

      relatedTargetTable.set(event, adjusted);
    }

    eventPhaseTable.set(event, phase);
    var type = event.type;

    var anyRemoved = false;
    targetTable.set(event, target);
    currentTargetTable.set(event, currentTarget);

    for (var i = 0; i < listeners.length; i++) {
      var listener = listeners[i];
      if (listener.removed) {
        anyRemoved = true;
        continue;
      }

      if (listener.type !== type ||
          !listener.capture && phase === Event.CAPTURING_PHASE ||
          listener.capture && phase === Event.BUBBLING_PHASE) {
        continue;
      }

      try {
        if (typeof listener.handler === 'function')
          listener.handler.call(currentTarget, event);
        else
          listener.handler.handleEvent(event);

        if (stopImmediatePropagationTable.get(event))
          return false;

      } catch (ex) {
        if (window.onerror)
          window.onerror(ex.message);
        else
          console.error(ex);
      }
    }

    if (anyRemoved) {
      var copy = listeners.slice();
      listeners.length = 0;
      for (var i = 0; i < copy.length; i++) {
        if (!copy[i].removed)
          listeners.push(copy[i]);
      }
    }

    return !stopPropagationTable.get(event);
  }

  function Listener(type, handler, capture) {
    this.type = type;
    this.handler = handler;
    this.capture = Boolean(capture);
  }
  Listener.prototype = {
    equals: function(that) {
      return this.handler === that.handler && this.type === that.type &&
          this.capture === that.capture;
    },
    get removed() {
      return this.handler === null;
    },
    remove: function() {
      this.handler = null;
    }
  };

  var OriginalEvent = window.Event;

  /**
   * Creates a new Event wrapper or wraps an existin native Event object.
   * @param {string|Event} type
   * @param {Object=} options
   * @constructor
   */
  function Event(type, options) {
    if (type instanceof OriginalEvent)
      this.impl = type;
    else
      return wrap(constructEvent(OriginalEvent, 'Event', type, options));
  }
  Event.prototype = {
    get target() {
      return targetTable.get(this);
    },
    get currentTarget() {
      return currentTargetTable.get(this);
    },
    get eventPhase() {
      return eventPhaseTable.get(this);
    },
    stopPropagation: function() {
      stopPropagationTable.set(this, true);
    },
    stopImmediatePropagation: function() {
      stopPropagationTable.set(this, true);
      stopImmediatePropagationTable.set(this, true);
    }
  };
  registerWrapper(OriginalEvent, Event, document.createEvent('Event'));

  function unwrapOptions(options) {
    if (!options || !options.relatedTarget)
      return options;
    return Object.create(options, {
      relatedTarget: {value: unwrap(options.relatedTarget)}
    });
  }

  function registerGenericEvent(name, SuperEvent, prototype) {
    var OriginalEvent = window[name];
    var GenericEvent = function(type, options) {
      if (type instanceof OriginalEvent)
        this.impl = type;
      else
        return wrap(constructEvent(OriginalEvent, name, type, options));
    };
    GenericEvent.prototype = Object.create(SuperEvent.prototype);
    if (prototype)
      mixin(GenericEvent.prototype, prototype);
    // Firefox does not support FocusEvent
    // https://bugzilla.mozilla.org/show_bug.cgi?id=855741
    if (OriginalEvent)
      registerWrapper(OriginalEvent, GenericEvent, document.createEvent(name));
    return GenericEvent;
  }

  var UIEvent = registerGenericEvent('UIEvent', Event);
  var CustomEvent = registerGenericEvent('CustomEvent', Event);

  var relatedTargetProto = {
    get relatedTarget() {
      return relatedTargetTable.get(this) || wrap(unwrap(this).relatedTarget);
    }
  };

  function getInitFunction(name, relatedTargetIndex) {
    return function() {
      arguments[relatedTargetIndex] = unwrap(arguments[relatedTargetIndex]);
      var impl = unwrap(this);
      impl[name].apply(impl, arguments);
    };
  }

  var mouseEventProto = mixin({
    initMouseEvent: getInitFunction('initMouseEvent', 14)
  }, relatedTargetProto);

  var focusEventProto = mixin({
    initFocusEvent: getInitFunction('initFocusEvent', 5)
  }, relatedTargetProto);

  var MouseEvent = registerGenericEvent('MouseEvent', UIEvent, mouseEventProto);
  var FocusEvent = registerGenericEvent('FocusEvent', UIEvent, focusEventProto);

  var MutationEvent = registerGenericEvent('MutationEvent', Event, {
    initMutationEvent: getInitFunction('initMutationEvent', 3),
    get relatedNode() {
      return wrap(this.impl.relatedNode);
    },
  });

  // In case the browser does not support event constructors we polyfill that
  // by calling `createEvent('Foo')` and `initFooEvent` where the arguments to
  // `initFooEvent` are derived from the registered default event init dict.
  var defaultInitDicts = Object.create(null);

  var supportsEventConstructors = (function() {
    try {
      new window.MouseEvent('click');
    } catch (ex) {
      return false;
    }
    return true;
  })();

  /**
   * Constructs a new native event.
   */
  function constructEvent(OriginalEvent, name, type, options) {
    if (supportsEventConstructors)
      return new OriginalEvent(type, unwrapOptions(options));

    // Create the arguments from the default dictionary.
    var event = unwrap(document.createEvent(name));
    var defaultDict = defaultInitDicts[name];
    var args = [type];
    Object.keys(defaultDict).forEach(function(key) {
      var v = options != null && key in options ?
          options[key] : defaultDict[key];
      if (key === 'relatedTarget')
        v = unwrap(v);
      args.push(v);
    });
    event['init' + name].apply(event, args);
    return event;
  }

  if (!supportsEventConstructors) {
    var configureEventConstructor = function(name, initDict, superName) {
      if (superName) {
        var superDict = defaultInitDicts[superName];
        initDict = mixin(mixin({}, superDict), initDict);
      }

      defaultInitDicts[name] = initDict;
    };

    // The order of the default event init dictionary keys is important, the
    // arguments to initFooEvent is derived from that.
    configureEventConstructor('Event', {bubbles: false, cancelable: false});
    configureEventConstructor('CustomEvent', {detail: null}, 'Event');
    configureEventConstructor('UIEvent', {view: null, detail: 0}, 'Event');
    configureEventConstructor('MouseEvent', {
      screenX: 0,
      screenY: 0,
      clientX: 0,
      clientY: 0,
      ctrlKey: false,
      altKey: false,
      shiftKey: false,
      metaKey: false,
      button: 0,
      relatedTarget: null
    }, 'UIEvent');
    configureEventConstructor('FocusEvent', {relatedTarget: null}, 'UIEvent');
  }

  function isValidListener(fun) {
    if (typeof fun === 'function')
      return true;
    return fun && fun.handleEvent;
  }

  var OriginalEventTarget = window.EventTarget;

  /**
   * This represents a wrapper for an EventTarget.
   * @param {!EventTarget} impl The original event target.
   * @constructor
   */
  function EventTarget(impl) {
    this.impl = impl;
  }

  // Node and Window have different internal type checks in WebKit so we cannot
  // use the same method as the original function.
  var methodNames = [
    'addEventListener',
    'removeEventListener',
    'dispatchEvent'
  ];

  [Element, Window, Document].forEach(function(constructor) {
    var p = constructor.prototype;
    methodNames.forEach(function(name) {
      Object.defineProperty(p, name + '_', {value: p[name]});
    });
  });

  function getTargetToListenAt(wrapper) {
    if (wrapper instanceof wrappers.ShadowRoot)
      wrapper = scope.getHostForShadowRoot(wrapper);
    return unwrap(wrapper);
  }

  EventTarget.prototype = {
    addEventListener: function(type, fun, capture) {
      if (!isValidListener(fun))
        return;

      var listener = new Listener(type, fun, capture);
      var listeners = listenersTable.get(this);
      if (!listeners) {
        listeners = [];
        listenersTable.set(this, listeners);
      } else {
        // Might have a duplicate.
        for (var i = 0; i < listeners.length; i++) {
          if (listener.equals(listeners[i]))
            return;
        }
      }

      listeners.push(listener);

      var target = getTargetToListenAt(this);
      target.addEventListener_(type, dispatchOriginalEvent, true);
    },
    removeEventListener: function(type, fun, capture) {
      capture = Boolean(capture);
      var listeners = listenersTable.get(this);
      if (!listeners)
        return;
      var count = 0, found = false;
      for (var i = 0; i < listeners.length; i++) {
        if (listeners[i].type === type && listeners[i].capture === capture) {
          count++;
          if (listeners[i].handler === fun) {
            found = true;
            listeners[i].remove();
          }
        }
      }

      if (found && count === 1) {
        var target = getTargetToListenAt(this);
        target.removeEventListener_(type, dispatchOriginalEvent, true);
      }
    },
    dispatchEvent: function(event) {
      scope.renderAllPending();
      var target = getTargetToListenAt(this);
      return target.dispatchEvent_(unwrap(event));
    }
  };

  if (OriginalEventTarget)
    registerWrapper(OriginalEventTarget, EventTarget);

  function wrapEventTargetMethods(constructors) {
    forwardMethodsToWrapper(constructors, methodNames);
  }


  var originalElementFromPoint = document.elementFromPoint;

  function elementFromPoint(self, document, x, y) {
    scope.renderAllPending();

    var element = wrap(originalElementFromPoint.call(document.impl, x, y));
    var targets = retarget(element, this)
    for (var i = 0; i < targets.length; i++) {
      var target = targets[i];
      if (target.currentTarget === self)
        return target.target;
    }
    return null;
  }

  scope.adjustRelatedTarget = adjustRelatedTarget;
  scope.elementFromPoint = elementFromPoint;
  scope.wrapEventTargetMethods = wrapEventTargetMethods;
  scope.wrappers.CustomEvent = CustomEvent;
  scope.wrappers.Event = Event;
  scope.wrappers.EventTarget = EventTarget;
  scope.wrappers.FocusEvent = FocusEvent;
  scope.wrappers.MouseEvent = MouseEvent;
  scope.wrappers.MutationEvent = MutationEvent;
  scope.wrappers.UIEvent = UIEvent;

})(this.ShadowDOMPolyfill);

// Copyright 2012 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var wrap = scope.wrap;

  function nonEnum(obj, prop) {
    Object.defineProperty(obj, prop, {enumerable: false});
  }

  function NodeList() {
    this.length = 0;
    nonEnum(this, 'length');
  }
  NodeList.prototype = {
    item: function(index) {
      return this[index];
    }
  };
  nonEnum(NodeList.prototype, 'item');

  function wrapNodeList(list) {
    if (list == null)
      return list;
    var wrapperList = new NodeList();
    for (var i = 0, length = list.length; i < length; i++) {
      wrapperList[i] = wrap(list[i]);
    }
    wrapperList.length = length;
    return wrapperList;
  }

  function addWrapNodeListMethod(wrapperConstructor, name) {
    wrapperConstructor.prototype[name] = function() {
      return wrapNodeList(this.impl[name].apply(this.impl, arguments));
    };
  }

  scope.wrappers.NodeList = NodeList;
  scope.addWrapNodeListMethod = addWrapNodeListMethod;
  scope.wrapNodeList = wrapNodeList;

})(this.ShadowDOMPolyfill);
// Copyright 2012 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var EventTarget = scope.wrappers.EventTarget;
  var NodeList = scope.wrappers.NodeList;
  var defineWrapGetter = scope.defineWrapGetter;
  var assert = scope.assert;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;

  function assertIsNodeWrapper(node) {
    assert(node instanceof Node);
  }

  /**
   * Collects nodes from a DocumentFragment or a Node for removal followed
   * by an insertion.
   *
   * This updates the internal pointers for node, previousNode and nextNode.
   */
  function collectNodes(node, parentNode, previousNode, nextNode) {
    if (node.nodeType !== Node.DOCUMENT_FRAGMENT_NODE) {
      if (node.parentNode)
        node.parentNode.removeChild(node);
      node.parentNode_ = parentNode;
      node.previousSibling_ = previousNode;
      node.nextSibling_ = nextNode;
      if (previousNode)
        previousNode.nextSibling_ = node;
      if (nextNode)
        nextNode.previousSibling_ = node;
      return [node];
    }

    var nodes = [];
    var firstChild;
    while (firstChild = node.firstChild) {
      node.removeChild(firstChild);
      nodes.push(firstChild);
      firstChild.parentNode_ = parentNode;
    }

    for (var i = 0; i < nodes.length; i++) {
      nodes[i].previousSibling_ = nodes[i - 1] || previousNode;
      nodes[i].nextSibling_ = nodes[i + 1] || nextNode;
    }

    if (previousNode)
      previousNode.nextSibling_ = nodes[0];
    if (nextNode)
      nextNode.previousSibling_ = nodes[nodes.length - 1];

    return nodes;
  }

  function unwrapNodesForInsertion(nodes) {
    if (nodes.length === 1)
      return unwrap(nodes[0]);

    var df = unwrap(document.createDocumentFragment());
    for (var i = 0; i < nodes.length; i++) {
      df.appendChild(unwrap(nodes[i]));
    }
    return df;
  }

  function removeAllChildNodes(wrapper) {
    var childWrapper = wrapper.firstChild;
    while (childWrapper) {
      assert(childWrapper.parentNode === wrapper);
      var nextSibling = childWrapper.nextSibling;
      var childNode = unwrap(childWrapper);
      var parentNode = childNode.parentNode;
      if (parentNode)
        originalRemoveChild.call(parentNode, childNode);
      childWrapper.previousSibling_ = childWrapper.nextSibling_ = childWrapper.parentNode_ = null;
      childWrapper = nextSibling;
    }
    wrapper.firstChild_ = wrapper.lastChild_ = null;
  }

  var OriginalNode = window.Node;

  /**
   * This represents a wrapper of a native DOM node.
   * @param {!Node} original The original DOM node, aka, the visual DOM node.
   * @constructor
   * @extends {EventTarget}
   */
  function Node(original) {
    assert(original instanceof OriginalNode);

    EventTarget.call(this, original);

    // These properties are used to override the visual references with the
    // logical ones. If the value is undefined it means that the logical is the
    // same as the visual.

    /**
     * @type {Node|undefined}
     * @private
     */
    this.parentNode_ = undefined;

    /**
     * @type {Node|undefined}
     * @private
     */
    this.firstChild_ = undefined;

    /**
     * @type {Node|undefined}
     * @private
     */
    this.lastChild_ = undefined;

    /**
     * @type {Node|undefined}
     * @private
     */
    this.nextSibling_ = undefined;

    /**
     * @type {Node|undefined}
     * @private
     */
    this.previousSibling_ = undefined;
  };

  var originalAppendChild = OriginalNode.prototype.appendChild;
  var originalInsertBefore = OriginalNode.prototype.insertBefore;
  var originalReplaceChild = OriginalNode.prototype.replaceChild;
  var originalRemoveChild = OriginalNode.prototype.removeChild;
  var originalCompareDocumentPosition =
      OriginalNode.prototype.compareDocumentPosition;

  Node.prototype = Object.create(EventTarget.prototype);
  mixin(Node.prototype, {
    appendChild: function(childWrapper) {
      assertIsNodeWrapper(childWrapper);

      this.invalidateShadowRenderer();

      var previousNode = this.lastChild;
      var nextNode = null;
      var nodes = collectNodes(childWrapper, this,
                               previousNode, nextNode);

      this.lastChild_ = nodes[nodes.length - 1];
      if (!previousNode)
        this.firstChild_ = nodes[0];

      // TODO(arv): It is unclear if we need to update the visual DOM here.
      // A better aproach might be to make sure we only get here for nodes that
      // are related to a shadow host and then invalidate that and re-render
      // the host (on reflow?).
      originalAppendChild.call(this.impl, unwrapNodesForInsertion(nodes));

      return childWrapper;
    },

    insertBefore: function(childWrapper, refWrapper) {
      // TODO(arv): Unify with appendChild
      if (!refWrapper)
        return this.appendChild(childWrapper);

      assertIsNodeWrapper(childWrapper);
      assertIsNodeWrapper(refWrapper);
      assert(refWrapper.parentNode === this);

      this.invalidateShadowRenderer();

      var previousNode = refWrapper.previousSibling;
      var nextNode = refWrapper;
      var nodes = collectNodes(childWrapper, this,
                               previousNode, nextNode);


      if (this.firstChild === refWrapper)
        this.firstChild_ = nodes[0];

      // insertBefore refWrapper no matter what the parent is?
      var refNode = unwrap(refWrapper);
      var parentNode = refNode.parentNode;
      if (parentNode) {
        originalInsertBefore.call(
            parentNode,
            unwrapNodesForInsertion(nodes),
            refNode);
      }

      return childWrapper;
    },

    removeChild: function(childWrapper) {
      assertIsNodeWrapper(childWrapper);
      if (childWrapper.parentNode !== this) {
        // TODO(arv): DOMException
        throw new Error('NotFoundError');
      }

      this.invalidateShadowRenderer();

      // We need to remove the real node from the DOM before updating the
      // pointers. This is so that that mutation event is dispatched before
      // the pointers have changed.
      var thisFirstChild = this.firstChild;
      var thisLastChild = this.lastChild;
      var childWrapperNextSibling = childWrapper.nextSibling;
      var childWrapperPreviousSibling = childWrapper.previousSibling;

      var childNode = unwrap(childWrapper);
      var parentNode = childNode.parentNode;
      if (parentNode)
        originalRemoveChild.call(parentNode, childNode);

      if (thisFirstChild === childWrapper)
        this.firstChild_ = childWrapperNextSibling;
      if (thisLastChild === childWrapper)
        this.lastChild_ = childWrapperPreviousSibling;
      if (childWrapperPreviousSibling)
        childWrapperPreviousSibling.nextSibling_ = childWrapperNextSibling;
      if (childWrapperNextSibling)
        childWrapperNextSibling.previousSibling_ = childWrapperPreviousSibling;

      childWrapper.previousSibling_ = childWrapper.nextSibling_ = childWrapper.parentNode_ = null;

      return childWrapper;
    },

    replaceChild: function(newChildWrapper, oldChildWrapper) {
      assertIsNodeWrapper(newChildWrapper);
      assertIsNodeWrapper(oldChildWrapper);

      if (oldChildWrapper.parentNode !== this) {
        // TODO(arv): DOMException
        throw new Error('NotFoundError');
      }

      this.invalidateShadowRenderer();

      var previousNode = oldChildWrapper.previousSibling;
      var nextNode = oldChildWrapper.nextSibling;
      if (nextNode === newChildWrapper)
        nextNode = newChildWrapper.nextSibling;
      var nodes = collectNodes(newChildWrapper, this,
                               previousNode, nextNode);

      if (this.firstChild === oldChildWrapper)
        this.firstChild_ = nodes[0];
      if (this.lastChild === oldChildWrapper)
        this.lastChild_ = nodes[nodes.length - 1];

      oldChildWrapper.previousSibling_ = null;
      oldChildWrapper.nextSibling_ = null;
      oldChildWrapper.parentNode_ = null;

      // replaceChild no matter what the parent is?
      var oldChildNode = unwrap(oldChildWrapper);
      if (oldChildNode.parentNode) {
        originalReplaceChild.call(
            oldChildNode.parentNode,
            unwrapNodesForInsertion(nodes),
            oldChildNode);
      }

      return oldChildWrapper;
    },

    hasChildNodes: function() {
      return this.firstChild === null;
    },

    /** @type {Node} */
    get parentNode() {
      // If the parentNode has not been overridden, use the original parentNode.
      return this.parentNode_ !== undefined ?
          this.parentNode_ : wrap(this.impl.parentNode);
    },

    /** @type {Node} */
    get firstChild() {
      return this.firstChild_ !== undefined ?
          this.firstChild_ : wrap(this.impl.firstChild);
    },

    /** @type {Node} */
    get lastChild() {
      return this.lastChild_ !== undefined ?
          this.lastChild_ : wrap(this.impl.lastChild);
    },

    /** @type {Node} */
    get nextSibling() {
      return this.nextSibling_ !== undefined ?
          this.nextSibling_ : wrap(this.impl.nextSibling);
    },

    /** @type {Node} */
    get previousSibling() {
      return this.previousSibling_ !== undefined ?
          this.previousSibling_ : wrap(this.impl.previousSibling);
    },

    get parentElement() {
      var p = this.parentNode;
      while (p && p.nodeType !== Node.ELEMENT_NODE) {
        p = p.parentNode;
      }
      return p;
    },

    get textContent() {
      // TODO(arv): This should fallback to this.impl.textContent if there
      // are no shadow trees below or above the context node.
      var s = '';
      for (var child = this.firstChild; child; child = child.nextSibling) {
        s += child.textContent;
      }
      return s;
    },
    set textContent(textContent) {
      removeAllChildNodes(this);
      this.invalidateShadowRenderer();
      if (textContent !== '') {
        var textNode = this.impl.ownerDocument.createTextNode(textContent);
        this.appendChild(textNode);
      }
    },

    get childNodes() {
      var wrapperList = new NodeList();
      var i = 0;
      for (var child = this.firstChild; child; child = child.nextSibling) {
        wrapperList[i++] = child;
      }
      wrapperList.length = i;
      return wrapperList;
    },

    cloneNode: function(deep) {
      if (!this.invalidateShadowRenderer())
        return wrap(this.impl.cloneNode(deep));

      var clone = wrap(this.impl.cloneNode(false));
      if (deep) {
        for (var child = this.firstChild; child; child = child.nextSibling) {
          clone.appendChild(child.cloneNode(true));
        }
      }
      // TODO(arv): Some HTML elements also clone other data like value.
      return clone;
    },

    // insertionParent is added in ShadowRender.js

    contains: function(child) {
      if (!child)
        return false;

      // TODO(arv): Optimize using ownerDocument etc.
      if (child === this)
        return true;
      var parentNode = child.parentNode;
      if (!parentNode)
        return false;
      return this.contains(parentNode);
    },

    compareDocumentPosition: function(otherNode) {
      // This only wraps, it therefore only operates on the composed DOM and not
      // the logical DOM.
      return originalCompareDocumentPosition.call(this.impl, unwrap(otherNode));
    },

    // TODO(jmesserly): this is a workaround for
    // https://github.com/Polymer/ShadowDOM/issues/200
    get ownerDocument() {
      scope.renderAllPending();
      return wrap(this.impl.ownerDocument);
    }
  });

  // TODO(jmesserly): this is commented out to workaround:
  // https://github.com/Polymer/ShadowDOM/issues/200
  //defineWrapGetter(Node, 'ownerDocument');

  // We use a DocumentFragment as a base and then delete the properties of
  // DocumentFragment.prototype from the wrapper Node. Since delete makes
  // objects slow in some JS engines we recreate the prototype object.
  registerWrapper(OriginalNode, Node, document.createDocumentFragment());
  delete Node.prototype.querySelector;
  delete Node.prototype.querySelectorAll;
  Node.prototype = mixin(Object.create(EventTarget.prototype), Node.prototype);

  scope.wrappers.Node = Node;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  function findOne(node, selector) {
    var m, el = node.firstElementChild;
    while (el) {
      if (el.matches(selector))
        return el;
      m = findOne(el, selector);
      if (m)
        return m;
      el = el.nextElementSibling;
    }
    return null;
  }

  function findAll(node, selector, results) {
    var el = node.firstElementChild;
    while (el) {
      if (el.matches(selector))
        results[results.length++] = el;
      findAll(el, selector, results);
      el = el.nextElementSibling;
    }
    return results;
  }

  // find and findAll will only match Simple Selectors,
  // Structural Pseudo Classes are not guarenteed to be correct
  // http://www.w3.org/TR/css3-selectors/#simple-selectors

  var SelectorsInterface = {
    querySelector: function(selector) {
      return findOne(this, selector);
    },
    querySelectorAll: function(selector) {
      return findAll(this, selector, new NodeList())
    }
  };

  var GetElementsByInterface = {
    getElementsByTagName: function(tagName) {
      // TODO(arv): Check tagName?
      return this.querySelectorAll(tagName);
    },
    getElementsByClassName: function(className) {
      // TODO(arv): Check className?
      return this.querySelectorAll('.' + className);
    },
    getElementsByTagNameNS: function(ns, tagName) {
      if (ns === '*')
        return this.getElementsByTagName(tagName);

      // TODO(arv): Check tagName?
      var result = new NodeList;
      var els = this.getElementsByTagName(tagName);
      for (var i = 0, j = 0; i < els.length; i++) {
        if (els[i].namespaceURI === ns)
          result[j++] = els[i];
      }
      result.length = j;
      return result;
    }
  };

  scope.GetElementsByInterface = GetElementsByInterface;
  scope.SelectorsInterface = SelectorsInterface;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var NodeList = scope.wrappers.NodeList;

  function forwardElement(node) {
    while (node && node.nodeType !== Node.ELEMENT_NODE) {
      node = node.nextSibling;
    }
    return node;
  }

  function backwardsElement(node) {
    while (node && node.nodeType !== Node.ELEMENT_NODE) {
      node = node.previousSibling;
    }
    return node;
  }

  var ParentNodeInterface = {
    get firstElementChild() {
      return forwardElement(this.firstChild);
    },

    get lastElementChild() {
      return backwardsElement(this.lastChild);
    },

    get childElementCount() {
      var count = 0;
      for (var child = this.firstElementChild;
           child;
           child = child.nextElementSibling) {
        count++;
      }
      return count;
    },

    get children() {
      var wrapperList = new NodeList();
      var i = 0;
      for (var child = this.firstElementChild;
           child;
           child = child.nextElementSibling) {
        wrapperList[i++] = child;
      }
      wrapperList.length = i;
      return wrapperList;
    }
  };

  var ChildNodeInterface = {
    get nextElementSibling() {
      return forwardElement(this.nextSibling);
    },

    get previousElementSibling() {
      return backwardsElement(this.nextSibling);
    }
  };

  scope.ChildNodeInterface = ChildNodeInterface;
  scope.ParentNodeInterface = ParentNodeInterface;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var ChildNodeInterface = scope.ChildNodeInterface;
  var Node = scope.wrappers.Node;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;

  var OriginalCharacterData = window.CharacterData;

  function CharacterData(node) {
    Node.call(this, node);
  }
  CharacterData.prototype = Object.create(Node.prototype);
  mixin(CharacterData.prototype, {
    get textContent() {
      return this.data;
    },
    set textContent(value) {
      this.data = value;
    }
  });

  mixin(CharacterData.prototype, ChildNodeInterface);

  registerWrapper(OriginalCharacterData, CharacterData,
                  document.createTextNode(''));

  scope.wrappers.CharacterData = CharacterData;
})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var ChildNodeInterface = scope.ChildNodeInterface;
  var GetElementsByInterface = scope.GetElementsByInterface;
  var Node = scope.wrappers.Node;
  var ParentNodeInterface = scope.ParentNodeInterface;
  var SelectorsInterface = scope.SelectorsInterface;
  var addWrapNodeListMethod = scope.addWrapNodeListMethod;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var wrappers = scope.wrappers;

  var shadowRootTable = new SideTable();
  var OriginalElement = window.Element;

  var originalMatches =
      OriginalElement.prototype.matches ||
      OriginalElement.prototype.mozMatchesSelector ||
      OriginalElement.prototype.msMatchesSelector ||
      OriginalElement.prototype.webkitMatchesSelector;

  function Element(node) {
    Node.call(this, node);
  }
  Element.prototype = Object.create(Node.prototype);
  mixin(Element.prototype, {
    createShadowRoot: function() {
      var newShadowRoot = new wrappers.ShadowRoot(this);
      shadowRootTable.set(this, newShadowRoot);

      scope.getRendererForHost(this);

      this.invalidateShadowRenderer(true);

      return newShadowRoot;
    },

    get shadowRoot() {
      return shadowRootTable.get(this) || null;
    },

    setAttribute: function(name, value) {
      this.impl.setAttribute(name, value);
      // This is a bit agressive. We need to invalidate if it affects
      // the rendering content[select] or if it effects the value of a content
      // select.
      this.invalidateShadowRenderer();
    },

    matches: function(selector) {
      return originalMatches.call(this.impl, selector);
    }
  });

  mixin(Element.prototype, ChildNodeInterface);
  mixin(Element.prototype, GetElementsByInterface);
  mixin(Element.prototype, ParentNodeInterface);
  mixin(Element.prototype, SelectorsInterface);

  registerWrapper(OriginalElement, Element);

  scope.wrappers.Element = Element;
})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var Element = scope.wrappers.Element;
  var defineGetter = scope.defineGetter;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;

  /////////////////////////////////////////////////////////////////////////////
  // innerHTML and outerHTML

  var escapeRegExp = /&|<|"/g;

  function escapeReplace(c) {
    switch (c) {
      case '&':
        return '&amp;';
      case '<':
        return '&lt;';
      case '"':
        return '&quot;'
    }
  }

  function escape(s) {
    return s.replace(escapeRegExp, escapeReplace);
  }

  // http://www.whatwg.org/specs/web-apps/current-work/#void-elements
  var voidElements = {
    'area': true,
    'base': true,
    'br': true,
    'col': true,
    'command': true,
    'embed': true,
    'hr': true,
    'img': true,
    'input': true,
    'keygen': true,
    'link': true,
    'meta': true,
    'param': true,
    'source': true,
    'track': true,
    'wbr': true
  };

  function getOuterHTML(node) {
    switch (node.nodeType) {
      case Node.ELEMENT_NODE:
        var tagName = node.tagName.toLowerCase();
        var s = '<' + tagName;
        var attrs = node.attributes;
        for (var i = 0, attr; attr = attrs[i]; i++) {
          s += ' ' + attr.name + '="' + escape(attr.value) + '"';
        }
        s += '>';
        if (voidElements[tagName])
          return s;

        return s + getInnerHTML(node) + '</' + tagName + '>';

      case Node.TEXT_NODE:
        return escape(node.nodeValue);

      case Node.COMMENT_NODE:
        return '<!--' + escape(node.nodeValue) + '-->';
      default:
        console.error(node);
        throw new Error('not implemented');
    }
  }

  function getInnerHTML(node) {
    var s = '';
    for (var child = node.firstChild; child; child = child.nextSibling) {
      s += getOuterHTML(child);
    }
    return s;
  }

  function setInnerHTML(node, value, opt_tagName) {
    var tagName = opt_tagName || 'div';
    node.textContent = '';
    var tempElement =unwrap(node.ownerDocument.createElement(tagName));
    tempElement.innerHTML = value;
    var firstChild;
    while (firstChild = tempElement.firstChild) {
      node.appendChild(wrap(firstChild));
    }
  }

  var OriginalHTMLElement = window.HTMLElement;

  function HTMLElement(node) {
    Element.call(this, node);
  }
  HTMLElement.prototype = Object.create(Element.prototype);
  mixin(HTMLElement.prototype, {
    get innerHTML() {
      // TODO(arv): This should fallback to this.impl.innerHTML if there
      // are no shadow trees below or above the context node.
      return getInnerHTML(this);
    },
    set innerHTML(value) {
      setInnerHTML(this, value, this.tagName);
    },

    get outerHTML() {
      // TODO(arv): This should fallback to HTMLElement_prototype.outerHTML if there
      // are no shadow trees below or above the context node.
      return getOuterHTML(this);
    },
    set outerHTML(value) {
      if (!this.invalidateShadowRenderer()) {
        this.impl.outerHTML = value;
      } else {
        throw new Error('not implemented');
      }
    }
  });

  function getterRequiresRendering(name) {
    defineGetter(HTMLElement, name, function() {
      scope.renderAllPending();
      return this.impl[name];
     });
  }

  [
    'clientHeight',
    'clientLeft',
    'clientTop',
    'clientWidth',
    'offsetHeight',
    'offsetLeft',
    'offsetTop',
    'offsetWidth',
    'scrollHeight',
    'scrollLeft',
    'scrollTop',
    'scrollWidth',
  ].forEach(getterRequiresRendering);

  function methodRequiresRendering(name) {
    Object.defineProperty(HTMLElement.prototype, name, {
      value: function() {
        scope.renderAllPending();
        return this.impl[name].apply(this.impl, arguments);
      },
      configurable: true,
      enumerable: true
    });
  }

  [
    'getBoundingClientRect',
    'getClientRects',
    'scrollIntoView'
  ].forEach(methodRequiresRendering);

  // HTMLElement is abstract so we use a subclass that has no members.
  registerWrapper(OriginalHTMLElement, HTMLElement,
                  document.createElement('b'));

  scope.wrappers.HTMLElement = HTMLElement;

  // TODO: Find a better way to share these two with WrapperShadowRoot.
  scope.getInnerHTML = getInnerHTML;
  scope.setInnerHTML = setInnerHTML
})(this.ShadowDOMPolyfill);
// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;

  var OriginalHTMLContentElement = window.HTMLContentElement;

  function HTMLContentElement(node) {
    HTMLElement.call(this, node);
  }
  HTMLContentElement.prototype = Object.create(HTMLElement.prototype);
  mixin(HTMLContentElement.prototype, {
    get select() {
      return this.getAttribute('select');
    },
    set select(value) {
      this.setAttribute('select', value);
    },

    setAttribute: function(n, v) {
      HTMLElement.prototype.setAttribute.call(this, n, v);
      if (String(n).toLowerCase() === 'select')
        this.invalidateShadowRenderer(true);
    }

    // getDistributedNodes is added in ShadowRenderer

    // TODO: attribute boolean resetStyleInheritance;
  });

  if (OriginalHTMLContentElement)
    registerWrapper(OriginalHTMLContentElement, HTMLContentElement);

  scope.wrappers.HTMLContentElement = HTMLContentElement;
})(this.ShadowDOMPolyfill);
// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;

  var OriginalHTMLShadowElement = window.HTMLShadowElement;

  function HTMLShadowElement(node) {
    HTMLElement.call(this, node);
    this.olderShadowRoot_ = null;
  }
  HTMLShadowElement.prototype = Object.create(HTMLElement.prototype);
  mixin(HTMLShadowElement.prototype, {
    get olderShadowRoot() {
      return this.olderShadowRoot_;
    },

    invalidateShadowRenderer: function() {
      HTMLElement.prototype.invalidateShadowRenderer.call(this, true);
    },

    // TODO: attribute boolean resetStyleInheritance;
  });

  if (OriginalHTMLShadowElement)
    registerWrapper(OriginalHTMLShadowElement, HTMLShadowElement);

  scope.wrappers.HTMLShadowElement = HTMLShadowElement;
})(this.ShadowDOMPolyfill);
// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var getInnerHTML = scope.getInnerHTML;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var setInnerHTML = scope.setInnerHTML;
  var wrap = scope.wrap;

  var contentTable = new SideTable();
  var templateContentsOwnerTable = new SideTable();

  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#dfn-template-contents-owner
  function getTemplateContentsOwner(doc) {
    if (!doc.defaultView)
      return doc;
    var d = templateContentsOwnerTable.get(doc);
    if (!d) {
      // TODO(arv): This should either be a Document or HTMLDocument depending
      // on doc.
      d = doc.implementation.createHTMLDocument('');
      while (d.lastChild) {
        d.removeChild(d.lastChild);
      }
      templateContentsOwnerTable.set(doc, d);
    }
    return d;
  }

  function extractContent(templateElement) {
    var doc = getTemplateContentsOwner(templateElement.ownerDocument);
    var df = doc.createDocumentFragment();
    var nextSibling;
    var child;
    while (child = templateElement.firstChild) {
      df.appendChild(child);
    }
    return df;
  }

  var OriginalHTMLTemplateElement = window.HTMLTemplateElement;

  function HTMLTemplateElement(node) {
    HTMLElement.call(this, node);
  }
  HTMLTemplateElement.prototype = Object.create(HTMLElement.prototype);

  mixin(HTMLTemplateElement.prototype, {
    get content() {
      if (OriginalHTMLTemplateElement)
        return wrap(this.impl.content);

      // TODO(arv): This should be done in createCallback. I initially tried to
      // do this in the constructor but the wrapper is not yet created at that
      // point in time so we hit an iloop.
      var content = contentTable.get(this);
      if (!content) {
        content = extractContent(this);
        contentTable.set(this, content);
      }
      return content;
    },

    get innerHTML() {
      return getInnerHTML(this.content);
    },
    set innerHTML(value) {
      setInnerHTML(this.content, value);
      this.invalidateShadowRenderer();
    }

    // TODO(arv): cloneNode needs to clone content.

  });

  if (OriginalHTMLTemplateElement)
    registerWrapper(OriginalHTMLTemplateElement, HTMLTemplateElement);

  scope.wrappers.HTMLTemplateElement = HTMLTemplateElement;
})(this.ShadowDOMPolyfill);
// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLContentElement = scope.wrappers.HTMLContentElement;
  var HTMLElement = scope.wrappers.HTMLElement;
  var HTMLShadowElement = scope.wrappers.HTMLShadowElement;
  var HTMLTemplateElement = scope.wrappers.HTMLTemplateElement;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;

  var OriginalHTMLUnknownElement = window.HTMLUnknownElement;

  function HTMLUnknownElement(node) {
    switch (node.localName) {
      case 'content':
        return new HTMLContentElement(node);
      case 'shadow':
        return new HTMLShadowElement(node);
      case 'template':
        return new HTMLTemplateElement(node);
    }
    HTMLElement.call(this, node);
  }
  HTMLUnknownElement.prototype = Object.create(HTMLElement.prototype);
  registerWrapper(OriginalHTMLUnknownElement, HTMLUnknownElement);
  scope.wrappers.HTMLUnknownElement = HTMLUnknownElement;
})(this.ShadowDOMPolyfill);
// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var GetElementsByInterface = scope.GetElementsByInterface;
  var ParentNodeInterface = scope.ParentNodeInterface;
  var SelectorsInterface = scope.SelectorsInterface;
  var mixin = scope.mixin;
  var registerObject = scope.registerObject;

  var DocumentFragment = registerObject(document.createDocumentFragment());
  mixin(DocumentFragment.prototype, ParentNodeInterface);
  mixin(DocumentFragment.prototype, SelectorsInterface);
  mixin(DocumentFragment.prototype, GetElementsByInterface);

  var Text = registerObject(document.createTextNode(''));
  var Comment = registerObject(document.createComment(''));

  scope.wrappers.Comment = Comment;
  scope.wrappers.DocumentFragment = DocumentFragment;
  scope.wrappers.Text = Text;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var DocumentFragment = scope.wrappers.DocumentFragment;
  var elementFromPoint = scope.elementFromPoint;
  var getInnerHTML = scope.getInnerHTML;
  var mixin = scope.mixin;
  var rewrap = scope.rewrap;
  var setInnerHTML = scope.setInnerHTML;
  var unwrap = scope.unwrap;

  var shadowHostTable = new SideTable();

  function ShadowRoot(hostWrapper) {
    var node = unwrap(hostWrapper.impl.ownerDocument.createDocumentFragment());
    DocumentFragment.call(this, node);

    // createDocumentFragment associates the node with a wrapper
    // DocumentFragment instance. Override that.
    rewrap(node, this);

    var oldShadowRoot = hostWrapper.shadowRoot;
    scope.nextOlderShadowTreeTable.set(this, oldShadowRoot);

    shadowHostTable.set(this, hostWrapper);
  }
  ShadowRoot.prototype = Object.create(DocumentFragment.prototype);
  mixin(ShadowRoot.prototype, {
    get innerHTML() {
      return getInnerHTML(this);
    },
    set innerHTML(value) {
      setInnerHTML(this, value);
      this.invalidateShadowRenderer();
    },

    invalidateShadowRenderer: function() {
      return shadowHostTable.get(this).invalidateShadowRenderer();
    },

    elementFromPoint: function(x, y) {
      return elementFromPoint(this, this.ownerDocument, x, y);
    },

    getElementById: function(id) {
      return this.querySelector('#' + id);
    }
  });

  scope.wrappers.ShadowRoot = ShadowRoot;
  scope.getHostForShadowRoot = function(node) {
    return shadowHostTable.get(node);
  };
})(this.ShadowDOMPolyfill);
// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLContentElement = scope.wrappers.HTMLContentElement;
  var Node = scope.wrappers.Node;
  var assert = scope.assert;
  var mixin = scope.mixin;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;

  /**
   * Updates the fields of a wrapper to a snapshot of the logical DOM as needed.
   * Up means parentNode
   * Sideways means previous and next sibling.
   * @param {!Node} wrapper
   */
  function updateWrapperUpAndSideways(wrapper) {
    wrapper.previousSibling_ = wrapper.previousSibling;
    wrapper.nextSibling_ = wrapper.nextSibling;
    wrapper.parentNode_ = wrapper.parentNode;
  }

  /**
   * Updates the fields of a wrapper to a snapshot of the logical DOM as needed.
   * Down means first and last child
   * @param {!Node} wrapper
   */
  function updateWrapperDown(wrapper) {
    wrapper.firstChild_ = wrapper.firstChild;
    wrapper.lastChild_ = wrapper.lastChild;
  }

  function updateAllChildNodes(parentNodeWrapper) {
    assert(parentNodeWrapper instanceof Node);
    for (var childWrapper = parentNodeWrapper.firstChild;
         childWrapper;
         childWrapper = childWrapper.nextSibling) {
      updateWrapperUpAndSideways(childWrapper);
    }
    updateWrapperDown(parentNodeWrapper);
  }

  // This object groups DOM operations. This is supposed to be the DOM as the
  // browser/render tree sees it.
  // When changes are done to the visual DOM the logical DOM needs to be updated
  // to reflect the correct tree.
  function removeAllChildNodes(parentNodeWrapper) {
    var parentNode = unwrap(parentNodeWrapper);
    updateAllChildNodes(parentNodeWrapper);
    parentNode.textContent = '';
  }

  function appendChild(parentNodeWrapper, childWrapper) {
    var parentNode = unwrap(parentNodeWrapper);
    var child = unwrap(childWrapper);
    if (child.nodeType === Node.DOCUMENT_FRAGMENT_NODE) {
      updateAllChildNodes(childWrapper);

    } else {
      remove(childWrapper);
      updateWrapperUpAndSideways(childWrapper);
    }

    parentNodeWrapper.lastChild_ = parentNodeWrapper.lastChild;
    if (parentNodeWrapper.lastChild === parentNodeWrapper.firstChild)
      parentNodeWrapper.firstChild_ = parentNodeWrapper.firstChild;

    var lastChildWrapper = wrap(parentNode.lastChild);
    if (lastChildWrapper) {
      lastChildWrapper.nextSibling_ = lastChildWrapper.nextSibling;
    }

    parentNode.appendChild(child);
  }

  function removeChild(parentNodeWrapper, childWrapper) {
    var parentNode = unwrap(parentNodeWrapper);
    var child = unwrap(childWrapper);

    updateWrapperUpAndSideways(childWrapper);

    if (childWrapper.previousSibling)
      childWrapper.previousSibling.nextSibling_ = childWrapper;
    if (childWrapper.nextSibling)
      childWrapper.nextSibling.previousSibling_ = childWrapper;

    if (parentNodeWrapper.lastChild === childWrapper)
      parentNodeWrapper.lastChild_ = childWrapper;
    if (parentNodeWrapper.firstChild === childWrapper)
      parentNodeWrapper.firstChild_ = childWrapper;

    parentNode.removeChild(child);
  }

  function remove(nodeWrapper) {
    var node = unwrap(nodeWrapper)
    var parentNode = node.parentNode;
    if (parentNode)
      removeChild(wrap(parentNode), nodeWrapper);
  }

  var distributedChildNodesTable = new SideTable();
  var eventParentsTable = new SideTable();
  var insertionParentTable = new SideTable();
  var nextOlderShadowTreeTable = new SideTable();
  var rendererForHostTable = new SideTable();
  var shadowDOMRendererTable = new SideTable();

  var reprCounter = 0;

  function repr(node) {
    if (!node.displayName)
      node.displayName = node.nodeName + '-' + ++reprCounter;
    return node.displayName;
  }

  function distributeChildToInsertionPoint(child, insertionPoint) {
    getDistributedChildNodes(insertionPoint).push(child);
    insertionParentTable.set(child, insertionPoint);

    var eventParents = eventParentsTable.get(child);
    if (!eventParents)
      eventParentsTable.set(child, eventParents = []);
    eventParents.push(insertionPoint);
  }

  function resetDistributedChildNodes(insertionPoint) {
    distributedChildNodesTable.set(insertionPoint, []);
  }

  function getDistributedChildNodes(insertionPoint) {
    return distributedChildNodesTable.get(insertionPoint);
  }

  function getChildNodesSnapshot(node) {
    var result = [], i = 0;
    for (var child = node.firstChild; child; child = child.nextSibling) {
      result[i++] = child;
    }
    return result;
  }

  /**
   * Visits all nodes in the tree that fulfils the |predicate|. If the |visitor|
   * function returns |false| the traversal is aborted.
   * @param {!Node} tree
   * @param {function(!Node) : boolean} predicate
   * @param {function(!Node) : *} visitor
   */
  function visit(tree, predicate, visitor) {
    // This operates on logical DOM.
    var nodes = getChildNodesSnapshot(tree);
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (predicate(node)) {
        if (visitor(node) === false)
          return;
      } else {
        visit(node, predicate, visitor);
      }
    }
  }

  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#dfn-distribution-algorithm
  function distribute(tree, pool) {
    var anyRemoved = false;

    visit(tree, isActiveInsertionPoint,
        function(insertionPoint) {
          resetDistributedChildNodes(insertionPoint);
          for (var i = 0; i < pool.length; i++) {  // 1.2
            var node = pool[i];  // 1.2.1
            if (node === undefined)  // removed
              continue;
            if (matchesCriteria(node, insertionPoint)) {  // 1.2.2
              distributeChildToInsertionPoint(node, insertionPoint);  // 1.2.2.1
              pool[i] = undefined;  // 1.2.2.2
              anyRemoved = true;
            }
          }
        });

    if (!anyRemoved)
      return pool;

    return pool.filter(function(item) {
      return item !== undefined;
    });
  }

  // Matching Insertion Points
  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#matching-insertion-points

  // TODO(arv): Verify this... I don't remember why I picked this regexp.
  var selectorMatchRegExp = /^[*.:#[a-zA-Z_|]/;

  var allowedPseudoRegExp = new RegExp('^:(' + [
    'link',
    'visited',
    'target',
    'enabled',
    'disabled',
    'checked',
    'indeterminate',
    'nth-child',
    'nth-last-child',
    'nth-of-type',
    'nth-last-of-type',
    'first-child',
    'last-child',
    'first-of-type',
    'last-of-type',
    'only-of-type',
  ].join('|') + ')');


  function oneOf(object, propertyNames) {
    for (var i = 0; i < propertyNames.length; i++) {
      if (propertyNames[i] in object)
        return propertyNames[i];
    }
  }

  /**
   * @param {Element} node
   * @oaram {Element} point The insertion point element.
   * @return {boolean} Whether the node matches the insertion point.
   */
  function matchesCriteria(node, point) {
    var select = point.getAttribute('select');
    if (!select)
      return true;

    // Here we know the select attribute is a non empty string.
    select = select.trim();
    if (!select)
      return true;

    if (node.nodeType !== Node.ELEMENT_NODE)
      return false;

    // TODO(arv): This does not seem right. Need to check for a simple selector.
    if (!selectorMatchRegExp.test(select))
      return false;

    if (select[0] === ':' &&!allowedPseudoRegExp.test(select))
      return false;

    try {
      return node.matches(select);
    } catch (ex) {
      // Invalid selector.
      return false;
    }
  }

  var request = oneOf(window, [
    'requestAnimationFrame',
    'mozRequestAnimationFrame',
    'webkitRequestAnimationFrame',
    'setTimeout'
  ]);

  var pendingDirtyRenderers = [];
  var renderTimer;

  function renderAllPending() {
    renderTimer = null;
    pendingDirtyRenderers.forEach(function(owner) {
      owner.render();
    });
    pendingDirtyRenderers = [];
  }

  function ShadowRenderer(host) {
    this.host = host;
    this.dirty = false;
    this.associateNode(host);
  }

  function getRendererForHost(host) {
    var renderer = rendererForHostTable.get(host);
    if (!renderer) {
      renderer = new ShadowRenderer(host);
      rendererForHostTable.set(host, renderer);
    }
    return renderer;
  }

  ShadowRenderer.prototype = {
    // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#rendering-shadow-trees
    render: function() {
      if (!this.dirty)
        return;

      var host = this.host;
      this.treeComposition();
      var shadowDOM = host.shadowRoot;
      if (!shadowDOM)
        return;

      this.removeAllChildNodes(this.host);

      var shadowDOMChildNodes = getChildNodesSnapshot(shadowDOM);
      shadowDOMChildNodes.forEach(function(node) {
        this.renderNode(host, shadowDOM, node, false);
      }, this);

      this.dirty = false;
    },

    invalidate: function() {
      if (!this.dirty) {
        this.dirty = true;
        pendingDirtyRenderers.push(this);
        if (renderTimer)
          return;
        renderTimer = window[request](renderAllPending, 0);
      }
    },

    renderNode: function(visualParent, tree, node, isNested) {
      if (isShadowHost(node)) {
        this.appendChild(visualParent, node);
        var renderer = getRendererForHost(node);
        renderer.dirty = true;  // Need to rerender due to reprojection.
        renderer.render();
      } else if (isInsertionPoint(node)) {
        this.renderInsertionPoint(visualParent, tree, node, isNested);
      } else if (isShadowInsertionPoint(node)) {
        this.renderShadowInsertionPoint(visualParent, tree, node);
      } else {
        this.renderAsAnyDomTree(visualParent, tree, node, isNested);
      }
    },

    renderAsAnyDomTree: function(visualParent, tree, child, isNested) {
      this.appendChild(visualParent, child);

      if (isShadowHost(child)) {
        render(child);
      } else {
        var parent = child;
        var logicalChildNodes = getChildNodesSnapshot(parent);
        logicalChildNodes.forEach(function(node) {
          this.renderNode(parent, tree, node, isNested);
        }, this);
      }
    },

    renderInsertionPoint: function(visualParent, tree, insertionPoint, isNested) {
      var distributedChildNodes = getDistributedChildNodes(insertionPoint);
      if (distributedChildNodes.length) {
        this.removeAllChildNodes(insertionPoint);

        distributedChildNodes.forEach(function(child) {
          if (isInsertionPoint(child) && isNested)
            this.renderInsertionPoint(visualParent, tree, child, isNested);
          else
            this.renderAsAnyDomTree(visualParent, tree, child, isNested);
        }, this);
      } else {
        this.renderFallbackContent(visualParent, insertionPoint);
      }
      this.remove(insertionPoint);
    },

    renderShadowInsertionPoint: function(visualParent, tree, shadowInsertionPoint) {
      var nextOlderTree = getNextOlderTree(tree);
      if (nextOlderTree) {
        // This makes ShadowRoot have its insertionParent be the <shadow>.
        insertionParentTable.set(nextOlderTree, shadowInsertionPoint);
        shadowInsertionPoint.olderShadowRoot_ = nextOlderTree;
        this.remove(shadowInsertionPoint);
        var shadowDOMChildNodes = getChildNodesSnapshot(nextOlderTree);
        shadowDOMChildNodes.forEach(function(node) {
          this.renderNode(visualParent, nextOlderTree, node, true);
        }, this);
      } else {
        this.renderFallbackContent(visualParent, shadowInsertionPoint);
      }
    },

    renderFallbackContent: function (visualParent, fallbackHost) {
      var logicalChildNodes = getChildNodesSnapshot(fallbackHost);
      logicalChildNodes.forEach(function(node) {
        this.appendChild(visualParent, node);
      }, this);
    },

    // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#dfn-tree-composition
    treeComposition: function () {
      var shadowHost = this.host;
      var tree = shadowHost.shadowRoot;  // 1.
      var pool = [];  // 2.
      var shadowHostChildNodes = getChildNodesSnapshot(shadowHost);
      shadowHostChildNodes.forEach(function(child) {  // 3.
        if (isInsertionPoint(child)) {  // 3.2.
          var reprojected = getDistributedChildNodes(child);  // 3.2.1.
          // if reprojected is undef... reset it?
          if (!reprojected || !reprojected.length)  // 3.2.2.
            reprojected = getChildNodesSnapshot(child);
          pool.push.apply(pool, reprojected);  // 3.2.3.
        } else {
          pool.push(child); // 3.3.
        }
      });

      var shadowInsertionPoint, point;
      while (tree) {  // 4.
        // 4.1.
        shadowInsertionPoint = undefined;  // Reset every iteration.
        visit(tree, isActiveShadowInsertionPoint, function(point) {
          shadowInsertionPoint = point;
          return false;
        });
        point = shadowInsertionPoint;

        pool = distribute(tree, pool);  // 4.2.
        if (point) {  // 4.3.
          var nextOlderTree = getNextOlderTree(tree);  // 4.3.1.
          if (!nextOlderTree) {
            break;  // 4.3.1.1.
          } else {
            tree = nextOlderTree;  // 4.3.2.2.
            assignShadowTreeToShadowInsertionPoint(tree, point);  // 4.3.2.2.
            continue;  // 4.3.2.3.
          }
        } else {
          break;  // 4.4.
        }
      }
    },

    // Visual DOM mutation.
    appendChild: function(parent, child) {
      appendChild(parent, child);
      this.associateNode(child);
    },

    remove: function(node) {
      remove(node);
      this.associateNode(node);
    },

    removeAllChildNodes: function(parent) {
      removeAllChildNodes(parent);
      // TODO(arv): Does this need to associate all the nodes with this renderer?
    },

    associateNode: function(node) {
      // TODO: Clear when moved out of shadow tree.
      shadowDOMRendererTable.set(node, this);
    }
  };

  function isInsertionPoint(node) {
    // Should this include <shadow>?
    return node.localName === 'content';
  }

  function isActiveInsertionPoint(node) {
    // <content> inside another <content> or <shadow> is considered inactive.
    return node.localName === 'content';
  }

  function isShadowInsertionPoint(node) {
    return node.localName === 'shadow';
  }

  function isActiveShadowInsertionPoint(node) {
    // <shadow> inside another <content> or <shadow> is considered inactive.
    return node.localName === 'shadow';
  }

  function isShadowHost(shadowHost) {
    return !!shadowHost.shadowRoot;
  }

  /**
   * @param {WrapperShadowRoot} tree
   */
  function getNextOlderTree(tree) {
    return nextOlderShadowTreeTable.get(tree);
  }

  function getShadowTrees(host) {
    var trees = [];

    for (var tree = host.shadowRoot;
         tree;
         tree = nextOlderShadowTreeTable.get(tree)) {
      trees.push(tree);
    }
    return trees;
  }

  function assignShadowTreeToShadowInsertionPoint(tree, point) {
    insertionParentTable.set(tree, point);
  }

  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#rendering-shadow-trees
  function render(host) {
    new ShadowRenderer(host).render();
  };

  Node.prototype.invalidateShadowRenderer = function(force) {
    // TODO: If this is in light DOM we only need to invalidate renderer if this
    // is a direct child of a ShadowRoot.
    // Maybe we should only associate renderers with direct child nodes of a
    // shadow root (and all nodes in the shadow dom).
    var renderer = shadowDOMRendererTable.get(this);
    if (!renderer)
      return false;

    var p;
    if (force || this.shadowRoot ||
        (p = this.parentNode) && (p.shadowRoot || p instanceof ShadowRoot)) {
      renderer.invalidate();
    }

    return true;
  };

  HTMLContentElement.prototype.getDistributedNodes = function() {
    // TODO(arv): We should associate the element with the shadow root so we
    // only have to rerender this ShadowRenderer.
    renderAllPending();
    return getDistributedChildNodes(this);
  };

  mixin(Node.prototype, {
    get insertionParent() {
      return insertionParentTable.get(this) || null;
    }
  });

  scope.eventParentsTable = eventParentsTable;
  scope.getRendererForHost = getRendererForHost;
  scope.getShadowTrees = getShadowTrees;
  scope.nextOlderShadowTreeTable = nextOlderShadowTreeTable;
  scope.renderAllPending = renderAllPending;

  // Exposed for testing
  scope.visual = {
    removeAllChildNodes: removeAllChildNodes,
    appendChild: appendChild,
    removeChild: removeChild
  };

})(this.ShadowDOMPolyfill);
// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var GetElementsByInterface = scope.GetElementsByInterface;
  var Node = scope.wrappers.Node;
  var ParentNodeInterface = scope.ParentNodeInterface;
  var SelectorsInterface = scope.SelectorsInterface;
  var defineWrapGetter = scope.defineWrapGetter;
  var elementFromPoint = scope.elementFromPoint;
  var forwardMethodsToWrapper = scope.forwardMethodsToWrapper;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;
  var wrapEventTargetMethods = scope.wrapEventTargetMethods;
  var wrapNodeList = scope.wrapNodeList;

  var implementationTable = new SideTable();

  function Document(node) {
    Node.call(this, node);
  }
  Document.prototype = Object.create(Node.prototype);

  defineWrapGetter(Document, 'documentElement');

  // Conceptually both body and head can be in a shadow but suporting that seems
  // overkill at this point.
  defineWrapGetter(Document, 'body');
  defineWrapGetter(Document, 'head');

  // document cannot be overridden so we override a bunch of its methods
  // directly on the instance.

  function wrapMethod(name) {
    var original = document[name];
    Document.prototype[name] = function() {
      return wrap(original.apply(this.impl, arguments));
    };
  }

  [
    'getElementById',
    'createElement',
    'createElementNS',
    'createTextNode',
    'createDocumentFragment',
    'createEvent',
    'createEventNS',
  ].forEach(wrapMethod);

  var originalAdoptNode = document.adoptNode;
  var originalWrite = document.write;

  mixin(Document.prototype, {
    adoptNode: function(node) {
      originalAdoptNode.call(this.impl, unwrap(node));
      return node;
    },
    elementFromPoint: function(x, y) {
      return elementFromPoint(this, this, x, y);
    },
    write: function(s) {
      var all = this.querySelectorAll('*');
      var last = all[all.length - 1];
      while (last.nextSibling) {
        last = last.nextSibling;
      }
      var p = last.parentNode;
      p.lastChild_ = undefined;
      last.nextSibling_ = undefined;
      originalWrite.call(this.impl, s);
    }
  });

  // We also override some of the methods on document.body and document.head
  // for convenience.
  forwardMethodsToWrapper([
    window.HTMLBodyElement,
    window.HTMLDocument || window.Document,  // Gecko adds these to HTMLDocument
    window.HTMLHeadElement,
  ], [
    'appendChild',
    'compareDocumentPosition',
    'getElementsByClassName',
    'getElementsByTagName',
    'getElementsByTagNameNS',
    'insertBefore',
    'querySelector',
    'querySelectorAll',
    'removeChild',
    'replaceChild',
  ]);

  forwardMethodsToWrapper([
    window.HTMLDocument || window.Document,  // Gecko adds these to HTMLDocument
  ], [
    'adoptNode',
    'createDocumentFragment',
    'createElement',
    'createElementNS',
    'createEvent',
    'createEventNS',
    'createTextNode',
    'elementFromPoint',
    'getElementById',
    'write',
  ]);

  mixin(Document.prototype, GetElementsByInterface);
  mixin(Document.prototype, ParentNodeInterface);
  mixin(Document.prototype, SelectorsInterface);

  mixin(Document.prototype, {
    get implementation() {
      var implementation = implementationTable.get(this);
      if (implementation)
        return implementation;
      implementation =
          new DOMImplementation(unwrap(this).implementation);
      implementationTable.set(this, implementation);
      return implementation;
    }
  });

  registerWrapper(window.Document, Document,
      document.implementation.createHTMLDocument(''));

  // Both WebKit and Gecko uses HTMLDocument for document. HTML5/DOM only has
  // one Document interface and IE implements the standard correctly.
  if (window.HTMLDocument)
    registerWrapper(window.HTMLDocument, Document);

  wrapEventTargetMethods([
    window.HTMLBodyElement,
    window.HTMLDocument || window.Document,  // Gecko adds these to HTMLDocument
    window.HTMLHeadElement,
  ]);

  function DOMImplementation(impl) {
    this.impl = impl;
  }

  function wrapImplMethod(constructor, name) {
    var original = document.implementation[name];
    constructor.prototype[name] = function() {
      return wrap(original.apply(this.impl, arguments));
    };
  }

  function forwardImplMethod(constructor, name) {
    var original = document.implementation[name];
    constructor.prototype[name] = function() {
      return original.apply(this.impl, arguments);
    };
  }

  wrapImplMethod(DOMImplementation, 'createDocumentType');
  wrapImplMethod(DOMImplementation, 'createDocument');
  wrapImplMethod(DOMImplementation, 'createHTMLDocument');
  forwardImplMethod(DOMImplementation, 'hasFeature');

  registerWrapper(window.DOMImplementation, DOMImplementation);

  forwardMethodsToWrapper([
    window.DOMImplementation,
  ], [
    'createDocumentType',
    'createDocument',
    'createHTMLDocument',
    'hasFeature',
  ]);

  scope.wrappers.Document = Document;
  scope.wrappers.DOMImplementation = DOMImplementation;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var EventTarget = scope.wrappers.EventTarget;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var unwrapIfNeeded = scope.unwrapIfNeeded;
  var wrap = scope.wrap;

  var OriginalWindow = window.Window;

  function Window(impl) {
    EventTarget.call(this, impl);
  }
  Window.prototype = Object.create(EventTarget.prototype);

  var originalGetComputedStyle = window.getComputedStyle;
  OriginalWindow.prototype.getComputedStyle = function(el, pseudo) {
    return originalGetComputedStyle.call(this || window, unwrapIfNeeded(el),
                                         pseudo);
  };

  ['addEventListener', 'removeEventListener', 'dispatchEvent'].forEach(
      function(name) {
        OriginalWindow.prototype[name] = function() {
          var w = wrap(this || window);
          return w[name].apply(w, arguments);
        };
      });

  mixin(Window.prototype, {
    getComputedStyle: function(el, pseudo) {
      return originalGetComputedStyle.call(unwrap(this), unwrapIfNeeded(el),
                                           pseudo);
    }
  });

  registerWrapper(OriginalWindow, Window);

  scope.wrappers.Window = Window;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var defineGetter = scope.defineGetter;
  var defineWrapGetter = scope.defineWrapGetter;
  var registerWrapper = scope.registerWrapper;
  var unwrapIfNeeded = scope.unwrapIfNeeded;
  var wrapNodeList = scope.wrapNodeList;
  var wrappers = scope.wrappers;

  var OriginalMutationObserver = window.MutationObserver ||
      window.WebKitMutationObserver;

  if (!OriginalMutationObserver)
    return;

  var OriginalMutationRecord = window.MutationRecord;

  function MutationRecord(impl) {
    this.impl = impl;
  }

  MutationRecord.prototype = {
    get addedNodes() {
      return wrapNodeList(this.impl.addedNodes);
    },
    get removedNodes() {
      return wrapNodeList(this.impl.removedNodes);
    }
  };

  ['target', 'previousSibling', 'nextSibling'].forEach(function(name) {
    defineWrapGetter(MutationRecord, name);
  });

  // WebKit/Blink treats these as instance properties so we override
  [
    'type',
    'attributeName',
    'attributeNamespace',
    'oldValue'
  ].forEach(function(name) {
    defineGetter(MutationRecord, name, function() {
      return this.impl[name];
    });
  });

  if (OriginalMutationRecord)
    registerWrapper(OriginalMutationRecord, MutationRecord);

  function wrapRecord(record) {
    return new MutationRecord(record);
  }

  function wrapRecords(records) {
    return records.map(wrapRecord);
  }

  function MutationObserver(callback) {
    var self = this;
    this.impl = new OriginalMutationObserver(function(mutations, observer) {
      callback.call(self, wrapRecords(mutations), self);
    });
  }

  var OriginalNode = window.Node;

  MutationObserver.prototype = {
    observe: function(target, options) {
      this.impl.observe(unwrapIfNeeded(target), options);
    },
    disconnect: function() {
      this.impl.disconnect();
    },
    takeRecords: function() {
      return wrapRecords(this.impl.takeRecords());
    }
  };

  scope.wrappers.MutationObserver = MutationObserver;
  scope.wrappers.MutationRecord = MutationRecord;

})(this.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var isWrapperFor = scope.isWrapperFor;

  // This is a list of the elements we currently override the global constructor
  // for.
  var elements = {
    'a': 'HTMLAnchorElement',
    'applet': 'HTMLAppletElement',
    'area': 'HTMLAreaElement',
    'audio': 'HTMLAudioElement',
    'br': 'HTMLBRElement',
    'base': 'HTMLBaseElement',
    'body': 'HTMLBodyElement',
    'button': 'HTMLButtonElement',
    'canvas': 'HTMLCanvasElement',
    // 'command': 'HTMLCommandElement',  // Not fully implemented in Gecko.
    'dl': 'HTMLDListElement',
    'datalist': 'HTMLDataListElement',
    'dir': 'HTMLDirectoryElement',
    'div': 'HTMLDivElement',
    'embed': 'HTMLEmbedElement',
    'fieldset': 'HTMLFieldSetElement',
    'font': 'HTMLFontElement',
    'form': 'HTMLFormElement',
    'frame': 'HTMLFrameElement',
    'frameset': 'HTMLFrameSetElement',
    'hr': 'HTMLHRElement',
    'head': 'HTMLHeadElement',
    'h1': 'HTMLHeadingElement',
    'html': 'HTMLHtmlElement',
    'iframe': 'HTMLIFrameElement',

    // Uses HTMLSpanElement in Firefox.
    // https://bugzilla.mozilla.org/show_bug.cgi?id=843881
    // 'image',

    'input': 'HTMLInputElement',
    'li': 'HTMLLIElement',
    'label': 'HTMLLabelElement',
    'legend': 'HTMLLegendElement',
    'link': 'HTMLLinkElement',
    'map': 'HTMLMapElement',
    // 'media', Covered by audio and video
    'menu': 'HTMLMenuElement',
    'menuitem': 'HTMLMenuItemElement',
    'meta': 'HTMLMetaElement',
    'meter': 'HTMLMeterElement',
    'del': 'HTMLModElement',
    'ol': 'HTMLOListElement',
    'object': 'HTMLObjectElement',
    'optgroup': 'HTMLOptGroupElement',
    'option': 'HTMLOptionElement',
    'output': 'HTMLOutputElement',
    'p': 'HTMLParagraphElement',
    'param': 'HTMLParamElement',
    'pre': 'HTMLPreElement',
    'progress': 'HTMLProgressElement',
    'q': 'HTMLQuoteElement',
    'script': 'HTMLScriptElement',
    'select': 'HTMLSelectElement',
    'source': 'HTMLSourceElement',
    'span': 'HTMLSpanElement',
    'style': 'HTMLStyleElement',
    'caption': 'HTMLTableCaptionElement',
    // WebKit and Moz are wrong:
    // https://bugs.webkit.org/show_bug.cgi?id=111469
    // https://bugzilla.mozilla.org/show_bug.cgi?id=848096
    // 'td': 'HTMLTableCellElement',
    'col': 'HTMLTableColElement',
    'table': 'HTMLTableElement',
    'tr': 'HTMLTableRowElement',
    'thead': 'HTMLTableSectionElement',
    'tbody': 'HTMLTableSectionElement',
    'textarea': 'HTMLTextAreaElement',
    'title': 'HTMLTitleElement',
    'ul': 'HTMLUListElement',
    'video': 'HTMLVideoElement',
  };

  function overrideConstructor(tagName) {
    var nativeConstructorName = elements[tagName];
    var nativeConstructor = window[nativeConstructorName];
    if (!nativeConstructor)
      return;
    var element = document.createElement(tagName);
    var wrapperConstructor = element.constructor;
    window[nativeConstructorName] = wrapperConstructor;
  }

  Object.keys(elements).forEach(overrideConstructor);

  Object.getOwnPropertyNames(scope.wrappers).forEach(function(name) {
    window[name] = scope.wrappers[name]
  });

  // Export for testing.
  scope.knownElements = elements;

})(this.ShadowDOMPolyfill);
/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function() {
  var ShadowDOMPolyfill = window.ShadowDOMPolyfill;
  var wrap = ShadowDOMPolyfill.wrap;

  // patch in prefixed name
  Object.defineProperties(HTMLElement.prototype, {
    //TODO(sjmiles): review accessor alias with Arv
    webkitShadowRoot: {
      get: function() {
        return this.shadowRoot;
      }
    }
  });

  //TODO(sjmiles): review method alias with Arv
  HTMLElement.prototype.webkitCreateShadowRoot =
      HTMLElement.prototype.createShadowRoot;

  // TODO(jmesserly): we need to wrap document somehow (a dart:html hook?)
  window.dartExperimentalFixupGetTag = function(originalGetTag) {
    var NodeList = ShadowDOMPolyfill.wrappers.NodeList;
    var ShadowRoot = ShadowDOMPolyfill.wrappers.ShadowRoot;
    var isWrapper = ShadowDOMPolyfill.isWrapper;
    var unwrap = ShadowDOMPolyfill.unwrap;
    function getTag(obj) {
      if (obj instanceof NodeList) return 'NodeList';
      if (obj instanceof ShadowRoot) return 'ShadowRoot';
      if (obj instanceof MutationRecord) return 'MutationRecord';
      if (obj instanceof MutationObserver) return 'MutationObserver';

      if (isWrapper(obj)) {
        obj = unwrap(obj);

        // Fix up class names for Firefox. For some of them like
        // HTMLFormElement and HTMLInputElement, the "constructor" property of
        // the unwrapped nodes points at the wrapper for some reason.
        // TODO(jmesserly): figure out why this is happening.
        var ctor = obj.constructor;
        if (ctor && ctor._ShadowDOMPolyfill$isGeneratedWrapper) {
          var name = ctor._ShadowDOMPolyfill$cacheTag_;
          if (!name) {
            name = Object.prototype.toString.call(obj);
            name = name.substring(8, name.length - 1);
            ctor._ShadowDOMPolyfill$cacheTag_ = name;
          }
          return name;
        }
      }
      return originalGetTag(obj);
    }

    return getTag;
  };
})();

}