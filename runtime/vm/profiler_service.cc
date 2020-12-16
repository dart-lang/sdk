// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/profiler_service.h"

#include "platform/text_buffer.h"
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
#include "vm/timeline.h"

namespace dart {

DECLARE_FLAG(int, max_profile_depth);
DECLARE_FLAG(int, profile_period);
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
      OS::PrintErr(
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

const char* ProfileFunction::ResolvedScriptUrl() const {
  if (function_.IsNull()) {
    return NULL;
  }
  const Script& script = Script::Handle(function_.script());
  const String& uri = String::Handle(script.resolved_url());
  if (uri.IsNull()) {
    return NULL;
  }
  return uri.ToCString();
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
    const intptr_t cmp =
        TokenPosition::CompareForSorting(position.token_pos(), token_position);
    if (cmp > 0) {
      // Found insertion point.
      break;
    } else if (cmp == 0) {
      if (FLAG_trace_profiler_verbose) {
        OS::PrintErr("Ticking source position %s %s\n",
                     exclusive ? "exclusive" : "inclusive",
                     token_position.ToCString());
      }
      // Found existing position, tick it.
      position.Tick(exclusive);
      return;
    }
  }

  // Add new one, sorted by token position value.
  ProfileFunctionSourcePosition pfsp(token_position);
  if (FLAG_trace_profiler_verbose) {
    OS::PrintErr("Ticking source position %s %s\n",
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
  func->AddProperty("type", "NativeFunction");
  func->AddProperty("name", name());
  func->AddProperty("_kind", KindToCString(kind()));
}

void ProfileFunction::PrintToJSONArray(JSONArray* functions) {
  JSONObject obj(functions);
  obj.AddProperty("type", "ProfileFunction");
  obj.AddProperty("kind", KindToCString(kind()));
  obj.AddProperty("inclusiveTicks", inclusive_ticks());
  obj.AddProperty("exclusiveTicks", exclusive_ticks());
  obj.AddProperty("resolvedUrl", ResolvedScriptUrl());
  if (kind() == kDartFunction) {
    ASSERT(!function_.IsNull());
    obj.AddProperty("function", function_);
  } else {
    JSONObject func(&obj, "function");
    PrintToJSONObject(&func);
  }
  {
    JSONArray codes(&obj, "_codes");
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
                         const AbstractCode code)
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
      address_ticks_(0) {
  ASSERT(start_ < end_);
}

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
  intptr_t len = strlen(name) + 1;
  name_ = Thread::Current()->zone()->Alloc<char>(len);
  strncpy(name_, name, len);
}

void ProfileCode::GenerateAndSetSymbolName(const char* prefix) {
  const intptr_t kBuffSize = 512;
  char buff[kBuffSize];
  Utils::SNPrint(&buff[0], kBuffSize - 1, "%s [%" Px ", %" Px ")", prefix,
                 start(), end());
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
    obj.AddProperty("code", *code_.handle());
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
      const intptr_t kBuffSize = 512;
      char buff[kBuffSize];
      uword dso_base;
      char* dso_name;
      if (NativeSymbolResolver::LookupSharedObject(start(), &dso_base,
                                                   &dso_name)) {
        uword dso_offset = start() - dso_base;
        Utils::SNPrint(&buff[0], kBuffSize - 1, "[Native] %s+0x%" Px, dso_name,
                       dso_offset);
        NativeSymbolResolver::FreeSymbolName(dso_name);
      } else {
        Utils::SNPrint(&buff[0], kBuffSize - 1, "[Native] %" Px, start());
      }
      SetName(buff);
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

void ProfileCodeInlinedFunctionsCache::Get(
    uword pc,
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
  Add(pc, code, sample, frame_index, inlined_functions, inlined_token_positions,
      token_position);
}

bool ProfileCodeInlinedFunctionsCache::FindInCache(
    uword pc,
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
void ProfileCodeInlinedFunctionsCache::Add(
    uword pc,
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
    *token_position = cache_entry->token_position = TokenPosition::kNoSource;
    return;
  }

  // Write outputs.
  *inlined_functions = &(cache_entry->inlined_functions);
  *inlined_token_positions = &(cache_entry->inlined_token_positions);
  *token_position = cache_entry->token_position =
      cache_entry->inlined_token_positions[0];
}

intptr_t ProfileCodeInlinedFunctionsCache::OffsetForPC(uword pc,
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
                 Profile* profile)
      : thread_(thread),
        vm_isolate_(Dart::vm_isolate()),
        filter_(filter),
        sample_buffer_(sample_buffer),
        profile_(profile),
        deoptimized_code_(new DeoptimizedCodeSet(thread->isolate())),
        null_code_(Code::null()),
        null_function_(Function::ZoneHandle()),
        inclusive_tree_(false),
        inlined_functions_cache_(new ProfileCodeInlinedFunctionsCache()),
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
    PopulateFunctionTicks();
  }

 private:
  // Returns true if |frame_index| in |sample| is using CPU.
  static bool IsExecutingFrame(ProcessedSample* sample, intptr_t frame_index) {
    return (frame_index == 0) &&
           (sample->first_frame_executing() || sample->IsAllocationSample());
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
      const AbstractCode code = descriptor->code();
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

  void PopulateFunctionTicks() {
    ScopeTimer sw("ProfileBuilder::PopulateFunctionTicks", FLAG_trace_profiler);
    for (intptr_t sample_index = 0; sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Walk the sampled PCs.
      for (intptr_t frame_index = 0; frame_index < sample->length();
           frame_index++) {
        ASSERT(sample->At(frame_index) != 0);
        ProcessFrame(sample_index, sample, frame_index);
      }
      if (sample->truncated()) {
        InclusiveTickTruncatedTag(sample);
      }
    }
  }

  void ProcessFrame(intptr_t sample_index,
                    ProcessedSample* sample,
                    intptr_t frame_index) {
    const uword pc = sample->At(frame_index);
    ProfileCode* profile_code = GetProfileCode(pc, sample->timestamp());
    ProfileFunction* function = profile_code->function();
    ASSERT(function != NULL);
    const intptr_t code_index = profile_code->code_table_index();
    ASSERT(profile_code != NULL);

    GrowableArray<const Function*>* inlined_functions = NULL;
    GrowableArray<TokenPosition>* inlined_token_positions = NULL;
    TokenPosition token_position = TokenPosition::kNoSource;
    Code& code = Code::ZoneHandle();
    if (profile_code->code().IsCode()) {
      code ^= profile_code->code().raw();
      inlined_functions_cache_->Get(pc, code, sample, frame_index,
                                    &inlined_functions,
                                    &inlined_token_positions, &token_position);
      if (FLAG_trace_profiler_verbose && (inlined_functions != NULL)) {
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
      ProcessFunction(sample_index, sample, frame_index, function,
                      token_position, code_index);
      return;
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

    // Append the inlined children.
    for (intptr_t i = inlined_functions->length() - 1; i >= 0; i--) {
      const Function* inlined_function = (*inlined_functions)[i];
      ASSERT(inlined_function != NULL);
      ASSERT(!inlined_function->IsNull());
      TokenPosition inlined_token_position = (*inlined_token_positions)[i];
      ProcessInlinedFunction(sample_index, sample, frame_index + i,
                             inlined_function, inlined_token_position,
                             code_index);
    }
  }

  void ProcessInlinedFunction(intptr_t sample_index,
                              ProcessedSample* sample,
                              intptr_t frame_index,
                              const Function* inlined_function,
                              TokenPosition inlined_token_position,
                              intptr_t code_index) {
    ProfileFunctionTable* function_table = profile_->functions_;
    ProfileFunction* function = function_table->LookupOrAdd(*inlined_function);
    ASSERT(function != NULL);
    ProcessFunction(sample_index, sample, frame_index, function,
                    inlined_token_position, code_index);
  }

  bool ShouldTickNode(ProcessedSample* sample, intptr_t frame_index) {
    if (frame_index != 0) {
      return true;
    }
    // Only tick the first frame's node, if we are executing
    return IsExecutingFrame(sample, frame_index) || !FLAG_profile_vm;
  }

  void ProcessFunction(intptr_t sample_index,
                       ProcessedSample* sample,
                       intptr_t frame_index,
                       ProfileFunction* function,
                       TokenPosition token_position,
                       intptr_t code_index) {
    if (!function->is_visible()) {
      return;
    }
    if (FLAG_trace_profiler_verbose) {
      THR_Print("S[%" Pd "]F[%" Pd "] %s %s 0x%" Px "\n", sample_index,
                frame_index, function->Name(), token_position.ToCString(),
                sample->At(frame_index));
    }
    function->Tick(IsExecutingFrame(sample, frame_index), sample_index,
                   token_position);
    function->AddProfileCode(code_index);
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
    return profile_->GetCodeFromPC(pc, timestamp);
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

    // Check NativeSymbolResolver for pc.
    uword native_start = 0;
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
    ASSERT(pc < (pc + 1));  // Should not overflow.
    profile_code = new ProfileCode(ProfileCode::kNativeCode, native_start,
                                   pc + 1, 0, null_code_);
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

  Thread* thread_;
  Isolate* vm_isolate_;
  SampleFilter* filter_;
  SampleBuffer* sample_buffer_;
  Profile* profile_;
  DeoptimizedCodeSet* deoptimized_code_;
  const AbstractCode null_code_;
  const Function& null_function_;
  bool inclusive_tree_;
  ProfileCodeInlinedFunctionsCache* inlined_functions_cache_;
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
}

void Profile::Build(Thread* thread,
                    SampleFilter* filter,
                    SampleBuffer* sample_buffer) {
  // Disable thread interrupts while processing the buffer.
  DisableThreadInterruptsScope dtis(thread);
  ThreadInterrupter::SampleBufferReaderScope scope;

  ProfileBuilder builder(thread, filter, sample_buffer, this);
  builder.Build();
}

ProcessedSample* Profile::SampleAt(intptr_t index) {
  ASSERT(index >= 0);
  ASSERT(index < sample_count_);
  return samples_->At(index);
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

ProfileCode* Profile::GetCodeFromPC(uword pc, int64_t timestamp) {
  intptr_t index = live_code_->FindCodeIndexForPC(pc);
  ProfileCode* code = NULL;
  if (index < 0) {
    index = dead_code_->FindCodeIndexForPC(pc);
    ASSERT(index >= 0);
    code = dead_code_->At(index);
  } else {
    code = live_code_->At(index);
    ASSERT(code != NULL);
    if (code->compile_timestamp() > timestamp) {
      // Code is newer than sample. Fall back to dead code table.
      index = dead_code_->FindCodeIndexForPC(pc);
      ASSERT(index >= 0);
      code = dead_code_->At(index);
    }
  }

  ASSERT(code != NULL);
  ASSERT(code->Contains(pc));
  ASSERT(code->compile_timestamp() <= timestamp);
  return code;
}

void Profile::PrintHeaderJSON(JSONObject* obj) {
  intptr_t pid = OS::ProcessId();

  obj->AddProperty("samplePeriod", static_cast<intptr_t>(FLAG_profile_period));
  obj->AddProperty("maxStackDepth",
                   static_cast<intptr_t>(FLAG_max_profile_depth));
  obj->AddProperty("sampleCount", sample_count());
  obj->AddProperty("timespan", MicrosecondsToSeconds(GetTimeSpan()));
  obj->AddPropertyTimeMicros("timeOriginMicros", min_time());
  obj->AddPropertyTimeMicros("timeExtentMicros", GetTimeSpan());
  obj->AddProperty64("pid", pid);
  ProfilerCounters counters = Profiler::counters();
  {
    JSONObject counts(obj, "_counters");
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

void Profile::ProcessSampleFrameJSON(JSONArray* stack,
                                     ProfileCodeInlinedFunctionsCache* cache_,
                                     ProcessedSample* sample,
                                     intptr_t frame_index) {
  const uword pc = sample->At(frame_index);
  ProfileCode* profile_code = GetCodeFromPC(pc, sample->timestamp());
  ASSERT(profile_code != NULL);
  ProfileFunction* function = profile_code->function();
  ASSERT(function != NULL);

  // Don't show stubs in stack traces.
  if (!function->is_visible() ||
      (function->kind() == ProfileFunction::kStubFunction)) {
    return;
  }

  GrowableArray<const Function*>* inlined_functions = NULL;
  GrowableArray<TokenPosition>* inlined_token_positions = NULL;
  TokenPosition token_position = TokenPosition::kNoSource;
  Code& code = Code::ZoneHandle();

  if (profile_code->code().IsCode()) {
    code ^= profile_code->code().raw();
    cache_->Get(pc, code, sample, frame_index, &inlined_functions,
                &inlined_token_positions, &token_position);
    if (FLAG_trace_profiler_verbose && (inlined_functions != NULL)) {
      for (intptr_t i = 0; i < inlined_functions->length(); i++) {
        const String& name =
            String::Handle((*inlined_functions)[i]->QualifiedScrubbedName());
        THR_Print("InlinedFunction[%" Pd "] = {%s, %s}\n", i, name.ToCString(),
                  (*inlined_token_positions)[i].ToCString());
      }
    }
  }

  if (code.IsNull() || (inlined_functions == NULL) ||
      (inlined_functions->length() <= 1)) {
    PrintFunctionFrameIndexJSON(stack, function);
    return;
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

  for (intptr_t i = inlined_functions->length() - 1; i >= 0; i--) {
    const Function* inlined_function = (*inlined_functions)[i];
    ASSERT(inlined_function != NULL);
    ASSERT(!inlined_function->IsNull());
    ProcessInlinedFunctionFrameJSON(stack, inlined_function);
  }
}

void Profile::ProcessInlinedFunctionFrameJSON(
    JSONArray* stack,
    const Function* inlined_function) {
  ProfileFunction* function = functions_->LookupOrAdd(*inlined_function);
  ASSERT(function != NULL);
  PrintFunctionFrameIndexJSON(stack, function);
}

void Profile::PrintFunctionFrameIndexJSON(JSONArray* stack,
                                          ProfileFunction* function) {
  stack->AddValue64(function->table_index());
}

void Profile::PrintCodeFrameIndexJSON(JSONArray* stack,
                                      ProcessedSample* sample,
                                      intptr_t frame_index) {
  ProfileCode* code =
      GetCodeFromPC(sample->At(frame_index), sample->timestamp());
  const AbstractCode codeObj = code->code();

  // Ignore stub code objects.
  if (codeObj.IsStubCode() || codeObj.IsAllocationStubCode() ||
      codeObj.IsTypeTestStubCode()) {
    return;
  }
  stack->AddValue64(code->code_table_index());
}

void Profile::PrintSamplesJSON(JSONObject* obj, bool code_samples) {
  JSONArray samples(obj, "samples");
  auto* cache = new ProfileCodeInlinedFunctionsCache();
  for (intptr_t sample_index = 0; sample_index < samples_->length();
       sample_index++) {
    JSONObject sample_obj(&samples);
    ProcessedSample* sample = samples_->At(sample_index);
    sample_obj.AddProperty64("tid", OSThread::ThreadIdToIntPtr(sample->tid()));
    sample_obj.AddPropertyTimeMicros("timestamp", sample->timestamp());
    sample_obj.AddProperty("vmTag", VMTag::TagName(sample->vm_tag()));
    if (VMTag::IsNativeEntryTag(sample->vm_tag())) {
      sample_obj.AddProperty("nativeEntryTag", true);
    }
    if (VMTag::IsRuntimeEntryTag(sample->vm_tag())) {
      sample_obj.AddProperty("runtimeEntryTag", true);
    }
    if (UserTags::IsUserTag(sample->user_tag())) {
      sample_obj.AddProperty("userTag", UserTags::TagName(sample->user_tag()));
    }
    if (sample->truncated()) {
      sample_obj.AddProperty("truncated", true);
    }
    if (sample->is_native_allocation_sample()) {
      sample_obj.AddProperty64("_nativeAllocationSizeBytes",
                               sample->native_allocation_size_bytes());
    }
    {
      JSONArray stack(&sample_obj, "stack");
      // Walk the sampled PCs.
      for (intptr_t frame_index = 0; frame_index < sample->length();
           frame_index++) {
        ASSERT(sample->At(frame_index) != 0);
        ProcessSampleFrameJSON(&stack, cache, sample, frame_index);
      }
    }
    if (code_samples) {
      JSONArray stack(&sample_obj, "_codeStack");
      for (intptr_t frame_index = 0; frame_index < sample->length();
           frame_index++) {
        ASSERT(sample->At(frame_index) != 0);
        PrintCodeFrameIndexJSON(&stack, sample, frame_index);
      }
    }
  }
}

ProfileFunction* Profile::FindFunction(const Function& function) {
  return (functions_ != NULL) ? functions_->Lookup(function) : NULL;
}

void Profile::PrintProfileJSON(JSONStream* stream, bool include_code_samples) {
  ScopeTimer sw("Profile::PrintProfileJSON", FLAG_trace_profiler);
  JSONObject obj(stream);
  obj.AddProperty("type", "CpuSamples");
  PrintHeaderJSON(&obj);
  if (include_code_samples) {
    JSONArray codes(&obj, "_codes");
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
  PrintSamplesJSON(&obj, include_code_samples);
}

void ProfilerService::PrintJSONImpl(Thread* thread,
                                    JSONStream* stream,
                                    SampleFilter* filter,
                                    SampleBuffer* sample_buffer,
                                    bool include_code_samples) {
  Isolate* isolate = thread->isolate();

  // We should bail out in service.cc if the profiler is disabled.
  ASSERT(sample_buffer != NULL);

  StackZone zone(thread);
  HANDLESCOPE(thread);
  Profile profile(isolate);
  profile.Build(thread, filter, sample_buffer);
  profile.PrintProfileJSON(stream, include_code_samples);
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
                                int64_t time_origin_micros,
                                int64_t time_extent_micros,
                                bool include_code_samples) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  NoAllocationSampleFilter filter(isolate->main_port(), Thread::kMutatorTask,
                                  time_origin_micros, time_extent_micros);
  PrintJSONImpl(thread, stream, &filter, Profiler::sample_buffer(),
                include_code_samples);
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
                                          const Class& cls,
                                          int64_t time_origin_micros,
                                          int64_t time_extent_micros) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ClassAllocationSampleFilter filter(isolate->main_port(), cls,
                                     Thread::kMutatorTask, time_origin_micros,
                                     time_extent_micros);
  PrintJSONImpl(thread, stream, &filter, Profiler::sample_buffer(), true);
}

void ProfilerService::PrintNativeAllocationJSON(JSONStream* stream,
                                                int64_t time_origin_micros,
                                                int64_t time_extent_micros,
                                                bool include_code_samples) {
  Thread* thread = Thread::Current();
  NativeAllocationSampleFilter filter(time_origin_micros, time_extent_micros);
  PrintJSONImpl(thread, stream, &filter, Profiler::allocation_sample_buffer(),
                include_code_samples);
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
  ThreadInterrupter::SampleBufferReaderScope scope;

  ClearProfileVisitor clear_profile(isolate);
  sample_buffer->VisitSamples(&clear_profile);
}

#endif  // !PRODUCT

}  // namespace dart
