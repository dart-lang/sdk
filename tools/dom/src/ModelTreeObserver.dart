// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _ModelTreeObserver {
  static bool _initialized = false;

  /**
   * Start an observer watching the document for tree changes to automatically
   * propagate model changes.
   *
   * Currently this does not support propagation through Shadow DOMs.
   */
  static void initialize() {
    if (!_initialized) {
      _initialized = true;

      if (MutationObserver.supported) {
        var observer = new MutationObserver(_processTreeChange);
        observer.observe(document, childList: true, subtree: true);
      } else {
        document.on['DOMNodeInserted'].listen(_handleNodeInserted);
        document.on['DOMNodeRemoved'].listen(_handleNodeRemoved);
      }
    }
  }

  static void _processTreeChange(List<MutationRecord> mutations,
      MutationObserver observer) {
    for (var record in mutations) {
      for (var node in record.addedNodes) {
        // When nodes enter the document we need to make sure that all of the
        // models are properly propagated through the entire sub-tree.
        propagateModel(node, _calculatedModel(node), true);
      }
      for (var node in record.removedNodes) {
        propagateModel(node, _calculatedModel(node), false);
      }
    }
  }

  static void _handleNodeInserted(MutationEvent e) {
    var node = e.target;
    window.setImmediate(() {
      propagateModel(node, _calculatedModel(node), true);
    });
  }

  static void _handleNodeRemoved(MutationEvent e) {
    var node = e.target;
    window.setImmediate(() {
      propagateModel(node, _calculatedModel(node), false);
    });
  }

  /**
   * Figures out what the model should be for a node, avoiding any cached
   * model values.
   */
  static _calculatedModel(node) {
    if (node._hasLocalModel == true) {
      return node._model;
    } else if (node.parentNode != null) {
      return node.parentNode._model;
    }
    return null;
  }

  /**
   * Pushes model changes down through the tree.
   *
   * Set fullTree to true if the state of the tree is unknown and model changes
   * should be propagated through the entire tree.
   */
  static void propagateModel(Node node, model, bool fullTree) {
    // Calling into user code with the != call could generate exceptions.
    // Catch and report them a global exceptions.
    try {
      if (node._hasLocalModel != true && node._model != model &&
          node._modelChangedStreams != null &&
          !node._modelChangedStreams.isEmpty) {
        node._model = model;
        node._modelChangedStreams.toList()
          .forEach((controller) => controller.add(node));
      }
    } catch (e, s) {
      new Future.error(e, s);
    }
    for (var child = node.$dom_firstChild; child != null;
        child = child.nextNode) {
      if (child._hasLocalModel != true) {
        propagateModel(child, model, fullTree);
      } else if (fullTree) {
        propagateModel(child, child._model, true);
      }
    }
  }
}
