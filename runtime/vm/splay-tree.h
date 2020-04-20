// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SPLAY_TREE_H_
#define RUNTIME_VM_SPLAY_TREE_H_

#include "platform/splay-tree.h"
#include "vm/zone.h"

namespace dart {

// A zone splay tree.  The config type parameter encapsulates the
// different configurations of a concrete splay tree (see
// platform/splay-tree.h). The tree itself and all its elements are allocated
// in the Zone.
template <typename Config>
class ZoneSplayTree final : public SplayTree<Config, ZoneAllocated, Zone> {
 public:
  explicit ZoneSplayTree(Zone* zone)
      : SplayTree<Config, ZoneAllocated, Zone>(ASSERT_NOTNULL(zone)) {}
  ~ZoneSplayTree() {
    // Reset the root to avoid unneeded iteration over all tree nodes
    // in the destructor.  For a zone-allocated tree, nodes will be
    // freed by the Zone.
    SplayTree<Config, ZoneAllocated, Zone>::ResetRoot();
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_SPLAY_TREE_H_
