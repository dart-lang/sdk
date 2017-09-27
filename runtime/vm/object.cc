// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/become.h"
#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/code_observers.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/intrinsifier.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler_stats.h"
#include "vm/cpu.h"
#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/datastream.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/double_conversion.h"
#include "vm/exceptions.h"
#include "vm/growable_array.h"
#include "vm/hash_table.h"
#include "vm/heap.h"
#include "vm/isolate_reload.h"
#include "vm/native_symbol.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/profiler.h"
#include "vm/resolver.h"
#include "vm/reusable_handles.h"
#include "vm/runtime_entry.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/type_table.h"
#include "vm/unicode.h"
#include "vm/weak_code.h"
#include "vm/zone_text_buffer.h"

namespace dart {

DEFINE_FLAG(int,
            huge_method_cutoff_in_code_size,
            200000,
            "Huge method cutoff in unoptimized code size (in bytes).");
DEFINE_FLAG(
    bool,
    overlap_type_arguments,
    true,
    "When possible, partially or fully overlap the type arguments of a type "
    "with the type arguments of its super type.");
DEFINE_FLAG(
    bool,
    show_internal_names,
    false,
    "Show names of internal classes (e.g. \"OneByteString\") in error messages "
    "instead of showing the corresponding interface names (e.g. \"String\")");
DEFINE_FLAG(bool, use_lib_cache, true, "Use library name cache");
DEFINE_FLAG(bool, use_exp_cache, true, "Use library exported name cache");
DEFINE_FLAG(bool,
            ignore_patch_signature_mismatch,
            false,
            "Ignore patch file member signature mismatch.");

DEFINE_FLAG(bool,
            remove_script_timestamps_for_test,
            false,
            "Remove script timestamps to allow for deterministic testing.");

DECLARE_FLAG(bool, show_invisible_frames);
DECLARE_FLAG(bool, trace_deoptimization);
DECLARE_FLAG(bool, trace_deoptimization_verbose);
DECLARE_FLAG(bool, trace_reload);
DECLARE_FLAG(bool, write_protect_code);

static const char* const kGetterPrefix = "get:";
static const intptr_t kGetterPrefixLength = strlen(kGetterPrefix);
static const char* const kSetterPrefix = "set:";
static const intptr_t kSetterPrefixLength = strlen(kSetterPrefix);

// A cache of VM heap allocated preinitialized empty ic data entry arrays.
RawArray* ICData::cached_icdata_arrays_[kCachedICDataArrayCount];

cpp_vtable Object::handle_vtable_ = 0;
cpp_vtable Object::builtin_vtables_[kNumPredefinedCids] = {0};
cpp_vtable Smi::handle_vtable_ = 0;

// These are initialized to a value that will force a illegal memory access if
// they are being used.
#if defined(RAW_NULL)
#error RAW_NULL should not be defined.
#endif
#define RAW_NULL kHeapObjectTag
Object* Object::null_object_ = NULL;
Array* Object::null_array_ = NULL;
String* Object::null_string_ = NULL;
Instance* Object::null_instance_ = NULL;
Function* Object::null_function_ = NULL;
TypeArguments* Object::null_type_arguments_ = NULL;
TypeArguments* Object::empty_type_arguments_ = NULL;
Array* Object::empty_array_ = NULL;
Array* Object::zero_array_ = NULL;
Context* Object::empty_context_ = NULL;
ContextScope* Object::empty_context_scope_ = NULL;
ObjectPool* Object::empty_object_pool_ = NULL;
PcDescriptors* Object::empty_descriptors_ = NULL;
LocalVarDescriptors* Object::empty_var_descriptors_ = NULL;
ExceptionHandlers* Object::empty_exception_handlers_ = NULL;
Array* Object::extractor_parameter_types_ = NULL;
Array* Object::extractor_parameter_names_ = NULL;
Instance* Object::sentinel_ = NULL;
Instance* Object::transition_sentinel_ = NULL;
Instance* Object::unknown_constant_ = NULL;
Instance* Object::non_constant_ = NULL;
Bool* Object::bool_true_ = NULL;
Bool* Object::bool_false_ = NULL;
Smi* Object::smi_illegal_cid_ = NULL;
LanguageError* Object::snapshot_writer_error_ = NULL;
LanguageError* Object::branch_offset_error_ = NULL;
LanguageError* Object::speculative_inlining_error_ = NULL;
LanguageError* Object::background_compilation_error_ = NULL;
Array* Object::vm_isolate_snapshot_object_table_ = NULL;
Type* Object::dynamic_type_ = NULL;
Type* Object::void_type_ = NULL;
Type* Object::vector_type_ = NULL;

RawObject* Object::null_ = reinterpret_cast<RawObject*>(RAW_NULL);
RawClass* Object::class_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::dynamic_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::vector_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::void_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::unresolved_class_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::type_arguments_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::patch_class_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::function_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::closure_data_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::signature_data_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::redirection_data_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::field_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::literal_token_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::token_stream_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::script_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::library_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::namespace_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::code_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::instructions_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::object_pool_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::pc_descriptors_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::code_source_map_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::stackmap_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::var_descriptors_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::exception_handlers_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::context_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::context_scope_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::singletargetcache_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::unlinkedcall_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::icdata_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::megamorphic_cache_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::subtypetestcache_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::api_error_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::language_error_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::unhandled_exception_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::unwind_error_class_ = reinterpret_cast<RawClass*>(RAW_NULL);

const double MegamorphicCache::kLoadFactor = 0.50;

static void AppendSubString(Zone* zone,
                            GrowableArray<const char*>* segments,
                            const char* name,
                            intptr_t start_pos,
                            intptr_t len) {
  char* segment = zone->Alloc<char>(len + 1);  // '\0'-terminated.
  memmove(segment, name + start_pos, len);
  segment[len] = '\0';
  segments->Add(segment);
}

static const char* MergeSubStrings(Zone* zone,
                                   const GrowableArray<const char*>& segments,
                                   intptr_t alloc_len) {
  char* result = zone->Alloc<char>(alloc_len + 1);  // '\0'-terminated
  intptr_t pos = 0;
  for (intptr_t k = 0; k < segments.length(); k++) {
    const char* piece = segments[k];
    const intptr_t piece_len = strlen(segments[k]);
    memmove(result + pos, piece, piece_len);
    pos += piece_len;
    ASSERT(pos <= alloc_len);
  }
  result[pos] = '\0';
  return result;
}

// Remove private keys, but retain getter/setter/constructor/mixin manglings.
RawString* String::RemovePrivateKey(const String& name) {
  ASSERT(name.IsOneByteString());
  GrowableArray<uint8_t> without_key(name.Length());
  intptr_t i = 0;
  while (i < name.Length()) {
    while (i < name.Length()) {
      uint8_t c = name.CharAt(i++);
      if (c == '@') break;
      without_key.Add(c);
    }
    while (i < name.Length()) {
      uint8_t c = name.CharAt(i);
      if ((c < '0') || (c > '9')) break;
      i++;
    }
  }

  return String::FromLatin1(without_key.data(), without_key.length());
}

// Takes a vm internal name and makes it suitable for external user.
//
// Examples:
//
// Internal getter and setter prefixes are changed:
//
//   get:foo -> foo
//   set:foo -> foo=
//
// Private name mangling is removed, possibly multiple times:
//
//   _ReceivePortImpl@709387912 -> _ReceivePortImpl
//   _ReceivePortImpl@709387912._internal@709387912 ->
//      _ReceivePortImpl._internal
//   _C@6328321&_E@6328321&_F@6328321 -> _C&_E&_F
//
// The trailing . on the default constructor name is dropped:
//
//   List. -> List
//
// And so forth:
//
//   get:foo@6328321 -> foo
//   _MyClass@6328321. -> _MyClass
//   _MyClass@6328321.named -> _MyClass.named
//
RawString* String::ScrubName(const String& name) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (name.Equals(Symbols::TopLevel())) {
    // Name of invisible top-level class.
    return Symbols::Empty().raw();
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  const char* cname = name.ToCString();
  ASSERT(strlen(cname) == static_cast<size_t>(name.Length()));
  const intptr_t name_len = name.Length();
  // First remove all private name mangling.
  intptr_t start_pos = 0;
  GrowableArray<const char*> unmangled_segments;
  intptr_t sum_segment_len = 0;
  for (intptr_t i = 0; i < name_len; i++) {
    if ((cname[i] == '@') && ((i + 1) < name_len) && (cname[i + 1] >= '0') &&
        (cname[i + 1] <= '9')) {
      // Append the current segment to the unmangled name.
      const intptr_t segment_len = i - start_pos;
      sum_segment_len += segment_len;
      AppendSubString(zone, &unmangled_segments, cname, start_pos, segment_len);
      // Advance until past the name mangling. The private keys are only
      // numbers so we skip until the first non-number.
      i++;  // Skip the '@'.
      while ((i < name.Length()) && (name.CharAt(i) >= '0') &&
             (name.CharAt(i) <= '9')) {
        i++;
      }
      start_pos = i;
      i--;  // Account for for-loop increment.
    }
  }

  const char* unmangled_name = NULL;
  if (start_pos == 0) {
    // No name unmangling needed, reuse the name that was passed in.
    unmangled_name = cname;
    sum_segment_len = name_len;
  } else if (name.Length() != start_pos) {
    // Append the last segment.
    const intptr_t segment_len = name.Length() - start_pos;
    sum_segment_len += segment_len;
    AppendSubString(zone, &unmangled_segments, cname, start_pos, segment_len);
  }
  if (unmangled_name == NULL) {
    // Merge unmangled_segments.
    unmangled_name = MergeSubStrings(zone, unmangled_segments, sum_segment_len);
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  intptr_t len = sum_segment_len;
  intptr_t start = 0;
  intptr_t dot_pos = -1;  // Position of '.' in the name, if any.
  bool is_setter = false;
  for (intptr_t i = start; i < len; i++) {
    if (unmangled_name[i] == ':') {
      if (start != 0) {
        // Reset and break.
        start = 0;
        dot_pos = -1;
        break;
      }
      ASSERT(start == 0);  // Only one : is possible in getters or setters.
      if (unmangled_name[0] == 's') {
        is_setter = true;
      }
      start = i + 1;
    } else if (unmangled_name[i] == '.') {
      if (dot_pos != -1) {
        // Reset and break.
        start = 0;
        dot_pos = -1;
        break;
      }
      ASSERT(dot_pos == -1);  // Only one dot is supported.
      dot_pos = i;
    }
  }

  if ((start == 0) && (dot_pos == -1)) {
    // This unmangled_name is fine as it is.
    return Symbols::New(thread, unmangled_name, sum_segment_len);
  }

  // Drop the trailing dot if needed.
  intptr_t end = ((dot_pos + 1) == len) ? dot_pos : len;

  unmangled_segments.Clear();
  intptr_t final_len = end - start;
  AppendSubString(zone, &unmangled_segments, unmangled_name, start, final_len);
  if (is_setter) {
    const char* equals = Symbols::Equals().ToCString();
    const intptr_t equals_len = strlen(equals);
    AppendSubString(zone, &unmangled_segments, equals, 0, equals_len);
    final_len += equals_len;
  }

  unmangled_name = MergeSubStrings(zone, unmangled_segments, final_len);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  return Symbols::New(thread, unmangled_name);
}

RawString* String::ScrubNameRetainPrivate(const String& name) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  intptr_t len = name.Length();
  intptr_t start = 0;
  intptr_t at_pos = -1;  // Position of '@' in the name, if any.
  bool is_setter = false;

  for (intptr_t i = start; i < len; i++) {
    if (name.CharAt(i) == ':') {
      ASSERT(start == 0);  // Only one : is possible in getters or setters.
      if (name.CharAt(0) == 's') {
        is_setter = true;
      }
      start = i + 1;
    } else if (name.CharAt(i) == '@') {
      // Setters should have only one @ so we know where to put the =.
      ASSERT(!is_setter || (at_pos == -1));
      at_pos = i;
    }
  }

  if (start == 0) {
    // This unmangled_name is fine as it is.
    return name.raw();
  }

  String& result =
      String::Handle(String::SubString(name, start, (len - start)));

  if (is_setter) {
    // Setters need to end with '='.
    if (at_pos == -1) {
      return String::Concat(result, Symbols::Equals());
    } else {
      const String& pre_at =
          String::Handle(String::SubString(result, 0, at_pos - 4));
      const String& post_at =
          String::Handle(String::SubString(name, at_pos, len - at_pos));
      result = String::Concat(pre_at, Symbols::Equals());
      result = String::Concat(result, post_at);
    }
  }

  return result.raw();
#endif                // !defined(DART_PRECOMPILED_RUNTIME)
  return name.raw();  // In AOT, return argument unchanged.
}

template <typename type>
static bool IsSpecialCharacter(type value) {
  return ((value == '"') || (value == '\n') || (value == '\f') ||
          (value == '\b') || (value == '\t') || (value == '\v') ||
          (value == '\r') || (value == '\\') || (value == '$'));
}

static inline bool IsAsciiNonprintable(int32_t c) {
  return ((0 <= c) && (c < 32)) || (c == 127);
}

static inline bool NeedsEscapeSequence(int32_t c) {
  return (c == '"') || (c == '\\') || (c == '$') || IsAsciiNonprintable(c);
}

static int32_t EscapeOverhead(int32_t c) {
  if (IsSpecialCharacter(c)) {
    return 1;  // 1 additional byte for the backslash.
  } else if (IsAsciiNonprintable(c)) {
    return 3;  // 3 additional bytes to encode c as \x00.
  }
  return 0;
}

template <typename type>
static type SpecialCharacter(type value) {
  if (value == '"') {
    return '"';
  } else if (value == '\n') {
    return 'n';
  } else if (value == '\f') {
    return 'f';
  } else if (value == '\b') {
    return 'b';
  } else if (value == '\t') {
    return 't';
  } else if (value == '\v') {
    return 'v';
  } else if (value == '\r') {
    return 'r';
  } else if (value == '\\') {
    return '\\';
  } else if (value == '$') {
    return '$';
  }
  UNREACHABLE();
  return '\0';
}

void Object::InitNull(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  // TODO(iposva): NoSafepointScope needs to be added here.
  ASSERT(class_class() == null_);

  Heap* heap = isolate->heap();

  // Allocate and initialize the null instance.
  // 'null_' must be the first object allocated as it is used in allocation to
  // clear the object.
  {
    uword address = heap->Allocate(Instance::InstanceSize(), Heap::kOld);
    null_ = reinterpret_cast<RawInstance*>(address + kHeapObjectTag);
    // The call below is using 'null_' to initialize itself.
    InitializeObject(address, kNullCid, Instance::InstanceSize(), true);
  }
}

void Object::InitOnce(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  // Initialize the static vtable values.
  {
    Object fake_object;
    Smi fake_smi;
    Object::handle_vtable_ = fake_object.vtable();
    Smi::handle_vtable_ = fake_smi.vtable();
  }

  Heap* heap = isolate->heap();

  // Allocate the read only object handles here.
  null_object_ = Object::ReadOnlyHandle();
  null_array_ = Array::ReadOnlyHandle();
  null_string_ = String::ReadOnlyHandle();
  null_instance_ = Instance::ReadOnlyHandle();
  null_function_ = Function::ReadOnlyHandle();
  null_type_arguments_ = TypeArguments::ReadOnlyHandle();
  empty_type_arguments_ = TypeArguments::ReadOnlyHandle();
  empty_array_ = Array::ReadOnlyHandle();
  zero_array_ = Array::ReadOnlyHandle();
  empty_context_ = Context::ReadOnlyHandle();
  empty_context_scope_ = ContextScope::ReadOnlyHandle();
  empty_object_pool_ = ObjectPool::ReadOnlyHandle();
  empty_descriptors_ = PcDescriptors::ReadOnlyHandle();
  empty_var_descriptors_ = LocalVarDescriptors::ReadOnlyHandle();
  empty_exception_handlers_ = ExceptionHandlers::ReadOnlyHandle();
  extractor_parameter_types_ = Array::ReadOnlyHandle();
  extractor_parameter_names_ = Array::ReadOnlyHandle();
  sentinel_ = Instance::ReadOnlyHandle();
  transition_sentinel_ = Instance::ReadOnlyHandle();
  unknown_constant_ = Instance::ReadOnlyHandle();
  non_constant_ = Instance::ReadOnlyHandle();
  bool_true_ = Bool::ReadOnlyHandle();
  bool_false_ = Bool::ReadOnlyHandle();
  smi_illegal_cid_ = Smi::ReadOnlyHandle();
  snapshot_writer_error_ = LanguageError::ReadOnlyHandle();
  branch_offset_error_ = LanguageError::ReadOnlyHandle();
  speculative_inlining_error_ = LanguageError::ReadOnlyHandle();
  background_compilation_error_ = LanguageError::ReadOnlyHandle();
  vm_isolate_snapshot_object_table_ = Array::ReadOnlyHandle();
  dynamic_type_ = Type::ReadOnlyHandle();
  void_type_ = Type::ReadOnlyHandle();
  vector_type_ = Type::ReadOnlyHandle();

  *null_object_ = Object::null();
  *null_array_ = Array::null();
  *null_string_ = String::null();
  *null_instance_ = Instance::null();
  *null_function_ = Function::null();
  *null_type_arguments_ = TypeArguments::null();

  // Initialize the empty and zero array handles to null_ in order to be able to
  // check if the empty and zero arrays were allocated (RAW_NULL is not
  // available).
  *empty_array_ = Array::null();
  *zero_array_ = Array::null();

  Class& cls = Class::Handle();

  // Allocate and initialize the class class.
  {
    intptr_t size = Class::InstanceSize();
    uword address = heap->Allocate(size, Heap::kOld);
    class_class_ = reinterpret_cast<RawClass*>(address + kHeapObjectTag);
    InitializeObject(address, Class::kClassId, size, true);

    Class fake;
    // Initialization from Class::New<Class>.
    // Directly set raw_ to break a circular dependency: SetRaw will attempt
    // to lookup class class in the class table where it is not registered yet.
    cls.raw_ = class_class_;
    cls.set_handle_vtable(fake.vtable());
    cls.set_instance_size(Class::InstanceSize());
    cls.set_next_field_offset(Class::NextFieldOffset());
    cls.set_id(Class::kClassId);
    cls.set_state_bits(0);
    cls.set_is_finalized();
    cls.set_is_type_finalized();
    cls.set_is_cycle_free();
    cls.set_type_arguments_field_offset_in_words(Class::kNoTypeArguments);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_num_native_fields(0);
    cls.InitEmptyFields();
    isolate->RegisterClass(cls);
  }

  // Allocate and initialize the null class.
  cls = Class::New<Instance>(kNullCid);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  isolate->object_store()->set_null_class(cls);

  // Allocate and initialize the free list element class.
  cls = Class::New<FreeListElement::FakeInstance>(kFreeListElement);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_finalized();
  cls.set_is_type_finalized();
  cls.set_is_cycle_free();

  // Allocate and initialize the forwarding corpse class.
  cls = Class::New<ForwardingCorpse::FakeInstance>(kForwardingCorpse);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_finalized();
  cls.set_is_type_finalized();
  cls.set_is_cycle_free();

  // Allocate and initialize the sentinel values of Null class.
  {
    *sentinel_ ^=
        Object::Allocate(kNullCid, Instance::InstanceSize(), Heap::kOld);

    *transition_sentinel_ ^=
        Object::Allocate(kNullCid, Instance::InstanceSize(), Heap::kOld);
  }

  // Allocate and initialize optimizing compiler constants.
  {
    *unknown_constant_ ^=
        Object::Allocate(kNullCid, Instance::InstanceSize(), Heap::kOld);
    *non_constant_ ^=
        Object::Allocate(kNullCid, Instance::InstanceSize(), Heap::kOld);
  }

  // Allocate the remaining VM internal classes.
  cls = Class::New<UnresolvedClass>();
  unresolved_class_class_ = cls.raw();

  cls = Class::New<TypeArguments>();
  type_arguments_class_ = cls.raw();

  cls = Class::New<PatchClass>();
  patch_class_class_ = cls.raw();

  cls = Class::New<Function>();
  function_class_ = cls.raw();

  cls = Class::New<ClosureData>();
  closure_data_class_ = cls.raw();

  cls = Class::New<SignatureData>();
  signature_data_class_ = cls.raw();

  cls = Class::New<RedirectionData>();
  redirection_data_class_ = cls.raw();

  cls = Class::New<Field>();
  field_class_ = cls.raw();

  cls = Class::New<LiteralToken>();
  literal_token_class_ = cls.raw();

  cls = Class::New<TokenStream>();
  token_stream_class_ = cls.raw();

  cls = Class::New<Script>();
  script_class_ = cls.raw();

  cls = Class::New<Library>();
  library_class_ = cls.raw();

  cls = Class::New<Namespace>();
  namespace_class_ = cls.raw();

  cls = Class::New<Code>();
  code_class_ = cls.raw();

  cls = Class::New<Instructions>();
  instructions_class_ = cls.raw();

  cls = Class::New<ObjectPool>();
  object_pool_class_ = cls.raw();

  cls = Class::New<PcDescriptors>();
  pc_descriptors_class_ = cls.raw();

  cls = Class::New<CodeSourceMap>();
  code_source_map_class_ = cls.raw();

  cls = Class::New<StackMap>();
  stackmap_class_ = cls.raw();

  cls = Class::New<LocalVarDescriptors>();
  var_descriptors_class_ = cls.raw();

  cls = Class::New<ExceptionHandlers>();
  exception_handlers_class_ = cls.raw();

  cls = Class::New<Context>();
  context_class_ = cls.raw();

  cls = Class::New<ContextScope>();
  context_scope_class_ = cls.raw();

  cls = Class::New<SingleTargetCache>();
  singletargetcache_class_ = cls.raw();

  cls = Class::New<UnlinkedCall>();
  unlinkedcall_class_ = cls.raw();

  cls = Class::New<ICData>();
  icdata_class_ = cls.raw();

  cls = Class::New<MegamorphicCache>();
  megamorphic_cache_class_ = cls.raw();

  cls = Class::New<SubtypeTestCache>();
  subtypetestcache_class_ = cls.raw();

  cls = Class::New<ApiError>();
  api_error_class_ = cls.raw();

  cls = Class::New<LanguageError>();
  language_error_class_ = cls.raw();

  cls = Class::New<UnhandledException>();
  unhandled_exception_class_ = cls.raw();

  cls = Class::New<UnwindError>();
  unwind_error_class_ = cls.raw();

  ASSERT(class_class() != null_);

  // Pre-allocate classes in the vm isolate so that we can for example create a
  // symbol table and populate it with some frequently used strings as symbols.
  cls = Class::New<Array>();
  isolate->object_store()->set_array_class(cls);
  cls.set_type_arguments_field_offset(Array::type_arguments_offset());
  cls.set_num_type_arguments(1);
  cls.set_num_own_type_arguments(1);
  cls = Class::New<Array>(kImmutableArrayCid);
  isolate->object_store()->set_immutable_array_class(cls);
  cls.set_type_arguments_field_offset(Array::type_arguments_offset());
  cls.set_num_type_arguments(1);
  cls.set_num_own_type_arguments(1);
  cls = Class::New<GrowableObjectArray>();
  isolate->object_store()->set_growable_object_array_class(cls);
  cls.set_type_arguments_field_offset(
      GrowableObjectArray::type_arguments_offset());
  cls.set_num_type_arguments(1);
  cls = Class::NewStringClass(kOneByteStringCid);
  isolate->object_store()->set_one_byte_string_class(cls);
  cls = Class::NewStringClass(kTwoByteStringCid);
  isolate->object_store()->set_two_byte_string_class(cls);
  cls = Class::New<Mint>();
  isolate->object_store()->set_mint_class(cls);
  cls = Class::New<Bigint>();
  isolate->object_store()->set_bigint_class(cls);
  cls = Class::New<Double>();
  isolate->object_store()->set_double_class(cls);

  // Ensure that class kExternalTypedDataUint8ArrayCid is registered as we
  // need it when reading in the token stream of bootstrap classes in the VM
  // isolate.
  Class::NewExternalTypedDataClass(kExternalTypedDataUint8ArrayCid);

  // Needed for object pools of VM isolate stubs.
  Class::NewTypedDataClass(kTypedDataInt8ArrayCid);

  // Allocate and initialize the empty_type_arguments instance.
  {
    uword address = heap->Allocate(TypeArguments::InstanceSize(0), Heap::kOld);
    InitializeObject(address, TypeArguments::kClassId,
                     TypeArguments::InstanceSize(0), true);
    TypeArguments::initializeHandle(
        empty_type_arguments_,
        reinterpret_cast<RawTypeArguments*>(address + kHeapObjectTag));
    empty_type_arguments_->StoreSmi(&empty_type_arguments_->raw_ptr()->length_,
                                    Smi::New(0));
    empty_type_arguments_->StoreSmi(&empty_type_arguments_->raw_ptr()->hash_,
                                    Smi::New(0));
    // instantiations_ field is initialized to null and should not be used.
    empty_type_arguments_->SetCanonical();
  }

  // Allocate and initialize the empty_array instance.
  {
    uword address = heap->Allocate(Array::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kImmutableArrayCid, Array::InstanceSize(0), true);
    Array::initializeHandle(
        empty_array_, reinterpret_cast<RawArray*>(address + kHeapObjectTag));
    empty_array_->StoreSmi(&empty_array_->raw_ptr()->length_, Smi::New(0));
    empty_array_->SetCanonical();
  }

  Smi& smi = Smi::Handle();
  // Allocate and initialize the zero_array instance.
  {
    uword address = heap->Allocate(Array::InstanceSize(1), Heap::kOld);
    InitializeObject(address, kImmutableArrayCid, Array::InstanceSize(1), true);
    Array::initializeHandle(
        zero_array_, reinterpret_cast<RawArray*>(address + kHeapObjectTag));
    zero_array_->StoreSmi(&zero_array_->raw_ptr()->length_, Smi::New(1));
    smi = Smi::New(0);
    zero_array_->SetAt(0, smi);
    zero_array_->SetCanonical();
  }

  // Allocate and initialize the empty context object.
  {
    uword address = heap->Allocate(Context::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kContextCid, Context::InstanceSize(0), true);
    Context::initializeHandle(empty_context_, reinterpret_cast<RawContext*>(
                                                  address + kHeapObjectTag));
    empty_context_->StoreNonPointer(&empty_context_->raw_ptr()->num_variables_,
                                    0);
    empty_context_->SetCanonical();
  }

  // Allocate and initialize the canonical empty context scope object.
  {
    uword address = heap->Allocate(ContextScope::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kContextScopeCid, ContextScope::InstanceSize(0),
                     true);
    ContextScope::initializeHandle(
        empty_context_scope_,
        reinterpret_cast<RawContextScope*>(address + kHeapObjectTag));
    empty_context_scope_->StoreNonPointer(
        &empty_context_scope_->raw_ptr()->num_variables_, 0);
    empty_context_scope_->StoreNonPointer(
        &empty_context_scope_->raw_ptr()->is_implicit_, true);
    empty_context_scope_->SetCanonical();
  }

  // Allocate and initialize the canonical empty object pool object.
  {
    uword address = heap->Allocate(ObjectPool::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kObjectPoolCid, ObjectPool::InstanceSize(0),
                     true);
    ObjectPool::initializeHandle(
        empty_object_pool_,
        reinterpret_cast<RawObjectPool*>(address + kHeapObjectTag));
    empty_object_pool_->StoreNonPointer(&empty_object_pool_->raw_ptr()->length_,
                                        0);
    empty_object_pool_->SetCanonical();
  }

  // Allocate and initialize the empty_descriptors instance.
  {
    uword address = heap->Allocate(PcDescriptors::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kPcDescriptorsCid, PcDescriptors::InstanceSize(0),
                     true);
    PcDescriptors::initializeHandle(
        empty_descriptors_,
        reinterpret_cast<RawPcDescriptors*>(address + kHeapObjectTag));
    empty_descriptors_->StoreNonPointer(&empty_descriptors_->raw_ptr()->length_,
                                        0);
    empty_descriptors_->SetCanonical();
  }

  // Allocate and initialize the canonical empty variable descriptor object.
  {
    uword address =
        heap->Allocate(LocalVarDescriptors::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kLocalVarDescriptorsCid,
                     LocalVarDescriptors::InstanceSize(0), true);
    LocalVarDescriptors::initializeHandle(
        empty_var_descriptors_,
        reinterpret_cast<RawLocalVarDescriptors*>(address + kHeapObjectTag));
    empty_var_descriptors_->StoreNonPointer(
        &empty_var_descriptors_->raw_ptr()->num_entries_, 0);
    empty_var_descriptors_->SetCanonical();
  }

  // Allocate and initialize the canonical empty exception handler info object.
  // The vast majority of all functions do not contain an exception handler
  // and can share this canonical descriptor.
  {
    uword address =
        heap->Allocate(ExceptionHandlers::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kExceptionHandlersCid,
                     ExceptionHandlers::InstanceSize(0), true);
    ExceptionHandlers::initializeHandle(
        empty_exception_handlers_,
        reinterpret_cast<RawExceptionHandlers*>(address + kHeapObjectTag));
    empty_exception_handlers_->StoreNonPointer(
        &empty_exception_handlers_->raw_ptr()->num_entries_, 0);
    empty_exception_handlers_->SetCanonical();
  }

  // The VM isolate snapshot object table is initialized to an empty array
  // as we do not have any VM isolate snapshot at this time.
  *vm_isolate_snapshot_object_table_ = Object::empty_array().raw();

  cls = Class::New<Instance>(kDynamicCid);
  cls.set_is_abstract();
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_finalized();
  cls.set_is_type_finalized();
  cls.set_is_cycle_free();
  dynamic_class_ = cls.raw();

  cls = Class::New<Instance>(kVoidCid);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_finalized();
  cls.set_is_type_finalized();
  cls.set_is_cycle_free();
  void_class_ = cls.raw();

  cls = Class::New<Instance>(kVectorCid);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_finalized();
  cls.set_is_type_finalized();
  cls.set_is_cycle_free();
  vector_class_ = cls.raw();

  cls = Class::New<Type>();
  cls.set_is_finalized();
  cls.set_is_type_finalized();
  cls.set_is_cycle_free();

  cls = dynamic_class_;
  *dynamic_type_ = Type::NewNonParameterizedType(cls);

  cls = void_class_;
  *void_type_ = Type::NewNonParameterizedType(cls);

  cls = vector_class_;
  *vector_type_ = Type::NewNonParameterizedType(cls);

  // Since TypeArguments objects are passed as function arguments, make them
  // behave as Dart instances, although they are just VM objects.
  // Note that we cannot set the super type to ObjectType, which does not live
  // in the vm isolate. See special handling in Class::SuperClass().
  cls = type_arguments_class_;
  cls.set_interfaces(Object::empty_array());
  cls.SetFields(Object::empty_array());
  cls.SetFunctions(Object::empty_array());

  // Allocate and initialize singleton true and false boolean objects.
  cls = Class::New<Bool>();
  isolate->object_store()->set_bool_class(cls);
  *bool_true_ = Bool::New(true);
  *bool_false_ = Bool::New(false);

  *smi_illegal_cid_ = Smi::New(kIllegalCid);

  String& error_str = String::Handle();
  error_str = String::New("SnapshotWriter Error", Heap::kOld);
  *snapshot_writer_error_ =
      LanguageError::New(error_str, Report::kError, Heap::kOld);
  error_str = String::New("Branch offset overflow", Heap::kOld);
  *branch_offset_error_ =
      LanguageError::New(error_str, Report::kBailout, Heap::kOld);
  error_str = String::New("Speculative inlining failed", Heap::kOld);
  *speculative_inlining_error_ =
      LanguageError::New(error_str, Report::kBailout, Heap::kOld);
  error_str = String::New("Background Compilation Failed", Heap::kOld);
  *background_compilation_error_ =
      LanguageError::New(error_str, Report::kBailout, Heap::kOld);

  // Some thread fields need to be reinitialized as null constants have not been
  // initialized until now.
  Thread* thr = Thread::Current();
  ASSERT(thr != NULL);
  thr->clear_sticky_error();
  thr->clear_pending_functions();

  ASSERT(!null_object_->IsSmi());
  ASSERT(!null_array_->IsSmi());
  ASSERT(null_array_->IsArray());
  ASSERT(!null_string_->IsSmi());
  ASSERT(null_string_->IsString());
  ASSERT(!null_instance_->IsSmi());
  ASSERT(null_instance_->IsInstance());
  ASSERT(!null_function_->IsSmi());
  ASSERT(null_function_->IsFunction());
  ASSERT(!null_type_arguments_->IsSmi());
  ASSERT(null_type_arguments_->IsTypeArguments());
  ASSERT(!empty_type_arguments_->IsSmi());
  ASSERT(empty_type_arguments_->IsTypeArguments());
  ASSERT(!empty_array_->IsSmi());
  ASSERT(empty_array_->IsArray());
  ASSERT(!zero_array_->IsSmi());
  ASSERT(zero_array_->IsArray());
  ASSERT(!empty_context_->IsSmi());
  ASSERT(empty_context_->IsContext());
  ASSERT(!empty_context_scope_->IsSmi());
  ASSERT(empty_context_scope_->IsContextScope());
  ASSERT(!empty_descriptors_->IsSmi());
  ASSERT(empty_descriptors_->IsPcDescriptors());
  ASSERT(!empty_var_descriptors_->IsSmi());
  ASSERT(empty_var_descriptors_->IsLocalVarDescriptors());
  ASSERT(!empty_exception_handlers_->IsSmi());
  ASSERT(empty_exception_handlers_->IsExceptionHandlers());
  ASSERT(!sentinel_->IsSmi());
  ASSERT(sentinel_->IsInstance());
  ASSERT(!transition_sentinel_->IsSmi());
  ASSERT(transition_sentinel_->IsInstance());
  ASSERT(!unknown_constant_->IsSmi());
  ASSERT(unknown_constant_->IsInstance());
  ASSERT(!non_constant_->IsSmi());
  ASSERT(non_constant_->IsInstance());
  ASSERT(!bool_true_->IsSmi());
  ASSERT(bool_true_->IsBool());
  ASSERT(!bool_false_->IsSmi());
  ASSERT(bool_false_->IsBool());
  ASSERT(smi_illegal_cid_->IsSmi());
  ASSERT(!snapshot_writer_error_->IsSmi());
  ASSERT(snapshot_writer_error_->IsLanguageError());
  ASSERT(!branch_offset_error_->IsSmi());
  ASSERT(branch_offset_error_->IsLanguageError());
  ASSERT(!speculative_inlining_error_->IsSmi());
  ASSERT(speculative_inlining_error_->IsLanguageError());
  ASSERT(!background_compilation_error_->IsSmi());
  ASSERT(background_compilation_error_->IsLanguageError());
  ASSERT(!vm_isolate_snapshot_object_table_->IsSmi());
  ASSERT(vm_isolate_snapshot_object_table_->IsArray());
}

// An object visitor which will mark all visited objects. This is used to
// premark all objects in the vm_isolate_ heap.  Also precalculates hash
// codes so that we can get the identity hash code of objects in the read-
// only VM isolate.
class FinalizeVMIsolateVisitor : public ObjectVisitor {
 public:
  FinalizeVMIsolateVisitor()
#if defined(HASH_IN_OBJECT_HEADER)
      : counter_(1337)
#endif
  {
  }

  void VisitObject(RawObject* obj) {
    // Free list elements should never be marked.
    ASSERT(!obj->IsMarked());
    // No forwarding corpses in the VM isolate.
    ASSERT(!obj->IsForwardingCorpse());
    if (!obj->IsFreeListElement()) {
      ASSERT(obj->IsVMHeapObject());
      obj->SetMarkBitUnsynchronized();
      if (obj->IsStringInstance()) {
        RawString* str = reinterpret_cast<RawString*>(obj);
        intptr_t hash = String::Hash(str);
        String::SetCachedHash(str, hash);
      }
#if defined(HASH_IN_OBJECT_HEADER)
      // These objects end up in the read-only VM isolate which is shared
      // between isolates, so we have to prepopulate them with identity hash
      // codes, since we can't add hash codes later.
      if (Object::GetCachedHash(obj) == 0) {
        // Some classes have identity hash codes that depend on their contents,
        // not per object.
        ASSERT(!obj->IsStringInstance());
        if (!obj->IsMint() && !obj->IsDouble() && !obj->IsBigint() &&
            !obj->IsRawNull() && !obj->IsBool()) {
          counter_ += 2011;  // The year Dart was announced and a prime.
          counter_ &= 0x3fffffff;
          if (counter_ == 0) counter_++;
          Object::SetCachedHash(obj, counter_);
        }
      }
#endif
    }
  }

 private:
#if defined(HASH_IN_OBJECT_HEADER)
  int32_t counter_;
#endif
};

#define SET_CLASS_NAME(class_name, name)                                       \
  cls = class_name##_class();                                                  \
  cls.set_name(Symbols::name());

void Object::FinalizeVMIsolate(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  // Allocate the parameter arrays for method extractor types and names.
  *extractor_parameter_types_ = Array::New(1, Heap::kOld);
  extractor_parameter_types_->SetAt(0, Object::dynamic_type());
  *extractor_parameter_names_ = Array::New(1, Heap::kOld);
  extractor_parameter_names_->SetAt(0, Symbols::This());

  ASSERT(!extractor_parameter_types_->IsSmi());
  ASSERT(extractor_parameter_types_->IsArray());
  ASSERT(!extractor_parameter_names_->IsSmi());
  ASSERT(extractor_parameter_names_->IsArray());

  // Set up names for all VM singleton classes.
  Class& cls = Class::Handle();

  SET_CLASS_NAME(class, Class);
  SET_CLASS_NAME(dynamic, Dynamic);
  SET_CLASS_NAME(void, Void);
  SET_CLASS_NAME(unresolved_class, UnresolvedClass);
  SET_CLASS_NAME(type_arguments, TypeArguments);
  SET_CLASS_NAME(patch_class, PatchClass);
  SET_CLASS_NAME(function, Function);
  SET_CLASS_NAME(closure_data, ClosureData);
  SET_CLASS_NAME(signature_data, SignatureData);
  SET_CLASS_NAME(redirection_data, RedirectionData);
  SET_CLASS_NAME(field, Field);
  SET_CLASS_NAME(literal_token, LiteralToken);
  SET_CLASS_NAME(token_stream, TokenStream);
  SET_CLASS_NAME(script, Script);
  SET_CLASS_NAME(library, LibraryClass);
  SET_CLASS_NAME(namespace, Namespace);
  SET_CLASS_NAME(code, Code);
  SET_CLASS_NAME(instructions, Instructions);
  SET_CLASS_NAME(object_pool, ObjectPool);
  SET_CLASS_NAME(code_source_map, CodeSourceMap);
  SET_CLASS_NAME(pc_descriptors, PcDescriptors);
  SET_CLASS_NAME(stackmap, StackMap);
  SET_CLASS_NAME(var_descriptors, LocalVarDescriptors);
  SET_CLASS_NAME(exception_handlers, ExceptionHandlers);
  SET_CLASS_NAME(context, Context);
  SET_CLASS_NAME(context_scope, ContextScope);
  SET_CLASS_NAME(singletargetcache, SingleTargetCache);
  SET_CLASS_NAME(unlinkedcall, UnlinkedCall);
  SET_CLASS_NAME(icdata, ICData);
  SET_CLASS_NAME(megamorphic_cache, MegamorphicCache);
  SET_CLASS_NAME(subtypetestcache, SubtypeTestCache);
  SET_CLASS_NAME(api_error, ApiError);
  SET_CLASS_NAME(language_error, LanguageError);
  SET_CLASS_NAME(unhandled_exception, UnhandledException);
  SET_CLASS_NAME(unwind_error, UnwindError);

  // Set up names for object array and one byte string class which are
  // pre-allocated in the vm isolate also.
  cls = isolate->object_store()->array_class();
  cls.set_name(Symbols::_List());
  cls = isolate->object_store()->one_byte_string_class();
  cls.set_name(Symbols::OneByteString());

  // Set up names for the pseudo-classes for free list elements and forwarding
  // corpses. Mainly this makes VM debugging easier.
  cls = isolate->class_table()->At(kFreeListElement);
  cls.set_name(Symbols::FreeListElement());
  cls = isolate->class_table()->At(kForwardingCorpse);
  cls.set_name(Symbols::ForwardingCorpse());

  {
    ASSERT(isolate == Dart::vm_isolate());
    Thread* thread = Thread::Current();
    WritableVMIsolateScope scope(thread);
    HeapIterationScope iteration(thread);
    FinalizeVMIsolateVisitor premarker;
    ASSERT(isolate->heap()->UsedInWords(Heap::kNew) == 0);
    iteration.IterateOldObjectsNoImagePages(&premarker);
    // Make the VM isolate read-only again after setting all objects as marked.
    // Note objects in image pages are already pre-marked.
  }
}

void Object::set_vm_isolate_snapshot_object_table(const Array& table) {
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  *vm_isolate_snapshot_object_table_ = table.raw();
}

// Make unused space in an object whose type has been transformed safe
// for traversing during GC.
// The unused part of the transformed object is marked as an TypedDataInt8Array
// object.
void Object::MakeUnusedSpaceTraversable(const Object& obj,
                                        intptr_t original_size,
                                        intptr_t used_size) {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() > 0);
  ASSERT(!obj.IsNull());
  ASSERT(original_size >= used_size);
  if (original_size > used_size) {
    intptr_t leftover_size = original_size - used_size;

    uword addr = RawObject::ToAddr(obj.raw()) + used_size;
    if (leftover_size >= TypedData::InstanceSize(0)) {
      // Update the leftover space as a TypedDataInt8Array object.
      RawTypedData* raw =
          reinterpret_cast<RawTypedData*>(RawObject::FromAddr(addr));
      uword new_tags = RawObject::ClassIdTag::update(kTypedDataInt8ArrayCid, 0);
      new_tags = RawObject::SizeTag::update(leftover_size, new_tags);
      uint32_t tags = raw->ptr()->tags_;
      uint32_t old_tags;
      // TODO(iposva): Investigate whether CompareAndSwapWord is necessary.
      do {
        old_tags = tags;
        // We can't use obj.CompareAndSwapTags here because we don't have a
        // handle for the new object.
        tags = AtomicOperations::CompareAndSwapUint32(&raw->ptr()->tags_,
                                                      old_tags, new_tags);
      } while (tags != old_tags);

      intptr_t leftover_len = (leftover_size - TypedData::InstanceSize(0));
      ASSERT(TypedData::InstanceSize(leftover_len) == leftover_size);
      raw->StoreSmi(&(raw->ptr()->length_), Smi::New(leftover_len));
    } else {
      // Update the leftover space as a basic object.
      ASSERT(leftover_size == Object::InstanceSize());
      RawObject* raw = reinterpret_cast<RawObject*>(RawObject::FromAddr(addr));
      uword new_tags = RawObject::ClassIdTag::update(kInstanceCid, 0);
      new_tags = RawObject::SizeTag::update(leftover_size, new_tags);
      uint32_t tags = raw->ptr()->tags_;
      uint32_t old_tags;
      // TODO(iposva): Investigate whether CompareAndSwapWord is necessary.
      do {
        old_tags = tags;
        tags = obj.CompareAndSwapTags(old_tags, new_tags);
      } while (tags != old_tags);
    }
  }
}

void Object::VerifyBuiltinVtables() {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Class& cls = Class::Handle(thread->zone(), Class::null());
  for (intptr_t cid = (kIllegalCid + 1); cid < kNumPredefinedCids; cid++) {
    if (isolate->class_table()->HasValidClassAt(cid)) {
      cls ^= isolate->class_table()->At(cid);
      ASSERT(builtin_vtables_[cid] == cls.raw_ptr()->handle_vtable_);
    }
  }
  ASSERT(builtin_vtables_[kFreeListElement] == 0);
  ASSERT(builtin_vtables_[kForwardingCorpse] == 0);
#endif
}

void Object::RegisterClass(const Class& cls,
                           const String& name,
                           const Library& lib) {
  ASSERT(name.Length() > 0);
  ASSERT(name.CharAt(0) != '_');
  cls.set_name(name);
  lib.AddClass(cls);
}

void Object::RegisterPrivateClass(const Class& cls,
                                  const String& public_class_name,
                                  const Library& lib) {
  ASSERT(public_class_name.Length() > 0);
  ASSERT(public_class_name.CharAt(0) == '_');
  String& str = String::Handle();
  str = lib.PrivateName(public_class_name);
  cls.set_name(str);
  lib.AddClass(cls);
}

// Initialize a new isolate from source or from a snapshot.
//
// There are three possibilities:
//   1. Running a Kernel binary.  This function will bootstrap from the KERNEL
//      file.
//   2. There is no snapshot.  This function will bootstrap from source.
//   3. There is a snapshot.  The caller should initialize from the snapshot.
//
// A non-NULL kernel argument indicates (1).  A NULL kernel indicates (2) or
// (3), depending on whether the VM is compiled with DART_NO_SNAPSHOT defined or
// not.
RawError* Object::Init(Isolate* isolate, kernel::Program* kernel_program) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(isolate == thread->isolate());
#if !defined(DART_PRECOMPILED_RUNTIME)
  const bool is_kernel = (kernel_program != NULL);
#endif
  NOT_IN_PRODUCT(TimelineDurationScope tds(thread, Timeline::GetIsolateStream(),
                                           "Object::Init");)

#if defined(DART_NO_SNAPSHOT)
  bool bootstrapping = Dart::vm_snapshot_kind() == Snapshot::kNone;
#elif defined(DART_PRECOMPILED_RUNTIME)
  bool bootstrapping = false;
#else
  bool bootstrapping = is_kernel;
#endif

  if (bootstrapping) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    // Object::Init version when we are bootstrapping from source or from a
    // Kernel binary.
    ObjectStore* object_store = isolate->object_store();

    Class& cls = Class::Handle(zone);
    Type& type = Type::Handle(zone);
    Array& array = Array::Handle(zone);
    Library& lib = Library::Handle(zone);

    // All RawArray fields will be initialized to an empty array, therefore
    // initialize array class first.
    cls = Class::New<Array>();
    object_store->set_array_class(cls);

    // VM classes that are parameterized (Array, ImmutableArray,
    // GrowableObjectArray, and LinkedHashMap) are also pre-finalized, so
    // CalculateFieldOffsets() is not called, so we need to set the offset of
    // their type_arguments_ field, which is explicitly declared in their
    // respective Raw* classes.
    cls.set_type_arguments_field_offset(Array::type_arguments_offset());
    cls.set_num_type_arguments(1);

    // Set up the growable object array class (Has to be done after the array
    // class is setup as one of its field is an array object).
    cls = Class::New<GrowableObjectArray>();
    object_store->set_growable_object_array_class(cls);
    cls.set_type_arguments_field_offset(
        GrowableObjectArray::type_arguments_offset());
    cls.set_num_type_arguments(1);

    // Initialize hash set for canonical_type_.
    const intptr_t kInitialCanonicalTypeSize = 16;
    array = HashTables::New<CanonicalTypeSet>(kInitialCanonicalTypeSize,
                                              Heap::kOld);
    object_store->set_canonical_types(array);

    // Initialize hash set for canonical_type_arguments_.
    const intptr_t kInitialCanonicalTypeArgumentsSize = 4;
    array = HashTables::New<CanonicalTypeArgumentsSet>(
        kInitialCanonicalTypeArgumentsSize, Heap::kOld);
    object_store->set_canonical_type_arguments(array);

    // Setup type class early in the process.
    const Class& type_cls = Class::Handle(zone, Class::New<Type>());
    const Class& type_ref_cls = Class::Handle(zone, Class::New<TypeRef>());
    const Class& type_parameter_cls =
        Class::Handle(zone, Class::New<TypeParameter>());
    const Class& bounded_type_cls =
        Class::Handle(zone, Class::New<BoundedType>());
    const Class& mixin_app_type_cls =
        Class::Handle(zone, Class::New<MixinAppType>());
    const Class& library_prefix_cls =
        Class::Handle(zone, Class::New<LibraryPrefix>());

    // Pre-allocate the OneByteString class needed by the symbol table.
    cls = Class::NewStringClass(kOneByteStringCid);
    object_store->set_one_byte_string_class(cls);

    // Pre-allocate the TwoByteString class needed by the symbol table.
    cls = Class::NewStringClass(kTwoByteStringCid);
    object_store->set_two_byte_string_class(cls);

    // Setup the symbol table for the symbols created in the isolate.
    Symbols::SetupSymbolTable(isolate);

    // Set up the libraries array before initializing the core library.
    const GrowableObjectArray& libraries =
        GrowableObjectArray::Handle(zone, GrowableObjectArray::New(Heap::kOld));
    object_store->set_libraries(libraries);

    // Pre-register the core library.
    Library::InitCoreLibrary(isolate);

    // Basic infrastructure has been setup, initialize the class dictionary.
    const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
    ASSERT(!core_lib.IsNull());

    const GrowableObjectArray& pending_classes =
        GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
    object_store->set_pending_classes(pending_classes);

    // Now that the symbol table is initialized and that the core dictionary as
    // well as the core implementation dictionary have been setup, preallocate
    // remaining classes and register them by name in the dictionaries.
    String& name = String::Handle(zone);
    cls = object_store->array_class();  // Was allocated above.
    RegisterPrivateClass(cls, Symbols::_List(), core_lib);
    pending_classes.Add(cls);
    // We cannot use NewNonParameterizedType(cls), because Array is
    // parameterized.  Warning: class _List has not been patched yet. Its
    // declared number of type parameters is still 0. It will become 1 after
    // patching. The array type allocated below represents the raw type _List
    // and not _List<E> as we could expect. Use with caution.
    type ^= Type::New(Object::Handle(zone, cls.raw()),
                      TypeArguments::Handle(zone), TokenPosition::kNoSource);
    type.SetIsFinalized();
    type ^= type.Canonicalize();
    object_store->set_array_type(type);

    cls = object_store->growable_object_array_class();  // Was allocated above.
    RegisterPrivateClass(cls, Symbols::_GrowableList(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Array>(kImmutableArrayCid);
    object_store->set_immutable_array_class(cls);
    cls.set_type_arguments_field_offset(Array::type_arguments_offset());
    cls.set_num_type_arguments(1);
    ASSERT(object_store->immutable_array_class() !=
           object_store->array_class());
    cls.set_is_prefinalized();
    RegisterPrivateClass(cls, Symbols::_ImmutableList(), core_lib);
    pending_classes.Add(cls);

    cls = object_store->one_byte_string_class();  // Was allocated above.
    RegisterPrivateClass(cls, Symbols::OneByteString(), core_lib);
    pending_classes.Add(cls);

    cls = object_store->two_byte_string_class();  // Was allocated above.
    RegisterPrivateClass(cls, Symbols::TwoByteString(), core_lib);
    pending_classes.Add(cls);

    cls = Class::NewStringClass(kExternalOneByteStringCid);
    object_store->set_external_one_byte_string_class(cls);
    RegisterPrivateClass(cls, Symbols::ExternalOneByteString(), core_lib);
    pending_classes.Add(cls);

    cls = Class::NewStringClass(kExternalTwoByteStringCid);
    object_store->set_external_two_byte_string_class(cls);
    RegisterPrivateClass(cls, Symbols::ExternalTwoByteString(), core_lib);
    pending_classes.Add(cls);

    // Pre-register the isolate library so the native class implementations can
    // be hooked up before compiling it.
    Library& isolate_lib = Library::Handle(
        zone, Library::LookupLibrary(thread, Symbols::DartIsolate()));
    if (isolate_lib.IsNull()) {
      isolate_lib = Library::NewLibraryHelper(Symbols::DartIsolate(), true);
      isolate_lib.SetLoadRequested();
      isolate_lib.Register(thread);
    }
    object_store->set_bootstrap_library(ObjectStore::kIsolate, isolate_lib);
    ASSERT(!isolate_lib.IsNull());
    ASSERT(isolate_lib.raw() == Library::IsolateLibrary());

    cls = Class::New<Capability>();
    RegisterPrivateClass(cls, Symbols::_CapabilityImpl(), isolate_lib);
    pending_classes.Add(cls);

    cls = Class::New<ReceivePort>();
    RegisterPrivateClass(cls, Symbols::_RawReceivePortImpl(), isolate_lib);
    pending_classes.Add(cls);

    cls = Class::New<SendPort>();
    RegisterPrivateClass(cls, Symbols::_SendPortImpl(), isolate_lib);
    pending_classes.Add(cls);

    const Class& stacktrace_cls = Class::Handle(zone, Class::New<StackTrace>());
    RegisterPrivateClass(stacktrace_cls, Symbols::_StackTrace(), core_lib);
    pending_classes.Add(stacktrace_cls);
    // Super type set below, after Object is allocated.

    cls = Class::New<RegExp>();
    RegisterPrivateClass(cls, Symbols::_RegExp(), core_lib);
    pending_classes.Add(cls);

    // Initialize the base interfaces used by the core VM classes.

    // Allocate and initialize the pre-allocated classes in the core library.
    // The script and token index of these pre-allocated classes is set up in
    // the parser when the corelib script is compiled (see
    // Parser::ParseClassDefinition).
    cls = Class::New<Instance>(kInstanceCid);
    object_store->set_object_class(cls);
    cls.set_name(Symbols::Object());
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    core_lib.AddClass(cls);
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_object_type(type);

    cls = Class::New<Bool>();
    object_store->set_bool_class(cls);
    RegisterClass(cls, Symbols::Bool(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Instance>(kNullCid);
    object_store->set_null_class(cls);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    RegisterClass(cls, Symbols::Null(), core_lib);
    pending_classes.Add(cls);

    ASSERT(!library_prefix_cls.IsNull());
    RegisterPrivateClass(library_prefix_cls, Symbols::_LibraryPrefix(),
                         core_lib);
    pending_classes.Add(library_prefix_cls);

    RegisterPrivateClass(type_cls, Symbols::Type(), core_lib);
    pending_classes.Add(type_cls);

    RegisterPrivateClass(type_ref_cls, Symbols::TypeRef(), core_lib);
    pending_classes.Add(type_ref_cls);

    RegisterPrivateClass(type_parameter_cls, Symbols::TypeParameter(),
                         core_lib);
    pending_classes.Add(type_parameter_cls);

    RegisterPrivateClass(bounded_type_cls, Symbols::BoundedType(), core_lib);
    pending_classes.Add(bounded_type_cls);

    RegisterPrivateClass(mixin_app_type_cls, Symbols::MixinAppType(), core_lib);
    pending_classes.Add(mixin_app_type_cls);

    cls = Class::New<Integer>();
    object_store->set_integer_implementation_class(cls);
    RegisterPrivateClass(cls, Symbols::IntegerImplementation(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Smi>();
    object_store->set_smi_class(cls);
    RegisterPrivateClass(cls, Symbols::_Smi(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Mint>();
    object_store->set_mint_class(cls);
    RegisterPrivateClass(cls, Symbols::_Mint(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Bigint>();
    object_store->set_bigint_class(cls);
    RegisterPrivateClass(cls, Symbols::_Bigint(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Double>();
    object_store->set_double_class(cls);
    RegisterPrivateClass(cls, Symbols::_Double(), core_lib);
    pending_classes.Add(cls);

    // Class that represents the Dart class _Closure and C++ class Closure.
    cls = Class::New<Closure>();
    object_store->set_closure_class(cls);
    cls.ResetFinalization();  // To calculate field offsets from Dart source.
    RegisterPrivateClass(cls, Symbols::_Closure(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<WeakProperty>();
    object_store->set_weak_property_class(cls);
    RegisterPrivateClass(cls, Symbols::_WeakProperty(), core_lib);

// Pre-register the mirrors library so we can place the vm class
// MirrorReference there rather than the core library.
#if !defined(DART_PRECOMPILED_RUNTIME)
    lib = Library::LookupLibrary(thread, Symbols::DartMirrors());
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(Symbols::DartMirrors(), true);
      lib.SetLoadRequested();
      lib.Register(thread);
    }
    object_store->set_bootstrap_library(ObjectStore::kMirrors, lib);
    ASSERT(!lib.IsNull());
    ASSERT(lib.raw() == Library::MirrorsLibrary());

    cls = Class::New<MirrorReference>();
    RegisterPrivateClass(cls, Symbols::_MirrorReference(), lib);
#endif

    // Pre-register the collection library so we can place the vm class
    // LinkedHashMap there rather than the core library.
    lib = Library::LookupLibrary(thread, Symbols::DartCollection());
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(Symbols::DartCollection(), true);
      lib.SetLoadRequested();
      lib.Register(thread);
    }

    object_store->set_bootstrap_library(ObjectStore::kCollection, lib);
    ASSERT(!lib.IsNull());
    ASSERT(lib.raw() == Library::CollectionLibrary());
    cls = Class::New<LinkedHashMap>();
    object_store->set_linked_hash_map_class(cls);
    cls.set_type_arguments_field_offset(LinkedHashMap::type_arguments_offset());
    cls.set_num_type_arguments(2);
    cls.set_num_own_type_arguments(0);
    RegisterPrivateClass(cls, Symbols::_LinkedHashMap(), lib);
    pending_classes.Add(cls);

    // Pre-register the developer library so we can place the vm class
    // UserTag there rather than the core library.
    lib = Library::LookupLibrary(thread, Symbols::DartDeveloper());
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(Symbols::DartDeveloper(), true);
      lib.SetLoadRequested();
      lib.Register(thread);
    }
    object_store->set_bootstrap_library(ObjectStore::kDeveloper, lib);
    ASSERT(!lib.IsNull());
    ASSERT(lib.raw() == Library::DeveloperLibrary());
    cls = Class::New<UserTag>();
    RegisterPrivateClass(cls, Symbols::_UserTag(), lib);
    pending_classes.Add(cls);

    // Setup some default native field classes which can be extended for
    // specifying native fields in dart classes.
    Library::InitNativeWrappersLibrary(isolate, is_kernel);
    ASSERT(object_store->native_wrappers_library() != Library::null());

    // Pre-register the typed_data library so the native class implementations
    // can be hooked up before compiling it.
    lib = Library::LookupLibrary(thread, Symbols::DartTypedData());
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(Symbols::DartTypedData(), true);
      lib.SetLoadRequested();
      lib.Register(thread);
    }
    object_store->set_bootstrap_library(ObjectStore::kTypedData, lib);
    ASSERT(!lib.IsNull());
    ASSERT(lib.raw() == Library::TypedDataLibrary());
#define REGISTER_TYPED_DATA_CLASS(clazz)                                       \
  cls = Class::NewTypedDataClass(kTypedData##clazz##ArrayCid);                 \
  RegisterPrivateClass(cls, Symbols::_##clazz##List(), lib);

    DART_CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_CLASS);
#undef REGISTER_TYPED_DATA_CLASS
#define REGISTER_TYPED_DATA_VIEW_CLASS(clazz)                                  \
  cls = Class::NewTypedDataViewClass(kTypedData##clazz##ViewCid);              \
  RegisterPrivateClass(cls, Symbols::_##clazz##View(), lib);                   \
  pending_classes.Add(cls);

    CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_VIEW_CLASS);
    cls = Class::NewTypedDataViewClass(kByteDataViewCid);
    RegisterPrivateClass(cls, Symbols::_ByteDataView(), lib);
    pending_classes.Add(cls);
#undef REGISTER_TYPED_DATA_VIEW_CLASS
#define REGISTER_EXT_TYPED_DATA_CLASS(clazz)                                   \
  cls = Class::NewExternalTypedDataClass(kExternalTypedData##clazz##Cid);      \
  RegisterPrivateClass(cls, Symbols::_External##clazz(), lib);

    cls = Class::New<Instance>(kByteBufferCid);
    cls.set_instance_size(0);
    cls.set_next_field_offset(-kWordSize);
    RegisterPrivateClass(cls, Symbols::_ByteBuffer(), lib);
    pending_classes.Add(cls);

    CLASS_LIST_TYPED_DATA(REGISTER_EXT_TYPED_DATA_CLASS);
#undef REGISTER_EXT_TYPED_DATA_CLASS
    // Register Float32x4, Int32x4, and Float64x2 in the object store.
    cls = Class::New<Float32x4>();
    RegisterPrivateClass(cls, Symbols::_Float32x4(), lib);
    pending_classes.Add(cls);
    object_store->set_float32x4_class(cls);

    cls = Class::New<Instance>(kIllegalCid);
    RegisterClass(cls, Symbols::Float32x4(), lib);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_float32x4_type(type);

    cls = Class::New<Int32x4>();
    RegisterPrivateClass(cls, Symbols::_Int32x4(), lib);
    pending_classes.Add(cls);
    object_store->set_int32x4_class(cls);

    cls = Class::New<Instance>(kIllegalCid);
    RegisterClass(cls, Symbols::Int32x4(), lib);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_int32x4_type(type);

    cls = Class::New<Float64x2>();
    RegisterPrivateClass(cls, Symbols::_Float64x2(), lib);
    pending_classes.Add(cls);
    object_store->set_float64x2_class(cls);

    cls = Class::New<Instance>(kIllegalCid);
    RegisterClass(cls, Symbols::Float64x2(), lib);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_float64x2_type(type);

    // Set the super type of class StackTrace to Object type so that the
    // 'toString' method is implemented.
    type = object_store->object_type();
    stacktrace_cls.set_super_type(type);

    // Abstract class that represents the Dart class Function.
    cls = Class::New<Instance>(kIllegalCid);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    RegisterClass(cls, Symbols::Function(), core_lib);
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_function_type(type);

    cls = Class::New<Number>();
    RegisterClass(cls, Symbols::Number(), core_lib);
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_number_type(type);

    cls = Class::New<Instance>(kIllegalCid);
    RegisterClass(cls, Symbols::Int(), core_lib);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_int_type(type);

    cls = Class::New<Instance>(kIllegalCid);
    RegisterPrivateClass(cls, Symbols::Int64(), core_lib);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_int64_type(type);

    cls = Class::New<Instance>(kIllegalCid);
    RegisterClass(cls, Symbols::Double(), core_lib);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_double_type(type);

    name = Symbols::_String().raw();
    cls = Class::New<Instance>(kIllegalCid);
    RegisterClass(cls, name, core_lib);
    cls.set_num_type_arguments(0);
    cls.set_num_own_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_string_type(type);

    cls = object_store->bool_class();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_bool_type(type);

    cls = object_store->smi_class();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_smi_type(type);

    cls = object_store->mint_class();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_mint_type(type);

    // The classes 'void' and 'dynamic' are phony classes to make type checking
    // more regular; they live in the VM isolate. The class 'void' is not
    // registered in the class dictionary because its name is a reserved word.
    // The class 'dynamic' is registered in the class dictionary because its
    // name is a built-in identifier (this is wrong).  The corresponding types
    // are stored in the object store.
    cls = object_store->null_class();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_null_type(type);

    // Consider removing when/if Null becomes an ordinary class.
    type = object_store->object_type();
    cls.set_super_type(type);

    // Finish the initialization by compiling the bootstrap scripts containing
    // the base interfaces and the implementation of the internal classes.
    const Error& error =
        Error::Handle(zone, Bootstrap::DoBootstrapping(kernel_program));
    if (!error.IsNull()) {
      return error.raw();
    }

    ClassFinalizer::VerifyBootstrapClasses();

    // Set up the intrinsic state of all functions (core, math and typed data).
    Intrinsifier::InitializeState();

    // Set up recognized state of all functions (core, math and typed data).
    MethodRecognizer::InitializeState();

    // Adds static const fields (class ids) to the class 'ClassID');
    lib = Library::LookupLibrary(thread, Symbols::DartInternal());
    ASSERT(!lib.IsNull());
    cls = lib.LookupClassAllowPrivate(Symbols::ClassID());
    ASSERT(!cls.IsNull());
    cls.InjectCIDFields();

    isolate->object_store()->InitKnownObjects();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  } else {
    // Object::Init version when we are running in a version of dart that has a
    // full snapshot linked in and an isolate is initialized using the full
    // snapshot.
    ObjectStore* object_store = isolate->object_store();

    Class& cls = Class::Handle(zone);

    // Set up empty classes in the object store, these will get initialized
    // correctly when we read from the snapshot.  This is done to allow
    // bootstrapping of reading classes from the snapshot.  Some classes are not
    // stored in the object store. Yet we still need to create their Class
    // object so that they get put into the class_table (as a side effect of
    // Class::New()).
    cls = Class::New<Instance>(kInstanceCid);
    object_store->set_object_class(cls);

    cls = Class::New<LibraryPrefix>();
    cls = Class::New<Type>();
    cls = Class::New<TypeRef>();
    cls = Class::New<TypeParameter>();
    cls = Class::New<BoundedType>();
    cls = Class::New<MixinAppType>();

    cls = Class::New<Array>();
    object_store->set_array_class(cls);

    cls = Class::New<Array>(kImmutableArrayCid);
    object_store->set_immutable_array_class(cls);

    cls = Class::New<GrowableObjectArray>();
    object_store->set_growable_object_array_class(cls);

    cls = Class::New<LinkedHashMap>();
    object_store->set_linked_hash_map_class(cls);

    cls = Class::New<Float32x4>();
    object_store->set_float32x4_class(cls);

    cls = Class::New<Int32x4>();
    object_store->set_int32x4_class(cls);

    cls = Class::New<Float64x2>();
    object_store->set_float64x2_class(cls);

#define REGISTER_TYPED_DATA_CLASS(clazz)                                       \
  cls = Class::NewTypedDataClass(kTypedData##clazz##Cid);
    CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_CLASS);
#undef REGISTER_TYPED_DATA_CLASS
#define REGISTER_TYPED_DATA_VIEW_CLASS(clazz)                                  \
  cls = Class::NewTypedDataViewClass(kTypedData##clazz##ViewCid);
    CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_VIEW_CLASS);
#undef REGISTER_TYPED_DATA_VIEW_CLASS
    cls = Class::NewTypedDataViewClass(kByteDataViewCid);
#define REGISTER_EXT_TYPED_DATA_CLASS(clazz)                                   \
  cls = Class::NewExternalTypedDataClass(kExternalTypedData##clazz##Cid);
    CLASS_LIST_TYPED_DATA(REGISTER_EXT_TYPED_DATA_CLASS);
#undef REGISTER_EXT_TYPED_DATA_CLASS

    cls = Class::New<Instance>(kByteBufferCid);

    cls = Class::New<Integer>();
    object_store->set_integer_implementation_class(cls);

    cls = Class::New<Smi>();
    object_store->set_smi_class(cls);

    cls = Class::New<Mint>();
    object_store->set_mint_class(cls);

    cls = Class::New<Double>();
    object_store->set_double_class(cls);

    cls = Class::New<Closure>();
    object_store->set_closure_class(cls);

    cls = Class::New<Bigint>();
    object_store->set_bigint_class(cls);

    cls = Class::NewStringClass(kOneByteStringCid);
    object_store->set_one_byte_string_class(cls);

    cls = Class::NewStringClass(kTwoByteStringCid);
    object_store->set_two_byte_string_class(cls);

    cls = Class::NewStringClass(kExternalOneByteStringCid);
    object_store->set_external_one_byte_string_class(cls);

    cls = Class::NewStringClass(kExternalTwoByteStringCid);
    object_store->set_external_two_byte_string_class(cls);

    cls = Class::New<Bool>();
    object_store->set_bool_class(cls);

    cls = Class::New<Instance>(kNullCid);
    object_store->set_null_class(cls);

    cls = Class::New<Capability>();
    cls = Class::New<ReceivePort>();
    cls = Class::New<SendPort>();
    cls = Class::New<StackTrace>();
    cls = Class::New<RegExp>();
    cls = Class::New<Number>();

    cls = Class::New<WeakProperty>();
    object_store->set_weak_property_class(cls);

    cls = Class::New<MirrorReference>();
    cls = Class::New<UserTag>();
  }
  return Error::null();
}

#if defined(DEBUG)
bool Object::InVMHeap() const {
  if (FLAG_verify_handles && raw()->IsVMHeapObject()) {
    Heap* vm_isolate_heap = Dart::vm_isolate()->heap();
    ASSERT(vm_isolate_heap->Contains(RawObject::ToAddr(raw())));
  }
  return raw()->IsVMHeapObject();
}
#endif  // DEBUG

void Object::Print() const {
  THR_Print("%s\n", ToCString());
}

RawString* Object::DictionaryName() const {
  return String::null();
}

void Object::InitializeObject(uword address,
                              intptr_t class_id,
                              intptr_t size,
                              bool is_vm_object) {
  uword initial_value = (class_id == kInstructionsCid)
                            ? Assembler::GetBreakInstructionFiller()
                            : reinterpret_cast<uword>(null_);
  uword cur = address;
  uword end = address + size;
  while (cur < end) {
    *reinterpret_cast<uword*>(cur) = initial_value;
    cur += kWordSize;
  }
  uint32_t tags = 0;
  ASSERT(class_id != kIllegalCid);
  tags = RawObject::ClassIdTag::update(class_id, tags);
  tags = RawObject::SizeTag::update(size, tags);
  tags = RawObject::VMHeapObjectTag::update(is_vm_object, tags);
  reinterpret_cast<RawObject*>(address)->tags_ = tags;
#if defined(HASH_IN_OBJECT_HEADER)
  reinterpret_cast<RawObject*>(address)->hash_ = 0;
#endif
  ASSERT(is_vm_object == RawObject::IsVMHeapObject(tags));
}

void Object::CheckHandle() const {
#if defined(DEBUG)
  if (raw_ != Object::null()) {
    if ((reinterpret_cast<uword>(raw_) & kSmiTagMask) == kSmiTag) {
      ASSERT(vtable() == Smi::handle_vtable_);
      return;
    }
    intptr_t cid = raw_->GetClassId();
    if (cid >= kNumPredefinedCids) {
      cid = kInstanceCid;
    }
    ASSERT(vtable() == builtin_vtables_[cid]);
    if (FLAG_verify_handles) {
      Isolate* isolate = Isolate::Current();
      Heap* isolate_heap = isolate->heap();
      Heap* vm_isolate_heap = Dart::vm_isolate()->heap();
      ASSERT(isolate_heap->Contains(RawObject::ToAddr(raw_)) ||
             vm_isolate_heap->Contains(RawObject::ToAddr(raw_)));
    }
  }
#endif
}

RawObject* Object::Allocate(intptr_t cls_id, intptr_t size, Heap::Space space) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  // New space allocation allowed only in mutator thread (Dart thread);
  ASSERT(thread->IsMutatorThread() || (space != Heap::kNew));
  ASSERT(thread->no_callback_scope_depth() == 0);
  Heap* heap = isolate->heap();

  uword address = heap->Allocate(size, space);
  if (address == 0) {
    // Use the preallocated out of memory exception to avoid calling
    // into dart code or allocating any code.
    const Instance& exception =
        Instance::Handle(isolate->object_store()->out_of_memory());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }
#ifndef PRODUCT
  ClassTable* class_table = isolate->class_table();
  if (space == Heap::kNew) {
    class_table->UpdateAllocatedNew(cls_id, size);
  } else {
    class_table->UpdateAllocatedOld(cls_id, size);
  }
  const Class& cls = Class::Handle(class_table->At(cls_id));
  if (FLAG_profiler && cls.TraceAllocation(isolate)) {
    Profiler::SampleAllocation(thread, cls_id);
  }
#endif  // !PRODUCT
  NoSafepointScope no_safepoint;
  InitializeObject(address, cls_id, size, (isolate == Dart::vm_isolate()));
  RawObject* raw_obj = reinterpret_cast<RawObject*>(address + kHeapObjectTag);
  ASSERT(cls_id == RawObject::ClassIdTag::decode(raw_obj->ptr()->tags_));
  return raw_obj;
}

class StoreBufferUpdateVisitor : public ObjectPointerVisitor {
 public:
  explicit StoreBufferUpdateVisitor(Thread* thread, RawObject* obj)
      : ObjectPointerVisitor(thread->isolate()),
        thread_(thread),
        old_obj_(obj) {
    ASSERT(old_obj_->IsOldObject());
  }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** curr = first; curr <= last; ++curr) {
      RawObject* raw_obj = *curr;
      if (raw_obj->IsHeapObject() && raw_obj->IsNewObject()) {
        old_obj_->SetRememberedBit();
        thread_->StoreBufferAddObject(old_obj_);
        // Remembered this object. There is no need to continue searching.
        return;
      }
    }
  }

 private:
  Thread* thread_;
  RawObject* old_obj_;

  DISALLOW_COPY_AND_ASSIGN(StoreBufferUpdateVisitor);
};

bool Object::IsReadOnlyHandle() const {
  return Dart::IsReadOnlyHandle(reinterpret_cast<uword>(this));
}

bool Object::IsNotTemporaryScopedHandle() const {
  return (IsZoneHandle() || IsReadOnlyHandle());
}

RawObject* Object::Clone(const Object& orig, Heap::Space space) {
  const Class& cls = Class::Handle(orig.clazz());
  intptr_t size = orig.raw()->Size();
  RawObject* raw_clone = Object::Allocate(cls.id(), size, space);
  NoSafepointScope no_safepoint;
  // TODO(koda): This will trip when we start allocating black.
  // Revisit code below at that point, to account for the new write barrier.
  ASSERT(!raw_clone->IsMarked());
  // Copy the body of the original into the clone.
  uword orig_addr = RawObject::ToAddr(orig.raw());
  uword clone_addr = RawObject::ToAddr(raw_clone);
  static const intptr_t kHeaderSizeInBytes = sizeof(RawObject);
  memmove(reinterpret_cast<uint8_t*>(clone_addr + kHeaderSizeInBytes),
          reinterpret_cast<uint8_t*>(orig_addr + kHeaderSizeInBytes),
          size - kHeaderSizeInBytes);
  // Add clone to store buffer, if needed.
  if (!raw_clone->IsOldObject()) {
    // No need to remember an object in new space.
    return raw_clone;
  } else if (orig.raw()->IsOldObject() && !orig.raw()->IsRemembered()) {
    // Old original doesn't need to be remembered, so neither does the clone.
    return raw_clone;
  }
  StoreBufferUpdateVisitor visitor(Thread::Current(), raw_clone);
  raw_clone->VisitPointers(&visitor);
  return raw_clone;
}

RawString* Class::Name() const {
  return raw_ptr()->name_;
}

RawString* Class::ScrubbedName() const {
  return String::ScrubName(String::Handle(Name()));
}

RawString* Class::UserVisibleName() const {
#if !defined(PRODUCT)
  ASSERT(raw_ptr()->user_name_ != String::null());
  return raw_ptr()->user_name_;
#endif                               // !defined(PRODUCT)
  return GenerateUserVisibleName();  // No caching in PRODUCT, regenerate.
}

bool Class::IsInFullSnapshot() const {
  NoSafepointScope no_safepoint;
  return raw_ptr()->library_->ptr()->is_in_fullsnapshot_;
}

RawAbstractType* Class::RareType() const {
  const Type& type = Type::Handle(Type::New(
      *this, Object::null_type_arguments(), TokenPosition::kNoSource));
  return ClassFinalizer::FinalizeType(*this, type);
}

RawAbstractType* Class::DeclarationType() const {
  const TypeArguments& args = TypeArguments::Handle(type_parameters());
  const Type& type =
      Type::Handle(Type::New(*this, args, TokenPosition::kNoSource));
  return ClassFinalizer::FinalizeType(*this, type);
}

template <class FakeObject>
RawClass* Class::New() {
  ASSERT(Object::class_class() != Class::null());
  Class& result = Class::Handle();
  {
    RawObject* raw =
        Object::Allocate(Class::kClassId, Class::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  FakeObject fake;
  result.set_handle_vtable(fake.vtable());
  result.set_instance_size(FakeObject::InstanceSize());
  result.set_next_field_offset(FakeObject::NextFieldOffset());
  COMPILE_ASSERT((FakeObject::kClassId != kInstanceCid));
  result.set_id(FakeObject::kClassId);
  result.set_state_bits(0);
  if ((FakeObject::kClassId < kInstanceCid) ||
      (FakeObject::kClassId == kTypeArgumentsCid)) {
    // VM internal classes are done. There is no finalization needed or
    // possible in this case.
    result.set_is_finalized();
  } else {
    // VM backed classes are almost ready: run checks and resolve class
    // references, but do not recompute size.
    result.set_is_prefinalized();
  }
  result.set_type_arguments_field_offset_in_words(kNoTypeArguments);
  result.set_num_type_arguments(0);
  result.set_num_own_type_arguments(0);
  result.set_num_native_fields(0);
  result.set_token_pos(TokenPosition::kNoSource);
  result.InitEmptyFields();
  Isolate::Current()->RegisterClass(result);
  return result.raw();
}

static void ReportTooManyTypeArguments(const Class& cls) {
  Report::MessageF(Report::kError, Script::Handle(cls.script()),
                   cls.token_pos(), Report::AtLocation,
                   "too many type parameters declared in class '%s' or in its "
                   "super classes",
                   String::Handle(cls.Name()).ToCString());
  UNREACHABLE();
}

void Class::set_num_type_arguments(intptr_t value) const {
  if (!Utils::IsInt(16, value)) {
    ReportTooManyTypeArguments(*this);
  }
  StoreNonPointer(&raw_ptr()->num_type_arguments_, value);
}

void Class::set_num_own_type_arguments(intptr_t value) const {
  if (!Utils::IsInt(16, value)) {
    ReportTooManyTypeArguments(*this);
  }
  StoreNonPointer(&raw_ptr()->num_own_type_arguments_, value);
}

// Initialize class fields of type Array with empty array.
void Class::InitEmptyFields() {
  if (Object::empty_array().raw() == Array::null()) {
    // The empty array has not been initialized yet.
    return;
  }
  StorePointer(&raw_ptr()->interfaces_, Object::empty_array().raw());
  StorePointer(&raw_ptr()->constants_, Object::empty_array().raw());
  StorePointer(&raw_ptr()->functions_, Object::empty_array().raw());
  StorePointer(&raw_ptr()->fields_, Object::empty_array().raw());
  StorePointer(&raw_ptr()->invocation_dispatcher_cache_,
               Object::empty_array().raw());
}

RawArray* Class::OffsetToFieldMap(bool original_classes) const {
  Array& array = Array::Handle(raw_ptr()->offset_in_words_to_field_);
  if (array.IsNull()) {
    ASSERT(is_finalized());
    const intptr_t length = raw_ptr()->instance_size_in_words_;
    array = Array::New(length, Heap::kOld);
    Class& cls = Class::Handle(this->raw());
    Array& fields = Array::Handle();
    Field& f = Field::Handle();
    while (!cls.IsNull()) {
      fields = cls.fields();
      for (intptr_t i = 0; i < fields.Length(); ++i) {
        f ^= fields.At(i);
        if (f.is_instance()) {
          array.SetAt(f.Offset() >> kWordSizeLog2, f);
        }
      }
      cls = cls.SuperClass(original_classes);
    }
    StorePointer(&raw_ptr()->offset_in_words_to_field_, array.raw());
  }
  return array.raw();
}

bool Class::HasInstanceFields() const {
  const Array& field_array = Array::Handle(fields());
  Field& field = Field::Handle();
  for (intptr_t i = 0; i < field_array.Length(); ++i) {
    field ^= field_array.At(i);
    if (!field.is_static()) {
      return true;
    }
  }
  return false;
}

class FunctionName {
 public:
  FunctionName(const String& name, String* tmp_string)
      : name_(name), tmp_string_(tmp_string) {}
  bool Matches(const Function& function) const {
    if (name_.IsSymbol()) {
      return name_.raw() == function.name();
    } else {
      *tmp_string_ = function.name();
      return name_.Equals(*tmp_string_);
    }
  }
  intptr_t Hash() const { return name_.Hash(); }

 private:
  const String& name_;
  String* tmp_string_;
};

// Traits for looking up Functions by name.
class ClassFunctionsTraits {
 public:
  static const char* Name() { return "ClassFunctionsTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsFunction() && b.IsFunction());
    // Function objects are always canonical.
    return a.raw() == b.raw();
  }
  static bool IsMatch(const FunctionName& name, const Object& obj) {
    return name.Matches(Function::Cast(obj));
  }
  static uword Hash(const Object& key) {
    return String::HashRawSymbol(Function::Cast(key).name());
  }
  static uword Hash(const FunctionName& name) { return name.Hash(); }
};
typedef UnorderedHashSet<ClassFunctionsTraits> ClassFunctionsSet;

void Class::SetFunctions(const Array& value) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->functions_, value.raw());
  const intptr_t len = value.Length();
  if (len >= kFunctionLookupHashTreshold) {
    ClassFunctionsSet set(HashTables::New<ClassFunctionsSet>(len, Heap::kOld));
    Function& func = Function::Handle();
    for (intptr_t i = 0; i < len; ++i) {
      func ^= value.At(i);
      // Verify that all the functions in the array have this class as owner.
      ASSERT(func.Owner() == raw());
      set.Insert(func);
    }
    StorePointer(&raw_ptr()->functions_hash_table_, set.Release().raw());
  } else {
    StorePointer(&raw_ptr()->functions_hash_table_, Array::null());
  }
}

void Class::AddFunction(const Function& function) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  const Array& arr = Array::Handle(functions());
  const Array& new_arr =
      Array::Handle(Array::Grow(arr, arr.Length() + 1, Heap::kOld));
  new_arr.SetAt(arr.Length(), function);
  StorePointer(&raw_ptr()->functions_, new_arr.raw());
  // Add to hash table, if any.
  const intptr_t new_len = new_arr.Length();
  if (new_len == kFunctionLookupHashTreshold) {
    // Transition to using hash table.
    SetFunctions(new_arr);
  } else if (new_len > kFunctionLookupHashTreshold) {
    ClassFunctionsSet set(raw_ptr()->functions_hash_table_);
    set.Insert(function);
    StorePointer(&raw_ptr()->functions_hash_table_, set.Release().raw());
  }
}

void Class::RemoveFunction(const Function& function) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  const Array& arr = Array::Handle(functions());
  StorePointer(&raw_ptr()->functions_, Object::empty_array().raw());
  StorePointer(&raw_ptr()->functions_hash_table_, Array::null());
  Function& entry = Function::Handle();
  for (intptr_t i = 0; i < arr.Length(); i++) {
    entry ^= arr.At(i);
    if (function.raw() != entry.raw()) {
      AddFunction(entry);
    }
  }
}

RawFunction* Class::FunctionFromIndex(intptr_t idx) const {
  const Array& funcs = Array::Handle(functions());
  if ((idx < 0) || (idx >= funcs.Length())) {
    return Function::null();
  }
  Function& func = Function::Handle();
  func ^= funcs.At(idx);
  ASSERT(!func.IsNull());
  return func.raw();
}

RawFunction* Class::ImplicitClosureFunctionFromIndex(intptr_t idx) const {
  const Array& funcs = Array::Handle(functions());
  if ((idx < 0) || (idx >= funcs.Length())) {
    return Function::null();
  }
  Function& func = Function::Handle();
  func ^= funcs.At(idx);
  ASSERT(!func.IsNull());
  if (!func.HasImplicitClosureFunction()) {
    return Function::null();
  }
  const Function& closure_func =
      Function::Handle(func.ImplicitClosureFunction());
  ASSERT(!closure_func.IsNull());
  return closure_func.raw();
}

intptr_t Class::FindImplicitClosureFunctionIndex(const Function& needle) const {
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return -1;
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  Function& function = thread->FunctionHandle();
  funcs ^= functions();
  ASSERT(!funcs.IsNull());
  Function& implicit_closure = Function::Handle(thread->zone());
  const intptr_t len = funcs.Length();
  for (intptr_t i = 0; i < len; i++) {
    function ^= funcs.At(i);
    implicit_closure ^= function.implicit_closure_function();
    if (implicit_closure.IsNull()) {
      // Skip non-implicit closure functions.
      continue;
    }
    if (needle.raw() == implicit_closure.raw()) {
      return i;
    }
  }
  // No function found.
  return -1;
}

intptr_t Class::FindInvocationDispatcherFunctionIndex(
    const Function& needle) const {
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return -1;
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  Object& object = thread->ObjectHandle();
  funcs ^= invocation_dispatcher_cache();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  for (intptr_t i = 0; i < len; i++) {
    object = funcs.At(i);
    // The invocation_dispatcher_cache is a table with some entries that
    // are functions.
    if (object.IsFunction()) {
      if (Function::Cast(object).raw() == needle.raw()) {
        return i;
      }
    }
  }
  // No function found.
  return -1;
}

RawFunction* Class::InvocationDispatcherFunctionFromIndex(intptr_t idx) const {
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Array& dispatcher_cache = thread->ArrayHandle();
  Object& object = thread->ObjectHandle();
  dispatcher_cache ^= invocation_dispatcher_cache();
  object = dispatcher_cache.At(idx);
  if (!object.IsFunction()) {
    return Function::null();
  }
  return Function::Cast(object).raw();
}

void Class::set_signature_function(const Function& value) const {
  ASSERT(value.IsClosureFunction() || value.IsSignatureFunction());
  StorePointer(&raw_ptr()->signature_function_, value.raw());
}

void Class::set_state_bits(intptr_t bits) const {
  StoreNonPointer(&raw_ptr()->state_bits_, static_cast<uint16_t>(bits));
}

void Class::set_library(const Library& value) const {
  StorePointer(&raw_ptr()->library_, value.raw());
}

void Class::set_type_parameters(const TypeArguments& value) const {
  StorePointer(&raw_ptr()->type_parameters_, value.raw());
}

intptr_t Class::NumTypeParameters(Thread* thread) const {
  if (IsMixinApplication() && !is_mixin_type_applied()) {
    ClassFinalizer::ApplyMixinType(*this);
  }
  if (type_parameters() == TypeArguments::null()) {
    const intptr_t cid = id();
    if ((cid == kArrayCid) || (cid == kImmutableArrayCid) ||
        (cid == kGrowableObjectArrayCid)) {
      return 1;  // List's type parameter may not have been parsed yet.
    }
    return 0;
  }
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(thread);
  TypeArguments& type_params = thread->TypeArgumentsHandle();
  type_params = type_parameters();
  return type_params.Length();
}

intptr_t Class::NumOwnTypeArguments() const {
  // Return cached value if already calculated.
  if (num_own_type_arguments() != kUnknownNumTypeArguments) {
    return num_own_type_arguments();
  }
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  const intptr_t num_type_params = NumTypeParameters();
  if (!FLAG_overlap_type_arguments || (num_type_params == 0) ||
      (super_type() == AbstractType::null()) ||
      (super_type() == isolate->object_store()->object_type())) {
    set_num_own_type_arguments(num_type_params);
    return num_type_params;
  }
  ASSERT(!IsMixinApplication() || is_mixin_type_applied());
  const AbstractType& sup_type = AbstractType::Handle(zone, super_type());
  const TypeArguments& sup_type_args =
      TypeArguments::Handle(zone, sup_type.arguments());
  if (sup_type_args.IsNull()) {
    // The super type is raw or the super class is non generic.
    // In either case, overlapping is not possible.
    set_num_own_type_arguments(num_type_params);
    return num_type_params;
  }
  const intptr_t num_sup_type_args = sup_type_args.Length();
  // At this point, the super type may or may not be finalized. In either case,
  // the result of this function must remain the same.
  // The value of num_sup_type_args may increase when the super type is
  // finalized, but the last num_sup_type_args type arguments will not be
  // modified by finalization, only shifted to higher indices in the vector.
  // They may however get wrapped in a BoundedType, which we skip.
  // The super type may not even be resolved yet. This is not necessary, since
  // we only check for matching type parameters, which are resolved by default.
  const TypeArguments& type_params =
      TypeArguments::Handle(zone, type_parameters());
  // Determine the maximum overlap of a prefix of the vector consisting of the
  // type parameters of this class with a suffix of the vector consisting of the
  // type arguments of the super type of this class.
  // The number of own type arguments of this class is the number of its type
  // parameters minus the number of type arguments in the overlap.
  // Attempt to overlap the whole vector of type parameters; reduce the size
  // of the vector (keeping the first type parameter) until it fits or until
  // its size is zero.
  TypeParameter& type_param = TypeParameter::Handle(zone);
  AbstractType& sup_type_arg = AbstractType::Handle(zone);
  for (intptr_t num_overlapping_type_args =
           (num_type_params < num_sup_type_args) ? num_type_params
                                                 : num_sup_type_args;
       num_overlapping_type_args > 0; num_overlapping_type_args--) {
    intptr_t i = 0;
    for (; i < num_overlapping_type_args; i++) {
      type_param ^= type_params.TypeAt(i);
      sup_type_arg = sup_type_args.TypeAt(num_sup_type_args -
                                          num_overlapping_type_args + i);
      // BoundedType can nest in case the finalized super type has bounded type
      // arguments that overlap multiple times in its own super class chain.
      while (sup_type_arg.IsBoundedType()) {
        sup_type_arg = BoundedType::Cast(sup_type_arg).type();
      }
      if (!type_param.Equals(sup_type_arg)) break;
    }
    if (i == num_overlapping_type_args) {
      // Overlap found.
      set_num_own_type_arguments(num_type_params - num_overlapping_type_args);
      return num_type_params - num_overlapping_type_args;
    }
  }
  // No overlap found.
  set_num_own_type_arguments(num_type_params);
  return num_type_params;
}

intptr_t Class::NumTypeArguments() const {
  // Return cached value if already calculated.
  if (num_type_arguments() != kUnknownNumTypeArguments) {
    return num_type_arguments();
  }
  // To work properly, this call requires the super class of this class to be
  // resolved, which is checked by the type_class() call on the super type.
  // Note that calling type_class() on a MixinAppType fails.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Class& cls = Class::Handle(zone);
  AbstractType& sup_type = AbstractType::Handle(zone);
  cls = raw();
  intptr_t num_type_args = 0;
  do {
    // Calling NumOwnTypeArguments() on a mixin application class will setup the
    // type parameters if not already done.
    num_type_args += cls.NumOwnTypeArguments();
    // Super type of Object class is null.
    if ((cls.super_type() == AbstractType::null()) ||
        (cls.super_type() == isolate->object_store()->object_type())) {
      break;
    }
    sup_type = cls.super_type();
    // A BoundedType, TypeRef, or function type can appear as type argument of
    // sup_type, but not as sup_type itself.
    ASSERT(sup_type.IsType());
    ClassFinalizer::ResolveTypeClass(cls, Type::Cast(sup_type));
    cls = sup_type.type_class();
    ASSERT(!cls.IsTypedefClass());
  } while (true);
  set_num_type_arguments(num_type_args);
  return num_type_args;
}

RawClass* Class::SuperClass(bool original_classes) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  if (super_type() == AbstractType::null()) {
    if (id() == kTypeArgumentsCid) {
      // Pretend TypeArguments objects are Dart instances.
      return isolate->class_table()->At(kInstanceCid);
    }
    return Class::null();
  }
  const AbstractType& sup_type = AbstractType::Handle(zone, super_type());
  const intptr_t type_class_id = sup_type.type_class_id();
  if (original_classes) {
    return isolate->GetClassForHeapWalkAt(type_class_id);
  } else {
    return isolate->class_table()->At(type_class_id);
  }
}

void Class::set_super_type(const AbstractType& value) const {
  ASSERT(value.IsNull() || (value.IsType() && !value.IsDynamicType()) ||
         value.IsMixinAppType());
  StorePointer(&raw_ptr()->super_type_, value.raw());
}

RawTypeParameter* Class::LookupTypeParameter(const String& type_name) const {
  ASSERT(!type_name.IsNull());
  Thread* thread = Thread::Current();
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(thread);
  REUSABLE_TYPE_PARAMETER_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  TypeArguments& type_params = thread->TypeArgumentsHandle();
  TypeParameter& type_param = thread->TypeParameterHandle();
  String& type_param_name = thread->StringHandle();

  type_params ^= type_parameters();
  if (!type_params.IsNull()) {
    const intptr_t num_type_params = type_params.Length();
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      type_param_name = type_param.name();
      if (type_param_name.Equals(type_name)) {
        return type_param.raw();
      }
    }
  }
  return TypeParameter::null();
}

void Class::CalculateFieldOffsets() const {
  Array& flds = Array::Handle(fields());
  const Class& super = Class::Handle(SuperClass());
  intptr_t offset = 0;
  intptr_t type_args_field_offset = kNoTypeArguments;
  if (super.IsNull()) {
    offset = Instance::NextFieldOffset();
    ASSERT(offset > 0);
  } else {
    ASSERT(super.is_finalized() || super.is_prefinalized());
    type_args_field_offset = super.type_arguments_field_offset();
    offset = super.next_field_offset();
    ASSERT(offset > 0);
    // We should never call CalculateFieldOffsets for native wrapper
    // classes, assert this.
    ASSERT(num_native_fields() == 0);
    set_num_native_fields(super.num_native_fields());
  }
  // If the super class is parameterized, use the same type_arguments field,
  // otherwise, if this class is the first in the super chain to be
  // parameterized, introduce a new type_arguments field.
  if (type_args_field_offset == kNoTypeArguments) {
    const TypeArguments& type_params = TypeArguments::Handle(type_parameters());
    if (!type_params.IsNull()) {
      ASSERT(type_params.Length() > 0);
      // The instance needs a type_arguments field.
      type_args_field_offset = offset;
      offset += kWordSize;
    }
  }
  set_type_arguments_field_offset(type_args_field_offset);
  ASSERT(offset > 0);
  Field& field = Field::Handle();
  intptr_t len = flds.Length();
  for (intptr_t i = 0; i < len; i++) {
    field ^= flds.At(i);
    // Offset is computed only for instance fields.
    if (!field.is_static()) {
      ASSERT(field.Offset() == 0);
      field.SetOffset(offset);
      offset += kWordSize;
    }
  }
  set_instance_size(RoundedAllocationSize(offset));
  set_next_field_offset(offset);
}

RawFunction* Class::GetInvocationDispatcher(const String& target_name,
                                            const Array& args_desc,
                                            RawFunction::Kind kind,
                                            bool create_if_absent) const {
  enum { kNameIndex = 0, kArgsDescIndex, kFunctionIndex, kEntrySize };

  ASSERT(kind == RawFunction::kNoSuchMethodDispatcher ||
         kind == RawFunction::kInvokeFieldDispatcher);
  Function& dispatcher = Function::Handle();
  Array& cache = Array::Handle(invocation_dispatcher_cache());
  ASSERT(!cache.IsNull());
  String& name = String::Handle();
  Array& desc = Array::Handle();
  intptr_t i = 0;
  for (; i < cache.Length(); i += kEntrySize) {
    name ^= cache.At(i + kNameIndex);
    if (name.IsNull()) break;  // Reached last entry.
    if (!name.Equals(target_name)) continue;
    desc ^= cache.At(i + kArgsDescIndex);
    if (desc.raw() != args_desc.raw()) continue;
    dispatcher ^= cache.At(i + kFunctionIndex);
    if (dispatcher.kind() == kind) {
      // Found match.
      ASSERT(dispatcher.IsFunction());
      break;
    }
  }

  if (dispatcher.IsNull() && create_if_absent) {
    if (i == cache.Length()) {
      // Allocate new larger cache.
      intptr_t new_len = (cache.Length() == 0)
                             ? static_cast<intptr_t>(kEntrySize)
                             : cache.Length() * 2;
      cache ^= Array::Grow(cache, new_len);
      set_invocation_dispatcher_cache(cache);
    }
    dispatcher ^= CreateInvocationDispatcher(target_name, args_desc, kind);
    cache.SetAt(i + kNameIndex, target_name);
    cache.SetAt(i + kArgsDescIndex, args_desc);
    cache.SetAt(i + kFunctionIndex, dispatcher);
  }
  return dispatcher.raw();
}

RawFunction* Class::CreateInvocationDispatcher(const String& target_name,
                                               const Array& args_desc,
                                               RawFunction::Kind kind) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& invocation = Function::Handle(
      zone, Function::New(
                String::Handle(zone, Symbols::New(thread, target_name)), kind,
                false,  // Not static.
                false,  // Not const.
                false,  // Not abstract.
                false,  // Not external.
                false,  // Not native.
                *this, TokenPosition::kMinSource));
  ArgumentsDescriptor desc(args_desc);
  if (desc.TypeArgsLen() > 0) {
    // Make dispatcher function generic, since type arguments are passed.
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, TypeArguments::New(desc.TypeArgsLen()));
    // TODO(regis): Can we leave the array uninitialized to save memory?
    invocation.set_type_parameters(type_params);
  }

  invocation.set_num_fixed_parameters(desc.PositionalCount());
  invocation.SetNumOptionalParameters(desc.NamedCount(),
                                      false);  // Not positional.
  invocation.set_parameter_types(
      Array::Handle(zone, Array::New(desc.Count(), Heap::kOld)));
  invocation.set_parameter_names(
      Array::Handle(zone, Array::New(desc.Count(), Heap::kOld)));
  // Receiver.
  invocation.SetParameterTypeAt(0, Object::dynamic_type());
  invocation.SetParameterNameAt(0, Symbols::This());
  // Remaining positional parameters.
  intptr_t i = 1;
  for (; i < desc.PositionalCount(); i++) {
    invocation.SetParameterTypeAt(i, Object::dynamic_type());
    char name[64];
    OS::SNPrint(name, 64, ":p%" Pd, i);
    invocation.SetParameterNameAt(
        i, String::Handle(zone, Symbols::New(thread, name)));
  }

  // Named parameters.
  for (; i < desc.Count(); i++) {
    invocation.SetParameterTypeAt(i, Object::dynamic_type());
    intptr_t index = i - desc.PositionalCount();
    invocation.SetParameterNameAt(i, String::Handle(zone, desc.NameAt(index)));
  }
  invocation.set_result_type(Object::dynamic_type());
  invocation.set_is_debuggable(false);
  invocation.set_is_visible(false);
  invocation.set_is_reflectable(false);
  invocation.set_saved_args_desc(args_desc);

  return invocation.raw();
}

// Method extractors are used to create implicit closures from methods.
// When an expression obj.M is evaluated for the first time and receiver obj
// does not have a getter called M but has a method called M then an extractor
// is created and injected as a getter (under the name get:M) into the class
// owning method M.
RawFunction* Function::CreateMethodExtractor(const String& getter_name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(Field::IsGetterName(getter_name));
  const Function& closure_function =
      Function::Handle(zone, ImplicitClosureFunction());

  const Class& owner = Class::Handle(zone, closure_function.Owner());
  Function& extractor = Function::Handle(
      zone,
      Function::New(String::Handle(zone, Symbols::New(thread, getter_name)),
                    RawFunction::kMethodExtractor,
                    false,  // Not static.
                    false,  // Not const.
                    false,  // Not abstract.
                    false,  // Not external.
                    false,  // Not native.
                    owner, TokenPosition::kMethodExtractor));

  // Initialize signature: receiver is a single fixed parameter.
  const intptr_t kNumParameters = 1;
  extractor.set_num_fixed_parameters(kNumParameters);
  extractor.SetNumOptionalParameters(0, 0);
  extractor.set_parameter_types(Object::extractor_parameter_types());
  extractor.set_parameter_names(Object::extractor_parameter_names());
  extractor.set_result_type(Object::dynamic_type());
  extractor.set_kernel_offset(kernel_offset());
  extractor.set_kernel_data(TypedData::Handle(zone, kernel_data()));

  extractor.set_extracted_method_closure(closure_function);
  extractor.set_is_debuggable(false);
  extractor.set_is_visible(false);

  owner.AddFunction(extractor);

  return extractor.raw();
}

RawFunction* Function::GetMethodExtractor(const String& getter_name) const {
  ASSERT(Field::IsGetterName(getter_name));
  const Function& closure_function =
      Function::Handle(ImplicitClosureFunction());
  const Class& owner = Class::Handle(closure_function.Owner());
  Function& result = Function::Handle(owner.LookupDynamicFunction(getter_name));
  if (result.IsNull()) {
    result ^= CreateMethodExtractor(getter_name);
  }
  ASSERT(result.kind() == RawFunction::kMethodExtractor);
  return result.raw();
}

RawArray* Class::invocation_dispatcher_cache() const {
  return raw_ptr()->invocation_dispatcher_cache_;
}

void Class::set_invocation_dispatcher_cache(const Array& cache) const {
  StorePointer(&raw_ptr()->invocation_dispatcher_cache_, cache.raw());
}

void Class::Finalize() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(!Isolate::Current()->all_classes_finalized());
  ASSERT(!is_finalized());
  // Prefinalized classes have a VM internal representation and no Dart fields.
  // Their instance size  is precomputed and field offsets are known.
  if (!is_prefinalized()) {
    // Compute offsets of instance fields and instance size.
    CalculateFieldOffsets();
  }
  set_is_finalized();
}

class CHACodeArray : public WeakCodeReferences {
 public:
  explicit CHACodeArray(const Class& cls)
      : WeakCodeReferences(Array::Handle(cls.dependent_code())), cls_(cls) {}

  virtual void UpdateArrayTo(const Array& value) {
    // TODO(fschneider): Fails for classes in the VM isolate.
    cls_.set_dependent_code(value);
  }

  virtual void ReportDeoptimization(const Code& code) {
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      Function& function = Function::Handle(code.function());
      THR_Print("Deoptimizing %s because CHA optimized (%s).\n",
                function.ToFullyQualifiedCString(), cls_.ToCString());
    }
  }

  virtual void ReportSwitchingCode(const Code& code) {
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      Function& function = Function::Handle(code.function());
      THR_Print(
          "Switching %s to unoptimized code because CHA invalid"
          " (%s)\n",
          function.ToFullyQualifiedCString(), cls_.ToCString());
    }
  }

 private:
  const Class& cls_;
  DISALLOW_COPY_AND_ASSIGN(CHACodeArray);
};

#if defined(DEBUG)
static bool IsMutatorOrAtSafepoint() {
  Thread* thread = Thread::Current();
  return thread->IsMutatorThread() || thread->IsAtSafepoint();
}
#endif

void Class::RegisterCHACode(const Code& code) {
  if (FLAG_trace_cha) {
    THR_Print("RegisterCHACode '%s' depends on class '%s'\n",
              Function::Handle(code.function()).ToQualifiedCString(),
              ToCString());
  }
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  ASSERT(code.is_optimized());
  CHACodeArray a(*this);
  a.Register(code);
}

void Class::DisableCHAOptimizedCode(const Class& subclass) {
  ASSERT(Thread::Current()->IsMutatorThread());
  CHACodeArray a(*this);
  if (FLAG_trace_deoptimization && a.HasCodes() && !subclass.IsNull()) {
    THR_Print("Adding subclass %s\n", subclass.ToCString());
  }
  a.DisableCode();
}

void Class::DisableAllCHAOptimizedCode() {
  DisableCHAOptimizedCode(Class::Handle());
}

bool Class::TraceAllocation(Isolate* isolate) const {
#ifndef PRODUCT
  ClassTable* class_table = isolate->class_table();
  return class_table->TraceAllocationFor(id());
#else
  return false;
#endif
}

void Class::SetTraceAllocation(bool trace_allocation) const {
#ifndef PRODUCT
  Isolate* isolate = Isolate::Current();
  const bool changed = trace_allocation != this->TraceAllocation(isolate);
  if (changed) {
    ClassTable* class_table = isolate->class_table();
    class_table->SetTraceAllocationFor(id(), trace_allocation);
    DisableAllocationStub();
  }
#else
  UNREACHABLE();
#endif
}

bool Class::ValidatePostFinalizePatch(const Class& orig_class,
                                      Error* error) const {
  ASSERT(error != NULL);
  // Not allowed to add new fields in a post finalization patch.
  if (fields() != Object::empty_array().raw()) {
    *error = LanguageError::NewFormatted(
        *error,  // No previous error.
        Script::Handle(script()), token_pos(), Report::AtLocation,
        Report::kError, Heap::kNew,
        "new fields are not allowed for this patch");
    return false;
  }
  // There seem to be no functions, the patch is pointless.
  if (functions() == Object::empty_array().raw()) {
    *error = LanguageError::NewFormatted(*error,  // No previous error.
                                         Script::Handle(script()), token_pos(),
                                         Report::AtLocation, Report::kError,
                                         Heap::kNew, "no functions to patch");
    return false;
  }
  // Iterate over all functions that will be patched and make sure
  // the original function was declared 'external' and has not executed
  // so far i.e no code has been generated for it.
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  Zone* zone = thread->zone();
  const Array& funcs = Array::Handle(zone, functions());
  Function& func = Function::Handle(zone);
  Function& orig_func = Function::Handle(zone);
  String& name = String::Handle(zone);
  for (intptr_t i = 0; i < funcs.Length(); i++) {
    func ^= funcs.At(i);
    name ^= func.name();
    orig_func ^= orig_class.LookupFunctionAllowPrivate(name);
    if (!orig_func.IsNull()) {
      if (!orig_func.is_external() || orig_func.HasCode()) {
        // We can only patch external functions in a post finalized class.
        *error = LanguageError::NewFormatted(
            *error,  // No previous error.
            Script::Handle(script()), token_pos(), Report::AtLocation,
            Report::kError, Heap::kNew,
            !orig_func.is_external()
                ? "'%s' is not external and therefore cannot be patched"
                : "'%s' has already executed and therefore cannot be patched",
            name.ToCString());
        return false;
      }
    } else if (!Library::IsPrivate(name)) {
      // We can only have new private functions that are added.
      *error = LanguageError::NewFormatted(
          *error,  // No previous error.
          Script::Handle(script()), token_pos(), Report::AtLocation,
          Report::kError, Heap::kNew,
          "'%s' is not private and therefore cannot be patched",
          name.ToCString());
      return false;
    }
  }
  return true;
}

void Class::set_dependent_code(const Array& array) const {
  StorePointer(&raw_ptr()->dependent_code_, array.raw());
}

// Apply the members from the patch class to the original class.
bool Class::ApplyPatch(const Class& patch, Error* error) const {
  ASSERT(error != NULL);
  ASSERT(!is_finalized());
  // Shared handles used during the iteration.
  String& member_name = String::Handle();

  const PatchClass& patch_class = PatchClass::Handle(
      PatchClass::New(*this, Script::Handle(patch.script())));

  Array& orig_list = Array::Handle(functions());
  intptr_t orig_len = orig_list.Length();
  Array& patch_list = Array::Handle(patch.functions());
  intptr_t patch_len = patch_list.Length();

  // TODO(iposva): Verify that only patching existing methods and adding only
  // new private methods.
  Function& func = Function::Handle();
  Function& orig_func = Function::Handle();
  // Lookup the original implicit constructor, if any.
  member_name = Name();
  member_name = String::Concat(member_name, Symbols::Dot());
  Function& orig_implicit_ctor = Function::Handle(LookupFunction(member_name));
  if (!orig_implicit_ctor.IsNull() &&
      !orig_implicit_ctor.IsImplicitConstructor()) {
    // Not an implicit constructor, but a user declared one.
    orig_implicit_ctor = Function::null();
  }
  const GrowableObjectArray& new_functions =
      GrowableObjectArray::Handle(GrowableObjectArray::New(orig_len));
  for (intptr_t i = 0; i < orig_len; i++) {
    orig_func ^= orig_list.At(i);
    member_name ^= orig_func.name();
    func = patch.LookupFunction(member_name);
    if (func.IsNull()) {
      // Non-patched function is preserved, all patched functions are added in
      // the loop below.
      // However, an implicitly created constructor should not be preserved if
      // the patch provides a constructor or a factory. Wait for now.
      if (orig_func.raw() != orig_implicit_ctor.raw()) {
        new_functions.Add(orig_func);
      }
    } else if (func.UserVisibleSignature() !=
                   orig_func.UserVisibleSignature() &&
               !FLAG_ignore_patch_signature_mismatch) {
      // Compare user visible signatures to ignore different implicit parameters
      // when patching a constructor with a factory.
      *error = LanguageError::NewFormatted(
          *error,  // No previous error.
          Script::Handle(patch.script()), func.token_pos(), Report::AtLocation,
          Report::kError, Heap::kNew, "signature mismatch: '%s'",
          member_name.ToCString());
      return false;
    }
  }
  for (intptr_t i = 0; i < patch_len; i++) {
    func ^= patch_list.At(i);
    if (func.IsGenerativeConstructor() || func.IsFactory()) {
      // Do not preserve the original implicit constructor, if any.
      orig_implicit_ctor = Function::null();
    }
    func.set_owner(patch_class);
    new_functions.Add(func);
  }
  if (!orig_implicit_ctor.IsNull()) {
    // Preserve the original implicit constructor.
    new_functions.Add(orig_implicit_ctor);
  }
  Array& new_list = Array::Handle(Array::MakeFixedLength(new_functions));
  SetFunctions(new_list);

  // Merge the two list of fields. Raise an error when duplicates are found or
  // when a public field is being added.
  orig_list = fields();
  orig_len = orig_list.Length();
  patch_list = patch.fields();
  patch_len = patch_list.Length();

  Field& field = Field::Handle();
  Field& orig_field = Field::Handle();
  new_list = Array::New(patch_len + orig_len);
  for (intptr_t i = 0; i < patch_len; i++) {
    field ^= patch_list.At(i);
    field.set_owner(patch_class);
    member_name = field.name();
    // TODO(iposva): Verify non-public fields only.

    // Verify no duplicate additions.
    orig_field ^= LookupField(member_name);
    if (!orig_field.IsNull()) {
      *error = LanguageError::NewFormatted(
          *error,  // No previous error.
          Script::Handle(patch.script()), field.token_pos(), Report::AtLocation,
          Report::kError, Heap::kNew, "duplicate field: %s",
          member_name.ToCString());
      return false;
    }
    new_list.SetAt(i, field);
  }
  for (intptr_t i = 0; i < orig_len; i++) {
    field ^= orig_list.At(i);
    new_list.SetAt(patch_len + i, field);
  }
  SetFields(new_list);

  // The functions and fields in the patch class are no longer needed.
  // The patch class itself is also no longer needed.
  patch.SetFunctions(Object::empty_array());
  patch.SetFields(Object::empty_array());
  Library::Handle(patch.library()).RemovePatchClass(patch);
  return true;
}

static RawString* BuildClosureSource(const Array& formal_params,
                                     const String& expr) {
  const GrowableObjectArray& src_pieces =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  String& piece = String::Handle();
  src_pieces.Add(Symbols::LParen());
  // Add formal parameters.
  intptr_t num_formals = formal_params.Length();
  for (intptr_t i = 0; i < num_formals; i++) {
    if (i > 0) {
      src_pieces.Add(Symbols::CommaSpace());
    }
    piece ^= formal_params.At(i);
    src_pieces.Add(piece);
  }
  src_pieces.Add(Symbols::RParenArrow());
  src_pieces.Add(expr);
  src_pieces.Add(Symbols::Semicolon());
  return String::ConcatAll(Array::Handle(Array::MakeFixedLength(src_pieces)));
}

RawFunction* Function::EvaluateHelper(const Class& cls,
                                      const String& expr,
                                      const Array& param_names,
                                      bool is_static) {
  const String& func_src =
      String::Handle(BuildClosureSource(param_names, expr));
  Script& script = Script::Handle();
  script =
      Script::New(Symbols::EvalSourceUri(), func_src, RawScript::kEvaluateTag);
  // In order to tokenize the source, we need to get the key to mangle
  // private names from the library from which the class originates.
  const Library& lib = Library::Handle(cls.library());
  ASSERT(!lib.IsNull());
  const String& lib_key = String::Handle(lib.private_key());
  script.Tokenize(lib_key, false);

  const Function& func =
      Function::Handle(Function::NewEvalFunction(cls, script, is_static));
  func.set_result_type(Object::dynamic_type());
  const intptr_t num_implicit_params = is_static ? 0 : 1;
  func.set_num_fixed_parameters(num_implicit_params + param_names.Length());
  func.SetNumOptionalParameters(0, true);
  func.SetIsOptimizable(false);
  return func.raw();
}

RawObject* Class::Evaluate(const String& expr,
                           const Array& param_names,
                           const Array& param_values) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  if (id() < kInstanceCid) {
    const Instance& exception = Instance::Handle(
        String::New("Cannot evaluate against a VM internal class"));
    const Instance& stacktrace = Instance::Handle();
    return UnhandledException::New(exception, stacktrace);
  }

  const Function& eval_func = Function::Handle(
      Function::EvaluateHelper(*this, expr, param_names, true));
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(eval_func, param_values));
  return result.raw();
}

// Ensure that top level parsing of the class has been done.
RawError* Class::EnsureIsFinalized(Thread* thread) const {
  // Finalized classes have already been parsed.
  if (is_finalized()) {
    return Error::null();
  }
  if (Compiler::IsBackgroundCompilation()) {
    Compiler::AbortBackgroundCompilation(Thread::kNoDeoptId,
                                         "Class finalization while compiling");
  }
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread != NULL);
  const Error& error =
      Error::Handle(thread->zone(), Compiler::CompileClass(*this));
  if (!error.IsNull()) {
    ASSERT(thread == Thread::Current());
    if (thread->long_jump_base() != NULL) {
      Report::LongJump(error);
      UNREACHABLE();
    }
  }
  return error.raw();
}

void Class::SetFields(const Array& value) const {
  ASSERT(!value.IsNull());
#if defined(DEBUG)
  // Verify that all the fields in the array have this class as owner.
  Field& field = Field::Handle();
  intptr_t len = value.Length();
  for (intptr_t i = 0; i < len; i++) {
    field ^= value.At(i);
    ASSERT(field.IsOriginal());
    ASSERT(field.Owner() == raw());
  }
#endif
  // The value of static fields is already initialized to null.
  StorePointer(&raw_ptr()->fields_, value.raw());
}

void Class::AddField(const Field& field) const {
  const Array& arr = Array::Handle(fields());
  const Array& new_arr = Array::Handle(Array::Grow(arr, arr.Length() + 1));
  new_arr.SetAt(arr.Length(), field);
  SetFields(new_arr);
}

void Class::AddFields(const GrowableArray<const Field*>& new_fields) const {
  const intptr_t num_new_fields = new_fields.length();
  if (num_new_fields == 0) return;
  const Array& arr = Array::Handle(fields());
  const intptr_t num_old_fields = arr.Length();
  const Array& new_arr = Array::Handle(
      Array::Grow(arr, num_old_fields + num_new_fields, Heap::kOld));
  for (intptr_t i = 0; i < num_new_fields; i++) {
    new_arr.SetAt(i + num_old_fields, *new_fields.At(i));
  }
  SetFields(new_arr);
}

void Class::InjectCIDFields() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Field& field = Field::Handle(zone);
  Smi& value = Smi::Handle(zone);
  String& field_name = String::Handle(zone);

#define CLASS_LIST_WITH_NULL(V)                                                \
  V(Null)                                                                      \
  CLASS_LIST_NO_OBJECT(V)

#define ADD_SET_FIELD(clazz)                                                   \
  field_name = Symbols::New(thread, "cid" #clazz);                             \
  field =                                                                      \
      Field::New(field_name, true, false, true, false, *this,                  \
                 Type::Handle(Type::IntType()), TokenPosition::kMinSource);    \
  value = Smi::New(k##clazz##Cid);                                             \
  field.SetStaticValue(value, true);                                           \
  AddField(field);

  CLASS_LIST_WITH_NULL(ADD_SET_FIELD)
#undef ADD_SET_FIELD
#undef CLASS_LIST_WITH_NULL
}

template <class FakeInstance>
RawClass* Class::NewCommon(intptr_t index) {
  ASSERT(Object::class_class() != Class::null());
  Class& result = Class::Handle();
  {
    RawObject* raw =
        Object::Allocate(Class::kClassId, Class::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  FakeInstance fake;
  ASSERT(fake.IsInstance());
  result.set_handle_vtable(fake.vtable());
  result.set_instance_size(FakeInstance::InstanceSize());
  result.set_next_field_offset(FakeInstance::NextFieldOffset());
  result.set_id(index);
  result.set_state_bits(0);
  result.set_type_arguments_field_offset_in_words(kNoTypeArguments);
  result.set_num_type_arguments(kUnknownNumTypeArguments);
  result.set_num_own_type_arguments(kUnknownNumTypeArguments);
  result.set_num_native_fields(0);
  result.set_token_pos(TokenPosition::kNoSource);
  result.InitEmptyFields();
  return result.raw();
}

template <class FakeInstance>
RawClass* Class::New(intptr_t index) {
  Class& result = Class::Handle(NewCommon<FakeInstance>(index));
  Isolate::Current()->RegisterClass(result);
  return result.raw();
}

RawClass* Class::New(const Library& lib,
                     const String& name,
                     const Script& script,
                     TokenPosition token_pos) {
  Class& result = Class::Handle(NewCommon<Instance>(kIllegalCid));
  result.set_library(lib);
  result.set_name(name);
  result.set_script(script);
  result.set_token_pos(token_pos);
  Isolate::Current()->RegisterClass(result);
  return result.raw();
}

RawClass* Class::NewInstanceClass() {
  return Class::New<Instance>(kIllegalCid);
}

RawClass* Class::NewNativeWrapper(const Library& library,
                                  const String& name,
                                  int field_count) {
  Class& cls = Class::Handle(library.LookupClass(name));
  if (cls.IsNull()) {
    cls = New(library, name, Script::Handle(), TokenPosition::kNoSource);
    cls.SetFields(Object::empty_array());
    cls.SetFunctions(Object::empty_array());
    // Set super class to Object.
    cls.set_super_type(Type::Handle(Type::ObjectType()));
    // Compute instance size. First word contains a pointer to a properly
    // sized typed array once the first native field has been set.
    intptr_t instance_size = sizeof(RawInstance) + kWordSize;
    cls.set_instance_size(RoundedAllocationSize(instance_size));
    cls.set_next_field_offset(instance_size);
    cls.set_num_native_fields(field_count);
    cls.set_is_finalized();
    cls.set_is_type_finalized();
    cls.set_is_synthesized_class();
    cls.set_is_cycle_free();
    library.AddClass(cls);
    return cls.raw();
  } else {
    return Class::null();
  }
}

RawClass* Class::NewStringClass(intptr_t class_id) {
  intptr_t instance_size;
  if (class_id == kOneByteStringCid) {
    instance_size = OneByteString::InstanceSize();
  } else if (class_id == kTwoByteStringCid) {
    instance_size = TwoByteString::InstanceSize();
  } else if (class_id == kExternalOneByteStringCid) {
    instance_size = ExternalOneByteString::InstanceSize();
  } else {
    ASSERT(class_id == kExternalTwoByteStringCid);
    instance_size = ExternalTwoByteString::InstanceSize();
  }
  Class& result = Class::Handle(New<String>(class_id));
  result.set_instance_size(instance_size);
  result.set_next_field_offset(String::NextFieldOffset());
  result.set_is_prefinalized();
  return result.raw();
}

RawClass* Class::NewTypedDataClass(intptr_t class_id) {
  ASSERT(RawObject::IsTypedDataClassId(class_id));
  intptr_t instance_size = TypedData::InstanceSize();
  Class& result = Class::Handle(New<TypedData>(class_id));
  result.set_instance_size(instance_size);
  result.set_next_field_offset(TypedData::NextFieldOffset());
  result.set_is_prefinalized();
  return result.raw();
}

RawClass* Class::NewTypedDataViewClass(intptr_t class_id) {
  ASSERT(RawObject::IsTypedDataViewClassId(class_id));
  Class& result = Class::Handle(New<Instance>(class_id));
  result.set_instance_size(0);
  result.set_next_field_offset(-kWordSize);
  return result.raw();
}

RawClass* Class::NewExternalTypedDataClass(intptr_t class_id) {
  ASSERT(RawObject::IsExternalTypedDataClassId(class_id));
  intptr_t instance_size = ExternalTypedData::InstanceSize();
  Class& result = Class::Handle(New<ExternalTypedData>(class_id));
  result.set_instance_size(instance_size);
  result.set_next_field_offset(ExternalTypedData::NextFieldOffset());
  result.set_is_prefinalized();
  return result.raw();
}

void Class::set_name(const String& value) const {
  ASSERT(raw_ptr()->name_ == String::null());
  ASSERT(value.IsSymbol());
  StorePointer(&raw_ptr()->name_, value.raw());
#if !defined(PRODUCT)
  if (raw_ptr()->user_name_ == String::null()) {
    // TODO(johnmccutchan): Eagerly set user name for VM isolate classes,
    // lazily set user name for the other classes.
    // Generate and set user_name.
    const String& user_name = String::Handle(GenerateUserVisibleName());
    set_user_name(user_name);
  }
#endif  // !defined(PRODUCT)
}

#if !defined(PRODUCT)
void Class::set_user_name(const String& value) const {
  StorePointer(&raw_ptr()->user_name_, value.raw());
}
#endif  // !defined(PRODUCT)

RawString* Class::GenerateUserVisibleName() const {
  if (FLAG_show_internal_names) {
    return Name();
  }
  switch (id()) {
    case kFloat32x4Cid:
      return Symbols::Float32x4().raw();
    case kInt32x4Cid:
      return Symbols::Int32x4().raw();
    case kTypedDataInt8ArrayCid:
    case kExternalTypedDataInt8ArrayCid:
      return Symbols::Int8List().raw();
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
      return Symbols::Uint8List().raw();
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return Symbols::Uint8ClampedList().raw();
    case kTypedDataInt16ArrayCid:
    case kExternalTypedDataInt16ArrayCid:
      return Symbols::Int16List().raw();
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint16ArrayCid:
      return Symbols::Uint16List().raw();
    case kTypedDataInt32ArrayCid:
    case kExternalTypedDataInt32ArrayCid:
      return Symbols::Int32List().raw();
    case kTypedDataUint32ArrayCid:
    case kExternalTypedDataUint32ArrayCid:
      return Symbols::Uint32List().raw();
    case kTypedDataInt64ArrayCid:
    case kExternalTypedDataInt64ArrayCid:
      return Symbols::Int64List().raw();
    case kTypedDataUint64ArrayCid:
    case kExternalTypedDataUint64ArrayCid:
      return Symbols::Uint64List().raw();
    case kTypedDataInt32x4ArrayCid:
    case kExternalTypedDataInt32x4ArrayCid:
      return Symbols::Int32x4List().raw();
    case kTypedDataFloat32x4ArrayCid:
    case kExternalTypedDataFloat32x4ArrayCid:
      return Symbols::Float32x4List().raw();
    case kTypedDataFloat64x2ArrayCid:
    case kExternalTypedDataFloat64x2ArrayCid:
      return Symbols::Float64x2List().raw();
    case kTypedDataFloat32ArrayCid:
    case kExternalTypedDataFloat32ArrayCid:
      return Symbols::Float32List().raw();
    case kTypedDataFloat64ArrayCid:
    case kExternalTypedDataFloat64ArrayCid:
      return Symbols::Float64List().raw();

#if !defined(PRODUCT)
    case kNullCid:
      return Symbols::Null().raw();
    case kDynamicCid:
      return Symbols::Dynamic().raw();
    case kVoidCid:
      return Symbols::Void().raw();
    case kClassCid:
      return Symbols::Class().raw();
    case kUnresolvedClassCid:
      return Symbols::UnresolvedClass().raw();
    case kTypeArgumentsCid:
      return Symbols::TypeArguments().raw();
    case kPatchClassCid:
      return Symbols::PatchClass().raw();
    case kFunctionCid:
      return Symbols::Function().raw();
    case kClosureDataCid:
      return Symbols::ClosureData().raw();
    case kSignatureDataCid:
      return Symbols::SignatureData().raw();
    case kRedirectionDataCid:
      return Symbols::RedirectionData().raw();
    case kFieldCid:
      return Symbols::Field().raw();
    case kLiteralTokenCid:
      return Symbols::LiteralToken().raw();
    case kTokenStreamCid:
      return Symbols::TokenStream().raw();
    case kScriptCid:
      return Symbols::Script().raw();
    case kLibraryCid:
      return Symbols::Library().raw();
    case kLibraryPrefixCid:
      return Symbols::LibraryPrefix().raw();
    case kNamespaceCid:
      return Symbols::Namespace().raw();
    case kCodeCid:
      return Symbols::Code().raw();
    case kInstructionsCid:
      return Symbols::Instructions().raw();
    case kObjectPoolCid:
      return Symbols::ObjectPool().raw();
    case kCodeSourceMapCid:
      return Symbols::CodeSourceMap().raw();
    case kPcDescriptorsCid:
      return Symbols::PcDescriptors().raw();
    case kStackMapCid:
      return Symbols::StackMap().raw();
    case kLocalVarDescriptorsCid:
      return Symbols::LocalVarDescriptors().raw();
    case kExceptionHandlersCid:
      return Symbols::ExceptionHandlers().raw();
    case kContextCid:
      return Symbols::Context().raw();
    case kContextScopeCid:
      return Symbols::ContextScope().raw();
    case kSingleTargetCacheCid:
      return Symbols::SingleTargetCache().raw();
    case kICDataCid:
      return Symbols::ICData().raw();
    case kMegamorphicCacheCid:
      return Symbols::MegamorphicCache().raw();
    case kSubtypeTestCacheCid:
      return Symbols::SubtypeTestCache().raw();
    case kApiErrorCid:
      return Symbols::ApiError().raw();
    case kLanguageErrorCid:
      return Symbols::LanguageError().raw();
    case kUnhandledExceptionCid:
      return Symbols::UnhandledException().raw();
    case kUnwindErrorCid:
      return Symbols::UnwindError().raw();
    case kIntegerCid:
    case kSmiCid:
    case kMintCid:
    case kBigintCid:
      return Symbols::Int().raw();
    case kDoubleCid:
      return Symbols::Double().raw();
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return Symbols::_String().raw();
    case kArrayCid:
    case kImmutableArrayCid:
    case kGrowableObjectArrayCid:
      return Symbols::List().raw();
#endif  // !defined(PRODUCT)
  }
  const String& name = String::Handle(Name());
  return String::ScrubName(name);
}

void Class::set_script(const Script& value) const {
  StorePointer(&raw_ptr()->script_, value.raw());
}

void Class::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

TokenPosition Class::ComputeEndTokenPos() const {
  // Return the begin token for synthetic classes.
  if (is_synthesized_class() || IsMixinApplication() || IsTopLevel()) {
    return token_pos();
  }

  Zone* zone = Thread::Current()->zone();
  const Script& scr = Script::Handle(zone, script());
  ASSERT(!scr.IsNull());

  if (scr.kind() == RawScript::kKernelTag) {
    TokenPosition largest_seen = token_pos();

    // Walk through all functions and get their end_tokens to find the classes
    // "end token".
    // TODO(jensj): Should probably walk though all fields as well.
    Function& function = Function::Handle(zone);
    const Array& arr = Array::Handle(functions());
    for (int i = 0; i < arr.Length(); i++) {
      function ^= arr.At(i);
      if (function.script() == script()) {
        if (largest_seen < function.end_token_pos()) {
          largest_seen = function.end_token_pos();
        }
      }
    }
    return TokenPosition(largest_seen);
  }

  const TokenStream& tkns = TokenStream::Handle(zone, scr.tokens());
  if (tkns.IsNull()) {
    ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
    return TokenPosition::kNoSource;
  }
  TokenStream::Iterator tkit(zone, tkns, token_pos(),
                             TokenStream::Iterator::kNoNewlines);
  intptr_t level = 0;
  while (tkit.CurrentTokenKind() != Token::kEOS) {
    if (tkit.CurrentTokenKind() == Token::kLBRACE) {
      level++;
    } else if (tkit.CurrentTokenKind() == Token::kRBRACE) {
      if (--level == 0) {
        return tkit.CurrentPosition();
      }
    }
    tkit.Advance();
  }
  UNREACHABLE();
  return TokenPosition::kNoSource;
}

void Class::set_is_implemented() const {
  set_state_bits(ImplementedBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_abstract() const {
  set_state_bits(AbstractBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_type_finalized() const {
  set_state_bits(TypeFinalizedBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_patch() const {
  set_state_bits(PatchBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_synthesized_class() const {
  set_state_bits(SynthesizedClassBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_enum_class() const {
  set_state_bits(EnumBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_const() const {
  set_state_bits(ConstBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_mixin_app_alias() const {
  set_state_bits(MixinAppAliasBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_mixin_type_applied() const {
  set_state_bits(MixinTypeAppliedBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_fields_marked_nullable() const {
  set_state_bits(FieldsMarkedNullableBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_cycle_free() const {
  ASSERT(!is_cycle_free());
  set_state_bits(CycleFreeBit::update(true, raw_ptr()->state_bits_));
}

void Class::set_is_allocated(bool value) const {
  set_state_bits(IsAllocatedBit::update(value, raw_ptr()->state_bits_));
}

void Class::set_is_finalized() const {
  ASSERT(!is_finalized());
  set_state_bits(
      ClassFinalizedBits::update(RawClass::kFinalized, raw_ptr()->state_bits_));
}

void Class::SetRefinalizeAfterPatch() const {
  ASSERT(!IsTopLevel());
  set_state_bits(ClassFinalizedBits::update(RawClass::kRefinalizeAfterPatch,
                                            raw_ptr()->state_bits_));
  set_state_bits(TypeFinalizedBit::update(false, raw_ptr()->state_bits_));
}

void Class::ResetFinalization() const {
  ASSERT(IsTopLevel() || IsClosureClass());
  set_state_bits(
      ClassFinalizedBits::update(RawClass::kAllocated, raw_ptr()->state_bits_));
  set_state_bits(TypeFinalizedBit::update(false, raw_ptr()->state_bits_));
}

void Class::set_is_prefinalized() const {
  ASSERT(!is_finalized());
  set_state_bits(ClassFinalizedBits::update(RawClass::kPreFinalized,
                                            raw_ptr()->state_bits_));
}

void Class::set_is_marked_for_parsing() const {
  set_state_bits(MarkedForParsingBit::update(true, raw_ptr()->state_bits_));
}

void Class::reset_is_marked_for_parsing() const {
  set_state_bits(MarkedForParsingBit::update(false, raw_ptr()->state_bits_));
}

void Class::set_interfaces(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->interfaces_, value.raw());
}

void Class::set_mixin(const Type& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->mixin_, value.raw());
}

bool Class::IsMixinApplication() const {
  return mixin() != Type::null();
}

RawClass* Class::GetPatchClass() const {
  const Library& lib = Library::Handle(library());
  return lib.GetPatchClass(String::Handle(Name()));
}

void Class::AddDirectSubclass(const Class& subclass) const {
  ASSERT(!subclass.IsNull());
  ASSERT(subclass.SuperClass() == raw());
  // Do not keep track of the direct subclasses of class Object.
  ASSERT(!IsObjectClass());
  GrowableObjectArray& direct_subclasses =
      GrowableObjectArray::Handle(raw_ptr()->direct_subclasses_);
  if (direct_subclasses.IsNull()) {
    direct_subclasses = GrowableObjectArray::New(4, Heap::kOld);
    StorePointer(&raw_ptr()->direct_subclasses_, direct_subclasses.raw());
  }
#if defined(DEBUG)
  // Verify that the same class is not added twice.
  for (intptr_t i = 0; i < direct_subclasses.Length(); i++) {
    ASSERT(direct_subclasses.At(i) != subclass.raw());
  }
#endif
  direct_subclasses.Add(subclass, Heap::kOld);
}

void Class::ClearDirectSubclasses() const {
  StorePointer(&raw_ptr()->direct_subclasses_, GrowableObjectArray::null());
}

RawArray* Class::constants() const {
  return raw_ptr()->constants_;
}

void Class::set_constants(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->constants_, value.raw());
}

RawType* Class::canonical_type() const {
  return raw_ptr()->canonical_type_;
}

void Class::set_canonical_type(const Type& value) const {
  ASSERT(!value.IsNull() && value.IsCanonical() && value.IsOld());
  StorePointer(&raw_ptr()->canonical_type_, value.raw());
}

RawType* Class::CanonicalType() const {
  return raw_ptr()->canonical_type_;
}

void Class::SetCanonicalType(const Type& type) const {
  ASSERT((canonical_type() == Object::null()) ||
         (canonical_type() == type.raw()));  // Set during own finalization.
  set_canonical_type(type);
}

void Class::set_allocation_stub(const Code& value) const {
  // Never clear the stub as it may still be a target, but will be GC-d if
  // not referenced.
  ASSERT(!value.IsNull());
  ASSERT(raw_ptr()->allocation_stub_ == Code::null());
  StorePointer(&raw_ptr()->allocation_stub_, value.raw());
}

void Class::DisableAllocationStub() const {
  const Code& existing_stub = Code::Handle(allocation_stub());
  if (existing_stub.IsNull()) {
    return;
  }
  ASSERT(!existing_stub.IsDisabled());
  // Change the stub so that the next caller will regenerate the stub.
  existing_stub.DisableStubCode();
  // Disassociate the existing stub from class.
  StorePointer(&raw_ptr()->allocation_stub_, Code::null());
}

bool Class::IsDartFunctionClass() const {
  return raw() == Type::Handle(Type::DartFunctionType()).type_class();
}

// If test_kind == kIsSubtypeOf, checks if type S is a subtype of type T.
// If test_kind == kIsMoreSpecificThan, checks if S is more specific than T.
// Type S is specified by this class parameterized with 'type_arguments', and
// type T by class 'other' parameterized with 'other_type_arguments'.
// This class and class 'other' do not need to be finalized, however, they must
// be resolved as well as their interfaces.
bool Class::TypeTestNonRecursive(const Class& cls,
                                 Class::TypeTestKind test_kind,
                                 const TypeArguments& type_arguments,
                                 const Class& other,
                                 const TypeArguments& other_type_arguments,
                                 Error* bound_error,
                                 TrailPtr bound_trail,
                                 Heap::Space space) {
  // Use the thsi object as if it was the receiver of this method, but instead
  // of recursing reset it to the super class and loop.
  Zone* zone = Thread::Current()->zone();
  Class& thsi = Class::Handle(zone, cls.raw());
  while (true) {
    // Check for DynamicType.
    // Each occurrence of DynamicType in type T is interpreted as the dynamic
    // type, a supertype of all types.
    if (other.IsDynamicClass()) {
      return true;
    }
    // Check for NullType, which, as of Dart 1.5, is a subtype of (and is more
    // specific than) any type. Note that the null instance is not handled here.
    if (thsi.IsNullClass()) {
      return true;
    }
    // In the case of a subtype test, each occurrence of DynamicType in type S
    // is interpreted as the bottom type, a subtype of all types.
    // However, DynamicType is not more specific than any type.
    if (thsi.IsDynamicClass()) {
      return test_kind == Class::kIsSubtypeOf;
    }
    // Check for ObjectType. Any type that is not NullType or DynamicType
    // (already checked above), is more specific than ObjectType/VoidType.
    if (other.IsObjectClass() || other.IsVoidClass()) {
      return true;
    }
    // If other is neither Object, dynamic or void, then ObjectType/VoidType
    // can't be a subtype of other.
    if (thsi.IsObjectClass() || thsi.IsVoidClass()) {
      return false;
    }
    // Check for reflexivity.
    if (thsi.raw() == other.raw()) {
      const intptr_t num_type_params = thsi.NumTypeParameters();
      if (num_type_params == 0) {
        return true;
      }
      const intptr_t num_type_args = thsi.NumTypeArguments();
      const intptr_t from_index = num_type_args - num_type_params;
      // Since we do not truncate the type argument vector of a subclass (see
      // below), we only check a subvector of the proper length.
      // Check for covariance.
      if (other_type_arguments.IsNull() ||
          other_type_arguments.IsRaw(from_index, num_type_params)) {
        return true;
      }
      if (type_arguments.IsNull() ||
          type_arguments.IsRaw(from_index, num_type_params)) {
        // Other type can't be more specific than this one because for that
        // it would have to have all dynamic type arguments which is checked
        // above.
        return test_kind == Class::kIsSubtypeOf;
      }
      return type_arguments.TypeTest(test_kind, other_type_arguments,
                                     from_index, num_type_params, bound_error,
                                     bound_trail, space);
    }
    if (other.IsDartFunctionClass()) {
      // Check if type S has a call() method.
      const Function& call_function =
          Function::Handle(zone, thsi.LookupCallFunctionForTypeTest());
      if (!call_function.IsNull()) {
        return true;
      }
    }
    // Check for 'direct super type' specified in the implements clause
    // and check for transitivity at the same time.
    Array& interfaces = Array::Handle(zone, thsi.interfaces());
    AbstractType& interface = AbstractType::Handle(zone);
    Class& interface_class = Class::Handle(zone);
    TypeArguments& interface_args = TypeArguments::Handle(zone);
    Error& error = Error::Handle(zone);
    for (intptr_t i = 0; i < interfaces.Length(); i++) {
      interface ^= interfaces.At(i);
      if (!interface.IsFinalized()) {
        // We may be checking bounds at finalization time and can encounter
        // a still unfinalized interface.
        if (interface.IsBeingFinalized()) {
          // Interface is part of a still unfinalized recursive type graph.
          // Skip it. The caller will create a bounded type to be checked at
          // runtime if this type test returns false at compile time.
          continue;
        }
        ClassFinalizer::FinalizeType(thsi, interface);
        interfaces.SetAt(i, interface);
      }
      if (interface.IsMalbounded()) {
        // Return the first bound error to the caller if it requests it.
        if ((bound_error != NULL) && bound_error->IsNull()) {
          *bound_error = interface.error();
        }
        continue;  // Another interface may work better.
      }
      interface_class = interface.type_class();
      interface_args = interface.arguments();
      if (!interface_args.IsNull() && !interface_args.IsInstantiated()) {
        // This type class implements an interface that is parameterized with
        // generic type(s), e.g. it implements List<T>.
        // The uninstantiated type T must be instantiated using the type
        // parameters of this type before performing the type test.
        // The type arguments of this type that are referred to by the type
        // parameters of the interface are at the end of the type vector,
        // after the type arguments of the super type of this type.
        // The index of the type parameters is adjusted upon finalization.
        error = Error::null();
        interface_args = interface_args.InstantiateFrom(
            type_arguments, Object::null_type_arguments(), &error, NULL,
            bound_trail, space);
        if (!error.IsNull()) {
          // Return the first bound error to the caller if it requests it.
          if ((bound_error != NULL) && bound_error->IsNull()) {
            *bound_error = error.raw();
          }
          continue;  // Another interface may work better.
        }
      }
      if (interface_class.TypeTest(test_kind, interface_args, other,
                                   other_type_arguments, bound_error,
                                   bound_trail, space)) {
        return true;
      }
    }
    // "Recurse" up the class hierarchy until we have reached the top.
    thsi = thsi.SuperClass();
    if (thsi.IsNull()) {
      return false;
    }
  }
  UNREACHABLE();
  return false;
}

// If test_kind == kIsSubtypeOf, checks if type S is a subtype of type T.
// If test_kind == kIsMoreSpecificThan, checks if S is more specific than T.
// Type S is specified by this class parameterized with 'type_arguments', and
// type T by class 'other' parameterized with 'other_type_arguments'.
// This class and class 'other' do not need to be finalized, however, they must
// be resolved as well as their interfaces.
bool Class::TypeTest(TypeTestKind test_kind,
                     const TypeArguments& type_arguments,
                     const Class& other,
                     const TypeArguments& other_type_arguments,
                     Error* bound_error,
                     TrailPtr bound_trail,
                     Heap::Space space) const {
  return TypeTestNonRecursive(*this, test_kind, type_arguments, other,
                              other_type_arguments, bound_error, bound_trail,
                              space);
}

bool Class::IsTopLevel() const {
  return Name() == Symbols::TopLevel().raw();
}

bool Class::IsPrivate() const {
  return Library::IsPrivate(String::Handle(Name()));
}

RawFunction* Class::LookupDynamicFunction(const String& name) const {
  return LookupFunction(name, kInstance);
}

RawFunction* Class::LookupDynamicFunctionAllowAbstract(
    const String& name) const {
  return LookupFunction(name, kInstanceAllowAbstract);
}

RawFunction* Class::LookupDynamicFunctionAllowPrivate(
    const String& name) const {
  return LookupFunctionAllowPrivate(name, kInstance);
}

RawFunction* Class::LookupStaticFunction(const String& name) const {
  return LookupFunction(name, kStatic);
}

RawFunction* Class::LookupStaticFunctionAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kStatic);
}

RawFunction* Class::LookupConstructor(const String& name) const {
  return LookupFunction(name, kConstructor);
}

RawFunction* Class::LookupConstructorAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kConstructor);
}

RawFunction* Class::LookupFactory(const String& name) const {
  return LookupFunction(name, kFactory);
}

RawFunction* Class::LookupFactoryAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kFactory);
}

RawFunction* Class::LookupFunction(const String& name) const {
  return LookupFunction(name, kAny);
}

RawFunction* Class::LookupFunctionAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kAny);
}

RawFunction* Class::LookupCallFunctionForTypeTest() const {
  // If this class is not compiled yet, it is too early to lookup a call
  // function. This case should only occur during bounds checking at compile
  // time. Return null as if the call method did not exist, so the type test
  // may return false, but without a bound error, and the bound check will get
  // postponed to runtime.
  if (!is_finalized()) {
    return Function::null();
  }
  Zone* zone = Thread::Current()->zone();
  Class& cls = Class::Handle(zone, raw());
  Function& call_function = Function::Handle(zone);
  do {
    ASSERT(cls.is_finalized());
    call_function = cls.LookupDynamicFunctionAllowAbstract(Symbols::Call());
    cls = cls.SuperClass();
  } while (call_function.IsNull() && !cls.IsNull());
  if (!call_function.IsNull()) {
    // Make sure the signature is finalized before using it in a type test.
    ClassFinalizer::FinalizeSignature(
        cls, call_function, ClassFinalizer::kFinalize);  // No bounds checking.
  }
  return call_function.raw();
}

// Returns true if 'prefix' and 'accessor_name' match 'name'.
static bool MatchesAccessorName(const String& name,
                                const char* prefix,
                                intptr_t prefix_length,
                                const String& accessor_name) {
  intptr_t name_len = name.Length();
  intptr_t accessor_name_len = accessor_name.Length();

  if (name_len != (accessor_name_len + prefix_length)) {
    return false;
  }
  for (intptr_t i = 0; i < prefix_length; i++) {
    if (name.CharAt(i) != prefix[i]) {
      return false;
    }
  }
  for (intptr_t i = 0, j = prefix_length; i < accessor_name_len; i++, j++) {
    if (name.CharAt(j) != accessor_name.CharAt(i)) {
      return false;
    }
  }
  return true;
}

RawFunction* Class::CheckFunctionType(const Function& func, MemberKind kind) {
  if ((kind == kInstance) || (kind == kInstanceAllowAbstract)) {
    if (func.IsDynamicFunction(kind == kInstanceAllowAbstract)) {
      return func.raw();
    }
  } else if (kind == kStatic) {
    if (func.IsStaticFunction()) {
      return func.raw();
    }
  } else if (kind == kConstructor) {
    if (func.IsGenerativeConstructor()) {
      ASSERT(!func.is_static());
      return func.raw();
    }
  } else if (kind == kFactory) {
    if (func.IsFactory()) {
      ASSERT(func.is_static());
      return func.raw();
    }
  } else if (kind == kAny) {
    return func.raw();
  }
  return Function::null();
}

RawFunction* Class::LookupFunction(const String& name, MemberKind kind) const {
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Function::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  funcs ^= functions();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  Function& function = thread->FunctionHandle();
  if (len >= kFunctionLookupHashTreshold) {
    // Cache functions hash table to allow multi threaded access.
    const Array& hash_table =
        Array::Handle(thread->zone(), raw_ptr()->functions_hash_table_);
    if (!hash_table.IsNull()) {
      ClassFunctionsSet set(hash_table.raw());
      REUSABLE_STRING_HANDLESCOPE(thread);
      function ^= set.GetOrNull(FunctionName(name, &(thread->StringHandle())));
      // No mutations.
      ASSERT(set.Release().raw() == hash_table.raw());
      return function.IsNull() ? Function::null()
                               : CheckFunctionType(function, kind);
    }
  }
  if (name.IsSymbol()) {
    // Quick Symbol compare.
    NoSafepointScope no_safepoint;
    for (intptr_t i = 0; i < len; i++) {
      function ^= funcs.At(i);
      if (function.name() == name.raw()) {
        return CheckFunctionType(function, kind);
      }
    }
  } else {
    REUSABLE_STRING_HANDLESCOPE(thread);
    String& function_name = thread->StringHandle();
    for (intptr_t i = 0; i < len; i++) {
      function ^= funcs.At(i);
      function_name ^= function.name();
      if (function_name.Equals(name)) {
        return CheckFunctionType(function, kind);
      }
    }
  }
  // No function found.
  return Function::null();
}

RawFunction* Class::LookupFunctionAllowPrivate(const String& name,
                                               MemberKind kind) const {
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Function::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  funcs ^= functions();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  Function& function = thread->FunctionHandle();
  String& function_name = thread->StringHandle();
  for (intptr_t i = 0; i < len; i++) {
    function ^= funcs.At(i);
    function_name ^= function.name();
    if (String::EqualsIgnoringPrivateKey(function_name, name)) {
      return CheckFunctionType(function, kind);
    }
  }
  // No function found.
  return Function::null();
}

RawFunction* Class::LookupGetterFunction(const String& name) const {
  return LookupAccessorFunction(kGetterPrefix, kGetterPrefixLength, name);
}

RawFunction* Class::LookupSetterFunction(const String& name) const {
  return LookupAccessorFunction(kSetterPrefix, kSetterPrefixLength, name);
}

RawFunction* Class::LookupAccessorFunction(const char* prefix,
                                           intptr_t prefix_length,
                                           const String& name) const {
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Function::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  funcs ^= functions();
  intptr_t len = funcs.Length();
  Function& function = thread->FunctionHandle();
  String& function_name = thread->StringHandle();
  for (intptr_t i = 0; i < len; i++) {
    function ^= funcs.At(i);
    function_name ^= function.name();
    if (MatchesAccessorName(function_name, prefix, prefix_length, name)) {
      return function.raw();
    }
  }

  // No function found.
  return Function::null();
}

RawField* Class::LookupInstanceField(const String& name) const {
  return LookupField(name, kInstance);
}

RawField* Class::LookupStaticField(const String& name) const {
  return LookupField(name, kStatic);
}

RawField* Class::LookupField(const String& name) const {
  return LookupField(name, kAny);
}

RawField* Class::LookupField(const String& name, MemberKind kind) const {
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Field::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FIELD_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& flds = thread->ArrayHandle();
  flds ^= fields();
  ASSERT(!flds.IsNull());
  intptr_t len = flds.Length();
  Field& field = thread->FieldHandle();
  if (name.IsSymbol()) {
    // Use fast raw pointer string compare for symbols.
    for (intptr_t i = 0; i < len; i++) {
      field ^= flds.At(i);
      if (name.raw() == field.name()) {
        if (kind == kInstance) {
          return field.is_static() ? Field::null() : field.raw();
        } else if (kind == kStatic) {
          return field.is_static() ? field.raw() : Field::null();
        }
        ASSERT(kind == kAny);
        return field.raw();
      }
    }
  } else {
    String& field_name = thread->StringHandle();
    for (intptr_t i = 0; i < len; i++) {
      field ^= flds.At(i);
      field_name ^= field.name();
      if (name.Equals(field_name)) {
        if (kind == kInstance) {
          return field.is_static() ? Field::null() : field.raw();
        } else if (kind == kStatic) {
          return field.is_static() ? field.raw() : Field::null();
        }
        ASSERT(kind == kAny);
        return field.raw();
      }
    }
  }
  return Field::null();
}

RawField* Class::LookupFieldAllowPrivate(const String& name,
                                         bool instance_only) const {
  // Use slow string compare, ignoring privacy name mangling.
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Field::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FIELD_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& flds = thread->ArrayHandle();
  flds ^= fields();
  ASSERT(!flds.IsNull());
  intptr_t len = flds.Length();
  Field& field = thread->FieldHandle();
  String& field_name = thread->StringHandle();
  for (intptr_t i = 0; i < len; i++) {
    field ^= flds.At(i);
    field_name ^= field.name();
    if (field.is_static() && instance_only) {
      // If we only care about instance fields, skip statics.
      continue;
    }
    if (String::EqualsIgnoringPrivateKey(field_name, name)) {
      return field.raw();
    }
  }
  return Field::null();
}

RawField* Class::LookupInstanceFieldAllowPrivate(const String& name) const {
  Field& field = Field::Handle(LookupFieldAllowPrivate(name, true));
  if (!field.IsNull() && !field.is_static()) {
    return field.raw();
  }
  return Field::null();
}

RawField* Class::LookupStaticFieldAllowPrivate(const String& name) const {
  Field& field = Field::Handle(LookupFieldAllowPrivate(name));
  if (!field.IsNull() && field.is_static()) {
    return field.raw();
  }
  return Field::null();
}

RawLibraryPrefix* Class::LookupLibraryPrefix(const String& name) const {
  Zone* zone = Thread::Current()->zone();
  const Library& lib = Library::Handle(zone, library());
  const Object& obj = Object::Handle(zone, lib.LookupLocalObject(name));
  if (!obj.IsNull() && obj.IsLibraryPrefix()) {
    return LibraryPrefix::Cast(obj).raw();
  }
  return LibraryPrefix::null();
}

const char* Class::ToCString() const {
  const Library& lib = Library::Handle(library());
  const char* library_name = lib.IsNull() ? "" : lib.ToCString();
  const char* patch_prefix = is_patch() ? "Patch " : "";
  const char* class_name = String::Handle(Name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(), "%s %sClass: %s", library_name,
                     patch_prefix, class_name);
}

// Returns an instance of Double or Double::null().
// 'index' points to either:
// - constants_list_ position of found element, or
// - constants_list_ position where new canonical can be inserted.
RawDouble* Class::LookupCanonicalDouble(Zone* zone,
                                        double value,
                                        intptr_t* index) const {
  ASSERT(this->raw() == Isolate::Current()->object_store()->double_class());
  const Array& constants = Array::Handle(zone, this->constants());
  const intptr_t constants_len = constants.Length();
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Double& canonical_value = Double::Handle(zone);
  while (*index < constants_len) {
    canonical_value ^= constants.At(*index);
    if (canonical_value.IsNull()) {
      break;
    }
    if (canonical_value.BitwiseEqualsToDouble(value)) {
      ASSERT(canonical_value.IsCanonical());
      return canonical_value.raw();
    }
    *index = *index + 1;
  }
  return Double::null();
}

RawMint* Class::LookupCanonicalMint(Zone* zone,
                                    int64_t value,
                                    intptr_t* index) const {
  ASSERT(this->raw() == Isolate::Current()->object_store()->mint_class());
  const Array& constants = Array::Handle(zone, this->constants());
  const intptr_t constants_len = constants.Length();
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Mint& canonical_value = Mint::Handle(zone);
  while (*index < constants_len) {
    canonical_value ^= constants.At(*index);
    if (canonical_value.IsNull()) {
      break;
    }
    if (canonical_value.value() == value) {
      ASSERT(canonical_value.IsCanonical());
      return canonical_value.raw();
    }
    *index = *index + 1;
  }
  return Mint::null();
}

RawBigint* Class::LookupCanonicalBigint(Zone* zone,
                                        const Bigint& value,
                                        intptr_t* index) const {
  ASSERT(this->raw() == Isolate::Current()->object_store()->bigint_class());
  const Array& constants = Array::Handle(zone, this->constants());
  const intptr_t constants_len = constants.Length();
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Bigint& canonical_value = Bigint::Handle(zone);
  while (*index < constants_len) {
    canonical_value ^= constants.At(*index);
    if (canonical_value.IsNull()) {
      break;
    }
    if (canonical_value.Equals(value)) {
      ASSERT(canonical_value.IsCanonical());
      return canonical_value.raw();
    }
    *index = *index + 1;
  }
  return Bigint::null();
}

class CanonicalInstanceKey {
 public:
  explicit CanonicalInstanceKey(const Instance& key) : key_(key) {
    ASSERT(!(key.IsString() || key.IsInteger() || key.IsAbstractType()));
  }
  bool Matches(const Instance& obj) const {
    ASSERT(!(obj.IsString() || obj.IsInteger() || obj.IsAbstractType()));
    if (key_.CanonicalizeEquals(obj)) {
      ASSERT(obj.IsCanonical());
      return true;
    }
    return false;
  }
  uword Hash() const { return key_.ComputeCanonicalTableHash(); }
  const Instance& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical Instances based on a hash of the fields.
class CanonicalInstanceTraits {
 public:
  static const char* Name() { return "CanonicalInstanceTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(!(a.IsString() || a.IsInteger() || a.IsAbstractType()));
    ASSERT(!(b.IsString() || b.IsInteger() || b.IsAbstractType()));
    return a.raw() == b.raw();
  }
  static bool IsMatch(const CanonicalInstanceKey& a, const Object& b) {
    return a.Matches(Instance::Cast(b));
  }
  static uword Hash(const Object& key) {
    ASSERT(!(key.IsString() || key.IsNumber() || key.IsAbstractType()));
    ASSERT(key.IsInstance());
    return Instance::Cast(key).ComputeCanonicalTableHash();
  }
  static uword Hash(const CanonicalInstanceKey& key) { return key.Hash(); }
  static RawObject* NewKey(const CanonicalInstanceKey& obj) {
    return obj.key_.raw();
  }
};
typedef UnorderedHashSet<CanonicalInstanceTraits> CanonicalInstancesSet;

RawInstance* Class::LookupCanonicalInstance(Zone* zone,
                                            const Instance& value) const {
  ASSERT(this->raw() == value.clazz());
  ASSERT(is_finalized());
  Instance& canonical_value = Instance::Handle(zone);
  if (this->constants() != Object::empty_array().raw()) {
    CanonicalInstancesSet constants(zone, this->constants());
    canonical_value ^= constants.GetOrNull(CanonicalInstanceKey(value));
    this->set_constants(constants.Release());
  }
  return canonical_value.raw();
}

RawInstance* Class::InsertCanonicalConstant(Zone* zone,
                                            const Instance& constant) const {
  ASSERT(this->raw() == constant.clazz());
  Instance& canonical_value = Instance::Handle(zone);
  if (this->constants() == Object::empty_array().raw()) {
    CanonicalInstancesSet constants(
        HashTables::New<CanonicalInstancesSet>(128, Heap::kOld));
    canonical_value ^= constants.InsertNewOrGet(CanonicalInstanceKey(constant));
    this->set_constants(constants.Release());
  } else {
    CanonicalInstancesSet constants(Thread::Current()->zone(),
                                    this->constants());
    canonical_value ^= constants.InsertNewOrGet(CanonicalInstanceKey(constant));
    this->set_constants(constants.Release());
  }
  return canonical_value.raw();
}

void Class::InsertCanonicalNumber(Zone* zone,
                                  intptr_t index,
                                  const Number& constant) const {
  // The constant needs to be added to the list. Grow the list if it is full.
  Array& canonical_list = Array::Handle(zone, constants());
  const intptr_t list_len = canonical_list.Length();
  if (index >= list_len) {
    const intptr_t new_length = list_len + 4 + (list_len >> 2);
    canonical_list ^= Array::Grow(canonical_list, new_length, Heap::kOld);
    set_constants(canonical_list);
  }
  canonical_list.SetAt(index, constant);
}

void Class::RehashConstants(Zone* zone) const {
  intptr_t cid = id();
  if ((cid == kMintCid) || (cid == kBigintCid) || (cid == kDoubleCid)) {
    // Constants stored as a plain list, no rehashing needed.
    return;
  }

  const Array& old_constants = Array::Handle(zone, constants());
  if (old_constants.Length() == 0) return;

  set_constants(Object::empty_array());
  CanonicalInstancesSet set(zone, old_constants.raw());
  Instance& constant = Instance::Handle(zone);
  CanonicalInstancesSet::Iterator it(&set);
  while (it.MoveNext()) {
    constant ^= set.GetKey(it.Current());
    ASSERT(!constant.IsNull());
    ASSERT(constant.IsCanonical());
    InsertCanonicalConstant(zone, constant);
  }
  set.Release();
}

RawUnresolvedClass* UnresolvedClass::New(const Object& library_prefix,
                                         const String& ident,
                                         TokenPosition token_pos) {
  const UnresolvedClass& type = UnresolvedClass::Handle(UnresolvedClass::New());
  type.set_library_or_library_prefix(library_prefix);
  type.set_ident(ident);
  type.set_token_pos(token_pos);
  return type.raw();
}

RawUnresolvedClass* UnresolvedClass::New() {
  ASSERT(Object::unresolved_class_class() != Class::null());
  RawObject* raw = Object::Allocate(
      UnresolvedClass::kClassId, UnresolvedClass::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawUnresolvedClass*>(raw);
}

void UnresolvedClass::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

void UnresolvedClass::set_ident(const String& ident) const {
  StorePointer(&raw_ptr()->ident_, ident.raw());
}

void UnresolvedClass::set_library_or_library_prefix(
    const Object& library_prefix) const {
  StorePointer(&raw_ptr()->library_or_library_prefix_, library_prefix.raw());
}

RawString* UnresolvedClass::Name() const {
  if (library_or_library_prefix() != Object::null()) {
    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();
    const Object& lib_prefix =
        Object::Handle(zone, library_or_library_prefix());
    String& name = String::Handle(zone);  // Qualifier.
    if (lib_prefix.IsLibraryPrefix()) {
      name = LibraryPrefix::Cast(lib_prefix).name();
    } else {
      name = Library::Cast(lib_prefix).name();
    }
    GrowableHandlePtrArray<const String> strs(zone, 3);
    strs.Add(name);
    strs.Add(Symbols::Dot());
    strs.Add(String::Handle(zone, ident()));
    return Symbols::FromConcatAll(thread, strs);
  } else {
    return ident();
  }
}

const char* UnresolvedClass::ToCString() const {
  const char* cname = String::Handle(Name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(), "unresolved class '%s'", cname);
}

static uint32_t CombineHashes(uint32_t hash, uint32_t other_hash) {
  hash += other_hash;
  hash += hash << 10;
  hash ^= hash >> 6;  // Logical shift, unsigned hash.
  return hash;
}

static uint32_t FinalizeHash(uint32_t hash, intptr_t hashbits) {
  hash += hash << 3;
  hash ^= hash >> 11;  // Logical shift, unsigned hash.
  hash += hash << 15;
  // FinalizeHash gets called with values for hashbits that are bigger than 31
  // (like kBitsPerWord - 1).  Therefore we are careful to use a type
  // (uintptr_t) big enough to avoid undefined behavior with the left shift.
  hash &= (static_cast<uintptr_t>(1) << hashbits) - 1;
  return (hash == 0) ? 1 : hash;
}

intptr_t TypeArguments::ComputeHash() const {
  if (IsNull()) return 0;
  const intptr_t num_types = Length();
  if (IsRaw(0, num_types)) return 0;
  uint32_t result = 0;
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    // The hash may be calculated during type finalization (for debugging
    // purposes only) while a type argument is still temporarily null.
    result = CombineHashes(result, type.IsNull() ? 0 : type.Hash());
  }
  result = FinalizeHash(result, kHashBits);
  SetHash(result);
  return result;
}

RawString* TypeArguments::SubvectorName(intptr_t from_index,
                                        intptr_t len,
                                        NameVisibility name_visibility) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(from_index + len <= Length());
  String& name = String::Handle(zone);
  const intptr_t num_strings =
      (len == 0) ? 2 : 2 * len + 1;  // "<""T"", ""T"">".
  GrowableHandlePtrArray<const String> pieces(zone, num_strings);
  pieces.Add(Symbols::LAngleBracket());
  AbstractType& type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < len; i++) {
    type = TypeAt(from_index + i);
    name = type.BuildName(name_visibility);
    pieces.Add(name);
    if (i < len - 1) {
      pieces.Add(Symbols::CommaSpace());
    }
  }
  pieces.Add(Symbols::RAngleBracket());
  ASSERT(pieces.length() == num_strings);
  return Symbols::FromConcatAll(thread, pieces);
}

bool TypeArguments::IsSubvectorEquivalent(const TypeArguments& other,
                                          intptr_t from_index,
                                          intptr_t len,
                                          TrailPtr trail) const {
  if (this->raw() == other.raw()) {
    return true;
  }
  if (IsNull() || other.IsNull()) {
    return false;
  }
  const intptr_t num_types = Length();
  if (num_types != other.Length()) {
    return false;
  }
  AbstractType& type = AbstractType::Handle();
  AbstractType& other_type = AbstractType::Handle();
  for (intptr_t i = from_index; i < from_index + len; i++) {
    type = TypeAt(i);
    other_type = other.TypeAt(i);
    if (!type.IsNull() && !type.IsEquivalent(other_type, trail)) {
      return false;
    }
  }
  return true;
}

bool TypeArguments::IsRecursive() const {
  if (IsNull()) return false;
  const intptr_t num_types = Length();
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    // If this type argument is null, the type parameterized with this type
    // argument is still being finalized and is definitely recursive. The null
    // type argument will be replaced by a non-null type before the type is
    // marked as finalized.
    if (type.IsNull() || type.IsRecursive()) {
      return true;
    }
  }
  return false;
}

void TypeArguments::SetScopeFunction(const Function& function) const {
  if (IsNull()) return;
  const intptr_t num_types = Length();
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    if (!type.IsNull()) {
      type.SetScopeFunction(function);
    }
  }
}

bool TypeArguments::IsDynamicTypes(bool raw_instantiated,
                                   intptr_t from_index,
                                   intptr_t len) const {
  ASSERT(Length() >= (from_index + len));
  AbstractType& type = AbstractType::Handle();
  Class& type_class = Class::Handle();
  for (intptr_t i = 0; i < len; i++) {
    type = TypeAt(from_index + i);
    if (type.IsNull()) {
      return false;
    }
    if (!type.HasResolvedTypeClass()) {
      if (raw_instantiated && type.IsTypeParameter()) {
        // An uninstantiated type parameter is equivalent to dynamic (even in
        // the presence of a malformed bound in checked mode).
        continue;
      }
      return false;
    }
    type_class = type.type_class();
    if (!type_class.IsDynamicClass()) {
      return false;
    }
  }
  return true;
}

bool TypeArguments::TypeTest(TypeTestKind test_kind,
                             const TypeArguments& other,
                             intptr_t from_index,
                             intptr_t len,
                             Error* bound_error,
                             TrailPtr bound_trail,
                             Heap::Space space) const {
  ASSERT(Length() >= (from_index + len));
  ASSERT(!other.IsNull());
  ASSERT(other.Length() >= (from_index + len));
  AbstractType& type = AbstractType::Handle();
  AbstractType& other_type = AbstractType::Handle();
  for (intptr_t i = 0; i < len; i++) {
    type = TypeAt(from_index + i);
    other_type = other.TypeAt(from_index + i);
    if (type.IsNull() || other_type.IsNull() ||
        !type.TypeTest(test_kind, other_type, bound_error, bound_trail,
                       space)) {
      return false;
    }
  }
  return true;
}

bool TypeArguments::HasInstantiations() const {
  const Array& prior_instantiations = Array::Handle(instantiations());
  ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
  return prior_instantiations.Length() > 1;
}

intptr_t TypeArguments::NumInstantiations() const {
  const Array& prior_instantiations = Array::Handle(instantiations());
  ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
  intptr_t num = 0;
  intptr_t i = 0;
  while (prior_instantiations.At(i) != Smi::New(StubCode::kNoInstantiator)) {
    i += StubCode::kInstantiationSizeInWords;
    num++;
  }
  return num;
}

RawArray* TypeArguments::instantiations() const {
  return raw_ptr()->instantiations_;
}

void TypeArguments::set_instantiations(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->instantiations_, value.raw());
}

intptr_t TypeArguments::Length() const {
  if (IsNull()) {
    return 0;
  }
  return Smi::Value(raw_ptr()->length_);
}

RawAbstractType* TypeArguments::TypeAt(intptr_t index) const {
  return *TypeAddr(index);
}

void TypeArguments::SetTypeAt(intptr_t index, const AbstractType& value) const {
  ASSERT(!IsCanonical());
  StorePointer(TypeAddr(index), value.raw());
}

bool TypeArguments::IsResolved() const {
  if (IsCanonical()) {
    return true;
  }
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    if (!type.IsResolved()) {
      return false;
    }
  }
  return true;
}

bool TypeArguments::IsSubvectorInstantiated(intptr_t from_index,
                                            intptr_t len,
                                            Genericity genericity,
                                            intptr_t num_free_fun_type_params,
                                            TrailPtr trail) const {
  ASSERT(!IsNull());
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < len; i++) {
    type = TypeAt(from_index + i);
    // If this type argument T is null, the type A containing T in its flattened
    // type argument vector V is recursive and is still being finalized.
    // T is the type argument of a super type of A. T is being instantiated
    // during finalization of V, which is also the instantiator. T depends
    // solely on the type parameters of A and will be replaced by a non-null
    // type before A is marked as finalized.
    if (!type.IsNull() &&
        !type.IsInstantiated(genericity, num_free_fun_type_params, trail)) {
      return false;
    }
  }
  return true;
}

bool TypeArguments::IsUninstantiatedIdentity() const {
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    if (type.IsNull()) {
      continue;
    }
    if (!type.IsTypeParameter()) {
      return false;
    }
    const TypeParameter& type_param = TypeParameter::Cast(type);
    ASSERT(type_param.IsFinalized());
    if ((type_param.index() != i) || type_param.IsFunctionTypeParameter()) {
      return false;
    }
    // TODO(regis): Do the bounds really matter, since they are checked at
    // finalization time (creating BoundedTypes where required)? Understand
    // why ignoring bounds here causes failures.
    // If this type parameter specifies an upper bound, then the type argument
    // vector does not really represent the identity vector. It cannot be
    // substituted by the instantiator's type argument vector without checking
    // the upper bound.
    const AbstractType& bound = AbstractType::Handle(type_param.bound());
    ASSERT(bound.IsResolved());
    if (!bound.IsObjectType() && !bound.IsDynamicType()) {
      return false;
    }
  }
  return true;
  // Note that it is not necessary to verify at runtime that the instantiator
  // type vector is long enough, since this uninstantiated vector contains as
  // many different type parameters as it is long.
}

// Return true if this uninstantiated type argument vector, once instantiated
// at runtime, is a prefix of the type argument vector of its instantiator.
bool TypeArguments::CanShareInstantiatorTypeArguments(
    const Class& instantiator_class) const {
  ASSERT(!IsInstantiated());
  const intptr_t num_type_args = Length();
  const intptr_t num_instantiator_type_args =
      instantiator_class.NumTypeArguments();
  if (num_type_args > num_instantiator_type_args) {
    // This vector cannot be a prefix of a shorter vector.
    return false;
  }
  const intptr_t num_instantiator_type_params =
      instantiator_class.NumTypeParameters();
  const intptr_t first_type_param_offset =
      num_instantiator_type_args - num_instantiator_type_params;
  // At compile time, the type argument vector of the instantiator consists of
  // the type argument vector of its super type, which may refer to the type
  // parameters of the instantiator class, followed by (or overlapping partially
  // or fully with) the type parameters of the instantiator class in declaration
  // order.
  // In other words, the only variables are the type parameters of the
  // instantiator class.
  // This uninstantiated type argument vector is also expressed in terms of the
  // type parameters of the instantiator class. Therefore, in order to be a
  // prefix once instantiated at runtime, every one of its type argument must be
  // equal to the type argument of the instantiator vector at the same index.

  // As a first requirement, the last num_instantiator_type_params type
  // arguments of this type argument vector must refer to the corresponding type
  // parameters of the instantiator class.
  AbstractType& type_arg = AbstractType::Handle();
  for (intptr_t i = first_type_param_offset; i < num_type_args; i++) {
    type_arg = TypeAt(i);
    if (!type_arg.IsTypeParameter()) {
      return false;
    }
    const TypeParameter& type_param = TypeParameter::Cast(type_arg);
    ASSERT(type_param.IsFinalized());
    if ((type_param.index() != i) || type_param.IsFunctionTypeParameter()) {
      return false;
    }
  }
  // As a second requirement, the type arguments corresponding to the super type
  // must be identical. Overlapping ones have already been checked starting at
  // first_type_param_offset.
  if (first_type_param_offset == 0) {
    return true;
  }
  AbstractType& super_type =
      AbstractType::Handle(instantiator_class.super_type());
  const TypeArguments& super_type_args =
      TypeArguments::Handle(super_type.arguments());
  if (super_type_args.IsNull()) {
    return false;
  }
  AbstractType& super_type_arg = AbstractType::Handle();
  for (intptr_t i = 0; (i < first_type_param_offset) && (i < num_type_args);
       i++) {
    type_arg = TypeAt(i);
    super_type_arg = super_type_args.TypeAt(i);
    if (!type_arg.Equals(super_type_arg)) {
      return false;
    }
  }
  return true;
}

bool TypeArguments::IsFinalized() const {
  ASSERT(!IsNull());
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    if (!type.IsFinalized()) {
      return false;
    }
  }
  return true;
}

bool TypeArguments::IsBounded() const {
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    if (type.IsBoundedType()) {
      return true;
    }
    if (type.IsTypeParameter()) {
      const AbstractType& bound =
          AbstractType::Handle(TypeParameter::Cast(type).bound());
      if (!bound.IsObjectType() && !bound.IsDynamicType()) {
        return true;
      }
      continue;
    }
    const TypeArguments& type_args =
        TypeArguments::Handle(Type::Cast(type).arguments());
    if (!type_args.IsNull() && type_args.IsBounded()) {
      return true;
    }
  }
  return false;
}

RawTypeArguments* TypeArguments::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Error* bound_error,
    TrailPtr instantiation_trail,
    TrailPtr bound_trail,
    Heap::Space space) const {
  ASSERT(!IsInstantiated());
  if (!instantiator_type_arguments.IsNull() && IsUninstantiatedIdentity() &&
      (instantiator_type_arguments.Length() == Length())) {
    return instantiator_type_arguments.raw();
  }
  const intptr_t num_types = Length();
  TypeArguments& instantiated_array =
      TypeArguments::Handle(TypeArguments::New(num_types, space));
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    // If this type argument T is null, the type A containing T in its flattened
    // type argument vector V is recursive and is still being finalized.
    // T is the type argument of a super type of A. T is being instantiated
    // during finalization of V, which is also the instantiator. T depends
    // solely on the type parameters of A and will be replaced by a non-null
    // type before A is marked as finalized.
    if (!type.IsNull() && !type.IsInstantiated()) {
      type = type.InstantiateFrom(instantiator_type_arguments,
                                  function_type_arguments, bound_error,
                                  instantiation_trail, bound_trail, space);
    }
    instantiated_array.SetTypeAt(i, type);
  }
  return instantiated_array.raw();
}

RawTypeArguments* TypeArguments::InstantiateAndCanonicalizeFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Error* bound_error) const {
  ASSERT(!IsInstantiated());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsCanonical());
  // TODO(regis): It is not clear yet whether we will canonicalize the result
  // of the concatenation of function_type_arguments in a nested generic
  // function. Leave the assert for now to be safe, but plan on revisiting.
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsCanonical());
  // Lookup instantiator and, if found, return paired instantiated result.
  Array& prior_instantiations = Array::Handle(instantiations());
  ASSERT(!prior_instantiations.IsNull() && prior_instantiations.IsArray());
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
  intptr_t index = 0;
  while (true) {
    if ((prior_instantiations.At(index) == instantiator_type_arguments.raw()) &&
        (prior_instantiations.At(index + 1) == function_type_arguments.raw())) {
      return TypeArguments::RawCast(prior_instantiations.At(index + 2));
    }
    if (prior_instantiations.At(index) == Smi::New(StubCode::kNoInstantiator)) {
      break;
    }
    index += StubCode::kInstantiationSizeInWords;
  }
  // Cache lookup failed. Instantiate the type arguments.
  TypeArguments& result = TypeArguments::Handle();
  result = InstantiateFrom(instantiator_type_arguments, function_type_arguments,
                           bound_error, NULL, NULL, Heap::kOld);
  if ((bound_error != NULL) && !bound_error->IsNull()) {
    return result.raw();
  }
  // Instantiation did not result in bound error. Canonicalize type arguments.
  result = result.Canonicalize();
  // InstantiateAndCanonicalizeFrom is not reentrant. It cannot have been called
  // indirectly, so the prior_instantiations array cannot have grown.
  ASSERT(prior_instantiations.raw() == instantiations());
  // Add instantiator and function type args and result to instantiations array.
  intptr_t length = prior_instantiations.Length();
  if ((index + StubCode::kInstantiationSizeInWords) >= length) {
    // TODO(regis): Should we limit the number of cached instantiations?
    // Grow the instantiations array by about 50%, but at least by 1.
    // The initial array is Object::zero_array() of length 1.
    intptr_t entries = (length - 1) / StubCode::kInstantiationSizeInWords;
    intptr_t new_entries = entries + (entries >> 1) + 1;
    length = new_entries * StubCode::kInstantiationSizeInWords + 1;
    prior_instantiations =
        Array::Grow(prior_instantiations, length, Heap::kOld);
    set_instantiations(prior_instantiations);
    ASSERT((index + StubCode::kInstantiationSizeInWords) < length);
  }
  prior_instantiations.SetAt(index + 0, instantiator_type_arguments);
  prior_instantiations.SetAt(index + 1, function_type_arguments);
  prior_instantiations.SetAt(index + 2, result);
  prior_instantiations.SetAt(index + 3,
                             Smi::Handle(Smi::New(StubCode::kNoInstantiator)));
  return result.raw();
}

RawTypeArguments* TypeArguments::New(intptr_t len, Heap::Space space) {
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in TypeArguments::New: invalid len %" Pd "\n", len);
  }
  TypeArguments& result = TypeArguments::Handle();
  {
    RawObject* raw = Object::Allocate(TypeArguments::kClassId,
                                      TypeArguments::InstanceSize(len), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    // Length must be set before we start storing into the array.
    result.SetLength(len);
    result.SetHash(0);
  }
  // The zero array should have been initialized.
  ASSERT(Object::zero_array().raw() != Array::null());
  COMPILE_ASSERT(StubCode::kNoInstantiator == 0);
  result.set_instantiations(Object::zero_array());
  return result.raw();
}

RawAbstractType* const* TypeArguments::TypeAddr(intptr_t index) const {
  ASSERT((index >= 0) && (index < Length()));
  return &raw_ptr()->types()[index];
}

void TypeArguments::SetLength(intptr_t value) const {
  ASSERT(!IsCanonical());
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  StoreSmi(&raw_ptr()->length_, Smi::New(value));
}

RawTypeArguments* TypeArguments::CloneUnfinalized() const {
  if (IsNull() || IsFinalized()) {
    return raw();
  }
  ASSERT(IsResolved());
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  const TypeArguments& clone =
      TypeArguments::Handle(TypeArguments::New(num_types));
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    type = type.CloneUnfinalized();
    clone.SetTypeAt(i, type);
  }
  ASSERT(clone.IsResolved());
  return clone.raw();
}

RawTypeArguments* TypeArguments::CloneUninstantiated(const Class& new_owner,
                                                     TrailPtr trail) const {
  ASSERT(!IsNull());
  ASSERT(IsFinalized());
  ASSERT(!IsInstantiated());
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  const TypeArguments& clone =
      TypeArguments::Handle(TypeArguments::New(num_types));
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    if (!type.IsInstantiated()) {
      type = type.CloneUninstantiated(new_owner, trail);
    }
    clone.SetTypeAt(i, type);
  }
  ASSERT(clone.IsFinalized());
  return clone.raw();
}

RawTypeArguments* TypeArguments::Canonicalize(TrailPtr trail) const {
  if (IsNull() || IsCanonical()) {
    ASSERT(IsOld());
    return this->raw();
  }
  const intptr_t num_types = Length();
  if (IsRaw(0, num_types)) {
    return TypeArguments::null();
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();
  TypeArguments& result = TypeArguments::Handle(zone);
  {
    SafepointMutexLocker ml(isolate->type_canonicalization_mutex());
    CanonicalTypeArgumentsSet table(zone,
                                    object_store->canonical_type_arguments());
    result ^= table.GetOrNull(CanonicalTypeArgumentsKey(*this));
    object_store->set_canonical_type_arguments(table.Release());
  }
  if (result.IsNull()) {
    // Canonicalize each type argument.
    AbstractType& type_arg = AbstractType::Handle(zone);
    for (intptr_t i = 0; i < num_types; i++) {
      type_arg = TypeAt(i);
      type_arg = type_arg.Canonicalize(trail);
      if (IsCanonical()) {
        // Canonicalizing this type_arg canonicalized this type.
        ASSERT(IsRecursive());
        return this->raw();
      }
      SetTypeAt(i, type_arg);
    }
    // Canonicalization of a type argument of a recursive type argument vector
    // may change the hash of the vector, so recompute.
    if (IsRecursive()) {
      ComputeHash();
    }
    SafepointMutexLocker ml(isolate->type_canonicalization_mutex());
    CanonicalTypeArgumentsSet table(zone,
                                    object_store->canonical_type_arguments());
    // Since we canonicalized some type arguments above we need to lookup
    // in the table again to make sure we don't already have an equivalent
    // canonical entry.
    result ^= table.GetOrNull(CanonicalTypeArgumentsKey(*this));
    if (result.IsNull()) {
      // Make sure we have an old space object and add it to the table.
      if (this->IsNew()) {
        result ^= Object::Clone(*this, Heap::kOld);
      } else {
        result ^= this->raw();
      }
      ASSERT(result.IsOld());
      result.SetCanonical();  // Mark object as being canonical.
      // Now add this TypeArgument into the canonical list of type arguments.
      bool present = table.Insert(result);
      ASSERT(!present);
    }
    object_store->set_canonical_type_arguments(table.Release());
  }
  ASSERT(result.Equals(*this));
  ASSERT(!result.IsNull());
  ASSERT(result.IsTypeArguments());
  ASSERT(result.IsCanonical());
  return result.raw();
}

RawString* TypeArguments::EnumerateURIs() const {
  if (IsNull()) {
    return Symbols::Empty().raw();
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  AbstractType& type = AbstractType::Handle(zone);
  const intptr_t num_types = Length();
  const Array& pieces = Array::Handle(zone, Array::New(num_types));
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    pieces.SetAt(i, String::Handle(zone, type.EnumerateURIs()));
  }
  return String::ConcatAll(pieces);
}

const char* TypeArguments::ToCString() const {
  if (IsNull()) {
    return "TypeArguments: null";
  }
  Zone* zone = Thread::Current()->zone();
  const char* prev_cstr = OS::SCreate(zone, "TypeArguments: (%" Pd ")",
                                      Smi::Value(raw_ptr()->hash_));
  for (int i = 0; i < Length(); i++) {
    const AbstractType& type_at = AbstractType::Handle(zone, TypeAt(i));
    const char* type_cstr = type_at.IsNull() ? "null" : type_at.ToCString();
    char* chars = OS::SCreate(zone, "%s [%s]", prev_cstr, type_cstr);
    prev_cstr = chars;
  }
  return prev_cstr;
}

const char* PatchClass::ToCString() const {
  const Class& cls = Class::Handle(patched_class());
  const char* cls_name = cls.ToCString();
  return OS::SCreate(Thread::Current()->zone(), "PatchClass for %s", cls_name);
}

RawPatchClass* PatchClass::New(const Class& patched_class,
                               const Class& origin_class) {
  const PatchClass& result = PatchClass::Handle(PatchClass::New());
  result.set_patched_class(patched_class);
  result.set_origin_class(origin_class);
  result.set_script(Script::Handle(origin_class.script()));
  return result.raw();
}

RawPatchClass* PatchClass::New(const Class& patched_class,
                               const Script& script) {
  const PatchClass& result = PatchClass::Handle(PatchClass::New());
  result.set_patched_class(patched_class);
  result.set_origin_class(patched_class);
  result.set_script(script);
  return result.raw();
}

RawPatchClass* PatchClass::New() {
  ASSERT(Object::patch_class_class() != Class::null());
  RawObject* raw = Object::Allocate(PatchClass::kClassId,
                                    PatchClass::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawPatchClass*>(raw);
}

void PatchClass::set_patched_class(const Class& value) const {
  StorePointer(&raw_ptr()->patched_class_, value.raw());
}

void PatchClass::set_origin_class(const Class& value) const {
  StorePointer(&raw_ptr()->origin_class_, value.raw());
}

void PatchClass::set_script(const Script& value) const {
  StorePointer(&raw_ptr()->script_, value.raw());
}

intptr_t Function::Hash() const {
  return String::HashRawSymbol(name());
}

bool Function::HasBreakpoint() const {
#if defined(PRODUCT)
  return false;
#else
  Thread* thread = Thread::Current();
  return thread->isolate()->debugger()->HasBreakpoint(*this, thread->zone());
#endif
}

void Function::InstallOptimizedCode(const Code& code) const {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  // We may not have previous code if FLAG_precompile is set.
  // Hot-reload may have already disabled the current code.
  if (HasCode() && !Code::Handle(CurrentCode()).IsDisabled()) {
    Code::Handle(CurrentCode()).DisableDartCode();
  }
  AttachCode(code);
}

void Function::SetInstructions(const Code& value) const {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  SetInstructionsSafe(value);
}

void Function::SetInstructionsSafe(const Code& value) const {
  StorePointer(&raw_ptr()->code_, value.raw());
  StoreNonPointer(&raw_ptr()->entry_point_, value.UncheckedEntryPoint());
}

void Function::AttachCode(const Code& value) const {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  // Finish setting up code before activating it.
  value.set_owner(*this);
  SetInstructions(value);
  ASSERT(Function::Handle(value.function()).IsNull() ||
         (value.function() == this->raw()));
}

bool Function::HasCode() const {
  ASSERT(raw_ptr()->code_ != Code::null());
  return raw_ptr()->code_ != StubCode::LazyCompile_entry()->code();
}

void Function::ClearCode() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(Thread::Current()->IsMutatorThread());
  StorePointer(&raw_ptr()->unoptimized_code_, Code::null());
  SetInstructions(Code::Handle(StubCode::LazyCompile_entry()->code()));
#endif
}

void Function::EnsureHasCompiledUnoptimizedCode() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());

  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, *this));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
}

void Function::SwitchToUnoptimizedCode() const {
  ASSERT(HasOptimizedCode());
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());
  const Code& current_code = Code::Handle(zone, CurrentCode());

  if (FLAG_trace_deoptimization_verbose) {
    THR_Print("Disabling optimized code: '%s' entry: %#" Px "\n",
              ToFullyQualifiedCString(), current_code.UncheckedEntryPoint());
  }
  current_code.DisableDartCode();
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, *this));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& unopt_code = Code::Handle(zone, unoptimized_code());
  AttachCode(unopt_code);
  unopt_code.Enable();
  isolate->TrackDeoptimizedCode(current_code);
}

void Function::SwitchToLazyCompiledUnoptimizedCode() const {
  if (!HasOptimizedCode()) {
    return;
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());

  const Code& current_code = Code::Handle(zone, CurrentCode());
  TIR_Print("Disabling optimized code for %s\n", ToCString());
  current_code.DisableDartCode();

  const Code& unopt_code = Code::Handle(zone, unoptimized_code());
  if (unopt_code.IsNull()) {
    // Set the lazy compile code.
    TIR_Print("Switched to lazy compile stub for %s\n", ToCString());
    SetInstructions(Code::Handle(StubCode::LazyCompile_entry()->code()));
    return;
  }

  TIR_Print("Switched to unoptimized code for %s\n", ToCString());

  AttachCode(unopt_code);
  unopt_code.Enable();
}

void Function::set_unoptimized_code(const Code& value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(value.IsNull() || !value.is_optimized());
  StorePointer(&raw_ptr()->unoptimized_code_, value.raw());
#endif
}

RawContextScope* Function::context_scope() const {
  if (IsClosureFunction() || IsConvertedClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    return ClosureData::Cast(obj).context_scope();
  }
  return ContextScope::null();
}

void Function::set_context_scope(const ContextScope& value) const {
  if (IsClosureFunction() || IsConvertedClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    ClosureData::Cast(obj).set_context_scope(value);
    return;
  }
  UNREACHABLE();
}

RawInstance* Function::implicit_static_closure() const {
  if (IsImplicitStaticClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    return ClosureData::Cast(obj).implicit_static_closure();
  }
  return Instance::null();
}

void Function::set_implicit_static_closure(const Instance& closure) const {
  if (IsImplicitStaticClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    ClosureData::Cast(obj).set_implicit_static_closure(closure);
    return;
  }
  UNREACHABLE();
}

RawScript* Function::eval_script() const {
  const Object& obj = Object::Handle(raw_ptr()->data_);
  if (obj.IsScript()) {
    return Script::Cast(obj).raw();
  }
  return Script::null();
}

void Function::set_eval_script(const Script& script) const {
  ASSERT(token_pos() == TokenPosition::kMinSource);
  ASSERT(raw_ptr()->data_ == Object::null());
  set_data(script);
}

RawFunction* Function::extracted_method_closure() const {
  ASSERT(kind() == RawFunction::kMethodExtractor);
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(obj.IsFunction());
  return Function::Cast(obj).raw();
}

void Function::set_extracted_method_closure(const Function& value) const {
  ASSERT(kind() == RawFunction::kMethodExtractor);
  ASSERT(raw_ptr()->data_ == Object::null());
  set_data(value);
}

RawArray* Function::saved_args_desc() const {
  ASSERT(kind() == RawFunction::kNoSuchMethodDispatcher ||
         kind() == RawFunction::kInvokeFieldDispatcher);
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(obj.IsArray());
  return Array::Cast(obj).raw();
}

void Function::set_saved_args_desc(const Array& value) const {
  ASSERT(kind() == RawFunction::kNoSuchMethodDispatcher ||
         kind() == RawFunction::kInvokeFieldDispatcher);
  ASSERT(raw_ptr()->data_ == Object::null());
  set_data(value);
}

RawField* Function::LookupImplicitGetterSetterField() const {
  ASSERT((kind() == RawFunction::kImplicitGetter) ||
         (kind() == RawFunction::kImplicitSetter) ||
         (kind() == RawFunction::kImplicitStaticFinalGetter));
  const Class& owner = Class::Handle(Owner());
  ASSERT(!owner.IsNull());
  const Array& fields = Array::Handle(owner.fields());
  ASSERT(!fields.IsNull());
  Field& field = Field::Handle();
  for (intptr_t i = 0; i < fields.Length(); i++) {
    field ^= fields.At(i);
    ASSERT(!field.IsNull());
    if (field.token_pos() == token_pos()) {
      return field.raw();
    }
  }
  return Field::null();
}

RawFunction* Function::parent_function() const {
  if (IsClosureFunction() || IsConvertedClosureFunction() ||
      IsSignatureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    if (IsClosureFunction() || IsConvertedClosureFunction()) {
      return ClosureData::Cast(obj).parent_function();
    } else {
      return SignatureData::Cast(obj).parent_function();
    }
  }
  return Function::null();
}

void Function::set_parent_function(const Function& value) const {
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(!obj.IsNull());
  if (IsClosureFunction() || IsConvertedClosureFunction()) {
    ClosureData::Cast(obj).set_parent_function(value);
  } else {
    ASSERT(IsSignatureFunction());
    SignatureData::Cast(obj).set_parent_function(value);
  }
}

bool Function::HasGenericParent() const {
  if (IsImplicitClosureFunction()) {
    // The parent function of an implicit closure function is not the enclosing
    // function we are asking about here.
    return false;
  }
  Function& parent = Function::Handle(parent_function());
  while (!parent.IsNull()) {
    if (parent.IsGeneric()) {
      return true;
    }
    parent = parent.parent_function();
  }
  return false;
}

RawFunction* Function::implicit_closure_function() const {
  if (IsClosureFunction() || IsConvertedClosureFunction() ||
      IsSignatureFunction() || IsFactory()) {
    return Function::null();
  }
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(obj.IsNull() || obj.IsScript() || obj.IsFunction() || obj.IsArray());
  if (obj.IsNull() || obj.IsScript()) {
    return Function::null();
  }
  if (obj.IsFunction()) {
    return Function::Cast(obj).raw();
  }
  ASSERT(is_native());
  ASSERT(obj.IsArray());
  const Object& res = Object::Handle(Array::Cast(obj).At(1));
  return res.IsNull() ? Function::null() : Function::Cast(res).raw();
}

void Function::set_implicit_closure_function(const Function& value) const {
  ASSERT(!IsClosureFunction() && !IsSignatureFunction() &&
         !IsConvertedClosureFunction());
  if (is_native()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(obj.IsArray());
    ASSERT((Array::Cast(obj).At(1) == Object::null()) || value.IsNull());
    Array::Cast(obj).SetAt(1, value);
  } else {
    ASSERT((raw_ptr()->data_ == Object::null()) || value.IsNull());
    set_data(value);
  }
}

RawFunction* Function::converted_closure_function() const {
  if (IsClosureFunction() || IsSignatureFunction() || IsFactory()) {
    return Function::null();
  }
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(obj.IsNull() || obj.IsFunction());
  if (obj.IsFunction()) {
    return Function::Cast(obj).raw();
  }
  return Function::null();
}

void Function::set_converted_closure_function(const Function& value) const {
  ASSERT(!IsClosureFunction() && !IsSignatureFunction() && !is_native());
  ASSERT((raw_ptr()->data_ == Object::null()) || value.IsNull());
  set_data(value);
}

RawType* Function::ExistingSignatureType() const {
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(!obj.IsNull());
  if (IsSignatureFunction()) {
    return SignatureData::Cast(obj).signature_type();
  } else {
    ASSERT(IsClosureFunction() || IsConvertedClosureFunction());
    return ClosureData::Cast(obj).signature_type();
  }
}

RawType* Function::SignatureType() const {
  Type& type = Type::Handle(ExistingSignatureType());
  if (type.IsNull()) {
    // The function type of this function is not yet cached and needs to be
    // constructed and cached here.
    // A function type is type parameterized in the same way as the owner class
    // of its non-static signature function.
    // It is not type parameterized if its signature function is static, or if
    // none of its result type or formal parameter types are type parameterized.
    // Unless the function type is a generic typedef, the type arguments of the
    // function type are not explicitly stored in the function type as a vector
    // of type arguments.
    // The type class of a non-typedef function type is always the non-generic
    // _Closure class, whether the type is generic or not.
    // The type class of a typedef function type is always the typedef class,
    // which may be generic, in which case the type stores type arguments.
    // With the introduction of generic functions, we may reach here before the
    // function type parameters have been resolved. Therefore, we cannot yet
    // check whether the function type has an instantiated signature.
    // We can do it only when the signature has been resolved.
    // We only set the type class of the function type to the typedef class
    // if the signature of the function type is the signature of the typedef.
    // Note that a function type can have a typedef class as owner without
    // representing the typedef, as in the following example:
    // typedef F(f(int x)); where the type of f is a function type with F as
    // owner, without representing the function type of F.
    Class& scope_class = Class::Handle(Owner());
    if (!scope_class.IsTypedefClass() ||
        (scope_class.signature_function() != raw())) {
      scope_class = Isolate::Current()->object_store()->closure_class();
    }
    const TypeArguments& signature_type_arguments =
        TypeArguments::Handle(scope_class.type_parameters());
    // Return the still unfinalized signature type.
    type = Type::New(scope_class, signature_type_arguments, token_pos());
    type.set_signature(*this);
    SetSignatureType(type);
  }
  return type.raw();
}

void Function::SetSignatureType(const Type& value) const {
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(!obj.IsNull());
  if (IsSignatureFunction()) {
    SignatureData::Cast(obj).set_signature_type(value);
    ASSERT(!value.IsCanonical() || (value.signature() == this->raw()));
  } else {
    ASSERT(IsClosureFunction() || IsConvertedClosureFunction());
    ClosureData::Cast(obj).set_signature_type(value);
  }
}

bool Function::IsRedirectingFactory() const {
  if (!IsFactory() || !is_redirecting()) {
    return false;
  }
  ASSERT(!IsClosureFunction());  // A factory cannot also be a closure.
  return true;
}

RawType* Function::RedirectionType() const {
  ASSERT(IsRedirectingFactory());
  ASSERT(!is_native());
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(!obj.IsNull());
  return RedirectionData::Cast(obj).type();
}

const char* Function::KindToCString(RawFunction::Kind kind) {
  switch (kind) {
    case RawFunction::kRegularFunction:
      return "RegularFunction";
      break;
    case RawFunction::kClosureFunction:
      return "ClosureFunction";
      break;
    case RawFunction::kImplicitClosureFunction:
      return "ImplicitClosureFunction";
      break;
    case RawFunction::kConvertedClosureFunction:
      return "ConvertedClosureFunction";
      break;
    case RawFunction::kSignatureFunction:
      return "SignatureFunction";
      break;
    case RawFunction::kGetterFunction:
      return "GetterFunction";
      break;
    case RawFunction::kSetterFunction:
      return "SetterFunction";
      break;
    case RawFunction::kConstructor:
      return "Constructor";
      break;
    case RawFunction::kImplicitGetter:
      return "ImplicitGetter";
      break;
    case RawFunction::kImplicitSetter:
      return "ImplicitSetter";
      break;
    case RawFunction::kImplicitStaticFinalGetter:
      return "ImplicitStaticFinalGetter";
      break;
    case RawFunction::kMethodExtractor:
      return "MethodExtractor";
      break;
    case RawFunction::kNoSuchMethodDispatcher:
      return "NoSuchMethodDispatcher";
      break;
    case RawFunction::kInvokeFieldDispatcher:
      return "InvokeFieldDispatcher";
      break;
    case RawFunction::kIrregexpFunction:
      return "IrregexpFunction";
      break;
    default:
      UNREACHABLE();
      return NULL;
  }
}

void Function::SetRedirectionType(const Type& type) const {
  ASSERT(IsFactory());
  Object& obj = Object::Handle(raw_ptr()->data_);
  if (obj.IsNull()) {
    obj = RedirectionData::New();
    set_data(obj);
  }
  RedirectionData::Cast(obj).set_type(type);
}

RawString* Function::RedirectionIdentifier() const {
  ASSERT(IsRedirectingFactory());
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(!obj.IsNull());
  return RedirectionData::Cast(obj).identifier();
}

void Function::SetRedirectionIdentifier(const String& identifier) const {
  ASSERT(IsFactory());
  Object& obj = Object::Handle(raw_ptr()->data_);
  if (obj.IsNull()) {
    obj = RedirectionData::New();
    set_data(obj);
  }
  RedirectionData::Cast(obj).set_identifier(identifier);
}

RawFunction* Function::RedirectionTarget() const {
  ASSERT(IsRedirectingFactory());
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(!obj.IsNull());
  return RedirectionData::Cast(obj).target();
}

void Function::SetRedirectionTarget(const Function& target) const {
  ASSERT(IsFactory());
  Object& obj = Object::Handle(raw_ptr()->data_);
  if (obj.IsNull()) {
    obj = RedirectionData::New();
    set_data(obj);
  }
  RedirectionData::Cast(obj).set_target(target);
}

// This field is heavily overloaded:
//   eval function:           Script expression source
//   signature function:      SignatureData
//   method extractor:        Function extracted closure function
//   noSuchMethod dispatcher: Array arguments descriptor
//   invoke-field dispatcher: Array arguments descriptor
//   redirecting constructor: RedirectionData
//   closure function:        ClosureData
//   irregexp function:       Array[0] = RegExp
//                            Array[1] = Smi string specialization cid
//   native function:         Array[0] = String native name
//                            Array[1] = Function implicit closure function
//   regular function:        Function for implicit closure function
void Function::set_data(const Object& value) const {
  StorePointer(&raw_ptr()->data_, value.raw());
}

bool Function::IsInFactoryScope() const {
  if (!IsLocalFunction()) {
    return IsFactory();
  }
  Function& outer_function = Function::Handle(parent_function());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  return outer_function.IsFactory();
}

void Function::set_name(const String& value) const {
  ASSERT(value.IsSymbol());
  StorePointer(&raw_ptr()->name_, value.raw());
}

void Function::set_owner(const Object& value) const {
  ASSERT(!value.IsNull() || IsSignatureFunction());
  StorePointer(&raw_ptr()->owner_, value.raw());
}

RawRegExp* Function::regexp() const {
  ASSERT(kind() == RawFunction::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data_));
  return RegExp::RawCast(pair.At(0));
}

class StickySpecialization : public BitField<intptr_t, bool, 0, 1> {};
class StringSpecializationCid
    : public BitField<intptr_t, intptr_t, 1, RawObject::kClassIdTagSize> {};

intptr_t Function::string_specialization_cid() const {
  ASSERT(kind() == RawFunction::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data_));
  return StringSpecializationCid::decode(Smi::Value(Smi::RawCast(pair.At(1))));
}

bool Function::is_sticky_specialization() const {
  ASSERT(kind() == RawFunction::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data_));
  return StickySpecialization::decode(Smi::Value(Smi::RawCast(pair.At(1))));
}

void Function::SetRegExpData(const RegExp& regexp,
                             intptr_t string_specialization_cid,
                             bool sticky) const {
  ASSERT(kind() == RawFunction::kIrregexpFunction);
  ASSERT(RawObject::IsStringClassId(string_specialization_cid));
  ASSERT(raw_ptr()->data_ == Object::null());
  const Array& pair = Array::Handle(Array::New(2, Heap::kOld));
  pair.SetAt(0, regexp);
  pair.SetAt(1, Smi::Handle(Smi::New(StickySpecialization::encode(sticky) |
                                     StringSpecializationCid::encode(
                                         string_specialization_cid))));
  set_data(pair);
}

RawString* Function::native_name() const {
  ASSERT(is_native());
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(obj.IsArray());
  return String::RawCast(Array::Cast(obj).At(0));
}

void Function::set_native_name(const String& value) const {
  ASSERT(is_native());
  ASSERT(raw_ptr()->data_ == Object::null());
  const Array& pair = Array::Handle(Array::New(2, Heap::kOld));
  pair.SetAt(0, value);
  // pair[1] will be the implicit closure function if needed.
  set_data(pair);
}

void Function::set_result_type(const AbstractType& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->result_type_, value.raw());
}

RawAbstractType* Function::ParameterTypeAt(intptr_t index) const {
  const Array& parameter_types = Array::Handle(raw_ptr()->parameter_types_);
  return AbstractType::RawCast(parameter_types.At(index));
}

void Function::SetParameterTypeAt(intptr_t index,
                                  const AbstractType& value) const {
  ASSERT(!value.IsNull());
  // Method extractor parameters are shared and are in the VM heap.
  ASSERT(kind() != RawFunction::kMethodExtractor);
  const Array& parameter_types = Array::Handle(raw_ptr()->parameter_types_);
  parameter_types.SetAt(index, value);
}

void Function::set_parameter_types(const Array& value) const {
  StorePointer(&raw_ptr()->parameter_types_, value.raw());
}

RawString* Function::ParameterNameAt(intptr_t index) const {
  const Array& parameter_names = Array::Handle(raw_ptr()->parameter_names_);
  return String::RawCast(parameter_names.At(index));
}

void Function::SetParameterNameAt(intptr_t index, const String& value) const {
  ASSERT(!value.IsNull() && value.IsSymbol());
  const Array& parameter_names = Array::Handle(raw_ptr()->parameter_names_);
  parameter_names.SetAt(index, value);
}

void Function::set_parameter_names(const Array& value) const {
  StorePointer(&raw_ptr()->parameter_names_, value.raw());
}

void Function::set_type_parameters(const TypeArguments& value) const {
  StorePointer(&raw_ptr()->type_parameters_, value.raw());
}

intptr_t Function::NumTypeParameters(Thread* thread) const {
  if (type_parameters() == TypeArguments::null()) {
    return 0;
  }
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(thread);
  TypeArguments& type_params = thread->TypeArgumentsHandle();
  type_params = type_parameters();
  // We require null to represent a non-generic function.
  ASSERT(type_params.Length() != 0);
  return type_params.Length();
}

intptr_t Function::NumParentTypeParameters() const {
  if (IsImplicitClosureFunction()) {
    return 0;
  }
  Thread* thread = Thread::Current();
  Function& parent = Function::Handle(parent_function());
  intptr_t num_parent_type_params = 0;
  while (!parent.IsNull()) {
    num_parent_type_params += parent.NumTypeParameters(thread);
    if (parent.IsImplicitClosureFunction()) break;
    parent ^= parent.parent_function();
  }
  return num_parent_type_params;
}

void Function::PrintSignatureTypes() const {
  Function& sig_fun = Function::Handle(raw());
  Type& sig_type = Type::Handle();
  while (!sig_fun.IsNull()) {
    sig_type = sig_fun.SignatureType();
    THR_Print("%s%s\n",
              sig_fun.IsImplicitClosureFunction() ? "implicit closure: " : "",
              sig_type.ToCString());
    sig_fun ^= sig_fun.parent_function();
  }
}

RawTypeParameter* Function::LookupTypeParameter(
    const String& type_name,
    intptr_t* function_level) const {
  ASSERT(!type_name.IsNull());
  Thread* thread = Thread::Current();
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(thread);
  REUSABLE_TYPE_PARAMETER_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  TypeArguments& type_params = thread->TypeArgumentsHandle();
  TypeParameter& type_param = thread->TypeParameterHandle();
  String& type_param_name = thread->StringHandle();
  Function& function = thread->FunctionHandle();

  function ^= this->raw();
  while (!function.IsNull()) {
    type_params ^= function.type_parameters();
    if (!type_params.IsNull()) {
      const intptr_t num_type_params = type_params.Length();
      for (intptr_t i = 0; i < num_type_params; i++) {
        type_param ^= type_params.TypeAt(i);
        type_param_name = type_param.name();
        if (type_param_name.Equals(type_name)) {
          return type_param.raw();
        }
      }
    }
    if (function.IsImplicitClosureFunction()) {
      // The parent function is not the enclosing function, but the closurized
      // function with identical type parameters.
      break;
    }
    function ^= function.parent_function();
    if (function_level != NULL) {
      (*function_level)--;
    }
  }
  return TypeParameter::null();
}

void Function::set_kind(RawFunction::Kind value) const {
  set_kind_tag(KindBits::update(value, raw_ptr()->kind_tag_));
}

void Function::set_modifier(RawFunction::AsyncModifier value) const {
  set_kind_tag(ModifierBits::update(value, raw_ptr()->kind_tag_));
}

void Function::set_recognized_kind(MethodRecognizer::Kind value) const {
  // Prevent multiple settings of kind.
  ASSERT((value == MethodRecognizer::kUnknown) || !IsRecognized());
  set_kind_tag(RecognizedBits::update(value, raw_ptr()->kind_tag_));
}

void Function::set_token_pos(TokenPosition token_pos) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(!token_pos.IsClassifying() || IsMethodExtractor());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
#endif
}

void Function::set_kind_tag(uint32_t value) const {
  StoreNonPointer(&raw_ptr()->kind_tag_, static_cast<uint32_t>(value));
}

void Function::set_num_fixed_parameters(intptr_t value) const {
  ASSERT(value >= 0);
  ASSERT(Utils::IsInt(16, value));
  StoreNonPointer(&raw_ptr()->num_fixed_parameters_,
                  static_cast<int16_t>(value));
}

void Function::set_num_optional_parameters(intptr_t value) const {
  // A positive value indicates positional params, a negative one named params.
  ASSERT(Utils::IsInt(16, value));
  StoreNonPointer(&raw_ptr()->num_optional_parameters_,
                  static_cast<int16_t>(value));
}

void Function::SetNumOptionalParameters(intptr_t num_optional_parameters,
                                        bool are_optional_positional) const {
  ASSERT(num_optional_parameters >= 0);
  set_num_optional_parameters(are_optional_positional
                                  ? num_optional_parameters
                                  : -num_optional_parameters);
}

void Function::set_kernel_data(const TypedData& data) const {
  StorePointer(&raw_ptr()->kernel_data_, data.raw());
}

bool Function::IsOptimizable() const {
  if (FLAG_precompiled_mode) {
    return true;
  }
  if (is_native()) {
    // Native methods don't need to be optimized.
    return false;
  }
  const intptr_t function_length = end_token_pos().Pos() - token_pos().Pos();
  if (is_optimizable() && (script() != Script::null()) &&
      (function_length < FLAG_huge_method_cutoff_in_tokens)) {
    // Additional check needed for implicit getters.
    return (unoptimized_code() == Object::null()) ||
           (Code::Handle(unoptimized_code()).Size() <
            FLAG_huge_method_cutoff_in_code_size);
  }
  return false;
}

void Function::SetIsOptimizable(bool value) const {
  ASSERT(!is_native());
  set_is_optimizable(value);
  if (!value) {
    set_is_inlinable(false);
    set_usage_counter(INT_MIN);
  }
}

bool Function::CanBeInlined() const {
#if defined(PRODUCT)
  return is_inlinable() && !is_external() && !is_generated_body();
#else
  Thread* thread = Thread::Current();
  return is_inlinable() && !is_external() && !is_generated_body() &&
         !thread->isolate()->debugger()->HasBreakpoint(*this, thread->zone());
#endif
}

intptr_t Function::NumParameters() const {
  return num_fixed_parameters() + NumOptionalParameters();
}

intptr_t Function::NumImplicitParameters() const {
  const RawFunction::Kind k = kind();
  if (k == RawFunction::kConstructor) {
    // Type arguments for factory; instance for generative constructor.
    return 1;
  }
  if ((k == RawFunction::kClosureFunction) ||
      (k == RawFunction::kImplicitClosureFunction) ||
      (k == RawFunction::kSignatureFunction) ||
      (k == RawFunction::kConvertedClosureFunction)) {
    return 1;  // Closure object.
  }
  if (!is_static()) {
    // Closure functions defined inside instance (i.e. non-static) functions are
    // marked as non-static, but they do not have a receiver.
    // Closures are handled above.
    ASSERT((k != RawFunction::kClosureFunction) &&
           (k != RawFunction::kImplicitClosureFunction) &&
           (k != RawFunction::kSignatureFunction));
    return 1;  // Receiver.
  }
  return 0;  // No implicit parameters.
}

bool Function::AreValidArgumentCounts(intptr_t num_type_arguments,
                                      intptr_t num_arguments,
                                      intptr_t num_named_arguments,
                                      String* error_message) const {
  if ((num_type_arguments != 0) &&
      (num_type_arguments != NumTypeParameters())) {
    if (error_message != NULL) {
      const intptr_t kMessageBufferSize = 64;
      char message_buffer[kMessageBufferSize];
      OS::SNPrint(message_buffer, kMessageBufferSize,
                  "%" Pd " type arguments passed, but %" Pd " expected",
                  num_type_arguments, NumTypeParameters());
      // Allocate in old space because it can be invoked in background
      // optimizing compilation.
      *error_message = String::New(message_buffer, Heap::kOld);
    }
    return false;  // Too many type arguments.
  }
  if (num_named_arguments > NumOptionalNamedParameters()) {
    if (error_message != NULL) {
      const intptr_t kMessageBufferSize = 64;
      char message_buffer[kMessageBufferSize];
      OS::SNPrint(message_buffer, kMessageBufferSize,
                  "%" Pd " named passed, at most %" Pd " expected",
                  num_named_arguments, NumOptionalNamedParameters());
      // Allocate in old space because it can be invoked in background
      // optimizing compilation.
      *error_message = String::New(message_buffer, Heap::kOld);
    }
    return false;  // Too many named arguments.
  }
  const intptr_t num_pos_args = num_arguments - num_named_arguments;
  const intptr_t num_opt_pos_params = NumOptionalPositionalParameters();
  const intptr_t num_pos_params = num_fixed_parameters() + num_opt_pos_params;
  if (num_pos_args > num_pos_params) {
    if (error_message != NULL) {
      const intptr_t kMessageBufferSize = 64;
      char message_buffer[kMessageBufferSize];
      // Hide implicit parameters to the user.
      const intptr_t num_hidden_params = NumImplicitParameters();
      OS::SNPrint(message_buffer, kMessageBufferSize,
                  "%" Pd "%s passed, %s%" Pd " expected",
                  num_pos_args - num_hidden_params,
                  num_opt_pos_params > 0 ? " positional" : "",
                  num_opt_pos_params > 0 ? "at most " : "",
                  num_pos_params - num_hidden_params);
      // Allocate in old space because it can be invoked in background
      // optimizing compilation.
      *error_message = String::New(message_buffer, Heap::kOld);
    }
    return false;  // Too many fixed and/or positional arguments.
  }
  if (num_pos_args < num_fixed_parameters()) {
    if (error_message != NULL) {
      const intptr_t kMessageBufferSize = 64;
      char message_buffer[kMessageBufferSize];
      // Hide implicit parameters to the user.
      const intptr_t num_hidden_params = NumImplicitParameters();
      OS::SNPrint(message_buffer, kMessageBufferSize,
                  "%" Pd "%s passed, %s%" Pd " expected",
                  num_pos_args - num_hidden_params,
                  num_opt_pos_params > 0 ? " positional" : "",
                  num_opt_pos_params > 0 ? "at least " : "",
                  num_fixed_parameters() - num_hidden_params);
      // Allocate in old space because it can be invoked in background
      // optimizing compilation.
      *error_message = String::New(message_buffer, Heap::kOld);
    }
    return false;  // Too few fixed and/or positional arguments.
  }
  return true;
}

bool Function::AreValidArguments(intptr_t num_type_arguments,
                                 intptr_t num_arguments,
                                 const Array& argument_names,
                                 String* error_message) const {
  const intptr_t num_named_arguments =
      argument_names.IsNull() ? 0 : argument_names.Length();
  if (!AreValidArgumentCounts(num_type_arguments, num_arguments,
                              num_named_arguments, error_message)) {
    return false;
  }
  // Verify that all argument names are valid parameter names.
  Zone* zone = Thread::Current()->zone();
  String& argument_name = String::Handle(zone);
  String& parameter_name = String::Handle(zone);
  for (intptr_t i = 0; i < num_named_arguments; i++) {
    argument_name ^= argument_names.At(i);
    ASSERT(argument_name.IsSymbol());
    bool found = false;
    const intptr_t num_positional_args = num_arguments - num_named_arguments;
    const intptr_t num_parameters = NumParameters();
    for (intptr_t j = num_positional_args; !found && (j < num_parameters);
         j++) {
      parameter_name = ParameterNameAt(j);
      ASSERT(argument_name.IsSymbol());
      if (argument_name.Equals(parameter_name)) {
        found = true;
      }
    }
    if (!found) {
      if (error_message != NULL) {
        const intptr_t kMessageBufferSize = 64;
        char message_buffer[kMessageBufferSize];
        OS::SNPrint(message_buffer, kMessageBufferSize,
                    "no optional formal parameter named '%s'",
                    argument_name.ToCString());
        // Allocate in old space because it can be invoked in background
        // optimizing compilation.
        *error_message = String::New(message_buffer, Heap::kOld);
      }
      return false;
    }
  }
  return true;
}

bool Function::AreValidArguments(const ArgumentsDescriptor& args_desc,
                                 String* error_message) const {
  const intptr_t num_type_arguments = args_desc.TypeArgsLen();
  const intptr_t num_arguments = args_desc.Count();
  const intptr_t num_named_arguments = args_desc.NamedCount();

  if (!AreValidArgumentCounts(num_type_arguments, num_arguments,
                              num_named_arguments, error_message)) {
    return false;
  }
  // Verify that all argument names are valid parameter names.
  Zone* zone = Thread::Current()->zone();
  String& argument_name = String::Handle(zone);
  String& parameter_name = String::Handle(zone);
  for (intptr_t i = 0; i < num_named_arguments; i++) {
    argument_name ^= args_desc.NameAt(i);
    ASSERT(argument_name.IsSymbol());
    bool found = false;
    const intptr_t num_positional_args = num_arguments - num_named_arguments;
    const int num_parameters = NumParameters();
    for (intptr_t j = num_positional_args; !found && (j < num_parameters);
         j++) {
      parameter_name = ParameterNameAt(j);
      ASSERT(argument_name.IsSymbol());
      if (argument_name.Equals(parameter_name)) {
        found = true;
      }
    }
    if (!found) {
      if (error_message != NULL) {
        const intptr_t kMessageBufferSize = 64;
        char message_buffer[kMessageBufferSize];
        OS::SNPrint(message_buffer, kMessageBufferSize,
                    "no optional formal parameter named '%s'",
                    argument_name.ToCString());
        // Allocate in old space because it can be invoked in background
        // optimizing compilation.
        *error_message = String::New(message_buffer, Heap::kOld);
      }
      return false;
    }
  }
  return true;
}

// Helper allocating a C string buffer in the zone, printing the fully qualified
// name of a function in it, and replacing ':' by '_' to make sure the
// constructed name is a valid C++ identifier for debugging purpose.
// Set 'chars' to allocated buffer and return number of written characters.

enum QualifiedFunctionLibKind {
  kQualifiedFunctionLibKindLibUrl,
  kQualifiedFunctionLibKindLibName
};

static intptr_t ConstructFunctionFullyQualifiedCString(
    const Function& function,
    char** chars,
    intptr_t reserve_len,
    bool with_lib,
    QualifiedFunctionLibKind lib_kind) {
  const char* name = String::Handle(function.name()).ToCString();
  const char* function_format = (reserve_len == 0) ? "%s" : "%s_";
  reserve_len += OS::SNPrint(NULL, 0, function_format, name);
  const Function& parent = Function::Handle(function.parent_function());
  intptr_t written = 0;
  if (parent.IsNull()) {
    const Class& function_class = Class::Handle(function.Owner());
    ASSERT(!function_class.IsNull());
    const char* class_name = String::Handle(function_class.Name()).ToCString();
    ASSERT(class_name != NULL);
    const Library& library = Library::Handle(function_class.library());
    ASSERT(!library.IsNull());
    const char* library_name = NULL;
    const char* lib_class_format = NULL;
    if (with_lib) {
      switch (lib_kind) {
        case kQualifiedFunctionLibKindLibUrl:
          library_name = String::Handle(library.url()).ToCString();
          break;
        case kQualifiedFunctionLibKindLibName:
          library_name = String::Handle(library.name()).ToCString();
          break;
        default:
          UNREACHABLE();
      }
      ASSERT(library_name != NULL);
      lib_class_format = (library_name[0] == '\0') ? "%s%s_" : "%s_%s_";
    } else {
      library_name = "";
      lib_class_format = "%s%s.";
    }
    reserve_len +=
        OS::SNPrint(NULL, 0, lib_class_format, library_name, class_name);
    ASSERT(chars != NULL);
    *chars = Thread::Current()->zone()->Alloc<char>(reserve_len + 1);
    written = OS::SNPrint(*chars, reserve_len + 1, lib_class_format,
                          library_name, class_name);
  } else {
    written = ConstructFunctionFullyQualifiedCString(parent, chars, reserve_len,
                                                     with_lib, lib_kind);
  }
  ASSERT(*chars != NULL);
  char* next = *chars + written;
  written += OS::SNPrint(next, reserve_len + 1, function_format, name);
  // Replace ":" with "_".
  while (true) {
    next = strchr(next, ':');
    if (next == NULL) break;
    *next = '_';
  }
  return written;
}

const char* Function::ToFullyQualifiedCString() const {
  char* chars = NULL;
  ConstructFunctionFullyQualifiedCString(*this, &chars, 0, true,
                                         kQualifiedFunctionLibKindLibUrl);
  return chars;
}

const char* Function::ToLibNamePrefixedQualifiedCString() const {
  char* chars = NULL;
  ConstructFunctionFullyQualifiedCString(*this, &chars, 0, true,
                                         kQualifiedFunctionLibKindLibName);
  return chars;
}

const char* Function::ToQualifiedCString() const {
  char* chars = NULL;
  ConstructFunctionFullyQualifiedCString(*this, &chars, 0, false,
                                         kQualifiedFunctionLibKindLibUrl);
  return chars;
}

bool Function::HasCompatibleParametersWith(const Function& other,
                                           Error* bound_error) const {
  ASSERT(Isolate::Current()->error_on_bad_override());
  ASSERT((bound_error != NULL) && bound_error->IsNull());
  // Check that this function's signature type is a subtype of the other
  // function's signature type.
  // Map type parameters referred to by formal parameter types and result type
  // in the signature to dynamic before the test.
  // Note that type parameters declared by a generic signature are preserved.
  Function& this_fun = Function::Handle(raw());
  if (!this_fun.HasInstantiatedSignature()) {
    this_fun = this_fun.InstantiateSignatureFrom(Object::null_type_arguments(),
                                                 Object::null_type_arguments(),
                                                 Heap::kOld);
  }
  Function& other_fun = Function::Handle(other.raw());
  if (!other_fun.HasInstantiatedSignature()) {
    other_fun = other_fun.InstantiateSignatureFrom(
        Object::null_type_arguments(), Object::null_type_arguments(),
        Heap::kOld);
  }
  if (!this_fun.TypeTest(kIsSubtypeOf, other_fun, bound_error, NULL,
                         Heap::kOld)) {
    // For more informative error reporting, use the location of the other
    // function here, since the caller will use the location of this function.
    *bound_error = LanguageError::NewFormatted(
        *bound_error,  // A bound error if non null.
        Script::Handle(other.script()), other.token_pos(), Report::AtLocation,
        Report::kError, Heap::kNew,
        "signature type '%s' of function '%s' is not a subtype of signature "
        "type '%s' of function '%s'\n",
        String::Handle(UserVisibleSignature()).ToCString(),
        String::Handle(UserVisibleName()).ToCString(),
        String::Handle(other.UserVisibleSignature()).ToCString(),
        String::Handle(other.UserVisibleName()).ToCString());
    return false;
  }
  // We should also check that if the other function explicitly specifies a
  // default value for a formal parameter, this function does not specify a
  // different default value for the same parameter. However, this check is not
  // possible in the current implementation, because the default parameter
  // values are not stored in the Function object, but discarded after a
  // function is compiled.
  return true;
}

RawFunction* Function::InstantiateSignatureFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Heap::Space space) const {
  Zone* zone = Thread::Current()->zone();
  const Object& owner = Object::Handle(zone, RawOwner());
  // Note that parent pointers in newly instantiated signatures still points to
  // the original uninstantiated parent signatures. That is not a problem.
  const Function& parent = Function::Handle(zone, parent_function());
  ASSERT(!HasInstantiatedSignature());

  Function& sig = Function::Handle(zone, Function::null());
  if (IsConvertedClosureFunction()) {
    sig = Function::NewConvertedClosureFunction(
        String::Handle(zone, name()), parent, TokenPosition::kNoSource);
    // TODO(30455): Kernel generic methods undone. Handle type parameters
    // correctly when generic closures are supported. Until then, all type
    // parameters to this target are used for captured type variables, so they
    // aren't relevant to the type of the function.
    sig.set_type_parameters(TypeArguments::Handle(zone, TypeArguments::null()));
  } else {
    sig = Function::NewSignatureFunction(owner, parent,
                                         TokenPosition::kNoSource, space);
    sig.set_type_parameters(TypeArguments::Handle(zone, type_parameters()));
  }

  AbstractType& type = AbstractType::Handle(zone, result_type());
  if (!type.IsInstantiated()) {
    type =
        type.InstantiateFrom(instantiator_type_arguments,
                             function_type_arguments, NULL, NULL, NULL, space);
  }
  sig.set_result_type(type);
  const intptr_t num_params = NumParameters();
  sig.set_num_fixed_parameters(num_fixed_parameters());
  sig.SetNumOptionalParameters(NumOptionalParameters(),
                               HasOptionalPositionalParameters());
  sig.set_parameter_types(Array::Handle(Array::New(num_params, space)));
  for (intptr_t i = 0; i < num_params; i++) {
    type = ParameterTypeAt(i);
    if (!type.IsInstantiated()) {
      type = type.InstantiateFrom(instantiator_type_arguments,
                                  function_type_arguments, NULL, NULL, NULL,
                                  space);
    }
    sig.SetParameterTypeAt(i, type);
  }
  sig.set_parameter_names(Array::Handle(zone, parameter_names()));
  return sig.raw();
}

// If test_kind == kIsSubtypeOf, checks if the type of the specified parameter
// of this function is a subtype or a supertype of the type of the specified
// parameter of the other function.
// If test_kind == kIsMoreSpecificThan, checks if the type of the specified
// parameter of this function is more specific than the type of the specified
// parameter of the other function.
// Note that we do not apply contravariance of parameter types, but covariance
// of both parameter types and result type.
bool Function::TestParameterType(TypeTestKind test_kind,
                                 intptr_t parameter_position,
                                 intptr_t other_parameter_position,
                                 const Function& other,
                                 Error* bound_error,
                                 TrailPtr bound_trail,
                                 Heap::Space space) const {
  const AbstractType& other_param_type =
      AbstractType::Handle(other.ParameterTypeAt(other_parameter_position));
  if (other_param_type.IsDynamicType()) {
    return true;
  }
  const AbstractType& param_type =
      AbstractType::Handle(ParameterTypeAt(parameter_position));
  if (param_type.IsDynamicType()) {
    return test_kind == kIsSubtypeOf;
  }
  if (test_kind == kIsSubtypeOf) {
    if (!param_type.IsSubtypeOf(other_param_type, bound_error, bound_trail,
                                space) &&
        !other_param_type.IsSubtypeOf(param_type, bound_error, bound_trail,
                                      space)) {
      return false;
    }
  } else {
    ASSERT(test_kind == kIsMoreSpecificThan);
    if (!param_type.IsMoreSpecificThan(other_param_type, bound_error,
                                       bound_trail, space)) {
      return false;
    }
  }
  return true;
}

bool Function::HasSameTypeParametersAndBounds(const Function& other) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  const intptr_t num_type_params = NumTypeParameters(thread);
  if (num_type_params != other.NumTypeParameters(thread)) {
    return false;
  }
  if (num_type_params > 0) {
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, type_parameters());
    ASSERT(!type_params.IsNull());
    const TypeArguments& other_type_params =
        TypeArguments::Handle(zone, other.type_parameters());
    ASSERT(!other_type_params.IsNull());
    TypeParameter& type_param = TypeParameter::Handle(zone);
    TypeParameter& other_type_param = TypeParameter::Handle(zone);
    AbstractType& bound = AbstractType::Handle(zone);
    AbstractType& other_bound = AbstractType::Handle(zone);
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      other_type_param ^= other_type_params.TypeAt(i);
      bound = type_param.bound();
      ASSERT(bound.IsFinalized());
      other_bound = other_type_param.bound();
      ASSERT(other_bound.IsFinalized());
      if (!bound.Equals(other_bound)) {
        return false;
      }
    }
  }
  return true;
}

bool Function::TypeTest(TypeTestKind test_kind,
                        const Function& other,
                        Error* bound_error,
                        TrailPtr bound_trail,
                        Heap::Space space) const {
  const intptr_t num_fixed_params = num_fixed_parameters();
  const intptr_t num_opt_pos_params = NumOptionalPositionalParameters();
  const intptr_t num_opt_named_params = NumOptionalNamedParameters();
  const intptr_t other_num_fixed_params = other.num_fixed_parameters();
  const intptr_t other_num_opt_pos_params =
      other.NumOptionalPositionalParameters();
  const intptr_t other_num_opt_named_params =
      other.NumOptionalNamedParameters();
  // This function requires the same arguments or less and accepts the same
  // arguments or more. We can ignore implicit parameters.
  const intptr_t num_ignored_params = NumImplicitParameters();
  const intptr_t other_num_ignored_params = other.NumImplicitParameters();
  if (((num_fixed_params - num_ignored_params) >
       (other_num_fixed_params - other_num_ignored_params)) ||
      ((num_fixed_params - num_ignored_params + num_opt_pos_params) <
       (other_num_fixed_params - other_num_ignored_params +
        other_num_opt_pos_params)) ||
      (num_opt_named_params < other_num_opt_named_params)) {
    return false;
  }
  if (FLAG_reify_generic_functions) {
    // Check the type parameters and bounds of generic functions.
    if (!HasSameTypeParametersAndBounds(other)) {
      return false;
    }
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // Check the result type.
  const AbstractType& other_res_type =
      AbstractType::Handle(zone, other.result_type());
  if (!other_res_type.IsDynamicType() && !other_res_type.IsVoidType()) {
    const AbstractType& res_type = AbstractType::Handle(zone, result_type());
    if (res_type.IsVoidType()) {
      return false;
    }
    if (test_kind == kIsSubtypeOf) {
      if (!res_type.IsSubtypeOf(other_res_type, bound_error, bound_trail,
                                space) &&
          !other_res_type.IsSubtypeOf(res_type, bound_error, bound_trail,
                                      space)) {
        return false;
      }
    } else {
      ASSERT(test_kind == kIsMoreSpecificThan);
      if (!res_type.IsMoreSpecificThan(other_res_type, bound_error, bound_trail,
                                       space)) {
        return false;
      }
    }
  }
  // Check the types of fixed and optional positional parameters.
  for (intptr_t i = 0; i < (other_num_fixed_params - other_num_ignored_params +
                            other_num_opt_pos_params);
       i++) {
    if (!TestParameterType(test_kind, i + num_ignored_params,
                           i + other_num_ignored_params, other, bound_error,
                           bound_trail, space)) {
      return false;
    }
  }
  // Check the names and types of optional named parameters.
  if (other_num_opt_named_params == 0) {
    return true;
  }
  // Check that for each optional named parameter of type T of the other
  // function type, there exists an optional named parameter of this function
  // type with an identical name and with a type S that is a either a subtype
  // or supertype of T (if test_kind == kIsSubtypeOf) or that is more specific
  // than T (if test_kind == kIsMoreSpecificThan).
  // Note that SetParameterNameAt() guarantees that names are symbols, so we
  // can compare their raw pointers.
  const int num_params = num_fixed_params + num_opt_named_params;
  const int other_num_params =
      other_num_fixed_params + other_num_opt_named_params;
  bool found_param_name;
  String& other_param_name = String::Handle(zone);
  for (intptr_t i = other_num_fixed_params; i < other_num_params; i++) {
    other_param_name = other.ParameterNameAt(i);
    ASSERT(other_param_name.IsSymbol());
    found_param_name = false;
    for (intptr_t j = num_fixed_params; j < num_params; j++) {
      ASSERT(String::Handle(zone, ParameterNameAt(j)).IsSymbol());
      if (ParameterNameAt(j) == other_param_name.raw()) {
        found_param_name = true;
        if (!TestParameterType(test_kind, j, i, other, bound_error, bound_trail,
                               space)) {
          return false;
        }
        break;
      }
    }
    if (!found_param_name) {
      return false;
    }
  }
  return true;
}

// The compiler generates an implicit constructor if a class definition
// does not contain an explicit constructor or factory. The implicit
// constructor has the same token position as the owner class.
bool Function::IsImplicitConstructor() const {
  return IsGenerativeConstructor() && (token_pos() == end_token_pos());
}

bool Function::IsImplicitStaticClosureFunction(RawFunction* func) {
  NoSafepointScope no_safepoint;
  uint32_t kind_tag = func->ptr()->kind_tag_;
  return (KindBits::decode(kind_tag) ==
          RawFunction::kImplicitClosureFunction) &&
         StaticBit::decode(kind_tag);
}

bool Function::IsConstructorClosureFunction() const {
  return IsClosureFunction() &&
         String::Handle(name()).StartsWith(Symbols::ConstructorClosurePrefix());
}

RawFunction* Function::New(Heap::Space space) {
  ASSERT(Object::function_class() != Class::null());
  RawObject* raw =
      Object::Allocate(Function::kClassId, Function::InstanceSize(), space);
  return reinterpret_cast<RawFunction*>(raw);
}

RawFunction* Function::New(const String& name,
                           RawFunction::Kind kind,
                           bool is_static,
                           bool is_const,
                           bool is_abstract,
                           bool is_external,
                           bool is_native,
                           const Object& owner,
                           TokenPosition token_pos,
                           Heap::Space space) {
  ASSERT(!owner.IsNull() || (kind == RawFunction::kSignatureFunction));
  const Function& result = Function::Handle(Function::New(space));
  result.set_parameter_types(Object::empty_array());
  result.set_parameter_names(Object::empty_array());
  result.set_name(name);
  result.set_kind(kind);
  result.set_recognized_kind(MethodRecognizer::kUnknown);
  result.set_modifier(RawFunction::kNoModifier);
  result.set_is_static(is_static);
  result.set_is_const(is_const);
  result.set_is_abstract(is_abstract);
  result.set_is_external(is_external);
  result.set_is_native(is_native);
  result.set_is_reflectable(true);  // Will be computed later.
  result.set_is_visible(true);      // Will be computed later.
  result.set_is_debuggable(true);   // Will be computed later.
  result.set_is_intrinsic(false);
  result.set_is_redirecting(false);
  result.set_is_generated_body(false);
  result.set_always_inline(false);
  result.set_is_polymorphic_target(false);
  NOT_IN_PRECOMPILED(result.SetWasCompiled(false));
  result.set_owner(owner);
  NOT_IN_PRECOMPILED(result.set_token_pos(token_pos));
  NOT_IN_PRECOMPILED(result.set_end_token_pos(token_pos));
  result.set_num_fixed_parameters(0);
  result.set_num_optional_parameters(0);
  NOT_IN_PRECOMPILED(result.set_usage_counter(0));
  NOT_IN_PRECOMPILED(result.set_deoptimization_counter(0));
  NOT_IN_PRECOMPILED(result.set_optimized_instruction_count(0));
  NOT_IN_PRECOMPILED(result.set_optimized_call_site_count(0));
  NOT_IN_PRECOMPILED(result.set_inlining_depth(0));
  NOT_IN_PRECOMPILED(result.set_kernel_offset(0));
  result.set_is_optimizable(is_native ? false : true);
  result.set_is_inlinable(true);
  result.set_allows_hoisting_check_class(true);
  result.set_allows_bounds_check_generalization(true);
  result.SetInstructionsSafe(
      Code::Handle(StubCode::LazyCompile_entry()->code()));
  if (kind == RawFunction::kClosureFunction ||
      kind == RawFunction::kImplicitClosureFunction ||
      kind == RawFunction::kConvertedClosureFunction) {
    ASSERT(space == Heap::kOld);
    const ClosureData& data = ClosureData::Handle(ClosureData::New());
    result.set_data(data);
  } else if (kind == RawFunction::kSignatureFunction) {
    const SignatureData& data =
        SignatureData::Handle(SignatureData::New(space));
    result.set_data(data);
  } else {
    // Functions other than signature functions have no reason to be allocated
    // in new space.
    ASSERT(space == Heap::kOld);
  }
  return result.raw();
}

RawFunction* Function::Clone(const Class& new_owner) const {
  ASSERT(!IsGenerativeConstructor());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& clone = Function::Handle(zone);
  clone ^= Object::Clone(*this, Heap::kOld);
  const Class& origin = Class::Handle(zone, this->origin());
  const PatchClass& clone_owner =
      PatchClass::Handle(zone, PatchClass::New(new_owner, origin));
  clone.set_owner(clone_owner);
  clone.ClearICDataArray();
  clone.ClearCode();
  clone.set_usage_counter(0);
  clone.set_deoptimization_counter(0);
  clone.set_optimized_instruction_count(0);
  clone.set_inlining_depth(0);
  clone.set_optimized_call_site_count(0);
  clone.set_kernel_offset(kernel_offset());
  clone.set_kernel_data(TypedData::Handle(zone, kernel_data()));

  if (new_owner.NumTypeParameters() > 0) {
    // Adjust uninstantiated types to refer to type parameters of the new owner.
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, type_parameters());
    if (!type_params.IsNull()) {
      const intptr_t num_type_params = type_params.Length();
      const TypeArguments& type_params_clone =
          TypeArguments::Handle(zone, TypeArguments::New(num_type_params));
      TypeParameter& type_param = TypeParameter::Handle(zone);
      for (intptr_t i = 0; i < num_type_params; i++) {
        type_param ^= type_params.TypeAt(i);
        type_param ^= type_param.CloneUninstantiated(new_owner);
        type_params_clone.SetTypeAt(i, type_param);
      }
      clone.set_type_parameters(type_params_clone);
    }
    AbstractType& type = AbstractType::Handle(zone, clone.result_type());
    type ^= type.CloneUninstantiated(new_owner);
    clone.set_result_type(type);
    const intptr_t num_params = clone.NumParameters();
    Array& array = Array::Handle(zone, clone.parameter_types());
    array ^= Object::Clone(array, Heap::kOld);
    clone.set_parameter_types(array);
    for (intptr_t i = 0; i < num_params; i++) {
      type = clone.ParameterTypeAt(i);
      type ^= type.CloneUninstantiated(new_owner);
      clone.SetParameterTypeAt(i, type);
    }
  }
  return clone.raw();
}

RawFunction* Function::NewClosureFunctionWithKind(RawFunction::Kind kind,
                                                  const String& name,
                                                  const Function& parent,
                                                  TokenPosition token_pos) {
  ASSERT((kind == RawFunction::kClosureFunction) ||
         (kind == RawFunction::kImplicitClosureFunction) ||
         (kind == RawFunction::kConvertedClosureFunction));
  ASSERT(!parent.IsNull());
  // Only static top-level functions are allowed to be converted right now.
  ASSERT((kind != RawFunction::kConvertedClosureFunction) ||
         parent.is_static());
  // Use the owner defining the parent function and not the class containing it.
  const Object& parent_owner = Object::Handle(parent.raw_ptr()->owner_);
  ASSERT(!parent_owner.IsNull());
  const Function& result = Function::Handle(
      Function::New(name, kind,
                    /* is_static = */ parent.is_static(),
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    /* is_external = */ false,
                    /* is_native = */ false, parent_owner, token_pos));
  result.set_parent_function(parent);
  return result.raw();
}

RawFunction* Function::NewClosureFunction(const String& name,
                                          const Function& parent,
                                          TokenPosition token_pos) {
  return NewClosureFunctionWithKind(RawFunction::kClosureFunction, name, parent,
                                    token_pos);
}

RawFunction* Function::NewImplicitClosureFunction(const String& name,
                                                  const Function& parent,
                                                  TokenPosition token_pos) {
  return NewClosureFunctionWithKind(RawFunction::kImplicitClosureFunction, name,
                                    parent, token_pos);
}

RawFunction* Function::NewConvertedClosureFunction(const String& name,
                                                   const Function& parent,
                                                   TokenPosition token_pos) {
  return NewClosureFunctionWithKind(RawFunction::kConvertedClosureFunction,
                                    name, parent, token_pos);
}

RawFunction* Function::NewSignatureFunction(const Object& owner,
                                            const Function& parent,
                                            TokenPosition token_pos,
                                            Heap::Space space) {
  const Function& result = Function::Handle(Function::New(
      Symbols::AnonymousSignature(), RawFunction::kSignatureFunction,
      /* is_static = */ false,
      /* is_const = */ false,
      /* is_abstract = */ false,
      /* is_external = */ false,
      /* is_native = */ false,
      owner,  // Same as function type scope class.
      token_pos, space));
  result.set_parent_function(parent);
  result.set_is_reflectable(false);
  result.set_is_visible(false);
  result.set_is_debuggable(false);
  return result.raw();
}

RawFunction* Function::NewEvalFunction(const Class& owner,
                                       const Script& script,
                                       bool is_static) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Function& result = Function::Handle(
      zone,
      Function::New(String::Handle(Symbols::New(thread, ":Eval")),
                    RawFunction::kRegularFunction, is_static,
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    /* is_external = */ false,
                    /* is_native = */ false, owner, TokenPosition::kMinSource));
  ASSERT(!script.IsNull());
  result.set_is_debuggable(false);
  result.set_is_visible(true);
  result.set_eval_script(script);
  return result.raw();
}

RawFunction* Function::ImplicitClosureFunction() const {
  // Return the existing implicit closure function if any.
  if (implicit_closure_function() != Function::null()) {
    return implicit_closure_function();
  }
  ASSERT(!IsSignatureFunction() && !IsClosureFunction());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // Create closure function.
  const String& closure_name = String::Handle(zone, name());
  const Function& closure_function = Function::Handle(
      zone, NewImplicitClosureFunction(closure_name, *this, token_pos()));

  // Set closure function's context scope.
  if (is_static()) {
    closure_function.set_context_scope(Object::empty_context_scope());
  } else {
    const ContextScope& context_scope = ContextScope::Handle(
        zone, LocalScope::CreateImplicitClosureScope(*this));
    closure_function.set_context_scope(context_scope);
  }

  // Set closure function's type parameters.
  closure_function.set_type_parameters(
      TypeArguments::Handle(zone, type_parameters()));

  // Set closure function's result type to this result type.
  closure_function.set_result_type(AbstractType::Handle(zone, result_type()));

  // Set closure function's end token to this end token.
  closure_function.set_end_token_pos(end_token_pos());

  // The closurized method stub just calls into the original method and should
  // therefore be skipped by the debugger and in stack traces.
  closure_function.set_is_debuggable(false);
  closure_function.set_is_visible(false);

  // Set closure function's formal parameters to this formal parameters,
  // removing the receiver if this is an instance method and adding the closure
  // object as first parameter.
  const int kClosure = 1;
  const int has_receiver = is_static() ? 0 : 1;
  const int num_fixed_params = kClosure - has_receiver + num_fixed_parameters();
  const int num_opt_params = NumOptionalParameters();
  const bool has_opt_pos_params = HasOptionalPositionalParameters();
  const int num_params = num_fixed_params + num_opt_params;
  closure_function.set_num_fixed_parameters(num_fixed_params);
  closure_function.SetNumOptionalParameters(num_opt_params, has_opt_pos_params);
  closure_function.set_parameter_types(
      Array::Handle(zone, Array::New(num_params, Heap::kOld)));
  closure_function.set_parameter_names(
      Array::Handle(zone, Array::New(num_params, Heap::kOld)));
  AbstractType& param_type = AbstractType::Handle(zone);
  String& param_name = String::Handle(zone);
  // Add implicit closure object parameter.
  param_type = Type::DynamicType();
  closure_function.SetParameterTypeAt(0, param_type);
  closure_function.SetParameterNameAt(0, Symbols::ClosureParameter());
  for (int i = kClosure; i < num_params; i++) {
    param_type = ParameterTypeAt(has_receiver - kClosure + i);
    closure_function.SetParameterTypeAt(i, param_type);
    param_name = ParameterNameAt(has_receiver - kClosure + i);
    closure_function.SetParameterNameAt(i, param_name);
  }
  closure_function.set_kernel_offset(kernel_offset());
  closure_function.set_kernel_data(TypedData::Handle(zone, kernel_data()));

  const Type& signature_type =
      Type::Handle(zone, closure_function.SignatureType());
  if (!signature_type.IsFinalized()) {
    ClassFinalizer::FinalizeType(Class::Handle(zone, Owner()), signature_type);
  }
  set_implicit_closure_function(closure_function);
  ASSERT(closure_function.IsImplicitClosureFunction());
  return closure_function.raw();
}

void Function::DropUncompiledImplicitClosureFunction() const {
  if (implicit_closure_function() != Function::null()) {
    const Function& func = Function::Handle(implicit_closure_function());
    if (!func.HasCode()) {
      set_implicit_closure_function(Function::Handle());
    }
  }
}

// Converted closure functions represent a pair of a top-level function and a
// vector of captured variables.  When being invoked, converted closure
// functions get the vector as the first argument, and the arguments supplied at
// the invocation are passed as the remaining arguments to that function.
//
// Consider the following example in Kernel:
//
//   static method foo(core::int start) → core::Function {
//     core::int i = 0;
//     return () → dynamic => start.+(
//       let final dynamic #t1 = i in
//         let final dynamic #t2 = i = #t1.+(1) in
//          #t1
//     );
//   }
//
// The method [foo] above produces a closure as a result.  The closure captures
// two variables: function parameter [start] and local variable [i].  Here is
// how this code would look like after closure conversion:
//
//   static method foo(core::int start) → core::Function {
//     final Vector #context = MakeVector(3);
//     #context[1] = start;
//     #context[2] = 0;
//     return MakeClosure<() → dynamic>(com::closure#foo#function, #context);
//   }
//   static method closure#foo#function(Vector #contextParameter) → dynamic {
//     return (#contextParameter[1]).+(
//       let final dynamic #t1 = #contextParameter[2] in
//         let final dynamic #t2 = #contextParameter[2] = #t1.+(1) in
//           #t1
//     );
//   }
//
// Converted closure functions are used in VM Closure instances that represent
// the results of evaluation of [MakeClosure] primitive operations.
//
// Internally, converted closure functions are represented with the same Closure
// class as implicit closure functions (that are used for dealing with
// tear-offs).  The Closure class instances have two fields, one for the
// function, and one for the captured context.  Implicit closure functions have
// pre-defined shape of the context: it's a single variable that is used as
// 'this'.  Converted closure functions use the context field to store the
// vector of captured variables that will be supplied as the first argument
// during invocation.
//
// The top-level functions used in converted closure functions are generated
// during a front-end transformation in Kernel.  Those functions have some
// common properties:
//   * they expect the captured context to be passed as the first argument,
//   * the first argument should be of [Vector] type (index-based storage),
//   * they retrieve the captured variables from [Vector] explicitly, so they
//   don't need the variables from the context to be put into their current
//   scope.
//
// During closure-conversion pass in Kernel, the contexts are generated
// explicitly and are represented as [Vector]s.  Then they are paired together
// with the top-level functions to form a closure.  When the closure, created
// this way, is invoked, it should receive the [Vector] as the first argument,
// and take the rest of the arguments from the invocation.
//
// Converted closure functions in VM follow same discipline as implicit closure
// functions, because they are similar in many ways. For further deatils, please
// refer to the following methods:
//   -> Function::ConvertedClosureFunction
//   -> StreamingFlowGraphBuilder::BuildGraphOfConvertedClosureFunction
//   -> StreamingFlowGraphBuilder::BuildGraph (small change that calls
//      BuildGraphOfConvertedClosureFunction)
//   -> StreamingFlowGraphBuilder::BuildClosureCreation (converted closure
//      functions are created here)
//
// Function::ConvertedClosureFunction method follows the logic of
// Function::ImplicitClosureFunction method.
//
// TODO(29181): Adjust the method to correctly pass type parameters after they
// are enabled in closure conversion.
RawFunction* Function::ConvertedClosureFunction() const {
  // Return the existing converted closure function if any.
  if (converted_closure_function() != Function::null()) {
    return converted_closure_function();
  }
  ASSERT(!IsSignatureFunction() && !IsClosureFunction());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // Create closure function.
  const String& closure_name = String::Handle(zone, name());
  const Function& closure_function = Function::Handle(
      zone, NewConvertedClosureFunction(closure_name, *this, token_pos()));

  // Currently only static top-level functions are allowed to be converted.
  ASSERT(is_static());
  closure_function.set_context_scope(Object::empty_context_scope());

  // Set closure function's type parameters.
  closure_function.set_type_parameters(
      TypeArguments::Handle(zone, type_parameters()));

  // Set closure function's result type to this result type.
  closure_function.set_result_type(AbstractType::Handle(zone, result_type()));

  // Set closure function's end token to this end token.
  closure_function.set_end_token_pos(end_token_pos());

  // Set closure function's formal parameters to this formal parameters,
  // removing the first parameter over which the currying is done, and adding
  // the closure class instance as the first parameter.  So, the overall number
  // of fixed parameters doesn't change.
  const int num_fixed_params = num_fixed_parameters();
  const int num_opt_params = NumOptionalParameters();
  const bool has_opt_pos_params = HasOptionalPositionalParameters();
  const int num_params = num_fixed_params + num_opt_params;

  closure_function.set_num_fixed_parameters(num_fixed_params);
  closure_function.SetNumOptionalParameters(num_opt_params, has_opt_pos_params);
  closure_function.set_parameter_types(
      Array::Handle(zone, Array::New(num_params, Heap::kOld)));
  closure_function.set_parameter_names(
      Array::Handle(zone, Array::New(num_params, Heap::kOld)));

  AbstractType& param_type = AbstractType::Handle(zone);
  String& param_name = String::Handle(zone);

  // Add implicit closure object as the first parameter.
  param_type = Type::DynamicType();
  closure_function.SetParameterTypeAt(0, param_type);
  closure_function.SetParameterNameAt(0, Symbols::ClosureParameter());

  // All the parameters, but the first one, are the same for the top-level
  // function being converted, and the method of the closure class that is being
  // generated.
  for (int i = 1; i < num_params; i++) {
    param_type = ParameterTypeAt(i);
    closure_function.SetParameterTypeAt(i, param_type);
    param_name = ParameterNameAt(i);
    closure_function.SetParameterNameAt(i, param_name);
  }
  closure_function.set_kernel_offset(kernel_offset());
  closure_function.set_kernel_data(TypedData::Handle(zone, kernel_data()));

  const Type& signature_type =
      Type::Handle(zone, closure_function.SignatureType());
  if (!signature_type.IsFinalized()) {
    ClassFinalizer::FinalizeType(Class::Handle(zone, Owner()), signature_type);
  }

  set_converted_closure_function(closure_function);

  return closure_function.raw();
}

void Function::DropUncompiledConvertedClosureFunction() const {
  if (converted_closure_function() != Function::null()) {
    const Function& func = Function::Handle(converted_closure_function());
    if (!func.HasCode()) {
      set_converted_closure_function(Function::Handle());
    }
  }
}

RawString* Function::UserVisibleFormalParameters() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // Typically 3, 5,.. elements in 'pieces', e.g.:
  // '_LoadRequest', CommaSpace, '_LoadError'.
  GrowableHandlePtrArray<const String> pieces(zone, 5);
  BuildSignatureParameters(thread, zone, kUserVisibleName, &pieces);
  return Symbols::FromConcatAll(thread, pieces);
}

void Function::BuildSignatureParameters(
    Thread* thread,
    Zone* zone,
    NameVisibility name_visibility,
    GrowableHandlePtrArray<const String>* pieces) const {
  AbstractType& param_type = AbstractType::Handle(zone);
  const intptr_t num_params = NumParameters();
  const intptr_t num_fixed_params = num_fixed_parameters();
  const intptr_t num_opt_pos_params = NumOptionalPositionalParameters();
  const intptr_t num_opt_named_params = NumOptionalNamedParameters();
  const intptr_t num_opt_params = num_opt_pos_params + num_opt_named_params;
  ASSERT((num_fixed_params + num_opt_params) == num_params);
  intptr_t i = 0;
  if (name_visibility == kUserVisibleName) {
    // Hide implicit parameters.
    i = NumImplicitParameters();
  }
  String& name = String::Handle(zone);
  while (i < num_fixed_params) {
    param_type = ParameterTypeAt(i);
    ASSERT(!param_type.IsNull());
    name = param_type.BuildName(name_visibility);
    pieces->Add(name);
    if (i != (num_params - 1)) {
      pieces->Add(Symbols::CommaSpace());
    }
    i++;
  }
  if (num_opt_params > 0) {
    if (num_opt_pos_params > 0) {
      pieces->Add(Symbols::LBracket());
    } else {
      pieces->Add(Symbols::LBrace());
    }
    for (intptr_t i = num_fixed_params; i < num_params; i++) {
      param_type = ParameterTypeAt(i);
      ASSERT(!param_type.IsNull());
      name = param_type.BuildName(name_visibility);
      pieces->Add(name);
      // The parameter name of an optional positional parameter does not need
      // to be part of the signature, since it is not used.
      if (num_opt_named_params > 0) {
        name = ParameterNameAt(i);
        pieces->Add(Symbols::Blank());
        pieces->Add(name);
      }
      if (i != (num_params - 1)) {
        pieces->Add(Symbols::CommaSpace());
      }
    }
    if (num_opt_pos_params > 0) {
      pieces->Add(Symbols::RBracket());
    } else {
      pieces->Add(Symbols::RBrace());
    }
  }
}

RawInstance* Function::ImplicitStaticClosure() const {
  ASSERT(IsImplicitStaticClosureFunction());
  if (implicit_static_closure() == Instance::null()) {
    Zone* zone = Thread::Current()->zone();
    const Context& context = Object::empty_context();
    TypeArguments& function_type_arguments = TypeArguments::Handle(zone);
    if (!HasInstantiatedSignature(kFunctions)) {
      function_type_arguments = Object::empty_type_arguments().raw();
    }
    Instance& closure =
        Instance::Handle(zone, Closure::New(Object::null_type_arguments(),
                                            function_type_arguments, *this,
                                            context, Heap::kOld));
    set_implicit_static_closure(closure);
  }
  return implicit_static_closure();
}

RawInstance* Function::ImplicitInstanceClosure(const Instance& receiver) const {
  ASSERT(IsImplicitClosureFunction());
  Zone* zone = Thread::Current()->zone();
  const Context& context = Context::Handle(zone, Context::New(1));
  context.SetAt(0, receiver);
  TypeArguments& instantiator_type_arguments = TypeArguments::Handle(zone);
  TypeArguments& function_type_arguments = TypeArguments::Handle(zone);
  if (!HasInstantiatedSignature(kCurrentClass)) {
    instantiator_type_arguments = receiver.GetTypeArguments();
  }
  if (!HasInstantiatedSignature(kFunctions)) {
    function_type_arguments = Object::empty_type_arguments().raw();
  }
  return Closure::New(instantiator_type_arguments, function_type_arguments,
                      *this, context);
}

intptr_t Function::ComputeClosureHash() const {
  ASSERT(IsClosureFunction());
  const Class& cls = Class::Handle(Owner());
  intptr_t result = String::Handle(name()).Hash();
  result += String::Handle(Signature()).Hash();
  result += String::Handle(cls.Name()).Hash();
  return result;
}

RawString* Function::BuildSignature(NameVisibility name_visibility) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, 4);
  String& name = String::Handle(zone);
  if (FLAG_reify_generic_functions) {
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, type_parameters());
    if (!type_params.IsNull()) {
      const intptr_t num_type_params = type_params.Length();
      ASSERT(num_type_params > 0);
      TypeParameter& type_param = TypeParameter::Handle(zone);
      AbstractType& bound = AbstractType::Handle(zone);
      pieces.Add(Symbols::LAngleBracket());
      for (intptr_t i = 0; i < num_type_params; i++) {
        type_param ^= type_params.TypeAt(i);
        name = type_param.name();
        pieces.Add(name);
        bound = type_param.bound();
        if (!bound.IsNull() && !bound.IsObjectType()) {
          pieces.Add(Symbols::SpaceExtendsSpace());
          name = bound.BuildName(name_visibility);
          pieces.Add(name);
        }
        if (i < num_type_params - 1) {
          pieces.Add(Symbols::CommaSpace());
        }
      }
      pieces.Add(Symbols::RAngleBracket());
    }
  }
  pieces.Add(Symbols::LParen());
  BuildSignatureParameters(thread, zone, name_visibility, &pieces);
  pieces.Add(Symbols::RParenArrow());
  const AbstractType& res_type = AbstractType::Handle(zone, result_type());
  name = res_type.BuildName(name_visibility);
  pieces.Add(name);
  return Symbols::FromConcatAll(thread, pieces);
}

bool Function::HasInstantiatedSignature(Genericity genericity,
                                        intptr_t num_free_fun_type_params,
                                        TrailPtr trail) const {
  // This function works differently for converted closures.
  //
  // Unlike regular closures, it's not possible to know which type parameters
  // are supposed to come from parent functions or classes and which are
  // actually parameters to the closure it represents. For example, consider:
  //
  //     class C<T> {
  //       getf() => (T x) { return x; }
  //     }
  //
  //     class D {
  //       getf() {
  //         dynamic fn<T>(T x) { return x; }
  //         return fn;
  //       }
  //     }
  //
  // The signature of `fn` as a converted closure will in both cases look like
  // `<T>(T) => dynamic`, because the signaute of the converted closure function
  // is the same as it's top-level target function. However, in the first case
  // the closure's type is instantiated, and in the second case it's not.
  //
  // Since we can never assume a converted closure is instantiated if it has any
  // type parameters, we always return true in these cases.
  if (IsConvertedClosureFunction()) {
    return genericity == kCurrentClass || NumTypeParameters() == 0;
  }

  if (genericity != kCurrentClass) {
    // A generic typedef may declare a non-generic function type and get
    // instantiated with unrelated function type parameters. In that case, its
    // signature is still uninstantiated, because these type parameters are
    // free (they are not declared by the typedef).
    // For that reason, we only adjust num_free_fun_type_params if this
    // signature is generic or has a generic parent.
    if (IsGeneric() || HasGenericParent()) {
      // We only consider the function type parameters declared by the parents
      // of this signature function as free.
      const int num_parent_type_params = NumParentTypeParameters();
      if (num_parent_type_params < num_free_fun_type_params) {
        num_free_fun_type_params = num_parent_type_params;
      }
    }
    // TODO(regis): Should we check the owners of the function type parameters
    // in addition to their indexes to decide if they are free or not?
  }
  AbstractType& type = AbstractType::Handle(result_type());
  if (!type.IsInstantiated(genericity, num_free_fun_type_params, trail)) {
    return false;
  }
  const intptr_t num_parameters = NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = ParameterTypeAt(i);
    if (!type.IsInstantiated(genericity, num_free_fun_type_params, trail)) {
      return false;
    }
  }
  return true;
}

RawClass* Function::Owner() const {
  if (raw_ptr()->owner_ == Object::null()) {
    ASSERT(IsSignatureFunction());
    return Class::null();
  }
  if (raw_ptr()->owner_->IsClass()) {
    return Class::RawCast(raw_ptr()->owner_);
  }
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).patched_class();
}

RawClass* Function::origin() const {
  if (raw_ptr()->owner_ == Object::null()) {
    ASSERT(IsSignatureFunction());
    return Class::null();
  }
  if (raw_ptr()->owner_->IsClass()) {
    return Class::RawCast(raw_ptr()->owner_);
  }
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).origin_class();
}

RawScript* Function::script() const {
  // NOTE(turnidge): If you update this function, you probably want to
  // update Class::PatchFieldsAndFunctions() at the same time.
  if (token_pos() == TokenPosition::kMinSource) {
    // Testing for position 0 is an optimization that relies on temporary
    // eval functions having token position 0.
    const Script& script = Script::Handle(eval_script());
    if (!script.IsNull()) {
      return script.raw();
    }
  }
  if (IsClosureFunction() || IsConvertedClosureFunction()) {
    return Function::Handle(parent_function()).script();
  }
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsNull()) {
    ASSERT(IsSignatureFunction());
    return Script::null();
  }
  if (obj.IsClass()) {
    return Class::Cast(obj).script();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).script();
}

bool Function::HasOptimizedCode() const {
  return HasCode() && Code::Handle(CurrentCode()).is_optimized();
}

RawString* Function::UserVisibleName() const {
  if (FLAG_show_internal_names) {
    return name();
  }
  return String::ScrubName(String::Handle(name()));
}

RawString* Function::QualifiedName(NameVisibility name_visibility) const {
  ASSERT(name_visibility != kInternalName);  // We never request it.
  // If |this| is the generated asynchronous body closure, use the
  // name of the parent function.
  Function& fun = Function::Handle(raw());
  if (fun.IsClosureFunction()) {
    // Sniff the parent function.
    fun = fun.parent_function();
    ASSERT(!fun.IsNull());
    if (!fun.IsAsyncGenerator() && !fun.IsAsyncFunction() &&
        !fun.IsSyncGenerator()) {
      // Parent function is not the generator of an asynchronous body closure,
      // start at |this|.
      fun = raw();
    }
  }
  // A function's scrubbed name and its user visible name are identical.
  String& result = String::Handle(fun.UserVisibleName());
  if (IsClosureFunction()) {
    while (fun.IsLocalFunction() && !fun.IsImplicitClosureFunction()) {
      fun = fun.parent_function();
      if (fun.IsAsyncClosure() || fun.IsSyncGenClosure() ||
          fun.IsAsyncGenClosure()) {
        // Skip the closure and use the real function name found in
        // the parent.
        fun = fun.parent_function();
      }
      result = String::Concat(Symbols::Dot(), result, Heap::kOld);
      result = String::Concat(String::Handle(fun.UserVisibleName()), result,
                              Heap::kOld);
    }
  }
  const Class& cls = Class::Handle(Owner());
  if (!cls.IsTopLevel()) {
    if (fun.kind() == RawFunction::kConstructor) {
      result = String::Concat(Symbols::ConstructorStacktracePrefix(), result,
                              Heap::kOld);
    } else {
      result = String::Concat(Symbols::Dot(), result, Heap::kOld);
      const String& cls_name = String::Handle(name_visibility == kScrubbedName
                                                  ? cls.ScrubbedName()
                                                  : cls.UserVisibleName());
      result = String::Concat(cls_name, result, Heap::kOld);
    }
  }
  return result.raw();
}

RawString* Function::GetSource() const {
  if (IsImplicitConstructor() || IsSignatureFunction()) {
    // We may need to handle more cases when the restrictions on mixins are
    // relaxed. In particular we might start associating some source with the
    // forwarding constructors when it becomes possible to specify a particular
    // constructor from the mixin to use.
    return String::null();
  }
  Zone* zone = Thread::Current()->zone();
  const Script& func_script = Script::Handle(zone, script());
  const TokenStream& stream = TokenStream::Handle(zone, func_script.tokens());
  if (!func_script.HasSource()) {
    // When source is not available, avoid printing the whole token stream and
    // doing expensive position calculations.
    return stream.GenerateSource(token_pos(), end_token_pos().Next());
  }

  const TokenStream::Iterator tkit(zone, stream, end_token_pos());
  intptr_t from_line;
  intptr_t from_col;
  intptr_t to_line;
  intptr_t to_col;
  func_script.GetTokenLocation(token_pos(), &from_line, &from_col);
  func_script.GetTokenLocation(end_token_pos(), &to_line, &to_col);
  intptr_t last_tok_len = String::Handle(tkit.CurrentLiteral()).Length();
  // Handle special cases for end tokens of closures (where we exclude the last
  // token):
  // (1) "foo(() => null, bar);": End token is `,', but we don't print it.
  // (2) "foo(() => null);": End token is ')`, but we don't print it.
  // (3) "var foo = () => null;": End token is `;', but in this case the token
  // semicolon belongs to the assignment so we skip it.
  if ((tkit.CurrentTokenKind() == Token::kCOMMA) ||   // Case 1.
      (tkit.CurrentTokenKind() == Token::kRPAREN) ||  // Case 2.
      (tkit.CurrentTokenKind() == Token::kSEMICOLON &&
       String::Handle(zone, name()).Equals("<anonymous closure>"))) {  // Cas 3.
    last_tok_len = 0;
  }
  const String& result =
      String::Handle(zone, func_script.GetSnippet(from_line, from_col, to_line,
                                                  to_col + last_tok_len));
  ASSERT(!result.IsNull());
  return result.raw();
}

// Construct fingerprint from token stream. The token stream contains also
// arguments.
int32_t Function::SourceFingerprint() const {
  return Script::Handle(script()).SourceFingerprint(token_pos(),
                                                    end_token_pos());
}

void Function::SaveICDataMap(
    const ZoneGrowableArray<const ICData*>& deopt_id_to_ic_data,
    const Array& edge_counters_array) const {
  // Compute number of ICData objects to save.
  // Store edge counter array in the first slot.
  intptr_t count = 1;
  for (intptr_t i = 0; i < deopt_id_to_ic_data.length(); i++) {
    if (deopt_id_to_ic_data[i] != NULL) {
      count++;
    }
  }
  const Array& array = Array::Handle(Array::New(count, Heap::kOld));
  INC_STAT(Thread::Current(), total_code_size, count * sizeof(uword));
  count = 1;
  for (intptr_t i = 0; i < deopt_id_to_ic_data.length(); i++) {
    if (deopt_id_to_ic_data[i] != NULL) {
      array.SetAt(count++, *deopt_id_to_ic_data[i]);
    }
  }
  array.SetAt(0, edge_counters_array);
  set_ic_data_array(array);
}

void Function::RestoreICDataMap(
    ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data,
    bool clone_ic_data) const {
  if (FLAG_force_clone_compiler_objects) {
    clone_ic_data = true;
  }
  ASSERT(deopt_id_to_ic_data->is_empty());
  Zone* zone = Thread::Current()->zone();
  const Array& saved_ic_data = Array::Handle(zone, ic_data_array());
  if (saved_ic_data.IsNull()) {
    // Could happen with deferred loading.
    return;
  }
  const intptr_t saved_length = saved_ic_data.Length();
  ASSERT(saved_length > 0);
  if (saved_length > 1) {
    const intptr_t restored_length =
        ICData::Cast(Object::Handle(zone, saved_ic_data.At(saved_length - 1)))
            .deopt_id() +
        1;
    deopt_id_to_ic_data->SetLength(restored_length);
    for (intptr_t i = 0; i < restored_length; i++) {
      (*deopt_id_to_ic_data)[i] = NULL;
    }
    for (intptr_t i = 1; i < saved_length; i++) {
      ICData& ic_data = ICData::ZoneHandle(zone);
      ic_data ^= saved_ic_data.At(i);
      if (clone_ic_data) {
        const ICData& original_ic_data = ICData::Handle(zone, ic_data.raw());
        ic_data = ICData::Clone(ic_data);
        ic_data.SetOriginal(original_ic_data);
      }
      (*deopt_id_to_ic_data)[ic_data.deopt_id()] = &ic_data;
    }
  }
}

void Function::set_ic_data_array(const Array& value) const {
  StorePointer(&raw_ptr()->ic_data_array_, value.raw());
}

RawArray* Function::ic_data_array() const {
  return raw_ptr()->ic_data_array_;
}

void Function::ClearICDataArray() const {
  set_ic_data_array(Array::null_array());
}

void Function::SetDeoptReasonForAll(intptr_t deopt_id,
                                    ICData::DeoptReasonId reason) {
  const Array& array = Array::Handle(ic_data_array());
  ICData& ic_data = ICData::Handle();
  for (intptr_t i = 1; i < array.Length(); i++) {
    ic_data ^= array.At(i);
    if (ic_data.deopt_id() == deopt_id) {
      ic_data.AddDeoptReason(reason);
    }
  }
}

bool Function::CheckSourceFingerprint(const char* prefix, int32_t fp) const {
  if (!Isolate::Current()->obfuscate() && (kernel_offset() <= 0) &&
      (SourceFingerprint() != fp)) {
    const bool recalculatingFingerprints = false;
    if (recalculatingFingerprints) {
      // This output can be copied into a file, then used with sed
      // to replace the old values.
      // sed -i.bak -f /tmp/newkeys runtime/vm/method_recognizer.h
      THR_Print("s/0x%08x/0x%08x/\n", fp, SourceFingerprint());
    } else {
      THR_Print(
          "FP mismatch while recognizing method %s:"
          " expecting 0x%08x found 0x%08x\n",
          ToFullyQualifiedCString(), fp, SourceFingerprint());
      return false;
    }
  }
  return true;
}

RawCode* Function::EnsureHasCode() const {
  if (HasCode()) return CurrentCode();
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Object& result =
      Object::Handle(zone, Compiler::CompileFunction(thread, *this));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }
  // Compiling in unoptimized mode should never fail if there are no errors.
  ASSERT(HasCode());
  ASSERT(unoptimized_code() == result.raw());
  return CurrentCode();
}

const char* Function::ToCString() const {
  if (IsNull()) {
    return "Function: null";
  }
  const char* static_str = is_static() ? " static" : "";
  const char* abstract_str = is_abstract() ? " abstract" : "";
  const char* kind_str = NULL;
  const char* const_str = is_const() ? " const" : "";
  switch (kind()) {
    case RawFunction::kRegularFunction:
    case RawFunction::kClosureFunction:
    case RawFunction::kImplicitClosureFunction:
    case RawFunction::kConvertedClosureFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
      kind_str = "";
      break;
    case RawFunction::kSignatureFunction:
      kind_str = " signature";
      break;
    case RawFunction::kConstructor:
      kind_str = is_static() ? " factory" : " constructor";
      break;
    case RawFunction::kImplicitGetter:
      kind_str = " getter";
      break;
    case RawFunction::kImplicitSetter:
      kind_str = " setter";
      break;
    case RawFunction::kImplicitStaticFinalGetter:
      kind_str = " static-final-getter";
      break;
    case RawFunction::kMethodExtractor:
      kind_str = " method-extractor";
      break;
    case RawFunction::kNoSuchMethodDispatcher:
      kind_str = " no-such-method-dispatcher";
      break;
    case RawFunction::kInvokeFieldDispatcher:
      kind_str = "invoke-field-dispatcher";
      break;
    case RawFunction::kIrregexpFunction:
      kind_str = "irregexp-function";
      break;
    default:
      UNREACHABLE();
  }
  const char* function_name = String::Handle(name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(), "Function '%s':%s%s%s%s.",
                     function_name, static_str, abstract_str, kind_str,
                     const_str);
}

void ClosureData::set_context_scope(const ContextScope& value) const {
  StorePointer(&raw_ptr()->context_scope_, value.raw());
}

void ClosureData::set_implicit_static_closure(const Instance& closure) const {
  ASSERT(!closure.IsNull());
  ASSERT(raw_ptr()->closure_ == Instance::null());
  StorePointer(&raw_ptr()->closure_, closure.raw());
}

void ClosureData::set_parent_function(const Function& value) const {
  StorePointer(&raw_ptr()->parent_function_, value.raw());
}

void ClosureData::set_signature_type(const Type& value) const {
  StorePointer(&raw_ptr()->signature_type_, value.raw());
}

RawClosureData* ClosureData::New() {
  ASSERT(Object::closure_data_class() != Class::null());
  RawObject* raw = Object::Allocate(ClosureData::kClassId,
                                    ClosureData::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawClosureData*>(raw);
}

const char* ClosureData::ToCString() const {
  if (IsNull()) {
    return "ClosureData: null";
  }
  const Function& parent = Function::Handle(parent_function());
  const Type& type = Type::Handle(signature_type());
  return OS::SCreate(Thread::Current()->zone(),
                     "ClosureData: context_scope: 0x%" Px
                     " parent_function: %s signature_type: %s"
                     " implicit_static_closure: 0x%" Px,
                     reinterpret_cast<uword>(context_scope()),
                     parent.IsNull() ? "null" : parent.ToCString(),
                     type.IsNull() ? "null" : type.ToCString(),
                     reinterpret_cast<uword>(implicit_static_closure()));
}

void SignatureData::set_parent_function(const Function& value) const {
  StorePointer(&raw_ptr()->parent_function_, value.raw());
}

void SignatureData::set_signature_type(const Type& value) const {
  StorePointer(&raw_ptr()->signature_type_, value.raw());
}

RawSignatureData* SignatureData::New(Heap::Space space) {
  ASSERT(Object::signature_data_class() != Class::null());
  RawObject* raw = Object::Allocate(SignatureData::kClassId,
                                    SignatureData::InstanceSize(), space);
  return reinterpret_cast<RawSignatureData*>(raw);
}

const char* SignatureData::ToCString() const {
  if (IsNull()) {
    return "SignatureData: null";
  }
  const Function& parent = Function::Handle(parent_function());
  const Type& type = Type::Handle(signature_type());
  return OS::SCreate(Thread::Current()->zone(),
                     "SignatureData parent_function: %s signature_type: %s",
                     parent.IsNull() ? "null" : parent.ToCString(),
                     type.IsNull() ? "null" : type.ToCString());
}

void RedirectionData::set_type(const Type& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->type_, value.raw());
}

void RedirectionData::set_identifier(const String& value) const {
  StorePointer(&raw_ptr()->identifier_, value.raw());
}

void RedirectionData::set_target(const Function& value) const {
  StorePointer(&raw_ptr()->target_, value.raw());
}

RawRedirectionData* RedirectionData::New() {
  ASSERT(Object::redirection_data_class() != Class::null());
  RawObject* raw = Object::Allocate(
      RedirectionData::kClassId, RedirectionData::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawRedirectionData*>(raw);
}

const char* RedirectionData::ToCString() const {
  if (IsNull()) {
    return "RedirectionData: null";
  }
  const Type& redir_type = Type::Handle(type());
  const String& ident = String::Handle(identifier());
  const Function& target_fun = Function::Handle(target());
  return OS::SCreate(Thread::Current()->zone(),
                     "RedirectionData: type: %s identifier: %s target: %s",
                     redir_type.IsNull() ? "null" : redir_type.ToCString(),
                     ident.IsNull() ? "null" : ident.ToCString(),
                     target_fun.IsNull() ? "null" : target_fun.ToCString());
}

RawField* Field::CloneFromOriginal() const {
  return this->Clone(*this);
}

RawField* Field::Original() const {
  if (IsNull()) {
    return Field::null();
  }
  Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsField()) {
    return Field::RawCast(obj.raw());
  } else {
    return this->raw();
  }
}

void Field::SetOriginal(const Field& value) const {
  ASSERT(value.IsOriginal());
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->owner_, reinterpret_cast<RawObject*>(value.raw()));
}

RawString* Field::GetterName(const String& field_name) {
  return String::Concat(Symbols::GetterPrefix(), field_name);
}

RawString* Field::GetterSymbol(const String& field_name) {
  return Symbols::FromGet(Thread::Current(), field_name);
}

RawString* Field::LookupGetterSymbol(const String& field_name) {
  return Symbols::LookupFromGet(Thread::Current(), field_name);
}

RawString* Field::SetterName(const String& field_name) {
  return String::Concat(Symbols::SetterPrefix(), field_name);
}

RawString* Field::SetterSymbol(const String& field_name) {
  return Symbols::FromSet(Thread::Current(), field_name);
}

RawString* Field::LookupSetterSymbol(const String& field_name) {
  return Symbols::LookupFromSet(Thread::Current(), field_name);
}

RawString* Field::NameFromGetter(const String& getter_name) {
  return Symbols::New(Thread::Current(), getter_name, kGetterPrefixLength,
                      getter_name.Length() - kGetterPrefixLength);
}

RawString* Field::NameFromSetter(const String& setter_name) {
  return Symbols::New(Thread::Current(), setter_name, kSetterPrefixLength,
                      setter_name.Length() - kSetterPrefixLength);
}

bool Field::IsGetterName(const String& function_name) {
  return function_name.StartsWith(Symbols::GetterPrefix());
}

bool Field::IsSetterName(const String& function_name) {
  return function_name.StartsWith(Symbols::SetterPrefix());
}

void Field::set_name(const String& value) const {
  ASSERT(value.IsSymbol());
  ASSERT(IsOriginal());
  StorePointer(&raw_ptr()->name_, value.raw());
}

void Field::set_kernel_data(const TypedData& data) const {
  StorePointer(&raw_ptr()->kernel_data_, data.raw());
}

RawObject* Field::RawOwner() const {
  if (IsOriginal()) {
    return raw_ptr()->owner_;
  } else {
    const Field& field = Field::Handle(Original());
    ASSERT(field.IsOriginal());
    ASSERT(!Object::Handle(field.raw_ptr()->owner_).IsField());
    return field.raw_ptr()->owner_;
  }
}

RawClass* Field::Owner() const {
  const Field& field = Field::Handle(Original());
  ASSERT(field.IsOriginal());
  const Object& obj = Object::Handle(field.raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).patched_class();
}

RawClass* Field::Origin() const {
  const Field& field = Field::Handle(Original());
  ASSERT(field.IsOriginal());
  const Object& obj = Object::Handle(field.raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).origin_class();
}

RawScript* Field::Script() const {
  // NOTE(turnidge): If you update this function, you probably want to
  // update Class::PatchFieldsAndFunctions() at the same time.
  const Field& field = Field::Handle(Original());
  ASSERT(field.IsOriginal());
  const Object& obj = Object::Handle(field.raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).script();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).script();
}

// Called at finalization time
void Field::SetFieldType(const AbstractType& value) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsOriginal());
  ASSERT(!value.IsNull());
  if (value.raw() != type()) {
    StorePointer(&raw_ptr()->type_, value.raw());
  }
}

RawField* Field::New() {
  ASSERT(Object::field_class() != Class::null());
  RawObject* raw =
      Object::Allocate(Field::kClassId, Field::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawField*>(raw);
}

void Field::InitializeNew(const Field& result,
                          const String& name,
                          bool is_static,
                          bool is_final,
                          bool is_const,
                          bool is_reflectable,
                          const Object& owner,
                          TokenPosition token_pos) {
  result.set_name(name);
  result.set_is_static(is_static);
  if (!is_static) {
    result.SetOffset(0);
  }
  result.set_is_final(is_final);
  result.set_is_const(is_const);
  result.set_is_reflectable(is_reflectable);
  result.set_is_double_initialized(false);
  result.set_owner(owner);
  result.set_token_pos(token_pos);
  result.set_has_initializer(false);
  result.set_is_unboxing_candidate(true);
  result.set_kernel_offset(0);
  Isolate* isolate = Isolate::Current();

  // Use field guards if they are enabled and the isolate has never reloaded.
  // TODO(johnmccutchan): The reload case assumes the worst case (everything is
  // dynamic and possibly null). Attempt to relax this later.
#if defined(PRODUCT)
  const bool use_guarded_cid =
      FLAG_precompiled_mode || isolate->use_field_guards();
#else
  const bool use_guarded_cid =
      FLAG_precompiled_mode ||
      (isolate->use_field_guards() && !isolate->HasAttemptedReload());
#endif  // !defined(PRODUCT)
  result.set_guarded_cid(use_guarded_cid ? kIllegalCid : kDynamicCid);
  result.set_is_nullable(use_guarded_cid ? false : true);
  result.set_guarded_list_length_in_object_offset(Field::kUnknownLengthOffset);
  // Presently, we only attempt to remember the list length for final fields.
  if (is_final && use_guarded_cid) {
    result.set_guarded_list_length(Field::kUnknownFixedLength);
  } else {
    result.set_guarded_list_length(Field::kNoFixedLength);
  }
}

RawField* Field::New(const String& name,
                     bool is_static,
                     bool is_final,
                     bool is_const,
                     bool is_reflectable,
                     const Object& owner,
                     const AbstractType& type,
                     TokenPosition token_pos) {
  ASSERT(!owner.IsNull());
  const Field& result = Field::Handle(Field::New());
  InitializeNew(result, name, is_static, is_final, is_const, is_reflectable,
                owner, token_pos);
  result.SetFieldType(type);
  return result.raw();
}

RawField* Field::NewTopLevel(const String& name,
                             bool is_final,
                             bool is_const,
                             const Object& owner,
                             TokenPosition token_pos) {
  ASSERT(!owner.IsNull());
  const Field& result = Field::Handle(Field::New());
  InitializeNew(result, name, true,       /* is_static */
                is_final, is_const, true, /* is_reflectable */
                owner, token_pos);
  return result.raw();
}

RawField* Field::Clone(const Class& new_owner) const {
  Field& clone = Field::Handle();
  clone ^= Object::Clone(*this, Heap::kOld);
  const Class& owner = Class::Handle(this->Owner());
  const PatchClass& clone_owner =
      PatchClass::Handle(PatchClass::New(new_owner, owner));
  clone.set_owner(clone_owner);
  if (!clone.is_static()) {
    clone.SetOffset(0);
  }
  if (new_owner.NumTypeParameters() > 0) {
    // Adjust the field type to refer to type parameters of the new owner.
    AbstractType& type = AbstractType::Handle(clone.type());
    type ^= type.CloneUninstantiated(new_owner);
    clone.SetFieldType(type);
  }
  return clone.raw();
}

RawField* Field::Clone(const Field& original) const {
  if (original.IsNull()) {
    return Field::null();
  }
  ASSERT(original.IsOriginal());
  Field& clone = Field::Handle();
  clone ^= Object::Clone(*this, Heap::kOld);
  clone.SetOriginal(original);
  clone.set_kernel_offset(original.kernel_offset());
  return clone.raw();
}

RawString* Field::InitializingExpression() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const class Script& scr = Script::Handle(zone, Script());
  ASSERT(!scr.IsNull());
  const TokenStream& tkns = TokenStream::Handle(zone, scr.tokens());
  if (tkns.IsNull()) {
    ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
    return String::null();
  }
  TokenStream::Iterator tkit(zone, tkns, token_pos());
  ASSERT(Token::IsIdentifier(tkit.CurrentTokenKind()));
#if defined(DEBUG)
  const String& literal = String::Handle(zone, tkit.CurrentLiteral());
  ASSERT(literal.raw() == name());
#endif
  tkit.Advance();
  if (tkit.CurrentTokenKind() != Token::kASSIGN) {
    return String::null();
  }
  tkit.Advance();
  const TokenPosition start_of_expression = tkit.CurrentPosition();
  while (tkit.CurrentTokenKind() != Token::kSEMICOLON) {
    tkit.Advance();
  }
  const TokenPosition end_of_expression = tkit.CurrentPosition();
  return scr.GetSnippet(start_of_expression, end_of_expression);
}

RawString* Field::UserVisibleName() const {
  if (FLAG_show_internal_names) {
    return name();
  }
  return String::ScrubName(String::Handle(name()));
}

intptr_t Field::guarded_list_length() const {
  return Smi::Value(raw_ptr()->guarded_list_length_);
}

void Field::set_guarded_list_length(intptr_t list_length) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsOriginal());
  StoreSmi(&raw_ptr()->guarded_list_length_, Smi::New(list_length));
}

intptr_t Field::guarded_list_length_in_object_offset() const {
  return raw_ptr()->guarded_list_length_in_object_offset_ + kHeapObjectTag;
}

void Field::set_guarded_list_length_in_object_offset(
    intptr_t list_length_offset) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsOriginal());
  StoreNonPointer(&raw_ptr()->guarded_list_length_in_object_offset_,
                  static_cast<int8_t>(list_length_offset - kHeapObjectTag));
  ASSERT(guarded_list_length_in_object_offset() == list_length_offset);
}

const char* Field::ToCString() const {
  if (IsNull()) {
    return "Field: null";
  }
  const char* kF0 = is_static() ? " static" : "";
  const char* kF1 = is_final() ? " final" : "";
  const char* kF2 = is_const() ? " const" : "";
  const char* field_name = String::Handle(name()).ToCString();
  const Class& cls = Class::Handle(Owner());
  const char* cls_name = String::Handle(cls.Name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(), "Field <%s.%s>:%s%s%s",
                     cls_name, field_name, kF0, kF1, kF2);
}

// Build a closure object that gets (or sets) the contents of a static
// field f and cache the closure in a newly created static field
// named #f (or #f= in case of a setter).
RawInstance* Field::AccessorClosure(bool make_setter) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(is_static());
  const Class& field_owner = Class::Handle(zone, Owner());

  String& closure_name = String::Handle(zone, this->name());
  closure_name = Symbols::FromConcat(thread, Symbols::HashMark(), closure_name);
  if (make_setter) {
    closure_name =
        Symbols::FromConcat(thread, Symbols::HashMark(), closure_name);
  }

  Field& closure_field = Field::Handle(zone);
  closure_field = field_owner.LookupStaticField(closure_name);
  if (!closure_field.IsNull()) {
    ASSERT(closure_field.is_static());
    const Instance& closure =
        Instance::Handle(zone, closure_field.StaticValue());
    ASSERT(!closure.IsNull());
    ASSERT(closure.IsClosure());
    return closure.raw();
  }

  // This is the first time a closure for this field is requested.
  // Create the closure and a new static field in which it is stored.
  const char* field_name = String::Handle(zone, name()).ToCString();
  String& expr_src = String::Handle(zone);
  if (make_setter) {
    expr_src = String::NewFormatted("(%s_) { return %s = %s_; }", field_name,
                                    field_name, field_name);
  } else {
    expr_src = String::NewFormatted("() { return %s; }", field_name);
  }
  Object& result =
      Object::Handle(zone, field_owner.Evaluate(expr_src, Object::empty_array(),
                                                Object::empty_array()));
  ASSERT(result.IsInstance());
  // The caller may expect the closure to be allocated in old space. Copy
  // the result here, since Object::Clone() is a private method.
  result = Object::Clone(result, Heap::kOld);

  closure_field =
      Field::New(closure_name,
                 true,   // is_static
                 true,   // is_final
                 true,   // is_const
                 false,  // is_reflectable
                 field_owner, Object::dynamic_type(), this->token_pos());
  closure_field.SetStaticValue(Instance::Cast(result), true);
  field_owner.AddField(closure_field);

  return Instance::RawCast(result.raw());
}

RawInstance* Field::GetterClosure() const {
  return AccessorClosure(false);
}

RawInstance* Field::SetterClosure() const {
  return AccessorClosure(true);
}

RawArray* Field::dependent_code() const {
  return raw_ptr()->dependent_code_;
}

void Field::set_dependent_code(const Array& array) const {
  ASSERT(IsOriginal());
  StorePointer(&raw_ptr()->dependent_code_, array.raw());
}

class FieldDependentArray : public WeakCodeReferences {
 public:
  explicit FieldDependentArray(const Field& field)
      : WeakCodeReferences(Array::Handle(field.dependent_code())),
        field_(field) {}

  virtual void UpdateArrayTo(const Array& value) {
    field_.set_dependent_code(value);
  }

  virtual void ReportDeoptimization(const Code& code) {
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      Function& function = Function::Handle(code.function());
      THR_Print("Deoptimizing %s because guard on field %s failed.\n",
                function.ToFullyQualifiedCString(), field_.ToCString());
    }
  }

  virtual void ReportSwitchingCode(const Code& code) {
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      Function& function = Function::Handle(code.function());
      THR_Print(
          "Switching '%s' to unoptimized code because guard"
          " on field '%s' was violated.\n",
          function.ToFullyQualifiedCString(), field_.ToCString());
    }
  }

 private:
  const Field& field_;
  DISALLOW_COPY_AND_ASSIGN(FieldDependentArray);
};

void Field::RegisterDependentCode(const Code& code) const {
  ASSERT(IsOriginal());
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  ASSERT(code.is_optimized());
  FieldDependentArray a(*this);
  a.Register(code);
}

void Field::DeoptimizeDependentCode() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsOriginal());
  FieldDependentArray a(*this);
  a.DisableCode();
}

bool Field::IsConsistentWith(const Field& other) const {
  return (raw_ptr()->guarded_cid_ == other.raw_ptr()->guarded_cid_) &&
         (raw_ptr()->is_nullable_ == other.raw_ptr()->is_nullable_) &&
         (raw_ptr()->guarded_list_length_ ==
          other.raw_ptr()->guarded_list_length_) &&
         (is_unboxing_candidate() == other.is_unboxing_candidate());
}

bool Field::IsUninitialized() const {
  const Instance& value = Instance::Handle(raw_ptr()->value_.static_value_);
  ASSERT(value.raw() != Object::transition_sentinel().raw());
  return value.raw() == Object::sentinel().raw();
}

void Field::SetPrecompiledInitializer(const Function& initializer) const {
  ASSERT(IsOriginal());
  StorePointer(&raw_ptr()->initializer_.precompiled_, initializer.raw());
}

bool Field::HasPrecompiledInitializer() const {
  return raw_ptr()->initializer_.precompiled_->IsHeapObject() &&
         raw_ptr()->initializer_.precompiled_->IsFunction();
}

void Field::SetSavedInitialStaticValue(const Instance& value) const {
  ASSERT(IsOriginal());
  ASSERT(!HasPrecompiledInitializer());
  StorePointer(&raw_ptr()->initializer_.saved_value_, value.raw());
}

void Field::EvaluateInitializer() const {
  ASSERT(IsOriginal());
  ASSERT(is_static());
  if (StaticValue() == Object::sentinel().raw()) {
    SetStaticValue(Object::transition_sentinel());
    const Object& value =
        Object::Handle(Compiler::EvaluateStaticInitializer(*this));
    if (value.IsError()) {
      SetStaticValue(Object::null_instance());
      Exceptions::PropagateError(Error::Cast(value));
      UNREACHABLE();
    }
    ASSERT(value.IsNull() || value.IsInstance());
    SetStaticValue(value.IsNull() ? Instance::null_instance()
                                  : Instance::Cast(value));
    return;
  } else if (StaticValue() == Object::transition_sentinel().raw()) {
    const Array& ctor_args = Array::Handle(Array::New(1));
    const String& field_name = String::Handle(name());
    ctor_args.SetAt(0, field_name);
    Exceptions::ThrowByType(Exceptions::kCyclicInitializationError, ctor_args);
    UNREACHABLE();
    return;
  }
  UNREACHABLE();
}

static intptr_t GetListLength(const Object& value) {
  if (value.IsTypedData()) {
    const TypedData& list = TypedData::Cast(value);
    return list.Length();
  } else if (value.IsArray()) {
    const Array& list = Array::Cast(value);
    return list.Length();
  } else if (value.IsGrowableObjectArray()) {
    // List length is variable.
    return Field::kNoFixedLength;
  } else if (value.IsExternalTypedData()) {
    // TODO(johnmccutchan): Enable for external typed data.
    return Field::kNoFixedLength;
  } else if (RawObject::IsTypedDataViewClassId(value.GetClassId())) {
    // TODO(johnmccutchan): Enable for typed data views.
    return Field::kNoFixedLength;
  }
  return Field::kNoFixedLength;
}

static intptr_t GetListLengthOffset(intptr_t cid) {
  if (RawObject::IsTypedDataClassId(cid)) {
    return TypedData::length_offset();
  } else if (cid == kArrayCid || cid == kImmutableArrayCid) {
    return Array::length_offset();
  } else if (cid == kGrowableObjectArrayCid) {
    // List length is variable.
    return Field::kUnknownLengthOffset;
  } else if (RawObject::IsExternalTypedDataClassId(cid)) {
    // TODO(johnmccutchan): Enable for external typed data.
    return Field::kUnknownLengthOffset;
  } else if (RawObject::IsTypedDataViewClassId(cid)) {
    // TODO(johnmccutchan): Enable for typed data views.
    return Field::kUnknownLengthOffset;
  }
  return Field::kUnknownLengthOffset;
}

const char* Field::GuardedPropertiesAsCString() const {
  if (guarded_cid() == kIllegalCid) {
    return "<?>";
  } else if (guarded_cid() == kDynamicCid) {
    return "<*>";
  }

  const Class& cls =
      Class::Handle(Isolate::Current()->class_table()->At(guarded_cid()));
  const char* class_name = String::Handle(cls.Name()).ToCString();

  if (RawObject::IsBuiltinListClassId(guarded_cid()) && !is_nullable() &&
      is_final()) {
    ASSERT(guarded_list_length() != kUnknownFixedLength);
    if (guarded_list_length() == kNoFixedLength) {
      return Thread::Current()->zone()->PrintToString("<%s [*]>", class_name);
    } else {
      return Thread::Current()->zone()->PrintToString(
          "<%s [%" Pd " @%" Pd "]>", class_name, guarded_list_length(),
          guarded_list_length_in_object_offset());
    }
  }

  return Thread::Current()->zone()->PrintToString(
      "<%s %s>", is_nullable() ? "nullable" : "not-nullable", class_name);
}

void Field::InitializeGuardedListLengthInObjectOffset() const {
  ASSERT(IsOriginal());
  if (needs_length_check() &&
      (guarded_list_length() != Field::kUnknownFixedLength)) {
    const intptr_t offset = GetListLengthOffset(guarded_cid());
    set_guarded_list_length_in_object_offset(offset);
    ASSERT(offset != Field::kUnknownLengthOffset);
  } else {
    set_guarded_list_length_in_object_offset(Field::kUnknownLengthOffset);
  }
}

bool Field::UpdateGuardedCidAndLength(const Object& value) const {
  ASSERT(IsOriginal());
  const intptr_t cid = value.GetClassId();

  if (guarded_cid() == kIllegalCid) {
    // Field is assigned first time.
    set_guarded_cid(cid);
    set_is_nullable(cid == kNullCid);

    // Start tracking length if needed.
    ASSERT((guarded_list_length() == Field::kUnknownFixedLength) ||
           (guarded_list_length() == Field::kNoFixedLength));
    if (needs_length_check()) {
      ASSERT(guarded_list_length() == Field::kUnknownFixedLength);
      set_guarded_list_length(GetListLength(value));
      InitializeGuardedListLengthInObjectOffset();
    }

    if (FLAG_trace_field_guards) {
      THR_Print("    => %s\n", GuardedPropertiesAsCString());
    }

    return false;
  }

  if ((cid == guarded_cid()) || ((cid == kNullCid) && is_nullable())) {
    // Class id of the assigned value matches expected class id and nullability.

    // If we are tracking length check if it has matches.
    if (needs_length_check() &&
        (guarded_list_length() != GetListLength(value))) {
      ASSERT(guarded_list_length() != Field::kUnknownFixedLength);
      set_guarded_list_length(Field::kNoFixedLength);
      set_guarded_list_length_in_object_offset(Field::kUnknownLengthOffset);
      return true;
    }

    // Everything matches.
    return false;
  }

  if ((cid == kNullCid) && !is_nullable()) {
    // Assigning null value to a non-nullable field makes it nullable.
    set_is_nullable(true);
  } else if ((cid != kNullCid) && (guarded_cid() == kNullCid)) {
    // Assigning non-null value to a field that previously contained only null
    // turns it into a nullable field with the given class id.
    ASSERT(is_nullable());
    set_guarded_cid(cid);
  } else {
    // Give up on tracking class id of values contained in this field.
    ASSERT(guarded_cid() != cid);
    set_guarded_cid(kDynamicCid);
    set_is_nullable(true);
  }

  // If we were tracking length drop collected feedback.
  if (needs_length_check()) {
    ASSERT(guarded_list_length() != Field::kUnknownFixedLength);
    set_guarded_list_length(Field::kNoFixedLength);
    set_guarded_list_length_in_object_offset(Field::kUnknownLengthOffset);
  }

  // Expected class id or nullability of the field changed.
  return true;
}

void Field::RecordStore(const Object& value) const {
  ASSERT(IsOriginal());
  if (!Isolate::Current()->use_field_guards()) {
    return;
  }

  if (FLAG_trace_field_guards) {
    THR_Print("Store %s %s <- %s\n", ToCString(), GuardedPropertiesAsCString(),
              value.ToCString());
  }

  if (UpdateGuardedCidAndLength(value)) {
    if (FLAG_trace_field_guards) {
      THR_Print("    => %s\n", GuardedPropertiesAsCString());
    }

    DeoptimizeDependentCode();
  }
}

void Field::ForceDynamicGuardedCidAndLength() const {
  // Assume nothing about this field.
  set_is_unboxing_candidate(false);
  set_guarded_cid(kDynamicCid);
  set_is_nullable(true);
  set_guarded_list_length(Field::kNoFixedLength);
  set_guarded_list_length_in_object_offset(Field::kUnknownLengthOffset);
  // Drop any code that relied on the above assumptions.
  DeoptimizeDependentCode();
}

void LiteralToken::set_literal(const String& literal) const {
  StorePointer(&raw_ptr()->literal_, literal.raw());
}

void LiteralToken::set_value(const Object& value) const {
  StorePointer(&raw_ptr()->value_, value.raw());
}

RawLiteralToken* LiteralToken::New() {
  ASSERT(Object::literal_token_class() != Class::null());
  RawObject* raw = Object::Allocate(LiteralToken::kClassId,
                                    LiteralToken::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawLiteralToken*>(raw);
}

RawLiteralToken* LiteralToken::New(Token::Kind kind, const String& literal) {
  const LiteralToken& result = LiteralToken::Handle(LiteralToken::New());
  result.set_kind(kind);
  result.set_literal(literal);
  if (kind == Token::kINTEGER) {
    const Integer& value = Integer::Handle(Integer::NewCanonical(literal));
    if (value.IsNull()) {
      // Integer is out of range.
      return LiteralToken::null();
    }
    ASSERT(value.IsSmi() || value.IsOld());
    result.set_value(value);
  } else if (kind == Token::kDOUBLE) {
    const Double& value = Double::Handle(Double::NewCanonical(literal));
    result.set_value(value);
  } else {
    ASSERT(Token::NeedsLiteralToken(kind));
    result.set_value(literal);
  }
  return result.raw();
}

const char* LiteralToken::ToCString() const {
  const String& token = String::Handle(literal());
  return token.ToCString();
}

RawGrowableObjectArray* TokenStream::TokenObjects() const {
  return raw_ptr()->token_objects_;
}

void TokenStream::SetTokenObjects(const GrowableObjectArray& value) const {
  StorePointer(&raw_ptr()->token_objects_, value.raw());
}

RawExternalTypedData* TokenStream::GetStream() const {
  return raw_ptr()->stream_;
}

void TokenStream::SetStream(const ExternalTypedData& value) const {
  StorePointer(&raw_ptr()->stream_, value.raw());
}

void TokenStream::DataFinalizer(void* isolate_callback_data,
                                Dart_WeakPersistentHandle handle,
                                void* peer) {
  ASSERT(peer != NULL);
  ::free(peer);
}

RawString* TokenStream::PrivateKey() const {
  return raw_ptr()->private_key_;
}

void TokenStream::SetPrivateKey(const String& value) const {
  StorePointer(&raw_ptr()->private_key_, value.raw());
}

RawString* TokenStream::GenerateSource() const {
  return GenerateSource(TokenPosition::kMinSource, TokenPosition::kMaxSource);
}

RawString* TokenStream::GenerateSource(TokenPosition start_pos,
                                       TokenPosition end_pos) const {
  Zone* zone = Thread::Current()->zone();
  Iterator iterator(zone, *this, start_pos, Iterator::kAllTokens);
  const ExternalTypedData& data = ExternalTypedData::Handle(zone, GetStream());
  const GrowableObjectArray& literals = GrowableObjectArray::Handle(
      zone, GrowableObjectArray::New(data.Length()));
  const String& private_key = String::Handle(zone, PrivateKey());
  intptr_t private_len = private_key.Length();

  Token::Kind curr = iterator.CurrentTokenKind();
  Token::Kind prev = Token::kILLEGAL;
  // Handles used in the loop.
  Object& obj = Object::Handle(zone);
  String& literal = String::Handle(zone);
  // Current indentation level.
  int indent = 0;

  while ((curr != Token::kEOS) && (iterator.CurrentPosition() < end_pos)) {
    // Remember current values for this token.
    obj = iterator.CurrentToken();
    literal = iterator.MakeLiteralToken(obj);
    // Advance to be able to use next token kind.
    iterator.Advance();
    Token::Kind next = iterator.CurrentTokenKind();

    // Handle the current token.
    if (curr == Token::kSTRING) {
      bool escape_characters = false;
      for (intptr_t i = 0; i < literal.Length(); i++) {
        if (NeedsEscapeSequence(literal.CharAt(i))) {
          escape_characters = true;
        }
      }
      if ((prev != Token::kINTERPOL_VAR) && (prev != Token::kINTERPOL_END)) {
        literals.Add(Symbols::DoubleQuote());
      }
      if (escape_characters) {
        literal = String::EscapeSpecialCharacters(literal);
        literals.Add(literal);
      } else {
        literals.Add(literal);
      }
      if ((next != Token::kINTERPOL_VAR) && (next != Token::kINTERPOL_START)) {
        literals.Add(Symbols::DoubleQuote());
      }
    } else if (curr == Token::kINTERPOL_VAR) {
      literals.Add(Symbols::Dollar());
      if (literal.CharAt(0) == Library::kPrivateIdentifierStart) {
        literal = String::SubString(literal, 0, literal.Length() - private_len);
      }
      literals.Add(literal);
    } else if (curr == Token::kIDENT) {
      if (literal.CharAt(0) == Library::kPrivateIdentifierStart) {
        literal = String::SubString(literal, 0, literal.Length() - private_len);
      }
      literals.Add(literal);
    } else {
      literals.Add(literal);
    }
    // Determine the separation text based on this current token.
    const String* separator = NULL;
    switch (curr) {
      case Token::kLBRACE:
      case Token::kRBRACE:
        if (next != Token::kNEWLINE) {
          separator = &Symbols::Blank();
        }
        break;
      case Token::kPERIOD:
      case Token::kLBRACK:
      case Token::kINTERPOL_VAR:
      case Token::kINTERPOL_START:
      case Token::kINTERPOL_END:
      case Token::kBIT_NOT:
      case Token::kNOT:
        break;
      // In case we see an opening parentheses '(' we increase the indent to
      // align multi-line parameters accordingly. The indent will be removed as
      // soon as we see the matching closing parentheses ')'.
      //
      // Example:
      // SomeVeryLongMethod(
      //     "withVeryLongParameter",
      //     "andAnotherVeryLongParameter",
      //     "andAnotherVeryLongParameter2") { ...
      case Token::kLPAREN:
        indent += 2;
        break;
      case Token::kRPAREN:
        indent -= 2;
        separator = &Symbols::Blank();
        break;
      case Token::kNEWLINE:
        if (prev == Token::kLBRACE) {
          indent++;
        }
        if (next == Token::kRBRACE) {
          indent--;
        }
        break;
      default:
        separator = &Symbols::Blank();
        break;
    }

    // Determine whether the separation text needs to be updated based on the
    // next token.
    switch (next) {
      case Token::kRBRACE:
        break;
      case Token::kNEWLINE:
      case Token::kSEMICOLON:
      case Token::kPERIOD:
      case Token::kCOMMA:
      case Token::kRPAREN:
      case Token::kLBRACK:
      case Token::kRBRACK:
      case Token::kINTERPOL_VAR:
      case Token::kINTERPOL_START:
      case Token::kINTERPOL_END:
        separator = NULL;
        break;
      case Token::kLPAREN:
        if (curr == Token::kCATCH) {
          separator = &Symbols::Blank();
        } else {
          separator = NULL;
        }
        break;
      case Token::kELSE:
        separator = &Symbols::Blank();
        break;
      default:
        // Do nothing.
        break;
    }

    // Update the few cases where both tokens need to be taken into account.
    if (((curr == Token::kIF) || (curr == Token::kFOR)) &&
        (next == Token::kLPAREN)) {
      separator = &Symbols::Blank();
    } else if ((curr == Token::kASSIGN) && (next == Token::kLPAREN)) {
      separator = &Symbols::Blank();
    } else if ((curr == Token::kRETURN || curr == Token::kCONDITIONAL ||
                Token::IsBinaryOperator(curr) ||
                Token::IsEqualityOperator(curr)) &&
               (next == Token::kLPAREN)) {
      separator = &Symbols::Blank();
    } else if ((curr == Token::kLBRACE) && (next == Token::kRBRACE)) {
      separator = NULL;
    } else if ((curr == Token::kSEMICOLON) && (next != Token::kNEWLINE)) {
      separator = &Symbols::Blank();
    } else if ((curr == Token::kIS) && (next == Token::kNOT)) {
      separator = NULL;
    } else if ((prev == Token::kIS) && (curr == Token::kNOT)) {
      separator = &Symbols::Blank();
    } else if ((curr == Token::kIDENT) &&
               ((next == Token::kINCR) || (next == Token::kDECR))) {
      separator = NULL;
    } else if (((curr == Token::kINCR) || (curr == Token::kDECR)) &&
               (next == Token::kIDENT)) {
      separator = NULL;
    }

    // Add the separator.
    if (separator != NULL) {
      literals.Add(*separator);
    }

    // Account for indentation in case we printed a newline.
    if (curr == Token::kNEWLINE) {
      for (int i = 0; i < indent; i++) {
        literals.Add(Symbols::TwoSpaces());
      }
    }

    // Setup for next iteration.
    prev = curr;
    curr = next;
  }
  const Array& source = Array::Handle(Array::MakeFixedLength(literals));
  return String::ConcatAll(source);
}

intptr_t TokenStream::ComputeSourcePosition(TokenPosition tok_pos) const {
  Zone* zone = Thread::Current()->zone();
  Iterator iterator(zone, *this, TokenPosition::kMinSource,
                    Iterator::kAllTokens);
  intptr_t src_pos = 0;
  Token::Kind kind = iterator.CurrentTokenKind();
  while ((iterator.CurrentPosition() < tok_pos) && (kind != Token::kEOS)) {
    iterator.Advance();
    kind = iterator.CurrentTokenKind();
    src_pos++;
  }
  return src_pos;
}

RawTokenStream* TokenStream::New() {
  ASSERT(Object::token_stream_class() != Class::null());
  RawObject* raw = Object::Allocate(TokenStream::kClassId,
                                    TokenStream::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawTokenStream*>(raw);
}

RawTokenStream* TokenStream::New(intptr_t len) {
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in TokenStream::New: invalid len %" Pd "\n", len);
  }
  uint8_t* data = reinterpret_cast<uint8_t*>(::malloc(len));
  ASSERT(data != NULL);
  Zone* zone = Thread::Current()->zone();
  const ExternalTypedData& stream = ExternalTypedData::Handle(
      zone, ExternalTypedData::New(kExternalTypedDataUint8ArrayCid, data, len,
                                   Heap::kOld));
  stream.AddFinalizer(data, DataFinalizer, len);
  const TokenStream& result = TokenStream::Handle(zone, TokenStream::New());
  result.SetStream(stream);
  return result.raw();
}

// CompressedTokenMap maps String and LiteralToken keys to Smi values.
// It also supports lookup by TokenDescriptor.
class CompressedTokenTraits {
 public:
  static const char* Name() { return "CompressedTokenTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Scanner::TokenDescriptor& descriptor,
                      const Object& key) {
    if (!key.IsLiteralToken()) {
      return false;
    }
    const LiteralToken& token = LiteralToken::Cast(key);
    return (token.literal() == descriptor.literal->raw()) &&
           (token.kind() == descriptor.kind);
  }

  // Only for non-descriptor lookup and table expansion.
  static bool IsMatch(const Object& a, const Object& b) {
    return a.raw() == b.raw();
  }

  static uword Hash(const Scanner::TokenDescriptor& descriptor) {
    return descriptor.literal->Hash();
  }

  static uword Hash(const Object& key) {
    if (key.IsLiteralToken()) {
      return String::HashRawSymbol(LiteralToken::Cast(key).literal());
    } else {
      return String::Cast(key).Hash();
    }
  }
};
typedef UnorderedHashMap<CompressedTokenTraits> CompressedTokenMap;

// Helper class for creation of compressed token stream data.
class CompressedTokenStreamData : public Scanner::TokenCollector {
 public:
  static const intptr_t kInitialBufferSize = 16 * KB;
  static const bool kPrintTokenObjects = false;

  CompressedTokenStreamData(const GrowableObjectArray& ta,
                            CompressedTokenMap* map,
                            Obfuscator* obfuscator)
      : buffer_(NULL),
        stream_(&buffer_, Reallocate, kInitialBufferSize),
        token_objects_(ta),
        tokens_(map),
        str_(String::Handle()),
        value_(Object::Handle()),
        fresh_index_smi_(Smi::Handle()),
        num_tokens_collected_(0),
        obfuscator_(obfuscator) {}
  virtual ~CompressedTokenStreamData() {}

  virtual void AddToken(const Scanner::TokenDescriptor& token) {
    if (token.kind == Token::kIDENT) {  // Identifier token.
      AddIdentToken(*token.literal);
    } else if (token.kind == Token::kINTERPOL_VAR) {
      str_ = token.literal->raw();
      str_ = obfuscator_->Rename(str_);

      Scanner::TokenDescriptor token_copy = token;
      token_copy.literal = &str_;
      AddLiteralToken(token_copy);
    } else if (Token::NeedsLiteralToken(token.kind)) {  // Literal token.
      AddLiteralToken(token);
    } else {  // Keyword, pseudo keyword etc.
      ASSERT(token.kind < Token::kNumTokens);
      AddSimpleToken(token.kind);
    }
    num_tokens_collected_++;
  }

  // Return the compressed token stream.
  uint8_t* GetStream() const { return buffer_; }

  // Return the compressed token stream length.
  intptr_t Length() const { return stream_.bytes_written(); }

  intptr_t NumTokens() const { return num_tokens_collected_; }

 private:
  // Add an IDENT token into the stream and the token hash map.
  void AddIdentToken(const String& ident) {
    ASSERT(ident.IsSymbol());
    const intptr_t fresh_index = token_objects_.Length();
    str_ = ident.raw();
    str_ = obfuscator_->Rename(str_);
    fresh_index_smi_ = Smi::New(fresh_index);
    intptr_t index = Smi::Value(
        Smi::RawCast(tokens_->InsertOrGetValue(ident, fresh_index_smi_)));
    if (index == fresh_index) {
      token_objects_.Add(str_);
      if (kPrintTokenObjects) {
        int iid = Isolate::Current()->main_port() % 1024;
        OS::Print("%03x ident <%s -> %s>\n", iid, ident.ToCString(),
                  str_.ToCString());
      }
    }
    WriteIndex(index);
  }

  // Add a LITERAL token into the stream and the token hash map.
  void AddLiteralToken(const Scanner::TokenDescriptor& descriptor) {
    ASSERT(descriptor.literal->IsSymbol());
    bool is_present = false;
    value_ = tokens_->GetOrNull(descriptor, &is_present);
    intptr_t index = -1;
    if (is_present) {
      ASSERT(value_.IsSmi());
      index = Smi::Cast(value_).Value();
    } else {
      const intptr_t fresh_index = token_objects_.Length();
      fresh_index_smi_ = Smi::New(fresh_index);
      const LiteralToken& lit = LiteralToken::Handle(
          LiteralToken::New(descriptor.kind, *descriptor.literal));
      if (lit.IsNull()) {
        // Convert token to an error.
        ASSERT(descriptor.kind == Token::kINTEGER);
        ASSERT(FLAG_limit_ints_to_64_bits);
        Scanner::TokenDescriptor errorDesc = descriptor;
        errorDesc.kind = Token::kERROR;
        errorDesc.literal = &String::Handle(Symbols::NewFormatted(
            Thread::Current(), "integer literal %s is out of range",
            descriptor.literal->ToCString()));
        AddLiteralToken(errorDesc);
        return;
      }
      index = Smi::Value(
          Smi::RawCast(tokens_->InsertOrGetValue(lit, fresh_index_smi_)));
      token_objects_.Add(lit);
      if (kPrintTokenObjects) {
        int iid = Isolate::Current()->main_port() % 1024;
        printf("lit    %03x  %p  %p  %p  <%s>\n", iid, token_objects_.raw(),
               lit.literal(), lit.value(),
               String::Handle(lit.literal()).ToCString());
      }
    }
    WriteIndex(index);
  }

  // Add a simple token into the stream.
  void AddSimpleToken(intptr_t kind) { stream_.WriteUnsigned(kind); }

  void WriteIndex(intptr_t value) {
    stream_.WriteUnsigned(value + Token::kNumTokens);
  }

  static uint8_t* Reallocate(uint8_t* ptr,
                             intptr_t old_size,
                             intptr_t new_size) {
    void* new_ptr = ::realloc(reinterpret_cast<void*>(ptr), new_size);
    return reinterpret_cast<uint8_t*>(new_ptr);
  }

  uint8_t* buffer_;
  WriteStream stream_;
  const GrowableObjectArray& token_objects_;
  CompressedTokenMap* tokens_;
  String& str_;
  Object& value_;
  Smi& fresh_index_smi_;
  intptr_t num_tokens_collected_;
  Obfuscator* obfuscator_;

  DISALLOW_COPY_AND_ASSIGN(CompressedTokenStreamData);
};

RawTokenStream* TokenStream::New(const String& source,
                                 const String& private_key,
                                 bool use_shared_tokens) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  GrowableObjectArray& token_objects = GrowableObjectArray::Handle(zone);
  Array& token_objects_map = Array::Handle(zone);
  if (use_shared_tokens) {
    // Use the shared token objects array in the object store. Allocate
    // a new array if necessary.
    ObjectStore* store = thread->isolate()->object_store();
    if (store->token_objects() == GrowableObjectArray::null()) {
      OpenSharedTokenList(thread->isolate());
    }
    token_objects = store->token_objects();
    token_objects_map = store->token_objects_map();
  } else {
    // Use new, non-shared token array.
    const int kInitialPrivateCapacity = 256;
    token_objects =
        GrowableObjectArray::New(kInitialPrivateCapacity, Heap::kOld);
    token_objects_map = HashTables::New<CompressedTokenMap>(
        kInitialPrivateCapacity, Heap::kOld);
  }
  Obfuscator obfuscator(thread, private_key);
  CompressedTokenMap map(token_objects_map.raw());
  CompressedTokenStreamData data(token_objects, &map, &obfuscator);
  Scanner scanner(source, private_key);
  scanner.ScanAll(&data);
  INC_STAT(thread, num_tokens_scanned, data.NumTokens());

  // Create and setup the token stream object.
  const ExternalTypedData& stream = ExternalTypedData::Handle(
      zone,
      ExternalTypedData::New(kExternalTypedDataUint8ArrayCid, data.GetStream(),
                             data.Length(), Heap::kOld));
  intptr_t external_size = data.Length();
  stream.AddFinalizer(data.GetStream(), DataFinalizer, external_size);
  const TokenStream& result = TokenStream::Handle(zone, New());
  result.SetPrivateKey(private_key);
  {
    NoSafepointScope no_safepoint;
    result.SetStream(stream);
    result.SetTokenObjects(token_objects);
  }

  token_objects_map = map.Release().raw();
  if (use_shared_tokens) {
    thread->isolate()->object_store()->set_token_objects_map(token_objects_map);
  }
  return result.raw();
}

void TokenStream::OpenSharedTokenList(Isolate* isolate) {
  const int kInitialSharedCapacity = 5 * 1024;
  ObjectStore* store = isolate->object_store();
  ASSERT(store->token_objects() == GrowableObjectArray::null());
  const GrowableObjectArray& token_objects = GrowableObjectArray::Handle(
      GrowableObjectArray::New(kInitialSharedCapacity, Heap::kOld));
  store->set_token_objects(token_objects);
  const Array& token_objects_map = Array::Handle(
      HashTables::New<CompressedTokenMap>(kInitialSharedCapacity, Heap::kOld));
  store->set_token_objects_map(token_objects_map);
}

void TokenStream::CloseSharedTokenList(Isolate* isolate) {
  isolate->object_store()->set_token_objects(GrowableObjectArray::Handle());
  isolate->object_store()->set_token_objects_map(Array::null_array());
}

const char* TokenStream::ToCString() const {
  return "TokenStream";
}

TokenStream::Iterator::Iterator(Zone* zone,
                                const TokenStream& tokens,
                                TokenPosition token_pos,
                                Iterator::StreamType stream_type)
    : tokens_(TokenStream::Handle(zone, tokens.raw())),
      data_(ExternalTypedData::Handle(zone, tokens.GetStream())),
      stream_(reinterpret_cast<uint8_t*>(data_.DataAddr(0)), data_.Length()),
      token_objects_(Array::Handle(
          zone,
          GrowableObjectArray::Handle(zone, tokens.TokenObjects()).data())),
      obj_(Object::Handle(zone)),
      cur_token_pos_(token_pos.Pos()),
      cur_token_kind_(Token::kILLEGAL),
      cur_token_obj_index_(-1),
      stream_type_(stream_type) {
  ASSERT(token_pos != TokenPosition::kNoSource);
  if (token_pos.IsReal()) {
    SetCurrentPosition(token_pos);
  }
}

void TokenStream::Iterator::SetStream(const TokenStream& tokens,
                                      TokenPosition token_pos) {
  tokens_ = tokens.raw();
  data_ = tokens.GetStream();
  stream_.SetStream(reinterpret_cast<uint8_t*>(data_.DataAddr(0)),
                    data_.Length());
  token_objects_ = GrowableObjectArray::Handle(tokens.TokenObjects()).data();
  obj_ = Object::null();
  cur_token_pos_ = token_pos.Pos();
  cur_token_kind_ = Token::kILLEGAL;
  cur_token_obj_index_ = -1;
  SetCurrentPosition(token_pos);
}

bool TokenStream::Iterator::IsValid() const {
  return !tokens_.IsNull();
}

Token::Kind TokenStream::Iterator::LookaheadTokenKind(intptr_t num_tokens) {
  intptr_t saved_position = stream_.Position();
  Token::Kind kind = Token::kILLEGAL;
  intptr_t value = -1;
  intptr_t count = 0;
  while (count < num_tokens && value != Token::kEOS) {
    value = ReadToken();
    if ((stream_type_ == kAllTokens) ||
        (static_cast<Token::Kind>(value) != Token::kNEWLINE)) {
      count += 1;
    }
  }
  if (value < Token::kNumTokens) {
    kind = static_cast<Token::Kind>(value);
  } else {
    value = value - Token::kNumTokens;
    obj_ = token_objects_.At(value);
    if (obj_.IsLiteralToken()) {
      const LiteralToken& literal_token = LiteralToken::Cast(obj_);
      kind = literal_token.kind();
    } else {
      ASSERT(obj_.IsString());  // Must be an identifier.
      kind = Token::kIDENT;
    }
  }
  stream_.SetPosition(saved_position);
  return kind;
}

TokenPosition TokenStream::Iterator::CurrentPosition() const {
  return TokenPosition(cur_token_pos_);
}

void TokenStream::Iterator::SetCurrentPosition(TokenPosition token_pos) {
  stream_.SetPosition(token_pos.value());
  Advance();
}

void TokenStream::Iterator::Advance() {
  intptr_t value;
  do {
    cur_token_pos_ = stream_.Position();
    value = ReadToken();
  } while ((stream_type_ == kNoNewlines) &&
           (static_cast<Token::Kind>(value) == Token::kNEWLINE));
  if (value < Token::kNumTokens) {
    cur_token_kind_ = static_cast<Token::Kind>(value);
    cur_token_obj_index_ = -1;
    return;
  }
  cur_token_obj_index_ = value - Token::kNumTokens;
  obj_ = token_objects_.At(cur_token_obj_index_);
  if (obj_.IsLiteralToken()) {
    const LiteralToken& literal_token = LiteralToken::Cast(obj_);
    cur_token_kind_ = literal_token.kind();
    return;
  }
  ASSERT(obj_.IsString());  // Must be an identifier.
  cur_token_kind_ = Token::kIDENT;
}

RawObject* TokenStream::Iterator::CurrentToken() const {
  if (cur_token_obj_index_ != -1) {
    return token_objects_.At(cur_token_obj_index_);
  } else {
    return Smi::New(cur_token_kind_);
  }
}

RawString* TokenStream::Iterator::CurrentLiteral() const {
  obj_ = CurrentToken();
  return MakeLiteralToken(obj_);
}

RawString* TokenStream::Iterator::MakeLiteralToken(const Object& obj) const {
  if (obj.IsString()) {
    return reinterpret_cast<RawString*>(obj.raw());
  } else if (obj.IsSmi()) {
    Token::Kind kind = static_cast<Token::Kind>(
        Smi::Value(reinterpret_cast<RawSmi*>(obj.raw())));
    ASSERT(kind < Token::kNumTokens);
    return Symbols::Token(kind).raw();
  } else {
    ASSERT(obj.IsLiteralToken());  // Must be a literal token.
    const LiteralToken& literal_token = LiteralToken::Cast(obj);
    return literal_token.literal();
  }
}

bool Script::HasSource() const {
  return raw_ptr()->source_ != String::null();
}

RawString* Script::Source() const {
  String& source = String::Handle(raw_ptr()->source_);
  if (source.IsNull()) {
    return GenerateSource();
  }
  return raw_ptr()->source_;
}

RawString* Script::GenerateSource() const {
  const TokenStream& token_stream = TokenStream::Handle(tokens());
  if (token_stream.IsNull()) {
    ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
    return String::null();
  }
  return token_stream.GenerateSource();
}

void Script::set_compile_time_constants(const Array& value) const {
  StorePointer(&raw_ptr()->compile_time_constants_, value.raw());
}

void Script::set_kernel_script_index(const intptr_t kernel_script_index) const {
  StoreNonPointer(&raw_ptr()->kernel_script_index_, kernel_script_index);
}

void Script::set_kernel_string_offsets(const TypedData& offsets) const {
  StorePointer(&raw_ptr()->kernel_string_offsets_, offsets.raw());
}

void Script::set_kernel_string_data(const TypedData& data) const {
  StorePointer(&raw_ptr()->kernel_string_data_, data.raw());
}

void Script::set_kernel_canonical_names(const TypedData& names) const {
  StorePointer(&raw_ptr()->kernel_canonical_names_, names.raw());
}

RawGrowableObjectArray* Script::GenerateLineNumberArray() const {
  Zone* zone = Thread::Current()->zone();
  const GrowableObjectArray& info =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const String& source = String::Handle(zone, Source());
  const String& key = Symbols::Empty();
  const Object& line_separator = Object::Handle(zone);
  Smi& value = Smi::Handle(zone);

  if (kind() == RawScript::kKernelTag) {
    const Array& line_starts_array = Array::Handle(line_starts());
    if (line_starts_array.IsNull()) {
      // Scripts in the AOT snapshot do not have a line starts array.
      // A well-formed line number array has a leading null.
      info.Add(line_separator);  // New line.
      return info.raw();
    }
    intptr_t line_count = line_starts_array.Length();
    ASSERT(line_count > 0);
    const Array& debug_positions_array = Array::Handle(debug_positions());
    intptr_t token_count = debug_positions_array.Length();
    int token_index = 0;

    for (int line_index = 0; line_index < line_count; ++line_index) {
      value ^= line_starts_array.At(line_index);
      intptr_t start = value.Value();
      // Output the rest of the tokens if we have no next line.
      intptr_t end = TokenPosition::kMaxSourcePos;
      if (line_index + 1 < line_count) {
        value ^= line_starts_array.At(line_index + 1);
        end = value.Value();
      }
      bool first = true;
      while (token_index < token_count) {
        value ^= debug_positions_array.At(token_index);
        intptr_t debug_position = value.Value();
        if (debug_position >= end) break;

        if (first) {
          info.Add(line_separator);          // New line.
          value = Smi::New(line_index + 1);  // Line number.
          info.Add(value);
          first = false;
        }

        value ^= debug_positions_array.At(token_index);
        info.Add(value);                               // Token position.
        value = Smi::New(debug_position - start + 1);  // Column.
        info.Add(value);
        ++token_index;
      }
    }
    return info.raw();
  }

  const TokenStream& tkns = TokenStream::Handle(zone, tokens());
  String& tokenValue = String::Handle(zone);
  ASSERT(!tkns.IsNull());
  TokenStream::Iterator tkit(zone, tkns, TokenPosition::kMinSource,
                             TokenStream::Iterator::kAllTokens);
  int current_line = -1;
  Scanner s(source, key);
  s.Scan();
  bool skippedNewline = false;
  while (tkit.CurrentTokenKind() != Token::kEOS) {
    if (tkit.CurrentTokenKind() == Token::kNEWLINE) {
      // Skip newlines from the token stream.
      skippedNewline = true;
      tkit.Advance();
      continue;
    }
    if (s.current_token().kind != tkit.CurrentTokenKind()) {
      // Suppose we have a multiline string with interpolation:
      //
      // 10    '''
      // 11    bar
      // 12    baz
      // 13    foo is $foo
      // 14    '''
      //
      // In the token stream, this becomes something like:
      //
      // 10    string('bar\nbaz\nfoo is\n')
      // 11    newline
      // 12    newline
      // 13    string('') interpol_var(foo) string('\n')
      // 14
      //
      // In order to keep the token iterator and the scanner in sync,
      // we need to skip the extra empty string before the
      // interpolation.
      if (skippedNewline &&
          (s.current_token().kind == Token::kINTERPOL_VAR ||
           s.current_token().kind == Token::kINTERPOL_START) &&
          tkit.CurrentTokenKind() == Token::kSTRING) {
        tokenValue = tkit.CurrentLiteral();
        if (tokenValue.Length() == 0) {
          tkit.Advance();
        }
      }
    }
    skippedNewline = false;
    ASSERT(s.current_token().kind == tkit.CurrentTokenKind());
    int token_line = s.current_token().position.line;
    if (token_line != current_line) {
      // emit line
      info.Add(line_separator);
      value = Smi::New(token_line + line_offset());
      info.Add(value);
      current_line = token_line;
    }
    // TODO(hausner): Could optimize here by not reporting tokens
    // that will never be a location used by the debugger, e.g.
    // braces, semicolons, most keywords etc.
    value = Smi::New(tkit.CurrentPosition().Pos());
    info.Add(value);
    int column = s.current_token().position.column;
    // On the first line of the script we must add the column offset.
    if (token_line == 1) {
      column += col_offset();
    }
    value = Smi::New(column);
    info.Add(value);
    tkit.Advance();
    s.Scan();
  }
  return info.raw();
}

const char* Script::GetKindAsCString() const {
  switch (kind()) {
    case RawScript::kScriptTag:
      return "script";
    case RawScript::kLibraryTag:
      return "library";
    case RawScript::kSourceTag:
      return "source";
    case RawScript::kPatchTag:
      return "patch";
    case RawScript::kEvaluateTag:
      return "evaluate";
    case RawScript::kKernelTag:
      return "kernel";
    default:
      UNIMPLEMENTED();
  }
  UNREACHABLE();
  return NULL;
}

void Script::set_url(const String& value) const {
  StorePointer(&raw_ptr()->url_, value.raw());
}

void Script::set_resolved_url(const String& value) const {
  StorePointer(&raw_ptr()->resolved_url_, value.raw());
}

void Script::set_source(const String& value) const {
  StorePointer(&raw_ptr()->source_, value.raw());
}

void Script::set_line_starts(const Array& value) const {
  StorePointer(&raw_ptr()->line_starts_, value.raw());
}

void Script::set_debug_positions(const Array& value) const {
  StorePointer(&raw_ptr()->debug_positions_, value.raw());
}

void Script::set_yield_positions(const Array& value) const {
  StorePointer(&raw_ptr()->yield_positions_, value.raw());
}

RawArray* Script::yield_positions() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Array& yields = Array::Handle(raw_ptr()->yield_positions_);
  if (yields.IsNull() && kind() == RawScript::kKernelTag) {
    // This is created lazily. Now we need it.
    kernel::CollectTokenPositionsFor(*this);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return raw_ptr()->yield_positions_;
}

RawArray* Script::line_starts() const {
  return raw_ptr()->line_starts_;
}

RawArray* Script::debug_positions() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Array& debug_positions_array = Array::Handle(raw_ptr()->debug_positions_);
  if (debug_positions_array.IsNull() && kind() == RawScript::kKernelTag) {
    // This is created lazily. Now we need it.
    kernel::CollectTokenPositionsFor(*this);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return raw_ptr()->debug_positions_;
}

void Script::set_kind(RawScript::Kind value) const {
  StoreNonPointer(&raw_ptr()->kind_, value);
}

void Script::set_load_timestamp(int64_t value) const {
  StoreNonPointer(&raw_ptr()->load_timestamp_, value);
}

void Script::set_tokens(const TokenStream& value) const {
  StorePointer(&raw_ptr()->tokens_, value.raw());
}

void Script::Tokenize(const String& private_key, bool use_shared_tokens) const {
  if (kind() == RawScript::kKernelTag) {
    return;
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const TokenStream& tkns = TokenStream::Handle(zone, tokens());
  if (!tkns.IsNull()) {
    // Already tokenized.
    return;
  }

  // Get the source, scan and allocate the token stream.
  VMTagScope tagScope(thread, VMTag::kCompileScannerTagId);
  CSTAT_TIMER_SCOPE(thread, scanner_timer);
  const String& src = String::Handle(zone, Source());
  const TokenStream& ts = TokenStream::Handle(
      zone, TokenStream::New(src, private_key, use_shared_tokens));
  set_tokens(ts);
  INC_STAT(thread, src_length, src.Length());
}

void Script::SetLocationOffset(intptr_t line_offset,
                               intptr_t col_offset) const {
  ASSERT(line_offset >= 0);
  ASSERT(col_offset >= 0);
  StoreNonPointer(&raw_ptr()->line_offset_, line_offset);
  StoreNonPointer(&raw_ptr()->col_offset_, col_offset);
}

// Specialized for AOT compilation, which does this lookup for every token
// position that could be part of a stack trace.
intptr_t Script::GetTokenLineUsingLineStarts(
    TokenPosition target_token_pos) const {
  if (target_token_pos.IsNoSource()) {
    return 0;
  }
  Zone* zone = Thread::Current()->zone();
  Array& line_starts_array = Array::Handle(zone, line_starts());
  Smi& token_pos = Smi::Handle(zone);
  if (line_starts_array.IsNull()) {
    ASSERT(kind() != RawScript::kKernelTag);
    GrowableObjectArray& line_starts_list =
        GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
    const TokenStream& tkns = TokenStream::Handle(zone, tokens());
    TokenStream::Iterator tkit(zone, tkns, TokenPosition::kMinSource,
                               TokenStream::Iterator::kAllTokens);
    intptr_t cur_line = line_offset() + 1;
    token_pos = Smi::New(0);
    line_starts_list.Add(token_pos);
    while (tkit.CurrentTokenKind() != Token::kEOS) {
      if (tkit.CurrentTokenKind() == Token::kNEWLINE) {
        cur_line++;
        token_pos = Smi::New(tkit.CurrentPosition().value() + 1);
        line_starts_list.Add(token_pos);
      }
      tkit.Advance();
    }
    line_starts_array = Array::MakeFixedLength(line_starts_list);
    set_line_starts(line_starts_array);
  }

  ASSERT(line_starts_array.Length() > 0);
  intptr_t offset = target_token_pos.Pos();
  intptr_t min = 0;
  intptr_t max = line_starts_array.Length() - 1;

  // Binary search to find the line containing this offset.
  while (min < max) {
    int midpoint = (max - min + 1) / 2 + min;
    token_pos ^= line_starts_array.At(midpoint);
    if (token_pos.Value() > offset) {
      max = midpoint - 1;
    } else {
      min = midpoint;
    }
  }
  return min + 1;  // Line numbers start at 1.
}

void Script::GetTokenLocation(TokenPosition token_pos,
                              intptr_t* line,
                              intptr_t* column,
                              intptr_t* token_len) const {
  ASSERT(line != NULL);
  Zone* zone = Thread::Current()->zone();

  if (kind() == RawScript::kKernelTag) {
    const Array& line_starts_array = Array::Handle(zone, line_starts());
    if (line_starts_array.IsNull()) {
      // Scripts in the AOT snapshot do not have a line starts array.
      *line = -1;
      if (column != NULL) {
        *column = -1;
      }
      if (token_len != NULL) {
        *token_len = 1;
      }
      return;
    }
    ASSERT(line_starts_array.Length() > 0);
    intptr_t offset = token_pos.value();
    intptr_t min = 0;
    intptr_t max = line_starts_array.Length() - 1;

    // Binary search to find the line containing this offset.
    Smi& smi = Smi::Handle(zone);
    while (min < max) {
      intptr_t midpoint = (max - min + 1) / 2 + min;

      smi ^= line_starts_array.At(midpoint);
      if (smi.Value() > offset) {
        max = midpoint - 1;
      } else {
        min = midpoint;
      }
    }
    *line = min + 1;  // Line numbers start at 1.
    smi ^= line_starts_array.At(min);
    if (column != NULL) {
      *column = offset - smi.Value() + 1;
    }
    if (token_len != NULL) {
      // We don't explicitly save this data: Load the source
      // and find it from there.
      const String& source = String::Handle(zone, Source());
      *token_len = 1;
      if (offset < source.Length() &&
          Scanner::IsIdentStartChar(source.CharAt(offset))) {
        for (intptr_t i = offset + 1;
             i < source.Length() && Scanner::IsIdentChar(source.CharAt(i));
             ++i) {
          ++*token_len;
        }
      }
    }
    return;
  }

  const TokenStream& tkns = TokenStream::Handle(zone, tokens());
  if (tkns.IsNull()) {
    ASSERT((Dart::vm_snapshot_kind() == Snapshot::kFullAOT));
    *line = -1;
    if (column != NULL) {
      *column = -1;
    }
    if (token_len != NULL) {
      *token_len = 1;
    }
    return;
  }
  if (column == NULL) {
    TokenStream::Iterator tkit(zone, tkns, TokenPosition::kMinSource,
                               TokenStream::Iterator::kAllTokens);
    intptr_t cur_line = line_offset() + 1;
    while ((tkit.CurrentPosition() < token_pos) &&
           (tkit.CurrentTokenKind() != Token::kEOS)) {
      if (tkit.CurrentTokenKind() == Token::kNEWLINE) {
        cur_line++;
      }
      tkit.Advance();
    }
    *line = cur_line;
  } else {
    const String& src = String::Handle(zone, Source());
    intptr_t src_pos = tkns.ComputeSourcePosition(token_pos);
    Scanner scanner(src, Symbols::Empty());
    scanner.ScanTo(src_pos);
    intptr_t relative_line = scanner.CurrentPosition().line;
    *line = relative_line + line_offset();
    *column = scanner.CurrentPosition().column;
    if (token_len != NULL) {
      if (scanner.current_token().literal != NULL) {
        *token_len = scanner.current_token().literal->Length();
      } else {
        *token_len = 1;
      }
    }
    // On the first line of the script we must add the column offset.
    if (relative_line == 1) {
      *column += col_offset();
    }
  }
}

void Script::TokenRangeAtLine(intptr_t line_number,
                              TokenPosition* first_token_index,
                              TokenPosition* last_token_index) const {
  ASSERT(first_token_index != NULL && last_token_index != NULL);
  ASSERT(line_number > 0);

  if (kind() == RawScript::kKernelTag) {
    const Array& line_starts_array = Array::Handle(line_starts());
    if (line_starts_array.IsNull()) {
      // Scripts in the AOT snapshot do not have a line starts array.
      *first_token_index = TokenPosition::kNoSource;
      *last_token_index = TokenPosition::kNoSource;
      return;
    }
    ASSERT(line_starts_array.Length() >= line_number);
    Smi& value = Smi::Handle();
    value ^= line_starts_array.At(line_number - 1);
    *first_token_index = TokenPosition(value.Value());
    if (line_starts_array.Length() > line_number) {
      value ^= line_starts_array.At(line_number);
      *last_token_index = TokenPosition(value.Value() - 1);
    } else {
      // Length of source is last possible token in this script.
      *last_token_index = TokenPosition(String::Handle(Source()).Length());
    }
    return;
  }

  Zone* zone = Thread::Current()->zone();
  *first_token_index = TokenPosition::kNoSource;
  *last_token_index = TokenPosition::kNoSource;
  const TokenStream& tkns = TokenStream::Handle(zone, tokens());
  line_number -= line_offset();
  if (line_number < 1) line_number = 1;
  TokenStream::Iterator tkit(zone, tkns, TokenPosition::kMinSource,
                             TokenStream::Iterator::kAllTokens);
  // Scan through the token stream to the required line.
  intptr_t cur_line = 1;
  while (cur_line < line_number && tkit.CurrentTokenKind() != Token::kEOS) {
    if (tkit.CurrentTokenKind() == Token::kNEWLINE) {
      cur_line++;
    }
    tkit.Advance();
  }
  if (tkit.CurrentTokenKind() == Token::kEOS) {
    // End of token stream before reaching required line.
    return;
  }
  if (tkit.CurrentTokenKind() == Token::kNEWLINE) {
    // No tokens on the current line. If there is a valid token afterwards, put
    // it into first_token_index.
    while (tkit.CurrentTokenKind() == Token::kNEWLINE &&
           tkit.CurrentTokenKind() != Token::kEOS) {
      tkit.Advance();
    }
    if (tkit.CurrentTokenKind() != Token::kEOS) {
      *first_token_index = tkit.CurrentPosition();
    }
    return;
  }
  *first_token_index = tkit.CurrentPosition();
  // We cannot do "CurrentPosition() - 1" for the last token, because we do not
  // know whether the previous token is a simple one or not.
  TokenPosition end_pos = *first_token_index;
  while (tkit.CurrentTokenKind() != Token::kNEWLINE &&
         tkit.CurrentTokenKind() != Token::kEOS) {
    end_pos = tkit.CurrentPosition();
    tkit.Advance();
  }
  *last_token_index = end_pos;
}

int32_t Script::SourceFingerprint() const {
  return SourceFingerprint(TokenPosition(TokenPosition::kMinSourcePos),
                           TokenPosition(TokenPosition::kMaxSourcePos));
}

int32_t Script::SourceFingerprint(TokenPosition start,
                                  TokenPosition end) const {
  uint32_t result = 0;
  Zone* zone = Thread::Current()->zone();
  TokenStream::Iterator tokens_iterator(
      zone, TokenStream::Handle(zone, tokens()), start);
  Object& obj = Object::Handle(zone);
  String& literal = String::Handle(zone);
  while ((tokens_iterator.CurrentTokenKind() != Token::kEOS) &&
         (tokens_iterator.CurrentPosition() < end)) {
    uint32_t val = 0;
    obj = tokens_iterator.CurrentToken();
    if (obj.IsSmi()) {
      val = Smi::Cast(obj).Value();
    } else {
      literal = tokens_iterator.MakeLiteralToken(obj);
      if (tokens_iterator.CurrentTokenKind() == Token::kIDENT ||
          tokens_iterator.CurrentTokenKind() == Token::kINTERPOL_VAR) {
        literal = String::RemovePrivateKey(literal);
      }
      val = literal.Hash();
    }
    result = 31 * result + val;
    tokens_iterator.Advance();
  }
  result = result & ((static_cast<uint32_t>(1) << 31) - 1);
  ASSERT(result <= static_cast<uint32_t>(kMaxInt32));
  return result;
}

RawString* Script::GetLine(intptr_t line_number, Heap::Space space) const {
  const String& src = String::Handle(Source());
  if (src.IsNull()) {
    ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
    return Symbols::OptimizedOut().raw();
  }
  intptr_t relative_line_number = line_number - line_offset();
  intptr_t current_line = 1;
  intptr_t line_start_idx = -1;
  intptr_t last_char_idx = -1;
  for (intptr_t ix = 0;
       (ix < src.Length()) && (current_line <= relative_line_number); ix++) {
    if ((current_line == relative_line_number) && (line_start_idx < 0)) {
      line_start_idx = ix;
    }
    if (src.CharAt(ix) == '\n') {
      current_line++;
    } else if (src.CharAt(ix) == '\r') {
      if ((ix + 1 != src.Length()) && (src.CharAt(ix + 1) != '\n')) {
        current_line++;
      }
    } else {
      last_char_idx = ix;
    }
  }
  // Guarantee that returned string is never NULL.

  if (line_start_idx >= 0) {
    return String::SubString(src, line_start_idx,
                             last_char_idx - line_start_idx + 1, space);
  } else {
    return Symbols::Empty().raw();
  }
}

RawString* Script::GetSnippet(TokenPosition from, TokenPosition to) const {
  intptr_t from_line;
  intptr_t from_column;
  intptr_t to_line;
  intptr_t to_column;
  GetTokenLocation(from, &from_line, &from_column);
  GetTokenLocation(to, &to_line, &to_column);
  return GetSnippet(from_line, from_column, to_line, to_column);
}

RawString* Script::GetSnippet(intptr_t from_line,
                              intptr_t from_column,
                              intptr_t to_line,
                              intptr_t to_column) const {
  const String& src = String::Handle(Source());
  if (src.IsNull()) {
    ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
    return Symbols::OptimizedOut().raw();
  }
  intptr_t length = src.Length();
  intptr_t line = 1 + line_offset();
  intptr_t column = 1;
  intptr_t scan_position = 0;
  intptr_t snippet_start = -1;
  intptr_t snippet_end = -1;
  if (from_line - line_offset() == 1) {
    column += col_offset();
  }

  while (scan_position != length) {
    if (snippet_start == -1) {
      if ((line == from_line) && (column == from_column)) {
        snippet_start = scan_position;
      }
    }

    char c = src.CharAt(scan_position);
    if (c == '\n') {
      line++;
      column = 0;
    } else if (c == '\r') {
      line++;
      column = 0;
      if ((scan_position + 1 != length) &&
          (src.CharAt(scan_position + 1) == '\n')) {
        scan_position++;
      }
    }
    scan_position++;
    column++;

    if ((line == to_line) && (column == to_column)) {
      snippet_end = scan_position;
      break;
    }
  }
  String& snippet = String::Handle();
  if ((snippet_start != -1) && (snippet_end != -1)) {
    snippet =
        String::SubString(src, snippet_start, snippet_end - snippet_start);
  }
  return snippet.raw();
}

RawScript* Script::New() {
  ASSERT(Object::script_class() != Class::null());
  RawObject* raw =
      Object::Allocate(Script::kClassId, Script::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawScript*>(raw);
}

RawScript* Script::New(const String& url,
                       const String& source,
                       RawScript::Kind kind) {
  return Script::New(url, url, source, kind);
}

RawScript* Script::New(const String& url,
                       const String& resolved_url,
                       const String& source,
                       RawScript::Kind kind) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Script& result = Script::Handle(zone, Script::New());
  result.set_url(String::Handle(zone, Symbols::New(thread, url)));
  result.set_resolved_url(
      String::Handle(zone, Symbols::New(thread, resolved_url)));
  result.set_source(source);
  result.set_kind(kind);
  result.set_load_timestamp(
      FLAG_remove_script_timestamps_for_test ? 0 : OS::GetCurrentTimeMillis());
  result.SetLocationOffset(0, 0);
  return result.raw();
}

const char* Script::ToCString() const {
  const String& name = String::Handle(url());
  return OS::SCreate(Thread::Current()->zone(), "Script(%s)", name.ToCString());
}

RawLibrary* Script::FindLibrary() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Array& scripts = Array::Handle(zone);
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    scripts = lib.LoadedScripts();
    for (intptr_t j = 0; j < scripts.Length(); j++) {
      if (scripts.At(j) == raw()) {
        return lib.raw();
      }
    }
  }
  return Library::null();
}

DictionaryIterator::DictionaryIterator(const Library& library)
    : array_(Array::Handle(library.dictionary())),
      // Last element in array is a Smi indicating the number of entries used.
      size_(Array::Handle(library.dictionary()).Length() - 1),
      next_ix_(0) {
  MoveToNextObject();
}

RawObject* DictionaryIterator::GetNext() {
  ASSERT(HasNext());
  int ix = next_ix_++;
  MoveToNextObject();
  ASSERT(array_.At(ix) != Object::null());
  return array_.At(ix);
}

void DictionaryIterator::MoveToNextObject() {
  Object& obj = Object::Handle(array_.At(next_ix_));
  while (obj.IsNull() && HasNext()) {
    next_ix_++;
    obj = array_.At(next_ix_);
  }
}

ClassDictionaryIterator::ClassDictionaryIterator(const Library& library,
                                                 IterationKind kind)
    : DictionaryIterator(library),
      toplevel_class_(Class::Handle((kind == kIteratePrivate)
                                        ? library.toplevel_class()
                                        : Class::null())) {
  MoveToNextClass();
}

RawClass* ClassDictionaryIterator::GetNextClass() {
  ASSERT(HasNext());
  Class& cls = Class::Handle();
  if (next_ix_ < size_) {
    int ix = next_ix_++;
    cls ^= array_.At(ix);
    MoveToNextClass();
    return cls.raw();
  }
  ASSERT(!toplevel_class_.IsNull());
  cls = toplevel_class_.raw();
  toplevel_class_ = Class::null();
  return cls.raw();
}

void ClassDictionaryIterator::MoveToNextClass() {
  Object& obj = Object::Handle();
  while (next_ix_ < size_) {
    obj = array_.At(next_ix_);
    if (obj.IsClass()) {
      return;
    }
    next_ix_++;
  }
}

LibraryPrefixIterator::LibraryPrefixIterator(const Library& library)
    : DictionaryIterator(library) {
  Advance();
}

RawLibraryPrefix* LibraryPrefixIterator::GetNext() {
  ASSERT(HasNext());
  int ix = next_ix_++;
  Object& obj = Object::Handle(array_.At(ix));
  Advance();
  return LibraryPrefix::Cast(obj).raw();
}

void LibraryPrefixIterator::Advance() {
  Object& obj = Object::Handle(array_.At(next_ix_));
  while (!obj.IsLibraryPrefix() && HasNext()) {
    next_ix_++;
    obj = array_.At(next_ix_);
  }
}

static void ReportTooManyImports(const Library& lib) {
  const String& url = String::Handle(lib.url());
  Report::MessageF(Report::kError, Script::Handle(lib.LookupScript(url)),
                   TokenPosition::kNoSource, Report::AtLocation,
                   "too many imports in library '%s'", url.ToCString());
  UNREACHABLE();
}

void Library::set_num_imports(intptr_t value) const {
  if (!Utils::IsUint(16, value)) {
    ReportTooManyImports(*this);
  }
  StoreNonPointer(&raw_ptr()->num_imports_, value);
}

void Library::set_name(const String& name) const {
  ASSERT(name.IsSymbol());
  StorePointer(&raw_ptr()->name_, name.raw());
}

void Library::set_url(const String& name) const {
  StorePointer(&raw_ptr()->url_, name.raw());
}

void Library::SetName(const String& name) const {
  // Only set name once.
  ASSERT(!Loaded());
  set_name(name);
}

void Library::SetLoadInProgress() const {
  // Must not already be in the process of being loaded.
  ASSERT(raw_ptr()->load_state_ <= RawLibrary::kLoadRequested);
  StoreNonPointer(&raw_ptr()->load_state_, RawLibrary::kLoadInProgress);
}

void Library::SetLoadRequested() const {
  // Must not be already loaded.
  ASSERT(raw_ptr()->load_state_ == RawLibrary::kAllocated);
  StoreNonPointer(&raw_ptr()->load_state_, RawLibrary::kLoadRequested);
}

void Library::SetLoaded() const {
  // Should not be already loaded or just allocated.
  ASSERT(LoadInProgress() || LoadRequested());
  StoreNonPointer(&raw_ptr()->load_state_, RawLibrary::kLoaded);
}

void Library::SetLoadError(const Instance& error) const {
  // Should not be already successfully loaded or just allocated.
  ASSERT(LoadInProgress() || LoadRequested() || LoadFailed());
  StoreNonPointer(&raw_ptr()->load_state_, RawLibrary::kLoadError);
  StorePointer(&raw_ptr()->load_error_, error.raw());
}

// Traits for looking up Libraries by url in a hash set.
class LibraryUrlTraits {
 public:
  static const char* Name() { return "LibraryUrlTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsLibrary() && b.IsLibrary());
    // Library objects are always canonical.
    return a.raw() == b.raw();
  }
  static uword Hash(const Object& key) { return Library::Cast(key).UrlHash(); }
};
typedef UnorderedHashSet<LibraryUrlTraits> LibraryLoadErrorSet;

RawInstance* Library::TransitiveLoadError() const {
  if (LoadError() != Instance::null()) {
    return LoadError();
  }
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ObjectStore* object_store = isolate->object_store();
  LibraryLoadErrorSet set(object_store->library_load_error_table());
  bool present = false;
  if (set.GetOrNull(*this, &present) != Object::null()) {
    object_store->set_library_load_error_table(set.Release());
    return Instance::null();
  }
  // Ensure we don't repeatedly visit the same library again.
  set.Insert(*this);
  object_store->set_library_load_error_table(set.Release());
  intptr_t num_imp = num_imports();
  Library& lib = Library::Handle(zone);
  Instance& error = Instance::Handle(zone);
  for (intptr_t i = 0; i < num_imp; i++) {
    HANDLESCOPE(thread);
    lib = ImportLibraryAt(i);
    error = lib.TransitiveLoadError();
    if (!error.IsNull()) {
      break;
    }
  }
  return error.raw();
}

void Library::AddPatchClass(const Class& cls) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(cls.is_patch());
  ASSERT(GetPatchClass(String::Handle(cls.Name())) == Class::null());
  const GrowableObjectArray& patch_classes =
      GrowableObjectArray::Handle(this->patch_classes());
  patch_classes.Add(cls);
}

RawClass* Library::GetPatchClass(const String& name) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  const GrowableObjectArray& patch_classes =
      GrowableObjectArray::Handle(this->patch_classes());
  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < patch_classes.Length(); i++) {
    obj = patch_classes.At(i);
    if (obj.IsClass() &&
        (Class::Cast(obj).Name() == name.raw())) {  // Names are canonicalized.
      return Class::RawCast(obj.raw());
    }
  }
  return Class::null();
}

void Library::RemovePatchClass(const Class& cls) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(cls.is_patch());
  const GrowableObjectArray& patch_classes =
      GrowableObjectArray::Handle(this->patch_classes());
  const intptr_t num_classes = patch_classes.Length();
  intptr_t i = 0;
  while (i < num_classes) {
    if (cls.raw() == patch_classes.At(i)) break;
    i++;
  }
  if (i == num_classes) return;
  // Replace the entry with the script. We keep the script so that
  // Library::LoadedScripts() can find it without having to iterate
  // over the members of each class.
  ASSERT(i < num_classes);  // We must have found a class.
  const Script& patch_script = Script::Handle(cls.script());
  patch_classes.SetAt(i, patch_script);
}

static RawString* MakeClassMetaName(Thread* thread,
                                    Zone* zone,
                                    const Class& cls) {
  return Symbols::FromConcat(thread, Symbols::At(),
                             String::Handle(zone, cls.Name()));
}

static RawString* MakeFieldMetaName(Thread* thread,
                                    Zone* zone,
                                    const Field& field) {
  const String& cname = String::Handle(
      zone,
      MakeClassMetaName(thread, zone, Class::Handle(zone, field.Origin())));
  GrowableHandlePtrArray<const String> pieces(zone, 3);
  pieces.Add(cname);
  pieces.Add(Symbols::At());
  pieces.Add(String::Handle(field.name()));
  return Symbols::FromConcatAll(thread, pieces);
}

static RawString* MakeFunctionMetaName(Thread* thread,
                                       Zone* zone,
                                       const Function& func) {
  const String& cname = String::Handle(
      zone,
      MakeClassMetaName(thread, zone, Class::Handle(zone, func.origin())));
  GrowableHandlePtrArray<const String> pieces(zone, 3);
  pieces.Add(cname);
  pieces.Add(Symbols::At());
  pieces.Add(String::Handle(func.QualifiedScrubbedName()));
  return Symbols::FromConcatAll(thread, pieces);
}

static RawString* MakeTypeParameterMetaName(Thread* thread,
                                            Zone* zone,
                                            const TypeParameter& param) {
  const String& cname = String::Handle(
      zone,
      MakeClassMetaName(thread, zone,
                        Class::Handle(zone, param.parameterized_class())));
  GrowableHandlePtrArray<const String> pieces(zone, 3);
  pieces.Add(cname);
  pieces.Add(Symbols::At());
  pieces.Add(String::Handle(param.name()));
  return Symbols::FromConcatAll(thread, pieces);
}

void Library::AddMetadata(const Object& owner,
                          const String& name,
                          TokenPosition token_pos,
                          intptr_t kernel_offset,
                          const TypedData* kernel_data) const {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  Zone* zone = thread->zone();
  const String& metaname = String::Handle(zone, Symbols::New(thread, name));
  const Field& field =
      Field::Handle(zone, Field::NewTopLevel(metaname,
                                             false,  // is_final
                                             false,  // is_const
                                             owner, token_pos));
  field.SetFieldType(Object::dynamic_type());
  field.set_is_reflectable(false);
  field.SetStaticValue(Array::empty_array(), true);
  field.set_kernel_offset(kernel_offset);
  if (kernel_data != NULL) {
    field.set_kernel_data(*kernel_data);
  }
  GrowableObjectArray& metadata =
      GrowableObjectArray::Handle(zone, this->metadata());
  metadata.Add(field, Heap::kOld);
}

void Library::AddClassMetadata(const Class& cls,
                               const Object& tl_owner,
                               TokenPosition token_pos,
                               intptr_t kernel_offset,
                               const TypedData* kernel_data) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  // We use the toplevel class as the owner of a class's metadata field because
  // a class's metadata is in scope of the library, not the class.
  AddMetadata(tl_owner,
              String::Handle(zone, MakeClassMetaName(thread, zone, cls)),
              token_pos, kernel_offset, kernel_data);
}

void Library::AddFieldMetadata(const Field& field,
                               TokenPosition token_pos,
                               intptr_t kernel_offset,
                               const TypedData* kernel_data) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  AddMetadata(Object::Handle(zone, field.RawOwner()),
              String::Handle(zone, MakeFieldMetaName(thread, zone, field)),
              token_pos, kernel_offset, kernel_data);
}

void Library::AddFunctionMetadata(const Function& func,
                                  TokenPosition token_pos,
                                  intptr_t kernel_offset,
                                  const TypedData* kernel_data) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  AddMetadata(Object::Handle(zone, func.RawOwner()),
              String::Handle(zone, MakeFunctionMetaName(thread, zone, func)),
              token_pos, kernel_offset, kernel_data);
}

void Library::AddTypeParameterMetadata(const TypeParameter& param,
                                       TokenPosition token_pos) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  AddMetadata(
      Class::Handle(zone, param.parameterized_class()),
      String::Handle(zone, MakeTypeParameterMetaName(thread, zone, param)),
      token_pos);
}

void Library::AddLibraryMetadata(const Object& tl_owner,
                                 TokenPosition token_pos) const {
  AddMetadata(tl_owner, Symbols::TopLevel(), token_pos);
}

RawString* Library::MakeMetadataName(const Object& obj) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  if (obj.IsClass()) {
    return MakeClassMetaName(thread, zone, Class::Cast(obj));
  } else if (obj.IsField()) {
    return MakeFieldMetaName(thread, zone, Field::Cast(obj));
  } else if (obj.IsFunction()) {
    return MakeFunctionMetaName(thread, zone, Function::Cast(obj));
  } else if (obj.IsLibrary()) {
    return Symbols::TopLevel().raw();
  } else if (obj.IsTypeParameter()) {
    return MakeTypeParameterMetaName(thread, zone, TypeParameter::Cast(obj));
  }
  UNIMPLEMENTED();
  return String::null();
}

RawField* Library::GetMetadataField(const String& metaname) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  const GrowableObjectArray& metadata =
      GrowableObjectArray::Handle(this->metadata());
  Field& entry = Field::Handle();
  String& entryname = String::Handle();
  intptr_t num_entries = metadata.Length();
  for (intptr_t i = 0; i < num_entries; i++) {
    entry ^= metadata.At(i);
    entryname = entry.name();
    if (entryname.Equals(metaname)) {
      return entry.raw();
    }
  }
  return Field::null();
}

RawObject* Library::GetMetadata(const Object& obj) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Object::empty_array().raw();
#else
  if (!obj.IsClass() && !obj.IsField() && !obj.IsFunction() &&
      !obj.IsLibrary() && !obj.IsTypeParameter()) {
    return Object::null();
  }
  const String& metaname = String::Handle(MakeMetadataName(obj));
  Field& field = Field::Handle(GetMetadataField(metaname));
  if (field.IsNull()) {
    // There is no metadata for this object.
    return Object::empty_array().raw();
  }
  Object& metadata = Object::Handle();
  metadata = field.StaticValue();
  if (field.StaticValue() == Object::empty_array().raw()) {
    if (field.kernel_offset() > 0) {
      metadata = kernel::EvaluateMetadata(field);
    } else {
      metadata = Parser::ParseMetadata(field);
    }
    if (metadata.IsArray()) {
      ASSERT(Array::Cast(metadata).raw() != Object::empty_array().raw());
      field.SetStaticValue(Array::Cast(metadata), true);
    }
  }
  return metadata.raw();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

static bool ShouldBePrivate(const String& name) {
  return (name.Length() >= 1 && name.CharAt(0) == '_') ||
         (name.Length() >= 5 &&
          (name.CharAt(4) == '_' &&
           (name.CharAt(0) == 'g' || name.CharAt(0) == 's') &&
           name.CharAt(1) == 'e' && name.CharAt(2) == 't' &&
           name.CharAt(3) == ':'));
}

RawObject* Library::ResolveName(const String& name) const {
  Object& obj = Object::Handle();
  if (FLAG_use_lib_cache && LookupResolvedNamesCache(name, &obj)) {
    return obj.raw();
  }
  obj = LookupLocalObject(name);
  if (!obj.IsNull()) {
    // Names that are in this library's dictionary and are unmangled
    // are not cached. This reduces the size of the cache.
    return obj.raw();
  }
  String& accessor_name = String::Handle(Field::LookupGetterSymbol(name));
  if (!accessor_name.IsNull()) {
    obj = LookupLocalObject(accessor_name);
  }
  if (obj.IsNull()) {
    accessor_name = Field::LookupSetterSymbol(name);
    if (!accessor_name.IsNull()) {
      obj = LookupLocalObject(accessor_name);
    }
    if (obj.IsNull() && !ShouldBePrivate(name)) {
      obj = LookupImportedObject(name);
    }
  }
  AddToResolvedNamesCache(name, obj);
  return obj.raw();
}

class StringEqualsTraits {
 public:
  static const char* Name() { return "StringEqualsTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    return String::Cast(a).Equals(String::Cast(b));
  }
  static uword Hash(const Object& obj) { return String::Cast(obj).Hash(); }
};
typedef UnorderedHashMap<StringEqualsTraits> ResolvedNamesMap;

// Returns true if the name is found in the cache, false no cache hit.
// obj is set to the cached entry. It may be null, indicating that the
// name does not resolve to anything in this library.
bool Library::LookupResolvedNamesCache(const String& name, Object* obj) const {
  if (resolved_names() == Array::null()) {
    return false;
  }
  ResolvedNamesMap cache(resolved_names());
  bool present = false;
  *obj = cache.GetOrNull(name, &present);
// Mutator compiler thread may add entries and therefore
// change 'resolved_names()' while running a background compilation;
// ASSERT that 'resolved_names()' has not changed only in mutator.
#if defined(DEBUG)
  if (Thread::Current()->IsMutatorThread()) {
    ASSERT(cache.Release().raw() == resolved_names());
  } else {
    // Release must be called in debug mode.
    cache.Release();
  }
#endif
  return present;
}

// Add a name to the resolved name cache. This name resolves to the
// given object in this library scope. obj may be null, which means
// the name does not resolve to anything in this library scope.
void Library::AddToResolvedNamesCache(const String& name,
                                      const Object& obj) const {
  if (!FLAG_use_lib_cache || Compiler::IsBackgroundCompilation()) {
    return;
  }
  if (resolved_names() == Array::null()) {
    InitResolvedNamesCache();
  }
  ResolvedNamesMap cache(resolved_names());
  cache.UpdateOrInsert(name, obj);
  StorePointer(&raw_ptr()->resolved_names_, cache.Release().raw());
}

bool Library::LookupExportedNamesCache(const String& name, Object* obj) const {
  ASSERT(FLAG_use_exp_cache);
  if (exported_names() == Array::null()) {
    return false;
  }
  ResolvedNamesMap cache(exported_names());
  bool present = false;
  *obj = cache.GetOrNull(name, &present);
// Mutator compiler thread may add entries and therefore
// change 'exported_names()' while running a background compilation;
// do not ASSERT that 'exported_names()' has not changed.
#if defined(DEBUG)
  if (Thread::Current()->IsMutatorThread()) {
    ASSERT(cache.Release().raw() == exported_names());
  } else {
    // Release must be called in debug mode.
    cache.Release();
  }
#endif
  return present;
}

void Library::AddToExportedNamesCache(const String& name,
                                      const Object& obj) const {
  if (!FLAG_use_exp_cache || Compiler::IsBackgroundCompilation()) {
    return;
  }
  if (exported_names() == Array::null()) {
    InitExportedNamesCache();
  }
  ResolvedNamesMap cache(exported_names());
  cache.UpdateOrInsert(name, obj);
  StorePointer(&raw_ptr()->exported_names_, cache.Release().raw());
}

void Library::InvalidateResolvedName(const String& name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Object& entry = Object::Handle(zone);
  if (LookupResolvedNamesCache(name, &entry)) {
    // TODO(koda): Support deleted sentinel in snapshots and remove only 'name'.
    ClearResolvedNamesCache();
  }
  // When a new name is added to a library, we need to invalidate all
  // caches that contain an entry for this name. If the name was previously
  // looked up but could not be resolved, the cache contains a null entry.
  GrowableObjectArray& libs = GrowableObjectArray::Handle(
      zone, thread->isolate()->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  intptr_t num_libs = libs.Length();
  for (intptr_t i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    if (lib.LookupExportedNamesCache(name, &entry)) {
      lib.ClearExportedNamesCache();
    }
  }
}

// Invalidate all exported names caches in the isolate.
void Library::InvalidateExportedNamesCaches() {
  GrowableObjectArray& libs = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  Library& lib = Library::Handle();
  intptr_t num_libs = libs.Length();
  for (intptr_t i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    lib.ClearExportedNamesCache();
  }
}

void Library::RehashDictionary(const Array& old_dict,
                               intptr_t new_dict_size) const {
  intptr_t old_dict_size = old_dict.Length() - 1;
  const Array& new_dict =
      Array::Handle(Array::New(new_dict_size + 1, Heap::kOld));
  // Rehash all elements from the original dictionary
  // to the newly allocated array.
  Object& entry = Class::Handle();
  String& entry_name = String::Handle();
  Object& new_entry = Object::Handle();
  intptr_t used = 0;
  for (intptr_t i = 0; i < old_dict_size; i++) {
    entry = old_dict.At(i);
    if (!entry.IsNull()) {
      entry_name = entry.DictionaryName();
      ASSERT(!entry_name.IsNull());
      const intptr_t hash = entry_name.Hash();
      intptr_t index = hash % new_dict_size;
      new_entry = new_dict.At(index);
      while (!new_entry.IsNull()) {
        index = (index + 1) % new_dict_size;  // Move to next element.
        new_entry = new_dict.At(index);
      }
      new_dict.SetAt(index, entry);
      used++;
    }
  }
  // Set used count.
  ASSERT(used < new_dict_size);  // Need at least one empty slot.
  new_entry = Smi::New(used);
  new_dict.SetAt(new_dict_size, new_entry);
  // Remember the new dictionary now.
  StorePointer(&raw_ptr()->dictionary_, new_dict.raw());
}

void Library::AddObject(const Object& obj, const String& name) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(obj.IsClass() || obj.IsFunction() || obj.IsField() ||
         obj.IsLibraryPrefix());
  ASSERT(name.Equals(String::Handle(obj.DictionaryName())));
  ASSERT(LookupLocalObject(name) == Object::null());
  const Array& dict = Array::Handle(dictionary());
  intptr_t dict_size = dict.Length() - 1;
  intptr_t index = name.Hash() % dict_size;

  Object& entry = Object::Handle();
  entry = dict.At(index);
  // An empty spot will be found because we keep the hash set at most 75% full.
  while (!entry.IsNull()) {
    index = (index + 1) % dict_size;
    entry = dict.At(index);
  }

  // Insert the object at the empty slot.
  dict.SetAt(index, obj);
  // One more element added.
  intptr_t used_elements = Smi::Value(Smi::RawCast(dict.At(dict_size))) + 1;
  const Smi& used = Smi::Handle(Smi::New(used_elements));
  dict.SetAt(dict_size, used);  // Update used count.

  // Rehash if symbol_table is 75% full.
  if (used_elements > ((dict_size / 4) * 3)) {
    // TODO(iposva): Avoid exponential growth.
    RehashDictionary(dict, 2 * dict_size);
  }

  // Invalidate the cache of loaded scripts.
  if (loaded_scripts() != Array::null()) {
    StorePointer(&raw_ptr()->loaded_scripts_, Array::null());
  }
}

// Lookup a name in the library's re-export namespace.
// This lookup can occur from two different threads: background compiler and
// mutator thread.
RawObject* Library::LookupReExport(const String& name,
                                   ZoneGrowableArray<intptr_t>* trail) const {
  if (!HasExports()) {
    return Object::null();
  }

  if (trail == NULL) {
    trail = new ZoneGrowableArray<intptr_t>();
  }
  Object& obj = Object::Handle();
  if (FLAG_use_exp_cache && LookupExportedNamesCache(name, &obj)) {
    return obj.raw();
  }

  const intptr_t lib_id = this->index();
  ASSERT(lib_id >= 0);  // We use -1 to indicate that a cycle was found.
  trail->Add(lib_id);
  const Array& exports = Array::Handle(this->exports());
  Namespace& ns = Namespace::Handle();
  for (int i = 0; i < exports.Length(); i++) {
    ns ^= exports.At(i);
    obj = ns.Lookup(name, trail);
    if (!obj.IsNull()) {
      // The Lookup call above may return a setter x= when we are looking
      // for the name x. Make sure we only return when a matching name
      // is found.
      String& obj_name = String::Handle(obj.DictionaryName());
      if (Field::IsSetterName(obj_name) == Field::IsSetterName(name)) {
        break;
      }
    }
  }
  bool in_cycle = (trail->RemoveLast() < 0);
  if (FLAG_use_exp_cache && !in_cycle && !Compiler::IsBackgroundCompilation()) {
    AddToExportedNamesCache(name, obj);
  }
  return obj.raw();
}

RawObject* Library::LookupEntry(const String& name, intptr_t* index) const {
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& dict = thread->ArrayHandle();
  dict ^= dictionary();
  intptr_t dict_size = dict.Length() - 1;
  *index = name.Hash() % dict_size;
  Object& entry = thread->ObjectHandle();
  String& entry_name = thread->StringHandle();
  entry = dict.At(*index);
  // Search the entry in the hash set.
  while (!entry.IsNull()) {
    entry_name = entry.DictionaryName();
    ASSERT(!entry_name.IsNull());
    if (entry_name.Equals(name)) {
      return entry.raw();
    }
    *index = (*index + 1) % dict_size;
    entry = dict.At(*index);
  }
  return Object::null();
}

void Library::ReplaceObject(const Object& obj, const String& name) const {
  ASSERT(!Compiler::IsBackgroundCompilation());
  ASSERT(obj.IsClass() || obj.IsFunction() || obj.IsField());
  ASSERT(LookupLocalObject(name) != Object::null());

  intptr_t index;
  LookupEntry(name, &index);
  // The value is guaranteed to be found.
  const Array& dict = Array::Handle(dictionary());
  dict.SetAt(index, obj);
}

void Library::AddClass(const Class& cls) const {
  ASSERT(!Compiler::IsBackgroundCompilation());
  const String& class_name = String::Handle(cls.Name());
  AddObject(cls, class_name);
  // Link class to this library.
  cls.set_library(*this);
  InvalidateResolvedName(class_name);
}

static void AddScriptIfUnique(const GrowableObjectArray& scripts,
                              const Script& candidate) {
  if (candidate.IsNull()) {
    return;
  }
  Script& script_obj = Script::Handle();

  for (int i = 0; i < scripts.Length(); i++) {
    script_obj ^= scripts.At(i);
    if (script_obj.raw() == candidate.raw()) {
      // We already have a reference to this script.
      return;
    }
  }
  // Add script to the list of scripts.
  scripts.Add(candidate);
}

RawArray* Library::LoadedScripts() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  // We compute the list of loaded scripts lazily. The result is
  // cached in loaded_scripts_.
  if (loaded_scripts() == Array::null()) {
    // Iterate over the library dictionary and collect all scripts.
    const GrowableObjectArray& scripts =
        GrowableObjectArray::Handle(GrowableObjectArray::New(8));
    Object& entry = Object::Handle();
    Class& cls = Class::Handle();
    Script& owner_script = Script::Handle();
    DictionaryIterator it(*this);
    while (it.HasNext()) {
      entry = it.GetNext();
      if (entry.IsClass()) {
        owner_script = Class::Cast(entry).script();
      } else if (entry.IsFunction()) {
        owner_script = Function::Cast(entry).script();
      } else if (entry.IsField()) {
        owner_script = Field::Cast(entry).Script();
      } else {
        continue;
      }
      AddScriptIfUnique(scripts, owner_script);
    }

    // Add all scripts from patch classes.
    GrowableObjectArray& patches = GrowableObjectArray::Handle(patch_classes());
    for (intptr_t i = 0; i < patches.Length(); i++) {
      entry = patches.At(i);
      if (entry.IsClass()) {
        owner_script = Class::Cast(entry).script();
      } else {
        ASSERT(entry.IsScript());
        owner_script = Script::Cast(entry).raw();
      }
      AddScriptIfUnique(scripts, owner_script);
    }

    cls ^= toplevel_class();
    if (!cls.IsNull()) {
      owner_script = cls.script();
      AddScriptIfUnique(scripts, owner_script);
      // Special case: Scripts that only contain external top-level functions
      // are not included above, but can be referenced through a library's
      // anonymous classes. Example: dart-core:identical.dart.
      Function& func = Function::Handle();
      Array& functions = Array::Handle(cls.functions());
      for (intptr_t j = 0; j < functions.Length(); j++) {
        func ^= functions.At(j);
        if (func.is_external()) {
          owner_script = func.script();
          AddScriptIfUnique(scripts, owner_script);
        }
      }
    }

    // Create the array of scripts and cache it in loaded_scripts_.
    const Array& scripts_array = Array::Handle(Array::MakeFixedLength(scripts));
    StorePointer(&raw_ptr()->loaded_scripts_, scripts_array.raw());
  }
  return loaded_scripts();
}

// TODO(hausner): we might want to add a script dictionary to the
// library class to make this lookup faster.
RawScript* Library::LookupScript(const String& url) const {
  const intptr_t url_length = url.Length();
  if (url_length == 0) {
    return Script::null();
  }
  const Array& scripts = Array::Handle(LoadedScripts());
  Script& script = Script::Handle();
  String& script_url = String::Handle();
  const intptr_t num_scripts = scripts.Length();
  for (int i = 0; i < num_scripts; i++) {
    script ^= scripts.At(i);
    script_url = script.url();
    const intptr_t start_idx = script_url.Length() - url_length;
    if ((start_idx == 0) && url.Equals(script_url)) {
      return script.raw();
    } else if (start_idx > 0) {
      // If we do a suffix match, only match if the partial path
      // starts at or immediately after the path separator.
      if (((url.CharAt(0) == '/') ||
           (script_url.CharAt(start_idx - 1) == '/')) &&
          url.Equals(script_url, start_idx, url_length)) {
        return script.raw();
      }
    }
  }
  return Script::null();
}

RawObject* Library::LookupLocalObject(const String& name) const {
  intptr_t index;
  return LookupEntry(name, &index);
}

RawField* Library::LookupFieldAllowPrivate(const String& name) const {
  Object& obj = Object::Handle(LookupObjectAllowPrivate(name));
  if (obj.IsField()) {
    return Field::Cast(obj).raw();
  }
  return Field::null();
}

RawField* Library::LookupLocalField(const String& name) const {
  Object& obj = Object::Handle(LookupLocalObjectAllowPrivate(name));
  if (obj.IsField()) {
    return Field::Cast(obj).raw();
  }
  return Field::null();
}

RawFunction* Library::LookupFunctionAllowPrivate(const String& name) const {
  Object& obj = Object::Handle(LookupObjectAllowPrivate(name));
  if (obj.IsFunction()) {
    return Function::Cast(obj).raw();
  }
  return Function::null();
}

RawFunction* Library::LookupLocalFunction(const String& name) const {
  Object& obj = Object::Handle(LookupLocalObjectAllowPrivate(name));
  if (obj.IsFunction()) {
    return Function::Cast(obj).raw();
  }
  return Function::null();
}

RawObject* Library::LookupLocalObjectAllowPrivate(const String& name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Object& obj = Object::Handle(zone, Object::null());
  obj = LookupLocalObject(name);
  if (obj.IsNull() && ShouldBePrivate(name)) {
    String& private_name = String::Handle(zone, PrivateName(name));
    obj = LookupLocalObject(private_name);
  }
  return obj.raw();
}

RawObject* Library::LookupObjectAllowPrivate(const String& name) const {
  // First check if name is found in the local scope of the library.
  Object& obj = Object::Handle(LookupLocalObjectAllowPrivate(name));
  if (!obj.IsNull()) {
    return obj.raw();
  }

  // Do not look up private names in imported libraries.
  if (ShouldBePrivate(name)) {
    return Object::null();
  }

  // Now check if name is found in any imported libs.
  return LookupImportedObject(name);
}

RawObject* Library::LookupImportedObject(const String& name) const {
  Object& obj = Object::Handle();
  Namespace& import = Namespace::Handle();
  Library& import_lib = Library::Handle();
  String& import_lib_url = String::Handle();
  String& first_import_lib_url = String::Handle();
  Object& found_obj = Object::Handle();
  String& found_obj_name = String::Handle();
  ASSERT(!ShouldBePrivate(name));
  for (intptr_t i = 0; i < num_imports(); i++) {
    import ^= ImportAt(i);
    obj = import.Lookup(name);
    if (!obj.IsNull()) {
      import_lib = import.library();
      import_lib_url = import_lib.url();
      if (found_obj.raw() != obj.raw()) {
        if (first_import_lib_url.IsNull() ||
            first_import_lib_url.StartsWith(Symbols::DartScheme())) {
          // This is the first object we found, or the
          // previously found object is exported from a Dart
          // system library. The newly found object hides the one
          // from the Dart library.
          first_import_lib_url = import_lib.url();
          found_obj = obj.raw();
          found_obj_name = obj.DictionaryName();
        } else if (import_lib_url.StartsWith(Symbols::DartScheme())) {
          // The newly found object is exported from a Dart system
          // library. It is hidden by the previously found object.
          // We continue to search.
        } else if (Field::IsSetterName(found_obj_name) &&
                   !Field::IsSetterName(name)) {
          // We are looking for an unmangled name or a getter, but
          // the first object we found is a setter. Replace the first
          // object with the one we just found.
          first_import_lib_url = import_lib.url();
          found_obj = obj.raw();
          found_obj_name = found_obj.DictionaryName();
        } else {
          // We found two different objects with the same name.
          // Note that we need to compare the names again because
          // looking up an unmangled name can return a getter or a
          // setter. A getter name is the same as the unmangled name,
          // but a setter name is different from an unmangled name or a
          // getter name.
          if (Field::IsGetterName(found_obj_name)) {
            found_obj_name = Field::NameFromGetter(found_obj_name);
          }
          String& second_obj_name = String::Handle(obj.DictionaryName());
          if (Field::IsGetterName(second_obj_name)) {
            second_obj_name = Field::NameFromGetter(second_obj_name);
          }
          if (found_obj_name.Equals(second_obj_name)) {
            return Object::null();
          }
        }
      }
    }
  }
  return found_obj.raw();
}

RawClass* Library::LookupClass(const String& name) const {
  Object& obj = Object::Handle(ResolveName(name));
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  return Class::null();
}

RawClass* Library::LookupLocalClass(const String& name) const {
  Object& obj = Object::Handle(LookupLocalObject(name));
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  return Class::null();
}

RawClass* Library::LookupClassAllowPrivate(const String& name) const {
  // See if the class is available in this library or in the top level
  // scope of any imported library.
  Zone* zone = Thread::Current()->zone();
  const Class& cls = Class::Handle(zone, LookupClass(name));
  if (!cls.IsNull()) {
    return cls.raw();
  }

  // Now try to lookup the class using its private name, but only in
  // this library (not in imported libraries).
  if (ShouldBePrivate(name)) {
    String& private_name = String::Handle(zone, PrivateName(name));
    const Object& obj = Object::Handle(LookupLocalObject(private_name));
    if (obj.IsClass()) {
      return Class::Cast(obj).raw();
    }
  }
  return Class::null();
}

// Mixin applications can have multiple private keys from different libraries.
RawClass* Library::SlowLookupClassAllowMultiPartPrivate(
    const String& name) const {
  Array& dict = Array::Handle(dictionary());
  Object& entry = Object::Handle();
  String& cls_name = String::Handle();
  for (intptr_t i = 0; i < dict.Length(); i++) {
    entry = dict.At(i);
    if (entry.IsClass()) {
      cls_name = Class::Cast(entry).Name();
      // Warning: comparison is not symmetric.
      if (String::EqualsIgnoringPrivateKey(cls_name, name)) {
        return Class::Cast(entry).raw();
      }
    }
  }
  return Class::null();
}

RawLibraryPrefix* Library::LookupLocalLibraryPrefix(const String& name) const {
  const Object& obj = Object::Handle(LookupLocalObject(name));
  if (obj.IsLibraryPrefix()) {
    return LibraryPrefix::Cast(obj).raw();
  }
  return LibraryPrefix::null();
}

void Library::set_toplevel_class(const Class& value) const {
  ASSERT(raw_ptr()->toplevel_class_ == Class::null());
  StorePointer(&raw_ptr()->toplevel_class_, value.raw());
}

void Library::set_metadata(const GrowableObjectArray& value) const {
  StorePointer(&raw_ptr()->metadata_, value.raw());
}

RawLibrary* Library::ImportLibraryAt(intptr_t index) const {
  Namespace& import = Namespace::Handle(ImportAt(index));
  if (import.IsNull()) {
    return Library::null();
  }
  return import.library();
}

RawNamespace* Library::ImportAt(intptr_t index) const {
  if ((index < 0) || index >= num_imports()) {
    return Namespace::null();
  }
  const Array& import_list = Array::Handle(imports());
  return Namespace::RawCast(import_list.At(index));
}

bool Library::ImportsCorelib() const {
  Zone* zone = Thread::Current()->zone();
  Library& imported = Library::Handle(zone);
  intptr_t count = num_imports();
  for (int i = 0; i < count; i++) {
    imported = ImportLibraryAt(i);
    if (imported.IsCoreLibrary()) {
      return true;
    }
  }
  LibraryPrefix& prefix = LibraryPrefix::Handle(zone);
  LibraryPrefixIterator it(*this);
  while (it.HasNext()) {
    prefix = it.GetNext();
    count = prefix.num_imports();
    for (int i = 0; i < count; i++) {
      imported = prefix.GetLibrary(i);
      if (imported.IsCoreLibrary()) {
        return true;
      }
    }
  }
  return false;
}

void Library::DropDependenciesAndCaches() const {
  StorePointer(&raw_ptr()->imports_, Object::empty_array().raw());
  StorePointer(&raw_ptr()->exports_, Object::empty_array().raw());
  StoreNonPointer(&raw_ptr()->num_imports_, 0);
  StorePointer(&raw_ptr()->resolved_names_, Array::null());
  StorePointer(&raw_ptr()->exported_names_, Array::null());
  StorePointer(&raw_ptr()->loaded_scripts_, Array::null());
}

void Library::AddImport(const Namespace& ns) const {
  Array& imports = Array::Handle(this->imports());
  intptr_t capacity = imports.Length();
  if (num_imports() == capacity) {
    capacity = capacity + kImportsCapacityIncrement + (capacity >> 2);
    imports = Array::Grow(imports, capacity);
    StorePointer(&raw_ptr()->imports_, imports.raw());
  }
  intptr_t index = num_imports();
  imports.SetAt(index, ns);
  set_num_imports(index + 1);
}

// Convenience function to determine whether the export list is
// non-empty.
bool Library::HasExports() const {
  return exports() != Object::empty_array().raw();
}

// We add one namespace at a time to the exports array and don't
// pre-allocate any unused capacity. The assumption is that
// re-exports are quite rare.
void Library::AddExport(const Namespace& ns) const {
  Array& exports = Array::Handle(this->exports());
  intptr_t num_exports = exports.Length();
  exports = Array::Grow(exports, num_exports + 1);
  StorePointer(&raw_ptr()->exports_, exports.raw());
  exports.SetAt(num_exports, ns);
}

static RawArray* NewDictionary(intptr_t initial_size) {
  const Array& dict = Array::Handle(Array::New(initial_size + 1, Heap::kOld));
  // The last element of the dictionary specifies the number of in use slots.
  dict.SetAt(initial_size, Smi::Handle(Smi::New(0)));
  return dict.raw();
}

void Library::InitResolvedNamesCache() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  StorePointer(&raw_ptr()->resolved_names_,
               HashTables::New<ResolvedNamesMap>(64));
}

void Library::ClearResolvedNamesCache() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  StorePointer(&raw_ptr()->resolved_names_, Array::null());
}

void Library::InitExportedNamesCache() const {
  StorePointer(&raw_ptr()->exported_names_,
               HashTables::New<ResolvedNamesMap>(16));
}

void Library::ClearExportedNamesCache() const {
  StorePointer(&raw_ptr()->exported_names_, Array::null());
}

void Library::InitClassDictionary() const {
  // TODO(iposva): Find reasonable initial size.
  const int kInitialElementCount = 16;
  StorePointer(&raw_ptr()->dictionary_, NewDictionary(kInitialElementCount));
}

void Library::InitImportList() const {
  const Array& imports =
      Array::Handle(Array::New(kInitialImportsCapacity, Heap::kOld));
  StorePointer(&raw_ptr()->imports_, imports.raw());
  StoreNonPointer(&raw_ptr()->num_imports_, 0);
}

RawLibrary* Library::New() {
  ASSERT(Object::library_class() != Class::null());
  RawObject* raw =
      Object::Allocate(Library::kClassId, Library::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawLibrary*>(raw);
}

RawLibrary* Library::NewLibraryHelper(const String& url, bool import_core_lib) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());
  // Force the url to have a hash code.
  url.Hash();
  const bool dart_scheme = url.StartsWith(Symbols::DartScheme());
  const bool dart_private_scheme =
      dart_scheme && url.StartsWith(Symbols::DartSchemePrivate());
  const Library& result = Library::Handle(zone, Library::New());
  result.StorePointer(&result.raw_ptr()->name_, Symbols::Empty().raw());
  result.StorePointer(&result.raw_ptr()->url_, url.raw());
  result.StorePointer(&result.raw_ptr()->resolved_names_, Array::null());
  result.StorePointer(&result.raw_ptr()->exported_names_, Array::null());
  result.StorePointer(&result.raw_ptr()->dictionary_,
                      Object::empty_array().raw());
  result.StorePointer(&result.raw_ptr()->metadata_,
                      GrowableObjectArray::New(4, Heap::kOld));
  result.StorePointer(&result.raw_ptr()->toplevel_class_, Class::null());
  result.StorePointer(
      &result.raw_ptr()->patch_classes_,
      GrowableObjectArray::New(Object::empty_array(), Heap::kOld));
  result.StorePointer(&result.raw_ptr()->imports_, Object::empty_array().raw());
  result.StorePointer(&result.raw_ptr()->exports_, Object::empty_array().raw());
  result.StorePointer(&result.raw_ptr()->loaded_scripts_, Array::null());
  result.StorePointer(&result.raw_ptr()->load_error_, Instance::null());
  result.set_native_entry_resolver(NULL);
  result.set_native_entry_symbol_resolver(NULL);
  result.set_is_in_fullsnapshot(false);
  result.StoreNonPointer(&result.raw_ptr()->corelib_imported_, true);
  if (dart_private_scheme) {
    // Never debug dart:_ libraries.
    result.set_debuggable(false);
  } else if (dart_scheme) {
    // Only debug dart: libraries if we have been requested to show invisible
    // frames.
    result.set_debuggable(FLAG_show_invisible_frames);
  } else {
    // Default to debuggable for all other libraries.
    result.set_debuggable(true);
  }
  result.set_is_dart_scheme(dart_scheme);
  result.StoreNonPointer(&result.raw_ptr()->load_state_,
                         RawLibrary::kAllocated);
  result.StoreNonPointer(&result.raw_ptr()->index_, -1);
  result.InitClassDictionary();
  result.InitImportList();
  result.AllocatePrivateKey();
  if (import_core_lib) {
    const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
    ASSERT(!core_lib.IsNull());
    const Namespace& ns = Namespace::Handle(
        zone,
        Namespace::New(core_lib, Object::null_array(), Object::null_array()));
    result.AddImport(ns);
  }
  return result.raw();
}

RawLibrary* Library::New(const String& url) {
  return NewLibraryHelper(url, false);
}

void Library::InitCoreLibrary(Isolate* isolate) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const String& core_lib_url = Symbols::DartCore();
  const Library& core_lib =
      Library::Handle(zone, Library::NewLibraryHelper(core_lib_url, false));
  core_lib.SetLoadRequested();
  core_lib.Register(thread);
  isolate->object_store()->set_bootstrap_library(ObjectStore::kCore, core_lib);
  isolate->object_store()->set_root_library(Library::Handle());

  // Hook up predefined classes without setting their library pointers. These
  // classes are coming from the VM isolate, and are shared between multiple
  // isolates so setting their library pointers would be wrong.
  const Class& cls = Class::Handle(zone, Object::dynamic_class());
  core_lib.AddObject(cls, String::Handle(zone, cls.Name()));
}

RawObject* Library::Evaluate(const String& expr,
                             const Array& param_names,
                             const Array& param_values) const {
  // Evaluate the expression as a static function of the toplevel class.
  Class& top_level_class = Class::Handle(toplevel_class());
  ASSERT(top_level_class.is_finalized());
  return top_level_class.Evaluate(expr, param_names, param_values);
}

void Library::InitNativeWrappersLibrary(Isolate* isolate, bool is_kernel) {
  static const int kNumNativeWrappersClasses = 4;
  COMPILE_ASSERT((kNumNativeWrappersClasses > 0) &&
                 (kNumNativeWrappersClasses < 10));
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const String& native_flds_lib_url = Symbols::DartNativeWrappers();
  const Library& native_flds_lib = Library::Handle(
      zone, Library::NewLibraryHelper(native_flds_lib_url, false));
  const String& native_flds_lib_name = Symbols::DartNativeWrappersLibName();
  native_flds_lib.SetName(native_flds_lib_name);
  native_flds_lib.SetLoadRequested();
  native_flds_lib.Register(thread);
  native_flds_lib.SetLoadInProgress();
  isolate->object_store()->set_native_wrappers_library(native_flds_lib);
  static const char* const kNativeWrappersClass = "NativeFieldWrapperClass";
  static const int kNameLength = 25;
  ASSERT(kNameLength == (strlen(kNativeWrappersClass) + 1 + 1));
  char name_buffer[kNameLength];
  String& cls_name = String::Handle(zone);
  for (int fld_cnt = 1; fld_cnt <= kNumNativeWrappersClasses; fld_cnt++) {
    OS::SNPrint(name_buffer, kNameLength, "%s%d", kNativeWrappersClass,
                fld_cnt);
    cls_name = Symbols::New(thread, name_buffer);
    Class::NewNativeWrapper(native_flds_lib, cls_name, fld_cnt);
  }
  // NOTE: If we bootstrap from a Kernel IR file we want to generate the
  // synthetic constructors for the native wrapper classes.  We leave this up to
  // the [KernelLoader] who will take care of it later.
  if (!is_kernel) {
    native_flds_lib.SetLoaded();
  }
}

// LibraryLookupSet maps URIs to libraries.
class LibraryLookupTraits {
 public:
  static const char* Name() { return "LibraryLookupTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const String& a_str = String::Cast(a);
    const String& b_str = String::Cast(b);

    ASSERT(a_str.HasHash() && b_str.HasHash());
    return a_str.Equals(b_str);
  }

  static uword Hash(const Object& key) { return String::Cast(key).Hash(); }

  static RawObject* NewKey(const String& str) { return str.raw(); }
};
typedef UnorderedHashMap<LibraryLookupTraits> LibraryLookupMap;

// Returns library with given url in current isolate, or NULL.
RawLibrary* Library::LookupLibrary(Thread* thread, const String& url) {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();

  // Make sure the URL string has an associated hash code
  // to speed up the repeated equality checks.
  url.Hash();

  // Use the libraries map to lookup the library by URL.
  Library& lib = Library::Handle(zone);
  if (object_store->libraries_map() == Array::null()) {
    return Library::null();
  } else {
    LibraryLookupMap map(object_store->libraries_map());
    lib ^= map.GetOrNull(url);
    ASSERT(map.Release().raw() == object_store->libraries_map());
  }
  return lib.raw();
}

RawError* Library::Patch(const Script& script) const {
  ASSERT(script.kind() == RawScript::kPatchTag);
  return Compiler::Compile(*this, script);
}

bool Library::IsPrivate(const String& name) {
  if (ShouldBePrivate(name)) return true;
  // Factory names: List._fromLiteral.
  for (intptr_t i = 1; i < name.Length() - 1; i++) {
    if (name.CharAt(i) == '.') {
      if (name.CharAt(i + 1) == '_') {
        return true;
      }
    }
  }
  return false;
}

// Create a private key for this library. It is based on the hash of the
// library URI and the sequence number of the library to guarantee unique
// private keys without having to verify.
void Library::AllocatePrivateKey() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_support_reload && isolate->IsReloading()) {
    // When reloading, we need to make sure we use the original private key
    // if this library previously existed.
    IsolateReloadContext* reload_context = isolate->reload_context();
    const String& original_key =
        String::Handle(reload_context->FindLibraryPrivateKey(*this));
    if (!original_key.IsNull()) {
      StorePointer(&raw_ptr()->private_key_, original_key.raw());
      return;
    }
  }
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  // Format of the private key is: "@<sequence number><6 digits of hash>
  const intptr_t hash_mask = 0x7FFFF;

  const String& url = String::Handle(zone, this->url());
  intptr_t hash_value = url.Hash() & hash_mask;

  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  intptr_t sequence_value = libs.Length();

  char private_key[32];
  OS::SNPrint(private_key, sizeof(private_key), "%c%" Pd "%06" Pd "",
              kPrivateKeySeparator, sequence_value, hash_value);
  const String& key =
      String::Handle(zone, String::New(private_key, Heap::kOld));
  key.Hash();  // This string may end up in the VM isolate.
  StorePointer(&raw_ptr()->private_key_, key.raw());
}

const String& Library::PrivateCoreLibName(const String& member) {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const String& private_name = String::ZoneHandle(core_lib.PrivateName(member));
  return private_name;
}

RawClass* Library::LookupCoreClass(const String& class_name) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
  String& name = String::Handle(zone, class_name.raw());
  if (class_name.CharAt(0) == kPrivateIdentifierStart) {
    // Private identifiers are mangled on a per library basis.
    name = Symbols::FromConcat(thread, name,
                               String::Handle(zone, core_lib.private_key()));
  }
  return core_lib.LookupClass(name);
}

// Cannot handle qualified names properly as it only appends private key to
// the end (e.g. _Alfa.foo -> _Alfa.foo@...).
RawString* Library::PrivateName(const String& name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(IsPrivate(name));
  // ASSERT(strchr(name, '@') == NULL);
  String& str = String::Handle(zone);
  str = name.raw();
  str = Symbols::FromConcat(thread, str,
                            String::Handle(zone, this->private_key()));
  return str.raw();
}

RawLibrary* Library::GetLibrary(intptr_t index) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  ASSERT(!libs.IsNull());
  if ((0 <= index) && (index < libs.Length())) {
    Library& lib = Library::Handle(zone);
    lib ^= libs.At(index);
    return lib.raw();
  }
  return Library::null();
}

void Library::Register(Thread* thread) const {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();

  // A library is "registered" in two places:
  // - A growable array mapping from index to library.
  const String& lib_url = String::Handle(zone, url());
  ASSERT(Library::LookupLibrary(thread, lib_url) == Library::null());
  ASSERT(lib_url.HasHash());
  GrowableObjectArray& libs =
      GrowableObjectArray::Handle(zone, object_store->libraries());
  ASSERT(!libs.IsNull());
  set_index(libs.Length());
  libs.Add(*this);

  // - A map from URL string to library.
  if (object_store->libraries_map() == Array::null()) {
    LibraryLookupMap map(HashTables::New<LibraryLookupMap>(16, Heap::kOld));
    object_store->set_libraries_map(map.Release());
  }

  LibraryLookupMap map(object_store->libraries_map());
  bool present = map.UpdateOrInsert(lib_url, *this);
  ASSERT(!present);
  object_store->set_libraries_map(map.Release());
}

void Library::RegisterLibraries(Thread* thread,
                                const GrowableObjectArray& libs) {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Library& lib = Library::Handle(zone);
  String& lib_url = String::Handle(zone);

  LibraryLookupMap map(HashTables::New<LibraryLookupMap>(16, Heap::kOld));

  intptr_t len = libs.Length();
  for (intptr_t i = 0; i < len; i++) {
    lib ^= libs.At(i);
    lib_url = lib.url();
    map.InsertNewOrGetValue(lib_url, lib);
  }
  // Now rememeber these in the isolate's object store.
  isolate->object_store()->set_libraries(libs);
  isolate->object_store()->set_libraries_map(map.Release());
}

RawLibrary* Library::AsyncLibrary() {
  return Isolate::Current()->object_store()->async_library();
}

RawLibrary* Library::ConvertLibrary() {
  return Isolate::Current()->object_store()->convert_library();
}

RawLibrary* Library::CoreLibrary() {
  return Isolate::Current()->object_store()->core_library();
}

RawLibrary* Library::CollectionLibrary() {
  return Isolate::Current()->object_store()->collection_library();
}

RawLibrary* Library::DeveloperLibrary() {
  return Isolate::Current()->object_store()->developer_library();
}

RawLibrary* Library::InternalLibrary() {
  return Isolate::Current()->object_store()->_internal_library();
}

RawLibrary* Library::IsolateLibrary() {
  return Isolate::Current()->object_store()->isolate_library();
}

RawLibrary* Library::MathLibrary() {
  return Isolate::Current()->object_store()->math_library();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
RawLibrary* Library::MirrorsLibrary() {
  return Isolate::Current()->object_store()->mirrors_library();
}
#endif

RawLibrary* Library::NativeWrappersLibrary() {
  return Isolate::Current()->object_store()->native_wrappers_library();
}

RawLibrary* Library::ProfilerLibrary() {
  return Isolate::Current()->object_store()->profiler_library();
}

RawLibrary* Library::TypedDataLibrary() {
  return Isolate::Current()->object_store()->typed_data_library();
}

RawLibrary* Library::VMServiceLibrary() {
  return Isolate::Current()->object_store()->_vmservice_library();
}

const char* Library::ToCString() const {
  const String& name = String::Handle(url());
  return OS::SCreate(Thread::Current()->zone(), "Library:'%s'",
                     name.ToCString());
}

RawLibrary* LibraryPrefix::GetLibrary(int index) const {
  if ((index >= 0) || (index < num_imports())) {
    const Array& imports = Array::Handle(this->imports());
    Namespace& import = Namespace::Handle();
    import ^= imports.At(index);
    return import.library();
  }
  return Library::null();
}

RawInstance* LibraryPrefix::LoadError() const {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ObjectStore* object_store = isolate->object_store();
  GrowableObjectArray& libs =
      GrowableObjectArray::Handle(zone, object_store->libraries());
  ASSERT(!libs.IsNull());
  LibraryLoadErrorSet set(HashTables::New<LibraryLoadErrorSet>(libs.Length()));
  object_store->set_library_load_error_table(set.Release());
  Library& lib = Library::Handle(zone);
  Instance& error = Instance::Handle(zone);
  for (int32_t i = 0; i < num_imports(); i++) {
    lib = GetLibrary(i);
    ASSERT(!lib.IsNull());
    HANDLESCOPE(thread);
    error = lib.TransitiveLoadError();
    if (!error.IsNull()) {
      break;
    }
  }
  object_store->set_library_load_error_table(Object::empty_array());
  return error.raw();
}

bool LibraryPrefix::ContainsLibrary(const Library& library) const {
  int32_t num_current_imports = num_imports();
  if (num_current_imports > 0) {
    Library& lib = Library::Handle();
    const String& url = String::Handle(library.url());
    String& lib_url = String::Handle();
    for (int32_t i = 0; i < num_current_imports; i++) {
      lib = GetLibrary(i);
      ASSERT(!lib.IsNull());
      lib_url = lib.url();
      if (url.Equals(lib_url)) {
        return true;
      }
    }
  }
  return false;
}

void LibraryPrefix::AddImport(const Namespace& import) const {
  intptr_t num_current_imports = num_imports();

  // Prefixes with deferred libraries can only contain one library.
  ASSERT((num_current_imports == 0) || !is_deferred_load());

  // The library needs to be added to the list.
  Array& imports = Array::Handle(this->imports());
  const intptr_t length = (imports.IsNull()) ? 0 : imports.Length();
  // Grow the list if it is full.
  if (num_current_imports >= length) {
    const intptr_t new_length = length + kIncrementSize + (length >> 2);
    imports = Array::Grow(imports, new_length, Heap::kOld);
    set_imports(imports);
  }
  imports.SetAt(num_current_imports, import);
  set_num_imports(num_current_imports + 1);
}

RawObject* LibraryPrefix::LookupObject(const String& name) const {
  if (!is_loaded() && !FLAG_load_deferred_eagerly) {
    return Object::null();
  }
  Array& imports = Array::Handle(this->imports());
  Object& obj = Object::Handle();
  Namespace& import = Namespace::Handle();
  Library& import_lib = Library::Handle();
  String& import_lib_url = String::Handle();
  String& first_import_lib_url = String::Handle();
  Object& found_obj = Object::Handle();
  String& found_obj_name = String::Handle();
  for (intptr_t i = 0; i < num_imports(); i++) {
    import ^= imports.At(i);
    obj = import.Lookup(name);
    if (!obj.IsNull()) {
      import_lib = import.library();
      import_lib_url = import_lib.url();
      if (found_obj.raw() != obj.raw()) {
        if (first_import_lib_url.IsNull() ||
            first_import_lib_url.StartsWith(Symbols::DartScheme())) {
          // This is the first object we found, or the
          // previously found object is exported from a Dart
          // system library. The newly found object hides the one
          // from the Dart library.
          first_import_lib_url = import_lib.url();
          found_obj = obj.raw();
          found_obj_name = found_obj.DictionaryName();
        } else if (import_lib_url.StartsWith(Symbols::DartScheme())) {
          // The newly found object is exported from a Dart system
          // library. It is hidden by the previously found object.
          // We continue to search.
        } else if (Field::IsSetterName(found_obj_name) &&
                   !Field::IsSetterName(name)) {
          // We are looking for an unmangled name or a getter, but
          // the first object we found is a setter. Replace the first
          // object with the one we just found.
          first_import_lib_url = import_lib.url();
          found_obj = obj.raw();
          found_obj_name = found_obj.DictionaryName();
        } else {
          // We found two different objects with the same name.
          // Note that we need to compare the names again because
          // looking up an unmangled name can return a getter or a
          // setter. A getter name is the same as the unmangled name,
          // but a setter name is different from an unmangled name or a
          // getter name.
          if (Field::IsGetterName(found_obj_name)) {
            found_obj_name = Field::NameFromGetter(found_obj_name);
          }
          String& second_obj_name = String::Handle(obj.DictionaryName());
          if (Field::IsGetterName(second_obj_name)) {
            second_obj_name = Field::NameFromGetter(second_obj_name);
          }
          if (found_obj_name.Equals(second_obj_name)) {
            return Object::null();
          }
        }
      }
    }
  }
  return found_obj.raw();
}

RawClass* LibraryPrefix::LookupClass(const String& class_name) const {
  const Object& obj = Object::Handle(LookupObject(class_name));
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  return Class::null();
}

void LibraryPrefix::set_is_loaded() const {
  StoreNonPointer(&raw_ptr()->is_loaded_, true);
}

bool LibraryPrefix::LoadLibrary() const {
  // Non-deferred prefixes are loaded.
  ASSERT(is_deferred_load() || is_loaded());
  if (is_loaded()) {
    return true;  // Load request has already completed.
  }
  ASSERT(is_deferred_load());
  ASSERT(num_imports() == 1);
  if (Dart::vm_snapshot_kind() == Snapshot::kFullAOT) {
    // The library list was tree-shaken away.
    this->set_is_loaded();
    return true;
  }
  // This is a prefix for a deferred library. If the library is not loaded
  // yet and isn't being loaded, call the library tag handler to schedule
  // loading. Once all outstanding load requests have completed, the embedder
  // will call the core library to:
  // - invalidate dependent code of this prefix;
  // - mark this prefixes as loaded;
  // - complete the future associated with this prefix.
  const Library& deferred_lib = Library::Handle(GetLibrary(0));
  if (deferred_lib.Loaded()) {
    this->set_is_loaded();
    return true;
  } else if (deferred_lib.LoadNotStarted()) {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    Zone* zone = thread->zone();
    deferred_lib.SetLoadRequested();
    const GrowableObjectArray& pending_deferred_loads =
        GrowableObjectArray::Handle(
            isolate->object_store()->pending_deferred_loads());
    pending_deferred_loads.Add(deferred_lib);
    const String& lib_url = String::Handle(zone, deferred_lib.url());
    Dart_LibraryTagHandler handler = isolate->library_tag_handler();
    Object& obj = Object::Handle(zone);
    {
      TransitionVMToNative transition(thread);
      Api::Scope api_scope(thread);
      obj = Api::UnwrapHandle(handler(Dart_kImportTag,
                                      Api::NewHandle(thread, importer()),
                                      Api::NewHandle(thread, lib_url.raw())));
    }
    if (obj.IsError()) {
      Exceptions::PropagateError(Error::Cast(obj));
    }
  } else {
    // Another load request is in flight or previously failed.
    ASSERT(deferred_lib.LoadRequested() || deferred_lib.LoadFailed());
  }
  return false;  // Load request not yet completed.
}

RawArray* LibraryPrefix::dependent_code() const {
  return raw_ptr()->dependent_code_;
}

void LibraryPrefix::set_dependent_code(const Array& array) const {
  StorePointer(&raw_ptr()->dependent_code_, array.raw());
}

class PrefixDependentArray : public WeakCodeReferences {
 public:
  explicit PrefixDependentArray(const LibraryPrefix& prefix)
      : WeakCodeReferences(Array::Handle(prefix.dependent_code())),
        prefix_(prefix) {}

  virtual void UpdateArrayTo(const Array& value) {
    prefix_.set_dependent_code(value);
  }

  virtual void ReportDeoptimization(const Code& code) {
    // This gets called when the code object is on the stack
    // while nuking code that depends on a prefix. We don't expect
    // this to happen, so make sure we die loudly if we find
    // ourselves here.
    UNIMPLEMENTED();
  }

  virtual void ReportSwitchingCode(const Code& code) {
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      THR_Print("Prefix '%s': disabling %s code for %s function '%s'\n",
                String::Handle(prefix_.name()).ToCString(),
                code.is_optimized() ? "optimized" : "unoptimized",
                code.IsDisabled() ? "'patched'" : "'unpatched'",
                Function::Handle(code.function()).ToCString());
    }
  }

 private:
  const LibraryPrefix& prefix_;
  DISALLOW_COPY_AND_ASSIGN(PrefixDependentArray);
};

void LibraryPrefix::RegisterDependentCode(const Code& code) const {
  ASSERT(is_deferred_load());
  // In background compilation, a library can be loaded while we are compiling.
  // The generated code will be rejected in that case,
  ASSERT(!is_loaded() || Compiler::IsBackgroundCompilation());
  PrefixDependentArray a(*this);
  a.Register(code);
}

void LibraryPrefix::InvalidateDependentCode() const {
  PrefixDependentArray a(*this);
  a.DisableCode();
  set_is_loaded();
}

RawLibraryPrefix* LibraryPrefix::New() {
  RawObject* raw = Object::Allocate(LibraryPrefix::kClassId,
                                    LibraryPrefix::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawLibraryPrefix*>(raw);
}

RawLibraryPrefix* LibraryPrefix::New(const String& name,
                                     const Namespace& import,
                                     bool deferred_load,
                                     const Library& importer) {
  const LibraryPrefix& result = LibraryPrefix::Handle(LibraryPrefix::New());
  result.set_name(name);
  result.set_num_imports(0);
  result.set_importer(importer);
  result.StoreNonPointer(&result.raw_ptr()->is_deferred_load_, deferred_load);
  result.StoreNonPointer(&result.raw_ptr()->is_loaded_, !deferred_load);
  result.set_imports(Array::Handle(Array::New(kInitialSize)));
  result.AddImport(import);
  return result.raw();
}

void LibraryPrefix::set_name(const String& value) const {
  ASSERT(value.IsSymbol());
  StorePointer(&raw_ptr()->name_, value.raw());
}

void LibraryPrefix::set_imports(const Array& value) const {
  StorePointer(&raw_ptr()->imports_, value.raw());
}

void LibraryPrefix::set_num_imports(intptr_t value) const {
  if (!Utils::IsUint(16, value)) {
    ReportTooManyImports(Library::Handle(importer()));
  }
  StoreNonPointer(&raw_ptr()->num_imports_, value);
}

void LibraryPrefix::set_importer(const Library& value) const {
  StorePointer(&raw_ptr()->importer_, value.raw());
}

const char* LibraryPrefix::ToCString() const {
  const String& prefix = String::Handle(name());
  return OS::SCreate(Thread::Current()->zone(), "LibraryPrefix:'%s'",
                     prefix.ToCString());
}

void Namespace::set_metadata_field(const Field& value) const {
  StorePointer(&raw_ptr()->metadata_field_, value.raw());
}

void Namespace::AddMetadata(const Object& owner, TokenPosition token_pos) {
  ASSERT(Field::Handle(metadata_field()).IsNull());
  Field& field = Field::Handle(Field::NewTopLevel(Symbols::TopLevel(),
                                                  false,  // is_final
                                                  false,  // is_const
                                                  owner, token_pos));
  field.set_is_reflectable(false);
  field.SetFieldType(Object::dynamic_type());
  field.SetStaticValue(Array::empty_array(), true);
  set_metadata_field(field);
}

RawObject* Namespace::GetMetadata() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Object::empty_array().raw();
#else
  Field& field = Field::Handle(metadata_field());
  if (field.IsNull()) {
    // There is no metadata for this object.
    return Object::empty_array().raw();
  }
  Object& metadata = Object::Handle();
  metadata = field.StaticValue();
  if (field.StaticValue() == Object::empty_array().raw()) {
    metadata = Parser::ParseMetadata(field);
    if (metadata.IsArray()) {
      ASSERT(Array::Cast(metadata).raw() != Object::empty_array().raw());
      field.SetStaticValue(Array::Cast(metadata), true);
    }
  }
  return metadata.raw();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

const char* Namespace::ToCString() const {
  const Library& lib = Library::Handle(library());
  return OS::SCreate(Thread::Current()->zone(), "Namespace for library '%s'",
                     lib.ToCString());
}

bool Namespace::HidesName(const String& name) const {
  // Quick check for common case with no combinators.
  if (hide_names() == show_names()) {
    ASSERT(hide_names() == Array::null());
    return false;
  }
  const String* plain_name = &name;
  if (Field::IsGetterName(name)) {
    plain_name = &String::Handle(Field::NameFromGetter(name));
  } else if (Field::IsSetterName(name)) {
    plain_name = &String::Handle(Field::NameFromSetter(name));
  }
  // Check whether the name is in the list of explicitly hidden names.
  if (hide_names() != Array::null()) {
    const Array& names = Array::Handle(hide_names());
    String& hidden = String::Handle();
    intptr_t num_names = names.Length();
    for (intptr_t i = 0; i < num_names; i++) {
      hidden ^= names.At(i);
      if (plain_name->Equals(hidden)) {
        return true;
      }
    }
  }
  // The name is not explicitly hidden. Now check whether it is in the
  // list of explicitly visible names, if there is one.
  if (show_names() != Array::null()) {
    const Array& names = Array::Handle(show_names());
    String& shown = String::Handle();
    intptr_t num_names = names.Length();
    for (intptr_t i = 0; i < num_names; i++) {
      shown ^= names.At(i);
      if (plain_name->Equals(shown)) {
        return false;
      }
    }
    // There is a list of visible names. The name we're looking for is not
    // contained in the list, so it is hidden.
    return true;
  }
  // The name is not filtered out.
  return false;
}

// Look up object with given name in library and filter out hidden
// names. Also look up getters and setters.
RawObject* Namespace::Lookup(const String& name,
                             ZoneGrowableArray<intptr_t>* trail) const {
  Zone* zone = Thread::Current()->zone();
  const Library& lib = Library::Handle(zone, library());

  if (trail != NULL) {
    // Look for cycle in reexport graph.
    for (int i = 0; i < trail->length(); i++) {
      if (trail->At(i) == lib.index()) {
        for (int j = i + 1; j < trail->length(); j++) {
          (*trail)[j] = -1;
        }
        return Object::null();
      }
    }
  }

  intptr_t ignore = 0;
  // Lookup the name in the library's symbols.
  Object& obj = Object::Handle(zone, lib.LookupEntry(name, &ignore));
  if (!Field::IsGetterName(name) && !Field::IsSetterName(name) &&
      (obj.IsNull() || obj.IsLibraryPrefix())) {
    String& accessor_name = String::Handle(zone);
    accessor_name ^= Field::LookupGetterSymbol(name);
    if (!accessor_name.IsNull()) {
      obj = lib.LookupEntry(accessor_name, &ignore);
    }
    if (obj.IsNull()) {
      accessor_name ^= Field::LookupSetterSymbol(name);
      if (!accessor_name.IsNull()) {
        obj = lib.LookupEntry(accessor_name, &ignore);
      }
    }
  }

  // Library prefixes are not exported.
  if (obj.IsNull() || obj.IsLibraryPrefix()) {
    // Lookup in the re-exported symbols.
    obj = lib.LookupReExport(name, trail);
    if (obj.IsNull() && !Field::IsSetterName(name)) {
      // LookupReExport() only returns objects that match the given name.
      // If there is no field/func/getter, try finding a setter.
      const String& setter_name =
          String::Handle(zone, Field::LookupSetterSymbol(name));
      if (!setter_name.IsNull()) {
        obj = lib.LookupReExport(setter_name, trail);
      }
    }
  }
  if (obj.IsNull() || HidesName(name) || obj.IsLibraryPrefix()) {
    return Object::null();
  }
  return obj.raw();
}

RawNamespace* Namespace::New() {
  ASSERT(Object::namespace_class() != Class::null());
  RawObject* raw = Object::Allocate(Namespace::kClassId,
                                    Namespace::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawNamespace*>(raw);
}

RawNamespace* Namespace::New(const Library& library,
                             const Array& show_names,
                             const Array& hide_names) {
  ASSERT(show_names.IsNull() || (show_names.Length() > 0));
  ASSERT(hide_names.IsNull() || (hide_names.Length() > 0));
  const Namespace& result = Namespace::Handle(Namespace::New());
  result.StorePointer(&result.raw_ptr()->library_, library.raw());
  result.StorePointer(&result.raw_ptr()->show_names_, show_names.raw());
  result.StorePointer(&result.raw_ptr()->hide_names_, hide_names.raw());
  return result.raw();
}

RawError* Library::CompileAll() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Error& error = Error::Handle(zone);
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      error = cls.EnsureIsFinalized(thread);
      if (!error.IsNull()) {
        return error.raw();
      }
      error = Compiler::CompileAllFunctions(cls);
      if (!error.IsNull()) {
        return error.raw();
      }
    }
  }

  // Inner functions get added to the closures array. As part of compilation
  // more closures can be added to the end of the array. Compile all the
  // closures until we have reached the end of the "worklist".
  Object& result = Object::Handle(zone);
  const GrowableObjectArray& closures = GrowableObjectArray::Handle(
      zone, Isolate::Current()->object_store()->closure_functions());
  Function& func = Function::Handle(zone);
  for (int i = 0; i < closures.Length(); i++) {
    func ^= closures.At(i);
    if (!func.HasCode()) {
      result = Compiler::CompileFunction(thread, func);
      if (result.IsError()) {
        return Error::Cast(result).raw();
      }
      func.ClearICDataArray();
      func.ClearCode();
    }
  }
  return Error::null();
}

RawError* Library::ParseAll(Thread* thread) {
  Zone* zone = thread->zone();
  Error& error = Error::Handle(zone);
  Isolate* isolate = thread->isolate();
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      error = cls.EnsureIsFinalized(thread);
      if (!error.IsNull()) {
        return error.raw();
      }
      error = Compiler::ParseAllFunctions(cls);
      if (!error.IsNull()) {
        return error.raw();
      }
    }
  }

  // Inner functions get added to the closures array. As part of compilation
  // more closures can be added to the end of the array. Compile all the
  // closures until we have reached the end of the "worklist".
  const GrowableObjectArray& closures = GrowableObjectArray::Handle(
      zone, Isolate::Current()->object_store()->closure_functions());
  Function& func = Function::Handle(zone);
  for (int i = 0; i < closures.Length(); i++) {
    func ^= closures.At(i);
    if (!func.HasCode()) {
      error = Compiler::ParseFunction(thread, func);
      if (!error.IsNull()) {
        return error.raw();
      }
      func.ClearICDataArray();
      func.ClearCode();
    }
  }
  return error.raw();
}

// Return Function::null() if function does not exist in libs.
RawFunction* Library::GetFunction(const GrowableArray<Library*>& libs,
                                  const char* class_name,
                                  const char* function_name) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& func = Function::Handle(zone);
  String& class_str = String::Handle(zone);
  String& func_str = String::Handle(zone);
  Class& cls = Class::Handle(zone);
  for (intptr_t l = 0; l < libs.length(); l++) {
    const Library& lib = *libs[l];
    if (strcmp(class_name, "::") == 0) {
      func_str = Symbols::New(thread, function_name);
      func = lib.LookupFunctionAllowPrivate(func_str);
    } else {
      class_str = String::New(class_name);
      cls = lib.LookupClassAllowPrivate(class_str);
      if (!cls.IsNull()) {
        func_str = String::New(function_name);
        if (function_name[0] == '.') {
          func_str = String::Concat(class_str, func_str);
        }
        func = cls.LookupFunctionAllowPrivate(func_str);
      }
    }
    if (!func.IsNull()) {
      return func.raw();
    }
  }
  return Function::null();
}

RawObject* Library::GetFunctionClosure(const String& name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& func = Function::Handle(zone, LookupFunctionAllowPrivate(name));
  if (func.IsNull()) {
    // Check whether the function is reexported into the library.
    const Object& obj = Object::Handle(zone, LookupReExport(name));
    if (obj.IsFunction()) {
      func ^= obj.raw();
    } else {
      // Check if there is a getter of 'name', in which case invoke it
      // and return the result.
      const String& getter_name = String::Handle(zone, Field::GetterName(name));
      func = LookupFunctionAllowPrivate(getter_name);
      if (func.IsNull()) {
        return Closure::null();
      }
      // Invoke the getter and return the result.
      return DartEntry::InvokeFunction(func, Object::empty_array());
    }
  }
  func = func.ImplicitClosureFunction();
  return func.ImplicitStaticClosure();
}

#if defined(DART_NO_SNAPSHOT) && !defined(PRODUCT)
void Library::CheckFunctionFingerprints() {
  GrowableArray<Library*> all_libs;
  Function& func = Function::Handle();
  bool has_errors = false;

#define CHECK_FINGERPRINTS(class_name, function_name, dest, fp)                \
  func = GetFunction(all_libs, #class_name, #function_name);                   \
  if (func.IsNull()) {                                                         \
    has_errors = true;                                                         \
    OS::Print("Function not found %s.%s\n", #class_name, #function_name);      \
  } else {                                                                     \
    CHECK_FINGERPRINT3(func, class_name, function_name, dest, fp);             \
  }

#define CHECK_FINGERPRINTS2(class_name, function_name, dest, type, fp)         \
  CHECK_FINGERPRINTS(class_name, function_name, dest, fp)

  all_libs.Add(&Library::ZoneHandle(Library::CoreLibrary()));
  CORE_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS2);
  CORE_INTEGER_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS2);

  all_libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::CollectionLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::InternalLibrary()));
  OTHER_RECOGNIZED_LIST(CHECK_FINGERPRINTS2);
  INLINE_WHITE_LIST(CHECK_FINGERPRINTS);
  INLINE_BLACK_LIST(CHECK_FINGERPRINTS);
  POLYMORPHIC_TARGET_LIST(CHECK_FINGERPRINTS);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::DeveloperLibrary()));
  DEVELOPER_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS2);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  MATH_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS2);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  TYPED_DATA_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS2);

#undef CHECK_FINGERPRINTS
#undef CHECK_FINGERPRINTS2

#define CHECK_FACTORY_FINGERPRINTS(symbol, class_name, factory_name, cid, fp)  \
  func = GetFunction(all_libs, #class_name, #factory_name);                    \
  if (func.IsNull()) {                                                         \
    has_errors = true;                                                         \
    OS::Print("Function not found %s.%s\n", #class_name, #factory_name);       \
  } else {                                                                     \
    CHECK_FINGERPRINT2(func, symbol, cid, fp);                                 \
  }

  all_libs.Add(&Library::ZoneHandle(Library::CoreLibrary()));
  RECOGNIZED_LIST_FACTORY_LIST(CHECK_FACTORY_FINGERPRINTS);

#undef CHECK_FACTORY_FINGERPRINTS

  if (has_errors) {
    FATAL("Fingerprint mismatch.");
  }
}
#endif  // defined(DART_NO_SNAPSHOT) && !defined(PRODUCT).

RawInstructions* Instructions::New(intptr_t size, bool has_single_entry_point) {
  ASSERT(size >= 0);
  ASSERT(Object::instructions_class() != Class::null());
  if (size < 0 || size > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Instructions::New: invalid size %" Pd "\n", size);
  }
  Instructions& result = Instructions::Handle();
  {
    uword aligned_size = Instructions::InstanceSize(size);
    RawObject* raw =
        Object::Allocate(Instructions::kClassId, aligned_size, Heap::kCode);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetSize(size);
    result.SetHasSingleEntryPoint(has_single_entry_point);
  }
  return result.raw();
}

const char* Instructions::ToCString() const {
  return "Instructions";
}

// Encode integer |value| in SLEB128 format and store into |data|.
static void EncodeSLEB128(GrowableArray<uint8_t>* data, intptr_t value) {
  bool is_last_part = false;
  while (!is_last_part) {
    uint8_t part = value & 0x7f;
    value >>= 7;
    if ((value == 0 && (part & 0x40) == 0) ||
        (value == static_cast<intptr_t>(-1) && (part & 0x40) != 0)) {
      is_last_part = true;
    } else {
      part |= 0x80;
    }
    data->Add(part);
  }
}

// Decode integer in SLEB128 format from |data| and update |byte_index|.
static intptr_t DecodeSLEB128(const uint8_t* data,
                              const intptr_t data_length,
                              intptr_t* byte_index) {
  ASSERT(*byte_index < data_length);
  uword shift = 0;
  intptr_t value = 0;
  uint8_t part = 0;
  do {
    part = data[(*byte_index)++];
    value |= static_cast<intptr_t>(part & 0x7f) << shift;
    shift += 7;
  } while ((part & 0x80) != 0);

  if ((shift < (sizeof(value) * 8)) && ((part & 0x40) != 0)) {
    value |= static_cast<intptr_t>(kUwordMax << shift);
  }
  return value;
}

// Encode integer in SLEB128 format.
void PcDescriptors::EncodeInteger(GrowableArray<uint8_t>* data,
                                  intptr_t value) {
  return EncodeSLEB128(data, value);
}

// Decode SLEB128 encoded integer. Update byte_index to the next integer.
intptr_t PcDescriptors::DecodeInteger(intptr_t* byte_index) const {
  NoSafepointScope no_safepoint;
  const uint8_t* data = raw_ptr()->data();
  return DecodeSLEB128(data, Length(), byte_index);
}

RawObjectPool* ObjectPool::New(intptr_t len) {
  ASSERT(Object::object_pool_class() != Class::null());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ObjectPool::New: invalid length %" Pd "\n", len);
  }
  ObjectPool& result = ObjectPool::Handle();
  {
    uword size = ObjectPool::InstanceSize(len);
    RawObject* raw = Object::Allocate(ObjectPool::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
  }

  // TODO(fschneider): Compress info array to just use just enough bits for
  // the entry type enum.
  const TypedData& info_array = TypedData::Handle(
      TypedData::New(kTypedDataInt8ArrayCid, len, Heap::kOld));
  result.set_info_array(info_array);
  return result.raw();
}

void ObjectPool::set_info_array(const TypedData& info_array) const {
  StorePointer(&raw_ptr()->info_array_, info_array.raw());
}

ObjectPool::EntryType ObjectPool::InfoAt(intptr_t index) const {
  ObjectPoolInfo pool_info(*this);
  return pool_info.InfoAt(index);
}

const char* ObjectPool::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  return zone->PrintToString("ObjectPool len:%" Pd, Length());
}

void ObjectPool::DebugPrint() const {
  THR_Print("Object Pool: 0x%" Px "{\n", reinterpret_cast<uword>(raw()));
  for (intptr_t i = 0; i < Length(); i++) {
    intptr_t offset = OffsetFromIndex(i);
    THR_Print("  %" Pd " PP+0x%" Px ": ", i, offset);
    if (InfoAt(i) == kTaggedObject) {
      RawObject* obj = ObjectAt(i);
      THR_Print("0x%" Px " %s (obj)\n", reinterpret_cast<uword>(obj),
                Object::Handle(obj).ToCString());
    } else if (InfoAt(i) == kNativeEntry) {
      THR_Print("0x%" Px " (native entry)\n", RawValueAt(i));
    } else {
      THR_Print("0x%" Px " (raw)\n", RawValueAt(i));
    }
  }
  THR_Print("}\n");
}

intptr_t PcDescriptors::Length() const {
  return raw_ptr()->length_;
}

void PcDescriptors::SetLength(intptr_t value) const {
  StoreNonPointer(&raw_ptr()->length_, value);
}

void PcDescriptors::CopyData(GrowableArray<uint8_t>* delta_encoded_data) {
  NoSafepointScope no_safepoint;
  uint8_t* data = UnsafeMutableNonPointer(&raw_ptr()->data()[0]);
  for (intptr_t i = 0; i < delta_encoded_data->length(); ++i) {
    data[i] = (*delta_encoded_data)[i];
  }
}

RawPcDescriptors* PcDescriptors::New(GrowableArray<uint8_t>* data) {
  ASSERT(Object::pc_descriptors_class() != Class::null());
  Thread* thread = Thread::Current();
  PcDescriptors& result = PcDescriptors::Handle(thread->zone());
  {
    uword size = PcDescriptors::InstanceSize(data->length());
    RawObject* raw =
        Object::Allocate(PcDescriptors::kClassId, size, Heap::kOld);
    INC_STAT(thread, total_code_size, size);
    INC_STAT(thread, pc_desc_size, size);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(data->length());
    result.CopyData(data);
  }
  return result.raw();
}

RawPcDescriptors* PcDescriptors::New(intptr_t length) {
  ASSERT(Object::pc_descriptors_class() != Class::null());
  Thread* thread = Thread::Current();
  PcDescriptors& result = PcDescriptors::Handle(thread->zone());
  {
    uword size = PcDescriptors::InstanceSize(length);
    RawObject* raw =
        Object::Allocate(PcDescriptors::kClassId, size, Heap::kOld);
    INC_STAT(thread, total_code_size, size);
    INC_STAT(thread, pc_desc_size, size);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  return result.raw();
}

const char* PcDescriptors::KindAsStr(RawPcDescriptors::Kind kind) {
  switch (kind) {
    case RawPcDescriptors::kDeopt:
      return "deopt        ";
    case RawPcDescriptors::kIcCall:
      return "ic-call      ";
    case RawPcDescriptors::kUnoptStaticCall:
      return "unopt-call   ";
    case RawPcDescriptors::kRuntimeCall:
      return "runtime-call ";
    case RawPcDescriptors::kOsrEntry:
      return "osr-entry    ";
    case RawPcDescriptors::kRewind:
      return "rewind       ";
    case RawPcDescriptors::kOther:
      return "other        ";
    case RawPcDescriptors::kAnyKind:
      UNREACHABLE();
      break;
  }
  UNREACHABLE();
  return "";
}

void PcDescriptors::PrintHeaderString() {
  // 4 bits per hex digit + 2 for "0x".
  const int addr_width = (kBitsPerWord / 4) + 2;
  // "*" in a printf format specifier tells it to read the field width from
  // the printf argument list.
  THR_Print("%-*s\tkind    \tdeopt-id\ttok-ix\ttry-ix\n", addr_width, "pc");
}

const char* PcDescriptors::ToCString() const {
// "*" in a printf format specifier tells it to read the field width from
// the printf argument list.
#define FORMAT "%#-*" Px "\t%s\t%" Pd "\t\t%s\t%" Pd "\n"
  if (Length() == 0) {
    return "empty PcDescriptors\n";
  }
  // 4 bits per hex digit.
  const int addr_width = kBitsPerWord / 4;
  // First compute the buffer size required.
  intptr_t len = 1;  // Trailing '\0'.
  {
    Iterator iter(*this, RawPcDescriptors::kAnyKind);
    while (iter.MoveNext()) {
      len += OS::SNPrint(NULL, 0, FORMAT, addr_width, iter.PcOffset(),
                         KindAsStr(iter.Kind()), iter.DeoptId(),
                         iter.TokenPos().ToCString(), iter.TryIndex());
    }
  }
  // Allocate the buffer.
  char* buffer = Thread::Current()->zone()->Alloc<char>(len);
  // Layout the fields in the buffer.
  intptr_t index = 0;
  Iterator iter(*this, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    index +=
        OS::SNPrint((buffer + index), (len - index), FORMAT, addr_width,
                    iter.PcOffset(), KindAsStr(iter.Kind()), iter.DeoptId(),
                    iter.TokenPos().ToCString(), iter.TryIndex());
  }
  return buffer;
#undef FORMAT
}

// Verify assumptions (in debug mode only).
// - No two deopt descriptors have the same deoptimization id.
// - No two ic-call descriptors have the same deoptimization id (type feedback).
// A function without unique ids is marked as non-optimizable (e.g., because of
// finally blocks).
void PcDescriptors::Verify(const Function& function) const {
#if defined(DEBUG)
  // Only check ids for unoptimized code that is optimizable.
  if (!function.IsOptimizable()) {
    return;
  }
  intptr_t max_deopt_id = 0;
  Iterator max_iter(*this,
                    RawPcDescriptors::kDeopt | RawPcDescriptors::kIcCall);
  while (max_iter.MoveNext()) {
    if (max_iter.DeoptId() > max_deopt_id) {
      max_deopt_id = max_iter.DeoptId();
    }
  }

  Zone* zone = Thread::Current()->zone();
  BitVector* deopt_ids = new (zone) BitVector(zone, max_deopt_id + 1);
  BitVector* iccall_ids = new (zone) BitVector(zone, max_deopt_id + 1);
  Iterator iter(*this, RawPcDescriptors::kDeopt | RawPcDescriptors::kIcCall);
  while (iter.MoveNext()) {
    // 'deopt_id' is set for kDeopt and kIcCall and must be unique for one kind.
    if (Thread::IsDeoptAfter(iter.DeoptId())) {
      // TODO(vegorov): some instructions contain multiple calls and have
      // multiple "after" targets recorded. Right now it is benign but might
      // lead to issues in the future. Fix that and enable verification.
      continue;
    }
    if (iter.Kind() == RawPcDescriptors::kDeopt) {
      ASSERT(!deopt_ids->Contains(iter.DeoptId()));
      deopt_ids->Add(iter.DeoptId());
    } else {
      ASSERT(!iccall_ids->Contains(iter.DeoptId()));
      iccall_ids->Add(iter.DeoptId());
    }
  }
#endif  // DEBUG
}

void CodeSourceMap::SetLength(intptr_t value) const {
  StoreNonPointer(&raw_ptr()->length_, value);
}

RawCodeSourceMap* CodeSourceMap::New(intptr_t length) {
  ASSERT(Object::code_source_map_class() != Class::null());
  Thread* thread = Thread::Current();
  CodeSourceMap& result = CodeSourceMap::Handle(thread->zone());
  {
    uword size = CodeSourceMap::InstanceSize(length);
    RawObject* raw =
        Object::Allocate(CodeSourceMap::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  return result.raw();
}

const char* CodeSourceMap::ToCString() const {
  return "CodeSourceMap";
}

bool StackMap::GetBit(intptr_t bit_index) const {
  ASSERT(InRange(bit_index));
  int byte_index = bit_index >> kBitsPerByteLog2;
  int bit_remainder = bit_index & (kBitsPerByte - 1);
  uint8_t byte_mask = 1U << bit_remainder;
  uint8_t byte = raw_ptr()->data()[byte_index];
  return (byte & byte_mask);
}

void StackMap::SetBit(intptr_t bit_index, bool value) const {
  ASSERT(InRange(bit_index));
  int byte_index = bit_index >> kBitsPerByteLog2;
  int bit_remainder = bit_index & (kBitsPerByte - 1);
  uint8_t byte_mask = 1U << bit_remainder;
  NoSafepointScope no_safepoint;
  uint8_t* byte_addr = UnsafeMutableNonPointer(&raw_ptr()->data()[byte_index]);
  if (value) {
    *byte_addr |= byte_mask;
  } else {
    *byte_addr &= ~byte_mask;
  }
}

RawStackMap* StackMap::New(intptr_t pc_offset,
                           BitmapBuilder* bmap,
                           intptr_t slow_path_bit_count) {
  ASSERT(Object::stackmap_class() != Class::null());
  ASSERT(bmap != NULL);
  StackMap& result = StackMap::Handle();
  // Guard against integer overflow of the instance size computation.
  intptr_t length = bmap->Length();
  intptr_t payload_size = Utils::RoundUp(length, kBitsPerByte) / kBitsPerByte;
  if ((payload_size < 0) || (payload_size > kMaxLengthInBytes)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in StackMap::New: invalid length %" Pd "\n", length);
  }
  {
    // StackMap data objects are associated with a code object, allocate them
    // in old generation.
    RawObject* raw = Object::Allocate(
        StackMap::kClassId, StackMap::InstanceSize(length), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  // When constructing a stackmap we store the pc offset in the stackmap's
  // PC. StackMapTableBuilder::FinalizeStackMaps will replace it with the pc
  // address.
  ASSERT(pc_offset >= 0);
  result.SetPcOffset(pc_offset);
  for (intptr_t i = 0; i < length; ++i) {
    result.SetBit(i, bmap->Get(i));
  }
  result.SetSlowPathBitCount(slow_path_bit_count);
  return result.raw();
}

RawStackMap* StackMap::New(intptr_t length,
                           intptr_t slow_path_bit_count,
                           intptr_t pc_offset) {
  ASSERT(Object::stackmap_class() != Class::null());
  StackMap& result = StackMap::Handle();
  // Guard against integer overflow of the instance size computation.
  intptr_t payload_size = Utils::RoundUp(length, kBitsPerByte) / kBitsPerByte;
  if ((payload_size < 0) || (payload_size > kMaxLengthInBytes)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in StackMap::New: invalid length %" Pd "\n", length);
  }
  {
    // StackMap data objects are associated with a code object, allocate them
    // in old generation.
    RawObject* raw = Object::Allocate(
        StackMap::kClassId, StackMap::InstanceSize(length), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  // When constructing a stackmap we store the pc offset in the stackmap's
  // PC. StackMapTableBuilder::FinalizeStackMaps will replace it with the pc
  // address.
  ASSERT(pc_offset >= 0);
  result.SetPcOffset(pc_offset);
  result.SetSlowPathBitCount(slow_path_bit_count);
  return result.raw();
}

const char* StackMap::ToCString() const {
#define FORMAT "%#05x: "
  if (IsNull()) {
    return "{null}";
  } else {
    intptr_t fixed_length = OS::SNPrint(NULL, 0, FORMAT, PcOffset()) + 1;
    Thread* thread = Thread::Current();
    // Guard against integer overflow in the computation of alloc_size.
    //
    // TODO(kmillikin): We could just truncate the string if someone
    // tries to print a 2 billion plus entry stackmap.
    if (Length() > (kIntptrMax - fixed_length)) {
      FATAL1("Length() is unexpectedly large (%" Pd ")", Length());
    }
    intptr_t alloc_size = fixed_length + Length();
    char* chars = thread->zone()->Alloc<char>(alloc_size);
    intptr_t index = OS::SNPrint(chars, alloc_size, FORMAT, PcOffset());
    for (intptr_t i = 0; i < Length(); i++) {
      chars[index++] = IsObject(i) ? '1' : '0';
    }
    chars[index] = '\0';
    return chars;
  }
#undef FORMAT
}

RawString* LocalVarDescriptors::GetName(intptr_t var_index) const {
  ASSERT(var_index < Length());
  ASSERT(Object::Handle(*raw()->nameAddrAt(var_index)).IsString());
  return *raw()->nameAddrAt(var_index);
}

void LocalVarDescriptors::SetVar(intptr_t var_index,
                                 const String& name,
                                 RawLocalVarDescriptors::VarInfo* info) const {
  ASSERT(var_index < Length());
  ASSERT(!name.IsNull());
  StorePointer(raw()->nameAddrAt(var_index), name.raw());
  raw()->data()[var_index] = *info;
}

void LocalVarDescriptors::GetInfo(intptr_t var_index,
                                  RawLocalVarDescriptors::VarInfo* info) const {
  ASSERT(var_index < Length());
  *info = raw()->data()[var_index];
}

static int PrintVarInfo(char* buffer,
                        int len,
                        intptr_t i,
                        const String& var_name,
                        const RawLocalVarDescriptors::VarInfo& info) {
  const RawLocalVarDescriptors::VarInfoKind kind = info.kind();
  const int32_t index = info.index();
  if (kind == RawLocalVarDescriptors::kContextLevel) {
    return OS::SNPrint(buffer, len,
                       "%2" Pd
                       " %-13s level=%-3d"
                       " begin=%-3d end=%d\n",
                       i, LocalVarDescriptors::KindToCString(kind), index,
                       static_cast<int>(info.begin_pos.value()),
                       static_cast<int>(info.end_pos.value()));
  } else if (kind == RawLocalVarDescriptors::kContextVar) {
    return OS::SNPrint(
        buffer, len,
        "%2" Pd
        " %-13s level=%-3d index=%-3d"
        " begin=%-3d end=%-3d name=%s\n",
        i, LocalVarDescriptors::KindToCString(kind), info.scope_id, index,
        static_cast<int>(info.begin_pos.Pos()),
        static_cast<int>(info.end_pos.Pos()), var_name.ToCString());
  } else {
    return OS::SNPrint(
        buffer, len,
        "%2" Pd
        " %-13s scope=%-3d index=%-3d"
        " begin=%-3d end=%-3d name=%s\n",
        i, LocalVarDescriptors::KindToCString(kind), info.scope_id, index,
        static_cast<int>(info.begin_pos.Pos()),
        static_cast<int>(info.end_pos.Pos()), var_name.ToCString());
  }
}

const char* LocalVarDescriptors::ToCString() const {
  if (IsNull()) {
    return "LocalVarDescriptors: null";
  }
  if (Length() == 0) {
    return "empty LocalVarDescriptors";
  }
  intptr_t len = 1;  // Trailing '\0'.
  String& var_name = String::Handle();
  for (intptr_t i = 0; i < Length(); i++) {
    RawLocalVarDescriptors::VarInfo info;
    var_name = GetName(i);
    GetInfo(i, &info);
    len += PrintVarInfo(NULL, 0, i, var_name, info);
  }
  char* buffer = Thread::Current()->zone()->Alloc<char>(len + 1);
  buffer[0] = '\0';
  intptr_t num_chars = 0;
  for (intptr_t i = 0; i < Length(); i++) {
    RawLocalVarDescriptors::VarInfo info;
    var_name = GetName(i);
    GetInfo(i, &info);
    num_chars += PrintVarInfo((buffer + num_chars), (len - num_chars), i,
                              var_name, info);
  }
  return buffer;
}

const char* LocalVarDescriptors::KindToCString(
    RawLocalVarDescriptors::VarInfoKind kind) {
  switch (kind) {
    case RawLocalVarDescriptors::kStackVar:
      return "StackVar";
    case RawLocalVarDescriptors::kContextVar:
      return "ContextVar";
    case RawLocalVarDescriptors::kContextLevel:
      return "ContextLevel";
    case RawLocalVarDescriptors::kSavedCurrentContext:
      return "CurrentCtx";
    default:
      UNIMPLEMENTED();
      return NULL;
  }
}

RawLocalVarDescriptors* LocalVarDescriptors::New(intptr_t num_variables) {
  ASSERT(Object::var_descriptors_class() != Class::null());
  if (num_variables < 0 || num_variables > kMaxElements) {
    // This should be caught before we reach here.
    FATAL2(
        "Fatal error in LocalVarDescriptors::New: "
        "invalid num_variables %" Pd ". Maximum is: %d\n",
        num_variables, RawLocalVarDescriptors::kMaxIndex);
  }
  LocalVarDescriptors& result = LocalVarDescriptors::Handle();
  {
    uword size = LocalVarDescriptors::InstanceSize(num_variables);
    RawObject* raw =
        Object::Allocate(LocalVarDescriptors::kClassId, size, Heap::kOld);
    INC_STAT(Thread::Current(), total_code_size, size);
    INC_STAT(Thread::Current(), vardesc_size, size);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->num_entries_, num_variables);
  }
  return result.raw();
}

intptr_t LocalVarDescriptors::Length() const {
  return raw_ptr()->num_entries_;
}

intptr_t ExceptionHandlers::num_entries() const {
  return raw_ptr()->num_entries_;
}

void ExceptionHandlers::SetHandlerInfo(intptr_t try_index,
                                       intptr_t outer_try_index,
                                       uword handler_pc_offset,
                                       bool needs_stacktrace,
                                       bool has_catch_all,
                                       TokenPosition token_pos,
                                       bool is_generated) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  NoSafepointScope no_safepoint;
  ExceptionHandlerInfo* info =
      UnsafeMutableNonPointer(&raw_ptr()->data()[try_index]);
  info->outer_try_index = outer_try_index;
  // Some C compilers warn about the comparison always being true when using <=
  // due to limited range of data type.
  ASSERT((handler_pc_offset == static_cast<uword>(kMaxUint32)) ||
         (handler_pc_offset < static_cast<uword>(kMaxUint32)));
  info->handler_pc_offset = handler_pc_offset;
  info->needs_stacktrace = needs_stacktrace;
  info->has_catch_all = has_catch_all;
  info->is_generated = is_generated;
}

void ExceptionHandlers::GetHandlerInfo(intptr_t try_index,
                                       ExceptionHandlerInfo* info) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  ASSERT(info != NULL);
  *info = raw_ptr()->data()[try_index];
}

uword ExceptionHandlers::HandlerPCOffset(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].handler_pc_offset;
}

intptr_t ExceptionHandlers::OuterTryIndex(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].outer_try_index;
}

bool ExceptionHandlers::NeedsStackTrace(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].needs_stacktrace;
}

bool ExceptionHandlers::IsGenerated(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].is_generated;
}

bool ExceptionHandlers::HasCatchAll(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].has_catch_all;
}

void ExceptionHandlers::SetHandledTypes(intptr_t try_index,
                                        const Array& handled_types) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  ASSERT(!handled_types.IsNull());
  const Array& handled_types_data =
      Array::Handle(raw_ptr()->handled_types_data_);
  handled_types_data.SetAt(try_index, handled_types);
}

RawArray* ExceptionHandlers::GetHandledTypes(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  Array& array = Array::Handle(raw_ptr()->handled_types_data_);
  array ^= array.At(try_index);
  return array.raw();
}

void ExceptionHandlers::set_handled_types_data(const Array& value) const {
  StorePointer(&raw_ptr()->handled_types_data_, value.raw());
}

RawExceptionHandlers* ExceptionHandlers::New(intptr_t num_handlers) {
  ASSERT(Object::exception_handlers_class() != Class::null());
  if ((num_handlers < 0) || (num_handlers >= kMaxHandlers)) {
    FATAL1(
        "Fatal error in ExceptionHandlers::New(): "
        "invalid num_handlers %" Pd "\n",
        num_handlers);
  }
  ExceptionHandlers& result = ExceptionHandlers::Handle();
  {
    uword size = ExceptionHandlers::InstanceSize(num_handlers);
    RawObject* raw =
        Object::Allocate(ExceptionHandlers::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->num_entries_, num_handlers);
  }
  const Array& handled_types_data =
      (num_handlers == 0) ? Object::empty_array()
                          : Array::Handle(Array::New(num_handlers, Heap::kOld));
  result.set_handled_types_data(handled_types_data);
  return result.raw();
}

RawExceptionHandlers* ExceptionHandlers::New(const Array& handled_types_data) {
  ASSERT(Object::exception_handlers_class() != Class::null());
  const intptr_t num_handlers = handled_types_data.Length();
  if ((num_handlers < 0) || (num_handlers >= kMaxHandlers)) {
    FATAL1(
        "Fatal error in ExceptionHandlers::New(): "
        "invalid num_handlers %" Pd "\n",
        num_handlers);
  }
  ExceptionHandlers& result = ExceptionHandlers::Handle();
  {
    uword size = ExceptionHandlers::InstanceSize(num_handlers);
    RawObject* raw =
        Object::Allocate(ExceptionHandlers::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->num_entries_, num_handlers);
  }
  result.set_handled_types_data(handled_types_data);
  return result.raw();
}

const char* ExceptionHandlers::ToCString() const {
#define FORMAT1 "%" Pd " => %#x  (%" Pd " types) (outer %d) %s\n"
#define FORMAT2 "  %d. %s\n"
  if (num_entries() == 0) {
    return "empty ExceptionHandlers\n";
  }
  Array& handled_types = Array::Handle();
  Type& type = Type::Handle();
  ExceptionHandlerInfo info;
  // First compute the buffer size required.
  intptr_t len = 1;  // Trailing '\0'.
  for (intptr_t i = 0; i < num_entries(); i++) {
    GetHandlerInfo(i, &info);
    handled_types = GetHandledTypes(i);
    const intptr_t num_types =
        handled_types.IsNull() ? 0 : handled_types.Length();
    len += OS::SNPrint(NULL, 0, FORMAT1, i, info.handler_pc_offset, num_types,
                       info.outer_try_index,
                       info.is_generated ? "(generated)" : "");
    for (int k = 0; k < num_types; k++) {
      type ^= handled_types.At(k);
      ASSERT(!type.IsNull());
      len += OS::SNPrint(NULL, 0, FORMAT2, k, type.ToCString());
    }
  }
  // Allocate the buffer.
  char* buffer = Thread::Current()->zone()->Alloc<char>(len);
  // Layout the fields in the buffer.
  intptr_t num_chars = 0;
  for (intptr_t i = 0; i < num_entries(); i++) {
    GetHandlerInfo(i, &info);
    handled_types = GetHandledTypes(i);
    const intptr_t num_types =
        handled_types.IsNull() ? 0 : handled_types.Length();
    num_chars +=
        OS::SNPrint((buffer + num_chars), (len - num_chars), FORMAT1, i,
                    info.handler_pc_offset, num_types, info.outer_try_index,
                    info.is_generated ? "(generated)" : "");
    for (int k = 0; k < num_types; k++) {
      type ^= handled_types.At(k);
      num_chars += OS::SNPrint((buffer + num_chars), (len - num_chars), FORMAT2,
                               k, type.ToCString());
    }
  }
  return buffer;
#undef FORMAT1
#undef FORMAT2
}

void SingleTargetCache::set_target(const Code& value) const {
  StorePointer(&raw_ptr()->target_, value.raw());
}

const char* SingleTargetCache::ToCString() const {
  return "SingleTargetCache";
}

RawSingleTargetCache* SingleTargetCache::New() {
  SingleTargetCache& result = SingleTargetCache::Handle();
  {
    // IC data objects are long living objects, allocate them in old generation.
    RawObject* raw =
        Object::Allocate(SingleTargetCache::kClassId,
                         SingleTargetCache::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_target(Code::Handle());
  result.set_entry_point(0);
  result.set_lower_limit(kIllegalCid);
  result.set_upper_limit(kIllegalCid);
  return result.raw();
}

void UnlinkedCall::set_target_name(const String& value) const {
  StorePointer(&raw_ptr()->target_name_, value.raw());
}

void UnlinkedCall::set_args_descriptor(const Array& value) const {
  StorePointer(&raw_ptr()->args_descriptor_, value.raw());
}

const char* UnlinkedCall::ToCString() const {
  return "UnlinkedCall";
}

RawUnlinkedCall* UnlinkedCall::New() {
  RawObject* raw = Object::Allocate(UnlinkedCall::kClassId,
                                    UnlinkedCall::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawUnlinkedCall*>(raw);
}

void ICData::ResetSwitchable(Zone* zone) const {
  ASSERT(NumArgsTested() == 1);
  set_ic_data_array(Array::Handle(zone, CachedEmptyICDataArray(1)));
}

const char* ICData::ToCString() const {
  const String& name = String::Handle(target_name());
  const intptr_t num_args = NumArgsTested();
  const intptr_t num_checks = NumberOfChecks();
  const intptr_t type_args_len = TypeArgsLen();
  return OS::SCreate(Thread::Current()->zone(),
                     "ICData target:'%s' num-args: %" Pd " num-checks: %" Pd
                     " type-args-len: %" Pd "",
                     name.ToCString(), num_args, num_checks, type_args_len);
}

RawFunction* ICData::Owner() const {
  Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsNull()) {
    ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
    return Function::null();
  } else if (obj.IsFunction()) {
    return Function::Cast(obj).raw();
  } else {
    ICData& original = ICData::Handle();
    original ^= obj.raw();
    return original.Owner();
  }
}

RawICData* ICData::Original() const {
  if (IsNull()) {
    return ICData::null();
  }
  Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsFunction()) {
    return this->raw();
  } else {
    return ICData::RawCast(obj.raw());
  }
}

void ICData::SetOriginal(const ICData& value) const {
  ASSERT(value.IsOriginal());
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->owner_, reinterpret_cast<RawObject*>(value.raw()));
}

void ICData::set_owner(const Function& value) const {
  StorePointer(&raw_ptr()->owner_, reinterpret_cast<RawObject*>(value.raw()));
}

void ICData::set_target_name(const String& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->target_name_, value.raw());
}

void ICData::set_arguments_descriptor(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->args_descriptor_, value.raw());
}

void ICData::set_deopt_id(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(value <= kMaxInt32);
  StoreNonPointer(&raw_ptr()->deopt_id_, value);
#endif
}

void ICData::set_ic_data_array(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->ic_data_, value.raw());
}

#if defined(TAG_IC_DATA)
void ICData::set_tag(intptr_t value) const {
  StoreNonPointer(&raw_ptr()->tag_, value);
}
#endif

intptr_t ICData::NumArgsTested() const {
  return NumArgsTestedBits::decode(raw_ptr()->state_bits_);
}

void ICData::SetNumArgsTested(intptr_t value) const {
  ASSERT(Utils::IsUint(2, value));
  StoreNonPointer(&raw_ptr()->state_bits_,
                  NumArgsTestedBits::update(value, raw_ptr()->state_bits_));
}

intptr_t ICData::TypeArgsLen() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.TypeArgsLen();
}

intptr_t ICData::CountWithTypeArgs() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.CountWithTypeArgs();
}

intptr_t ICData::CountWithoutTypeArgs() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.Count();
}

uint32_t ICData::DeoptReasons() const {
  return DeoptReasonBits::decode(raw_ptr()->state_bits_);
}

void ICData::SetDeoptReasons(uint32_t reasons) const {
  StoreNonPointer(&raw_ptr()->state_bits_,
                  DeoptReasonBits::update(reasons, raw_ptr()->state_bits_));
}

bool ICData::HasDeoptReason(DeoptReasonId reason) const {
  ASSERT(reason <= kLastRecordedDeoptReason);
  return (DeoptReasons() & (1 << reason)) != 0;
}

void ICData::AddDeoptReason(DeoptReasonId reason) const {
  if (reason <= kLastRecordedDeoptReason) {
    SetDeoptReasons(DeoptReasons() | (1 << reason));
  }
}

void ICData::SetIsStaticCall(bool static_call) const {
  StoreNonPointer(&raw_ptr()->state_bits_,
                  StaticCallBit::update(static_call, raw_ptr()->state_bits_));
}

bool ICData::is_static_call() const {
  return StaticCallBit::decode(raw_ptr()->state_bits_);
}

void ICData::set_state_bits(uint32_t bits) const {
  StoreNonPointer(&raw_ptr()->state_bits_, bits);
}

intptr_t ICData::TestEntryLengthFor(intptr_t num_args) {
  return num_args + 1 /* target function*/ + 1 /* frequency */;
}

intptr_t ICData::TestEntryLength() const {
  return TestEntryLengthFor(NumArgsTested());
}

intptr_t ICData::Length() const {
  return (Smi::Value(ic_data()->ptr()->length_) / TestEntryLength());
}

intptr_t ICData::NumberOfChecks() const {
  const intptr_t length = Length();
  for (intptr_t i = 0; i < length; i++) {
    if (IsSentinelAt(i)) {
      return i;
    }
  }
  UNREACHABLE();
  return -1;
}

bool ICData::NumberOfChecksIs(intptr_t n) const {
  const intptr_t length = Length();
  for (intptr_t i = 0; i < length; i++) {
    if (i == n) {
      return IsSentinelAt(i);
    } else {
      if (IsSentinelAt(i)) return false;
    }
  }
  return n == length;
}

// Discounts any checks with usage of zero.
intptr_t ICData::NumberOfUsedChecks() const {
  intptr_t n = NumberOfChecks();
  if (n == 0) {
    return 0;
  }
  intptr_t count = 0;
  for (intptr_t i = 0; i < n; i++) {
    if (GetCountAt(i) > 0) {
      count++;
    }
  }
  return count;
}

void ICData::WriteSentinel(const Array& data, intptr_t test_entry_length) {
  ASSERT(!data.IsNull());
  for (intptr_t i = 1; i <= test_entry_length; i++) {
    data.SetAt(data.Length() - i, smi_illegal_cid());
  }
}

#if defined(DEBUG)
// Used in asserts to verify that a check is not added twice.
bool ICData::HasCheck(const GrowableArray<intptr_t>& cids) const {
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    GrowableArray<intptr_t> class_ids;
    GetClassIdsAt(i, &class_ids);
    bool matches = true;
    for (intptr_t k = 0; k < class_ids.length(); k++) {
      ASSERT(class_ids[k] != kIllegalCid);
      if (class_ids[k] != cids[k]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }
  return false;
}
#endif  // DEBUG

void ICData::WriteSentinelAt(intptr_t index) const {
  const intptr_t len = Length();
  ASSERT(index >= 0);
  ASSERT(index < len);
  Array& data = Array::Handle(ic_data());
  const intptr_t start = index * TestEntryLength();
  const intptr_t end = start + TestEntryLength();
  for (intptr_t i = start; i < end; i++) {
    data.SetAt(i, smi_illegal_cid());
  }
}

void ICData::ClearCountAt(intptr_t index) const {
  ASSERT(index >= 0);
  ASSERT(index < NumberOfChecks());
  SetCountAt(index, 0);
}

void ICData::ClearWithSentinel() const {
  if (IsImmutable()) {
    return;
  }
  // Write the sentinel value into all entries except the first one.
  const intptr_t len = Length();
  if (len == 0) {
    return;
  }
  // The final entry is always the sentinel.
  ASSERT(IsSentinelAt(len - 1));
  for (intptr_t i = len - 1; i > 0; i--) {
    WriteSentinelAt(i);
  }
  if (NumArgsTested() != 2) {
    // Not the smi fast path case, write sentinel to first one and exit.
    WriteSentinelAt(0);
    return;
  }
  if (IsSentinelAt(0)) {
    return;
  }
  Zone* zone = Thread::Current()->zone();
  const String& name = String::Handle(target_name());
  const Class& smi_class = Class::Handle(Smi::Class());
  const Function& smi_op_target =
      Function::Handle(Resolver::ResolveDynamicAnyArgs(zone, smi_class, name));
  GrowableArray<intptr_t> class_ids(2);
  Function& target = Function::Handle();
  GetCheckAt(0, &class_ids, &target);
  if ((target.raw() == smi_op_target.raw()) && (class_ids[0] == kSmiCid) &&
      (class_ids[1] == kSmiCid)) {
    // The smi fast path case, preserve the initial entry but reset the count.
    ClearCountAt(0);
    return;
  }
  WriteSentinelAt(0);
}

void ICData::ClearAndSetStaticTarget(const Function& func) const {
  if (IsImmutable()) {
    return;
  }
  const intptr_t len = Length();
  if (len == 0) {
    return;
  }
  // The final entry is always the sentinel.
  ASSERT(IsSentinelAt(len - 1));
  if (NumArgsTested() == 0) {
    // No type feedback is being collected.
    const Array& data = Array::Handle(ic_data());
    // Static calls with no argument checks hold only one target and the
    // sentinel value.
    ASSERT(len == 2);
    // Static calls with no argument checks only need two words.
    ASSERT(TestEntryLength() == 2);
    // Set the target.
    data.SetAt(0, func);
    // Set count to 0 as this is called during compilation, before the
    // call has been executed.
    const Smi& value = Smi::Handle(Smi::New(0));
    data.SetAt(1, value);
  } else {
    // Type feedback on arguments is being collected.
    const Array& data = Array::Handle(ic_data());

    // Fill all but the first entry with the sentinel.
    for (intptr_t i = len - 1; i > 0; i--) {
      WriteSentinelAt(i);
    }
    // Rewrite the dummy entry.
    const Smi& object_cid = Smi::Handle(Smi::New(kObjectCid));
    for (intptr_t i = 0; i < NumArgsTested(); i++) {
      data.SetAt(i, object_cid);
    }
    data.SetAt(NumArgsTested(), func);
    const Smi& value = Smi::Handle(Smi::New(0));
    data.SetAt(NumArgsTested() + 1, value);
  }
}

// Add an initial Smi/Smi check with count 0.
bool ICData::AddSmiSmiCheckForFastSmiStubs() const {
  bool is_smi_two_args_op = false;

  ASSERT(NumArgsTested() == 2);
  const String& name = String::Handle(target_name());
  const Class& smi_class = Class::Handle(Smi::Class());
  Zone* zone = Thread::Current()->zone();
  const Function& smi_op_target =
      Function::Handle(Resolver::ResolveDynamicAnyArgs(zone, smi_class, name));
  if (NumberOfChecksIs(0)) {
    GrowableArray<intptr_t> class_ids(2);
    class_ids.Add(kSmiCid);
    class_ids.Add(kSmiCid);
    AddCheck(class_ids, smi_op_target);
    // 'AddCheck' sets the initial count to 1.
    SetCountAt(0, 0);
    is_smi_two_args_op = true;
  } else if (NumberOfChecksIs(1)) {
    GrowableArray<intptr_t> class_ids(2);
    Function& target = Function::Handle();
    GetCheckAt(0, &class_ids, &target);
    if ((target.raw() == smi_op_target.raw()) && (class_ids[0] == kSmiCid) &&
        (class_ids[1] == kSmiCid)) {
      is_smi_two_args_op = true;
    }
  }
  return is_smi_two_args_op;
}

// Used for unoptimized static calls when no class-ids are checked.
void ICData::AddTarget(const Function& target) const {
  ASSERT(!target.IsNull());
  if (NumArgsTested() > 0) {
    // Create a fake cid entry, so that we can store the target.
    if (NumArgsTested() == 1) {
      AddReceiverCheck(kObjectCid, target, 1);
    } else {
      GrowableArray<intptr_t> class_ids(NumArgsTested());
      for (intptr_t i = 0; i < NumArgsTested(); i++) {
        class_ids.Add(kObjectCid);
      }
      AddCheck(class_ids, target);
    }
    return;
  }
  ASSERT(NumArgsTested() == 0);
  // Can add only once.
  const intptr_t old_num = NumberOfChecks();
  ASSERT(old_num == 0);
  Array& data = Array::Handle(ic_data());
  const intptr_t new_len = data.Length() + TestEntryLength();
  data = Array::Grow(data, new_len, Heap::kOld);
  WriteSentinel(data, TestEntryLength());
  intptr_t data_pos = old_num * TestEntryLength();
  ASSERT(!target.IsNull());
  data.SetAt(data_pos++, target);
  // Set count to 0 as this is called during compilation, before the
  // call has been executed.
  const Smi& value = Smi::Handle(Smi::New(0));
  data.SetAt(data_pos, value);
  // Multithreaded access to ICData requires setting of array to be the last
  // operation.
  set_ic_data_array(data);
}

bool ICData::ValidateInterceptor(const Function& target) const {
  ObjectStore* store = Isolate::Current()->object_store();
  ASSERT((target.raw() == store->simple_instance_of_true_function()) ||
         (target.raw() == store->simple_instance_of_false_function()));
  const String& instance_of_name = String::Handle(
      Library::PrivateCoreLibName(Symbols::_simpleInstanceOf()).raw());
  ASSERT(target_name() == instance_of_name.raw());
  return true;
}

void ICData::AddCheck(const GrowableArray<intptr_t>& class_ids,
                      const Function& target,
                      intptr_t count) const {
  ASSERT(!target.IsNull());
  ASSERT((target.name() == target_name()) || ValidateInterceptor(target));
  DEBUG_ASSERT(!HasCheck(class_ids));
  ASSERT(NumArgsTested() > 1);  // Otherwise use 'AddReceiverCheck'.
  ASSERT(class_ids.length() == NumArgsTested());
  const intptr_t old_num = NumberOfChecks();
  Array& data = Array::Handle(ic_data());
  // ICData of static calls with NumArgsTested() > 0 have initially a
  // dummy set of cids entered (see ICData::AddTarget). That entry is
  // overwritten by first real type feedback data.
  if (old_num == 1) {
    bool has_dummy_entry = true;
    for (intptr_t i = 0; i < NumArgsTested(); i++) {
      if (Smi::Value(Smi::RawCast(data.At(i))) != kObjectCid) {
        has_dummy_entry = false;
        break;
      }
    }
    if (has_dummy_entry) {
      ASSERT(target.raw() == data.At(NumArgsTested()));
      // Replace dummy entry.
      Smi& value = Smi::Handle();
      for (intptr_t i = 0; i < NumArgsTested(); i++) {
        ASSERT(class_ids[i] != kIllegalCid);
        value = Smi::New(class_ids[i]);
        data.SetAt(i, value);
      }
      return;
    }
  }
  intptr_t index = -1;
  data = FindFreeIndex(&index);
  ASSERT(!data.IsNull());
  intptr_t data_pos = index * TestEntryLength();
  Smi& value = Smi::Handle();
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    // kIllegalCid is used as terminating value, do not add it.
    ASSERT(class_ids[i] != kIllegalCid);
    value = Smi::New(class_ids[i]);
    data.SetAt(data_pos++, value);
  }
  ASSERT(!target.IsNull());
  data.SetAt(data_pos++, target);
  value = Smi::New(count);
  data.SetAt(data_pos, value);
  // Multithreaded access to ICData requires setting of array to be the last
  // operation.
  set_ic_data_array(data);
}

RawArray* ICData::FindFreeIndex(intptr_t* index) const {
  // The final entry is always the sentinel value, don't consider it
  // when searching.
  const intptr_t len = Length() - 1;
  Array& data = Array::Handle(ic_data());
  *index = len;
  for (intptr_t i = 0; i < len; i++) {
    if (IsSentinelAt(i)) {
      *index = i;
      break;
    }
  }
  if (*index < len) {
    // We've found a free slot.
    return data.raw();
  }
  // Append case.
  ASSERT(*index == len);
  ASSERT(*index >= 0);
  // Grow array.
  const intptr_t new_len = data.Length() + TestEntryLength();
  data = Array::Grow(data, new_len, Heap::kOld);
  WriteSentinel(data, TestEntryLength());
  return data.raw();
}

void ICData::DebugDump() const {
  const Function& owner = Function::Handle(Owner());
  THR_Print("ICData::DebugDump\n");
  THR_Print("Owner = %s [deopt=%" Pd "]\n", owner.ToCString(), deopt_id());
  THR_Print("NumArgsTested = %" Pd "\n", NumArgsTested());
  THR_Print("Length = %" Pd "\n", Length());
  THR_Print("NumberOfChecks = %" Pd "\n", NumberOfChecks());

  GrowableArray<intptr_t> class_ids;
  for (intptr_t i = 0; i < NumberOfChecks(); i++) {
    THR_Print("Check[%" Pd "]:", i);
    GetClassIdsAt(i, &class_ids);
    for (intptr_t c = 0; c < class_ids.length(); c++) {
      THR_Print(" %" Pd "", class_ids[c]);
    }
    THR_Print("--- %" Pd " hits\n", GetCountAt(i));
  }
}

void ICData::AddReceiverCheck(intptr_t receiver_class_id,
                              const Function& target,
                              intptr_t count) const {
#if defined(DEBUG)
  GrowableArray<intptr_t> class_ids(1);
  class_ids.Add(receiver_class_id);
  ASSERT(!HasCheck(class_ids));
#endif  // DEBUG
  ASSERT(!target.IsNull());
  ASSERT(NumArgsTested() == 1);  // Otherwise use 'AddCheck'.
  ASSERT(receiver_class_id != kIllegalCid);

  intptr_t index = -1;
  Array& data = Array::Handle(FindFreeIndex(&index));
  intptr_t data_pos = index * TestEntryLength();
  if ((receiver_class_id == kSmiCid) && (data_pos > 0)) {
    ASSERT(GetReceiverClassIdAt(0) != kSmiCid);
    // Move class occupying position 0 to the data_pos.
    for (intptr_t i = 0; i < TestEntryLength(); i++) {
      data.SetAt(data_pos + i, Object::Handle(data.At(i)));
    }
    // Insert kSmiCid in position 0.
    data_pos = 0;
  }
  data.SetAt(data_pos, Smi::Handle(Smi::New(receiver_class_id)));
  if (Isolate::Current()->compilation_allowed()) {
    data.SetAt(data_pos + 1, target);
    data.SetAt(data_pos + 2, Smi::Handle(Smi::New(count)));
  } else {
    // Precompilation only, after all functions have been compiled.
    ASSERT(target.HasCode());
    const Code& code = Code::Handle(target.CurrentCode());
    const Smi& entry_point =
        Smi::Handle(Smi::FromAlignedAddress(code.UncheckedEntryPoint()));
    data.SetAt(data_pos + 1, code);
    data.SetAt(data_pos + 2, entry_point);
  }
  // Multithreaded access to ICData requires setting of array to be the last
  // operation.
  set_ic_data_array(data);
}

void ICData::GetCheckAt(intptr_t index,
                        GrowableArray<intptr_t>* class_ids,
                        Function* target) const {
  ASSERT(index < NumberOfChecks());
  ASSERT(class_ids != NULL);
  ASSERT(target != NULL);
  class_ids->Clear();
  const Array& data = Array::Handle(ic_data());
  intptr_t data_pos = index * TestEntryLength();
  for (intptr_t i = 0; i < NumArgsTested(); i++) {
    class_ids->Add(Smi::Value(Smi::RawCast(data.At(data_pos++))));
  }
  (*target) ^= data.At(data_pos++);
}

bool ICData::IsSentinelAt(intptr_t index) const {
  ASSERT(index < Length());
  const Array& data = Array::Handle(ic_data());
  const intptr_t entry_length = TestEntryLength();
  intptr_t data_pos = index * TestEntryLength();
  for (intptr_t i = 0; i < entry_length; i++) {
    if (data.At(data_pos++) != smi_illegal_cid().raw()) {
      return false;
    }
  }
  // The entry at |index| was filled with the value kIllegalCid.
  return true;
}

void ICData::GetClassIdsAt(intptr_t index,
                           GrowableArray<intptr_t>* class_ids) const {
  ASSERT(index < Length());
  ASSERT(class_ids != NULL);
  ASSERT(!IsSentinelAt(index));
  class_ids->Clear();
  const Array& data = Array::Handle(ic_data());
  intptr_t data_pos = index * TestEntryLength();
  for (intptr_t i = 0; i < NumArgsTested(); i++) {
    class_ids->Add(Smi::Value(Smi::RawCast(data.At(data_pos++))));
  }
}

void ICData::GetOneClassCheckAt(intptr_t index,
                                intptr_t* class_id,
                                Function* target) const {
  ASSERT(class_id != NULL);
  ASSERT(target != NULL);
  ASSERT(NumArgsTested() == 1);
  const Array& data = Array::Handle(ic_data());
  const intptr_t data_pos = index * TestEntryLength();
  *class_id = Smi::Value(Smi::RawCast(data.At(data_pos)));
  *target ^= data.At(data_pos + 1);
}

intptr_t ICData::GetCidAt(intptr_t index) const {
  ASSERT(NumArgsTested() == 1);
  const Array& data = Array::Handle(ic_data());
  const intptr_t data_pos = index * TestEntryLength();
  return Smi::Value(Smi::RawCast(data.At(data_pos)));
}

intptr_t ICData::GetClassIdAt(intptr_t index, intptr_t arg_nr) const {
  GrowableArray<intptr_t> class_ids;
  GetClassIdsAt(index, &class_ids);
  return class_ids[arg_nr];
}

intptr_t ICData::GetReceiverClassIdAt(intptr_t index) const {
  ASSERT(index < Length());
  ASSERT(!IsSentinelAt(index));
  const intptr_t data_pos = index * TestEntryLength();
  NoSafepointScope no_safepoint;
  RawArray* raw_data = ic_data();
  return Smi::Value(Smi::RawCast(raw_data->ptr()->data()[data_pos]));
}

RawFunction* ICData::GetTargetAt(intptr_t index) const {
  ASSERT(Isolate::Current()->compilation_allowed());
  const intptr_t data_pos = index * TestEntryLength() + NumArgsTested();
  ASSERT(Object::Handle(Array::Handle(ic_data()).At(data_pos)).IsFunction());

  NoSafepointScope no_safepoint;
  RawArray* raw_data = ic_data();
  return reinterpret_cast<RawFunction*>(raw_data->ptr()->data()[data_pos]);
}

RawObject* ICData::GetTargetOrCodeAt(intptr_t index) const {
  const intptr_t data_pos = index * TestEntryLength() + NumArgsTested();

  NoSafepointScope no_safepoint;
  RawArray* raw_data = ic_data();
  return raw_data->ptr()->data()[data_pos];
}

void ICData::IncrementCountAt(intptr_t index, intptr_t value) const {
  ASSERT(0 <= value);
  ASSERT(value <= Smi::kMaxValue);
  SetCountAt(index, Utils::Minimum(GetCountAt(index) + value, Smi::kMaxValue));
}

void ICData::SetCountAt(intptr_t index, intptr_t value) const {
  ASSERT(0 <= value);
  ASSERT(value <= Smi::kMaxValue);

  const Array& data = Array::Handle(ic_data());
  const intptr_t data_pos =
      index * TestEntryLength() + CountIndexFor(NumArgsTested());
  data.SetAt(data_pos, Smi::Handle(Smi::New(value)));
}

intptr_t ICData::GetCountAt(intptr_t index) const {
  ASSERT(Isolate::Current()->compilation_allowed());
  const Array& data = Array::Handle(ic_data());
  const intptr_t data_pos =
      index * TestEntryLength() + CountIndexFor(NumArgsTested());
  intptr_t value = Smi::Value(Smi::RawCast(data.At(data_pos)));
  if (value >= 0) return value;

  // The counter very rarely overflows to a negative value, but if it does, we
  // would rather just reset it to zero.
  SetCountAt(index, 0);
  return 0;
}

intptr_t ICData::AggregateCount() const {
  if (IsNull()) return 0;
  const intptr_t len = NumberOfChecks();
  intptr_t count = 0;
  for (intptr_t i = 0; i < len; i++) {
    count += GetCountAt(i);
  }
  return count;
}

void ICData::SetCodeAt(intptr_t index, const Code& value) const {
  ASSERT(!Isolate::Current()->compilation_allowed());
  const Array& data = Array::Handle(ic_data());
  const intptr_t data_pos =
      index * TestEntryLength() + CodeIndexFor(NumArgsTested());
  data.SetAt(data_pos, value);
}

void ICData::SetEntryPointAt(intptr_t index, const Smi& value) const {
  ASSERT(!Isolate::Current()->compilation_allowed());
  const Array& data = Array::Handle(ic_data());
  const intptr_t data_pos =
      index * TestEntryLength() + EntryPointIndexFor(NumArgsTested());
  data.SetAt(data_pos, value);
}

RawFunction* ICData::GetTargetForReceiverClassId(intptr_t class_id,
                                                 intptr_t* count_return) const {
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (GetReceiverClassIdAt(i) == class_id) {
      *count_return = GetCountAt(i);
      return GetTargetAt(i);
    }
  }
  return Function::null();
}

RawICData* ICData::AsUnaryClassChecksForCid(intptr_t cid,
                                            const Function& target) const {
  ASSERT(!IsNull());
  const intptr_t kNumArgsTested = 1;
  ICData& result = ICData::Handle(ICData::NewFrom(*this, kNumArgsTested));

  // Copy count so that we copy the state "count == 0" vs "count > 0".
  result.AddReceiverCheck(cid, target, GetCountAt(0));
  return result.raw();
}

RawICData* ICData::AsUnaryClassChecksForArgNr(intptr_t arg_nr) const {
  ASSERT(!IsNull());
  ASSERT(NumArgsTested() > arg_nr);
  if ((arg_nr == 0) && (NumArgsTested() == 1)) {
    // Frequent case.
    return raw();
  }
  const intptr_t kNumArgsTested = 1;
  ICData& result = ICData::Handle(ICData::NewFrom(*this, kNumArgsTested));
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    const intptr_t class_id = GetClassIdAt(i, arg_nr);
    const intptr_t count = GetCountAt(i);
    if (count == 0) {
      continue;
    }
    intptr_t duplicate_class_id = -1;
    const intptr_t result_len = result.NumberOfChecks();
    for (intptr_t k = 0; k < result_len; k++) {
      if (class_id == result.GetReceiverClassIdAt(k)) {
        duplicate_class_id = k;
        break;
      }
    }
    if (duplicate_class_id >= 0) {
      // This check is valid only when checking the receiver.
      ASSERT((arg_nr != 0) ||
             (result.GetTargetAt(duplicate_class_id) == GetTargetAt(i)));
      result.IncrementCountAt(duplicate_class_id, count);
    } else {
      // This will make sure that Smi is first if it exists.
      result.AddReceiverCheck(class_id, Function::Handle(GetTargetAt(i)),
                              count);
    }
  }

  return result.raw();
}

// (cid, count) tuple used to sort ICData by count.
struct CidCount {
  CidCount(intptr_t cid_, intptr_t count_, Function* f_)
      : cid(cid_), count(count_), function(f_) {}

  static int HighestCountFirst(const CidCount* a, const CidCount* b);

  intptr_t cid;
  intptr_t count;
  Function* function;
};

int CidCount::HighestCountFirst(const CidCount* a, const CidCount* b) {
  if (a->count > b->count) {
    return -1;
  }
  return (a->count < b->count) ? 1 : 0;
}

RawICData* ICData::AsUnaryClassChecksSortedByCount() const {
  ASSERT(!IsNull());
  const intptr_t kNumArgsTested = 1;
  const intptr_t len = NumberOfChecks();
  if (len <= 1) {
    // No sorting needed.
    return AsUnaryClassChecks();
  }
  GrowableArray<CidCount> aggregate;
  for (intptr_t i = 0; i < len; i++) {
    const intptr_t class_id = GetClassIdAt(i, 0);
    const intptr_t count = GetCountAt(i);
    if (count == 0) {
      continue;
    }
    bool found = false;
    for (intptr_t r = 0; r < aggregate.length(); r++) {
      if (aggregate[r].cid == class_id) {
        aggregate[r].count += count;
        found = true;
        break;
      }
    }
    if (!found) {
      aggregate.Add(
          CidCount(class_id, count, &Function::ZoneHandle(GetTargetAt(i))));
    }
  }
  aggregate.Sort(CidCount::HighestCountFirst);

  ICData& result = ICData::Handle(ICData::NewFrom(*this, kNumArgsTested));
  ASSERT(result.NumberOfChecksIs(0));
  // Room for all entries and the sentinel.
  const intptr_t data_len = result.TestEntryLength() * (aggregate.length() + 1);
  // Allocate the array but do not assign it to result until we have populated
  // it with the aggregate data and the terminating sentinel.
  const Array& data = Array::Handle(Array::New(data_len, Heap::kOld));
  intptr_t pos = 0;
  for (intptr_t i = 0; i < aggregate.length(); i++) {
    data.SetAt(pos + 0, Smi::Handle(Smi::New(aggregate[i].cid)));
    data.SetAt(pos + TargetIndexFor(1), *aggregate[i].function);
    data.SetAt(pos + CountIndexFor(1),
               Smi::Handle(Smi::New(aggregate[i].count)));

    pos += result.TestEntryLength();
  }
  WriteSentinel(data, result.TestEntryLength());
  result.set_ic_data_array(data);
  ASSERT(result.NumberOfChecksIs(aggregate.length()));
  return result.raw();
}

bool ICData::AllTargetsHaveSameOwner(intptr_t owner_cid) const {
  if (NumberOfChecksIs(0)) return false;
  Class& cls = Class::Handle();
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (IsUsedAt(i)) {
      cls = Function::Handle(GetTargetAt(i)).Owner();
      if (cls.id() != owner_cid) {
        return false;
      }
    }
  }
  return true;
}

bool ICData::HasReceiverClassId(intptr_t class_id) const {
  ASSERT(NumArgsTested() > 0);
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (IsUsedAt(i)) {
      const intptr_t test_class_id = GetReceiverClassIdAt(i);
      if (test_class_id == class_id) {
        return true;
      }
    }
  }
  return false;
}

// Returns true if all targets are the same.
// TODO(srdjan): if targets are native use their C_function to compare.
bool ICData::HasOneTarget() const {
  ASSERT(!NumberOfChecksIs(0));
  const Function& first_target = Function::Handle(GetTargetAt(0));
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 1; i < len; i++) {
    if (IsUsedAt(i) && (GetTargetAt(i) != first_target.raw())) {
      return false;
    }
  }
  return true;
}

void ICData::GetUsedCidsForTwoArgs(GrowableArray<intptr_t>* first,
                                   GrowableArray<intptr_t>* second) const {
  ASSERT(NumArgsTested() == 2);
  first->Clear();
  second->Clear();
  GrowableArray<intptr_t> class_ids;
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (GetCountAt(i) > 0) {
      GetClassIdsAt(i, &class_ids);
      ASSERT(class_ids.length() == 2);
      first->Add(class_ids[0]);
      second->Add(class_ids[1]);
    }
  }
}

bool ICData::IsUsedAt(intptr_t i) const {
  if (GetCountAt(i) <= 0) {
    // Do not mistake unoptimized static call ICData for unused.
    // See ICData::AddTarget.
    // TODO(srdjan): Make this test more robust.
    if (NumArgsTested() > 0) {
      const intptr_t cid = GetReceiverClassIdAt(i);
      if (cid == kObjectCid) {
        return true;
      }
    }
    return false;
  }
  return true;
}

void ICData::InitOnce() {
  for (int i = 0; i < kCachedICDataArrayCount; i++) {
    cached_icdata_arrays_[i] = ICData::NewNonCachedEmptyICDataArray(i);
  }
}

RawArray* ICData::NewNonCachedEmptyICDataArray(intptr_t num_args_tested) {
  // IC data array must be null terminated (sentinel entry).
  const intptr_t len = TestEntryLengthFor(num_args_tested);
  const Array& array = Array::Handle(Array::New(len, Heap::kOld));
  WriteSentinel(array, len);
  array.MakeImmutable();
  return array.raw();
}

RawArray* ICData::CachedEmptyICDataArray(intptr_t num_args_tested) {
  ASSERT(num_args_tested >= 0);
  ASSERT(num_args_tested < kCachedICDataArrayCount);
  return cached_icdata_arrays_[num_args_tested];
}

// Does not initialize ICData array.
RawICData* ICData::NewDescriptor(Zone* zone,
                                 const Function& owner,
                                 const String& target_name,
                                 const Array& arguments_descriptor,
                                 intptr_t deopt_id,
                                 intptr_t num_args_tested,
                                 bool is_static_call) {
  ASSERT(!owner.IsNull());
  ASSERT(!target_name.IsNull());
  ASSERT(!arguments_descriptor.IsNull());
  ASSERT(Object::icdata_class() != Class::null());
  ASSERT(num_args_tested >= 0);
  ICData& result = ICData::Handle(zone);
  {
    // IC data objects are long living objects, allocate them in old generation.
    RawObject* raw =
        Object::Allocate(ICData::kClassId, ICData::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_owner(owner);
  result.set_target_name(target_name);
  result.set_arguments_descriptor(arguments_descriptor);
  NOT_IN_PRECOMPILED(result.set_deopt_id(deopt_id));
  result.set_state_bits(0);
#if defined(TAG_IC_DATA)
  result.set_tag(-1);
#endif
  result.SetIsStaticCall(is_static_call);
  result.SetNumArgsTested(num_args_tested);
  return result.raw();
}

bool ICData::IsImmutable() const {
  const Array& data = Array::Handle(ic_data());
  return data.IsImmutable();
}

RawICData* ICData::New() {
  ICData& result = ICData::Handle();
  {
    // IC data objects are long living objects, allocate them in old generation.
    RawObject* raw =
        Object::Allocate(ICData::kClassId, ICData::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_deopt_id(Thread::kNoDeoptId);
  result.set_state_bits(0);
#if defined(TAG_IC_DATA)
  result.set_tag(-1);
#endif
  return result.raw();
}

RawICData* ICData::New(const Function& owner,
                       const String& target_name,
                       const Array& arguments_descriptor,
                       intptr_t deopt_id,
                       intptr_t num_args_tested,
                       bool is_static_call) {
  Zone* zone = Thread::Current()->zone();
  const ICData& result = ICData::Handle(
      zone, NewDescriptor(zone, owner, target_name, arguments_descriptor,
                          deopt_id, num_args_tested, is_static_call));
  result.set_ic_data_array(
      Array::Handle(zone, CachedEmptyICDataArray(num_args_tested)));
  return result.raw();
}

RawICData* ICData::NewFrom(const ICData& from, intptr_t num_args_tested) {
  const ICData& result = ICData::Handle(ICData::New(
      Function::Handle(from.Owner()), String::Handle(from.target_name()),
      Array::Handle(from.arguments_descriptor()), from.deopt_id(),
      num_args_tested, from.is_static_call()));
  // Copy deoptimization reasons.
  result.SetDeoptReasons(from.DeoptReasons());
  return result.raw();
}

RawICData* ICData::Clone(const ICData& from) {
  Zone* zone = Thread::Current()->zone();
  const ICData& result = ICData::Handle(ICData::NewDescriptor(
      zone, Function::Handle(zone, from.Owner()),
      String::Handle(zone, from.target_name()),
      Array::Handle(zone, from.arguments_descriptor()), from.deopt_id(),
      from.NumArgsTested(), from.is_static_call()));
  // Clone entry array.
  const Array& from_array = Array::Handle(zone, from.ic_data());
  const intptr_t len = from_array.Length();
  const Array& cloned_array = Array::Handle(zone, Array::New(len, Heap::kOld));
  Object& obj = Object::Handle(zone);
  for (intptr_t i = 0; i < len; i++) {
    obj = from_array.At(i);
    cloned_array.SetAt(i, obj);
  }
  result.set_ic_data_array(cloned_array);
  // Copy deoptimization reasons.
  result.SetDeoptReasons(from.DeoptReasons());
  return result.raw();
}

Code::Comments& Code::Comments::New(intptr_t count) {
  Comments* comments;
  if (count < 0 || count > (kIntptrMax / kNumberOfEntries)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Code::Comments::New: invalid count %" Pd "\n",
           count);
  }
  if (count == 0) {
    comments = new Comments(Object::empty_array());
  } else {
    const Array& data =
        Array::Handle(Array::New(count * kNumberOfEntries, Heap::kOld));
    comments = new Comments(data);
  }
  return *comments;
}

intptr_t Code::Comments::Length() const {
  if (comments_.IsNull()) {
    return 0;
  }
  return comments_.Length() / kNumberOfEntries;
}

intptr_t Code::Comments::PCOffsetAt(intptr_t idx) const {
  return Smi::Value(
      Smi::RawCast(comments_.At(idx * kNumberOfEntries + kPCOffsetEntry)));
}

void Code::Comments::SetPCOffsetAt(intptr_t idx, intptr_t pc) {
  comments_.SetAt(idx * kNumberOfEntries + kPCOffsetEntry,
                  Smi::Handle(Smi::New(pc)));
}

RawString* Code::Comments::CommentAt(intptr_t idx) const {
  return String::RawCast(comments_.At(idx * kNumberOfEntries + kCommentEntry));
}

void Code::Comments::SetCommentAt(intptr_t idx, const String& comment) {
  comments_.SetAt(idx * kNumberOfEntries + kCommentEntry, comment);
}

Code::Comments::Comments(const Array& comments) : comments_(comments) {}

RawLocalVarDescriptors* Code::GetLocalVarDescriptors() const {
  const LocalVarDescriptors& v = LocalVarDescriptors::Handle(var_descriptors());
  if (v.IsNull()) {
    ASSERT(!is_optimized());
    const Function& f = Function::Handle(function());
    ASSERT(!f.IsIrregexpFunction());  // Not yet implemented.
    Compiler::ComputeLocalVarDescriptors(*this);
  }
  return var_descriptors();
}

void Code::set_state_bits(intptr_t bits) const {
  StoreNonPointer(&raw_ptr()->state_bits_, bits);
}

void Code::set_is_optimized(bool value) const {
  set_state_bits(OptimizedBit::update(value, raw_ptr()->state_bits_));
}

void Code::set_is_alive(bool value) const {
  set_state_bits(AliveBit::update(value, raw_ptr()->state_bits_));
}

void Code::set_stackmaps(const Array& maps) const {
  ASSERT(maps.IsOld());
  StorePointer(&raw_ptr()->stackmaps_, maps.raw());
  INC_STAT(Thread::Current(), total_code_size,
           maps.IsNull() ? 0 : maps.Length() * sizeof(uword));
}

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(DART_PRECOMPILER)
void Code::set_variables(const Smi& smi) const {
  StorePointer(&raw_ptr()->catch_entry_.variables_, smi.raw());
}
#else
void Code::set_catch_entry_state_maps(const TypedData& maps) const {
  StorePointer(&raw_ptr()->catch_entry_.catch_entry_state_maps_, maps.raw());
}
#endif

void Code::set_deopt_info_array(const Array& array) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(array.IsOld());
  StorePointer(&raw_ptr()->deopt_info_array_, array.raw());
#endif
}

void Code::set_static_calls_target_table(const Array& value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  StorePointer(&raw_ptr()->static_calls_target_table_, value.raw());
#endif
#if defined(DEBUG)
  // Check that the table is sorted by pc offsets.
  // FlowGraphCompiler::AddStaticCallTarget adds pc-offsets to the table while
  // emitting assembly. This guarantees that every succeeding pc-offset is
  // larger than the previously added one.
  for (intptr_t i = kSCallTableEntryLength; i < value.Length();
       i += kSCallTableEntryLength) {
    ASSERT(value.At(i - kSCallTableEntryLength) < value.At(i));
  }
#endif  // DEBUG
}

bool Code::HasBreakpoint() const {
#if defined(PRODUCT)
  return false;
#else
  return Isolate::Current()->debugger()->HasBreakpoint(*this);
#endif
}

RawTypedData* Code::GetDeoptInfoAtPc(uword pc,
                                     ICData::DeoptReasonId* deopt_reason,
                                     uint32_t* deopt_flags) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
  return TypedData::null();
#else
  ASSERT(is_optimized());
  const Instructions& instrs = Instructions::Handle(instructions());
  uword code_entry = instrs.PayloadStart();
  const Array& table = Array::Handle(deopt_info_array());
  if (table.IsNull()) {
    ASSERT(Dart::vm_snapshot_kind() == Snapshot::kFullAOT);
    return TypedData::null();
  }
  // Linear search for the PC offset matching the target PC.
  intptr_t length = DeoptTable::GetLength(table);
  Smi& offset = Smi::Handle();
  Smi& reason_and_flags = Smi::Handle();
  TypedData& info = TypedData::Handle();
  for (intptr_t i = 0; i < length; ++i) {
    DeoptTable::GetEntry(table, i, &offset, &info, &reason_and_flags);
    if (pc == (code_entry + offset.Value())) {
      ASSERT(!info.IsNull());
      *deopt_reason = DeoptTable::ReasonField::decode(reason_and_flags.Value());
      *deopt_flags = DeoptTable::FlagsField::decode(reason_and_flags.Value());
      return info.raw();
    }
  }
  *deopt_reason = ICData::kDeoptUnknown;
  return TypedData::null();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

intptr_t Code::BinarySearchInSCallTable(uword pc) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  NoSafepointScope no_safepoint;
  const Array& table = Array::Handle(raw_ptr()->static_calls_target_table_);
  RawObject* key = reinterpret_cast<RawObject*>(Smi::New(pc - PayloadStart()));
  intptr_t imin = 0;
  intptr_t imax = table.Length() / kSCallTableEntryLength;
  while (imax >= imin) {
    const intptr_t imid = ((imax - imin) / 2) + imin;
    const intptr_t real_index = imid * kSCallTableEntryLength;
    RawObject* key_in_table = table.At(real_index);
    if (key_in_table < key) {
      imin = imid + 1;
    } else if (key_in_table > key) {
      imax = imid - 1;
    } else {
      return real_index;
    }
  }
#endif
  return -1;
}

RawFunction* Code::GetStaticCallTargetFunctionAt(uword pc) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return Function::null();
#else
  const intptr_t i = BinarySearchInSCallTable(pc);
  if (i < 0) {
    return Function::null();
  }
  const Array& array = Array::Handle(raw_ptr()->static_calls_target_table_);
  Function& function = Function::Handle();
  function ^= array.At(i + kSCallTableFunctionEntry);
  return function.raw();
#endif
}

RawCode* Code::GetStaticCallTargetCodeAt(uword pc) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return Code::null();
#else
  const intptr_t i = BinarySearchInSCallTable(pc);
  if (i < 0) {
    return Code::null();
  }
  const Array& array = Array::Handle(raw_ptr()->static_calls_target_table_);
  Code& code = Code::Handle();
  code ^= array.At(i + kSCallTableCodeEntry);
  return code.raw();
#endif
}

void Code::SetStaticCallTargetCodeAt(uword pc, const Code& code) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  const intptr_t i = BinarySearchInSCallTable(pc);
  ASSERT(i >= 0);
  const Array& array = Array::Handle(raw_ptr()->static_calls_target_table_);
  ASSERT(code.IsNull() ||
         (code.function() == array.At(i + kSCallTableFunctionEntry)));
  array.SetAt(i + kSCallTableCodeEntry, code);
#endif
}

void Code::SetStubCallTargetCodeAt(uword pc, const Code& code) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  const intptr_t i = BinarySearchInSCallTable(pc);
  ASSERT(i >= 0);
  const Array& array = Array::Handle(raw_ptr()->static_calls_target_table_);
#if defined(DEBUG)
  if (array.At(i + kSCallTableFunctionEntry) == Function::null()) {
    ASSERT(!code.IsNull() && Object::Handle(code.owner()).IsClass());
  } else {
    ASSERT(code.IsNull() ||
           (code.function() == array.At(i + kSCallTableFunctionEntry)));
  }
#endif
  array.SetAt(i + kSCallTableCodeEntry, code);
#endif
}

void Code::Disassemble(DisassemblyFormatter* formatter) const {
#if !defined(PRODUCT)
  if (!FLAG_support_disassembler) {
    return;
  }
  const Instructions& instr = Instructions::Handle(instructions());
  uword start = instr.PayloadStart();
  if (formatter == NULL) {
    Disassembler::Disassemble(start, start + instr.Size(), *this);
  } else {
    Disassembler::Disassemble(start, start + instr.Size(), formatter, *this);
  }
#endif
}

const Code::Comments& Code::comments() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  Comments* comments = new Code::Comments(Array::Handle());
#else
  Comments* comments = new Code::Comments(Array::Handle(raw_ptr()->comments_));
#endif
  return *comments;
}

void Code::set_comments(const Code::Comments& comments) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(comments.comments_.IsOld());
  StorePointer(&raw_ptr()->comments_, comments.comments_.raw());
#endif
}

void Code::SetPrologueOffset(intptr_t offset) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(offset >= 0);
  StoreSmi(
      reinterpret_cast<RawSmi* const*>(&raw_ptr()->return_address_metadata_),
      Smi::New(offset));
#endif
}

intptr_t Code::GetPrologueOffset() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  return -1;
#else
  const Object& object = Object::Handle(raw_ptr()->return_address_metadata_);
  // In the future we may put something other than a smi in
  // |return_address_metadata_|.
  if (object.IsNull() || !object.IsSmi()) {
    return -1;
  }
  return Smi::Cast(object).Value();
#endif
}

RawArray* Code::inlined_id_to_function() const {
  return raw_ptr()->inlined_id_to_function_;
}

void Code::set_inlined_id_to_function(const Array& value) const {
  ASSERT(value.IsOld());
  StorePointer(&raw_ptr()->inlined_id_to_function_, value.raw());
}

RawCode* Code::New(intptr_t pointer_offsets_length) {
  if (pointer_offsets_length < 0 || pointer_offsets_length > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Code::New: invalid pointer_offsets_length %" Pd "\n",
           pointer_offsets_length);
  }
  ASSERT(Object::code_class() != Class::null());
  Code& result = Code::Handle();
  {
    uword size = Code::InstanceSize(pointer_offsets_length);
    RawObject* raw = Object::Allocate(Code::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_pointer_offsets_length(pointer_offsets_length);
    result.set_is_optimized(false);
    result.set_is_alive(false);
    result.set_comments(Comments::New(0));
    result.set_compile_timestamp(0);
    result.set_pc_descriptors(Object::empty_descriptors());
  }
  return result.raw();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
RawCode* Code::FinalizeCode(const char* name,
                            Assembler* assembler,
                            bool optimized) {
  Isolate* isolate = Isolate::Current();
  if (!isolate->compilation_allowed()) {
    FATAL1("Precompilation missed code %s\n", name);
  }

  ASSERT(assembler != NULL);
  const ObjectPool& object_pool =
      ObjectPool::Handle(assembler->object_pool_wrapper().MakeObjectPool());

  // Allocate the Code and Instructions objects.  Code is allocated first
  // because a GC during allocation of the code will leave the instruction
  // pages read-only.
  intptr_t pointer_offset_count = assembler->CountPointerOffsets();
  Code& code = Code::ZoneHandle(Code::New(pointer_offset_count));
#ifdef TARGET_ARCH_IA32
  assembler->set_code_object(code);
#endif
  Instructions& instrs = Instructions::ZoneHandle(Instructions::New(
      assembler->CodeSize(), assembler->has_single_entry_point()));
  INC_STAT(Thread::Current(), total_instr_size, assembler->CodeSize());
  INC_STAT(Thread::Current(), total_code_size, assembler->CodeSize());

  // Copy the instructions into the instruction area and apply all fixups.
  // Embedded pointers are still in handles at this point.
  MemoryRegion region(reinterpret_cast<void*>(instrs.PayloadStart()),
                      instrs.Size());
  assembler->FinalizeInstructions(region);
  CPU::FlushICache(instrs.PayloadStart(), instrs.Size());

  code.set_compile_timestamp(OS::GetCurrentMonotonicMicros());
#ifndef PRODUCT
  CodeObservers::NotifyAll(name, instrs.PayloadStart(),
                           assembler->prologue_offset(), instrs.Size(),
                           optimized);
#endif
  {
    NoSafepointScope no_safepoint;
    const ZoneGrowableArray<intptr_t>& pointer_offsets =
        assembler->GetPointerOffsets();
    ASSERT(pointer_offsets.length() == pointer_offset_count);
    ASSERT(code.pointer_offsets_length() == pointer_offsets.length());

    // Set pointer offsets list in Code object and resolve all handles in
    // the instruction stream to raw objects.
    for (intptr_t i = 0; i < pointer_offsets.length(); i++) {
      intptr_t offset_in_instrs = pointer_offsets[i];
      code.SetPointerOffsetAt(i, offset_in_instrs);
      uword addr = region.start() + offset_in_instrs;
      const Object* object = *reinterpret_cast<Object**>(addr);
      instrs.raw()->StorePointer(reinterpret_cast<RawObject**>(addr),
                                 object->raw());
    }

    // Hook up Code and Instructions objects.
    code.SetActiveInstructions(instrs);
    code.set_instructions(instrs);
    code.set_is_alive(true);

    // Set object pool in Instructions object.
    INC_STAT(Thread::Current(), total_code_size,
             object_pool.Length() * sizeof(uintptr_t));
    code.set_object_pool(object_pool.raw());

    if (FLAG_write_protect_code) {
      uword address = RawObject::ToAddr(instrs.raw());
      bool status = VirtualMemory::Protect(reinterpret_cast<void*>(address),
                                           instrs.raw()->Size(),
                                           VirtualMemory::kReadExecute);
      ASSERT(status);
    }
  }
  code.set_comments(assembler->GetCodeComments());
  if (assembler->prologue_offset() >= 0) {
    code.SetPrologueOffset(assembler->prologue_offset());
  } else {
    // No prologue was ever entered, optimistically assume nothing was ever
    // pushed onto the stack.
    code.SetPrologueOffset(assembler->CodeSize());
  }
  INC_STAT(Thread::Current(), total_code_size,
           code.comments().comments_.Length());
  return code.raw();
}

RawCode* Code::FinalizeCode(const Function& function,
                            Assembler* assembler,
                            bool optimized) {
// Calling ToLibNamePrefixedQualifiedCString is very expensive,
// try to avoid it.
#ifndef PRODUCT
  if (CodeObservers::AreActive()) {
    return FinalizeCode(function.ToLibNamePrefixedQualifiedCString(), assembler,
                        optimized);
  }
#endif  // !PRODUCT
  return FinalizeCode("", assembler, optimized);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

bool Code::SlowFindRawCodeVisitor::FindObject(RawObject* raw_obj) const {
  return RawCode::ContainsPC(raw_obj, pc_);
}

RawCode* Code::LookupCodeInIsolate(Isolate* isolate, uword pc) {
  ASSERT((isolate == Isolate::Current()) || (isolate == Dart::vm_isolate()));
  if (isolate->heap() == NULL) {
    return Code::null();
  }
  HeapIterationScope heap_iteration_scope(Thread::Current());
  SlowFindRawCodeVisitor visitor(pc);
  RawObject* needle = isolate->heap()->FindOldObject(&visitor);
  if (needle != Code::null()) {
    return static_cast<RawCode*>(needle);
  }
  return Code::null();
}

RawCode* Code::LookupCode(uword pc) {
  return LookupCodeInIsolate(Isolate::Current(), pc);
}

RawCode* Code::LookupCodeInVmIsolate(uword pc) {
  return LookupCodeInIsolate(Dart::vm_isolate(), pc);
}

// Given a pc and a timestamp, lookup the code.
RawCode* Code::FindCode(uword pc, int64_t timestamp) {
  Code& code = Code::Handle(Code::LookupCode(pc));
  if (!code.IsNull() && (code.compile_timestamp() == timestamp) &&
      (code.PayloadStart() == pc)) {
    // Found code in isolate.
    return code.raw();
  }
  code ^= Code::LookupCodeInVmIsolate(pc);
  if (!code.IsNull() && (code.compile_timestamp() == timestamp) &&
      (code.PayloadStart() == pc)) {
    // Found code in VM isolate.
    return code.raw();
  }
  return Code::null();
}

TokenPosition Code::GetTokenIndexOfPC(uword pc) const {
  uword pc_offset = pc - PayloadStart();
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return iter.TokenPos();
    }
  }
  return TokenPosition::kNoSource;
}

uword Code::GetPcForDeoptId(intptr_t deopt_id,
                            RawPcDescriptors::Kind kind) const {
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, kind);
  while (iter.MoveNext()) {
    if (iter.DeoptId() == deopt_id) {
      uword pc_offset = iter.PcOffset();
      uword pc = PayloadStart() + pc_offset;
      ASSERT(ContainsInstructionAt(pc));
      return pc;
    }
  }
  return 0;
}

intptr_t Code::GetDeoptIdForOsr(uword pc) const {
  uword pc_offset = pc - PayloadStart();
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kOsrEntry);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return iter.DeoptId();
    }
  }
  return Thread::kNoDeoptId;
}

const char* Code::ToCString() const {
  return Thread::Current()->zone()->PrintToString("Code(%s)", QualifiedName());
}

const char* Code::Name() const {
  Zone* zone = Thread::Current()->zone();
  const Object& obj = Object::Handle(zone, owner());
  if (obj.IsNull()) {
    // Regular stub.
    const char* name = StubCode::NameOfStub(UncheckedEntryPoint());
    if (name == NULL) {
      ASSERT(!StubCode::HasBeenInitialized());
      return zone->PrintToString("[this stub]");  // Not yet recorded.
    }
    return zone->PrintToString("[Stub] %s", name);
  } else if (obj.IsClass()) {
    // Allocation stub.
    String& cls_name = String::Handle(zone, Class::Cast(obj).ScrubbedName());
    ASSERT(!cls_name.IsNull());
    return zone->PrintToString("[Stub] Allocate %s", cls_name.ToCString());
  } else {
    ASSERT(obj.IsFunction());
    // Dart function.
    const char* opt = is_optimized() ? "*" : "";
    const char* function_name =
        String::Handle(zone, Function::Cast(obj).UserVisibleName()).ToCString();
    return zone->PrintToString("%s%s", opt, function_name);
  }
}

const char* Code::QualifiedName() const {
  Zone* zone = Thread::Current()->zone();
  const Object& obj = Object::Handle(zone, owner());
  if (obj.IsFunction()) {
    const char* opt = is_optimized() ? "*" : "";
    const char* function_name =
        String::Handle(zone, Function::Cast(obj).QualifiedScrubbedName())
            .ToCString();
    return zone->PrintToString("%s%s", opt, function_name);
  }
  return Name();
}

bool Code::IsAllocationStubCode() const {
  const Object& obj = Object::Handle(owner());
  return obj.IsClass();
}

bool Code::IsStubCode() const {
  const Object& obj = Object::Handle(owner());
  return obj.IsNull();
}

bool Code::IsFunctionCode() const {
  const Object& obj = Object::Handle(owner());
  return obj.IsFunction();
}

void Code::DisableDartCode() const {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  ASSERT(IsFunctionCode());
  ASSERT(instructions() == active_instructions());
  const Code& new_code =
      Code::Handle(StubCode::FixCallersTarget_entry()->code());
  SetActiveInstructions(Instructions::Handle(new_code.instructions()));
}

void Code::DisableStubCode() const {
#if !defined(TARGET_ARCH_DBC)
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsAllocationStubCode());
  ASSERT(instructions() == active_instructions());
  const Code& new_code =
      Code::Handle(StubCode::FixAllocationStubTarget_entry()->code());
  SetActiveInstructions(Instructions::Handle(new_code.instructions()));
#else
  // DBC does not use allocation stubs.
  UNIMPLEMENTED();
#endif  // !defined(TARGET_ARCH_DBC)
}

void Code::SetActiveInstructions(const Instructions& instructions) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  DEBUG_ASSERT(IsMutatorOrAtSafepoint() || !is_alive());
  // RawInstructions are never allocated in New space and hence a
  // store buffer update is not needed here.
  StorePointer(&raw_ptr()->active_instructions_, instructions.raw());
  StoreNonPointer(&raw_ptr()->entry_point_,
                  Instructions::UncheckedEntryPoint(instructions.raw()));
  StoreNonPointer(&raw_ptr()->checked_entry_point_,
                  Instructions::CheckedEntryPoint(instructions.raw()));
#endif
}

RawStackMap* Code::GetStackMap(uint32_t pc_offset,
                               Array* maps,
                               StackMap* map) const {
  // This code is used during iterating frames during a GC and hence it
  // should not in turn start a GC.
  NoSafepointScope no_safepoint;
  if (stackmaps() == Array::null()) {
    // No stack maps are present in the code object which means this
    // frame relies on tagged pointers.
    return StackMap::null();
  }
  // A stack map is present in the code object, use the stack map to visit
  // frame slots which are marked as having objects.
  *maps = stackmaps();
  *map = StackMap::null();
  for (intptr_t i = 0; i < maps->Length(); i++) {
    *map ^= maps->At(i);
    ASSERT(!map->IsNull());
    if (map->PcOffset() == pc_offset) {
      return map->raw();  // We found a stack map for this frame.
    }
  }
  // If we are missing a stack map, this must either be unoptimized code, or
  // the entry to an osr function. (In which case all stack slots are
  // considered to have tagged pointers.)
  // Running with --verify-on-transition should hit this.
  ASSERT(!is_optimized() ||
         (pc_offset == UncheckedEntryPoint() - PayloadStart()));
  return StackMap::null();
}

void Code::GetInlinedFunctionsAtInstruction(
    intptr_t pc_offset,
    GrowableArray<const Function*>* functions,
    GrowableArray<TokenPosition>* token_positions) const {
  const CodeSourceMap& map = CodeSourceMap::Handle(code_source_map());
  if (map.IsNull()) {
    ASSERT(!IsFunctionCode() ||
           (Isolate::Current()->object_store()->megamorphic_miss_code() ==
            this->raw()));
    return;  // VM stub, allocation stub, or megamorphic miss function.
  }
  const Array& id_map = Array::Handle(inlined_id_to_function());
  const Function& root = Function::Handle(function());
  CodeSourceMapReader reader(map, id_map, root);
  reader.GetInlinedFunctionsAt(pc_offset, functions, token_positions);
}

#ifndef PRODUCT
void Code::PrintJSONInlineIntervals(JSONObject* jsobj) const {
  if (!is_optimized()) {
    return;  // No inlining.
  }
  const CodeSourceMap& map = CodeSourceMap::Handle(code_source_map());
  const Array& id_map = Array::Handle(inlined_id_to_function());
  const Function& root = Function::Handle(function());
  CodeSourceMapReader reader(map, id_map, root);
  reader.PrintJSONInlineIntervals(jsobj);
}
#endif

void Code::DumpInlineIntervals() const {
  const CodeSourceMap& map = CodeSourceMap::Handle(code_source_map());
  if (map.IsNull()) {
    // Stub code.
    return;
  }
  const Array& id_map = Array::Handle(inlined_id_to_function());
  const Function& root = Function::Handle(function());
  CodeSourceMapReader reader(map, id_map, root);
  reader.DumpInlineIntervals(PayloadStart());
}

void Code::DumpSourcePositions() const {
  const CodeSourceMap& map = CodeSourceMap::Handle(code_source_map());
  if (map.IsNull()) {
    // Stub code.
    return;
  }
  const Array& id_map = Array::Handle(inlined_id_to_function());
  const Function& root = Function::Handle(function());
  CodeSourceMapReader reader(map, id_map, root);
  reader.DumpSourcePositions(PayloadStart());
}

RawArray* Code::await_token_positions() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Array::null();
#else
  return raw_ptr()->await_token_positions_;
#endif
}

RawContext* Context::New(intptr_t num_variables, Heap::Space space) {
  ASSERT(num_variables >= 0);
  ASSERT(Object::context_class() != Class::null());

  if (num_variables < 0 || num_variables > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Context::New: invalid num_variables %" Pd "\n",
           num_variables);
  }
  Context& result = Context::Handle();
  {
    RawObject* raw = Object::Allocate(
        Context::kClassId, Context::InstanceSize(num_variables), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_num_variables(num_variables);
  }
  return result.raw();
}

const char* Context::ToCString() const {
  if (IsNull()) {
    return "Context: null";
  }
  Zone* zone = Thread::Current()->zone();
  const Context& parent_ctx = Context::Handle(parent());
  if (parent_ctx.IsNull()) {
    return zone->PrintToString("Context num_variables: %" Pd "",
                               num_variables());
  } else {
    const char* parent_str = parent_ctx.ToCString();
    return zone->PrintToString("Context num_variables: %" Pd " parent:{ %s }",
                               num_variables(), parent_str);
  }
}

static void IndentN(int count) {
  for (int i = 0; i < count; i++) {
    THR_Print(" ");
  }
}

void Context::Dump(int indent) const {
  if (IsNull()) {
    IndentN(indent);
    THR_Print("Context@null\n");
    return;
  }

  IndentN(indent);
  THR_Print("Context@%p vars(%" Pd ") {\n", this->raw(), num_variables());
  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < num_variables(); i++) {
    IndentN(indent + 2);
    obj = At(i);
    const char* s = obj.ToCString();
    if (strlen(s) > 50) {
      THR_Print("[%" Pd "] = [first 50 chars:] %.50s...\n", i, s);
    } else {
      THR_Print("[%" Pd "] = %s\n", i, s);
    }
  }

  const Context& parent_ctx = Context::Handle(parent());
  if (!parent_ctx.IsNull()) {
    parent_ctx.Dump(indent + 2);
  }
  IndentN(indent);
  THR_Print("}\n");
}

RawContextScope* ContextScope::New(intptr_t num_variables, bool is_implicit) {
  ASSERT(Object::context_scope_class() != Class::null());
  if (num_variables < 0 || num_variables > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ContextScope::New: invalid num_variables %" Pd "\n",
           num_variables);
  }
  intptr_t size = ContextScope::InstanceSize(num_variables);
  ContextScope& result = ContextScope::Handle();
  {
    RawObject* raw = Object::Allocate(ContextScope::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_num_variables(num_variables);
    result.set_is_implicit(is_implicit);
  }
  return result.raw();
}

TokenPosition ContextScope::TokenIndexAt(intptr_t scope_index) const {
  return TokenPosition(Smi::Value(VariableDescAddr(scope_index)->token_pos));
}

void ContextScope::SetTokenIndexAt(intptr_t scope_index,
                                   TokenPosition token_pos) const {
  StoreSmi(&VariableDescAddr(scope_index)->token_pos,
           Smi::New(token_pos.value()));
}

TokenPosition ContextScope::DeclarationTokenIndexAt(
    intptr_t scope_index) const {
  return TokenPosition(
      Smi::Value(VariableDescAddr(scope_index)->declaration_token_pos));
}

void ContextScope::SetDeclarationTokenIndexAt(
    intptr_t scope_index,
    TokenPosition declaration_token_pos) const {
  StoreSmi(&VariableDescAddr(scope_index)->declaration_token_pos,
           Smi::New(declaration_token_pos.value()));
}

RawString* ContextScope::NameAt(intptr_t scope_index) const {
  return VariableDescAddr(scope_index)->name;
}

void ContextScope::SetNameAt(intptr_t scope_index, const String& name) const {
  StorePointer(&(VariableDescAddr(scope_index)->name), name.raw());
}

bool ContextScope::IsFinalAt(intptr_t scope_index) const {
  return Bool::Handle(VariableDescAddr(scope_index)->is_final).value();
}

void ContextScope::SetIsFinalAt(intptr_t scope_index, bool is_final) const {
  StorePointer(&(VariableDescAddr(scope_index)->is_final),
               Bool::Get(is_final).raw());
}

bool ContextScope::IsConstAt(intptr_t scope_index) const {
  return Bool::Handle(VariableDescAddr(scope_index)->is_const).value();
}

void ContextScope::SetIsConstAt(intptr_t scope_index, bool is_const) const {
  StorePointer(&(VariableDescAddr(scope_index)->is_const),
               Bool::Get(is_const).raw());
}

RawAbstractType* ContextScope::TypeAt(intptr_t scope_index) const {
  ASSERT(!IsConstAt(scope_index));
  return VariableDescAddr(scope_index)->type;
}

void ContextScope::SetTypeAt(intptr_t scope_index,
                             const AbstractType& type) const {
  StorePointer(&(VariableDescAddr(scope_index)->type), type.raw());
}

RawInstance* ContextScope::ConstValueAt(intptr_t scope_index) const {
  ASSERT(IsConstAt(scope_index));
  return VariableDescAddr(scope_index)->value;
}

void ContextScope::SetConstValueAt(intptr_t scope_index,
                                   const Instance& value) const {
  ASSERT(IsConstAt(scope_index));
  StorePointer(&(VariableDescAddr(scope_index)->value), value.raw());
}

intptr_t ContextScope::ContextIndexAt(intptr_t scope_index) const {
  return Smi::Value(VariableDescAddr(scope_index)->context_index);
}

void ContextScope::SetContextIndexAt(intptr_t scope_index,
                                     intptr_t context_index) const {
  StoreSmi(&(VariableDescAddr(scope_index)->context_index),
           Smi::New(context_index));
}

intptr_t ContextScope::ContextLevelAt(intptr_t scope_index) const {
  return Smi::Value(VariableDescAddr(scope_index)->context_level);
}

void ContextScope::SetContextLevelAt(intptr_t scope_index,
                                     intptr_t context_level) const {
  StoreSmi(&(VariableDescAddr(scope_index)->context_level),
           Smi::New(context_level));
}

const char* ContextScope::ToCString() const {
  const char* prev_cstr = "ContextScope:";
  String& name = String::Handle();
  for (int i = 0; i < num_variables(); i++) {
    name = NameAt(i);
    const char* cname = name.ToCString();
    TokenPosition pos = TokenIndexAt(i);
    intptr_t idx = ContextIndexAt(i);
    intptr_t lvl = ContextLevelAt(i);
    char* chars =
        OS::SCreate(Thread::Current()->zone(),
                    "%s\nvar %s  token-pos %s  ctx lvl %" Pd "  index %" Pd "",
                    prev_cstr, cname, pos.ToCString(), lvl, idx);
    prev_cstr = chars;
  }
  return prev_cstr;
}

RawArray* MegamorphicCache::buckets() const {
  return raw_ptr()->buckets_;
}

void MegamorphicCache::set_buckets(const Array& buckets) const {
  StorePointer(&raw_ptr()->buckets_, buckets.raw());
}

// Class IDs in the table are smi-tagged, so we use a smi-tagged mask
// and target class ID to avoid untagging (on each iteration of the
// test loop) in generated code.
intptr_t MegamorphicCache::mask() const {
  return Smi::Value(raw_ptr()->mask_);
}

void MegamorphicCache::set_mask(intptr_t mask) const {
  StoreSmi(&raw_ptr()->mask_, Smi::New(mask));
}

intptr_t MegamorphicCache::filled_entry_count() const {
  return raw_ptr()->filled_entry_count_;
}

void MegamorphicCache::set_filled_entry_count(intptr_t count) const {
  StoreNonPointer(&raw_ptr()->filled_entry_count_, count);
}

void MegamorphicCache::set_target_name(const String& value) const {
  StorePointer(&raw_ptr()->target_name_, value.raw());
}

void MegamorphicCache::set_arguments_descriptor(const Array& value) const {
  StorePointer(&raw_ptr()->args_descriptor_, value.raw());
}

RawMegamorphicCache* MegamorphicCache::New() {
  MegamorphicCache& result = MegamorphicCache::Handle();
  {
    RawObject* raw =
        Object::Allocate(MegamorphicCache::kClassId,
                         MegamorphicCache::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_filled_entry_count(0);
  return result.raw();
}

RawMegamorphicCache* MegamorphicCache::New(const String& target_name,
                                           const Array& arguments_descriptor) {
  MegamorphicCache& result = MegamorphicCache::Handle();
  {
    RawObject* raw =
        Object::Allocate(MegamorphicCache::kClassId,
                         MegamorphicCache::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  const intptr_t capacity = kInitialCapacity;
  const Array& buckets =
      Array::Handle(Array::New(kEntryLength * capacity, Heap::kOld));
  const Function& handler =
      Function::Handle(MegamorphicCacheTable::miss_handler(Isolate::Current()));
  for (intptr_t i = 0; i < capacity; ++i) {
    SetEntry(buckets, i, smi_illegal_cid(), handler);
  }
  result.set_buckets(buckets);
  result.set_mask(capacity - 1);
  result.set_target_name(target_name);
  result.set_arguments_descriptor(arguments_descriptor);
  result.set_filled_entry_count(0);
  return result.raw();
}

void MegamorphicCache::EnsureCapacity() const {
  intptr_t old_capacity = mask() + 1;
  double load_limit = kLoadFactor * static_cast<double>(old_capacity);
  if (static_cast<double>(filled_entry_count() + 1) > load_limit) {
    const Array& old_buckets = Array::Handle(buckets());
    intptr_t new_capacity = old_capacity * 2;
    const Array& new_buckets =
        Array::Handle(Array::New(kEntryLength * new_capacity));

    Function& target = Function::Handle(
        MegamorphicCacheTable::miss_handler(Isolate::Current()));
    for (intptr_t i = 0; i < new_capacity; ++i) {
      SetEntry(new_buckets, i, smi_illegal_cid(), target);
    }
    set_buckets(new_buckets);
    set_mask(new_capacity - 1);
    set_filled_entry_count(0);

    // Rehash the valid entries.
    Smi& class_id = Smi::Handle();
    for (intptr_t i = 0; i < old_capacity; ++i) {
      class_id ^= GetClassId(old_buckets, i);
      if (class_id.Value() != kIllegalCid) {
        target ^= GetTargetFunction(old_buckets, i);
        Insert(class_id, target);
      }
    }
  }
}

void MegamorphicCache::Insert(const Smi& class_id,
                              const Function& target) const {
  ASSERT(static_cast<double>(filled_entry_count() + 1) <=
         (kLoadFactor * static_cast<double>(mask() + 1)));
  const Array& backing_array = Array::Handle(buckets());
  intptr_t id_mask = mask();
  intptr_t index = (class_id.Value() * kSpreadFactor) & id_mask;
  intptr_t i = index;
  do {
    if (Smi::Value(Smi::RawCast(GetClassId(backing_array, i))) == kIllegalCid) {
      SetEntry(backing_array, i, class_id, target);
      set_filled_entry_count(filled_entry_count() + 1);
      return;
    }
    i = (i + 1) & id_mask;
  } while (i != index);
  UNREACHABLE();
}

const char* MegamorphicCache::ToCString() const {
  const String& name = String::Handle(target_name());
  return OS::SCreate(Thread::Current()->zone(), "MegamorphicCache(%s)",
                     name.ToCString());
}

RawSubtypeTestCache* SubtypeTestCache::New() {
  ASSERT(Object::subtypetestcache_class() != Class::null());
  SubtypeTestCache& result = SubtypeTestCache::Handle();
  {
    // SubtypeTestCache objects are long living objects, allocate them in the
    // old generation.
    RawObject* raw =
        Object::Allocate(SubtypeTestCache::kClassId,
                         SubtypeTestCache::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  const Array& cache = Array::Handle(Array::New(kTestEntryLength, Heap::kOld));
  result.set_cache(cache);
  return result.raw();
}

void SubtypeTestCache::set_cache(const Array& value) const {
  StorePointer(&raw_ptr()->cache_, value.raw());
}

intptr_t SubtypeTestCache::NumberOfChecks() const {
  NoSafepointScope no_safepoint;
  // Do not count the sentinel;
  return (Smi::Value(cache()->ptr()->length_) / kTestEntryLength) - 1;
}

void SubtypeTestCache::AddCheck(
    const Object& instance_class_id_or_function,
    const TypeArguments& instance_type_arguments,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const Bool& test_result) const {
  intptr_t old_num = NumberOfChecks();
  Array& data = Array::Handle(cache());
  intptr_t new_len = data.Length() + kTestEntryLength;
  data = Array::Grow(data, new_len);
  set_cache(data);
  intptr_t data_pos = old_num * kTestEntryLength;
  data.SetAt(data_pos + kInstanceClassIdOrFunction,
             instance_class_id_or_function);
  data.SetAt(data_pos + kInstanceTypeArguments, instance_type_arguments);
  data.SetAt(data_pos + kInstantiatorTypeArguments,
             instantiator_type_arguments);
  data.SetAt(data_pos + kFunctionTypeArguments, function_type_arguments);
  data.SetAt(data_pos + kTestResult, test_result);
}

void SubtypeTestCache::GetCheck(intptr_t ix,
                                Object* instance_class_id_or_function,
                                TypeArguments* instance_type_arguments,
                                TypeArguments* instantiator_type_arguments,
                                TypeArguments* function_type_arguments,
                                Bool* test_result) const {
  Array& data = Array::Handle(cache());
  intptr_t data_pos = ix * kTestEntryLength;
  *instance_class_id_or_function =
      data.At(data_pos + kInstanceClassIdOrFunction);
  *instance_type_arguments ^= data.At(data_pos + kInstanceTypeArguments);
  *instantiator_type_arguments ^=
      data.At(data_pos + kInstantiatorTypeArguments);
  *function_type_arguments ^= data.At(data_pos + kFunctionTypeArguments);
  *test_result ^= data.At(data_pos + kTestResult);
}

const char* SubtypeTestCache::ToCString() const {
  return "SubtypeTestCache";
}

const char* Error::ToErrorCString() const {
  if (IsNull()) {
    return "Error: null";
  }
  UNREACHABLE();
  return "Error";
}

const char* Error::ToCString() const {
  if (IsNull()) {
    return "Error: null";
  }
  // Error is an abstract class.  We should never reach here.
  UNREACHABLE();
  return "Error";
}

RawApiError* ApiError::New() {
  ASSERT(Object::api_error_class() != Class::null());
  RawObject* raw = Object::Allocate(ApiError::kClassId,
                                    ApiError::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawApiError*>(raw);
}

RawApiError* ApiError::New(const String& message, Heap::Space space) {
#ifndef PRODUCT
  if (FLAG_print_stacktrace_at_api_error) {
    OS::PrintErr("ApiError: %s\n", message.ToCString());
    Profiler::DumpStackTrace(false /* for_crash */);
  }
#endif  // !PRODUCT

  ASSERT(Object::api_error_class() != Class::null());
  ApiError& result = ApiError::Handle();
  {
    RawObject* raw =
        Object::Allocate(ApiError::kClassId, ApiError::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_message(message);
  return result.raw();
}

void ApiError::set_message(const String& message) const {
  StorePointer(&raw_ptr()->message_, message.raw());
}

const char* ApiError::ToErrorCString() const {
  const String& msg_str = String::Handle(message());
  return msg_str.ToCString();
}

const char* ApiError::ToCString() const {
  return "ApiError";
}

RawLanguageError* LanguageError::New() {
  ASSERT(Object::language_error_class() != Class::null());
  RawObject* raw = Object::Allocate(LanguageError::kClassId,
                                    LanguageError::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawLanguageError*>(raw);
}

RawLanguageError* LanguageError::NewFormattedV(const Error& prev_error,
                                               const Script& script,
                                               TokenPosition token_pos,
                                               bool report_after_token,
                                               Report::Kind kind,
                                               Heap::Space space,
                                               const char* format,
                                               va_list args) {
  ASSERT(Object::language_error_class() != Class::null());
  LanguageError& result = LanguageError::Handle();
  {
    RawObject* raw = Object::Allocate(LanguageError::kClassId,
                                      LanguageError::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_previous_error(prev_error);
  result.set_script(script);
  result.set_token_pos(token_pos);
  result.set_report_after_token(report_after_token);
  result.set_kind(kind);
  result.set_message(
      String::Handle(String::NewFormattedV(format, args, space)));
  return result.raw();
}

RawLanguageError* LanguageError::NewFormatted(const Error& prev_error,
                                              const Script& script,
                                              TokenPosition token_pos,
                                              bool report_after_token,
                                              Report::Kind kind,
                                              Heap::Space space,
                                              const char* format,
                                              ...) {
  va_list args;
  va_start(args, format);
  RawLanguageError* result = LanguageError::NewFormattedV(
      prev_error, script, token_pos, report_after_token, kind, space, format,
      args);
  NoSafepointScope no_safepoint;
  va_end(args);
  return result;
}

RawLanguageError* LanguageError::New(const String& formatted_message,
                                     Report::Kind kind,
                                     Heap::Space space) {
  ASSERT(Object::language_error_class() != Class::null());
  LanguageError& result = LanguageError::Handle();
  {
    RawObject* raw = Object::Allocate(LanguageError::kClassId,
                                      LanguageError::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_formatted_message(formatted_message);
  result.set_kind(kind);
  return result.raw();
}

void LanguageError::set_previous_error(const Error& value) const {
  StorePointer(&raw_ptr()->previous_error_, value.raw());
}

void LanguageError::set_script(const Script& value) const {
  StorePointer(&raw_ptr()->script_, value.raw());
}

void LanguageError::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

void LanguageError::set_report_after_token(bool value) {
  StoreNonPointer(&raw_ptr()->report_after_token_, value);
}

void LanguageError::set_kind(uint8_t value) const {
  StoreNonPointer(&raw_ptr()->kind_, value);
}

void LanguageError::set_message(const String& value) const {
  StorePointer(&raw_ptr()->message_, value.raw());
}

void LanguageError::set_formatted_message(const String& value) const {
  StorePointer(&raw_ptr()->formatted_message_, value.raw());
}

RawString* LanguageError::FormatMessage() const {
  if (formatted_message() != String::null()) {
    return formatted_message();
  }
  String& result = String::Handle(
      Report::PrependSnippet(kind(), Script::Handle(script()), token_pos(),
                             report_after_token(), String::Handle(message())));
  // Prepend previous error message.
  const Error& prev_error = Error::Handle(previous_error());
  if (!prev_error.IsNull()) {
    result = String::Concat(
        String::Handle(String::New(prev_error.ToErrorCString())), result);
  }
  set_formatted_message(result);
  return result.raw();
}

const char* LanguageError::ToErrorCString() const {
  Thread* thread = Thread::Current();
  NoReloadScope no_reload_scope(thread->isolate(), thread);
  const String& msg_str = String::Handle(FormatMessage());
  return msg_str.ToCString();
}

const char* LanguageError::ToCString() const {
  return "LanguageError";
}

RawUnhandledException* UnhandledException::New(const Instance& exception,
                                               const Instance& stacktrace,
                                               Heap::Space space) {
  ASSERT(Object::unhandled_exception_class() != Class::null());
  UnhandledException& result = UnhandledException::Handle();
  {
    RawObject* raw =
        Object::Allocate(UnhandledException::kClassId,
                         UnhandledException::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_exception(exception);
  result.set_stacktrace(stacktrace);
  return result.raw();
}

RawUnhandledException* UnhandledException::New(Heap::Space space) {
  ASSERT(Object::unhandled_exception_class() != Class::null());
  UnhandledException& result = UnhandledException::Handle();
  {
    RawObject* raw =
        Object::Allocate(UnhandledException::kClassId,
                         UnhandledException::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_exception(Object::null_instance());
  result.set_stacktrace(StackTrace::Handle());
  return result.raw();
}

void UnhandledException::set_exception(const Instance& exception) const {
  StorePointer(&raw_ptr()->exception_, exception.raw());
}

void UnhandledException::set_stacktrace(const Instance& stacktrace) const {
  StorePointer(&raw_ptr()->stacktrace_, stacktrace.raw());
}

const char* UnhandledException::ToErrorCString() const {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  NoReloadScope no_reload_scope(isolate, thread);
  HANDLESCOPE(thread);
  Object& strtmp = Object::Handle();
  const char* exc_str;
  if (exception() == isolate->object_store()->out_of_memory()) {
    exc_str = "Out of Memory";
  } else if (exception() == isolate->object_store()->stack_overflow()) {
    exc_str = "Stack Overflow";
  } else {
    const Instance& exc = Instance::Handle(exception());
    strtmp = DartLibraryCalls::ToString(exc);
    if (!strtmp.IsError()) {
      exc_str = strtmp.ToCString();
    } else {
      exc_str = "<Received error while converting exception to string>";
    }
  }
  const Instance& stack = Instance::Handle(stacktrace());
  strtmp = DartLibraryCalls::ToString(stack);
  const char* stack_str =
      "<Received error while converting stack trace to string>";
  if (!strtmp.IsError()) {
    stack_str = strtmp.ToCString();
  }
  return OS::SCreate(thread->zone(), "Unhandled exception:\n%s\n%s", exc_str,
                     stack_str);
}

const char* UnhandledException::ToCString() const {
  return "UnhandledException";
}

RawUnwindError* UnwindError::New(const String& message, Heap::Space space) {
  ASSERT(Object::unwind_error_class() != Class::null());
  UnwindError& result = UnwindError::Handle();
  {
    RawObject* raw = Object::Allocate(UnwindError::kClassId,
                                      UnwindError::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_message(message);
  result.set_is_user_initiated(false);
  return result.raw();
}

void UnwindError::set_message(const String& message) const {
  StorePointer(&raw_ptr()->message_, message.raw());
}

void UnwindError::set_is_user_initiated(bool value) const {
  StoreNonPointer(&raw_ptr()->is_user_initiated_, value);
}

const char* UnwindError::ToErrorCString() const {
  const String& msg_str = String::Handle(message());
  return msg_str.ToCString();
}

const char* UnwindError::ToCString() const {
  return "UnwindError";
}

RawObject* Instance::Evaluate(const Class& method_cls,
                              const String& expr,
                              const Array& param_names,
                              const Array& param_values) const {
  const Function& eval_func = Function::Handle(
      Function::EvaluateHelper(method_cls, expr, param_names, false));
  const Array& args = Array::Handle(Array::New(1 + param_values.Length()));
  PassiveObject& param = PassiveObject::Handle();
  args.SetAt(0, *this);
  for (intptr_t i = 0; i < param_values.Length(); i++) {
    param = param_values.At(i);
    args.SetAt(i + 1, param);
  }
  return DartEntry::InvokeFunction(eval_func, args);
}

RawObject* Instance::HashCode() const {
  // TODO(koda): Optimize for all builtin classes and all classes
  // that do not override hashCode.
  return DartLibraryCalls::HashCode(*this);
}

RawObject* Instance::IdentityHashCode() const {
  return DartLibraryCalls::IdentityHashCode(*this);
}

bool Instance::CanonicalizeEquals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    return true;  // "===".
  }

  if (other.IsNull() || (this->clazz() != other.clazz())) {
    return false;
  }

  {
    NoSafepointScope no_safepoint;
    // Raw bits compare.
    const intptr_t instance_size = SizeFromClass();
    ASSERT(instance_size != 0);
    const intptr_t other_instance_size = other.SizeFromClass();
    ASSERT(other_instance_size != 0);
    if (instance_size != other_instance_size) {
      return false;
    }
    uword this_addr = reinterpret_cast<uword>(this->raw_ptr());
    uword other_addr = reinterpret_cast<uword>(other.raw_ptr());
    for (intptr_t offset = Instance::NextFieldOffset(); offset < instance_size;
         offset += kWordSize) {
      if ((*reinterpret_cast<RawObject**>(this_addr + offset)) !=
          (*reinterpret_cast<RawObject**>(other_addr + offset))) {
        return false;
      }
    }
  }
  return true;
}

uword Instance::ComputeCanonicalTableHash() const {
  ASSERT(!IsNull());
  NoSafepointScope no_safepoint;
  const intptr_t instance_size = SizeFromClass();
  ASSERT(instance_size != 0);
  uword hash = instance_size;
  uword this_addr = reinterpret_cast<uword>(this->raw_ptr());
  for (intptr_t offset = Instance::NextFieldOffset(); offset < instance_size;
       offset += kWordSize) {
    uword value = reinterpret_cast<uword>(
        *reinterpret_cast<RawObject**>(this_addr + offset));
    hash = CombineHashes(hash, value);
  }
  return FinalizeHash(hash, (kBitsPerWord - 1));
}

#if defined(DEBUG)
class CheckForPointers : public ObjectPointerVisitor {
 public:
  explicit CheckForPointers(Isolate* isolate)
      : ObjectPointerVisitor(isolate), has_pointers_(false) {}

  bool has_pointers() const { return has_pointers_; }

  void VisitPointers(RawObject** first, RawObject** last) {
    if (first != last) {
      has_pointers_ = true;
    }
  }

 private:
  bool has_pointers_;

  DISALLOW_COPY_AND_ASSIGN(CheckForPointers);
};
#endif  // DEBUG

bool Instance::CheckAndCanonicalizeFields(Thread* thread,
                                          const char** error_str) const {
  if (GetClassId() >= kNumPredefinedCids) {
    // Iterate over all fields, canonicalize numbers and strings, expect all
    // other instances to be canonical otherwise report error (return false).
    Zone* zone = thread->zone();
    Object& obj = Object::Handle(zone);
    const intptr_t instance_size = SizeFromClass();
    ASSERT(instance_size != 0);
    for (intptr_t offset = Instance::NextFieldOffset(); offset < instance_size;
         offset += kWordSize) {
      obj = *this->FieldAddrAtOffset(offset);
      if (obj.IsInstance() && !obj.IsSmi() && !obj.IsCanonical()) {
        if (obj.IsNumber() || obj.IsString()) {
          obj = Instance::Cast(obj).CheckAndCanonicalize(thread, NULL);
          ASSERT(!obj.IsNull());
          this->SetFieldAtOffset(offset, obj);
        } else {
          ASSERT(error_str != NULL);
          char* chars = OS::SCreate(zone, "field: %s\n", obj.ToCString());
          *error_str = chars;
          return false;
        }
      }
    }
  } else {
#if defined(DEBUG)
    // Make sure that we are not missing any fields.
    CheckForPointers has_pointers(Isolate::Current());
    this->raw()->VisitPointers(&has_pointers);
    ASSERT(!has_pointers.has_pointers());
#endif  // DEBUG
  }
  return true;
}

RawInstance* Instance::CheckAndCanonicalize(Thread* thread,
                                            const char** error_str) const {
  ASSERT(!IsNull());
  if (this->IsCanonical()) {
    return this->raw();
  }
  if (!CheckAndCanonicalizeFields(thread, error_str)) {
    return Instance::null();
  }
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Instance& result = Instance::Handle(zone);
  const Class& cls = Class::Handle(zone, this->clazz());
  {
    SafepointMutexLocker ml(isolate->constant_canonicalization_mutex());
    result ^= cls.LookupCanonicalInstance(zone, *this);
    if (!result.IsNull()) {
      return result.raw();
    }
    if (IsNew()) {
      ASSERT((isolate == Dart::vm_isolate()) || !InVMHeap());
      // Create a canonical object in old space.
      result ^= Object::Clone(*this, Heap::kOld);
    } else {
      result ^= this->raw();
    }
    ASSERT(result.IsOld());
    result.SetCanonical();
    return cls.InsertCanonicalConstant(zone, result);
  }
}

#if defined(DEBUG)
bool Instance::CheckIsCanonical(Thread* thread) const {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Instance& result = Instance::Handle(zone);
  const Class& cls = Class::Handle(zone, this->clazz());
  SafepointMutexLocker ml(isolate->constant_canonicalization_mutex());
  result ^= cls.LookupCanonicalInstance(zone, *this);
  return (result.raw() == this->raw());
}
#endif  // DEBUG

RawAbstractType* Instance::GetType(Heap::Space space) const {
  if (IsNull()) {
    return Type::NullType();
  }
  const Class& cls = Class::Handle(clazz());
  if (cls.IsClosureClass()) {
    const Function& signature =
        Function::Handle(Closure::Cast(*this).function());
    Type& type = Type::Handle(signature.SignatureType());
    if (!type.IsInstantiated()) {
      const TypeArguments& instantiator_type_arguments = TypeArguments::Handle(
          Closure::Cast(*this).instantiator_type_arguments());
      const TypeArguments& function_type_arguments =
          TypeArguments::Handle(Closure::Cast(*this).function_type_arguments());
      // No bound error possible, since the instance exists.
      type ^= type.InstantiateFrom(instantiator_type_arguments,
                                   function_type_arguments, NULL, NULL, NULL,
                                   space);
    }
    type ^= type.Canonicalize();
    return type.raw();
  }
  Type& type = Type::Handle();
  if (!cls.IsGeneric()) {
    type = cls.CanonicalType();
  }
  if (type.IsNull()) {
    TypeArguments& type_arguments = TypeArguments::Handle();
    if (cls.NumTypeArguments() > 0) {
      type_arguments = GetTypeArguments();
    }
    type = Type::New(cls, type_arguments, TokenPosition::kNoSource, space);
    type.SetIsFinalized();
    type ^= type.Canonicalize();
  }
  return type.raw();
}

RawTypeArguments* Instance::GetTypeArguments() const {
  const Class& cls = Class::Handle(clazz());
  intptr_t field_offset = cls.type_arguments_field_offset();
  ASSERT(field_offset != Class::kNoTypeArguments);
  TypeArguments& type_arguments = TypeArguments::Handle();
  type_arguments ^= *FieldAddrAtOffset(field_offset);
  return type_arguments.raw();
}

void Instance::SetTypeArguments(const TypeArguments& value) const {
  ASSERT(value.IsNull() || value.IsCanonical());
  const Class& cls = Class::Handle(clazz());
  intptr_t field_offset = cls.type_arguments_field_offset();
  ASSERT(field_offset != Class::kNoTypeArguments);
  SetFieldAtOffset(field_offset, value);
}

bool Instance::IsInstanceOf(
    const AbstractType& other,
    const TypeArguments& other_instantiator_type_arguments,
    const TypeArguments& other_function_type_arguments,
    Error* bound_error) const {
  ASSERT(other.IsFinalized());
  ASSERT(!other.IsDynamicType());
  ASSERT(!other.IsTypeRef());  // Must be dereferenced at compile time.
  ASSERT(!other.IsMalformed());
  ASSERT(!other.IsMalbounded());
  if (other.IsVoidType()) {
    return true;
  }
  Zone* zone = Thread::Current()->zone();
  const Class& cls = Class::Handle(zone, clazz());
  if (cls.IsClosureClass()) {
    if (other.IsObjectType() || other.IsDartFunctionType() ||
        other.IsDartClosureType()) {
      return true;
    }
    AbstractType& instantiated_other = AbstractType::Handle(zone, other.raw());
    // Note that we may encounter a bound error in checked mode.
    if (!other.IsInstantiated()) {
      instantiated_other = other.InstantiateFrom(
          other_instantiator_type_arguments, other_function_type_arguments,
          bound_error, NULL, NULL, Heap::kOld);
      if ((bound_error != NULL) && !bound_error->IsNull()) {
        ASSERT(Isolate::Current()->type_checks());
        return false;
      }
      if (instantiated_other.IsTypeRef()) {
        instantiated_other = TypeRef::Cast(instantiated_other).type();
      }
      if (instantiated_other.IsDynamicType() ||
          instantiated_other.IsObjectType() ||
          instantiated_other.IsVoidType() ||
          instantiated_other.IsDartFunctionType()) {
        return true;
      }
    }
    if (!instantiated_other.IsFunctionType()) {
      return false;
    }
    Function& other_signature =
        Function::Handle(zone, Type::Cast(instantiated_other).signature());
    Function& sig_fun = Function::Handle(zone, Closure::Cast(*this).function());
    if (!sig_fun.HasInstantiatedSignature()) {
      const TypeArguments& instantiator_type_arguments = TypeArguments::Handle(
          zone, Closure::Cast(*this).instantiator_type_arguments());
      const TypeArguments& function_type_arguments = TypeArguments::Handle(
          zone, Closure::Cast(*this).function_type_arguments());
      sig_fun = sig_fun.InstantiateSignatureFrom(
          instantiator_type_arguments, function_type_arguments, Heap::kOld);
    }
    return sig_fun.IsSubtypeOf(other_signature, bound_error, NULL, Heap::kOld);
  }
  TypeArguments& type_arguments = TypeArguments::Handle(zone);
  if (cls.NumTypeArguments() > 0) {
    type_arguments = GetTypeArguments();
    ASSERT(type_arguments.IsNull() || type_arguments.IsCanonical());
    // The number of type arguments in the instance must be greater or equal to
    // the number of type arguments expected by the instance class.
    // A discrepancy is allowed for closures, which borrow the type argument
    // vector of their instantiator, which may be of a subclass of the class
    // defining the closure. Truncating the vector to the correct length on
    // instantiation is unnecessary. The vector may therefore be longer.
    // Also, an optimization reuses the type argument vector of the instantiator
    // of generic instances when its layout is compatible.
    ASSERT(type_arguments.IsNull() ||
           (type_arguments.Length() >= cls.NumTypeArguments()));
  }
  Class& other_class = Class::Handle(zone);
  TypeArguments& other_type_arguments = TypeArguments::Handle(zone);
  AbstractType& instantiated_other = AbstractType::Handle(zone, other.raw());
  // Note that we may encounter a bound error in checked mode.
  if (!other.IsInstantiated()) {
    instantiated_other = other.InstantiateFrom(
        other_instantiator_type_arguments, other_function_type_arguments,
        bound_error, NULL, NULL, Heap::kOld);
    if ((bound_error != NULL) && !bound_error->IsNull()) {
      ASSERT(Isolate::Current()->type_checks());
      return false;
    }
    if (instantiated_other.IsTypeRef()) {
      instantiated_other = TypeRef::Cast(instantiated_other).type();
    }
    if (instantiated_other.IsDynamicType() ||
        instantiated_other.IsObjectType() || instantiated_other.IsVoidType()) {
      return true;
    }
  }
  other_type_arguments = instantiated_other.arguments();
  const bool other_is_dart_function = instantiated_other.IsDartFunctionType();
  if (other_is_dart_function || instantiated_other.IsFunctionType()) {
    // Check if this instance understands a call() method of a compatible type.
    Function& sig_fun =
        Function::Handle(zone, cls.LookupCallFunctionForTypeTest());
    if (!sig_fun.IsNull()) {
      if (other_is_dart_function) {
        return true;
      }
      if (!sig_fun.HasInstantiatedSignature()) {
        // The following signature instantiation of sig_fun with its own type
        // parameters only works if sig_fun has no generic parent, which is
        // guaranteed to be the case, since the looked up call() function
        // cannot be nested. It is most probably not even generic.
        ASSERT(!sig_fun.HasGenericParent());
        const TypeArguments& function_type_arguments =
            TypeArguments::Handle(zone, sig_fun.type_parameters());
        // No bound error possible, since the instance exists.
        sig_fun = sig_fun.InstantiateSignatureFrom(
            type_arguments, function_type_arguments, Heap::kOld);
      }
      const Function& other_signature =
          Function::Handle(zone, Type::Cast(instantiated_other).signature());
      if (sig_fun.IsSubtypeOf(other_signature, bound_error, NULL, Heap::kOld)) {
        return true;
      }
    }
  }
  if (!instantiated_other.IsType()) {
    return false;
  }
  other_class = instantiated_other.type_class();
  if (IsNull()) {
    ASSERT(cls.IsNullClass());
    // As of Dart 1.5, the null instance and Null type are handled differently.
    // We already checked other for dynamic and void.
    return other_class.IsNullClass() || other_class.IsObjectClass();
  }
  return cls.IsSubtypeOf(type_arguments, other_class, other_type_arguments,
                         bound_error, NULL, Heap::kOld);
}

bool Instance::OperatorEquals(const Instance& other) const {
  // TODO(koda): Optimize for all builtin classes and all classes
  // that do not override operator==.
  return DartLibraryCalls::Equals(*this, other) == Object::bool_true().raw();
}

bool Instance::IsIdenticalTo(const Instance& other) const {
  if (raw() == other.raw()) return true;
  if (IsInteger() && other.IsInteger()) {
    return Integer::Cast(*this).Equals(other);
  }
  if (IsDouble() && other.IsDouble()) {
    double other_value = Double::Cast(other).value();
    return Double::Cast(*this).BitwiseEqualsToDouble(other_value);
  }
  return false;
}

intptr_t* Instance::NativeFieldsDataAddr() const {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() > 0);
  RawTypedData* native_fields =
      reinterpret_cast<RawTypedData*>(*NativeFieldsAddr());
  if (native_fields == TypedData::null()) {
    return NULL;
  }
  return reinterpret_cast<intptr_t*>(native_fields->ptr()->data());
}

void Instance::SetNativeField(int index, intptr_t value) const {
  ASSERT(IsValidNativeIndex(index));
  Object& native_fields = Object::Handle(*NativeFieldsAddr());
  if (native_fields.IsNull()) {
    // Allocate backing storage for the native fields.
    native_fields = TypedData::New(kIntPtrCid, NumNativeFields());
    StorePointer(NativeFieldsAddr(), native_fields.raw());
  }
  intptr_t byte_offset = index * sizeof(intptr_t);
  TypedData::Cast(native_fields).SetIntPtr(byte_offset, value);
}

void Instance::SetNativeFields(uint16_t num_native_fields,
                               const intptr_t* field_values) const {
  ASSERT(num_native_fields == NumNativeFields());
  ASSERT(field_values != NULL);
  Object& native_fields = Object::Handle(*NativeFieldsAddr());
  if (native_fields.IsNull()) {
    // Allocate backing storage for the native fields.
    native_fields = TypedData::New(kIntPtrCid, NumNativeFields());
    StorePointer(NativeFieldsAddr(), native_fields.raw());
  }
  for (uint16_t i = 0; i < num_native_fields; i++) {
    intptr_t byte_offset = i * sizeof(intptr_t);
    TypedData::Cast(native_fields).SetIntPtr(byte_offset, field_values[i]);
  }
}

bool Instance::IsCallable(Function* function) const {
  Class& cls = Class::Handle(clazz());
  if (cls.IsClosureClass()) {
    if (function != NULL) {
      *function = Closure::Cast(*this).function();
    }
    return true;
  }
  // Try to resolve a "call" method.
  Function& call_function = Function::Handle();
  do {
    call_function = cls.LookupDynamicFunction(Symbols::Call());
    if (!call_function.IsNull()) {
      if (function != NULL) {
        *function = call_function.raw();
      }
      return true;
    }
    cls = cls.SuperClass();
  } while (!cls.IsNull());
  return false;
}

RawInstance* Instance::New(const Class& cls, Heap::Space space) {
  Thread* thread = Thread::Current();
  if (cls.EnsureIsFinalized(thread) != Error::null()) {
    return Instance::null();
  }
  intptr_t instance_size = cls.instance_size();
  ASSERT(instance_size > 0);
  RawObject* raw = Object::Allocate(cls.id(), instance_size, space);
  return reinterpret_cast<RawInstance*>(raw);
}

bool Instance::IsValidFieldOffset(intptr_t offset) const {
  Thread* thread = Thread::Current();
  REUSABLE_CLASS_HANDLESCOPE(thread);
  Class& cls = thread->ClassHandle();
  cls = clazz();
  return (offset >= 0 && offset <= (cls.instance_size() - kWordSize));
}

intptr_t Instance::ElementSizeFor(intptr_t cid) {
  if (RawObject::IsExternalTypedDataClassId(cid)) {
    return ExternalTypedData::ElementSizeInBytes(cid);
  } else if (RawObject::IsTypedDataClassId(cid)) {
    return TypedData::ElementSizeInBytes(cid);
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
      return Array::kBytesPerElement;
    case kOneByteStringCid:
      return OneByteString::kBytesPerElement;
    case kTwoByteStringCid:
      return TwoByteString::kBytesPerElement;
    case kExternalOneByteStringCid:
      return ExternalOneByteString::kBytesPerElement;
    case kExternalTwoByteStringCid:
      return ExternalTwoByteString::kBytesPerElement;
    default:
      UNIMPLEMENTED();
      return 0;
  }
}

intptr_t Instance::DataOffsetFor(intptr_t cid) {
  if (RawObject::IsExternalTypedDataClassId(cid) ||
      RawObject::IsExternalStringClassId(cid)) {
    // Elements start at offset 0 of the external data.
    return 0;
  }
  if (RawObject::IsTypedDataClassId(cid)) {
    return TypedData::data_offset();
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
      return Array::data_offset();
    case kOneByteStringCid:
      return OneByteString::data_offset();
    case kTwoByteStringCid:
      return TwoByteString::data_offset();
    default:
      UNIMPLEMENTED();
      return Array::data_offset();
  }
}

const char* Instance::ToCString() const {
  if (IsNull()) {
    return "null";
  } else if (raw() == Object::sentinel().raw()) {
    return "sentinel";
  } else if (raw() == Object::transition_sentinel().raw()) {
    return "transition_sentinel";
  } else if (raw() == Object::unknown_constant().raw()) {
    return "unknown_constant";
  } else if (raw() == Object::non_constant().raw()) {
    return "non_constant";
  } else if (Thread::Current()->no_safepoint_scope_depth() > 0) {
    // Can occur when running disassembler.
    return "Instance";
  } else {
    if (IsClosure()) {
      return Closure::Cast(*this).ToCString();
    }
    const Class& cls = Class::Handle(clazz());
    TypeArguments& type_arguments = TypeArguments::Handle();
    const intptr_t num_type_arguments = cls.NumTypeArguments();
    if (num_type_arguments > 0) {
      type_arguments = GetTypeArguments();
    }
    const Type& type =
        Type::Handle(Type::New(cls, type_arguments, TokenPosition::kNoSource));
    const String& type_name = String::Handle(type.UserVisibleName());
    return OS::SCreate(Thread::Current()->zone(), "Instance of '%s'",
                       type_name.ToCString());
  }
}

bool AbstractType::IsResolved() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

void AbstractType::SetIsResolved() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
}

bool AbstractType::HasResolvedTypeClass() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

classid_t AbstractType::type_class_id() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return kIllegalCid;
}

RawClass* AbstractType::type_class() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return Class::null();
}

RawUnresolvedClass* AbstractType::unresolved_class() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return UnresolvedClass::null();
}

RawTypeArguments* AbstractType::arguments() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

void AbstractType::set_arguments(const TypeArguments& value) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
}

TokenPosition AbstractType::token_pos() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return TokenPosition::kNoSource;
}

bool AbstractType::IsInstantiated(Genericity genericity,
                                  intptr_t num_free_fun_type_params,
                                  TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

bool AbstractType::IsFinalized() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

void AbstractType::SetIsFinalized() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
}

bool AbstractType::IsBeingFinalized() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

void AbstractType::SetIsBeingFinalized() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
}

bool AbstractType::IsMalformed() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

bool AbstractType::IsMalbounded() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

bool AbstractType::IsMalformedOrMalbounded() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

RawLanguageError* AbstractType::error() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return LanguageError::null();
}

void AbstractType::set_error(const LanguageError& value) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
}

bool AbstractType::IsEquivalent(const Instance& other, TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

bool AbstractType::IsRecursive() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

void AbstractType::SetScopeFunction(const Function& function) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
}

RawAbstractType* AbstractType::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Error* bound_error,
    TrailPtr instantiation_trail,
    TrailPtr bound_trail,
    Heap::Space space) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

RawAbstractType* AbstractType::CloneUnfinalized() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

RawAbstractType* AbstractType::CloneUninstantiated(const Class& new_owner,
                                                   TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

RawAbstractType* AbstractType::Canonicalize(TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

RawString* AbstractType::EnumerateURIs() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

RawAbstractType* AbstractType::OnlyBuddyInTrail(TrailPtr trail) const {
  if (trail == NULL) {
    return AbstractType::null();
  }
  const intptr_t len = trail->length();
  ASSERT((len % 2) == 0);
  for (intptr_t i = 0; i < len; i += 2) {
    ASSERT(trail->At(i).IsZoneHandle());
    ASSERT(trail->At(i + 1).IsZoneHandle());
    if (trail->At(i).raw() == this->raw()) {
      ASSERT(!trail->At(i + 1).IsNull());
      return trail->At(i + 1).raw();
    }
  }
  return AbstractType::null();
}

void AbstractType::AddOnlyBuddyToTrail(TrailPtr* trail,
                                       const AbstractType& buddy) const {
  if (*trail == NULL) {
    *trail = new Trail(Thread::Current()->zone(), 4);
  } else {
    ASSERT(OnlyBuddyInTrail(*trail) == AbstractType::null());
  }
  (*trail)->Add(*this);
  (*trail)->Add(buddy);
}

bool AbstractType::TestAndAddToTrail(TrailPtr* trail) const {
  if (*trail == NULL) {
    *trail = new Trail(Thread::Current()->zone(), 4);
  } else {
    const intptr_t len = (*trail)->length();
    for (intptr_t i = 0; i < len; i++) {
      if ((*trail)->At(i).raw() == this->raw()) {
        return true;
      }
    }
  }
  (*trail)->Add(*this);
  return false;
}

bool AbstractType::TestAndAddBuddyToTrail(TrailPtr* trail,
                                          const AbstractType& buddy) const {
  if (*trail == NULL) {
    *trail = new Trail(Thread::Current()->zone(), 4);
  } else {
    const intptr_t len = (*trail)->length();
    ASSERT((len % 2) == 0);
    const bool this_is_typeref = IsTypeRef();
    const bool buddy_is_typeref = buddy.IsTypeRef();
    // Note that at least one of 'this' and 'buddy' should be a typeref, with
    // one exception, when the class of the 'this' type implements the 'call'
    // method, thereby possibly creating a recursive type (see regress_29405).
    for (intptr_t i = 0; i < len; i += 2) {
      if ((((*trail)->At(i).raw() == this->raw()) ||
           (buddy_is_typeref && (*trail)->At(i).Equals(*this))) &&
          (((*trail)->At(i + 1).raw() == buddy.raw()) ||
           (this_is_typeref && (*trail)->At(i + 1).Equals(buddy)))) {
        return true;
      }
    }
  }
  (*trail)->Add(*this);
  (*trail)->Add(buddy);
  return false;
}

RawString* AbstractType::BuildName(NameVisibility name_visibility) const {
  ASSERT(name_visibility != kScrubbedName);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  if (IsBoundedType()) {
    const AbstractType& type =
        AbstractType::Handle(zone, BoundedType::Cast(*this).type());
    if (name_visibility == kUserVisibleName) {
      return type.BuildName(kUserVisibleName);
    }
    GrowableHandlePtrArray<const String> pieces(zone, 5);
    String& type_name = String::Handle(zone, type.BuildName(kInternalName));
    pieces.Add(type_name);
    pieces.Add(Symbols::SpaceExtendsSpace());
    // Build the bound name without causing divergence.
    const AbstractType& bound =
        AbstractType::Handle(zone, BoundedType::Cast(*this).bound());
    String& bound_name = String::Handle(zone);
    if (bound.IsTypeParameter()) {
      bound_name = TypeParameter::Cast(bound).name();
      pieces.Add(bound_name);
    } else if (bound.IsType()) {
      const Class& cls = Class::Handle(zone, Type::Cast(bound).type_class());
      bound_name = cls.Name();
      pieces.Add(bound_name);
      if (Type::Cast(bound).arguments() != TypeArguments::null()) {
        pieces.Add(Symbols::OptimizedOut());
      }
    } else {
      pieces.Add(Symbols::OptimizedOut());
    }
    return Symbols::FromConcatAll(thread, pieces);
  }
  if (IsTypeParameter()) {
    return TypeParameter::Cast(*this).name();
  }
  // If the type is still being finalized, we may be reporting an error about
  // a malformed type, so proceed with caution.
  const TypeArguments& args = TypeArguments::Handle(zone, arguments());
  const intptr_t num_args = args.IsNull() ? 0 : args.Length();
  String& class_name = String::Handle(zone);
  intptr_t first_type_param_index;
  intptr_t num_type_params;  // Number of type parameters to print.
  Class& cls = Class::Handle(zone);
  if (IsFunctionType()) {
    cls = type_class();
    const Function& signature_function =
        Function::Handle(zone, Type::Cast(*this).signature());
    if (!cls.IsTypedefClass()) {
      return signature_function.UserVisibleSignature();
    }
    // Instead of printing the actual signature, use the typedef name with
    // its type arguments, if any.
    class_name = cls.Name();  // Typedef name.
    // We may be reporting an error about a malformed function type. In that
    // case, avoid instantiating the signature, since it may cause divergence.
    if (!IsFinalized() || IsBeingFinalized() || IsMalformed()) {
      return class_name.raw();
    }
    // Print the name of a typedef as a regular, possibly parameterized, class.
  } else if (HasResolvedTypeClass()) {
    cls = type_class();
  }
  if (!cls.IsNull()) {
    if (IsResolved() || !cls.IsMixinApplication()) {
      // Do not print the full vector, but only the declared type parameters.
      num_type_params = cls.NumTypeParameters();
    } else {
      // Do not print the type parameters of an unresolved mixin application,
      // since it would prematurely trigger the application of the mixin type.
      num_type_params = 0;
    }
    if (name_visibility == kInternalName) {
      class_name = cls.Name();
    } else {
      ASSERT(name_visibility == kUserVisibleName);
      // Map internal types to their corresponding public interfaces.
      class_name = cls.UserVisibleName();
    }
    if (num_type_params > num_args) {
      first_type_param_index = 0;
      if (!IsFinalized() || IsBeingFinalized() || IsMalformed()) {
        // Most probably a malformed type. Do not fill up with "dynamic",
        // but use actual vector.
        num_type_params = num_args;
      } else {
        ASSERT(num_args == 0);  // Type is raw.
        // No need to fill up with "dynamic".
        num_type_params = 0;
      }
    } else {
      // The actual type argument vector can be longer than necessary, because
      // of type optimizations.
      if (IsFinalized() && cls.is_type_finalized()) {
        first_type_param_index = cls.NumTypeArguments() - num_type_params;
      } else {
        first_type_param_index = num_args - num_type_params;
      }
    }
  } else {
    class_name = UnresolvedClass::Handle(zone, unresolved_class()).Name();
    num_type_params = num_args;
    first_type_param_index = 0;
  }
  GrowableHandlePtrArray<const String> pieces(zone, 4);
  pieces.Add(class_name);
  if ((num_type_params == 0) ||
      args.IsRaw(first_type_param_index, num_type_params)) {
    // Do nothing.
  } else {
    const String& args_name = String::Handle(
        zone, args.SubvectorName(first_type_param_index, num_type_params,
                                 name_visibility));
    pieces.Add(args_name);
  }
  // The name is only used for type checking and debugging purposes.
  // Unless profiling data shows otherwise, it is not worth caching the name in
  // the type.
  return Symbols::FromConcatAll(thread, pieces);
}

RawString* AbstractType::ClassName() const {
  ASSERT(!IsFunctionType());
  if (HasResolvedTypeClass()) {
    return Class::Handle(type_class()).Name();
  } else {
    return UnresolvedClass::Handle(unresolved_class()).Name();
  }
}

bool AbstractType::IsDynamicType() const {
  if (IsCanonical()) {
    return raw() == Object::dynamic_type().raw();
  }
  return HasResolvedTypeClass() && (type_class() == Object::dynamic_class());
}

bool AbstractType::IsVoidType() const {
  return raw() == Object::void_type().raw();
}

bool AbstractType::IsNullType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Isolate::Current()->object_store()->null_class());
}

bool AbstractType::IsBoolType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Isolate::Current()->object_store()->bool_class());
}

bool AbstractType::IsIntType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::IntType()).type_class());
}

bool AbstractType::IsInt64Type() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::Int64Type()).type_class());
}

bool AbstractType::IsDoubleType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::Double()).type_class());
}

bool AbstractType::IsFloat32x4Type() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::Float32x4()).type_class());
}

bool AbstractType::IsFloat64x2Type() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::Float64x2()).type_class());
}

bool AbstractType::IsInt32x4Type() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::Int32x4()).type_class());
}

bool AbstractType::IsNumberType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::Number()).type_class());
}

bool AbstractType::IsSmiType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::SmiType()).type_class());
}

bool AbstractType::IsStringType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::StringType()).type_class());
}

bool AbstractType::IsDartFunctionType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Type::Handle(Type::DartFunctionType()).type_class());
}

bool AbstractType::IsDartClosureType() const {
  return !IsFunctionType() && HasResolvedTypeClass() &&
         (type_class() == Isolate::Current()->object_store()->closure_class());
}

bool AbstractType::TypeTest(TypeTestKind test_kind,
                            const AbstractType& other,
                            Error* bound_error,
                            TrailPtr bound_trail,
                            Heap::Space space) const {
  ASSERT(IsFinalized());
  ASSERT(other.IsFinalized());
  if (IsMalformed() || other.IsMalformed()) {
    // Malformed types involved in subtype tests should be handled specially
    // by the caller. Malformed types should only be encountered here in a
    // more specific than test.
    ASSERT(test_kind == kIsMoreSpecificThan);
    return false;
  }
  // In case the type checked in a type test is malbounded, the code generator
  // may compile a throw instead of a run time call performing the type check.
  // However, in checked mode, a function type may include malbounded result
  // type and/or malbounded parameter types, which will then be encountered here
  // at run time.
  if (IsMalbounded()) {
    ASSERT(Isolate::Current()->type_checks());
    if ((bound_error != NULL) && bound_error->IsNull()) {
      *bound_error = error();
    }
    return false;
  }
  if (other.IsMalbounded()) {
    ASSERT(Isolate::Current()->type_checks());
    if ((bound_error != NULL) && bound_error->IsNull()) {
      *bound_error = other.error();
    }
    return false;
  }
  // Any type is a subtype of (and is more specific than) Object and dynamic.
  // As of Dart 1.24, void is dynamically treated like Object (except when
  // comparing function-types).
  // As of Dart 1.5, the Null type is a subtype of (and is more specific than)
  // any type.
  if (other.IsObjectType() || other.IsDynamicType() || other.IsVoidType() ||
      IsNullType()) {
    return true;
  }
  Zone* zone = Thread::Current()->zone();
  if (IsBoundedType() || other.IsBoundedType()) {
    if (Equals(other)) {
      return true;
    }
    // Redundant check if other type is equal to the upper bound of this type.
    if (IsBoundedType() &&
        AbstractType::Handle(BoundedType::Cast(*this).bound()).Equals(other)) {
      return true;
    }
    // Bound checking at run time occurs when allocating an instance of a
    // generic bounded type using a valid instantiator. The instantiator is
    // the type of an instance successfully allocated, i.e. not containing
    // unchecked bounds anymore.
    // Therefore, when performing a type test at compile time (what is happening
    // here), it is safe to ignore the bounds, since they will not exist at run
    // time anymore.
    if (IsBoundedType()) {
      const AbstractType& bounded_type =
          AbstractType::Handle(zone, BoundedType::Cast(*this).type());
      return bounded_type.TypeTest(test_kind, other, bound_error, bound_trail,
                                   space);
    }
    const AbstractType& other_bounded_type =
        AbstractType::Handle(zone, BoundedType::Cast(other).type());
    return TypeTest(test_kind, other_bounded_type, bound_error, bound_trail,
                    space);
  }
  // Type parameters cannot be handled by Class::TypeTest().
  // When comparing two uninstantiated function types, one returning type
  // parameter K, the other returning type parameter V, we cannot assume that K
  // is a subtype of V, or vice versa. We only return true if K equals V, as
  // defined by TypeParameter::Equals.
  // The same rule applies when checking the upper bound of a still
  // uninstantiated type at compile time. Returning false will defer the test
  // to run time.
  // There are however some cases that can be decided at compile time.
  // For example, with class A<K, V extends K>, new A<T, T> called from within
  // a class B<T> will never require a run time bound check, even if T is
  // uninstantiated at compile time.
  if (IsTypeParameter()) {
    const TypeParameter& type_param = TypeParameter::Cast(*this);
    if (other.IsTypeParameter()) {
      const TypeParameter& other_type_param = TypeParameter::Cast(other);
      if (type_param.Equals(other_type_param)) {
        return true;
      }
      if (type_param.IsFunctionTypeParameter() &&
          other_type_param.IsFunctionTypeParameter() &&
          type_param.IsFinalized() && other_type_param.IsFinalized()) {
        // To be compatible, the function type parameters should be declared at
        // the same position in the generic function. Their index therefore
        // needs adjustement before comparison.
        // Example: 'foo<F>(bar<B>(B b)) { }' and 'baz<Z>(Z z) { }', baz can be
        // assigned to bar, although B has index 1 and Z index 0.
        const Function& sig_fun =
            Function::Handle(zone, type_param.parameterized_function());
        const Function& other_sig_fun =
            Function::Handle(zone, other_type_param.parameterized_function());
        const int offset = sig_fun.NumParentTypeParameters();
        const int other_offset = other_sig_fun.NumParentTypeParameters();
        if (type_param.index() - offset ==
            other_type_param.index() - other_offset) {
          return true;
        }
      }
    }
    const AbstractType& bound = AbstractType::Handle(zone, type_param.bound());
    // We may be checking bounds at finalization time and can encounter
    // a still unfinalized bound. Finalizing the bound here may lead to cycles.
    if (!bound.IsFinalized()) {
      return false;  // TODO(regis): Return "maybe after instantiation".
    }
    // The current bound_trail cannot be used, because operands are swapped and
    // the test is different anyway (more specific vs. subtype).
    if (bound.IsMoreSpecificThan(other, bound_error, NULL, space)) {
      return true;
    }
    return false;  // TODO(regis): We should return "maybe after instantiation".
  }
  if (other.IsTypeParameter()) {
    return false;  // TODO(regis): We should return "maybe after instantiation".
  }
  const Class& type_cls = Class::Handle(zone, type_class());
  // Function types cannot be handled by Class::TypeTest().
  const bool other_is_dart_function_type = other.IsDartFunctionType();
  if (other_is_dart_function_type || other.IsFunctionType()) {
    if (IsFunctionType()) {
      if (other_is_dart_function_type) {
        return true;
      }
      const Function& other_fun =
          Function::Handle(zone, Type::Cast(other).signature());
      // Check for two function types.
      const Function& fun =
          Function::Handle(zone, Type::Cast(*this).signature());
      return fun.TypeTest(test_kind, other_fun, bound_error, bound_trail,
                          space);
    }
    // Check if type S has a call() method of function type T.
    const Function& call_function =
        Function::Handle(zone, type_cls.LookupCallFunctionForTypeTest());
    if (!call_function.IsNull()) {
      if (other_is_dart_function_type) {
        return true;
      }
      // Shortcut the test involving the call function if the
      // pair <this, other> is already in the trail.
      if (TestAndAddBuddyToTrail(&bound_trail, other)) {
        return true;
      }
      if (call_function.TypeTest(
              test_kind, Function::Handle(zone, Type::Cast(other).signature()),
              bound_error, bound_trail, space)) {
        return true;
      }
    }
  }
  if (IsFunctionType()) {
    return false;
  }
  return type_cls.TypeTest(test_kind, TypeArguments::Handle(zone, arguments()),
                           Class::Handle(zone, other.type_class()),
                           TypeArguments::Handle(zone, other.arguments()),
                           bound_error, bound_trail, space);
}

intptr_t AbstractType::Hash() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return 0;
}

const char* AbstractType::ToCString() const {
  if (IsNull()) {
    return "AbstractType: null";
  }
  // AbstractType is an abstract class.
  UNREACHABLE();
  return "AbstractType";
}

RawType* Type::NullType() {
  return Isolate::Current()->object_store()->null_type();
}

RawType* Type::DynamicType() {
  return Object::dynamic_type().raw();
}

RawType* Type::VoidType() {
  return Object::void_type().raw();
}

RawType* Type::ObjectType() {
  return Isolate::Current()->object_store()->object_type();
}

RawType* Type::BoolType() {
  return Isolate::Current()->object_store()->bool_type();
}

RawType* Type::IntType() {
  return Isolate::Current()->object_store()->int_type();
}

RawType* Type::Int64Type() {
  return Isolate::Current()->object_store()->int64_type();
}

RawType* Type::SmiType() {
  return Isolate::Current()->object_store()->smi_type();
}

RawType* Type::MintType() {
  return Isolate::Current()->object_store()->mint_type();
}

RawType* Type::Double() {
  return Isolate::Current()->object_store()->double_type();
}

RawType* Type::Float32x4() {
  return Isolate::Current()->object_store()->float32x4_type();
}

RawType* Type::Float64x2() {
  return Isolate::Current()->object_store()->float64x2_type();
}

RawType* Type::Int32x4() {
  return Isolate::Current()->object_store()->int32x4_type();
}

RawType* Type::Number() {
  return Isolate::Current()->object_store()->number_type();
}

RawType* Type::StringType() {
  return Isolate::Current()->object_store()->string_type();
}

RawType* Type::ArrayType() {
  return Isolate::Current()->object_store()->array_type();
}

RawType* Type::DartFunctionType() {
  return Isolate::Current()->object_store()->function_type();
}

RawType* Type::NewNonParameterizedType(const Class& type_class) {
  ASSERT(type_class.NumTypeArguments() == 0);
  Type& type = Type::Handle(type_class.CanonicalType());
  if (type.IsNull()) {
    type ^= Type::New(Object::Handle(type_class.raw()),
                      Object::null_type_arguments(), TokenPosition::kNoSource);
    type.SetIsFinalized();
    type ^= type.Canonicalize();
  }
  ASSERT(type.IsFinalized());
  return type.raw();
}

void Type::SetIsFinalized() const {
  ASSERT(!IsFinalized());
  if (IsInstantiated()) {
    ASSERT(HasResolvedTypeClass());
    set_type_state(RawType::kFinalizedInstantiated);
  } else {
    set_type_state(RawType::kFinalizedUninstantiated);
  }
}

void Type::ResetIsFinalized() const {
  ASSERT(IsFinalized());
  set_type_state(RawType::kBeingFinalized);
  SetIsFinalized();
}

void Type::SetIsBeingFinalized() const {
  ASSERT(IsResolved() && !IsFinalized() && !IsBeingFinalized());
  set_type_state(RawType::kBeingFinalized);
}

bool Type::IsMalformed() const {
  if (raw_ptr()->sig_or_err_.error_ == LanguageError::null()) {
    return false;  // Valid type, but not a function type.
  }
  if (!raw_ptr()->sig_or_err_.error_->IsLanguageError()) {
    return false;  // Valid function type.
  }
  const LanguageError& type_error = LanguageError::Handle(error());
  ASSERT(!type_error.IsNull());
  return type_error.kind() == Report::kMalformedType;
}

bool Type::IsMalbounded() const {
  if (raw_ptr()->sig_or_err_.error_ == LanguageError::null()) {
    return false;  // Valid type, but not a function type.
  }
  if (!Isolate::Current()->type_checks()) {
    return false;
  }
  if (!raw_ptr()->sig_or_err_.error_->IsLanguageError()) {
    return false;  // Valid function type.
  }
  const LanguageError& type_error = LanguageError::Handle(error());
  ASSERT(!type_error.IsNull());
  return type_error.kind() == Report::kMalboundedType;
}

bool Type::IsMalformedOrMalbounded() const {
  if (raw_ptr()->sig_or_err_.error_ == LanguageError::null()) {
    return false;  // Valid type, but not a function type.
  }
  const LanguageError& type_error = LanguageError::Handle(error());
  if (type_error.IsNull()) {
    return false;  // Valid function type.
  }
  if (type_error.kind() == Report::kMalformedType) {
    return true;
  }
  ASSERT(type_error.kind() == Report::kMalboundedType);
  return Isolate::Current()->type_checks();
}

RawLanguageError* Type::error() const {
  if (raw_ptr()->sig_or_err_.error_->IsLanguageError()) {
    return LanguageError::RawCast(raw_ptr()->sig_or_err_.error_);
  }
  return LanguageError::null();
}

void Type::set_error(const LanguageError& value) const {
  StorePointer(&raw_ptr()->sig_or_err_.error_, value.raw());
}

RawFunction* Type::signature() const {
  intptr_t cid = raw_ptr()->sig_or_err_.signature_->GetClassId();
  if (cid == kNullCid) {
    return Function::null();
  }
  if (cid == kFunctionCid) {
    return Function::RawCast(raw_ptr()->sig_or_err_.signature_);
  }
  ASSERT(cid == kLanguageErrorCid);  // Type is malformed or malbounded.
  return Function::null();
}

void Type::set_signature(const Function& value) const {
  StorePointer(&raw_ptr()->sig_or_err_.signature_, value.raw());
}

void Type::SetIsResolved() const {
  ASSERT(!IsResolved());
  set_type_state(RawType::kResolved);
}

bool Type::HasResolvedTypeClass() const {
  return !raw_ptr()->type_class_id_->IsHeapObject();
}

classid_t Type::type_class_id() const {
  ASSERT(HasResolvedTypeClass());
  return Smi::Value(reinterpret_cast<RawSmi*>(raw_ptr()->type_class_id_));
}

RawClass* Type::type_class() const {
  return Isolate::Current()->class_table()->At(type_class_id());
}

RawUnresolvedClass* Type::unresolved_class() const {
#ifdef DEBUG
  ASSERT(!HasResolvedTypeClass());
  UnresolvedClass& unresolved_class = UnresolvedClass::Handle();
  unresolved_class ^= raw_ptr()->type_class_id_;
  ASSERT(!unresolved_class.IsNull());
  return unresolved_class.raw();
#else
  ASSERT(!Object::Handle(raw_ptr()->type_class_id_).IsNull());
  ASSERT(Object::Handle(raw_ptr()->type_class_id_).IsUnresolvedClass());
  return reinterpret_cast<RawUnresolvedClass*>(raw_ptr()->type_class_id_);
#endif
}

bool Type::IsInstantiated(Genericity genericity,
                          intptr_t num_free_fun_type_params,
                          TrailPtr trail) const {
  if (raw_ptr()->type_state_ == RawType::kFinalizedInstantiated) {
    return true;
  }
  if ((genericity == kAny) && (num_free_fun_type_params == kMaxInt32) &&
      (raw_ptr()->type_state_ == RawType::kFinalizedUninstantiated)) {
    return false;
  }
  if (IsFunctionType()) {
    const Function& sig_fun = Function::Handle(signature());
    if (!sig_fun.HasInstantiatedSignature(genericity, num_free_fun_type_params,
                                          trail)) {
      return false;
    }
    // Because a generic typedef with an instantiated signature is considered
    // uninstantiated, we still need to check the type arguments, even if the
    // signature is instantiated.
  }
  if (arguments() == TypeArguments::null()) {
    return true;
  }
  const TypeArguments& args = TypeArguments::Handle(arguments());
  intptr_t num_type_args = args.Length();
  intptr_t len = num_type_args;  // Check the full vector of type args.
  ASSERT(num_type_args > 0);
  // This type is not instantiated if it refers to type parameters.
  // Although this type may still be unresolved, the type parameters it may
  // refer to are resolved by definition. We can therefore return the correct
  // result even for an unresolved type. We just need to look at all type
  // arguments and not just at the type parameters.
  if (HasResolvedTypeClass()) {
    const Class& cls = Class::Handle(type_class());
    len = cls.NumTypeParameters();  // Check the type parameters only.
    if (len > num_type_args) {
      // This type has the wrong number of arguments and is not finalized yet.
      // Type arguments are reset to null when finalizing such a type.
      ASSERT(!IsFinalized());
      len = num_type_args;
    }
  }
  return (len == 0) ||
         args.IsSubvectorInstantiated(num_type_args - len, len, genericity,
                                      num_free_fun_type_params, trail);
}

RawAbstractType* Type::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Error* bound_error,
    TrailPtr instantiation_trail,
    TrailPtr bound_trail,
    Heap::Space space) const {
  Zone* zone = Thread::Current()->zone();
  ASSERT(IsFinalized() || IsBeingFinalized());
  ASSERT(!IsInstantiated());
  // Return the uninstantiated type unchanged if malformed. No copy needed.
  if (IsMalformed()) {
    return raw();
  }
  // Note that the type class has to be resolved at this time, but not
  // necessarily finalized yet. We may be checking bounds at compile time or
  // finalizing the type argument vector of a recursive type.
  const Class& cls = Class::Handle(zone, type_class());
  TypeArguments& type_arguments = TypeArguments::Handle(zone, arguments());
  Function& sig_fun = Function::Handle(zone, signature());
  if (!type_arguments.IsNull() &&
      (sig_fun.IsNull() || !type_arguments.IsInstantiated())) {
    // This type is uninstantiated because either its type arguments or its
    // signature, or both are uninstantiated.
    // Note that the type arguments of a function type merely document the
    // parameterization of a generic typedef. They are otherwise ignored.
    ASSERT(type_arguments.Length() == cls.NumTypeArguments());
    type_arguments = type_arguments.InstantiateFrom(
        instantiator_type_arguments, function_type_arguments, bound_error,
        instantiation_trail, bound_trail, space);
  }
  // This uninstantiated type is not modified, as it can be instantiated
  // with different instantiators. Allocate a new instantiated version of it.
  const Type& instantiated_type =
      Type::Handle(zone, Type::New(cls, type_arguments, token_pos(), space));
  // Preserve the bound error if any.
  if (IsMalbounded()) {
    const LanguageError& bound_error = LanguageError::Handle(zone, error());
    instantiated_type.set_error(bound_error);
  }
  // For a function type, possibly instantiate and set its signature.
  if (!sig_fun.IsNull()) {
    // If we are finalizing a typedef, do not yet instantiate its signature,
    // since it gets instantiated just before the type is marked as finalized.
    // Other function types should never get instantiated while unfinalized,
    // even while checking bounds of recursive types.
    if (IsFinalized()) {
      // A generic typedef may actually declare an instantiated signature.
      if (!sig_fun.HasInstantiatedSignature()) {
        sig_fun = sig_fun.InstantiateSignatureFrom(
            instantiator_type_arguments, function_type_arguments, space);
      }
    } else {
      // The Kernel frontend does not keep the information that a function type
      // is a typedef, so we cannot assert that cls.IsTypedefClass().
    }
    instantiated_type.set_signature(sig_fun);
  }
  if (IsFinalized()) {
    instantiated_type.SetIsFinalized();
  } else {
    instantiated_type.SetIsResolved();
    if (IsBeingFinalized()) {
      instantiated_type.SetIsBeingFinalized();
    }
  }
  // Canonicalization is not part of instantiation.
  return instantiated_type.raw();
}

bool Type::IsEquivalent(const Instance& other, TrailPtr trail) const {
  ASSERT(!IsNull());
  if (raw() == other.raw()) {
    return true;
  }
  if (other.IsTypeRef()) {
    // Unfold right hand type. Divergence is controlled by left hand type.
    const AbstractType& other_ref_type =
        AbstractType::Handle(TypeRef::Cast(other).type());
    ASSERT(!other_ref_type.IsTypeRef());
    return IsEquivalent(other_ref_type, trail);
  }
  if (!other.IsType()) {
    return false;
  }
  const Type& other_type = Type::Cast(other);
  if (IsFunctionType() != other_type.IsFunctionType()) {
    return false;
  }
  ASSERT(IsResolved() && other_type.IsResolved());
  if (IsMalformed() || other_type.IsMalformed()) {
    return false;  // Malformed types do not get canonicalized.
  }
  if (IsMalbounded() != other_type.IsMalbounded()) {
    return false;  // Do not drop bound error.
  }
  if (type_class() != other_type.type_class()) {
    return false;
  }
  if (!IsFinalized() || !other_type.IsFinalized()) {
    return false;  // Too early to decide if equal.
  }
  if ((arguments() == other_type.arguments()) &&
      (signature() == other_type.signature())) {
    return true;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  if (arguments() != other_type.arguments()) {
    const Class& cls = Class::Handle(zone, type_class());
    const intptr_t num_type_params = cls.NumTypeParameters(thread);
    // Shortcut unnecessary handle allocation below if non-generic.
    if (num_type_params > 0) {
      const intptr_t num_type_args = cls.NumTypeArguments();
      const intptr_t from_index = num_type_args - num_type_params;
      const TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
      const TypeArguments& other_type_args =
          TypeArguments::Handle(zone, other_type.arguments());
      if (type_args.IsNull()) {
        // Ignore from_index.
        if (!other_type_args.IsRaw(0, num_type_args)) {
          return false;
        }
      } else if (other_type_args.IsNull()) {
        // Ignore from_index.
        if (!type_args.IsRaw(0, num_type_args)) {
          return false;
        }
      } else if (!type_args.IsSubvectorEquivalent(other_type_args, from_index,
                                                  num_type_params, trail)) {
        return false;
      }
#ifdef DEBUG
      if ((from_index > 0) && !type_args.IsNull() &&
          !other_type_args.IsNull()) {
        // Verify that the type arguments of the super class match, since they
        // depend solely on the type parameters that were just verified to
        // match.
        ASSERT(type_args.Length() >= (from_index + num_type_params));
        ASSERT(other_type_args.Length() >= (from_index + num_type_params));
        AbstractType& type_arg = AbstractType::Handle(zone);
        AbstractType& other_type_arg = AbstractType::Handle(zone);
        for (intptr_t i = 0; i < from_index; i++) {
          type_arg = type_args.TypeAt(i);
          other_type_arg = other_type_args.TypeAt(i);
          // Ignore bounds of bounded types.
          while (type_arg.IsBoundedType()) {
            type_arg = BoundedType::Cast(type_arg).type();
          }
          while (other_type_arg.IsBoundedType()) {
            other_type_arg = BoundedType::Cast(other_type_arg).type();
          }
          ASSERT(type_arg.IsEquivalent(other_type_arg, trail));
        }
      }
#endif
    }
  }
  if (!IsFunctionType()) {
    return true;
  }
  ASSERT(Type::Cast(other).IsFunctionType());
  // Equal function types must have equal signature types and equal optional
  // named arguments.
  if (signature() == other_type.signature()) {
    return true;
  }
  const Function& sig_fun = Function::Handle(zone, signature());
  const Function& other_sig_fun =
      Function::Handle(zone, other_type.signature());

  if (FLAG_reify_generic_functions) {
    // Compare function type parameters and their bounds.
    // Check the type parameters and bounds of generic functions.
    if (!sig_fun.HasSameTypeParametersAndBounds(other_sig_fun)) {
      return false;
    }
  }

  // Compare number of function parameters.
  const intptr_t num_fixed_params = sig_fun.num_fixed_parameters();
  const intptr_t other_num_fixed_params = other_sig_fun.num_fixed_parameters();
  if (num_fixed_params != other_num_fixed_params) {
    return false;
  }
  const intptr_t num_opt_pos_params = sig_fun.NumOptionalPositionalParameters();
  const intptr_t other_num_opt_pos_params =
      other_sig_fun.NumOptionalPositionalParameters();
  if (num_opt_pos_params != other_num_opt_pos_params) {
    return false;
  }
  const intptr_t num_opt_named_params = sig_fun.NumOptionalNamedParameters();
  const intptr_t other_num_opt_named_params =
      other_sig_fun.NumOptionalNamedParameters();
  if (num_opt_named_params != other_num_opt_named_params) {
    return false;
  }
  const intptr_t num_ignored_params = sig_fun.NumImplicitParameters();
  const intptr_t other_num_ignored_params =
      other_sig_fun.NumImplicitParameters();
  if (num_ignored_params != other_num_ignored_params) {
    return false;
  }
  AbstractType& param_type = Type::Handle(zone);
  AbstractType& other_param_type = Type::Handle(zone);
  // Check the result type.
  param_type = sig_fun.result_type();
  other_param_type = other_sig_fun.result_type();
  if (!param_type.Equals(other_param_type)) {
    return false;
  }
  // Check the types of all parameters.
  const intptr_t num_params = sig_fun.NumParameters();
  ASSERT(other_sig_fun.NumParameters() == num_params);
  for (intptr_t i = 0; i < num_params; i++) {
    param_type = sig_fun.ParameterTypeAt(i);
    other_param_type = other_sig_fun.ParameterTypeAt(i);
    if (!param_type.Equals(other_param_type)) {
      return false;
    }
  }
  // Check the names and types of optional named parameters.
  if (num_opt_named_params == 0) {
    return true;
  }
  for (intptr_t i = num_fixed_params; i < num_params; i++) {
    if (sig_fun.ParameterNameAt(i) != other_sig_fun.ParameterNameAt(i)) {
      return false;
    }
  }
  return true;
}

bool Type::IsRecursive() const {
  return TypeArguments::Handle(arguments()).IsRecursive();
}

void Type::SetScopeFunction(const Function& function) const {
  TypeArguments::Handle(arguments()).SetScopeFunction(function);
  if (IsFunctionType()) {
    const Function& sig_fun = Function::Handle(signature());
    sig_fun.set_parent_function(function);
    // No need to traverse result type and parameter types (and bounds, in case
    // sig_fun is generic), since they have sig_fun as scope function.
  }
}

RawAbstractType* Type::CloneUnfinalized() const {
  ASSERT(IsResolved());
  if (IsFinalized()) {
    return raw();
  }
  ASSERT(!IsMalformed());       // Malformed types are finalized.
  ASSERT(!IsBeingFinalized());  // Cloning must occur prior to finalization.
  Zone* zone = Thread::Current()->zone();
  const TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
  const TypeArguments& type_args_clone =
      TypeArguments::Handle(zone, type_args.CloneUnfinalized());
  if (type_args_clone.raw() == type_args.raw()) {
    return raw();
  }
  const Type& clone = Type::Handle(
      zone,
      Type::New(Class::Handle(zone, type_class()), type_args, token_pos()));
  // Preserve the bound error if any.
  if (IsMalbounded()) {
    const LanguageError& bound_error = LanguageError::Handle(zone, error());
    clone.set_error(bound_error);
  }
  // Clone the signature if this type represents a function type.
  Function& fun = Function::Handle(zone, signature());
  if (!fun.IsNull()) {
    const Class& owner = Class::Handle(zone, fun.Owner());
    const Function& parent = Function::Handle(zone, fun.parent_function());
    Function& fun_clone =
        Function::Handle(zone, Function::NewSignatureFunction(
                                   owner, parent, TokenPosition::kNoSource));
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, fun.type_parameters());
    if (!type_params.IsNull()) {
      const intptr_t num_type_params = type_params.Length();
      const TypeArguments& type_params_clone =
          TypeArguments::Handle(zone, TypeArguments::New(num_type_params));
      TypeParameter& type_param = TypeParameter::Handle(zone);
      for (intptr_t i = 0; i < num_type_params; i++) {
        type_param ^= type_params.TypeAt(i);
        type_param ^= type_param.CloneUnfinalized();
        type_params_clone.SetTypeAt(i, type_param);
      }
      fun_clone.set_type_parameters(type_params_clone);
    }
    AbstractType& type = AbstractType::Handle(zone, fun.result_type());
    type = type.CloneUnfinalized();
    fun_clone.set_result_type(type);
    const intptr_t num_params = fun.NumParameters();
    fun_clone.set_num_fixed_parameters(fun.num_fixed_parameters());
    fun_clone.SetNumOptionalParameters(fun.NumOptionalParameters(),
                                       fun.HasOptionalPositionalParameters());
    fun_clone.set_parameter_types(
        Array::Handle(Array::New(num_params, Heap::kOld)));
    for (intptr_t i = 0; i < num_params; i++) {
      type = fun.ParameterTypeAt(i);
      type = type.CloneUnfinalized();
      fun_clone.SetParameterTypeAt(i, type);
    }
    fun_clone.set_parameter_names(Array::Handle(zone, fun.parameter_names()));
    clone.set_signature(fun_clone);
    fun_clone.SetSignatureType(clone);
  }
  clone.SetIsResolved();
  return clone.raw();
}

RawAbstractType* Type::CloneUninstantiated(const Class& new_owner,
                                           TrailPtr trail) const {
  ASSERT(IsFinalized());
  ASSERT(IsCanonical());
  ASSERT(!IsMalformed());
  if (IsInstantiated()) {
    return raw();
  }
  // We may recursively encounter a type already being cloned, because we clone
  // the upper bounds of its uninstantiated type arguments in the same pass.
  Zone* zone = Thread::Current()->zone();
  Type& clone = Type::Handle(zone);
  clone ^= OnlyBuddyInTrail(trail);
  if (!clone.IsNull()) {
    return clone.raw();
  }
  const Class& type_cls = Class::Handle(zone, type_class());
  clone = Type::New(type_cls, TypeArguments::Handle(zone), token_pos());
  // Preserve the bound error if any.
  if (IsMalbounded()) {
    const LanguageError& bound_error = LanguageError::Handle(zone, error());
    clone.set_error(bound_error);
  }
  // Clone the signature if this type represents a function type.
  const Function& fun = Function::Handle(zone, signature());
  if (!fun.IsNull()) {
    ASSERT(type_cls.IsTypedefClass() || type_cls.IsClosureClass());
    // If the scope class is not a typedef and if it is generic, it must be the
    // mixin class, set it to the new owner.
    const Function& parent = Function::Handle(zone, fun.parent_function());
    // TODO(regis): Is it safe to reuse the parent function with the old owner?
    Function& fun_clone = Function::Handle(
        zone, Function::NewSignatureFunction(new_owner, parent,
                                             TokenPosition::kNoSource));
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, fun.type_parameters());
    if (!type_params.IsNull()) {
      const intptr_t num_type_params = type_params.Length();
      const TypeArguments& type_params_clone =
          TypeArguments::Handle(zone, TypeArguments::New(num_type_params));
      TypeParameter& type_param = TypeParameter::Handle(zone);
      for (intptr_t i = 0; i < num_type_params; i++) {
        type_param ^= type_params.TypeAt(i);
        type_param ^= type_param.CloneUninstantiated(new_owner, trail);
        type_params_clone.SetTypeAt(i, type_param);
      }
      fun_clone.set_type_parameters(type_params_clone);
    }
    AbstractType& type = AbstractType::Handle(zone, fun.result_type());
    type = type.CloneUninstantiated(new_owner, trail);
    fun_clone.set_result_type(type);
    const intptr_t num_params = fun.NumParameters();
    fun_clone.set_num_fixed_parameters(fun.num_fixed_parameters());
    fun_clone.SetNumOptionalParameters(fun.NumOptionalParameters(),
                                       fun.HasOptionalPositionalParameters());
    fun_clone.set_parameter_types(
        Array::Handle(Array::New(num_params, Heap::kOld)));
    for (intptr_t i = 0; i < num_params; i++) {
      type = fun.ParameterTypeAt(i);
      type = type.CloneUninstantiated(new_owner, trail);
      fun_clone.SetParameterTypeAt(i, type);
    }
    fun_clone.set_parameter_names(Array::Handle(zone, fun.parameter_names()));
    clone.set_signature(fun_clone);
  }
  TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
  if (!type_args.IsNull()) {
    // Upper bounds of uninstantiated type arguments may form a cycle.
    if (type_args.IsRecursive() || !type_args.IsInstantiated()) {
      AddOnlyBuddyToTrail(&trail, clone);
    }
    type_args = type_args.CloneUninstantiated(new_owner, trail);
    clone.set_arguments(type_args);
  }
  clone.SetIsFinalized();
  clone ^= clone.Canonicalize();
  return clone.raw();
}

RawAbstractType* Type::Canonicalize(TrailPtr trail) const {
  ASSERT(IsFinalized());
  if (IsCanonical() || IsMalformed()) {
    ASSERT(IsMalformed() || TypeArguments::Handle(arguments()).IsOld());
    return this->raw();
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

  // Since void is a keyword, we never have to canonicalize the void type after
  // it is canonicalized once by the vm isolate. The parser does the mapping.
  ASSERT((type_class() != Object::void_class()) ||
         (isolate == Dart::vm_isolate()));

  // Since dynamic is not a keyword, the parser builds a type that requires
  // canonicalization.
  if ((type_class() == Object::dynamic_class()) &&
      (isolate != Dart::vm_isolate())) {
    ASSERT(Object::dynamic_type().IsCanonical());
    return Object::dynamic_type().raw();
  }

  const Class& cls = Class::Handle(zone, type_class());

  // Fast canonical lookup/registry for simple types.
  if (!cls.IsGeneric() && !cls.IsClosureClass() && !cls.IsTypedefClass()) {
    ASSERT(!IsFunctionType());
    Type& type = Type::Handle(zone, cls.CanonicalType());
    if (type.IsNull()) {
      ASSERT(!cls.raw()->IsVMHeapObject() || (isolate == Dart::vm_isolate()));
      // Canonicalize the type arguments of the supertype, if any.
      TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
      type_args = type_args.Canonicalize(trail);
      if (IsCanonical()) {
        // Canonicalizing type_args canonicalized this type.
        ASSERT(IsRecursive());
        return this->raw();
      }
      set_arguments(type_args);
      type = cls.CanonicalType();  // May be set while canonicalizing type args.
      if (type.IsNull()) {
        SafepointMutexLocker ml(isolate->type_canonicalization_mutex());
        // Recheck if type exists.
        type = cls.CanonicalType();
        if (type.IsNull()) {
          if (this->IsNew()) {
            type ^= Object::Clone(*this, Heap::kOld);
          } else {
            type ^= this->raw();
          }
          ASSERT(type.IsOld());
          type.ComputeHash();
          type.SetCanonical();
          cls.set_canonical_type(type);
          return type.raw();
        }
      }
    }
    ASSERT(this->Equals(type));
    ASSERT(type.IsCanonical());
    ASSERT(type.IsOld());
    return type.raw();
  }

  AbstractType& type = Type::Handle(zone);
  ObjectStore* object_store = isolate->object_store();
  {
    SafepointMutexLocker ml(isolate->type_canonicalization_mutex());
    CanonicalTypeSet table(zone, object_store->canonical_types());
    type ^= table.GetOrNull(CanonicalTypeKey(*this));
    ASSERT(object_store->canonical_types() == table.Release().raw());
  }
  if (type.IsNull()) {
    // The type was not found in the table. It is not canonical yet.

    // Canonicalize the type arguments.
    TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
    // In case the type is first canonicalized at runtime, its type argument
    // vector may be longer than necessary. This is not an issue.
    ASSERT(type_args.IsNull() ||
           (type_args.Length() >= cls.NumTypeArguments()));
    type_args = type_args.Canonicalize(trail);
    if (IsCanonical()) {
      // Canonicalizing type_args canonicalized this type as a side effect.
      ASSERT(IsRecursive());
      // Cycles via typedefs are detected and disallowed, but a function type
      // can be recursive due to a cycle in its type arguments.
      return this->raw();
    }
    set_arguments(type_args);
    ASSERT(type_args.IsNull() || type_args.IsOld());

    // In case of a function type, the signature has already been canonicalized
    // when finalizing the type and passing kCanonicalize as finalization.
    // Therefore, we do not canonicalize the signature here, which would have no
    // effect on selecting the canonical type anyway, because the function
    // object is not replaced when canonicalizing the signature.

    // Check to see if the type got added to canonical list as part of the
    // type arguments canonicalization.
    SafepointMutexLocker ml(isolate->type_canonicalization_mutex());
    CanonicalTypeSet table(zone, object_store->canonical_types());
    type ^= table.GetOrNull(CanonicalTypeKey(*this));
    if (type.IsNull()) {
      // Add this Type into the canonical list of types.
      if (this->IsNew()) {
        type ^= Object::Clone(*this, Heap::kOld);
      } else {
        type ^= this->raw();
      }
      ASSERT(type.IsOld());
      type.SetCanonical();  // Mark object as being canonical.
      bool present = table.Insert(type);
      ASSERT(!present);
    }
    object_store->set_canonical_types(table.Release());
  }
  return type.raw();
}

#if defined(DEBUG)
bool Type::CheckIsCanonical(Thread* thread) const {
  if (IsMalformed()) {
    return true;
  }
  if (type_class() == Object::dynamic_class()) {
    return (raw() == Object::dynamic_type().raw());
  }
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  AbstractType& type = Type::Handle(zone);
  const Class& cls = Class::Handle(zone, type_class());

  // Fast canonical lookup/registry for simple types.
  if (!cls.IsGeneric() && !cls.IsClosureClass() && !cls.IsTypedefClass()) {
    ASSERT(!IsFunctionType());
    type = cls.CanonicalType();
    return (raw() == type.raw());
  }

  ObjectStore* object_store = isolate->object_store();
  {
    SafepointMutexLocker ml(isolate->type_canonicalization_mutex());
    CanonicalTypeSet table(zone, object_store->canonical_types());
    type ^= table.GetOrNull(CanonicalTypeKey(*this));
    object_store->set_canonical_types(table.Release());
  }
  return (raw() == type.raw());
}
#endif  // DEBUG

RawString* Type::EnumerateURIs() const {
  if (IsDynamicType() || IsVoidType()) {
    return Symbols::Empty().raw();
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, 6);
  if (IsFunctionType()) {
    // The scope class and type arguments do not appear explicitly in the user
    // visible name. The type arguments were used to instantiate the function
    // type prior to this call.
    const Function& sig_fun = Function::Handle(zone, signature());
    AbstractType& type = AbstractType::Handle(zone);
    const intptr_t num_params = sig_fun.NumParameters();
    GrowableHandlePtrArray<const String> pieces(zone, num_params + 1);
    for (intptr_t i = 0; i < num_params; i++) {
      type = sig_fun.ParameterTypeAt(i);
      pieces.Add(String::Handle(zone, type.EnumerateURIs()));
    }
    // Handle result type last, since it appears last in the user visible name.
    type = sig_fun.result_type();
    pieces.Add(String::Handle(zone, type.EnumerateURIs()));
  } else {
    const Class& cls = Class::Handle(zone, type_class());
    pieces.Add(Symbols::TwoSpaces());
    pieces.Add(String::Handle(zone, cls.UserVisibleName()));
    pieces.Add(Symbols::SpaceIsFromSpace());
    const Library& library = Library::Handle(zone, cls.library());
    pieces.Add(String::Handle(zone, library.url()));
    pieces.Add(Symbols::NewLine());
    const TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
    pieces.Add(String::Handle(zone, type_args.EnumerateURIs()));
  }
  return Symbols::FromConcatAll(thread, pieces);
}

intptr_t Type::ComputeHash() const {
  ASSERT(IsFinalized());
  uint32_t result = 1;
  if (IsMalformed()) return result;
  result = CombineHashes(result, Class::Handle(type_class()).id());
  result = CombineHashes(result, TypeArguments::Handle(arguments()).Hash());
  if (IsFunctionType()) {
    const Function& sig_fun = Function::Handle(signature());
    AbstractType& type = AbstractType::Handle(sig_fun.result_type());
    result = CombineHashes(result, type.Hash());
    result = CombineHashes(result, sig_fun.NumOptionalPositionalParameters());
    const intptr_t num_params = sig_fun.NumParameters();
    for (intptr_t i = 0; i < num_params; i++) {
      type = sig_fun.ParameterTypeAt(i);
      result = CombineHashes(result, type.Hash());
    }
    if (sig_fun.NumOptionalNamedParameters() > 0) {
      String& param_name = String::Handle();
      for (intptr_t i = sig_fun.num_fixed_parameters(); i < num_params; i++) {
        param_name = sig_fun.ParameterNameAt(i);
        result = CombineHashes(result, param_name.Hash());
      }
    }
  }
  result = FinalizeHash(result, kHashBits);
  SetHash(result);
  return result;
}

void Type::set_type_class(const Class& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->type_class_id_,
               reinterpret_cast<RawObject*>(Smi::New(value.id())));
}

void Type::set_unresolved_class(const Object& value) const {
  ASSERT(!value.IsNull() && value.IsUnresolvedClass());
  StorePointer(&raw_ptr()->type_class_id_, value.raw());
}

void Type::set_arguments(const TypeArguments& value) const {
  ASSERT(!IsCanonical());
  StorePointer(&raw_ptr()->arguments_, value.raw());
}

RawType* Type::New(Heap::Space space) {
  RawObject* raw =
      Object::Allocate(Type::kClassId, Type::InstanceSize(), space);
  return reinterpret_cast<RawType*>(raw);
}

RawType* Type::New(const Object& clazz,
                   const TypeArguments& arguments,
                   TokenPosition token_pos,
                   Heap::Space space) {
  const Type& result = Type::Handle(Type::New(space));
  if (clazz.IsClass()) {
    result.set_type_class(Class::Cast(clazz));
  } else {
    result.set_unresolved_class(clazz);
  }
  result.set_arguments(arguments);
  result.SetHash(0);
  result.set_token_pos(token_pos);
  result.StoreNonPointer(&result.raw_ptr()->type_state_, RawType::kAllocated);
  return result.raw();
}

void Type::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

void Type::set_type_state(int8_t state) const {
  ASSERT((state >= RawType::kAllocated) &&
         (state <= RawType::kFinalizedUninstantiated));
  StoreNonPointer(&raw_ptr()->type_state_, state);
}

const char* Type::ToCString() const {
  if (IsNull()) {
    return "Type: null";
  }
  Zone* zone = Thread::Current()->zone();
  const char* unresolved = IsResolved() ? "" : "Unresolved ";
  const TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
  const char* args_cstr = type_args.IsNull() ? "null" : type_args.ToCString();
  Class& cls = Class::Handle(zone);
  const char* class_name;
  if (HasResolvedTypeClass()) {
    cls = type_class();
    class_name = String::Handle(zone, cls.Name()).ToCString();
  } else {
    class_name = UnresolvedClass::Handle(zone, unresolved_class()).ToCString();
  }
  if (IsFunctionType()) {
    const Function& sig_fun = Function::Handle(zone, signature());
    const String& sig = String::Handle(zone, sig_fun.Signature());
    if (cls.IsClosureClass()) {
      ASSERT(type_args.IsNull());
      return OS::SCreate(zone, "%sFunction Type: %s", unresolved,
                         sig.ToCString());
    }
    return OS::SCreate(zone, "%s Function Type: %s (class: %s, args: %s)",
                       unresolved, sig.ToCString(), class_name, args_cstr);
  }
  if (type_args.IsNull()) {
    return OS::SCreate(zone, "%sType: class '%s'", unresolved, class_name);
  } else if (IsResolved() && IsFinalized() && IsRecursive()) {
    const intptr_t hash = Hash();
    return OS::SCreate(zone, "Type: (@%p H%" Px ") class '%s', args:[%s]",
                       raw(), hash, class_name, args_cstr);
  } else {
    return OS::SCreate(zone, "%sType: class '%s', args:[%s]", unresolved,
                       class_name, args_cstr);
  }
}

bool TypeRef::IsInstantiated(Genericity genericity,
                             intptr_t num_free_fun_type_params,
                             TrailPtr trail) const {
  if (TestAndAddToTrail(&trail)) {
    return true;
  }
  const AbstractType& ref_type = AbstractType::Handle(type());
  return !ref_type.IsNull() &&
         ref_type.IsInstantiated(genericity, num_free_fun_type_params, trail);
}

bool TypeRef::IsEquivalent(const Instance& other, TrailPtr trail) const {
  if (raw() == other.raw()) {
    return true;
  }
  if (!other.IsAbstractType()) {
    return false;
  }
  if (TestAndAddBuddyToTrail(&trail, AbstractType::Cast(other))) {
    return true;
  }
  const AbstractType& ref_type = AbstractType::Handle(type());
  return !ref_type.IsNull() && ref_type.IsEquivalent(other, trail);
}

void TypeRef::SetScopeFunction(const Function& function) const {
  // TypeRefs are created during finalization, when scope functions have
  // already been adjusted.
  UNREACHABLE();
}

RawTypeRef* TypeRef::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Error* bound_error,
    TrailPtr instantiation_trail,
    TrailPtr bound_trail,
    Heap::Space space) const {
  TypeRef& instantiated_type_ref = TypeRef::Handle();
  instantiated_type_ref ^= OnlyBuddyInTrail(instantiation_trail);
  if (!instantiated_type_ref.IsNull()) {
    return instantiated_type_ref.raw();
  }
  instantiated_type_ref = TypeRef::New();
  AddOnlyBuddyToTrail(&instantiation_trail, instantiated_type_ref);

  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull() && !ref_type.IsTypeRef());
  AbstractType& instantiated_ref_type = AbstractType::Handle();
  instantiated_ref_type = ref_type.InstantiateFrom(
      instantiator_type_arguments, function_type_arguments, bound_error,
      instantiation_trail, bound_trail, space);
  ASSERT(!instantiated_ref_type.IsTypeRef());
  instantiated_type_ref.set_type(instantiated_ref_type);
  return instantiated_type_ref.raw();
}

RawTypeRef* TypeRef::CloneUninstantiated(const Class& new_owner,
                                         TrailPtr trail) const {
  TypeRef& cloned_type_ref = TypeRef::Handle();
  cloned_type_ref ^= OnlyBuddyInTrail(trail);
  if (!cloned_type_ref.IsNull()) {
    return cloned_type_ref.raw();
  }
  cloned_type_ref = TypeRef::New();
  AddOnlyBuddyToTrail(&trail, cloned_type_ref);
  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull() && !ref_type.IsTypeRef());
  AbstractType& cloned_ref_type = AbstractType::Handle();
  cloned_ref_type = ref_type.CloneUninstantiated(new_owner, trail);
  ASSERT(!cloned_ref_type.IsTypeRef());
  cloned_type_ref.set_type(cloned_ref_type);
  return cloned_type_ref.raw();
}

void TypeRef::set_type(const AbstractType& value) const {
  ASSERT(value.IsFunctionType() || value.HasResolvedTypeClass());
  ASSERT(!value.IsTypeRef());
  StorePointer(&raw_ptr()->type_, value.raw());
}

// A TypeRef cannot be canonical by definition. Only its referenced type can be.
// Consider the type Derived, where class Derived extends Base<Derived>.
// The first type argument of its flattened type argument vector is Derived,
// represented by a TypeRef pointing to itself.
RawAbstractType* TypeRef::Canonicalize(TrailPtr trail) const {
  if (TestAndAddToTrail(&trail)) {
    return raw();
  }
  // TODO(regis): Try to reduce the number of nodes required to represent the
  // referenced recursive type.
  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull());
  ref_type = ref_type.Canonicalize(trail);
  set_type(ref_type);
  return raw();
}

#if defined(DEBUG)
bool TypeRef::CheckIsCanonical(Thread* thread) const {
  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull());
  return ref_type.CheckIsCanonical(thread);
}
#endif  // DEBUG

RawString* TypeRef::EnumerateURIs() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const AbstractType& ref_type = AbstractType::Handle(zone, type());
  ASSERT(!ref_type.IsDynamicType() && !ref_type.IsVoidType());
  GrowableHandlePtrArray<const String> pieces(zone, 6);
  const Class& cls = Class::Handle(zone, ref_type.type_class());
  pieces.Add(Symbols::TwoSpaces());
  pieces.Add(String::Handle(zone, cls.UserVisibleName()));
  // Break cycle by not printing type arguments, but '<optimized out>' instead.
  pieces.Add(Symbols::OptimizedOut());
  pieces.Add(Symbols::SpaceIsFromSpace());
  const Library& library = Library::Handle(zone, cls.library());
  pieces.Add(String::Handle(zone, library.url()));
  pieces.Add(Symbols::NewLine());
  return Symbols::FromConcatAll(thread, pieces);
}

intptr_t TypeRef::Hash() const {
  // Do not calculate the hash of the referenced type to avoid divergence.
  const AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull());
  const uint32_t result = Class::Handle(ref_type.type_class()).id();
  return FinalizeHash(result, kHashBits);
}

RawTypeRef* TypeRef::New() {
  RawObject* raw =
      Object::Allocate(TypeRef::kClassId, TypeRef::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawTypeRef*>(raw);
}

RawTypeRef* TypeRef::New(const AbstractType& type) {
  const TypeRef& result = TypeRef::Handle(TypeRef::New());
  result.set_type(type);
  return result.raw();
}

const char* TypeRef::ToCString() const {
  AbstractType& ref_type = AbstractType::Handle(type());
  if (ref_type.IsNull()) {
    return "TypeRef: null";
  }
  const char* type_cstr =
      String::Handle(Class::Handle(type_class()).Name()).ToCString();
  if (ref_type.IsFinalized()) {
    const intptr_t hash = ref_type.Hash();
    return OS::SCreate(Thread::Current()->zone(),
                       "TypeRef: %s<...> (@%p H%" Px ")", type_cstr,
                       ref_type.raw(), hash);
  } else {
    return OS::SCreate(Thread::Current()->zone(), "TypeRef: %s<...>",
                       type_cstr);
  }
}

void TypeParameter::SetIsFinalized() const {
  ASSERT(!IsFinalized());
  set_type_state(RawTypeParameter::kFinalizedUninstantiated);
}

bool TypeParameter::IsInstantiated(Genericity genericity,
                                   intptr_t num_free_fun_type_params,
                                   TrailPtr trail) const {
  if (IsClassTypeParameter()) {
    return genericity == kFunctions;
  }
  ASSERT(IsFunctionTypeParameter());
  ASSERT(IsFinalized());
  return (genericity == kCurrentClass) || (index() >= num_free_fun_type_params);
}

bool TypeParameter::IsEquivalent(const Instance& other, TrailPtr trail) const {
  if (raw() == other.raw()) {
    return true;
  }
  if (other.IsTypeRef()) {
    // Unfold right hand type. Divergence is controlled by left hand type.
    const AbstractType& other_ref_type =
        AbstractType::Handle(TypeRef::Cast(other).type());
    ASSERT(!other_ref_type.IsTypeRef());
    return IsEquivalent(other_ref_type, trail);
  }
  if (!other.IsTypeParameter()) {
    return false;
  }
  const TypeParameter& other_type_param = TypeParameter::Cast(other);
  if (parameterized_class_id() != other_type_param.parameterized_class_id()) {
    return false;
  }
  // The function doesn't matter in type tests, but it does in canonicalization.
  if (parameterized_function() != other_type_param.parameterized_function()) {
    return false;
  }
  if (IsFinalized() == other_type_param.IsFinalized()) {
    return (index() == other_type_param.index());
  }
  return name() == other_type_param.name();
}

void TypeParameter::set_parameterized_class(const Class& value) const {
  // Set value may be null.
  classid_t cid = kFunctionCid;  // Denotes a function type parameter.
  if (!value.IsNull()) {
    cid = value.id();
  }
  StoreNonPointer(&raw_ptr()->parameterized_class_id_, cid);
}

classid_t TypeParameter::parameterized_class_id() const {
  return raw_ptr()->parameterized_class_id_;
}

RawClass* TypeParameter::parameterized_class() const {
  classid_t cid = parameterized_class_id();
  if (cid == kFunctionCid) {
    return Class::null();
  }
  return Isolate::Current()->class_table()->At(cid);
}

void TypeParameter::set_parameterized_function(const Function& value) const {
  StorePointer(&raw_ptr()->parameterized_function_, value.raw());
}

void TypeParameter::set_index(intptr_t value) const {
  ASSERT(value >= 0);
  ASSERT(Utils::IsInt(16, value));
  StoreNonPointer(&raw_ptr()->index_, value);
}

void TypeParameter::set_name(const String& value) const {
  ASSERT(value.IsSymbol());
  StorePointer(&raw_ptr()->name_, value.raw());
}

void TypeParameter::set_bound(const AbstractType& value) const {
  StorePointer(&raw_ptr()->bound_, value.raw());
}

RawAbstractType* TypeParameter::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Error* bound_error,
    TrailPtr instantiation_trail,
    TrailPtr bound_trail,
    Heap::Space space) const {
  ASSERT(IsFinalized());
  if (IsFunctionTypeParameter()) {
    // We make the distinction between a null function_type_arguments vector,
    // which instantiates every function type parameter to dynamic, and a
    // (possibly empty) function_type_arguments vector of length N, which only
    // instantiates function type parameters with indices below N.
    if (function_type_arguments.IsNull()) {
      return Type::DynamicType();
    }
    if (index() >= function_type_arguments.Length()) {
      // Return uninstantiated type parameter unchanged.
      return raw();
    }
    return function_type_arguments.TypeAt(index());
  }
  ASSERT(IsClassTypeParameter());
  if (instantiator_type_arguments.IsNull()) {
    return Type::DynamicType();
  }
  return instantiator_type_arguments.TypeAt(index());
  // There is no need to canonicalize the instantiated type parameter, since all
  // type arguments are canonicalized at type finalization time. It would be too
  // early to canonicalize the returned type argument here, since instantiation
  // not only happens at run time, but also during type finalization.

  // If the instantiated type parameter type_arg is a BoundedType, it means that
  // it is still uninstantiated and that we are instantiating at finalization
  // time (i.e. compile time).
  // Indeed, the instantiator (type arguments of an instance) is always
  // instantiated at run time and any bounds were checked during allocation.
  // Similarly, function type arguments are always instantiated before being
  // passed to a function at run time and bounds are checked as part of the
  // signature compatibility check (during call resolution or in the function
  // prolog).
}

bool TypeParameter::CheckBound(const AbstractType& bounded_type,
                               const AbstractType& upper_bound,
                               Error* bound_error,
                               TrailPtr bound_trail,
                               Heap::Space space) const {
  ASSERT((bound_error != NULL) && bound_error->IsNull());
  ASSERT(bounded_type.IsFinalized());
  ASSERT(upper_bound.IsFinalized());
  ASSERT(!bounded_type.IsMalformed());
  if (bounded_type.IsTypeRef() || upper_bound.IsTypeRef()) {
    // Shortcut the bound check if the pair <bounded_type, upper_bound> is
    // already in the trail.
    if (bounded_type.TestAndAddBuddyToTrail(&bound_trail, upper_bound)) {
      return true;
    }
  }

  if (bounded_type.IsSubtypeOf(upper_bound, bound_error, bound_trail, space)) {
    return true;
  }
  // Set bound_error if the caller is interested and if this is the first error.
  if ((bound_error != NULL) && bound_error->IsNull()) {
    // Report the bound error only if both the bounded type and the upper bound
    // are instantiated. Otherwise, we cannot tell yet it is a bound error.
    if (bounded_type.IsInstantiated() && upper_bound.IsInstantiated()) {
      // There is another special case where we do not want to report a bound
      // error yet: if the upper bound is a function type, but the bounded type
      // is not and its class is not compiled yet, i.e. we cannot look for
      // a call method yet.
      if (!bounded_type.IsFunctionType() && upper_bound.IsFunctionType() &&
          bounded_type.HasResolvedTypeClass() &&
          !Class::Handle(bounded_type.type_class()).is_finalized()) {
        return false;  // Not a subtype yet, but no bound error yet.
      }
      const String& bounded_type_name =
          String::Handle(bounded_type.UserVisibleName());
      const String& upper_bound_name =
          String::Handle(upper_bound.UserVisibleName());
      const AbstractType& declared_bound = AbstractType::Handle(bound());
      const String& declared_bound_name =
          String::Handle(declared_bound.UserVisibleName());
      const String& type_param_name = String::Handle(UserVisibleName());
      const Class& cls = Class::Handle(parameterized_class());
      const String& class_name = String::Handle(cls.Name());
      const Script& script = Script::Handle(cls.script());
      // Since the bound may have been canonicalized, its token index is
      // meaningless, therefore use the token index of this type parameter.
      *bound_error = LanguageError::NewFormatted(
          *bound_error, script, token_pos(), Report::AtLocation,
          Report::kMalboundedType, Heap::kNew,
          "type parameter '%s' of class '%s' must extend bound '%s', "
          "but type argument '%s' is not a subtype of '%s' where\n%s%s",
          type_param_name.ToCString(), class_name.ToCString(),
          declared_bound_name.ToCString(), bounded_type_name.ToCString(),
          upper_bound_name.ToCString(),
          String::Handle(bounded_type.EnumerateURIs()).ToCString(),
          String::Handle(upper_bound.EnumerateURIs()).ToCString());
    }
  }
  return false;
}

RawAbstractType* TypeParameter::CloneUnfinalized() const {
  if (IsFinalized()) {
    return raw();
  }
  // No need to clone bound, as it is not part of the finalization state.
  return TypeParameter::New(Class::Handle(parameterized_class()),
                            Function::Handle(parameterized_function()), index(),
                            String::Handle(name()),
                            AbstractType::Handle(bound()), token_pos());
}

RawAbstractType* TypeParameter::CloneUninstantiated(const Class& new_owner,
                                                    TrailPtr trail) const {
  ASSERT(IsFinalized());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  TypeParameter& clone = TypeParameter::Handle(zone);
  clone ^= OnlyBuddyInTrail(trail);
  if (!clone.IsNull()) {
    return clone.raw();
  }
  intptr_t new_index = index();
  AbstractType& upper_bound = AbstractType::Handle(zone, bound());
  const Function& fun = Function::Handle(zone, parameterized_function());
  Class& cls = Class::Handle(zone, parameterized_class());
  if (!cls.IsNull()) {
    ASSERT(fun.IsNull());
    new_index += new_owner.NumTypeArguments() - cls.NumTypeArguments();
    cls = new_owner.raw();
  } else {
    ASSERT(IsFunctionTypeParameter());
    // Only the bounds of function type parameters need cloning.
  }
  clone = TypeParameter::New(cls, fun, new_index, String::Handle(zone, name()),
                             upper_bound,  // Not cloned yet.
                             token_pos());
  clone.SetIsFinalized();
  AddOnlyBuddyToTrail(&trail, clone);
  upper_bound = upper_bound.CloneUninstantiated(new_owner, trail);
  clone.set_bound(upper_bound);
  return clone.raw();
}

RawString* TypeParameter::EnumerateURIs() const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, 4);
  pieces.Add(Symbols::TwoSpaces());
  pieces.Add(String::Handle(zone, name()));
  Class& cls = Class::Handle(zone, parameterized_class());
  if (cls.IsNull()) {
    const Function& fun = Function::Handle(zone, parameterized_function());
    pieces.Add(Symbols::SpaceOfSpace());
    pieces.Add(String::Handle(zone, fun.UserVisibleName()));
    cls = fun.Owner();  // May be null.
    // TODO(regis): Should we keep the function owner for better error messages?
  }
  if (!cls.IsNull()) {
    pieces.Add(Symbols::SpaceOfSpace());
    pieces.Add(String::Handle(zone, cls.UserVisibleName()));
    pieces.Add(Symbols::SpaceIsFromSpace());
    const Library& library = Library::Handle(zone, cls.library());
    pieces.Add(String::Handle(zone, library.url()));
  }
  pieces.Add(Symbols::NewLine());
  return Symbols::FromConcatAll(thread, pieces);
}

intptr_t TypeParameter::ComputeHash() const {
  ASSERT(IsFinalized());
  uint32_t result;
  if (IsClassTypeParameter()) {
    result = parameterized_class_id();
  } else {
    result = Function::Handle(parameterized_function()).Hash();
  }
  // No need to include the hash of the bound, since the type parameter is fully
  // identified by its class and index.
  result = CombineHashes(result, index());
  result = FinalizeHash(result, kHashBits);
  SetHash(result);
  return result;
}

RawTypeParameter* TypeParameter::New() {
  RawObject* raw = Object::Allocate(TypeParameter::kClassId,
                                    TypeParameter::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawTypeParameter*>(raw);
}

RawTypeParameter* TypeParameter::New(const Class& parameterized_class,
                                     const Function& parameterized_function,
                                     intptr_t index,
                                     const String& name,
                                     const AbstractType& bound,
                                     TokenPosition token_pos) {
  ASSERT(parameterized_class.IsNull() != parameterized_function.IsNull());
  const TypeParameter& result = TypeParameter::Handle(TypeParameter::New());
  result.set_parameterized_class(parameterized_class);
  result.set_parameterized_function(parameterized_function);
  result.set_index(index);
  result.set_name(name);
  result.set_bound(bound);
  result.SetHash(0);
  result.set_token_pos(token_pos);
  result.StoreNonPointer(&result.raw_ptr()->type_state_,
                         RawTypeParameter::kAllocated);
  return result.raw();
}

void TypeParameter::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

void TypeParameter::set_type_state(int8_t state) const {
  ASSERT((state == RawTypeParameter::kAllocated) ||
         (state == RawTypeParameter::kBeingFinalized) ||
         (state == RawTypeParameter::kFinalizedUninstantiated));
  StoreNonPointer(&raw_ptr()->type_state_, state);
}

const char* TypeParameter::ToCString() const {
  const char* name_cstr = String::Handle(Name()).ToCString();
  const AbstractType& upper_bound = AbstractType::Handle(bound());
  const char* bound_cstr = String::Handle(upper_bound.Name()).ToCString();
  if (IsFunctionTypeParameter()) {
    const char* format =
        "TypeParameter: name %s; index: %d; function: %s; bound: %s";
    const Function& function = Function::Handle(parameterized_function());
    const char* fun_cstr = String::Handle(function.name()).ToCString();
    intptr_t len =
        OS::SNPrint(NULL, 0, format, name_cstr, index(), fun_cstr, bound_cstr) +
        1;
    char* chars = Thread::Current()->zone()->Alloc<char>(len);
    OS::SNPrint(chars, len, format, name_cstr, index(), fun_cstr, bound_cstr);
    return chars;
  } else {
    const char* format =
        "TypeParameter: name %s; index: %d; class: %s; bound: %s";
    const Class& cls = Class::Handle(parameterized_class());
    const char* cls_cstr =
        cls.IsNull() ? " null" : String::Handle(cls.Name()).ToCString();
    intptr_t len =
        OS::SNPrint(NULL, 0, format, name_cstr, index(), cls_cstr, bound_cstr) +
        1;
    char* chars = Thread::Current()->zone()->Alloc<char>(len);
    OS::SNPrint(chars, len, format, name_cstr, index(), cls_cstr, bound_cstr);
    return chars;
  }
}

bool BoundedType::IsMalformed() const {
  return AbstractType::Handle(type()).IsMalformed();
}

bool BoundedType::IsMalbounded() const {
  return AbstractType::Handle(type()).IsMalbounded();
}

bool BoundedType::IsMalformedOrMalbounded() const {
  return AbstractType::Handle(type()).IsMalformedOrMalbounded();
}

RawLanguageError* BoundedType::error() const {
  return AbstractType::Handle(type()).error();
}

bool BoundedType::IsEquivalent(const Instance& other, TrailPtr trail) const {
  // BoundedType are not canonicalized, because their bound may get finalized
  // after the BoundedType is created and initialized.
  if (raw() == other.raw()) {
    return true;
  }
  if (other.IsTypeRef()) {
    // Unfold right hand type. Divergence is controlled by left hand type.
    const AbstractType& other_ref_type =
        AbstractType::Handle(TypeRef::Cast(other).type());
    ASSERT(!other_ref_type.IsTypeRef());
    return IsEquivalent(other_ref_type, trail);
  }
  if (!other.IsBoundedType()) {
    return false;
  }
  const BoundedType& other_bounded = BoundedType::Cast(other);
  if (type_parameter() != other_bounded.type_parameter()) {
    return false;
  }
  const AbstractType& this_type = AbstractType::Handle(type());
  const AbstractType& other_type = AbstractType::Handle(other_bounded.type());
  if (!this_type.IsEquivalent(other_type, trail)) {
    return false;
  }
  const AbstractType& this_bound = AbstractType::Handle(bound());
  const AbstractType& other_bound = AbstractType::Handle(other_bounded.bound());
  return this_bound.IsFinalized() && other_bound.IsFinalized() &&
         this_bound.Equals(other_bound);  // Different graph, do not pass trail.
}

bool BoundedType::IsRecursive() const {
  return AbstractType::Handle(type()).IsRecursive();
}

void BoundedType::SetScopeFunction(const Function& function) const {
  AbstractType::Handle(type()).SetScopeFunction(function);
  AbstractType::Handle(bound()).SetScopeFunction(function);
}

void BoundedType::set_type(const AbstractType& value) const {
  ASSERT(value.IsFinalized() || value.IsBeingFinalized() ||
         value.IsTypeParameter());
  ASSERT(!value.IsMalformed());
  StorePointer(&raw_ptr()->type_, value.raw());
}

void BoundedType::set_bound(const AbstractType& value) const {
  // The bound may still be unfinalized because of legal cycles.
  // It must be finalized before it is checked at run time, though.
  ASSERT(value.IsFinalized() || value.IsBeingFinalized());
  StorePointer(&raw_ptr()->bound_, value.raw());
}

void BoundedType::set_type_parameter(const TypeParameter& value) const {
  // A null type parameter is set when marking a type malformed because of a
  // bound error at compile time.
  ASSERT(value.IsNull() || value.IsFinalized());
  StorePointer(&raw_ptr()->type_parameter_, value.raw());
}

RawAbstractType* BoundedType::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    Error* bound_error,
    TrailPtr instantiation_trail,
    TrailPtr bound_trail,
    Heap::Space space) const {
  ASSERT(IsFinalized());
  AbstractType& bounded_type = AbstractType::Handle(type());
  ASSERT(bounded_type.IsFinalized());
  AbstractType& instantiated_bounded_type =
      AbstractType::Handle(bounded_type.raw());
  if (!bounded_type.IsInstantiated()) {
    instantiated_bounded_type = bounded_type.InstantiateFrom(
        instantiator_type_arguments, function_type_arguments, bound_error,
        instantiation_trail, bound_trail, space);
    // In case types of instantiator_type_arguments are not finalized
    // (or instantiated), then the instantiated_bounded_type is not finalized
    // (or instantiated) either.
    // Note that instantiator_type_arguments must have the final length, though.
  }
  // If instantiated_bounded_type is not finalized, it is too early to check
  // its upper bound. It will be checked in a second finalization phase.
  if ((Isolate::Current()->type_checks()) && (bound_error != NULL) &&
      bound_error->IsNull() && instantiated_bounded_type.IsFinalized()) {
    AbstractType& upper_bound = AbstractType::Handle(bound());
    ASSERT(!upper_bound.IsObjectType() && !upper_bound.IsDynamicType());
    AbstractType& instantiated_upper_bound =
        AbstractType::Handle(upper_bound.raw());
    if (upper_bound.IsFinalized() && !upper_bound.IsInstantiated()) {
      instantiated_upper_bound = upper_bound.InstantiateFrom(
          instantiator_type_arguments, function_type_arguments, bound_error,
          instantiation_trail, bound_trail, space);
      // The instantiated_upper_bound may not be finalized or instantiated.
      // See comment above.
    }
    if (bound_error->IsNull()) {
      // Shortcut the F-bounded case where we have reached a fixpoint.
      if (instantiated_bounded_type.Equals(bounded_type) &&
          instantiated_upper_bound.Equals(upper_bound)) {
        return bounded_type.raw();
      }
      const TypeParameter& type_param = TypeParameter::Handle(type_parameter());
      if (instantiated_upper_bound.IsFinalized() &&
          (!type_param.CheckBound(instantiated_bounded_type,
                                  instantiated_upper_bound, bound_error,
                                  bound_trail, space) &&
           bound_error->IsNull())) {
        // We cannot determine yet whether the bounded_type is below the
        // upper_bound, because one or both of them is still being finalized or
        // uninstantiated. For example, instantiated_bounded_type may be the
        // still unfinalized cloned type parameter of a mixin application class.
        // There is another special case where we do not want to report a bound
        // error yet: if the upper bound is a function type, but the bounded
        // type is not and its class is not compiled yet, i.e. we cannot look
        // for a call method yet.
        ASSERT(!instantiated_bounded_type.IsInstantiated() ||
               !instantiated_upper_bound.IsInstantiated() ||
               (!instantiated_bounded_type.IsFunctionType() &&
                instantiated_upper_bound.IsFunctionType() &&
                instantiated_bounded_type.HasResolvedTypeClass() &&
                !Class::Handle(instantiated_bounded_type.type_class())
                     .is_finalized()));
        // Postpone bound check by returning a new BoundedType with unfinalized
        // or partially instantiated bounded_type and upper_bound, but keeping
        // type_param.
        instantiated_bounded_type = BoundedType::New(
            instantiated_bounded_type, instantiated_upper_bound, type_param);
      }
    }
  }
  return instantiated_bounded_type.raw();
}

RawAbstractType* BoundedType::CloneUnfinalized() const {
  if (IsFinalized()) {
    return raw();
  }
  const AbstractType& bounded_type = AbstractType::Handle(type());
  const AbstractType& bounded_type_clone =
      AbstractType::Handle(bounded_type.CloneUnfinalized());
  if (bounded_type_clone.raw() == bounded_type.raw()) {
    return raw();
  }
  // No need to clone bound or type parameter, as they are not part of the
  // finalization state of this bounded type.
  return BoundedType::New(bounded_type, AbstractType::Handle(bound()),
                          TypeParameter::Handle(type_parameter()));
}

RawAbstractType* BoundedType::CloneUninstantiated(const Class& new_owner,
                                                  TrailPtr trail) const {
  if (IsInstantiated()) {
    return raw();
  }
  AbstractType& bounded_type = AbstractType::Handle(type());
  bounded_type = bounded_type.CloneUninstantiated(new_owner, trail);
  AbstractType& upper_bound = AbstractType::Handle(bound());
  upper_bound = upper_bound.CloneUninstantiated(new_owner, trail);
  TypeParameter& type_param = TypeParameter::Handle(type_parameter());
  type_param ^= type_param.CloneUninstantiated(new_owner, trail);
  return BoundedType::New(bounded_type, upper_bound, type_param);
}

RawString* BoundedType::EnumerateURIs() const {
  // The bound does not appear in the user visible name.
  return AbstractType::Handle(type()).EnumerateURIs();
}

intptr_t BoundedType::ComputeHash() const {
  uint32_t result = AbstractType::Handle(type()).Hash();
  // No need to include the hash of the bound, since the bound is defined by the
  // type parameter (modulo instantiation state).
  result =
      CombineHashes(result, TypeParameter::Handle(type_parameter()).Hash());
  result = FinalizeHash(result, kHashBits);
  SetHash(result);
  return result;
}

RawBoundedType* BoundedType::New() {
  RawObject* raw = Object::Allocate(BoundedType::kClassId,
                                    BoundedType::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawBoundedType*>(raw);
}

RawBoundedType* BoundedType::New(const AbstractType& type,
                                 const AbstractType& bound,
                                 const TypeParameter& type_parameter) {
  const BoundedType& result = BoundedType::Handle(BoundedType::New());
  result.set_type(type);
  result.set_bound(bound);
  result.SetHash(0);
  result.set_type_parameter(type_parameter);
  return result.raw();
}

const char* BoundedType::ToCString() const {
  const char* format = "BoundedType: type %s; bound: %s; type param: %s of %s";
  const char* type_cstr =
      String::Handle(AbstractType::Handle(type()).Name()).ToCString();
  const char* bound_cstr =
      String::Handle(AbstractType::Handle(bound()).Name()).ToCString();
  const TypeParameter& type_param = TypeParameter::Handle(type_parameter());
  const char* type_param_cstr = String::Handle(type_param.name()).ToCString();
  const Class& cls = Class::Handle(type_param.parameterized_class());
  const char* cls_cstr = String::Handle(cls.Name()).ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, format, type_cstr, bound_cstr,
                             type_param_cstr, cls_cstr) +
                 1;
  char* chars = Thread::Current()->zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, format, type_cstr, bound_cstr, type_param_cstr,
              cls_cstr);
  return chars;
}

TokenPosition MixinAppType::token_pos() const {
  return AbstractType::Handle(MixinTypeAt(0)).token_pos();
}

intptr_t MixinAppType::Depth() const {
  return Array::Handle(mixin_types()).Length();
}

RawString* MixinAppType::Name() const {
  return String::New("MixinAppType");
}

const char* MixinAppType::ToCString() const {
  const char* format = "MixinAppType: super type: %s; first mixin type: %s";
  const char* super_type_cstr =
      String::Handle(AbstractType::Handle(super_type()).Name()).ToCString();
  const char* first_mixin_type_cstr =
      String::Handle(AbstractType::Handle(MixinTypeAt(0)).Name()).ToCString();
  intptr_t len =
      OS::SNPrint(NULL, 0, format, super_type_cstr, first_mixin_type_cstr) + 1;
  char* chars = Thread::Current()->zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, format, super_type_cstr, first_mixin_type_cstr);
  return chars;
}

RawAbstractType* MixinAppType::MixinTypeAt(intptr_t depth) const {
  return AbstractType::RawCast(Array::Handle(mixin_types()).At(depth));
}

void MixinAppType::set_super_type(const AbstractType& value) const {
  StorePointer(&raw_ptr()->super_type_, value.raw());
}

void MixinAppType::set_mixin_types(const Array& value) const {
  StorePointer(&raw_ptr()->mixin_types_, value.raw());
}

RawMixinAppType* MixinAppType::New() {
  // MixinAppType objects do not survive finalization, so allocate
  // on new heap.
  RawObject* raw = Object::Allocate(MixinAppType::kClassId,
                                    MixinAppType::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawMixinAppType*>(raw);
}

RawMixinAppType* MixinAppType::New(const AbstractType& super_type,
                                   const Array& mixin_types) {
  const MixinAppType& result = MixinAppType::Handle(MixinAppType::New());
  result.set_super_type(super_type);
  result.set_mixin_types(mixin_types);
  return result.raw();
}

RawInstance* Number::CheckAndCanonicalize(Thread* thread,
                                          const char** error_str) const {
  intptr_t cid = GetClassId();
  switch (cid) {
    case kSmiCid:
      return reinterpret_cast<RawSmi*>(raw_value());
    case kMintCid:
      return Mint::NewCanonical(Mint::Cast(*this).value());
    case kDoubleCid:
      return Double::NewCanonical(Double::Cast(*this).value());
    case kBigintCid: {
      if (this->IsCanonical()) {
        return this->raw();
      }
      Zone* zone = thread->zone();
      Isolate* isolate = thread->isolate();
      Bigint& result = Bigint::Handle(zone);
      const Class& cls = Class::Handle(zone, this->clazz());
      intptr_t index = 0;
      result ^= cls.LookupCanonicalBigint(zone, Bigint::Cast(*this), &index);
      if (!result.IsNull()) {
        return result.raw();
      }
      {
        SafepointMutexLocker ml(isolate->constant_canonicalization_mutex());
        // Retry lookup.
        {
          result ^=
              cls.LookupCanonicalBigint(zone, Bigint::Cast(*this), &index);
          if (!result.IsNull()) {
            return result.raw();
          }
        }

        // The value needs to be added to the list. Grow the list if
        // it is full.
        result ^= this->raw();
        ASSERT((isolate == Dart::vm_isolate()) || !result.InVMHeap());
        if (result.IsNew()) {
          // Create a canonical object in old space.
          result ^= Object::Clone(result, Heap::kOld);
        }
        ASSERT(result.IsOld());
        result.SetCanonical();
        cls.InsertCanonicalNumber(zone, index, result);
        return result.raw();
      }
    }
    default:
      UNREACHABLE();
  }
  return Instance::null();
}

#if defined(DEBUG)
bool Number::CheckIsCanonical(Thread* thread) const {
  intptr_t cid = GetClassId();
  intptr_t idx = 0;
  Zone* zone = thread->zone();
  const Class& cls = Class::Handle(zone, this->clazz());
  switch (cid) {
    case kSmiCid:
      return true;
    case kMintCid: {
      Mint& result = Mint::Handle(zone);
      result ^= cls.LookupCanonicalMint(zone, Mint::Cast(*this).value(), &idx);
      return (result.raw() == this->raw());
    }
    case kDoubleCid: {
      Double& dbl = Double::Handle(zone);
      dbl ^= cls.LookupCanonicalDouble(zone, Double::Cast(*this).value(), &idx);
      return (dbl.raw() == this->raw());
    }
    case kBigintCid: {
      Bigint& result = Bigint::Handle(zone);
      result ^= cls.LookupCanonicalBigint(zone, Bigint::Cast(*this), &idx);
      return (result.raw() == this->raw());
    }
    default:
      UNREACHABLE();
  }
  return false;
}
#endif  // DEBUG

const char* Number::ToCString() const {
  // Number is an interface. No instances of Number should exist.
  UNREACHABLE();
  return "Number";
}

const char* Integer::ToCString() const {
  // Integer is an interface. No instances of Integer should exist except null.
  ASSERT(IsNull());
  return "NULL Integer";
}

RawInteger* Integer::New(const String& str, Heap::Space space) {
  // We are not supposed to have integers represented as two byte strings.
  ASSERT(str.IsOneByteString());
  int64_t value;
  if (!OS::StringToInt64(str.ToCString(), &value)) {
    if (FLAG_limit_ints_to_64_bits) {
      // Out of range.
      return Integer::null();
    }
    const Bigint& big =
        Bigint::Handle(Bigint::NewFromCString(str.ToCString(), space));
    ASSERT(!big.FitsIntoSmi());
    ASSERT(!big.FitsIntoInt64());
    return big.raw();
  }
  return Integer::New(value, space);
}

RawInteger* Integer::NewCanonical(const String& str) {
  // We are not supposed to have integers represented as two byte strings.
  ASSERT(str.IsOneByteString());
  int64_t value;
  if (!OS::StringToInt64(str.ToCString(), &value)) {
    if (FLAG_limit_ints_to_64_bits) {
      // Out of range.
      return Integer::null();
    }
    const Bigint& big = Bigint::Handle(Bigint::NewCanonical(str));
    ASSERT(!big.FitsIntoSmi());
    ASSERT(!big.FitsIntoInt64());
    return big.raw();
  }
  if (Smi::IsValid(value)) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  return Mint::NewCanonical(value);
}

RawInteger* Integer::New(int64_t value, Heap::Space space) {
  const bool is_smi = Smi::IsValid(value);
  if (is_smi) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  return Mint::New(value, space);
}

RawInteger* Integer::NewFromUint64(uint64_t value, Heap::Space space) {
  if (!FLAG_limit_ints_to_64_bits &&
      (value > static_cast<uint64_t>(Mint::kMaxValue))) {
    return Bigint::NewFromUint64(value, space);
  }
  return Integer::New(static_cast<int64_t>(value), space);
}

bool Integer::IsValueInRange(uint64_t value) {
  if (FLAG_limit_ints_to_64_bits) {
    return (value <= static_cast<uint64_t>(Mint::kMaxValue));
  } else {
    return true;
  }
}

bool Integer::Equals(const Instance& other) const {
  // Integer is an abstract class.
  UNREACHABLE();
  return false;
}

bool Integer::IsZero() const {
  // Integer is an abstract class.
  UNREACHABLE();
  return false;
}

bool Integer::IsNegative() const {
  // Integer is an abstract class.
  UNREACHABLE();
  return false;
}

double Integer::AsDoubleValue() const {
  // Integer is an abstract class.
  UNREACHABLE();
  return 0.0;
}

int64_t Integer::AsInt64Value() const {
  // Integer is an abstract class.
  UNREACHABLE();
  return 0;
}

uint32_t Integer::AsTruncatedUint32Value() const {
  // Integer is an abstract class.
  UNREACHABLE();
  return 0;
}

bool Integer::FitsIntoSmi() const {
  // Integer is an abstract class.
  UNREACHABLE();
  return false;
}

int Integer::CompareWith(const Integer& other) const {
  // Integer is an abstract class.
  UNREACHABLE();
  return 0;
}

RawInteger* Integer::AsValidInteger() const {
  if (IsSmi()) return raw();
  if (IsMint()) {
    Mint& mint = Mint::Handle();
    mint ^= raw();
    if (Smi::IsValid(mint.value())) {
      return Smi::New(static_cast<intptr_t>(mint.value()));
    } else {
      return raw();
    }
  }
  if (Bigint::Cast(*this).FitsIntoInt64()) {
    const int64_t value = AsInt64Value();
    if (Smi::IsValid(value)) {
      // This cast is safe because Smi::IsValid verifies that value will fit.
      intptr_t val = static_cast<intptr_t>(value);
      return Smi::New(val);
    }
    return Mint::New(value);
  }
  return raw();
}

const char* Integer::ToHexCString(Zone* zone) const {
  ASSERT(IsSmi() || IsMint());  // Bigint has its own implementation.
  int64_t value = AsInt64Value();
  if (value < 0) {
    return OS::SCreate(zone, "-0x%" PX64, static_cast<uint64_t>(-value));
  } else {
    return OS::SCreate(zone, "0x%" PX64, static_cast<uint64_t>(value));
  }
}

RawInteger* Integer::ArithmeticOp(Token::Kind operation,
                                  const Integer& other,
                                  Heap::Space space) const {
  // In 32-bit mode, the result of any operation between two Smis will fit in a
  // 32-bit signed result, except the product of two Smis, which will be 64-bit.
  // In 64-bit mode, the result of any operation between two Smis will fit in a
  // 64-bit signed result, except the product of two Smis (see below).
  if (IsSmi() && other.IsSmi()) {
    const intptr_t left_value = Smi::Value(Smi::RawCast(raw()));
    const intptr_t right_value = Smi::Value(Smi::RawCast(other.raw()));
    switch (operation) {
      case Token::kADD:
        return Integer::New(left_value + right_value, space);
      case Token::kSUB:
        return Integer::New(left_value - right_value, space);
      case Token::kMUL: {
        if (Smi::kBits < 32) {
          // In 32-bit mode, the product of two Smis fits in a 64-bit result.
          return Integer::New(static_cast<int64_t>(left_value) *
                                  static_cast<int64_t>(right_value),
                              space);
        } else {
          ASSERT(sizeof(intptr_t) == sizeof(int64_t));
          if (FLAG_limit_ints_to_64_bits) {
            return Integer::New(
                Utils::MulWithWrapAround(left_value, right_value), space);
          } else {
            // In 64-bit mode, the product of two signed integers fits in a
            // 64-bit result if the sum of the highest bits of their absolute
            // values is smaller than 62.
            if ((Utils::HighestBit(left_value) +
                 Utils::HighestBit(right_value)) < 62) {
              return Integer::New(left_value * right_value, space);
            }
          }
        }
        // Perform a Bigint multiplication below.
        break;
      }
      case Token::kTRUNCDIV:
        return Integer::New(left_value / right_value, space);
      case Token::kMOD: {
        const intptr_t remainder = left_value % right_value;
        if (remainder < 0) {
          if (right_value < 0) {
            return Integer::New(remainder - right_value, space);
          } else {
            return Integer::New(remainder + right_value, space);
          }
        }
        return Integer::New(remainder, space);
      }
      default:
        UNIMPLEMENTED();
    }
  }
  if (!IsBigint() && !other.IsBigint()) {
    const int64_t left_value = AsInt64Value();
    const int64_t right_value = other.AsInt64Value();
    switch (operation) {
      case Token::kADD: {
        if (FLAG_limit_ints_to_64_bits) {
          return Integer::New(Utils::AddWithWrapAround(left_value, right_value),
                              space);
        } else {
          if (!Utils::WillAddOverflow(left_value, right_value)) {
            return Integer::New(left_value + right_value, space);
          }
        }
        break;
      }
      case Token::kSUB: {
        if (FLAG_limit_ints_to_64_bits) {
          return Integer::New(Utils::SubWithWrapAround(left_value, right_value),
                              space);
        } else {
          if (!Utils::WillSubOverflow(left_value, right_value)) {
            return Integer::New(left_value - right_value, space);
          }
        }
        break;
      }
      case Token::kMUL: {
        if (FLAG_limit_ints_to_64_bits) {
          return Integer::New(Utils::MulWithWrapAround(left_value, right_value),
                              space);
        } else {
          if ((Utils::HighestBit(left_value) + Utils::HighestBit(right_value)) <
              62) {
            return Integer::New(left_value * right_value, space);
          }
        }
        break;
      }
      case Token::kTRUNCDIV: {
        if ((left_value == Mint::kMinValue) && (right_value == -1)) {
          // Division special case: overflow in int64_t.
          if (FLAG_limit_ints_to_64_bits) {
            // MIN_VALUE / -1 = (MAX_VALUE + 1), which wraps around to MIN_VALUE
            return Integer::New(Mint::kMinValue, space);
          }
        } else {
          return Integer::New(left_value / right_value, space);
        }
        break;
      }
      case Token::kMOD: {
        const int64_t remainder = left_value % right_value;
        if (remainder < 0) {
          if (right_value < 0) {
            return Integer::New(remainder - right_value, space);
          } else {
            return Integer::New(remainder + right_value, space);
          }
        }
        return Integer::New(remainder, space);
      }
      default:
        UNIMPLEMENTED();
    }
  }
  ASSERT(!Bigint::IsDisabled());
  return Integer::null();  // Notify caller that a bigint operation is required.
}

static bool Are64bitOperands(const Integer& op1, const Integer& op2) {
  return !op1.IsBigint() && !op2.IsBigint();
}

RawInteger* Integer::BitOp(Token::Kind kind,
                           const Integer& other,
                           Heap::Space space) const {
  if (IsSmi() && other.IsSmi()) {
    intptr_t op1_value = Smi::Value(Smi::RawCast(raw()));
    intptr_t op2_value = Smi::Value(Smi::RawCast(other.raw()));
    intptr_t result = 0;
    switch (kind) {
      case Token::kBIT_AND:
        result = op1_value & op2_value;
        break;
      case Token::kBIT_OR:
        result = op1_value | op2_value;
        break;
      case Token::kBIT_XOR:
        result = op1_value ^ op2_value;
        break;
      default:
        UNIMPLEMENTED();
    }
    ASSERT(Smi::IsValid(result));
    return Smi::New(result);
  } else if (Are64bitOperands(*this, other)) {
    int64_t a = AsInt64Value();
    int64_t b = other.AsInt64Value();
    switch (kind) {
      case Token::kBIT_AND:
        return Integer::New(a & b, space);
      case Token::kBIT_OR:
        return Integer::New(a | b, space);
      case Token::kBIT_XOR:
        return Integer::New(a ^ b, space);
      default:
        UNIMPLEMENTED();
    }
  }
  ASSERT(!Bigint::IsDisabled());
  return Integer::null();  // Notify caller that a bigint operation is required.
}

// TODO(srdjan): Clarify handling of negative right operand in a shift op.
RawInteger* Smi::ShiftOp(Token::Kind kind,
                         const Smi& other,
                         Heap::Space space) const {
  intptr_t result = 0;
  const intptr_t left_value = Value();
  const intptr_t right_value = other.Value();
  ASSERT(right_value >= 0);
  switch (kind) {
    case Token::kSHL: {
      if ((left_value == 0) || (right_value == 0)) {
        return raw();
      }
      {  // Check for overflow.
        int cnt = Utils::BitLength(left_value);
        if (right_value > (Smi::kBits - cnt)) {
          if (FLAG_limit_ints_to_64_bits) {
            return Integer::New(
                Utils::ShiftLeftWithTruncation(left_value, right_value), space);
          } else {
            if (right_value > (Mint::kBits - cnt)) {
              return Bigint::NewFromShiftedInt64(left_value, right_value,
                                                 space);
            } else {
              int64_t left_64 = left_value;
              return Integer::New(left_64 << right_value, space);
            }
          }
        }
      }
      result = left_value << right_value;
      break;
    }
    case Token::kSHR: {
      const intptr_t shift_amount =
          (right_value >= kBitsPerWord) ? (kBitsPerWord - 1) : right_value;
      result = left_value >> shift_amount;
      break;
    }
    default:
      UNIMPLEMENTED();
  }
  ASSERT(Smi::IsValid(result));
  return Smi::New(result);
}

bool Smi::Equals(const Instance& other) const {
  if (other.IsNull() || !other.IsSmi()) {
    return false;
  }
  return (this->Value() == Smi::Cast(other).Value());
}

double Smi::AsDoubleValue() const {
  return static_cast<double>(this->Value());
}

int64_t Smi::AsInt64Value() const {
  return this->Value();
}

uint32_t Smi::AsTruncatedUint32Value() const {
  return this->Value() & 0xFFFFFFFF;
}

int Smi::CompareWith(const Integer& other) const {
  if (other.IsSmi()) {
    const Smi& other_smi = Smi::Cast(other);
    if (this->Value() < other_smi.Value()) {
      return -1;
    } else if (this->Value() > other_smi.Value()) {
      return 1;
    } else {
      return 0;
    }
  }
  ASSERT(!other.FitsIntoSmi());
  if (other.IsMint() || other.IsBigint()) {
    if (this->IsNegative() == other.IsNegative()) {
      return this->IsNegative() ? 1 : -1;
    }
    return this->IsNegative() ? -1 : 1;
  }
  UNREACHABLE();
  return 0;
}

const char* Smi::ToCString() const {
  return OS::SCreate(Thread::Current()->zone(), "%" Pd "", Value());
}

RawClass* Smi::Class() {
  return Isolate::Current()->object_store()->smi_class();
}

void Mint::set_value(int64_t value) const {
  StoreNonPointer(&raw_ptr()->value_, value);
}

RawMint* Mint::New(int64_t val, Heap::Space space) {
  // Do not allocate a Mint if Smi would do.
  ASSERT(!Smi::IsValid(val));
  ASSERT(Isolate::Current()->object_store()->mint_class() != Class::null());
  Mint& result = Mint::Handle();
  {
    RawObject* raw =
        Object::Allocate(Mint::kClassId, Mint::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(val);
  return result.raw();
}

RawMint* Mint::NewCanonical(int64_t value) {
  // Do not allocate a Mint if Smi would do.
  ASSERT(!Smi::IsValid(value));
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const Class& cls = Class::Handle(zone, isolate->object_store()->mint_class());
  Mint& canonical_value = Mint::Handle(zone);
  intptr_t index = 0;
  canonical_value ^= cls.LookupCanonicalMint(zone, value, &index);
  if (!canonical_value.IsNull()) {
    return canonical_value.raw();
  }
  {
    SafepointMutexLocker ml(isolate->constant_canonicalization_mutex());
    // Retry lookup.
    {
      canonical_value ^= cls.LookupCanonicalMint(zone, value, &index);
      if (!canonical_value.IsNull()) {
        return canonical_value.raw();
      }
    }
    canonical_value = Mint::New(value, Heap::kOld);
    canonical_value.SetCanonical();
    // The value needs to be added to the constants list. Grow the list if
    // it is full.
    cls.InsertCanonicalNumber(zone, index, canonical_value);
    return canonical_value.raw();
  }
}

bool Mint::Equals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    // Both handles point to the same raw instance.
    return true;
  }
  if (!other.IsMint() || other.IsNull()) {
    return false;
  }
  return value() == Mint::Cast(other).value();
}

double Mint::AsDoubleValue() const {
  return static_cast<double>(this->value());
}

int64_t Mint::AsInt64Value() const {
  return this->value();
}

uint32_t Mint::AsTruncatedUint32Value() const {
  return this->value() & 0xFFFFFFFF;
}

bool Mint::FitsIntoSmi() const {
  return Smi::IsValid(AsInt64Value());
}

int Mint::CompareWith(const Integer& other) const {
  ASSERT(!FitsIntoSmi());
  if (other.IsMint() || other.IsSmi()) {
    int64_t a = AsInt64Value();
    int64_t b = other.AsInt64Value();
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    } else {
      return 0;
    }
  }
  ASSERT(other.IsBigint());
  ASSERT(!Bigint::Cast(other).FitsIntoInt64());
  if (this->IsNegative() == other.IsNegative()) {
    return this->IsNegative() ? 1 : -1;
  }
  return this->IsNegative() ? -1 : 1;
}

const char* Mint::ToCString() const {
  return OS::SCreate(Thread::Current()->zone(), "%" Pd64 "", value());
}

void Double::set_value(double value) const {
  StoreNonPointer(&raw_ptr()->value_, value);
}

bool Double::BitwiseEqualsToDouble(double value) const {
  intptr_t value_offset = Double::value_offset();
  void* this_addr = reinterpret_cast<void*>(
      reinterpret_cast<uword>(this->raw_ptr()) + value_offset);
  void* other_addr = reinterpret_cast<void*>(&value);
  return (memcmp(this_addr, other_addr, sizeof(value)) == 0);
}

bool Double::OperatorEquals(const Instance& other) const {
  if (this->IsNull() || other.IsNull()) {
    return (this->IsNull() && other.IsNull());
  }
  if (!other.IsDouble()) {
    return false;
  }
  return this->value() == Double::Cast(other).value();
}

bool Double::CanonicalizeEquals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    return true;  // "===".
  }
  if (other.IsNull() || !other.IsDouble()) {
    return false;
  }
  return BitwiseEqualsToDouble(Double::Cast(other).value());
}

RawDouble* Double::New(double d, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->double_class() != Class::null());
  Double& result = Double::Handle();
  {
    RawObject* raw =
        Object::Allocate(Double::kClassId, Double::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(d);
  return result.raw();
}

RawDouble* Double::New(const String& str, Heap::Space space) {
  double double_value;
  if (!CStringToDouble(str.ToCString(), str.Length(), &double_value)) {
    return Double::Handle().raw();
  }
  return New(double_value, space);
}

RawDouble* Double::NewCanonical(double value) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const Class& cls = Class::Handle(isolate->object_store()->double_class());
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Double& canonical_value = Double::Handle(zone);
  intptr_t index = 0;

  canonical_value ^= cls.LookupCanonicalDouble(zone, value, &index);
  if (!canonical_value.IsNull()) {
    return canonical_value.raw();
  }
  {
    SafepointMutexLocker ml(isolate->constant_canonicalization_mutex());
    // Retry lookup.
    {
      canonical_value ^= cls.LookupCanonicalDouble(zone, value, &index);
      if (!canonical_value.IsNull()) {
        return canonical_value.raw();
      }
    }
    canonical_value = Double::New(value, Heap::kOld);
    canonical_value.SetCanonical();
    // The value needs to be added to the constants list. Grow the list if
    // it is full.
    cls.InsertCanonicalNumber(zone, index, canonical_value);
    return canonical_value.raw();
  }
}

RawDouble* Double::NewCanonical(const String& str) {
  double double_value;
  if (!CStringToDouble(str.ToCString(), str.Length(), &double_value)) {
    return Double::Handle().raw();
  }
  return NewCanonical(double_value);
}

RawString* Number::ToString(Heap::Space space) const {
  // Refactoring can avoid Zone::Alloc and strlen, but gains are insignificant.
  const char* cstr = ToCString();
  intptr_t len = strlen(cstr);
// Resulting string is ASCII ...
#ifdef DEBUG
  for (intptr_t i = 0; i < len; ++i) {
    ASSERT(static_cast<uint8_t>(cstr[i]) < 128);
  }
#endif  // DEBUG
  // ... which is a subset of Latin-1.
  return String::FromLatin1(reinterpret_cast<const uint8_t*>(cstr), len, space);
}

const char* Double::ToCString() const {
  if (isnan(value())) {
    return "NaN";
  }
  if (isinf(value())) {
    return value() < 0 ? "-Infinity" : "Infinity";
  }
  const int kBufferSize = 128;
  char* buffer = Thread::Current()->zone()->Alloc<char>(kBufferSize);
  buffer[kBufferSize - 1] = '\0';
  DoubleToCString(value(), buffer, kBufferSize);
  return buffer;
}

bool Bigint::Neg() const {
  return Bool::Handle(neg()).value();
}

void Bigint::SetNeg(bool value) const {
  StorePointer(&raw_ptr()->neg_, Bool::Get(value).raw());
}

intptr_t Bigint::Used() const {
  return Smi::Value(used());
}

void Bigint::SetUsed(intptr_t value) const {
  StoreSmi(&raw_ptr()->used_, Smi::New(value));
}

uint32_t Bigint::DigitAt(intptr_t index) const {
  const TypedData& typed_data = TypedData::Handle(digits());
  return typed_data.GetUint32(index << 2);
}

void Bigint::set_digits(const TypedData& value) const {
  // The VM expects digits_ to be a Uint32List (not null).
  ASSERT(!value.IsNull() && (value.GetClassId() == kTypedDataUint32ArrayCid));
  StorePointer(&raw_ptr()->digits_, value.raw());
}

RawTypedData* Bigint::NewDigits(intptr_t length, Heap::Space space) {
  ASSERT(length > 0);
  // Account for leading zero for 64-bit processing.
  return TypedData::New(kTypedDataUint32ArrayCid, length + 1, space);
}

uint32_t Bigint::DigitAt(const TypedData& digits, intptr_t index) {
  return digits.GetUint32(index << 2);
}

void Bigint::SetDigitAt(const TypedData& digits,
                        intptr_t index,
                        uint32_t value) {
  digits.SetUint32(index << 2, value);
}

bool Bigint::Equals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    // Both handles point to the same raw instance.
    return true;
  }

  if (!other.IsBigint() || other.IsNull()) {
    return false;
  }

  const Bigint& other_bgi = Bigint::Cast(other);

  if (this->Neg() != other_bgi.Neg()) {
    return false;
  }

  const intptr_t used = this->Used();
  if (used != other_bgi.Used()) {
    return false;
  }

  for (intptr_t i = 0; i < used; i++) {
    if (this->DigitAt(i) != other_bgi.DigitAt(i)) {
      return false;
    }
  }
  return true;
}

bool Bigint::CheckAndCanonicalizeFields(Thread* thread,
                                        const char** error_str) const {
  Zone* zone = thread->zone();
  // Bool field neg should always be canonical.
  ASSERT(Bool::Handle(zone, neg()).IsCanonical());
  // Smi field used is canonical by definition.
  if (Used() > 0) {
    // Canonicalize TypedData field digits.
    TypedData& digits_ = TypedData::Handle(zone, digits());
    digits_ ^= digits_.CheckAndCanonicalize(thread, NULL);
    ASSERT(!digits_.IsNull());
    set_digits(digits_);
  } else {
    ASSERT(digits() == TypedData::EmptyUint32Array(Thread::Current()));
  }
  return true;
}

RawBigint* Bigint::New(Heap::Space space) {
  ASSERT(!Bigint::IsDisabled());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->object_store()->bigint_class() != Class::null());
  Bigint& result = Bigint::Handle(zone);
  {
    RawObject* raw =
        Object::Allocate(Bigint::kClassId, Bigint::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.SetNeg(false);
  result.SetUsed(0);
  result.set_digits(
      TypedData::Handle(zone, TypedData::EmptyUint32Array(thread)));
  return result.raw();
}

RawBigint* Bigint::New(bool neg,
                       intptr_t used,
                       const TypedData& digits,
                       Heap::Space space) {
  ASSERT(!Bigint::IsDisabled());
  ASSERT((used == 0) ||
         (!digits.IsNull() && (digits.Length() >= (used + (used & 1)))));
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->object_store()->bigint_class() != Class::null());
  Bigint& result = Bigint::Handle(zone);
  {
    RawObject* raw =
        Object::Allocate(Bigint::kClassId, Bigint::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  // Clamp the digits array.
  while ((used > 0) && (digits.GetUint32((used - 1) << 2) == 0)) {
    --used;
  }
  if (used > 0) {
    if (((used & 1) != 0) && (digits.GetUint32(used << 2) != 0)) {
      // Set leading zero for 64-bit processing of digit pairs if not set.
      // The check above ensures that we avoid a write access to a possibly
      // reused digits array that could be marked read only.
      digits.SetUint32(used << 2, 0);
    }
    result.set_digits(digits);
  } else {
    neg = false;
    result.set_digits(
        TypedData::Handle(zone, TypedData::EmptyUint32Array(thread)));
  }
  result.SetNeg(neg);
  result.SetUsed(used);
  return result.raw();
}

RawBigint* Bigint::NewFromInt64(int64_t value, Heap::Space space) {
  ASSERT(!Bigint::IsDisabled());
  const TypedData& digits = TypedData::Handle(NewDigits(2, space));
  bool neg;
  uint64_t abs_value;
  if (value < 0) {
    neg = true;
    abs_value = -value;
  } else {
    neg = false;
    abs_value = value;
  }
  SetDigitAt(digits, 0, static_cast<uint32_t>(abs_value));
  SetDigitAt(digits, 1, static_cast<uint32_t>(abs_value >> 32));
  return New(neg, 2, digits, space);
}

RawBigint* Bigint::NewFromUint64(uint64_t value, Heap::Space space) {
  ASSERT(!Bigint::IsDisabled());
  const TypedData& digits = TypedData::Handle(NewDigits(2, space));
  SetDigitAt(digits, 0, static_cast<uint32_t>(value));
  SetDigitAt(digits, 1, static_cast<uint32_t>(value >> 32));
  return New(false, 2, digits, space);
}

RawBigint* Bigint::NewFromShiftedInt64(int64_t value,
                                       intptr_t shift,
                                       Heap::Space space) {
  ASSERT(!Bigint::IsDisabled());
  ASSERT(kBitsPerDigit == 32);
  ASSERT(shift >= 0);
  const intptr_t digit_shift = shift / kBitsPerDigit;
  const intptr_t bit_shift = shift % kBitsPerDigit;
  const intptr_t used = 3 + digit_shift;
  const TypedData& digits = TypedData::Handle(NewDigits(used, space));
  bool neg;
  uint64_t abs_value;
  if (value < 0) {
    neg = true;
    abs_value = -value;
  } else {
    neg = false;
    abs_value = value;
  }
  for (intptr_t i = 0; i < digit_shift; i++) {
    SetDigitAt(digits, i, 0);
  }
  SetDigitAt(digits, 0 + digit_shift,
             static_cast<uint32_t>(abs_value << bit_shift));
  SetDigitAt(digits, 1 + digit_shift,
             static_cast<uint32_t>(abs_value >> (32 - bit_shift)));
  SetDigitAt(digits, 2 + digit_shift,
             (bit_shift == 0)
                 ? 0
                 : static_cast<uint32_t>(abs_value >> (64 - bit_shift)));
  return New(neg, used, digits, space);
}

RawBigint* Bigint::NewFromCString(const char* str, Heap::Space space) {
  ASSERT(!Bigint::IsDisabled());
  ASSERT(str != NULL);
  bool neg = false;
  TypedData& digits = TypedData::Handle();
  if (str[0] == '-') {
    ASSERT(str[1] != '-');
    neg = true;
    str++;
  }
  intptr_t used;
  const intptr_t str_length = strlen(str);
  if ((str_length >= 2) && (str[0] == '0') &&
      ((str[1] == 'x') || (str[1] == 'X'))) {
    digits = NewDigitsFromHexCString(&str[2], &used, space);
  } else {
    digits = NewDigitsFromDecCString(str, &used, space);
  }
  return New(neg, used, digits, space);
}

RawBigint* Bigint::NewCanonical(const String& str) {
  ASSERT(!Bigint::IsDisabled());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const Bigint& value =
      Bigint::Handle(zone, Bigint::NewFromCString(str.ToCString(), Heap::kOld));
  const Class& cls =
      Class::Handle(zone, isolate->object_store()->bigint_class());
  intptr_t index = 0;
  Bigint& canonical_value = Bigint::Handle(zone);
  canonical_value ^= cls.LookupCanonicalBigint(zone, value, &index);
  if (!canonical_value.IsNull()) {
    return canonical_value.raw();
  }
  {
    SafepointMutexLocker ml(isolate->constant_canonicalization_mutex());
    // Retry lookup.
    {
      canonical_value ^= cls.LookupCanonicalBigint(zone, value, &index);
      if (!canonical_value.IsNull()) {
        return canonical_value.raw();
      }
    }
    value.SetCanonical();
    // The value needs to be added to the constants list. Grow the list if
    // it is full.
    cls.InsertCanonicalNumber(zone, index, value);
    return value.raw();
  }
}

RawTypedData* Bigint::NewDigitsFromHexCString(const char* str,
                                              intptr_t* used,
                                              Heap::Space space) {
  const int kBitsPerHexDigit = 4;
  const int kHexDigitsPerDigit = 8;
  const int kBitsPerDigit = kBitsPerHexDigit * kHexDigitsPerDigit;
  intptr_t hex_i = strlen(str);  // Terminating byte excluded.
  if ((hex_i <= 0) || (hex_i >= kMaxInt32)) {
    FATAL("Fatal error parsing hex bigint: string too long or empty");
  }
  const intptr_t length = (hex_i + kHexDigitsPerDigit - 1) / kHexDigitsPerDigit;
  const TypedData& digits = TypedData::Handle(NewDigits(length, space));
  intptr_t used_ = 0;
  uint32_t digit = 0;
  intptr_t bit_i = 0;
  while (--hex_i >= 0) {
    digit += Utils::HexDigitToInt(str[hex_i]) << bit_i;
    bit_i += kBitsPerHexDigit;
    if (bit_i == kBitsPerDigit) {
      bit_i = 0;
      SetDigitAt(digits, used_++, digit);
      digit = 0;
    }
  }
  if (bit_i != 0) {
    SetDigitAt(digits, used_++, digit);
  }
  *used = used_;
  return digits.raw();
}

RawTypedData* Bigint::NewDigitsFromDecCString(const char* str,
                                              intptr_t* used,
                                              Heap::Space space) {
  // Read 9 digits a time. 10^9 < 2^32.
  const int kDecDigitsPerIteration = 9;
  const uint32_t kTenMultiplier = 1000000000;
  ASSERT(kBitsPerDigit == 32);
  const intptr_t str_length = strlen(str);
  if ((str_length <= 0) || (str_length >= kMaxInt32)) {
    FATAL("Fatal error parsing dec bigint: string too long or empty");
  }
  // One decimal digit takes log2(10) bits, i.e. ~3.32192809489 bits.
  // That is a theoretical limit for large numbers.
  // The extra 5 digits allocated take care of variations.
  const int64_t kLog10Dividend = 33219281;
  const int64_t kLog10Divisor = 10000000;
  const intptr_t length =
      (kLog10Dividend * str_length) / (kLog10Divisor * kBitsPerDigit) + 5;
  const TypedData& digits = TypedData::Handle(NewDigits(length, space));
  // Read first digit separately. This avoids a multiplication and addition.
  // The first digit might also not have kDecDigitsPerIteration decimal digits.
  const intptr_t lsdigit_length = str_length % kDecDigitsPerIteration;
  uint32_t digit = 0;
  intptr_t str_pos = 0;
  for (intptr_t i = 0; i < lsdigit_length; i++) {
    char c = str[str_pos++];
    ASSERT(('0' <= c) && (c <= '9'));
    digit = digit * 10 + c - '0';
  }
  SetDigitAt(digits, 0, digit);
  intptr_t used_ = 1;
  // Read kDecDigitsPerIteration at a time, and store it in 'digit'.
  // Then multiply the temporary result by 10^kDecDigitsPerIteration and add
  // 'digit' to the new result.
  while (str_pos < str_length - 1) {
    digit = 0;
    for (intptr_t i = 0; i < kDecDigitsPerIteration; i++) {
      char c = str[str_pos++];
      ASSERT(('0' <= c) && (c <= '9'));
      digit = digit * 10 + c - '0';
    }
    // Multiply result with kTenMultiplier and add digit.
    for (intptr_t i = 0; i < used_; i++) {
      uint64_t product =
          (static_cast<uint64_t>(DigitAt(digits, i)) * kTenMultiplier) + digit;
      SetDigitAt(digits, i, static_cast<uint32_t>(product & kDigitMask));
      digit = static_cast<uint32_t>(product >> kBitsPerDigit);
    }
    SetDigitAt(digits, used_++, digit);
  }
  *used = used_;
  return digits.raw();
}

static double Uint64ToDouble(uint64_t x) {
#if _WIN64
  // For static_cast<double>(x) MSVC x64 generates
  //
  //    cvtsi2sd xmm0, rax
  //    test  rax, rax
  //    jns done
  //    addsd xmm0, static_cast<double>(2^64)
  //  done:
  //
  // while GCC -m64 generates
  //
  //    test rax, rax
  //    js negative
  //    cvtsi2sd xmm0, rax
  //    jmp done
  //  negative:
  //    mov rdx, rax
  //    shr rdx, 1
  //    and eax, 0x1
  //    or rdx, rax
  //    cvtsi2sd xmm0, rdx
  //    addsd xmm0, xmm0
  //  done:
  //
  // which results in a different rounding.
  //
  // For consistency between platforms fallback to GCC style conversion
  // on Win64.
  //
  const int64_t y = static_cast<int64_t>(x);
  if (y > 0) {
    return static_cast<double>(y);
  } else {
    const double half =
        static_cast<double>(static_cast<int64_t>(x >> 1) | (y & 1));
    return half + half;
  }
#else
  return static_cast<double>(x);
#endif
}

double Bigint::AsDoubleValue() const {
  ASSERT(kBitsPerDigit == 32);
  const intptr_t used = Used();
  if (used == 0) {
    return 0.0;
  }
  if (used <= 2) {
    const uint64_t digit1 = (used > 1) ? DigitAt(1) : 0;
    const uint64_t abs_value = (digit1 << 32) + DigitAt(0);
    const double abs_double_value = Uint64ToDouble(abs_value);
    return Neg() ? -abs_double_value : abs_double_value;
  }

  static const int kPhysicalSignificandSize = 52;
  // The significand size has an additional hidden bit.
  static const int kSignificandSize = kPhysicalSignificandSize + 1;
  static const int kExponentBias = 0x3FF + kPhysicalSignificandSize;
  static const int kMaxExponent = 0x7FF - kExponentBias;
  static const uint64_t kOne64 = 1;
  static const uint64_t kInfinityBits =
      DART_2PART_UINT64_C(0x7FF00000, 00000000);

  // A double is composed of an exponent e and a significand s. Its value equals
  // s * 2^e. The significand has 53 bits of which the first one must always be
  // 1 (at least for then numbers we are working with here) and is therefore
  // omitted. The physical size of the significand is thus 52 bits.
  // The exponent has 11 bits and is biased by 0x3FF + 52. For example an
  // exponent e = 10 is written as 0x3FF + 52 + 10 (in the 11 bits that are
  // reserved for the exponent).
  // When converting the given bignum to a double we have to pay attention to
  // the rounding. In particular we have to decide which double to pick if an
  // input lies exactly between two doubles. As usual with double operations
  // we pick the double with an even significand in such cases.
  //
  // General approach of this algorithm: Get 54 bits (one more than the
  // significand size) of the bigint. If the last bit is then 1, then (without
  // knowledge of the remaining bits) we could have a half-way number.
  // If the second-to-last bit is odd then we know that we have to round up:
  // if the remaining bits are not zero then the input lies closer to the higher
  // double. If the remaining bits are zero then we have a half-way case and
  // we need to round up too (rounding to the even double).
  // If the second-to-last bit is even then we need to look at the remaining
  // bits to determine if any of them is not zero. If that's the case then the
  // number lies closer to the next-higher double. Otherwise we round the
  // half-way case down to even.

  if (((used - 1) * kBitsPerDigit) > (kMaxExponent + kSignificandSize)) {
    // Does not fit into a double.
    const double infinity = bit_cast<double>(kInfinityBits);
    return Neg() ? -infinity : infinity;
  }

  intptr_t digit_index = used - 1;
  // In order to round correctly we need to look at half-way cases. Therefore we
  // get kSignificandSize + 1 bits. If the last bit is 1 then we have to look
  // at the remaining bits to know if we have to round up.
  int needed_bits = kSignificandSize + 1;
  ASSERT((kBitsPerDigit < needed_bits) && (2 * kBitsPerDigit >= needed_bits));
  bool discarded_bits_were_zero = true;

  const uint32_t firstDigit = DigitAt(digit_index--);
  ASSERT(firstDigit > 0);
  uint64_t twice_significand_floor = firstDigit;
  intptr_t twice_significant_exponent = (digit_index + 1) * kBitsPerDigit;
  needed_bits -= Utils::HighestBit(firstDigit) + 1;

  if (needed_bits >= kBitsPerDigit) {
    twice_significand_floor <<= kBitsPerDigit;
    twice_significand_floor |= DigitAt(digit_index--);
    twice_significant_exponent -= kBitsPerDigit;
    needed_bits -= kBitsPerDigit;
  }
  if (needed_bits > 0) {
    ASSERT(needed_bits <= kBitsPerDigit);
    uint32_t digit = DigitAt(digit_index--);
    int discarded_bits_count = kBitsPerDigit - needed_bits;
    twice_significand_floor <<= needed_bits;
    twice_significand_floor |= digit >> discarded_bits_count;
    twice_significant_exponent -= needed_bits;
    uint64_t discarded_bits_mask = (kOne64 << discarded_bits_count) - 1;
    discarded_bits_were_zero = ((digit & discarded_bits_mask) == 0);
  }
  ASSERT((twice_significand_floor >> kSignificandSize) == 1);

  // We might need to round up the significand later.
  uint64_t significand = twice_significand_floor >> 1;
  const intptr_t exponent = twice_significant_exponent + 1;

  if (exponent >= kMaxExponent) {
    // Infinity.
    // Does not fit into a double.
    const double infinity = bit_cast<double>(kInfinityBits);
    return Neg() ? -infinity : infinity;
  }

  if ((twice_significand_floor & 1) == 1) {
    bool round_up = false;

    if ((significand & 1) != 0 || !discarded_bits_were_zero) {
      // Even if the remaining bits are zero we still need to round up since we
      // want to round to even for half-way cases.
      round_up = true;
    } else {
      // Could be a half-way case. See if the remaining bits are non-zero.
      for (intptr_t i = 0; i <= digit_index; i++) {
        if (DigitAt(i) != 0) {
          round_up = true;
          break;
        }
      }
    }

    if (round_up) {
      significand++;
      // It might be that we just went from 53 bits to 54 bits.
      // Example: After adding 1 to 1FFF..FF (with 53 bits set to 1) we have
      // 2000..00 (= 2 ^ 54). When adding the exponent and significand together
      // this will increase the exponent by 1 which is exactly what we want.
    }
  }

  ASSERT(((significand >> (kSignificandSize - 1)) == 1) ||
         (significand == (kOne64 << kSignificandSize)));
  // The significand still has the hidden bit. We simply decrement the biased
  // exponent by one instead of playing around with the significand.
  const uint64_t biased_exponent = exponent + kExponentBias - 1;
  // Note that we must use the plus operator instead of bit-or.
  const uint64_t double_bits =
      (biased_exponent << kPhysicalSignificandSize) + significand;

  const double value = bit_cast<double>(double_bits);
  return Neg() ? -value : value;
}

bool Bigint::FitsIntoSmi() const {
  return FitsIntoInt64() && Smi::IsValid(AsInt64Value());
}

bool Bigint::FitsIntoInt64() const {
  ASSERT(Bigint::kBitsPerDigit == 32);
  const intptr_t used = Used();
  if (used < 2) return true;
  if (used > 2) return false;
  const uint64_t digit1 = DigitAt(1);
  const uint64_t value = (digit1 << 32) + DigitAt(0);
  uint64_t limit = Mint::kMaxValue;
  if (Neg()) {
    limit++;
  }
  return value <= limit;
}

int64_t Bigint::AsTruncatedInt64Value() const {
  const intptr_t used = Used();
  if (used == 0) return 0;
  const int64_t digit1 = (used > 1) ? DigitAt(1) : 0;
  const int64_t value = (digit1 << 32) + DigitAt(0);
  return Neg() ? -value : value;
}

int64_t Bigint::AsInt64Value() const {
  ASSERT(FitsIntoInt64());
  return AsTruncatedInt64Value();
}

bool Bigint::FitsIntoUint64() const {
  ASSERT(Bigint::kBitsPerDigit == 32);
  return !Neg() && (Used() <= 2);
}

uint64_t Bigint::AsUint64Value() const {
  ASSERT(FitsIntoUint64());
  const intptr_t used = Used();
  if (used == 0) return 0;
  const uint64_t digit1 = (used > 1) ? DigitAt(1) : 0;
  return (digit1 << 32) + DigitAt(0);
}

uint32_t Bigint::AsTruncatedUint32Value() const {
  // Note: the previous implementation of Bigint returned the absolute value
  // truncated to 32 bits, which is not consistent with Smi and Mint behavior.
  ASSERT(Bigint::kBitsPerDigit == 32);
  const intptr_t used = Used();
  if (used == 0) return 0;
  const uint32_t digit0 = DigitAt(0);
  return Neg() ? static_cast<uint32_t>(-static_cast<int32_t>(digit0)) : digit0;
}

// For positive values: Smi < Mint < Bigint.
int Bigint::CompareWith(const Integer& other) const {
  ASSERT(!FitsIntoSmi());
  ASSERT(!FitsIntoInt64());
  if (other.IsBigint() && (IsNegative() == other.IsNegative())) {
    const Bigint& other_bgi = Bigint::Cast(other);
    int64_t result = Used() - other_bgi.Used();
    if (result == 0) {
      for (intptr_t i = Used(); --i >= 0;) {
        result = DigitAt(i);
        result -= other_bgi.DigitAt(i);
        if (result != 0) break;
      }
    }
    if (IsNegative()) {
      result = -result;
    }
    return result > 0 ? 1 : result < 0 ? -1 : 0;
  }
  return this->IsNegative() ? -1 : 1;
}

const char* Bigint::ToDecCString(Zone* zone) const {
  // log10(2) ~= 0.30102999566398114.
  const intptr_t kLog2Dividend = 30103;
  const intptr_t kLog2Divisor = 100000;
  intptr_t used = Used();
  const intptr_t kMaxUsed =
      kIntptrMax / kBitsPerDigit / kLog2Dividend * kLog2Divisor;
  if (used > kMaxUsed) {
    Exceptions::ThrowOOM();
    UNREACHABLE();
  }
  const int64_t bit_len = used * kBitsPerDigit;
  const int64_t dec_len = (bit_len * kLog2Dividend / kLog2Divisor) + 1;
  // Add one byte for the minus sign and for the trailing \0 character.
  const int64_t len = (Neg() ? 1 : 0) + dec_len + 1;
  char* chars = zone->Alloc<char>(len);
  intptr_t pos = 0;
  const intptr_t kDivisor = 100000000;
  const intptr_t kDigits = 8;
  ASSERT(pow(10.0, 1.0 * kDigits) == kDivisor);
  ASSERT(kDivisor < kDigitBase);
  ASSERT(Smi::IsValid(kDivisor));
  // Allocate a copy of the digits.
  uint32_t* rest_digits = zone->Alloc<uint32_t>(used);
  for (intptr_t i = 0; i < used; i++) {
    rest_digits[i] = DigitAt(i);
  }
  if (used == 0) {
    chars[pos++] = '0';
  }
  while (used > 0) {
    uint32_t remainder = 0;
    for (intptr_t i = used - 1; i >= 0; i--) {
      uint64_t dividend =
          (static_cast<uint64_t>(remainder) << kBitsPerDigit) + rest_digits[i];
      uint32_t quotient = static_cast<uint32_t>(dividend / kDivisor);
      remainder = static_cast<uint32_t>(
          dividend - static_cast<uint64_t>(quotient) * kDivisor);
      rest_digits[i] = quotient;
    }
    // Clamp rest_digits.
    while ((used > 0) && (rest_digits[used - 1] == 0)) {
      used--;
    }
    for (intptr_t i = 0; i < kDigits; i++) {
      chars[pos++] = '0' + (remainder % 10);
      remainder /= 10;
    }
    ASSERT(remainder == 0);
  }
  // Remove leading zeros.
  while ((pos > 1) && (chars[pos - 1] == '0')) {
    pos--;
  }
  if (Neg()) {
    chars[pos++] = '-';
  }
  // Reverse the string.
  intptr_t i = 0;
  intptr_t j = pos - 1;
  while (i < j) {
    char tmp = chars[i];
    chars[i] = chars[j];
    chars[j] = tmp;
    i++;
    j--;
  }
  chars[pos] = '\0';
  return chars;
}

const char* Bigint::ToHexCString(Zone* zone) const {
  const intptr_t used = Used();
  if (used == 0) {
    const char* zero = "0x0";
    const size_t len = strlen(zero) + 1;
    char* chars = zone->Alloc<char>(len);
    strncpy(chars, zero, len);
    return chars;
  }
  const int kBitsPerHexDigit = 4;
  const int kHexDigitsPerDigit = 8;
  const intptr_t kMaxUsed = (kIntptrMax - 4) / kHexDigitsPerDigit;
  if (used > kMaxUsed) {
    Exceptions::ThrowOOM();
    UNREACHABLE();
  }
  intptr_t hex_len = (used - 1) * kHexDigitsPerDigit;
  // The most significant digit may use fewer than kHexDigitsPerDigit digits.
  uint32_t digit = DigitAt(used - 1);
  ASSERT(digit != 0);  // Value must be clamped.
  while (digit != 0) {
    hex_len++;
    digit >>= kBitsPerHexDigit;
  }
  // Add bytes for '0x', for the minus sign, and for the trailing \0 character.
  const int32_t len = (Neg() ? 1 : 0) + 2 + hex_len + 1;
  char* chars = zone->Alloc<char>(len);
  intptr_t pos = len;
  chars[--pos] = '\0';
  for (intptr_t i = 0; i < (used - 1); i++) {
    digit = DigitAt(i);
    for (intptr_t j = 0; j < kHexDigitsPerDigit; j++) {
      chars[--pos] = Utils::IntToHexDigit(digit & 0xf);
      digit >>= kBitsPerHexDigit;
    }
  }
  digit = DigitAt(used - 1);
  while (digit != 0) {
    chars[--pos] = Utils::IntToHexDigit(digit & 0xf);
    digit >>= kBitsPerHexDigit;
  }
  chars[--pos] = 'x';
  chars[--pos] = '0';
  if (Neg()) {
    chars[--pos] = '-';
  }
  ASSERT(pos == 0);
  return chars;
}

const char* Bigint::ToCString() const {
  return ToDecCString(Thread::Current()->zone());
}

// Synchronize with implementation in compiler (intrinsifier).
class StringHasher : ValueObject {
 public:
  StringHasher() : hash_(0) {}
  void Add(int32_t ch) { hash_ = CombineHashes(hash_, ch); }
  void Add(const String& str, intptr_t begin_index, intptr_t len);

  // Return a non-zero hash of at most 'bits' bits.
  intptr_t Finalize(int bits) {
    ASSERT(1 <= bits && bits <= (kBitsPerWord - 1));
    hash_ = FinalizeHash(hash_, bits);
    ASSERT(hash_ <= static_cast<uint32_t>(kMaxInt32));
    return hash_;
  }

 private:
  uint32_t hash_;
};

void StringHasher::Add(const String& str, intptr_t begin_index, intptr_t len) {
  ASSERT(begin_index >= 0);
  ASSERT(len >= 0);
  ASSERT((begin_index + len) <= str.Length());
  if (len == 0) {
    return;
  }
  if (str.IsOneByteString()) {
    NoSafepointScope no_safepoint;
    uint8_t* str_addr = OneByteString::CharAddr(str, begin_index);
    for (intptr_t i = 0; i < len; i++) {
      Add(*str_addr);
      str_addr++;
    }
  } else {
    String::CodePointIterator it(str, begin_index, len);
    while (it.Next()) {
      Add(it.Current());
    }
  }
}

intptr_t String::Hash(const String& str, intptr_t begin_index, intptr_t len) {
  StringHasher hasher;
  hasher.Add(str, begin_index, len);
  return hasher.Finalize(kHashBits);
}

intptr_t String::HashConcat(const String& str1, const String& str2) {
  intptr_t len1 = str1.Length();
  // Since String::Hash works at the code point (rune) level, a surrogate pair
  // that crosses the boundary between str1 and str2 must be composed.
  if (str1.IsTwoByteString() && Utf16::IsLeadSurrogate(str1.CharAt(len1 - 1))) {
    const String& temp = String::Handle(String::Concat(str1, str2));
    return temp.Hash();
  } else {
    StringHasher hasher;
    hasher.Add(str1, 0, len1);
    hasher.Add(str2, 0, str2.Length());
    return hasher.Finalize(kHashBits);
  }
}

template <typename T>
static intptr_t HashImpl(const T* characters, intptr_t len) {
  ASSERT(len >= 0);
  StringHasher hasher;
  for (intptr_t i = 0; i < len; i++) {
    hasher.Add(characters[i]);
  }
  return hasher.Finalize(String::kHashBits);
}

intptr_t String::Hash(RawString* raw) {
  StringHasher hasher;
  uword length = Smi::Value(raw->ptr()->length_);
  if (raw->IsOneByteString() || raw->IsExternalOneByteString()) {
    const uint8_t* data;
    if (raw->IsOneByteString()) {
      data = reinterpret_cast<RawOneByteString*>(raw)->ptr()->data();
    } else {
      ASSERT(raw->IsExternalOneByteString());
      RawExternalOneByteString* str =
          reinterpret_cast<RawExternalOneByteString*>(raw);
      data = str->ptr()->external_data_->data();
    }
    return String::Hash(data, length);
  } else {
    const uint16_t* data;
    if (raw->IsTwoByteString()) {
      data = reinterpret_cast<RawTwoByteString*>(raw)->ptr()->data();
    } else {
      ASSERT(raw->IsExternalTwoByteString());
      RawExternalTwoByteString* str =
          reinterpret_cast<RawExternalTwoByteString*>(raw);
      data = str->ptr()->external_data_->data();
    }
    return String::Hash(data, length);
  }
}

intptr_t String::Hash(const char* characters, intptr_t len) {
  return HashImpl(characters, len);
}

intptr_t String::Hash(const uint8_t* characters, intptr_t len) {
  return HashImpl(characters, len);
}

intptr_t String::Hash(const uint16_t* characters, intptr_t len) {
  StringHasher hasher;
  intptr_t i = 0;
  while (i < len) {
    hasher.Add(Utf16::Next(characters, &i, len));
  }
  return hasher.Finalize(kHashBits);
}

intptr_t String::Hash(const int32_t* characters, intptr_t len) {
  return HashImpl(characters, len);
}

uint16_t String::CharAt(intptr_t index) const {
  intptr_t class_id = raw()->GetClassId();
  ASSERT(RawObject::IsStringClassId(class_id));
  if (class_id == kOneByteStringCid) {
    return OneByteString::CharAt(*this, index);
  }
  if (class_id == kTwoByteStringCid) {
    return TwoByteString::CharAt(*this, index);
  }
  if (class_id == kExternalOneByteStringCid) {
    return ExternalOneByteString::CharAt(*this, index);
  }
  ASSERT(class_id == kExternalTwoByteStringCid);
  return ExternalTwoByteString::CharAt(*this, index);
}

Scanner::CharAtFunc String::CharAtFunc() const {
  intptr_t class_id = raw()->GetClassId();
  ASSERT(RawObject::IsStringClassId(class_id));
  if (class_id == kOneByteStringCid) {
    return &OneByteString::CharAt;
  }
  if (class_id == kTwoByteStringCid) {
    return &TwoByteString::CharAt;
  }
  if (class_id == kExternalOneByteStringCid) {
    return &ExternalOneByteString::CharAt;
  }
  ASSERT(class_id == kExternalTwoByteStringCid);
  return &ExternalTwoByteString::CharAt;
}

intptr_t String::CharSize() const {
  intptr_t class_id = raw()->GetClassId();
  if (class_id == kOneByteStringCid || class_id == kExternalOneByteStringCid) {
    return kOneByteChar;
  }
  ASSERT(class_id == kTwoByteStringCid ||
         class_id == kExternalTwoByteStringCid);
  return kTwoByteChar;
}

void* String::GetPeer() const {
  intptr_t class_id = raw()->GetClassId();
  if (class_id == kExternalOneByteStringCid) {
    return ExternalOneByteString::GetPeer(*this);
  }
  ASSERT(class_id == kExternalTwoByteStringCid);
  return ExternalTwoByteString::GetPeer(*this);
}

bool String::Equals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    // Both handles point to the same raw instance.
    return true;
  }

  if (!other.IsString()) {
    return false;
  }

  const String& other_string = String::Cast(other);
  return Equals(other_string);
}

bool String::Equals(const String& str,
                    intptr_t begin_index,
                    intptr_t len) const {
  ASSERT(begin_index >= 0);
  ASSERT((begin_index == 0) || (begin_index < str.Length()));
  ASSERT(len >= 0);
  ASSERT(len <= str.Length());
  if (len != this->Length()) {
    return false;  // Lengths don't match.
  }

  Scanner::CharAtFunc this_char_at_func = this->CharAtFunc();
  Scanner::CharAtFunc str_char_at_func = str.CharAtFunc();
  for (intptr_t i = 0; i < len; i++) {
    if (this_char_at_func(*this, i) != str_char_at_func(str, begin_index + i)) {
      return false;
    }
  }

  return true;
}

bool String::Equals(const char* cstr) const {
  ASSERT(cstr != NULL);
  CodePointIterator it(*this);
  intptr_t len = strlen(cstr);
  while (it.Next()) {
    if (*cstr == '\0') {
      // Lengths don't match.
      return false;
    }
    int32_t ch;
    intptr_t consumed =
        Utf8::Decode(reinterpret_cast<const uint8_t*>(cstr), len, &ch);
    if (consumed == 0 || it.Current() != ch) {
      return false;
    }
    cstr += consumed;
    len -= consumed;
  }
  return *cstr == '\0';
}

bool String::Equals(const uint8_t* latin1_array, intptr_t len) const {
  if (len != this->Length()) {
    // Lengths don't match.
    return false;
  }

  for (intptr_t i = 0; i < len; i++) {
    if (this->CharAt(i) != latin1_array[i]) {
      return false;
    }
  }
  return true;
}

bool String::Equals(const uint16_t* utf16_array, intptr_t len) const {
  if (len != this->Length()) {
    // Lengths don't match.
    return false;
  }

  for (intptr_t i = 0; i < len; i++) {
    if (this->CharAt(i) != utf16_array[i]) {
      return false;
    }
  }
  return true;
}

bool String::Equals(const int32_t* utf32_array, intptr_t len) const {
  if (len < 0) return false;
  intptr_t j = 0;
  for (intptr_t i = 0; i < len; ++i) {
    if (Utf::IsSupplementary(utf32_array[i])) {
      uint16_t encoded[2];
      Utf16::Encode(utf32_array[i], &encoded[0]);
      if (j + 1 >= Length()) return false;
      if (CharAt(j++) != encoded[0]) return false;
      if (CharAt(j++) != encoded[1]) return false;
    } else {
      if (j >= Length()) return false;
      if (CharAt(j++) != utf32_array[i]) return false;
    }
  }
  return j == Length();
}

bool String::EqualsConcat(const String& str1, const String& str2) const {
  return (Length() == str1.Length() + str2.Length()) &&
         str1.Equals(*this, 0, str1.Length()) &&
         str2.Equals(*this, str1.Length(), str2.Length());
}

intptr_t String::CompareTo(const String& other) const {
  const intptr_t this_len = this->Length();
  const intptr_t other_len = other.IsNull() ? 0 : other.Length();
  const intptr_t len = (this_len < other_len) ? this_len : other_len;
  for (intptr_t i = 0; i < len; i++) {
    uint16_t this_code_unit = this->CharAt(i);
    uint16_t other_code_unit = other.CharAt(i);
    if (this_code_unit < other_code_unit) {
      return -1;
    }
    if (this_code_unit > other_code_unit) {
      return 1;
    }
  }
  if (this_len < other_len) return -1;
  if (this_len > other_len) return 1;
  return 0;
}

bool String::StartsWith(const String& other) const {
  if (other.IsNull() || (other.Length() > this->Length())) {
    return false;
  }
  intptr_t slen = other.Length();
  for (int i = 0; i < slen; i++) {
    if (this->CharAt(i) != other.CharAt(i)) {
      return false;
    }
  }
  return true;
}

RawInstance* String::CheckAndCanonicalize(Thread* thread,
                                          const char** error_str) const {
  if (IsCanonical()) {
    return this->raw();
  }
  return Symbols::New(Thread::Current(), *this);
}

#if defined(DEBUG)
bool String::CheckIsCanonical(Thread* thread) const {
  Zone* zone = thread->zone();
  const String& str = String::Handle(zone, Symbols::Lookup(thread, *this));
  return (str.raw() == this->raw());
}
#endif  // DEBUG

RawString* String::New(const char* cstr, Heap::Space space) {
  ASSERT(cstr != NULL);
  intptr_t array_len = strlen(cstr);
  const uint8_t* utf8_array = reinterpret_cast<const uint8_t*>(cstr);
  return String::FromUTF8(utf8_array, array_len, space);
}

RawString* String::FromUTF8(const uint8_t* utf8_array,
                            intptr_t array_len,
                            Heap::Space space) {
  Utf8::Type type;
  intptr_t len = Utf8::CodeUnitCount(utf8_array, array_len, &type);
  if (type == Utf8::kLatin1) {
    const String& strobj = String::Handle(OneByteString::New(len, space));
    if (len > 0) {
      NoSafepointScope no_safepoint;
      Utf8::DecodeToLatin1(utf8_array, array_len,
                           OneByteString::CharAddr(strobj, 0), len);
    }
    return strobj.raw();
  }
  ASSERT((type == Utf8::kBMP) || (type == Utf8::kSupplementary));
  const String& strobj = String::Handle(TwoByteString::New(len, space));
  NoSafepointScope no_safepoint;
  Utf8::DecodeToUTF16(utf8_array, array_len, TwoByteString::CharAddr(strobj, 0),
                      len);
  return strobj.raw();
}

RawString* String::FromLatin1(const uint8_t* latin1_array,
                              intptr_t array_len,
                              Heap::Space space) {
  return OneByteString::New(latin1_array, array_len, space);
}

RawString* String::FromUTF16(const uint16_t* utf16_array,
                             intptr_t array_len,
                             Heap::Space space) {
  bool is_one_byte_string = true;
  for (intptr_t i = 0; i < array_len; ++i) {
    if (!Utf::IsLatin1(utf16_array[i])) {
      is_one_byte_string = false;
      break;
    }
  }
  if (is_one_byte_string) {
    return OneByteString::New(utf16_array, array_len, space);
  }
  return TwoByteString::New(utf16_array, array_len, space);
}

RawString* String::FromUTF32(const int32_t* utf32_array,
                             intptr_t array_len,
                             Heap::Space space) {
  bool is_one_byte_string = true;
  intptr_t utf16_len = array_len;
  for (intptr_t i = 0; i < array_len; ++i) {
    if (!Utf::IsLatin1(utf32_array[i])) {
      is_one_byte_string = false;
      if (Utf::IsSupplementary(utf32_array[i])) {
        utf16_len += 1;
      }
    }
  }
  if (is_one_byte_string) {
    return OneByteString::New(utf32_array, array_len, space);
  }
  return TwoByteString::New(utf16_len, utf32_array, array_len, space);
}

RawString* String::New(const String& str, Heap::Space space) {
  // Currently this just creates a copy of the string in the correct space.
  // Once we have external string support, this will also create a heap copy of
  // the string if necessary. Some optimizations are possible, such as not
  // copying internal strings into the same space.
  intptr_t len = str.Length();
  String& result = String::Handle();
  intptr_t char_size = str.CharSize();
  if (char_size == kOneByteChar) {
    result = OneByteString::New(len, space);
  } else {
    ASSERT(char_size == kTwoByteChar);
    result = TwoByteString::New(len, space);
  }
  String::Copy(result, 0, str, 0, len);
  return result.raw();
}

RawString* String::NewExternal(const uint8_t* characters,
                               intptr_t len,
                               void* peer,
                               Dart_PeerFinalizer callback,
                               Heap::Space space) {
  return ExternalOneByteString::New(characters, len, peer, callback, space);
}

RawString* String::NewExternal(const uint16_t* characters,
                               intptr_t len,
                               void* peer,
                               Dart_PeerFinalizer callback,
                               Heap::Space space) {
  return ExternalTwoByteString::New(characters, len, peer, callback, space);
}

void String::Copy(const String& dst,
                  intptr_t dst_offset,
                  const uint8_t* characters,
                  intptr_t len) {
  ASSERT(dst_offset >= 0);
  ASSERT(len >= 0);
  ASSERT(len <= (dst.Length() - dst_offset));
  if (dst.IsOneByteString()) {
    NoSafepointScope no_safepoint;
    if (len > 0) {
      memmove(OneByteString::CharAddr(dst, dst_offset), characters, len);
    }
  } else if (dst.IsTwoByteString()) {
    for (intptr_t i = 0; i < len; ++i) {
      *TwoByteString::CharAddr(dst, i + dst_offset) = characters[i];
    }
  }
}

void String::Copy(const String& dst,
                  intptr_t dst_offset,
                  const uint16_t* utf16_array,
                  intptr_t array_len) {
  ASSERT(dst_offset >= 0);
  ASSERT(array_len >= 0);
  ASSERT(array_len <= (dst.Length() - dst_offset));
  if (dst.IsOneByteString()) {
    NoSafepointScope no_safepoint;
    for (intptr_t i = 0; i < array_len; ++i) {
      ASSERT(Utf::IsLatin1(utf16_array[i]));
      *OneByteString::CharAddr(dst, i + dst_offset) = utf16_array[i];
    }
  } else {
    ASSERT(dst.IsTwoByteString());
    NoSafepointScope no_safepoint;
    if (array_len > 0) {
      memmove(TwoByteString::CharAddr(dst, dst_offset), utf16_array,
              array_len * 2);
    }
  }
}

void String::Copy(const String& dst,
                  intptr_t dst_offset,
                  const String& src,
                  intptr_t src_offset,
                  intptr_t len) {
  ASSERT(dst_offset >= 0);
  ASSERT(src_offset >= 0);
  ASSERT(len >= 0);
  ASSERT(len <= (dst.Length() - dst_offset));
  ASSERT(len <= (src.Length() - src_offset));
  if (len > 0) {
    intptr_t char_size = src.CharSize();
    if (char_size == kOneByteChar) {
      if (src.IsOneByteString()) {
        NoSafepointScope no_safepoint;
        String::Copy(dst, dst_offset, OneByteString::CharAddr(src, src_offset),
                     len);
      } else {
        ASSERT(src.IsExternalOneByteString());
        NoSafepointScope no_safepoint;
        String::Copy(dst, dst_offset,
                     ExternalOneByteString::CharAddr(src, src_offset), len);
      }
    } else {
      ASSERT(char_size == kTwoByteChar);
      if (src.IsTwoByteString()) {
        NoSafepointScope no_safepoint;
        String::Copy(dst, dst_offset, TwoByteString::CharAddr(src, src_offset),
                     len);
      } else {
        ASSERT(src.IsExternalTwoByteString());
        NoSafepointScope no_safepoint;
        String::Copy(dst, dst_offset,
                     ExternalTwoByteString::CharAddr(src, src_offset), len);
      }
    }
  }
}

RawString* String::EscapeSpecialCharacters(const String& str) {
  if (str.IsOneByteString()) {
    return OneByteString::EscapeSpecialCharacters(str);
  }
  if (str.IsTwoByteString()) {
    return TwoByteString::EscapeSpecialCharacters(str);
  }
  if (str.IsExternalOneByteString()) {
    return ExternalOneByteString::EscapeSpecialCharacters(str);
  }
  ASSERT(str.IsExternalTwoByteString());
  // If EscapeSpecialCharacters is frequently called on external two byte
  // strings, we should implement it directly on ExternalTwoByteString rather
  // than first converting to a TwoByteString.
  return TwoByteString::EscapeSpecialCharacters(
      String::Handle(TwoByteString::New(str, Heap::kNew)));
}

static bool IsPercent(int32_t c) {
  return c == '%';
}

static bool IsHexCharacter(int32_t c) {
  if (c >= '0' && c <= '9') {
    return true;
  }
  if (c >= 'A' && c <= 'F') {
    return true;
  }
  return false;
}

static bool IsURISafeCharacter(int32_t c) {
  if ((c >= '0') && (c <= '9')) {
    return true;
  }
  if ((c >= 'a') && (c <= 'z')) {
    return true;
  }
  if ((c >= 'A') && (c <= 'Z')) {
    return true;
  }
  return (c == '-') || (c == '_') || (c == '.') || (c == '~');
}

static int32_t GetHexCharacter(int32_t c) {
  ASSERT(c >= 0);
  ASSERT(c < 16);
  const char* hex = "0123456789ABCDEF";
  return hex[c];
}

static int32_t GetHexValue(int32_t c) {
  if (c >= '0' && c <= '9') {
    return c - '0';
  }
  if (c >= 'A' && c <= 'F') {
    return c - 'A' + 10;
  }
  UNREACHABLE();
  return 0;
}

static int32_t MergeHexCharacters(int32_t c1, int32_t c2) {
  return GetHexValue(c1) << 4 | GetHexValue(c2);
}

const char* String::EncodeIRI(const String& str) {
  const intptr_t len = Utf8::Length(str);
  Zone* zone = Thread::Current()->zone();
  uint8_t* utf8 = zone->Alloc<uint8_t>(len);
  str.ToUTF8(utf8, len);
  intptr_t num_escapes = 0;
  for (int i = 0; i < len; ++i) {
    uint8_t byte = utf8[i];
    if (!IsURISafeCharacter(byte)) {
      num_escapes += 2;
    }
  }
  intptr_t cstr_len = len + num_escapes + 1;
  char* cstr = zone->Alloc<char>(cstr_len);
  intptr_t index = 0;
  for (int i = 0; i < len; ++i) {
    uint8_t byte = utf8[i];
    if (!IsURISafeCharacter(byte)) {
      cstr[index++] = '%';
      cstr[index++] = GetHexCharacter(byte >> 4);
      cstr[index++] = GetHexCharacter(byte & 0xF);
    } else {
      ASSERT(byte <= 127);
      cstr[index++] = byte;
    }
  }
  cstr[index] = '\0';
  return cstr;
}

RawString* String::DecodeIRI(const String& str) {
  CodePointIterator cpi(str);
  intptr_t num_escapes = 0;
  intptr_t len = str.Length();
  {
    CodePointIterator cpi(str);
    while (cpi.Next()) {
      int32_t code_point = cpi.Current();
      if (IsPercent(code_point)) {
        // Verify that the two characters following the % are hex digits.
        if (!cpi.Next()) {
          return String::null();
        }
        int32_t code_point = cpi.Current();
        if (!IsHexCharacter(code_point)) {
          return String::null();
        }
        if (!cpi.Next()) {
          return String::null();
        }
        code_point = cpi.Current();
        if (!IsHexCharacter(code_point)) {
          return String::null();
        }
        num_escapes += 2;
      }
    }
  }
  intptr_t utf8_len = len - num_escapes;
  ASSERT(utf8_len >= 0);
  Zone* zone = Thread::Current()->zone();
  uint8_t* utf8 = zone->Alloc<uint8_t>(utf8_len);
  {
    intptr_t index = 0;
    CodePointIterator cpi(str);
    while (cpi.Next()) {
      ASSERT(index < utf8_len);
      int32_t code_point = cpi.Current();
      if (IsPercent(code_point)) {
        cpi.Next();
        int32_t ch1 = cpi.Current();
        cpi.Next();
        int32_t ch2 = cpi.Current();
        int32_t merged = MergeHexCharacters(ch1, ch2);
        ASSERT(merged >= 0 && merged < 256);
        utf8[index] = static_cast<uint8_t>(merged);
      } else {
        ASSERT(code_point >= 0 && code_point < 256);
        utf8[index] = static_cast<uint8_t>(code_point);
      }
      index++;
    }
  }
  return FromUTF8(utf8, utf8_len);
}

RawString* String::NewFormatted(const char* format, ...) {
  va_list args;
  va_start(args, format);
  RawString* result = NewFormattedV(format, args);
  NoSafepointScope no_safepoint;
  va_end(args);
  return result;
}

RawString* String::NewFormatted(Heap::Space space, const char* format, ...) {
  va_list args;
  va_start(args, format);
  RawString* result = NewFormattedV(format, args, space);
  NoSafepointScope no_safepoint;
  va_end(args);
  return result;
}

RawString* String::NewFormattedV(const char* format,
                                 va_list args,
                                 Heap::Space space) {
  va_list args_copy;
  va_copy(args_copy, args);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args_copy);
  va_end(args_copy);

  Zone* zone = Thread::Current()->zone();
  char* buffer = zone->Alloc<char>(len + 1);
  OS::VSNPrint(buffer, (len + 1), format, args);

  return String::New(buffer, space);
}

RawString* String::Concat(const String& str1,
                          const String& str2,
                          Heap::Space space) {
  ASSERT(!str1.IsNull() && !str2.IsNull());
  intptr_t char_size = Utils::Maximum(str1.CharSize(), str2.CharSize());
  if (char_size == kTwoByteChar) {
    return TwoByteString::Concat(str1, str2, space);
  }
  return OneByteString::Concat(str1, str2, space);
}

RawString* String::ConcatAll(const Array& strings, Heap::Space space) {
  return ConcatAllRange(strings, 0, strings.Length(), space);
}

RawString* String::ConcatAllRange(const Array& strings,
                                  intptr_t start,
                                  intptr_t end,
                                  Heap::Space space) {
  ASSERT(!strings.IsNull());
  ASSERT(start >= 0);
  ASSERT(end <= strings.Length());
  intptr_t result_len = 0;
  String& str = String::Handle();
  intptr_t char_size = kOneByteChar;
  // Compute 'char_size' and 'result_len'.
  for (intptr_t i = start; i < end; i++) {
    str ^= strings.At(i);
    const intptr_t str_len = str.Length();
    if ((kMaxElements - result_len) < str_len) {
      Exceptions::ThrowOOM();
      UNREACHABLE();
    }
    result_len += str_len;
    char_size = Utils::Maximum(char_size, str.CharSize());
  }
  if (char_size == kOneByteChar) {
    return OneByteString::ConcatAll(strings, start, end, result_len, space);
  }
  ASSERT(char_size == kTwoByteChar);
  return TwoByteString::ConcatAll(strings, start, end, result_len, space);
}

RawString* String::SubString(const String& str,
                             intptr_t begin_index,
                             Heap::Space space) {
  ASSERT(!str.IsNull());
  if (begin_index >= str.Length()) {
    return String::null();
  }
  return String::SubString(str, begin_index, (str.Length() - begin_index),
                           space);
}

RawString* String::SubString(Thread* thread,
                             const String& str,
                             intptr_t begin_index,
                             intptr_t length,
                             Heap::Space space) {
  ASSERT(!str.IsNull());
  ASSERT(begin_index >= 0);
  ASSERT(length >= 0);
  if (begin_index <= str.Length() && length == 0) {
    return Symbols::Empty().raw();
  }
  if (begin_index > str.Length()) {
    return String::null();
  }
  bool is_one_byte_string = true;
  intptr_t char_size = str.CharSize();
  if (char_size == kTwoByteChar) {
    for (intptr_t i = begin_index; i < begin_index + length; ++i) {
      if (!Utf::IsLatin1(str.CharAt(i))) {
        is_one_byte_string = false;
        break;
      }
    }
  }
  REUSABLE_STRING_HANDLESCOPE(thread);
  String& result = thread->StringHandle();
  if (is_one_byte_string) {
    result = OneByteString::New(length, space);
  } else {
    result = TwoByteString::New(length, space);
  }
  String::Copy(result, 0, str, begin_index, length);
  return result.raw();
}

const char* String::ToCString() const {
  if (IsOneByteString()) {
    // Quick conversion if OneByteString contains only ASCII characters.
    intptr_t len = Length();
    if (len == 0) {
      return "";
    }
    Zone* zone = Thread::Current()->zone();
    uint8_t* result = zone->Alloc<uint8_t>(len + 1);
    NoSafepointScope no_safepoint;
    const uint8_t* original_str = OneByteString::CharAddr(*this, 0);
    for (intptr_t i = 0; i < len; i++) {
      if (original_str[i] <= Utf8::kMaxOneByteChar) {
        result[i] = original_str[i];
      } else {
        len = -1;
        break;
      }
    }
    if (len > 0) {
      result[len] = 0;
      return reinterpret_cast<const char*>(result);
    }
  }
  const intptr_t len = Utf8::Length(*this);
  Zone* zone = Thread::Current()->zone();
  uint8_t* result = zone->Alloc<uint8_t>(len + 1);
  ToUTF8(result, len);
  result[len] = 0;
  return reinterpret_cast<const char*>(result);
}

char* String::ToMallocCString() const {
  if (IsOneByteString()) {
    // Quick conversion if OneByteString contains only ASCII characters.
    intptr_t len = Length();
    uint8_t* result = reinterpret_cast<uint8_t*>(malloc(len + 1));
    NoSafepointScope no_safepoint;
    const uint8_t* original_str = OneByteString::CharAddr(*this, 0);
    for (intptr_t i = 0; i < len; i++) {
      if (original_str[i] <= Utf8::kMaxOneByteChar) {
        result[i] = original_str[i];
      } else {
        len = -1;
        free(result);
        break;
      }
    }
    if (len > 0) {
      result[len] = 0;
      return reinterpret_cast<char*>(result);
    }
  }
  const intptr_t len = Utf8::Length(*this);
  uint8_t* result = reinterpret_cast<uint8_t*>(malloc(len + 1));
  ToUTF8(result, len);
  result[len] = 0;
  return reinterpret_cast<char*>(result);
}

void String::ToUTF8(uint8_t* utf8_array, intptr_t array_len) const {
  ASSERT(array_len >= Utf8::Length(*this));
  Utf8::Encode(*this, reinterpret_cast<char*>(utf8_array), array_len);
}

static FinalizablePersistentHandle* AddFinalizer(
    const Object& referent,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback,
    intptr_t external_size) {
  ASSERT((callback != NULL && peer != NULL) ||
         (callback == NULL && peer == NULL));
  return FinalizablePersistentHandle::New(Isolate::Current(), referent, peer,
                                          callback, external_size);
}

RawString* String::Transform(int32_t (*mapping)(int32_t ch),
                             const String& str,
                             Heap::Space space) {
  ASSERT(!str.IsNull());
  bool has_mapping = false;
  int32_t dst_max = 0;
  CodePointIterator it(str);
  while (it.Next()) {
    int32_t src = it.Current();
    int32_t dst = mapping(src);
    if (src != dst) {
      has_mapping = true;
    }
    dst_max = Utils::Maximum(dst_max, dst);
  }
  if (!has_mapping) {
    return str.raw();
  }
  if (Utf::IsLatin1(dst_max)) {
    return OneByteString::Transform(mapping, str, space);
  }
  ASSERT(Utf::IsBmp(dst_max) || Utf::IsSupplementary(dst_max));
  return TwoByteString::Transform(mapping, str, space);
}

RawString* String::ToUpperCase(const String& str, Heap::Space space) {
  // TODO(cshapiro): create a fast-path for OneByteString instances.
  return Transform(CaseMapping::ToUpper, str, space);
}

RawString* String::ToLowerCase(const String& str, Heap::Space space) {
  // TODO(cshapiro): create a fast-path for OneByteString instances.
  return Transform(CaseMapping::ToLower, str, space);
}

bool String::ParseDouble(const String& str,
                         intptr_t start,
                         intptr_t end,
                         double* result) {
  ASSERT(0 <= start);
  ASSERT(start <= end);
  ASSERT(end <= str.Length());
  intptr_t length = end - start;
  NoSafepointScope no_safepoint;
  const uint8_t* startChar;
  if (str.IsOneByteString()) {
    startChar = OneByteString::CharAddr(str, start);
  } else if (str.IsExternalOneByteString()) {
    startChar = ExternalOneByteString::CharAddr(str, start);
  } else {
    uint8_t* chars = Thread::Current()->zone()->Alloc<uint8_t>(length);
    const Scanner::CharAtFunc char_at = str.CharAtFunc();
    for (intptr_t i = 0; i < length; i++) {
      int32_t ch = char_at(str, start + i);
      if (ch < 128) {
        chars[i] = ch;
      } else {
        return false;  // Not ASCII, so definitely not valid double numeral.
      }
    }
    startChar = chars;
  }
  return CStringToDouble(reinterpret_cast<const char*>(startChar), length,
                         result);
}

// Check to see if 'str1' matches 'str2' as is or
// once the private key separator is stripped from str2.
//
// Things are made more complicated by the fact that constructors are
// added *after* the private suffix, so "foo@123.named" should match
// "foo.named".
//
// Also, the private suffix can occur more than once in the name, as in:
//
//    _ReceivePortImpl@6be832b._internal@6be832b
//
template <typename T1, typename T2>
static bool EqualsIgnoringPrivateKey(const String& str1, const String& str2) {
  intptr_t len = str1.Length();
  intptr_t str2_len = str2.Length();
  if (len == str2_len) {
    for (intptr_t i = 0; i < len; i++) {
      if (T1::CharAt(str1, i) != T2::CharAt(str2, i)) {
        return false;
      }
    }
    return true;
  }
  if (len < str2_len) {
    return false;  // No way they can match.
  }
  intptr_t pos = 0;
  intptr_t str2_pos = 0;
  while (pos < len) {
    int32_t ch = T1::CharAt(str1, pos);
    pos++;

    if (ch == Library::kPrivateKeySeparator) {
      // Consume a private key separator.
      while ((pos < len) && (T1::CharAt(str1, pos) != '.') &&
             (T1::CharAt(str1, pos) != '&')) {
        pos++;
      }
      // Resume matching characters.
      continue;
    }
    if ((str2_pos == str2_len) || (ch != T2::CharAt(str2, str2_pos))) {
      return false;
    }
    str2_pos++;
  }

  // We have reached the end of mangled_name string.
  ASSERT(pos == len);
  return (str2_pos == str2_len);
}

#define EQUALS_IGNORING_PRIVATE_KEY(class_id, type, str1, str2)                \
  switch (class_id) {                                                          \
    case kOneByteStringCid:                                                    \
      return dart::EqualsIgnoringPrivateKey<type, OneByteString>(str1, str2);  \
    case kTwoByteStringCid:                                                    \
      return dart::EqualsIgnoringPrivateKey<type, TwoByteString>(str1, str2);  \
    case kExternalOneByteStringCid:                                            \
      return dart::EqualsIgnoringPrivateKey<type, ExternalOneByteString>(      \
          str1, str2);                                                         \
    case kExternalTwoByteStringCid:                                            \
      return dart::EqualsIgnoringPrivateKey<type, ExternalTwoByteString>(      \
          str1, str2);                                                         \
  }                                                                            \
  UNREACHABLE();

bool String::EqualsIgnoringPrivateKey(const String& str1, const String& str2) {
  if (str1.raw() == str2.raw()) {
    return true;  // Both handles point to the same raw instance.
  }
  NoSafepointScope no_safepoint;
  intptr_t str1_class_id = str1.raw()->GetClassId();
  intptr_t str2_class_id = str2.raw()->GetClassId();
  switch (str1_class_id) {
    case kOneByteStringCid:
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id, OneByteString, str1, str2);
      break;
    case kTwoByteStringCid:
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id, TwoByteString, str1, str2);
      break;
    case kExternalOneByteStringCid:
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id, ExternalOneByteString, str1,
                                  str2);
      break;
    case kExternalTwoByteStringCid:
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id, ExternalTwoByteString, str1,
                                  str2);
      break;
  }
  UNREACHABLE();
  return false;
}

bool String::CodePointIterator::Next() {
  ASSERT(index_ >= -1);
  intptr_t length = Utf16::Length(ch_);
  if (index_ < (end_ - length)) {
    index_ += length;
    ch_ = str_.CharAt(index_);
    if (Utf16::IsLeadSurrogate(ch_) && (index_ < (end_ - 1))) {
      int32_t ch2 = str_.CharAt(index_ + 1);
      if (Utf16::IsTrailSurrogate(ch2)) {
        ch_ = Utf16::Decode(ch_, ch2);
      }
    }
    return true;
  }
  index_ = end_;
  return false;
}

RawOneByteString* OneByteString::EscapeSpecialCharacters(const String& str) {
  intptr_t len = str.Length();
  if (len > 0) {
    intptr_t num_escapes = 0;
    for (intptr_t i = 0; i < len; i++) {
      num_escapes += EscapeOverhead(CharAt(str, i));
    }
    const String& dststr =
        String::Handle(OneByteString::New(len + num_escapes, Heap::kNew));
    intptr_t index = 0;
    for (intptr_t i = 0; i < len; i++) {
      uint8_t ch = CharAt(str, i);
      if (IsSpecialCharacter(ch)) {
        SetCharAt(dststr, index, '\\');
        SetCharAt(dststr, index + 1, SpecialCharacter(ch));
        index += 2;
      } else if (IsAsciiNonprintable(ch)) {
        SetCharAt(dststr, index, '\\');
        SetCharAt(dststr, index + 1, 'x');
        SetCharAt(dststr, index + 2, GetHexCharacter(ch >> 4));
        SetCharAt(dststr, index + 3, GetHexCharacter(ch & 0xF));
        index += 4;
      } else {
        SetCharAt(dststr, index, ch);
        index += 1;
      }
    }
    return OneByteString::raw(dststr);
  }
  return OneByteString::raw(Symbols::Empty());
}

RawOneByteString* ExternalOneByteString::EscapeSpecialCharacters(
    const String& str) {
  intptr_t len = str.Length();
  if (len > 0) {
    intptr_t num_escapes = 0;
    for (intptr_t i = 0; i < len; i++) {
      num_escapes += EscapeOverhead(CharAt(str, i));
    }
    const String& dststr =
        String::Handle(OneByteString::New(len + num_escapes, Heap::kNew));
    intptr_t index = 0;
    for (intptr_t i = 0; i < len; i++) {
      uint8_t ch = CharAt(str, i);
      if (IsSpecialCharacter(ch)) {
        OneByteString::SetCharAt(dststr, index, '\\');
        OneByteString::SetCharAt(dststr, index + 1, SpecialCharacter(ch));
        index += 2;
      } else if (IsAsciiNonprintable(ch)) {
        OneByteString::SetCharAt(dststr, index, '\\');
        OneByteString::SetCharAt(dststr, index + 1, 'x');
        OneByteString::SetCharAt(dststr, index + 2, GetHexCharacter(ch >> 4));
        OneByteString::SetCharAt(dststr, index + 3, GetHexCharacter(ch & 0xF));
        index += 4;
      } else {
        OneByteString::SetCharAt(dststr, index, ch);
        index += 1;
      }
    }
    return OneByteString::raw(dststr);
  }
  return OneByteString::raw(Symbols::Empty());
}

RawOneByteString* OneByteString::New(intptr_t len, Heap::Space space) {
  ASSERT((Isolate::Current() == Dart::vm_isolate()) ||
         ((Isolate::Current()->object_store() != NULL) &&
          (Isolate::Current()->object_store()->one_byte_string_class() !=
           Class::null())));
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in OneByteString::New: invalid len %" Pd "\n", len);
  }
  {
    RawObject* raw = Object::Allocate(OneByteString::kClassId,
                                      OneByteString::InstanceSize(len), space);
    NoSafepointScope no_safepoint;
    RawOneByteString* result = reinterpret_cast<RawOneByteString*>(raw);
    result->StoreSmi(&(result->ptr()->length_), Smi::New(len));
#if !defined(HASH_IN_OBJECT_HEADER)
    result->StoreSmi(&(result->ptr()->hash_), Smi::New(0));
#endif
    return result;
  }
}

RawOneByteString* OneByteString::New(const uint8_t* characters,
                                     intptr_t len,
                                     Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(len, space));
  if (len > 0) {
    NoSafepointScope no_safepoint;
    memmove(CharAddr(result, 0), characters, len);
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::New(const uint16_t* characters,
                                     intptr_t len,
                                     Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(len, space));
  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < len; ++i) {
    ASSERT(Utf::IsLatin1(characters[i]));
    *CharAddr(result, i) = characters[i];
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::New(const int32_t* characters,
                                     intptr_t len,
                                     Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(len, space));
  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < len; ++i) {
    ASSERT(Utf::IsLatin1(characters[i]));
    *CharAddr(result, i) = characters[i];
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::New(const String& str, Heap::Space space) {
  intptr_t len = str.Length();
  const String& result = String::Handle(OneByteString::New(len, space));
  String::Copy(result, 0, str, 0, len);
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::New(const String& other_one_byte_string,
                                     intptr_t other_start_index,
                                     intptr_t other_len,
                                     Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(other_len, space));
  ASSERT(other_one_byte_string.IsOneByteString());
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(OneByteString::CharAddr(result, 0),
            OneByteString::CharAddr(other_one_byte_string, other_start_index),
            other_len);
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::New(const TypedData& other_typed_data,
                                     intptr_t other_start_index,
                                     intptr_t other_len,
                                     Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(other_len, space));
  ASSERT(other_typed_data.ElementSizeInBytes() == 1);
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(OneByteString::CharAddr(result, 0),
            other_typed_data.DataAddr(other_start_index), other_len);
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::New(const ExternalTypedData& other_typed_data,
                                     intptr_t other_start_index,
                                     intptr_t other_len,
                                     Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(other_len, space));
  ASSERT(other_typed_data.ElementSizeInBytes() == 1);
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(OneByteString::CharAddr(result, 0),
            other_typed_data.DataAddr(other_start_index), other_len);
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::Concat(const String& str1,
                                        const String& str2,
                                        Heap::Space space) {
  intptr_t len1 = str1.Length();
  intptr_t len2 = str2.Length();
  intptr_t len = len1 + len2;
  const String& result = String::Handle(OneByteString::New(len, space));
  String::Copy(result, 0, str1, 0, len1);
  String::Copy(result, len1, str2, 0, len2);
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::ConcatAll(const Array& strings,
                                           intptr_t start,
                                           intptr_t end,
                                           intptr_t len,
                                           Heap::Space space) {
  ASSERT(!strings.IsNull());
  ASSERT(start >= 0);
  ASSERT(end <= strings.Length());
  const String& result = String::Handle(OneByteString::New(len, space));
  String& str = String::Handle();
  intptr_t pos = 0;
  for (intptr_t i = start; i < end; i++) {
    str ^= strings.At(i);
    const intptr_t str_len = str.Length();
    String::Copy(result, pos, str, 0, str_len);
    ASSERT((kMaxElements - pos) >= str_len);
    pos += str_len;
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::Transform(int32_t (*mapping)(int32_t ch),
                                           const String& str,
                                           Heap::Space space) {
  ASSERT(!str.IsNull());
  intptr_t len = str.Length();
  const String& result = String::Handle(OneByteString::New(len, space));
  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < len; ++i) {
    int32_t ch = mapping(str.CharAt(i));
    ASSERT(Utf::IsLatin1(ch));
    *CharAddr(result, i) = ch;
  }
  return OneByteString::raw(result);
}

RawOneByteString* OneByteString::SubStringUnchecked(const String& str,
                                                    intptr_t begin_index,
                                                    intptr_t length,
                                                    Heap::Space space) {
  ASSERT(!str.IsNull() && str.IsOneByteString());
  ASSERT(begin_index >= 0);
  ASSERT(length >= 0);
  if (begin_index <= str.Length() && length == 0) {
    return OneByteString::raw(Symbols::Empty());
  }
  ASSERT(begin_index < str.Length());
  RawOneByteString* result = OneByteString::New(length, space);
  NoSafepointScope no_safepoint;
  if (length > 0) {
    uint8_t* dest = &result->ptr()->data()[0];
    const uint8_t* src = &raw_ptr(str)->data()[begin_index];
    memmove(dest, src, length);
  }
  return result;
}

void OneByteString::SetPeer(const String& str,
                            intptr_t external_size,
                            void* peer,
                            Dart_PeerFinalizer cback) {
  ASSERT(!str.IsNull() && str.IsOneByteString());
  ASSERT(peer != NULL);
  ExternalStringData<uint8_t>* ext_data =
      new ExternalStringData<uint8_t>(NULL, peer, cback);
  AddFinalizer(str, ext_data, OneByteString::Finalize, external_size);
  Isolate::Current()->heap()->SetPeer(str.raw(), peer);
}

void OneByteString::Finalize(void* isolate_callback_data,
                             Dart_WeakPersistentHandle handle,
                             void* peer) {
  delete reinterpret_cast<ExternalStringData<uint8_t>*>(peer);
}

RawTwoByteString* TwoByteString::EscapeSpecialCharacters(const String& str) {
  intptr_t len = str.Length();
  if (len > 0) {
    intptr_t num_escapes = 0;
    for (intptr_t i = 0; i < len; i++) {
      num_escapes += EscapeOverhead(CharAt(str, i));
    }
    const String& dststr =
        String::Handle(TwoByteString::New(len + num_escapes, Heap::kNew));
    intptr_t index = 0;
    for (intptr_t i = 0; i < len; i++) {
      uint16_t ch = CharAt(str, i);
      if (IsSpecialCharacter(ch)) {
        SetCharAt(dststr, index, '\\');
        SetCharAt(dststr, index + 1, SpecialCharacter(ch));
        index += 2;
      } else if (IsAsciiNonprintable(ch)) {
        SetCharAt(dststr, index, '\\');
        SetCharAt(dststr, index + 1, 'x');
        SetCharAt(dststr, index + 2, GetHexCharacter(ch >> 4));
        SetCharAt(dststr, index + 3, GetHexCharacter(ch & 0xF));
        index += 4;
      } else {
        SetCharAt(dststr, index, ch);
        index += 1;
      }
    }
    return TwoByteString::raw(dststr);
  }
  return TwoByteString::New(0, Heap::kNew);
}

RawTwoByteString* TwoByteString::New(intptr_t len, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->two_byte_string_class());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in TwoByteString::New: invalid len %" Pd "\n", len);
  }
  String& result = String::Handle();
  {
    RawObject* raw = Object::Allocate(TwoByteString::kClassId,
                                      TwoByteString::InstanceSize(len), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
  }
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::New(const uint16_t* utf16_array,
                                     intptr_t array_len,
                                     Heap::Space space) {
  ASSERT(array_len > 0);
  const String& result = String::Handle(TwoByteString::New(array_len, space));
  {
    NoSafepointScope no_safepoint;
    memmove(CharAddr(result, 0), utf16_array, (array_len * 2));
  }
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::New(intptr_t utf16_len,
                                     const int32_t* utf32_array,
                                     intptr_t array_len,
                                     Heap::Space space) {
  ASSERT((array_len > 0) && (utf16_len >= array_len));
  const String& result = String::Handle(TwoByteString::New(utf16_len, space));
  {
    NoSafepointScope no_safepoint;
    intptr_t j = 0;
    for (intptr_t i = 0; i < array_len; ++i) {
      if (Utf::IsSupplementary(utf32_array[i])) {
        ASSERT(j < (utf16_len - 1));
        Utf16::Encode(utf32_array[i], CharAddr(result, j));
        j += 2;
      } else {
        ASSERT(j < utf16_len);
        *CharAddr(result, j) = utf32_array[i];
        j += 1;
      }
    }
  }
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::New(const String& str, Heap::Space space) {
  intptr_t len = str.Length();
  const String& result = String::Handle(TwoByteString::New(len, space));
  String::Copy(result, 0, str, 0, len);
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::New(const TypedData& other_typed_data,
                                     intptr_t other_start_index,
                                     intptr_t other_len,
                                     Heap::Space space) {
  const String& result = String::Handle(TwoByteString::New(other_len, space));
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(TwoByteString::CharAddr(result, 0),
            other_typed_data.DataAddr(other_start_index),
            other_len * sizeof(uint16_t));
  }
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::New(const ExternalTypedData& other_typed_data,
                                     intptr_t other_start_index,
                                     intptr_t other_len,
                                     Heap::Space space) {
  const String& result = String::Handle(TwoByteString::New(other_len, space));
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(TwoByteString::CharAddr(result, 0),
            other_typed_data.DataAddr(other_start_index),
            other_len * sizeof(uint16_t));
  }
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::Concat(const String& str1,
                                        const String& str2,
                                        Heap::Space space) {
  intptr_t len1 = str1.Length();
  intptr_t len2 = str2.Length();
  intptr_t len = len1 + len2;
  const String& result = String::Handle(TwoByteString::New(len, space));
  String::Copy(result, 0, str1, 0, len1);
  String::Copy(result, len1, str2, 0, len2);
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::ConcatAll(const Array& strings,
                                           intptr_t start,
                                           intptr_t end,
                                           intptr_t len,
                                           Heap::Space space) {
  ASSERT(!strings.IsNull());
  ASSERT(start >= 0);
  ASSERT(end <= strings.Length());
  const String& result = String::Handle(TwoByteString::New(len, space));
  String& str = String::Handle();
  intptr_t pos = 0;
  for (intptr_t i = start; i < end; i++) {
    str ^= strings.At(i);
    const intptr_t str_len = str.Length();
    String::Copy(result, pos, str, 0, str_len);
    ASSERT((kMaxElements - pos) >= str_len);
    pos += str_len;
  }
  return TwoByteString::raw(result);
}

RawTwoByteString* TwoByteString::Transform(int32_t (*mapping)(int32_t ch),
                                           const String& str,
                                           Heap::Space space) {
  ASSERT(!str.IsNull());
  intptr_t len = str.Length();
  const String& result = String::Handle(TwoByteString::New(len, space));
  String::CodePointIterator it(str);
  intptr_t i = 0;
  NoSafepointScope no_safepoint;
  while (it.Next()) {
    int32_t src = it.Current();
    int32_t dst = mapping(src);
    ASSERT(dst >= 0 && dst <= 0x10FFFF);
    intptr_t len = Utf16::Length(dst);
    if (len == 1) {
      *CharAddr(result, i) = dst;
    } else {
      ASSERT(len == 2);
      Utf16::Encode(dst, CharAddr(result, i));
    }
    i += len;
  }
  return TwoByteString::raw(result);
}

void TwoByteString::SetPeer(const String& str,
                            intptr_t external_size,
                            void* peer,
                            Dart_PeerFinalizer cback) {
  ASSERT(!str.IsNull() && str.IsTwoByteString());
  ASSERT(peer != NULL);
  ExternalStringData<uint16_t>* ext_data =
      new ExternalStringData<uint16_t>(NULL, peer, cback);
  AddFinalizer(str, ext_data, TwoByteString::Finalize, external_size);
  Isolate::Current()->heap()->SetPeer(str.raw(), peer);
}

void TwoByteString::Finalize(void* isolate_callback_data,
                             Dart_WeakPersistentHandle handle,
                             void* peer) {
  delete reinterpret_cast<ExternalStringData<uint16_t>*>(peer);
}

RawExternalOneByteString* ExternalOneByteString::New(
    const uint8_t* data,
    intptr_t len,
    void* peer,
    Dart_PeerFinalizer callback,
    Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->external_one_byte_string_class() !=
         Class::null());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ExternalOneByteString::New: invalid len %" Pd "\n",
           len);
  }
  String& result = String::Handle();
  ExternalStringData<uint8_t>* external_data =
      new ExternalStringData<uint8_t>(data, peer, callback);
  {
    RawObject* raw =
        Object::Allocate(ExternalOneByteString::kClassId,
                         ExternalOneByteString::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
    SetExternalData(result, external_data);
  }
  intptr_t external_size = len;
  AddFinalizer(result, external_data, ExternalOneByteString::Finalize,
               external_size);
  return ExternalOneByteString::raw(result);
}

void ExternalOneByteString::Finalize(void* isolate_callback_data,
                                     Dart_WeakPersistentHandle handle,
                                     void* peer) {
  delete reinterpret_cast<ExternalStringData<uint8_t>*>(peer);
}

RawExternalTwoByteString* ExternalTwoByteString::New(
    const uint16_t* data,
    intptr_t len,
    void* peer,
    Dart_PeerFinalizer callback,
    Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->external_two_byte_string_class() !=
         Class::null());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ExternalTwoByteString::New: invalid len %" Pd "\n",
           len);
  }
  String& result = String::Handle();
  ExternalStringData<uint16_t>* external_data =
      new ExternalStringData<uint16_t>(data, peer, callback);
  {
    RawObject* raw =
        Object::Allocate(ExternalTwoByteString::kClassId,
                         ExternalTwoByteString::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
    SetExternalData(result, external_data);
  }
  intptr_t external_size = len * 2;
  AddFinalizer(result, external_data, ExternalTwoByteString::Finalize,
               external_size);
  return ExternalTwoByteString::raw(result);
}

void ExternalTwoByteString::Finalize(void* isolate_callback_data,
                                     Dart_WeakPersistentHandle handle,
                                     void* peer) {
  delete reinterpret_cast<ExternalStringData<uint16_t>*>(peer);
}

RawBool* Bool::New(bool value) {
  ASSERT(Isolate::Current()->object_store()->bool_class() != Class::null());
  Bool& result = Bool::Handle();
  {
    // Since the two boolean instances are singletons we allocate them straight
    // in the old generation.
    RawObject* raw =
        Object::Allocate(Bool::kClassId, Bool::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(value);
  result.SetCanonical();
  return result.raw();
}

const char* Bool::ToCString() const {
  return value() ? "true" : "false";
}

bool Array::CanonicalizeEquals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    // Both handles point to the same raw instance.
    return true;
  }

  // An Array may be compared to an ImmutableArray.
  if (!other.IsArray() || other.IsNull()) {
    return false;
  }

  // First check if both arrays have the same length and elements.
  const Array& other_arr = Array::Cast(other);

  intptr_t len = this->Length();
  if (len != other_arr.Length()) {
    return false;
  }

  for (intptr_t i = 0; i < len; i++) {
    if (this->At(i) != other_arr.At(i)) {
      return false;
    }
  }

  // Now check if both arrays have the same type arguments.
  if (GetTypeArguments() == other.GetTypeArguments()) {
    return true;
  }
  const TypeArguments& type_args = TypeArguments::Handle(GetTypeArguments());
  const TypeArguments& other_type_args =
      TypeArguments::Handle(other.GetTypeArguments());
  if (!type_args.Equals(other_type_args)) {
    return false;
  }
  return true;
}

uword Array::ComputeCanonicalTableHash() const {
  ASSERT(!IsNull());
  NoSafepointScope no_safepoint;
  intptr_t len = Length();
  uword hash = len;
  uword value = reinterpret_cast<uword>(GetTypeArguments());
  hash = CombineHashes(hash, value);
  for (intptr_t i = 0; i < len; i++) {
    value = reinterpret_cast<uword>(At(i));
    hash = CombineHashes(hash, value);
  }
  return FinalizeHash(hash, kHashBits);
}

RawArray* Array::New(intptr_t len, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->array_class() != Class::null());
  return New(kClassId, len, space);
}

RawArray* Array::New(intptr_t class_id, intptr_t len, Heap::Space space) {
  if ((len < 0) || (len > Array::kMaxElements)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Array::New: invalid len %" Pd "\n", len);
  }
  {
    RawArray* raw = reinterpret_cast<RawArray*>(
        Object::Allocate(class_id, Array::InstanceSize(len), space));
    NoSafepointScope no_safepoint;
    raw->StoreSmi(&(raw->ptr()->length_), Smi::New(len));
    return raw;
  }
}

RawArray* Array::Slice(intptr_t start,
                       intptr_t count,
                       bool with_type_argument) const {
  // TODO(vegorov) introduce an array allocation method that fills newly
  // allocated array with values from the given source array instead of
  // null-initializing all elements.
  Array& dest = Array::Handle(Array::New(count));
  dest.StorePointers(dest.ObjectAddr(0), ObjectAddr(start), count);

  if (with_type_argument) {
    dest.SetTypeArguments(TypeArguments::Handle(GetTypeArguments()));
  }

  return dest.raw();
}

void Array::MakeImmutable() const {
  if (IsImmutable()) return;
  ASSERT(!IsCanonical());
  NoSafepointScope no_safepoint;
  uint32_t tags = raw_ptr()->tags_;
  uint32_t old_tags;
  do {
    old_tags = tags;
    uint32_t new_tags =
        RawObject::ClassIdTag::update(kImmutableArrayCid, old_tags);
    tags = CompareAndSwapTags(old_tags, new_tags);
  } while (tags != old_tags);
}

const char* Array::ToCString() const {
  if (IsNull()) {
    return IsImmutable() ? "_ImmutableList NULL" : "_List NULL";
  }
  Zone* zone = Thread::Current()->zone();
  const char* format =
      IsImmutable() ? "_ImmutableList len:%" Pd : "_List len:%" Pd;
  return zone->PrintToString(format, Length());
}

RawArray* Array::Grow(const Array& source,
                      intptr_t new_length,
                      Heap::Space space) {
  Zone* zone = Thread::Current()->zone();
  const Array& result = Array::Handle(zone, Array::New(new_length, space));
  intptr_t len = 0;
  if (!source.IsNull()) {
    len = source.Length();
    result.SetTypeArguments(
        TypeArguments::Handle(zone, source.GetTypeArguments()));
  }
  ASSERT(new_length >= len);  // Cannot copy 'source' into new array.
  ASSERT(new_length != len);  // Unnecessary copying of array.
  PassiveObject& obj = PassiveObject::Handle(zone);
  for (int i = 0; i < len; i++) {
    obj = source.At(i);
    result.SetAt(i, obj);
  }
  return result.raw();
}

RawArray* Array::MakeFixedLength(const GrowableObjectArray& growable_array,
                                 bool unique) {
  ASSERT(!growable_array.IsNull());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  intptr_t used_len = growable_array.Length();
  // Get the type arguments and prepare to copy them.
  const TypeArguments& type_arguments =
      TypeArguments::Handle(growable_array.GetTypeArguments());
  if (used_len == 0) {
    if (type_arguments.IsNull() && !unique) {
      // This is a raw List (as in no type arguments), so we can return the
      // simple empty array.
      return Object::empty_array().raw();
    }

    // The backing array may be a shared instance, or may not have correct
    // type parameters. Create a new empty array.
    Heap::Space space = thread->IsMutatorThread() ? Heap::kNew : Heap::kOld;
    Array& array = Array::Handle(zone, Array::New(0, space));
    array.SetTypeArguments(type_arguments);
    return array.raw();
  }
  intptr_t capacity_len = growable_array.Capacity();
  const Array& array = Array::Handle(zone, growable_array.data());
  ASSERT(array.IsArray());
  array.SetTypeArguments(type_arguments);
  intptr_t capacity_size = Array::InstanceSize(capacity_len);
  intptr_t used_size = Array::InstanceSize(used_len);
  NoSafepointScope no_safepoint;

  // If there is any left over space fill it with either an Array object or
  // just a plain object (depending on the amount of left over space) so
  // that it can be traversed over successfully during garbage collection.
  Object::MakeUnusedSpaceTraversable(array, capacity_size, used_size);

  // Update the size in the header field and length of the array object.
  uword tags = array.raw_ptr()->tags_;
  ASSERT(kArrayCid == RawObject::ClassIdTag::decode(tags));
  uint32_t old_tags;
  do {
    old_tags = tags;
    uint32_t new_tags = RawObject::SizeTag::update(used_size, old_tags);
    tags = array.CompareAndSwapTags(old_tags, new_tags);
  } while (tags != old_tags);
  // TODO(22501): For the heap to remain walkable by the sweeper, it must
  // observe the creation of the filler object no later than the new length
  // of the array. This assumption holds on ia32/x64 or if the CAS above is a
  // full memory barrier.
  //
  // Also, between the CAS of the header above and the SetLength below,
  // the array is temporarily in an inconsistent state. The header is considered
  // the overriding source of object size by RawObject::Size, but the ASSERTs
  // in RawObject::SizeFromClass must handle this special case.
  array.SetLength(used_len);

  // Null the GrowableObjectArray, we are removing its backing array.
  growable_array.SetLength(0);
  growable_array.SetData(Object::empty_array());

  return array.raw();
}

bool Array::CheckAndCanonicalizeFields(Thread* thread,
                                       const char** error_str) const {
  intptr_t len = Length();
  if (len > 0) {
    Zone* zone = thread->zone();
    Object& obj = Object::Handle(zone);
    // Iterate over all elements, canonicalize numbers and strings, expect all
    // other instances to be canonical otherwise report error (return false).
    for (intptr_t i = 0; i < len; i++) {
      obj = At(i);
      if (obj.IsInstance() && !obj.IsSmi() && !obj.IsCanonical()) {
        if (obj.IsNumber() || obj.IsString()) {
          obj = Instance::Cast(obj).CheckAndCanonicalize(thread, NULL);
          ASSERT(!obj.IsNull());
          this->SetAt(i, obj);
        } else {
          ASSERT(error_str != NULL);
          char* chars = OS::SCreate(zone, "element at index %" Pd ": %s\n", i,
                                    obj.ToCString());
          *error_str = chars;
          return false;
        }
      }
    }
  }
  return true;
}

RawImmutableArray* ImmutableArray::New(intptr_t len, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->immutable_array_class() !=
         Class::null());
  return reinterpret_cast<RawImmutableArray*>(Array::New(kClassId, len, space));
}

void GrowableObjectArray::Add(const Object& value, Heap::Space space) const {
  ASSERT(!IsNull());
  if (Length() == Capacity()) {
    // Grow from 0 to 3, and then double + 1.
    intptr_t new_capacity = (Capacity() * 2) | 3;
    if (new_capacity <= Capacity()) {
      Exceptions::ThrowOOM();
      UNREACHABLE();
    }
    Grow(new_capacity, space);
  }
  ASSERT(Length() < Capacity());
  intptr_t index = Length();
  SetLength(index + 1);
  SetAt(index, value);
}

void GrowableObjectArray::Grow(intptr_t new_capacity, Heap::Space space) const {
  ASSERT(new_capacity > Capacity());
  const Array& contents = Array::Handle(data());
  const Array& new_contents =
      Array::Handle(Array::Grow(contents, new_capacity, space));
  StorePointer(&(raw_ptr()->data_), new_contents.raw());
}

RawObject* GrowableObjectArray::RemoveLast() const {
  ASSERT(!IsNull());
  ASSERT(Length() > 0);
  intptr_t index = Length() - 1;
  const Array& contents = Array::Handle(data());
  const PassiveObject& obj = PassiveObject::Handle(contents.At(index));
  contents.SetAt(index, Object::null_object());
  SetLength(index);
  return obj.raw();
}

RawGrowableObjectArray* GrowableObjectArray::New(intptr_t capacity,
                                                 Heap::Space space) {
  RawArray* raw_data = (capacity == 0) ? Object::empty_array().raw()
                                       : Array::New(capacity, space);
  const Array& data = Array::Handle(raw_data);
  return New(data, space);
}

RawGrowableObjectArray* GrowableObjectArray::New(const Array& array,
                                                 Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->growable_object_array_class() !=
         Class::null());
  GrowableObjectArray& result = GrowableObjectArray::Handle();
  {
    RawObject* raw =
        Object::Allocate(GrowableObjectArray::kClassId,
                         GrowableObjectArray::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(0);
    result.SetData(array);
  }
  return result.raw();
}

const char* GrowableObjectArray::ToCString() const {
  if (IsNull()) {
    return "_GrowableList: null";
  }
  return OS::SCreate(Thread::Current()->zone(),
                     "Instance(length:%" Pd ") of '_GrowableList'", Length());
}

// Equivalent to Dart's operator "==" and hashCode.
class DefaultHashTraits {
 public:
  static const char* Name() { return "DefaultHashTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    if (a.IsNull() || b.IsNull()) {
      return (a.IsNull() && b.IsNull());
    } else {
      return Instance::Cast(a).OperatorEquals(Instance::Cast(b));
    }
  }
  static uword Hash(const Object& obj) {
    if (obj.IsNull()) {
      return 0;
    }
    // TODO(koda): Ensure VM classes only produce Smi hash codes, and remove
    // non-Smi cases once Dart-side implementation is complete.
    Thread* thread = Thread::Current();
    REUSABLE_INSTANCE_HANDLESCOPE(thread);
    Instance& hash_code = thread->InstanceHandle();
    hash_code ^= Instance::Cast(obj).HashCode();
    if (hash_code.IsSmi()) {
      // May waste some bits on 64-bit, to ensure consistency with non-Smi case.
      return static_cast<uword>(Smi::Cast(hash_code).AsTruncatedUint32Value());
    } else if (hash_code.IsInteger()) {
      return static_cast<uword>(
          Integer::Cast(hash_code).AsTruncatedUint32Value());
    } else {
      return 0;
    }
  }
};

RawLinkedHashMap* LinkedHashMap::NewDefault(Heap::Space space) {
  const Array& data = Array::Handle(Array::New(kInitialIndexSize, space));
  const TypedData& index = TypedData::Handle(
      TypedData::New(kTypedDataUint32ArrayCid, kInitialIndexSize, space));
  // On 32-bit, the top bits are wasted to avoid Mint allocation.
  static const intptr_t kAvailableBits = (kSmiBits >= 32) ? 32 : kSmiBits;
  static const intptr_t kInitialHashMask =
      (1 << (kAvailableBits - kInitialIndexBits)) - 1;
  return LinkedHashMap::New(data, index, kInitialHashMask, 0, 0, space);
}

RawLinkedHashMap* LinkedHashMap::New(const Array& data,
                                     const TypedData& index,
                                     intptr_t hash_mask,
                                     intptr_t used_data,
                                     intptr_t deleted_keys,
                                     Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->linked_hash_map_class() !=
         Class::null());
  LinkedHashMap& result =
      LinkedHashMap::Handle(LinkedHashMap::NewUninitialized(space));
  result.SetData(data);
  result.SetIndex(index);
  result.SetHashMask(hash_mask);
  result.SetUsedData(used_data);
  result.SetDeletedKeys(deleted_keys);
  return result.raw();
}

RawLinkedHashMap* LinkedHashMap::NewUninitialized(Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->linked_hash_map_class() !=
         Class::null());
  LinkedHashMap& result = LinkedHashMap::Handle();
  {
    RawObject* raw = Object::Allocate(LinkedHashMap::kClassId,
                                      LinkedHashMap::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  return result.raw();
}

const char* LinkedHashMap::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  return zone->PrintToString("_LinkedHashMap len:%" Pd, Length());
}

RawFloat32x4* Float32x4::New(float v0,
                             float v1,
                             float v2,
                             float v3,
                             Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float32x4_class() !=
         Class::null());
  Float32x4& result = Float32x4::Handle();
  {
    RawObject* raw =
        Object::Allocate(Float32x4::kClassId, Float32x4::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_x(v0);
  result.set_y(v1);
  result.set_z(v2);
  result.set_w(v3);
  return result.raw();
}

RawFloat32x4* Float32x4::New(simd128_value_t value, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float32x4_class() !=
         Class::null());
  Float32x4& result = Float32x4::Handle();
  {
    RawObject* raw =
        Object::Allocate(Float32x4::kClassId, Float32x4::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(value);
  return result.raw();
}

simd128_value_t Float32x4::value() const {
  return ReadUnaligned(
      reinterpret_cast<const simd128_value_t*>(&raw_ptr()->value_));
}

void Float32x4::set_value(simd128_value_t value) const {
  StoreUnaligned(reinterpret_cast<simd128_value_t*>(&raw()->ptr()->value_),
                 value);
}

void Float32x4::set_x(float value) const {
  StoreNonPointer(&raw_ptr()->value_[0], value);
}

void Float32x4::set_y(float value) const {
  StoreNonPointer(&raw_ptr()->value_[1], value);
}

void Float32x4::set_z(float value) const {
  StoreNonPointer(&raw_ptr()->value_[2], value);
}

void Float32x4::set_w(float value) const {
  StoreNonPointer(&raw_ptr()->value_[3], value);
}

float Float32x4::x() const {
  return raw_ptr()->value_[0];
}

float Float32x4::y() const {
  return raw_ptr()->value_[1];
}

float Float32x4::z() const {
  return raw_ptr()->value_[2];
}

float Float32x4::w() const {
  return raw_ptr()->value_[3];
}

const char* Float32x4::ToCString() const {
  float _x = x();
  float _y = y();
  float _z = z();
  float _w = w();
  return OS::SCreate(Thread::Current()->zone(), "[%f, %f, %f, %f]", _x, _y, _z,
                     _w);
}

RawInt32x4* Int32x4::New(int32_t v0,
                         int32_t v1,
                         int32_t v2,
                         int32_t v3,
                         Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->int32x4_class() != Class::null());
  Int32x4& result = Int32x4::Handle();
  {
    RawObject* raw =
        Object::Allocate(Int32x4::kClassId, Int32x4::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_x(v0);
  result.set_y(v1);
  result.set_z(v2);
  result.set_w(v3);
  return result.raw();
}

RawInt32x4* Int32x4::New(simd128_value_t value, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->int32x4_class() != Class::null());
  Int32x4& result = Int32x4::Handle();
  {
    RawObject* raw =
        Object::Allocate(Int32x4::kClassId, Int32x4::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(value);
  return result.raw();
}

void Int32x4::set_x(int32_t value) const {
  StoreNonPointer(&raw_ptr()->value_[0], value);
}

void Int32x4::set_y(int32_t value) const {
  StoreNonPointer(&raw_ptr()->value_[1], value);
}

void Int32x4::set_z(int32_t value) const {
  StoreNonPointer(&raw_ptr()->value_[2], value);
}

void Int32x4::set_w(int32_t value) const {
  StoreNonPointer(&raw_ptr()->value_[3], value);
}

int32_t Int32x4::x() const {
  return raw_ptr()->value_[0];
}

int32_t Int32x4::y() const {
  return raw_ptr()->value_[1];
}

int32_t Int32x4::z() const {
  return raw_ptr()->value_[2];
}

int32_t Int32x4::w() const {
  return raw_ptr()->value_[3];
}

simd128_value_t Int32x4::value() const {
  return ReadUnaligned(
      reinterpret_cast<const simd128_value_t*>(&raw_ptr()->value_));
}

void Int32x4::set_value(simd128_value_t value) const {
  StoreUnaligned(reinterpret_cast<simd128_value_t*>(&raw()->ptr()->value_),
                 value);
}

const char* Int32x4::ToCString() const {
  int32_t _x = x();
  int32_t _y = y();
  int32_t _z = z();
  int32_t _w = w();
  return OS::SCreate(Thread::Current()->zone(), "[%08x, %08x, %08x, %08x]", _x,
                     _y, _z, _w);
}

RawFloat64x2* Float64x2::New(double value0, double value1, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float64x2_class() !=
         Class::null());
  Float64x2& result = Float64x2::Handle();
  {
    RawObject* raw =
        Object::Allocate(Float64x2::kClassId, Float64x2::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_x(value0);
  result.set_y(value1);
  return result.raw();
}

RawFloat64x2* Float64x2::New(simd128_value_t value, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float64x2_class() !=
         Class::null());
  Float64x2& result = Float64x2::Handle();
  {
    RawObject* raw =
        Object::Allocate(Float64x2::kClassId, Float64x2::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(value);
  return result.raw();
}

double Float64x2::x() const {
  return raw_ptr()->value_[0];
}

double Float64x2::y() const {
  return raw_ptr()->value_[1];
}

void Float64x2::set_x(double x) const {
  StoreNonPointer(&raw_ptr()->value_[0], x);
}

void Float64x2::set_y(double y) const {
  StoreNonPointer(&raw_ptr()->value_[1], y);
}

simd128_value_t Float64x2::value() const {
  return simd128_value_t().readFrom(&raw_ptr()->value_[0]);
}

void Float64x2::set_value(simd128_value_t value) const {
  StoreSimd128(&raw_ptr()->value_[0], value);
}

const char* Float64x2::ToCString() const {
  double _x = x();
  double _y = y();
  return OS::SCreate(Thread::Current()->zone(), "[%f, %f]", _x, _y);
}

const intptr_t TypedData::element_size_table[TypedData::kNumElementSizes] = {
    1,   // kTypedDataInt8ArrayCid.
    1,   // kTypedDataUint8ArrayCid.
    1,   // kTypedDataUint8ClampedArrayCid.
    2,   // kTypedDataInt16ArrayCid.
    2,   // kTypedDataUint16ArrayCid.
    4,   // kTypedDataInt32ArrayCid.
    4,   // kTypedDataUint32ArrayCid.
    8,   // kTypedDataInt64ArrayCid.
    8,   // kTypedDataUint64ArrayCid.
    4,   // kTypedDataFloat32ArrayCid.
    8,   // kTypedDataFloat64ArrayCid.
    16,  // kTypedDataFloat32x4ArrayCid.
    16,  // kTypedDataInt32x4ArrayCid.
    16,  // kTypedDataFloat64x2ArrayCid,
};

bool TypedData::CanonicalizeEquals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    // Both handles point to the same raw instance.
    return true;
  }

  if (!other.IsTypedData() || other.IsNull()) {
    return false;
  }

  const TypedData& other_typed_data = TypedData::Cast(other);

  if (this->ElementType() != other_typed_data.ElementType()) {
    return false;
  }

  const intptr_t len = this->LengthInBytes();
  if (len != other_typed_data.LengthInBytes()) {
    return false;
  }
  NoSafepointScope no_safepoint;
  return (len == 0) ||
         (memcmp(DataAddr(0), other_typed_data.DataAddr(0), len) == 0);
}

uword TypedData::ComputeCanonicalTableHash() const {
  const intptr_t len = this->LengthInBytes();
  ASSERT(len != 0);
  uword hash = len;
  for (intptr_t i = 0; i < len; i++) {
    hash = CombineHashes(len, GetUint8(i));
  }
  return FinalizeHash(hash, kHashBits);
}

RawTypedData* TypedData::New(intptr_t class_id,
                             intptr_t len,
                             Heap::Space space) {
  if (len < 0 || len > TypedData::MaxElements(class_id)) {
    FATAL1("Fatal error in TypedData::New: invalid len %" Pd "\n", len);
  }
  TypedData& result = TypedData::Handle();
  {
    const intptr_t lengthInBytes = len * ElementSizeInBytes(class_id);
    RawObject* raw = Object::Allocate(
        class_id, TypedData::InstanceSize(lengthInBytes), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    if (len > 0) {
      memset(result.DataAddr(0), 0, lengthInBytes);
    }
  }
  return result.raw();
}

RawTypedData* TypedData::EmptyUint32Array(Thread* thread) {
  ASSERT(thread != NULL);
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  ASSERT(isolate->object_store() != NULL);
  if (isolate->object_store()->empty_uint32_array() != TypedData::null()) {
    // Already created.
    return isolate->object_store()->empty_uint32_array();
  }
  const TypedData& array = TypedData::Handle(
      thread->zone(), TypedData::New(kTypedDataUint32ArrayCid, 0, Heap::kOld));
  isolate->object_store()->set_empty_uint32_array(array);
  return array.raw();
}

const char* TypedData::ToCString() const {
  switch (GetClassId()) {
#define CASE_TYPED_DATA_CLASS(clazz)                                           \
  case kTypedData##clazz##Cid:                                                 \
    return #clazz;
    CLASS_LIST_TYPED_DATA(CASE_TYPED_DATA_CLASS);
#undef CASE_TYPED_DATA_CLASS
  }
  return "TypedData";
}

FinalizablePersistentHandle* ExternalTypedData::AddFinalizer(
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback,
    intptr_t external_size) const {
  return dart::AddFinalizer(*this, peer, callback, external_size);
}

RawExternalTypedData* ExternalTypedData::New(intptr_t class_id,
                                             uint8_t* data,
                                             intptr_t len,
                                             Heap::Space space) {
  ExternalTypedData& result = ExternalTypedData::Handle();
  {
    RawObject* raw =
        Object::Allocate(class_id, ExternalTypedData::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetData(data);
  }
  return result.raw();
}

const char* ExternalTypedData::ToCString() const {
  return "ExternalTypedData";
}

RawCapability* Capability::New(uint64_t id, Heap::Space space) {
  Capability& result = Capability::Handle();
  {
    RawObject* raw = Object::Allocate(Capability::kClassId,
                                      Capability::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->id_, id);
  }
  return result.raw();
}

const char* Capability::ToCString() const {
  return "Capability";
}

RawReceivePort* ReceivePort::New(Dart_Port id,
                                 bool is_control_port,
                                 Heap::Space space) {
  ASSERT(id != ILLEGAL_PORT);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const SendPort& send_port =
      SendPort::Handle(zone, SendPort::New(id, thread->isolate()->origin_id()));

  ReceivePort& result = ReceivePort::Handle(zone);
  {
    RawObject* raw = Object::Allocate(ReceivePort::kClassId,
                                      ReceivePort::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StorePointer(&result.raw_ptr()->send_port_, send_port.raw());
  }
  if (is_control_port) {
    PortMap::SetPortState(id, PortMap::kControlPort);
  } else {
    PortMap::SetPortState(id, PortMap::kLivePort);
  }
  return result.raw();
}

const char* ReceivePort::ToCString() const {
  return "ReceivePort";
}

RawSendPort* SendPort::New(Dart_Port id, Heap::Space space) {
  return New(id, Isolate::Current()->origin_id(), space);
}

RawSendPort* SendPort::New(Dart_Port id,
                           Dart_Port origin_id,
                           Heap::Space space) {
  ASSERT(id != ILLEGAL_PORT);
  SendPort& result = SendPort::Handle();
  {
    RawObject* raw =
        Object::Allocate(SendPort::kClassId, SendPort::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->id_, id);
    result.StoreNonPointer(&result.raw_ptr()->origin_id_, origin_id);
  }
  return result.raw();
}

const char* SendPort::ToCString() const {
  return "SendPort";
}

const char* Closure::ToCString() const {
  const Function& fun = Function::Handle(function());
  const bool is_implicit_closure = fun.IsImplicitClosureFunction();
  const char* fun_sig = String::Handle(fun.UserVisibleSignature()).ToCString();
  const char* from = is_implicit_closure ? " from " : "";
  const char* fun_desc = is_implicit_closure ? fun.ToCString() : "";
  return OS::SCreate(Thread::Current()->zone(), "Closure: %s%s%s", fun_sig,
                     from, fun_desc);
}

int64_t Closure::ComputeHash() const {
  Zone* zone = Thread::Current()->zone();
  const Function& func = Function::Handle(zone, function());
  uint32_t result = 0;
  if (func.IsImplicitInstanceClosureFunction()) {
    // Implicit instance closures are not unqiue, so combine function's hash
    // code with identityHashCode of cached receiver.
    result = static_cast<uint32_t>(func.ComputeClosureHash());
    const Context& context = Context::Handle(zone, this->context());
    const Object& receiver = Object::Handle(zone, context.At(0));
    const Object& receiverHash =
        Object::Handle(zone, Instance::Cast(receiver).IdentityHashCode());
    if (receiverHash.IsError()) {
      Exceptions::PropagateError(Error::Cast(receiverHash));
      UNREACHABLE();
    }
    result = CombineHashes(
        result, Integer::Cast(receiverHash).AsTruncatedUint32Value());
  } else {
    // Explicit closures and implicit static closures are unique,
    // so identityHashCode of closure object is good enough.
    const Object& identityHash = Object::Handle(zone, this->IdentityHashCode());
    if (identityHash.IsError()) {
      Exceptions::PropagateError(Error::Cast(identityHash));
      UNREACHABLE();
    }
    result = Integer::Cast(identityHash).AsTruncatedUint32Value();
  }
  return FinalizeHash(result, String::kHashBits);
}

RawClosure* Closure::New(const TypeArguments& instantiator_type_arguments,
                         const TypeArguments& function_type_arguments,
                         const Function& function,
                         const Context& context,
                         Heap::Space space) {
  Closure& result = Closure::Handle();
  {
    RawObject* raw =
        Object::Allocate(Closure::kClassId, Closure::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StorePointer(&result.raw_ptr()->instantiator_type_arguments_,
                        instantiator_type_arguments.raw());
    result.StorePointer(&result.raw_ptr()->function_type_arguments_,
                        function_type_arguments.raw());
    result.StorePointer(&result.raw_ptr()->function_, function.raw());
    result.StorePointer(&result.raw_ptr()->context_, context.raw());
  }
  return result.raw();
}

RawClosure* Closure::New() {
  RawObject* raw =
      Object::Allocate(Closure::kClassId, Closure::InstanceSize(), Heap::kOld);
  return reinterpret_cast<RawClosure*>(raw);
}

intptr_t StackTrace::Length() const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array_);
  return code_array.Length();
}

RawCode* StackTrace::CodeAtFrame(intptr_t frame_index) const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array_);
  return reinterpret_cast<RawCode*>(code_array.At(frame_index));
}

void StackTrace::SetCodeAtFrame(intptr_t frame_index, const Code& code) const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array_);
  code_array.SetAt(frame_index, code);
}

RawSmi* StackTrace::PcOffsetAtFrame(intptr_t frame_index) const {
  const Array& pc_offset_array = Array::Handle(raw_ptr()->pc_offset_array_);
  return reinterpret_cast<RawSmi*>(pc_offset_array.At(frame_index));
}

void StackTrace::SetPcOffsetAtFrame(intptr_t frame_index,
                                    const Smi& pc_offset) const {
  const Array& pc_offset_array = Array::Handle(raw_ptr()->pc_offset_array_);
  pc_offset_array.SetAt(frame_index, pc_offset);
}

void StackTrace::set_async_link(const StackTrace& async_link) const {
  StorePointer(&raw_ptr()->async_link_, async_link.raw());
}

void StackTrace::set_code_array(const Array& code_array) const {
  StorePointer(&raw_ptr()->code_array_, code_array.raw());
}

void StackTrace::set_pc_offset_array(const Array& pc_offset_array) const {
  StorePointer(&raw_ptr()->pc_offset_array_, pc_offset_array.raw());
}

void StackTrace::set_expand_inlined(bool value) const {
  StoreNonPointer(&raw_ptr()->expand_inlined_, value);
}

bool StackTrace::expand_inlined() const {
  return raw_ptr()->expand_inlined_;
}

RawStackTrace* StackTrace::New(const Array& code_array,
                               const Array& pc_offset_array,
                               Heap::Space space) {
  StackTrace& result = StackTrace::Handle();
  {
    RawObject* raw = Object::Allocate(StackTrace::kClassId,
                                      StackTrace::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_code_array(code_array);
  result.set_pc_offset_array(pc_offset_array);
  result.set_expand_inlined(true);  // default.
  return result.raw();
}

RawStackTrace* StackTrace::New(const Array& code_array,
                               const Array& pc_offset_array,
                               const StackTrace& async_link,
                               Heap::Space space) {
  StackTrace& result = StackTrace::Handle();
  {
    RawObject* raw = Object::Allocate(StackTrace::kClassId,
                                      StackTrace::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_async_link(async_link);
  result.set_code_array(code_array);
  result.set_pc_offset_array(pc_offset_array);
  result.set_expand_inlined(true);  // default.
  return result.raw();
}

static void PrintStackTraceFrame(Zone* zone,
                                 ZoneTextBuffer* buffer,
                                 const Function& function,
                                 TokenPosition token_pos,
                                 intptr_t frame_index) {
  const Script& script = Script::Handle(zone, function.script());
  const String& function_name =
      String::Handle(zone, function.QualifiedUserVisibleName());
  const String& url = String::Handle(
      zone, script.IsNull() ? String::New("Kernel") : script.url());
  intptr_t line = -1;
  intptr_t column = -1;
  if (FLAG_precompiled_mode) {
    line = token_pos.value();
  } else {
    if (!script.IsNull() && token_pos.IsSourcePosition()) {
      if (script.HasSource() || script.kind() == RawScript::kKernelTag) {
        script.GetTokenLocation(token_pos.SourcePosition(), &line, &column);
      } else {
        script.GetTokenLocation(token_pos.SourcePosition(), &line, NULL);
      }
    }
  }
  if (column >= 0) {
    buffer->Printf("#%-6" Pd " %s (%s:%" Pd ":%" Pd ")\n", frame_index,
                   function_name.ToCString(), url.ToCString(), line, column);
  } else if (line >= 0) {
    buffer->Printf("#%-6" Pd " %s (%s:%" Pd ")\n", frame_index,
                   function_name.ToCString(), url.ToCString(), line);
  } else {
    buffer->Printf("#%-6" Pd " %s (%s)\n", frame_index,
                   function_name.ToCString(), url.ToCString());
  }
}

const char* StackTrace::ToDartCString(const StackTrace& stack_trace_in) {
  Zone* zone = Thread::Current()->zone();
  StackTrace& stack_trace = StackTrace::Handle(zone, stack_trace_in.raw());
  Function& function = Function::Handle(zone);
  Code& code = Code::Handle(zone);

  GrowableArray<const Function*> inlined_functions;
  GrowableArray<TokenPosition> inlined_token_positions;
  ZoneTextBuffer buffer(zone, 1024);

  // Iterate through the stack frames and create C string description
  // for each frame.
  intptr_t frame_index = 0;
  do {
    for (intptr_t i = 0; i < stack_trace.Length(); i++) {
      code = stack_trace.CodeAtFrame(i);
      if (code.IsNull()) {
        // Check for a null function, which indicates a gap in a StackOverflow
        // or OutOfMemory trace.
        if ((i < (stack_trace.Length() - 1)) &&
            (stack_trace.CodeAtFrame(i + 1) != Code::null())) {
          buffer.AddString("...\n...\n");
          ASSERT(stack_trace.PcOffsetAtFrame(i) != Smi::null());
          // To account for gap frames.
          frame_index += Smi::Value(stack_trace.PcOffsetAtFrame(i));
        }
      } else if (code.raw() ==
                 StubCode::AsynchronousGapMarker_entry()->code()) {
        buffer.AddString("<asynchronous suspension>\n");
        // The frame immediately after the asynchronous gap marker is the
        // identical to the frame above the marker. Skip the frame to enhance
        // the readability of the trace.
        i++;
      } else {
        ASSERT(code.IsFunctionCode());
        intptr_t pc_offset = Smi::Value(stack_trace.PcOffsetAtFrame(i));
        if (code.is_optimized() && stack_trace.expand_inlined()) {
          code.GetInlinedFunctionsAtReturnAddress(pc_offset, &inlined_functions,
                                                  &inlined_token_positions);
          ASSERT(inlined_functions.length() >= 1);
          for (intptr_t j = inlined_functions.length() - 1; j >= 0; j--) {
            if (inlined_functions[j]->is_visible() ||
                FLAG_show_invisible_frames) {
              PrintStackTraceFrame(zone, &buffer, *inlined_functions[j],
                                   inlined_token_positions[j], frame_index);
              frame_index++;
            }
          }
        } else {
          function = code.function();
          if (function.is_visible() || FLAG_show_invisible_frames) {
            uword pc = code.PayloadStart() + pc_offset;
            const TokenPosition token_pos = code.GetTokenIndexOfPC(pc);
            PrintStackTraceFrame(zone, &buffer, function, token_pos,
                                 frame_index);
            frame_index++;
          }
        }
      }
    }
    // Follow the link.
    stack_trace ^= stack_trace.async_link();
  } while (!stack_trace.IsNull());

  return buffer.buffer();
}

const char* StackTrace::ToDwarfCString(const StackTrace& stack_trace_in) {
#if defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
  Zone* zone = Thread::Current()->zone();
  StackTrace& stack_trace = StackTrace::Handle(zone, stack_trace_in.raw());
  Code& code = Code::Handle(zone);
  ZoneTextBuffer buffer(zone, 1024);

  // The Dart standard requires the output of StackTrace.toString to include
  // all pending activations with precise source locations (i.e., to expand
  // inlined frames and provide line and column numbers).
  buffer.Printf(
      "Warning: This VM has been configured to produce stack traces "
      "that violate the Dart standard.\n");
  // This prologue imitates Android's debuggerd to make it possible to paste
  // the stack trace into ndk-stack.
  buffer.Printf(
      "*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***\n");
  OSThread* thread = OSThread::Current();
  buffer.Printf("pid: %" Pd ", tid: %" Pd ", name %s\n", OS::ProcessId(),
                OSThread::ThreadIdToIntPtr(thread->id()), thread->name());
  intptr_t frame_index = 0;
  do {
    for (intptr_t i = 0; i < stack_trace.Length(); i++) {
      code = stack_trace.CodeAtFrame(i);
      if (code.IsNull()) {
        // Check for a null function, which indicates a gap in a StackOverflow
        // or OutOfMemory trace.
        if ((i < (stack_trace.Length() - 1)) &&
            (stack_trace.CodeAtFrame(i + 1) != Code::null())) {
          buffer.AddString("...\n...\n");
          ASSERT(stack_trace.PcOffsetAtFrame(i) != Smi::null());
          // To account for gap frames.
          frame_index += Smi::Value(stack_trace.PcOffsetAtFrame(i));
        }
      } else if (code.raw() ==
                 StubCode::AsynchronousGapMarker_entry()->code()) {
        buffer.AddString("<asynchronous suspension>\n");
        // The frame immediately after the asynchronous gap marker is the
        // identical to the frame above the marker. Skip the frame to enhance
        // the readability of the trace.
        i++;
      } else {
        intptr_t pc_offset = Smi::Value(stack_trace.PcOffsetAtFrame(i));
        // This output is formatted like Android's debuggerd. Note debuggerd
        // prints call addresses instead of return addresses.
        uword return_addr = code.PayloadStart() + pc_offset;
        uword call_addr = return_addr - 1;
        uword dso_base;
        char* dso_name;
        if (NativeSymbolResolver::LookupSharedObject(call_addr, &dso_base,
                                                     &dso_name)) {
          uword dso_offset = call_addr - dso_base;
          buffer.Printf("    #%02" Pd " pc %" Pp "  %s\n", frame_index,
                        dso_offset, dso_name);
          NativeSymbolResolver::FreeSymbolName(dso_name);
        } else {
          buffer.Printf("    #%02" Pd " pc %" Pp "  <unknown>\n", frame_index,
                        call_addr);
        }
        frame_index++;
      }
    }
    // Follow the link.
    stack_trace ^= stack_trace.async_link();
  } while (!stack_trace.IsNull());

  return buffer.buffer();
#else
  UNREACHABLE();
  return NULL;
#endif  // defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
}

const char* StackTrace::ToCString() const {
#if defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_dwarf_stack_traces) {
    return ToDwarfCString(*this);
  }
#endif
  return ToDartCString(*this);
}

void RegExp::set_pattern(const String& pattern) const {
  StorePointer(&raw_ptr()->pattern_, pattern.raw());
}

void RegExp::set_function(intptr_t cid,
                          bool sticky,
                          const Function& value) const {
  StorePointer(FunctionAddr(cid, sticky), value.raw());
}

void RegExp::set_bytecode(bool is_one_byte,
                          bool sticky,
                          const TypedData& bytecode) const {
  if (sticky) {
    if (is_one_byte) {
      StorePointer(&raw_ptr()->one_byte_sticky_.bytecode_, bytecode.raw());
    } else {
      StorePointer(&raw_ptr()->two_byte_sticky_.bytecode_, bytecode.raw());
    }
  } else {
    if (is_one_byte) {
      StorePointer(&raw_ptr()->one_byte_.bytecode_, bytecode.raw());
    } else {
      StorePointer(&raw_ptr()->two_byte_.bytecode_, bytecode.raw());
    }
  }
}

void RegExp::set_num_bracket_expressions(intptr_t value) const {
  StoreSmi(&raw_ptr()->num_bracket_expressions_, Smi::New(value));
}

RawRegExp* RegExp::New(Heap::Space space) {
  RegExp& result = RegExp::Handle();
  {
    RawObject* raw =
        Object::Allocate(RegExp::kClassId, RegExp::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_type(kUnitialized);
    result.set_flags(0);
    result.set_num_registers(-1);
  }
  return result.raw();
}

void* RegExp::GetDataStartAddress() const {
  intptr_t addr = reinterpret_cast<intptr_t>(raw_ptr());
  return reinterpret_cast<void*>(addr + sizeof(RawRegExp));
}

RawRegExp* RegExp::FromDataStartAddress(void* data) {
  RegExp& regexp = RegExp::Handle();
  intptr_t addr = reinterpret_cast<intptr_t>(data) - sizeof(RawRegExp);
  regexp ^= RawObject::FromAddr(addr);
  return regexp.raw();
}

const char* RegExp::Flags() const {
  switch (flags()) {
    case kGlobal | kIgnoreCase | kMultiLine:
    case kIgnoreCase | kMultiLine:
      return "im";
    case kGlobal | kIgnoreCase:
    case kIgnoreCase:
      return "i";
    case kGlobal | kMultiLine:
    case kMultiLine:
      return "m";
    default:
      break;
  }
  return "";
}

bool RegExp::CanonicalizeEquals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    return true;  // "===".
  }
  if (other.IsNull() || !other.IsRegExp()) {
    return false;
  }
  const RegExp& other_js = RegExp::Cast(other);
  // Match the pattern.
  const String& str1 = String::Handle(pattern());
  const String& str2 = String::Handle(other_js.pattern());
  if (!str1.Equals(str2)) {
    return false;
  }
  // Match the flags.
  if ((is_global() != other_js.is_global()) ||
      (is_ignore_case() != other_js.is_ignore_case()) ||
      (is_multi_line() != other_js.is_multi_line())) {
    return false;
  }
  return true;
}

const char* RegExp::ToCString() const {
  const String& str = String::Handle(pattern());
  return OS::SCreate(Thread::Current()->zone(), "RegExp: pattern=%s flags=%s",
                     str.ToCString(), Flags());
}

RawWeakProperty* WeakProperty::New(Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->weak_property_class() !=
         Class::null());
  RawObject* raw = Object::Allocate(WeakProperty::kClassId,
                                    WeakProperty::InstanceSize(), space);
  RawWeakProperty* result = reinterpret_cast<RawWeakProperty*>(raw);
  result->ptr()->next_ = 0;  // Init the list to NULL.
  return result;
}

const char* WeakProperty::ToCString() const {
  return "_WeakProperty";
}

RawAbstractType* MirrorReference::GetAbstractTypeReferent() const {
  ASSERT(Object::Handle(referent()).IsAbstractType());
  return AbstractType::Cast(Object::Handle(referent())).raw();
}

RawClass* MirrorReference::GetClassReferent() const {
  ASSERT(Object::Handle(referent()).IsClass());
  return Class::Cast(Object::Handle(referent())).raw();
}

RawField* MirrorReference::GetFieldReferent() const {
  ASSERT(Object::Handle(referent()).IsField());
  return Field::Cast(Object::Handle(referent())).raw();
}

RawFunction* MirrorReference::GetFunctionReferent() const {
  ASSERT(Object::Handle(referent()).IsFunction());
  return Function::Cast(Object::Handle(referent())).raw();
}

RawLibrary* MirrorReference::GetLibraryReferent() const {
  ASSERT(Object::Handle(referent()).IsLibrary());
  return Library::Cast(Object::Handle(referent())).raw();
}

RawTypeParameter* MirrorReference::GetTypeParameterReferent() const {
  ASSERT(Object::Handle(referent()).IsTypeParameter());
  return TypeParameter::Cast(Object::Handle(referent())).raw();
}

RawMirrorReference* MirrorReference::New(const Object& referent,
                                         Heap::Space space) {
  MirrorReference& result = MirrorReference::Handle();
  {
    RawObject* raw = Object::Allocate(MirrorReference::kClassId,
                                      MirrorReference::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_referent(referent);
  return result.raw();
}

const char* MirrorReference::ToCString() const {
  return "_MirrorReference";
}

void UserTag::MakeActive() const {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  isolate->set_current_tag(*this);
}

RawUserTag* UserTag::New(const String& label, Heap::Space space) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  // Canonicalize by name.
  UserTag& result = UserTag::Handle(FindTagInIsolate(thread, label));
  if (!result.IsNull()) {
    // Tag already exists, return existing instance.
    return result.raw();
  }
  if (TagTableIsFull(thread)) {
    const String& error = String::Handle(String::NewFormatted(
        "UserTag instance limit (%" Pd ") reached.", UserTags::kMaxUserTags));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, error);
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
  }
  // No tag with label exists, create and register with isolate tag table.
  {
    RawObject* raw =
        Object::Allocate(UserTag::kClassId, UserTag::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_label(label);
  AddTagToIsolate(thread, result);
  return result.raw();
}

RawUserTag* UserTag::DefaultTag() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  if (isolate->default_tag() != UserTag::null()) {
    // Already created.
    return isolate->default_tag();
  }
  // Create default tag.
  const UserTag& result =
      UserTag::Handle(zone, UserTag::New(Symbols::Default()));
  ASSERT(result.tag() == UserTags::kDefaultUserTag);
  isolate->set_default_tag(result);
  return result.raw();
}

RawUserTag* UserTag::FindTagInIsolate(Thread* thread, const String& label) {
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table =
      GrowableObjectArray::Handle(zone, isolate->tag_table());
  UserTag& other = UserTag::Handle(zone);
  String& tag_label = String::Handle(zone);
  for (intptr_t i = 0; i < tag_table.Length(); i++) {
    other ^= tag_table.At(i);
    ASSERT(!other.IsNull());
    tag_label ^= other.label();
    ASSERT(!tag_label.IsNull());
    if (tag_label.Equals(label)) {
      return other.raw();
    }
  }
  return UserTag::null();
}

void UserTag::AddTagToIsolate(Thread* thread, const UserTag& tag) {
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table =
      GrowableObjectArray::Handle(zone, isolate->tag_table());
  ASSERT(!TagTableIsFull(thread));
#if defined(DEBUG)
  // Verify that no existing tag has the same tag id.
  UserTag& other = UserTag::Handle(thread->zone());
  for (intptr_t i = 0; i < tag_table.Length(); i++) {
    other ^= tag_table.At(i);
    ASSERT(!other.IsNull());
    ASSERT(tag.tag() != other.tag());
  }
#endif
  // Generate the UserTag tag id by taking the length of the isolate's
  // tag table + kUserTagIdOffset.
  uword tag_id = tag_table.Length() + UserTags::kUserTagIdOffset;
  ASSERT(tag_id >= UserTags::kUserTagIdOffset);
  ASSERT(tag_id < (UserTags::kUserTagIdOffset + UserTags::kMaxUserTags));
  tag.set_tag(tag_id);
  tag_table.Add(tag);
}

bool UserTag::TagTableIsFull(Thread* thread) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table =
      GrowableObjectArray::Handle(thread->zone(), isolate->tag_table());
  ASSERT(tag_table.Length() <= UserTags::kMaxUserTags);
  return tag_table.Length() == UserTags::kMaxUserTags;
}

RawUserTag* UserTag::FindTagById(uword tag_id) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table =
      GrowableObjectArray::Handle(zone, isolate->tag_table());
  UserTag& tag = UserTag::Handle(zone);
  for (intptr_t i = 0; i < tag_table.Length(); i++) {
    tag ^= tag_table.At(i);
    if (tag.tag() == tag_id) {
      return tag.raw();
    }
  }
  return UserTag::null();
}

const char* UserTag::ToCString() const {
  const String& tag_label = String::Handle(label());
  return tag_label.ToCString();
}

}  // namespace dart
