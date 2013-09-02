// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The js.dart library provides simple JavaScript invocation from Dart that
 * works on both Dartium and on other modern browsers via Dart2JS.
 *
 * It provides a model based on scoped [JsObject] objects.  Proxies give Dart
 * code access to JavaScript objects, fields, and functions as well as the
 * ability to pass Dart objects and functions to JavaScript functions.  Scopes
 * enable developers to use proxies without memory leaks - a common challenge
 * with cross-runtime interoperation.
 *
 * The top-level [context] getter provides a [JsObject] to the global JavaScript
 * context for the page your Dart code is running on.  In the following example:
 *
 *     import 'dart:js';
 *
 *     void main() {
 *       context.callMethod('alert', ['Hello from Dart via JavaScript']);
 *     }
 *
 * context['alert'] creates a proxy to the top-level alert function in
 * JavaScript.  It is invoked from Dart as a regular function that forwards to
 * the underlying JavaScript one.  By default, proxies are released when
 * the currently executing event completes, e.g., when main is completes
 * in this example.
 *
 * The library also enables JavaScript proxies to Dart objects and functions.
 * For example, the following Dart code:
 *
 *     context['dartCallback'] = new Callback.once((x) => print(x*2));
 *
 * defines a top-level JavaScript function 'dartCallback' that is a proxy to
 * the corresponding Dart function.  The [Callback.once] constructor allows the
 * proxy to the Dart function to be retained across multiple events;
 * instead it is released after the first invocation.  (This is a common
 * pattern for asychronous callbacks.)
 *
 * Note, parameters and return values are intuitively passed by value for
 * primitives and by reference for non-primitives.  In the latter case, the
 * references are automatically wrapped and unwrapped as proxies by the library.
 *
 * This library also allows construction of JavaScripts objects given a
 * [JsObject] to a corresponding JavaScript constructor.  For example, if the
 * following JavaScript is loaded on the page:
 *
 *     function Foo(x) {
 *       this.x = x;
 *     }
 *
 *     Foo.prototype.add = function(other) {
 *       return new Foo(this.x + other.x);
 *     }
 *
 * then, the following Dart:
 *
 *     var foo = new JsObject(context['Foo'], [42]);
 *     var foo2 = foo.callMethod('add', [foo]);
 *     print(foo2['x']);
 *
 * will construct a JavaScript Foo object with the parameter 42, invoke its
 * add method, and return a [JsObject] to a new Foo object whose x field is 84.
 */

library dart.js;

import 'dart:html';
import 'dart:isolate';

// Global ports to manage communication from Dart to JS.
SendPortSync _jsPortSync = window.lookupPort('dart-js-context');
SendPortSync _jsPortCreate = window.lookupPort('dart-js-create');
SendPortSync _jsPortInstanceof = window.lookupPort('dart-js-instanceof');
SendPortSync _jsPortDeleteProperty = window.lookupPort('dart-js-delete-property');
SendPortSync _jsPortConvert = window.lookupPort('dart-js-convert');

/**
 * Returns a proxy to the global JavaScript context for this page.
 */
JsObject get context {
  var port = _jsPortSync;
  if (port == null) {
    return null;
  }
  return _deserialize(_jsPortSync.callSync([]));
}

/**
 * Converts a json-like [data] to a JavaScript map or array and return a
 * [JsObject] to it.
 */
JsObject jsify(dynamic data) => data == null ? null : new JsObject._json(data);

/**
 * Converts a local Dart function to a callback that can be passed to
 * JavaScript.
 */
class Callback implements Serializable<JsFunction> {
  JsFunction _f;

  Callback._(Function f, bool withThis) {
    final id = _proxiedObjectTable.add((List args) {
      final arguments = new List.from(args);
      if (!withThis) arguments.removeAt(0);
      return Function.apply(f, arguments);
    });
    _f = new JsFunction._internal(_proxiedObjectTable.sendPort, id);
  }

  factory Callback(Function f) => new Callback._(f, false);
  factory Callback.withThis(Function f) => new Callback._(f, true);

  JsFunction toJs() => _f;
}

/**
 * Proxies to JavaScript objects.
 */
class JsObject implements Serializable<JsObject> {
  final SendPortSync _port;
  final String _id;

  /**
   * Constructs a [JsObject] to a new JavaScript object by invoking a (proxy to
   * a) JavaScript [constructor].  The [arguments] list should contain either
   * primitive values, DOM elements, or Proxies.
   */
  factory JsObject(Serializable<JsFunction> constructor, [List arguments]) {
    final params = [constructor];
    if (arguments != null) params.addAll(arguments);
    final serialized = params.map(_serialize).toList();
    final result = _jsPortCreate.callSync(serialized);
    return _deserialize(result);
  }

  /**
   * Constructs a [JsObject] to a new JavaScript map or list created defined via
   * Dart map or list.
   */
  factory JsObject._json(data) => _convert(data);

  static _convert(data) =>
      _deserialize(_jsPortConvert.callSync(_serializeDataTree(data)));

  static _serializeDataTree(data) {
    if (data is Map) {
      final entries = new List();
      for (var key in data.keys) {
        entries.add([key, _serializeDataTree(data[key])]);
      }
      return ['map', entries];
    } else if (data is Iterable) {
      return ['list', data.map(_serializeDataTree).toList()];
    } else {
      return ['simple', _serialize(data)];
    }
  }

  JsObject._internal(this._port, this._id);

  JsObject toJs() => this;

  // Resolve whether this is needed.
  operator[](arg) => _forward(this, '[]', 'method', [ arg ]);

  // Resolve whether this is needed.
  operator[]=(key, value) => _forward(this, '[]=', 'method', [ key, value ]);

  int get hashCode => _id.hashCode;

  // Test if this is equivalent to another Proxy.  This essentially
  // maps to JavaScript's === operator.
  operator==(other) => other is JsObject && this._id == other._id;

  /**
   * Check if this [JsObject] has a [name] property.
   */
  bool hasProperty(String name) => _forward(this, name, 'hasProperty', []);

  /**
   * Delete the [name] property.
   */
  void deleteProperty(String name) {
    _jsPortDeleteProperty.callSync([this, name].map(_serialize).toList());
  }

  /**
   * Check if this [JsObject] is instance of [type].
   */
  bool instanceof(Serializable<JsFunction> type) =>
      _jsPortInstanceof.callSync([this, type].map(_serialize).toList());

  String toString() {
    try {
      return _forward(this, 'toString', 'method', []);
    } catch(e) {
      return super.toString();
    }
  }

  callMethod(String name, [List args]) {
    return _forward(this, name, 'method', args != null ? args : []);
  }

  // Forward member accesses to the backing JavaScript object.
  static _forward(JsObject receiver, String member, String kind, List args) {
    var result = receiver._port.callSync([receiver._id, member, kind,
                                          args.map(_serialize).toList()]);
    switch (result[0]) {
      case 'return': return _deserialize(result[1]);
      case 'throws': throw _deserialize(result[1]);
      case 'none':
          throw new NoSuchMethodError(receiver, new Symbol(member), args, {});
      default: throw 'Invalid return value';
    }
  }
}

/// A [JsObject] subtype to JavaScript functions.
class JsFunction extends JsObject implements Serializable<JsFunction> {
  JsFunction._internal(SendPortSync port, String id)
      : super._internal(port, id);

  apply(thisArg, [List args]) {
    return JsObject._forward(this, '', 'apply',
        [thisArg]..addAll(args == null ? [] : args));
  }
}

/// Marker class used to indicate it is serializable to js. If a class is a
/// [Serializable] the "toJs" method will be called and the result will be used
/// as value.
abstract class Serializable<T> {
  T toJs();
}

// A table to managed local Dart objects that are proxied in JavaScript.
class _ProxiedObjectTable {
  // Debugging name.
  final String _name;

  // Generator for unique IDs.
  int _nextId;

  // Table of IDs to Dart objects.
  final Map<String, Object> _registry;

  // Port to handle and forward requests to the underlying Dart objects.
  // A remote proxy is uniquely identified by an ID and SendPortSync.
  final ReceivePortSync _port;

  _ProxiedObjectTable() :
      _name = 'dart-ref',
      _nextId = 0,
      _registry = {},
      _port = new ReceivePortSync() {
    _port.receive((msg) {
      try {
        final receiver = _registry[msg[0]];
        final method = msg[1];
        final args = msg[2].map(_deserialize).toList();
        if (method == '#call') {
          final func = receiver as Function;
          var result = _serialize(func(args));
          return ['return', result];
        } else {
          // TODO(vsm): Support a mechanism to register a handler here.
          throw 'Invocation unsupported on non-function Dart proxies';
        }
      } catch (e) {
        // TODO(vsm): callSync should just handle exceptions itself.
        return ['throws', '$e'];
      }
    });
  }

  // Adds a new object to the table and return a new ID for it.
  String add(x) {
    // TODO(vsm): Cache x and reuse id.
    final id = '$_name-${_nextId++}';
    _registry[id] = x;
    return id;
  }

  // Gets an object by ID.
  Object get(String id) {
    return _registry[id];
  }

  // Gets the current number of objects kept alive by this table.
  get count => _registry.length;

  // Gets a send port for this table.
  get sendPort => _port.toSendPort();
}

// The singleton to manage proxied Dart objects.
_ProxiedObjectTable _proxiedObjectTable = new _ProxiedObjectTable();

/// End of proxy implementation.

// Dart serialization support.

_serialize(var message) {
  if (message == null) {
    return null;  // Convert undefined to null.
  } else if (message is String ||
             message is num ||
             message is bool) {
    // Primitives are passed directly through.
    return message;
  } else if (message is SendPortSync) {
    // Non-proxied objects are serialized.
    return message;
  } else if (message is JsFunction) {
    // Remote function proxy.
    return [ 'funcref', message._id, message._port ];
  } else if (message is JsObject) {
    // Remote object proxy.
    return [ 'objref', message._id, message._port ];
  } else if (message is Serializable) {
    // use of result of toJs()
    return _serialize(message.toJs());
  } else if (message is Function) {
    return _serialize(new Callback(message));
  } else {
    // Local object proxy.
    return [ 'objref',
             _proxiedObjectTable.add(message),
             _proxiedObjectTable.sendPort ];
  }
}

_deserialize(var message) {
  deserializeFunction(message) {
    var id = message[1];
    var port = message[2];
    if (port == _proxiedObjectTable.sendPort) {
      // Local function.
      return _proxiedObjectTable.get(id);
    } else {
      // Remote function.  Forward to its port.
      return new JsFunction._internal(port, id);
    }
  }

  deserializeObject(message) {
    var id = message[1];
    var port = message[2];
    if (port == _proxiedObjectTable.sendPort) {
      // Local object.
      return _proxiedObjectTable.get(id);
    } else {
      // Remote object.
      return new JsObject._internal(port, id);
    }
  }

  if (message == null) {
    return null;  // Convert undefined to null.
  } else if (message is String ||
             message is num ||
             message is bool) {
    // Primitives are passed directly through.
    return message;
  } else if (message is SendPortSync) {
    // Serialized type.
    return message;
  }
  var tag = message[0];
  switch (tag) {
    case 'funcref': return deserializeFunction(message);
    case 'objref': return deserializeObject(message);
  }
  throw 'Unsupported serialized data: $message';
}
