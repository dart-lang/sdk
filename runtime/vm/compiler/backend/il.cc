// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il.h"

#include "platform/assert.h"
#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/compiler/aot/dispatch_table_generator.h"
#include "vm/compiler/backend/code_statistics.h"
#include "vm/compiler/backend/constant_propagator.h"
#include "vm/compiler/backend/evaluator.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/locations_helpers.h"
#include "vm/compiler/backend/loops.h"
#include "vm/compiler/backend/parallel_move_resolver.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/ffi/frame_rebase.h"
#include "vm/compiler/ffi/marshaller.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/compiler/runtime_api.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/regexp_assembler_ir.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"

#include "vm/compiler/backend/il_printer.h"

namespace dart {

DEFINE_FLAG(bool,
            propagate_ic_data,
            true,
            "Propagate IC data from unoptimized to optimized IC calls.");
DEFINE_FLAG(bool,
            two_args_smi_icd,
            true,
            "Generate special IC stubs for two args Smi operations");

DECLARE_FLAG(bool, inline_alloc);
DECLARE_FLAG(bool, use_slow_path);

class SubtypeFinder {
 public:
  SubtypeFinder(Zone* zone,
                GrowableArray<intptr_t>* cids,
                bool include_abstract)
      : array_handles_(zone),
        class_handles_(zone),
        cids_(cids),
        include_abstract_(include_abstract) {}

  void ScanImplementorClasses(const Class& klass) {
    // An implementor of [klass] is
    //    * the [klass] itself.
    //    * all implementors of the direct subclasses of [klass].
    //    * all implementors of the direct implementors of [klass].
    if (include_abstract_ || !klass.is_abstract()) {
      cids_->Add(klass.id());
    }

    ScopedHandle<GrowableObjectArray> array(&array_handles_);
    ScopedHandle<Class> subclass_or_implementor(&class_handles_);

    *array = klass.direct_subclasses();
    if (!array->IsNull()) {
      for (intptr_t i = 0; i < array->Length(); ++i) {
        *subclass_or_implementor ^= (*array).At(i);
        ScanImplementorClasses(*subclass_or_implementor);
      }
    }
    *array = klass.direct_implementors();
    if (!array->IsNull()) {
      for (intptr_t i = 0; i < array->Length(); ++i) {
        *subclass_or_implementor ^= (*array).At(i);
        ScanImplementorClasses(*subclass_or_implementor);
      }
    }
  }

 private:
  ReusableHandleStack<GrowableObjectArray> array_handles_;
  ReusableHandleStack<Class> class_handles_;
  GrowableArray<intptr_t>* cids_;
  const bool include_abstract_;
};

const CidRangeVector& HierarchyInfo::SubtypeRangesForClass(
    const Class& klass,
    bool include_abstract,
    bool exclude_null) {
  ClassTable* table = thread()->isolate_group()->class_table();
  const intptr_t cid_count = table->NumCids();
  std::unique_ptr<CidRangeVector[]>* cid_ranges = nullptr;
  if (include_abstract) {
    cid_ranges = exclude_null ? &cid_subtype_ranges_abstract_nonnullable_
                              : &cid_subtype_ranges_abstract_nullable_;
  } else {
    cid_ranges = exclude_null ? &cid_subtype_ranges_nonnullable_
                              : &cid_subtype_ranges_nullable_;
  }
  if (*cid_ranges == nullptr) {
    cid_ranges->reset(new CidRangeVector[cid_count]);
  }
  CidRangeVector& ranges = (*cid_ranges)[klass.id()];
  if (ranges.length() == 0) {
    BuildRangesFor(table, &ranges, klass, include_abstract, exclude_null);
  }
  return ranges;
}

class CidCheckerForRanges : public ValueObject {
 public:
  CidCheckerForRanges(Thread* thread,
                      ClassTable* table,
                      const Class& cls,
                      bool include_abstract,
                      bool exclude_null)
      : thread_(thread),
        table_(table),
        supertype_(AbstractType::Handle(zone(), cls.RareType())),
        include_abstract_(include_abstract),
        exclude_null_(exclude_null),
        to_check_(Class::Handle(zone())),
        subtype_(AbstractType::Handle(zone())) {}

  bool MayInclude(intptr_t cid) {
    if (!table_->HasValidClassAt(cid)) return true;
    if (cid == kTypeArgumentsCid) return true;
    if (cid == kVoidCid) return true;
    if (cid == kDynamicCid) return true;
    if (cid == kNeverCid) return true;
    if (!exclude_null_ && cid == kNullCid) return true;
    to_check_ = table_->At(cid);
    ASSERT(!to_check_.IsNull());
    if (!include_abstract_ && to_check_.is_abstract()) return true;
    return to_check_.IsTopLevel();
  }

  bool MustInclude(intptr_t cid) {
    ASSERT(!MayInclude(cid));
    if (cid == kNullCid) return false;
    to_check_ = table_->At(cid);
    subtype_ = to_check_.RareType();
    // Create local zone because deep hierarchies may allocate lots of handles.
    StackZone stack_zone(thread_);
    HANDLESCOPE(thread_);
    return subtype_.IsSubtypeOf(supertype_, Heap::kNew);
  }

 private:
  Zone* zone() const { return thread_->zone(); }

  Thread* const thread_;
  ClassTable* const table_;
  const AbstractType& supertype_;
  const bool include_abstract_;
  const bool exclude_null_;
  Class& to_check_;
  AbstractType& subtype_;
};

// Build the ranges either for:
//    "<obj> as <Type>", or
//    "<obj> is <Type>"
void HierarchyInfo::BuildRangesUsingClassTableFor(ClassTable* table,
                                                  CidRangeVector* ranges,
                                                  const Class& klass,
                                                  bool include_abstract,
                                                  bool exclude_null) {
  CidCheckerForRanges checker(thread(), table, klass, include_abstract,
                              exclude_null);
  // Iterate over all cids to find the ones to be included in the ranges.
  const intptr_t cid_count = table->NumCids();
  intptr_t start = -1;
  intptr_t end = -1;
  for (intptr_t cid = kInstanceCid; cid < cid_count; ++cid) {
    // Some cases are "don't care", i.e., they may or may not be included,
    // whatever yields the least number of ranges for efficiency.
    if (checker.MayInclude(cid)) continue;
    if (checker.MustInclude(cid)) {
      // On success, open a new or continue any open range.
      if (start == -1) start = cid;
      end = cid;
    } else if (start != -1) {
      // On failure, close any open range from start to end
      // (the latter is the most recent succesful "do-care" cid).
      ranges->Add({start, end});
      start = end = -1;
    }
  }

  // Construct last range if there is a open one.
  if (start != -1) {
    ranges->Add({start, end});
  }
}

void HierarchyInfo::BuildRangesFor(ClassTable* table,
                                   CidRangeVector* ranges,
                                   const Class& dst_klass,
                                   bool include_abstract,
                                   bool exclude_null) {
  // Use the class table in cases where the direct subclasses and implementors
  // are not filled out.
  if (dst_klass.InVMIsolateHeap() || dst_klass.id() == kInstanceCid) {
    BuildRangesUsingClassTableFor(table, ranges, dst_klass, include_abstract,
                                  exclude_null);
    return;
  }

  Zone* zone = thread()->zone();
  GrowableArray<intptr_t> cids;
  SubtypeFinder finder(zone, &cids, include_abstract);
  {
    SafepointReadRwLocker ml(thread(),
                             thread()->isolate_group()->program_lock());
    finder.ScanImplementorClasses(dst_klass);
  }
  if (cids.is_empty()) return;

  // Sort all collected cids.
  intptr_t* cids_array = cids.data();

  qsort(cids_array, cids.length(), sizeof(intptr_t),
        [](const void* a, const void* b) {
          // MSAN seems unaware of allocations inside qsort. The linker flag
          // -fsanitize=memory should give us a MSAN-aware version of libc...
          MSAN_UNPOISON(static_cast<const intptr_t*>(a), sizeof(intptr_t));
          MSAN_UNPOISON(static_cast<const intptr_t*>(b), sizeof(intptr_t));
          return static_cast<int>(*static_cast<const intptr_t*>(a) -
                                  *static_cast<const intptr_t*>(b));
        });

  // Build ranges of all the cids.
  CidCheckerForRanges checker(thread(), table, dst_klass, include_abstract,
                              exclude_null);
  intptr_t left_cid = -1;
  intptr_t right_cid = -1;
  intptr_t previous_cid = -1;
  for (intptr_t i = 0; i < cids.length(); ++i) {
    const intptr_t current_cid = cids[i];
    if (current_cid == previous_cid) continue;  // Skip duplicates.

    // We sorted, after all!
    RELEASE_ASSERT(previous_cid < current_cid);

    if (left_cid != -1) {
      ASSERT(previous_cid != -1);
      // Check the cids between the previous cid from cids and this one.
      for (intptr_t j = previous_cid + 1; j < current_cid; ++j) {
        // Stop if we find a do-care class before reaching the current cid.
        if (!checker.MayInclude(j)) {
          ranges->Add({left_cid, right_cid});
          left_cid = right_cid = -1;
          break;
        }
      }
    }
    previous_cid = current_cid;

    if (checker.MayInclude(current_cid)) continue;
    if (checker.MustInclude(current_cid)) {
      if (left_cid == -1) {
        // Open a new range starting at this cid.
        left_cid = current_cid;
      }
      right_cid = current_cid;
    } else if (left_cid != -1) {
      // Close the existing range.
      ranges->Add({left_cid, right_cid});
      left_cid = right_cid = -1;
    }
  }

  // If there is an open cid-range which we haven't finished yet, we'll
  // complete it.
  if (left_cid != -1) {
    ranges->Add(CidRange{left_cid, right_cid});
  }
}

bool HierarchyInfo::CanUseSubtypeRangeCheckFor(const AbstractType& type) {
  ASSERT(type.IsFinalized());

  if (!type.IsInstantiated() || !type.IsType()) {
    return false;
  }

  // The FutureOr<T> type cannot be handled by checking whether the instance is
  // a subtype of FutureOr and then checking whether the type argument `T`
  // matches.
  //
  // Instead we would need to perform multiple checks:
  //
  //    instance is Null || instance is T || instance is Future<T>
  //
  if (type.IsFutureOrType()) {
    return false;
  }

  Zone* zone = thread()->zone();
  const Class& type_class = Class::Handle(zone, type.type_class());

  // We can use class id range checks only if we don't have to test type
  // arguments.
  //
  // This is e.g. true for "String" but also for "List<dynamic>".  (A type for
  // which the type arguments vector is instantiated to bounds is known as a
  // rare type.)
  if (type_class.IsGeneric()) {
    const Type& rare_type = Type::Handle(zone, type_class.RareType());
    if (!rare_type.IsSubtypeOf(type, Heap::kNew)) {
      ASSERT(Type::Cast(type).arguments() != TypeArguments::null());
      return false;
    }
  }

  return true;
}

bool HierarchyInfo::CanUseGenericSubtypeRangeCheckFor(
    const AbstractType& type) {
  ASSERT(type.IsFinalized());

  if (!type.IsType() || type.IsDartFunctionType()) {
    return false;
  }

  // The FutureOr<T> type cannot be handled by checking whether the instance is
  // a subtype of FutureOr and then checking whether the type argument `T`
  // matches.
  //
  // Instead we would need to perform multiple checks:
  //
  //    instance is Null || instance is T || instance is Future<T>
  //
  if (type.IsFutureOrType()) {
    return false;
  }

  // NOTE: We do allow non-instantiated types here (in comparison to
  // [CanUseSubtypeRangeCheckFor], since we handle type parameters in the type
  // expression in some cases (see below).

  Zone* zone = thread()->zone();
  const Class& type_class = Class::Handle(zone, type.type_class());
  const intptr_t num_type_parameters = type_class.NumTypeParameters();

  // This function should only be called for generic classes.
  ASSERT(type_class.NumTypeParameters() > 0 &&
         Type::Cast(type).arguments() != TypeArguments::null());

  const TypeArguments& ta =
      TypeArguments::Handle(zone, Type::Cast(type).arguments());
  ASSERT(ta.Length() == num_type_parameters);

  // Ensure we can handle all type arguments
  // via [CidRange]-based checks or that it is a type parameter.
  AbstractType& type_arg = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < num_type_parameters; ++i) {
    type_arg = ta.TypeAt(i);
    if (!CanUseSubtypeRangeCheckFor(type_arg) && !type_arg.IsTypeParameter()) {
      return false;
    }
  }

  return true;
}

bool HierarchyInfo::CanUseRecordSubtypeRangeCheckFor(const AbstractType& type) {
  ASSERT(type.IsFinalized());
  if (!type.IsRecordType()) {
    return false;
  }
  const RecordType& rec = RecordType::Cast(type);
  Zone* zone = thread()->zone();
  auto& field_type = AbstractType::Handle(zone);
  for (intptr_t i = 0, n = rec.NumFields(); i < n; ++i) {
    field_type = rec.FieldTypeAt(i);
    if (!CanUseSubtypeRangeCheckFor(field_type)) {
      return false;
    }
  }
  return true;
}

bool HierarchyInfo::InstanceOfHasClassRange(const AbstractType& type,
                                            intptr_t* lower_limit,
                                            intptr_t* upper_limit) {
  ASSERT(CompilerState::Current().is_aot());
  if (type.IsNullable()) {
    // 'is' test for nullable types should accept null cid in addition to the
    // class range. In most cases it is not possible to extend class range to
    // include kNullCid.
    return false;
  }
  if (CanUseSubtypeRangeCheckFor(type)) {
    const Class& type_class =
        Class::Handle(thread()->zone(), type.type_class());
    const CidRangeVector& ranges =
        SubtypeRangesForClass(type_class,
                              /*include_abstract=*/false,
                              /*exclude_null=*/true);
    if (ranges.length() == 1) {
      const CidRangeValue& range = ranges[0];
      ASSERT(!range.IsIllegalRange());
      *lower_limit = range.cid_start;
      *upper_limit = range.cid_end;
      return true;
    }
  }
  return false;
}

// The set of supported non-integer unboxed representations.
// Format: (unboxed representations suffix, boxed class type)
#define FOR_EACH_NON_INT_BOXED_REPRESENTATION(M)                               \
  M(Double, Double)                                                            \
  M(Float, Double)                                                             \
  M(Float32x4, Float32x4)                                                      \
  M(Float64x2, Float64x2)                                                      \
  M(Int32x4, Int32x4)

#define BOXING_IN_SET_CASE(unboxed, boxed)                                     \
  case kUnboxed##unboxed:                                                      \
    return true;
#define BOXING_VALUE_OFFSET_CASE(unboxed, boxed)                               \
  case kUnboxed##unboxed:                                                      \
    return compiler::target::boxed::value_offset();
#define BOXING_CID_CASE(unboxed, boxed)                                        \
  case kUnboxed##unboxed:                                                      \
    return k##boxed##Cid;

bool Boxing::Supports(Representation rep) {
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    return true;
  }
  switch (rep) {
    FOR_EACH_NON_INT_BOXED_REPRESENTATION(BOXING_IN_SET_CASE)
    default:
      return false;
  }
}

bool Boxing::RequiresAllocation(Representation rep) {
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    return (kBitsPerByte * RepresentationUtils::ValueSize(rep)) >
           compiler::target::kSmiBits;
  }
  return true;
}

intptr_t Boxing::ValueOffset(Representation rep) {
  if (RepresentationUtils::IsUnboxedInteger(rep) &&
      Boxing::RequiresAllocation(rep) &&
      RepresentationUtils::ValueSize(rep) <= sizeof(int64_t)) {
    return compiler::target::Mint::value_offset();
  }
  switch (rep) {
    FOR_EACH_NON_INT_BOXED_REPRESENTATION(BOXING_VALUE_OFFSET_CASE)
    default:
      UNREACHABLE();
      return 0;
  }
}

// Note that not all boxes require allocation (e.g., Smis).
intptr_t Boxing::BoxCid(Representation rep) {
  if (RepresentationUtils::IsUnboxedInteger(rep)) {
    if (!Boxing::RequiresAllocation(rep)) {
      return kSmiCid;
    } else if (RepresentationUtils::ValueSize(rep) <= sizeof(int64_t)) {
      return kMintCid;
    }
  }
  switch (rep) {
    FOR_EACH_NON_INT_BOXED_REPRESENTATION(BOXING_CID_CASE)
    default:
      UNREACHABLE();
      return kIllegalCid;
  }
}

#undef BOXING_CID_CASE
#undef BOXING_VALUE_OFFSET_CASE
#undef BOXING_IN_SET_CASE
#undef FOR_EACH_NON_INT_BOXED_REPRESENTATION

#if defined(DEBUG)
void Instruction::CheckField(const Field& field) const {
  DEBUG_ASSERT(field.IsNotTemporaryScopedHandle());
  ASSERT(!Compiler::IsBackgroundCompilation() || !field.IsOriginal());
}
#endif  // DEBUG

// A value in the constant propagation lattice.
//    - non-constant sentinel
//    - a constant (any non-sentinel value)
//    - unknown sentinel
Object& Definition::constant_value() {
  if (constant_value_ == nullptr) {
    constant_value_ = &Object::ZoneHandle(ConstantPropagator::Unknown());
  }
  return *constant_value_;
}

Definition* Definition::OriginalDefinition() {
  Definition* defn = this;
  Value* unwrapped;
  while ((unwrapped = defn->RedefinedValue()) != nullptr) {
    defn = unwrapped->definition();
  }
  return defn;
}

Value* Definition::RedefinedValue() const {
  return nullptr;
}

Value* RedefinitionInstr::RedefinedValue() const {
  return value();
}

Value* AssertAssignableInstr::RedefinedValue() const {
  return value();
}

Value* AssertBooleanInstr::RedefinedValue() const {
  return value();
}

Value* CheckBoundBase::RedefinedValue() const {
  return index();
}

Value* CheckWritableInstr::RedefinedValue() const {
  return value();
}

Value* CheckNullInstr::RedefinedValue() const {
  return value();
}

Definition* Definition::OriginalDefinitionIgnoreBoxingAndConstraints() {
  Definition* def = this;
  while (true) {
    Definition* orig;
    if (def->IsConstraint() || def->IsBox() || def->IsUnbox() ||
        def->IsIntConverter()) {
      orig = def->InputAt(0)->definition();
    } else {
      orig = def->OriginalDefinition();
    }
    if (orig == def) return def;
    def = orig;
  }
}

bool Definition::IsArrayLength(Definition* def) {
  if (def != nullptr) {
    if (auto load = def->OriginalDefinitionIgnoreBoxingAndConstraints()
                        ->AsLoadField()) {
      return load->IsImmutableLengthLoad();
    }
  }
  return false;
}

const ICData* Instruction::GetICData(
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    intptr_t deopt_id,
    bool is_static_call) {
  // The deopt_id can be outside the range of the IC data array for
  // computations added in the optimizing compiler.
  ASSERT(deopt_id != DeoptId::kNone);
  if (deopt_id >= ic_data_array.length()) {
    return nullptr;
  }
  const ICData* result = ic_data_array[deopt_id];
  ASSERT(result == nullptr || is_static_call == result->is_static_call());
  return result;
}

uword Instruction::Hash() const {
  uword result = tag();
  for (intptr_t i = 0; i < InputCount(); ++i) {
    Value* value = InputAt(i);
    result = CombineHashes(result, value->definition()->ssa_temp_index());
  }
  return FinalizeHash(result, kBitsPerInt32 - 1);
}

bool Instruction::Equals(const Instruction& other) const {
  if (tag() != other.tag()) return false;
  if (InputCount() != other.InputCount()) return false;
  for (intptr_t i = 0; i < InputCount(); ++i) {
    if (!InputAt(i)->Equals(*other.InputAt(i))) return false;
  }
  return AttributesEqual(other);
}

void Instruction::Unsupported(FlowGraphCompiler* compiler) {
  compiler->Bailout(ToCString());
  UNREACHABLE();
}

bool Value::Equals(const Value& other) const {
  return definition() == other.definition();
}

static int OrderById(CidRange* const* a, CidRange* const* b) {
  // Negative if 'a' should sort before 'b'.
  ASSERT((*a)->IsSingleCid());
  ASSERT((*b)->IsSingleCid());
  return (*a)->cid_start - (*b)->cid_start;
}

static int OrderByFrequencyThenId(CidRange* const* a, CidRange* const* b) {
  const TargetInfo* target_info_a = static_cast<const TargetInfo*>(*a);
  const TargetInfo* target_info_b = static_cast<const TargetInfo*>(*b);
  // Negative if 'a' should sort before 'b'.
  if (target_info_b->count != target_info_a->count) {
    return (target_info_b->count - target_info_a->count);
  } else {
    return (*a)->cid_start - (*b)->cid_start;
  }
}

bool Cids::Equals(const Cids& other) const {
  if (length() != other.length()) return false;
  for (int i = 0; i < length(); i++) {
    if (cid_ranges_[i]->cid_start != other.cid_ranges_[i]->cid_start ||
        cid_ranges_[i]->cid_end != other.cid_ranges_[i]->cid_end) {
      return false;
    }
  }
  return true;
}

intptr_t Cids::ComputeLowestCid() const {
  intptr_t min = kIntptrMax;
  for (intptr_t i = 0; i < cid_ranges_.length(); ++i) {
    min = Utils::Minimum(min, cid_ranges_[i]->cid_start);
  }
  return min;
}

intptr_t Cids::ComputeHighestCid() const {
  intptr_t max = -1;
  for (intptr_t i = 0; i < cid_ranges_.length(); ++i) {
    max = Utils::Maximum(max, cid_ranges_[i]->cid_end);
  }
  return max;
}

bool Cids::HasClassId(intptr_t cid) const {
  for (int i = 0; i < length(); i++) {
    if (cid_ranges_[i]->Contains(cid)) {
      return true;
    }
  }
  return false;
}

Cids* Cids::CreateMonomorphic(Zone* zone, intptr_t cid) {
  Cids* cids = new (zone) Cids(zone);
  cids->Add(new (zone) CidRange(cid, cid));
  return cids;
}

Cids* Cids::CreateForArgument(Zone* zone,
                              const BinaryFeedback& binary_feedback,
                              int argument_number) {
  Cids* cids = new (zone) Cids(zone);
  for (intptr_t i = 0; i < binary_feedback.feedback_.length(); i++) {
    ASSERT((argument_number == 0) || (argument_number == 1));
    const intptr_t cid = argument_number == 0
                             ? binary_feedback.feedback_[i].first
                             : binary_feedback.feedback_[i].second;
    cids->Add(new (zone) CidRange(cid, cid));
  }

  if (cids->length() != 0) {
    cids->Sort(OrderById);

    // Merge adjacent class id ranges.
    int dest = 0;
    for (int src = 1; src < cids->length(); src++) {
      if (cids->cid_ranges_[dest]->cid_end + 1 >=
          cids->cid_ranges_[src]->cid_start) {
        cids->cid_ranges_[dest]->cid_end = cids->cid_ranges_[src]->cid_end;
      } else {
        dest++;
        if (src != dest) cids->cid_ranges_[dest] = cids->cid_ranges_[src];
      }
    }
    cids->SetLength(dest + 1);
  }

  return cids;
}

static intptr_t Usage(Thread* thread, const Function& function) {
  intptr_t count = function.usage_counter();
  if (count < 0) {
    if (function.HasCode()) {
      // 'function' is queued for optimized compilation
      count = thread->isolate_group()->optimization_counter_threshold();
    } else {
      count = 0;
    }
  } else if (Code::IsOptimized(function.CurrentCode())) {
    // 'function' was optimized and stopped counting
    count = thread->isolate_group()->optimization_counter_threshold();
  }
  return count;
}

void CallTargets::CreateHelper(Zone* zone, const ICData& ic_data) {
  Function& dummy = Function::Handle(zone);

  const intptr_t num_args_tested = ic_data.NumArgsTested();

  for (int i = 0, n = ic_data.NumberOfChecks(); i < n; i++) {
    if (ic_data.GetCountAt(i) == 0) {
      continue;
    }

    intptr_t id = kDynamicCid;
    if (num_args_tested == 0) {
    } else if (num_args_tested == 1) {
      ic_data.GetOneClassCheckAt(i, &id, &dummy);
    } else {
      ASSERT(num_args_tested == 2);
      GrowableArray<intptr_t> arg_ids;
      ic_data.GetCheckAt(i, &arg_ids, &dummy);
      id = arg_ids[0];
    }
    Function& function = Function::ZoneHandle(zone, ic_data.GetTargetAt(i));
    intptr_t count = ic_data.GetCountAt(i);
    cid_ranges_.Add(new (zone) TargetInfo(id, id, &function, count,
                                          ic_data.GetExactnessAt(i)));
  }

  if (ic_data.is_megamorphic()) {
    ASSERT(num_args_tested == 1);  // Only 1-arg ICData will turn megamorphic.
    const String& name = String::Handle(zone, ic_data.target_name());
    const Array& descriptor =
        Array::Handle(zone, ic_data.arguments_descriptor());
    Thread* thread = Thread::Current();

    const auto& cache = MegamorphicCache::Handle(
        zone, MegamorphicCacheTable::Lookup(thread, name, descriptor));
    {
      SafepointMutexLocker ml(thread->isolate_group()->type_feedback_mutex());
      MegamorphicCacheEntries entries(Array::Handle(zone, cache.buckets()));
      for (intptr_t i = 0, n = entries.Length(); i < n; i++) {
        const intptr_t id =
            Smi::Value(entries[i].Get<MegamorphicCache::kClassIdIndex>());
        if (id == kIllegalCid) {
          continue;
        }
        Function& function = Function::ZoneHandle(zone);
        function ^= entries[i].Get<MegamorphicCache::kTargetFunctionIndex>();
        const intptr_t filled_entry_count = cache.filled_entry_count();
        ASSERT(filled_entry_count > 0);
        cid_ranges_.Add(new (zone) TargetInfo(
            id, id, &function, Usage(thread, function) / filled_entry_count,
            StaticTypeExactnessState::NotTracking()));
      }
    }
  }
}

bool Cids::IsMonomorphic() const {
  if (length() != 1) return false;
  return cid_ranges_[0]->IsSingleCid();
}

intptr_t Cids::MonomorphicReceiverCid() const {
  ASSERT(IsMonomorphic());
  return cid_ranges_[0]->cid_start;
}

StaticTypeExactnessState CallTargets::MonomorphicExactness() const {
  ASSERT(IsMonomorphic());
  return TargetAt(0)->exactness;
}

const char* AssertAssignableInstr::KindToCString(Kind kind) {
  switch (kind) {
#define KIND_CASE(name)                                                        \
  case k##name:                                                                \
    return #name;
    FOR_EACH_ASSERT_ASSIGNABLE_KIND(KIND_CASE)
#undef KIND_CASE
    default:
      UNREACHABLE();
      return nullptr;
  }
}

bool AssertAssignableInstr::ParseKind(const char* str, Kind* out) {
#define KIND_CASE(name)                                                        \
  if (strcmp(str, #name) == 0) {                                               \
    *out = Kind::k##name;                                                      \
    return true;                                                               \
  }
  FOR_EACH_ASSERT_ASSIGNABLE_KIND(KIND_CASE)
#undef KIND_CASE
  return false;
}

CheckClassInstr::CheckClassInstr(Value* value,
                                 intptr_t deopt_id,
                                 const Cids& cids,
                                 const InstructionSource& source)
    : TemplateInstruction(source, deopt_id),
      cids_(cids),
      is_bit_test_(IsCompactCidRange(cids)),
      token_pos_(source.token_pos) {
  // Expected useful check data.
  const intptr_t number_of_checks = cids.length();
  ASSERT(number_of_checks > 0);
  SetInputAt(0, value);
  // Otherwise use CheckSmiInstr.
  ASSERT(number_of_checks != 1 || !cids[0].IsSingleCid() ||
         cids[0].cid_start != kSmiCid);
}

bool CheckClassInstr::AttributesEqual(const Instruction& other) const {
  auto const other_check = other.AsCheckClass();
  ASSERT(other_check != nullptr);
  return cids().Equals(other_check->cids());
}

bool CheckClassInstr::IsDeoptIfNull() const {
  if (!cids().IsMonomorphic()) {
    return false;
  }
  CompileType* in_type = value()->Type();
  const intptr_t cid = cids().MonomorphicReceiverCid();
  // Performance check: use CheckSmiInstr instead.
  ASSERT(cid != kSmiCid);
  return in_type->is_nullable() && (in_type->ToNullableCid() == cid);
}

// Null object is a singleton of null-class (except for some sentinel,
// transitional temporaries). Instead of checking against the null class only
// we can check against null instance instead.
bool CheckClassInstr::IsDeoptIfNotNull() const {
  if (!cids().IsMonomorphic()) {
    return false;
  }
  const intptr_t cid = cids().MonomorphicReceiverCid();
  return cid == kNullCid;
}

bool CheckClassInstr::IsCompactCidRange(const Cids& cids) {
  const intptr_t number_of_checks = cids.length();
  // If there are only two checks, the extra register pressure needed for the
  // dense-cid-range code is not justified.
  if (number_of_checks <= 2) return false;

  // TODO(fschneider): Support smis in dense cid checks.
  if (cids.HasClassId(kSmiCid)) return false;

  intptr_t min = cids.ComputeLowestCid();
  intptr_t max = cids.ComputeHighestCid();
  return (max - min) < compiler::target::kBitsPerWord;
}

bool CheckClassInstr::IsBitTest() const {
  return is_bit_test_;
}

intptr_t CheckClassInstr::ComputeCidMask() const {
  ASSERT(IsBitTest());
  const uintptr_t one = 1;
  intptr_t min = cids_.ComputeLowestCid();
  intptr_t mask = 0;
  for (intptr_t i = 0; i < cids_.length(); ++i) {
    uintptr_t run;
    uintptr_t range = one + cids_[i].Extent();
    if (range >= static_cast<uintptr_t>(compiler::target::kBitsPerWord)) {
      run = -1;
    } else {
      run = (one << range) - 1;
    }
    mask |= run << (cids_[i].cid_start - min);
  }
  return mask;
}

Representation LoadFieldInstr::representation() const {
  return slot().representation();
}

AllocateUninitializedContextInstr::AllocateUninitializedContextInstr(
    const InstructionSource& source,
    intptr_t num_context_variables,
    intptr_t deopt_id)
    : TemplateAllocation(source, deopt_id),
      num_context_variables_(num_context_variables) {
  // This instruction is not used in AOT for code size reasons.
  ASSERT(!CompilerState::Current().is_aot());
}

LocationSummary* AllocateClosureInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = inputs_.length();
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(kFunctionPos,
               Location::RegisterLocation(AllocateClosureABI::kFunctionReg));
  locs->set_in(kContextPos,
               Location::RegisterLocation(AllocateClosureABI::kContextReg));
  locs->set_out(0, Location::RegisterLocation(AllocateClosureABI::kResultReg));
  return locs;
}

void AllocateClosureInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Code& stub = Code::ZoneHandle(
      compiler->zone(),
      compiler->isolate_group()->object_store()->allocate_closure_stub());
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
}

LocationSummary* AllocateTypedDataInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(kLengthPos, Location::RegisterLocation(
                               AllocateTypedDataArrayABI::kLengthReg));
  locs->set_out(
      0, Location::RegisterLocation(AllocateTypedDataArrayABI::kResultReg));
  return locs;
}

void AllocateTypedDataInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Code& stub = Code::ZoneHandle(
      compiler->zone(), StubCode::GetAllocationStubForTypedData(class_id()));
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
}

Representation StoreFieldInstr::RequiredInputRepresentation(
    intptr_t index) const {
  ASSERT((index == 0) || (index == 1));
  if (index == 0) {
    // The instance is always tagged.
    return kTagged;
  }
  return slot().representation();
}

Instruction* StoreFieldInstr::Canonicalize(FlowGraph* flow_graph) {
  // Dart objects are allocated null-initialized, which means we can eliminate
  // all initializing stores which store null value.
  // Context objects can be allocated uninitialized as a performance
  // optimization in JIT mode - however in AOT mode we always allocate them
  // null initialized.
  if (is_initialization_ && slot().representation() == kTagged &&
      (!slot().IsContextSlot() ||
       !instance()->definition()->IsAllocateUninitializedContext()) &&
      value()->BindsToConstantNull()) {
    return nullptr;
  }
  return this;
}

bool GuardFieldClassInstr::AttributesEqual(const Instruction& other) const {
  return field().ptr() == other.AsGuardFieldClass()->field().ptr();
}

bool GuardFieldLengthInstr::AttributesEqual(const Instruction& other) const {
  return field().ptr() == other.AsGuardFieldLength()->field().ptr();
}

bool GuardFieldTypeInstr::AttributesEqual(const Instruction& other) const {
  return field().ptr() == other.AsGuardFieldType()->field().ptr();
}

Instruction* AssertSubtypeInstr::Canonicalize(FlowGraph* flow_graph) {
  // If all inputs needed to check instantiation are constant, instantiate the
  // sub and super type and remove the instruction if the subtype test succeeds.
  if (super_type()->BindsToConstant() && sub_type()->BindsToConstant() &&
      instantiator_type_arguments()->BindsToConstant() &&
      function_type_arguments()->BindsToConstant()) {
    auto Z = Thread::Current()->zone();
    const auto& constant_instantiator_type_args =
        instantiator_type_arguments()->BoundConstant().IsNull()
            ? TypeArguments::null_type_arguments()
            : TypeArguments::Cast(
                  instantiator_type_arguments()->BoundConstant());
    const auto& constant_function_type_args =
        function_type_arguments()->BoundConstant().IsNull()
            ? TypeArguments::null_type_arguments()
            : TypeArguments::Cast(function_type_arguments()->BoundConstant());
    auto& constant_sub_type = AbstractType::Handle(
        Z, AbstractType::Cast(sub_type()->BoundConstant()).ptr());
    auto& constant_super_type = AbstractType::Handle(
        Z, AbstractType::Cast(super_type()->BoundConstant()).ptr());

    if (AbstractType::InstantiateAndTestSubtype(
            &constant_sub_type, &constant_super_type,
            constant_instantiator_type_args, constant_function_type_args)) {
      return nullptr;
    }
  }
  return this;
}

bool StrictCompareInstr::AttributesEqual(const Instruction& other) const {
  auto const other_op = other.AsStrictCompare();
  ASSERT(other_op != nullptr);
  return ComparisonInstr::AttributesEqual(other) &&
         (needs_number_check() == other_op->needs_number_check());
}

const RuntimeEntry& CaseInsensitiveCompareInstr::TargetFunction() const {
  return handle_surrogates_ ? kCaseInsensitiveCompareUTF16RuntimeEntry
                            : kCaseInsensitiveCompareUCS2RuntimeEntry;
}

bool MathMinMaxInstr::AttributesEqual(const Instruction& other) const {
  auto const other_op = other.AsMathMinMax();
  ASSERT(other_op != nullptr);
  return (op_kind() == other_op->op_kind()) &&
         (result_cid() == other_op->result_cid());
}

bool BinaryIntegerOpInstr::AttributesEqual(const Instruction& other) const {
  ASSERT(other.tag() == tag());
  auto const other_op = other.AsBinaryIntegerOp();
  return (op_kind() == other_op->op_kind()) &&
         (can_overflow() == other_op->can_overflow()) &&
         (is_truncating() == other_op->is_truncating());
}

bool LoadFieldInstr::AttributesEqual(const Instruction& other) const {
  auto const other_load = other.AsLoadField();
  ASSERT(other_load != nullptr);
  return &this->slot_ == &other_load->slot_;
}

bool LoadStaticFieldInstr::AttributesEqual(const Instruction& other) const {
  ASSERT(AllowsCSE());
  return field().ptr() == other.AsLoadStaticField()->field().ptr();
}

ConstantInstr::ConstantInstr(const Object& value,
                             const InstructionSource& source)
    : TemplateDefinition(source), value_(value), token_pos_(source.token_pos) {
  // Check that the value is not an incorrect Integer representation.
  ASSERT(!value.IsMint() || !Smi::IsValid(Mint::Cast(value).AsInt64Value()));
  // Check that clones of fields are not stored as constants.
  ASSERT(!value.IsField() || Field::Cast(value).IsOriginal());
  // Check that all non-Smi objects are heap allocated and in old space.
  ASSERT(value.IsSmi() || value.IsOld());
#if defined(DEBUG)
  // Generally, instances in the flow graph should be canonical. Smis, null
  // values, and sentinel values are canonical by construction and so we skip
  // them here.
  if (!value.IsNull() && !value.IsSmi() && value.IsInstance() &&
      !value.IsCanonical() && (value.ptr() != Object::sentinel().ptr())) {
    // Arrays in ConstantInstrs are usually immutable and canonicalized, but
    // the Arrays created as backing for ArgumentsDescriptors may not be
    // canonicalized for space reasons when inlined in the IL. However, they
    // are still immutable.
    //
    // IRRegExp compilation uses TypeData non-canonical values as "constants".
    // Specifically, the bit tables used for certain character classes are
    // represented as TypedData, and so those values are also neither immutable
    // (as there are no immutable TypedData values) or canonical.
    //
    // LibraryPrefixes are also never canonicalized since their equality is
    // their identity.
    ASSERT(value.IsArray() || value.IsTypedData() || value.IsLibraryPrefix());
  }
#endif
}

bool ConstantInstr::AttributesEqual(const Instruction& other) const {
  auto const other_constant = other.AsConstant();
  ASSERT(other_constant != nullptr);
  return (value().ptr() == other_constant->value().ptr() &&
          representation() == other_constant->representation());
}

UnboxedConstantInstr::UnboxedConstantInstr(const Object& value,
                                           Representation representation)
    : ConstantInstr(value),
      representation_(representation),
      constant_address_(0) {
  if (representation_ == kUnboxedDouble) {
    ASSERT(value.IsDouble());
    constant_address_ = FindDoubleConstant(Double::Cast(value).value());
  }
}

// Returns true if the value represents a constant.
bool Value::BindsToConstant() const {
  return definition()->OriginalDefinition()->IsConstant();
}

bool Value::BindsToConstant(ConstantInstr** constant_defn) const {
  if (auto constant = definition()->OriginalDefinition()->AsConstant()) {
    *constant_defn = constant;
    return true;
  }
  return false;
}

// Returns true if the value represents constant null.
bool Value::BindsToConstantNull() const {
  ConstantInstr* constant = definition()->OriginalDefinition()->AsConstant();
  return (constant != nullptr) && constant->value().IsNull();
}

const Object& Value::BoundConstant() const {
  ASSERT(BindsToConstant());
  ConstantInstr* constant = definition()->OriginalDefinition()->AsConstant();
  ASSERT(constant != nullptr);
  return constant->value();
}

bool Value::BindsToSmiConstant() const {
  return BindsToConstant() && BoundConstant().IsSmi();
}

intptr_t Value::BoundSmiConstant() const {
  ASSERT(BindsToSmiConstant());
  return Smi::Cast(BoundConstant()).Value();
}

GraphEntryInstr::GraphEntryInstr(const ParsedFunction& parsed_function,
                                 intptr_t osr_id)
    : GraphEntryInstr(parsed_function,
                      osr_id,
                      CompilerState::Current().GetNextDeoptId()) {}

GraphEntryInstr::GraphEntryInstr(const ParsedFunction& parsed_function,
                                 intptr_t osr_id,
                                 intptr_t deopt_id)
    : BlockEntryWithInitialDefs(0,
                                kInvalidTryIndex,
                                deopt_id,
                                /*stack_depth*/ 0),
      parsed_function_(parsed_function),
      catch_entries_(),
      indirect_entries_(),
      osr_id_(osr_id),
      entry_count_(0),
      spill_slot_count_(0),
      fixed_slot_count_(0) {}

ConstantInstr* GraphEntryInstr::constant_null() {
  ASSERT(initial_definitions()->length() > 0);
  for (intptr_t i = 0; i < initial_definitions()->length(); ++i) {
    ConstantInstr* defn = (*initial_definitions())[i]->AsConstant();
    if (defn != nullptr && defn->value().IsNull()) return defn;
  }
  UNREACHABLE();
  return nullptr;
}

CatchBlockEntryInstr* GraphEntryInstr::GetCatchEntry(intptr_t index) {
  // TODO(fschneider): Sort the catch entries by catch_try_index to avoid
  // searching.
  for (intptr_t i = 0; i < catch_entries_.length(); ++i) {
    if (catch_entries_[i]->catch_try_index() == index) return catch_entries_[i];
  }
  return nullptr;
}

bool GraphEntryInstr::IsCompiledForOsr() const {
  return osr_id_ != Compiler::kNoOSRDeoptId;
}

// ==== Support for visiting flow graphs.

#define DEFINE_ACCEPT(ShortName, Attrs)                                        \
  void ShortName##Instr::Accept(InstructionVisitor* visitor) {                 \
    visitor->Visit##ShortName(this);                                           \
  }

FOR_EACH_INSTRUCTION(DEFINE_ACCEPT)

#undef DEFINE_ACCEPT

void Instruction::SetEnvironment(Environment* deopt_env) {
  intptr_t use_index = 0;
  for (Environment::DeepIterator it(deopt_env); !it.Done(); it.Advance()) {
    Value* use = it.CurrentValue();
    use->set_instruction(this);
    use->set_use_index(use_index++);
  }
  env_ = deopt_env;
}

void Instruction::RemoveEnvironment() {
  for (Environment::DeepIterator it(env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }
  env_ = nullptr;
}

void Instruction::ReplaceInEnvironment(Definition* current,
                                       Definition* replacement) {
  for (Environment::DeepIterator it(env()); !it.Done(); it.Advance()) {
    Value* use = it.CurrentValue();
    if (use->definition() == current) {
      use->RemoveFromUseList();
      use->set_definition(replacement);
      replacement->AddEnvUse(use);
    }
  }
}

Instruction* Instruction::RemoveFromGraph(bool return_previous) {
  ASSERT(!IsBlockEntry());
  ASSERT(!IsBranch());
  ASSERT(!IsThrow());
  ASSERT(!IsReturn());
  ASSERT(!IsReThrow());
  ASSERT(!IsGoto());
  ASSERT(previous() != nullptr);
  // We cannot assert that the instruction, if it is a definition, has no
  // uses.  This function is used to remove instructions from the graph and
  // reinsert them elsewhere (e.g., hoisting).
  Instruction* prev_instr = previous();
  Instruction* next_instr = next();
  ASSERT(next_instr != nullptr);
  ASSERT(!next_instr->IsBlockEntry());
  prev_instr->LinkTo(next_instr);
  UnuseAllInputs();
  // Reset the successor and previous instruction to indicate that the
  // instruction is removed from the graph.
  set_previous(nullptr);
  set_next(nullptr);
  return return_previous ? prev_instr : next_instr;
}

void Instruction::InsertAfter(Instruction* prev) {
  ASSERT(previous_ == nullptr);
  ASSERT(next_ == nullptr);
  previous_ = prev;
  next_ = prev->next_;
  next_->previous_ = this;
  previous_->next_ = this;

  // Update def-use chains whenever instructions are added to the graph
  // after initial graph construction.
  for (intptr_t i = InputCount() - 1; i >= 0; --i) {
    Value* input = InputAt(i);
    input->definition()->AddInputUse(input);
  }
}

Instruction* Instruction::AppendInstruction(Instruction* tail) {
  LinkTo(tail);
  // Update def-use chains whenever instructions are added to the graph
  // after initial graph construction.
  for (intptr_t i = tail->InputCount() - 1; i >= 0; --i) {
    Value* input = tail->InputAt(i);
    input->definition()->AddInputUse(input);
  }
  return tail;
}

BlockEntryInstr* Instruction::GetBlock() {
  // TODO(fschneider): Implement a faster way to get the block of an
  // instruction.
  Instruction* result = previous();
  while ((result != nullptr) && !result->IsBlockEntry()) {
    result = result->previous();
  }
  // InlineExitCollector::RemoveUnreachableExits may call
  // Instruction::GetBlock on instructions which are not properly linked
  // to the flow graph (as collected exits may belong to unreachable
  // fragments), so this code should gracefully handle the absence of
  // BlockEntry.
  return (result != nullptr) ? result->AsBlockEntry() : nullptr;
}

void ForwardInstructionIterator::RemoveCurrentFromGraph() {
  current_ = current_->RemoveFromGraph(true);  // Set current_ to previous.
}

void BackwardInstructionIterator::RemoveCurrentFromGraph() {
  current_ = current_->RemoveFromGraph(false);  // Set current_ to next.
}

// Default implementation of visiting basic blocks.  Can be overridden.
void FlowGraphVisitor::VisitBlocks() {
  ASSERT(current_iterator_ == nullptr);
  for (intptr_t i = 0; i < block_order_->length(); ++i) {
    BlockEntryInstr* entry = (*block_order_)[i];
    entry->Accept(this);
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      it.Current()->Accept(this);
    }
    current_iterator_ = nullptr;
  }
}

bool Value::NeedsWriteBarrier() {
  Value* value = this;
  do {
    if (value->Type()->IsNull() ||
        (value->Type()->ToNullableCid() == kSmiCid) ||
        (value->Type()->ToNullableCid() == kBoolCid)) {
      return false;
    }

    // Strictly speaking, the incremental barrier can only be skipped for
    // immediate objects (Smis) or permanent objects (vm-isolate heap or
    // image pages). Here we choose to skip the barrier for any constant on
    // the assumption it will remain reachable through the object pool.
    if (value->BindsToConstant()) {
      return false;
    }

    // Follow the chain of redefinitions as redefined value could have a more
    // accurate type (for example, AssertAssignable of Smi to a generic T).
    value = value->definition()->RedefinedValue();
  } while (value != nullptr);

  return true;
}

void JoinEntryInstr::AddPredecessor(BlockEntryInstr* predecessor) {
  // Require the predecessors to be sorted by block_id to make managing
  // their corresponding phi inputs simpler.
  intptr_t pred_id = predecessor->block_id();
  intptr_t index = 0;
  while ((index < predecessors_.length()) &&
         (predecessors_[index]->block_id() < pred_id)) {
    ++index;
  }
#if defined(DEBUG)
  for (intptr_t i = index; i < predecessors_.length(); ++i) {
    ASSERT(predecessors_[i]->block_id() != pred_id);
  }
#endif
  predecessors_.InsertAt(index, predecessor);
}

intptr_t JoinEntryInstr::IndexOfPredecessor(BlockEntryInstr* pred) const {
  for (intptr_t i = 0; i < predecessors_.length(); ++i) {
    if (predecessors_[i] == pred) return i;
  }
  return -1;
}

void Value::AddToList(Value* value, Value** list) {
  ASSERT(value->next_use() == nullptr);
  ASSERT(value->previous_use() == nullptr);
  Value* next = *list;
  ASSERT(value != next);
  *list = value;
  value->set_next_use(next);
  value->set_previous_use(nullptr);
  if (next != nullptr) next->set_previous_use(value);
}

void Value::RemoveFromUseList() {
  Definition* def = definition();
  Value* next = next_use();
  if (this == def->input_use_list()) {
    def->set_input_use_list(next);
    if (next != nullptr) next->set_previous_use(nullptr);
  } else if (this == def->env_use_list()) {
    def->set_env_use_list(next);
    if (next != nullptr) next->set_previous_use(nullptr);
  } else if (Value* prev = previous_use()) {
    prev->set_next_use(next);
    if (next != nullptr) next->set_previous_use(prev);
  }

  set_previous_use(nullptr);
  set_next_use(nullptr);
}

// True if the definition has a single input use and is used only in
// environments at the same instruction as that input use.
bool Definition::HasOnlyUse(Value* use) const {
  if (!HasOnlyInputUse(use)) {
    return false;
  }

  Instruction* target = use->instruction();
  for (Value::Iterator it(env_use_list()); !it.Done(); it.Advance()) {
    if (it.Current()->instruction() != target) return false;
  }
  return true;
}

bool Definition::HasOnlyInputUse(Value* use) const {
  return (input_use_list() == use) && (use->next_use() == nullptr);
}

void Definition::ReplaceUsesWith(Definition* other) {
  ASSERT(other != nullptr);
  ASSERT(this != other);

  Value* current = nullptr;
  Value* next = input_use_list();
  if (next != nullptr) {
    // Change all the definitions.
    while (next != nullptr) {
      current = next;
      current->set_definition(other);
      current->RefineReachingType(other->Type());
      next = current->next_use();
    }

    // Concatenate the lists.
    next = other->input_use_list();
    current->set_next_use(next);
    if (next != nullptr) next->set_previous_use(current);
    other->set_input_use_list(input_use_list());
    set_input_use_list(nullptr);
  }

  // Repeat for environment uses.
  current = nullptr;
  next = env_use_list();
  if (next != nullptr) {
    while (next != nullptr) {
      current = next;
      current->set_definition(other);
      current->RefineReachingType(other->Type());
      next = current->next_use();
    }
    next = other->env_use_list();
    current->set_next_use(next);
    if (next != nullptr) next->set_previous_use(current);
    other->set_env_use_list(env_use_list());
    set_env_use_list(nullptr);
  }
}

void Instruction::UnuseAllInputs() {
  for (intptr_t i = InputCount() - 1; i >= 0; --i) {
    InputAt(i)->RemoveFromUseList();
  }
  for (Environment::DeepIterator it(env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }
}

void Instruction::RepairArgumentUsesInEnvironment() const {
  // Some calls (e.g. closure calls) have more inputs than actual arguments.
  // Those extra inputs will be consumed from the stack before the call.
  const intptr_t after_args_input_count = env()->LazyDeoptPruneCount();
  MoveArgumentsArray* move_arguments = GetMoveArguments();
  ASSERT(move_arguments != nullptr);
  const intptr_t arg_count = ArgumentCount();
  ASSERT((arg_count + after_args_input_count) <= env()->Length());
  const intptr_t env_base =
      env()->Length() - arg_count - after_args_input_count;
  for (intptr_t i = 0; i < arg_count; ++i) {
    env()->ValueAt(env_base + i)->BindToEnvironment(move_arguments->At(i));
  }
}

void Instruction::InheritDeoptTargetAfter(FlowGraph* flow_graph,
                                          Definition* call,
                                          Definition* result) {
  ASSERT(call->env() != nullptr);
  deopt_id_ = DeoptId::ToDeoptAfter(call->deopt_id_);
  call->env()->DeepCopyAfterTo(
      flow_graph->zone(), this, call->ArgumentCount(),
      flow_graph->constant_dead(),
      result != nullptr ? result : flow_graph->constant_dead());
}

void Instruction::InheritDeoptTarget(Zone* zone, Instruction* other) {
  ASSERT(other->env() != nullptr);
  CopyDeoptIdFrom(*other);
  other->env()->DeepCopyTo(zone, this);
}

bool Instruction::IsDominatedBy(Instruction* dom) {
  BlockEntryInstr* block = GetBlock();
  BlockEntryInstr* dom_block = dom->GetBlock();

  if (dom->IsPhi()) {
    dom = dom_block;
  }

  if (block == dom_block) {
    if ((block == dom) || (this == block->last_instruction())) {
      return true;
    }

    if (IsPhi()) {
      return false;
    }

    for (Instruction* curr = dom->next(); curr != nullptr;
         curr = curr->next()) {
      if (curr == this) return true;
    }

    return false;
  }

  return dom_block->Dominates(block);
}

bool Instruction::HasUnmatchedInputRepresentations() const {
  for (intptr_t i = 0; i < InputCount(); i++) {
    Definition* input = InputAt(i)->definition();
    const Representation input_representation = RequiredInputRepresentation(i);
    if (input_representation != kNoRepresentation &&
        input_representation != input->representation()) {
      return true;
    }
  }

  return false;
}

const intptr_t Instruction::kInstructionAttrs[Instruction::kNumInstructions] = {
#define INSTR_ATTRS(type, attrs) InstrAttrs::attrs,
    FOR_EACH_INSTRUCTION(INSTR_ATTRS)
#undef INSTR_ATTRS
};

bool Instruction::CanTriggerGC() const {
  return (kInstructionAttrs[tag()] & InstrAttrs::kNoGC) == 0;
}

void Definition::ReplaceWithResult(Instruction* replacement,
                                   Definition* replacement_for_uses,
                                   ForwardInstructionIterator* iterator) {
  // Record replacement's input uses.
  for (intptr_t i = replacement->InputCount() - 1; i >= 0; --i) {
    Value* input = replacement->InputAt(i);
    input->definition()->AddInputUse(input);
  }
  // Take replacement's environment from this definition.
  ASSERT(replacement->env() == nullptr);
  replacement->SetEnvironment(env());
  ClearEnv();
  // Replace all uses of this definition with replacement_for_uses.
  ReplaceUsesWith(replacement_for_uses);

  // Finally replace this one with the replacement instruction in the graph.
  previous()->LinkTo(replacement);
  if ((iterator != nullptr) && (this == iterator->Current())) {
    // Remove through the iterator.
    replacement->LinkTo(this);
    iterator->RemoveCurrentFromGraph();
  } else {
    replacement->LinkTo(next());
    // Remove this definition's input uses.
    UnuseAllInputs();
  }
  set_previous(nullptr);
  set_next(nullptr);
}

void Definition::ReplaceWith(Definition* other,
                             ForwardInstructionIterator* iterator) {
  // Reuse this instruction's SSA name for other.
  ASSERT(!other->HasSSATemp());
  if (HasSSATemp()) {
    other->set_ssa_temp_index(ssa_temp_index());
  }
  ReplaceWithResult(other, other, iterator);
}

void BranchInstr::SetComparison(ComparisonInstr* new_comparison) {
  for (intptr_t i = new_comparison->InputCount() - 1; i >= 0; --i) {
    Value* input = new_comparison->InputAt(i);
    input->definition()->AddInputUse(input);
    input->set_instruction(this);
  }
  // There should be no need to copy or unuse an environment.
  ASSERT(comparison()->env() == nullptr);
  ASSERT(new_comparison->env() == nullptr);
  // Remove the current comparison's input uses.
  comparison()->UnuseAllInputs();
  ASSERT(!new_comparison->HasUses());
  comparison_ = new_comparison;
}

// ==== Postorder graph traversal.
static bool IsMarked(BlockEntryInstr* block,
                     GrowableArray<BlockEntryInstr*>* preorder) {
  // Detect that a block has been visited as part of the current
  // DiscoverBlocks (we can call DiscoverBlocks multiple times).  The block
  // will be 'marked' by (1) having a preorder number in the range of the
  // preorder array and (2) being in the preorder array at that index.
  intptr_t i = block->preorder_number();
  return (i >= 0) && (i < preorder->length()) && ((*preorder)[i] == block);
}

// Base class implementation used for JoinEntry and TargetEntry.
bool BlockEntryInstr::DiscoverBlock(BlockEntryInstr* predecessor,
                                    GrowableArray<BlockEntryInstr*>* preorder,
                                    GrowableArray<intptr_t>* parent) {
  // If this block has a predecessor (i.e., is not the graph entry) we can
  // assume the preorder array is non-empty.
  ASSERT((predecessor == nullptr) || !preorder->is_empty());
  // Blocks with a single predecessor cannot have been reached before.
  ASSERT(IsJoinEntry() || !IsMarked(this, preorder));

  // 1. If the block has already been reached, add current_block as a
  // basic-block predecessor and we are done.
  if (IsMarked(this, preorder)) {
    ASSERT(predecessor != nullptr);
    AddPredecessor(predecessor);
    return false;
  }

  // 2. Otherwise, clear the predecessors which might have been computed on
  // some earlier call to DiscoverBlocks and record this predecessor.
  ClearPredecessors();
  if (predecessor != nullptr) AddPredecessor(predecessor);

  // 3. The predecessor is the spanning-tree parent.  The graph entry has no
  // parent, indicated by -1.
  intptr_t parent_number =
      (predecessor == nullptr) ? -1 : predecessor->preorder_number();
  parent->Add(parent_number);

  // 4. Assign the preorder number and add the block entry to the list.
  set_preorder_number(preorder->length());
  preorder->Add(this);

  // The preorder and parent arrays are indexed by
  // preorder block number, so they should stay in lockstep.
  ASSERT(preorder->length() == parent->length());

  // 5. Iterate straight-line successors to record assigned variables and
  // find the last instruction in the block.  The graph entry block consists
  // of only the entry instruction, so that is the last instruction in the
  // block.
  Instruction* last = this;
  for (ForwardInstructionIterator it(this); !it.Done(); it.Advance()) {
    last = it.Current();
  }
  set_last_instruction(last);
  if (last->IsGoto()) last->AsGoto()->set_block(this);

  return true;
}

void GraphEntryInstr::RelinkToOsrEntry(Zone* zone, intptr_t max_block_id) {
  ASSERT(osr_id_ != Compiler::kNoOSRDeoptId);
  BitVector* block_marks = new (zone) BitVector(zone, max_block_id + 1);
  bool found = FindOsrEntryAndRelink(this, /*parent=*/nullptr, block_marks);
  ASSERT(found);
}

bool BlockEntryInstr::FindOsrEntryAndRelink(GraphEntryInstr* graph_entry,
                                            Instruction* parent,
                                            BitVector* block_marks) {
  const intptr_t osr_id = graph_entry->osr_id();

  // Search for the instruction with the OSR id.  Use a depth first search
  // because basic blocks have not been discovered yet.  Prune unreachable
  // blocks by replacing the normal entry with a jump to the block
  // containing the OSR entry point.

  // Do not visit blocks more than once.
  if (block_marks->Contains(block_id())) return false;
  block_marks->Add(block_id());

  // Search this block for the OSR id.
  Instruction* instr = this;
  for (ForwardInstructionIterator it(this); !it.Done(); it.Advance()) {
    instr = it.Current();
    if (instr->GetDeoptId() == osr_id) {
      // Sanity check that we found a stack check instruction.
      ASSERT(instr->IsCheckStackOverflow());
      // Loop stack check checks are always in join blocks so that they can
      // be the target of a goto.
      ASSERT(IsJoinEntry());
      // The instruction should be the first instruction in the block so
      // we can simply jump to the beginning of the block.
      ASSERT(instr->previous() == this);

      ASSERT(stack_depth() == instr->AsCheckStackOverflow()->stack_depth());
      auto normal_entry = graph_entry->normal_entry();
      auto osr_entry = new OsrEntryInstr(
          graph_entry, normal_entry->block_id(), normal_entry->try_index(),
          normal_entry->deopt_id(), stack_depth());

      auto goto_join = new GotoInstr(AsJoinEntry(),
                                     CompilerState::Current().GetNextDeoptId());
      ASSERT(parent != nullptr);
      goto_join->CopyDeoptIdFrom(*parent);
      osr_entry->LinkTo(goto_join);

      // Remove normal function entries & add osr entry.
      graph_entry->set_normal_entry(nullptr);
      graph_entry->set_unchecked_entry(nullptr);
      graph_entry->set_osr_entry(osr_entry);

      return true;
    }
  }

  // Recursively search the successors.
  for (intptr_t i = instr->SuccessorCount() - 1; i >= 0; --i) {
    if (instr->SuccessorAt(i)->FindOsrEntryAndRelink(graph_entry, instr,
                                                     block_marks)) {
      return true;
    }
  }
  return false;
}

bool BlockEntryInstr::Dominates(BlockEntryInstr* other) const {
  // TODO(fschneider): Make this faster by e.g. storing dominators for each
  // block while computing the dominator tree.
  ASSERT(other != nullptr);
  BlockEntryInstr* current = other;
  while (current != nullptr && current != this) {
    current = current->dominator();
  }
  return current == this;
}

BlockEntryInstr* BlockEntryInstr::ImmediateDominator() const {
  Instruction* last = dominator()->last_instruction();
  if ((last->SuccessorCount() == 1) && (last->SuccessorAt(0) == this)) {
    return dominator();
  }
  return nullptr;
}

bool BlockEntryInstr::IsLoopHeader() const {
  return loop_info_ != nullptr && loop_info_->header() == this;
}

intptr_t BlockEntryInstr::NestingDepth() const {
  return loop_info_ == nullptr ? 0 : loop_info_->NestingDepth();
}

// Helper to mutate the graph during inlining. This block should be
// replaced with new_block as a predecessor of all of this block's
// successors.  For each successor, the predecessors will be reordered
// to preserve block-order sorting of the predecessors as well as the
// phis if the successor is a join.
void BlockEntryInstr::ReplaceAsPredecessorWith(BlockEntryInstr* new_block) {
  // Set the last instruction of the new block to that of the old block.
  Instruction* last = last_instruction();
  new_block->set_last_instruction(last);
  // For each successor, update the predecessors.
  for (intptr_t sidx = 0; sidx < last->SuccessorCount(); ++sidx) {
    // If the successor is a target, update its predecessor.
    TargetEntryInstr* target = last->SuccessorAt(sidx)->AsTargetEntry();
    if (target != nullptr) {
      target->predecessor_ = new_block;
      continue;
    }
    // If the successor is a join, update each predecessor and the phis.
    JoinEntryInstr* join = last->SuccessorAt(sidx)->AsJoinEntry();
    ASSERT(join != nullptr);
    // Find the old predecessor index.
    intptr_t old_index = join->IndexOfPredecessor(this);
    intptr_t pred_count = join->PredecessorCount();
    ASSERT(old_index >= 0);
    ASSERT(old_index < pred_count);
    // Find the new predecessor index while reordering the predecessors.
    intptr_t new_id = new_block->block_id();
    intptr_t new_index = old_index;
    if (block_id() < new_id) {
      // Search upwards, bubbling down intermediate predecessors.
      for (; new_index < pred_count - 1; ++new_index) {
        if (join->predecessors_[new_index + 1]->block_id() > new_id) break;
        join->predecessors_[new_index] = join->predecessors_[new_index + 1];
      }
    } else {
      // Search downwards, bubbling up intermediate predecessors.
      for (; new_index > 0; --new_index) {
        if (join->predecessors_[new_index - 1]->block_id() < new_id) break;
        join->predecessors_[new_index] = join->predecessors_[new_index - 1];
      }
    }
    join->predecessors_[new_index] = new_block;
    // If the new and old predecessor index match there is nothing to update.
    if ((join->phis() == nullptr) || (old_index == new_index)) return;
    // Otherwise, reorder the predecessor uses in each phi.
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      ASSERT(phi != nullptr);
      ASSERT(pred_count == phi->InputCount());
      // Save the predecessor use.
      Value* pred_use = phi->InputAt(old_index);
      // Move uses between old and new.
      intptr_t step = (old_index < new_index) ? 1 : -1;
      for (intptr_t use_idx = old_index; use_idx != new_index;
           use_idx += step) {
        phi->SetInputAt(use_idx, phi->InputAt(use_idx + step));
      }
      // Write the predecessor use.
      phi->SetInputAt(new_index, pred_use);
    }
  }
}

void BlockEntryInstr::ClearAllInstructions() {
  JoinEntryInstr* join = this->AsJoinEntry();
  if (join != nullptr) {
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      it.Current()->UnuseAllInputs();
    }
  }
  UnuseAllInputs();
  for (ForwardInstructionIterator it(this); !it.Done(); it.Advance()) {
    it.Current()->UnuseAllInputs();
  }
}

PhiInstr* JoinEntryInstr::InsertPhi(intptr_t var_index, intptr_t var_count) {
  // Lazily initialize the array of phis.
  // Currently, phis are stored in a sparse array that holds the phi
  // for variable with index i at position i.
  // TODO(fschneider): Store phis in a more compact way.
  if (phis_ == nullptr) {
    phis_ = new ZoneGrowableArray<PhiInstr*>(var_count);
    for (intptr_t i = 0; i < var_count; i++) {
      phis_->Add(nullptr);
    }
  }
  ASSERT((*phis_)[var_index] == nullptr);
  return (*phis_)[var_index] = new PhiInstr(this, PredecessorCount());
}

void JoinEntryInstr::InsertPhi(PhiInstr* phi) {
  // Lazily initialize the array of phis.
  if (phis_ == nullptr) {
    phis_ = new ZoneGrowableArray<PhiInstr*>(1);
  }
  phis_->Add(phi);
}

void JoinEntryInstr::RemovePhi(PhiInstr* phi) {
  ASSERT(phis_ != nullptr);
  for (intptr_t index = 0; index < phis_->length(); ++index) {
    if (phi == (*phis_)[index]) {
      (*phis_)[index] = phis_->Last();
      phis_->RemoveLast();
      return;
    }
  }
}

void JoinEntryInstr::RemoveDeadPhis(Definition* replacement) {
  if (phis_ == nullptr) return;

  intptr_t to_index = 0;
  for (intptr_t from_index = 0; from_index < phis_->length(); ++from_index) {
    PhiInstr* phi = (*phis_)[from_index];
    if (phi != nullptr) {
      if (phi->is_alive()) {
        (*phis_)[to_index++] = phi;
        for (intptr_t i = phi->InputCount() - 1; i >= 0; --i) {
          Value* input = phi->InputAt(i);
          input->definition()->AddInputUse(input);
        }
      } else {
        phi->ReplaceUsesWith(replacement);
      }
    }
  }
  if (to_index == 0) {
    phis_ = nullptr;
  } else {
    phis_->TruncateTo(to_index);
  }
}

intptr_t Instruction::SuccessorCount() const {
  return 0;
}

BlockEntryInstr* Instruction::SuccessorAt(intptr_t index) const {
  // Called only if index is in range.  Only control-transfer instructions
  // can have non-zero successor counts and they override this function.
  UNREACHABLE();
  return nullptr;
}

intptr_t GraphEntryInstr::SuccessorCount() const {
  return (normal_entry() == nullptr ? 0 : 1) +
         (unchecked_entry() == nullptr ? 0 : 1) +
         (osr_entry() == nullptr ? 0 : 1) + catch_entries_.length();
}

BlockEntryInstr* GraphEntryInstr::SuccessorAt(intptr_t index) const {
  if (normal_entry() != nullptr) {
    if (index == 0) return normal_entry_;
    index--;
  }
  if (unchecked_entry() != nullptr) {
    if (index == 0) return unchecked_entry();
    index--;
  }
  if (osr_entry() != nullptr) {
    if (index == 0) return osr_entry();
    index--;
  }
  return catch_entries_[index];
}

intptr_t BranchInstr::SuccessorCount() const {
  return 2;
}

BlockEntryInstr* BranchInstr::SuccessorAt(intptr_t index) const {
  if (index == 0) return true_successor_;
  if (index == 1) return false_successor_;
  UNREACHABLE();
  return nullptr;
}

intptr_t GotoInstr::SuccessorCount() const {
  return 1;
}

BlockEntryInstr* GotoInstr::SuccessorAt(intptr_t index) const {
  ASSERT(index == 0);
  return successor();
}

void Instruction::Goto(JoinEntryInstr* entry) {
  LinkTo(new GotoInstr(entry, CompilerState::Current().GetNextDeoptId()));
}

bool IntConverterInstr::ComputeCanDeoptimize() const {
  return (to() == kUnboxedInt32) && !is_truncating() &&
         !RangeUtils::Fits(value()->definition()->range(),
                           RangeBoundary::kRangeBoundaryInt32);
}

bool UnboxInt32Instr::ComputeCanDeoptimize() const {
  if (SpeculativeModeOfInputs() == kNotSpeculative) {
    return false;
  }
  const intptr_t value_cid = value()->Type()->ToCid();
  if (value_cid == kSmiCid) {
    return (compiler::target::kSmiBits > 32) && !is_truncating() &&
           !RangeUtils::Fits(value()->definition()->range(),
                             RangeBoundary::kRangeBoundaryInt32);
  } else if (value_cid == kMintCid) {
    return !is_truncating() &&
           !RangeUtils::Fits(value()->definition()->range(),
                             RangeBoundary::kRangeBoundaryInt32);
  } else if (is_truncating() && value()->definition()->IsBoxInteger()) {
    return false;
  } else if ((compiler::target::kSmiBits < 32) && value()->Type()->IsInt()) {
    return !RangeUtils::Fits(value()->definition()->range(),
                             RangeBoundary::kRangeBoundaryInt32);
  } else {
    return true;
  }
}

bool UnboxUint32Instr::ComputeCanDeoptimize() const {
  ASSERT(is_truncating());
  if (SpeculativeModeOfInputs() == kNotSpeculative) {
    return false;
  }
  if ((value()->Type()->ToCid() == kSmiCid) ||
      (value()->Type()->ToCid() == kMintCid)) {
    return false;
  }
  // Check input value's range.
  Range* value_range = value()->definition()->range();
  return !RangeUtils::Fits(value_range, RangeBoundary::kRangeBoundaryInt64);
}

bool BinaryInt32OpInstr::ComputeCanDeoptimize() const {
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      return false;

    case Token::kSHR:
      return false;

    case Token::kUSHR:
    case Token::kSHL:
      // Currently only shifts by in range constant are supported, see
      // BinaryInt32OpInstr::IsSupported.
      return can_overflow();

    case Token::kMOD: {
      UNREACHABLE();
    }

    default:
      return can_overflow();
  }
}

bool BinarySmiOpInstr::ComputeCanDeoptimize() const {
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      return false;

    case Token::kSHR:
      return !RangeUtils::IsPositive(right_range());

    case Token::kUSHR:
    case Token::kSHL:
      return can_overflow() || !RangeUtils::IsPositive(right_range());

    case Token::kMOD:
      return RangeUtils::CanBeZero(right_range());

    case Token::kTRUNCDIV:
      return RangeUtils::CanBeZero(right_range()) ||
             RangeUtils::Overlaps(right_range(), -1, -1);

    default:
      return can_overflow();
  }
}

bool ShiftIntegerOpInstr::IsShiftCountInRange(int64_t max) const {
  return RangeUtils::IsWithin(shift_range(), 0, max);
}

bool BinaryIntegerOpInstr::RightIsPowerOfTwoConstant() const {
  if (!right()->definition()->IsConstant()) return false;
  const Object& constant = right()->definition()->AsConstant()->value();
  if (!constant.IsSmi()) return false;
  const intptr_t int_value = Smi::Cast(constant).Value();
  ASSERT(int_value != kIntptrMin);
  return Utils::IsPowerOfTwo(Utils::Abs(int_value));
}

static intptr_t RepresentationBits(Representation r) {
  switch (r) {
    case kTagged:
      return compiler::target::kSmiBits + 1;
    case kUnboxedInt32:
    case kUnboxedUint32:
      return 32;
    case kUnboxedInt64:
      return 64;
    default:
      UNREACHABLE();
      return 0;
  }
}

static int64_t RepresentationMask(Representation r) {
  return static_cast<int64_t>(static_cast<uint64_t>(-1) >>
                              (64 - RepresentationBits(r)));
}

static Definition* CanonicalizeCommutativeDoubleArithmetic(Token::Kind op,
                                                           Value* left,
                                                           Value* right) {
  int64_t left_value;
  if (!Evaluator::ToIntegerConstant(left, &left_value)) {
    return nullptr;
  }

  // Can't apply 0.0 * x -> 0.0 equivalence to double operation because
  // 0.0 * NaN is NaN not 0.0.
  // Can't apply 0.0 + x -> x to double because 0.0 + (-0.0) is 0.0 not -0.0.
  switch (op) {
    case Token::kMUL:
      if (left_value == 1) {
        if (right->definition()->representation() != kUnboxedDouble) {
          // Can't yet apply the equivalence because representation selection
          // did not run yet. We need it to guarantee that right value is
          // correctly coerced to double. The second canonicalization pass
          // will apply this equivalence.
          return nullptr;
        } else {
          return right->definition();
        }
      }
      break;
    default:
      break;
  }

  return nullptr;
}

Definition* DoubleToFloatInstr::Canonicalize(FlowGraph* flow_graph) {
#ifdef DEBUG
  // Must only be used in Float32 StoreIndexedInstr, FloatToDoubleInstr,
  // Phis introduce by load forwarding, or MaterializeObject for
  // eliminated Float32 array.
  ASSERT(env_use_list() == nullptr);
  for (Value* use = input_use_list(); use != nullptr; use = use->next_use()) {
    ASSERT(use->instruction()->IsPhi() ||
           use->instruction()->IsFloatToDouble() ||
           (use->instruction()->IsStoreIndexed() &&
            (use->instruction()->AsStoreIndexed()->class_id() ==
             kTypedDataFloat32ArrayCid)) ||
           (use->instruction()->IsMaterializeObject() &&
            (use->instruction()->AsMaterializeObject()->cls().id() ==
             kTypedDataFloat32ArrayCid)));
  }
#endif
  if (!HasUses()) return nullptr;
  if (value()->definition()->IsFloatToDouble()) {
    // F2D(D2F(v)) == v.
    return value()->definition()->AsFloatToDouble()->value()->definition();
  }
  return this;
}

Definition* FloatToDoubleInstr::Canonicalize(FlowGraph* flow_graph) {
  return HasUses() ? this : nullptr;
}

Definition* BinaryDoubleOpInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return nullptr;

  Definition* result = nullptr;

  result = CanonicalizeCommutativeDoubleArithmetic(op_kind(), left(), right());
  if (result != nullptr) {
    return result;
  }

  result = CanonicalizeCommutativeDoubleArithmetic(op_kind(), right(), left());
  if (result != nullptr) {
    return result;
  }

  if ((op_kind() == Token::kMUL) &&
      (left()->definition() == right()->definition())) {
    MathUnaryInstr* math_unary = new MathUnaryInstr(
        MathUnaryInstr::kDoubleSquare, new Value(left()->definition()),
        DeoptimizationTarget());
    flow_graph->InsertBefore(this, math_unary, env(), FlowGraph::kValue);
    return math_unary;
  }

  return this;
}

Definition* DoubleTestOpInstr::Canonicalize(FlowGraph* flow_graph) {
  return HasUses() ? this : nullptr;
}

static bool IsCommutative(Token::Kind op) {
  switch (op) {
    case Token::kMUL:
      FALL_THROUGH;
    case Token::kADD:
      FALL_THROUGH;
    case Token::kBIT_AND:
      FALL_THROUGH;
    case Token::kBIT_OR:
      FALL_THROUGH;
    case Token::kBIT_XOR:
      return true;
    default:
      return false;
  }
}

UnaryIntegerOpInstr* UnaryIntegerOpInstr::Make(Representation representation,
                                               Token::Kind op_kind,
                                               Value* value,
                                               intptr_t deopt_id,
                                               Range* range) {
  UnaryIntegerOpInstr* op = nullptr;
  switch (representation) {
    case kTagged:
      op = new UnarySmiOpInstr(op_kind, value, deopt_id);
      break;
    case kUnboxedInt32:
      return nullptr;
    case kUnboxedUint32:
      op = new UnaryUint32OpInstr(op_kind, value, deopt_id);
      break;
    case kUnboxedInt64:
      op = new UnaryInt64OpInstr(op_kind, value, deopt_id);
      break;
    default:
      UNREACHABLE();
      return nullptr;
  }

  if (op == nullptr) {
    return op;
  }

  if (!Range::IsUnknown(range)) {
    op->set_range(*range);
  }

  ASSERT(op->representation() == representation);
  return op;
}

BinaryIntegerOpInstr* BinaryIntegerOpInstr::Make(
    Representation representation,
    Token::Kind op_kind,
    Value* left,
    Value* right,
    intptr_t deopt_id,
    SpeculativeMode speculative_mode) {
  BinaryIntegerOpInstr* op = nullptr;
  Range* right_range = nullptr;
  switch (op_kind) {
    case Token::kMOD:
    case Token::kTRUNCDIV:
      if (representation != kTagged) break;
      FALL_THROUGH;
    case Token::kSHL:
    case Token::kSHR:
    case Token::kUSHR:
      if (auto const const_def = right->definition()->AsConstant()) {
        right_range = new Range();
        const_def->InferRange(nullptr, right_range);
      }
      break;
    default:
      break;
  }
  switch (representation) {
    case kTagged:
      op = new BinarySmiOpInstr(op_kind, left, right, deopt_id, right_range);
      break;
    case kUnboxedInt32:
      if (!BinaryInt32OpInstr::IsSupported(op_kind, left, right)) {
        return nullptr;
      }
      op = new BinaryInt32OpInstr(op_kind, left, right, deopt_id);
      break;
    case kUnboxedUint32:
      if ((op_kind == Token::kSHL) || (op_kind == Token::kSHR) ||
          (op_kind == Token::kUSHR)) {
        if (speculative_mode == kNotSpeculative) {
          op = new ShiftUint32OpInstr(op_kind, left, right, deopt_id,
                                      right_range);
        } else {
          op = new SpeculativeShiftUint32OpInstr(op_kind, left, right, deopt_id,
                                                 right_range);
        }
      } else {
        op = new BinaryUint32OpInstr(op_kind, left, right, deopt_id);
      }
      break;
    case kUnboxedInt64:
      if ((op_kind == Token::kSHL) || (op_kind == Token::kSHR) ||
          (op_kind == Token::kUSHR)) {
        if (speculative_mode == kNotSpeculative) {
          op = new ShiftInt64OpInstr(op_kind, left, right, deopt_id,
                                     right_range);
        } else {
          op = new SpeculativeShiftInt64OpInstr(op_kind, left, right, deopt_id,
                                                right_range);
        }
      } else {
        op = new BinaryInt64OpInstr(op_kind, left, right, deopt_id);
      }
      break;
    default:
      UNREACHABLE();
      return nullptr;
  }

  ASSERT(op->representation() == representation);
  return op;
}

BinaryIntegerOpInstr* BinaryIntegerOpInstr::Make(
    Representation representation,
    Token::Kind op_kind,
    Value* left,
    Value* right,
    intptr_t deopt_id,
    bool can_overflow,
    bool is_truncating,
    Range* range,
    SpeculativeMode speculative_mode) {
  BinaryIntegerOpInstr* op = BinaryIntegerOpInstr::Make(
      representation, op_kind, left, right, deopt_id, speculative_mode);
  if (op == nullptr) {
    return nullptr;
  }
  if (!Range::IsUnknown(range)) {
    op->set_range(*range);
  }

  op->set_can_overflow(can_overflow);
  if (is_truncating) {
    op->mark_truncating();
  }

  return op;
}

Definition* BinaryIntegerOpInstr::Canonicalize(FlowGraph* flow_graph) {
  // If both operands are constants evaluate this expression. Might
  // occur due to load forwarding after constant propagation pass
  // have already been run.

  if (left()->BindsToConstant() && right()->BindsToConstant()) {
    const Integer& result = Integer::Handle(Evaluator::BinaryIntegerEvaluate(
        left()->BoundConstant(), right()->BoundConstant(), op_kind(),
        is_truncating(), representation(), Thread::Current()));

    if (!result.IsNull()) {
      return flow_graph->TryCreateConstantReplacementFor(this, result);
    }
  }

  if (left()->BindsToConstant() && !right()->BindsToConstant() &&
      IsCommutative(op_kind())) {
    Value* l = left();
    Value* r = right();
    SetInputAt(0, r);
    SetInputAt(1, l);
  }

  int64_t rhs;
  if (!Evaluator::ToIntegerConstant(right(), &rhs)) {
    return this;
  }

  if (is_truncating()) {
    switch (op_kind()) {
      case Token::kMUL:
      case Token::kSUB:
      case Token::kADD:
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
        rhs = Evaluator::TruncateTo(rhs, representation());
        break;
      default:
        break;
    }
  }

  switch (op_kind()) {
    case Token::kMUL:
      if (rhs == 1) {
        return left()->definition();
      } else if (rhs == 0) {
        return right()->definition();
      } else if ((rhs > 0) && Utils::IsPowerOfTwo(rhs)) {
        const int64_t shift_amount = Utils::ShiftForPowerOfTwo(rhs);
        ConstantInstr* constant_shift_amount = flow_graph->GetConstant(
            Smi::Handle(Smi::New(shift_amount)), representation());
        BinaryIntegerOpInstr* shift = BinaryIntegerOpInstr::Make(
            representation(), Token::kSHL, left()->CopyWithType(),
            new Value(constant_shift_amount), GetDeoptId(), can_overflow(),
            is_truncating(), range(), SpeculativeModeOfInputs());
        if (shift != nullptr) {
          // Assign a range to the shift factor, just in case range
          // analysis no longer runs after this rewriting.
          if (auto shift_with_range = shift->AsShiftIntegerOp()) {
            shift_with_range->set_shift_range(
                new Range(RangeBoundary::FromConstant(shift_amount),
                          RangeBoundary::FromConstant(shift_amount)));
          }
          if (!MayThrow()) {
            ASSERT(!shift->MayThrow());
          }
          if (!CanDeoptimize()) {
            ASSERT(!shift->CanDeoptimize());
          }
          flow_graph->InsertBefore(this, shift, env(), FlowGraph::kValue);
          return shift;
        }
      }

      break;
    case Token::kADD:
      if (rhs == 0) {
        return left()->definition();
      }
      break;
    case Token::kBIT_AND:
      if (rhs == 0) {
        return right()->definition();
      } else if (rhs == RepresentationMask(representation())) {
        return left()->definition();
      }
      break;
    case Token::kBIT_OR:
      if (rhs == 0) {
        return left()->definition();
      } else if (rhs == RepresentationMask(representation())) {
        return right()->definition();
      }
      break;
    case Token::kBIT_XOR:
      if (rhs == 0) {
        return left()->definition();
      } else if (rhs == RepresentationMask(representation())) {
        UnaryIntegerOpInstr* bit_not = UnaryIntegerOpInstr::Make(
            representation(), Token::kBIT_NOT, left()->CopyWithType(),
            GetDeoptId(), range());
        if (bit_not != nullptr) {
          flow_graph->InsertBefore(this, bit_not, env(), FlowGraph::kValue);
          return bit_not;
        }
      }
      break;

    case Token::kSUB:
      if (rhs == 0) {
        return left()->definition();
      }
      break;

    case Token::kTRUNCDIV:
      if (rhs == 1) {
        return left()->definition();
      } else if (rhs == -1) {
        UnaryIntegerOpInstr* negation = UnaryIntegerOpInstr::Make(
            representation(), Token::kNEGATE, left()->CopyWithType(),
            GetDeoptId(), range());
        if (negation != nullptr) {
          flow_graph->InsertBefore(this, negation, env(), FlowGraph::kValue);
          return negation;
        }
      }
      break;

    case Token::kMOD:
      if (std::abs(rhs) == 1) {
        return flow_graph->TryCreateConstantReplacementFor(this,
                                                           Object::smi_zero());
      }
      break;

    case Token::kUSHR:
      if (rhs >= kBitsPerInt64) {
        return flow_graph->TryCreateConstantReplacementFor(this,
                                                           Object::smi_zero());
      }
      FALL_THROUGH;
    case Token::kSHR:
      if (rhs == 0) {
        return left()->definition();
      } else if (rhs < 0) {
        // Instruction will always throw on negative rhs operand.
        if (!CanDeoptimize()) {
          // For non-speculative operations (no deopt), let
          // the code generator deal with throw on slowpath.
          break;
        }
        ASSERT(GetDeoptId() != DeoptId::kNone);
        DeoptimizeInstr* deopt =
            new DeoptimizeInstr(ICData::kDeoptBinarySmiOp, GetDeoptId());
        flow_graph->InsertBefore(this, deopt, env(), FlowGraph::kEffect);
        // Replace with zero since it always throws.
        return flow_graph->TryCreateConstantReplacementFor(this,
                                                           Object::smi_zero());
      }
      break;

    case Token::kSHL: {
      const intptr_t result_bits = RepresentationBits(representation());
      if (rhs == 0) {
        return left()->definition();
      } else if ((rhs >= kBitsPerInt64) ||
                 ((rhs >= result_bits) && is_truncating())) {
        return flow_graph->TryCreateConstantReplacementFor(this,
                                                           Object::smi_zero());
      } else if ((rhs < 0) || ((rhs >= result_bits) && !is_truncating())) {
        // Instruction will always throw on negative rhs operand or
        // deoptimize on large rhs operand.
        if (!CanDeoptimize()) {
          // For non-speculative operations (no deopt), let
          // the code generator deal with throw on slowpath.
          break;
        }
        ASSERT(GetDeoptId() != DeoptId::kNone);
        DeoptimizeInstr* deopt =
            new DeoptimizeInstr(ICData::kDeoptBinarySmiOp, GetDeoptId());
        flow_graph->InsertBefore(this, deopt, env(), FlowGraph::kEffect);
        // Replace with zero since it overshifted or always throws.
        return flow_graph->TryCreateConstantReplacementFor(this,
                                                           Object::smi_zero());
      }
      break;
    }

    default:
      break;
  }

  return this;
}

// Optimizations that eliminate or simplify individual instructions.
Instruction* Instruction::Canonicalize(FlowGraph* flow_graph) {
  return this;
}

Definition* Definition::Canonicalize(FlowGraph* flow_graph) {
  return this;
}

Definition* RedefinitionInstr::Canonicalize(FlowGraph* flow_graph) {
  // Must not remove Redefinitions without uses until LICM, even though
  // Redefinition might not have any uses itself it can still be dominating
  // uses of the value it redefines and must serve as a barrier for those
  // uses. RenameUsesDominatedByRedefinitions would normalize the graph and
  // route those uses through this redefinition.
  if (!HasUses() && !flow_graph->is_licm_allowed()) {
    return nullptr;
  }
  if (constrained_type() != nullptr &&
      constrained_type()->IsEqualTo(value()->Type())) {
    return value()->definition();
  }
  return this;
}

Instruction* CheckStackOverflowInstr::Canonicalize(FlowGraph* flow_graph) {
  switch (kind_) {
    case kOsrAndPreemption:
      return this;
    case kOsrOnly:
      // Don't need OSR entries in the optimized code.
      return nullptr;
  }

  // Switch above exhausts all possibilities but some compilers can't figure
  // it out.
  UNREACHABLE();
  return this;
}

bool LoadFieldInstr::IsFixedLengthArrayCid(intptr_t cid) {
  if (IsTypedDataClassId(cid) || IsExternalTypedDataClassId(cid)) {
    return true;
  }

  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kTypeArgumentsCid:
      return true;
    default:
      return false;
  }
}

bool LoadFieldInstr::IsTypedDataViewFactory(const Function& function) {
  auto kind = function.recognized_kind();
  switch (kind) {
    case MethodRecognizer::kTypedData_ByteDataView_factory:
    case MethodRecognizer::kTypedData_Int8ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint8ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint8ClampedArrayView_factory:
    case MethodRecognizer::kTypedData_Int16ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint16ArrayView_factory:
    case MethodRecognizer::kTypedData_Int32ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint32ArrayView_factory:
    case MethodRecognizer::kTypedData_Int64ArrayView_factory:
    case MethodRecognizer::kTypedData_Uint64ArrayView_factory:
    case MethodRecognizer::kTypedData_Float32ArrayView_factory:
    case MethodRecognizer::kTypedData_Float64ArrayView_factory:
    case MethodRecognizer::kTypedData_Float32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_Int32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_Float64x2ArrayView_factory:
      return true;
    default:
      return false;
  }
}

bool LoadFieldInstr::IsUnmodifiableTypedDataViewFactory(
    const Function& function) {
  auto kind = function.recognized_kind();
  switch (kind) {
    case MethodRecognizer::kTypedData_UnmodifiableByteDataView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt8ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint8ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint8ClampedArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt16ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint16ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt32ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint32ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt64ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableUint64ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat32ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat64ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableInt32x4ArrayView_factory:
    case MethodRecognizer::kTypedData_UnmodifiableFloat64x2ArrayView_factory:
      return true;
    default:
      return false;
  }
}

Definition* ConstantInstr::Canonicalize(FlowGraph* flow_graph) {
  return HasUses() ? this : nullptr;
}

// A math unary instruction has a side effect (exception
// thrown) if the argument is not a number.
// TODO(srdjan): eliminate if has no uses and input is guaranteed to be number.
Definition* MathUnaryInstr::Canonicalize(FlowGraph* flow_graph) {
  return this;
}

bool LoadFieldInstr::TryEvaluateLoad(const Object& instance,
                                     const Slot& field,
                                     Object* result) {
  switch (field.kind()) {
    case Slot::Kind::kDartField:
      return TryEvaluateLoad(instance, field.field(), result);

    case Slot::Kind::kArgumentsDescriptor_type_args_len:
      if (instance.IsArray() && Array::Cast(instance).IsImmutable()) {
        ArgumentsDescriptor desc(Array::Cast(instance));
        *result = Smi::New(desc.TypeArgsLen());
        return true;
      }
      return false;

    case Slot::Kind::kArgumentsDescriptor_count:
      if (instance.IsArray() && Array::Cast(instance).IsImmutable()) {
        ArgumentsDescriptor desc(Array::Cast(instance));
        *result = Smi::New(desc.Count());
        return true;
      }
      return false;

    case Slot::Kind::kArgumentsDescriptor_positional_count:
      if (instance.IsArray() && Array::Cast(instance).IsImmutable()) {
        ArgumentsDescriptor desc(Array::Cast(instance));
        *result = Smi::New(desc.PositionalCount());
        return true;
      }
      return false;

    case Slot::Kind::kArgumentsDescriptor_size:
      // If a constant arguments descriptor appears, then either it is from
      // a invocation dispatcher (which always has tagged arguments and so
      // [host]Size() ==  [target]Size() == Count()) or the constant should
      // have the correct Size() in terms of the target architecture if any
      // spill slots are involved.
      if (instance.IsArray() && Array::Cast(instance).IsImmutable()) {
        ArgumentsDescriptor desc(Array::Cast(instance));
        *result = Smi::New(desc.Size());
        return true;
      }
      return false;

    case Slot::Kind::kTypeArguments_length:
      if (instance.IsTypeArguments()) {
        *result = Smi::New(TypeArguments::Cast(instance).Length());
        return true;
      }
      return false;

    case Slot::Kind::kRecord_shape:
      if (instance.IsRecord()) {
        *result = Record::Cast(instance).shape().AsSmi();
        return true;
      }
      return false;

    case Slot::Kind::kRecordField:
      if (instance.IsRecord()) {
        const intptr_t index = compiler::target::Record::field_index_at_offset(
            field.offset_in_bytes());
        const Record& record = Record::Cast(instance);
        if (index < record.num_fields()) {
          *result = record.FieldAt(index);
        }
        return true;
      }
      return false;

    default:
      break;
  }
  return false;
}

bool LoadFieldInstr::TryEvaluateLoad(const Object& instance,
                                     const Field& field,
                                     Object* result) {
  if (!field.is_final() || !instance.IsInstance()) {
    return false;
  }

  // Check that instance really has the field which we
  // are trying to load from.
  Class& cls = Class::Handle(instance.clazz());
  while (cls.ptr() != Class::null() && cls.ptr() != field.Owner()) {
    cls = cls.SuperClass();
  }
  if (cls.ptr() != field.Owner()) {
    // Failed to find the field in class or its superclasses.
    return false;
  }

  // Object has the field: execute the load.
  *result = Instance::Cast(instance).GetField(field);
  return true;
}

bool LoadFieldInstr::Evaluate(const Object& instance, Object* result) {
  return TryEvaluateLoad(instance, slot(), result);
}

Definition* LoadFieldInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses() && !calls_initializer()) return nullptr;

  Definition* orig_instance = instance()->definition()->OriginalDefinition();
  if (IsImmutableLengthLoad()) {
    ASSERT(!calls_initializer());
    if (StaticCallInstr* call = orig_instance->AsStaticCall()) {
      // For fixed length arrays if the array is the result of a known
      // constructor call we can replace the length load with the length
      // argument passed to the constructor.
      if (call->is_known_list_constructor() &&
          IsFixedLengthArrayCid(call->Type()->ToCid())) {
        return call->ArgumentAt(1);
      } else if (call->function().recognized_kind() ==
                 MethodRecognizer::kByteDataFactory) {
        // Similarly, we check for the ByteData constructor and forward its
        // explicit length argument appropriately.
        return call->ArgumentAt(1);
      } else if (IsTypedDataViewFactory(call->function())) {
        // Typed data view factories all take three arguments (after
        // the implicit type arguments parameter):
        //
        // 1) _TypedList buffer -- the underlying data for the view
        // 2) int offsetInBytes -- the offset into the buffer to start viewing
        // 3) int length        -- the number of elements in the view
        //
        // Here, we forward the third.
        return call->ArgumentAt(3);
      }
    } else if (LoadFieldInstr* load_array = orig_instance->AsLoadField()) {
      // For arrays with guarded lengths, replace the length load
      // with a constant.
      const Slot& slot = load_array->slot();
      if (slot.IsDartField()) {
        if (slot.field().guarded_list_length() >= 0) {
          return flow_graph->GetConstant(
              Smi::Handle(Smi::New(slot.field().guarded_list_length())));
        }
      }
    }
  }

  switch (slot().kind()) {
    case Slot::Kind::kArray_length:
      if (CreateArrayInstr* create_array = orig_instance->AsCreateArray()) {
        return create_array->num_elements()->definition();
      }
      break;
    case Slot::Kind::kTypedDataBase_length:
      if (AllocateTypedDataInstr* alloc_typed_data =
              orig_instance->AsAllocateTypedData()) {
        return alloc_typed_data->num_elements()->definition();
      }
      break;
    case Slot::Kind::kTypedDataView_typed_data:
      // This case cover the first explicit argument to typed data view
      // factories, the data (buffer).
      ASSERT(!calls_initializer());
      if (StaticCallInstr* call = orig_instance->AsStaticCall()) {
        if (IsTypedDataViewFactory(call->function()) ||
            IsUnmodifiableTypedDataViewFactory(call->function())) {
          return call->ArgumentAt(1);
        }
      }
      break;
    case Slot::Kind::kTypedDataView_offset_in_bytes:
      // This case cover the second explicit argument to typed data view
      // factories, the offset into the buffer.
      ASSERT(!calls_initializer());
      if (StaticCallInstr* call = orig_instance->AsStaticCall()) {
        if (IsTypedDataViewFactory(call->function())) {
          return call->ArgumentAt(2);
        } else if (call->function().recognized_kind() ==
                   MethodRecognizer::kByteDataFactory) {
          // A _ByteDataView returned from the ByteData constructor always
          // has an offset of 0.
          return flow_graph->GetConstant(Object::smi_zero());
        }
      }
      break;
    case Slot::Kind::kRecord_shape:
      ASSERT(!calls_initializer());
      if (auto* alloc_rec = orig_instance->AsAllocateRecord()) {
        return flow_graph->GetConstant(Smi::Handle(alloc_rec->shape().AsSmi()));
      } else if (auto* alloc_rec = orig_instance->AsAllocateSmallRecord()) {
        return flow_graph->GetConstant(Smi::Handle(alloc_rec->shape().AsSmi()));
      } else {
        const AbstractType* type = instance()->Type()->ToAbstractType();
        if (type->IsRecordType()) {
          return flow_graph->GetConstant(
              Smi::Handle(RecordType::Cast(*type).shape().AsSmi()));
        }
      }
      break;
    case Slot::Kind::kTypeArguments:
      ASSERT(!calls_initializer());
      if (StaticCallInstr* call = orig_instance->AsStaticCall()) {
        if (call->is_known_list_constructor()) {
          return call->ArgumentAt(0);
        } else if (IsTypedDataViewFactory(call->function()) ||
                   IsUnmodifiableTypedDataViewFactory(call->function())) {
          return flow_graph->constant_null();
        }
        switch (call->function().recognized_kind()) {
          case MethodRecognizer::kByteDataFactory:
          case MethodRecognizer::kLinkedHashBase_getData:
          case MethodRecognizer::kImmutableLinkedHashBase_getData:
            return flow_graph->constant_null();
          default:
            break;
        }
      } else if (CreateArrayInstr* create_array =
                     orig_instance->AsCreateArray()) {
        return create_array->type_arguments()->definition();
      } else if (LoadFieldInstr* load_array = orig_instance->AsLoadField()) {
        const Slot& slot = load_array->slot();
        switch (slot.kind()) {
          case Slot::Kind::kDartField: {
            // For trivially exact fields we know that type arguments match
            // static type arguments exactly.
            const Field& field = slot.field();
            if (field.static_type_exactness_state().IsTriviallyExact()) {
              return flow_graph->GetConstant(TypeArguments::Handle(
                  Type::Cast(AbstractType::Handle(field.type()))
                      .GetInstanceTypeArguments(flow_graph->thread())));
            }
            break;
          }

          case Slot::Kind::kLinkedHashBase_data:
            return flow_graph->constant_null();

          default:
            break;
        }
      }
      break;
    default:
      break;
  }

  // Try folding away loads from constant objects.
  if (instance()->BindsToConstant()) {
    Object& result = Object::Handle();
    if (Evaluate(instance()->BoundConstant(), &result)) {
      if (result.IsSmi() || result.IsOld()) {
        return flow_graph->GetConstant(result);
      }
    }
  }

  if (instance()->definition()->IsAllocateObject() && slot().is_immutable()) {
    StoreFieldInstr* initializing_store = nullptr;
    for (auto use : instance()->definition()->input_uses()) {
      if (auto store = use->instruction()->AsStoreField()) {
        if (store->slot().IsIdentical(slot())) {
          if (initializing_store == nullptr) {
            initializing_store = store;
          } else {
            initializing_store = nullptr;
            break;
          }
        }
      }
    }

    // If we find an initializing store then it *must* by construction
    // dominate the load.
    if (initializing_store != nullptr &&
        initializing_store->is_initialization()) {
      ASSERT(IsDominatedBy(initializing_store));
      return initializing_store->value()->definition();
    }
  }

  return this;
}

Definition* AssertBooleanInstr::Canonicalize(FlowGraph* flow_graph) {
  if (FLAG_eliminate_type_checks) {
    if (value()->Type()->ToCid() == kBoolCid) {
      return value()->definition();
    }

    // In strong mode type is already verified either by static analysis
    // or runtime checks, so AssertBoolean just ensures that value is not null.
    if (!value()->Type()->is_nullable()) {
      return value()->definition();
    }
  }

  return this;
}

Definition* AssertAssignableInstr::Canonicalize(FlowGraph* flow_graph) {
  // We need dst_type() to be a constant AbstractType to perform any
  // canonicalization.
  if (!dst_type()->BindsToConstant()) return this;
  const auto& abs_type = AbstractType::Cast(dst_type()->BoundConstant());

  if (abs_type.IsTopTypeForSubtyping() ||
      (FLAG_eliminate_type_checks &&
       value()->Type()->IsAssignableTo(abs_type))) {
    return value()->definition();
  }
  if (abs_type.IsInstantiated()) {
    return this;
  }

  // For uninstantiated target types: If the instantiator and function
  // type arguments are constant, instantiate the target type here.
  // Note: these constant type arguments might not necessarily correspond
  // to the correct instantiator because AssertAssignable might
  // be located in the unreachable part of the graph (e.g.
  // it might be dominated by CheckClass that always fails).
  // This means that the code below must guard against such possibility.
  Thread* thread = Thread::Current();
  Zone* Z = thread->zone();

  const TypeArguments* instantiator_type_args = nullptr;
  const TypeArguments* function_type_args = nullptr;

  if (instantiator_type_arguments()->BindsToConstant()) {
    const Object& val = instantiator_type_arguments()->BoundConstant();
    instantiator_type_args = (val.ptr() == TypeArguments::null())
                                 ? &TypeArguments::null_type_arguments()
                                 : &TypeArguments::Cast(val);
  }

  if (function_type_arguments()->BindsToConstant()) {
    const Object& val = function_type_arguments()->BoundConstant();
    function_type_args =
        (val.ptr() == TypeArguments::null())
            ? &TypeArguments::null_type_arguments()
            : &TypeArguments::Cast(function_type_arguments()->BoundConstant());
  }

  // If instantiator_type_args are not constant try to match the pattern
  // obj.field.:type_arguments where field's static type exactness state
  // tells us that all values stored in the field have exact superclass.
  // In this case we know the prefix of the actual type arguments vector
  // and can try to instantiate the type using just the prefix.
  //
  // Note: TypeParameter::InstantiateFrom returns an error if we try
  // to instantiate it from a vector that is too short.
  if (instantiator_type_args == nullptr) {
    if (LoadFieldInstr* load_type_args =
            instantiator_type_arguments()->definition()->AsLoadField()) {
      if (load_type_args->slot().IsTypeArguments()) {
        if (LoadFieldInstr* load_field = load_type_args->instance()
                                             ->definition()
                                             ->OriginalDefinition()
                                             ->AsLoadField()) {
          if (load_field->slot().IsDartField() &&
              load_field->slot()
                  .field()
                  .static_type_exactness_state()
                  .IsHasExactSuperClass()) {
            instantiator_type_args = &TypeArguments::Handle(
                Z, Type::Cast(AbstractType::Handle(
                                  Z, load_field->slot().field().type()))
                       .GetInstanceTypeArguments(thread));
          }
        }
      }
    }
  }

  if ((instantiator_type_args != nullptr) && (function_type_args != nullptr)) {
    AbstractType& new_dst_type = AbstractType::Handle(
        Z, abs_type.InstantiateFrom(*instantiator_type_args,
                                    *function_type_args, kAllFree, Heap::kOld));
    if (new_dst_type.IsNull()) {
      // Failed instantiation in dead code.
      return this;
    }
    new_dst_type = new_dst_type.Canonicalize(Thread::Current());

    // Successfully instantiated destination type: update the type attached
    // to this instruction and set type arguments to null because we no
    // longer need them (the type was instantiated).
    dst_type()->BindTo(flow_graph->GetConstant(new_dst_type));
    instantiator_type_arguments()->BindTo(flow_graph->constant_null());
    function_type_arguments()->BindTo(flow_graph->constant_null());

    if (new_dst_type.IsTopTypeForSubtyping() ||
        (FLAG_eliminate_type_checks &&
         value()->Type()->IsAssignableTo(new_dst_type))) {
      return value()->definition();
    }
  }
  return this;
}

Definition* InstantiateTypeArgumentsInstr::Canonicalize(FlowGraph* flow_graph) {
  return HasUses() ? this : nullptr;
}

LocationSummary* DebugStepCheckInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  return locs;
}

Instruction* DebugStepCheckInstr::Canonicalize(FlowGraph* flow_graph) {
  return nullptr;
}

Instruction* RecordCoverageInstr::Canonicalize(FlowGraph* flow_graph) {
  ASSERT(!coverage_array_.IsNull());
  return coverage_array_.At(coverage_index_) != Smi::New(0) ? nullptr : this;
}

Definition* BoxInstr::Canonicalize(FlowGraph* flow_graph) {
  if (input_use_list() == nullptr) {
    // Environments can accommodate any representation. No need to box.
    return value()->definition();
  }

  // Fold away Box<rep>(v) if v has a target representation already.
  Definition* value_defn = value()->definition();
  if (value_defn->representation() == representation()) {
    return value_defn;
  }

  // Fold away Box<rep>(Unbox<rep>(v)) if value is known to be of the
  // right class.
  UnboxInstr* unbox_defn = value()->definition()->AsUnbox();
  if ((unbox_defn != nullptr) &&
      (unbox_defn->representation() == from_representation()) &&
      (unbox_defn->value()->Type()->ToCid() == Type()->ToCid())) {
    return unbox_defn->value()->definition();
  }

  return this;
}

bool BoxIntegerInstr::ValueFitsSmi() const {
  Range* range = value()->definition()->range();
  return RangeUtils::Fits(range, RangeBoundary::kRangeBoundarySmi);
}

Definition* BoxIntegerInstr::Canonicalize(FlowGraph* flow_graph) {
  if (input_use_list() == nullptr) {
    // Environments can accommodate any representation. No need to box.
    return value()->definition();
  }

  // Fold away Box<rep>(v) if v has a target representation already.
  Definition* value_defn = value()->definition();
  if (value_defn->representation() == representation()) {
    return value_defn;
  }

  return this;
}

Definition* BoxInt64Instr::Canonicalize(FlowGraph* flow_graph) {
  Definition* replacement = BoxIntegerInstr::Canonicalize(flow_graph);
  if (replacement != this) {
    return replacement;
  }

  // For all x, box(unbox(x)) = x.
  if (auto unbox = value()->definition()->AsUnboxInt64()) {
    if (unbox->SpeculativeModeOfInputs() == kNotSpeculative) {
      return unbox->value()->definition();
    }
  } else if (auto unbox = value()->definition()->AsUnboxedConstant()) {
    return flow_graph->GetConstant(unbox->value());
  }

  // Find a more precise box instruction.
  if (auto conv = value()->definition()->AsIntConverter()) {
    Definition* replacement;
    if (conv->from() == kUntagged) {
      return this;
    }
    switch (conv->from()) {
      case kUnboxedInt32:
        replacement = new BoxInt32Instr(conv->value()->CopyWithType());
        break;
      case kUnboxedUint32:
        replacement = new BoxUint32Instr(conv->value()->CopyWithType());
        break;
      default:
        UNREACHABLE();
        break;
    }
    flow_graph->InsertBefore(this, replacement, nullptr, FlowGraph::kValue);
    return replacement;
  }

  return this;
}

Definition* UnboxInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses() && !CanDeoptimize()) return nullptr;

  // Fold away Unbox<rep>(v) if v has a target representation already.
  Definition* value_defn = value()->definition();
  if (value_defn->representation() == representation()) {
    return value_defn;
  }

  // Fold away Unbox<rep>(Box<rep>(v)).
  BoxInstr* box_defn = value()->definition()->AsBox();
  if ((box_defn != nullptr) &&
      (box_defn->from_representation() == representation())) {
    return box_defn->value()->definition();
  }

  if (representation() == kUnboxedDouble && value()->BindsToConstant()) {
    const Object& val = value()->BoundConstant();
    if (val.IsInteger()) {
      const Double& double_val = Double::ZoneHandle(
          flow_graph->zone(),
          Double::NewCanonical(Integer::Cast(val).AsDoubleValue()));
      return flow_graph->GetConstant(double_val, kUnboxedDouble);
    } else if (val.IsDouble()) {
      return flow_graph->GetConstant(val, kUnboxedDouble);
    }
  }

  return this;
}

Definition* UnboxIntegerInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses() && !CanDeoptimize()) return nullptr;

  // Fold away Unbox<rep>(v) if v has a target representation already.
  Definition* value_defn = value()->definition();
  if (value_defn->representation() == representation()) {
    return value_defn;
  }

  // Do not attempt to fold this instruction if we have not matched
  // input/output representations yet.
  if (HasUnmatchedInputRepresentations()) {
    return this;
  }

  // Fold away UnboxInteger<rep_to>(BoxInteger<rep_from>(v)).
  BoxIntegerInstr* box_defn = value()->definition()->AsBoxInteger();
  if (box_defn != nullptr && !box_defn->HasUnmatchedInputRepresentations()) {
    Representation from_representation =
        box_defn->value()->definition()->representation();
    if (from_representation == representation()) {
      return box_defn->value()->definition();
    } else {
      // Only operate on explicit unboxed operands.
      IntConverterInstr* converter = new IntConverterInstr(
          from_representation, representation(),
          box_defn->value()->CopyWithType(),
          (representation() == kUnboxedInt32) ? GetDeoptId() : DeoptId::kNone);
      // TODO(vegorov): marking resulting converter as truncating when
      // unboxing can't deoptimize is a workaround for the missing
      // deoptimization environment when we insert converter after
      // EliminateEnvironments and there is a mismatch between predicates
      // UnboxIntConverterInstr::CanDeoptimize and UnboxInt32::CanDeoptimize.
      if ((representation() == kUnboxedInt32) &&
          (is_truncating() || !CanDeoptimize())) {
        converter->mark_truncating();
      }
      flow_graph->InsertBefore(this, converter, env(), FlowGraph::kValue);
      return converter;
    }
  }

  if ((SpeculativeModeOfInput(0) == kGuardInputs) && !ComputeCanDeoptimize()) {
    // Remember if we ever learn out input doesn't require checking, as
    // the input Value might be later changed that would make us forget.
    set_speculative_mode(kNotSpeculative);
  }

  return this;
}

Definition* UnboxInt32Instr::Canonicalize(FlowGraph* flow_graph) {
  Definition* replacement = UnboxIntegerInstr::Canonicalize(flow_graph);
  if (replacement != this) {
    return replacement;
  }

  ConstantInstr* c = value()->definition()->AsConstant();
  if ((c != nullptr) && c->value().IsInteger()) {
    if (!is_truncating()) {
      // Check that constant fits into 32-bit integer.
      const int64_t value = Integer::Cast(c->value()).AsInt64Value();
      if (!Utils::IsInt(32, value)) {
        return this;
      }
    }

    return flow_graph->GetConstant(c->value(), kUnboxedInt32);
  }

  return this;
}

Definition* UnboxInt64Instr::Canonicalize(FlowGraph* flow_graph) {
  Definition* replacement = UnboxIntegerInstr::Canonicalize(flow_graph);
  if (replacement != this) {
    return replacement;
  }

  ConstantInstr* c = value()->definition()->AsConstant();
  if (c != nullptr && c->value().IsInteger()) {
    return flow_graph->GetConstant(c->value(), kUnboxedInt64);
  }

  return this;
}

Definition* IntConverterInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return nullptr;

  // Fold IntConverter({Unboxed}Constant(...)) to UnboxedConstant.
  if (auto constant = value()->definition()->AsConstant()) {
    if (from() != kUntagged && to() != kUntagged &&
        constant->representation() == from() && constant->value().IsInteger()) {
      const int64_t value = Integer::Cast(constant->value()).AsInt64Value();
      const int64_t result =
          Evaluator::TruncateTo(Evaluator::TruncateTo(value, from()), to());
      if (is_truncating() || (value == result)) {
        auto& box = Integer::Handle(Integer::New(result, Heap::kOld));
        box ^= box.Canonicalize(flow_graph->thread());
        return flow_graph->GetConstant(box, to());
      }
    }
  }

  IntConverterInstr* box_defn = value()->definition()->AsIntConverter();
  if ((box_defn != nullptr) && (box_defn->representation() == from())) {
    // If the first conversion can erase bits (or deoptimize) we can't
    // canonicalize it away.
    auto src_defn = box_defn->value()->definition();
    if ((box_defn->from() == kUnboxedInt64) &&
        !Range::Fits(src_defn->range(), box_defn->to())) {
      return this;
    }

    // Otherise it is safe to discard any other conversions from and then back
    // to the same integer type.
    if (box_defn->from() == to()) {
      return src_defn;
    }

    // Do not merge conversions where the first starts from Untagged or the
    // second ends at Untagged, since we expect to see either UnboxedIntPtr
    // or UnboxedFfiIntPtr as the other type in an Untagged conversion.
    if ((box_defn->from() == kUntagged) || (to() == kUntagged)) {
      return this;
    }

    IntConverterInstr* converter = new IntConverterInstr(
        box_defn->from(), representation(), box_defn->value()->CopyWithType(),
        (to() == kUnboxedInt32) ? GetDeoptId() : DeoptId::kNone);
    if ((representation() == kUnboxedInt32) && is_truncating()) {
      converter->mark_truncating();
    }
    flow_graph->InsertBefore(this, converter, env(), FlowGraph::kValue);
    return converter;
  }

  UnboxInt64Instr* unbox_defn = value()->definition()->AsUnboxInt64();
  if (unbox_defn != nullptr && (from() == kUnboxedInt64) &&
      (to() == kUnboxedInt32) && unbox_defn->HasOnlyInputUse(value())) {
    // TODO(vegorov): there is a duplication of code between UnboxedIntConverter
    // and code path that unboxes Mint into Int32. We should just schedule
    // these instructions close to each other instead of fusing them.
    Definition* replacement =
        new UnboxInt32Instr(is_truncating() ? UnboxInt32Instr::kTruncate
                                            : UnboxInt32Instr::kNoTruncation,
                            unbox_defn->value()->CopyWithType(), GetDeoptId());
    flow_graph->InsertBefore(this, replacement, env(), FlowGraph::kValue);
    return replacement;
  }

  return this;
}

// Tests for a FP comparison that cannot be negated
// (to preserve NaN semantics).
static bool IsFpCompare(ComparisonInstr* comp) {
  if (comp->IsRelationalOp()) {
    return comp->operation_cid() == kDoubleCid;
  }
  return false;
}

Definition* BooleanNegateInstr::Canonicalize(FlowGraph* flow_graph) {
  Definition* defn = value()->definition();
  // Convert e.g. !(x > y) into (x <= y) for non-FP x, y.
  if (defn->IsComparison() && defn->HasOnlyUse(value()) &&
      defn->Type()->ToCid() == kBoolCid) {
    ComparisonInstr* comp = defn->AsComparison();
    if (!IsFpCompare(comp)) {
      comp->NegateComparison();
      return defn;
    }
  }
  return this;
}

static bool MayBeBoxableNumber(intptr_t cid) {
  return (cid == kDynamicCid) || (cid == kMintCid) || (cid == kDoubleCid);
}

static bool MayBeNumber(CompileType* type) {
  if (type->IsNone()) {
    return false;
  }
  const AbstractType& unwrapped_type =
      AbstractType::Handle(type->ToAbstractType()->UnwrapFutureOr());
  // Note that type 'Number' is a subtype of itself.
  return unwrapped_type.IsTopTypeForSubtyping() ||
         unwrapped_type.IsObjectType() || unwrapped_type.IsTypeParameter() ||
         unwrapped_type.IsSubtypeOf(Type::Handle(Type::Number()), Heap::kOld);
}

// Returns a replacement for a strict comparison and signals if the result has
// to be negated.
static Definition* CanonicalizeStrictCompare(StrictCompareInstr* compare,
                                             bool* negated,
                                             bool is_branch) {
  // Use propagated cid and type information to eliminate number checks.
  // If one of the inputs is not a boxable number (Mint, Double), or
  // is not a subtype of num, no need for number checks.
  if (compare->needs_number_check()) {
    if (!MayBeBoxableNumber(compare->left()->Type()->ToCid()) ||
        !MayBeBoxableNumber(compare->right()->Type()->ToCid())) {
      compare->set_needs_number_check(false);
    } else if (!MayBeNumber(compare->left()->Type()) ||
               !MayBeNumber(compare->right()->Type())) {
      compare->set_needs_number_check(false);
    }
  }
  *negated = false;
  ConstantInstr* constant_defn = nullptr;
  Value* other = nullptr;

  if (!compare->IsComparisonWithConstant(&other, &constant_defn)) {
    return compare;
  }

  const Object& constant = constant_defn->value();
  const bool can_merge = is_branch || (other->Type()->ToCid() == kBoolCid);
  Definition* other_defn = other->definition();
  Token::Kind kind = compare->kind();

  if (!constant.IsBool() || !can_merge) {
    return compare;
  }

  const bool constant_value = Bool::Cast(constant).value();

  // Handle `e === true` and `e !== false`: these cases don't require
  // negation and allow direct merge.
  if ((kind == Token::kEQ_STRICT) == constant_value) {
    return other_defn;
  }

  // We now have `e !== true` or `e === false`: these cases require
  // negation.
  if (auto comp = other_defn->AsComparison()) {
    if (other_defn->HasOnlyUse(other) && !IsFpCompare(comp)) {
      *negated = true;
      return other_defn;
    }
  }

  return compare;
}

static bool BindsToGivenConstant(Value* v, intptr_t expected) {
  return v->BindsToConstant() && v->BoundConstant().IsSmi() &&
         (Smi::Cast(v->BoundConstant()).Value() == expected);
}

// Recognize patterns (a & b) == 0 and (a & 2^n) != 2^n.
static bool RecognizeTestPattern(Value* left, Value* right, bool* negate) {
  if (!right->BindsToConstant() || !right->BoundConstant().IsSmi()) {
    return false;
  }

  const intptr_t value = Smi::Cast(right->BoundConstant()).Value();
  if ((value != 0) && !Utils::IsPowerOfTwo(value)) {
    return false;
  }

  BinarySmiOpInstr* mask_op = left->definition()->AsBinarySmiOp();
  if ((mask_op == nullptr) || (mask_op->op_kind() != Token::kBIT_AND) ||
      !mask_op->HasOnlyUse(left)) {
    return false;
  }

  if (value == 0) {
    // Recognized (a & b) == 0 pattern.
    *negate = false;
    return true;
  }

  // Recognize
  if (BindsToGivenConstant(mask_op->left(), value) ||
      BindsToGivenConstant(mask_op->right(), value)) {
    // Recognized (a & 2^n) == 2^n pattern. It's equivalent to (a & 2^n) != 0
    // so we need to negate original comparison.
    *negate = true;
    return true;
  }

  return false;
}

Instruction* BranchInstr::Canonicalize(FlowGraph* flow_graph) {
  Zone* zone = flow_graph->zone();
  if (comparison()->IsStrictCompare()) {
    bool negated = false;
    Definition* replacement = CanonicalizeStrictCompare(
        comparison()->AsStrictCompare(), &negated, /*is_branch=*/true);
    if (replacement == comparison()) {
      return this;
    }
    ComparisonInstr* comp = replacement->AsComparison();
    if ((comp == nullptr) || comp->CanDeoptimize() ||
        comp->HasUnmatchedInputRepresentations()) {
      return this;
    }

    // Replace the comparison if the replacement is used at this branch,
    // and has exactly one use.
    Value* use = comp->input_use_list();
    if ((use->instruction() == this) && comp->HasOnlyUse(use)) {
      if (negated) {
        comp->NegateComparison();
      }
      RemoveEnvironment();
      flow_graph->CopyDeoptTarget(this, comp);
      // Unlink environment from the comparison since it is copied to the
      // branch instruction.
      comp->RemoveEnvironment();

      comp->RemoveFromGraph();
      SetComparison(comp);
      if (FLAG_trace_optimization && flow_graph->should_print()) {
        THR_Print("Merging comparison v%" Pd "\n", comp->ssa_temp_index());
      }
      // Clear the comparison's temp index and ssa temp index since the
      // value of the comparison is not used outside the branch anymore.
      ASSERT(comp->input_use_list() == nullptr);
      comp->ClearSSATempIndex();
      comp->ClearTempIndex();
    }

    return this;
  }

  if (comparison()->IsEqualityCompare() &&
      comparison()->operation_cid() == kSmiCid) {
    BinarySmiOpInstr* bit_and = nullptr;
    bool negate = false;
    if (RecognizeTestPattern(comparison()->left(), comparison()->right(),
                             &negate)) {
      bit_and = comparison()->left()->definition()->AsBinarySmiOp();
    } else if (RecognizeTestPattern(comparison()->right(), comparison()->left(),
                                    &negate)) {
      bit_and = comparison()->right()->definition()->AsBinarySmiOp();
    }
    if (bit_and != nullptr) {
      if (FLAG_trace_optimization && flow_graph->should_print()) {
        THR_Print("Merging test smi v%" Pd "\n", bit_and->ssa_temp_index());
      }
      TestSmiInstr* test = new TestSmiInstr(
          comparison()->source(),
          negate ? Token::NegateComparison(comparison()->kind())
                 : comparison()->kind(),
          bit_and->left()->Copy(zone), bit_and->right()->Copy(zone));
      ASSERT(!CanDeoptimize());
      RemoveEnvironment();
      flow_graph->CopyDeoptTarget(this, bit_and);
      SetComparison(test);
      bit_and->RemoveFromGraph();
    }
  }
  return this;
}

Definition* StrictCompareInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return nullptr;

  bool negated = false;
  Definition* replacement = CanonicalizeStrictCompare(this, &negated,
                                                      /*is_branch=*/false);
  if (negated && replacement->IsComparison()) {
    ASSERT(replacement != this);
    replacement->AsComparison()->NegateComparison();
  }
  return replacement;
}

static bool IsSingleUseUnboxOrConstant(Value* use) {
  return (use->definition()->IsUnbox() && use->IsSingleUse()) ||
         use->definition()->IsConstant();
}

Definition* EqualityCompareInstr::Canonicalize(FlowGraph* flow_graph) {
  if (is_null_aware()) {
    ASSERT(operation_cid() == kMintCid);
    // Select more efficient instructions based on operand types.
    CompileType* left_type = left()->Type();
    CompileType* right_type = right()->Type();
    if (left_type->IsNull() || left_type->IsNullableSmi() ||
        right_type->IsNull() || right_type->IsNullableSmi()) {
      auto replacement = new StrictCompareInstr(
          source(),
          (kind() == Token::kEQ) ? Token::kEQ_STRICT : Token::kNE_STRICT,
          left()->CopyWithType(), right()->CopyWithType(),
          /*needs_number_check=*/false, DeoptId::kNone);
      flow_graph->InsertBefore(this, replacement, env(), FlowGraph::kValue);
      return replacement;
    } else {
      // Null-aware EqualityCompare takes boxed inputs, so make sure
      // unmatched representations are still allowed when converting
      // EqualityCompare to the unboxed instruction.
      if (!left_type->is_nullable() && !right_type->is_nullable() &&
          flow_graph->unmatched_representations_allowed()) {
        set_null_aware(false);
      }
    }
  } else {
    if ((operation_cid() == kMintCid) && IsSingleUseUnboxOrConstant(left()) &&
        IsSingleUseUnboxOrConstant(right()) &&
        (left()->Type()->IsNullableSmi() || right()->Type()->IsNullableSmi()) &&
        flow_graph->unmatched_representations_allowed()) {
      auto replacement = new StrictCompareInstr(
          source(),
          (kind() == Token::kEQ) ? Token::kEQ_STRICT : Token::kNE_STRICT,
          left()->CopyWithType(), right()->CopyWithType(),
          /*needs_number_check=*/false, DeoptId::kNone);
      flow_graph->InsertBefore(this, replacement, env(), FlowGraph::kValue);
      return replacement;
    }
  }
  return this;
}

Instruction* CheckClassInstr::Canonicalize(FlowGraph* flow_graph) {
  const intptr_t value_cid = value()->Type()->ToCid();
  if (value_cid == kDynamicCid) {
    return this;
  }

  return cids().HasClassId(value_cid) ? nullptr : this;
}

Definition* LoadClassIdInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!HasUses()) return nullptr;

  const intptr_t cid = object()->Type()->ToCid();
  if (cid != kDynamicCid) {
    const auto& smi = Smi::ZoneHandle(flow_graph->zone(), Smi::New(cid));
    return flow_graph->GetConstant(smi, representation());
  }
  return this;
}

Instruction* CheckClassIdInstr::Canonicalize(FlowGraph* flow_graph) {
  if (value()->BindsToConstant()) {
    const Object& constant_value = value()->BoundConstant();
    if (constant_value.IsSmi() &&
        cids_.Contains(Smi::Cast(constant_value).Value())) {
      return nullptr;
    }
  }
  return this;
}

TestCidsInstr::TestCidsInstr(const InstructionSource& source,
                             Token::Kind kind,
                             Value* value,
                             const ZoneGrowableArray<intptr_t>& cid_results,
                             intptr_t deopt_id)
    : TemplateComparison(source, kind, deopt_id), cid_results_(cid_results) {
  ASSERT((kind == Token::kIS) || (kind == Token::kISNOT));
  SetInputAt(0, value);
  set_operation_cid(kObjectCid);
#ifdef DEBUG
  ASSERT(cid_results[0] == kSmiCid);
  if (deopt_id == DeoptId::kNone) {
    // The entry for Smi can be special, but all other entries have
    // to match in the no-deopt case.
    for (intptr_t i = 4; i < cid_results.length(); i += 2) {
      ASSERT(cid_results[i + 1] == cid_results[3]);
    }
  }
#endif
}

Definition* TestCidsInstr::Canonicalize(FlowGraph* flow_graph) {
  CompileType* in_type = value()->Type();
  intptr_t cid = in_type->ToCid();
  if (cid == kDynamicCid) return this;

  const ZoneGrowableArray<intptr_t>& data = cid_results();
  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  for (intptr_t i = 0; i < data.length(); i += 2) {
    if (data[i] == cid) {
      return (data[i + 1] == true_result)
                 ? flow_graph->GetConstant(Bool::True())
                 : flow_graph->GetConstant(Bool::False());
    }
  }

  if (!CanDeoptimize()) {
    ASSERT(deopt_id() == DeoptId::kNone);
    return (data[data.length() - 1] == true_result)
               ? flow_graph->GetConstant(Bool::False())
               : flow_graph->GetConstant(Bool::True());
  }

  // TODO(sra): Handle nullable input, possibly canonicalizing to a compare
  // against `null`.
  return this;
}

TestRangeInstr::TestRangeInstr(const InstructionSource& source,
                               Value* value,
                               uword lower,
                               uword upper,
                               Representation value_representation)
    : TemplateComparison(source, Token::kIS, DeoptId::kNone),
      lower_(lower),
      upper_(upper),
      value_representation_(value_representation) {
  ASSERT(lower < upper);
  ASSERT(value_representation == kTagged ||
         value_representation == kUnboxedUword);
  SetInputAt(0, value);
  set_operation_cid(kObjectCid);
}

Definition* TestRangeInstr::Canonicalize(FlowGraph* flow_graph) {
  if (value()->BindsToSmiConstant()) {
    uword val = Smi::Cast(value()->BoundConstant()).Value();
    bool in_range = lower_ <= val && val <= upper_;
    ASSERT((kind() == Token::kIS) || (kind() == Token::kISNOT));
    return flow_graph->GetConstant(
        Bool::Get(in_range == (kind() == Token::kIS)));
  }
  return this;
}

Instruction* GuardFieldClassInstr::Canonicalize(FlowGraph* flow_graph) {
  if (field().guarded_cid() == kDynamicCid) {
    return nullptr;  // Nothing to guard.
  }

  if (field().is_nullable() && value()->Type()->IsNull()) {
    return nullptr;
  }

  const intptr_t cid = field().is_nullable() ? value()->Type()->ToNullableCid()
                                             : value()->Type()->ToCid();
  if (field().guarded_cid() == cid) {
    return nullptr;  // Value is guaranteed to have this cid.
  }

  return this;
}

Instruction* GuardFieldLengthInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!field().needs_length_check()) {
    return nullptr;  // Nothing to guard.
  }

  const intptr_t expected_length = field().guarded_list_length();
  if (expected_length == Field::kUnknownFixedLength) {
    return this;
  }

  // Check if length is statically known.
  StaticCallInstr* call = value()->definition()->AsStaticCall();
  if (call == nullptr) {
    return this;
  }

  ConstantInstr* length = nullptr;
  if (call->is_known_list_constructor() &&
      LoadFieldInstr::IsFixedLengthArrayCid(call->Type()->ToCid())) {
    length = call->ArgumentAt(1)->AsConstant();
  } else if (call->function().recognized_kind() ==
             MethodRecognizer::kByteDataFactory) {
    length = call->ArgumentAt(1)->AsConstant();
  } else if (LoadFieldInstr::IsTypedDataViewFactory(call->function())) {
    length = call->ArgumentAt(3)->AsConstant();
  }
  if ((length != nullptr) && length->value().IsSmi() &&
      Smi::Cast(length->value()).Value() == expected_length) {
    return nullptr;  // Expected length matched.
  }

  return this;
}

Instruction* GuardFieldTypeInstr::Canonicalize(FlowGraph* flow_graph) {
  return field().static_type_exactness_state().NeedsFieldGuard() ? this
                                                                 : nullptr;
}

Instruction* CheckSmiInstr::Canonicalize(FlowGraph* flow_graph) {
  return (value()->Type()->ToCid() == kSmiCid) ? nullptr : this;
}

Instruction* CheckEitherNonSmiInstr::Canonicalize(FlowGraph* flow_graph) {
  if ((left()->Type()->ToCid() == kDoubleCid) ||
      (right()->Type()->ToCid() == kDoubleCid)) {
    return nullptr;  // Remove from the graph.
  }
  return this;
}

Definition* CheckNullInstr::Canonicalize(FlowGraph* flow_graph) {
  return (!value()->Type()->is_nullable()) ? value()->definition() : this;
}

bool CheckNullInstr::AttributesEqual(const Instruction& other) const {
  auto const other_check = other.AsCheckNull();
  ASSERT(other_check != nullptr);
  return function_name().Equals(other_check->function_name()) &&
         exception_type() == other_check->exception_type();
}

BoxInstr* BoxInstr::Create(Representation from, Value* value) {
  switch (from) {
    case kUnboxedUint8:
    case kUnboxedUint16:
#if defined(HAS_SMI_63_BITS)
    case kUnboxedInt32:
    case kUnboxedUint32:
#endif
      return new BoxSmallIntInstr(from, value);

#if defined(TARGET_ARCH_IS_32_BIT) || defined(DART_COMPRESSED_POINTERS)
    case kUnboxedInt32:
      return new BoxInt32Instr(value);

    case kUnboxedUint32:
      return new BoxUint32Instr(value);
#endif

    case kUnboxedInt64:
      return new BoxInt64Instr(value);

    case kUnboxedDouble:
    case kUnboxedFloat:
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      return new BoxInstr(from, value);

    default:
      UNREACHABLE();
      return nullptr;
  }
}

UnboxInstr* UnboxInstr::Create(Representation to,
                               Value* value,
                               intptr_t deopt_id,
                               SpeculativeMode speculative_mode) {
  switch (to) {
    case kUnboxedInt32:
      // We must truncate if we can't deoptimize.
      return new UnboxInt32Instr(
          speculative_mode == SpeculativeMode::kNotSpeculative
              ? UnboxInt32Instr::kTruncate
              : UnboxInt32Instr::kNoTruncation,
          value, deopt_id, speculative_mode);

    case kUnboxedUint32:
      return new UnboxUint32Instr(value, deopt_id, speculative_mode);

    case kUnboxedInt64:
      return new UnboxInt64Instr(value, deopt_id, speculative_mode);

    case kUnboxedDouble:
    case kUnboxedFloat:
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      ASSERT(FlowGraphCompiler::SupportsUnboxedDoubles());
      return new UnboxInstr(to, value, deopt_id, speculative_mode);

    default:
      UNREACHABLE();
      return nullptr;
  }
}

bool UnboxInstr::CanConvertSmi() const {
  switch (representation()) {
    case kUnboxedDouble:
    case kUnboxedFloat:
    case kUnboxedInt32:
    case kUnboxedInt64:
      return true;

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      return false;

    default:
      UNREACHABLE();
      return false;
  }
}

const BinaryFeedback* BinaryFeedback::Create(Zone* zone,
                                             const ICData& ic_data) {
  BinaryFeedback* result = new (zone) BinaryFeedback(zone);
  if (ic_data.NumArgsTested() == 2) {
    for (intptr_t i = 0, n = ic_data.NumberOfChecks(); i < n; i++) {
      if (ic_data.GetCountAt(i) == 0) {
        continue;
      }
      GrowableArray<intptr_t> arg_ids;
      ic_data.GetClassIdsAt(i, &arg_ids);
      result->feedback_.Add({arg_ids[0], arg_ids[1]});
    }
  }
  return result;
}

const BinaryFeedback* BinaryFeedback::CreateMonomorphic(Zone* zone,
                                                        intptr_t receiver_cid,
                                                        intptr_t argument_cid) {
  BinaryFeedback* result = new (zone) BinaryFeedback(zone);
  result->feedback_.Add({receiver_cid, argument_cid});
  return result;
}

const CallTargets* CallTargets::CreateMonomorphic(Zone* zone,
                                                  intptr_t receiver_cid,
                                                  const Function& target) {
  CallTargets* targets = new (zone) CallTargets(zone);
  const intptr_t count = 1;
  targets->cid_ranges_.Add(new (zone) TargetInfo(
      receiver_cid, receiver_cid, &Function::ZoneHandle(zone, target.ptr()),
      count, StaticTypeExactnessState::NotTracking()));
  return targets;
}

const CallTargets* CallTargets::Create(Zone* zone, const ICData& ic_data) {
  CallTargets* targets = new (zone) CallTargets(zone);
  targets->CreateHelper(zone, ic_data);
  targets->Sort(OrderById);
  targets->MergeIntoRanges();
  return targets;
}

const CallTargets* CallTargets::CreateAndExpand(Zone* zone,
                                                const ICData& ic_data) {
  CallTargets& targets = *new (zone) CallTargets(zone);
  targets.CreateHelper(zone, ic_data);

  if (targets.is_empty() || targets.IsMonomorphic()) {
    return &targets;
  }

  targets.Sort(OrderById);

  Array& args_desc_array = Array::Handle(zone, ic_data.arguments_descriptor());
  ArgumentsDescriptor args_desc(args_desc_array);
  String& name = String::Handle(zone, ic_data.target_name());

  Function& fn = Function::Handle(zone);

  intptr_t length = targets.length();

  // Merging/extending cid ranges is also done in Cids::CreateAndExpand.
  // If changing this code, consider also adjusting Cids code.

  // Spread class-ids to preceding classes where a lookup yields the same
  // method.  A polymorphic target is not really the same method since its
  // behaviour depends on the receiver class-id, so we don't spread the
  // class-ids in that case.
  for (int idx = 0; idx < length; idx++) {
    int lower_limit_cid = (idx == 0) ? -1 : targets[idx - 1].cid_end;
    auto target_info = targets.TargetAt(idx);
    const Function& target = *target_info->target;
    if (target.is_polymorphic_target()) continue;
    for (int i = target_info->cid_start - 1; i > lower_limit_cid; i--) {
      bool class_is_abstract = false;
      if (FlowGraphCompiler::LookupMethodFor(i, name, args_desc, &fn,
                                             &class_is_abstract) &&
          fn.ptr() == target.ptr()) {
        if (!class_is_abstract) {
          target_info->cid_start = i;
          target_info->exactness = StaticTypeExactnessState::NotTracking();
        }
      } else {
        break;
      }
    }
  }

  // Spread class-ids to following classes where a lookup yields the same
  // method.
  const intptr_t max_cid = IsolateGroup::Current()->class_table()->NumCids();
  for (int idx = 0; idx < length; idx++) {
    int upper_limit_cid =
        (idx == length - 1) ? max_cid : targets[idx + 1].cid_start;
    auto target_info = targets.TargetAt(idx);
    const Function& target = *target_info->target;
    if (target.is_polymorphic_target()) continue;
    // The code below makes attempt to avoid spreading class-id range
    // into a suffix that consists purely of abstract classes to
    // shorten the range.
    // However such spreading is beneficial when it allows to
    // merge to consecutive ranges.
    intptr_t cid_end_including_abstract = target_info->cid_end;
    for (int i = target_info->cid_end + 1; i < upper_limit_cid; i++) {
      bool class_is_abstract = false;
      if (FlowGraphCompiler::LookupMethodFor(i, name, args_desc, &fn,
                                             &class_is_abstract) &&
          fn.ptr() == target.ptr()) {
        cid_end_including_abstract = i;
        if (!class_is_abstract) {
          target_info->cid_end = i;
          target_info->exactness = StaticTypeExactnessState::NotTracking();
        }
      } else {
        break;
      }
    }

    // Check if we have a suffix that consists of abstract classes
    // and expand into it if that would allow us to merge this
    // range with subsequent range.
    if ((cid_end_including_abstract > target_info->cid_end) &&
        (idx < length - 1) &&
        ((cid_end_including_abstract + 1) == targets[idx + 1].cid_start) &&
        (target.ptr() == targets.TargetAt(idx + 1)->target->ptr())) {
      target_info->cid_end = cid_end_including_abstract;
      target_info->exactness = StaticTypeExactnessState::NotTracking();
    }
  }
  targets.MergeIntoRanges();
  return &targets;
}

void CallTargets::MergeIntoRanges() {
  if (length() == 0) {
    return;  // For correctness not performance: must not update length to 1.
  }

  // Merge adjacent class id ranges.
  int dest = 0;
  // We merge entries that dispatch to the same target, but polymorphic targets
  // are not really the same target since they depend on the class-id, so we
  // don't merge them.
  for (int src = 1; src < length(); src++) {
    const Function& target = *TargetAt(dest)->target;
    if (TargetAt(dest)->cid_end + 1 >= TargetAt(src)->cid_start &&
        target.ptr() == TargetAt(src)->target->ptr() &&
        !target.is_polymorphic_target()) {
      TargetAt(dest)->cid_end = TargetAt(src)->cid_end;
      TargetAt(dest)->count += TargetAt(src)->count;
      TargetAt(dest)->exactness = StaticTypeExactnessState::NotTracking();
    } else {
      dest++;
      if (src != dest) {
        // Use cid_ranges_ instead of TargetAt when updating the pointer.
        cid_ranges_[dest] = TargetAt(src);
      }
    }
  }
  SetLength(dest + 1);
  Sort(OrderByFrequencyThenId);
}

void CallTargets::Print() const {
  for (intptr_t i = 0; i < length(); i++) {
    THR_Print("cid = [%" Pd ", %" Pd "], count = %" Pd ", target = %s\n",
              TargetAt(i)->cid_start, TargetAt(i)->cid_end, TargetAt(i)->count,
              TargetAt(i)->target->ToQualifiedCString());
  }
}

// Shared code generation methods (EmitNativeCode and
// MakeLocationSummary). Only assembly code that can be shared across all
// architectures can be used. Machine specific register allocation and code
// generation is located in intermediate_language_<arch>.cc

#define __ compiler->assembler()->

LocationSummary* GraphEntryInstr::MakeLocationSummary(Zone* zone,
                                                      bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

LocationSummary* JoinEntryInstr::MakeLocationSummary(Zone* zone,
                                                     bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void JoinEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  if (!compiler->is_optimizing()) {
    compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, GetDeoptId(),
                                   InstructionSource());
  }
  if (HasParallelMove()) {
    parallel_move()->EmitNativeCode(compiler);
  }
}

LocationSummary* TargetEntryInstr::MakeLocationSummary(Zone* zone,
                                                       bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));

  // TODO(kusterman): Remove duplicate between
  // {TargetEntryInstr,FunctionEntryInstr}::EmitNativeCode.
  if (!compiler->is_optimizing()) {
    if (compiler->NeedsEdgeCounter(this)) {
      compiler->EmitEdgeCounter(preorder_number());
    }

    // The deoptimization descriptor points after the edge counter code for
    // uniformity with ARM, where we can reuse pattern matching code that
    // matches backwards from the end of the pattern.
    compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, GetDeoptId(),
                                   InstructionSource());
  }
  if (HasParallelMove()) {
    if (compiler::Assembler::EmittingComments()) {
      compiler->EmitComment(parallel_move());
    }
    parallel_move()->EmitNativeCode(compiler);
  }
}

LocationSummary* FunctionEntryInstr::MakeLocationSummary(
    Zone* zone,
    bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void FunctionEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
#if defined(TARGET_ARCH_X64)
  // Ensure the start of the monomorphic checked entry is 2-byte aligned (see
  // also Assembler::MonomorphicCheckedEntry()).
  if (__ CodeSize() % 2 == 1) {
    __ nop();
  }
#endif
  if (tag() == Instruction::kFunctionEntry) {
    __ Bind(compiler->GetJumpLabel(this));
  }

  if (this == compiler->flow_graph().graph_entry()->unchecked_entry()) {
    __ BindUncheckedEntryPoint();
  }

  // In the AOT compiler we want to reduce code size, so generate no
  // fall-through code in [FlowGraphCompiler::CompileGraph()].
  // (As opposed to here where we don't check for the return value of
  // [Intrinsify]).
  const Function& function = compiler->parsed_function().function();

  if (function.NeedsMonomorphicCheckedEntry(compiler->zone())) {
    compiler->SpecialStatsBegin(CombinedCodeStatistics::kTagCheckedEntry);
    if (!FLAG_precompiled_mode) {
      __ MonomorphicCheckedEntryJIT();
    } else {
      __ MonomorphicCheckedEntryAOT();
    }
    compiler->SpecialStatsEnd(CombinedCodeStatistics::kTagCheckedEntry);
  }

  // NOTE: Because of the presence of multiple entry-points, we generate several
  // times the same intrinsification & frame setup. That's why we cannot rely on
  // the constant pool being `false` when we come in here.
#if defined(TARGET_USES_OBJECT_POOL)
  __ set_constant_pool_allowed(false);
#endif

  if (compiler->TryIntrinsify() && compiler->skip_body_compilation()) {
    return;
  }
  compiler->EmitPrologue();

#if defined(TARGET_USES_OBJECT_POOL)
  ASSERT(__ constant_pool_allowed());
#endif

  if (!compiler->is_optimizing()) {
    if (compiler->NeedsEdgeCounter(this)) {
      compiler->EmitEdgeCounter(preorder_number());
    }

    // The deoptimization descriptor points after the edge counter code for
    // uniformity with ARM, where we can reuse pattern matching code that
    // matches backwards from the end of the pattern.
    compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kDeopt, GetDeoptId(),
                                   InstructionSource());
  }
  if (HasParallelMove()) {
    if (compiler::Assembler::EmittingComments()) {
      compiler->EmitComment(parallel_move());
    }
    parallel_move()->EmitNativeCode(compiler);
  }
}

LocationSummary* NativeEntryInstr::MakeLocationSummary(Zone* zone,
                                                       bool optimizing) const {
  UNREACHABLE();
}

void NativeEntryInstr::SaveArguments(FlowGraphCompiler* compiler) const {
  __ Comment("SaveArguments");

  // Save the argument registers, in reverse order.
  const auto& return_loc = marshaller_.Location(compiler::ffi::kResultIndex);
  if (return_loc.IsPointerToMemory()) {
    SaveArgument(compiler, return_loc.AsPointerToMemory().pointer_location());
  }
  for (intptr_t i = marshaller_.num_args(); i-- > 0;) {
    SaveArgument(compiler, marshaller_.Location(i));
  }

  __ Comment("SaveArgumentsEnd");
}

void NativeEntryInstr::SaveArgument(
    FlowGraphCompiler* compiler,
    const compiler::ffi::NativeLocation& nloc) const {
  if (nloc.IsStack()) return;

  if (nloc.IsRegisters()) {
    const auto& reg_loc = nloc.WidenTo4Bytes(compiler->zone()).AsRegisters();
    const intptr_t num_regs = reg_loc.num_regs();
    // Save higher-order component first, so bytes are in little-endian layout
    // overall.
    for (intptr_t i = num_regs - 1; i >= 0; i--) {
      __ PushRegister(reg_loc.reg_at(i));
    }
  } else if (nloc.IsFpuRegisters()) {
    // TODO(dartbug.com/40469): Reduce code size.
    __ AddImmediate(SPREG, -8);
    NoTemporaryAllocator temp_alloc;
    const auto& dst = compiler::ffi::NativeStackLocation(
        nloc.payload_type(), nloc.payload_type(), SPREG, 0);
    compiler->EmitNativeMove(dst, nloc, &temp_alloc);
  } else if (nloc.IsPointerToMemory()) {
    const auto& pointer_loc = nloc.AsPointerToMemory().pointer_location();
    if (pointer_loc.IsRegisters()) {
      const auto& regs_loc = pointer_loc.AsRegisters();
      ASSERT(regs_loc.num_regs() == 1);
      __ PushRegister(regs_loc.reg_at(0));
    } else {
      ASSERT(pointer_loc.IsStack());
      // It's already on the stack, so we don't have to save it.
    }
  } else if (nloc.IsMultiple()) {
    const auto& multiple = nloc.AsMultiple();
    const intptr_t num = multiple.locations().length();
    // Save the argument registers, in reverse order.
    for (intptr_t i = num; i-- > 0;) {
      SaveArgument(compiler, *multiple.locations().At(i));
    }
  } else {
    ASSERT(nloc.IsBoth());
    const auto& both = nloc.AsBoth();
    SaveArgument(compiler, both.location(0));
  }
}

LocationSummary* OsrEntryInstr::MakeLocationSummary(Zone* zone,
                                                    bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void OsrEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!CompilerState::Current().is_aot());
  ASSERT(compiler->is_optimizing());
  __ Bind(compiler->GetJumpLabel(this));

  // NOTE: Because the graph can have multiple entrypoints, we generate several
  // times the same intrinsification & frame setup. That's why we cannot rely on
  // the constant pool being `false` when we come in here.
#if defined(TARGET_USES_OBJECT_POOL)
  __ set_constant_pool_allowed(false);
#endif

  compiler->EmitPrologue();

#if defined(TARGET_USES_OBJECT_POOL)
  ASSERT(__ constant_pool_allowed());
#endif

  if (HasParallelMove()) {
    if (compiler::Assembler::EmittingComments()) {
      compiler->EmitComment(parallel_move());
    }
    parallel_move()->EmitNativeCode(compiler);
  }
}

void IndirectGotoInstr::ComputeOffsetTable(FlowGraphCompiler* compiler) {
  ASSERT(SuccessorCount() == offsets_.Length());
  intptr_t element_size = offsets_.ElementSizeInBytes();
  for (intptr_t i = 0; i < SuccessorCount(); i++) {
    TargetEntryInstr* target = SuccessorAt(i);
    auto* label = compiler->GetJumpLabel(target);
    RELEASE_ASSERT(label != nullptr);
    RELEASE_ASSERT(label->IsBound());
    intptr_t offset = label->Position();
    RELEASE_ASSERT(offset > 0);
    offsets_.SetInt32(i * element_size, offset);
  }
}

LocationSummary* IndirectEntryInstr::MakeLocationSummary(
    Zone* zone,
    bool optimizing) const {
  return JoinEntryInstr::MakeLocationSummary(zone, optimizing);
}

void IndirectEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  JoinEntryInstr::EmitNativeCode(compiler);
}

LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const bool use_shared_stub = UseSharedSlowPathStub(opt);
  const intptr_t kNumTemps = calls_initializer() &&
                                     throw_exception_on_initialization() &&
                                     use_shared_stub
                                 ? 1
                                 : 0;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      calls_initializer()
          ? (throw_exception_on_initialization()
                 ? (use_shared_stub ? LocationSummary::kCallOnSharedSlowPath
                                    : LocationSummary::kCallOnSlowPath)
                 : LocationSummary::kCall)
          : LocationSummary::kNoCall);
  if (calls_initializer() && throw_exception_on_initialization() &&
      use_shared_stub) {
    locs->set_temp(
        0, Location::RegisterLocation(LateInitializationErrorABI::kFieldReg));
  }
  locs->set_out(0, calls_initializer() ? Location::RegisterLocation(
                                             InitStaticFieldABI::kResultReg)
                                       : Location::RequiresRegister());
  return locs;
}

void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();

  compiler->used_static_fields().Add(&field());

  // Note: static fields ids won't be changed by hot-reload.
  const intptr_t field_table_offset =
      compiler::target::Thread::field_table_values_offset();
  const intptr_t field_offset = compiler::target::FieldTable::OffsetOf(field());

  __ LoadMemoryValue(result, THR, static_cast<int32_t>(field_table_offset));
  __ LoadMemoryValue(result, result, static_cast<int32_t>(field_offset));

  if (calls_initializer()) {
    if (throw_exception_on_initialization()) {
      ThrowErrorSlowPathCode* slow_path =
          new LateInitializationErrorSlowPath(this);
      compiler->AddSlowPathCode(slow_path);

      __ CompareObject(result, Object::sentinel());
      __ BranchIf(EQUAL, slow_path->entry_label());
      return;
    }
    ASSERT(field().has_initializer());
    auto object_store = compiler->isolate_group()->object_store();
    const Field& original_field = Field::ZoneHandle(field().Original());

    compiler::Label no_call, call_initializer;
    __ CompareObject(result, Object::sentinel());
    if (!field().is_late()) {
      __ BranchIf(EQUAL, &call_initializer);
      __ CompareObject(result, Object::transition_sentinel());
    }
    __ BranchIf(NOT_EQUAL, &no_call);

    auto& stub = Code::ZoneHandle(compiler->zone());
    __ Bind(&call_initializer);
    if (field().needs_load_guard()) {
      stub = object_store->init_static_field_stub();
    } else if (field().is_late()) {
      // The stubs below call the initializer function directly, so make sure
      // one is created.
      original_field.EnsureInitializerFunction();
      stub = field().is_final()
                 ? object_store->init_late_final_static_field_stub()
                 : object_store->init_late_static_field_stub();
    } else {
      // We call to runtime for non-late fields because the stub would need to
      // catch any exception generated by the initialization function to change
      // the value of the static field from the transition sentinel to null.
      stub = object_store->init_static_field_stub();
    }

    __ LoadObject(InitStaticFieldABI::kFieldReg, original_field);
    compiler->GenerateStubCall(source(), stub,
                               /*kind=*/UntaggedPcDescriptors::kOther, locs(),
                               deopt_id(), env());

    __ Bind(&no_call);
  }
}

LocationSummary* LoadFieldInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  LocationSummary* locs = nullptr;
  if (slot().representation() != kTagged) {
    ASSERT(!calls_initializer());

    const intptr_t kNumTemps = 0;
    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    if (RepresentationUtils::IsUnboxedInteger(slot().representation())) {
      const size_t value_size =
          RepresentationUtils::ValueSize(slot().representation());
      if (value_size <= compiler::target::kWordSize) {
        locs->set_out(0, Location::RequiresRegister());
      } else {
        ASSERT(value_size == 2 * compiler::target::kWordSize);
        locs->set_out(0, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
      }
    } else {
      locs->set_out(0, Location::RequiresFpuRegister());
    }
  } else if (calls_initializer()) {
    if (throw_exception_on_initialization()) {
      const bool using_shared_stub = UseSharedSlowPathStub(opt);
      const intptr_t kNumTemps = using_shared_stub ? 1 : 0;
      locs = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps,
          using_shared_stub ? LocationSummary::kCallOnSharedSlowPath
                            : LocationSummary::kCallOnSlowPath);
      if (using_shared_stub) {
        locs->set_temp(0, Location::RegisterLocation(
                              LateInitializationErrorABI::kFieldReg));
      }
      locs->set_in(0, Location::RequiresRegister());
      locs->set_out(0, Location::RequiresRegister());
    } else {
      const intptr_t kNumTemps = 0;
      locs = new (zone)
          LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
      locs->set_in(
          0, Location::RegisterLocation(InitInstanceFieldABI::kInstanceReg));
      locs->set_out(
          0, Location::RegisterLocation(InitInstanceFieldABI::kResultReg));
    }
  } else {
    const intptr_t kNumTemps = 0;
    locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}

void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register instance_reg = locs()->in(0).reg();
  if (representation() != kTagged) {
    if (RepresentationUtils::IsUnboxedInteger(representation())) {
      const size_t value_size =
          RepresentationUtils::ValueSize(representation());
      if (value_size <= compiler::target::kWordSize) {
        const Register result = locs()->out(0).reg();
        __ LoadFieldFromOffset(
            result, instance_reg, OffsetInBytes(),
            RepresentationUtils::OperandSize(representation()));
      } else {
        auto const result_pair = locs()->out(0).AsPairLocation();
        const Register result_lo = result_pair->At(0).reg();
        const Register result_hi = result_pair->At(1).reg();
        __ LoadFieldFromOffset(result_lo, instance_reg, OffsetInBytes());
        __ LoadFieldFromOffset(result_hi, instance_reg,
                               OffsetInBytes() + compiler::target::kWordSize);
      }
    } else {
      const FpuRegister result = locs()->out(0).fpu_reg();
      const intptr_t cid = slot().field().guarded_cid();
      switch (cid) {
        case kDoubleCid:
          __ LoadUnboxedDouble(result, instance_reg,
                               OffsetInBytes() - kHeapObjectTag);
          break;
        case kFloat32x4Cid:
        case kFloat64x2Cid:
          __ LoadUnboxedSimd128(result, instance_reg,
                                OffsetInBytes() - kHeapObjectTag);
          break;
        default:
          UNREACHABLE();
      }
    }
    return;
  }

  // Tagged load.
  const Register result = locs()->out(0).reg();
  if (slot().is_compressed()) {
    __ LoadCompressedFieldFromOffset(result, instance_reg, OffsetInBytes());
  } else {
    __ LoadFieldFromOffset(result, instance_reg, OffsetInBytes());
  }

  if (calls_initializer()) {
    EmitNativeCodeForInitializerCall(compiler);
  }
}

void LoadFieldInstr::EmitNativeCodeForInitializerCall(
    FlowGraphCompiler* compiler) {
  ASSERT(calls_initializer());

  if (throw_exception_on_initialization()) {
    ThrowErrorSlowPathCode* slow_path =
        new LateInitializationErrorSlowPath(this);
    compiler->AddSlowPathCode(slow_path);

    const Register result_reg = locs()->out(0).reg();
    __ CompareObject(result_reg, Object::sentinel());
    __ BranchIf(EQUAL, slow_path->entry_label());
    return;
  }

  ASSERT(locs()->in(0).reg() == InitInstanceFieldABI::kInstanceReg);
  ASSERT(locs()->out(0).reg() == InitInstanceFieldABI::kResultReg);
  ASSERT(slot().IsDartField());
  const Field& field = slot().field();
  const Field& original_field = Field::ZoneHandle(field.Original());

  compiler::Label no_call;
  __ CompareObject(InitInstanceFieldABI::kResultReg, Object::sentinel());
  __ BranchIf(NOT_EQUAL, &no_call);

  __ LoadObject(InitInstanceFieldABI::kFieldReg, original_field);

  auto object_store = compiler->isolate_group()->object_store();
  auto& stub = Code::ZoneHandle(compiler->zone());
  if (field.needs_load_guard()) {
    stub = object_store->init_instance_field_stub();
  } else if (field.is_late()) {
    if (!field.has_nontrivial_initializer()) {
      stub = object_store->init_instance_field_stub();
    } else {
      // Stubs for late field initialization call initializer
      // function directly, so make sure one is created.
      original_field.EnsureInitializerFunction();

      if (field.is_final()) {
        stub = object_store->init_late_final_instance_field_stub();
      } else {
        stub = object_store->init_late_instance_field_stub();
      }
    }
  } else {
    UNREACHABLE();
  }

  compiler->GenerateStubCall(source(), stub,
                             /*kind=*/UntaggedPcDescriptors::kOther, locs(),
                             deopt_id(), env());
  __ Bind(&no_call);
}

LocationSummary* ThrowInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(ThrowABI::kExceptionReg));
  return summary;
}

void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  auto object_store = compiler->isolate_group()->object_store();
  const auto& throw_stub =
      Code::ZoneHandle(compiler->zone(), object_store->throw_stub());

  compiler->GenerateStubCall(source(), throw_stub,
                             /*kind=*/UntaggedPcDescriptors::kOther, locs(),
                             deopt_id(), env());
  // Issue(dartbug.com/41353): Right now we have to emit an extra breakpoint
  // instruction: The ThrowInstr will terminate the current block. The very
  // next machine code instruction might get a pc descriptor attached with a
  // different try-index. If we removed this breakpoint instruction, the
  // runtime might associated this call with the try-index of the next
  // instruction.
  __ Breakpoint();
}

LocationSummary* ReThrowInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(ReThrowABI::kExceptionReg));
  summary->set_in(1, Location::RegisterLocation(ReThrowABI::kStackTraceReg));
  return summary;
}

void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  auto object_store = compiler->isolate_group()->object_store();
  const auto& re_throw_stub =
      Code::ZoneHandle(compiler->zone(), object_store->re_throw_stub());

  compiler->SetNeedsStackTrace(catch_try_index());
  compiler->GenerateStubCall(source(), re_throw_stub,
                             /*kind=*/UntaggedPcDescriptors::kOther, locs(),
                             deopt_id(), env());
  // Issue(dartbug.com/41353): Right now we have to emit an extra breakpoint
  // instruction: The ThrowInstr will terminate the current block. The very
  // next machine code instruction might get a pc descriptor attached with a
  // different try-index. If we removed this breakpoint instruction, the
  // runtime might associated this call with the try-index of the next
  // instruction.
  __ Breakpoint();
}

LocationSummary* AssertBooleanInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(AssertBooleanABI::kObjectReg));
  locs->set_out(0, Location::RegisterLocation(AssertBooleanABI::kObjectReg));
  return locs;
}

LocationSummary* PhiInstr::MakeLocationSummary(Zone* zone,
                                               bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void PhiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

LocationSummary* RedefinitionInstr::MakeLocationSummary(Zone* zone,
                                                        bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void RedefinitionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

LocationSummary* ReachabilityFenceInstr::MakeLocationSummary(
    Zone* zone,
    bool optimizing) const {
  LocationSummary* summary = new (zone)
      LocationSummary(zone, 1, 0, LocationSummary::ContainsCall::kNoCall);
  // Keep the parameter alive and reachable, in any location.
  summary->set_in(0, Location::Any());
  return summary;
}

void ReachabilityFenceInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // No native code, but we rely on the parameter being passed in here so that
  // it stays alive and reachable.
}

LocationSummary* ParameterInstr::MakeLocationSummary(Zone* zone,
                                                     bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void ParameterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

void NativeParameterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // There are two frames between SaveArguments and the NativeParameterInstr
  // moves.
  constexpr intptr_t delta =
      kCallerSpSlotFromFp          // second frame FP to exit link slot
      + -kExitLinkSlotFromEntryFp  // exit link slot to first frame FP
      + kCallerSpSlotFromFp;       // first frame FP to argument save SP
  compiler::ffi::FrameRebase rebase(compiler->zone(),
                                    /*old_base=*/SPREG, /*new_base=*/FPREG,
                                    delta * compiler::target::kWordSize);
  const auto& location =
      marshaller_.NativeLocationOfNativeParameter(def_index_);
  const auto& src =
      rebase.Rebase(location.IsPointerToMemory()
                        ? location.AsPointerToMemory().pointer_location()
                        : location);
  NoTemporaryAllocator no_temp;
  const Location out_loc = locs()->out(0);
  const Representation out_rep = representation();
  compiler->EmitMoveFromNative(out_loc, out_rep, src, &no_temp);
}

LocationSummary* NativeParameterInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  ASSERT(opt);
  Location output = Location::Any();
  if (representation() == kUnboxedInt64 && compiler::target::kWordSize < 8) {
    output = Location::Pair(Location::RequiresRegister(),
                            Location::RequiresFpuRegister());
  } else {
    output = RegisterKindForResult() == Location::kRegister
                 ? Location::RequiresRegister()
                 : Location::RequiresFpuRegister();
  }
  return LocationSummary::Make(zone, /*num_inputs=*/0, output,
                               LocationSummary::kNoCall);
}

bool ParallelMoveInstr::IsRedundant() const {
  for (intptr_t i = 0; i < moves_.length(); i++) {
    if (!moves_[i]->IsRedundant()) {
      return false;
    }
  }
  return true;
}

LocationSummary* ParallelMoveInstr::MakeLocationSummary(Zone* zone,
                                                        bool optimizing) const {
  return nullptr;
}

void ParallelMoveInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ParallelMoveEmitter(compiler, this).EmitNativeCode();
}

LocationSummary* ConstraintInstr::MakeLocationSummary(Zone* zone,
                                                      bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void ConstraintInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

LocationSummary* MaterializeObjectInstr::MakeLocationSummary(
    Zone* zone,
    bool optimizing) const {
  UNREACHABLE();
  return nullptr;
}

void MaterializeObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

// This function should be kept in sync with
// FlowGraphCompiler::SlowPathEnvironmentFor().
void MaterializeObjectInstr::RemapRegisters(intptr_t* cpu_reg_slots,
                                            intptr_t* fpu_reg_slots) {
  if (registers_remapped_) {
    return;
  }
  registers_remapped_ = true;

  for (intptr_t i = 0; i < InputCount(); i++) {
    locations_[i] = LocationRemapForSlowPath(
        LocationAt(i), InputAt(i)->definition(), cpu_reg_slots, fpu_reg_slots);
  }
}

const char* SpecialParameterInstr::KindToCString(SpecialParameterKind k) {
  switch (k) {
#define KIND_CASE(Name)                                                        \
  case SpecialParameterKind::k##Name:                                          \
    return #Name;
    FOR_EACH_SPECIAL_PARAMETER_KIND(KIND_CASE)
#undef KIND_CASE
  }
  return nullptr;
}

bool SpecialParameterInstr::ParseKind(const char* str,
                                      SpecialParameterKind* out) {
  ASSERT(str != nullptr && out != nullptr);
#define KIND_CASE(Name)                                                        \
  if (strcmp(str, #Name) == 0) {                                               \
    *out = SpecialParameterKind::k##Name;                                      \
    return true;                                                               \
  }
  FOR_EACH_SPECIAL_PARAMETER_KIND(KIND_CASE)
#undef KIND_CASE
  return false;
}

LocationSummary* SpecialParameterInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  // Only appears in initial definitions, never in normal code.
  UNREACHABLE();
  return nullptr;
}

void SpecialParameterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Only appears in initial definitions, never in normal code.
  UNREACHABLE();
}

LocationSummary* MakeTempInstr::MakeLocationSummary(Zone* zone,
                                                    bool optimizing) const {
  ASSERT(!optimizing);
  null_->InitializeLocationSummary(zone, optimizing);
  return null_->locs();
}

void MakeTempInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  null_->EmitNativeCode(compiler);
}

LocationSummary* DropTempsInstr::MakeLocationSummary(Zone* zone,
                                                     bool optimizing) const {
  ASSERT(!optimizing);
  return (InputCount() == 1)
             ? LocationSummary::Make(zone, 1, Location::SameAsFirstInput(),
                                     LocationSummary::kNoCall)
             : LocationSummary::Make(zone, 0, Location::NoLocation(),
                                     LocationSummary::kNoCall);
}

void DropTempsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  // Assert that register assignment is correct.
  ASSERT((InputCount() == 0) || (locs()->out(0).reg() == locs()->in(0).reg()));
  __ Drop(num_temps());
}

LocationSummary* BoxSmallIntInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  ASSERT(RepresentationUtils::ValueSize(from_representation()) * kBitsPerByte <=
         compiler::target::kSmiBits);
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

void BoxSmallIntInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  ASSERT(value != out);

  __ ExtendAndSmiTagValue(
      out, value, RepresentationUtils::OperandSize(from_representation()));
}

StrictCompareInstr::StrictCompareInstr(const InstructionSource& source,
                                       Token::Kind kind,
                                       Value* left,
                                       Value* right,
                                       bool needs_number_check,
                                       intptr_t deopt_id)
    : TemplateComparison(source, kind, deopt_id),
      needs_number_check_(needs_number_check) {
  ASSERT((kind == Token::kEQ_STRICT) || (kind == Token::kNE_STRICT));
  SetInputAt(0, left);
  SetInputAt(1, right);
}

Condition StrictCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                 BranchLabels labels) {
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());
  Condition true_condition;
  if (left.IsConstant()) {
    if (TryEmitBoolTest(compiler, labels, 1, left.constant(),
                        &true_condition)) {
      return true_condition;
    }
    true_condition = EmitComparisonCodeRegConstant(
        compiler, labels, right.reg(), left.constant());
  } else if (right.IsConstant()) {
    if (TryEmitBoolTest(compiler, labels, 0, right.constant(),
                        &true_condition)) {
      return true_condition;
    }
    true_condition = EmitComparisonCodeRegConstant(compiler, labels, left.reg(),
                                                   right.constant());
  } else {
    true_condition = compiler->EmitEqualityRegRegCompare(
        left.reg(), right.reg(), needs_number_check(), source(), deopt_id());
  }
  return true_condition != kInvalidCondition && (kind() != Token::kEQ_STRICT)
             ? InvertCondition(true_condition)
             : true_condition;
}

bool StrictCompareInstr::TryEmitBoolTest(FlowGraphCompiler* compiler,
                                         BranchLabels labels,
                                         intptr_t input_index,
                                         const Object& obj,
                                         Condition* true_condition_out) {
  CompileType* input_type = InputAt(input_index)->Type();
  if (input_type->ToCid() == kBoolCid && obj.GetClassId() == kBoolCid) {
    bool invert = (kind() != Token::kEQ_STRICT) ^ !Bool::Cast(obj).value();
    *true_condition_out =
        compiler->EmitBoolTest(locs()->in(input_index).reg(), labels, invert);
    return true;
  }
  return false;
}

LocationSummary* LoadClassIdInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register object = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  if (input_can_be_smi_ && this->object()->Type()->CanBeSmi()) {
    if (representation() == kTagged) {
      __ LoadTaggedClassIdMayBeSmi(result, object);
    } else {
      __ LoadClassIdMayBeSmi(result, object);
    }
  } else {
    __ LoadClassId(result, object);
    if (representation() == kTagged) {
      __ SmiTag(result);
    }
  }
}

LocationSummary* TestRangeInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_ARM)
  const bool needs_temp = true;
#else
  const bool needs_temp = false;
#endif
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (needs_temp) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

Condition TestRangeInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                             BranchLabels labels) {
  intptr_t lower = lower_;
  intptr_t upper = upper_;
  if (value_representation_ == kTagged) {
    lower = Smi::RawValue(lower);
    upper = Smi::RawValue(upper);
  }

  Register in = locs()->in(0).reg();
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_ARM)
  Register temp = locs()->temp(0).reg();
#else
  Register temp = TMP;
#endif
  __ AddImmediate(temp, in, -lower);
  __ CompareImmediate(temp, upper - lower);
  ASSERT((kind() == Token::kIS) || (kind() == Token::kISNOT));
  return kind() == Token::kIS ? UNSIGNED_LESS_EQUAL : UNSIGNED_GREATER;
}

LocationSummary* InstanceCallInstr::MakeLocationSummary(Zone* zone,
                                                        bool optimizing) const {
  return MakeCallSummary(zone, this);
}

static CodePtr TwoArgsSmiOpInlineCacheEntry(Token::Kind kind) {
  if (!FLAG_two_args_smi_icd) {
    return Code::null();
  }
  switch (kind) {
    case Token::kADD:
      return StubCode::SmiAddInlineCache().ptr();
    case Token::kLT:
      return StubCode::SmiLessInlineCache().ptr();
    case Token::kEQ:
      return StubCode::SmiEqualInlineCache().ptr();
    default:
      return Code::null();
  }
}

bool InstanceCallBaseInstr::CanReceiverBeSmiBasedOnInterfaceTarget(
    Zone* zone) const {
  if (!interface_target().IsNull()) {
    // Note: target_type is fully instantiated rare type (all type parameters
    // are replaced with dynamic) so checking if Smi is assignable to
    // it would compute correctly whether or not receiver can be a smi.
    const AbstractType& target_type = AbstractType::Handle(
        zone, Class::Handle(zone, interface_target().Owner()).RareType());
    if (!CompileType::Smi().IsAssignableTo(target_type)) {
      return false;
    }
  }
  // In all other cases conservatively assume that the receiver can be a smi.
  return true;
}

Representation InstanceCallBaseInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // The first input is the array of types
  // for generic functions
  if (type_args_len() > 0) {
    if (idx == 0) {
      return kTagged;
    }
    idx--;
  }
  return FlowGraph::ParameterRepresentationAt(interface_target(), idx);
}

intptr_t InstanceCallBaseInstr::ArgumentsSize() const {
  if (interface_target().IsNull()) {
    return ArgumentCountWithoutTypeArgs() + ((type_args_len() > 0) ? 1 : 0);
  }

  return FlowGraph::ParameterOffsetAt(interface_target(),
                                      ArgumentCountWithoutTypeArgs(),
                                      /*last_slot=*/false) +
         ((type_args_len() > 0) ? 1 : 0);
}

Representation InstanceCallBaseInstr::representation() const {
  return FlowGraph::ReturnRepresentationOf(interface_target());
}

void InstanceCallBaseInstr::UpdateReceiverSminess(Zone* zone) {
  if (CompilerState::Current().is_aot() && !receiver_is_not_smi()) {
    if (!Receiver()->Type()->CanBeSmi() ||
        !CanReceiverBeSmiBasedOnInterfaceTarget(zone)) {
      set_receiver_is_not_smi(true);
    }
  }
}

static FunctionPtr FindBinarySmiOp(Zone* zone, const String& name) {
  const auto& smi_class = Class::Handle(zone, Smi::Class());
  auto& smi_op_target = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, smi_class, name));

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (smi_op_target.IsNull() &&
      Function::IsDynamicInvocationForwarderName(name)) {
    const String& demangled = String::Handle(
        zone, Function::DemangleDynamicInvocationForwarderName(name));
    smi_op_target = Resolver::ResolveDynamicAnyArgs(zone, smi_class, demangled);
  }
#endif
  return smi_op_target.ptr();
}

void InstanceCallInstr::EnsureICData(FlowGraph* graph) {
  if (HasICData()) {
    return;
  }

  const Array& arguments_descriptor =
      Array::Handle(graph->zone(), GetArgumentsDescriptor());
  const ICData& ic_data = ICData::ZoneHandle(
      graph->zone(),
      ICData::New(graph->function(), function_name(), arguments_descriptor,
                  deopt_id(), checked_argument_count(), ICData::kInstance));
  set_ic_data(&ic_data);
}

void InstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Zone* zone = compiler->zone();

  UpdateReceiverSminess(zone);

  auto& specialized_binary_smi_ic_stub = Code::ZoneHandle(zone);
  auto& binary_smi_op_target = Function::Handle(zone);
  if (!receiver_is_not_smi()) {
    specialized_binary_smi_ic_stub = TwoArgsSmiOpInlineCacheEntry(token_kind());
    if (!specialized_binary_smi_ic_stub.IsNull()) {
      binary_smi_op_target = FindBinarySmiOp(zone, function_name());
    }
  }

  const ICData* call_ic_data = nullptr;
  if (!FLAG_propagate_ic_data || !compiler->is_optimizing() ||
      (ic_data() == nullptr)) {
    const Array& arguments_descriptor =
        Array::Handle(zone, GetArgumentsDescriptor());

    AbstractType& receivers_static_type = AbstractType::Handle(zone);
    if (receivers_static_type_ != nullptr) {
      receivers_static_type = receivers_static_type_->ptr();
    }

    call_ic_data = compiler->GetOrAddInstanceCallICData(
        deopt_id(), function_name(), arguments_descriptor,
        checked_argument_count(), receivers_static_type, binary_smi_op_target);
  } else {
    call_ic_data = &ICData::ZoneHandle(zone, ic_data()->ptr());
  }

  if (compiler->is_optimizing() && HasICData()) {
    if (ic_data()->NumberOfUsedChecks() > 0) {
      const ICData& unary_ic_data =
          ICData::ZoneHandle(zone, ic_data()->AsUnaryClassChecks());
      compiler->GenerateInstanceCall(deopt_id(), source(), locs(),
                                     unary_ic_data, entry_kind(),
                                     !receiver_is_not_smi());
    } else {
      // Call was not visited yet, use original ICData in order to populate it.
      compiler->GenerateInstanceCall(deopt_id(), source(), locs(),
                                     *call_ic_data, entry_kind(),
                                     !receiver_is_not_smi());
    }
  } else {
    // Unoptimized code.
    compiler->AddCurrentDescriptor(UntaggedPcDescriptors::kRewind, deopt_id(),
                                   source());

    // If the ICData contains a (Smi, Smi, <binary-smi-op-target>) stub already
    // we will call the specialized IC Stub that works as a normal IC Stub but
    // has inlined fast path for the specific Smi operation.
    bool use_specialized_smi_ic_stub = false;
    if (!specialized_binary_smi_ic_stub.IsNull() &&
        call_ic_data->NumberOfChecksIs(1)) {
      GrowableArray<intptr_t> class_ids(2);
      auto& target = Function::Handle();
      call_ic_data->GetCheckAt(0, &class_ids, &target);
      if (class_ids[0] == kSmiCid && class_ids[1] == kSmiCid &&
          target.ptr() == binary_smi_op_target.ptr()) {
        use_specialized_smi_ic_stub = true;
      }
    }

    if (use_specialized_smi_ic_stub) {
      ASSERT(ArgumentCount() == 2);
      compiler->EmitInstanceCallJIT(specialized_binary_smi_ic_stub,
                                    *call_ic_data, deopt_id(), source(), locs(),
                                    entry_kind());
    } else {
      compiler->GenerateInstanceCall(deopt_id(), source(), locs(),
                                     *call_ic_data, entry_kind(),
                                     !receiver_is_not_smi());
    }
  }
}

bool InstanceCallInstr::MatchesCoreName(const String& name) {
  return Library::IsPrivateCoreLibName(function_name(), name);
}

FunctionPtr InstanceCallBaseInstr::ResolveForReceiverClass(
    const Class& cls,
    bool allow_add /* = true */) {
  const Array& args_desc_array = Array::Handle(GetArgumentsDescriptor());
  ArgumentsDescriptor args_desc(args_desc_array);
  return Resolver::ResolveDynamicForReceiverClass(cls, function_name(),
                                                  args_desc, allow_add);
}

const CallTargets& InstanceCallInstr::Targets() {
  if (targets_ == nullptr) {
    Zone* zone = Thread::Current()->zone();
    if (HasICData()) {
      targets_ = CallTargets::CreateAndExpand(zone, *ic_data());
    } else {
      targets_ = new (zone) CallTargets(zone);
      ASSERT(targets_->is_empty());
    }
  }
  return *targets_;
}

const BinaryFeedback& InstanceCallInstr::BinaryFeedback() {
  if (binary_ == nullptr) {
    Zone* zone = Thread::Current()->zone();
    if (HasICData()) {
      binary_ = BinaryFeedback::Create(zone, *ic_data());
    } else {
      binary_ = new (zone) class BinaryFeedback(zone);
    }
  }
  return *binary_;
}

Representation DispatchTableCallInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  if (idx == (InputCount() - 1)) {
    return kUnboxedUword;  // Receiver's CID.
  }

  // The first input is the array of types
  // for generic functions
  if (type_args_len() > 0) {
    if (idx == 0) {
      return kTagged;
    }
    idx--;
  }
  return FlowGraph::ParameterRepresentationAt(interface_target(), idx);
}

intptr_t DispatchTableCallInstr::ArgumentsSize() const {
  if (interface_target().IsNull()) {
    return ArgumentCountWithoutTypeArgs() + ((type_args_len() > 0) ? 1 : 0);
  }

  return FlowGraph::ParameterOffsetAt(interface_target(),
                                      ArgumentCountWithoutTypeArgs(),
                                      /*last_slot=*/false) +
         ((type_args_len() > 0) ? 1 : 0);
}

Representation DispatchTableCallInstr::representation() const {
  return FlowGraph::ReturnRepresentationOf(interface_target());
}

DispatchTableCallInstr* DispatchTableCallInstr::FromCall(
    Zone* zone,
    const InstanceCallBaseInstr* call,
    Value* cid,
    const Function& interface_target,
    const compiler::TableSelector* selector) {
  InputsArray args(zone, call->ArgumentCount() + 1);
  for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
    args.Add(call->ArgumentValueAt(i)->CopyWithType());
  }
  args.Add(cid);
  auto dispatch_table_call = new (zone) DispatchTableCallInstr(
      call->source(), interface_target, selector, std::move(args),
      call->type_args_len(), call->argument_names());
  return dispatch_table_call;
}

LocationSummary* DispatchTableCallInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(
      0, Location::RegisterLocation(DispatchTableNullErrorABI::kClassIdReg));
  return MakeCallSummary(zone, this, summary);
}

void DispatchTableCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == DispatchTableNullErrorABI::kClassIdReg);
  Array& arguments_descriptor = Array::ZoneHandle();
  if (selector()->requires_args_descriptor) {
    ArgumentsInfo args_info(type_args_len(), ArgumentCount(), ArgumentsSize(),
                            argument_names());
    arguments_descriptor = args_info.ToArgumentsDescriptor();
  }
  compiler->EmitDispatchTableCall(selector()->offset, arguments_descriptor);
  compiler->EmitCallsiteMetadata(source(), DeoptId::kNone,
                                 UntaggedPcDescriptors::kOther, locs(), env());
  if (selector()->called_on_null && !selector()->on_null_interface) {
    Value* receiver = ArgumentValueAt(FirstArgIndex());
    if (receiver->Type()->is_nullable()) {
      const String& function_name =
          String::ZoneHandle(interface_target().name());
      compiler->AddNullCheck(source(), function_name);
    }
  }
  compiler->EmitDropArguments(ArgumentsSize());
  compiler->AddDispatchTableCallTarget(selector());
}

Representation StaticCallInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // The first input is the array of types
  // for generic functions
  if (type_args_len() > 0 || function().IsFactory()) {
    if (idx == 0) {
      return kTagged;
    }
    idx--;
  }
  return FlowGraph::ParameterRepresentationAt(function(), idx);
}

intptr_t StaticCallInstr::ArgumentsSize() const {
  return FlowGraph::ParameterOffsetAt(function(),
                                      ArgumentCountWithoutTypeArgs(),
                                      /*last_slot=*/false) +
         ((type_args_len() > 0) ? 1 : 0);
}

Representation StaticCallInstr::representation() const {
  return FlowGraph::ReturnRepresentationOf(function());
}

const CallTargets& StaticCallInstr::Targets() {
  if (targets_ == nullptr) {
    Zone* zone = Thread::Current()->zone();
    if (HasICData()) {
      targets_ = CallTargets::CreateAndExpand(zone, *ic_data());
    } else {
      targets_ = new (zone) CallTargets(zone);
      ASSERT(targets_->is_empty());
    }
  }
  return *targets_;
}

const BinaryFeedback& StaticCallInstr::BinaryFeedback() {
  if (binary_ == nullptr) {
    Zone* zone = Thread::Current()->zone();
    if (HasICData()) {
      binary_ = BinaryFeedback::Create(zone, *ic_data());
    } else {
      binary_ = new (zone) class BinaryFeedback(zone);
    }
  }
  return *binary_;
}

bool CallTargets::HasSingleRecognizedTarget() const {
  if (!HasSingleTarget()) return false;
  return FirstTarget().recognized_kind() != MethodRecognizer::kUnknown;
}

bool CallTargets::HasSingleTarget() const {
  if (length() == 0) return false;
  for (int i = 0; i < length(); i++) {
    if (TargetAt(i)->target->ptr() != TargetAt(0)->target->ptr()) return false;
  }
  return true;
}

const Function& CallTargets::FirstTarget() const {
  ASSERT(length() != 0);
  DEBUG_ASSERT(TargetAt(0)->target->IsNotTemporaryScopedHandle());
  return *TargetAt(0)->target;
}

const Function& CallTargets::MostPopularTarget() const {
  ASSERT(length() != 0);
  DEBUG_ASSERT(TargetAt(0)->target->IsNotTemporaryScopedHandle());
  for (int i = 1; i < length(); i++) {
    ASSERT(TargetAt(i)->count <= TargetAt(0)->count);
  }
  return *TargetAt(0)->target;
}

intptr_t CallTargets::AggregateCallCount() const {
  intptr_t sum = 0;
  for (int i = 0; i < length(); i++) {
    sum += TargetAt(i)->count;
  }
  return sum;
}

bool PolymorphicInstanceCallInstr::HasOnlyDispatcherOrImplicitAccessorTargets()
    const {
  const intptr_t len = targets_.length();
  Function& target = Function::Handle();
  for (intptr_t i = 0; i < len; i++) {
    target = targets_.TargetAt(i)->target->ptr();
    if (!target.IsDispatcherOrImplicitAccessor()) {
      return false;
    }
  }
  return true;
}

intptr_t PolymorphicInstanceCallInstr::CallCount() const {
  return targets().AggregateCallCount();
}

LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    Zone* zone,
    bool optimizing) const {
  return MakeCallSummary(zone, this);
}

void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ArgumentsInfo args_info(type_args_len(), ArgumentCount(), ArgumentsSize(),
                          argument_names());
  UpdateReceiverSminess(compiler->zone());
  compiler->EmitPolymorphicInstanceCall(
      this, targets(), args_info, deopt_id(), source(), locs(), complete(),
      total_call_count(), !receiver_is_not_smi());
}

TypePtr PolymorphicInstanceCallInstr::ComputeRuntimeType(
    const CallTargets& targets) {
  bool is_string = true;
  bool is_integer = true;
  bool is_double = true;
  bool is_type = true;

  const intptr_t num_checks = targets.length();
  for (intptr_t i = 0; i < num_checks; i++) {
    ASSERT(targets.TargetAt(i)->target->ptr() ==
           targets.TargetAt(0)->target->ptr());
    const intptr_t start = targets[i].cid_start;
    const intptr_t end = targets[i].cid_end;
    for (intptr_t cid = start; cid <= end; cid++) {
      is_string = is_string && IsStringClassId(cid);
      is_integer = is_integer && IsIntegerClassId(cid);
      is_double = is_double && (cid == kDoubleCid);
      is_type = is_type && IsTypeClassId(cid);
    }
  }

  if (is_string) {
    ASSERT(!is_integer);
    ASSERT(!is_double);
    ASSERT(!is_type);
    return Type::StringType();
  } else if (is_integer) {
    ASSERT(!is_double);
    ASSERT(!is_type);
    return Type::IntType();
  } else if (is_double) {
    ASSERT(!is_type);
    return Type::Double();
  } else if (is_type) {
    return Type::DartTypeType();
  }

  return Type::null();
}

Definition* InstanceCallInstr::Canonicalize(FlowGraph* flow_graph) {
  const intptr_t receiver_cid = Receiver()->Type()->ToCid();

  // We could turn cold call sites for known receiver cids into a StaticCall.
  // However, that keeps the ICData of the InstanceCall from being updated.
  //
  // This is fine if there is no later deoptimization, but if there is, then
  // the InstanceCall with the updated ICData for this receiver may then be
  // better optimized by the compiler.
  //
  // This optimization is safe to apply in AOT mode because deoptimization is
  // not a concern there.
  //
  // TODO(dartbug.com/37291): Allow this optimization, but accumulate affected
  // InstanceCallInstrs and the corresponding receiver cids during compilation.
  // After compilation, add receiver checks to the ICData for those call sites.
  if (!CompilerState::Current().is_aot() && Targets().is_empty()) {
    return this;
  }

  const CallTargets* new_target =
      FlowGraphCompiler::ResolveCallTargetsForReceiverCid(
          receiver_cid,
          String::Handle(flow_graph->zone(), ic_data()->target_name()),
          Array::Handle(flow_graph->zone(), ic_data()->arguments_descriptor()));
  if (new_target == nullptr) {
    // No specialization.
    return this;
  }

  ASSERT(new_target->HasSingleTarget());
  const Function& target = new_target->FirstTarget();
  StaticCallInstr* specialized = StaticCallInstr::FromCall(
      flow_graph->zone(), this, target, new_target->AggregateCallCount());
  flow_graph->InsertBefore(this, specialized, env(), FlowGraph::kValue);
  return specialized;
}

Definition* DispatchTableCallInstr::Canonicalize(FlowGraph* flow_graph) {
  // TODO(dartbug.com/40188): Allow this to canonicalize into a StaticCall when
  // when input class id is constant;
  return this;
}

Definition* PolymorphicInstanceCallInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!IsSureToCallSingleRecognizedTarget()) {
    return this;
  }

  const Function& target = targets().FirstTarget();
  if (target.recognized_kind() == MethodRecognizer::kObjectRuntimeType) {
    const AbstractType& type =
        AbstractType::Handle(ComputeRuntimeType(targets_));
    if (!type.IsNull()) {
      return flow_graph->GetConstant(type);
    }
  }

  return this;
}

bool PolymorphicInstanceCallInstr::IsSureToCallSingleRecognizedTarget() const {
  if (CompilerState::Current().is_aot() && !complete()) return false;
  return targets_.HasSingleRecognizedTarget();
}

bool StaticCallInstr::InitResultType(Zone* zone) {
  const intptr_t list_cid = FactoryRecognizer::GetResultCidOfListFactory(
      zone, function(), ArgumentCount());
  if (list_cid != kDynamicCid) {
    SetResultType(zone, CompileType::FromCid(list_cid));
    set_is_known_list_constructor(true);
    return true;
  } else if (function().has_pragma()) {
    const intptr_t recognized_cid =
        MethodRecognizer::ResultCidFromPragma(function());
    if (recognized_cid != kDynamicCid) {
      SetResultType(zone, CompileType::FromCid(recognized_cid));
      return true;
    }
  }
  return false;
}

static const String& EvaluateToString(Zone* zone, Definition* defn) {
  if (auto konst = defn->AsConstant()) {
    const Object& obj = konst->value();
    if (obj.IsString()) {
      return String::Cast(obj);
    } else if (obj.IsSmi()) {
      const char* cstr = obj.ToCString();
      return String::Handle(zone, String::New(cstr, Heap::kOld));
    } else if (obj.IsBool()) {
      return Bool::Cast(obj).value() ? Symbols::True() : Symbols::False();
    } else if (obj.IsNull()) {
      return Symbols::null();
    }
  }
  return String::null_string();
}

static Definition* CanonicalizeStringInterpolate(StaticCallInstr* call,
                                                 FlowGraph* flow_graph) {
  auto arg0 = call->ArgumentValueAt(0)->definition();
  auto create_array = arg0->AsCreateArray();
  if (create_array == nullptr) {
    // Do not try to fold interpolate if array is an OSR argument.
    ASSERT(flow_graph->IsCompiledForOsr());
    ASSERT(arg0->IsPhi() || arg0->IsParameter());
    return call;
  }
  // Check if the string interpolation has only constant inputs.
  Value* num_elements = create_array->num_elements();
  if (!num_elements->BindsToConstant() ||
      !num_elements->BoundConstant().IsSmi()) {
    return call;
  }
  const intptr_t length = Smi::Cast(num_elements->BoundConstant()).Value();
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, length);
  for (intptr_t i = 0; i < length; i++) {
    pieces.Add(Object::null_string());
  }

  for (Value::Iterator it(create_array->input_use_list()); !it.Done();
       it.Advance()) {
    auto current = it.Current()->instruction();
    if (current == call) {
      continue;
    }
    auto store = current->AsStoreIndexed();
    if (store == nullptr || !store->index()->BindsToConstant() ||
        !store->index()->BoundConstant().IsSmi()) {
      return call;
    }
    intptr_t store_index = Smi::Cast(store->index()->BoundConstant()).Value();
    ASSERT(store_index < length);
    const String& piece =
        EvaluateToString(flow_graph->zone(), store->value()->definition());
    if (!piece.IsNull()) {
      pieces.SetAt(store_index, piece);
    } else {
      return call;
    }
  }

  const String& concatenated =
      String::ZoneHandle(zone, Symbols::FromConcatAll(thread, pieces));
  return flow_graph->GetConstant(concatenated);
}

static Definition* CanonicalizeStringInterpolateSingle(StaticCallInstr* call,
                                                       FlowGraph* flow_graph) {
  auto arg0 = call->ArgumentValueAt(0)->definition();
  const auto& result = EvaluateToString(flow_graph->zone(), arg0);
  if (!result.IsNull()) {
    return flow_graph->GetConstant(String::ZoneHandle(
        flow_graph->zone(), Symbols::New(flow_graph->thread(), result)));
  }
  return call;
}

Definition* StaticCallInstr::Canonicalize(FlowGraph* flow_graph) {
  auto& compiler_state = CompilerState::Current();

  if (function().ptr() == compiler_state.StringBaseInterpolate().ptr()) {
    return CanonicalizeStringInterpolate(this, flow_graph);
  } else if (function().ptr() ==
             compiler_state.StringBaseInterpolateSingle().ptr()) {
    return CanonicalizeStringInterpolateSingle(this, flow_graph);
  }

  const auto kind = function().recognized_kind();

  if (kind != MethodRecognizer::kUnknown) {
    if (ArgumentCount() == 1) {
      const auto argument = ArgumentValueAt(0);
      if (argument->BindsToConstant()) {
        Object& result = Object::Handle();
        if (Evaluate(flow_graph, argument->BoundConstant(), &result)) {
          return flow_graph->TryCreateConstantReplacementFor(this, result);
        }
      }
    } else if (ArgumentCount() == 2) {
      const auto argument1 = ArgumentValueAt(0);
      const auto argument2 = ArgumentValueAt(1);
      if (argument1->BindsToConstant() && argument2->BindsToConstant()) {
        Object& result = Object::Handle();
        if (Evaluate(flow_graph, argument1->BoundConstant(),
                     argument2->BoundConstant(), &result)) {
          return flow_graph->TryCreateConstantReplacementFor(this, result);
        }
      }
    }
  }

  if (!compiler_state.is_aot()) {
    return this;
  }

  if (kind == MethodRecognizer::kObjectRuntimeType) {
    if (input_use_list() == nullptr) {
      // This function has only environment uses. In precompiled mode it is
      // fine to remove it - because we will never deoptimize.
      return flow_graph->constant_dead();
    }
  }

  return this;
}

bool StaticCallInstr::Evaluate(FlowGraph* flow_graph,
                               const Object& argument,
                               Object* result) {
  const auto kind = function().recognized_kind();
  switch (kind) {
    case MethodRecognizer::kSmi_bitLength: {
      ASSERT(FirstArgIndex() == 0);
      if (argument.IsInteger()) {
        const Integer& value = Integer::Handle(
            flow_graph->zone(),
            Evaluator::BitLengthEvaluate(argument, representation(),
                                         flow_graph->thread()));
        if (!value.IsNull()) {
          *result = value.ptr();
          return true;
        }
      }
      break;
    }
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty: {
      ASSERT(FirstArgIndex() == 0);
      if (argument.IsString()) {
        const auto& str = String::Cast(argument);
        if (kind == MethodRecognizer::kStringBaseLength) {
          *result = Integer::New(str.Length());
        } else {
          *result = Bool::Get(str.Length() == 0).ptr();
          break;
        }
        return true;
      }
      break;
    }
    default:
      break;
  }
  return false;
}

bool StaticCallInstr::Evaluate(FlowGraph* flow_graph,
                               const Object& argument1,
                               const Object& argument2,
                               Object* result) {
  const auto kind = function().recognized_kind();
  switch (kind) {
    case MethodRecognizer::kOneByteString_equality:
    case MethodRecognizer::kTwoByteString_equality: {
      if (argument1.IsString() && argument2.IsString()) {
        *result =
            Bool::Get(String::Cast(argument1).Equals(String::Cast(argument2)))
                .ptr();
        return true;
      }
      break;
    }
    default:
      break;
  }
  return false;
}

LocationSummary* StaticCallInstr::MakeLocationSummary(Zone* zone,
                                                      bool optimizing) const {
  return MakeCallSummary(zone, this);
}

void StaticCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Zone* zone = compiler->zone();
  const ICData* call_ic_data = nullptr;
  if (!FLAG_propagate_ic_data || !compiler->is_optimizing() ||
      (ic_data() == nullptr)) {
    const Array& arguments_descriptor =
        Array::Handle(zone, GetArgumentsDescriptor());
    const int num_args_checked =
        MethodRecognizer::NumArgsCheckedForStaticCall(function());
    call_ic_data = compiler->GetOrAddStaticCallICData(
        deopt_id(), function(), arguments_descriptor, num_args_checked,
        rebind_rule_);
  } else {
    call_ic_data = &ICData::ZoneHandle(ic_data()->ptr());
  }
  ArgumentsInfo args_info(type_args_len(), ArgumentCount(), ArgumentsSize(),
                          argument_names());
  compiler->GenerateStaticCall(deopt_id(), source(), function(), args_info,
                               locs(), *call_ic_data, rebind_rule_,
                               entry_kind());
  if (function().IsFactory()) {
    TypeUsageInfo* type_usage_info = compiler->thread()->type_usage_info();
    if (type_usage_info != nullptr) {
      const Class& klass = Class::Handle(function().Owner());
      RegisterTypeArgumentsUse(compiler->function(), type_usage_info, klass,
                               ArgumentAt(0));
    }
  }
}

intptr_t AssertAssignableInstr::statistics_tag() const {
  switch (kind_) {
    case kParameterCheck:
      return CombinedCodeStatistics::kTagAssertAssignableParameterCheck;
    case kInsertedByFrontend:
      return CombinedCodeStatistics::kTagAssertAssignableInsertedByFrontend;
    case kFromSource:
      return CombinedCodeStatistics::kTagAssertAssignableFromSource;
    case kUnknown:
      break;
  }

  return tag();
}

void AssertAssignableInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateAssertAssignable(value()->Type(), source(), deopt_id(),
                                     env(), dst_name(), locs());
  ASSERT(locs()->in(kInstancePos).reg() == locs()->out(0).reg());
}

LocationSummary* AssertSubtypeInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 5;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(kInstantiatorTAVPos,
                  Location::RegisterLocation(
                      AssertSubtypeABI::kInstantiatorTypeArgumentsReg));
  summary->set_in(
      kFunctionTAVPos,
      Location::RegisterLocation(AssertSubtypeABI::kFunctionTypeArgumentsReg));
  summary->set_in(kSubTypePos,
                  Location::RegisterLocation(AssertSubtypeABI::kSubTypeReg));
  summary->set_in(kSuperTypePos,
                  Location::RegisterLocation(AssertSubtypeABI::kSuperTypeReg));
  summary->set_in(kDstNamePos,
                  Location::RegisterLocation(AssertSubtypeABI::kDstNameReg));
  return summary;
}

void AssertSubtypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateStubCall(source(), StubCode::AssertSubtype(),
                             UntaggedPcDescriptors::kOther, locs(), deopt_id(),
                             env());
}

LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(
                      InstantiateTypeABI::kInstantiatorTypeArgumentsReg));
  locs->set_in(1, Location::RegisterLocation(
                      InstantiateTypeABI::kFunctionTypeArgumentsReg));
  locs->set_out(0,
                Location::RegisterLocation(InstantiateTypeABI::kResultTypeReg));
  return locs;
}

void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  auto& stub = Code::ZoneHandle(StubCode::InstantiateType().ptr());
  if (type().IsTypeParameter()) {
    const auto& type_parameter = TypeParameter::Cast(type());
    const bool is_function_parameter = type_parameter.IsFunctionTypeParameter();

    switch (type_parameter.nullability()) {
      case Nullability::kNonNullable:
        stub = is_function_parameter
                   ? StubCode::InstantiateTypeNonNullableFunctionTypeParameter()
                         .ptr()
                   : StubCode::InstantiateTypeNonNullableClassTypeParameter()
                         .ptr();
        break;
      case Nullability::kNullable:
        stub =
            is_function_parameter
                ? StubCode::InstantiateTypeNullableFunctionTypeParameter().ptr()
                : StubCode::InstantiateTypeNullableClassTypeParameter().ptr();
        break;
      case Nullability::kLegacy:
        stub =
            is_function_parameter
                ? StubCode::InstantiateTypeLegacyFunctionTypeParameter().ptr()
                : StubCode::InstantiateTypeLegacyClassTypeParameter().ptr();
        break;
    }
  }
  __ LoadObject(InstantiateTypeABI::kTypeReg, type());
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
}

LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(
                      InstantiationABI::kInstantiatorTypeArgumentsReg));
  locs->set_in(1, Location::RegisterLocation(
                      InstantiationABI::kFunctionTypeArgumentsReg));
  locs->set_in(2, Location::RegisterLocation(
                      InstantiationABI::kUninstantiatedTypeArgumentsReg));
  locs->set_out(
      0, Location::RegisterLocation(InstantiationABI::kResultTypeArgumentsReg));
  return locs;
}

void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  // We should never try and instantiate a TAV known at compile time to be null,
  // so we can use a null value below for the dynamic case.
  ASSERT(!type_arguments()->BindsToConstant() ||
         !type_arguments()->BoundConstant().IsNull());
  const auto& type_args =
      type_arguments()->BindsToConstant()
          ? TypeArguments::Cast(type_arguments()->BoundConstant())
          : Object::null_type_arguments();
  const intptr_t len = type_args.Length();
  const bool can_function_type_args_be_null =
      function_type_arguments()->CanBe(Object::null_object());

  compiler::Label type_arguments_instantiated;
  if (type_args.IsNull()) {
    // Currently we only create dynamic InstantiateTypeArguments instructions
    // in cases where we know the type argument is uninstantiated at runtime,
    // so there are no extra checks needed to call the stub successfully.
  } else if (type_args.IsRawWhenInstantiatedFromRaw(len) &&
             can_function_type_args_be_null) {
    // If both the instantiator and function type arguments are null and if the
    // type argument vector instantiated from null becomes a vector of dynamic,
    // then use null as the type arguments.
    compiler::Label non_null_type_args;
    __ LoadObject(InstantiationABI::kResultTypeArgumentsReg,
                  Object::null_object());
    __ CompareRegisters(InstantiationABI::kInstantiatorTypeArgumentsReg,
                        InstantiationABI::kResultTypeArgumentsReg);
    if (!function_type_arguments()->BindsToConstant()) {
      __ BranchIf(NOT_EQUAL, &non_null_type_args,
                  compiler::AssemblerBase::kNearJump);
      __ CompareRegisters(InstantiationABI::kFunctionTypeArgumentsReg,
                          InstantiationABI::kResultTypeArgumentsReg);
    }
    __ BranchIf(EQUAL, &type_arguments_instantiated,
                compiler::AssemblerBase::kNearJump);
    __ Bind(&non_null_type_args);
  }

  compiler->GenerateStubCall(source(), GetStub(), UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
  __ Bind(&type_arguments_instantiated);
}

LocationSummary* DeoptimizeInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}

void DeoptimizeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Jump(compiler->AddDeoptStub(deopt_id(), deopt_reason_));
}

void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckClass);
  if (IsNullCheck()) {
    EmitNullCheck(compiler, deopt);
    return;
  }

  ASSERT(!cids_.IsMonomorphic() || !cids_.HasClassId(kSmiCid));
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  compiler::Label is_ok;

  __ BranchIfSmi(value, cids_.HasClassId(kSmiCid) ? &is_ok : deopt);

  __ LoadClassId(temp, value);

  if (IsBitTest()) {
    intptr_t min = cids_.ComputeLowestCid();
    intptr_t max = cids_.ComputeHighestCid();
    EmitBitTest(compiler, min, max, ComputeCidMask(), deopt);
  } else {
    const intptr_t num_checks = cids_.length();
    const bool use_near_jump = num_checks < 5;
    int bias = 0;
    for (intptr_t i = 0; i < num_checks; i++) {
      intptr_t cid_start = cids_[i].cid_start;
      intptr_t cid_end = cids_[i].cid_end;
      if (cid_start == kSmiCid && cid_end == kSmiCid) {
        continue;  // We already handled Smi above.
      }
      if (cid_start == kSmiCid) cid_start++;
      if (cid_end == kSmiCid) cid_end--;
      const bool is_last =
          (i == num_checks - 1) ||
          (i == num_checks - 2 && cids_[i + 1].cid_start == kSmiCid &&
           cids_[i + 1].cid_end == kSmiCid);
      bias = EmitCheckCid(compiler, bias, cid_start, cid_end, is_last, &is_ok,
                          deopt, use_near_jump);
    }
  }
  __ Bind(&is_ok);
}

LocationSummary* GenericCheckBoundInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      UseSharedSlowPathStub(opt) ? LocationSummary::kCallOnSharedSlowPath
                                 : LocationSummary::kCallOnSlowPath);
  locs->set_in(kLengthPos,
               Location::RegisterLocation(RangeErrorABI::kLengthReg));
  locs->set_in(kIndexPos, Location::RegisterLocation(RangeErrorABI::kIndexReg));
  return locs;
}

void GenericCheckBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(representation() == RequiredInputRepresentation(kIndexPos));
  ASSERT(representation() == RequiredInputRepresentation(kLengthPos));

  RangeErrorSlowPath* slow_path = new RangeErrorSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);
  Register length = length_loc.reg();
  Register index = index_loc.reg();
  const intptr_t index_cid = this->index()->Type()->ToCid();

  // The length comes from one of our variable-sized heap objects (e.g. typed
  // data array) and is therefore guaranteed to be in the positive Smi range.
  if (representation() == kTagged) {
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, slow_path->entry_label());
    }
    __ CompareObjectRegisters(index, length);
  } else {
    ASSERT(representation() == kUnboxedInt64);
    __ CompareRegisters(index, length);
  }
  __ BranchIf(UNSIGNED_GREATER_EQUAL, slow_path->entry_label());
}

LocationSummary* CheckNullInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      UseSharedSlowPathStub(opt) ? LocationSummary::kCallOnSharedSlowPath
                                 : LocationSummary::kCallOnSlowPath);
  locs->set_in(0, Location::RequiresRegister());
  return locs;
}

void CheckNullInstr::AddMetadataForRuntimeCall(CheckNullInstr* check_null,
                                               FlowGraphCompiler* compiler) {
  compiler->AddNullCheck(check_null->source(), check_null->function_name());
}

void BoxAllocationSlowPath::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (compiler::Assembler::EmittingComments()) {
    __ Comment("%s slow path allocation of %s", instruction()->DebugName(),
               String::Handle(cls_.ScrubbedName()).ToCString());
  }
  __ Bind(entry_label());
  const auto& stub = Code::ZoneHandle(
      compiler->zone(), StubCode::GetAllocationStubForClass(cls_));

  LocationSummary* locs = instruction()->locs();

  locs->live_registers()->Remove(Location::RegisterLocation(result_));
  compiler->SaveLiveRegisters(locs);
  // Box allocation slow paths cannot lazy-deopt.
  ASSERT(!kAllocateMintRuntimeEntry.can_lazy_deopt() &&
         !kAllocateDoubleRuntimeEntry.can_lazy_deopt() &&
         !kAllocateFloat32x4RuntimeEntry.can_lazy_deopt() &&
         !kAllocateFloat64x2RuntimeEntry.can_lazy_deopt());
  compiler->GenerateNonLazyDeoptableStubCall(
      InstructionSource(),  // No token position.
      stub, UntaggedPcDescriptors::kOther, locs);
  __ MoveRegister(result_, AllocateBoxABI::kResultReg);
  compiler->RestoreLiveRegisters(locs);
  __ Jump(exit_label());
}

void BoxAllocationSlowPath::Allocate(FlowGraphCompiler* compiler,
                                     Instruction* instruction,
                                     const Class& cls,
                                     Register result,
                                     Register temp) {
  if (compiler->intrinsic_mode()) {
    __ TryAllocate(cls, compiler->intrinsic_slow_path_label(),
                   compiler::Assembler::kFarJump, result, temp);
  } else {
    RELEASE_ASSERT(instruction->CanTriggerGC());
    auto slow_path = new BoxAllocationSlowPath(instruction, cls, result);
    compiler->AddSlowPathCode(slow_path);

    if (FLAG_inline_alloc && !FLAG_use_slow_path) {
      __ TryAllocate(cls, slow_path->entry_label(),
                     compiler::Assembler::kFarJump, result, temp);
    } else {
      __ Jump(slow_path->entry_label());
    }
    __ Bind(slow_path->exit_label());
  }
}

void DoubleToIntegerSlowPath::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("DoubleToIntegerSlowPath");
  __ Bind(entry_label());

  LocationSummary* locs = instruction()->locs();
  locs->live_registers()->Remove(locs->out(0));

  compiler->SaveLiveRegisters(locs);

  auto slow_path_env =
      compiler->SlowPathEnvironmentFor(instruction(), /*num_slow_path_args=*/0);

  __ MoveUnboxedDouble(DoubleToIntegerStubABI::kInputReg, value_reg_);
  __ LoadImmediate(
      DoubleToIntegerStubABI::kRecognizedKindReg,
      compiler::target::ToRawSmi(instruction()->recognized_kind()));
  compiler->GenerateStubCall(instruction()->source(),
                             StubCode::DoubleToInteger(),
                             UntaggedPcDescriptors::kOther, locs,
                             instruction()->deopt_id(), slow_path_env);
  __ MoveRegister(instruction()->locs()->out(0).reg(),
                  DoubleToIntegerStubABI::kResultReg);
  compiler->RestoreLiveRegisters(instruction()->locs());
  __ Jump(exit_label());
}


void UnboxInstr::EmitLoadFromBoxWithDeopt(FlowGraphCompiler* compiler) {
  const intptr_t box_cid = BoxCid();
  ASSERT(box_cid != kSmiCid);  // Should never reach here with Smi-able ints.
  const Register box = locs()->in(0).reg();
  const Register temp =
      (locs()->temp_count() > 0) ? locs()->temp(0).reg() : kNoRegister;
  compiler::Label* deopt =
      compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnbox);
  compiler::Label is_smi;

  if ((value()->Type()->ToNullableCid() == box_cid) &&
      value()->Type()->is_nullable()) {
    __ CompareObject(box, Object::null_object());
    __ BranchIf(EQUAL, deopt);
  } else {
    __ BranchIfSmi(box, CanConvertSmi() ? &is_smi : deopt);
    __ CompareClassId(box, box_cid, temp);
    __ BranchIf(NOT_EQUAL, deopt);
  }

  EmitLoadFromBox(compiler);

  if (is_smi.IsLinked()) {
    compiler::Label done;
    __ Jump(&done, compiler::Assembler::kNearJump);
    __ Bind(&is_smi);
    EmitSmiConversion(compiler);
    __ Bind(&done);
  }
}

void UnboxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (SpeculativeModeOfInputs() == kNotSpeculative) {
    if (BoxCid() == kSmiCid) {
      // Since the representation fits in a Smi, we can extract it directly.
      ASSERT_EQUAL(value()->Type()->ToCid(), kSmiCid);
      return EmitSmiConversion(compiler);
    }
    switch (representation()) {
      case kUnboxedDouble:
      case kUnboxedFloat:
      case kUnboxedFloat32x4:
      case kUnboxedFloat64x2:
      case kUnboxedInt32x4:
        EmitLoadFromBox(compiler);
        break;

      case kUnboxedInt32:
        EmitLoadInt32FromBoxOrSmi(compiler);
        break;

      case kUnboxedInt64: {
        if (value()->Type()->ToCid() == kSmiCid) {
          // Smi -> int64 conversion is more efficient than
          // handling arbitrary smi/mint.
          EmitSmiConversion(compiler);
        } else {
          EmitLoadInt64FromBoxOrSmi(compiler);
        }
        break;
      }
      default:
        UNREACHABLE();
        break;
    }
  } else {
    ASSERT(SpeculativeModeOfInputs() == kGuardInputs);
    const intptr_t value_cid = value()->Type()->ToCid();
    const intptr_t box_cid = BoxCid();

    if (box_cid == kSmiCid || (CanConvertSmi() && (value_cid == kSmiCid))) {
      ASSERT_EQUAL(value_cid, kSmiCid);
      EmitSmiConversion(compiler);
    } else if (representation() == kUnboxedInt32 && value()->Type()->IsInt()) {
      EmitLoadInt32FromBoxOrSmi(compiler);
    } else if (representation() == kUnboxedInt64 && value()->Type()->IsInt()) {
      EmitLoadInt64FromBoxOrSmi(compiler);
    } else if ((value_cid == box_cid) || !CanDeoptimize()) {
      EmitLoadFromBox(compiler);
    } else {
      EmitLoadFromBoxWithDeopt(compiler);
    }
  }
}

Environment* Environment::From(Zone* zone,
                               const GrowableArray<Definition*>& definitions,
                               intptr_t fixed_parameter_count,
                               intptr_t lazy_deopt_pruning_count,
                               const ParsedFunction& parsed_function) {
  Environment* env = new (zone) Environment(
      definitions.length(), fixed_parameter_count, lazy_deopt_pruning_count,
      parsed_function.function(), nullptr);
  for (intptr_t i = 0; i < definitions.length(); ++i) {
    env->values_.Add(new (zone) Value(definitions[i]));
  }
  return env;
}

void Environment::PushValue(Value* value) {
  values_.Add(value);
}

Environment* Environment::DeepCopy(Zone* zone, intptr_t length) const {
  ASSERT(length <= values_.length());
  Environment* copy = new (zone) Environment(
      length, fixed_parameter_count_, LazyDeoptPruneCount(), function_,
      (outer_ == nullptr) ? nullptr : outer_->DeepCopy(zone));
  copy->SetDeoptId(DeoptIdBits::decode(bitfield_));
  copy->SetLazyDeoptToBeforeDeoptId(LazyDeoptToBeforeDeoptId());
  if (IsHoisted()) {
    copy->MarkAsHoisted();
  }
  if (locations_ != nullptr) {
    Location* new_locations = zone->Alloc<Location>(length);
    copy->set_locations(new_locations);
  }
  for (intptr_t i = 0; i < length; ++i) {
    copy->values_.Add(values_[i]->CopyWithType(zone));
    if (locations_ != nullptr) {
      copy->locations_[i] = locations_[i].Copy();
    }
  }
  return copy;
}

// Copies the environment and updates the environment use lists.
void Environment::DeepCopyTo(Zone* zone, Instruction* instr) const {
  for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }

  Environment* copy = DeepCopy(zone);
  instr->SetEnvironment(copy);
  for (Environment::DeepIterator it(copy); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->definition()->AddEnvUse(value);
  }
}

void Environment::DeepCopyAfterTo(Zone* zone,
                                  Instruction* instr,
                                  intptr_t argc,
                                  Definition* dead,
                                  Definition* result) const {
  for (Environment::DeepIterator it(instr->env()); !it.Done(); it.Advance()) {
    it.CurrentValue()->RemoveFromUseList();
  }

  Environment* copy =
      DeepCopy(zone, values_.length() - argc - LazyDeoptPruneCount());
  copy->SetLazyDeoptPruneCount(0);
  for (intptr_t i = 0; i < argc; i++) {
    copy->values_.Add(new (zone) Value(dead));
  }
  copy->values_.Add(new (zone) Value(result));

  instr->SetEnvironment(copy);
  for (Environment::DeepIterator it(copy); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->definition()->AddEnvUse(value);
  }
}

// Copies the environment as outer on an inlined instruction and updates the
// environment use lists.
void Environment::DeepCopyToOuter(Zone* zone,
                                  Instruction* instr,
                                  intptr_t outer_deopt_id) const {
  // Create a deep copy removing caller arguments from the environment.
  ASSERT(instr->env()->outer() == nullptr);
  intptr_t argument_count = instr->env()->fixed_parameter_count();
  Environment* outer =
      DeepCopy(zone, values_.length() - argument_count - LazyDeoptPruneCount());
  outer->SetDeoptId(outer_deopt_id);
  outer->SetLazyDeoptPruneCount(0);
  instr->env()->outer_ = outer;
  intptr_t use_index = instr->env()->Length();  // Start index after inner.
  for (Environment::DeepIterator it(outer); !it.Done(); it.Advance()) {
    Value* value = it.CurrentValue();
    value->set_instruction(instr);
    value->set_use_index(use_index++);
    value->definition()->AddEnvUse(value);
  }
}

ComparisonInstr* DoubleTestOpInstr::CopyWithNewOperands(Value* new_left,
                                                        Value* new_right) {
  UNREACHABLE();
  return nullptr;
}

ComparisonInstr* EqualityCompareInstr::CopyWithNewOperands(Value* new_left,
                                                           Value* new_right) {
  return new EqualityCompareInstr(source(), kind(), new_left, new_right,
                                  operation_cid(), deopt_id(), is_null_aware(),
                                  speculative_mode_);
}

ComparisonInstr* RelationalOpInstr::CopyWithNewOperands(Value* new_left,
                                                        Value* new_right) {
  return new RelationalOpInstr(source(), kind(), new_left, new_right,
                               operation_cid(), deopt_id(),
                               SpeculativeModeOfInputs());
}

ComparisonInstr* StrictCompareInstr::CopyWithNewOperands(Value* new_left,
                                                         Value* new_right) {
  return new StrictCompareInstr(source(), kind(), new_left, new_right,
                                needs_number_check(), DeoptId::kNone);
}

ComparisonInstr* TestSmiInstr::CopyWithNewOperands(Value* new_left,
                                                   Value* new_right) {
  return new TestSmiInstr(source(), kind(), new_left, new_right);
}

ComparisonInstr* TestCidsInstr::CopyWithNewOperands(Value* new_left,
                                                    Value* new_right) {
  return new TestCidsInstr(source(), kind(), new_left, cid_results(),
                           deopt_id());
}

ComparisonInstr* TestRangeInstr::CopyWithNewOperands(Value* new_left,
                                                     Value* new_right) {
  return new TestRangeInstr(source(), new_left, lower_, upper_,
                            value_representation_);
}

bool TestCidsInstr::AttributesEqual(const Instruction& other) const {
  auto const other_instr = other.AsTestCids();
  if (!ComparisonInstr::AttributesEqual(other)) {
    return false;
  }
  if (cid_results().length() != other_instr->cid_results().length()) {
    return false;
  }
  for (intptr_t i = 0; i < cid_results().length(); i++) {
    if (cid_results()[i] != other_instr->cid_results()[i]) {
      return false;
    }
  }
  return true;
}

bool TestRangeInstr::AttributesEqual(const Instruction& other) const {
  auto const other_instr = other.AsTestRange();
  if (!ComparisonInstr::AttributesEqual(other)) {
    return false;
  }
  return lower_ == other_instr->lower_ && upper_ == other_instr->upper_ &&
         value_representation_ == other_instr->value_representation_;
}

bool IfThenElseInstr::Supports(ComparisonInstr* comparison,
                               Value* v1,
                               Value* v2) {
  bool is_smi_result = v1->BindsToSmiConstant() && v2->BindsToSmiConstant();
  if (comparison->IsStrictCompare()) {
    // Strict comparison with number checks calls a stub and is not supported
    // by if-conversion.
    return is_smi_result &&
           !comparison->AsStrictCompare()->needs_number_check();
  }
  if (comparison->operation_cid() != kSmiCid) {
    // Non-smi comparisons are not supported by if-conversion.
    return false;
  }
  return is_smi_result;
}

bool PhiInstr::IsRedundant() const {
  ASSERT(InputCount() > 1);
  Definition* first = InputAt(0)->definition();
  for (intptr_t i = 1; i < InputCount(); ++i) {
    Definition* def = InputAt(i)->definition();
    if (def != first) return false;
  }
  return true;
}

Definition* PhiInstr::GetReplacementForRedundantPhi() const {
  Definition* first = InputAt(0)->definition();
  if (InputCount() == 1) {
    return first;
  }
  ASSERT(InputCount() > 1);
  Definition* first_origin = first->OriginalDefinition();
  bool look_for_redefinition = false;
  for (intptr_t i = 1; i < InputCount(); ++i) {
    Definition* def = InputAt(i)->definition();
    if ((def != first) && (def != this)) {
      Definition* origin = def->OriginalDefinition();
      if ((origin != first_origin) && (origin != this)) return nullptr;
      look_for_redefinition = true;
    }
  }
  if (look_for_redefinition) {
    // Find the most specific redefinition which is common for all inputs
    // (the longest common chain).
    Definition* redef = first;
    for (intptr_t i = 1, n = InputCount(); redef != first_origin && i < n;) {
      Value* value = InputAt(i);
      bool found = false;
      do {
        Definition* def = value->definition();
        if ((def == redef) || (def == this)) {
          found = true;
          break;
        }
        value = def->RedefinedValue();
      } while (value != nullptr);
      if (found) {
        ++i;
      } else {
        ASSERT(redef != first_origin);
        redef = redef->RedefinedValue()->definition();
      }
    }
    return redef;
  } else {
    return first;
  }
}

static bool AllInputsAreRedefinitions(PhiInstr* phi) {
  for (intptr_t i = 0; i < phi->InputCount(); i++) {
    if (phi->InputAt(i)->definition()->RedefinedValue() == nullptr) {
      return false;
    }
  }
  return true;
}

Definition* PhiInstr::Canonicalize(FlowGraph* flow_graph) {
  Definition* replacement = GetReplacementForRedundantPhi();
  if (replacement != nullptr && flow_graph->is_licm_allowed() &&
      AllInputsAreRedefinitions(this)) {
    // If we are replacing a Phi which has redefinitions as all of its inputs
    // then to maintain the redefinition chain we are going to insert a
    // redefinition. If any input is *not* a redefinition that means that
    // whatever properties were inferred for a Phi also hold on a path
    // that does not pass through any redefinitions so there is no need
    // to redefine this value.
    auto zone = flow_graph->zone();
    auto redef = new (zone) RedefinitionInstr(new (zone) Value(replacement));
    flow_graph->InsertAfter(block(), redef, /*env=*/nullptr, FlowGraph::kValue);

    // Redefinition is not going to dominate the block entry itself, so we
    // have to handle environment uses at the block entry specially.
    Value* next_use;
    for (Value* use = env_use_list(); use != nullptr; use = next_use) {
      next_use = use->next_use();
      if (use->instruction() == block()) {
        use->RemoveFromUseList();
        use->set_definition(replacement);
        replacement->AddEnvUse(use);
      }
    }
    return redef;
  }

  return (replacement != nullptr) ? replacement : this;
}

// Removes current phi from graph and sets current to previous phi.
void PhiIterator::RemoveCurrentFromGraph() {
  Current()->UnuseAllInputs();
  (*phis_)[index_] = phis_->Last();
  phis_->RemoveLast();
  --index_;
}

Instruction* CheckConditionInstr::Canonicalize(FlowGraph* graph) {
  if (StrictCompareInstr* strict_compare = comparison()->AsStrictCompare()) {
    if ((InputAt(0)->definition()->OriginalDefinition() ==
         InputAt(1)->definition()->OriginalDefinition()) &&
        strict_compare->kind() == Token::kEQ_STRICT) {
      return nullptr;
    }
  }
  return this;
}

LocationSummary* CheckConditionInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}

void CheckConditionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler::Label if_true;
  compiler::Label* if_false =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnknown);
  BranchLabels labels = {&if_true, if_false, &if_true};
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);
  if (true_condition != kInvalidCondition) {
    __ BranchIf(InvertCondition(true_condition), if_false);
  }
  __ Bind(&if_true);
}

bool CheckArrayBoundInstr::IsFixedLengthArrayType(intptr_t cid) {
  return LoadFieldInstr::IsFixedLengthArrayCid(cid);
}

Definition* CheckBoundBase::Canonicalize(FlowGraph* flow_graph) {
  return IsRedundant() ? index()->definition() : this;
}

intptr_t CheckArrayBoundInstr::LengthOffsetFor(intptr_t class_id) {
  if (IsTypedDataClassId(class_id) || IsTypedDataViewClassId(class_id) ||
      IsUnmodifiableTypedDataViewClassId(class_id) ||
      IsExternalTypedDataClassId(class_id)) {
    return compiler::target::TypedDataBase::length_offset();
  }

  switch (class_id) {
    case kGrowableObjectArrayCid:
      return compiler::target::GrowableObjectArray::length_offset();
    case kOneByteStringCid:
    case kTwoByteStringCid:
      return compiler::target::String::length_offset();
    case kArrayCid:
    case kImmutableArrayCid:
      return compiler::target::Array::length_offset();
    default:
      UNREACHABLE();
      return -1;
  }
}

Definition* CheckWritableInstr::Canonicalize(FlowGraph* flow_graph) {
  intptr_t cid = value()->Type()->ToCid();
  if ((cid != kIllegalCid) && (cid != kDynamicCid) &&
      !IsUnmodifiableTypedDataViewClassId(cid)) {
    return value()->definition();
  }
  return this;
}

static AlignmentType StrengthenAlignment(intptr_t cid,
                                         AlignmentType alignment) {
  switch (cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      // Don't need to worry about alignment for accessing bytes.
      return kAlignedAccess;
    case kTypedDataFloat64x2ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      // TODO(rmacnak): Investigate alignment requirements of floating point
      // loads.
      return kAlignedAccess;
  }

  return alignment;
}

LoadIndexedInstr::LoadIndexedInstr(Value* array,
                                   Value* index,
                                   bool index_unboxed,
                                   intptr_t index_scale,
                                   intptr_t class_id,
                                   AlignmentType alignment,
                                   intptr_t deopt_id,
                                   const InstructionSource& source,
                                   CompileType* result_type)
    : TemplateDefinition(source, deopt_id),
      index_unboxed_(index_unboxed),
      index_scale_(index_scale),
      class_id_(class_id),
      alignment_(StrengthenAlignment(class_id, alignment)),
      token_pos_(source.token_pos),
      result_type_(result_type) {
  SetInputAt(0, array);
  SetInputAt(1, index);
}

Definition* LoadIndexedInstr::Canonicalize(FlowGraph* flow_graph) {
  auto Z = flow_graph->zone();
  if (auto box = index()->definition()->AsBoxInt64()) {
    // TODO(dartbug.com/39432): Make LoadIndexed fully suport unboxed indices.
    if (!box->ComputeCanDeoptimize() && compiler::target::kWordSize == 8) {
      auto load = new (Z) LoadIndexedInstr(
          array()->CopyWithType(Z), box->value()->CopyWithType(Z),
          /*index_unboxed=*/true, index_scale(), class_id(), alignment_,
          GetDeoptId(), source(), result_type_);
      flow_graph->InsertBefore(this, load, env(), FlowGraph::kValue);
      return load;
    }
  }
  return this;
}

Representation LoadIndexedInstr::RepresentationOfArrayElement(
    intptr_t array_cid) {
  switch (array_cid) {
    case kImmutableArrayCid:
    case kRecordCid:
    case kTypeArgumentsCid:
      return kTagged;
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return kUnboxedIntPtr;
    default:
      return StoreIndexedInstr::RepresentationOfArrayElement(array_cid);
  }
}

StoreIndexedInstr::StoreIndexedInstr(Value* array,
                                     Value* index,
                                     Value* value,
                                     StoreBarrierType emit_store_barrier,
                                     bool index_unboxed,
                                     intptr_t index_scale,
                                     intptr_t class_id,
                                     AlignmentType alignment,
                                     intptr_t deopt_id,
                                     const InstructionSource& source,
                                     SpeculativeMode speculative_mode)
    : TemplateInstruction(source, deopt_id),
      emit_store_barrier_(emit_store_barrier),
      index_unboxed_(index_unboxed),
      index_scale_(index_scale),
      class_id_(class_id),
      alignment_(StrengthenAlignment(class_id, alignment)),
      token_pos_(source.token_pos),
      speculative_mode_(speculative_mode) {
  SetInputAt(kArrayPos, array);
  SetInputAt(kIndexPos, index);
  SetInputAt(kValuePos, value);
}

Instruction* StoreIndexedInstr::Canonicalize(FlowGraph* flow_graph) {
  auto Z = flow_graph->zone();
  if (auto box = index()->definition()->AsBoxInt64()) {
    // TODO(dartbug.com/39432): Make StoreIndexed fully suport unboxed indices.
    if (!box->ComputeCanDeoptimize() && compiler::target::kWordSize == 8) {
      auto store = new (Z) StoreIndexedInstr(
          array()->CopyWithType(Z), box->value()->CopyWithType(Z),
          value()->CopyWithType(Z), emit_store_barrier_,
          /*index_unboxed=*/true, index_scale(), class_id(), alignment_,
          GetDeoptId(), source(), speculative_mode_);
      flow_graph->InsertBefore(this, store, env(), FlowGraph::kEffect);
      return nullptr;
    }
  }
  return this;
}

Representation StoreIndexedInstr::RepresentationOfArrayElement(
    intptr_t array_cid) {
  switch (array_cid) {
    case kArrayCid:
      return kTagged;
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return kUnboxedIntPtr;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      return kUnboxedInt64;
    case kTypedDataFloat32ArrayCid:
      return kUnboxedFloat;
    case kTypedDataFloat64ArrayCid:
      return kUnboxedDouble;
    case kTypedDataInt32x4ArrayCid:
      return kUnboxedInt32x4;
    case kTypedDataFloat32x4ArrayCid:
      return kUnboxedFloat32x4;
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      UNREACHABLE();
      return kTagged;
  }
}

Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // Array can be a Dart object or a pointer to external data.
  if (idx == 0) return kNoRepresentation;  // Flexible input representation.
  if (idx == 1) {
    if (index_unboxed_) {
#if defined(TARGET_ARCH_IS_64_BIT)
      return kUnboxedInt64;
#else
      // TODO(dartbug.com/39432): kUnboxedInt32 || kUnboxedUint32 on 32-bit
      //  architectures.
      return kNoRepresentation;  // Index can be any unboxed representation.
#endif
    } else {
      return kTagged;  // Index is a smi.
    }
  }
  ASSERT(idx == 2);
  return RepresentationOfArrayElement(class_id());
}

#if defined(TARGET_ARCH_ARM64)
// We can emit a 16 byte move in a single instruction using LDP/STP.
static const intptr_t kMaxElementSizeForEfficientCopy = 16;
#else
static const intptr_t kMaxElementSizeForEfficientCopy =
    compiler::target::kWordSize;
#endif

Instruction* MemoryCopyInstr::Canonicalize(FlowGraph* flow_graph) {
  if (!length()->BindsToSmiConstant()) {
    return this;
  } else if (length()->BoundSmiConstant() == 0) {
    // Nothing to copy.
    return nullptr;
  }

  if (!src_start()->BindsToSmiConstant() ||
      !dest_start()->BindsToSmiConstant()) {
    // TODO(https://dartbug.com/51031): Consider adding support for src/dest
    // starts to be in bytes rather than element size.
    return this;
  }

  intptr_t new_length = length()->BoundSmiConstant();
  intptr_t new_src_start = src_start()->BoundSmiConstant();
  intptr_t new_dest_start = dest_start()->BoundSmiConstant();
  intptr_t new_element_size = element_size_;
  while (((new_length | new_src_start | new_dest_start) & 1) == 0 &&
         new_element_size < kMaxElementSizeForEfficientCopy) {
    new_length >>= 1;
    new_src_start >>= 1;
    new_dest_start >>= 1;
    new_element_size <<= 1;
  }
  if (new_element_size == element_size_) {
    return this;
  }

  Zone* const zone = flow_graph->zone();
  // The new element size is larger than the original one, so it must be > 1.
  // That means unboxed integers will always require a shift, but Smis
  // may not if element_size == 2, so always use Smis.
  auto* const length_instr = flow_graph->GetConstant(
      Integer::ZoneHandle(zone, Integer::New(new_length, Heap::kOld)));
  auto* const src_start_instr = flow_graph->GetConstant(
      Integer::ZoneHandle(zone, Integer::New(new_src_start, Heap::kOld)));
  auto* const dest_start_instr = flow_graph->GetConstant(
      Integer::ZoneHandle(zone, Integer::New(new_dest_start, Heap::kOld)));
  length()->BindTo(length_instr);
  src_start()->BindTo(src_start_instr);
  dest_start()->BindTo(dest_start_instr);
  element_size_ = new_element_size;
  unboxed_inputs_ = false;
  return this;
}

void MemoryCopyInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register src_reg = locs()->in(kSrcPos).reg();
  const Register dest_reg = locs()->in(kDestPos).reg();
  const Location& src_start_loc = locs()->in(kSrcStartPos);
  const Location& dest_start_loc = locs()->in(kDestStartPos);
  const Location& length_loc = locs()->in(kLengthPos);
  // Note that for all architectures, constant_length is only true if
  // length() binds to a _small_ constant, so we can end up generating a loop
  // if the constant length() was bound to is too large.
  const bool constant_length = length_loc.IsConstant();
  const Register length_reg = constant_length ? kNoRegister : length_loc.reg();
  const intptr_t num_elements =
      constant_length ? Integer::Cast(length_loc.constant()).AsInt64Value()
                      : -1;

  // The zero constant case should be handled via canonicalization.
  ASSERT(!constant_length || num_elements > 0);

  EmitComputeStartPointer(compiler, src_cid_, src_reg, src_start_loc);
  EmitComputeStartPointer(compiler, dest_cid_, dest_reg, dest_start_loc);

  compiler::Label copy_forwards, done;
  if (!constant_length) {
#if defined(TARGET_ARCH_IA32)
    // Save ESI (THR), as we have to use it on the loop path.
    __ PushRegister(ESI);
#endif
    PrepareLengthRegForLoop(compiler, length_reg, &done);
  }
  // Omit the reversed loop for possible overlap if copying a single element.
  if (can_overlap() && num_elements != 1) {
    __ CompareRegisters(dest_reg, src_reg);
    // Both regions are the same size, so if there is an overlap, then either:
    //
    // * The destination region comes before the source, so copying from
    //   front to back ensures that the data in the overlap is read and
    //   copied before it is written.
    // * The source region comes before the destination, which requires
    //   copying from back to front to ensure that the data in the overlap is
    //   read and copied before it is written.
    //
    // To make the generated code smaller for the unrolled case, we do not
    // additionally verify here that there is an actual overlap. Instead, only
    // do that when we need to calculate the end address of the regions in
    // the loop case.
    __ BranchIf(UNSIGNED_LESS_EQUAL, &copy_forwards,
                compiler::Assembler::kNearJump);
    __ Comment("Copying backwards");
    if (constant_length) {
      EmitUnrolledCopy(compiler, dest_reg, src_reg, num_elements,
                       /*reversed=*/true);
    } else {
      EmitLoopCopy(compiler, dest_reg, src_reg, length_reg, &done,
                   &copy_forwards);
    }
    __ Jump(&done, compiler::Assembler::kNearJump);
    __ Comment("Copying forwards");
  }
  __ Bind(&copy_forwards);
  if (constant_length) {
    EmitUnrolledCopy(compiler, dest_reg, src_reg, num_elements,
                     /*reversed=*/false);
  } else {
    EmitLoopCopy(compiler, dest_reg, src_reg, length_reg, &done);
  }
  __ Bind(&done);
#if defined(TARGET_ARCH_IA32)
  if (!constant_length) {
    // Restore ESI (THR).
    __ PopRegister(ESI);
  }
#endif
}

// EmitUnrolledCopy on ARM is different enough that it is defined separately.
#if !defined(TARGET_ARCH_ARM)
void MemoryCopyInstr::EmitUnrolledCopy(FlowGraphCompiler* compiler,
                                       Register dest_reg,
                                       Register src_reg,
                                       intptr_t num_elements,
                                       bool reversed) {
  ASSERT(element_size_ <= 16);
  const intptr_t num_bytes = num_elements * element_size_;
#if defined(TARGET_ARCH_ARM64)
  // We use LDP/STP with TMP/TMP2 to handle 16-byte moves.
  const intptr_t mov_size = element_size_;
#else
  const intptr_t mov_size =
      Utils::Minimum<intptr_t>(element_size_, compiler::target::kWordSize);
#endif
  const intptr_t mov_repeat = num_bytes / mov_size;
  ASSERT(num_bytes % mov_size == 0);

#if defined(TARGET_ARCH_IA32)
  // No TMP on IA32, so we have to allocate one instead.
  const Register temp_reg = locs()->temp(0).reg();
#else
  const Register temp_reg = TMP;
#endif
  for (intptr_t i = 0; i < mov_repeat; i++) {
    const intptr_t offset = (reversed ? (mov_repeat - (i + 1)) : i) * mov_size;
    switch (mov_size) {
      case 1:
        __ LoadFromOffset(temp_reg, src_reg, offset, compiler::kUnsignedByte);
        __ StoreToOffset(temp_reg, dest_reg, offset, compiler::kUnsignedByte);
        break;
      case 2:
        __ LoadFromOffset(temp_reg, src_reg, offset,
                          compiler::kUnsignedTwoBytes);
        __ StoreToOffset(temp_reg, dest_reg, offset,
                         compiler::kUnsignedTwoBytes);
        break;
      case 4:
        __ LoadFromOffset(temp_reg, src_reg, offset,
                          compiler::kUnsignedFourBytes);
        __ StoreToOffset(temp_reg, dest_reg, offset,
                         compiler::kUnsignedFourBytes);
        break;
      case 8:
#if defined(TARGET_ARCH_IS_64_BIT)
        __ LoadFromOffset(temp_reg, src_reg, offset, compiler::kEightBytes);
        __ StoreToOffset(temp_reg, dest_reg, offset, compiler::kEightBytes);
#else
        UNREACHABLE();
#endif
        break;
      case 16: {
#if defined(TARGET_ARCH_ARM64)
        __ ldp(
            TMP, TMP2,
            compiler::Address(src_reg, offset, compiler::Address::PairOffset));
        __ stp(
            TMP, TMP2,
            compiler::Address(dest_reg, offset, compiler::Address::PairOffset));
#else
        UNREACHABLE();
#endif
        break;
      }
      default:
        UNREACHABLE();
    }
  }
}
#endif

bool Utf8ScanInstr::IsScanFlagsUnboxed() const {
  return scan_flags_field_.is_unboxed();
}

InvokeMathCFunctionInstr::InvokeMathCFunctionInstr(
    InputsArray&& inputs,
    intptr_t deopt_id,
    MethodRecognizer::Kind recognized_kind,
    const InstructionSource& source)
    : VariadicDefinition(std::move(inputs), source, deopt_id),
      recognized_kind_(recognized_kind),
      token_pos_(source.token_pos) {
  ASSERT(InputCount() == ArgumentCountFor(recognized_kind_));
}

intptr_t InvokeMathCFunctionInstr::ArgumentCountFor(
    MethodRecognizer::Kind kind) {
  switch (kind) {
    case MethodRecognizer::kDoubleTruncateToDouble:
    case MethodRecognizer::kDoubleFloorToDouble:
    case MethodRecognizer::kDoubleCeilToDouble:
    case MethodRecognizer::kDoubleRoundToDouble:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathSin:
    case MethodRecognizer::kMathCos:
    case MethodRecognizer::kMathExp:
    case MethodRecognizer::kMathLog:
      return 1;
    case MethodRecognizer::kDoubleMod:
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathAtan2:
      return 2;
    default:
      UNREACHABLE();
  }
  return 0;
}

const RuntimeEntry& InvokeMathCFunctionInstr::TargetFunction() const {
  switch (recognized_kind_) {
    case MethodRecognizer::kDoubleTruncateToDouble:
      return kLibcTruncRuntimeEntry;
    case MethodRecognizer::kDoubleRoundToDouble:
      return kLibcRoundRuntimeEntry;
    case MethodRecognizer::kDoubleFloorToDouble:
      return kLibcFloorRuntimeEntry;
    case MethodRecognizer::kDoubleCeilToDouble:
      return kLibcCeilRuntimeEntry;
    case MethodRecognizer::kMathDoublePow:
      return kLibcPowRuntimeEntry;
    case MethodRecognizer::kDoubleMod:
      return kDartModuloRuntimeEntry;
    case MethodRecognizer::kMathTan:
      return kLibcTanRuntimeEntry;
    case MethodRecognizer::kMathAsin:
      return kLibcAsinRuntimeEntry;
    case MethodRecognizer::kMathSin:
      return kLibcSinRuntimeEntry;
    case MethodRecognizer::kMathCos:
      return kLibcCosRuntimeEntry;
    case MethodRecognizer::kMathAcos:
      return kLibcAcosRuntimeEntry;
    case MethodRecognizer::kMathAtan:
      return kLibcAtanRuntimeEntry;
    case MethodRecognizer::kMathAtan2:
      return kLibcAtan2RuntimeEntry;
    case MethodRecognizer::kMathExp:
      return kLibcExpRuntimeEntry;
    case MethodRecognizer::kMathLog:
      return kLibcLogRuntimeEntry;
    default:
      UNREACHABLE();
  }
  return kLibcPowRuntimeEntry;
}

const char* MathUnaryInstr::KindToCString(MathUnaryKind kind) {
  switch (kind) {
    case kIllegal:
      return "illegal";
    case kSqrt:
      return "sqrt";
    case kDoubleSquare:
      return "double-square";
  }
  UNREACHABLE();
  return "";
}

TruncDivModInstr::TruncDivModInstr(Value* lhs, Value* rhs, intptr_t deopt_id)
    : TemplateDefinition(deopt_id) {
  SetInputAt(0, lhs);
  SetInputAt(1, rhs);
}

intptr_t TruncDivModInstr::OutputIndexOf(Token::Kind token) {
  switch (token) {
    case Token::kTRUNCDIV:
      return 0;
    case Token::kMOD:
      return 1;
    default:
      UNIMPLEMENTED();
      return -1;
  }
}

LocationSummary* NativeCallInstr::MakeLocationSummary(Zone* zone,
                                                      bool optimizing) const {
  return MakeCallSummary(zone, this);
}

void NativeCallInstr::SetupNative() {
  if (link_lazily()) {
    // Resolution will happen during NativeEntry::LinkNativeCall.
    return;
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  // Currently we perform unoptimized compilations only on mutator threads. If
  // the compiler has to resolve a native to a function pointer it calls out to
  // the embedder to do so.
  //
  // Unfortunately that embedder API was designed by giving it a handle to a
  // string. So the embedder will have to call back into the VM to convert it to
  // a C string - which requires an active isolate.
  //
  // => To allow this `dart-->jit-compiler-->embedder-->dart api` we set the
  //    active isolate again.
  //
  ActiveIsolateScope active_isolate(thread);

  const Class& cls = Class::Handle(zone, function().Owner());
  const Library& library = Library::Handle(zone, cls.library());

  Dart_NativeEntryResolver resolver = library.native_entry_resolver();
  bool is_bootstrap_native = Bootstrap::IsBootstrapResolver(resolver);
  set_is_bootstrap_native(is_bootstrap_native);

  const int num_params =
      NativeArguments::ParameterCountForResolution(function());
  bool auto_setup_scope = true;
  NativeFunction native_function = NativeEntry::ResolveNative(
      library, native_name(), num_params, &auto_setup_scope);
  if (native_function == nullptr) {
    if (has_inlining_id()) {
      UNIMPLEMENTED();
    }
    Report::MessageF(Report::kError, Script::Handle(function().script()),
                     function().token_pos(), Report::AtLocation,
                     "native function '%s' (%" Pd " arguments) cannot be found",
                     native_name().ToCString(), function().NumParameters());
  }
  set_is_auto_scope(auto_setup_scope);
  set_native_c_function(native_function);
}

#if !defined(TARGET_ARCH_ARM) && !defined(TARGET_ARCH_ARM64) &&                \
    !defined(TARGET_ARCH_RISCV32) && !defined(TARGET_ARCH_RISCV64)

LocationSummary* BitCastInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  UNREACHABLE();
}

void BitCastInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNREACHABLE();
}

#endif  // !defined(TARGET_ARCH_ARM) && !defined(TARGET_ARCH_ARM64) &&         \
        // !defined(TARGET_ARCH_RISCV32) && !defined(TARGET_ARCH_RISCV64)

Representation FfiCallInstr::RequiredInputRepresentation(intptr_t idx) const {
  if (idx < TargetAddressIndex()) {
    // All input handles are passed as Tagged values on the stack to
    // FfiCallInstr, which passes "handles", i.e. pointers, to these.
    if (marshaller_.IsHandle(marshaller_.ArgumentIndex(idx))) {
      return kTagged;
    }
    return marshaller_.RepInFfiCall(idx);
  } else if (idx == TargetAddressIndex()) {
    return kUnboxedFfiIntPtr;
  } else {
    ASSERT(idx == TypedDataIndex());
    return kTagged;
  }
}

#define Z zone_

LocationSummary* FfiCallInstr::MakeLocationSummaryInternal(
    Zone* zone,
    bool is_optimizing,
    const RegList temps) const {
  auto contains_call =
      is_leaf_ ? LocationSummary::kNativeLeafCall : LocationSummary::kCall;

  LocationSummary* summary = new (zone) LocationSummary(
      zone, /*num_inputs=*/InputCount(),
      /*num_temps=*/Utils::CountOneBitsWord(temps), contains_call);

  intptr_t reg_i = 0;
  for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
    if ((temps & (1 << reg)) != 0) {
      summary->set_temp(reg_i,
                        Location::RegisterLocation(static_cast<Register>(reg)));
      reg_i++;
    }
  }

#if defined(TARGET_ARCH_X64) && !defined(DART_TARGET_OS_WINDOWS)
  // Only use R13 if really needed, having R13 free causes less spilling.
  const Register target_address =
      marshaller_.contains_varargs()
          ? R13
          : CallingConventions::kFirstNonArgumentRegister;  // RAX
  summary->set_in(TargetAddressIndex(),
                  Location::RegisterLocation(target_address));
#else
  summary->set_in(TargetAddressIndex(),
                  Location::RegisterLocation(
                      CallingConventions::kFirstNonArgumentRegister));
#endif
  for (intptr_t i = 0, n = marshaller_.NumDefinitions(); i < n; ++i) {
    summary->set_in(i, marshaller_.LocInFfiCall(i));
  }

  if (marshaller_.PassTypedData()) {
    summary->set_in(TypedDataIndex(), Location::Any());
    // We don't care about return location, but we need to pass a register.
    summary->set_out(
        0, Location::RegisterLocation(CallingConventions::kReturnReg));
  } else {
    summary->set_out(0, marshaller_.LocInFfiCall(compiler::ffi::kResultIndex));
  }

  return summary;
}

void FfiCallInstr::EmitParamMoves(FlowGraphCompiler* compiler,
                                  const Register saved_fp,
                                  const Register temp0,
                                  const Register temp1) {
  __ Comment("EmitParamMoves");

  // Moves for return pointer.
  const auto& return_location =
      marshaller_.Location(compiler::ffi::kResultIndex);
  if (return_location.IsPointerToMemory()) {
    __ Comment("return_location.IsPointerToMemory");
    const auto& pointer_location =
        return_location.AsPointerToMemory().pointer_location();
    const auto& pointer_register =
        pointer_location.IsRegisters()
            ? pointer_location.AsRegisters().reg_at(0)
            : temp0;
    __ MoveRegister(pointer_register, SPREG);
    __ AddImmediate(pointer_register, marshaller_.PassByPointerStackOffset(
                                          compiler::ffi::kResultIndex));

    if (pointer_location.IsStack()) {
      const auto& pointer_stack = pointer_location.AsStack();
      __ StoreMemoryValue(pointer_register, pointer_stack.base_register(),
                          pointer_stack.offset_in_bytes());
    }
  }

  // Moves for arguments.
  compiler::ffi::FrameRebase rebase(compiler->zone(), /*old_base=*/FPREG,
                                    /*new_base=*/saved_fp,
                                    /*stack_delta=*/0);
  intptr_t def_index = 0;
  for (intptr_t arg_index = 0; arg_index < marshaller_.num_args();
       arg_index++) {
    const intptr_t num_defs = marshaller_.NumDefinitions(arg_index);
    const auto& arg_target = marshaller_.Location(arg_index);
    __ Comment("arg_index %" Pd " arg_target %s", arg_index,
               arg_target.ToCString());

    // First deal with moving all individual definitions passed in to the
    // FfiCall to the right native location based on calling convention.
    for (intptr_t i = 0; i < num_defs; i++) {
      __ Comment("  def_index %" Pd, def_index);
      const Location origin = rebase.Rebase(locs()->in(def_index));
      const Representation origin_rep =
          RequiredInputRepresentation(def_index) == kTagged
              ? kUnboxedFfiIntPtr  // When arg_target.IsPointerToMemory().
              : RequiredInputRepresentation(def_index);

      // Find the native location where this individual definition should be
      // moved to.
      const auto& def_target =
          arg_target.payload_type().IsPrimitive() ? arg_target
          : arg_target.IsMultiple() ? *arg_target.AsMultiple().locations()[i]
          : arg_target.IsPointerToMemory()
              ? arg_target.AsPointerToMemory().pointer_location()
              : /*arg_target.IsStack()*/ arg_target.Split(compiler->zone(),
                                                          num_defs, i);

      ConstantTemporaryAllocator temp_alloc(temp0);
      if (origin.IsConstant()) {
        // Can't occur because we currently don't inline FFI trampolines (see
        // http://dartbug.com/45055), which means all incoming arguments
        // originate from parameters and thus are non-constant.
        UNREACHABLE();
      }

      // Handles are passed into FfiCalls as Tagged values on the stack, and
      // then we pass pointers to these handles to the native function here.
      if (marshaller_.IsHandle(arg_index)) {
        ASSERT(compiler::target::LocalHandle::ptr_offset() == 0);
        ASSERT(compiler::target::LocalHandle::InstanceSize() ==
               compiler::target::kWordSize);
        ASSERT(num_defs == 1);
        ASSERT(origin.IsStackSlot());
        if (def_target.IsRegisters()) {
          __ AddImmediate(def_target.AsLocation().reg(), origin.base_reg(),
                          origin.stack_index() * compiler::target::kWordSize);
        } else {
          ASSERT(def_target.IsStack());
          const auto& target_stack = def_target.AsStack();
          __ AddImmediate(temp0, origin.base_reg(),
                          origin.stack_index() * compiler::target::kWordSize);
          __ StoreToOffset(temp0,
                           compiler::Address(target_stack.base_register(),
                                             target_stack.offset_in_bytes()));
        }
      } else {
#if defined(INCLUDE_IL_PRINTER)
        __ Comment("def_target %s <- origin %s %s", def_target.ToCString(),
                   origin.ToCString(), RepresentationToCString(origin_rep));
#endif  // defined(INCLUDE_IL_PRINTER)
#ifdef DEBUG
        // Stack arguments split are in word-size chunks. These chunks can copy
        // too much. However, that doesn't matter in practise because we process
        // the stack in order.
        // It only matters for the last chunk, it should not overwrite what was
        // already on the stack.
        if (def_target.IsStack()) {
          const auto& def_target_stack = def_target.AsStack();
          ASSERT(def_target_stack.offset_in_bytes() +
                     def_target.payload_type().SizeInBytes() <=
                 marshaller_.RequiredStackSpaceInBytes());
        }
#endif
        compiler->EmitMoveToNative(def_target, origin, origin_rep, &temp_alloc);
      }
      def_index++;
    }

    // Then make sure that any pointers passed through the calling convention
    // actually have a copy of the struct.
    // Note that the step above has already moved the pointer into the expected
    // native location.
    if (arg_target.IsPointerToMemory()) {
      __ Comment("arg_target.IsPointerToMemory");
      NoTemporaryAllocator temp_alloc;
      const auto& pointer_loc =
          arg_target.AsPointerToMemory().pointer_location();

      // TypedData/Pointer data pointed to in temp.
      const auto& dst = compiler::ffi::NativeRegistersLocation(
          compiler->zone(), pointer_loc.payload_type(),
          pointer_loc.container_type(), temp0);
      compiler->EmitNativeMove(dst, pointer_loc, &temp_alloc);
      __ LoadField(temp0,
                   compiler::FieldAddress(
                       temp0, compiler::target::PointerBase::data_offset()));

      // Copy chunks.
      const intptr_t sp_offset =
          marshaller_.PassByPointerStackOffset(arg_index);
      // Struct size is rounded up to a multiple of target::kWordSize.
      // This is safe because we do the same rounding when we allocate the
      // space on the stack.
      for (intptr_t i = 0; i < arg_target.payload_type().SizeInBytes();
           i += compiler::target::kWordSize) {
        __ LoadMemoryValue(temp1, temp0, i);
        __ StoreMemoryValue(temp1, SPREG, i + sp_offset);
      }

      // Store the stack address in the argument location.
      __ MoveRegister(temp0, SPREG);
      __ AddImmediate(temp0, sp_offset);
      const auto& src = compiler::ffi::NativeRegistersLocation(
          compiler->zone(), pointer_loc.payload_type(),
          pointer_loc.container_type(), temp0);
      __ Comment("pointer_loc %s <- src %s", pointer_loc.ToCString(),
                 src.ToCString());
      compiler->EmitNativeMove(pointer_loc, src, &temp_alloc);
    }
  }

  __ Comment("EmitParamMovesEnd");
}

void FfiCallInstr::EmitReturnMoves(FlowGraphCompiler* compiler,
                                   const Register temp0,
                                   const Register temp1) {
  const auto& returnLocation =
      marshaller_.Location(compiler::ffi::kResultIndex);
  if (returnLocation.payload_type().IsVoid()) {
    return;
  }

  __ Comment("EmitReturnMoves");

  NoTemporaryAllocator no_temp;
  if (returnLocation.IsRegisters() || returnLocation.IsFpuRegisters()) {
    const auto& src = returnLocation;
    const Location dst_loc = locs()->out(0);
    const Representation dst_type = representation();
    compiler->EmitMoveFromNative(dst_loc, dst_type, src, &no_temp);
  } else if (returnLocation.IsPointerToMemory() ||
             returnLocation.IsMultiple()) {
    ASSERT(returnLocation.payload_type().IsCompound());
    ASSERT(marshaller_.PassTypedData());

    // Get the typed data pointer which we have pinned to a stack slot.
    const Location typed_data_loc = locs()->in(TypedDataIndex());
    if (typed_data_loc.IsStackSlot()) {
      ASSERT(typed_data_loc.base_reg() == FPREG);
      // If this is a leaf call there is no extra call frame to step through.
      if (is_leaf_) {
        __ LoadMemoryValue(temp0, FPREG, typed_data_loc.ToStackSlotOffset());
      } else {
        __ LoadMemoryValue(
            temp0, FPREG,
            kSavedCallerFpSlotFromFp * compiler::target::kWordSize);
        __ LoadMemoryValue(temp0, temp0, typed_data_loc.ToStackSlotOffset());
      }
    } else {
      compiler->EmitMove(Location::RegisterLocation(temp0), typed_data_loc,
                         &no_temp);
    }
    __ LoadField(temp0,
                 compiler::FieldAddress(
                     temp0, compiler::target::PointerBase::data_offset()));

    if (returnLocation.IsPointerToMemory()) {
      // Copy blocks from the stack location to TypedData.
      // Struct size is rounded up to a multiple of target::kWordSize.
      // This is safe because we do the same rounding when we allocate the
      // TypedData in IL.
      const intptr_t sp_offset =
          marshaller_.PassByPointerStackOffset(compiler::ffi::kResultIndex);
      for (intptr_t i = 0; i < marshaller_.TypedDataSizeInBytes();
           i += compiler::target::kWordSize) {
        __ LoadMemoryValue(temp1, SPREG, i + sp_offset);
        __ StoreMemoryValue(temp1, temp0, i);
      }
    } else {
      ASSERT(returnLocation.IsMultiple());
      // Copy to the struct from the native locations.
      const auto& multiple =
          marshaller_.Location(compiler::ffi::kResultIndex).AsMultiple();

      int offset_in_bytes = 0;
      for (int i = 0; i < multiple.locations().length(); i++) {
        const auto& src = *multiple.locations().At(i);
        const auto& dst = compiler::ffi::NativeStackLocation(
            src.payload_type(), src.container_type(), temp0, offset_in_bytes);
        compiler->EmitNativeMove(dst, src, &no_temp);
        offset_in_bytes += src.payload_type().SizeInBytes();
      }
    }
  } else {
    UNREACHABLE();
  }

  __ Comment("EmitReturnMovesEnd");
}

LocationSummary* RawStoreFieldInstr::MakeLocationSummary(
    Zone* zone,
    bool is_optimizing) const {
  LocationSummary* summary =
      new (zone) LocationSummary(zone, /*num_inputs=*/2,
                                 /*num_temps=*/0, LocationSummary::kNoCall);

  summary->set_in(kBase, Location::RequiresRegister());
  summary->set_in(kValue, Location::RequiresRegister());

  return summary;
}

Representation RawStoreFieldInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  switch (idx) {
    case kBase:
      return kUntagged;
    case kValue:
      return kTagged;
    default:
      break;
  }
  UNREACHABLE();
}

void RawStoreFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register base_reg = locs()->in(kBase).reg();
  const Register value_reg = locs()->in(kValue).reg();
  compiler->assembler()->StoreMemoryValue(value_reg, base_reg, offset_);
}

LocationSummary* StoreFieldInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 2;
#if defined(TARGET_ARCH_IA32)
  const intptr_t kNumTemps = ShouldEmitStoreBarrier() ? 1 : 0;
#else
  const intptr_t kNumTemps = 0;
#endif
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  summary->set_in(kInstancePos, Location::RequiresRegister());
  if (slot().representation() != kTagged) {
    if (RepresentationUtils::IsUnboxedInteger(slot().representation())) {
      const size_t value_size =
          RepresentationUtils::ValueSize(slot().representation());
      if (value_size <= compiler::target::kWordSize) {
        summary->set_in(kValuePos, Location::RequiresRegister());
      } else {
        ASSERT(value_size == 2 * compiler::target::kWordSize);
        summary->set_in(kValuePos,
                        Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
      }
    } else {
      summary->set_in(kValuePos, Location::RequiresFpuRegister());
    }
  } else {
    Location value_loc;
    if (ShouldEmitStoreBarrier()) {
      summary->set_in(kValuePos,
                      Location::RegisterLocation(kWriteBarrierValueReg));
    } else {
#if defined(TARGET_ARCH_IA32)
      // IA32 supports emitting `mov mem, Imm32` even for heap
      // pointer immediates.
      summary->set_in(kValuePos, LocationRegisterOrConstant(value()));
#elif defined(TARGET_ARCH_X64)
      // X64 supports emitting `mov mem, Imm32` only with non-pointer
      // immediate.
      summary->set_in(kValuePos, LocationRegisterOrSmiConstant(value()));
#elif defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_RISCV32) ||            \
    defined(TARGET_ARCH_RISCV64)
      // ARM64 and RISC-V have dedicated zero and null registers which can be
      // used in store instructions.
      Location value_loc = Location::RequiresRegister();
      if (auto constant = value()->definition()->AsConstant()) {
        const auto& value = constant->value();
        if (value.IsNull() ||
            (value.IsSmi() && Smi::Cast(value).Value() == 0)) {
          value_loc = Location::Constant(constant);
        }
      }
      summary->set_in(kValuePos, value_loc);
#else
      // No support for moving immediate to memory directly.
      summary->set_in(kValuePos, Location::RequiresRegister());
#endif
    }
  }
  if (kNumTemps == 1) {
    summary->set_temp(0, Location::RequiresRegister());
  } else {
    ASSERT(kNumTemps == 0);
  }
  return summary;
}

void StoreFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register instance_reg = locs()->in(kInstancePos).reg();
  const intptr_t offset_in_bytes = OffsetInBytes();
  ASSERT(offset_in_bytes > 0);  // Field is finalized and points after header.

  if (slot().representation() != kTagged) {
    // Unboxed field.
    ASSERT(memory_order_ != compiler::AssemblerBase::kRelease);
    if (RepresentationUtils::IsUnboxedInteger(slot().representation())) {
      const size_t value_size =
          RepresentationUtils::ValueSize(slot().representation());
      if (value_size <= compiler::target::kWordSize) {
        const Register value = locs()->in(kValuePos).reg();
        __ StoreFieldToOffset(
            value, instance_reg, offset_in_bytes,
            RepresentationUtils::OperandSize(slot().representation()));
      } else {
        auto const value_pair = locs()->in(kValuePos).AsPairLocation();
        const Register value_lo = value_pair->At(0).reg();
        const Register value_hi = value_pair->At(1).reg();
        __ StoreFieldToOffset(value_lo, instance_reg, offset_in_bytes);
        __ StoreFieldToOffset(value_hi, instance_reg,
                              offset_in_bytes + compiler::target::kWordSize);
      }
    } else {
      // This is an FPU store.
      const intptr_t cid = slot().field().guarded_cid();
      const FpuRegister value = locs()->in(kValuePos).fpu_reg();
      switch (cid) {
        case kDoubleCid:
          __ StoreUnboxedDouble(value, instance_reg,
                                offset_in_bytes - kHeapObjectTag);
          return;
        case kFloat32x4Cid:
        case kFloat64x2Cid:
          __ StoreUnboxedSimd128(value, instance_reg,
                                 offset_in_bytes - kHeapObjectTag);
          return;
        default:
          UNREACHABLE();
      }
    }
    return;
  }

  // Store of a tagged pointer.
  const bool compressed = slot().is_compressed();
  if (ShouldEmitStoreBarrier()) {
    Register value_reg = locs()->in(kValuePos).reg();
    if (!compressed) {
#if defined(TARGET_ARCH_IA32)
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes, value_reg,
                               CanValueBeSmi(), memory_order_,
                               locs()->temp(0).reg());
#else
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes, value_reg,
                               CanValueBeSmi(), memory_order_);
#endif
    } else {
#if defined(DART_COMPRESSED_POINTERS)
      __ StoreCompressedIntoObjectOffset(instance_reg, offset_in_bytes,
                                         value_reg, CanValueBeSmi(),
                                         memory_order_);
#else
      UNREACHABLE();
#endif
    }
  } else {
    if (locs()->in(kValuePos).IsConstant()) {
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32) ||                   \
    defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_RISCV32) ||              \
    defined(TARGET_ARCH_RISCV64)
      const auto& value = locs()->in(kValuePos).constant();
      if (!compressed) {
        __ StoreIntoObjectOffsetNoBarrier(instance_reg, offset_in_bytes, value,
                                          memory_order_);
      } else {
#if defined(DART_COMPRESSED_POINTERS)
        __ StoreCompressedIntoObjectOffsetNoBarrier(
            instance_reg, offset_in_bytes, value, memory_order_);
#else
        UNREACHABLE();
#endif
      }
      return;
#else
      UNREACHABLE();
#endif
    }

    Register value_reg = locs()->in(kValuePos).reg();
    if (!compressed) {
      __ StoreIntoObjectOffsetNoBarrier(instance_reg, offset_in_bytes,
                                        value_reg, memory_order_);
    } else {
#if defined(DART_COMPRESSED_POINTERS)
      __ StoreCompressedIntoObjectOffsetNoBarrier(instance_reg, offset_in_bytes,
                                                  value_reg, memory_order_);
#else
      UNREACHABLE();
#endif
    }
  }
}

const Code& ReturnInstr::GetReturnStub(FlowGraphCompiler* compiler) const {
  const Function& function = compiler->parsed_function().function();
  ASSERT(function.IsSuspendableFunction());
  if (function.IsAsyncFunction()) {
    if (compiler->is_optimizing() && !value()->Type()->CanBeFuture()) {
      return Code::ZoneHandle(compiler->zone(),
                              compiler->isolate_group()
                                  ->object_store()
                                  ->return_async_not_future_stub());
    }
    return Code::ZoneHandle(
        compiler->zone(),
        compiler->isolate_group()->object_store()->return_async_stub());
  } else if (function.IsAsyncGenerator()) {
    return Code::ZoneHandle(
        compiler->zone(),
        compiler->isolate_group()->object_store()->return_async_star_stub());
  } else {
    UNREACHABLE();
  }
}

void NativeReturnInstr::EmitReturnMoves(FlowGraphCompiler* compiler) {
  const auto& dst1 = marshaller_.Location(compiler::ffi::kResultIndex);
  if (dst1.payload_type().IsVoid()) {
    return;
  }
  if (dst1.IsMultiple()) {
    Register typed_data_reg = locs()->in(0).reg();
    // Load the data pointer out of the TypedData/Pointer.
    __ LoadField(
        typed_data_reg,
        compiler::FieldAddress(typed_data_reg,
                               compiler::target::PointerBase::data_offset()));

    const auto& multiple = dst1.AsMultiple();
    int offset_in_bytes = 0;
    for (intptr_t i = 0; i < multiple.locations().length(); i++) {
      const auto& dst = *multiple.locations().At(i);
      ASSERT(!dst.IsRegisters() ||
             dst.AsRegisters().reg_at(0) != typed_data_reg);
      const auto& src = compiler::ffi::NativeStackLocation(
          dst.payload_type(), dst.container_type(), typed_data_reg,
          offset_in_bytes);
      NoTemporaryAllocator no_temp;
      compiler->EmitNativeMove(dst, src, &no_temp);
      offset_in_bytes += dst.payload_type().SizeInBytes();
    }
    return;
  }
  const auto& dst = dst1.IsPointerToMemory()
                        ? dst1.AsPointerToMemory().pointer_return_location()
                        : dst1;

  const Location src_loc = locs()->in(0);
  const Representation src_type = RequiredInputRepresentation(0);
  NoTemporaryAllocator no_temp;
  compiler->EmitMoveToNative(dst, src_loc, src_type, &no_temp);
}

LocationSummary* NativeReturnInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  ASSERT(marshaller_.NumReturnDefinitions() == 1);
  const auto& native_loc = marshaller_.Location(compiler::ffi::kResultIndex);
  const auto& native_return_loc =
      native_loc.IsPointerToMemory()
          ? native_loc.AsPointerToMemory().pointer_return_location()
          : native_loc;
  if (native_loc.IsMultiple()) {
    // We pass in a typed data for easy copying in machine code.
    // Can be any register which does not conflict with return registers.
    Register typed_data_reg = CallingConventions::kSecondNonArgumentRegister;
    ASSERT(typed_data_reg != CallingConventions::kReturnReg);
    ASSERT(typed_data_reg != CallingConventions::kSecondReturnReg);
    locs->set_in(0, Location::RegisterLocation(typed_data_reg));
  } else {
    locs->set_in(0, native_return_loc.AsLocation());
  }
  return locs;
}

LocationSummary* RecordCoverageInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 2;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_temp(1, Location::RequiresRegister());
  return locs;
}

void RecordCoverageInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const auto array_temp = locs()->temp(0).reg();
  const auto value_temp = locs()->temp(1).reg();

  __ LoadObject(array_temp, coverage_array_);
  __ LoadImmediate(value_temp, Smi::RawValue(1));
  __ StoreFieldToOffset(
      value_temp, array_temp,
      compiler::target::Array::element_offset(coverage_index_),
      compiler::kObjectBytes);
}

#undef Z

Representation FfiCallInstr::representation() const {
  if (marshaller_.PassTypedData()) {
    // Don't care, we're discarding the value.
    return kTagged;
  }
  return marshaller_.RepInFfiCall(compiler::ffi::kResultIndex);
}

// TODO(http://dartbug.com/48543): integrate with register allocator directly.
DEFINE_BACKEND(LoadThread, (Register out)) {
  __ MoveRegister(out, THR);
}

LocationSummary* CCallInstr::MakeLocationSummaryInternal(
    Zone* zone,
    const RegList temps) const {
  LocationSummary* summary =
      new (zone) LocationSummary(zone, /*num_inputs=*/InputCount(),
                                 /*num_temps=*/Utils::CountOneBitsWord(temps),
                                 LocationSummary::kNativeLeafCall);

  intptr_t reg_i = 0;
  for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
    if ((temps & (1 << reg)) != 0) {
      summary->set_temp(reg_i,
                        Location::RegisterLocation(static_cast<Register>(reg)));
      reg_i++;
    }
  }

  summary->set_in(TargetAddressIndex(),
                  Location::RegisterLocation(
                      CallingConventions::kFirstNonArgumentRegister));

  const auto& argument_locations =
      native_calling_convention_.argument_locations();
  for (intptr_t i = 0, n = argument_locations.length(); i < n; ++i) {
    const auto& argument_location = *argument_locations.At(i);
    if (argument_location.IsRegisters()) {
      const auto& reg_location = argument_location.AsRegisters();
      ASSERT(reg_location.num_regs() == 1);
      summary->set_in(i, reg_location.AsLocation());
    } else if (argument_location.IsFpuRegisters()) {
      UNIMPLEMENTED();
    } else if (argument_location.IsStack()) {
      summary->set_in(i, Location::Any());
    } else {
      UNIMPLEMENTED();
    }
  }
  const auto& return_location = native_calling_convention_.return_location();
  ASSERT(return_location.IsRegisters());
  summary->set_out(0, return_location.AsLocation());
  return summary;
}

CCallInstr::CCallInstr(
    const compiler::ffi::NativeCallingConvention& native_calling_convention,
    InputsArray&& inputs)
    : VariadicDefinition(std::move(inputs), DeoptId::kNone),
      native_calling_convention_(native_calling_convention) {
#ifdef DEBUG
  const intptr_t num_inputs =
      native_calling_convention.argument_locations().length() + 1;
  ASSERT(num_inputs == InputCount());
#endif
}

Representation CCallInstr::RequiredInputRepresentation(intptr_t idx) const {
  if (idx < native_calling_convention_.argument_locations().length()) {
    const auto& argument_type =
        native_calling_convention_.argument_locations().At(idx)->payload_type();
    ASSERT(argument_type.IsExpressibleAsRepresentation());
    return argument_type.AsRepresentation();
  }
  ASSERT(idx == TargetAddressIndex());
  return kUnboxedFfiIntPtr;
}

void CCallInstr::EmitParamMoves(FlowGraphCompiler* compiler,
                                Register saved_fp,
                                Register temp0) {
  if (native_calling_convention_.StackTopInBytes() == 0) {
    return;
  }

  ConstantTemporaryAllocator temp_alloc(temp0);
  compiler::ffi::FrameRebase rebase(compiler->zone(), /*old_base=*/FPREG,
                                    /*new_base=*/saved_fp,
                                    /*stack_delta=*/0);

  __ Comment("EmitParamMoves");
  const auto& argument_locations =
      native_calling_convention_.argument_locations();
  for (intptr_t i = 0, n = argument_locations.length(); i < n; ++i) {
    const auto& argument_location = *argument_locations.At(i);
    if (argument_location.IsRegisters()) {
      const auto& reg_location = argument_location.AsRegisters();
      ASSERT(reg_location.num_regs() == 1);
      const Location src_loc = rebase.Rebase(locs()->in(i));
      const Representation src_rep = RequiredInputRepresentation(i);
      compiler->EmitMoveToNative(argument_location, src_loc, src_rep,
                                 &temp_alloc);
    } else if (argument_location.IsFpuRegisters()) {
      UNIMPLEMENTED();
    } else if (argument_location.IsStack()) {
      const Location src_loc = rebase.Rebase(locs()->in(i));
      const Representation src_rep = RequiredInputRepresentation(i);
#if defined(INCLUDE_IL_PRINTER)
      __ Comment("Param %" Pd ": %s %s -> %s", i, src_loc.ToCString(),
                 RepresentationToCString(src_rep),
                 argument_location.ToCString());
#endif
      compiler->EmitMoveToNative(argument_location, src_loc, src_rep,
                                 &temp_alloc);
    } else {
      UNIMPLEMENTED();
    }
  }
  __ Comment("EmitParamMovesEnd");
}

Representation CCallInstr::representation() const {
  const auto& return_type =
      native_calling_convention_.return_location().payload_type();
  ASSERT(return_type.IsExpressibleAsRepresentation());
  return return_type.AsRepresentation();
}

// SIMD

SimdOpInstr::Kind SimdOpInstr::KindForOperator(MethodRecognizer::Kind kind) {
  switch (kind) {
    case MethodRecognizer::kFloat32x4Mul:
      return SimdOpInstr::kFloat32x4Mul;
    case MethodRecognizer::kFloat32x4Div:
      return SimdOpInstr::kFloat32x4Div;
    case MethodRecognizer::kFloat32x4Add:
      return SimdOpInstr::kFloat32x4Add;
    case MethodRecognizer::kFloat32x4Sub:
      return SimdOpInstr::kFloat32x4Sub;
    case MethodRecognizer::kFloat64x2Mul:
      return SimdOpInstr::kFloat64x2Mul;
    case MethodRecognizer::kFloat64x2Div:
      return SimdOpInstr::kFloat64x2Div;
    case MethodRecognizer::kFloat64x2Add:
      return SimdOpInstr::kFloat64x2Add;
    case MethodRecognizer::kFloat64x2Sub:
      return SimdOpInstr::kFloat64x2Sub;
    default:
      break;
  }
  UNREACHABLE();
  return SimdOpInstr::kIllegalSimdOp;
}

SimdOpInstr* SimdOpInstr::CreateFromCall(Zone* zone,
                                         MethodRecognizer::Kind kind,
                                         Definition* receiver,
                                         Instruction* call,
                                         intptr_t mask /* = 0 */) {
  SimdOpInstr* op;
  switch (kind) {
    case MethodRecognizer::kFloat32x4Mul:
    case MethodRecognizer::kFloat32x4Div:
    case MethodRecognizer::kFloat32x4Add:
    case MethodRecognizer::kFloat32x4Sub:
    case MethodRecognizer::kFloat64x2Mul:
    case MethodRecognizer::kFloat64x2Div:
    case MethodRecognizer::kFloat64x2Add:
    case MethodRecognizer::kFloat64x2Sub:
      op = new (zone) SimdOpInstr(KindForOperator(kind), call->deopt_id());
      break;
    default:
      op = new (zone) SimdOpInstr(KindForMethod(kind), call->deopt_id());
      break;
  }

  if (receiver != nullptr) {
    op->SetInputAt(0, new (zone) Value(receiver));
  }
  for (intptr_t i = (receiver != nullptr ? 1 : 0); i < op->InputCount(); i++) {
    op->SetInputAt(i, call->ArgumentValueAt(i)->CopyWithType(zone));
  }
  if (op->HasMask()) {
    op->set_mask(mask);
  }
  ASSERT(call->ArgumentCount() == (op->InputCount() + (op->HasMask() ? 1 : 0)));
  return op;
}

SimdOpInstr* SimdOpInstr::CreateFromFactoryCall(Zone* zone,
                                                MethodRecognizer::Kind kind,
                                                Instruction* call) {
  SimdOpInstr* op =
      new (zone) SimdOpInstr(KindForMethod(kind), call->deopt_id());
  for (intptr_t i = 0; i < op->InputCount(); i++) {
    // Note: ArgumentAt(0) is type arguments which we don't need.
    op->SetInputAt(i, call->ArgumentValueAt(i + 1)->CopyWithType(zone));
  }
  ASSERT(call->ArgumentCount() == (op->InputCount() + 1));
  return op;
}

SimdOpInstr::Kind SimdOpInstr::KindForOperator(intptr_t cid, Token::Kind op) {
  switch (cid) {
    case kFloat32x4Cid:
      switch (op) {
        case Token::kADD:
          return kFloat32x4Add;
        case Token::kSUB:
          return kFloat32x4Sub;
        case Token::kMUL:
          return kFloat32x4Mul;
        case Token::kDIV:
          return kFloat32x4Div;
        default:
          break;
      }
      break;

    case kFloat64x2Cid:
      switch (op) {
        case Token::kADD:
          return kFloat64x2Add;
        case Token::kSUB:
          return kFloat64x2Sub;
        case Token::kMUL:
          return kFloat64x2Mul;
        case Token::kDIV:
          return kFloat64x2Div;
        default:
          break;
      }
      break;

    case kInt32x4Cid:
      switch (op) {
        case Token::kADD:
          return kInt32x4Add;
        case Token::kSUB:
          return kInt32x4Sub;
        case Token::kBIT_AND:
          return kInt32x4BitAnd;
        case Token::kBIT_OR:
          return kInt32x4BitOr;
        case Token::kBIT_XOR:
          return kInt32x4BitXor;
        default:
          break;
      }
      break;
  }

  UNREACHABLE();
  return kIllegalSimdOp;
}

SimdOpInstr::Kind SimdOpInstr::KindForMethod(MethodRecognizer::Kind kind) {
  switch (kind) {
#define CASE_METHOD(Arity, Mask, Name, ...)                                    \
  case MethodRecognizer::k##Name:                                              \
    return k##Name;
#define CASE_BINARY_OP(Arity, Mask, Name, Args, Result)
    SIMD_OP_LIST(CASE_METHOD, CASE_BINARY_OP)
#undef CASE_METHOD
#undef CASE_BINARY_OP
    default:
      break;
  }

  FATAL("Not a SIMD method: %s", MethodRecognizer::KindToCString(kind));
  return kIllegalSimdOp;
}

// Methods InputCount(), representation(), RequiredInputRepresentation() and
// HasMask() are using an array of SimdOpInfo structures representing all
// necessary information about the instruction.

struct SimdOpInfo {
  uint8_t arity;
  bool has_mask;
  Representation output;
  Representation inputs[4];
};

// Make representation from type name used by SIMD_OP_LIST.
#define REP(T) (kUnboxed##T)
static const Representation kUnboxedBool = kTagged;
static const Representation kUnboxedInt8 = kUnboxedInt32;

#define ENCODE_INPUTS_0()
#define ENCODE_INPUTS_1(In0) REP(In0)
#define ENCODE_INPUTS_2(In0, In1) REP(In0), REP(In1)
#define ENCODE_INPUTS_3(In0, In1, In2) REP(In0), REP(In1), REP(In2)
#define ENCODE_INPUTS_4(In0, In1, In2, In3)                                    \
  REP(In0), REP(In1), REP(In2), REP(In3)

// Helpers for correct interpretation of the Mask field in the SIMD_OP_LIST.
#define HAS_MASK true
#define HAS__ false

// Define the metadata array.
static const SimdOpInfo simd_op_information[] = {
#define CASE(Arity, Mask, Name, Args, Result)                                  \
  {Arity, HAS_##Mask, REP(Result), {PP_APPLY(ENCODE_INPUTS_##Arity, Args)}},
    SIMD_OP_LIST(CASE, CASE)
#undef CASE
};

// Undef all auxiliary macros.
#undef ENCODE_INFORMATION
#undef HAS__
#undef HAS_MASK
#undef ENCODE_INPUTS_0
#undef ENCODE_INPUTS_1
#undef ENCODE_INPUTS_2
#undef ENCODE_INPUTS_3
#undef ENCODE_INPUTS_4
#undef REP

intptr_t SimdOpInstr::InputCount() const {
  return simd_op_information[kind()].arity;
}

Representation SimdOpInstr::representation() const {
  return simd_op_information[kind()].output;
}

Representation SimdOpInstr::RequiredInputRepresentation(intptr_t idx) const {
  ASSERT(0 <= idx && idx < InputCount());
  return simd_op_information[kind()].inputs[idx];
}

bool SimdOpInstr::HasMask() const {
  return simd_op_information[kind()].has_mask;
}

LocationSummary* Call1ArgStubInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  switch (stub_id_) {
    case StubId::kCloneSuspendState:
      locs->set_in(
          0, Location::RegisterLocation(CloneSuspendStateStubABI::kSourceReg));
      break;
    case StubId::kInitAsync:
    case StubId::kInitAsyncStar:
    case StubId::kInitSyncStar:
      locs->set_in(0, Location::RegisterLocation(
                          InitSuspendableFunctionStubABI::kTypeArgsReg));
      break;
    case StubId::kFfiAsyncCallbackSend:
      locs->set_in(
          0, Location::RegisterLocation(FfiAsyncCallbackSendStubABI::kArgsReg));
      break;
  }
  locs->set_out(0, Location::RegisterLocation(CallingConventions::kReturnReg));
  return locs;
}

void Call1ArgStubInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ObjectStore* object_store = compiler->isolate_group()->object_store();
  Code& stub = Code::ZoneHandle(compiler->zone());
  switch (stub_id_) {
    case StubId::kCloneSuspendState:
      stub = object_store->clone_suspend_state_stub();
      break;
    case StubId::kInitAsync:
      stub = object_store->init_async_stub();
      break;
    case StubId::kInitAsyncStar:
      stub = object_store->init_async_star_stub();
      break;
    case StubId::kInitSyncStar:
      stub = object_store->init_sync_star_stub();
      break;
    case StubId::kFfiAsyncCallbackSend:
      stub = object_store->ffi_async_callback_send_stub();
      break;
  }
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
}

Definition* SuspendInstr::Canonicalize(FlowGraph* flow_graph) {
  if (stub_id() == StubId::kAwaitWithTypeCheck &&
      !operand()->Type()->CanBeFuture()) {
    type_args()->RemoveFromUseList();
    stub_id_ = StubId::kAwait;
  }
  return this;
}

LocationSummary* SuspendInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = has_type_args() ? 2 : 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(SuspendStubABI::kArgumentReg));
  if (has_type_args()) {
    locs->set_in(1, Location::RegisterLocation(SuspendStubABI::kTypeArgsReg));
  }
  locs->set_out(0, Location::RegisterLocation(CallingConventions::kReturnReg));
  return locs;
}

void SuspendInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Use deopt_id as a yield index.
  compiler->EmitYieldPositionMetadata(source(), deopt_id());

  ObjectStore* object_store = compiler->isolate_group()->object_store();
  Code& stub = Code::ZoneHandle(compiler->zone());
  switch (stub_id_) {
    case StubId::kAwait:
      stub = object_store->await_stub();
      break;
    case StubId::kAwaitWithTypeCheck:
      stub = object_store->await_with_type_check_stub();
      break;
    case StubId::kYieldAsyncStar:
      stub = object_store->yield_async_star_stub();
      break;
    case StubId::kSuspendSyncStarAtStart:
      stub = object_store->suspend_sync_star_at_start_stub();
      break;
    case StubId::kSuspendSyncStarAtYield:
      stub = object_store->suspend_sync_star_at_yield_stub();
      break;
  }
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());

#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32)
  // On x86 (X64 and IA32) mismatch between calls and returns
  // significantly regresses performance. So suspend stub
  // does not return directly to the caller. Instead, a small
  // epilogue is generated right after the call to suspend stub,
  // and resume stub adjusts resume PC to skip this epilogue.
  const intptr_t start = compiler->assembler()->CodeSize();
  __ LeaveFrame();
  __ ret();
  RELEASE_ASSERT(compiler->assembler()->CodeSize() - start ==
                 SuspendStubABI::kResumePcDistance);
  compiler->EmitCallsiteMetadata(source(), resume_deopt_id(),
                                 UntaggedPcDescriptors::kOther, locs(), env());
#endif
}

LocationSummary* AllocateRecordInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_out(0, Location::RegisterLocation(AllocateRecordABI::kResultReg));
  return locs;
}

void AllocateRecordInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Code& stub = Code::ZoneHandle(
      compiler->zone(),
      compiler->isolate_group()->object_store()->allocate_record_stub());
  __ LoadImmediate(AllocateRecordABI::kShapeReg,
                   Smi::RawValue(shape().AsInt()));
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
}

LocationSummary* AllocateSmallRecordInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  ASSERT(num_fields() == 2 || num_fields() == 3);
  const intptr_t kNumInputs = InputCount();
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0,
               Location::RegisterLocation(AllocateSmallRecordABI::kValue0Reg));
  locs->set_in(1,
               Location::RegisterLocation(AllocateSmallRecordABI::kValue1Reg));
  if (num_fields() > 2) {
    locs->set_in(
        2, Location::RegisterLocation(AllocateSmallRecordABI::kValue2Reg));
  }
  locs->set_out(0,
                Location::RegisterLocation(AllocateSmallRecordABI::kResultReg));
  return locs;
}

void AllocateSmallRecordInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  auto object_store = compiler->isolate_group()->object_store();
  Code& stub = Code::ZoneHandle(compiler->zone());
  if (shape().HasNamedFields()) {
    __ LoadImmediate(AllocateSmallRecordABI::kShapeReg,
                     Smi::RawValue(shape().AsInt()));
    switch (num_fields()) {
      case 2:
        stub = object_store->allocate_record2_named_stub();
        break;
      case 3:
        stub = object_store->allocate_record3_named_stub();
        break;
      default:
        UNREACHABLE();
    }
  } else {
    switch (num_fields()) {
      case 2:
        stub = object_store->allocate_record2_stub();
        break;
      case 3:
        stub = object_store->allocate_record3_stub();
        break;
      default:
        UNREACHABLE();
    }
  }
  compiler->GenerateStubCall(source(), stub, UntaggedPcDescriptors::kOther,
                             locs(), deopt_id(), env());
}

LocationSummary* MakePairInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // MakePair instruction is used to combine 2 separate kTagged values into
  // a single kPairOfTagged value for the subsequent Return, so it uses
  // fixed registers used to return values according to the calling conventions
  // in order to avoid any extra moves.
  locs->set_in(0, Location::RegisterLocation(CallingConventions::kReturnReg));
  locs->set_in(
      1, Location::RegisterLocation(CallingConventions::kSecondReturnReg));
  locs->set_out(
      0, Location::Pair(
             Location::RegisterLocation(CallingConventions::kReturnReg),
             Location::RegisterLocation(CallingConventions::kSecondReturnReg)));
  return locs;
}

void MakePairInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // No-op.
}

#undef __

}  // namespace dart
