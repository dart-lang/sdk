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
    enum Type {
      kElement,
      kProperty,
    } reference_type;
    union {
      intptr_t offset;   // kElement
      const char* name;  // kProperty
    };
  };

  enum ConstantStrings {
    kUnknownString = 0,
    kArtificialRootString = 1,
  };

  static const ObjectId kArtificialRootId;

#if !defined(DART_PRECOMPILER)
  explicit V8SnapshotProfileWriter(Zone* zone) {}
  virtual ~V8SnapshotProfileWriter() {}

  void SetObjectType(ObjectId object_id, const char* type) {}
  void SetObjectTypeAndName(ObjectId object_id,
                            const char* type,
                            const char* name) {}
  void AttributeBytesTo(ObjectId object_id, size_t num_bytes) {}
  void AttributeReferenceTo(ObjectId from_object_id,
                            Reference reference,
                            ObjectId to_object_id) {}
  void AttributeWeakReferenceTo(
      ObjectId from_object_id,
      Reference reference,
      ObjectId to_object_id,
      ObjectId replacement_object_id = kArtificialRootId) {}
  void AddRoot(ObjectId object_id, const char* name = nullptr) {}
  bool HasId(const ObjectId& object_id) { return false; }
#else
  explicit V8SnapshotProfileWriter(Zone* zone);
  virtual ~V8SnapshotProfileWriter() {}

  void SetObjectType(ObjectId object_id, const char* type) {
    SetObjectTypeAndName(object_id, type, nullptr);
  }

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
  // in order to serialize the object with id 'from_object_id'. This does not
  // affect the number of bytes charged to 'from_object_id'.
  void AttributeReferenceTo(ObjectId from_object_id,
                            Reference reference,
                            ObjectId to_object_id);

  // Records that a weak serialization reference to a dropped object
  // with id 'to_object_id' was written in order to serialize the object with id
  // 'from_object_id'. 'to_object_id' must be an artificial node and
  // 'replacement_object_id' is recorded as the replacement for the
  // dropped object in the snapshot. This does not affect the number of
  // bytes charged to 'from_object_id'.
  void AttributeDroppedReferenceTo(ObjectId from_object_id,
                                   Reference reference,
                                   ObjectId to_object_id,
                                   ObjectId replacement_object_id);

  // Marks an object as being a root in the graph. Used for analysis of the
  // graph.
  void AddRoot(ObjectId object_id, const char* name = nullptr);

  // Write to a file in the V8 Snapshot Profile (JSON/.heapsnapshot) format.
  void Write(const char* file);

  // Whether the given object ID has been added to the profile (via AddRoot,
  // SetObjectTypeAndName, etc.).
  bool HasId(const ObjectId& object_id);

 private:
  static constexpr intptr_t kNumNodeFields = 5;
  static constexpr intptr_t kNumEdgeFields = 3;

  using Edge = std::pair<intptr_t, intptr_t>;

  struct EdgeToObjectIdMapTrait {
    using Key = Edge;
    using Value = ObjectId;

    struct Pair {
      Pair() : edge{kContext, -1}, target(kArtificialRootId) {}
      Pair(Key key, Value value) : edge(key), target(value) {}
      Edge edge;
      ObjectId target;
    };

    static Key KeyOf(Pair kv) { return kv.edge; }
    static Value ValueOf(Pair kv) { return kv.target; }
    static intptr_t Hashcode(Key key) {
      return FinalizeHash(CombineHashes(key.first, key.second), 30);
    }
    static bool IsKeyEqual(Pair kv, Key key) { return kv.edge == key; }
  };

  using EdgeMap = ZoneDirectChainedHashMap<EdgeToObjectIdMapTrait>;

  struct NodeInfo {
    intptr_t type = 0;
    intptr_t name = 0;
    ObjectId id;
    intptr_t self_size = 0;
    EdgeMap* edges = nullptr;
    // Populated during serialization.
    intptr_t offset = -1;
    // 'trace_node_id' isn't supported.
    // 'edge_count' is computed on-demand.

    // Used for testing sentinel in the hashtable.
    bool operator!=(const NodeInfo& other) { return id != other.id; }
    bool operator==(const NodeInfo& other) { return !(*this != other); }

    void AddEdge(const Edge& edge, const ObjectId& target) {
      edges->Insert({edge, target});
    }
    bool HasEdge(const Edge& edge) { return edges->HasKey(edge); }

    // To allow NodeInfo to be used as the pair in ObjectIdToNodeInfoTraits.
    NodeInfo() : id{kSnapshot, -1} {}

    NodeInfo(Zone* zone,
             intptr_t type,
             intptr_t name,
             const ObjectId& id,
             intptr_t self_size,
             intptr_t offset)
        : type(type),
          name(name),
          id(id),
          self_size(self_size),
          edges(new (zone) EdgeMap(zone)),
          offset(offset) {}
  };

  NodeInfo* EnsureId(ObjectId object_id);
  static intptr_t NodeIdFor(ObjectId id) {
    return (id.second << kIdSpaceBits) | id.first;
  }

  intptr_t EnsureString(const char* str);

  enum ConstantEdgeType {
    kContext = 0,
    kElement = 1,
    kProperty = 2,
    kInternal = 3,
    kHidden = 4,
    kShortcut = 5,
    kWeak = 6,
    kExtra = 7,
  };

  static ConstantEdgeType ReferenceTypeToEdgeType(Reference::Type type);

  enum ConstantNodeType {
    kUnknown = 0,
    kArtificialRoot = 1,
  };

  struct ObjectIdToNodeInfoTraits {
    typedef NodeInfo Pair;
    typedef ObjectId Key;
    typedef Pair Value;

    static Key KeyOf(const Pair& pair) { return pair.id; }

    static Value ValueOf(const Pair& pair) { return pair; }

    static size_t Hashcode(Key key) { return NodeIdFor(key); }

    static bool IsKeyEqual(const Pair& x, Key y) { return x.id == y; }
  };

  Zone* zone_;
  void Write(JSONWriter* writer);
  intptr_t WriteNodeInfo(JSONWriter* writer, const NodeInfo& info);
  void WriteEdgeInfo(JSONWriter* writer,
                     const Edge& info,
                     const ObjectId& target);
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
