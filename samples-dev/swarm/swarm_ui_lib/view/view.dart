// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library view;

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;

import '../base/base.dart';
import '../observable/observable.dart';
import '../touch/touch.dart';
import '../layout/layout.dart';

part 'CompositeView.dart';
part 'ConveyorView.dart';
part 'MeasureText.dart';
part 'PagedViews.dart';
part 'SliderMenu.dart';

// TODO(rnystrom): Note! This class is undergoing heavy construction. It will
// temporary support both some old and some new ways of doing things until all
// subclasses are refactored to use the new way. There will be some scaffolding
// and construction cones laying around. Try not to freak out.

/** A generic view. */
class View implements Positionable {
  Element _node;
  ViewLayout _layout;

  // TODO(jmesserly): instead of tracking this on every View, we could have the
  // App track the views that want to be notified of resize()
  StreamSubscription _resizeSubscription;

  /**
   * Style properties configured for this view.
   */
  // TODO(jmesserly): We should be getting these from our CSS preprocessor.
  // I'm not sure if this will stay as a Map, or just be a get method.
  // TODO(jacobr): Consider returning a somewhat typed base.Style wrapper
  // object instead, and integrating with built in CSS properties.
  final Map<String, String> customStyle;

  View() : customStyle = new Map<String, String>();

  View.fromNode(Element this._node) : customStyle = new Map<String, String>();

  View.html(String html)
      : customStyle = new Map<String, String>(),
        _node = new Element.html(html);

  // TODO(rnystrom): Get rid of this when all views are refactored to not use
  // it.
  Element get node {
    // Lazy render.
    if (_node == null) {
      _render();
    }

    return _node;
  }

  /**
   * A subclass that contains child views should override this to return those
   * views. View uses this to ensure that child views are properly rendered
   * and initialized when their parent view is without the parent having to
   * manually handle that traversal.
   */
  Iterable<View> get childViews {
    return const [];
  }

  /**
   * View presumes the collection of views returned by childViews is more or
   * less static after the view is first created. Subclasses should call this
   * when that invariant doesn't hold to let View know that a new childView has
   * appeared.
   */
  void childViewAdded(View child) {
    if (isInDocument) {
      child._enterDocument();

      // TODO(jmesserly): is this too expensive?
      doLayout();
    }
  }

  /**
   * View presumes the collection of views returned by childViews is more or
   * less static after the view is first created. Subclasses should call this
   * when that invariant doesn't hold to let View know that a childView has
   * been removed.
   */
  void childViewRemoved(View child) {
    if (isInDocument) {
      child._exitDocument();
    }
  }

  /** Gets whether this View has already been rendered or not. */
  bool get isRendered {
    return _node != null;
  }

  /**
   * Gets whether this View (or one of its parents) has been added to the
   * document or not.
   */
  bool get isInDocument {
    return _node != null &&
        node.ownerDocument is HtmlDocument &&
        (node.ownerDocument as HtmlDocument).body.contains(node);
  }

  /**
   * Adds this view to the document as a child of the given node. This should
   * generally only be called once for the top-level view.
   */
  void addToDocument(Element parentNode) {
    assert(!isInDocument);

    _render();
    parentNode.nodes.add(_node);
    _hookGlobalLayoutEvents();
    _enterDocument();
  }

  void removeFromDocument() {
    assert(isInDocument);

    // Remove runs in reverse order of how we entered.
    _exitDocument();
    _unhookGlobalLayoutEvents();
    _node.remove();
  }

  /**
   * Override this to generate the DOM structure for the view.
   */
  // TODO(rnystrom): make this method abstract, see b/5015671
  Element render() {
    throw 'abstract';
  }

  /**
   * Override this to perform initialization behavior that requires access to
   * the DOM associated with the View, such as event wiring.
   */
  void afterRender(Element node) {
    // Do nothing by default.
  }

  /**
   * Override this to perform behavior after this View has been added to the
   * document. This is appropriate if you need access to state (such as the
   * calculated size of an element) that's only available when the View is in
   * the document.
   *
   * This will be called each time the View is added to the document, if it is
   * added and removed multiple times.
   */
  void enterDocument() {}

  /**
   * Override this to perform behavior after this View has been removed from the
   * document. This can be a convenient time to unregister event handlers bound
   * in enterDocument().
   *
   * This will be called each time the View is removed from the document, if it
   * is added and removed multiple times.
   */
  void exitDocument() {}

  /** Override this to perform behavior after the window is resized. */
  // TODO(jmesserly): this isn't really the event we want. Ideally we want to
  // fire the event only if this particular View changed size. Also we should
  // give a view the ability to measure itself when added to the document.
  void windowResized() {}

  /**
   * Registers the given listener callback to the given observable. Also
   * immediately invokes the callback once as if a change has just come in.
   * This lets you define a render() method that renders the skeleton of a
   * view, then register a bunch of listeners which all fire to populate the
   * view with model data.
   */
  void watch(Observable observable, void watcher(EventSummary summary)) {
    // Make a fake summary for the initial watch.
    final summary = new EventSummary(observable);
    watcher(summary);

    attachWatch(observable, watcher);
  }

  /** Registers the given listener callback to the given observable. */
  void attachWatch(Observable observable, void watcher(EventSummary summary)) {
    observable.addChangeListener(watcher);

    // TODO(rnystrom): Should keep track of this and unregister when the view
    // is discarded.
  }

  void addOnClick(EventListener handler) {
    _node.onClick.listen(handler);
  }

  /**
   * Gets whether the view is hidden.
   */
  bool get hidden => _node.style.display == 'none';

  /**
   * Sets whether the view is hidden.
   */
  void set hidden(bool hidden) {
    if (hidden) {
      node.style.display = 'none';
    } else {
      node.style.display = '';
    }
  }

  void addClass(String className) {
    node.classes.add(className);
  }

  void removeClass(String className) {
    node.classes.remove(className);
  }

  /** Sets the CSS3 transform applied to the view. */
  set transform(String transform) {
    node.style.transform = transform;
  }

  // TODO(rnystrom): Get rid of this, or move into a separate class?
  /** Creates a View whose node is a <div> with the given class(es). */
  static View div(String cssClass, [String body = null]) {
    if (body == null) {
      body = '';
    }
    return new View.html('<div class="$cssClass">$body</div>');
  }

  /**
   * Internal render method that deals with traversing child views. Should not
   * be overridden.
   */
  void _render() {
    // TODO(rnystrom): Should render child views here. Not implemented yet.
    // Instead, we rely on the parent accessing .node to implicitly cause the
    // child to be rendered.

    // Render this view.
    if (_node == null) {
      _node = render();
    }

    // Pass the node back to the derived view so it can register event
    // handlers on it.
    afterRender(_node);
  }

  /**
   * Internal method that deals with traversing child views. Should not be
   * overridden.
   */
  void _enterDocument() {
    // Notify the children first.
    for (final child in childViews) {
      child._enterDocument();
    }

    enterDocument();
  }

  // Layout related methods

  ViewLayout get layout {
    if (_layout == null) {
      _layout = new ViewLayout.fromView(this);
    }
    return _layout;
  }

  /**
   * Internal method that deals with traversing child views. Should not be
   * overridden.
   */
  void _exitDocument() {
    // Notify this View first so that it's children are still valid.
    exitDocument();

    // Notify the children.
    for (final child in childViews) {
      child._exitDocument();
    }
  }

  /**
   * If needed, starts a layout computation from the top level.
   * Also hooks the relevant events like window resize, so we can layout on too
   * demand.
   */
  void _hookGlobalLayoutEvents() {
    if (_resizeSubscription == null) {
      var handler = EventBatch.wrap((e) => doLayout());
      _resizeSubscription = window.onResize.listen(handler);
    }

    // Trigger the initial layout.
    doLayout();
  }

  void _unhookGlobalLayoutEvents() {
    if (_resizeSubscription != null) {
      _resizeSubscription.cancel();
      _resizeSubscription = null;
    }
  }

  void doLayout() {
    _measureLayout().then((changed) {
      if (changed) {
        _applyLayoutToChildren();
      }
    });
  }

  Future<bool> _measureLayout() {
    // TODO(10459): code should not use Completer.sync.
    final changed = new Completer<bool>.sync();
    _measureLayoutHelper(changed);

    var changedComplete = false;
    changed.future.then((_) {
      changedComplete = true;
    });

    scheduleMicrotask(() {
      if (!changedComplete) {
        changed.complete(false);
      }
    });
    return changed.future;
  }

  void _measureLayoutHelper(Completer<bool> changed) {
    windowResized();

    // TODO(jmesserly): this logic is more complex than it needs to be because
    // we're taking pains to not initialize _layout if it's not needed. Is that
    // a good tradeoff?
    if (ViewLayout.hasCustomLayout(this)) {
      // TODO(10459): code should not use Completer.sync.
      Completer sizeCompleter = new Completer<Size>.sync();
      scheduleMicrotask(() {
        sizeCompleter
            .complete(new Size(_node.client.width, _node.client.height));
      });
      layout.measureLayout(sizeCompleter.future, changed);
    } else {
      for (final child in childViews) {
        child._measureLayoutHelper(changed);
      }
    }
  }

  void _applyLayoutToChildren() {
    for (final child in childViews) {
      child._applyLayout();
    }
  }

  void _applyLayout() {
    if (_layout != null) {
      _layout.applyLayout();
    }
    _applyLayoutToChildren();
  }
}
