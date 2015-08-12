// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/profiler_service.h"

#include "vm/growable_array.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/scope_timer.h"

namespace dart {

DECLARE_FLAG(int, profile_depth);
DECLARE_FLAG(int, profile_period);

DEFINE_FLAG(bool, trace_profiler, false, "Trace profiler.");

class DeoptimizedCodeSet : public ZoneAllocated {
 public:
  explicit DeoptimizedCodeSet(Isolate* isolate)
      : previous_(
            GrowableObjectArray::ZoneHandle(isolate->deoptimized_code_array())),
        current_(GrowableObjectArray::ZoneHandle(
            previous_.IsNull() ? GrowableObjectArray::null() :
                                 GrowableObjectArray::New())) {
  }

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
      OS::Print("Updating isolate deoptimized code array: "
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
    for (intptr_t i = 0; array.Length(); i++) {
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


ProfileFunction::ProfileFunction(Kind kind,
                  const char* name,
                  const Function& function,
                  const intptr_t table_index)
    : kind_(kind),
      name_(name),
      function_(Function::ZoneHandle(function.raw())),
      table_index_(table_index),
      profile_codes_(0),
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

void ProfileFunction::Tick(bool exclusive, intptr_t inclusive_serial) {
  if (exclusive) {
    exclusive_ticks_++;
  }
  // Fall through and tick inclusive count too.
  if (inclusive_serial_ == inclusive_serial) {
    // Already ticked.
    return;
  }
  inclusive_serial_ = inclusive_serial;
  inclusive_ticks_++;
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
  obj.AddPropertyF("inclusiveTicks", "%" Pd "", inclusive_ticks());
  obj.AddPropertyF("exclusiveTicks", "%" Pd "", exclusive_ticks());
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


ProfileCodeAddress::ProfileCodeAddress(uword pc)
    : pc_(pc),
      exclusive_ticks_(0),
      inclusive_ticks_(0) {
}


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
      address_ticks_(0) {
}


void ProfileCode::AdjustExtent(uword start, uword end) {
  if (start < start_) {
    start_ = start;
  }
  if (end > end_) {
    end_ = end;
  }
  ASSERT(start_ < end_);
}


bool ProfileCode::Overlaps(const ProfileCode* other) const {
  ASSERT(other != NULL);
  return other->Contains(start_)   ||
         other->Contains(end_ - 1) ||
         Contains(other->start())  ||
         Contains(other->end() - 1);
}


bool ProfileCode::IsOptimizedDart() const {
  return !code_.IsNull() && code_.is_optimized();
}


void ProfileCode::SetName(const char* name) {
  if (name == NULL) {
    name_ = NULL;
  }
  intptr_t len = strlen(name);
  name_ = Thread::Current()->zone()->Alloc<const char>(len + 1);
  strncpy(const_cast<char*>(name_), name, len);
  const_cast<char*>(name_)[len] = '\0';
}


void ProfileCode::GenerateAndSetSymbolName(const char* prefix) {
  const intptr_t kBuffSize = 512;
  char buff[kBuffSize];
  OS::SNPrint(&buff[0], kBuffSize-1, "%s [%" Px ", %" Px ")",
              prefix, start(), end());
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
  obj.AddPropertyF("inclusiveTicks", "%" Pd "", inclusive_ticks());
  obj.AddPropertyF("exclusiveTicks", "%" Pd "", exclusive_ticks());
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
      ticks.AddValueF("%" Pd "", entry.exclusive_ticks());
      ticks.AddValueF("%" Pd "", entry.inclusive_ticks());
    }
  }
}


class ProfileFunctionTable : public ZoneAllocated {
 public:
  ProfileFunctionTable()
      : null_function_(Function::ZoneHandle()),
        table_(8),
        unknown_function_(NULL) {
    unknown_function_ = Add(ProfileFunction::kUnknownFunction,
                            "<unknown Dart function>");
  }

  ProfileFunction* LookupOrAdd(const Function& function) {
    ASSERT(!function.IsNull());
    ProfileFunction* profile_function = Lookup(function);
    if (profile_function != NULL) {
      return profile_function;
    }
    return Add(function);
  }

  intptr_t LookupIndex(const Function& function) {
    ASSERT(!function.IsNull());
    for (intptr_t i = 0; i < table_.length(); i++) {
      ProfileFunction* profile_function = table_[i];
      if (profile_function->function() == function.raw()) {
        return i;
      }
    }
    return -1;
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

  intptr_t length() const {
    return table_.length();
  }

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
        new ProfileFunction(kind,
                            name,
                            null_function_,
                            table_.length());
    table_.Add(profile_function);
    return profile_function;
  }

  ProfileFunction* Add(const Function& function) {
    ASSERT(Lookup(function) == NULL);
    ProfileFunction* profile_function =
        new ProfileFunction(ProfileFunction::kDartFunction,
                            NULL,
                            function,
                            table_.length());
    table_.Add(profile_function);
    return profile_function;
  }

  ProfileFunction* Lookup(const Function& function) {
    ASSERT(!function.IsNull());
    intptr_t index = LookupIndex(function);
    if (index == -1) {
      return NULL;
    }
    return table_[index];
  }

  const Function& null_function_;
  ZoneGrowableArray<ProfileFunction*> table_;
  ProfileFunction* unknown_function_;
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
    const Object& obj = Object::Handle(code_.owner());
    if (obj.IsFunction()) {
      const String& user_name = String::Handle(code_.PrettyName());
      function = table->LookupOrAdd(Function::Cast(obj));
      SetName(user_name.ToCString());
    } else {
      // A stub.
      const String& user_name = String::Handle(code_.PrettyName());
      function = table->AddStub(start(), user_name.ToCString());
      SetName(user_name.ToCString());
    }
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
      } else if (VMTag::IsVMTag(start()) ||
                 VMTag::IsRuntimeEntryTag(start()) ||
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


typedef bool (*RangeCompare)(uword pc, uword region_start, uword region_end);

class ProfileCodeTable : public ZoneAllocated {
 public:
  ProfileCodeTable()
      : table_(8) {
  }

  intptr_t length() const { return table_.length(); }

  ProfileCode* At(intptr_t index) const {
    ASSERT(index >= 0);
    ASSERT(index < length());
    return table_[index];
  }

  // Find the table index to the ProfileCode containing pc.
  // Returns < 0 if not found.
  intptr_t FindCodeIndexForPC(uword pc) const {
    intptr_t index = FindCodeIndex(pc, &CompareLowerBound);
    if (index == length()) {
      // Not present.
      return -1;
    }
    const ProfileCode* code = At(index);
    if (!code->Contains(pc)) {
      // Not present.
      return -1;
    }
    // Found at index.
    return index;
  }

  ProfileCode* FindCodeForPC(uword pc) const {
    intptr_t index = FindCodeIndexForPC(pc);
    if (index < 0) {
      return NULL;
    }
    return At(index);
  }

  // Insert |new_code| into the table. Returns the table index where |new_code|
  // was inserted. Will merge with an overlapping ProfileCode if one is present.
  intptr_t InsertCode(ProfileCode* new_code) {
    const uword start = new_code->start();
    const uword end = new_code->end();
    const intptr_t length = table_.length();
    if (length == 0) {
      table_.Add(new_code);
      return length;
    }
    // Determine the correct place to insert or merge |new_code| into table.
    intptr_t lo = FindCodeIndex(start, &CompareLowerBound);
    intptr_t hi = FindCodeIndex(end - 1, &CompareUpperBound);
    // TODO(johnmccutchan): Simplify below logic.
    if ((lo == length) && (hi == length)) {
      lo = length - 1;
    }
    if (lo == length) {
      ProfileCode* code = At(hi);
      if (code->Overlaps(new_code)) {
        HandleOverlap(code, new_code, start, end);
        return hi;
      }
      table_.Add(new_code);
      return length;
    } else if (hi == length) {
      ProfileCode* code = At(lo);
      if (code->Overlaps(new_code)) {
        HandleOverlap(code, new_code, start, end);
        return lo;
      }
      table_.Add(new_code);
      return length;
    } else if (lo == hi) {
      ProfileCode* code = At(lo);
      if (code->Overlaps(new_code)) {
        HandleOverlap(code, new_code, start, end);
        return lo;
      }
      table_.InsertAt(lo, new_code);
      return lo;
    } else {
      ProfileCode* code = At(lo);
      if (code->Overlaps(new_code)) {
        HandleOverlap(code, new_code, start, end);
        return lo;
      }
      code = At(hi);
      if (code->Overlaps(new_code)) {
        HandleOverlap(code, new_code, start, end);
        return hi;
      }
      table_.InsertAt(hi, new_code);
      return hi;
    }
    UNREACHABLE();
  }

 private:
  intptr_t FindCodeIndex(uword pc, RangeCompare comparator) const {
    ASSERT(comparator != NULL);
    intptr_t count = table_.length();
    intptr_t first = 0;
    while (count > 0) {
      intptr_t it = first;
      intptr_t step = count / 2;
      it += step;
      const ProfileCode* code = At(it);
      if (comparator(pc, code->start(), code->end())) {
        first = ++it;
        count -= (step + 1);
      } else {
        count = step;
      }
    }
    return first;
  }

  static bool CompareUpperBound(uword pc, uword start, uword end) {
    return pc >= end;
  }

  static bool CompareLowerBound(uword pc, uword start, uword end) {
    return end <= pc;
  }

  void HandleOverlap(ProfileCode* existing, ProfileCode* code,
                     uword start, uword end) {
    // We should never see overlapping Dart code regions.
    ASSERT(existing->kind() != ProfileCode::kDartCode);
    // We should never see overlapping Tag code regions.
    ASSERT(existing->kind() != ProfileCode::kTagCode);
    // When code regions overlap, they should be of the same kind.
    ASSERT(existing->kind() == code->kind());
    existing->AdjustExtent(start, end);
  }

  void VerifyOrder() {
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

  void VerifyOverlap() {
    const intptr_t length = table_.length();
    for (intptr_t i = 0; i < length; i++) {
      ProfileCode* a = table_[i];
      for (intptr_t j = i+1; j < length; j++) {
        ProfileCode* b = table_[j];
        ASSERT(!a->Contains(b->start()) &&
               !a->Contains(b->end() - 1) &&
               !b->Contains(a->start()) &&
               !b->Contains(a->end() - 1));
      }
    }
  }

  ZoneGrowableArray<ProfileCode*> table_;
};


ProfileTrieNode::ProfileTrieNode(intptr_t table_index)
    : table_index_(table_index),
      count_(0),
      children_(0) {
  ASSERT(table_index_ >= 0);
}


ProfileTrieNode::~ProfileTrieNode() {
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
      : ProfileTrieNode(table_index) {
  }

  void PrintToJSONArray(JSONArray* array) const {
    ASSERT(array != NULL);
    // Write CodeRegion index.
    array->AddValue(table_index());
    // Write count.
    array->AddValue(count());
    // Write number of children.
    intptr_t child_count = NumChildren();
    array->AddValue(child_count);
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
      : code_index_(index),
        ticks_(0) {
  }

  intptr_t index() const {
    return code_index_;
  }

  void Tick() {
    ticks_++;
  }

  intptr_t ticks() const {
    return ticks_;
  }

 private:
  intptr_t code_index_;
  intptr_t ticks_;
};


class ProfileFunctionTrieNode : public ProfileTrieNode {
 public:
  explicit ProfileFunctionTrieNode(intptr_t table_index)
      : ProfileTrieNode(table_index),
        code_objects_(1) {
  }

  void PrintToJSONArray(JSONArray* array) const {
    ASSERT(array != NULL);
    // Write CodeRegion index.
    array->AddValue(table_index());
    // Write count.
    array->AddValue(count());
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

  ProfileBuilder(Isolate* isolate,
                 SampleFilter* filter,
                 Profile::TagOrder tag_order,
                 intptr_t extra_tags,
                 Profile* profile)
      : isolate_(isolate),
        vm_isolate_(Dart::vm_isolate()),
        filter_(filter),
        tag_order_(tag_order),
        extra_tags_(extra_tags),
        profile_(profile),
        deoptimized_code_(new DeoptimizedCodeSet(isolate)),
        null_code_(Code::ZoneHandle()),
        null_function_(Function::ZoneHandle()),
        tick_functions_(false),
        inclusive_tree_(false),
        samples_(NULL),
        info_kind_(kNone) {
    ASSERT(profile_ != NULL);
  }

  void Build() {
    ScopeTimer sw("ProfileBuilder::Build", FLAG_trace_profiler);
    FilterSamples();

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
    return (frame_index == 0) && (sample->first_frame_executing() ||
                                  sample->IsAllocationSample());
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

  void FilterSamples() {
    ScopeTimer sw("ProfileBuilder::FilterSamples", FLAG_trace_profiler);
    MutexLocker profiler_data_lock(isolate_->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate_->profiler_data();
    if (profiler_data == NULL) {
      return;
    }
    SampleBuffer* sample_buffer = profiler_data->sample_buffer();
    if (sample_buffer == NULL) {
      return;
    }
    samples_ = sample_buffer->BuildProcessedSampleBuffer(filter_);
    profile_->sample_count_ = samples_->length();
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
    for (intptr_t sample_index = 0;
         sample_index < samples_->length();
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
      for (intptr_t frame_index = 0;
           frame_index < sample->length();
           frame_index++) {
        const uword pc = sample->At(frame_index);
        ASSERT(pc != 0);
        ProfileCode* code = RegisterProfileCode(pc, timestamp);
        ASSERT(code != NULL);
        code->Tick(pc, IsExecutingFrame(sample, frame_index), sample_index);
      }
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
    for (intptr_t sample_index = 0;
         sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileCodeTrieNode* current = root;
      current->Tick();

      // VM & User tags.
      current = AppendTags(sample->vm_tag(), sample->user_tag(), current);

      ResetKind();

      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current);
      }

      // Walk the sampled PCs.
      Code& code = Code::Handle();
      for (intptr_t frame_index = sample->length() - 1;
           frame_index >= 0;
           frame_index--) {
        ASSERT(sample->At(frame_index) != 0);
        intptr_t index =
            GetProfileCodeIndex(sample->At(frame_index), sample->timestamp());
        ASSERT(index >= 0);
        ProfileCode* profile_code =
            GetProfileCode(sample->At(frame_index), sample->timestamp());
        ASSERT(profile_code->code_table_index() == index);
        code ^= profile_code->code();
        current = AppendKind(code, current);
        current = current->GetChild(index);
        current->Tick();
      }
    }
  }

  void BuildExclusiveCodeTrie(ProfileCodeTrieNode* root) {
    ScopeTimer sw("ProfileBuilder::BuildExclusiveCodeTrie",
                  FLAG_trace_profiler);
    for (intptr_t sample_index = 0;
         sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileCodeTrieNode* current = root;
      current->Tick();

      // VM & User tags.
      current = AppendTags(sample->vm_tag(), sample->user_tag(), current);

      ResetKind();

      // Walk the sampled PCs.
      Code& code = Code::Handle();
      for (intptr_t frame_index = 0;
           frame_index < sample->length();
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
          current->Tick();
        }
        current = AppendKind(code, current);
      }
      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current);
      }
    }
  }

  void BuildFunctionTrie(Profile::TrieKind kind) {
    ProfileFunctionTrieNode* root =
        new ProfileFunctionTrieNode(
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
    for (intptr_t sample_index = 0;
         sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileFunctionTrieNode* current = root;
      current->Tick();

      // VM & User tags.
      current = AppendTags(sample->vm_tag(), sample->user_tag(), current);

      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current);
      }

      // Walk the sampled PCs.
      for (intptr_t frame_index = sample->length() - 1;
           frame_index >= 0;
           frame_index--) {
        ASSERT(sample->At(frame_index) != 0);
        current = ProcessFrame(current, sample_index, sample, frame_index);
      }
    }
  }

  void BuildExclusiveFunctionTrie(ProfileFunctionTrieNode* root) {
    ScopeTimer sw("ProfileBuilder::BuildExclusiveFunctionTrie",
                  FLAG_trace_profiler);
    ASSERT(tick_functions_);
    for (intptr_t sample_index = 0;
         sample_index < samples_->length();
         sample_index++) {
      ProcessedSample* sample = samples_->At(sample_index);

      // Tick the root.
      ProfileFunctionTrieNode* current = root;
      current->Tick();

      // VM & User tags.
      current = AppendTags(sample->vm_tag(), sample->user_tag(), current);

      ResetKind();

      // Walk the sampled PCs.
      for (intptr_t frame_index = 0;
           frame_index < sample->length();
           frame_index++) {
        ASSERT(sample->At(frame_index) != 0);
        current = ProcessFrame(current, sample_index, sample, frame_index);
      }

      // Truncated tag.
      if (sample->truncated()) {
        current = AppendTruncatedTag(current);
        InclusiveTickTruncatedTag();
      }
    }
  }

  ProfileFunctionTrieNode* ProcessFrame(
      ProfileFunctionTrieNode* current,
      intptr_t sample_index,
      ProcessedSample* sample,
      intptr_t frame_index) {
    const uword pc = sample->At(frame_index);
    ProfileCode* profile_code = GetProfileCode(pc,
                                               sample->timestamp());
    ProfileFunction* function = profile_code->function();
    ASSERT(function != NULL);
    const intptr_t code_index = profile_code->code_table_index();
    ASSERT(profile_code != NULL);
    const Code& code = Code::ZoneHandle(profile_code->code());
    GrowableArray<Function*> inlined_functions;
    if (!code.IsNull()) {
      intptr_t offset = pc - code.EntryPoint();
      code.GetInlinedFunctionsAt(offset, &inlined_functions);
    }
    if (code.IsNull() || (inlined_functions.length() == 0)) {
      // No inlined functions.
      if (inclusive_tree_) {
        current = AppendKind(code, current);
      }
      current = ProcessFunction(current,
                                sample_index,
                                sample,
                                frame_index,
                                function,
                                code_index);
      if (!inclusive_tree_) {
        current = AppendKind(code, current);
      }
      return current;
    }

    ASSERT(code.is_optimized());

    if (inclusive_tree_) {
      for (intptr_t i = inlined_functions.length() - 1; i >= 0; i--) {
        Function* inlined_function = inlined_functions[i];
        ASSERT(inlined_function != NULL);
        ASSERT(!inlined_function->IsNull());
        const bool inliner = i == (inlined_functions.length() - 1);
        if (inliner) {
          current = AppendKind(code, current);
        }
        current = ProcessInlinedFunction(current,
                                         sample_index,
                                         sample,
                                         frame_index,
                                         inlined_function,
                                         code_index);
        if (inliner) {
          current = AppendKind(kInlineStart, current);
        }
      }
      current = AppendKind(kInlineFinish, current);
    } else {
      // Append the inlined children.
      current = AppendKind(kInlineFinish, current);
      for (intptr_t i = 0; i < inlined_functions.length(); i++) {
        Function* inlined_function = inlined_functions[i];
        ASSERT(inlined_function != NULL);
        ASSERT(!inlined_function->IsNull());
        const bool inliner = i == (inlined_functions.length() - 1);
        if (inliner) {
          current = AppendKind(kInlineStart, current);
        }
        current = ProcessInlinedFunction(current,
                                         sample_index,
                                         sample,
                                         frame_index + i,
                                         inlined_function,
                                         code_index);
        if (inliner) {
          current = AppendKind(code, current);
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
      Function* inlined_function,
      intptr_t code_index) {
    ProfileFunctionTable* function_table = profile_->functions_;
    ProfileFunction* function = function_table->LookupOrAdd(*inlined_function);
    ASSERT(function != NULL);
    return ProcessFunction(current,
                           sample_index,
                           sample,
                           frame_index,
                           function,
                           code_index);
  }

  bool ShouldTickNode(ProcessedSample* sample, intptr_t frame_index) {
    if (frame_index != 0) {
      return true;
    }
    // Only tick the first frame's node, if we are executing OR
    // vm tags have been emitted.
    return IsExecutingFrame(sample, frame_index) || vm_tags_emitted();
  }

  ProfileFunctionTrieNode* ProcessFunction(ProfileFunctionTrieNode* current,
                                           intptr_t sample_index,
                                           ProcessedSample* sample,
                                           intptr_t frame_index,
                                           ProfileFunction* function,
                                           intptr_t code_index) {
    if (tick_functions_) {
      function->Tick(IsExecutingFrame(sample, frame_index), sample_index);
    }
    function->AddProfileCode(code_index);
    current = current->GetChild(function->table_index());
    if (ShouldTickNode(sample, frame_index)) {
      current->Tick();
    }
    current->AddCodeObjectIndex(code_index);
    return current;
  }

  // Tick the truncated tag's inclusive tick count.
  void InclusiveTickTruncatedTag() {
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
                                     ProfileCodeTrieNode* current) {
    intptr_t user_tag_index = GetProfileCodeTagIndex(user_tag);
    if (user_tag_index >= 0) {
      current = current->GetChild(user_tag_index);
      current->Tick();
    }
    return current;
  }

  ProfileCodeTrieNode* AppendTruncatedTag(ProfileCodeTrieNode* current) {
    intptr_t truncated_tag_index =
        GetProfileCodeTagIndex(VMTag::kTruncatedTagId);
    ASSERT(truncated_tag_index >= 0);
    current = current->GetChild(truncated_tag_index);
    current->Tick();
    return current;
  }

  ProfileCodeTrieNode* AppendVMTag(uword vm_tag,
                                   ProfileCodeTrieNode* current) {
    if (VMTag::IsNativeEntryTag(vm_tag)) {
      // Insert a dummy kNativeTagId node.
      intptr_t tag_index = GetProfileCodeTagIndex(VMTag::kNativeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else if (VMTag::IsRuntimeEntryTag(vm_tag)) {
      // Insert a dummy kRuntimeTagId node.
      intptr_t tag_index = GetProfileCodeTagIndex(VMTag::kRuntimeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else {
      intptr_t tag_index = GetProfileCodeTagIndex(vm_tag);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    }
    return current;
  }

  ProfileCodeTrieNode* AppendSpecificNativeRuntimeEntryVMTag(
      uword vm_tag, ProfileCodeTrieNode* current) {
    // Only Native and Runtime entries have a second VM tag.
    if (!VMTag::IsNativeEntryTag(vm_tag) &&
        !VMTag::IsRuntimeEntryTag(vm_tag)) {
      return current;
    }
    intptr_t tag_index = GetProfileCodeTagIndex(vm_tag);
    current = current->GetChild(tag_index);
    // Give the tag a tick.
    current->Tick();
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
                                  ProfileCodeTrieNode* current) {
    if (!TagsEnabled(ProfilerService::kCodeTransitionTagsBit)) {
      // Only emit if debug tags are requested.
      return current;
    }
    if (kind != info_kind_) {
      info_kind_ = kind;
      intptr_t tag_index = GetProfileCodeTagIndex(ProfileInfoKindToVMTag(kind));
      ASSERT(tag_index >= 0);
      current = current->GetChild(tag_index);
      current->Tick();
    }
    return current;
  }

  ProfileCodeTrieNode* AppendKind(const Code& code,
                                  ProfileCodeTrieNode* current) {
    if (code.IsNull()) {
      return AppendKind(kNone, current);
    } else if (code.is_optimized()) {
      return AppendKind(kOptimized, current);
    } else {
      return AppendKind(kUnoptimized, current);
    }
  }

  ProfileCodeTrieNode* AppendVMTags(uword vm_tag,
                                    ProfileCodeTrieNode* current) {
    current = AppendVMTag(vm_tag, current);
    current = AppendSpecificNativeRuntimeEntryVMTag(vm_tag, current);
    return current;
  }

  ProfileCodeTrieNode* AppendTags(uword vm_tag,
                                  uword user_tag,
                                  ProfileCodeTrieNode* current) {
    // None.
    if (tag_order() == Profile::kNoTags) {
      return current;
    }
    // User first.
    if ((tag_order() == Profile::kUserVM) ||
        (tag_order() == Profile::kUser)) {
      current = AppendUserTag(user_tag, current);
      // Only user.
      if (tag_order() == Profile::kUser) {
        return current;
      }
      return AppendVMTags(vm_tag, current);
    }
    // VM first.
    ASSERT((tag_order() == Profile::kVMUser) ||
           (tag_order() == Profile::kVM));
    current = AppendVMTags(vm_tag, current);
    // Only VM.
    if (tag_order() == Profile::kVM) {
      return current;
    }
    return AppendUserTag(user_tag, current);
  }

  // ProfileFunctionTrieNode
  void ResetKind() {
    info_kind_ = kNone;
  }

  ProfileFunctionTrieNode* AppendKind(ProfileInfoKind kind,
                                      ProfileFunctionTrieNode* current) {
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
      current->Tick();
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendKind(const Code& code,
                                      ProfileFunctionTrieNode* current) {
    if (code.IsNull()) {
      return AppendKind(kNone, current);
    } else if (code.is_optimized()) {
      return AppendKind(kOptimized, current);
    } else {
      return AppendKind(kUnoptimized, current);
    }
  }

  ProfileFunctionTrieNode* AppendUserTag(uword user_tag,
                                         ProfileFunctionTrieNode* current) {
    intptr_t user_tag_index = GetProfileFunctionTagIndex(user_tag);
    if (user_tag_index >= 0) {
      current = current->GetChild(user_tag_index);
      current->Tick();
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendTruncatedTag(
      ProfileFunctionTrieNode* current) {
    intptr_t truncated_tag_index =
        GetProfileFunctionTagIndex(VMTag::kTruncatedTagId);
    ASSERT(truncated_tag_index >= 0);
    current = current->GetChild(truncated_tag_index);
    current->Tick();
    return current;
  }

  ProfileFunctionTrieNode* AppendVMTag(uword vm_tag,
                                       ProfileFunctionTrieNode* current) {
    if (VMTag::IsNativeEntryTag(vm_tag)) {
      // Insert a dummy kNativeTagId node.
      intptr_t tag_index = GetProfileFunctionTagIndex(VMTag::kNativeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else if (VMTag::IsRuntimeEntryTag(vm_tag)) {
      // Insert a dummy kRuntimeTagId node.
      intptr_t tag_index = GetProfileFunctionTagIndex(VMTag::kRuntimeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else {
      intptr_t tag_index = GetProfileFunctionTagIndex(vm_tag);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendSpecificNativeRuntimeEntryVMTag(
      uword vm_tag, ProfileFunctionTrieNode* current) {
    // Only Native and Runtime entries have a second VM tag.
    if (!VMTag::IsNativeEntryTag(vm_tag) &&
        !VMTag::IsRuntimeEntryTag(vm_tag)) {
      return current;
    }
    intptr_t tag_index = GetProfileFunctionTagIndex(vm_tag);
    current = current->GetChild(tag_index);
    // Give the tag a tick.
    current->Tick();
    return current;
  }

  ProfileFunctionTrieNode* AppendVMTags(uword vm_tag,
                                    ProfileFunctionTrieNode* current) {
    current = AppendVMTag(vm_tag, current);
    current = AppendSpecificNativeRuntimeEntryVMTag(vm_tag, current);
    return current;
  }

  ProfileFunctionTrieNode* AppendTags(uword vm_tag,
                                      uword user_tag,
                                      ProfileFunctionTrieNode* current) {
    // None.
    if (tag_order() == Profile::kNoTags) {
      return current;
    }
    // User first.
    if ((tag_order() == Profile::kUserVM) ||
        (tag_order() == Profile::kUser)) {
      current = AppendUserTag(user_tag, current);
      // Only user.
      if (tag_order() == Profile::kUser) {
        return current;
      }
      return AppendVMTags(vm_tag, current);
    }
    // VM first.
    ASSERT((tag_order() == Profile::kVMUser) ||
           (tag_order() == Profile::kVM));
    current = AppendVMTags(vm_tag, current);
    // Only VM.
    if (tag_order() == Profile::kVM) {
      return current;
    }
    return AppendUserTag(user_tag, current);
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
    ProfileCode* code = new ProfileCode(ProfileCode::kTagCode,
                                        tag,
                                        tag + 1,
                                        0,
                                        null_code_);
    index = tag_table->InsertCode(code);
    ASSERT(index >= 0);
  }

  ProfileCode* CreateProfileCodeReused(uword pc) {
    ProfileCode* code = new ProfileCode(ProfileCode::kReusedCode,
                                        pc,
                                        pc + 1,
                                        0,
                                        null_code_);
    return code;
  }

  ProfileCode* CreateProfileCode(uword pc) {
    const intptr_t kDartCodeAlignment = OS::PreferredCodeAlignment();
    const intptr_t kDartCodeAlignmentMask = ~(kDartCodeAlignment - 1);
    Code& code = Code::Handle(isolate_);

    // Check current isolate for pc.
    if (isolate_->heap()->CodeContains(pc)) {
      code ^= Code::LookupCode(pc);
      if (!code.IsNull()) {
        deoptimized_code_->Add(code);
        return new ProfileCode(ProfileCode::kDartCode,
                              code.EntryPoint(),
                              code.EntryPoint() + code.Size(),
                              code.compile_timestamp(),
                              code);
      }
      return new ProfileCode(ProfileCode::kCollectedCode,
                            pc,
                            (pc & kDartCodeAlignmentMask) + kDartCodeAlignment,
                            0,
                            code);
    }

    // Check VM isolate for pc.
    if (vm_isolate_->heap()->CodeContains(pc)) {
      code ^= Code::LookupCodeInVmIsolate(pc);
      if (!code.IsNull()) {
        return new ProfileCode(ProfileCode::kDartCode,
                              code.EntryPoint(),
                              code.EntryPoint() + code.Size(),
                              code.compile_timestamp(),
                              code);
      }
      return new ProfileCode(ProfileCode::kCollectedCode,
                            pc,
                            (pc & kDartCodeAlignmentMask) + kDartCodeAlignment,
                            0,
                            code);
    }

    // Check NativeSymbolResolver for pc.
    uintptr_t native_start = 0;
    char* native_name = NativeSymbolResolver::LookupSymbolName(pc,
                                                               &native_start);
    if (native_name == NULL) {
      // No native name found.
      return new ProfileCode(ProfileCode::kNativeCode,
                            pc,
                            pc + 1,
                            0,
                            code);
    }
    ASSERT(pc >= native_start);
    ProfileCode* profile_code =
        new ProfileCode(ProfileCode::kNativeCode,
                       native_start,
                       pc + 1,
                       0,
                       code);
    profile_code->SetName(native_name);
    free(native_name);
    return profile_code;
  }

  ProfileCode* RegisterProfileCode(uword pc, int64_t timestamp) {
    ProfileCodeTable* live_table = profile_->live_code_;
    ProfileCodeTable* dead_table = profile_->dead_code_;

    ProfileCode* code = live_table->FindCodeForPC(pc);
    if (code == NULL) {
      // Code not found.
      intptr_t index = live_table->InsertCode(CreateProfileCode(pc));
      ASSERT(index >= 0);
      code = live_table->At(index);
      if (code->compile_timestamp() <= timestamp) {
        // Code was compiled before sample was taken.
        return code;
      }
      // Code was compiled after the sample was taken. Insert code object into
      // the dead code table.
      index = dead_table->InsertCode(CreateProfileCodeReused(pc));
      ASSERT(index >= 0);
      return dead_table->At(index);
    }
    // Existing code found.
    if (code->compile_timestamp() <= timestamp) {
      // Code was compiled before sample was taken.
      return code;
    }
    // Code was compiled after the sample was taken. Check if we have an entry
    // in the dead code table.
    code = dead_table->FindCodeForPC(pc);
    if (code != NULL) {
      return code;
    }
    // Create a new dead code entry.
    intptr_t index = dead_table->InsertCode(CreateProfileCodeReused(pc));
    ASSERT(index >= 0);
    return dead_table->At(index);
  }

  Profile::TagOrder tag_order() const {
    return tag_order_;
  }

  bool vm_tags_emitted() const {
    return (tag_order_ == Profile::kUserVM) ||
           (tag_order_ == Profile::kVMUser) ||
           (tag_order_ == Profile::kVM);
  }

  bool TagsEnabled(intptr_t extra_tags_bits) const {
    return (extra_tags_ & extra_tags_bits) != 0;
  }

  Isolate* isolate_;
  Isolate* vm_isolate_;
  SampleFilter* filter_;
  Profile::TagOrder tag_order_;
  intptr_t extra_tags_;
  Profile* profile_;
  DeoptimizedCodeSet* deoptimized_code_;
  const Code& null_code_;
  const Function& null_function_;
  bool tick_functions_;
  bool inclusive_tree_;

  ProcessedSampleBuffer* samples_;
  ProfileInfoKind info_kind_;
};


Profile::Profile(Isolate* isolate)
    : isolate_(isolate),
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


void Profile::Build(SampleFilter* filter,
                    TagOrder tag_order,
                    intptr_t extra_tags) {
  ProfileBuilder builder(isolate_, filter, tag_order, extra_tags, this);
  builder.Build();
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


void Profile::PrintJSON(JSONStream* stream) {
  ScopeTimer sw("Profile::PrintJSON", FLAG_trace_profiler);
  JSONObject obj(stream);
  obj.AddProperty("type", "_CpuProfile");
  obj.AddProperty("samplePeriod",
                  static_cast<intptr_t>(FLAG_profile_period));
  obj.AddProperty("stackDepth",
                  static_cast<intptr_t>(FLAG_profile_depth));
  obj.AddProperty("sampleCount", sample_count());
  obj.AddProperty("timeSpan", MicrosecondsToSeconds(GetTimeSpan()));
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


void ProfilerService::PrintJSONImpl(Isolate* isolate,
                                    JSONStream* stream,
                                    Profile::TagOrder tag_order,
                                    intptr_t extra_tags,
                                    SampleFilter* filter) {
  // Disable profile interrupts while processing the buffer.
  Profiler::EndExecution(isolate);

  {
    MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    if (profiler_data == NULL) {
      stream->PrintError(kFeatureDisabled, NULL);
      return;
    }
  }

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    profile.Build(filter, tag_order, extra_tags);
    profile.PrintJSON(stream);
  }

  // Enable profile interrupts.
  Profiler::BeginExecution(isolate);
}


class NoAllocationSampleFilter : public SampleFilter {
 public:
  explicit NoAllocationSampleFilter(Isolate* isolate)
      : SampleFilter(isolate) {
  }

  bool FilterSample(Sample* sample) {
    return !sample->is_allocation_sample();
  }
};


void ProfilerService::PrintJSON(JSONStream* stream,
                                Profile::TagOrder tag_order,
                                intptr_t extra_tags) {
  Isolate* isolate = Isolate::Current();
  NoAllocationSampleFilter filter(isolate);
  PrintJSONImpl(isolate, stream, tag_order, extra_tags, &filter);
}


class ClassAllocationSampleFilter : public SampleFilter {
 public:
  ClassAllocationSampleFilter(Isolate* isolate, const Class& cls)
      : SampleFilter(isolate),
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
                                          const Class& cls) {
  Isolate* isolate = Isolate::Current();
  ClassAllocationSampleFilter filter(isolate, cls);
  PrintJSONImpl(isolate, stream, tag_order, kNoExtraTags, &filter);
}


void ProfilerService::ClearSamples() {
  Isolate* isolate = Isolate::Current();

  // Disable profile interrupts while processing the buffer.
  Profiler::EndExecution(isolate);

  MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  ASSERT(sample_buffer != NULL);

  ClearProfileVisitor clear_profile(isolate);
  sample_buffer->VisitSamples(&clear_profile);

  // Enable profile interrupts.
  Profiler::BeginExecution(isolate);
}

}  // namespace dart
