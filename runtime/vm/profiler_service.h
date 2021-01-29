// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROFILER_SERVICE_H_
#define RUNTIME_VM_PROFILER_SERVICE_H_

#include "platform/text_buffer.h"
#include "vm/allocation.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/profiler.h"
#include "vm/tags.h"
#include "vm/thread_interrupter.h"
#include "vm/token_position.h"

// CPU Profile model and service protocol bits.
// NOTE: For sampling and stack walking related code, see profiler.h.

namespace dart {

// Forward declarations.
class Code;
class Function;
class JSONArray;
class JSONStream;
class ProfileFunctionTable;
class ProfileCodeTable;
class SampleFilter;
class ProcessedSample;
class ProcessedSampleBuffer;
class Profile;

class ProfileFunctionSourcePosition {
 public:
  explicit ProfileFunctionSourcePosition(TokenPosition token_pos);

  void Tick(bool exclusive);

  TokenPosition token_pos() const { return token_pos_; }
  intptr_t exclusive_ticks() const { return exclusive_ticks_; }
  intptr_t inclusive_ticks() const { return inclusive_ticks_; }

 private:
  TokenPosition token_pos_;
  intptr_t exclusive_ticks_;
  intptr_t inclusive_ticks_;

  DISALLOW_ALLOCATION();
};

class ProfileCodeInlinedFunctionsCache : public ZoneAllocated {
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
      OS::PrintErr("LOOKUPS: %" Pd " HITS: %" Pd " MISSES: %" Pd "\n", total,
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
           TokenPosition* token_position);

 private:
  bool FindInCache(uword pc,
                   intptr_t offset,
                   GrowableArray<const Function*>** inlined_functions,
                   GrowableArray<TokenPosition>** inlined_token_positions,
                   TokenPosition* token_position);

  // Add to cache and fill in outputs.
  void Add(uword pc,
           const Code& code,
           ProcessedSample* sample,
           intptr_t frame_index,
           // Outputs:
           GrowableArray<const Function*>** inlined_functions,
           GrowableArray<TokenPosition>** inlined_token_positions,
           TokenPosition* token_position);

  intptr_t NextFreeIndex() {
    cache_cursor_ = (cache_cursor_ + 1) % kCacheSize;
    return cache_cursor_;
  }

  intptr_t OffsetForPC(uword pc,
                       const Code& code,
                       ProcessedSample* sample,
                       intptr_t frame_index);
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
    TokenPosition token_position = TokenPosition::kNoSource;
  };

  static const intptr_t kCacheSize = 128;
  intptr_t cache_cursor_;
  intptr_t last_hit_;
  CacheEntry cache_[kCacheSize];
  intptr_t cache_miss_;
  intptr_t cache_hit_;
};

// Profile data related to a |Function|.
class ProfileFunction : public ZoneAllocated {
 public:
  enum Kind {
    kDartFunction,     // Dart function.
    kNativeFunction,   // Synthetic function for Native (C/C++).
    kTagFunction,      // Synthetic function for a VM or User tag.
    kStubFunction,     // Synthetic function for stub code.
    kUnknownFunction,  // A singleton function for unknown objects.
  };

  ProfileFunction(Kind kind,
                  const char* name,
                  const Function& function,
                  const intptr_t table_index);

  const char* name() const {
    ASSERT(name_ != NULL);
    return name_;
  }

  const char* Name() const;

  const Function* function() const { return &function_; }

  // Returns the resolved_url for the script containing this function.
  const char* ResolvedScriptUrl() const;

  bool is_visible() const;

  intptr_t table_index() const { return table_index_; }

  Kind kind() const { return kind_; }

  intptr_t exclusive_ticks() const { return exclusive_ticks_; }
  intptr_t inclusive_ticks() const { return inclusive_ticks_; }

  void IncInclusiveTicks() { inclusive_ticks_++; }

  void Tick(bool exclusive,
            intptr_t inclusive_serial,
            TokenPosition token_position);

  static const char* KindToCString(Kind kind);

  void PrintToJSONArray(JSONArray* functions);

  // Returns true if the call was successful and |pfsp| is set.
  bool GetSinglePosition(ProfileFunctionSourcePosition* pfsp);

  void TickSourcePosition(TokenPosition token_position, bool exclusive);

  intptr_t NumSourcePositions() const {
    return source_position_ticks_.length();
  }

  const ProfileFunctionSourcePosition& GetSourcePosition(intptr_t i) const {
    return source_position_ticks_.At(i);
  }

 private:
  const Kind kind_;
  const char* name_;
  const Function& function_;
  const intptr_t table_index_;
  ZoneGrowableArray<intptr_t> profile_codes_;
  ZoneGrowableArray<ProfileFunctionSourcePosition> source_position_ticks_;

  intptr_t exclusive_ticks_;
  intptr_t inclusive_ticks_;
  intptr_t inclusive_serial_;

  void PrintToJSONObject(JSONObject* func);
  // A |ProfileCode| that contains this function.
  void AddProfileCode(intptr_t code_table_index);

  friend class ProfileCode;
  friend class ProfileBuilder;
};

class ProfileCodeAddress {
 public:
  explicit ProfileCodeAddress(uword pc);

  void Tick(bool exclusive);

  uword pc() const { return pc_; }
  intptr_t exclusive_ticks() const { return exclusive_ticks_; }
  intptr_t inclusive_ticks() const { return inclusive_ticks_; }

 private:
  uword pc_;
  intptr_t exclusive_ticks_;
  intptr_t inclusive_ticks_;
};

// Profile data related to a |Code|.
class ProfileCode : public ZoneAllocated {
 public:
  enum Kind {
    kDartCode,       // Live Dart code.
    kCollectedCode,  // Dead Dart code.
    kNativeCode,     // Native code.
    kReusedCode,     // Dead Dart code that has been reused by new kDartCode.
    kTagCode,        // A special kind of code representing a tag.
  };

  ProfileCode(Kind kind,
              uword start,
              uword end,
              int64_t timestamp,
              const AbstractCode code);

  Kind kind() const { return kind_; }

  uword start() const { return start_; }
  void set_start(uword start) { start_ = start; }

  uword end() const { return end_; }
  void set_end(uword end) { end_ = end; }

  void ExpandLower(uword start);
  void ExpandUpper(uword end);
  void TruncateLower(uword start);
  void TruncateUpper(uword end);

  bool Contains(uword pc) const { return (pc >= start_) && (pc < end_); }

  bool Overlaps(const ProfileCode* other) const;

  int64_t compile_timestamp() const { return compile_timestamp_; }
  void set_compile_timestamp(int64_t timestamp) {
    compile_timestamp_ = timestamp;
  }

  intptr_t exclusive_ticks() const { return exclusive_ticks_; }
  void set_exclusive_ticks(intptr_t exclusive_ticks) {
    exclusive_ticks_ = exclusive_ticks;
  }
  void IncExclusiveTicks() { exclusive_ticks_++; }

  intptr_t inclusive_ticks() const { return inclusive_ticks_; }
  void set_inclusive_ticks(intptr_t inclusive_ticks) {
    inclusive_ticks_ = inclusive_ticks;
  }
  void IncInclusiveTicks() { inclusive_ticks_++; }

  bool IsOptimizedDart() const;
  const AbstractCode code() const { return code_; }

  const char* name() const { return name_; }
  void SetName(const char* name);
  void GenerateAndSetSymbolName(const char* prefix);

  static const char* KindToCString(Kind kind);

  void PrintToJSONArray(JSONArray* codes);

  ProfileFunction* function() const { return function_; }

  intptr_t code_table_index() const { return code_table_index_; }

 private:
  void Tick(uword pc, bool exclusive, intptr_t serial);
  void TickAddress(uword pc, bool exclusive);

  ProfileFunction* SetFunctionAndName(ProfileFunctionTable* table);

  void PrintNativeCode(JSONObject* profile_code_obj);
  void PrintCollectedCode(JSONObject* profile_code_obj);
  void PrintOverwrittenCode(JSONObject* profile_code_obj);
  void PrintTagCode(JSONObject* profile_code_obj);

  void set_code_table_index(intptr_t index) { code_table_index_ = index; }

  const Kind kind_;
  uword start_;
  uword end_;
  intptr_t exclusive_ticks_;
  intptr_t inclusive_ticks_;
  intptr_t inclusive_serial_;

  const AbstractCode code_;
  char* name_;
  int64_t compile_timestamp_;
  ProfileFunction* function_;
  intptr_t code_table_index_;
  ZoneGrowableArray<ProfileCodeAddress> address_ticks_;

  friend class ProfileBuilder;
};

class ProfileCodeTable : public ZoneAllocated {
 public:
  ProfileCodeTable() : table_(8) {}

  intptr_t length() const { return table_.length(); }

  ProfileCode* At(intptr_t index) const {
    ASSERT(index >= 0);
    ASSERT(index < length());
    return table_[index];
  }

  // Find the table index to the ProfileCode containing pc.
  // Returns < 0 if not found.
  intptr_t FindCodeIndexForPC(uword pc) const;

  ProfileCode* FindCodeForPC(uword pc) const {
    intptr_t index = FindCodeIndexForPC(pc);
    if (index < 0) {
      return NULL;
    }
    return At(index);
  }

  // Insert |new_code| into the table. Returns the table index where |new_code|
  // was inserted. Will merge with an overlapping ProfileCode if one is present.
  intptr_t InsertCode(ProfileCode* new_code);

 private:
  void FindNeighbors(uword pc,
                     intptr_t* lo,
                     intptr_t* hi,
                     ProfileCode** lo_code,
                     ProfileCode** hi_code) const;

  void VerifyOrder();
  void VerifyOverlap();

  ZoneGrowableArray<ProfileCode*> table_;
};


// The model for a profile. Most of the model is zone allocated, therefore
// a zone must be created that lives longer than this object.
class Profile : public ValueObject {
 public:
  explicit Profile(Isolate* isolate);

  // Build a filtered model using |filter|.
  void Build(Thread* thread, SampleFilter* filter, SampleBuffer* sample_buffer);

  // After building:
  int64_t min_time() const { return min_time_; }
  int64_t max_time() const { return max_time_; }
  int64_t GetTimeSpan() const { return max_time() - min_time(); }
  intptr_t sample_count() const { return sample_count_; }
  ProcessedSample* SampleAt(intptr_t index);

  intptr_t NumFunctions() const;

  ProfileFunction* GetFunction(intptr_t index);
  ProfileCode* GetCode(intptr_t index);
  ProfileCode* GetCodeFromPC(uword pc, int64_t timestamp);

  void PrintProfileJSON(JSONStream* stream, bool include_code_samples);

  ProfileFunction* FindFunction(const Function& function);

 private:
  void PrintHeaderJSON(JSONObject* obj);
  void ProcessSampleFrameJSON(JSONArray* stack,
                              ProfileCodeInlinedFunctionsCache* cache,
                              ProcessedSample* sample,
                              intptr_t frame_index);
  void ProcessInlinedFunctionFrameJSON(JSONArray* stack,
                                       const Function* inlined_function);
  void PrintFunctionFrameIndexJSON(JSONArray* stack, ProfileFunction* function);
  void PrintCodeFrameIndexJSON(JSONArray* stack,
                               ProcessedSample* sample,
                               intptr_t frame_index);
  void PrintSamplesJSON(JSONObject* obj, bool code_samples);

  Isolate* isolate_;
  Zone* zone_;
  ProcessedSampleBuffer* samples_;
  ProfileCodeTable* live_code_;
  ProfileCodeTable* dead_code_;
  ProfileCodeTable* tag_code_;
  ProfileFunctionTable* functions_;
  intptr_t dead_code_index_offset_;
  intptr_t tag_code_index_offset_;

  int64_t min_time_;
  int64_t max_time_;

  intptr_t sample_count_;

  friend class ProfileBuilder;
};

class ProfilerService : public AllStatic {
 public:
  static void PrintJSON(JSONStream* stream,
                        int64_t time_origin_micros,
                        int64_t time_extent_micros,
                        bool include_code_samples);

  static void PrintAllocationJSON(JSONStream* stream,
                                  const Class& cls,
                                  int64_t time_origin_micros,
                                  int64_t time_extent_micros);

  static void PrintNativeAllocationJSON(JSONStream* stream,
                                        int64_t time_origin_micros,
                                        int64_t time_extent_micros,
                                        bool include_code_samples);

  static void ClearSamples();

 private:
  static void PrintJSONImpl(Thread* thread,
                            JSONStream* stream,
                            SampleFilter* filter,
                            SampleBuffer* sample_buffer,
                            bool include_code_samples);
};

}  // namespace dart

#endif  // RUNTIME_VM_PROFILER_SERVICE_H_
