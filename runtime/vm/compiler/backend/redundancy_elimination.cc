// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/redundancy_elimination.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/loops.h"
#include "vm/hash_map.h"
#include "vm/stack_frame.h"

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

class CSEInstructionMap : public ValueObject {
 public:
  CSEInstructionMap() : map_() {}
  explicit CSEInstructionMap(const CSEInstructionMap& other)
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
  typedef DirectChainedHashMap<PointerKeyValueTrait<Instruction> > Map;

  Map map_;
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
//     allows unanaligned access through it's get*/set* methods.
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

    // Instance field location. It is reprensented by a pair of instance
    // and a Slot.
    kInstanceField,

    // Indexed location with a non-constant index.
    kIndexed,

    // Indexed location with a constant index.
    kConstantIndexed,
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
    kInt8,

    // 2 bytes (Int16List, Uint16List).
    kInt16,

    // 4 bytes (Int32List, Uint32List, Float32List).
    kInt32,

    // 8 bytes (Int64List, Uint64List, Float64List).
    kInt64,

    // 16 bytes (Int32x4List, Float32x4List, Float64x2List).
    kInt128,

    kLargestElementSize = kInt128,
  };

  Place(const Place& other)
      : ValueObject(),
        flags_(other.flags_),
        instance_(other.instance_),
        raw_selector_(other.raw_selector_),
        id_(other.id_) {}

  // Construct a place from instruction if instruction accesses any place.
  // Otherwise constructs kNone place.
  Place(Instruction* instr, bool* is_load, bool* is_store)
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

      case Instruction::kStoreInstanceField: {
        StoreInstanceFieldInstr* store = instr->AsStoreInstanceField();
        set_representation(store->RequiredInputRepresentation(
            StoreInstanceFieldInstr::kValuePos));
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
        set_representation(load_indexed->representation());
        instance_ = load_indexed->array()->definition()->OriginalDefinition();
        SetIndex(load_indexed->index()->definition()->OriginalDefinition(),
                 load_indexed->index_scale(), load_indexed->class_id());
        *is_load = true;
        break;
      }

      case Instruction::kStoreIndexed: {
        StoreIndexedInstr* store_indexed = instr->AsStoreIndexed();
        set_representation(store_indexed->RequiredInputRepresentation(
            StoreIndexedInstr::kValuePos));
        instance_ = store_indexed->array()->definition()->OriginalDefinition();
        SetIndex(store_indexed->index()->definition()->OriginalDefinition(),
                 store_indexed->index_scale(), store_indexed->class_id());
        *is_store = true;
        break;
      }

      default:
        break;
    }
  }

  bool IsConstant(Object* value) const {
    switch (kind()) {
      case kInstanceField:
        return (instance() != nullptr) && instance()->IsConstant() &&
               LoadFieldInstr::TryEvaluateLoad(
                   instance()->AsConstant()->constant_value(), instance_field(),
                   value);
      default:
        return false;
    }
  }

  // Create object representing *[*] alias.
  static Place* CreateAnyInstanceAnyIndexAlias(Zone* zone, intptr_t id) {
    return Wrap(
        zone, Place(EncodeFlags(kIndexed, kNoRepresentation, kNoSize), NULL, 0),
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
  //      respectively;
  //    - for non-constant indexed places X[i] we drop information about the
  //      index obtaining alias X[*].
  //    - we drop information about representation, but keep element size
  //      if any.
  //
  Place ToAlias() const {
    return Place(
        RepresentationBits::update(kNoRepresentation, flags_),
        (DependsOnInstance() && IsAllocation(instance())) ? instance() : NULL,
        (kind() == kIndexed) ? 0 : raw_selector_);
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
    return Place(flags_, NULL, raw_selector_);
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
  // For example for X[9|kInt8] and target size kInt32 we would return
  // X[8|kInt32].
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
  // For example X[8|kInt32] contains inside X[8|kInt16] (index is 0) and
  // X[10|kInt16] (index is 1).
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
    if (def == NULL) {
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
      case kStaticField:
        return static_field().is_final() && !FLAG_fields_may_be_reset;
      default:
        return false;
    }
  }

  intptr_t Hashcode() const {
    return (flags_ * 63 + reinterpret_cast<intptr_t>(instance_)) * 31 +
           FieldHashcode();
  }

  bool Equals(const Place* other) const {
    return (flags_ == other->flags_) && (instance_ == other->instance_) &&
           SameField(other);
  }

  // Create a zone allocated copy of this place and assign given id to it.
  static Place* Wrap(Zone* zone, const Place& place, intptr_t id);

  static bool IsAllocation(Definition* defn) {
    return (defn != NULL) &&
           (defn->IsAllocateObject() || defn->IsCreateArray() ||
            defn->IsAllocateUninitializedContext() ||
            (defn->IsStaticCall() &&
             defn->AsStaticCall()->IsRecognizedFactory()));
  }

 private:
  Place(uword flags, Definition* instance, intptr_t selector)
      : flags_(flags), instance_(instance), raw_selector_(selector), id_(0) {}

  bool SameField(const Place* other) const {
    return (kind() == kStaticField)
               ? (static_field().Original() == other->static_field().Original())
               : (raw_selector_ == other->raw_selector_);
  }

  intptr_t FieldHashcode() const {
    return (kind() == kStaticField)
               ? String::Handle(Field::Handle(static_field().Original()).name())
                     .Hash()
               : raw_selector_;
  }

  void set_representation(Representation rep) {
    flags_ = RepresentationBits::update(rep, flags_);
  }

  void set_kind(Kind kind) { flags_ = KindBits::update(kind, flags_); }

  void set_element_size(ElementSize scale) {
    flags_ = ElementSizeBits::update(scale, flags_);
  }

  void SetIndex(Definition* index, intptr_t scale, intptr_t class_id) {
    ConstantInstr* index_constant = index->AsConstant();
    if ((index_constant != NULL) && index_constant->value().IsSmi()) {
      const intptr_t index_value = Smi::Cast(index_constant->value()).Value();
      const ElementSize size = ElementSizeFor(class_id);
      const bool is_typed_access = (size != kNoSize);
      // Indexing into [RawTypedDataView]/[RawExternalTypedData happens via a
      // untagged load of the `_data` field (which points to C memory).
      //
      // Indexing into dart:ffi's [RawPointer] happens via loading of the
      // `c_memory_address_`, converting it to an integer, doing some arithmetic
      // and finally using IntConverterInstr to convert to a untagged
      // representation.
      //
      // In both cases the array used for load/store has untagged
      // representation.
      const bool can_be_view = instance_->representation() == kUntagged;

      // If we are writing into the typed data scale the index to
      // get byte offset. Otherwise ignore the scale.
      if (!is_typed_access) {
        scale = 1;
      }

      // Guard against potential multiplication overflow and negative indices.
      if ((0 <= index_value) && (index_value < (kMaxInt32 / scale))) {
        const intptr_t scaled_index = index_value * scale;

        // Guard against unaligned byte offsets and access through raw
        // memory pointer (which can be pointing into another typed data).
        if (!is_typed_access ||
            (!can_be_view &&
             Utils::IsAligned(scaled_index, ElementSizeMultiplier(size)))) {
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

  static ElementSize ElementSizeFor(intptr_t class_id) {
    switch (class_id) {
      case kArrayCid:
      case kImmutableArrayCid:
      case kOneByteStringCid:
      case kTwoByteStringCid:
      case kExternalOneByteStringCid:
      case kExternalTwoByteStringCid:
        // Object arrays and strings do not allow accessing them through
        // different types. No need to attach scale.
        return kNoSize;

      case kTypedDataInt8ArrayCid:
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
        return kInt8;

      case kTypedDataInt16ArrayCid:
      case kTypedDataUint16ArrayCid:
        return kInt16;

      case kTypedDataInt32ArrayCid:
      case kTypedDataUint32ArrayCid:
      case kTypedDataFloat32ArrayCid:
        return kInt32;

      case kTypedDataInt64ArrayCid:
      case kTypedDataUint64ArrayCid:
      case kTypedDataFloat64ArrayCid:
        return kInt64;

      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
      case kTypedDataFloat64x2ArrayCid:
        return kInt128;

      default:
        UNREACHABLE();
        return kNoSize;
    }
  }

  static intptr_t ElementSizeMultiplier(ElementSize size) {
    return 1 << (static_cast<intptr_t>(size) - static_cast<intptr_t>(kInt8));
  }

  static intptr_t RoundByteOffset(ElementSize size, intptr_t offset) {
    return offset & ~(ElementSizeMultiplier(size) - 1);
  }

  static intptr_t ByteOffsetToSmallerElement(ElementSize size,
                                             intptr_t index,
                                             intptr_t base_offset) {
    return base_offset + index * ElementSizeMultiplier(size);
  }

  class KindBits : public BitField<uword, Kind, 0, 3> {};
  class RepresentationBits
      : public BitField<uword, Representation, KindBits::kNextBit, 11> {};
  class ElementSizeBits
      : public BitField<uword, ElementSize, RepresentationBits::kNextBit, 3> {};

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
    return (block_num < moves_.length()) ? moves_[block_num] : NULL;
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
             DirectChainedHashMap<PointerKeyValueTrait<Place> >* places_map,
             ZoneGrowableArray<Place*>* places,
             PhiPlaceMoves* phi_moves)
      : zone_(zone),
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
    return (result != NULL) ? result->id() : static_cast<intptr_t>(kNoAlias);
  }

  BitVector* GetKilledSet(intptr_t alias) {
    return (alias < killed_.length()) ? killed_[alias] : NULL;
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

  void RollbackAliasedIdentites() {
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

        if (alias->instance() == NULL) {
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

    if (FLAG_trace_load_optimization) {
      THR_Print("Aliases KILL sets:\n");
      for (intptr_t i = 0; i < aliases_.length(); ++i) {
        const Place* alias = aliases_[i];
        BitVector* kill = GetKilledSet(alias->id());

        THR_Print("%s: ", alias->ToCString());
        if (kill != NULL) {
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
    if (canonical == NULL) {
      canonical = Place::Wrap(zone_, alias,
                              kAnyInstanceAnyIndexAlias + aliases_.length());
      InsertAlias(canonical);
    }
    ASSERT(aliases_map_.LookupValue(&alias) == canonical);
    return canonical;
  }

  BitVector* GetRepresentativesSet(intptr_t alias) {
    return (alias < representatives_.length()) ? representatives_[alias] : NULL;
  }

  BitVector* EnsureSet(GrowableArray<BitVector*>* sets, intptr_t alias) {
    while (sets->length() <= alias) {
      sets->Add(NULL);
    }

    BitVector* set = (*sets)[alias];
    if (set == NULL) {
      (*sets)[alias] = set = new (zone_) BitVector(zone_, max_place_id());
    }
    return set;
  }

  void AddAllRepresentatives(const Place* to, intptr_t from) {
    AddAllRepresentatives(to->id(), from);
  }

  void AddAllRepresentatives(intptr_t to, intptr_t from) {
    BitVector* from_set = GetRepresentativesSet(from);
    if (from_set != NULL) {
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
  // representatives into more generic alias'es kill set. For example
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
        if (alias->instance() == NULL) {
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
              (alias->instance() != NULL) && CanBeAliased(alias->instance());

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
            for (intptr_t i = Place::kInt8; i <= Place::kLargestElementSize;
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

        if (alias->instance() == NULL) {
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

    return (place->kind() == Place::kInstanceField) &&
           !CanBeAliased(place->instance());
  }

  // Returns true if there are direct loads from the given place.
  bool HasLoadsFromPlace(Definition* defn, const Place* place) {
    ASSERT(place->kind() == Place::kInstanceField);

    for (Value* use = defn->input_use_list(); use != NULL;
         use = use->next_use()) {
      Instruction* instr = use->instruction();
      if (UseIsARedefinition(use) &&
          HasLoadsFromPlace(instr->Cast<Definition>(), place)) {
        return true;
      }
      bool is_load = false, is_store;
      Place load_place(instr, &is_load, &is_store);

      if (is_load && load_place.Equals(place)) {
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
    for (Value* use = defn->input_use_list(); use != NULL;
         use = use->next_use()) {
      Instruction* instr = use->instruction();
      if (instr->HasUnknownSideEffects() || instr->IsLoadUntagged() ||
          (instr->IsStoreIndexed() &&
           (use->use_index() == StoreIndexedInstr::kValuePos)) ||
          instr->IsStoreStaticField() || instr->IsPhi()) {
        return true;
      } else if (UseIsARedefinition(use) &&
                 AnyUseCreatesAlias(instr->Cast<Definition>())) {
        return true;
      } else if ((instr->IsStoreInstanceField() &&
                  (use->use_index() !=
                   StoreInstanceFieldInstr::kInstancePos))) {
        ASSERT(use->use_index() == StoreInstanceFieldInstr::kValuePos);
        // If we store this value into an object that is not aliased itself
        // and we never load again then the store does not create an alias.
        StoreInstanceFieldInstr* store = instr->AsStoreInstanceField();
        Definition* instance =
            store->instance()->definition()->OriginalDefinition();
        if (Place::IsAllocation(instance) &&
            !instance->Identity().IsAliased()) {
          bool is_load, is_store;
          Place store_place(instr, &is_load, &is_store);

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
    }
    return false;
  }

  // Mark any value stored into the given object as potentially aliased.
  void MarkStoredValuesEscaping(Definition* defn) {
    // Find all stores into this object.
    for (Value* use = defn->input_use_list(); use != NULL;
         use = use->next_use()) {
      auto instr = use->instruction();
      if (UseIsARedefinition(use)) {
        MarkStoredValuesEscaping(instr->AsDefinition());
        continue;
      }
      if ((use->use_index() == StoreInstanceFieldInstr::kInstancePos) &&
          instr->IsStoreInstanceField()) {
        StoreInstanceFieldInstr* store = instr->AsStoreInstanceField();
        Definition* value = store->value()->definition()->OriginalDefinition();
        if (value->Identity().IsNotAliased()) {
          value->SetIdentity(AliasIdentity::Aliased());
          identity_rollback_.Add(value);

          // Add to worklist to propagate the mark transitively.
          aliasing_worklist_.Add(value);
        }
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

  DirectChainedHashMap<PointerKeyValueTrait<Place> >* places_map_;

  const ZoneGrowableArray<Place*>& places_;

  const PhiPlaceMoves* phi_moves_;

  // A list of all seen aliases and a map that allows looking up canonical
  // alias object.
  GrowableArray<const Place*> aliases_;
  DirectChainedHashMap<PointerKeyValueTrait<const Place> > aliases_map_;

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

  StoreInstanceFieldInstr* store_instance_field = instr->AsStoreInstanceField();
  if (store_instance_field != NULL) {
    return store_instance_field->value()->definition();
  }

  StoreStaticFieldInstr* store_static_field = instr->AsStoreStaticField();
  if (store_static_field != NULL) {
    return store_static_field->value()->definition();
  }

  UNREACHABLE();  // Should only be called for supported store instructions.
  return NULL;
}

static bool IsPhiDependentPlace(Place* place) {
  return (place->kind() == Place::kInstanceField) &&
         (place->instance() != NULL) && place->instance()->IsPhi();
}

// For each place that depends on a phi ensure that equivalent places
// corresponding to phi input are numbered and record outgoing phi moves
// for each block which establish correspondence between phi dependent place
// and phi input's place that is flowing in.
static PhiPlaceMoves* ComputePhiMoves(
    DirectChainedHashMap<PointerKeyValueTrait<Place> >* map,
    ZoneGrowableArray<Place*>* places) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  PhiPlaceMoves* phi_moves = new (zone) PhiPlaceMoves();

  for (intptr_t i = 0; i < places->length(); i++) {
    Place* place = (*places)[i];

    if (IsPhiDependentPlace(place)) {
      PhiInstr* phi = place->instance()->AsPhi();
      BlockEntryInstr* block = phi->GetBlock();

      if (FLAG_trace_optimization) {
        THR_Print("phi dependent place %s\n", place->ToCString());
      }

      Place input_place(*place);
      for (intptr_t j = 0; j < phi->InputCount(); j++) {
        input_place.set_instance(phi->InputAt(j)->definition());

        Place* result = map->LookupValue(&input_place);
        if (result == NULL) {
          result = Place::Wrap(zone, input_place, places->length());
          map->Insert(result);
          places->Add(result);
          if (FLAG_trace_optimization) {
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

static AliasedSet* NumberPlaces(
    FlowGraph* graph,
    DirectChainedHashMap<PointerKeyValueTrait<Place> >* map,
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
      Place place(instr, &has_loads, &has_stores);
      if (place.kind() == Place::kNone) {
        continue;
      }

      Place* result = map->LookupValue(&place);
      if (result == NULL) {
        result = Place::Wrap(zone, place, places->length());
        map->Insert(result);
        places->Add(result);

        if (FLAG_trace_optimization) {
          THR_Print("numbering %s as %" Pd "\n", result->ToCString(),
                    result->id());
        }
      }

      SetPlaceId(instr, result->id());
    }
  }

  if ((mode == kOptimizeLoads) && !has_loads) {
    return NULL;
  }
  if ((mode == kOptimizeStores) && !has_stores) {
    return NULL;
  }

  PhiPlaceMoves* phi_moves = ComputePhiMoves(map, places);

  // Build aliasing sets mapping aliases to loads.
  return new (zone) AliasedSet(zone, map, places, phi_moves);
}

// Load instructions handled by load elimination.
static bool IsLoadEliminationCandidate(Instruction* instr) {
  return instr->IsLoadField() || instr->IsLoadIndexed() ||
         instr->IsLoadStaticField();
}

static bool IsLoopInvariantLoad(ZoneGrowableArray<BitVector*>* sets,
                                intptr_t loop_header_index,
                                Instruction* instr) {
  return IsLoadEliminationCandidate(instr) && (sets != NULL) &&
         HasPlaceId(instr) &&
         (*sets)[loop_header_index]->Contains(GetPlaceId(instr));
}

LICM::LICM(FlowGraph* flow_graph) : flow_graph_(flow_graph) {
  ASSERT(flow_graph->is_licm_allowed());
}

void LICM::Hoist(ForwardInstructionIterator* it,
                 BlockEntryInstr* pre_header,
                 Instruction* current) {
  if (current->IsCheckClass()) {
    current->AsCheckClass()->set_licm_hoisted(true);
  } else if (current->IsCheckSmi()) {
    current->AsCheckSmi()->set_licm_hoisted(true);
  } else if (current->IsCheckEitherNonSmi()) {
    current->AsCheckEitherNonSmi()->set_licm_hoisted(true);
  } else if (current->IsCheckArrayBound()) {
    ASSERT(!CompilerState::Current().is_aot());  // speculative in JIT only
    current->AsCheckArrayBound()->set_licm_hoisted(true);
  } else if (current->IsGenericCheckBound()) {
    ASSERT(CompilerState::Current().is_aot());  // non-speculative in AOT only
    // Does not deopt, so no need for licm_hoisted flag.
  } else if (current->IsTestCids()) {
    current->AsTestCids()->set_licm_hoisted(true);
  }
  if (FLAG_trace_optimization) {
    THR_Print("Hoisting instruction %s:%" Pd " from B%" Pd " to B%" Pd "\n",
              current->DebugName(), current->GetDeoptId(),
              current->GetBlock()->block_id(), pre_header->block_id());
  }
  // Move the instruction out of the loop.
  current->RemoveEnvironment();
  if (it != NULL) {
    it->RemoveCurrentFromGraph();
  } else {
    current->RemoveFromGraph();
  }
  GotoInstr* last = pre_header->last_instruction()->AsGoto();
  // Using kind kEffect will not assign a fresh ssa temporary index.
  flow_graph()->InsertBefore(last, current, last->env(), FlowGraph::kEffect);
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

  CheckSmiInstr* check = NULL;
  for (Value* use = phi->input_use_list(); (use != NULL) && (check == NULL);
       use = use->next_use()) {
    check = use->instruction()->AsCheckSmi();
  }

  if (check == NULL) {
    return;
  }

  // Host CheckSmi instruction and make this phi smi one.
  Hoist(NULL, pre_header, check);

  // Replace value we are checking with phi's input.
  check->value()->BindTo(phi->InputAt(non_smi_input)->definition());
  check->value()->SetReachingType(phi->InputAt(non_smi_input)->Type());

  phi->UpdateType(CompileType::FromCid(kSmiCid));
}

void LICM::OptimisticallySpecializeSmiPhis() {
  if (flow_graph()->function().ProhibitsHoistingCheckClass() ||
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
    if (pre_header == NULL) continue;

    for (PhiIterator it(header); !it.Done(); it.Advance()) {
      TrySpecializeSmiPhi(it.Current(), header, pre_header);
    }
  }
}

// Returns true if instruction may have a "visible" effect,
static bool MayHaveVisibleEffect(Instruction* instr) {
  switch (instr->tag()) {
    case Instruction::kStoreInstanceField:
    case Instruction::kStoreStaticField:
    case Instruction::kStoreIndexed:
    case Instruction::kStoreIndexedUnsafe:
    case Instruction::kStoreUntagged:
      return true;
    default:
      return instr->HasUnknownSideEffects() || instr->MayThrow();
  }
}

void LICM::Optimize() {
  if (flow_graph()->function().ProhibitsHoistingCheckClass()) {
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
          if (load->AllowsCSE() && !load->IsFieldInitialized()) {
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
            (!seen_visible_effect || !current->MayThrow())) {
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
        } else if (!seen_visible_effect && MayHaveVisibleEffect(current)) {
          seen_visible_effect = true;
        }
      }
    }
  }
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
        in_worklist_(NULL),
        forwarded_(false) {
    const intptr_t num_blocks = graph_->preorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      out_.Add(NULL);
      gen_.Add(new (Z) BitVector(Z, aliased_set_->max_place_id()));
      kill_.Add(new (Z) BitVector(Z, aliased_set_->max_place_id()));
      in_.Add(new (Z) BitVector(Z, aliased_set_->max_place_id()));

      exposed_values_.Add(NULL);
      out_values_.Add(NULL);
    }
  }

  ~LoadOptimizer() { aliased_set_->RollbackAliasedIdentites(); }

  Isolate* isolate() const { return graph_->isolate(); }
  Zone* zone() const { return graph_->zone(); }

  static bool OptimizeGraph(FlowGraph* graph) {
    ASSERT(FLAG_load_cse);

    // For now, bail out for large functions to avoid OOM situations.
    // TODO(fschneider): Fix the memory consumption issue.
    intptr_t function_length = graph->function().end_token_pos().Pos() -
                               graph->function().token_pos().Pos();
    if (function_length >= FLAG_huge_method_cutoff_in_tokens) {
      return false;
    }

    DirectChainedHashMap<PointerKeyValueTrait<Place> > map;
    AliasedSet* aliased_set = NumberPlaces(graph, &map, kOptimizeLoads);
    if ((aliased_set != NULL) && !aliased_set->IsEmpty()) {
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
      load_field->set_calls_initializer(false);
    } else if (auto* load_static = instr->AsLoadStaticField()) {
      load_static->set_calls_initializer(false);
    } else {
      UNREACHABLE();
    }
  }

  // Returns true if given instruction stores the sentinel value.
  // Such a store doesn't initialize corresponding field.
  bool IsSentinelStore(Instruction* instr) {
    Value* value = nullptr;
    if (auto* store_field = instr->AsStoreInstanceField()) {
      value = store_field->value();
    } else if (auto* store_static = instr->AsStoreStaticField()) {
      value = store_static->value();
    }
    return value != nullptr && value->BindsToConstant() &&
           (value->BoundConstant().raw() == Object::sentinel().raw());
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
    // figure out if there are lazy intializer calls left to optimize.
    bool has_lazy_initializer_calls = false;
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      BitVector* gen = gen_[block->preorder_number()];

      for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        bool is_load = false, is_store = false;
        Place place(instr, &is_load, &is_store);

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
    return ((array_store == nullptr) ||
            (array_store->class_id() == kArrayCid) ||
            (array_store->class_id() == kTypedDataFloat64ArrayCid) ||
            (array_store->class_id() == kTypedDataFloat32ArrayCid) ||
            (array_store->class_id() == kTypedDataFloat32x4ArrayCid));
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

      ZoneGrowableArray<Definition*>* exposed_values = NULL;
      ZoneGrowableArray<Definition*>* out_values = NULL;

      for (ForwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        bool is_load = false, is_store = false;
        Place place(instr, &is_load, &is_store);

        BitVector* killed = NULL;
        if (is_store) {
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
                  if (FLAG_trace_optimization) {
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
          if ((canonical != NULL) &&
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
        if (defn == NULL) {
          continue;
        }

        // For object allocation forward initial values of the fields to
        // subsequent loads (and potential dead stores) except for final
        // fields of escaping objects. Final fields are initialized in
        // constructor which potentially was not inlined into the function
        // that we are currently optimizing. However at the same time we
        // assume that values of the final fields can be forwarded across
        // side-effects. If we add 'null' as known values for these fields
        // here we will incorrectly propagate this null across constructor
        // invocation.
        if (auto alloc = instr->AsAllocateObject()) {
          for (Value* use = alloc->input_use_list(); use != NULL;
               use = use->next_use()) {
            // Look for all immediate loads/stores from this object.
            if (use->use_index() != 0) {
              continue;
            }
            const Slot* slot = nullptr;
            intptr_t place_id = 0;
            if (auto load = use->instruction()->AsLoadField()) {
              slot = &load->slot();
              place_id = GetPlaceId(load);
            } else if (auto store =
                           use->instruction()->AsStoreInstanceField()) {
              slot = &store->slot();
              place_id = GetPlaceId(store);
            }

            if (slot != nullptr) {
              // Found a load/store. Initialize current value of the field
              // to null for normal fields, or with type arguments.

              // If the object escapes then don't forward final fields - see
              // the comment above for explanation.
              if (aliased_set_->CanBeAliased(alloc) && slot->IsDartField() &&
                  slot->is_immutable()) {
                continue;
              }

              Definition* forward_def = graph_->constant_null();
              if (alloc->type_arguments() != nullptr) {
                const Slot& type_args_slot = Slot::GetTypeArgumentsSlotFor(
                    graph_->thread(), alloc->cls());
                if (slot->IsIdentical(type_args_slot)) {
                  forward_def = alloc->type_arguments()->definition();
                }
              }
              gen->Add(place_id);
              if (out_values == nullptr) out_values = CreateBlockOutValues();
              (*out_values)[place_id] = forward_def;
            }
          }
          continue;
        }

        if (!IsLoadEliminationCandidate(defn)) {
          continue;
        }

        const intptr_t place_id = GetPlaceId(defn);
        if (gen->Contains(place_id)) {
          // This is a locally redundant load.
          ASSERT((out_values != NULL) && ((*out_values)[place_id] != NULL));

          Definition* replacement = (*out_values)[place_id];
          graph_->EnsureSSATempIndex(defn, replacement);
          if (FLAG_trace_optimization) {
            THR_Print("Replacing load v%" Pd " with v%" Pd "\n",
                      defn->ssa_temp_index(), replacement->ssa_temp_index());
          }

          defn->ReplaceUsesWith(replacement);
          instr_it.RemoveCurrentFromGraph();
          forwarded_ = true;
          continue;
        } else if (!kill->Contains(place_id)) {
          // This is an exposed load: it is the first representative of a
          // given expression id and it is not killed on the path from
          // the block entry.
          if (exposed_values == NULL) {
            static const intptr_t kMaxExposedValuesInitialSize = 5;
            exposed_values = new (Z) ZoneGrowableArray<Definition*>(
                Utils::Minimum(kMaxExposedValuesInitialSize,
                               aliased_set_->max_place_id()));
          }

          exposed_values->Add(defn);
        }

        gen->Add(place_id);

        if (out_values == NULL) out_values = CreateBlockOutValues();
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

  // Compute OUT sets by propagating them iteratively until fix point
  // is reached.
  void ComputeOutSets() {
    BitVector* temp = new (Z) BitVector(Z, aliased_set_->max_place_id());
    BitVector* forwarded_loads =
        new (Z) BitVector(Z, aliased_set_->max_place_id());
    BitVector* temp_out = new (Z) BitVector(Z, aliased_set_->max_place_id());

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
            if (pred_out == NULL) continue;
            PhiPlaceMoves::MovesList phi_moves =
                aliased_set_->phi_moves()->GetOutgoingMoves(pred);
            if (phi_moves != NULL) {
              // If there are phi moves, perform intersection with
              // a copy of pred_out where the phi moves are applied.
              temp_out->CopyFrom(pred_out);
              PerformPhiMoves(phi_moves, temp_out, forwarded_loads);
              pred_out = temp_out;
            }
            temp->Intersect(pred_out);
          }
        }

        if (!temp->Equals(*block_in) || (block_out == NULL)) {
          // If IN set has changed propagate the change to OUT set.
          block_in->CopyFrom(temp);

          temp->RemoveAll(block_kill);
          temp->AddAll(block_gen);

          if ((block_out == NULL) || !block_out->Equals(*temp)) {
            if (block_out == NULL) {
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
  // changed at most once: from NULL to an actual value.
  // When merging incoming loads we might need to create a phi.
  // These phis are not inserted at the graph immediately because some of them
  // might become redundant after load forwarding is done.
  void ComputeOutValues() {
    GrowableArray<PhiInstr*> pending_phis(5);
    ZoneGrowableArray<Definition*>* temp_forwarded_values = NULL;

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

        if (block_out_values == NULL) {
          out_values_[preorder_number] = block_out_values =
              CreateBlockOutValues();
        }

        if ((*block_out_values)[place_id] == NULL) {
          ASSERT(block->PredecessorCount() > 0);
          Definition* in_value =
              can_merge_eagerly ? MergeIncomingValues(block, place_id) : NULL;
          if ((in_value == NULL) &&
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
      if ((phi_moves != NULL) && (block_out_values != NULL)) {
        if (temp_forwarded_values == NULL) {
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

      if (FLAG_trace_load_optimization) {
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
      if (pre_header == NULL) {
        invariant_loads->Add(NULL);
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

      if (FLAG_trace_optimization) {
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
    Definition* incoming = NULL;
    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ZoneGrowableArray<Definition*>* pred_out_values =
          out_values_[pred->preorder_number()];
      if ((pred_out_values == NULL) || ((*pred_out_values)[place_id] == NULL)) {
        return NULL;
      } else if (incoming == NULL) {
        incoming = (*pred_out_values)[place_id];
      } else if (incoming != (*pred_out_values)[place_id]) {
        incoming = kDifferentValuesMarker;
      }
    }

    if (incoming != kDifferentValuesMarker) {
      ASSERT(incoming != NULL);
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
      ASSERT((*pred_out_values)[place_id] != NULL);

      // Sets of outgoing values are not linked into use lists so
      // they might contain values that were replaced and removed
      // from the graph by this iteration.
      // To prevent using them we additionally mark definitions themselves
      // as replaced and store a pointer to the replacement.
      Definition* replacement = (*pred_out_values)[place_id]->Replacement();
      Value* input = new (Z) Value(replacement);
      phi->SetInputAt(i, input);
      replacement->AddInputUse(input);
    }

    graph_->AllocateSSAIndexes(phi);
    phis_.Add(phi);  // Postpone phi insertion until after load forwarding.

    if (FLAG_support_il_printer && FLAG_trace_load_optimization) {
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
      if (loads == NULL) continue;  // No exposed loads.

      BitVector* in = in_[block->preorder_number()];

      for (intptr_t i = 0; i < loads->length(); i++) {
        Definition* load = (*loads)[i];
        if (!in->Contains(GetPlaceId(load))) continue;  // No incoming value.

        Definition* replacement = MergeIncomingValues(block, GetPlaceId(load));
        ASSERT(replacement != NULL);

        // Sets of outgoing values are not linked into use lists so
        // they might contain values that were replace and removed
        // from the graph by this iteration.
        // To prevent using them we additionally mark definitions themselves
        // as replaced and store a pointer to the replacement.
        replacement = replacement->Replacement();

        if (load != replacement) {
          graph_->EnsureSSATempIndex(load, replacement);

          if (FLAG_trace_optimization) {
            THR_Print("Replacing load v%" Pd " with v%" Pd "\n",
                      load->ssa_temp_index(), replacement->ssa_temp_index());
          }

          load->ReplaceUsesWith(replacement);
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
    Definition* value = NULL;  // Possible value of this phi.

    worklist_.Clear();
    if (in_worklist_ == NULL) {
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
        if ((phi_input != NULL) && !phi_input->is_alive()) {
          if (!in_worklist_->Contains(phi_input->ssa_temp_index())) {
            worklist_.Add(phi_input);
            in_worklist_->Add(phi_input->ssa_temp_index());
          }
          continue;
        }

        if (value == NULL) {
          value = input;
        } else if (value != input) {
          return false;  // This phi is not redundant.
        }
      }
    }

    // All phis in the worklist are redundant and have the same computed
    // value on all code paths.
    ASSERT(value != NULL);
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
            (a->AllowsCSE() && a->AttributesEqual(b)));
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
      for (Instruction* current = dom->next(); current != NULL;
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
    if (in_worklist_ == NULL) {
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

      if (FLAG_support_il_printer && FLAG_trace_load_optimization) {
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
        phis_[i] = NULL;
      }
    }

    // Now emit phis or replace them with equal phis already present in the
    // graph.
    for (intptr_t i = 0; i < phis_.length(); i++) {
      PhiInstr* phi = phis_[i];
      if ((phi != NULL) && (!phi->HasUses() || !EmitPhi(phi))) {
        phi->UnuseAllInputs();
      }
    }
  }

  ZoneGrowableArray<Definition*>* CreateBlockOutValues() {
    ZoneGrowableArray<Definition*>* out =
        new (Z) ZoneGrowableArray<Definition*>(aliased_set_->max_place_id());
    for (intptr_t i = 0; i < aliased_set_->max_place_id(); i++) {
      out->Add(NULL);
    }
    return out;
  }

  FlowGraph* graph_;
  DirectChainedHashMap<PointerKeyValueTrait<Place> >* map_;

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

bool DominatorBasedCSE::Optimize(FlowGraph* graph) {
  bool changed = false;
  if (FLAG_load_cse) {
    changed = LoadOptimizer::OptimizeGraph(graph) || changed;
  }

  CSEInstructionMap map;
  changed = OptimizeRecursive(graph, graph->graph_entry(), &map) || changed;

  return changed;
}

bool DominatorBasedCSE::OptimizeRecursive(FlowGraph* graph,
                                          BlockEntryInstr* block,
                                          CSEInstructionMap* map) {
  bool changed = false;
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    if (current->AllowsCSE()) {
      Instruction* replacement = map->Lookup(current);

      if (replacement != NULL) {
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
      CSEInstructionMap child_map(*map);
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
                 DirectChainedHashMap<PointerKeyValueTrait<Place> >* map)
      : LivenessAnalysis(aliased_set->max_place_id(), graph->postorder()),
        graph_(graph),
        map_(map),
        aliased_set_(aliased_set),
        exposed_stores_(graph_->postorder().length()) {
    const intptr_t num_blocks = graph_->postorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      exposed_stores_.Add(NULL);
    }
  }

  static void OptimizeGraph(FlowGraph* graph) {
    ASSERT(FLAG_load_cse);

    // For now, bail out for large functions to avoid OOM situations.
    // TODO(fschneider): Fix the memory consumption issue.
    intptr_t function_length = graph->function().end_token_pos().Pos() -
                               graph->function().token_pos().Pos();
    if (function_length >= FLAG_huge_method_cutoff_in_tokens) {
      return;
    }

    DirectChainedHashMap<PointerKeyValueTrait<Place> > map;
    AliasedSet* aliased_set = NumberPlaces(graph, &map, kOptimizeStores);
    if ((aliased_set != NULL) && !aliased_set->IsEmpty()) {
      StoreOptimizer store_optimizer(graph, aliased_set, &map);
      store_optimizer.Optimize();
    }
  }

 private:
  void Optimize() {
    Analyze();
    if (FLAG_trace_load_optimization) {
      Dump();
    }
    EliminateDeadStores();
  }

  bool CanEliminateStore(Instruction* instr) {
    switch (instr->tag()) {
      case Instruction::kStoreInstanceField: {
        StoreInstanceFieldInstr* store_instance = instr->AsStoreInstanceField();
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
    for (BlockIterator block_it = graph_->postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t postorder_number = block->postorder_number();

      BitVector* kill = kill_[postorder_number];
      BitVector* live_in = live_in_[postorder_number];
      BitVector* live_out = live_out_[postorder_number];

      ZoneGrowableArray<Instruction*>* exposed_stores = NULL;

      // Iterate backwards starting at the last instruction.
      for (BackwardInstructionIterator instr_it(block); !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        bool is_load = false;
        bool is_store = false;
        Place place(instr, &is_load, &is_store);
        if (place.IsImmutableField()) {
          // Loads/stores of final fields do not participate.
          continue;
        }

        // Handle stores.
        if (is_store) {
          if (kill->Contains(GetPlaceId(instr))) {
            if (!live_in->Contains(GetPlaceId(instr)) &&
                CanEliminateStore(instr)) {
              if (FLAG_trace_optimization) {
                THR_Print("Removing dead store to place %" Pd " in block B%" Pd
                          "\n",
                          GetPlaceId(instr), block->block_id());
              }
              instr_it.RemoveCurrentFromGraph();
            }
          } else if (!live_in->Contains(GetPlaceId(instr))) {
            // Mark this store as down-ward exposed: They are the only
            // candidates for the global store elimination.
            if (exposed_stores == NULL) {
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

        // Handle side effects, deoptimization and function return.
        if (instr->HasUnknownSideEffects() || instr->CanDeoptimize() ||
            instr->MayThrow() || instr->IsReturn()) {
          // Instructions that return from the function, instructions with side
          // effects and instructions that can deoptimize are considered as
          // loads from all places.
          live_in->CopyFrom(all_places);
          if (instr->IsThrow() || instr->IsReThrow() || instr->IsReturn()) {
            // Initialize live-out for exit blocks since it won't be computed
            // otherwise during the fixed point iteration.
            live_out->CopyFrom(all_places);
          }
          continue;
        }

        // Handle loads.
        Definition* defn = instr->AsDefinition();
        if ((defn != NULL) && IsLoadEliminationCandidate(defn)) {
          const intptr_t alias = aliased_set_->LookupAliasId(place.ToAlias());
          live_in->AddAll(aliased_set_->GetKilledSet(alias));
          continue;
        }
      }
      exposed_stores_[postorder_number] = exposed_stores;
    }
    if (FLAG_trace_load_optimization) {
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
      if (exposed_stores == NULL) continue;  // No exposed stores.

      // Iterate over candidate stores.
      for (intptr_t i = 0; i < exposed_stores->length(); ++i) {
        Instruction* instr = (*exposed_stores)[i];
        bool is_load = false;
        bool is_store = false;
        Place place(instr, &is_load, &is_store);
        ASSERT(!is_load && is_store);
        if (place.IsImmutableField()) {
          // Final field do not participate in dead store elimination.
          continue;
        }
        // Eliminate a downward exposed store if the corresponding place is not
        // in live-out.
        if (!live_out->Contains(GetPlaceId(instr)) &&
            CanEliminateStore(instr)) {
          if (FLAG_trace_optimization) {
            THR_Print("Removing dead store to place %" Pd " block B%" Pd "\n",
                      GetPlaceId(instr), block->block_id());
          }
          instr->RemoveFromGraph(/* ignored */ false);
        }
      }
    }
  }

  FlowGraph* graph_;
  DirectChainedHashMap<PointerKeyValueTrait<Place> >* map_;

  // Mapping between field offsets in words and expression ids of loads from
  // that offset.
  AliasedSet* aliased_set_;

  // Per block list of downward exposed stores.
  GrowableArray<ZoneGrowableArray<Instruction*>*> exposed_stores_;

  DISALLOW_COPY_AND_ASSIGN(StoreOptimizer);
};

void DeadStoreElimination::Optimize(FlowGraph* graph) {
  if (FLAG_dead_store_elimination) {
    StoreOptimizer::OptimizeGraph(graph);
  }
}

//
// Allocation Sinking
//

// Returns true if the given instruction is an allocation that
// can be sunk by the Allocation Sinking pass.
static bool IsSupportedAllocation(Instruction* instr) {
  return instr->IsAllocateObject() || instr->IsAllocateUninitializedContext();
}

enum SafeUseCheck { kOptimisticCheck, kStrictCheck };

// Check if the use is safe for allocation sinking. Allocation sinking
// candidates can only be used at store instructions:
//
//     - any store into the allocation candidate itself is unconditionally safe
//       as it just changes the rematerialization state of this candidate;
//     - store into another object is only safe if another object is allocation
//       candidate.
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
// Fix-point algorithm in CollectCandiates first collects a set of allocations
// optimistically and then checks each collected candidate strictly and unmarks
// invalid candidates transitively until only strictly valid ones remain.
static bool IsSafeUse(Value* use, SafeUseCheck check_type) {
  if (use->instruction()->IsMaterializeObject()) {
    return true;
  }

  StoreInstanceFieldInstr* store = use->instruction()->AsStoreInstanceField();
  if (store != NULL) {
    if (use == store->value()) {
      Definition* instance = store->instance()->definition();
      return IsSupportedAllocation(instance) &&
             ((check_type == kOptimisticCheck) ||
              instance->Identity().IsAllocationSinkingCandidate());
    }
    return true;
  }

  return false;
}

// Right now we are attempting to sink allocation only into
// deoptimization exit. So candidate should only be used in StoreInstanceField
// instructions that write into fields of the allocated object.
static bool IsAllocationSinkingCandidate(Definition* alloc,
                                         SafeUseCheck check_type) {
  for (Value* use = alloc->input_use_list(); use != NULL;
       use = use->next_use()) {
    if (!IsSafeUse(use, check_type)) {
      if (FLAG_support_il_printer && FLAG_trace_optimization) {
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
static Definition* StoreInto(Value* use) {
  StoreInstanceFieldInstr* store = use->instruction()->AsStoreInstanceField();
  if (store != NULL) {
    return store->instance()->definition();
  }

  return NULL;
}

// Remove the given allocation from the graph. It is not observable.
// If deoptimization occurs the object will be materialized.
void AllocationSinking::EliminateAllocation(Definition* alloc) {
  ASSERT(IsAllocationSinkingCandidate(alloc, kStrictCheck));

  if (FLAG_trace_optimization) {
    THR_Print("removing allocation from the graph: v%" Pd "\n",
              alloc->ssa_temp_index());
  }

  // As an allocation sinking candidate it is only used in stores to its own
  // fields. Remove these stores.
  for (Value* use = alloc->input_use_list(); use != NULL;
       use = alloc->input_use_list()) {
    use->instruction()->RemoveFromGraph();
  }

// There should be no environment uses. The pass replaced them with
// MaterializeObject instructions.
#ifdef DEBUG
  for (Value* use = alloc->env_use_list(); use != NULL; use = use->next_use()) {
    ASSERT(use->instruction()->IsMaterializeObject());
  }
#endif
  ASSERT(alloc->input_use_list() == NULL);
  alloc->RemoveFromGraph();
  if (alloc->ArgumentCount() > 0) {
    ASSERT(alloc->ArgumentCount() == 1);
    ASSERT(!alloc->HasPushArguments());
  }
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
      if (FLAG_trace_optimization) {
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
    for (Value* use = alloc->input_use_list(); use != NULL; use = next_use) {
      next_use = use->next_use();
      if (use->instruction()->IsMaterializeObject()) {
        use->BindTo(MaterializationFor(alloc, use->instruction()));
      }
    }
  }
}

// We transitively insert materializations at each deoptimization exit that
// might see the given allocation (see ExitsCollector). Some of this
// materializations are not actually used and some fail to compute because
// they are inserted in the block that is not dominated by the allocation.
// Remove them unused materializations from the graph.
void AllocationSinking::RemoveUnusedMaterializations() {
  intptr_t j = 0;
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    MaterializeObjectInstr* mat = materializations_[i];
    if ((mat->input_use_list() == NULL) && (mat->env_use_list() == NULL)) {
      // Check if this materialization failed to compute and remove any
      // unforwarded loads. There were no loads from any allocation sinking
      // candidate in the beginning so it is safe to assume that any encountered
      // load was inserted by CreateMaterializationAt.
      for (intptr_t i = 0; i < mat->InputCount(); i++) {
        LoadFieldInstr* load = mat->InputAt(i)->definition()->AsLoadField();
        if ((load != NULL) &&
            (load->instance()->definition() == mat->allocation())) {
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
      if (FLAG_trace_optimization) {
        THR_Print("allocation v%" Pd " can't be eliminated\n",
                  alloc->ssa_temp_index());
      }

#ifdef DEBUG
      for (Value* use = alloc->env_use_list(); use != NULL;
           use = use->next_use()) {
        ASSERT(use->instruction()->IsMaterializeObject());
      }
#endif

      // All materializations will be removed from the graph. Remove inserted
      // loads first and detach materializations from allocation's environment
      // use list: we will reconstruct it when we start removing
      // materializations.
      alloc->set_env_use_list(NULL);
      for (Value* use = alloc->input_use_list(); use != NULL;
           use = use->next_use()) {
        if (use->instruction()->IsLoadField()) {
          LoadFieldInstr* load = use->instruction()->AsLoadField();
          load->ReplaceUsesWith(flow_graph_->constant_null());
          load->RemoveFromGraph();
        } else {
          ASSERT(use->instruction()->IsMaterializeObject() ||
                 use->instruction()->IsPhi() ||
                 use->instruction()->IsStoreInstanceField());
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
  CollectCandidates();

  // Insert MaterializeObject instructions that will describe the state of the
  // object at all deoptimization points. Each inserted materialization looks
  // like this (where v_0 is allocation that we are going to eliminate):
  //   v_1     <- LoadField(v_0, field_1)
  //           ...
  //   v_N     <- LoadField(v_0, field_N)
  //   v_{N+1} <- MaterializeObject(field_1 = v_1, ..., field_N = v_{N})
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    InsertMaterializations(candidates_[i]);
  }

  // Run load forwarding to eliminate LoadField instructions inserted above.
  // All loads will be successfully eliminated because:
  //   a) they use fields (not offsets) and thus provide precise aliasing
  //      information
  //   b) candidate does not escape and thus its fields is not affected by
  //      external effects from calls.
  LoadOptimizer::OptimizeGraph(flow_graph_);

  NormalizeMaterializations();

  RemoveUnusedMaterializations();

  // If any candidates are no longer eligible for allocation sinking abort
  // the optimization for them and undo any changes we did in preparation.
  DiscoverFailedCandidates();

  // At this point we have computed the state of object at each deoptimization
  // point and we can eliminate it. Loads inserted above were forwarded so there
  // are no uses of the allocation just as in the begging of the pass.
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
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    materializations_[i]->previous()->LinkTo(materializations_[i]->next());
  }
}

// Add a field/offset to the list of fields if it is not yet present there.
static bool AddSlot(ZoneGrowableArray<const Slot*>* slots, const Slot& slot) {
  for (auto s : *slots) {
    if (s == &slot) {
      return false;
    }
  }
  slots->Add(&slot);
  return true;
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
       mat != NULL; mat = mat->previous()->AsMaterializeObject()) {
    if (mat->allocation() == alloc) {
      return mat;
    }
  }

  return NULL;
}

// Insert MaterializeObject instruction for the given allocation before
// the given instruction that can deoptimize.
void AllocationSinking::CreateMaterializationAt(
    Instruction* exit,
    Definition* alloc,
    const ZoneGrowableArray<const Slot*>& slots) {
  ZoneGrowableArray<Value*>* values =
      new (Z) ZoneGrowableArray<Value*>(slots.length());

  // All loads should be inserted before the first materialization so that
  // IR follows the following pattern: loads, materializations, deoptimizing
  // instruction.
  Instruction* load_point = FirstMaterializationAt(exit);

  // Insert load instruction for every field.
  for (auto slot : slots) {
    LoadFieldInstr* load =
        new (Z) LoadFieldInstr(new (Z) Value(alloc), *slot, alloc->token_pos());
    flow_graph_->InsertBefore(load_point, load, nullptr, FlowGraph::kValue);
    values->Add(new (Z) Value(load));
  }

  MaterializeObjectInstr* mat = nullptr;
  if (alloc->IsAllocateObject()) {
    mat = new (Z)
        MaterializeObjectInstr(alloc->AsAllocateObject(), slots, values);
  } else {
    ASSERT(alloc->IsAllocateUninitializedContext());
    mat = new (Z) MaterializeObjectInstr(
        alloc->AsAllocateUninitializedContext(), slots, values);
  }

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
  for (Value* use = alloc->env_use_list(); use != NULL; use = use->next_use()) {
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
  for (Value* use = alloc->input_use_list(); use != NULL;
       use = use->next_use()) {
    Definition* obj = StoreInto(use);
    if ((obj != NULL) && (obj != alloc)) {
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

void AllocationSinking::InsertMaterializations(Definition* alloc) {
  // Collect all fields that are written for this instance.
  auto slots = new (Z) ZoneGrowableArray<const Slot*>(5);

  for (Value* use = alloc->input_use_list(); use != NULL;
       use = use->next_use()) {
    StoreInstanceFieldInstr* store = use->instruction()->AsStoreInstanceField();
    if ((store != NULL) && (store->instance()->definition() == alloc)) {
      AddSlot(slots, store->slot());
    }
  }

  if (auto alloc_object = alloc->AsAllocateObject()) {
    if (alloc_object->type_arguments() != nullptr) {
      AddSlot(slots, Slot::GetTypeArgumentsSlotFor(flow_graph_->thread(),
                                                   alloc_object->cls()));
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
//
// Caveat: when analyzing which Parameter-s are redundant we limit ourselves to
// constant values because CatchBlockEntry-s are hanging out directly from
// GraphEntry and thus they are only dominated by constants from GraphEntry -
// thus we can't replace Parameter with arbitrary Definition which is not a
// Constant even if we know that this Parameter is redundant and would always
// evaluate to that Definition.
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
    for (auto catch_entry : flow_graph_->graph_entry()->catch_entries()) {
      const GrowableArray<Definition*>& idefs =
          *catch_entry->initial_definitions();
      for (auto idef : idefs) {
        if (idef->IsParameter()) {
          SetParameterId(idef, parameter_info_.length());
          parameter_info_.Add(new ParameterInfo(idef->AsParameter()));
        }
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

        for (intptr_t env_idx = 0; env_idx < idefs.length(); ++env_idx) {
          if (ParameterInstr* param = idefs[env_idx]->AsParameter()) {
            Definition* defn = env->ValueAt(env_idx)->definition();

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
          if (HasNonPhiUse(phi)) {
            MarkLive(phi);
          }
        }
      }
    }

    for (auto info : parameter_info_) {
      if (HasNonPhiUse(info->instr)) {
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

        for (intptr_t env_idx = 0; env_idx < idefs.length(); ++env_idx) {
          if (ParameterInstr* param = idefs[env_idx]->AsParameter()) {
            if (!parameter_info_[GetParameterId(param)]->alive) {
              env->ValueAt(env_idx)->BindToEnvironment(
                  flow_graph_->constant_null());
            }
          }
        }
      }
    }

    DeadCodeElimination::RemoveDeadAndRedundantPhisFromTheGraph(flow_graph_);
  }

  // Returns true if definition has a use in an instruction which is not a phi.
  static bool HasNonPhiUse(Definition* defn) {
    for (Value* use = defn->input_use_list(); use != nullptr;
         use = use->next_use()) {
      if (!use->instruction()->IsPhi()) {
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
  if (flow_graph->graph_entry()->catch_entries().is_empty()) {
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

  // For every catch-block: Iterate over all call instructions inside the
  // corresponding try-block and figure out for each environment value if it
  // is the same constant at all calls. If yes, replace the initial definition
  // at the catch-entry with this constant.
  const GrowableArray<CatchBlockEntryInstr*>& catch_entries =
      flow_graph_->graph_entry()->catch_entries();

  for (auto catch_entry : catch_entries) {
    // Initialize cdefs with the original initial definitions (ParameterInstr).
    // The following representation is used:
    // ParameterInstr => unknown
    // ConstantInstr => known constant
    // NULL => non-constant
    GrowableArray<Definition*>* idefs = catch_entry->initial_definitions();
    GrowableArray<Definition*> cdefs(idefs->length());
    cdefs.AddArray(*idefs);

    // exception_var and stacktrace_var are never constant.  In asynchronous or
    // generator functions they may be context-allocated in which case they are
    // not tracked in the environment anyway.

    cdefs[flow_graph_->EnvIndex(catch_entry->raw_exception_var())] = nullptr;
    cdefs[flow_graph_->EnvIndex(catch_entry->raw_stacktrace_var())] = nullptr;

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
            for (intptr_t env_idx = 0; env_idx < cdefs.length(); ++env_idx) {
              if (cdefs[env_idx] != nullptr && !cdefs[env_idx]->IsConstant() &&
                  env->ValueAt(env_idx)->BindsToConstant()) {
                // If the recorded definition is not a constant, record this
                // definition as the current constant definition.
                cdefs[env_idx] = env->ValueAt(env_idx)->definition();
              }
              if (cdefs[env_idx] != env->ValueAt(env_idx)->definition()) {
                // Non-constant definitions are reset to nullptr.
                cdefs[env_idx] = nullptr;
              }
            }
          }
        }
      }
    }
    for (intptr_t j = 0; j < idefs->length(); ++j) {
      if (cdefs[j] != nullptr && cdefs[j]->IsConstant()) {
        Definition* old = (*idefs)[j];
        ConstantInstr* orig = cdefs[j]->AsConstant();
        ConstantInstr* copy =
            new (flow_graph_->zone()) ConstantInstr(orig->value());
        copy->set_ssa_temp_index(flow_graph_->alloc_ssa_temp_index());
        if (FlowGraph::NeedsPairLocation(copy->representation())) {
          flow_graph_->alloc_ssa_temp_index();
        }
        old->ReplaceUsesWith(copy);
        copy->set_previous(old->previous());  // partial link
        (*idefs)[j] = copy;
      }
    }
  }
}

// Returns true iff this definition is used in a non-phi instruction.
static bool HasRealUse(Definition* def) {
  // Environment uses are real (non-phi) uses.
  if (def->env_use_list() != NULL) return true;

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
    if (join != NULL) {
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
      if ((used_phi != NULL) && !used_phi->is_alive()) {
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
            if (FLAG_trace_optimization) {
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

// Returns true if [current] instruction can be possibly eliminated
// (if its result is not used).
static bool CanEliminateInstruction(Instruction* current,
                                    BlockEntryInstr* block) {
  ASSERT(current->GetBlock() == block);
  if (MayHaveVisibleEffect(current) || current->CanDeoptimize() ||
      current == block->last_instruction() || current->IsMaterializeObject() ||
      current->IsCheckStackOverflow() || current->IsReachabilityFence() ||
      current->IsEnterHandleScope() || current->IsExitHandleScope() ||
      current->IsRawStoreField()) {
    return false;
  }
  return true;
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
      ASSERT(!current->IsPushArgument());
      // TODO(alexmarkov): take control dependencies into account and
      // eliminate dead branches/conditions.
      if (!CanEliminateInstruction(current, block)) {
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
        ASSERT(!input->IsPushArgument());
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
      if (!CanEliminateInstruction(current, block)) {
        continue;
      }
      ASSERT(!current->IsPushArgument());
      ASSERT((current->ArgumentCount() == 0) || !current->HasPushArguments());
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
  CheckStackOverflowInstr* first_stack_overflow_instr = NULL;
  for (BlockIterator block_it = graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* entry = block_it.Current();

    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();

      if (CheckStackOverflowInstr* instr = current->AsCheckStackOverflow()) {
        if (first_stack_overflow_instr == NULL) {
          first_stack_overflow_instr = instr;
          ASSERT(!first_stack_overflow_instr->in_loop());
        }
        continue;
      }

      if (current->IsBranch()) {
        current = current->AsBranch()->comparison();
      }

      if (current->HasUnknownSideEffects()) {
        return;
      }
    }
  }

  if (first_stack_overflow_instr != NULL) {
    first_stack_overflow_instr->RemoveFromGraph();
  }
}

}  // namespace dart
