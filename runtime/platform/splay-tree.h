// Copyright (c) 2010, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// The original file can be found at:
// https://github.com/v8/v8/blob/master/src/splay-tree.h

#ifndef RUNTIME_PLATFORM_SPLAY_TREE_H_
#define RUNTIME_PLATFORM_SPLAY_TREE_H_

#include "platform/allocation.h"

namespace dart {

// A splay tree.  The config type parameter encapsulates the different
// configurations of a concrete splay tree:
//
//   typedef Key: the key type
//   typedef Value: the value type
//   static const Key kNoKey: the dummy key used when no key is set
//   static Value kNoValue(): the dummy value used to initialize nodes
//   static int (Compare)(Key& a, Key& b) -> {-1, 0, 1}: comparison function
//
// The tree is also parameterized by an allocation policy
// (Allocator). The policy is used for allocating lists in the C free
// store or the zone; see zone.h.

template <typename Config, class B, class Allocator>
class SplayTree : public B {
 public:
  typedef typename Config::Key Key;
  typedef typename Config::Value Value;

  class Locator;

  explicit SplayTree(Allocator* allocator)
      : root_(nullptr), allocator_(allocator) {}
  ~SplayTree();

  Allocator* allocator() { return allocator_; }

  // Checks if there is a mapping for the key.
  bool Contains(const Key& key);

  // Inserts the given key in this tree with the given value.  Returns
  // true if a node was inserted, otherwise false.  If found the locator
  // is enabled and provides access to the mapping for the key.
  bool Insert(const Key& key, Locator* locator);

  // Looks up the key in this tree and returns true if it was found,
  // otherwise false.  If the node is found the locator is enabled and
  // provides access to the mapping for the key.
  bool Find(const Key& key, Locator* locator);

  // Finds the mapping with the greatest key less than or equal to the
  // given key.
  bool FindGreatestLessThan(const Key& key, Locator* locator);

  // Find the mapping with the greatest key in this tree.
  bool FindGreatest(Locator* locator);

  // Finds the mapping with the least key greater than or equal to the
  // given key.
  bool FindLeastGreaterThan(const Key& key, Locator* locator);

  // Find the mapping with the least key in this tree.
  bool FindLeast(Locator* locator);

  // Move the node from one key to another.
  bool Move(const Key& old_key, const Key& new_key);

  // Remove the node with the given key from the tree.
  bool Remove(const Key& key);

  // Remove all keys from the tree.
  void Clear() { ResetRoot(); }

  bool is_empty() { return root_ == nullptr; }

  // Perform the splay operation for the given key. Moves the node with
  // the given key to the top of the tree.  If no node has the given
  // key, the last node on the search path is moved to the top of the
  // tree.
  void Splay(const Key& key);

  class Node : public B {
   public:
    Node(const Key& key, const Value& value)
        : key_(key), value_(value), left_(nullptr), right_(nullptr) {}

    Key key() { return key_; }
    Value value() { return value_; }
    Node* left() { return left_; }
    Node* right() { return right_; }

   private:
    friend class SplayTree;
    friend class Locator;
    Key key_;
    Value value_;
    Node* left_;
    Node* right_;
  };

  // A locator provides access to a node in the tree without actually
  // exposing the node.
  class Locator : public B {
   public:
    explicit Locator(Node* node) : node_(node) {}
    Locator() : node_(nullptr) {}
    const Key& key() { return node_->key_; }
    Value& value() { return node_->value_; }
    void set_value(const Value& value) { node_->value_ = value; }
    inline void bind(Node* node) { node_ = node; }

   private:
    Node* node_;
  };

  template <class Callback>
  void ForEach(Callback* callback);

 protected:
  // Resets tree root. Existing nodes become unreachable.
  void ResetRoot() { root_ = nullptr; }

 private:
  // Search for a node with a given key. If found, root_ points
  // to the node.
  bool FindInternal(const Key& key);

  // Inserts a node assuming that root_ is already set up.
  void InsertInternal(int cmp, Node* node);

  // Removes root_ node.
  void RemoveRootNode(const Key& key);

  template <class Callback>
  class NodeToPairAdaptor : public B {
   public:
    explicit NodeToPairAdaptor(Callback* callback) : callback_(callback) {}
    void Call(Node* node) { callback_->Call(node->key(), node->value()); }

   private:
    Callback* callback_;

    DISALLOW_COPY_AND_ASSIGN(NodeToPairAdaptor);
  };

  class NodeDeleter : public B {
   public:
    NodeDeleter() = default;
    void Call(Node* node) { delete node; }

   private:
    DISALLOW_COPY_AND_ASSIGN(NodeDeleter);
  };

  template <class Callback>
  void ForEachNode(Callback* callback);

  Node* root_;
  Allocator* allocator_;

  DISALLOW_COPY_AND_ASSIGN(SplayTree);
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_SPLAY_TREE_H_
