// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/profiler_service.h"

#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/log.h"
#include "vm/malloc_hooks.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/scope_timer.h"

namespace dart {

DECLARE_FLAG(int, max_profile_depth);
DECLARE_FLAG(int, profile_period);
DECLARE_FLAG(bool, show_invisible_frames);
DECLARE_FLAG(bool, profile_vm);

#ifndef PRODUCT

class DeoptimizedCodeSet : public ZoneAllocated {
 public:
  explicit DeoptimizedCodeSet(Isolate* isolate)
      : previous_(
            GrowableObjectArray::ZoneHandle(isolate->deoptimized_code_array())),
        current_(GrowableObjectArray::ZoneHandle(
            previous_.IsNull() ? GrowableObjectArray::null()
                               : GrowableObjectArray::New())) {}

  void Add(const Code& code) {
    if (current_.IsNull()) {
      return;
    }
    if (!Contained(code, previous_) || Contained(code, current_)) {
      return;
    }
    current_.Add(code);
  }

  void UpdateIsolate(Isolate* isolate) {
    intptr_t size_before = SizeOf(previous_);
    intptr_t size_after = SizeOf(current_);
    if ((size_before > 0) && FLAG_trace_profiler) {
      intptr_t length_before = previous_.Length();
      intptr_t length_after = current_.Length();
      OS::Print(
          "Updating isolate deoptimized code array: "
          "%" Pd " -> %" Pd " [%" Pd " -> %" Pd "]\n",
          size_before, size_after, length_before, length_after);
    }
    isolate->set_deoptimized_code_array(current_);
  }

 private:
  bool Contained(const Code& code, const GrowableObjectArray& array) {
    if (array.IsNull() || code.IsNull()) {
      return false;
    }
    NoSafepointScope no_safepoint_scope;
    for (intptr_t i = 0; i < array.Length(); i++) {
      if (code.raw() == array.At(i)) {
        return true;
      }
    }
    return false;
  }

  intptr_t SizeOf(const GrowableObjectArray& array) {
    if (array.IsNull()) {
      return 0;
    }
    Code& code = Code::ZoneHandle();
    intptr_t size = 0;
    for (intptr_t i = 0; i < array.Length(); i++) {
      code ^= array.At(i);
      ASSERT(!code.IsNull());
      size += code.Size();
    }
    return size;
  }

  // Array holding code that is being kept around only for the profiler.
  const GrowableObjectArray& previous_;
  // Array holding code that should continue to be kept around for the profiler.
  const GrowableObjectArray& current_;
};

ProfileFunctionSourcePosition::ProfileFunctionSourcePosition(
    TokenPosition token_pos)
    : token_pos_(token_pos), exclusive_ticks_(0), inclusive_ticks_(0) {}

void ProfileFunctionSourcePosition::Tick(bool exclusive) {
  if (exclusive) {
    exclusive_ticks_++;
  } else {
    inclusive_ticks_++;
  }
}

ProfileFunction::ProfileFunction(Kind kind,
                                 const char* name,
                                 const Function& function,
                                 const intptr_t table_index)
    : kind_(kind),
      name_(name),
      function_(Function::ZoneHandle(function.raw())),
      table_index_(table_index),
      profile_codes_(0),
      source_position_ticks_(0),
      exclusive_ticks_(0),
      inclusive_ticks_(0),
      inclusive_serial_(-1) {
  ASSERT((kind_ != kDartFunction) || !function_.IsNull());
  ASSERT((kind_ != kDartFunction) || (table_index_ >= 0));
  ASSERT(profile_codes_.length() == 0);
}

const char* ProfileFunction::Name() const {
  if (name_ != NULL) {
    return name_;
  }
  ASSERT(!function_.IsNull());
  const String& func_name =
      String::Handle(function_.QualifiedUserVisibleName());
  return func_name.ToCString();
}

bool ProfileFunction::is_visible() const {
  if (function_.IsNull()) {
    // Some synthetic function.
    return true;
  }
  return FLAG_show_invisible_frames || function_.is_visible();
}

void ProfileFunction::Tick(bool exclusive,
                           intptr_t inclusive_serial,
                           TokenPosition token_position) {
  if (exclusive) {
    exclusive_ticks_++;
    TickSourcePosition(token_position, exclusive);
  }
  // Fall through and tick inclusive count too.
  if (inclusive_serial_ == inclusive_serial) {
    // Already ticked.
    return;
  }
  inclusive_serial_ = inclusive_serial;
  inclusive_ticks_++;
  TickSourcePosition(token_position, false);
}

void ProfileFunction::TickSourcePosition(TokenPosition token_position,
                                         bool exclusive) {
  intptr_t i = 0;
  for (; i < source_position_ticks_.length(); i++) {
    ProfileFunctionSourcePosition& position = source_position_ticks_[i];
    if (position.token_pos().value() == token_position.value()) {
      if (FLAG_trace_profiler_verbose) {
        OS::Print("Ticking source position %s %s\n",
                  exclusive ? "exclusive" : "inclusive",
                  token_position.ToCString());
      }
      // Found existing position, tick it.
      position.Tick(exclusive);
      return;
    }
    if (position.token_pos().value() > token_position.value()) {
      break;
    }
  }

  // Add new one, sorted by token position value.
  ProfileFunctionSourcePosition pfsp(token_position);
  if (FLAG_trace_profiler_verbose) {
    OS::Print("Ticking source position %s %s\n",
              exclusive ? "exclusive" : "inclusive",
              token_position.ToCString());
  }
  pfsp.Tick(exclusive);

  if (i < source_position_ticks_.length()) {
    source_position_ticks_.InsertAt(i, pfsp);
  } else {
    source_position_ticks_.Add(pfsp);
  }
}

const char* ProfileFunction::KindToCString(Kind kind) {
  switch (kind) {
    case kDartFunction:
      return "Dart";
    case kNativeFunction:
      return "Native";
    case kTagFunction:
      return "Tag";
    case kStubFunction:
      return "Stub";
    case kUnknownFunction:
      return "Collected";
    default:
      UNIMPLEMENTED();
      return "";
  }
}

void ProfileFunction::PrintToJSONObject(JSONObject* func) {
  func->AddProperty("type", "@Function");
  func->AddProperty("name", name());
  func->AddProperty("_kind", KindToCString(kind()));
}

void ProfileFunction::PrintToJSONArray(JSONArray* functions) {
  JSONObject obj(functions);
  obj.AddProperty("kind", KindToCString(kind()));
  obj.AddProperty("inclusiveTicks", inclusive_ticks());
  obj.AddProperty("exclusiveTicks", exclusive_ticks());
  if (kind() == kDartFunction) {
    ASSERT(!function_.IsNull());
    obj.AddProperty("function", function_);
  } else {
    JSONObject func(&obj, "function");
    PrintToJSONObject(&func);
  }
  {
    JSONArray codes(&obj, "codes");
    for (intptr_t i = 0; i < profile_codes_.length(); i++) {
      intptr_t code_index = profile_codes_[i];
      codes.AddValue(code_index);
    }
  }
}

void ProfileFunction::AddProfileCode(intptr_t code_table_index) {
  for (intptr_t i = 0; i < profile_codes_.length(); i++) {
    if (profile_codes_[i] == code_table_index) {
      return;
    }
  }
  profile_codes_.Add(code_table_index);
}

bool ProfileFunction::GetSinglePosition(ProfileFunctionSourcePosition* pfsp) {
  if (pfsp == NULL) {
    return false;
  }
  if (source_position_ticks_.length() != 1) {
    return false;
  }
  *pfsp = source_position_ticks_[0];
  return true;
}

ProfileCodeAddress::ProfileCodeAddress(uword pc)
    : pc_(pc), exclusive_ticks_(0), inclusive_ticks_(0) {}

void ProfileCodeAddress::Tick(bool exclusive) {
  if (exclusive) {
    exclusive_ticks_++;
  } else {
    inclusive_ticks_++;
  }
}

ProfileCode::ProfileCode(Kind kind,
                         uword start,
                         uword end,
                         int64_t timestamp,
                         const Code& code)
    : kind_(kind),
      start_(start),
      end_(end),
      exclusive_ticks_(0),
      inclusive_ticks_(0),
      inclusive_serial_(-1),
      code_(code),
      name_(NULL),
      compile_timestamp_(0),
      function_(NULL),
      code_table_index_(-1),
      address_ticks_(0) {}

void ProfileCode::TruncateLower(uword start) {
  if (start > start_) {
    start_ = start;
  }
  ASSERT(start_ < end_);
}

void ProfileCode::TruncateUpper(uword end) {
  if (end < end_) {
    end_ = end;
  }
  ASSERT(start_ < end_);
}

void ProfileCode::ExpandLower(uword start) {
  if (start < start_) {
    start_ = start;
  }
  ASSERT(start_ < end_);
}

void ProfileCode::ExpandUpper(uword end) {
  if (end > end_) {
    end_ = end;
  }
  ASSERT(start_ < end_);
}

bool ProfileCode::Overlaps(const ProfileCode* other) const {
  ASSERT(other != NULL);
  return other->Contains(start_) || other->Contains(end_ - 1) ||
         Contains(other->start()) || Contains(other->end() - 1);
}

bool ProfileCode::IsOptimizedDart() const {
  return !code_.IsNull() && code_.is_optimized();
}

void ProfileCode::SetName(const char* name) {
  if (name == NULL) {
    name_ = NULL;
  }
  intptr_t len = strlen(name);
  name_ = Thread::Current()->zone()->Alloc<char>(len + 1);
  strncpy(name_, name, len);
  name_[len] = '\0';
}

void ProfileCode::GenerateAndSetSymbolName(const char* prefix) {
  const intptr_t kBuffSize = 512;
  char buff[kBuffSize];
  OS::SNPrint(&buff[0], kBuffSize - 1, "%s [%" Px ", %" Px ")", prefix, start(),
              end());
  SetName(buff);
}

void ProfileCode::Tick(uword pc, bool exclusive, intptr_t serial) {
  // If exclusive is set, tick it.
  if (exclusive) {
    exclusive_ticks_++;
    TickAddress(pc, true);
  }
  // Fall through and tick inclusive count too.
  if (inclusive_serial_ == serial) {
    // Already gave inclusive tick for this sample.
    return;
  }
  inclusive_serial_ = serial;
  inclusive_ticks_++;
  TickAddress(pc, false);
}

void ProfileCode::TickAddress(uword pc, bool exclusive) {
  const intptr_t length = address_ticks_.length();

  intptr_t i = 0;
  for (; i < length; i++) {
    ProfileCodeAddress& entry = address_ticks_[i];
    if (entry.pc() == pc) {
      // Tick the address entry.
      entry.Tick(exclusive);
      return;
    }
    if (entry.pc() > pc) {
      break;
    }
  }

  // New address, add entry.
  ProfileCodeAddress entry(pc);

  entry.Tick(exclusive);

  if (i < length) {
    // Insert at i.
    address_ticks_.InsertAt(i, entry);
  } else {
    // Add to end.
    address_ticks_.Add(entry);
  }
}

void ProfileCode::PrintNativeCode(JSONObject* profile_code_obj) {
  ASSERT(kind() == kNativeCode);
  JSONObject obj(profile_code_obj, "code");
  obj.AddProperty("type", "@Code");
  obj.AddProperty("kind", "Native");
  obj.AddProperty("name", name());
  obj.AddProperty("_optimized", false);
  obj.AddPropertyF("start", "%" Px "", start());
  obj.AddPropertyF("end", "%" Px "", end());
  {
    // Generate a fake function entry.
    JSONObject func(&obj, "function");
    ASSERT(function_ != NULL);
    function_->PrintToJSONObject(&func);
  }
}

void ProfileCode::PrintCollectedCode(JSONObject* profile_code_obj) {
  ASSERT(kind() == kCollectedCode);
  JSONObject obj(profile_code_obj, "code");
  obj.AddProperty("type", "@Code");
  obj.AddProperty("kind", "Collected");
  obj.AddProperty("name", name());
  obj.AddProperty("_optimized", false);
  obj.AddPropertyF("start", "%" Px "", start());
  obj.AddPropertyF("end", "%" Px "", end());
  {
    // Generate a fake function entry.
    JSONObject func(&obj, "function");
    ASSERT(function_ != NULL);
    function_->PrintToJSONObject(&func);
  }
}

void ProfileCode::PrintOverwrittenCode(JSONObject* profile_code_obj) {
  ASSERT(kind() == kReusedCode);
  JSONObject obj(profile_code_obj, "code");
  obj.AddProperty("type", "@Code");
  obj.AddProperty("kind", "Collected");
  obj.AddProperty("name", name());
  obj.AddProperty("_optimized", false);
  obj.AddPropertyF("start", "%" Px "", start());
  obj.AddPropertyF("end", "%" Px "", end());
  {
    // Generate a fake function entry.
    JSONObject func(&obj, "function");
    ASSERT(function_ != NULL);
    function_->PrintToJSONObject(&func);
  }
}

void ProfileCode::PrintTagCode(JSONObject* profile_code_obj) {
  ASSERT(kind() == kTagCode);
  JSONObject obj(profile_code_obj, "code");
  obj.AddProperty("type", "@Code");
  obj.AddProperty("kind", "Tag");
  obj.AddProperty("name", name());
  obj.AddPropertyF("start", "%" Px "", start());
  obj.AddPropertyF("end", "%" Px "", end());
  obj.AddProperty("_optimized", false);
  {
    // Generate a fake function entry.
    JSONObject func(&obj, "function");
    ASSERT(function_ != NULL);
    function_->PrintToJSONObject(&func);
  }
}

const char* ProfileCode::KindToCString(Kind kind) {
  switch (kind) {
    case kDartCode:
      return "Dart";
    case kCollectedCode:
      return "Collected";
    case kNativeCode:
      return "Native";
    case kReusedCode:
      return "Overwritten";
    case kTagCode:
      return "Tag";
  }
  UNREACHABLE();
  return NULL;
}

void ProfileCode::PrintToJSONArray(JSONArray* codes) {
  JSONObject obj(codes);
  obj.AddProperty("kind", ProfileCode::KindToCString(kind()));
  obj.AddProperty("inclusiveTicks", inclusive_ticks());
  obj.AddProperty("exclusiveTicks", exclusive_ticks());
  if (kind() == kDartCode) {
    ASSERT(!code_.IsNull());
    obj.AddProperty("code", code_);
  } else if (kind() == kCollectedCode) {
    PrintCollectedCode(&obj);
  } else if (kind() == kReusedCode) {
    PrintOverwrittenCode(&obj);
  } else if (kind() == kTagCode) {
    PrintTagCode(&obj);
  } else {
    ASSERT(kind() == kNativeCode);
    PrintNativeCode(&obj);
  }
  {
    JSONArray ticks(&obj, "ticks");
    for (intptr_t i = 0; i < address_ticks_.length(); i++) {
      const ProfileCodeAddress& entry = address_ticks_[i];
      ticks.AddValueF("%" Px "", entry.pc());
      ticks.AddValue(entry.exclusive_ticks());
      ticks.AddValue(entry.inclusive_ticks());
    }
  }
}

class ProfileFunctionTable : public ZoneAllocated {
 public:
  ProfileFunctionTable()
      : null_function_(Function::ZoneHandle()),
        unknown_function_(NULL),
        table_(8) {
    unknown_function_ =
        Add(ProfileFunction::kUnknownFunction, "<unknown Dart function>");
  }

  ProfileFunction* LookupOrAdd(const Function& function) {
    ASSERT(!function.IsNull());
    ProfileFunction* profile_function = Lookup(function);
    if (profile_function != NULL) {
      return profile_function;
    }
    return Add(function);
  }

  ProfileFunction* Lookup(const Function& function) {
    ASSERT(!function.IsNull());
    return function_hash_.LookupValue(&function);
  }

  ProfileFunction* GetUnknown() {
    ASSERT(unknown_function_ != NULL);
    return unknown_function_;
  }

  // No protection against being called more than once for the same tag_id.
  ProfileFunction* AddTag(uword tag_id, const char* name) {
    // TODO(johnmccutchan): Canonicalize ProfileFunctions for tags.
    return Add(ProfileFunction::kTagFunction, name);
  }

  // No protection against being called more than once for the same native
  // address.
  ProfileFunction* AddNative(uword start_address, const char* name) {
    // TODO(johnmccutchan): Canonicalize ProfileFunctions for natives.
    return Add(ProfileFunction::kNativeFunction, name);
  }

  // No protection against being called more tha once for the same stub.
  ProfileFunction* AddStub(uword start_address, const char* name) {
    return Add(ProfileFunction::kStubFunction, name);
  }

  intptr_t length() const { return table_.length(); }

  ProfileFunction* At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < length());
    return table_[i];
  }

 private:
  ProfileFunction* Add(ProfileFunction::Kind kind, const char* name) {
    ASSERT(kind != ProfileFunction::kDartFunction);
    ASSERT(name != NULL);
    ProfileFunction* profile_function =
        new ProfileFunction(kind, name, null_function_, table_.length());
    table_.Add(profile_function);
    return profile_function;
  }

  ProfileFunction* Add(const Function& function) {
    ASSERT(Lookup(function) == NULL);
    ProfileFunction* profile_function = new ProfileFunction(
        ProfileFunction::kDartFunction, NULL, function, table_.length());
    table_.Add(profile_function);
    function_hash_.Insert(profile_function);
    return profile_function;
  }

  // Needed for DirectChainedHashMap.
  struct ProfileFunctionTableTrait {
    typedef ProfileFunction* Value;
    typedef const Function* Key;
    typedef ProfileFunction* Pair;

    static Key KeyOf(Pair kv) { return kv->function(); }

    static Value ValueOf(Pair kv) { return kv; }

    static inline intptr_t Hashcode(Key key) { return key->Hash(); }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return kv->function()->raw() == key->raw();
    }
  };

  const Function& null_function_;
  ProfileFunction* unknown_function_;
  ZoneGrowableArray<ProfileFunction*> table_;
  DirectChainedHashMap<ProfileFunctionTableTrait> function_hash_;
};

ProfileFunction* ProfileCode::SetFunctionAndName(ProfileFunctionTable* table) {
  ASSERT(function_ == NULL);

  ProfileFunction* function = NULL;
  if ((kind() == kReusedCode) || (kind() == kCollectedCode)) {
    if (name() == NULL) {
      // Lazily set generated name.
      GenerateAndSetSymbolName("[Collected]");
    }
    // Map these to a canonical unknown function.
    function = table->GetUnknown();
  } else if (kind() == kDartCode) {
    ASSERT(!code_.IsNull());
    const char* name = code_.QualifiedName();
    const Object& obj = Object::Handle(code_.owner());
    if (obj.IsFunction()) {
      function = table->LookupOrAdd(Function::Cast(obj));
    } else {
      // A stub.
      function = table->AddStub(start(), name);
    }
    SetName(name);
  } else if (kind() == kNativeCode) {
    if (name() == NULL) {
      // Lazily set generated name.
      GenerateAndSetSymbolName("[Native]");
    }
    function = table->AddNative(start(), name());
  } else if (kind() == kTagCode) {
    if (name() == NULL) {
      if (UserTags::IsUserTag(start())) {
        const char* tag_name = UserTags::TagName(start());
        ASSERT(tag_name != NULL);
        SetName(tag_name);
      } else if (VMTag::IsVMTag(start()) || VMTag::IsRuntimeEntryTag(start()) ||
                 VMTag::IsNativeEntryTag(start())) {
        const char* tag_name = VMTag::TagName(start());
        ASSERT(tag_name != NULL);
        SetName(tag_name);
      } else {
        switch (start()) {
          case VMTag::kRootTagId:
            SetName("Root");
            break;
          case VMTag::kTruncatedTagId:
            SetName("[Truncated]");
            break;
          case VMTag::kNoneCodeTagId:
            SetName("[No Code]");
            break;
          case VMTag::kOptimizedCodeTagId:
            SetName("[Optimized Code]");
            break;
          case VMTag::kUnoptimizedCodeTagId:
            SetName("[Unoptimized Code]");
            break;
          case VMTag::kNativeCodeTagId:
            SetName("[Native Code]");
            break;
          case VMTag::kInlineStartCodeTagId:
            SetName("[Inline Start]");
            break;
          case VMTag::kInlineEndCodeTagId:
            SetName("[Inline End]");
            break;
          default:
            UNIMPLEMENTED();
            break;
        }
      }
    }
    function = table->AddTag(start(), name());
  } else {
    UNREACHABLE();
  }
  ASSERT(function != NULL);

  function->AddProfileCode(code_table_index());

  function_ = function;
  return function_;
}

intptr_t ProfileCodeTable::FindCodeIndexForPC(uword pc) const {
  intptr_t length = table_.length();
  if (length == 0) {
    return -1;  // Not found.
  }
  intptr_t lo = 0;
  intptr_t hi = length - 1;
  while (lo <= hi) {
    intptr_t mid = (hi - lo + 1) / 2 + lo;
    ASSERT(mid >= lo);
    ASSERT(mid <= hi);
    ProfileCode* code = At(mid);
    if (code->Contains(pc)) {
      return mid;
    } else if (pc < code->start()) {
      hi = mid - 1;
    } else {
      lo = mid + 1;
    }
  }
  return -1;
}

intptr_t ProfileCodeTable::InsertCode(ProfileCode* new_code) {
  const intptr_t length = table_.length();
  if (length == 0) {
    table_.Add(new_code);
    return length;
  }

  // Determine the correct place to insert or merge |new_code| into table.
  intptr_t lo = -1;
  intptr_t hi = -1;
  ProfileCode* lo_code = NULL;
  ProfileCode* hi_code = NULL;
  const uword pc = new_code->end() - 1;
  FindNeighbors(pc, &lo, &hi, &lo_code, &hi_code);
  ASSERT((lo_code != NULL) || (hi_code != NULL));

  if (lo != -1) {
    // Has left neighbor.
    new_code->TruncateLower(lo_code->end());
    ASSERT(!new_code->Overlaps(lo_code));
  }
  if (hi != -1) {
    // Has right neighbor.
    new_code->TruncateUpper(hi_code->start());
    ASSERT(!new_code->Overlaps(hi_code));
  }

  if ((lo != -1) && (lo_code->kind() == ProfileCode::kNativeCode) &&
      (new_code->kind() == ProfileCode::kNativeCode) &&
      (lo_code->end() == new_code->start())) {
    // Adjacent left neighbor of the same kind: merge.
    // (dladdr doesn't give us symbol size so processing more samples may see
    // more PCs we didn't previously know belonged to it.)
    lo_code->ExpandUpper(new_code->end());
    return lo;
  }

  if ((hi != -1) && (hi_code->kind() == ProfileCode::kNativeCode) &&
      (new_code->kind() == ProfileCode::kNativeCode) &&
      (new_code->end() == hi_code->start())) {
    // Adjacent right neighbor of the same kind: merge.
    // (dladdr doesn't give us symbol size so processing more samples may see
    // more PCs we didn't previously know belonged to it.)
    hi_code->ExpandLower(new_code->start());
    return hi;
  }

  intptr_t insert;
  if (lo == -1) {
    insert = 0;
  } else if (hi == -1) {
    insert = length;
  } else {
    insert = lo + 1;
  }
  table_.InsertAt(insert, new_code);
  return insert;
}

void ProfileCodeTable::FindNeighbors(uword pc,
                                     intptr_t* lo,
                                     intptr_t* hi,
                                     ProfileCode** lo_code,
                                     ProfileCode** hi_code) const {
  ASSERT(table_.length() >= 1);

  intptr_t length = table_.length();

  if (pc < At(0)->start()) {
    // Lower than any existing code.
    *lo = -1;
    *lo_code = NULL;
    *hi = 0;
    *hi_code = At(*hi);
    return;
  }

  if (pc >= At(length - 1)->end()) {
    // Higher than any existing code.
    *lo = length - 1;
    *lo_code = At(*lo);
    *hi = -1;
    *hi_code = NULL;
    return;
  }

  *lo = 0;
  *lo_code = At(*lo);
  *hi = length - 1;
  *hi_code = At(*hi);

  while ((*hi - *lo) > 1) {
    intptr_t mid = (*hi - *lo + 1) / 2 + *lo;
    ASSERT(*lo <= mid);
    ASSERT(*hi >= mid);
    ProfileCode* code = At(mid);
    if (code->end() <= pc) {
      *lo = mid;
      *lo_code = code;
    }
    if (pc < code->end()) {
      *hi = mid;
      *hi_code = code;
    }
  }
}

void ProfileCodeTable::VerifyOrder() {
  const intptr_t length = table_.length();
  if (length == 0) {
    return;
  }
  uword last = table_[0]->end();
  for (intptr_t i = 1; i < length; i++) {
    ProfileCode* a = table_[i];
    ASSERT(last <= a->start());
    last = a->end();
  }
}

void ProfileCodeTable::VerifyOverlap() {
  const intptr_t length = table_.length();
  for (intptr_t i = 0; i < length; i++) {
    ProfileCode* a = table_[i];
    for (intptr_t j = i + 1; j < length; j++) {
      ProfileCode* b = table_[j];
      ASSERT(!a->Contains(b->start()) && !a->Contains(b->end() - 1) &&
             !b->Contains(a->start()) && !b->Contains(a->end() - 1));
    }
  }
}

ProfileTrieNode::ProfileTrieNode(intptr_t table_index)
    : table_index_(table_index),
      count_(0),
      exclusive_allocations_(0),
      inclusive_allocations_(0),
      children_(0),
      frame_id_(-1) {
  ASSERT(table_index_ >= 0);
}

ProfileTrieNode::~ProfileTrieNode() {}

void ProfileTrieNode::Tick(ProcessedSample* sample, bool exclusive) {
  count_++;
  IncrementAllocation(sample->native_allocation_size_bytes(), exclusive);
}

void ProfileTrieNode::SortChildren() {
  children_.Sort(ProfileTrieNodeCompare);
  // Recurse.
  for (intptr_t i = 0; i < children_.length(); i++) {
    children_[i]->SortChildren();
  }
}

intptr_t ProfileTrieNode::IndexOf(ProfileTrieNode* node) {
  for (intptr_t i = 0; i < children_.length(); i++) {
    if (children_[i] == node) {
      return i;
    }
  }
  return -1;
}

class ProfileCodeTrieNode : public ProfileTrieNode {
 public:
  explicit ProfileCodeTrieNode(intptr_t table_index)
      : ProfileTrieNode(table_index) {}

  void PrintToJSONArray(JSONArray* array) const {
    ASSERT(array != NULL);
    // Write CodeRegion index.
    array->AddValue(table_index());
    // Write count.
    array->AddValue(count());
    // Write number of children.
    intptr_t child_count = NumChildren();
    array->AddValue(child_count);
    // Write inclusive allocations.
    array->AddValue64(inclusive_allocations_);
    // Write exclusive allocations.
    array->AddValue64(exclusive_allocations_);
    // Recurse.
    for (intptr_t i = 0; i < child_count; i++) {
      children_[i]->PrintToJSONArray(array);
    }
  }

  ProfileCodeTrieNode* GetChild(intptr_t child_table_index) {
    const intptr_t length = NumChildren();
    intptr_t i = 0;
    while (i < length) {
      ProfileCodeTrieNode* child =
          reinterpret_cast<ProfileCodeTrieNode*>(children_[i]);
      if (child->table_index() == child_table_index) {
        return child;
      }
      if (child->table_index() > child_table_index) {
        break;
      }
      i++;
    }
    ProfileCodeTrieNode* child = new ProfileCodeTrieNode(child_table_index);
    if (i < length) {
      // Insert at i.
      children_.InsertAt(i, reinterpret_cast<ProfileTrieNode*>(child));
    } else {
      // Add to end.
      children_.Add(reinterpret_cast<ProfileTrieNode*>(child));
    }
    return child;
  }
};

class ProfileFunctionTrieNodeCode {
 public:
  explicit ProfileFunctionTrieNodeCode(intptr_t index)
      : code_index_(index), ticks_(0) {}

  intptr_t index() const { return code_index_; }

  void Tick() { ticks_++; }

  intptr_t ticks() const { return ticks_; }

 private:
  intptr_t code_index_;
  intptr_t ticks_;
};

class ProfileFunctionTrieNode : public ProfileTrieNode {
 public:
  explicit ProfileFunctionTrieNode(intptr_t table_index)
      : ProfileTrieNode(table_index), code_objects_(1) {}

  void PrintToJSONArray(JSONArray* array) const {
    ASSERT(array != NULL);
    // Write CodeRegion index.
    array->AddValue(table_index());
    // Write count.
    array->AddValue(count());
    // Write inclusive allocations.
    array->AddValue64(inclusive_allocations_);
    // Write exclusive allocations.
    array->AddValue64(exclusive_allocations_);
    // Write number of code objects.
    intptr_t code_count = code_objects_.length();
    array->AddValue(code_count);
    // Write each code object index and ticks.
    for (intptr_t i = 0; i < code_count; i++) {
      array->AddValue(code_objects_[i].index());
      array->AddValue(code_objects_[i].ticks());
    }
    // Write number of children.
    intptr_t child_count = children_.length();
    array->AddValue(child_count);
    // Recurse.
    for (intptr_t i = 0; i < child_count; i++) {
      children_[i]->PrintToJSONArray(array);
    }
  }

  ProfileFunctionTrieNode* GetChild(intptr_t child_table_index) {
    const intptr_t length = NumChildren();
    intptr_t i = 0;
    while (i < length) {
      ProfileFunctionTrieNode* child =
          reinterpret_cast<ProfileFunctionTrieNode*>(children_[i]);
      if (child->table_index() == child_table_index) {
        return child;
      }
      if (child->table_index() > child_table_index) {
        break;
      }
      i++;
    }
    ProfileFunctionTrieNode* child =
        new ProfileFunctionTrieNode(child_table_index);
    if (i < length) {
      // Insert at i.
      children_.InsertAt(i, reinterpret_cast<ProfileTrieNode*>(child));
    } else {
      // Add to end.
      children_.Add(reinterpret_cast<ProfileTrieNode*>(child));
    }
    return child;
  }

  void AddCodeObjectIndex(intptr_t index) {
    for (intptr_t i = 0; i < code_objects_.length(); i++) {
      ProfileFunctionTrieNodeCode& code_object = code_objects_[i];
      if (code_object.index() == index) {
        code_object.Tick();
        return;
      }
    }
    ProfileFunctionTrieNodeCode code_object(index);
    code_object.Tick();
    code_objects_.Add(code_object);
  }

 private:
  ZoneGrowableArray<ProfileFunctionTrieNodeCode> code_objects_;
};

class ProfileCodeInlinedFunctionsCache : public ValueObject {
 public:
  ProfileCodeInlinedFunctionsCache() : cache_cursor_(0), last_hit_(0) {
    for (intptr_t i = 0; i < kCacheSize; i++) {
      cache_[i].Reset();
    }
    cache_hit_ = 0;
    cache_miss_ = 0;
  }

  ~ProfileCodeInlinedFunctionsCache() {
    if (FLAG_trace_profiler) {
      intptr_t total = cache_hit_ + cache_miss_;
      OS::Print("LOOKUPS: %" Pd " HITS: %" Pd " MISSES: %" Pd "\n", total,
                cache_hit_, cache_miss_);
    }
  }

  void Get(uword pc,
           const Code& code,
           ProcessedSample* sample,
           intptr_t frame_index,
           // Outputs:
           GrowableArray<const Function*>** inlined_functions,
           GrowableArray<TokenPosition>** inlined_token_positions,
           TokenPosition* token_position) {
    const intptr_t offset = OffsetForPC(pc, code, sample, frame_index);
    if (FindInCache(pc, offset, inlined_functions, inlined_token_positions,
                    token_position)) {
      // Found in cache.
      return;
    }
    Add(pc, code, sample, frame_index, inlined_functions,
        inlined_token_positions, token_position);
  }

 private:
  bool FindInCache(uword pc,
                   intptr_t offset,
                   GrowableArray<const Function*>** inlined_functions,
                   GrowableArray<TokenPosition>** inlined_token_positions,
                   TokenPosition* token_position) {
    // Simple linear scan.
    for (intptr_t i = 0; i < kCacheSize; i++) {
      intptr_t index = (last_hit_ + i) % kCacheSize;
      if ((cache_[index].pc == pc) && (cache_[index].offset == offset)) {
        // Hit.
        if (cache_[index].inlined_functions.length() == 0) {
          *inlined_functions = NULL;
          *inlined_token_positions = NULL;
        } else {
          *inlined_functions = &cache_[index].inlined_functions;
          *inlined_token_positions = &cache_[index].inlined_token_positions;
        }
        *token_position = cache_[index].token_position;
        cache_hit_++;
        last_hit_ = index;
        return true;
      }
    }
    cache_miss_++;
    return false;
  }

  // Add to cache and fill in outputs.
  void Add(uword pc,
           const Code& code,
           ProcessedSample* sample,
           intptr_t frame_index,
           // Outputs:
           GrowableArray<const Function*>** inlined_functions,
           GrowableArray<TokenPosition>** inlined_token_positions,
           TokenPosition* token_position) {
    const intptr_t offset = OffsetForPC(pc, code, sample, frame_index);
    CacheEntry* cache_entry = &cache_[NextFreeIndex()];
    cache_entry->Reset();
    cache_entry->pc = pc;
    cache_entry->offset = offset;
    code.GetInlinedFunctionsAtInstruction(
        offset, &(cache_entry->inlined_functions),
        &(cache_entry->inlined_token_positions));
    if (cache_entry->inlined_functions.length() == 0) {
      *inlined_functions = NULL;
      *inlined_token_positions = NULL;
      *token_position = cache_entry->token_position = TokenPosition();
      return;
    }

    // Write outputs.
    *inlined_functions = &(cache_entry->inlined_functions);
    *inlined_token_positions = &(cache_entry->inlined_token_positions);
    *token_position = cache_entry->token_position =
        cache_entry->inlined_token_positions[0];
  }

  intptr_t NextFreeIndex() {
    cache_cursor_ = (cache_cursor_ + 1) % kCacheSize;
    return cache_cursor_;
  }

  intptr_t OffsetForPC(uword pc,
                       const Code& code,
                       ProcessedSample* sample,
                       intptr_t frame_index) {
    intptr_t offset = pc - code.PayloadStart();
    if (frame_index != 0) {
      // The PC of frames below the top frame is a call's return address,
      // which can belong to a different inlining interval than the call.
      offset--;
    } else if (sample->IsAllocationSample()) {
      // Allocation samples skip the top frame, so the top frame's pc is
      // also a call's return address.
      offset--;
    } else if (!sample->first_frame_executing()) {
      // If the first frame wasn't executing code (i.e. we started to collect
      // the stack trace at an exit frame), the top frame's pc is also a
      // call's return address.
      offset--;
    }
    return offset;
  }

  struct CacheEntry {
    void Reset() {
      pc = 0;
      offset = 0;
      inlined_functions.Clear();
      inlined_token_positions.Clear();
    }
    uword pc;
    intptr_t offset;
    GrowableArray<const Function*> inlined_functions;
    GrowableArray<TokenPosition> inlined_token_positions;
    TokenPosition token_position;
  };

  static const intptr_t kCacheSize = 128;
  intptr_t cache_cursor_;
  intptr_t last_hit_;
  CacheEntry cache_[kCacheSize];
  intptr_t cache_miss_;
  intptr_t cache_hit_;
};

class ProfileBuilder : public ValueObject {
 public:
  enum ProfileInfoKind {
    kNone,
    kOptimized,
    kUnoptimized,
    kNative,
    kInlineStart,
    kInlineFinish,
    kNumProfileInfoKind,
  };

  ProfileBuilder(Thread* thread,
                 SampleFilter* filter,
                 SampleBuffer* sample_buffer,
                 Profile::TagOrder tag_order,
                 intptr_t extra_tags,
                 Profile* profile)
      : thread_(thread),
        vm_isolate_(Dart::vm_isolate()),
        filter_(filter),
        sample_buffer_(sample_buffer),
        tag_order_(tag_order),
        extra_tags_(extra_tags),
        profile_(profile),
        deoptimized_code_(new DeoptimizedCodeSet(thread->isolate())),
        null_code_(Code::ZoneHandle()),
        null_function_(Function::ZoneHandle()),
        tick_functions_(false),
        inclusive_tree_(false),
        samples_(NULL),
        info_kind_(kNone) {
    ASSERT((sample_buffer_ == Profiler::sample_buffer()) ||
           (sample_buffer_ == Profiler::allocation_sample_buffer()));
    ASSERT(profile_ != NULL);
  }

  void Build() {
    ScopeTimer sw("ProfileBuilder::Build", FLAG_trace_profiler);
    if (!FilterSamples()) {
      return;
    }

    Setup();
    BuildCodeTable();
    FinalizeCodeIndexes();
    BuildFunctionTable();

    BuildCodeTrie(Profile::kExclusiveCode);
    BuildCodeTrie(Profile::kInclusiveCode);

    BuildFunctionTrie(Profile::kExclusiveFunction);
    BuildFunctionTrie(Profile::kInclusiveFunction);
  }

 private:
  // Returns true if |frame_index| in |sample| is using CPU.
  static bool IsExecutingFrame(ProcessedSample* sample, intptr_t frame_index) {
    return (frame_index == 0) &&
           (sample->first_frame_executing() || sample->IsAllocationSample());
  }

  static bool IsInclusiveTrie(Profile::TrieKind kind) {
    return (kind == Profile::kInclusiveFunction) ||
           (kind == Profile::kInclusiveCode);
  }

  void Setup() {
    profile_->live_code_ = new ProfileCodeTable();
    profile_->dead_code_ = new ProfileCodeTable();
    profile_->tag_code_ = new ProfileCodeTable();
    profile_->functions_ = new ProfileFunctionTable();
    // Register some synthetic tags.
    RegisterProfileCodeTag(VMTag::kRootTagId);
    RegisterProfileCodeTag(VMTag::kTruncatedTagId);
    RegisterProfileCodeTag(VMTag::kNoneCodeTagId);
    RegisterProfileCodeTag(VMTag::kOptimizedCodeTagId);
    RegisterProfileCodeTag(VMTag::kUnoptimizedCodeTagId);
    RegisterProfileCodeTag(VMTag::kNativeCodeTagId);
    RegisterProfileCodeTag(VMTag::kInlineStartCodeTagId);
    RegisterProfileCodeTag(VMTag::kInlineEndCodeTagId);
  }

  bool FilterSamples() {
    ScopeTimer sw("ProfileBuilder::FilterSamples", FLAG_trace_profiler);
    ASSERT(sample_buffer_ != NULL);
    samples_ = sample_buffer_->BuildProcessedSampleBuffer(filter_);
    profile_->samples_ = samples_;
    profile_->sample_count_ = samples_->length();
    return true;
  }

  void UpdateMinMaxTimes(int64_t timestamp) {
    profile_->min_time_ =
        timestamp < profile_->min_time_ ? timestamp : profile_->min_time_;
    profile_->max_time_ =
        timestamp > profile_->max_time_ ? timestamp : profile_->max_time_;
  }

  void SanitizeMinMaxTimes() {
    if ((profile_->min_time_ == kMaxInt64) && (profile_->max_time_ == 0)) {
      profile_->min_time_ = 0;
      profile_->max_time_ = 0;
    }
  }

  void BuildCodeTable() {
    ScopeTimer sw("ProfileBuilder::BuildCodeTable", FLAG_trace_profiler);

    Isolate* isolate = thread_->isolate();
    ASSERT(isolate != NULL);

    // Build the live code table eagerly by populating it with code objects
    // from the processed sample buffer.
    const CodeLookupTable& code_lookup_table = samples_->code_lookup_table();
    for (intptr_t i = 0; i < code_lookup_table.length(); i++) {
      const CodeDescriptor* descriptor = code_lookup_table.At(i);
      ASSERT(descriptor != NULL);
      const Code& code = Code::Handle(descriptor->code());
      ASSERT(!code.IsNull());
      RegisterLiveProfileCode(new ProfileCode(
          ProfileCode::kDartCode, code.PayloadStart(),
          code.PayloadStart() + code.Size(), code.compile_timestamp(), code));
    }

    // Iterate over samples.
    for (intptr_t sample_index = 0; sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);
      const int64_t timestamp = sample->timestamp();

      // This is our first pass over the sample buffer, use this as an
      // opportunity to determine the min and max time ranges of this profile.
      UpdateMinMaxTimes(timestamp);

      // Make sure VM tag exists.
      if (VMTag::IsNativeEntryTag(sample->vm_tag())) {
        RegisterProfileCodeTag(VMTag::kNativeTagId);
      } else if (VMTag::IsRuntimeEntryTag(sample->vm_tag())) {
        RegisterProfileCodeTag(VMTag::kRuntimeTagId);
      }
      RegisterProfileCodeTag(sample->vm_tag());
      // Make sure user tag exists.
      RegisterProfileCodeTag(sample->user_tag());

      // Make sure that a ProfileCode objects exist for all pcs in the sample
      // and tick each one.
      for (intptr_t frame_index = 0; frame_index < sample->length();
           frame_index++) {
        const uword pc = sample->At(frame_index);
        ASSERT(pc != 0);
        ProfileCode* code = FindOrRegisterProfileCode(pc, timestamp);
        ASSERT(code != NULL);
        code->Tick(pc, IsExecutingFrame(sample, frame_index), sample_index);
      }

      TickExitFrame(sample->vm_tag(), sample_index, sample);
    }
    SanitizeMinMaxTimes();
  }

  void FinalizeCodeIndexes() {
    ScopeTimer sw("ProfileBuilder::FinalizeCodeIndexes", FLAG_trace_profiler);
    ProfileCodeTable* live_table = profile_->live_code_;
    ProfileCodeTable* dead_table = profile_->dead_code_;
    ProfileCodeTable* tag_table = profile_->tag_code_;
    const intptr_t dead_code_index_offset = live_table->length();
    const intptr_t tag_code_index_offset =
        dead_table->length() + dead_code_index_offset;

    profile_->dead_code_index_offset_ = dead_code_index_offset;
    profile_->tag_code_index_offset_ = tag_code_index_offset;

    for (intptr_t i = 0; i < live_table->length(); i++) {
      const intptr_t index = i;
      ProfileCode* code = live_table->At(i);
      ASSERT(code != NULL);
      code->set_code_table_index(index);
    }

    for (intptr_t i = 0; i < dead_table->length(); i++) {
      const intptr_t index = dead_code_index_offset + i;
      ProfileCode* code = dead_table->At(i);
      ASSERT(code != NULL);
      code->set_code_table_index(index);
    }

    for (intptr_t i = 0; i < tag_table->length(); i++) {
      const intptr_t index = tag_code_index_offset + i;
      ProfileCode* code = tag_table->At(i);
      ASSERT(code != NULL);
      code->set_code_table_index(index);
    }
  }

  void BuildFunctionTable() {
    ScopeTimer sw("ProfileBuilder::BuildFunctionTable", FLAG_trace_profiler);
    ProfileCodeTable* live_table = profile_->live_code_;
    ProfileCodeTable* dead_table = profile_->dead_code_;
    ProfileCodeTable* tag_table = profile_->tag_code_;
    ProfileFunctionTable* function_table = profile_->functions_;
    for (intptr_t i = 0; i < live_table->length(); i++) {
      ProfileCode* code = live_table->At(i);
      ASSERT(code != NULL);
      code->SetFunctionAndName(function_table);
    }

    for (intptr_t i = 0; i < dead_table->length(); i++) {
      ProfileCode* code = dead_table->At(i);
      ASSERT(code != NULL);
      code->SetFunctionAndName(function_table);
    }

    for (intptr_t i = 0; i < tag_table->length(); i++) {
      ProfileCode* code = tag_table->At(i);
      ASSERT(code != NULL);
      code->SetFunctionAndName(function_table);
    }
  }

  void BuildCodeTrie(Profile::TrieKind kind) {
    ProfileCodeTrieNode* root =
        new ProfileCodeTrieNode(GetProfileCodeTagIndex(VMTag::kRootTagId));
    inclusive_tree_ = IsInclusiveTrie(kind);
    if (inclusive_tree_) {
      BuildInclusiveCodeTrie(root);
    } else {
      BuildExclusiveCodeTrie(root);
    }
    root->SortChildren();
    profile_->roots_[static_cast<intptr_t>(kind)] = root;
  }

  void BuildInclusiveCodeTrie(ProfileCodeTrieNode* root) {
    ScopeTimer sw("ProfileBuilder::BuildInclusiveCodeTrie",
                  FLAG_trace_profiler);
    for (intptr_t sample_index = 0; sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileCodeTrieNode* current = root;
      current->Tick(sample);

      // VM & User tags.
      current =
          AppendTags(sample->vm_tag(), sample->user_tag(), current, sample);

      ResetKind();

      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current, sample);
      }

      // Walk the sampled PCs.
      Code& code = Code::Handle();
      for (intptr_t frame_index = sample->length() - 1; frame_index >= 0;
           frame_index--) {
        ASSERT(sample->At(frame_index) != 0);
        intptr_t index =
            GetProfileCodeIndex(sample->At(frame_index), sample->timestamp());
        ASSERT(index >= 0);
        ProfileCode* profile_code =
            GetProfileCode(sample->At(frame_index), sample->timestamp());
        ASSERT(profile_code->code_table_index() == index);
        code ^= profile_code->code();
        current = AppendKind(code, current, sample);
        current = current->GetChild(index);
        current->Tick(sample, (frame_index == 0));
      }

      if (!sample->first_frame_executing()) {
        current = AppendExitFrame(sample->vm_tag(), current, sample);
      }
    }
  }

  void BuildExclusiveCodeTrie(ProfileCodeTrieNode* root) {
    ScopeTimer sw("ProfileBuilder::BuildExclusiveCodeTrie",
                  FLAG_trace_profiler);
    for (intptr_t sample_index = 0; sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileCodeTrieNode* current = root;
      current->Tick(sample);
      // VM & User tags.
      current =
          AppendTags(sample->vm_tag(), sample->user_tag(), current, sample);

      ResetKind();

      if (!sample->first_frame_executing()) {
        current = AppendExitFrame(sample->vm_tag(), current, sample);
      }

      // Walk the sampled PCs.
      Code& code = Code::Handle();
      for (intptr_t frame_index = 0; frame_index < sample->length();
           frame_index++) {
        ASSERT(sample->At(frame_index) != 0);
        intptr_t index =
            GetProfileCodeIndex(sample->At(frame_index), sample->timestamp());
        ASSERT(index >= 0);
        ProfileCode* profile_code =
            GetProfileCode(sample->At(frame_index), sample->timestamp());
        ASSERT(profile_code->code_table_index() == index);
        code ^= profile_code->code();
        current = current->GetChild(index);
        if (ShouldTickNode(sample, frame_index)) {
          current->Tick(sample, (frame_index == 0));
        }
        current = AppendKind(code, current, sample);
      }
      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current, sample);
      }
    }
  }

  void BuildFunctionTrie(Profile::TrieKind kind) {
    ProfileFunctionTrieNode* root = new ProfileFunctionTrieNode(
        GetProfileFunctionTagIndex(VMTag::kRootTagId));
    // We tick the functions while building the trie, but, we don't want to do
    // it for both tries, just the exclusive trie.
    inclusive_tree_ = IsInclusiveTrie(kind);
    tick_functions_ = !inclusive_tree_;
    if (inclusive_tree_) {
      BuildInclusiveFunctionTrie(root);
    } else {
      BuildExclusiveFunctionTrie(root);
    }
    root->SortChildren();
    profile_->roots_[static_cast<intptr_t>(kind)] = root;
  }

  void BuildInclusiveFunctionTrie(ProfileFunctionTrieNode* root) {
    ScopeTimer sw("ProfileBuilder::BuildInclusiveFunctionTrie",
                  FLAG_trace_profiler);
    ASSERT(!tick_functions_);
    for (intptr_t sample_index = 0; sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileFunctionTrieNode* current = root;
      current->Tick(sample);
      // VM & User tags.
      current =
          AppendTags(sample->vm_tag(), sample->user_tag(), current, sample);

      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current, sample);
      }

      // Walk the sampled PCs.
      for (intptr_t frame_index = sample->length() - 1; frame_index >= 0;
           frame_index--) {
        ASSERT(sample->At(frame_index) != 0);
        current = ProcessFrame(current, sample_index, sample, frame_index);
      }

      if (!sample->first_frame_executing()) {
        current = AppendExitFrame(sample->vm_tag(), current, sample);
      }

      sample->set_timeline_trie(current);
    }
  }

  void BuildExclusiveFunctionTrie(ProfileFunctionTrieNode* root) {
    ScopeTimer sw("ProfileBuilder::BuildExclusiveFunctionTrie",
                  FLAG_trace_profiler);
    ASSERT(tick_functions_);
    for (intptr_t sample_index = 0; sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileFunctionTrieNode* current = root;
      current->Tick(sample);
      // VM & User tags.
      current =
          AppendTags(sample->vm_tag(), sample->user_tag(), current, sample);

      ResetKind();

      if (!sample->first_frame_executing()) {
        current = AppendExitFrame(sample->vm_tag(), current, sample);
      }

      // Walk the sampled PCs.
      for (intptr_t frame_index = 0; frame_index < sample->length();
           frame_index++) {
        ASSERT(sample->At(frame_index) != 0);
        current = ProcessFrame(current, sample_index, sample, frame_index);
      }

      TickExitFrameFunction(sample->vm_tag(), sample_index);

      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current, sample);
        InclusiveTickTruncatedTag(sample);
      }
    }
  }

  ProfileFunctionTrieNode* ProcessFrame(ProfileFunctionTrieNode* current,
                                        intptr_t sample_index,
                                        ProcessedSample* sample,
                                        intptr_t frame_index) {
    const uword pc = sample->At(frame_index);
    ProfileCode* profile_code = GetProfileCode(pc, sample->timestamp());
    ProfileFunction* function = profile_code->function();
    ASSERT(function != NULL);
    const intptr_t code_index = profile_code->code_table_index();
    ASSERT(profile_code != NULL);
    const Code& code = Code::ZoneHandle(profile_code->code());
    GrowableArray<const Function*>* inlined_functions = NULL;
    GrowableArray<TokenPosition>* inlined_token_positions = NULL;
    TokenPosition token_position = TokenPosition::kNoSource;
    if (!code.IsNull()) {
      inlined_functions_cache_.Get(pc, code, sample, frame_index,
                                   &inlined_functions, &inlined_token_positions,
                                   &token_position);
      if (FLAG_trace_profiler_verbose) {
        for (intptr_t i = 0; i < inlined_functions->length(); i++) {
          const String& name =
              String::Handle((*inlined_functions)[i]->QualifiedScrubbedName());
          THR_Print("InlinedFunction[%" Pd "] = {%s, %s}\n", i,
                    name.ToCString(),
                    (*inlined_token_positions)[i].ToCString());
        }
      }
    }

    if (code.IsNull() || (inlined_functions == NULL) ||
        (inlined_functions->length() <= 1)) {
      // No inlined functions.
      if (inclusive_tree_) {
        current = AppendKind(code, current, sample);
      }
      current = ProcessFunction(current, sample_index, sample, frame_index,
                                function, token_position, code_index);
      if (!inclusive_tree_) {
        current = AppendKind(code, current, sample);
      }
      return current;
    }

    if (!code.is_optimized()) {
      OS::PrintErr("Code that should be optimized is not. Please file a bug\n");
      OS::PrintErr("Code object: %s\n", code.ToCString());
      OS::PrintErr("Inlined functions length: %" Pd "\n",
                   inlined_functions->length());
      for (intptr_t i = 0; i < inlined_functions->length(); i++) {
        OS::PrintErr("IF[%" Pd "] = %s\n", i,
                     (*inlined_functions)[i]->ToFullyQualifiedCString());
      }
    }

    ASSERT(code.is_optimized());

    if (inclusive_tree_) {
      for (intptr_t i = 0; i < inlined_functions->length(); i++) {
        const Function* inlined_function = (*inlined_functions)[i];
        ASSERT(inlined_function != NULL);
        ASSERT(!inlined_function->IsNull());
        TokenPosition inlined_token_position = (*inlined_token_positions)[i];
        const bool inliner = i == 0;
        if (inliner) {
          current = AppendKind(code, current, sample);
        }
        current = ProcessInlinedFunction(current, sample_index, sample,
                                         frame_index, inlined_function,
                                         inlined_token_position, code_index);
        if (inliner) {
          current = AppendKind(kInlineStart, current, sample);
        }
      }
      current = AppendKind(kInlineFinish, current, sample);
    } else {
      // Append the inlined children.
      current = AppendKind(kInlineFinish, current, sample);
      for (intptr_t i = inlined_functions->length() - 1; i >= 0; i--) {
        const Function* inlined_function = (*inlined_functions)[i];
        ASSERT(inlined_function != NULL);
        ASSERT(!inlined_function->IsNull());
        TokenPosition inlined_token_position = (*inlined_token_positions)[i];
        const bool inliner = i == 0;
        if (inliner) {
          current = AppendKind(kInlineStart, current, sample);
        }
        current = ProcessInlinedFunction(current, sample_index, sample,
                                         frame_index + i, inlined_function,
                                         inlined_token_position, code_index);
        if (inliner) {
          current = AppendKind(code, current, sample);
        }
      }
    }

    return current;
  }

  ProfileFunctionTrieNode* ProcessInlinedFunction(
      ProfileFunctionTrieNode* current,
      intptr_t sample_index,
      ProcessedSample* sample,
      intptr_t frame_index,
      const Function* inlined_function,
      TokenPosition inlined_token_position,
      intptr_t code_index) {
    ProfileFunctionTable* function_table = profile_->functions_;
    ProfileFunction* function = function_table->LookupOrAdd(*inlined_function);
    ASSERT(function != NULL);
    return ProcessFunction(current, sample_index, sample, frame_index, function,
                           inlined_token_position, code_index);
  }

  bool ShouldTickNode(ProcessedSample* sample, intptr_t frame_index) {
    if (frame_index != 0) {
      return true;
    }
    // Only tick the first frame's node, if we are executing OR
    // vm tags have been emitted.
    return IsExecutingFrame(sample, frame_index) || !FLAG_profile_vm ||
           vm_tags_emitted();
  }

  ProfileFunctionTrieNode* ProcessFunction(ProfileFunctionTrieNode* current,
                                           intptr_t sample_index,
                                           ProcessedSample* sample,
                                           intptr_t frame_index,
                                           ProfileFunction* function,
                                           TokenPosition token_position,
                                           intptr_t code_index) {
    if (!function->is_visible()) {
      return current;
    }
    if (tick_functions_) {
      if (FLAG_trace_profiler_verbose) {
        THR_Print("S[%" Pd "]F[%" Pd "] %s %s 0x%" Px "\n", sample_index,
                  frame_index, function->Name(), token_position.ToCString(),
                  sample->At(frame_index));
      }
      function->Tick(IsExecutingFrame(sample, frame_index), sample_index,
                     token_position);
    }
    function->AddProfileCode(code_index);
    current = current->GetChild(function->table_index());
    if (ShouldTickNode(sample, frame_index)) {
      current->Tick(sample, (frame_index == 0));
    }
    current->AddCodeObjectIndex(code_index);
    return current;
  }

  // Tick the truncated tag's inclusive tick count.
  void InclusiveTickTruncatedTag(ProcessedSample* sample) {
    ProfileCodeTable* tag_table = profile_->tag_code_;
    intptr_t index = tag_table->FindCodeIndexForPC(VMTag::kTruncatedTagId);
    ASSERT(index >= 0);
    ProfileCode* code = tag_table->At(index);
    code->IncInclusiveTicks();
    ASSERT(code != NULL);
    ProfileFunction* function = code->function();
    function->IncInclusiveTicks();
  }

  // Tag append functions are overloaded for |ProfileCodeTrieNode| and
  // |ProfileFunctionTrieNode| types.

  // ProfileCodeTrieNode
  ProfileCodeTrieNode* AppendUserTag(uword user_tag,
                                     ProfileCodeTrieNode* current,
                                     ProcessedSample* sample) {
    intptr_t user_tag_index = GetProfileCodeTagIndex(user_tag);
    if (user_tag_index >= 0) {
      current = current->GetChild(user_tag_index);
      current->Tick(sample);
    }
    return current;
  }

  ProfileCodeTrieNode* AppendTruncatedTag(ProfileCodeTrieNode* current,
                                          ProcessedSample* sample) {
    intptr_t truncated_tag_index =
        GetProfileCodeTagIndex(VMTag::kTruncatedTagId);
    ASSERT(truncated_tag_index >= 0);
    current = current->GetChild(truncated_tag_index);
    current->Tick(sample);
    return current;
  }

  ProfileCodeTrieNode* AppendVMTag(uword vm_tag,
                                   ProfileCodeTrieNode* current,
                                   ProcessedSample* sample) {
    if (VMTag::IsNativeEntryTag(vm_tag)) {
      // Insert a dummy kNativeTagId node.
      intptr_t tag_index = GetProfileCodeTagIndex(VMTag::kNativeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    } else if (VMTag::IsRuntimeEntryTag(vm_tag)) {
      // Insert a dummy kRuntimeTagId node.
      intptr_t tag_index = GetProfileCodeTagIndex(VMTag::kRuntimeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    } else {
      intptr_t tag_index = GetProfileCodeTagIndex(vm_tag);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    }
    return current;
  }

  ProfileCodeTrieNode* AppendSpecificNativeRuntimeEntryVMTag(
      uword vm_tag,
      ProfileCodeTrieNode* current,
      ProcessedSample* sample) {
    // Only Native and Runtime entries have a second VM tag.
    if (!VMTag::IsNativeEntryTag(vm_tag) && !VMTag::IsRuntimeEntryTag(vm_tag)) {
      return current;
    }
    intptr_t tag_index = GetProfileCodeTagIndex(vm_tag);
    current = current->GetChild(tag_index);
    // Give the tag a tick.
    current->Tick(sample);
    return current;
  }

  uword ProfileInfoKindToVMTag(ProfileInfoKind kind) {
    switch (kind) {
      case kNone:
        return VMTag::kNoneCodeTagId;
      case kOptimized:
        return VMTag::kOptimizedCodeTagId;
      case kUnoptimized:
        return VMTag::kUnoptimizedCodeTagId;
      case kNative:
        return VMTag::kNativeCodeTagId;
      case kInlineStart:
        return VMTag::kInlineStartCodeTagId;
      case kInlineFinish:
        return VMTag::kInlineEndCodeTagId;
      default:
        UNIMPLEMENTED();
        return VMTag::kInvalidTagId;
    }
  }

  ProfileCodeTrieNode* AppendKind(ProfileInfoKind kind,
                                  ProfileCodeTrieNode* current,
                                  ProcessedSample* sample) {
    if (!TagsEnabled(ProfilerService::kCodeTransitionTagsBit)) {
      // Only emit if debug tags are requested.
      return current;
    }
    if (kind != info_kind_) {
      info_kind_ = kind;
      intptr_t tag_index = GetProfileCodeTagIndex(ProfileInfoKindToVMTag(kind));
      ASSERT(tag_index >= 0);
      current = current->GetChild(tag_index);
      current->Tick(sample);
    }
    return current;
  }

  ProfileCodeTrieNode* AppendKind(const Code& code,
                                  ProfileCodeTrieNode* current,
                                  ProcessedSample* sample) {
    if (code.IsNull()) {
      return AppendKind(kNone, current, sample);
    } else if (code.is_optimized()) {
      return AppendKind(kOptimized, current, sample);
    } else {
      return AppendKind(kUnoptimized, current, sample);
    }
  }

  ProfileCodeTrieNode* AppendVMTags(uword vm_tag,
                                    ProfileCodeTrieNode* current,
                                    ProcessedSample* sample) {
    current = AppendVMTag(vm_tag, current, sample);
    current = AppendSpecificNativeRuntimeEntryVMTag(vm_tag, current, sample);
    return current;
  }

  void TickExitFrame(uword vm_tag, intptr_t serial, ProcessedSample* sample) {
    if (FLAG_profile_vm) {
      return;
    }
    if (!VMTag::IsExitFrameTag(vm_tag)) {
      return;
    }
    ProfileCodeTable* tag_table = profile_->tag_code_;
    ProfileCode* code = tag_table->FindCodeForPC(vm_tag);
    ASSERT(code != NULL);
    code->Tick(vm_tag, true, serial);
  }

  void TickExitFrameFunction(uword vm_tag, intptr_t serial) {
    if (FLAG_profile_vm) {
      return;
    }
    if (!VMTag::IsExitFrameTag(vm_tag)) {
      return;
    }
    ProfileCodeTable* tag_table = profile_->tag_code_;
    ProfileCode* code = tag_table->FindCodeForPC(vm_tag);
    ASSERT(code != NULL);
    ProfileFunction* function = code->function();
    ASSERT(function != NULL);
    function->Tick(true, serial, TokenPosition::kNoSource);
  }

  ProfileCodeTrieNode* AppendExitFrame(uword vm_tag,
                                       ProfileCodeTrieNode* current,
                                       ProcessedSample* sample) {
    if (FLAG_profile_vm) {
      return current;
    }

    if (!VMTag::IsExitFrameTag(vm_tag)) {
      return current;
    }

    if (VMTag::IsNativeEntryTag(vm_tag) || VMTag::IsRuntimeEntryTag(vm_tag)) {
      current = AppendSpecificNativeRuntimeEntryVMTag(vm_tag, current, sample);
    } else {
      intptr_t tag_index = GetProfileCodeTagIndex(vm_tag);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    }
    return current;
  }

  ProfileCodeTrieNode* AppendTags(uword vm_tag,
                                  uword user_tag,
                                  ProfileCodeTrieNode* current,
                                  ProcessedSample* sample) {
    if (FLAG_profile_vm) {
      // None.
      if (tag_order() == Profile::kNoTags) {
        return current;
      }
      // User first.
      if ((tag_order() == Profile::kUserVM) ||
          (tag_order() == Profile::kUser)) {
        current = AppendUserTag(user_tag, current, sample);
        // Only user.
        if (tag_order() == Profile::kUser) {
          return current;
        }
        return AppendVMTags(vm_tag, current, sample);
      }
      // VM first.
      ASSERT((tag_order() == Profile::kVMUser) ||
             (tag_order() == Profile::kVM));
      current = AppendVMTags(vm_tag, current, sample);
      // Only VM.
      if (tag_order() == Profile::kVM) {
        return current;
      }
      return AppendUserTag(user_tag, current, sample);
    }

    if (tag_order() == Profile::kNoTags) {
      return current;
    }

    return AppendUserTag(user_tag, current, sample);
  }

  // ProfileFunctionTrieNode
  void ResetKind() { info_kind_ = kNone; }

  ProfileFunctionTrieNode* AppendKind(ProfileInfoKind kind,
                                      ProfileFunctionTrieNode* current,
                                      ProcessedSample* sample) {
    if (!TagsEnabled(ProfilerService::kCodeTransitionTagsBit)) {
      // Only emit if debug tags are requested.
      return current;
    }
    if (kind != info_kind_) {
      info_kind_ = kind;
      intptr_t tag_index =
          GetProfileFunctionTagIndex(ProfileInfoKindToVMTag(kind));
      ASSERT(tag_index >= 0);
      current = current->GetChild(tag_index);
      current->Tick(sample);
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendKind(const Code& code,
                                      ProfileFunctionTrieNode* current,
                                      ProcessedSample* sample) {
    if (code.IsNull()) {
      return AppendKind(kNone, current, sample);
    } else if (code.is_optimized()) {
      return AppendKind(kOptimized, current, sample);
    } else {
      return AppendKind(kUnoptimized, current, sample);
    }
  }

  ProfileFunctionTrieNode* AppendUserTag(uword user_tag,
                                         ProfileFunctionTrieNode* current,
                                         ProcessedSample* sample) {
    intptr_t user_tag_index = GetProfileFunctionTagIndex(user_tag);
    if (user_tag_index >= 0) {
      current = current->GetChild(user_tag_index);
      current->Tick(sample);
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendTruncatedTag(ProfileFunctionTrieNode* current,
                                              ProcessedSample* sample) {
    intptr_t truncated_tag_index =
        GetProfileFunctionTagIndex(VMTag::kTruncatedTagId);
    ASSERT(truncated_tag_index >= 0);
    current = current->GetChild(truncated_tag_index);
    current->Tick(sample);
    return current;
  }

  ProfileFunctionTrieNode* AppendVMTag(uword vm_tag,
                                       ProfileFunctionTrieNode* current,
                                       ProcessedSample* sample) {
    if (VMTag::IsNativeEntryTag(vm_tag)) {
      // Insert a dummy kNativeTagId node.
      intptr_t tag_index = GetProfileFunctionTagIndex(VMTag::kNativeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    } else if (VMTag::IsRuntimeEntryTag(vm_tag)) {
      // Insert a dummy kRuntimeTagId node.
      intptr_t tag_index = GetProfileFunctionTagIndex(VMTag::kRuntimeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    } else {
      intptr_t tag_index = GetProfileFunctionTagIndex(vm_tag);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendSpecificNativeRuntimeEntryVMTag(
      uword vm_tag,
      ProfileFunctionTrieNode* current,
      ProcessedSample* sample) {
    // Only Native and Runtime entries have a second VM tag.
    if (!VMTag::IsNativeEntryTag(vm_tag) && !VMTag::IsRuntimeEntryTag(vm_tag)) {
      return current;
    }
    intptr_t tag_index = GetProfileFunctionTagIndex(vm_tag);
    current = current->GetChild(tag_index);
    // Give the tag a tick.
    current->Tick(sample);
    return current;
  }

  ProfileFunctionTrieNode* AppendVMTags(uword vm_tag,
                                        ProfileFunctionTrieNode* current,
                                        ProcessedSample* sample) {
    current = AppendVMTag(vm_tag, current, sample);
    current = AppendSpecificNativeRuntimeEntryVMTag(vm_tag, current, sample);
    return current;
  }

  ProfileFunctionTrieNode* AppendExitFrame(uword vm_tag,
                                           ProfileFunctionTrieNode* current,
                                           ProcessedSample* sample) {
    if (FLAG_profile_vm) {
      return current;
    }

    if (!VMTag::IsExitFrameTag(vm_tag)) {
      return current;
    }
    if (VMTag::IsNativeEntryTag(vm_tag) || VMTag::IsRuntimeEntryTag(vm_tag)) {
      current = AppendSpecificNativeRuntimeEntryVMTag(vm_tag, current, sample);
    } else {
      intptr_t tag_index = GetProfileFunctionTagIndex(vm_tag);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick(sample);
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendTags(uword vm_tag,
                                      uword user_tag,
                                      ProfileFunctionTrieNode* current,
                                      ProcessedSample* sample) {
    if (FLAG_profile_vm) {
      // None.
      if (tag_order() == Profile::kNoTags) {
        return current;
      }
      // User first.
      if ((tag_order() == Profile::kUserVM) ||
          (tag_order() == Profile::kUser)) {
        current = AppendUserTag(user_tag, current, sample);
        // Only user.
        if (tag_order() == Profile::kUser) {
          return current;
        }
        return AppendVMTags(vm_tag, current, sample);
      }
      // VM first.
      ASSERT((tag_order() == Profile::kVMUser) ||
             (tag_order() == Profile::kVM));
      current = AppendVMTags(vm_tag, current, sample);
      // Only VM.
      if (tag_order() == Profile::kVM) {
        return current;
      }
      return AppendUserTag(user_tag, current, sample);
    }

    if (tag_order() == Profile::kNoTags) {
      return current;
    }

    return AppendUserTag(user_tag, current, sample);
  }

  intptr_t GetProfileCodeTagIndex(uword tag) {
    ProfileCodeTable* tag_table = profile_->tag_code_;
    intptr_t index = tag_table->FindCodeIndexForPC(tag);
    ASSERT(index >= 0);
    ProfileCode* code = tag_table->At(index);
    ASSERT(code != NULL);
    return code->code_table_index();
  }

  intptr_t GetProfileFunctionTagIndex(uword tag) {
    ProfileCodeTable* tag_table = profile_->tag_code_;
    intptr_t index = tag_table->FindCodeIndexForPC(tag);
    ASSERT(index >= 0);
    ProfileCode* code = tag_table->At(index);
    ASSERT(code != NULL);
    ProfileFunction* function = code->function();
    ASSERT(function != NULL);
    return function->table_index();
  }

  intptr_t GetProfileCodeIndex(uword pc, int64_t timestamp) {
    return GetProfileCode(pc, timestamp)->code_table_index();
  }

  ProfileCode* GetProfileCode(uword pc, int64_t timestamp) {
    ProfileCodeTable* live_table = profile_->live_code_;
    ProfileCodeTable* dead_table = profile_->dead_code_;

    intptr_t index = live_table->FindCodeIndexForPC(pc);
    ProfileCode* code = NULL;
    if (index < 0) {
      index = dead_table->FindCodeIndexForPC(pc);
      ASSERT(index >= 0);
      code = dead_table->At(index);
    } else {
      code = live_table->At(index);
      ASSERT(code != NULL);
      if (code->compile_timestamp() > timestamp) {
        // Code is newer than sample. Fall back to dead code table.
        index = dead_table->FindCodeIndexForPC(pc);
        ASSERT(index >= 0);
        code = dead_table->At(index);
      }
    }

    ASSERT(code != NULL);
    ASSERT(code->Contains(pc));
    ASSERT(code->compile_timestamp() <= timestamp);
    return code;
  }

  void RegisterProfileCodeTag(uword tag) {
    if (tag == 0) {
      // No tag.
      return;
    }
    ProfileCodeTable* tag_table = profile_->tag_code_;
    intptr_t index = tag_table->FindCodeIndexForPC(tag);
    if (index >= 0) {
      // Already created.
      return;
    }
    ProfileCode* code =
        new ProfileCode(ProfileCode::kTagCode, tag, tag + 1, 0, null_code_);
    index = tag_table->InsertCode(code);
    ASSERT(index >= 0);
  }

  ProfileCode* CreateProfileCodeReused(uword pc) {
    ProfileCode* code =
        new ProfileCode(ProfileCode::kReusedCode, pc, pc + 1, 0, null_code_);
    return code;
  }

  bool IsPCInDartHeap(uword pc) {
    return vm_isolate_->heap()->CodeContains(pc) ||
           thread_->isolate()->heap()->CodeContains(pc);
  }

  ProfileCode* FindOrRegisterNativeProfileCode(uword pc) {
    // Check if |pc| is already known in the live code table.
    ProfileCodeTable* live_table = profile_->live_code_;
    ProfileCode* profile_code = live_table->FindCodeForPC(pc);
    if (profile_code != NULL) {
      return profile_code;
    }

    // We haven't seen this pc yet.
    Code& code = Code::Handle(thread_->zone());

    // Check NativeSymbolResolver for pc.
    uintptr_t native_start = 0;
    char* native_name =
        NativeSymbolResolver::LookupSymbolName(pc, &native_start);
    if (native_name == NULL) {
      // Failed to find a native symbol for pc.
      native_start = pc;
    }

#if defined(HOST_ARCH_ARM)
    // The symbol for a Thumb function will be xxx1, but we may have samples
    // at function entry which will have pc xxx0.
    native_start &= ~1;
#endif

    if (native_start > pc) {
      // Bogus lookup result.
      if (native_name != NULL) {
        NativeSymbolResolver::FreeSymbolName(native_name);
        native_name = NULL;
      }
      native_start = pc;
    }
    if ((pc - native_start) > (32 * KB)) {
      // Suspect lookup result. More likely dladdr going off the rails than a
      // jumbo function.
      if (native_name != NULL) {
        NativeSymbolResolver::FreeSymbolName(native_name);
        native_name = NULL;
      }
      native_start = pc;
    }

    ASSERT(pc >= native_start);
    profile_code = new ProfileCode(ProfileCode::kNativeCode, native_start,
                                   pc + 1, 0, code);
    if (native_name != NULL) {
      profile_code->SetName(native_name);
      NativeSymbolResolver::FreeSymbolName(native_name);
    }

    RegisterLiveProfileCode(profile_code);
    return profile_code;
  }

  void RegisterLiveProfileCode(ProfileCode* code) {
    ProfileCodeTable* live_table = profile_->live_code_;
    intptr_t index = live_table->InsertCode(code);
    ASSERT(index >= 0);
  }

  ProfileCode* FindOrRegisterDeadProfileCode(uword pc) {
    ProfileCodeTable* dead_table = profile_->dead_code_;

    ProfileCode* code = dead_table->FindCodeForPC(pc);
    if (code != NULL) {
      return code;
    }

    // Create a new dead code entry.
    intptr_t index = dead_table->InsertCode(CreateProfileCodeReused(pc));
    ASSERT(index >= 0);
    return dead_table->At(index);
  }

  ProfileCode* FindOrRegisterProfileCode(uword pc, int64_t timestamp) {
    ProfileCodeTable* live_table = profile_->live_code_;
    ProfileCode* code = live_table->FindCodeForPC(pc);
    if ((code != NULL) && (code->compile_timestamp() <= timestamp)) {
      // Code was compiled before sample was taken.
      return code;
    }
    if ((code == NULL) && !IsPCInDartHeap(pc)) {
      // Not a PC from Dart code. Check with native code.
      return FindOrRegisterNativeProfileCode(pc);
    }
    // We either didn't find the code or it was compiled after the sample.
    return FindOrRegisterDeadProfileCode(pc);
  }

  Profile::TagOrder tag_order() const { return tag_order_; }

  bool vm_tags_emitted() const {
    return (tag_order_ == Profile::kUserVM) ||
           (tag_order_ == Profile::kVMUser) || (tag_order_ == Profile::kVM);
  }

  bool TagsEnabled(intptr_t extra_tags_bits) const {
    return (extra_tags_ & extra_tags_bits) != 0;
  }

  Thread* thread_;
  Isolate* vm_isolate_;
  SampleFilter* filter_;
  SampleBuffer* sample_buffer_;
  Profile::TagOrder tag_order_;
  intptr_t extra_tags_;
  Profile* profile_;
  DeoptimizedCodeSet* deoptimized_code_;
  const Code& null_code_;
  const Function& null_function_;
  bool tick_functions_;
  bool inclusive_tree_;
  ProfileCodeInlinedFunctionsCache inlined_functions_cache_;
  ProcessedSampleBuffer* samples_;
  ProfileInfoKind info_kind_;
};  // ProfileBuilder.

Profile::Profile(Isolate* isolate)
    : isolate_(isolate),
      zone_(Thread::Current()->zone()),
      samples_(NULL),
      live_code_(NULL),
      dead_code_(NULL),
      tag_code_(NULL),
      functions_(NULL),
      dead_code_index_offset_(-1),
      tag_code_index_offset_(-1),
      min_time_(kMaxInt64),
      max_time_(0) {
  ASSERT(isolate_ != NULL);
  for (intptr_t i = 0; i < kNumTrieKinds; i++) {
    roots_[i] = NULL;
  }
}

void Profile::Build(Thread* thread,
                    SampleFilter* filter,
                    SampleBuffer* sample_buffer,
                    TagOrder tag_order,
                    intptr_t extra_tags) {
  ProfileBuilder builder(thread, filter, sample_buffer, tag_order, extra_tags,
                         this);
  builder.Build();
}

intptr_t Profile::NumFunctions() const {
  return functions_->length();
}

ProfileFunction* Profile::GetFunction(intptr_t index) {
  ASSERT(functions_ != NULL);
  return functions_->At(index);
}

ProfileCode* Profile::GetCode(intptr_t index) {
  ASSERT(live_code_ != NULL);
  ASSERT(dead_code_ != NULL);
  ASSERT(tag_code_ != NULL);
  ASSERT(dead_code_index_offset_ >= 0);
  ASSERT(tag_code_index_offset_ >= 0);

  // Code indexes span three arrays.
  //           0 ... |live_code|
  // |live_code| ... |dead_code|
  // |dead_code| ... |tag_code|

  if (index < dead_code_index_offset_) {
    return live_code_->At(index);
  }

  if (index < tag_code_index_offset_) {
    index -= dead_code_index_offset_;
    return dead_code_->At(index);
  }

  index -= tag_code_index_offset_;
  return tag_code_->At(index);
}

ProfileTrieNode* Profile::GetTrieRoot(TrieKind trie_kind) {
  return roots_[static_cast<intptr_t>(trie_kind)];
}

void Profile::PrintHeaderJSON(JSONObject* obj) {
  obj->AddProperty("samplePeriod", static_cast<intptr_t>(FLAG_profile_period));
  obj->AddProperty("stackDepth", static_cast<intptr_t>(FLAG_max_profile_depth));
  obj->AddProperty("sampleCount", sample_count());
  obj->AddProperty("timeSpan", MicrosecondsToSeconds(GetTimeSpan()));
  obj->AddPropertyTimeMicros("timeOriginMicros", min_time());
  obj->AddPropertyTimeMicros("timeExtentMicros", GetTimeSpan());

  ProfilerCounters counters = Profiler::counters();
  {
    JSONObject counts(obj, "counters");
    counts.AddProperty64("bail_out_unknown_task",
                         counters.bail_out_unknown_task);
    counts.AddProperty64("bail_out_jump_to_exception_handler",
                         counters.bail_out_jump_to_exception_handler);
    counts.AddProperty64("bail_out_check_isolate",
                         counters.bail_out_check_isolate);
    counts.AddProperty64("single_frame_sample_deoptimizing",
                         counters.single_frame_sample_deoptimizing);
    counts.AddProperty64("single_frame_sample_register_check",
                         counters.single_frame_sample_register_check);
    counts.AddProperty64(
        "single_frame_sample_get_and_validate_stack_bounds",
        counters.single_frame_sample_get_and_validate_stack_bounds);
    counts.AddProperty64("stack_walker_native", counters.stack_walker_native);
    counts.AddProperty64("stack_walker_dart_exit",
                         counters.stack_walker_dart_exit);
    counts.AddProperty64("stack_walker_dart", counters.stack_walker_dart);
    counts.AddProperty64("stack_walker_none", counters.stack_walker_none);
  }
}

void Profile::PrintTimelineFrameJSON(JSONObject* frames,
                                     ProfileTrieNode* current,
                                     ProfileTrieNode* parent,
                                     intptr_t* next_id) {
  ASSERT(current->frame_id() == -1);
  const intptr_t id = *next_id;
  *next_id = id + 1;
  current->set_frame_id(id);
  ASSERT(current->frame_id() != -1);

  {
    // The samples from many isolates may be merged into a single timeline,
    // so prefix frames id with the isolate.
    intptr_t isolate_id = reinterpret_cast<intptr_t>(isolate_);
    const char* key =
        zone_->PrintToString("%" Pd "-%" Pd, isolate_id, current->frame_id());
    JSONObject frame(frames, key);
    frame.AddProperty("category", "Dart");
    ProfileFunction* func = GetFunction(current->table_index());
    frame.AddProperty("name", func->Name());
    if (parent != NULL) {
      ASSERT(parent->frame_id() != -1);
      frame.AddPropertyF("parent", "%" Pd "-%" Pd, isolate_id,
                         parent->frame_id());
    }
  }

  for (intptr_t i = 0; i < current->NumChildren(); i++) {
    ProfileTrieNode* child = current->At(i);
    PrintTimelineFrameJSON(frames, child, current, next_id);
  }
}

void Profile::PrintTimelineJSON(JSONStream* stream) {
  ScopeTimer sw("Profile::PrintTimelineJSON", FLAG_trace_profiler);
  JSONObject obj(stream);
  obj.AddProperty("type", "_CpuProfileTimeline");
  PrintHeaderJSON(&obj);
  {
    JSONObject frames(&obj, "stackFrames");
    ProfileTrieNode* root = GetTrieRoot(kInclusiveFunction);
    intptr_t next_id = 0;
    PrintTimelineFrameJSON(&frames, root, NULL, &next_id);
  }
  {
    JSONArray events(&obj, "traceEvents");
    intptr_t pid = OS::ProcessId();
    intptr_t isolate_id = reinterpret_cast<intptr_t>(isolate_);
    for (intptr_t sample_index = 0; sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);
      JSONObject event(&events);
      event.AddProperty("ph", "P");  // kind = sample event
      // Add a blank name to keep about:tracing happy.
      event.AddProperty("name", "");
      event.AddProperty64("pid", pid);
      event.AddProperty64("tid", OSThread::ThreadIdToIntPtr(sample->tid()));
      event.AddPropertyTimeMicros("ts", sample->timestamp());
      event.AddProperty("cat", "Dart");
      if (!Isolate::IsVMInternalIsolate(isolate_)) {
        JSONObject args(&event, "args");
        args.AddProperty("mode", "basic");
      }

      ProfileTrieNode* trie = sample->timeline_trie();
      ASSERT(trie->frame_id() != -1);
      event.AddPropertyF("sf", "%" Pd "-%" Pd, isolate_id, trie->frame_id());
    }
  }
}

ProfileFunction* Profile::FindFunction(const Function& function) {
  return (functions_ != NULL) ? functions_->Lookup(function) : NULL;
}

void Profile::PrintProfileJSON(JSONStream* stream) {
  ScopeTimer sw("Profile::PrintProfileJSON", FLAG_trace_profiler);
  JSONObject obj(stream);
  obj.AddProperty("type", "_CpuProfile");
  PrintHeaderJSON(&obj);
  {
    JSONArray codes(&obj, "codes");
    for (intptr_t i = 0; i < live_code_->length(); i++) {
      ProfileCode* code = live_code_->At(i);
      ASSERT(code != NULL);
      code->PrintToJSONArray(&codes);
    }
    for (intptr_t i = 0; i < dead_code_->length(); i++) {
      ProfileCode* code = dead_code_->At(i);
      ASSERT(code != NULL);
      code->PrintToJSONArray(&codes);
    }
    for (intptr_t i = 0; i < tag_code_->length(); i++) {
      ProfileCode* code = tag_code_->At(i);
      ASSERT(code != NULL);
      code->PrintToJSONArray(&codes);
    }
  }

  {
    JSONArray functions(&obj, "functions");
    for (intptr_t i = 0; i < functions_->length(); i++) {
      ProfileFunction* function = functions_->At(i);
      ASSERT(function != NULL);
      function->PrintToJSONArray(&functions);
    }
  }
  {
    JSONArray code_trie(&obj, "exclusiveCodeTrie");
    ProfileTrieNode* root = roots_[static_cast<intptr_t>(kExclusiveCode)];
    ASSERT(root != NULL);
    root->PrintToJSONArray(&code_trie);
  }
  {
    JSONArray code_trie(&obj, "inclusiveCodeTrie");
    ProfileTrieNode* root = roots_[static_cast<intptr_t>(kInclusiveCode)];
    ASSERT(root != NULL);
    root->PrintToJSONArray(&code_trie);
  }
  {
    JSONArray function_trie(&obj, "exclusiveFunctionTrie");
    ProfileTrieNode* root = roots_[static_cast<intptr_t>(kExclusiveFunction)];
    ASSERT(root != NULL);
    root->PrintToJSONArray(&function_trie);
  }
  {
    JSONArray function_trie(&obj, "inclusiveFunctionTrie");
    ProfileTrieNode* root = roots_[static_cast<intptr_t>(kInclusiveFunction)];
    ASSERT(root != NULL);
    root->PrintToJSONArray(&function_trie);
  }
}

void ProfileTrieWalker::Reset(Profile::TrieKind trie_kind) {
  code_trie_ = Profile::IsCodeTrie(trie_kind);
  parent_ = NULL;
  current_ = profile_->GetTrieRoot(trie_kind);
  ASSERT(current_ != NULL);
}

const char* ProfileTrieWalker::CurrentName() {
  if (current_ == NULL) {
    return NULL;
  }
  if (code_trie_) {
    ProfileCode* code = profile_->GetCode(current_->table_index());
    return code->name();
  } else {
    ProfileFunction* func = profile_->GetFunction(current_->table_index());
    return func->Name();
  }
  UNREACHABLE();
  return NULL;
}

intptr_t ProfileTrieWalker::CurrentNodeTickCount() {
  if (current_ == NULL) {
    return -1;
  }
  return current_->count();
}

intptr_t ProfileTrieWalker::CurrentInclusiveTicks() {
  if (current_ == NULL) {
    return -1;
  }
  if (code_trie_) {
    ProfileCode* code = profile_->GetCode(current_->table_index());
    return code->inclusive_ticks();
  } else {
    ProfileFunction* func = profile_->GetFunction(current_->table_index());
    return func->inclusive_ticks();
  }
  UNREACHABLE();
  return -1;
}

intptr_t ProfileTrieWalker::CurrentExclusiveTicks() {
  if (current_ == NULL) {
    return -1;
  }
  if (code_trie_) {
    ProfileCode* code = profile_->GetCode(current_->table_index());
    return code->exclusive_ticks();
  } else {
    ProfileFunction* func = profile_->GetFunction(current_->table_index());
    return func->exclusive_ticks();
  }
  UNREACHABLE();
  return -1;
}

intptr_t ProfileTrieWalker::CurrentInclusiveAllocations() {
  if (current_ == NULL) {
    return -1;
  }
  return current_->inclusive_allocations();
}

intptr_t ProfileTrieWalker::CurrentExclusiveAllocations() {
  if (current_ == NULL) {
    return -1;
  }
  return current_->exclusive_allocations();
}

const char* ProfileTrieWalker::CurrentToken() {
  if (current_ == NULL) {
    return NULL;
  }
  if (code_trie_) {
    return NULL;
  }
  ProfileFunction* func = profile_->GetFunction(current_->table_index());
  const Function& function = *(func->function());
  if (function.IsNull()) {
    // No function.
    return NULL;
  }
  Zone* zone = Thread::Current()->zone();
  const Script& script = Script::Handle(zone, function.script());
  if (script.IsNull()) {
    // No script.
    return NULL;
  }
  ProfileFunctionSourcePosition pfsp(TokenPosition::kNoSource);
  if (!func->GetSinglePosition(&pfsp)) {
    // Not exactly one source position.
    return NULL;
  }
  TokenPosition token_pos = pfsp.token_pos();
  if (!token_pos.IsSourcePosition()) {
    // Not a location in a script.
    return NULL;
  }
  if (token_pos.IsSynthetic()) {
    token_pos = token_pos.FromSynthetic();
  }

  String& str = String::Handle(zone);
  if (script.kind() == RawScript::kKernelTag) {
    intptr_t line = 0, column = 0, token_len = 0;
    script.GetTokenLocation(token_pos, &line, &column, &token_len);
    str = script.GetSnippet(line, column, line, column + token_len);
  } else {
    const TokenStream& token_stream =
        TokenStream::Handle(zone, script.tokens());
    if (token_stream.IsNull()) {
      // No token position.
      return NULL;
    }
    TokenStream::Iterator iterator(zone, token_stream, token_pos);
    str = iterator.CurrentLiteral();
  }
  return str.IsNull() ? NULL : str.ToCString();
}

bool ProfileTrieWalker::Down() {
  if ((current_ == NULL) || (current_->NumChildren() == 0)) {
    return false;
  }
  parent_ = current_;
  current_ = current_->At(0);
  return true;
}

bool ProfileTrieWalker::NextSibling() {
  if (parent_ == NULL) {
    return false;
  }
  intptr_t current_index = parent_->IndexOf(current_);
  if (current_index < 0) {
    return false;
  }
  current_index++;
  if (current_index >= parent_->NumChildren()) {
    return false;
  }
  current_ = parent_->At(current_index);
  return true;
}

intptr_t ProfileTrieWalker::SiblingCount() {
  ASSERT(parent_ != NULL);
  return parent_->NumChildren();
}

void ProfilerService::PrintJSONImpl(Thread* thread,
                                    JSONStream* stream,
                                    Profile::TagOrder tag_order,
                                    intptr_t extra_tags,
                                    SampleFilter* filter,
                                    SampleBuffer* sample_buffer,
                                    bool as_timeline) {
  Isolate* isolate = thread->isolate();
  // Disable thread interrupts while processing the buffer.
  DisableThreadInterruptsScope dtis(thread);

  if (sample_buffer == NULL) {
    stream->PrintError(kFeatureDisabled, NULL);
    return;
  }

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    profile.Build(thread, filter, sample_buffer, tag_order, extra_tags);
    if (as_timeline) {
      profile.PrintTimelineJSON(stream);
    } else {
      profile.PrintProfileJSON(stream);
    }
  }
}

class NoAllocationSampleFilter : public SampleFilter {
 public:
  NoAllocationSampleFilter(Dart_Port port,
                           intptr_t thread_task_mask,
                           int64_t time_origin_micros,
                           int64_t time_extent_micros)
      : SampleFilter(port,
                     thread_task_mask,
                     time_origin_micros,
                     time_extent_micros) {}

  bool FilterSample(Sample* sample) { return !sample->is_allocation_sample(); }
};

void ProfilerService::PrintJSON(JSONStream* stream,
                                Profile::TagOrder tag_order,
                                intptr_t extra_tags,
                                int64_t time_origin_micros,
                                int64_t time_extent_micros) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  NoAllocationSampleFilter filter(isolate->main_port(), Thread::kMutatorTask,
                                  time_origin_micros, time_extent_micros);
  const bool as_timeline = false;
  PrintJSONImpl(thread, stream, tag_order, extra_tags, &filter,
                Profiler::sample_buffer(), as_timeline);
}

class ClassAllocationSampleFilter : public SampleFilter {
 public:
  ClassAllocationSampleFilter(Dart_Port port,
                              const Class& cls,
                              intptr_t thread_task_mask,
                              int64_t time_origin_micros,
                              int64_t time_extent_micros)
      : SampleFilter(port,
                     thread_task_mask,
                     time_origin_micros,
                     time_extent_micros),
        cls_(Class::Handle(cls.raw())) {
    ASSERT(!cls_.IsNull());
  }

  bool FilterSample(Sample* sample) {
    return sample->is_allocation_sample() &&
           (sample->allocation_cid() == cls_.id());
  }

 private:
  const Class& cls_;
};

void ProfilerService::PrintAllocationJSON(JSONStream* stream,
                                          Profile::TagOrder tag_order,
                                          const Class& cls,
                                          int64_t time_origin_micros,
                                          int64_t time_extent_micros) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ClassAllocationSampleFilter filter(isolate->main_port(), cls,
                                     Thread::kMutatorTask, time_origin_micros,
                                     time_extent_micros);
  const bool as_timeline = false;
  PrintJSONImpl(thread, stream, tag_order, kNoExtraTags, &filter,
                Profiler::sample_buffer(), as_timeline);
}

void ProfilerService::PrintNativeAllocationJSON(JSONStream* stream,
                                                Profile::TagOrder tag_order,
                                                int64_t time_origin_micros,
                                                int64_t time_extent_micros) {
  Thread* thread = Thread::Current();
  NativeAllocationSampleFilter filter(time_origin_micros, time_extent_micros);
  const bool as_timeline = false;
  PrintJSONImpl(thread, stream, tag_order, kNoExtraTags, &filter,
                Profiler::allocation_sample_buffer(), as_timeline);
}

void ProfilerService::PrintTimelineJSON(JSONStream* stream,
                                        Profile::TagOrder tag_order,
                                        int64_t time_origin_micros,
                                        int64_t time_extent_micros) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const intptr_t thread_task_mask = Thread::kMutatorTask |
                                    Thread::kCompilerTask |
                                    Thread::kSweeperTask | Thread::kMarkerTask;
  NoAllocationSampleFilter filter(isolate->main_port(), thread_task_mask,
                                  time_origin_micros, time_extent_micros);
  const bool as_timeline = true;
  PrintJSONImpl(thread, stream, tag_order, kNoExtraTags, &filter,
                Profiler::sample_buffer(), as_timeline);
}

void ProfilerService::ClearSamples() {
  SampleBuffer* sample_buffer = Profiler::sample_buffer();
  if (sample_buffer == NULL) {
    return;
  }

  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();

  // Disable thread interrupts while processing the buffer.
  DisableThreadInterruptsScope dtis(thread);

  ClearProfileVisitor clear_profile(isolate);
  sample_buffer->VisitSamples(&clear_profile);
}

#endif  // !PRODUCT

}  // namespace dart
