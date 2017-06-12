// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/watch_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WatchManagerTest);
    defineReflectiveTests(WatchNodeTest);
  });
}

/**
 * Tokens that can be used for testing purposes.
 */
class Token {
  /**
   * A name used for debugging.
   */
  final String name;

  /**
   * Initialize a newly created token to have the given name.
   */
  Token(this.name);

  @override
  String toString() => name;
}

/**
 * A listener that captures the state of watch events so that they can be
 * tested.
 */
class WatchListener {
  /**
   * The event that was passed to the listener method.
   */
  WatchEvent event;

  /**
   * The tokens that were passed to the listener method.
   */
  List<Token> tokens;

  /**
   * Clear the state so that we can distinguish between not receiving an event
   * and receiving the wrong event.
   */
  void clear() {
    this.event = null;
    this.tokens = null;
  }

  /**
   * The listener method.
   */
  void handleWatchEvent(WatchEvent event, List<Token> tokens) {
    this.event = event;
    this.tokens = tokens;
  }
}

@reflectiveTest
class WatchManagerTest {
  MemoryResourceProvider provider;
  WatchListener listener;
  WatchManager<Token> manager;

  void setUp() {
    provider = new MemoryResourceProvider();
    listener = new WatchListener();
    manager = new WatchManager<Token>(provider, listener.handleWatchEvent);
  }

  Future test_addFolder_folderAndSubfolder() async {
    Folder topFolder = provider.getFolder('/a/b');
    Folder childFolder = provider.getFolder('/a/b/c/d');
    Token topToken = new Token('topToken');
    Token childToken = new Token('childToken');
    manager.addFolder(topFolder, topToken);
    manager.addFolder(childFolder, childToken);

    File newFile1 = provider.newFile('/a/b/c/lib.dart', '');
    await _expectEvent(ChangeType.ADD, newFile1.path, [topToken]);

    File newFile2 = provider.newFile('/a/b/c/d/lib.dart', '');
    return _expectEvent(ChangeType.ADD, newFile2.path, [topToken, childToken]);
  }

  Future test_addFolder_singleFolder_multipleTokens() {
    Folder folder = provider.getFolder('/a/b');
    Token token1 = new Token('token1');
    Token token2 = new Token('token2');
    manager.addFolder(folder, token1);
    manager.addFolder(folder, token2);

    File newFile = provider.newFile('/a/b/lib.dart', '');
    return _expectEvent(ChangeType.ADD, newFile.path, [token1, token2]);
  }

  Future test_addFolder_singleFolder_singleToken() async {
    Folder folder = provider.getFolder('/a/b');
    Token token = new Token('token');
    manager.addFolder(folder, token);

    Folder newFolder = provider.newFolder('/a/b/c');
    await _expectEvent(ChangeType.ADD, newFolder.path, [token]);

    File newFile = provider.newFile('/a/b/c/lib.dart', '');
    return _expectEvent(ChangeType.ADD, newFile.path, [token]);
  }

  Future test_addFolder_unrelatedFolders() async {
    Folder folder1 = provider.getFolder('/a/b');
    Folder folder2 = provider.getFolder('/c/d');
    Token token1 = new Token('token1');
    Token token2 = new Token('token2');
    manager.addFolder(folder1, token1);
    manager.addFolder(folder2, token2);

    File newFile1 = provider.newFile('/a/b/lib.dart', '');
    await _expectEvent(ChangeType.ADD, newFile1.path, [token1]);

    File newFile2 = provider.newFile('/c/d/lib.dart', '');
    return _expectEvent(ChangeType.ADD, newFile2.path, [token2]);
  }

  void test_creation() {
    expect(manager, isNotNull);
  }

  Future test_removeFolder_multipleTokens() {
    Folder folder = provider.getFolder('/a/b');
    Token token1 = new Token('token1');
    Token token2 = new Token('token2');
    manager.addFolder(folder, token1);
    manager.addFolder(folder, token2);
    manager.removeFolder(folder, token2);

    File newFile = provider.newFile('/a/b/lib.dart', '');
    return _expectEvent(ChangeType.ADD, newFile.path, [token1]);
  }

  Future test_removeFolder_withChildren() async {
    Folder topFolder = provider.getFolder('/a/b');
    Folder childFolder = provider.getFolder('/a/b/c/d');
    Token topToken = new Token('topToken');
    Token childToken = new Token('childToken');
    manager.addFolder(topFolder, topToken);
    manager.addFolder(childFolder, childToken);
    manager.removeFolder(topFolder, topToken);

    File newFile = provider.newFile('/a/b/c/d/lib.dart', '');
    await _expectEvent(ChangeType.ADD, newFile.path, [childToken]);

    provider.newFile('/a/b/lib.dart', '');
    return _expectNoEvent();
  }

  Future test_removeFolder_withNoChildren() {
    Folder folder = provider.getFolder('/a/b');
    Token token = new Token('token');
    manager.addFolder(folder, token);
    manager.removeFolder(folder, token);

    provider.newFile('/a/b/lib.dart', '');
    return _expectNoEvent();
  }

  Future _expectEvent(ChangeType expectedType, String expectedPath,
      List<Token> expectedTokens) async {
    await pumpEventQueue();
    WatchEvent event = listener.event;
    expect(event, isNotNull);
    expect(event.type, expectedType);
    expect(event.path, expectedPath);
    expect(listener.tokens, unorderedEquals(expectedTokens));
    listener.clear();
  }

  Future _expectNoEvent() async {
    await pumpEventQueue();
    expect(listener.event, isNull);
    expect(listener.tokens, isNull);
  }
}

@reflectiveTest
class WatchNodeTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();

  void test_creation_folder() {
    Folder folder = provider.getFolder('/a/b');
    WatchNode node = new WatchNode(folder);
    expect(node, isNotNull);
    expect(node.children, isEmpty);
    expect(node.folder, folder);
    expect(node.parent, isNull);
    expect(node.subscription, isNull);
    expect(node.tokens, isEmpty);
  }

  void test_creation_noFolder() {
    WatchNode node = new WatchNode(null);
    expect(node, isNotNull);
    expect(node.children, isEmpty);
    expect(node.folder, isNull);
    expect(node.parent, isNull);
    expect(node.subscription, isNull);
    expect(node.tokens, isEmpty);
  }

  void test_delete_nested_child() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    WatchNode childNode = new WatchNode(provider.getFolder('/a/b/c/d'));
    WatchNode grandchildNode = new WatchNode(provider.getFolder('/a/b/c/d/e'));
    rootNode.insert(topNode);
    rootNode.insert(childNode);
    rootNode.insert(grandchildNode);

    childNode.delete();
    expect(rootNode.children, equals([topNode]));
    expect(topNode.children, equals([grandchildNode]));
    expect(topNode.parent, rootNode);
    expect(grandchildNode.parent, topNode);
  }

  void test_delete_nested_noChild() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    WatchNode childNode = new WatchNode(provider.getFolder('/a/b/c/d'));
    rootNode.insert(topNode);
    rootNode.insert(childNode);

    childNode.delete();
    expect(rootNode.children, equals([topNode]));
    expect(topNode.children, isEmpty);
    expect(topNode.parent, rootNode);
  }

  void test_delete_top_child() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    WatchNode childNode = new WatchNode(provider.getFolder('/a/b/c/d'));
    rootNode.insert(topNode);
    rootNode.insert(childNode);

    topNode.delete();
    expect(rootNode.children, equals([childNode]));
    expect(childNode.parent, rootNode);
  }

  void test_delete_top_noChild() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    rootNode.insert(topNode);

    topNode.delete();
    expect(rootNode.children, isEmpty);
  }

  void test_findParent_childOfLeaf() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    rootNode.insert(topNode);

    expect(rootNode.findParent('/a/b/c'), topNode);
  }

  void test_findParent_childOfNonLeaf() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    WatchNode childNode = new WatchNode(provider.getFolder('/a/b/c/d'));
    rootNode.insert(topNode);
    rootNode.insert(childNode);

    expect(rootNode.findParent('/a/b/c'), topNode);
  }

  void test_findParent_noMatch() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    rootNode.insert(topNode);

    expect(rootNode.findParent('/c/d'), rootNode);
  }

  void test_insert_intermediate_afterParentAndChild() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    WatchNode childNode = new WatchNode(provider.getFolder('/a/b/c/d'));
    WatchNode intermediateNode = new WatchNode(provider.getFolder('/a/b/c'));

    rootNode.insert(topNode);
    rootNode.insert(childNode);
    rootNode.insert(intermediateNode);
    expect(topNode.parent, rootNode);
    expect(topNode.children, equals([intermediateNode]));
    expect(intermediateNode.parent, topNode);
    expect(intermediateNode.children, equals([childNode]));
    expect(childNode.parent, intermediateNode);
    expect(childNode.children, isEmpty);
  }

  void test_insert_nested_afterParent() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    WatchNode childNode = new WatchNode(provider.getFolder('/a/b/c/d'));

    rootNode.insert(topNode);
    rootNode.insert(childNode);
    expect(childNode.parent, topNode);
    expect(childNode.children, isEmpty);
    expect(topNode.children, equals([childNode]));
  }

  void test_insert_nested_beforeParent() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));
    WatchNode childNode = new WatchNode(provider.getFolder('/a/b/c/d'));

    rootNode.insert(childNode);
    rootNode.insert(topNode);
    expect(childNode.parent, topNode);
    expect(childNode.children, isEmpty);
    expect(topNode.children, equals([childNode]));
  }

  void test_insert_top() {
    WatchNode rootNode = new WatchNode(null);
    WatchNode topNode = new WatchNode(provider.getFolder('/a/b'));

    rootNode.insert(topNode);
    expect(rootNode.children, equals([topNode]));
    expect(topNode.parent, rootNode);
    expect(topNode.children, isEmpty);
  }
}
