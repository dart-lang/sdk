// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/redundancy_elimination.h"

#include <utility>

#include "vm/bit_vector.h"
#include "vm/class_id.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/loops.h"
#include "vm/hash_map.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, dead_store_elimination, true, "Eliminate dead stores");
DEFINE_FLAG(bool, load_cse, true, "Use redundant load elimination.");
DEFINE_FLAG(bool,
            optimize_lazy_initializer_calls,
            true,
            "Eliminate redundant lazy initializer calls.");
DEFINE_FLAG(bool,
            trace_load_optimization,
            false,
            "Print live sets for load optimization pass.");

// Quick access to the current zone.
#define Z (zone())

// A set of Instructions used by CSE pass.
//
// Instructions are compared as if all redefinitions were removed from the
// graph, with the exception of LoadField instruction which gets special
// treatment.
class CSEInstructionSet : public ValueObject {
 public:
  CSEInstructionSet() : map_() {}
  explicit CSEInstructionSet(const CSEInstructionSet& other)
      : ValueObject(), map_(other.map_) {}

  Instruction* Lookup(Instruction* other) const {
    ASSERT(other->AllowsCSE());
    return map_.LookupValue(other);
  }

  void Insert(Instruction* instr) {
    ASSERT(instr->AllowsCSE());
    return map_.Insert(instr);
  }

 private:
  static Definition* OriginalDefinition(Value* value) {
    return value->definition()->OriginalDefinition();
  }

  static bool EqualsIgnoringRedefinitions(const Instruction& a,
                                          const Instruction& b) {
    const auto tag = a.tag();
    if (tag != b.tag()) return false;
    const auto input_count = a.InputCount();
    if (input_count != b.InputCount()) return false;

    // We would like to avoid replacing a load from a redefinition with a
    // load from an original definition because that breaks the dependency
    // on the redefinition and enables potentially incorrect code motion.
    if (tag != Instruction::kLoadField) {
      for (intptr_t i = 0; i < input_count; ++i) {
        if (OriginalDefinition(a.InputAt(i)) !=
            OriginalDefinition(b.InputAt(i))) {
          return false;
        }
      }
    } else {
      for (intptr_t i = 0; i < input_count; ++i) {
        if (!a.InputAt(i)->Equals(*b.InputAt(i))) return false;
      }
    }
    return a.AttributesEqual(b);
  }

  class Trait {
   public:
    typedef Instruction* Value;
    typedef Instruction* Key;
    typedef Instruction* Pair;

    static Key KeyOf(Pair kv) { return kv; }
    static Value ValueOf(Pair kv) { return kv; }

    static inline uword Hash(Key key) {
      uword result = key->tag();
      for (intptr_t i = 0; i < key->InputCount(); ++i) {
        result = CombineHashes(
            result, OriginalDefinition(key->InputAt(i))->ssa_temp_index());
      }
      return FinalizeHash(result, kBitsPerInt32 - 1);
    }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return EqualsIgnoringRedefinitions(*kv, *key);
    }
  };

  DirectChainedHashMap<Trait> map_;
};

// Place describes an abstract location (e.g. field) that IR can load
// from or store to.
//
// Places are also used to describe wild-card locations also known as aliases,
// that essentially represent sets of places that alias each other. Places A
// and B are said to alias each other if store into A can affect load from B.
//
// We distinguish the following aliases:
//
//   - for fields
//     - *.f - field inside some object;
//     - X.f - field inside an allocated object X;
//     -   f - static fields
//
//   - for indexed accesses
//     - *[*] - non-constant index inside some object;
//     - *[C] - constant index inside some object;
//     - X[*] - non-constant index inside an allocated object X;
//     - X[C] - constant index inside an allocated object X.
//
// Constant indexed places are divided into two subcategories:
//
//   - Access to homogeneous array-like objects: Array, ImmutableArray,
//     OneByteString, TwoByteString. These objects can only be accessed
//     on element by element basis with all elements having the same size.
//     This means X[C] aliases X[K] if and only if C === K.
//   - TypedData accesses. TypedData allow to read one of the primitive
//     data types at the given byte offset. When TypedData is accessed through
//     index operator on a typed array or a typed array view it is guaranteed
//     that the byte offset is always aligned by the element size. We write
//     these accesses as X[C|S], where C is constant byte offset and S is size
//     of the data type. Obviously X[C|S] and X[K|U] alias if and only if either
//     C = RoundDown(K, S) or K = RoundDown(C, U).
//     Note that not all accesses to typed data are aligned: e.g. ByteData
//     allows unaligned access through it's get*/set* methods.
//     Check in Place::SetIndex ensures that we never create a place X[C|S]
//     such that C is not aligned by S.
//
// Separating allocations from other objects improves precision of the
// load forwarding pass because of the following two properties:
//
//   - if X can be proven to have no aliases itself (i.e. there is no other SSA
//     variable that points to X) then no place inside X can be aliased with any
//     wildcard dependent place (*.f, *.@offs, *[*], *[C]);
//   - given allocations X and Y no place inside X can be aliased with any place
//     inside Y even if any of them or both escape.
//
// It is important to realize that single place can belong to multiple aliases.
// For example place X.f with aliased allocation X belongs both to X.f and *.f
// aliases. Likewise X[C] with non-aliased allocation X belongs to X[C] and X[*]
// aliases.
//
class Place : public ValueObject {
 public:
  enum Kind {
    kNone,

    // Static field location. Is represented as a Field object with a
    // nullptr instance.
    kStaticField,

    // Instance field location. It is represented by a pair of instance
    // and a Slot.
    kInstanceField,

    // Indexed location with a non-constant index.
    kIndexed,

    // Indexed location with a constant index.
    kConstantIndexed,

    // Update KindBits below if more kinds are added.
  };

  // Size of the element accessed by constant index. Size is only important
  // for TypedData because those accesses can alias even when constant indexes
  // are not the same: X[0|4] aliases X[0|2] and X[2|2].
  enum ElementSize {
    // If indexed access is not a TypedData access then element size is not
    // important because there is only a single possible access size depending
    // on the receiver - X[C] aliases X[K] if and only if C == K.
    // This is the size set for Array, ImmutableArray, OneByteString and
    // TwoByteString accesses.
    kNoSize,

    // 1 byte (Int8List, Uint8List, Uint8ClampedList).
    k1Byte,

    // 2 bytes (Int16List, Uint16List).
    k2Bytes,

    // 4 bytes (Int32List, Uint32List, Float32List).
    k4Bytes,

    // 8 bytes (Int64List, Uint64List, Float64List).
    k8Bytes,

    // 16 bytes (Int32x4List, Float32x4List, Float64x2List).
    k16Bytes,

    kLargestElementSize = k16Bytes,
  };

  Place(const Place& other)
      : ValueObject(),
        flags_(other.flags_),
        instance_(other.instance_),
        raw_selector_(other.raw_selector_),
        id_(other.id_) {}

  // Construct a place from instruction if instruction accesses any place.
  // Otherwise constructs kNone place.
  Place(FlowGraph* graph, Instruction* instr, bool* is_load, bool* is_store)
      : flags_(0), instance_(nullptr), raw_selector_(0), id_(0) {
    switch (instr->tag()) {
      case Instruction::kLoadField: {
        LoadFieldInstr* load_field = instr->AsLoadField();
        set_representation(load_field->representation());
        instance_ = load_field->instance()->definition()->OriginalDefinition();
        set_kind(kInstanceField);
        instance_field_ = &load_field->slot();
        *is_load = true;
        break;
      }

      case Instruction::kStoreField: {
        StoreFieldInstr* store = instr->AsStoreField();
        set_representation(
            store->RequiredInputRepresentation(StoreFieldInstr::kValuePos));
        instance_ = store->instance()->definition()->OriginalDefinition();
        set_kind(kInstanceField);
        instance_field_ = &store->slot();
        *is_store = true;
        break;
      }

      case Instruction::kLoadStaticField:
        set_kind(kStaticField);
        set_representation(instr->AsLoadStaticField()->representation());
        static_field_ = &instr->AsLoadStaticField()->field();
        *is_load = true;
        break;

      case Instruction::kStoreStaticField:
        set_kind(kStaticField);
        set_representation(
            instr->AsStoreStaticField()->RequiredInputRepresentation(
                StoreStaticFieldInstr::kValuePos));
        static_field_ = &instr->AsStoreStaticField()->field();
        *is_store = true;
        break;

      case Instruction::kLoadIndexed: {
        LoadIndexedInstr* load_indexed = instr->AsLoadIndexed();
        // Since the same returned representation is used for arrays with small
        // elements, use the array element representation instead.
        //
        // For example, loads from signed and unsigned byte views of the same
        // array share the same place if the returned representation is used,
        // which means a load which sign extends the byte to the native word
        // size might be replaced with an load that zero extends the byte
        // instead and vice versa.
        set_representation(RepresentationUtils::RepresentationOfArrayElement(
            load_indexed->class_id()));
        instance_ = load_indexed->array()->definition()->OriginalDefinition();
        SetIndex(load_indexed->index()->definition()->OriginalDefinition(),
                 load_indexed->index_scale(), load_indexed->class_id());
        *is_load = true;
        break;
      }

      case Instruction::kStoreIndexed: {
        StoreIndexedInstr* store_indexed = instr->AsStoreIndexed();
        // Use the array element representation instead of the value
        // representation for the same reasons as for LoadIndexed above.
        set_representation(RepresentationUtils::RepresentationOfArrayElement(
            store_indexed->class_id()));
        instance_ = store_indexed->array()->definition()->OriginalDefinition();
        SetIndex(store_indexed->index()->definition()->OriginalDefinition(),
                 store_indexed->index_scale(), store_indexed->class_id());
        *is_store = true;
        break;
      }

      case Instruction::kThrow: {
        // [stackTrace] property of thrown [Error] object is populated by this
        // instruction, so pretend that `throw e` is a
        // `StoreField(e, Error.stackTrace, ...)`
        // TODO(aam): Investigate whether it is better to treat throw/rethrow
        // similar to dart call with `HasUnknownSideEffects`.
        ThrowInstr* throw_instr = instr->AsThrow();
        set_representation(kTagged);
        instance_ =
            throw_instr->exception()->definition()->OriginalDefinition();
        set_kind(kInstanceField);
        instance_field_ = &Slot::Get(
            Field::ZoneHandle(graph->zone(), CompilerState::Current()
                                                 .ErrorStackTraceField()
                                                 .CloneFromOriginal()),
            &graph->parsed_function());
        *is_store = true;
        break;
      }

      default:
        break;
    }
  }

  // Construct a place from an allocation where the place represents a store to
  // a slot that corresponds to the given input position.
  // Otherwise, constructs a kNone place.
  Place(AllocationInstr* alloc, intptr_t input_pos)
      : flags_(0), instance_(nullptr), raw_selector_(0), id_(0) {
    if (const Slot* slot = alloc->SlotForInput(input_pos)) {
      set_representation(alloc->RequiredInputRepresentation(input_pos));
      instance_ = alloc;
      set_kind(kInstanceField);
      instance_field_ = slot;
    }
  }

  // Create object representing *[*] alias.
  static Place* CreateAnyInstanceAnyIndexAlias(Zone* zone, intptr_t id) {
    return Wrap(
        zone,
        Place(EncodeFlags(kIndexed, kNoRepresentation, kNoSize), nullptr, 0),
        id);
  }

  // Return least generic alias for this place. Given that aliases are
  // essentially sets of places we define least generic alias as a smallest
  // alias that contains this place.
  //
  // We obtain such alias by a simple transformation:
  //
  //    - for places that depend on an instance X.f, X.@offs, X[i], X[C]
  //      we drop X if X is not an allocation because in this case X does not
  //      possess an identity obtaining aliases *.f, *.@offs, *[i] and *[C]
  //      respectively; also drop instance of X[i] for typed data view
  //      allocations as they may alias other indexed accesses.
  //    - for non-constant indexed places X[i] we drop information about the
  //      index obtaining alias X[*].
  //    - we drop information about representation, but keep element size
  //      if any.
  //
  Place ToAlias() const {
    Definition* alias_instance = nullptr;
    if (DependsOnInstance() && IsAllocation(instance()) &&
        ((kind() != kIndexed) || !IsTypedDataViewAllocation(instance()))) {
      alias_instance = instance();
    }
    return Place(RepresentationBits::update(kNoRepresentation, flags_),
                 alias_instance, (kind() == kIndexed) ? 0 : raw_selector_);
  }

  bool DependsOnInstance() const {
    switch (kind()) {
      case kInstanceField:
      case kIndexed:
      case kConstantIndexed:
        return true;

      case kStaticField:
      case kNone:
        return false;
    }

    UNREACHABLE();
    return false;
  }

  // Given instance dependent alias X.f, X.@offs, X[C], X[*] return
  // wild-card dependent alias *.f, *.@offs, *[C] or *[*] respectively.
  Place CopyWithoutInstance() const {
    ASSERT(DependsOnInstance());
    return Place(flags_, nullptr, raw_selector_);
  }

  // Given alias X[C] or *[C] return X[*] and *[*] respectively.
  Place CopyWithoutIndex() const {
    ASSERT(kind() == kConstantIndexed);
    return Place(EncodeFlags(kIndexed, kNoRepresentation, kNoSize), instance_,
                 0);
  }

  // Given alias X[ByteOffs|S] and a larger element size S', return
  // alias X[RoundDown(ByteOffs, S')|S'] - this is the byte offset of a larger
  // typed array element that contains this typed array element.
  // In other words this method computes the only possible place with the given
  // size that can alias this place (due to alignment restrictions).
  // For example for X[9|k1Byte] and target size k4Bytes we would return
  // X[8|k4Bytes].
  Place ToLargerElement(ElementSize to) const {
    ASSERT(kind() == kConstantIndexed);
    ASSERT(element_size() != kNoSize);
    ASSERT(element_size() < to);
    return Place(ElementSizeBits::update(to, flags_), instance_,
                 RoundByteOffset(to, index_constant_));
  }

  // Given alias X[ByteOffs|S], smaller element size S' and index from 0 to
  // S/S' - 1 return alias X[ByteOffs + S'*index|S'] - this is the byte offset
  // of a smaller typed array element which is contained within this typed
  // array element.
  // For example X[8|k4Bytes] contains inside X[8|k2Bytes] (index is 0) and
  // X[10|k2Bytes] (index is 1).
  Place ToSmallerElement(ElementSize to, intptr_t index) const {
    ASSERT(kind() == kConstantIndexed);
    ASSERT(element_size() != kNoSize);
    ASSERT(element_size() > to);
    ASSERT(index >= 0);
    ASSERT(index <
           ElementSizeMultiplier(element_size()) / ElementSizeMultiplier(to));
    return Place(ElementSizeBits::update(to, flags_), instance_,
                 ByteOffsetToSmallerElement(to, index, index_constant_));
  }

  intptr_t id() const { return id_; }

  Kind kind() const { return KindBits::decode(flags_); }

  Representation representation() const {
    return RepresentationBits::decode(flags_);
  }

  Definition* instance() const {
    ASSERT(DependsOnInstance());
    return instance_;
  }

  void set_instance(Definition* def) {
    ASSERT(DependsOnInstance());
    instance_ = def->OriginalDefinition();
  }

  const Field& static_field() const {
    ASSERT(kind() == kStaticField);
    ASSERT(static_field_->is_static());
    return *static_field_;
  }

  const Slot& instance_field() const {
    ASSERT(kind() == kInstanceField);
    return *instance_field_;
  }

  Definition* index() const {
    ASSERT(kind() == kIndexed);
    return index_;
  }

  ElementSize element_size() const { return ElementSizeBits::decode(flags_); }

  intptr_t index_constant() const {
    ASSERT(kind() == kConstantIndexed);
    return index_constant_;
  }

  static const char* DefinitionName(Definition* def) {
    if (def == nullptr) {
      return "*";
    } else {
      return Thread::Current()->zone()->PrintToString("v%" Pd,
                                                      def->ssa_temp_index());
    }
  }

  const char* ToCString() const {
    switch (kind()) {
      case kNone:
        return "<none>";

      case kStaticField: {
        const char* field_name =
            String::Handle(static_field().name()).ToCString();
        return Thread::Current()->zone()->PrintToString("<%s>", field_name);
      }

      case kInstanceField:
        return Thread::Current()->zone()->PrintToString(
            "<%s.%s[%p]>", DefinitionName(instance()), instance_field().Name(),
            &instance_field());

      case kIndexed:
        return Thread::Current()->zone()->PrintToString(
            "<%s[%s]>", DefinitionName(instance()), DefinitionName(index()));

      case kConstantIndexed:
        if (element_size() == kNoSize) {
          return Thread::Current()->zone()->PrintToString(
              "<%s[%" Pd "]>", DefinitionName(instance()), index_constant());
        } else {
          return Thread::Current()->zone()->PrintToString(
              "<%s[%" Pd "|%" Pd "]>", DefinitionName(instance()),
              index_constant(), ElementSizeMultiplier(element_size()));
        }
    }
    UNREACHABLE();
    return "<?>";
  }

  // Fields that are considered immutable by load optimization.
  // Handle static finals as non-final with precompilation because
  // they may be reset to uninitialized after compilation.
  bool IsImmutableField() const {
    switch (kind()) {
      case kInstanceField:
        return instance_field().is_immutable();
      default:
        return false;
    }
  }

  uword Hash() const {
    return FinalizeHash(
        CombineHashes(flags_, reinterpret_cast<uword>(instance_)),
        kBitsPerInt32 - 1);
  }

  bool Equals(const Place& other) const {
    return (flags_ == other.flags_) && (instance_ == other.instance_) &&
           SameField(other);
  }

  // Create a zone allocated copy of this place and assign given id to it.
  static Place* Wrap(Zone* zone, const Place& place, intptr_t id);

  static bool IsAllocation(Definition* defn) {
    return (defn != nullptr) && (defn->IsAllocation() ||
                                 (defn->IsStaticCall() &&
                                  defn->AsStaticCall()->IsRecognizedFactory()));
  }

  static bool IsTypedDataViewAllocation(Definition* defn) {
    if (defn != nullptr) {
      if (auto* alloc = defn->AsAllocateObject()) {
        auto const cid = alloc->cls().id();
        return IsTypedDataViewClassId(cid) ||
               IsUnmodifiableTypedDataViewClassId(cid);
      }
    }
    return false;
  }

 private:
  Place(uword flags, Definition* instance, intptr_t selector)
      : flags_(flags), instance_(instance), raw_selector_(selector), id_(0) {}

  bool SameField(const Place& other) const {
    return (kind() == kStaticField)
               ? (static_field().Original() == other.static_field().Original())
               : (raw_selector_ == other.raw_selector_);
  }

  void set_representation(Representation rep) {
    flags_ = RepresentationBits::update(rep, flags_);
  }

  void set_kind(Kind kind) { flags_ = KindBits::update(kind, flags_); }

  void set_element_size(ElementSize scale) {
    flags_ = ElementSizeBits::update(scale, flags_);
  }

  void SetIndex(Definition* index, intptr_t scale, classid_t class_id) {
    ConstantInstr* index_constant = index->AsConstant();
    if ((index_constant != nullptr) && index_constant->value().IsSmi()) {
      const intptr_t index_value = Smi::Cast(index_constant->value()).Value();

      // Places only need to scale the index for typed data objects, as other
      // types of arrays (for which ElementSizeFor returns kNoSize) cannot be
      // accessed at different scales.
      const ElementSize size = ElementSizeFor(class_id);
      if (size == kNoSize) {
        set_kind(kConstantIndexed);
        set_element_size(size);
        index_constant_ = index_value;
        return;
      }

      // Guard against potential multiplication overflow and negative indices.
      if ((0 <= index_value) && (index_value < (kMaxInt32 / scale))) {
        const intptr_t scaled_index = index_value * scale;

        // If the indexed array is a subclass of PointerBase, then it must be
        // treated as a view unless the class id of the array is known at
        // compile time to be an internal typed data object.
        //
        // Indexes into untagged pointers only happen for external typed data
        // objects or dart:ffi's Pointer, but those should also be treated like
        // views, since anyone who has access to the underlying pointer can
        // modify the corresponding memory.
        auto const cid = instance_->Type()->ToCid();
        const bool can_be_view = instance_->representation() == kUntagged ||
                                 !IsTypedDataClassId(cid);

        // Guard against unaligned byte offsets and access through raw
        // memory pointer (which can be pointing into another typed data).
        if (!can_be_view &&
            Utils::IsAligned(scaled_index, ElementSizeMultiplier(size))) {
          set_kind(kConstantIndexed);
          set_element_size(size);
          index_constant_ = scaled_index;
          return;
        }
      }

      // Fallthrough: create generic _[*] place.
    }

    set_kind(kIndexed);
    index_ = index;
  }

  static uword EncodeFlags(Kind kind, Representation rep, ElementSize scale) {
    ASSERT((kind == kConstantIndexed) || (scale == kNoSize));
    return KindBits::encode(kind) | RepresentationBits::encode(rep) |
           ElementSizeBits::encode(scale);
  }

  static ElementSize ElementSizeFor(classid_t class_id) {
    // Object arrays and strings do not allow accessing them through
    // different types. No need to attach scale.
    if (!IsTypedDataBaseClassId(class_id)) return kNoSize;

    const auto rep =
        RepresentationUtils::RepresentationOfArrayElement(class_id);
    if (!RepresentationUtils::IsUnboxed(rep)) return kNoSize;
    switch (RepresentationUtils::ValueSize(rep)) {
      case 1:
        return k1Byte;
      case 2:
        return k2Bytes;
      case 4:
        return k4Bytes;
      case 8:
        return k8Bytes;
      case 16:
        return k16Bytes;
      default:
        FATAL("Unhandled value size for representation %s",
              RepresentationUtils::ToCString(rep));
        return kNoSize;
    }
  }

  static constexpr intptr_t ElementSizeMultiplier(ElementSize size) {
    return 1 << (static_cast<intptr_t>(size) - static_cast<intptr_t>(k1Byte));
  }

  static intptr_t RoundByteOffset(ElementSize size, intptr_t offset) {
    return offset & ~(ElementSizeMultiplier(size) - 1);
  }

  static intptr_t ByteOffsetToSmallerElement(ElementSize size,
                                             intptr_t index,
                                             intptr_t base_offset) {
    return base_offset + index * ElementSizeMultiplier(size);
  }

  using KindBits = BitField<uword, Kind, 0, Utils::BitLength(kConstantIndexed)>;
  using RepresentationBits =
      BitField<uword,
               Representation,
               KindBits::kNextBit,
               Utils::BitLength(kNumRepresentations - 1)>;
  using ElementSizeBits = BitField<uword,
                                   ElementSize,
                                   RepresentationBits::kNextBit,
                                   Utils::BitLength(kLargestElementSize)>;

  uword flags_;
  Definition* instance_;
  union {
    intptr_t raw_selector_;
    const Field* static_field_;
    const Slot* instance_field_;
    intptr_t index_constant_;
    Definition* index_;
  };

  intptr_t id_;
};

class ZonePlace : public ZoneAllocated {
 public:
  explicit ZonePlace(const Place& place) : place_(place) {}

  Place* place() { return &place_; }

 private:
  Place place_;
};

Place* Place::Wrap(Zone* zone, const Place& place, intptr_t id) {
  Place* wrapped = (new (zone) ZonePlace(place))->place();
  wrapped->id_ = id;
  return wrapped;
}

// Correspondence between places connected through outgoing phi moves on the
// edge that targets join.
class PhiPlaceMoves : public ZoneAllocated {
 public:
  // Record a move from the place with id |from| to the place with id |to| at
  // the given block.
  void CreateOutgoingMove(Zone* zone,
                          BlockEntryInstr* block,
                          intptr_t from,
                          intptr_t to) {
    const intptr_t block_num = block->preorder_number();
    moves_.EnsureLength(block_num + 1, nullptr);

    if (moves_[block_num] == nullptr) {
      moves_[block_num] = new (zone) ZoneGrowableArray<Move>(5);
    }

    moves_[block_num]->Add(Move(from, to));
  }

  class Move {
   public:
    Move(intptr_t from, intptr_t to) : from_(from), to_(to) {}

    intptr_t from() const { return from_; }
    intptr_t to() const { return to_; }

   private:
    intptr_t from_;
    intptr_t to_;
  };

  typedef const ZoneGrowableArray<Move>* MovesList;

  MovesList GetOutgoingMoves(BlockEntryInstr* block) const {
    const intptr_t block_num = block->preorder_number();
    return (block_num < moves_.length()) ? moves_[block_num] : nullptr;
  }

 private:
  GrowableArray<ZoneGrowableArray<Move>*> moves_;
};

// A map from aliases to a set of places sharing the alias. Additionally
// carries a set of places that can be aliased by side-effects, essentially
// those that are affected by calls.
class AliasedSet : public ZoneAllocated {
 public:
  AliasedSet(Zone* zone,
             FlowGraph* graph,
             PointerSet<Place>* places_map,
             ZoneGrowableArray<Place*>* places,
             PhiPlaceMoves* phi_moves,
             bool print_traces)
      : zone_(zone),
        graph_(graph),
        print_traces_(print_traces),
        places_map_(places_map),
        places_(*places),
        phi_moves_(phi_moves),
        aliases_(5),
        aliases_map_(),
        typed_data_access_sizes_(),
        representatives_(),
        killed_(),
        aliased_by_effects_(new (zone) BitVector(zone, places->length())) {
    InsertAlias(Place::CreateAnyInstanceAnyIndexAlias(
        zone_, kAnyInstanceAnyIndexAlias));
    for (intptr_t i = 0; i < places_.length(); i++) {
      AddRepresentative(places_[i]);
    }
    ComputeKillSets();
  }

  intptr_t LookupAliasId(const Place& alias) {
    const Place* result = aliases_map_.LookupValue(&alias);
    return (result != nullptr) ? result->id() : static_cast<intptr_t>(kNoAlias);
  }

  BitVector* GetKilledSet(intptr_t alias) {
    return (alias < killed_.length()) ? killed_[alias] : nullptr;
  }

  intptr_t max_place_id() const { return places().length(); }
  bool IsEmpty() const { return max_place_id() == 0; }

  BitVector* aliased_by_effects() const { return aliased_by_effects_; }

  const ZoneGrowableArray<Place*>& places() const { return places_; }

  Place* LookupCanonical(Place* place) const {
    return places_map_->LookupValue(place);
  }

  void PrintSet(BitVector* set) {
    bool comma = false;
    for (BitVector::Iterator it(set); !it.Done(); it.Advance()) {
      if (comma) {
        THR_Print(", ");
      }
      THR_Print("%s", places_[it.Current()]->ToCString());
      comma = true;
    }
  }

  const PhiPlaceMoves* phi_moves() const { return phi_moves_; }

  void RollbackAliasedIdentities() {
    for (intptr_t i = 0; i < identity_rollback_.length(); ++i) {
      identity_rollback_[i]->SetIdentity(AliasIdentity::Unknown());
    }
  }

  // Returns false if the result of an allocation instruction can't be aliased
  // by another SSA variable and true otherwise.
  bool CanBeAliased(Definition* alloc) {
    if (!Place::IsAllocation(alloc)) {
      return true;
    }

    if (alloc->Identity().IsUnknown()) {
      ComputeAliasing(alloc);
    }

    return !alloc->Identity().IsNotAliased();
  }

  enum { kNoAlias = 0 };

 private:
  enum {
    // Artificial alias that is used to collect all representatives of the
    // *[C], X[C] aliases for arbitrary C.
    kAnyConstantIndexedAlias = 1,

    // Artificial alias that is used to collect all representatives of
    // *[C] alias for arbitrary C.
    kUnknownInstanceConstantIndexedAlias = 2,

    // Artificial alias that is used to collect all representatives of
    // X[*] alias for all X.
    kAnyAllocationIndexedAlias = 3,

    // *[*] alias.
    kAnyInstanceAnyIndexAlias = 4
  };

  // Compute least generic alias for the place and assign alias id to it.
  void AddRepresentative(Place* place) {
    if (!place->IsImmutableField()) {
      const Place* alias = CanonicalizeAlias(place->ToAlias());
      EnsureSet(&representatives_, alias->id())->Add(place->id());

      // Update cumulative representative sets that are used during
      // killed sets computation.
      if (alias->kind() == Place::kConstantIndexed) {
        if (CanBeAliased(alias->instance())) {
          EnsureSet(&representatives_, kAnyConstantIndexedAlias)
              ->Add(place->id());
        }

        if (alias->instance() == nullptr) {
          EnsureSet(&representatives_, kUnknownInstanceConstantIndexedAlias)
              ->Add(place->id());
        }

        // Collect all element sizes used to access TypedData arrays in
        // the function. This is used to skip sizes without representatives
        // when computing kill sets.
        if (alias->element_size() != Place::kNoSize) {
          typed_data_access_sizes_.Add(alias->element_size());
        }
      } else if ((alias->kind() == Place::kIndexed) &&
                 CanBeAliased(place->instance())) {
        EnsureSet(&representatives_, kAnyAllocationIndexedAlias)
            ->Add(place->id());
      }

      if (!IsIndependentFromEffects(place)) {
        aliased_by_effects_->Add(place->id());
      }
    }
  }

  void ComputeKillSets() {
    for (intptr_t i = 0; i < aliases_.length(); ++i) {
      const Place* alias = aliases_[i];
      // Add all representatives to the kill set.
      AddAllRepresentatives(alias->id(), alias->id());
      ComputeKillSet(alias);
    }

    if (FLAG_trace_load_optimization && print_traces_) {
      THR_Print("Aliases KILL sets:\n");
      for (intptr_t i = 0; i < aliases_.length(); ++i) {
        const Place* alias = aliases_[i];
        BitVector* kill = GetKilledSet(alias->id());

        THR_Print("%s: ", alias->ToCString());
        if (kill != nullptr) {
          PrintSet(kill);
        }
        THR_Print("\n");
      }
    }
  }

  void InsertAlias(const Place* alias) {
    aliases_map_.Insert(alias);
    aliases_.Add(alias);
  }

  const Place* CanonicalizeAlias(const Place& alias) {
    const Place* canonical = aliases_map_.LookupValue(&alias);
    if (canonical == nullptr) {
      canonical = Place::Wrap(zone_, alias,
                              kAnyInstanceAnyIndexAlias + aliases_.length());
      InsertAlias(canonical);
    }
    ASSERT(aliases_map_.LookupValue(&alias) == canonical);
    return canonical;
  }

  BitVector* GetRepresentativesSet(intptr_t alias) {
    return (alias < representatives_.length()) ? representatives_[alias]
                                               : nullptr;
  }

  BitVector* EnsureSet(GrowableArray<BitVector*>* sets, intptr_t alias) {
    while (sets->length() <= alias) {
      sets->Add(nullptr);
    }

    BitVector* set = (*sets)[alias];
    if (set == nullptr) {
      (*sets)[alias] = set = new (zone_) BitVector(zone_, max_place_id());
    }
    return set;
  }

  void AddAllRepresentatives(const Place* to, intptr_t from) {
    AddAllRepresentatives(to->id(), from);
  }

  void AddAllRepresentatives(intptr_t to, intptr_t from) {
    BitVector* from_set = GetRepresentativesSet(from);
    if (from_set != nullptr) {
      EnsureSet(&killed_, to)->AddAll(from_set);
    }
  }

  void CrossAlias(const Place* to, const Place& from) {
    const intptr_t from_id = LookupAliasId(from);
    if (from_id == kNoAlias) {
      return;
    }
    CrossAlias(to, from_id);
  }

  void CrossAlias(const Place* to, intptr_t from) {
    AddAllRepresentatives(to->id(), from);
    AddAllRepresentatives(from, to->id());
  }

  // When computing kill sets we let less generic alias insert its
  // representatives into more generic aliases kill set. For example
  // when visiting alias X[*] instead of searching for all aliases X[C]
  // and inserting their representatives into kill set for X[*] we update
  // kill set for X[*] each time we visit new X[C] for some C.
  // There is an exception however: if both aliases are parametric like *[C]
  // and X[*] which cross alias when X is an aliased allocation then we use
  // artificial aliases that contain all possible representatives for the given
  // alias for any value of the parameter to compute resulting kill set.
  void ComputeKillSet(const Place* alias) {
    switch (alias->kind()) {
      case Place::kIndexed:  // Either *[*] or X[*] alias.
        if (alias->instance() == nullptr) {
          // *[*] aliases with X[*], X[C], *[C].
          AddAllRepresentatives(alias, kAnyConstantIndexedAlias);
          AddAllRepresentatives(alias, kAnyAllocationIndexedAlias);
        } else if (CanBeAliased(alias->instance())) {
          // X[*] aliases with X[C].
          // If X can be aliased then X[*] also aliases with *[C], *[*].
          CrossAlias(alias, kAnyInstanceAnyIndexAlias);
          AddAllRepresentatives(alias, kUnknownInstanceConstantIndexedAlias);
        }
        break;

      case Place::kConstantIndexed:  // Either X[C] or *[C] alias.
        if (alias->element_size() != Place::kNoSize) {
          const bool has_aliased_instance =
              (alias->instance() != nullptr) && CanBeAliased(alias->instance());

          // If this is a TypedData access then X[C|S] aliases larger elements
          // covering this one X[RoundDown(C, S')|S'] for all S' > S and
          // all smaller elements being covered by this one X[C'|S'] for
          // some S' < S and all C' such that C = RoundDown(C', S).
          // In the loop below it's enough to only propagate aliasing to
          // larger aliases because propagation is symmetric: smaller aliases
          // (if there are any) would update kill set for this alias when they
          // are visited.
          for (intptr_t i = static_cast<intptr_t>(alias->element_size()) + 1;
               i <= Place::kLargestElementSize; i++) {
            // Skip element sizes that a guaranteed to have no representatives.
            if (!typed_data_access_sizes_.Contains(alias->element_size())) {
              continue;
            }

            // X[C|S] aliases with X[RoundDown(C, S')|S'] and likewise
            // *[C|S] aliases with *[RoundDown(C, S')|S'].
            CrossAlias(alias, alias->ToLargerElement(
                                  static_cast<Place::ElementSize>(i)));
          }

          if (has_aliased_instance) {
            // If X is an aliased instance then X[C|S] aliases *[C'|S'] for all
            // related combinations of C' and S'.
            // Caveat: this propagation is not symmetric (we would not know
            // to propagate aliasing from *[C'|S'] to X[C|S] when visiting
            // *[C'|S']) and thus we need to handle both element sizes smaller
            // and larger than S.
            const Place no_instance_alias = alias->CopyWithoutInstance();
            for (intptr_t i = Place::k1Byte; i <= Place::kLargestElementSize;
                 i++) {
              // Skip element sizes that a guaranteed to have no
              // representatives.
              if (!typed_data_access_sizes_.Contains(alias->element_size())) {
                continue;
              }

              const auto other_size = static_cast<Place::ElementSize>(i);
              if (other_size > alias->element_size()) {
                // X[C|S] aliases all larger elements which cover it:
                // *[RoundDown(C, S')|S'] for S' > S.
                CrossAlias(alias,
                           no_instance_alias.ToLargerElement(other_size));
              } else if (other_size < alias->element_size()) {
                // X[C|S] aliases all sub-elements of smaller size:
                // *[C+j*S'|S'] for S' < S and j from 0 to S/S' - 1.
                const auto num_smaller_elements =
                    1 << (alias->element_size() - other_size);
                for (intptr_t j = 0; j < num_smaller_elements; j++) {
                  CrossAlias(alias,
                             no_instance_alias.ToSmallerElement(other_size, j));
                }
              }
            }
          }
        }

        if (alias->instance() == nullptr) {
          // *[C] aliases with X[C], X[*], *[*].
          AddAllRepresentatives(alias, kAnyAllocationIndexedAlias);
          CrossAlias(alias, kAnyInstanceAnyIndexAlias);
        } else {
          // X[C] aliases with X[*].
          // If X can be aliased then X[C] also aliases with *[C], *[*].
          CrossAlias(alias, alias->CopyWithoutIndex());
          if (CanBeAliased(alias->instance())) {
            CrossAlias(alias, alias->CopyWithoutInstance());
            CrossAlias(alias, kAnyInstanceAnyIndexAlias);
          }
        }
        break;

      case Place::kStaticField:
        // Nothing to do.
        break;

      case Place::kInstanceField:
        if (CanBeAliased(alias->instance())) {
          // X.f alias with *.f.
          CrossAlias(alias, alias->CopyWithoutInstance());
        }
        break;

      case Place::kNone:
        UNREACHABLE();
    }
  }

  // Returns true if the given load is unaffected by external side-effects.
  // This essentially means that no stores to the same location can
  // occur in other functions.
  bool IsIndependentFromEffects(Place* place) {
    if (place->IsImmutableField()) {
      return true;
    }

    return ((place->kind() == Place::kInstanceField) ||
            (place->kind() == Place::kConstantIndexed)) &&
           (place->instance() != nullptr) && !CanBeAliased(place->instance());
  }

  // Returns true if there are direct loads from the given place.
  bool HasLoadsFromPlace(Definition* defn, const Place* place) {
    ASSERT(place->kind() == Place::kInstanceField);

    for (Value* use = defn->input_use_list(); use != nullptr;
         use = use->next_use()) {
      Instruction* instr = use->instruction();
      if (UseIsARedefinition(use) &&
          HasLoadsFromPlace(instr->Cast<Definition>(), place)) {
        return true;
      }
      bool is_load = false, is_store;
      Place load_place(graph_, instr, &is_load, &is_store);

      if (is_load && load_place.Equals(*place)) {
        return true;
      }
    }

    return false;
  }

  // Returns true if the given [use] is a redefinition (e.g. RedefinitionInstr,
  // CheckNull, CheckArrayBound, etc).
  static bool UseIsARedefinition(Value* use) {
    Instruction* instr = use->instruction();
    return instr->IsDefinition() &&
           (instr->Cast<Definition>()->RedefinedValue() == use);
  }

  // Check if any use of the definition can create an alias.
  // Can add more objects into aliasing_worklist_.
  bool AnyUseCreatesAlias(Definition* defn) {
    for (Value* env_use = defn->env_use_list(); env_use != nullptr;
         env_use = env_use->next_use()) {
      Instruction* instr = env_use->instruction();
      if (instr->MayThrow() && instr->GetBlock()->InsideTryBlock()) {
        // TODO(aam): This can be improved given that the alias is only
        // created if matching catch block has a corresponding parameter.
        return true;
      }
    }
    for (Value* use = defn->input_use_list(); use != nullptr;
         use = use->next_use()) {
      Instruction* instr = use->instruction();
      if (instr->HasUnknownSideEffects() ||
          (instr->IsLoadField() &&
           instr->AsLoadField()->MayCreateUntaggedAlias()) ||
          (instr->IsStoreIndexed() &&
           (use->use_index() == StoreIndexedInstr::kValuePos)) ||
          instr->IsStoreStaticField() || instr->IsPhi()) {
        return true;
      } else if (UseIsARedefinition(use) &&
                 AnyUseCreatesAlias(instr->Cast<Definition>())) {
        return true;
      } else if (instr->IsStoreField()) {
        StoreFieldInstr* store = instr->AsStoreField();

        if (store->slot().kind() == Slot::Kind::kTypedDataView_typed_data) {
          // Initialization of TypedDataView.typed_data field creates
          // aliasing between the view and original typed data,
          // as the same data can now be accessed via both typed data
          // view and the original typed data.
          return true;
        }

        if (use->use_index() != StoreFieldInstr::kInstancePos) {
          ASSERT(use->use_index() == StoreFieldInstr::kValuePos);
          // If we store this value into an object that is not aliased itself
          // and we never load again then the store does not create an alias.
          Definition* instance =
              store->instance()->definition()->OriginalDefinition();
          if (Place::IsAllocation(instance) &&
              !instance->Identity().IsAliased()) {
            bool is_load, is_store;
            Place store_place(graph_, instr, &is_load, &is_store);

            if (!HasLoadsFromPlace(instance, &store_place)) {
              // No loads found that match this store. If it is yet unknown if
              // the object is not aliased then optimistically assume this but
              // add it to the worklist to check its uses transitively.
              if (instance->Identity().IsUnknown()) {
                instance->SetIdentity(AliasIdentity::NotAliased());
                aliasing_worklist_.Add(instance);
              }
              continue;
            }
          }
          return true;
        }
      } else if (auto* const alloc = instr->AsAllocation()) {
        // Treat inputs to an allocation instruction exactly as if they were
        // manually stored using a StoreField instruction.
        if (alloc->Identity().IsAliased()) {
          return true;
        }
        Place input_place(alloc, use->use_index());
        if (HasLoadsFromPlace(alloc, &input_place)) {
          return true;
        }
        if (alloc->Identity().IsUnknown()) {
          alloc->SetIdentity(AliasIdentity::NotAliased());
          aliasing_worklist_.Add(alloc);
        }
      }
    }
    return false;
  }

  void MarkDefinitionAsAliased(Definition* d) {
    auto* const defn = d->OriginalDefinition();
    if (defn->Identity().IsNotAliased()) {
      defn->SetIdentity(AliasIdentity::Aliased());
      identity_rollback_.Add(defn);

      // Add to worklist to propagate the mark transitively.
      aliasing_worklist_.Add(defn);
    }
  }

  // Mark any value stored into the given object as potentially aliased.
  void MarkStoredValuesEscaping(Definition* defn) {
    // Find all inputs corresponding to fields if allocating an object.
    if (auto* const alloc = defn->AsAllocation()) {
      for (intptr_t i = 0; i < alloc->InputCount(); i++) {
        if (auto* const slot = alloc->SlotForInput(i)) {
          MarkDefinitionAsAliased(alloc->InputAt(i)->definition());
        }
      }
    }
    // Find all stores into this object.
    for (Value* use = defn->input_use_list(); use != nullptr;
         use = use->next_use()) {
      auto instr = use->instruction();
      if (UseIsARedefinition(use)) {
        MarkStoredValuesEscaping(instr->AsDefinition());
        continue;
      }
      if ((use->use_index() == StoreFieldInstr::kInstancePos) &&
          instr->IsStoreField()) {
        MarkDefinitionAsAliased(instr->AsStoreField()->value()->definition());
      }
    }
  }

  // Determine if the given definition can't be aliased.
  void ComputeAliasing(Definition* alloc) {
    ASSERT(Place::IsAllocation(alloc));
    ASSERT(alloc->Identity().IsUnknown());
    ASSERT(aliasing_worklist_.is_empty());

    alloc->SetIdentity(AliasIdentity::NotAliased());
    aliasing_worklist_.Add(alloc);

    while (!aliasing_worklist_.is_empty()) {
      Definition* defn = aliasing_worklist_.RemoveLast();
      ASSERT(Place::IsAllocation(defn));
      // If the definition in the worklist was optimistically marked as
      // not-aliased check that optimistic assumption still holds: check if
      // any of its uses can create an alias.
      if (!defn->Identity().IsAliased() && AnyUseCreatesAlias(defn)) {
        defn->SetIdentity(AliasIdentity::Aliased());
        identity_rollback_.Add(defn);
      }

      // If the allocation site is marked as aliased conservatively mark
      // any values stored into the object aliased too.
      if (defn->Identity().IsAliased()) {
        MarkStoredValuesEscaping(defn);
      }
    }
  }

  Zone* zone_;
  FlowGraph* graph_;

  const bool print_traces_;

  PointerSet<Place>* places_map_;

  const ZoneGrowableArray<Place*>& places_;

  const PhiPlaceMoves* phi_moves_;

  // A list of all seen aliases and a map that allows looking up canonical
  // alias object.
  GrowableArray<const Place*> aliases_;
  PointerSet<const Place> aliases_map_;

  SmallSet<Place::ElementSize> typed_data_access_sizes_;

  // Maps alias id to set of ids of places representing the alias.
  // Place represents an alias if this alias is least generic alias for
  // the place.
  // (see ToAlias for the definition of least generic alias).
  GrowableArray<BitVector*> representatives_;

  // Maps alias id to set of ids of places aliased.
  GrowableArray<BitVector*> killed_;

  // Set of ids of places that can be affected by side-effects other than
  // explicit stores (i.e. through calls).
  BitVector* aliased_by_effects_;

  // Worklist used during alias analysis.
  GrowableArray<Definition*> aliasing_worklist_;

  // List of definitions that had their identity set to Aliased. At the end
  // of load optimization their identity will be rolled back to Unknown to
  // avoid treating them as Aliased at later stages without checking first
  // as optimizations can potentially eliminate instructions leading to
  // aliasing.
  GrowableArray<Definition*> identity_rollback_;
};

static Definition* GetStoredValue(Instruction* instr) {
  if (instr->IsStoreIndexed()) {
    return instr->AsStoreIndexed()->value()->definition();
  }

  StoreFieldInstr* store_instance_field = instr->AsStoreField();
  if (store_instance_field != nullptr) {
    return store_instance_field->value()->definition();
  }

  StoreStaticFieldInstr* store_static_field = instr->AsStoreStaticField();
  if (store_static_field != nullptr) {
    return store_static_field->value()->definition();
  }

  UNREACHABLE();  // Should only be called for supported store instructions.
  return nullptr;
}

static bool IsPhiDependentPlace(Place* place) {
  return (place->kind() == Place::kInstanceField) &&
         (place->instance() != nullptr) && place->instance()->IsPhi();
}

// For each place that depends on a phi ensure that equivalent places
// corresponding to phi input are numbered and record outgoing phi moves
// for each block which establish correspondence between phi dependent place
// and phi input's place that is flowing in.
static PhiPlaceMoves* ComputePhiMoves(PointerSet<Place>* map,
                                      ZoneGrowableArray<Place*>* places,
                                      bool print_traces) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  PhiPlaceMoves* phi_moves = new (zone) PhiPlaceMoves();

  for (intptr_t i = 0; i < places->length(); i++) {
    Place* place = (*places)[i];

    if (IsPhiDependentPlace(place)) {
      PhiInstr* phi = place->instance()->AsPhi();
      BlockEntryInstr* block = phi->GetBlock();

      if (FLAG_trace_optimization && print_traces) {
        THR_Print("phi dependent place %s\n", place->ToCString());
      }

      Place input_place(*place);
      for (intptr_t j = 0; j < phi->InputCount(); j++) {
        input_place.set_instance(phi->InputAt(j)->definition());

        Place* result = map->LookupValue(&input_place);
        if (result == nullptr) {
          result = Place::Wrap(zone, input_place, places->length());
          map->Insert(result);
          places->Add(result);
          if (FLAG_trace_optimization && print_traces) {
            THR_Print("  adding place %s as %" Pd "\n", result->ToCString(),
                      result->id());
          }
        }
        phi_moves->CreateOutgoingMove(zone, block->PredecessorAt(j),
                                      result->id(), place->id());
      }
    }
  }

  return phi_moves;
}

DART_FORCE_INLINE static void SetPlaceId(Instruction* instr, intptr_t id) {
  instr->SetPassSpecificId(CompilerPass::kCSE, id);
}

DART_FORCE_INLINE static bool HasPlaceId(const Instruction* instr) {
  return instr->HasPassSpecificId(CompilerPass::kCSE);
}

DART_FORCE_INLINE static intptr_t GetPlaceId(const Instruction* instr) {
  ASSERT(HasPlaceId(instr));
  return instr->GetPassSpecificId(CompilerPass::kCSE);
}

enum CSEMode { kOptimizeLoads, kOptimizeStores };

static AliasedSet* NumberPlaces(FlowGraph* graph,
                                PointerSet<Place>* map,
                                CSEMode mode) {
  // Loads representing different expression ids will be collected and
  // used to build per offset kill sets.
  Zone* zone = graph->zone();
  ZoneGrowableArray<Place*>* places = new (zone) ZoneGrowableArray<Place*>(10);

  bool has_loads = false;
  bool has_stores = false;
  for (BlockIterator it = graph->reverse_postorder_iterator(); !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();

    for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
         instr_it.Advance()) {
      Instruction* instr = instr_it.Current();
      Place place(graph, instr, &has_loads, &has_stores);
      if (place.kind() == Place::kNone) {
        continue;
      }

      Place* result = map->LookupValue(&place);
      if (result == nullptr) {
        result = Place::Wrap(zone, place, places->length());
        map->Insert(result);
        places->Add(result);

        if (FLAG_trace_optimization && graph->should_print()) {
          THR_Print("numbering %s as %" Pd "\n", result->ToCString(),
                    result->id());
        }
      }

      SetPlaceId(instr, result->id());
    }
  }

  if ((mode == kOptimizeLoads) && !has_loads) {
    return nullptr;
  }
  if ((mode == kOptimizeStores) && !has_stores) {
    return nullptr;
  }

  PhiPlaceMoves* phi_moves =
      ComputePhiMoves(map, places, graph->should_print());

  // Build aliasing sets mapping aliases to loads.
  return new (zone)
      AliasedSet(zone, graph, map, places, phi_moves, graph->should_print());
}

// Load instructions handled by load elimination.
static bool IsLoadEliminationCandidate(Instruction* instr) {
  if (instr->IsDefinition() &&
      instr->AsDefinition()->MayCreateUnsafeUntaggedPointer()) {
    return false;
  }
  if (auto* load = instr->AsLoadField()) {
    if (load->slot().is_weak()) {
      return false;
    }
  }
  return instr->IsLoadField() || instr->IsLoadIndexed() ||
         instr->IsLoadStaticField();
}

static bool IsLoopInvariantLoad(ZoneGrowableArray<BitVector*>* sets,
                                intptr_t loop_header_index,
                                Instruction* instr) {
  return IsLoadEliminationCandidate(instr) && (sets != nullptr) &&
         HasPlaceId(instr) &&
         (*sets)[loop_header_index]->Contains(GetPlaceId(instr));
}

LICM::LICM(FlowGraph* flow_graph) : flow_graph_(flow_graph) {
  ASSERT(flow_graph->is_licm_allowed());
}

void LICM::Hoist(ForwardInstructionIterator* it,
                 BlockEntryInstr* pre_header,
                 Instruction* current) {
  if (FLAG_trace_optimization && flow_graph_->should_print()) {
    THR_Print("Hoisting instruction %s:%" Pd " from B%" Pd " to B%" Pd "\n",
              current->DebugName(), current->GetDeoptId(),
              current->GetBlock()->block_id(), pre_header->block_id());
  }
  // Move the instruction out of the loop.
  current->RemoveEnvironment();
  if (it != nullptr) {
    it->RemoveCurrentFromGraph();
  } else {
    current->RemoveFromGraph();
  }
  GotoInstr* last = pre_header->last_instruction()->AsGoto();
  // Using kind kEffect will not assign a fresh ssa temporary index.
  flow_graph()->InsertBefore(last, current, last->env(), FlowGraph::kEffect);
  // If the hoisted instruction lazy-deopts, it should continue at the start of
  // the Goto (of which we copy the deopt-id from).
  current->env()->MarkAsLazyDeoptToBeforeDeoptId();
  current->env()->MarkAsHoisted();
  current->CopyDeoptIdFrom(*last);
}

void LICM::TrySpecializeSmiPhi(PhiInstr* phi,
                               BlockEntryInstr* header,
                               BlockEntryInstr* pre_header) {
  if (phi->Type()->ToCid() == kSmiCid) {
    return;
  }

  // Check if there is only a single kDynamicCid input to the phi that
  // comes from the pre-header.
  const intptr_t kNotFound = -1;
  intptr_t non_smi_input = kNotFound;
  for (intptr_t i = 0; i < phi->InputCount(); ++i) {
    Value* input = phi->InputAt(i);
    if (input->Type()->ToCid() != kSmiCid) {
      if ((non_smi_input != kNotFound) ||
          (input->Type()->ToCid() != kDynamicCid)) {
        // There are multiple kDynamicCid inputs or there is an input that is
        // known to be non-smi.
        return;
      } else {
        non_smi_input = i;
      }
    }
  }

  if ((non_smi_input == kNotFound) ||
      (phi->block()->PredecessorAt(non_smi_input) != pre_header)) {
    return;
  }

  CheckSmiInstr* check = nullptr;
  for (Value* use = phi->input_use_list();
       (use != nullptr) && (check == nullptr); use = use->next_use()) {
    check = use->instruction()->AsCheckSmi();
  }

  if (check == nullptr) {
    return;
  }

  // Host CheckSmi instruction and make this phi smi one.
  Hoist(nullptr, pre_header, check);

  // Replace value we are checking with phi's input.
  check->value()->BindTo(phi->InputAt(non_smi_input)->definition());
  check->value()->SetReachingType(phi->InputAt(non_smi_input)->Type());

  phi->UpdateType(CompileType::FromCid(kSmiCid));
}

void LICM::OptimisticallySpecializeSmiPhis() {
  if (flow_graph()->function().ProhibitsInstructionHoisting() ||
      CompilerState::Current().is_aot()) {
    // Do not hoist any: Either deoptimized on a hoisted check,
    // or compiling precompiled code where we can't do optimistic
    // hoisting of checks.
    return;
  }

  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
      flow_graph()->GetLoopHierarchy().headers();

  for (intptr_t i = 0; i < loop_headers.length(); ++i) {
    JoinEntryInstr* header = loop_headers[i]->AsJoinEntry();
    // Skip loop that don't have a pre-header block.
    BlockEntryInstr* pre_header = header->ImmediateDominator();
    if (pre_header == nullptr) continue;

    for (PhiIterator it(header); !it.Done(); it.Advance()) {
      TrySpecializeSmiPhi(it.Current(), header, pre_header);
    }
  }
}

void LICM::Optimize() {
  if (flow_graph()->function().ProhibitsInstructionHoisting()) {
    // Do not hoist any.
    return;
  }

  // Compute loops and induction in flow graph.
  const LoopHierarchy& loop_hierarchy = flow_graph()->GetLoopHierarchy();
  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
      loop_hierarchy.headers();
  loop_hierarchy.ComputeInduction();

  ZoneGrowableArray<BitVector*>* loop_invariant_loads =
      flow_graph()->loop_invariant_loads();

  // Iterate over all loops.
  for (intptr_t i = 0; i < loop_headers.length(); ++i) {
    BlockEntryInstr* header = loop_headers[i];

    // Skip loops that don't have a pre-header block.
    BlockEntryInstr* pre_header = header->ImmediateDominator();
    if (pre_header == nullptr) {
      continue;
    }

    // Flag that remains true as long as the loop has not seen any instruction
    // that may have a "visible" effect (write, throw, or other side-effect).
    bool seen_visible_effect = false;

    // Iterate over all blocks in the loop.
    LoopInfo* loop = header->loop_info();
    for (BitVector::Iterator loop_it(loop->blocks()); !loop_it.Done();
         loop_it.Advance()) {
      BlockEntryInstr* block = flow_graph()->preorder()[loop_it.Current()];

      if (block->IsCatchBlockEntry()) {
        // Don't hoist out of catch block because transitions from try
        // block to catch block are implicit and we might be hoisting
        // load around and over the "store followed by throw in the try".
        continue;
      }

      // Preserve the "visible" effect flag as long as the preorder traversal
      // sees always-taken blocks. This way, we can only hoist invariant
      // may-throw instructions that are always seen during the first iteration.
      if (!seen_visible_effect && !loop->IsAlwaysTaken(block)) {
        seen_visible_effect = true;
      }
      // Iterate over all instructions in the block.
      for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
        Instruction* current = it.Current();

        // Treat loads of static final fields specially: we can CSE them but
        // we should not move them around unless the field is initialized.
        // Otherwise we might move load past the initialization.
        if (LoadStaticFieldInstr* load = current->AsLoadStaticField()) {
          if (load->AllowsCSE()) {
            seen_visible_effect = true;
            continue;
          }
        }

        // Determine if we can hoist loop invariant code. Even may-throw
        // instructions can be hoisted as long as its exception is still
        // the very first "visible" effect of the loop.
        bool is_loop_invariant = false;
        if ((current->AllowsCSE() ||
             IsLoopInvariantLoad(loop_invariant_loads, i, current)) &&
            (!seen_visible_effect || !current->MayHaveVisibleEffect())) {
          is_loop_invariant = true;
          for (intptr_t i = 0; i < current->InputCount(); ++i) {
            Definition* input_def = current->InputAt(i)->definition();
            if (!input_def->GetBlock()->Dominates(pre_header)) {
              is_loop_invariant = false;
              break;
            }
          }
        }

        // Hoist if all inputs are loop invariant. If not hoisted, any
        // instruction that writes, may throw, or has an unknown side
        // effect invalidates the first "visible" effect flag.
        if (is_loop_invariant) {
          Hoist(&it, pre_header, current);
        } else if (!seen_visible_effect && current->MayHaveVisibleEffect()) {
          seen_visible_effect = true;
        }
      }
    }
  }
}

void DelayAllocations::Optimize(FlowGraph* graph) {
  // Go through all Allocation instructions and move them down to their
  // dominant use when doing so is sound.
  DirectChainedHashMap<IdentitySetKeyValueTrait<Instruction*>> moved;
  for (BlockIterator block_it = graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();

    for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
         instr_it.Advance()) {
      Definition* def = instr_it.Current()->AsDefinition();
      if (def != nullptr && def->IsAllocation() && def->env() == nullptr &&
          !moved.HasKey(def)) {
        auto [block_of_use, use] = DominantUse({block, def});
        if (use != nullptr && !use->IsPhi() &&
            IsOneTimeUse(block_of_use, block)) {
          instr_it.RemoveCurrentFromGraph();
          def->InsertBefore(use);
          moved.Insert(def);
        }
      }
    }
  }
}

std::pair<BlockEntryInstr*, Instruction*> DelayAllocations::DominantUse(
    std::pair<BlockEntryInstr*, Definition*> def_in_block) {
  const auto block_of_def = def_in_block.first;
  const auto def = def_in_block.second;

  // Find the use that dominates all other uses.

  // Collect all uses.
  DirectChainedHashMap<IdentitySetKeyValueTrait<Instruction*>> uses;
  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    Instruction* use = it.Current()->instruction();
    uses.Insert(use);
  }
  for (Value::Iterator it(def->env_use_list()); !it.Done(); it.Advance()) {
    Instruction* use = it.Current()->instruction();
    uses.Insert(use);
  }

  // Returns |true| iff |instr| or any instruction dominating it are either a
  // a |def| or a use of a |def|.
  //
  // Additionally this function computes the block of the |instr| and sets
  // |*block_of_instr| to that block.
  auto is_dominated_by_another_use = [&](Instruction* instr,
                                         BlockEntryInstr** block_of_instr) {
    BlockEntryInstr* first_block = nullptr;
    while (instr != def) {
      if (uses.HasKey(instr)) {
        // We hit another use, meaning that this use dominates the given |use|.
        return true;
      }
      if (auto block = instr->AsBlockEntry()) {
        if (first_block == nullptr) {
          first_block = block;
        }
        instr = block->dominator()->last_instruction();
      } else {
        instr = instr->previous();
      }
    }
    if (block_of_instr != nullptr) {
      if (first_block == nullptr) {
        // We hit |def| while iterating instructions without actually hitting
        // the start of the block. This means |def| and |use| reside in the
        // same block.
        *block_of_instr = block_of_def;
      } else {
        *block_of_instr = first_block;
      }
    }
    return false;
  };

  // Find the dominant use.
  std::pair<BlockEntryInstr*, Instruction*> dominant_use = {nullptr, nullptr};
  auto use_it = uses.GetIterator();
  while (auto use = use_it.Next()) {
    bool dominated_by_another_use = false;
    BlockEntryInstr* block_of_use = nullptr;

    if (auto phi = (*use)->AsPhi()) {
      // For phi uses check that the dominant use dominates all
      // predecessor blocks corresponding to matching phi inputs.
      ASSERT(phi->InputCount() == phi->block()->PredecessorCount());
      dominated_by_another_use = true;
      for (intptr_t i = 0; i < phi->InputCount(); i++) {
        if (phi->InputAt(i)->definition() == def) {
          if (!is_dominated_by_another_use(
                  phi->block()->PredecessorAt(i)->last_instruction(),
                  /*block_of_instr=*/nullptr)) {
            dominated_by_another_use = false;
            block_of_use = phi->block();
            break;
          }
        }
      }
    } else {
      // Start with the instruction before the use, then walk backwards through
      // blocks in the dominator chain until we hit the definition or
      // another use.
      dominated_by_another_use =
          is_dominated_by_another_use((*use)->previous(), &block_of_use);
    }

    if (!dominated_by_another_use) {
      if (dominant_use.second != nullptr) {
        // More than one use reached the definition, which means no use
        // dominates all other uses.
        return {nullptr, nullptr};
      }
      dominant_use = {block_of_use, *use};
    }
  }

  return dominant_use;
}

bool DelayAllocations::IsOneTimeUse(BlockEntryInstr* use_block,
                                    BlockEntryInstr* def_block) {
  // Check that this use is always executed at most once for each execution of
  // the definition, i.e. that there is no path from the use to itself that
  // doesn't pass through the definition.
  if (use_block == def_block) return true;

  DirectChainedHashMap<IdentitySetKeyValueTrait<BlockEntryInstr*>> seen;
  GrowableArray<BlockEntryInstr*> worklist;
  worklist.Add(use_block);

  while (!worklist.is_empty()) {
    BlockEntryInstr* block = worklist.RemoveLast();
    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      if (pred == use_block) return false;
      if (pred == def_block) continue;
      if (seen.HasKey(pred)) continue;
      seen.Insert(pred);
      worklist.Add(pred);
    }
  }
  return true;
}

class LoadOptimizer : public ValueObject {
 public:
  LoadOptimizer(FlowGraph* graph, AliasedSet* aliased_set)
      : graph_(graph),
        aliased_set_(aliased_set),
        in_(graph_->preorder().length()),
        out_(graph_->preorder().length()),
        gen_(graph_->preorder().length()),
        kill_(graph_->preorder().length()),
        exposed_values_(graph_->preorder().length()),
        out_values_(graph_->preorder().length()),
        phis_(5),
        worklist_(5),
        congruency_worklist_(6),
        in_worklist_(nullptr),
        forwarded_(false) {
    const intptr_t num_blocks = graph_->preorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      out_.Add(nullptr);
      gen_.Add(new (Z) BitVector(Z, aliased_set_->max_place_id()));
      kill_.Add(new (Z) BitVector(Z, aliased_set_->max_place_id()));
      in_.Add(new (Z) BitVector(Z, aliased_set_->max_place_id()));

      exposed_values_.Add(nullptr);
      out_values_.Add(nullptr);
    }
  }

  ~LoadOptimizer() { aliased_set_->RollbackAliasedIdentities(); }

  Zone* zone() const { return graph_->zone(); }

  static bool OptimizeGraph(FlowGraph* graph) {
    ASSERT(FLAG_load_cse);

    // For now, bail out for large functions to avoid OOM situations.
    // TODO(fschneider): Fix the memory consumption issue.
    if (graph->is_huge_method()) {
      return false;
    }

    PointerSet<Place> map;
    AliasedSet* aliased_set = NumberPlaces(graph, &map, kOptimizeLoads);
    if ((aliased_set != nullptr) && !aliased_set->IsEmpty()) {
      // If any loads were forwarded return true from Optimize to run load
      // forwarding again. This will allow to forward chains of loads.
      // This is especially important for context variables as they are built
      // as loads from loaded context.
      // TODO(vegorov): renumber newly discovered congruences during the
      // forwarding to forward chains without running whole pass twice.
      LoadOptimizer load_optimizer(graph, aliased_set);
      return load_optimizer.Optimize();
    }
    return false;
  }

 private:
  bool Optimize() {
    // Initializer calls should be eliminated before ComputeInitialSets()
    // in order to calculate kill sets more precisely.
    OptimizeLazyInitialization();

    ComputeInitialSets();
    ComputeOutSets();
    ComputeOutValues();
    if (graph_->is_licm_allowed()) {
      MarkLoopInvariantLoads();
    }
    ForwardLoads();
    EmitPhis();
    return forwarded_;
  }

  bool CallsInitializer(Instruction* instr) {
    if (auto* load_field = instr->AsLoadField()) {
      return load_field->calls_initializer();
    } else if (auto* load_static = instr->AsLoadStaticField()) {
      return load_static->calls_initializer();
    }
    return false;
  }

  void ClearCallsInitializer(Instruction* instr) {
    if (auto* load_field = instr->AsLoadField()) {
      load_field->clear_calls_initializer();
    } else if (auto* load_static = instr->AsLoadStaticField()) {
      load_static->clear_calls_initializer();
    } else {
      UNREACHABLE();
    }
  }

  bool CanForwardLoadTo(Definition* load, Definition* replacement) {
    // Loads which check initialization status can only be replaced if
    // we can guarantee that forwarded value is not a sentinel.
    return !(CallsInitializer(load) && replacement->Type()->can_be_sentinel());
  }

  // Returns true if given instruction stores the sentinel value.
  // Such a store doesn't initialize corresponding field.
  bool IsSentinelStore(Instruction* instr) {
    Value* value = nullptr;
    if (auto* store_field = instr->AsStoreField()) {
      value = store_field->value();
    } else if (auto* store_static = instr->AsStoreStaticField()) {
      value = store_static->value();
    }
    return value != nullptr && value->BindsToConstant() &&
           (value->BoundConstant().ptr() == Object::sentinel().ptr());
  }

  // This optimization pass tries to get rid of lazy initializer calls in
  // LoadField and LoadStaticField instructions. The "initialized" state of
  // places is propagated through the flow graph.
  void OptimizeLazyInitialization() {
    if (!FLAG_optimize_lazy_initializer_calls) {
      return;
    }

    // 1) Populate 'gen' sets with places which are initialized at each basic
    // block. Optimize lazy initializer calls within basic block and
    // figure out if there are lazy initializer calls left to optimize.
    bool has_lazy_initializer_calls = false;
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      BitVector* gen = gen_[block->preorder_number()];

      for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        bool is_load = false, is_store = false;
        Place place(graph_, instr, &is_load, &is_store);

        if (is_store && !IsSentinelStore(instr)) {
          gen->Add(GetPlaceId(instr));
        } else if (is_load) {
          const auto place_id = GetPlaceId(instr);
          if (CallsInitializer(instr)) {
            if (gen->Contains(place_id)) {
              ClearCallsInitializer(instr);
            } else {
              has_lazy_initializer_calls = true;
            }
          }
          gen->Add(place_id);
        }
      }

      // Spread initialized state through outgoing phis.
      PhiPlaceMoves::MovesList phi_moves =
          aliased_set_->phi_moves()->GetOutgoingMoves(block);
      if (phi_moves != nullptr) {
        for (intptr_t i = 0, n = phi_moves->length(); i < n; ++i) {
          const intptr_t from = (*phi_moves)[i].from();
          const intptr_t to = (*phi_moves)[i].to();
          if ((from != to) && gen->Contains(from)) {
            gen->Add(to);
          }
        }
      }
    }

    if (has_lazy_initializer_calls) {
      // 2) Propagate initialized state between blocks, calculating
      // incoming initialized state. Iterate until reaching fixed point.
      BitVector* temp = new (Z) BitVector(Z, aliased_set_->max_place_id());
      bool changed = true;
      while (changed) {
        changed = false;

        for (BlockIterator block_it = graph_->reverse_postorder_iterator();
             !block_it.Done(); block_it.Advance()) {
          BlockEntryInstr* block = block_it.Current();
          BitVector* block_in = in_[block->preorder_number()];
          BitVector* gen = gen_[block->preorder_number()];

          // Incoming initialized state is the intersection of all
          // outgoing initialized states of predecessors.
          if (block->IsGraphEntry()) {
            temp->Clear();
          } else {
            temp->SetAll();
            ASSERT(block->PredecessorCount() > 0);
            for (intptr_t i = 0, pred_count = block->PredecessorCount();
                 i < pred_count; ++i) {
              BlockEntryInstr* pred = block->PredecessorAt(i);
              BitVector* pred_out = gen_[pred->preorder_number()];
              temp->Intersect(pred_out);
            }
          }

          if (!temp->Equals(*block_in)) {
            ASSERT(block_in->SubsetOf(*temp));
            block_in->AddAll(temp);
            gen->AddAll(temp);
            changed = true;
          }
        }
      }

      // 3) Single pass through basic blocks to optimize lazy
      // initializer calls using calculated incoming inter-block
      // initialized state.
      for (BlockIterator block_it = graph_->reverse_postorder_iterator();
           !block_it.Done(); block_it.Advance()) {
        BlockEntryInstr* block = block_it.Current();
        BitVector* block_in = in_[block->preorder_number()];

        for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
             instr_it.Advance()) {
          Instruction* instr = instr_it.Current();
          if (CallsInitializer(instr) &&
              block_in->Contains(GetPlaceId(instr))) {
            ClearCallsInitializer(instr);
          }
        }
      }
    }

    // Clear sets which are also used in the main part of load forwarding.
    for (intptr_t i = 0, n = graph_->preorder().length(); i < n; ++i) {
      gen_[i]->Clear();
      in_[i]->Clear();
    }
  }

  // Only forward stores to normal arrays, float64, and simd arrays
  // to loads because other array stores (intXX/uintXX/float32)
  // may implicitly convert the value stored.
  bool CanForwardStore(StoreIndexedInstr* array_store) {
    if (array_store == nullptr) return true;
    auto const rep = RepresentationUtils::RepresentationOfArrayElement(
        array_store->class_id());
    return !RepresentationUtils::IsUnboxedInteger(rep) && rep != kUnboxedFloat;
  }

  static bool AlreadyPinnedByRedefinition(Definition* replacement,
                                          Definition* redefinition) {
    Definition* defn = replacement;
    if (auto load_field = replacement->AsLoadField()) {
      defn = load_field->instance()->definition();
    } else if (auto load_indexed = replacement->AsLoadIndexed()) {
      defn = load_indexed->array()->definition();
    }

    Value* unwrapped;
    while ((unwrapped = defn->RedefinedValue()) != nullptr) {
      if (defn == redefinition) {
        return true;
      }
      defn = unwrapped->definition();
    }

    return false;
  }

  Definition* ReplaceLoad(Definition* load, Definition* replacement) {
    // When replacing a load from a generic field or from an array element
    // check if instance we are loading from is redefined. If it is then
    // we need to ensure that replacement is not going to break the
    // dependency chain.
    Definition* redef = nullptr;
    if (auto load_field = load->AsLoadField()) {
      auto instance = load_field->instance()->definition();
      if (instance->RedefinedValue() != nullptr) {
        if ((load_field->slot().kind() ==
                 Slot::Kind::kGrowableObjectArray_data ||
             (load_field->slot().IsDartField() &&
              !AbstractType::Handle(load_field->slot().field().type())
                   .IsInstantiated()))) {
          redef = instance;
        }
      }
    } else if (auto load_indexed = load->AsLoadIndexed()) {
      if (load_indexed->class_id() == kArrayCid ||
          load_indexed->class_id() == kImmutableArrayCid) {
        auto instance = load_indexed->array()->definition();
        if (instance->RedefinedValue() != nullptr) {
          redef = instance;
        }
      }
    }
    if (redef != nullptr && !AlreadyPinnedByRedefinition(replacement, redef)) {
      // Original load had a redefined instance and replacement does not
      // depend on the same redefinition. Create a redefinition
      // of the replacement to keep the dependency chain.
      auto replacement_redefinition =
          new (zone()) RedefinitionInstr(new (zone()) Value(replacement));
      if (redef->IsDominatedBy(replacement)) {
        graph_->InsertAfter(redef, replacement_redefinition, /*env=*/nullptr,
                            FlowGraph::kValue);
      } else {
        graph_->InsertBefore(load, replacement_redefinition, /*env=*/nullptr,
                             FlowGraph::kValue);
      }
      replacement = replacement_redefinition;
    }

    load->ReplaceUsesWith(replacement);
    return replacement;
  }

  // Compute sets of loads generated and killed by each block.
  // Additionally compute upwards exposed and generated loads for each block.
  // Exposed loads are those that can be replaced if a corresponding
  // reaching load will be found.
  // Loads that are locally redundant will be replaced as we go through
  // instructions.
  void ComputeInitialSets() {
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t preorder_number = block->preorder_number();

      BitVector* kill = kill_[preorder_number];
      BitVector* gen = gen_[preorder_number];

      ZoneGrowableArray<Definition*>* exposed_values = nullptr;
      ZoneGrowableArray<Definition*>* out_values = nullptr;

      for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        bool is_load = false, is_store = false;
        Place place(graph_, instr, &is_load, &is_store);

        BitVector* killed = nullptr;
        // Throw that stores into e.stackTrace is not considered here.
        if (is_store && !instr->IsThrow()) {
          const intptr_t alias_id =
              aliased_set_->LookupAliasId(place.ToAlias());
          if (alias_id != AliasedSet::kNoAlias) {
            killed = aliased_set_->GetKilledSet(alias_id);
          } else if (!place.IsImmutableField()) {
            // We encountered unknown alias: this means intrablock load
            // forwarding refined parameter of this store, for example
            //
            //     o   <- alloc()
            //     a.f <- o
            //     u   <- a.f
            //     u.x <- null ;; this store alias is *.x
            //
            // after intrablock load forwarding
            //
            //     o   <- alloc()
            //     a.f <- o
            //     o.x <- null ;; this store alias is o.x
            //
            // In this case we fallback to using place id recorded in the
            // instruction that still points to the old place with a more
            // generic alias.
            const intptr_t old_alias_id = aliased_set_->LookupAliasId(
                aliased_set_->places()[GetPlaceId(instr)]->ToAlias());
            killed = aliased_set_->GetKilledSet(old_alias_id);
          }

          // Find canonical place of store.
          Place* canonical_place = nullptr;
          if (CanForwardStore(instr->AsStoreIndexed())) {
            canonical_place = aliased_set_->LookupCanonical(&place);
            if (canonical_place != nullptr) {
              // Is this a redundant store (stored value already resides
              // in this field)?
              const intptr_t place_id = canonical_place->id();
              if (gen->Contains(place_id)) {
                ASSERT((out_values != nullptr) &&
                       ((*out_values)[place_id] != nullptr));
                if ((*out_values)[place_id] == GetStoredValue(instr)) {
                  if (FLAG_trace_optimization && graph_->should_print()) {
                    THR_Print("Removing redundant store to place %" Pd
                              " in block B%" Pd "\n",
                              GetPlaceId(instr), block->block_id());
                  }
                  instr_it.RemoveCurrentFromGraph();
                  continue;
                }
              }
            }
          }

          // Update kill/gen/out_values (after inspection of incoming values).
          if (killed != nullptr) {
            kill->AddAll(killed);
            // There is no need to clear out_values when clearing GEN set
            // because only those values that are in the GEN set
            // will ever be used.
            gen->RemoveAll(killed);
          }
          if (canonical_place != nullptr) {
            // Store has a corresponding numbered place that might have a
            // load. Try forwarding stored value to it.
            gen->Add(canonical_place->id());
            if (out_values == nullptr) out_values = CreateBlockOutValues();
            (*out_values)[canonical_place->id()] = GetStoredValue(instr);
          }

          ASSERT(!instr->IsDefinition() ||
                 !IsLoadEliminationCandidate(instr->AsDefinition()));
          continue;
        } else if (is_load) {
          // Check if this load needs renumbering because of the intrablock
          // load forwarding.
          const Place* canonical = aliased_set_->LookupCanonical(&place);
          if ((canonical != nullptr) &&
              (canonical->id() != GetPlaceId(instr->AsDefinition()))) {
            SetPlaceId(instr->AsDefinition(), canonical->id());
          }
        }

        // If instruction has effects then kill all loads affected.
        if (instr->HasUnknownSideEffects()) {
          kill->AddAll(aliased_set_->aliased_by_effects());
          // There is no need to clear out_values when removing values from GEN
          // set because only those values that are in the GEN set
          // will ever be used.
          gen->RemoveAll(aliased_set_->aliased_by_effects());
        }

        Definition* defn = instr->AsDefinition();
        if (defn == nullptr) {
          continue;
        }

        if (auto* const alloc = instr->AsAllocation()) {
          if (!alloc->ObjectIsInitialized()) {
            // Since the allocated object is uninitialized, we can't forward
            // any values from it.
            continue;
          }
          for (Value* use = alloc->input_use_list(); use != nullptr;
               use = use->next_use()) {
            if (use->use_index() != 0) {
              // Not a potential immediate load or store, since they take the
              // instance as the first input.
              continue;
            }
            intptr_t place_id = -1;
            Definition* forward_def = nullptr;
            const Slot* slot = nullptr;
            if (auto* const load = use->instruction()->AsLoadField()) {
              place_id = GetPlaceId(load);
              slot = &load->slot();
            } else if (auto* const store = use->instruction()->AsStoreField()) {
              ASSERT(!alloc->IsArrayAllocation());
              place_id = GetPlaceId(store);
              slot = &store->slot();
            } else if (use->instruction()->IsLoadIndexed() ||
                       use->instruction()->IsStoreIndexed()) {
              if (!alloc->IsArrayAllocation()) {
                // Non-array allocations can be accessed with LoadIndexed
                // and StoreIndex in the unreachable code.
                continue;
              }
              if (alloc->IsAllocateTypedData()) {
                // Typed data payload elements are unboxed and initialized to
                // zero, so don't forward a tagged null value.
                continue;
              }
              if (aliased_set_->CanBeAliased(alloc)) {
                continue;
              }
              place_id = GetPlaceId(use->instruction());
              if (aliased_set_->places()[place_id]->kind() !=
                  Place::kConstantIndexed) {
                continue;
              }
              // Set initial value of array element to null.
              forward_def = graph_->constant_null();
            } else {
              // Not an immediate load or store.
              continue;
            }

            ASSERT(place_id != -1);
            if (slot != nullptr) {
              ASSERT(forward_def == nullptr);
              // Final fields are initialized in constructors. However, at the
              // same time we assume that known values of final fields can be
              // forwarded across side-effects. For an escaping object, one such
              // side effect can be an uninlined constructor invocation. Thus,
              // if we add 'null' as known initial values for these fields,
              // this null will be incorrectly propagated across any uninlined
              // constructor invocation and used instead of the real value.
              if (aliased_set_->CanBeAliased(alloc) && slot->IsDartField() &&
                  slot->is_immutable()) {
                continue;
              }

              const intptr_t pos = alloc->InputForSlot(*slot);
              if (pos != -1) {
                forward_def = alloc->InputAt(pos)->definition();
              } else if (!slot->is_tagged()) {
                // Fields that do not contain tagged values should not
                // have a tagged null value forwarded for them, similar to
                // payloads of typed data arrays.
                continue;
              } else {
                // Fields not provided as an input to the instruction are
                // initialized to null during allocation.
                forward_def = graph_->constant_null();
              }
            }

            ASSERT(forward_def != nullptr);
            gen->Add(place_id);
            if (out_values == nullptr) out_values = CreateBlockOutValues();
            (*out_values)[place_id] = forward_def;
          }
          continue;
        }

        if (!IsLoadEliminationCandidate(defn)) {
          continue;
        }

        const intptr_t place_id = GetPlaceId(defn);
        if (gen->Contains(place_id)) {
          // This is a locally redundant load.
          ASSERT((out_values != nullptr) &&
                 ((*out_values)[place_id] != nullptr));

          Definition* replacement = (*out_values)[place_id];
          if (CanForwardLoadTo(defn, replacement)) {
            graph_->EnsureSSATempIndex(defn, replacement);
            if (FLAG_trace_optimization && graph_->should_print()) {
              THR_Print("Replacing load v%" Pd " with v%" Pd "\n",
                        defn->ssa_temp_index(), replacement->ssa_temp_index());
            }

            ReplaceLoad(defn, replacement);
            instr_it.RemoveCurrentFromGraph();
            forwarded_ = true;
            continue;
          }
        } else if (!kill->Contains(place_id)) {
          // This is an exposed load: it is the first representative of a
          // given expression id and it is not killed on the path from
          // the block entry.
          if (exposed_values == nullptr) {
            const intptr_t kMaxExposedValuesInitialSize = 5;
            exposed_values = new (Z) ZoneGrowableArray<Definition*>(
                Utils::Minimum(kMaxExposedValuesInitialSize,
                               aliased_set_->max_place_id()));
          }

          exposed_values->Add(defn);
        }

        gen->Add(place_id);

        if (out_values == nullptr) out_values = CreateBlockOutValues();
        (*out_values)[place_id] = defn;
      }

      exposed_values_[preorder_number] = exposed_values;
      out_values_[preorder_number] = out_values;
    }
  }

  static void PerformPhiMoves(PhiPlaceMoves::MovesList phi_moves,
                              BitVector* out,
                              BitVector* forwarded_loads) {
    forwarded_loads->Clear();

    for (intptr_t i = 0; i < phi_moves->length(); i++) {
      const intptr_t from = (*phi_moves)[i].from();
      const intptr_t to = (*phi_moves)[i].to();
      if (from == to) continue;

      if (out->Contains(from)) {
        forwarded_loads->Add(to);
      }
    }

    for (intptr_t i = 0; i < phi_moves->length(); i++) {
      const intptr_t from = (*phi_moves)[i].from();
      const intptr_t to = (*phi_moves)[i].to();
      if (from == to) continue;

      out->Remove(to);
    }

    out->AddAll(forwarded_loads);
  }

  // Aggregate kill sets for all blocks sharing same try index.
  void ComputeKillSetsForTryBodies(
      GrowableArray<BitVector*>& try_bodies_kills) {
    for (intptr_t i = 0; i < graph_->try_entries().length(); i++) {
      try_bodies_kills.Add(nullptr);
    }
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      if (block->try_index() == kInvalidTryIndex) {
        continue;
      }
      BitVector* kill = kill_[block->preorder_number()];
      BitVector* existing = try_bodies_kills[block->try_index()];
      if (existing == nullptr) {
        BitVector* copy = new BitVector(Z, kill->length());
        copy->CopyFrom(kill);
        try_bodies_kills[block->try_index()] = copy;
      } else {
        existing->AddAll(kill);
      }
    }
  }

  // Compute OUT sets by propagating them iteratively until fix point
  // is reached.
  void ComputeOutSets() {
    BitVector* temp = new (Z) BitVector(Z, aliased_set_->max_place_id());
    BitVector* forwarded_loads =
        new (Z) BitVector(Z, aliased_set_->max_place_id());
    BitVector* temp_out = new (Z) BitVector(Z, aliased_set_->max_place_id());

    GrowableArray<BitVector*> try_bodies_kills(graph_->try_entries().length());
    ComputeKillSetsForTryBodies(try_bodies_kills);

    bool changed = true;
    while (changed) {
      changed = false;

      for (BlockIterator block_it = graph_->reverse_postorder_iterator();
           !block_it.Done(); block_it.Advance()) {
        BlockEntryInstr* block = block_it.Current();

        const intptr_t preorder_number = block->preorder_number();

        BitVector* block_in = in_[preorder_number];
        BitVector* block_out = out_[preorder_number];
        BitVector* block_kill = kill_[preorder_number];
        BitVector* block_gen = gen_[preorder_number];

        // Compute block_in as the intersection of all out(p) where p
        // is a predecessor of the current block.
        if (block->IsGraphEntry()) {
          temp->Clear();
        } else {
          temp->SetAll();
          ASSERT(block->PredecessorCount() > 0);
          for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
            BlockEntryInstr* pred = block->PredecessorAt(i);
            BitVector* pred_out = out_[pred->preorder_number()];
            if (pred_out == nullptr) continue;
            PhiPlaceMoves::MovesList phi_moves =
                aliased_set_->phi_moves()->GetOutgoingMoves(pred);
            if (phi_moves != nullptr) {
              // If there are phi moves, perform intersection with
              // a copy of pred_out where the phi moves are applied.
              temp_out->CopyFrom(pred_out);
              PerformPhiMoves(phi_moves, temp_out, forwarded_loads);
              pred_out = temp_out;
            }
            temp->Intersect(pred_out);
          }
          if (auto catch_entry = block->AsCatchBlockEntry()) {
            // Everything that is getting killed in corresponding try-block
            // should be removed from catch-block_in because we assume the
            // execution can get to catch-block at any point of the try-block.
            intptr_t catch_index = catch_entry->catch_try_index();
            temp->RemoveAll(try_bodies_kills[catch_index]);
          }
        }

        if (!temp->Equals(*block_in) || (block_out == nullptr)) {
          // If IN set has changed propagate the change to OUT set.
          block_in->CopyFrom(temp);

          temp->RemoveAll(block_kill);
          temp->AddAll(block_gen);

          if ((block_out == nullptr) || !block_out->Equals(*temp)) {
            if (block_out == nullptr) {
              block_out = out_[preorder_number] =
                  new (Z) BitVector(Z, aliased_set_->max_place_id());
            }
            block_out->CopyFrom(temp);
            changed = true;
          }
        }
      }
    }
  }

  // Compute out_values mappings by propagating them in reverse postorder once
  // through the graph. Generate phis on back edges where eager merge is
  // impossible.
  // No replacement is done at this point and thus any out_value[place_id] is
  // changed at most once: from nullptr to an actual value.
  // When merging incoming loads we might need to create a phi.
  // These phis are not inserted at the graph immediately because some of them
  // might become redundant after load forwarding is done.
  void ComputeOutValues() {
    GrowableArray<PhiInstr*> pending_phis(5);
    ZoneGrowableArray<Definition*>* temp_forwarded_values = nullptr;

    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();

      const bool can_merge_eagerly = CanMergeEagerly(block);

      const intptr_t preorder_number = block->preorder_number();

      ZoneGrowableArray<Definition*>* block_out_values =
          out_values_[preorder_number];

      // If OUT set has changed then we have new values available out of
      // the block. Compute these values creating phi where necessary.
      for (BitVector::Iterator it(out_[preorder_number]); !it.Done();
           it.Advance()) {
        const intptr_t place_id = it.Current();

        if (block_out_values == nullptr) {
          out_values_[preorder_number] = block_out_values =
              CreateBlockOutValues();
        }

        if ((*block_out_values)[place_id] == nullptr) {
          ASSERT(block->PredecessorCount() > 0);
          Definition* in_value = can_merge_eagerly
                                     ? MergeIncomingValues(block, place_id)
                                     : nullptr;
          if ((in_value == nullptr) &&
              (in_[preorder_number]->Contains(place_id))) {
            PhiInstr* phi = new (Z)
                PhiInstr(block->AsJoinEntry(), block->PredecessorCount());
            SetPlaceId(phi, place_id);
            pending_phis.Add(phi);
            in_value = phi;
          }
          (*block_out_values)[place_id] = in_value;
        }
      }

      // If the block has outgoing phi moves perform them. Use temporary list
      // of values to ensure that cyclic moves are performed correctly.
      PhiPlaceMoves::MovesList phi_moves =
          aliased_set_->phi_moves()->GetOutgoingMoves(block);
      if ((phi_moves != nullptr) && (block_out_values != nullptr)) {
        if (temp_forwarded_values == nullptr) {
          temp_forwarded_values = CreateBlockOutValues();
        }

        for (intptr_t i = 0; i < phi_moves->length(); i++) {
          const intptr_t from = (*phi_moves)[i].from();
          const intptr_t to = (*phi_moves)[i].to();
          if (from == to) continue;

          (*temp_forwarded_values)[to] = (*block_out_values)[from];
        }

        for (intptr_t i = 0; i < phi_moves->length(); i++) {
          const intptr_t from = (*phi_moves)[i].from();
          const intptr_t to = (*phi_moves)[i].to();
          if (from == to) continue;

          (*block_out_values)[to] = (*temp_forwarded_values)[to];
        }
      }

      if (FLAG_trace_load_optimization && graph_->should_print()) {
        THR_Print("B%" Pd "\n", block->block_id());
        THR_Print("  IN: ");
        aliased_set_->PrintSet(in_[preorder_number]);
        THR_Print("\n");

        THR_Print("  KILL: ");
        aliased_set_->PrintSet(kill_[preorder_number]);
        THR_Print("\n");

        THR_Print("  OUT: ");
        aliased_set_->PrintSet(out_[preorder_number]);
        THR_Print("\n");
      }
    }

    // All blocks were visited. Fill pending phis with inputs
    // that flow on back edges.
    for (intptr_t i = 0; i < pending_phis.length(); i++) {
      FillPhiInputs(pending_phis[i]);
    }
  }

  bool CanMergeEagerly(BlockEntryInstr* block) {
    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      if (pred->postorder_number() < block->postorder_number()) {
        return false;
      }
    }
    return true;
  }

  void MarkLoopInvariantLoads() {
    const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
        graph_->GetLoopHierarchy().headers();

    ZoneGrowableArray<BitVector*>* invariant_loads =
        new (Z) ZoneGrowableArray<BitVector*>(loop_headers.length());

    for (intptr_t i = 0; i < loop_headers.length(); i++) {
      BlockEntryInstr* header = loop_headers[i];
      BlockEntryInstr* pre_header = header->ImmediateDominator();
      if (pre_header == nullptr) {
        invariant_loads->Add(nullptr);
        continue;
      }

      BitVector* loop_gen = new (Z) BitVector(Z, aliased_set_->max_place_id());
      for (BitVector::Iterator loop_it(header->loop_info()->blocks());
           !loop_it.Done(); loop_it.Advance()) {
        const intptr_t preorder_number = loop_it.Current();
        loop_gen->AddAll(gen_[preorder_number]);
      }

      for (BitVector::Iterator loop_it(header->loop_info()->blocks());
           !loop_it.Done(); loop_it.Advance()) {
        const intptr_t preorder_number = loop_it.Current();
        loop_gen->RemoveAll(kill_[preorder_number]);
      }

      if (FLAG_trace_optimization && graph_->should_print()) {
        for (BitVector::Iterator it(loop_gen); !it.Done(); it.Advance()) {
          THR_Print("place %s is loop invariant for B%" Pd "\n",
                    aliased_set_->places()[it.Current()]->ToCString(),
                    header->block_id());
        }
      }

      invariant_loads->Add(loop_gen);
    }

    graph_->set_loop_invariant_loads(invariant_loads);
  }

  // Compute incoming value for the given expression id.
  // Will create a phi if different values are incoming from multiple
  // predecessors.
  Definition* MergeIncomingValues(BlockEntryInstr* block, intptr_t place_id) {
    // First check if the same value is coming in from all predecessors.
    static Definition* const kDifferentValuesMarker =
        reinterpret_cast<Definition*>(-1);
    Definition* incoming = nullptr;
    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ZoneGrowableArray<Definition*>* pred_out_values =
          out_values_[pred->preorder_number()];
      if ((pred_out_values == nullptr) ||
          ((*pred_out_values)[place_id] == nullptr)) {
        return nullptr;
      } else if (incoming == nullptr) {
        incoming = (*pred_out_values)[place_id];
      } else if (incoming != (*pred_out_values)[place_id]) {
        incoming = kDifferentValuesMarker;
      }
    }

    if (incoming != kDifferentValuesMarker) {
      ASSERT(incoming != nullptr);
      return incoming;
    }

    // Incoming values are different. Phi is required to merge.
    PhiInstr* phi =
        new (Z) PhiInstr(block->AsJoinEntry(), block->PredecessorCount());
    SetPlaceId(phi, place_id);
    FillPhiInputs(phi);
    return phi;
  }

  void FillPhiInputs(PhiInstr* phi) {
    BlockEntryInstr* block = phi->GetBlock();
    const intptr_t place_id = GetPlaceId(phi);

    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ZoneGrowableArray<Definition*>* pred_out_values =
          out_values_[pred->preorder_number()];
      ASSERT((*pred_out_values)[place_id] != nullptr);

      // Sets of outgoing values are not linked into use lists so
      // they might contain values that were replaced and removed
      // from the graph by this iteration.
      // To prevent using them we additionally mark definitions themselves
      // as replaced and store a pointer to the replacement.
      Definition* replacement = (*pred_out_values)[place_id]->Replacement();
      Value* input = new (Z) Value(replacement);
      phi->SetInputAt(i, input);
      replacement->AddInputUse(input);
      // If any input is untagged, then the Phi should be marked as untagged.
      if (replacement->representation() == kUntagged) {
        phi->set_representation(kUntagged);
      }
    }

    graph_->AllocateSSAIndex(phi);
    phis_.Add(phi);  // Postpone phi insertion until after load forwarding.

    if (FLAG_support_il_printer && FLAG_trace_load_optimization &&
        graph_->should_print()) {
      THR_Print("created pending phi %s for %s at B%" Pd "\n", phi->ToCString(),
                aliased_set_->places()[place_id]->ToCString(),
                block->block_id());
    }
  }

  // Iterate over basic blocks and replace exposed loads with incoming
  // values.
  void ForwardLoads() {
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();

      ZoneGrowableArray<Definition*>* loads =
          exposed_values_[block->preorder_number()];
      if (loads == nullptr) continue;  // No exposed loads.

      BitVector* in = in_[block->preorder_number()];

      for (intptr_t i = 0; i < loads->length(); i++) {
        Definition* load = (*loads)[i];
        if (!in->Contains(GetPlaceId(load))) continue;  // No incoming value.

        Definition* replacement = MergeIncomingValues(block, GetPlaceId(load));
        ASSERT(replacement != nullptr);

        // Sets of outgoing values are not linked into use lists so
        // they might contain values that were replaced and removed
        // from the graph by this iteration.
        // To prevent using them we additionally mark definitions themselves
        // as replaced and store a pointer to the replacement.
        replacement = replacement->Replacement();

        if ((load != replacement) && CanForwardLoadTo(load, replacement)) {
          graph_->EnsureSSATempIndex(load, replacement);

          if (FLAG_trace_optimization && graph_->should_print()) {
            THR_Print("Replacing load v%" Pd " with v%" Pd "\n",
                      load->ssa_temp_index(), replacement->ssa_temp_index());
          }

          replacement = ReplaceLoad(load, replacement);
          load->RemoveFromGraph();
          load->SetReplacement(replacement);
          forwarded_ = true;
        }
      }
    }
  }

  // Check if the given phi take the same value on all code paths.
  // Eliminate it as redundant if this is the case.
  // When analyzing phi operands assumes that only generated during
  // this load phase can be redundant. They can be distinguished because
  // they are not marked alive.
  // TODO(vegorov): move this into a separate phase over all phis.
  bool EliminateRedundantPhi(PhiInstr* phi) {
    Definition* value = nullptr;  // Possible value of this phi.

    worklist_.Clear();
    if (in_worklist_ == nullptr) {
      in_worklist_ = new (Z) BitVector(Z, graph_->current_ssa_temp_index());
    } else {
      in_worklist_->Clear();
    }

    worklist_.Add(phi);
    in_worklist_->Add(phi->ssa_temp_index());

    for (intptr_t i = 0; i < worklist_.length(); i++) {
      PhiInstr* phi = worklist_[i];

      for (intptr_t i = 0; i < phi->InputCount(); i++) {
        Definition* input = phi->InputAt(i)->definition();
        if (input == phi) continue;

        PhiInstr* phi_input = input->AsPhi();
        if ((phi_input != nullptr) && !phi_input->is_alive()) {
          if (!in_worklist_->Contains(phi_input->ssa_temp_index())) {
            worklist_.Add(phi_input);
            in_worklist_->Add(phi_input->ssa_temp_index());
          }
          continue;
        }

        if (value == nullptr) {
          value = input;
        } else if (value != input) {
          return false;  // This phi is not redundant.
        }
      }
    }

    // All phis in the worklist are redundant and have the same computed
    // value on all code paths.
    ASSERT(value != nullptr);
    for (intptr_t i = 0; i < worklist_.length(); i++) {
      worklist_[i]->ReplaceUsesWith(value);
    }

    return true;
  }

  // Returns true if definitions are congruent assuming their inputs
  // are congruent.
  bool CanBeCongruent(Definition* a, Definition* b) {
    return (a->tag() == b->tag()) &&
           ((a->IsPhi() && (a->GetBlock() == b->GetBlock())) ||
            (a->AllowsCSE() && a->AttributesEqual(*b)));
  }

  // Given two definitions check if they are congruent under assumption that
  // their inputs will be proven congruent. If they are - add them to the
  // worklist to check their inputs' congruency.
  // Returns true if pair was added to the worklist or is already in the
  // worklist and false if a and b are not congruent.
  bool AddPairToCongruencyWorklist(Definition* a, Definition* b) {
    if (!CanBeCongruent(a, b)) {
      return false;
    }

    // If a is already in the worklist check if it is being compared to b.
    // Give up if it is not.
    if (in_worklist_->Contains(a->ssa_temp_index())) {
      for (intptr_t i = 0; i < congruency_worklist_.length(); i += 2) {
        if (a == congruency_worklist_[i]) {
          return (b == congruency_worklist_[i + 1]);
        }
      }
      UNREACHABLE();
    } else if (in_worklist_->Contains(b->ssa_temp_index())) {
      return AddPairToCongruencyWorklist(b, a);
    }

    congruency_worklist_.Add(a);
    congruency_worklist_.Add(b);
    in_worklist_->Add(a->ssa_temp_index());
    return true;
  }

  bool AreInputsCongruent(Definition* a, Definition* b) {
    ASSERT(a->tag() == b->tag());
    ASSERT(a->InputCount() == b->InputCount());
    for (intptr_t j = 0; j < a->InputCount(); j++) {
      Definition* inputA = a->InputAt(j)->definition();
      Definition* inputB = b->InputAt(j)->definition();

      if (inputA != inputB) {
        if (!AddPairToCongruencyWorklist(inputA, inputB)) {
          return false;
        }
      }
    }
    return true;
  }

  // Returns true if instruction dom dominates instruction other.
  static bool Dominates(Instruction* dom, Instruction* other) {
    BlockEntryInstr* dom_block = dom->GetBlock();
    BlockEntryInstr* other_block = other->GetBlock();

    if (dom_block == other_block) {
      for (Instruction* current = dom->next(); current != nullptr;
           current = current->next()) {
        if (current == other) {
          return true;
        }
      }
      return false;
    }

    return dom_block->Dominates(other_block);
  }

  // Replace the given phi with another if they are congruent.
  // Returns true if succeeds.
  bool ReplacePhiWith(PhiInstr* phi, PhiInstr* replacement) {
    ASSERT(phi->InputCount() == replacement->InputCount());
    ASSERT(phi->block() == replacement->block());

    congruency_worklist_.Clear();
    if (in_worklist_ == nullptr) {
      in_worklist_ = new (Z) BitVector(Z, graph_->current_ssa_temp_index());
    } else {
      in_worklist_->Clear();
    }

    // During the comparison worklist contains pairs of definitions to be
    // compared.
    if (!AddPairToCongruencyWorklist(phi, replacement)) {
      return false;
    }

    // Process the worklist. It might grow during each comparison step.
    for (intptr_t i = 0; i < congruency_worklist_.length(); i += 2) {
      if (!AreInputsCongruent(congruency_worklist_[i],
                              congruency_worklist_[i + 1])) {
        return false;
      }
    }

    // At this point worklist contains pairs of congruent definitions.
    // Replace the one member of the pair with another maintaining proper
    // domination relation between definitions and uses.
    for (intptr_t i = 0; i < congruency_worklist_.length(); i += 2) {
      Definition* a = congruency_worklist_[i];
      Definition* b = congruency_worklist_[i + 1];

      // If these definitions are not phis then we need to pick up one
      // that dominates another as the replacement: if a dominates b swap them.
      // Note: both a and b are used as a phi input at the same block B which
      // means a dominates B and b dominates B, which guarantees that either
      // a dominates b or b dominates a.
      if (!a->IsPhi()) {
        if (Dominates(a, b)) {
          Definition* t = a;
          a = b;
          b = t;
        }
        ASSERT(Dominates(b, a));
      }

      if (FLAG_support_il_printer && FLAG_trace_load_optimization &&
          graph_->should_print()) {
        THR_Print("Replacing %s with congruent %s\n", a->ToCString(),
                  b->ToCString());
      }

      a->ReplaceUsesWith(b);
      if (a->IsPhi()) {
        // We might be replacing a phi introduced by the load forwarding
        // that is not inserted in the graph yet.
        ASSERT(b->IsPhi());
        PhiInstr* phi_a = a->AsPhi();
        if (phi_a->is_alive()) {
          phi_a->mark_dead();
          phi_a->block()->RemovePhi(phi_a);
          phi_a->UnuseAllInputs();
        }
      } else {
        a->RemoveFromGraph();
      }
    }

    return true;
  }

  // Insert the given phi into the graph. Attempt to find an equal one in the
  // target block first.
  // Returns true if the phi was inserted and false if it was replaced.
  bool EmitPhi(PhiInstr* phi) {
    for (PhiIterator it(phi->block()); !it.Done(); it.Advance()) {
      if (ReplacePhiWith(phi, it.Current())) {
        return false;
      }
    }

    phi->mark_alive();
    phi->block()->InsertPhi(phi);
    return true;
  }

  // Phis have not yet been inserted into the graph but they have uses of
  // their inputs.  Insert the non-redundant ones and clear the input uses
  // of the redundant ones.
  void EmitPhis() {
    // First eliminate all redundant phis.
    for (intptr_t i = 0; i < phis_.length(); i++) {
      PhiInstr* phi = phis_[i];
      if (!phi->HasUses() || EliminateRedundantPhi(phi)) {
        phi->UnuseAllInputs();
        phis_[i] = nullptr;
      }
    }

    // Now emit phis or replace them with equal phis already present in the
    // graph.
    for (intptr_t i = 0; i < phis_.length(); i++) {
      PhiInstr* phi = phis_[i];
      if ((phi != nullptr) && (!phi->HasUses() || !EmitPhi(phi))) {
        phi->UnuseAllInputs();
      }
    }
  }

  ZoneGrowableArray<Definition*>* CreateBlockOutValues() {
    ZoneGrowableArray<Definition*>* out =
        new (Z) ZoneGrowableArray<Definition*>(aliased_set_->max_place_id());
    for (intptr_t i = 0; i < aliased_set_->max_place_id(); i++) {
      out->Add(nullptr);
    }
    return out;
  }

  FlowGraph* graph_;
  PointerSet<Place>* map_;

  // Mapping between field offsets in words and expression ids of loads from
  // that offset.
  AliasedSet* aliased_set_;

  // Per block sets of expression ids for loads that are: incoming (available
  // on the entry), outgoing (available on the exit), generated and killed.
  GrowableArray<BitVector*> in_;
  GrowableArray<BitVector*> out_;
  GrowableArray<BitVector*> gen_;
  GrowableArray<BitVector*> kill_;

  // Per block list of upwards exposed loads.
  GrowableArray<ZoneGrowableArray<Definition*>*> exposed_values_;

  // Per block mappings between expression ids and outgoing definitions that
  // represent those ids.
  GrowableArray<ZoneGrowableArray<Definition*>*> out_values_;

  // List of phis generated during ComputeOutValues and ForwardLoads.
  // Some of these phis might be redundant and thus a separate pass is
  // needed to emit only non-redundant ones.
  GrowableArray<PhiInstr*> phis_;

  // Auxiliary worklist used by redundant phi elimination.
  GrowableArray<PhiInstr*> worklist_;
  GrowableArray<Definition*> congruency_worklist_;
  BitVector* in_worklist_;

  // True if any load was eliminated.
  bool forwarded_;

  DISALLOW_COPY_AND_ASSIGN(LoadOptimizer);
};

bool DominatorBasedCSE::Optimize(FlowGraph* graph,
                                 bool run_load_optimization /* = true */) {
  bool changed = false;
  if (FLAG_load_cse && run_load_optimization) {
    changed = LoadOptimizer::OptimizeGraph(graph) || changed;
  }

  CSEInstructionSet map;
  changed = OptimizeRecursive(graph, graph->graph_entry(), &map) || changed;

  return changed;
}

bool DominatorBasedCSE::OptimizeRecursive(FlowGraph* graph,
                                          BlockEntryInstr* block,
                                          CSEInstructionSet* map) {
  bool changed = false;
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    if (current->AllowsCSE()) {
      Instruction* replacement = map->Lookup(current);

      if (replacement != nullptr) {
        // Replace current with lookup result.
        ASSERT(replacement->AllowsCSE());
        graph->ReplaceCurrentInstruction(&it, current, replacement);
        changed = true;
        continue;
      }

      map->Insert(current);
    }
  }

  // Process children in the dominator tree recursively.
  intptr_t num_children = block->dominated_blocks().length();
  if (num_children != 0) {
    graph->thread()->CheckForSafepoint();
  }
  for (intptr_t i = 0; i < num_children; ++i) {
    BlockEntryInstr* child = block->dominated_blocks()[i];
    if (i < num_children - 1) {
      // Copy map.
      CSEInstructionSet child_map(*map);
      changed = OptimizeRecursive(graph, child, &child_map) || changed;
    } else {
      // Reuse map for the last child.
      changed = OptimizeRecursive(graph, child, map) || changed;
    }
  }
  return changed;
}

class StoreOptimizer : public LivenessAnalysis {
 public:
  StoreOptimizer(FlowGraph* graph,
                 AliasedSet* aliased_set,
                 PointerSet<Place>* map)
      : LivenessAnalysis(graph, aliased_set->max_place_id()),
        graph_(graph),
        map_(map),
        aliased_set_(aliased_set),
        exposed_stores_(graph_->postorder().length()) {
    const intptr_t num_blocks = graph_->postorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      exposed_stores_.Add(nullptr);
    }
  }

  static void OptimizeGraph(FlowGraph* graph) {
    ASSERT(FLAG_load_cse);

    // For now, bail out for large functions to avoid OOM situations.
    // TODO(fschneider): Fix the memory consumption issue.
    if (graph->is_huge_method()) {
      return;
    }

    PointerSet<Place> map;
    AliasedSet* aliased_set = NumberPlaces(graph, &map, kOptimizeStores);
    if ((aliased_set != nullptr) && !aliased_set->IsEmpty()) {
      StoreOptimizer store_optimizer(graph, aliased_set, &map);
      store_optimizer.Optimize();
    }
  }

 private:
  void Optimize() {
    Analyze();
    if (FLAG_trace_load_optimization && graph_->should_print()) {
      Dump();
    }
    EliminateDeadStores();
  }

  bool CanEliminateStore(Instruction* instr) {
    if (instr->IsThrow()) {
      // Throw stores into Error.stackTrace field
      return false;
    }
    if (CompilerState::Current().is_aot()) {
      // Tracking initializing stores is important for proper shared boxes
      // initialization, which doesn't happen in AOT and for
      // LowerContextAllocation optimization which creates unitialized objects
      // which is also JIT-only currently.
      return true;
    }
    switch (instr->tag()) {
      case Instruction::kStoreField: {
        StoreFieldInstr* store_instance = instr->AsStoreField();
        // Can't eliminate stores that initialize fields.
        return !store_instance->is_initialization();
      }
      case Instruction::kStoreIndexed:
      case Instruction::kStoreStaticField:
        return true;
      default:
        UNREACHABLE();
        return false;
    }
  }

  virtual void ComputeInitialSets() {
    Zone* zone = graph_->zone();
    BitVector* all_places =
        new (zone) BitVector(zone, aliased_set_->max_place_id());
    all_places->SetAll();

    BitVector* all_aliased_places = nullptr;
    if (CompilerState::Current().is_aot()) {
      all_aliased_places =
          new (zone) BitVector(zone, aliased_set_->max_place_id());
    }
    const auto& places = aliased_set_->places();
    for (intptr_t i = 0; i < places.length(); i++) {
      Place* place = places[i];
      if (place->DependsOnInstance()) {
        Definition* instance = place->instance();
        // Find escaping places by inspecting definition allocation
        // [AliasIdentity] field, which is populated above by
        // [AliasedSet::ComputeAliasing].
        if ((all_aliased_places != nullptr) &&
            (!Place::IsAllocation(instance) ||
             instance->Identity().IsAliased())) {
          all_aliased_places->Add(i);
        }
        if (instance != nullptr) {
          // Avoid incorrect propagation of "dead" state beyond definition
          // of the instance. Otherwise it may eventually reach stores into
          // this place via loop backedge.
          live_in_[instance->GetBlock()->postorder_number()]->Add(i);
        }
      } else {
        if (all_aliased_places != nullptr) {
          all_aliased_places->Add(i);
        }
      }
      if (place->kind() == Place::kIndexed) {
        Definition* index = place->index();
        if (index != nullptr) {
          // Avoid incorrect propagation of "dead" state beyond definition
          // of the index. Otherwise it may eventually reach stores into
          // this place via loop backedge.
          live_in_[index->GetBlock()->postorder_number()]->Add(i);
        }
      }
    }

    for (BlockIterator block_it = graph_->postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t postorder_number = block->postorder_number();

      BitVector* kill = kill_[postorder_number];
      BitVector* live_in = live_in_[postorder_number];
      BitVector* live_out = live_out_[postorder_number];

      ZoneGrowableArray<Instruction*>* exposed_stores = nullptr;

      // Iterate backwards starting at the last instruction.
      for (BackwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        bool is_load = false;
        bool is_store = false;
        Place place(graph_, instr, &is_load, &is_store);
        if (place.IsImmutableField()) {
          // Loads/stores of final fields do not participate.
          continue;
        }

        // Handle stores.
        if (is_store && !instr->IsThrow()) {
          if (kill->Contains(GetPlaceId(instr))) {
            if (!live_in->Contains(GetPlaceId(instr)) &&
                CanEliminateStore(instr)) {
              if (FLAG_trace_optimization && graph_->should_print()) {
                THR_Print("Removing dead store to place %" Pd " in block B%" Pd
                          "\n",
                          GetPlaceId(instr), block->block_id());
              }
              instr_it.RemoveCurrentFromGraph();
            }
          } else if (!live_in->Contains(GetPlaceId(instr))) {
            // Mark this store as down-ward exposed: They are the only
            // candidates for the global store elimination.
            if (exposed_stores == nullptr) {
              const intptr_t kMaxExposedStoresInitialSize = 5;
              exposed_stores = new (zone) ZoneGrowableArray<Instruction*>(
                  Utils::Minimum(kMaxExposedStoresInitialSize,
                                 aliased_set_->max_place_id()));
            }
            exposed_stores->Add(instr);
          }
          // Interfering stores kill only loads from the same place.
          kill->Add(GetPlaceId(instr));
          live_in->Remove(GetPlaceId(instr));
          continue;
        }

        if (instr->IsThrow() || instr->IsReThrow() || instr->IsReturnBase()) {
          // Initialize live-out for exit blocks since it won't be computed
          // otherwise during the fixed point iteration.
          live_out->CopyFrom(all_places);
        }

        // Handle side effects, deoptimization and function return.
        if (CompilerState::Current().is_aot()) {
          if (instr->HasUnknownSideEffects() || instr->IsReturnBase()) {
            // An instruction that returns or has unknown side effects
            // is treated as if it loads from all places.
            live_in->CopyFrom(all_places);
            continue;
          } else if (instr->MayThrow()) {
            if (block->try_index() == kInvalidTryIndex) {
              // Outside of a try-catch block, an instruction that may throw
              // is only treated as if it loads from escaping places.
              live_in->AddAll(all_aliased_places);
            } else {
              // Inside of a try-catch block, an instruction that may throw
              // is treated as if it loads from all places.
              live_in->CopyFrom(all_places);
            }
            continue;
          }
        } else {  // jit
          // Similar optimization to the above could be implemented in JIT
          // as long as deoptimization side-effects are taken into account.
          // Conceptually variables in deoptimization environment for
          // "MayThrow" instructions have to be also added to the
          // [live_in] set as they can be considered as escaping (to
          // unoptimized code). However those deoptimization environment
          // variables include also non-escaping(not aliased) ones, so
          // how to deal with that needs to be figured out.
          if (instr->HasUnknownSideEffects() || instr->CanDeoptimize() ||
              instr->MayThrow() || instr->IsReturnBase()) {
            // Instructions that return from the function, instructions with
            // side effects and instructions that can deoptimize are considered
            // as loads from all places.
            live_in->CopyFrom(all_places);
            continue;
          }
        }

        // Handle loads.
        Definition* defn = instr->AsDefinition();
        if ((defn != nullptr) && IsLoadEliminationCandidate(defn)) {
          const intptr_t alias = aliased_set_->LookupAliasId(place.ToAlias());
          live_in->AddAll(aliased_set_->GetKilledSet(alias));
          continue;
        }
      }
      exposed_stores_[postorder_number] = exposed_stores;
    }
    if (FLAG_trace_load_optimization && graph_->should_print()) {
      Dump();
      THR_Print("---\n");
    }
  }

  void EliminateDeadStores() {
    // Iteration order does not matter here.
    for (BlockIterator block_it = graph_->postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t postorder_number = block->postorder_number();

      BitVector* live_out = live_out_[postorder_number];

      ZoneGrowableArray<Instruction*>* exposed_stores =
          exposed_stores_[postorder_number];
      if (exposed_stores == nullptr) continue;  // No exposed stores.

      // Iterate over candidate stores.
      for (intptr_t i = 0; i < exposed_stores->length(); ++i) {
        Instruction* instr = (*exposed_stores)[i];
        bool is_load = false;
        bool is_store = false;
        Place place(graph_, instr, &is_load, &is_store);
        ASSERT(!is_load && is_store);
        if (place.IsImmutableField()) {
          // Final field do not participate in dead store elimination.
          continue;
        }
        // Eliminate a downward exposed store if the corresponding place is not
        // in live-out.
        if (!live_out->Contains(GetPlaceId(instr)) &&
            CanEliminateStore(instr)) {
          if (FLAG_trace_optimization && graph_->should_print()) {
            THR_Print("Removing dead store to place %" Pd " block B%" Pd "\n",
                      GetPlaceId(instr), block->block_id());
          }
          instr->RemoveFromGraph(/* ignored */ false);
        }
      }
    }
  }

  FlowGraph* graph_;
  PointerSet<Place>* map_;

  // Mapping between field offsets in words and expression ids of loads from
  // that offset.
  AliasedSet* aliased_set_;

  // Per block list of downward exposed stores.
  GrowableArray<ZoneGrowableArray<Instruction*>*> exposed_stores_;

  DISALLOW_COPY_AND_ASSIGN(StoreOptimizer);
};

void DeadStoreElimination::Optimize(FlowGraph* graph) {
  if (FLAG_dead_store_elimination && FLAG_load_cse) {
    StoreOptimizer::OptimizeGraph(graph);
  }
}

//
// Allocation Sinking
//

static bool IsValidLengthForAllocationSinking(
    ArrayAllocationInstr* array_alloc) {
  const intptr_t kMaxAllocationSinkingNumElements = 32;
  if (!array_alloc->HasConstantNumElements()) {
    return false;
  }
  const intptr_t length = array_alloc->GetConstantNumElements();
  return (length >= 0) && (length <= kMaxAllocationSinkingNumElements);
}

// Returns true if the given instruction is an allocation that
// can be sunk by the Allocation Sinking pass.
static bool IsSupportedAllocation(Instruction* instr) {
  return instr->IsAllocation() &&
         (!instr->IsArrayAllocation() ||
          IsValidLengthForAllocationSinking(instr->AsArrayAllocation()));
}

// Check if the use is safe for allocation sinking. Allocation sinking
// candidates can only be used as inputs to store and allocation instructions:
//
//     - any store into the allocation candidate itself is unconditionally safe
//       as it just changes the rematerialization state of this candidate;
//     - store into another object is only safe if the other object is
//       an allocation candidate.
//     - use as input to another allocation is only safe if the other allocation
//       is a candidate.
//
// We use a simple fix-point algorithm to discover the set of valid candidates
// (see CollectCandidates method), that's why this IsSafeUse can operate in two
// modes:
//
//     - optimistic, when every allocation is assumed to be an allocation
//       sinking candidate;
//     - strict, when only marked allocations are assumed to be allocation
//       sinking candidates.
//
// Fix-point algorithm in CollectCandidates first collects a set of allocations
// optimistically and then checks each collected candidate strictly and unmarks
// invalid candidates transitively until only strictly valid ones remain.
bool AllocationSinking::IsSafeUse(Value* use, SafeUseCheck check_type) {
  ASSERT(IsSupportedAllocation(use->definition()));

  if (use->instruction()->IsMaterializeObject()) {
    return true;
  }

  if (auto* const alloc = use->instruction()->AsAllocation()) {
    return IsSupportedAllocation(alloc) &&
           ((check_type == kOptimisticCheck) ||
            alloc->Identity().IsAllocationSinkingCandidate());
  }

  if (auto* store = use->instruction()->AsStoreField()) {
    if (use == store->value()) {
      Definition* instance = store->instance()->definition();
      return IsSupportedAllocation(instance) &&
             ((check_type == kOptimisticCheck) ||
              instance->Identity().IsAllocationSinkingCandidate());
    }
    return true;
  }

  if (auto* store = use->instruction()->AsStoreIndexed()) {
    if (use == store->index()) {
      return false;
    }
    if (use == store->array()) {
      if (!store->index()->BindsToSmiConstant()) {
        return false;
      }
      const intptr_t index = store->index()->BoundSmiConstant();
      if (index < 0 || index >= use->definition()
                                    ->AsArrayAllocation()
                                    ->GetConstantNumElements()) {
        return false;
      }
      if (auto* alloc_typed_data = use->definition()->AsAllocateTypedData()) {
        if (store->class_id() != alloc_typed_data->class_id() ||
            !store->aligned() ||
            store->index_scale() != compiler::target::Instance::ElementSizeFor(
                                        alloc_typed_data->class_id())) {
          return false;
        }
      }
    }
    if (use == store->value()) {
      Definition* instance = store->array()->definition();
      return IsSupportedAllocation(instance) &&
             ((check_type == kOptimisticCheck) ||
              instance->Identity().IsAllocationSinkingCandidate());
    }
    return true;
  }

  return false;
}

// Right now we are attempting to sink allocation only into
// deoptimization exit. So candidate should only be used in StoreField
// instructions that write into fields of the allocated object.
bool AllocationSinking::IsAllocationSinkingCandidate(Definition* alloc,
                                                     SafeUseCheck check_type) {
  for (Value* use = alloc->input_use_list(); use != nullptr;
       use = use->next_use()) {
    if (!IsSafeUse(use, check_type)) {
      if (FLAG_support_il_printer && FLAG_trace_optimization &&
          flow_graph_->should_print()) {
        THR_Print("use of %s at %s is unsafe for allocation sinking\n",
                  alloc->ToCString(), use->instruction()->ToCString());
      }
      return false;
    }
  }

  return true;
}

// If the given use is a store into an object then return an object we are
// storing into.
static Definition* StoreDestination(Value* use) {
  if (auto* const alloc = use->instruction()->AsAllocation()) {
    return alloc;
  }
  if (auto* const store = use->instruction()->AsStoreField()) {
    return store->instance()->definition();
  }
  if (auto* const store = use->instruction()->AsStoreIndexed()) {
    return store->array()->definition();
  }
  return nullptr;
}

// If the given instruction is a load from an object, then return an object
// we are loading from.
static Definition* LoadSource(Definition* instr) {
  if (auto load = instr->AsLoadField()) {
    return load->instance()->definition();
  }
  if (auto load = instr->AsLoadIndexed()) {
    return load->array()->definition();
  }
  return nullptr;
}

// Remove the given allocation from the graph. It is not observable.
// If deoptimization occurs the object will be materialized.
void AllocationSinking::EliminateAllocation(Definition* alloc) {
  ASSERT(IsAllocationSinkingCandidate(alloc, kStrictCheck));

  if (FLAG_trace_optimization && flow_graph_->should_print()) {
    THR_Print("removing allocation from the graph: v%" Pd "\n",
              alloc->ssa_temp_index());
  }

  // As an allocation sinking candidate, remove stores to this candidate.
  // Do this in a two-step process, as this allocation may be used multiple
  // times in a single instruction (e.g., as the instance and the value in
  // a StoreField). This means multiple entries may be removed from the
  // use list when removing instructions, not just the current one, so
  // Value::Iterator cannot be safely used.
  GrowableArray<Instruction*> stores_to_remove;
  for (Value* use = alloc->input_use_list(); use != nullptr;
       use = use->next_use()) {
    Instruction* const instr = use->instruction();
    Definition* const instance = StoreDestination(use);
    // All uses of a candidate should be stores or other allocations.
    ASSERT(instance != nullptr);
    if (instance == alloc) {
      // An allocation instruction cannot be a direct input to itself.
      ASSERT(!instr->IsAllocation());
      stores_to_remove.Add(instr);
    } else {
      // The candidate is being stored into another candidate, either through
      // a store instruction or as the input to a to-be-eliminated allocation,
      // so this instruction will be removed with the other candidate.
      ASSERT(candidates_.Contains(instance));
    }
  }

  for (auto* const store : stores_to_remove) {
    // Avoid calling RemoveFromGraph() more than once on the same instruction.
    if (store->previous() != nullptr) {
      store->RemoveFromGraph();
    }
  }

// There should be no environment uses. The pass replaced them with
// MaterializeObject instructions.
#ifdef DEBUG
  for (Value* use = alloc->env_use_list(); use != nullptr;
       use = use->next_use()) {
    ASSERT(use->instruction()->IsMaterializeObject());
  }
#endif

  alloc->RemoveFromGraph();
}

// Find allocation instructions that can be potentially eliminated and
// rematerialized at deoptimization exits if needed. See IsSafeUse
// for the description of algorithm used below.
void AllocationSinking::CollectCandidates() {
  // Optimistically collect all potential candidates.
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (!IsSupportedAllocation(current)) {
        continue;
      }

      Definition* alloc = current->Cast<Definition>();
      if (IsAllocationSinkingCandidate(alloc, kOptimisticCheck)) {
        alloc->SetIdentity(AliasIdentity::AllocationSinkingCandidate());
        candidates_.Add(alloc);
      }
    }
  }

  // Transitively unmark all candidates that are not strictly valid.
  bool changed;
  do {
    changed = false;
    for (intptr_t i = 0; i < candidates_.length(); i++) {
      Definition* alloc = candidates_[i];
      if (alloc->Identity().IsAllocationSinkingCandidate()) {
        if (!IsAllocationSinkingCandidate(alloc, kStrictCheck)) {
          alloc->SetIdentity(AliasIdentity::Unknown());
          changed = true;
        }
      }
    }
  } while (changed);

  // Shrink the list of candidates removing all unmarked ones.
  intptr_t j = 0;
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    Definition* alloc = candidates_[i];
    if (alloc->Identity().IsAllocationSinkingCandidate()) {
      if (FLAG_trace_optimization && flow_graph_->should_print()) {
        THR_Print("discovered allocation sinking candidate: v%" Pd "\n",
                  alloc->ssa_temp_index());
      }

      if (j != i) {
        candidates_[j] = alloc;
      }
      j++;
    }
  }
  candidates_.TruncateTo(j);
}

// If materialization references an allocation sinking candidate then replace
// this reference with a materialization which should have been computed for
// this side-exit. CollectAllExits should have collected this exit.
void AllocationSinking::NormalizeMaterializations() {
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    Definition* alloc = candidates_[i];

    Value* next_use;
    for (Value* use = alloc->input_use_list(); use != nullptr; use = next_use) {
      next_use = use->next_use();
      if (use->instruction()->IsMaterializeObject()) {
        use->BindTo(MaterializationFor(alloc, use->instruction()));
      }
    }
  }
}

// We transitively insert materializations at each deoptimization exit that
// might see the given allocation (see ExitsCollector). Some of these
// materializations are not actually used and some fail to compute because
// they are inserted in the block that is not dominated by the allocation.
// Remove unused materializations from the graph.
void AllocationSinking::RemoveUnusedMaterializations() {
  intptr_t j = 0;
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    MaterializeObjectInstr* mat = materializations_[i];
    if ((mat->input_use_list() == nullptr) &&
        (mat->env_use_list() == nullptr)) {
      // Check if this materialization failed to compute and remove any
      // unforwarded loads. There were no loads from any allocation sinking
      // candidate in the beginning so it is safe to assume that any encountered
      // load was inserted by CreateMaterializationAt.
      for (intptr_t i = 0; i < mat->InputCount(); i++) {
        Definition* load = mat->InputAt(i)->definition();
        if (LoadSource(load) == mat->allocation()) {
          load->ReplaceUsesWith(flow_graph_->constant_null());
          load->RemoveFromGraph();
        }
      }
      mat->RemoveFromGraph();
    } else {
      if (j != i) {
        materializations_[j] = mat;
      }
      j++;
    }
  }
  materializations_.TruncateTo(j);
}

// Some candidates might stop being eligible for allocation sinking after
// the load forwarding because they flow into phis that load forwarding
// inserts. Discover such allocations and remove them from the list
// of allocation sinking candidates undoing all changes that we did
// in preparation for sinking these allocations.
void AllocationSinking::DiscoverFailedCandidates() {
  // Transitively unmark all candidates that are not strictly valid.
  bool changed;
  do {
    changed = false;
    for (intptr_t i = 0; i < candidates_.length(); i++) {
      Definition* alloc = candidates_[i];
      if (alloc->Identity().IsAllocationSinkingCandidate()) {
        if (!IsAllocationSinkingCandidate(alloc, kStrictCheck)) {
          alloc->SetIdentity(AliasIdentity::Unknown());
          changed = true;
        }
      }
    }
  } while (changed);

  // Remove all failed candidates from the candidates list.
  intptr_t j = 0;
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    Definition* alloc = candidates_[i];
    if (!alloc->Identity().IsAllocationSinkingCandidate()) {
      if (FLAG_trace_optimization && flow_graph_->should_print()) {
        THR_Print("allocation v%" Pd " can't be eliminated\n",
                  alloc->ssa_temp_index());
      }

#ifdef DEBUG
      for (Value* use = alloc->env_use_list(); use != nullptr;
           use = use->next_use()) {
        ASSERT(use->instruction()->IsMaterializeObject());
      }
#endif

      // All materializations will be removed from the graph. Remove inserted
      // loads first and detach materializations from allocation's environment
      // use list: we will reconstruct it when we start removing
      // materializations.
      alloc->set_env_use_list(nullptr);
      for (Value* use = alloc->input_use_list(); use != nullptr;
           use = use->next_use()) {
        if (use->instruction()->IsLoadField() ||
            use->instruction()->IsLoadIndexed()) {
          Definition* load = use->instruction()->AsDefinition();
          load->ReplaceUsesWith(flow_graph_->constant_null());
          load->RemoveFromGraph();
        } else {
          ASSERT(use->instruction()->IsMaterializeObject() ||
                 use->instruction()->IsPhi() ||
                 use->instruction()->IsStoreField() ||
                 use->instruction()->IsStoreIndexed());
        }
      }
    } else {
      if (j != i) {
        candidates_[j] = alloc;
      }
      j++;
    }
  }

  if (j != candidates_.length()) {  // Something was removed from candidates.
    intptr_t k = 0;
    for (intptr_t i = 0; i < materializations_.length(); i++) {
      MaterializeObjectInstr* mat = materializations_[i];
      if (!mat->allocation()->Identity().IsAllocationSinkingCandidate()) {
        // Restore environment uses of the allocation that were replaced
        // by this materialization and drop materialization.
        mat->ReplaceUsesWith(mat->allocation());
        mat->RemoveFromGraph();
      } else {
        if (k != i) {
          materializations_[k] = mat;
        }
        k++;
      }
    }
    materializations_.TruncateTo(k);
  }

  candidates_.TruncateTo(j);
}

void AllocationSinking::Optimize() {
  // Allocation sinking depends on load forwarding, so give up early if load
  // forwarding is disabled.
  if (!FLAG_load_cse || flow_graph_->is_huge_method()) {
    return;
  }

  CollectCandidates();

  // Insert MaterializeObject instructions that will describe the state of the
  // object at all deoptimization points. Each inserted materialization looks
  // like this (where v_0 is allocation that we are going to eliminate):
  //   v_1     <- LoadField(v_0, field_1)
  //           ...
  //   v_N     <- LoadField(v_0, field_N)
  //   v_{N+1} <- MaterializeObject(field_1 = v_1, ..., field_N = v_N)
  //
  // For typed data objects materialization looks like this:
  //   v_1     <- LoadIndexed(v_0, index_1)
  //           ...
  //   v_N     <- LoadIndexed(v_0, index_N)
  //   v_{N+1} <- MaterializeObject([index_1] = v_1, ..., [index_N] = v_N)
  //
  // For arrays materialization looks like this:
  //   v_1     <- LoadIndexed(v_0, index_1)
  //           ...
  //   v_N     <- LoadIndexed(v_0, index_N)
  //   v_{N+1} <- LoadField(v_0, Array.type_arguments)
  //   v_{N+2} <- MaterializeObject([index_1] = v_1, ..., [index_N] = v_N,
  //                                type_arguments = v_{N+1})
  //
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    InsertMaterializations(candidates_[i]);
  }

  // Run load forwarding to eliminate LoadField/LoadIndexed instructions
  // inserted above.
  //
  // All loads will be successfully eliminated because:
  //   a) they use fields/constant indices and thus provide precise aliasing
  //      information
  //   b) candidate does not escape and thus its fields/elements are not
  //      affected by external effects from calls.
  LoadOptimizer::OptimizeGraph(flow_graph_);

  NormalizeMaterializations();

  RemoveUnusedMaterializations();

  // If any candidates are no longer eligible for allocation sinking abort
  // the optimization for them and undo any changes we did in preparation.
  DiscoverFailedCandidates();

  // At this point we have computed the state of object at each deoptimization
  // point and we can eliminate it. Loads inserted above were forwarded so there
  // are no uses of the allocation outside other candidates to eliminate, just
  // as in the beginning of the pass.
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    EliminateAllocation(candidates_[i]);
  }

  // Process materializations and unbox their arguments: materializations
  // are part of the environment and can materialize boxes for double/mint/simd
  // values when needed.
  // TODO(vegorov): handle all box types here.
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    MaterializeObjectInstr* mat = materializations_[i];
    for (intptr_t j = 0; j < mat->InputCount(); j++) {
      Definition* defn = mat->InputAt(j)->definition();
      if (defn->IsBox()) {
        mat->InputAt(j)->BindTo(defn->InputAt(0)->definition());
      }
    }
  }
}

// Remove materializations from the graph. Register allocator will treat them
// as part of the environment not as a real instruction.
void AllocationSinking::DetachMaterializations() {
  for (MaterializeObjectInstr* mat : materializations_) {
    mat->previous()->LinkTo(mat->next());
    mat->set_next(nullptr);
    mat->set_previous(nullptr);
  }
}

// Add a field/offset to the list of fields if it is not yet present there.
static void AddSlot(ZoneGrowableArray<const Slot*>* slots, const Slot& slot) {
  if (!slots->Contains(&slot)) {
    slots->Add(&slot);
  }
}

// Find deoptimization exit for the given materialization assuming that all
// materializations are emitted right before the instruction which is a
// deoptimization exit.
static Instruction* ExitForMaterialization(MaterializeObjectInstr* mat) {
  while (mat->next()->IsMaterializeObject()) {
    mat = mat->next()->AsMaterializeObject();
  }
  return mat->next();
}

// Given the deoptimization exit find first materialization that was inserted
// before it.
static Instruction* FirstMaterializationAt(Instruction* exit) {
  while (exit->previous()->IsMaterializeObject()) {
    exit = exit->previous();
  }
  return exit;
}

// Given the allocation and deoptimization exit try to find MaterializeObject
// instruction corresponding to this allocation at this exit.
MaterializeObjectInstr* AllocationSinking::MaterializationFor(
    Definition* alloc,
    Instruction* exit) {
  if (exit->IsMaterializeObject()) {
    exit = ExitForMaterialization(exit->AsMaterializeObject());
  }

  for (MaterializeObjectInstr* mat = exit->previous()->AsMaterializeObject();
       mat != nullptr; mat = mat->previous()->AsMaterializeObject()) {
    if (mat->allocation() == alloc) {
      return mat;
    }
  }

  return nullptr;
}

static InnerPointerAccess AccessForSlotInAllocatedObject(Definition* alloc,
                                                         const Slot& slot) {
  if (slot.representation() != kUntagged) {
    return InnerPointerAccess::kNotUntagged;
  }
  if (!slot.may_contain_inner_pointer()) {
    return InnerPointerAccess::kCannotBeInnerPointer;
  }
  if (slot.IsIdentical(Slot::PointerBase_data())) {
    // The data field of external arrays is not unsafe, as it never contains
    // a GC-movable address.
    if (alloc->IsAllocateObject() &&
        IsExternalPayloadClassId(alloc->AsAllocateObject()->cls().id())) {
      return InnerPointerAccess::kCannotBeInnerPointer;
    }
  }
  return InnerPointerAccess::kMayBeInnerPointer;
}

// Insert MaterializeObject instruction for the given allocation before
// the given instruction that can deoptimize.
void AllocationSinking::CreateMaterializationAt(
    Instruction* exit,
    Definition* alloc,
    const ZoneGrowableArray<const Slot*>& slots) {
  InputsArray values(slots.length());

  // All loads should be inserted before the first materialization so that
  // IR follows the following pattern: loads, materializations, deoptimizing
  // instruction.
  Instruction* load_point = FirstMaterializationAt(exit);

  // Insert load instruction for every field and element.
  for (auto slot : slots) {
    Definition* load = nullptr;
    if (slot->IsArrayElement()) {
      intptr_t array_cid, index;
      if (alloc->IsCreateArray()) {
        array_cid = kArrayCid;
        index =
            compiler::target::Array::index_at_offset(slot->offset_in_bytes());
      } else if (auto alloc_typed_data = alloc->AsAllocateTypedData()) {
        array_cid = alloc_typed_data->class_id();
        index = slot->offset_in_bytes() /
                compiler::target::Instance::ElementSizeFor(array_cid);
      } else {
        UNREACHABLE();
      }
      load = new (Z) LoadIndexedInstr(
          new (Z) Value(alloc),
          new (Z) Value(
              flow_graph_->GetConstant(Smi::ZoneHandle(Z, Smi::New(index)))),
          /*index_unboxed=*/false,
          /*index_scale=*/compiler::target::Instance::ElementSizeFor(array_cid),
          array_cid, kAlignedAccess, DeoptId::kNone, alloc->source());
    } else {
      InnerPointerAccess access = AccessForSlotInAllocatedObject(alloc, *slot);
      ASSERT(access != InnerPointerAccess::kMayBeInnerPointer);
      load = new (Z)
          LoadFieldInstr(new (Z) Value(alloc), *slot, access, alloc->source());
    }
    flow_graph_->InsertBefore(load_point, load, nullptr, FlowGraph::kValue);
    values.Add(new (Z) Value(load));
  }

  const Class* cls = nullptr;
  intptr_t length_or_shape = -1;
  if (auto instr = alloc->AsAllocateObject()) {
    cls = &(instr->cls());
  } else if (alloc->IsAllocateClosure()) {
    cls = &Class::ZoneHandle(
        flow_graph_->isolate_group()->object_store()->closure_class());
  } else if (auto instr = alloc->AsAllocateContext()) {
    cls = &Class::ZoneHandle(Object::context_class());
    length_or_shape = instr->num_context_variables();
  } else if (auto instr = alloc->AsAllocateUninitializedContext()) {
    cls = &Class::ZoneHandle(Object::context_class());
    length_or_shape = instr->num_context_variables();
  } else if (auto instr = alloc->AsCreateArray()) {
    cls = &Class::ZoneHandle(
        flow_graph_->isolate_group()->object_store()->array_class());
    length_or_shape = instr->GetConstantNumElements();
  } else if (auto instr = alloc->AsAllocateTypedData()) {
    cls = &Class::ZoneHandle(
        flow_graph_->isolate_group()->class_table()->At(instr->class_id()));
    length_or_shape = instr->GetConstantNumElements();
  } else if (auto instr = alloc->AsAllocateRecord()) {
    cls = &Class::ZoneHandle(
        flow_graph_->isolate_group()->class_table()->At(kRecordCid));
    length_or_shape = instr->shape().AsInt();
  } else if (auto instr = alloc->AsAllocateSmallRecord()) {
    cls = &Class::ZoneHandle(
        flow_graph_->isolate_group()->class_table()->At(kRecordCid));
    length_or_shape = instr->shape().AsInt();
  } else {
    UNREACHABLE();
  }
  MaterializeObjectInstr* mat = new (Z) MaterializeObjectInstr(
      alloc->AsAllocation(), *cls, length_or_shape, slots, std::move(values));

  flow_graph_->InsertBefore(exit, mat, nullptr, FlowGraph::kValue);

  // Replace all mentions of this allocation with a newly inserted
  // MaterializeObject instruction.
  // We must preserve the identity: all mentions are replaced by the same
  // materialization.
  exit->ReplaceInEnvironment(alloc, mat);

  // Mark MaterializeObject as an environment use of this allocation.
  // This will allow us to discover it when we are looking for deoptimization
  // exits for another allocation that potentially flows into this one.
  Value* val = new (Z) Value(alloc);
  val->set_instruction(mat);
  alloc->AddEnvUse(val);

  // Record inserted materialization.
  materializations_.Add(mat);
}

// Add given instruction to the list of the instructions if it is not yet
// present there.
template <typename T>
void AddInstruction(GrowableArray<T*>* list, T* value) {
  ASSERT(!value->IsGraphEntry() && !value->IsFunctionEntry());
  for (intptr_t i = 0; i < list->length(); i++) {
    if ((*list)[i] == value) {
      return;
    }
  }
  list->Add(value);
}

// Transitively collect all deoptimization exits that might need this allocation
// rematerialized. It is not enough to collect only environment uses of this
// allocation because it can flow into other objects that will be
// dematerialized and that are referenced by deopt environments that
// don't contain this allocation explicitly.
void AllocationSinking::ExitsCollector::Collect(Definition* alloc) {
  for (Value* use = alloc->env_use_list(); use != nullptr;
       use = use->next_use()) {
    if (use->instruction()->IsMaterializeObject()) {
      AddInstruction(&exits_, ExitForMaterialization(
                                  use->instruction()->AsMaterializeObject()));
    } else {
      AddInstruction(&exits_, use->instruction());
    }
  }

  // Check if this allocation is stored into any other allocation sinking
  // candidate and put it on worklist so that we conservatively collect all
  // exits for that candidate as well because they potentially might see
  // this object.
  for (Value* use = alloc->input_use_list(); use != nullptr;
       use = use->next_use()) {
    Definition* obj = StoreDestination(use);
    if ((obj != nullptr) && (obj != alloc)) {
      AddInstruction(&worklist_, obj);
    }
  }
}

void AllocationSinking::ExitsCollector::CollectTransitively(Definition* alloc) {
  exits_.TruncateTo(0);
  worklist_.TruncateTo(0);

  worklist_.Add(alloc);

  // Note: worklist potentially will grow while we are iterating over it.
  // We are not removing allocations from the worklist not to waste space on
  // the side maintaining BitVector of already processed allocations: worklist
  // is expected to be very small thus linear search in it is just as efficient
  // as a bitvector.
  for (intptr_t i = 0; i < worklist_.length(); i++) {
    Collect(worklist_[i]);
  }
}

static bool IsDataFieldOfTypedDataView(Definition* alloc, const Slot& slot) {
  if (!slot.IsIdentical(Slot::PointerBase_data())) return false;
  // Internal typed data objects use AllocateTypedData.
  if (!alloc->IsAllocateObject()) return false;
  auto const cid = alloc->AsAllocateObject()->cls().id();
  return IsTypedDataViewClassId(cid) || IsUnmodifiableTypedDataViewClassId(cid);
}

void AllocationSinking::InsertMaterializations(Definition* alloc) {
  // Collect all fields and array elements that are written for this instance.
  auto slots = new (Z) ZoneGrowableArray<const Slot*>(5);

  for (Value* use = alloc->input_use_list(); use != nullptr;
       use = use->next_use()) {
    if (StoreDestination(use) == alloc) {
      // Allocation instructions cannot be used in as inputs to themselves.
      ASSERT(!use->instruction()->AsAllocation());
      if (auto store = use->instruction()->AsStoreField()) {
        // Only add the data field slot for external arrays. For views, it is
        // recomputed using the other fields in DeferredObject::Fill().
        if (!IsDataFieldOfTypedDataView(alloc, store->slot())) {
          AddSlot(slots, store->slot());
        }
      } else if (auto store = use->instruction()->AsStoreIndexed()) {
        const intptr_t index = store->index()->BoundSmiConstant();
        intptr_t offset = -1;
        if (alloc->IsCreateArray()) {
          offset = compiler::target::Array::element_offset(index);
        } else if (alloc->IsAllocateTypedData()) {
          offset = index * store->index_scale();
        } else {
          UNREACHABLE();
        }
        AddSlot(slots,
                Slot::GetArrayElementSlot(flow_graph_->thread(), offset));
      }
    }
  }

  if (auto* const allocation = alloc->AsAllocation()) {
    for (intptr_t pos = 0; pos < allocation->InputCount(); pos++) {
      if (auto* const slot = allocation->SlotForInput(pos)) {
        // Don't add slots for immutable length slots if not already added
        // above, as they are already represented as the number of elements in
        // the MaterializeObjectInstr.
        if (!slot->IsImmutableLengthSlot()) {
          AddSlot(slots, *slot);
        }
      }
    }
  }

  // Collect all instructions that mention this object in the environment.
  exits_collector_.CollectTransitively(alloc);

  // Insert materializations at environment uses.
  for (intptr_t i = 0; i < exits_collector_.exits().length(); i++) {
    CreateMaterializationAt(exits_collector_.exits()[i], alloc, *slots);
  }
}

// TryCatchAnalyzer tries to reduce the state that needs to be synchronized
// on entry to the catch by discovering Parameter-s which are never used
// or which are always constant.
//
// This analysis is similar to dead/redundant phi elimination because
// Parameter instructions serve as "implicit" phis.
class TryCatchAnalyzer : public ValueObject {
 public:
  explicit TryCatchAnalyzer(FlowGraph* flow_graph, bool is_aot)
      : flow_graph_(flow_graph),
        is_aot_(is_aot),
        // Initial capacity is selected based on trivial examples.
        worklist_(flow_graph, /*initial_capacity=*/10) {}

  // Run analysis and eliminate dead/redundant Parameter-s.
  void Optimize();

 private:
  // In precompiled mode we can eliminate all parameters that have no real uses
  // and subsequently clear out corresponding slots in the environments assigned
  // to instructions that can throw an exception which would be caught by
  // the corresponding CatchEntryBlock.
  //
  // Computing "dead" parameters is essentially a fixed point algorithm because
  // Parameter value can flow into another Parameter via an environment attached
  // to an instruction that can throw.
  //
  // Note: this optimization pass assumes that environment values are only
  // used during catching, that is why it should only be used in AOT mode.
  void OptimizeDeadParameters() {
    ASSERT(is_aot_);

    NumberCatchEntryParameters();
    ComputeIncomingValues();
    CollectAliveParametersOrPhis();
    PropagateLivenessToInputs();
    EliminateDeadParameters();
  }

  static intptr_t GetParameterId(const Instruction* instr) {
    return instr->GetPassSpecificId(CompilerPass::kTryCatchOptimization);
  }

  static void SetParameterId(Instruction* instr, intptr_t id) {
    instr->SetPassSpecificId(CompilerPass::kTryCatchOptimization, id);
  }

  static bool HasParameterId(Instruction* instr) {
    return instr->HasPassSpecificId(CompilerPass::kTryCatchOptimization);
  }

  // Assign sequential ids to each ParameterInstr in each CatchEntryBlock.
  // Collect reverse mapping from try indexes to corresponding catches.
  void NumberCatchEntryParameters() {
    for (TryEntryInstr* try_entry : flow_graph_->try_entries()) {
      if (try_entry == nullptr) {
        continue;
      }
      CatchBlockEntryInstr* const catch_entry = try_entry->catch_target();
      const GrowableArray<Definition*>& idefs =
          *catch_entry->initial_definitions();
      for (auto idef : idefs) {
        ParameterInstr* param = idef->AsParameter();
        ASSERT(param != nullptr);
        SetParameterId(param, parameter_info_.length());
        parameter_info_.Add(new ParameterInfo(param));
      }

      catch_by_index_.EnsureLength(catch_entry->catch_try_index() + 1, nullptr);
      catch_by_index_[catch_entry->catch_try_index()] = catch_entry;
    }
  }

  // Compute potential incoming values for each Parameter in each catch block
  // by looking into environments assigned to MayThrow instructions within
  // blocks covered by the corresponding catch.
  void ComputeIncomingValues() {
    for (auto block : flow_graph_->reverse_postorder()) {
      if (block->try_index() == kInvalidTryIndex) {
        continue;
      }

      ASSERT(block->try_index() < catch_by_index_.length());
      auto catch_entry = catch_by_index_[block->try_index()];
      const auto& idefs = *catch_entry->initial_definitions();

      for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* current = instr_it.Current();
        if (!current->MayThrow()) continue;

        Environment* env = current->env()->Outermost();
        ASSERT(env != nullptr);

        for (intptr_t i = 0; i < idefs.length(); ++i) {
          ParameterInstr* param = idefs[i]->AsParameter();
          ASSERT(param != nullptr);
          Definition* defn = env->ValueAt(param->env_index())->definition();

          // Add defn as an incoming value to the parameter if it is not
          // already present in the list.
          bool found = false;
          for (auto other_defn :
               parameter_info_[GetParameterId(param)]->incoming) {
            if (other_defn == defn) {
              found = true;
              break;
            }
          }
          if (!found) {
            parameter_info_[GetParameterId(param)]->incoming.Add(defn);
          }
        }
      }
    }
  }

  // Find all parameters (and phis) that are definitely alive - because they
  // have non-phi uses and place them into worklist.
  //
  // Note: phis that only have phi (and environment) uses would be marked as
  // dead.
  void CollectAliveParametersOrPhis() {
    for (auto block : flow_graph_->reverse_postorder()) {
      if (JoinEntryInstr* join = block->AsJoinEntry()) {
        if (join->phis() == nullptr) continue;

        for (auto phi : *join->phis()) {
          phi->mark_dead();
          if (HasActualUse(phi)) {
            MarkLive(phi);
          }
        }
      }
    }

    for (auto info : parameter_info_) {
      if (HasActualUse(info->instr)) {
        MarkLive(info->instr);
      }
    }
  }

  // Propagate liveness from live parameters and phis to other parameters and
  // phis transitively.
  void PropagateLivenessToInputs() {
    while (!worklist_.IsEmpty()) {
      Definition* defn = worklist_.RemoveLast();
      if (ParameterInstr* param = defn->AsParameter()) {
        auto s = parameter_info_[GetParameterId(param)];
        for (auto input : s->incoming) {
          MarkLive(input);
        }
      } else if (PhiInstr* phi = defn->AsPhi()) {
        for (intptr_t i = 0; i < phi->InputCount(); i++) {
          MarkLive(phi->InputAt(i)->definition());
        }
      }
    }
  }

  // Mark definition as live if it is a dead Phi or a dead Parameter and place
  // them into worklist.
  void MarkLive(Definition* defn) {
    if (PhiInstr* phi = defn->AsPhi()) {
      if (!phi->is_alive()) {
        phi->mark_alive();
        worklist_.Add(phi);
      }
    } else if (ParameterInstr* param = defn->AsParameter()) {
      if (HasParameterId(param)) {
        auto input_s = parameter_info_[GetParameterId(param)];
        if (!input_s->alive) {
          input_s->alive = true;
          worklist_.Add(param);
        }
      }
    } else if (UnboxInstr* unbox = defn->AsUnbox()) {
      MarkLive(unbox->value()->definition());
    }
  }

  // Replace all dead parameters with null value and clear corresponding
  // slots in environments.
  void EliminateDeadParameters() {
    for (auto info : parameter_info_) {
      if (!info->alive) {
        info->instr->ReplaceUsesWith(flow_graph_->constant_null());
      }
    }

    for (auto block : flow_graph_->reverse_postorder()) {
      if (block->try_index() == -1) continue;

      auto catch_entry = catch_by_index_[block->try_index()];
      const auto& idefs = *catch_entry->initial_definitions();

      for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* current = instr_it.Current();
        if (!current->MayThrow()) continue;

        Environment* env = current->env()->Outermost();
        RELEASE_ASSERT(env != nullptr);

        for (intptr_t i = 0; i < idefs.length(); ++i) {
          ParameterInstr* param = idefs[i]->AsParameter();
          ASSERT(param != nullptr);
          if (!parameter_info_[GetParameterId(param)]->alive) {
            env->ValueAt(param->env_index())
                ->BindToEnvironment(flow_graph_->constant_null());
          }
        }
      }
    }

    DeadCodeElimination::RemoveDeadAndRedundantPhisFromTheGraph(flow_graph_);
  }

  // Returns true if definition has a use in an instruction which is not a phi.
  // Skip over Unbox instructions which may be inserted for unused phis.
  static bool HasActualUse(Definition* defn) {
    for (Value* use = defn->input_use_list(); use != nullptr;
         use = use->next_use()) {
      Instruction* use_instruction = use->instruction();
      if (UnboxInstr* unbox = use_instruction->AsUnbox()) {
        if (HasActualUse(unbox)) {
          return true;
        }
      } else if (!use_instruction->IsPhi()) {
        return true;
      }
    }
    return false;
  }

  struct ParameterInfo : public ZoneAllocated {
    explicit ParameterInfo(ParameterInstr* instr) : instr(instr) {}

    ParameterInstr* instr;
    bool alive = false;
    GrowableArray<Definition*> incoming;
  };

  FlowGraph* const flow_graph_;
  const bool is_aot_;

  // Additional information for each Parameter from each CatchBlockEntry.
  // Parameter-s are numbered and their number is stored in
  // Instruction::place_id() field which is otherwise not used for anything
  // at this stage.
  GrowableArray<ParameterInfo*> parameter_info_;

  // Mapping from catch_try_index to corresponding CatchBlockEntry-s.
  GrowableArray<CatchBlockEntryInstr*> catch_by_index_;

  // Worklist for live Phi and Parameter instructions which need to be
  // processed by PropagateLivenessToInputs.
  DefinitionWorklist worklist_;
};

void OptimizeCatchEntryStates(FlowGraph* flow_graph, bool is_aot) {
  if (flow_graph->try_entries().is_empty()) {
    return;
  }

  TryCatchAnalyzer analyzer(flow_graph, is_aot);
  analyzer.Optimize();
}

void TryCatchAnalyzer::Optimize() {
  // Analyze catch entries and remove "dead" Parameter instructions.
  if (is_aot_) {
    OptimizeDeadParameters();
  }

  // If catch-block parameter always have the same value, no need to pass
  // it as a parameter. Instead replace that parameter with the value.
  // Only caveat is that the value should dominate the try-entry block - it
  // should exist before we enter try block, and therefor before we hit
  // first "MayThrow" instruction.
  //
  // Catch-block parameter values come from "MayThrow"-instructions in
  // the try-blocks with corresponding try-index.
  //
  for (auto try_entry : flow_graph_->try_entries()) {
    if (try_entry == nullptr) {
      // There might be gaps in try-indexes
      continue;
    }
    auto catch_entry = try_entry->catch_target();
    // Initialize env_cdefs with the original initial definitions.
    // The following representation is used:
    // ParameterInstr => unknown
    // Definition => Definition that is so far been the only
    //               one dominating def
    // nullptr => indication of mulitple Definitions
    GrowableArray<Definition*> env_idefs;
    for (intptr_t i = catch_entry->initial_definitions()->length() - 1; i >= 0;
         i--) {
      Definition* def = (*catch_entry->initial_definitions())[i];
      ParameterInstr* param = def->AsParameter();
      ASSERT(param != nullptr);
      env_idefs.EnsureLength(param->env_index() + 1, nullptr);
      env_idefs[param->env_index()] = def;
    }
    GrowableArray<Definition*> env_cdefs(env_idefs.length());
    env_cdefs.AddArray(env_idefs);

    // exception_var and stacktrace_var are always set inside catch block.
    env_cdefs[flow_graph_->EnvIndex(catch_entry->raw_exception_var())] =
        nullptr;
    env_cdefs[flow_graph_->EnvIndex(catch_entry->raw_stacktrace_var())] =
        nullptr;

    for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      if (block->try_index() == catch_entry->catch_try_index()) {
        for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
             instr_it.Advance()) {
          Instruction* current = instr_it.Current();
          if (current->MayThrow()) {
            Environment* env = current->env()->Outermost();
            ASSERT(env != nullptr);
            for (intptr_t env_idx = 0; env_idx < env_cdefs.length();
                 ++env_idx) {
              if (env_cdefs[env_idx] == nullptr) {
                // It is already known that this var has multiple definitions.
                continue;
              }
              Definition* existing_def = env_cdefs[env_idx];
              Definition* candidate_def = env->ValueAt(env_idx)->definition();
              if (existing_def == env_idefs[env_idx]) {
                // First definition.
                env_cdefs[env_idx] = candidate_def;
              } else {
                // We have encountered some definition already.
                if (candidate_def != existing_def) {
                  // Get rid of it if we see something different.
                  env_cdefs[env_idx] = nullptr;
                }
              }
            }
          }
        }
      }
    }
    GrowableArray<Definition*> updated_params;
    ASSERT(env_cdefs.length() == env_idefs.length());
    for (intptr_t i = 0; i < env_cdefs.length(); ++i) {
      Definition* new_def = env_cdefs[i];
      // The new definition must dominate the try entry to be considered
      // as an acceptable replacement.
      if (new_def != nullptr && !new_def->GetBlock()->Dominates(try_entry)) {
        new_def = nullptr;
      }
      Definition* old_def = env_idefs[i];
      if (new_def != nullptr && new_def != old_def) {
        ASSERT(old_def->IsParameter());
        old_def->ReplaceUsesWith(new_def);
      } else {
        if (old_def != nullptr) {
          updated_params.Add(old_def);
        }
      }
    }
    catch_entry->initial_definitions()->Clear();
    catch_entry->initial_definitions()->AddArray(updated_params);
  }
}

// Returns true iff this definition is used in a non-phi instruction.
static bool HasRealUse(Definition* def) {
  // Environment uses are real (non-phi) uses.
  if (def->env_use_list() != nullptr) return true;

  for (Value::Iterator it(def->input_use_list()); !it.Done(); it.Advance()) {
    if (!it.Current()->instruction()->IsPhi()) return true;
  }
  return false;
}

void DeadCodeElimination::EliminateDeadPhis(FlowGraph* flow_graph) {
  GrowableArray<PhiInstr*> live_phis;
  for (BlockIterator b = flow_graph->postorder_iterator(); !b.Done();
       b.Advance()) {
    JoinEntryInstr* join = b.Current()->AsJoinEntry();
    if (join != nullptr) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        // Phis that have uses and phis inside try blocks are
        // marked as live.
        if (HasRealUse(phi)) {
          live_phis.Add(phi);
          phi->mark_alive();
        } else {
          phi->mark_dead();
        }
      }
    }
  }

  while (!live_phis.is_empty()) {
    PhiInstr* phi = live_phis.RemoveLast();
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Value* val = phi->InputAt(i);
      PhiInstr* used_phi = val->definition()->AsPhi();
      if ((used_phi != nullptr) && !used_phi->is_alive()) {
        used_phi->mark_alive();
        live_phis.Add(used_phi);
      }
    }
  }

  RemoveDeadAndRedundantPhisFromTheGraph(flow_graph);
}

void DeadCodeElimination::RemoveDeadAndRedundantPhisFromTheGraph(
    FlowGraph* flow_graph) {
  for (auto block : flow_graph->postorder()) {
    if (JoinEntryInstr* join = block->AsJoinEntry()) {
      if (join->phis_ == nullptr) continue;

      // Eliminate dead phis and compact the phis_ array of the block.
      intptr_t to_index = 0;
      for (intptr_t i = 0; i < join->phis_->length(); ++i) {
        PhiInstr* phi = (*join->phis_)[i];
        if (phi != nullptr) {
          if (!phi->is_alive()) {
            phi->ReplaceUsesWith(flow_graph->constant_null());
            phi->UnuseAllInputs();
            (*join->phis_)[i] = nullptr;
            if (FLAG_trace_optimization && flow_graph->should_print()) {
              THR_Print("Removing dead phi v%" Pd "\n", phi->ssa_temp_index());
            }
          } else {
            (*join->phis_)[to_index++] = phi;
          }
        }
      }
      if (to_index == 0) {
        join->phis_ = nullptr;
      } else {
        join->phis_->TruncateTo(to_index);
      }
    }
  }
}

void DeadCodeElimination::EliminateDeadCode(FlowGraph* flow_graph) {
  GrowableArray<Instruction*> worklist;
  BitVector live(flow_graph->zone(), flow_graph->current_ssa_temp_index());

  // Mark all instructions with side-effects as live.
  for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      ASSERT(!current->IsMoveArgument());
      // TODO(alexmarkov): take control dependencies into account and
      // eliminate dead branches/conditions.
      if (!current->CanEliminate(block)) {
        worklist.Add(current);
        if (Definition* def = current->AsDefinition()) {
          if (def->HasSSATemp()) {
            live.Add(def->ssa_temp_index());
          }
        }
      }
    }
  }

  // Iteratively follow inputs of instructions in the work list.
  while (!worklist.is_empty()) {
    Instruction* current = worklist.RemoveLast();
    for (intptr_t i = 0, n = current->InputCount(); i < n; ++i) {
      Definition* input = current->InputAt(i)->definition();
      ASSERT(input->HasSSATemp());
      if (!live.Contains(input->ssa_temp_index())) {
        worklist.Add(input);
        live.Add(input->ssa_temp_index());
      }
    }
    for (intptr_t i = 0, n = current->ArgumentCount(); i < n; ++i) {
      Definition* input = current->ArgumentAt(i);
      ASSERT(input->HasSSATemp());
      if (!live.Contains(input->ssa_temp_index())) {
        worklist.Add(input);
        live.Add(input->ssa_temp_index());
      }
    }
    if (current->env() != nullptr) {
      for (Environment::DeepIterator it(current->env()); !it.Done();
           it.Advance()) {
        Definition* input = it.CurrentValue()->definition();
        ASSERT(!input->IsMoveArgument());
        if (input->HasSSATemp() && !live.Contains(input->ssa_temp_index())) {
          worklist.Add(input);
          live.Add(input->ssa_temp_index());
        }
      }
    }
  }

  // Remove all instructions which are not marked as live.
  for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    if (JoinEntryInstr* join = block->AsJoinEntry()) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* current = it.Current();
        if (!live.Contains(current->ssa_temp_index())) {
          it.RemoveCurrentFromGraph();
        }
      }
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (!current->CanEliminate(block)) {
        continue;
      }
      ASSERT(!current->IsMoveArgument());
      ASSERT((current->ArgumentCount() == 0) || !current->HasMoveArguments());
      if (Definition* def = current->AsDefinition()) {
        if (def->HasSSATemp() && live.Contains(def->ssa_temp_index())) {
          continue;
        }
      }
      it.RemoveCurrentFromGraph();
    }
  }
}

void CheckStackOverflowElimination::EliminateStackOverflow(FlowGraph* graph) {
  CheckStackOverflowInstr* first_stack_overflow_instr = nullptr;
  for (auto entry : graph->reverse_postorder()) {
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();

      if (CheckStackOverflowInstr* instr = current->AsCheckStackOverflow()) {
        if (first_stack_overflow_instr == nullptr) {
          first_stack_overflow_instr = instr;
          ASSERT(!first_stack_overflow_instr->in_loop());
        }
        continue;
      }

      if (current->IsBranch()) {
        current = current->AsBranch()->condition();
      }

      if (current->HasUnknownSideEffects()) {
        return;
      }
    }
  }

  if (first_stack_overflow_instr != nullptr) {
    first_stack_overflow_instr->RemoveFromGraph();
  }
}

}  // namespace dart
