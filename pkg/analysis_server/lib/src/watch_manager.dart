// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:watcher/watcher.dart';

/**
 * A function called when a watch [event] associated with a watched resource is
 * received. The list of [tokens] will contain all of the tokens associated with
 * folders containing (or the same as) the watched resource.
 */
typedef void HandleWatchEvent<T>(WatchEvent event, List<T> tokens);

/**
 * An object that manages a collections of folders that need to be watched in
 * order to ensure that we are watching the minimum number of folders.
 *
 * Each folder can be watched multiple times. In order to differentiate between
 * the watch requests, each watch request has a *token* associated with it. The
 * tokens that are used must correctly implement both [==] and [hashCode].
 */
class WatchManager<T> {
  /**
   * The resource provider used to convert paths to resources.
   */
  final ResourceProvider provider;

  /**
   * The function that is invoked when a watch event is received.
   */
  final HandleWatchEvent<T> handleWatchEvent;

  /**
   * A node representing the (conceptual) root of all other folders.
   */
  final WatchNode<T> rootNode = new WatchNode<T>(null);

  /**
   * A table mapping the folders that are being watched to the nodes
   * representing those folders.
   */
  final Map<Folder, WatchNode<T>> _watchedFolders =
      new HashMap<Folder, WatchNode<T>>();

  /**
   * Initialize a newly created watch manager to use the resource [provider] to
   * convert file paths to resources and to call the [handleWatchEvent] function
   * to notify the owner of the manager when resources have been changed.
   */
  WatchManager(this.provider, this.handleWatchEvent);

  /**
   * Record the fact that we are now watching the given [folder], and associate
   * that folder with the given [token]. If the folder is already being watched
   * and is already associated with the token, then this request is effectively
   * ignored.
   */
  void addFolder(Folder folder, T token) {
    WatchNode<T> folderNode = _watchedFolders[folder];
    //
    // If the folder was already being watched, just record the new token.
    //
    if (folderNode != null) {
      folderNode.tokens.add(token);
      return;
    }
    //
    // Otherwise, add the folder to the tree.
    //
    folderNode = new WatchNode<T>(folder);
    _watchedFolders[folder] = folderNode;
    folderNode.tokens.add(token);
    WatchNode<T> parentNode = rootNode.insert(folderNode);
    //
    // If we are not watching a folder that contains the folder, then create a
    // subscription for it.
    //
    if (parentNode == rootNode) {
      folderNode.subscription = folder.changes.listen(_handleWatchEvent);
      //
      // Any nodes that became children of the newly added folder would have
      // been top-level folders and would have been watched. We need to cancel
      // their subscriptions.
      //
      for (WatchNode<T> childNode in folderNode.children) {
        assert(childNode.subscription != null);
        if (childNode.subscription != null) {
          childNode.subscription.cancel();
          childNode.subscription = null;
        }
      }
    }
  }

  /**
   * Record that we are no longer watching the given [folder] with the given
   * [token].
   *
   * Throws a [StateError] if the folder is not be watched or is not associated
   * with the given token.
   */
  void removeFolder(Folder folder, T token) {
    WatchNode<T> folderNode = _watchedFolders[folder];
    if (folderNode == null) {
      assert(false);
      return;
    }
    Set<T> tokens = folderNode.tokens;
    if (!tokens.remove(token)) {
      assert(false);
    }
    //
    // If this was the last token associated with this folder, then remove the
    // folder from the tree.
    //
    if (tokens.isEmpty) {
      //
      // If the folder was a top-level folder, then we need to create
      // subscriptions for all of its children and cancel its subscription.
      //
      if (folderNode.subscription != null) {
        for (WatchNode<T> childNode in folderNode.children) {
          assert(childNode.subscription == null);
          childNode.subscription =
              childNode.folder.changes.listen(_handleWatchEvent);
        }
        folderNode.subscription.cancel();
        folderNode.subscription = null;
      }
      folderNode.delete();
      _watchedFolders.remove(folder);
    }
  }

  /**
   * Dispatch the given event by finding all of the tokens that contain the
   * resource and invoke the [handleWatchEvent] function.
   */
  void _handleWatchEvent(WatchEvent event) {
    String path = event.path;
    List<T> tokens = <T>[];
    WatchNode<T> parent = rootNode.findParent(path);
    while (parent != rootNode) {
      tokens.addAll(parent.tokens);
      parent = parent.parent;
    }
    if (tokens.isNotEmpty) {
      handleWatchEvent(event, tokens);
    }
  }
}

/**
 * The information kept by a [WatchManager] about a single folder that is being
 * watched.
 *
 * Watch nodes form a tree in which one node is a child of another node if the
 * child's folder is contained in the parent's folder and none of the folders
 * between the parent's folder and the child's folder are being watched.
 */
class WatchNode<T> {
  /**
   * The folder for which information is being maintained. This is `null` for
   * the unique "root" node that maintains references to all of the top-level
   * folders being watched.
   */
  final Folder folder;

  /**
   * The parent of this node.
   */
  WatchNode<T> parent;

  /**
   * The information for the children of this node.
   */
  final List<WatchNode<T>> _children = <WatchNode<T>>[];

  /**
   * The tokens that were used to register interest in watching this folder.
   */
  final Set<T> tokens = new HashSet<T>();

  /**
   * The subscription being used to watch the folder, or `null` if the folder
   * is being watched as part of a containing folder (in other words, if the
   * parent is not the special "root").
   */
  StreamSubscription<WatchEvent> subscription;

  /**
   * Initialize a newly created node to represent the given [folder].
   */
  WatchNode(this.folder);

  /**
   * Return a list containing the children of this node.
   */
  Iterable<WatchNode<T>> get children => _children;

  /**
   * Remove this node from the tree of watched folders.
   */
  void delete() {
    if (parent != null) {
      parent._removeChild(this);
      parent = null;
    }
  }

  /**
   * Return the highest node reachable from this node that contains the given
   * [filePath]. If no other node is found, return this node, even if this node
   * does not contain the path.
   */
  WatchNode<T> findParent(String filePath) {
    if (_children == null) {
      return this;
    }
    for (WatchNode<T> childNode in _children) {
      if (childNode.folder.isOrContains(filePath)) {
        return childNode.findParent(filePath);
      }
    }
    return this;
  }

  /**
   * Insert the given [node] into the tree of watched folders, either as a child
   * of this node or as a descendent of one of this node's children. Return the
   * immediate parent of the newly added node.
   */
  WatchNode<T> insert(WatchNode<T> node) {
    WatchNode<T> parentNode = findParent(node.folder.path);
    parentNode._addChild(node, true);
    return parentNode;
  }

  @override
  String toString() => 'WatchNode ('
      'folder = ${folder == null ? '<root>' : folder.path}, '
      'tokens = $tokens, '
      'subscription = ${subscription == null ? 'null' : 'non-null'})';

  /**
   * Add the given [newChild] as an immediate child of this node.
   *
   * If [checkChildren] is `true`, check to see whether any of the previously
   * existing children of this node should now be children of the new child, and
   * if so, move them.
   */
  void _addChild(WatchNode<T> newChild, bool checkChildren) {
    if (checkChildren) {
      Folder folder = newChild.folder;
      for (int i = _children.length - 1; i >= 0; i--) {
        WatchNode<T> existingChild = _children[i];
        if (folder.contains(existingChild.folder.path)) {
          newChild._addChild(existingChild, false);
          _children.removeAt(i);
        }
      }
    }
    newChild.parent = this;
    _children.add(newChild);
  }

  /**
   * Remove the given [node] from the list of children of this node. Any
   * children of the [node] will become children of this node.
   */
  void _removeChild(WatchNode<T> child) {
    _children.remove(child);
    Iterable<WatchNode<T>> grandchildren = child.children;
    for (WatchNode<T> grandchild in grandchildren) {
      grandchild.parent = this;
      _children.add(grandchild);
    }
    child._children.clear();
  }
}
