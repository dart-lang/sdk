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

enum class IdSpace : uint8_t {
  kInvalid = 0,   // So default-constructed ObjectIds are invalid.
  kSnapshot = 1,  // Can be VM or Isolate heap, they share ids.
  kVmText = 2,
  kIsolateText = 3,
  kVmData = 4,
  kIsolateData = 5,
  kArtificial = 6,  // Artificial objects (e.g. the global root).
  // Change ObjectId::kIdSpaceBits to use last entry if more are added.
};

class V8SnapshotProfileWriter : public ZoneAllocated {
 public:
  struct ObjectId {
    ObjectId() : ObjectId(IdSpace::kInvalid, -1) {}
    ObjectId(IdSpace space, int64_t nonce)
        : encoded_((static_cast<uint64_t>(nonce) << kIdSpaceBits) |
                   static_cast<intptr_t>(space)) {
      ASSERT(Utils::IsInt(kBitsPerInt64 - kIdSpaceBits, nonce));
    }

    inline bool operator!=(const ObjectId& other) const {
      return encoded_ != other.encoded_;
    }
    inline bool operator==(const ObjectId& other) const {
      return !(*this != other);
    }

    inline uword Hash() const { return Utils::WordHash(encoded_); }
    inline int64_t nonce() const { return encoded_ >> kIdSpaceBits; }
    inline IdSpace space() const {
      return static_cast<IdSpace>(encoded_ & kIdSpaceMask);
    }
    inline bool IsArtificial() const { return space() == IdSpace::kArtificial; }

    const char* ToCString(Zone* zone) const;
    void Write(JSONWriter* writer, const char* property = nullptr) const;
    void WriteDebug(JSONWriter* writer, const char* property = nullptr) const;

   private:
    static constexpr size_t kIdSpaceBits =
        Utils::BitLength(static_cast<int64_t>(IdSpace::kArtificial));
    static constexpr int64_t kIdSpaceMask =
        Utils::NBitMask<int64_t>(kIdSpaceBits);
    static const char* IdSpaceToCString(IdSpace space);

    int64_t encoded_;
  };

  struct Reference {
    enum class Type {
      kElement,
      kProperty,
    } type;
    intptr_t offset;   // kElement
    const char* name;  // kProperty

    static Reference Element(intptr_t offset) {
      return {Type::kElement, offset, nullptr};
    }
    static Reference Property(const char* name) {
      return {Type::kProperty, 0, name};
    }

    bool IsElement() const { return type == Type::kElement; }
  };

  static const ObjectId kArtificialRootId;

#if !defined(DART_PRECOMPILER)
  explicit V8SnapshotProfileWriter(Zone* zone) {}
  virtual ~V8SnapshotProfileWriter() {}

  void SetObjectTypeAndName(const ObjectId& object_id,
                            const char* type,
                            const char* name) {}
  void AttributeBytesTo(const ObjectId& object_id, size_t num_bytes) {}
  void AttributeReferenceTo(const ObjectId& from_object_id,
                            const Reference& reference,
                            const ObjectId& to_object_id) {}
  void AttributeWeakReferenceTo(const ObjectId& from_object_id,
                                const Reference& reference,
                                const ObjectId& to_object_id,
                                const ObjectId& replacement_object_id) {}
  void AddRoot(const ObjectId& object_id, const char* name = nullptr) {}
  bool HasId(const ObjectId& object_id) { return false; }
#else
  explicit V8SnapshotProfileWriter(Zone* zone);
  virtual ~V8SnapshotProfileWriter() {}

  // Records that the object referenced by 'object_id' has type 'type'. The
  // 'type' for all 'Instance's should be 'Instance', not the user-visible type
  // and use 'name' for the real type instead.
  void SetObjectTypeAndName(const ObjectId& object_id,
                            const char* type,
                            const char* name);

  // Charges 'num_bytes'-many bytes to 'object_id'. In a clustered snapshot,
  // objects can have their data spread across multiple sections, so this can be
  // called multiple times for the same object.
  void AttributeBytesTo(const ObjectId& object_id, size_t num_bytes);

  // Records that a reference to the object with id 'to_object_id' was written
  // in order to serialize the object with id 'from_object_id'. This does not
  // affect the number of bytes charged to 'from_object_id'.
  void AttributeReferenceTo(const ObjectId& from_object_id,
                            const Reference& reference,
                            const ObjectId& to_object_id);

  // Records that a weak serialization reference to a dropped object
  // with id 'to_object_id' was written in order to serialize the object with id
  // 'from_object_id'. 'to_object_id' must be an artificial node and
  // 'replacement_object_id' is recorded as the replacement for the
  // dropped object in the snapshot. This does not affect the number of
  // bytes charged to 'from_object_id'.
  void AttributeDroppedReferenceTo(const ObjectId& from_object_id,
                                   const Reference& reference,
                                   const ObjectId& to_object_id,
                                   const ObjectId& replacement_object_id);

  // Marks an object as being a root in the graph. Used for analysis of
  // the graph.
  void AddRoot(const ObjectId& object_id, const char* name = nullptr);

  // Write to a file in the V8 Snapshot Profile (JSON/.heapsnapshot) format.
  void Write(const char* file);

  // Whether the given object ID has been added to the profile (via AddRoot,
  // SetObjectTypeAndName, etc.).
  bool HasId(const ObjectId& object_id);

 private:
  static constexpr intptr_t kInvalidString =
      CStringIntMapKeyValueTrait::kNoValue;
  static constexpr intptr_t kNumNodeFields = 5;
  static constexpr intptr_t kNumEdgeFields = 3;

  struct Edge {
    enum class Type : int32_t {
      kInvalid = -1,
      kContext = 0,
      kElement = 1,
      kProperty = 2,
      kInternal = 3,
      kHidden = 4,
      kShortcut = 5,
      kWeak = 6,
      kExtra = 7,
    };

    Edge() : Edge(nullptr, Type::kInvalid, -1) {}
    Edge(V8SnapshotProfileWriter* profile_writer, const Reference& reference)
        : Edge(profile_writer,
               reference.type == Reference::Type::kElement ? Type::kElement
                                                           : Type::kProperty,
               reference.type == Reference::Type::kElement
                   ? reference.offset
                   : profile_writer->strings_.Add(reference.name)) {}
    Edge(V8SnapshotProfileWriter* profile_writer,
         Type type,
         intptr_t name_or_offset)
        : type(type), name_or_offset(name_or_offset) {}

    inline bool operator!=(const Edge& other) {
      return type != other.type || name_or_offset != other.name_or_offset;
    }
    inline bool operator==(const Edge& other) { return !(*this != other); }

    void Write(V8SnapshotProfileWriter* profile_writer,
               JSONWriter* writer,
               const ObjectId& target_id) const;
    void WriteDebug(V8SnapshotProfileWriter* profile_writer,
                    JSONWriter* writer,
                    const ObjectId& target_id) const;

    Type type;
    int32_t name_or_offset;
  };

  struct EdgeToObjectIdMapTrait {
    using Key = Edge;
    using Value = ObjectId;

    struct Pair {
      Pair() : edge{}, target(kArtificialRootId) {}
      Pair(Key key, Value value) : edge(key), target(value) {}
      Edge edge;
      ObjectId target;
    };

    static Key KeyOf(Pair kv) { return kv.edge; }
    static Value ValueOf(Pair kv) { return kv.target; }
    static uword Hash(Key key) {
      return FinalizeHash(
          CombineHashes(static_cast<intptr_t>(key.type), key.name_or_offset));
    }
    static bool IsKeyEqual(Pair kv, Key key) { return kv.edge == key; }
  };

  struct EdgeMap : public ZoneDirectChainedHashMap<EdgeToObjectIdMapTrait> {
    explicit EdgeMap(Zone* zone)
        : ZoneDirectChainedHashMap<EdgeToObjectIdMapTrait>(zone, 1) {}

    const char* ToCString(V8SnapshotProfileWriter* profile_writer,
                          Zone* zone) const;
    void WriteDebug(V8SnapshotProfileWriter* profile_writer,
                    JSONWriter* writer,
                    const char* property = nullptr) const;
  };

  struct NodeInfo {
    NodeInfo() {}
    NodeInfo(V8SnapshotProfileWriter* profile_writer,
             const ObjectId& id,
             intptr_t type = kInvalidString,
             intptr_t name = kInvalidString)
        : id(id),
          edges(new (profile_writer->zone_) EdgeMap(profile_writer->zone_)),
          type(type),
          name(name) {}

    inline bool operator!=(const NodeInfo& other) {
      return id != other.id || type != other.type || name != other.name ||
             self_size != other.self_size || edges != other.edges ||
             offset_ != other.offset_;
    }
    inline bool operator==(const NodeInfo& other) { return !(*this != other); }

    void AddEdge(const Edge& edge, const ObjectId& target) {
      edges->Insert({edge, target});
    }
    bool HasEdge(const Edge& edge) { return edges->HasKey(edge); }

    const char* ToCString(V8SnapshotProfileWriter* profile_writer,
                          Zone* zone) const;
    void Write(V8SnapshotProfileWriter* profile_writer,
               JSONWriter* writer) const;
    void WriteDebug(V8SnapshotProfileWriter* profile_writer,
                    JSONWriter* writer) const;

    intptr_t offset() const { return offset_; }
    void set_offset(intptr_t offset) {
      ASSERT_EQUAL(offset_, -1);
      offset_ = offset;
    }

    ObjectId id;
    EdgeMap* edges = nullptr;
    intptr_t type = kInvalidString;
    intptr_t name = kInvalidString;
    intptr_t self_size = 0;

   private:
    // Populated during serialization.
    intptr_t offset_ = -1;
    // 'trace_node_id' isn't supported.
    // 'edge_count' is computed on-demand.
  };

  NodeInfo* EnsureId(const ObjectId& object_id);
  void Write(JSONWriter* writer);

  // Class that encapsulates both an array of strings and a mapping from
  // strings to their index in the array.
  class StringsTable {
   public:
    explicit StringsTable(Zone* zone)
        : zone_(zone), index_map_(zone), strings_(zone, 2) {}

    intptr_t Add(const char* str);
    intptr_t AddFormatted(const char* fmt, ...) PRINTF_ATTRIBUTE(2, 3);
    const char* At(intptr_t index) const;
    void Write(JSONWriter* writer, const char* property = nullptr) const;

   private:
    Zone* zone_;
    CStringIntMap index_map_;
    GrowableArray<const char*> strings_;
  };

  struct ObjectIdToNodeInfoTraits {
    typedef NodeInfo Pair;
    typedef ObjectId Key;
    typedef Pair Value;

    static Key KeyOf(const Pair& pair) { return pair.id; }

    static Value ValueOf(const Pair& pair) { return pair; }

    static uword Hash(const Key& key) { return key.Hash(); }

    static bool IsKeyEqual(const Pair& x, const Key& y) { return x.id == y; }
  };

  struct ObjectIdSetKeyValueTrait {
    using Pair = ObjectId;
    using Key = Pair;
    using Value = Pair;

    static Key KeyOf(const Pair& pair) { return pair; }
    static Value ValueOf(const Pair& pair) { return pair; }
    static uword Hash(const Key& key) { return key.Hash(); }
    static bool IsKeyEqual(const Pair& pair, const Key& key) {
      return pair == key;
    }
  };

  Zone* const zone_;
  DirectChainedHashMap<ObjectIdToNodeInfoTraits> nodes_;
  StringsTable node_types_;
  StringsTable edge_types_;
  StringsTable strings_;
  DirectChainedHashMap<ObjectIdSetKeyValueTrait> roots_;
#endif
};

}  // namespace dart

#endif  //  RUNTIME_VM_V8_SNAPSHOT_WRITER_H_
