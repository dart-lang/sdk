// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart DOM implementation.

function DOM$EnsureDartNull(value) {
  return value === null ? (void 0) : value;
}

function DOM$fixStatic(cls, key) {
  cls[key + '$getter'] = function() {
    return DOM$EnsureDartNull(cls[key]);
  };
}
function DOM$fixGetter(cls, key) {
  cls.prototype[key + '$getter'] = function() {
    return DOM$EnsureDartNull(this[key]);
  };
}
function DOM$fixSetter(cls, key) {
  cls.prototype[key + '$setter'] = function(x) { this[key] = x; };
}
function DOM$fixMember(cls, key) {
  cls.prototype[key + '$member'] = function () {
    return DOM$EnsureDartNull(this[key].apply(this, arguments));
  };
}
function DOM$fixProp(cls, key) {
  DOM$fixGetter(cls, key);
  DOM$fixSetter(cls, key);
}
function DOM$fixStatics(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixStatic(cls, keys[i]);
    }
  }
}
function DOM$fixAccessors(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls && cls.prototype) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixProp(cls, keys[i]);
    }
  }
}
function DOM$fixGetters(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls && cls.prototype) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixGetter(cls, keys[i]);
    }
  }
}
function DOM$fixMembers(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls && cls.prototype) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixMember(cls, keys[i]);
    }
  }
}

$(!GLOBAL)
function DOM$FixBindings(w) {

  // Have we been called to augment the prototypes on this window before?
  if (w.HTMLIFrameElement.prototype &&
     w.HTMLIFrameElement.prototype.contentWindow$getter) {
    return;
  }

  // TODO(vsm): Clean this up.  This is a workaround for Firefox 3.6 where
  // the Location prototype cannot be modified.
  // TODO(jacobr): unify the hacks for Navigator and Location.
  var tmpLocation = w.Location;
  if (w.location) {
    if (tmpLocation) {
      try {
        delete tmpLocation.prototype.get$dart$test;
      } catch (e) {
        w.Location = { prototype: w.location };
      }
    } else {
      w.Location = { prototype: w.location.__proto__ };
    }
  }
  // TODO(vsm): Clean this up.  This is a workaround for Firefox 3.6 where
  // the Navigator prototype cannot be modified.
  if (navigator.userAgent.indexOf("Firefox") != -1) {
    w.Navigator = { prototype: w.navigator };
  }
$(!INNER)
  if (tmpLocation) {
    w.Location = tmpLocation;
  }

  // Chrome still uses initWebKitWheelEvent.
  if (w && w.WheelEvent && w.WheelEvent.prototype &&
      !w.WheelEvent.prototype.initWheelEvent) {
    w.WheelEvent.prototype.initWheelEvent = function() {
      return this.initWebKitWheelEvent.apply(this, arguments);
    };
  }


  // Special implementations that fix the prototypes in a new context on the
  // fly.
  // TODO(sra): HTMLFrameElement, HTMLObjectElement
  if (w.HTMLIFrameElement) {
    w.HTMLIFrameElement$Dart = w.HTMLIFrameElement;
    w.HTMLIFrameElement.prototype.contentDocument$getter = function() {
      this.contentWindow$getter();  // Fix bindings in context
      return DOM$EnsureDartNull(this.contentDocument);
    };
    w.HTMLIFrameElement.prototype.contentWindow$getter = function() {
      var window = this.contentWindow;
      if (window) {
        DOM$FixBindings(window);
      }
      return DOM$EnsureDartNull(window);
    };
  }
} // end of DOM$FixBindings

if (this.window) {
  DOM$FixBindings(this.window);

  this.arguments = window;
}

// Declared in src/GlobalProperties.dart
function native__NativeDomGlobalProperties_getWindow() {
  // TODO: Should the window be obtained from an isolate?
  return window;
}

// Declared in src/GlobalProperties.dart
function native__NativeDomGlobalProperties_getDocument() {
  // TODO: Should the window be obtained from an isolate?
  return window.document;
}
