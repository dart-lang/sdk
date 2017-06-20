// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROFILER_SERVICE_H_
#define RUNTIME_VM_PROFILER_SERVICE_H_

#include "vm/allocation.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"
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
class RawCode;
class RawFunction;
class SampleFilter;
class ProcessedSample;
class ProcessedSampleBuffer;

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
              const Code& code);

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
  RawCode* code() const { return code_.raw(); }

  const char* name() const { return name_; }
  void SetName(const char* name);
  void GenerateAndSetSymbolName(const char* prefix);

  static const char* KindToCString(Kind kind);

  void PrintToJSONArray(JSONArray* codes);

 private:
  void Tick(uword pc, bool exclusive, intptr_t serial);
  void TickAddress(uword pc, bool exclusive);

  ProfileFunction* SetFunctionAndName(ProfileFunctionTable* table);

  ProfileFunction* function() const { return function_; }

  void PrintNativeCode(JSONObject* profile_code_obj);
  void PrintCollectedCode(JSONObject* profile_code_obj);
  void PrintOverwrittenCode(JSONObject* profile_code_obj);
  void PrintTagCode(JSONObject* profile_code_obj);

  void set_code_table_index(intptr_t index) { code_table_index_ = index; }
  intptr_t code_table_index() const { return code_table_index_; }

  const Kind kind_;
  uword start_;
  uword end_;
  intptr_t exclusive_ticks_;
  intptr_t inclusive_ticks_;
  intptr_t inclusive_serial_;

  const Code& code_;
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


// Stack traces are organized in a trie. This holds information about one node
// in the trie. A node in a tree represents a stack frame and a path in the tree
// represents a stack trace. Each unique stack trace appears in the tree once
// and each node has a count indicating how many times this has been observed.
// The index can be used to look up a |ProfileFunction| or |ProfileCode|.
// A node can have zero or more children. Depending on the kind of trie the
// children are callers or callees of the current node.
class ProfileTrieNode : public ZoneAllocated {
 public:
  explicit ProfileTrieNode(intptr_t index);
  virtual ~ProfileTrieNode();

  virtual void PrintToJSONArray(JSONArray* array) const = 0;

  // Index into function or code tables.
  intptr_t table_index() const { return table_index_; }

  intptr_t count() const { return count_; }

  void Tick(ProcessedSample* sample, bool exclusive = false);

  void IncrementAllocation(intptr_t allocation, bool exclusive) {
    ASSERT(allocation >= 0);
    if (exclusive) {
      exclusive_allocations_ += allocation;
    }
    inclusive_allocations_ += allocation;
  }

  intptr_t inclusive_allocations() const { return inclusive_allocations_; }
  intptr_t exclusive_allocations() const { return exclusive_allocations_; }

  intptr_t NumChildren() const { return children_.length(); }

  ProfileTrieNode* At(intptr_t i) { return children_.At(i); }

  intptr_t IndexOf(ProfileTrieNode* node);

  intptr_t frame_id() const { return frame_id_; }
  void set_frame_id(intptr_t id) {
    ASSERT(frame_id_ == -1);
    frame_id_ = id;
  }

 protected:
  void SortChildren();

  static int ProfileTrieNodeCompare(ProfileTrieNode* const* a,
                                    ProfileTrieNode* const* b) {
    ASSERT(a != NULL);
    ASSERT(b != NULL);
    return (*b)->count() - (*a)->count();
  }


  intptr_t table_index_;
  intptr_t count_;
  intptr_t exclusive_allocations_;
  intptr_t inclusive_allocations_;
  ZoneGrowableArray<ProfileTrieNode*> children_;
  intptr_t frame_id_;

  friend class ProfileBuilder;
};


// The model for a profile. Most of the model is zone allocated, therefore
// a zone must be created that lives longer than this object.
class Profile : public ValueObject {
 public:
  enum TagOrder { kNoTags, kUser, kUserVM, kVM, kVMUser };

  enum TrieKind {
    kExclusiveCode,
    kExclusiveFunction,
    kInclusiveCode,
    kInclusiveFunction,
    kNumTrieKinds,
  };

  static bool IsCodeTrie(TrieKind kind) {
    return (kind == kExclusiveCode) || (kind == kInclusiveCode);
  }

  static bool IsFunctionTrie(TrieKind kind) { return !IsCodeTrie(kind); }

  explicit Profile(Isolate* isolate);

  // Build a filtered model using |filter| with the specified |tag_order|.
  void Build(Thread* thread,
             SampleFilter* filter,
             TagOrder tag_order,
             intptr_t extra_tags = 0);

  // After building:
  int64_t min_time() const { return min_time_; }
  int64_t max_time() const { return max_time_; }
  int64_t GetTimeSpan() const { return max_time() - min_time(); }
  intptr_t sample_count() const { return sample_count_; }

  intptr_t NumFunctions() const;

  ProfileFunction* GetFunction(intptr_t index);
  ProfileCode* GetCode(intptr_t index);
  ProfileTrieNode* GetTrieRoot(TrieKind trie_kind);

  void PrintProfileJSON(JSONStream* stream);
  void PrintTimelineJSON(JSONStream* stream);

  ProfileFunction* FindFunction(const Function& function);

 private:
  void PrintHeaderJSON(JSONObject* obj);
  void PrintTimelineFrameJSON(JSONObject* frames,
                              ProfileTrieNode* current,
                              ProfileTrieNode* parent,
                              intptr_t* next_id);

  Isolate* isolate_;
  Zone* zone_;
  ProcessedSampleBuffer* samples_;
  ProfileCodeTable* live_code_;
  ProfileCodeTable* dead_code_;
  ProfileCodeTable* tag_code_;
  ProfileFunctionTable* functions_;
  intptr_t dead_code_index_offset_;
  intptr_t tag_code_index_offset_;

  ProfileTrieNode* roots_[kNumTrieKinds];

  int64_t min_time_;
  int64_t max_time_;

  intptr_t sample_count_;

  friend class ProfileBuilder;
};


class ProfileTrieWalker : public ValueObject {
 public:
  explicit ProfileTrieWalker(Profile* profile)
      : profile_(profile), parent_(NULL), current_(NULL), code_trie_(false) {
    ASSERT(profile_ != NULL);
  }

  void Reset(Profile::TrieKind trie_kind);

  const char* CurrentName();
  // Return the current node's peer's inclusive tick count.
  intptr_t CurrentInclusiveTicks();
  // Return the current node's peer's exclusive tick count.
  intptr_t CurrentExclusiveTicks();
  // Return the current node's inclusive allocation count.
  intptr_t CurrentInclusiveAllocations();
  // Return the current node's exclusive allocation count.
  intptr_t CurrentExclusiveAllocations();
  // Return the current node's tick count.
  intptr_t CurrentNodeTickCount();
  // Return the number siblings (including yourself).
  intptr_t SiblingCount();

  // If the following conditions are met returns the current token:
  // 1) This is a function trie.
  // 2) There is only one token position for a given function.
  // Will return NULL otherwise.
  const char* CurrentToken();

  bool Down();
  bool NextSibling();

 private:
  Profile* profile_;
  ProfileTrieNode* parent_;
  ProfileTrieNode* current_;
  bool code_trie_;
};


class ProfilerService : public AllStatic {
 public:
  enum {
    kNoExtraTags = 0,
    kCodeTransitionTagsBit = (1 << 0),
  };

  static void PrintJSON(JSONStream* stream,
                        Profile::TagOrder tag_order,
                        intptr_t extra_tags,
                        int64_t time_origin_micros,
                        int64_t time_extent_micros);

  static void PrintAllocationJSON(JSONStream* stream,
                                  Profile::TagOrder tag_order,
                                  const Class& cls,
                                  int64_t time_origin_micros,
                                  int64_t time_extent_micros);

  static void PrintNativeAllocationJSON(JSONStream* stream,
                                        Profile::TagOrder tag_order,
                                        int64_t time_origin_micros,
                                        int64_t time_extent_micros);

  static void PrintTimelineJSON(JSONStream* stream,
                                Profile::TagOrder tag_order,
                                int64_t time_origin_micros,
                                int64_t time_extent_micros);

  static void ClearSamples();

 private:
  static void PrintJSONImpl(Thread* thread,
                            JSONStream* stream,
                            Profile::TagOrder tag_order,
                            intptr_t extra_tags,
                            SampleFilter* filter,
                            bool as_timline);
};

}  // namespace dart

#endif  // RUNTIME_VM_PROFILER_SERVICE_H_
