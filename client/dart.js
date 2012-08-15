// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bootstrap support for Dart scripts on the page as this script.
if (navigator.webkitStartDart) {
  if (!navigator.webkitStartDart()) {
    document.body.innerHTML = 'This build has expired.  Please download a new Dartium at http://www.dartlang.org/dartium/index.html';
  }
} else {
  // TODO:
  // - Support in-browser compilation.
  // - Handle inline Dart scripts.
  window.addEventListener("DOMContentLoaded", function (e) {
    // Fall back to compiled JS. Run through all the scripts and
    // replace them if they have a type that indicate that they source
    // in Dart code.
    //
    //   <script type="application/dart" src="..."></script>
    //
    var scripts = document.getElementsByTagName("script");
    var length = scripts.length;
    for (var i = 0; i < length; ++i) {
      if (scripts[i].type == "application/dart") {
        // Remap foo.dart to foo.dart.js.
        if (scripts[i].src && scripts[i].src != '') {
          var script = document.createElement('script');
          script.src = scripts[i].src + '.js';
          var parent = scripts[i].parentNode;
          parent.replaceChild(script, scripts[i]);
        }
      }
    }
  }, false);
}

// ---------------------------------------------------------------------------
// Experimental support for JS interoperability
// ---------------------------------------------------------------------------
function SendPortSync() {
}

function ReceivePortSync() {
  this.id = ReceivePortSync.id++;
  ReceivePortSync.map[this.id] = this;
}

(function() {
  function serialize(message) {
    var visited = [];
    function checkedSerialization(obj, serializer) {
      // Implementation detail: for now use linear search.
      // Another option is expando, but it may prohibit
      // VM optimizations (like putting object into slow mode
      // on property deletion.)
      var id = visited.indexOf(obj);
      if (id != -1) return [ 'ref', id ];
      var id = visited.length;
      visited.push(obj);
      return serializer(id);
    }

    function doSerialize(message) {
      if (message == null) {
        return null;  // Convert undefined to null.
      } else if (typeof(message) == 'string' ||
                 typeof(message) == 'number' ||
                 typeof(message) == 'boolean') {
        return message;
      } else if (message instanceof Array) {
        return checkedSerialization(message, function(id) {
          var values = new Array(message.length);
          for (var i = 0; i < message.length; i++) {
            values[i] = doSerialize(message[i]);
          }
          return [ 'list', id, values ];
        });
      } else if (message instanceof LocalSendPortSync) {
        return [ 'sendport', 'nativejs', message.receivePort.id ];
      } else if (message instanceof DartSendPortSync) {
        return [ 'sendport', 'dart', message.isolateId, message.portId ];
      } else {
        return checkedSerialization(message, function(id) {
          var keys = Object.getOwnPropertyNames(message);
          var values = new Array(keys.length);
          for (var i = 0; i < keys.length; i++) {
            values[i] = doSerialize(message[keys[i]]);
          }
          return [ 'map', id, keys, values ];
        });
      }
    }
    return doSerialize(message);
  }

  function deserialize(message) {
    return deserializeHelper(message);
  }

  function deserializeHelper(x) {
    if (x == null ||
        typeof(x) == 'string' ||
        typeof(x) == 'number' ||
        typeof(x) == 'boolean') {
      return x;
    }
    switch (x[0]) {
      case 'map': return deserializeMap(x);
      case 'sendport': return deserializeSendPort(x);
      case 'list': return deserializeList(x);
      case 'funcref': return deserializeFunction(x);
      default: throw 'unimplemented';
    }
  }

  function deserializeMap(x) {
    var result = { };
    var id = x[1];
    var keys = x[2];
    var values = x[3];
    for (var i = 0, length = keys.length; i < length; i++) {
      var key = deserializeHelper(keys[i]);
      var value = deserializeHelper(values[i]);
      result[key] = value;
    }
    return result;
  }

  function deserializeSendPort(x) {
    var tag = x[1];
    switch (tag) {
      case 'nativejs':
        var id = x[2];
        return new LocalSendPortSync(ReceivePortSync.map[id]);
      case 'dart':
        var isolateId = x[2];
        var portId = x[3];
        return new DartSendPortSync(isolateId, portId);
      default:
        throw 'Illegal SendPortSync type: $tag';
    }
  }

  function deserializeList(x) {
    var values = x[2];
    var length = values.length;
    var result = new Array(length);
    for (var i = 0; i < length; i++) {
      result[i] = deserializeHelper(values[i]);
    }
    return result;
  }

  function deserializeFunction(x) {
    var ref = x[1];
    var sendPort = deserializeSendPort(x[2]);
    // Number of arguments is not used as of now
    // we cannot find it out for Dart function in pure Dart.
    return _makeFunctionFromRef(ref, sendPort);
  }

  window.registerPort = function(name, port) {
    var stringified = JSON.stringify(serialize(port));
    window.localStorage['dart-port:' + name] = stringified;
  };

  window.lookupPort = function(name) {
    var stringified = window.localStorage['dart-port:' + name];
    return deserialize(JSON.parse(stringified));
  };

  ReceivePortSync.id = 0;
  ReceivePortSync.map = {};

  ReceivePortSync.dispatchCall = function(id, message) {
    // TODO(vsm): Handle and propagate exceptions.
    var deserialized = deserialize(message);
    var result = ReceivePortSync.map[id].callback(deserialized);
    return serialize(result);
  };

  ReceivePortSync.prototype.receive = function(callback) {
    this.callback = callback;
  };

  ReceivePortSync.prototype.toSendPort = function() {
    return new LocalSendPortSync(this);
  };

  ReceivePortSync.prototype.close = function() {
    delete ReceivePortSync.map[this.id];
  };

  if (navigator.webkitStartDart) {
    window.addEventListener('js-sync-message', function(event) {
      var data = JSON.parse(event.data);
      var deserialized = deserialize(data.message);
      var result = ReceivePortSync.map[data.id].callback(deserialized);
      // TODO(vsm): Handle and propagate exceptions.
      dispatchEvent('js-result', serialize(result));
    }, false);
  }

  function LocalSendPortSync(receivePort) {
    this.receivePort = receivePort;
  }

  LocalSendPortSync.prototype = new SendPortSync();

  LocalSendPortSync.prototype.callSync = function(message) {
    // TODO(vsm): Do a direct deepcopy.
    message = deserialize(serialize(message));
    return this.receivePort.callback(message);
  }

  function DartSendPortSync(isolateId, portId) {
    this.isolateId = isolateId;
    this.portId = portId;
  }

  DartSendPortSync.prototype = new SendPortSync();

  function dispatchEvent(receiver, message) {
    var string = JSON.stringify(message);
    var event = document.createEvent('TextEvent');
    event.initTextEvent(receiver, false, false, window, string);
    window.dispatchEvent(event);
  }

  DartSendPortSync.prototype.callSync = function(message) {
    var serialized = serialize(message);
    var target = 'dart-port-' + this.isolateId + '-' + this.portId;
    // TODO(vsm): Make this re-entrant.
    // TODO(vsm): Set this up set once, on the first call.
    var source = target + '-result';
    var result = null;
    var listener = function (e) {
      result = JSON.parse(e.data);
    };
    window.addEventListener(source, listener, false);
    dispatchEvent(target, [source, serialized]);
    window.removeEventListener(source, listener, false);
    return deserialize(result);
  }

  // Leaking implementation.
  // TODO: provide proper, backend-specific implementation.
  function _makeFunctionFromRef(ref, sendPort) {
    return function() {
      return sendPort.callSync([ref, Array.prototype.slice.call(arguments)]);
    }
  }
})();
