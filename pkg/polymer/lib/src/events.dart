// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Code from declaration/events.js
part of polymer;

/// An extension of [polymer_expressions.PolymerExpressions] that adds support
/// for binding events using `on-eventName` using [PolymerEventBindings].
// TODO(jmesserly): the JS layering is a bit odd, with polymer-dev implementing
// events and polymer-expressions implementing everything else. I don't think
// this separation is right in the long term, so we're using the same class name
// until we can sort it out.
class PolymerExpressions extends BindingDelegate with PolymerEventBindings {

  /// A wrapper around polymer_expressions used to implement forwarding.
  /// Ideally we would inherit from it, but mixins can't be applied to a type
  /// that forwards to a superclass with a constructor that has optional or
  /// named arguments.
  final polymer_expressions.PolymerExpressions _delegate;

  Map<String, Object> get globals => _delegate.globals;

  PolymerExpressions({Map<String, Object> globals})
      : _delegate = new polymer_expressions.PolymerExpressions(
          globals: globals);

  prepareBinding(String path, name, node) {
    if (_hasEventPrefix(name)) {
      return prepareEventBinding(path, name, node);
    }
    return _delegate.prepareBinding(path, name, node);
  }

  prepareInstanceModel(Element template) =>
      _delegate.prepareInstanceModel(template);

  prepareInstancePositionChanged(Element template) =>
      _delegate.prepareInstancePositionChanged(template);

  static final getExpression =
      polymer_expressions.PolymerExpressions.getExpression;
  static final getBinding = polymer_expressions.PolymerExpressions.getBinding;

}

/// A mixin for a [BindingDelegate] to add Polymer event support.
/// This is included in [PolymerExpressions].
abstract class PolymerEventBindings {
  /// Finds the event controller for this node.
  Element findController(Node node) {
    while (node.parentNode != null) {
      if (node is Polymer && node.eventController != null) {
        return node.eventController;
      } else if (node is Element) {
        // If it is a normal element, js polymer element, or dart wrapper to a
        // js polymer element, then we try js interop.
        var eventController =
            new JsObject.fromBrowserObject(node)['eventController'];
        if (eventController != null) return eventController;
      }
      node = node.parentNode;
    }
    return node is ShadowRoot ? node.host : null;
  }

  EventListener getEventHandler(controller, target, String method) => (e) {
    if (controller == null || controller is! Polymer) {
      controller = findController(target);
    }

    if (controller is Polymer) {
      var detail = null;
      if (e is CustomEvent) {
        detail = e.detail;
        // TODO(sigmund): this shouldn't be necessary. See issue 19315.
        if (detail == null) {
          detail = new JsObject.fromBrowserObject(e)['detail'];
        }
      }
      var args = [e, detail, e.currentTarget];
      controller.dispatchMethod(controller, method, args);
    } else {
      throw new StateError('controller $controller is not a '
          'Dart polymer-element.');
    }
  };

  prepareEventBinding(String path, String name, Node node) {
    if (!_hasEventPrefix(name)) return null;

    var eventType = _removeEventPrefix(name);
    var translated = _eventTranslations[eventType];
    eventType = translated != null ? translated : eventType;

    return (model, node, oneTime) {
      var eventHandler =
          Zone.current.bindUnaryCallback(getEventHandler(null, node, path));
      // TODO(jakemac): Remove this indirection if/when JsFunction gets a
      // simpler constructor that doesn't pass this, http://dartbug.com/20545.
      var handler = new JsFunction.withThis((_, e) => eventHandler(e));
      _PolymerGestures.callMethod(
          'addEventListener', [node, eventType, handler]);

      if (oneTime) return null;
      return new _EventBindable(path, node, eventType, handler);
    };
  }
}


class _EventBindable extends Bindable {
  final String _path;
  final Node _node;
  final String _eventType;
  final JsFunction _handler;

  _EventBindable(this._path, this._node, this._eventType, this._handler);

  // TODO(rafaelw): This is really pointless work. Aside from the cost
  // of these allocations, NodeBind is going to setAttribute back to its
  // current value. Fixing this would mean changing the TemplateBinding
  // binding delegate API.
  get value => '{{ $_path }}';

  open(callback) => value;

  void close() {
    _PolymerGestures.callMethod(
        'removeEventListener', [_node, _eventType, _handler]);
  }
}


/// Attribute prefix used for declarative event handlers.
const _EVENT_PREFIX = 'on-';

/// Whether an attribute declares an event.
bool _hasEventPrefix(String attr) => attr.startsWith(_EVENT_PREFIX);

String _removeEventPrefix(String name) => name.substring(_EVENT_PREFIX.length);

// Dart note: polymer.js calls this mixedCaseEventTypes. But we have additional
// things that need translation due to renames.
final _eventTranslations = const {
  'domfocusout': 'DOMFocusOut',
  'domfocusin': 'DOMFocusIn',
  'dommousescroll': 'DOMMouseScroll',

  // Dart note: handle Dart-specific event names.
  'animationend': 'webkitAnimationEnd',
  'animationiteration': 'webkitAnimationIteration',
  'animationstart': 'webkitAnimationStart',
  'doubleclick': 'dblclick',
  'fullscreenchange': 'webkitfullscreenchange',
  'fullscreenerror': 'webkitfullscreenerror',
  'keyadded': 'webkitkeyadded',
  'keyerror': 'webkitkeyerror',
  'keymessage': 'webkitkeymessage',
  'needkey': 'webkitneedkey',
  'speechchange': 'webkitSpeechChange',
};

final _reverseEventTranslations = () {
  final map = new Map<String, String>();
  _eventTranslations.forEach((onName, eventType) {
    map[eventType] = onName;
  });
  return map;
}();

// Dart note: we need this function because we have additional renames JS does
// not have. The JS renames are simply case differences, whereas we have ones
// like doubleclick -> dblclick and stripping the webkit prefix.
String _eventNameFromType(String eventType) {
  final result = _reverseEventTranslations[eventType];
  return result != null ? result : eventType;
}
