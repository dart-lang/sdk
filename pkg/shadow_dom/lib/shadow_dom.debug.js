if (!HTMLElement.prototype.createShadowRoot
    || window.__forceShadowDomPolyfill) {

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

// Copyright 2012 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

(function(global) {
  'use strict';

  var PROP_ADD_TYPE = 'add';
  var PROP_UPDATE_TYPE = 'update';
  var PROP_RECONFIGURE_TYPE = 'reconfigure';
  var PROP_DELETE_TYPE = 'delete';
  var ARRAY_SPLICE_TYPE = 'splice';

  // Detect and do basic sanity checking on Object/Array.observe.
  function detectObjectObserve() {
    if (typeof Object.observe !== 'function' ||
        typeof Array.observe !== 'function') {
      return false;
    }

    var records = [];

    function callback(recs) {
      records = recs;
    }

    var test = {};
    Object.observe(test, callback);
    test.id = 1;
    test.id = 2;
    delete test.id;
    Object.deliverChangeRecords(callback);
    if (records.length !== 3)
      return false;

    // TODO(rafaelw): Remove this when new change record type names make it to
    // chrome release.
    if (records[0].type == 'new' &&
        records[1].type == 'updated' &&
        records[2].type == 'deleted') {
      PROP_ADD_TYPE = 'new';
      PROP_UPDATE_TYPE = 'updated';
      PROP_RECONFIGURE_TYPE = 'reconfigured';
      PROP_DELETE_TYPE = 'deleted';
    } else if (records[0].type != 'add' ||
               records[1].type != 'update' ||
               records[2].type != 'delete') {
      console.error('Unexpected change record names for Object.observe. ' +
                    'Using dirty-checking instead');
      return false;
    }
    Object.unobserve(test, callback);

    test = [0];
    Array.observe(test, callback);
    test[1] = 1;
    test.length = 0;
    Object.deliverChangeRecords(callback);
    if (records.length != 2)
      return false;
    if (records[0].type != ARRAY_SPLICE_TYPE ||
        records[1].type != ARRAY_SPLICE_TYPE) {
      return false;
    }
    Array.unobserve(test, callback);

    return true;
  }

  var hasObserve = detectObjectObserve();

  function detectEval() {
    // don't test for eval if document has CSP securityPolicy object and we can see that
    // eval is not supported. This avoids an error message in console even when the exception
    // is caught
    if (global.document &&
        'securityPolicy' in global.document &&
        !global.document.securityPolicy.allowsEval) {
      return false;
    }

    try {
      var f = new Function('', 'return true;');
      return f();
    } catch (ex) {
      return false;
    }
  }

  var hasEval = detectEval();

  function isIndex(s) {
    return +s === s >>> 0;
  }

  function toNumber(s) {
    return +s;
  }

  function isObject(obj) {
    return obj === Object(obj);
  }

  var numberIsNaN = global.Number.isNaN || function isNaN(value) {
    return typeof value === 'number' && global.isNaN(value);
  }

  function areSameValue(left, right) {
    if (left === right)
      return left !== 0 || 1 / left === 1 / right;
    if (numberIsNaN(left) && numberIsNaN(right))
      return true;

    return left !== left && right !== right;
  }

  var createObject = ('__proto__' in {}) ?
    function(obj) { return obj; } :
    function(obj) {
      var proto = obj.__proto__;
      if (!proto)
        return obj;
      var newObject = Object.create(proto);
      Object.getOwnPropertyNames(obj).forEach(function(name) {
        Object.defineProperty(newObject, name,
                             Object.getOwnPropertyDescriptor(obj, name));
      });
      return newObject;
    };

  var identStart = '[\$_a-zA-Z]';
  var identPart = '[\$_a-zA-Z0-9]';
  var ident = identStart + '+' + identPart + '*';
  var elementIndex = '(?:[0-9]|[1-9]+[0-9]+)';
  var identOrElementIndex = '(?:' + ident + '|' + elementIndex + ')';
  var path = '(?:' + identOrElementIndex + ')(?:\\s*\\.\\s*' + identOrElementIndex + ')*';
  var pathRegExp = new RegExp('^' + path + '$');

  function isPathValid(s) {
    if (typeof s != 'string')
      return false;
    s = s.trim();

    if (s == '')
      return true;

    if (s[0] == '.')
      return false;

    return pathRegExp.test(s);
  }

  var constructorIsPrivate = {};

  function Path(s, privateToken) {
    if (privateToken !== constructorIsPrivate)
      throw Error('Use Path.get to retrieve path objects');

    if (s.trim() == '')
      return this;

    if (isIndex(s)) {
      this.push(s);
      return this;
    }

    s.split(/\s*\.\s*/).filter(function(part) {
      return part;
    }).forEach(function(part) {
      this.push(part);
    }, this);

    if (hasEval && !hasObserve && this.length) {
      this.getValueFrom = this.compiledGetValueFromFn();
    }
  }

  // TODO(rafaelw): Make simple LRU cache
  var pathCache = {};

  function getPath(pathString) {
    if (pathString instanceof Path)
      return pathString;

    if (pathString == null)
      pathString = '';

    if (typeof pathString !== 'string')
      pathString = String(pathString);

    var path = pathCache[pathString];
    if (path)
      return path;
    if (!isPathValid(pathString))
      return invalidPath;
    var path = new Path(pathString, constructorIsPrivate);
    pathCache[pathString] = path;
    return path;
  }

  Path.get = getPath;

  Path.prototype = createObject({
    __proto__: [],
    valid: true,

    toString: function() {
      return this.join('.');
    },

    getValueFrom: function(obj, observedSet) {
      for (var i = 0; i < this.length; i++) {
        if (obj == null)
          return;
        if (observedSet)
          observedSet.observe(obj);
        obj = obj[this[i]];
      }
      return obj;
    },

    compiledGetValueFromFn: function() {
      var accessors = this.map(function(ident) {
        return isIndex(ident) ? '["' + ident + '"]' : '.' + ident;
      });

      var str = '';
      var pathString = 'obj';
      str += 'if (obj != null';
      var i = 0;
      for (; i < (this.length - 1); i++) {
        var ident = this[i];
        pathString += accessors[i];
        str += ' &&\n     ' + pathString + ' != null';
      }
      str += ')\n';

      pathString += accessors[i];

      str += '  return ' + pathString + ';\nelse\n  return undefined;';
      return new Function('obj', str);
    },

    setValueFrom: function(obj, value) {
      if (!this.length)
        return false;

      for (var i = 0; i < this.length - 1; i++) {
        if (!isObject(obj))
          return false;
        obj = obj[this[i]];
      }

      if (!isObject(obj))
        return false;

      obj[this[i]] = value;
      return true;
    }
  });

  var invalidPath = new Path('', constructorIsPrivate);
  invalidPath.valid = false;
  invalidPath.getValueFrom = invalidPath.setValueFrom = function() {};

  var MAX_DIRTY_CHECK_CYCLES = 1000;

  function dirtyCheck(observer) {
    var cycles = 0;
    while (cycles < MAX_DIRTY_CHECK_CYCLES && observer.check()) {
      observer.report();
      cycles++;
    }
    if (global.testingExposeCycleCount)
      global.dirtyCheckCycleCount = cycles;
  }

  function objectIsEmpty(object) {
    for (var prop in object)
      return false;
    return true;
  }

  function diffIsEmpty(diff) {
    return objectIsEmpty(diff.added) &&
           objectIsEmpty(diff.removed) &&
           objectIsEmpty(diff.changed);
  }

  function diffObjectFromOldObject(object, oldObject) {
    var added = {};
    var removed = {};
    var changed = {};
    var oldObjectHas = {};

    for (var prop in oldObject) {
      var newValue = object[prop];

      if (newValue !== undefined && newValue === oldObject[prop])
        continue;

      if (!(prop in object)) {
        removed[prop] = undefined;
        continue;
      }

      if (newValue !== oldObject[prop])
        changed[prop] = newValue;
    }

    for (var prop in object) {
      if (prop in oldObject)
        continue;

      added[prop] = object[prop];
    }

    if (Array.isArray(object) && object.length !== oldObject.length)
      changed.length = object.length;

    return {
      added: added,
      removed: removed,
      changed: changed
    };
  }

  function copyObject(object, opt_copy) {
    var copy = opt_copy || (Array.isArray(object) ? [] : {});
    for (var prop in object) {
      copy[prop] = object[prop];
    };
    if (Array.isArray(object))
      copy.length = object.length;
    return copy;
  }

  function Observer(object, callback, target, token) {
    this.closed = false;
    this.object = object;
    this.callback = callback;
    // TODO(rafaelw): Hold this.target weakly when WeakRef is available.
    this.target = target;
    this.token = token;
    this.reporting = true;
    if (hasObserve) {
      var self = this;
      this.boundInternalCallback = function(records) {
        self.internalCallback(records);
      };
    }

    addToAll(this);
  }

  Observer.prototype = {
    internalCallback: function(records) {
      if (this.closed)
        return;
      if (this.reporting && this.check(records)) {
        this.report();
        if (this.testingResults)
          this.testingResults.anyChanged = true;
      }
    },

    close: function() {
      if (this.closed)
        return;
      if (this.object && typeof this.object.close === 'function')
        this.object.close();

      this.disconnect();
      this.object = undefined;
      this.closed = true;
    },

    deliver: function(testingResults) {
      if (this.closed)
        return;
      if (hasObserve) {
        this.testingResults = testingResults;
        Object.deliverChangeRecords(this.boundInternalCallback);
        this.testingResults = undefined;
      } else {
        dirtyCheck(this);
      }
    },

    report: function() {
      if (!this.reporting)
        return;

      this.sync(false);
      if (this.callback) {
        this.reportArgs.push(this.token);
        this.invokeCallback(this.reportArgs);
      }
      this.reportArgs = undefined;
    },

    invokeCallback: function(args) {
      try {
        this.callback.apply(this.target, args);
      } catch (ex) {
        Observer._errorThrownDuringCallback = true;
        console.error('Exception caught during observer callback: ' + (ex.stack || ex));
      }
    },

    reset: function() {
      if (this.closed)
        return;

      if (hasObserve) {
        this.reporting = false;
        Object.deliverChangeRecords(this.boundInternalCallback);
        this.reporting = true;
      }

      this.sync(true);
    }
  }

  var collectObservers = !hasObserve || global.forceCollectObservers;
  var allObservers;
  Observer._allObserversCount = 0;

  if (collectObservers) {
    allObservers = [];
  }

  function addToAll(observer) {
    if (!collectObservers)
      return;

    allObservers.push(observer);
    Observer._allObserversCount++;
  }

  var runningMicrotaskCheckpoint = false;

  var hasDebugForceFullDelivery = typeof Object.deliverAllChangeRecords == 'function';

  global.Platform = global.Platform || {};

  global.Platform.performMicrotaskCheckpoint = function() {
    if (runningMicrotaskCheckpoint)
      return;

    if (hasDebugForceFullDelivery) {
      Object.deliverAllChangeRecords();
      return;
    }

    if (!collectObservers)
      return;

    runningMicrotaskCheckpoint = true;

    var cycles = 0;
    var results = {};

    do {
      cycles++;
      var toCheck = allObservers;
      allObservers = [];
      results.anyChanged = false;

      for (var i = 0; i < toCheck.length; i++) {
        var observer = toCheck[i];
        if (observer.closed)
          continue;

        if (hasObserve) {
          observer.deliver(results);
        } else if (observer.check()) {
          results.anyChanged = true;
          observer.report();
        }

        allObservers.push(observer);
      }
    } while (cycles < MAX_DIRTY_CHECK_CYCLES && results.anyChanged);

    if (global.testingExposeCycleCount)
      global.dirtyCheckCycleCount = cycles;

    Observer._allObserversCount = allObservers.length;
    runningMicrotaskCheckpoint = false;
  };

  if (collectObservers) {
    global.Platform.clearObservers = function() {
      allObservers = [];
    };
  }

  function ObjectObserver(object, callback, target, token) {
    Observer.call(this, object, callback, target, token);
    this.connect();
    this.sync(true);
  }

  ObjectObserver.prototype = createObject({
    __proto__: Observer.prototype,

    connect: function() {
      if (hasObserve)
        Object.observe(this.object, this.boundInternalCallback);
    },

    sync: function(hard) {
      if (!hasObserve)
        this.oldObject = copyObject(this.object);
    },

    check: function(changeRecords) {
      var diff;
      var oldValues;
      if (hasObserve) {
        if (!changeRecords)
          return false;

        oldValues = {};
        diff = diffObjectFromChangeRecords(this.object, changeRecords,
                                           oldValues);
      } else {
        oldValues = this.oldObject;
        diff = diffObjectFromOldObject(this.object, this.oldObject);
      }

      if (diffIsEmpty(diff))
        return false;

      this.reportArgs =
          [diff.added || {}, diff.removed || {}, diff.changed || {}];
      this.reportArgs.push(function(property) {
        return oldValues[property];
      });

      return true;
    },

    disconnect: function() {
      if (!hasObserve)
        this.oldObject = undefined;
      else if (this.object)
        Object.unobserve(this.object, this.boundInternalCallback);
    }
  });

  function ArrayObserver(array, callback, target, token) {
    if (!Array.isArray(array))
      throw Error('Provided object is not an Array');
    ObjectObserver.call(this, array, callback, target, token);
  }

  ArrayObserver.prototype = createObject({
    __proto__: ObjectObserver.prototype,

    connect: function() {
      if (hasObserve)
        Array.observe(this.object, this.boundInternalCallback);
    },

    sync: function() {
      if (!hasObserve)
        this.oldObject = this.object.slice();
    },

    check: function(changeRecords) {
      var splices;
      if (hasObserve) {
        if (!changeRecords)
          return false;
        splices = projectArraySplices(this.object, changeRecords);
      } else {
        splices = calcSplices(this.object, 0, this.object.length,
                              this.oldObject, 0, this.oldObject.length);
      }

      if (!splices || !splices.length)
        return false;

      this.reportArgs = [splices];
      return true;
    }
  });

  ArrayObserver.applySplices = function(previous, current, splices) {
    splices.forEach(function(splice) {
      var spliceArgs = [splice.index, splice.removed.length];
      var addIndex = splice.index;
      while (addIndex < splice.index + splice.addedCount) {
        spliceArgs.push(current[addIndex]);
        addIndex++;
      }

      Array.prototype.splice.apply(previous, spliceArgs);
    });
  };

  function ObservedSet(callback) {
    this.arr = [];
    this.callback = callback;
    this.isObserved = true;
  }

  // TODO(rafaelw): Consider surfacing a way to avoid observing prototype
  // ancestors which are expected not to change (e.g. Element, Node...).
  var objProto = Object.getPrototypeOf({});
  var arrayProto = Object.getPrototypeOf([]);
  ObservedSet.prototype = {
    reset: function() {
      this.isObserved = !this.isObserved;
    },

    observe: function(obj) {
      if (!isObject(obj) || obj === objProto || obj === arrayProto)
        return;
      var i = this.arr.indexOf(obj);
      if (i >= 0 && this.arr[i+1] === this.isObserved)
        return;

      if (i < 0) {
        i = this.arr.length;
        this.arr[i] = obj;
        Object.observe(obj, this.callback);
      }

      this.arr[i+1] = this.isObserved;
      this.observe(Object.getPrototypeOf(obj));
    },

    cleanup: function() {
      var i = 0, j = 0;
      var isObserved = this.isObserved;
      while(j < this.arr.length) {
        var obj = this.arr[j];
        if (this.arr[j + 1] == isObserved) {
          if (i < j) {
            this.arr[i] = obj;
            this.arr[i + 1] = isObserved;
          }
          i += 2;
        } else {
          Object.unobserve(obj, this.callback);
        }
        j += 2;
      }

      this.arr.length = i;
    }
  };

  function PathObserver(object, path, callback, target, token, valueFn,
                        setValueFn) {
    var path = path instanceof Path ? path : getPath(path);
    if (!path || !path.length || !isObject(object)) {
      this.value_ = path ? path.getValueFrom(object) : undefined;
      this.value = valueFn ? valueFn(this.value_) : this.value_;
      this.closed = true;
      return;
    }

    Observer.call(this, object, callback, target, token);
    this.valueFn = valueFn;
    this.setValueFn = setValueFn;
    this.path = path;

    this.connect();
    this.sync(true);
  }

  PathObserver.prototype = createObject({
    __proto__: Observer.prototype,

    connect: function() {
      if (hasObserve)
        this.observedSet = new ObservedSet(this.boundInternalCallback);
    },

    disconnect: function() {
      this.value = undefined;
      this.value_ = undefined;
      if (this.observedSet) {
        this.observedSet.reset();
        this.observedSet.cleanup();
        this.observedSet = undefined;
      }
    },

    check: function() {
      // Note: Extracting this to a member function for use here and below
      // regresses dirty-checking path perf by about 25% =-(.
      if (this.observedSet)
        this.observedSet.reset();

      this.value_ = this.path.getValueFrom(this.object, this.observedSet);

      if (this.observedSet)
        this.observedSet.cleanup();

      if (areSameValue(this.value_, this.oldValue_))
        return false;

      this.value = this.valueFn ? this.valueFn(this.value_) : this.value_;
      this.reportArgs = [this.value, this.oldValue];
      return true;
    },

    sync: function(hard) {
      if (hard) {
        if (this.observedSet)
          this.observedSet.reset();

        this.value_ = this.path.getValueFrom(this.object, this.observedSet);
        this.value = this.valueFn ? this.valueFn(this.value_) : this.value_;

        if (this.observedSet)
          this.observedSet.cleanup();
      }

      this.oldValue_ = this.value_;
      this.oldValue = this.value;
    },

    setValue: function(newValue) {
      if (!this.path)
        return;
      if (typeof this.setValueFn === 'function')
        newValue = this.setValueFn(newValue);
      this.path.setValueFrom(this.object, newValue);
    }
  });

  function CompoundPathObserver(callback, target, token, valueFn) {
    Observer.call(this, undefined, callback, target, token);
    this.valueFn = valueFn;

    this.observed = [];
    this.values = [];
    this.value = undefined;
    this.oldValue = undefined;
    this.oldValues = undefined;
    this.changeFlags = undefined;
    this.started = false;
  }

  CompoundPathObserver.prototype = createObject({
    __proto__: PathObserver.prototype,

    // TODO(rafaelw): Consider special-casing when |object| is a PathObserver
    // and path 'value' to avoid explicit observation.
    addPath: function(object, path) {
      if (this.started)
        throw Error('Cannot add more paths once started.');

      var path = path instanceof Path ? path : getPath(path);
      var value = path ? path.getValueFrom(object) : undefined;

      this.observed.push(object, path);
      this.values.push(value);
    },

    start: function() {
      this.started = true;
      this.connect();
      this.sync(true);
    },

    getValues: function() {
      if (this.observedSet)
        this.observedSet.reset();

      var anyChanged = false;
      for (var i = 0; i < this.observed.length; i = i+2) {
        var path = this.observed[i+1];
        if (!path)
          continue;
        var object = this.observed[i];
        var value = path.getValueFrom(object, this.observedSet);
        var oldValue = this.values[i/2];
        if (!areSameValue(value, oldValue)) {
          if (!anyChanged && !this.valueFn) {
            this.oldValues = this.oldValues || [];
            this.changeFlags = this.changeFlags || [];
            for (var j = 0; j < this.values.length; j++) {
              this.oldValues[j] = this.values[j];
              this.changeFlags[j] = false;
            }
          }

          if (!this.valueFn)
            this.changeFlags[i/2] = true;

          this.values[i/2] = value;
          anyChanged = true;
        }
      }

      if (this.observedSet)
        this.observedSet.cleanup();

      return anyChanged;
    },

    check: function() {
      if (!this.getValues())
        return;

      if (this.valueFn) {
        this.value = this.valueFn(this.values);

        if (areSameValue(this.value, this.oldValue))
          return false;

        this.reportArgs = [this.value, this.oldValue];
      } else {
        this.reportArgs = [this.values, this.oldValues, this.changeFlags,
                           this.observed];
      }

      return true;
    },

    sync: function(hard) {
      if (hard) {
        this.getValues();
        if (this.valueFn)
          this.value = this.valueFn(this.values);
      }

      if (this.valueFn)
        this.oldValue = this.value;
    },

    close: function() {
      if (this.observed) {
        for (var i = 0; i < this.observed.length; i = i + 2) {
          var object = this.observed[i];
          if (object && typeof object.close === 'function')
            object.close();
        }
        this.observed = undefined;
        this.values = undefined;
      }

      Observer.prototype.close.call(this);
    }
  });

  var expectedRecordTypes = {};
  expectedRecordTypes[PROP_ADD_TYPE] = true;
  expectedRecordTypes[PROP_UPDATE_TYPE] = true;
  expectedRecordTypes[PROP_DELETE_TYPE] = true;

  function notifyFunction(object, name) {
    if (typeof Object.observe !== 'function')
      return;

    var notifier = Object.getNotifier(object);
    return function(type, oldValue) {
      var changeRecord = {
        object: object,
        type: type,
        name: name
      };
      if (arguments.length === 2)
        changeRecord.oldValue = oldValue;
      notifier.notify(changeRecord);
    }
  }

  // TODO(rafaelw): It should be possible for the Object.observe case to have
  // every PathObserver used by defineProperty share a single Object.observe
  // callback, and thus get() can simply call observer.deliver() and any changes
  // to any dependent value will be observed.
  PathObserver.defineProperty = function(target, name, object, path) {
    // TODO(rafaelw): Validate errors
    path = getPath(path);
    var notify = notifyFunction(target, name);

    var observer = new PathObserver(object, path,
        function(newValue, oldValue) {
          if (notify)
            notify(PROP_UPDATE_TYPE, oldValue);
        }
    );

    Object.defineProperty(target, name, {
      get: function() {
        return path.getValueFrom(object);
      },
      set: function(newValue) {
        path.setValueFrom(object, newValue);
      },
      configurable: true
    });

    return {
      close: function() {
        var oldValue = path.getValueFrom(object);
        if (notify)
          observer.deliver();
        observer.close();
        Object.defineProperty(target, name, {
          value: oldValue,
          writable: true,
          configurable: true
        });
      }
    };
  }

  function diffObjectFromChangeRecords(object, changeRecords, oldValues) {
    var added = {};
    var removed = {};

    for (var i = 0; i < changeRecords.length; i++) {
      var record = changeRecords[i];
      if (!expectedRecordTypes[record.type]) {
        console.error('Unknown changeRecord type: ' + record.type);
        console.error(record);
        continue;
      }

      if (!(record.name in oldValues))
        oldValues[record.name] = record.oldValue;

      if (record.type == PROP_UPDATE_TYPE)
        continue;

      if (record.type == PROP_ADD_TYPE) {
        if (record.name in removed)
          delete removed[record.name];
        else
          added[record.name] = true;

        continue;
      }

      // type = 'delete'
      if (record.name in added) {
        delete added[record.name];
        delete oldValues[record.name];
      } else {
        removed[record.name] = true;
      }
    }

    for (var prop in added)
      added[prop] = object[prop];

    for (var prop in removed)
      removed[prop] = undefined;

    var changed = {};
    for (var prop in oldValues) {
      if (prop in added || prop in removed)
        continue;

      var newValue = object[prop];
      if (oldValues[prop] !== newValue)
        changed[prop] = newValue;
    }

    return {
      added: added,
      removed: removed,
      changed: changed
    };
  }

  function newSplice(index, removed, addedCount) {
    return {
      index: index,
      removed: removed,
      addedCount: addedCount
    };
  }

  var EDIT_LEAVE = 0;
  var EDIT_UPDATE = 1;
  var EDIT_ADD = 2;
  var EDIT_DELETE = 3;

  function ArraySplice() {}

  ArraySplice.prototype = {

    // Note: This function is *based* on the computation of the Levenshtein
    // "edit" distance. The one change is that "updates" are treated as two
    // edits - not one. With Array splices, an update is really a delete
    // followed by an add. By retaining this, we optimize for "keeping" the
    // maximum array items in the original array. For example:
    //
    //   'xxxx123' -> '123yyyy'
    //
    // With 1-edit updates, the shortest path would be just to update all seven
    // characters. With 2-edit updates, we delete 4, leave 3, and add 4. This
    // leaves the substring '123' intact.
    calcEditDistances: function(current, currentStart, currentEnd,
                                old, oldStart, oldEnd) {
      // "Deletion" columns
      var rowCount = oldEnd - oldStart + 1;
      var columnCount = currentEnd - currentStart + 1;
      var distances = new Array(rowCount);

      // "Addition" rows. Initialize null column.
      for (var i = 0; i < rowCount; i++) {
        distances[i] = new Array(columnCount);
        distances[i][0] = i;
      }

      // Initialize null row
      for (var j = 0; j < columnCount; j++)
        distances[0][j] = j;

      for (var i = 1; i < rowCount; i++) {
        for (var j = 1; j < columnCount; j++) {
          if (this.equals(current[currentStart + j - 1], old[oldStart + i - 1]))
            distances[i][j] = distances[i - 1][j - 1];
          else {
            var north = distances[i - 1][j] + 1;
            var west = distances[i][j - 1] + 1;
            distances[i][j] = north < west ? north : west;
          }
        }
      }

      return distances;
    },

    // This starts at the final weight, and walks "backward" by finding
    // the minimum previous weight recursively until the origin of the weight
    // matrix.
    spliceOperationsFromEditDistances: function(distances) {
      var i = distances.length - 1;
      var j = distances[0].length - 1;
      var current = distances[i][j];
      var edits = [];
      while (i > 0 || j > 0) {
        if (i == 0) {
          edits.push(EDIT_ADD);
          j--;
          continue;
        }
        if (j == 0) {
          edits.push(EDIT_DELETE);
          i--;
          continue;
        }
        var northWest = distances[i - 1][j - 1];
        var west = distances[i - 1][j];
        var north = distances[i][j - 1];

        var min;
        if (west < north)
          min = west < northWest ? west : northWest;
        else
          min = north < northWest ? north : northWest;

        if (min == northWest) {
          if (northWest == current) {
            edits.push(EDIT_LEAVE);
          } else {
            edits.push(EDIT_UPDATE);
            current = northWest;
          }
          i--;
          j--;
        } else if (min == west) {
          edits.push(EDIT_DELETE);
          i--;
          current = west;
        } else {
          edits.push(EDIT_ADD);
          j--;
          current = north;
        }
      }

      edits.reverse();
      return edits;
    },

    /**
     * Splice Projection functions:
     *
     * A splice map is a representation of how a previous array of items
     * was transformed into a new array of items. Conceptually it is a list of
     * tuples of
     *
     *   <index, removed, addedCount>
     *
     * which are kept in ascending index order of. The tuple represents that at
     * the |index|, |removed| sequence of items were removed, and counting forward
     * from |index|, |addedCount| items were added.
     */

    /**
     * Lacking individual splice mutation information, the minimal set of
     * splices can be synthesized given the previous state and final state of an
     * array. The basic approach is to calculate the edit distance matrix and
     * choose the shortest path through it.
     *
     * Complexity: O(l * p)
     *   l: The length of the current array
     *   p: The length of the old array
     */
    calcSplices: function(current, currentStart, currentEnd,
                          old, oldStart, oldEnd) {
      var prefixCount = 0;
      var suffixCount = 0;

      var minLength = Math.min(currentEnd - currentStart, oldEnd - oldStart);
      if (currentStart == 0 && oldStart == 0)
        prefixCount = this.sharedPrefix(current, old, minLength);

      if (currentEnd == current.length && oldEnd == old.length)
        suffixCount = this.sharedSuffix(current, old, minLength - prefixCount);

      currentStart += prefixCount;
      oldStart += prefixCount;
      currentEnd -= suffixCount;
      oldEnd -= suffixCount;

      if (currentEnd - currentStart == 0 && oldEnd - oldStart == 0)
        return [];

      if (currentStart == currentEnd) {
        var splice = newSplice(currentStart, [], 0);
        while (oldStart < oldEnd)
          splice.removed.push(old[oldStart++]);

        return [ splice ];
      } else if (oldStart == oldEnd)
        return [ newSplice(currentStart, [], currentEnd - currentStart) ];

      var ops = this.spliceOperationsFromEditDistances(
          this.calcEditDistances(current, currentStart, currentEnd,
                                 old, oldStart, oldEnd));

      var splice = undefined;
      var splices = [];
      var index = currentStart;
      var oldIndex = oldStart;
      for (var i = 0; i < ops.length; i++) {
        switch(ops[i]) {
          case EDIT_LEAVE:
            if (splice) {
              splices.push(splice);
              splice = undefined;
            }

            index++;
            oldIndex++;
            break;
          case EDIT_UPDATE:
            if (!splice)
              splice = newSplice(index, [], 0);

            splice.addedCount++;
            index++;

            splice.removed.push(old[oldIndex]);
            oldIndex++;
            break;
          case EDIT_ADD:
            if (!splice)
              splice = newSplice(index, [], 0);

            splice.addedCount++;
            index++;
            break;
          case EDIT_DELETE:
            if (!splice)
              splice = newSplice(index, [], 0);

            splice.removed.push(old[oldIndex]);
            oldIndex++;
            break;
        }
      }

      if (splice) {
        splices.push(splice);
      }
      return splices;
    },

    sharedPrefix: function(current, old, searchLength) {
      for (var i = 0; i < searchLength; i++)
        if (!this.equals(current[i], old[i]))
          return i;
      return searchLength;
    },

    sharedSuffix: function(current, old, searchLength) {
      var index1 = current.length;
      var index2 = old.length;
      var count = 0;
      while (count < searchLength && this.equals(current[--index1], old[--index2]))
        count++;

      return count;
    },

    calculateSplices: function(current, previous) {
      return this.calcSplices(current, 0, current.length, previous, 0,
                              previous.length);
    },

    equals: function(currentValue, previousValue) {
      return currentValue === previousValue;
    }
  };

  var arraySplice = new ArraySplice();

  function calcSplices(current, currentStart, currentEnd,
                       old, oldStart, oldEnd) {
    return arraySplice.calcSplices(current, currentStart, currentEnd,
                                   old, oldStart, oldEnd);
  }

  function intersect(start1, end1, start2, end2) {
    // Disjoint
    if (end1 < start2 || end2 < start1)
      return -1;

    // Adjacent
    if (end1 == start2 || end2 == start1)
      return 0;

    // Non-zero intersect, span1 first
    if (start1 < start2) {
      if (end1 < end2)
        return end1 - start2; // Overlap
      else
        return end2 - start2; // Contained
    } else {
      // Non-zero intersect, span2 first
      if (end2 < end1)
        return end2 - start1; // Overlap
      else
        return end1 - start1; // Contained
    }
  }

  function mergeSplice(splices, index, removed, addedCount) {

    var splice = newSplice(index, removed, addedCount);

    var inserted = false;
    var insertionOffset = 0;

    for (var i = 0; i < splices.length; i++) {
      var current = splices[i];
      current.index += insertionOffset;

      if (inserted)
        continue;

      var intersectCount = intersect(splice.index,
                                     splice.index + splice.removed.length,
                                     current.index,
                                     current.index + current.addedCount);

      if (intersectCount >= 0) {
        // Merge the two splices

        splices.splice(i, 1);
        i--;

        insertionOffset -= current.addedCount - current.removed.length;

        splice.addedCount += current.addedCount - intersectCount;
        var deleteCount = splice.removed.length +
                          current.removed.length - intersectCount;

        if (!splice.addedCount && !deleteCount) {
          // merged splice is a noop. discard.
          inserted = true;
        } else {
          var removed = current.removed;

          if (splice.index < current.index) {
            // some prefix of splice.removed is prepended to current.removed.
            var prepend = splice.removed.slice(0, current.index - splice.index);
            Array.prototype.push.apply(prepend, removed);
            removed = prepend;
          }

          if (splice.index + splice.removed.length > current.index + current.addedCount) {
            // some suffix of splice.removed is appended to current.removed.
            var append = splice.removed.slice(current.index + current.addedCount - splice.index);
            Array.prototype.push.apply(removed, append);
          }

          splice.removed = removed;
          if (current.index < splice.index) {
            splice.index = current.index;
          }
        }
      } else if (splice.index < current.index) {
        // Insert splice here.

        inserted = true;

        splices.splice(i, 0, splice);
        i++;

        var offset = splice.addedCount - splice.removed.length
        current.index += offset;
        insertionOffset += offset;
      }
    }

    if (!inserted)
      splices.push(splice);
  }

  function createInitialSplices(array, changeRecords) {
    var splices = [];

    for (var i = 0; i < changeRecords.length; i++) {
      var record = changeRecords[i];
      switch(record.type) {
        case ARRAY_SPLICE_TYPE:
          mergeSplice(splices, record.index, record.removed.slice(), record.addedCount);
          break;
        case PROP_ADD_TYPE:
        case PROP_UPDATE_TYPE:
        case PROP_DELETE_TYPE:
          if (!isIndex(record.name))
            continue;
          var index = toNumber(record.name);
          if (index < 0)
            continue;
          mergeSplice(splices, index, [record.oldValue], 1);
          break;
        default:
          console.error('Unexpected record type: ' + JSON.stringify(record));
          break;
      }
    }

    return splices;
  }

  function projectArraySplices(array, changeRecords) {
    var splices = [];

    createInitialSplices(array, changeRecords).forEach(function(splice) {
      if (splice.addedCount == 1 && splice.removed.length == 1) {
        if (splice.removed[0] !== array[splice.index])
          splices.push(splice);

        return
      };

      splices = splices.concat(calcSplices(array, splice.index, splice.index + splice.addedCount,
                                           splice.removed, 0, splice.removed.length));
    });

    return splices;
  }

  global.Observer = Observer;
  global.Observer.hasObjectObserve = hasObserve;
  global.ArrayObserver = ArrayObserver;
  global.ArrayObserver.calculateSplices = function(current, previous) {
    return arraySplice.calculateSplices(current, previous);
  };

  global.ArraySplice = ArraySplice;
  global.ObjectObserver = ObjectObserver;
  global.PathObserver = PathObserver;
  global.CompoundPathObserver = CompoundPathObserver;
  global.Path = Path;

  // TODO(rafaelw): Only needed for testing until new change record names
  // make it to release.
  global.Observer.changeRecordTypes = {
    add: PROP_ADD_TYPE,
    update: PROP_UPDATE_TYPE,
    reconfigure: PROP_RECONFIGURE_TYPE,
    'delete': PROP_DELETE_TYPE,
    splice: ARRAY_SPLICE_TYPE
  };
})(typeof global !== 'undefined' && global ? global : this || window);

/*
 * Copyright 2012 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

if (typeof WeakMap === 'undefined') {
  (function() {
    var defineProperty = Object.defineProperty;
    var counter = Date.now() % 1e9;

    var WeakMap = function() {
      this.name = '__st' + (Math.random() * 1e9 >>> 0) + (counter++ + '__');
    };

    WeakMap.prototype = {
      set: function(key, value) {
        var entry = key[this.name];
        if (entry && entry[0] === key)
          entry[1] = value;
        else
          defineProperty(key, this.name, {value: [key, value], writable: true});
      },
      get: function(key) {
        var entry;
        return (entry = key[this.name]) && entry[0] === key ?
            entry[1] : undefined;
      },
      delete: function(key) {
        this.set(key, undefined);
      }
    };

    window.WeakMap = WeakMap;
  })();
}

// Copyright 2012 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

window.ShadowDOMPolyfill = {};

(function(scope) {
  'use strict';

  var constructorTable = new WeakMap();
  var nativePrototypeTable = new WeakMap();
  var wrappers = Object.create(null);

  // Don't test for eval if document has CSP securityPolicy object and we can
  // see that eval is not supported. This avoids an error message in console
  // even when the exception is caught
  var hasEval = !('securityPolicy' in document) ||
      document.securityPolicy.allowsEval;
  if (hasEval) {
    try {
      var f = new Function('', 'return true;');
      hasEval = f();
    } catch (ex) {
      hasEval = false;
    }
  }

  function assert(b) {
    if (!b)
      throw new Error('Assertion failed');
  };

  var defineProperty = Object.defineProperty;
  var getOwnPropertyNames = Object.getOwnPropertyNames;
  var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;

  function mixin(to, from) {
    getOwnPropertyNames(from).forEach(function(name) {
      defineProperty(to, name, getOwnPropertyDescriptor(from, name));
    });
    return to;
  };

  function mixinStatics(to, from) {
    getOwnPropertyNames(from).forEach(function(name) {
      switch (name) {
        case 'arguments':
        case 'caller':
        case 'length':
        case 'name':
        case 'prototype':
        case 'toString':
          return;
      }
      defineProperty(to, name, getOwnPropertyDescriptor(from, name));
    });
    return to;
  };

  function oneOf(object, propertyNames) {
    for (var i = 0; i < propertyNames.length; i++) {
      if (propertyNames[i] in object)
        return propertyNames[i];
    }
  }

  // Mozilla's old DOM bindings are bretty busted:
  // https://bugzilla.mozilla.org/show_bug.cgi?id=855844
  // Make sure they are create before we start modifying things.
  getOwnPropertyNames(window);

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

  function isEventHandlerName(name) {
    return /^on[a-z]+$/.test(name);
  }

  function isIdentifierName(name) {
    return /^\w[a-zA-Z_0-9]*$/.test(name);
  }

  function getGetter(name) {
    return hasEval && isIdentifierName(name) ?
        new Function('return this.impl.' + name) :
        function() { return this.impl[name]; };
  }

  function getSetter(name) {
    return hasEval && isIdentifierName(name) ?
        new Function('v', 'this.impl.' + name + ' = v') :
        function(v) { this.impl[name] = v; };
  }

  function getMethod(name) {
    return hasEval && isIdentifierName(name) ?
        new Function('return this.impl.' + name +
                     '.apply(this.impl, arguments)') :
        function() { return this.impl[name].apply(this.impl, arguments); };
  }

  function getDescriptor(source, name) {
    try {
      return Object.getOwnPropertyDescriptor(source, name);
    } catch (ex) {
      // JSC and V8 both use data properties instead of accessors which can
      // cause getting the property desciptor to throw an exception.
      // https://bugs.webkit.org/show_bug.cgi?id=49739
      return dummyDescriptor;
    }
  }

  function installProperty(source, target, allowMethod, opt_blacklist) {
    var names = getOwnPropertyNames(source);
    for (var i = 0; i < names.length; i++) {
      var name = names[i];
      if (name === 'polymerBlackList_')
        continue;

      if (name in target)
        continue;

      if (source.polymerBlackList_ && source.polymerBlackList_[name])
        continue;

      if (isFirefox) {
        // Tickle Firefox's old bindings.
        source.__lookupGetter__(name);
      }
      var descriptor = getDescriptor(source, name);
      var getter, setter;
      if (allowMethod && typeof descriptor.value === 'function') {
        target[name] = getMethod(name);
        continue;
      }

      var isEvent = isEventHandlerName(name);
      if (isEvent)
        getter = scope.getEventHandlerGetter(name);
      else
        getter = getGetter(name);

      if (descriptor.writable || descriptor.set) {
        if (isEvent)
          setter = scope.getEventHandlerSetter(name);
        else
          setter = getSetter(name);
      }

      defineProperty(target, name, {
        get: getter,
        set: setter,
        configurable: descriptor.configurable,
        enumerable: descriptor.enumerable
      });
    }
  }

  /**
   * @param {Function} nativeConstructor
   * @param {Function} wrapperConstructor
   * @param {Object=} opt_instance If present, this is used to extract
   *     properties from an instance object.
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
    nativePrototypeTable.set(wrapperPrototype, nativePrototype);

    addForwardingProperties(nativePrototype, wrapperPrototype);
    if (opt_instance)
      registerInstanceProperties(wrapperPrototype, opt_instance);
    defineProperty(wrapperPrototype, 'constructor', {
      value: wrapperConstructor,
      configurable: true,
      enumerable: false,
      writable: true
    });
  }

  function isWrapperFor(wrapperConstructor, nativeConstructor) {
    return constructorTable.get(nativeConstructor.prototype) ===
        wrapperConstructor;
  }

  /**
   * Creates a generic wrapper constructor based on |object| and its
   * constructor.
   * @param {Node} object
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

    return GeneratedWrapper;
  }

  var OriginalDOMImplementation = window.DOMImplementation;
  var OriginalEvent = window.Event;
  var OriginalNode = window.Node;
  var OriginalWindow = window.Window;
  var OriginalRange = window.Range;
  var OriginalCanvasRenderingContext2D = window.CanvasRenderingContext2D;
  var OriginalWebGLRenderingContext = window.WebGLRenderingContext;

  function isWrapper(object) {
    return object instanceof wrappers.EventTarget ||
           object instanceof wrappers.Event ||
           object instanceof wrappers.Range ||
           object instanceof wrappers.DOMImplementation ||
           object instanceof wrappers.CanvasRenderingContext2D ||
           wrappers.WebGLRenderingContext &&
               object instanceof wrappers.WebGLRenderingContext;
  }

  function isNative(object) {
    return object instanceof OriginalNode ||
           object instanceof OriginalEvent ||
           object instanceof OriginalWindow ||
           object instanceof OriginalRange ||
           object instanceof OriginalDOMImplementation ||
           object instanceof OriginalCanvasRenderingContext2D ||
           OriginalWebGLRenderingContext &&
               object instanceof OriginalWebGLRenderingContext;
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
    return impl.polymerWrapper_ ||
        (impl.polymerWrapper_ = new (getWrapperConstructor(impl))(impl));
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
    node.polymerWrapper_ = wrapper;
  }

  function defineGetter(constructor, name, getter) {
    defineProperty(constructor.prototype, name, {
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
          var w = wrapIfNeeded(this);
          return w[name].apply(w, arguments);
        };
      });
    });
  }

  scope.assert = assert;
  scope.constructorTable = constructorTable;
  scope.defineGetter = defineGetter;
  scope.defineWrapGetter = defineWrapGetter;
  scope.forwardMethodsToWrapper = forwardMethodsToWrapper;
  scope.isWrapperFor = isWrapperFor;
  scope.mixin = mixin;
  scope.nativePrototypeTable = nativePrototypeTable;
  scope.oneOf = oneOf;
  scope.registerObject = registerObject;
  scope.registerWrapper = register;
  scope.rewrap = rewrap;
  scope.unwrap = unwrap;
  scope.unwrapIfNeeded = unwrapIfNeeded;
  scope.wrap = wrap;
  scope.wrapIfNeeded = wrapIfNeeded;
  scope.wrappers = wrappers;

})(window.ShadowDOMPolyfill);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is goverened by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(context) {
  'use strict';

  var OriginalMutationObserver = window.MutationObserver;
  var callbacks = [];
  var pending = false;
  var timerFunc;

  function handle() {
    pending = false;
    var copies = callbacks.slice(0);
    callbacks = [];
    for (var i = 0; i < copies.length; i++) {
      (0, copies[i])();
    }
  }

  if (OriginalMutationObserver) {
    var counter = 1;
    var observer = new OriginalMutationObserver(handle);
    var textNode = document.createTextNode(counter);
    observer.observe(textNode, {characterData: true});

    timerFunc = function() {
      counter = (counter + 1) % 2;
      textNode.data = counter;
    };

  } else {
    timerFunc = window.setImmediate || window.setTimeout;
  }

  function setEndOfMicrotask(func) {
    callbacks.push(func);
    if (pending)
      return;
    pending = true;
    timerFunc(handle, 0);
  }

  context.setEndOfMicrotask = setEndOfMicrotask;

})(window.ShadowDOMPolyfill);

/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is goverened by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {
  'use strict';

  var setEndOfMicrotask = scope.setEndOfMicrotask
  var wrapIfNeeded = scope.wrapIfNeeded
  var wrappers = scope.wrappers;

  var registrationsTable = new WeakMap();
  var globalMutationObservers = [];
  var isScheduled = false;

  function scheduleCallback(observer) {
    if (isScheduled)
      return;
    setEndOfMicrotask(notifyObservers);
    isScheduled = true;
  }

  // http://dom.spec.whatwg.org/#mutation-observers
  function notifyObservers() {
    isScheduled = false;

    do {
      var notifyList = globalMutationObservers.slice();
      var anyNonEmpty = false;
      for (var i = 0; i < notifyList.length; i++) {
        var mo = notifyList[i];
        var queue = mo.takeRecords();
        removeTransientObserversFor(mo);
        if (queue.length) {
          mo.callback_(queue, mo);
          anyNonEmpty = true;
        }
      }
    } while (anyNonEmpty);
  }

  /**
   * @param {string} type
   * @param {Node} target
   * @constructor
   */
  function MutationRecord(type, target) {
    this.type = type;
    this.target = target;
    this.addedNodes = new wrappers.NodeList();
    this.removedNodes = new wrappers.NodeList();
    this.previousSibling = null;
    this.nextSibling = null;
    this.attributeName = null;
    this.attributeNamespace = null;
    this.oldValue = null;
  }

  /**
   * Registers transient observers to ancestor and its ancesors for the node
   * which was removed.
   * @param {!Node} ancestor
   * @param {!Node} node
   */
  function registerTransientObservers(ancestor, node) {
    for (; ancestor; ancestor = ancestor.parentNode) {
      var registrations = registrationsTable.get(ancestor);
      if (!registrations)
        continue;
      for (var i = 0; i < registrations.length; i++) {
        var registration = registrations[i];
        if (registration.options.subtree)
          registration.addTransientObserver(node);
      }
    }
  }

  function removeTransientObserversFor(observer) {
    for (var i = 0; i < observer.nodes_.length; i++) {
      var node = observer.nodes_[i];
      var registrations = registrationsTable.get(node);
      if (!registrations)
        return;
      for (var j = 0; j < registrations.length; j++) {
        var registration = registrations[j];
        if (registration.observer === observer)
          registration.removeTransientObservers();
      }
    }
  }

  // http://dom.spec.whatwg.org/#queue-a-mutation-record
  function enqueueMutation(target, type, data) {
    // 1.
    var interestedObservers = Object.create(null);
    var associatedStrings = Object.create(null);

    // 2.
    for (var node = target; node; node = node.parentNode) {
      // 3.
      var registrations = registrationsTable.get(node);
      if (!registrations)
        continue;
      for (var j = 0; j < registrations.length; j++) {
        var registration = registrations[j];
        var options = registration.options;
        // 1.
        if (node !== target && !options.subtree)
          continue;

        // 2.
        if (type === 'attributes' && !options.attributes)
          continue;

        // 3. If type is "attributes", options's attributeFilter is present, and
        // either options's attributeFilter does not contain name or namespace
        // is non-null, continue.
        if (type === 'attributes' && options.attributeFilter &&
            (data.namespace !== null ||
             options.attributeFilter.indexOf(data.name) === -1)) {
          continue;
        }

        // 4.
        if (type === 'characterData' && !options.characterData)
          continue;

        // 5.
        if (type === 'childList' && !options.childList)
          continue;

        // 6.
        var observer = registration.observer;
        interestedObservers[observer.uid_] = observer;

        // 7. If either type is "attributes" and options's attributeOldValue is
        // true, or type is "characterData" and options's characterDataOldValue
        // is true, set the paired string of registered observer's observer in
        // interested observers to oldValue.
        if (type === 'attributes' && options.attributeOldValue ||
            type === 'characterData' && options.characterDataOldValue) {
          associatedStrings[observer.uid_] = data.oldValue;
        }
      }
    }

    var anyRecordsEnqueued = false;

    // 4.
    for (var uid in interestedObservers) {
      var observer = interestedObservers[uid];
      var record = new MutationRecord(type, target);

      // 2.
      if ('name' in data && 'namespace' in data) {
        record.attributeName = data.name;
        record.attributeNamespace = data.namespace;
      }

      // 3.
      if (data.addedNodes)
        record.addedNodes = data.addedNodes;

      // 4.
      if (data.removedNodes)
        record.removedNodes = data.removedNodes;

      // 5.
      if (data.previousSibling)
        record.previousSibling = data.previousSibling;

      // 6.
      if (data.nextSibling)
        record.nextSibling = data.nextSibling;

      // 7.
      if (associatedStrings[uid] !== undefined)
        record.oldValue = associatedStrings[uid];

      // 8.
      observer.records_.push(record);

      anyRecordsEnqueued = true;
    }

    if (anyRecordsEnqueued)
      scheduleCallback();
  }

  var slice = Array.prototype.slice;

  /**
   * @param {!Object} options
   * @constructor
   */
  function MutationObserverOptions(options) {
    this.childList = !!options.childList;
    this.subtree = !!options.subtree;

    // 1. If either options' attributeOldValue or attributeFilter is present
    // and options' attributes is omitted, set options' attributes to true.
    if (!('attributes' in options) &&
        ('attributeOldValue' in options || 'attributeFilter' in options)) {
      this.attributes = true;
    } else {
      this.attributes = !!options.attributes;
    }

    // 2. If options' characterDataOldValue is present and options'
    // characterData is omitted, set options' characterData to true.
    if ('characterDataOldValue' in options && !('characterData' in options))
      this.characterData = true;
    else
      this.characterData = !!options.characterData;

    // 3. & 4.
    if (!this.attributes &&
        (options.attributeOldValue || 'attributeFilter' in options) ||
        // 5.
        !this.characterData && options.characterDataOldValue) {
      throw new TypeError();
    }

    this.characterData = !!options.characterData;
    this.attributeOldValue = !!options.attributeOldValue;
    this.characterDataOldValue = !!options.characterDataOldValue;
    if ('attributeFilter' in options) {
      if (options.attributeFilter == null ||
          typeof options.attributeFilter !== 'object') {
        throw new TypeError();
      }
      this.attributeFilter = slice.call(options.attributeFilter);
    } else {
      this.attributeFilter = null;
    }
  }

  var uidCounter = 0;

  /**
   * The class that maps to the DOM MutationObserver interface.
   * @param {Function} callback.
   * @constructor
   */
  function MutationObserver(callback) {
    this.callback_ = callback;
    this.nodes_ = [];
    this.records_ = [];
    this.uid_ = ++uidCounter;

    // This will leak. There is no way to implement this without WeakRefs :'(
    globalMutationObservers.push(this);
  }

  MutationObserver.prototype = {
    // http://dom.spec.whatwg.org/#dom-mutationobserver-observe
    observe: function(target, options) {
      target = wrapIfNeeded(target);

      var newOptions = new MutationObserverOptions(options);

      // 6.
      var registration;
      var registrations = registrationsTable.get(target);
      if (!registrations)
        registrationsTable.set(target, registrations = []);

      for (var i = 0; i < registrations.length; i++) {
        if (registrations[i].observer === this) {
          registration = registrations[i];
          // 6.1.
          registration.removeTransientObservers();
          // 6.2.
          registration.options = newOptions;
        }
      }

      // 7.
      if (!registration) {
        registration = new Registration(this, target, newOptions);
        registrations.push(registration);
        this.nodes_.push(target);
      }
    },

    // http://dom.spec.whatwg.org/#dom-mutationobserver-disconnect
    disconnect: function() {
      this.nodes_.forEach(function(node) {
        var registrations = registrationsTable.get(node);
        for (var i = 0; i < registrations.length; i++) {
          var registration = registrations[i];
          if (registration.observer === this) {
            registrations.splice(i, 1);
            // Each node can only have one registered observer associated with
            // this observer.
            break;
          }
        }
      }, this);
      this.records_ = [];
    },

    takeRecords: function() {
      var copyOfRecords = this.records_;
      this.records_ = [];
      return copyOfRecords;
    }
  };

  /**
   * Class used to represent a registered observer.
   * @param {MutationObserver} observer
   * @param {Node} target
   * @param {MutationObserverOptions} options
   * @constructor
   */
  function Registration(observer, target, options) {
    this.observer = observer;
    this.target = target;
    this.options = options;
    this.transientObservedNodes = [];
  }

  Registration.prototype = {
    /**
     * Adds a transient observer on node. The transient observer gets removed
     * next time we deliver the change records.
     * @param {Node} node
     */
    addTransientObserver: function(node) {
      // Don't add transient observers on the target itself. We already have all
      // the required listeners set up on the target.
      if (node === this.target)
        return;

      this.transientObservedNodes.push(node);
      var registrations = registrationsTable.get(node);
      if (!registrations)
        registrationsTable.set(node, registrations = []);

      // We know that registrations does not contain this because we already
      // checked if node === this.target.
      registrations.push(this);
    },

    removeTransientObservers: function() {
      var transientObservedNodes = this.transientObservedNodes;
      this.transientObservedNodes = [];

      for (var i = 0; i < transientObservedNodes.length; i++) {
        var node = transientObservedNodes[i];
        var registrations = registrationsTable.get(node);
        for (var j = 0; j < registrations.length; j++) {
          if (registrations[j] === this) {
            registrations.splice(j, 1);
            // Each node can only have one registered observer associated with
            // this observer.
            break;
          }
        }
      }
    }
  };

  scope.enqueueMutation = enqueueMutation;
  scope.registerTransientObservers = registerTransientObservers;
  scope.wrappers.MutationObserver = MutationObserver;
  scope.wrappers.MutationRecord = MutationRecord;

})(window.ShadowDOMPolyfill);

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

  var wrappedFuns = new WeakMap();
  var listenersTable = new WeakMap();
  var handledEventsTable = new WeakMap();
  var targetTable = new WeakMap();
  var currentTargetTable = new WeakMap();
  var relatedTargetTable = new WeakMap();
  var eventPhaseTable = new WeakMap();
  var stopPropagationTable = new WeakMap();
  var stopImmediatePropagationTable = new WeakMap();
  var eventHandlersTable = new WeakMap();
  var eventPathTable = new WeakMap();

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
      return getInsertionParent(node) || node.host;

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
        var p = getInsertionParent(context);
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
        target = target.host;
      else
        target = target.parentNode;  // 3.6.
    }
  }

  function getInsertionParent(node) {
    return scope.insertionParentTable.get(node);
  }

  function isDistributed(node) {
    return getInsertionParent(node);
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

  function enclosedBy(a, b) {
    if (a === b)
      return true;
    if (a instanceof wrappers.ShadowRoot)
      return enclosedBy(rootOfNode(a.host), b);
    return false;
  }


  function dispatchOriginalEvent(originalEvent) {
    // Make sure this event is only dispatched once.
    if (handledEventsTable.get(originalEvent))
      return;
    handledEventsTable.set(originalEvent, true);

    // Render before dispatching the event to ensure that the event path is
    // correct.
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
    // TODO(arv): Find a less hacky way to do this.
    if (event.type === 'load' &&
        eventPath.length === 2 &&
        eventPath[0].target instanceof wrappers.Document) {
      eventPath.shift();
    }

    eventPathTable.set(event, eventPath);

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
      // X-Tag sets relatedTarget on a CustomEvent. If they do that there is no
      // way to have relatedTarget return the adjusted target but worse is that
      // the originalEvent might not have a relatedTarget so we hit an assert
      // when we try to wrap it.
      if (originalEvent.relatedTarget) {
        var relatedTarget = wrap(originalEvent.relatedTarget);

        var adjusted = adjustRelatedTarget(currentTarget, relatedTarget);
        if (adjusted === target)
          return true;

        relatedTargetTable.set(event, adjusted);
      }
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
          console.error(ex, ex.stack);
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
  OriginalEvent.prototype.polymerBlackList_ = {returnValue: true};

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
    get path() {
      var nodeList = new wrappers.NodeList();
      var eventPath = eventPathTable.get(this);
      if (eventPath) {
        var index = 0;
        var lastIndex = eventPath.length - 1;
        var baseRoot = rootOfNode(currentTargetTable.get(this));

        for (var i = 0; i <= lastIndex; i++) {
          var currentTarget = eventPath[i].currentTarget;
          var currentRoot = rootOfNode(currentTarget);
          if (enclosedBy(baseRoot, currentRoot) &&
              // Make sure we do not add Window to the path.
              (i !== lastIndex || currentTarget instanceof wrappers.Node)) {
            nodeList[index++] = currentTarget;
          }
        }
        nodeList.length = index;
      }
      return nodeList;
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
    if (OriginalEvent) {
      // IE does not support event constructors but FocusEvent can only be
      // created using new FocusEvent in Firefox.
      // https://bugzilla.mozilla.org/show_bug.cgi?id=882165
      if (OriginalEvent.prototype['init' + name]) {
        registerWrapper(OriginalEvent, GenericEvent,
                        document.createEvent(name));
      } else {
        registerWrapper(OriginalEvent, GenericEvent, new OriginalEvent('temp'));
      }
    }
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

  function BeforeUnloadEvent(impl) {
    Event.call(this);
  }
  BeforeUnloadEvent.prototype = Object.create(Event.prototype);
  mixin(BeforeUnloadEvent.prototype, {
    get returnValue() {
      return this.impl.returnValue;
    },
    set returnValue(v) {
      this.impl.returnValue = v;
    }
  });

  function isValidListener(fun) {
    if (typeof fun === 'function')
      return true;
    return fun && fun.handleEvent;
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

  [Node, Window].forEach(function(constructor) {
    var p = constructor.prototype;
    methodNames.forEach(function(name) {
      Object.defineProperty(p, name + '_', {value: p[name]});
    });
  });

  function getTargetToListenAt(wrapper) {
    if (wrapper instanceof wrappers.ShadowRoot)
      wrapper = wrapper.host;
    return unwrap(wrapper);
  }

  EventTarget.prototype = {
    addEventListener: function(type, fun, capture) {
      if (!isValidListener(fun) || isMutationEvent(type))
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
      var target = getTargetToListenAt(this);
      var nativeEvent = unwrap(event);
      // Allow dispatching the same event again. This is safe because if user
      // code calls this during an existing dispatch of the same event the
      // native dispatchEvent throws (that is required by the spec).
      handledEventsTable.set(nativeEvent, false);
      return target.dispatchEvent_(nativeEvent);
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

  /**
   * Returns a function that is to be used as a getter for `onfoo` properties.
   * @param {string} name
   * @return {Function}
   */
  function getEventHandlerGetter(name) {
    return function() {
      var inlineEventHandlers = eventHandlersTable.get(this);
      return inlineEventHandlers && inlineEventHandlers[name] &&
          inlineEventHandlers[name].value || null;
     };
  }

  /**
   * Returns a function that is to be used as a setter for `onfoo` properties.
   * @param {string} name
   * @return {Function}
   */
  function getEventHandlerSetter(name) {
    var eventType = name.slice(2);
    return function(value) {
      var inlineEventHandlers = eventHandlersTable.get(this);
      if (!inlineEventHandlers) {
        inlineEventHandlers = Object.create(null);
        eventHandlersTable.set(this, inlineEventHandlers);
      }

      var old = inlineEventHandlers[name];
      if (old)
        this.removeEventListener(eventType, old.wrapped, false);

      if (typeof value === 'function') {
        var wrapped = function(e) {
          var rv = value.call(this, e);
          if (rv === false)
            e.preventDefault();
          else if (name === 'onbeforeunload' && typeof rv === 'string')
            e.returnValue = rv;
          // mouseover uses true for preventDefault but preventDefault for
          // mouseover is ignored by browsers these day.
        };

        this.addEventListener(eventType, wrapped, false);
        inlineEventHandlers[name] = {
          value: value,
          wrapped: wrapped
        };
      }
    };
  }

  scope.adjustRelatedTarget = adjustRelatedTarget;
  scope.elementFromPoint = elementFromPoint;
  scope.getEventHandlerGetter = getEventHandlerGetter;
  scope.getEventHandlerSetter = getEventHandlerSetter;
  scope.wrapEventTargetMethods = wrapEventTargetMethods;
  scope.wrappers.BeforeUnloadEvent = BeforeUnloadEvent;
  scope.wrappers.CustomEvent = CustomEvent;
  scope.wrappers.Event = Event;
  scope.wrappers.EventTarget = EventTarget;
  scope.wrappers.FocusEvent = FocusEvent;
  scope.wrappers.MouseEvent = MouseEvent;
  scope.wrappers.UIEvent = UIEvent;

})(window.ShadowDOMPolyfill);

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

})(window.ShadowDOMPolyfill);

// Copyright 2012 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var EventTarget = scope.wrappers.EventTarget;
  var NodeList = scope.wrappers.NodeList;
  var assert = scope.assert;
  var defineWrapGetter = scope.defineWrapGetter;
  var enqueueMutation = scope.enqueueMutation;
  var mixin = scope.mixin;
  var registerTransientObservers = scope.registerTransientObservers;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;
  var wrapIfNeeded = scope.wrapIfNeeded;

  function assertIsNodeWrapper(node) {
    assert(node instanceof Node);
  }

  function createOneElementNodeList(node) {
    var nodes = new NodeList();
    nodes[0] = node;
    nodes.length = 1;
    return nodes;
  }

  var surpressMutations = false;

  /**
   * Called before node is inserted into a node to enqueue its removal from its
   * old parent.
   * @param {!Node} node The node that is about to be removed.
   * @param {!Node} parent The parent node that the node is being removed from.
   * @param {!NodeList} nodes The collected nodes.
   */
  function enqueueRemovalForInsertedNodes(node, parent, nodes) {
    enqueueMutation(parent, 'childList', {
      removedNodes: nodes,
      previousSibling: node.previousSibling,
      nextSibling: node.nextSibling
    });
  }

  function enqueueRemovalForInsertedDocumentFragment(df, nodes) {
    enqueueMutation(df, 'childList', {
      removedNodes: nodes
    });
  }

  /**
   * Collects nodes from a DocumentFragment or a Node for removal followed
   * by an insertion.
   *
   * This updates the internal pointers for node, previousNode and nextNode.
   */
  function collectNodes(node, parentNode, previousNode, nextNode) {
    if (node instanceof DocumentFragment) {
      var nodes = collectNodesForDocumentFragment(node);

      // The extra loop is to work around bugs with DocumentFragments in IE.
      surpressMutations = true;
      for (var i = nodes.length - 1; i >= 0; i--) {
        node.removeChild(nodes[i]);
        nodes[i].parentNode_ = parentNode;
      }
      surpressMutations = false;

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

    var nodes = createOneElementNodeList(node);
    var oldParent = node.parentNode;
    if (oldParent) {
      // This will enqueue the mutation record for the removal as needed.
      oldParent.removeChild(node);
    }

    node.parentNode_ = parentNode;
    node.previousSibling_ = previousNode;
    node.nextSibling_ = nextNode;
    if (previousNode)
      previousNode.nextSibling_ = node;
    if (nextNode)
      nextNode.previousSibling_ = node;

    return nodes;
  }

  function collectNodesNative(node) {
    if (node instanceof DocumentFragment)
      return collectNodesForDocumentFragment(node);

    var nodes = createOneElementNodeList(node);
    var oldParent = node.parentNode;
    if (oldParent)
      enqueueRemovalForInsertedNodes(node, oldParent, nodes);
    return nodes;
  }

  function collectNodesForDocumentFragment(node) {
    var nodes = new NodeList();
    var i = 0;
    for (var child = node.firstChild; child; child = child.nextSibling) {
      nodes[i++] = child;
    }
    nodes.length = i;
    enqueueRemovalForInsertedDocumentFragment(node, nodes);
    return nodes;
  }

  function snapshotNodeList(nodeList) {
    // NodeLists are not live at the moment so just return the same object.
    return nodeList;
  }

  // http://dom.spec.whatwg.org/#node-is-inserted
  function nodeWasAdded(node) {
    node.nodeIsInserted_();
  }

  function nodesWereAdded(nodes) {
    for (var i = 0; i < nodes.length; i++) {
      nodeWasAdded(nodes[i]);
    }
  }

  // http://dom.spec.whatwg.org/#node-is-removed
  function nodeWasRemoved(node) {
    // Nothing at this point in time.
  }

  function nodesWereRemoved(nodes) {
    // Nothing at this point in time.
  }

  function ensureSameOwnerDocument(parent, child) {
    var ownerDoc = parent.nodeType === Node.DOCUMENT_NODE ?
        parent : parent.ownerDocument;
    if (ownerDoc !== child.ownerDocument)
      ownerDoc.adoptNode(child);
  }

  function adoptNodesIfNeeded(owner, nodes) {
    if (!nodes.length)
      return;

    var ownerDoc = owner.ownerDocument;

    // All nodes have the same ownerDocument when we get here.
    if (ownerDoc === nodes[0].ownerDocument)
      return;

    for (var i = 0; i < nodes.length; i++) {
      scope.adoptNodeNoRemove(nodes[i], ownerDoc);
    }
  }

  function unwrapNodesForInsertion(owner, nodes) {
    adoptNodesIfNeeded(owner, nodes);
    var length = nodes.length;

    if (length === 1)
      return unwrap(nodes[0]);

    var df = unwrap(owner.ownerDocument.createDocumentFragment());
    for (var i = 0; i < length; i++) {
      df.appendChild(unwrap(nodes[i]));
    }
    return df;
  }

  function removeAllChildNodes(wrapper) {
    if (wrapper.invalidateShadowRenderer()) {
      var childWrapper = wrapper.firstChild;
      while (childWrapper) {
        assert(childWrapper.parentNode === wrapper);
        var nextSibling = childWrapper.nextSibling;
        var childNode = unwrap(childWrapper);
        var parentNode = childNode.parentNode;
        if (parentNode)
          originalRemoveChild.call(parentNode, childNode);
        childWrapper.previousSibling_ = childWrapper.nextSibling_ =
            childWrapper.parentNode_ = null;
        childWrapper = nextSibling;
      }
      wrapper.firstChild_ = wrapper.lastChild_ = null;
    } else {
      var node = unwrap(wrapper);
      var child = node.firstChild;
      var nextSibling;
      while (child) {
        nextSibling = child.nextSibling;
        originalRemoveChild.call(node, child);
        child = nextSibling;
      }
    }
  }

  function invalidateParent(node) {
    var p = node.parentNode;
    return p && p.invalidateShadowRenderer();
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

  var OriginalDocumentFragment = window.DocumentFragment;
  var originalAppendChild = OriginalNode.prototype.appendChild;
  var originalCompareDocumentPosition =
      OriginalNode.prototype.compareDocumentPosition;
  var originalInsertBefore = OriginalNode.prototype.insertBefore;
  var originalRemoveChild = OriginalNode.prototype.removeChild;
  var originalReplaceChild = OriginalNode.prototype.replaceChild;

  var isIe = /Trident/.test(navigator.userAgent);

  var removeChildOriginalHelper = isIe ?
      function(parent, child) {
        try {
          originalRemoveChild.call(parent, child);
        } catch (ex) {
          if (!(parent instanceof OriginalDocumentFragment))
            throw ex;
        }
      } :
      function(parent, child) {
        originalRemoveChild.call(parent, child);
      };

  Node.prototype = Object.create(EventTarget.prototype);
  mixin(Node.prototype, {
    appendChild: function(childWrapper) {
      return this.insertBefore(childWrapper, null);
    },

    insertBefore: function(childWrapper, refWrapper) {
      assertIsNodeWrapper(childWrapper);

      refWrapper = refWrapper || null;
      refWrapper && assertIsNodeWrapper(refWrapper);
      refWrapper && assert(refWrapper.parentNode === this);

      var nodes;
      var previousNode =
          refWrapper ? refWrapper.previousSibling : this.lastChild;

      var useNative = !this.invalidateShadowRenderer() &&
                      !invalidateParent(childWrapper);

      if (useNative)
        nodes = collectNodesNative(childWrapper);
      else
        nodes = collectNodes(childWrapper, this, previousNode, refWrapper);

      if (useNative) {
        ensureSameOwnerDocument(this, childWrapper);
        originalInsertBefore.call(this.impl, unwrap(childWrapper),
                                  unwrap(refWrapper));
      } else {
        if (!previousNode)
          this.firstChild_ = nodes[0];
        if (!refWrapper)
          this.lastChild_ = nodes[nodes.length - 1];

        var refNode = unwrap(refWrapper);
        var parentNode = refNode ? refNode.parentNode : this.impl;

        // insertBefore refWrapper no matter what the parent is?
        if (parentNode) {
          originalInsertBefore.call(parentNode,
              unwrapNodesForInsertion(this, nodes), refNode);
        } else {
          adoptNodesIfNeeded(this, nodes);
        }
      }

      enqueueMutation(this, 'childList', {
        addedNodes: nodes,
        nextSibling: refWrapper,
        previousSibling: previousNode
      });

      nodesWereAdded(nodes);

      return childWrapper;
    },

    removeChild: function(childWrapper) {
      assertIsNodeWrapper(childWrapper);
      if (childWrapper.parentNode !== this) {
        // IE has invalid DOM trees at times.
        var found = false;
        var childNodes = this.childNodes;
        for (var ieChild = this.firstChild; ieChild;
             ieChild = ieChild.nextSibling) {
          if (ieChild === childWrapper) {
            found = true;
            break;
          }
        }
        if (!found) {
          // TODO(arv): DOMException
          throw new Error('NotFoundError');
        }
      }

      var childNode = unwrap(childWrapper);
      var childWrapperNextSibling = childWrapper.nextSibling;
      var childWrapperPreviousSibling = childWrapper.previousSibling;

      if (this.invalidateShadowRenderer()) {
        // We need to remove the real node from the DOM before updating the
        // pointers. This is so that that mutation event is dispatched before
        // the pointers have changed.
        var thisFirstChild = this.firstChild;
        var thisLastChild = this.lastChild;

        var parentNode = childNode.parentNode;
        if (parentNode)
          removeChildOriginalHelper(parentNode, childNode);

        if (thisFirstChild === childWrapper)
          this.firstChild_ = childWrapperNextSibling;
        if (thisLastChild === childWrapper)
          this.lastChild_ = childWrapperPreviousSibling;
        if (childWrapperPreviousSibling)
          childWrapperPreviousSibling.nextSibling_ = childWrapperNextSibling;
        if (childWrapperNextSibling) {
          childWrapperNextSibling.previousSibling_ =
              childWrapperPreviousSibling;
        }

        childWrapper.previousSibling_ = childWrapper.nextSibling_ =
            childWrapper.parentNode_ = undefined;
      } else {
        removeChildOriginalHelper(this.impl, childNode);
      }

      if (!surpressMutations) {
        enqueueMutation(this, 'childList', {
          removedNodes: createOneElementNodeList(childWrapper),
          nextSibling: childWrapperNextSibling,
          previousSibling: childWrapperPreviousSibling
        });
      }

      registerTransientObservers(this, childWrapper);

      return childWrapper;
    },

    replaceChild: function(newChildWrapper, oldChildWrapper) {
      assertIsNodeWrapper(newChildWrapper);
      assertIsNodeWrapper(oldChildWrapper);

      if (oldChildWrapper.parentNode !== this) {
        // TODO(arv): DOMException
        throw new Error('NotFoundError');
      }

      var oldChildNode = unwrap(oldChildWrapper);
      var nextNode = oldChildWrapper.nextSibling;
      var previousNode = oldChildWrapper.previousSibling;
      var nodes;

      var useNative = !this.invalidateShadowRenderer() &&
                      !invalidateParent(newChildWrapper);

      if (useNative) {
        nodes = collectNodesNative(newChildWrapper);
      } else {
        if (nextNode === newChildWrapper)
          nextNode = newChildWrapper.nextSibling;
        nodes = collectNodes(newChildWrapper, this, previousNode, nextNode);
      }

      if (!useNative) {
        if (this.firstChild === oldChildWrapper)
          this.firstChild_ = nodes[0];
        if (this.lastChild === oldChildWrapper)
          this.lastChild_ = nodes[nodes.length - 1];

        oldChildWrapper.previousSibling_ = oldChildWrapper.nextSibling_ =
            oldChildWrapper.parentNode_ = undefined;

        // replaceChild no matter what the parent is?
        if (oldChildNode.parentNode) {
          originalReplaceChild.call(
              oldChildNode.parentNode,
              unwrapNodesForInsertion(this, nodes),
              oldChildNode);
        }
      } else {
        ensureSameOwnerDocument(this, newChildWrapper);
        originalReplaceChild.call(this.impl, unwrap(newChildWrapper),
                                  oldChildNode);
      }

      enqueueMutation(this, 'childList', {
        addedNodes: nodes,
        removedNodes: createOneElementNodeList(oldChildWrapper),
        nextSibling: nextNode,
        previousSibling: previousNode
      });

      nodeWasRemoved(oldChildWrapper);
      nodesWereAdded(nodes);

      return oldChildWrapper;
    },

    /**
     * Called after a node was inserted. Subclasses override this to invalidate
     * the renderer as needed.
     * @private
     */
    nodeIsInserted_: function() {
      for (var child = this.firstChild; child; child = child.nextSibling) {
        child.nodeIsInserted_();
      }
    },

    hasChildNodes: function() {
      return this.firstChild !== null;
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
      var removedNodes = snapshotNodeList(this.childNodes);

      if (this.invalidateShadowRenderer()) {
        removeAllChildNodes(this);
        if (textContent !== '') {
          var textNode = this.impl.ownerDocument.createTextNode(textContent);
          this.appendChild(textNode);
        }
      } else {
        this.impl.textContent = textContent;
      }

      var addedNodes = snapshotNodeList(this.childNodes);

      enqueueMutation(this, 'childList', {
        addedNodes: addedNodes,
        removedNodes: removedNodes
      });

      nodesWereRemoved(removedNodes);
      nodesWereAdded(addedNodes);
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
      var clone = wrap(this.impl.cloneNode(false));
      if (deep) {
        for (var child = this.firstChild; child; child = child.nextSibling) {
          clone.appendChild(child.cloneNode(true));
        }
      }
      // TODO(arv): Some HTML elements also clone other data like value.
      return clone;
    },

    contains: function(child) {
      if (!child)
        return false;

      child = wrapIfNeeded(child);

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
    }
  });

  defineWrapGetter(Node, 'ownerDocument');

  // We use a DocumentFragment as a base and then delete the properties of
  // DocumentFragment.prototype from the wrapper Node. Since delete makes
  // objects slow in some JS engines we recreate the prototype object.
  registerWrapper(OriginalNode, Node, document.createDocumentFragment());
  delete Node.prototype.querySelector;
  delete Node.prototype.querySelectorAll;
  Node.prototype = mixin(Object.create(EventTarget.prototype), Node.prototype);

  scope.nodeWasAdded = nodeWasAdded;
  scope.nodeWasRemoved = nodeWasRemoved;
  scope.nodesWereAdded = nodesWereAdded;
  scope.nodesWereRemoved = nodesWereRemoved;
  scope.snapshotNodeList = snapshotNodeList;
  scope.wrappers.Node = Node;

})(window.ShadowDOMPolyfill);

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

})(window.ShadowDOMPolyfill);

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
      return backwardsElement(this.previousSibling);
    }
  };

  scope.ChildNodeInterface = ChildNodeInterface;
  scope.ParentNodeInterface = ParentNodeInterface;

})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var ChildNodeInterface = scope.ChildNodeInterface;
  var Node = scope.wrappers.Node;
  var enqueueMutation = scope.enqueueMutation;
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
    },
    get data() {
      return this.impl.data;
    },
    set data(value) {
      var oldValue = this.impl.data;
      enqueueMutation(this, 'characterData', {
        oldValue: oldValue
      });
      this.impl.data = value;
    }
  });

  mixin(CharacterData.prototype, ChildNodeInterface);

  registerWrapper(OriginalCharacterData, CharacterData,
                  document.createTextNode(''));

  scope.wrappers.CharacterData = CharacterData;
})(window.ShadowDOMPolyfill);

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
  var enqueueMutation = scope.enqueueMutation;
  var mixin = scope.mixin;
  var oneOf = scope.oneOf;
  var registerWrapper = scope.registerWrapper;
  var wrappers = scope.wrappers;

  var OriginalElement = window.Element;

  var matchesName = oneOf(OriginalElement.prototype, [
    'matches',
    'mozMatchesSelector',
    'msMatchesSelector',
    'webkitMatchesSelector',
  ]);

  var originalMatches = OriginalElement.prototype[matchesName];

  function invalidateRendererBasedOnAttribute(element, name) {
    // Only invalidate if parent node is a shadow host.
    var p = element.parentNode;
    if (!p || !p.shadowRoot)
      return;

    var renderer = scope.getRendererForHost(p);
    if (renderer.dependsOnAttribute(name))
      renderer.invalidate();
  }

  function enqueAttributeChange(element, name, oldValue) {
    // This is not fully spec compliant. We should use localName (which might
    // have a different case than name) and the namespace (which requires us
    // to get the Attr object).
    enqueueMutation(element, 'attributes', {
      name: name,
      namespace: null,
      oldValue: oldValue
    });
  }

  function Element(node) {
    Node.call(this, node);
  }
  Element.prototype = Object.create(Node.prototype);
  mixin(Element.prototype, {
    createShadowRoot: function() {
      var newShadowRoot = new wrappers.ShadowRoot(this);
      this.impl.polymerShadowRoot_ = newShadowRoot;

      var renderer = scope.getRendererForHost(this);
      renderer.invalidate();

      return newShadowRoot;
    },

    get shadowRoot() {
      return this.impl.polymerShadowRoot_ || null;
    },

    setAttribute: function(name, value) {
      var oldValue = this.impl.getAttribute(name);
      this.impl.setAttribute(name, value);
      enqueAttributeChange(this, name, oldValue);
      invalidateRendererBasedOnAttribute(this, name);
    },

    removeAttribute: function(name) {
      var oldValue = this.impl.getAttribute(name);
      this.impl.removeAttribute(name);
      enqueAttributeChange(this, name, oldValue);
      invalidateRendererBasedOnAttribute(this, name);
    },

    matches: function(selector) {
      return originalMatches.call(this.impl, selector);
    }
  });

  Element.prototype[matchesName] = function(selector) {
    return this.matches(selector);
  };

  if (OriginalElement.prototype.webkitCreateShadowRoot) {
    Element.prototype.webkitCreateShadowRoot =
        Element.prototype.createShadowRoot;
  }

  /**
   * Useful for generating the accessor pair for a property that reflects an
   * attribute.
   */
  function setterDirtiesAttribute(prototype, propertyName, opt_attrName) {
    var attrName = opt_attrName || propertyName;
    Object.defineProperty(prototype, propertyName, {
      get: function() {
        return this.impl[propertyName];
      },
      set: function(v) {
        this.impl[propertyName] = v;
        invalidateRendererBasedOnAttribute(this, attrName);
      },
      configurable: true,
      enumerable: true
    });
  }

  setterDirtiesAttribute(Element.prototype, 'id');
  setterDirtiesAttribute(Element.prototype, 'className', 'class');

  mixin(Element.prototype, ChildNodeInterface);
  mixin(Element.prototype, GetElementsByInterface);
  mixin(Element.prototype, ParentNodeInterface);
  mixin(Element.prototype, SelectorsInterface);

  registerWrapper(OriginalElement, Element);

  // TODO(arv): Export setterDirtiesAttribute and apply it to more bindings
  // that reflect attributes.
  scope.matchesName = matchesName;
  scope.wrappers.Element = Element;
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var Element = scope.wrappers.Element;
  var defineGetter = scope.defineGetter;
  var enqueueMutation = scope.enqueueMutation;
  var mixin = scope.mixin;
  var nodesWereAdded = scope.nodesWereAdded;
  var nodesWereRemoved = scope.nodesWereRemoved;
  var registerWrapper = scope.registerWrapper;
  var snapshotNodeList = scope.snapshotNodeList;
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
    var tempElement = unwrap(node.ownerDocument.createElement(tagName));
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
      var removedNodes = snapshotNodeList(this.childNodes);

      if (this.invalidateShadowRenderer())
        setInnerHTML(this, value, this.tagName);
      else
        this.impl.innerHTML = value;
      var addedNodes = snapshotNodeList(this.childNodes);

      enqueueMutation(this, 'childList', {
        addedNodes: addedNodes,
        removedNodes: removedNodes
      });

      nodesWereRemoved(removedNodes);
      nodesWereAdded(addedNodes);
    },

    get outerHTML() {
      // TODO(arv): This should fallback to HTMLElement_prototype.outerHTML if there
      // are no shadow trees below or above the context node.
      return getOuterHTML(this);
    },
    set outerHTML(value) {
      var p = this.parentNode;
      if (p) {
        p.invalidateShadowRenderer();
        this.impl.outerHTML = value;
      }
    }
  });

  function getter(name) {
    return function() {
      scope.renderAllPending();
      return this.impl[name];
    };
  }

  function getterRequiresRendering(name) {
    defineGetter(HTMLElement, name, getter(name));
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
    'scrollWidth',
  ].forEach(getterRequiresRendering);

  function getterAndSetterRequiresRendering(name) {
    Object.defineProperty(HTMLElement.prototype, name, {
      get: getter(name),
      set: function(v) {
        scope.renderAllPending();
        this.impl[name] = v;
      },
      configurable: true,
      enumerable: true
    });
  }

  [
    'scrollLeft',
    'scrollTop',
  ].forEach(getterAndSetterRequiresRendering);

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
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var wrap = scope.wrap;

  var OriginalHTMLCanvasElement = window.HTMLCanvasElement;

  function HTMLCanvasElement(node) {
    HTMLElement.call(this, node);
  }
  HTMLCanvasElement.prototype = Object.create(HTMLElement.prototype);

  mixin(HTMLCanvasElement.prototype, {
    getContext: function() {
      var context = this.impl.getContext.apply(this.impl, arguments);
      return context && wrap(context);
    }
  });

  registerWrapper(OriginalHTMLCanvasElement, HTMLCanvasElement,
                  document.createElement('canvas'));

  scope.wrappers.HTMLCanvasElement = HTMLCanvasElement;
})(window.ShadowDOMPolyfill);

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
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var rewrap = scope.rewrap;

  var OriginalHTMLImageElement = window.HTMLImageElement;

  function HTMLImageElement(node) {
    HTMLElement.call(this, node);
  }
  HTMLImageElement.prototype = Object.create(HTMLElement.prototype);

  registerWrapper(OriginalHTMLImageElement, HTMLImageElement,
                  document.createElement('img'));

  function Image(width, height) {
    if (!(this instanceof Image)) {
      throw new TypeError(
          'DOM object constructor cannot be called as a function.');
    }

    var node = unwrap(document.createElement('img'));
    HTMLElement.call(this, node);
    rewrap(node, this);

    if (width !== undefined)
      node.width = width;
    if (height !== undefined)
      node.height = height;
  }

  Image.prototype = HTMLImageElement.prototype;

  scope.wrappers.HTMLImageElement = HTMLImageElement;
  scope.wrappers.Image = Image;
})(window.ShadowDOMPolyfill);

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
  }
  HTMLShadowElement.prototype = Object.create(HTMLElement.prototype);
  mixin(HTMLShadowElement.prototype, {
    // TODO: attribute boolean resetStyleInheritance;
  });

  if (OriginalHTMLShadowElement)
    registerWrapper(OriginalHTMLShadowElement, HTMLShadowElement);

  scope.wrappers.HTMLShadowElement = HTMLShadowElement;
})(window.ShadowDOMPolyfill);

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
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;

  var contentTable = new WeakMap();
  var templateContentsOwnerTable = new WeakMap();

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
    // templateElement is not a wrapper here.
    var doc = getTemplateContentsOwner(templateElement.ownerDocument);
    var df = unwrap(doc.createDocumentFragment());
    var child;
    while (child = templateElement.firstChild) {
      df.appendChild(child);
    }
    return df;
  }

  var OriginalHTMLTemplateElement = window.HTMLTemplateElement;

  function HTMLTemplateElement(node) {
    HTMLElement.call(this, node);
    if (!OriginalHTMLTemplateElement) {
      var content = extractContent(node);
      contentTable.set(this, wrap(content));
    }
  }
  HTMLTemplateElement.prototype = Object.create(HTMLElement.prototype);

  mixin(HTMLTemplateElement.prototype, {
    get content() {
      if (OriginalHTMLTemplateElement)
        return wrap(this.impl.content);
      return contentTable.get(this);
    },

    get innerHTML() {
      return getInnerHTML(this.content);
    },
    set innerHTML(value) {
      setInnerHTML(this.content, value);
    }

    // TODO(arv): cloneNode needs to clone content.

  });

  if (OriginalHTMLTemplateElement)
    registerWrapper(OriginalHTMLTemplateElement, HTMLTemplateElement);

  scope.wrappers.HTMLTemplateElement = HTMLTemplateElement;
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var registerWrapper = scope.registerWrapper;

  var OriginalHTMLMediaElement = window.HTMLMediaElement;

  function HTMLMediaElement(node) {
    HTMLElement.call(this, node);
  }
  HTMLMediaElement.prototype = Object.create(HTMLElement.prototype);

  registerWrapper(OriginalHTMLMediaElement, HTMLMediaElement,
                  document.createElement('audio'));

  scope.wrappers.HTMLMediaElement = HTMLMediaElement;
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLMediaElement = scope.wrappers.HTMLMediaElement;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var rewrap = scope.rewrap;

  var OriginalHTMLAudioElement = window.HTMLAudioElement;

  function HTMLAudioElement(node) {
    HTMLMediaElement.call(this, node);
  }
  HTMLAudioElement.prototype = Object.create(HTMLMediaElement.prototype);

  registerWrapper(OriginalHTMLAudioElement, HTMLAudioElement,
                  document.createElement('audio'));

  function Audio(src) {
    if (!(this instanceof Audio)) {
      throw new TypeError(
          'DOM object constructor cannot be called as a function.');
    }

    var node = unwrap(document.createElement('audio'));
    HTMLMediaElement.call(this, node);
    rewrap(node, this);

    node.setAttribute('preload', 'auto');
    if (src !== undefined)
      node.setAttribute('src', src);
  }

  Audio.prototype = HTMLAudioElement.prototype;

  scope.wrappers.HTMLAudioElement = HTMLAudioElement;
  scope.wrappers.Audio = Audio;
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var rewrap = scope.rewrap;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;

  var OriginalHTMLOptionElement = window.HTMLOptionElement;

  function trimText(s) {
    return s.replace(/\s+/g, ' ').trim();
  }

  function HTMLOptionElement(node) {
    HTMLElement.call(this, node);
  }
  HTMLOptionElement.prototype = Object.create(HTMLElement.prototype);
  mixin(HTMLOptionElement.prototype, {
    get text() {
      return trimText(this.textContent);
    },
    set text(value) {
      this.textContent = trimText(String(value));
    },
    get form() {
      return wrap(unwrap(this).form);
    }
  });

  registerWrapper(OriginalHTMLOptionElement, HTMLOptionElement,
                  document.createElement('option'));

  function Option(text, value, defaultSelected, selected) {
    if (!(this instanceof Option)) {
      throw new TypeError(
          'DOM object constructor cannot be called as a function.');
    }

    var node = unwrap(document.createElement('option'));
    HTMLElement.call(this, node);
    rewrap(node, this);

    if (text !== undefined)
      node.text = text;
    if (value !== undefined)
      node.setAttribute('value', value);
    if (defaultSelected === true)
      node.setAttribute('selected', '');
    node.selected = selected === true;
  }

  Option.prototype = HTMLOptionElement.prototype;

  scope.wrappers.HTMLOptionElement = HTMLOptionElement;
  scope.wrappers.Option = Option;
})(window.ShadowDOMPolyfill);

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
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var unwrapIfNeeded = scope.unwrapIfNeeded;
  var wrap = scope.wrap;

  var OriginalCanvasRenderingContext2D = window.CanvasRenderingContext2D;

  function CanvasRenderingContext2D(impl) {
    this.impl = impl;
  }

  mixin(CanvasRenderingContext2D.prototype, {
    get canvas() {
      return wrap(this.impl.canvas);
    },

    drawImage: function() {
      arguments[0] = unwrapIfNeeded(arguments[0]);
      this.impl.drawImage.apply(this.impl, arguments);
    },

    createPattern: function() {
      arguments[0] = unwrap(arguments[0]);
      return this.impl.createPattern.apply(this.impl, arguments);
    }
  });

  registerWrapper(OriginalCanvasRenderingContext2D, CanvasRenderingContext2D,
                  document.createElement('canvas').getContext('2d'));

  scope.wrappers.CanvasRenderingContext2D = CanvasRenderingContext2D;
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrapIfNeeded = scope.unwrapIfNeeded;
  var wrap = scope.wrap;

  var OriginalWebGLRenderingContext = window.WebGLRenderingContext;

  // IE10 does not have WebGL.
  if (!OriginalWebGLRenderingContext)
    return;

  function WebGLRenderingContext(impl) {
    this.impl = impl;
  }

  mixin(WebGLRenderingContext.prototype, {
    get canvas() {
      return wrap(this.impl.canvas);
    },

    texImage2D: function() {
      arguments[5] = unwrapIfNeeded(arguments[5]);
      this.impl.texImage2D.apply(this.impl, arguments);
    },

    texSubImage2D: function() {
      arguments[6] = unwrapIfNeeded(arguments[6]);
      this.impl.texSubImage2D.apply(this.impl, arguments);
    }
  });

  // Blink/WebKit has broken DOM bindings. Usually we would create an instance
  // of the object and pass it into registerWrapper as a "blueprint" but
  // creating WebGL contexts is expensive and might fail so we use a dummy
  // object with dummy instance properties for these broken browsers.
  var instanceProperties = /WebKit/.test(navigator.userAgent) ?
      {drawingBufferHeight: null, drawingBufferWidth: null} : {};

  registerWrapper(OriginalWebGLRenderingContext, WebGLRenderingContext,
      instanceProperties);

  scope.wrappers.WebGLRenderingContext = WebGLRenderingContext;
})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var unwrapIfNeeded = scope.unwrapIfNeeded;
  var wrap = scope.wrap;

  var OriginalRange = window.Range;

  function Range(impl) {
    this.impl = impl;
  }
  Range.prototype = {
    get startContainer() {
      return wrap(this.impl.startContainer);
    },
    get endContainer() {
      return wrap(this.impl.endContainer);
    },
    get commonAncestorContainer() {
      return wrap(this.impl.commonAncestorContainer);
    },
    setStart: function(refNode,offset) {
      this.impl.setStart(unwrapIfNeeded(refNode), offset);
    },
    setEnd: function(refNode,offset) {
      this.impl.setEnd(unwrapIfNeeded(refNode), offset);
    },
    setStartBefore: function(refNode) {
      this.impl.setStartBefore(unwrapIfNeeded(refNode));
    },
    setStartAfter: function(refNode) {
      this.impl.setStartAfter(unwrapIfNeeded(refNode));
    },
    setEndBefore: function(refNode) {
      this.impl.setEndBefore(unwrapIfNeeded(refNode));
    },
    setEndAfter: function(refNode) {
      this.impl.setEndAfter(unwrapIfNeeded(refNode));
    },
    selectNode: function(refNode) {
      this.impl.selectNode(unwrapIfNeeded(refNode));
    },
    selectNodeContents: function(refNode) {
      this.impl.selectNodeContents(unwrapIfNeeded(refNode));
    },
    compareBoundaryPoints: function(how, sourceRange) {
      return this.impl.compareBoundaryPoints(how, unwrap(sourceRange));
    },
    extractContents: function() {
      return wrap(this.impl.extractContents());
    },
    cloneContents: function() {
      return wrap(this.impl.cloneContents());
    },
    insertNode: function(node) {
      this.impl.insertNode(unwrapIfNeeded(node));
    },
    surroundContents: function(newParent) {
      this.impl.surroundContents(unwrapIfNeeded(newParent));
    },
    cloneRange: function() {
      return wrap(this.impl.cloneRange());
    },
    isPointInRange: function(node, offset) {
      return this.impl.isPointInRange(unwrapIfNeeded(node), offset);
    },
    comparePoint: function(node, offset) {
      return this.impl.comparePoint(unwrapIfNeeded(node), offset);
    },
    intersectsNode: function(node) {
      return this.impl.intersectsNode(unwrapIfNeeded(node));
    }
  };

  // IE9 does not have createContextualFragment.
  if (OriginalRange.prototype.createContextualFragment) {
    Range.prototype.createContextualFragment = function(html) {
      return wrap(this.impl.createContextualFragment(html));
    };
  }

  registerWrapper(window.Range, Range, document.createRange());

  scope.wrappers.Range = Range;

})(window.ShadowDOMPolyfill);

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

})(window.ShadowDOMPolyfill);

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

  var shadowHostTable = new WeakMap();
  var nextOlderShadowTreeTable = new WeakMap();

  function ShadowRoot(hostWrapper) {
    var node = unwrap(hostWrapper.impl.ownerDocument.createDocumentFragment());
    DocumentFragment.call(this, node);

    // createDocumentFragment associates the node with a wrapper
    // DocumentFragment instance. Override that.
    rewrap(node, this);

    var oldShadowRoot = hostWrapper.shadowRoot;
    nextOlderShadowTreeTable.set(this, oldShadowRoot);

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

    get olderShadowRoot() {
      return nextOlderShadowTreeTable.get(this) || null;
    },

    get host() {
      return shadowHostTable.get(this) || null;
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

})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var Element = scope.wrappers.Element;
  var HTMLContentElement = scope.wrappers.HTMLContentElement;
  var HTMLShadowElement = scope.wrappers.HTMLShadowElement;
  var Node = scope.wrappers.Node;
  var ShadowRoot = scope.wrappers.ShadowRoot;
  var assert = scope.assert;
  var mixin = scope.mixin;
  var oneOf = scope.oneOf;
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

  function insertBefore(parentNodeWrapper, newChildWrapper, refChildWrapper) {
    var parentNode = unwrap(parentNodeWrapper);
    var newChild = unwrap(newChildWrapper);
    var refChild = refChildWrapper ? unwrap(refChildWrapper) : null;

    remove(newChildWrapper);
    updateWrapperUpAndSideways(newChildWrapper);

    if (!refChildWrapper) {
      parentNodeWrapper.lastChild_ = parentNodeWrapper.lastChild;
      if (parentNodeWrapper.lastChild === parentNodeWrapper.firstChild)
        parentNodeWrapper.firstChild_ = parentNodeWrapper.firstChild;

      var lastChildWrapper = wrap(parentNode.lastChild);
      if (lastChildWrapper)
        lastChildWrapper.nextSibling_ = lastChildWrapper.nextSibling;
    } else {
      if (parentNodeWrapper.firstChild === refChildWrapper)
        parentNodeWrapper.firstChild_ = refChildWrapper;

      refChildWrapper.previousSibling_ = refChildWrapper.previousSibling;
    }

    parentNode.insertBefore(newChild, refChild);
  }

  function remove(nodeWrapper) {
    var node = unwrap(nodeWrapper)
    var parentNode = node.parentNode;
    if (!parentNode)
      return;

    var parentNodeWrapper = wrap(parentNode);
    updateWrapperUpAndSideways(nodeWrapper);

    if (nodeWrapper.previousSibling)
      nodeWrapper.previousSibling.nextSibling_ = nodeWrapper;
    if (nodeWrapper.nextSibling)
      nodeWrapper.nextSibling.previousSibling_ = nodeWrapper;

    if (parentNodeWrapper.lastChild === nodeWrapper)
      parentNodeWrapper.lastChild_ = nodeWrapper;
    if (parentNodeWrapper.firstChild === nodeWrapper)
      parentNodeWrapper.firstChild_ = nodeWrapper;

    parentNode.removeChild(node);
  }

  var distributedChildNodesTable = new WeakMap();
  var eventParentsTable = new WeakMap();
  var insertionParentTable = new WeakMap();
  var rendererForHostTable = new WeakMap();

  function distributeChildToInsertionPoint(child, insertionPoint) {
    getDistributedChildNodes(insertionPoint).push(child);
    assignToInsertionPoint(child, insertionPoint);

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
    for (var node = tree.firstChild; node; node = node.nextSibling) {
      if (predicate(node)) {
        if (visitor(node) === false)
          return;
      } else {
        visit(node, predicate, visitor);
      }
    }
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

    if (!(node instanceof Element))
      return false;

    // TODO(arv): This does not seem right. Need to check for a simple selector.
    if (!selectorMatchRegExp.test(select))
      return false;

    if (select[0] === ':' && !allowedPseudoRegExp.test(select))
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
    for (var i = 0; i < pendingDirtyRenderers.length; i++) {
      pendingDirtyRenderers[i].render();
    }
    pendingDirtyRenderers = [];
  }

  function handleRequestAnimationFrame() {
    renderTimer = null;
    renderAllPending();
  }

  /**
   * Returns existing shadow renderer for a host or creates it if it is needed.
   * @params {!Element} host
   * @return {!ShadowRenderer}
   */
  function getRendererForHost(host) {
    var renderer = rendererForHostTable.get(host);
    if (!renderer) {
      renderer = new ShadowRenderer(host);
      rendererForHostTable.set(host, renderer);
    }
    return renderer;
  }

  function getShadowRootAncestor(node) {
    for (; node; node = node.parentNode) {
      if (node instanceof ShadowRoot)
        return node;
    }
    return null;
  }

  function getRendererForShadowRoot(shadowRoot) {
    return getRendererForHost(shadowRoot.host);
  }

  var spliceDiff = new ArraySplice();
  spliceDiff.equals = function(renderNode, rawNode) {
    return unwrap(renderNode.node) === rawNode;
  };

  /**
   * RenderNode is used as an in memory "render tree". When we render the
   * composed tree we create a tree of RenderNodes, then we diff this against
   * the real DOM tree and make minimal changes as needed.
   */
  function RenderNode(node) {
    this.skip = false;
    this.node = node;
    this.childNodes = [];
  }

  RenderNode.prototype = {
    append: function(node) {
      var rv = new RenderNode(node);
      this.childNodes.push(rv);
      return rv;
    },

    sync: function(opt_added) {
      if (this.skip)
        return;

      var nodeWrapper = this.node;
      // plain array of RenderNodes
      var newChildren = this.childNodes;
      // plain array of real nodes.
      var oldChildren = getChildNodesSnapshot(unwrap(nodeWrapper));
      var added = opt_added || new WeakMap();

      var splices = spliceDiff.calculateSplices(newChildren, oldChildren);

      var newIndex = 0, oldIndex = 0;
      var lastIndex = 0;
      for (var i = 0; i < splices.length; i++) {
        var splice = splices[i];
        for (; lastIndex < splice.index; lastIndex++) {
          oldIndex++;
          newChildren[newIndex++].sync(added);
        }

        var removedCount = splice.removed.length;
        for (var j = 0; j < removedCount; j++) {
          var wrapper = wrap(oldChildren[oldIndex++]);
          if (!added.get(wrapper))
            remove(wrapper);
        }

        var addedCount = splice.addedCount;
        var refNode = oldChildren[oldIndex] && wrap(oldChildren[oldIndex]);
        for (var j = 0; j < addedCount; j++) {
          var newChildRenderNode = newChildren[newIndex++];
          var newChildWrapper = newChildRenderNode.node;
          insertBefore(nodeWrapper, newChildWrapper, refNode);

          // Keep track of added so that we do not remove the node after it
          // has been added.
          added.set(newChildWrapper, true);

          newChildRenderNode.sync(added);
        }

        lastIndex += addedCount;
      }

      for (var i = lastIndex; i < newChildren.length; i++) {
        newChildren[i].sync(added);
      }
    }
  };

  function ShadowRenderer(host) {
    this.host = host;
    this.dirty = false;
    this.invalidateAttributes();
    this.associateNode(host);
  }

  ShadowRenderer.prototype = {

    // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#rendering-shadow-trees
    render: function(opt_renderNode) {
      if (!this.dirty)
        return;

      this.invalidateAttributes();
      this.treeComposition();

      var host = this.host;
      var shadowRoot = host.shadowRoot;

      this.associateNode(host);
      var topMostRenderer = !renderNode;
      var renderNode = opt_renderNode || new RenderNode(host);

      for (var node = shadowRoot.firstChild; node; node = node.nextSibling) {
        this.renderNode(shadowRoot, renderNode, node, false);
      }

      if (topMostRenderer)
        renderNode.sync();

      this.dirty = false;
    },

    invalidate: function() {
      if (!this.dirty) {
        this.dirty = true;
        pendingDirtyRenderers.push(this);
        if (renderTimer)
          return;
        renderTimer = window[request](handleRequestAnimationFrame, 0);
      }
    },

    renderNode: function(shadowRoot, renderNode, node, isNested) {
      if (isShadowHost(node)) {
        renderNode = renderNode.append(node);
        var renderer = getRendererForHost(node);
        renderer.dirty = true;  // Need to rerender due to reprojection.
        renderer.render(renderNode);
      } else if (isInsertionPoint(node)) {
        this.renderInsertionPoint(shadowRoot, renderNode, node, isNested);
      } else if (isShadowInsertionPoint(node)) {
        this.renderShadowInsertionPoint(shadowRoot, renderNode, node);
      } else {
        this.renderAsAnyDomTree(shadowRoot, renderNode, node, isNested);
      }
    },

    renderAsAnyDomTree: function(shadowRoot, renderNode, node, isNested) {
      renderNode = renderNode.append(node);

      if (isShadowHost(node)) {
        var renderer = getRendererForHost(node);
        renderNode.skip = !renderer.dirty;
        renderer.render(renderNode);
      } else {
        for (var child = node.firstChild; child; child = child.nextSibling) {
          this.renderNode(shadowRoot, renderNode, child, isNested);
        }
      }
    },

    renderInsertionPoint: function(shadowRoot, renderNode, insertionPoint,
                                   isNested) {
      var distributedChildNodes = getDistributedChildNodes(insertionPoint);
      if (distributedChildNodes.length) {
        this.associateNode(insertionPoint);

        for (var i = 0; i < distributedChildNodes.length; i++) {
          var child = distributedChildNodes[i];
          if (isInsertionPoint(child) && isNested)
            this.renderInsertionPoint(shadowRoot, renderNode, child, isNested);
          else
            this.renderAsAnyDomTree(shadowRoot, renderNode, child, isNested);
        }
      } else {
        this.renderFallbackContent(shadowRoot, renderNode, insertionPoint);
      }
      this.associateNode(insertionPoint.parentNode);
    },

    renderShadowInsertionPoint: function(shadowRoot, renderNode,
                                         shadowInsertionPoint) {
      var nextOlderTree = shadowRoot.olderShadowRoot;
      if (nextOlderTree) {
        assignToInsertionPoint(nextOlderTree, shadowInsertionPoint);
        this.associateNode(shadowInsertionPoint.parentNode);
        for (var node = nextOlderTree.firstChild;
             node;
             node = node.nextSibling) {
          this.renderNode(nextOlderTree, renderNode, node, true);
        }
      } else {
        this.renderFallbackContent(shadowRoot, renderNode,
                                   shadowInsertionPoint);
      }
    },

    renderFallbackContent: function(shadowRoot, renderNode, fallbackHost) {
      this.associateNode(fallbackHost);
      this.associateNode(fallbackHost.parentNode);
      for (var node = fallbackHost.firstChild; node; node = node.nextSibling) {
        this.renderAsAnyDomTree(shadowRoot, renderNode, node, false);
      }
    },

    /**
     * Invalidates the attributes used to keep track of which attributes may
     * cause the renderer to be invalidated.
     */
    invalidateAttributes: function() {
      this.attributes = Object.create(null);
    },

    /**
     * Parses the selector and makes this renderer dependent on the attribute
     * being used in the selector.
     * @param {string} selector
     */
    updateDependentAttributes: function(selector) {
      if (!selector)
        return;

      var attributes = this.attributes;

      // .class
      if (/\.\w+/.test(selector))
        attributes['class'] = true;

      // #id
      if (/#\w+/.test(selector))
        attributes['id'] = true;

      selector.replace(/\[\s*([^\s=\|~\]]+)/g, function(_, name) {
        attributes[name] = true;
      });

      // Pseudo selectors have been removed from the spec.
    },

    dependsOnAttribute: function(name) {
      return this.attributes[name];
    },

    // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#dfn-distribution-algorithm
    distribute: function(tree, pool) {
      var self = this;

      visit(tree, isActiveInsertionPoint,
          function(insertionPoint) {
            resetDistributedChildNodes(insertionPoint);
            self.updateDependentAttributes(
                insertionPoint.getAttribute('select'));

            for (var i = 0; i < pool.length; i++) {  // 1.2
              var node = pool[i];  // 1.2.1
              if (node === undefined)  // removed
                continue;
              if (matchesCriteria(node, insertionPoint)) {  // 1.2.2
                distributeChildToInsertionPoint(node, insertionPoint);  // 1.2.2.1
                pool[i] = undefined;  // 1.2.2.2
              }
            }
          });
    },

    // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#dfn-tree-composition
    treeComposition: function () {
      var shadowHost = this.host;
      var tree = shadowHost.shadowRoot;  // 1.
      var pool = [];  // 2.

      for (var child = shadowHost.firstChild;
           child;
           child = child.nextSibling) {  // 3.
        if (isInsertionPoint(child)) {  // 3.2.
          var reprojected = getDistributedChildNodes(child);  // 3.2.1.
          // if reprojected is undef... reset it?
          if (!reprojected || !reprojected.length)  // 3.2.2.
            reprojected = getChildNodesSnapshot(child);
          pool.push.apply(pool, reprojected);  // 3.2.3.
        } else {
          pool.push(child); // 3.3.
        }
      }

      var shadowInsertionPoint, point;
      while (tree) {  // 4.
        // 4.1.
        shadowInsertionPoint = undefined;  // Reset every iteration.
        visit(tree, isActiveShadowInsertionPoint, function(point) {
          shadowInsertionPoint = point;
          return false;
        });
        point = shadowInsertionPoint;

        this.distribute(tree, pool);  // 4.2.
        if (point) {  // 4.3.
          var nextOlderTree = tree.olderShadowRoot;  // 4.3.1.
          if (!nextOlderTree) {
            break;  // 4.3.1.1.
          } else {
            tree = nextOlderTree;  // 4.3.2.2.
            assignToInsertionPoint(tree, point);  // 4.3.2.2.
            continue;  // 4.3.2.3.
          }
        } else {
          break;  // 4.4.
        }
      }
    },

    associateNode: function(node) {
      node.impl.polymerShadowRenderer_ = this;
    }
  };

  function isInsertionPoint(node) {
    // Should this include <shadow>?
    return node instanceof HTMLContentElement;
  }

  function isActiveInsertionPoint(node) {
    // <content> inside another <content> or <shadow> is considered inactive.
    return node instanceof HTMLContentElement;
  }

  function isShadowInsertionPoint(node) {
    return node instanceof HTMLShadowElement;
  }

  function isActiveShadowInsertionPoint(node) {
    // <shadow> inside another <content> or <shadow> is considered inactive.
    return node instanceof HTMLShadowElement;
  }

  function isShadowHost(shadowHost) {
    return shadowHost.shadowRoot;
  }

  function getShadowTrees(host) {
    var trees = [];

    for (var tree = host.shadowRoot; tree; tree = tree.olderShadowRoot) {
      trees.push(tree);
    }
    return trees;
  }

  function assignToInsertionPoint(tree, point) {
    insertionParentTable.set(tree, point);
  }

  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#rendering-shadow-trees
  function render(host) {
    new ShadowRenderer(host).render();
  };

  // Need to rerender shadow host when:
  //
  // - a direct child to the ShadowRoot is added or removed
  // - a direct child to the host is added or removed
  // - a new shadow root is created
  // - a direct child to a content/shadow element is added or removed
  // - a sibling to a content/shadow element is added or removed
  // - content[select] is changed
  // - an attribute in a direct child to a host is modified

  /**
   * This gets called when a node was added or removed to it.
   */
  Node.prototype.invalidateShadowRenderer = function(force) {
    var renderer = this.impl.polymerShadowRenderer_;
    if (renderer) {
      renderer.invalidate();
      return true;
    }

    return false;
  };

  HTMLContentElement.prototype.getDistributedNodes = function() {
    // TODO(arv): We should only rerender the dirty ancestor renderers (from
    // the root and down).
    renderAllPending();
    return getDistributedChildNodes(this);
  };

  HTMLShadowElement.prototype.nodeIsInserted_ =
  HTMLContentElement.prototype.nodeIsInserted_ = function() {
    // Invalidate old renderer if any.
    this.invalidateShadowRenderer();

    var shadowRoot = getShadowRootAncestor(this);
    var renderer;
    if (shadowRoot)
      renderer = getRendererForShadowRoot(shadowRoot);
    this.impl.polymerShadowRenderer_ = renderer;
    if (renderer)
      renderer.invalidate();
  };

  scope.eventParentsTable = eventParentsTable;
  scope.getRendererForHost = getRendererForHost;
  scope.getShadowTrees = getShadowTrees;
  scope.insertionParentTable = insertionParentTable;
  scope.renderAllPending = renderAllPending;

  // Exposed for testing
  scope.visual = {
    insertBefore: insertBefore,
    remove: remove,
  };

})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var HTMLElement = scope.wrappers.HTMLElement;
  var assert = scope.assert;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;

  var elementsWithFormProperty = [
    'HTMLButtonElement',
    'HTMLFieldSetElement',
    'HTMLInputElement',
    'HTMLKeygenElement',
    'HTMLLabelElement',
    'HTMLLegendElement',
    'HTMLObjectElement',
    // HTMLOptionElement is handled in HTMLOptionElement.js
    'HTMLOutputElement',
    'HTMLSelectElement',
    'HTMLTextAreaElement',
  ];

  function createWrapperConstructor(name) {
    if (!window[name])
      return;

    // Ensure we are not overriding an already existing constructor.
    assert(!scope.wrappers[name]);

    var GeneratedWrapper = function(node) {
      // At this point all of them extend HTMLElement.
      HTMLElement.call(this, node);
    }
    GeneratedWrapper.prototype = Object.create(HTMLElement.prototype);
    mixin(GeneratedWrapper.prototype, {
      get form() {
        return wrap(unwrap(this).form);
      },
    });

    registerWrapper(window[name], GeneratedWrapper,
        document.createElement(name.slice(4, -7)));
    scope.wrappers[name] = GeneratedWrapper;
  }

  elementsWithFormProperty.forEach(createWrapperConstructor);

})(window.ShadowDOMPolyfill);

// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function(scope) {
  'use strict';

  var GetElementsByInterface = scope.GetElementsByInterface;
  var Node = scope.wrappers.Node;
  var ParentNodeInterface = scope.ParentNodeInterface;
  var SelectorsInterface = scope.SelectorsInterface;
  var ShadowRoot = scope.wrappers.ShadowRoot;
  var defineWrapGetter = scope.defineWrapGetter;
  var elementFromPoint = scope.elementFromPoint;
  var forwardMethodsToWrapper = scope.forwardMethodsToWrapper;
  var matchesName = scope.matchesName;
  var mixin = scope.mixin;
  var registerWrapper = scope.registerWrapper;
  var unwrap = scope.unwrap;
  var wrap = scope.wrap;
  var wrapEventTargetMethods = scope.wrapEventTargetMethods;
  var wrapNodeList = scope.wrapNodeList;

  var implementationTable = new WeakMap();

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
    'createComment',
    'createDocumentFragment',
    'createElement',
    'createElementNS',
    'createEvent',
    'createEventNS',
    'createRange',
    'createTextNode',
    'getElementById',
  ].forEach(wrapMethod);

  var originalAdoptNode = document.adoptNode;

  function adoptNodeNoRemove(node, doc) {
    originalAdoptNode.call(doc.impl, unwrap(node));
    adoptSubtree(node, doc);
  }

  function adoptSubtree(node, doc) {
    if (node.shadowRoot)
      doc.adoptNode(node.shadowRoot);
    if (node instanceof ShadowRoot)
      adoptOlderShadowRoots(node, doc);
    for (var child = node.firstChild; child; child = child.nextSibling) {
      adoptSubtree(child, doc);
    }
  }

  function adoptOlderShadowRoots(shadowRoot, doc) {
    var oldShadowRoot = shadowRoot.olderShadowRoot;
    if (oldShadowRoot)
      doc.adoptNode(oldShadowRoot);
  }

  var originalImportNode = document.importNode;

  mixin(Document.prototype, {
    adoptNode: function(node) {
      if (node.parentNode)
        node.parentNode.removeChild(node);
      adoptNodeNoRemove(node, this);
      return node;
    },
    elementFromPoint: function(x, y) {
      return elementFromPoint(this, this, x, y);
    },
    importNode: function(node, deep) {
      // We need to manually walk the tree to ensure we do not include rendered
      // shadow trees.
      var clone = wrap(originalImportNode.call(this.impl, unwrap(node), false));
      if (deep) {
        for (var child = node.firstChild; child; child = child.nextSibling) {
          clone.appendChild(this.importNode(child, true));
        }
      }
      return clone;
    }
  });

  if (document.register) {
    var originalRegister = document.register;
    Document.prototype.register = function(tagName, object) {
      var prototype = object.prototype;

      // If we already used the object as a prototype for another custom
      // element.
      if (scope.nativePrototypeTable.get(prototype)) {
        // TODO(arv): DOMException
        throw new Error('NotSupportedError');
      }

      // Find first object on the prototype chain that already have a native
      // prototype. Keep track of all the objects before that so we can create
      // a similar structure for the native case.
      var proto = Object.getPrototypeOf(prototype);
      var nativePrototype;
      var prototypes = [];
      while (proto) {
        nativePrototype = scope.nativePrototypeTable.get(proto);
        if (nativePrototype)
          break;
        prototypes.push(proto);
        proto = Object.getPrototypeOf(proto);
      }

      if (!nativePrototype) {
        // TODO(arv): DOMException
        throw new Error('NotSupportedError');
      }

      // This works by creating a new prototype object that is empty, but has
      // the native prototype as its proto. The original prototype object
      // passed into register is used as the wrapper prototype.

      var newPrototype = Object.create(nativePrototype);
      for (var i = prototypes.length - 1; i >= 0; i--) {
        newPrototype = Object.create(newPrototype);
      }

      // Add callbacks if present.
      // Names are taken from:
      //   https://code.google.com/p/chromium/codesearch#chromium/src/third_party/WebKit/Source/bindings/v8/CustomElementConstructorBuilder.cpp&sq=package:chromium&type=cs&l=156
      // and not from the spec since the spec is out of date.
      [
        'createdCallback',
        'enteredViewCallback',
        'leftViewCallback',
        'attributeChangedCallback',
      ].forEach(function(name) {
        var f = prototype[name];
        if (!f)
          return;
        newPrototype[name] = function() {
          f.apply(wrap(this), arguments);
        };
      });

      var p = {prototype: newPrototype};
      if (object.extends)
        p.extends = object.extends;
      var nativeConstructor = originalRegister.call(unwrap(this), tagName, p);

      function GeneratedWrapper(node) {
        if (!node) {
          if (object.extends) {
            return document.createElement(object.extends, tagName);
          } else {
            return document.createElement(tagName);
          }
        }
        this.impl = node;
      }
      GeneratedWrapper.prototype = prototype;
      GeneratedWrapper.prototype.constructor = GeneratedWrapper;

      scope.constructorTable.set(newPrototype, GeneratedWrapper);
      scope.nativePrototypeTable.set(prototype, newPrototype);

      return GeneratedWrapper;
    };

    forwardMethodsToWrapper([
      window.HTMLDocument || window.Document,  // Gecko adds these to HTMLDocument
    ], [
      'register',
    ]);
  }

  // We also override some of the methods on document.body and document.head
  // for convenience.
  forwardMethodsToWrapper([
    window.HTMLBodyElement,
    window.HTMLDocument || window.Document,  // Gecko adds these to HTMLDocument
    window.HTMLHeadElement,
    window.HTMLHtmlElement,
  ], [
    'appendChild',
    'compareDocumentPosition',
    'contains',
    'getElementsByClassName',
    'getElementsByTagName',
    'getElementsByTagNameNS',
    'insertBefore',
    'querySelector',
    'querySelectorAll',
    'removeChild',
    'replaceChild',
    matchesName,
  ]);

  forwardMethodsToWrapper([
    window.HTMLDocument || window.Document,  // Gecko adds these to HTMLDocument
  ], [
    'adoptNode',
    'importNode',
    'contains',
    'createComment',
    'createDocumentFragment',
    'createElement',
    'createElementNS',
    'createEvent',
    'createEventNS',
    'createRange',
    'createTextNode',
    'elementFromPoint',
    'getElementById',
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

  scope.adoptNodeNoRemove = adoptNodeNoRemove;
  scope.wrappers.DOMImplementation = DOMImplementation;
  scope.wrappers.Document = Document;

})(window.ShadowDOMPolyfill);

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
  var renderAllPending = scope.renderAllPending;

  var OriginalWindow = window.Window;

  function Window(impl) {
    EventTarget.call(this, impl);
  }
  Window.prototype = Object.create(EventTarget.prototype);

  var originalGetComputedStyle = window.getComputedStyle;
  OriginalWindow.prototype.getComputedStyle = function(el, pseudo) {
    renderAllPending();
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

})(window.ShadowDOMPolyfill);

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
    'br': 'HTMLBRElement',
    'base': 'HTMLBaseElement',
    'body': 'HTMLBodyElement',
    'button': 'HTMLButtonElement',
    // 'command': 'HTMLCommandElement',  // Not fully implemented in Gecko.
    'dl': 'HTMLDListElement',
    'datalist': 'HTMLDataListElement',
    'data': 'HTMLDataElement',
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
    'input': 'HTMLInputElement',
    'li': 'HTMLLIElement',
    'label': 'HTMLLabelElement',
    'legend': 'HTMLLegendElement',
    'link': 'HTMLLinkElement',
    'map': 'HTMLMapElement',
    'marquee': 'HTMLMarqueeElement',
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
    'time': 'HTMLTimeElement',
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
    'track': 'HTMLTrackElement',
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

})(window.ShadowDOMPolyfill);

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
    var unwrapIfNeeded = ShadowDOMPolyfill.unwrapIfNeeded;
    function getTag(obj) {
      // TODO(jmesserly): do we still need these?
      if (obj instanceof NodeList) return 'NodeList';
      if (obj instanceof ShadowRoot) return 'ShadowRoot';
      if (window.MutationRecord && (obj instanceof MutationRecord))
          return 'MutationRecord';
      if (window.MutationObserver && (obj instanceof MutationObserver))
          return 'MutationObserver';

      // TODO(jmesserly): this prevents incorrect interaction between ShadowDOM
      // and dart:html's <template> polyfill. Essentially, ShadowDOM is
      // polyfilling native template, but our Dart polyfill fails to detect this
      // because the unwrapped node is an HTMLUnknownElement, leading it to
      // think the node has no content.
      if (obj instanceof HTMLTemplateElement) return 'HTMLTemplateElement';

      var unwrapped = unwrapIfNeeded(obj);
      if (obj !== unwrapped) {
        // Fix up class names for Firefox.
        // For some of them (like HTMLFormElement and HTMLInputElement),
        // the "constructor" property of the unwrapped nodes points at the
        // same constructor as the wrapper.
        var ctor = obj.constructor
        if (ctor === unwrapped.constructor) {
          var name = ctor._ShadowDOMPolyfill$cacheTag_;
          if (!name) {
            name = Object.prototype.toString.call(unwrapped);
            name = name.substring(8, name.length - 1);
            ctor._ShadowDOMPolyfill$cacheTag_ = name;
          }
          return name;
        }

        obj = unwrapped;
      }
      return originalGetTag(obj);
    }

    return getTag;
  };
})();

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var Platform = {};

/*
 * Copyright 2012 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

/*
  This is a limited shim for ShadowDOM css styling.
  https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#styles
  
  The intention here is to support only the styling features which can be 
  relatively simply implemented. The goal is to allow users to avoid the 
  most obvious pitfalls and do so without compromising performance significantly. 
  For ShadowDOM styling that's not covered here, a set of best practices
  can be provided that should allow users to accomplish more complex styling.

  The following is a list of specific ShadowDOM styling features and a brief
  discussion of the approach used to shim.

  Shimmed features:

  * @host: ShadowDOM allows styling of the shadowRoot's host element using the 
  @host rule. To shim this feature, the @host styles are reformatted and 
  prefixed with a given scope name and promoted to a document level stylesheet.
  For example, given a scope name of .foo, a rule like this:
  
    @host {
      * {
        background: red;
      }
    }
  
  becomes:
  
    .foo {
      background: red;
    }
  
  * encapsultion: Styles defined within ShadowDOM, apply only to 
  dom inside the ShadowDOM. Polymer uses one of two techniques to imlement
  this feature.
  
  By default, rules are prefixed with the host element tag name 
  as a descendant selector. This ensures styling does not leak out of the 'top'
  of the element's ShadowDOM. For example,

  div {
      font-weight: bold;
    }
  
  becomes:

  x-foo div {
      font-weight: bold;
    }
  
  becomes:


  Alternatively, if Platform.ShadowCSS.strictStyling is set to true then 
  selectors are scoped by adding an attribute selector suffix to each
  simple selector that contains the host element tag name. Each element 
  in the element's ShadowDOM template is also given the scope attribute. 
  Thus, these rules match only elements that have the scope attribute.
  For example, given a scope name of x-foo, a rule like this:
  
    div {
      font-weight: bold;
    }
  
  becomes:
  
    div[x-foo] {
      font-weight: bold;
    }

  Note that elements that are dynamically added to a scope must have the scope
  selector added to them manually.

  * ::pseudo: These rules are converted to rules that take advantage of the
  pseudo attribute. For example, a shadowRoot like this inside an x-foo

    <div pseudo="x-special">Special</div>

  with a rule like this:

    x-foo::x-special { ... }

  becomes:

    x-foo [pseudo=x-special] { ... }

  * ::part(): These rules are converted to rules that take advantage of the
  part attribute. For example, a shadowRoot like this inside an x-foo

    <div part="special">Special</div>

  with a rule like this:

    x-foo::part(special) { ... }

  becomes:

    x-foo [part=special] { ... }    
  
  Unaddressed ShadowDOM styling features:
  
  * upper/lower bound encapsulation: Styles which are defined outside a
  shadowRoot should not cross the ShadowDOM boundary and should not apply
  inside a shadowRoot.

  This styling behavior is not emulated. Some possible ways to do this that 
  were rejected due to complexity and/or performance concerns include: (1) reset
  every possible property for every possible selector for a given scope name;
  (2) re-implement css in javascript.
  
  As an alternative, users should make sure to use selectors
  specific to the scope in which they are working.
  
  * ::distributed: This behavior is not emulated. It's often not necessary
  to style the contents of a specific insertion point and instead, descendants
  of the host element can be styled selectively. Users can also create an 
  extra node around an insertion point and style that node's contents
  via descendent selectors. For example, with a shadowRoot like this:
  
    <style>
      content::-webkit-distributed(div) {
        background: red;
      }
    </style>
    <content></content>
  
  could become:
  
    <style>
      / *@polyfill .content-container div * / 
      content::-webkit-distributed(div) {
        background: red;
      }
    </style>
    <div class="content-container">
      <content></content>
    </div>
  
  Note the use of @polyfill in the comment above a ShadowDOM specific style
  declaration. This is a directive to the styling shim to use the selector 
  in comments in lieu of the next selector when running under polyfill.
*/
(function(scope) {

var ShadowCSS = {
  strictStyling: false,
  registry: {},
  // Shim styles for a given root associated with a name and extendsName
  // 1. cache root styles by name
  // 2. optionally tag root nodes with scope name
  // 3. shim polyfill directives /* @polyfill */ and /* @polyfill-rule */
  // 4. shim @host and scoping
  shimStyling: function(root, name, extendsName) {
    var typeExtension = this.isTypeExtension(extendsName);
    // use caching to make working with styles nodes easier and to facilitate
    // lookup of extendee
    var def = this.registerDefinition(root, name, extendsName);
    // find styles and apply shimming...
    if (this.strictStyling) {
      this.applyScopeToContent(root, name);
    }
    // insert @polyfill and @polyfill-rule rules into style elements
    // scoping process takes care of shimming these
    this.insertPolyfillDirectives(def.rootStyles);
    this.insertPolyfillRules(def.rootStyles);
    var cssText = this.stylesToShimmedCssText(def.scopeStyles, name,
        typeExtension);
    // note: we only need to do rootStyles since these are unscoped.
    cssText += this.extractPolyfillUnscopedRules(def.rootStyles);
    // provide shimmedStyle for user extensibility
    def.shimmedStyle = cssTextToStyle(cssText);
    if (root) {
      root.shimmedStyle = def.shimmedStyle;
    }
    // remove existing style elements
    for (var i=0, l=def.rootStyles.length, s; (i<l) && (s=def.rootStyles[i]); 
        i++) {
      s.parentNode.removeChild(s);
    }
    // add style to document
    addCssToDocument(cssText);
  },
  registerDefinition: function(root, name, extendsName) {
    var def = this.registry[name] = {
      root: root,
      name: name,
      extendsName: extendsName
    }
    var styles = root ? root.querySelectorAll('style') : [];
    styles = styles ? Array.prototype.slice.call(styles, 0) : [];
    def.rootStyles = styles;
    def.scopeStyles = def.rootStyles;
    var extendee = this.registry[def.extendsName];
    if (extendee && (!root || root.querySelector('shadow'))) {
      def.scopeStyles = extendee.scopeStyles.concat(def.scopeStyles);
    }
    return def;
  },
  isTypeExtension: function(extendsName) {
    return extendsName && extendsName.indexOf('-') < 0;
  },
  applyScopeToContent: function(root, name) {
    if (root) {
      // add the name attribute to each node in root.
      Array.prototype.forEach.call(root.querySelectorAll('*'),
          function(node) {
            node.setAttribute(name, '');
          });
      // and template contents too
      Array.prototype.forEach.call(root.querySelectorAll('template'),
          function(template) {
            this.applyScopeToContent(template.content, name);
          },
          this);
    }
  },
  /*
   * Process styles to convert native ShadowDOM rules that will trip
   * up the css parser; we rely on decorating the stylesheet with comments.
   * 
   * For example, we convert this rule:
   * 
   * (comment start) @polyfill :host menu-item (comment end)
   * shadow::-webkit-distributed(menu-item) {
   * 
   * to this:
   * 
   * scopeName menu-item {
   *
  **/
  insertPolyfillDirectives: function(styles) {
    if (styles) {
      Array.prototype.forEach.call(styles, function(s) {
        s.textContent = this.insertPolyfillDirectivesInCssText(s.textContent);
      }, this);
    }
  },
  insertPolyfillDirectivesInCssText: function(cssText) {
    return cssText.replace(cssPolyfillCommentRe, function(match, p1) {
      // remove end comment delimiter and add block start
      return p1.slice(0, -2) + '{';
    });
  },
  /*
   * Process styles to add rules which will only apply under the polyfill
   * 
   * For example, we convert this rule:
   * 
   * (comment start) @polyfill-rule :host menu-item { 
   * ... } (comment end)
   * 
   * to this:
   * 
   * scopeName menu-item {...}
   *
  **/
  insertPolyfillRules: function(styles) {
    if (styles) {
      Array.prototype.forEach.call(styles, function(s) {
        s.textContent = this.insertPolyfillRulesInCssText(s.textContent);
      }, this);
    }
  },
  insertPolyfillRulesInCssText: function(cssText) {
    return cssText.replace(cssPolyfillRuleCommentRe, function(match, p1) {
      // remove end comment delimiter
      return p1.slice(0, -1);
    });
  },
  /*
   * Process styles to add rules which will only apply under the polyfill
   * and do not process via CSSOM. (CSSOM is destructive to rules on rare 
   * occasions, e.g. -webkit-calc on Safari.)
   * For example, we convert this rule:
   * 
   * (comment start) @polyfill-unscoped-rule menu-item { 
   * ... } (comment end)
   * 
   * to this:
   * 
   * menu-item {...}
   *
  **/
  extractPolyfillUnscopedRules: function(styles) {
    var cssText = '';
    if (styles) {
      Array.prototype.forEach.call(styles, function(s) {
        cssText += this.extractPolyfillUnscopedRulesFromCssText(
            s.textContent) + '\n\n';
      }, this);
    }
    return cssText;
  },
  extractPolyfillUnscopedRulesFromCssText: function(cssText) {
    var r = '', matches;
    while (matches = cssPolyfillUnscopedRuleCommentRe.exec(cssText)) {
      r += matches[1].slice(0, -1) + '\n\n';
    }
    return r;
  },
  // apply @host and scope shimming
  stylesToShimmedCssText: function(styles, name, typeExtension) {
    return this.shimAtHost(styles, name, typeExtension) +
        this.shimScoping(styles, name, typeExtension);
  },
  // form: @host { .foo { declarations } }
  // becomes: scopeName.foo { declarations }
  shimAtHost: function(styles, name, typeExtension) {
    if (styles) {
      return this.convertAtHostStyles(styles, name, typeExtension);
    }
  },
  convertAtHostStyles: function(styles, name, typeExtension) {
    var cssText = stylesToCssText(styles), self = this;
    cssText = cssText.replace(hostRuleRe, function(m, p1) {
      return self.scopeHostCss(p1, name, typeExtension);
    });
    cssText = rulesToCss(this.findAtHostRules(cssToRules(cssText),
        this.makeScopeMatcher(name, typeExtension)));
    return cssText;
  },
  scopeHostCss: function(cssText, name, typeExtension) {
    var self = this;
    return cssText.replace(selectorRe, function(m, p1, p2) {
      return self.scopeHostSelector(p1, name, typeExtension) + ' ' + p2 + '\n\t';
    });
  },
  // supports scopig by name and  [is=name] syntax
  scopeHostSelector: function(selector, name, typeExtension) {
    var r = [], parts = selector.split(','), is = '[is=' + name + ']';
    parts.forEach(function(p) {
      p = p.trim();
      // selector: *|:scope -> name
      if (p.match(hostElementRe)) {
        p = p.replace(hostElementRe, typeExtension ? is + '$1$3' :
            name + '$1$3');
      // selector: .foo -> name.foo (OR) [bar] -> name[bar]
      } else if (p.match(hostFixableRe)) {
        p = typeExtension ? is + p : name + p;
      }
      r.push(p);
    }, this);
    return r.join(', ');
  },
  // consider styles that do not include component name in the selector to be
  // unscoped and in need of promotion; 
  // for convenience, also consider keyframe rules this way.
  findAtHostRules: function(cssRules, matcher) {
    return Array.prototype.filter.call(cssRules, 
      this.isHostRule.bind(this, matcher));
  },
  isHostRule: function(matcher, cssRule) {
    return (cssRule.selectorText && cssRule.selectorText.match(matcher)) ||
      (cssRule.cssRules && this.findAtHostRules(cssRule.cssRules, matcher).length) ||
      (cssRule.type == CSSRule.WEBKIT_KEYFRAMES_RULE);
  },
  /* Ensure styles are scoped. Pseudo-scoping takes a rule like:
   * 
   *  .foo {... } 
   *  
   *  and converts this to
   *  
   *  scopeName .foo { ... }
  */
  shimScoping: function(styles, name, typeExtension) {
    if (styles) {
      return this.convertScopedStyles(styles, name, typeExtension);
    }
  },
  convertScopedStyles: function(styles, name, typeExtension) {
    var cssText = stylesToCssText(styles).replace(hostRuleRe, '');
    cssText = this.insertPolyfillHostInCssText(cssText);
    cssText = this.convertColonHost(cssText);
    cssText = this.convertPseudos(cssText);
    cssText = this.convertParts(cssText);
    cssText = this.convertCombinators(cssText);
    var rules = cssToRules(cssText);
    cssText = this.scopeRules(rules, name, typeExtension);
    return cssText;
  },
  convertPseudos: function(cssText) {
    return cssText.replace(cssPseudoRe, ' [pseudo=$1]');
  },
  convertParts: function(cssText) {
    return cssText.replace(cssPartRe, ' [part=$1]');
  },
  /*
   * convert a rule like :host(.foo) > .bar { }
   *
   * to
   *
   * scopeName.foo > .bar, .foo scopeName > .bar { }
   * 
   * and
   *
   * :host(.foo:host) .bar { ... }
   * 
   * to
   * 
   * scopeName.foo .bar { ... }
  */
  convertColonHost: function(cssText) {
    // p1 = :host, p2 = contents of (), p3 rest of rule
    return cssText.replace(cssColonHostRe, function(m, p1, p2, p3) {
      p1 = polyfillHostNoCombinator;
      if (p2) {
        var parts = p2.split(','), r = [];
        for (var i=0, l=parts.length, p; (i<l) && (p=parts[i]); i++) {
          p = p.trim();
          if (p.match(polyfillHost)) {
            r.push(p1 + p.replace(polyfillHost, '') + p3);
          } else {
            r.push(p1 + p + p3 + ', ' + p + ' ' + p1 + p3);
          }
        }
        return r.join(',');
      } else {
        return p1 + p3;
      }
    });
  },
  /*
   * Convert ^ and ^^ combinators by replacing with space.
  */
  convertCombinators: function(cssText) {
    return cssText.replace(/\^\^/g, ' ').replace(/\^/g, ' ');
  },
  // change a selector like 'div' to 'name div'
  scopeRules: function(cssRules, name, typeExtension) {
    var cssText = '';
    Array.prototype.forEach.call(cssRules, function(rule) {
      if (rule.selectorText && (rule.style && rule.style.cssText)) {
        cssText += this.scopeSelector(rule.selectorText, name, typeExtension, 
          this.strictStyling) + ' {\n\t';
        cssText += this.propertiesFromRule(rule) + '\n}\n\n';
      } else if (rule.media) {
        cssText += '@media ' + rule.media.mediaText + ' {\n';
        cssText += this.scopeRules(rule.cssRules, name, typeExtension);
        cssText += '\n}\n\n';
      } else if (rule.cssText) {
        cssText += rule.cssText + '\n\n';
      }
    }, this);
    return cssText;
  },
  scopeSelector: function(selector, name, typeExtension, strict) {
    var r = [], parts = selector.split(',');
    parts.forEach(function(p) {
      p = p.trim();
      if (this.selectorNeedsScoping(p, name, typeExtension)) {
        p = (strict && !p.match(polyfillHostNoCombinator)) ? 
            this.applyStrictSelectorScope(p, name) :
            this.applySimpleSelectorScope(p, name, typeExtension);
      }
      r.push(p);
    }, this);
    return r.join(', ');
  },
  selectorNeedsScoping: function(selector, name, typeExtension) {
    var re = this.makeScopeMatcher(name, typeExtension);
    return !selector.match(re);
  },
  makeScopeMatcher: function(name, typeExtension) {
    var matchScope = typeExtension ? '\\[is=[\'"]?' + name + '[\'"]?\\]' : name;
    return new RegExp('^(' + matchScope + ')' + selectorReSuffix, 'm');
  },
  // scope via name and [is=name]
  applySimpleSelectorScope: function(selector, name, typeExtension) {
    var scoper = typeExtension ? '[is=' + name + ']' : name;
    if (selector.match(polyfillHostRe)) {
      selector = selector.replace(polyfillHostNoCombinator, scoper);
      return selector.replace(polyfillHostRe, scoper + ' ');
    } else {
      return scoper + ' ' + selector;
    }
  },
  // return a selector with [name] suffix on each simple selector
  // e.g. .foo.bar > .zot becomes .foo[name].bar[name] > .zot[name]
  applyStrictSelectorScope: function(selector, name) {
    var splits = [' ', '>', '+', '~'],
      scoped = selector,
      attrName = '[' + name + ']';
    splits.forEach(function(sep) {
      var parts = scoped.split(sep);
      scoped = parts.map(function(p) {
        // remove :host since it should be unnecessary
        var t = p.trim().replace(polyfillHostRe, '');
        if (t && (splits.indexOf(t) < 0) && (t.indexOf(attrName) < 0)) {
          p = t.replace(/([^:]*)(:*)(.*)/, '$1' + attrName + '$2$3')
        }
        return p;
      }).join(sep);
    });
    return scoped;
  },
  insertPolyfillHostInCssText: function(selector) {
    return selector.replace(hostRe, polyfillHost).replace(colonHostRe,
        polyfillHost);
  },
  propertiesFromRule: function(rule) {
    return rule.style.cssText;
  }
};

var hostRuleRe = /@host[^{]*{(([^}]*?{[^{]*?}[\s\S]*?)+)}/gim,
    selectorRe = /([^{]*)({[\s\S]*?})/gim,
    hostElementRe = /(.*)((?:\*)|(?:\:scope))(.*)/,
    hostFixableRe = /^[.\[:]/,
    cssCommentRe = /\/\*[^*]*\*+([^/*][^*]*\*+)*\//gim,
    cssPolyfillCommentRe = /\/\*\s*@polyfill ([^*]*\*+([^/*][^*]*\*+)*\/)([^{]*?){/gim,
    cssPolyfillRuleCommentRe = /\/\*\s@polyfill-rule([^*]*\*+([^/*][^*]*\*+)*)\//gim,
    cssPolyfillUnscopedRuleCommentRe = /\/\*\s@polyfill-unscoped-rule([^*]*\*+([^/*][^*]*\*+)*)\//gim,
    cssPseudoRe = /::(x-[^\s{,(]*)/gim,
    cssPartRe = /::part\(([^)]*)\)/gim,
    // note: :host pre-processed to -shadowcsshost.
    polyfillHost = '-shadowcsshost',
    cssColonHostRe = new RegExp('(' + polyfillHost +
        ')(?:\\((' +
        '(?:\\([^)(]*\\)|[^)(]*)+?' +
        ')\\))?([^,{]*)', 'gim'),
    selectorReSuffix = '([>\\s~+\[.,{:][\\s\\S]*)?$',
    hostRe = /@host/gim,
    colonHostRe = /\:host/gim,
    /* host name without combinator */
    polyfillHostNoCombinator = polyfillHost + '-no-combinator',
    polyfillHostRe = new RegExp(polyfillHost, 'gim');

function stylesToCssText(styles, preserveComments) {
  var cssText = '';
  Array.prototype.forEach.call(styles, function(s) {
    cssText += s.textContent + '\n\n';
  });
  // strip comments for easier processing
  if (!preserveComments) {
    cssText = cssText.replace(cssCommentRe, '');
  }
  return cssText;
}

function cssTextToStyle(cssText) {
  var style = document.createElement('style');
  style.textContent = cssText;
  return style;
}

function cssToRules(cssText) {
  var style = cssTextToStyle(cssText);
  document.head.appendChild(style);
  var rules = style.sheet.cssRules;
  style.parentNode.removeChild(style);
  return rules;
}

function rulesToCss(cssRules) {
  for (var i=0, css=[]; i < cssRules.length; i++) {
    css.push(cssRules[i].cssText);
  }
  return css.join('\n\n');
}

function addCssToDocument(cssText) {
  if (cssText) {
    getSheet().appendChild(document.createTextNode(cssText));
  }
}

var sheet;
function getSheet() {
  if (!sheet) {
    sheet = document.createElement("style");
    sheet.setAttribute('ShadowCSSShim', '');
  }
  return sheet;
}

// add polyfill stylesheet to document
if (window.ShadowDOMPolyfill) {
  addCssToDocument('style { display: none !important; }\n');
  var head = document.querySelector('head');
  head.insertBefore(getSheet(), head.childNodes[0]);
}

// exports
scope.ShadowCSS = ShadowCSS;

})(window.Platform);
}