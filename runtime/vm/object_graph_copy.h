// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_GRAPH_COPY_H_
#define RUNTIME_VM_OBJECT_GRAPH_COPY_H_

namespace dart {

class Object;
class ObjectPtr;

// Makes a transitive copy of the object graph referenced by [object]. Will not
// copy objects that can be safely shared - due to being immutable.
//
// The result will be an array of length 2 of the format
//
//   [<copy-of-root>, <array-of-objects-to-rehash / null>]
//
// If the array of objects to rehash is not `null` the receiver should re-hash
// those objects.
ObjectPtr CopyMutableObjectGraph(const Object& root);

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_GRAPH_COPY_H_
