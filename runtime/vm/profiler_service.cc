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

// Forward declarations.
class CodeRegion;
class ProfileFunction;
class ProfileFunctionTable;


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

class ProfileFunction : public ZoneAllocated {
 public:
  enum Kind {
    kDartFunction,    // Dart function.
    kNativeFunction,  // Synthetic function for Native (C/C++).
    kTagFunction,     // Synthetic function for a VM or User tag.
    kStubFunction,    // Synthetic function for stub code.
    kUnkownFunction,  // A singleton function for unknown objects.
  };
  ProfileFunction(Kind kind,
                  const char* name,
                  const Function& function,
                  const intptr_t table_index)
      : kind_(kind),
        name_(name),
        function_(Function::ZoneHandle(function.raw())),
        table_index_(table_index),
        code_objects_(new ZoneGrowableArray<intptr_t>()),
        exclusive_ticks_(0),
        inclusive_ticks_(0),
        inclusive_tick_serial_(0) {
    ASSERT((kind_ != kDartFunction) || !function_.IsNull());
    ASSERT((kind_ != kDartFunction) || (table_index_ >= 0));
    ASSERT(code_objects_->length() == 0);
  }

  const char* name() const {
    ASSERT(name_ != NULL);
    return name_;
  }

  RawFunction* function() const {
    return function_.raw();
  }

  intptr_t index() const {
    return table_index_;
  }

  Kind kind() const {
    return kind_;
  }

  const char* KindToCString(Kind kind) {
    switch (kind) {
      case kDartFunction:
        return "Dart";
      case kNativeFunction:
        return "Native";
      case kTagFunction:
        return "Tag";
      case kStubFunction:
        return "Stub";
      case kUnkownFunction:
        return "Collected";
      default:
        UNIMPLEMENTED();
        return "";
    }
  }

  void Dump() {
    const char* n = (name_ == NULL) ? "<NULL>" : name_;
    const char* fn = "";
    if (!function_.IsNull()) {
      fn = function_.ToQualifiedCString();
    }
    OS::Print("%s %s [%s]", KindToCString(kind()), n, fn);
  }

  void AddCodeObjectIndex(intptr_t index) {
    for (intptr_t i = 0; i < code_objects_->length(); i++) {
      if ((*code_objects_)[i] == index) {
        return;
      }
    }
    code_objects_->Add(index);
  }

  intptr_t inclusive_ticks() const {
    return inclusive_ticks_;
  }
  void inc_inclusive_ticks() {
    inclusive_ticks_++;
  }
  intptr_t exclusive_ticks() const {
    return exclusive_ticks_;
  }

  void Tick(bool exclusive, intptr_t serial) {
    // Assert that exclusive ticks are never passed a valid serial number.
    ASSERT((exclusive && (serial == -1)) || (!exclusive && (serial != -1)));
    if (!exclusive && (inclusive_tick_serial_ == serial)) {
      // We've already given this object an inclusive tick for this sample.
      return;
    }
    if (exclusive) {
      exclusive_ticks_++;
    } else {
      inclusive_ticks_++;
      // Mark the last serial we ticked the inclusive count.
      inclusive_tick_serial_ = serial;
    }
  }

  void PrintToJSONObject(JSONObject* func) {
    func->AddProperty("type", "@Function");
    func->AddProperty("name", name());
    func->AddProperty("_kind", KindToCString(kind()));
  }

  void PrintToJSONArray(JSONArray* functions) {
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
      for (intptr_t i = 0; i < code_objects_->length(); i++) {
        intptr_t code_index = (*code_objects_)[i];
        codes.AddValue(code_index);
      }
    }
  }

 private:
  const Kind kind_;
  const char* name_;
  const Function& function_;
  const intptr_t table_index_;
  ZoneGrowableArray<intptr_t>* code_objects_;
  intptr_t exclusive_ticks_;
  intptr_t inclusive_ticks_;
  intptr_t inclusive_tick_serial_;
};


class ProfileFunctionTable : public ValueObject {
 public:
  ProfileFunctionTable()
      : null_function_(Function::ZoneHandle()),
        table_(new ZoneGrowableArray<ProfileFunction*>()),
        unknown_function_(NULL) {
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
    for (intptr_t i = 0; i < table_->length(); i++) {
      ProfileFunction* profile_function = (*table_)[i];
      if (profile_function->function() == function.raw()) {
        return i;
      }
    }
    return -1;
  }

  ProfileFunction* GetUnknown() {
    if (unknown_function_ == NULL) {
      // Construct.
      unknown_function_ = Add(ProfileFunction::kUnkownFunction,
                              "<unknown Dart function>");
    }
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

  intptr_t Length() const {
    return table_->length();
  }

  ProfileFunction* At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < Length());
    return (*table_)[i];
  }

 private:
  ProfileFunction* Add(ProfileFunction::Kind kind, const char* name) {
    ASSERT(kind != ProfileFunction::kDartFunction);
    ASSERT(name != NULL);
    ProfileFunction* profile_function =
        new ProfileFunction(kind,
                            name,
                            null_function_,
                            table_->length());
    table_->Add(profile_function);
    return profile_function;
  }

  ProfileFunction* Add(const Function& function) {
    ASSERT(Lookup(function) == NULL);
    ProfileFunction* profile_function =
        new ProfileFunction(ProfileFunction::kDartFunction,
                            NULL,
                            function,
                            table_->length());
    table_->Add(profile_function);
    return profile_function;
  }

  ProfileFunction* Lookup(const Function& function) {
    ASSERT(!function.IsNull());
    intptr_t index = LookupIndex(function);
    if (index == -1) {
      return NULL;
    }
    return (*table_)[index];
  }

  const Function& null_function_;
  ZoneGrowableArray<ProfileFunction*>* table_;

  ProfileFunction* unknown_function_;
};


struct AddressEntry {
  uword pc;
  intptr_t exclusive_ticks;
  intptr_t inclusive_ticks;

  void tick(bool exclusive) {
    if (exclusive) {
      exclusive_ticks++;
    } else {
      inclusive_ticks++;
    }
  }
};

typedef bool (*RegionCompare)(uword pc, uword region_start, uword region_end);

// A contiguous address region that holds code. Each CodeRegion has a "kind"
// which describes the type of code contained inside the region. Each
// region covers the following interval: [start, end).
class CodeRegion : public ZoneAllocated {
 public:
  enum Kind {
    kDartCode,       // Live Dart code.
    kCollectedCode,  // Dead Dart code.
    kNativeCode,     // Native code.
    kReusedCode,     // Dead Dart code that has been reused by new kDartCode.
    kTagCode,        // A special kind of code representing a tag.
  };

  CodeRegion(Kind kind,
             uword start,
             uword end,
             int64_t timestamp,
             const Code& code)
      : kind_(kind),
        start_(start),
        end_(end),
        inclusive_ticks_(0),
        exclusive_ticks_(0),
        inclusive_tick_serial_(0),
        name_(NULL),
        compile_timestamp_(timestamp),
        creation_serial_(0),
        code_(Code::ZoneHandle(code.raw())),
        profile_function_(NULL),
        code_table_index_(-1) {
    ASSERT(start_ < end_);
    // Ensure all kDartCode have a valid code_ object.
    ASSERT((kind != kDartCode) || (!code_.IsNull()));
  }

  uword start() const { return start_; }
  void set_start(uword start) {
    start_ = start;
  }

  uword end() const { return end_; }
  void set_end(uword end) {
    end_ = end;
  }

  void AdjustExtent(uword start, uword end) {
    if (start < start_) {
      start_ = start;
    }
    if (end > end_) {
      end_ = end;
    }
    ASSERT(start_ < end_);
  }

  bool contains(uword pc) const {
    return (pc >= start_) && (pc < end_);
  }

  bool overlaps(const CodeRegion* other) const {
    ASSERT(other != NULL);
    return other->contains(start_)   ||
           other->contains(end_ - 1) ||
           contains(other->start())  ||
           contains(other->end() - 1);
  }

  intptr_t creation_serial() const { return creation_serial_; }
  void set_creation_serial(intptr_t serial) {
    creation_serial_ = serial;
  }
  int64_t compile_timestamp() const { return compile_timestamp_; }
  void set_compile_timestamp(int64_t timestamp) {
    compile_timestamp_ = timestamp;
  }

  intptr_t inclusive_ticks() const { return inclusive_ticks_; }
  void set_inclusive_ticks(intptr_t inclusive_ticks) {
    inclusive_ticks_ = inclusive_ticks;
  }
  void inc_inclusive_ticks() {
    inclusive_ticks_++;
  }

  intptr_t exclusive_ticks() const { return exclusive_ticks_; }
  void set_exclusive_ticks(intptr_t exclusive_ticks) {
    exclusive_ticks_ = exclusive_ticks;
  }

  const char* name() const { return name_; }
  void SetName(const char* name) {
    if (name == NULL) {
      name_ = NULL;
    }
    intptr_t len = strlen(name);
    name_ = Isolate::Current()->current_zone()->Alloc<const char>(len + 1);
    strncpy(const_cast<char*>(name_), name, len);
    const_cast<char*>(name_)[len] = '\0';
  }

  bool IsOptimizedDart() const {
    return !code_.IsNull() && code_.is_optimized();
  }

  RawCode* code() const {
    return code_.raw();
  }

  ProfileFunction* SetFunctionAndName(ProfileFunctionTable* table) {
    ASSERT(profile_function_ == NULL);

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
          if (start() == VMTag::kRootTagId) {
            SetName("Root");
          } else {
            ASSERT(start() == VMTag::kTruncatedTagId);
            SetName("[Truncated]");
          }
        }
      }
      function = table->AddTag(start(), name());
    } else {
      UNREACHABLE();
    }
    ASSERT(function != NULL);
    // Register this CodeRegion with this function.
    function->AddCodeObjectIndex(code_table_index());
    profile_function_ = function;
    return profile_function_;
  }

  ProfileFunction* function() const {
    ASSERT(profile_function_ != NULL);
    return profile_function_;
  }

  void set_code_table_index(intptr_t code_table_index) {
    ASSERT(code_table_index_ == -1);
    ASSERT(code_table_index != -1);
    code_table_index_ = code_table_index;
  }
  intptr_t code_table_index() const {
    ASSERT(code_table_index_ != -1);
    return code_table_index_;
  }

  Kind kind() const { return kind_; }

  static const char* KindToCString(Kind kind) {
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

  void DebugPrint() const {
    OS::Print("%s [%" Px ", %" Px ") %" Pd " %" Pd64 "\n",
              KindToCString(kind_),
              start(),
              end(),
              creation_serial_,
              compile_timestamp_);
  }

  void Tick(uword pc, bool exclusive, intptr_t serial) {
    // Assert that exclusive ticks are never passed a valid serial number.
    ASSERT((exclusive && (serial == -1)) || (!exclusive && (serial != -1)));
    if (!exclusive && (inclusive_tick_serial_ == serial)) {
      // We've already given this code object an inclusive tick for this sample.
      return;
    }
    // Tick the code object.
    if (exclusive) {
      exclusive_ticks_++;
    } else {
      inclusive_ticks_++;
      // Mark the last serial we ticked the inclusive count.
      inclusive_tick_serial_ = serial;
    }
    TickAddress(pc, exclusive);
  }

  void PrintNativeCode(JSONObject* profile_code_obj) {
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
      profile_function_->PrintToJSONObject(&func);
    }
  }

  void PrintCollectedCode(JSONObject* profile_code_obj) {
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
      profile_function_->PrintToJSONObject(&func);
    }
  }

  void PrintOverwrittenCode(JSONObject* profile_code_obj) {
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
      ASSERT(profile_function_ != NULL);
      profile_function_->PrintToJSONObject(&func);
    }
  }

  void PrintTagCode(JSONObject* profile_code_obj) {
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
      ASSERT(profile_function_ != NULL);
      profile_function_->PrintToJSONObject(&func);
    }
  }

  void PrintToJSONArray(JSONArray* codes) {
    JSONObject obj(codes);
    obj.AddProperty("kind", KindToCString(kind()));
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
      for (intptr_t i = 0; i < address_table_.length(); i++) {
        const AddressEntry& entry = address_table_[i];
        ticks.AddValueF("%" Px "", entry.pc);
        ticks.AddValueF("%" Pd "", entry.exclusive_ticks);
        ticks.AddValueF("%" Pd "", entry.inclusive_ticks);
      }
    }
  }

 private:
  void TickAddress(uword pc, bool exclusive) {
    const intptr_t length = address_table_.length();
    intptr_t i = 0;
    for (; i < length; i++) {
      AddressEntry& entry = address_table_[i];
      if (entry.pc == pc) {
        // Tick the address entry.
        entry.tick(exclusive);
        return;
      }
      if (entry.pc > pc) {
        break;
      }
    }
    // New address, add entry.
    AddressEntry entry;
    entry.pc = pc;
    entry.exclusive_ticks = 0;
    entry.inclusive_ticks = 0;
    entry.tick(exclusive);
    if (i < length) {
      // Insert at i.
      address_table_.InsertAt(i, entry);
    } else {
      // Add to end.
      address_table_.Add(entry);
    }
  }

  void GenerateAndSetSymbolName(const char* prefix) {
    const intptr_t kBuffSize = 512;
    char buff[kBuffSize];
    OS::SNPrint(&buff[0], kBuffSize-1, "%s [%" Px ", %" Px ")",
                prefix, start(), end());
    SetName(buff);
  }

  // CodeRegion kind.
  const Kind kind_;
  // CodeRegion start address.
  uword start_;
  // CodeRegion end address.
  uword end_;
  // Inclusive ticks.
  intptr_t inclusive_ticks_;
  // Exclusive ticks.
  intptr_t exclusive_ticks_;
  // Inclusive tick serial number, ensures that each CodeRegion is only given
  // a single inclusive tick per sample.
  intptr_t inclusive_tick_serial_;
  // Name of code region.
  const char* name_;
  // The compilation timestamp associated with this code region.
  int64_t compile_timestamp_;
  // Serial number at which this CodeRegion was created.
  intptr_t creation_serial_;
  // Dart code object (may be null).
  const Code& code_;
  // Pointer to ProfileFunction.
  ProfileFunction* profile_function_;
  // Final code table index.
  intptr_t code_table_index_;
  ZoneGrowableArray<AddressEntry> address_table_;
  DISALLOW_COPY_AND_ASSIGN(CodeRegion);
};


// A sorted table of CodeRegions. Does not allow for overlap.
class CodeRegionTable : public ValueObject {
 public:
  enum TickResult {
    kTicked = 0,     // CodeRegion found and ticked.
    kNotFound = -1,   // No CodeRegion found.
    kNewerCode = -2,  // CodeRegion found but it was compiled after sample.
  };

  CodeRegionTable() :
      code_region_table_(new ZoneGrowableArray<CodeRegion*>(64)) {
  }

  // Ticks the CodeRegion containing pc if it is alive at timestamp.
  TickResult Tick(uword pc, bool exclusive, intptr_t serial,
                  int64_t timestamp) {
    intptr_t index = FindIndex(pc);
    if (index < 0) {
      // Not found.
      return kNotFound;
    }
    ASSERT(index < code_region_table_->length());
    CodeRegion* region = At(index);
    if (region->compile_timestamp() > timestamp) {
      // Compiled after tick.
      return kNewerCode;
    }
    region->Tick(pc, exclusive, serial);
    return kTicked;
  }

  // Table length.
  intptr_t Length() const { return code_region_table_->length(); }

  // Get the CodeRegion at index.
  CodeRegion* At(intptr_t index) const {
    return (*code_region_table_)[index];
  }

  // Find the table index to the CodeRegion containing pc.
  // Returns < 0 if not found.
  intptr_t FindIndex(uword pc) const {
    intptr_t index = FindRegionIndex(pc, &CompareLowerBound);
    const CodeRegion* code_region = NULL;
    if (index == code_region_table_->length()) {
      // Not present.
      return -1;
    }
    code_region = At(index);
    if (code_region->contains(pc)) {
      // Found at index.
      return index;
    }
    return -2;
  }

  // Insert code_region into the table. Returns the table index where the
  // CodeRegion was inserted. Will merge with an overlapping CodeRegion if
  // one is present.
  intptr_t InsertCodeRegion(CodeRegion* code_region) {
    const uword start = code_region->start();
    const uword end = code_region->end();
    const intptr_t length = code_region_table_->length();
    if (length == 0) {
      code_region_table_->Add(code_region);
      return length;
    }
    // Determine the correct place to insert or merge code_region into table.
    intptr_t lo = FindRegionIndex(start, &CompareLowerBound);
    intptr_t hi = FindRegionIndex(end - 1, &CompareUpperBound);
    // TODO(johnmccutchan): Simplify below logic.
    if ((lo == length) && (hi == length)) {
      lo = length - 1;
    }
    if (lo == length) {
      CodeRegion* region = At(hi);
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return hi;
      }
      code_region_table_->Add(code_region);
      return length;
    } else if (hi == length) {
      CodeRegion* region = At(lo);
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return lo;
      }
      code_region_table_->Add(code_region);
      return length;
    } else if (lo == hi) {
      CodeRegion* region = At(lo);
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return lo;
      }
      code_region_table_->InsertAt(lo, code_region);
      return lo;
    } else {
      CodeRegion* region = At(lo);
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return lo;
      }
      region = At(hi);
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return hi;
      }
      code_region_table_->InsertAt(hi, code_region);
      return hi;
    }
    UNREACHABLE();
  }

  void Verify() {
    VerifyOrder();
    VerifyOverlap();
  }

  void DebugPrint() {
    OS::Print("Dumping CodeRegionTable:\n");
    for (intptr_t i = 0; i < code_region_table_->length(); i++) {
      CodeRegion* region = At(i);
      region->DebugPrint();
    }
  }

 private:
  intptr_t FindRegionIndex(uword pc, RegionCompare comparator) const {
    ASSERT(comparator != NULL);
    intptr_t count = code_region_table_->length();
    intptr_t first = 0;
    while (count > 0) {
      intptr_t it = first;
      intptr_t step = count / 2;
      it += step;
      const CodeRegion* code_region = At(it);
      if (comparator(pc, code_region->start(), code_region->end())) {
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

  void HandleOverlap(CodeRegion* region, CodeRegion* code_region,
                     uword start, uword end) {
    // We should never see overlapping Dart code regions.
    ASSERT(region->kind() != CodeRegion::kDartCode);
    // We should never see overlapping Tag code regions.
    ASSERT(region->kind() != CodeRegion::kTagCode);
    // When code regions overlap, they should be of the same kind.
    ASSERT(region->kind() == code_region->kind());
    region->AdjustExtent(start, end);
  }

  void VerifyOrder() {
    const intptr_t length = code_region_table_->length();
    if (length == 0) {
      return;
    }
    uword last = (*code_region_table_)[0]->end();
    for (intptr_t i = 1; i < length; i++) {
      CodeRegion* a = (*code_region_table_)[i];
      ASSERT(last <= a->start());
      last = a->end();
    }
  }

  void VerifyOverlap() {
    const intptr_t length = code_region_table_->length();
    for (intptr_t i = 0; i < length; i++) {
      CodeRegion* a = (*code_region_table_)[i];
      for (intptr_t j = i+1; j < length; j++) {
        CodeRegion* b = (*code_region_table_)[j];
        ASSERT(!a->contains(b->start()) &&
               !a->contains(b->end() - 1) &&
               !b->contains(a->start()) &&
               !b->contains(a->end() - 1));
      }
    }
  }

  ZoneGrowableArray<CodeRegion*>* code_region_table_;
};


class CodeRegionTableBuilder : public SampleVisitor {
 public:
  CodeRegionTableBuilder(Isolate* isolate,
                         CodeRegionTable* live_code_table,
                         CodeRegionTable* dead_code_table,
                         CodeRegionTable* tag_code_table,
                         DeoptimizedCodeSet* deoptimized_code)
      : SampleVisitor(isolate),
        live_code_table_(live_code_table),
        dead_code_table_(dead_code_table),
        tag_code_table_(tag_code_table),
        isolate_(isolate),
        vm_isolate_(Dart::vm_isolate()),
        null_code_(Code::ZoneHandle()),
        deoptimized_code_(deoptimized_code) {
    ASSERT(live_code_table_ != NULL);
    ASSERT(dead_code_table_ != NULL);
    ASSERT(tag_code_table_ != NULL);
    ASSERT(isolate_ != NULL);
    ASSERT(vm_isolate_ != NULL);
    ASSERT(null_code_.IsNull());
    frames_ = 0;
    min_time_ = kMaxInt64;
    max_time_ = 0;
  }

  void VisitSample(Sample* sample) {
    int64_t timestamp = sample->timestamp();
    if (timestamp > max_time_) {
      max_time_ = timestamp;
    }
    if (timestamp < min_time_) {
      min_time_ = timestamp;
    }
    // Make sure VM tag is created.
    if (VMTag::IsNativeEntryTag(sample->vm_tag())) {
      CreateTag(VMTag::kNativeTagId);
    } else if (VMTag::IsRuntimeEntryTag(sample->vm_tag())) {
      CreateTag(VMTag::kRuntimeTagId);
    }
    CreateTag(sample->vm_tag());
    // Make sure user tag is created.
    CreateUserTag(sample->user_tag());
    // Exclusive tick for top frame if we aren't sampled from an exit frame.
    if (!sample->exit_frame_sample()) {
      Tick(sample->At(0), true, timestamp);
    }
    // Inclusive tick for all frames.
    for (intptr_t i = 0; i < FLAG_profile_depth; i++) {
      if (sample->At(i) == 0) {
        break;
      }
      frames_++;
      Tick(sample->At(i), false, timestamp);
    }
  }

  intptr_t frames() const { return frames_; }

  intptr_t  TimeDeltaMicros() const {
    return static_cast<intptr_t>(max_time_ - min_time_);
  }
  int64_t  max_time() const { return max_time_; }

 private:
  void CreateTag(uword tag) {
    intptr_t index = tag_code_table_->FindIndex(tag);
    if (index >= 0) {
      // Already created.
      return;
    }
    CodeRegion* region = new CodeRegion(CodeRegion::kTagCode,
                                        tag,
                                        tag + 1,
                                        0,
                                        null_code_);
    index = tag_code_table_->InsertCodeRegion(region);
    ASSERT(index >= 0);
    region->set_creation_serial(visited());
  }

  void CreateUserTag(uword tag) {
    if (tag == 0) {
      // None set.
      return;
    }
    return CreateTag(tag);
  }

  void Tick(uword pc, bool exclusive, int64_t timestamp) {
    CodeRegionTable::TickResult r;
    intptr_t serial = exclusive ? -1 : visited();
    r = live_code_table_->Tick(pc, exclusive, serial, timestamp);
    if (r == CodeRegionTable::kTicked) {
      // Live code found and ticked.
      return;
    }
    if (r == CodeRegionTable::kNewerCode) {
      // Code has been overwritten by newer code.
      // Update shadow table of dead code regions.
      r = dead_code_table_->Tick(pc, exclusive, serial, timestamp);
      ASSERT(r != CodeRegionTable::kNewerCode);
      if (r == CodeRegionTable::kTicked) {
        // Dead code found and ticked.
        return;
      }
      ASSERT(r == CodeRegionTable::kNotFound);
      CreateAndTickDeadCodeRegion(pc, exclusive, serial);
      return;
    }
    // Create new live CodeRegion.
    ASSERT(r == CodeRegionTable::kNotFound);
    CodeRegion* region = CreateCodeRegion(pc);
    region->set_creation_serial(visited());
    intptr_t index = live_code_table_->InsertCodeRegion(region);
    ASSERT(index >= 0);
    region = live_code_table_->At(index);
    if (region->compile_timestamp() <= timestamp) {
      region->Tick(pc, exclusive, serial);
      return;
    }
    // We have created a new code region but it's for a CodeRegion
    // compiled after the sample.
    ASSERT(region->kind() == CodeRegion::kDartCode);
    CreateAndTickDeadCodeRegion(pc, exclusive, serial);
  }

  void CreateAndTickDeadCodeRegion(uword pc, bool exclusive, intptr_t serial) {
    // Need to create dead code.
    CodeRegion* region = new CodeRegion(CodeRegion::kReusedCode,
                                        pc,
                                        pc + 1,
                                        0,
                                        null_code_);
    intptr_t index = dead_code_table_->InsertCodeRegion(region);
    region->set_creation_serial(visited());
    ASSERT(index >= 0);
    dead_code_table_->At(index)->Tick(pc, exclusive, serial);
  }

  CodeRegion* CreateCodeRegion(uword pc) {
    const intptr_t kDartCodeAlignment = OS::PreferredCodeAlignment();
    const intptr_t kDartCodeAlignmentMask = ~(kDartCodeAlignment - 1);
    Code& code = Code::Handle(isolate_);
    // Check current isolate for pc.
    if (isolate_->heap()->CodeContains(pc)) {
      code ^= Code::LookupCode(pc);
      if (!code.IsNull()) {
        deoptimized_code_->Add(code);
        return new CodeRegion(CodeRegion::kDartCode,
                              code.EntryPoint(),
                              code.EntryPoint() + code.Size(),
                              code.compile_timestamp(),
                              code);
      }
      return new CodeRegion(CodeRegion::kCollectedCode,
                            pc,
                            (pc & kDartCodeAlignmentMask) + kDartCodeAlignment,
                            0,
                            code);
    }
    // Check VM isolate for pc.
    if (vm_isolate_->heap()->CodeContains(pc)) {
      code ^= Code::LookupCodeInVmIsolate(pc);
      if (!code.IsNull()) {
        return new CodeRegion(CodeRegion::kDartCode,
                              code.EntryPoint(),
                              code.EntryPoint() + code.Size(),
                              code.compile_timestamp(),
                              code);
      }
      return new CodeRegion(CodeRegion::kCollectedCode,
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
      return new CodeRegion(CodeRegion::kNativeCode,
                            pc,
                            pc + 1,
                            0,
                            code);
    }
    ASSERT(pc >= native_start);
    CodeRegion* code_region =
        new CodeRegion(CodeRegion::kNativeCode,
                       native_start,
                       pc + 1,
                       0,
                       code);
    code_region->SetName(native_name);
    free(native_name);
    return code_region;
  }

  intptr_t frames_;
  int64_t min_time_;
  int64_t max_time_;
  CodeRegionTable* live_code_table_;
  CodeRegionTable* dead_code_table_;
  CodeRegionTable* tag_code_table_;
  Isolate* isolate_;
  Isolate* vm_isolate_;
  const Code& null_code_;
  DeoptimizedCodeSet* deoptimized_code_;
};


class CodeRegionFunctionMapper : public ValueObject {
 public:
  CodeRegionFunctionMapper(Isolate* isolate,
                           CodeRegionTable* live_code_table,
                           CodeRegionTable* dead_code_table,
                           CodeRegionTable* tag_code_table,
                           ProfileFunctionTable* function_table)
      : isolate_(isolate),
        live_code_table_(live_code_table),
        dead_code_table_(dead_code_table),
        tag_code_table_(tag_code_table),
        function_table_(function_table) {
    ASSERT(isolate_ != NULL);
    ASSERT(live_code_table_ != NULL);
    ASSERT(dead_code_table_ != NULL);
    ASSERT(tag_code_table_ != NULL);
    dead_code_table_offset_ = live_code_table_->Length();
    tag_code_table_offset_ = dead_code_table_offset_ +
                             dead_code_table_->Length();

    const Code& null_code = Code::ZoneHandle();

    // Create the truncated tag.
    intptr_t truncated_index =
        tag_code_table_->FindIndex(VMTag::kTruncatedTagId);
    ASSERT(truncated_index < 0);
    CodeRegion* truncated =
        new CodeRegion(CodeRegion::kTagCode,
                       VMTag::kTruncatedTagId,
                       VMTag::kTruncatedTagId + 1,
                       0,
                       null_code);
    truncated_index = tag_code_table_->InsertCodeRegion(truncated);
    ASSERT(truncated_index >= 0);
    truncated->set_creation_serial(0);

    // Create the root tag.
    intptr_t root_index = tag_code_table_->FindIndex(VMTag::kRootTagId);
    ASSERT(root_index < 0);
    CodeRegion* root = new CodeRegion(CodeRegion::kTagCode,
                                      VMTag::kRootTagId,
                                      VMTag::kRootTagId + 1,
                                      0,
                                      null_code);
    root_index = tag_code_table_->InsertCodeRegion(root);
    ASSERT(root_index >= 0);
    root->set_creation_serial(0);
  }

  void Map() {
    // Calculate final indexes in code table for each CodeRegion.
    for (intptr_t i = 0; i < live_code_table_->Length(); i++) {
      const intptr_t index = i;
      CodeRegion* region = live_code_table_->At(i);
      ASSERT(region != NULL);
      region->set_code_table_index(index);
    }

    for (intptr_t i = 0; i < dead_code_table_->Length(); i++) {
      const intptr_t index = dead_code_table_offset_ + i;
      CodeRegion* region = dead_code_table_->At(i);
      ASSERT(region != NULL);
      region->set_code_table_index(index);
    }

    for (intptr_t i = 0; i < tag_code_table_->Length(); i++) {
      const intptr_t index = tag_code_table_offset_ + i;
      CodeRegion* region = tag_code_table_->At(i);
      ASSERT(region != NULL);
      region->set_code_table_index(index);
    }

    // Associate a ProfileFunction with each CodeRegion.
    for (intptr_t i = 0; i < live_code_table_->Length(); i++) {
      CodeRegion* region = live_code_table_->At(i);
      ASSERT(region != NULL);
      region->SetFunctionAndName(function_table_);
    }

    for (intptr_t i = 0; i < dead_code_table_->Length(); i++) {
      CodeRegion* region = dead_code_table_->At(i);
      ASSERT(region != NULL);
      region->SetFunctionAndName(function_table_);
    }

    for (intptr_t i = 0; i < tag_code_table_->Length(); i++) {
      CodeRegion* region = tag_code_table_->At(i);
      ASSERT(region != NULL);
      region->SetFunctionAndName(function_table_);
    }
  }

 private:
  Isolate* isolate_;
  CodeRegionTable* live_code_table_;
  CodeRegionTable* dead_code_table_;
  CodeRegionTable* tag_code_table_;
  ProfileFunctionTable* function_table_;
  intptr_t dead_code_table_offset_;
  intptr_t tag_code_table_offset_;
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


class ProfileFunctionTrieNode : public ZoneAllocated {
 public:
  explicit ProfileFunctionTrieNode(intptr_t profile_function_table_index)
      : profile_function_table_index_(profile_function_table_index),
        count_(0),
        code_objects_(new ZoneGrowableArray<ProfileFunctionTrieNodeCode>()) {
  }

  void Tick() {
    count_++;
  }

  intptr_t count() const {
    return count_;
  }

  intptr_t profile_function_table_index() const {
    return profile_function_table_index_;
  }


  ProfileFunctionTrieNode* GetChild(intptr_t child_index) {
    const intptr_t length = children_.length();
    intptr_t i = 0;
    while (i < length) {
      ProfileFunctionTrieNode* child = children_[i];
      if (child->profile_function_table_index() == child_index) {
        return child;
      }
      if (child->profile_function_table_index() > child_index) {
        break;
      }
      i++;
    }
    // Add new ProfileFunctionTrieNode, sorted by index.
    ProfileFunctionTrieNode* child =
        new ProfileFunctionTrieNode(child_index);
    if (i < length) {
      // Insert at i.
      children_.InsertAt(i, child);
    } else {
      // Add to end.
      children_.Add(child);
    }
    return child;
  }

  void AddCodeObjectIndex(intptr_t index) {
    for (intptr_t i = 0; i < code_objects_->length(); i++) {
      ProfileFunctionTrieNodeCode& code_object = (*code_objects_)[i];
      if (code_object.index() == index) {
        code_object.Tick();
        return;
      }
    }
    ProfileFunctionTrieNodeCode code_object(index);
    code_object.Tick();
    code_objects_->Add(code_object);
  }

  // This should only be called after the trie is completely built.
  void SortByCount() {
    code_objects_->Sort(ProfileFunctionTrieNodeCodeCompare);
    children_.Sort(ProfileFunctionTrieNodeCompare);
    intptr_t child_count = children_.length();
    // Recurse.
    for (intptr_t i = 0; i < child_count; i++) {
      children_[i]->SortByCount();
    }
  }

  void PrintToJSONArray(JSONArray* array) const {
    ASSERT(array != NULL);
    // Write CodeRegion index.
    array->AddValue(profile_function_table_index_);
    // Write count.
    array->AddValue(count_);
    // Write number of code objects.
    intptr_t code_count = code_objects_->length();
    array->AddValue(code_count);
    // Write each code object index and ticks.
    for (intptr_t i = 0; i < code_count; i++) {
      array->AddValue((*code_objects_)[i].index());
      array->AddValue((*code_objects_)[i].ticks());
    }
    // Write number of children.
    intptr_t child_count = children_.length();
    array->AddValue(child_count);
    // Recurse.
    for (intptr_t i = 0; i < child_count; i++) {
      children_[i]->PrintToJSONArray(array);
    }
  }

 private:
  static int ProfileFunctionTrieNodeCodeCompare(
      const ProfileFunctionTrieNodeCode* a,
      const ProfileFunctionTrieNodeCode* b) {
    ASSERT(a != NULL);
    ASSERT(b != NULL);
    return b->ticks() - a->ticks();
  }

  static int ProfileFunctionTrieNodeCompare(ProfileFunctionTrieNode* const* a,
                                            ProfileFunctionTrieNode* const* b) {
    ASSERT(a != NULL);
    ASSERT(b != NULL);
    return (*b)->count() - (*a)->count();
  }

  const intptr_t profile_function_table_index_;
  intptr_t count_;
  ZoneGrowableArray<ProfileFunctionTrieNode*> children_;
  ZoneGrowableArray<ProfileFunctionTrieNodeCode>* code_objects_;
};


class ProfileFunctionTrieBuilder : public SampleVisitor {
 public:
  ProfileFunctionTrieBuilder(Isolate* isolate,
                             CodeRegionTable* live_code_table,
                             CodeRegionTable* dead_code_table,
                             CodeRegionTable* tag_code_table,
                             ProfileFunctionTable* function_table)
      : SampleVisitor(isolate),
        live_code_table_(live_code_table),
        dead_code_table_(dead_code_table),
        tag_code_table_(tag_code_table),
        function_table_(function_table),
        inclusive_tree_(false),
        trace_(false),
        trace_code_filter_(NULL) {
    ASSERT(live_code_table_ != NULL);
    ASSERT(dead_code_table_ != NULL);
    ASSERT(tag_code_table_ != NULL);
    ASSERT(function_table_ != NULL);
    set_tag_order(ProfilerService::kUserVM);

    // Verify that the truncated tag exists.
    ASSERT(tag_code_table_->FindIndex(VMTag::kTruncatedTagId) >= 0);

    // Verify that the root tag exists.
    intptr_t root_index = tag_code_table_->FindIndex(VMTag::kRootTagId);
    ASSERT(root_index >= 0);

    // Setup root.
    CodeRegion* region = tag_code_table_->At(root_index);
    ASSERT(region != NULL);
    ProfileFunction* function = region->function();
    ASSERT(function != NULL);

    exclusive_root_ = new ProfileFunctionTrieNode(function->index());
    inclusive_root_ = new ProfileFunctionTrieNode(function->index());
  }

  void VisitSample(Sample* sample) {
    inclusive_tree_ = false;
    ProcessSampleExclusive(sample);
    inclusive_tree_ = true;
    ProcessSampleInclusive(sample);
  }

  ProfileFunctionTrieNode* exclusive_root() const {
    return exclusive_root_;
  }

  ProfileFunctionTrieNode* inclusive_root() const {
    return inclusive_root_;
  }

  ProfilerService::TagOrder tag_order() const {
    return tag_order_;
  }

  bool vm_tags_emitted() const {
    return (tag_order_ == ProfilerService::kUserVM) ||
           (tag_order_ == ProfilerService::kVMUser) ||
           (tag_order_ == ProfilerService::kVM);
  }

  void set_tag_order(ProfilerService::TagOrder tag_order) {
    tag_order_ = tag_order;
  }

 private:
  void ProcessSampleInclusive(Sample* sample) {
    // Give the root a tick.
    inclusive_root_->Tick();
    ProfileFunctionTrieNode* current = inclusive_root_;
    current = AppendTags(sample, current);
    if (sample->truncated_trace()) {
      InclusiveTickTruncatedTag();
      current = AppendTruncatedTag(current);
    }
    // Walk the sampled PCs.
    for (intptr_t i = FLAG_profile_depth - 1; i >= 0; i--) {
      if (sample->At(i) == 0) {
        continue;
      }
      current = ProcessPC(sample->At(i),
                          sample->timestamp(),
                          current,
                          visited(),
                          (i == 0),
                          sample->exit_frame_sample() && (i == 0),
                          sample->missing_frame_inserted());
    }
  }

  void ProcessSampleExclusive(Sample* sample) {
    // Give the root a tick.
    exclusive_root_->Tick();
    ProfileFunctionTrieNode* current = exclusive_root_;
    current = AppendTags(sample, current);
    // Walk the sampled PCs.
    for (intptr_t i = 0; i < FLAG_profile_depth; i++) {
      if (sample->At(i) == 0) {
        break;
      }
      current = ProcessPC(sample->At(i),
                          sample->timestamp(),
                          current,
                          visited(),
                          (i == 0),
                          sample->exit_frame_sample() && (i == 0),
                          sample->missing_frame_inserted());
    }
    if (sample->truncated_trace()) {
      current = AppendTruncatedTag(current);
    }
  }

  ProfileFunctionTrieNode* AppendUserTag(Sample* sample,
                                         ProfileFunctionTrieNode* current) {
    intptr_t user_tag_index = FindTagIndex(sample->user_tag());
    if (user_tag_index >= 0) {
      current = current->GetChild(user_tag_index);
      // Give the tag a tick.
      current->Tick();
    }
    return current;
  }


  ProfileFunctionTrieNode* AppendTruncatedTag(
      ProfileFunctionTrieNode* current) {
    intptr_t truncated_tag_index = FindTagIndex(VMTag::kTruncatedTagId);
    ASSERT(truncated_tag_index >= 0);
    current = current->GetChild(truncated_tag_index);
    current->Tick();
    return current;
  }

  void InclusiveTickTruncatedTag() {
    intptr_t index = tag_code_table_->FindIndex(VMTag::kTruncatedTagId);
    CodeRegion* region = tag_code_table_->At(index);
    ProfileFunction* function = region->function();
    function->inc_inclusive_ticks();
  }

  ProfileFunctionTrieNode* AppendVMTag(Sample* sample,
                                       ProfileFunctionTrieNode* current) {
    if (VMTag::IsNativeEntryTag(sample->vm_tag())) {
      // Insert a dummy kNativeTagId node.
      intptr_t tag_index = FindTagIndex(VMTag::kNativeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else if (VMTag::IsRuntimeEntryTag(sample->vm_tag())) {
      // Insert a dummy kRuntimeTagId node.
      intptr_t tag_index = FindTagIndex(VMTag::kRuntimeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else {
      intptr_t tag_index = FindTagIndex(sample->vm_tag());
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    }
    return current;
  }

  ProfileFunctionTrieNode* AppendSpecificNativeRuntimeEntryVMTag(
      Sample* sample, ProfileFunctionTrieNode* current) {
    // Only Native and Runtime entries have a second VM tag.
    if (!VMTag::IsNativeEntryTag(sample->vm_tag()) &&
        !VMTag::IsRuntimeEntryTag(sample->vm_tag())) {
      return current;
    }
    intptr_t tag_index = FindTagIndex(sample->vm_tag());
    current = current->GetChild(tag_index);
    // Give the tag a tick.
    current->Tick();
    return current;
  }

  ProfileFunctionTrieNode* AppendVMTags(Sample* sample,
                                        ProfileFunctionTrieNode* current) {
    current = AppendVMTag(sample, current);
    current = AppendSpecificNativeRuntimeEntryVMTag(sample, current);
    return current;
  }

  ProfileFunctionTrieNode* AppendTags(Sample* sample,
                                      ProfileFunctionTrieNode* current) {
    // None.
    if (tag_order() == ProfilerService::kNoTags) {
      return current;
    }
    // User first.
    if ((tag_order() == ProfilerService::kUserVM) ||
        (tag_order() == ProfilerService::kUser)) {
      current = AppendUserTag(sample, current);
      // Only user.
      if (tag_order() == ProfilerService::kUser) {
        return current;
      }
      return AppendVMTags(sample, current);
    }
    // VM first.
    ASSERT((tag_order() == ProfilerService::kVMUser) ||
           (tag_order() == ProfilerService::kVM));
    current = AppendVMTags(sample, current);
    // Only VM.
    if (tag_order() == ProfilerService::kVM) {
      return current;
    }
    return AppendUserTag(sample, current);
  }

  intptr_t FindTagIndex(uword tag) const {
    if (tag == 0) {
      UNREACHABLE();
      return -1;
    }
    intptr_t index = tag_code_table_->FindIndex(tag);
    if (index < 0) {
      UNREACHABLE();
      return -1;
    }
    ASSERT(index >= 0);
    CodeRegion* region = tag_code_table_->At(index);
    ASSERT(region->contains(tag));
    ProfileFunction* function = region->function();
    ASSERT(function != NULL);
    return function->index();
  }

  void Dump(ProfileFunctionTrieNode* current) {
    int current_index = current->profile_function_table_index();
    ProfileFunction* function = function_table_->At(current_index);
    function->Dump();
    OS::Print("\n");
  }

  ProfileFunctionTrieNode* ProcessPC(uword pc,
                                     int64_t timestamp,
                                     ProfileFunctionTrieNode* current,
                                     intptr_t inclusive_serial,
                                     bool top_frame,
                                     bool exit_frame,
                                     bool missing_frame_inserted) {
    CodeRegion* region = FindCodeObject(pc, timestamp);
    if (region == NULL) {
      return current;
    }
    const char* region_name = region->name();
    if (region_name == NULL) {
      region_name = "";
    }
    intptr_t code_index = region->code_table_index();
    const Code& code = Code::ZoneHandle(region->code());
    GrowableArray<Function*> inlined_functions;
    if (!code.IsNull()) {
      intptr_t offset = pc - code.EntryPoint();
      code.GetInlinedFunctionsAt(offset, &inlined_functions);
    }
    if (code.IsNull() || (inlined_functions.length() == 0)) {
      // No inlined functions.
      ProfileFunction* function = region->function();
      ASSERT(function != NULL);
      if (trace_) {
        OS::Print("[%" Px "] X - %s (%s)\n",
                  pc, function->name(), region_name);
      }
      current = ProcessFunction(function,
                                current,
                                inclusive_serial,
                                top_frame,
                                exit_frame,
                                code_index);
      if ((trace_code_filter_ != NULL) &&
          (strstr(region_name, trace_code_filter_) != NULL)) {
        trace_ = true;
        OS::Print("Tracing from: %" Px " [%s] ", pc,
                  missing_frame_inserted ? "INSERTED" : "");
        Dump(current);
      }
      return current;
    }

    if (inclusive_tree_) {
      for (intptr_t i = inlined_functions.length() - 1; i >= 0; i--) {
        Function* inlined_function = inlined_functions[i];
        ASSERT(inlined_function != NULL);
        ASSERT(!inlined_function->IsNull());
        current = ProcessInlinedFunction(inlined_function,
                                         current,
                                         inclusive_serial,
                                         top_frame,
                                         exit_frame,
                                         code_index);
        top_frame = false;
      }
    } else {
      for (intptr_t i = 0; i < inlined_functions.length(); i++) {
        Function* inlined_function = inlined_functions[i];
        ASSERT(inlined_function != NULL);
        ASSERT(!inlined_function->IsNull());
        const char* inline_name = inlined_function->ToQualifiedCString();
        if (trace_) {
          OS::Print("[%" Px "] %" Pd " - %s (%s)\n",
                  pc, i, inline_name, region_name);
        }
        current = ProcessInlinedFunction(inlined_function,
                                         current,
                                         inclusive_serial,
                                         top_frame,
                                         exit_frame,
                                         code_index);
        top_frame = false;
        if ((trace_code_filter_ != NULL) &&
            (strstr(region_name, trace_code_filter_) != NULL)) {
          trace_ = true;
          OS::Print("Tracing from: %" Px " [%s] ",
                    pc, missing_frame_inserted ? "INSERTED" : "");
          Dump(current);
        }
      }
    }

    return current;
  }

  ProfileFunctionTrieNode* ProcessInlinedFunction(
      Function* inlined_function,
      ProfileFunctionTrieNode* current,
      intptr_t inclusive_serial,
      bool top_frame,
      bool exit_frame,
      intptr_t code_index) {
    ProfileFunction* function =
        function_table_->LookupOrAdd(*inlined_function);
    ASSERT(function != NULL);
    return ProcessFunction(function,
                           current,
                           inclusive_serial,
                           top_frame,
                           exit_frame,
                           code_index);
  }

  ProfileFunctionTrieNode* ProcessFunction(ProfileFunction* function,
                                           ProfileFunctionTrieNode* current,
                                           intptr_t inclusive_serial,
                                           bool top_frame,
                                           bool exit_frame,
                                           intptr_t code_index) {
    const bool exclusive = top_frame && !exit_frame;
    if (!inclusive_tree_) {
      // We process functions for the inclusive and exclusive trees.
      // Only tick the function for the exclusive tree.
      function->Tick(exclusive, exclusive ? -1 : inclusive_serial);
    }
    function->AddCodeObjectIndex(code_index);
    current = current->GetChild(function->index());
    current->AddCodeObjectIndex(code_index);
    if (top_frame) {
      if (!exit_frame || vm_tags_emitted()) {
        // Only tick if this isn't an exit frame or VM tags are emitted.
        current->Tick();
      }
    } else {
      current->Tick();
    }
    return current;
  }

  CodeRegion* FindCodeObject(uword pc, int64_t timestamp) const {
    intptr_t index = live_code_table_->FindIndex(pc);
    if (index < 0) {
      return NULL;
    }
    CodeRegion* region = live_code_table_->At(index);
    ASSERT(region->contains(pc));
    if (region->compile_timestamp() > timestamp) {
      // Overwritten code, find in dead code table.
      index = dead_code_table_->FindIndex(pc);
      if (index < 0) {
        return NULL;
      }
      region = dead_code_table_->At(index);
      ASSERT(region->contains(pc));
      ASSERT(region->compile_timestamp() <= timestamp);
      return region;
    }
    ASSERT(region->compile_timestamp() <= timestamp);
    return region;
  }

  ProfilerService::TagOrder tag_order_;
  ProfileFunctionTrieNode* exclusive_root_;
  ProfileFunctionTrieNode* inclusive_root_;
  CodeRegionTable* live_code_table_;
  CodeRegionTable* dead_code_table_;
  CodeRegionTable* tag_code_table_;
  ProfileFunctionTable* function_table_;
  bool inclusive_tree_;
  bool trace_;
  const char* trace_code_filter_;
};


class CodeRegionTrieNode : public ZoneAllocated {
 public:
  explicit CodeRegionTrieNode(intptr_t code_region_index)
      : code_region_index_(code_region_index),
        count_(0),
        children_(new ZoneGrowableArray<CodeRegionTrieNode*>()) {
  }

  void Tick() {
    ASSERT(code_region_index_ >= 0);
    count_++;
  }

  intptr_t count() const {
    ASSERT(code_region_index_ >= 0);
    return count_;
  }

  intptr_t code_region_index() const {
    return code_region_index_;
  }

  ZoneGrowableArray<CodeRegionTrieNode*>& children() const {
    return *children_;
  }

  CodeRegionTrieNode* GetChild(intptr_t child_code_region_index) {
    const intptr_t length = children_->length();
    intptr_t i = 0;
    while (i < length) {
      CodeRegionTrieNode* child = (*children_)[i];
      if (child->code_region_index() == child_code_region_index) {
        return child;
      }
      if (child->code_region_index() > child_code_region_index) {
        break;
      }
      i++;
    }
    // Add new CodeRegion, sorted by CodeRegionTable index.
    CodeRegionTrieNode* child = new CodeRegionTrieNode(child_code_region_index);
    if (i < length) {
      // Insert at i.
      children_->InsertAt(i, child);
    } else {
      // Add to end.
      children_->Add(child);
    }
    return child;
  }

  // This should only be called after the trie is completely built.
  void SortByCount() {
    children_->Sort(CodeRegionTrieNodeCompare);
    ZoneGrowableArray<CodeRegionTrieNode*>& kids = children();
    intptr_t child_count = kids.length();
    // Recurse.
    for (intptr_t i = 0; i < child_count; i++) {
      kids[i]->SortByCount();
    }
  }

  void PrintToJSONArray(JSONArray* array) const {
    ASSERT(array != NULL);
    // Write CodeRegion index.
    array->AddValue(code_region_index_);
    // Write count.
    array->AddValue(count_);
    // Write number of children.
    ZoneGrowableArray<CodeRegionTrieNode*>& kids = children();
    intptr_t child_count = kids.length();
    array->AddValue(child_count);
    // Recurse.
    for (intptr_t i = 0; i < child_count; i++) {
      kids[i]->PrintToJSONArray(array);
    }
  }

 private:
  static int CodeRegionTrieNodeCompare(CodeRegionTrieNode* const* a,
                                       CodeRegionTrieNode* const* b) {
    ASSERT(a != NULL);
    ASSERT(b != NULL);
    return (*b)->count() - (*a)->count();
  }

  const intptr_t code_region_index_;
  intptr_t count_;
  ZoneGrowableArray<CodeRegionTrieNode*>* children_;
};


class CodeRegionTrieBuilder : public SampleVisitor {
 public:
  CodeRegionTrieBuilder(Isolate* isolate,
                        CodeRegionTable* live_code_table,
                        CodeRegionTable* dead_code_table,
                        CodeRegionTable* tag_code_table)
      : SampleVisitor(isolate),
        live_code_table_(live_code_table),
        dead_code_table_(dead_code_table),
        tag_code_table_(tag_code_table) {
    ASSERT(live_code_table_ != NULL);
    ASSERT(dead_code_table_ != NULL);
    ASSERT(tag_code_table_ != NULL);
    set_tag_order(ProfilerService::kUserVM);

    // Verify that the truncated tag exists.
    ASSERT(tag_code_table_->FindIndex(VMTag::kTruncatedTagId) >= 0);

    // Verify that the root tag exists.
    intptr_t root_index = tag_code_table_->FindIndex(VMTag::kRootTagId);
    ASSERT(root_index >= 0);
    CodeRegion* region = tag_code_table_->At(root_index);
    ASSERT(region != NULL);

    exclusive_root_ = new CodeRegionTrieNode(region->code_table_index());
    inclusive_root_ = new CodeRegionTrieNode(region->code_table_index());
  }

  void VisitSample(Sample* sample) {
    ProcessSampleExclusive(sample);
    ProcessSampleInclusive(sample);
  }

  CodeRegionTrieNode* inclusive_root() const {
    return inclusive_root_;
  }

  CodeRegionTrieNode* exclusive_root() const {
    return exclusive_root_;
  }

  ProfilerService::TagOrder tag_order() const {
    return tag_order_;
  }

  bool vm_tags_emitted() const {
    return (tag_order_ == ProfilerService::kUserVM) ||
           (tag_order_ == ProfilerService::kVMUser) ||
           (tag_order_ == ProfilerService::kVM);
  }

  void set_tag_order(ProfilerService::TagOrder tag_order) {
    tag_order_ = tag_order;
  }

 private:
  void ProcessSampleInclusive(Sample* sample) {
    // Give the root a tick.
    inclusive_root_->Tick();
    CodeRegionTrieNode* current = inclusive_root_;
    current = AppendTags(sample, current);
    if (sample->truncated_trace()) {
      current = AppendTruncatedTag(current);
    }
    // Walk the sampled PCs.
    for (intptr_t i = FLAG_profile_depth - 1; i >= 0; i--) {
      if (sample->At(i) == 0) {
        continue;
      }
      intptr_t index = FindFinalIndex(sample->At(i), sample->timestamp());
      if (index < 0) {
        continue;
      }
      current = current->GetChild(index);
      current->Tick();
    }
  }

  void ProcessSampleExclusive(Sample* sample) {
    // Give the root a tick.
    exclusive_root_->Tick();
    CodeRegionTrieNode* current = exclusive_root_;
    current = AppendTags(sample, current);
    // Walk the sampled PCs.
    for (intptr_t i = 0; i < FLAG_profile_depth; i++) {
      if (sample->At(i) == 0) {
        break;
      }
      intptr_t index = FindFinalIndex(sample->At(i), sample->timestamp());
      if (index < 0) {
        continue;
      }
      current = current->GetChild(index);
      if (i == 0) {
        // Executing PC.
        if (!sample->exit_frame_sample() || vm_tags_emitted()) {
          // Only tick if this isn't an exit frame or VM tags are emitted.
          current->Tick();
        }
      } else {
        // Caller PCs.
        current->Tick();
      }
    }
    if (sample->truncated_trace()) {
      current = AppendTruncatedTag(current);
    }
  }

  CodeRegionTrieNode* AppendUserTag(Sample* sample,
                                    CodeRegionTrieNode* current) {
    intptr_t user_tag_index = FindTagIndex(sample->user_tag());
    if (user_tag_index >= 0) {
      current = current->GetChild(user_tag_index);
      // Give the tag a tick.
      current->Tick();
    }
    return current;
  }

  CodeRegionTrieNode* AppendTruncatedTag(CodeRegionTrieNode* current) {
    intptr_t truncated_tag_index = FindTagIndex(VMTag::kTruncatedTagId);
    ASSERT(truncated_tag_index >= 0);
    current = current->GetChild(truncated_tag_index);
    current->Tick();
    return current;
  }

  CodeRegionTrieNode* AppendVMTag(Sample* sample,
                                  CodeRegionTrieNode* current) {
    if (VMTag::IsNativeEntryTag(sample->vm_tag())) {
      // Insert a dummy kNativeTagId node.
      intptr_t tag_index = FindTagIndex(VMTag::kNativeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else if (VMTag::IsRuntimeEntryTag(sample->vm_tag())) {
      // Insert a dummy kRuntimeTagId node.
      intptr_t tag_index = FindTagIndex(VMTag::kRuntimeTagId);
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    } else {
      intptr_t tag_index = FindTagIndex(sample->vm_tag());
      current = current->GetChild(tag_index);
      // Give the tag a tick.
      current->Tick();
    }
    return current;
  }

  CodeRegionTrieNode* AppendSpecificNativeRuntimeEntryVMTag(
      Sample* sample, CodeRegionTrieNode* current) {
    // Only Native and Runtime entries have a second VM tag.
    if (!VMTag::IsNativeEntryTag(sample->vm_tag()) &&
        !VMTag::IsRuntimeEntryTag(sample->vm_tag())) {
      return current;
    }
    intptr_t tag_index = FindTagIndex(sample->vm_tag());
    current = current->GetChild(tag_index);
    // Give the tag a tick.
    current->Tick();
    return current;
  }

  CodeRegionTrieNode* AppendVMTags(Sample* sample,
                                   CodeRegionTrieNode* current) {
    current = AppendVMTag(sample, current);
    current = AppendSpecificNativeRuntimeEntryVMTag(sample, current);
    return current;
  }

  CodeRegionTrieNode* AppendTags(Sample* sample, CodeRegionTrieNode* current) {
    // None.
    if (tag_order() == ProfilerService::kNoTags) {
      return current;
    }
    // User first.
    if ((tag_order() == ProfilerService::kUserVM) ||
        (tag_order() == ProfilerService::kUser)) {
      current = AppendUserTag(sample, current);
      // Only user.
      if (tag_order() == ProfilerService::kUser) {
        return current;
      }
      return AppendVMTags(sample, current);
    }
    // VM first.
    ASSERT((tag_order() == ProfilerService::kVMUser) ||
           (tag_order() == ProfilerService::kVM));
    current = AppendVMTags(sample, current);
    // Only VM.
    if (tag_order() == ProfilerService::kVM) {
      return current;
    }
    return AppendUserTag(sample, current);
  }

  intptr_t FindTagIndex(uword tag) const {
    if (tag == 0) {
      UNREACHABLE();
      return -1;
    }
    intptr_t index = tag_code_table_->FindIndex(tag);
    if (index < 0) {
      UNREACHABLE();
      return -1;
    }
    ASSERT(index >= 0);
    CodeRegion* region = tag_code_table_->At(index);
    ASSERT(region->contains(tag));
    return region->code_table_index();
  }

  intptr_t FindDeadIndex(uword pc, int64_t timestamp) const {
    intptr_t index = dead_code_table_->FindIndex(pc);
    if (index < 0) {
      OS::Print("%" Px " cannot be found\n", pc);
      return -1;
    }
    CodeRegion* region = dead_code_table_->At(index);
    ASSERT(region->contains(pc));
    ASSERT(region->compile_timestamp() <= timestamp);
    return region->code_table_index();
  }

  intptr_t FindFinalIndex(uword pc, int64_t timestamp) const {
    intptr_t index = live_code_table_->FindIndex(pc);
    if (index < 0) {
      // Try dead code table.
      return FindDeadIndex(pc, timestamp);
    }
    CodeRegion* region = live_code_table_->At(index);
    ASSERT(region->contains(pc));
    if (region->compile_timestamp() > timestamp) {
      // Overwritten code, find in dead code table.
      return FindDeadIndex(pc, timestamp);
    }
    ASSERT(region->compile_timestamp() <= timestamp);
    return region->code_table_index();
  }

  ProfilerService::TagOrder tag_order_;
  CodeRegionTrieNode* exclusive_root_;
  CodeRegionTrieNode* inclusive_root_;
  CodeRegionTable* live_code_table_;
  CodeRegionTable* dead_code_table_;
  CodeRegionTable* tag_code_table_;
};


void ProfilerService::PrintJSON(JSONStream* stream, TagOrder tag_order) {
  Isolate* isolate = Isolate::Current();
  // Disable profile interrupts while processing the buffer.
  Profiler::EndExecution(isolate);
  MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    stream->PrintError(kFeatureDisabled, NULL);
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  ASSERT(sample_buffer != NULL);
  ScopeTimer sw("ProfilerService::PrintJSON", FLAG_trace_profiler);
  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    {
      // Live code holds Dart, Native, and Collected CodeRegions.
      CodeRegionTable live_code_table;
      // Dead code holds Overwritten CodeRegions.
      CodeRegionTable dead_code_table;
      // Tag code holds Tag CodeRegions.
      CodeRegionTable tag_code_table;
      // Table holding all ProfileFunctions.
      ProfileFunctionTable function_table;
      // Set of deoptimized code still referenced by the profiler.
      DeoptimizedCodeSet* deoptimized_code = new DeoptimizedCodeSet(isolate);

      {
        ScopeTimer sw("PreprocessSamples", FLAG_trace_profiler);
        // Preprocess samples.
        PreprocessVisitor preprocessor(isolate);
        sample_buffer->VisitSamples(&preprocessor);
      }

      // Build CodeRegion tables.
      CodeRegionTableBuilder builder(isolate,
                                     &live_code_table,
                                     &dead_code_table,
                                     &tag_code_table,
                                     deoptimized_code);
      {
        ScopeTimer sw("CodeRegionTableBuilder", FLAG_trace_profiler);
        sample_buffer->VisitSamples(&builder);
      }
      intptr_t samples = builder.visited();
      intptr_t frames = builder.frames();
      if (FLAG_trace_profiler) {
        intptr_t total_live_code_objects = live_code_table.Length();
        intptr_t total_dead_code_objects = dead_code_table.Length();
        intptr_t total_tag_code_objects = tag_code_table.Length();
        OS::Print(
            "Processed %" Pd " samples with %" Pd " frames\n", samples, frames);
        OS::Print("CodeTables: live=%" Pd " dead=%" Pd " tag=%" Pd "\n",
                  total_live_code_objects,
                  total_dead_code_objects,
                  total_tag_code_objects);
      }

      if (FLAG_trace_profiler) {
        ScopeTimer sw("CodeRegionTableVerify", FLAG_trace_profiler);
        live_code_table.Verify();
        dead_code_table.Verify();
        tag_code_table.Verify();
      }

      {
        ScopeTimer st("CodeRegionFunctionMapping", FLAG_trace_profiler);
        CodeRegionFunctionMapper mapper(isolate, &live_code_table,
                                                 &dead_code_table,
                                                 &tag_code_table,
                                                 &function_table);
        mapper.Map();
      }
      if (FLAG_trace_profiler) {
        intptr_t total_functions = function_table.Length();
        OS::Print("FunctionTable: size=%" Pd "\n", total_functions);
      }
      CodeRegionTrieBuilder code_trie_builder(isolate,
                                              &live_code_table,
                                              &dead_code_table,
                                              &tag_code_table);
      code_trie_builder.set_tag_order(tag_order);
      {
        // Build CodeRegion trie.
        ScopeTimer sw("CodeRegionTrieBuilder", FLAG_trace_profiler);
        sample_buffer->VisitSamples(&code_trie_builder);
        code_trie_builder.exclusive_root()->SortByCount();
        code_trie_builder.inclusive_root()->SortByCount();
      }
      if (FLAG_trace_profiler) {
        OS::Print("Code Trie Root Count: E: %" Pd " I: %" Pd "\n",
                  code_trie_builder.exclusive_root()->count(),
                  code_trie_builder.inclusive_root()->count());
      }
      ProfileFunctionTrieBuilder function_trie_builder(isolate,
                                                       &live_code_table,
                                                       &dead_code_table,
                                                       &tag_code_table,
                                                       &function_table);
      function_trie_builder.set_tag_order(tag_order);
      {
        // Build ProfileFunction trie.
        ScopeTimer sw("ProfileFunctionTrieBuilder",
                      FLAG_trace_profiler);
        sample_buffer->VisitSamples(&function_trie_builder);
        function_trie_builder.exclusive_root()->SortByCount();
        function_trie_builder.inclusive_root()->SortByCount();
      }
      if (FLAG_trace_profiler) {
        OS::Print("Function Trie Root Count: E: %" Pd " I: %" Pd "\n",
                  function_trie_builder.exclusive_root()->count(),
                  function_trie_builder.inclusive_root()->count());
      }
      {
        ScopeTimer sw("CpuProfileJSONStream", FLAG_trace_profiler);
        // Serialize to JSON.
        JSONObject obj(stream);
        obj.AddProperty("type", "_CpuProfile");
        obj.AddProperty("sampleCount", samples);
        obj.AddProperty("samplePeriod",
                        static_cast<intptr_t>(FLAG_profile_period));
        obj.AddProperty("stackDepth",
                        static_cast<intptr_t>(FLAG_profile_depth));
        obj.AddProperty("timeSpan",
                        MicrosecondsToSeconds(builder.TimeDeltaMicros()));
        {
          JSONArray code_trie(&obj, "exclusiveCodeTrie");
          CodeRegionTrieNode* root = code_trie_builder.exclusive_root();
          ASSERT(root != NULL);
          root->PrintToJSONArray(&code_trie);
        }
        {
          JSONArray code_trie(&obj, "inclusiveCodeTrie");
          CodeRegionTrieNode* root = code_trie_builder.inclusive_root();
          ASSERT(root != NULL);
          root->PrintToJSONArray(&code_trie);
        }
        {
          JSONArray function_trie(&obj, "exclusiveFunctionTrie");
          ProfileFunctionTrieNode* root =
              function_trie_builder.exclusive_root();
          ASSERT(root != NULL);
          root->PrintToJSONArray(&function_trie);
        }
        {
          JSONArray function_trie(&obj, "inclusiveFunctionTrie");
          ProfileFunctionTrieNode* root =
              function_trie_builder.inclusive_root();
          ASSERT(root != NULL);
          root->PrintToJSONArray(&function_trie);
        }
        {
          JSONArray codes(&obj, "codes");
          for (intptr_t i = 0; i < live_code_table.Length(); i++) {
            CodeRegion* region = live_code_table.At(i);
            ASSERT(region != NULL);
            region->PrintToJSONArray(&codes);
          }
          for (intptr_t i = 0; i < dead_code_table.Length(); i++) {
            CodeRegion* region = dead_code_table.At(i);
            ASSERT(region != NULL);
            region->PrintToJSONArray(&codes);
          }
          for (intptr_t i = 0; i < tag_code_table.Length(); i++) {
            CodeRegion* region = tag_code_table.At(i);
            ASSERT(region != NULL);
            region->PrintToJSONArray(&codes);
          }
        }
        {
          JSONArray functions(&obj, "functions");
          for (intptr_t i = 0; i < function_table.Length(); i++) {
            ProfileFunction* function = function_table.At(i);
            ASSERT(function != NULL);
            function->PrintToJSONArray(&functions);
          }
        }
      }
      // Update the isolates set of dead code.
      deoptimized_code->UpdateIsolate(isolate);
    }
  }
  // Enable profile interrupts.
  Profiler::BeginExecution(isolate);
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
