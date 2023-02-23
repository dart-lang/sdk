// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_GRAPH_COPY_H_
#define RUNTIME_VM_OBJECT_GRAPH_COPY_H_

namespace dart {

class Isolate;
class Object;
class ObjectPtr;
class Zone;

// Whether the object can safely be shared across isolates due to it being
// deeply immutable.
bool CanShareObjectAcrossIsolates(ObjectPtr obj);

// Makes a transitive copy of the object graph referenced by [object]. Will not
// copy objects that can be safely shared - due to being immutable.
//
// The result will be an array of length 3 of the format
//
//   [
//     <message>,
//     <collection-lib-objects-to-rehash>,
//     <core-lib-objects-to-rehash>,
//   ]
//
// If the array of objects to rehash is not `null` the receiver should re-hash
// those objects.
ObjectPtr CopyMutableObjectGraph(const Object& root);

typedef enum {
  kInternalToIsolateGroup,
  kExternalBetweenIsolateGroups,
} TraversalRules;

// Returns a string representation of a retaining path from `from` to `to`,
// blank string if `to` is not reachable from `from`.
// Traversal doesn't follow all the object graph links, only those
// that makes sense isolate message passing.
const char* FindRetainingPath(Zone* zone,
                              Isolate* isolate,
                              const Object& from,
                              const Object& to,
                              TraversalRules traversal_rules);

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_GRAPH_COPY_H_
