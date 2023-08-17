// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/profiler_service.h"

#include <memory>

#include "platform/text_buffer.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/heap/safepoint.h"
#include "vm/json_stream.h"
#include "vm/log.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/scope_timer.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/timeline.h"

#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
#include "perfetto/ext/tracing/core/trace_packet.h"
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "vm/perfetto_utils.h"
#include "vm/protos/perfetto/common/builtin_clock.pbzero.h"
#include "vm/protos/perfetto/trace/interned_data/interned_data.pbzero.h"
#include "vm/protos/perfetto/trace/profiling/profile_common.pbzero.h"
#include "vm/protos/perfetto/trace/profiling/profile_packet.pbzero.h"
#include "vm/protos/perfetto/trace/trace_packet.pbzero.h"
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

namespace dart {

DECLARE_FLAG(int, max_profile_depth);
DECLARE_FLAG(int, profile_period);
DECLARE_FLAG(bool, profile_vm);

#ifndef PRODUCT

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
      function_(Function::ZoneHandle(function.ptr())),
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
  if (name_ != nullptr) {
    return name_;
  }
  ASSERT(!function_.IsNull());
  const String& func_name =
      String::Handle(function_.QualifiedUserVisibleName());
  return func_name.ToCString();
}

const char* ProfileFunction::ResolvedScriptUrl() const {
  if (function_.IsNull()) {
    return nullptr;
  }
  const Script& script = Script::Handle(function_.script());
  if (script.IsNull()) {
    return nullptr;
  }
  const String& uri = String::Handle(script.resolved_url());
  if (uri.IsNull()) {
    return nullptr;
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

void ProfileFunction::PrintToJSONArray(JSONArray* functions,
                                       bool print_only_ids) {
  if (print_only_ids) {
    JSONObject obj(functions);
    if (kind() == kDartFunction) {
      ASSERT(!function_.IsNull());
      obj.AddProperty("type", "@Object");
      function_.AddFunctionServiceId(obj);
    } else {
      PrintToJSONObject(&obj);
    }
    return;
  }
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
  if (pfsp == nullptr) {
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
      name_(nullptr),
      compile_timestamp_(0),
      function_(nullptr),
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
  ASSERT(other != nullptr);
  return other->Contains(start_) || other->Contains(end_ - 1) ||
         Contains(other->start()) || Contains(other->end() - 1);
}

bool ProfileCode::IsOptimizedDart() const {
  return !code_.IsNull() && code_.is_optimized();
}

void ProfileCode::SetName(const char* name) {
  if (name == nullptr) {
    name_ = nullptr;
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
    ASSERT(function_ != nullptr);
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
    ASSERT(function_ != nullptr);
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
    ASSERT(function_ != nullptr);
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
    ASSERT(function_ != nullptr);
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
  return nullptr;
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
        unknown_function_(nullptr),
        table_(8) {
    unknown_function_ =
        Add(ProfileFunction::kUnknownFunction, "<unknown Dart function>");
  }

  ProfileFunction* LookupOrAdd(const Function& function) {
    ASSERT(!function.IsNull());
    ProfileFunction* profile_function = Lookup(function);
    if (profile_function != nullptr) {
      return profile_function;
    }
    return Add(function);
  }

  ProfileFunction* Lookup(const Function& function) {
    ASSERT(!function.IsNull());
    return function_hash_.LookupValue(&function);
  }

  ProfileFunction* GetUnknown() {
    ASSERT(unknown_function_ != nullptr);
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
    ASSERT(name != nullptr);
    ProfileFunction* profile_function =
        new ProfileFunction(kind, name, null_function_, table_.length());
    table_.Add(profile_function);
    return profile_function;
  }

  ProfileFunction* Add(const Function& function) {
    ASSERT(Lookup(function) == nullptr);
    ProfileFunction* profile_function = new ProfileFunction(
        ProfileFunction::kDartFunction, nullptr, function, table_.length());
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

    static inline uword Hash(Key key) { return key->Hash(); }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return kv->function()->ptr() == key->ptr();
    }
  };

  const Function& null_function_;
  ProfileFunction* unknown_function_;
  ZoneGrowableArray<ProfileFunction*> table_;
  DirectChainedHashMap<ProfileFunctionTableTrait> function_hash_;
};

ProfileFunction* ProfileCode::SetFunctionAndName(ProfileFunctionTable* table) {
  ASSERT(function_ == nullptr);

  ProfileFunction* function = nullptr;
  if ((kind() == kReusedCode) || (kind() == kCollectedCode)) {
    if (name() == nullptr) {
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
    if (name() == nullptr) {
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
    if (name() == nullptr) {
      if (UserTags::IsUserTag(start())) {
        const char* tag_name = UserTags::TagName(start());
        ASSERT(tag_name != nullptr);
        SetName(tag_name);
      } else if (VMTag::IsVMTag(start()) || VMTag::IsRuntimeEntryTag(start()) ||
                 VMTag::IsNativeEntryTag(start())) {
        const char* tag_name = VMTag::TagName(start());
        ASSERT(tag_name != nullptr);
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
  ASSERT(function != nullptr);

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
  ProfileCode* lo_code = nullptr;
  ProfileCode* hi_code = nullptr;
  const uword pc = new_code->end() - 1;
  FindNeighbors(pc, &lo, &hi, &lo_code, &hi_code);
  ASSERT((lo_code != nullptr) || (hi_code != nullptr));

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
    *lo_code = nullptr;
    *hi = 0;
    *hi_code = At(*hi);
    return;
  }

  if (pc >= At(length - 1)->end()) {
    // Higher than any existing code.
    *lo = length - 1;
    *lo_code = At(*lo);
    *hi = -1;
    *hi_code = nullptr;
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
        *inlined_functions = nullptr;
        *inlined_token_positions = nullptr;
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
    *inlined_functions = nullptr;
    *inlined_token_positions = nullptr;
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
                 Isolate* isolate,
                 SampleFilter* filter,
                 SampleBlockBuffer* sample_buffer,
                 Profile* profile)
      : thread_(thread),
        isolate_(isolate),
        vm_isolate_(Dart::vm_isolate()),
        filter_(filter),
        sample_buffer_(sample_buffer),
        profile_(profile),
        null_code_(Code::null()),
        null_function_(Function::ZoneHandle()),
        inclusive_tree_(false),
        inlined_functions_cache_(new ProfileCodeInlinedFunctionsCache()),
        samples_(nullptr),
        info_kind_(kNone) {
    ASSERT(profile_ != nullptr);
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
    SanitizeMinMaxTimes();
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
    if (sample_buffer_ == nullptr) {
      return false;
    }
    samples_ = sample_buffer_->BuildProcessedSampleBuffer(isolate_, filter_);
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

    // Build the live code table eagerly by populating it with code objects
    // from the processed sample buffer.
    const CodeLookupTable& code_lookup_table = samples_->code_lookup_table();
    for (intptr_t i = 0; i < code_lookup_table.length(); i++) {
      const CodeDescriptor* descriptor = code_lookup_table.At(i);
      ASSERT(descriptor != nullptr);
      const AbstractCode code = descriptor->code();
      RegisterLiveProfileCode(new ProfileCode(
          ProfileCode::kDartCode, code.PayloadStart(),
          code.PayloadStart() + code.Size(), code.compile_timestamp(), code));
      thread_->CheckForSafepoint();
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
        ASSERT(code != nullptr);
        code->Tick(pc, IsExecutingFrame(sample, frame_index), sample_index);
      }

      TickExitFrame(sample->vm_tag(), sample_index, sample);
      thread_->CheckForSafepoint();
    }
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
      ASSERT(code != nullptr);
      code->set_code_table_index(index);
    }

    for (intptr_t i = 0; i < dead_table->length(); i++) {
      const intptr_t index = dead_code_index_offset + i;
      ProfileCode* code = dead_table->At(i);
      ASSERT(code != nullptr);
      code->set_code_table_index(index);
    }

    for (intptr_t i = 0; i < tag_table->length(); i++) {
      const intptr_t index = tag_code_index_offset + i;
      ProfileCode* code = tag_table->At(i);
      ASSERT(code != nullptr);
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
      ASSERT(code != nullptr);
      code->SetFunctionAndName(function_table);
      thread_->CheckForSafepoint();
    }

    for (intptr_t i = 0; i < dead_table->length(); i++) {
      ProfileCode* code = dead_table->At(i);
      ASSERT(code != nullptr);
      code->SetFunctionAndName(function_table);
      thread_->CheckForSafepoint();
    }

    for (intptr_t i = 0; i < tag_table->length(); i++) {
      ProfileCode* code = tag_table->At(i);
      ASSERT(code != nullptr);
      code->SetFunctionAndName(function_table);
      thread_->CheckForSafepoint();
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
    ASSERT(function != nullptr);
    const intptr_t code_index = profile_code->code_table_index();
    ASSERT(profile_code != nullptr);

    GrowableArray<const Function*>* inlined_functions = nullptr;
    GrowableArray<TokenPosition>* inlined_token_positions = nullptr;
    TokenPosition token_position = TokenPosition::kNoSource;
    Code& code = Code::ZoneHandle();
    if (profile_code->code().IsCode()) {
      code ^= profile_code->code().ptr();
      inlined_functions_cache_->Get(pc, code, sample, frame_index,
                                    &inlined_functions,
                                    &inlined_token_positions, &token_position);
      if (FLAG_trace_profiler_verbose && (inlined_functions != nullptr)) {
        for (intptr_t i = 0; i < inlined_functions->length(); i++) {
          const String& name =
              String::Handle((*inlined_functions)[i]->QualifiedScrubbedName());
          THR_Print("InlinedFunction[%" Pd "] = {%s, %s}\n", i,
                    name.ToCString(),
                    (*inlined_token_positions)[i].ToCString());
        }
      }
    }

    if (code.IsNull() || (inlined_functions == nullptr) ||
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
      ASSERT(inlined_function != nullptr);
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
    ASSERT(function != nullptr);
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
    ASSERT(code != nullptr);
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
    ASSERT(code != nullptr);
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
    ASSERT(code != nullptr);
    ProfileFunction* function = code->function();
    ASSERT(function != nullptr);
    function->Tick(true, serial, TokenPosition::kNoSource);
  }

  intptr_t GetProfileCodeTagIndex(uword tag) {
    ProfileCodeTable* tag_table = profile_->tag_code_;
    intptr_t index = tag_table->FindCodeIndexForPC(tag);
    ASSERT(index >= 0);
    ProfileCode* code = tag_table->At(index);
    ASSERT(code != nullptr);
    return code->code_table_index();
  }

  intptr_t GetProfileFunctionTagIndex(uword tag) {
    ProfileCodeTable* tag_table = profile_->tag_code_;
    intptr_t index = tag_table->FindCodeIndexForPC(tag);
    ASSERT(index >= 0);
    ProfileCode* code = tag_table->At(index);
    ASSERT(code != nullptr);
    ProfileFunction* function = code->function();
    ASSERT(function != nullptr);
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
    return vm_isolate_->group()->heap()->CodeContains(pc) ||
           thread_->isolate()->group()->heap()->CodeContains(pc);
  }

  ProfileCode* FindOrRegisterNativeProfileCode(uword pc) {
    // Check if |pc| is already known in the live code table.
    ProfileCodeTable* live_table = profile_->live_code_;
    ProfileCode* profile_code = live_table->FindCodeForPC(pc);
    if (profile_code != nullptr) {
      return profile_code;
    }

    // We haven't seen this pc yet.

    // Check NativeSymbolResolver for pc.
    uword native_start = 0;
    char* native_name =
        NativeSymbolResolver::LookupSymbolName(pc, &native_start);
    if (native_name == nullptr) {
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
      if (native_name != nullptr) {
        NativeSymbolResolver::FreeSymbolName(native_name);
        native_name = nullptr;
      }
      native_start = pc;
    }
    if ((pc - native_start) > (32 * KB)) {
      // Suspect lookup result. More likely dladdr going off the rails than a
      // jumbo function.
      if (native_name != nullptr) {
        NativeSymbolResolver::FreeSymbolName(native_name);
        native_name = nullptr;
      }
      native_start = pc;
    }

    ASSERT(pc >= native_start);
    ASSERT(pc < (pc + 1));  // Should not overflow.
    profile_code = new ProfileCode(ProfileCode::kNativeCode, native_start,
                                   pc + 1, 0, null_code_);
    if (native_name != nullptr) {
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
    if (code != nullptr) {
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
    if ((code != nullptr) && (code->compile_timestamp() <= timestamp)) {
      // Code was compiled before sample was taken.
      return code;
    }
    if ((code == nullptr) && !IsPCInDartHeap(pc)) {
      // Not a PC from Dart code. Check with native code.
      return FindOrRegisterNativeProfileCode(pc);
    }
    // We either didn't find the code or it was compiled after the sample.
    return FindOrRegisterDeadProfileCode(pc);
  }

  Thread* thread_;
  Isolate* isolate_;
  Isolate* vm_isolate_;
  SampleFilter* filter_;
  SampleBlockBuffer* sample_buffer_;
  Profile* profile_;
  const AbstractCode null_code_;
  const Function& null_function_;
  bool inclusive_tree_;
  ProfileCodeInlinedFunctionsCache* inlined_functions_cache_;
  ProcessedSampleBuffer* samples_;
  ProfileInfoKind info_kind_;
};  // ProfileBuilder.

Profile::Profile()
    : zone_(Thread::Current()->zone()),
      samples_(nullptr),
      live_code_(nullptr),
      dead_code_(nullptr),
      tag_code_(nullptr),
      functions_(nullptr),
      dead_code_index_offset_(-1),
      tag_code_index_offset_(-1),
      min_time_(kMaxInt64),
      max_time_(0),
      sample_count_(0) {}

void Profile::Build(Thread* thread,
                    Isolate* isolate,
                    SampleFilter* filter,
                    SampleBlockBuffer* sample_buffer) {
  ASSERT(isolate != nullptr);

  // Disable thread interrupts while processing the buffer.
  DisableThreadInterruptsScope dtis(thread);
  ProfileBuilder builder(thread, isolate, filter, sample_buffer, this);
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
  ASSERT(functions_ != nullptr);
  return functions_->At(index);
}

ProfileCode* Profile::GetCode(intptr_t index) {
  ASSERT(live_code_ != nullptr);
  ASSERT(dead_code_ != nullptr);
  ASSERT(tag_code_ != nullptr);
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
  ProfileCode* code = nullptr;
  if (index < 0) {
    index = dead_code_->FindCodeIndexForPC(pc);
    ASSERT(index >= 0);
    code = dead_code_->At(index);
  } else {
    code = live_code_->At(index);
    ASSERT(code != nullptr);
    if (code->compile_timestamp() > timestamp) {
      // Code is newer than sample. Fall back to dead code table.
      index = dead_code_->FindCodeIndexForPC(pc);
      ASSERT(index >= 0);
      code = dead_code_->At(index);
    }
  }

  ASSERT(code != nullptr);
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
                                     ProfileCodeInlinedFunctionsCache* cache,
                                     ProcessedSample* sample,
                                     intptr_t frame_index) {
  const uword pc = sample->At(frame_index);
  ProfileCode* profile_code = GetCodeFromPC(pc, sample->timestamp());
  ASSERT(profile_code != nullptr);
  ProfileFunction* function = profile_code->function();
  ASSERT(function != nullptr);

  // Don't show stubs in stack traces.
  if (!function->is_visible() ||
      (function->kind() == ProfileFunction::kStubFunction)) {
    return;
  }

  GrowableArray<const Function*>* inlined_functions = nullptr;
  GrowableArray<TokenPosition>* inlined_token_positions = nullptr;
  TokenPosition token_position = TokenPosition::kNoSource;
  Code& code = Code::ZoneHandle();

  if (profile_code->code().IsCode()) {
    code ^= profile_code->code().ptr();
    cache->Get(pc, code, sample, frame_index, &inlined_functions,
               &inlined_token_positions, &token_position);
    if (FLAG_trace_profiler_verbose && (inlined_functions != nullptr)) {
      for (intptr_t i = 0; i < inlined_functions->length(); i++) {
        const String& name =
            String::Handle((*inlined_functions)[i]->QualifiedScrubbedName());
        THR_Print("InlinedFunction[%" Pd "] = {%s, %s}\n", i, name.ToCString(),
                  (*inlined_token_positions)[i].ToCString());
      }
    }
  }

  if (code.IsNull() || (inlined_functions == nullptr) ||
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
    ASSERT(inlined_function != nullptr);
    ASSERT(!inlined_function->IsNull());
    ProcessInlinedFunctionFrameJSON(stack, inlined_function);
  }
}

#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
void Profile::ProcessSampleFramePerfetto(
    perfetto::protos::pbzero::Callstack* callstack,
    ProfileCodeInlinedFunctionsCache* cache,
    ProcessedSample* sample,
    intptr_t frame_index) {
  const uword pc = sample->At(frame_index);
  ProfileCode* profile_code = GetCodeFromPC(pc, sample->timestamp());
  ASSERT(profile_code != nullptr);
  ProfileFunction* function = profile_code->function();
  ASSERT(function != nullptr);

  // Don't show stubs in stack traces.
  if (!function->is_visible() ||
      (function->kind() == ProfileFunction::kStubFunction)) {
    return;
  }

  GrowableArray<const Function*>* inlined_functions = nullptr;
  GrowableArray<TokenPosition>* inlined_token_positions = nullptr;
  TokenPosition token_position = TokenPosition::kNoSource;
  Code& code = Code::ZoneHandle();

  if (profile_code->code().IsCode()) {
    code ^= profile_code->code().ptr();
    cache->Get(pc, code, sample, frame_index, &inlined_functions,
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

  if (code.IsNull() || (inlined_functions == nullptr) ||
      (inlined_functions->length() <= 1)) {
    // This is the ID of a |Frame| that was added to the interned data table in
    // |ProfilerService::PrintProfilePerfetto|. See the comments in that method
    // for more details.
    callstack->add_frame_ids(function->table_index() + 1);
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

  for (intptr_t i = 0; i < inlined_functions->length(); ++i) {
    const Function* inlined_function = (*inlined_functions)[i];
    ASSERT(inlined_function != NULL);
    ASSERT(!inlined_function->IsNull());
    ProfileFunction* profile_function =
        functions_->LookupOrAdd(*inlined_function);
    ASSERT(profile_function != NULL);
    // This is the ID of a |Frame| that was added to the interned data table in
    // |ProfilerService::PrintProfilePerfetto|. See the comments in that method
    // for more details.
    callstack->add_frame_ids(profile_function->table_index() + 1);
  }
}
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

void Profile::ProcessInlinedFunctionFrameJSON(
    JSONArray* stack,
    const Function* inlined_function) {
  ProfileFunction* function = functions_->LookupOrAdd(*inlined_function);
  ASSERT(function != nullptr);
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
  // Note that |cache| is zone-allocated, so it does not need to be deallocated
  // manually.
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
    if (sample->IsAllocationSample()) {
      sample_obj.AddProperty64("classId", sample->allocation_cid());
      sample_obj.AddProperty64("identityHashCode",
                               sample->allocation_identity_hash());
    }
  }
}

#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
void Profile::PrintSamplesPerfetto(
    JSONBase64String* jsonBase64String,
    protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket>*
        packet_ptr) {
  ASSERT(jsonBase64String != nullptr);
  ASSERT(packet_ptr != nullptr);
  auto& packet = *packet_ptr;

  // Note that |cache| is zone-allocated, so it does not need to be deallocated
  // manually.
  auto* cache = new ProfileCodeInlinedFunctionsCache();
  for (intptr_t sample_index = 0; sample_index < samples_->length();
       ++sample_index) {
    ProcessedSample* sample = samples_->At(sample_index);

    perfetto_utils::SetTrustedPacketSequenceId(packet.get());
    // We set this flag to indicate that this packet reads from the interned
    // data table.
    packet->set_sequence_flags(
        perfetto::protos::pbzero::TracePacket_SequenceFlags::
            SEQ_NEEDS_INCREMENTAL_STATE);
    perfetto_utils::SetTimestampAndMonotonicClockId(packet.get(),
                                                    sample->timestamp());

    const intptr_t callstack_iid = sample_index + 1;
    // Add a |Callstack| to the interned data table that represents the stack
    // trace stored in |sample|.
    perfetto::protos::pbzero::Callstack* callstack =
        packet->set_interned_data()->add_callstacks();
    callstack->set_iid(callstack_iid);
    // Walk the sampled PCs.
    for (intptr_t frame_index = sample->length() - 1; frame_index >= 0;
         --frame_index) {
      ASSERT(sample->At(frame_index) != 0);
      ProcessSampleFramePerfetto(callstack, cache, sample, frame_index);
    }

    // Populate |packet| with a |PerfSample| that is linked to the |Callstack|
    // that we populated above.
    perfetto::protos::pbzero::PerfSample& perf_sample =
        *packet->set_perf_sample();
    perf_sample.set_pid(OS::ProcessId());
    perf_sample.set_tid(OSThread::ThreadIdToIntPtr(sample->tid()));
    perf_sample.set_callstack_iid(callstack_iid);

    perfetto_utils::AppendPacketToJSONBase64String(jsonBase64String, &packet);
    packet.Reset();
  }
}
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

ProfileFunction* Profile::FindFunction(const Function& function) {
  return (functions_ != nullptr) ? functions_->Lookup(function) : nullptr;
}

void Profile::PrintProfileJSON(JSONStream* stream, bool include_code_samples) {
  JSONObject obj(stream);
  PrintProfileJSON(&obj, include_code_samples);
}

void Profile::PrintProfileJSON(JSONObject* obj,
                               bool include_code_samples,
                               bool is_event) {
  ScopeTimer sw("Profile::PrintProfileJSON", FLAG_trace_profiler);
  Thread* thread = Thread::Current();
  if (is_event) {
    obj->AddProperty("type", "CpuSamplesEvent");
  } else {
    obj->AddProperty("type", "CpuSamples");
  }
  PrintHeaderJSON(obj);
  if (include_code_samples) {
    JSONArray codes(obj, "_codes");
    for (intptr_t i = 0; i < live_code_->length(); i++) {
      ProfileCode* code = live_code_->At(i);
      ASSERT(code != nullptr);
      code->PrintToJSONArray(&codes);
      thread->CheckForSafepoint();
    }
    for (intptr_t i = 0; i < dead_code_->length(); i++) {
      ProfileCode* code = dead_code_->At(i);
      ASSERT(code != nullptr);
      code->PrintToJSONArray(&codes);
      thread->CheckForSafepoint();
    }
    for (intptr_t i = 0; i < tag_code_->length(); i++) {
      ProfileCode* code = tag_code_->At(i);
      ASSERT(code != nullptr);
      code->PrintToJSONArray(&codes);
      thread->CheckForSafepoint();
    }
  }

  {
    JSONArray functions(obj, "functions");
    for (intptr_t i = 0; i < functions_->length(); i++) {
      ProfileFunction* function = functions_->At(i);
      ASSERT(function != nullptr);
      function->PrintToJSONArray(&functions, is_event);
      thread->CheckForSafepoint();
    }
  }
  PrintSamplesJSON(obj, include_code_samples);
  thread->CheckForSafepoint();
}

#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
void Profile::PrintProfilePerfetto(JSONStream* js) {
  ScopeTimer sw("Profile::PrintProfilePerfetto", FLAG_trace_profiler);
  Thread* thread = Thread::Current();

  JSONObject jsobj_topLevel(js);
  jsobj_topLevel.AddProperty("type", "PerfettoCpuSamples");
  PrintHeaderJSON(&jsobj_topLevel);

  js->AppendSerializedObject("\"samples\":");
  JSONBase64String jsonBase64String(js);

  // We allocate one heap-buffered packet and continuously follow a cycle of
  // resetting the buffer and writing its contents.
  protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket> packet;

  perfetto_utils::PopulateClockSnapshotPacket(packet.get());
  perfetto_utils::AppendPacketToJSONBase64String(&jsonBase64String, &packet);
  packet.Reset();

  perfetto_utils::SetTrustedPacketSequenceId(packet.get());
  // We use |PerfSample|s to serialize our CPU sample information. Each
  // |PerfSample| must be linked to a |Callstack| in the interned data table.
  // When serializing a new profile, we set |SEQ_INCREMENTAL_STATE_CLEARED| on
  // the first packet to clear the interned data table and avoid conflicts with
  // any profiles that are combined with this one.
  // See "runtime/vm/protos/perfetto/trace/interned_data/interned_data.proto"
  // a detailed description of how the interned data table works.
  packet->set_sequence_flags(
      perfetto::protos::pbzero::TracePacket_SequenceFlags::
          SEQ_INCREMENTAL_STATE_CLEARED);

  perfetto::protos::pbzero::InternedData& interned_data =
      *packet->set_interned_data();

  // The Perfetto trace viewer will not be able to parse our trace if the
  // mapping with iid 0 is not declared.
  perfetto::protos::pbzero::Mapping& mapping = *interned_data.add_mappings();
  mapping.set_iid(0);

  for (intptr_t i = 0; i < functions_->length(); ++i) {
    ProfileFunction* function = functions_->At(i);
    ASSERT(function != NULL);
    const intptr_t common_iid = function->table_index() + 1;

    perfetto::protos::pbzero::InternedString& function_name =
        *interned_data.add_function_names();
    function_name.set_iid(common_iid);
    function_name.set_str(function->Name());

    const char* resolved_script_url = function->ResolvedScriptUrl();
    if (resolved_script_url != nullptr) {
      perfetto::protos::pbzero::InternedString& mapping_path =
          *interned_data.add_mapping_paths();
      mapping_path.set_iid(common_iid);
      const Script& script_handle =
          Script::Handle(function->function()->script());
      TokenPosition token_pos = function->function()->token_pos();
      if (!script_handle.IsNull() && token_pos.IsReal()) {
        intptr_t line = -1;
        intptr_t column = -1;
        script_handle.GetTokenLocation(token_pos, &line, &column);
        intptr_t path_with_location_buffer_size =
            Utils::SNPrint(nullptr, 0, "%s:%" Pd ":%" Pd, resolved_script_url,
                           line, column) +
            1;
        std::unique_ptr<char[]> path_with_location =
            std::make_unique<char[]>(path_with_location_buffer_size);
        Utils::SNPrint(path_with_location.get(), path_with_location_buffer_size,
                       "%s:%" Pd ":%" Pd, resolved_script_url, line, column);
        mapping_path.set_str(path_with_location.get());
      } else {
        mapping_path.set_str(resolved_script_url);
      }

      // TODO(derekx): Check if using profiled_frame_symbols instead of mapping
      // provides any benefit.
      perfetto::protos::pbzero::Mapping& mapping =
          *interned_data.add_mappings();
      mapping.set_iid(common_iid);
      mapping.add_path_string_ids(common_iid);
    }

    // Add a |Frame| to the interned data table that is linked to |function|'s
    // name and source location (through the interned data table). A Perfetto
    // |Callstack| consists of a stack of |Frame|s, so the |Callstack|s
    // populated by |PrintSamplesPerfetto| will refer to these |Frame|s.
    perfetto::protos::pbzero::Frame& frame = *interned_data.add_frames();
    frame.set_iid(common_iid);
    frame.set_function_name_id(common_iid);
    frame.set_mapping_id(resolved_script_url == nullptr ? 0 : common_iid);

    thread->CheckForSafepoint();
  }
  perfetto_utils::AppendPacketToJSONBase64String(&jsonBase64String, &packet);
  packet.Reset();

  PrintSamplesPerfetto(&jsonBase64String, &packet);
  thread->CheckForSafepoint();
}
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

void ProfilerService::PrintCommonImpl(PrintFormat format,
                                      Thread* thread,
                                      JSONStream* js,
                                      SampleFilter* filter,
                                      SampleBlockBuffer* buffer,
                                      bool include_code_samples) {
  // We should bail out in service.cc if the profiler is disabled.
  ASSERT(buffer != nullptr);

  StackZone zone(thread);
  Profile profile;
  profile.Build(thread, thread->isolate(), filter, buffer);

  if (format == PrintFormat::JSON) {
    profile.PrintProfileJSON(js, include_code_samples);
  } else if (format == PrintFormat::Perfetto) {
#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
    // This branch will never be reached when SUPPORT_PERFETTO is not defined or
    // when PRODUCT is defined, because |PrintPerfetto| is not defined when
    // SUPPORT_PERFETTO is not defined or when PRODUCT is defined.
    profile.PrintProfilePerfetto(js);
#else
    UNREACHABLE();

#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
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

void ProfilerService::PrintCommon(PrintFormat format,
                                  JSONStream* js,
                                  int64_t time_origin_micros,
                                  int64_t time_extent_micros,
                                  bool include_code_samples) {
  Thread* thread = Thread::Current();
  const Isolate* isolate = thread->isolate();
  NoAllocationSampleFilter filter(isolate->main_port(), Thread::kMutatorTask,
                                  time_origin_micros, time_extent_micros);

  PrintCommonImpl(format, thread, js, &filter, Profiler::sample_block_buffer(),
                  include_code_samples);
}

void ProfilerService::PrintJSON(JSONStream* js,
                                int64_t time_origin_micros,
                                int64_t time_extent_micros,
                                bool include_code_samples) {
  PrintCommon(PrintFormat::JSON, js, time_origin_micros, time_extent_micros,
              include_code_samples);
}

#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
void ProfilerService::PrintPerfetto(JSONStream* js,
                                    int64_t time_origin_micros,
                                    int64_t time_extent_micros) {
  PrintCommon(PrintFormat::Perfetto, js, time_origin_micros,
              time_extent_micros);
}
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

class AllocationSampleFilter : public SampleFilter {
 public:
  AllocationSampleFilter(Dart_Port port,
                         intptr_t thread_task_mask,
                         int64_t time_origin_micros,
                         int64_t time_extent_micros)
      : SampleFilter(port,
                     thread_task_mask,
                     time_origin_micros,
                     time_extent_micros) {}

  bool FilterSample(Sample* sample) { return sample->is_allocation_sample(); }
};

void ProfilerService::PrintAllocationJSON(JSONStream* stream,
                                          int64_t time_origin_micros,
                                          int64_t time_extent_micros) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  AllocationSampleFilter filter(isolate->main_port(), Thread::kMutatorTask,
                                time_origin_micros, time_extent_micros);
  PrintCommonImpl(PrintFormat::JSON, thread, stream, &filter,
                  Profiler::sample_block_buffer(), true);
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
        cls_(Class::Handle(cls.ptr())) {
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
  PrintCommonImpl(PrintFormat::JSON, thread, stream, &filter,
                  Profiler::sample_block_buffer(), true);
}

void ProfilerService::ClearSamples() {
  SampleBlockBuffer* sample_block_buffer = Profiler::sample_block_buffer();
  if (sample_block_buffer == nullptr) {
    return;
  }

  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();

  // Disable thread interrupts while processing the buffer.
  DisableThreadInterruptsScope dtis(thread);

  ClearProfileVisitor clear_profile(isolate);
  sample_block_buffer->VisitSamples(&clear_profile);
}

#endif  // !PRODUCT

}  // namespace dart
