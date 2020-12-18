// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object.h"

#include <memory>

#include "include/dart_api.h"
#include "lib/stacktrace.h"
#include "platform/assert.h"
#include "platform/text_buffer.h"
#include "platform/unaligned.h"
#include "platform/unicode.h"
#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/canonical_tables.h"
#include "vm/class_finalizer.h"
#include "vm/code_comments.h"
#include "vm/code_descriptors.h"
#include "vm/code_observers.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/runtime_api.h"
#include "vm/cpu.h"
#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/datastream.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/double_conversion.h"
#include "vm/elf.h"
#include "vm/exceptions.h"
#include "vm/growable_array.h"
#include "vm/hash.h"
#include "vm/hash_table.h"
#include "vm/heap/become.h"
#include "vm/heap/heap.h"
#include "vm/heap/weak_code.h"
#include "vm/image_snapshot.h"
#include "vm/isolate_reload.h"
#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/kernel_isolate.h"
#include "vm/kernel_loader.h"
#include "vm/native_symbol.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/profiler.h"
#include "vm/resolver.h"
#include "vm/reusable_handles.h"
#include "vm/runtime_entry.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/code_statistics.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/frontend/kernel_fingerprints.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/compiler/intrinsifier.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DEFINE_FLAG(int,
            huge_method_cutoff_in_code_size,
            200000,
            "Huge method cutoff in unoptimized code size (in bytes).");
DEFINE_FLAG(
    bool,
    show_internal_names,
    false,
    "Show names of internal classes (e.g. \"OneByteString\") in error messages "
    "instead of showing the corresponding interface names (e.g. \"String\"). "
    "Also show legacy nullability in type names.");
DEFINE_FLAG(bool, use_lib_cache, false, "Use library name cache");
DEFINE_FLAG(bool, use_exp_cache, false, "Use library exported name cache");

DEFINE_FLAG(bool,
            remove_script_timestamps_for_test,
            false,
            "Remove script timestamps to allow for deterministic testing.");

DECLARE_FLAG(bool, dual_map_code);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, trace_deoptimization);
DECLARE_FLAG(bool, trace_deoptimization_verbose);
DECLARE_FLAG(bool, trace_reload);
DECLARE_FLAG(bool, write_protect_code);
DECLARE_FLAG(bool, precompiled_mode);
DECLARE_FLAG(int, max_polymorphic_checks);

static const char* const kGetterPrefix = "get:";
static const intptr_t kGetterPrefixLength = strlen(kGetterPrefix);
static const char* const kSetterPrefix = "set:";
static const intptr_t kSetterPrefixLength = strlen(kSetterPrefix);
static const char* const kInitPrefix = "init:";
static const intptr_t kInitPrefixLength = strlen(kInitPrefix);

// A cache of VM heap allocated preinitialized empty ic data entry arrays.
ArrayPtr ICData::cached_icdata_arrays_[kCachedICDataArrayCount];
// A VM heap allocated preinitialized empty subtype entry array.
ArrayPtr SubtypeTestCache::cached_array_;

cpp_vtable Object::builtin_vtables_[kNumPredefinedCids] = {};

// These are initialized to a value that will force a illegal memory access if
// they are being used.
#if defined(RAW_NULL)
#error RAW_NULL should not be defined.
#endif
#define RAW_NULL static_cast<uword>(kHeapObjectTag)

#define CHECK_ERROR(error)                                                     \
  {                                                                            \
    ErrorPtr err = (error);                                                    \
    if (err != Error::null()) {                                                \
      return err;                                                              \
    }                                                                          \
  }

#define DEFINE_SHARED_READONLY_HANDLE(Type, name)                              \
  Type* Object::name##_ = nullptr;
SHARED_READONLY_HANDLES_LIST(DEFINE_SHARED_READONLY_HANDLE)
#undef DEFINE_SHARED_READONLY_HANDLE

ObjectPtr Object::null_ = static_cast<ObjectPtr>(RAW_NULL);
BoolPtr Object::true_ = static_cast<BoolPtr>(RAW_NULL);
BoolPtr Object::false_ = static_cast<BoolPtr>(RAW_NULL);
ClassPtr Object::class_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::dynamic_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::void_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::type_arguments_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::patch_class_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::function_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::closure_data_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::signature_data_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::ffi_trampoline_data_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::field_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::script_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::library_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::namespace_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::kernel_program_info_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::code_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::instructions_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::instructions_section_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::object_pool_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::pc_descriptors_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::code_source_map_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::compressed_stackmaps_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::var_descriptors_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::exception_handlers_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::context_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::context_scope_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::singletargetcache_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::unlinkedcall_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::monomorphicsmiablecall_class_ =
    static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::icdata_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::megamorphic_cache_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::subtypetestcache_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::loadingunit_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::api_error_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::language_error_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::unhandled_exception_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::unwind_error_class_ = static_cast<ClassPtr>(RAW_NULL);
ClassPtr Object::weak_serialization_reference_class_ =
    static_cast<ClassPtr>(RAW_NULL);

const double MegamorphicCache::kLoadFactor = 0.50;

static void AppendSubString(BaseTextBuffer* buffer,
                            const char* name,
                            intptr_t start_pos,
                            intptr_t len) {
  buffer->Printf("%.*s", static_cast<int>(len), &name[start_pos]);
}

// Remove private keys, but retain getter/setter/constructor/mixin manglings.
StringPtr String::RemovePrivateKey(const String& name) {
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
// For extension methods the following demangling is done
//   ext|func -> ext.func (instance extension method)
//   ext|get#prop -> ext.prop (instance extension getter)
//   ext|set#prop -> ext.prop= (instance extension setter)
//   ext|sfunc -> ext.sfunc (static extension method)
//   get:ext|sprop -> ext.sprop (static extension getter)
//   set:ext|sprop -> ext.sprop= (static extension setter)
//
const char* String::ScrubName(const String& name, bool is_extension) {
  Thread* thread = Thread::Current();
  NoSafepointScope no_safepoint(thread);
  Zone* zone = thread->zone();
  ZoneTextBuffer printer(zone);

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (name.Equals(Symbols::TopLevel())) {
    // Name of invisible top-level class.
    return "";
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  const char* cname = name.ToCString();
  ASSERT(strlen(cname) == static_cast<size_t>(name.Length()));
  const intptr_t name_len = name.Length();
  // First remove all private name mangling and if 'is_extension' is true
  // substitute the first '|' character with '.'.
  intptr_t start_pos = 0;
  intptr_t sum_segment_len = 0;
  for (intptr_t i = 0; i < name_len; i++) {
    if ((cname[i] == '@') && ((i + 1) < name_len) && (cname[i + 1] >= '0') &&
        (cname[i + 1] <= '9')) {
      // Append the current segment to the unmangled name.
      const intptr_t segment_len = i - start_pos;
      sum_segment_len += segment_len;
      AppendSubString(&printer, cname, start_pos, segment_len);
      // Advance until past the name mangling. The private keys are only
      // numbers so we skip until the first non-number.
      i++;  // Skip the '@'.
      while ((i < name.Length()) && (name.CharAt(i) >= '0') &&
             (name.CharAt(i) <= '9')) {
        i++;
      }
      start_pos = i;
      i--;  // Account for for-loop increment.
    } else if (is_extension && cname[i] == '|') {
      // Append the current segment to the unmangled name.
      const intptr_t segment_len = i - start_pos;
      AppendSubString(&printer, cname, start_pos, segment_len);
      // Append the '.' character (replaces '|' with '.').
      AppendSubString(&printer, ".", 0, 1);
      start_pos = i + 1;
      // Account for length of segments added so far.
      sum_segment_len += (segment_len + 1);
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
    AppendSubString(&printer, cname, start_pos, segment_len);
  }
  if (unmangled_name == NULL) {
    // Merge unmangled_segments.
    unmangled_name = printer.buffer();
  }

  printer.Clear();
  intptr_t start = 0;
  intptr_t final_len = 0;
  intptr_t len = sum_segment_len;
  bool is_setter = false;
  if (is_extension) {
    // First scan till we see the '.' character.
    for (intptr_t i = 0; i < len; i++) {
      if (unmangled_name[i] == '.') {
        intptr_t slen = i + 1;
        intptr_t plen = slen - start;
        AppendSubString(&printer, unmangled_name, start, plen);
        final_len = plen;
        unmangled_name += slen;
        len -= slen;
        break;
      } else if (unmangled_name[i] == ':') {
        if (start != 0) {
          // Reset and break.
          start = 0;
          is_setter = false;
          break;
        }
        if (unmangled_name[0] == 's') {
          is_setter = true;
        }
        start = i + 1;
      }
    }
  }
  intptr_t dot_pos = -1;  // Position of '.' in the name, if any.
  start = 0;
  for (intptr_t i = start; i < len; i++) {
    if (unmangled_name[i] == ':' ||
        (is_extension && unmangled_name[i] == '#')) {
      if (start != 0) {
        // Reset and break.
        start = 0;
        dot_pos = -1;
        break;
      }
      ASSERT(start == 0);  // Only one : is possible in getters or setters.
      if (unmangled_name[0] == 's') {
        ASSERT(!is_setter);
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

  if (!is_extension && (start == 0) && (dot_pos == -1)) {
    // This unmangled_name is fine as it is.
    return unmangled_name;
  }

  // Drop the trailing dot if needed.
  intptr_t end = ((dot_pos + 1) == len) ? dot_pos : len;

  intptr_t substr_len = end - start;
  final_len += substr_len;
  AppendSubString(&printer, unmangled_name, start, substr_len);
  if (is_setter) {
    const char* equals = Symbols::Equals().ToCString();
    const intptr_t equals_len = strlen(equals);
    AppendSubString(&printer, equals, 0, equals_len);
    final_len += equals_len;
  }

  return printer.buffer();
}

StringPtr String::ScrubNameRetainPrivate(const String& name,
                                         bool is_extension) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  intptr_t len = name.Length();
  intptr_t start = 0;
  intptr_t at_pos = -1;  // Position of '@' in the name, if any.
  bool is_setter = false;

  String& result = String::Handle();

  // If extension strip out the leading prefix e.g" ext|func would strip out
  // 'ext|'.
  if (is_extension) {
    // First scan till we see the '|' character.
    for (intptr_t i = 0; i < len; i++) {
      if (name.CharAt(i) == '|') {
        result = String::SubString(name, start, (i - start));
        result = String::Concat(result, Symbols::Dot());
        start = i + 1;
        break;
      } else if (name.CharAt(i) == ':') {
        if (start != 0) {
          // Reset and break.
          start = 0;
          is_setter = false;
          break;
        }
        if (name.CharAt(0) == 's') {
          is_setter = true;
        }
        start = i + 1;
      }
    }
  }

  for (intptr_t i = start; i < len; i++) {
    if (name.CharAt(i) == ':' || (is_extension && name.CharAt(i) == '#')) {
      // Only one : is possible in getters or setters.
      ASSERT(is_extension || start == 0);
      if (name.CharAt(start) == 's') {
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

  if (is_extension) {
    const String& fname =
        String::Handle(String::SubString(name, start, (len - start)));
    result = String::Concat(result, fname);
  } else {
    result = String::SubString(name, start, (len - start));
  }

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

void Object::InitNullAndBool(Isolate* isolate) {
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
    null_ = static_cast<InstancePtr>(address + kHeapObjectTag);
    // The call below is using 'null_' to initialize itself.
    InitializeObject(address, kNullCid, Instance::InstanceSize());
    null_->ptr()->SetCanonical();
  }

  // Allocate and initialize the bool instances.
  // These must be allocated such that at kBoolValueBitPosition, the address
  // of true is 0 and the address of false is 1, and their addresses are
  // otherwise identical.
  {
    // Allocate a dummy bool object to give true the desired alignment.
    uword address = heap->Allocate(Bool::InstanceSize(), Heap::kOld);
    InitializeObject(address, kBoolCid, Bool::InstanceSize());
    static_cast<BoolPtr>(address + kHeapObjectTag)->ptr()->value_ = false;
  }
  {
    // Allocate true.
    uword address = heap->Allocate(Bool::InstanceSize(), Heap::kOld);
    true_ = static_cast<BoolPtr>(address + kHeapObjectTag);
    InitializeObject(address, kBoolCid, Bool::InstanceSize());
    true_->ptr()->value_ = true;
    true_->ptr()->SetCanonical();
  }
  {
    // Allocate false.
    uword address = heap->Allocate(Bool::InstanceSize(), Heap::kOld);
    false_ = static_cast<BoolPtr>(address + kHeapObjectTag);
    InitializeObject(address, kBoolCid, Bool::InstanceSize());
    false_->ptr()->value_ = false;
    false_->ptr()->SetCanonical();
  }

  // Check that the objects have been allocated at appropriate addresses.
  ASSERT(static_cast<uword>(true_) ==
         static_cast<uword>(null_) + kTrueOffsetFromNull);
  ASSERT(static_cast<uword>(false_) ==
         static_cast<uword>(null_) + kFalseOffsetFromNull);
  ASSERT((static_cast<uword>(true_) & kBoolValueMask) == 0);
  ASSERT((static_cast<uword>(false_) & kBoolValueMask) != 0);
  ASSERT(static_cast<uword>(false_) ==
         (static_cast<uword>(true_) | kBoolValueMask));
}

void Object::InitVtables() {
  {
    Object fake_handle;
    builtin_vtables_[kObjectCid] = fake_handle.vtable();
  }

#define INIT_VTABLE(clazz)                                                     \
  {                                                                            \
    clazz fake_handle;                                                         \
    builtin_vtables_[k##clazz##Cid] = fake_handle.vtable();                    \
  }
  CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY(INIT_VTABLE)
#undef INIT_VTABLE

#define INIT_VTABLE(clazz)                                                     \
  {                                                                            \
    Array fake_handle;                                                         \
    builtin_vtables_[k##clazz##Cid] = fake_handle.vtable();                    \
  }
  CLASS_LIST_ARRAYS(INIT_VTABLE)
#undef INIT_VTABLE

#define INIT_VTABLE(clazz)                                                     \
  {                                                                            \
    String fake_handle;                                                        \
    builtin_vtables_[k##clazz##Cid] = fake_handle.vtable();                    \
  }
  CLASS_LIST_STRINGS(INIT_VTABLE)
#undef INIT_VTABLE

  {
    Instance fake_handle;
    builtin_vtables_[kFfiNativeTypeCid] = fake_handle.vtable();
  }

#define INIT_VTABLE(clazz)                                                     \
  {                                                                            \
    Instance fake_handle;                                                      \
    builtin_vtables_[kFfi##clazz##Cid] = fake_handle.vtable();                 \
  }
  CLASS_LIST_FFI_TYPE_MARKER(INIT_VTABLE)
#undef INIT_VTABLE

  {
    Instance fake_handle;
    builtin_vtables_[kFfiNativeFunctionCid] = fake_handle.vtable();
  }

  {
    Pointer fake_handle;
    builtin_vtables_[kFfiPointerCid] = fake_handle.vtable();
  }

  {
    DynamicLibrary fake_handle;
    builtin_vtables_[kFfiDynamicLibraryCid] = fake_handle.vtable();
  }

#define INIT_VTABLE(clazz)                                                     \
  {                                                                            \
    TypedData fake_internal_handle;                                            \
    builtin_vtables_[kTypedData##clazz##Cid] = fake_internal_handle.vtable();  \
    TypedDataView fake_view_handle;                                            \
    builtin_vtables_[kTypedData##clazz##ViewCid] = fake_view_handle.vtable();  \
    ExternalTypedData fake_external_handle;                                    \
    builtin_vtables_[kExternalTypedData##clazz##Cid] =                         \
        fake_external_handle.vtable();                                         \
  }
  CLASS_LIST_TYPED_DATA(INIT_VTABLE)
#undef INIT_VTABLE

  {
    TypedDataView fake_handle;
    builtin_vtables_[kByteDataViewCid] = fake_handle.vtable();
  }

  {
    Instance fake_handle;
    builtin_vtables_[kByteBufferCid] = fake_handle.vtable();
    builtin_vtables_[kNullCid] = fake_handle.vtable();
    builtin_vtables_[kDynamicCid] = fake_handle.vtable();
    builtin_vtables_[kVoidCid] = fake_handle.vtable();
    builtin_vtables_[kNeverCid] = fake_handle.vtable();
  }
}

void Object::Init(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  InitVtables();

  Heap* heap = isolate->heap();

// Allocate the read only object handles here.
#define INITIALIZE_SHARED_READONLY_HANDLE(Type, name)                          \
  name##_ = Type::ReadOnlyHandle();
  SHARED_READONLY_HANDLES_LIST(INITIALIZE_SHARED_READONLY_HANDLE)
#undef INITIALIZE_SHARED_READONLY_HANDLE

  *null_object_ = Object::null();
  *null_array_ = Array::null();
  *null_string_ = String::null();
  *null_instance_ = Instance::null();
  *null_function_ = Function::null();
  *null_type_arguments_ = TypeArguments::null();
  *empty_type_arguments_ = TypeArguments::null();
  *null_abstract_type_ = AbstractType::null();
  *null_compressed_stackmaps_ = CompressedStackMaps::null();
  *bool_true_ = true_;
  *bool_false_ = false_;

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
    class_class_ = static_cast<ClassPtr>(address + kHeapObjectTag);
    InitializeObject(address, Class::kClassId, size);

    Class fake;
    // Initialization from Class::New<Class>.
    // Directly set raw_ to break a circular dependency: SetRaw will attempt
    // to lookup class class in the class table where it is not registered yet.
    cls.raw_ = class_class_;
    ASSERT(builtin_vtables_[kClassCid] == fake.vtable());
    cls.set_instance_size(
        Class::InstanceSize(),
        compiler::target::RoundedAllocationSize(RTN::Class::InstanceSize()));
    const intptr_t host_next_field_offset = Class::NextFieldOffset();
    const intptr_t target_next_field_offset = RTN::Class::NextFieldOffset();
    cls.set_next_field_offset(host_next_field_offset, target_next_field_offset);
    cls.set_id(Class::kClassId);
    cls.set_state_bits(0);
    cls.set_is_allocate_finalized();
    cls.set_is_declaration_loaded();
    cls.set_is_type_finalized();
    cls.set_type_arguments_field_offset_in_words(Class::kNoTypeArguments,
                                                 RTN::Class::kNoTypeArguments);
    cls.set_num_type_arguments(0);
    cls.set_num_native_fields(0);
    cls.InitEmptyFields();
    isolate->class_table()->Register(cls);
  }

  // Allocate and initialize the null class.
  cls = Class::New<Instance, RTN::Instance>(kNullCid, isolate);
  cls.set_num_type_arguments(0);
  isolate->object_store()->set_null_class(cls);

  // Allocate and initialize Never class.
  cls = Class::New<Instance, RTN::Instance>(kNeverCid, isolate);
  cls.set_num_type_arguments(0);
  cls.set_is_allocate_finalized();
  cls.set_is_declaration_loaded();
  cls.set_is_type_finalized();
  isolate->object_store()->set_never_class(cls);

  // Allocate and initialize the free list element class.
  cls =
      Class::New<FreeListElement::FakeInstance,
                 RTN::FreeListElement::FakeInstance>(kFreeListElement, isolate);
  cls.set_num_type_arguments(0);
  cls.set_is_allocate_finalized();
  cls.set_is_declaration_loaded();
  cls.set_is_type_finalized();

  // Allocate and initialize the forwarding corpse class.
  cls = Class::New<ForwardingCorpse::FakeInstance,
                   RTN::ForwardingCorpse::FakeInstance>(kForwardingCorpse,
                                                        isolate);
  cls.set_num_type_arguments(0);
  cls.set_is_allocate_finalized();
  cls.set_is_declaration_loaded();
  cls.set_is_type_finalized();

  // Allocate and initialize the sentinel values.
  {
    *sentinel_ ^=
        Object::Allocate(kNeverCid, Instance::InstanceSize(), Heap::kOld);

    *transition_sentinel_ ^=
        Object::Allocate(kNeverCid, Instance::InstanceSize(), Heap::kOld);
  }

  // Allocate and initialize optimizing compiler constants.
  {
    *unknown_constant_ ^=
        Object::Allocate(kNeverCid, Instance::InstanceSize(), Heap::kOld);
    *non_constant_ ^=
        Object::Allocate(kNeverCid, Instance::InstanceSize(), Heap::kOld);
  }

  // Allocate the remaining VM internal classes.
  cls = Class::New<TypeArguments, RTN::TypeArguments>(isolate);
  type_arguments_class_ = cls.raw();

  cls = Class::New<PatchClass, RTN::PatchClass>(isolate);
  patch_class_class_ = cls.raw();

  cls = Class::New<Function, RTN::Function>(isolate);
  function_class_ = cls.raw();

  cls = Class::New<ClosureData, RTN::ClosureData>(isolate);
  closure_data_class_ = cls.raw();

  cls = Class::New<SignatureData, RTN::SignatureData>(isolate);
  signature_data_class_ = cls.raw();

  cls = Class::New<FfiTrampolineData, RTN::FfiTrampolineData>(isolate);
  ffi_trampoline_data_class_ = cls.raw();

  cls = Class::New<Field, RTN::Field>(isolate);
  field_class_ = cls.raw();

  cls = Class::New<Script, RTN::Script>(isolate);
  script_class_ = cls.raw();

  cls = Class::New<Library, RTN::Library>(isolate);
  library_class_ = cls.raw();

  cls = Class::New<Namespace, RTN::Namespace>(isolate);
  namespace_class_ = cls.raw();

  cls = Class::New<KernelProgramInfo, RTN::KernelProgramInfo>(isolate);
  kernel_program_info_class_ = cls.raw();

  cls = Class::New<Code, RTN::Code>(isolate);
  code_class_ = cls.raw();

  cls = Class::New<Instructions, RTN::Instructions>(isolate);
  instructions_class_ = cls.raw();

  cls = Class::New<InstructionsSection, RTN::InstructionsSection>(isolate);
  instructions_section_class_ = cls.raw();

  cls = Class::New<ObjectPool, RTN::ObjectPool>(isolate);
  object_pool_class_ = cls.raw();

  cls = Class::New<PcDescriptors, RTN::PcDescriptors>(isolate);
  pc_descriptors_class_ = cls.raw();

  cls = Class::New<CodeSourceMap, RTN::CodeSourceMap>(isolate);
  code_source_map_class_ = cls.raw();

  cls = Class::New<CompressedStackMaps, RTN::CompressedStackMaps>(isolate);
  compressed_stackmaps_class_ = cls.raw();

  cls = Class::New<LocalVarDescriptors, RTN::LocalVarDescriptors>(isolate);
  var_descriptors_class_ = cls.raw();

  cls = Class::New<ExceptionHandlers, RTN::ExceptionHandlers>(isolate);
  exception_handlers_class_ = cls.raw();

  cls = Class::New<Context, RTN::Context>(isolate);
  context_class_ = cls.raw();

  cls = Class::New<ContextScope, RTN::ContextScope>(isolate);
  context_scope_class_ = cls.raw();

  cls = Class::New<SingleTargetCache, RTN::SingleTargetCache>(isolate);
  singletargetcache_class_ = cls.raw();

  cls = Class::New<UnlinkedCall, RTN::UnlinkedCall>(isolate);
  unlinkedcall_class_ = cls.raw();

  cls =
      Class::New<MonomorphicSmiableCall, RTN::MonomorphicSmiableCall>(isolate);
  monomorphicsmiablecall_class_ = cls.raw();

  cls = Class::New<ICData, RTN::ICData>(isolate);
  icdata_class_ = cls.raw();

  cls = Class::New<MegamorphicCache, RTN::MegamorphicCache>(isolate);
  megamorphic_cache_class_ = cls.raw();

  cls = Class::New<SubtypeTestCache, RTN::SubtypeTestCache>(isolate);
  subtypetestcache_class_ = cls.raw();

  cls = Class::New<LoadingUnit, RTN::LoadingUnit>(isolate);
  loadingunit_class_ = cls.raw();

  cls = Class::New<ApiError, RTN::ApiError>(isolate);
  api_error_class_ = cls.raw();

  cls = Class::New<LanguageError, RTN::LanguageError>(isolate);
  language_error_class_ = cls.raw();

  cls = Class::New<UnhandledException, RTN::UnhandledException>(isolate);
  unhandled_exception_class_ = cls.raw();

  cls = Class::New<UnwindError, RTN::UnwindError>(isolate);
  unwind_error_class_ = cls.raw();

  cls = Class::New<WeakSerializationReference, RTN::WeakSerializationReference>(
      isolate);
  weak_serialization_reference_class_ = cls.raw();

  ASSERT(class_class() != null_);

  // Pre-allocate classes in the vm isolate so that we can for example create a
  // symbol table and populate it with some frequently used strings as symbols.
  cls = Class::New<Array, RTN::Array>(isolate);
  isolate->object_store()->set_array_class(cls);
  cls.set_type_arguments_field_offset(Array::type_arguments_offset(),
                                      RTN::Array::type_arguments_offset());
  cls.set_num_type_arguments(1);
  cls = Class::New<Array, RTN::Array>(kImmutableArrayCid, isolate);
  isolate->object_store()->set_immutable_array_class(cls);
  cls.set_type_arguments_field_offset(Array::type_arguments_offset(),
                                      RTN::Array::type_arguments_offset());
  cls.set_num_type_arguments(1);
  cls = Class::New<GrowableObjectArray, RTN::GrowableObjectArray>(isolate);
  isolate->object_store()->set_growable_object_array_class(cls);
  cls.set_type_arguments_field_offset(
      GrowableObjectArray::type_arguments_offset(),
      RTN::GrowableObjectArray::type_arguments_offset());
  cls.set_num_type_arguments(1);
  cls = Class::NewStringClass(kOneByteStringCid, isolate);
  isolate->object_store()->set_one_byte_string_class(cls);
  cls = Class::NewStringClass(kTwoByteStringCid, isolate);
  isolate->object_store()->set_two_byte_string_class(cls);
  cls = Class::New<Mint, RTN::Mint>(isolate);
  isolate->object_store()->set_mint_class(cls);
  cls = Class::New<Double, RTN::Double>(isolate);
  isolate->object_store()->set_double_class(cls);

  // Ensure that class kExternalTypedDataUint8ArrayCid is registered as we
  // need it when reading in the token stream of bootstrap classes in the VM
  // isolate.
  Class::NewExternalTypedDataClass(kExternalTypedDataUint8ArrayCid, isolate);

  // Needed for object pools of VM isolate stubs.
  Class::NewTypedDataClass(kTypedDataInt8ArrayCid, isolate);

  // Allocate and initialize the empty_array instance.
  {
    uword address = heap->Allocate(Array::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kImmutableArrayCid, Array::InstanceSize(0));
    Array::initializeHandle(empty_array_,
                            static_cast<ArrayPtr>(address + kHeapObjectTag));
    empty_array_->raw_ptr()->set_length(Smi::New(0));
    empty_array_->SetCanonical();
  }

  Smi& smi = Smi::Handle();
  // Allocate and initialize the zero_array instance.
  {
    uword address = heap->Allocate(Array::InstanceSize(1), Heap::kOld);
    InitializeObject(address, kImmutableArrayCid, Array::InstanceSize(1));
    Array::initializeHandle(zero_array_,
                            static_cast<ArrayPtr>(address + kHeapObjectTag));
    zero_array_->raw_ptr()->set_length(Smi::New(1));
    smi = Smi::New(0);
    zero_array_->SetAt(0, smi);
    zero_array_->SetCanonical();
  }

  // Allocate and initialize the canonical empty context scope object.
  {
    uword address = heap->Allocate(ContextScope::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kContextScopeCid, ContextScope::InstanceSize(0));
    ContextScope::initializeHandle(
        empty_context_scope_,
        static_cast<ContextScopePtr>(address + kHeapObjectTag));
    empty_context_scope_->StoreNonPointer(
        &empty_context_scope_->raw_ptr()->num_variables_, 0);
    empty_context_scope_->StoreNonPointer(
        &empty_context_scope_->raw_ptr()->is_implicit_, true);
    empty_context_scope_->SetCanonical();
  }

  // Allocate and initialize the canonical empty object pool object.
  {
    uword address = heap->Allocate(ObjectPool::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kObjectPoolCid, ObjectPool::InstanceSize(0));
    ObjectPool::initializeHandle(
        empty_object_pool_,
        static_cast<ObjectPoolPtr>(address + kHeapObjectTag));
    empty_object_pool_->StoreNonPointer(&empty_object_pool_->raw_ptr()->length_,
                                        0);
    empty_object_pool_->SetCanonical();
  }

  // Allocate and initialize the empty_compressed_stackmaps instance.
  {
    const intptr_t instance_size = CompressedStackMaps::InstanceSize(0);
    uword address = heap->Allocate(instance_size, Heap::kOld);
    InitializeObject(address, kCompressedStackMapsCid, instance_size);
    CompressedStackMaps::initializeHandle(
        empty_compressed_stackmaps_,
        static_cast<CompressedStackMapsPtr>(address + kHeapObjectTag));
    empty_compressed_stackmaps_->StoreNonPointer(
        &empty_compressed_stackmaps_->raw_ptr()->flags_and_size_, 0);
    empty_compressed_stackmaps_->SetCanonical();
  }

  // Allocate and initialize the empty_descriptors instance.
  {
    uword address = heap->Allocate(PcDescriptors::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kPcDescriptorsCid,
                     PcDescriptors::InstanceSize(0));
    PcDescriptors::initializeHandle(
        empty_descriptors_,
        static_cast<PcDescriptorsPtr>(address + kHeapObjectTag));
    empty_descriptors_->StoreNonPointer(&empty_descriptors_->raw_ptr()->length_,
                                        0);
    empty_descriptors_->SetCanonical();
  }

  // Allocate and initialize the canonical empty variable descriptor object.
  {
    uword address =
        heap->Allocate(LocalVarDescriptors::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kLocalVarDescriptorsCid,
                     LocalVarDescriptors::InstanceSize(0));
    LocalVarDescriptors::initializeHandle(
        empty_var_descriptors_,
        static_cast<LocalVarDescriptorsPtr>(address + kHeapObjectTag));
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
                     ExceptionHandlers::InstanceSize(0));
    ExceptionHandlers::initializeHandle(
        empty_exception_handlers_,
        static_cast<ExceptionHandlersPtr>(address + kHeapObjectTag));
    empty_exception_handlers_->StoreNonPointer(
        &empty_exception_handlers_->raw_ptr()->num_entries_, 0);
    empty_exception_handlers_->SetCanonical();
  }

  // Allocate and initialize the canonical empty type arguments object.
  {
    uword address = heap->Allocate(TypeArguments::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kTypeArgumentsCid,
                     TypeArguments::InstanceSize(0));
    TypeArguments::initializeHandle(
        empty_type_arguments_,
        static_cast<TypeArgumentsPtr>(address + kHeapObjectTag));
    empty_type_arguments_->raw_ptr()->set_length(Smi::New(0));
    empty_type_arguments_->raw_ptr()->set_hash(Smi::New(0));
    empty_type_arguments_->ComputeHash();
    empty_type_arguments_->SetCanonical();
  }

  // The VM isolate snapshot object table is initialized to an empty array
  // as we do not have any VM isolate snapshot at this time.
  *vm_isolate_snapshot_object_table_ = Object::empty_array().raw();

  cls = Class::New<Instance, RTN::Instance>(kDynamicCid, isolate);
  cls.set_is_abstract();
  cls.set_num_type_arguments(0);
  cls.set_is_allocate_finalized();
  cls.set_is_declaration_loaded();
  cls.set_is_type_finalized();
  dynamic_class_ = cls.raw();

  cls = Class::New<Instance, RTN::Instance>(kVoidCid, isolate);
  cls.set_num_type_arguments(0);
  cls.set_is_allocate_finalized();
  cls.set_is_declaration_loaded();
  cls.set_is_type_finalized();
  void_class_ = cls.raw();

  cls = Class::New<Type, RTN::Type>(isolate);
  cls.set_is_allocate_finalized();
  cls.set_is_declaration_loaded();
  cls.set_is_type_finalized();

  cls = dynamic_class_;
  *dynamic_type_ = Type::New(cls, Object::null_type_arguments(),
                             TokenPosition::kNoSource, Nullability::kNullable);
  dynamic_type_->SetIsFinalized();
  dynamic_type_->ComputeHash();
  dynamic_type_->SetCanonical();

  cls = void_class_;
  *void_type_ = Type::New(cls, Object::null_type_arguments(),
                          TokenPosition::kNoSource, Nullability::kNullable);
  void_type_->SetIsFinalized();
  void_type_->ComputeHash();
  void_type_->SetCanonical();

  // Since TypeArguments objects are passed as function arguments, make them
  // behave as Dart instances, although they are just VM objects.
  // Note that we cannot set the super type to ObjectType, which does not live
  // in the vm isolate. See special handling in Class::SuperClass().
  cls = type_arguments_class_;
  cls.set_interfaces(Object::empty_array());
  {
    Thread* thread = Thread::Current();
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    cls.SetFields(Object::empty_array());
    cls.SetFunctions(Object::empty_array());
  }

  cls = Class::New<Bool, RTN::Bool>(isolate);
  isolate->object_store()->set_bool_class(cls);

  *smi_illegal_cid_ = Smi::New(kIllegalCid);
  *smi_zero_ = Smi::New(0);

  String& error_str = String::Handle();
  error_str = String::New(
      "Internal Dart data pointers have been acquired, please release them "
      "using Dart_TypedDataReleaseData.",
      Heap::kOld);
  *typed_data_acquire_error_ = ApiError::New(error_str, Heap::kOld);
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
  error_str = String::New("Out of memory", Heap::kOld);
  *out_of_memory_error_ =
      LanguageError::New(error_str, Report::kBailout, Heap::kOld);

  // Allocate the parameter arrays for method extractor types and names.
  *extractor_parameter_types_ = Array::New(1, Heap::kOld);
  extractor_parameter_types_->SetAt(0, Object::dynamic_type());
  *extractor_parameter_names_ = Array::New(1, Heap::kOld);
  // Fill in extractor_parameter_names_ later, after symbols are initialized
  // (in Object::FinalizeVMIsolate). extractor_parameter_names_ object
  // needs to be created earlier as VM isolate snapshot reader references it
  // before Object::FinalizeVMIsolate.

  // Some thread fields need to be reinitialized as null constants have not been
  // initialized until now.
  Thread* thr = Thread::Current();
  ASSERT(thr != NULL);
  thr->ClearStickyError();
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
  ASSERT(!null_compressed_stackmaps_->IsSmi());
  ASSERT(null_compressed_stackmaps_->IsCompressedStackMaps());
  ASSERT(!empty_array_->IsSmi());
  ASSERT(empty_array_->IsArray());
  ASSERT(!zero_array_->IsSmi());
  ASSERT(zero_array_->IsArray());
  ASSERT(!empty_type_arguments_->IsSmi());
  ASSERT(empty_type_arguments_->IsTypeArguments());
  ASSERT(!empty_context_scope_->IsSmi());
  ASSERT(empty_context_scope_->IsContextScope());
  ASSERT(!empty_compressed_stackmaps_->IsSmi());
  ASSERT(empty_compressed_stackmaps_->IsCompressedStackMaps());
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
  ASSERT(smi_zero_->IsSmi());
  ASSERT(!typed_data_acquire_error_->IsSmi());
  ASSERT(typed_data_acquire_error_->IsApiError());
  ASSERT(!snapshot_writer_error_->IsSmi());
  ASSERT(snapshot_writer_error_->IsLanguageError());
  ASSERT(!branch_offset_error_->IsSmi());
  ASSERT(branch_offset_error_->IsLanguageError());
  ASSERT(!speculative_inlining_error_->IsSmi());
  ASSERT(speculative_inlining_error_->IsLanguageError());
  ASSERT(!background_compilation_error_->IsSmi());
  ASSERT(background_compilation_error_->IsLanguageError());
  ASSERT(!out_of_memory_error_->IsSmi());
  ASSERT(out_of_memory_error_->IsLanguageError());
  ASSERT(!vm_isolate_snapshot_object_table_->IsSmi());
  ASSERT(vm_isolate_snapshot_object_table_->IsArray());
  ASSERT(!extractor_parameter_types_->IsSmi());
  ASSERT(extractor_parameter_types_->IsArray());
  ASSERT(!extractor_parameter_names_->IsSmi());
  ASSERT(extractor_parameter_names_->IsArray());
}

void Object::FinishInit(Isolate* isolate) {
  // The type testing stubs we initialize in AbstractType objects for the
  // canonical type of kDynamicCid/kVoidCid need to be set in this
  // method, which is called after StubCode::InitOnce().
  Code& code = Code::Handle();

  code = TypeTestingStubGenerator::DefaultCodeForType(*dynamic_type_);
  dynamic_type_->SetTypeTestingStub(code);

  code = TypeTestingStubGenerator::DefaultCodeForType(*void_type_);
  void_type_->SetTypeTestingStub(code);
}

void Object::Cleanup() {
  null_ = static_cast<ObjectPtr>(RAW_NULL);
  true_ = static_cast<BoolPtr>(RAW_NULL);
  false_ = static_cast<BoolPtr>(RAW_NULL);
  class_class_ = static_cast<ClassPtr>(RAW_NULL);
  dynamic_class_ = static_cast<ClassPtr>(RAW_NULL);
  void_class_ = static_cast<ClassPtr>(RAW_NULL);
  type_arguments_class_ = static_cast<ClassPtr>(RAW_NULL);
  patch_class_class_ = static_cast<ClassPtr>(RAW_NULL);
  function_class_ = static_cast<ClassPtr>(RAW_NULL);
  closure_data_class_ = static_cast<ClassPtr>(RAW_NULL);
  signature_data_class_ = static_cast<ClassPtr>(RAW_NULL);
  ffi_trampoline_data_class_ = static_cast<ClassPtr>(RAW_NULL);
  field_class_ = static_cast<ClassPtr>(RAW_NULL);
  script_class_ = static_cast<ClassPtr>(RAW_NULL);
  library_class_ = static_cast<ClassPtr>(RAW_NULL);
  namespace_class_ = static_cast<ClassPtr>(RAW_NULL);
  kernel_program_info_class_ = static_cast<ClassPtr>(RAW_NULL);
  code_class_ = static_cast<ClassPtr>(RAW_NULL);
  instructions_class_ = static_cast<ClassPtr>(RAW_NULL);
  instructions_section_class_ = static_cast<ClassPtr>(RAW_NULL);
  object_pool_class_ = static_cast<ClassPtr>(RAW_NULL);
  pc_descriptors_class_ = static_cast<ClassPtr>(RAW_NULL);
  code_source_map_class_ = static_cast<ClassPtr>(RAW_NULL);
  compressed_stackmaps_class_ = static_cast<ClassPtr>(RAW_NULL);
  var_descriptors_class_ = static_cast<ClassPtr>(RAW_NULL);
  exception_handlers_class_ = static_cast<ClassPtr>(RAW_NULL);
  context_class_ = static_cast<ClassPtr>(RAW_NULL);
  context_scope_class_ = static_cast<ClassPtr>(RAW_NULL);
  singletargetcache_class_ = static_cast<ClassPtr>(RAW_NULL);
  unlinkedcall_class_ = static_cast<ClassPtr>(RAW_NULL);
  monomorphicsmiablecall_class_ = static_cast<ClassPtr>(RAW_NULL);
  icdata_class_ = static_cast<ClassPtr>(RAW_NULL);
  megamorphic_cache_class_ = static_cast<ClassPtr>(RAW_NULL);
  subtypetestcache_class_ = static_cast<ClassPtr>(RAW_NULL);
  loadingunit_class_ = static_cast<ClassPtr>(RAW_NULL);
  api_error_class_ = static_cast<ClassPtr>(RAW_NULL);
  language_error_class_ = static_cast<ClassPtr>(RAW_NULL);
  unhandled_exception_class_ = static_cast<ClassPtr>(RAW_NULL);
  unwind_error_class_ = static_cast<ClassPtr>(RAW_NULL);
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

  void VisitObject(ObjectPtr obj) {
    // Free list elements should never be marked.
    ASSERT(!obj->ptr()->IsMarked());
    // No forwarding corpses in the VM isolate.
    ASSERT(!obj->IsForwardingCorpse());
    if (!obj->IsFreeListElement()) {
      obj->ptr()->SetMarkBitUnsynchronized();
      Object::FinalizeReadOnlyObject(obj);
#if defined(HASH_IN_OBJECT_HEADER)
      // These objects end up in the read-only VM isolate which is shared
      // between isolates, so we have to prepopulate them with identity hash
      // codes, since we can't add hash codes later.
      if (Object::GetCachedHash(obj) == 0) {
        // Some classes have identity hash codes that depend on their contents,
        // not per object.
        ASSERT(!obj->IsStringInstance());
        if (!obj->IsMint() && !obj->IsDouble() && !obj->IsRawNull() &&
            !obj->IsBool()) {
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

  // Finish initialization of extractor_parameter_names_ which was
  // Started in Object::InitOnce()
  extractor_parameter_names_->SetAt(0, Symbols::This());

  // Set up names for all VM singleton classes.
  Class& cls = Class::Handle();

  SET_CLASS_NAME(class, Class);
  SET_CLASS_NAME(dynamic, Dynamic);
  SET_CLASS_NAME(void, Void);
  SET_CLASS_NAME(type_arguments, TypeArguments);
  SET_CLASS_NAME(patch_class, PatchClass);
  SET_CLASS_NAME(function, Function);
  SET_CLASS_NAME(closure_data, ClosureData);
  SET_CLASS_NAME(signature_data, SignatureData);
  SET_CLASS_NAME(ffi_trampoline_data, FfiTrampolineData);
  SET_CLASS_NAME(field, Field);
  SET_CLASS_NAME(script, Script);
  SET_CLASS_NAME(library, LibraryClass);
  SET_CLASS_NAME(namespace, Namespace);
  SET_CLASS_NAME(kernel_program_info, KernelProgramInfo);
  SET_CLASS_NAME(code, Code);
  SET_CLASS_NAME(instructions, Instructions);
  SET_CLASS_NAME(instructions_section, InstructionsSection);
  SET_CLASS_NAME(object_pool, ObjectPool);
  SET_CLASS_NAME(code_source_map, CodeSourceMap);
  SET_CLASS_NAME(pc_descriptors, PcDescriptors);
  SET_CLASS_NAME(compressed_stackmaps, CompressedStackMaps);
  SET_CLASS_NAME(var_descriptors, LocalVarDescriptors);
  SET_CLASS_NAME(exception_handlers, ExceptionHandlers);
  SET_CLASS_NAME(context, Context);
  SET_CLASS_NAME(context_scope, ContextScope);
  SET_CLASS_NAME(singletargetcache, SingleTargetCache);
  SET_CLASS_NAME(unlinkedcall, UnlinkedCall);
  SET_CLASS_NAME(monomorphicsmiablecall, MonomorphicSmiableCall);
  SET_CLASS_NAME(icdata, ICData);
  SET_CLASS_NAME(megamorphic_cache, MegamorphicCache);
  SET_CLASS_NAME(subtypetestcache, SubtypeTestCache);
  SET_CLASS_NAME(loadingunit, LoadingUnit);
  SET_CLASS_NAME(api_error, ApiError);
  SET_CLASS_NAME(language_error, LanguageError);
  SET_CLASS_NAME(unhandled_exception, UnhandledException);
  SET_CLASS_NAME(unwind_error, UnwindError);

  // Set up names for classes which are also pre-allocated in the vm isolate.
  cls = isolate->object_store()->array_class();
  cls.set_name(Symbols::_List());
  cls = isolate->object_store()->one_byte_string_class();
  cls.set_name(Symbols::OneByteString());
  cls = isolate->object_store()->never_class();
  cls.set_name(Symbols::Never());

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

void Object::FinalizeReadOnlyObject(ObjectPtr object) {
  NoSafepointScope no_safepoint;
  intptr_t cid = object->GetClassId();
  if (cid == kOneByteStringCid) {
    OneByteStringPtr str = static_cast<OneByteStringPtr>(object);
    if (String::GetCachedHash(str) == 0) {
      intptr_t hash = String::Hash(str);
      String::SetCachedHash(str, hash);
    }
    intptr_t size = OneByteString::UnroundedSize(str);
    ASSERT(size <= str->ptr()->HeapSize());
    memset(reinterpret_cast<void*>(ObjectLayout::ToAddr(str) + size), 0,
           str->ptr()->HeapSize() - size);
  } else if (cid == kTwoByteStringCid) {
    TwoByteStringPtr str = static_cast<TwoByteStringPtr>(object);
    if (String::GetCachedHash(str) == 0) {
      intptr_t hash = String::Hash(str);
      String::SetCachedHash(str, hash);
    }
    ASSERT(String::GetCachedHash(str) != 0);
    intptr_t size = TwoByteString::UnroundedSize(str);
    ASSERT(size <= str->ptr()->HeapSize());
    memset(reinterpret_cast<void*>(ObjectLayout::ToAddr(str) + size), 0,
           str->ptr()->HeapSize() - size);
  } else if (cid == kExternalOneByteStringCid) {
    ExternalOneByteStringPtr str =
        static_cast<ExternalOneByteStringPtr>(object);
    if (String::GetCachedHash(str) == 0) {
      intptr_t hash = String::Hash(str);
      String::SetCachedHash(str, hash);
    }
  } else if (cid == kExternalTwoByteStringCid) {
    ExternalTwoByteStringPtr str =
        static_cast<ExternalTwoByteStringPtr>(object);
    if (String::GetCachedHash(str) == 0) {
      intptr_t hash = String::Hash(str);
      String::SetCachedHash(str, hash);
    }
  } else if (cid == kCodeSourceMapCid) {
    CodeSourceMapPtr map = CodeSourceMap::RawCast(object);
    intptr_t size = CodeSourceMap::UnroundedSize(map);
    ASSERT(size <= map->ptr()->HeapSize());
    memset(reinterpret_cast<void*>(ObjectLayout::ToAddr(map) + size), 0,
           map->ptr()->HeapSize() - size);
  } else if (cid == kCompressedStackMapsCid) {
    CompressedStackMapsPtr maps = CompressedStackMaps::RawCast(object);
    intptr_t size = CompressedStackMaps::UnroundedSize(maps);
    ASSERT(size <= maps->ptr()->HeapSize());
    memset(reinterpret_cast<void*>(ObjectLayout::ToAddr(maps) + size), 0,
           maps->ptr()->HeapSize() - size);
  } else if (cid == kPcDescriptorsCid) {
    PcDescriptorsPtr desc = PcDescriptors::RawCast(object);
    intptr_t size = PcDescriptors::UnroundedSize(desc);
    ASSERT(size <= desc->ptr()->HeapSize());
    memset(reinterpret_cast<void*>(ObjectLayout::ToAddr(desc) + size), 0,
           desc->ptr()->HeapSize() - size);
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

    uword addr = ObjectLayout::ToAddr(obj.raw()) + used_size;
    if (leftover_size >= TypedData::InstanceSize(0)) {
      // Update the leftover space as a TypedDataInt8Array object.
      TypedDataPtr raw =
          static_cast<TypedDataPtr>(ObjectLayout::FromAddr(addr));
      uword new_tags =
          ObjectLayout::ClassIdTag::update(kTypedDataInt8ArrayCid, 0);
      new_tags = ObjectLayout::SizeTag::update(leftover_size, new_tags);
      const bool is_old = obj.raw()->IsOldObject();
      new_tags = ObjectLayout::OldBit::update(is_old, new_tags);
      new_tags = ObjectLayout::OldAndNotMarkedBit::update(is_old, new_tags);
      new_tags = ObjectLayout::OldAndNotRememberedBit::update(is_old, new_tags);
      new_tags = ObjectLayout::NewBit::update(!is_old, new_tags);
      // On architectures with a relaxed memory model, the concurrent marker may
      // observe the write of the filler object's header before observing the
      // new array length, and so treat it as a pointer. Ensure it is a Smi so
      // the marker won't dereference it.
      ASSERT((new_tags & kSmiTagMask) == kSmiTag);
      raw->ptr()->tags_ = new_tags;

      intptr_t leftover_len = (leftover_size - TypedData::InstanceSize(0));
      ASSERT(TypedData::InstanceSize(leftover_len) == leftover_size);
      raw->ptr()->set_length(Smi::New(leftover_len));
      raw->ptr()->RecomputeDataField();
    } else {
      // Update the leftover space as a basic object.
      ASSERT(leftover_size == Object::InstanceSize());
      ObjectPtr raw = static_cast<ObjectPtr>(ObjectLayout::FromAddr(addr));
      uword new_tags = ObjectLayout::ClassIdTag::update(kInstanceCid, 0);
      new_tags = ObjectLayout::SizeTag::update(leftover_size, new_tags);
      const bool is_old = obj.raw()->IsOldObject();
      new_tags = ObjectLayout::OldBit::update(is_old, new_tags);
      new_tags = ObjectLayout::OldAndNotMarkedBit::update(is_old, new_tags);
      new_tags = ObjectLayout::OldAndNotRememberedBit::update(is_old, new_tags);
      new_tags = ObjectLayout::NewBit::update(!is_old, new_tags);
      // On architectures with a relaxed memory model, the concurrent marker may
      // observe the write of the filler object's header before observing the
      // new array length, and so treat it as a pointer. Ensure it is a Smi so
      // the marker won't dereference it.
      ASSERT((new_tags & kSmiTagMask) == kSmiTag);
      raw->ptr()->tags_ = new_tags;
    }
  }
}

void Object::VerifyBuiltinVtables() {
#if defined(DEBUG)
  ASSERT(builtin_vtables_[kIllegalCid] == 0);
  ASSERT(builtin_vtables_[kFreeListElement] == 0);
  ASSERT(builtin_vtables_[kForwardingCorpse] == 0);
  ClassTable* table = Isolate::Current()->class_table();
  for (intptr_t cid = kObjectCid; cid < kNumPredefinedCids; cid++) {
    if (table->HasValidClassAt(cid)) {
      ASSERT(builtin_vtables_[cid] != 0);
    }
  }
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
//   2. There is no vm snapshot.  This function will bootstrap from source.
//   3. There is a vm snapshot.  The caller should initialize from the snapshot.
//
// A non-NULL kernel argument indicates (1).
// A NULL kernel indicates (2) or (3).
ErrorPtr Object::Init(Isolate* isolate,
                      const uint8_t* kernel_buffer,
                      intptr_t kernel_buffer_size) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(isolate == thread->isolate());
  TIMELINE_DURATION(thread, Isolate, "Object::Init");

#if defined(DART_PRECOMPILED_RUNTIME)
  const bool bootstrapping = false;
#else
  const bool is_kernel = (kernel_buffer != NULL);
  const bool bootstrapping =
      (Dart::vm_snapshot_kind() == Snapshot::kNone) || is_kernel;
#endif  // defined(DART_PRECOMPILED_RUNTIME).

  if (bootstrapping) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    // Object::Init version when we are bootstrapping from source or from a
    // Kernel binary.
    // This will initialize isolate group object_store, shared by all isolates
    // running in the isolate group.
    ObjectStore* object_store = isolate->object_store();
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

    Class& cls = Class::Handle(zone);
    Type& type = Type::Handle(zone);
    Array& array = Array::Handle(zone);
    Library& lib = Library::Handle(zone);
    TypeArguments& type_args = TypeArguments::Handle(zone);

    // All RawArray fields will be initialized to an empty array, therefore
    // initialize array class first.
    cls = Class::New<Array, RTN::Array>(isolate);
    ASSERT(object_store->array_class() == Class::null());
    object_store->set_array_class(cls);

    // VM classes that are parameterized (Array, ImmutableArray,
    // GrowableObjectArray, and LinkedHashMap) are also pre-finalized, so
    // CalculateFieldOffsets() is not called, so we need to set the offset of
    // their type_arguments_ field, which is explicitly declared in their
    // respective Raw* classes.
    cls.set_type_arguments_field_offset(Array::type_arguments_offset(),
                                        RTN::Array::type_arguments_offset());
    cls.set_num_type_arguments(1);

    // Set up the growable object array class (Has to be done after the array
    // class is setup as one of its field is an array object).
    cls = Class::New<GrowableObjectArray, RTN::GrowableObjectArray>(isolate);
    object_store->set_growable_object_array_class(cls);
    cls.set_type_arguments_field_offset(
        GrowableObjectArray::type_arguments_offset(),
        RTN::GrowableObjectArray::type_arguments_offset());
    cls.set_num_type_arguments(1);

    // Initialize hash set for canonical types.
    const intptr_t kInitialCanonicalTypeSize = 16;
    array = HashTables::New<CanonicalTypeSet>(kInitialCanonicalTypeSize,
                                              Heap::kOld);
    object_store->set_canonical_types(array);

    // Initialize hash set for canonical type parameters.
    const intptr_t kInitialCanonicalTypeParameterSize = 4;
    array = HashTables::New<CanonicalTypeParameterSet>(
        kInitialCanonicalTypeParameterSize, Heap::kOld);
    object_store->set_canonical_type_parameters(array);

    // Initialize hash set for canonical_type_arguments_.
    const intptr_t kInitialCanonicalTypeArgumentsSize = 4;
    array = HashTables::New<CanonicalTypeArgumentsSet>(
        kInitialCanonicalTypeArgumentsSize, Heap::kOld);
    object_store->set_canonical_type_arguments(array);

    // Setup type class early in the process.
    const Class& type_cls =
        Class::Handle(zone, Class::New<Type, RTN::Type>(isolate));
    const Class& type_ref_cls =
        Class::Handle(zone, Class::New<TypeRef, RTN::TypeRef>(isolate));
    const Class& type_parameter_cls = Class::Handle(
        zone, Class::New<TypeParameter, RTN::TypeParameter>(isolate));
    const Class& library_prefix_cls = Class::Handle(
        zone, Class::New<LibraryPrefix, RTN::LibraryPrefix>(isolate));

    // Pre-allocate the OneByteString class needed by the symbol table.
    cls = Class::NewStringClass(kOneByteStringCid, isolate);
    object_store->set_one_byte_string_class(cls);

    // Pre-allocate the TwoByteString class needed by the symbol table.
    cls = Class::NewStringClass(kTwoByteStringCid, isolate);
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
    // We cannot use NewNonParameterizedType(), because Array is
    // parameterized.  Warning: class _List has not been patched yet. Its
    // declared number of type parameters is still 0. It will become 1 after
    // patching. The array type allocated below represents the raw type _List
    // and not _List<E> as we could expect. Use with caution.
    type =
        Type::New(Class::Handle(zone, cls.raw()), TypeArguments::Handle(zone),
                  TokenPosition::kNoSource, Nullability::kNonNullable);
    type.SetIsFinalized();
    type ^= type.Canonicalize(thread, nullptr);
    object_store->set_array_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_array_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_array_type(type);

    cls = object_store->growable_object_array_class();  // Was allocated above.
    RegisterPrivateClass(cls, Symbols::_GrowableList(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Array, RTN::Array>(kImmutableArrayCid, isolate);
    object_store->set_immutable_array_class(cls);
    cls.set_type_arguments_field_offset(Array::type_arguments_offset(),
                                        RTN::Array::type_arguments_offset());
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

    cls = Class::NewStringClass(kExternalOneByteStringCid, isolate);
    object_store->set_external_one_byte_string_class(cls);
    RegisterPrivateClass(cls, Symbols::ExternalOneByteString(), core_lib);
    pending_classes.Add(cls);

    cls = Class::NewStringClass(kExternalTwoByteStringCid, isolate);
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

    cls = Class::New<Capability, RTN::Capability>(isolate);
    RegisterPrivateClass(cls, Symbols::_CapabilityImpl(), isolate_lib);
    pending_classes.Add(cls);

    cls = Class::New<ReceivePort, RTN::ReceivePort>(isolate);
    RegisterPrivateClass(cls, Symbols::_RawReceivePortImpl(), isolate_lib);
    pending_classes.Add(cls);

    cls = Class::New<SendPort, RTN::SendPort>(isolate);
    RegisterPrivateClass(cls, Symbols::_SendPortImpl(), isolate_lib);
    pending_classes.Add(cls);

    cls =
        Class::New<TransferableTypedData, RTN::TransferableTypedData>(isolate);
    RegisterPrivateClass(cls, Symbols::_TransferableTypedDataImpl(),
                         isolate_lib);
    pending_classes.Add(cls);

    const Class& stacktrace_cls =
        Class::Handle(zone, Class::New<StackTrace, RTN::StackTrace>(isolate));
    RegisterPrivateClass(stacktrace_cls, Symbols::_StackTrace(), core_lib);
    pending_classes.Add(stacktrace_cls);
    // Super type set below, after Object is allocated.

    cls = Class::New<RegExp, RTN::RegExp>(isolate);
    RegisterPrivateClass(cls, Symbols::_RegExp(), core_lib);
    pending_classes.Add(cls);

    // Initialize the base interfaces used by the core VM classes.

    // Allocate and initialize the pre-allocated classes in the core library.
    // The script and token index of these pre-allocated classes is set up in
    // the parser when the corelib script is compiled (see
    // Parser::ParseClassDefinition).
    cls = Class::New<Instance, RTN::Instance>(kInstanceCid, isolate);
    object_store->set_object_class(cls);
    cls.set_name(Symbols::Object());
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    cls.set_is_const();
    core_lib.AddClass(cls);
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_object_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_object_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_object_type(type);
    type = type.ToNullability(Nullability::kNullable, Heap::kOld);
    object_store->set_nullable_object_type(type);

    cls = Class::New<Bool, RTN::Bool>(isolate);
    object_store->set_bool_class(cls);
    RegisterClass(cls, Symbols::Bool(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Instance, RTN::Instance>(kNullCid, isolate);
    object_store->set_null_class(cls);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    RegisterClass(cls, Symbols::Null(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Instance, RTN::Instance>(kNeverCid, isolate);
    cls.set_num_type_arguments(0);
    cls.set_is_allocate_finalized();
    cls.set_is_declaration_loaded();
    cls.set_is_type_finalized();
    cls.set_name(Symbols::Never());
    object_store->set_never_class(cls);

    ASSERT(!library_prefix_cls.IsNull());
    RegisterPrivateClass(library_prefix_cls, Symbols::_LibraryPrefix(),
                         core_lib);
    pending_classes.Add(library_prefix_cls);

    RegisterPrivateClass(type_cls, Symbols::_Type(), core_lib);
    pending_classes.Add(type_cls);

    RegisterPrivateClass(type_ref_cls, Symbols::_TypeRef(), core_lib);
    pending_classes.Add(type_ref_cls);

    RegisterPrivateClass(type_parameter_cls, Symbols::_TypeParameter(),
                         core_lib);
    pending_classes.Add(type_parameter_cls);

    cls = Class::New<Integer, RTN::Integer>(isolate);
    object_store->set_integer_implementation_class(cls);
    RegisterPrivateClass(cls, Symbols::_IntegerImplementation(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Smi, RTN::Smi>(isolate);
    object_store->set_smi_class(cls);
    RegisterPrivateClass(cls, Symbols::_Smi(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Mint, RTN::Mint>(isolate);
    object_store->set_mint_class(cls);
    RegisterPrivateClass(cls, Symbols::_Mint(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<Double, RTN::Double>(isolate);
    object_store->set_double_class(cls);
    RegisterPrivateClass(cls, Symbols::_Double(), core_lib);
    pending_classes.Add(cls);

    // Class that represents the Dart class _Closure and C++ class Closure.
    cls = Class::New<Closure, RTN::Closure>(isolate);
    object_store->set_closure_class(cls);
    RegisterPrivateClass(cls, Symbols::_Closure(), core_lib);
    pending_classes.Add(cls);

    cls = Class::New<WeakProperty, RTN::WeakProperty>(isolate);
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

    cls = Class::New<MirrorReference, RTN::MirrorReference>(isolate);
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
    cls = Class::New<LinkedHashMap, RTN::LinkedHashMap>(isolate);
    object_store->set_linked_hash_map_class(cls);
    cls.set_type_arguments_field_offset(
        LinkedHashMap::type_arguments_offset(),
        RTN::LinkedHashMap::type_arguments_offset());
    cls.set_num_type_arguments(2);
    RegisterPrivateClass(cls, Symbols::_LinkedHashMap(), lib);
    pending_classes.Add(cls);

    // Pre-register the async library so we can place the vm class
    // FutureOr there rather than the core library.
    lib = Library::LookupLibrary(thread, Symbols::DartAsync());
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(Symbols::DartAsync(), true);
      lib.SetLoadRequested();
      lib.Register(thread);
    }
    object_store->set_bootstrap_library(ObjectStore::kAsync, lib);
    ASSERT(!lib.IsNull());
    ASSERT(lib.raw() == Library::AsyncLibrary());
    cls = Class::New<FutureOr, RTN::FutureOr>(isolate);
    cls.set_type_arguments_field_offset(FutureOr::type_arguments_offset(),
                                        RTN::FutureOr::type_arguments_offset());
    cls.set_num_type_arguments(1);
    RegisterClass(cls, Symbols::FutureOr(), lib);
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
    cls = Class::New<UserTag, RTN::UserTag>(isolate);
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
  cls = Class::NewTypedDataClass(kTypedData##clazz##ArrayCid, isolate);        \
  RegisterPrivateClass(cls, Symbols::_##clazz##List(), lib);

    DART_CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_CLASS);
#undef REGISTER_TYPED_DATA_CLASS
#define REGISTER_TYPED_DATA_VIEW_CLASS(clazz)                                  \
  cls = Class::NewTypedDataViewClass(kTypedData##clazz##ViewCid, isolate);     \
  RegisterPrivateClass(cls, Symbols::_##clazz##View(), lib);                   \
  pending_classes.Add(cls);

    CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_VIEW_CLASS);

    cls = Class::NewTypedDataViewClass(kByteDataViewCid, isolate);
    RegisterPrivateClass(cls, Symbols::_ByteDataView(), lib);
    pending_classes.Add(cls);

#undef REGISTER_TYPED_DATA_VIEW_CLASS
#define REGISTER_EXT_TYPED_DATA_CLASS(clazz)                                   \
  cls = Class::NewExternalTypedDataClass(kExternalTypedData##clazz##Cid,       \
                                         isolate);                             \
  RegisterPrivateClass(cls, Symbols::_External##clazz(), lib);

    cls = Class::New<Instance, RTN::Instance>(kByteBufferCid, isolate,
                                              /*register_class=*/false);
    cls.set_instance_size(0, 0);
    cls.set_next_field_offset(-kWordSize, -compiler::target::kWordSize);
    isolate->class_table()->Register(cls);
    RegisterPrivateClass(cls, Symbols::_ByteBuffer(), lib);
    pending_classes.Add(cls);

    CLASS_LIST_TYPED_DATA(REGISTER_EXT_TYPED_DATA_CLASS);
#undef REGISTER_EXT_TYPED_DATA_CLASS
    // Register Float32x4, Int32x4, and Float64x2 in the object store.
    cls = Class::New<Float32x4, RTN::Float32x4>(isolate);
    RegisterPrivateClass(cls, Symbols::_Float32x4(), lib);
    pending_classes.Add(cls);
    object_store->set_float32x4_class(cls);

    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    RegisterClass(cls, Symbols::Float32x4(), lib);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_float32x4_type(type);

    cls = Class::New<Int32x4, RTN::Int32x4>(isolate);
    RegisterPrivateClass(cls, Symbols::_Int32x4(), lib);
    pending_classes.Add(cls);
    object_store->set_int32x4_class(cls);

    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    RegisterClass(cls, Symbols::Int32x4(), lib);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_int32x4_type(type);

    cls = Class::New<Float64x2, RTN::Float64x2>(isolate);
    RegisterPrivateClass(cls, Symbols::_Float64x2(), lib);
    pending_classes.Add(cls);
    object_store->set_float64x2_class(cls);

    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    RegisterClass(cls, Symbols::Float64x2(), lib);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_float64x2_type(type);

    // Set the super type of class StackTrace to Object type so that the
    // 'toString' method is implemented.
    type = object_store->object_type();
    stacktrace_cls.set_super_type(type);

    // Abstract class that represents the Dart class Type.
    // Note that this class is implemented by Dart class _AbstractType.
    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    RegisterClass(cls, Symbols::Type(), core_lib);
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_type_type(type);

    // Abstract class that represents the Dart class Function.
    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    RegisterClass(cls, Symbols::Function(), core_lib);
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_function_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_function_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_function_type(type);

    cls = Class::New<Number, RTN::Number>(isolate);
    RegisterClass(cls, Symbols::Number(), core_lib);
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_number_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_number_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_number_type(type);

    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    RegisterClass(cls, Symbols::Int(), core_lib);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_int_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_int_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_int_type(type);
    type = type.ToNullability(Nullability::kNullable, Heap::kOld);
    object_store->set_nullable_int_type(type);

    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    RegisterClass(cls, Symbols::Double(), core_lib);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_double_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_double_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_double_type(type);
    type = type.ToNullability(Nullability::kNullable, Heap::kOld);
    object_store->set_nullable_double_type(type);

    name = Symbols::_String().raw();
    cls = Class::New<Instance, RTN::Instance>(kIllegalCid, isolate,
                                              /*register_class=*/true,
                                              /*is_abstract=*/true);
    RegisterClass(cls, name, core_lib);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    type = Type::NewNonParameterizedType(cls);
    object_store->set_string_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_string_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_string_type(type);

    cls = object_store->bool_class();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_bool_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_bool_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_bool_type(type);

    cls = object_store->smi_class();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_smi_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_smi_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_smi_type(type);

    cls = object_store->mint_class();
    type = Type::NewNonParameterizedType(cls);
    object_store->set_mint_type(type);
    type = type.ToNullability(Nullability::kLegacy, Heap::kOld);
    object_store->set_legacy_mint_type(type);
    type = type.ToNullability(Nullability::kNonNullable, Heap::kOld);
    object_store->set_non_nullable_mint_type(type);

    // The classes 'void' and 'dynamic' are phony classes to make type checking
    // more regular; they live in the VM isolate. The class 'void' is not
    // registered in the class dictionary because its name is a reserved word.
    // The class 'dynamic' is registered in the class dictionary because its
    // name is a built-in identifier (this is wrong).  The corresponding types
    // are stored in the object store.
    cls = object_store->null_class();
    type = Type::New(cls, Object::null_type_arguments(),
                     TokenPosition::kNoSource, Nullability::kNullable);
    type.SetIsFinalized();
    type ^= type.Canonicalize(thread, nullptr);
    object_store->set_null_type(type);
    ASSERT(type.IsNullable());

    // Consider removing when/if Null becomes an ordinary class.
    type = object_store->object_type();
    cls.set_super_type(type);

    cls = object_store->never_class();
    type = Type::New(cls, Object::null_type_arguments(),
                     TokenPosition::kNoSource, Nullability::kNonNullable);
    type.SetIsFinalized();
    type ^= type.Canonicalize(thread, nullptr);
    object_store->set_never_type(type);

    // Create and cache commonly used type arguments <int>, <double>,
    // <String>, <String, dynamic> and <String, String>.
    type_args = TypeArguments::New(1);
    type = object_store->int_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_int(type_args);
    type_args = TypeArguments::New(1);
    type = object_store->legacy_int_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_legacy_int(type_args);
    type_args = TypeArguments::New(1);
    type = object_store->non_nullable_int_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_non_nullable_int(type_args);

    type_args = TypeArguments::New(1);
    type = object_store->double_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_double(type_args);
    type_args = TypeArguments::New(1);
    type = object_store->legacy_double_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_legacy_double(type_args);
    type_args = TypeArguments::New(1);
    type = object_store->non_nullable_double_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_non_nullable_double(type_args);

    type_args = TypeArguments::New(1);
    type = object_store->string_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_string(type_args);
    type_args = TypeArguments::New(1);
    type = object_store->legacy_string_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_legacy_string(type_args);
    type_args = TypeArguments::New(1);
    type = object_store->non_nullable_string_type();
    type_args.SetTypeAt(0, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_non_nullable_string(type_args);

    type_args = TypeArguments::New(2);
    type = object_store->string_type();
    type_args.SetTypeAt(0, type);
    type_args.SetTypeAt(1, Object::dynamic_type());
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_string_dynamic(type_args);
    type_args = TypeArguments::New(2);
    type = object_store->legacy_string_type();
    type_args.SetTypeAt(0, type);
    type_args.SetTypeAt(1, Object::dynamic_type());
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_legacy_string_dynamic(type_args);
    type_args = TypeArguments::New(2);
    type = object_store->non_nullable_string_type();
    type_args.SetTypeAt(0, type);
    type_args.SetTypeAt(1, Object::dynamic_type());
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_non_nullable_string_dynamic(type_args);

    type_args = TypeArguments::New(2);
    type = object_store->string_type();
    type_args.SetTypeAt(0, type);
    type_args.SetTypeAt(1, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_string_string(type_args);
    type_args = TypeArguments::New(2);
    type = object_store->legacy_string_type();
    type_args.SetTypeAt(0, type);
    type_args.SetTypeAt(1, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_legacy_string_legacy_string(type_args);
    type_args = TypeArguments::New(2);
    type = object_store->non_nullable_string_type();
    type_args.SetTypeAt(0, type);
    type_args.SetTypeAt(1, type);
    type_args = type_args.Canonicalize(thread, nullptr);
    object_store->set_type_argument_non_nullable_string_non_nullable_string(
        type_args);

    lib = Library::LookupLibrary(thread, Symbols::DartFfi());
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(Symbols::DartFfi(), true);
      lib.SetLoadRequested();
      lib.Register(thread);
    }
    object_store->set_bootstrap_library(ObjectStore::kFfi, lib);

    cls = Class::New<Instance, RTN::Instance>(kFfiNativeTypeCid, isolate);
    cls.set_num_type_arguments(0);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    object_store->set_ffi_native_type_class(cls);
    RegisterClass(cls, Symbols::FfiNativeType(), lib);

#define REGISTER_FFI_TYPE_MARKER(clazz)                                        \
  cls = Class::New<Instance, RTN::Instance>(kFfi##clazz##Cid, isolate);        \
  cls.set_num_type_arguments(0);                                               \
  cls.set_is_prefinalized();                                                   \
  pending_classes.Add(cls);                                                    \
  RegisterClass(cls, Symbols::Ffi##clazz(), lib);
    CLASS_LIST_FFI_TYPE_MARKER(REGISTER_FFI_TYPE_MARKER);
#undef REGISTER_FFI_TYPE_MARKER

    cls = Class::New<Instance, RTN::Instance>(kFfiNativeFunctionCid, isolate);
    cls.set_type_arguments_field_offset(Pointer::type_arguments_offset(),
                                        RTN::Pointer::type_arguments_offset());
    cls.set_num_type_arguments(1);
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    RegisterClass(cls, Symbols::FfiNativeFunction(), lib);

    cls = Class::NewPointerClass(kFfiPointerCid, isolate);
    object_store->set_ffi_pointer_class(cls);
    pending_classes.Add(cls);
    RegisterClass(cls, Symbols::FfiPointer(), lib);

    cls = Class::New<DynamicLibrary, RTN::DynamicLibrary>(kFfiDynamicLibraryCid,
                                                          isolate);
    cls.set_instance_size(DynamicLibrary::InstanceSize(),
                          compiler::target::RoundedAllocationSize(
                              RTN::DynamicLibrary::InstanceSize()));
    cls.set_is_prefinalized();
    pending_classes.Add(cls);
    RegisterClass(cls, Symbols::FfiDynamicLibrary(), lib);

    // Finish the initialization by compiling the bootstrap scripts containing
    // the base interfaces and the implementation of the internal classes.
    const Error& error = Error::Handle(
        zone, Bootstrap::DoBootstrapping(kernel_buffer, kernel_buffer_size));
    if (!error.IsNull()) {
      return error.raw();
    }

    isolate->class_table()->CopySizesFromClassObjects();

    ClassFinalizer::VerifyBootstrapClasses();

    // Set up the intrinsic state of all functions (core, math and typed data).
    compiler::Intrinsifier::InitializeState();

    // Adds static const fields (class ids) to the class 'ClassID');
    lib = Library::LookupLibrary(thread, Symbols::DartInternal());
    ASSERT(!lib.IsNull());
    cls = lib.LookupClassAllowPrivate(Symbols::ClassID());
    ASSERT(!cls.IsNull());
    const bool injected = cls.InjectCIDFields();
    ASSERT(injected);

    isolate->object_store()->InitKnownObjects();

    // Set up recognized state of all functions (core, math and typed data).
    MethodRecognizer::InitializeState();
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
    cls = Class::New<Instance, RTN::Instance>(kInstanceCid, isolate);
    object_store->set_object_class(cls);

    cls = Class::New<LibraryPrefix, RTN::LibraryPrefix>(isolate);
    cls = Class::New<Type, RTN::Type>(isolate);
    cls = Class::New<TypeRef, RTN::TypeRef>(isolate);
    cls = Class::New<TypeParameter, RTN::TypeParameter>(isolate);

    cls = Class::New<Array, RTN::Array>(isolate);
    object_store->set_array_class(cls);

    cls = Class::New<Array, RTN::Array>(kImmutableArrayCid, isolate);
    object_store->set_immutable_array_class(cls);

    cls = Class::New<GrowableObjectArray, RTN::GrowableObjectArray>(isolate);
    object_store->set_growable_object_array_class(cls);

    cls = Class::New<LinkedHashMap, RTN::LinkedHashMap>(isolate);
    object_store->set_linked_hash_map_class(cls);

    cls = Class::New<Float32x4, RTN::Float32x4>(isolate);
    object_store->set_float32x4_class(cls);

    cls = Class::New<Int32x4, RTN::Int32x4>(isolate);
    object_store->set_int32x4_class(cls);

    cls = Class::New<Float64x2, RTN::Float64x2>(isolate);
    object_store->set_float64x2_class(cls);

#define REGISTER_TYPED_DATA_CLASS(clazz)                                       \
  cls = Class::NewTypedDataClass(kTypedData##clazz##Cid, isolate);
    CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_CLASS);
#undef REGISTER_TYPED_DATA_CLASS
#define REGISTER_TYPED_DATA_VIEW_CLASS(clazz)                                  \
  cls = Class::NewTypedDataViewClass(kTypedData##clazz##ViewCid, isolate);
    CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_VIEW_CLASS);
#undef REGISTER_TYPED_DATA_VIEW_CLASS
    cls = Class::NewTypedDataViewClass(kByteDataViewCid, isolate);
#define REGISTER_EXT_TYPED_DATA_CLASS(clazz)                                   \
  cls = Class::NewExternalTypedDataClass(kExternalTypedData##clazz##Cid,       \
                                         isolate);
    CLASS_LIST_TYPED_DATA(REGISTER_EXT_TYPED_DATA_CLASS);
#undef REGISTER_EXT_TYPED_DATA_CLASS

    cls = Class::New<Instance, RTN::Instance>(kFfiNativeTypeCid, isolate);
    object_store->set_ffi_native_type_class(cls);

#define REGISTER_FFI_CLASS(clazz)                                              \
  cls = Class::New<Instance, RTN::Instance>(kFfi##clazz##Cid, isolate);
    CLASS_LIST_FFI_TYPE_MARKER(REGISTER_FFI_CLASS);
#undef REGISTER_FFI_CLASS

    cls = Class::New<Instance, RTN::Instance>(kFfiNativeFunctionCid, isolate);

    cls = Class::NewPointerClass(kFfiPointerCid, isolate);
    object_store->set_ffi_pointer_class(cls);

    cls = Class::New<DynamicLibrary, RTN::DynamicLibrary>(kFfiDynamicLibraryCid,
                                                          isolate);

    cls = Class::New<Instance, RTN::Instance>(kByteBufferCid, isolate,
                                              /*register_isolate=*/false);
    cls.set_instance_size_in_words(0, 0);
    isolate->class_table()->Register(cls);

    cls = Class::New<Integer, RTN::Integer>(isolate);
    object_store->set_integer_implementation_class(cls);

    cls = Class::New<Smi, RTN::Smi>(isolate);
    object_store->set_smi_class(cls);

    cls = Class::New<Mint, RTN::Mint>(isolate);
    object_store->set_mint_class(cls);

    cls = Class::New<Double, RTN::Double>(isolate);
    object_store->set_double_class(cls);

    cls = Class::New<Closure, RTN::Closure>(isolate);
    object_store->set_closure_class(cls);

    cls = Class::NewStringClass(kOneByteStringCid, isolate);
    object_store->set_one_byte_string_class(cls);

    cls = Class::NewStringClass(kTwoByteStringCid, isolate);
    object_store->set_two_byte_string_class(cls);

    cls = Class::NewStringClass(kExternalOneByteStringCid, isolate);
    object_store->set_external_one_byte_string_class(cls);

    cls = Class::NewStringClass(kExternalTwoByteStringCid, isolate);
    object_store->set_external_two_byte_string_class(cls);

    cls = Class::New<Bool, RTN::Bool>(isolate);
    object_store->set_bool_class(cls);

    cls = Class::New<Instance, RTN::Instance>(kNullCid, isolate);
    object_store->set_null_class(cls);

    cls = Class::New<Instance, RTN::Instance>(kNeverCid, isolate);
    object_store->set_never_class(cls);

    cls = Class::New<Capability, RTN::Capability>(isolate);
    cls = Class::New<ReceivePort, RTN::ReceivePort>(isolate);
    cls = Class::New<SendPort, RTN::SendPort>(isolate);
    cls = Class::New<StackTrace, RTN::StackTrace>(isolate);
    cls = Class::New<RegExp, RTN::RegExp>(isolate);
    cls = Class::New<Number, RTN::Number>(isolate);

    cls = Class::New<WeakProperty, RTN::WeakProperty>(isolate);
    object_store->set_weak_property_class(cls);

    cls = Class::New<MirrorReference, RTN::MirrorReference>(isolate);
    cls = Class::New<UserTag, RTN::UserTag>(isolate);
    cls = Class::New<FutureOr, RTN::FutureOr>(isolate);
    cls =
        Class::New<TransferableTypedData, RTN::TransferableTypedData>(isolate);
  }
  return Error::null();
}

#if defined(DEBUG)
bool Object::InVMIsolateHeap() const {
  if (FLAG_verify_handles && raw()->ptr()->InVMIsolateHeap()) {
    Heap* vm_isolate_heap = Dart::vm_isolate()->heap();
    uword addr = ObjectLayout::ToAddr(raw());
    if (!vm_isolate_heap->Contains(addr)) {
      ASSERT(FLAG_write_protect_code);
      addr = ObjectLayout::ToAddr(OldPage::ToWritable(raw()));
      ASSERT(vm_isolate_heap->Contains(addr));
    }
  }
  return raw()->ptr()->InVMIsolateHeap();
}
#endif  // DEBUG

void Object::Print() const {
  THR_Print("%s\n", ToCString());
}

StringPtr Object::DictionaryName() const {
  return String::null();
}

void Object::InitializeObject(uword address, intptr_t class_id, intptr_t size) {
  // Note: we skip the header word here to avoid a racy read in the concurrent
  // marker from observing the null object when it reads into a heap page
  // allocated after marking started.
  uword cur = address + sizeof(ObjectLayout);
  uword end = address + size;
  if (class_id == kInstructionsCid) {
    compiler::target::uword initial_value = kBreakInstructionFiller;
    while (cur < end) {
      *reinterpret_cast<compiler::target::uword*>(cur) = initial_value;
      cur += compiler::target::kWordSize;
    }
  } else {
    uword initial_value;
    bool needs_init;
    if (IsTypedDataBaseClassId(class_id)) {
      initial_value = 0;
      // If the size is greater than both kNewAllocatableSize and
      // kAllocatablePageSize, the object must have been allocated to a new
      // large page, which must already have been zero initialized by the OS.
      needs_init = Heap::IsAllocatableInNewSpace(size) ||
                   Heap::IsAllocatableViaFreeLists(size);
    } else {
      initial_value = static_cast<uword>(null_);
      needs_init = true;
    }
    if (needs_init) {
      while (cur < end) {
        *reinterpret_cast<uword*>(cur) = initial_value;
        cur += kWordSize;
      }
    } else {
      // Check that MemorySantizer understands this is initialized.
      MSAN_CHECK_INITIALIZED(reinterpret_cast<void*>(address), size);
#if defined(DEBUG)
      while (cur < end) {
        ASSERT(*reinterpret_cast<uword*>(cur) == initial_value);
        cur += kWordSize;
      }
#endif
    }
  }
  uword tags = 0;
  ASSERT(class_id != kIllegalCid);
  tags = ObjectLayout::ClassIdTag::update(class_id, tags);
  tags = ObjectLayout::SizeTag::update(size, tags);
  const bool is_old =
      (address & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;
  tags = ObjectLayout::OldBit::update(is_old, tags);
  tags = ObjectLayout::OldAndNotMarkedBit::update(is_old, tags);
  tags = ObjectLayout::OldAndNotRememberedBit::update(is_old, tags);
  tags = ObjectLayout::NewBit::update(!is_old, tags);
  reinterpret_cast<ObjectLayout*>(address)->tags_ = tags;
}

void Object::CheckHandle() const {
#if defined(DEBUG)
  if (raw_ != Object::null()) {
    intptr_t cid = raw_->GetClassIdMayBeSmi();
    if (cid >= kNumPredefinedCids) {
      cid = kInstanceCid;
    }
    ASSERT(vtable() == builtin_vtables_[cid]);
    if (FLAG_verify_handles && raw_->IsHeapObject()) {
      Heap* isolate_heap = IsolateGroup::Current()->heap();
      if (!isolate_heap->new_space()->scavenging()) {
        Heap* vm_isolate_heap = Dart::vm_isolate()->heap();
        uword addr = ObjectLayout::ToAddr(raw_);
        if (!isolate_heap->Contains(addr) && !vm_isolate_heap->Contains(addr)) {
          ASSERT(FLAG_write_protect_code);
          addr = ObjectLayout::ToAddr(OldPage::ToWritable(raw_));
          ASSERT(isolate_heap->Contains(addr) ||
                 vm_isolate_heap->Contains(addr));
        }
      }
    }
  }
#endif
}

ObjectPtr Object::Allocate(intptr_t cls_id, intptr_t size, Heap::Space space) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  Thread* thread = Thread::Current();
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  ASSERT(thread->no_safepoint_scope_depth() == 0);
  ASSERT(thread->no_callback_scope_depth() == 0);
  Heap* heap = thread->heap();

  uword address = heap->Allocate(size, space);
  if (UNLIKELY(address == 0)) {
    // SuspendLongJumpScope during Dart entry ensures that if a longjmp base is
    // available, it is the innermost error handler, so check for a longjmp base
    // before checking for an exit frame.
    if (thread->long_jump_base() != nullptr) {
      Report::LongJump(Object::out_of_memory_error());
      UNREACHABLE();
    } else if (thread->top_exit_frame_info() != 0) {
      // Use the preallocated out of memory exception to avoid calling
      // into dart code or allocating any code.
      const Instance& exception =
          Instance::Handle(thread->isolate()->object_store()->out_of_memory());
      Exceptions::Throw(thread, exception);
      UNREACHABLE();
    } else {
      // Nowhere to propagate an exception to.
      OUT_OF_MEMORY();
    }
  }
#ifndef PRODUCT
  auto class_table = thread->isolate_group()->shared_class_table();
  if (class_table->TraceAllocationFor(cls_id)) {
    Profiler::SampleAllocation(thread, cls_id);
  }
#endif  // !PRODUCT
  NoSafepointScope no_safepoint;
  InitializeObject(address, cls_id, size);
  ObjectPtr raw_obj = static_cast<ObjectPtr>(address + kHeapObjectTag);
  ASSERT(cls_id == ObjectLayout::ClassIdTag::decode(raw_obj->ptr()->tags_));
  if (raw_obj->IsOldObject() && UNLIKELY(thread->is_marking())) {
    // Black allocation. Prevents a data race between the mutator and concurrent
    // marker on ARM and ARM64 (the marker may observe a publishing store of
    // this object before the stores that initialize its slots), and helps the
    // collection to finish sooner.
    raw_obj->ptr()->SetMarkBitUnsynchronized();
    // Setting the mark bit must not be ordered after a publishing store of this
    // object. Adding a barrier here is cheaper than making every store into the
    // heap a store-release. Compare Scavenger::ScavengePointer.
    std::atomic_thread_fence(std::memory_order_release);
    heap->old_space()->AllocateBlack(size);
  }
  return raw_obj;
}

class WriteBarrierUpdateVisitor : public ObjectPointerVisitor {
 public:
  explicit WriteBarrierUpdateVisitor(Thread* thread, ObjectPtr obj)
      : ObjectPointerVisitor(thread->isolate()->group()),
        thread_(thread),
        old_obj_(obj) {
    ASSERT(old_obj_->IsOldObject());
  }

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) {
    if (old_obj_->IsArray()) {
      for (ObjectPtr* slot = from; slot <= to; ++slot) {
        ObjectPtr value = *slot;
        if (value->IsHeapObject()) {
          old_obj_->ptr()->CheckArrayPointerStore(slot, value, thread_);
        }
      }
    } else {
      for (ObjectPtr* slot = from; slot <= to; ++slot) {
        ObjectPtr value = *slot;
        if (value->IsHeapObject()) {
          old_obj_->ptr()->CheckHeapPointerStore(value, thread_);
        }
      }
    }
  }

 private:
  Thread* thread_;
  ObjectPtr old_obj_;

  DISALLOW_COPY_AND_ASSIGN(WriteBarrierUpdateVisitor);
};

bool Object::IsReadOnlyHandle() const {
  return Dart::IsReadOnlyHandle(reinterpret_cast<uword>(this));
}

bool Object::IsNotTemporaryScopedHandle() const {
  return (IsZoneHandle() || IsReadOnlyHandle());
}

ObjectPtr Object::Clone(const Object& orig, Heap::Space space) {
  const Class& cls = Class::Handle(orig.clazz());
  intptr_t size = orig.raw()->ptr()->HeapSize();
  ObjectPtr raw_clone = Object::Allocate(cls.id(), size, space);
  NoSafepointScope no_safepoint;
  // Copy the body of the original into the clone.
  uword orig_addr = ObjectLayout::ToAddr(orig.raw());
  uword clone_addr = ObjectLayout::ToAddr(raw_clone);
  static const intptr_t kHeaderSizeInBytes = sizeof(ObjectLayout);
  memmove(reinterpret_cast<uint8_t*>(clone_addr + kHeaderSizeInBytes),
          reinterpret_cast<uint8_t*>(orig_addr + kHeaderSizeInBytes),
          size - kHeaderSizeInBytes);

  // Add clone to store buffer, if needed.
  if (!raw_clone->IsOldObject()) {
    // No need to remember an object in new space.
    return raw_clone;
  }
  WriteBarrierUpdateVisitor visitor(Thread::Current(), raw_clone);
  raw_clone->ptr()->VisitPointers(&visitor);
  return raw_clone;
}

StringPtr Class::Name() const {
  return raw_ptr()->name();
}

StringPtr Class::ScrubbedName() const {
  return Symbols::New(Thread::Current(), ScrubbedNameCString());
}

const char* Class::ScrubbedNameCString() const {
  return String::ScrubName(String::Handle(Name()));
}

StringPtr Class::UserVisibleName() const {
#if !defined(PRODUCT)
  ASSERT(raw_ptr()->user_name() != String::null());
  return raw_ptr()->user_name();
#endif  // !defined(PRODUCT)
  // No caching in PRODUCT, regenerate.
  return Symbols::New(Thread::Current(), GenerateUserVisibleName());
}

const char* Class::UserVisibleNameCString() const {
#if !defined(PRODUCT)
  ASSERT(raw_ptr()->user_name() != String::null());
  return String::Handle(raw_ptr()->user_name()).ToCString();
#endif                               // !defined(PRODUCT)
  return GenerateUserVisibleName();  // No caching in PRODUCT, regenerate.
}

const char* Class::NameCString(NameVisibility name_visibility) const {
  switch (name_visibility) {
    case Object::kInternalName:
      return String::Handle(Name()).ToCString();
    case Object::kScrubbedName:
      return ScrubbedNameCString();
    case Object::kUserVisibleName:
      return UserVisibleNameCString();
    default:
      UNREACHABLE();
      return nullptr;
  }
}

ClassPtr Class::Mixin() const {
  if (is_transformed_mixin_application()) {
    const Array& interfaces = Array::Handle(this->interfaces());
    const Type& mixin_type =
        Type::Handle(Type::RawCast(interfaces.At(interfaces.Length() - 1)));
    return mixin_type.type_class();
  }
  return raw();
}

NNBDMode Class::nnbd_mode() const {
  return Library::Handle(library()).nnbd_mode();
}

bool Class::IsInFullSnapshot() const {
  NoSafepointScope no_safepoint;
  return LibraryLayout::InFullSnapshotBit::decode(
      raw_ptr()->library()->ptr()->flags_);
}

AbstractTypePtr Class::RareType() const {
  if (!IsGeneric() && !IsClosureClass() && !IsTypedefClass()) {
    return DeclarationType();
  }
  ASSERT(is_declaration_loaded());
  const Type& type = Type::Handle(
      Type::New(*this, Object::null_type_arguments(), TokenPosition::kNoSource,
                Nullability::kNonNullable));
  return ClassFinalizer::FinalizeType(type);
}

template <class FakeObject, class TargetFakeObject>
ClassPtr Class::New(Isolate* isolate, bool register_class) {
  ASSERT(Object::class_class() != Class::null());
  Class& result = Class::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(Class::kClassId, Class::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  Object::VerifyBuiltinVtable<FakeObject>(FakeObject::kClassId);
  result.set_token_pos(TokenPosition::kNoSource);
  result.set_end_token_pos(TokenPosition::kNoSource);
  result.set_instance_size(FakeObject::InstanceSize(),
                           compiler::target::RoundedAllocationSize(
                               TargetFakeObject::InstanceSize()));
  result.set_type_arguments_field_offset_in_words(kNoTypeArguments,
                                                  RTN::Class::kNoTypeArguments);
  const intptr_t host_next_field_offset = FakeObject::NextFieldOffset();
  const intptr_t target_next_field_offset = TargetFakeObject::NextFieldOffset();
  result.set_next_field_offset(host_next_field_offset,
                               target_next_field_offset);
  COMPILE_ASSERT((FakeObject::kClassId != kInstanceCid));
  result.set_id(FakeObject::kClassId);
  result.set_num_type_arguments(0);
  result.set_num_native_fields(0);
  result.set_state_bits(0);
  if ((FakeObject::kClassId < kInstanceCid) ||
      (FakeObject::kClassId == kTypeArgumentsCid)) {
    // VM internal classes are done. There is no finalization needed or
    // possible in this case.
    result.set_is_declaration_loaded();
    result.set_is_type_finalized();
    result.set_is_allocate_finalized();
  } else if (FakeObject::kClassId != kClosureCid) {
    // VM backed classes are almost ready: run checks and resolve class
    // references, but do not recompute size.
    result.set_is_prefinalized();
  }
  NOT_IN_PRECOMPILED(result.set_kernel_offset(0));
  result.InitEmptyFields();
  if (register_class) {
    isolate->class_table()->Register(result);
  }
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

void Class::set_has_pragma(bool value) const {
  set_state_bits(HasPragmaBit::update(value, state_bits()));
}

// Initialize class fields of type Array with empty array.
void Class::InitEmptyFields() {
  if (Object::empty_array().raw() == Array::null()) {
    // The empty array has not been initialized yet.
    return;
  }
  raw_ptr()->set_interfaces(Object::empty_array().raw());
  raw_ptr()->set_constants(Object::null_array().raw());
  set_functions(Object::empty_array());
  set_fields(Object::empty_array());
  set_invocation_dispatcher_cache(Object::empty_array());
}

ArrayPtr Class::OffsetToFieldMap(bool original_classes) const {
  if (raw_ptr()->offset_in_words_to_field() == Array::null()) {
    ASSERT(is_finalized());
    const intptr_t length = raw_ptr()->host_instance_size_in_words_;
    const Array& array = Array::Handle(Array::New(length, Heap::kOld));
    Class& cls = Class::Handle(this->raw());
    Array& fields = Array::Handle();
    Field& f = Field::Handle();
    while (!cls.IsNull()) {
      fields = cls.fields();
      for (intptr_t i = 0; i < fields.Length(); ++i) {
        f ^= fields.At(i);
        if (f.is_instance()) {
          array.SetAt(f.HostOffset() >> kWordSizeLog2, f);
        }
      }
      cls = cls.SuperClass(original_classes);
    }
    raw_ptr()->set_offset_in_words_to_field(array.raw());
  }
  return raw_ptr()->offset_in_words_to_field();
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
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadWriter());
#endif
  ASSERT(!value.IsNull());
  set_functions(value);
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
    raw_ptr()->set_functions_hash_table(set.Release().raw());
  } else {
    raw_ptr()->set_functions_hash_table(Array::null());
  }
}

void Class::AddFunction(const Function& function) const {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadWriter());
#endif
  const Array& arr = Array::Handle(functions());
  const Array& new_array =
      Array::Handle(Array::Grow(arr, arr.Length() + 1, Heap::kOld));
  new_array.SetAt(arr.Length(), function);
  set_functions(new_array);
  // Add to hash table, if any.
  const intptr_t new_len = new_array.Length();
  if (new_len == kFunctionLookupHashTreshold) {
    // Transition to using hash table.
    SetFunctions(new_array);
  } else if (new_len > kFunctionLookupHashTreshold) {
    ClassFunctionsSet set(raw_ptr()->functions_hash_table());
    set.Insert(function);
    raw_ptr()->set_functions_hash_table(set.Release().raw());
  }
}

FunctionPtr Class::FunctionFromIndex(intptr_t idx) const {
  const Array& funcs = Array::Handle(current_functions());
  if ((idx < 0) || (idx >= funcs.Length())) {
    return Function::null();
  }
  Function& func = Function::Handle();
  func ^= funcs.At(idx);
  ASSERT(!func.IsNull());
  return func.raw();
}

FunctionPtr Class::ImplicitClosureFunctionFromIndex(intptr_t idx) const {
  const Array& funcs = Array::Handle(current_functions());
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
  funcs = current_functions();
  ASSERT(!funcs.IsNull());
  Function& implicit_closure = Function::Handle(thread->zone());
  const intptr_t len = funcs.Length();
  for (intptr_t i = 0; i < len; i++) {
    function ^= funcs.At(i);
    implicit_closure = function.implicit_closure_function();
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
  funcs = invocation_dispatcher_cache();
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

FunctionPtr Class::InvocationDispatcherFunctionFromIndex(intptr_t idx) const {
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  Array& dispatcher_cache = thread->ArrayHandle();
  Object& object = thread->ObjectHandle();
  dispatcher_cache = invocation_dispatcher_cache();
  object = dispatcher_cache.At(idx);
  if (!object.IsFunction()) {
    return Function::null();
  }
  return Function::Cast(object).raw();
}

void Class::set_signature_function(const Function& value) const {
  ASSERT(value.IsClosureFunction() || value.IsSignatureFunction());
  raw_ptr()->set_signature_function(value.raw());
}

void Class::set_state_bits(intptr_t bits) const {
  StoreNonPointer<uint32_t, uint32_t, std::memory_order_release>(
      &raw_ptr()->state_bits_, static_cast<uint32_t>(bits));
}

void Class::set_library(const Library& value) const {
  raw_ptr()->set_library(value.raw());
}

void Class::set_type_parameters(const TypeArguments& value) const {
  ASSERT((num_type_arguments() == kUnknownNumTypeArguments) ||
         is_prefinalized());
  raw_ptr()->set_type_parameters(value.raw());
}

void Class::set_functions(const Array& value) const {
  // Ensure all writes to the [Function]s are visible by the time the array
  // is visible.
  raw_ptr()->set_functions<std::memory_order_release>(value.raw());
}

void Class::set_fields(const Array& value) const {
  // Ensure all writes to the [Field]s are visible by the time the array
  // is visible.
  raw_ptr()->set_fields<std::memory_order_release>(value.raw());
}

void Class::set_invocation_dispatcher_cache(const Array& cache) const {
  // Ensure all writes to the cache are visible by the time the array
  // is visible.
  raw_ptr()->set_invocation_dispatcher_cache<std::memory_order_release>(
      cache.raw());
}

intptr_t Class::NumTypeParameters(Thread* thread) const {
  if (!is_declaration_loaded()) {
    ASSERT(is_prefinalized());
    const intptr_t cid = id();
    if ((cid == kArrayCid) || (cid == kImmutableArrayCid) ||
        (cid == kGrowableObjectArrayCid)) {
      return 1;  // List's type parameter may not have been parsed yet.
    }
    return 0;
  }
  if (type_parameters() == TypeArguments::null()) {
    return 0;
  }
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(thread);
  TypeArguments& type_params = thread->TypeArgumentsHandle();
  type_params = type_parameters();
  return type_params.Length();
}

intptr_t Class::ComputeNumTypeArguments() const {
  ASSERT(is_declaration_loaded());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const intptr_t num_type_params = NumTypeParameters();

  if ((super_type() == AbstractType::null()) ||
      (super_type() == isolate->object_store()->object_type())) {
    return num_type_params;
  }

  const auto& sup_type = AbstractType::Handle(zone, super_type());
  ASSERT(sup_type.IsType());

  const auto& sup_class = Class::Handle(zone, sup_type.type_class());
  ASSERT(!sup_class.IsTypedefClass());

  const intptr_t sup_class_num_type_args = sup_class.NumTypeArguments();
  if (num_type_params == 0) {
    return sup_class_num_type_args;
  }

  const auto& sup_type_args = TypeArguments::Handle(zone, sup_type.arguments());
  if (sup_type_args.IsNull()) {
    // The super type is raw or the super class is non generic.
    // In either case, overlapping is not possible.
    return sup_class_num_type_args + num_type_params;
  }

  const intptr_t sup_type_args_length = sup_type_args.Length();
  // At this point, the super type may or may not be finalized. In either case,
  // the result of this function must remain the same.
  // The value of num_sup_type_args may increase when the super type is
  // finalized, but the last [sup_type_args_length] type arguments will not be
  // modified by finalization, only shifted to higher indices in the vector.
  // The super type may not even be resolved yet. This is not necessary, since
  // we only check for matching type parameters, which are resolved by default.
  const auto& type_params = TypeArguments::Handle(zone, type_parameters());
  // Determine the maximum overlap of a prefix of the vector consisting of the
  // type parameters of this class with a suffix of the vector consisting of the
  // type arguments of the super type of this class.
  // The number of own type arguments of this class is the number of its type
  // parameters minus the number of type arguments in the overlap.
  // Attempt to overlap the whole vector of type parameters; reduce the size
  // of the vector (keeping the first type parameter) until it fits or until
  // its size is zero.
  auto& type_param = TypeParameter::Handle(zone);
  auto& sup_type_arg = AbstractType::Handle(zone);
  for (intptr_t num_overlapping_type_args =
           (num_type_params < sup_type_args_length) ? num_type_params
                                                    : sup_type_args_length;
       num_overlapping_type_args > 0; num_overlapping_type_args--) {
    intptr_t i = 0;
    for (; i < num_overlapping_type_args; i++) {
      type_param ^= type_params.TypeAt(i);
      sup_type_arg = sup_type_args.TypeAt(sup_type_args_length -
                                          num_overlapping_type_args + i);
      if (!type_param.Equals(sup_type_arg)) break;
    }
    if (i == num_overlapping_type_args) {
      // Overlap found.
      return sup_class_num_type_args + num_type_params -
             num_overlapping_type_args;
    }
  }
  // No overlap found.
  return sup_class_num_type_args + num_type_params;
}

intptr_t Class::NumTypeArguments() const {
  // Return cached value if already calculated.
  intptr_t num_type_args = num_type_arguments();
  if (num_type_args != kUnknownNumTypeArguments) {
    return num_type_args;
  }

  num_type_args = ComputeNumTypeArguments();
  ASSERT(num_type_args != kUnknownNumTypeArguments);
  set_num_type_arguments(num_type_args);
  return num_type_args;
}

static TypeArgumentsPtr InstantiateTypeArgumentsToBounds(
    Thread* thread,
    const TypeArguments& parameters) {
  ASSERT(thread != nullptr);
  if (parameters.IsNull()) {
    return Object::empty_type_arguments().raw();
  }
  auto const zone = thread->zone();
  const auto& result = TypeArguments::Handle(
      zone, TypeArguments::New(parameters.Length(), Heap::kNew));
  auto& param = TypeParameter::Handle(zone);
  auto& type = AbstractType::Handle(zone);
  for (intptr_t i = 0, n = parameters.Length(); i < n; i++) {
    param ^= parameters.TypeAt(i);
    type = param.default_argument();
    ASSERT(type.IsFinalized());
    result.SetTypeAt(i, type);
  }
  return result.Canonicalize(thread);
}

TypeArgumentsPtr Class::InstantiateToBounds(Thread* thread) const {
  const auto& type_params =
      TypeArguments::Handle(thread->zone(), type_parameters());
  return InstantiateTypeArgumentsToBounds(thread, type_params);
}

ClassPtr Class::SuperClass(bool original_classes) const {
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
  ASSERT(value.IsNull() || (value.IsType() && !value.IsDynamicType()));
  raw_ptr()->set_super_type(value.raw());
}

TypeParameterPtr Class::LookupTypeParameter(const String& type_name) const {
  ASSERT(!type_name.IsNull());
  Thread* thread = Thread::Current();
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(thread);
  REUSABLE_TYPE_PARAMETER_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  TypeArguments& type_params = thread->TypeArgumentsHandle();
  TypeParameter& type_param = thread->TypeParameterHandle();
  String& type_param_name = thread->StringHandle();

  type_params = type_parameters();
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

UnboxedFieldBitmap Class::CalculateFieldOffsets() const {
  Array& flds = Array::Handle(fields());
  const Class& super = Class::Handle(SuperClass());
  intptr_t host_offset = 0;
  UnboxedFieldBitmap host_bitmap{};
  // Target offsets might differ if the word size are different
  intptr_t target_offset = 0;
  intptr_t host_type_args_field_offset = kNoTypeArguments;
  intptr_t target_type_args_field_offset = RTN::Class::kNoTypeArguments;
  if (super.IsNull()) {
    host_offset = Instance::NextFieldOffset();
    target_offset = RTN::Instance::NextFieldOffset();
    ASSERT(host_offset > 0);
    ASSERT(target_offset > 0);
  } else {
    ASSERT(super.is_finalized() || super.is_prefinalized());
    host_type_args_field_offset = super.host_type_arguments_field_offset();
    target_type_args_field_offset = super.target_type_arguments_field_offset();
    host_offset = super.host_next_field_offset();
    ASSERT(host_offset > 0);
    target_offset = super.target_next_field_offset();
    ASSERT(target_offset > 0);
    // We should never call CalculateFieldOffsets for native wrapper
    // classes, assert this.
    ASSERT(num_native_fields() == 0);
    set_num_native_fields(super.num_native_fields());

    if (FLAG_precompiled_mode) {
      host_bitmap = Isolate::Current()
                        ->group()
                        ->shared_class_table()
                        ->GetUnboxedFieldsMapAt(super.id());
    }
  }
  // If the super class is parameterized, use the same type_arguments field,
  // otherwise, if this class is the first in the super chain to be
  // parameterized, introduce a new type_arguments field.
  if (host_type_args_field_offset == kNoTypeArguments) {
    ASSERT(target_type_args_field_offset == RTN::Class::kNoTypeArguments);
    const TypeArguments& type_params = TypeArguments::Handle(type_parameters());
    if (!type_params.IsNull()) {
      ASSERT(type_params.Length() > 0);
      // The instance needs a type_arguments field.
      host_type_args_field_offset = host_offset;
      target_type_args_field_offset = target_offset;
      host_offset += kWordSize;
      target_offset += compiler::target::kWordSize;
    }
  } else {
    ASSERT(target_type_args_field_offset != RTN::Class::kNoTypeArguments);
  }

  set_type_arguments_field_offset(host_type_args_field_offset,
                                  target_type_args_field_offset);
  ASSERT(host_offset > 0);
  ASSERT(target_offset > 0);
  Field& field = Field::Handle();
  const intptr_t len = flds.Length();
  for (intptr_t i = 0; i < len; i++) {
    field ^= flds.At(i);
    // Offset is computed only for instance fields.
    if (!field.is_static()) {
      ASSERT(field.HostOffset() == 0);
      ASSERT(field.TargetOffset() == 0);
      field.SetOffset(host_offset, target_offset);

      if (FLAG_precompiled_mode && field.is_unboxing_candidate()) {
        intptr_t field_size;
        switch (field.guarded_cid()) {
          case kDoubleCid:
            field_size = sizeof(DoubleLayout::value_);
            break;
          case kFloat32x4Cid:
            field_size = sizeof(Float32x4Layout::value_);
            break;
          case kFloat64x2Cid:
            field_size = sizeof(Float64x2Layout::value_);
            break;
          default:
            if (field.is_non_nullable_integer()) {
              field_size = sizeof(MintLayout::value_);
            } else {
              UNREACHABLE();
              field_size = 0;
            }
            break;
        }

        const intptr_t host_num_words = field_size / kWordSize;
        const intptr_t host_next_offset = host_offset + field_size;
        const intptr_t host_next_position = host_next_offset / kWordSize;

        const intptr_t target_next_offset = target_offset + field_size;
        const intptr_t target_next_position =
            target_next_offset / compiler::target::kWordSize;

        // The bitmap has fixed length. Checks if the offset position is smaller
        // than its length. If it is not, than the field should be boxed
        if (host_next_position <= UnboxedFieldBitmap::Length() &&
            target_next_position <= UnboxedFieldBitmap::Length()) {
          for (intptr_t j = 0; j < host_num_words; j++) {
            // Activate the respective bit in the bitmap, indicating that the
            // content is not a pointer
            host_bitmap.Set(host_offset / kWordSize);
            host_offset += kWordSize;
          }

          ASSERT(host_offset == host_next_offset);
          target_offset = target_next_offset;
        } else {
          // Make the field boxed
          field.set_is_unboxing_candidate(false);
          host_offset += kWordSize;
          target_offset += compiler::target::kWordSize;
        }
      } else {
        host_offset += kWordSize;
        target_offset += compiler::target::kWordSize;
      }
    }
  }
  set_instance_size(RoundedAllocationSize(host_offset),
                    compiler::target::RoundedAllocationSize(target_offset));
  set_next_field_offset(host_offset, target_offset);

  return host_bitmap;
}

void Class::AddInvocationDispatcher(const String& target_name,
                                    const Array& args_desc,
                                    const Function& dispatcher) const {
  auto thread = Thread::Current();
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadWriter());

  auto zone = thread->zone();
  auto& cache = Array::Handle(zone, invocation_dispatcher_cache());
  InvocationDispatcherTable dispatchers(cache);
  intptr_t i = 0;
  for (auto dispatcher : dispatchers) {
    if (dispatcher.Get<kInvocationDispatcherName>() == String::null()) {
      break;
    }
    i++;
  }
  if (i == dispatchers.Length()) {
    const intptr_t new_len =
        cache.Length() == 0
            ? static_cast<intptr_t>(Class::kInvocationDispatcherEntrySize)
            : cache.Length() * 2;
    cache = Array::Grow(cache, new_len);
    set_invocation_dispatcher_cache(cache);
  }
  // Ensure all stores are visible at the point the name is visible.
  auto entry = dispatchers[i];
  entry.Set<Class::kInvocationDispatcherArgsDesc>(args_desc);
  entry.Set<Class::kInvocationDispatcherFunction>(dispatcher);
  entry.Set<Class::kInvocationDispatcherName, std::memory_order_release>(
      target_name);
}

FunctionPtr Class::GetInvocationDispatcher(const String& target_name,
                                           const Array& args_desc,
                                           FunctionLayout::Kind kind,
                                           bool create_if_absent) const {
  ASSERT(kind == FunctionLayout::kNoSuchMethodDispatcher ||
         kind == FunctionLayout::kInvokeFieldDispatcher ||
         kind == FunctionLayout::kDynamicInvocationForwarder);
  auto thread = Thread::Current();
  auto Z = thread->zone();
  auto& function = Function::Handle(Z);
  auto& name = String::Handle(Z);
  auto& desc = Array::Handle(Z);
  auto& cache = Array::Handle(Z);

  auto find_entry = [&]() {
    cache = invocation_dispatcher_cache();
    ASSERT(!cache.IsNull());
    InvocationDispatcherTable dispatchers(cache);
    for (auto dispatcher : dispatchers) {
      // Ensure all loads are done after loading the name.
      name = dispatcher.Get<Class::kInvocationDispatcherName,
                            std::memory_order_acquire>();
      if (name.IsNull()) break;  // Reached last entry.
      if (!name.Equals(target_name)) continue;
      desc = dispatcher.Get<Class::kInvocationDispatcherArgsDesc>();
      if (desc.raw() != args_desc.raw()) continue;
      function = dispatcher.Get<Class::kInvocationDispatcherFunction>();
      if (function.kind() == kind) {
        return function.raw();
      }
    }
    return Function::null();
  };

  // First we'll try to find it without using locks.
  function = find_entry();
  if (!function.IsNull() || !create_if_absent) {
    return function.raw();
  }

  // If we failed to find it and possibly need to create it, use a write lock.
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  // Try to find it again & return if it was added in the meantime.
  function = find_entry();
  if (!function.IsNull()) return function.raw();

  // Otherwise create it & add it.
  function = CreateInvocationDispatcher(target_name, args_desc, kind);
  AddInvocationDispatcher(target_name, args_desc, function);
  return function.raw();
}

FunctionPtr Class::CreateInvocationDispatcher(const String& target_name,
                                              const Array& args_desc,
                                              FunctionLayout::Kind kind) const {
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
    // The presence of a type parameter array is enough to mark this dispatcher
    // as generic. To save memory, we do not copy the type parameters to the
    // array (they are not accessed), but leave it as an array of null objects.
    invocation.set_type_parameters(type_params);
  }

  invocation.set_num_fixed_parameters(desc.PositionalCount());
  invocation.SetNumOptionalParameters(desc.NamedCount(),
                                      false);  // Not positional.
  invocation.set_parameter_types(
      Array::Handle(zone, Array::New(desc.Count(), Heap::kOld)));
  invocation.CreateNameArrayIncludingFlags(Heap::kOld);
  // Receiver.
  invocation.SetParameterTypeAt(0, Object::dynamic_type());
  invocation.SetParameterNameAt(0, Symbols::This());
  // Remaining positional parameters.
  for (intptr_t i = 1; i < desc.PositionalCount(); i++) {
    invocation.SetParameterTypeAt(i, Object::dynamic_type());
    char name[64];
    Utils::SNPrint(name, 64, ":p%" Pd, i);
    invocation.SetParameterNameAt(
        i, String::Handle(zone, Symbols::New(thread, name)));
  }

  // Named parameters.
  for (intptr_t i = 0; i < desc.NamedCount(); i++) {
    const intptr_t param_index = desc.PositionAt(i);
    const auto& param_name = String::Handle(zone, desc.NameAt(i));
    invocation.SetParameterTypeAt(param_index, Object::dynamic_type());
    invocation.SetParameterNameAt(param_index, param_name);
  }
  invocation.TruncateUnusedParameterFlags();
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
FunctionPtr Function::CreateMethodExtractor(const String& getter_name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(Field::IsGetterName(getter_name));
  const Function& closure_function =
      Function::Handle(zone, ImplicitClosureFunction());

  const Class& owner = Class::Handle(zone, closure_function.Owner());
  Function& extractor = Function::Handle(
      zone,
      Function::New(String::Handle(zone, Symbols::New(thread, getter_name)),
                    FunctionLayout::kMethodExtractor,
                    false,  // Not static.
                    false,  // Not const.
                    is_abstract(),
                    false,  // Not external.
                    false,  // Not native.
                    owner, TokenPosition::kMethodExtractor));

  // Initialize signature: receiver is a single fixed parameter.
  const intptr_t kNumParameters = 1;
  extractor.set_num_fixed_parameters(kNumParameters);
  extractor.SetNumOptionalParameters(0, false);
  extractor.set_parameter_types(Object::extractor_parameter_types());
  extractor.set_parameter_names(Object::extractor_parameter_names());
  extractor.set_result_type(Object::dynamic_type());

  extractor.InheritKernelOffsetFrom(*this);

  extractor.set_extracted_method_closure(closure_function);
  extractor.set_is_debuggable(false);
  extractor.set_is_visible(false);

  owner.AddFunction(extractor);

  return extractor.raw();
}

FunctionPtr Function::GetMethodExtractor(const String& getter_name) const {
  ASSERT(Field::IsGetterName(getter_name));
  const Function& closure_function =
      Function::Handle(ImplicitClosureFunction());
  const Class& owner = Class::Handle(closure_function.Owner());
  Thread* thread = Thread::Current();
  if (owner.EnsureIsFinalized(thread) != Error::null()) {
    return Function::null();
  }
  IsolateGroup* group = thread->isolate_group();
  Function& result = Function::Handle(
      Resolver::ResolveDynamicFunction(thread->zone(), owner, getter_name));
  if (result.IsNull()) {
    SafepointWriteRwLocker ml(thread, group->program_lock());
    result = owner.LookupDynamicFunctionUnsafe(getter_name);
    if (result.IsNull()) {
      result = CreateMethodExtractor(getter_name);
    }
  }
  ASSERT(result.kind() == FunctionLayout::kMethodExtractor);
  return result.raw();
}

bool Library::FindPragma(Thread* T,
                         bool only_core,
                         const Object& obj,
                         const String& pragma_name,
                         Object* options) {
  auto I = T->isolate();
  auto Z = T->zone();
  auto& lib = Library::Handle(Z);

  if (obj.IsClass()) {
    auto& klass = Class::Cast(obj);
    if (!klass.has_pragma()) return false;
    lib = klass.library();
  } else if (obj.IsFunction()) {
    auto& function = Function::Cast(obj);
    if (!function.has_pragma()) return false;
    lib = Class::Handle(Z, function.Owner()).library();
  } else if (obj.IsField()) {
    auto& field = Field::Cast(obj);
    if (!field.has_pragma()) return false;
    lib = Class::Handle(Z, field.Owner()).library();
  } else {
    UNREACHABLE();
  }

  if (only_core && !lib.IsAnyCoreLibrary()) {
    return false;
  }

  Object& metadata_obj = Object::Handle(Z, lib.GetMetadata(obj));
  if (metadata_obj.IsUnwindError()) {
    Report::LongJump(UnwindError::Cast(metadata_obj));
  }

  // If there is a compile-time error while evaluating the metadata, we will
  // simply claim there was no @pramga annotation.
  if (metadata_obj.IsNull() || metadata_obj.IsLanguageError()) {
    return false;
  }
  ASSERT(metadata_obj.IsArray());

  auto& metadata = Array::Cast(metadata_obj);
  auto& pragma_class = Class::Handle(Z, I->object_store()->pragma_class());
  auto& pragma_name_field =
      Field::Handle(Z, pragma_class.LookupField(Symbols::name()));
  auto& pragma_options_field =
      Field::Handle(Z, pragma_class.LookupField(Symbols::options()));

  auto& pragma = Object::Handle(Z);
  for (intptr_t i = 0; i < metadata.Length(); ++i) {
    pragma = metadata.At(i);
    if (pragma.clazz() != pragma_class.raw() ||
        Instance::Cast(pragma).GetField(pragma_name_field) !=
            pragma_name.raw()) {
      continue;
    }
    *options = Instance::Cast(pragma).GetField(pragma_options_field);
    return true;
  }

  return false;
}

bool Function::IsDynamicInvocationForwarderName(const String& name) {
  return IsDynamicInvocationForwarderName(name.raw());
}

bool Function::IsDynamicInvocationForwarderName(StringPtr name) {
  return String::StartsWith(name, Symbols::DynamicPrefix().raw());
}

StringPtr Function::DemangleDynamicInvocationForwarderName(const String& name) {
  const intptr_t kDynamicPrefixLength = 4;  // "dyn:"
  ASSERT(Symbols::DynamicPrefix().Length() == kDynamicPrefixLength);
  return Symbols::New(Thread::Current(), name, kDynamicPrefixLength,
                      name.Length() - kDynamicPrefixLength);
}

StringPtr Function::CreateDynamicInvocationForwarderName(const String& name) {
  return Symbols::FromConcat(Thread::Current(), Symbols::DynamicPrefix(), name);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
FunctionPtr Function::CreateDynamicInvocationForwarder(
    const String& mangled_name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  Function& forwarder = Function::Handle(zone);
  forwarder ^= Object::Clone(*this, Heap::kOld);

  forwarder.reset_unboxed_parameters_and_return();

  forwarder.set_name(mangled_name);
  forwarder.set_is_native(false);
  // TODO(dartbug.com/37737): Currently, we intentionally keep the recognized
  // kind when creating the dynamic invocation forwarder.
  forwarder.set_kind(FunctionLayout::kDynamicInvocationForwarder);
  forwarder.set_is_debuggable(false);

  // TODO(vegorov) for error reporting reasons it is better to make this
  // function visible and instead use a TailCall to invoke the target.
  // Our TailCall instruction is not ready for such usage though it
  // blocks inlining and can't take Function-s only Code objects.
  forwarder.set_is_visible(false);

  forwarder.ClearICDataArray();
  forwarder.ClearCode();
  forwarder.set_usage_counter(0);
  forwarder.set_deoptimization_counter(0);
  forwarder.set_optimized_instruction_count(0);
  forwarder.set_inlining_depth(0);
  forwarder.set_optimized_call_site_count(0);

  forwarder.InheritKernelOffsetFrom(*this);

  const Array& checks = Array::Handle(zone, Array::New(1));
  checks.SetAt(0, *this);
  forwarder.SetForwardingChecks(checks);

  return forwarder.raw();
}

FunctionPtr Function::GetDynamicInvocationForwarder(
    const String& mangled_name,
    bool allow_add /*=true*/) const {
  ASSERT(IsDynamicInvocationForwarderName(mangled_name));
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const Class& owner = Class::Handle(zone, Owner());
  Function& result = Function::Handle(zone);

  // First we'll try to find it without using locks.
  result =
      owner.GetInvocationDispatcher(mangled_name, Array::null_array(),
                                    FunctionLayout::kDynamicInvocationForwarder,
                                    /*create_if_absent=*/false);
  if (!result.IsNull()) return result.raw();

  const bool needs_dyn_forwarder =
      kernel::NeedsDynamicInvocationForwarder(*this);
  if (!allow_add) {
    return needs_dyn_forwarder ? Function::null() : raw();
  }

  // If we failed to find it and possibly need to create it, use a write lock.
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  // Try to find it again & return if it was added in the mean time.
  result =
      owner.GetInvocationDispatcher(mangled_name, Array::null_array(),
                                    FunctionLayout::kDynamicInvocationForwarder,
                                    /*create_if_absent=*/false);
  if (!result.IsNull()) return result.raw();

  // Otherwise create it & add it.
  result = needs_dyn_forwarder ? CreateDynamicInvocationForwarder(mangled_name)
                               : raw();
  owner.AddInvocationDispatcher(mangled_name, Array::null_array(), result);

  return result.raw();
}

#endif

bool AbstractType::InstantiateAndTestSubtype(
    AbstractType* subtype,
    AbstractType* supertype,
    const TypeArguments& instantiator_type_args,
    const TypeArguments& function_type_args) {
  if (!subtype->IsInstantiated()) {
    *subtype = subtype->InstantiateFrom(
        instantiator_type_args, function_type_args, kAllFree, Heap::kOld);
  }
  if (!supertype->IsInstantiated()) {
    *supertype = supertype->InstantiateFrom(
        instantiator_type_args, function_type_args, kAllFree, Heap::kOld);
  }
  return subtype->IsSubtypeOf(*supertype, Heap::kOld);
}

ArrayPtr Class::invocation_dispatcher_cache() const {
  return raw_ptr()->invocation_dispatcher_cache();
}

void Class::Finalize() const {
  auto thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(thread->IsMutatorThread());
  ASSERT(!isolate->all_classes_finalized());
  ASSERT(!is_finalized());
  // Prefinalized classes have a VM internal representation and no Dart fields.
  // Their instance size  is precomputed and field offsets are known.
  if (!is_prefinalized()) {
    // Compute offsets of instance fields, instance size and bitmap for unboxed
    // fields.
    const auto host_bitmap = CalculateFieldOffsets();
    if (raw() == isolate->class_table()->At(id())) {
      // Sets the new size in the class table.
      isolate->class_table()->SetAt(id(), raw());
      if (FLAG_precompiled_mode && !ClassTable::IsTopLevelCid(id())) {
        isolate->group()->shared_class_table()->SetUnboxedFieldsMapAt(
            id(), host_bitmap);
      }
    }
  }

#if defined(DEBUG)
  if (is_const()) {
    // Double-check that all fields are final (CFE should guarantee that if it
    // marks the class as having a constant constructor).
    auto Z = thread->zone();
    const auto& super_class = Class::Handle(Z, SuperClass());
    ASSERT(super_class.IsNull() || super_class.is_const());
    const auto& fields = Array::Handle(Z, this->fields());
    auto& field = Field::Handle(Z);
    for (intptr_t i = 0; i < fields.Length(); ++i) {
      field ^= fields.At(i);
      ASSERT(field.is_static() || field.is_final());
    }
  }
#endif

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
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  // TODO(dartbug.com/36097): The program_lock acquisition has to move up the
  // call chain to ClassFinalizer::AllocateFinalizeClass() so that:
  //   - no two threads allocate-finalize a class at the same time(we should
  // use the logic similar to what is used in EnsureIsAllocateFinalized()).
  //   - code is deoptimized before we violate optimization assumptions
  // potentially done concurrently (AddDirectSubclass/AddDirectImplementor).
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  CHACodeArray a(*this);
  if (FLAG_trace_deoptimization && a.HasCodes()) {
    if (subclass.IsNull()) {
      THR_Print("Deopt for CHA (all)\n");
    } else {
      THR_Print("Deopt for CHA (new subclass %s)\n", subclass.ToCString());
    }
  }
  a.DisableCode();
}

void Class::DisableAllCHAOptimizedCode() {
  DisableCHAOptimizedCode(Class::Handle());
}

bool Class::TraceAllocation(Isolate* isolate) const {
#ifndef PRODUCT
  auto class_table = isolate->group()->shared_class_table();
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
    auto class_table = isolate->group()->shared_class_table();
    class_table->SetTraceAllocationFor(id(), trace_allocation);
    DisableAllocationStub();
  }
#else
  UNREACHABLE();
#endif
}

ArrayPtr Class::dependent_code() const {
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
  return raw_ptr()->dependent_code();
}

void Class::set_dependent_code(const Array& array) const {
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  raw_ptr()->set_dependent_code(array.raw());
}

// Conventions:
// * For throwing a NSM in a class klass we use its runtime type as receiver,
//   i.e., klass.RareType().
// * For throwing a NSM in a library, we just pass the null instance as
//   receiver.
static ObjectPtr ThrowNoSuchMethod(const Instance& receiver,
                                   const String& function_name,
                                   const Array& arguments,
                                   const Array& argument_names,
                                   const InvocationMirror::Level level,
                                   const InvocationMirror::Kind kind) {
  const Smi& invocation_type =
      Smi::Handle(Smi::New(InvocationMirror::EncodeType(level, kind)));

  const Array& args = Array::Handle(Array::New(7));
  args.SetAt(0, receiver);
  args.SetAt(1, function_name);
  args.SetAt(2, invocation_type);
  args.SetAt(3, Object::smi_zero());  // Type arguments length.
  args.SetAt(4, Object::null_type_arguments());
  args.SetAt(5, arguments);
  args.SetAt(6, argument_names);

  const Library& libcore = Library::Handle(Library::CoreLibrary());
  const Class& cls =
      Class::Handle(libcore.LookupClass(Symbols::NoSuchMethodError()));
  ASSERT(!cls.IsNull());
  const auto& error = cls.EnsureIsFinalized(Thread::Current());
  ASSERT(error == Error::null());
  const Function& throwNew =
      Function::Handle(cls.LookupFunctionAllowPrivate(Symbols::ThrowNew()));
  return DartEntry::InvokeFunction(throwNew, args);
}

static ObjectPtr ThrowTypeError(const TokenPosition token_pos,
                                const Instance& src_value,
                                const AbstractType& dst_type,
                                const String& dst_name) {
  const Array& args = Array::Handle(Array::New(4));
  const Smi& pos = Smi::Handle(Smi::New(token_pos.Serialize()));
  args.SetAt(0, pos);
  args.SetAt(1, src_value);
  args.SetAt(2, dst_type);
  args.SetAt(3, dst_name);

  const Library& libcore = Library::Handle(Library::CoreLibrary());
  const Class& cls =
      Class::Handle(libcore.LookupClassAllowPrivate(Symbols::TypeError()));
  const auto& error = cls.EnsureIsFinalized(Thread::Current());
  ASSERT(error == Error::null());
  const Function& throwNew =
      Function::Handle(cls.LookupFunctionAllowPrivate(Symbols::ThrowNew()));
  return DartEntry::InvokeFunction(throwNew, args);
}

ObjectPtr Class::InvokeGetter(const String& getter_name,
                              bool throw_nsm_if_absent,
                              bool respect_reflectable,
                              bool check_is_entrypoint) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  CHECK_ERROR(EnsureIsFinalized(thread));

  // Note static fields do not have implicit getters.
  const Field& field = Field::Handle(zone, LookupStaticField(getter_name));

  if (!field.IsNull() && check_is_entrypoint) {
    CHECK_ERROR(field.VerifyEntryPoint(EntryPointPragma::kGetterOnly));
  }

  if (field.IsNull() || field.IsUninitialized()) {
    const String& internal_getter_name =
        String::Handle(zone, Field::GetterName(getter_name));
    Function& getter =
        Function::Handle(zone, LookupStaticFunction(internal_getter_name));

    if (field.IsNull() && !getter.IsNull() && check_is_entrypoint) {
      CHECK_ERROR(getter.VerifyCallEntryPoint());
    }

    if (getter.IsNull() || (respect_reflectable && !getter.is_reflectable())) {
      if (getter.IsNull()) {
        getter = LookupStaticFunction(getter_name);
        if (!getter.IsNull()) {
          if (check_is_entrypoint) {
            CHECK_ERROR(getter.VerifyClosurizedEntryPoint());
          }
          if (getter.SafeToClosurize()) {
            // Looking for a getter but found a regular method: closurize it.
            const Function& closure_function =
                Function::Handle(zone, getter.ImplicitClosureFunction());
            return closure_function.ImplicitStaticClosure();
          }
        }
      }
      if (throw_nsm_if_absent) {
        return ThrowNoSuchMethod(
            AbstractType::Handle(zone, RareType()), getter_name,
            Object::null_array(), Object::null_array(),
            InvocationMirror::kStatic, InvocationMirror::kGetter);
      }
      // Fall through case: Indicate that we didn't find any function or field
      // using a special null instance. This is different from a field being
      // null. Callers make sure that this null does not leak into Dartland.
      return Object::sentinel().raw();
    }

    // Invoke the getter and return the result.
    return DartEntry::InvokeFunction(getter, Object::empty_array());
  }

  return field.StaticValue();
}

ObjectPtr Class::InvokeSetter(const String& setter_name,
                              const Instance& value,
                              bool respect_reflectable,
                              bool check_is_entrypoint) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  CHECK_ERROR(EnsureIsFinalized(thread));

  // Check for real fields and user-defined setters.
  const Field& field = Field::Handle(zone, LookupStaticField(setter_name));
  const String& internal_setter_name =
      String::Handle(zone, Field::SetterName(setter_name));

  if (!field.IsNull() && check_is_entrypoint) {
    CHECK_ERROR(field.VerifyEntryPoint(EntryPointPragma::kSetterOnly));
  }

  AbstractType& parameter_type = AbstractType::Handle(zone);
  if (field.IsNull()) {
    const Function& setter =
        Function::Handle(zone, LookupStaticFunction(internal_setter_name));
    if (!setter.IsNull() && check_is_entrypoint) {
      CHECK_ERROR(setter.VerifyCallEntryPoint());
    }
    const int kNumArgs = 1;
    const Array& args = Array::Handle(zone, Array::New(kNumArgs));
    args.SetAt(0, value);
    if (setter.IsNull() || (respect_reflectable && !setter.is_reflectable())) {
      return ThrowNoSuchMethod(AbstractType::Handle(zone, RareType()),
                               internal_setter_name, args, Object::null_array(),
                               InvocationMirror::kStatic,
                               InvocationMirror::kSetter);
    }
    parameter_type = setter.ParameterTypeAt(0);
    if (!value.RuntimeTypeIsSubtypeOf(parameter_type,
                                      Object::null_type_arguments(),
                                      Object::null_type_arguments())) {
      const String& argument_name =
          String::Handle(zone, setter.ParameterNameAt(0));
      return ThrowTypeError(setter.token_pos(), value, parameter_type,
                            argument_name);
    }
    // Invoke the setter and return the result.
    return DartEntry::InvokeFunction(setter, args);
  }

  if (field.is_final() || (respect_reflectable && !field.is_reflectable())) {
    const int kNumArgs = 1;
    const Array& args = Array::Handle(zone, Array::New(kNumArgs));
    args.SetAt(0, value);
    return ThrowNoSuchMethod(AbstractType::Handle(zone, RareType()),
                             internal_setter_name, args, Object::null_array(),
                             InvocationMirror::kStatic,
                             InvocationMirror::kSetter);
  }

  parameter_type = field.type();
  if (!value.RuntimeTypeIsSubtypeOf(parameter_type,
                                    Object::null_type_arguments(),
                                    Object::null_type_arguments())) {
    const String& argument_name = String::Handle(zone, field.name());
    return ThrowTypeError(field.token_pos(), value, parameter_type,
                          argument_name);
  }
  field.SetStaticValue(value);
  return value.raw();
}

// Creates a new array of boxed arguments suitable for invoking the callable
// from the original boxed arguments for a static call. Also sets the contents
// of the handle pointed to by [callable_args_desc_array_out] to an appropriate
// arguments descriptor array for the new arguments.
//
// Assumes [arg_names] are consistent with [static_args_descriptor].
static ArrayPtr CreateCallableArgumentsFromStatic(
    Zone* zone,
    const Instance& receiver,
    const Array& static_args,
    const Array& arg_names,
    const ArgumentsDescriptor& static_args_descriptor) {
  const intptr_t num_static_type_args = static_args_descriptor.TypeArgsLen();
  const intptr_t num_static_args = static_args_descriptor.Count();
  // Double check that the static args descriptor expects boxed arguments
  // and the static args descriptor is consistent with the static arguments.
  ASSERT_EQUAL(static_args_descriptor.Size(), num_static_args);
  ASSERT_EQUAL(static_args.Length(),
               num_static_args + (num_static_type_args > 0 ? 1 : 0));
  // Add an additional slot to store the callable as the receiver.
  const auto& callable_args =
      Array::Handle(zone, Array::New(static_args.Length() + 1));
  const intptr_t first_arg_index = static_args_descriptor.FirstArgIndex();
  auto& temp = Object::Handle(zone);
  // Copy the static args into the corresponding slots of the callable args.
  if (num_static_type_args > 0) {
    temp = static_args.At(0);
    callable_args.SetAt(0, temp);
  }
  for (intptr_t i = first_arg_index; i < static_args.Length(); i++) {
    temp = static_args.At(i);
    callable_args.SetAt(i + 1, temp);
  }
  // Set the receiver slot in the callable args.
  callable_args.SetAt(first_arg_index, receiver);
  return callable_args.raw();
}

ObjectPtr Class::Invoke(const String& function_name,
                        const Array& args,
                        const Array& arg_names,
                        bool respect_reflectable,
                        bool check_is_entrypoint) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  CHECK_ERROR(EnsureIsFinalized(thread));

  // We don't pass any explicit type arguments, which will be understood as
  // using dynamic for any function type arguments by lower layers.
  const int kTypeArgsLen = 0;
  const Array& args_descriptor_array = Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length(),
                                          arg_names, Heap::kNew));
  ArgumentsDescriptor args_descriptor(args_descriptor_array);

  Function& function =
      Function::Handle(zone, LookupStaticFunction(function_name));

  if (!function.IsNull() && check_is_entrypoint) {
    CHECK_ERROR(function.VerifyCallEntryPoint());
  }

  if (function.IsNull()) {
    // Didn't find a method: try to find a getter and invoke call on its result.
    const Object& getter_result = Object::Handle(
        zone, InvokeGetter(function_name, false, respect_reflectable,
                           check_is_entrypoint));
    if (getter_result.raw() != Object::sentinel().raw()) {
      if (check_is_entrypoint) {
        CHECK_ERROR(EntryPointFieldInvocationError(function_name));
      }
      const auto& call_args_descriptor_array = Array::Handle(
          zone, ArgumentsDescriptor::NewBoxed(args_descriptor.TypeArgsLen(),
                                              args_descriptor.Count() + 1,
                                              arg_names, Heap::kNew));
      const auto& call_args = Array::Handle(
          zone,
          CreateCallableArgumentsFromStatic(zone, Instance::Cast(getter_result),
                                            args, arg_names, args_descriptor));
      return DartEntry::InvokeClosure(thread, call_args,
                                      call_args_descriptor_array);
    }
  }

  if (function.IsNull() ||
      !function.AreValidArguments(args_descriptor, nullptr) ||
      (respect_reflectable && !function.is_reflectable())) {
    return ThrowNoSuchMethod(
        AbstractType::Handle(zone, RareType()), function_name, args, arg_names,
        InvocationMirror::kStatic, InvocationMirror::kMethod);
  }
  // This is a static function, so we pass an empty instantiator tav.
  ASSERT(function.is_static());
  ObjectPtr type_error = function.DoArgumentTypesMatch(
      args, args_descriptor, Object::empty_type_arguments());
  if (type_error != Error::null()) {
    return type_error;
  }
  return DartEntry::InvokeFunction(function, args, args_descriptor_array);
}

static ObjectPtr EvaluateCompiledExpressionHelper(
    const ExternalTypedData& kernel_buffer,
    const Array& type_definitions,
    const String& library_url,
    const String& klass,
    const Array& arguments,
    const TypeArguments& type_arguments);

ObjectPtr Class::EvaluateCompiledExpression(
    const ExternalTypedData& kernel_buffer,
    const Array& type_definitions,
    const Array& arguments,
    const TypeArguments& type_arguments) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  if (id() < kInstanceCid || id() == kTypeArgumentsCid) {
    const Instance& exception = Instance::Handle(String::New(
        "Expressions can be evaluated only with regular Dart instances"));
    const Instance& stacktrace = Instance::Handle();
    return UnhandledException::New(exception, stacktrace);
  }

  return EvaluateCompiledExpressionHelper(
      kernel_buffer, type_definitions,
      String::Handle(Library::Handle(library()).url()),
      IsTopLevel() ? String::Handle() : String::Handle(UserVisibleName()),
      arguments, type_arguments);
}

void Class::EnsureDeclarationLoaded() const {
  if (!is_declaration_loaded()) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    FATAL1("Unable to use class %s which is not loaded yet.", ToCString());
#endif
  }
}

// Ensure that top level parsing of the class has been done.
ErrorPtr Class::EnsureIsFinalized(Thread* thread) const {
  ASSERT(!IsNull());
  if (is_finalized()) {
    return Error::null();
  }
  if (Compiler::IsBackgroundCompilation()) {
    Compiler::AbortBackgroundCompilation(DeoptId::kNone,
                                         "Class finalization while compiling");
  }
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if (is_finalized()) {
    return Error::null();
  }
  LeaveCompilerScope ncs(thread);
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread != NULL);
  const Error& error =
      Error::Handle(thread->zone(), ClassFinalizer::LoadClassMembers(*this));
  if (!error.IsNull()) {
    ASSERT(thread == Thread::Current());
    if (thread->long_jump_base() != NULL) {
      Report::LongJump(error);
      UNREACHABLE();
    }
  }
  return error.raw();
}

// Ensure that code outdated by finalized class is cleaned up, new instance of
// this class is ready to be allocated.
ErrorPtr Class::EnsureIsAllocateFinalized(Thread* thread) const {
  ASSERT(!IsNull());
  if (is_allocate_finalized()) {
    return Error::null();
  }
  if (Compiler::IsBackgroundCompilation()) {
    Compiler::AbortBackgroundCompilation(
        DeoptId::kNone, "Class allocate finalization while compiling");
  }
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if (is_allocate_finalized()) {
    return Error::null();
  }
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread != NULL);
  Error& error = Error::Handle(thread->zone(), EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    ASSERT(thread == Thread::Current());
    if (thread->long_jump_base() != NULL) {
      Report::LongJump(error);
      UNREACHABLE();
    }
  }
  // May be allocate-finalized recursively during EnsureIsFinalized.
  if (is_allocate_finalized()) {
    return Error::null();
  }
  error ^= ClassFinalizer::AllocateFinalizeClass(*this);
  return error.raw();
}

void Class::SetFields(const Array& value) const {
  ASSERT(!value.IsNull());
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadWriter());
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
  set_fields(value);
}

void Class::AddField(const Field& field) const {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadWriter());
#endif
  const Array& arr = Array::Handle(fields());
  const Array& new_arr = Array::Handle(Array::Grow(arr, arr.Length() + 1));
  new_arr.SetAt(arr.Length(), field);
  SetFields(new_arr);
}

void Class::AddFields(const GrowableArray<const Field*>& new_fields) const {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadWriter());
#endif
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

bool Class::InjectCIDFields() const {
  if (library() != Library::InternalLibrary() ||
      Name() != Symbols::ClassID().raw()) {
    return false;
  }

  auto thread = Thread::Current();
  auto isolate_group = thread->isolate_group();
  auto zone = thread->zone();
  Field& field = Field::Handle(zone);
  Smi& value = Smi::Handle(zone);
  String& field_name = String::Handle(zone);

  static const struct {
    const char* const field_name;
    const intptr_t cid;
  } cid_fields[] = {
#define CLASS_LIST_WITH_NULL(V)                                                \
  V(Null)                                                                      \
  CLASS_LIST_NO_OBJECT(V)
#define ADD_SET_FIELD(clazz) {"cid" #clazz, k##clazz##Cid},
      CLASS_LIST_WITH_NULL(ADD_SET_FIELD)
#undef ADD_SET_FIELD
#define ADD_SET_FIELD(clazz) {"cid" #clazz "View", kTypedData##clazz##ViewCid},
          CLASS_LIST_TYPED_DATA(ADD_SET_FIELD)
#undef ADD_SET_FIELD
#define ADD_SET_FIELD(clazz) {"cid" #clazz, kTypedData##clazz##Cid},
              CLASS_LIST_TYPED_DATA(ADD_SET_FIELD)
#undef ADD_SET_FIELD
#define ADD_SET_FIELD(clazz)                                                   \
  {"cidExternal" #clazz, kExternalTypedData##clazz##Cid},
                  CLASS_LIST_TYPED_DATA(ADD_SET_FIELD)
#undef ADD_SET_FIELD
#undef CLASS_LIST_WITH_NULL
  };

  const AbstractType& field_type = Type::Handle(zone, Type::IntType());
  for (size_t i = 0; i < ARRAY_SIZE(cid_fields); i++) {
    field_name = Symbols::New(thread, cid_fields[i].field_name);
    field = Field::New(field_name, /* is_static = */ true,
                       /* is_final = */ false,
                       /* is_const = */ true,
                       /* is_reflectable = */ false,
                       /* is_late = */ false, *this, field_type,
                       TokenPosition::kMinSource, TokenPosition::kMinSource);
    value = Smi::New(cid_fields[i].cid);
    isolate_group->RegisterStaticField(field, value);
    AddField(field);
  }

  return true;
}

template <class FakeInstance, class TargetFakeInstance>
ClassPtr Class::NewCommon(intptr_t index) {
  ASSERT(Object::class_class() != Class::null());
  Class& result = Class::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(Class::kClassId, Class::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  // Here kIllegalCid means not-yet-assigned.
  Object::VerifyBuiltinVtable<FakeInstance>(index == kIllegalCid ? kInstanceCid
                                                                 : index);
  result.set_token_pos(TokenPosition::kNoSource);
  result.set_end_token_pos(TokenPosition::kNoSource);
  const intptr_t host_instance_size = FakeInstance::InstanceSize();
  const intptr_t target_instance_size = compiler::target::RoundedAllocationSize(
      TargetFakeInstance::InstanceSize());
  result.set_instance_size(host_instance_size, target_instance_size);
  result.set_type_arguments_field_offset_in_words(kNoTypeArguments,
                                                  RTN::Class::kNoTypeArguments);
  const intptr_t host_next_field_offset = FakeInstance::NextFieldOffset();
  const intptr_t target_next_field_offset =
      TargetFakeInstance::NextFieldOffset();
  result.set_next_field_offset(host_next_field_offset,
                               target_next_field_offset);
  result.set_id(index);
  result.set_num_type_arguments(kUnknownNumTypeArguments);
  result.set_num_native_fields(0);
  result.set_state_bits(0);
  NOT_IN_PRECOMPILED(result.set_kernel_offset(0));
  result.InitEmptyFields();
  return result.raw();
}

template <class FakeInstance, class TargetFakeInstance>
ClassPtr Class::New(intptr_t index,
                    Isolate* isolate,
                    bool register_class,
                    bool is_abstract) {
  Class& result =
      Class::Handle(NewCommon<FakeInstance, TargetFakeInstance>(index));
  if (is_abstract) {
    result.set_is_abstract();
  }
  if (register_class) {
    isolate->class_table()->Register(result);
  }
  return result.raw();
}

ClassPtr Class::New(const Library& lib,
                    const String& name,
                    const Script& script,
                    TokenPosition token_pos,
                    bool register_class) {
  Class& result =
      Class::Handle(NewCommon<Instance, RTN::Instance>(kIllegalCid));
  result.set_library(lib);
  result.set_name(name);
  result.set_script(script);
  result.set_token_pos(token_pos);

  // The size gets initialized to 0. Once the class gets finalized the class
  // finalizer will set the correct size.
  ASSERT(!result.is_finalized() && !result.is_prefinalized());
  result.set_instance_size_in_words(0, 0);

  if (register_class) {
    Isolate::Current()->RegisterClass(result);
  }
  return result.raw();
}

ClassPtr Class::NewInstanceClass() {
  return Class::New<Instance, RTN::Instance>(kIllegalCid, Isolate::Current());
}

ClassPtr Class::NewNativeWrapper(const Library& library,
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
    const intptr_t host_instance_size = sizeof(InstanceLayout) + kWordSize;
#if defined(DART_PRECOMPILER)
    const intptr_t target_instance_size =
        compiler::target::Instance::InstanceSize() +
        compiler::target::kWordSize;
#else
    const intptr_t target_instance_size =
        sizeof(InstanceLayout) + compiler::target::kWordSize;
#endif
    cls.set_instance_size(
        RoundedAllocationSize(host_instance_size),
        compiler::target::RoundedAllocationSize(target_instance_size));
    cls.set_next_field_offset(host_instance_size, target_instance_size);
    cls.set_num_native_fields(field_count);
    cls.set_is_allocate_finalized();
    cls.set_is_declaration_loaded();
    cls.set_is_type_finalized();
    cls.set_is_synthesized_class();
    library.AddClass(cls);
    return cls.raw();
  } else {
    return Class::null();
  }
}

ClassPtr Class::NewStringClass(intptr_t class_id, Isolate* isolate) {
  intptr_t host_instance_size, target_instance_size;
  if (class_id == kOneByteStringCid) {
    host_instance_size = OneByteString::InstanceSize();
    target_instance_size = compiler::target::RoundedAllocationSize(
        RTN::OneByteString::InstanceSize());
  } else if (class_id == kTwoByteStringCid) {
    host_instance_size = TwoByteString::InstanceSize();
    target_instance_size = compiler::target::RoundedAllocationSize(
        RTN::TwoByteString::InstanceSize());
  } else if (class_id == kExternalOneByteStringCid) {
    host_instance_size = ExternalOneByteString::InstanceSize();
    target_instance_size = compiler::target::RoundedAllocationSize(
        RTN::ExternalOneByteString::InstanceSize());
  } else {
    ASSERT(class_id == kExternalTwoByteStringCid);
    host_instance_size = ExternalTwoByteString::InstanceSize();
    target_instance_size = compiler::target::RoundedAllocationSize(
        RTN::ExternalTwoByteString::InstanceSize());
  }
  Class& result = Class::Handle(
      New<String, RTN::String>(class_id, isolate, /*register_class=*/false));
  result.set_instance_size(host_instance_size, target_instance_size);

  const intptr_t host_next_field_offset = String::NextFieldOffset();
  const intptr_t target_next_field_offset = RTN::String::NextFieldOffset();
  result.set_next_field_offset(host_next_field_offset,
                               target_next_field_offset);
  result.set_is_prefinalized();
  isolate->class_table()->Register(result);
  return result.raw();
}

ClassPtr Class::NewTypedDataClass(intptr_t class_id, Isolate* isolate) {
  ASSERT(IsTypedDataClassId(class_id));
  const intptr_t host_instance_size = TypedData::InstanceSize();
  const intptr_t target_instance_size =
      compiler::target::RoundedAllocationSize(RTN::TypedData::InstanceSize());
  Class& result = Class::Handle(New<TypedData, RTN::TypedData>(
      class_id, isolate, /*register_class=*/false));
  result.set_instance_size(host_instance_size, target_instance_size);

  const intptr_t host_next_field_offset = TypedData::NextFieldOffset();
  const intptr_t target_next_field_offset = RTN::TypedData::NextFieldOffset();
  result.set_next_field_offset(host_next_field_offset,
                               target_next_field_offset);
  result.set_is_prefinalized();
  isolate->class_table()->Register(result);
  return result.raw();
}

ClassPtr Class::NewTypedDataViewClass(intptr_t class_id, Isolate* isolate) {
  ASSERT(IsTypedDataViewClassId(class_id));
  const intptr_t host_instance_size = TypedDataView::InstanceSize();
  const intptr_t target_instance_size = compiler::target::RoundedAllocationSize(
      RTN::TypedDataView::InstanceSize());
  Class& result = Class::Handle(New<TypedDataView, RTN::TypedDataView>(
      class_id, isolate, /*register_class=*/false));
  result.set_instance_size(host_instance_size, target_instance_size);

  const intptr_t host_next_field_offset = TypedDataView::NextFieldOffset();
  const intptr_t target_next_field_offset =
      RTN::TypedDataView::NextFieldOffset();
  result.set_next_field_offset(host_next_field_offset,
                               target_next_field_offset);
  result.set_is_prefinalized();
  isolate->class_table()->Register(result);
  return result.raw();
}

ClassPtr Class::NewExternalTypedDataClass(intptr_t class_id, Isolate* isolate) {
  ASSERT(IsExternalTypedDataClassId(class_id));
  const intptr_t host_instance_size = ExternalTypedData::InstanceSize();
  const intptr_t target_instance_size = compiler::target::RoundedAllocationSize(
      RTN::ExternalTypedData::InstanceSize());
  Class& result = Class::Handle(New<ExternalTypedData, RTN::ExternalTypedData>(
      class_id, isolate, /*register_class=*/false));

  const intptr_t host_next_field_offset = ExternalTypedData::NextFieldOffset();
  const intptr_t target_next_field_offset =
      RTN::ExternalTypedData::NextFieldOffset();
  result.set_instance_size(host_instance_size, target_instance_size);
  result.set_next_field_offset(host_next_field_offset,
                               target_next_field_offset);
  result.set_is_prefinalized();
  isolate->class_table()->Register(result);
  return result.raw();
}

ClassPtr Class::NewPointerClass(intptr_t class_id, Isolate* isolate) {
  ASSERT(IsFfiPointerClassId(class_id));
  intptr_t host_instance_size = Pointer::InstanceSize();
  intptr_t target_instance_size =
      compiler::target::RoundedAllocationSize(RTN::Pointer::InstanceSize());
  Class& result = Class::Handle(
      New<Pointer, RTN::Pointer>(class_id, isolate, /*register_class=*/false));
  result.set_instance_size(host_instance_size, target_instance_size);
  result.set_type_arguments_field_offset(Pointer::type_arguments_offset(),
                                         RTN::Pointer::type_arguments_offset());

  const intptr_t host_next_field_offset = Pointer::NextFieldOffset();
  const intptr_t target_next_field_offset = RTN::Pointer::NextFieldOffset();

  result.set_next_field_offset(host_next_field_offset,
                               target_next_field_offset);
  result.set_is_prefinalized();
  isolate->class_table()->Register(result);
  return result.raw();
}

void Class::set_name(const String& value) const {
  ASSERT(raw_ptr()->name() == String::null());
  ASSERT(value.IsSymbol());
  raw_ptr()->set_name(value.raw());
#if !defined(PRODUCT)
  if (raw_ptr()->user_name() == String::null()) {
    // TODO(johnmccutchan): Eagerly set user name for VM isolate classes,
    // lazily set user name for the other classes.
    // Generate and set user_name.
    const String& user_name = String::Handle(
        Symbols::New(Thread::Current(), GenerateUserVisibleName()));
    set_user_name(user_name);
  }
#endif  // !defined(PRODUCT)
}

#if !defined(PRODUCT)
void Class::set_user_name(const String& value) const {
  raw_ptr()->set_user_name(value.raw());
}
#endif  // !defined(PRODUCT)

const char* Class::GenerateUserVisibleName() const {
  if (FLAG_show_internal_names) {
    return String::Handle(Name()).ToCString();
  }
  switch (id()) {
    case kFloat32x4Cid:
      return Symbols::Float32x4().ToCString();
    case kInt32x4Cid:
      return Symbols::Int32x4().ToCString();
    case kTypedDataInt8ArrayCid:
    case kExternalTypedDataInt8ArrayCid:
      return Symbols::Int8List().ToCString();
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
      return Symbols::Uint8List().ToCString();
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return Symbols::Uint8ClampedList().ToCString();
    case kTypedDataInt16ArrayCid:
    case kExternalTypedDataInt16ArrayCid:
      return Symbols::Int16List().ToCString();
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint16ArrayCid:
      return Symbols::Uint16List().ToCString();
    case kTypedDataInt32ArrayCid:
    case kExternalTypedDataInt32ArrayCid:
      return Symbols::Int32List().ToCString();
    case kTypedDataUint32ArrayCid:
    case kExternalTypedDataUint32ArrayCid:
      return Symbols::Uint32List().ToCString();
    case kTypedDataInt64ArrayCid:
    case kExternalTypedDataInt64ArrayCid:
      return Symbols::Int64List().ToCString();
    case kTypedDataUint64ArrayCid:
    case kExternalTypedDataUint64ArrayCid:
      return Symbols::Uint64List().ToCString();
    case kTypedDataInt32x4ArrayCid:
    case kExternalTypedDataInt32x4ArrayCid:
      return Symbols::Int32x4List().ToCString();
    case kTypedDataFloat32x4ArrayCid:
    case kExternalTypedDataFloat32x4ArrayCid:
      return Symbols::Float32x4List().ToCString();
    case kTypedDataFloat64x2ArrayCid:
    case kExternalTypedDataFloat64x2ArrayCid:
      return Symbols::Float64x2List().ToCString();
    case kTypedDataFloat32ArrayCid:
    case kExternalTypedDataFloat32ArrayCid:
      return Symbols::Float32List().ToCString();
    case kTypedDataFloat64ArrayCid:
    case kExternalTypedDataFloat64ArrayCid:
      return Symbols::Float64List().ToCString();

    case kFfiPointerCid:
      return Symbols::FfiPointer().ToCString();
    case kFfiDynamicLibraryCid:
      return Symbols::FfiDynamicLibrary().ToCString();

#if !defined(PRODUCT)
    case kNullCid:
      return Symbols::Null().ToCString();
    case kDynamicCid:
      return Symbols::Dynamic().ToCString();
    case kVoidCid:
      return Symbols::Void().ToCString();
    case kNeverCid:
      return Symbols::Never().ToCString();
    case kClassCid:
      return Symbols::Class().ToCString();
    case kTypeArgumentsCid:
      return Symbols::TypeArguments().ToCString();
    case kPatchClassCid:
      return Symbols::PatchClass().ToCString();
    case kFunctionCid:
      return Symbols::Function().ToCString();
    case kClosureDataCid:
      return Symbols::ClosureData().ToCString();
    case kSignatureDataCid:
      return Symbols::SignatureData().ToCString();
    case kFfiTrampolineDataCid:
      return Symbols::FfiTrampolineData().ToCString();
    case kFieldCid:
      return Symbols::Field().ToCString();
    case kScriptCid:
      return Symbols::Script().ToCString();
    case kLibraryCid:
      return Symbols::Library().ToCString();
    case kLibraryPrefixCid:
      return Symbols::LibraryPrefix().ToCString();
    case kNamespaceCid:
      return Symbols::Namespace().ToCString();
    case kKernelProgramInfoCid:
      return Symbols::KernelProgramInfo().ToCString();
    case kCodeCid:
      return Symbols::Code().ToCString();
    case kInstructionsCid:
      return Symbols::Instructions().ToCString();
    case kInstructionsSectionCid:
      return Symbols::InstructionsSection().ToCString();
    case kObjectPoolCid:
      return Symbols::ObjectPool().ToCString();
    case kCodeSourceMapCid:
      return Symbols::CodeSourceMap().ToCString();
    case kPcDescriptorsCid:
      return Symbols::PcDescriptors().ToCString();
    case kCompressedStackMapsCid:
      return Symbols::CompressedStackMaps().ToCString();
    case kLocalVarDescriptorsCid:
      return Symbols::LocalVarDescriptors().ToCString();
    case kExceptionHandlersCid:
      return Symbols::ExceptionHandlers().ToCString();
    case kContextCid:
      return Symbols::Context().ToCString();
    case kContextScopeCid:
      return Symbols::ContextScope().ToCString();
    case kSingleTargetCacheCid:
      return Symbols::SingleTargetCache().ToCString();
    case kICDataCid:
      return Symbols::ICData().ToCString();
    case kMegamorphicCacheCid:
      return Symbols::MegamorphicCache().ToCString();
    case kSubtypeTestCacheCid:
      return Symbols::SubtypeTestCache().ToCString();
    case kLoadingUnitCid:
      return Symbols::LoadingUnit().ToCString();
    case kApiErrorCid:
      return Symbols::ApiError().ToCString();
    case kLanguageErrorCid:
      return Symbols::LanguageError().ToCString();
    case kUnhandledExceptionCid:
      return Symbols::UnhandledException().ToCString();
    case kUnwindErrorCid:
      return Symbols::UnwindError().ToCString();
    case kIntegerCid:
    case kSmiCid:
    case kMintCid:
      return Symbols::Int().ToCString();
    case kDoubleCid:
      return Symbols::Double().ToCString();
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return Symbols::_String().ToCString();
    case kArrayCid:
    case kImmutableArrayCid:
    case kGrowableObjectArrayCid:
      return Symbols::List().ToCString();
#endif  // !defined(PRODUCT)
  }
  String& name = String::Handle(Name());
  name = Symbols::New(Thread::Current(), String::ScrubName(name));
  if (name.raw() == Symbols::FutureImpl().raw() &&
      library() == Library::AsyncLibrary()) {
    return Symbols::Future().ToCString();
  }
  return name.ToCString();
}

void Class::set_script(const Script& value) const {
  raw_ptr()->set_script(value.raw());
}

void Class::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

void Class::set_end_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->end_token_pos_, token_pos);
}

int32_t Class::SourceFingerprint() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  return kernel::KernelSourceFingerprintHelper::CalculateClassFingerprint(
      *this);
#else
  return 0;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

void Class::set_is_implemented() const {
  set_state_bits(ImplementedBit::update(true, state_bits()));
}

void Class::set_is_abstract() const {
  set_state_bits(AbstractBit::update(true, state_bits()));
}

void Class::set_is_declaration_loaded() const {
  ASSERT(!is_declaration_loaded());
  set_state_bits(
      ClassLoadingBits::update(ClassLayout::kDeclarationLoaded, state_bits()));
}

void Class::set_is_type_finalized() const {
  ASSERT(is_declaration_loaded());
  ASSERT(!is_type_finalized());
  set_state_bits(
      ClassLoadingBits::update(ClassLayout::kTypeFinalized, state_bits()));
}

void Class::set_is_synthesized_class() const {
  set_state_bits(SynthesizedClassBit::update(true, state_bits()));
}

void Class::set_is_enum_class() const {
  set_state_bits(EnumBit::update(true, state_bits()));
}

void Class::set_is_const() const {
  set_state_bits(ConstBit::update(true, state_bits()));
}

void Class::set_is_transformed_mixin_application() const {
  set_state_bits(TransformedMixinApplicationBit::update(true, state_bits()));
}

void Class::set_is_fields_marked_nullable() const {
  set_state_bits(FieldsMarkedNullableBit::update(true, state_bits()));
}

void Class::set_is_allocated(bool value) const {
  set_state_bits(IsAllocatedBit::update(value, state_bits()));
}

void Class::set_is_loaded(bool value) const {
  set_state_bits(IsLoadedBit::update(value, state_bits()));
}

void Class::set_is_finalized() const {
  ASSERT(!is_finalized());
  set_state_bits(
      ClassFinalizedBits::update(ClassLayout::kFinalized, state_bits()));
}

void Class::set_is_allocate_finalized() const {
  ASSERT(!is_allocate_finalized());
  set_state_bits(ClassFinalizedBits::update(ClassLayout::kAllocateFinalized,
                                            state_bits()));
}

void Class::set_is_prefinalized() const {
  ASSERT(!is_finalized());
  set_state_bits(
      ClassFinalizedBits::update(ClassLayout::kPreFinalized, state_bits()));
}

void Class::set_interfaces(const Array& value) const {
  ASSERT(!value.IsNull());
  raw_ptr()->set_interfaces(value.raw());
}

void Class::AddDirectImplementor(const Class& implementor,
                                 bool is_mixin) const {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(is_implemented());
  ASSERT(!implementor.IsNull());
  GrowableObjectArray& direct_implementors =
      GrowableObjectArray::Handle(raw_ptr()->direct_implementors());
  if (direct_implementors.IsNull()) {
    direct_implementors = GrowableObjectArray::New(4, Heap::kOld);
    raw_ptr()->set_direct_implementors(direct_implementors.raw());
  }
#if defined(DEBUG)
  // Verify that the same class is not added twice.
  // The only exception is mixins: when mixin application is transformed,
  // mixin is added to the end of interfaces list and may be duplicated:
  //   class X = A with B implements B;
  // This is rare and harmless.
  if (!is_mixin) {
    for (intptr_t i = 0; i < direct_implementors.Length(); i++) {
      ASSERT(direct_implementors.At(i) != implementor.raw());
    }
  }
#endif
  direct_implementors.Add(implementor, Heap::kOld);
}

void Class::ClearDirectImplementors() const {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  raw_ptr()->set_direct_implementors(GrowableObjectArray::null());
}

void Class::AddDirectSubclass(const Class& subclass) const {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(!subclass.IsNull());
  ASSERT(subclass.SuperClass() == raw());
  // Do not keep track of the direct subclasses of class Object.
  ASSERT(!IsObjectClass());
  GrowableObjectArray& direct_subclasses =
      GrowableObjectArray::Handle(raw_ptr()->direct_subclasses());
  if (direct_subclasses.IsNull()) {
    direct_subclasses = GrowableObjectArray::New(4, Heap::kOld);
    raw_ptr()->set_direct_subclasses(direct_subclasses.raw());
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
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  raw_ptr()->set_direct_subclasses(GrowableObjectArray::null());
}

ArrayPtr Class::constants() const {
  return raw_ptr()->constants();
}

void Class::set_constants(const Array& value) const {
  raw_ptr()->set_constants(value.raw());
}

void Class::set_declaration_type(const Type& value) const {
  ASSERT(id() != kDynamicCid && id() != kVoidCid);
  ASSERT(!value.IsNull() && value.IsCanonical() && value.IsOld());
  ASSERT((declaration_type() == Object::null()) ||
         (declaration_type() == value.raw()));  // Set during own finalization.
  // Since DeclarationType is used as the runtime type of instances of a
  // non-generic class, its nullability must be kNonNullable.
  // The exception is DeclarationType of Null which is kNullable.
  ASSERT(value.type_class_id() != kNullCid || value.IsNullable());
  ASSERT(value.type_class_id() == kNullCid || value.IsNonNullable());
  raw_ptr()->set_declaration_type(value.raw());
}

TypePtr Class::DeclarationType() const {
  ASSERT(is_declaration_loaded());
  if (IsNullClass()) {
    return Type::NullType();
  }
  if (IsDynamicClass()) {
    return Type::DynamicType();
  }
  if (IsVoidClass()) {
    return Type::VoidType();
  }
  if (declaration_type() != Type::null()) {
    return declaration_type();
  }
  // For efficiency, the runtimeType intrinsic returns the type cached by
  // DeclarationType without checking its nullability. Therefore, we
  // consistently cache the kNonNullable version of the type.
  // The exception is type Null which is stored as kNullable.
  Type& type =
      Type::Handle(Type::New(*this, TypeArguments::Handle(type_parameters()),
                             token_pos(), Nullability::kNonNullable));
  type ^= ClassFinalizer::FinalizeType(type);
  set_declaration_type(type);
  return type.raw();
}

void Class::set_allocation_stub(const Code& value) const {
  // Never clear the stub as it may still be a target, but will be GC-d if
  // not referenced.
  ASSERT(!value.IsNull());
  ASSERT(raw_ptr()->allocation_stub() == Code::null());
  raw_ptr()->set_allocation_stub(value.raw());
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
  raw_ptr()->set_allocation_stub(Code::null());
}

bool Class::IsDartFunctionClass() const {
  return raw() == Type::Handle(Type::DartFunctionType()).type_class();
}

bool Class::IsFutureClass() const {
  // Looking up future_class in the object store would not work, because
  // this function is called during class finalization, before the object store
  // field would be initialized by InitKnownObjects().
  return (Name() == Symbols::Future().raw()) &&
         (library() == Library::AsyncLibrary());
}

// Checks if type T0 is a subtype of type T1.
// Type T0 is specified by class 'cls' parameterized with 'type_arguments' and
// by 'nullability', and type T1 is specified by 'other' and must have a type
// class.
bool Class::IsSubtypeOf(const Class& cls,
                        const TypeArguments& type_arguments,
                        Nullability nullability,
                        const AbstractType& other,
                        Heap::Space space,
                        TrailPtr trail) {
  // This function does not support Null, Never, dynamic, or void as type T0.
  classid_t this_cid = cls.id();
  ASSERT(this_cid != kNullCid && this_cid != kNeverCid &&
         this_cid != kDynamicCid && this_cid != kVoidCid);
  // Type T1 must have a type class (e.g. not a type parameter).
  ASSERT(other.HasTypeClass());
  const classid_t other_cid = other.type_class_id();
  if (other_cid == kDynamicCid || other_cid == kVoidCid) {
    return true;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  // Nullability of left and right hand sides is verified in strong mode only.
  const bool verified_nullability = !isolate->use_strict_null_safety_checks() ||
                                    nullability != Nullability::kNullable ||
                                    !other.IsNonNullable();

  // Right Object.
  if (other_cid == kObjectCid) {
    return verified_nullability;
  }
  const Class& other_class = Class::Handle(zone, other.type_class());
  const TypeArguments& other_type_arguments =
      TypeArguments::Handle(zone, other.arguments());
  // Use the 'this_class' object as if it was the receiver of this method, but
  // instead of recursing, reset it to the super class and loop.
  Class& this_class = Class::Handle(zone, cls.raw());
  while (true) {
    // Apply additional subtyping rules if T0 or T1 are 'FutureOr'.

    // Left FutureOr:
    //   if T0 is FutureOr<S0> then:
    //     T0 <: T1 iff Future<S0> <: T1 and S0 <: T1
    if (this_cid == kFutureOrCid) {
      // Check Future<S0> <: T1.
      ObjectStore* object_store = Isolate::Current()->object_store();
      const Class& future_class =
          Class::Handle(zone, object_store->future_class());
      ASSERT(!future_class.IsNull() && future_class.NumTypeParameters() == 1 &&
             this_class.NumTypeParameters() == 1);
      ASSERT(type_arguments.IsNull() || type_arguments.Length() >= 1);
      if (Class::IsSubtypeOf(future_class, type_arguments,
                             Nullability::kNonNullable, other, space, trail)) {
        // Check S0 <: T1.
        const AbstractType& type_arg =
            AbstractType::Handle(zone, type_arguments.TypeAtNullSafe(0));
        if (type_arg.IsSubtypeOf(other, space, trail)) {
          return verified_nullability;
        }
      }
    }

    // Right FutureOr:
    //   if T1 is FutureOr<S1> then:
    //     T0 <: T1 iff any of the following hold:
    //     either T0 <: Future<S1>
    //     or T0 <: S1
    //     or T0 is X0 and X0 has bound S0 and S0 <: T1  (checked elsewhere)
    if (other_cid == kFutureOrCid) {
      const AbstractType& other_type_arg =
          AbstractType::Handle(zone, other_type_arguments.TypeAtNullSafe(0));
      // Check if S1 is a top type.
      if (other_type_arg.IsTopTypeForSubtyping()) {
        return true;
      }
      // Check T0 <: Future<S1> when T0 is Future<S0>.
      if (this_class.IsFutureClass()) {
        const AbstractType& type_arg =
            AbstractType::Handle(zone, type_arguments.TypeAtNullSafe(0));
        // If T0 is Future<S0>, then T0 <: Future<S1>, iff S0 <: S1.
        if (type_arg.IsSubtypeOf(other_type_arg, space, trail)) {
          if (verified_nullability) {
            return true;
          }
        }
      }
      // Check T0 <: Future<S1> when T0 is FutureOr<S0> is already done.
      // Check T0 <: S1.
      if (other_type_arg.HasTypeClass() &&
          Class::IsSubtypeOf(this_class, type_arguments, nullability,
                             other_type_arg, space, trail)) {
        return true;
      }
    }

    // Left nullable:
    //   if T0 is S0? then:
    //     T0 <: T1 iff S0 <: T1 and Null <: T1
    if (!verified_nullability) {
      return false;
    }

    // Check for reflexivity.
    if (this_class.raw() == other_class.raw()) {
      const intptr_t num_type_params = this_class.NumTypeParameters();
      if (num_type_params == 0) {
        return true;
      }
      const intptr_t num_type_args = this_class.NumTypeArguments();
      const intptr_t from_index = num_type_args - num_type_params;
      // Since we do not truncate the type argument vector of a subclass (see
      // below), we only check a subvector of the proper length.
      // Check for covariance.
      if (other_type_arguments.IsNull()) {
        return true;
      }
      AbstractType& type = AbstractType::Handle(zone);
      AbstractType& other_type = AbstractType::Handle(zone);
      for (intptr_t i = 0; i < num_type_params; ++i) {
        type = type_arguments.TypeAtNullSafe(from_index + i);
        other_type = other_type_arguments.TypeAt(from_index + i);
        ASSERT(!type.IsNull() && !other_type.IsNull());
        if (!type.IsSubtypeOf(other_type, space, trail)) {
          return false;
        }
      }
      return true;
    }
    // Check for 'direct super type' specified in the implements clause
    // and check for transitivity at the same time.
    Array& interfaces = Array::Handle(zone, this_class.interfaces());
    AbstractType& interface = AbstractType::Handle(zone);
    Class& interface_class = Class::Handle(zone);
    TypeArguments& interface_args = TypeArguments::Handle(zone);
    for (intptr_t i = 0; i < interfaces.Length(); i++) {
      interface ^= interfaces.At(i);
      ASSERT(interface.IsFinalized());
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
        interface_args = interface_args.InstantiateFrom(
            type_arguments, Object::null_type_arguments(), kNoneFree, space);
      }
      // In Dart 2, implementing Function has no meaning.
      // TODO(regis): Can we encounter and skip Object as well?
      if (interface_class.IsDartFunctionClass()) {
        continue;
      }
      // No need to pass the trail as cycles are not possible via interfaces.
      if (Class::IsSubtypeOf(interface_class, interface_args,
                             Nullability::kNonNullable, other, space)) {
        return true;
      }
    }
    // "Recurse" up the class hierarchy until we have reached the top.
    this_class = this_class.SuperClass();
    if (this_class.IsNull()) {
      return false;
    }
    this_cid = this_class.id();
  }
  UNREACHABLE();
  return false;
}

bool Class::IsTopLevel() const {
  return Name() == Symbols::TopLevel().raw();
}

bool Class::IsPrivate() const {
  return Library::IsPrivate(String::Handle(Name()));
}

FunctionPtr Class::LookupDynamicFunctionUnsafe(const String& name) const {
  return LookupFunctionReadLocked(name, kInstance);
}

FunctionPtr Class::LookupDynamicFunctionAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kInstance);
}

FunctionPtr Class::LookupStaticFunction(const String& name) const {
  Thread* thread = Thread::Current();
  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  return LookupFunctionReadLocked(name, kStatic);
}

FunctionPtr Class::LookupStaticFunctionAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kStatic);
}

FunctionPtr Class::LookupConstructor(const String& name) const {
  Thread* thread = Thread::Current();
  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  return LookupFunctionReadLocked(name, kConstructor);
}

FunctionPtr Class::LookupConstructorAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kConstructor);
}

FunctionPtr Class::LookupFactory(const String& name) const {
  Thread* thread = Thread::Current();
  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  return LookupFunctionReadLocked(name, kFactory);
}

FunctionPtr Class::LookupFactoryAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kFactory);
}

FunctionPtr Class::LookupFunctionAllowPrivate(const String& name) const {
  return LookupFunctionAllowPrivate(name, kAny);
}

FunctionPtr Class::LookupFunctionReadLocked(const String& name) const {
  return LookupFunctionReadLocked(name, kAny);
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

FunctionPtr Class::CheckFunctionType(const Function& func, MemberKind kind) {
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

FunctionPtr Class::LookupFunctionReadLocked(const String& name,
                                            MemberKind kind) const {
  ASSERT(!IsNull());
  Thread* thread = Thread::Current();
  RELEASE_ASSERT(is_finalized());
  // Caller needs to ensure they grab program_lock because this method
  // can be invoked with either ReadRwLock or WriteRwLock.
#if defined(DEBUG)
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadReader());
#endif
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  funcs = functions();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  Function& function = thread->FunctionHandle();
  if (len >= kFunctionLookupHashTreshold) {
    // TODO(dartbug.com/36097): We require currently a read lock in the resolver
    // to avoid read-write race access to this hash table.
    // If we want to increase resolver speed by avoiding the need for read lock,
    // we could make change this hash table to be lock-free for the reader.
    const Array& hash_table =
        Array::Handle(thread->zone(), raw_ptr()->functions_hash_table());
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
      function_name = function.name();
      if (function_name.Equals(name)) {
        return CheckFunctionType(function, kind);
      }
    }
  }
  // No function found.
  return Function::null();
}

FunctionPtr Class::LookupFunctionAllowPrivate(const String& name,
                                              MemberKind kind) const {
  ASSERT(!IsNull());
  Thread* thread = Thread::Current();
  RELEASE_ASSERT(is_finalized());
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  funcs = current_functions();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  Function& function = thread->FunctionHandle();
  String& function_name = thread->StringHandle();
  for (intptr_t i = 0; i < len; i++) {
    function ^= funcs.At(i);
    function_name = function.name();
    if (String::EqualsIgnoringPrivateKey(function_name, name)) {
      return CheckFunctionType(function, kind);
    }
  }
  // No function found.
  return Function::null();
}

FunctionPtr Class::LookupGetterFunction(const String& name) const {
  return LookupAccessorFunction(kGetterPrefix, kGetterPrefixLength, name);
}

FunctionPtr Class::LookupSetterFunction(const String& name) const {
  return LookupAccessorFunction(kSetterPrefix, kSetterPrefixLength, name);
}

FunctionPtr Class::LookupAccessorFunction(const char* prefix,
                                          intptr_t prefix_length,
                                          const String& name) const {
  ASSERT(!IsNull());
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Function::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& funcs = thread->ArrayHandle();
  funcs = current_functions();
  intptr_t len = funcs.Length();
  Function& function = thread->FunctionHandle();
  String& function_name = thread->StringHandle();
  for (intptr_t i = 0; i < len; i++) {
    function ^= funcs.At(i);
    function_name = function.name();
    if (MatchesAccessorName(function_name, prefix, prefix_length, name)) {
      return function.raw();
    }
  }

  // No function found.
  return Function::null();
}

FieldPtr Class::LookupInstanceField(const String& name) const {
  return LookupField(name, kInstance);
}

FieldPtr Class::LookupStaticField(const String& name) const {
  return LookupField(name, kStatic);
}

FieldPtr Class::LookupField(const String& name) const {
  return LookupField(name, kAny);
}

FieldPtr Class::LookupField(const String& name, MemberKind kind) const {
  ASSERT(!IsNull());
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Field::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FIELD_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& flds = thread->ArrayHandle();
  flds = fields();
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
      field_name = field.name();
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

FieldPtr Class::LookupFieldAllowPrivate(const String& name,
                                        bool instance_only) const {
  ASSERT(!IsNull());
  // Use slow string compare, ignoring privacy name mangling.
  Thread* thread = Thread::Current();
  if (EnsureIsFinalized(thread) != Error::null()) {
    return Field::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_FIELD_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& flds = thread->ArrayHandle();
  flds = fields();
  ASSERT(!flds.IsNull());
  intptr_t len = flds.Length();
  Field& field = thread->FieldHandle();
  String& field_name = thread->StringHandle();
  for (intptr_t i = 0; i < len; i++) {
    field ^= flds.At(i);
    field_name = field.name();
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

FieldPtr Class::LookupInstanceFieldAllowPrivate(const String& name) const {
  Field& field = Field::Handle(LookupFieldAllowPrivate(name, true));
  if (!field.IsNull() && !field.is_static()) {
    return field.raw();
  }
  return Field::null();
}

FieldPtr Class::LookupStaticFieldAllowPrivate(const String& name) const {
  Field& field = Field::Handle(LookupFieldAllowPrivate(name));
  if (!field.IsNull() && field.is_static()) {
    return field.raw();
  }
  return Field::null();
}

const char* Class::ToCString() const {
  NoSafepointScope no_safepoint;
  const Library& lib = Library::Handle(library());
  const char* library_name = lib.IsNull() ? "" : lib.ToCString();
  const char* class_name = String::Handle(Name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(), "%s Class: %s", library_name,
                     class_name);
}

// Thomas Wang, Integer Hash Functions.
// https://gist.github.com/badboy/6267743
// "64 bit to 32 bit Hash Functions"
static uword Hash64To32(uint64_t v) {
  v = ~v + (v << 18);
  v = v ^ (v >> 31);
  v = v * 21;
  v = v ^ (v >> 11);
  v = v + (v << 6);
  v = v ^ (v >> 22);
  return static_cast<uint32_t>(v);
}

class CanonicalDoubleKey {
 public:
  explicit CanonicalDoubleKey(const Double& key)
      : key_(&key), value_(key.value()) {}
  explicit CanonicalDoubleKey(const double value) : key_(NULL), value_(value) {}
  bool Matches(const Double& obj) const {
    return obj.BitwiseEqualsToDouble(value_);
  }
  uword Hash() const { return Hash(value_); }
  static uword Hash(double value) {
    return Hash64To32(bit_cast<uint64_t>(value));
  }

  const Double* key_;
  const double value_;

 private:
  DISALLOW_ALLOCATION();
};

class CanonicalMintKey {
 public:
  explicit CanonicalMintKey(const Mint& key)
      : key_(&key), value_(key.value()) {}
  explicit CanonicalMintKey(const int64_t value) : key_(NULL), value_(value) {}
  bool Matches(const Mint& obj) const { return obj.value() == value_; }
  uword Hash() const { return Hash(value_); }
  static uword Hash(int64_t value) {
    return Hash64To32(bit_cast<uint64_t>(value));
  }

  const Mint* key_;
  const int64_t value_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical numbers based on a hash of the value.
template <typename ObjectType, typename KeyType>
class CanonicalNumberTraits {
 public:
  static const char* Name() { return "CanonicalNumberTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    return a.raw() == b.raw();
  }
  static bool IsMatch(const KeyType& a, const Object& b) {
    return a.Matches(ObjectType::Cast(b));
  }
  static uword Hash(const Object& key) {
    return KeyType::Hash(ObjectType::Cast(key).value());
  }
  static uword Hash(const KeyType& key) { return key.Hash(); }
  static ObjectPtr NewKey(const KeyType& obj) {
    if (obj.key_ != NULL) {
      return obj.key_->raw();
    } else {
      UNIMPLEMENTED();
      return NULL;
    }
  }
};
typedef UnorderedHashSet<CanonicalNumberTraits<Double, CanonicalDoubleKey> >
    CanonicalDoubleSet;
typedef UnorderedHashSet<CanonicalNumberTraits<Mint, CanonicalMintKey> >
    CanonicalMintSet;

// Returns an instance of Double or Double::null().
DoublePtr Class::LookupCanonicalDouble(Zone* zone, double value) const {
  ASSERT(this->raw() == Isolate::Current()->object_store()->double_class());
  if (this->constants() == Array::null()) return Double::null();

  Double& canonical_value = Double::Handle(zone);
  CanonicalDoubleSet constants(zone, this->constants());
  canonical_value ^= constants.GetOrNull(CanonicalDoubleKey(value));
  this->set_constants(constants.Release());
  return canonical_value.raw();
}

// Returns an instance of Mint or Mint::null().
MintPtr Class::LookupCanonicalMint(Zone* zone, int64_t value) const {
  ASSERT(this->raw() == Isolate::Current()->object_store()->mint_class());
  if (this->constants() == Array::null()) return Mint::null();

  Mint& canonical_value = Mint::Handle(zone);
  CanonicalMintSet constants(zone, this->constants());
  canonical_value ^= constants.GetOrNull(CanonicalMintKey(value));
  this->set_constants(constants.Release());
  return canonical_value.raw();
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
  uword Hash() const { return key_.CanonicalizeHash(); }
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
    return Instance::Cast(key).CanonicalizeHash();
  }
  static uword Hash(const CanonicalInstanceKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const CanonicalInstanceKey& obj) {
    return obj.key_.raw();
  }
};
typedef UnorderedHashSet<CanonicalInstanceTraits> CanonicalInstancesSet;

InstancePtr Class::LookupCanonicalInstance(Zone* zone,
                                           const Instance& value) const {
  ASSERT(this->raw() == value.clazz());
  ASSERT(is_finalized() || is_prefinalized());
  Instance& canonical_value = Instance::Handle(zone);
  if (this->constants() != Array::null()) {
    CanonicalInstancesSet constants(zone, this->constants());
    canonical_value ^= constants.GetOrNull(CanonicalInstanceKey(value));
    this->set_constants(constants.Release());
  }
  return canonical_value.raw();
}

InstancePtr Class::InsertCanonicalConstant(Zone* zone,
                                           const Instance& constant) const {
  ASSERT(this->raw() == constant.clazz());
  Instance& canonical_value = Instance::Handle(zone);
  if (this->constants() == Array::null()) {
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

void Class::InsertCanonicalDouble(Zone* zone, const Double& constant) const {
  if (this->constants() == Array::null()) {
    this->set_constants(Array::Handle(
        zone, HashTables::New<CanonicalDoubleSet>(128, Heap::kOld)));
  }
  CanonicalDoubleSet constants(zone, this->constants());
  constants.InsertNewOrGet(CanonicalDoubleKey(constant));
  this->set_constants(constants.Release());
}

void Class::InsertCanonicalMint(Zone* zone, const Mint& constant) const {
  if (this->constants() == Array::null()) {
    this->set_constants(Array::Handle(
        zone, HashTables::New<CanonicalMintSet>(128, Heap::kOld)));
  }
  CanonicalMintSet constants(zone, this->constants());
  constants.InsertNewOrGet(CanonicalMintKey(constant));
  this->set_constants(constants.Release());
}

void Class::RehashConstants(Zone* zone) const {
  intptr_t cid = id();
  if ((cid == kMintCid) || (cid == kDoubleCid)) {
    // Constants stored as a plain list or in a hashset with a stable hashcode,
    // which only depends on the actual value of the constant.
    return;
  }

  const Array& old_constants = Array::Handle(zone, constants());
  if (old_constants.IsNull()) return;

  set_constants(Object::null_array());

  CanonicalInstancesSet set(zone, old_constants.raw());
  Instance& constant = Instance::Handle(zone);
  CanonicalInstancesSet::Iterator it(&set);
  while (it.MoveNext()) {
    constant ^= set.GetKey(it.Current());
    ASSERT(!constant.IsNull());
    // Shape changes lose the canonical bit because they may result/ in merging
    // constants. E.g., [x1, y1], [x1, y2] -> [x1].
    DEBUG_ASSERT(constant.IsCanonical() ||
                 Isolate::Current()->HasAttemptedReload());
    InsertCanonicalConstant(zone, constant);
  }
  set.Release();
}

bool Class::RequireLegacyErasureOfConstants(Zone* zone) const {
  const intptr_t num_type_params = NumTypeParameters();
  const intptr_t num_type_args = NumTypeArguments();
  const intptr_t from_index = num_type_args - num_type_params;
  Instance& constant = Instance::Handle(zone);
  TypeArguments& type_arguments = TypeArguments::Handle(zone);
  AbstractType& type = AbstractType::Handle(zone);
  CanonicalInstancesSet set(zone, constants());
  CanonicalInstancesSet::Iterator it(&set);
  while (it.MoveNext()) {
    constant ^= set.GetKey(it.Current());
    ASSERT(!constant.IsNull());
    ASSERT(!constant.IsTypeArguments());
    ASSERT(!constant.IsType());
    type_arguments = constant.GetTypeArguments();
    if (type_arguments.IsNull()) {
      continue;
    }
    for (intptr_t i = 0; i < num_type_params; i++) {
      type = type_arguments.TypeAt(from_index + i);
      if (!type.IsLegacy() && !type.IsVoidType() && !type.IsDynamicType() &&
          !type.IsNullType()) {
        set.Release();
        return true;
      }
      // It is not possible for a legacy type to have non-legacy type
      // arguments or for a legacy function type to have non-legacy parameter
      // types, non-legacy type parameters, or required named parameters.
    }
  }
  set.Release();
  return false;
}

intptr_t TypeArguments::ComputeNullability() const {
  if (IsNull()) return 0;
  const intptr_t num_types = Length();
  intptr_t result = 0;
  if (num_types <= kNullabilityMaxTypes) {
    AbstractType& type = AbstractType::Handle();
    for (intptr_t i = 0; i < num_types; i++) {
      result <<= kNullabilityBitsPerType;
      type = TypeAt(i);
      if (!type.IsNull() && !type.IsNullTypeRef()) {
        switch (type.nullability()) {
          case Nullability::kNullable:
            result |= kNullableBits;
            break;
          case Nullability::kNonNullable:
            result |= kNonNullableBits;
            break;
          case Nullability::kLegacy:
            result |= kLegacyBits;
            break;
          default:
            UNREACHABLE();
        }
      }
    }
  }
  set_nullability(result);
  return result;
}

void TypeArguments::set_nullability(intptr_t value) const {
  raw_ptr()->set_nullability(Smi::New(value));
}

intptr_t TypeArguments::HashForRange(intptr_t from_index, intptr_t len) const {
  if (IsNull()) return kAllDynamicHash;
  if (IsRaw(from_index, len)) return kAllDynamicHash;
  uint32_t result = 0;
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < len; i++) {
    type = TypeAt(from_index + i);
    // The hash may be calculated during type finalization (for debugging
    // purposes only) while a type argument is still temporarily null.
    if (type.IsNull() || type.IsNullTypeRef()) {
      return 0;  // Do not cache hash, since it will still change.
    }
    result = CombineHashes(result, type.Hash());
  }
  result = FinalizeHash(result, kHashBits);
  return result;
}

intptr_t TypeArguments::ComputeHash() const {
  if (IsNull()) return kAllDynamicHash;
  const intptr_t num_types = Length();
  const uint32_t result = HashForRange(0, num_types);
  if (result != 0) {
    SetHash(result);
  }
  return result;
}

TypeArgumentsPtr TypeArguments::Prepend(Zone* zone,
                                        const TypeArguments& other,
                                        intptr_t other_length,
                                        intptr_t total_length) const {
  if (other_length == 0) {
    ASSERT(IsCanonical());
    return raw();
  } else if (other_length == total_length) {
    ASSERT(other.IsCanonical());
    return other.raw();
  } else if (IsNull() && other.IsNull()) {
    return TypeArguments::null();
  }
  const TypeArguments& result =
      TypeArguments::Handle(zone, TypeArguments::New(total_length, Heap::kNew));
  AbstractType& type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < other_length; i++) {
    type = other.IsNull() ? Type::DynamicType() : other.TypeAt(i);
    result.SetTypeAt(i, type);
  }
  for (intptr_t i = other_length; i < total_length; i++) {
    type = IsNull() ? Type::DynamicType() : TypeAt(i - other_length);
    result.SetTypeAt(i, type);
  }
  return result.Canonicalize(Thread::Current(), nullptr);
}

TypeArgumentsPtr TypeArguments::ConcatenateTypeParameters(
    Zone* zone,
    const TypeArguments& other) const {
  ASSERT(!IsNull() && !other.IsNull());
  const intptr_t this_len = Length();
  const intptr_t other_len = other.Length();
  const auto& result = TypeArguments::Handle(
      zone, TypeArguments::New(this_len + other_len, Heap::kNew));
  auto& type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < this_len; ++i) {
    type = TypeAt(i);
    result.SetTypeAt(i, type);
  }
  for (intptr_t i = 0; i < other_len; ++i) {
    type = other.TypeAt(i);
    result.SetTypeAt(this_len + i, type);
  }
  return result.raw();
}

StringPtr TypeArguments::Name() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintSubvectorName(0, Length(), kInternalName, &printer);
  return Symbols::New(thread, printer.buffer());
}

StringPtr TypeArguments::UserVisibleName() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintSubvectorName(0, Length(), kUserVisibleName, &printer);
  return Symbols::New(thread, printer.buffer());
}

void TypeArguments::PrintSubvectorName(
    intptr_t from_index,
    intptr_t len,
    NameVisibility name_visibility,
    BaseTextBuffer* printer,
    NameDisambiguation name_disambiguation /* = NameDisambiguation::kNo */)
    const {
  printer->AddString("<");
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < len; i++) {
    if (from_index + i < Length()) {
      type = TypeAt(from_index + i);
      if (type.IsNull()) {
        printer->AddString("null");  // Unfinalized vector.
      } else {
        type.PrintName(name_visibility, printer, name_disambiguation);
      }
    } else {
      printer->AddString("dynamic");
    }
    if (i < len - 1) {
      printer->AddString(", ");
    }
  }
  printer->AddString(">");
}

void TypeArguments::PrintTo(BaseTextBuffer* buffer) const {
  buffer->AddString("TypeArguments: ");
  if (IsNull()) {
    return buffer->AddString("null");
  }
  buffer->Printf("(H%" Px ")", Smi::Value(raw_ptr()->hash()));
  auto& type_at = AbstractType::Handle();
  for (intptr_t i = 0; i < Length(); i++) {
    type_at = TypeAt(i);
    buffer->Printf(" [%s]", type_at.IsNull() ? "null" : type_at.ToCString());
  }
}

bool TypeArguments::IsSubvectorEquivalent(const TypeArguments& other,
                                          intptr_t from_index,
                                          intptr_t len,
                                          TypeEquality kind,
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
    // Still unfinalized vectors should not be considered equivalent.
    if (type.IsNull() || !type.IsEquivalent(other_type, kind, trail)) {
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
    if (!type.HasTypeClass()) {
      if (raw_instantiated && type.IsTypeParameter()) {
        // An uninstantiated type parameter is equivalent to dynamic.
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
  while (prior_instantiations.At(i) !=
         Smi::New(TypeArguments::kNoInstantiator)) {
    i += TypeArguments::Instantiation::kSizeInWords;
    num++;
  }
  return num;
}

ArrayPtr TypeArguments::instantiations() const {
  // We rely on the fact that any loads from the array are dependent loads and
  // avoid the load-acquire barrier here.
  return raw_ptr()->instantiations();
}

void TypeArguments::set_instantiations(const Array& value) const {
  // We have to ensure that initializing stores to the array are available
  // when releasing the pointer to the array pointer.
  // => We have to use store-release here.
  ASSERT(!value.IsNull());
  raw_ptr()->set_instantiations<std::memory_order_release>(value.raw());
}

bool TypeArguments::HasCount(intptr_t count) const {
  if (IsNull()) {
    return true;
  }
  return Length() == count;
}

intptr_t TypeArguments::Length() const {
  if (IsNull()) {
    return 0;
  }
  return Smi::Value(raw_ptr()->length());
}

intptr_t TypeArguments::nullability() const {
  if (IsNull()) {
    return 0;
  }
  return Smi::Value(raw_ptr()->nullability());
}

AbstractTypePtr TypeArguments::TypeAt(intptr_t index) const {
  ASSERT(!IsNull());
  ASSERT((index >= 0) && (index < Length()));
  return raw_ptr()->element(index);
}

AbstractTypePtr TypeArguments::TypeAtNullSafe(intptr_t index) const {
  if (IsNull()) {
    // null vector represents infinite list of dynamics
    return Type::dynamic_type().raw();
  }
  ASSERT((index >= 0) && (index < Length()));
  return TypeAt(index);
}

void TypeArguments::SetTypeAt(intptr_t index, const AbstractType& value) const {
  ASSERT(!IsCanonical());
  ASSERT((index >= 0) && (index < Length()));
  return raw_ptr()->set_element(index, value.raw());
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
      return false;  // Still unfinalized, too early to tell.
    }
    if (!type.IsTypeParameter()) {
      return false;
    }
    const TypeParameter& type_param = TypeParameter::Cast(type);
    ASSERT(type_param.IsFinalized());
    if ((type_param.index() != i) || type_param.IsFunctionTypeParameter()) {
      return false;
    }
    // Instantiating nullable and legacy type parameters may change
    // nullability of a type, so type arguments vector containing such type
    // parameters cannot be substituted with instantiator type arguments.
    if (type_param.IsNullable() || type_param.IsLegacy()) {
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
// A runtime check may be required, as indicated by with_runtime_check.
bool TypeArguments::CanShareInstantiatorTypeArguments(
    const Class& instantiator_class,
    bool* with_runtime_check) const {
  ASSERT(!IsInstantiated());
  if (with_runtime_check != nullptr) {
    *with_runtime_check = false;
  }
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
    // Instantiating nullable and legacy type parameters may change nullability
    // of a type, so type arguments vector containing such type parameters
    // cannot be substituted with instantiator type arguments, unless we check
    // at runtime the nullability of the first 1 or 2 type arguments of the
    // instantiator.
    // Note that the presence of non-overlapping super type arguments (i.e.
    // first_type_param_offset > 0) will prevent this optimization.
    if (type_param.IsNullable() || type_param.IsLegacy()) {
      if (with_runtime_check == nullptr || i >= kNullabilityMaxTypes) {
        return false;
      }
      *with_runtime_check = true;
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
    ASSERT(!IsUninstantiatedIdentity());
    return false;
  }
  AbstractType& super_type_arg = AbstractType::Handle();
  for (intptr_t i = 0; (i < first_type_param_offset) && (i < num_type_args);
       i++) {
    type_arg = TypeAt(i);
    super_type_arg = super_type_args.TypeAt(i);
    if (!type_arg.Equals(super_type_arg)) {
      ASSERT(!IsUninstantiatedIdentity());
      return false;
    }
  }
  return true;
}

// Return true if this uninstantiated type argument vector, once instantiated
// at runtime, is a prefix of the enclosing function type arguments.
// A runtime check may be required, as indicated by with_runtime_check.
bool TypeArguments::CanShareFunctionTypeArguments(
    const Function& function,
    bool* with_runtime_check) const {
  ASSERT(!IsInstantiated());
  if (with_runtime_check != nullptr) {
    *with_runtime_check = false;
  }
  const intptr_t num_type_args = Length();
  const intptr_t num_parent_type_params = function.NumParentTypeParameters();
  const intptr_t num_function_type_params = function.NumTypeParameters();
  const intptr_t num_function_type_args =
      num_parent_type_params + num_function_type_params;
  if (num_type_args > num_function_type_args) {
    // This vector cannot be a prefix of a shorter vector.
    return false;
  }
  AbstractType& type_arg = AbstractType::Handle();
  for (intptr_t i = 0; i < num_type_args; i++) {
    type_arg = TypeAt(i);
    if (!type_arg.IsTypeParameter()) {
      return false;
    }
    const TypeParameter& type_param = TypeParameter::Cast(type_arg);
    ASSERT(type_param.IsFinalized());
    if ((type_param.index() != i) || !type_param.IsFunctionTypeParameter()) {
      return false;
    }
    // Instantiating nullable and legacy type parameters may change nullability
    // of a type, so type arguments vector containing such type parameters
    // cannot be substituted with the enclosing function type arguments, unless
    // we check at runtime the nullability of the first 1 or 2 type arguments of
    // the enclosing function type arguments.
    if (type_param.IsNullable() || type_param.IsLegacy()) {
      if (with_runtime_check == nullptr || i >= kNullabilityMaxTypes) {
        return false;
      }
      *with_runtime_check = true;
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

TypeArgumentsPtr TypeArguments::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    intptr_t num_free_fun_type_params,
    Heap::Space space,
    TrailPtr trail) const {
  ASSERT(!IsInstantiated(kAny, num_free_fun_type_params));
  if ((instantiator_type_arguments.IsNull() ||
       instantiator_type_arguments.Length() == Length()) &&
      IsUninstantiatedIdentity()) {
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
    if (!type.IsNull() &&
        !type.IsInstantiated(kAny, num_free_fun_type_params)) {
      type = type.InstantiateFrom(instantiator_type_arguments,
                                  function_type_arguments,
                                  num_free_fun_type_params, space, trail);
      // A returned null type indicates a failed instantiation in dead code that
      // must be propagated up to the caller, the optimizing compiler.
      if (type.IsNull()) {
        return Object::empty_type_arguments().raw();
      }
    }
    instantiated_array.SetTypeAt(i, type);
  }
  return instantiated_array.raw();
}

TypeArgumentsPtr TypeArguments::InstantiateAndCanonicalizeFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments) const {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  SafepointMutexLocker ml(
      thread->isolate_group()->type_arguments_canonicalization_mutex());

  ASSERT(!IsInstantiated());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsCanonical());
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsCanonical());
  // Lookup instantiators and if found, return instantiated result.
  Array& prior_instantiations = Array::Handle(zone, instantiations());
  ASSERT(!prior_instantiations.IsNull() && prior_instantiations.IsArray());
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
  intptr_t index = 0;
  while (true) {
    if ((prior_instantiations.At(
             index +
             TypeArguments::Instantiation::kInstantiatorTypeArgsIndex) ==
         instantiator_type_arguments.raw()) &&
        (prior_instantiations.At(
             index + TypeArguments::Instantiation::kFunctionTypeArgsIndex) ==
         function_type_arguments.raw())) {
      return TypeArguments::RawCast(prior_instantiations.At(
          index + TypeArguments::Instantiation::kInstantiatedTypeArgsIndex));
    }
    if (prior_instantiations.At(index) ==
        Smi::New(TypeArguments::kNoInstantiator)) {
      break;
    }
    index += TypeArguments::Instantiation::kSizeInWords;
  }
  // Cache lookup failed. Instantiate the type arguments.
  TypeArguments& result = TypeArguments::Handle(zone);
  result = InstantiateFrom(instantiator_type_arguments, function_type_arguments,
                           kAllFree, Heap::kOld);
  // Canonicalize type arguments.
  result = result.Canonicalize(thread, nullptr);
  // InstantiateAndCanonicalizeFrom is not reentrant. It cannot have been called
  // indirectly, so the prior_instantiations array cannot have grown.
  ASSERT(prior_instantiations.raw() == instantiations());
  // Add instantiator and function type args and result to instantiations array.
  intptr_t length = prior_instantiations.Length();
  if ((index + TypeArguments::Instantiation::kSizeInWords) >= length) {
    // TODO(regis): Should we limit the number of cached instantiations?
    // Grow the instantiations array by about 50%, but at least by 1.
    // The initial array is Object::zero_array() of length 1.
    intptr_t entries =
        (length - 1) / TypeArguments::Instantiation::kSizeInWords;
    intptr_t new_entries = entries + (entries >> 1) + 1;
    length = new_entries * TypeArguments::Instantiation::kSizeInWords + 1;
    prior_instantiations =
        Array::Grow(prior_instantiations, length, Heap::kOld);
    set_instantiations(prior_instantiations);
    ASSERT((index + TypeArguments::Instantiation::kSizeInWords) < length);
  }

  // Set sentinel marker at next position.
  prior_instantiations.SetAt(
      index + TypeArguments::Instantiation::kSizeInWords +
          TypeArguments::Instantiation::kInstantiatorTypeArgsIndex,
      Smi::Handle(zone, Smi::New(TypeArguments::kNoInstantiator)));

  prior_instantiations.SetAt(
      index + TypeArguments::Instantiation::kFunctionTypeArgsIndex,
      function_type_arguments);
  prior_instantiations.SetAt(
      index + TypeArguments::Instantiation::kInstantiatedTypeArgsIndex, result);

  // We let any concurrently running mutator thread now see the new entry by
  // using a store-release barrier.
  ASSERT(
      prior_instantiations.At(
          index + TypeArguments::Instantiation::kInstantiatorTypeArgsIndex) ==
      Smi::New(TypeArguments::kNoInstantiator));
  prior_instantiations.SetAtRelease(
      index + TypeArguments::Instantiation::kInstantiatorTypeArgsIndex,
      instantiator_type_arguments);
  return result.raw();
}

TypeArgumentsPtr TypeArguments::New(intptr_t len, Heap::Space space) {
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in TypeArguments::New: invalid len %" Pd "\n", len);
  }
  TypeArguments& result = TypeArguments::Handle();
  {
    ObjectPtr raw = Object::Allocate(TypeArguments::kClassId,
                                     TypeArguments::InstanceSize(len), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    // Length must be set before we start storing into the array.
    result.SetLength(len);
    result.SetHash(0);
    result.set_nullability(0);
  }
  // The zero array should have been initialized.
  ASSERT(Object::zero_array().raw() != Array::null());
  COMPILE_ASSERT(TypeArguments::kNoInstantiator == 0);
  result.set_instantiations(Object::zero_array());
  return result.raw();
}

void TypeArguments::SetLength(intptr_t value) const {
  ASSERT(!IsCanonical());
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  raw_ptr()->set_length(Smi::New(value));
}

TypeArgumentsPtr TypeArguments::Canonicalize(Thread* thread,
                                             TrailPtr trail) const {
  if (IsNull() || IsCanonical()) {
    ASSERT(IsOld());
    return this->raw();
  }
  const intptr_t num_types = Length();
  if (num_types == 0) {
    return TypeArguments::empty_type_arguments().raw();
  } else if (IsRaw(0, num_types)) {
    return TypeArguments::null();
  }
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();
  TypeArguments& result = TypeArguments::Handle(zone);
  {
    SafepointMutexLocker ml(isolate->group()->type_canonicalization_mutex());
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
      type_arg = type_arg.Canonicalize(thread, trail);
      if (IsCanonical()) {
        // Canonicalizing this type_arg canonicalized this type.
        ASSERT(IsRecursive());
        return this->raw();
      }
      SetTypeAt(i, type_arg);
    }
    // Canonicalization of a type argument of a recursive type argument vector
    // may change the hash of the vector, so invalidate.
    if (IsRecursive()) {
      SetHash(0);
    }
    SafepointMutexLocker ml(isolate->group()->type_canonicalization_mutex());
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
        result = this->raw();
      }
      ASSERT(result.IsOld());
      result.ComputeNullability();
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

void TypeArguments::EnumerateURIs(URIs* uris) const {
  if (IsNull()) {
    return;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  AbstractType& type = AbstractType::Handle(zone);
  const intptr_t num_types = Length();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    type.EnumerateURIs(uris);
  }
}

const char* TypeArguments::ToCString() const {
  if (IsNull()) {
    return "TypeArguments: null";  // Optimizing the frequent case.
  }
  ZoneTextBuffer buffer(Thread::Current()->zone());
  PrintTo(&buffer);
  return buffer.buffer();
}

const char* PatchClass::ToCString() const {
  const Class& cls = Class::Handle(patched_class());
  const char* cls_name = cls.ToCString();
  return OS::SCreate(Thread::Current()->zone(), "PatchClass for %s", cls_name);
}

PatchClassPtr PatchClass::New(const Class& patched_class,
                              const Class& origin_class) {
  const PatchClass& result = PatchClass::Handle(PatchClass::New());
  result.set_patched_class(patched_class);
  result.set_origin_class(origin_class);
  result.set_script(Script::Handle(origin_class.script()));
  result.set_library_kernel_offset(-1);
  return result.raw();
}

PatchClassPtr PatchClass::New(const Class& patched_class,
                              const Script& script) {
  const PatchClass& result = PatchClass::Handle(PatchClass::New());
  result.set_patched_class(patched_class);
  result.set_origin_class(patched_class);
  result.set_script(script);
  result.set_library_kernel_offset(-1);
  return result.raw();
}

PatchClassPtr PatchClass::New() {
  ASSERT(Object::patch_class_class() != Class::null());
  ObjectPtr raw = Object::Allocate(PatchClass::kClassId,
                                   PatchClass::InstanceSize(), Heap::kOld);
  return static_cast<PatchClassPtr>(raw);
}

void PatchClass::set_patched_class(const Class& value) const {
  raw_ptr()->set_patched_class(value.raw());
}

void PatchClass::set_origin_class(const Class& value) const {
  raw_ptr()->set_origin_class(value.raw());
}

void PatchClass::set_script(const Script& value) const {
  raw_ptr()->set_script(value.raw());
}

void PatchClass::set_library_kernel_data(const ExternalTypedData& data) const {
  raw_ptr()->set_library_kernel_data(data.raw());
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
  raw_ptr()->set_code(value.raw());
  StoreNonPointer(&raw_ptr()->entry_point_, value.EntryPoint());
  StoreNonPointer(&raw_ptr()->unchecked_entry_point_,
                  value.UncheckedEntryPoint());
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
  NoSafepointScope no_safepoint;
  ASSERT(raw_ptr()->code() != Code::null());
  return raw_ptr()->code() != StubCode::LazyCompile().raw();
}

bool Function::HasCode(FunctionPtr function) {
  NoSafepointScope no_safepoint;
  ASSERT(function->ptr()->code() != Code::null());
  return function->ptr()->code() != StubCode::LazyCompile().raw();
}

void Function::ClearCode() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(Thread::Current()->IsMutatorThread());

  raw_ptr()->set_unoptimized_code(Code::null());

  SetInstructions(StubCode::LazyCompile());
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

void Function::EnsureHasCompiledUnoptimizedCode() const {
  ASSERT(!ForceOptimize());
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  DEBUG_ASSERT(thread->TopErrorHandlerIsExitFrame());
  Zone* zone = thread->zone();

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
  // TODO(35224): DEBUG_ASSERT(thread->TopErrorHandlerIsExitFrame());
  const Code& current_code = Code::Handle(zone, CurrentCode());

  if (FLAG_trace_deoptimization_verbose) {
    THR_Print("Disabling optimized code: '%s' entry: %#" Px "\n",
              ToFullyQualifiedCString(), current_code.EntryPoint());
  }
  current_code.DisableDartCode();
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, *this));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& unopt_code = Code::Handle(zone, unoptimized_code());
  unopt_code.Enable();
  AttachCode(unopt_code);
  isolate->TrackDeoptimizedCode(current_code);
}

void Function::SwitchToLazyCompiledUnoptimizedCode() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
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
    // Set the lazy compile stub code.
    TIR_Print("Switched to lazy compile stub for %s\n", ToCString());
    SetInstructions(StubCode::LazyCompile());
    return;
  }

  TIR_Print("Switched to unoptimized code for %s\n", ToCString());

  AttachCode(unopt_code);
  unopt_code.Enable();
#endif
}

void Function::set_unoptimized_code(const Code& value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  ASSERT(value.IsNull() || !value.is_optimized());
  raw_ptr()->set_unoptimized_code(value.raw());
#endif
}

ContextScopePtr Function::context_scope() const {
  if (IsClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data());
    ASSERT(!obj.IsNull());
    return ClosureData::Cast(obj).context_scope();
  }
  return ContextScope::null();
}

void Function::set_context_scope(const ContextScope& value) const {
  if (IsClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data());
    ASSERT(!obj.IsNull());
    ClosureData::Cast(obj).set_context_scope(value);
    return;
  }
  UNREACHABLE();
}

InstancePtr Function::implicit_static_closure() const {
  if (IsImplicitStaticClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data());
    ASSERT(!obj.IsNull());
    return ClosureData::Cast(obj).implicit_static_closure();
  }
  return Instance::null();
}

void Function::set_implicit_static_closure(const Instance& closure) const {
  if (IsImplicitStaticClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data());
    ASSERT(!obj.IsNull());
    ClosureData::Cast(obj).set_implicit_static_closure(closure);
    return;
  }
  UNREACHABLE();
}

ScriptPtr Function::eval_script() const {
  const Object& obj = Object::Handle(raw_ptr()->data());
  if (obj.IsScript()) {
    return Script::Cast(obj).raw();
  }
  return Script::null();
}

void Function::set_eval_script(const Script& script) const {
  ASSERT(token_pos() == TokenPosition::kMinSource);
  ASSERT(raw_ptr()->data() == Object::null());
  set_data(script);
}

FunctionPtr Function::extracted_method_closure() const {
  ASSERT(kind() == FunctionLayout::kMethodExtractor);
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(obj.IsFunction());
  return Function::Cast(obj).raw();
}

void Function::set_extracted_method_closure(const Function& value) const {
  ASSERT(kind() == FunctionLayout::kMethodExtractor);
  ASSERT(raw_ptr()->data() == Object::null());
  set_data(value);
}

ArrayPtr Function::saved_args_desc() const {
  ASSERT(kind() == FunctionLayout::kNoSuchMethodDispatcher ||
         kind() == FunctionLayout::kInvokeFieldDispatcher);
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(obj.IsArray());
  return Array::Cast(obj).raw();
}

void Function::set_saved_args_desc(const Array& value) const {
  ASSERT(kind() == FunctionLayout::kNoSuchMethodDispatcher ||
         kind() == FunctionLayout::kInvokeFieldDispatcher);
  ASSERT(raw_ptr()->data() == Object::null());
  set_data(value);
}

FieldPtr Function::accessor_field() const {
  ASSERT(kind() == FunctionLayout::kImplicitGetter ||
         kind() == FunctionLayout::kImplicitSetter ||
         kind() == FunctionLayout::kImplicitStaticGetter ||
         kind() == FunctionLayout::kFieldInitializer);
  return Field::RawCast(raw_ptr()->data());
}

void Function::set_accessor_field(const Field& value) const {
  ASSERT(kind() == FunctionLayout::kImplicitGetter ||
         kind() == FunctionLayout::kImplicitSetter ||
         kind() == FunctionLayout::kImplicitStaticGetter ||
         kind() == FunctionLayout::kFieldInitializer);
  // Top level classes may be finalized multiple times.
  ASSERT(raw_ptr()->data() == Object::null() ||
         raw_ptr()->data() == value.raw());
  set_data(value);
}

FunctionPtr Function::parent_function() const {
  if (IsClosureFunction() || IsSignatureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data());
    ASSERT(!obj.IsNull());
    if (IsClosureFunction()) {
      return ClosureData::Cast(obj).parent_function();
    } else {
      return SignatureData::Cast(obj).parent_function();
    }
  }
  return Function::null();
}

void Function::set_parent_function(const Function& value) const {
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  if (IsClosureFunction()) {
    ClosureData::Cast(obj).set_parent_function(value);
  } else {
    ASSERT(IsSignatureFunction());
    SignatureData::Cast(obj).set_parent_function(value);
  }
}

TypeArgumentsPtr Function::InstantiateToBounds(
    Thread* thread,
    DefaultTypeArgumentsKind* kind_out) const {
  if (CachesDefaultTypeArguments()) {
    // Always use the cached version, even if the type parameters are null,
    // to catch cases where the cache isn't properly initialized.
    return default_type_arguments(kind_out);
  }
  // No cached version, so just retrieve from the type parameters and return
  // a canonicalized version..
  if (type_parameters() == TypeArguments::null()) {
    if (kind_out != nullptr) {
      *kind_out = DefaultTypeArgumentsKind::kIsInstantiated;
    }
    return Object::empty_type_arguments().raw();
  }
  auto& result = TypeArguments::Handle(thread->zone(), type_parameters());
  result = InstantiateTypeArgumentsToBounds(thread, result);
  if (kind_out != nullptr) {
    // We just return is/is not instantiated if the value isn't cached, as
    // the other checks may be more overhead at runtime than just doing the
    // instantiation.
    *kind_out = result.IsNull() || result.IsInstantiated()
                    ? DefaultTypeArgumentsKind::kIsInstantiated
                    : DefaultTypeArgumentsKind::kNeedsInstantiation;
  }
  return result.raw();
}

void Function::UpdateCachedDefaultTypeArguments(Thread* thread) const {
  auto const zone = thread->zone();
  auto& closure_function = Function::Handle(zone);
  if (HasImplicitClosureFunction()) {
    closure_function = ImplicitClosureFunction();
  }
  if (CachesDefaultTypeArguments()) {
    auto defaults = &Object::empty_type_arguments();
    if (NumTypeParameters(thread) > 0) {
      const auto& params = TypeArguments::Handle(zone, type_parameters());
      const intptr_t num_params = params.Length();
      auto& new_defaults = TypeArguments::Handle(
          zone, TypeArguments::New(num_params, Heap::kNew));
      // Only canonicalize the result if all the default arguments have been
      // canonicalized, to avoid premature canonicalization of the arguments.
      bool all_canonical = true;
      auto& type = AbstractType::Handle(zone);
      for (intptr_t i = 0; i < num_params; i++) {
        type = params.TypeAt(i);
        type = TypeParameter::Cast(type).default_argument();
        if (!type.IsCanonical()) {
          all_canonical = false;
        }
        new_defaults.SetTypeAt(i, type);
      }
      if (all_canonical) {
        new_defaults = new_defaults.Canonicalize(thread);
      }
      defaults = &new_defaults;
    }
    set_default_type_arguments(*defaults);
    if (!closure_function.IsNull()) {
      closure_function.set_default_type_arguments(*defaults);
    }
  } else if (!closure_function.IsNull()) {
    closure_function.UpdateCachedDefaultTypeArguments(thread);
  }
}

TypeArgumentsPtr Function::default_type_arguments(
    DefaultTypeArgumentsKind* kind_out) const {
  if (!CachesDefaultTypeArguments()) {
    UNREACHABLE();
  }
  const auto& closure_data =
      ClosureData::Handle(ClosureData::RawCast(raw_ptr()->data()));
  ASSERT(!closure_data.IsNull());
  if (kind_out != nullptr) {
    *kind_out = DefaultTypeArgumentsKindField::decode(
        closure_data.default_type_arguments_info());
  }
  return closure_data.default_type_arguments();
}

void Function::set_default_type_arguments(const TypeArguments& value) const {
  if (!CachesDefaultTypeArguments()) {
    UNREACHABLE();
  }
  const auto& closure_data =
      ClosureData::Handle(ClosureData::RawCast(raw_ptr()->data()));
  ASSERT(!closure_data.IsNull());
  intptr_t updated_info = closure_data.default_type_arguments_info();
  auto kind = DefaultTypeArgumentsKindFor(value);
  ASSERT(kind != DefaultTypeArgumentsKind::kInvalid);
  updated_info = DefaultTypeArgumentsKindField::update(kind, updated_info);
  updated_info = NumParentTypeParametersField::update(NumParentTypeParameters(),
                                                      updated_info);
  closure_data.set_default_type_arguments_info(updated_info);
  // We could just store null for the ksharesFunction/kSharesInstantiator cases,
  // assuming all clients retrieve the DefaultTypeArgumentsKind to distinguish.
  closure_data.set_default_type_arguments(value);
}

Function::DefaultTypeArgumentsKind Function::DefaultTypeArgumentsKindFor(
    const TypeArguments& value) const {
  if (value.IsNull() || value.IsInstantiated()) {
    return DefaultTypeArgumentsKind::kIsInstantiated;
  }
  if (value.CanShareFunctionTypeArguments(*this)) {
    return DefaultTypeArgumentsKind::kSharesFunctionTypeArguments;
  }
  const auto& cls = Class::Handle(Owner());
  if (value.CanShareInstantiatorTypeArguments(cls)) {
    return DefaultTypeArgumentsKind::kSharesInstantiatorTypeArguments;
  }
  return DefaultTypeArgumentsKind::kNeedsInstantiation;
}

FunctionPtr Function::GetGeneratedClosure() const {
  const auto& closure_functions = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->closure_functions());
  auto& entry = Object::Handle();

  for (auto i = (closure_functions.Length() - 1); i >= 0; i--) {
    entry = closure_functions.At(i);

    ASSERT(entry.IsFunction());

    const auto& closure_function = Function::Cast(entry);
    if (closure_function.parent_function() == raw() &&
        closure_function.is_generated_body()) {
      return closure_function.raw();
    }
  }

  return Function::null();
}

// Enclosing outermost function of this local function.
FunctionPtr Function::GetOutermostFunction() const {
  FunctionPtr parent = parent_function();
  if (parent == Object::null()) {
    return raw();
  }
  Function& function = Function::Handle();
  do {
    function = parent;
    parent = function.parent_function();
  } while (parent != Object::null());
  return function.raw();
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

FunctionPtr Function::implicit_closure_function() const {
  if (IsClosureFunction() || IsSignatureFunction() || IsFactory() ||
      IsDispatcherOrImplicitAccessor() || IsFieldInitializer()) {
    return Function::null();
  }
  const Object& obj = Object::Handle(raw_ptr()->data());
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
  ASSERT(!IsClosureFunction() && !IsSignatureFunction());
  const Object& old_data = Object::Handle(raw_ptr()->data());
  if (is_native()) {
    ASSERT(old_data.IsArray());
    ASSERT((Array::Cast(old_data).At(1) == Object::null()) || value.IsNull());
    Array::Cast(old_data).SetAt(1, value);
  } else {
    // Maybe this function will turn into a native later on :-/
    if (old_data.IsArray()) {
      ASSERT((Array::Cast(old_data).At(1) == Object::null()) || value.IsNull());
      Array::Cast(old_data).SetAt(1, value);
    } else {
      ASSERT(old_data.IsNull() || value.IsNull());
      set_data(value);
    }
  }
}

TypePtr Function::ExistingSignatureType() const {
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  if (IsSignatureFunction()) {
    return SignatureData::Cast(obj).signature_type();
  } else if (IsClosureFunction()) {
    return ClosureData::Cast(obj).signature_type();
  } else {
    ASSERT(IsFfiTrampoline());
    return FfiTrampolineData::Cast(obj).signature_type();
  }
}

void Function::SetFfiCSignature(const Function& sig) const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  FfiTrampolineData::Cast(obj).set_c_signature(sig);
}

FunctionPtr Function::FfiCSignature() const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  return FfiTrampolineData::Cast(obj).c_signature();
}

bool Function::FfiCSignatureContainsHandles() const {
  ASSERT(IsFfiTrampoline());
  const Function& c_signature = Function::Handle(FfiCSignature());
  const intptr_t num_params = c_signature.num_fixed_parameters();
  for (intptr_t i = 0; i < num_params; i++) {
    const bool is_handle =
        AbstractType::Handle(c_signature.ParameterTypeAt(i)).type_class_id() ==
        kFfiHandleCid;
    if (is_handle) {
      return true;
    }
  }
  return AbstractType::Handle(c_signature.result_type()).type_class_id() ==
         kFfiHandleCid;
}

bool Function::FfiCSignatureReturnsStruct() const {
  ASSERT(IsFfiTrampoline());
  const Function& c_signature = Function::Handle(FfiCSignature());
  const auto& return_type = AbstractType::Handle(c_signature.result_type());
  const bool predefined = IsFfiTypeClassId(return_type.type_class_id());
  return !predefined;
}

int32_t Function::FfiCallbackId() const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  return FfiTrampolineData::Cast(obj).callback_id();
}

void Function::SetFfiCallbackId(int32_t value) const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  FfiTrampolineData::Cast(obj).set_callback_id(value);
}

FunctionPtr Function::FfiCallbackTarget() const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  return FfiTrampolineData::Cast(obj).callback_target();
}

void Function::SetFfiCallbackTarget(const Function& target) const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  FfiTrampolineData::Cast(obj).set_callback_target(target);
}

InstancePtr Function::FfiCallbackExceptionalReturn() const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  return FfiTrampolineData::Cast(obj).callback_exceptional_return();
}

void Function::SetFfiCallbackExceptionalReturn(const Instance& value) const {
  ASSERT(IsFfiTrampoline());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  FfiTrampolineData::Cast(obj).set_callback_exceptional_return(value);
}

TypePtr Function::SignatureType(Nullability nullability) const {
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
    type = Type::New(scope_class, signature_type_arguments, token_pos(),
                     nullability);
    type.set_signature(*this);
    SetSignatureType(type);
  }
  return type.ToNullability(nullability, Heap::kOld);
}

void Function::SetSignatureType(const Type& value) const {
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(!obj.IsNull());
  if (IsSignatureFunction()) {
    SignatureData::Cast(obj).set_signature_type(value);
    ASSERT(!value.IsCanonical() || (value.signature() == this->raw()));
  } else if (IsClosureFunction()) {
    ClosureData::Cast(obj).set_signature_type(value);
  } else {
    ASSERT(IsFfiTrampoline());
    FfiTrampolineData::Cast(obj).set_signature_type(value);
  }
}

const char* Function::KindToCString(FunctionLayout::Kind kind) {
  return FunctionLayout::KindToCString(kind);
}

FunctionPtr Function::ForwardingTarget() const {
  ASSERT(kind() == FunctionLayout::kDynamicInvocationForwarder);
  Array& checks = Array::Handle();
  checks ^= raw_ptr()->data();
  return Function::RawCast(checks.At(0));
}

void Function::SetForwardingChecks(const Array& checks) const {
  ASSERT(kind() == FunctionLayout::kDynamicInvocationForwarder);
  ASSERT(checks.Length() >= 1);
  ASSERT(Object::Handle(checks.At(0)).IsFunction());
  set_data(checks);
}

// This field is heavily overloaded:
//   eval function:           Script expression source
//   kernel eval function:    Array[0] = Script
//                            Array[1] = Kernel data
//                            Array[2] = Kernel offset of enclosing library
//   signature function:      SignatureData
//   method extractor:        Function extracted closure function
//   implicit getter:         Field
//   implicit setter:         Field
//   impl. static final gttr: Field
//   field initializer:       Field
//   noSuchMethod dispatcher: Array arguments descriptor
//   invoke-field dispatcher: Array arguments descriptor
//   closure function:        ClosureData
//   irregexp function:       Array[0] = RegExp
//                            Array[1] = Smi string specialization cid
//   native function:         Array[0] = String native name
//                            Array[1] = Function implicit closure function
//   regular function:        Function for implicit closure function
//   ffi trampoline function: FfiTrampolineData  (Dart->C)
//   dyn inv forwarder:       Array[0] = Function target
//                            Array[1] = TypeArguments default type args
void Function::set_data(const Object& value) const {
  raw_ptr()->set_data(value.raw());
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
  raw_ptr()->set_name(value.raw());
}

void Function::set_owner(const Object& value) const {
  ASSERT(!value.IsNull() || IsSignatureFunction());
  raw_ptr()->set_owner(value.raw());
}

RegExpPtr Function::regexp() const {
  ASSERT(kind() == FunctionLayout::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data()));
  return RegExp::RawCast(pair.At(0));
}

class StickySpecialization : public BitField<intptr_t, bool, 0, 1> {};
class StringSpecializationCid
    : public BitField<intptr_t, intptr_t, 1, ObjectLayout::kClassIdTagSize> {};

intptr_t Function::string_specialization_cid() const {
  ASSERT(kind() == FunctionLayout::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data()));
  return StringSpecializationCid::decode(Smi::Value(Smi::RawCast(pair.At(1))));
}

bool Function::is_sticky_specialization() const {
  ASSERT(kind() == FunctionLayout::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data()));
  return StickySpecialization::decode(Smi::Value(Smi::RawCast(pair.At(1))));
}

void Function::SetRegExpData(const RegExp& regexp,
                             intptr_t string_specialization_cid,
                             bool sticky) const {
  ASSERT(kind() == FunctionLayout::kIrregexpFunction);
  ASSERT(IsStringClassId(string_specialization_cid));
  ASSERT(raw_ptr()->data() == Object::null());
  const Array& pair = Array::Handle(Array::New(2, Heap::kOld));
  pair.SetAt(0, regexp);
  pair.SetAt(1, Smi::Handle(Smi::New(StickySpecialization::encode(sticky) |
                                     StringSpecializationCid::encode(
                                         string_specialization_cid))));
  set_data(pair);
}

StringPtr Function::native_name() const {
  ASSERT(is_native());
  const Object& obj = Object::Handle(raw_ptr()->data());
  ASSERT(obj.IsArray());
  return String::RawCast(Array::Cast(obj).At(0));
}

void Function::set_native_name(const String& value) const {
  Zone* zone = Thread::Current()->zone();
  ASSERT(is_native());

  // Due to the fact that kernel needs to read in the constant table before the
  // annotation data is available, we don't know at function creation time
  // whether the function is a native or not.
  //
  // Reading the constant table can cause a static function to get an implicit
  // closure function.
  //
  // We therefore handle both cases.
  const Object& old_data = Object::Handle(zone, raw_ptr()->data());
  ASSERT(old_data.IsNull() ||
         (old_data.IsFunction() &&
          Function::Handle(zone, Function::RawCast(old_data.raw()))
              .IsImplicitClosureFunction()));

  const Array& pair = Array::Handle(zone, Array::New(2, Heap::kOld));
  pair.SetAt(0, value);
  pair.SetAt(1, old_data);  // will be the implicit closure function if needed.
  set_data(pair);
}

void Function::set_result_type(const AbstractType& value) const {
  ASSERT(!value.IsNull());
  raw_ptr()->set_result_type(value.raw());
}

AbstractTypePtr Function::ParameterTypeAt(intptr_t index) const {
  const Array& parameter_types = Array::Handle(raw_ptr()->parameter_types());
  return AbstractType::RawCast(parameter_types.At(index));
}

void Function::SetParameterTypeAt(intptr_t index,
                                  const AbstractType& value) const {
  ASSERT(!value.IsNull());
  // Method extractor parameters are shared and are in the VM heap.
  ASSERT(kind() != FunctionLayout::kMethodExtractor);
  const Array& parameter_types = Array::Handle(raw_ptr()->parameter_types());
  parameter_types.SetAt(index, value);
}

void Function::set_parameter_types(const Array& value) const {
  raw_ptr()->set_parameter_types(value.raw());
}

StringPtr Function::ParameterNameAt(intptr_t index) const {
  const Array& parameter_names = Array::Handle(raw_ptr()->parameter_names());
  return String::RawCast(parameter_names.At(index));
}

void Function::SetParameterNameAt(intptr_t index, const String& value) const {
  ASSERT(!value.IsNull() && value.IsSymbol());
  const Array& parameter_names = Array::Handle(raw_ptr()->parameter_names());
  parameter_names.SetAt(index, value);
}

void Function::set_parameter_names(const Array& value) const {
  raw_ptr()->set_parameter_names(value.raw());
}

void Function::CreateNameArrayIncludingFlags(Heap::Space space) const {
  // Currently, we only store flags for named parameters that are required.
  const intptr_t num_parameters = NumParameters();
  intptr_t num_total_slots = num_parameters;
  if (HasOptionalNamedParameters()) {
    const intptr_t last_index = (NumOptionalNamedParameters() - 1) /
                                compiler::target::kNumParameterFlagsPerElement;
    const intptr_t num_flag_slots = last_index + 1;
    num_total_slots += num_flag_slots;
  }
  auto& array = Array::Handle(Array::New(num_total_slots, space));
  if (num_total_slots > num_parameters) {
    // Set flag slots to Smi 0 before handing off.
    auto& empty_flags_smi = Smi::Handle(Smi::New(0));
    for (intptr_t i = num_parameters; i < num_total_slots; i++) {
      array.SetAt(i, empty_flags_smi);
    }
  }
  set_parameter_names(array);
}

intptr_t Function::GetRequiredFlagIndex(intptr_t index,
                                        intptr_t* flag_mask) const {
  // If these calculations change, also change
  // FlowGraphBuilder::BuildClosureCallHasRequiredNamedArgumentsCheck.
  ASSERT(flag_mask != nullptr);
  ASSERT(index >= num_fixed_parameters());
  index -= num_fixed_parameters();
  *flag_mask = (1 << compiler::target::kRequiredNamedParameterFlag)
               << ((static_cast<uintptr_t>(index) %
                    compiler::target::kNumParameterFlagsPerElement) *
                   compiler::target::kNumParameterFlags);
  return NumParameters() +
         index / compiler::target::kNumParameterFlagsPerElement;
}

bool Function::IsRequiredAt(intptr_t index) const {
  if (index < num_fixed_parameters() + NumOptionalPositionalParameters()) {
    return false;
  }
  intptr_t flag_mask;
  const intptr_t flag_index = GetRequiredFlagIndex(index, &flag_mask);
  const Array& parameter_names = Array::Handle(raw_ptr()->parameter_names());
  if (flag_index >= parameter_names.Length()) {
    return false;
  }
  const intptr_t flags =
      Smi::Value(Smi::RawCast(parameter_names.At(flag_index)));
  return (flags & flag_mask) != 0;
}

void Function::SetIsRequiredAt(intptr_t index) const {
  intptr_t flag_mask;
  const intptr_t flag_index = GetRequiredFlagIndex(index, &flag_mask);
  const Array& parameter_names = Array::Handle(raw_ptr()->parameter_names());
  ASSERT(flag_index < parameter_names.Length());
  const intptr_t flags =
      Smi::Value(Smi::RawCast(parameter_names.At(flag_index)));
  parameter_names.SetAt(flag_index, Smi::Handle(Smi::New(flags | flag_mask)));
}

void Function::TruncateUnusedParameterFlags() const {
  const Array& parameter_names = Array::Handle(raw_ptr()->parameter_names());
  const intptr_t num_params = NumParameters();
  if (parameter_names.Length() == num_params) {
    // No flag slots to truncate.
    return;
  }
  // Truncate the parameter names array to remove unused flags from the end.
  intptr_t last_used = parameter_names.Length() - 1;
  for (; last_used >= num_params; --last_used) {
    if (Smi::Value(Smi::RawCast(parameter_names.At(last_used))) != 0) {
      break;
    }
  }
  parameter_names.Truncate(last_used + 1);
}

void Function::set_type_parameters(const TypeArguments& value) const {
  raw_ptr()->set_type_parameters(value.raw());
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
    parent = parent.parent_function();
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
    sig_fun = sig_fun.parent_function();
  }
}

TypeParameterPtr Function::LookupTypeParameter(const String& type_name,
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

  function = this->raw();
  while (!function.IsNull()) {
    type_params = function.type_parameters();
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
    function = function.parent_function();
    if (function_level != NULL) {
      (*function_level)--;
    }
  }
  return TypeParameter::null();
}

void Function::set_kind(FunctionLayout::Kind value) const {
  set_kind_tag(KindBits::update(value, raw_ptr()->kind_tag_));
}

void Function::set_modifier(FunctionLayout::AsyncModifier value) const {
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

void Function::set_packed_fields(uint32_t packed_fields) const {
  StoreNonPointer(&raw_ptr()->packed_fields_, packed_fields);
}

void Function::set_num_fixed_parameters(intptr_t value) const {
  ASSERT(value >= 0);
  ASSERT(Utils::IsUint(FunctionLayout::kMaxFixedParametersBits, value));
  const uint32_t* original = &raw_ptr()->packed_fields_;
  StoreNonPointer(original, FunctionLayout::PackedNumFixedParameters::update(
                                value, *original));
}

void Function::SetNumOptionalParameters(intptr_t value,
                                        bool are_optional_positional) const {
  ASSERT(Utils::IsUint(FunctionLayout::kMaxOptionalParametersBits, value));
  uint32_t packed_fields = raw_ptr()->packed_fields_;
  packed_fields = FunctionLayout::PackedHasNamedOptionalParameters::update(
      !are_optional_positional, packed_fields);
  packed_fields =
      FunctionLayout::PackedNumOptionalParameters::update(value, packed_fields);
  set_packed_fields(packed_fields);
}

bool Function::IsOptimizable() const {
  if (FLAG_precompiled_mode) {
    return true;
  }
  if (ForceOptimize()) return true;
  if (is_native()) {
    // Native methods don't need to be optimized.
    return false;
  }
  if (is_optimizable() && (script() != Script::null()) &&
      SourceSize() < FLAG_huge_method_cutoff_in_tokens) {
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
    set_usage_counter(INT32_MIN);
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
bool Function::CanBeInlined() const {
  // Our force-optimized functions cannot deoptimize to an unoptimized frame.
  // If the instructions of the force-optimized function body get moved via
  // code motion, we might attempt do deoptimize a frame where the force-
  // optimized function has only partially finished. Since force-optimized
  // functions cannot deoptimize to unoptimized frames we prevent them from
  // being inlined (for now).
  if (ForceOptimize()) {
    if (IsFfiTrampoline()) {
      // The CallSiteInliner::InlineCall asserts in PrepareGraphs that
      // GraphEntryInstr::SuccessorCount() == 1, but FFI trampoline has two
      // entries (a normal and a catch entry).
      return false;
    }
    return CompilerState::Current().is_aot();
  }

#if !defined(PRODUCT)
  Thread* thread = Thread::Current();
  if (thread->isolate()->debugger()->HasBreakpoint(*this, thread->zone())) {
    return false;
  }
#endif  // !defined(PRODUCT)

  return is_inlinable() && !is_external() && !is_generated_body();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

intptr_t Function::NumParameters() const {
  return num_fixed_parameters() + NumOptionalParameters();
}

intptr_t Function::NumImplicitParameters() const {
  const FunctionLayout::Kind k = kind();
  if (k == FunctionLayout::kConstructor) {
    // Type arguments for factory; instance for generative constructor.
    return 1;
  }
  if ((k == FunctionLayout::kClosureFunction) ||
      (k == FunctionLayout::kImplicitClosureFunction) ||
      (k == FunctionLayout::kSignatureFunction) ||
      (k == FunctionLayout::kFfiTrampoline)) {
    return 1;  // Closure object.
  }
  if (!is_static()) {
    // Closure functions defined inside instance (i.e. non-static) functions are
    // marked as non-static, but they do not have a receiver.
    // Closures are handled above.
    ASSERT((k != FunctionLayout::kClosureFunction) &&
           (k != FunctionLayout::kImplicitClosureFunction) &&
           (k != FunctionLayout::kSignatureFunction));
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
      Utils::SNPrint(message_buffer, kMessageBufferSize,
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
      Utils::SNPrint(message_buffer, kMessageBufferSize,
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
      Utils::SNPrint(message_buffer, kMessageBufferSize,
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
      Utils::SNPrint(message_buffer, kMessageBufferSize,
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
  const Array& args_desc_array = Array::Handle(ArgumentsDescriptor::NewBoxed(
      num_type_arguments, num_arguments, argument_names, Heap::kNew));
  ArgumentsDescriptor args_desc(args_desc_array);
  return AreValidArguments(args_desc, error_message);
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
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  String& argument_name = String::Handle(zone);
  String& parameter_name = String::Handle(zone);
  const intptr_t num_positional_args = num_arguments - num_named_arguments;
  const intptr_t num_parameters = NumParameters();
  for (intptr_t i = 0; i < num_named_arguments; i++) {
    argument_name = args_desc.NameAt(i);
    ASSERT(argument_name.IsSymbol());
    bool found = false;
    for (intptr_t j = num_positional_args; j < num_parameters; j++) {
      parameter_name = ParameterNameAt(j);
      ASSERT(parameter_name.IsSymbol());
      if (argument_name.Equals(parameter_name)) {
        found = true;
        break;
      }
    }
    if (!found) {
      if (error_message != nullptr) {
        const intptr_t kMessageBufferSize = 64;
        char message_buffer[kMessageBufferSize];
        Utils::SNPrint(message_buffer, kMessageBufferSize,
                       "no optional formal parameter named '%s'",
                       argument_name.ToCString());
        *error_message = String::New(message_buffer);
      }
      return false;
    }
  }
  if (isolate->use_strict_null_safety_checks()) {
    // Verify that all required named parameters are filled.
    for (intptr_t j = num_parameters - NumOptionalNamedParameters();
         j < num_parameters; j++) {
      if (IsRequiredAt(j)) {
        parameter_name = ParameterNameAt(j);
        ASSERT(parameter_name.IsSymbol());
        bool found = false;
        for (intptr_t i = 0; i < num_named_arguments; i++) {
          argument_name = args_desc.NameAt(i);
          ASSERT(argument_name.IsSymbol());
          if (argument_name.Equals(parameter_name)) {
            found = true;
            break;
          }
        }
        if (!found) {
          if (error_message != nullptr) {
            const intptr_t kMessageBufferSize = 64;
            char message_buffer[kMessageBufferSize];
            Utils::SNPrint(message_buffer, kMessageBufferSize,
                           "missing required named parameter '%s'",
                           parameter_name.ToCString());
            *error_message = String::New(message_buffer);
          }
          return false;
        }
      }
    }
  }
  return true;
}

// Retrieves the function type arguments, if any. This could be explicitly
// passed type from the arguments array, delayed type arguments in closures,
// or instantiated bounds for the type parameters if no other source for
// function type arguments are found.
static TypeArgumentsPtr RetrieveFunctionTypeArguments(
    Thread* thread,
    Zone* zone,
    const Function& function,
    const Instance& receiver,
    const TypeArguments& instantiator_type_args,
    const TypeArguments& type_params,
    const Array& args,
    const ArgumentsDescriptor& args_desc) {
  ASSERT(!function.IsNull());

  const intptr_t kNumCurrentTypeArgs = function.NumTypeParameters(thread);
  const intptr_t kNumParentTypeArgs = function.NumParentTypeParameters();
  const intptr_t kNumTypeArgs = kNumCurrentTypeArgs + kNumParentTypeArgs;
  // Non-generic functions don't receive type arguments.
  if (kNumTypeArgs == 0) return Object::empty_type_arguments().raw();
  // Closure functions require that the receiver be provided (and is a closure).
  ASSERT(!function.IsClosureFunction() || receiver.IsClosure());

  // Only closure functions should have possibly generic parents.
  ASSERT(function.IsClosureFunction() || kNumParentTypeArgs == 0);
  const auto& parent_type_args =
      function.IsClosureFunction()
          ? TypeArguments::Handle(
                zone, Closure::Cast(receiver).function_type_arguments())
          : Object::empty_type_arguments();
  // We don't try to instantiate the parent type parameters to their bounds
  // if not provided or check any closed-over type arguments against the parent
  // type parameter bounds (since they have been type checked already).
  if (kNumCurrentTypeArgs == 0) return parent_type_args.raw();

  auto& function_type_args = TypeArguments::Handle(zone);
  // First check for delayed type arguments before using either provided or
  // default type arguments.
  bool has_delayed_type_args = false;
  if (function.IsClosureFunction()) {
    const auto& closure = Closure::Cast(receiver);
    function_type_args = closure.delayed_type_arguments();
    has_delayed_type_args =
        function_type_args.raw() != Object::empty_type_arguments().raw();
  }

  if (args_desc.TypeArgsLen() > 0) {
    // We should never end up here when the receiver is a closure with delayed
    // type arguments unless this dynamically called closure function was
    // retrieved directly from the closure instead of going through
    // DartEntry::ResolveCallable, which appropriately checks for this case.
    ASSERT(!has_delayed_type_args);
    function_type_args ^= args.At(0);
  } else if (!has_delayed_type_args) {
    // We have no explicitly provided function type arguments, so instantiate
    // the type parameters to bounds or replace as appropriate.
    Function::DefaultTypeArgumentsKind kind;
    function_type_args = function.InstantiateToBounds(thread, &kind);
    switch (kind) {
      case Function::DefaultTypeArgumentsKind::kInvalid:
        // We shouldn't hit the invalid case.
        UNREACHABLE();
        break;
      case Function::DefaultTypeArgumentsKind::kIsInstantiated:
        // Nothing left to do.
        break;
      case Function::DefaultTypeArgumentsKind::kNeedsInstantiation:
        function_type_args = function_type_args.InstantiateAndCanonicalizeFrom(
            instantiator_type_args, parent_type_args);
        break;
      case Function::DefaultTypeArgumentsKind::kSharesInstantiatorTypeArguments:
        function_type_args = instantiator_type_args.raw();
        break;
      case Function::DefaultTypeArgumentsKind::kSharesFunctionTypeArguments:
        function_type_args = parent_type_args.raw();
        break;
    }
  }

  return function_type_args.Prepend(zone, parent_type_args, kNumParentTypeArgs,
                                    kNumTypeArgs);
}

// Retrieves the instantiator type arguments, if any, from the receiver.
static TypeArgumentsPtr RetrieveInstantiatorTypeArguments(
    Zone* zone,
    const Function& function,
    const Instance& receiver) {
  if (function.IsClosureFunction()) {
    ASSERT(receiver.IsClosure());
    const auto& closure = Closure::Cast(receiver);
    return closure.instantiator_type_arguments();
  }
  if (!receiver.IsNull()) {
    const auto& cls = Class::Handle(zone, receiver.clazz());
    if (cls.NumTypeArguments() > 0) {
      return receiver.GetTypeArguments();
    }
  }
  return Object::empty_type_arguments().raw();
}

ObjectPtr Function::DoArgumentTypesMatch(
    const Array& args,
    const ArgumentsDescriptor& args_desc) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  auto& receiver = Instance::Handle(zone);
  if (IsClosureFunction() || HasThisParameter()) {
    receiver ^= args.At(args_desc.FirstArgIndex());
  }
  const auto& instantiator_type_arguments = TypeArguments::Handle(
      zone, RetrieveInstantiatorTypeArguments(zone, *this, receiver));
  return Function::DoArgumentTypesMatch(args, args_desc,
                                        instantiator_type_arguments);
}

ObjectPtr Function::DoArgumentTypesMatch(
    const Array& args,
    const ArgumentsDescriptor& args_desc,
    const TypeArguments& instantiator_type_arguments) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  auto& receiver = Instance::Handle(zone);
  if (IsClosureFunction() || HasThisParameter()) {
    receiver ^= args.At(args_desc.FirstArgIndex());
  }

  const auto& params = TypeArguments::Handle(zone, type_parameters());
  const auto& function_type_arguments = TypeArguments::Handle(
      zone, RetrieveFunctionTypeArguments(thread, zone, *this, receiver,
                                          instantiator_type_arguments, params,
                                          args, args_desc));
  return Function::DoArgumentTypesMatch(
      args, args_desc, instantiator_type_arguments, function_type_arguments);
}

ObjectPtr Function::DoArgumentTypesMatch(
    const Array& args,
    const ArgumentsDescriptor& args_desc,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  // Perform any non-covariant bounds checks on the provided function type
  // arguments to make sure they are appropriate subtypes of the bounds.
  const intptr_t kNumLocalTypeArgs = NumTypeParameters(thread);
  if (kNumLocalTypeArgs > 0) {
    ASSERT(function_type_arguments.HasCount(kNumLocalTypeArgs +
                                            NumParentTypeParameters()));
    const auto& params = TypeArguments::Handle(zone, type_parameters());
    auto& parameter = TypeParameter::Handle(zone);
    auto& type = AbstractType::Handle(zone);
    auto& bound = AbstractType::Handle(zone);
    for (intptr_t i = 0; i < kNumLocalTypeArgs; i++) {
      parameter ^= params.TypeAt(i);
      type = parameter.raw();
      bound = parameter.bound();
      // Only perform non-covariant checks where the bound is not the top type.
      if (parameter.IsGenericCovariantImpl() || bound.IsTopTypeForSubtyping()) {
        continue;
      }
      if (!AbstractType::InstantiateAndTestSubtype(&type, &bound,
                                                   instantiator_type_arguments,
                                                   function_type_arguments)) {
        const auto& name = String::Handle(zone, parameter.name());
        return Error::RawCast(ThrowTypeError(token_pos(), type, bound, name));
      }
    }
  } else {
    ASSERT(function_type_arguments.HasCount(NumParentTypeParameters()));
  }

  AbstractType& type = AbstractType::Handle(zone);
  Instance& argument = Instance::Handle(zone);

  auto check_argument = [](const Instance& argument, const AbstractType& type,
                           const TypeArguments& instantiator_type_args,
                           const TypeArguments& function_type_args) -> bool {
    // If the argument type is the top type, no need to check.
    if (type.IsTopTypeForSubtyping()) return true;
    if (argument.IsNull()) {
      return Instance::NullIsAssignableTo(type);
    }
    return argument.IsAssignableTo(type, instantiator_type_args,
                                   function_type_args);
  };

  // Check types of the provided arguments against the expected parameter types.
  const intptr_t arg_offset = args_desc.FirstArgIndex();
  // Only check explicit arguments.
  const intptr_t arg_start = arg_offset + NumImplicitParameters();
  const intptr_t end_positional_args = arg_offset + args_desc.PositionalCount();
  for (intptr_t arg_index = arg_start; arg_index < end_positional_args;
       ++arg_index) {
    argument ^= args.At(arg_index);
    // Adjust for type arguments when they're present.
    const intptr_t param_index = arg_index - arg_offset;
    type = ParameterTypeAt(param_index);

    if (!check_argument(argument, type, instantiator_type_arguments,
                        function_type_arguments)) {
      auto& name = String::Handle(zone, ParameterNameAt(param_index));
      return ThrowTypeError(token_pos(), argument, type, name);
    }
  }

  const intptr_t num_named_arguments = args_desc.NamedCount();
  if (num_named_arguments == 0) {
    return Error::null();
  }

  const int num_parameters = NumParameters();
  const int num_fixed_params = num_fixed_parameters();

  String& argument_name = String::Handle(zone);
  String& parameter_name = String::Handle(zone);

  // Check types of named arguments against expected parameter type.
  for (intptr_t named_index = 0; named_index < num_named_arguments;
       named_index++) {
    argument_name = args_desc.NameAt(named_index);
    ASSERT(argument_name.IsSymbol());
    argument ^= args.At(arg_offset + args_desc.PositionAt(named_index));

    // Try to find the named parameter that matches the provided argument.
    // Even when annotated with @required, named parameters are still stored
    // as if they were optional and so come after the fixed parameters.
    // Currently O(n^2) as there's no guarantee from either the CFE or the
    // VM that named parameters and named arguments are sorted in the same way.
    intptr_t param_index = num_fixed_params;
    for (; param_index < num_parameters; param_index++) {
      parameter_name = ParameterNameAt(param_index);
      ASSERT(parameter_name.IsSymbol());

      if (!parameter_name.Equals(argument_name)) continue;

      type = ParameterTypeAt(param_index);
      if (!check_argument(argument, type, instantiator_type_arguments,
                          function_type_arguments)) {
        auto& name = String::Handle(zone, ParameterNameAt(param_index));
        return ThrowTypeError(token_pos(), argument, type, name);
      }
      break;
    }
    // Only should fail if AreValidArguments returns a false positive.
    ASSERT(param_index < num_parameters);
  }
  return Error::null();
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
  Zone* zone = Thread::Current()->zone();
  const char* name = String::Handle(zone, function.name()).ToCString();
  const char* function_format = (reserve_len == 0) ? "%s" : "%s_";
  reserve_len += Utils::SNPrint(NULL, 0, function_format, name);
  const Function& parent = Function::Handle(zone, function.parent_function());
  intptr_t written = 0;
  if (parent.IsNull()) {
    const Class& function_class = Class::Handle(zone, function.Owner());
    ASSERT(!function_class.IsNull());
    const char* class_name =
        String::Handle(zone, function_class.Name()).ToCString();
    ASSERT(class_name != NULL);
    const char* library_name = NULL;
    const char* lib_class_format = NULL;
    if (with_lib) {
      const Library& library = Library::Handle(zone, function_class.library());
      ASSERT(!library.IsNull());
      switch (lib_kind) {
        case kQualifiedFunctionLibKindLibUrl:
          library_name = String::Handle(zone, library.url()).ToCString();
          break;
        case kQualifiedFunctionLibKindLibName:
          library_name = String::Handle(zone, library.name()).ToCString();
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
        Utils::SNPrint(NULL, 0, lib_class_format, library_name, class_name);
    ASSERT(chars != NULL);
    *chars = zone->Alloc<char>(reserve_len + 1);
    written = Utils::SNPrint(*chars, reserve_len + 1, lib_class_format,
                             library_name, class_name);
  } else {
    written = ConstructFunctionFullyQualifiedCString(parent, chars, reserve_len,
                                                     with_lib, lib_kind);
  }
  ASSERT(*chars != NULL);
  char* next = *chars + written;
  written += Utils::SNPrint(next, reserve_len + 1, function_format, name);
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

FunctionPtr Function::InstantiateSignatureFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    intptr_t num_free_fun_type_params,
    Heap::Space space) const {
  Zone* zone = Thread::Current()->zone();
  const Object& owner = Object::Handle(zone, RawOwner());
  // Note that parent pointers in newly instantiated signatures still points to
  // the original uninstantiated parent signatures. That is not a problem.
  const Function& parent = Function::Handle(zone, parent_function());
  const intptr_t num_parent_type_params = NumParentTypeParameters();

  // See the comment on kCurrentAndEnclosingFree to understand why we don't
  // adjust 'num_free_fun_type_params' downward in this case.
  bool delete_type_parameters = false;
  if (num_free_fun_type_params == kCurrentAndEnclosingFree) {
    num_free_fun_type_params = kAllFree;
    delete_type_parameters = true;
  } else {
    ASSERT(!HasInstantiatedSignature(kAny, num_free_fun_type_params));

    // A generic typedef may declare a non-generic function type and get
    // instantiated with unrelated function type parameters. In that case, its
    // signature is still uninstantiated, because these type parameters are
    // free (they are not declared by the typedef).
    // For that reason, we only adjust num_free_fun_type_params if this
    // signature is generic or has a generic parent.
    if (IsGeneric() || HasGenericParent()) {
      // We only consider the function type parameters declared by the parents
      // of this signature function as free.
      if (num_parent_type_params < num_free_fun_type_params) {
        num_free_fun_type_params = num_parent_type_params;
      }
    }
  }

  Function& sig = Function::Handle(Function::NewSignatureFunction(
      owner, parent, TokenPosition::kNoSource, space));
  const intptr_t offset =
      sig.NumParentTypeParameters() - num_parent_type_params;
  AbstractType& type = AbstractType::Handle(zone);

  // Copy the type parameters and instantiate their bounds (if necessary).
  if (!delete_type_parameters) {
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, type_parameters());
    if (!type_params.IsNull()) {
      TypeArguments& instantiated_type_params = TypeArguments::Handle(zone);
      TypeParameter& type_param = TypeParameter::Handle(zone);
      const Class& null_class = Class::Handle(zone);
      String& param_name = String::Handle(zone);
      for (intptr_t i = 0; i < type_params.Length(); ++i) {
        type_param ^= type_params.TypeAt(i);
        ASSERT(type_param.index() == num_parent_type_params + i);
        type = type_param.bound();
        if (!type.IsInstantiated(kAny, num_free_fun_type_params)) {
          type = type.InstantiateFrom(instantiator_type_arguments,
                                      function_type_arguments,
                                      num_free_fun_type_params, space);
          // A returned null type indicates a failed instantiation in dead code
          // that must be propagated up to the caller, the optimizing compiler.
          if (type.IsNull()) {
            return Function::null();
          }
        }
        if (offset > 0 || type.raw() != type_param.bound()) {
          param_name = type_param.name();
          ASSERT(type_param.IsFunctionTypeParameter());
          ASSERT(type_param.IsFinalized());
          ASSERT(type_param.IsCanonical());
          type_param = TypeParameter::New(
              null_class, sig, type_param.index() + offset, param_name, type,
              type_param.IsGenericCovariantImpl(), type_param.nullability(),
              type_param.token_pos());
          type_param.SetIsFinalized();
          type_param.SetCanonical();
          type_param.SetDeclaration(true);
          if (instantiated_type_params.IsNull()) {
            instantiated_type_params = TypeArguments::New(type_params.Length());
            for (intptr_t j = 0; j < i; ++j) {
              type = type_params.TypeAt(j);
              instantiated_type_params.SetTypeAt(j, type);
            }
          }
          instantiated_type_params.SetTypeAt(i, type_param);
        } else if (!instantiated_type_params.IsNull()) {
          instantiated_type_params.SetTypeAt(i, type_param);
        }
      }
      sig.set_type_parameters(instantiated_type_params.IsNull()
                                  ? type_params
                                  : instantiated_type_params);
    }
  }

  type = result_type();
  if (!type.IsInstantiated(kAny, num_free_fun_type_params)) {
    type = type.InstantiateFrom(instantiator_type_arguments,
                                function_type_arguments,
                                num_free_fun_type_params, space);
    // A returned null type indicates a failed instantiation in dead code that
    // must be propagated up to the caller, the optimizing compiler.
    if (type.IsNull()) {
      return Function::null();
    }
  }
  sig.set_result_type(type);
  const intptr_t num_params = NumParameters();
  sig.set_num_fixed_parameters(num_fixed_parameters());
  sig.SetNumOptionalParameters(NumOptionalParameters(),
                               HasOptionalPositionalParameters());
  sig.set_parameter_types(Array::Handle(Array::New(num_params, space)));
  for (intptr_t i = 0; i < num_params; i++) {
    type = ParameterTypeAt(i);
    if (!type.IsInstantiated(kAny, num_free_fun_type_params)) {
      type = type.InstantiateFrom(instantiator_type_arguments,
                                  function_type_arguments,
                                  num_free_fun_type_params, space);
      // A returned null type indicates a failed instantiation in dead code that
      // must be propagated up to the caller, the optimizing compiler.
      if (type.IsNull()) {
        return Function::null();
      }
    }
    sig.SetParameterTypeAt(i, type);
  }
  sig.set_parameter_names(Array::Handle(zone, parameter_names()));

  if (delete_type_parameters) {
    ASSERT(sig.HasInstantiatedSignature(kFunctions));
  }
  return sig.raw();
}

// Checks if the type of the specified parameter of this function is a supertype
// of the type of the specified parameter of the other function (i.e. check
// parameter contravariance).
// Note that types marked as covariant are already dealt with in the front-end.
bool Function::IsContravariantParameter(intptr_t parameter_position,
                                        const Function& other,
                                        intptr_t other_parameter_position,
                                        Heap::Space space) const {
  const AbstractType& param_type =
      AbstractType::Handle(ParameterTypeAt(parameter_position));
  if (param_type.IsTopTypeForSubtyping()) {
    return true;
  }
  const AbstractType& other_param_type =
      AbstractType::Handle(other.ParameterTypeAt(other_parameter_position));
  return other_param_type.IsSubtypeOf(param_type, space);
}

bool Function::HasSameTypeParametersAndBounds(const Function& other,
                                              TypeEquality kind) const {
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
      if (kind == TypeEquality::kInSubtypeTest) {
        // Bounds that are mutual subtypes are considered equal.
        if (!bound.IsSubtypeOf(other_bound, Heap::kOld) ||
            !other_bound.IsSubtypeOf(bound, Heap::kOld)) {
          return false;
        }
      } else {
        if (!bound.IsEquivalent(other_bound, kind)) {
          return false;
        }
      }
    }
  }
  return true;
}

bool Function::IsSubtypeOf(const Function& other, Heap::Space space) const {
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
  // Check the type parameters and bounds of generic functions.
  if (!HasSameTypeParametersAndBounds(other, TypeEquality::kInSubtypeTest)) {
    return false;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  // Check the result type.
  const AbstractType& other_res_type =
      AbstractType::Handle(zone, other.result_type());
  // 'void Function()' is a subtype of 'Object Function()'.
  if (!other_res_type.IsTopTypeForSubtyping()) {
    const AbstractType& res_type = AbstractType::Handle(zone, result_type());
    if (!res_type.IsSubtypeOf(other_res_type, space)) {
      return false;
    }
  }
  // Check the types of fixed and optional positional parameters.
  for (intptr_t i = 0; i < (other_num_fixed_params - other_num_ignored_params +
                            other_num_opt_pos_params);
       i++) {
    if (!IsContravariantParameter(i + num_ignored_params, other,
                                  i + other_num_ignored_params, space)) {
      return false;
    }
  }
  // Check that for each optional named parameter of type T of the other
  // function type, there exists an optional named parameter of this function
  // type with an identical name and with a type S that is a supertype of T.
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
        if (!IsContravariantParameter(j, other, i, space)) {
          return false;
        }
        break;
      }
    }
    if (!found_param_name) {
      return false;
    }
  }
  if (isolate->use_strict_null_safety_checks()) {
    // Check that for each required named parameter in this function, there's a
    // corresponding required named parameter in the other function.
    String& param_name = other_param_name;
    for (intptr_t j = num_params - num_opt_named_params; j < num_params; j++) {
      if (IsRequiredAt(j)) {
        param_name = ParameterNameAt(j);
        ASSERT(param_name.IsSymbol());
        bool found = false;
        for (intptr_t i = other_num_fixed_params; i < other_num_params; i++) {
          ASSERT(String::Handle(zone, other.ParameterNameAt(i)).IsSymbol());
          if (other.ParameterNameAt(i) == param_name.raw()) {
            found = true;
            if (!other.IsRequiredAt(i)) {
              return false;
            }
          }
        }
        if (!found) {
          return false;
        }
      }
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

bool Function::IsImplicitStaticClosureFunction(FunctionPtr func) {
  NoSafepointScope no_safepoint;
  uint32_t kind_tag = func->ptr()->kind_tag_;
  return (KindBits::decode(kind_tag) ==
          FunctionLayout::kImplicitClosureFunction) &&
         StaticBit::decode(kind_tag);
}

FunctionPtr Function::New(Heap::Space space) {
  ASSERT(Object::function_class() != Class::null());
  ObjectPtr raw =
      Object::Allocate(Function::kClassId, Function::InstanceSize(), space);
  return static_cast<FunctionPtr>(raw);
}

FunctionPtr Function::New(const String& name,
                          FunctionLayout::Kind kind,
                          bool is_static,
                          bool is_const,
                          bool is_abstract,
                          bool is_external,
                          bool is_native,
                          const Object& owner,
                          TokenPosition token_pos,
                          Heap::Space space) {
  ASSERT(!owner.IsNull() || (kind == FunctionLayout::kSignatureFunction));
  const Function& result = Function::Handle(Function::New(space));
  result.set_kind_tag(0);
  result.set_parameter_types(Object::empty_array());
  result.set_parameter_names(Object::empty_array());
  result.set_name(name);
  result.set_kind_tag(0);  // Ensure determinism of uninitialized bits.
  result.set_kind(kind);
  result.set_recognized_kind(MethodRecognizer::kUnknown);
  result.set_modifier(FunctionLayout::kNoModifier);
  result.set_is_static(is_static);
  result.set_is_const(is_const);
  result.set_is_abstract(is_abstract);
  result.set_is_external(is_external);
  result.set_is_native(is_native);
  result.set_is_reflectable(true);  // Will be computed later.
  result.set_is_visible(true);      // Will be computed later.
  result.set_is_debuggable(true);   // Will be computed later.
  result.set_is_intrinsic(false);
  result.set_is_generated_body(false);
  result.set_has_pragma(false);
  result.set_is_polymorphic_target(false);
  result.set_is_synthetic(false);
  NOT_IN_PRECOMPILED(result.set_state_bits(0));
  result.set_owner(owner);
  NOT_IN_PRECOMPILED(result.set_token_pos(token_pos));
  NOT_IN_PRECOMPILED(result.set_end_token_pos(token_pos));
  result.set_num_fixed_parameters(0);
  result.SetNumOptionalParameters(0, false);
  NOT_IN_PRECOMPILED(result.set_usage_counter(0));
  NOT_IN_PRECOMPILED(result.set_deoptimization_counter(0));
  NOT_IN_PRECOMPILED(result.set_optimized_instruction_count(0));
  NOT_IN_PRECOMPILED(result.set_optimized_call_site_count(0));
  NOT_IN_PRECOMPILED(result.set_inlining_depth(0));
  NOT_IN_PRECOMPILED(result.set_kernel_offset(0));
  result.set_is_optimizable(is_native ? false : true);
  result.set_is_background_optimizable(is_native ? false : true);
  result.set_is_inlinable(true);
  result.reset_unboxed_parameters_and_return();
  result.SetInstructionsSafe(StubCode::LazyCompile());
  if (kind == FunctionLayout::kClosureFunction ||
      kind == FunctionLayout::kImplicitClosureFunction) {
    ASSERT(space == Heap::kOld);
    const ClosureData& data = ClosureData::Handle(ClosureData::New());
    result.set_data(data);
  } else if (kind == FunctionLayout::kSignatureFunction) {
    const SignatureData& data =
        SignatureData::Handle(SignatureData::New(space));
    result.set_data(data);
  } else if (kind == FunctionLayout::kFfiTrampoline) {
    const FfiTrampolineData& data =
        FfiTrampolineData::Handle(FfiTrampolineData::New());
    result.set_data(data);
  } else {
    // Functions other than signature functions have no reason to be allocated
    // in new space.
    ASSERT(space == Heap::kOld);
  }
  if (result.CachesDefaultTypeArguments()) {
    // Make sure the default type arguments are set consistently with the
    // function type parameters (currently null).
    result.set_default_type_arguments(Object::empty_type_arguments());
  }

  // Force-optimized functions are not debuggable because they cannot
  // deoptimize.
  if (result.ForceOptimize()) {
    result.set_is_debuggable(false);
  }

  return result.raw();
}

FunctionPtr Function::NewClosureFunctionWithKind(FunctionLayout::Kind kind,
                                                 const String& name,
                                                 const Function& parent,
                                                 TokenPosition token_pos,
                                                 const Object& owner) {
  ASSERT((kind == FunctionLayout::kClosureFunction) ||
         (kind == FunctionLayout::kImplicitClosureFunction));
  ASSERT(!parent.IsNull());
  ASSERT(!owner.IsNull());
  const Function& result = Function::Handle(
      Function::New(name, kind,
                    /* is_static = */ parent.is_static(),
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    /* is_external = */ false,
                    /* is_native = */ false, owner, token_pos));
  result.set_parent_function(parent);
  return result.raw();
}

FunctionPtr Function::NewClosureFunction(const String& name,
                                         const Function& parent,
                                         TokenPosition token_pos) {
  // Use the owner defining the parent function and not the class containing it.
  const Object& parent_owner = Object::Handle(parent.RawOwner());
  return NewClosureFunctionWithKind(FunctionLayout::kClosureFunction, name,
                                    parent, token_pos, parent_owner);
}

FunctionPtr Function::NewImplicitClosureFunction(const String& name,
                                                 const Function& parent,
                                                 TokenPosition token_pos) {
  // Use the owner defining the parent function and not the class containing it.
  const Object& parent_owner = Object::Handle(parent.RawOwner());
  return NewClosureFunctionWithKind(FunctionLayout::kImplicitClosureFunction,
                                    name, parent, token_pos, parent_owner);
}

FunctionPtr Function::NewSignatureFunction(const Object& owner,
                                           const Function& parent,
                                           TokenPosition token_pos,
                                           Heap::Space space) {
  const Function& result = Function::Handle(Function::New(
      Symbols::AnonymousSignature(), FunctionLayout::kSignatureFunction,
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

FunctionPtr Function::NewEvalFunction(const Class& owner,
                                      const Script& script,
                                      bool is_static) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Function& result = Function::Handle(
      zone,
      Function::New(String::Handle(Symbols::New(thread, ":Eval")),
                    FunctionLayout::kRegularFunction, is_static,
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

bool Function::SafeToClosurize() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  return HasImplicitClosureFunction();
#else
  return true;
#endif
}

bool Function::IsDynamicClosureCallDispatcher(Thread* thread) const {
  if (!IsInvokeFieldDispatcher()) return false;
  if (thread->isolate()->object_store()->closure_class() != Owner()) {
    return false;
  }
  const auto& handle = String::Handle(thread->zone(), name());
  return handle.Equals(Symbols::DynamicCall());
}

FunctionPtr Function::ImplicitClosureFunction() const {
  // Return the existing implicit closure function if any.
  if (implicit_closure_function() != Function::null()) {
    return implicit_closure_function();
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  // In AOT mode all implicit closures are pre-created.
  FATAL("Cannot create implicit closure in AOT!");
  return Function::null();
#else
  ASSERT(!IsSignatureFunction() && !IsClosureFunction());

  Thread* thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  if (implicit_closure_function() != Function::null()) {
    return implicit_closure_function();
  }

  // Create closure function.
  Zone* zone = thread->zone();
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
  auto& type_args_handle = TypeArguments::Handle(zone, type_parameters());
  // This function cannot be local, therefore it has no generic parent.
  // Its implicit closure function therefore has no generic parent function
  // either. That is why it is safe to simply copy the type parameters.
  closure_function.set_type_parameters(type_args_handle);
  closure_function.UpdateCachedDefaultTypeArguments(thread);

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
  closure_function.CreateNameArrayIncludingFlags(Heap::kOld);
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
    if (IsRequiredAt(has_receiver - kClosure + i)) {
      closure_function.SetIsRequiredAt(i);
    }
  }
  closure_function.TruncateUnusedParameterFlags();
  closure_function.InheritKernelOffsetFrom(*this);

  // Change covariant parameter types to either Object? for an opted-in implicit
  // closure or to Object* for a legacy implicit closure.
  if (!is_static()) {
    BitVector is_covariant(zone, NumParameters());
    BitVector is_generic_covariant_impl(zone, NumParameters());
    kernel::ReadParameterCovariance(*this, &is_covariant,
                                    &is_generic_covariant_impl);

    Type& object_type = Type::Handle(zone, Type::ObjectType());
    ObjectStore* object_store = Isolate::Current()->object_store();
    object_type = nnbd_mode() == NNBDMode::kOptedInLib
                      ? object_store->nullable_object_type()
                      : object_store->legacy_object_type();
    for (intptr_t i = kClosure; i < num_params; ++i) {
      const intptr_t original_param_index = has_receiver - kClosure + i;
      if (is_covariant.Contains(original_param_index) ||
          is_generic_covariant_impl.Contains(original_param_index)) {
        closure_function.SetParameterTypeAt(i, object_type);
      }
    }
  }
  const Type& signature_type =
      Type::Handle(zone, closure_function.SignatureType());
  if (!signature_type.IsFinalized()) {
    ClassFinalizer::FinalizeType(signature_type);
  }
  set_implicit_closure_function(closure_function);
  ASSERT(closure_function.IsImplicitClosureFunction());
  return closure_function.raw();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

void Function::DropUncompiledImplicitClosureFunction() const {
  if (implicit_closure_function() != Function::null()) {
    const Function& func = Function::Handle(implicit_closure_function());
    if (!func.HasCode()) {
      set_implicit_closure_function(Function::Handle());
    }
  }
}

StringPtr Function::Signature() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintSignature(kInternalName, &printer);
  return Symbols::New(thread, printer.buffer());
}

StringPtr Function::UserVisibleSignature() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintSignature(kUserVisibleName, &printer);
  return Symbols::New(thread, printer.buffer());
}

void Function::PrintSignatureParameters(Thread* thread,
                                        Zone* zone,
                                        NameVisibility name_visibility,
                                        BaseTextBuffer* printer) const {
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
    param_type.PrintName(name_visibility, printer);
    if (i != (num_params - 1)) {
      printer->AddString(", ");
    }
    i++;
  }
  if (num_opt_params > 0) {
    if (num_opt_pos_params > 0) {
      printer->AddString("[");
    } else {
      printer->AddString("{");
    }
    for (intptr_t i = num_fixed_params; i < num_params; i++) {
      if (num_opt_named_params > 0 && IsRequiredAt(i)) {
        printer->AddString("required ");
      }
      param_type = ParameterTypeAt(i);
      ASSERT(!param_type.IsNull());
      param_type.PrintName(name_visibility, printer);
      // The parameter name of an optional positional parameter does not need
      // to be part of the signature, since it is not used.
      if (num_opt_named_params > 0) {
        name = ParameterNameAt(i);
        printer->AddString(" ");
        printer->AddString(name.ToCString());
      }
      if (i != (num_params - 1)) {
        printer->AddString(", ");
      }
    }
    if (num_opt_pos_params > 0) {
      printer->AddString("]");
    } else {
      printer->AddString("}");
    }
  }
}

InstancePtr Function::ImplicitStaticClosure() const {
  ASSERT(IsImplicitStaticClosureFunction());
  if (implicit_static_closure() != Instance::null()) {
    return implicit_static_closure();
  }

  auto thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  if (implicit_static_closure() != Instance::null()) {
    return implicit_static_closure();
  }

  Zone* zone = thread->zone();
  const auto& null_context = Context::Handle(zone);
  const auto& closure =
      Instance::Handle(zone, Closure::New(Object::null_type_arguments(),
                                          Object::null_type_arguments(), *this,
                                          null_context, Heap::kOld));
  set_implicit_static_closure(closure);
  return implicit_static_closure();
}

InstancePtr Function::ImplicitInstanceClosure(const Instance& receiver) const {
  ASSERT(IsImplicitClosureFunction());
  Zone* zone = Thread::Current()->zone();
  const Context& context = Context::Handle(zone, Context::New(1));
  context.SetAt(0, receiver);
  TypeArguments& instantiator_type_arguments = TypeArguments::Handle(zone);
  if (!HasInstantiatedSignature(kCurrentClass)) {
    instantiator_type_arguments = receiver.GetTypeArguments();
  }
  ASSERT(HasInstantiatedSignature(kFunctions));  // No generic parent function.
  return Closure::New(instantiator_type_arguments,
                      Object::null_type_arguments(), *this, context);
}

FunctionPtr Function::ImplicitClosureTarget(Zone* zone) const {
  const auto& parent = Function::Handle(zone, parent_function());
  const auto& func_name = String::Handle(zone, parent.name());
  const auto& owner = Class::Handle(zone, parent.Owner());
  Thread* thread = Thread::Current();
  const auto& error = owner.EnsureIsFinalized(thread);
  ASSERT(error == Error::null());
  auto& target =
      Function::Handle(zone, Resolver::ResolveFunction(zone, owner, func_name));

  if (!target.IsNull() && (target.raw() != parent.raw())) {
    DEBUG_ASSERT(Isolate::Current()->HasAttemptedReload());
    if ((target.is_static() != parent.is_static()) ||
        (target.kind() != parent.kind())) {
      target = Function::null();
    }
  }

  return target.raw();
}

intptr_t Function::ComputeClosureHash() const {
  ASSERT(IsClosureFunction());
  const Class& cls = Class::Handle(Owner());
  uintptr_t result = String::Handle(name()).Hash();
  result += String::Handle(Signature()).Hash();
  result += String::Handle(cls.Name()).Hash();
  return result;
}

void Function::PrintSignature(NameVisibility name_visibility,
                              BaseTextBuffer* printer) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  String& name = String::Handle(zone);
  const TypeArguments& type_params =
      TypeArguments::Handle(zone, type_parameters());
  if (!type_params.IsNull()) {
    const intptr_t num_type_params = type_params.Length();
    ASSERT(num_type_params > 0);
    TypeParameter& type_param = TypeParameter::Handle(zone);
    AbstractType& bound = AbstractType::Handle(zone);
    printer->AddString("<");
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      name = type_param.name();
      printer->AddString(name.ToCString());
      bound = type_param.bound();
      // Do not print default bound or non-nullable Object bound in weak mode.
      if (!bound.IsNull() &&
          (!bound.IsObjectType() ||
           (isolate->null_safety() && bound.IsNonNullable()))) {
        printer->AddString(" extends ");
        bound.PrintName(name_visibility, printer);
      }
      if (i < num_type_params - 1) {
        printer->AddString(", ");
      }
    }
    printer->AddString(">");
  }
  printer->AddString("(");
  PrintSignatureParameters(thread, zone, name_visibility, printer);
  printer->AddString(") => ");
  const AbstractType& res_type = AbstractType::Handle(zone, result_type());
  res_type.PrintName(name_visibility, printer);
}

bool Function::HasInstantiatedSignature(Genericity genericity,
                                        intptr_t num_free_fun_type_params,
                                        TrailPtr trail) const {
  if (num_free_fun_type_params == kCurrentAndEnclosingFree) {
    num_free_fun_type_params = kAllFree;
  } else if (genericity != kCurrentClass) {
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
  TypeArguments& type_params = TypeArguments::Handle(type_parameters());
  TypeParameter& type_param = TypeParameter::Handle();
  for (intptr_t i = 0; i < type_params.Length(); ++i) {
    type_param ^= type_params.TypeAt(i);
    type = type_param.bound();
    if (!type.IsInstantiated(genericity, num_free_fun_type_params, trail)) {
      return false;
    }
  }
  return true;
}

ClassPtr Function::Owner() const {
  if (raw_ptr()->owner() == Object::null()) {
    ASSERT(IsSignatureFunction());
    return Class::null();
  }
  if (raw_ptr()->owner()->IsClass()) {
    return Class::RawCast(raw_ptr()->owner());
  }
  const Object& obj = Object::Handle(raw_ptr()->owner());
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).patched_class();
}

ClassPtr Function::origin() const {
  if (raw_ptr()->owner() == Object::null()) {
    ASSERT(IsSignatureFunction());
    return Class::null();
  }
  if (raw_ptr()->owner()->IsClass()) {
    return Class::RawCast(raw_ptr()->owner());
  }
  const Object& obj = Object::Handle(raw_ptr()->owner());
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).origin_class();
}

void Function::InheritKernelOffsetFrom(const Function& src) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  StoreNonPointer(&raw_ptr()->kernel_offset_, src.raw_ptr()->kernel_offset_);
#endif
}

void Function::InheritKernelOffsetFrom(const Field& src) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  set_kernel_offset(src.kernel_offset());
#endif
}

void Function::SetKernelDataAndScript(const Script& script,
                                      const ExternalTypedData& data,
                                      intptr_t offset) const {
  Array& data_field = Array::Handle(Array::New(3));
  data_field.SetAt(0, script);
  data_field.SetAt(1, data);
  data_field.SetAt(2, Smi::Handle(Smi::New(offset)));
  set_data(data_field);
}

ScriptPtr Function::script() const {
  // NOTE(turnidge): If you update this function, you probably want to
  // update Class::PatchFieldsAndFunctions() at the same time.
  const Object& data = Object::Handle(raw_ptr()->data());
  if (IsDynamicInvocationForwarder()) {
    const auto& forwarding_target = Function::Handle(ForwardingTarget());
    return forwarding_target.script();
  }
  if (IsImplicitGetterOrSetter()) {
    const auto& field = Field::Handle(accessor_field());
    return field.Script();
  }
  if (data.IsArray()) {
    Object& script = Object::Handle(Array::Cast(data).At(0));
    if (script.IsScript()) {
      return Script::Cast(script).raw();
    }
  }
  if (token_pos() == TokenPosition::kMinSource) {
    // Testing for position 0 is an optimization that relies on temporary
    // eval functions having token position 0.
    const Script& script = Script::Handle(eval_script());
    if (!script.IsNull()) {
      return script.raw();
    }
  }
  const Object& obj = Object::Handle(raw_ptr()->owner());
  if (obj.IsPatchClass()) {
    return PatchClass::Cast(obj).script();
  }
  if (IsClosureFunction()) {
    return Function::Handle(parent_function()).script();
  }
  if (obj.IsNull()) {
    ASSERT(IsSignatureFunction());
    return Script::null();
  }
  ASSERT(obj.IsClass());
  return Class::Cast(obj).script();
}

ExternalTypedDataPtr Function::KernelData() const {
  Object& data = Object::Handle(raw_ptr()->data());
  if (data.IsArray()) {
    Object& script = Object::Handle(Array::Cast(data).At(0));
    if (script.IsScript()) {
      return ExternalTypedData::RawCast(Array::Cast(data).At(1));
    }
  }
  if (IsClosureFunction()) {
    Function& parent = Function::Handle(parent_function());
    ASSERT(!parent.IsNull());
    return parent.KernelData();
  }

  const Object& obj = Object::Handle(raw_ptr()->owner());
  if (obj.IsClass()) {
    Library& lib = Library::Handle(Class::Cast(obj).library());
    return lib.kernel_data();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).library_kernel_data();
}

intptr_t Function::KernelDataProgramOffset() const {
  if (IsNoSuchMethodDispatcher() || IsInvokeFieldDispatcher() ||
      IsFfiTrampoline()) {
    return 0;
  }
  Object& data = Object::Handle(raw_ptr()->data());
  if (data.IsArray()) {
    Object& script = Object::Handle(Array::Cast(data).At(0));
    if (script.IsScript()) {
      return Smi::Value(Smi::RawCast(Array::Cast(data).At(2)));
    }
  }
  if (IsClosureFunction()) {
    Function& parent = Function::Handle(parent_function());
    ASSERT(!parent.IsNull());
    return parent.KernelDataProgramOffset();
  }

  const Object& obj = Object::Handle(raw_ptr()->owner());
  if (obj.IsClass()) {
    Library& lib = Library::Handle(Class::Cast(obj).library());
    return lib.kernel_offset();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).library_kernel_offset();
}

bool Function::HasOptimizedCode() const {
  return HasCode() && Code::Handle(CurrentCode()).is_optimized();
}

const char* Function::NameCString(NameVisibility name_visibility) const {
  switch (name_visibility) {
    case kInternalName:
      return String::Handle(name()).ToCString();
    case kScrubbedName:
    case kUserVisibleName:
      return UserVisibleNameCString();
  }
  UNREACHABLE();
  return nullptr;
}

const char* Function::UserVisibleNameCString() const {
  if (FLAG_show_internal_names) {
    return String::Handle(name()).ToCString();
  }
  return String::ScrubName(String::Handle(name()), is_extension_member());
}

StringPtr Function::UserVisibleName() const {
  if (FLAG_show_internal_names) {
    return name();
  }
  return Symbols::New(
      Thread::Current(),
      String::ScrubName(String::Handle(name()), is_extension_member()));
}

StringPtr Function::QualifiedScrubbedName() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintName(NameFormattingParams(kScrubbedName), &printer);
  return Symbols::New(thread, printer.buffer());
}

StringPtr Function::QualifiedUserVisibleName() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintName(NameFormattingParams(kUserVisibleName), &printer);
  return Symbols::New(thread, printer.buffer());
}

const char* Function::QualifiedUserVisibleNameCString() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintName(NameFormattingParams(kUserVisibleName), &printer);
  return printer.buffer();
}

void Function::PrintName(const NameFormattingParams& params,
                         BaseTextBuffer* printer) const {
  // If |this| is the generated asynchronous body closure, use the
  // name of the parent function.
  Function& fun = Function::Handle(raw());

  if (params.disambiguate_names) {
    if (fun.IsInvokeFieldDispatcher()) {
      printer->AddString("[invoke-field] ");
    }
    if (fun.IsImplicitClosureFunction()) {
      printer->AddString("[tear-off] ");
    }
    if (fun.IsMethodExtractor()) {
      printer->AddString("[tear-off-extractor] ");
    }
  }

  if (fun.IsNonImplicitClosureFunction()) {
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
  if (IsClosureFunction()) {
    if (fun.IsLocalFunction() && !fun.IsImplicitClosureFunction()) {
      Function& parent = Function::Handle(fun.parent_function());
      if (parent.IsAsyncClosure() || parent.IsSyncGenClosureMaker() ||
          parent.IsAsyncGenClosure()) {
        // Skip the closure and use the real function name found in
        // the parent.
        parent = parent.parent_function();
      }
      if (params.include_parent_name) {
        parent.PrintName(params, printer);
        // A function's scrubbed name and its user visible name are identical.
        printer->AddString(".");
      }
      if (params.disambiguate_names &&
          fun.name() == Symbols::AnonymousClosure().raw()) {
        printer->Printf("<anonymous closure @%" Pd ">", fun.token_pos().Pos());
      } else {
        printer->AddString(fun.NameCString(params.name_visibility));
      }
      // If we skipped rewritten async/async*/sync* body then append a suffix
      // to the end of the name.
      if (fun.raw() != raw() && params.disambiguate_names) {
        printer->AddString("{body}");
      }
      return;
    }
  }

  if (fun.kind() == FunctionLayout::kConstructor) {
    printer->AddString("new ");
  } else if (params.include_class_name) {
    const Class& cls = Class::Handle(Owner());
    if (!cls.IsTopLevel()) {
      const Class& mixin = Class::Handle(cls.Mixin());
      printer->AddString(params.name_visibility == kUserVisibleName
                             ? mixin.UserVisibleNameCString()
                             : cls.NameCString(params.name_visibility));
      printer->AddString(".");
    }
  }

  printer->AddString(fun.NameCString(params.name_visibility));

  // If we skipped rewritten async/async*/sync* body then append a suffix
  // to the end of the name.
  if (fun.raw() != raw() && params.disambiguate_names) {
    printer->AddString("{body}");
  }

  // Field dispatchers are specialized for an argument descriptor so there
  // might be multiples of them with the same name but different argument
  // descriptors. Add a suffix to disambiguate.
  if (params.disambiguate_names && fun.IsInvokeFieldDispatcher()) {
    printer->AddString(" ");
    if (NumTypeParameters() != 0) {
      printer->Printf("<%" Pd ">", fun.NumTypeParameters());
    }
    printer->AddString("(");
    printer->Printf("%" Pd "", fun.num_fixed_parameters());
    if (fun.NumOptionalPositionalParameters() != 0) {
      printer->Printf(" [%" Pd "]", fun.NumOptionalPositionalParameters());
    }
    if (fun.NumOptionalNamedParameters() != 0) {
      printer->AddString(" {");
      String& name = String::Handle();
      for (intptr_t i = 0; i < fun.NumOptionalNamedParameters(); i++) {
        name = fun.ParameterNameAt(fun.num_fixed_parameters() + i);
        printer->Printf("%s%s", i > 0 ? ", " : "", name.ToCString());
      }
      printer->AddString("}");
    }
    printer->AddString(")");
  }
}

StringPtr Function::GetSource() const {
  if (IsImplicitConstructor() || IsSignatureFunction() || is_synthetic()) {
    // We may need to handle more cases when the restrictions on mixins are
    // relaxed. In particular we might start associating some source with the
    // forwarding constructors when it becomes possible to specify a particular
    // constructor from the mixin to use.
    return String::null();
  }
  Zone* zone = Thread::Current()->zone();
  const Script& func_script = Script::Handle(zone, script());

  intptr_t from_line, from_col;
  if (!func_script.GetTokenLocation(token_pos(), &from_line, &from_col)) {
    return String::null();
  }
  intptr_t to_line, to_col;
  if (!func_script.GetTokenLocation(end_token_pos(), &to_line, &to_col)) {
    return String::null();
  }
  intptr_t to_length = func_script.GetTokenLength(end_token_pos());
  if (to_length < 0) {
    return String::null();
  }

  if (to_length == 1) {
    // Handle special cases for end tokens of closures (where we exclude the
    // last token):
    // (1) "foo(() => null, bar);": End token is `,', but we don't print it.
    // (2) "foo(() => null);": End token is ')`, but we don't print it.
    // (3) "var foo = () => null;": End token is `;', but in this case the
    // token semicolon belongs to the assignment so we skip it.
    const String& src = String::Handle(func_script.Source());
    if (src.IsNull() || src.Length() == 0) {
      return Symbols::OptimizedOut().raw();
    }
    uint16_t end_char = src.CharAt(end_token_pos().Pos());
    if ((end_char == ',') ||  // Case 1.
        (end_char == ')') ||  // Case 2.
        (end_char == ';' && String::Handle(zone, name())
                                .Equals("<anonymous closure>"))) {  // Case 3.
      to_length = 0;
    }
  }

  return func_script.GetSnippet(from_line, from_col, to_line,
                                to_col + to_length);
}

// Construct fingerprint from token stream. The token stream contains also
// arguments.
int32_t Function::SourceFingerprint() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  return kernel::KernelSourceFingerprintHelper::CalculateFunctionFingerprint(
      *this);
#else
  return 0;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

void Function::SaveICDataMap(
    const ZoneGrowableArray<const ICData*>& deopt_id_to_ic_data,
    const Array& edge_counters_array) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Compute number of ICData objects to save.
  // Store edge counter array in the first slot.
  intptr_t count = 1;
  for (intptr_t i = 0; i < deopt_id_to_ic_data.length(); i++) {
    if (deopt_id_to_ic_data[i] != NULL) {
      count++;
    }
  }
  const Array& array = Array::Handle(Array::New(count, Heap::kOld));
  count = 1;
  for (intptr_t i = 0; i < deopt_id_to_ic_data.length(); i++) {
    if (deopt_id_to_ic_data[i] != NULL) {
      ASSERT(i == deopt_id_to_ic_data[i]->deopt_id());
      array.SetAt(count++, *deopt_id_to_ic_data[i]);
    }
  }
  array.SetAt(0, edge_counters_array);
  set_ic_data_array(array);
#else   // DART_PRECOMPILED_RUNTIME
  UNREACHABLE();
#endif  // DART_PRECOMPILED_RUNTIME
}

void Function::RestoreICDataMap(
    ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data,
    bool clone_ic_data) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
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
      ASSERT(deopt_id_to_ic_data->At(ic_data.deopt_id()) == nullptr);
      (*deopt_id_to_ic_data)[ic_data.deopt_id()] = &ic_data;
    }
  }
#else   // DART_PRECOMPILED_RUNTIME
  UNREACHABLE();
#endif  // DART_PRECOMPILED_RUNTIME
}

void Function::set_ic_data_array(const Array& value) const {
  raw_ptr()->set_ic_data_array<std::memory_order_release>(value.raw());
}

ArrayPtr Function::ic_data_array() const {
  return raw_ptr()->ic_data_array<std::memory_order_acquire>();
}

void Function::ClearICDataArray() const {
  set_ic_data_array(Array::null_array());
}

ICDataPtr Function::FindICData(intptr_t deopt_id) const {
  const Array& array = Array::Handle(ic_data_array());
  ICData& ic_data = ICData::Handle();
  for (intptr_t i = 1; i < array.Length(); i++) {
    ic_data ^= array.At(i);
    if (ic_data.deopt_id() == deopt_id) {
      return ic_data.raw();
    }
  }
  return ICData::null();
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

bool Function::CheckSourceFingerprint(int32_t fp, const char* kind) const {
#if !defined(DEBUG)
  return true;  // Only check on debug.
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Check that the function is marked as recognized via the vm:recognized
  // pragma. This is so that optimizations that change the signature will know
  // not to touch it.
  if (kind != nullptr && !MethodRecognizer::IsMarkedAsRecognized(*this, kind)) {
    OS::PrintErr(
        "Recognized method %s should be marked with: "
        "@pragma(\"vm:recognized\", \"%s\")\n",
        ToQualifiedCString(), kind);
    return false;
  }
#endif

  if (Isolate::Current()->obfuscate() || FLAG_precompiled_mode ||
      (Dart::vm_snapshot_kind() != Snapshot::kNone)) {
    return true;  // The kernel structure has been altered, skip checking.
  }

  if (SourceFingerprint() != fp) {
    // This output can be copied into a file, then used with sed
    // to replace the old values.
    // sed -i.bak -f /tmp/newkeys \
    //    runtime/vm/compiler/recognized_methods_list.h
    THR_Print("s/0x%08x/0x%08x/\n", fp, SourceFingerprint());
    return false;
  }
  return true;
}

CodePtr Function::EnsureHasCode() const {
  if (HasCode()) return CurrentCode();
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  DEBUG_ASSERT(thread->TopErrorHandlerIsExitFrame());
  Zone* zone = thread->zone();
  const Object& result =
      Object::Handle(zone, Compiler::CompileFunction(thread, *this));
  if (result.IsError()) {
    if (result.IsLanguageError()) {
      Exceptions::ThrowCompileTimeError(LanguageError::Cast(result));
      UNREACHABLE();
    }
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }
  // Compiling in unoptimized mode should never fail if there are no errors.
  ASSERT(HasCode());
  ASSERT(ForceOptimize() || unoptimized_code() == result.raw());
  return CurrentCode();
}

bool Function::NeedsMonomorphicCheckedEntry(Zone* zone) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (!IsDynamicFunction()) {
    return false;
  }

  // For functions which need an args descriptor the switchable call sites will
  // transition directly to calling via a stub (and therefore never call the
  // monomorphic entry).
  //
  // See runtime_entry.cc:DEFINE_RUNTIME_ENTRY(UnlinkedCall)
  if (PrologueNeedsArgumentsDescriptor()) {
    return false;
  }

  // All dyn:* forwarders are called via SwitchableCalls and all except the ones
  // with `PrologueNeedsArgumentsDescriptor()` transition into monomorphic
  // state.
  if (Function::IsDynamicInvocationForwarderName(name())) {
    return true;
  }

  // If table dispatch is disabled, all instance calls use switchable calls.
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions &&
        FLAG_use_table_dispatch)) {
    return true;
  }

  // Only if there are dynamic callers and if we didn't create a dyn:* forwarder
  // for it do we need the monomorphic checked entry.
  return HasDynamicCallers(zone) &&
         !kernel::NeedsDynamicInvocationForwarder(*this);
#else
  UNREACHABLE();
  return true;
#endif
}

bool Function::HasDynamicCallers(Zone* zone) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Issue(dartbug.com/42719):
  // Right now the metadata of _Closure.call says there are no dynamic callers -
  // even though there can be. To be conservative we return true.
  if ((name() == Symbols::GetCall().raw() || name() == Symbols::Call().raw()) &&
      Class::IsClosureClass(Owner())) {
    return true;
  }

  // Use the results of TFA to determine whether this function is ever
  // called dynamically, i.e. using switchable calls.
  kernel::ProcedureAttributesMetadata metadata;
  metadata = kernel::ProcedureAttributesOf(*this, zone);
  if (IsGetterFunction() || IsImplicitGetterFunction() || IsMethodExtractor()) {
    return metadata.getter_called_dynamically;
  } else {
    return metadata.method_or_setter_called_dynamically;
  }
#else
  UNREACHABLE();
  return true;
#endif
}

bool Function::PrologueNeedsArgumentsDescriptor() const {
  // These functions have a saved compile-time arguments descriptor that is
  // used in lieu of the runtime arguments descriptor in generated IL.
  if (IsInvokeFieldDispatcher() || IsNoSuchMethodDispatcher()) {
    return false;
  }
  // The prologue of those functions need to examine the arg descriptor for
  // various purposes.
  return IsGeneric() || HasOptionalParameters();
}

bool Function::MayHaveUncheckedEntryPoint() const {
  return FLAG_enable_multiple_entrypoints &&
         (NeedsTypeArgumentTypeChecks() || NeedsArgumentTypeChecks());
}

intptr_t Function::SourceSize() const {
  const TokenPosition& start = token_pos();
  const TokenPosition& end = end_token_pos();
  if (!end.IsReal() || start.IsNoSource() || start.IsClassifying()) {
    // No source information, so just return 0.
    return 0;
  }
  if (start.IsSynthetic()) {
    // Try and approximate the source size using the parent's source size.
    const auto& parent = Function::Handle(parent_function());
    ASSERT(!parent.IsNull());
    const intptr_t parent_size = parent.SourceSize();
    if (parent_size == 0) {
      return parent_size;
    }
    // Parent must have a real ending position.
    return parent_size - (parent.end_token_pos().Pos() - end.Pos());
  }
  return end.Pos() - start.Pos();
}

const char* Function::ToCString() const {
  if (IsNull()) {
    return "Function: null";
  }
  Zone* zone = Thread::Current()->zone();
  ZoneTextBuffer buffer(zone);
  buffer.Printf("Function '%s':", String::Handle(zone, name()).ToCString());
  if (is_static()) {
    buffer.AddString(" static");
  }
  if (is_abstract()) {
    buffer.AddString(" abstract");
  }
  switch (kind()) {
    case FunctionLayout::kRegularFunction:
    case FunctionLayout::kClosureFunction:
    case FunctionLayout::kImplicitClosureFunction:
    case FunctionLayout::kGetterFunction:
    case FunctionLayout::kSetterFunction:
      break;
    case FunctionLayout::kSignatureFunction:
      buffer.AddString(" signature");
      break;
    case FunctionLayout::kConstructor:
      buffer.AddString(is_static() ? " factory" : " constructor");
      break;
    case FunctionLayout::kImplicitGetter:
      buffer.AddString(" getter");
      break;
    case FunctionLayout::kImplicitSetter:
      buffer.AddString(" setter");
      break;
    case FunctionLayout::kImplicitStaticGetter:
      buffer.AddString(" static-getter");
      break;
    case FunctionLayout::kFieldInitializer:
      buffer.AddString(" field-initializer");
      break;
    case FunctionLayout::kMethodExtractor:
      buffer.AddString(" method-extractor");
      break;
    case FunctionLayout::kNoSuchMethodDispatcher:
      buffer.AddString(" no-such-method-dispatcher");
      break;
    case FunctionLayout::kDynamicInvocationForwarder:
      buffer.AddString(" dynamic-invocation-forwarder");
      break;
    case FunctionLayout::kInvokeFieldDispatcher:
      buffer.AddString(" invoke-field-dispatcher");
      break;
    case FunctionLayout::kIrregexpFunction:
      buffer.AddString(" irregexp-function");
      break;
    case FunctionLayout::kFfiTrampoline:
      buffer.AddString(" ffi-trampoline-function");
      break;
    default:
      UNREACHABLE();
  }
  if (IsNoSuchMethodDispatcher() || IsInvokeFieldDispatcher()) {
    const auto& args_desc_array = Array::Handle(zone, saved_args_desc());
    const ArgumentsDescriptor args_desc(args_desc_array);
    buffer.AddChar('[');
    args_desc.PrintTo(&buffer);
    buffer.AddChar(']');
  }
  if (is_const()) {
    buffer.AddString(" const");
  }
  buffer.AddChar('.');
  return buffer.buffer();
}

void ClosureData::set_context_scope(const ContextScope& value) const {
  raw_ptr()->set_context_scope(value.raw());
}

void ClosureData::set_implicit_static_closure(const Instance& closure) const {
  ASSERT(!closure.IsNull());
  ASSERT(raw_ptr()->closure() == Instance::null());
  raw_ptr()->set_closure(closure.raw());
}

void ClosureData::set_parent_function(const Function& value) const {
  raw_ptr()->set_parent_function(value.raw());
}

void ClosureData::set_signature_type(const Type& value) const {
  raw_ptr()->set_signature_type(value.raw());
}

void ClosureData::set_default_type_arguments(const TypeArguments& value) const {
  raw_ptr()->set_default_type_arguments(value.raw());
}

intptr_t ClosureData::default_type_arguments_info() const {
  const SmiPtr value = raw_ptr()->default_type_arguments_info();
  if (value == Smi::null()) {
    static_assert(Function::DefaultTypeArgumentsKindField::decode(0) ==
                      Function::DefaultTypeArgumentsKind::kInvalid,
                  "Returning valid value for null Smi");
    return 0;
  }
  return Smi::Value(raw_ptr()->default_type_arguments_info());
}

void ClosureData::set_default_type_arguments_info(intptr_t value) const {
  ASSERT(Smi::IsValid(value));
  raw_ptr()->set_default_type_arguments_info(Smi::New(value));
}

ClosureDataPtr ClosureData::New() {
  ASSERT(Object::closure_data_class() != Class::null());
  ObjectPtr raw = Object::Allocate(ClosureData::kClassId,
                                   ClosureData::InstanceSize(), Heap::kOld);
  return static_cast<ClosureDataPtr>(raw);
}

const char* ClosureData::ToCString() const {
  if (IsNull()) {
    return "ClosureData: null";
  }
  auto const zone = Thread::Current()->zone();
  ZoneTextBuffer buffer(zone);
  buffer.Printf("ClosureData: context_scope: 0x%" Px "",
                static_cast<uword>(context_scope()));
  buffer.AddString(" parent_function: ");
  if (parent_function() == Function::null()) {
    buffer.AddString("null");
  } else {
    buffer.AddString(Function::Handle(zone, parent_function()).ToCString());
  }
  buffer.AddString(" signature_type: ");
  if (signature_type() == Type::null()) {
    buffer.AddString("null");
  } else {
    buffer.AddString(Type::Handle(zone, signature_type()).ToCString());
  }
  buffer.Printf(" implicit_static_closure: 0x%" Px "",
                static_cast<uword>(implicit_static_closure()));
  buffer.AddString(" default_type_arguments: ");
  if (default_type_arguments() == TypeArguments::null()) {
    buffer.AddString("null");
  } else {
    buffer.AddString(
        TypeArguments::Handle(zone, default_type_arguments()).ToCString());
  }
  return buffer.buffer();
}

void SignatureData::set_parent_function(const Function& value) const {
  raw_ptr()->set_parent_function(value.raw());
}

void SignatureData::set_signature_type(const Type& value) const {
  raw_ptr()->set_signature_type(value.raw());
}

SignatureDataPtr SignatureData::New(Heap::Space space) {
  ASSERT(Object::signature_data_class() != Class::null());
  ObjectPtr raw = Object::Allocate(SignatureData::kClassId,
                                   SignatureData::InstanceSize(), space);
  return static_cast<SignatureDataPtr>(raw);
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

void FfiTrampolineData::set_signature_type(const Type& value) const {
  raw_ptr()->set_signature_type(value.raw());
}

void FfiTrampolineData::set_c_signature(const Function& value) const {
  raw_ptr()->set_c_signature(value.raw());
}

void FfiTrampolineData::set_callback_target(const Function& value) const {
  raw_ptr()->set_callback_target(value.raw());
}

void FfiTrampolineData::set_callback_id(int32_t callback_id) const {
  StoreNonPointer(&raw_ptr()->callback_id_, callback_id);
}

void FfiTrampolineData::set_callback_exceptional_return(
    const Instance& value) const {
  raw_ptr()->set_callback_exceptional_return(value.raw());
}

FfiTrampolineDataPtr FfiTrampolineData::New() {
  ASSERT(Object::ffi_trampoline_data_class() != Class::null());
  ObjectPtr raw =
      Object::Allocate(FfiTrampolineData::kClassId,
                       FfiTrampolineData::InstanceSize(), Heap::kOld);
  FfiTrampolineDataPtr data = static_cast<FfiTrampolineDataPtr>(raw);
  data->ptr()->callback_id_ = 0;
  return data;
}

const char* FfiTrampolineData::ToCString() const {
  Type& signature_type = Type::Handle(this->signature_type());
  String& signature_type_name =
      String::Handle(signature_type.UserVisibleName());
  return OS::SCreate(
      Thread::Current()->zone(), "TrampolineData: signature=%s",
      signature_type_name.IsNull() ? "null" : signature_type_name.ToCString());
}

FieldPtr Field::CloneFromOriginal() const {
  return this->Clone(*this);
}

FieldPtr Field::Original() const {
  if (IsNull()) {
    return Field::null();
  }
  Object& obj = Object::Handle(raw_ptr()->owner());
  if (obj.IsField()) {
    return Field::RawCast(obj.raw());
  } else {
    return this->raw();
  }
}

const Object* Field::CloneForUnboxed(const Object& value) const {
  if (is_unboxing_candidate() && !is_nullable()) {
    switch (guarded_cid()) {
      case kDoubleCid:
      case kFloat32x4Cid:
      case kFloat64x2Cid:
        return &Object::Handle(Object::Clone(value, Heap::kNew));
      default:
        // Not a supported unboxed field type.
        return &value;
    }
  }
  return &value;
}

void Field::DisableFieldUnboxing() const {
  Thread* thread = Thread::Current();
  ASSERT(!IsOriginal());
  const Field& original = Field::Handle(Original());
  if (!original.is_unboxing_candidate()) {
    return;
  }
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if (!original.is_unboxing_candidate()) {
    return;
  }
  original.set_is_unboxing_candidate(false);
  set_is_unboxing_candidate(false);
  original.DeoptimizeDependentCode();
}

intptr_t Field::guarded_cid() const {
#if defined(DEBUG)
  // This assertion ensures that the cid seen by the background compiler is
  // consistent. So the assertion passes if the field is a clone. It also
  // passes if the field is static, because we don't use field guards on
  // static fields.
  Thread* thread = Thread::Current();
  ASSERT(!thread->IsInsideCompiler() ||
#if !defined(DART_PRECOMPILED_RUNTIME)
         ((CompilerState::Current().should_clone_fields() == !IsOriginal())) ||
#endif
         is_static());
#endif
  return LoadNonPointer<ClassIdTagType, std::memory_order_relaxed>(
      &raw_ptr()->guarded_cid_);
}

void Field::SetOriginal(const Field& value) const {
  ASSERT(value.IsOriginal());
  ASSERT(!value.IsNull());
  raw_ptr()->set_owner(static_cast<ObjectPtr>(value.raw()));
}

StringPtr Field::GetterName(const String& field_name) {
  return String::Concat(Symbols::GetterPrefix(), field_name);
}

StringPtr Field::GetterSymbol(const String& field_name) {
  return Symbols::FromGet(Thread::Current(), field_name);
}

StringPtr Field::LookupGetterSymbol(const String& field_name) {
  return Symbols::LookupFromGet(Thread::Current(), field_name);
}

StringPtr Field::SetterName(const String& field_name) {
  return String::Concat(Symbols::SetterPrefix(), field_name);
}

StringPtr Field::SetterSymbol(const String& field_name) {
  return Symbols::FromSet(Thread::Current(), field_name);
}

StringPtr Field::LookupSetterSymbol(const String& field_name) {
  return Symbols::LookupFromSet(Thread::Current(), field_name);
}

StringPtr Field::NameFromGetter(const String& getter_name) {
  return Symbols::New(Thread::Current(), getter_name, kGetterPrefixLength,
                      getter_name.Length() - kGetterPrefixLength);
}

StringPtr Field::NameFromSetter(const String& setter_name) {
  return Symbols::New(Thread::Current(), setter_name, kSetterPrefixLength,
                      setter_name.Length() - kSetterPrefixLength);
}

StringPtr Field::NameFromInit(const String& init_name) {
  return Symbols::New(Thread::Current(), init_name, kInitPrefixLength,
                      init_name.Length() - kInitPrefixLength);
}

bool Field::IsGetterName(const String& function_name) {
  return function_name.StartsWith(Symbols::GetterPrefix());
}

bool Field::IsSetterName(const String& function_name) {
  return function_name.StartsWith(Symbols::SetterPrefix());
}

bool Field::IsInitName(const String& function_name) {
  return function_name.StartsWith(Symbols::InitPrefix());
}

void Field::set_name(const String& value) const {
  ASSERT(value.IsSymbol());
  ASSERT(IsOriginal());
  raw_ptr()->set_name(value.raw());
}

ObjectPtr Field::RawOwner() const {
  if (IsOriginal()) {
    return raw_ptr()->owner();
  } else {
    const Field& field = Field::Handle(Original());
    ASSERT(field.IsOriginal());
    ASSERT(!Object::Handle(field.raw_ptr()->owner()).IsField());
    return field.raw_ptr()->owner();
  }
}

ClassPtr Field::Owner() const {
  const Field& field = Field::Handle(Original());
  ASSERT(field.IsOriginal());
  const Object& obj = Object::Handle(field.raw_ptr()->owner());
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).patched_class();
}

ClassPtr Field::Origin() const {
  const Field& field = Field::Handle(Original());
  ASSERT(field.IsOriginal());
  const Object& obj = Object::Handle(field.raw_ptr()->owner());
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).origin_class();
}

ScriptPtr Field::Script() const {
  // NOTE(turnidge): If you update this function, you probably want to
  // update Class::PatchFieldsAndFunctions() at the same time.
  const Field& field = Field::Handle(Original());
  ASSERT(field.IsOriginal());
  const Object& obj = Object::Handle(field.raw_ptr()->owner());
  if (obj.IsClass()) {
    return Class::Cast(obj).script();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).script();
}

ExternalTypedDataPtr Field::KernelData() const {
  const Object& obj = Object::Handle(this->raw_ptr()->owner());
  // During background JIT compilation field objects are copied
  // and copy points to the original field via the owner field.
  if (obj.IsField()) {
    return Field::Cast(obj).KernelData();
  } else if (obj.IsClass()) {
    Library& library = Library::Handle(Class::Cast(obj).library());
    return library.kernel_data();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).library_kernel_data();
}

void Field::InheritKernelOffsetFrom(const Field& src) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  StoreNonPointer(&raw_ptr()->kernel_offset_, src.raw_ptr()->kernel_offset_);
#endif
}

intptr_t Field::KernelDataProgramOffset() const {
  const Object& obj = Object::Handle(raw_ptr()->owner());
  // During background JIT compilation field objects are copied
  // and copy points to the original field via the owner field.
  if (obj.IsField()) {
    return Field::Cast(obj).KernelDataProgramOffset();
  } else if (obj.IsClass()) {
    Library& lib = Library::Handle(Class::Cast(obj).library());
    return lib.kernel_offset();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).library_kernel_offset();
}

// Called at finalization time
void Field::SetFieldType(const AbstractType& value) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsOriginal());
  ASSERT(!value.IsNull());
  if (value.raw() != type()) {
    raw_ptr()->set_type(value.raw());
  }
}

FieldPtr Field::New() {
  ASSERT(Object::field_class() != Class::null());
  ObjectPtr raw =
      Object::Allocate(Field::kClassId, Field::InstanceSize(), Heap::kOld);
  return static_cast<FieldPtr>(raw);
}

void Field::InitializeNew(const Field& result,
                          const String& name,
                          bool is_static,
                          bool is_final,
                          bool is_const,
                          bool is_reflectable,
                          bool is_late,
                          const Object& owner,
                          TokenPosition token_pos,
                          TokenPosition end_token_pos) {
  result.set_kind_bits(0);
  result.set_name(name);
  result.set_is_static(is_static);
  if (is_static) {
    result.set_field_id(-1);
  } else {
    result.SetOffset(0, 0);
  }
  result.set_is_final(is_final);
  result.set_is_const(is_const);
  result.set_is_reflectable(is_reflectable);
  result.set_is_late(is_late);
  result.set_is_double_initialized(false);
  result.set_owner(owner);
  result.set_token_pos(token_pos);
  result.set_end_token_pos(end_token_pos);
  result.set_has_nontrivial_initializer(false);
  result.set_has_initializer(false);
  if (FLAG_precompiled_mode) {
    // May be updated by KernelLoader::ReadInferredType
    result.set_is_unboxing_candidate_unsafe(false);
  } else {
    result.set_is_unboxing_candidate_unsafe(!is_final && !is_late &&
                                            !is_static);
  }
  result.set_initializer_changed_after_initialization(false);
  NOT_IN_PRECOMPILED(result.set_kernel_offset(0));
  result.set_has_pragma(false);
  result.set_static_type_exactness_state(
      StaticTypeExactnessState::NotTracking());
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
  result.set_guarded_cid_unsafe(use_guarded_cid ? kIllegalCid : kDynamicCid);
  result.set_is_nullable_unsafe(use_guarded_cid ? false : true);
  result.set_guarded_list_length_in_object_offset_unsafe(
      Field::kUnknownLengthOffset);
  // Presently, we only attempt to remember the list length for final fields.
  if (is_final && use_guarded_cid) {
    result.set_guarded_list_length_unsafe(Field::kUnknownFixedLength);
  } else {
    result.set_guarded_list_length_unsafe(Field::kNoFixedLength);
  }
}

FieldPtr Field::New(const String& name,
                    bool is_static,
                    bool is_final,
                    bool is_const,
                    bool is_reflectable,
                    bool is_late,
                    const Object& owner,
                    const AbstractType& type,
                    TokenPosition token_pos,
                    TokenPosition end_token_pos) {
  ASSERT(!owner.IsNull());
  const Field& result = Field::Handle(Field::New());
  InitializeNew(result, name, is_static, is_final, is_const, is_reflectable,
                is_late, owner, token_pos, end_token_pos);
  result.SetFieldType(type);
  return result.raw();
}

FieldPtr Field::NewTopLevel(const String& name,
                            bool is_final,
                            bool is_const,
                            bool is_late,
                            const Object& owner,
                            TokenPosition token_pos,
                            TokenPosition end_token_pos) {
  ASSERT(!owner.IsNull());
  const Field& result = Field::Handle(Field::New());
  InitializeNew(result, name, true,       /* is_static */
                is_final, is_const, true, /* is_reflectable */
                is_late, owner, token_pos, end_token_pos);
  return result.raw();
}

FieldPtr Field::Clone(const Field& original) const {
  if (original.IsNull()) {
    return Field::null();
  }
  ASSERT(original.IsOriginal());
  Field& clone = Field::Handle();
  clone ^= Object::Clone(*this, Heap::kOld);
  clone.SetOriginal(original);
  clone.InheritKernelOffsetFrom(original);
  return clone.raw();
}

int32_t Field::SourceFingerprint() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  return kernel::KernelSourceFingerprintHelper::CalculateFieldFingerprint(
      *this);
#else
  return 0;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

StringPtr Field::InitializingExpression() const {
  UNREACHABLE();
  return String::null();
}

const char* Field::UserVisibleNameCString() const {
  NoSafepointScope no_safepoint;
  if (FLAG_show_internal_names) {
    return String::Handle(name()).ToCString();
  }
  return String::ScrubName(String::Handle(name()), is_extension_member());
}

StringPtr Field::UserVisibleName() const {
  if (FLAG_show_internal_names) {
    return name();
  }
  return Symbols::New(
      Thread::Current(),
      String::ScrubName(String::Handle(name()), is_extension_member()));
}

intptr_t Field::guarded_list_length() const {
  return Smi::Value(raw_ptr()->guarded_list_length());
}

void Field::set_guarded_list_length_unsafe(intptr_t list_length) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsOriginal());
  raw_ptr()->set_guarded_list_length(Smi::New(list_length));
}

intptr_t Field::guarded_list_length_in_object_offset() const {
  return raw_ptr()->guarded_list_length_in_object_offset_ + kHeapObjectTag;
}

void Field::set_guarded_list_length_in_object_offset_unsafe(
    intptr_t list_length_offset) const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsOriginal());
  StoreNonPointer(&raw_ptr()->guarded_list_length_in_object_offset_,
                  static_cast<int8_t>(list_length_offset - kHeapObjectTag));
  ASSERT(guarded_list_length_in_object_offset() == list_length_offset);
}

bool Field::NeedsSetter() const {
  // Late fields always need a setter, unless they're static and non-final, or
  // final with an initializer.
  if (is_late()) {
    if (is_static() && !is_final()) {
      return false;
    }
    if (is_final() && has_initializer()) {
      return false;
    }
    return true;
  }

  // Non-late static fields never need a setter.
  if (is_static()) {
    return false;
  }

  // Otherwise, the field only needs a setter if it isn't final.
  return !is_final();
}

bool Field::NeedsGetter() const {
  // All instance fields need a getter.
  if (!is_static()) return true;

  // Static fields also need a getter if they have a non-trivial initializer,
  // because it needs to be initialized lazily.
  if (has_nontrivial_initializer()) return true;

  // Static late fields with no initializer also need a getter, to check if it's
  // been initialized.
  return is_late() && !has_initializer();
}

const char* Field::ToCString() const {
  NoSafepointScope no_safepoint;
  if (IsNull()) {
    return "Field: null";
  }
  const char* kF0 = is_static() ? " static" : "";
  const char* kF1 = is_late() ? " late" : "";
  const char* kF2 = is_final() ? " final" : "";
  const char* kF3 = is_const() ? " const" : "";
  const char* field_name = String::Handle(name()).ToCString();
  const Class& cls = Class::Handle(Owner());
  const char* cls_name = String::Handle(cls.Name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(), "Field <%s.%s>:%s%s%s%s",
                     cls_name, field_name, kF0, kF1, kF2, kF3);
}

// Build a closure object that gets (or sets) the contents of a static
// field f and cache the closure in a newly created static field
// named #f (or #f= in case of a setter).
InstancePtr Field::AccessorClosure(bool make_setter) const {
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

  UNREACHABLE();
  return Instance::null();
}

InstancePtr Field::GetterClosure() const {
  return AccessorClosure(false);
}

InstancePtr Field::SetterClosure() const {
  return AccessorClosure(true);
}

ArrayPtr Field::dependent_code() const {
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadReader());
  return raw_ptr()->dependent_code();
}

void Field::set_dependent_code(const Array& array) const {
  ASSERT(IsOriginal());
  DEBUG_ASSERT(
      IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  raw_ptr()->set_dependent_code(array.raw());
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
  if (FLAG_trace_deoptimization && a.HasCodes()) {
    THR_Print("Deopt for field guard (field %s)\n", ToCString());
  }
  a.DisableCode();
}

bool Field::IsConsistentWith(const Field& other) const {
  return (raw_ptr()->guarded_cid_ == other.raw_ptr()->guarded_cid_) &&
         (raw_ptr()->is_nullable_ == other.raw_ptr()->is_nullable_) &&
         (raw_ptr()->guarded_list_length() ==
          other.raw_ptr()->guarded_list_length()) &&
         (is_unboxing_candidate() == other.is_unboxing_candidate()) &&
         (static_type_exactness_state().Encode() ==
          other.static_type_exactness_state().Encode());
}

bool Field::IsUninitialized() const {
  Thread* thread = Thread::Current();
  const FieldTable* field_table = thread->isolate()->field_table();
  const InstancePtr raw_value = field_table->At(field_id());
  ASSERT(raw_value != Object::transition_sentinel().raw());
  return raw_value == Object::sentinel().raw();
}

FunctionPtr Field::EnsureInitializerFunction() const {
  ASSERT(has_nontrivial_initializer());
  ASSERT(IsOriginal());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& initializer = Function::Handle(zone, InitializerFunction());
  if (initializer.IsNull()) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    SafepointMutexLocker ml(
        thread->isolate()->group()->initializer_functions_mutex());
    // Double check after grabbing the lock.
    initializer = InitializerFunction();
    if (initializer.IsNull()) {
      initializer = kernel::CreateFieldInitializerFunction(thread, zone, *this);
    }
#endif
  }
  return initializer.raw();
}

void Field::SetInitializerFunction(const Function& initializer) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(IsOriginal());
  ASSERT(IsolateGroup::Current()
             ->initializer_functions_mutex()
             ->IsOwnedByCurrentThread());
  // We have to ensure that all stores into the initializer function object
  // happen before releasing the pointer to the initializer as it may be
  // accessed without grabbing the lock.
  raw_ptr()->set_initializer_function<std::memory_order_release>(
      initializer.raw());
#endif
}

bool Field::HasInitializerFunction() const {
  return raw_ptr()->initializer_function() != Function::null();
}

ErrorPtr Field::InitializeInstance(const Instance& instance) const {
  ASSERT(IsOriginal());
  ASSERT(is_instance());
  ASSERT(instance.GetField(*this) == Object::sentinel().raw());
  Object& value = Object::Handle();

  if (has_nontrivial_initializer()) {
    const Function& initializer = Function::Handle(EnsureInitializerFunction());
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, instance);
    value = DartEntry::InvokeFunction(initializer, args);
    if (!value.IsNull() && value.IsError()) {
      return Error::Cast(value).raw();
    }
  } else {
    if (is_late() && !has_initializer()) {
      Exceptions::ThrowLateFieldNotInitialized(String::Handle(name()));
      UNREACHABLE();
    }
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    // Our trivial initializer is `null`. Any non-`null` initializer is
    // non-trivial (see `KernelLoader::CheckForInitializer()`).
    value = Object::null();
#endif
  }
  ASSERT(value.IsNull() || value.IsInstance());
  if (is_late() && is_final() &&
      (instance.GetField(*this) != Object::sentinel().raw())) {
    Exceptions::ThrowLateFieldAssignedDuringInitialization(
        String::Handle(name()));
    UNREACHABLE();
  }
  instance.SetField(*this, value);
  return Error::null();
}

ErrorPtr Field::InitializeStatic() const {
  ASSERT(IsOriginal());
  ASSERT(is_static());
  if (StaticValue() == Object::sentinel().raw()) {
    auto& value = Object::Handle();
    if (is_late()) {
      if (!has_initializer()) {
        Exceptions::ThrowLateFieldNotInitialized(String::Handle(name()));
        UNREACHABLE();
      }
      value = EvaluateInitializer();
      if (value.IsError()) {
        return Error::Cast(value).raw();
      }
      if (is_final() && (StaticValue() != Object::sentinel().raw())) {
        Exceptions::ThrowLateFieldAssignedDuringInitialization(
            String::Handle(name()));
        UNREACHABLE();
      }
    } else {
      SetStaticValue(Object::transition_sentinel());
      value = EvaluateInitializer();
      if (value.IsError()) {
        SetStaticValue(Object::null_instance());
        return Error::Cast(value).raw();
      }
    }
    ASSERT(value.IsNull() || value.IsInstance());
    SetStaticValue(
        value.IsNull() ? Instance::null_instance() : Instance::Cast(value),
        is_const());
    return Error::null();
  } else if (StaticValue() == Object::transition_sentinel().raw()) {
    ASSERT(!is_late());
    const Array& ctor_args = Array::Handle(Array::New(1));
    const String& field_name = String::Handle(name());
    ctor_args.SetAt(0, field_name);
    Exceptions::ThrowByType(Exceptions::kCyclicInitializationError, ctor_args);
    UNREACHABLE();
  }
  return Error::null();
}

ObjectPtr Field::EvaluateInitializer() const {
  Thread* const thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (is_static() && is_const()) {
    ASSERT(!FLAG_precompiled_mode);
    return kernel::EvaluateStaticConstFieldInitializer(*this);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  NoOOBMessageScope no_msg_scope(thread);
  NoReloadScope no_reload_scope(thread->isolate(), thread);
  const Function& initializer = Function::Handle(EnsureInitializerFunction());
  return DartEntry::InvokeFunction(initializer, Object::empty_array());
}

static intptr_t GetListLength(const Object& value) {
  if (value.IsTypedData() || value.IsTypedDataView() ||
      value.IsExternalTypedData()) {
    return TypedDataBase::Cast(value).Length();
  } else if (value.IsArray()) {
    return Array::Cast(value).Length();
  } else if (value.IsGrowableObjectArray()) {
    // List length is variable.
    return Field::kNoFixedLength;
  }
  return Field::kNoFixedLength;
}

static intptr_t GetListLengthOffset(intptr_t cid) {
  if (IsTypedDataClassId(cid) || IsTypedDataViewClassId(cid) ||
      IsExternalTypedDataClassId(cid)) {
    return TypedData::length_offset();
  } else if (cid == kArrayCid || cid == kImmutableArrayCid) {
    return Array::length_offset();
  } else if (cid == kGrowableObjectArrayCid) {
    // List length is variable.
    return Field::kUnknownLengthOffset;
  }
  return Field::kUnknownLengthOffset;
}

const char* Field::GuardedPropertiesAsCString() const {
  if (guarded_cid() == kIllegalCid) {
    return "<?>";
  } else if (guarded_cid() == kDynamicCid) {
    ASSERT(!static_type_exactness_state().IsExactOrUninitialized());
    return "<*>";
  }

  Zone* zone = Thread::Current()->zone();

  const char* exactness = "";
  if (static_type_exactness_state().IsTracking()) {
    exactness =
        zone->PrintToString(" {%s}", static_type_exactness_state().ToCString());
  }

  const Class& cls =
      Class::Handle(Isolate::Current()->class_table()->At(guarded_cid()));
  const char* class_name = String::Handle(cls.Name()).ToCString();

  if (IsBuiltinListClassId(guarded_cid()) && !is_nullable() && is_final()) {
    ASSERT(guarded_list_length() != kUnknownFixedLength);
    if (guarded_list_length() == kNoFixedLength) {
      return zone->PrintToString("<%s [*]%s>", class_name, exactness);
    } else {
      return zone->PrintToString(
          "<%s [%" Pd " @%" Pd "]%s>", class_name, guarded_list_length(),
          guarded_list_length_in_object_offset(), exactness);
    }
  }

  return zone->PrintToString("<%s %s%s>",
                             is_nullable() ? "nullable" : "not-nullable",
                             class_name, exactness);
}

void Field::InitializeGuardedListLengthInObjectOffset(bool unsafe) const {
  auto setter = unsafe ? &Field::set_guarded_list_length_in_object_offset_unsafe
                       : &Field::set_guarded_list_length_in_object_offset;
  ASSERT(IsOriginal());
  if (needs_length_check() &&
      (guarded_list_length() != Field::kUnknownFixedLength)) {
    const intptr_t offset = GetListLengthOffset(guarded_cid());
    (this->*setter)(offset);
    ASSERT(offset != Field::kUnknownLengthOffset);
  } else {
    (this->*setter)(Field::kUnknownLengthOffset);
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

// Given the type G<T0, ..., Tn> and class C<U0, ..., Un> find path to C at G.
// This path can be used to compute type arguments of C at G.
//
// Note: we are relying on the restriction that the same class can only occur
// once among the supertype.
static bool FindInstantiationOf(const Type& type,
                                const Class& cls,
                                GrowableArray<const AbstractType*>* path,
                                bool consider_only_super_classes) {
  if (type.type_class() == cls.raw()) {
    return true;  // Found instantiation.
  }

  Class& cls2 = Class::Handle();
  AbstractType& super_type = AbstractType::Handle();
  super_type = cls.super_type();
  if (!super_type.IsNull() && !super_type.IsObjectType()) {
    cls2 = super_type.type_class();
    path->Add(&super_type);
    if (FindInstantiationOf(type, cls2, path, consider_only_super_classes)) {
      return true;  // Found instantiation.
    }
    path->RemoveLast();
  }

  if (!consider_only_super_classes) {
    Array& super_interfaces = Array::Handle(cls.interfaces());
    for (intptr_t i = 0; i < super_interfaces.Length(); i++) {
      super_type ^= super_interfaces.At(i);
      cls2 = super_type.type_class();
      path->Add(&super_type);
      if (FindInstantiationOf(type, cls2, path,
                              /*consider_only_supertypes=*/false)) {
        return true;  // Found instantiation.
      }
      path->RemoveLast();
    }
  }

  return false;  // Not found.
}

void Field::SetStaticValue(const Instance& value,
                           bool save_initial_value) const {
  auto thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());

  ASSERT(is_static());  // Valid only for static dart fields.
  const intptr_t id = field_id();
  ASSERT(id >= 0);

  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  thread->isolate()->field_table()->SetAt(id, value.raw());
  if (save_initial_value) {
    // TODO(https://dartbug.com/36097): We should re-visit call-sites where
    // `save_initial_value == true` and try to have a different path. This
    // method should only modify the isolate-local field state and not modify
    // the initial field table.
#if !defined(DART_PRECOMPILED_RUNTIME)
    thread->isolate_group()->initial_field_table()->SetAt(field_id(),
                                                          value.raw());
#endif
  }
}

static StaticTypeExactnessState TrivialTypeExactnessFor(const Class& cls) {
  const intptr_t type_arguments_offset = cls.host_type_arguments_field_offset();
  ASSERT(type_arguments_offset != Class::kNoTypeArguments);
  if (StaticTypeExactnessState::CanRepresentAsTriviallyExact(
          type_arguments_offset / kWordSize)) {
    return StaticTypeExactnessState::TriviallyExact(type_arguments_offset /
                                                    kWordSize);
  } else {
    return StaticTypeExactnessState::NotExact();
  }
}

static const char* SafeTypeArgumentsToCString(const TypeArguments& args) {
  return (args.raw() == TypeArguments::null()) ? "<null>" : args.ToCString();
}

StaticTypeExactnessState StaticTypeExactnessState::Compute(
    const Type& static_type,
    const Instance& value,
    bool print_trace /* = false */) {
  ASSERT(!value.IsNull());  // Should be handled by the caller.
  ASSERT(value.raw() != Object::sentinel().raw());
  ASSERT(value.raw() != Object::transition_sentinel().raw());

  const TypeArguments& static_type_args =
      TypeArguments::Handle(static_type.arguments());

  TypeArguments& args = TypeArguments::Handle();

  ASSERT(static_type.IsFinalized());
  const Class& cls = Class::Handle(value.clazz());
  GrowableArray<const AbstractType*> path(10);

  bool is_super_class = true;
  if (!FindInstantiationOf(static_type, cls, &path,
                           /*consider_only_super_classes=*/true)) {
    is_super_class = false;
    bool found_super_interface = FindInstantiationOf(
        static_type, cls, &path, /*consider_only_super_classes=*/false);
    ASSERT(found_super_interface);
  }

  // Trivial case: field has type G<T0, ..., Tn> and value has type
  // G<U0, ..., Un>. Check if type arguments match.
  if (path.is_empty()) {
    ASSERT(cls.raw() == static_type.type_class());
    args = value.GetTypeArguments();
    // TODO(dartbug.com/34170) Evaluate if comparing relevant subvectors (that
    // disregards superclass own arguments) improves precision of the
    // tracking.
    if (args.raw() == static_type_args.raw()) {
      return TrivialTypeExactnessFor(cls);
    }

    if (print_trace) {
      THR_Print("  expected %s got %s type arguments\n",
                SafeTypeArgumentsToCString(static_type_args),
                SafeTypeArgumentsToCString(args));
    }
    return StaticTypeExactnessState::NotExact();
  }

  // Value has type C<U0, ..., Un> and field has type G<T0, ..., Tn> and G != C.
  // Compute C<X0, ..., Xn> at G (Xi are free type arguments).
  // Path array contains a chain of immediate supertypes S0 <: S1 <: ... Sn,
  // such that S0 is an immediate supertype of C and Sn is G<...>.
  // Each Si might depend on type parameters of the previous supertype S{i-1}.
  // To compute C<X0, ..., Xn> at G we walk the chain backwards and
  // instantiate Si using type parameters of S{i-1} which gives us a type
  // depending on type parameters of S{i-2}.
  AbstractType& type = AbstractType::Handle(path.Last()->raw());
  for (intptr_t i = path.length() - 2; (i >= 0) && !type.IsInstantiated();
       i--) {
    args = path[i]->arguments();
    type = type.InstantiateFrom(args, TypeArguments::null_type_arguments(),
                                kAllFree, Heap::kNew);
  }

  if (type.IsInstantiated()) {
    // C<X0, ..., Xn> at G is fully instantiated and does not depend on
    // Xi. In this case just check if type arguments match.
    args = type.arguments();
    if (args.Equals(static_type_args)) {
      return is_super_class ? StaticTypeExactnessState::HasExactSuperClass()
                            : StaticTypeExactnessState::HasExactSuperType();
    }

    if (print_trace) {
      THR_Print("  expected %s got %s type arguments\n",
                SafeTypeArgumentsToCString(static_type_args),
                SafeTypeArgumentsToCString(args));
    }

    return StaticTypeExactnessState::NotExact();
  }

  // The most complicated case: C<X0, ..., Xn> at G depends on
  // Xi values. To compare type arguments we would need to instantiate
  // it fully from value's type arguments and compare with <U0, ..., Un>.
  // However this would complicate fast path in the native code. To avoid this
  // complication we would optimize for the trivial case: we check if
  // C<X0, ..., Xn> at G is exactly G<X0, ..., Xn> which means we can simply
  // compare values type arguements (<T0, ..., Tn>) to fields type arguments
  // (<U0, ..., Un>) to establish if field type is exact.
  ASSERT(cls.IsGeneric());
  const intptr_t num_type_params = cls.NumTypeParameters();
  bool trivial_case =
      (num_type_params ==
       Class::Handle(static_type.type_class()).NumTypeParameters()) &&
      (value.GetTypeArguments() == static_type.arguments());
  if (!trivial_case && FLAG_trace_field_guards) {
    THR_Print("Not a simple case: %" Pd " vs %" Pd
              " type parameters, %s vs %s type arguments\n",
              num_type_params,
              Class::Handle(static_type.type_class()).NumTypeParameters(),
              SafeTypeArgumentsToCString(
                  TypeArguments::Handle(value.GetTypeArguments())),
              SafeTypeArgumentsToCString(static_type_args));
  }

  AbstractType& type_arg = AbstractType::Handle();
  args = type.arguments();
  for (intptr_t i = 0; (i < num_type_params) && trivial_case; i++) {
    type_arg = args.TypeAt(i);
    if (!type_arg.IsTypeParameter() ||
        (TypeParameter::Cast(type_arg).index() != i)) {
      if (FLAG_trace_field_guards) {
        THR_Print("  => encountered %s at index % " Pd "\n",
                  type_arg.ToCString(), i);
      }
      trivial_case = false;
    }
  }

  return trivial_case ? TrivialTypeExactnessFor(cls)
                      : StaticTypeExactnessState::NotExact();
}

const char* StaticTypeExactnessState::ToCString() const {
  if (!IsTracking()) {
    return "not-tracking";
  } else if (!IsExactOrUninitialized()) {
    return "not-exact";
  } else if (IsTriviallyExact()) {
    return Thread::Current()->zone()->PrintToString(
        "trivially-exact(%hhu)", GetTypeArgumentsOffsetInWords());
  } else if (IsHasExactSuperType()) {
    return "has-exact-super-type";
  } else if (IsHasExactSuperClass()) {
    return "has-exact-super-class";
  } else {
    ASSERT(IsUninitialized());
    return "uninitialized-exactness";
  }
}

bool Field::UpdateGuardedExactnessState(const Object& value) const {
  if (!static_type_exactness_state().IsExactOrUninitialized()) {
    // Nothing to update.
    return false;
  }

  if (guarded_cid() == kDynamicCid) {
    if (FLAG_trace_field_guards) {
      THR_Print(
          "  => switching off exactness tracking because guarded cid is "
          "dynamic\n");
    }
    set_static_type_exactness_state(StaticTypeExactnessState::NotExact());
    return true;  // Invalidate.
  }

  // If we are storing null into a field or we have an exact super type
  // then there is nothing to do.
  if (value.IsNull() || static_type_exactness_state().IsHasExactSuperType() ||
      static_type_exactness_state().IsHasExactSuperClass()) {
    return false;
  }

  // If we are storing a non-null value into a field that is considered
  // to be trivially exact then we need to check if value has an appropriate
  // type.
  ASSERT(guarded_cid() != kNullCid);

  const Type& field_type = Type::Cast(AbstractType::Handle(type()));
  const TypeArguments& field_type_args =
      TypeArguments::Handle(field_type.arguments());

  const Instance& instance = Instance::Cast(value);
  TypeArguments& args = TypeArguments::Handle();
  if (static_type_exactness_state().IsTriviallyExact()) {
    args = instance.GetTypeArguments();
    if (args.raw() == field_type_args.raw()) {
      return false;
    }

    if (FLAG_trace_field_guards) {
      THR_Print("  expected %s got %s type arguments\n",
                field_type_args.ToCString(), args.ToCString());
    }

    set_static_type_exactness_state(StaticTypeExactnessState::NotExact());
    return true;
  }

  ASSERT(static_type_exactness_state().IsUninitialized());
  set_static_type_exactness_state(StaticTypeExactnessState::Compute(
      field_type, instance, FLAG_trace_field_guards));
  return true;
}

void Field::RecordStore(const Object& value) const {
  ASSERT(IsOriginal());
  if (!Isolate::Current()->use_field_guards()) {
    return;
  }

  // We should never try to record a sentinel.
  ASSERT(value.raw() != Object::sentinel().raw());

  Thread* const thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if ((guarded_cid() == kDynamicCid) ||
      (is_nullable() && value.raw() == Object::null())) {
    // Nothing to do: the field is not guarded or we are storing null into
    // a nullable field.
    return;
  }

  if (FLAG_trace_field_guards) {
    THR_Print("Store %s %s <- %s\n", ToCString(), GuardedPropertiesAsCString(),
              value.ToCString());
  }

  bool invalidate = false;
  if (UpdateGuardedCidAndLength(value)) {
    invalidate = true;
  }
  if (UpdateGuardedExactnessState(value)) {
    invalidate = true;
  }

  if (invalidate) {
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
  if (static_type_exactness_state().IsTracking()) {
    set_static_type_exactness_state(StaticTypeExactnessState::NotExact());
  }
  // Drop any code that relied on the above assumptions.
  DeoptimizeDependentCode();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void Field::set_type_test_cache(const SubtypeTestCache& cache) const {
  raw_ptr()->set_type_test_cache(cache.raw());
}
#endif

bool Script::HasSource() const {
  return raw_ptr()->source() != String::null();
}

StringPtr Script::Source() const {
  return raw_ptr()->source();
}

bool Script::IsPartOfDartColonLibrary() const {
  const String& script_url = String::Handle(url());
  return (script_url.StartsWith(Symbols::DartScheme()) ||
          script_url.StartsWith(Symbols::DartSchemePrivate()));
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void Script::LoadSourceFromKernel(const uint8_t* kernel_buffer,
                                  intptr_t kernel_buffer_len) const {
  String& uri = String::Handle(resolved_url());
  String& source = String::Handle(kernel::KernelLoader::FindSourceForScript(
      kernel_buffer, kernel_buffer_len, uri));
  set_source(source);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void Script::set_compile_time_constants(const Array& value) const {
  raw_ptr()->set_compile_time_constants(value.raw());
}

void Script::set_kernel_program_info(const KernelProgramInfo& info) const {
  raw_ptr()->set_kernel_program_info(info.raw());
}

void Script::set_kernel_script_index(const intptr_t kernel_script_index) const {
  StoreNonPointer(&raw_ptr()->kernel_script_index_, kernel_script_index);
}

TypedDataPtr Script::kernel_string_offsets() const {
  KernelProgramInfo& program_info =
      KernelProgramInfo::Handle(kernel_program_info());
  ASSERT(!program_info.IsNull());
  return program_info.string_offsets();
}

void Script::LookupSourceAndLineStarts(Zone* zone) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (!IsLazyLookupSourceAndLineStarts()) {
    return;
  }
  const String& uri = String::Handle(zone, resolved_url());
  ASSERT(uri.IsSymbol());
  if (uri.Length() > 0) {
    // Entry included only to provide URI - actual source should already exist
    // in the VM, so try to find it.
    Library& lib = Library::Handle(zone);
    Script& script = Script::Handle(zone);
    const GrowableObjectArray& libs = GrowableObjectArray::Handle(
        zone, Isolate::Current()->object_store()->libraries());
    for (intptr_t i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      script = lib.LookupScript(uri, /* useResolvedUri = */ true);
      if (!script.IsNull()) {
        const auto& source = String::Handle(zone, script.Source());
        const auto& starts = TypedData::Handle(zone, script.line_starts());
        if (!source.IsNull() || !starts.IsNull()) {
          set_source(source);
          set_line_starts(starts);
          break;
        }
      }
    }
  }
  SetLazyLookupSourceAndLineStarts(false);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

GrowableObjectArrayPtr Script::GenerateLineNumberArray() const {
  Zone* zone = Thread::Current()->zone();
  const GrowableObjectArray& info =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const Object& line_separator = Object::Handle(zone);
  LookupSourceAndLineStarts(zone);
  if (line_starts() == TypedData::null()) {
    // Scripts in the AOT snapshot do not have a line starts array.
    // A well-formed line number array has a leading null.
    info.Add(line_separator);  // New line.
    return info.raw();
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  Smi& value = Smi::Handle(zone);
  const TypedData& line_starts_data = TypedData::Handle(zone, line_starts());
  intptr_t line_count = line_starts_data.Length();
  const Array& debug_positions_array = Array::Handle(debug_positions());
  intptr_t token_count = debug_positions_array.Length();
  int token_index = 0;

  kernel::KernelLineStartsReader line_starts_reader(line_starts_data, zone);
  intptr_t previous_start = 0;
  for (int line_index = 0; line_index < line_count; ++line_index) {
    intptr_t start = previous_start + line_starts_reader.DeltaAt(line_index);
    // Output the rest of the tokens if we have no next line.
    intptr_t end = TokenPosition::kMaxSourcePos;
    if (line_index + 1 < line_count) {
      end = start + line_starts_reader.DeltaAt(line_index + 1);
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
    previous_start = start;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return info.raw();
}

TokenPosition Script::MaxPosition() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (HasCachedMaxPosition()) {
    return TokenPosition::Deserialize(
        ScriptLayout::CachedMaxPositionBitField::decode(
            raw_ptr()->flags_and_max_position_));
  }
  auto const zone = Thread::Current()->zone();
  LookupSourceAndLineStarts(zone);
  if (!HasCachedMaxPosition() && line_starts() != TypedData::null()) {
    const auto& starts = TypedData::Handle(zone, line_starts());
    kernel::KernelLineStartsReader reader(starts, zone);
    const intptr_t max_position = reader.MaxPosition();
    SetCachedMaxPosition(max_position);
    SetHasCachedMaxPosition(true);
    return TokenPosition::Deserialize(max_position);
  }
#endif
  return TokenPosition::kNoSource;
}

void Script::set_url(const String& value) const {
  raw_ptr()->set_url(value.raw());
}

void Script::set_resolved_url(const String& value) const {
  raw_ptr()->set_resolved_url(value.raw());
}

void Script::set_source(const String& value) const {
  raw_ptr()->set_source(value.raw());
}

void Script::set_line_starts(const TypedData& value) const {
  raw_ptr()->set_line_starts(value.raw());
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
void Script::set_constant_coverage(const ExternalTypedData& value) const {
  raw_ptr()->set_constant_coverage(value.raw());
}

ExternalTypedDataPtr Script::constant_coverage() const {
  return raw_ptr()->constant_coverage();
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

void Script::set_debug_positions(const Array& value) const {
  raw_ptr()->set_debug_positions(value.raw());
}

TypedDataPtr Script::line_starts() const {
  return raw_ptr()->line_starts();
}

ArrayPtr Script::debug_positions() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Array& debug_positions_array = Array::Handle(raw_ptr()->debug_positions());
  if (debug_positions_array.IsNull()) {
    // This is created lazily. Now we need it.
    kernel::CollectTokenPositionsFor(*this);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  return raw_ptr()->debug_positions();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void Script::SetLazyLookupSourceAndLineStarts(bool value) const {
  StoreNonPointer(&raw_ptr()->flags_and_max_position_,
                  ScriptLayout::LazyLookupSourceAndLineStartsBit::update(
                      value, raw_ptr()->flags_and_max_position_));
}

bool Script::IsLazyLookupSourceAndLineStarts() const {
  return ScriptLayout::LazyLookupSourceAndLineStartsBit::decode(
      raw_ptr()->flags_and_max_position_);
}

bool Script::HasCachedMaxPosition() const {
  return ScriptLayout::HasCachedMaxPositionBit::decode(
      raw_ptr()->flags_and_max_position_);
}

void Script::SetHasCachedMaxPosition(bool value) const {
  StoreNonPointer(&raw_ptr()->flags_and_max_position_,
                  ScriptLayout::HasCachedMaxPositionBit::update(
                      value, raw_ptr()->flags_and_max_position_));
}

void Script::SetCachedMaxPosition(intptr_t value) const {
  StoreNonPointer(&raw_ptr()->flags_and_max_position_,
                  ScriptLayout::CachedMaxPositionBitField::update(
                      value, raw_ptr()->flags_and_max_position_));
}
#endif

void Script::set_load_timestamp(int64_t value) const {
  StoreNonPointer(&raw_ptr()->load_timestamp_, value);
}

void Script::SetLocationOffset(intptr_t line_offset,
                               intptr_t col_offset) const {
  ASSERT(line_offset >= 0);
  ASSERT(col_offset >= 0);
  StoreNonPointer(&raw_ptr()->line_offset_, line_offset);
  StoreNonPointer(&raw_ptr()->col_offset_, col_offset);
}

bool Script::IsValidTokenPosition(TokenPosition token_pos) const {
  const TokenPosition& max_position = MaxPosition();
  // We may end up with scripts that have the empty string as a source file
  // in testing and the like, so allow any token position when the max position
  // is 0 as well as when it is kNoSource.
  return !max_position.IsReal() || !token_pos.IsReal() ||
         max_position.Pos() == 0 || token_pos <= max_position;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static bool IsLetter(int32_t c) {
  return (('A' <= c) && (c <= 'Z')) || (('a' <= c) && (c <= 'z'));
}

static bool IsDecimalDigit(int32_t c) {
  return '0' <= c && c <= '9';
}

static bool IsIdentStartChar(int32_t c) {
  return IsLetter(c) || (c == '_') || (c == '$');
}

static bool IsIdentChar(int32_t c) {
  return IsLetter(c) || IsDecimalDigit(c) || (c == '_') || (c == '$');
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

bool Script::GetTokenLocation(const TokenPosition& token_pos,
                              intptr_t* line,
                              intptr_t* column) const {
  ASSERT(line != nullptr);
#if defined(DART_PRECOMPILED_RUNTIME)
  // Scripts in the AOT snapshot do not have a line starts array.
  return false;
#else
  if (!token_pos.IsReal()) return false;

  auto const zone = Thread::Current()->zone();
  LookupSourceAndLineStarts(zone);
  const TypedData& line_starts_data = TypedData::Handle(zone, line_starts());
  if (line_starts_data.IsNull()) return false;
  kernel::KernelLineStartsReader line_starts_reader(line_starts_data, zone);
  return line_starts_reader.LocationForPosition(token_pos.Pos(), line, column);
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

intptr_t Script::GetTokenLength(const TokenPosition& token_pos) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  // Scripts in the AOT snapshot do not have their source.
  return -1;
#else
  if (!HasSource() || !token_pos.IsReal()) return -1;
  auto const zone = Thread::Current()->zone();
  LookupSourceAndLineStarts(zone);
  // We don't explicitly save this data: Load the source and find it from there.
  const String& source = String::Handle(zone, Source());
  const intptr_t start = token_pos.Pos();
  if (start >= source.Length()) return -1;  // Can't determine token_len.
  intptr_t end = start;
  if (IsIdentStartChar(source.CharAt(end++))) {
    for (; end < source.Length(); ++end) {
      if (!IsIdentChar(source.CharAt(end))) break;
    }
  }
  return end - start;
#endif
}

bool Script::TokenRangeAtLine(intptr_t line_number,
                              TokenPosition* first_token_index,
                              TokenPosition* last_token_index) const {
  ASSERT(first_token_index != nullptr && last_token_index != nullptr);
#if defined(DART_PRECOMPILED_RUNTIME)
  // Scripts in the AOT snapshot do not have a line starts array.
  return false;
#else
  // Line numbers are 1-indexed.
  if (line_number <= 0) return false;
  Zone* zone = Thread::Current()->zone();
  LookupSourceAndLineStarts(zone);
  const TypedData& line_starts_data = TypedData::Handle(zone, line_starts());
  kernel::KernelLineStartsReader line_starts_reader(line_starts_data, zone);
  if (!line_starts_reader.TokenRangeAtLine(line_number, first_token_index,
                                           last_token_index)) {
    return false;
  }
#if defined(DEBUG)
  intptr_t source_length;
  if (!HasSource()) {
    Smi& value = Smi::Handle(zone);
    const Array& debug_positions_array = Array::Handle(zone, debug_positions());
    value ^= debug_positions_array.At(debug_positions_array.Length() - 1);
    source_length = value.Value();
  } else {
    const String& source = String::Handle(zone, Source());
    source_length = source.Length();
  }
  ASSERT(last_token_index->Serialize() <= source_length);
#endif
  return true;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

// Returns the index in the given source string for the given (1-based) absolute
// line and column numbers. The line and column offsets are used to calculate
// the absolute line and column number for the starting index in the source.
//
// If the given line number is outside the range of lines represented by the
// source, the given column number invalid for the given line, or a negative
// starting index is given, a negative value is returned to indicate failure.
static intptr_t GetRelativeSourceIndex(const String& src,
                                       intptr_t line,
                                       intptr_t line_offset = 0,
                                       intptr_t column = 1,
                                       intptr_t column_offset = 0,
                                       intptr_t starting_index = 0) {
  if (starting_index < 0 || line < 1 || column < 1 || line <= line_offset ||
      (line == line_offset + 1 && column <= column_offset)) {
    return -1;
  }
  intptr_t len = src.Length();
  intptr_t current_line = line_offset + 1;
  intptr_t current_index = starting_index;
  for (; current_index < len; current_index++) {
    if (current_line == line) {
      break;
    }
    const uint16_t c = src.CharAt(current_index);
    if (c == '\n' || c == '\r') {
      current_line++;
    }
    if (c == '\r' && current_index + 1 < len &&
        src.CharAt(current_index + 1) == '\n') {
      // \r\n is treated as a single line terminator.
      current_index++;
    }
  }
  if (current_line != line) {
    return -1;
  }
  // Only adjust with column offset when still on the first line.
  intptr_t current_column = 1 + (line == line_offset + 1 ? column_offset : 0);
  for (; current_index < len; current_index++, current_column++) {
    if (current_column == column) {
      return current_index;
    }
    const uint16_t c = src.CharAt(current_index);
    if (c == '\n' || c == '\r') {
      break;
    }
  }
  // Check for a column value representing the source's end.
  if (current_column == column) {
    return current_index;
  }
  return -1;
}

StringPtr Script::GetLine(intptr_t line_number, Heap::Space space) const {
  if (!HasSource()) {
    return Symbols::OptimizedOut().raw();
  }
  const String& src = String::Handle(Source());
  const intptr_t start =
      GetRelativeSourceIndex(src, line_number, line_offset());
  if (start < 0) {
    return Symbols::Empty().raw();
  }
  intptr_t end = start;
  for (; end < src.Length(); end++) {
    const uint16_t c = src.CharAt(end);
    if (c == '\n' || c == '\r') {
      break;
    }
  }
  return String::SubString(src, start, end - start, space);
}

StringPtr Script::GetSnippet(intptr_t from_line,
                             intptr_t from_column,
                             intptr_t to_line,
                             intptr_t to_column) const {
  if (!HasSource()) {
    return Symbols::OptimizedOut().raw();
  }
  const String& src = String::Handle(Source());
  const intptr_t start = GetRelativeSourceIndex(src, from_line, line_offset(),
                                                from_column, col_offset());
  // Lines and columns are 1-based, so need to subtract one to get offsets.
  const intptr_t end = GetRelativeSourceIndex(
      src, to_line, from_line - 1, to_column, from_column - 1, start);
  // Only need to check end, because a negative start results in a negative end.
  if (end < 0) {
    return String::null();
  }
  return String::SubString(src, start, end - start);
}

ScriptPtr Script::New() {
  ASSERT(Object::script_class() != Class::null());
  ObjectPtr raw =
      Object::Allocate(Script::kClassId, Script::InstanceSize(), Heap::kOld);
  return static_cast<ScriptPtr>(raw);
}

ScriptPtr Script::New(const String& url, const String& source) {
  return Script::New(url, url, source);
}

ScriptPtr Script::New(const String& url,
                      const String& resolved_url,
                      const String& source) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Script& result = Script::Handle(zone, Script::New());
  result.set_url(String::Handle(zone, Symbols::New(thread, url)));
  result.set_resolved_url(
      String::Handle(zone, Symbols::New(thread, resolved_url)));
  result.set_source(source);
  result.SetLocationOffset(0, 0);
  NOT_IN_PRECOMPILED(result.SetLazyLookupSourceAndLineStarts(false));
  NOT_IN_PRECOMPILED(result.SetHasCachedMaxPosition(false));
  result.set_kernel_script_index(0);
  result.set_load_timestamp(
      FLAG_remove_script_timestamps_for_test ? 0 : OS::GetCurrentTimeMillis());
  return result.raw();
}

const char* Script::ToCString() const {
  const String& name = String::Handle(url());
  return OS::SCreate(Thread::Current()->zone(), "Script(%s)", name.ToCString());
}

LibraryPtr Script::FindLibrary() const {
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

ObjectPtr DictionaryIterator::GetNext() {
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

ClassPtr ClassDictionaryIterator::GetNextClass() {
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

static void ReportTooManyImports(const Library& lib) {
  const String& url = String::Handle(lib.url());
  Report::MessageF(Report::kError, Script::Handle(lib.LookupScript(url)),
                   TokenPosition::kNoSource, Report::AtLocation,
                   "too many imports in library '%s'", url.ToCString());
  UNREACHABLE();
}

bool Library::IsAnyCoreLibrary() const {
  String& url_str = Thread::Current()->StringHandle();
  url_str = url();
  return url_str.StartsWith(Symbols::DartScheme()) ||
         url_str.StartsWith(Symbols::DartSchemePrivate());
}

void Library::set_num_imports(intptr_t value) const {
  if (!Utils::IsUint(16, value)) {
    ReportTooManyImports(*this);
  }
  StoreNonPointer(&raw_ptr()->num_imports_, value);
}

void Library::set_name(const String& name) const {
  ASSERT(name.IsSymbol());
  raw_ptr()->set_name(name.raw());
}

void Library::set_url(const String& name) const {
  raw_ptr()->set_url(name.raw());
}

void Library::set_kernel_data(const ExternalTypedData& data) const {
  raw_ptr()->set_kernel_data(data.raw());
}

void Library::set_loading_unit(const LoadingUnit& value) const {
  raw_ptr()->set_loading_unit(value.raw());
}

void Library::SetName(const String& name) const {
  // Only set name once.
  ASSERT(!Loaded());
  set_name(name);
}

void Library::SetLoadInProgress() const {
  // Must not already be in the process of being loaded.
  ASSERT(raw_ptr()->load_state_ <= LibraryLayout::kLoadRequested);
  StoreNonPointer(&raw_ptr()->load_state_, LibraryLayout::kLoadInProgress);
}

void Library::SetLoadRequested() const {
  // Must not be already loaded.
  ASSERT(raw_ptr()->load_state_ == LibraryLayout::kAllocated);
  StoreNonPointer(&raw_ptr()->load_state_, LibraryLayout::kLoadRequested);
}

void Library::SetLoaded() const {
  // Should not be already loaded or just allocated.
  ASSERT(LoadInProgress() || LoadRequested());
  StoreNonPointer(&raw_ptr()->load_state_, LibraryLayout::kLoaded);
}

void Library::AddMetadata(const Object& declaration,
                          intptr_t kernel_offset) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  Thread* thread = Thread::Current();
  ASSERT(thread->isolate_group()->program_lock()->IsCurrentThreadWriter());

  MetadataMap map(metadata());
  map.UpdateOrInsert(declaration, Smi::Handle(Smi::New(kernel_offset)));
  set_metadata(map.Release());
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

ObjectPtr Library::GetMetadata(const Object& declaration) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Object::empty_array().raw();
#else
  RELEASE_ASSERT(declaration.IsClass() || declaration.IsField() ||
                 declaration.IsFunction() || declaration.IsLibrary() ||
                 declaration.IsTypeParameter() || declaration.IsNamespace());

  auto thread = Thread::Current();
  auto zone = thread->zone();

  if (declaration.IsLibrary()) {
    // Ensure top-level class is loaded as it may contain annotations of
    // a library.
    const auto& cls = Class::Handle(zone, toplevel_class());
    if (!cls.IsNull()) {
      cls.EnsureDeclarationLoaded();
    }
  }
  Object& value = Object::Handle(zone);
  {
    SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
    MetadataMap map(metadata());
    value = map.GetOrNull(declaration);
    set_metadata(map.Release());
  }
  if (value.IsNull()) {
    // There is no metadata for this object.
    return Object::empty_array().raw();
  }
  if (!value.IsSmi()) {
    // Metadata is already evaluated.
    ASSERT(value.IsArray());
    return value.raw();
  }
  const auto& smi_value = Smi::Cast(value);
  intptr_t kernel_offset = smi_value.Value();
  ASSERT(kernel_offset > 0);
  const auto& evaluated_value = Object::Handle(
      zone, kernel::EvaluateMetadata(
                *this, kernel_offset,
                /* is_annotations_offset = */ declaration.IsLibrary() ||
                    declaration.IsNamespace()));
  if (evaluated_value.IsArray() || evaluated_value.IsNull()) {
    ASSERT(evaluated_value.raw() != Object::empty_array().raw());
    SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
    MetadataMap map(metadata());
    if (map.GetOrNull(declaration) == smi_value.raw()) {
      map.UpdateOrInsert(declaration, evaluated_value);
    } else {
      ASSERT(map.GetOrNull(declaration) == evaluated_value.raw());
    }
    set_metadata(map.Release());
  }
  return evaluated_value.raw();
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

ObjectPtr Library::ResolveName(const String& name) const {
  Object& obj = Object::Handle();
  if (FLAG_use_lib_cache && LookupResolvedNamesCache(name, &obj)) {
    return obj.raw();
  }
  EnsureTopLevelClassIsFinalized();
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
  raw_ptr()->set_resolved_names(cache.Release().raw());
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
  raw_ptr()->set_exported_names(cache.Release().raw());
}

void Library::InvalidateResolvedName(const String& name) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Object& entry = Object::Handle(zone);
  if (FLAG_use_lib_cache && LookupResolvedNamesCache(name, &entry)) {
    // TODO(koda): Support deleted sentinel in snapshots and remove only 'name'.
    ClearResolvedNamesCache();
  }
  if (!FLAG_use_exp_cache) {
    return;
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
  raw_ptr()->set_dictionary(new_dict.raw());
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
    raw_ptr()->set_loaded_scripts(Array::null());
  }
}

// Lookup a name in the library's re-export namespace.
// This lookup can occur from two different threads: background compiler and
// mutator thread.
ObjectPtr Library::LookupReExport(const String& name,
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

ObjectPtr Library::LookupEntry(const String& name, intptr_t* index) const {
  ASSERT(!IsNull());
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Array& dict = thread->ArrayHandle();
  dict = dictionary();
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

ArrayPtr Library::LoadedScripts() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  // We compute the list of loaded scripts lazily. The result is
  // cached in loaded_scripts_.
  if (loaded_scripts() == Array::null()) {
    // TODO(jensj): This can be cleaned up.
    // It really should just return the content of `used_scripts`, and there
    // should be no need to do the O(n) call to `AddScriptIfUnique` per script.

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
    GrowableObjectArray& patches = GrowableObjectArray::Handle(used_scripts());
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

    cls = toplevel_class();
    if (!cls.IsNull()) {
      owner_script = cls.script();
      AddScriptIfUnique(scripts, owner_script);
      // Special case: Scripts that only contain external top-level functions
      // are not included above, but can be referenced through a library's
      // anonymous classes. Example: dart-core:identical.dart.
      Function& func = Function::Handle();
      Array& functions = Array::Handle(cls.current_functions());
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
    raw_ptr()->set_loaded_scripts(scripts_array.raw());
  }
  return loaded_scripts();
}

// TODO(hausner): we might want to add a script dictionary to the
// library class to make this lookup faster.
ScriptPtr Library::LookupScript(const String& url,
                                bool useResolvedUri /* = false */) const {
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
    if (useResolvedUri) {
      // Use for urls with 'org-dartlang-sdk:' or 'file:' schemes
      script_url = script.resolved_url();
    } else {
      // Use for urls with 'dart:', 'package:', or 'file:' schemes
      script_url = script.url();
    }
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

void Library::EnsureTopLevelClassIsFinalized() const {
  if (toplevel_class() == Object::null()) {
    return;
  }
  Thread* thread = Thread::Current();
  const Class& cls = Class::Handle(thread->zone(), toplevel_class());
  if (cls.is_finalized()) {
    return;
  }
  const Error& error =
      Error::Handle(thread->zone(), cls.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
}

ObjectPtr Library::LookupLocalObject(const String& name) const {
  intptr_t index;
  return LookupEntry(name, &index);
}

ObjectPtr Library::LookupLocalOrReExportObject(const String& name) const {
  intptr_t index;
  EnsureTopLevelClassIsFinalized();
  const Object& result = Object::Handle(LookupEntry(name, &index));
  if (!result.IsNull() && !result.IsLibraryPrefix()) {
    return result.raw();
  }
  return LookupReExport(name);
}

FieldPtr Library::LookupFieldAllowPrivate(const String& name) const {
  EnsureTopLevelClassIsFinalized();
  Object& obj = Object::Handle(LookupObjectAllowPrivate(name));
  if (obj.IsField()) {
    return Field::Cast(obj).raw();
  }
  return Field::null();
}

FieldPtr Library::LookupLocalField(const String& name) const {
  EnsureTopLevelClassIsFinalized();
  Object& obj = Object::Handle(LookupLocalObjectAllowPrivate(name));
  if (obj.IsField()) {
    return Field::Cast(obj).raw();
  }
  return Field::null();
}

FunctionPtr Library::LookupFunctionAllowPrivate(const String& name) const {
  EnsureTopLevelClassIsFinalized();
  Object& obj = Object::Handle(LookupObjectAllowPrivate(name));
  if (obj.IsFunction()) {
    return Function::Cast(obj).raw();
  }
  return Function::null();
}

FunctionPtr Library::LookupLocalFunction(const String& name) const {
  EnsureTopLevelClassIsFinalized();
  Object& obj = Object::Handle(LookupLocalObjectAllowPrivate(name));
  if (obj.IsFunction()) {
    return Function::Cast(obj).raw();
  }
  return Function::null();
}

ObjectPtr Library::LookupLocalObjectAllowPrivate(const String& name) const {
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

ObjectPtr Library::LookupObjectAllowPrivate(const String& name) const {
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

ObjectPtr Library::LookupImportedObject(const String& name) const {
  Object& obj = Object::Handle();
  Namespace& import = Namespace::Handle();
  Library& import_lib = Library::Handle();
  String& import_lib_url = String::Handle();
  String& first_import_lib_url = String::Handle();
  Object& found_obj = Object::Handle();
  String& found_obj_name = String::Handle();
  ASSERT(!ShouldBePrivate(name));
  for (intptr_t i = 0; i < num_imports(); i++) {
    import = ImportAt(i);
    obj = import.Lookup(name);
    if (!obj.IsNull()) {
      import_lib = import.target();
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

ClassPtr Library::LookupClass(const String& name) const {
  Object& obj = Object::Handle(LookupLocalObject(name));
  if (obj.IsNull() && !ShouldBePrivate(name)) {
    obj = LookupImportedObject(name);
  }
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  return Class::null();
}

ClassPtr Library::LookupLocalClass(const String& name) const {
  Object& obj = Object::Handle(LookupLocalObject(name));
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  return Class::null();
}

ClassPtr Library::LookupClassAllowPrivate(const String& name) const {
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
ClassPtr Library::SlowLookupClassAllowMultiPartPrivate(
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

LibraryPrefixPtr Library::LookupLocalLibraryPrefix(const String& name) const {
  const Object& obj = Object::Handle(LookupLocalObject(name));
  if (obj.IsLibraryPrefix()) {
    return LibraryPrefix::Cast(obj).raw();
  }
  return LibraryPrefix::null();
}

void Library::set_toplevel_class(const Class& value) const {
  ASSERT(raw_ptr()->toplevel_class() == Class::null());
  raw_ptr()->set_toplevel_class(value.raw());
}

void Library::set_dependencies(const Array& deps) const {
  raw_ptr()->set_dependencies(deps.raw());
}

void Library::set_metadata(const Array& value) const {
  if (raw_ptr()->metadata() != value.raw()) {
    DEBUG_ASSERT(
        IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
    raw_ptr()->set_metadata(value.raw());
  }
}

LibraryPtr Library::ImportLibraryAt(intptr_t index) const {
  Namespace& import = Namespace::Handle(ImportAt(index));
  if (import.IsNull()) {
    return Library::null();
  }
  return import.target();
}

NamespacePtr Library::ImportAt(intptr_t index) const {
  if ((index < 0) || index >= num_imports()) {
    return Namespace::null();
  }
  const Array& import_list = Array::Handle(imports());
  return Namespace::RawCast(import_list.At(index));
}

void Library::DropDependenciesAndCaches() const {
  // We need to preserve the "dart-ext:" imports because they are used by
  // Loader::ReloadNativeExtensions().
  intptr_t native_import_count = 0;
  Array& imports = Array::Handle(raw_ptr()->imports());
  Namespace& ns = Namespace::Handle();
  Library& lib = Library::Handle();
  String& url = String::Handle();
  for (int i = 0; i < imports.Length(); ++i) {
    ns = Namespace::RawCast(imports.At(i));
    if (ns.IsNull()) continue;
    lib = ns.target();
    url = lib.url();
    if (url.StartsWith(Symbols::DartExtensionScheme())) {
      native_import_count++;
    }
  }
  Array& new_imports =
      Array::Handle(Array::New(native_import_count, Heap::kOld));
  for (int i = 0, j = 0; i < imports.Length(); ++i) {
    ns = Namespace::RawCast(imports.At(i));
    if (ns.IsNull()) continue;
    lib = ns.target();
    url = lib.url();
    if (url.StartsWith(Symbols::DartExtensionScheme())) {
      new_imports.SetAt(j++, ns);
    }
  }

  raw_ptr()->set_imports(new_imports.raw());
  raw_ptr()->set_exports(Object::empty_array().raw());
  StoreNonPointer(&raw_ptr()->num_imports_, 0);
  raw_ptr()->set_resolved_names(Array::null());
  raw_ptr()->set_exported_names(Array::null());
  raw_ptr()->set_loaded_scripts(Array::null());
  raw_ptr()->set_dependencies(Array::null());
}

void Library::AddImport(const Namespace& ns) const {
  Array& imports = Array::Handle(this->imports());
  intptr_t capacity = imports.Length();
  if (num_imports() == capacity) {
    capacity = capacity + kImportsCapacityIncrement + (capacity >> 2);
    imports = Array::Grow(imports, capacity);
    raw_ptr()->set_imports(imports.raw());
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
  raw_ptr()->set_exports(exports.raw());
  exports.SetAt(num_exports, ns);
}

static ArrayPtr NewDictionary(intptr_t initial_size) {
  const Array& dict = Array::Handle(Array::New(initial_size + 1, Heap::kOld));
  // The last element of the dictionary specifies the number of in use slots.
  dict.SetAt(initial_size, Object::smi_zero());
  return dict.raw();
}

void Library::InitResolvedNamesCache() const {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  Array& cache = thread->ArrayHandle();
  cache = HashTables::New<ResolvedNamesMap>(64);
  raw_ptr()->set_resolved_names(cache.raw());
}

void Library::ClearResolvedNamesCache() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  raw_ptr()->set_resolved_names(Array::null());
}

void Library::InitExportedNamesCache() const {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  Array& cache = thread->ArrayHandle();
  cache = HashTables::New<ResolvedNamesMap>(16);
  raw_ptr()->set_exported_names(cache.raw());
}

void Library::ClearExportedNamesCache() const {
  raw_ptr()->set_exported_names(Array::null());
}

void Library::InitClassDictionary() const {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  REUSABLE_FUNCTION_HANDLESCOPE(thread);
  Array& dictionary = thread->ArrayHandle();
  // TODO(iposva): Find reasonable initial size.
  const int kInitialElementCount = 16;
  dictionary = NewDictionary(kInitialElementCount);
  raw_ptr()->set_dictionary(dictionary.raw());
}

void Library::InitImportList() const {
  const Array& imports =
      Array::Handle(Array::New(kInitialImportsCapacity, Heap::kOld));
  raw_ptr()->set_imports(imports.raw());
  StoreNonPointer(&raw_ptr()->num_imports_, 0);
}

LibraryPtr Library::New() {
  ASSERT(Object::library_class() != Class::null());
  ObjectPtr raw =
      Object::Allocate(Library::kClassId, Library::InstanceSize(), Heap::kOld);
  return static_cast<LibraryPtr>(raw);
}

LibraryPtr Library::NewLibraryHelper(const String& url, bool import_core_lib) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());
  // Force the url to have a hash code.
  url.Hash();
  const bool dart_scheme = url.StartsWith(Symbols::DartScheme());
  const Library& result = Library::Handle(zone, Library::New());
  result.raw_ptr()->set_name(Symbols::Empty().raw());
  result.raw_ptr()->set_url(url.raw());
  result.raw_ptr()->set_resolved_names(Array::null());
  result.raw_ptr()->set_exported_names(Array::null());
  result.raw_ptr()->set_dictionary(Object::empty_array().raw());
  Array& array = Array::Handle(zone);
  array = HashTables::New<MetadataMap>(4, Heap::kOld);
  result.raw_ptr()->set_metadata(array.raw());
  result.raw_ptr()->set_toplevel_class(Class::null());
  GrowableObjectArray& list = GrowableObjectArray::Handle(zone);
  list = GrowableObjectArray::New(Object::empty_array(), Heap::kOld);
  result.raw_ptr()->set_used_scripts(list.raw());
  result.raw_ptr()->set_imports(Object::empty_array().raw());
  result.raw_ptr()->set_exports(Object::empty_array().raw());
  result.raw_ptr()->set_loaded_scripts(Array::null());
  result.set_native_entry_resolver(NULL);
  result.set_native_entry_symbol_resolver(NULL);
  result.set_flags(0);
  result.set_is_in_fullsnapshot(false);
  result.set_is_nnbd(false);
  if (dart_scheme) {
    // Only debug dart: libraries if we have been requested to show invisible
    // frames.
    result.set_debuggable(FLAG_show_invisible_frames);
  } else {
    // Default to debuggable for all other libraries.
    result.set_debuggable(true);
  }
  result.set_is_dart_scheme(dart_scheme);
  NOT_IN_PRECOMPILED(result.set_kernel_offset(0));
  result.StoreNonPointer(&result.raw_ptr()->load_state_,
                         LibraryLayout::kAllocated);
  result.StoreNonPointer(&result.raw_ptr()->index_, -1);
  result.InitClassDictionary();
  result.InitImportList();
  result.AllocatePrivateKey();
  if (import_core_lib) {
    const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());
    ASSERT(!core_lib.IsNull());
    const Namespace& ns =
        Namespace::Handle(zone, Namespace::New(core_lib, Object::null_array(),
                                               Object::null_array(), result));
    result.AddImport(ns);
  }
  return result.raw();
}

LibraryPtr Library::New(const String& url) {
  return NewLibraryHelper(url, false);
}

void Library::set_flags(uint8_t flags) const {
  StoreNonPointer(&raw_ptr()->flags_, flags);
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
}

// Invoke the function, or noSuchMethod if it is null.
static ObjectPtr InvokeInstanceFunction(
    Thread* thread,
    const Instance& receiver,
    const Function& function,
    const String& target_name,
    const Array& args,
    const Array& args_descriptor_array,
    bool respect_reflectable,
    const TypeArguments& instantiator_type_args) {
  // Note "args" is already the internal arguments with the receiver as the
  // first element.
  ArgumentsDescriptor args_descriptor(args_descriptor_array);
  if (function.IsNull() ||
      !function.AreValidArguments(args_descriptor, nullptr) ||
      (respect_reflectable && !function.is_reflectable())) {
    return DartEntry::InvokeNoSuchMethod(thread, receiver, target_name, args,
                                         args_descriptor_array);
  }
  ObjectPtr type_error = function.DoArgumentTypesMatch(args, args_descriptor,
                                                       instantiator_type_args);
  if (type_error != Error::null()) {
    return type_error;
  }
  return DartEntry::InvokeFunction(function, args, args_descriptor_array);
}

ObjectPtr Library::InvokeGetter(const String& getter_name,
                                bool throw_nsm_if_absent,
                                bool respect_reflectable,
                                bool check_is_entrypoint) const {
  Object& obj = Object::Handle(LookupLocalOrReExportObject(getter_name));
  Function& getter = Function::Handle();
  if (obj.IsField()) {
    const Field& field = Field::Cast(obj);
    if (check_is_entrypoint) {
      CHECK_ERROR(field.VerifyEntryPoint(EntryPointPragma::kGetterOnly));
    }
    if (!field.IsUninitialized()) {
      return field.StaticValue();
    }
    // An uninitialized field was found.  Check for a getter in the field's
    // owner class.
    const Class& klass = Class::Handle(field.Owner());
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = klass.LookupStaticFunction(internal_getter_name);
  } else {
    // No field found. Check for a getter in the lib.
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    obj = LookupLocalOrReExportObject(internal_getter_name);
    if (obj.IsFunction()) {
      getter = Function::Cast(obj).raw();
      if (check_is_entrypoint) {
        CHECK_ERROR(getter.VerifyCallEntryPoint());
      }
    } else {
      obj = LookupLocalOrReExportObject(getter_name);
      // Normally static top-level methods cannot be closurized through the
      // native API even if they are marked as entry-points, with the one
      // exception of "main".
      if (obj.IsFunction() && check_is_entrypoint) {
        if (!getter_name.Equals(String::Handle(String::New("main"))) ||
            raw() != Isolate::Current()->object_store()->root_library()) {
          CHECK_ERROR(Function::Cast(obj).VerifyClosurizedEntryPoint());
        }
      }
      if (obj.IsFunction() && Function::Cast(obj).SafeToClosurize()) {
        // Looking for a getter but found a regular method: closurize it.
        const Function& closure_function =
            Function::Handle(Function::Cast(obj).ImplicitClosureFunction());
        return closure_function.ImplicitStaticClosure();
      }
    }
  }

  if (getter.IsNull() || (respect_reflectable && !getter.is_reflectable())) {
    if (throw_nsm_if_absent) {
      return ThrowNoSuchMethod(
          AbstractType::Handle(Class::Handle(toplevel_class()).RareType()),
          getter_name, Object::null_array(), Object::null_array(),
          InvocationMirror::kTopLevel, InvocationMirror::kGetter);
    }

    // Fall through case: Indicate that we didn't find any function or field
    // using a special null instance. This is different from a field being null.
    // Callers make sure that this null does not leak into Dartland.
    return Object::sentinel().raw();
  }

  // Invoke the getter and return the result.
  return DartEntry::InvokeFunction(getter, Object::empty_array());
}

ObjectPtr Library::InvokeSetter(const String& setter_name,
                                const Instance& value,
                                bool respect_reflectable,
                                bool check_is_entrypoint) const {
  Object& obj = Object::Handle(LookupLocalOrReExportObject(setter_name));
  const String& internal_setter_name =
      String::Handle(Field::SetterName(setter_name));
  AbstractType& setter_type = AbstractType::Handle();
  AbstractType& argument_type = AbstractType::Handle(value.GetType(Heap::kOld));
  if (obj.IsField()) {
    const Field& field = Field::Cast(obj);
    if (check_is_entrypoint) {
      CHECK_ERROR(field.VerifyEntryPoint(EntryPointPragma::kSetterOnly));
    }
    setter_type = field.type();
    if (!argument_type.IsNullType() && !setter_type.IsDynamicType() &&
        !value.IsInstanceOf(setter_type, Object::null_type_arguments(),
                            Object::null_type_arguments())) {
      return ThrowTypeError(field.token_pos(), value, setter_type, setter_name);
    }
    if (field.is_final() || (respect_reflectable && !field.is_reflectable())) {
      const int kNumArgs = 1;
      const Array& args = Array::Handle(Array::New(kNumArgs));
      args.SetAt(0, value);

      return ThrowNoSuchMethod(
          AbstractType::Handle(Class::Handle(toplevel_class()).RareType()),
          internal_setter_name, args, Object::null_array(),
          InvocationMirror::kTopLevel, InvocationMirror::kSetter);
    }
    field.SetStaticValue(value);
    return value.raw();
  }

  Function& setter = Function::Handle();
  obj = LookupLocalOrReExportObject(internal_setter_name);
  if (obj.IsFunction()) {
    setter ^= obj.raw();
  }

  if (!setter.IsNull() && check_is_entrypoint) {
    CHECK_ERROR(setter.VerifyCallEntryPoint());
  }

  const int kNumArgs = 1;
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, value);
  if (setter.IsNull() || (respect_reflectable && !setter.is_reflectable())) {
    return ThrowNoSuchMethod(
        AbstractType::Handle(Class::Handle(toplevel_class()).RareType()),
        internal_setter_name, args, Object::null_array(),
        InvocationMirror::kTopLevel, InvocationMirror::kSetter);
  }

  setter_type = setter.ParameterTypeAt(0);
  if (!argument_type.IsNullType() && !setter_type.IsDynamicType() &&
      !value.IsInstanceOf(setter_type, Object::null_type_arguments(),
                          Object::null_type_arguments())) {
    return ThrowTypeError(setter.token_pos(), value, setter_type, setter_name);
  }

  return DartEntry::InvokeFunction(setter, args);
}

ObjectPtr Library::Invoke(const String& function_name,
                          const Array& args,
                          const Array& arg_names,
                          bool respect_reflectable,
                          bool check_is_entrypoint) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  // We don't pass any explicit type arguments, which will be understood as
  // using dynamic for any function type arguments by lower layers.
  const int kTypeArgsLen = 0;
  const Array& args_descriptor_array = Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length(),
                                          arg_names, Heap::kNew));
  ArgumentsDescriptor args_descriptor(args_descriptor_array);

  auto& function = Function::Handle(zone);
  auto& result =
      Object::Handle(zone, LookupLocalOrReExportObject(function_name));
  if (result.IsFunction()) {
    function ^= result.raw();
  }

  if (!function.IsNull() && check_is_entrypoint) {
    CHECK_ERROR(function.VerifyCallEntryPoint());
  }

  if (function.IsNull()) {
    // Didn't find a method: try to find a getter and invoke call on its result.
    const Object& getter_result = Object::Handle(
        zone, InvokeGetter(function_name, false, respect_reflectable,
                           check_is_entrypoint));
    if (getter_result.raw() != Object::sentinel().raw()) {
      if (check_is_entrypoint) {
        CHECK_ERROR(EntryPointFieldInvocationError(function_name));
      }
      const auto& call_args_descriptor_array = Array::Handle(
          zone, ArgumentsDescriptor::NewBoxed(args_descriptor.TypeArgsLen(),
                                              args_descriptor.Count() + 1,
                                              arg_names, Heap::kNew));
      const auto& call_args = Array::Handle(
          zone,
          CreateCallableArgumentsFromStatic(zone, Instance::Cast(getter_result),
                                            args, arg_names, args_descriptor));
      return DartEntry::InvokeClosure(thread, call_args,
                                      call_args_descriptor_array);
    }
  }

  if (function.IsNull() ||
      !function.AreValidArguments(args_descriptor, nullptr) ||
      (respect_reflectable && !function.is_reflectable())) {
    return ThrowNoSuchMethod(
        AbstractType::Handle(zone,
                             Class::Handle(zone, toplevel_class()).RareType()),
        function_name, args, arg_names, InvocationMirror::kTopLevel,
        InvocationMirror::kMethod);
  }
  // This is a static function, so we pass an empty instantiator tav.
  ASSERT(function.is_static());
  ObjectPtr type_error = function.DoArgumentTypesMatch(
      args, args_descriptor, Object::empty_type_arguments());
  if (type_error != Error::null()) {
    return type_error;
  }
  return DartEntry::InvokeFunction(function, args, args_descriptor_array);
}

ObjectPtr Library::EvaluateCompiledExpression(
    const ExternalTypedData& kernel_buffer,
    const Array& type_definitions,
    const Array& arguments,
    const TypeArguments& type_arguments) const {
  return EvaluateCompiledExpressionHelper(
      kernel_buffer, type_definitions, String::Handle(url()), String::Handle(),
      arguments, type_arguments);
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
    Utils::SNPrint(name_buffer, kNameLength, "%s%d", kNativeWrappersClass,
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

  static ObjectPtr NewKey(const String& str) { return str.raw(); }
};
typedef UnorderedHashMap<LibraryLookupTraits> LibraryLookupMap;

static ObjectPtr EvaluateCompiledExpressionHelper(
    const ExternalTypedData& kernel_buffer,
    const Array& type_definitions,
    const String& library_url,
    const String& klass,
    const Array& arguments,
    const TypeArguments& type_arguments) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
#if defined(DART_PRECOMPILED_RUNTIME)
  const String& error_str = String::Handle(
      zone,
      String::New("Expression evaluation not available in precompiled mode."));
  return ApiError::New(error_str);
#else
  std::unique_ptr<kernel::Program> kernel_pgm =
      kernel::Program::ReadFromTypedData(kernel_buffer);

  if (kernel_pgm == NULL) {
    return ApiError::New(String::Handle(
        zone, String::New("Kernel isolate returned ill-formed kernel.")));
  }

  kernel::KernelLoader loader(kernel_pgm.get(),
                              /*uri_to_source_table=*/nullptr);
  auto& result = Object::Handle(
      zone, loader.LoadExpressionEvaluationFunction(library_url, klass));
  kernel_pgm.reset();

  if (result.IsError()) return result.raw();

  const auto& callee = Function::CheckedHandle(zone, result.raw());

  // type_arguments is null if all type arguments are dynamic.
  if (type_definitions.Length() == 0 || type_arguments.IsNull()) {
    result = DartEntry::InvokeFunction(callee, arguments);
  } else {
    intptr_t num_type_args = type_arguments.Length();
    Array& real_arguments =
        Array::Handle(zone, Array::New(arguments.Length() + 1));
    real_arguments.SetAt(0, type_arguments);
    Object& arg = Object::Handle(zone);
    for (intptr_t i = 0; i < arguments.Length(); ++i) {
      arg = arguments.At(i);
      real_arguments.SetAt(i + 1, arg);
    }

    const Array& args_desc =
        Array::Handle(zone, ArgumentsDescriptor::NewBoxed(
                                num_type_args, arguments.Length(), Heap::kNew));
    result = DartEntry::InvokeFunction(callee, real_arguments, args_desc);
  }

  return result.raw();
#endif
}

// Returns library with given url in current isolate, or NULL.
LibraryPtr Library::LookupLibrary(Thread* thread, const String& url) {
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
  if (isolate->group()->IsReloading()) {
    // When reloading, we need to make sure we use the original private key
    // if this library previously existed.
    IsolateReloadContext* reload_context = isolate->reload_context();
    const String& original_key =
        String::Handle(reload_context->FindLibraryPrivateKey(*this));
    if (!original_key.IsNull()) {
      raw_ptr()->set_private_key(original_key.raw());
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
  Utils::SNPrint(private_key, sizeof(private_key), "%c%" Pd "%06" Pd "",
                 kPrivateKeySeparator, sequence_value, hash_value);
  const String& key =
      String::Handle(zone, String::New(private_key, Heap::kOld));
  key.Hash();  // This string may end up in the VM isolate.
  raw_ptr()->set_private_key(key.raw());
}

const String& Library::PrivateCoreLibName(const String& member) {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const String& private_name = String::ZoneHandle(core_lib.PrivateName(member));
  return private_name;
}

bool Library::IsPrivateCoreLibName(const String& name, const String& member) {
  Zone* zone = Thread::Current()->zone();
  const auto& core_lib = Library::Handle(zone, Library::CoreLibrary());
  const auto& private_key = String::Handle(zone, core_lib.private_key());

  ASSERT(core_lib.IsPrivate(member));
  return name.EqualsConcat(member, private_key);
}

ClassPtr Library::LookupCoreClass(const String& class_name) {
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
StringPtr Library::PrivateName(const String& name) const {
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

LibraryPtr Library::GetLibrary(intptr_t index) {
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
  // Now remember these in the isolate's object store.
  isolate->object_store()->set_libraries(libs);
  isolate->object_store()->set_libraries_map(map.Release());
}

LibraryPtr Library::AsyncLibrary() {
  return Isolate::Current()->object_store()->async_library();
}

LibraryPtr Library::ConvertLibrary() {
  return Isolate::Current()->object_store()->convert_library();
}

LibraryPtr Library::CoreLibrary() {
  return Isolate::Current()->object_store()->core_library();
}

LibraryPtr Library::CollectionLibrary() {
  return Isolate::Current()->object_store()->collection_library();
}

LibraryPtr Library::DeveloperLibrary() {
  return Isolate::Current()->object_store()->developer_library();
}

LibraryPtr Library::FfiLibrary() {
  return Isolate::Current()->object_store()->ffi_library();
}

LibraryPtr Library::InternalLibrary() {
  return Isolate::Current()->object_store()->_internal_library();
}

LibraryPtr Library::IsolateLibrary() {
  return Isolate::Current()->object_store()->isolate_library();
}

LibraryPtr Library::MathLibrary() {
  return Isolate::Current()->object_store()->math_library();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
LibraryPtr Library::MirrorsLibrary() {
  return Isolate::Current()->object_store()->mirrors_library();
}
#endif

LibraryPtr Library::NativeWrappersLibrary() {
  return Isolate::Current()->object_store()->native_wrappers_library();
}

LibraryPtr Library::ProfilerLibrary() {
  return Isolate::Current()->object_store()->profiler_library();
}

LibraryPtr Library::TypedDataLibrary() {
  return Isolate::Current()->object_store()->typed_data_library();
}

LibraryPtr Library::VMServiceLibrary() {
  return Isolate::Current()->object_store()->_vmservice_library();
}

const char* Library::ToCString() const {
  NoSafepointScope no_safepoint;
  const String& name = String::Handle(url());
  return OS::SCreate(Thread::Current()->zone(), "Library:'%s'",
                     name.ToCString());
}

LibraryPtr LibraryPrefix::GetLibrary(int index) const {
  if ((index >= 0) || (index < num_imports())) {
    const Array& imports = Array::Handle(this->imports());
    Namespace& import = Namespace::Handle();
    import ^= imports.At(index);
    return import.target();
  }
  return Library::null();
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

LibraryPrefixPtr LibraryPrefix::New() {
  ObjectPtr raw = Object::Allocate(LibraryPrefix::kClassId,
                                   LibraryPrefix::InstanceSize(), Heap::kOld);
  return static_cast<LibraryPrefixPtr>(raw);
}

LibraryPrefixPtr LibraryPrefix::New(const String& name,
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
  raw_ptr()->set_name(value.raw());
}

void LibraryPrefix::set_imports(const Array& value) const {
  raw_ptr()->set_imports(value.raw());
}

void LibraryPrefix::set_num_imports(intptr_t value) const {
  if (!Utils::IsUint(16, value)) {
    ReportTooManyImports(Library::Handle(importer()));
  }
  StoreNonPointer(&raw_ptr()->num_imports_, value);
}

void LibraryPrefix::set_importer(const Library& value) const {
  raw_ptr()->set_importer(value.raw());
}

const char* LibraryPrefix::ToCString() const {
  const String& prefix = String::Handle(name());
  return prefix.ToCString();
}

const char* Namespace::ToCString() const {
  const Library& lib = Library::Handle(target());
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
ObjectPtr Namespace::Lookup(const String& name,
                            ZoneGrowableArray<intptr_t>* trail) const {
  Zone* zone = Thread::Current()->zone();
  const Library& lib = Library::Handle(zone, target());

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

  lib.EnsureTopLevelClassIsFinalized();

  intptr_t ignore = 0;
  // Lookup the name in the library's symbols.
  Object& obj = Object::Handle(zone, lib.LookupEntry(name, &ignore));
  if (!Field::IsGetterName(name) && !Field::IsSetterName(name) &&
      (obj.IsNull() || obj.IsLibraryPrefix())) {
    String& accessor_name = String::Handle(zone);
    accessor_name = Field::LookupGetterSymbol(name);
    if (!accessor_name.IsNull()) {
      obj = lib.LookupEntry(accessor_name, &ignore);
    }
    if (obj.IsNull()) {
      accessor_name = Field::LookupSetterSymbol(name);
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

NamespacePtr Namespace::New() {
  ASSERT(Object::namespace_class() != Class::null());
  ObjectPtr raw = Object::Allocate(Namespace::kClassId,
                                   Namespace::InstanceSize(), Heap::kOld);
  return static_cast<NamespacePtr>(raw);
}

NamespacePtr Namespace::New(const Library& target,
                            const Array& show_names,
                            const Array& hide_names,
                            const Library& owner) {
  ASSERT(show_names.IsNull() || (show_names.Length() > 0));
  ASSERT(hide_names.IsNull() || (hide_names.Length() > 0));
  const Namespace& result = Namespace::Handle(Namespace::New());
  result.raw_ptr()->set_target(target.raw());
  result.raw_ptr()->set_show_names(show_names.raw());
  result.raw_ptr()->set_hide_names(hide_names.raw());
  result.raw_ptr()->set_owner(owner.raw());
  return result.raw();
}

KernelProgramInfoPtr KernelProgramInfo::New() {
  ObjectPtr raw =
      Object::Allocate(KernelProgramInfo::kClassId,
                       KernelProgramInfo::InstanceSize(), Heap::kOld);
  return static_cast<KernelProgramInfoPtr>(raw);
}

KernelProgramInfoPtr KernelProgramInfo::New(
    const TypedData& string_offsets,
    const ExternalTypedData& string_data,
    const TypedData& canonical_names,
    const ExternalTypedData& metadata_payloads,
    const ExternalTypedData& metadata_mappings,
    const ExternalTypedData& constants_table,
    const Array& scripts,
    const Array& libraries_cache,
    const Array& classes_cache,
    const Object& retained_kernel_blob,
    const uint32_t binary_version) {
  const KernelProgramInfo& info =
      KernelProgramInfo::Handle(KernelProgramInfo::New());
  info.raw_ptr()->set_string_offsets(string_offsets.raw());
  info.raw_ptr()->set_string_data(string_data.raw());
  info.raw_ptr()->set_canonical_names(canonical_names.raw());
  info.raw_ptr()->set_metadata_payloads(metadata_payloads.raw());
  info.raw_ptr()->set_metadata_mappings(metadata_mappings.raw());
  info.raw_ptr()->set_scripts(scripts.raw());
  info.raw_ptr()->set_constants_table(constants_table.raw());
  info.raw_ptr()->set_libraries_cache(libraries_cache.raw());
  info.raw_ptr()->set_classes_cache(classes_cache.raw());
  info.raw_ptr()->set_retained_kernel_blob(retained_kernel_blob.raw());
  info.set_kernel_binary_version(binary_version);
  return info.raw();
}

const char* KernelProgramInfo::ToCString() const {
  return "[KernelProgramInfo]";
}

ScriptPtr KernelProgramInfo::ScriptAt(intptr_t index) const {
  const Array& all_scripts = Array::Handle(scripts());
  ObjectPtr script = all_scripts.At(index);
  return Script::RawCast(script);
}

void KernelProgramInfo::set_scripts(const Array& scripts) const {
  raw_ptr()->set_scripts(scripts.raw());
}

void KernelProgramInfo::set_constants(const Array& constants) const {
  raw_ptr()->set_constants(constants.raw());
}

void KernelProgramInfo::set_kernel_binary_version(uint32_t version) const {
  StoreNonPointer(&raw_ptr()->kernel_binary_version_, version);
}

void KernelProgramInfo::set_constants_table(
    const ExternalTypedData& value) const {
  raw_ptr()->set_constants_table(value.raw());
}

void KernelProgramInfo::set_potential_natives(
    const GrowableObjectArray& candidates) const {
  raw_ptr()->set_potential_natives(candidates.raw());
}

void KernelProgramInfo::set_potential_pragma_functions(
    const GrowableObjectArray& candidates) const {
  raw_ptr()->set_potential_pragma_functions(candidates.raw());
}

void KernelProgramInfo::set_libraries_cache(const Array& cache) const {
  raw_ptr()->set_libraries_cache(cache.raw());
}

typedef UnorderedHashMap<SmiTraits> IntHashMap;

LibraryPtr KernelProgramInfo::LookupLibrary(Thread* thread,
                                            const Smi& name_index) const {
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_LIBRARY_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  REUSABLE_SMI_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  Library& result = thread->LibraryHandle();
  Object& key = thread->ObjectHandle();
  Smi& value = thread->SmiHandle();
  {
    SafepointMutexLocker ml(
        thread->isolate_group()->kernel_data_lib_cache_mutex());
    data = libraries_cache();
    ASSERT(!data.IsNull());
    IntHashMap table(&key, &value, &data);
    result ^= table.GetOrNull(name_index);
    table.Release();
  }
  return result.raw();
}

LibraryPtr KernelProgramInfo::InsertLibrary(Thread* thread,
                                            const Smi& name_index,
                                            const Library& lib) const {
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_LIBRARY_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  REUSABLE_SMI_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  Library& result = thread->LibraryHandle();
  Object& key = thread->ObjectHandle();
  Smi& value = thread->SmiHandle();
  {
    SafepointMutexLocker ml(
        thread->isolate_group()->kernel_data_lib_cache_mutex());
    data = libraries_cache();
    ASSERT(!data.IsNull());
    IntHashMap table(&key, &value, &data);
    result ^= table.InsertOrGetValue(name_index, lib);
    set_libraries_cache(table.Release());
  }
  return result.raw();
}

void KernelProgramInfo::set_classes_cache(const Array& cache) const {
  raw_ptr()->set_classes_cache(cache.raw());
}

ClassPtr KernelProgramInfo::LookupClass(Thread* thread,
                                        const Smi& name_index) const {
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_CLASS_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  REUSABLE_SMI_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  Class& result = thread->ClassHandle();
  Object& key = thread->ObjectHandle();
  Smi& value = thread->SmiHandle();
  {
    SafepointMutexLocker ml(
        thread->isolate_group()->kernel_data_class_cache_mutex());
    data = classes_cache();
    ASSERT(!data.IsNull());
    IntHashMap table(&key, &value, &data);
    result ^= table.GetOrNull(name_index);
    table.Release();
  }
  return result.raw();
}

ClassPtr KernelProgramInfo::InsertClass(Thread* thread,
                                        const Smi& name_index,
                                        const Class& klass) const {
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  REUSABLE_CLASS_HANDLESCOPE(thread);
  REUSABLE_OBJECT_HANDLESCOPE(thread);
  REUSABLE_SMI_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  Class& result = thread->ClassHandle();
  Object& key = thread->ObjectHandle();
  Smi& value = thread->SmiHandle();
  {
    SafepointMutexLocker ml(
        thread->isolate_group()->kernel_data_class_cache_mutex());
    data = classes_cache();
    ASSERT(!data.IsNull());
    IntHashMap table(&key, &value, &data);
    result ^= table.InsertOrGetValue(name_index, klass);
    set_classes_cache(table.Release());
  }
  return result.raw();
}

ErrorPtr Library::CompileAll(bool ignore_error /* = false */) {
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
        if (ignore_error) continue;
        return error.raw();
      }
      error = Compiler::CompileAllFunctions(cls);
      if (!error.IsNull()) {
        if (ignore_error) continue;
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
        if (ignore_error) continue;
        return Error::Cast(result).raw();
      }
    }
  }
  return Error::null();
}

#if !defined(DART_PRECOMPILED_RUNTIME)

ErrorPtr Library::FinalizeAllClasses() {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  Zone* zone = thread->zone();
  Error& error = Error::Handle(zone);
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    if (!lib.Loaded()) {
      String& uri = String::Handle(zone, lib.url());
      String& msg = String::Handle(
          zone,
          String::NewFormatted("Library '%s' is not loaded. "
                               "Did you forget to call Dart_FinalizeLoading?",
                               uri.ToCString()));
      return ApiError::New(msg);
    }
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      error = cls.EnsureIsFinalized(thread);
      if (!error.IsNull()) {
        return error.raw();
      }
    }
  }
  return Error::null();
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// Return Function::null() if function does not exist in libs.
FunctionPtr Library::GetFunction(const GrowableArray<Library*>& libs,
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
        if (cls.EnsureIsFinalized(thread) == Error::null()) {
          func_str = String::New(function_name);
          if (function_name[0] == '.') {
            func_str = String::Concat(class_str, func_str);
          }
          func = cls.LookupFunctionAllowPrivate(func_str);
        }
      }
    }
    if (!func.IsNull()) {
      return func.raw();
    }
  }
  return Function::null();
}

ObjectPtr Library::GetFunctionClosure(const String& name) const {
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

#if defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME)
void Library::CheckFunctionFingerprints() {
  GrowableArray<Library*> all_libs;
  Function& func = Function::Handle();
  bool fingerprints_match = true;

#define CHECK_FINGERPRINTS_INNER(class_name, function_name, dest, fp, kind)    \
  func = GetFunction(all_libs, #class_name, #function_name);                   \
  if (func.IsNull()) {                                                         \
    fingerprints_match = false;                                                \
    OS::PrintErr("Function not found %s.%s\n", #class_name, #function_name);   \
  } else {                                                                     \
    fingerprints_match =                                                       \
        func.CheckSourceFingerprint(fp, kind) && fingerprints_match;           \
  }

#define CHECK_FINGERPRINTS(class_name, function_name, dest, fp)                \
  CHECK_FINGERPRINTS_INNER(class_name, function_name, dest, fp, nullptr)
#define CHECK_FINGERPRINTS_ASM_INTRINSIC(class_name, function_name, dest, fp)  \
  CHECK_FINGERPRINTS_INNER(class_name, function_name, dest, fp, "asm-intrinsic")
#define CHECK_FINGERPRINTS_GRAPH_INTRINSIC(class_name, function_name, dest,    \
                                           fp)                                 \
  CHECK_FINGERPRINTS_INNER(class_name, function_name, dest, fp,                \
                           "graph-intrinsic")
#define CHECK_FINGERPRINTS_OTHER(class_name, function_name, dest, fp)          \
  CHECK_FINGERPRINTS_INNER(class_name, function_name, dest, fp, "other")

  all_libs.Add(&Library::ZoneHandle(Library::CoreLibrary()));
  CORE_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS_ASM_INTRINSIC);
  CORE_INTEGER_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS_ASM_INTRINSIC);
  GRAPH_CORE_INTRINSICS_LIST(CHECK_FINGERPRINTS_GRAPH_INTRINSIC);

  all_libs.Add(&Library::ZoneHandle(Library::AsyncLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::CollectionLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::ConvertLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::InternalLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::FfiLibrary()));
  INTERNAL_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS_ASM_INTRINSIC);
  OTHER_RECOGNIZED_LIST(CHECK_FINGERPRINTS_OTHER);
  POLYMORPHIC_TARGET_LIST(CHECK_FINGERPRINTS);
  GRAPH_TYPED_DATA_INTRINSICS_LIST(CHECK_FINGERPRINTS_GRAPH_INTRINSIC);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::DeveloperLibrary()));
  DEVELOPER_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS_ASM_INTRINSIC);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  MATH_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS_ASM_INTRINSIC);
  GRAPH_MATH_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS_GRAPH_INTRINSIC);

#undef CHECK_FINGERPRINTS_INNER
#undef CHECK_FINGERPRINTS
#undef CHECK_FINGERPRINTS_ASM_INTRINSIC
#undef CHECK_FINGERPRINTS_GRAPH_INTRINSIC
#undef CHECK_FINGERPRINTS_OTHER

#define CHECK_FACTORY_FINGERPRINTS(symbol, class_name, factory_name, cid, fp)  \
  func = GetFunction(all_libs, #class_name, #factory_name);                    \
  if (func.IsNull()) {                                                         \
    fingerprints_match = false;                                                \
    OS::PrintErr("Function not found %s.%s\n", #class_name, #factory_name);    \
  } else {                                                                     \
    fingerprints_match =                                                       \
        func.CheckSourceFingerprint(fp) && fingerprints_match;                 \
  }

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::CoreLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  RECOGNIZED_LIST_FACTORY_LIST(CHECK_FACTORY_FINGERPRINTS);

#undef CHECK_FACTORY_FINGERPRINTS

  if (!fingerprints_match) {
    FATAL(
        "FP mismatch while recognizing methods. If the behavior of "
        "these functions has changed, then changes are also needed in "
        "the VM's compiler. Otherwise the fingerprint can simply be "
        "updated in recognized_methods_list.h\n");
  }
}
#endif  // defined(DEBUG) && !defined(DART_PRECOMPILED_RUNTIME).

InstructionsPtr Instructions::New(intptr_t size, bool has_monomorphic_entry) {
  ASSERT(size >= 0);
  ASSERT(Object::instructions_class() != Class::null());
  if (size < 0 || size > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Instructions::New: invalid size %" Pd "\n", size);
  }
  Instructions& result = Instructions::Handle();
  {
    uword aligned_size = Instructions::InstanceSize(size);
    ObjectPtr raw =
        Object::Allocate(Instructions::kClassId, aligned_size, Heap::kCode);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetSize(size);
    result.SetHasMonomorphicEntry(has_monomorphic_entry);
    result.set_stats(nullptr);
  }
  return result.raw();
}

const char* Instructions::ToCString() const {
  return "Instructions";
}

CodeStatistics* Instructions::stats() const {
#if defined(DART_PRECOMPILER)
  return reinterpret_cast<CodeStatistics*>(
      Thread::Current()->heap()->GetPeer(raw()));
#else
  return nullptr;
#endif
}

void Instructions::set_stats(CodeStatistics* stats) const {
#if defined(DART_PRECOMPILER)
  Thread::Current()->heap()->SetPeer(raw(), stats);
#endif
}

const char* InstructionsSection::ToCString() const {
  return "InstructionsSection";
}

ObjectPoolPtr ObjectPool::New(intptr_t len) {
  ASSERT(Object::object_pool_class() != Class::null());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ObjectPool::New: invalid length %" Pd "\n", len);
  }
  ObjectPool& result = ObjectPool::Handle();
  {
    uword size = ObjectPool::InstanceSize(len);
    ObjectPtr raw = Object::Allocate(ObjectPool::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    for (intptr_t i = 0; i < len; i++) {
      result.SetTypeAt(i, ObjectPool::EntryType::kImmediate,
                       ObjectPool::Patchability::kPatchable);
    }
  }

  return result.raw();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
ObjectPoolPtr ObjectPool::NewFromBuilder(
    const compiler::ObjectPoolBuilder& builder) {
  const intptr_t len = builder.CurrentLength();
  if (len == 0) {
    return Object::empty_object_pool().raw();
  }
  const ObjectPool& result = ObjectPool::Handle(ObjectPool::New(len));
  for (intptr_t i = 0; i < len; i++) {
    auto entry = builder.EntryAt(i);
    auto type = entry.type();
    auto patchable = entry.patchable();
    result.SetTypeAt(i, type, patchable);
    if (type == EntryType::kTaggedObject) {
      result.SetObjectAt(i, *entry.obj_);
    } else {
      result.SetRawValueAt(i, entry.raw_value_);
    }
  }
  return result.raw();
}

void ObjectPool::CopyInto(compiler::ObjectPoolBuilder* builder) const {
  ASSERT(builder->CurrentLength() == 0);
  for (intptr_t i = 0; i < Length(); i++) {
    auto type = TypeAt(i);
    auto patchable = PatchableAt(i);
    switch (type) {
      case compiler::ObjectPoolBuilderEntry::kTaggedObject: {
        compiler::ObjectPoolBuilderEntry entry(&Object::ZoneHandle(ObjectAt(i)),
                                               patchable);
        builder->AddObject(entry);
        break;
      }
      case compiler::ObjectPoolBuilderEntry::kImmediate:
      case compiler::ObjectPoolBuilderEntry::kNativeFunction:
      case compiler::ObjectPoolBuilderEntry::kNativeFunctionWrapper: {
        compiler::ObjectPoolBuilderEntry entry(RawValueAt(i), type, patchable);
        builder->AddObject(entry);
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  ASSERT(builder->CurrentLength() == Length());
}
#endif

const char* ObjectPool::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  return zone->PrintToString("ObjectPool len:%" Pd, Length());
}

void ObjectPool::DebugPrint() const {
  THR_Print("ObjectPool len:%" Pd " {\n", Length());
  for (intptr_t i = 0; i < Length(); i++) {
    intptr_t offset = OffsetFromIndex(i);
    THR_Print("  [pp+0x%" Px "] ", offset);
    if (TypeAt(i) == EntryType::kTaggedObject) {
      const Object& obj = Object::Handle(ObjectAt(i));
      THR_Print("%s (obj)\n", obj.ToCString());
    } else if (TypeAt(i) == EntryType::kNativeFunction) {
      uword pc = RawValueAt(i);
      uintptr_t start = 0;
      char* name = NativeSymbolResolver::LookupSymbolName(pc, &start);
      if (name != NULL) {
        THR_Print("%s (native function)\n", name);
        NativeSymbolResolver::FreeSymbolName(name);
      } else {
        THR_Print("0x%" Px " (native function)\n", pc);
      }
    } else if (TypeAt(i) == EntryType::kNativeFunctionWrapper) {
      THR_Print("0x%" Px " (native function wrapper)\n", RawValueAt(i));
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

void PcDescriptors::CopyData(const void* bytes, intptr_t size) {
  NoSafepointScope no_safepoint;
  uint8_t* data = UnsafeMutableNonPointer(&raw_ptr()->data()[0]);
  // We're guaranted these memory spaces do not overlap.
  memcpy(data, bytes, size);  // NOLINT
}

PcDescriptorsPtr PcDescriptors::New(const void* delta_encoded_data,
                                    intptr_t size) {
  ASSERT(Object::pc_descriptors_class() != Class::null());
  Thread* thread = Thread::Current();
  PcDescriptors& result = PcDescriptors::Handle(thread->zone());
  {
    ObjectPtr raw = Object::Allocate(
        PcDescriptors::kClassId, PcDescriptors::InstanceSize(size), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(size);
    result.CopyData(delta_encoded_data, size);
  }
  return result.raw();
}

PcDescriptorsPtr PcDescriptors::New(intptr_t length) {
  ASSERT(Object::pc_descriptors_class() != Class::null());
  Thread* thread = Thread::Current();
  PcDescriptors& result = PcDescriptors::Handle(thread->zone());
  {
    uword size = PcDescriptors::InstanceSize(length);
    ObjectPtr raw = Object::Allocate(PcDescriptors::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  return result.raw();
}

const char* PcDescriptors::KindAsStr(PcDescriptorsLayout::Kind kind) {
  switch (kind) {
    case PcDescriptorsLayout::kDeopt:
      return "deopt        ";
    case PcDescriptorsLayout::kIcCall:
      return "ic-call      ";
    case PcDescriptorsLayout::kUnoptStaticCall:
      return "unopt-call   ";
    case PcDescriptorsLayout::kRuntimeCall:
      return "runtime-call ";
    case PcDescriptorsLayout::kOsrEntry:
      return "osr-entry    ";
    case PcDescriptorsLayout::kRewind:
      return "rewind       ";
    case PcDescriptorsLayout::kBSSRelocation:
      return "bss reloc    ";
    case PcDescriptorsLayout::kOther:
      return "other        ";
    case PcDescriptorsLayout::kAnyKind:
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
  THR_Print("%-*s\tkind    \tdeopt-id\ttok-ix\ttry-ix\tyield-idx\n", addr_width,
            "pc");
}

const char* PcDescriptors::ToCString() const {
// "*" in a printf format specifier tells it to read the field width from
// the printf argument list.
#define FORMAT "%#-*" Px "\t%s\t%" Pd "\t\t%s\t%" Pd "\t%" Pd "\n"
  if (Length() == 0) {
    return "empty PcDescriptors\n";
  }
  // 4 bits per hex digit.
  const int addr_width = kBitsPerWord / 4;
  // First compute the buffer size required.
  intptr_t len = 1;  // Trailing '\0'.
  {
    Iterator iter(*this, PcDescriptorsLayout::kAnyKind);
    while (iter.MoveNext()) {
      len += Utils::SNPrint(NULL, 0, FORMAT, addr_width, iter.PcOffset(),
                            KindAsStr(iter.Kind()), iter.DeoptId(),
                            iter.TokenPos().ToCString(), iter.TryIndex(),
                            iter.YieldIndex());
    }
  }
  // Allocate the buffer.
  char* buffer = Thread::Current()->zone()->Alloc<char>(len);
  // Layout the fields in the buffer.
  intptr_t index = 0;
  Iterator iter(*this, PcDescriptorsLayout::kAnyKind);
  while (iter.MoveNext()) {
    index += Utils::SNPrint((buffer + index), (len - index), FORMAT, addr_width,
                            iter.PcOffset(), KindAsStr(iter.Kind()),
                            iter.DeoptId(), iter.TokenPos().ToCString(),
                            iter.TryIndex(), iter.YieldIndex());
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
                    PcDescriptorsLayout::kDeopt | PcDescriptorsLayout::kIcCall);
  while (max_iter.MoveNext()) {
    if (max_iter.DeoptId() > max_deopt_id) {
      max_deopt_id = max_iter.DeoptId();
    }
  }

  Zone* zone = Thread::Current()->zone();
  BitVector* deopt_ids = new (zone) BitVector(zone, max_deopt_id + 1);
  BitVector* iccall_ids = new (zone) BitVector(zone, max_deopt_id + 1);
  Iterator iter(*this,
                PcDescriptorsLayout::kDeopt | PcDescriptorsLayout::kIcCall);
  while (iter.MoveNext()) {
    // 'deopt_id' is set for kDeopt and kIcCall and must be unique for one kind.
    if (DeoptId::IsDeoptAfter(iter.DeoptId())) {
      // TODO(vegorov): some instructions contain multiple calls and have
      // multiple "after" targets recorded. Right now it is benign but might
      // lead to issues in the future. Fix that and enable verification.
      continue;
    }
    if (iter.Kind() == PcDescriptorsLayout::kDeopt) {
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

CodeSourceMapPtr CodeSourceMap::New(intptr_t length) {
  ASSERT(Object::code_source_map_class() != Class::null());
  Thread* thread = Thread::Current();
  CodeSourceMap& result = CodeSourceMap::Handle(thread->zone());
  {
    uword size = CodeSourceMap::InstanceSize(length);
    ObjectPtr raw = Object::Allocate(CodeSourceMap::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  return result.raw();
}

const char* CodeSourceMap::ToCString() const {
  return "CodeSourceMap";
}

intptr_t CompressedStackMaps::Hashcode() const {
  NoSafepointScope scope;
  uint8_t* data = UnsafeMutableNonPointer(&raw_ptr()->data()[0]);
  uint8_t* end = data + payload_size();
  uint32_t hash = payload_size();
  for (uint8_t* cursor = data; cursor < end; cursor++) {
    hash = CombineHashes(hash, *cursor);
  }
  return FinalizeHash(hash, kHashBits);
}

CompressedStackMaps::Iterator::Iterator(const CompressedStackMaps& maps,
                                        const CompressedStackMaps& global_table)
    : maps_(maps),
      bits_container_(maps_.UsesGlobalTable() ? global_table : maps_) {
  ASSERT(!maps_.IsNull());
  ASSERT(!bits_container_.IsNull());
  ASSERT(!maps_.IsGlobalTable());
  ASSERT(!maps_.UsesGlobalTable() || bits_container_.IsGlobalTable());
}

CompressedStackMaps::Iterator::Iterator(Thread* thread,
                                        const CompressedStackMaps& maps)
    : CompressedStackMaps::Iterator(
          maps,
          // Only look up the global table if the map will end up using it.
          maps.UsesGlobalTable() ? CompressedStackMaps::Handle(
                                       thread->zone(),
                                       thread->isolate()
                                           ->object_store()
                                           ->canonicalized_stack_map_entries())
                                 : Object::null_compressed_stackmaps()) {}

CompressedStackMaps::Iterator::Iterator(const CompressedStackMaps::Iterator& it)
    : maps_(it.maps_),
      bits_container_(it.bits_container_),
      next_offset_(it.next_offset_),
      current_pc_offset_(it.current_pc_offset_),
      current_global_table_offset_(it.current_global_table_offset_),
      current_spill_slot_bit_count_(it.current_spill_slot_bit_count_),
      current_non_spill_slot_bit_count_(it.current_spill_slot_bit_count_),
      current_bits_offset_(it.current_bits_offset_) {}

bool CompressedStackMaps::Iterator::MoveNext() {
  if (next_offset_ >= maps_.payload_size()) {
    return false;
  }

  NoSafepointScope scope;
  ReadStream stream(maps_.raw_ptr()->data(), maps_.payload_size(),
                    next_offset_);

  auto const pc_delta = stream.ReadLEB128();
  ASSERT(pc_delta <= (kMaxUint32 - current_pc_offset_));
  current_pc_offset_ += pc_delta;

  // Table-using CSMs have a table offset after the PC offset delta, whereas
  // the post-delta part of inlined entries has the same information as
  // global table entries.
  if (maps_.UsesGlobalTable()) {
    current_global_table_offset_ = stream.ReadLEB128();
    ASSERT(current_global_table_offset_ < bits_container_.payload_size());

    // Since generally we only use entries in the GC and the GC only needs
    // the rest of the entry information if the PC offset matches, we lazily
    // load and cache the information stored in the global object when it is
    // actually requested.
    current_spill_slot_bit_count_ = -1;
    current_non_spill_slot_bit_count_ = -1;
    current_bits_offset_ = -1;

    next_offset_ = stream.Position();
  } else {
    current_spill_slot_bit_count_ = stream.ReadLEB128();
    ASSERT(current_spill_slot_bit_count_ >= 0);

    current_non_spill_slot_bit_count_ = stream.ReadLEB128();
    ASSERT(current_non_spill_slot_bit_count_ >= 0);

    const auto stackmap_bits =
        current_spill_slot_bit_count_ + current_non_spill_slot_bit_count_;
    const uintptr_t stackmap_size =
        Utils::RoundUp(stackmap_bits, kBitsPerByte) >> kBitsPerByteLog2;
    ASSERT(stackmap_size <= (maps_.payload_size() - stream.Position()));

    current_bits_offset_ = stream.Position();
    next_offset_ = current_bits_offset_ + stackmap_size;
  }

  return true;
}

intptr_t CompressedStackMaps::Iterator::Length() const {
  EnsureFullyLoadedEntry();
  return current_spill_slot_bit_count_ + current_non_spill_slot_bit_count_;
}
intptr_t CompressedStackMaps::Iterator::SpillSlotBitCount() const {
  EnsureFullyLoadedEntry();
  return current_spill_slot_bit_count_;
}

bool CompressedStackMaps::Iterator::IsObject(intptr_t bit_index) const {
  EnsureFullyLoadedEntry();
  ASSERT(bit_index >= 0 && bit_index < Length());
  const intptr_t byte_index = bit_index >> kBitsPerByteLog2;
  const intptr_t bit_remainder = bit_index & (kBitsPerByte - 1);
  uint8_t byte_mask = 1U << bit_remainder;
  const intptr_t byte_offset = current_bits_offset_ + byte_index;
  NoSafepointScope scope;
  return (bits_container_.raw_ptr()->data()[byte_offset] & byte_mask) != 0;
}

void CompressedStackMaps::Iterator::LazyLoadGlobalTableEntry() const {
  ASSERT(maps_.UsesGlobalTable());
  ASSERT(HasLoadedEntry());
  ASSERT(current_global_table_offset_ < bits_container_.payload_size());

  NoSafepointScope scope;
  ReadStream stream(bits_container_.raw_ptr()->data(),
                    bits_container_.payload_size(),
                    current_global_table_offset_);

  current_spill_slot_bit_count_ = stream.ReadLEB128();
  ASSERT(current_spill_slot_bit_count_ >= 0);

  current_non_spill_slot_bit_count_ = stream.ReadLEB128();
  ASSERT(current_non_spill_slot_bit_count_ >= 0);

  const auto stackmap_bits = Length();
  const uintptr_t stackmap_size =
      Utils::RoundUp(stackmap_bits, kBitsPerByte) >> kBitsPerByteLog2;
  ASSERT(stackmap_size <= (bits_container_.payload_size() - stream.Position()));

  current_bits_offset_ = stream.Position();
}

void CompressedStackMaps::Iterator::WriteToBuffer(BaseTextBuffer* buffer,
                                                  const char* separator) const {
  CompressedStackMaps::Iterator it(*this);
  // If we haven't loaded an entry yet, do so (but don't skip the current
  // one if we have!)
  if (!it.HasLoadedEntry()) {
    if (!it.MoveNext()) return;
  }
  bool first_entry = true;
  do {
    if (!first_entry) {
      buffer->AddString(separator);
    }
    buffer->Printf("0x%.8" Px32 ": ", it.pc_offset());
    for (intptr_t i = 0, n = it.Length(); i < n; i++) {
      buffer->AddString(it.IsObject(i) ? "1" : "0");
    }
    first_entry = false;
  } while (it.MoveNext());
}

CompressedStackMapsPtr CompressedStackMaps::New(const void* payload,
                                                intptr_t size,
                                                bool is_global_table,
                                                bool uses_global_table) {
  ASSERT(Object::compressed_stackmaps_class() != Class::null());
  // We don't currently allow both flags to be true.
  ASSERT(!is_global_table || !uses_global_table);
  // The canonical empty instance should be used instead.
  ASSERT(size != 0);

  if (!CompressedStackMapsLayout::SizeField::is_valid(size)) {
    FATAL1(
        "Fatal error in CompressedStackMaps::New: "
        "invalid payload size %" Pu "\n",
        size);
  }

  auto& result = CompressedStackMaps::Handle();
  {
    // CompressedStackMaps data objects are associated with a code object,
    // allocate them in old generation.
    ObjectPtr raw =
        Object::Allocate(CompressedStackMaps::kClassId,
                         CompressedStackMaps::InstanceSize(size), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(
        &result.raw_ptr()->flags_and_size_,
        CompressedStackMapsLayout::GlobalTableBit::encode(is_global_table) |
            CompressedStackMapsLayout::UsesTableBit::encode(uses_global_table) |
            CompressedStackMapsLayout::SizeField::encode(size));
    auto cursor = result.UnsafeMutableNonPointer(result.raw_ptr()->data());
    memcpy(cursor, payload, size);  // NOLINT
  }

  ASSERT(!result.IsGlobalTable() || !result.UsesGlobalTable());

  return result.raw();
}

const char* CompressedStackMaps::ToCString() const {
  ASSERT(!IsGlobalTable());
  if (payload_size() == 0) {
    return "CompressedStackMaps()";
  }
  auto const t = Thread::Current();
  CompressedStackMaps::Iterator it(t, *this);
  ZoneTextBuffer buffer(t->zone(), 100);
  buffer.AddString("CompressedStackMaps(");
  it.WriteToBuffer(&buffer, ", ");
  buffer.AddString(")");
  return buffer.buffer();
}

StringPtr LocalVarDescriptors::GetName(intptr_t var_index) const {
  ASSERT(var_index < Length());
  ASSERT(Object::Handle(*raw()->ptr()->nameAddrAt(var_index)).IsString());
  return *raw()->ptr()->nameAddrAt(var_index);
}

void LocalVarDescriptors::SetVar(
    intptr_t var_index,
    const String& name,
    LocalVarDescriptorsLayout::VarInfo* info) const {
  ASSERT(var_index < Length());
  ASSERT(!name.IsNull());
  StorePointer(raw()->ptr()->nameAddrAt(var_index), name.raw());
  raw()->ptr()->data()[var_index] = *info;
}

void LocalVarDescriptors::GetInfo(
    intptr_t var_index,
    LocalVarDescriptorsLayout::VarInfo* info) const {
  ASSERT(var_index < Length());
  *info = raw()->ptr()->data()[var_index];
}

static int PrintVarInfo(char* buffer,
                        int len,
                        intptr_t i,
                        const String& var_name,
                        const LocalVarDescriptorsLayout::VarInfo& info) {
  const LocalVarDescriptorsLayout::VarInfoKind kind = info.kind();
  const int32_t index = info.index();
  if (kind == LocalVarDescriptorsLayout::kContextLevel) {
    return Utils::SNPrint(buffer, len,
                          "%2" Pd
                          " %-13s level=%-3d"
                          " begin=%-3d end=%d\n",
                          i, LocalVarDescriptors::KindToCString(kind), index,
                          static_cast<int>(info.begin_pos.Pos()),
                          static_cast<int>(info.end_pos.Pos()));
  } else if (kind == LocalVarDescriptorsLayout::kContextVar) {
    return Utils::SNPrint(
        buffer, len,
        "%2" Pd
        " %-13s level=%-3d index=%-3d"
        " begin=%-3d end=%-3d name=%s\n",
        i, LocalVarDescriptors::KindToCString(kind), info.scope_id, index,
        static_cast<int>(info.begin_pos.Pos()),
        static_cast<int>(info.end_pos.Pos()), var_name.ToCString());
  } else {
    return Utils::SNPrint(
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
    LocalVarDescriptorsLayout::VarInfo info;
    var_name = GetName(i);
    GetInfo(i, &info);
    len += PrintVarInfo(NULL, 0, i, var_name, info);
  }
  char* buffer = Thread::Current()->zone()->Alloc<char>(len + 1);
  buffer[0] = '\0';
  intptr_t num_chars = 0;
  for (intptr_t i = 0; i < Length(); i++) {
    LocalVarDescriptorsLayout::VarInfo info;
    var_name = GetName(i);
    GetInfo(i, &info);
    num_chars += PrintVarInfo((buffer + num_chars), (len - num_chars), i,
                              var_name, info);
  }
  return buffer;
}

const char* LocalVarDescriptors::KindToCString(
    LocalVarDescriptorsLayout::VarInfoKind kind) {
  switch (kind) {
    case LocalVarDescriptorsLayout::kStackVar:
      return "StackVar";
    case LocalVarDescriptorsLayout::kContextVar:
      return "ContextVar";
    case LocalVarDescriptorsLayout::kContextLevel:
      return "ContextLevel";
    case LocalVarDescriptorsLayout::kSavedCurrentContext:
      return "CurrentCtx";
    default:
      UNIMPLEMENTED();
      return NULL;
  }
}

LocalVarDescriptorsPtr LocalVarDescriptors::New(intptr_t num_variables) {
  ASSERT(Object::var_descriptors_class() != Class::null());
  if (num_variables < 0 || num_variables > kMaxElements) {
    // This should be caught before we reach here.
    FATAL2(
        "Fatal error in LocalVarDescriptors::New: "
        "invalid num_variables %" Pd ". Maximum is: %d\n",
        num_variables, LocalVarDescriptorsLayout::kMaxIndex);
  }
  LocalVarDescriptors& result = LocalVarDescriptors::Handle();
  {
    uword size = LocalVarDescriptors::InstanceSize(num_variables);
    ObjectPtr raw =
        Object::Allocate(LocalVarDescriptors::kClassId, size, Heap::kOld);
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
  info->needs_stacktrace = static_cast<int8_t>(needs_stacktrace);
  info->has_catch_all = static_cast<int8_t>(has_catch_all);
  info->is_generated = static_cast<int8_t>(is_generated);
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
  return raw_ptr()->data()[try_index].needs_stacktrace != 0;
}

bool ExceptionHandlers::IsGenerated(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].is_generated != 0;
}

bool ExceptionHandlers::HasCatchAll(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].has_catch_all != 0;
}

void ExceptionHandlers::SetHandledTypes(intptr_t try_index,
                                        const Array& handled_types) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  ASSERT(!handled_types.IsNull());
  const Array& handled_types_data =
      Array::Handle(raw_ptr()->handled_types_data());
  handled_types_data.SetAt(try_index, handled_types);
}

ArrayPtr ExceptionHandlers::GetHandledTypes(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  Array& array = Array::Handle(raw_ptr()->handled_types_data());
  array ^= array.At(try_index);
  return array.raw();
}

void ExceptionHandlers::set_handled_types_data(const Array& value) const {
  raw_ptr()->set_handled_types_data(value.raw());
}

ExceptionHandlersPtr ExceptionHandlers::New(intptr_t num_handlers) {
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
    ObjectPtr raw =
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

ExceptionHandlersPtr ExceptionHandlers::New(const Array& handled_types_data) {
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
    ObjectPtr raw =
        Object::Allocate(ExceptionHandlers::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->num_entries_, num_handlers);
  }
  result.set_handled_types_data(handled_types_data);
  return result.raw();
}

const char* ExceptionHandlers::ToCString() const {
#define FORMAT1 "%" Pd " => %#x  (%" Pd " types) (outer %d)%s%s\n"
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
    len += Utils::SNPrint(
        NULL, 0, FORMAT1, i, info.handler_pc_offset, num_types,
        info.outer_try_index,
        ((info.needs_stacktrace != 0) ? " (needs stack trace)" : ""),
        ((info.is_generated != 0) ? " (generated)" : ""));
    for (int k = 0; k < num_types; k++) {
      type ^= handled_types.At(k);
      ASSERT(!type.IsNull());
      len += Utils::SNPrint(NULL, 0, FORMAT2, k, type.ToCString());
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
    num_chars += Utils::SNPrint(
        (buffer + num_chars), (len - num_chars), FORMAT1, i,
        info.handler_pc_offset, num_types, info.outer_try_index,
        ((info.needs_stacktrace != 0) ? " (needs stack trace)" : ""),
        ((info.is_generated != 0) ? " (generated)" : ""));
    for (int k = 0; k < num_types; k++) {
      type ^= handled_types.At(k);
      num_chars += Utils::SNPrint((buffer + num_chars), (len - num_chars),
                                  FORMAT2, k, type.ToCString());
    }
  }
  return buffer;
#undef FORMAT1
#undef FORMAT2
}

void SingleTargetCache::set_target(const Code& value) const {
  raw_ptr()->set_target(value.raw());
}

const char* SingleTargetCache::ToCString() const {
  return "SingleTargetCache";
}

SingleTargetCachePtr SingleTargetCache::New() {
  SingleTargetCache& result = SingleTargetCache::Handle();
  {
    // IC data objects are long living objects, allocate them in old generation.
    ObjectPtr raw =
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

void UnlinkedCall::set_can_patch_to_monomorphic(bool value) const {
  StoreNonPointer(&raw_ptr()->can_patch_to_monomorphic_, value);
}

intptr_t UnlinkedCall::Hashcode() const {
  return String::Handle(target_name()).Hash();
}

bool UnlinkedCall::Equals(const UnlinkedCall& other) const {
  return (target_name() == other.target_name()) &&
         (arguments_descriptor() == other.arguments_descriptor()) &&
         (can_patch_to_monomorphic() == other.can_patch_to_monomorphic());
}

const char* UnlinkedCall::ToCString() const {
  return "UnlinkedCall";
}

UnlinkedCallPtr UnlinkedCall::New() {
  UnlinkedCall& result = UnlinkedCall::Handle();
  result ^= Object::Allocate(UnlinkedCall::kClassId,
                             UnlinkedCall::InstanceSize(), Heap::kOld);
  result.set_can_patch_to_monomorphic(!FLAG_precompiled_mode);
  return result.raw();
}

MonomorphicSmiableCallPtr MonomorphicSmiableCall::New(classid_t expected_cid,
                                                      const Code& target) {
  auto& result = MonomorphicSmiableCall::Handle();
  result ^=
      Object::Allocate(MonomorphicSmiableCall::kClassId,
                       MonomorphicSmiableCall::InstanceSize(), Heap::kOld);
  result.raw_ptr()->set_target(target.raw());
  result.StoreNonPointer(&result.raw_ptr()->expected_cid_, expected_cid);
  result.StoreNonPointer(&result.raw_ptr()->entrypoint_, target.EntryPoint());
  return result.raw();
}

const char* MonomorphicSmiableCall::ToCString() const {
  return "MonomorphicSmiableCall";
}

const char* CallSiteData::ToCString() const {
  // CallSiteData is an abstract class.  We should never reach here.
  UNREACHABLE();
  return "CallSiteData";
}

void CallSiteData::set_target_name(const String& value) const {
  ASSERT(!value.IsNull());
  raw_ptr()->set_target_name(value.raw());
}

void CallSiteData::set_arguments_descriptor(const Array& value) const {
  ASSERT(!value.IsNull());
  raw_ptr()->set_args_descriptor(value.raw());
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void ICData::SetReceiversStaticType(const AbstractType& type) const {
  raw_ptr()->set_receivers_static_type(type.raw());

#if defined(TARGET_ARCH_X64)
  if (!type.IsNull() && type.HasTypeClass() && (NumArgsTested() == 1) &&
      type.IsInstantiated() && !type.IsFutureOrType()) {
    const Class& cls = Class::Handle(type.type_class());
    if (cls.IsGeneric()) {
      set_tracking_exactness(true);
    }
  }
#endif  // defined(TARGET_ARCH_X64)
}
#endif

void ICData::SetTargetAtPos(const Array& data,
                            intptr_t data_pos,
                            intptr_t num_args_tested,
                            const Function& target) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // JIT
  data.SetAt(data_pos + TargetIndexFor(num_args_tested), target);
#else
  // AOT
  ASSERT(target.HasCode());
  const Code& code = Code::Handle(target.CurrentCode());
  const Smi& entry_point =
      Smi::Handle(Smi::FromAlignedAddress(code.EntryPoint()));
  data.SetAt(data_pos + CodeIndexFor(num_args_tested), code);
  data.SetAt(data_pos + EntryPointIndexFor(num_args_tested), entry_point);
#endif
}

const char* ICData::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  const String& name = String::Handle(zone, target_name());
  const intptr_t num_args = NumArgsTested();
  const intptr_t num_checks = NumberOfChecks();
  const intptr_t type_args_len = TypeArgsLen();
  return zone->PrintToString(
      "ICData(%s num-args: %" Pd " num-checks: %" Pd " type-args-len: %" Pd ")",
      name.ToCString(), num_args, num_checks, type_args_len);
}

FunctionPtr ICData::Owner() const {
  Object& obj = Object::Handle(raw_ptr()->owner());
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

ICDataPtr ICData::Original() const {
  if (IsNull()) {
    return ICData::null();
  }
  Object& obj = Object::Handle(raw_ptr()->owner());
  if (obj.IsFunction()) {
    return this->raw();
  } else {
    return ICData::RawCast(obj.raw());
  }
}

void ICData::SetOriginal(const ICData& value) const {
  ASSERT(value.IsOriginal());
  ASSERT(!value.IsNull());
  raw_ptr()->set_owner(static_cast<ObjectPtr>(value.raw()));
}

void ICData::set_owner(const Function& value) const {
  raw_ptr()->set_owner(static_cast<ObjectPtr>(value.raw()));
}

void ICData::set_deopt_id(intptr_t value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(value <= kMaxInt32);
  StoreNonPointer(&raw_ptr()->deopt_id_, value);
#endif
}

void ICData::set_entries(const Array& value) const {
  ASSERT(!value.IsNull());
  raw_ptr()->set_entries<std::memory_order_release>(value.raw());
}

intptr_t ICData::NumArgsTested() const {
  return NumArgsTestedBits::decode(raw_ptr()->state_bits_);
}

void ICData::SetNumArgsTested(intptr_t value) const {
  ASSERT(Utils::IsUint(2, value));
  StoreNonPointer(&raw_ptr()->state_bits_,
                  NumArgsTestedBits::update(value, raw_ptr()->state_bits_));
}

intptr_t CallSiteData::TypeArgsLen() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.TypeArgsLen();
}

intptr_t CallSiteData::CountWithTypeArgs() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.CountWithTypeArgs();
}

intptr_t CallSiteData::CountWithoutTypeArgs() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.Count();
}

intptr_t CallSiteData::SizeWithoutTypeArgs() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.Size();
}

intptr_t CallSiteData::SizeWithTypeArgs() const {
  ArgumentsDescriptor args_desc(Array::Handle(arguments_descriptor()));
  return args_desc.SizeWithTypeArgs();
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

const char* ICData::RebindRuleToCString(RebindRule r) {
  switch (r) {
#define RULE_CASE(Name)                                                        \
  case RebindRule::k##Name:                                                    \
    return #Name;
    FOR_EACH_REBIND_RULE(RULE_CASE)
#undef RULE_CASE
    default:
      return nullptr;
  }
}

bool ICData::ParseRebindRule(const char* str, RebindRule* out) {
#define RULE_CASE(Name)                                                        \
  if (strcmp(str, #Name) == 0) {                                               \
    *out = RebindRule::k##Name;                                                \
    return true;                                                               \
  }
  FOR_EACH_REBIND_RULE(RULE_CASE)
#undef RULE_CASE
  return false;
}

ICData::RebindRule ICData::rebind_rule() const {
  return (ICData::RebindRule)RebindRuleBits::decode(raw_ptr()->state_bits_);
}

void ICData::set_rebind_rule(uint32_t rebind_rule) const {
  StoreNonPointer(&raw_ptr()->state_bits_,
                  RebindRuleBits::update(rebind_rule, raw_ptr()->state_bits_));
}

bool ICData::is_static_call() const {
  return rebind_rule() != kInstance;
}

void ICData::set_state_bits(uint32_t bits) const {
  StoreNonPointer(&raw_ptr()->state_bits_, bits);
}

intptr_t ICData::TestEntryLengthFor(intptr_t num_args,
                                    bool tracking_exactness) {
  return num_args + 1 /* target function*/ + 1 /* frequency */ +
         (tracking_exactness ? 1 : 0) /* exactness state */;
}

intptr_t ICData::TestEntryLength() const {
  return TestEntryLengthFor(NumArgsTested(), is_tracking_exactness());
}

intptr_t ICData::Length() const {
  return (Smi::Value(entries()->ptr()->length()) / TestEntryLength());
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
  RELEASE_ASSERT(smi_illegal_cid().Value() == kIllegalCid);
  for (intptr_t i = 1; i <= test_entry_length; i++) {
    data.SetAt(data.Length() - i, smi_illegal_cid());
  }
}

#if defined(DEBUG)
// Used in asserts to verify that a check is not added twice.
bool ICData::HasCheck(const GrowableArray<intptr_t>& cids) const {
  return FindCheck(cids) != -1;
}
#endif  // DEBUG

intptr_t ICData::FindCheck(const GrowableArray<intptr_t>& cids) const {
  const intptr_t len = NumberOfChecks();
  GrowableArray<intptr_t> class_ids;
  for (intptr_t i = 0; i < len; i++) {
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
      return i;
    }
  }
  return -1;
}

void ICData::WriteSentinelAt(intptr_t index,
                             const CallSiteResetter& proof_of_reload) const {
  USE(proof_of_reload);  // This method can only be called during reload.

  Thread* thread = Thread::Current();
  const intptr_t len = Length();
  ASSERT(index >= 0);
  ASSERT(index < len);
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
  const intptr_t start = index * TestEntryLength();
  const intptr_t end = start + TestEntryLength();
  for (intptr_t i = start; i < end; i++) {
    data.SetAt(i, smi_illegal_cid());
  }
}

void ICData::ClearCountAt(intptr_t index,
                          const CallSiteResetter& proof_of_reload) const {
  USE(proof_of_reload);  // This method can only be called during reload.

  ASSERT(index >= 0);
  ASSERT(index < NumberOfChecks());
  SetCountAt(index, 0);
}

void ICData::ClearAndSetStaticTarget(
    const Function& func,
    const CallSiteResetter& proof_of_reload) const {
  USE(proof_of_reload);  // This method can only be called during reload.

  if (IsImmutable()) {
    return;
  }
  const intptr_t len = Length();
  if (len == 0) {
    return;
  }
  Thread* thread = Thread::Current();

  // The final entry is always the sentinel.
  ASSERT(IsSentinelAt(len - 1));
  const intptr_t num_args_tested = NumArgsTested();
  if (num_args_tested == 0) {
    // No type feedback is being collected.
    REUSABLE_ARRAY_HANDLESCOPE(thread);
    Array& data = thread->ArrayHandle();
    data = entries();
    // Static calls with no argument checks hold only one target and the
    // sentinel value.
    ASSERT(len == 2);
    // Static calls with no argument checks only need two words.
    ASSERT(TestEntryLength() == 2);
    // Set the target.
    data.SetAt(TargetIndexFor(num_args_tested), func);
    // Set count to 0 as this is called during compilation, before the
    // call has been executed.
    data.SetAt(CountIndexFor(num_args_tested), Object::smi_zero());
  } else {
    // Type feedback on arguments is being collected.
    // Fill all but the first entry with the sentinel.
    for (intptr_t i = len - 1; i > 0; i--) {
      WriteSentinelAt(i, proof_of_reload);
    }
    REUSABLE_ARRAY_HANDLESCOPE(thread);
    Array& data = thread->ArrayHandle();
    data = entries();
    // Rewrite the dummy entry.
    const Smi& object_cid = Smi::Handle(Smi::New(kObjectCid));
    for (intptr_t i = 0; i < NumArgsTested(); i++) {
      data.SetAt(i, object_cid);
    }
    data.SetAt(TargetIndexFor(num_args_tested), func);
    data.SetAt(CountIndexFor(num_args_tested), Object::smi_zero());
  }
}

bool ICData::ValidateInterceptor(const Function& target) const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const String& name = String::Handle(target_name());
  if (Function::IsDynamicInvocationForwarderName(name)) {
    return Function::DemangleDynamicInvocationForwarderName(name) ==
           target.name();
  }
#endif
  ObjectStore* store = Isolate::Current()->object_store();
  ASSERT((target.raw() == store->simple_instance_of_true_function()) ||
         (target.raw() == store->simple_instance_of_false_function()));
  const String& instance_of_name = String::Handle(
      Library::PrivateCoreLibName(Symbols::_simpleInstanceOf()).raw());
  ASSERT(target_name() == instance_of_name.raw());
  return true;
}

void ICData::EnsureHasCheck(const GrowableArray<intptr_t>& class_ids,
                            const Function& target,
                            intptr_t count) const {
  SafepointMutexLocker ml(IsolateGroup::Current()->type_feedback_mutex());

  if (FindCheck(class_ids) != -1) return;
  AddCheckInternal(class_ids, target, count);
}

void ICData::AddCheck(const GrowableArray<intptr_t>& class_ids,
                      const Function& target,
                      intptr_t count) const {
  SafepointMutexLocker ml(IsolateGroup::Current()->type_feedback_mutex());
  AddCheckInternal(class_ids, target, count);
}

void ICData::AddCheckInternal(const GrowableArray<intptr_t>& class_ids,
                              const Function& target,
                              intptr_t count) const {
  ASSERT(
      IsolateGroup::Current()->type_feedback_mutex()->IsOwnedByCurrentThread());

  ASSERT(!is_tracking_exactness());
  ASSERT(!target.IsNull());
  ASSERT((target.name() == target_name()) || ValidateInterceptor(target));
  DEBUG_ASSERT(!HasCheck(class_ids));
  ASSERT(NumArgsTested() > 1);  // Otherwise use 'AddReceiverCheck'.
  const intptr_t num_args_tested = NumArgsTested();
  ASSERT(class_ids.length() == num_args_tested);
  const intptr_t old_num = NumberOfChecks();
  Array& data = Array::Handle(entries());

  // ICData of static calls with NumArgsTested() > 0 have initially a
  // dummy set of cids entered (see ICData::NewForStaticCall). That entry is
  // overwritten by first real type feedback data.
  if (old_num == 1 && num_args_tested == 2) {
    const bool has_dummy_entry =
        Smi::Value(Smi::RawCast(data.At(0))) == kObjectCid &&
        Smi::Value(Smi::RawCast(data.At(1))) == kObjectCid;
    if (has_dummy_entry) {
      ASSERT(target.raw() == data.At(TargetIndexFor(num_args_tested)));
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
  data = Grow(&index);
  ASSERT(!data.IsNull());
  intptr_t data_pos = index * TestEntryLength();
  Smi& value = Smi::Handle();
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    // kIllegalCid is used as terminating value, do not add it.
    ASSERT(class_ids[i] != kIllegalCid);
    value = Smi::New(class_ids[i]);
    data.SetAt(data_pos + i, value);
  }
  ASSERT(!target.IsNull());
  data.SetAt(data_pos + TargetIndexFor(num_args_tested), target);
  value = Smi::New(count);
  data.SetAt(data_pos + CountIndexFor(num_args_tested), value);
  // Multithreaded access to ICData requires setting of array to be the last
  // operation.
  set_entries(data);
}

ArrayPtr ICData::Grow(intptr_t* index) const {
  Array& data = Array::Handle(entries());
  // Last entry in array should be a sentinel and will be the new entry
  // that can be updated after growing.
  *index = Length() - 1;
  ASSERT(*index >= 0);
  ASSERT(IsSentinelAt(*index));
  // Grow the array and write the new final sentinel into place.
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

void ICData::EnsureHasReceiverCheck(intptr_t receiver_class_id,
                                    const Function& target,
                                    intptr_t count,
                                    StaticTypeExactnessState exactness) const {
  SafepointMutexLocker ml(IsolateGroup::Current()->type_feedback_mutex());

  GrowableArray<intptr_t> class_ids(1);
  class_ids.Add(receiver_class_id);
  if (FindCheck(class_ids) != -1) return;

  AddReceiverCheckInternal(receiver_class_id, target, count, exactness);
}

void ICData::AddReceiverCheck(intptr_t receiver_class_id,
                              const Function& target,
                              intptr_t count,
                              StaticTypeExactnessState exactness) const {
  SafepointMutexLocker ml(IsolateGroup::Current()->type_feedback_mutex());
  AddReceiverCheckInternal(receiver_class_id, target, count, exactness);
}

void ICData::AddReceiverCheckInternal(
    intptr_t receiver_class_id,
    const Function& target,
    intptr_t count,
    StaticTypeExactnessState exactness) const {
#if defined(DEBUG)
  GrowableArray<intptr_t> class_ids(1);
  class_ids.Add(receiver_class_id);
  ASSERT(!HasCheck(class_ids));
#endif  // DEBUG
  ASSERT(!target.IsNull());
  const intptr_t kNumArgsTested = 1;
  ASSERT(NumArgsTested() == kNumArgsTested);  // Otherwise use 'AddCheck'.
  ASSERT(receiver_class_id != kIllegalCid);

  intptr_t index = -1;
  Array& data = Array::Handle(Grow(&index));
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
  SetTargetAtPos(data, data_pos, kNumArgsTested, target);

#if !defined(DART_PRECOMPILED_RUNTIME)
  data.SetAt(data_pos + CountIndexFor(kNumArgsTested),
             Smi::Handle(Smi::New(count)));
  if (is_tracking_exactness()) {
    data.SetAt(data_pos + ExactnessIndexFor(kNumArgsTested),
               Smi::Handle(Smi::New(exactness.Encode())));
  }
#endif

  // Multithreaded access to ICData requires setting of array to be the last
  // operation.
  set_entries(data);
}

StaticTypeExactnessState ICData::GetExactnessAt(intptr_t index) const {
  if (!is_tracking_exactness()) {
    return StaticTypeExactnessState::NotTracking();
  }
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
  intptr_t data_pos =
      index * TestEntryLength() + ExactnessIndexFor(NumArgsTested());
  return StaticTypeExactnessState::Decode(
      Smi::Value(Smi::RawCast(data.At(data_pos))));
}

void ICData::GetCheckAt(intptr_t index,
                        GrowableArray<intptr_t>* class_ids,
                        Function* target) const {
  ASSERT(index < NumberOfChecks());
  ASSERT(class_ids != NULL);
  ASSERT(target != NULL);
  class_ids->Clear();
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
  intptr_t data_pos = index * TestEntryLength();
  for (intptr_t i = 0; i < NumArgsTested(); i++) {
    class_ids->Add(Smi::Value(Smi::RawCast(data.At(data_pos + i))));
  }
  (*target) ^= data.At(data_pos + TargetIndexFor(NumArgsTested()));
}

bool ICData::IsSentinelAt(intptr_t index) const {
  ASSERT(index < Length());
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
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
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
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
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
  const intptr_t data_pos = index * TestEntryLength();
  *class_id = Smi::Value(Smi::RawCast(data.At(data_pos)));
  *target ^= data.At(data_pos + TargetIndexFor(NumArgsTested()));
}

intptr_t ICData::GetCidAt(intptr_t index) const {
  ASSERT(NumArgsTested() == 1);
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
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
  ArrayPtr raw_data = entries();
  return Smi::Value(Smi::RawCast(raw_data->ptr()->data()[data_pos]));
}

FunctionPtr ICData::GetTargetAt(intptr_t index) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return nullptr;
#else
  const intptr_t data_pos =
      index * TestEntryLength() + TargetIndexFor(NumArgsTested());
  ASSERT(Object::Handle(Array::Handle(entries()).At(data_pos)).IsFunction());

  NoSafepointScope no_safepoint;
  ArrayPtr raw_data = entries();
  return static_cast<FunctionPtr>(raw_data->ptr()->data()[data_pos]);
#endif
}

void ICData::IncrementCountAt(intptr_t index, intptr_t value) const {
  ASSERT(0 <= value);
  ASSERT(value <= Smi::kMaxValue);
  SetCountAt(index, Utils::Minimum(GetCountAt(index) + value, Smi::kMaxValue));
}

void ICData::SetCountAt(intptr_t index, intptr_t value) const {
  ASSERT(0 <= value);
  ASSERT(value <= Smi::kMaxValue);

  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
  const intptr_t data_pos =
      index * TestEntryLength() + CountIndexFor(NumArgsTested());
  data.SetAt(data_pos, Smi::Handle(Smi::New(value)));
}

intptr_t ICData::GetCountAt(intptr_t index) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return 0;
#else
  Thread* thread = Thread::Current();
  REUSABLE_ARRAY_HANDLESCOPE(thread);
  Array& data = thread->ArrayHandle();
  data = entries();
  const intptr_t data_pos =
      index * TestEntryLength() + CountIndexFor(NumArgsTested());
  intptr_t value = Smi::Value(Smi::RawCast(data.At(data_pos)));
  if (value >= 0) return value;

  // The counter very rarely overflows to a negative value, but if it does, we
  // would rather just reset it to zero.
  SetCountAt(index, 0);
  return 0;
#endif
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

#if !defined(DART_PRECOMPILED_RUNTIME)
ICDataPtr ICData::AsUnaryClassChecksForArgNr(intptr_t arg_nr) const {
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
      result.AddReceiverCheckInternal(class_id,
                                      Function::Handle(GetTargetAt(i)), count,
                                      StaticTypeExactnessState::NotTracking());
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

ICDataPtr ICData::AsUnaryClassChecksSortedByCount() const {
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
  result.set_entries(data);
  ASSERT(result.NumberOfChecksIs(aggregate.length()));
  return result.raw();
}

UnlinkedCallPtr ICData::AsUnlinkedCall() const {
  ASSERT(NumArgsTested() == 1);
  ASSERT(!is_tracking_exactness());
  const UnlinkedCall& result = UnlinkedCall::Handle(UnlinkedCall::New());
  result.set_target_name(String::Handle(target_name()));
  result.set_arguments_descriptor(Array::Handle(arguments_descriptor()));
  result.set_can_patch_to_monomorphic(!FLAG_precompiled_mode ||
                                      receiver_cannot_be_smi());
  return result.raw();
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
#endif

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

void ICData::Init() {
  for (int i = 0; i <= kCachedICDataMaxArgsTestedWithoutExactnessTracking;
       i++) {
    cached_icdata_arrays_
        [kCachedICDataZeroArgTestedWithoutExactnessTrackingIdx + i] =
            ICData::NewNonCachedEmptyICDataArray(i, false);
  }
  cached_icdata_arrays_[kCachedICDataOneArgWithExactnessTrackingIdx] =
      ICData::NewNonCachedEmptyICDataArray(1, true);
}

void ICData::Cleanup() {
  for (int i = 0; i < kCachedICDataArrayCount; ++i) {
    cached_icdata_arrays_[i] = NULL;
  }
}

ArrayPtr ICData::NewNonCachedEmptyICDataArray(intptr_t num_args_tested,
                                              bool tracking_exactness) {
  // IC data array must be null terminated (sentinel entry).
  const intptr_t len = TestEntryLengthFor(num_args_tested, tracking_exactness);
  const Array& array = Array::Handle(Array::New(len, Heap::kOld));
  WriteSentinel(array, len);
  array.MakeImmutable();
  return array.raw();
}

ArrayPtr ICData::CachedEmptyICDataArray(intptr_t num_args_tested,
                                        bool tracking_exactness) {
  if (tracking_exactness) {
    ASSERT(num_args_tested == 1);
    return cached_icdata_arrays_[kCachedICDataOneArgWithExactnessTrackingIdx];
  } else {
    ASSERT(num_args_tested >= 0);
    ASSERT(num_args_tested <=
           kCachedICDataMaxArgsTestedWithoutExactnessTracking);
    return cached_icdata_arrays_
        [kCachedICDataZeroArgTestedWithoutExactnessTrackingIdx +
         num_args_tested];
  }
}

// Does not initialize ICData array.
ICDataPtr ICData::NewDescriptor(Zone* zone,
                                const Function& owner,
                                const String& target_name,
                                const Array& arguments_descriptor,
                                intptr_t deopt_id,
                                intptr_t num_args_tested,
                                RebindRule rebind_rule,
                                const AbstractType& receivers_static_type) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // We should only have null owners in the precompiled runtime, if the
  // owning function for a Code object was optimized out.
  ASSERT(!owner.IsNull());
#endif
  ASSERT(!target_name.IsNull());
  ASSERT(!arguments_descriptor.IsNull());
  ASSERT(Object::icdata_class() != Class::null());
  ASSERT(num_args_tested >= 0);
  ICData& result = ICData::Handle(zone);
  {
    // IC data objects are long living objects, allocate them in old generation.
    ObjectPtr raw =
        Object::Allocate(ICData::kClassId, ICData::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_owner(owner);
  result.set_target_name(target_name);
  result.set_arguments_descriptor(arguments_descriptor);
  NOT_IN_PRECOMPILED(result.set_deopt_id(deopt_id));
  result.set_state_bits(0);
  result.set_rebind_rule(rebind_rule);
  result.SetNumArgsTested(num_args_tested);
  NOT_IN_PRECOMPILED(result.SetReceiversStaticType(receivers_static_type));
  return result.raw();
}

bool ICData::IsImmutable() const {
  return entries()->IsImmutableArray();
}

ICDataPtr ICData::New() {
  ICData& result = ICData::Handle();
  {
    // IC data objects are long living objects, allocate them in old generation.
    ObjectPtr raw =
        Object::Allocate(ICData::kClassId, ICData::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_deopt_id(DeoptId::kNone);
  result.set_state_bits(0);
  return result.raw();
}

ICDataPtr ICData::New(const Function& owner,
                      const String& target_name,
                      const Array& arguments_descriptor,
                      intptr_t deopt_id,
                      intptr_t num_args_tested,
                      RebindRule rebind_rule,
                      const AbstractType& receivers_static_type) {
  Zone* zone = Thread::Current()->zone();
  const ICData& result = ICData::Handle(
      zone,
      NewDescriptor(zone, owner, target_name, arguments_descriptor, deopt_id,
                    num_args_tested, rebind_rule, receivers_static_type));
  result.set_entries(Array::Handle(
      zone,
      CachedEmptyICDataArray(num_args_tested, result.is_tracking_exactness())));
  return result.raw();
}

ICDataPtr ICData::NewWithCheck(const Function& owner,
                               const String& target_name,
                               const Array& arguments_descriptor,
                               intptr_t deopt_id,
                               intptr_t num_args_tested,
                               RebindRule rebind_rule,
                               GrowableArray<intptr_t>* cids,
                               const Function& target,
                               const AbstractType& receiver_type) {
  ASSERT((cids != nullptr) && !target.IsNull());
  ASSERT(cids->length() == num_args_tested);

  Zone* zone = Thread::Current()->zone();
  const auto& result = ICData::Handle(
      zone,
      NewDescriptor(zone, owner, target_name, arguments_descriptor, deopt_id,
                    num_args_tested, rebind_rule, receiver_type));

  const intptr_t kNumEntries = 2;  // 1 entry and a sentinel.
  const intptr_t entry_len =
      TestEntryLengthFor(num_args_tested, result.is_tracking_exactness());
  const auto& array =
      Array::Handle(zone, Array::New(kNumEntries * entry_len, Heap::kOld));

  auto& cid = Smi::Handle(zone);
  for (intptr_t i = 0; i < num_args_tested; ++i) {
    cid = Smi::New((*cids)[i]);
    array.SetAt(i, cid);
  }

  SetTargetAtPos(array, 0, num_args_tested, target);
#if !defined(DART_PRECOMPILED_RUNTIME)
  array.SetAt(CountIndexFor(num_args_tested), Object::smi_zero());
#endif
  WriteSentinel(array, entry_len);

  result.set_entries(array);

  return result.raw();
}

ICDataPtr ICData::NewForStaticCall(const Function& owner,
                                   const Function& target,
                                   const Array& arguments_descriptor,
                                   intptr_t deopt_id,
                                   intptr_t num_args_tested,
                                   RebindRule rebind_rule) {
  // See `MethodRecognizer::NumArgsCheckedForStaticCall`.
  ASSERT(num_args_tested == 0 || num_args_tested == 2);
  ASSERT(!target.IsNull());

  Zone* zone = Thread::Current()->zone();
  const auto& target_name = String::Handle(zone, target.name());
  GrowableArray<intptr_t> cids(num_args_tested);
  if (num_args_tested == 2) {
    cids.Add(kObjectCid);
    cids.Add(kObjectCid);
  }
  return ICData::NewWithCheck(owner, target_name, arguments_descriptor,
                              deopt_id, num_args_tested, rebind_rule, &cids,
                              target, Object::null_abstract_type());
}

#if !defined(DART_PRECOMPILED_RUNTIME)
ICDataPtr ICData::NewFrom(const ICData& from, intptr_t num_args_tested) {
  // See comment in [ICData::Clone] why we access the megamorphic bit first.
  const bool is_megamorphic = from.is_megamorphic();

  const ICData& result = ICData::Handle(ICData::New(
      Function::Handle(from.Owner()), String::Handle(from.target_name()),
      Array::Handle(from.arguments_descriptor()), from.deopt_id(),
      num_args_tested, from.rebind_rule(),
      AbstractType::Handle(from.receivers_static_type())));
  // Copy deoptimization reasons.
  result.SetDeoptReasons(from.DeoptReasons());
  result.set_is_megamorphic(is_megamorphic);
  return result.raw();
}

ICDataPtr ICData::Clone(const ICData& from) {
  Zone* zone = Thread::Current()->zone();

  // We have to check the megamorphic bit before accessing the entries of the
  // ICData to ensure all writes to the entries have been flushed and are
  // visible at this point.
  //
  // This will allow us to maintain the invariant that if the megamorphic bit is
  // set, the number of entries in the ICData have reached the limit.
  const bool is_megamorphic = from.is_megamorphic();

  const ICData& result = ICData::Handle(
      zone, ICData::NewDescriptor(
                zone, Function::Handle(zone, from.Owner()),
                String::Handle(zone, from.target_name()),
                Array::Handle(zone, from.arguments_descriptor()),
                from.deopt_id(), from.NumArgsTested(), from.rebind_rule(),
                AbstractType::Handle(zone, from.receivers_static_type())));
  // Clone entry array.
  const Array& from_array = Array::Handle(zone, from.entries());
  const intptr_t len = from_array.Length();
  const Array& cloned_array = Array::Handle(zone, Array::New(len, Heap::kOld));
  Object& obj = Object::Handle(zone);
  for (intptr_t i = 0; i < len; i++) {
    obj = from_array.At(i);
    cloned_array.SetAt(i, obj);
  }
  result.set_entries(cloned_array);
  // Copy deoptimization reasons.
  result.SetDeoptReasons(from.DeoptReasons());
  result.set_is_megamorphic(is_megamorphic);

  RELEASE_ASSERT(!is_megamorphic ||
                 result.NumberOfChecks() >= FLAG_max_polymorphic_checks);

  return result.raw();
}
#endif

const char* WeakSerializationReference::ToCString() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Symbols::OptimizedOut().ToCString();
#else
  return Object::Handle(target()).ToCString();
#endif
}

#if defined(DART_PRECOMPILER)
bool WeakSerializationReference::CanWrap(const Object& object) {
  // Currently we do not wrap the null object (which cannot be dropped from
  // snapshots), non-heap objects, and WSRs (as there is no point in deeply
  // nesting them). We also only wrap objects in the precompiler.
  return FLAG_precompiled_mode && !object.IsNull() &&
         object.raw()->IsHeapObject() && !object.IsWeakSerializationReference();
}

ObjectPtr WeakSerializationReference::Wrap(Zone* zone, const Object& target) {
  if (!CanWrap(target)) return target.raw();
  ASSERT(Object::weak_serialization_reference_class() != Class::null());
  WeakSerializationReference& result = WeakSerializationReference::Handle(zone);
  {
    ObjectPtr raw = Object::Allocate(WeakSerializationReference::kClassId,
                                     WeakSerializationReference::InstanceSize(),
                                     Heap::kOld);
    NoSafepointScope no_safepoint;

    result ^= raw;
    result.raw_ptr()->set_target(target.raw());
  }
  return result.raw();
}
#endif

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

StringPtr Code::Comments::CommentAt(intptr_t idx) const {
  return String::RawCast(comments_.At(idx * kNumberOfEntries + kCommentEntry));
}

void Code::Comments::SetCommentAt(intptr_t idx, const String& comment) {
  comments_.SetAt(idx * kNumberOfEntries + kCommentEntry, comment);
}

Code::Comments::Comments(const Array& comments) : comments_(comments) {}

const char* Code::EntryKindToCString(EntryKind kind) {
  switch (kind) {
    case EntryKind::kNormal:
      return "Normal";
    case EntryKind::kUnchecked:
      return "Unchecked";
    case EntryKind::kMonomorphic:
      return "Monomorphic";
    case EntryKind::kMonomorphicUnchecked:
      return "MonomorphicUnchecked";
    default:
      UNREACHABLE();
      return nullptr;
  }
}

bool Code::ParseEntryKind(const char* str, EntryKind* out) {
  if (strcmp(str, "Normal") == 0) {
    *out = EntryKind::kNormal;
    return true;
  } else if (strcmp(str, "Unchecked") == 0) {
    *out = EntryKind::kUnchecked;
    return true;
  } else if (strcmp(str, "Monomorphic") == 0) {
    *out = EntryKind::kMonomorphic;
    return true;
  } else if (strcmp(str, "MonomorphicUnchecked") == 0) {
    *out = EntryKind::kMonomorphicUnchecked;
    return true;
  }
  return false;
}

LocalVarDescriptorsPtr Code::GetLocalVarDescriptors() const {
  const LocalVarDescriptors& v = LocalVarDescriptors::Handle(var_descriptors());
  if (v.IsNull()) {
    ASSERT(!is_optimized());
    const Function& f = Function::Handle(function());
    ASSERT(!f.IsIrregexpFunction());  // Not yet implemented.
    Compiler::ComputeLocalVarDescriptors(*this);
  }
  return var_descriptors();
}

void Code::set_owner(const Object& owner) const {
#if defined(DEBUG)
  const auto& unwrapped_owner =
      Object::Handle(WeakSerializationReference::Unwrap(owner));
  ASSERT(unwrapped_owner.IsFunction() || unwrapped_owner.IsClass() ||
         unwrapped_owner.IsAbstractType());
#endif
  raw_ptr()->set_owner(owner.raw());
}

void Code::set_state_bits(intptr_t bits) const {
  StoreNonPointer(&raw_ptr()->state_bits_, bits);
}

void Code::set_is_optimized(bool value) const {
  set_state_bits(OptimizedBit::update(value, raw_ptr()->state_bits_));
}

void Code::set_is_force_optimized(bool value) const {
  set_state_bits(ForceOptimizedBit::update(value, raw_ptr()->state_bits_));
}

void Code::set_is_alive(bool value) const {
  set_state_bits(AliveBit::update(value, raw_ptr()->state_bits_));
}

void Code::set_compressed_stackmaps(const CompressedStackMaps& maps) const {
  ASSERT(maps.IsOld());
  raw_ptr()->set_compressed_stackmaps(maps.raw());
}

#if !defined(DART_PRECOMPILED_RUNTIME)
intptr_t Code::num_variables() const {
  ASSERT(!FLAG_precompiled_mode);
  return Smi::Value(Smi::RawCast(raw_ptr()->catch_entry()));
}
void Code::set_num_variables(intptr_t num_variables) const {
  ASSERT(!FLAG_precompiled_mode);
  raw_ptr()->set_catch_entry(Smi::New(num_variables));
}
#endif

#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
TypedDataPtr Code::catch_entry_moves_maps() const {
  ASSERT(FLAG_precompiled_mode);
  return TypedData::RawCast(raw_ptr()->catch_entry());
}
void Code::set_catch_entry_moves_maps(const TypedData& maps) const {
  ASSERT(FLAG_precompiled_mode);
  raw_ptr()->set_catch_entry(maps.raw());
}
#endif

void Code::set_deopt_info_array(const Array& array) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  ASSERT(array.IsOld());
  raw_ptr()->set_deopt_info_array(array.raw());
#endif
}

void Code::set_static_calls_target_table(const Array& value) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  raw_ptr()->set_static_calls_target_table(value.raw());
#endif
#if defined(DEBUG)
  // Check that the table is sorted by pc offsets.
  // FlowGraphCompiler::AddStaticCallTarget adds pc-offsets to the table while
  // emitting assembly. This guarantees that every succeeding pc-offset is
  // larger than the previously added one.
  StaticCallsTable entries(value);
  const intptr_t count = entries.Length();
  for (intptr_t i = 0; i < count - 1; ++i) {
    auto left = Smi::Value(entries[i].Get<kSCallTableKindAndOffset>());
    auto right = Smi::Value(entries[i + 1].Get<kSCallTableKindAndOffset>());
    ASSERT(OffsetField::decode(left) < OffsetField::decode(right));
  }
#endif  // DEBUG
}

ObjectPoolPtr Code::GetObjectPool() const {
#if defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    return Isolate::Current()->object_store()->global_object_pool();
  }
#endif
  return object_pool();
}

bool Code::HasBreakpoint() const {
#if defined(PRODUCT)
  return false;
#else
  return Isolate::Current()->debugger()->HasBreakpoint(*this);
#endif
}

TypedDataPtr Code::GetDeoptInfoAtPc(uword pc,
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
  const Array& table = Array::Handle(raw_ptr()->static_calls_target_table());
  StaticCallsTable entries(table);
  const intptr_t pc_offset = pc - PayloadStart();
  intptr_t imin = 0;
  intptr_t imax = (table.Length() / kSCallTableEntryLength) - 1;
  while (imax >= imin) {
    const intptr_t imid = imin + (imax - imin) / 2;
    const auto offset = OffsetField::decode(
        Smi::Value(entries[imid].Get<kSCallTableKindAndOffset>()));
    if (offset < pc_offset) {
      imin = imid + 1;
    } else if (offset > pc_offset) {
      imax = imid - 1;
    } else {
      return imid;
    }
  }
#endif
  return -1;
}

FunctionPtr Code::GetStaticCallTargetFunctionAt(uword pc) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return Function::null();
#else
  const intptr_t i = BinarySearchInSCallTable(pc);
  if (i < 0) {
    return Function::null();
  }
  const Array& array = Array::Handle(raw_ptr()->static_calls_target_table());
  StaticCallsTable entries(array);
  return entries[i].Get<kSCallTableFunctionTarget>();
#endif
}

void Code::SetStaticCallTargetCodeAt(uword pc, const Code& code) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  const intptr_t i = BinarySearchInSCallTable(pc);
  ASSERT(i >= 0);
  const Array& array = Array::Handle(raw_ptr()->static_calls_target_table());
  StaticCallsTable entries(array);
  ASSERT(code.IsNull() ||
         (code.function() == entries[i].Get<kSCallTableFunctionTarget>()));
  return entries[i].Set<kSCallTableCodeOrTypeTarget>(code);
#endif
}

void Code::SetStubCallTargetCodeAt(uword pc, const Code& code) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  const intptr_t i = BinarySearchInSCallTable(pc);
  ASSERT(i >= 0);
  const Array& array = Array::Handle(raw_ptr()->static_calls_target_table());
  StaticCallsTable entries(array);
#if defined(DEBUG)
  if (entries[i].Get<kSCallTableFunctionTarget>() == Function::null()) {
    ASSERT(!code.IsNull() && Object::Handle(code.owner()).IsClass());
  } else {
    ASSERT(code.IsNull() ||
           (code.function() == entries[i].Get<kSCallTableFunctionTarget>()));
  }
#endif
  return entries[i].Set<kSCallTableCodeOrTypeTarget>(code);
#endif
}

void Code::Disassemble(DisassemblyFormatter* formatter) const {
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
  if (!FLAG_support_disassembler) {
    return;
  }
  const uword start = PayloadStart();
  if (formatter == NULL) {
    Disassembler::Disassemble(start, start + Size(), *this);
  } else {
    Disassembler::Disassemble(start, start + Size(), formatter, *this);
  }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
}

const Code::Comments& Code::comments() const {
#if defined(PRODUCT)
  Comments* comments = new Code::Comments(Array::Handle());
#else
  Comments* comments = new Code::Comments(Array::Handle(raw_ptr()->comments()));
#endif
  return *comments;
}

void Code::set_comments(const Code::Comments& comments) const {
#if defined(PRODUCT)
  UNREACHABLE();
#else
  ASSERT(comments.comments_.IsOld());
  raw_ptr()->set_comments(comments.comments_.raw());
#endif
}

void Code::SetPrologueOffset(intptr_t offset) const {
#if defined(PRODUCT)
  UNREACHABLE();
#else
  ASSERT(offset >= 0);
  raw_ptr()->set_return_address_metadata(Smi::New(offset));
#endif
}

intptr_t Code::GetPrologueOffset() const {
#if defined(PRODUCT)
  UNREACHABLE();
  return -1;
#else
  const Object& object = Object::Handle(raw_ptr()->return_address_metadata());
  // In the future we may put something other than a smi in
  // |return_address_metadata_|.
  if (object.IsNull() || !object.IsSmi()) {
    return -1;
  }
  return Smi::Cast(object).Value();
#endif
}

ArrayPtr Code::inlined_id_to_function() const {
  return raw_ptr()->inlined_id_to_function();
}

void Code::set_inlined_id_to_function(const Array& value) const {
  ASSERT(value.IsOld());
  raw_ptr()->set_inlined_id_to_function(value.raw());
}

CodePtr Code::New(intptr_t pointer_offsets_length) {
  if (pointer_offsets_length < 0 || pointer_offsets_length > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Code::New: invalid pointer_offsets_length %" Pd "\n",
           pointer_offsets_length);
  }
  ASSERT(Object::code_class() != Class::null());
  Code& result = Code::Handle();
  {
    uword size = Code::InstanceSize(pointer_offsets_length);
    ObjectPtr raw = Object::Allocate(Code::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_pointer_offsets_length(pointer_offsets_length);
    result.set_is_optimized(false);
    result.set_is_force_optimized(false);
    result.set_is_alive(false);
    NOT_IN_PRODUCT(result.set_comments(Comments::New(0)));
    NOT_IN_PRODUCT(result.set_compile_timestamp(0));
    result.set_pc_descriptors(Object::empty_descriptors());
    result.set_compressed_stackmaps(Object::empty_compressed_stackmaps());
  }
  return result.raw();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
CodePtr Code::FinalizeCodeAndNotify(const Function& function,
                                    FlowGraphCompiler* compiler,
                                    compiler::Assembler* assembler,
                                    PoolAttachment pool_attachment,
                                    bool optimized,
                                    CodeStatistics* stats) {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  const auto& code = Code::Handle(
      FinalizeCode(compiler, assembler, pool_attachment, optimized, stats));
  NotifyCodeObservers(function, code, optimized);
  return code.raw();
}

CodePtr Code::FinalizeCodeAndNotify(const char* name,
                                    FlowGraphCompiler* compiler,
                                    compiler::Assembler* assembler,
                                    PoolAttachment pool_attachment,
                                    bool optimized,
                                    CodeStatistics* stats) {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  const auto& code = Code::Handle(
      FinalizeCode(compiler, assembler, pool_attachment, optimized, stats));
  NotifyCodeObservers(name, code, optimized);
  return code.raw();
}

#if defined(DART_PRECOMPILER)
DECLARE_FLAG(charp, write_v8_snapshot_profile_to);
DECLARE_FLAG(charp, trace_precompiler_to);
#endif  // defined(DART_PRECOMPILER)

CodePtr Code::FinalizeCode(FlowGraphCompiler* compiler,
                           compiler::Assembler* assembler,
                           PoolAttachment pool_attachment,
                           bool optimized,
                           CodeStatistics* stats /* = nullptr */) {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());

  ASSERT(assembler != NULL);
  ObjectPool& object_pool = ObjectPool::Handle();

  if (pool_attachment == PoolAttachment::kAttachPool) {
    if (assembler->HasObjectPoolBuilder()) {
      object_pool =
          ObjectPool::NewFromBuilder(assembler->object_pool_builder());
    } else {
      object_pool = ObjectPool::empty_object_pool().raw();
    }
  } else {
#if defined(DART_PRECOMPILER)
    const bool needs_pool = (FLAG_write_v8_snapshot_profile_to != nullptr) ||
                            (FLAG_trace_precompiler_to != nullptr);
    if (needs_pool && assembler->HasObjectPoolBuilder() &&
        assembler->object_pool_builder().HasParent()) {
      // We are not going to write this pool into snapshot, but we will use
      // it to emit references from this code object to other objects in the
      // snapshot that it uses.
      object_pool =
          ObjectPool::NewFromBuilder(assembler->object_pool_builder());
    }
#endif  // defined(DART_PRECOMPILER)
  }

  // Allocate the Code and Instructions objects.  Code is allocated first
  // because a GC during allocation of the code will leave the instruction
  // pages read-only.
  intptr_t pointer_offset_count = assembler->CountPointerOffsets();
  Code& code = Code::ZoneHandle(Code::New(pointer_offset_count));
#ifdef TARGET_ARCH_IA32
  assembler->GetSelfHandle() = code.raw();
#endif
  Instructions& instrs = Instructions::ZoneHandle(Instructions::New(
      assembler->CodeSize(), assembler->has_monomorphic_entry()));

  {
    // Important: if GC is triggerred at any point between Instructions::New
    // and here it would write protect instructions object that we are trying
    // to fill in.
    NoSafepointScope no_safepoint;

    // Copy the instructions into the instruction area and apply all fixups.
    // Embedded pointers are still in handles at this point.
    MemoryRegion region(reinterpret_cast<void*>(instrs.PayloadStart()),
                        instrs.Size());
    assembler->FinalizeInstructions(region);

    const auto& pointer_offsets = assembler->GetPointerOffsets();
    ASSERT(pointer_offsets.length() == pointer_offset_count);
    ASSERT(code.pointer_offsets_length() == pointer_offsets.length());

    // Set pointer offsets list in Code object and resolve all handles in
    // the instruction stream to raw objects.
    Thread* thread = Thread::Current();
    for (intptr_t i = 0; i < pointer_offsets.length(); i++) {
      intptr_t offset_in_instrs = pointer_offsets[i];
      code.SetPointerOffsetAt(i, offset_in_instrs);
      uword addr = region.start() + offset_in_instrs;
      ASSERT(instrs.PayloadStart() <= addr);
      ASSERT((instrs.PayloadStart() + instrs.Size()) > addr);
      const Object* object = LoadUnaligned(reinterpret_cast<Object**>(addr));
      ASSERT(object->IsOld());
      // N.B. The pointer is embedded in the Instructions object, but visited
      // through the Code object.
      code.raw()->ptr()->StorePointerUnaligned(
          reinterpret_cast<ObjectPtr*>(addr), object->raw(), thread);
    }

    // Write protect instructions and, if supported by OS, use dual mapping
    // for execution.
    if (FLAG_write_protect_code) {
      uword address = ObjectLayout::ToAddr(instrs.raw());
      // Check if a dual mapping exists.
      instrs = Instructions::RawCast(OldPage::ToExecutable(instrs.raw()));
      uword exec_address = ObjectLayout::ToAddr(instrs.raw());
      const bool use_dual_mapping = exec_address != address;
      ASSERT(use_dual_mapping == FLAG_dual_map_code);

      // When dual mapping is enabled the executable mapping is RX from the
      // point of allocation and never changes protection.
      // Yet the writable mapping is still turned back from RW to R.
      if (use_dual_mapping) {
        VirtualMemory::Protect(reinterpret_cast<void*>(address),
                               instrs.raw()->ptr()->HeapSize(),
                               VirtualMemory::kReadOnly);
        address = exec_address;
      } else {
        // If dual mapping is disabled and we write protect then we have to
        // change the single mapping from RW -> RX.
        VirtualMemory::Protect(reinterpret_cast<void*>(address),
                               instrs.raw()->ptr()->HeapSize(),
                               VirtualMemory::kReadExecute);
      }
    }

    // Hook up Code and Instructions objects.
    const uword unchecked_offset = assembler->UncheckedEntryOffset();
    code.SetActiveInstructions(instrs, unchecked_offset);
    code.set_instructions(instrs);
    NOT_IN_PRECOMPILED(code.set_unchecked_offset(unchecked_offset));
    code.set_is_alive(true);

    // Set object pool in Instructions object.
    if (!object_pool.IsNull()) {
      code.set_object_pool(object_pool.raw());
    }

#if defined(DART_PRECOMPILER)
    if (stats != nullptr) {
      stats->Finalize();
      instrs.set_stats(stats);
    }
#endif

    CPU::FlushICache(instrs.PayloadStart(), instrs.Size());
  }

#ifndef PRODUCT
  code.set_compile_timestamp(OS::GetCurrentMonotonicMicros());
  code.set_comments(CreateCommentsFrom(assembler));
  if (assembler->prologue_offset() >= 0) {
    code.SetPrologueOffset(assembler->prologue_offset());
  } else {
    // No prologue was ever entered, optimistically assume nothing was ever
    // pushed onto the stack.
    code.SetPrologueOffset(assembler->CodeSize());
  }
#endif
  return code.raw();
}

void Code::NotifyCodeObservers(const Code& code, bool optimized) {
#if !defined(PRODUCT)
  ASSERT(!Thread::Current()->IsAtSafepoint());
  if (CodeObservers::AreActive()) {
    if (code.IsFunctionCode()) {
      const auto& function = Function::Handle(code.function());
      if (!function.IsNull()) {
        return NotifyCodeObservers(function, code, optimized);
      }
    }
    NotifyCodeObservers(code.Name(), code, optimized);
  }
#endif
}

void Code::NotifyCodeObservers(const Function& function,
                               const Code& code,
                               bool optimized) {
#if !defined(PRODUCT)
  ASSERT(!function.IsNull());
  ASSERT(!Thread::Current()->IsAtSafepoint());
  // Calling ToLibNamePrefixedQualifiedCString is very expensive,
  // try to avoid it.
  if (CodeObservers::AreActive()) {
    const char* name = function.ToLibNamePrefixedQualifiedCString();
    NotifyCodeObservers(name, code, optimized);
  }
#endif
}

void Code::NotifyCodeObservers(const char* name,
                               const Code& code,
                               bool optimized) {
#if !defined(PRODUCT)
  ASSERT(name != nullptr);
  ASSERT(!code.IsNull());
  ASSERT(!Thread::Current()->IsAtSafepoint());
  if (CodeObservers::AreActive()) {
    const auto& instrs = Instructions::Handle(code.instructions());
    CodeCommentsWrapper comments_wrapper(code.comments());
    CodeObservers::NotifyAll(name, instrs.PayloadStart(),
                             code.GetPrologueOffset(), instrs.Size(), optimized,
                             &comments_wrapper);
  }
#endif
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

bool Code::SlowFindRawCodeVisitor::FindObject(ObjectPtr raw_obj) const {
  return CodeLayout::ContainsPC(raw_obj, pc_);
}

CodePtr Code::LookupCodeInIsolate(Isolate* isolate, uword pc) {
  ASSERT((isolate == Isolate::Current()) || (isolate == Dart::vm_isolate()));
  if (isolate->heap() == NULL) {
    return Code::null();
  }
  HeapIterationScope heap_iteration_scope(Thread::Current());
  SlowFindRawCodeVisitor visitor(pc);
  ObjectPtr needle = isolate->heap()->FindOldObject(&visitor);
  if (needle != Code::null()) {
    return static_cast<CodePtr>(needle);
  }
  return Code::null();
}

CodePtr Code::LookupCode(uword pc) {
  return LookupCodeInIsolate(Isolate::Current(), pc);
}

CodePtr Code::LookupCodeInVmIsolate(uword pc) {
  return LookupCodeInIsolate(Dart::vm_isolate(), pc);
}

// Given a pc and a timestamp, lookup the code.
CodePtr Code::FindCode(uword pc, int64_t timestamp) {
  Code& code = Code::Handle(Code::LookupCode(pc));
  if (!code.IsNull() && (code.compile_timestamp() == timestamp) &&
      (code.PayloadStart() == pc)) {
    // Found code in isolate.
    return code.raw();
  }
  code = Code::LookupCodeInVmIsolate(pc);
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
  PcDescriptors::Iterator iter(descriptors, PcDescriptorsLayout::kAnyKind);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return iter.TokenPos();
    }
  }
  return TokenPosition::kNoSource;
}

uword Code::GetPcForDeoptId(intptr_t deopt_id,
                            PcDescriptorsLayout::Kind kind) const {
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
  PcDescriptors::Iterator iter(descriptors, PcDescriptorsLayout::kOsrEntry);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return iter.DeoptId();
    }
  }
  return DeoptId::kNone;
}

const char* Code::ToCString() const {
  return OS::SCreate(Thread::Current()->zone(), "Code(%s)",
                     QualifiedName(NameFormattingParams(
                         kScrubbedName, NameDisambiguation::kYes)));
}

const char* Code::Name() const {
  Zone* zone = Thread::Current()->zone();
  if (IsStubCode()) {
    // Regular stub.
    const char* name = StubCode::NameOfStub(EntryPoint());
    if (name == NULL) {
      return "[unknown stub]";  // Not yet recorded.
    }
    return OS::SCreate(zone, "[Stub] %s", name);
  }
  const auto& obj =
      Object::Handle(zone, WeakSerializationReference::UnwrapIfTarget(owner()));
  if (obj.IsClass()) {
    // Allocation stub.
    return OS::SCreate(zone, "[Stub] Allocate %s",
                       Class::Cast(obj).ScrubbedNameCString());
  } else if (obj.IsAbstractType()) {
    // Type test stub.
    return OS::SCreate(zone, "[Stub] Type Test %s",
                       AbstractType::Cast(obj).ToCString());
  } else {
    ASSERT(IsFunctionCode());
    // Dart function.
    const char* opt = is_optimized() ? "[Optimized]" : "[Unoptimized]";
    const char* function_name =
        obj.IsFunction()
            ? String::Handle(zone, Function::Cast(obj).UserVisibleName())
                  .ToCString()
            : WeakSerializationReference::Cast(obj).ToCString();
    return OS::SCreate(zone, "%s %s", opt, function_name);
  }
}

const char* Code::QualifiedName(const NameFormattingParams& params) const {
  Zone* zone = Thread::Current()->zone();
  const Object& obj =
      Object::Handle(zone, WeakSerializationReference::UnwrapIfTarget(owner()));
  if (obj.IsFunction()) {
    ZoneTextBuffer printer(zone);
    printer.AddString(is_optimized() ? "[Optimized] " : "[Unoptimized] ");
    Function::Cast(obj).PrintName(params, &printer);
    return printer.buffer();
  }
  return Name();
}

bool Code::IsStubCode() const {
  // We should _not_ unwrap any possible WSRs here, as the null value is never
  // wrapped by a WSR.
  return owner() == Object::null();
}

bool Code::IsAllocationStubCode() const {
  return OwnerClassId() == kClassCid;
}

bool Code::IsTypeTestStubCode() const {
  auto const cid = OwnerClassId();
  return cid == kAbstractTypeCid || cid == kTypeCid || cid == kTypeRefCid ||
         cid == kTypeParameterCid;
}

bool Code::IsFunctionCode() const {
  return OwnerClassId() == kFunctionCid;
}

void Code::DisableDartCode() const {
  DEBUG_ASSERT(IsMutatorOrAtSafepoint());
  ASSERT(IsFunctionCode());
  ASSERT(instructions() == active_instructions());
  const Code& new_code = StubCode::FixCallersTarget();
  SetActiveInstructions(Instructions::Handle(new_code.instructions()),
                        new_code.UncheckedEntryPointOffset());
}

void Code::DisableStubCode() const {
  ASSERT(Thread::Current()->IsMutatorThread());
  ASSERT(IsAllocationStubCode());
  ASSERT(instructions() == active_instructions());
  const Code& new_code = StubCode::FixAllocationStubTarget();
  SetActiveInstructions(Instructions::Handle(new_code.instructions()),
                        new_code.UncheckedEntryPointOffset());
}

void Code::InitializeCachedEntryPointsFrom(CodePtr code,
                                           InstructionsPtr instructions,
                                           uint32_t unchecked_offset) {
  NoSafepointScope _;
  const uword entry_point = Instructions::EntryPoint(instructions);
  const uword monomorphic_entry_point =
      Instructions::MonomorphicEntryPoint(instructions);
  code->ptr()->entry_point_ = entry_point;
  code->ptr()->monomorphic_entry_point_ = monomorphic_entry_point;
  code->ptr()->unchecked_entry_point_ = entry_point + unchecked_offset;
  code->ptr()->monomorphic_unchecked_entry_point_ =
      monomorphic_entry_point + unchecked_offset;
}

void Code::SetActiveInstructions(const Instructions& instructions,
                                 uint32_t unchecked_offset) const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  DEBUG_ASSERT(IsMutatorOrAtSafepoint() || !is_alive());
  // RawInstructions are never allocated in New space and hence a
  // store buffer update is not needed here.
  raw_ptr()->set_active_instructions(instructions.raw());
  Code::InitializeCachedEntryPointsFrom(raw(), instructions.raw(),
                                        unchecked_offset);
#endif
}

void Code::ResetActiveInstructions() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  SetActiveInstructions(Instructions::Handle(instructions()),
                        raw_ptr()->unchecked_offset_);
#endif
}

void Code::GetInlinedFunctionsAtInstruction(
    intptr_t pc_offset,
    GrowableArray<const Function*>* functions,
    GrowableArray<TokenPosition>* token_positions) const {
  const CodeSourceMap& map = CodeSourceMap::Handle(code_source_map());
  if (map.IsNull()) {
    ASSERT(!IsFunctionCode());
    return;  // VM stub, allocation stub, or type testing stub.
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

void Code::DumpSourcePositions(bool relative_addresses) const {
  const CodeSourceMap& map = CodeSourceMap::Handle(code_source_map());
  if (map.IsNull()) {
    // Stub code.
    return;
  }
  const Array& id_map = Array::Handle(inlined_id_to_function());
  const Function& root = Function::Handle(function());
  CodeSourceMapReader reader(map, id_map, root);
  reader.DumpSourcePositions(relative_addresses ? 0 : PayloadStart());
}

intptr_t Context::GetLevel() const {
  intptr_t level = 0;
  Context& parent_ctx = Context::Handle(parent());
  while (!parent_ctx.IsNull()) {
    level++;
    parent_ctx = parent_ctx.parent();
  }
  return level;
}

ContextPtr Context::New(intptr_t num_variables, Heap::Space space) {
  ASSERT(num_variables >= 0);
  ASSERT(Object::context_class() != Class::null());

  if (!IsValidLength(num_variables)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Context::New: invalid num_variables %" Pd "\n",
           num_variables);
  }
  Context& result = Context::Handle();
  {
    ObjectPtr raw = Object::Allocate(
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
  THR_Print("Context vars(%" Pd ") {\n", num_variables());
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

ContextScopePtr ContextScope::New(intptr_t num_variables, bool is_implicit) {
  ASSERT(Object::context_scope_class() != Class::null());
  if (num_variables < 0 || num_variables > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ContextScope::New: invalid num_variables %" Pd "\n",
           num_variables);
  }
  intptr_t size = ContextScope::InstanceSize(num_variables);
  ContextScope& result = ContextScope::Handle();
  {
    ObjectPtr raw = Object::Allocate(ContextScope::kClassId, size, Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_num_variables(num_variables);
    result.set_is_implicit(is_implicit);
  }
  return result.raw();
}

TokenPosition ContextScope::TokenIndexAt(intptr_t scope_index) const {
  return TokenPosition::Deserialize(
      Smi::Value(VariableDescAddr(scope_index)->token_pos));
}

void ContextScope::SetTokenIndexAt(intptr_t scope_index,
                                   TokenPosition token_pos) const {
  StoreSmi(&VariableDescAddr(scope_index)->token_pos,
           Smi::New(token_pos.Serialize()));
}

TokenPosition ContextScope::DeclarationTokenIndexAt(
    intptr_t scope_index) const {
  return TokenPosition::Deserialize(
      Smi::Value(VariableDescAddr(scope_index)->declaration_token_pos));
}

void ContextScope::SetDeclarationTokenIndexAt(
    intptr_t scope_index,
    TokenPosition declaration_token_pos) const {
  StoreSmi(&VariableDescAddr(scope_index)->declaration_token_pos,
           Smi::New(declaration_token_pos.Serialize()));
}

StringPtr ContextScope::NameAt(intptr_t scope_index) const {
  return VariableDescAddr(scope_index)->name;
}

void ContextScope::SetNameAt(intptr_t scope_index, const String& name) const {
  StorePointer(&(VariableDescAddr(scope_index)->name), name.raw());
}

void ContextScope::ClearFlagsAt(intptr_t scope_index) const {
  StoreSmi(&(VariableDescAddr(scope_index)->flags), 0);
}

bool ContextScope::GetFlagAt(intptr_t scope_index, intptr_t mask) const {
  return (Smi::Value(VariableDescAddr(scope_index)->flags) & mask) != 0;
}

void ContextScope::SetFlagAt(intptr_t scope_index,
                             intptr_t mask,
                             bool value) const {
  intptr_t flags = Smi::Value(VariableDescAddr(scope_index)->flags);
  StoreSmi(&(VariableDescAddr(scope_index)->flags),
           Smi::New(value ? flags | mask : flags & ~mask));
}

bool ContextScope::IsFinalAt(intptr_t scope_index) const {
  return GetFlagAt(scope_index, ContextScopeLayout::VariableDesc::kIsFinal);
}

void ContextScope::SetIsFinalAt(intptr_t scope_index, bool is_final) const {
  SetFlagAt(scope_index, ContextScopeLayout::VariableDesc::kIsFinal, is_final);
}

bool ContextScope::IsLateAt(intptr_t scope_index) const {
  return GetFlagAt(scope_index, ContextScopeLayout::VariableDesc::kIsLate);
}

void ContextScope::SetIsLateAt(intptr_t scope_index, bool is_late) const {
  SetFlagAt(scope_index, ContextScopeLayout::VariableDesc::kIsLate, is_late);
}

bool ContextScope::IsConstAt(intptr_t scope_index) const {
  return GetFlagAt(scope_index, ContextScopeLayout::VariableDesc::kIsConst);
}

void ContextScope::SetIsConstAt(intptr_t scope_index, bool is_const) const {
  SetFlagAt(scope_index, ContextScopeLayout::VariableDesc::kIsConst, is_const);
}

intptr_t ContextScope::LateInitOffsetAt(intptr_t scope_index) const {
  return Smi::Value(VariableDescAddr(scope_index)->late_init_offset);
}

void ContextScope::SetLateInitOffsetAt(intptr_t scope_index,
                                       intptr_t late_init_offset) const {
  StoreSmi(&(VariableDescAddr(scope_index)->late_init_offset),
           Smi::New(late_init_offset));
}

AbstractTypePtr ContextScope::TypeAt(intptr_t scope_index) const {
  ASSERT(!IsConstAt(scope_index));
  return VariableDescAddr(scope_index)->type;
}

void ContextScope::SetTypeAt(intptr_t scope_index,
                             const AbstractType& type) const {
  StorePointer(&(VariableDescAddr(scope_index)->type), type.raw());
}

InstancePtr ContextScope::ConstValueAt(intptr_t scope_index) const {
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

ArrayPtr MegamorphicCache::buckets() const {
  return raw_ptr()->buckets();
}

void MegamorphicCache::set_buckets(const Array& buckets) const {
  raw_ptr()->set_buckets(buckets.raw());
}

// Class IDs in the table are smi-tagged, so we use a smi-tagged mask
// and target class ID to avoid untagging (on each iteration of the
// test loop) in generated code.
intptr_t MegamorphicCache::mask() const {
  return Smi::Value(raw_ptr()->mask());
}

void MegamorphicCache::set_mask(intptr_t mask) const {
  raw_ptr()->set_mask(Smi::New(mask));
}

intptr_t MegamorphicCache::filled_entry_count() const {
  return raw_ptr()->filled_entry_count_;
}

void MegamorphicCache::set_filled_entry_count(intptr_t count) const {
  StoreNonPointer(&raw_ptr()->filled_entry_count_, count);
}

MegamorphicCachePtr MegamorphicCache::New() {
  MegamorphicCache& result = MegamorphicCache::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(MegamorphicCache::kClassId,
                         MegamorphicCache::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_filled_entry_count(0);
  return result.raw();
}

MegamorphicCachePtr MegamorphicCache::New(const String& target_name,
                                          const Array& arguments_descriptor) {
  MegamorphicCache& result = MegamorphicCache::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(MegamorphicCache::kClassId,
                         MegamorphicCache::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  const intptr_t capacity = kInitialCapacity;
  const Array& buckets =
      Array::Handle(Array::New(kEntryLength * capacity, Heap::kOld));
  const Object& handler = Object::Handle();
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

void MegamorphicCache::EnsureContains(const Smi& class_id,
                                      const Object& target) const {
  SafepointMutexLocker ml(IsolateGroup::Current()->type_feedback_mutex());

  if (LookupLocked(class_id) == Object::null()) {
    InsertLocked(class_id, target);
  }

#if defined(DEBUG)
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    if (target.IsFunction()) {
      const auto& function = Function::Cast(target);
      const auto& entry_point = Smi::Handle(
          Smi::FromAlignedAddress(Code::EntryPointOf(function.CurrentCode())));
      ASSERT(LookupLocked(class_id) == entry_point.raw());
    }
  } else {
    ASSERT(LookupLocked(class_id) == target.raw());
  }
#endif  // define(DEBUG)
}

ObjectPtr MegamorphicCache::Lookup(const Smi& class_id) const {
  SafepointMutexLocker ml(IsolateGroup::Current()->type_feedback_mutex());
  return LookupLocked(class_id);
}

ObjectPtr MegamorphicCache::LookupLocked(const Smi& class_id) const {
  auto thread = Thread::Current();
  auto isolate_group = thread->isolate_group();
  auto zone = thread->zone();
  ASSERT(thread->IsMutatorThread());
  ASSERT(isolate_group->type_feedback_mutex()->IsOwnedByCurrentThread());

  const auto& backing_array = Array::Handle(zone, buckets());
  intptr_t id_mask = mask();
  intptr_t index = (class_id.Value() * kSpreadFactor) & id_mask;
  intptr_t i = index;
  do {
    const classid_t current_cid =
        Smi::Value(Smi::RawCast(GetClassId(backing_array, i)));
    if (current_cid == class_id.Value()) {
      return GetTargetFunction(backing_array, i);
    } else if (current_cid == kIllegalCid) {
      return Object::null();
    }
    i = (i + 1) & id_mask;
  } while (i != index);
  UNREACHABLE();
}

void MegamorphicCache::InsertLocked(const Smi& class_id,
                                    const Object& target) const {
  auto isolate_group = IsolateGroup::Current();
  ASSERT(isolate_group->type_feedback_mutex()->IsOwnedByCurrentThread());

  // As opposed to ICData we are stopping mutator threads from other isolates
  // while modifying the megamorphic cache, since updates are not atomic.
  //
  // NOTE: In the future we might change the megamorphic cache insertions to
  // carefully use store-release barriers on the writer as well as
  // load-acquire barriers on the reader, ...
  isolate_group->RunWithStoppedMutators(
      [&]() {
        EnsureCapacityLocked();
        InsertEntryLocked(class_id, target);
      },
      /*use_force_growth=*/true);
}

void MegamorphicCache::EnsureCapacityLocked() const {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto isolate_group = thread->isolate_group();
  ASSERT(isolate_group->type_feedback_mutex()->IsOwnedByCurrentThread());

  intptr_t old_capacity = mask() + 1;
  double load_limit = kLoadFactor * static_cast<double>(old_capacity);
  if (static_cast<double>(filled_entry_count() + 1) > load_limit) {
    const Array& old_buckets = Array::Handle(zone, buckets());
    intptr_t new_capacity = old_capacity * 2;
    const Array& new_buckets =
        Array::Handle(zone, Array::New(kEntryLength * new_capacity));

    auto& target = Object::Handle(zone);
    for (intptr_t i = 0; i < new_capacity; ++i) {
      SetEntry(new_buckets, i, smi_illegal_cid(), target);
    }
    set_buckets(new_buckets);
    set_mask(new_capacity - 1);
    set_filled_entry_count(0);

    // Rehash the valid entries.
    Smi& class_id = Smi::Handle(zone);
    for (intptr_t i = 0; i < old_capacity; ++i) {
      class_id ^= GetClassId(old_buckets, i);
      if (class_id.Value() != kIllegalCid) {
        target = GetTargetFunction(old_buckets, i);
        InsertEntryLocked(class_id, target);
      }
    }
  }
}

void MegamorphicCache::InsertEntryLocked(const Smi& class_id,
                                         const Object& target) const {
  auto thread = Thread::Current();
  auto isolate_group = thread->isolate_group();
  ASSERT(isolate_group->type_feedback_mutex()->IsOwnedByCurrentThread());

  ASSERT(Thread::Current()->IsMutatorThread());
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

void MegamorphicCache::SwitchToBareInstructions() {
  NoSafepointScope no_safepoint_scope;

  intptr_t capacity = mask() + 1;
  for (intptr_t i = 0; i < capacity; ++i) {
    const intptr_t target_index = i * kEntryLength + kTargetFunctionIndex;
    ObjectPtr* slot = &Array::DataOf(buckets())[target_index];
    const intptr_t cid = (*slot)->GetClassIdMayBeSmi();
    if (cid == kFunctionCid) {
      CodePtr code = Function::CurrentCodeOf(Function::RawCast(*slot));
      *slot = Smi::FromAlignedAddress(Code::EntryPointOf(code));
    } else {
      ASSERT(cid == kSmiCid || cid == kNullCid);
    }
  }
}

void SubtypeTestCache::Init() {
  cached_array_ = Array::New(kTestEntryLength, Heap::kOld);
}

void SubtypeTestCache::Cleanup() {
  cached_array_ = NULL;
}

SubtypeTestCachePtr SubtypeTestCache::New() {
  ASSERT(Object::subtypetestcache_class() != Class::null());
  SubtypeTestCache& result = SubtypeTestCache::Handle();
  {
    // SubtypeTestCache objects are long living objects, allocate them in the
    // old generation.
    ObjectPtr raw =
        Object::Allocate(SubtypeTestCache::kClassId,
                         SubtypeTestCache::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_cache(Array::Handle(cached_array_));
  return result.raw();
}

ArrayPtr SubtypeTestCache::cache() const {
  // We rely on the fact that any loads from the array are dependent loads and
  // avoid the load-acquire barrier here.
  return raw_ptr()->cache<std::memory_order_relaxed>();
}

void SubtypeTestCache::set_cache(const Array& value) const {
  // We have to ensure that initializing stores to the array are available
  // when releasing the pointer to the array pointer.
  // => We have to use store-release here.
  raw_ptr()->set_cache<std::memory_order_release>(value.raw());
}

intptr_t SubtypeTestCache::NumberOfChecks() const {
  NoSafepointScope no_safepoint;
  // Do not count the sentinel;
  return (Smi::Value(cache()->ptr()->length()) / kTestEntryLength) - 1;
}

void SubtypeTestCache::AddCheck(
    const Object& instance_class_id_or_function,
    const AbstractType& destination_type,
    const TypeArguments& instance_type_arguments,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const TypeArguments& instance_parent_function_type_arguments,
    const TypeArguments& instance_delayed_type_arguments,
    const Bool& test_result) const {
  ASSERT(Thread::Current()
             ->isolate_group()
             ->subtype_test_cache_mutex()
             ->IsOwnedByCurrentThread());

  intptr_t old_num = NumberOfChecks();
  Array& data = Array::Handle(cache());
  intptr_t new_len = data.Length() + kTestEntryLength;
  data = Array::Grow(data, new_len);

  SubtypeTestCacheTable entries(data);
  auto entry = entries[old_num];
  ASSERT(entry.Get<kInstanceClassIdOrFunction>() == Object::null());
  entry.Set<kInstanceClassIdOrFunction>(instance_class_id_or_function);
  entry.Set<kDestinationType>(destination_type);
  entry.Set<kInstanceTypeArguments>(instance_type_arguments);
  entry.Set<kInstantiatorTypeArguments>(instantiator_type_arguments);
  entry.Set<kFunctionTypeArguments>(function_type_arguments);
  entry.Set<kInstanceParentFunctionTypeArguments>(
      instance_parent_function_type_arguments);
  entry.Set<kInstanceDelayedFunctionTypeArguments>(
      instance_delayed_type_arguments);
  entry.Set<kTestResult>(test_result);

  // We let any concurrently running mutator thread now see the new entry (the
  // `set_cache()` uses a store-release barrier).
  set_cache(data);
}

void SubtypeTestCache::GetCheck(
    intptr_t ix,
    Object* instance_class_id_or_function,
    AbstractType* destination_type,
    TypeArguments* instance_type_arguments,
    TypeArguments* instantiator_type_arguments,
    TypeArguments* function_type_arguments,
    TypeArguments* instance_parent_function_type_arguments,
    TypeArguments* instance_delayed_type_arguments,
    Bool* test_result) const {
  ASSERT(Thread::Current()
             ->isolate_group()
             ->subtype_test_cache_mutex()
             ->IsOwnedByCurrentThread());
  GetCurrentCheck(ix, instance_class_id_or_function, destination_type,
                  instance_type_arguments, instantiator_type_arguments,
                  function_type_arguments,
                  instance_parent_function_type_arguments,
                  instance_delayed_type_arguments, test_result);
}

void SubtypeTestCache::GetCurrentCheck(
    intptr_t ix,
    Object* instance_class_id_or_function,
    AbstractType* destination_type,
    TypeArguments* instance_type_arguments,
    TypeArguments* instantiator_type_arguments,
    TypeArguments* function_type_arguments,
    TypeArguments* instance_parent_function_type_arguments,
    TypeArguments* instance_delayed_type_arguments,
    Bool* test_result) const {
  Array& data = Array::Handle(cache());
  SubtypeTestCacheTable entries(data);
  auto entry = entries[ix];
  *instance_class_id_or_function = entry.Get<kInstanceClassIdOrFunction>();
  *destination_type = entry.Get<kDestinationType>();
  *instance_type_arguments = entry.Get<kInstanceTypeArguments>();
  *instantiator_type_arguments = entry.Get<kInstantiatorTypeArguments>();
  *function_type_arguments = entry.Get<kFunctionTypeArguments>();
  *instance_parent_function_type_arguments =
      entry.Get<kInstanceParentFunctionTypeArguments>();
  *instance_delayed_type_arguments =
      entry.Get<kInstanceDelayedFunctionTypeArguments>();
  *test_result ^= entry.Get<kTestResult>();
}

bool SubtypeTestCache::HasCheck(
    const Object& instance_class_id_or_function,
    const AbstractType& destination_type,
    const TypeArguments& instance_type_arguments,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const TypeArguments& instance_parent_function_type_arguments,
    const TypeArguments& instance_delayed_type_arguments,
    intptr_t* index,
    Bool* result) const {
  ASSERT(Thread::Current()
             ->isolate_group()
             ->subtype_test_cache_mutex()
             ->IsOwnedByCurrentThread());
  const intptr_t last_index = NumberOfChecks();
  const auto& data = Array::Handle(cache());

  SubtypeTestCacheTable entries(data);
  for (intptr_t i = 0; i < last_index; i++) {
    const auto entry = entries[i];
    if (entry.Get<kInstanceClassIdOrFunction>() ==
            instance_class_id_or_function.raw() &&
        entry.Get<kDestinationType>() == destination_type.raw() &&
        entry.Get<kInstanceTypeArguments>() == instance_type_arguments.raw() &&
        entry.Get<kInstantiatorTypeArguments>() ==
            instantiator_type_arguments.raw() &&
        entry.Get<kFunctionTypeArguments>() == function_type_arguments.raw() &&
        entry.Get<kInstanceParentFunctionTypeArguments>() ==
            instance_parent_function_type_arguments.raw() &&
        entry.Get<kInstanceDelayedFunctionTypeArguments>() ==
            instance_delayed_type_arguments.raw()) {
      if (index != nullptr) {
        *index = i;
      }
      if (result != nullptr) {
        *result ^= entry.Get<kTestResult>();
      }
      return true;
    }
  }
  return false;
}

void SubtypeTestCache::WriteEntryToBuffer(Zone* zone,
                                          BaseTextBuffer* buffer,
                                          intptr_t index,
                                          const char* line_prefix) const {
  ASSERT(Thread::Current()
             ->isolate_group()
             ->subtype_test_cache_mutex()
             ->IsOwnedByCurrentThread());
  WriteCurrentEntryToBuffer(zone, buffer, index, line_prefix);
}

void SubtypeTestCache::WriteCurrentEntryToBuffer(
    Zone* zone,
    BaseTextBuffer* buffer,
    intptr_t index,
    const char* line_prefix) const {
  const char* separator =
      line_prefix == nullptr ? ", " : OS::SCreate(zone, "\n%s", line_prefix);
  auto& instance_class_id_or_function = Object::Handle(zone);
  auto& destination_type = AbstractType::Handle(zone);
  auto& instance_type_arguments = TypeArguments::Handle(zone);
  auto& instantiator_type_arguments = TypeArguments::Handle(zone);
  auto& function_type_arguments = TypeArguments::Handle(zone);
  auto& instance_parent_function_type_arguments = TypeArguments::Handle(zone);
  auto& instance_delayed_type_arguments = TypeArguments::Handle(zone);
  auto& result = Bool::Handle(zone);
  GetCurrentCheck(index, &instance_class_id_or_function, &destination_type,
                  &instance_type_arguments, &instantiator_type_arguments,
                  &function_type_arguments,
                  &instance_parent_function_type_arguments,
                  &instance_delayed_type_arguments, &result);
  ASSERT(!result.IsNull());
  buffer->Printf(
      "[ %#" Px ", %#" Px ", %#" Px ", %#" Px ", %#" Px ", %#" Px ", %#" Px
      ", %#" Px " ]",
      static_cast<uword>(instance_class_id_or_function.raw()),
      static_cast<uword>(destination_type.raw()),
      static_cast<uword>(instance_type_arguments.raw()),
      static_cast<uword>(instantiator_type_arguments.raw()),
      static_cast<uword>(function_type_arguments.raw()),
      static_cast<uword>(instance_parent_function_type_arguments.raw()),
      static_cast<uword>(instance_delayed_type_arguments.raw()),
      static_cast<uword>(result.raw()));
  if (instance_class_id_or_function.IsSmi()) {
    buffer->Printf("%sclass id: %" Pd "", separator,
                   Smi::Cast(instance_class_id_or_function).Value());
  } else {
    ASSERT(instance_class_id_or_function.IsFunction());
    buffer->Printf("%sfunction: %s", separator,
                   Function::Cast(instance_class_id_or_function)
                       .ToFullyQualifiedCString());
  }
  if (!destination_type.IsNull()) {
    buffer->Printf("%sdestination type: %s", separator,
                   destination_type.ToCString());
    if (!destination_type.IsInstantiated()) {
      AbstractType& test_type = AbstractType::Handle(
          zone, destination_type.InstantiateFrom(instantiator_type_arguments,
                                                 function_type_arguments,
                                                 kAllFree, Heap::kNew));
      const auto& type_class = Class::Handle(zone, test_type.type_class());
      buffer->Printf("%sinstantiated type: %s", separator,
                     test_type.ToCString());
      buffer->Printf("%sinstantiated type class id: %" Pd "", separator,
                     type_class.id());
    }
  }
  if (!instance_type_arguments.IsNull()) {
    if (instance_class_id_or_function.IsSmi()) {
      buffer->Printf("%sinstance type arguments: %s", separator,
                     instance_type_arguments.ToCString());
    } else {
      ASSERT(instance_class_id_or_function.IsFunction());
      buffer->Printf("%sclosure instantiator function type arguments: %s",
                     separator, instance_type_arguments.ToCString());
    }
  }
  if (!instantiator_type_arguments.IsNull()) {
    buffer->Printf("%sinstantiator type arguments: %s", separator,
                   instantiator_type_arguments.ToCString());
  }
  if (!function_type_arguments.IsNull()) {
    buffer->Printf("%sfunction type arguments: %s", separator,
                   function_type_arguments.ToCString());
  }
  if (!instance_parent_function_type_arguments.IsNull()) {
    ASSERT(instance_class_id_or_function.IsFunction());
    buffer->Printf("%sclosure parent function type arguments: %s", separator,
                   instance_parent_function_type_arguments.ToCString());
  }
  if (!instance_delayed_type_arguments.IsNull()) {
    ASSERT(instance_class_id_or_function.IsFunction());
    buffer->Printf("%sclosure delayed function type arguments: %s", separator,
                   instance_delayed_type_arguments.ToCString());
  }
  buffer->Printf("%sresult: %s", separator, result.ToCString());
}

void SubtypeTestCache::Reset() const {
  set_cache(Array::Handle(cached_array_));
}

const char* SubtypeTestCache::ToCString() const {
  auto const zone = Thread::Current()->zone();
  ZoneTextBuffer buffer(zone);
  const intptr_t num_checks = NumberOfChecks();
  buffer.AddString("SubtypeTestCache(");
  for (intptr_t i = 0; i < num_checks; i++) {
    if (i != 0) {
      buffer.AddString(",");
    }
    buffer.AddString("{ entry: ");
    WriteCurrentEntryToBuffer(zone, &buffer, i);
    buffer.AddString(" }");
  }
  buffer.AddString(")");
  return buffer.buffer();
}

LoadingUnitPtr LoadingUnit::New() {
  ASSERT(Object::loadingunit_class() != Class::null());
  LoadingUnit& result = LoadingUnit::Handle();
  {
    // LoadingUnit objects are long living objects, allocate them in the
    // old generation.
    ObjectPtr raw = Object::Allocate(LoadingUnit::kClassId,
                                     LoadingUnit::InstanceSize(), Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_id(kIllegalId);
  result.set_loaded(false);
  result.set_load_outstanding(false);
  return result.raw();
}

LoadingUnitPtr LoadingUnit::parent() const {
  return raw_ptr()->parent();
}
void LoadingUnit::set_parent(const LoadingUnit& value) const {
  raw_ptr()->set_parent(value.raw());
}

ArrayPtr LoadingUnit::base_objects() const {
  return raw_ptr()->base_objects();
}
void LoadingUnit::set_base_objects(const Array& value) const {
  raw_ptr()->set_base_objects(value.raw());
}

const char* LoadingUnit::ToCString() const {
  return "LoadingUnit";
}

ObjectPtr LoadingUnit::IssueLoad() const {
  ASSERT(!loaded());
  ASSERT(!load_outstanding());
  set_load_outstanding(true);
  return Isolate::Current()->CallDeferredLoadHandler(id());
}

ObjectPtr LoadingUnit::CompleteLoad(const String& error_message,
                                    bool transient_error) const {
  ASSERT(!loaded());
  ASSERT(load_outstanding());
  set_loaded(error_message.IsNull());
  set_load_outstanding(false);

  const Library& lib = Library::Handle(Library::CoreLibrary());
  const String& sel = String::Handle(String::New("_completeLoads"));
  const Function& func = Function::Handle(lib.LookupFunctionAllowPrivate(sel));
  ASSERT(!func.IsNull());
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, Smi::Handle(Smi::New(id())));
  args.SetAt(1, error_message);
  args.SetAt(2, Bool::Get(transient_error));
  return DartEntry::InvokeFunction(func, args);
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

ApiErrorPtr ApiError::New() {
  ASSERT(Object::api_error_class() != Class::null());
  ObjectPtr raw = Object::Allocate(ApiError::kClassId, ApiError::InstanceSize(),
                                   Heap::kOld);
  return static_cast<ApiErrorPtr>(raw);
}

ApiErrorPtr ApiError::New(const String& message, Heap::Space space) {
#ifndef PRODUCT
  if (FLAG_print_stacktrace_at_api_error) {
    OS::PrintErr("ApiError: %s\n", message.ToCString());
    Profiler::DumpStackTrace(false /* for_crash */);
  }
#endif  // !PRODUCT

  ASSERT(Object::api_error_class() != Class::null());
  ApiError& result = ApiError::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(ApiError::kClassId, ApiError::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_message(message);
  return result.raw();
}

void ApiError::set_message(const String& message) const {
  raw_ptr()->set_message(message.raw());
}

const char* ApiError::ToErrorCString() const {
  const String& msg_str = String::Handle(message());
  return msg_str.ToCString();
}

const char* ApiError::ToCString() const {
  return "ApiError";
}

LanguageErrorPtr LanguageError::New() {
  ASSERT(Object::language_error_class() != Class::null());
  ObjectPtr raw = Object::Allocate(LanguageError::kClassId,
                                   LanguageError::InstanceSize(), Heap::kOld);
  return static_cast<LanguageErrorPtr>(raw);
}

LanguageErrorPtr LanguageError::NewFormattedV(const Error& prev_error,
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
    ObjectPtr raw = Object::Allocate(LanguageError::kClassId,
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

LanguageErrorPtr LanguageError::NewFormatted(const Error& prev_error,
                                             const Script& script,
                                             TokenPosition token_pos,
                                             bool report_after_token,
                                             Report::Kind kind,
                                             Heap::Space space,
                                             const char* format,
                                             ...) {
  va_list args;
  va_start(args, format);
  LanguageErrorPtr result = LanguageError::NewFormattedV(
      prev_error, script, token_pos, report_after_token, kind, space, format,
      args);
  NoSafepointScope no_safepoint;
  va_end(args);
  return result;
}

LanguageErrorPtr LanguageError::New(const String& formatted_message,
                                    Report::Kind kind,
                                    Heap::Space space) {
  ASSERT(Object::language_error_class() != Class::null());
  LanguageError& result = LanguageError::Handle();
  {
    ObjectPtr raw = Object::Allocate(LanguageError::kClassId,
                                     LanguageError::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_formatted_message(formatted_message);
  result.set_kind(kind);
  return result.raw();
}

void LanguageError::set_previous_error(const Error& value) const {
  raw_ptr()->set_previous_error(value.raw());
}

void LanguageError::set_script(const Script& value) const {
  raw_ptr()->set_script(value.raw());
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
  raw_ptr()->set_message(value.raw());
}

void LanguageError::set_formatted_message(const String& value) const {
  raw_ptr()->set_formatted_message(value.raw());
}

StringPtr LanguageError::FormatMessage() const {
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

UnhandledExceptionPtr UnhandledException::New(const Instance& exception,
                                              const Instance& stacktrace,
                                              Heap::Space space) {
  ASSERT(Object::unhandled_exception_class() != Class::null());
  UnhandledException& result = UnhandledException::Handle();
  {
    ObjectPtr raw = Object::Allocate(UnhandledException::kClassId,
                                     UnhandledException::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_exception(exception);
  result.set_stacktrace(stacktrace);
  return result.raw();
}

UnhandledExceptionPtr UnhandledException::New(Heap::Space space) {
  ASSERT(Object::unhandled_exception_class() != Class::null());
  UnhandledException& result = UnhandledException::Handle();
  {
    ObjectPtr raw = Object::Allocate(UnhandledException::kClassId,
                                     UnhandledException::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_exception(Object::null_instance());
  result.set_stacktrace(StackTrace::Handle());
  return result.raw();
}

void UnhandledException::set_exception(const Instance& exception) const {
  raw_ptr()->set_exception(exception.raw());
}

void UnhandledException::set_stacktrace(const Instance& stacktrace) const {
  raw_ptr()->set_stacktrace(stacktrace.raw());
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

UnwindErrorPtr UnwindError::New(const String& message, Heap::Space space) {
  ASSERT(Object::unwind_error_class() != Class::null());
  UnwindError& result = UnwindError::Handle();
  {
    ObjectPtr raw = Object::Allocate(UnwindError::kClassId,
                                     UnwindError::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_message(message);
  result.set_is_user_initiated(false);
  return result.raw();
}

void UnwindError::set_message(const String& message) const {
  raw_ptr()->set_message(message.raw());
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

ObjectPtr Instance::InvokeGetter(const String& getter_name,
                                 bool respect_reflectable,
                                 bool check_is_entrypoint) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  Class& klass = Class::Handle(zone, clazz());
  CHECK_ERROR(klass.EnsureIsFinalized(thread));
  const auto& inst_type_args =
      klass.NumTypeArguments() > 0
          ? TypeArguments::Handle(zone, GetTypeArguments())
          : Object::null_type_arguments();

  const String& internal_getter_name =
      String::Handle(zone, Field::GetterName(getter_name));
  Function& function = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, klass, internal_getter_name));

  if (!function.IsNull() && check_is_entrypoint) {
    // The getter must correspond to either an entry-point field or a getter
    // method explicitly marked.
    Field& field = Field::Handle(zone);
    if (function.kind() == FunctionLayout::kImplicitGetter) {
      field = function.accessor_field();
    }
    if (!field.IsNull()) {
      CHECK_ERROR(field.VerifyEntryPoint(EntryPointPragma::kGetterOnly));
    } else {
      CHECK_ERROR(function.VerifyCallEntryPoint());
    }
  }

  // Check for method extraction when method extractors are not created.
  if (function.IsNull() && !FLAG_lazy_dispatchers) {
    function = Resolver::ResolveDynamicAnyArgs(zone, klass, getter_name);

    if (!function.IsNull() && check_is_entrypoint) {
      CHECK_ERROR(function.VerifyClosurizedEntryPoint());
    }

    if (!function.IsNull() && function.SafeToClosurize()) {
      const Function& closure_function =
          Function::Handle(zone, function.ImplicitClosureFunction());
      return closure_function.ImplicitInstanceClosure(*this);
    }
  }

  const int kTypeArgsLen = 0;
  const int kNumArgs = 1;
  const Array& args = Array::Handle(zone, Array::New(kNumArgs));
  args.SetAt(0, *this);
  const Array& args_descriptor = Array::Handle(
      zone,
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length(), Heap::kNew));

  return InvokeInstanceFunction(thread, *this, function, internal_getter_name,
                                args, args_descriptor, respect_reflectable,
                                inst_type_args);
}

ObjectPtr Instance::InvokeSetter(const String& setter_name,
                                 const Instance& value,
                                 bool respect_reflectable,
                                 bool check_is_entrypoint) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  const Class& klass = Class::Handle(zone, clazz());
  CHECK_ERROR(klass.EnsureIsFinalized(thread));
  const auto& inst_type_args =
      klass.NumTypeArguments() > 0
          ? TypeArguments::Handle(zone, GetTypeArguments())
          : Object::null_type_arguments();

  const String& internal_setter_name =
      String::Handle(zone, Field::SetterName(setter_name));
  const Function& setter = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, klass, internal_setter_name));

  if (check_is_entrypoint) {
    // The setter must correspond to either an entry-point field or a setter
    // method explicitly marked.
    Field& field = Field::Handle(zone);
    if (setter.kind() == FunctionLayout::kImplicitSetter) {
      field = setter.accessor_field();
    }
    if (!field.IsNull()) {
      CHECK_ERROR(field.VerifyEntryPoint(EntryPointPragma::kSetterOnly));
    } else if (!setter.IsNull()) {
      CHECK_ERROR(setter.VerifyCallEntryPoint());
    }
  }

  const int kTypeArgsLen = 0;
  const int kNumArgs = 2;
  const Array& args = Array::Handle(zone, Array::New(kNumArgs));
  args.SetAt(0, *this);
  args.SetAt(1, value);
  const Array& args_descriptor = Array::Handle(
      zone,
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length(), Heap::kNew));

  return InvokeInstanceFunction(thread, *this, setter, internal_setter_name,
                                args, args_descriptor, respect_reflectable,
                                inst_type_args);
}

ObjectPtr Instance::Invoke(const String& function_name,
                           const Array& args,
                           const Array& arg_names,
                           bool respect_reflectable,
                           bool check_is_entrypoint) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Class& klass = Class::Handle(zone, clazz());
  CHECK_ERROR(klass.EnsureIsFinalized(thread));

  Function& function = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, klass, function_name));

  if (!function.IsNull() && check_is_entrypoint) {
    CHECK_ERROR(function.VerifyCallEntryPoint());
  }

  // We don't pass any explicit type arguments, which will be understood as
  // using dynamic for any function type arguments by lower layers.
  const int kTypeArgsLen = 0;
  const Array& args_descriptor = Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length(),
                                          arg_names, Heap::kNew));

  const auto& inst_type_args =
      klass.NumTypeArguments() > 0
          ? TypeArguments::Handle(zone, GetTypeArguments())
          : Object::null_type_arguments();

  if (function.IsNull()) {
    // Didn't find a method: try to find a getter and invoke call on its result.
    const String& getter_name =
        String::Handle(zone, Field::GetterName(function_name));
    function = Resolver::ResolveDynamicAnyArgs(zone, klass, getter_name);
    if (!function.IsNull()) {
      if (check_is_entrypoint) {
        CHECK_ERROR(EntryPointFieldInvocationError(function_name));
      }
      ASSERT(function.kind() != FunctionLayout::kMethodExtractor);
      // Invoke the getter.
      const int kNumArgs = 1;
      const Array& getter_args = Array::Handle(zone, Array::New(kNumArgs));
      getter_args.SetAt(0, *this);
      const Array& getter_args_descriptor = Array::Handle(
          zone, ArgumentsDescriptor::NewBoxed(
                    kTypeArgsLen, getter_args.Length(), Heap::kNew));
      const Object& getter_result = Object::Handle(
          zone, InvokeInstanceFunction(thread, *this, function, getter_name,
                                       getter_args, getter_args_descriptor,
                                       respect_reflectable, inst_type_args));
      if (getter_result.IsError()) {
        return getter_result.raw();
      }
      // Replace the closure as the receiver in the arguments list.
      args.SetAt(0, getter_result);
      return DartEntry::InvokeClosure(thread, args, args_descriptor);
    }
  }

  // Found an ordinary method.
  return InvokeInstanceFunction(thread, *this, function, function_name, args,
                                args_descriptor, respect_reflectable,
                                inst_type_args);
}

ObjectPtr Instance::EvaluateCompiledExpression(
    const Class& method_cls,
    const ExternalTypedData& kernel_buffer,
    const Array& type_definitions,
    const Array& arguments,
    const TypeArguments& type_arguments) const {
  const Array& arguments_with_receiver =
      Array::Handle(Array::New(1 + arguments.Length()));
  PassiveObject& param = PassiveObject::Handle();
  arguments_with_receiver.SetAt(0, *this);
  for (intptr_t i = 0; i < arguments.Length(); i++) {
    param = arguments.At(i);
    arguments_with_receiver.SetAt(i + 1, param);
  }

  return EvaluateCompiledExpressionHelper(
      kernel_buffer, type_definitions,
      String::Handle(Library::Handle(method_cls.library()).url()),
      String::Handle(method_cls.UserVisibleName()), arguments_with_receiver,
      type_arguments);
}

ObjectPtr Instance::HashCode() const {
  // TODO(koda): Optimize for all builtin classes and all classes
  // that do not override hashCode.
  return DartLibraryCalls::HashCode(*this);
}

ObjectPtr Instance::IdentityHashCode() const {
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
      if ((*reinterpret_cast<ObjectPtr*>(this_addr + offset)) !=
          (*reinterpret_cast<ObjectPtr*>(other_addr + offset))) {
        return false;
      }
    }
  }
  return true;
}

uint32_t Instance::CanonicalizeHash() const {
  if (GetClassId() == kNullCid) {
    return 2011;  // Matches null_patch.dart.
  }
  Thread* thread = Thread::Current();
  uint32_t hash = thread->heap()->GetCanonicalHash(raw());
  if (hash != 0) {
    return hash;
  }
  const Class& cls = Class::Handle(clazz());
  NoSafepointScope no_safepoint(thread);
  const intptr_t instance_size = SizeFromClass();
  ASSERT(instance_size != 0);
  hash = instance_size / kWordSize;
  uword this_addr = reinterpret_cast<uword>(this->raw_ptr());
  Instance& member = Instance::Handle();

  const auto unboxed_fields_bitmap =
      thread->isolate()->group()->shared_class_table()->GetUnboxedFieldsMapAt(
          GetClassId());

  for (intptr_t offset = Instance::NextFieldOffset();
       offset < cls.host_next_field_offset(); offset += kWordSize) {
    if (unboxed_fields_bitmap.Get(offset / kWordSize)) {
      if (kWordSize == 8) {
        hash = CombineHashes(hash,
                             *reinterpret_cast<uint32_t*>(this_addr + offset));
        hash = CombineHashes(
            hash, *reinterpret_cast<uint32_t*>(this_addr + offset + 4));
      } else {
        hash = CombineHashes(hash,
                             *reinterpret_cast<uint32_t*>(this_addr + offset));
      }
    } else {
      member ^= *reinterpret_cast<ObjectPtr*>(this_addr + offset);
      hash = CombineHashes(hash, member.CanonicalizeHash());
    }
  }
  hash = FinalizeHash(hash, String::kHashBits);
  thread->heap()->SetCanonicalHash(raw(), hash);
  return hash;
}

#if defined(DEBUG)
class CheckForPointers : public ObjectPointerVisitor {
 public:
  explicit CheckForPointers(IsolateGroup* isolate_group)
      : ObjectPointerVisitor(isolate_group), has_pointers_(false) {}

  bool has_pointers() const { return has_pointers_; }

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) {
    if (first != last) {
      has_pointers_ = true;
    }
  }

 private:
  bool has_pointers_;

  DISALLOW_COPY_AND_ASSIGN(CheckForPointers);
};
#endif  // DEBUG

void Instance::CanonicalizeFieldsLocked(Thread* thread) const {
  const intptr_t class_id = GetClassId();
  if (class_id >= kNumPredefinedCids) {
    // Iterate over all fields, canonicalize numbers and strings, expect all
    // other instances to be canonical otherwise report error (return false).
    Zone* zone = thread->zone();
    Instance& obj = Instance::Handle(zone);
    const intptr_t instance_size = SizeFromClass();
    ASSERT(instance_size != 0);
    const auto unboxed_fields_bitmap =
        thread->isolate()->group()->shared_class_table()->GetUnboxedFieldsMapAt(
            class_id);
    for (intptr_t offset = Instance::NextFieldOffset(); offset < instance_size;
         offset += kWordSize) {
      if (unboxed_fields_bitmap.Get(offset / kWordSize)) {
        continue;
      }
      obj ^= *this->FieldAddrAtOffset(offset);
      obj = obj.CanonicalizeLocked(thread);
      this->SetFieldAtOffset(offset, obj);
    }
  } else {
#if defined(DEBUG)
    // Make sure that we are not missing any fields.
    CheckForPointers has_pointers(Isolate::Current()->group());
    this->raw()->ptr()->VisitPointers(&has_pointers);
    ASSERT(!has_pointers.has_pointers());
#endif  // DEBUG
  }
}

InstancePtr Instance::CopyShallowToOldSpace(Thread* thread) const {
  return Instance::RawCast(Object::Clone(*this, Heap::kOld));
}

InstancePtr Instance::Canonicalize(Thread* thread) const {
  SafepointMutexLocker ml(
      thread->isolate_group()->constant_canonicalization_mutex());
  return CanonicalizeLocked(thread);
}

InstancePtr Instance::CanonicalizeLocked(Thread* thread) const {
  if (this->IsCanonical()) {
    return this->raw();
  }
  ASSERT(!IsNull());
  CanonicalizeFieldsLocked(thread);
  Zone* zone = thread->zone();
  const Class& cls = Class::Handle(zone, this->clazz());
  Instance& result =
      Instance::Handle(zone, cls.LookupCanonicalInstance(zone, *this));
  if (!result.IsNull()) {
    return result.raw();
  }
  if (IsNew()) {
    ASSERT((thread->isolate() == Dart::vm_isolate()) || !InVMIsolateHeap());
    // Create a canonical object in old space.
    result ^= Object::Clone(*this, Heap::kOld);
  } else {
    result = this->raw();
  }
  ASSERT(result.IsOld());
  result.SetCanonical();
  return cls.InsertCanonicalConstant(zone, result);
}

#if defined(DEBUG)
bool Instance::CheckIsCanonical(Thread* thread) const {
  Zone* zone = thread->zone();
  Instance& result = Instance::Handle(zone);
  const Class& cls = Class::Handle(zone, this->clazz());
  SafepointMutexLocker ml(
      thread->isolate_group()->constant_canonicalization_mutex());
  result ^= cls.LookupCanonicalInstance(zone, *this);
  return (result.raw() == this->raw());
}
#endif  // DEBUG

ObjectPtr Instance::GetField(const Field& field) const {
  if (FLAG_precompiled_mode && field.is_unboxing_candidate()) {
    switch (field.guarded_cid()) {
      case kDoubleCid:
        return Double::New(*reinterpret_cast<double_t*>(FieldAddr(field)));
      case kFloat32x4Cid:
        return Float32x4::New(
            *reinterpret_cast<simd128_value_t*>(FieldAddr(field)));
      case kFloat64x2Cid:
        return Float64x2::New(
            *reinterpret_cast<simd128_value_t*>(FieldAddr(field)));
      default:
        if (field.is_non_nullable_integer()) {
          return Integer::New(*reinterpret_cast<int64_t*>(FieldAddr(field)));
        } else {
          UNREACHABLE();
          return nullptr;
        }
    }
  } else {
    return *FieldAddr(field);
  }
}

void Instance::SetField(const Field& field, const Object& value) const {
  if (FLAG_precompiled_mode && field.is_unboxing_candidate()) {
    switch (field.guarded_cid()) {
      case kDoubleCid:
        StoreNonPointer(reinterpret_cast<double_t*>(FieldAddr(field)),
                        Double::Cast(value).value());
        break;
      case kFloat32x4Cid:
        StoreNonPointer(reinterpret_cast<simd128_value_t*>(FieldAddr(field)),
                        Float32x4::Cast(value).value());
        break;
      case kFloat64x2Cid:
        StoreNonPointer(reinterpret_cast<simd128_value_t*>(FieldAddr(field)),
                        Float64x2::Cast(value).value());
        break;
      default:
        if (field.is_non_nullable_integer()) {
          StoreNonPointer(reinterpret_cast<int64_t*>(FieldAddr(field)),
                          Integer::Cast(value).AsInt64Value());
        } else {
          UNREACHABLE();
        }
        break;
    }
  } else {
    field.RecordStore(value);
    const Object* stored_value = field.CloneForUnboxed(value);
    StorePointer(FieldAddr(field), stored_value->raw());
  }
}

AbstractTypePtr Instance::GetType(Heap::Space space) const {
  if (IsNull()) {
    return Type::NullType();
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Class& cls = Class::Handle(zone, clazz());
  if (!cls.is_finalized()) {
    // Various predefined classes can be instantiated by the VM or
    // Dart_NewString/Integer/TypedData/... before the class is finalized.
    ASSERT(cls.is_prefinalized());
    cls.EnsureDeclarationLoaded();
  }
  if (cls.IsClosureClass()) {
    Function& signature = Function::Handle(
        zone, Closure::Cast(*this).GetInstantiatedSignature(zone));
    Type& type = Type::Handle(zone, signature.SignatureType());
    if (!type.IsFinalized()) {
      type.SetIsFinalized();
    }
    type ^= type.Canonicalize(thread, nullptr);
    return type.raw();
  }
  Type& type = Type::Handle(zone);
  if (!cls.IsGeneric()) {
    type = cls.DeclarationType();
  }
  if (type.IsNull()) {
    TypeArguments& type_arguments = TypeArguments::Handle(zone);
    if (cls.NumTypeArguments() > 0) {
      type_arguments = GetTypeArguments();
    }
    type = Type::New(cls, type_arguments, TokenPosition::kNoSource,
                     Nullability::kNonNullable, space);
    type.SetIsFinalized();
    type ^= type.Canonicalize(thread, nullptr);
  }
  return type.raw();
}

TypeArgumentsPtr Instance::GetTypeArguments() const {
  ASSERT(!IsType());
  const Class& cls = Class::Handle(clazz());
  intptr_t field_offset = cls.host_type_arguments_field_offset();
  ASSERT(field_offset != Class::kNoTypeArguments);
  TypeArguments& type_arguments = TypeArguments::Handle();
  type_arguments ^= *FieldAddrAtOffset(field_offset);
  return type_arguments.raw();
}

void Instance::SetTypeArguments(const TypeArguments& value) const {
  ASSERT(!IsType());
  ASSERT(value.IsNull() || value.IsCanonical());
  const Class& cls = Class::Handle(clazz());
  intptr_t field_offset = cls.host_type_arguments_field_offset();
  ASSERT(field_offset != Class::kNoTypeArguments);
  SetFieldAtOffset(field_offset, value);
}

/*
Specification of instance checks (e is T) and casts (e as T), where e evaluates
to a value v and v has runtime type S:

Instance checks (e is T) in weak checking mode in a legacy or opted-in library:
  If v == null and T is a legacy type
    return LEGACY_SUBTYPE(T, Null) || LEGACY_SUBTYPE(Object, T)
  If v == null and T is not a legacy type, return NNBD_SUBTYPE(Null, T)
  Otherwise return LEGACY_SUBTYPE(S, T)

Instance checks (e is T) in strong checking mode in a legacy or opted-in lib:
  If v == null and T is a legacy type
    return LEGACY_SUBTYPE(T, Null) || LEGACY_SUBTYPE(Object, T)
  Otherwise return NNBD_SUBTYPE(S, T)

Casts (e as T) in weak checking mode in a legacy or opted-in library:
  If LEGACY_SUBTYPE(S, T) then e as T evaluates to v.
  Otherwise a CastError is thrown.

Casts (e as T) in strong checking mode in a legacy or opted-in library:
  If NNBD_SUBTYPE(S, T) then e as T evaluates to v.
  Otherwise a CastError is thrown.
*/

bool Instance::IsInstanceOf(
    const AbstractType& other,
    const TypeArguments& other_instantiator_type_arguments,
    const TypeArguments& other_function_type_arguments) const {
  ASSERT(!other.IsDynamicType());
  if (IsNull()) {
    return Instance::NullIsInstanceOf(other, other_instantiator_type_arguments,
                                      other_function_type_arguments);
  }
  // In strong mode, compute NNBD_SUBTYPE(runtimeType, other).
  // In weak mode, compute LEGACY_SUBTYPE(runtimeType, other).
  return RuntimeTypeIsSubtypeOf(other, other_instantiator_type_arguments,
                                other_function_type_arguments);
}

bool Instance::IsAssignableTo(
    const AbstractType& other,
    const TypeArguments& other_instantiator_type_arguments,
    const TypeArguments& other_function_type_arguments) const {
  ASSERT(!other.IsDynamicType());
  // In weak mode type casts, whether in legacy or opted-in libraries, the null
  // instance is detected and handled in inlined code and therefore cannot be
  // encountered here as a Dart null receiver.
  ASSERT(Isolate::Current()->use_strict_null_safety_checks() || !IsNull());
  // In strong mode, compute NNBD_SUBTYPE(runtimeType, other).
  // In weak mode, compute LEGACY_SUBTYPE(runtimeType, other).
  return RuntimeTypeIsSubtypeOf(other, other_instantiator_type_arguments,
                                other_function_type_arguments);
}

// If 'other' type (once instantiated) is a legacy type:
//   return LEGACY_SUBTYPE(other, Null) || LEGACY_SUBTYPE(Object, other).
// Otherwise return NNBD_SUBTYPE(Null, T).
// Ignore value of strong flag value.
bool Instance::NullIsInstanceOf(
    const AbstractType& other,
    const TypeArguments& other_instantiator_type_arguments,
    const TypeArguments& other_function_type_arguments) {
  ASSERT(other.IsFinalized());
  ASSERT(!other.IsTypeRef());  // Must be dereferenced at compile time.
  if (other.IsNullable()) {
    // This case includes top types (void, dynamic, Object?).
    // The uninstantiated nullable type will remain nullable after
    // instantiation.
    return true;
  }
  if (other.IsFutureOrType()) {
    const auto& type = AbstractType::Handle(other.UnwrapFutureOr());
    return NullIsInstanceOf(type, other_instantiator_type_arguments,
                            other_function_type_arguments);
  }
  // No need to instantiate type, unless it is a type parameter.
  // Note that a typeref cannot refer to a type parameter.
  if (other.IsTypeParameter()) {
    auto& type = AbstractType::Handle(other.InstantiateFrom(
        other_instantiator_type_arguments, other_function_type_arguments,
        kAllFree, Heap::kOld));
    if (type.IsTypeRef()) {
      type = TypeRef::Cast(type).type();
    }
    return Instance::NullIsInstanceOf(type, Object::null_type_arguments(),
                                      Object::null_type_arguments());
  }
  return other.IsLegacy() && (other.IsObjectType() || other.IsNeverType());
}

// Must be kept in sync with GenerateNullIsAssignableToType in
// stub_code_compiler.cc if any changes are made.
bool Instance::NullIsAssignableTo(const AbstractType& other) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();

  // In weak mode, Null is a bottom type (according to LEGACY_SUBTYPE).
  if (!isolate->use_strict_null_safety_checks()) {
    return true;
  }
  // "Left Null" rule: null is assignable when destination type is either
  // legacy or nullable. Otherwise it is not assignable or we cannot tell
  // without instantiating type parameter.
  if (other.IsLegacy() || other.IsNullable()) {
    return true;
  }
  if (other.IsFutureOrType()) {
    return NullIsAssignableTo(
        AbstractType::Handle(zone, other.UnwrapFutureOr()));
  }
  return false;
}

bool Instance::RuntimeTypeIsSubtypeOf(
    const AbstractType& other,
    const TypeArguments& other_instantiator_type_arguments,
    const TypeArguments& other_function_type_arguments) const {
  ASSERT(other.IsFinalized());
  ASSERT(!other.IsTypeRef());  // Must be dereferenced at compile time.
  ASSERT(raw() != Object::sentinel().raw());
  // Instance may not have runtimeType dynamic, void, or Never.
  if (other.IsTopTypeForSubtyping()) {
    return true;
  }
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  // In weak testing mode, Null type is a subtype of any type.
  if (IsNull() && !isolate->use_strict_null_safety_checks()) {
    return true;
  }
  const Class& cls = Class::Handle(zone, clazz());
  if (cls.IsClosureClass()) {
    if (other.IsDartFunctionType() || other.IsDartClosureType() ||
        other.IsObjectType()) {
      return true;
    }
    AbstractType& instantiated_other = AbstractType::Handle(zone, other.raw());
    if (!other.IsInstantiated()) {
      instantiated_other = other.InstantiateFrom(
          other_instantiator_type_arguments, other_function_type_arguments,
          kAllFree, Heap::kOld);
      if (instantiated_other.IsTypeRef()) {
        instantiated_other = TypeRef::Cast(instantiated_other).type();
      }
      if (instantiated_other.IsTopTypeForSubtyping() ||
          instantiated_other.IsDartFunctionType()) {
        return true;
      }
    }
    if (RuntimeTypeIsSubtypeOfFutureOr(zone, instantiated_other)) {
      return true;
    }
    if (!instantiated_other.IsFunctionType()) {
      return false;
    }
    Function& other_signature =
        Function::Handle(zone, Type::Cast(instantiated_other).signature());
    const Function& sig_fun =
        Function::Handle(Closure::Cast(*this).GetInstantiatedSignature(zone));
    return sig_fun.IsSubtypeOf(other_signature, Heap::kOld);
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
  AbstractType& instantiated_other = AbstractType::Handle(zone, other.raw());
  if (!other.IsInstantiated()) {
    instantiated_other = other.InstantiateFrom(
        other_instantiator_type_arguments, other_function_type_arguments,
        kAllFree, Heap::kOld);
    if (instantiated_other.IsTypeRef()) {
      instantiated_other = TypeRef::Cast(instantiated_other).type();
    }
    if (instantiated_other.IsTopTypeForSubtyping()) {
      return true;
    }
  }
  if (!instantiated_other.IsType()) {
    return false;
  }
  if (IsNull()) {
    ASSERT(isolate->use_strict_null_safety_checks());
    if (instantiated_other.IsNullType()) {
      return true;
    }
    if (RuntimeTypeIsSubtypeOfFutureOr(zone, instantiated_other)) {
      return true;
    }
    return !instantiated_other.IsNonNullable();
  }
  // RuntimeType of non-null instance is non-nullable, so there is no need to
  // check nullability of other type.
  return Class::IsSubtypeOf(cls, type_arguments, Nullability::kNonNullable,
                            instantiated_other, Heap::kOld);
}

bool Instance::RuntimeTypeIsSubtypeOfFutureOr(Zone* zone,
                                              const AbstractType& other) const {
  if (other.IsFutureOrType()) {
    const TypeArguments& other_type_arguments =
        TypeArguments::Handle(zone, other.arguments());
    const AbstractType& other_type_arg =
        AbstractType::Handle(zone, other_type_arguments.TypeAtNullSafe(0));
    if (other_type_arg.IsTopTypeForSubtyping()) {
      return true;
    }
    if (Class::Handle(zone, clazz()).IsFutureClass()) {
      const TypeArguments& type_arguments =
          TypeArguments::Handle(zone, GetTypeArguments());
      const AbstractType& type_arg =
          AbstractType::Handle(zone, type_arguments.TypeAtNullSafe(0));
      if (type_arg.IsSubtypeOf(other_type_arg, Heap::kOld)) {
        return true;
      }
    }
    // Retry RuntimeTypeIsSubtypeOf after unwrapping type arg of FutureOr.
    if (RuntimeTypeIsSubtypeOf(other_type_arg, Object::null_type_arguments(),
                               Object::null_type_arguments())) {
      return true;
    }
  }
  return false;
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
  TypedDataPtr native_fields = static_cast<TypedDataPtr>(*NativeFieldsAddr());
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
    if (function != nullptr) {
      *function = Closure::Cast(*this).function();
    }
    return true;
  }
  // Try to resolve a "call" method.
  Zone* zone = Thread::Current()->zone();
  Function& call_function = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, cls, Symbols::Call(),
                                            /*allow_add=*/false));
  if (call_function.IsNull()) {
    return false;
  }
  if (function != nullptr) {
    *function = call_function.raw();
  }
  return true;
}

InstancePtr Instance::New(const Class& cls, Heap::Space space) {
  Thread* thread = Thread::Current();
  if (cls.EnsureIsAllocateFinalized(thread) != Error::null()) {
    return Instance::null();
  }
  intptr_t instance_size = cls.host_instance_size();
  ASSERT(instance_size > 0);
  ObjectPtr raw = Object::Allocate(cls.id(), instance_size, space);
  return static_cast<InstancePtr>(raw);
}

InstancePtr Instance::NewFromCidAndSize(SharedClassTable* shared_class_table,
                                        classid_t cid,
                                        Heap::Space heap) {
  const intptr_t instance_size = shared_class_table->SizeAt(cid);
  ASSERT(instance_size > 0);
  ObjectPtr raw = Object::Allocate(cid, instance_size, heap);
  return static_cast<InstancePtr>(raw);
}

bool Instance::IsValidFieldOffset(intptr_t offset) const {
  Thread* thread = Thread::Current();
  REUSABLE_CLASS_HANDLESCOPE(thread);
  Class& cls = thread->ClassHandle();
  cls = clazz();
  return (offset >= 0 && offset <= (cls.host_instance_size() - kWordSize));
}

intptr_t Instance::ElementSizeFor(intptr_t cid) {
  if (IsExternalTypedDataClassId(cid) || IsTypedDataClassId(cid) ||
      IsTypedDataViewClassId(cid)) {
    return TypedDataBase::ElementSizeInBytes(cid);
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
      return Array::kBytesPerElement;
    case kTypeArgumentsCid:
      return TypeArguments::ArrayTraits::kElementSize;
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
  if (IsExternalTypedDataClassId(cid) || IsExternalStringClassId(cid)) {
    // Elements start at offset 0 of the external data.
    return 0;
  }
  if (IsTypedDataClassId(cid)) {
    return TypedData::data_offset();
  }
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
      return Array::data_offset();
    case kTypeArgumentsCid:
      return TypeArguments::types_offset();
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
    // Background compiler disassembly of instructions referring to pool objects
    // calls this function and requires allocation of Type in old space.
    const AbstractType& type = AbstractType::Handle(GetType(Heap::kOld));
    const String& type_name = String::Handle(type.UserVisibleName());
    return OS::SCreate(Thread::Current()->zone(), "Instance of '%s'",
                       type_name.ToCString());
  }
}

classid_t AbstractType::type_class_id() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return kIllegalCid;
}

ClassPtr AbstractType::type_class() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return Class::null();
}

TypeArgumentsPtr AbstractType::arguments() const {
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

Nullability AbstractType::nullability() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return Nullability::kNullable;
}

bool AbstractType::IsStrictlyNonNullable() const {
  // Null can be assigned to legacy and nullable types.
  if (!IsNonNullable()) {
    return false;
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  // In weak mode null can be assigned to any type.
  if (!thread->isolate()->null_safety()) {
    return false;
  }

  if (IsTypeParameter()) {
    const auto& bound =
        AbstractType::Handle(zone, TypeParameter::Cast(*this).bound());
    ASSERT(!bound.IsNull());
    return bound.IsStrictlyNonNullable();
  }
  if (IsFutureOrType()) {
    return AbstractType::Handle(zone, UnwrapFutureOr()).IsStrictlyNonNullable();
  }
  return true;
}

AbstractTypePtr AbstractType::SetInstantiatedNullability(
    const TypeParameter& type_param,
    Heap::Space space) const {
  Nullability result_nullability;
  const Nullability arg_nullability = nullability();
  const Nullability var_nullability = type_param.nullability();
  // Adjust nullability of result 'arg' instantiated from 'var'.
  // arg/var ! ? *
  //  !      ! ? *
  //  ?      ? ? ?
  //  *      * ? *
  if (var_nullability == Nullability::kNullable ||
      arg_nullability == Nullability::kNullable) {
    result_nullability = Nullability::kNullable;
  } else if (var_nullability == Nullability::kLegacy ||
             arg_nullability == Nullability::kLegacy) {
    result_nullability = Nullability::kLegacy;
  } else {
    // Keep arg nullability.
    return raw();
  }
  if (arg_nullability == result_nullability) {
    return raw();
  }
  if (IsType()) {
    return Type::Cast(*this).ToNullability(result_nullability, space);
  }
  if (IsTypeParameter()) {
    return TypeParameter::Cast(*this).ToNullability(result_nullability, space);
  }
  // TODO(regis): TypeRefs are problematic, since changing the nullability of
  // a type by cloning it may break the graph of a recursive type.
  ASSERT(IsTypeRef());
  return AbstractType::Handle(TypeRef::Cast(*this).type())
      .SetInstantiatedNullability(type_param, space);
}

AbstractTypePtr AbstractType::NormalizeFutureOrType(Heap::Space space) const {
  if (IsFutureOrType()) {
    Zone* zone = Thread::Current()->zone();
    const AbstractType& unwrapped_type =
        AbstractType::Handle(zone, UnwrapFutureOr());
    const classid_t cid = unwrapped_type.type_class_id();
    if (cid == kDynamicCid || cid == kVoidCid) {
      return unwrapped_type.raw();
    }
    if (cid == kInstanceCid) {
      if (IsNonNullable()) {
        return unwrapped_type.raw();
      }
      if (IsNullable() || unwrapped_type.IsNullable()) {
        return Type::Cast(unwrapped_type)
            .ToNullability(Nullability::kNullable, space);
      }
      return Type::Cast(unwrapped_type)
          .ToNullability(Nullability::kLegacy, space);
    }
    if (cid == kNeverCid && unwrapped_type.IsNonNullable()) {
      ObjectStore* object_store = Isolate::Current()->object_store();
      const Type& future_never_type =
          Type::Handle(zone, object_store->non_nullable_future_never_type());
      ASSERT(!future_never_type.IsNull());
      return future_never_type.ToNullability(nullability(), space);
    }
    if (cid == kNullCid) {
      ObjectStore* object_store = Isolate::Current()->object_store();
      ASSERT(object_store->nullable_future_null_type() != Type::null());
      return object_store->nullable_future_null_type();
    }
    if (IsNullable() && unwrapped_type.IsNullable()) {
      return Type::Cast(*this).ToNullability(Nullability::kNonNullable, space);
    }
  }
  return raw();
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

bool AbstractType::IsEquivalent(const Instance& other,
                                TypeEquality kind,
                                TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

bool AbstractType::IsRecursive() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}

AbstractTypePtr AbstractType::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    intptr_t num_free_fun_type_params,
    Heap::Space space,
    TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

AbstractTypePtr AbstractType::Canonicalize(Thread* thread,
                                           TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}

void AbstractType::EnumerateURIs(URIs* uris) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
}

AbstractTypePtr AbstractType::OnlyBuddyInTrail(TrailPtr trail) const {
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

void AbstractType::AddURI(URIs* uris, const String& name, const String& uri) {
  ASSERT(uris != NULL);
  const intptr_t len = uris->length();
  ASSERT((len % 3) == 0);
  bool print_uri = false;
  for (intptr_t i = 0; i < len; i += 3) {
    if (uris->At(i).Equals(name)) {
      if (uris->At(i + 1).Equals(uri)) {
        // Same name and same URI: no need to add this already listed URI.
        return;  // No state change is possible.
      } else {
        // Same name and different URI: the name is ambiguous, print both URIs.
        print_uri = true;
        uris->SetAt(i + 2, Symbols::print());
      }
    }
  }
  uris->Add(name);
  uris->Add(uri);
  if (print_uri) {
    uris->Add(Symbols::print());
  } else {
    uris->Add(Symbols::Empty());
  }
}

StringPtr AbstractType::PrintURIs(URIs* uris) {
  ASSERT(uris != NULL);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const intptr_t len = uris->length();
  ASSERT((len % 3) == 0);
  GrowableHandlePtrArray<const String> pieces(zone, 5 * (len / 3));
  for (intptr_t i = 0; i < len; i += 3) {
    // Only print URIs that have been marked.
    if (uris->At(i + 2).raw() == Symbols::print().raw()) {
      pieces.Add(Symbols::TwoSpaces());
      pieces.Add(uris->At(i));
      pieces.Add(Symbols::SpaceIsFromSpace());
      pieces.Add(uris->At(i + 1));
      pieces.Add(Symbols::NewLine());
    }
  }
  return Symbols::FromConcatAll(thread, pieces);
}

const char* AbstractType::NullabilitySuffix(
    NameVisibility name_visibility) const {
  if (IsDynamicType() || IsVoidType() || IsNullType()) {
    // Hide nullable suffix.
    return "";
  }
  // Keep in sync with Nullability enum in runtime/vm/object.h.
  switch (nullability()) {
    case Nullability::kNullable:
      return "?";
    case Nullability::kNonNullable:
      return "";
    case Nullability::kLegacy:
      return (FLAG_show_internal_names || name_visibility == kInternalName)
                 ? "*"
                 : "";
    default:
      UNREACHABLE();
  }
}

StringPtr AbstractType::Name() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintName(kInternalName, &printer);
  return Symbols::New(thread, printer.buffer());
}

StringPtr AbstractType::UserVisibleName() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  PrintName(kUserVisibleName, &printer);
  return Symbols::New(thread, printer.buffer());
}

void AbstractType::PrintName(
    NameVisibility name_visibility,
    BaseTextBuffer* printer,
    NameDisambiguation name_disambiguation /* = NameDisambiguation::kNo */)
    const {
  ASSERT(name_visibility != kScrubbedName);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Class& cls = Class::Handle(zone);
  String& name_str = String::Handle(zone);
  if (IsTypeParameter()) {
    const TypeParameter& param = TypeParameter::Cast(*this);

    // Type parameters might have the same name but be owned by different
    // entities. If we want to disambiguate them we need to prefix
    // type parameter name with the name of its owner.
    if (name_disambiguation == NameDisambiguation::kYes) {
      cls = param.parameterized_class();
      if (cls.raw() != Class::null()) {
        printer->AddString(cls.NameCString(name_visibility));
        printer->AddString("::");
      } else if (param.parameterized_function() != Function::null()) {
        const Function& func =
            Function::Handle(zone, param.parameterized_function());
        func.PrintName(
            NameFormattingParams(name_visibility, name_disambiguation),
            printer);
        printer->AddString("::");
      }
    }

    name_str = param.name();
    printer->AddString(name_str.ToCString());
    printer->AddString(NullabilitySuffix(name_visibility));
    return;
  }
  const TypeArguments& args = TypeArguments::Handle(zone, arguments());
  const intptr_t num_args = args.IsNull() ? 0 : args.Length();
  intptr_t first_type_param_index;
  intptr_t num_type_params;  // Number of type parameters to print.
  cls = type_class();
  if (IsFunctionType()) {
    const Function& signature_function =
        Function::Handle(zone, Type::Cast(*this).signature());
    if (!cls.IsTypedefClass()) {
      const char* suffix = NullabilitySuffix(name_visibility);
      if (suffix[0] != '\0') {
        printer->AddString("(");
      }
      signature_function.PrintSignature(name_visibility, printer);
      if (suffix[0] != '\0') {
        printer->AddString(")");
        printer->AddString(suffix);
      }
      return;
    }
    // Instead of printing the actual signature, use the typedef name with
    // its type arguments, if any.
    name_str = cls.Name();  // Typedef name.
    if (!IsFinalized() || IsBeingFinalized()) {
      // TODO(regis): Check if this is dead code.
      printer->AddString(name_str.ToCString());
      printer->AddString(NullabilitySuffix(name_visibility));
      return;
    }
    // Print the name of a typedef as a regular, possibly parameterized, class.
  }
  // Do not print the full vector, but only the declared type parameters.
  num_type_params = cls.NumTypeParameters();
  if (name_visibility == kInternalName) {
    name_str = cls.Name();
    printer->AddString(name_str.ToCString());
  } else {
    ASSERT(name_visibility == kUserVisibleName);
    // Map internal types to their corresponding public interfaces.
    printer->AddString(cls.UserVisibleNameCString());
  }
  if (num_type_params > num_args) {
    first_type_param_index = 0;
    if (!IsFinalized() || IsBeingFinalized()) {
      // TODO(regis): Check if this is dead code.
      num_type_params = num_args;
    } else {
      ASSERT(num_args == 0);  // Type is raw.
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
  if (num_type_params == 0) {
    // Do nothing.
  } else {
    args.PrintSubvectorName(first_type_param_index, num_type_params,
                            name_visibility, printer, name_disambiguation);
  }
  printer->AddString(NullabilitySuffix(name_visibility));
  // The name is only used for type checking and debugging purposes.
  // Unless profiling data shows otherwise, it is not worth caching the name in
  // the type.
}

StringPtr AbstractType::ClassName() const {
  ASSERT(!IsFunctionType());
  return Class::Handle(type_class()).Name();
}

bool AbstractType::IsNullTypeRef() const {
  return IsTypeRef() && (TypeRef::Cast(*this).type() == AbstractType::null());
}

bool AbstractType::IsNullType() const {
  return type_class_id() == kNullCid;
}

bool AbstractType::IsNeverType() const {
  return type_class_id() == kNeverCid;
}

bool AbstractType::IsTopTypeForInstanceOf() const {
  const classid_t cid = type_class_id();
  if (cid == kDynamicCid || cid == kVoidCid) {
    return true;
  }
  if (cid == kInstanceCid) {  // Object type.
    return !IsNonNullable();  // kLegacy or kNullable.
  }
  if (cid == kFutureOrCid) {
    // FutureOr<T> where T is a top type behaves as a top type.
    return AbstractType::Handle(UnwrapFutureOr()).IsTopTypeForInstanceOf();
  }
  return false;
}

// Must be kept in sync with GenerateTypeIsTopTypeForSubtyping in
// stub_code_compiler.cc if any changes are made.
bool AbstractType::IsTopTypeForSubtyping() const {
  const classid_t cid = type_class_id();
  if (cid == kDynamicCid || cid == kVoidCid) {
    return true;
  }
  if (cid == kInstanceCid) {  // Object type.
    // NNBD weak mode uses LEGACY_SUBTYPE for assignability / 'as' tests,
    // and non-nullable Object is a top type according to LEGACY_SUBTYPE.
    return !IsNonNullable() ||
           !Isolate::Current()->use_strict_null_safety_checks();
  }
  if (cid == kFutureOrCid) {
    // FutureOr<T> where T is a top type behaves as a top type.
    return AbstractType::Handle(UnwrapFutureOr()).IsTopTypeForSubtyping();
  }
  return false;
}

bool AbstractType::IsIntType() const {
  return HasTypeClass() &&
         (type_class() == Type::Handle(Type::IntType()).type_class());
}

bool AbstractType::IsDoubleType() const {
  return HasTypeClass() &&
         (type_class() == Type::Handle(Type::Double()).type_class());
}

bool AbstractType::IsFloat32x4Type() const {
  // kFloat32x4Cid refers to the private class and cannot be used here.
  return HasTypeClass() &&
         (type_class() == Type::Handle(Type::Float32x4()).type_class());
}

bool AbstractType::IsFloat64x2Type() const {
  // kFloat64x2Cid refers to the private class and cannot be used here.
  return HasTypeClass() &&
         (type_class() == Type::Handle(Type::Float64x2()).type_class());
}

bool AbstractType::IsInt32x4Type() const {
  // kInt32x4Cid refers to the private class and cannot be used here.
  return HasTypeClass() &&
         (type_class() == Type::Handle(Type::Int32x4()).type_class());
}

bool AbstractType::IsStringType() const {
  return HasTypeClass() &&
         (type_class() == Type::Handle(Type::StringType()).type_class());
}

bool AbstractType::IsDartFunctionType() const {
  return HasTypeClass() &&
         (type_class() == Type::Handle(Type::DartFunctionType()).type_class());
}

bool AbstractType::IsDartClosureType() const {
  // Non-typedef function types have '_Closure' class as type class, but are not
  // the Dart '_Closure' type.
  return !IsFunctionType() && (type_class_id() == kClosureCid);
}

bool AbstractType::IsFfiPointerType() const {
  return HasTypeClass() && type_class_id() == kFfiPointerCid;
}

AbstractTypePtr AbstractType::UnwrapFutureOr() const {
  if (!IsFutureOrType()) {
    return raw();
  }
  if (arguments() == TypeArguments::null()) {
    return Type::dynamic_type().raw();
  }
  Thread* thread = Thread::Current();
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(thread);
  TypeArguments& type_args = thread->TypeArgumentsHandle();
  type_args = arguments();
  REUSABLE_ABSTRACT_TYPE_HANDLESCOPE(thread);
  AbstractType& type_arg = thread->AbstractTypeHandle();
  type_arg = type_args.TypeAt(0);
  while (type_arg.IsFutureOrType()) {
    if (type_arg.arguments() == TypeArguments::null()) {
      return Type::dynamic_type().raw();
    }
    type_args = type_arg.arguments();
    type_arg = type_args.TypeAt(0);
  }
  return type_arg.raw();
}

bool AbstractType::IsSubtypeOf(const AbstractType& other,
                               Heap::Space space,
                               TrailPtr trail) const {
  ASSERT(IsFinalized());
  ASSERT(other.IsFinalized());
  // Reflexivity.
  if (raw() == other.raw()) {
    return true;
  }
  // Right top type.
  if (other.IsTopTypeForSubtyping()) {
    return true;
  }
  // Left bottom type.
  // Any form of Never in weak mode maps to Null and Null is a bottom type in
  // weak mode. In strong mode, Never and Never* are bottom types. Therefore,
  // Never and Never* are bottom types regardless of weak/strong mode.
  // Note that we cannot encounter Never?, as it is normalized to Null.
  if (IsNeverType()) {
    ASSERT(!IsNullable());
    return true;
  }
  // Left top type.
  if (IsDynamicType() || IsVoidType()) {
    return false;
  }
  // Left Null type.
  if (IsNullType()) {
    return Instance::NullIsAssignableTo(other);
  }
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  // Type parameters cannot be handled by Class::IsSubtypeOf().
  // When comparing two uninstantiated function types, one returning type
  // parameter K, the other returning type parameter V, we cannot assume that
  // K is a subtype of V, or vice versa. We only return true if K equals V, as
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
      if (type_param.IsEquivalent(other_type_param,
                                  TypeEquality::kInSubtypeTest)) {
        return true;
      }
    }
    const AbstractType& bound = AbstractType::Handle(zone, type_param.bound());
    ASSERT(bound.IsFinalized());
    // Avoid cycles with F-bounded types.
    if (TestAndAddBuddyToTrail(&trail, other)) {
      return true;
    }
    if (bound.IsSubtypeOf(other, space, trail)) {
      return true;
    }
    // Apply additional subtyping rules if 'other' is 'FutureOr'.
    if (IsSubtypeOfFutureOr(zone, other, space, trail)) {
      return true;
    }
    return false;
  }
  if (other.IsTypeParameter()) {
    return false;
  }
  const Class& type_cls = Class::Handle(zone, type_class());
  const Class& other_type_cls = Class::Handle(zone, other.type_class());
  // Function types cannot be handled by Class::IsSubtypeOf().
  const bool other_is_dart_function_type = other.IsDartFunctionType();
  if (other_is_dart_function_type || other.IsFunctionType()) {
    if (IsFunctionType()) {
      if (isolate->use_strict_null_safety_checks() && IsNullable() &&
          other.IsNonNullable()) {
        return false;
      }
      if (other_is_dart_function_type) {
        return true;
      }
      const Function& other_fun =
          Function::Handle(zone, Type::Cast(other).signature());
      // Check for two function types.
      const Function& fun =
          Function::Handle(zone, Type::Cast(*this).signature());
      return fun.IsSubtypeOf(other_fun, space);
    }
    if (other.IsFunctionType() && !other_type_cls.IsTypedefClass()) {
      // [this] is not a function type. Therefore, non-function type [this]
      // cannot be a subtype of function type [other], unless [other] is not
      // only a function type, but also a named typedef.
      // Indeed a typedef also behaves as a regular class-based type (with
      // type arguments when generic).
      // This check is needed to avoid falling through to class-based type
      // tests, which yield incorrect result if [this] = _Closure class,
      // and [other] is a function type, because class of a function type is
      // also _Closure (unless [other] is a typedef).
      return false;
    }
  }
  if (IsFunctionType()) {
    // Apply additional subtyping rules if 'other' is 'FutureOr'.
    if (IsSubtypeOfFutureOr(zone, other, space, trail)) {
      return true;
    }
    return false;
  }
  return Class::IsSubtypeOf(type_cls, TypeArguments::Handle(zone, arguments()),
                            nullability(), other, space, trail);
}

bool AbstractType::IsSubtypeOfFutureOr(Zone* zone,
                                       const AbstractType& other,
                                       Heap::Space space,
                                       TrailPtr trail) const {
  if (other.IsFutureOrType()) {
    // This function is only called with a receiver that is either a function
    // type or an uninstantiated type parameter, therefore, it cannot be of
    // class Future and we can spare the check.
    ASSERT(IsFunctionType() || IsTypeParameter());
    const TypeArguments& other_type_arguments =
        TypeArguments::Handle(zone, other.arguments());
    const AbstractType& other_type_arg =
        AbstractType::Handle(zone, other_type_arguments.TypeAtNullSafe(0));
    if (other_type_arg.IsTopTypeForSubtyping()) {
      return true;
    }
    // Retry the IsSubtypeOf check after unwrapping type arg of FutureOr.
    if (IsSubtypeOf(other_type_arg, space, trail)) {
      return true;
    }
  }
  return false;
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

void AbstractType::SetTypeTestingStub(const Code& stub) const {
  if (stub.IsNull()) {
    // This only happens during bootstrapping when creating Type objects before
    // we have the instructions.
    ASSERT(type_class_id() == kDynamicCid || type_class_id() == kVoidCid);
    StoreNonPointer(&raw_ptr()->type_test_stub_entry_point_, 0);
    raw_ptr()->set_type_test_stub(stub.raw());
    return;
  }

  Thread* thread = Thread::Current();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  StoreNonPointer(&raw_ptr()->type_test_stub_entry_point_, stub.EntryPoint());
  raw_ptr()->set_type_test_stub(stub.raw());
}

TypePtr Type::NullType() {
  return Isolate::Current()->object_store()->null_type();
}

TypePtr Type::DynamicType() {
  return Object::dynamic_type().raw();
}

TypePtr Type::VoidType() {
  return Object::void_type().raw();
}

TypePtr Type::NeverType() {
  return Isolate::Current()->object_store()->never_type();
}

TypePtr Type::ObjectType() {
  return Isolate::Current()->object_store()->object_type();
}

TypePtr Type::BoolType() {
  return Isolate::Current()->object_store()->bool_type();
}

TypePtr Type::IntType() {
  return Isolate::Current()->object_store()->int_type();
}

TypePtr Type::NullableIntType() {
  return Isolate::Current()->object_store()->nullable_int_type();
}

TypePtr Type::SmiType() {
  return Isolate::Current()->object_store()->smi_type();
}

TypePtr Type::MintType() {
  return Isolate::Current()->object_store()->mint_type();
}

TypePtr Type::Double() {
  return Isolate::Current()->object_store()->double_type();
}

TypePtr Type::NullableDouble() {
  return Isolate::Current()->object_store()->nullable_double_type();
}

TypePtr Type::Float32x4() {
  return Isolate::Current()->object_store()->float32x4_type();
}

TypePtr Type::Float64x2() {
  return Isolate::Current()->object_store()->float64x2_type();
}

TypePtr Type::Int32x4() {
  return Isolate::Current()->object_store()->int32x4_type();
}

TypePtr Type::Number() {
  return Isolate::Current()->object_store()->number_type();
}

TypePtr Type::StringType() {
  return Isolate::Current()->object_store()->string_type();
}

TypePtr Type::ArrayType() {
  return Isolate::Current()->object_store()->array_type();
}

TypePtr Type::DartFunctionType() {
  return Isolate::Current()->object_store()->function_type();
}

TypePtr Type::DartTypeType() {
  return Isolate::Current()->object_store()->type_type();
}

TypePtr Type::NewNonParameterizedType(const Class& type_class) {
  ASSERT(type_class.NumTypeArguments() == 0);
  if (type_class.IsNullClass()) {
    return Type::NullType();
  }
  if (type_class.IsDynamicClass()) {
    return Type::DynamicType();
  }
  if (type_class.IsVoidClass()) {
    return Type::VoidType();
  }
  // It is too early to use the class finalizer, as type_class may not be named
  // yet, so do not call DeclarationType().
  Type& type = Type::Handle(type_class.declaration_type());
  if (type.IsNull()) {
    type = Type::New(Class::Handle(type_class.raw()),
                     Object::null_type_arguments(), TokenPosition::kNoSource,
                     Nullability::kNonNullable);
    type.SetIsFinalized();
    type ^= type.Canonicalize(Thread::Current(), nullptr);
    type_class.set_declaration_type(type);
  }
  ASSERT(type.IsFinalized());
  return type.raw();
}

void Type::SetIsFinalized() const {
  ASSERT(!IsFinalized());
  if (IsInstantiated()) {
    set_type_state(TypeLayout::kFinalizedInstantiated);
  } else {
    set_type_state(TypeLayout::kFinalizedUninstantiated);
  }
}

void Type::ResetIsFinalized() const {
  ASSERT(IsFinalized());
  set_type_state(TypeLayout::kBeingFinalized);
  SetIsFinalized();
}

void Type::SetIsBeingFinalized() const {
  ASSERT(!IsFinalized() && !IsBeingFinalized());
  set_type_state(TypeLayout::kBeingFinalized);
}

TypePtr Type::ToNullability(Nullability value, Heap::Space space) const {
  if (nullability() == value) {
    return raw();
  }
  // Type parameter instantiation may request a nullability change, which should
  // be ignored for types dynamic and void. Type Null cannot be the result of
  // instantiating a non-nullable type parameter (TypeError thrown).
  const classid_t cid = type_class_id();
  if (cid == kDynamicCid || cid == kVoidCid || cid == kNullCid) {
    return raw();
  }
  if (cid == kNeverCid && value == Nullability::kNullable) {
    // Normalize Never? to Null.
    return Type::NullType();
  }
  // Clone type and set new nullability.
  Type& type = Type::Handle();
  // Always cloning in old space and removing space parameter would not satisfy
  // currently existing requests for type instantiation in new space.
  type ^= Object::Clone(*this, space);
  type.set_nullability(value);
  type.SetHash(0);
  type.SetTypeTestingStub(
      Code::Handle(TypeTestingStubGenerator::DefaultCodeForType(type)));
  if (IsCanonical()) {
    // Object::Clone does not clone canonical bit.
    ASSERT(!type.IsCanonical());
    type ^= type.Canonicalize(Thread::Current(), nullptr);
  }
  return type.raw();
}

FunctionPtr Type::signature() const {
  intptr_t cid = raw_ptr()->signature()->GetClassId();
  if (cid == kNullCid) {
    return Function::null();
  }
  ASSERT(cid == kFunctionCid);
  return Function::RawCast(raw_ptr()->signature());
}

void Type::set_signature(const Function& value) const {
  raw_ptr()->set_signature(value.raw());
}

classid_t Type::type_class_id() const {
  return Smi::Value(raw_ptr()->type_class_id());
}

ClassPtr Type::type_class() const {
  return Isolate::Current()->class_table()->At(type_class_id());
}

bool Type::IsInstantiated(Genericity genericity,
                          intptr_t num_free_fun_type_params,
                          TrailPtr trail) const {
  if (raw_ptr()->type_state_ == TypeLayout::kFinalizedInstantiated) {
    return true;
  }
  if ((genericity == kAny) && (num_free_fun_type_params == kAllFree) &&
      (raw_ptr()->type_state_ == TypeLayout::kFinalizedUninstantiated)) {
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
  const Class& cls = Class::Handle(type_class());
  len = cls.NumTypeParameters();  // Check the type parameters only.
  if (len > num_type_args) {
    // This type has the wrong number of arguments and is not finalized yet.
    // Type arguments are reset to null when finalizing such a type.
    ASSERT(!IsFinalized());
    len = num_type_args;
  }
  return (len == 0) ||
         args.IsSubvectorInstantiated(num_type_args - len, len, genericity,
                                      num_free_fun_type_params, trail);
}

AbstractTypePtr Type::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    intptr_t num_free_fun_type_params,
    Heap::Space space,
    TrailPtr trail) const {
  Zone* zone = Thread::Current()->zone();
  ASSERT(IsFinalized() || IsBeingFinalized());
  ASSERT(!IsInstantiated());
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
        instantiator_type_arguments, function_type_arguments,
        num_free_fun_type_params, space, trail);
    // A returned empty_type_arguments indicates a failed instantiation in dead
    // code that must be propagated up to the caller, the optimizing compiler.
    if (type_arguments.raw() == Object::empty_type_arguments().raw()) {
      return Type::null();
    }
  }
  // This uninstantiated type is not modified, as it can be instantiated
  // with different instantiators. Allocate a new instantiated version of it.
  const Type& instantiated_type = Type::Handle(
      zone, Type::New(cls, type_arguments, token_pos(), nullability(), space));
  // For a function type, possibly instantiate and set its signature.
  if (!sig_fun.IsNull()) {
    // If we are finalizing a typedef, do not yet instantiate its signature,
    // since it gets instantiated just before the type is marked as finalized.
    // Other function types should never get instantiated while unfinalized,
    // even while checking bounds of recursive types.
    if (IsFinalized()) {
      // A generic typedef may actually declare an instantiated signature.
      if (!sig_fun.HasInstantiatedSignature(kAny, num_free_fun_type_params)) {
        sig_fun = sig_fun.InstantiateSignatureFrom(
            instantiator_type_arguments, function_type_arguments,
            num_free_fun_type_params, space);
        // A returned null signature indicates a failed instantiation in dead
        // code that must be propagated up to the caller, the optimizing
        // compiler.
        if (sig_fun.IsNull()) {
          return Type::null();
        }
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
    if (IsBeingFinalized()) {
      instantiated_type.SetIsBeingFinalized();
    }
  }
  // Canonicalization is not part of instantiation.
  return instantiated_type.NormalizeFutureOrType(space);
}

bool Type::IsEquivalent(const Instance& other,
                        TypeEquality kind,
                        TrailPtr trail) const {
  ASSERT(!IsNull());
  if (raw() == other.raw()) {
    return true;
  }
  if (other.IsTypeRef()) {
    // Unfold right hand type. Divergence is controlled by left hand type.
    const AbstractType& other_ref_type =
        AbstractType::Handle(TypeRef::Cast(other).type());
    ASSERT(!other_ref_type.IsTypeRef());
    return IsEquivalent(other_ref_type, kind, trail);
  }
  if (!other.IsType()) {
    return false;
  }
  const Type& other_type = Type::Cast(other);
  if (IsFunctionType() != other_type.IsFunctionType()) {
    return false;
  }
  if (type_class_id() != other_type.type_class_id()) {
    return false;
  }
  Nullability this_type_nullability = nullability();
  Nullability other_type_nullability = other_type.nullability();
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  if (kind == TypeEquality::kInSubtypeTest) {
    if (isolate->use_strict_null_safety_checks() &&
        this_type_nullability == Nullability::kNullable &&
        other_type_nullability == Nullability::kNonNullable) {
      return false;
    }
  } else {
    if (kind == TypeEquality::kSyntactical) {
      if (this_type_nullability == Nullability::kLegacy) {
        this_type_nullability = Nullability::kNonNullable;
      }
      if (other_type_nullability == Nullability::kLegacy) {
        other_type_nullability = Nullability::kNonNullable;
      }
    } else {
      ASSERT(kind == TypeEquality::kCanonical);
    }
    if (this_type_nullability != other_type_nullability) {
      return false;
    }
  }
  if (!IsFinalized() || !other_type.IsFinalized()) {
    return false;  // Too early to decide if equal.
  }
  if ((arguments() == other_type.arguments()) &&
      (signature() == other_type.signature())) {
    return true;
  }
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
                                                  num_type_params, kind,
                                                  trail)) {
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
          ASSERT(type_arg.IsEquivalent(other_type_arg, kind, trail));
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

  // Compare function type parameters and their bounds.
  // Check the type parameters and bounds of generic functions.
  if (!sig_fun.HasSameTypeParametersAndBounds(other_sig_fun, kind)) {
    return false;
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
  if (!param_type.IsEquivalent(other_param_type, kind)) {
    return false;
  }
  // Check the types of all parameters.
  const intptr_t num_params = sig_fun.NumParameters();
  ASSERT(other_sig_fun.NumParameters() == num_params);
  for (intptr_t i = 0; i < num_params; i++) {
    param_type = sig_fun.ParameterTypeAt(i);
    other_param_type = other_sig_fun.ParameterTypeAt(i);
    // Use contravariant order in case we test for subtyping.
    if (!other_param_type.IsEquivalent(param_type, kind)) {
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
    if (sig_fun.IsRequiredAt(i) != other_sig_fun.IsRequiredAt(i)) {
      return false;
    }
  }
  return true;
}

bool Type::IsRecursive() const {
  return TypeArguments::Handle(arguments()).IsRecursive();
}

bool Type::IsDeclarationTypeOf(const Class& cls) const {
  ASSERT(type_class() == cls.raw());
  if (cls.IsNullClass()) {
    return true;
  }
  if (cls.IsGeneric() || cls.IsClosureClass() || cls.IsTypedefClass()) {
    return false;
  }
  return nullability() == Nullability::kNonNullable;
}

AbstractTypePtr Type::Canonicalize(Thread* thread, TrailPtr trail) const {
  ASSERT(IsFinalized());
  if (IsCanonical()) {
    ASSERT(TypeArguments::Handle(arguments()).IsOld());
    return this->raw();
  }
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

  const classid_t cid = type_class_id();
  if (cid == kDynamicCid) {
    ASSERT(Object::dynamic_type().IsCanonical());
    return Object::dynamic_type().raw();
  }

  if (cid == kVoidCid) {
    ASSERT(Object::void_type().IsCanonical());
    return Object::void_type().raw();
  }

  const Class& cls = Class::Handle(zone, type_class());

  // Fast canonical lookup/registry for simple types.
  if (IsDeclarationTypeOf(cls)) {
    ASSERT(!IsFunctionType());
    ASSERT(!cls.IsNullClass() || IsNullable());
    Type& type = Type::Handle(zone, cls.declaration_type());
    if (type.IsNull()) {
      ASSERT(!cls.raw()->ptr()->InVMIsolateHeap() ||
             (isolate == Dart::vm_isolate()));
      // Canonicalize the type arguments of the supertype, if any.
      TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
      type_args = type_args.Canonicalize(thread, trail);
      if (IsCanonical()) {
        // Canonicalizing type_args canonicalized this type.
        ASSERT(IsRecursive());
        return this->raw();
      }
      set_arguments(type_args);
      type = cls.declaration_type();
      // May be set while canonicalizing type args.
      if (type.IsNull()) {
        SafepointMutexLocker ml(
            isolate->group()->type_canonicalization_mutex());
        // Recheck if type exists.
        type = cls.declaration_type();
        if (type.IsNull()) {
          if (this->IsNew()) {
            type ^= Object::Clone(*this, Heap::kOld);
          } else {
            type = this->raw();
          }
          ASSERT(type.IsOld());
          type.ComputeHash();
          type.SetCanonical();
          cls.set_declaration_type(type);
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
    SafepointMutexLocker ml(isolate->group()->type_canonicalization_mutex());
    CanonicalTypeSet table(zone, object_store->canonical_types());
    type ^= table.GetOrNull(CanonicalTypeKey(*this));
    ASSERT(object_store->canonical_types() == table.Release().raw());
  }
  if (type.IsNull()) {
    // The type was not found in the table. It is not canonical yet.

    // Canonicalize the type arguments.
    TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
    // In case the type is first canonicalized at runtime, its type argument
    // vector may be longer than necessary. If so, reallocate a vector of the
    // exact size to prevent multiple "canonical" types.
    if (!type_args.IsNull()) {
      const intptr_t num_type_args = cls.NumTypeArguments();
      ASSERT(type_args.Length() >= num_type_args);
      if (type_args.Length() > num_type_args) {
        TypeArguments& new_type_args =
            TypeArguments::Handle(zone, TypeArguments::New(num_type_args));
        AbstractType& type_arg = AbstractType::Handle(zone);
        for (intptr_t i = 0; i < num_type_args; i++) {
          type_arg = type_args.TypeAt(i);
          new_type_args.SetTypeAt(i, type_arg);
        }
        type_args = new_type_args.raw();
        set_arguments(type_args);
        SetHash(0);  // Flush cached hash value.
      }
    }
    type_args = type_args.Canonicalize(thread, trail);
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
    SafepointMutexLocker ml(isolate->group()->type_canonicalization_mutex());
    CanonicalTypeSet table(zone, object_store->canonical_types());
    type ^= table.GetOrNull(CanonicalTypeKey(*this));
    if (type.IsNull()) {
      // Add this Type into the canonical list of types.
      if (this->IsNew()) {
        type ^= Object::Clone(*this, Heap::kOld);
      } else {
        type = this->raw();
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
  if (IsRecursive()) {
    return true;
  }
  const classid_t cid = type_class_id();
  if (cid == kDynamicCid) {
    return (raw() == Object::dynamic_type().raw());
  }
  if (cid == kVoidCid) {
    return (raw() == Object::void_type().raw());
  }
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  AbstractType& type = Type::Handle(zone);
  const Class& cls = Class::Handle(zone, type_class());

  // Fast canonical lookup/registry for simple types.
  if (IsDeclarationTypeOf(cls)) {
    ASSERT(!IsFunctionType());
    type = cls.declaration_type();
    ASSERT(type.IsCanonical());
    return (raw() == type.raw());
  }

  ObjectStore* object_store = isolate->object_store();
  {
    SafepointMutexLocker ml(isolate->group()->type_canonicalization_mutex());
    CanonicalTypeSet table(zone, object_store->canonical_types());
    type ^= table.GetOrNull(CanonicalTypeKey(*this));
    object_store->set_canonical_types(table.Release());
  }
  return (raw() == type.raw());
}
#endif  // DEBUG

void Type::EnumerateURIs(URIs* uris) const {
  if (IsDynamicType() || IsVoidType() || IsNeverType()) {
    return;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  if (IsFunctionType()) {
    // The scope class and type arguments do not appear explicitly in the user
    // visible name. The type arguments were used to instantiate the function
    // type prior to this call.
    const Function& sig_fun = Function::Handle(zone, signature());
    AbstractType& type = AbstractType::Handle(zone);
    const intptr_t num_params = sig_fun.NumParameters();
    for (intptr_t i = 0; i < num_params; i++) {
      type = sig_fun.ParameterTypeAt(i);
      type.EnumerateURIs(uris);
    }
    // Handle result type last, since it appears last in the user visible name.
    type = sig_fun.result_type();
    type.EnumerateURIs(uris);
  } else {
    const Class& cls = Class::Handle(zone, type_class());
    const String& name = String::Handle(zone, cls.UserVisibleName());
    const Library& library = Library::Handle(zone, cls.library());
    const String& uri = String::Handle(zone, library.url());
    AddURI(uris, name, uri);
    const TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
    type_args.EnumerateURIs(uris);
  }
}

intptr_t Type::ComputeHash() const {
  ASSERT(IsFinalized());
  uint32_t result = 0;
  result = CombineHashes(result, type_class_id());
  // A legacy type should have the same hash as its non-nullable version to be
  // consistent with the definition of type equality in Dart code.
  Nullability type_nullability = nullability();
  if (type_nullability == Nullability::kLegacy) {
    type_nullability = Nullability::kNonNullable;
  }
  result = CombineHashes(result, static_cast<uint32_t>(type_nullability));
  uint32_t type_args_hash = TypeArguments::kAllDynamicHash;
  if (arguments() != TypeArguments::null()) {
    // Only include hashes of type arguments corresponding to type parameters.
    // This prevents obtaining different hashes depending on the location of
    // TypeRefs in the super class type argument vector.
    const TypeArguments& type_args = TypeArguments::Handle(arguments());
    const Class& cls = Class::Handle(type_class());
    const intptr_t num_type_params = cls.NumTypeParameters();
    if (num_type_params > 0) {
      const intptr_t from_index = cls.NumTypeArguments() - num_type_params;
      type_args_hash = type_args.HashForRange(from_index, num_type_params);
    }
  }
  result = CombineHashes(result, type_args_hash);
  if (IsFunctionType()) {
    AbstractType& type = AbstractType::Handle();
    const Function& sig_fun = Function::Handle(signature());
    const intptr_t num_type_params = sig_fun.NumTypeParameters();
    if (num_type_params > 0) {
      const TypeArguments& type_params =
          TypeArguments::Handle(sig_fun.type_parameters());
      for (intptr_t i = 0; i < num_type_params; i++) {
        type = type_params.TypeAt(i);
        type = TypeParameter::Cast(type).bound();
        result = CombineHashes(result, type.Hash());
      }
    }
    type = sig_fun.result_type();
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
      // Required flag is not hashed, see comment above.
    }
  }
  result = FinalizeHash(result, kHashBits);
  SetHash(result);
  return result;
}

void Type::set_type_class(const Class& value) const {
  ASSERT(!value.IsNull());
  raw_ptr()->set_type_class_id(Smi::New(value.id()));
}

void Type::set_arguments(const TypeArguments& value) const {
  ASSERT(!IsCanonical());
  raw_ptr()->set_arguments(value.raw());
}

TypePtr Type::New(Heap::Space space) {
  ObjectPtr raw = Object::Allocate(Type::kClassId, Type::InstanceSize(), space);
  return static_cast<TypePtr>(raw);
}

TypePtr Type::New(const Class& clazz,
                  const TypeArguments& arguments,
                  TokenPosition token_pos,
                  Nullability nullability,
                  Heap::Space space) {
  Zone* Z = Thread::Current()->zone();
  const Type& result = Type::Handle(Z, Type::New(space));
  result.set_type_class(clazz);
  result.set_arguments(arguments);
  result.SetHash(0);
  result.set_token_pos(token_pos);
  result.StoreNonPointer(&result.raw_ptr()->type_state_,
                         TypeLayout::kAllocated);
  result.set_nullability(nullability);

  result.SetTypeTestingStub(
      Code::Handle(Z, TypeTestingStubGenerator::DefaultCodeForType(result)));
  return result.raw();
}

void Type::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

void Type::set_type_state(int8_t state) const {
  ASSERT((state >= TypeLayout::kAllocated) &&
         (state <= TypeLayout::kFinalizedUninstantiated));
  StoreNonPointer(&raw_ptr()->type_state_, state);
}

const char* Type::ToCString() const {
  if (IsNull()) {
    return "Type: null";
  }
  Zone* zone = Thread::Current()->zone();
  ZoneTextBuffer args(zone);
  const TypeArguments& type_args = TypeArguments::Handle(zone, arguments());
  const char* args_cstr = "";
  if (!type_args.IsNull()) {
    type_args.PrintSubvectorName(0, type_args.Length(), kInternalName, &args,
                                 NameDisambiguation::kYes);
    args_cstr = args.buffer();
  }
  const Class& cls = Class::Handle(zone, type_class());
  const char* class_name;
  const String& name = String::Handle(zone, cls.Name());
  class_name = name.IsNull() ? "<null>" : name.ToCString();
  const char* suffix = NullabilitySuffix(kInternalName);
  if (IsFunctionType()) {
    const Function& sig_fun = Function::Handle(zone, signature());
    ZoneTextBuffer sig(zone);
    if (suffix[0] != '\0') {
      sig.AddString("(");
    }
    sig_fun.PrintSignature(kInternalName, &sig);
    if (suffix[0] != '\0') {
      sig.AddString(")");
      sig.AddString(suffix);
    }
    if (cls.IsClosureClass()) {
      ASSERT(type_args.IsNull());
      return OS::SCreate(zone, "Function Type: %s", sig.buffer());
    }
    return OS::SCreate(zone, "Function Type: %s (%s%s%s)", sig.buffer(),
                       class_name, args_cstr, suffix);
  }
  if (IsFinalized() && IsRecursive()) {
    const intptr_t hash = Hash();
    return OS::SCreate(zone, "Type: (H%" Px ") %s%s%s", hash, class_name,
                       args_cstr, suffix);
  } else {
    return OS::SCreate(zone, "Type: %s%s%s", class_name, args_cstr, suffix);
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

bool TypeRef::IsEquivalent(const Instance& other,
                           TypeEquality kind,
                           TrailPtr trail) const {
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
  return !ref_type.IsNull() && ref_type.IsEquivalent(other, kind, trail);
}

AbstractTypePtr TypeRef::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    intptr_t num_free_fun_type_params,
    Heap::Space space,
    TrailPtr trail) const {
  TypeRef& instantiated_type_ref = TypeRef::Handle();
  instantiated_type_ref ^= OnlyBuddyInTrail(trail);
  if (!instantiated_type_ref.IsNull()) {
    return instantiated_type_ref.raw();
  }
  instantiated_type_ref = TypeRef::New();
  AddOnlyBuddyToTrail(&trail, instantiated_type_ref);

  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull() && !ref_type.IsTypeRef());
  AbstractType& instantiated_ref_type = AbstractType::Handle();
  instantiated_ref_type = ref_type.InstantiateFrom(
      instantiator_type_arguments, function_type_arguments,
      num_free_fun_type_params, space, trail);
  // A returned null type indicates a failed instantiation in dead code that
  // must be propagated up to the caller, the optimizing compiler.
  if (instantiated_ref_type.IsNull()) {
    return TypeRef::null();
  }
  ASSERT(!instantiated_ref_type.IsTypeRef());
  instantiated_type_ref.set_type(instantiated_ref_type);

  instantiated_type_ref.SetTypeTestingStub(Code::Handle(
      TypeTestingStubGenerator::DefaultCodeForType(instantiated_type_ref)));
  return instantiated_type_ref.raw();
}

void TypeRef::set_type(const AbstractType& value) const {
  ASSERT(value.IsNull() || value.IsFunctionType() || value.HasTypeClass());
  ASSERT(!value.IsTypeRef());
  raw_ptr()->set_type(value.raw());
}

// A TypeRef cannot be canonical by definition. Only its referenced type can be.
// Consider the type Derived, where class Derived extends Base<Derived>.
// The first type argument of its flattened type argument vector is Derived,
// represented by a TypeRef pointing to itself.
AbstractTypePtr TypeRef::Canonicalize(Thread* thread, TrailPtr trail) const {
  if (TestAndAddToTrail(&trail)) {
    return raw();
  }
  // TODO(regis): Try to reduce the number of nodes required to represent the
  // referenced recursive type.
  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull());
  ref_type = ref_type.Canonicalize(thread, trail);
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

void TypeRef::EnumerateURIs(URIs* uris) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const AbstractType& ref_type = AbstractType::Handle(zone, type());
  ASSERT(!ref_type.IsDynamicType() && !ref_type.IsVoidType() &&
         !ref_type.IsNeverType());
  const Class& cls = Class::Handle(zone, ref_type.type_class());
  const String& name = String::Handle(zone, cls.UserVisibleName());
  const Library& library = Library::Handle(zone, cls.library());
  const String& uri = String::Handle(zone, library.url());
  AddURI(uris, name, uri);
  // Break cycle by not printing type arguments.
}

intptr_t TypeRef::Hash() const {
  // Do not use hash of the referenced type because
  //  - we could be in process of calculating it (as TypeRef is used to
  //    represent recursive references to types).
  //  - referenced type might be incomplete (e.g. not all its
  //    type arguments are set).
  const AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsNull());
  uint32_t result = Class::Handle(ref_type.type_class()).id();
  result = CombineHashes(result, static_cast<uint32_t>(ref_type.nullability()));
  return FinalizeHash(result, kHashBits);
}

TypeRefPtr TypeRef::New() {
  ObjectPtr raw =
      Object::Allocate(TypeRef::kClassId, TypeRef::InstanceSize(), Heap::kOld);
  return static_cast<TypeRefPtr>(raw);
}

TypeRefPtr TypeRef::New(const AbstractType& type) {
  Zone* Z = Thread::Current()->zone();
  const TypeRef& result = TypeRef::Handle(Z, TypeRef::New());
  result.set_type(type);

  result.SetTypeTestingStub(
      Code::Handle(Z, TypeTestingStubGenerator::DefaultCodeForType(result)));
  return result.raw();
}

const char* TypeRef::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  AbstractType& ref_type = AbstractType::Handle(zone, type());
  if (ref_type.IsNull()) {
    return "TypeRef: null";
  }
  ZoneTextBuffer printer(zone);
  printer.AddString("TypeRef: ");
  ref_type.PrintName(kInternalName, &printer);
  if (ref_type.IsFinalized()) {
    const intptr_t hash = ref_type.Hash();
    printer.Printf(" (H%" Px ")", hash);
  }
  return printer.buffer();
}

void TypeParameter::SetIsFinalized() const {
  ASSERT(!IsFinalized());
  set_flags(TypeParameterLayout::FinalizedBit::update(true, raw_ptr()->flags_));
}

void TypeParameter::SetGenericCovariantImpl(bool value) const {
  set_flags(TypeParameterLayout::GenericCovariantImplBit::update(
      value, raw_ptr()->flags_));
}

void TypeParameter::SetDeclaration(bool value) const {
  set_flags(
      TypeParameterLayout::DeclarationBit::update(value, raw_ptr()->flags_));
}

void TypeParameter::set_nullability(Nullability value) const {
  StoreNonPointer(&raw_ptr()->nullability_, static_cast<int8_t>(value));
}

TypeParameterPtr TypeParameter::ToNullability(Nullability value,
                                              Heap::Space space) const {
  if (nullability() == value) {
    return raw();
  }
  // Clone type parameter and set new nullability.
  TypeParameter& type_parameter = TypeParameter::Handle();
  type_parameter ^= Object::Clone(*this, space);
  type_parameter.set_nullability(value);
  type_parameter.SetDeclaration(false);
  type_parameter.SetHash(0);
  type_parameter.SetTypeTestingStub(Code::Handle(
      TypeTestingStubGenerator::DefaultCodeForType(type_parameter)));
  if (IsCanonical()) {
    // Object::Clone does not clone canonical bit.
    ASSERT(!type_parameter.IsCanonical());
    if (IsFinalized()) {
      type_parameter ^= type_parameter.Canonicalize(Thread::Current(), nullptr);
    }
  }
  return type_parameter.raw();
}

bool TypeParameter::IsInstantiated(Genericity genericity,
                                   intptr_t num_free_fun_type_params,
                                   TrailPtr trail) const {
  // Bounds of class type parameters are ignored in the VM.
  if (IsClassTypeParameter()) {
    return genericity == kFunctions;
  }
  ASSERT(IsFunctionTypeParameter());
  ASSERT(IsFinalized());
  if ((genericity != kCurrentClass) && (index() < num_free_fun_type_params)) {
    return false;
  }
  // Although the type parameter is instantiated, its bound may not be.
  const AbstractType& upper_bound = AbstractType::Handle(bound());
  if (upper_bound.IsTypeParameter() ||
      upper_bound.arguments() != TypeArguments::null()) {
    // Use trail to break cycles created by bound referring to type parameter.
    if (!TestAndAddToTrail(&trail) &&
        !upper_bound.IsInstantiated(genericity, num_free_fun_type_params,
                                    trail)) {
      return false;
    }
  }
  return true;
}

bool TypeParameter::IsEquivalent(const Instance& other,
                                 TypeEquality kind,
                                 TrailPtr trail) const {
  if (raw() == other.raw()) {
    return true;
  }
  if (other.IsTypeRef()) {
    // Unfold right hand type. Divergence is controlled by left hand type.
    const AbstractType& other_ref_type =
        AbstractType::Handle(TypeRef::Cast(other).type());
    ASSERT(!other_ref_type.IsTypeRef());
    return IsEquivalent(other_ref_type, kind, trail);
  }
  if (!other.IsTypeParameter()) {
    return false;
  }
  const TypeParameter& other_type_param = TypeParameter::Cast(other);
  // Class type parameters must parameterize the same class to be equivalent.
  // Note that this check will also reject a class type parameter being compared
  // to a function type parameter.
  if (parameterized_class_id() != other_type_param.parameterized_class_id()) {
    return false;
  }
  // The function does not matter in type tests or when comparing types with
  // syntactical equality, but it does matter in canonicalization.
  if (kind == TypeEquality::kCanonical &&
      parameterized_function() != other_type_param.parameterized_function()) {
    return false;
  }
  Nullability this_type_param_nullability = nullability();
  Nullability other_type_param_nullability = other_type_param.nullability();
  if (kind == TypeEquality::kInSubtypeTest) {
    if (Isolate::Current()->use_strict_null_safety_checks() &&
        (this_type_param_nullability == Nullability::kNullable) &&
        (other_type_param_nullability == Nullability::kNonNullable)) {
      return false;
    }
  } else {
    if (kind == TypeEquality::kSyntactical) {
      if (this_type_param_nullability == Nullability::kLegacy) {
        this_type_param_nullability = Nullability::kNonNullable;
      }
      if (other_type_param_nullability == Nullability::kLegacy) {
        other_type_param_nullability = Nullability::kNonNullable;
      }
    } else {
      ASSERT(kind == TypeEquality::kCanonical);
    }
    if (this_type_param_nullability != other_type_param_nullability) {
      return false;
    }
  }
  if (kind == TypeEquality::kInSubtypeTest) {
    if (IsFunctionTypeParameter() && IsFinalized() &&
        other_type_param.IsFinalized()) {
      ASSERT(other_type_param.IsFunctionTypeParameter());  // Checked above.
      // To be equivalent, the function type parameters should be declared
      // at the same position in the generic function. Their index therefore
      // needs adjustement before comparison.
      // Example: 'foo<F>(bar<B>(B b)) { }' and 'baz<Z>(Z z) { }', baz can
      // be assigned to bar, although B has index 1 and Z index 0.
      const Function& sig_fun = Function::Handle(parameterized_function());
      const Function& other_sig_fun =
          Function::Handle(other_type_param.parameterized_function());
      const int offset = sig_fun.NumParentTypeParameters();
      const int other_offset = other_sig_fun.NumParentTypeParameters();
      return index() - offset == other_type_param.index() - other_offset;
    } else if (IsFinalized() == other_type_param.IsFinalized()) {
      return index() == other_type_param.index();
    }
    return false;
  }
  if (IsFinalized() == other_type_param.IsFinalized()) {
    return index() == other_type_param.index();
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

ClassPtr TypeParameter::parameterized_class() const {
  classid_t cid = parameterized_class_id();
  if (cid == kFunctionCid) {
    return Class::null();
  }
  return Isolate::Current()->class_table()->At(cid);
}

void TypeParameter::set_parameterized_function(const Function& value) const {
  raw_ptr()->set_parameterized_function(value.raw());
}

void TypeParameter::set_index(intptr_t value) const {
  ASSERT(value >= 0);
  ASSERT(Utils::IsInt(16, value));
  StoreNonPointer(&raw_ptr()->index_, value);
}

void TypeParameter::set_name(const String& value) const {
  ASSERT(value.IsSymbol());
  raw_ptr()->set_name(value.raw());
}

void TypeParameter::set_bound(const AbstractType& value) const {
  raw_ptr()->set_bound(value.raw());
}

void TypeParameter::set_default_argument(const AbstractType& value) const {
  raw_ptr()->set_default_argument(value.raw());
}

AbstractTypePtr TypeParameter::GetFromTypeArguments(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments) const {
  ASSERT(IsFinalized());
  const TypeArguments& type_args = IsFunctionTypeParameter()
                                       ? function_type_arguments
                                       : instantiator_type_arguments;
  return type_args.TypeAtNullSafe(index());
}

AbstractTypePtr TypeParameter::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    intptr_t num_free_fun_type_params,
    Heap::Space space,
    TrailPtr trail) const {
  ASSERT(IsFinalized());
  AbstractType& result = AbstractType::Handle();
  if (IsFunctionTypeParameter()) {
    if (index() >= num_free_fun_type_params) {
      // Do not instantiate the function type parameter, but possibly its bound.
      result = raw();
      AbstractType& upper_bound = AbstractType::Handle(bound());
      if (!upper_bound.IsInstantiated(kAny, num_free_fun_type_params,
                                      nullptr)) {
        // Use trail to break cycles created by bound referring to type param.
        if (OnlyBuddyInTrail(trail) == Object::null()) {
          AddOnlyBuddyToTrail(&trail, *this);
          upper_bound = upper_bound.InstantiateFrom(
              instantiator_type_arguments, function_type_arguments,
              num_free_fun_type_params, space, trail);
          if (upper_bound.raw() == Type::NeverType()) {
            // Normalize 'X extends Never' to 'Never'.
            result = Type::NeverType();
          } else if (upper_bound.raw() != bound()) {
            result ^= Object::Clone(result, space);
            TypeParameter::Cast(result).set_bound(upper_bound);
          }
        }
      }
    } else if (function_type_arguments.IsNull()) {
      return Type::DynamicType();
    } else {
      result = function_type_arguments.TypeAt(index());
      ASSERT(!result.IsTypeParameter());
    }
  } else {
    ASSERT(IsClassTypeParameter());
    if (instantiator_type_arguments.IsNull()) {
      return Type::DynamicType();
    }
    if (instantiator_type_arguments.Length() <= index()) {
      // InstantiateFrom can be invoked from a compilation pipeline with
      // mismatching type arguments vector. This can only happen for
      // a dynamically unreachable code - which compiler can't remove
      // statically for some reason.
      // To prevent crashes we return AbstractType::null(), understood by caller
      // (see AssertAssignableInstr::Canonicalize).
      return AbstractType::null();
    }
    result = instantiator_type_arguments.TypeAt(index());
    // Instantiating a class type parameter cannot result in a
    // function type parameter.
    // Bounds of class type parameters are ignored in the VM.
  }
  result = result.SetInstantiatedNullability(*this, space);
  // Canonicalization is not part of instantiation.
  return result.NormalizeFutureOrType(space);
}

AbstractTypePtr TypeParameter::Canonicalize(Thread* thread,
                                            TrailPtr trail) const {
  ASSERT(IsFinalized());
  if (IsCanonical()) {
    return this->raw();
  }
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

  const Class& cls = Class::Handle(zone, parameterized_class());
  const Function& function = Function::Handle(
      zone, cls.IsNull() ? parameterized_function() : Function::null());
  const TypeArguments& type_params = TypeArguments::Handle(
      zone, cls.IsNull() ? function.type_parameters() : cls.type_parameters());
  const intptr_t offset =
      cls.IsNull() ? function.NumParentTypeParameters()
                   : (cls.NumTypeArguments() - cls.NumTypeParameters());
  TypeParameter& type_parameter = TypeParameter::Handle(zone);
  type_parameter ^= type_params.TypeAt(index() - offset);
  ASSERT(!type_parameter.IsNull());
  if (type_parameter.nullability() == nullability()) {
    ASSERT(this->Equals(type_parameter));
    ASSERT(type_parameter.IsCanonical());
    ASSERT(type_parameter.IsDeclaration());
    ASSERT(type_parameter.IsOld());
    return type_parameter.raw();
  }

  ObjectStore* object_store = isolate->object_store();
  {
    SafepointMutexLocker ml(isolate->group()->type_canonicalization_mutex());
    CanonicalTypeParameterSet table(zone,
                                    object_store->canonical_type_parameters());
    type_parameter ^= table.GetOrNull(CanonicalTypeParameterKey(*this));
    if (type_parameter.IsNull()) {
      // The type parameter was not found in the table. It is not canonical yet.
      // Add this type parameter into the canonical list of type parameters.
      if (this->IsNew()) {
        type_parameter ^= Object::Clone(*this, Heap::kOld);
      } else {
        type_parameter = this->raw();
      }
      ASSERT(type_parameter.IsOld());
      type_parameter.SetCanonical();  // Mark object as being canonical.
      bool present = table.Insert(type_parameter);
      ASSERT(!present);
    }
    object_store->set_canonical_type_parameters(table.Release());
  }
  ASSERT(!type_parameter.IsDeclaration());
  return type_parameter.raw();
}

#if defined(DEBUG)
bool TypeParameter::CheckIsCanonical(Thread* thread) const {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

  const Class& cls = Class::Handle(zone, parameterized_class());
  const Function& function = Function::Handle(
      zone, cls.IsNull() ? parameterized_function() : Function::null());
  const TypeArguments& type_params = TypeArguments::Handle(
      zone, cls.IsNull() ? function.type_parameters() : cls.type_parameters());
  const intptr_t offset =
      IsFinalized()
          ? (cls.IsNull() ? function.NumParentTypeParameters()
                          : (cls.NumTypeArguments() - cls.NumTypeParameters()))
          : 0;
  TypeParameter& type_parameter = TypeParameter::Handle(zone);
  type_parameter ^= type_params.TypeAt(index() - offset);
  ASSERT(!type_parameter.IsNull());
  if (type_parameter.nullability() == nullability()) {
    ASSERT(type_parameter.IsCanonical());
    return (raw() == type_parameter.raw());
  }

  ObjectStore* object_store = isolate->object_store();
  {
    SafepointMutexLocker ml(isolate->group()->type_canonicalization_mutex());
    CanonicalTypeParameterSet table(zone,
                                    object_store->canonical_type_parameters());
    type_parameter ^= table.GetOrNull(CanonicalTypeParameterKey(*this));
    object_store->set_canonical_type_parameters(table.Release());
  }
  return (raw() == type_parameter.raw());
}
#endif  // DEBUG

void TypeParameter::EnumerateURIs(URIs* uris) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, 4);
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
    const String& name =
        String::Handle(zone, Symbols::FromConcatAll(thread, pieces));
    const Library& library = Library::Handle(zone, cls.library());
    const String& uri = String::Handle(zone, library.url());
    AddURI(uris, name, uri);
  }
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
  // A legacy type should have the same hash as its non-nullable version to be
  // consistent with the definition of type equality in Dart code.
  Nullability type_param_nullability = nullability();
  if (type_param_nullability == Nullability::kLegacy) {
    type_param_nullability = Nullability::kNonNullable;
  }
  result = CombineHashes(result, static_cast<uint32_t>(type_param_nullability));
  result = FinalizeHash(result, kHashBits);
  SetHash(result);
  return result;
}

TypeParameterPtr TypeParameter::New() {
  ObjectPtr raw = Object::Allocate(TypeParameter::kClassId,
                                   TypeParameter::InstanceSize(), Heap::kOld);
  return static_cast<TypeParameterPtr>(raw);
}

TypeParameterPtr TypeParameter::New(const Class& parameterized_class,
                                    const Function& parameterized_function,
                                    intptr_t index,
                                    const String& name,
                                    const AbstractType& bound,
                                    bool is_generic_covariant_impl,
                                    Nullability nullability,
                                    TokenPosition token_pos) {
  ASSERT(parameterized_class.IsNull() != parameterized_function.IsNull());
  Zone* Z = Thread::Current()->zone();
  const TypeParameter& result = TypeParameter::Handle(Z, TypeParameter::New());
  result.set_parameterized_class(parameterized_class);
  result.set_parameterized_function(parameterized_function);
  result.set_index(index);
  result.set_name(name);
  result.set_bound(bound);
  result.set_flags(0);
  result.set_nullability(nullability);
  result.SetGenericCovariantImpl(is_generic_covariant_impl);
  result.SetDeclaration(false);
  result.SetHash(0);
  result.set_token_pos(token_pos);

  result.SetTypeTestingStub(
      Code::Handle(Z, TypeTestingStubGenerator::DefaultCodeForType(result)));
  return result.raw();
}

void TypeParameter::set_token_pos(TokenPosition token_pos) const {
  ASSERT(!token_pos.IsClassifying());
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}

void TypeParameter::set_flags(uint8_t flags) const {
  StoreNonPointer(&raw_ptr()->flags_, flags);
}

const char* TypeParameter::ToCString() const {
  Thread* thread = Thread::Current();
  ZoneTextBuffer printer(thread->zone());
  auto& name_str = String::Handle(thread->zone(), name());
  printer.Printf("TypeParameter: name ");
  printer.AddString(name_str.ToCString());
  printer.AddString(NullabilitySuffix(kInternalName));
  printer.Printf("; index: %" Pd ";", index());
  if (IsFunctionTypeParameter()) {
    const Function& function = Function::Handle(parameterized_function());
    printer.Printf(" function: ");
    name_str = function.name();
    printer.AddString(name_str.ToCString());
  } else {
    const Class& cls = Class::Handle(parameterized_class());
    printer.Printf(" class: ");
    name_str = cls.Name();
    printer.AddString(name_str.ToCString());
  }
  printer.Printf("; bound: ");
  const AbstractType& upper_bound = AbstractType::Handle(bound());
  if (upper_bound.IsNull()) {
    printer.AddString("<null>");
  } else {
    upper_bound.PrintName(kInternalName, &printer);
  }
  return printer.buffer();
}

InstancePtr Number::CanonicalizeLocked(Thread* thread) const {
  intptr_t cid = GetClassId();
  switch (cid) {
    case kSmiCid:
      return static_cast<SmiPtr>(raw_value());
    case kMintCid:
      return Mint::NewCanonicalLocked(thread, Mint::Cast(*this).value());
    case kDoubleCid:
      return Double::NewCanonicalLocked(thread, Double::Cast(*this).value());
    default:
      UNREACHABLE();
  }
  return Instance::null();
}

#if defined(DEBUG)
bool Number::CheckIsCanonical(Thread* thread) const {
  intptr_t cid = GetClassId();
  Zone* zone = thread->zone();
  const Class& cls = Class::Handle(zone, this->clazz());
  switch (cid) {
    case kSmiCid:
      return true;
    case kMintCid: {
      Mint& result = Mint::Handle(zone);
      result ^= cls.LookupCanonicalMint(zone, Mint::Cast(*this).value());
      return (result.raw() == this->raw());
    }
    case kDoubleCid: {
      Double& dbl = Double::Handle(zone);
      dbl ^= cls.LookupCanonicalDouble(zone, Double::Cast(*this).value());
      return (dbl.raw() == this->raw());
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

IntegerPtr Integer::New(const String& str, Heap::Space space) {
  // We are not supposed to have integers represented as two byte strings.
  ASSERT(str.IsOneByteString());
  if (str.IsNull() || (str.Length() == 0)) {
    return Integer::null();
  }
  int64_t value = 0;
  const char* cstr = str.ToCString();
  if (!OS::StringToInt64(cstr, &value)) {
    // Out of range.
    return Integer::null();
  }
  return Integer::New(value, space);
}

IntegerPtr Integer::NewCanonical(const String& str) {
  // We are not supposed to have integers represented as two byte strings.
  ASSERT(str.IsOneByteString());
  int64_t value = 0;
  const char* cstr = str.ToCString();
  if (!OS::StringToInt64(cstr, &value)) {
    // Out of range.
    return Integer::null();
  }
  return NewCanonical(value);
}

IntegerPtr Integer::NewCanonical(int64_t value) {
  if (Smi::IsValid(value)) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  return Mint::NewCanonical(value);
}

IntegerPtr Integer::New(int64_t value, Heap::Space space) {
  const bool is_smi = Smi::IsValid(value);
  if (is_smi) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  return Mint::New(value, space);
}

IntegerPtr Integer::NewFromUint64(uint64_t value, Heap::Space space) {
  return Integer::New(static_cast<int64_t>(value), space);
}

bool Integer::IsValueInRange(uint64_t value) {
  return (value <= static_cast<uint64_t>(Mint::kMaxValue));
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

IntegerPtr Integer::AsValidInteger() const {
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
  return raw();
}

const char* Integer::ToHexCString(Zone* zone) const {
  ASSERT(IsSmi() || IsMint());
  int64_t value = AsInt64Value();
  if (value < 0) {
    return OS::SCreate(zone, "-0x%" PX64, -static_cast<uint64_t>(value));
  } else {
    return OS::SCreate(zone, "0x%" PX64, static_cast<uint64_t>(value));
  }
}

IntegerPtr Integer::ArithmeticOp(Token::Kind operation,
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
      case Token::kMUL:
        return Integer::New(
            Utils::MulWithWrapAround(static_cast<int64_t>(left_value),
                                     static_cast<int64_t>(right_value)),
            space);
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
  const int64_t left_value = AsInt64Value();
  const int64_t right_value = other.AsInt64Value();
  switch (operation) {
    case Token::kADD:
      return Integer::New(Utils::AddWithWrapAround(left_value, right_value),
                          space);

    case Token::kSUB:
      return Integer::New(Utils::SubWithWrapAround(left_value, right_value),
                          space);

    case Token::kMUL:
      return Integer::New(Utils::MulWithWrapAround(left_value, right_value),
                          space);

    case Token::kTRUNCDIV:
      if ((left_value == Mint::kMinValue) && (right_value == -1)) {
        // Division special case: overflow in int64_t.
        // MIN_VALUE / -1 = (MAX_VALUE + 1), which wraps around to MIN_VALUE
        return Integer::New(Mint::kMinValue, space);
      }
      return Integer::New(left_value / right_value, space);

    case Token::kMOD: {
      if ((left_value == Mint::kMinValue) && (right_value == -1)) {
        // Modulo special case: overflow in int64_t.
        // MIN_VALUE % -1 = 0 for reason given above.
        return Integer::New(0, space);
      }
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
      return Integer::null();
  }
}

IntegerPtr Integer::BitOp(Token::Kind kind,
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
  } else {
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
        return Integer::null();
    }
  }
}

IntegerPtr Integer::ShiftOp(Token::Kind kind,
                            const Integer& other,
                            Heap::Space space) const {
  int64_t a = AsInt64Value();
  int64_t b = other.AsInt64Value();
  ASSERT(b >= 0);
  switch (kind) {
    case Token::kSHL:
      return Integer::New(Utils::ShiftLeftWithTruncation(a, b), space);
    case Token::kSHR:
      return Integer::New(a >> Utils::Minimum<int64_t>(b, Mint::kBits), space);
    default:
      UNIMPLEMENTED();
      return Integer::null();
  }
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
  if (other.IsMint()) {
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

ClassPtr Smi::Class() {
  return Isolate::Current()->object_store()->smi_class();
}

void Mint::set_value(int64_t value) const {
  StoreNonPointer(&raw_ptr()->value_, value);
}

MintPtr Mint::New(int64_t val, Heap::Space space) {
  // Do not allocate a Mint if Smi would do.
  ASSERT(!Smi::IsValid(val));
  ASSERT(Isolate::Current()->object_store()->mint_class() != Class::null());
  Mint& result = Mint::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(Mint::kClassId, Mint::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(val);
  return result.raw();
}

MintPtr Mint::NewCanonical(int64_t value) {
  Thread* thread = Thread::Current();
  SafepointMutexLocker ml(
      thread->isolate_group()->constant_canonicalization_mutex());
  return NewCanonicalLocked(thread, value);
}

MintPtr Mint::NewCanonicalLocked(Thread* thread, int64_t value) {
  // Do not allocate a Mint if Smi would do.
  ASSERT(!Smi::IsValid(value));
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const Class& cls = Class::Handle(zone, isolate->object_store()->mint_class());
  Mint& canonical_value =
      Mint::Handle(zone, cls.LookupCanonicalMint(zone, value));
  if (!canonical_value.IsNull()) {
    return canonical_value.raw();
  }
  canonical_value = Mint::New(value, Heap::kOld);
  canonical_value.SetCanonical();
  // The value needs to be added to the constants list. Grow the list if
  // it is full.
  cls.InsertCanonicalMint(zone, canonical_value);
  return canonical_value.raw();
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
  ASSERT(other.IsMint() || other.IsSmi());
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

uint32_t Double::CanonicalizeHash() const {
  return Hash64To32(bit_cast<uint64_t>(value()));
}

DoublePtr Double::New(double d, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->double_class() != Class::null());
  Double& result = Double::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(Double::kClassId, Double::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(d);
  return result.raw();
}

DoublePtr Double::New(const String& str, Heap::Space space) {
  double double_value;
  if (!CStringToDouble(str.ToCString(), str.Length(), &double_value)) {
    return Double::Handle().raw();
  }
  return New(double_value, space);
}

DoublePtr Double::NewCanonical(double value) {
  Thread* thread = Thread::Current();
  SafepointMutexLocker ml(
      thread->isolate_group()->constant_canonicalization_mutex());
  return NewCanonicalLocked(thread, value);
}

DoublePtr Double::NewCanonicalLocked(Thread* thread, double value) {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  const Class& cls =
      Class::Handle(zone, isolate->object_store()->double_class());
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Double& canonical_value =
      Double::Handle(zone, cls.LookupCanonicalDouble(zone, value));
  if (!canonical_value.IsNull()) {
    return canonical_value.raw();
  }
  canonical_value = Double::New(value, Heap::kOld);
  canonical_value.SetCanonical();
  // The value needs to be added to the constants list.
  cls.InsertCanonicalDouble(zone, canonical_value);
  return canonical_value.raw();
}

DoublePtr Double::NewCanonical(const String& str) {
  double double_value;
  if (!CStringToDouble(str.ToCString(), str.Length(), &double_value)) {
    return Double::Handle().raw();
  }
  return NewCanonical(double_value);
}

StringPtr Number::ToString(Heap::Space space) const {
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

void StringHasher::Add(const String& str, intptr_t begin_index, intptr_t len) {
  ASSERT(begin_index >= 0);
  ASSERT(len >= 0);
  ASSERT((begin_index + len) <= str.Length());
  if (len == 0) {
    return;
  }
  if (str.IsOneByteString()) {
    NoSafepointScope no_safepoint;
    Add(OneByteString::CharAddr(str, begin_index), len);
  } else if (str.IsExternalOneByteString()) {
    NoSafepointScope no_safepoint;
    Add(ExternalOneByteString::CharAddr(str, begin_index), len);
  } else if (str.IsTwoByteString()) {
    NoSafepointScope no_safepoint;
    Add(TwoByteString::CharAddr(str, begin_index), len);
  } else if (str.IsExternalOneByteString()) {
    NoSafepointScope no_safepoint;
    Add(ExternalTwoByteString::CharAddr(str, begin_index), len);
  } else {
    UNREACHABLE();
  }
}

intptr_t String::Hash(const String& str, intptr_t begin_index, intptr_t len) {
  StringHasher hasher;
  hasher.Add(str, begin_index, len);
  return hasher.Finalize();
}

intptr_t String::HashConcat(const String& str1, const String& str2) {
  StringHasher hasher;
  hasher.Add(str1, 0, str1.Length());
  hasher.Add(str2, 0, str2.Length());
  return hasher.Finalize();
}

intptr_t String::Hash(StringPtr raw) {
  StringHasher hasher;
  uword length = Smi::Value(raw->ptr()->length());
  if (raw->IsOneByteString() || raw->IsExternalOneByteString()) {
    const uint8_t* data;
    if (raw->IsOneByteString()) {
      data = static_cast<OneByteStringPtr>(raw)->ptr()->data();
    } else {
      ASSERT(raw->IsExternalOneByteString());
      ExternalOneByteStringPtr str = static_cast<ExternalOneByteStringPtr>(raw);
      data = str->ptr()->external_data_;
    }
    return String::Hash(data, length);
  } else {
    const uint16_t* data;
    if (raw->IsTwoByteString()) {
      data = static_cast<TwoByteStringPtr>(raw)->ptr()->data();
    } else {
      ASSERT(raw->IsExternalTwoByteString());
      ExternalTwoByteStringPtr str = static_cast<ExternalTwoByteStringPtr>(raw);
      data = str->ptr()->external_data_;
    }
    return String::Hash(data, length);
  }
}

intptr_t String::Hash(const char* characters, intptr_t len) {
  StringHasher hasher;
  hasher.Add(reinterpret_cast<const uint8_t*>(characters), len);
  return hasher.Finalize();
}

intptr_t String::Hash(const uint8_t* characters, intptr_t len) {
  StringHasher hasher;
  hasher.Add(characters, len);
  return hasher.Finalize();
}

intptr_t String::Hash(const uint16_t* characters, intptr_t len) {
  StringHasher hasher;
  hasher.Add(characters, len);
  return hasher.Finalize();
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

  for (intptr_t i = 0; i < len; i++) {
    if (CharAt(i) != str.CharAt(begin_index + i)) {
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
    if (this->CharAt(i) != LoadUnaligned(&utf16_array[i])) {
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

bool String::StartsWith(StringPtr str, StringPtr prefix) {
  if (prefix == String::null()) return false;

  const intptr_t length = String::LengthOf(str);
  const intptr_t prefix_length = String::LengthOf(prefix);
  if (prefix_length > length) return false;

  for (intptr_t i = 0; i < prefix_length; i++) {
    if (String::CharAt(str, i) != String::CharAt(prefix, i)) {
      return false;
    }
  }
  return true;
}

bool String::EndsWith(const String& other) const {
  if (other.IsNull()) {
    return false;
  }
  const intptr_t len = this->Length();
  const intptr_t other_len = other.Length();
  const intptr_t offset = len - other_len;

  if ((other_len == 0) || (other_len > len)) {
    return false;
  }
  for (int i = offset; i < len; i++) {
    if (this->CharAt(i) != other.CharAt(i - offset)) {
      return false;
    }
  }
  return true;
}

InstancePtr String::CanonicalizeLocked(Thread* thread) const {
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

StringPtr String::New(const char* cstr, Heap::Space space) {
  ASSERT(cstr != NULL);
  intptr_t array_len = strlen(cstr);
  const uint8_t* utf8_array = reinterpret_cast<const uint8_t*>(cstr);
  return String::FromUTF8(utf8_array, array_len, space);
}

StringPtr String::FromUTF8(const uint8_t* utf8_array,
                           intptr_t array_len,
                           Heap::Space space) {
  Utf8::Type type;
  intptr_t len = Utf8::CodeUnitCount(utf8_array, array_len, &type);
  if (type == Utf8::kLatin1) {
    const String& strobj = String::Handle(OneByteString::New(len, space));
    if (len > 0) {
      NoSafepointScope no_safepoint;
      if (!Utf8::DecodeToLatin1(utf8_array, array_len,
                                OneByteString::DataStart(strobj), len)) {
        Utf8::ReportInvalidByte(utf8_array, array_len, len);
        return String::null();
      }
    }
    return strobj.raw();
  }
  ASSERT((type == Utf8::kBMP) || (type == Utf8::kSupplementary));
  const String& strobj = String::Handle(TwoByteString::New(len, space));
  NoSafepointScope no_safepoint;
  if (!Utf8::DecodeToUTF16(utf8_array, array_len,
                           TwoByteString::DataStart(strobj), len)) {
    Utf8::ReportInvalidByte(utf8_array, array_len, len);
    return String::null();
  }
  return strobj.raw();
}

StringPtr String::FromLatin1(const uint8_t* latin1_array,
                             intptr_t array_len,
                             Heap::Space space) {
  return OneByteString::New(latin1_array, array_len, space);
}

StringPtr String::FromUTF16(const uint16_t* utf16_array,
                            intptr_t array_len,
                            Heap::Space space) {
  bool is_one_byte_string = true;
  for (intptr_t i = 0; i < array_len; ++i) {
    if (!Utf::IsLatin1(LoadUnaligned(&utf16_array[i]))) {
      is_one_byte_string = false;
      break;
    }
  }
  if (is_one_byte_string) {
    return OneByteString::New(utf16_array, array_len, space);
  }
  return TwoByteString::New(utf16_array, array_len, space);
}

StringPtr String::FromUTF32(const int32_t* utf32_array,
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

StringPtr String::New(const String& str, Heap::Space space) {
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

StringPtr String::NewExternal(const uint8_t* characters,
                              intptr_t len,
                              void* peer,
                              intptr_t external_allocation_size,
                              Dart_HandleFinalizer callback,
                              Heap::Space space) {
  return ExternalOneByteString::New(characters, len, peer,
                                    external_allocation_size, callback, space);
}

StringPtr String::NewExternal(const uint16_t* characters,
                              intptr_t len,
                              void* peer,
                              intptr_t external_allocation_size,
                              Dart_HandleFinalizer callback,
                              Heap::Space space) {
  return ExternalTwoByteString::New(characters, len, peer,
                                    external_allocation_size, callback, space);
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
      ASSERT(Utf::IsLatin1(LoadUnaligned(&utf16_array[i])));
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

StringPtr String::EscapeSpecialCharacters(const String& str) {
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

StringPtr String::DecodeIRI(const String& str) {
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

StringPtr String::NewFormatted(const char* format, ...) {
  va_list args;
  va_start(args, format);
  StringPtr result = NewFormattedV(format, args);
  NoSafepointScope no_safepoint;
  va_end(args);
  return result;
}

StringPtr String::NewFormatted(Heap::Space space, const char* format, ...) {
  va_list args;
  va_start(args, format);
  StringPtr result = NewFormattedV(format, args, space);
  NoSafepointScope no_safepoint;
  va_end(args);
  return result;
}

StringPtr String::NewFormattedV(const char* format,
                                va_list args,
                                Heap::Space space) {
  va_list args_copy;
  va_copy(args_copy, args);
  intptr_t len = Utils::VSNPrint(NULL, 0, format, args_copy);
  va_end(args_copy);

  Zone* zone = Thread::Current()->zone();
  char* buffer = zone->Alloc<char>(len + 1);
  Utils::VSNPrint(buffer, (len + 1), format, args);

  return String::New(buffer, space);
}

StringPtr String::Concat(const String& str1,
                         const String& str2,
                         Heap::Space space) {
  ASSERT(!str1.IsNull() && !str2.IsNull());
  intptr_t char_size = Utils::Maximum(str1.CharSize(), str2.CharSize());
  if (char_size == kTwoByteChar) {
    return TwoByteString::Concat(str1, str2, space);
  }
  return OneByteString::Concat(str1, str2, space);
}

StringPtr String::ConcatAll(const Array& strings, Heap::Space space) {
  return ConcatAllRange(strings, 0, strings.Length(), space);
}

StringPtr String::ConcatAllRange(const Array& strings,
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

StringPtr String::SubString(const String& str,
                            intptr_t begin_index,
                            Heap::Space space) {
  ASSERT(!str.IsNull());
  if (begin_index >= str.Length()) {
    return String::null();
  }
  return String::SubString(str, begin_index, (str.Length() - begin_index),
                           space);
}

StringPtr String::SubString(Thread* thread,
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
  const intptr_t len = Utf8::Length(*this);
  Zone* zone = Thread::Current()->zone();
  uint8_t* result = zone->Alloc<uint8_t>(len + 1);
  ToUTF8(result, len);
  result[len] = 0;
  return reinterpret_cast<const char*>(result);
}

char* String::ToMallocCString() const {
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

static FinalizablePersistentHandle* AddFinalizer(const Object& referent,
                                                 void* peer,
                                                 Dart_HandleFinalizer callback,
                                                 intptr_t external_size) {
  ASSERT(callback != NULL);
  return FinalizablePersistentHandle::New(Isolate::Current(), referent, peer,
                                          callback, external_size,
                                          /*auto_delete=*/true);
}

StringPtr String::Transform(int32_t (*mapping)(int32_t ch),
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

StringPtr String::ToUpperCase(const String& str, Heap::Space space) {
  // TODO(cshapiro): create a fast-path for OneByteString instances.
  return Transform(CaseMapping::ToUpper, str, space);
}

StringPtr String::ToLowerCase(const String& str, Heap::Space space) {
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
    for (intptr_t i = 0; i < length; i++) {
      int32_t ch = str.CharAt(start + i);
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

    if ((str2_pos < str2_len) && (ch == T2::CharAt(str2, str2_pos))) {
      str2_pos++;
      continue;
    }

    if (ch == Library::kPrivateKeySeparator) {
      // Consume a private key separator if str1 has it but str2 does not.
      while ((pos < len) && (T1::CharAt(str1, pos) != '.') &&
             (T1::CharAt(str1, pos) != '&')) {
        pos++;
      }
      // Resume matching characters.
      continue;
    }

    return false;
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

OneByteStringPtr OneByteString::EscapeSpecialCharacters(const String& str) {
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

OneByteStringPtr ExternalOneByteString::EscapeSpecialCharacters(
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

OneByteStringPtr OneByteString::New(intptr_t len, Heap::Space space) {
  ASSERT((Isolate::Current() == Dart::vm_isolate()) ||
         ((Isolate::Current()->object_store() != NULL) &&
          (Isolate::Current()->object_store()->one_byte_string_class() !=
           Class::null())));
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in OneByteString::New: invalid len %" Pd "\n", len);
  }
  {
    ObjectPtr raw = Object::Allocate(OneByteString::kClassId,
                                     OneByteString::InstanceSize(len), space);
    NoSafepointScope no_safepoint;
    OneByteStringPtr result = static_cast<OneByteStringPtr>(raw);
    result->ptr()->set_length(Smi::New(len));
#if !defined(HASH_IN_OBJECT_HEADER)
    result->ptr()->set_hash(Smi::New(0));
#endif
    return result;
  }
}

OneByteStringPtr OneByteString::New(const uint8_t* characters,
                                    intptr_t len,
                                    Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(len, space));
  if (len > 0) {
    NoSafepointScope no_safepoint;
    memmove(DataStart(result), characters, len);
  }
  return OneByteString::raw(result);
}

OneByteStringPtr OneByteString::New(const uint16_t* characters,
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

OneByteStringPtr OneByteString::New(const int32_t* characters,
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

OneByteStringPtr OneByteString::New(const String& str, Heap::Space space) {
  intptr_t len = str.Length();
  const String& result = String::Handle(OneByteString::New(len, space));
  String::Copy(result, 0, str, 0, len);
  return OneByteString::raw(result);
}

OneByteStringPtr OneByteString::New(const String& other_one_byte_string,
                                    intptr_t other_start_index,
                                    intptr_t other_len,
                                    Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(other_len, space));
  ASSERT(other_one_byte_string.IsOneByteString());
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(OneByteString::DataStart(result),
            OneByteString::CharAddr(other_one_byte_string, other_start_index),
            other_len);
  }
  return OneByteString::raw(result);
}

OneByteStringPtr OneByteString::New(const TypedData& other_typed_data,
                                    intptr_t other_start_index,
                                    intptr_t other_len,
                                    Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(other_len, space));
  ASSERT(other_typed_data.ElementSizeInBytes() == 1);
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(OneByteString::DataStart(result),
            other_typed_data.DataAddr(other_start_index), other_len);
  }
  return OneByteString::raw(result);
}

OneByteStringPtr OneByteString::New(const ExternalTypedData& other_typed_data,
                                    intptr_t other_start_index,
                                    intptr_t other_len,
                                    Heap::Space space) {
  const String& result = String::Handle(OneByteString::New(other_len, space));
  ASSERT(other_typed_data.ElementSizeInBytes() == 1);
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(OneByteString::DataStart(result),
            other_typed_data.DataAddr(other_start_index), other_len);
  }
  return OneByteString::raw(result);
}

OneByteStringPtr OneByteString::Concat(const String& str1,
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

OneByteStringPtr OneByteString::ConcatAll(const Array& strings,
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

OneByteStringPtr OneByteString::Transform(int32_t (*mapping)(int32_t ch),
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

OneByteStringPtr OneByteString::SubStringUnchecked(const String& str,
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
  OneByteStringPtr result = OneByteString::New(length, space);
  NoSafepointScope no_safepoint;
  if (length > 0) {
    uint8_t* dest = &result->ptr()->data()[0];
    const uint8_t* src = &raw_ptr(str)->data()[begin_index];
    memmove(dest, src, length);
  }
  return result;
}

TwoByteStringPtr TwoByteString::EscapeSpecialCharacters(const String& str) {
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

TwoByteStringPtr TwoByteString::New(intptr_t len, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->two_byte_string_class() !=
         nullptr);
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in TwoByteString::New: invalid len %" Pd "\n", len);
  }
  String& result = String::Handle();
  {
    ObjectPtr raw = Object::Allocate(TwoByteString::kClassId,
                                     TwoByteString::InstanceSize(len), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
  }
  return TwoByteString::raw(result);
}

TwoByteStringPtr TwoByteString::New(const uint16_t* utf16_array,
                                    intptr_t array_len,
                                    Heap::Space space) {
  ASSERT(array_len > 0);
  const String& result = String::Handle(TwoByteString::New(array_len, space));
  {
    NoSafepointScope no_safepoint;
    memmove(DataStart(result), utf16_array, (array_len * 2));
  }
  return TwoByteString::raw(result);
}

TwoByteStringPtr TwoByteString::New(intptr_t utf16_len,
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

TwoByteStringPtr TwoByteString::New(const String& str, Heap::Space space) {
  intptr_t len = str.Length();
  const String& result = String::Handle(TwoByteString::New(len, space));
  String::Copy(result, 0, str, 0, len);
  return TwoByteString::raw(result);
}

TwoByteStringPtr TwoByteString::New(const TypedData& other_typed_data,
                                    intptr_t other_start_index,
                                    intptr_t other_len,
                                    Heap::Space space) {
  const String& result = String::Handle(TwoByteString::New(other_len, space));
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(TwoByteString::DataStart(result),
            other_typed_data.DataAddr(other_start_index),
            other_len * sizeof(uint16_t));
  }
  return TwoByteString::raw(result);
}

TwoByteStringPtr TwoByteString::New(const ExternalTypedData& other_typed_data,
                                    intptr_t other_start_index,
                                    intptr_t other_len,
                                    Heap::Space space) {
  const String& result = String::Handle(TwoByteString::New(other_len, space));
  if (other_len > 0) {
    NoSafepointScope no_safepoint;
    memmove(TwoByteString::DataStart(result),
            other_typed_data.DataAddr(other_start_index),
            other_len * sizeof(uint16_t));
  }
  return TwoByteString::raw(result);
}

TwoByteStringPtr TwoByteString::Concat(const String& str1,
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

TwoByteStringPtr TwoByteString::ConcatAll(const Array& strings,
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

TwoByteStringPtr TwoByteString::Transform(int32_t (*mapping)(int32_t ch),
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

ExternalOneByteStringPtr ExternalOneByteString::New(
    const uint8_t* data,
    intptr_t len,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback,
    Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->external_one_byte_string_class() !=
         Class::null());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ExternalOneByteString::New: invalid len %" Pd "\n",
           len);
  }
  String& result = String::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(ExternalOneByteString::kClassId,
                         ExternalOneByteString::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
    SetExternalData(result, data, peer);
  }
  AddFinalizer(result, peer, callback, external_allocation_size);
  return ExternalOneByteString::raw(result);
}

ExternalTwoByteStringPtr ExternalTwoByteString::New(
    const uint16_t* data,
    intptr_t len,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback,
    Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->external_two_byte_string_class() !=
         Class::null());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ExternalTwoByteString::New: invalid len %" Pd "\n",
           len);
  }
  String& result = String::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(ExternalTwoByteString::kClassId,
                         ExternalTwoByteString::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
    SetExternalData(result, data, peer);
  }
  AddFinalizer(result, peer, callback, external_allocation_size);
  return ExternalTwoByteString::raw(result);
}

BoolPtr Bool::New(bool value) {
  ASSERT(Isolate::Current()->object_store()->bool_class() != Class::null());
  Bool& result = Bool::Handle();
  {
    // Since the two boolean instances are singletons we allocate them straight
    // in the old generation.
    ObjectPtr raw =
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

uint32_t Array::CanonicalizeHash() const {
  intptr_t len = Length();
  if (len == 0) {
    return 1;
  }
  Thread* thread = Thread::Current();
  uint32_t hash = thread->heap()->GetCanonicalHash(raw());
  if (hash != 0) {
    return hash;
  }
  hash = len;
  Instance& member = Instance::Handle(GetTypeArguments());
  hash = CombineHashes(hash, member.CanonicalizeHash());
  for (intptr_t i = 0; i < len; i++) {
    member ^= At(i);
    hash = CombineHashes(hash, member.CanonicalizeHash());
  }
  hash = FinalizeHash(hash, kHashBits);
  thread->heap()->SetCanonicalHash(raw(), hash);
  return hash;
}

ArrayPtr Array::New(intptr_t len, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->array_class() != Class::null());
  ArrayPtr result = New(kClassId, len, space);
  if (UseCardMarkingForAllocation(len)) {
    ASSERT(result->IsOldObject());
    result->ptr()->SetCardRememberedBitUnsynchronized();
  }
  return result;
}

ArrayPtr Array::New(intptr_t len,
                    const AbstractType& element_type,
                    Heap::Space space) {
  const Array& result = Array::Handle(Array::New(len, space));
  if (!element_type.IsDynamicType()) {
    TypeArguments& type_args = TypeArguments::Handle(TypeArguments::New(1));
    type_args.SetTypeAt(0, element_type);
    type_args = type_args.Canonicalize(Thread::Current(), nullptr);
    result.SetTypeArguments(type_args);
  }
  return result.raw();
}

ArrayPtr Array::New(intptr_t class_id, intptr_t len, Heap::Space space) {
  if (!IsValidLength(len)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Array::New: invalid len %" Pd "\n", len);
  }
  {
    ArrayPtr raw = static_cast<ArrayPtr>(
        Object::Allocate(class_id, Array::InstanceSize(len), space));
    NoSafepointScope no_safepoint;
    raw->ptr()->set_length(Smi::New(len));
    return raw;
  }
}

ArrayPtr Array::Slice(intptr_t start,
                      intptr_t count,
                      bool with_type_argument) const {
  // TODO(vegorov) introduce an array allocation method that fills newly
  // allocated array with values from the given source array instead of
  // null-initializing all elements.
  Array& dest = Array::Handle(Array::New(count));
  dest.StoreArrayPointers(dest.ObjectAddr(0), ObjectAddr(start), count);

  if (with_type_argument) {
    dest.SetTypeArguments(TypeArguments::Handle(GetTypeArguments()));
  }

  return dest.raw();
}

void Array::MakeImmutable() const {
  if (IsImmutable()) return;
  ASSERT(!IsCanonical());
  raw_ptr()->SetClassId(kImmutableArrayCid);
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

ArrayPtr Array::Grow(const Array& source,
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

void Array::Truncate(intptr_t new_len) const {
  if (IsNull()) {
    return;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Array& array = Array::Handle(zone, this->raw());

  intptr_t old_len = array.Length();
  ASSERT(new_len <= old_len);
  if (old_len == new_len) {
    return;
  }
  intptr_t old_size = Array::InstanceSize(old_len);
  intptr_t new_size = Array::InstanceSize(new_len);

  NoSafepointScope no_safepoint;

  // If there is any left over space fill it with either an Array object or
  // just a plain object (depending on the amount of left over space) so
  // that it can be traversed over successfully during garbage collection.
  Object::MakeUnusedSpaceTraversable(array, old_size, new_size);

  // Update the size in the header field and length of the array object.
  // These release operations are balanced by acquire operations in the
  // concurrent sweeper.
  uword old_tags = array.raw_ptr()->tags_;
  uword new_tags;
  ASSERT(kArrayCid == ObjectLayout::ClassIdTag::decode(old_tags));
  do {
    new_tags = ObjectLayout::SizeTag::update(new_size, old_tags);
  } while (!array.raw_ptr()->tags_.compare_exchange_weak(
      old_tags, new_tags, std::memory_order_release));

  // Between the CAS of the header above and the SetLength below, the array is
  // temporarily in an inconsistent state. The header is considered the
  // overriding source of object size by ObjectLayout::Size, but the ASSERTs in
  // ObjectLayout::HeapSizeFromClass must handle this special case.
  array.SetLengthRelease(new_len);
}

ArrayPtr Array::MakeFixedLength(const GrowableObjectArray& growable_array,
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
  const Array& array = Array::Handle(zone, growable_array.data());
  ASSERT(array.IsArray());
  array.SetTypeArguments(type_arguments);

  // Null the GrowableObjectArray, we are removing its backing array.
  growable_array.SetLength(0);
  growable_array.SetData(Object::empty_array());

  // Truncate the old backing array and return it.
  array.Truncate(used_len);
  return array.raw();
}

void Array::CanonicalizeFieldsLocked(Thread* thread) const {
  intptr_t len = Length();
  if (len > 0) {
    Zone* zone = thread->zone();
    Instance& obj = Instance::Handle(zone);
    for (intptr_t i = 0; i < len; i++) {
      obj ^= At(i);
      obj = obj.CanonicalizeLocked(thread);
      this->SetAt(i, obj);
    }
  }
}

ImmutableArrayPtr ImmutableArray::New(intptr_t len, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->immutable_array_class() !=
         Class::null());
  return static_cast<ImmutableArrayPtr>(Array::New(kClassId, len, space));
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
  raw_ptr()->set_data(new_contents.raw());
}

ObjectPtr GrowableObjectArray::RemoveLast() const {
  ASSERT(!IsNull());
  ASSERT(Length() > 0);
  intptr_t index = Length() - 1;
  const Array& contents = Array::Handle(data());
  const PassiveObject& obj = PassiveObject::Handle(contents.At(index));
  contents.SetAt(index, Object::null_object());
  SetLength(index);
  return obj.raw();
}

GrowableObjectArrayPtr GrowableObjectArray::New(intptr_t capacity,
                                                Heap::Space space) {
  ArrayPtr raw_data = (capacity == 0) ? Object::empty_array().raw()
                                      : Array::New(capacity, space);
  const Array& data = Array::Handle(raw_data);
  return New(data, space);
}

GrowableObjectArrayPtr GrowableObjectArray::New(const Array& array,
                                                Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->growable_object_array_class() !=
         Class::null());
  GrowableObjectArray& result = GrowableObjectArray::Handle();
  {
    ObjectPtr raw =
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

LinkedHashMapPtr LinkedHashMap::NewDefault(Heap::Space space) {
  const Array& data = Array::Handle(Array::New(kInitialIndexSize, space));
  const TypedData& index = TypedData::Handle(
      TypedData::New(kTypedDataUint32ArrayCid, kInitialIndexSize, space));
  // On 32-bit, the top bits are wasted to avoid Mint allocation.
  static const intptr_t kAvailableBits = (kSmiBits >= 32) ? 32 : kSmiBits;
  static const intptr_t kInitialHashMask =
      (1 << (kAvailableBits - kInitialIndexBits)) - 1;
  return LinkedHashMap::New(data, index, kInitialHashMask, 0, 0, space);
}

LinkedHashMapPtr LinkedHashMap::New(const Array& data,
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

LinkedHashMapPtr LinkedHashMap::NewUninitialized(Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->linked_hash_map_class() !=
         Class::null());
  LinkedHashMap& result = LinkedHashMap::Handle();
  {
    ObjectPtr raw = Object::Allocate(LinkedHashMap::kClassId,
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

const char* FutureOr::ToCString() const {
  // FutureOr is an abstract class.
  UNREACHABLE();
}

Float32x4Ptr Float32x4::New(float v0,
                            float v1,
                            float v2,
                            float v3,
                            Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float32x4_class() !=
         Class::null());
  Float32x4& result = Float32x4::Handle();
  {
    ObjectPtr raw =
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

Float32x4Ptr Float32x4::New(simd128_value_t value, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float32x4_class() !=
         Class::null());
  Float32x4& result = Float32x4::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(Float32x4::kClassId, Float32x4::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(value);
  return result.raw();
}

simd128_value_t Float32x4::value() const {
  return LoadUnaligned(
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

Int32x4Ptr Int32x4::New(int32_t v0,
                        int32_t v1,
                        int32_t v2,
                        int32_t v3,
                        Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->int32x4_class() != Class::null());
  Int32x4& result = Int32x4::Handle();
  {
    ObjectPtr raw =
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

Int32x4Ptr Int32x4::New(simd128_value_t value, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->int32x4_class() != Class::null());
  Int32x4& result = Int32x4::Handle();
  {
    ObjectPtr raw =
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
  return LoadUnaligned(
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

Float64x2Ptr Float64x2::New(double value0, double value1, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float64x2_class() !=
         Class::null());
  Float64x2& result = Float64x2::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(Float64x2::kClassId, Float64x2::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_x(value0);
  result.set_y(value1);
  return result.raw();
}

Float64x2Ptr Float64x2::New(simd128_value_t value, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float64x2_class() !=
         Class::null());
  Float64x2& result = Float64x2::Handle();
  {
    ObjectPtr raw =
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

const intptr_t
    TypedDataBase::element_size_table[TypedDataBase::kNumElementSizes] = {
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

uint32_t TypedData::CanonicalizeHash() const {
  const intptr_t len = this->LengthInBytes();
  if (len == 0) {
    return 1;
  }
  uint32_t hash = len;
  for (intptr_t i = 0; i < len; i++) {
    hash = CombineHashes(len, GetUint8(i));
  }
  return FinalizeHash(hash, kHashBits);
}

TypedDataPtr TypedData::New(intptr_t class_id,
                            intptr_t len,
                            Heap::Space space) {
  if (len < 0 || len > TypedData::MaxElements(class_id)) {
    FATAL1("Fatal error in TypedData::New: invalid len %" Pd "\n", len);
  }
  TypedData& result = TypedData::Handle();
  {
    const intptr_t length_in_bytes = len * ElementSizeInBytes(class_id);
    ObjectPtr raw = Object::Allocate(
        class_id, TypedData::InstanceSize(length_in_bytes), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.RecomputeDataField();
  }
  return result.raw();
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
    Dart_HandleFinalizer callback,
    intptr_t external_size) const {
  return dart::AddFinalizer(*this, peer, callback, external_size);
}

ExternalTypedDataPtr ExternalTypedData::New(
    intptr_t class_id,
    uint8_t* data,
    intptr_t len,
    Heap::Space space,
    bool perform_eager_msan_initialization_check) {
  if (len < 0 || len > ExternalTypedData::MaxElements(class_id)) {
    FATAL1("Fatal error in ExternalTypedData::New: invalid len %" Pd "\n", len);
  }

  if (perform_eager_msan_initialization_check) {
    // Once the TypedData is created, Dart might read this memory. Check for
    // intialization at construction to make it easier to track the source.
    MSAN_CHECK_INITIALIZED(data, len);
  }

  ExternalTypedData& result = ExternalTypedData::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(class_id, ExternalTypedData::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetData(data);
  }
  return result.raw();
}

ExternalTypedDataPtr ExternalTypedData::NewFinalizeWithFree(uint8_t* data,
                                                            intptr_t len) {
  ExternalTypedData& result = ExternalTypedData::Handle(ExternalTypedData::New(
      kExternalTypedDataUint8ArrayCid, data, len, Heap::kOld));
  result.AddFinalizer(
      data, [](void* isolate_callback_data, void* data) { free(data); }, len);
  return result.raw();
}

TypedDataViewPtr TypedDataView::New(intptr_t class_id, Heap::Space space) {
  auto& result = TypedDataView::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(class_id, TypedDataView::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.Clear();
  }
  return result.raw();
}

TypedDataViewPtr TypedDataView::New(intptr_t class_id,
                                    const TypedDataBase& typed_data,
                                    intptr_t offset_in_bytes,
                                    intptr_t length,
                                    Heap::Space space) {
  auto& result = TypedDataView::Handle(TypedDataView::New(class_id, space));
  result.InitializeWith(typed_data, offset_in_bytes, length);
  return result.raw();
}

const char* TypedDataBase::ToCString() const {
  // There are no instances of RawTypedDataBase.
  UNREACHABLE();
  return nullptr;
}

const char* TypedDataView::ToCString() const {
  auto zone = Thread::Current()->zone();
  return OS::SCreate(zone, "TypedDataView(cid: %" Pd ")", GetClassId());
}

const char* ExternalTypedData::ToCString() const {
  return "ExternalTypedData";
}

PointerPtr Pointer::New(const AbstractType& type_arg,
                        uword native_address,
                        Heap::Space space) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  TypeArguments& type_args = TypeArguments::Handle(zone);
  type_args = TypeArguments::New(1);
  type_args.SetTypeAt(Pointer::kNativeTypeArgPos, type_arg);
  type_args = type_args.Canonicalize(thread, nullptr);

  const Class& cls =
      Class::Handle(Isolate::Current()->class_table()->At(kFfiPointerCid));
  cls.EnsureIsAllocateFinalized(Thread::Current());

  Pointer& result = Pointer::Handle(zone);
  result ^= Object::Allocate(kFfiPointerCid, Pointer::InstanceSize(), space);
  result.SetTypeArguments(type_args);
  result.SetNativeAddress(native_address);

  return result.raw();
}

const char* Pointer::ToCString() const {
  TypeArguments& type_args = TypeArguments::Handle(GetTypeArguments());
  String& type_args_name = String::Handle(type_args.UserVisibleName());
  return OS::SCreate(Thread::Current()->zone(), "Pointer%s: address=0x%" Px,
                     type_args_name.ToCString(), NativeAddress());
}

DynamicLibraryPtr DynamicLibrary::New(void* handle, Heap::Space space) {
  DynamicLibrary& result = DynamicLibrary::Handle();
  result ^= Object::Allocate(kFfiDynamicLibraryCid,
                             DynamicLibrary::InstanceSize(), space);
  NoSafepointScope no_safepoint;
  result.SetHandle(handle);
  return result.raw();
}

bool Pointer::IsPointer(const Instance& obj) {
  return IsFfiPointerClassId(obj.raw()->GetClassId());
}

bool Instance::IsPointer() const {
  return Pointer::IsPointer(*this);
}

const char* DynamicLibrary::ToCString() const {
  return OS::SCreate(Thread::Current()->zone(), "DynamicLibrary: handle=0x%" Px,
                     reinterpret_cast<uintptr_t>(GetHandle()));
}

CapabilityPtr Capability::New(uint64_t id, Heap::Space space) {
  Capability& result = Capability::Handle();
  {
    ObjectPtr raw = Object::Allocate(Capability::kClassId,
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

ReceivePortPtr ReceivePort::New(Dart_Port id,
                                const String& debug_name,
                                bool is_control_port,
                                Heap::Space space) {
  ASSERT(id != ILLEGAL_PORT);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const SendPort& send_port =
      SendPort::Handle(zone, SendPort::New(id, thread->isolate()->origin_id()));
#if !defined(PRODUCT)
  const StackTrace& allocation_location_ =
      HasStack() ? GetCurrentStackTrace(0) : StackTrace::Handle();
#endif  // !defined(PRODUCT)

  ReceivePort& result = ReceivePort::Handle(zone);
  {
    ObjectPtr raw = Object::Allocate(ReceivePort::kClassId,
                                     ReceivePort::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.raw_ptr()->set_send_port(send_port.raw());
#if !defined(PRODUCT)
    result.raw_ptr()->set_debug_name(debug_name.raw());
    result.raw_ptr()->set_allocation_location(allocation_location_.raw());
#endif  // !defined(PRODUCT)
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

SendPortPtr SendPort::New(Dart_Port id, Heap::Space space) {
  return New(id, Isolate::Current()->origin_id(), space);
}

SendPortPtr SendPort::New(Dart_Port id,
                          Dart_Port origin_id,
                          Heap::Space space) {
  ASSERT(id != ILLEGAL_PORT);
  SendPort& result = SendPort::Handle();
  {
    ObjectPtr raw =
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

static void TransferableTypedDataFinalizer(void* isolate_callback_data,
                                           void* peer) {
  delete (reinterpret_cast<TransferableTypedDataPeer*>(peer));
}

TransferableTypedDataPtr TransferableTypedData::New(uint8_t* data,
                                                    intptr_t length,
                                                    Heap::Space space) {
  TransferableTypedDataPeer* peer = new TransferableTypedDataPeer(data, length);

  Thread* thread = Thread::Current();
  TransferableTypedData& result = TransferableTypedData::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(TransferableTypedData::kClassId,
                         TransferableTypedData::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    thread->heap()->SetPeer(raw, peer);
    result ^= raw;
  }
  // Set up finalizer so it frees allocated memory if handle is
  // garbage-collected.
  peer->set_handle(FinalizablePersistentHandle::New(
      thread->isolate(), result, peer, &TransferableTypedDataFinalizer, length,
      /*auto_delete=*/true));

  return result.raw();
}

const char* TransferableTypedData::ToCString() const {
  return "TransferableTypedData";
}

bool Closure::CanonicalizeEquals(const Instance& other) const {
  if (!other.IsClosure()) return false;

  const Closure& other_closure = Closure::Cast(other);
  return (instantiator_type_arguments() ==
          other_closure.instantiator_type_arguments()) &&
         (function_type_arguments() ==
          other_closure.function_type_arguments()) &&
         (delayed_type_arguments() == other_closure.delayed_type_arguments()) &&
         (function() == other_closure.function()) &&
         (context() == other_closure.context());
}

void Closure::CanonicalizeFieldsLocked(Thread* thread) const {
  TypeArguments& type_args = TypeArguments::Handle();
  type_args = instantiator_type_arguments();
  if (!type_args.IsNull()) {
    type_args = type_args.Canonicalize(thread, nullptr);
    set_instantiator_type_arguments(type_args);
  }
  type_args = function_type_arguments();
  if (!type_args.IsNull()) {
    type_args = type_args.Canonicalize(thread, nullptr);
    set_function_type_arguments(type_args);
  }
  type_args = delayed_type_arguments();
  if (!type_args.IsNull()) {
    type_args = type_args.Canonicalize(thread, nullptr);
    set_delayed_type_arguments(type_args);
  }
  // Ignore function, context, hash.
}

intptr_t Closure::NumTypeParameters(Thread* thread) const {
  // Only check for empty here, as the null TAV is used to mean that the
  // closed-over delayed type parameters were all of dynamic type.
  if (delayed_type_arguments() != Object::empty_type_arguments().raw()) {
    return 0;
  } else {
    const auto& closure_function = Function::Handle(thread->zone(), function());
    return closure_function.NumTypeParameters(thread);
  }
}

const char* Closure::ToCString() const {
  auto const thread = Thread::Current();
  auto const zone = thread->zone();
  ZoneTextBuffer buffer(zone);
  buffer.AddString("Closure: ");
  const Function& fun = Function::Handle(zone, function());
  const Function& sig_fun =
      Function::Handle(zone, GetInstantiatedSignature(zone));
  sig_fun.PrintSignature(NameVisibility::kUserVisibleName, &buffer);
  if (fun.IsImplicitClosureFunction()) {
    buffer.Printf(" from %s", fun.ToCString());
  }
  return buffer.buffer();
}

int64_t Closure::ComputeHash() const {
  Thread* thread = Thread::Current();
  DEBUG_ASSERT(thread->TopErrorHandlerIsExitFrame());
  Zone* zone = thread->zone();
  const Function& func = Function::Handle(zone, function());
  uint32_t result = 0;
  if (func.IsImplicitInstanceClosureFunction()) {
    // Implicit instance closures are not unique, so combine function's hash
    // code with identityHashCode of cached receiver.
    result = static_cast<uint32_t>(func.ComputeClosureHash());
    const Context& context = Context::Handle(zone, this->context());
    const Instance& receiver =
        Instance::Handle(zone, Instance::RawCast(context.At(0)));
    const Object& receiverHash =
        Object::Handle(zone, receiver.IdentityHashCode());
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

ClosurePtr Closure::New(const TypeArguments& instantiator_type_arguments,
                        const TypeArguments& function_type_arguments,
                        const Function& function,
                        const Context& context,
                        Heap::Space space) {
  return Closure::New(instantiator_type_arguments, function_type_arguments,
                      function.IsGeneric() ? Object::empty_type_arguments()
                                           : Object::null_type_arguments(),
                      function, context, space);
}

ClosurePtr Closure::New(const TypeArguments& instantiator_type_arguments,
                        const TypeArguments& function_type_arguments,
                        const TypeArguments& delayed_type_arguments,
                        const Function& function,
                        const Context& context,
                        Heap::Space space) {
  Closure& result = Closure::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(Closure::kClassId, Closure::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.raw_ptr()->set_instantiator_type_arguments(
        instantiator_type_arguments.raw());
    result.raw_ptr()->set_function_type_arguments(
        function_type_arguments.raw());
    result.raw_ptr()->set_delayed_type_arguments(delayed_type_arguments.raw());
    result.raw_ptr()->set_function(function.raw());
    result.raw_ptr()->set_context(context.raw());
  }
  return result.raw();
}

ClosurePtr Closure::New() {
  ObjectPtr raw =
      Object::Allocate(Closure::kClassId, Closure::InstanceSize(), Heap::kOld);
  return static_cast<ClosurePtr>(raw);
}

FunctionPtr Closure::GetInstantiatedSignature(Zone* zone) const {
  Function& sig_fun = Function::Handle(zone, function());
  TypeArguments& fn_type_args =
      TypeArguments::Handle(zone, function_type_arguments());
  const TypeArguments& delayed_type_args =
      TypeArguments::Handle(zone, delayed_type_arguments());
  const TypeArguments& inst_type_args =
      TypeArguments::Handle(zone, instantiator_type_arguments());

  // We detect the case of a partial tearoff type application and substitute the
  // type arguments for the type parameters of the function.
  intptr_t num_free_params;
  if (delayed_type_args.raw() != Object::empty_type_arguments().raw()) {
    num_free_params = kCurrentAndEnclosingFree;
    fn_type_args = delayed_type_args.Prepend(
        zone, fn_type_args, sig_fun.NumParentTypeParameters(),
        sig_fun.NumTypeParameters() + sig_fun.NumParentTypeParameters());
  } else {
    num_free_params = kAllFree;
  }
  if (num_free_params == kCurrentAndEnclosingFree ||
      !sig_fun.HasInstantiatedSignature(kAny)) {
    return sig_fun.InstantiateSignatureFrom(inst_type_args, fn_type_args,
                                            num_free_params, Heap::kOld);
  }
  return sig_fun.raw();
}

bool StackTrace::skip_sync_start_in_parent_stack() const {
  return raw_ptr()->skip_sync_start_in_parent_stack;
}

void StackTrace::set_skip_sync_start_in_parent_stack(bool value) const {
  StoreNonPointer(&raw_ptr()->skip_sync_start_in_parent_stack, value);
}

intptr_t StackTrace::Length() const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array());
  return code_array.Length();
}

ObjectPtr StackTrace::CodeAtFrame(intptr_t frame_index) const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array());
  return code_array.At(frame_index);
}

void StackTrace::SetCodeAtFrame(intptr_t frame_index,
                                const Object& code) const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array());
  code_array.SetAt(frame_index, code);
}

SmiPtr StackTrace::PcOffsetAtFrame(intptr_t frame_index) const {
  const Array& pc_offset_array = Array::Handle(raw_ptr()->pc_offset_array());
  return static_cast<SmiPtr>(pc_offset_array.At(frame_index));
}

void StackTrace::SetPcOffsetAtFrame(intptr_t frame_index,
                                    const Smi& pc_offset) const {
  const Array& pc_offset_array = Array::Handle(raw_ptr()->pc_offset_array());
  pc_offset_array.SetAt(frame_index, pc_offset);
}

void StackTrace::set_async_link(const StackTrace& async_link) const {
  raw_ptr()->set_async_link(async_link.raw());
}

void StackTrace::set_code_array(const Array& code_array) const {
  raw_ptr()->set_code_array(code_array.raw());
}

void StackTrace::set_pc_offset_array(const Array& pc_offset_array) const {
  raw_ptr()->set_pc_offset_array(pc_offset_array.raw());
}

void StackTrace::set_expand_inlined(bool value) const {
  StoreNonPointer(&raw_ptr()->expand_inlined_, value);
}

bool StackTrace::expand_inlined() const {
  return raw_ptr()->expand_inlined_;
}

StackTracePtr StackTrace::New(const Array& code_array,
                              const Array& pc_offset_array,
                              Heap::Space space) {
  StackTrace& result = StackTrace::Handle();
  {
    ObjectPtr raw = Object::Allocate(StackTrace::kClassId,
                                     StackTrace::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_code_array(code_array);
  result.set_pc_offset_array(pc_offset_array);
  result.set_expand_inlined(true);  // default.
  result.set_skip_sync_start_in_parent_stack(false);
  return result.raw();
}

StackTracePtr StackTrace::New(const Array& code_array,
                              const Array& pc_offset_array,
                              const StackTrace& async_link,
                              bool skip_sync_start_in_parent_stack,
                              Heap::Space space) {
  StackTrace& result = StackTrace::Handle();
  {
    ObjectPtr raw = Object::Allocate(StackTrace::kClassId,
                                     StackTrace::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_async_link(async_link);
  result.set_code_array(code_array);
  result.set_pc_offset_array(pc_offset_array);
  result.set_expand_inlined(true);  // default.
  result.set_skip_sync_start_in_parent_stack(skip_sync_start_in_parent_stack);
  return result.raw();
}

#if defined(DART_PRECOMPILED_RUNTIME)
// Prints the best representation(s) for the call address.
static void PrintNonSymbolicStackFrameBody(BaseTextBuffer* buffer,
                                           uword call_addr,
                                           uword isolate_instructions,
                                           uword vm_instructions) {
  const Image vm_image(reinterpret_cast<const void*>(vm_instructions));
  const Image isolate_image(
      reinterpret_cast<const void*>(isolate_instructions));

  if (isolate_image.contains(call_addr)) {
    auto const symbol_name = kIsolateSnapshotInstructionsAsmSymbol;
    auto const offset = call_addr - isolate_instructions;
    // Only print the relocated address of the call when we know the saved
    // debugging information (if any) will have the same relocated address.
    if (isolate_image.compiled_to_elf()) {
      const uword relocated_section_start =
          isolate_image.instructions_relocated_address();
      buffer->Printf(" virt %" Pp "", relocated_section_start + offset);
    }
    buffer->Printf(" %s+0x%" Px "", symbol_name, offset);
  } else if (vm_image.contains(call_addr)) {
    auto const offset = call_addr - vm_instructions;
    // We currently don't print 'virt' entries for vm addresses, even if
    // they were compiled to ELF, as we should never encounter these in
    // non-symbolic stack traces (since stub addresses are stripped).
    //
    // In case they leak due to code issues elsewhere, we still print them as
    // <vm symbol>+<offset>, just to distinguish from other cases.
    buffer->Printf(" %s+0x%" Px "", kVmSnapshotInstructionsAsmSymbol, offset);
  } else {
    // This case should never happen, since these are not addresses within the
    // VM or app isolate instructions sections, so make it easy to notice.
    buffer->Printf(" <invalid Dart instruction address>");
  }
  buffer->Printf("\n");
}
#endif

static void PrintSymbolicStackFrameIndex(BaseTextBuffer* buffer,
                                         intptr_t frame_index) {
  buffer->Printf("#%-6" Pd "", frame_index);
}

static void PrintSymbolicStackFrameBody(BaseTextBuffer* buffer,
                                        const char* function_name,
                                        const char* url,
                                        intptr_t line = -1,
                                        intptr_t column = -1) {
  buffer->Printf(" %s (%s", function_name, url);
  if (line >= 0) {
    buffer->Printf(":%" Pd "", line);
    if (column >= 0) {
      buffer->Printf(":%" Pd "", column);
    }
  }
  buffer->Printf(")\n");
}

static void PrintSymbolicStackFrame(Zone* zone,
                                    BaseTextBuffer* buffer,
                                    const Function& function,
                                    TokenPosition token_pos_or_line,
                                    intptr_t frame_index,
                                    bool is_line = false) {
  ASSERT(!function.IsNull());
  const auto& script = Script::Handle(zone, function.script());
  const char* function_name = function.QualifiedUserVisibleNameCString();
  const char* url = script.IsNull()
                        ? "Kernel"
                        : String::Handle(zone, script.url()).ToCString();

  // If the URI starts with "data:application/dart;" this is a URI encoded
  // script so we shouldn't print the entire URI because it could be very long.
  if (strstr(url, "data:application/dart;") == url) {
    url = "<data:application/dart>";
  }

  intptr_t line = -1;
  intptr_t column = -1;
  if (is_line) {
    ASSERT(token_pos_or_line.IsNoSource() || token_pos_or_line.IsReal());
    if (token_pos_or_line.IsReal()) {
      line = token_pos_or_line.Pos();
    }
  } else {
    ASSERT(!script.IsNull());
    script.GetTokenLocation(token_pos_or_line, &line, &column);
  }
  PrintSymbolicStackFrameIndex(buffer, frame_index);
  PrintSymbolicStackFrameBody(buffer, function_name, url, line, column);
}

const char* StackTrace::ToCString() const {
  auto const T = Thread::Current();
  auto const zone = T->zone();
  auto& stack_trace = StackTrace::Handle(zone, this->raw());
  auto& function = Function::Handle(zone);
  auto& code_object = Object::Handle(zone);
  auto& code = Code::Handle(zone);

  NoSafepointScope no_allocation;
  GrowableArray<const Function*> inlined_functions;
  GrowableArray<TokenPosition> inlined_token_positions;
  ZoneTextBuffer buffer(zone, 1024);

#if defined(DART_PRECOMPILED_RUNTIME)
  auto const isolate_instructions = reinterpret_cast<uword>(
      T->isolate_group()->source()->snapshot_instructions);
  auto const vm_instructions = reinterpret_cast<uword>(
      Dart::vm_isolate()->group()->source()->snapshot_instructions);
  if (FLAG_dwarf_stack_traces_mode) {
    const Image isolate_instructions_image(
        reinterpret_cast<const void*>(isolate_instructions));
    const Image vm_instructions_image(
        reinterpret_cast<const void*>(vm_instructions));
    auto const isolate_relocated_address =
        isolate_instructions_image.instructions_relocated_address();
    auto const vm_relocated_address =
        vm_instructions_image.instructions_relocated_address();
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
    if (auto const build_id = isolate_instructions_image.build_id()) {
      const intptr_t length = isolate_instructions_image.build_id_length();
      buffer.Printf("build_id: '");
      for (intptr_t i = 0; i < length; i++) {
        buffer.Printf("%2.2x", build_id[i]);
      }
      buffer.Printf("'\n");
    }
    // Print the dso_base of the VM and isolate_instructions. We print both here
    // as the VM and isolate may be loaded from different snapshot images.
    buffer.Printf("isolate_dso_base: %" Px "",
                  isolate_instructions - isolate_relocated_address);
    buffer.Printf(", vm_dso_base: %" Px "\n",
                  vm_instructions - vm_relocated_address);
    buffer.Printf("isolate_instructions: %" Px "", isolate_instructions);
    buffer.Printf(", vm_instructions: %" Px "\n", vm_instructions);
  }
#endif

  // Iterate through the stack frames and create C string description
  // for each frame.
  intptr_t frame_index = 0;
  uint32_t frame_skip = 0;
  // If we're already in a gap, don't print multiple gap markers.
  bool in_gap = false;
  do {
    for (intptr_t i = frame_skip; i < stack_trace.Length(); i++) {
      code_object = stack_trace.CodeAtFrame(i);
      if (code_object.IsNull()) {
        // Check for a null function, which indicates a gap in a StackOverflow
        // or OutOfMemory trace.
        if ((i < (stack_trace.Length() - 1)) &&
            (stack_trace.CodeAtFrame(i + 1) != Code::null())) {
          buffer.AddString("...\n...\n");
          ASSERT(stack_trace.PcOffsetAtFrame(i) != Smi::null());
          // To account for gap frames.
          frame_index += Smi::Value(stack_trace.PcOffsetAtFrame(i));
        }
        continue;
      }

      if (code_object.raw() == StubCode::AsynchronousGapMarker().raw()) {
        if (!in_gap) {
          buffer.AddString("<asynchronous suspension>\n");
        }
        in_gap = true;
        continue;
      }

      intptr_t pc_offset = Smi::Value(stack_trace.PcOffsetAtFrame(i));
      ASSERT(code_object.IsCode());
      code ^= code_object.raw();
      ASSERT(code.IsFunctionCode());
      function = code.function();
      const uword pc = code.PayloadStart() + pc_offset;

      // If the function is not to be shown, skip.
      if (!FLAG_show_invisible_frames && !function.IsNull() &&
          !function.is_visible()) {
        continue;
      }

      // A visible frame ends any gap we might be in.
      in_gap = false;

#if defined(DART_PRECOMPILED_RUNTIME)
      // When printing non-symbolic frames, we normally print call
      // addresses, not return addresses, by subtracting one from the PC to
      // get an address within the preceding instruction.
      //
      // The one exception is a normal closure registered as a listener on a
      // future. In this case, the returned pc_offset is 0, as the closure
      // is invoked with the value of the resolved future. Thus, we must
      // report the return address, as returning a value before the closure
      // payload will cause failures to decode the frame using DWARF info.
      const bool is_future_listener = pc_offset == 0;
      const uword call_addr = is_future_listener ? pc : pc - 1;

      if (FLAG_dwarf_stack_traces_mode) {
        // This output is formatted like Android's debuggerd. Note debuggerd
        // prints call addresses instead of return addresses.
        buffer.Printf("    #%02" Pd " abs %" Pp "", frame_index, call_addr);
        PrintNonSymbolicStackFrameBody(&buffer, call_addr, isolate_instructions,
                                       vm_instructions);
        frame_index++;
        continue;
      }

      if (function.IsNull()) {
        in_gap = false;
        // We can't print the symbolic information since the owner was not
        // retained, so instead print the static symbol + offset like the
        // non-symbolic stack traces.
        PrintSymbolicStackFrameIndex(&buffer, frame_index);
        PrintNonSymbolicStackFrameBody(&buffer, call_addr, isolate_instructions,
                                       vm_instructions);
        frame_index++;
        continue;
      }
#endif

      if (code.is_optimized() && stack_trace.expand_inlined()) {
        code.GetInlinedFunctionsAtReturnAddress(pc_offset, &inlined_functions,
                                                &inlined_token_positions);
        ASSERT(inlined_functions.length() >= 1);
        for (intptr_t j = inlined_functions.length() - 1; j >= 0; j--) {
          const auto& inlined = *inlined_functions[j];
          auto const pos = inlined_token_positions[j];
          PrintSymbolicStackFrame(zone, &buffer, inlined, pos, frame_index,
                                  /*is_line=*/FLAG_precompiled_mode);
          frame_index++;
        }
        continue;
      }

      auto const pos = code.GetTokenIndexOfPC(pc);
      PrintSymbolicStackFrame(zone, &buffer, function, pos, frame_index);
      frame_index++;
    }

    // Follow the link.
    frame_skip = stack_trace.skip_sync_start_in_parent_stack()
                     ? StackTrace::kSyncAsyncCroppedFrames
                     : 0;
    stack_trace = stack_trace.async_link();
  } while (!stack_trace.IsNull());

  return buffer.buffer();
}

static void DwarfStackTracesHandler(bool value) {
  FLAG_dwarf_stack_traces_mode = value;

#if defined(PRODUCT)
  // We can safely remove function objects in precompiled snapshots if the
  // runtime will generate DWARF stack traces and we don't have runtime
  // debugging options like the observatory available.
  if (value) {
    FLAG_retain_function_objects = false;
  }
#endif
}

DEFINE_FLAG_HANDLER(DwarfStackTracesHandler,
                    dwarf_stack_traces,
                    "Omit CodeSourceMaps in precompiled snapshots and don't "
                    "symbolize stack traces in the precompiled runtime.");

void RegExp::set_pattern(const String& pattern) const {
  raw_ptr()->set_pattern(pattern.raw());
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
      raw_ptr()->set_one_byte_sticky(bytecode.raw());
    } else {
      raw_ptr()->set_two_byte_sticky(bytecode.raw());
    }
  } else {
    if (is_one_byte) {
      raw_ptr()->set_one_byte(bytecode.raw());
    } else {
      raw_ptr()->set_two_byte(bytecode.raw());
    }
  }
}

void RegExp::set_num_bracket_expressions(intptr_t value) const {
  raw_ptr()->set_num_bracket_expressions(Smi::New(value));
}

void RegExp::set_capture_name_map(const Array& array) const {
  raw_ptr()->set_capture_name_map(array.raw());
}

RegExpPtr RegExp::New(Heap::Space space) {
  RegExp& result = RegExp::Handle();
  {
    ObjectPtr raw =
        Object::Allocate(RegExp::kClassId, RegExp::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_type(kUninitialized);
    result.set_flags(RegExpFlags());
    result.set_num_registers(/*is_one_byte=*/false, -1);
    result.set_num_registers(/*is_one_byte=*/true, -1);
  }
  return result.raw();
}

const char* RegExpFlags::ToCString() const {
  switch (value_ & ~kGlobal) {
    case kIgnoreCase | kMultiLine | kDotAll | kUnicode:
      return "imsu";
    case kIgnoreCase | kMultiLine | kDotAll:
      return "ims";
    case kIgnoreCase | kMultiLine | kUnicode:
      return "imu";
    case kIgnoreCase | kUnicode | kDotAll:
      return "ius";
    case kMultiLine | kDotAll | kUnicode:
      return "msu";
    case kIgnoreCase | kMultiLine:
      return "im";
    case kIgnoreCase | kDotAll:
      return "is";
    case kIgnoreCase | kUnicode:
      return "iu";
    case kMultiLine | kDotAll:
      return "ms";
    case kMultiLine | kUnicode:
      return "mu";
    case kDotAll | kUnicode:
      return "su";
    case kIgnoreCase:
      return "i";
    case kMultiLine:
      return "m";
    case kDotAll:
      return "s";
    case kUnicode:
      return "u";
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
  if (flags() != other_js.flags()) {
    return false;
  }
  return true;
}

const char* RegExp::ToCString() const {
  const String& str = String::Handle(pattern());
  return OS::SCreate(Thread::Current()->zone(), "RegExp: pattern=%s flags=%s",
                     str.ToCString(), flags().ToCString());
}

WeakPropertyPtr WeakProperty::New(Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->weak_property_class() !=
         Class::null());
  ObjectPtr raw = Object::Allocate(WeakProperty::kClassId,
                                   WeakProperty::InstanceSize(), space);
  return static_cast<WeakPropertyPtr>(raw);
}

const char* WeakProperty::ToCString() const {
  return "_WeakProperty";
}

AbstractTypePtr MirrorReference::GetAbstractTypeReferent() const {
  ASSERT(Object::Handle(referent()).IsAbstractType());
  return AbstractType::Cast(Object::Handle(referent())).raw();
}

ClassPtr MirrorReference::GetClassReferent() const {
  ASSERT(Object::Handle(referent()).IsClass());
  return Class::Cast(Object::Handle(referent())).raw();
}

FieldPtr MirrorReference::GetFieldReferent() const {
  ASSERT(Object::Handle(referent()).IsField());
  return Field::Cast(Object::Handle(referent())).raw();
}

FunctionPtr MirrorReference::GetFunctionReferent() const {
  ASSERT(Object::Handle(referent()).IsFunction());
  return Function::Cast(Object::Handle(referent())).raw();
}

LibraryPtr MirrorReference::GetLibraryReferent() const {
  ASSERT(Object::Handle(referent()).IsLibrary());
  return Library::Cast(Object::Handle(referent())).raw();
}

TypeParameterPtr MirrorReference::GetTypeParameterReferent() const {
  ASSERT(Object::Handle(referent()).IsTypeParameter());
  return TypeParameter::Cast(Object::Handle(referent())).raw();
}

MirrorReferencePtr MirrorReference::New(const Object& referent,
                                        Heap::Space space) {
  MirrorReference& result = MirrorReference::Handle();
  {
    ObjectPtr raw = Object::Allocate(MirrorReference::kClassId,
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

UserTagPtr UserTag::New(const String& label, Heap::Space space) {
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
    ObjectPtr raw =
        Object::Allocate(UserTag::kClassId, UserTag::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_label(label);
  AddTagToIsolate(thread, result);
  return result.raw();
}

UserTagPtr UserTag::DefaultTag() {
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

UserTagPtr UserTag::FindTagInIsolate(Thread* thread, const String& label) {
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
    tag_label = other.label();
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

UserTagPtr UserTag::FindTagById(uword tag_id) {
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

void DumpTypeTable(Isolate* isolate) {
  OS::PrintErr("canonical types:\n");
  CanonicalTypeSet table(isolate->object_store()->canonical_types());
  table.Dump();
  table.Release();
}

void DumpTypeParameterTable(Isolate* isolate) {
  OS::PrintErr("canonical type parameters (cloned from declarations):\n");
  CanonicalTypeParameterSet table(
      isolate->object_store()->canonical_type_parameters());
  table.Dump();
  table.Release();
}

void DumpTypeArgumentsTable(Isolate* isolate) {
  OS::PrintErr("canonical type arguments:\n");
  CanonicalTypeArgumentsSet table(
      isolate->object_store()->canonical_type_arguments());
  table.Dump();
  table.Release();
}

EntryPointPragma FindEntryPointPragma(Isolate* I,
                                      const Array& metadata,
                                      Field* reusable_field_handle,
                                      Object* pragma) {
  for (intptr_t i = 0; i < metadata.Length(); i++) {
    *pragma = metadata.At(i);
    if (pragma->clazz() != I->object_store()->pragma_class()) {
      continue;
    }
    *reusable_field_handle = I->object_store()->pragma_name();
    if (Instance::Cast(*pragma).GetField(*reusable_field_handle) !=
        Symbols::vm_entry_point().raw()) {
      continue;
    }
    *reusable_field_handle = I->object_store()->pragma_options();
    *pragma = Instance::Cast(*pragma).GetField(*reusable_field_handle);
    if (pragma->raw() == Bool::null() || pragma->raw() == Bool::True().raw()) {
      return EntryPointPragma::kAlways;
      break;
    }
    if (pragma->raw() == Symbols::Get().raw()) {
      return EntryPointPragma::kGetterOnly;
    }
    if (pragma->raw() == Symbols::Set().raw()) {
      return EntryPointPragma::kSetterOnly;
    }
    if (pragma->raw() == Symbols::Call().raw()) {
      return EntryPointPragma::kCallOnly;
    }
  }
  return EntryPointPragma::kNever;
}

DART_WARN_UNUSED_RESULT
ErrorPtr VerifyEntryPoint(
    const Library& lib,
    const Object& member,
    const Object& annotated,
    std::initializer_list<EntryPointPragma> allowed_kinds) {
#if defined(DART_PRECOMPILED_RUNTIME)
  // Annotations are discarded in the AOT snapshot, so we can't determine
  // precisely if this member was marked as an entry-point. Instead, we use
  // "has_pragma()" as a proxy, since that bit is usually retained.
  bool is_marked_entrypoint = true;
  if (annotated.IsClass() && !Class::Cast(annotated).has_pragma()) {
    is_marked_entrypoint = false;
  } else if (annotated.IsField() && !Field::Cast(annotated).has_pragma()) {
    is_marked_entrypoint = false;
  } else if (annotated.IsFunction() &&
             !Function::Cast(annotated).has_pragma()) {
    is_marked_entrypoint = false;
  }
#else
  Object& metadata = Object::Handle(Object::empty_array().raw());
  if (!annotated.IsNull()) {
    metadata = lib.GetMetadata(annotated);
  }
  if (metadata.IsError()) return Error::RawCast(metadata.raw());
  ASSERT(!metadata.IsNull() && metadata.IsArray());
  EntryPointPragma pragma =
      FindEntryPointPragma(Isolate::Current(), Array::Cast(metadata),
                           &Field::Handle(), &Object::Handle());
  bool is_marked_entrypoint = pragma == EntryPointPragma::kAlways;
  if (!is_marked_entrypoint) {
    for (const auto allowed_kind : allowed_kinds) {
      if (pragma == allowed_kind) {
        is_marked_entrypoint = true;
        break;
      }
    }
  }
#endif
  if (!is_marked_entrypoint) {
    const char* member_cstring =
        member.IsFunction()
            ? OS::SCreate(
                  Thread::Current()->zone(), "%s (kind %s)",
                  Function::Cast(member).ToLibNamePrefixedQualifiedCString(),
                  Function::KindToCString(Function::Cast(member).kind()))
            : member.ToCString();
    char const* error = OS::SCreate(
        Thread::Current()->zone(),
        "ERROR: It is illegal to access '%s' through Dart C API.\n"
        "ERROR: See "
        "https://github.com/dart-lang/sdk/blob/master/runtime/docs/compiler/"
        "aot/entry_point_pragma.md\n",
        member_cstring);
    OS::PrintErr("%s", error);
    return ApiError::New(String::Handle(String::New(error)));
  }
  return Error::null();
}

DART_WARN_UNUSED_RESULT
ErrorPtr EntryPointFieldInvocationError(const String& getter_name) {
  if (!FLAG_verify_entry_points) return Error::null();

  char const* error = OS::SCreate(
      Thread::Current()->zone(),
      "ERROR: Entry-points do not allow invoking fields "
      "(failure to resolve '%s')\n"
      "ERROR: See "
      "https://github.com/dart-lang/sdk/blob/master/runtime/docs/compiler/"
      "aot/entry_point_pragma.md\n",
      getter_name.ToCString());
  OS::PrintErr("%s", error);
  return ApiError::New(String::Handle(String::New(error)));
}

ErrorPtr Function::VerifyCallEntryPoint() const {
  if (!FLAG_verify_entry_points) return Error::null();

  const Class& cls = Class::Handle(Owner());
  const Library& lib = Library::Handle(cls.library());
  switch (kind()) {
    case FunctionLayout::kRegularFunction:
    case FunctionLayout::kSetterFunction:
    case FunctionLayout::kConstructor:
      return dart::VerifyEntryPoint(lib, *this, *this,
                                    {EntryPointPragma::kCallOnly});
      break;
    case FunctionLayout::kGetterFunction:
      return dart::VerifyEntryPoint(
          lib, *this, *this,
          {EntryPointPragma::kCallOnly, EntryPointPragma::kGetterOnly});
      break;
    case FunctionLayout::kImplicitGetter:
      return dart::VerifyEntryPoint(lib, *this, Field::Handle(accessor_field()),
                                    {EntryPointPragma::kGetterOnly});
      break;
    case FunctionLayout::kImplicitSetter:
      return dart::VerifyEntryPoint(lib, *this, Field::Handle(accessor_field()),
                                    {EntryPointPragma::kSetterOnly});
    case FunctionLayout::kMethodExtractor:
      return Function::Handle(extracted_method_closure())
          .VerifyClosurizedEntryPoint();
      break;
    default:
      return dart::VerifyEntryPoint(lib, *this, Object::Handle(), {});
      break;
  }
}

ErrorPtr Function::VerifyClosurizedEntryPoint() const {
  if (!FLAG_verify_entry_points) return Error::null();

  const Class& cls = Class::Handle(Owner());
  const Library& lib = Library::Handle(cls.library());
  switch (kind()) {
    case FunctionLayout::kRegularFunction:
      return dart::VerifyEntryPoint(lib, *this, *this,
                                    {EntryPointPragma::kGetterOnly});
    case FunctionLayout::kImplicitClosureFunction: {
      const Function& parent = Function::Handle(parent_function());
      return dart::VerifyEntryPoint(lib, parent, parent,
                                    {EntryPointPragma::kGetterOnly});
    }
    default:
      UNREACHABLE();
  }
}

ErrorPtr Field::VerifyEntryPoint(EntryPointPragma pragma) const {
  if (!FLAG_verify_entry_points) return Error::null();
  const Class& cls = Class::Handle(Owner());
  const Library& lib = Library::Handle(cls.library());
  return dart::VerifyEntryPoint(lib, *this, *this, {pragma});
}

ErrorPtr Class::VerifyEntryPoint() const {
  if (!FLAG_verify_entry_points) return Error::null();
  const Library& lib = Library::Handle(library());
  if (!lib.IsNull()) {
    return dart::VerifyEntryPoint(lib, *this, *this, {});
  } else {
    return Error::null();
  }
}

}  // namespace dart
