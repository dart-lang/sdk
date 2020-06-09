// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_V8_SNAPSHOT_WRITER_H_
#define RUNTIME_VM_V8_SNAPSHOT_WRITER_H_

#include <utility>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/hash_map.h"
#include "vm/hash_table.h"
#include "vm/json_writer.h"
#include "vm/object.h"

namespace dart {

struct StringToIntMapTraits {
  typedef char const* Key;
  typedef intptr_t Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(nullptr), value(-1) {}
    Pair(Key k, Value v) : key(k), value(v) {}
  };

  static Value ValueOf(Pair pair) { return pair.value; }

  static Key KeyOf(Pair pair) { return pair.key; }

  static size_t Hashcode(Key key) { return String::Hash(key, strlen(key)); }

  static bool IsKeyEqual(Pair x, Key y) { return strcmp(x.key, y) == 0; }
};

class V8SnapshotProfileWriter : public ZoneAllocated {
 public:
  enum IdSpace {
    kSnapshot = 0,  // Can be VM or Isolate heap, they share ids.
    kVmText = 1,
    kIsolateText = 2,
    kVmData = 3,
    kIsolateData = 4,
    kArtificial = 5,  // Artificial objects (e.g. the global root).
    kIdSpaceBits = 3,
  };

  typedef std::pair<IdSpace, intptr_t> ObjectId;

  struct Reference {
    ObjectId to_object_id;
    enum {
      kElement,
      kProperty,
    } reference_type;
    intptr_t offset_or_name;
  };

  enum ConstantStrings {
    kUnknownString = 0,
    kArtificialRootString = 1,
  };

#if !defined(DART_PRECOMPILER)
  explicit V8SnapshotProfileWriter(Zone* zone) {}
  virtual ~V8SnapshotProfileWriter() {}

  void SetObjectTypeAndName(ObjectId object_id,
                            const char* type,
                            const char* name) {}
  void AttributeBytesTo(ObjectId object_id, size_t num_bytes) {}
  void AttributeReferenceTo(ObjectId object_id, Reference reference) {}
  void AddRoot(ObjectId object_id, const char* name = nullptr) {}
  intptr_t EnsureString(const char* str) { return 0; }
#else
  explicit V8SnapshotProfileWriter(Zone* zone);
  virtual ~V8SnapshotProfileWriter() {}

  // Records that the object referenced by 'object_id' has type 'type'. The
  // 'type' for all 'Instance's should be 'Instance', not the user-visible type
  // and use 'name' for the real type instead.
  void SetObjectTypeAndName(ObjectId object_id,
                            const char* type,
                            const char* name);

  // Charges 'num_bytes'-many bytes to 'object_id'. In a clustered snapshot,
  // objects can have their data spread across multiple sections, so this can be
  // called multiple times for the same object.
  void AttributeBytesTo(ObjectId object_id, size_t num_bytes);

  // Records that a reference to the object with id 'to_object_id' was written
  // in order to serialize the object with id 'object_id'. This does not affect
  // the number of bytes charged to 'object_id'.
  void AttributeReferenceTo(ObjectId object_id, Reference reference);

  // Marks an object as being a root in the graph. Used for analysis of the
  // graph.
  void AddRoot(ObjectId object_id, const char* name = nullptr);

  // Write to a file in the V8 Snapshot Profile (JSON/.heapsnapshot) format.
  void Write(const char* file);

  intptr_t EnsureString(const char* str);

  static ObjectId ArtificialRootId() { return {kArtificial, 0}; }

 private:
  static constexpr intptr_t kNumNodeFields = 5;
  static constexpr intptr_t kNumEdgeFields = 3;

  struct EdgeInfo {
    intptr_t type;
    intptr_t name_or_index;
    ObjectId to_node;
  };

  struct NodeInfo {
    intptr_t type;
    intptr_t name;
    ObjectId id;
    intptr_t self_size;
    ZoneGrowableArray<EdgeInfo>* edges = nullptr;
    // Populated during serialization.
    intptr_t offset = -1;
    // 'trace_node_id' isn't supported.
    // 'edge_count' is computed on-demand.

    // Used for testing sentinel in the hashtable.
    bool operator!=(const NodeInfo& other) { return id != other.id; }
    bool operator==(const NodeInfo& other) { return !(*this != other); }

    NodeInfo(intptr_t type,
             intptr_t name,
             ObjectId id,
             intptr_t self_size,
             ZoneGrowableArray<EdgeInfo>* edges,
             intptr_t offset)
        : type(type),
          name(name),
          id(id),
          self_size(self_size),
          edges(edges),
          offset(offset) {}
  };

  NodeInfo DefaultNode(ObjectId object_id);
  const NodeInfo& ArtificialRoot();

  NodeInfo* EnsureId(ObjectId object_id);
  static intptr_t NodeIdFor(ObjectId id) {
    return (id.second << kIdSpaceBits) | id.first;
  }

  enum ConstantEdgeTypes {
    kContext = 0,
    kElement = 1,
    kProperty = 2,
    kInternal = 3,
    kHidden = 4,
    kShortcut = 5,
    kWeak = 6,
    kExtra = 7,
  };

  enum ConstantNodeTypes {
    kUnknown = 0,
    kArtificialRoot = 1,
  };

  struct ObjectIdToNodeInfoTraits {
    typedef ObjectId Key;
    typedef NodeInfo Value;

    struct Pair {
      Key key;
      Value value;
      Pair()
          : key{kSnapshot, -1}, value{0, 0, {kSnapshot, -1}, 0, nullptr, -1} {};
      Pair(Key k, Value v) : key(k), value(v) {}
    };

    static Key KeyOf(const Pair& pair) { return pair.key; }

    static Value ValueOf(const Pair& pair) { return pair.value; }

    static size_t Hashcode(Key key) { return NodeIdFor(key); }

    static bool IsKeyEqual(const Pair& x, Key y) { return x.key == y; }
  };

  Zone* zone_;
  void Write(JSONWriter* writer);
  void WriteNodeInfo(JSONWriter* writer, const NodeInfo& info);
  void WriteEdgeInfo(JSONWriter* writer, const EdgeInfo& info);
  void WriteStringsTable(JSONWriter* writer,
                         const DirectChainedHashMap<StringToIntMapTraits>& map);

  DirectChainedHashMap<ObjectIdToNodeInfoTraits> nodes_;
  DirectChainedHashMap<StringToIntMapTraits> node_types_;
  DirectChainedHashMap<StringToIntMapTraits> edge_types_;
  DirectChainedHashMap<StringToIntMapTraits> strings_;

  // We don't have a zone-allocated hash set, so we just re-use the type for
  // nodes_ even though we don't need to access the node info (and fill it with
  // dummy values).
  DirectChainedHashMap<ObjectIdToNodeInfoTraits> roots_;

  size_t edge_count_ = 0;
#endif
};

}  // namespace dart

#endif  //  RUNTIME_VM_V8_SNAPSHOT_WRITER_H_
