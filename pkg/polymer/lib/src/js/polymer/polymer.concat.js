/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
Polymer = {};

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

// TODO(sorvell): this ensures Polymer is an object and not a function
// Platform is currently defining it as a function to allow for async loading
// of polymer; once we refine the loading process this likely goes away.
if (typeof window.Polymer === 'function') {
  Polymer = {};
}


/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // copy own properties from 'api' to 'prototype, with name hinting for 'super'
  function extend(prototype, api) {
    if (prototype && api) {
      // use only own properties of 'api'
      Object.getOwnPropertyNames(api).forEach(function(n) {
        // acquire property descriptor
        var pd = Object.getOwnPropertyDescriptor(api, n);
        if (pd) {
          // clone property via descriptor
          Object.defineProperty(prototype, n, pd);
          // cache name-of-method for 'super' engine
          if (typeof pd.value == 'function') {
            // hint the 'super' engine
            pd.value.nom = n;
          }
        }
      });
    }
    return prototype;
  }
  
  // exports

  scope.extend = extend;

})(Polymer);

/* 
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {
  
  // usage
  
  // invoke cb.call(this) in 100ms, unless the job is re-registered,
  // which resets the timer
  // 
  // this.myJob = this.job(this.myJob, cb, 100)
  //
  // returns a job handle which can be used to re-register a job

  var Job = function(inContext) {
    this.context = inContext;
    this.boundComplete = this.complete.bind(this)
  };
  Job.prototype = {
    go: function(callback, wait) {
      this.callback = callback;
      var h;
      if (!wait) {
        h = requestAnimationFrame(this.boundComplete);
        this.handle = function() {
          cancelAnimationFrame(h);
        }
      } else {
        h = setTimeout(this.boundComplete, wait);
        this.handle = function() {
          clearTimeout(h);
        }
      }
    },
    stop: function() {
      if (this.handle) {
        this.handle();
        this.handle = null;
      }
    },
    complete: function() {
      if (this.handle) {
        this.stop();
        this.callback.call(this.context);
      }
    }
  };
  
  function job(job, callback, wait) {
    if (job) {
      job.stop();
    } else {
      job = new Job(this);
    }
    job.go(callback, wait);
    return job;
  }
  
  // exports 

  scope.job = job;
  
})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  var registry = {};

  HTMLElement.register = function(tag, prototype) {
    registry[tag] = prototype;
  }

  // get prototype mapped to node <tag>
  HTMLElement.getPrototypeForTag = function(tag) {
    var prototype = !tag ? HTMLElement.prototype : registry[tag];
    // TODO(sjmiles): creating <tag> is likely to have wasteful side-effects
    return prototype || Object.getPrototypeOf(document.createElement(tag));
  };

  // we have to flag propagation stoppage for the event dispatcher
  var originalStopPropagation = Event.prototype.stopPropagation;
  Event.prototype.stopPropagation = function() {
    this.cancelBubble = true;
    originalStopPropagation.apply(this, arguments);
  };
  
  // TODO(sorvell): remove when we're sure imports does not need
  // to load stylesheets
  /*
  HTMLImports.importer.preloadSelectors += 
      ', polymer-element link[rel=stylesheet]';
  */
})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
 (function(scope) {
    // super

    // `arrayOfArgs` is an optional array of args like one might pass
    // to `Function.apply`

    // TODO(sjmiles):
    //    $super must be installed on an instance or prototype chain
    //    as `super`, and invoked via `this`, e.g.
    //      `this.super();`

    //    will not work if function objects are not unique, for example,
    //    when using mixins.
    //    The memoization strategy assumes each function exists on only one 
    //    prototype chain i.e. we use the function object for memoizing)
    //    perhaps we can bookkeep on the prototype itself instead
    function $super(arrayOfArgs) {
      // since we are thunking a method call, performance is important here: 
      // memoize all lookups, once memoized the fast path calls no other 
      // functions
      //
      // find the caller (cannot be `strict` because of 'caller')
      var caller = $super.caller;
      // memoized 'name of method' 
      var nom = caller.nom;
      // memoized next implementation prototype
      var _super = caller._super;
      if (!_super) {
        if (!nom) {
          nom = caller.nom = nameInThis.call(this, caller);
        }
        if (!nom) {
          console.warn('called super() on a method not installed declaratively (has no .nom property)');
        }
        // super prototype is either cached or we have to find it
        // by searching __proto__ (at the 'top')
        _super = memoizeSuper(caller, nom, getPrototypeOf(this));
      }
      if (!_super) {
        // if _super is falsey, there is no super implementation
        //console.warn('called $super(' + nom + ') where there is no super implementation');
      } else {
        // our super function
        var fn = _super[nom];
        // memoize information so 'fn' can call 'super'
        if (!fn._super) {
          memoizeSuper(fn, nom, _super);
        }
        // invoke the inherited method
        // if 'fn' is not function valued, this will throw
        return fn.apply(this, arrayOfArgs || []);
      }
    }

    function nextSuper(proto, name, caller) {
      // look for an inherited prototype that implements name
      while (proto) {
        if ((proto[name] !== caller) && proto[name]) {
          return proto;
        }
        proto = getPrototypeOf(proto);
      }
    }

    function memoizeSuper(method, name, proto) {
      // find and cache next prototype containing `name`
      // we need the prototype so we can do another lookup
      // from here
      method._super = nextSuper(proto, name, method);
      if (method._super) {
        // _super is a prototype, the actual method is _super[name]
        // tag super method with it's name for further lookups
        method._super[name].nom = name;
      }
      return method._super;
    }

    function nameInThis(value) {
      var p = this.__proto__;
      while (p && p !== HTMLElement.prototype) {
        // TODO(sjmiles): getOwnPropertyNames is absurdly expensive
        var n$ = Object.getOwnPropertyNames(p);
        for (var i=0, l=n$.length, n; i<l && (n=n$[i]); i++) {
          var d = Object.getOwnPropertyDescriptor(p, n);
          if (typeof d.value === 'function' && d.value === value) {
            return n;
          }
        }
        p = p.__proto__;
      }
    }

    // NOTE: In some platforms (IE10) the prototype chain is faked via 
    // __proto__. Therefore, always get prototype via __proto__ instead of
    // the more standard Object.getPrototypeOf.
    function getPrototypeOf(prototype) {
      return prototype.__proto__;
    }

    // utility function to precompute name tags for functions
    // in a (unchained) prototype
    function hintSuper(prototype) {
      // tag functions with their prototype name to optimize
      // super call invocations
      for (var n in prototype) {
        var pd = Object.getOwnPropertyDescriptor(prototype, n);
        if (pd && typeof pd.value === 'function') {
          pd.value.nom = n;
        }
      }
    }

    // exports

    scope.super = $super;

})(Polymer);

/* 
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {

  var typeHandlers = {
    string: function(value) {
      return value;
    },
    date: function(value) {
      return new Date(Date.parse(value) || Date.now());
    },
    boolean: function(value) {
      if (value === '') {
        return true;
      }
      return value === 'false' ? false : !!value;
    },
    number: function(value) {
      var n = parseFloat(value);
      // hex values like "0xFFFF" parseFloat as 0
      if (n === 0) {
        n = parseInt(value);
      }
      return isNaN(n) ? value : n;
      // this code disabled because encoded values (like "0xFFFF")
      // do not round trip to their original format
      //return (String(floatVal) === value) ? floatVal : value;
    },
    object: function(value, currentValue) {
      if (currentValue === null) {
        return value;
      }
      try {
        // If the string is an object, we can parse is with the JSON library.
        // include convenience replace for single-quotes. If the author omits
        // quotes altogether, parse will fail.
        return JSON.parse(value.replace(/'/g, '"'));
      } catch(e) {
        // The object isn't valid JSON, return the raw value
        return value;
      }
    },
    // avoid deserialization of functions
    'function': function(value, currentValue) {
      return currentValue;
    }
  };

  function deserializeValue(value, currentValue) {
    // attempt to infer type from default value
    var inferredType = typeof currentValue;
    // invent 'date' type value for Date
    if (currentValue instanceof Date) {
      inferredType = 'date';
    }
    // delegate deserialization via type string
    return typeHandlers[inferredType](value, currentValue);
  }

  // exports

  scope.deserializeValue = deserializeValue;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports

  var extend = scope.extend;

  // module

  var api = {};

  api.declaration = {};
  api.instance = {};

  api.publish = function(apis, prototype) {
    for (var n in apis) {
      extend(prototype, apis[n]);
    }
  }

  // exports

  scope.api = api;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  var utils = {
    /**
      * Invokes a function asynchronously. The context of the callback
      * function is bound to 'this' automatically.
      * @method async
      * @param {Function|String} method
      * @param {any|Array} args
      * @param {number} timeout
      */
    async: function(method, args, timeout) {
      // when polyfilling Object.observe, ensure changes 
      // propagate before executing the async method
      Platform.flush();
      // second argument to `apply` must be an array
      args = (args && args.length) ? args : [args];
      // function to invoke
      var fn = function() {
        (this[method] || method).apply(this, args);
      }.bind(this);
      // execute `fn` sooner or later
      var handle = timeout ? setTimeout(fn, timeout) :
          requestAnimationFrame(fn);
      // NOTE: switch on inverting handle to determine which time is used.
      return timeout ? handle : ~handle;
    },
    cancelAsync: function(handle) {
      if (handle < 0) {
        cancelAnimationFrame(~handle);
      } else {
        clearTimeout(handle);
      }
    },
    /**
      * Fire an event.
      * @method fire
      * @returns {Object} event
      * @param {string} type An event name.
      * @param {any} detail
      * @param {Node} onNode Target node.
      */
    fire: function(type, detail, onNode, bubbles, cancelable) {
      var node = onNode || this;
      var detail = detail || {};
      var event = new CustomEvent(type, {
        bubbles: (bubbles !== undefined ? bubbles : true), 
        cancelable: (cancelable !== undefined ? cancelable : true), 
        detail: detail
      });
      node.dispatchEvent(event);
      return event;
    },
    /**
      * Fire an event asynchronously.
      * @method asyncFire
      * @param {string} type An event name.
      * @param detail
      * @param {Node} toNode Target node.
      */
    asyncFire: function(/*inType, inDetail*/) {
      this.async("fire", arguments);
    },
    /**
      * Remove class from old, add class to anew, if they exist
      * @param classFollows
      * @param anew A node.
      * @param old A node
      * @param className
      */
    classFollows: function(anew, old, className) {
      if (old) {
        old.classList.remove(className);
      }
      if (anew) {
        anew.classList.add(className);
      }
    }
  };

  // no-operation function for handy stubs
  var nop = function() {};

  // null-object for handy stubs
  var nob = {};

  // deprecated

  utils.asyncMethod = utils.async;

  // exports

  scope.api.instance.utils = utils;
  scope.nop = nop;
  scope.nob = nob;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {

  // imports

  var log = window.logFlags || {};
  var EVENT_PREFIX = 'on-';

  // instance events api
  var events = {
    // read-only
    EVENT_PREFIX: EVENT_PREFIX,
    // event listeners on host
    addHostListeners: function() {
      var events = this.eventDelegates;
      log.events && (Object.keys(events).length > 0) && console.log('[%s] addHostListeners:', this.localName, events);
      // NOTE: host events look like bindings but really are not;
      // (1) we don't want the attribute to be set and (2) we want to support
      // multiple event listeners ('host' and 'instance') and Node.bind
      // by default supports 1 thing being bound.
      // We do, however, leverage the event hookup code in PolymerExpressions
      // so that we have a common code path for handling declarative events.
      var self = this, bindable, eventName;
      for (var n in events) {
        eventName = EVENT_PREFIX + n;
        bindable = PolymerExpressions.prepareEventBinding(
          Path.get(events[n]),
          eventName, 
          {
            resolveEventHandler: function(model, path, node) {
              var fn = path.getValueFrom(self);
              if (fn) {
                return fn.bind(self);
              }
            }
          }
        );
        bindable(this, this, false);
      }
    },
    // call 'method' or function method on 'obj' with 'args', if the method exists
    dispatchMethod: function(obj, method, args) {
      if (obj) {
        log.events && console.group('[%s] dispatch [%s]', obj.localName, method);
        var fn = typeof method === 'function' ? method : obj[method];
        if (fn) {
          fn[args ? 'apply' : 'call'](obj, args);
        }
        log.events && console.groupEnd();
        Platform.flush();
      }
    }
  };

  // exports

  scope.api.instance.events = events;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // instance api for attributes

  var attributes = {
    copyInstanceAttributes: function () {
      var a$ = this._instanceAttributes;
      for (var k in a$) {
        if (!this.hasAttribute(k)) {
          this.setAttribute(k, a$[k]);
        }
      }
    },
    // for each attribute on this, deserialize value to property as needed
    takeAttributes: function() {
      // if we have no publish lookup table, we have no attributes to take
      // TODO(sjmiles): ad hoc
      if (this._publishLC) {
        for (var i=0, a$=this.attributes, l=a$.length, a; (a=a$[i]) && i<l; i++) {
          this.attributeToProperty(a.name, a.value);
        }
      }
    },
    // if attribute 'name' is mapped to a property, deserialize
    // 'value' into that property
    attributeToProperty: function(name, value) {
      // try to match this attribute to a property (attributes are
      // all lower-case, so this is case-insensitive search)
      var name = this.propertyForAttribute(name);
      if (name) {
        // filter out 'mustached' values, these are to be
        // replaced with bound-data and are not yet values
        // themselves
        if (value && value.search(scope.bindPattern) >= 0) {
          return;
        }
        // get original value
        var currentValue = this[name];
        // deserialize Boolean or Number values from attribute
        var value = this.deserializeValue(value, currentValue);
        // only act if the value has changed
        if (value !== currentValue) {
          // install new value (has side-effects)
          this[name] = value;
        }
      }
    },
    // return the published property matching name, or undefined
    propertyForAttribute: function(name) {
      var match = this._publishLC && this._publishLC[name];
      //console.log('propertyForAttribute:', name, 'matches', match);
      return match;
    },
    // convert representation of 'stringValue' based on type of 'currentValue'
    deserializeValue: function(stringValue, currentValue) {
      return scope.deserializeValue(stringValue, currentValue);
    },
    serializeValue: function(value, inferredType) {
      if (inferredType === 'boolean') {
        return value ? '' : undefined;
      } else if (inferredType !== 'object' && inferredType !== 'function'
          && value !== undefined) {
        return value;
      }
    },
    reflectPropertyToAttribute: function(name) {
      var inferredType = typeof this[name];
      // try to intelligently serialize property value
      var serializedValue = this.serializeValue(this[name], inferredType);
      // boolean properties must reflect as boolean attributes
      if (serializedValue !== undefined) {
        this.setAttribute(name, serializedValue);
        // TODO(sorvell): we should remove attr for all properties
        // that have undefined serialization; however, we will need to
        // refine the attr reflection system to achieve this; pica, for example,
        // relies on having inferredType object properties not removed as
        // attrs.
      } else if (inferredType === 'boolean') {
        this.removeAttribute(name);
      }
    }
  };

  // exports

  scope.api.instance.attributes = attributes;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports

  var log = window.logFlags || {};

  // magic words

  var OBSERVE_SUFFIX = 'Changed';

  // element api

  var empty = [];

  var properties = {
    observeProperties: function() {
      var n$ = this._observeNames, pn$ = this._publishNames;
      if ((n$ && n$.length) || (pn$ && pn$.length)) {
        var self = this;
        var o = this._propertyObserver = new CompoundObserver();
        // keep track of property observer so we can shut it down
        this.registerObservers([o]);
        for (var i=0, l=n$.length, n; (i<l) && (n=n$[i]); i++) {
          o.addPath(this, n);
          // observer array properties
          var pd = Object.getOwnPropertyDescriptor(this.__proto__, n);
          if (pd && pd.value) {
            this.observeArrayValue(n, pd.value, null);
          }
        }
        for (var i=0, l=pn$.length, n; (i<l) && (n=pn$[i]); i++) {
          if (!this.observe || (this.observe[n] === undefined)) {
            o.addPath(this, n);
          }
        }
        o.open(this.notifyPropertyChanges, this);
      }
    },
    notifyPropertyChanges: function(newValues, oldValues, paths) {
      var name, method, called = {};
      for (var i in oldValues) {
        // note: paths is of form [object, path, object, path]
        name = paths[2 * i + 1];
        if (this.publish[name] !== undefined) {
          this.reflectPropertyToAttribute(name);
        }
        method = this.observe[name];
        if (method) {
          this.observeArrayValue(name, newValues[i], oldValues[i]);
          if (!called[method]) {
            called[method] = true;
            // observes the value if it is an array
            this.invokeMethod(method, [oldValues[i], newValues[i], arguments]);
          }
        }
      }
    },
    observeArrayValue: function(name, value, old) {
      // we only care if there are registered side-effects
      var callbackName = this.observe[name];
      if (callbackName) {
        // if we are observing the previous value, stop
        if (Array.isArray(old)) {
          log.observe && console.log('[%s] observeArrayValue: unregister observer [%s]', this.localName, name);
          this.closeNamedObserver(name + '__array');
        }
        // if the new value is an array, being observing it
        if (Array.isArray(value)) {
          log.observe && console.log('[%s] observeArrayValue: register observer [%s]', this.localName, name, value);
          var observer = new ArrayObserver(value);
          observer.open(function(value, old) {
            this.invokeMethod(callbackName, [old]);
          }, this);
          this.registerNamedObserver(name + '__array', observer);
        }
      }
    },
    bindProperty: function(property, observable) {
      // apply Polymer two-way reference binding
      return bindProperties(this, property, observable);
    },
    invokeMethod: function(method, args) {
      var fn = this[method] || method;
      if (typeof fn === 'function') {
        fn.apply(this, args);
      }
    },
    registerObservers: function(observers) {
      this._observers.push(observers);
    },
    // observer array items are arrays of observers.
    closeObservers: function() {
      for (var i=0, l=this._observers.length; i<l; i++) {
        this.closeObserverArray(this._observers[i]);
      }
      this._observers = [];
    },
    closeObserverArray: function(observerArray) {
      for (var i=0, l=observerArray.length, o; i<l; i++) {
        o = observerArray[i];
        if (o && o.close) {
          o.close();
        }
      }
    },
    // bookkeeping observers for memory management
    registerNamedObserver: function(name, observer) {
      var o$ = this._namedObservers || (this._namedObservers = {});
      o$[name] = observer;
    },
    closeNamedObserver: function(name) {
      var o$ = this._namedObservers;
      if (o$ && o$[name]) {
        o$[name].close();
        o$[name] = null;
        return true;
      }
    },
    closeNamedObservers: function() {
      if (this._namedObservers) {
        var keys=Object.keys(this._namedObservers);
        for (var i=0, l=keys.length, k, o; (i < l) && (k=keys[i]); i++) {
          o = this._namedObservers[k];
          o.close();
        }
        this._namedObservers = {};
      }
    }
  };

  // property binding
  // bind a property in A to a path in B by converting A[property] to a
  // getter/setter pair that accesses B[...path...]
  function bindProperties(inA, inProperty, observable) {
    log.bind && console.log(LOG_BIND_PROPS, inB.localName || 'object', inPath, inA.localName, inProperty);
    // capture A's value if B's value is null or undefined,
    // otherwise use B's value
    // TODO(sorvell): need to review, can do with ObserverTransform
    var v = observable.discardChanges();
    if (v === null || v === undefined) {
      observable.setValue(inA[inProperty]);
    }
    return Observer.defineComputedProperty(inA, inProperty, observable);
  }

  // logging
  var LOG_OBSERVE = '[%s] watching [%s]';
  var LOG_OBSERVED = '[%s#%s] watch: [%s] now [%s] was [%s]';
  var LOG_CHANGED = '[%s#%s] propertyChanged: [%s] now [%s] was [%s]';
  var LOG_BIND_PROPS = "[%s]: bindProperties: [%s] to [%s].[%s]";

  // exports

  scope.api.instance.properties = properties;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports

  var log = window.logFlags || 0;
  var events = scope.api.instance.events;

  var syntax = new PolymerExpressions();
  syntax.resolveEventHandler = function(model, path, node) {
    var ctlr = findEventController(node);
    if (ctlr) {
      var fn = path.getValueFrom(ctlr);
      if (fn) {
        return fn.bind(ctlr);
      }
    }
  }

  // An event controller is the host element for the shadowRoot in which 
  // the node exists, or the first ancestor with a 'lightDomController'
  // property.
  function findEventController(node) {
    while (node.parentNode) {
      if (node.lightDomController) {
        return node;
      }
      node = node.parentNode;
    }
    return node.host;
  };

  // element api supporting mdv

  var mdv = {
    syntax: syntax,
    instanceTemplate: function(template) {
      var dom = template.createInstance(this, this.syntax);
      this.registerObservers(dom.bindings_);
      return dom;
    },
    bind: function(name, observable, oneTime) {
      var property = this.propertyForAttribute(name);
      if (!property) {
        // TODO(sjmiles): this mixin method must use the special form
        // of `super` installed by `mixinMethod` in declaration/prototype.js
        return this.mixinSuper(arguments);
      } else {
        // use n-way Polymer binding
        var observer = this.bindProperty(property, observable);
        this.reflectPropertyToAttribute(property);
        // NOTE: reflecting binding information is typically required only for
        // tooling. It has a performance cost so it's opt-in in Node.bind.
        if (Platform.enableBindingsReflection) {
          observer.path = observable.path_;
          this.bindings_ = this.bindings_ || {};
          this.bindings_[name] = observer;
        }
        return observer;
      }
    },
    // TODO(sorvell): unbind/unbindAll has been removed, as public api, from
    // TemplateBinding. We still need to close/dispose of observers but perhaps
    // we should choose a more explicit name.
    asyncUnbindAll: function() {
      if (!this._unbound) {
        log.unbind && console.log('[%s] asyncUnbindAll', this.localName);
        this._unbindAllJob = this.job(this._unbindAllJob, this.unbindAll, 0);
      }
    },
    unbindAll: function() {
      if (!this._unbound) {
        this.closeObservers();
        this.closeNamedObservers();
        this._unbound = true;
      }
    },
    cancelUnbindAll: function() {
      if (this._unbound) {
        log.unbind && console.warn('[%s] already unbound, cannot cancel unbindAll', this.localName);
        return;
      }
      log.unbind && console.log('[%s] cancelUnbindAll', this.localName);
      if (this._unbindAllJob) {
        this._unbindAllJob = this._unbindAllJob.stop();
      }
    }
  };

  function unbindNodeTree(node) {
    forNodeTree(node, _nodeUnbindAll);
  }

  function _nodeUnbindAll(node) {
    node.unbindAll();
  }

  function forNodeTree(node, callback) {
    if (node) {
      callback(node);
      for (var child = node.firstChild; child; child = child.nextSibling) {
        forNodeTree(child, callback);
      }
    }
  }

  var mustachePattern = /\{\{([^{}]*)}}/;

  // exports

  scope.bindPattern = mustachePattern;
  scope.api.instance.mdv = mdv;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  var base = {
    PolymerBase: true,
    job: function(job, callback, wait) {
      if (typeof job === 'string') {
        var n = '___' + job;
        this[n] = Polymer.job.call(this, this[n], callback, wait);
      } else {
        return Polymer.job.call(this, job, callback, wait);
      }
    },
    super: Polymer.super,
    // user entry point for element has had its createdCallback called
    created: function() {
    },
    // user entry point for element has shadowRoot and is ready for
    // api interaction
    ready: function() {
    },
    createdCallback: function() {
      if (this.templateInstance && this.templateInstance.model) {
        console.warn('Attributes on ' + this.localName + ' were data bound ' +
            'prior to Polymer upgrading the element. This may result in ' +
            'incorrect binding types.');
      }
      this.created();
      this.prepareElement();
    },
    // system entry point, do not override
    prepareElement: function() {
      this._elementPrepared = true;
      // install shadowRoots storage
      this.shadowRoots = {};
      // storage for closeable observers.
      this._observers = [];
      // install property observers
      this.observeProperties();
      // install boilerplate attributes
      this.copyInstanceAttributes();
      // process input attributes
      this.takeAttributes();
      // add event listeners
      this.addHostListeners();
      // process declarative resources
      this.parseDeclarations(this.__proto__);
      // TODO(sorvell): CE polyfill uses unresolved attribute to simulate
      // :unresolved; remove this attribute to be compatible with native
      // CE.
      this.removeAttribute('unresolved');
      // user entry point
      this.ready();
    },
    attachedCallback: function() {
      this.cancelUnbindAll();
      // invoke user action
      if (this.attached) {
        this.attached();
      }
      // TODO(sorvell): bc
      if (this.enteredView) {
        this.enteredView();
      }
      // NOTE: domReady can be used to access elements in dom (descendants, 
      // ancestors, siblings) such that the developer is enured to upgrade
      // ordering. If the element definitions have loaded, domReady
      // can be used to access upgraded elements.
      if (!this.hasBeenAttached) {
        this.hasBeenAttached = true;
        if (this.domReady) {
          this.async('domReady');
        }
      }
    },
    detachedCallback: function() {
      if (!this.preventDispose) {
        this.asyncUnbindAll();
      }
      // invoke user action
      if (this.detached) {
        this.detached();
      }
      // TODO(sorvell): bc
      if (this.leftView) {
        this.leftView();
      }
    },
    // TODO(sorvell): bc
    enteredViewCallback: function() {
      this.attachedCallback();
    },
    // TODO(sorvell): bc
    leftViewCallback: function() {
      this.detachedCallback();
    },
    // TODO(sorvell): bc
    enteredDocumentCallback: function() {
      this.attachedCallback();
    },
    // TODO(sorvell): bc
    leftDocumentCallback: function() {
      this.detachedCallback();
    },
    // recursive ancestral <element> initialization, oldest first
    parseDeclarations: function(p) {
      if (p && p.element) {
        this.parseDeclarations(p.__proto__);
        p.parseDeclaration.call(this, p.element);
      }
    },
    // parse input <element> as needed, override for custom behavior
    parseDeclaration: function(elementElement) {
      var template = this.fetchTemplate(elementElement);
      if (template) {
        var root = this.shadowFromTemplate(template);
        this.shadowRoots[elementElement.name] = root;
      }
    },
    // return a shadow-root template (if desired), override for custom behavior
    fetchTemplate: function(elementElement) {
      return elementElement.querySelector('template');
    },
    // utility function that creates a shadow root from a <template>
    shadowFromTemplate: function(template) {
      if (template) {
        // make a shadow root
        var root = this.createShadowRoot();
        // stamp template
        // which includes parsing and applying MDV bindings before being 
        // inserted (to avoid {{}} in attribute values)
        // e.g. to prevent <img src="images/{{icon}}"> from generating a 404.
        var dom = this.instanceTemplate(template);
        // append to shadow dom
        root.appendChild(dom);
        // perform post-construction initialization tasks on shadow root
        this.shadowRootReady(root, template);
        // return the created shadow root
        return root;
      }
    },
    // utility function that stamps a <template> into light-dom
    lightFromTemplate: function(template, refNode) {
      if (template) {
        // TODO(sorvell): mark this element as a lightDOMController so that
        // event listeners on bound nodes inside it will be called on it.
        // Note, the expectation here is that events on all descendants 
        // should be handled by this element.
        this.lightDomController = true;
        // stamp template
        // which includes parsing and applying MDV bindings before being 
        // inserted (to avoid {{}} in attribute values)
        // e.g. to prevent <img src="images/{{icon}}"> from generating a 404.
        var dom = this.instanceTemplate(template);
        // append to shadow dom
        if (refNode) {
          this.insertBefore(dom, refNode);          
        } else {
          this.appendChild(dom);
        }
        // perform post-construction initialization tasks on ahem, light root
        this.shadowRootReady(this);
        // return the created shadow root
        return dom;
      }
    },
    shadowRootReady: function(root) {
      // locate nodes with id and store references to them in this.$ hash
      this.marshalNodeReferences(root);
      // set up pointer gestures
      PointerGestures.register(root);
    },
    // locate nodes with id and store references to them in this.$ hash
    marshalNodeReferences: function(root) {
      // establish $ instance variable
      var $ = this.$ = this.$ || {};
      // populate $ from nodes with ID from the LOCAL tree
      if (root) {
        var n$ = root.querySelectorAll("[id]");
        for (var i=0, l=n$.length, n; (i<l) && (n=n$[i]); i++) {
          $[n.id] = n;
        };
      }
    },
    attributeChangedCallback: function(name, oldValue) {
      // TODO(sjmiles): adhoc filter
      if (name !== 'class' && name !== 'style') {
        this.attributeToProperty(name, this.getAttribute(name));
      }
      if (this.attributeChanged) {
        this.attributeChanged.apply(this, arguments);
      }
    },
    onMutation: function(node, listener) {
      var observer = new MutationObserver(function(mutations) {
        listener.call(this, observer, mutations);
        observer.disconnect();
      }.bind(this));
      observer.observe(node, {childList: true, subtree: true});
    }
  };

  // true if object has own PolymerBase api
  function isBase(object) {
    return object.hasOwnProperty('PolymerBase') 
  }

  // name a base constructor for dev tools

  function PolymerBase() {};
  PolymerBase.prototype = base;
  base.constructor = PolymerBase;
  
  // exports

  scope.Base = PolymerBase;
  scope.isBase = isBase;
  scope.api.instance.base = base;
  
})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports

  var log = window.logFlags || {};
  
  // magic words
  
  var STYLE_SCOPE_ATTRIBUTE = 'element';
  var STYLE_CONTROLLER_SCOPE = 'controller';
  
  var styles = {
    STYLE_SCOPE_ATTRIBUTE: STYLE_SCOPE_ATTRIBUTE,
    /**
     * Installs external stylesheets and <style> elements with the attribute 
     * polymer-scope='controller' into the scope of element. This is intended
     * to be a called during custom element construction.
    */
    installControllerStyles: function() {
      // apply controller styles, but only if they are not yet applied
      var scope = this.findStyleScope();
      if (scope && !this.scopeHasNamedStyle(scope, this.localName)) {
        // allow inherited controller styles
        var proto = getPrototypeOf(this), cssText = '';
        while (proto && proto.element) {
          cssText += proto.element.cssTextForScope(STYLE_CONTROLLER_SCOPE);
          proto = getPrototypeOf(proto);
        }
        if (cssText) {
          this.installScopeCssText(cssText, scope);
        }
      }
    },
    installScopeStyle: function(style, name, scope) {
      var scope = scope || this.findStyleScope(), name = name || '';
      if (scope && !this.scopeHasNamedStyle(scope, this.localName + name)) {
        var cssText = '';
        if (style instanceof Array) {
          for (var i=0, l=style.length, s; (i<l) && (s=style[i]); i++) {
            cssText += s.textContent + '\n\n';
          }
        } else {
          cssText = style.textContent;
        }
        this.installScopeCssText(cssText, scope, name);
      }
    },
    installScopeCssText: function(cssText, scope, name) {
      scope = scope || this.findStyleScope();
      name = name || '';
      if (!scope) {
        return;
      }
      if (window.ShadowDOMPolyfill) {
        cssText = shimCssText(cssText, scope.host);
      }
      var style = this.element.cssTextToScopeStyle(cssText,
          STYLE_CONTROLLER_SCOPE);
      Polymer.applyStyleToScope(style, scope);
      // cache that this style has been applied
      scope._scopeStyles[this.localName + name] = true;
    },
    findStyleScope: function(node) {
      // find the shadow root that contains this element
      var n = node || this;
      while (n.parentNode) {
        n = n.parentNode;
      }
      return n;
    },
    scopeHasNamedStyle: function(scope, name) {
      scope._scopeStyles = scope._scopeStyles || {};
      return scope._scopeStyles[name];
    }
  };
  
  // NOTE: use raw prototype traversal so that we ensure correct traversal
  // on platforms where the protoype chain is simulated via __proto__ (IE10)
  function getPrototypeOf(prototype) {
    return prototype.__proto__;
  }

  function shimCssText(cssText, host) {
    var name = '', is = false;
    if (host) {
      name = host.localName;
      is = host.hasAttribute('is');
    }
    var selector = Platform.ShadowCSS.makeScopeSelector(name, is);
    return Platform.ShadowCSS.shimCssText(cssText, selector);
  }

  // exports

  scope.api.instance.styles = styles;
  
})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports

  var extend = scope.extend;
  var api = scope.api;

  // imperative implementation: Polymer()

  // specify an 'own' prototype for tag `name`
  function element(name, prototype) {
    if (arguments.length === 1 && typeof arguments[0] !== 'string') {
      prototype = name;
      var script = document._currentScript;
      name = script && script.parentNode && script.parentNode.getAttribute ?
          script.parentNode.getAttribute('name') : '';
      if (!name) {
        throw 'Element name could not be inferred.';
      }
    }
    if (getRegisteredPrototype[name]) {
      throw 'Already registered (Polymer) prototype for element ' + name;
    }
    // cache the prototype
    registerPrototype(name, prototype);
    // notify the registrar waiting for 'name', if any
    notifyPrototype(name);
  }

  // async prototype source

  function waitingForPrototype(name, client) {
    waitPrototype[name] = client;
  }

  var waitPrototype = {};

  function notifyPrototype(name) {
    if (waitPrototype[name]) {
      waitPrototype[name].registerWhenReady();
      delete waitPrototype[name];
    }
  }

  // utility and bookkeeping

  // maps tag names to prototypes, as registered with
  // Polymer. Prototypes associated with a tag name
  // using document.registerElement are available from
  // HTMLElement.getPrototypeForTag().
  // If an element was fully registered by Polymer, then
  // Polymer.getRegisteredPrototype(name) === 
  //   HTMLElement.getPrototypeForTag(name)

  var prototypesByName = {};

  function registerPrototype(name, prototype) {
    return prototypesByName[name] = prototype || {};
  }

  function getRegisteredPrototype(name) {
    return prototypesByName[name];
  }

  // exports

  scope.getRegisteredPrototype = getRegisteredPrototype;
  scope.waitingForPrototype = waitingForPrototype;

  // namespace shenanigans so we can expose our scope on the registration 
  // function

  // make window.Polymer reference `element()`

  window.Polymer = element;

  // TODO(sjmiles): find a way to do this that is less terrible
  // copy window.Polymer properties onto `element()`

  extend(Polymer, scope);

  // Under the HTMLImports polyfill, scripts in the main document
  // do not block on imports; we want to allow calls to Polymer in the main
  // document. Platform collects those calls until we can process them, which
  // we do here.

  var declarations = Platform.deliverDeclarations();
  if (declarations) {
    for (var i=0, l=declarations.length, d; (i<l) && (d=declarations[i]); i++) {
      element.apply(null, d);
    }
  }

})(Polymer);

/* 
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {

var path = {
  resolveElementPaths: function(node) {
    Platform.urlResolver.resolveDom(node);
  },
  addResolvePathApi: function() {
    // let assetpath attribute modify the resolve path
    var assetPath = this.getAttribute('assetpath') || '';
    var root = new URL(assetPath, this.ownerDocument.baseURI);
    this.prototype.resolvePath = function(urlPath, base) {
      var u = new URL(urlPath, base || root);
      return u.href;
    };
  }
};

// exports
scope.api.declaration.path = path;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports

  var log = window.logFlags || {};
  var api = scope.api.instance.styles;
  var STYLE_SCOPE_ATTRIBUTE = api.STYLE_SCOPE_ATTRIBUTE;

  // magic words

  var STYLE_SELECTOR = 'style';
  var STYLE_LOADABLE_MATCH = '@import';
  var SHEET_SELECTOR = 'link[rel=stylesheet]';
  var STYLE_GLOBAL_SCOPE = 'global';
  var SCOPE_ATTR = 'polymer-scope';

  var styles = {
    // returns true if resources are loading
    loadStyles: function(callback) {
      var content = this.templateContent();
      if (content) {
        this.convertSheetsToStyles(content);
      }
      var styles = this.findLoadableStyles(content);
      if (styles.length) {
        Platform.styleResolver.loadStyles(styles, callback);
      } else if (callback) {
        callback();
      }
    },
    convertSheetsToStyles: function(root) {
      var s$ = root.querySelectorAll(SHEET_SELECTOR);
      for (var i=0, l=s$.length, s, c; (i<l) && (s=s$[i]); i++) {
        c = createStyleElement(importRuleForSheet(s, this.ownerDocument.baseURI),
            this.ownerDocument);
        this.copySheetAttributes(c, s);
        s.parentNode.replaceChild(c, s);
      }
    },
    copySheetAttributes: function(style, link) {
      for (var i=0, a$=link.attributes, l=a$.length, a; (a=a$[i]) && i<l; i++) {
        if (a.name !== 'rel' && a.name !== 'href') {
          style.setAttribute(a.name, a.value);
        }
      }
    },
    findLoadableStyles: function(root) {
      var loadables = [];
      if (root) {
        var s$ = root.querySelectorAll(STYLE_SELECTOR);
        for (var i=0, l=s$.length, s; (i<l) && (s=s$[i]); i++) {
          if (s.textContent.match(STYLE_LOADABLE_MATCH)) {
            loadables.push(s);
          }
        }
      }
      return loadables;
    },
    /**
     * Install external stylesheets loaded in <polymer-element> elements into the 
     * element's template.
     * @param elementElement The <element> element to style.
     */
    installSheets: function() {
      this.cacheSheets();
      this.cacheStyles();
      this.installLocalSheets();
      this.installGlobalStyles();
    },
    /**
     * Remove all sheets from element and store for later use.
     */
    cacheSheets: function() {
      this.sheets = this.findNodes(SHEET_SELECTOR);
      this.sheets.forEach(function(s) {
        if (s.parentNode) {
          s.parentNode.removeChild(s);
        }
      });
    },
    cacheStyles: function() {
      this.styles = this.findNodes(STYLE_SELECTOR + '[' + SCOPE_ATTR + ']');
      this.styles.forEach(function(s) {
        if (s.parentNode) {
          s.parentNode.removeChild(s);
        }
      });
    },
    /**
     * Takes external stylesheets loaded in an <element> element and moves
     * their content into a <style> element inside the <element>'s template.
     * The sheet is then removed from the <element>. This is done only so 
     * that if the element is loaded in the main document, the sheet does
     * not become active.
     * Note, ignores sheets with the attribute 'polymer-scope'.
     * @param elementElement The <element> element to style.
     */
    installLocalSheets: function () {
      var sheets = this.sheets.filter(function(s) {
        return !s.hasAttribute(SCOPE_ATTR);
      });
      var content = this.templateContent();
      if (content) {
        var cssText = '';
        sheets.forEach(function(sheet) {
          cssText += cssTextFromSheet(sheet) + '\n';
        });
        if (cssText) {
          var style = createStyleElement(cssText, this.ownerDocument);
          content.insertBefore(style, content.firstChild);
        }
      }
    },
    findNodes: function(selector, matcher) {
      var nodes = this.querySelectorAll(selector).array();
      var content = this.templateContent();
      if (content) {
        var templateNodes = content.querySelectorAll(selector).array();
        nodes = nodes.concat(templateNodes);
      }
      return matcher ? nodes.filter(matcher) : nodes;
    },
    templateContent: function() {
      var template = this.querySelector('template');
      return template && templateContent(template);
    },
    /**
     * Promotes external stylesheets and <style> elements with the attribute 
     * polymer-scope='global' into global scope.
     * This is particularly useful for defining @keyframe rules which 
     * currently do not function in scoped or shadow style elements.
     * (See wkb.ug/72462)
     * @param elementElement The <element> element to style.
    */
    // TODO(sorvell): remove when wkb.ug/72462 is addressed.
    installGlobalStyles: function() {
      var style = this.styleForScope(STYLE_GLOBAL_SCOPE);
      applyStyleToScope(style, document.head);
    },
    cssTextForScope: function(scopeDescriptor) {
      var cssText = '';
      // handle stylesheets
      var selector = '[' + SCOPE_ATTR + '=' + scopeDescriptor + ']';
      var matcher = function(s) {
        return matchesSelector(s, selector);
      };
      var sheets = this.sheets.filter(matcher);
      sheets.forEach(function(sheet) {
        cssText += cssTextFromSheet(sheet) + '\n\n';
      });
      // handle cached style elements
      var styles = this.styles.filter(matcher);
      styles.forEach(function(style) {
        cssText += style.textContent + '\n\n';
      });
      return cssText;
    },
    styleForScope: function(scopeDescriptor) {
      var cssText = this.cssTextForScope(scopeDescriptor);
      return this.cssTextToScopeStyle(cssText, scopeDescriptor);
    },
    cssTextToScopeStyle: function(cssText, scopeDescriptor) {
      if (cssText) {
        var style = createStyleElement(cssText);
        style.setAttribute(STYLE_SCOPE_ATTRIBUTE, this.getAttribute('name') +
            '-' + scopeDescriptor);
        return style;
      }
    }
  };

  function importRuleForSheet(sheet, baseUrl) {
    var href = new URL(sheet.getAttribute('href'), baseUrl).href;
    return '@import \'' + href + '\';';
  }

  function applyStyleToScope(style, scope) {
    if (style) {
      if (scope === document) {
        scope = document.head;
      }
      if (window.ShadowDOMPolyfill) {
        scope = document.head;
      }
      // TODO(sorvell): necessary for IE
      // see https://connect.microsoft.com/IE/feedback/details/790212/
      // cloning-a-style-element-and-adding-to-document-produces
      // -unexpected-result#details
      // var clone = style.cloneNode(true);
      var clone = createStyleElement(style.textContent);
      var attr = style.getAttribute(STYLE_SCOPE_ATTRIBUTE);
      if (attr) {
        clone.setAttribute(STYLE_SCOPE_ATTRIBUTE, attr);
      }
      // TODO(sorvell): probably too brittle; try to figure out 
      // where to put the element.
      var refNode = scope.firstElementChild;
      if (scope === document.head) {
        var selector = 'style[' + STYLE_SCOPE_ATTRIBUTE + ']';
        var s$ = document.head.querySelectorAll(selector);
        if (s$.length) {
          refNode = s$[s$.length-1].nextElementSibling;
        }
      }
      scope.insertBefore(clone, refNode);
    }
  }

  function createStyleElement(cssText, scope) {
    scope = scope || document;
    scope = scope.createElement ? scope : scope.ownerDocument;
    var style = scope.createElement('style');
    style.textContent = cssText;
    return style;
  }

  function cssTextFromSheet(sheet) {
    return (sheet && sheet.__resource) || '';
  }

  function matchesSelector(node, inSelector) {
    if (matches) {
      return matches.call(node, inSelector);
    }
  }
  var p = HTMLElement.prototype;
  var matches = p.matches || p.matchesSelector || p.webkitMatchesSelector 
      || p.mozMatchesSelector;
  
  // exports

  scope.api.declaration.styles = styles;
  scope.applyStyleToScope = applyStyleToScope;
  
})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {

  // imports

  var log = window.logFlags || {};
  var api = scope.api.instance.events;
  var EVENT_PREFIX = api.EVENT_PREFIX;
  // polymer-element declarative api: events feature

  var events = { 
    parseHostEvents: function() {
      // our delegates map
      var delegates = this.prototype.eventDelegates;
      // extract data from attributes into delegates
      this.addAttributeDelegates(delegates);
    },
    addAttributeDelegates: function(delegates) {
      // for each attribute
      for (var i=0, a; a=this.attributes[i]; i++) {
        // does it have magic marker identifying it as an event delegate?
        if (this.hasEventPrefix(a.name)) {
          // if so, add the info to delegates
          delegates[this.removeEventPrefix(a.name)] = a.value.replace('{{', '')
              .replace('}}', '').trim();
        }
      }
    },
    // starts with 'on-'
    hasEventPrefix: function (n) {
      return n && (n[0] === 'o') && (n[1] === 'n') && (n[2] === '-');
    },
    removeEventPrefix: function(n) {
      return n.slice(prefixLength);
    }
  };

  var prefixLength = EVENT_PREFIX.length;

  // exports
  scope.api.declaration.events = events;

})(Polymer);
/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // element api

  var properties = {
    inferObservers: function(prototype) {
      // called before prototype.observe is chained to inherited object
      var observe = prototype.observe, property;
      for (var n in prototype) {
        if (n.slice(-7) === 'Changed') {
          if (!observe) {
            observe  = (prototype.observe = {});
          }
          property = n.slice(0, -7)
          observe[property] = observe[property] || n;
        }
      }
    },
    explodeObservers: function(prototype) {
      // called before prototype.observe is chained to inherited object
      var o = prototype.observe;
      if (o) {
        var exploded = {};
        for (var n in o) {
          var names = n.split(' ');
          for (var i=0, ni; ni=names[i]; i++) {
            exploded[ni] = o[n];
          }
        }
        prototype.observe = exploded;
      }
    },
    optimizePropertyMaps: function(prototype) {
      if (prototype.observe) {
        // construct name list
        var a = prototype._observeNames = [];
        for (var n in prototype.observe) {
          var names = n.split(' ');
          for (var i=0, ni; ni=names[i]; i++) {
            a.push(ni);
          }
        }
      }
      if (prototype.publish) {
        // construct name list
        var a = prototype._publishNames = [];
        for (var n in prototype.publish) {
          a.push(n);
        }
      }
    },
    publishProperties: function(prototype, base) {
      // if we have any properties to publish
      var publish = prototype.publish;
      if (publish) {
        // transcribe `publish` entries onto own prototype
        this.requireProperties(publish, prototype, base);
        // construct map of lower-cased property names
        prototype._publishLC = this.lowerCaseMap(publish);
      }
    },
    requireProperties: function(properties, prototype, base) {
      // ensure a prototype value for each property
      for (var n in properties) {
        if (prototype[n] === undefined && base[n] === undefined) {
          prototype[n] = properties[n];
        }
      }
    },
    lowerCaseMap: function(properties) {
      var map = {};
      for (var n in properties) {
        map[n.toLowerCase()] = n;
      }
      return map;
    }
  };

  // exports

  scope.api.declaration.properties = properties;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // magic words

  var ATTRIBUTES_ATTRIBUTE = 'attributes';
  var ATTRIBUTES_REGEX = /\s|,/;

  // attributes api

  var attributes = {
    inheritAttributesObjects: function(prototype) {
      // chain our lower-cased publish map to the inherited version
      this.inheritObject(prototype, 'publishLC');
      // chain our instance attributes map to the inherited version
      this.inheritObject(prototype, '_instanceAttributes');
    },
    publishAttributes: function(prototype, base) {
      // merge names from 'attributes' attribute
      var attributes = this.getAttribute(ATTRIBUTES_ATTRIBUTE);
      if (attributes) {
        // get properties to publish
        var publish = prototype.publish || (prototype.publish = {});
        // names='a b c' or names='a,b,c'
        var names = attributes.split(ATTRIBUTES_REGEX);
        // record each name for publishing
        for (var i=0, l=names.length, n; i<l; i++) {
          // remove excess ws
          n = names[i].trim();
          // do not override explicit entries
          if (n && publish[n] === undefined && base[n] === undefined) {
            publish[n] = null;
          }
        }
      }
    },
    // record clonable attributes from <element>
    accumulateInstanceAttributes: function() {
      // inherit instance attributes
      var clonable = this.prototype._instanceAttributes;
      // merge attributes from element
      var a$ = this.attributes;
      for (var i=0, l=a$.length, a; (i<l) && (a=a$[i]); i++) {  
        if (this.isInstanceAttribute(a.name)) {
          clonable[a.name] = a.value;
        }
      }
    },
    isInstanceAttribute: function(name) {
      return !this.blackList[name] && name.slice(0,3) !== 'on-';
    },
    // do not clone these attributes onto instances
    blackList: {
      name: 1,
      'extends': 1,
      constructor: 1,
      noscript: 1,
      assetpath: 1,
      'cache-csstext': 1
    }
  };

  // add ATTRIBUTES_ATTRIBUTE to the blacklist
  attributes.blackList[ATTRIBUTES_ATTRIBUTE] = 1;

  // exports

  scope.api.declaration.attributes = attributes;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports
  
  var api = scope.api;
  var isBase = scope.isBase;
  var extend = scope.extend;

  // prototype api

  var prototype = {

    register: function(name, extendeeName) {
      // build prototype combining extendee, Polymer base, and named api
      this.buildPrototype(name, extendeeName);
      // register our custom element with the platform
      this.registerPrototype(name, extendeeName);
      // reference constructor in a global named by 'constructor' attribute
      this.publishConstructor();
    },

    buildPrototype: function(name, extendeeName) {
      // get our custom prototype (before chaining)
      var extension = scope.getRegisteredPrototype(name);
      // get basal prototype
      var base = this.generateBasePrototype(extendeeName);
      // implement declarative features
      this.desugarBeforeChaining(extension, base);
      // join prototypes
      this.prototype = this.chainPrototypes(extension, base);
      // more declarative features
      this.desugarAfterChaining(name, extendeeName);
    },

    desugarBeforeChaining: function(prototype, base) {
      // back reference declaration element
      // TODO(sjmiles): replace `element` with `elementElement` or `declaration`
      prototype.element = this;
      // transcribe `attributes` declarations onto own prototype's `publish`
      this.publishAttributes(prototype, base);
      // `publish` properties to the prototype and to attribute watch
      this.publishProperties(prototype, base);
      // infer observers for `observe` list based on method names
      this.inferObservers(prototype);
      // desugar compound observer syntax, e.g. 'a b c' 
      this.explodeObservers(prototype);
    },

    chainPrototypes: function(prototype, base) {
      // chain various meta-data objects to inherited versions
      this.inheritMetaData(prototype, base);
      // chain custom api to inherited
      var chained = this.chainObject(prototype, base);
      // x-platform fixup
      ensurePrototypeTraversal(chained);
      return chained;
    },

    inheritMetaData: function(prototype, base) {
      // chain observe object to inherited
      this.inheritObject('observe', prototype, base);
      // chain publish object to inherited
      this.inheritObject('publish', prototype, base);
      // chain our lower-cased publish map to the inherited version
      this.inheritObject('_publishLC', prototype, base);
      // chain our instance attributes map to the inherited version
      this.inheritObject('_instanceAttributes', prototype, base);
      // chain our event delegates map to the inherited version
      this.inheritObject('eventDelegates', prototype, base);
    },

    // implement various declarative features
    desugarAfterChaining: function(name, extendee) {
      // build side-chained lists to optimize iterations
      this.optimizePropertyMaps(this.prototype);
      // install external stylesheets as if they are inline
      this.installSheets();
      // adjust any paths in dom from imports
      this.resolveElementPaths(this);
      // compile list of attributes to copy to instances
      this.accumulateInstanceAttributes();
      // parse on-* delegates declared on `this` element
      this.parseHostEvents();
      //
      // install a helper method this.resolvePath to aid in 
      // setting resource urls. e.g.
      // this.$.image.src = this.resolvePath('images/foo.png')
      this.addResolvePathApi();
      // under ShadowDOMPolyfill, transforms to approximate missing CSS features
      if (window.ShadowDOMPolyfill) {
        Platform.ShadowCSS.shimStyling(this.templateContent(), name, extendee);
      }
      // allow custom element access to the declarative context
      if (this.prototype.registerCallback) {
        this.prototype.registerCallback(this);
      }
    },

    // if a named constructor is requested in element, map a reference
    // to the constructor to the given symbol
    publishConstructor: function() {
      var symbol = this.getAttribute('constructor');
      if (symbol) {
        window[symbol] = this.ctor;
      }
    },

    // build prototype combining extendee, Polymer base, and named api
    generateBasePrototype: function(extnds) {
      var prototype = this.findBasePrototype(extnds);
      if (!prototype) {
        // create a prototype based on tag-name extension
        var prototype = HTMLElement.getPrototypeForTag(extnds);
        // insert base api in inheritance chain (if needed)
        prototype = this.ensureBaseApi(prototype);
        // memoize this base
        memoizedBases[extnds] = prototype;
      }
      return prototype;
    },

    findBasePrototype: function(name) {
      return memoizedBases[name];
    },

    // install Polymer instance api into prototype chain, as needed 
    ensureBaseApi: function(prototype) {
      if (prototype.PolymerBase) {
        return prototype;
      }
      var extended = Object.create(prototype);
      // we need a unique copy of base api for each base prototype
      // therefore we 'extend' here instead of simply chaining
      api.publish(api.instance, extended);
      // TODO(sjmiles): sharing methods across prototype chains is
      // not supported by 'super' implementation which optimizes
      // by memoizing prototype relationships.
      // Probably we should have a version of 'extend' that is 
      // share-aware: it could study the text of each function,
      // look for usage of 'super', and wrap those functions in
      // closures.
      // As of now, there is only one problematic method, so 
      // we just patch it manually.
      // To avoid re-entrancy problems, the special super method
      // installed is called `mixinSuper` and the mixin method
      // must use this method instead of the default `super`.
      this.mixinMethod(extended, prototype, api.instance.mdv, 'bind');
      // return buffed-up prototype
      return extended;
    },

    mixinMethod: function(extended, prototype, api, name) {
      var $super = function(args) {
        return prototype[name].apply(this, args);
      };
      extended[name] = function() {
        this.mixinSuper = $super;
        return api[name].apply(this, arguments);
      }
    },

    // ensure prototype[name] inherits from a prototype.prototype[name]
    inheritObject: function(name, prototype, base) {
      // require an object
      var source = prototype[name] || {};
      // chain inherited properties onto a new object
      prototype[name] = this.chainObject(source, base[name]);
    },

    // register 'prototype' to custom element 'name', store constructor 
    registerPrototype: function(name, extendee) { 
      var info = {
        prototype: this.prototype
      }
      // native element must be specified in extends
      var typeExtension = this.findTypeExtension(extendee);
      if (typeExtension) {
        info.extends = typeExtension;
      }
      // register the prototype with HTMLElement for name lookup
      HTMLElement.register(name, this.prototype);
      // register the custom type
      this.ctor = document.registerElement(name, info);
    },

    findTypeExtension: function(name) {
      if (name && name.indexOf('-') < 0) {
        return name;
      } else {
        var p = this.findBasePrototype(name);
        if (p.element) {
          return this.findTypeExtension(p.element.extends);
        }
      }
    }

  };

  // memoize base prototypes
  var memoizedBases = {};

  // implementation of 'chainObject' depends on support for __proto__
  if (Object.__proto__) {
    prototype.chainObject = function(object, inherited) {
      if (object && inherited && object !== inherited) {
        object.__proto__ = inherited;
      }
      return object;
    }
  } else {
    prototype.chainObject = function(object, inherited) {
      if (object && inherited && object !== inherited) {
        var chained = Object.create(inherited);
        object = extend(chained, object);
      }
      return object;
    }
  }

  // On platforms that do not support __proto__ (versions of IE), the prototype
  // chain of a custom element is simulated via installation of __proto__.
  // Although custom elements manages this, we install it here so it's
  // available during desugaring.
  function ensurePrototypeTraversal(prototype) {
    if (!Object.__proto__) {
      var ancestor = Object.getPrototypeOf(prototype);
      prototype.__proto__ = ancestor;
      if (isBase(ancestor)) {
        ancestor.__proto__ = Object.getPrototypeOf(ancestor);
      }
    }
  }

  // exports

  api.declaration.prototype = prototype;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  var queue = {
    // tell the queue to wait for an element to be ready
    wait: function(element, check, go) {
      if (this.indexOf(element) === -1) {
        this.add(element);
        element.__check = check;
        element.__go = go;
      }
      return (this.indexOf(element) !== 0);
    },
    add: function(element) {
      //console.log('queueing', element.name);
      queueForElement(element).push(element);
    },
    indexOf: function(element) {
      var i = queueForElement(element).indexOf(element);
      if (i >= 0 && document.contains(element)) {
        i += (HTMLImports.useNative || HTMLImports.ready) ? 
          importQueue.length : 1e9;
      }
      return i;  
    },
    // tell the queue an element is ready to be registered
    go: function(element) {
      var readied = this.remove(element);
      if (readied) {
        readied.__go.call(readied);
        readied.__check = readied.__go = null;
        this.check();
      }
    },
    remove: function(element) {
      var i = this.indexOf(element);
      if (i !== 0) {
        //console.warn('queue order wrong', i);
        return;
      }
      return queueForElement(element).shift();
    },
    check: function() {
      // next
      var element = this.nextElement();
      if (element) {
        element.__check.call(element);
      }
      if (this.canReady()) {
        this.ready();
        return true;
      }
    },
    nextElement: function() {
      return nextQueued();
    },
    canReady: function() {
      return !this.waitToReady && this.isEmpty();
    },
    isEmpty: function() {
      return !importQueue.length && !mainQueue.length;
    },
    ready: function() {
      // TODO(sorvell): As an optimization, turn off CE polyfill upgrading
      // while registering. This way we avoid having to upgrade each document
      // piecemeal per registration and can instead register all elements
      // and upgrade once in a batch. Without this optimization, upgrade time
      // degrades significantly when SD polyfill is used. This is mainly because
      // querying the document tree for elements is slow under the SD polyfill.
      if (CustomElements.ready === false) {
        CustomElements.upgradeDocumentTree(document);
        CustomElements.ready = true;
      }
      if (readyCallbacks) {
        var fn;
        while (readyCallbacks.length) {
          fn = readyCallbacks.shift();
          fn();
        }
      }
    },
    addReadyCallback: function(callback) {
      if (callback) {
        readyCallbacks.push(callback);
      }
    },
    waitToReady: true
  };

  var importQueue = [];
  var mainQueue = [];
  var readyCallbacks = [];

  function queueForElement(element) {
    return document.contains(element) ? mainQueue : importQueue;
  }

  function nextQueued() {
    return importQueue.length ? importQueue[0] : mainQueue[0];
  }

  var polymerReadied = false; 

  document.addEventListener('WebComponentsReady', function() {
    CustomElements.ready = false;
  });
  
  function whenPolymerReady(callback) {
    queue.waitToReady = true;
    CustomElements.ready = false;
    HTMLImports.whenImportsReady(function() {
      queue.addReadyCallback(callback);
      queue.waitToReady = false;
      queue.check();
    });
  }

  // exports
  scope.queue = queue;
  scope.whenPolymerReady = whenPolymerReady;
})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  var whenPolymerReady = scope.whenPolymerReady;

  function importElements(elementOrFragment, callback) {
    if (elementOrFragment) {
      document.head.appendChild(elementOrFragment);
      whenPolymerReady(callback);
    } else if (callback) {
      callback();
    }
  }

  function importUrls(urls, callback) {
    if (urls && urls.length) {
        var frag = document.createDocumentFragment();
        for (var i=0, l=urls.length, url, link; (i<l) && (url=urls[i]); i++) {
          link = document.createElement('link');
          link.rel = 'import';
          link.href = url;
          frag.appendChild(link);
        }
        importElements(frag, callback);
    } else if (callback) {
      callback();
    }
  }

  // exports
  scope.import = importUrls;
  scope.importElements = importElements;

})(Polymer);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function(scope) {

  // imports

  var extend = scope.extend;
  var api = scope.api;
  var queue = scope.queue;
  var whenPolymerReady = scope.whenPolymerReady;
  var getRegisteredPrototype = scope.getRegisteredPrototype;
  var waitingForPrototype = scope.waitingForPrototype;

  // declarative implementation: <polymer-element>

  var prototype = extend(Object.create(HTMLElement.prototype), {

    createdCallback: function() {
      if (this.getAttribute('name')) {
        this.init();
      }
    },

    init: function() {
      // fetch declared values
      this.name = this.getAttribute('name');
      this.extends = this.getAttribute('extends');
      // initiate any async resource fetches
      this.loadResources();
      // register when all constraints are met
      this.registerWhenReady();
    },

    registerWhenReady: function() {
     if (this.registered
       || this.waitingForPrototype(this.name)
       || this.waitingForQueue()
       || this.waitingForResources()) {
          return;
      }
      // TODO(sorvell): ends up calling '_register' by virtue
      // of `waitingForQueue` (see below)
      queue.go(this);
    },

    // TODO(sorvell): refactor, this method is private-ish, but it's being
    // called by the queue object.
    _register: function() {
      //console.log('registering', this.name);
      //console.group('registering', this.name);
      // warn if extending from a custom element not registered via Polymer
      if (isCustomTag(this.extends) && !isRegistered(this.extends)) {
        console.warn('%s is attempting to extend %s, an unregistered element ' +
            'or one that was not registered with Polymer.', this.name,
            this.extends);
      }
      this.register(this.name, this.extends);
      this.registered = true;
      //console.groupEnd();
    },

    waitingForPrototype: function(name) {
      if (!getRegisteredPrototype(name)) {
        // then wait for a prototype
        waitingForPrototype(name, this);
        // emulate script if user is not supplying one
        this.handleNoScript(name);
        // prototype not ready yet
        return true;
      }
    },

    handleNoScript: function(name) {
      // if explicitly marked as 'noscript'
      if (this.hasAttribute('noscript') && !this.noscript) {
        this.noscript = true;
        // TODO(sorvell): CustomElements polyfill awareness:
        // noscript elements should upgrade in logical order
        // script injection ensures this under native custom elements;
        // under imports + ce polyfills, scripts run before upgrades.
        // dependencies should be ready at upgrade time so register
        // prototype at this time.
        if (window.CustomElements && !CustomElements.useNative) {
          Polymer(name);
        } else {
          var script = document.createElement('script');
          script.textContent = 'Polymer(\'' + name + '\');';
          this.appendChild(script);
        }
      }
    },

    waitingForResources: function() {
      return this._needsResources;
    },

    // NOTE: Elements must be queued in proper order for inheritance/composition
    // dependency resolution. Previously this was enforced for inheritance,
    // and by rule for composition. It's now entirely by rule.
    waitingForQueue: function() {
      return queue.wait(this, this.registerWhenReady, this._register);
    },

    loadResources: function() {
      this._needsResources = true;
      this.loadStyles(function() {
        this._needsResources = false;
        this.registerWhenReady();
      }.bind(this));
    }

  });

  // semi-pluggable APIs 

  // TODO(sjmiles): should be fully pluggable (aka decoupled, currently
  // the various plugins are allowed to depend on each other directly)
  api.publish(api.declaration, prototype);

  // utility and bookkeeping

  function isRegistered(name) {
    return Boolean(HTMLElement.getPrototypeForTag(name));
  }

  function isCustomTag(name) {
    return (name && name.indexOf('-') >= 0);
  }

  // exports

  scope.getRegisteredPrototype = getRegisteredPrototype;
  
  // boot tasks

  whenPolymerReady(function() {
    document.body.removeAttribute('unresolved');
    document.dispatchEvent(
      new CustomEvent('polymer-ready', {bubbles: true})
    );
  });

  // register polymer-element with document

  document.registerElement('polymer-element', {prototype: prototype});

})(Polymer);

//# sourceMappingURL=polymer.concat.js.map