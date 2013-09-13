// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.polymer_element;

import 'dart:async';
import 'dart:html';
import 'dart:mirrors';
import 'dart:js' as dartJs;

import 'package:custom_element/custom_element.dart';
import 'package:js/js.dart' as js;
import 'package:mdv/mdv.dart' show NodeBinding;
import 'package:observe/observe.dart';
import 'package:observe/src/microtask.dart';
import 'package:polymer_expressions/polymer_expressions.dart';

import 'src/utils.dart' show toCamelCase, toHyphenedName;

/**
 * Registers a [PolymerElement]. This is similar to [registerCustomElement]
 * but it is designed to work with the `<element>` element and adds additional
 * features.
 */
void registerPolymerElement(String localName, PolymerElement create()) {
  registerCustomElement(localName, () => create().._initialize(localName));
}

/**
 * *Warning*: many features of this class are not fully implemented.
 *
 * The base class for Polymer elements. It provides convience features on top
 * of the custom elements web standard.
 *
 * Currently it supports publishing attributes via:
 *
 *     <element name="..." attributes="foo, bar, baz">
 *
 * Any attribute published this way can be used in a data binding expression,
 * and it should contain a corresponding DOM field.
 *
 * *Warning*: due to dart2js mirror limititations, the mapping from HTML
 * attribute to element property is a conversion from `dash-separated-words`
 * to camelCase, rather than searching for a property with the same name.
 */
// TODO(jmesserly): fix the dash-separated-words issue. Polymer uses lowercase.
class PolymerElement extends CustomElement with _EventsMixin {
  // This is a partial port of:
  // https://github.com/Polymer/polymer/blob/stable/src/attrs.js
  // https://github.com/Polymer/polymer/blob/stable/src/bindProperties.js
  // https://github.com/Polymer/polymer/blob/7936ff8/src/declaration/events.js
  // https://github.com/Polymer/polymer/blob/7936ff8/src/instance/events.js
  // TODO(jmesserly): we still need to port more of the functionality

  /// The one syntax to rule them all.
  static BindingDelegate _polymerSyntax = new PolymerExpressions();
  // TODO(sigmund): delete. The next line is only added to avoid warnings from
  // the analyzer (see http://dartbug.com/11672)
  Element get host => super.host;

  bool get applyAuthorStyles => false;
  bool get resetStyleInheritance => false;

  /**
   * The declaration of this polymer-element, used to extract template contents
   * and other information.
   */
  static Map<String, Element> _declarations = {};
  static Element getDeclaration(String localName) {
    if (localName == null) return null;
    var element = _declarations[localName];
    if (element == null) {
      element = document.query('polymer-element[name="$localName"]');
      _declarations[localName] = element;
    }
    return element;
  }

  Map<String, PathObserver> _publishedAttrs;
  Map<String, StreamSubscription> _bindings;
  final List<String> _localNames = [];

  void _initialize(String localName) {
    if (localName == null) return;

    var declaration = getDeclaration(localName);
    if (declaration == null) return;

    if (declaration.attributes['extends'] != null) {
      var base = declaration.attributes['extends'];
      // Skip normal tags, only initialize parent custom elements.
      if (base.contains('-')) _initialize(base);
    }

    _parseHostEvents(declaration);
    _parseLocalEvents(declaration);
    _publishAttributes(declaration);
    _localNames.add(localName);
  }

  void _publishAttributes(elementElement) {
    _bindings = {};
    _publishedAttrs = {};

    var attrs = elementElement.attributes['attributes'];
    if (attrs != null) {
      // attributes='a b c' or attributes='a,b,c'
      for (var name in attrs.split(attrs.contains(',') ? ',' : ' ')) {
        name = name.trim();

        // TODO(jmesserly): PathObserver is overkill here; it helps avoid
        // "new Symbol" and other mirrors-related warnings.
        _publishedAttrs[name] = new PathObserver(this, toCamelCase(name));
      }
    }
  }

  void created() {
    // TODO(jmesserly): this breaks until we get some kind of type conversion.
    // _publishedAttrs.forEach((name, propObserver) {
    // var value = attributes[name];
    //   if (value != null) propObserver.value = value;
    // });
    _initShadowRoot();
    _addHostListeners();
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

  void _initShadowRoot() {
    for (var localName in _localNames) {
      var declaration = getDeclaration(localName);
      var root = createShadowRoot(localName);
      _addInstanceListeners(root, localName);

      root.applyAuthorStyles = applyAuthorStyles;
      root.resetStyleInheritance = resetStyleInheritance;

      var templateNode = declaration.children.firstWhere(
          (n) => n.localName == 'template', orElse: () => null);
      if (templateNode == null) return;

      // Create the contents of the element's ShadowRoot, and add them.
      root.nodes.add(instanceTemplate(templateNode));

      var extendsName = declaration.attributes['extends'];
      _shimCss(root, localName, extendsName);
    }
  }

  NodeBinding createBinding(String name, model, String path) {
    var propObserver = _publishedAttrs[name];
    if (propObserver != null) {
      return new _PolymerBinding(this, name, model, path, propObserver);
    }
    return super.createBinding(name, model, path);
  }

  /**
   * Using Polymer's platform/src/ShadowCSS.js passing the style tag's content.
   */
  void _shimCss(ShadowRoot root, String localName, String extendsName) {
    // TODO(terry): Need to detect if ShadowCSS.js has been loaded.  Under
    //              Dartium this wouldn't exist.  However, dart:js isn't robust
    //              to use to detect in both Dartium and dart2js if Platform is
    //              defined.  This bug is described in
    //              https://code.google.com/p/dart/issues/detail?id=12548
    //              When fixed only use dart:js.  This is necessary under
    //              Dartium (no compile) we want to run w/o the JS polyfill.
    if (dartJs.context == null || !dartJs.context.hasProperty('Platform')) {
      return;
    }

    var platform = js.context["Platform"];
    if (platform == null) return;
    var shadowCss = platform.ShadowCSS;
    if (shadowCss == null) return;

    // TODO(terry): Remove calls to shimShadowDOMStyling2 and replace with
    //              shimShadowDOMStyling when we support unwrapping dart:html
    //              Element to a JS DOM node.
    var shimShadowDOMStyling2 = shadowCss.shimShadowDOMStyling2;
    if (shimShadowDOMStyling2 == null) return;
    var style = root.query('style');
    if (style == null) return;
    var scopedCSS = shimShadowDOMStyling2(style.text, localName);

    // TODO(terry): Remove when shimShadowDOMStyling is called we don't need to
    //              replace original CSS with scoped CSS shimShadowDOMStyling
    //              does that.
    style.text = scopedCSS;
  }
}

class _PolymerBinding extends NodeBinding {
  final PathObserver _publishedAttr;

  _PolymerBinding(node, property, model, path, PathObserver this._publishedAttr)
      : super(node, property, model, path);

  void boundValueChanged(newValue) {
    _publishedAttr.value = newValue;
  }
}

/**
 * Polymer features to handle the syntactic sugar on-* to declare to
 * automatically map event handlers to instance methods of the [PolymerElement].
 * This mixin is a port of:
 * https://github.com/Polymer/polymer/blob/7936ff8/src/declaration/events.js
 * https://github.com/Polymer/polymer/blob/7936ff8/src/instance/events.js
 */
abstract class _EventsMixin {
  // TODO(sigmund): implement the Dart equivalent of 'inheritDelegates'
  // Notes about differences in the implementation below:
  //  - _templateDelegates: polymer stores the template delegates directly on
  //    the template node (see in parseLocalEvents: 't.delegates = {}'). Here we
  //    simply use a separate map, where keys are the name of the
  //    custom-element.
  //  - _listenLocal we return true/false and propagate that up, JS
  //    implementation does't forward the return value.
  //  - we don't keep the side-table (weak hash map) of unhandled events (see
  //    handleIfNotHandled)
  //  - we don't use event.type to dispatch events, instead we save the event
  //    name with the event listeners. We do so to avoid translating back and
  //    forth between Dom and Dart event names.

  // ---------------------------------------------------------------------------
  // The following section was ported from:
  // https://github.com/Polymer/polymer/blob/7936ff8/src/declaration/events.js
  // ---------------------------------------------------------------------------

  /** Maps event names and their associated method in the element class. */
  final Map<String, String> _delegates = {};

  /** Expected events per element node. */
  // TODO(sigmund): investigate whether we need more than 1 set of local events
  // per element (why does the js implementation stores 1 per template node?)
  final Map<String, Set<String>> _templateDelegates =
      new Map<String, Set<String>>();

  /** [host] is needed by this mixin, but not defined here. */
  Element get host;

  /** Attribute prefix used for declarative event handlers. */
  static const _eventPrefix = 'on-';

  /** Whether an attribute declares an event. */
  static bool _isEvent(String attr) => attr.startsWith(_eventPrefix);

  /** Extracts events from the element tag attributes. */
  void _parseHostEvents(elementElement) {
    for (var attr in elementElement.attributes.keys.where(_isEvent)) {
      _delegates[toCamelCase(attr)] = elementElement.attributes[attr];
    }
  }

  /** Extracts events under the element's <template>. */
  void _parseLocalEvents(elementElement) {
    var name = elementElement.attributes["name"];
    if (name == null) return;
    var events = null;
    for (var template in elementElement.queryAll('template')) {
      var content = template.content;
      if (content != null) {
        for (var child in content.children) {
          events = _accumulateEvents(child, events);
        }
      }
    }
    if (events != null) {
      _templateDelegates[name] = events;
    }
  }

  /** Returns all events names listened by [element] and it's children. */
  static Set<String> _accumulateEvents(Element element, [Set<String> events]) {
    events = events == null ? new Set<String>() : events;

    // from: accumulateAttributeEvents, accumulateEvent
    events.addAll(element.attributes.keys.where(_isEvent).map(toCamelCase));

    // from: accumulateChildEvents
    for (var child in element.children) {
      _accumulateEvents(child, events);
    }

    // from: accumulateTemplatedEvents
    if (element.isTemplate) {
      var content = element.content;
      if (content != null) {
        for (var child in content.children) {
          _accumulateEvents(child, events);
        }
      }
    }
    return events;
  }

  // ---------------------------------------------------------------------------
  // The following section was ported from:
  // https://github.com/Polymer/polymer/blob/7936ff8/src/instance/events.js
  // ---------------------------------------------------------------------------

  /** Attaches event listeners on the [host] element. */
  void _addHostListeners() {
    for (var eventName in _delegates.keys) {
      _addNodeListener(host, eventName,
          (e) => _hostEventListener(eventName, e));
    }
  }

  void _addNodeListener(node, String onEvent, Function listener) {
    // If [node] is an element (typically when listening for host events) we
    // use directly the '.onFoo' event stream of the element instance.
    if (node is Element) {
      reflect(node).getField(new Symbol(onEvent)).reflectee.listen(listener);
      return;
    }

    // When [node] is not an element, most commonly when [node] is the
    // shadow-root of the polymer-element, we find the appropriate static event
    // stream providers and attach it to [node].
    var eventProvider = _eventStreamProviders[onEvent];
    if (eventProvider != null) {
      eventProvider.forTarget(node).listen(listener);
      return;
    }

    // When no provider is available, mainly because of custom-events, we use
    // the underlying event listeners from the DOM.
    var eventName = onEvent.substring(2).toLowerCase(); // onOneTwo => onetwo
    // Most events names in Dart match those in JS in lowercase except for some
    // few events listed in this map. We expect these cases to be handled above,
    // but just in case we include them as a safety net here.
    var jsNameFixes = const {
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
    var fixedName = jsNameFixes[eventName];
    node.on[fixedName != null ? fixedName : eventName].listen(listener);
  }

  void _addInstanceListeners(ShadowRoot root, String elementName) {
    var events = _templateDelegates[elementName];
    if (events == null) return;
    for (var eventName in events) {
      _addNodeListener(root, eventName,
          (e) => _instanceEventListener(eventName, e));
    }
  }

  void _hostEventListener(String eventName, Event event) {
    var method = _delegates[eventName];
    if (event.bubbles && method != null) {
      _dispatchMethod(this, method, event, host);
    }
  }

  void _dispatchMethod(Object receiver, String methodName, Event event,
      Node target) {
    var detail = event is CustomEvent ? (event as CustomEvent).detail : null;
    var args = [event, detail, target];

    var method = new Symbol(methodName);
    // TODO(sigmund): consider making event listeners list all arguments
    // explicitly. Unless VM mirrors are optimized first, this reflectClass call
    // will be expensive once custom elements extend directly from Element (see
    // dartbug.com/11108).
    var methodDecl = reflectClass(receiver.runtimeType).methods[method];
    if (methodDecl != null) {
      // This will either truncate the argument list or extend it with extra
      // null arguments, so it will match the signature.
      // TODO(sigmund): consider accepting optional arguments when we can tell
      // them appart from named arguments (see http://dartbug.com/11334)
      args.length = methodDecl.parameters.where((p) => !p.isOptional).length;
    }
    reflect(receiver).invoke(method, args);
    performMicrotaskCheckpoint();
  }

  bool _instanceEventListener(String eventName, Event event) {
    if (event.bubbles) {
      if (event.path == null || !ShadowRoot.supported) {
        return _listenLocalNoEventPath(eventName, event);
      } else {
        return _listenLocal(eventName, event);
      }
    }
    return false;
  }

  bool _listenLocal(String eventName, Event event) {
    var controller = null;
    for (var target in event.path) {
      // if we hit host, stop
      if (target == host) return true;

      // find a controller for the target, unless we already found `host`
      // as a controller
      controller = (controller == host) ? controller : _findController(target);

      // if we have a controller, dispatch the event, and stop if the handler
      // returns true
      if (controller != null
          && handleEvent(controller, eventName, event, target)) {
        return true;
      }
    }
    return false;
  }

  // TODO(sorvell): remove when ShadowDOM polyfill supports event path.
  // Note that _findController will not return the expected controller when the
  // event target is a distributed node.  This is because we cannot traverse
  // from a composed node to a node in shadowRoot.
  // This will be addressed via an event path api
  // https://www.w3.org/Bugs/Public/show_bug.cgi?id=21066
  bool _listenLocalNoEventPath(String eventName, Event event) {
    var target = event.target;
    var controller = null;
    while (target != null && target != host) {
      controller = (controller == host) ? controller : _findController(target);
      if (controller != null
          && handleEvent(controller, eventName, event, target)) {
        return true;
      }
      target = target.parent;
    }
    return false;
  }

  // TODO(sigmund): investigate if this implementation is correct. Polymer looks
  // up the shadow-root that contains [node] and uses a weak-hashmap to find the
  // host associated with that root. This implementation assumes that the
  // [node] is under [host]'s shadow-root.
  Element _findController(Node node) => host.xtag;

  bool handleEvent(
      Element controller, String eventName, Event event, Element element) {
    // Note: local events are listened only in the shadow root. This dynamic
    // lookup is used to distinguish determine whether the target actually has a
    // listener, and if so, to determine lazily what's the target method.
    var methodName = element.attributes[toHyphenedName(eventName)];
    if (methodName != null) {
      _dispatchMethod(controller, methodName, event, element);
    }
    return event.bubbles;
  }
}


/** Event stream providers per event name. */
// TODO(sigmund): after dartbug.com/11108 is fixed, consider eliminating this
// table and using reflection instead.
const Map<String, EventStreamProvider> _eventStreamProviders = const {
  'onMouseWheel': Element.mouseWheelEvent,
  'onTransitionEnd': Element.transitionEndEvent,
  'onAbort': Element.abortEvent,
  'onBeforeCopy': Element.beforeCopyEvent,
  'onBeforeCut': Element.beforeCutEvent,
  'onBeforePaste': Element.beforePasteEvent,
  'onBlur': Element.blurEvent,
  'onChange': Element.changeEvent,
  'onClick': Element.clickEvent,
  'onContextMenu': Element.contextMenuEvent,
  'onCopy': Element.copyEvent,
  'onCut': Element.cutEvent,
  'onDoubleClick': Element.doubleClickEvent,
  'onDrag': Element.dragEvent,
  'onDragEnd': Element.dragEndEvent,
  'onDragEnter': Element.dragEnterEvent,
  'onDragLeave': Element.dragLeaveEvent,
  'onDragOver': Element.dragOverEvent,
  'onDragStart': Element.dragStartEvent,
  'onDrop': Element.dropEvent,
  'onError': Element.errorEvent,
  'onFocus': Element.focusEvent,
  'onInput': Element.inputEvent,
  'onInvalid': Element.invalidEvent,
  'onKeyDown': Element.keyDownEvent,
  'onKeyPress': Element.keyPressEvent,
  'onKeyUp': Element.keyUpEvent,
  'onLoad': Element.loadEvent,
  'onMouseDown': Element.mouseDownEvent,
  'onMouseMove': Element.mouseMoveEvent,
  'onMouseOut': Element.mouseOutEvent,
  'onMouseOver': Element.mouseOverEvent,
  'onMouseUp': Element.mouseUpEvent,
  'onPaste': Element.pasteEvent,
  'onReset': Element.resetEvent,
  'onScroll': Element.scrollEvent,
  'onSearch': Element.searchEvent,
  'onSelect': Element.selectEvent,
  'onSelectStart': Element.selectStartEvent,
  'onSubmit': Element.submitEvent,
  'onTouchCancel': Element.touchCancelEvent,
  'onTouchEnd': Element.touchEndEvent,
  'onTouchEnter': Element.touchEnterEvent,
  'onTouchLeave': Element.touchLeaveEvent,
  'onTouchMove': Element.touchMoveEvent,
  'onTouchStart': Element.touchStartEvent,
  'onFullscreenChange': Element.fullscreenChangeEvent,
  'onFullscreenError': Element.fullscreenErrorEvent,
  'onAutocomplete': FormElement.autocompleteEvent,
  'onAutocompleteError': FormElement.autocompleteErrorEvent,
  'onSpeechChange': InputElement.speechChangeEvent,
  'onCanPlay': MediaElement.canPlayEvent,
  'onCanPlayThrough': MediaElement.canPlayThroughEvent,
  'onDurationChange': MediaElement.durationChangeEvent,
  'onEmptied': MediaElement.emptiedEvent,
  'onEnded': MediaElement.endedEvent,
  'onLoadStart': MediaElement.loadStartEvent,
  'onLoadedData': MediaElement.loadedDataEvent,
  'onLoadedMetadata': MediaElement.loadedMetadataEvent,
  'onPause': MediaElement.pauseEvent,
  'onPlay': MediaElement.playEvent,
  'onPlaying': MediaElement.playingEvent,
  'onProgress': MediaElement.progressEvent,
  'onRateChange': MediaElement.rateChangeEvent,
  'onSeeked': MediaElement.seekedEvent,
  'onSeeking': MediaElement.seekingEvent,
  'onShow': MediaElement.showEvent,
  'onStalled': MediaElement.stalledEvent,
  'onSuspend': MediaElement.suspendEvent,
  'onTimeUpdate': MediaElement.timeUpdateEvent,
  'onVolumeChange': MediaElement.volumeChangeEvent,
  'onWaiting': MediaElement.waitingEvent,
  'onKeyAdded': MediaElement.keyAddedEvent,
  'onKeyError': MediaElement.keyErrorEvent,
  'onKeyMessage': MediaElement.keyMessageEvent,
  'onNeedKey': MediaElement.needKeyEvent,
  'onWebGlContextLost': CanvasElement.webGlContextLostEvent,
  'onWebGlContextRestored': CanvasElement.webGlContextRestoredEvent,
  'onPointerLockChange': Document.pointerLockChangeEvent,
  'onPointerLockError': Document.pointerLockErrorEvent,
  'onReadyStateChange': Document.readyStateChangeEvent,
  'onSelectionChange': Document.selectionChangeEvent,
  'onSecurityPolicyViolation': Document.securityPolicyViolationEvent,
};
