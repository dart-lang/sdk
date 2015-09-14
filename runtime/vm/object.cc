// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/bit_vector.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/code_generator.h"
#include "vm/code_observers.h"
#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/compiler_stats.h"
#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/datastream.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/disassembler.h"
#include "vm/double_conversion.h"
#include "vm/exceptions.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/growable_array.h"
#include "vm/hash_table.h"
#include "vm/heap.h"
#include "vm/intermediate_language.h"
#include "vm/intrinsifier.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/profiler.h"
#include "vm/report.h"
#include "vm/reusable_handles.h"
#include "vm/runtime_entry.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/timer.h"
#include "vm/unicode.h"
#include "vm/verified_memory.h"
#include "vm/weak_code.h"

namespace dart {

DEFINE_FLAG(int, huge_method_cutoff_in_code_size, 200000,
    "Huge method cutoff in unoptimized code size (in bytes).");
DEFINE_FLAG(int, huge_method_cutoff_in_tokens, 20000,
    "Huge method cutoff in tokens: Disables optimizations for huge methods.");
DEFINE_FLAG(bool, overlap_type_arguments, true,
    "When possible, partially or fully overlap the type arguments of a type "
    "with the type arguments of its super type.");
DEFINE_FLAG(bool, show_internal_names, false,
    "Show names of internal classes (e.g. \"OneByteString\") in error messages "
    "instead of showing the corresponding interface names (e.g. \"String\")");
DEFINE_FLAG(bool, throw_on_javascript_int_overflow, false,
    "Throw an exception when the result of an integer calculation will not "
    "fit into a javascript integer.");
DEFINE_FLAG(bool, trace_cha, false, "Trace CHA operations");
DEFINE_FLAG(bool, use_field_guards, true, "Guard field cids.");
DEFINE_FLAG(bool, use_lib_cache, true, "Use library name cache");
DEFINE_FLAG(bool, trace_field_guards, false, "Trace changes in field's cids.");

DECLARE_FLAG(charp, coverage_dir);
DECLARE_FLAG(bool, load_deferred_eagerly);
DECLARE_FLAG(bool, show_invisible_frames);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_deoptimization);
DECLARE_FLAG(bool, trace_deoptimization_verbose);
DECLARE_FLAG(bool, write_protect_code);


static const char* kGetterPrefix = "get:";
static const intptr_t kGetterPrefixLength = strlen(kGetterPrefix);
static const char* kSetterPrefix = "set:";
static const intptr_t kSetterPrefixLength = strlen(kSetterPrefix);

cpp_vtable Object::handle_vtable_ = 0;
cpp_vtable Object::builtin_vtables_[kNumPredefinedCids] = { 0 };
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
TypeArguments* Object::null_type_arguments_ = NULL;
Array* Object::empty_array_ = NULL;
Array* Object::zero_array_ = NULL;
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
Array* Object::vm_isolate_snapshot_object_table_ = NULL;
const uint8_t* Object::instructions_snapshot_buffer_ = NULL;

RawObject* Object::null_ = reinterpret_cast<RawObject*>(RAW_NULL);
RawClass* Object::class_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::dynamic_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::void_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawType* Object::dynamic_type_ = reinterpret_cast<RawType*>(RAW_NULL);
RawType* Object::void_type_ = reinterpret_cast<RawType*>(RAW_NULL);
RawClass* Object::unresolved_class_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::type_arguments_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::patch_class_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::function_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::closure_data_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
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
RawClass* Object::stackmap_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::var_descriptors_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::exception_handlers_class_ =
    reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::context_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
RawClass* Object::context_scope_class_ = reinterpret_cast<RawClass*>(RAW_NULL);
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


const double MegamorphicCache::kLoadFactor = 0.75;


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
//   _ReceivePortImpl@6be832b -> _ReceivePortImpl
//   _ReceivePortImpl@6be832b._internal@6be832b -> _ReceivePortImpl._internal
//   _C@0x2b4ab9cc&_E@0x2b4ab9cc&_F@0x2b4ab9cc -> _C&_E&_F
//
// The trailing . on the default constructor name is dropped:
//
//   List. -> List
//
// And so forth:
//
//   get:foo@6be832b -> foo
//   _MyClass@6b3832b. -> _MyClass
//   _MyClass@6b3832b.named -> _MyClass.named
//
RawString* String::IdentifierPrettyName(const String& name) {
  if (name.Equals(Symbols::TopLevel())) {
    // Name of invisible top-level class.
    return Symbols::Empty().raw();
  }

  // First remove all private name mangling.
  String& unmangled_name = String::Handle(Symbols::Empty().raw());
  String& segment = String::Handle();
  intptr_t start_pos = 0;
  for (intptr_t i = 0; i < name.Length(); i++) {
    if (name.CharAt(i) == '@' &&
        (i+1) < name.Length() &&
        (name.CharAt(i+1) >= '0') &&
        (name.CharAt(i+1) <= '9')) {
      // Append the current segment to the unmangled name.
      segment = String::SubString(name, start_pos, (i - start_pos));
      unmangled_name = String::Concat(unmangled_name, segment);

      // Advance until past the name mangling. The private keys are only
      // numbers so we skip until the first non-number.
      i++;  // Skip the '@'.
      while ((i < name.Length()) &&
             (name.CharAt(i) >= '0') &&
             (name.CharAt(i) <= '9')) {
        i++;
      }
      start_pos = i;
      i--;  // Account for for-loop increment.
    }
  }
  if (start_pos == 0) {
    // No name unmangling needed, reuse the name that was passed in.
    unmangled_name = name.raw();
  } else if (name.Length() != start_pos) {
    // Append the last segment.
    segment = String::SubString(name, start_pos, (name.Length() - start_pos));
    unmangled_name = String::Concat(unmangled_name, segment);
  }

  intptr_t len = unmangled_name.Length();
  intptr_t start = 0;
  intptr_t dot_pos = -1;  // Position of '.' in the name, if any.
  bool is_setter = false;
  for (intptr_t i = start; i < len; i++) {
    if (unmangled_name.CharAt(i) == ':') {
      if (start != 0) {
        // Reset and break.
        start = 0;
        dot_pos = -1;
        break;
      }
      ASSERT(start == 0);  // Only one : is possible in getters or setters.
      if (unmangled_name.CharAt(0) == 's') {
        is_setter = true;
      }
      start = i + 1;
    } else if (unmangled_name.CharAt(i) == '.') {
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
    return unmangled_name.raw();
  }

  // Drop the trailing dot if needed.
  intptr_t end = ((dot_pos + 1) == len) ? dot_pos : len;

  const String& result =
      String::Handle(String::SubString(unmangled_name, start, (end - start)));

  if (is_setter) {
    // Setters need to end with '='.
    return String::Concat(result, Symbols::Equals());
  }

  return result.raw();
}


RawString* String::IdentifierPrettyNameRetainPrivate(const String& name) {
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
}


template<typename type>
static bool IsSpecialCharacter(type value) {
  return ((value == '"') ||
          (value == '\n') ||
          (value == '\f') ||
          (value == '\b') ||
          (value == '\t') ||
          (value == '\v') ||
          (value == '\r') ||
          (value == '\\') ||
          (value == '$'));
}


static inline bool IsAsciiNonprintable(int32_t c) {
  return ((0 <= c) && (c < 32)) || (c == 127);
}


static inline bool NeedsEscapeSequence(int32_t c) {
  return (c == '"')  ||
         (c == '\\') ||
         (c == '$')  ||
         IsAsciiNonprintable(c);
}


static int32_t EscapeOverhead(int32_t c) {
  if (IsSpecialCharacter(c)) {
    return 1;  // 1 additional byte for the backslash.
  } else if (IsAsciiNonprintable(c)) {
    return 3;  // 3 additional bytes to encode c as \x00.
  }
  return 0;
}


template<typename type>
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
  null_type_arguments_ = TypeArguments::ReadOnlyHandle();
  empty_array_ = Array::ReadOnlyHandle();
  zero_array_ = Array::ReadOnlyHandle();
  empty_context_scope_ = ContextScope::ReadOnlyHandle();
  empty_object_pool_ = ObjectPool::ReadOnlyHandle();
  empty_descriptors_ = PcDescriptors::ReadOnlyHandle();
  empty_var_descriptors_ = LocalVarDescriptors::ReadOnlyHandle();
  empty_exception_handlers_ = ExceptionHandlers::ReadOnlyHandle();
  extractor_parameter_types_ = Array::ReadOnlyHandle();
  extractor_parameter_names_ = Array::ReadOnlyHandle();
  sentinel_ = Instance::ReadOnlyHandle();
  transition_sentinel_ = Instance::ReadOnlyHandle();
  unknown_constant_ =  Instance::ReadOnlyHandle();
  non_constant_ =  Instance::ReadOnlyHandle();
  bool_true_ = Bool::ReadOnlyHandle();
  bool_false_ = Bool::ReadOnlyHandle();
  smi_illegal_cid_ = Smi::ReadOnlyHandle();
  snapshot_writer_error_ = LanguageError::ReadOnlyHandle();
  branch_offset_error_ = LanguageError::ReadOnlyHandle();
  vm_isolate_snapshot_object_table_ = Array::ReadOnlyHandle();

  *null_object_ = Object::null();
  *null_array_ = Array::null();
  *null_string_ = String::null();
  *null_instance_ = Instance::null();
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

  cls = Class::New<Stackmap>();
  stackmap_class_ = cls.raw();

  cls = Class::New<LocalVarDescriptors>();
  var_descriptors_class_ = cls.raw();

  cls = Class::New<ExceptionHandlers>();
  exception_handlers_class_ = cls.raw();

  cls = Class::New<Context>();
  context_class_ = cls.raw();

  cls = Class::New<ContextScope>();
  context_scope_class_ = cls.raw();

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

  // Allocate and initialize the empty_array instance.
  {
    uword address = heap->Allocate(Array::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kImmutableArrayCid, Array::InstanceSize(0), true);
    Array::initializeHandle(
        empty_array_,
        reinterpret_cast<RawArray*>(address + kHeapObjectTag));
    empty_array_->StoreSmi(&empty_array_->raw_ptr()->length_, Smi::New(0));
  }

  Smi& smi = Smi::Handle();
  // Allocate and initialize the zero_array instance.
  {
    uword address = heap->Allocate(Array::InstanceSize(1), Heap::kOld);
    InitializeObject(address, kImmutableArrayCid, Array::InstanceSize(1), true);
    Array::initializeHandle(
        zero_array_,
        reinterpret_cast<RawArray*>(address + kHeapObjectTag));
    zero_array_->StoreSmi(&zero_array_->raw_ptr()->length_, Smi::New(1));
    smi = Smi::New(0);
    zero_array_->SetAt(0, smi);
  }

  // Allocate and initialize the canonical empty context scope object.
  {
    uword address = heap->Allocate(ContextScope::InstanceSize(0), Heap::kOld);
    InitializeObject(address,
                     kContextScopeCid,
                     ContextScope::InstanceSize(0),
                     true);
    ContextScope::initializeHandle(
        empty_context_scope_,
        reinterpret_cast<RawContextScope*>(address + kHeapObjectTag));
    empty_context_scope_->StoreNonPointer(
        &empty_context_scope_->raw_ptr()->num_variables_, 0);
    empty_context_scope_->StoreNonPointer(
        &empty_context_scope_->raw_ptr()->is_implicit_, true);
  }

  // Allocate and initialize the canonical empty object pool object.
  {
    uword address =
        heap->Allocate(ObjectPool::InstanceSize(0), Heap::kOld);
    InitializeObject(address,
                     kObjectPoolCid,
                     ObjectPool::InstanceSize(0),
                     true);
    ObjectPool::initializeHandle(
        empty_object_pool_,
        reinterpret_cast<RawObjectPool*>(address + kHeapObjectTag));
    empty_object_pool_->StoreNonPointer(
        &empty_object_pool_->raw_ptr()->length_, 0);
  }

  // Allocate and initialize the empty_descriptors instance.
  {
    uword address = heap->Allocate(PcDescriptors::InstanceSize(0), Heap::kOld);
    InitializeObject(address, kPcDescriptorsCid,
                     PcDescriptors::InstanceSize(0),
                     true);
    PcDescriptors::initializeHandle(
        empty_descriptors_,
        reinterpret_cast<RawPcDescriptors*>(address + kHeapObjectTag));
    empty_descriptors_->StoreNonPointer(&empty_descriptors_->raw_ptr()->length_,
                                        0);
  }

  // Allocate and initialize the canonical empty variable descriptor object.
  {
    uword address =
        heap->Allocate(LocalVarDescriptors::InstanceSize(0), Heap::kOld);
    InitializeObject(address,
                     kLocalVarDescriptorsCid,
                     LocalVarDescriptors::InstanceSize(0),
                     true);
    LocalVarDescriptors::initializeHandle(
        empty_var_descriptors_,
        reinterpret_cast<RawLocalVarDescriptors*>(address + kHeapObjectTag));
    empty_var_descriptors_->StoreNonPointer(
        &empty_var_descriptors_->raw_ptr()->num_entries_, 0);
  }

  // Allocate and initialize the canonical empty exception handler info object.
  // The vast majority of all functions do not contain an exception handler
  // and can share this canonical descriptor.
  {
    uword address =
        heap->Allocate(ExceptionHandlers::InstanceSize(0), Heap::kOld);
    InitializeObject(address,
                     kExceptionHandlersCid,
                     ExceptionHandlers::InstanceSize(0),
                     true);
    ExceptionHandlers::initializeHandle(
        empty_exception_handlers_,
        reinterpret_cast<RawExceptionHandlers*>(address + kHeapObjectTag));
    empty_exception_handlers_->StoreNonPointer(
        &empty_exception_handlers_->raw_ptr()->num_entries_, 0);
  }

  // The VM isolate snapshot object table is initialized to an empty array
  // as we do not have any VM isolate snapshot at this time.
  *vm_isolate_snapshot_object_table_ = Object::empty_array().raw();

  cls = Class::New<Instance>(kDynamicCid);
  cls.set_is_abstract();
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_type_finalized();
  cls.set_is_finalized();
  dynamic_class_ = cls.raw();

  cls = Class::New<Instance>(kVoidCid);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_type_finalized();
  cls.set_is_finalized();
  void_class_ = cls.raw();

  cls = Class::New<Type>();
  cls.set_is_type_finalized();
  cls.set_is_finalized();

  cls = dynamic_class_;
  dynamic_type_ = Type::NewNonParameterizedType(cls);

  cls = void_class_;
  void_type_ = Type::NewNonParameterizedType(cls);

  // Allocate and initialize singleton true and false boolean objects.
  cls = Class::New<Bool>();
  isolate->object_store()->set_bool_class(cls);
  *bool_true_ = Bool::New(true);
  *bool_false_ = Bool::New(false);

  *smi_illegal_cid_ = Smi::New(kIllegalCid);

  String& error_str = String::Handle();
  error_str = String::New("SnapshotWriter Error", Heap::kOld);
  *snapshot_writer_error_ = LanguageError::New(error_str,
                                               Report::kError,
                                               Heap::kOld);
  error_str = String::New("Branch offset overflow", Heap::kOld);
  *branch_offset_error_ = LanguageError::New(error_str,
                                             Report::kBailout,
                                             Heap::kOld);

  ASSERT(!null_object_->IsSmi());
  ASSERT(!null_array_->IsSmi());
  ASSERT(null_array_->IsArray());
  ASSERT(!null_string_->IsSmi());
  ASSERT(null_string_->IsString());
  ASSERT(!null_instance_->IsSmi());
  ASSERT(null_instance_->IsInstance());
  ASSERT(!null_type_arguments_->IsSmi());
  ASSERT(null_type_arguments_->IsTypeArguments());
  ASSERT(!empty_array_->IsSmi());
  ASSERT(empty_array_->IsArray());
  ASSERT(!zero_array_->IsSmi());
  ASSERT(zero_array_->IsArray());
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
  ASSERT(!vm_isolate_snapshot_object_table_->IsSmi());
  ASSERT(vm_isolate_snapshot_object_table_->IsArray());
}


// An object visitor which will mark all visited objects. This is used to
// premark all objects in the vm_isolate_ heap.
class PremarkingVisitor : public ObjectVisitor {
 public:
  explicit PremarkingVisitor(Isolate* isolate) : ObjectVisitor(isolate) {}

  void VisitObject(RawObject* obj) {
    ASSERT(!obj->IsMarked());
    // Free list elements should never be marked.
    if (!obj->IsFreeListElement()) {
      ASSERT(obj->IsVMHeapObject());
      obj->SetMarkBitUnsynchronized();
    }
  }
};


#define SET_CLASS_NAME(class_name, name)                                       \
  cls = class_name##_class();                                                  \
  cls.set_name(Symbols::name());                                               \

void Object::FinalizeVMIsolate(Isolate* isolate) {
  // Should only be run by the vm isolate.
  ASSERT(isolate == Dart::vm_isolate());

  // Allocate the parameter arrays for method extractor types and names.
  *extractor_parameter_types_ = Array::New(1, Heap::kOld);
  extractor_parameter_types_->SetAt(0, Type::Handle(Type::DynamicType()));
  *extractor_parameter_names_ = Array::New(1, Heap::kOld);
  extractor_parameter_names_->SetAt(0, Symbols::This());

  ASSERT(!extractor_parameter_types_->IsSmi());
  ASSERT(extractor_parameter_types_->IsArray());
  ASSERT(!extractor_parameter_names_->IsSmi());
  ASSERT(extractor_parameter_names_->IsArray());


  // Set up names for all VM singleton classes.
  Class& cls = Class::Handle(isolate);

  SET_CLASS_NAME(class, Class);
  SET_CLASS_NAME(dynamic, Dynamic);
  SET_CLASS_NAME(void, Void);
  SET_CLASS_NAME(unresolved_class, UnresolvedClass);
  SET_CLASS_NAME(type_arguments, TypeArguments);
  SET_CLASS_NAME(patch_class, PatchClass);
  SET_CLASS_NAME(function, Function);
  SET_CLASS_NAME(closure_data, ClosureData);
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
  SET_CLASS_NAME(pc_descriptors, PcDescriptors);
  SET_CLASS_NAME(stackmap, Stackmap);
  SET_CLASS_NAME(var_descriptors, LocalVarDescriptors);
  SET_CLASS_NAME(exception_handlers, ExceptionHandlers);
  SET_CLASS_NAME(context, Context);
  SET_CLASS_NAME(context_scope, ContextScope);
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

  // Make the VM isolate read-only after setting all objects as marked.
  PremarkingVisitor premarker(isolate);
  isolate->heap()->WriteProtect(false);
  ASSERT(isolate->heap()->UsedInWords(Heap::kNew) == 0);
  isolate->heap()->IterateOldObjects(&premarker);
  isolate->heap()->WriteProtect(true);
}


void Object::InitVmIsolateSnapshotObjectTable(intptr_t len) {
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  *vm_isolate_snapshot_object_table_ = Array::New(len, Heap::kOld);
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
      uword tags = raw->ptr()->tags_;
      uword old_tags;
      // TODO(iposva): Investigate whether CompareAndSwapWord is necessary.
      do {
        old_tags = tags;
        tags = AtomicOperations::CompareAndSwapWord(
            &raw->ptr()->tags_, old_tags, new_tags);
      } while (tags != old_tags);

      intptr_t leftover_len = (leftover_size - TypedData::InstanceSize(0));
      ASSERT(TypedData::InstanceSize(leftover_len) == leftover_size);
      raw->InitializeSmi(&(raw->ptr()->length_), Smi::New(leftover_len));
    } else {
      // Update the leftover space as a basic object.
      ASSERT(leftover_size == Object::InstanceSize());
      RawObject* raw = reinterpret_cast<RawObject*>(RawObject::FromAddr(addr));
      uword new_tags = RawObject::ClassIdTag::update(kInstanceCid, 0);
      new_tags = RawObject::SizeTag::update(leftover_size, new_tags);
      uword tags = raw->ptr()->tags_;
      uword old_tags;
      // TODO(iposva): Investigate whether CompareAndSwapWord is necessary.
      do {
        old_tags = tags;
        tags = AtomicOperations::CompareAndSwapWord(
            &raw->ptr()->tags_, old_tags, new_tags);
      } while (tags != old_tags);
    }
  }
}


void Object::VerifyBuiltinVtables() {
#if defined(DEBUG)
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  Class& cls = Class::Handle(isolate, Class::null());
  for (intptr_t cid = (kIllegalCid + 1); cid < kNumPredefinedCids; cid++) {
    if (isolate->class_table()->HasValidClassAt(cid)) {
      cls ^= isolate->class_table()->At(cid);
      ASSERT(builtin_vtables_[cid] == cls.raw_ptr()->handle_vtable_);
    }
  }
  ASSERT(builtin_vtables_[kFreeListElement] == 0);
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


RawError* Object::Init(Isolate* isolate) {
  Thread* thread = Thread::Current();
  ASSERT(isolate == thread->isolate());
  TIMERSCOPE(thread, time_bootstrap);
  TimelineDurationScope tds(isolate,
                            isolate->GetIsolateStream(),
                            "Object::Init");

#if defined(DART_NO_SNAPSHOT)
  // Object::Init version when we are running in a version of dart that does
  // not have a full snapshot linked in.
  ObjectStore* object_store = isolate->object_store();

  Class& cls = Class::Handle(isolate);
  Type& type = Type::Handle(isolate);
  Array& array = Array::Handle(isolate);
  Library& lib = Library::Handle(isolate);

  // All RawArray fields will be initialized to an empty array, therefore
  // initialize array class first.
  cls = Class::New<Array>();
  object_store->set_array_class(cls);

  // VM classes that are parameterized (Array, ImmutableArray,
  // GrowableObjectArray, and LinkedHashMap) are also pre-finalized,
  // so CalculateFieldOffsets() is not called, so we need to set the
  // offset of their type_arguments_ field, which is explicitly
  // declared in their respective Raw* classes.
  cls.set_type_arguments_field_offset(Array::type_arguments_offset());
  cls.set_num_type_arguments(1);

  // Set up the growable object array class (Has to be done after the array
  // class is setup as one of its field is an array object).
  cls = Class::New<GrowableObjectArray>();
  object_store->set_growable_object_array_class(cls);
  cls.set_type_arguments_field_offset(
      GrowableObjectArray::type_arguments_offset());
  cls.set_num_type_arguments(1);

  // canonical_type_arguments_ are Smi terminated.
  // Last element contains the count of used slots.
  const intptr_t kInitialCanonicalTypeArgumentsSize = 4;
  array = Array::New(kInitialCanonicalTypeArgumentsSize + 1);
  array.SetAt(kInitialCanonicalTypeArgumentsSize,
              Smi::Handle(isolate, Smi::New(0)));
  object_store->set_canonical_type_arguments(array);

  // Setup type class early in the process.
  const Class& type_cls = Class::Handle(isolate, Class::New<Type>());
  const Class& type_ref_cls = Class::Handle(isolate, Class::New<TypeRef>());
  const Class& type_parameter_cls = Class::Handle(isolate,
                                                  Class::New<TypeParameter>());
  const Class& bounded_type_cls = Class::Handle(isolate,
                                                Class::New<BoundedType>());
  const Class& mixin_app_type_cls = Class::Handle(isolate,
                                                  Class::New<MixinAppType>());
  const Class& library_prefix_cls = Class::Handle(isolate,
                                                  Class::New<LibraryPrefix>());

  // Pre-allocate the OneByteString class needed by the symbol table.
  cls = Class::NewStringClass(kOneByteStringCid);
  object_store->set_one_byte_string_class(cls);

  // Pre-allocate the TwoByteString class needed by the symbol table.
  cls = Class::NewStringClass(kTwoByteStringCid);
  object_store->set_two_byte_string_class(cls);

  // Setup the symbol table for the symbols created in the isolate.
  Symbols::SetupSymbolTable(isolate);

  // Set up the libraries array before initializing the core library.
  const GrowableObjectArray& libraries = GrowableObjectArray::Handle(
      isolate, GrowableObjectArray::New(Heap::kOld));
  object_store->set_libraries(libraries);

  // Pre-register the core library.
  Library::InitCoreLibrary(isolate);

  // Basic infrastructure has been setup, initialize the class dictionary.
  const Library& core_lib = Library::Handle(isolate, Library::CoreLibrary());
  ASSERT(!core_lib.IsNull());

  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  object_store->set_pending_classes(pending_classes);

  Context& context = Context::Handle(isolate, Context::New(0, Heap::kOld));
  object_store->set_empty_context(context);

  // Now that the symbol table is initialized and that the core dictionary as
  // well as the core implementation dictionary have been setup, preallocate
  // remaining classes and register them by name in the dictionaries.
  String& name = String::Handle(isolate);
  cls = object_store->array_class();  // Was allocated above.
  RegisterPrivateClass(cls, Symbols::_List(), core_lib);
  pending_classes.Add(cls);
  // We cannot use NewNonParameterizedType(cls), because Array is parameterized.
  // Warning: class _List has not been patched yet. Its declared number of type
  // parameters is still 0. It will become 1 after patching. The array type
  // allocated below represents the raw type _List and not _List<E> as we
  // could expect. Use with caution.
  type ^= Type::New(Object::Handle(isolate, cls.raw()),
                    TypeArguments::Handle(isolate),
                    Scanner::kNoSourcePos);
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
  ASSERT(object_store->immutable_array_class() != object_store->array_class());
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

  // Pre-register the isolate library so the native class implementations
  // can be hooked up before compiling it.
  Library& isolate_lib =
      Library::Handle(isolate, Library::LookupLibrary(Symbols::DartIsolate()));
  if (isolate_lib.IsNull()) {
    isolate_lib = Library::NewLibraryHelper(Symbols::DartIsolate(), true);
    isolate_lib.SetLoadRequested();
    isolate_lib.Register();
    object_store->set_bootstrap_library(ObjectStore::kIsolate, isolate_lib);
  }
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

  const Class& stacktrace_cls = Class::Handle(isolate,
                                              Class::New<Stacktrace>());
  RegisterPrivateClass(stacktrace_cls, Symbols::_StackTrace(), core_lib);
  pending_classes.Add(stacktrace_cls);
  // Super type set below, after Object is allocated.

  cls = Class::New<JSRegExp>();
  RegisterPrivateClass(cls, Symbols::JSSyntaxRegExp(), core_lib);
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
  RegisterPrivateClass(library_prefix_cls, Symbols::_LibraryPrefix(), core_lib);
  pending_classes.Add(library_prefix_cls);

  RegisterPrivateClass(type_cls, Symbols::Type(), core_lib);
  pending_classes.Add(type_cls);

  RegisterPrivateClass(type_ref_cls, Symbols::TypeRef(), core_lib);
  pending_classes.Add(type_ref_cls);

  RegisterPrivateClass(type_parameter_cls, Symbols::TypeParameter(), core_lib);
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

  // Abstract super class for all signature classes.
  cls = Class::New<Instance>(kIllegalCid);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_prefinalized();
  RegisterPrivateClass(cls, Symbols::FunctionImpl(), core_lib);
  pending_classes.Add(cls);
  type = Type::NewNonParameterizedType(cls);
  object_store->set_function_impl_type(type);

  cls = Class::New<WeakProperty>();
  object_store->set_weak_property_class(cls);
  RegisterPrivateClass(cls, Symbols::_WeakProperty(), core_lib);

  // Pre-register the mirrors library so we can place the vm class
  // MirrorReference there rather than the core library.
  lib = Library::LookupLibrary(Symbols::DartMirrors());
  if (lib.IsNull()) {
    lib = Library::NewLibraryHelper(Symbols::DartMirrors(), true);
    lib.SetLoadRequested();
    lib.Register();
    object_store->set_bootstrap_library(ObjectStore::kMirrors, lib);
  }
  ASSERT(!lib.IsNull());
  ASSERT(lib.raw() == Library::MirrorsLibrary());

  cls = Class::New<MirrorReference>();
  RegisterPrivateClass(cls, Symbols::_MirrorReference(), lib);

  // Pre-register the collection library so we can place the vm class
  // LinkedHashMap there rather than the core library.
  lib = Library::LookupLibrary(Symbols::DartCollection());
  if (lib.IsNull()) {
    lib = Library::NewLibraryHelper(Symbols::DartCollection(), true);
    lib.SetLoadRequested();
    lib.Register();
    object_store->set_bootstrap_library(ObjectStore::kCollection, lib);
  }
  ASSERT(!lib.IsNull());
  ASSERT(lib.raw() == Library::CollectionLibrary());
  cls = Class::New<LinkedHashMap>();
  object_store->set_linked_hash_map_class(cls);
  cls.set_type_arguments_field_offset(LinkedHashMap::type_arguments_offset());
  cls.set_num_type_arguments(2);
  cls.set_num_own_type_arguments(2);
  RegisterPrivateClass(cls, Symbols::_LinkedHashMap(), lib);
  pending_classes.Add(cls);

  // Pre-register the developer library so we can place the vm class
  // UserTag there rather than the core library.
  lib = Library::LookupLibrary(Symbols::DartDeveloper());
  if (lib.IsNull()) {
    lib = Library::NewLibraryHelper(Symbols::DartDeveloper(), true);
    lib.SetLoadRequested();
    lib.Register();
    object_store->set_bootstrap_library(ObjectStore::kDeveloper, lib);
  }
  ASSERT(!lib.IsNull());
  ASSERT(lib.raw() == Library::DeveloperLibrary());

  lib = Library::LookupLibrary(Symbols::DartDeveloper());
  ASSERT(!lib.IsNull());
  cls = Class::New<UserTag>();
  RegisterPrivateClass(cls, Symbols::_UserTag(), lib);
  pending_classes.Add(cls);

  // Setup some default native field classes which can be extended for
  // specifying native fields in dart classes.
  Library::InitNativeWrappersLibrary(isolate);
  ASSERT(object_store->native_wrappers_library() != Library::null());

  // Pre-register the typed_data library so the native class implementations
  // can be hooked up before compiling it.
  lib = Library::LookupLibrary(Symbols::DartTypedData());
  if (lib.IsNull()) {
    lib = Library::NewLibraryHelper(Symbols::DartTypedData(), true);
    lib.SetLoadRequested();
    lib.Register();
    object_store->set_bootstrap_library(ObjectStore::kTypedData, lib);
  }
  ASSERT(!lib.IsNull());
  ASSERT(lib.raw() == Library::TypedDataLibrary());
#define REGISTER_TYPED_DATA_CLASS(clazz)                                       \
  cls = Class::NewTypedDataClass(kTypedData##clazz##Cid);                      \
  RegisterPrivateClass(cls, Symbols::_##clazz(), lib);                         \

  CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_CLASS);
#undef REGISTER_TYPED_DATA_CLASS
#define REGISTER_TYPED_DATA_VIEW_CLASS(clazz)                                  \
  cls = Class::NewTypedDataViewClass(kTypedData##clazz##ViewCid);              \
  RegisterPrivateClass(cls, Symbols::_##clazz##View(), lib);                   \
  pending_classes.Add(cls);                                                    \

  CLASS_LIST_TYPED_DATA(REGISTER_TYPED_DATA_VIEW_CLASS);
  cls = Class::NewTypedDataViewClass(kByteDataViewCid);
  RegisterPrivateClass(cls, Symbols::_ByteDataView(), lib);
  pending_classes.Add(cls);
#undef REGISTER_TYPED_DATA_VIEW_CLASS
#define REGISTER_EXT_TYPED_DATA_CLASS(clazz)                                   \
  cls = Class::NewExternalTypedDataClass(kExternalTypedData##clazz##Cid);      \
  RegisterPrivateClass(cls, Symbols::_External##clazz(), lib);                 \

  cls = Class::New<Instance>(kByteBufferCid);
  cls.set_instance_size(0);
  cls.set_next_field_offset(-kWordSize);
  RegisterPrivateClass(cls, Symbols::_ByteBuffer(), lib);
  pending_classes.Add(cls);

  CLASS_LIST_TYPED_DATA(REGISTER_EXT_TYPED_DATA_CLASS);
#undef REGISTER_EXT_TYPED_DATA_CLASS
  // Register Float32x4 and Int32x4 in the object store.
  cls = Class::New<Float32x4>();
  object_store->set_float32x4_class(cls);
  RegisterPrivateClass(cls, Symbols::_Float32x4(), lib);
  cls = Class::New<Int32x4>();
  object_store->set_int32x4_class(cls);
  RegisterPrivateClass(cls, Symbols::_Int32x4(), lib);
  cls = Class::New<Float64x2>();
  object_store->set_float64x2_class(cls);
  RegisterPrivateClass(cls, Symbols::_Float64x2(), lib);

  cls = Class::New<Instance>(kIllegalCid);
  RegisterClass(cls, Symbols::Float32x4(), lib);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_prefinalized();
  pending_classes.Add(cls);
  type = Type::NewNonParameterizedType(cls);
  object_store->set_float32x4_type(type);

  cls = Class::New<Instance>(kIllegalCid);
  RegisterClass(cls, Symbols::Int32x4(), lib);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_prefinalized();
  pending_classes.Add(cls);
  type = Type::NewNonParameterizedType(cls);
  object_store->set_int32x4_type(type);

  cls = Class::New<Instance>(kIllegalCid);
  RegisterClass(cls, Symbols::Float64x2(), lib);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_prefinalized();
  pending_classes.Add(cls);
  type = Type::NewNonParameterizedType(cls);
  object_store->set_float64x2_type(type);

  // Set the super type of class Stacktrace to Object type so that the
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
  RegisterClass(cls, Symbols::Double(), core_lib);
  cls.set_num_type_arguments(0);
  cls.set_num_own_type_arguments(0);
  cls.set_is_prefinalized();
  pending_classes.Add(cls);
  type = Type::NewNonParameterizedType(cls);
  object_store->set_double_type(type);

  name = Symbols::New("String");
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

  // The classes 'void' and 'dynamic' are phoney classes to make type checking
  // more regular; they live in the VM isolate. The class 'void' is not
  // registered in the class dictionary because its name is a reserved word.
  // The class 'dynamic' is registered in the class dictionary because its name
  // is a built-in identifier (this is wrong).
  // The corresponding types are stored in the object store.
  cls = object_store->null_class();
  type = Type::NewNonParameterizedType(cls);
  object_store->set_null_type(type);

  // Consider removing when/if Null becomes an ordinary class.
  type = object_store->object_type();
  cls.set_super_type(type);

  // Finish the initialization by compiling the bootstrap scripts containing the
  // base interfaces and the implementation of the internal classes.
  const Error& error = Error::Handle(Bootstrap::LoadandCompileScripts());
  if (!error.IsNull()) {
    return error.raw();
  }

  ClassFinalizer::VerifyBootstrapClasses();

  // Set up the intrinsic state of all functions (core, math and typed data).
  Intrinsifier::InitializeState();

  // Set up recognized state of all functions (core, math and typed data).
  MethodRecognizer::InitializeState();

  // Adds static const fields (class ids) to the class 'ClassID');
  lib = Library::LookupLibrary(Symbols::DartInternal());
  ASSERT(!lib.IsNull());
  cls = lib.LookupClassAllowPrivate(Symbols::ClassID());
  ASSERT(!cls.IsNull());
  Field& field = Field::Handle(isolate);
  Smi& value = Smi::Handle(isolate);
  String& field_name = String::Handle(isolate);

#define CLASS_LIST_WITH_NULL(V)                                                \
  V(Null)                                                                      \
  CLASS_LIST_NO_OBJECT(V)

#define ADD_SET_FIELD(clazz)                                                   \
  field_name = Symbols::New("cid"#clazz);                                      \
  field = Field::New(field_name, true, false, true, false, cls, 0);            \
  value = Smi::New(k##clazz##Cid);                                             \
  field.SetStaticValue(value, true);                                           \
  field.set_type(Type::Handle(Type::IntType()));                               \
  cls.AddField(field);                                                         \

  CLASS_LIST_WITH_NULL(ADD_SET_FIELD)
#undef ADD_SET_FIELD

  isolate->object_store()->InitKnownObjects();

  return Error::null();
#else  // defined(DART_NO_SNAPSHOT).
  // Object::Init version when we are running in a version of dart that has
  // a full snapshot linked in and an isolate is initialized using the full
  // snapshot.
  ObjectStore* object_store = isolate->object_store();

  Class& cls = Class::Handle();

  // Set up empty classes in the object store, these will get
  // initialized correctly when we read from the snapshot.
  // This is done to allow bootstrapping of reading classes from the snapshot.
  // Some classes are not stored in the object store. Yet we still need to
  // create their Class object so that they get put into the class_table
  // (as a side effect of Class::New()).

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
  cls = Class::NewTypedDataViewClass(kByteDataViewCid);
#undef REGISTER_TYPED_DATA_VIEW_CLASS
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
  cls = Class::New<Stacktrace>();
  cls = Class::New<JSRegExp>();
  cls = Class::New<Number>();

  cls = Class::New<WeakProperty>();
  object_store->set_weak_property_class(cls);

  cls = Class::New<MirrorReference>();
  cls = Class::New<UserTag>();

  const Context& context = Context::Handle(isolate,
                                           Context::New(0, Heap::kOld));
  object_store->set_empty_context(context);

#endif  // defined(DART_NO_SNAPSHOT).

  return Error::null();
}


void Object::Print() const {
  THR_Print("%s\n", ToCString());
}


static void AddNameProperties(JSONObject* jsobj,
                              const String& name,
                              const String& vm_name) {
  jsobj->AddProperty("name", name.ToCString());
  if (!name.Equals(vm_name)) {
    jsobj->AddProperty("_vmName", vm_name.ToCString());
  }
}


void Object::AddCommonObjectProperties(JSONObject* jsobj,
                                       const char* protocol_type,
                                       bool ref) const {
  const char* vm_type = JSONType();
  bool same_type = (strcmp(protocol_type, vm_type) == 0);
  if (ref) {
    jsobj->AddPropertyF("type", "@%s", protocol_type);
  } else {
    jsobj->AddProperty("type", protocol_type);
  }
  if (!same_type) {
    jsobj->AddProperty("_vmType", vm_type);
  }
  if (!ref || IsInstance() || IsNull()) {
    // TODO(turnidge): Provide the type arguments here too?
    const Class& cls = Class::Handle(this->clazz());
    jsobj->AddProperty("class", cls);
  }
  if (!ref) {
    if (raw()->IsHeapObject()) {
      jsobj->AddProperty("size", raw()->Size());
    } else {
      jsobj->AddProperty("size", (intptr_t)0);
    }
  }
}


void Object::PrintJSON(JSONStream* stream, bool ref) const {
  if (IsNull()) {
    JSONObject jsobj(stream);
    AddCommonObjectProperties(&jsobj, "Instance", ref);
    jsobj.AddProperty("kind", "Null");
    jsobj.AddFixedServiceId("objects/null");
    jsobj.AddProperty("valueAsString", "null");
  } else {
    PrintJSONImpl(stream, ref);
  }
}


void Object::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
}


RawString* Object::DictionaryName() const {
  return String::null();
}


void Object::InitializeObject(uword address,
                              intptr_t class_id,
                              intptr_t size,
                              bool is_vm_object) {
  // TODO(iposva): Get a proper halt instruction from the assembler which
  // would be needed here for code objects.
  uword initial_value = reinterpret_cast<uword>(null_);
  uword cur = address;
  uword end = address + size;
  while (cur < end) {
    *reinterpret_cast<uword*>(cur) = initial_value;
    cur += kWordSize;
  }
  uword tags = 0;
  ASSERT(class_id != kIllegalCid);
  tags = RawObject::ClassIdTag::update(class_id, tags);
  tags = RawObject::SizeTag::update(size, tags);
  tags = RawObject::VMHeapObjectTag::update(is_vm_object, tags);
  reinterpret_cast<RawObject*>(address)->tags_ = tags;
  ASSERT(is_vm_object == RawObject::IsVMHeapObject(tags));
  VerifiedMemory::Accept(address, size);
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


RawObject* Object::Allocate(intptr_t cls_id,
                            intptr_t size,
                            Heap::Space space) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate->no_callback_scope_depth() == 0);
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
  ClassTable* class_table = isolate->class_table();
  if (space == Heap::kNew) {
    class_table->UpdateAllocatedNew(cls_id, size);
  } else {
    class_table->UpdateAllocatedOld(cls_id, size);
  }
  const Class& cls = Class::Handle(class_table->At(cls_id));
  if (cls.TraceAllocation(isolate)) {
    Profiler::RecordAllocation(isolate, cls_id);
  }
  NoSafepointScope no_safepoint;
  InitializeObject(address, cls_id, size, (isolate == Dart::vm_isolate()));
  RawObject* raw_obj = reinterpret_cast<RawObject*>(address + kHeapObjectTag);
  ASSERT(cls_id == RawObject::ClassIdTag::decode(raw_obj->ptr()->tags_));
  return raw_obj;
}


class StoreBufferUpdateVisitor : public ObjectPointerVisitor {
 public:
  explicit StoreBufferUpdateVisitor(Thread* thread, RawObject* obj) :
      ObjectPointerVisitor(thread->isolate()), thread_(thread), old_obj_(obj) {
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
  VerifiedMemory::Accept(clone_addr, size);
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
  // TODO(turnidge): This assert fails for the fake kFreeListElement class.
  // Fix this.
  ASSERT(raw_ptr()->name_ != String::null());
  return raw_ptr()->name_;
}


RawString* Class::PrettyName() const {
  return GeneratePrettyName();
}


RawString* Class::UserVisibleName() const {
  ASSERT(raw_ptr()->user_name_ != String::null());
  return raw_ptr()->user_name_;
}


bool Class::IsInFullSnapshot() const {
  NoSafepointScope no_safepoint;
  return raw_ptr()->library_->ptr()->is_in_fullsnapshot_;
}


RawType* Class::SignatureType() const {
  ASSERT(IsSignatureClass());
  Zone* zone = Thread::Current()->zone();
  const Function& function = Function::Handle(zone, signature_function());
  ASSERT(!function.IsNull());
  if (function.signature_class() != raw()) {
    // This class is a function type alias. Return the canonical signature type.
    const Class& canonical_signature_class =
        Class::Handle(zone, function.signature_class());
    return canonical_signature_class.SignatureType();
  }
  const Type& signature_type = Type::Handle(zone, CanonicalType());
  if (!signature_type.IsNull()) {
    return signature_type.raw();
  }
  // A signature class extends class Instance and is parameterized in the same
  // way as the owner class of its non-static signature function.
  // It is not type parameterized if its signature function is static.
  // See Class::NewSignatureClass() for the setup of its type parameters.
  // During type finalization, the type arguments of the super class of the
  // owner class of its signature function will be prepended to the type
  // argument vector. Therefore, we only need to set the type arguments
  // matching the type parameters here.
  const TypeArguments& signature_type_arguments =
      TypeArguments::Handle(zone, type_parameters());
  // Return the still unfinalized signature type.
  return Type::New(*this, signature_type_arguments, token_pos());
}


RawAbstractType* Class::RareType() const {
  const Type& type = Type::Handle(Type::New(
      *this,
      Object::null_type_arguments(),
      Scanner::kNoSourcePos));
  return ClassFinalizer::FinalizeType(*this,
                                      type,
                                      ClassFinalizer::kCanonicalize);
}


RawAbstractType* Class::DeclarationType() const {
  const TypeArguments& args = TypeArguments::Handle(type_parameters());
  const Type& type = Type::Handle(Type::New(
      *this,
      args,
      Scanner::kNoSourcePos));
  return ClassFinalizer::FinalizeType(*this,
                                      type,
                                      ClassFinalizer::kCanonicalize);
}


template <class FakeObject>
RawClass* Class::New() {
  ASSERT(Object::class_class() != Class::null());
  Class& result = Class::Handle();
  {
    RawObject* raw = Object::Allocate(Class::kClassId,
                                      Class::InstanceSize(),
                                      Heap::kOld);
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
  if (FakeObject::kClassId < kInstanceCid) {
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
  result.set_token_pos(Scanner::kNoSourcePos);
  result.InitEmptyFields();
  Isolate::Current()->RegisterClass(result);
  return result.raw();
}



static void ReportTooManyTypeArguments(const Class& cls) {
  Report::MessageF(Report::kError,
                   Script::Handle(cls.script()),
                   cls.token_pos(),
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


RawArray* Class::OffsetToFieldMap() const {
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
        if (!f.is_static()) {
          array.SetAt(f.Offset() >> kWordSizeLog2, f);
        }
      }
      cls = cls.SuperClass();
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
  static uword Hash(const FunctionName& name) {
    return name.Hash();
  }
};
typedef UnorderedHashSet<ClassFunctionsTraits> ClassFunctionsSet;


void Class::SetFunctions(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->functions_, value.raw());
  const intptr_t len = value.Length();
  ClassFunctionsSet set(HashTables::New<ClassFunctionsSet>(len, Heap::kOld));
  if (len >= kFunctionLookupHashTreshold) {
    Function& func = Function::Handle();
    for (intptr_t i = 0; i < len; ++i) {
      func ^= value.At(i);
      // Verify that all the functions in the array have this class as owner.
      ASSERT(func.Owner() == raw());
      set.Insert(func);
    }
  }
  StorePointer(&raw_ptr()->functions_hash_table_, set.Release().raw());
}


void Class::AddFunction(const Function& function) const {
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
  const Array& arr = Array::Handle(functions());
  StorePointer(&raw_ptr()->functions_, Object::empty_array().raw());
  Function& entry = Function::Handle();
  for (intptr_t i = 0; i < arr.Length(); i++) {
    entry ^= arr.At(i);
    if (function.raw() != entry.raw()) {
      AddFunction(entry);
    }
  }
}


intptr_t Class::FindFunctionIndex(const Function& needle) const {
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return -1;
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_FUNCTION_HANDLESCOPE(isolate);
  Array& funcs = isolate->ArrayHandle();
  Function& function = isolate->FunctionHandle();
  funcs ^= functions();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  for (intptr_t i = 0; i < len; i++) {
    function ^= funcs.At(i);
    if (function.raw() == needle.raw()) {
      return i;
    }
  }
  // No function found.
  return -1;
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
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return -1;
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_FUNCTION_HANDLESCOPE(isolate);
  Array& funcs = isolate->ArrayHandle();
  Function& function = isolate->FunctionHandle();
  funcs ^= functions();
  ASSERT(!funcs.IsNull());
  Function& implicit_closure = Function::Handle(isolate);
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
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return -1;
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Array& funcs = isolate->ArrayHandle();
  Object& object = isolate->ObjectHandle();
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
  Isolate* isolate = Isolate::Current();
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Array& dispatcher_cache = isolate->ArrayHandle();
  Object& object = isolate->ObjectHandle();
  dispatcher_cache ^= invocation_dispatcher_cache();
  object = dispatcher_cache.At(idx);
  if (!object.IsFunction()) {
    return Function::null();
  }
  return Function::Cast(object).raw();
}


void Class::AddClosureFunction(const Function& function) const {
  GrowableObjectArray& closures =
      GrowableObjectArray::Handle(raw_ptr()->closure_functions_);
  if (closures.IsNull()) {
    closures = GrowableObjectArray::New(4, Heap::kOld);
    StorePointer(&raw_ptr()->closure_functions_, closures.raw());
  }
  ASSERT(function.IsNonImplicitClosureFunction());
  ASSERT(function.Owner() == this->raw());
  closures.Add(function, Heap::kOld);
}


// Lookup the innermost closure function that contains token at token_pos.
RawFunction* Class::LookupClosureFunction(intptr_t token_pos) const {
  if (raw_ptr()->closure_functions_ == GrowableObjectArray::null()) {
    return Function::null();
  }
  const GrowableObjectArray& closures =
      GrowableObjectArray::Handle(raw_ptr()->closure_functions_);
  Function& closure = Function::Handle();
  intptr_t num_closures = closures.Length();
  intptr_t best_fit_token_pos = -1;
  intptr_t best_fit_index = -1;
  for (intptr_t i = 0; i < num_closures; i++) {
    closure ^= closures.At(i);
    ASSERT(!closure.IsNull());
    if ((closure.token_pos() <= token_pos) &&
        (token_pos <= closure.end_token_pos()) &&
        (best_fit_token_pos < closure.token_pos())) {
      best_fit_index = i;
      best_fit_token_pos = closure.token_pos();
    }
  }
  closure = Function::null();
  if (best_fit_index >= 0) {
    closure ^= closures.At(best_fit_index);
  }
  return closure.raw();
}

intptr_t Class::FindClosureIndex(const Function& needle) const {
  if (closures() == GrowableObjectArray::null()) {
    return -1;
  }
  Isolate* isolate = Isolate::Current();
  const GrowableObjectArray& closures_array =
      GrowableObjectArray::Handle(isolate, closures());
  REUSABLE_FUNCTION_HANDLESCOPE(isolate);
  Function& closure = isolate->FunctionHandle();
  intptr_t num_closures = closures_array.Length();
  for (intptr_t i = 0; i < num_closures; i++) {
    closure ^= closures_array.At(i);
    ASSERT(!closure.IsNull());
    if (closure.raw() == needle.raw()) {
      return i;
    }
  }
  return -1;
}


RawFunction* Class::ClosureFunctionFromIndex(intptr_t idx) const {
  const GrowableObjectArray& closures_array =
      GrowableObjectArray::Handle(closures());
  if ((idx < 0) || (idx >= closures_array.Length())) {
    return Function::null();
  }
  Function& func = Function::Handle();
  func ^= closures_array.At(idx);
  ASSERT(!func.IsNull());
  return func.raw();
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


intptr_t Class::NumTypeParameters(Isolate* isolate) const {
  if (IsMixinApplication() && !is_mixin_type_applied()) {
    ClassFinalizer::ApplyMixinType(*this);
  }
  if (type_parameters() == TypeArguments::null()) {
    return 0;
  }
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(isolate);
  TypeArguments& type_params = isolate->TypeArgumentsHandle();
  type_params = type_parameters();
  return type_params.Length();
}


intptr_t Class::NumOwnTypeArguments() const {
  // Return cached value if already calculated.
  if (num_own_type_arguments() != kUnknownNumTypeArguments) {
    return num_own_type_arguments();
  }
  Isolate* isolate = Isolate::Current();
  const intptr_t num_type_params = NumTypeParameters();
  if (!FLAG_overlap_type_arguments ||
      (num_type_params == 0) ||
      (super_type() == AbstractType::null()) ||
      (super_type() == isolate->object_store()->object_type())) {
    set_num_own_type_arguments(num_type_params);
    return num_type_params;
  }
  ASSERT(!IsMixinApplication() || is_mixin_type_applied());
  const AbstractType& sup_type = AbstractType::Handle(isolate, super_type());
  const TypeArguments& sup_type_args =
      TypeArguments::Handle(isolate, sup_type.arguments());
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
      TypeArguments::Handle(isolate, type_parameters());
  // Determine the maximum overlap of a prefix of the vector consisting of the
  // type parameters of this class with a suffix of the vector consisting of the
  // type arguments of the super type of this class.
  // The number of own type arguments of this class is the number of its type
  // parameters minus the number of type arguments in the overlap.
  // Attempt to overlap the whole vector of type parameters; reduce the size
  // of the vector (keeping the first type parameter) until it fits or until
  // its size is zero.
  TypeParameter& type_param = TypeParameter::Handle(isolate);
  AbstractType& sup_type_arg = AbstractType::Handle(isolate);
  for (intptr_t num_overlapping_type_args =
           (num_type_params < num_sup_type_args) ?
               num_type_params : num_sup_type_args;
       num_overlapping_type_args > 0; num_overlapping_type_args--) {
    intptr_t i = 0;
    for (; i < num_overlapping_type_args; i++) {
      type_param ^= type_params.TypeAt(i);
      sup_type_arg = sup_type_args.TypeAt(
          num_sup_type_args - num_overlapping_type_args + i);
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


bool Class::IsGeneric() const {
  return NumTypeParameters() != 0;
}


intptr_t Class::NumTypeArguments() const {
  // Return cached value if already calculated.
  if (num_type_arguments() != kUnknownNumTypeArguments) {
    return num_type_arguments();
  }
  // To work properly, this call requires the super class of this class to be
  // resolved, which is checked by the type_class() call on the super type.
  // Note that calling type_class() on a MixinAppType fails.
  Isolate* isolate = Isolate::Current();
  Class& cls = Class::Handle(isolate);
  AbstractType& sup_type = AbstractType::Handle(isolate);
  cls = raw();
  intptr_t num_type_args = 0;
  do {
    if (cls.IsSignatureClass()) {
      Function& signature_fun = Function::Handle(isolate);
      signature_fun ^= cls.signature_function();
      if (!signature_fun.is_static() &&
          !signature_fun.HasInstantiatedSignature()) {
        cls = signature_fun.Owner();
      }
    }
    // Calling NumOwnTypeArguments() on a mixin application class will setup the
    // type parameters if not already done.
    num_type_args += cls.NumOwnTypeArguments();
    // Super type of Object class is null.
    if ((cls.super_type() == AbstractType::null()) ||
        (cls.super_type() == isolate->object_store()->object_type())) {
      break;
    }
    sup_type = cls.super_type();
    ClassFinalizer::ResolveTypeClass(cls, sup_type);
    cls = sup_type.type_class();
  } while (true);
  set_num_type_arguments(num_type_args);
  return num_type_args;
}


RawClass* Class::SuperClass() const {
  if (super_type() == AbstractType::null()) {
    return Class::null();
  }
  const AbstractType& sup_type = AbstractType::Handle(super_type());
  return sup_type.type_class();
}


void Class::set_super_type(const AbstractType& value) const {
  ASSERT(value.IsNull() ||
         (value.IsType() && !value.IsDynamicType()) ||
         value.IsMixinAppType());
  StorePointer(&raw_ptr()->super_type_, value.raw());
}


// Return a TypeParameter if the type_name is a type parameter of this class.
// Return null otherwise.
RawTypeParameter* Class::LookupTypeParameter(const String& type_name) const {
  ASSERT(!type_name.IsNull());
  Isolate* isolate = Isolate::Current();
  REUSABLE_TYPE_ARGUMENTS_HANDLESCOPE(isolate);
  REUSABLE_TYPE_PARAMETER_HANDLESCOPE(isolate);
  REUSABLE_STRING_HANDLESCOPE(isolate);
  TypeArguments& type_params = isolate->TypeArgumentsHandle();
  TypeParameter&  type_param = isolate->TypeParameterHandle();
  String& type_param_name = isolate->StringHandle();

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
                                            RawFunction::Kind kind) const {
  enum {
    kNameIndex = 0,
    kArgsDescIndex,
    kFunctionIndex,
    kEntrySize
  };

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

  if (dispatcher.IsNull()) {
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
  Function& invocation = Function::Handle(
      Function::New(String::Handle(Symbols::New(target_name)),
                    kind,
                    false,  // Not static.
                    false,  // Not const.
                    false,  // Not abstract.
                    false,  // Not external.
                    false,  // Not native.
                    *this,
                    0));  // No token position.
  ArgumentsDescriptor desc(args_desc);
  invocation.set_num_fixed_parameters(desc.PositionalCount());
  invocation.SetNumOptionalParameters(desc.NamedCount(),
                                      false);  // Not positional.
  invocation.set_parameter_types(Array::Handle(Array::New(desc.Count(),
                                                          Heap::kOld)));
  invocation.set_parameter_names(Array::Handle(Array::New(desc.Count(),
                                                          Heap::kOld)));
  // Receiver.
  invocation.SetParameterTypeAt(0, Type::Handle(Type::DynamicType()));
  invocation.SetParameterNameAt(0, Symbols::This());
  // Remaining positional parameters.
  intptr_t i = 1;
  for (; i < desc.PositionalCount(); i++) {
    invocation.SetParameterTypeAt(i, Type::Handle(Type::DynamicType()));
    char name[64];
    OS::SNPrint(name, 64, ":p%" Pd, i);
    invocation.SetParameterNameAt(i, String::Handle(Symbols::New(name)));
  }

  // Named parameters.
  for (; i < desc.Count(); i++) {
    invocation.SetParameterTypeAt(i, Type::Handle(Type::DynamicType()));
    intptr_t index = i - desc.PositionalCount();
    invocation.SetParameterNameAt(i, String::Handle(desc.NameAt(index)));
  }
  invocation.set_result_type(Type::Handle(Type::DynamicType()));
  invocation.set_is_debuggable(false);
  invocation.set_is_visible(false);
  invocation.set_is_reflectable(false);
  invocation.set_saved_args_desc(args_desc);

  return invocation.raw();
}


RawArray* Class::invocation_dispatcher_cache() const {
  return raw_ptr()->invocation_dispatcher_cache_;
}


void Class::set_invocation_dispatcher_cache(const Array& cache) const {
  StorePointer(&raw_ptr()->invocation_dispatcher_cache_, cache.raw());
}


void Class::Finalize() const {
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
      : WeakCodeReferences(Array::Handle(cls.cha_codes())), cls_(cls) {
  }

  virtual void UpdateArrayTo(const Array& value) {
    // TODO(fschneider): Fails for classes in the VM isolate.
    cls_.set_cha_codes(value);
  }

  virtual void ReportDeoptimization(const Code& code) {
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      Function& function = Function::Handle(code.function());
      THR_Print("Deoptimizing %s because CHA optimized (%s).\n",
          function.ToFullyQualifiedCString(),
          cls_.ToCString());
    }
  }

  virtual void ReportSwitchingCode(const Code& code) {
    if (FLAG_trace_deoptimization || FLAG_trace_deoptimization_verbose) {
      Function& function = Function::Handle(code.function());
      THR_Print("Switching %s to unoptimized code because CHA invalid"
                " (%s)\n",
                function.ToFullyQualifiedCString(),
                cls_.ToCString());
    }
  }

 private:
  const Class& cls_;
  DISALLOW_COPY_AND_ASSIGN(CHACodeArray);
};


void Class::RegisterCHACode(const Code& code) {
  if (FLAG_trace_cha) {
    THR_Print("RegisterCHACode %s class %s\n",
        Function::Handle(code.function()).ToQualifiedCString(), ToCString());
  }
  ASSERT(code.is_optimized());
  CHACodeArray a(*this);
  a.Register(code);
}


void Class::DisableCHAOptimizedCode() {
  CHACodeArray a(*this);
  a.DisableCode();
}


bool Class::TraceAllocation(Isolate* isolate) const {
  ClassTable* class_table = isolate->class_table();
  return class_table->TraceAllocationFor(id());
}


void Class::SetTraceAllocation(bool trace_allocation) const {
  Isolate* isolate = Isolate::Current();
  const bool changed = trace_allocation != this->TraceAllocation(isolate);
  if (changed) {
    ClassTable* class_table = isolate->class_table();
    class_table->SetTraceAllocationFor(id(), trace_allocation);
    DisableAllocationStub();
  }
}


void Class::set_cha_codes(const Array& cache) const {
  StorePointer(&raw_ptr()->cha_codes_, cache.raw());
}


// Apply the members from the patch class to the original class.
bool Class::ApplyPatch(const Class& patch, Error* error) const {
  ASSERT(error != NULL);
  ASSERT(!is_finalized());
  // Shared handles used during the iteration.
  String& member_name = String::Handle();

  const PatchClass& patch_class =
      PatchClass::Handle(PatchClass::New(*this, patch));

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
  const GrowableObjectArray& new_functions = GrowableObjectArray::Handle(
      GrowableObjectArray::New(orig_len));
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
               orig_func.UserVisibleSignature()) {
      // Compare user visible signatures to ignore different implicit parameters
      // when patching a constructor with a factory.
      *error = LanguageError::NewFormatted(
          *error,  // No previous error.
          Script::Handle(patch.script()),
          func.token_pos(),
          Report::kError,
          Heap::kNew,
          "signature mismatch: '%s'", member_name.ToCString());
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
  Array& new_list = Array::Handle(Array::MakeArray(new_functions));
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
          Script::Handle(patch.script()),
          field.token_pos(),
          Report::kError,
          Heap::kNew,
          "duplicate field: %s", member_name.ToCString());
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
  patch.SetFunctions(Object::empty_array());
  patch.SetFields(Object::empty_array());
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
  return String::ConcatAll(Array::Handle(Array::MakeArray(src_pieces)));
}


static RawFunction* EvaluateHelper(const Class& cls,
                                   const String& expr,
                                   const Array& param_names,
                                   bool is_static) {
  const String& func_src =
      String::Handle(BuildClosureSource(param_names, expr));
  Script& script = Script::Handle();
  script = Script::New(Symbols::EvalSourceUri(),
                       func_src,
                       RawScript::kEvaluateTag);
  // In order to tokenize the source, we need to get the key to mangle
  // private names from the library from which the class originates.
  const Library& lib = Library::Handle(cls.library());
  ASSERT(!lib.IsNull());
  const String& lib_key = String::Handle(lib.private_key());
  script.Tokenize(lib_key);

  const Function& func = Function::Handle(
       Function::NewEvalFunction(cls, script, is_static));
  func.set_result_type(Type::Handle(Type::DynamicType()));
  const intptr_t num_implicit_params = is_static ? 0 : 1;
  func.set_num_fixed_parameters(num_implicit_params + param_names.Length());
  func.SetNumOptionalParameters(0, true);
  func.SetIsOptimizable(false);
  return func.raw();
}


RawObject* Class::Evaluate(const String& expr,
                           const Array& param_names,
                           const Array& param_values) const {
  const Function& eval_func =
      Function::Handle(EvaluateHelper(*this, expr, param_names, true));
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(eval_func, param_values));
  return result.raw();
}


// Ensure that top level parsing of the class has been done.
// TODO(24109): Migrate interface to Thread*.
RawError* Class::EnsureIsFinalized(Isolate* isolate) const {
  // Finalized classes have already been parsed.
  if (is_finalized()) {
    return Error::null();
  }
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(isolate, Compiler::CompileClass(*this));
  if (!error.IsNull()) {
    ASSERT(isolate == Thread::Current()->isolate());
    if (Thread::Current()->long_jump_base() != NULL) {
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
    ASSERT(field.owner() == raw());
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


intptr_t Class::FindFieldIndex(const Field& needle) const {
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return -1;
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_FIELD_HANDLESCOPE(isolate);
  REUSABLE_STRING_HANDLESCOPE(isolate);
  Array& fields_array = isolate->ArrayHandle();
  Field& field = isolate->FieldHandle();
  String& field_name = isolate->StringHandle();
  fields_array ^= fields();
  ASSERT(!fields_array.IsNull());
  String& needle_name = String::Handle(isolate);
  needle_name ^= needle.name();
  const intptr_t len = fields_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    field ^= fields_array.At(i);
    field_name ^= field.name();
    if (field_name.Equals(needle_name)) {
      return i;
    }
  }
  // No field found.
  return -1;
}


RawField* Class::FieldFromIndex(intptr_t idx) const {
  const Array& flds = Array::Handle(fields());
  if ((idx < 0) || (idx >= flds.Length())) {
    return Field::null();
  }
  Field& field = Field::Handle();
  field ^= flds.At(idx);
  ASSERT(!field.IsNull());
  return field.raw();
}


template <class FakeInstance>
RawClass* Class::New(intptr_t index) {
  ASSERT(Object::class_class() != Class::null());
  Class& result = Class::Handle();
  {
    RawObject* raw = Object::Allocate(Class::kClassId,
                                      Class::InstanceSize(),
                                      Heap::kOld);
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
  result.set_token_pos(Scanner::kNoSourcePos);
  result.InitEmptyFields();
  Isolate::Current()->RegisterClass(result);
  return result.raw();
}


RawClass* Class::New(const String& name,
                     const Script& script,
                     intptr_t token_pos) {
  Class& result = Class::Handle(New<Instance>(kIllegalCid));
  result.set_name(name);
  result.set_script(script);
  result.set_token_pos(token_pos);
  return result.raw();
}


RawClass* Class::NewSignatureClass(const String& name,
                                   const Function& signature_function,
                                   const Script& script,
                                   intptr_t token_pos) {
  const Class& result = Class::Handle(New(name, script, token_pos));
  // Instances of a signature class can only be closures.
  result.set_instance_size(Closure::InstanceSize());
  result.set_next_field_offset(Closure::NextFieldOffset());
  // Signature classes extend the _FunctionImpl class.
  result.set_super_type(Type::Handle(
      Isolate::Current()->object_store()->function_impl_type()));
  result.set_is_synthesized_class();
  result.set_type_arguments_field_offset(Closure::type_arguments_offset());
  if (!signature_function.IsNull()) {
    result.PatchSignatureFunction(signature_function);
  }
  return result.raw();
}


void Class::PatchSignatureFunction(const Function& signature_function) const {
  ASSERT(!signature_function.IsNull());
  set_signature_function(signature_function);
  const Class& owner_class = Class::Handle(signature_function.Owner());
  ASSERT(!owner_class.IsNull());
  // A signature class extends class Instance and is either not parameterized or
  // parameterized with exactly the same list of type parameters as the owner
  // class of its function.
  // In case of a function type alias, the function owner is the alias class,
  // which is also the signature class. The signature class is therefore
  // parameterized according to the alias class declaration, even if the
  // function type is not generic.
  // Otherwise, if the function is static or if its signature type is
  // non-generic, i.e. it does not depend on any type parameter of the owner
  // class, then the signature class is not parameterized, although the owner
  // class may be.
  if (owner_class.raw() == raw()) {
    // This signature class is an alias, which cannot be the canonical
    // signature class for this signature function.
    ASSERT(!IsCanonicalSignatureClass());
    // Do not modify the declared type parameters of the alias, even if unused.
  } else {
    // Copy the type parameters only for an instance function type that is not
    // instantiated, i.e. that depends on the type parameters of the owner
    // class.
    // TODO(regis): Verify that it is not a problem for the copied type
    // parameters to refer to the owner class rather than to the signature
    // class. In other words, uninstantiated function types should only get
    // instantiated by the owner class as instantiator and never by the
    // signature class itself.
    TypeArguments& type_parameters = TypeArguments::Handle();
    if (!signature_function.is_static() &&
        (owner_class.NumTypeParameters() > 0) &&
        !signature_function.HasInstantiatedSignature()) {
      type_parameters = owner_class.type_parameters();
    }
    set_type_parameters(type_parameters);
    if (signature_function.signature_class() == Object::null()) {
      // Make this signature class the canonical signature class.
      signature_function.set_signature_class(*this);
      ASSERT(IsCanonicalSignatureClass());
    }
  }
  set_is_prefinalized();
}


RawClass* Class::NewNativeWrapper(const Library& library,
                                  const String& name,
                                  int field_count) {
  Class& cls = Class::Handle(library.LookupClass(name));
  if (cls.IsNull()) {
    cls = New(name, Script::Handle(), Scanner::kNoSourcePos);
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
  ASSERT(value.IsSymbol());
  StorePointer(&raw_ptr()->name_, value.raw());
  if (raw_ptr()->user_name_ == String::null()) {
    // TODO(johnmccutchan): Eagerly set user name for VM isolate classes,
    // lazily set user name for the other classes.
    // Generate and set user_name.
    const String& user_name = String::Handle(GenerateUserVisibleName());
    set_user_name(user_name);
  }
}


void Class::set_user_name(const String& value) const {
  StorePointer(&raw_ptr()->user_name_, value.raw());
}


RawString* Class::GeneratePrettyName() const {
  if (!IsCanonicalSignatureClass()) {
    const String& name = String::Handle(Name());
    return String::IdentifierPrettyName(name);
  } else {
    return Name();
  }
}


RawString* Class::GenerateUserVisibleName() const {
  if (FLAG_show_internal_names) {
    return Name();
  }
  switch (id()) {
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
    case kPcDescriptorsCid:
      return Symbols::PcDescriptors().raw();
    case kStackmapCid:
      return Symbols::Stackmap().raw();
    case kLocalVarDescriptorsCid:
      return Symbols::LocalVarDescriptors().raw();
    case kExceptionHandlersCid:
      return Symbols::ExceptionHandlers().raw();
    case kContextCid:
      return Symbols::Context().raw();
    case kContextScopeCid:
      return Symbols::ContextScope().raw();
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
    default:
      if (!IsCanonicalSignatureClass()) {
        const String& name = String::Handle(Name());
        return String::IdentifierPrettyName(name);
      } else {
        return Name();
      }
  }
  UNREACHABLE();
}


void Class::set_script(const Script& value) const {
  StorePointer(&raw_ptr()->script_, value.raw());
}


void Class::set_token_pos(intptr_t token_pos) const {
  ASSERT(token_pos >= 0);
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}


intptr_t Class::ComputeEndTokenPos() const {
  // Return the begin token for synthetic classes.
  if (IsSignatureClass() || IsMixinApplication() || IsTopLevel()) {
    return token_pos();
  }
  const Script& scr = Script::Handle(script());
  ASSERT(!scr.IsNull());
  const TokenStream& tkns = TokenStream::Handle(scr.tokens());
  TokenStream::Iterator tkit(
      tkns, token_pos(), TokenStream::Iterator::kNoNewlines);
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
  return 0;
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


void Class::set_is_allocated() const {
  set_state_bits(IsAllocatedBit::update(true, raw_ptr()->state_bits_));
}


void Class::set_is_finalized() const {
  ASSERT(!is_finalized());
  set_state_bits(ClassFinalizedBits::update(RawClass::kFinalized,
                                            raw_ptr()->state_bits_));
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


void Class::set_patch_class(const Class& cls) const {
  ASSERT(patch_class() == Class::null());
  StorePointer(&raw_ptr()->patch_class_, cls.raw());
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


RawArray* Class::constants() const {
  return raw_ptr()->constants_;
}

void Class::set_constants(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->constants_, value.raw());
}


RawObject* Class::canonical_types() const {
  return raw_ptr()->canonical_types_;
}


void Class::set_canonical_types(const Object& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->canonical_types_, value.raw());
}


RawType* Class::CanonicalType() const {
  if (NumTypeArguments() == 0) {
    return reinterpret_cast<RawType*>(raw_ptr()->canonical_types_);
  }
  Array& types = Array::Handle();
  types ^= canonical_types();
  if (!types.IsNull() && (types.Length() > 0)) {
    return reinterpret_cast<RawType*>(types.At(0));
  }
  return reinterpret_cast<RawType*>(Object::null());
}


void Class::SetCanonicalType(const Type& type) const {
  ASSERT(type.IsCanonical());
  if (NumTypeArguments() == 0) {
    ASSERT((canonical_types() == Object::null()) ||
           (canonical_types() == type.raw()));  // Set during own finalization.
    set_canonical_types(type);
  } else {
    Array& types = Array::Handle();
    types ^= canonical_types();
    ASSERT(!types.IsNull() && (types.Length() > 1));
    ASSERT((types.At(0) == Object::null()) || (types.At(0) == type.raw()));
    types.SetAt(0, type);
  }
}


intptr_t Class::FindCanonicalTypeIndex(const Type& needle) const {
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return -1;
  }
  if (needle.raw() == CanonicalType()) {
    // For a generic type or signature type, there exists another index with the
    // same type. It will never be returned by this function.
    return 0;
  }
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  Object& types = isolate->ObjectHandle();
  types = canonical_types();
  if (types.IsNull()) {
    return -1;
  }
  const intptr_t len = Array::Cast(types).Length();
  REUSABLE_ABSTRACT_TYPE_HANDLESCOPE(isolate);
  AbstractType& type = isolate->AbstractTypeHandle();
  for (intptr_t i = 0; i < len; i++) {
    type ^= Array::Cast(types).At(i);
    if (needle.raw() == type.raw()) {
      return i;
    }
  }
  // No type found.
  return -1;
}


RawType* Class::CanonicalTypeFromIndex(intptr_t idx) const {
  Type& type = Type::Handle();
  if (idx == 0) {
    type = CanonicalType();
    if (!type.IsNull()) {
      return type.raw();
    }
  }
  Object& types = Object::Handle(canonical_types());
  if (types.IsNull() || !types.IsArray()) {
    return Type::null();
  }
  if ((idx < 0) || (idx >= Array::Cast(types).Length())) {
    return Type::null();
  }
  type ^= Array::Cast(types).At(idx);
  ASSERT(!type.IsNull());
  return type.raw();
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
  ASSERT(!CodePatcher::IsEntryPatched(existing_stub));
  // Patch the stub so that the next caller will regenerate the stub.
  CodePatcher::PatchEntry(existing_stub);
  // Disassociate the existing stub from class.
  StorePointer(&raw_ptr()->allocation_stub_, Code::null());
}


bool Class::IsFunctionClass() const {
  return raw() == Type::Handle(Type::Function()).type_class();
}


bool Class::IsCanonicalSignatureClass() const {
  const Function& function = Function::Handle(signature_function());
  return (!function.IsNull() && (function.signature_class() == raw()));
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
                                 Heap::Space space) {
  // Use the thsi object as if it was the receiver of this method, but instead
  // of recursing reset it to the super class and loop.
  Isolate* isolate = Isolate::Current();
  Class& thsi = Class::Handle(isolate, cls.raw());
  while (true) {
    ASSERT(!thsi.IsVoidClass());
    // Check for DynamicType.
    // Each occurrence of DynamicType in type T is interpreted as the dynamic
    // type, a supertype of all types.
    if (other.IsDynamicClass()) {
      return true;
    }
    // In the case of a subtype test, each occurrence of DynamicType in type S
    // is interpreted as the bottom type, a subtype of all types.
    // However, DynamicType is not more specific than any type.
    if (thsi.IsDynamicClass()) {
      return test_kind == Class::kIsSubtypeOf;
    }
    // Check for NullType, which is only a subtype of ObjectType, of
    // DynamicType, or of itself, and which is more specific than any type.
    if (thsi.IsNullClass()) {
      // We already checked for other.IsDynamicClass() above.
      return (test_kind == Class::kIsMoreSpecificThan) ||
      other.IsObjectClass() || other.IsNullClass();
    }
    // Check for ObjectType. Any type that is not NullType or DynamicType
    // (already checked above), is more specific than ObjectType.
    if (other.IsObjectClass()) {
      return true;
    }
    // Check for reflexivity.
    if (thsi.raw() == other.raw()) {
      const intptr_t num_type_args = thsi.NumTypeArguments();
      if (num_type_args == 0) {
        return true;
      }
      const intptr_t num_type_params = thsi.NumTypeParameters();
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
      return type_arguments.TypeTest(test_kind,
                                     other_type_arguments,
                                     from_index,
                                     num_type_params,
                                     bound_error,
                                     space);
    }
    const bool other_is_function_class = other.IsFunctionClass();
    if (other.IsSignatureClass() || other_is_function_class) {
      const Function& other_fun = Function::Handle(isolate,
                                                   other.signature_function());
      if (thsi.IsSignatureClass()) {
        if (other_is_function_class) {
          return true;
        }
        // Check for two function types.
        const Function& fun =
            Function::Handle(isolate, thsi.signature_function());
        return fun.TypeTest(test_kind,
                            type_arguments,
                            other_fun,
                            other_type_arguments,
                            bound_error,
                            space);
      }
      // Check if type S has a call() method of function type T.
      Function& function =
          Function::Handle(isolate,
                           thsi.LookupDynamicFunction(Symbols::Call()));
      if (function.IsNull()) {
        // Walk up the super_class chain.
        Class& cls = Class::Handle(isolate, thsi.SuperClass());
        while (!cls.IsNull() && function.IsNull()) {
          function = cls.LookupDynamicFunction(Symbols::Call());
          cls = cls.SuperClass();
        }
      }
      if (!function.IsNull()) {
        if (other_is_function_class ||
            function.TypeTest(test_kind,
                              type_arguments,
                              other_fun,
                              other_type_arguments,
                              bound_error,
                              space)) {
              return true;
            }
      }
    }
    // Check for 'direct super type' specified in the implements clause
    // and check for transitivity at the same time.
    Array& interfaces = Array::Handle(isolate, thsi.interfaces());
    AbstractType& interface = AbstractType::Handle(isolate);
    Class& interface_class = Class::Handle(isolate);
    TypeArguments& interface_args = TypeArguments::Handle(isolate);
    Error& error = Error::Handle(isolate);
    for (intptr_t i = 0; i < interfaces.Length(); i++) {
      interface ^= interfaces.At(i);
      if (!interface.IsFinalized()) {
        // We may be checking bounds at finalization time and can encounter
        // a still unfinalized interface.
        ClassFinalizer::FinalizeType(
            thsi, interface, ClassFinalizer::kCanonicalize);
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
        interface_args =
            interface_args.InstantiateFrom(type_arguments, &error, NULL, space);
        if (!error.IsNull()) {
          // Return the first bound error to the caller if it requests it.
          if ((bound_error != NULL) && bound_error->IsNull()) {
            *bound_error = error.raw();
          }
          continue;  // Another interface may work better.
        }
      }
      if (interface_class.TypeTest(test_kind,
                                   interface_args,
                                   other,
                                   other_type_arguments,
                                   bound_error,
                                   space)) {
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
                     Heap::Space space) const {
  return TypeTestNonRecursive(*this,
                              test_kind,
                              type_arguments,
                              other,
                              other_type_arguments,
                              bound_error,
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
  if (kind == kInstance) {
    if (func.IsDynamicFunction()) {
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
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return Function::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_FUNCTION_HANDLESCOPE(isolate);
  Array& funcs = isolate->ArrayHandle();
  funcs ^= functions();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  Function& function = isolate->FunctionHandle();
  if (len >= kFunctionLookupHashTreshold) {
    ClassFunctionsSet set(raw_ptr()->functions_hash_table_);
    REUSABLE_STRING_HANDLESCOPE(isolate);
    function ^= set.GetOrNull(FunctionName(name, &(isolate->StringHandle())));
    // No mutations.
    ASSERT(set.Release().raw() == raw_ptr()->functions_hash_table_);
    return function.IsNull() ? Function::null()
                             : CheckFunctionType(function, kind);
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
    REUSABLE_STRING_HANDLESCOPE(isolate);
    String& function_name = isolate->StringHandle();
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
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return Function::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_FUNCTION_HANDLESCOPE(isolate);
  REUSABLE_STRING_HANDLESCOPE(isolate);
  Array& funcs = isolate->ArrayHandle();
  funcs ^= functions();
  ASSERT(!funcs.IsNull());
  const intptr_t len = funcs.Length();
  Function& function = isolate->FunctionHandle();
  String& function_name = isolate->StringHandle();
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
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return Function::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_FUNCTION_HANDLESCOPE(isolate);
  REUSABLE_STRING_HANDLESCOPE(isolate);
  Array& funcs = isolate->ArrayHandle();
  funcs ^= functions();
  intptr_t len = funcs.Length();
  Function& function = isolate->FunctionHandle();
  String& function_name = isolate->StringHandle();
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


RawFunction* Class::LookupFunctionAtToken(intptr_t token_pos) const {
  // TODO(hausner): we can shortcut the negative case if we knew the
  // beginning and end token position of the class.
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return Function::null();
  }
  Function& func = Function::Handle(isolate);
  func = LookupClosureFunction(token_pos);
  if (!func.IsNull()) {
    return func.raw();
  }
  Array& funcs = Array::Handle(isolate, functions());
  intptr_t len = funcs.Length();
  for (intptr_t i = 0; i < len; i++) {
    func ^= funcs.At(i);
    if ((func.token_pos() <= token_pos) &&
        (token_pos <= func.end_token_pos())) {
      return func.raw();
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
  Isolate* isolate = Isolate::Current();
  if (EnsureIsFinalized(isolate) != Error::null()) {
    return Field::null();
  }
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_FIELD_HANDLESCOPE(isolate);
  REUSABLE_STRING_HANDLESCOPE(isolate);
  Array& flds = isolate->ArrayHandle();
  flds ^= fields();
  ASSERT(!flds.IsNull());
  intptr_t len = flds.Length();
  Field& field = isolate->FieldHandle();
  String& field_name = isolate->StringHandle();
  for (intptr_t i = 0; i < len; i++) {
    field ^= flds.At(i);
    field_name ^= field.name();
    if (String::EqualsIgnoringPrivateKey(field_name, name)) {
      if (kind == kInstance) {
        if (!field.is_static()) {
          return field.raw();
        }
      } else if (kind == kStatic) {
        if (field.is_static()) {
          return field.raw();
        }
      } else if (kind == kAny) {
        return field.raw();
      }
      return Field::null();
    }
  }
  // No field found.
  return Field::null();
}


RawLibraryPrefix* Class::LookupLibraryPrefix(const String& name) const {
  Isolate* isolate = Isolate::Current();
  const Library& lib = Library::Handle(isolate, library());
  const Object& obj = Object::Handle(isolate, lib.LookupLocalObject(name));
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
  return OS::SCreate(Thread::Current()->zone(),
      "%s %sClass: %s", library_name, patch_prefix, class_name);
}


void Class::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Isolate* isolate = Isolate::Current();
  JSONObject jsobj(stream);
  if ((raw() == Class::null()) || (id() == kFreeListElement)) {
    // TODO(turnidge): This is weird and needs to be changed.
    jsobj.AddProperty("type", "null");
    return;
  }
  AddCommonObjectProperties(&jsobj, "Class", ref);
  jsobj.AddFixedServiceId("classes/%" Pd "", id());
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name, vm_name);
  if (ref) {
    return;
  }

  const Error& err = Error::Handle(EnsureIsFinalized(Isolate::Current()));
  if (!err.IsNull()) {
    jsobj.AddProperty("error", err);
  }
  jsobj.AddProperty("abstract", is_abstract());
  jsobj.AddProperty("const", is_const());
  jsobj.AddProperty("_finalized", is_finalized());
  jsobj.AddProperty("_implemented", is_implemented());
  jsobj.AddProperty("_patch", is_patch());
  jsobj.AddProperty("_traceAllocations", TraceAllocation(isolate));
  const Class& superClass = Class::Handle(SuperClass());
  if (!superClass.IsNull()) {
    jsobj.AddProperty("super", superClass);
  }
  jsobj.AddProperty("library", Object::Handle(library()));
  const Script& script = Script::Handle(this->script());
  if (!script.IsNull()) {
    jsobj.AddLocation(script, token_pos(), ComputeEndTokenPos());
  }
  {
    JSONArray interfaces_array(&jsobj, "interfaces");
    const Array& interface_array = Array::Handle(interfaces());
    Type& interface_type = Type::Handle();
    if (!interface_array.IsNull()) {
      for (intptr_t i = 0; i < interface_array.Length(); ++i) {
        interface_type ^= interface_array.At(i);
        interfaces_array.AddValue(interface_type);
      }
    }
  }
  {
    JSONArray fields_array(&jsobj, "fields");
    const Array& field_array = Array::Handle(fields());
    Field& field = Field::Handle();
    if (!field_array.IsNull()) {
      for (intptr_t i = 0; i < field_array.Length(); ++i) {
        field ^= field_array.At(i);
        fields_array.AddValue(field);
      }
    }
  }
  {
    JSONArray functions_array(&jsobj, "functions");
    const Array& function_array = Array::Handle(functions());
    Function& function = Function::Handle();
    if (!function_array.IsNull()) {
      for (intptr_t i = 0; i < function_array.Length(); i++) {
        function ^= function_array.At(i);
        functions_array.AddValue(function);
      }
    }
  }
  {
    JSONArray subclasses_array(&jsobj, "subclasses");
    const GrowableObjectArray& subclasses =
        GrowableObjectArray::Handle(direct_subclasses());
    if (!subclasses.IsNull()) {
      Class& subclass = Class::Handle();
      for (intptr_t i = 0; i < subclasses.Length(); ++i) {
        // TODO(turnidge): Use the Type directly once regis has added
        // types to the vmservice.
        subclass ^= subclasses.At(i);
        subclasses_array.AddValue(subclass);
      }
    }
  }
  {
    ClassTable* class_table = Isolate::Current()->class_table();
    const ClassHeapStats* stats = class_table->StatsWithUpdatedSize(id());
    if (stats != NULL) {
      JSONObject allocation_stats(&jsobj, "_allocationStats");
      stats->PrintToJSONObject(*this, &allocation_stats);
    }
  }
}


void Class::InsertCanonicalConstant(intptr_t index,
                                    const Instance& constant) const {
  // The constant needs to be added to the list. Grow the list if it is full.
  Array& canonical_list = Array::Handle(constants());
  const intptr_t list_len = canonical_list.Length();
  if (index >= list_len) {
    const intptr_t new_length = (list_len == 0) ? 4 : list_len + 4;
    const Array& new_canonical_list =
        Array::Handle(Array::Grow(canonical_list, new_length, Heap::kOld));
    set_constants(new_canonical_list);
    new_canonical_list.SetAt(index, constant);
  } else {
    canonical_list.SetAt(index, constant);
  }
}


RawUnresolvedClass* UnresolvedClass::New(const LibraryPrefix& library_prefix,
                                         const String& ident,
                                         intptr_t token_pos) {
  const UnresolvedClass& type = UnresolvedClass::Handle(UnresolvedClass::New());
  type.set_library_prefix(library_prefix);
  type.set_ident(ident);
  type.set_token_pos(token_pos);
  return type.raw();
}


RawUnresolvedClass* UnresolvedClass::New() {
  ASSERT(Object::unresolved_class_class() != Class::null());
  RawObject* raw = Object::Allocate(UnresolvedClass::kClassId,
                                    UnresolvedClass::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawUnresolvedClass*>(raw);
}


void UnresolvedClass::set_token_pos(intptr_t token_pos) const {
  ASSERT(token_pos >= 0);
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}


void UnresolvedClass::set_ident(const String& ident) const {
  StorePointer(&raw_ptr()->ident_, ident.raw());
}


void UnresolvedClass::set_library_prefix(
    const LibraryPrefix& library_prefix) const {
  StorePointer(&raw_ptr()->library_prefix_, library_prefix.raw());
}


RawString* UnresolvedClass::Name() const {
  if (library_prefix() != LibraryPrefix::null()) {
    const LibraryPrefix& lib_prefix = LibraryPrefix::Handle(library_prefix());
    String& name = String::Handle();
    name = lib_prefix.name();  // Qualifier.
    name = String::Concat(name, Symbols::Dot());
    const String& str = String::Handle(ident());
    name = String::Concat(name, str);
    return name.raw();
  } else {
    return ident();
  }
}


const char* UnresolvedClass::ToCString() const {
  const char* cname =  String::Handle(Name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(),
      "unresolved class '%s'", cname);
}


void UnresolvedClass::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


static uint32_t CombineHashes(uint32_t hash, uint32_t other_hash) {
  hash += other_hash;
  hash += hash << 10;
  hash ^= hash >> 6;  // Logical shift, unsigned hash.
  return hash;
}


static uint32_t FinalizeHash(uint32_t hash) {
  hash += hash << 3;
  hash ^= hash >> 11;  // Logical shift, unsigned hash.
  hash += hash << 15;
  return hash;
}


intptr_t TypeArguments::Hash() const {
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
  return FinalizeHash(result);
}


RawString* TypeArguments::SubvectorName(intptr_t from_index,
                                        intptr_t len,
                                        NameVisibility name_visibility) const {
  Zone* zone = Thread::Current()->zone();
  ASSERT(from_index + len <= Length());
  String& name = String::Handle(zone);
  const intptr_t num_strings = (len == 0) ? 2 : 2*len + 1;  // "<""T"", ""T"">".
  GrowableHandlePtrArray<const String> pieces(zone, num_strings);
  pieces.Add(Symbols::LAngleBracket());
  AbstractType& type = AbstractType::Handle();
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
  return Symbols::FromConcatAll(pieces);
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
    if (!type.IsEquivalent(other_type, trail)) {
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
                             Heap::Space space) const {
  ASSERT(Length() >= (from_index + len));
  ASSERT(!other.IsNull());
  ASSERT(other.Length() >= (from_index + len));
  AbstractType& type = AbstractType::Handle();
  AbstractType& other_type = AbstractType::Handle();
  for (intptr_t i = 0; i < len; i++) {
    type = TypeAt(from_index + i);
    ASSERT(!type.IsNull());
    other_type = other.TypeAt(from_index + i);
    ASSERT(!other_type.IsNull());
    if (!type.TypeTest(test_kind, other_type, bound_error, space)) {
      return false;
    }
  }
  return true;
}


void TypeArguments::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  // The index in the canonical_type_arguments table cannot be used as part of
  // the object id (as in typearguments/id), because the indices are not
  // preserved when the table grows and the entries get rehashed. Use the ring.
  Isolate* isolate = Isolate::Current();
  ObjectStore* object_store = isolate->object_store();
  const Array& table = Array::Handle(object_store->canonical_type_arguments());
  ASSERT(table.Length() > 0);
  AddCommonObjectProperties(&jsobj, "TypeArguments", ref);
  jsobj.AddServiceId(*this);
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name, vm_name);
  if (ref) {
    return;
  }
  {
    JSONArray jsarr(&jsobj, "types");
    AbstractType& type_arg = AbstractType::Handle();
    for (intptr_t i = 0; i < Length(); i++) {
      type_arg = TypeAt(i);
      jsarr.AddValue(type_arg);
    }
  }
  if (!IsInstantiated()) {
    JSONArray jsarr(&jsobj, "_instantiations");
    Array& prior_instantiations = Array::Handle(instantiations());
    ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
    TypeArguments& type_args = TypeArguments::Handle();
    intptr_t i = 0;
    while (true) {
      if (prior_instantiations.At(i) == Smi::New(StubCode::kNoInstantiator)) {
        break;
      }
      JSONObject instantiation(&jsarr);
      type_args ^= prior_instantiations.At(i);
      instantiation.AddProperty("instantiator", type_args, true);
      type_args ^= prior_instantiations.At(i + 1);
      instantiation.AddProperty("instantiated", type_args, true);
      i += 2;
    }
  }
}


bool TypeArguments::HasInstantiations() const {
  const Array& prior_instantiations = Array::Handle(instantiations());
  ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
  return prior_instantiations.Length() > 1;
}


intptr_t TypeArguments::NumInstantiations() const {
  const Array& prior_instantiations = Array::Handle(instantiations());
  ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
  intptr_t i = 0;
  while (prior_instantiations.At(i) != Smi::New(StubCode::kNoInstantiator)) {
    i += 2;
  }
  return i/2;
}


RawArray* TypeArguments::instantiations() const {
  return raw_ptr()->instantiations_;
}


void TypeArguments::set_instantiations(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->instantiations_, value.raw());
}


intptr_t TypeArguments::Length() const {
  ASSERT(!IsNull());
  return Smi::Value(raw_ptr()->length_);
}


RawAbstractType* TypeArguments::TypeAt(intptr_t index) const {
  return *TypeAddr(index);
}


void TypeArguments::SetTypeAt(intptr_t index,
                                const AbstractType& value) const {
  StorePointer(TypeAddr(index), value.raw());
}


bool TypeArguments::IsResolved() const {
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
                                            TrailPtr trail) const {
  ASSERT(!IsNull());
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < len; i++) {
    type = TypeAt(from_index + i);
    // If the type argument is null, the type parameterized with this type
    // argument is still being finalized. Skip this null type argument.
    if (!type.IsNull() && !type.IsInstantiated(trail)) {
      return false;
    }
  }
  return true;
}


bool TypeArguments::IsUninstantiatedIdentity() const {
  ASSERT(!IsInstantiated());
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    if (!type.IsTypeParameter()) {
      return false;
    }
    const TypeParameter& type_param = TypeParameter::Cast(type);
    ASSERT(type_param.IsFinalized());
    if ((type_param.index() != i)) {
      return false;
    }
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
    if ((type_param.index() != i)) {
      return false;
    }
  }
  // As a second requirement, the type arguments corresponding to the super type
  // must be identical. Overlapping ones have already been checked starting at
  // first_type_param_offset.
  if (first_type_param_offset == 0) {
    return true;
  }
  AbstractType& super_type = AbstractType::Handle(
      instantiator_class.super_type());
  const TypeArguments& super_type_args = TypeArguments::Handle(
      super_type.arguments());
  if (super_type_args.IsNull()) {
    return false;
  }
  AbstractType& super_type_arg = AbstractType::Handle();
  for (intptr_t i = 0;
       (i < first_type_param_offset) && (i < num_type_args); i++) {
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
      const AbstractType& bound = AbstractType::Handle(
          TypeParameter::Cast(type).bound());
      if (!bound.IsObjectType() && !bound.IsDynamicType()) {
        return true;
      }
      continue;
    }
    const TypeArguments& type_args = TypeArguments::Handle(
        Type::Cast(type).arguments());
    if (!type_args.IsNull() && type_args.IsBounded()) {
      return true;
    }
  }
  return false;
}


RawTypeArguments* TypeArguments::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    Error* bound_error,
    TrailPtr trail,
    Heap::Space space) const {
  ASSERT(!IsInstantiated());
  if (!instantiator_type_arguments.IsNull() &&
      IsUninstantiatedIdentity() &&
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
                                  bound_error,
                                  trail,
                                  space);
    }
    instantiated_array.SetTypeAt(i, type);
  }
  return instantiated_array.raw();
}


RawTypeArguments* TypeArguments::InstantiateAndCanonicalizeFrom(
    const TypeArguments& instantiator_type_arguments,
    Error* bound_error) const {
  ASSERT(!IsInstantiated());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsCanonical());
  // Lookup instantiator and, if found, return paired instantiated result.
  Array& prior_instantiations = Array::Handle(instantiations());
  ASSERT(!prior_instantiations.IsNull() && prior_instantiations.IsArray());
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  ASSERT(prior_instantiations.Length() > 0);  // Always at least a sentinel.
  intptr_t index = 0;
  while (true) {
    if (prior_instantiations.At(index) == instantiator_type_arguments.raw()) {
      return TypeArguments::RawCast(prior_instantiations.At(index + 1));
    }
    if (prior_instantiations.At(index) == Smi::New(StubCode::kNoInstantiator)) {
      break;
    }
    index += 2;
  }
  // Cache lookup failed. Instantiate the type arguments.
  TypeArguments& result = TypeArguments::Handle();
  result = InstantiateFrom(instantiator_type_arguments, bound_error);
  if ((bound_error != NULL) && !bound_error->IsNull()) {
    return result.raw();
  }
  // Instantiation did not result in bound error. Canonicalize type arguments.
  result = result.Canonicalize();
  // InstantiateAndCanonicalizeFrom is not reentrant. It cannot have been called
  // indirectly, so the prior_instantiations array cannot have grown.
  ASSERT(prior_instantiations.raw() == instantiations());
  // Add instantiator and result to instantiations array.
  intptr_t length = prior_instantiations.Length();
  if ((index + 2) >= length) {
    // Grow the instantiations array.
    // The initial array is Object::zero_array() of length 1.
    length = (length > 64) ?
        (length + 64) :
        ((length == 1) ? 3 : ((length - 1) * 2 + 1));
    prior_instantiations =
        Array::Grow(prior_instantiations, length, Heap::kOld);
    set_instantiations(prior_instantiations);
    ASSERT((index + 2) < length);
  }
  prior_instantiations.SetAt(index, instantiator_type_arguments);
  prior_instantiations.SetAt(index + 1, result);
  prior_instantiations.SetAt(index + 2,
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
                                      TypeArguments::InstanceSize(len),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    // Length must be set before we start storing into the array.
    result.SetLength(len);
  }
  // The zero array should have been initialized.
  ASSERT(Object::zero_array().raw() != Array::null());
  COMPILE_ASSERT(StubCode::kNoInstantiator == 0);
  result.set_instantiations(Object::zero_array());
  return result.raw();
}



RawAbstractType* const* TypeArguments::TypeAddr(intptr_t index) const {
  // TODO(iposva): Determine if we should throw an exception here.
  ASSERT((index >= 0) && (index < Length()));
  return &raw_ptr()->types()[index];
}


void TypeArguments::SetLength(intptr_t value) const {
  ASSERT(!IsCanonical());
  // This is only safe because we create a new Smi, which does not cause
  // heap allocation.
  StoreSmi(&raw_ptr()->length_, Smi::New(value));
}


static void GrowCanonicalTypeArguments(Isolate* isolate, const Array& table) {
  // Last element of the array is the number of used elements.
  const intptr_t table_size = table.Length() - 1;
  const intptr_t new_table_size = table_size * 2;
  Array& new_table = Array::Handle(isolate, Array::New(new_table_size + 1));
  // Copy all elements from the original table to the newly allocated
  // array.
  TypeArguments& element = TypeArguments::Handle(isolate);
  Object& new_element = Object::Handle(isolate);
  for (intptr_t i = 0; i < table_size; i++) {
    element ^= table.At(i);
    if (!element.IsNull()) {
      const intptr_t hash = element.Hash();
      ASSERT(Utils::IsPowerOfTwo(new_table_size));
      intptr_t index = hash & (new_table_size - 1);
      new_element = new_table.At(index);
      while (!new_element.IsNull()) {
        index = (index + 1) & (new_table_size - 1);  // Move to next element.
        new_element = new_table.At(index);
      }
      new_table.SetAt(index, element);
    }
  }
  // Copy used count.
  new_element = table.At(table_size);
  new_table.SetAt(new_table_size, new_element);
  // Remember the new table now.
  isolate->object_store()->set_canonical_type_arguments(new_table);
}


static void InsertIntoCanonicalTypeArguments(Isolate* isolate,
                                             const Array& table,
                                             const TypeArguments& arguments,
                                             intptr_t index) {
  arguments.SetCanonical();  // Mark object as being canonical.
  table.SetAt(index, arguments);  // Remember the new element.
  // Update used count.
  // Last element of the array is the number of used elements.
  const intptr_t table_size = table.Length() - 1;
  const intptr_t used_elements =
      Smi::Value(Smi::RawCast(table.At(table_size))) + 1;
  const Smi& used = Smi::Handle(isolate, Smi::New(used_elements));
  table.SetAt(table_size, used);

#ifdef DEBUG
  // Verify that there are no duplicates.
  // Duplicates could appear if hash values are not kept constant across
  // snapshots, e.g. if class ids are not preserved by the snapshots.
  TypeArguments& other_arguments = TypeArguments::Handle();
  for (intptr_t i = 0; i < table_size; i++) {
    if ((i != index) && (table.At(i) != TypeArguments::null())) {
      other_arguments ^= table.At(i);
      if (arguments.Equals(other_arguments)) {
        // Recursive types may be equal, but have different hashes.
        ASSERT(arguments.IsRecursive());
        ASSERT(other_arguments.IsRecursive());
        ASSERT(arguments.Hash() != other_arguments.Hash());
      }
    }
  }
#endif

  // Rehash if table is 75% full.
  if (used_elements > ((table_size / 4) * 3)) {
    GrowCanonicalTypeArguments(isolate, table);
  }
}


static intptr_t FindIndexInCanonicalTypeArguments(
    Isolate* isolate,
    const Array& table,
    const TypeArguments& arguments,
    intptr_t hash) {
  // Last element of the array is the number of used elements.
  const intptr_t table_size = table.Length() - 1;
  ASSERT(Utils::IsPowerOfTwo(table_size));
  intptr_t index = hash & (table_size - 1);

  TypeArguments& current = TypeArguments::Handle(isolate);
  current ^= table.At(index);
  while (!current.IsNull() && !current.Equals(arguments)) {
    index = (index + 1) & (table_size - 1);  // Move to next element.
    current ^= table.At(index);
  }
  return index;  // Index of element if found or slot into which to add it.
}


RawTypeArguments* TypeArguments::CloneUnfinalized() const {
  if (IsNull() || IsFinalized()) {
    return raw();
  }
  ASSERT(IsResolved());
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  const TypeArguments& clone = TypeArguments::Handle(
      TypeArguments::New(num_types));
  for (intptr_t i = 0; i < num_types; i++) {
    type = TypeAt(i);
    type = type.CloneUnfinalized();
    clone.SetTypeAt(i, type);
  }
  ASSERT(clone.IsResolved());
  return clone.raw();
}


RawTypeArguments* TypeArguments::CloneUninstantiated(
    const Class& new_owner,
    TrailPtr trail) const {
  ASSERT(!IsNull());
  ASSERT(IsFinalized());
  ASSERT(!IsInstantiated());
  AbstractType& type = AbstractType::Handle();
  const intptr_t num_types = Length();
  const TypeArguments& clone = TypeArguments::Handle(
      TypeArguments::New(num_types));
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
  Isolate* isolate = Isolate::Current();
  ObjectStore* object_store = isolate->object_store();
  Array& table = Array::Handle(isolate,
                               object_store->canonical_type_arguments());
  // Last element of the array is the number of used elements.
  const intptr_t num_used =
      Smi::Value(Smi::RawCast(table.At(table.Length() - 1)));
  const intptr_t hash = Hash();
  intptr_t index =
      FindIndexInCanonicalTypeArguments(isolate, table, *this, hash);
  TypeArguments& result = TypeArguments::Handle(isolate);
  result ^= table.At(index);
  if (result.IsNull()) {
    // Canonicalize each type argument.
    AbstractType& type_arg = AbstractType::Handle(isolate);
    for (intptr_t i = 0; i < num_types; i++) {
      type_arg = TypeAt(i);
      type_arg = type_arg.Canonicalize(trail);
      SetTypeAt(i, type_arg);
    }
    // Canonicalization of a recursive type may change its hash.
    intptr_t canonical_hash = hash;
    if (IsRecursive()) {
      canonical_hash = Hash();
    }
    // Canonicalization of the type argument's own type arguments may add an
    // entry to the table, or even grow the table, and thereby change the
    // previously calculated index.
    table = object_store->canonical_type_arguments();
    if ((canonical_hash != hash) ||
        (Smi::Value(Smi::RawCast(table.At(table.Length() - 1))) != num_used)) {
      index = FindIndexInCanonicalTypeArguments(
          isolate, table, *this, canonical_hash);
      result ^= table.At(index);
    }
    if (result.IsNull()) {
      // Make sure we have an old space object and add it to the table.
      if (this->IsNew()) {
        result ^= Object::Clone(*this, Heap::kOld);
      } else {
        result ^= this->raw();
      }
      ASSERT(result.IsOld());
      InsertIntoCanonicalTypeArguments(isolate, table, result, index);
    }
  }
  ASSERT(result.Equals(*this));
  ASSERT(!result.IsNull());
  ASSERT(result.IsTypeArguments());
  ASSERT(result.IsCanonical());
  return result.raw();
}


const char* TypeArguments::ToCString() const {
  if (IsNull()) {
    return "NULL TypeArguments";
  }
  const char* prev_cstr = "TypeArguments:";
  for (int i = 0; i < Length(); i++) {
    const AbstractType& type_at = AbstractType::Handle(TypeAt(i));
    const char* type_cstr = type_at.IsNull() ? "null" : type_at.ToCString();
    char* chars = OS::SCreate(Thread::Current()->zone(),
        "%s [%s]", prev_cstr, type_cstr);
    prev_cstr = chars;
  }
  return prev_cstr;
}


const char* PatchClass::ToCString() const {
  const Class& cls = Class::Handle(patched_class());
  const char* cls_name = cls.ToCString();
  return OS::SCreate(Thread::Current()->zone(),
      "PatchClass for %s", cls_name);
}


void PatchClass::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


RawPatchClass* PatchClass::New(const Class& patched_class,
                               const Class& source_class) {
  const PatchClass& result = PatchClass::Handle(PatchClass::New());
  result.set_patched_class(patched_class);
  result.set_source_class(source_class);
  return result.raw();
}


RawPatchClass* PatchClass::New() {
  ASSERT(Object::patch_class_class() != Class::null());
  RawObject* raw = Object::Allocate(PatchClass::kClassId,
                                    PatchClass::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawPatchClass*>(raw);
}


RawScript* PatchClass::Script() const {
  const Class& source_class = Class::Handle(this->source_class());
  return source_class.script();
}


void PatchClass::set_patched_class(const Class& value) const {
  StorePointer(&raw_ptr()->patched_class_, value.raw());
}


void PatchClass::set_source_class(const Class& value) const {
  StorePointer(&raw_ptr()->source_class_, value.raw());
}


bool Function::HasBreakpoint() const {
  return Isolate::Current()->debugger()->HasBreakpoint(*this);
}


void Function::SetInstructions(const Code& value) const {
  StorePointer(&raw_ptr()->instructions_, value.instructions());
  StoreNonPointer(&raw_ptr()->entry_point_, value.EntryPoint());
}

void Function::AttachCode(const Code& value) const {
  SetInstructions(value);
  ASSERT(Function::Handle(value.function()).IsNull() ||
    (value.function() == this->raw()));
  value.set_owner(*this);
}


bool Function::HasCode() const {
  ASSERT(raw_ptr()->instructions_ != Instructions::null());
  return raw_ptr()->instructions_ !=
      StubCode::LazyCompile_entry()->code()->ptr()->instructions_;
}


void Function::ClearCode() const {
  ASSERT(ic_data_array() == Array::null());
  StorePointer(&raw_ptr()->unoptimized_code_, Code::null());
  SetInstructions(Code::Handle(StubCode::LazyCompile_entry()->code()));
}


void Function::SwitchToUnoptimizedCode() const {
  ASSERT(HasOptimizedCode());
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  const Code& current_code = Code::Handle(zone, CurrentCode());

  if (FLAG_trace_deoptimization_verbose) {
    THR_Print("Disabling optimized code: '%s' entry: %#" Px "\n",
      ToFullyQualifiedCString(),
      current_code.EntryPoint());
  }
  // Patch entry of the optimized code.
  CodePatcher::PatchEntry(current_code);
  const Error& error = Error::Handle(zone,
      Compiler::EnsureUnoptimizedCode(thread, *this));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& unopt_code = Code::Handle(zone, unoptimized_code());
  AttachCode(unopt_code);
  CodePatcher::RestoreEntry(unopt_code);
  isolate->TrackDeoptimizedCode(current_code);
}


void Function::set_unoptimized_code(const Code& value) const {
  ASSERT(value.IsNull() || !value.is_optimized());
  StorePointer(&raw_ptr()->unoptimized_code_, value.raw());
}


RawContextScope* Function::context_scope() const {
  if (IsClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    return ClosureData::Cast(obj).context_scope();
  }
  return ContextScope::null();
}


void Function::set_context_scope(const ContextScope& value) const {
  if (IsClosureFunction()) {
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
  ASSERT(token_pos() == 0);
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


RawFunction* Function::parent_function() const {
  if (IsClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    return ClosureData::Cast(obj).parent_function();
  }
  return Function::null();
}


void Function::set_parent_function(const Function& value) const {
  if (IsClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    ClosureData::Cast(obj).set_parent_function(value);
    return;
  }
  UNREACHABLE();
}


RawFunction* Function::implicit_closure_function() const {
  if (IsClosureFunction() ||
      IsSignatureFunction() ||
      IsFactory()) {
    return Function::null();
  }
  const Object& obj = Object::Handle(raw_ptr()->data_);
  ASSERT(obj.IsNull() || obj.IsScript() || obj.IsFunction());
  return (obj.IsNull() || obj.IsScript()) ? Function::null()
                                          : Function::Cast(obj).raw();
}


void Function::set_implicit_closure_function(const Function& value) const {
  ASSERT(!IsClosureFunction() && !IsSignatureFunction());
  ASSERT(raw_ptr()->data_ == Object::null());
  set_data(value);
}


RawClass* Function::signature_class() const {
  if (IsSignatureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(obj.IsNull() || obj.IsClass());
    return (obj.IsNull()) ? Class::null() : Class::Cast(obj).raw();
  }
  if (IsClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    return ClosureData::Cast(obj).signature_class();
  }
  return Class::null();
}


void Function::set_signature_class(const Class& value) const {
  if (IsSignatureFunction()) {
    set_data(value);
    return;
  }
  if (IsClosureFunction()) {
    const Object& obj = Object::Handle(raw_ptr()->data_);
    ASSERT(!obj.IsNull());
    ClosureData::Cast(obj).set_signature_class(value);
    return;
  }
  UNREACHABLE();
}


bool Function::IsRedirectingFactory() const {
  if (!IsFactory() || (raw_ptr()->data_ == Object::null())) {
    return false;
  }
  ASSERT(!IsClosureFunction());  // A factory cannot also be a closure.
  return true;
}


RawType* Function::RedirectionType() const {
  ASSERT(IsRedirectingFactory());
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
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->owner_, value.raw());
}


RawJSRegExp* Function::regexp() const {
  ASSERT(kind() == RawFunction::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data_));
  return JSRegExp::RawCast(pair.At(0));
}


intptr_t Function::string_specialization_cid() const {
  ASSERT(kind() == RawFunction::kIrregexpFunction);
  const Array& pair = Array::Cast(Object::Handle(raw_ptr()->data_));
  return Smi::Value(Smi::RawCast(pair.At(1)));
}


void Function::SetRegExpData(const JSRegExp& regexp,
                             intptr_t string_specialization_cid) const {
  ASSERT(kind() == RawFunction::kIrregexpFunction);
  ASSERT(RawObject::IsStringClassId(string_specialization_cid));
  ASSERT(raw_ptr()->data_ == Object::null());
  const Array& pair = Array::Handle(Array::New(2, Heap::kOld));
  pair.SetAt(0, regexp);
  pair.SetAt(1, Smi::Handle(Smi::New(string_specialization_cid)));
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


void Function::SetParameterTypeAt(
    intptr_t index, const AbstractType& value) const {
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


void Function::set_token_pos(intptr_t value) const {
  ASSERT(value >= 0);
  StoreNonPointer(&raw_ptr()->token_pos_, value);
}


void Function::set_kind_tag(intptr_t value) const {
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
  set_num_optional_parameters(are_optional_positional ?
                              num_optional_parameters :
                              -num_optional_parameters);
}


bool Function::IsOptimizable() const {
  if (FLAG_coverage_dir != NULL) {
    // Do not optimize if collecting coverage data.
    return false;
  }
  if (is_native()) {
    // Native methods don't need to be optimized.
    return false;
  }
  if (is_optimizable() && (script() != Script::null()) &&
      ((end_token_pos() - token_pos()) < FLAG_huge_method_cutoff_in_tokens)) {
    // Additional check needed for implicit getters.
    return (unoptimized_code() == Object::null()) ||
           (Code::Handle(unoptimized_code()).Size() <
            FLAG_huge_method_cutoff_in_code_size);
  }
  return false;
}


bool Function::IsNativeAutoSetupScope() const {
  return is_native() ? is_optimizable() : false;
}


void Function::SetIsOptimizable(bool value) const {
  ASSERT(!is_native());
  set_is_optimizable(value);
  if (!value) {
    set_is_inlinable(false);
  }
}


void Function::SetIsNativeAutoSetupScope(bool value) const {
  ASSERT(is_native());
  set_is_optimizable(value);
}


bool Function::CanBeInlined() const {
  return is_inlinable() &&
         !is_generated_body() &&
         HasCode() &&
         !Isolate::Current()->debugger()->HasBreakpoint(*this);
}


intptr_t Function::NumParameters() const {
  return num_fixed_parameters() + NumOptionalParameters();
}


intptr_t Function::NumImplicitParameters() const {
  if (kind() == RawFunction::kConstructor) {
    if (is_static()) {
      ASSERT(IsFactory());
      return 1;  // Type arguments.
    } else {
      ASSERT(IsGenerativeConstructor());
      return 2;  // Instance, phase.
    }
  }
  if ((kind() == RawFunction::kClosureFunction) ||
      (kind() == RawFunction::kSignatureFunction)) {
    return 1;  // Closure object.
  }
  if (!is_static()) {
    // Closure functions defined inside instance (i.e. non-static) functions are
    // marked as non-static, but they do not have a receiver.
    // Closures are handled above.
    ASSERT((kind() != RawFunction::kClosureFunction) &&
           (kind() != RawFunction::kSignatureFunction));
    return 1;  // Receiver.
  }
  return 0;  // No implicit parameters.
}


bool Function::AreValidArgumentCounts(intptr_t num_arguments,
                                      intptr_t num_named_arguments,
                                      String* error_message) const {
  if (num_named_arguments > NumOptionalNamedParameters()) {
    if (error_message != NULL) {
      const intptr_t kMessageBufferSize = 64;
      char message_buffer[kMessageBufferSize];
      OS::SNPrint(message_buffer,
                  kMessageBufferSize,
                  "%" Pd " named passed, at most %" Pd " expected",
                  num_named_arguments,
                  NumOptionalNamedParameters());
      *error_message = String::New(message_buffer);
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
      OS::SNPrint(message_buffer,
                  kMessageBufferSize,
                  "%" Pd "%s passed, %s%" Pd " expected",
                  num_pos_args - num_hidden_params,
                  num_opt_pos_params > 0 ? " positional" : "",
                  num_opt_pos_params > 0 ? "at most " : "",
                  num_pos_params - num_hidden_params);
      *error_message = String::New(message_buffer);
    }
    return false;  // Too many fixed and/or positional arguments.
  }
  if (num_pos_args < num_fixed_parameters()) {
    if (error_message != NULL) {
      const intptr_t kMessageBufferSize = 64;
      char message_buffer[kMessageBufferSize];
      // Hide implicit parameters to the user.
      const intptr_t num_hidden_params = NumImplicitParameters();
      OS::SNPrint(message_buffer,
                  kMessageBufferSize,
                  "%" Pd "%s passed, %s%" Pd " expected",
                  num_pos_args - num_hidden_params,
                  num_opt_pos_params > 0 ? " positional" : "",
                  num_opt_pos_params > 0 ? "at least " : "",
                  num_fixed_parameters() - num_hidden_params);
      *error_message = String::New(message_buffer);
    }
    return false;  // Too few fixed and/or positional arguments.
  }
  return true;
}


bool Function::AreValidArguments(intptr_t num_arguments,
                                 const Array& argument_names,
                                 String* error_message) const {
  const intptr_t num_named_arguments =
      argument_names.IsNull() ? 0 : argument_names.Length();
  if (!AreValidArgumentCounts(num_arguments,
                              num_named_arguments,
                              error_message)) {
    return false;
  }
  // Verify that all argument names are valid parameter names.
  Isolate* isolate = Isolate::Current();
  String& argument_name = String::Handle(isolate);
  String& parameter_name = String::Handle(isolate);
  for (intptr_t i = 0; i < num_named_arguments; i++) {
    argument_name ^= argument_names.At(i);
    ASSERT(argument_name.IsSymbol());
    bool found = false;
    const intptr_t num_positional_args = num_arguments - num_named_arguments;
    const intptr_t num_parameters = NumParameters();
    for (intptr_t j = num_positional_args;
         !found && (j < num_parameters);
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
        OS::SNPrint(message_buffer,
                    kMessageBufferSize,
                    "no optional formal parameter named '%s'",
                    argument_name.ToCString());
        *error_message = String::New(message_buffer);
      }
      return false;
    }
  }
  return true;
}


bool Function::AreValidArguments(const ArgumentsDescriptor& args_desc,
                                 String* error_message) const {
  const intptr_t num_arguments = args_desc.Count();
  const intptr_t num_named_arguments = args_desc.NamedCount();

  if (!AreValidArgumentCounts(num_arguments,
                              num_named_arguments,
                              error_message)) {
    return false;
  }
  // Verify that all argument names are valid parameter names.
  Isolate* isolate = Isolate::Current();
  String& argument_name = String::Handle(isolate);
  String& parameter_name = String::Handle(isolate);
  for (intptr_t i = 0; i < num_named_arguments; i++) {
    argument_name ^= args_desc.NameAt(i);
    ASSERT(argument_name.IsSymbol());
    bool found = false;
    const intptr_t num_positional_args = num_arguments - num_named_arguments;
    const int num_parameters = NumParameters();
    for (intptr_t j = num_positional_args;
         !found && (j < num_parameters);
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
        OS::SNPrint(message_buffer,
                    kMessageBufferSize,
                    "no optional formal parameter named '%s'",
                    argument_name.ToCString());
        *error_message = String::New(message_buffer);
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
    written = OS::SNPrint(
        *chars, reserve_len + 1, lib_class_format, library_name, class_name);
  } else {
    written = ConstructFunctionFullyQualifiedCString(parent,
                                                     chars,
                                                     reserve_len,
                                                     with_lib,
                                                     lib_kind);
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
  ASSERT(Isolate::Current()->flags().error_on_bad_override());
  ASSERT((bound_error != NULL) && bound_error->IsNull());
  // Check that this function's signature type is a subtype of the other
  // function's signature type.
  if (!TypeTest(kIsSubtypeOf, Object::null_type_arguments(),
                other, Object::null_type_arguments(), bound_error,
                Heap::kOld)) {
    // For more informative error reporting, use the location of the other
    // function here, since the caller will use the location of this function.
    *bound_error = LanguageError::NewFormatted(
        *bound_error,  // A bound error if non null.
        Script::Handle(other.script()),
        other.token_pos(),
        Report::kError,
        Heap::kNew,
        "signature type '%s' of function '%s' is not a subtype of signature "
        "type '%s' of function '%s'",
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


// If test_kind == kIsSubtypeOf, checks if the type of the specified parameter
// of this function is a subtype or a supertype of the type of the specified
// parameter of the other function.
// If test_kind == kIsMoreSpecificThan, checks if the type of the specified
// parameter of this function is more specific than the type of the specified
// parameter of the other function.
// Note that we do not apply contravariance of parameter types, but covariance
// of both parameter types and result type.
bool Function::TestParameterType(
    TypeTestKind test_kind,
    intptr_t parameter_position,
    intptr_t other_parameter_position,
    const TypeArguments& type_arguments,
    const Function& other,
    const TypeArguments& other_type_arguments,
    Error* bound_error,
    Heap::Space space) const {
  AbstractType& other_param_type =
      AbstractType::Handle(other.ParameterTypeAt(other_parameter_position));
  if (!other_param_type.IsInstantiated()) {
    other_param_type = other_param_type.InstantiateFrom(other_type_arguments,
                                                        bound_error,
                                                        NULL,  // trail
                                                        space);
    ASSERT((bound_error == NULL) || bound_error->IsNull());
  }
  if (other_param_type.IsDynamicType()) {
    return true;
  }
  AbstractType& param_type =
      AbstractType::Handle(ParameterTypeAt(parameter_position));
  if (!param_type.IsInstantiated()) {
    param_type = param_type.InstantiateFrom(
        type_arguments, bound_error, NULL /*trail*/, space);
    ASSERT((bound_error == NULL) || bound_error->IsNull());
  }
  if (param_type.IsDynamicType()) {
    return test_kind == kIsSubtypeOf;
  }
  if (test_kind == kIsSubtypeOf) {
    if (!param_type.IsSubtypeOf(other_param_type, bound_error, space) &&
        !other_param_type.IsSubtypeOf(param_type, bound_error, space)) {
      return false;
    }
  } else {
    ASSERT(test_kind == kIsMoreSpecificThan);
    if (!param_type.IsMoreSpecificThan(other_param_type, bound_error, space)) {
      return false;
    }
  }
  return true;
}


bool Function::TypeTest(TypeTestKind test_kind,
                        const TypeArguments& type_arguments,
                        const Function& other,
                        const TypeArguments& other_type_arguments,
                        Error* bound_error,
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
  // arguments or more.
  // A generative constructor may be compared to a redirecting factory and be
  // compatible although it has an additional phase parameter.
  // More generally, we can ignore implicit parameters.
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
  // Check the result type.
  AbstractType& other_res_type = AbstractType::Handle(other.result_type());
  if (!other_res_type.IsInstantiated()) {
    other_res_type = other_res_type.InstantiateFrom(other_type_arguments,
                                                    bound_error);
    ASSERT((bound_error == NULL) || bound_error->IsNull());
  }
  if (!other_res_type.IsDynamicType() && !other_res_type.IsVoidType()) {
    AbstractType& res_type = AbstractType::Handle(result_type());
    if (!res_type.IsInstantiated()) {
      res_type = res_type.InstantiateFrom(type_arguments, bound_error);
      ASSERT((bound_error == NULL) || bound_error->IsNull());
    }
    if (res_type.IsVoidType()) {
      return false;
    }
    if (test_kind == kIsSubtypeOf) {
      if (!res_type.IsSubtypeOf(other_res_type, bound_error) &&
          !other_res_type.IsSubtypeOf(res_type, bound_error)) {
        return false;
      }
    } else {
      ASSERT(test_kind == kIsMoreSpecificThan);
      if (!res_type.IsMoreSpecificThan(other_res_type, bound_error)) {
        return false;
      }
    }
  }
  // Check the types of fixed and optional positional parameters.
  for (intptr_t i = 0; i < (other_num_fixed_params - other_num_ignored_params +
                            other_num_opt_pos_params); i++) {
    if (!TestParameterType(test_kind,
                           i + num_ignored_params, i + other_num_ignored_params,
                           type_arguments, other, other_type_arguments,
                           bound_error,
                           space)) {
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
  String& other_param_name = String::Handle();
  for (intptr_t i = other_num_fixed_params; i < other_num_params; i++) {
    other_param_name = other.ParameterNameAt(i);
    ASSERT(other_param_name.IsSymbol());
    found_param_name = false;
    for (intptr_t j = num_fixed_params; j < num_params; j++) {
      ASSERT(String::Handle(ParameterNameAt(j)).IsSymbol());
      if (ParameterNameAt(j) == other_param_name.raw()) {
        found_param_name = true;
        if (!TestParameterType(test_kind,
                               j, i,
                               type_arguments, other, other_type_arguments,
                               bound_error,
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


bool Function::IsImplicitClosureFunction() const {
  if (!IsClosureFunction()) {
    return false;
  }
  const Function& parent = Function::Handle(parent_function());
  return (parent.implicit_closure_function() == raw());
}


bool Function::IsImplicitStaticClosureFunction(RawFunction* func) {
  NoSafepointScope no_safepoint;
  uint32_t kind_tag = func->ptr()->kind_tag_;
  if (KindBits::decode(kind_tag) != RawFunction::kClosureFunction) {
    return false;
  }
  if (!StaticBit::decode(kind_tag)) {
    return false;
  }
  RawClosureData* data = reinterpret_cast<RawClosureData*>(func->ptr()->data_);
  RawFunction* parent_function = data->ptr()->parent_function_;
  return (parent_function->ptr()->data_ == reinterpret_cast<RawObject*>(func));
}


bool Function::IsConstructorClosureFunction() const {
  return IsClosureFunction() &&
      String::Handle(name()).StartsWith(Symbols::ConstructorClosurePrefix());
}


RawFunction* Function::New() {
  ASSERT(Object::function_class() != Class::null());
  RawObject* raw = Object::Allocate(Function::kClassId,
                                    Function::InstanceSize(),
                                    Heap::kOld);
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
                           intptr_t token_pos) {
  ASSERT(!owner.IsNull());
  const Function& result = Function::Handle(Function::New());
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
  result.set_is_visible(true);  // Will be computed later.
  result.set_is_debuggable(true);  // Will be computed later.
  result.set_is_intrinsic(false);
  result.set_is_redirecting(false);
  result.set_is_generated_body(false);
  result.set_always_inline(false);
  result.set_is_polymorphic_target(false);
  result.set_owner(owner);
  result.set_token_pos(token_pos);
  result.set_end_token_pos(token_pos);
  result.set_num_fixed_parameters(0);
  result.set_num_optional_parameters(0);
  result.set_usage_counter(0);
  result.set_deoptimization_counter(0);
  result.set_optimized_instruction_count(0);
  result.set_optimized_call_site_count(0);
  result.set_is_optimizable(is_native ? false : true);
  result.set_is_inlinable(true);
  result.set_allows_hoisting_check_class(true);
  result.set_allows_bounds_check_generalization(true);
  result.SetInstructions(Code::Handle(StubCode::LazyCompile_entry()->code()));
  if (kind == RawFunction::kClosureFunction) {
    const ClosureData& data = ClosureData::Handle(ClosureData::New());
    result.set_data(data);
  }
  return result.raw();
}


RawFunction* Function::Clone(const Class& new_owner) const {
  ASSERT(!IsGenerativeConstructor());
  Function& clone = Function::Handle();
  clone ^= Object::Clone(*this, Heap::kOld);
  const Class& origin = Class::Handle(this->origin());
  const PatchClass& clone_owner =
      PatchClass::Handle(PatchClass::New(new_owner, origin));
  clone.set_owner(clone_owner);
  clone.ClearICDataArray();
  clone.ClearCode();
  clone.set_usage_counter(0);
  clone.set_deoptimization_counter(0);
  clone.set_optimized_instruction_count(0);
  clone.set_optimized_call_site_count(0);
  if (new_owner.NumTypeParameters() > 0) {
    // Adjust uninstantiated types to refer to type parameters of the new owner.
    AbstractType& type = AbstractType::Handle(clone.result_type());
    type ^= type.CloneUninstantiated(new_owner);
    clone.set_result_type(type);
    const intptr_t num_params = clone.NumParameters();
    Array& array = Array::Handle(clone.parameter_types());
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


RawFunction* Function::NewClosureFunction(const String& name,
                                          const Function& parent,
                                          intptr_t token_pos) {
  ASSERT(!parent.IsNull());
  // Use the owner defining the parent function and not the class containing it.
  const Object& parent_owner = Object::Handle(parent.raw_ptr()->owner_);
  ASSERT(!parent_owner.IsNull());
  const Function& result = Function::Handle(
      Function::New(name,
                    RawFunction::kClosureFunction,
                    /* is_static = */ parent.is_static(),
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    /* is_external = */ false,
                    parent.is_native(),
                    parent_owner,
                    token_pos));
  result.set_parent_function(parent);
  return result.raw();
}


RawFunction* Function::NewEvalFunction(const Class& owner,
                                       const Script& script,
                                       bool is_static) {
  const Function& result = Function::Handle(
      Function::New(String::Handle(Symbols::New(":Eval")),
                    RawFunction::kRegularFunction,
                    is_static,
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    /* is_external = */ false,
                    /* is_native = */ false,
                    owner,
                    0));
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
  // Create closure function.
  const String& closure_name = String::Handle(name());
  const Function& closure_function = Function::Handle(
      NewClosureFunction(closure_name, *this, token_pos()));

  // Set closure function's context scope.
  if (is_static()) {
    closure_function.set_context_scope(Object::empty_context_scope());
  } else {
    const ContextScope& context_scope =
        ContextScope::Handle(LocalScope::CreateImplicitClosureScope(*this));
    closure_function.set_context_scope(context_scope);
  }

  // Set closure function's result type to this result type.
  closure_function.set_result_type(AbstractType::Handle(result_type()));

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
  closure_function.set_parameter_types(Array::Handle(Array::New(num_params,
                                                                Heap::kOld)));
  closure_function.set_parameter_names(Array::Handle(Array::New(num_params,
                                                                Heap::kOld)));
  AbstractType& param_type = AbstractType::Handle();
  String& param_name = String::Handle();
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

  // Lookup or create a new signature class for the closure function in the
  // library of the owner class.
  const Class& owner_class = Class::Handle(Owner());
  ASSERT(!owner_class.IsNull() && (Owner() == closure_function.Owner()));
  const Library& library = Library::Handle(owner_class.library());
  ASSERT(!library.IsNull());
  const String& signature = String::Handle(closure_function.Signature());
  Class& signature_class = Class::ZoneHandle(
      library.LookupLocalClass(signature));
  if (signature_class.IsNull()) {
    const Script& script = Script::Handle(this->script());
    signature_class = Class::NewSignatureClass(signature,
                                               closure_function,
                                               script,
                                               closure_function.token_pos());
    library.AddClass(signature_class);
  } else {
    closure_function.set_signature_class(signature_class);
  }
  // Finalize types in signature class here, so that the
  // signature type is not computed twice.
  ClassFinalizer::FinalizeTypesInClass(signature_class);
  const Type& signature_type = Type::Handle(signature_class.SignatureType());
  if (!signature_type.IsFinalized()) {
    ClassFinalizer::FinalizeType(
        signature_class, signature_type, ClassFinalizer::kCanonicalize);
  }
  ASSERT(closure_function.signature_class() == signature_class.raw());
  set_implicit_closure_function(closure_function);
  ASSERT(closure_function.IsImplicitClosureFunction());
  return closure_function.raw();
}


RawString* Function::UserVisibleFormalParameters() const {
  // Typically 3, 5,.. elements in 'pieces', e.g.:
  // '_LoadRequest', CommaSpace, '_LoadError'.
  GrowableHandlePtrArray<const String> pieces(Thread::Current()->zone(), 5);
  const TypeArguments& instantiator = TypeArguments::Handle();
  BuildSignatureParameters(false, kUserVisibleName, instantiator, &pieces);
  return Symbols::FromConcatAll(pieces);
}


void Function::BuildSignatureParameters(
    bool instantiate,
    NameVisibility name_visibility,
    const TypeArguments& instantiator,
    GrowableHandlePtrArray<const String>* pieces) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

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
    if (instantiate && !param_type.IsInstantiated()) {
      param_type = param_type.InstantiateFrom(instantiator, NULL);
    }
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
      // The parameter name of an optional positional parameter does not need
      // to be part of the signature, since it is not used.
      if (num_opt_named_params > 0) {
        name = ParameterNameAt(i);
        pieces->Add(name);
        pieces->Add(Symbols::ColonSpace());
      }
      param_type = ParameterTypeAt(i);
      if (instantiate && !param_type.IsInstantiated()) {
        param_type = param_type.InstantiateFrom(instantiator, NULL);
      }
      ASSERT(!param_type.IsNull());
      name = param_type.BuildName(name_visibility);
      pieces->Add(name);
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
  if (implicit_static_closure() == Instance::null()) {
    Isolate* isolate = Isolate::Current();
    ObjectStore* object_store = isolate->object_store();
    const Context& context =
        Context::Handle(isolate, object_store->empty_context());
    Instance& closure =
        Instance::Handle(isolate, Closure::New(*this, context, Heap::kOld));
    const char* error_str = NULL;
    closure ^= closure.CheckAndCanonicalize(&error_str);
    ASSERT(!closure.IsNull());
    set_implicit_static_closure(closure);
  }
  return implicit_static_closure();
}


RawInstance* Function::ImplicitInstanceClosure(const Instance& receiver) const {
  ASSERT(IsImplicitClosureFunction());
  const Class& cls = Class::Handle(signature_class());
  const Context& context = Context::Handle(Context::New(1));
  context.SetAt(0, receiver);
  const Instance& result = Instance::Handle(Closure::New(*this, context));
  if (cls.NumTypeArguments() > 0) {
    const TypeArguments& type_arguments =
        TypeArguments::Handle(receiver.GetTypeArguments());
    result.SetTypeArguments(type_arguments);
  }
  return result.raw();
}


RawString* Function::BuildSignature(bool instantiate,
                                    NameVisibility name_visibility,
                                    const TypeArguments& instantiator) const {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  GrowableHandlePtrArray<const String> pieces(zone, 4);
  String& name = String::Handle(zone);
  if (!instantiate && !is_static() && (name_visibility == kInternalName)) {
    // Prefix the signature with its signature class and type parameters, if any
    // (e.g. "Map<K, V>(K) => bool"). In case of a function type alias, the
    // signature class name is the alias name.
    // The signature of static functions cannot be type parameterized.
    const Class& function_class = Class::Handle(zone, Owner());
    ASSERT(!function_class.IsNull());
    const TypeArguments& type_parameters = TypeArguments::Handle(
        zone, function_class.type_parameters());
    if (!type_parameters.IsNull()) {
      const String& function_class_name =
          String::Handle(zone, function_class.Name());
      pieces.Add(function_class_name);
      const intptr_t num_type_parameters = type_parameters.Length();
      pieces.Add(Symbols::LAngleBracket());
      TypeParameter& type_parameter = TypeParameter::Handle(zone);
      AbstractType& bound = AbstractType::Handle(zone);
      for (intptr_t i = 0; i < num_type_parameters; i++) {
        type_parameter ^= type_parameters.TypeAt(i);
        name = type_parameter.name();
        pieces.Add(name);
        bound = type_parameter.bound();
        if (!bound.IsNull() && !bound.IsObjectType()) {
          pieces.Add(Symbols::SpaceExtendsSpace());
          name = bound.BuildName(name_visibility);
          pieces.Add(name);
        }
        if (i < num_type_parameters - 1) {
          pieces.Add(Symbols::CommaSpace());
        }
      }
      pieces.Add(Symbols::RAngleBracket());
    }
  }
  pieces.Add(Symbols::LParen());
  BuildSignatureParameters(instantiate,
                           name_visibility,
                           instantiator,
                           &pieces);
  pieces.Add(Symbols::RParenArrow());
  AbstractType& res_type = AbstractType::Handle(zone, result_type());
  if (instantiate && !res_type.IsInstantiated()) {
    res_type = res_type.InstantiateFrom(instantiator, NULL);
  }
  name = res_type.BuildName(name_visibility);
  pieces.Add(name);
  return Symbols::FromConcatAll(pieces);
}


bool Function::HasInstantiatedSignature() const {
  AbstractType& type = AbstractType::Handle(result_type());
  if (!type.IsInstantiated()) {
    return false;
  }
  const intptr_t num_parameters = NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = ParameterTypeAt(i);
    if (!type.IsInstantiated()) {
      return false;
    }
  }
  return true;
}


RawClass* Function::Owner() const {
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).patched_class();
}


RawClass* Function::origin() const {
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).source_class();
}


RawScript* Function::script() const {
  if (token_pos() == 0) {
    // Testing for position 0 is an optimization that relies on temporary
    // eval functions having token position 0.
    const Script& script = Script::Handle(eval_script());
    if (!script.IsNull()) {
      return script.raw();
    }
  }
  if (IsClosureFunction()) {
    return Function::Handle(parent_function()).script();
  }
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).script();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).Script();
}


bool Function::HasOptimizedCode() const {
  return HasCode() &&  Code::Handle(Instructions::Handle(
      raw_ptr()->instructions_).code()).is_optimized();
}


RawString* Function::PrettyName() const {
  const String& str = String::Handle(name());
  return String::IdentifierPrettyName(str);
}


const char* Function::QualifiedUserVisibleNameCString() const {
  const String& str = String::Handle(QualifiedUserVisibleName());
  return str.ToCString();
}


RawString* Function::UserVisibleName() const {
  return PrettyName();
}


RawString* Function::QualifiedPrettyName() const {
  String& tmp = String::Handle();
  const Class& cls = Class::Handle(Owner());

  if (IsClosureFunction()) {
    if (IsLocalFunction() && !IsImplicitClosureFunction()) {
      const Function& parent = Function::Handle(parent_function());
      tmp = parent.QualifiedPrettyName();
    } else {
      return PrettyName();
    }
  } else {
    if (cls.IsTopLevel()) {
      return PrettyName();
    } else {
      tmp = cls.PrettyName();
    }
  }
  tmp = String::Concat(tmp, Symbols::Dot(), Heap::kOld);
  const String& suffix = String::Handle(PrettyName());
  return String::Concat(tmp, suffix, Heap::kOld);
}


RawString* Function::QualifiedUserVisibleName() const {
  String& tmp = String::Handle();
  const Class& cls = Class::Handle(Owner());

  if (IsClosureFunction()) {
    if (IsLocalFunction() && !IsImplicitClosureFunction()) {
      const Function& parent = Function::Handle(parent_function());
      tmp = parent.QualifiedUserVisibleName();
    } else {
      return UserVisibleName();
    }
  } else {
    if (cls.IsTopLevel()) {
      return UserVisibleName();
    } else {
      tmp = cls.UserVisibleName();
    }
  }
  tmp = String::Concat(tmp, Symbols::Dot());
  const String& suffix = String::Handle(UserVisibleName());
  return String::Concat(tmp, suffix);
}


RawString* Function::GetSource() const {
  if (IsImplicitConstructor() || IsSignatureFunction()) {
    // We may need to handle more cases when the restrictions on mixins are
    // relaxed. In particular we might start associating some source with the
    // forwarding constructors when it becomes possible to specify a particular
    // constructor from the mixin to use.
    return String::null();
  }
  const Script& func_script = Script::Handle(script());
  const TokenStream& stream = TokenStream::Handle(func_script.tokens());
  if (!func_script.HasSource()) {
    // When source is not available, avoid printing the whole token stream and
    // doing expensive position calculations.
    return stream.GenerateSource(token_pos(), end_token_pos() + 1);
  }

  const TokenStream::Iterator tkit(stream, end_token_pos());
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
  if ((tkit.CurrentTokenKind() == Token::kCOMMA) ||                   // Case 1.
      (tkit.CurrentTokenKind() == Token::kRPAREN) ||                  // Case 2.
      (tkit.CurrentTokenKind() == Token::kSEMICOLON &&
       String::Handle(name()).Equals("<anonymous closure>"))) {  // Case 3.
    last_tok_len = 0;
  }
  const String& result = String::Handle(func_script.GetSnippet(
      from_line, from_col, to_line, to_col + last_tok_len));
  ASSERT(!result.IsNull());
  return result.raw();
}


// Construct fingerprint from token stream. The token stream contains also
// arguments.
int32_t Function::SourceFingerprint() const {
  uint32_t result = IsImplicitClosureFunction()
      ? String::Handle(Function::Handle(parent_function()).Signature()).Hash()
      : String::Handle(Signature()).Hash();
  TokenStream::Iterator tokens_iterator(TokenStream::Handle(
      Script::Handle(script()).tokens()), token_pos());
  Object& obj = Object::Handle();
  String& literal = String::Handle();
  while (tokens_iterator.CurrentPosition() < end_token_pos()) {
    uint32_t val = 0;
    obj = tokens_iterator.CurrentToken();
    if (obj.IsSmi()) {
      val = Smi::Cast(obj).Value();
    } else {
      literal = tokens_iterator.MakeLiteralToken(obj);
      val = literal.Hash();
    }
    result = 31 * result + val;
    tokens_iterator.Advance();
  }
  result = result & ((static_cast<uint32_t>(1) << 31) - 1);
  ASSERT(result <= static_cast<uint32_t>(kMaxInt32));
  return result;
}


void Function::SaveICDataMap(
    const ZoneGrowableArray<const ICData*>& deopt_id_to_ic_data) const {
  // Compute number of ICData objectsto save.
  intptr_t count = 0;
  for (intptr_t i = 0; i < deopt_id_to_ic_data.length(); i++) {
    if (deopt_id_to_ic_data[i] != NULL) {
      count++;
    }
  }
  if (count == 0) {
    set_ic_data_array(Object::empty_array());
  } else {
    const Array& a = Array::Handle(Array::New(count, Heap::kOld));
    INC_STAT(Thread::Current(), total_code_size, count * sizeof(uword));
    count = 0;
    for (intptr_t i = 0; i < deopt_id_to_ic_data.length(); i++) {
      if (deopt_id_to_ic_data[i] != NULL) {
        a.SetAt(count++, *deopt_id_to_ic_data[i]);
      }
    }
    set_ic_data_array(a);
  }
}


void Function::RestoreICDataMap(
    ZoneGrowableArray<const ICData*>* deopt_id_to_ic_data) const {
  Zone* zone = Thread::Current()->zone();
  const Array& saved_icd = Array::Handle(zone, ic_data_array());
  if (saved_icd.IsNull() || (saved_icd.Length() == 0)) {
    deopt_id_to_ic_data->Clear();
    return;
  }
  ICData& icd = ICData::Handle();
  icd ^= saved_icd.At(saved_icd.Length() - 1);
  const intptr_t len = icd.deopt_id() + 1;
  deopt_id_to_ic_data->SetLength(len);
  for (intptr_t i = 0; i < len; i++) {
    (*deopt_id_to_ic_data)[i] = NULL;
  }
  for (intptr_t i = 0; i < saved_icd.Length(); i++) {
    ICData& icd = ICData::ZoneHandle(zone);
    icd ^= saved_icd.At(i);
    (*deopt_id_to_ic_data)[icd.deopt_id()] = &icd;
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
  const Array& icd_array = Array::Handle(ic_data_array());
  ICData& icd = ICData::Handle();
  for (intptr_t i = 0; i < icd_array.Length(); i++) {
    icd ^= icd_array.At(i);
    if (icd.deopt_id() == deopt_id) {
      icd.AddDeoptReason(reason);
    }
  }
}


bool Function::CheckSourceFingerprint(const char* prefix, int32_t fp) const {
  if (SourceFingerprint() != fp) {
    const bool recalculatingFingerprints = false;
    if (recalculatingFingerprints) {
      // This output can be copied into a file, then used with sed
      // to replace the old values.
      // sed -i .bak -f /tmp/newkeys runtime/vm/method_recognizer.h
      // sed -i .bak -f /tmp/newkeys runtime/vm/flow_graph_builder.h
      THR_Print("s/V(%s, %d)/V(%s, %d)/\n",
                prefix, fp, prefix, SourceFingerprint());
    } else {
      THR_Print("FP mismatch while recognizing method %s:"
                " expecting %d found %d\n",
                ToFullyQualifiedCString(),
                fp,
                SourceFingerprint());
      return false;
    }
  }
  return true;
}


const char* Function::ToCString() const {
  const char* static_str = is_static() ? " static" : "";
  const char* abstract_str = is_abstract() ? " abstract" : "";
  const char* kind_str = NULL;
  const char* const_str = is_const() ? " const" : "";
  switch (kind()) {
    case RawFunction::kRegularFunction:
    case RawFunction::kClosureFunction:
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
  return OS::SCreate(Thread::Current()->zone(),
      "Function '%s':%s%s%s%s.",
      function_name, static_str, abstract_str, kind_str, const_str);
}


static void AddFunctionServiceId(const JSONObject& jsobj,
                                 const Function& f,
                                 const Class& cls) {
  // Special kinds of functions use indices in their respective lists.
  intptr_t id = -1;
  const char* selector = NULL;
  if (f.IsNonImplicitClosureFunction()) {
    id = cls.FindClosureIndex(f);
    selector = "closures";
  } else if (f.IsImplicitClosureFunction()) {
    id = cls.FindImplicitClosureFunctionIndex(f);
    selector = "implicit_closures";
  } else if (f.IsNoSuchMethodDispatcher() || f.IsInvokeFieldDispatcher()) {
    id = cls.FindInvocationDispatcherFunctionIndex(f);
    selector = "dispatchers";
  }
  if (id != -1) {
    ASSERT(selector != NULL);
    jsobj.AddFixedServiceId("classes/%" Pd "/%s/%" Pd "",
                            cls.id(), selector, id);
    return;
  }
  // Regular functions known to their owner use their name (percent-encoded).
  String& name = String::Handle(f.name());
  if (cls.LookupFunction(name) == f.raw()) {
    name = String::EncodeIRI(name);
    jsobj.AddFixedServiceId("classes/%" Pd "/functions/%s",
                            cls.id(), name.ToCString());
    return;
  }
  // Oddball functions (not known to their owner) fall back to use the object
  // id ring. Current known examples are signature functions of closures
  // and stubs like 'megamorphic_miss'.
  jsobj.AddServiceId(f);
}


void Function::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Class& cls = Class::Handle(Owner());
  ASSERT(!cls.IsNull());
  Error& err = Error::Handle();
  err ^= cls.EnsureIsFinalized(Isolate::Current());
  ASSERT(err.IsNull());
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Function", ref);
  AddFunctionServiceId(jsobj, *this, cls);
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(name());
  AddNameProperties(&jsobj, user_name, vm_name);
  const Function& parent = Function::Handle(parent_function());
  if (!parent.IsNull()) {
    jsobj.AddProperty("owner", parent);
  } else if (cls.IsTopLevel()) {
    const Library& library = Library::Handle(cls.library());
    jsobj.AddProperty("owner", library);
  } else {
    jsobj.AddProperty("owner", cls);
  }

  const char* kind_string = Function::KindToCString(kind());
  jsobj.AddProperty("_kind", kind_string);
  jsobj.AddProperty("static", is_static());
  jsobj.AddProperty("const", is_const());
  if (ref) {
    return;
  }
  Code& code = Code::Handle(CurrentCode());
  if (!code.IsNull()) {
    jsobj.AddProperty("code", code);
  }
  Array& ics = Array::Handle(ic_data_array());
  if (!ics.IsNull()) {
    jsobj.AddProperty("_icDataArray", ics);
  }
  jsobj.AddProperty("_optimizable", is_optimizable());
  jsobj.AddProperty("_inlinable", is_inlinable());
  code = unoptimized_code();
  if (!code.IsNull()) {
    jsobj.AddProperty("_unoptimizedCode", code);
  }
  jsobj.AddProperty("_usageCounter", usage_counter());
  jsobj.AddProperty("_optimizedCallSiteCount", optimized_call_site_count());
  jsobj.AddProperty("_deoptimizations",
                    static_cast<intptr_t>(deoptimization_counter()));

  const Script& script = Script::Handle(this->script());
  if (!script.IsNull()) {
    jsobj.AddLocation(script, token_pos(), end_token_pos());
  }
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


void ClosureData::set_signature_class(const Class& value) const {
  StorePointer(&raw_ptr()->signature_class_, value.raw());
}


RawClosureData* ClosureData::New() {
  ASSERT(Object::closure_data_class() != Class::null());
  RawObject* raw = Object::Allocate(ClosureData::kClassId,
                                    ClosureData::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawClosureData*>(raw);
}


const char* ClosureData::ToCString() const {
  return "ClosureData class";
}


void ClosureData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
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
  RawObject* raw = Object::Allocate(RedirectionData::kClassId,
                                    RedirectionData::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawRedirectionData*>(raw);
}


const char* RedirectionData::ToCString() const {
  return "RedirectionData class";
}


void RedirectionData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


RawString* Field::GetterName(const String& field_name) {
  return String::Concat(Symbols::GetterPrefix(), field_name);
}


RawString* Field::GetterSymbol(const String& field_name) {
  return Symbols::FromConcat(Symbols::GetterPrefix(), field_name);
}


RawString* Field::LookupGetterSymbol(const String& field_name) {
  return Symbols::LookupFromConcat(Symbols::GetterPrefix(), field_name);
}


RawString* Field::SetterName(const String& field_name) {
  return String::Concat(Symbols::SetterPrefix(), field_name);
}


RawString* Field::SetterSymbol(const String& field_name) {
  return Symbols::FromConcat(Symbols::SetterPrefix(), field_name);
}


RawString* Field::LookupSetterSymbol(const String& field_name) {
  return Symbols::LookupFromConcat(Symbols::SetterPrefix(), field_name);
}


RawString* Field::NameFromGetter(const String& getter_name) {
  return Symbols::New(getter_name, kGetterPrefixLength,
      getter_name.Length() - kGetterPrefixLength);
}


RawString* Field::NameFromSetter(const String& setter_name) {
  return Symbols::New(setter_name, kSetterPrefixLength,
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
  StorePointer(&raw_ptr()->name_, value.raw());
}


RawClass* Field::owner() const {
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).patched_class();
}


RawClass* Field::origin() const {
  const Object& obj = Object::Handle(raw_ptr()->owner_);
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  ASSERT(obj.IsPatchClass());
  return PatchClass::Cast(obj).source_class();
}


void Field::set_type(const AbstractType& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->type_, value.raw());
}


RawField* Field::New() {
  ASSERT(Object::field_class() != Class::null());
  RawObject* raw = Object::Allocate(Field::kClassId,
                                    Field::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawField*>(raw);
}


RawField* Field::New(const String& name,
                     bool is_static,
                     bool is_final,
                     bool is_const,
                     bool is_reflectable,
                     const Class& owner,
                     intptr_t token_pos) {
  ASSERT(!owner.IsNull());
  const Field& result = Field::Handle(Field::New());
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
  result.set_guarded_cid(FLAG_use_field_guards ? kIllegalCid : kDynamicCid);
  result.set_is_nullable(FLAG_use_field_guards ? false : true);
  result.set_guarded_list_length_in_object_offset(Field::kUnknownLengthOffset);
  // Presently, we only attempt to remember the list length for final fields.
  if (is_final && FLAG_use_field_guards) {
    result.set_guarded_list_length(Field::kUnknownFixedLength);
  } else {
    result.set_guarded_list_length(Field::kNoFixedLength);
  }
  return result.raw();
}



RawField* Field::Clone(const Class& new_owner) const {
  Field& clone = Field::Handle();
  clone ^= Object::Clone(*this, Heap::kOld);
  const Class& owner = Class::Handle(this->owner());
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
    clone.set_type(type);
  }
  return clone.raw();
}


RawString* Field::PrettyName() const {
  const String& str = String::Handle(name());
  return String::IdentifierPrettyName(str);
}


RawString* Field::UserVisibleName() const {
  return PrettyName();
}


intptr_t Field::guarded_list_length() const {
  return Smi::Value(raw_ptr()->guarded_list_length_);
}


void Field::set_guarded_list_length(intptr_t list_length) const {
  StoreSmi(&raw_ptr()->guarded_list_length_, Smi::New(list_length));
}


intptr_t Field::guarded_list_length_in_object_offset() const {
  return raw_ptr()->guarded_list_length_in_object_offset_ + kHeapObjectTag;
}


void Field::set_guarded_list_length_in_object_offset(
    intptr_t list_length_offset) const {
  StoreNonPointer(&raw_ptr()->guarded_list_length_in_object_offset_,
                  static_cast<int8_t>(list_length_offset - kHeapObjectTag));
  ASSERT(guarded_list_length_in_object_offset() == list_length_offset);
}


bool Field::IsUnboxedField() const {
  bool valid_class = (FlowGraphCompiler::SupportsUnboxedDoubles() &&
                      (guarded_cid() == kDoubleCid)) ||
                     (FlowGraphCompiler::SupportsUnboxedSimd128() &&
                      (guarded_cid() == kFloat32x4Cid)) ||
                     (FlowGraphCompiler::SupportsUnboxedSimd128() &&
                      (guarded_cid() == kFloat64x2Cid));
  return is_unboxing_candidate() && !is_final() && !is_nullable() &&
         valid_class;
}


bool Field::IsPotentialUnboxedField() const {
  return is_unboxing_candidate() &&
         (IsUnboxedField() || (!is_final() && (guarded_cid() == kIllegalCid)));
}


const char* Field::ToCString() const {
  if (IsNull()) {
    return "Field::null";
  }
  const char* kF0 = is_static() ? " static" : "";
  const char* kF1 = is_final() ? " final" : "";
  const char* kF2 = is_const() ? " const" : "";
  const char* field_name = String::Handle(name()).ToCString();
  const Class& cls = Class::Handle(owner());
  const char* cls_name = String::Handle(cls.Name()).ToCString();
  return OS::SCreate(Thread::Current()->zone(),
      "Field <%s.%s>:%s%s%s", cls_name, field_name, kF0, kF1, kF2);
}

void Field::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  Class& cls = Class::Handle(owner());
  intptr_t id = cls.FindFieldIndex(*this);
  ASSERT(id >= 0);
  intptr_t cid = cls.id();
  AddCommonObjectProperties(&jsobj, "Field", ref);
  jsobj.AddFixedServiceId("classes/%" Pd "/fields/%" Pd "", cid, id);
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(name());
  AddNameProperties(&jsobj, user_name, vm_name);
  if (cls.IsTopLevel()) {
    const Library& library = Library::Handle(cls.library());
    jsobj.AddProperty("owner", library);
  } else {
    jsobj.AddProperty("owner", cls);
  }

  AbstractType& declared_type = AbstractType::Handle(type());
  jsobj.AddProperty("declaredType", declared_type);
  jsobj.AddProperty("static", is_static());
  jsobj.AddProperty("final", is_final());
  jsobj.AddProperty("const", is_const());
  if (ref) {
    return;
  }
  if (is_static()) {
    const Instance& valueObj = Instance::Handle(StaticValue());
    jsobj.AddProperty("staticValue", valueObj);
  }

  jsobj.AddProperty("_guardNullable", is_nullable());
  if (guarded_cid() == kIllegalCid) {
    jsobj.AddProperty("_guardClass", "unknown");
  } else if (guarded_cid() == kDynamicCid) {
    jsobj.AddProperty("_guardClass", "dynamic");
  } else {
    ClassTable* table = Isolate::Current()->class_table();
    ASSERT(table->IsValidIndex(guarded_cid()));
    cls ^= table->At(guarded_cid());
    jsobj.AddProperty("_guardClass", cls);
  }
  if (guarded_list_length() == kUnknownFixedLength) {
    jsobj.AddProperty("_guardLength", "unknown");
  } else if (guarded_list_length() == kNoFixedLength) {
    jsobj.AddProperty("_guardLength", "variable");
  } else {
    jsobj.AddProperty("_guardLength", guarded_list_length());
  }
  const Class& origin_cls = Class::Handle(origin());
  const Script& script = Script::Handle(origin_cls.script());
  if (!script.IsNull()) {
    jsobj.AddLocation(script, token_pos());
  }
}


// Build a closure object that gets (or sets) the contents of a static
// field f and cache the closure in a newly created static field
// named #f (or #f= in case of a setter).
RawInstance* Field::AccessorClosure(bool make_setter) const {
  ASSERT(is_static());
  const Class& field_owner = Class::Handle(owner());

  String& closure_name = String::Handle(this->name());
  closure_name = Symbols::FromConcat(Symbols::HashMark(), closure_name);
  if (make_setter) {
    closure_name = Symbols::FromConcat(Symbols::HashMark(), closure_name);
  }

  Field& closure_field = Field::Handle();
  closure_field = field_owner.LookupStaticField(closure_name);
  if (!closure_field.IsNull()) {
    ASSERT(closure_field.is_static());
    const Instance& closure =
        Instance::Handle(closure_field.StaticValue());
    ASSERT(!closure.IsNull());
    ASSERT(closure.IsClosure());
    return closure.raw();
  }

  // This is the first time a closure for this field is requested.
  // Create the closure and a new static field in which it is stored.
  const char* field_name = String::Handle(name()).ToCString();
  String& expr_src = String::Handle();
  if (make_setter) {
    expr_src =
        String::NewFormatted("(%s_) { return %s = %s_; }",
                             field_name, field_name, field_name);
  } else {
    expr_src = String::NewFormatted("() { return %s; }", field_name);
  }
  Object& result =
      Object::Handle(field_owner.Evaluate(expr_src,
                                          Object::empty_array(),
                                          Object::empty_array()));
  ASSERT(result.IsInstance());
  // The caller may expect the closure to be allocated in old space. Copy
  // the result here, since Object::Clone() is a private method.
  result = Object::Clone(result, Heap::kOld);

  closure_field = Field::New(closure_name,
                             true,  // is_static
                             true,  // is_final
                             true,  // is_const
                             false,  // is_reflectable
                             field_owner,
                             this->token_pos());
  closure_field.SetStaticValue(Instance::Cast(result), true);
  closure_field.set_type(Type::Handle(Type::DynamicType()));
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
      THR_Print("Switching %s to unoptimized code because guard"
                " on field %s was violated.\n",
                function.ToFullyQualifiedCString(),
                field_.ToCString());
    }
  }

 private:
  const Field& field_;
  DISALLOW_COPY_AND_ASSIGN(FieldDependentArray);
};


void Field::RegisterDependentCode(const Code& code) const {
  ASSERT(code.is_optimized());
  FieldDependentArray a(*this);
  a.Register(code);
}


void Field::DeoptimizeDependentCode() const {
  FieldDependentArray a(*this);
  a.DisableCode();
}


bool Field::IsUninitialized() const {
  const Instance& value = Instance::Handle(raw_ptr()->value_.static_value_);
  ASSERT(value.raw() != Object::transition_sentinel().raw());
  return value.raw() == Object::sentinel().raw();
}


void Field::SetPrecompiledInitializer(const Function& initializer) const {
  StorePointer(&raw_ptr()->initializer_.precompiled_, initializer.raw());
}


bool Field::HasPrecompiledInitializer() const {
  return raw_ptr()->initializer_.precompiled_->IsFunction();
}


void Field::SetSavedInitialStaticValue(const Instance& value) const {
  StorePointer(&raw_ptr()->initializer_.saved_value_, value.raw());
}


void Field::EvaluateInitializer() const {
  ASSERT(is_static());
  if (StaticValue() == Object::sentinel().raw()) {
    SetStaticValue(Object::transition_sentinel());
    Object& value = Object::Handle(Compiler::EvaluateStaticInitializer(*this));
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
    SetStaticValue(Object::null_instance());
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

  const Class& cls = Class::Handle(
      Isolate::Current()->class_table()->At(guarded_cid()));
  const char* class_name = String::Handle(cls.Name()).ToCString();

  if (RawObject::IsBuiltinListClassId(guarded_cid()) &&
      !is_nullable() &&
      is_final()) {
    ASSERT(guarded_list_length() != kUnknownFixedLength);
    if (guarded_list_length() == kNoFixedLength) {
      return Thread::Current()->zone()->PrintToString(
          "<%s [*]>", class_name);
    } else {
      return Thread::Current()->zone()->PrintToString(
          "<%s [%" Pd " @%" Pd "]>",
          class_name,
          guarded_list_length(),
          guarded_list_length_in_object_offset());
    }
  }

  return Thread::Current()->zone()->PrintToString("<%s %s>",
    is_nullable() ? "nullable" : "not-nullable",
    class_name);
}


void Field::InitializeGuardedListLengthInObjectOffset() const {
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
  if (!FLAG_use_field_guards) {
    return;
  }

  if (FLAG_trace_field_guards) {
    THR_Print("Store %s %s <- %s\n",
              ToCString(),
              GuardedPropertiesAsCString(),
              value.ToCString());
  }

  if (UpdateGuardedCidAndLength(value)) {
    if (FLAG_trace_field_guards) {
      THR_Print("    => %s\n", GuardedPropertiesAsCString());
    }

    DeoptimizeDependentCode();
  }
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
                                    LiteralToken::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawLiteralToken*>(raw);
}


RawLiteralToken* LiteralToken::New(Token::Kind kind, const String& literal) {
  const LiteralToken& result = LiteralToken::Handle(LiteralToken::New());
  result.set_kind(kind);
  result.set_literal(literal);
  if (kind == Token::kINTEGER) {
    const Integer& value = Integer::Handle(Integer::NewCanonical(literal));
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


void LiteralToken::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


RawArray* TokenStream::TokenObjects() const {
  return raw_ptr()->token_objects_;
}


void TokenStream::SetTokenObjects(const Array& value) const {
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
                                void *peer) {
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
  return GenerateSource(0, kMaxElements);
}

RawString* TokenStream::GenerateSource(intptr_t start_pos,
                                       intptr_t end_pos) const {
  Iterator iterator(*this, start_pos, Iterator::kAllTokens);
  const ExternalTypedData& data = ExternalTypedData::Handle(GetStream());
  const GrowableObjectArray& literals =
      GrowableObjectArray::Handle(GrowableObjectArray::New(data.Length()));
  const String& private_key = String::Handle(PrivateKey());
  intptr_t private_len = private_key.Length();

  Token::Kind curr = iterator.CurrentTokenKind();
  Token::Kind prev = Token::kILLEGAL;
  // Handles used in the loop.
  Object& obj = Object::Handle();
  String& literal = String::Handle();
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
        literals.Add(Symbols::DoubleQuotes());
      }
      if (escape_characters) {
        literal = String::EscapeSpecialCharacters(literal);
        literals.Add(literal);
      } else {
        literals.Add(literal);
      }
      if ((next != Token::kINTERPOL_VAR) && (next != Token::kINTERPOL_START)) {
        literals.Add(Symbols::DoubleQuotes());
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
    } else if ((curr == Token::kRETURN  ||
                curr == Token::kCONDITIONAL ||
                Token::IsBinaryOperator(curr) ||
                Token::IsEqualityOperator(curr)) && (next == Token::kLPAREN)) {
      separator = &Symbols::Blank();
    } else if ((curr == Token::kLBRACE) && (next == Token::kRBRACE)) {
      separator = NULL;
    } else if ((curr == Token::kSEMICOLON) && (next != Token::kNEWLINE)) {
      separator = &Symbols::Blank();
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
  const Array& source = Array::Handle(Array::MakeArray(literals));
  return String::ConcatAll(source);
}


intptr_t TokenStream::ComputeSourcePosition(intptr_t tok_pos) const {
  Iterator iterator(*this, 0, Iterator::kAllTokens);
  intptr_t src_pos = 0;
  Token::Kind kind = iterator.CurrentTokenKind();
  while (iterator.CurrentPosition() < tok_pos && kind != Token::kEOS) {
    iterator.Advance();
    kind = iterator.CurrentTokenKind();
    src_pos += 1;
  }
  return src_pos;
}


RawTokenStream* TokenStream::New() {
  ASSERT(Object::token_stream_class() != Class::null());
  RawObject* raw = Object::Allocate(TokenStream::kClassId,
                                    TokenStream::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawTokenStream*>(raw);
}


RawTokenStream* TokenStream::New(intptr_t len) {
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in TokenStream::New: invalid len %" Pd "\n", len);
  }
  uint8_t* data = reinterpret_cast<uint8_t*>(::malloc(len));
  ASSERT(data != NULL);
  Isolate* isolate = Isolate::Current();
  const ExternalTypedData& stream = ExternalTypedData::Handle(
      isolate,
      ExternalTypedData::New(kExternalTypedDataUint8ArrayCid,
                             data, len, Heap::kOld));
  stream.AddFinalizer(data, DataFinalizer);
  const TokenStream& result = TokenStream::Handle(isolate, TokenStream::New());
  result.SetStream(stream);
  return result.raw();
}


// CompressedTokenMap maps String and LiteralToken keys to Smi values.
// It also supports lookup by Scanner::TokenDescriptor.
class CompressedTokenTraits {
 public:
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

  static RawObject* NewKey(const Scanner::TokenDescriptor& descriptor) {
    return LiteralToken::New(descriptor.kind, *descriptor.literal);
  }
};
typedef UnorderedHashMap<CompressedTokenTraits> CompressedTokenMap;


// Helper class for creation of compressed token stream data.
class CompressedTokenStreamData : public ValueObject {
 public:
  static const intptr_t kInitialBufferSize = 16 * KB;
  CompressedTokenStreamData() :
      buffer_(NULL),
      stream_(&buffer_, Reallocate, kInitialBufferSize),
      tokens_(HashTables::New<CompressedTokenMap>(kInitialTableSize)) {
  }
  ~CompressedTokenStreamData() {
    // Safe to discard the hash table now.
    tokens_.Release();
  }

  // Add an IDENT token into the stream and the token hash map.
  void AddIdentToken(const String* ident) {
    ASSERT(ident->IsSymbol());
    const intptr_t fresh_index = tokens_.NumOccupied();
    intptr_t index = Smi::Value(Smi::RawCast(
        tokens_.InsertOrGetValue(*ident,
                                 Smi::Handle(Smi::New(fresh_index)))));
    WriteIndex(index);
  }

  // Add a LITERAL token into the stream and the token hash map.
  void AddLiteralToken(const Scanner::TokenDescriptor& descriptor) {
    ASSERT(descriptor.literal->IsSymbol());
    const intptr_t fresh_index = tokens_.NumOccupied();
    intptr_t index = Smi::Value(Smi::RawCast(
        tokens_.InsertNewOrGetValue(descriptor,
                                    Smi::Handle(Smi::New(fresh_index)))));
    WriteIndex(index);
  }

  // Add a simple token into the stream.
  void AddSimpleToken(intptr_t kind) {
    stream_.WriteUnsigned(kind);
  }

  // Return the compressed token stream.
  uint8_t* GetStream() const { return buffer_; }

  // Return the compressed token stream length.
  intptr_t Length() const { return stream_.bytes_written(); }

  // Generate and return the token objects array.
  RawArray* MakeTokenObjectsArray() const {
    Array& result = Array::Handle(
        Array::New(tokens_.NumOccupied(), Heap::kOld));
    CompressedTokenMap::Iterator it(&tokens_);
    Object& key = Object::Handle();
    while (it.MoveNext()) {
      intptr_t entry = it.Current();
      key = tokens_.GetKey(entry);
      result.SetAt(Smi::Value(Smi::RawCast(tokens_.GetPayload(entry, 0))), key);
    }
    return result.raw();
  }

 private:
  void WriteIndex(intptr_t value) {
    stream_.WriteUnsigned(value + Token::kNumTokens);
  }

  static uint8_t* Reallocate(uint8_t* ptr,
                             intptr_t old_size,
                             intptr_t new_size) {
    void* new_ptr = ::realloc(reinterpret_cast<void*>(ptr), new_size);
    return reinterpret_cast<uint8_t*>(new_ptr);
  }

  static const intptr_t kInitialTableSize = 32;

  uint8_t* buffer_;
  WriteStream stream_;
  CompressedTokenMap tokens_;

  DISALLOW_COPY_AND_ASSIGN(CompressedTokenStreamData);
};


RawTokenStream* TokenStream::New(const Scanner::GrowableTokenStream& tokens,
                                 const String& private_key) {
  Isolate* isolate = Isolate::Current();
  // Copy the relevant data out of the scanner into a compressed stream of
  // tokens.
  CompressedTokenStreamData data;
  intptr_t len = tokens.length();
  for (intptr_t i = 0; i < len; i++) {
    Scanner::TokenDescriptor token = tokens[i];
    if (token.kind == Token::kIDENT) {  // Identifier token.
      data.AddIdentToken(token.literal);
    } else if (Token::NeedsLiteralToken(token.kind)) {  // Literal token.
      data.AddLiteralToken(token);
    } else {  // Keyword, pseudo keyword etc.
      ASSERT(token.kind < Token::kNumTokens);
      data.AddSimpleToken(token.kind);
    }
  }
  data.AddSimpleToken(Token::kEOS);  // End of stream.

  // Create and setup the token stream object.
  const ExternalTypedData& stream = ExternalTypedData::Handle(
      isolate,
      ExternalTypedData::New(kExternalTypedDataUint8ArrayCid,
                             data.GetStream(), data.Length(), Heap::kOld));
  stream.AddFinalizer(data.GetStream(), DataFinalizer);
  const TokenStream& result = TokenStream::Handle(isolate, New());
  result.SetPrivateKey(private_key);
  const Array& token_objects =
      Array::Handle(isolate, data.MakeTokenObjectsArray());
  {
    NoSafepointScope no_safepoint;
    result.SetStream(stream);
    result.SetTokenObjects(token_objects);
  }
  return result.raw();
}


const char* TokenStream::ToCString() const {
  return "TokenStream";
}


void TokenStream::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  // TODO(johnmccutchan): Generate a stable id. TokenStreams hang off
  // a Script object but do not have a back reference to generate a stable id.
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
  const String& private_key = String::Handle(PrivateKey());
  jsobj.AddProperty("privateKey", private_key);
  // TODO(johnmccutchan): Add support for printing LiteralTokens and add
  // them to members array.
  JSONArray members(&jsobj, "members");
}


TokenStream::Iterator::Iterator(const TokenStream& tokens,
                                intptr_t token_pos,
                                Iterator::StreamType stream_type)
    : tokens_(TokenStream::Handle(tokens.raw())),
      data_(ExternalTypedData::Handle(tokens.GetStream())),
      stream_(reinterpret_cast<uint8_t*>(data_.DataAddr(0)), data_.Length()),
      token_objects_(Array::Handle(tokens.TokenObjects())),
      obj_(Object::Handle()),
      cur_token_pos_(token_pos),
      cur_token_kind_(Token::kILLEGAL),
      cur_token_obj_index_(-1),
      stream_type_(stream_type) {
  SetCurrentPosition(token_pos);
}


void TokenStream::Iterator::SetStream(const TokenStream& tokens,
                                      intptr_t token_pos) {
  tokens_ = tokens.raw();
  data_ = tokens.GetStream();
  stream_.SetStream(reinterpret_cast<uint8_t*>(data_.DataAddr(0)),
                    data_.Length());
  token_objects_ = tokens.TokenObjects();
  obj_ = Object::null();
  cur_token_pos_ = token_pos;
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


intptr_t TokenStream::Iterator::CurrentPosition() const {
  return cur_token_pos_;
}


void TokenStream::Iterator::SetCurrentPosition(intptr_t value) {
  stream_.SetPosition(value);
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
    if (Token::IsPseudoKeyword(kind) || Token::IsKeyword(kind)) {
      return Symbols::Keyword(kind).raw();
    }
    return Symbols::New(Token::Str(kind));
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
  return token_stream.GenerateSource();
}


RawGrowableObjectArray* Script::GenerateLineNumberArray() const {
  Isolate* isolate = Isolate::Current();
  const GrowableObjectArray& info =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New());
  const String& source = String::Handle(isolate, Source());
  const String& key = Symbols::Empty();
  const Object& line_separator = Object::Handle(isolate);
  const TokenStream& tkns = TokenStream::Handle(isolate, tokens());
  Smi& value = Smi::Handle(isolate);
  String& tokenValue = String::Handle(isolate);
  ASSERT(!tkns.IsNull());
  TokenStream::Iterator tkit(tkns, 0, TokenStream::Iterator::kAllTokens);
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
    value = Smi::New(tkit.CurrentPosition());
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
    default:
      UNIMPLEMENTED();
  }
  UNREACHABLE();
  return NULL;
}


void Script::set_url(const String& value) const {
  StorePointer(&raw_ptr()->url_, value.raw());
}


void Script::set_source(const String& value) const {
  StorePointer(&raw_ptr()->source_, value.raw());
}


void Script::set_kind(RawScript::Kind value) const {
  StoreNonPointer(&raw_ptr()->kind_, value);
}


void Script::set_tokens(const TokenStream& value) const {
  StorePointer(&raw_ptr()->tokens_, value.raw());
}


void Script::Tokenize(const String& private_key) const {
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
  Scanner scanner(src, private_key);
  set_tokens(TokenStream::Handle(zone,
                                 TokenStream::New(scanner.GetStream(),
                                                  private_key)));
  INC_STAT(thread, src_length, src.Length());
}


void Script::SetLocationOffset(intptr_t line_offset,
                               intptr_t col_offset) const {
  ASSERT(line_offset >= 0);
  ASSERT(col_offset >= 0);
  StoreNonPointer(&raw_ptr()->line_offset_, line_offset);
  StoreNonPointer(&raw_ptr()->col_offset_, col_offset);
}


void Script::GetTokenLocation(intptr_t token_pos,
                              intptr_t* line,
                              intptr_t* column,
                              intptr_t* token_len) const {
  ASSERT(line != NULL);
  const TokenStream& tkns = TokenStream::Handle(tokens());
  if (column == NULL) {
    TokenStream::Iterator tkit(tkns, 0, TokenStream::Iterator::kAllTokens);
    intptr_t cur_line = line_offset() + 1;
    while (tkit.CurrentPosition() < token_pos &&
           tkit.CurrentTokenKind() != Token::kEOS) {
      if (tkit.CurrentTokenKind() == Token::kNEWLINE) {
        cur_line++;
      }
      tkit.Advance();
    }
    *line = cur_line;
  } else {
    const String& src = String::Handle(Source());
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
                              intptr_t* first_token_index,
                              intptr_t* last_token_index) const {
  ASSERT(first_token_index != NULL && last_token_index != NULL);
  ASSERT(line_number > 0);
  *first_token_index = -1;
  *last_token_index = -1;
  const TokenStream& tkns = TokenStream::Handle(tokens());
  line_number -= line_offset();
  if (line_number < 1) line_number = 1;
  TokenStream::Iterator tkit(tkns, 0, TokenStream::Iterator::kAllTokens);
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
  intptr_t end_pos = *first_token_index;
  while (tkit.CurrentTokenKind() != Token::kNEWLINE &&
         tkit.CurrentTokenKind() != Token::kEOS) {
    end_pos = tkit.CurrentPosition();
    tkit.Advance();
  }
  *last_token_index = end_pos;
}


RawString* Script::GetLine(intptr_t line_number) const {
  const String& src = String::Handle(Source());
  intptr_t relative_line_number = line_number - line_offset();
  intptr_t current_line = 1;
  intptr_t line_start_idx = -1;
  intptr_t last_char_idx = -1;
  for (intptr_t ix = 0;
       (ix < src.Length()) && (current_line <= relative_line_number);
       ix++) {
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
    return String::SubString(src,
                             line_start_idx,
                             last_char_idx - line_start_idx + 1);
  } else {
    return Symbols::Empty().raw();
  }
}


RawString* Script::GetSnippet(intptr_t from_line,
                              intptr_t from_column,
                              intptr_t to_line,
                              intptr_t to_column) const {
  const String& src = String::Handle(Source());
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
  RawObject* raw = Object::Allocate(Script::kClassId,
                                    Script::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawScript*>(raw);
}


RawScript* Script::New(const String& url,
                       const String& source,
                       RawScript::Kind kind) {
  const Script& result = Script::Handle(Script::New());
  result.set_url(String::Handle(Symbols::New(url)));
  result.set_source(source);
  result.set_kind(kind);
  result.SetLocationOffset(0, 0);
  return result.raw();
}


const char* Script::ToCString() const {
  return "Script";
}


RawLibrary* Script::FindLibrary() const {
  Isolate* isolate = Isolate::Current();
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      isolate, isolate->object_store()->libraries());
  Library& lib = Library::Handle();
  Array& scripts = Array::Handle();
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


// See also Dart_ScriptGetTokenInfo.
void Script::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Script", ref);
  const String& uri = String::Handle(url());
  ASSERT(!uri.IsNull());
  const String& encoded_uri = String::Handle(String::EncodeIRI(uri));
  ASSERT(!encoded_uri.IsNull());
  const Library& lib = Library::Handle(FindLibrary());
  if (lib.IsNull()) {
    ASSERT(kind() == RawScript::kEvaluateTag);
    jsobj.AddServiceId(*this);
  } else {
    ASSERT(kind() != RawScript::kEvaluateTag);
    jsobj.AddFixedServiceId("libraries/%" Pd "/scripts/%s",
        lib.index(), encoded_uri.ToCString());
  }
  jsobj.AddPropertyStr("uri", uri);
  jsobj.AddProperty("_kind", GetKindAsCString());
  if (ref) {
    return;
  }
  if (!lib.IsNull()) {
    jsobj.AddProperty("library", lib);
  }
  const String& source = String::Handle(Source());
  jsobj.AddProperty("lineOffset", line_offset());
  jsobj.AddProperty("columnOffset", col_offset());
  jsobj.AddPropertyStr("source", source);

  // Print the line number table
  {
    JSONArray tokenPosTable(&jsobj, "tokenPosTable");

    const GrowableObjectArray& lineNumberArray =
        GrowableObjectArray::Handle(GenerateLineNumberArray());
    Object& value = Object::Handle();
    intptr_t pos = 0;

    // Skip leading null.
    ASSERT(lineNumberArray.Length() > 0);
    value = lineNumberArray.At(pos);
    ASSERT(value.IsNull());
    pos++;

    while (pos < lineNumberArray.Length()) {
      JSONArray lineInfo(&tokenPosTable);
      while (pos < lineNumberArray.Length()) {
        value = lineNumberArray.At(pos);
        pos++;
        if (value.IsNull()) {
          break;
        }
        const Smi& smi = Smi::Cast(value);
        lineInfo.AddValue(smi.Value());
      }
    }
  }
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
      anon_array_((kind == kIteratePrivate) ?
          Array::Handle(library.anonymous_classes()) : Object::empty_array()),
      anon_size_((kind == kIteratePrivate) ?
                 library.num_anonymous_classes() : 0),
      anon_ix_(0) {
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
  ASSERT(anon_ix_ < anon_size_);
  cls ^= anon_array_.At(anon_ix_++);
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
  Report::MessageF(Report::kError,
                   Script::Handle(lib.LookupScript(url)),
                   Scanner::kNoSourcePos,
                   "too many imports in library '%s'",
                   url.ToCString());
  UNREACHABLE();
}


void Library::set_num_imports(intptr_t value) const {
  if (!Utils::IsUint(16, value)) {
    ReportTooManyImports(*this);
  }
  StoreNonPointer(&raw_ptr()->num_imports_, value);
}


void Library::SetName(const String& name) const {
  // Only set name once.
  ASSERT(!Loaded());
  ASSERT(name.IsSymbol());
  StorePointer(&raw_ptr()->name_, name.raw());
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
  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsLibrary() && b.IsLibrary());
    // Library objects are always canonical.
    return a.raw() == b.raw();
  }
  static uword Hash(const Object& key) {
    return Library::Cast(key).UrlHash();
  }
};


typedef UnorderedHashSet<LibraryUrlTraits> LibraryLoadErrorSet;


RawInstance* Library::TransitiveLoadError() const {
  if (LoadError() != Instance::null()) {
    return LoadError();
  }
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
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
  Library& lib = Library::Handle(isolate);
  Instance& error = Instance::Handle(isolate);
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


static RawString* MakeClassMetaName(const Class& cls) {
  return Symbols::FromConcat(Symbols::At(), String::Handle(cls.Name()));
}


static RawString* MakeFieldMetaName(const Field& field) {
  const String& cname =
      String::Handle(MakeClassMetaName(Class::Handle(field.origin())));
  GrowableHandlePtrArray<const String> pieces(Thread::Current()->zone(), 3);
  pieces.Add(cname);
  pieces.Add(Symbols::At());
  pieces.Add(String::Handle(field.name()));
  return Symbols::FromConcatAll(pieces);
}


static RawString* MakeFunctionMetaName(const Function& func) {
  const String& cname =
      String::Handle(MakeClassMetaName(Class::Handle(func.origin())));
  GrowableHandlePtrArray<const String> pieces(Thread::Current()->zone(), 3);
  pieces.Add(cname);
  pieces.Add(Symbols::At());
  pieces.Add(String::Handle(func.QualifiedPrettyName()));
  return Symbols::FromConcatAll(pieces);
}


static RawString* MakeTypeParameterMetaName(const TypeParameter& param) {
  const String& cname = String::Handle(
      MakeClassMetaName(Class::Handle(param.parameterized_class())));
  GrowableHandlePtrArray<const String> pieces(Thread::Current()->zone(), 3);
  pieces.Add(cname);
  pieces.Add(Symbols::At());
  pieces.Add(String::Handle(param.name()));
  return Symbols::FromConcatAll(pieces);
}


void Library::AddMetadata(const Class& cls,
                          const String& name,
                          intptr_t token_pos) const {
  const String& metaname = String::Handle(Symbols::New(name));
  Field& field = Field::Handle(Field::New(metaname,
                                          true,   // is_static
                                          false,  // is_final
                                          false,  // is_const
                                          false,  // is_reflectable
                                          cls,
                                          token_pos));
  field.set_type(Type::Handle(Type::DynamicType()));
  field.SetStaticValue(Array::empty_array(), true);
  GrowableObjectArray& metadata =
      GrowableObjectArray::Handle(this->metadata());
  metadata.Add(field, Heap::kOld);
  cls.AddField(field);
}


void Library::AddClassMetadata(const Class& cls,
                               const Class& toplevel_class,
                               intptr_t token_pos) const {
  // We use the toplevel class as the owner of a class's metadata field because
  // a class's metadata is in scope of the library, not the class.
  AddMetadata(toplevel_class,
              String::Handle(MakeClassMetaName(cls)),
              token_pos);
}


void Library::AddFieldMetadata(const Field& field,
                               intptr_t token_pos) const {
  AddMetadata(Class::Handle(field.origin()),
              String::Handle(MakeFieldMetaName(field)),
              token_pos);
}


void Library::AddFunctionMetadata(const Function& func,
                                  intptr_t token_pos) const {
  AddMetadata(Class::Handle(func.origin()),
              String::Handle(MakeFunctionMetaName(func)),
              token_pos);
}


void Library::AddTypeParameterMetadata(const TypeParameter& param,
                                       intptr_t token_pos) const {
  AddMetadata(Class::Handle(param.parameterized_class()),
              String::Handle(MakeTypeParameterMetaName(param)),
              token_pos);
}


void Library::AddLibraryMetadata(const Class& cls, intptr_t token_pos) const {
  AddMetadata(cls, Symbols::TopLevel(), token_pos);
}


RawString* Library::MakeMetadataName(const Object& obj) const {
  if (obj.IsClass()) {
    return MakeClassMetaName(Class::Cast(obj));
  } else if (obj.IsField()) {
    return MakeFieldMetaName(Field::Cast(obj));
  } else if (obj.IsFunction()) {
    return MakeFunctionMetaName(Function::Cast(obj));
  } else if (obj.IsLibrary()) {
    return Symbols::TopLevel().raw();
  } else if (obj.IsTypeParameter()) {
    return MakeTypeParameterMetaName(TypeParameter::Cast(obj));
  }
  UNIMPLEMENTED();
  return String::null();
}


RawField* Library::GetMetadataField(const String& metaname) const {
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
    metadata = Parser::ParseMetadata(Class::Handle(field.owner()),
                                     field.token_pos());
    if (metadata.IsArray()) {
      ASSERT(Array::Cast(metadata).raw() != Object::empty_array().raw());
      field.SetStaticValue(Array::Cast(metadata), true);
    }
  }
  return metadata.raw();
}


static bool ShouldBePrivate(const String& name) {
  return
      (name.Length() >= 1 &&
       name.CharAt(0) == '_') ||
      (name.Length() >= 5 &&
       (name.CharAt(4) == '_' &&
        (name.CharAt(0) == 'g' || name.CharAt(0) == 's') &&
        name.CharAt(1) == 'e' &&
        name.CharAt(2) == 't' &&
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
    // are not cached. This reduces the size of the the cache.
    return obj.raw();
  }
  String& accessor_name = String::Handle(Field::GetterName(name));
  obj = LookupLocalObject(accessor_name);
  if (obj.IsNull()) {
    accessor_name = Field::SetterName(name);
    obj = LookupLocalObject(accessor_name);
    if (obj.IsNull() && !ShouldBePrivate(name)) {
      obj = LookupImportedObject(name);
    }
  }
  AddToResolvedNamesCache(name, obj);
  return obj.raw();
}


class StringEqualsTraits {
 public:
  static bool IsMatch(const Object& a, const Object& b) {
    return String::Cast(a).Equals(String::Cast(b));
  }
  static uword Hash(const Object& obj) {
    return String::Cast(obj).Hash();
  }
};
typedef UnorderedHashMap<StringEqualsTraits> ResolvedNamesMap;


// Returns true if the name is found in the cache, false no cache hit.
// obj is set to the cached entry. It may be null, indicating that the
// name does not resolve to anything in this library.
bool Library::LookupResolvedNamesCache(const String& name,
                                       Object* obj) const {
  ResolvedNamesMap cache(resolved_names());
  bool present = false;
  *obj = cache.GetOrNull(name, &present);
  ASSERT(cache.Release().raw() == resolved_names());
  return present;
}


// Add a name to the resolved name cache. This name resolves to the
// given object in this library scope. obj may be null, which means
// the name does not resolve to anything in this library scope.
void Library::AddToResolvedNamesCache(const String& name,
                                      const Object& obj) const {
  if (!FLAG_use_lib_cache) {
    return;
  }
  ResolvedNamesMap cache(resolved_names());
  cache.UpdateOrInsert(name, obj);
  StorePointer(&raw_ptr()->resolved_names_, cache.Release().raw());
}


void Library::InvalidateResolvedName(const String& name) const {
  Object& entry = Object::Handle();
  if (LookupResolvedNamesCache(name, &entry)) {
    // TODO(koda): Support deleted sentinel in snapshots and remove only 'name'.
    InvalidateResolvedNamesCache();
  }
}


void Library::InvalidateResolvedNamesCache() const {
  const intptr_t kInvalidatedCacheSize = 16;
  InitResolvedNamesCache(kInvalidatedCacheSize);
}


void Library::GrowDictionary(const Array& dict, intptr_t dict_size) const {
  // TODO(iposva): Avoid exponential growth.
  intptr_t new_dict_size = dict_size * 2;
  const Array& new_dict =
      Array::Handle(Array::New(new_dict_size + 1, Heap::kOld));
  // Rehash all elements from the original dictionary
  // to the newly allocated array.
  Object& entry = Class::Handle();
  String& entry_name = String::Handle();
  Object& new_entry = Object::Handle();
  for (intptr_t i = 0; i < dict_size; i++) {
    entry = dict.At(i);
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
    }
  }
  // Copy used count.
  new_entry = dict.At(dict_size);
  new_dict.SetAt(new_dict_size, new_entry);
  // Remember the new dictionary now.
  StorePointer(&raw_ptr()->dictionary_, new_dict.raw());
}


void Library::AddObject(const Object& obj, const String& name) const {
  ASSERT(obj.IsClass() ||
         obj.IsFunction() ||
         obj.IsField() ||
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
    GrowDictionary(dict, dict_size);
  }

  // Invalidate the cache of loaded scripts.
  if (loaded_scripts() != Array::null()) {
    StorePointer(&raw_ptr()->loaded_scripts_, Array::null());
  }
}


// Lookup a name in the library's re-export namespace. The name is
// unmangled, i.e. no getter or setter names should be looked up.
RawObject* Library::LookupReExport(const String& name) const {
  if (HasExports()) {
    const Array& exports = Array::Handle(this->exports());
    // Break potential export cycle while looking up name.
    StorePointer(&raw_ptr()->exports_, Object::empty_array().raw());
    Namespace& ns = Namespace::Handle();
    Object& obj = Object::Handle();
    for (int i = 0; i < exports.Length(); i++) {
      ns ^= exports.At(i);
      obj = ns.Lookup(name);
      if (!obj.IsNull()) {
        break;
      }
    }
    StorePointer(&raw_ptr()->exports_, exports.raw());
    return obj.raw();
  }
  return Object::null();
}


RawObject* Library::LookupEntry(const String& name, intptr_t *index) const {
  Isolate* isolate = Isolate::Current();
  REUSABLE_ARRAY_HANDLESCOPE(isolate);
  REUSABLE_OBJECT_HANDLESCOPE(isolate);
  REUSABLE_STRING_HANDLESCOPE(isolate);
  Array& dict = isolate->ArrayHandle();
  dict ^= dictionary();
  intptr_t dict_size = dict.Length() - 1;
  *index = name.Hash() % dict_size;
  Object& entry = isolate->ObjectHandle();
  String& entry_name = isolate->StringHandle();
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
  ASSERT(obj.IsClass() || obj.IsFunction() || obj.IsField());
  ASSERT(LookupLocalObject(name) != Object::null());

  intptr_t index;
  LookupEntry(name, &index);
  // The value is guaranteed to be found.
  const Array& dict = Array::Handle(dictionary());
  dict.SetAt(index, obj);
}


void Library::AddClass(const Class& cls) const {
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
  // We compute the list of loaded scripts lazily. The result is
  // cached in loaded_scripts_.
  if (loaded_scripts() == Array::null()) {
    // Iterate over the library dictionary and collect all scripts.
    const GrowableObjectArray& scripts =
        GrowableObjectArray::Handle(GrowableObjectArray::New(8));
    Object& entry = Object::Handle();
    Class& cls = Class::Handle();
    Class& patch_cls = Class::Handle();
    Script& owner_script = Script::Handle();
    Script& patch_script = Script::Handle();
    DictionaryIterator it(*this);
    while (it.HasNext()) {
      entry = it.GetNext();
      if (entry.IsClass()) {
        owner_script = Class::Cast(entry).script();
        patch_cls = Class::Cast(entry).patch_class();
        if (!patch_cls.IsNull()) {
          patch_script = patch_cls.script();
          AddScriptIfUnique(scripts, patch_script);
        }
      } else if (entry.IsFunction()) {
        owner_script = Function::Cast(entry).script();
      } else if (entry.IsField()) {
        cls = Field::Cast(entry).owner();
        owner_script = cls.script();
      } else {
        continue;
      }
      AddScriptIfUnique(scripts, owner_script);
    }

    // Special case: Scripts that only contain external top-level functions are
    // not included above, but can be referenced through a library's anonymous
    // classes. Example: dart-core:identical.dart.
    Array& anon_classes = Array::Handle(anonymous_classes());
    Function& func = Function::Handle();
    Array& functions = Array::Handle();
    for (intptr_t i = 0; i < anon_classes.Length(); i++) {
      cls ^= anon_classes.At(i);
      if (cls.IsNull()) continue;
      owner_script = cls.script();
      AddScriptIfUnique(scripts, owner_script);
      functions = cls.functions();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        func ^= functions.At(j);
        owner_script = func.script();
        AddScriptIfUnique(scripts, owner_script);
      }
    }

    // Create the array of scripts and cache it in loaded_scripts_.
    const Array& scripts_array = Array::Handle(Array::MakeArray(scripts));
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


RawFunction* Library::LookupFunctionInScript(const Script& script,
                                             intptr_t token_pos) const {
  Class& cls = Class::Handle();
  Function& func = Function::Handle();
  ClassDictionaryIterator it(*this, ClassDictionaryIterator::kIteratePrivate);
  while (it.HasNext()) {
    cls = it.GetNextClass();
    if (script.raw() == cls.script()) {
      func = cls.LookupFunctionAtToken(token_pos);
      if (!func.IsNull()) {
        return func.raw();
      }
    }
  }
  return Function::null();
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
  Isolate* isolate = Isolate::Current();
  Object& obj = Object::Handle(isolate, Object::null());
  obj = LookupLocalObject(name);
  if (obj.IsNull() && ShouldBePrivate(name)) {
    String& private_name = String::Handle(isolate, PrivateName(name));
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
  Isolate* isolate = Isolate::Current();
  const Class& cls = Class::Handle(isolate, LookupClass(name));
  if (!cls.IsNull()) {
    return cls.raw();
  }

  // Now try to lookup the class using its private name, but only in
  // this library (not in imported libraries).
  if (ShouldBePrivate(name)) {
    String& private_name = String::Handle(isolate, PrivateName(name));
    const Object& obj = Object::Handle(LookupLocalObject(private_name));
    if (obj.IsClass()) {
      return Class::Cast(obj).raw();
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


void Library::AddAnonymousClass(const Class& cls) const {
  intptr_t num_anonymous = this->raw_ptr()->num_anonymous_;
  Array& anon_array = Array::Handle(this->raw_ptr()->anonymous_classes_);
  if (num_anonymous == anon_array.Length()) {
    intptr_t new_len = (num_anonymous == 0) ? 4 : num_anonymous * 2;
    anon_array = Array::Grow(anon_array, new_len);
    StorePointer(&raw_ptr()->anonymous_classes_, anon_array.raw());
  }
  anon_array.SetAt(num_anonymous, cls);
  num_anonymous++;
  StoreNonPointer(&raw_ptr()->num_anonymous_, num_anonymous);
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
  Isolate* isolate = Isolate::Current();
  Library& imported = Library::Handle(isolate);
  intptr_t count = num_imports();
  for (int i = 0; i < count; i++) {
    imported = ImportLibraryAt(i);
    if (imported.IsCoreLibrary()) {
      return true;
    }
  }
  LibraryPrefix& prefix = LibraryPrefix::Handle(isolate);
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


void Library::AddImport(const Namespace& ns) const {
  Array& imports = Array::Handle(this->imports());
  intptr_t capacity = imports.Length();
  if (num_imports() == capacity) {
    capacity = capacity + kImportsCapacityIncrement;
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
  Array &exports = Array::Handle(this->exports());
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


void Library::InitResolvedNamesCache(intptr_t size) const {
  const Array& cache = Array::Handle(HashTables::New<ResolvedNamesMap>(size));
  StorePointer(&raw_ptr()->resolved_names_, cache.raw());
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
  RawObject* raw = Object::Allocate(Library::kClassId,
                                    Library::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawLibrary*>(raw);
}


RawLibrary* Library::NewLibraryHelper(const String& url,
                                      bool import_core_lib) {
  const Library& result = Library::Handle(Library::New());
  result.StorePointer(&result.raw_ptr()->name_, Symbols::Empty().raw());
  result.StorePointer(&result.raw_ptr()->url_, url.raw());
  result.StorePointer(&result.raw_ptr()->resolved_names_,
                      Object::empty_array().raw());
  result.StorePointer(&result.raw_ptr()->dictionary_,
                      Object::empty_array().raw());
  result.StorePointer(&result.raw_ptr()->metadata_,
                      GrowableObjectArray::New(4, Heap::kOld));
  result.StorePointer(&result.raw_ptr()->anonymous_classes_,
                      Object::empty_array().raw());
  result.StoreNonPointer(&result.raw_ptr()->num_anonymous_, 0);
  result.StorePointer(&result.raw_ptr()->imports_, Object::empty_array().raw());
  result.StorePointer(&result.raw_ptr()->exports_, Object::empty_array().raw());
  result.StorePointer(&result.raw_ptr()->loaded_scripts_, Array::null());
  result.StorePointer(&result.raw_ptr()->load_error_, Instance::null());
  result.set_native_entry_resolver(NULL);
  result.set_native_entry_symbol_resolver(NULL);
  result.set_is_in_fullsnapshot(false);
  result.StoreNonPointer(&result.raw_ptr()->corelib_imported_, true);
  result.set_debuggable(false);
  result.set_is_dart_scheme(url.StartsWith(Symbols::DartScheme()));
  result.StoreNonPointer(&result.raw_ptr()->load_state_,
                         RawLibrary::kAllocated);
  result.StoreNonPointer(&result.raw_ptr()->index_, -1);
  const intptr_t kInitialNameCacheSize = 64;
  result.InitResolvedNamesCache(kInitialNameCacheSize);
  result.InitClassDictionary();
  result.InitImportList();
  result.AllocatePrivateKey();
  if (import_core_lib) {
    const Library& core_lib = Library::Handle(Library::CoreLibrary());
    ASSERT(!core_lib.IsNull());
    const Namespace& ns = Namespace::Handle(
        Namespace::New(core_lib, Object::null_array(), Object::null_array()));
    result.AddImport(ns);
  }
  return result.raw();
}


RawLibrary* Library::New(const String& url) {
  return NewLibraryHelper(url, false);
}


void Library::InitCoreLibrary(Isolate* isolate) {
  const String& core_lib_url = Symbols::DartCore();
  const Library& core_lib =
      Library::Handle(Library::NewLibraryHelper(core_lib_url, false));
  core_lib.SetLoadRequested();
  core_lib.Register();
  isolate->object_store()->set_bootstrap_library(ObjectStore::kCore, core_lib);
  isolate->object_store()->set_root_library(Library::Handle());

  // Hook up predefined classes without setting their library pointers. These
  // classes are coming from the VM isolate, and are shared between multiple
  // isolates so setting their library pointers would be wrong.
  const Class& cls = Class::Handle(Object::dynamic_class());
  core_lib.AddObject(cls, String::Handle(cls.Name()));
}


RawObject* Library::Evaluate(const String& expr,
                             const Array& param_names,
                             const Array& param_values) const {
  // Take or make a fake top-level class and evaluate the expression
  // as a static function of the class.
  Class& top_level_class = Class::Handle();
  Array& top_level_classes = Array::Handle(anonymous_classes());
  ASSERT(top_level_classes.Length() > 0);
  top_level_class ^= top_level_classes.At(0);
  ASSERT(top_level_class.is_finalized());
  return top_level_class.Evaluate(expr, param_names, param_values);
}


void Library::InitNativeWrappersLibrary(Isolate* isolate) {
  static const int kNumNativeWrappersClasses = 4;
  ASSERT(kNumNativeWrappersClasses > 0 && kNumNativeWrappersClasses < 10);
  const String& native_flds_lib_url = Symbols::DartNativeWrappers();
  const Library& native_flds_lib = Library::Handle(
      Library::NewLibraryHelper(native_flds_lib_url, false));
  const String& native_flds_lib_name = Symbols::DartNativeWrappersLibName();
  native_flds_lib.SetName(native_flds_lib_name);
  native_flds_lib.SetLoadRequested();
  native_flds_lib.Register();
  native_flds_lib.SetLoadInProgress();
  isolate->object_store()->set_native_wrappers_library(native_flds_lib);
  static const char* const kNativeWrappersClass = "NativeFieldWrapperClass";
  static const int kNameLength = 25;
  ASSERT(kNameLength == (strlen(kNativeWrappersClass) + 1 + 1));
  char name_buffer[kNameLength];
  String& cls_name = String::Handle();
  for (int fld_cnt = 1; fld_cnt <= kNumNativeWrappersClasses; fld_cnt++) {
    OS::SNPrint(name_buffer,
                kNameLength,
                "%s%d",
                kNativeWrappersClass,
                fld_cnt);
    cls_name = Symbols::New(name_buffer);
    Class::NewNativeWrapper(native_flds_lib, cls_name, fld_cnt);
  }
  native_flds_lib.SetLoaded();
}


// Returns library with given url in current isolate, or NULL.
RawLibrary* Library::LookupLibrary(const String &url) {
  Isolate* isolate = Isolate::Current();
  Library& lib = Library::Handle(isolate, Library::null());
  String& lib_url = String::Handle(isolate, String::null());
  GrowableObjectArray& libs = GrowableObjectArray::Handle(
      isolate, isolate->object_store()->libraries());
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    lib_url ^= lib.url();
    if (lib_url.Equals(url)) {
      return lib.raw();
    }
  }
  return Library::null();
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


bool Library::IsKeyUsed(intptr_t key) {
  intptr_t lib_key;
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  Library& lib = Library::Handle();
  String& lib_url = String::Handle();
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    lib_url ^= lib.url();
    lib_key = lib_url.Hash();
    if (lib_key == key) {
      return true;
    }
  }
  return false;
}


void Library::AllocatePrivateKey() const {
  const String& url = String::Handle(this->url());
  intptr_t key_value = url.Hash() & kIntptrMax;
  while ((key_value == 0) || Library::IsKeyUsed(key_value)) {
    key_value = (key_value + 1) & kIntptrMax;
  }
  ASSERT(key_value > 0);
  char private_key[32];
  OS::SNPrint(private_key, sizeof(private_key),
              "%c%" Pd "", kPrivateKeySeparator, key_value);
  StorePointer(&raw_ptr()->private_key_, String::New(private_key, Heap::kOld));
}


const String& Library::PrivateCoreLibName(const String& member) {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const String& private_name = String::ZoneHandle(core_lib.PrivateName(member));
  return private_name;
}


RawClass* Library::LookupCoreClass(const String& class_name) {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  String& name = String::Handle(class_name.raw());
  if (class_name.CharAt(0) == kPrivateIdentifierStart) {
    // Private identifiers are mangled on a per library basis.
    name = Symbols::FromConcat(name, String::Handle(core_lib.private_key()));
  }
  return core_lib.LookupClass(name);
}


// Cannot handle qualified names properly as it only appends private key to
// the end (e.g. _Alfa.foo -> _Alfa.foo@...).
RawString* Library::PrivateName(const String& name) const {
  ASSERT(IsPrivate(name));
  // ASSERT(strchr(name, '@') == NULL);
  String& str = String::Handle();
  str = name.raw();
  str = Symbols::FromConcat(str, String::Handle(this->private_key()));
  return str.raw();
}


RawLibrary* Library::GetLibrary(intptr_t index) {
  Isolate* isolate = Isolate::Current();
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  ASSERT(!libs.IsNull());
  if ((0 <= index) && (index < libs.Length())) {
    Library& lib = Library::Handle();
    lib ^= libs.At(index);
    return lib.raw();
  }
  return Library::null();
}


void Library::Register() const {
  ASSERT(Library::LookupLibrary(String::Handle(url())) == Library::null());
  ObjectStore* object_store = Isolate::Current()->object_store();
  GrowableObjectArray& libs =
      GrowableObjectArray::Handle(object_store->libraries());
  ASSERT(!libs.IsNull());
  set_index(libs.Length());
  libs.Add(*this);
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
  return Isolate::Current()->object_store()->internal_library();
}


RawLibrary* Library::IsolateLibrary() {
  return Isolate::Current()->object_store()->isolate_library();
}


RawLibrary* Library::MathLibrary() {
  return Isolate::Current()->object_store()->math_library();
}


RawLibrary* Library::MirrorsLibrary() {
  return Isolate::Current()->object_store()->mirrors_library();
}


RawLibrary* Library::NativeWrappersLibrary() {
  return Isolate::Current()->object_store()->native_wrappers_library();
}


RawLibrary* Library::ProfilerLibrary() {
  return Isolate::Current()->object_store()->profiler_library();
}


RawLibrary* Library::TypedDataLibrary() {
  return Isolate::Current()->object_store()->typed_data_library();
}


const char* Library::ToCString() const {
  const String& name = String::Handle(url());
  return OS::SCreate(Thread::Current()->zone(),
      "Library:'%s'", name.ToCString());
}


void Library::PrintJSONImpl(JSONStream* stream, bool ref) const {
  intptr_t id = index();
  ASSERT(id >= 0);
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Library", ref);
  jsobj.AddFixedServiceId("libraries/%" Pd "", id);
  const String& vm_name = String::Handle(name());
  const String& user_name =
      String::Handle(String::IdentifierPrettyName(vm_name));
  AddNameProperties(&jsobj, user_name, vm_name);
  const String& library_url = String::Handle(url());
  jsobj.AddPropertyStr("uri", library_url);
  if (ref) {
    return;
  }
  jsobj.AddProperty("debuggable", IsDebuggable());
  {
    JSONArray jsarr(&jsobj, "classes");
    ClassDictionaryIterator class_iter(*this);
    Class& klass = Class::Handle();
    while (class_iter.HasNext()) {
      klass = class_iter.GetNextClass();
      if (!klass.IsCanonicalSignatureClass() &&
          !klass.IsMixinApplication()) {
        jsarr.AddValue(klass);
      }
    }
  }
  {
    JSONArray jsarr(&jsobj, "dependencies");

    Array& ports = Array::Handle();
    Namespace& ns = Namespace::Handle();
    Library& target = Library::Handle();

    // Unprefixed imports.
    ports = imports();
    for (intptr_t i = 0; i < ports.Length(); i++) {
      ns ^= ports.At(i);
      if (ns.IsNull()) continue;

      JSONObject jsdep(&jsarr);
      jsdep.AddProperty("isDeferred", false);
      jsdep.AddProperty("isExport", false);
      jsdep.AddProperty("isImport", true);
      target = ns.library();
      jsdep.AddProperty("target", target);
    }

    // Exports.
    ports = exports();
    for (intptr_t i = 0; i < ports.Length(); i++) {
      ns ^= ports.At(i);
      if (ns.IsNull()) continue;

      JSONObject jsdep(&jsarr);
      jsdep.AddProperty("isDeferred", false);
      jsdep.AddProperty("isExport", true);
      jsdep.AddProperty("isImport", false);
      target = ns.library();
      jsdep.AddProperty("target", target);
    }

    // Prefixed imports.
    DictionaryIterator entries(*this);
    Object& entry = Object::Handle();
    LibraryPrefix& prefix = LibraryPrefix::Handle();
    String& prefixName = String::Handle();
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsLibraryPrefix()) {
        prefix ^= entry.raw();
        ports = prefix.imports();
        for (intptr_t i = 0; i < ports.Length(); i++) {
          ns ^= ports.At(i);
          if (ns.IsNull()) continue;

          JSONObject jsdep(&jsarr);
          jsdep.AddProperty("isDeferred", prefix.is_deferred_load());
          jsdep.AddProperty("isExport", false);
          jsdep.AddProperty("isImport", true);
          prefixName = prefix.name();
          ASSERT(!prefixName.IsNull());
          jsdep.AddProperty("prefix", prefixName.ToCString());
          target = ns.library();
          jsdep.AddProperty("target", target);
        }
      }
    }
  }
  {
    JSONArray jsarr(&jsobj, "variables");
    DictionaryIterator entries(*this);
    Object& entry = Object::Handle();
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsField()) {
        jsarr.AddValue(entry);
      }
    }
  }
  {
    JSONArray jsarr(&jsobj, "functions");
    DictionaryIterator entries(*this);
    Object& entry = Object::Handle();
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsFunction()) {
        const Function& func = Function::Cast(entry);
        if (func.kind() == RawFunction::kRegularFunction ||
            func.kind() == RawFunction::kGetterFunction ||
            func.kind() == RawFunction::kSetterFunction) {
          jsarr.AddValue(func);
        }
      }
    }
  }
  {
    JSONArray jsarr(&jsobj, "scripts");
    Array& scripts = Array::Handle(LoadedScripts());
    Script& script = Script::Handle();
    for (intptr_t i = 0; i < scripts.Length(); i++) {
      script ^= scripts.At(i);
      jsarr.AddValue(script);
    }
  }
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
  ObjectStore* object_store = isolate->object_store();
  GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate, object_store->libraries());
  ASSERT(!libs.IsNull());
  LibraryLoadErrorSet set(HashTables::New<LibraryLoadErrorSet>(libs.Length()));
  object_store->set_library_load_error_table(set.Release());
  Library& lib = Library::Handle(isolate);
  Instance& error = Instance::Handle(isolate);
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
    const intptr_t new_length = length + kIncrementSize;
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
        } else if (import_lib_url.StartsWith(Symbols::DartScheme())) {
          // The newly found object is exported from a Dart system
          // library. It is hidden by the previously found object.
          // We continue to search.
        } else {
          // We found two different objects with the same name.
          return Object::null();
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
    Isolate* isolate = Isolate::Current();
    Api::Scope api_scope(isolate);
    deferred_lib.SetLoadRequested();
    const GrowableObjectArray& pending_deferred_loads =
        GrowableObjectArray::Handle(
            isolate->object_store()->pending_deferred_loads());
    pending_deferred_loads.Add(deferred_lib);
    const String& lib_url = String::Handle(isolate, deferred_lib.url());
    Dart_LibraryTagHandler handler = isolate->library_tag_handler();
    handler(Dart_kImportTag,
            Api::NewHandle(isolate, importer()),
            Api::NewHandle(isolate, lib_url.raw()));
  } else {
    // Another load request is in flight.
    ASSERT(deferred_lib.LoadRequested());
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
          CodePatcher::IsEntryPatched(code) ? "patched" : "unpatched",
          Function::Handle(code.function()).ToCString());
    }
  }

 private:
  const LibraryPrefix& prefix_;
  DISALLOW_COPY_AND_ASSIGN(PrefixDependentArray);
};


void LibraryPrefix::RegisterDependentCode(const Code& code) const {
  ASSERT(is_deferred_load());
  ASSERT(!is_loaded());
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
                                    LibraryPrefix::InstanceSize(),
                                    Heap::kOld);
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
  return OS::SCreate(Thread::Current()->zone(),
      "LibraryPrefix:'%s'", prefix.ToCString());
}


void LibraryPrefix::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


void Namespace::set_metadata_field(const Field& value) const {
  StorePointer(&raw_ptr()->metadata_field_, value.raw());
}


void Namespace::AddMetadata(intptr_t token_pos, const Class& owner_class) {
  ASSERT(Field::Handle(metadata_field()).IsNull());
  Field& field = Field::Handle(Field::New(Symbols::TopLevel(),
                                          true,   // is_static
                                          false,  // is_final
                                          false,  // is_const
                                          false,  // is_reflectable
                                          owner_class,
                                          token_pos));
  field.set_type(Type::Handle(Type::DynamicType()));
  field.SetStaticValue(Array::empty_array(), true);
  set_metadata_field(field);
  owner_class.AddField(field);
}


RawObject* Namespace::GetMetadata() const {
  Field& field = Field::Handle(metadata_field());
  if (field.IsNull()) {
    // There is no metadata for this object.
    return Object::empty_array().raw();
  }
  Object& metadata = Object::Handle();
  metadata = field.StaticValue();
  if (field.StaticValue() == Object::empty_array().raw()) {
    metadata = Parser::ParseMetadata(Class::Handle(field.owner()),
                                     field.token_pos());
    if (metadata.IsArray()) {
      ASSERT(Array::Cast(metadata).raw() != Object::empty_array().raw());
      field.SetStaticValue(Array::Cast(metadata), true);
    }
  }
  return metadata.raw();
}


const char* Namespace::ToCString() const {
  const Library& lib = Library::Handle(library());
  return OS::SCreate(Thread::Current()->zone(),
      "Namespace for library '%s'", lib.ToCString());
}


void Namespace::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
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
RawObject* Namespace::Lookup(const String& name) const {
  Isolate* isolate = Isolate::Current();
  const Library& lib = Library::Handle(isolate, library());
  intptr_t ignore = 0;

  // Lookup the name in the library's symbols.
  Object& obj = Object::Handle(isolate, lib.LookupEntry(name, &ignore));
  if (!Field::IsGetterName(name) &&
      !Field::IsSetterName(name) &&
      (obj.IsNull() || obj.IsLibraryPrefix())) {
    const String& getter_name = String::Handle(Field::LookupGetterSymbol(name));
    if (!getter_name.IsNull()) {
      obj = lib.LookupEntry(getter_name, &ignore);
    }
    if (obj.IsNull()) {
      const String& setter_name =
          String::Handle(Field::LookupSetterSymbol(name));
      if (!setter_name.IsNull()) {
        obj = lib.LookupEntry(setter_name, &ignore);
      }
    }
  }

  // Library prefixes are not exported.
  if (obj.IsNull() || obj.IsLibraryPrefix()) {
    // Lookup in the re-exported symbols.
    obj = lib.LookupReExport(name);
  }
  if (obj.IsNull() || HidesName(name) || obj.IsLibraryPrefix()) {
    return Object::null();
  }
  return obj.raw();
}


RawNamespace* Namespace::New() {
  ASSERT(Object::namespace_class() != Class::null());
  RawObject* raw = Object::Allocate(Namespace::kClassId,
                                    Namespace::InstanceSize(),
                                    Heap::kOld);
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
  Error& error = Error::Handle();
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  Library& lib = Library::Handle();
  Class& cls = Class::Handle();
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      error = cls.EnsureIsFinalized(Isolate::Current());
      if (!error.IsNull()) {
        return error.raw();
      }
      error = Compiler::CompileAllFunctions(cls);
      if (!error.IsNull()) {
        return error.raw();
      }
    }
  }
  return error.raw();
}


// Return Function::null() if function does not exist in libs.
RawFunction* Library::GetFunction(const GrowableArray<Library*>& libs,
                                  const char* class_name,
                                  const char* function_name) {
  Function& func = Function::Handle();
  String& class_str = String::Handle();
  String& func_str = String::Handle();
  Class& cls = Class::Handle();
  for (intptr_t l = 0; l < libs.length(); l++) {
    const Library& lib = *libs[l];
    if (strcmp(class_name, "::") == 0) {
      func_str = Symbols::New(function_name);
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


#if defined(DART_NO_SNAPSHOT)
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
  }                                                                            \

  all_libs.Add(&Library::ZoneHandle(Library::CoreLibrary()));
  CORE_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS);
  CORE_INTEGER_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS);

  all_libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  all_libs.Add(&Library::ZoneHandle(Library::CollectionLibrary()));
  OTHER_RECOGNIZED_LIST(CHECK_FINGERPRINTS);
  INLINE_WHITE_LIST(CHECK_FINGERPRINTS);
  INLINE_BLACK_LIST(CHECK_FINGERPRINTS);
  POLYMORPHIC_TARGET_LIST(CHECK_FINGERPRINTS);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::DeveloperLibrary()));
  DEVELOPER_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::MathLibrary()));
  MATH_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS);

  all_libs.Clear();
  all_libs.Add(&Library::ZoneHandle(Library::TypedDataLibrary()));
  TYPED_DATA_LIB_INTRINSIC_LIST(CHECK_FINGERPRINTS);

#undef CHECK_FINGERPRINTS

Class& cls = Class::Handle();

#define CHECK_FACTORY_FINGERPRINTS(factory_symbol, cid, fp)                    \
  cls = Isolate::Current()->class_table()->At(cid);                            \
  func = cls.LookupFunctionAllowPrivate(Symbols::factory_symbol());            \
  if (func.IsNull()) {                                                         \
    has_errors = true;                                                         \
    OS::Print("Function not found %s.%s\n", cls.ToCString(),                   \
        Symbols::factory_symbol().ToCString());                                \
  } else {                                                                     \
    CHECK_FINGERPRINT2(func, factory_symbol, cid, fp);                         \
  }                                                                            \

  RECOGNIZED_LIST_FACTORY_LIST(CHECK_FACTORY_FINGERPRINTS);

#undef CHECK_FACTORY_FINGERPRINTS

  if (has_errors) {
    FATAL("Fingerprint mismatch.");
  }
}
#endif  // defined(DART_NO_SNAPSHOT).


RawInstructions* Instructions::New(intptr_t size) {
  ASSERT(Object::instructions_class() != Class::null());
  if (size < 0 || size > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Instructions::New: invalid size %" Pd "\n", size);
  }
  Instructions& result = Instructions::Handle();
  {
    uword aligned_size = Instructions::InstanceSize(size);
    RawObject* raw = Object::Allocate(Instructions::kClassId,
                                      aligned_size,
                                      Heap::kCode);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_size(size);
  }
  return result.raw();
}


const char* Instructions::ToCString() const {
  return "Instructions";
}


void Instructions::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("_code", Code::Handle(code()));
  if (ref) {
    return;
  }
  jsobj.AddProperty("_objectPool", ObjectPool::Handle(object_pool()));
}


// Encode integer in SLEB128 format.
void PcDescriptors::EncodeInteger(GrowableArray<uint8_t>* data,
                                  intptr_t value) {
  bool is_last_part = false;
  while (!is_last_part) {
    intptr_t part = value & 0x7f;
    value >>= 7;
    if ((value == 0 && (part & 0x40) == 0) ||
        (value == -1 && (part & 0x40) != 0)) {
      is_last_part = true;
    } else {
      part |= 0x80;
    }
    data->Add(part);
  }
}


// Decode SLEB128 encoded integer. Update byte_index to the next integer.
intptr_t PcDescriptors::DecodeInteger(intptr_t* byte_index) const {
  NoSafepointScope no_safepoint;
  const uint8_t* data = raw_ptr()->data();
  ASSERT(*byte_index < Length());
  uword shift = 0;
  intptr_t value = 0;
  intptr_t part = 0;
  do {
    part = data[(*byte_index)++];
    value |= (part & 0x7f) << shift;
    shift += 7;
  } while ((part & 0x80) != 0);

  if (shift < sizeof(value) * 8 && (part & 0x40) != 0) {
    value |= -(1 << shift);
  }
  return value;
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
    RawObject* raw = Object::Allocate(ObjectPool::kClassId,
                                      size,
                                      Heap::kOld);
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
  const TypedData& array = TypedData::Handle(info_array());
  return static_cast<EntryType>(array.GetInt8(index));
}


const char* ObjectPool::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  return zone->PrintToString("ObjectPool len:%" Pd, Length());
}


void ObjectPool::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }

  {
    JSONArray jsarr(&jsobj, "_entries");
    uword imm;
    Object& obj = Object::Handle();
    for (intptr_t i = 0; i < Length(); i++) {
      switch (InfoAt(i)) {
      case ObjectPool::kTaggedObject:
        obj = ObjectAt(i);
        jsarr.AddValue(obj);
        break;
      case ObjectPool::kImmediate:
        imm = RawValueAt(i);
        jsarr.AddValue64(imm);
        break;
      case ObjectPool::kExternalLabel:
      case ObjectPool::kNativeEntry:
        imm = RawValueAt(i);
        jsarr.AddValueF("0x%" Px, imm);
        break;
      default:
        UNREACHABLE();
      }
    }
  }
}


static const char* DescribeExternalLabel(uword addr) {
  const char* stub_name = StubCode::NameOfStub(addr);
  if (stub_name != NULL) {
    return stub_name;
  }

  return "UNKNOWN";
}


void ObjectPool::DebugPrint() const {
  THR_Print("Object Pool: {\n");
  for (intptr_t i = 0; i < Length(); i++) {
    intptr_t offset = OffsetFromIndex(i);
    THR_Print("  %" Pd " PP+0x%" Px ": ", i, offset);
    if (InfoAt(i) == kTaggedObject) {
      RawObject* obj = ObjectAt(i);
      THR_Print("0x%" Px " %s (obj)\n",
          reinterpret_cast<uword>(obj),
          Object::Handle(obj).ToCString());
    } else if (InfoAt(i) == kExternalLabel) {
      uword addr = RawValueAt(i);
      THR_Print("0x%" Px " (external label: %s)\n",
                addr, DescribeExternalLabel(addr));
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
    RawObject* raw = Object::Allocate(PcDescriptors::kClassId,
                                      size,
                                      Heap::kOld);
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
    RawObject* raw = Object::Allocate(PcDescriptors::kClassId,
                                      size,
                                      Heap::kOld);
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
    case RawPcDescriptors::kDeopt:           return "deopt        ";
    case RawPcDescriptors::kIcCall:          return "ic-call      ";
    case RawPcDescriptors::kUnoptStaticCall: return "unopt-call   ";
    case RawPcDescriptors::kRuntimeCall:     return "runtime-call ";
    case RawPcDescriptors::kOsrEntry:        return "osr-entry    ";
    case RawPcDescriptors::kOther:           return "other        ";
    case RawPcDescriptors::kAnyKind:         UNREACHABLE(); break;
  }
  UNREACHABLE();
  return "";
}


void PcDescriptors::PrintHeaderString() {
  // 4 bits per hex digit + 2 for "0x".
  const int addr_width = (kBitsPerWord / 4) + 2;
  // "*" in a printf format specifier tells it to read the field width from
  // the printf argument list.
  THR_Print("%-*s\tkind    \tdeopt-id\ttok-ix\ttry-ix\n",
            addr_width, "pc");
}


const char* PcDescriptors::ToCString() const {
  // "*" in a printf format specifier tells it to read the field width from
  // the printf argument list.
#define FORMAT "%#-*" Px "\t%s\t%" Pd "\t\t%" Pd "\t%" Pd "\n"
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
      len += OS::SNPrint(NULL, 0, FORMAT, addr_width,
                         iter.PcOffset(),
                         KindAsStr(iter.Kind()),
                         iter.DeoptId(),
                         iter.TokenPos(),
                         iter.TryIndex());
    }
  }
  // Allocate the buffer.
  char* buffer = Thread::Current()->zone()->Alloc<char>(len);
  // Layout the fields in the buffer.
  intptr_t index = 0;
  Iterator iter(*this, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    index += OS::SNPrint((buffer + index), (len - index), FORMAT, addr_width,
                         iter.PcOffset(),
                         KindAsStr(iter.Kind()),
                         iter.DeoptId(),
                         iter.TokenPos(),
                         iter.TryIndex());
  }
  return buffer;
#undef FORMAT
}


void PcDescriptors::PrintToJSONObject(JSONObject* jsobj, bool ref) const {
  AddCommonObjectProperties(jsobj, "Object", ref);
  // TODO(johnmccutchan): Generate a stable id. PcDescriptors hang off a Code
  // object but do not have a back reference to generate an ID.
  jsobj->AddServiceId(*this);
  if (ref) {
    return;
  }
  JSONArray members(jsobj, "members");
  Iterator iter(*this, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    JSONObject descriptor(&members);
    descriptor.AddPropertyF("pcOffset", "%" Px "", iter.PcOffset());
    descriptor.AddProperty("kind", KindAsStr(iter.Kind()));
    descriptor.AddProperty("deoptId", iter.DeoptId());
    // TODO(turnidge): Use AddLocation instead.
    descriptor.AddProperty("tokenPos", iter.TokenPos());
    descriptor.AddProperty("tryIndex", iter.TryIndex());
  }
}


void PcDescriptors::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintToJSONObject(&jsobj, ref);
}


// Verify assumptions (in debug mode only).
// - No two deopt descriptors have the same deoptimization id.
// - No two ic-call descriptors have the same deoptimization id (type feedback).
// A function without unique ids is marked as non-optimizable (e.g., because of
// finally blocks).
void PcDescriptors::Verify(const Function& function) const {
#if defined(DEBUG)
  // TODO(srdjan): Implement a more efficient way to check, currently drop
  // the check for too large number of descriptors.
  if (Length() > 3000) {
    if (FLAG_trace_compiler) {
      OS::Print("Not checking pc decriptors, length %" Pd "\n", Length());
    }
    return;
  }
  // Only check ids for unoptimized code that is optimizable.
  if (!function.IsOptimizable()) {
    return;
  }
  Iterator iter(*this, RawPcDescriptors::kDeopt | RawPcDescriptors::kIcCall);
  while (iter.MoveNext()) {
    // 'deopt_id' is set for kDeopt and kIcCall and must be unique for one kind.
    if (Isolate::IsDeoptAfter(iter.DeoptId())) {
      // TODO(vegorov): some instructions contain multiple calls and have
      // multiple "after" targets recorded. Right now it is benign but might
      // lead to issues in the future. Fix that and enable verification.
      continue;
    }

    Iterator nested(iter);
    while (nested.MoveNext()) {
      if (iter.Kind() == nested.Kind()) {
        ASSERT(nested.DeoptId() != iter.DeoptId());
      }
    }
  }
#endif  // DEBUG
}


bool Stackmap::GetBit(intptr_t bit_index) const {
  ASSERT(InRange(bit_index));
  int byte_index = bit_index >> kBitsPerByteLog2;
  int bit_remainder = bit_index & (kBitsPerByte - 1);
  uint8_t byte_mask = 1U << bit_remainder;
  uint8_t byte = raw_ptr()->data()[byte_index];
  return (byte & byte_mask);
}


void Stackmap::SetBit(intptr_t bit_index, bool value) const {
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


RawStackmap* Stackmap::New(intptr_t pc_offset,
                           BitmapBuilder* bmap,
                           intptr_t register_bit_count) {
  ASSERT(Object::stackmap_class() != Class::null());
  ASSERT(bmap != NULL);
  Stackmap& result = Stackmap::Handle();
  // Guard against integer overflow of the instance size computation.
  intptr_t length = bmap->Length();
  intptr_t payload_size =
      Utils::RoundUp(length, kBitsPerByte) / kBitsPerByte;
  if ((payload_size < 0) ||
      (payload_size > kMaxLengthInBytes)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Stackmap::New: invalid length %" Pd "\n",
           length);
  }
  {
    // Stackmap data objects are associated with a code object, allocate them
    // in old generation.
    RawObject* raw = Object::Allocate(Stackmap::kClassId,
                                      Stackmap::InstanceSize(length),
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  // When constructing a stackmap we store the pc offset in the stackmap's
  // PC. StackmapTableBuilder::FinalizeStackmaps will replace it with the pc
  // address.
  ASSERT(pc_offset >= 0);
  result.SetPcOffset(pc_offset);
  for (intptr_t i = 0; i < length; ++i) {
    result.SetBit(i, bmap->Get(i));
  }
  result.SetRegisterBitCount(register_bit_count);
  return result.raw();
}


RawStackmap* Stackmap::New(intptr_t length,
                           intptr_t register_bit_count,
                           intptr_t pc_offset) {
  ASSERT(Object::stackmap_class() != Class::null());
  Stackmap& result = Stackmap::Handle();
  // Guard against integer overflow of the instance size computation.
  intptr_t payload_size =
  Utils::RoundUp(length, kBitsPerByte) / kBitsPerByte;
  if ((payload_size < 0) ||
      (payload_size > kMaxLengthInBytes)) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in Stackmap::New: invalid length %" Pd "\n",
           length);
  }
  {
    // Stackmap data objects are associated with a code object, allocate them
    // in old generation.
    RawObject* raw = Object::Allocate(Stackmap::kClassId,
                                      Stackmap::InstanceSize(length),
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(length);
  }
  // When constructing a stackmap we store the pc offset in the stackmap's
  // PC. StackmapTableBuilder::FinalizeStackmaps will replace it with the pc
  // address.
  ASSERT(pc_offset >= 0);
  result.SetPcOffset(pc_offset);
  result.SetRegisterBitCount(register_bit_count);
  return result.raw();
}


const char* Stackmap::ToCString() const {
#define FORMAT "%#x: "
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


void Stackmap::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
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


static const char* VarKindString(int kind) {
  switch (kind) {
    case RawLocalVarDescriptors::kStackVar:
      return "StackVar";
      break;
    case RawLocalVarDescriptors::kContextVar:
      return "ContextVar";
      break;
    case RawLocalVarDescriptors::kContextLevel:
      return "ContextLevel";
      break;
    case RawLocalVarDescriptors::kSavedCurrentContext:
      return "CurrentCtx";
      break;
    case RawLocalVarDescriptors::kAsyncOperation:
      return "AsyncOperation";
      break;
    default:
      UNREACHABLE();
      return "Unknown";
  }
}


static int PrintVarInfo(char* buffer, int len,
                        intptr_t i,
                        const String& var_name,
                        const RawLocalVarDescriptors::VarInfo& info) {
  const int8_t kind = info.kind();
  const int32_t index = info.index();
  if (kind == RawLocalVarDescriptors::kContextLevel) {
    return OS::SNPrint(buffer, len,
                       "%2" Pd " %-13s level=%-3d scope=%-3d"
                       " begin=%-3d end=%d\n",
                       i,
                       VarKindString(kind),
                       index,
                       info.scope_id,
                       info.begin_pos,
                       info.end_pos);
  } else if (kind == RawLocalVarDescriptors::kContextVar) {
    return OS::SNPrint(buffer, len,
                       "%2" Pd " %-13s level=%-3d index=%-3d"
                       " begin=%-3d end=%-3d name=%s\n",
                       i,
                       VarKindString(kind),
                       info.scope_id,
                       index,
                       info.begin_pos,
                       info.end_pos,
                       var_name.ToCString());
  } else {
    return OS::SNPrint(buffer, len,
                       "%2" Pd " %-13s scope=%-3d index=%-3d"
                       " begin=%-3d end=%-3d name=%s\n",
                       i,
                       VarKindString(kind),
                       info.scope_id,
                       index,
                       info.begin_pos,
                       info.end_pos,
                       var_name.ToCString());
  }
}


const char* LocalVarDescriptors::ToCString() const {
  if (IsNull()) {
    return "LocalVarDescriptors(NULL)";
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
    num_chars += PrintVarInfo((buffer + num_chars),
                              (len - num_chars),
                              i, var_name, info);
  }
  return buffer;
}


void LocalVarDescriptors::PrintJSONImpl(JSONStream* stream,
                                        bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  // TODO(johnmccutchan): Generate a stable id. LocalVarDescriptors hang off
  // a Code object but do not have a back reference to generate an ID.
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }
  JSONArray members(&jsobj, "members");
  String& var_name = String::Handle();
  for (intptr_t i = 0; i < Length(); i++) {
    RawLocalVarDescriptors::VarInfo info;
    var_name = GetName(i);
    GetInfo(i, &info);
    JSONObject var(&members);
    var.AddProperty("name", var_name.ToCString());
    var.AddProperty("index", static_cast<intptr_t>(info.index()));
    var.AddProperty("beginPos", static_cast<intptr_t>(info.begin_pos));
    var.AddProperty("endPos", static_cast<intptr_t>(info.end_pos));
    var.AddProperty("scopeId", static_cast<intptr_t>(info.scope_id));
    var.AddProperty("kind", KindToStr(info.kind()));
  }
}


const char* LocalVarDescriptors::KindToStr(intptr_t kind) {
  switch (kind) {
    case RawLocalVarDescriptors::kStackVar:
      return "StackVar";
    case RawLocalVarDescriptors::kContextVar:
      return "ContextVar";
    case RawLocalVarDescriptors::kContextLevel:
      return "ContextLevel";
    case RawLocalVarDescriptors::kSavedCurrentContext:
      return "SavedCurrentContext";
    case RawLocalVarDescriptors::kAsyncOperation:
      return "AsyncOperation";
    default:
      UNIMPLEMENTED();
      return NULL;
  }
}

RawLocalVarDescriptors* LocalVarDescriptors::New(intptr_t num_variables) {
  ASSERT(Object::var_descriptors_class() != Class::null());
  if (num_variables < 0 || num_variables > kMaxElements) {
    // This should be caught before we reach here.
    FATAL2("Fatal error in LocalVarDescriptors::New: "
           "invalid num_variables %" Pd ". Maximum is: %d\n",
           num_variables, RawLocalVarDescriptors::kMaxIndex);
  }
  LocalVarDescriptors& result = LocalVarDescriptors::Handle();
  {
    uword size = LocalVarDescriptors::InstanceSize(num_variables);
    RawObject* raw = Object::Allocate(LocalVarDescriptors::kClassId,
                                      size,
                                      Heap::kOld);
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
                                       bool has_catch_all) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  NoSafepointScope no_safepoint;
  RawExceptionHandlers::HandlerInfo* info =
      UnsafeMutableNonPointer(&raw_ptr()->data()[try_index]);
  info->outer_try_index = outer_try_index;
  // Some C compilers warn about the comparison always being true when using <=
  // due to limited range of data type.
  ASSERT((handler_pc_offset == static_cast<uword>(kMaxUint32)) ||
         (handler_pc_offset < static_cast<uword>(kMaxUint32)));
  info->handler_pc_offset = handler_pc_offset;
  info->needs_stacktrace = needs_stacktrace;
  info->has_catch_all = has_catch_all;
}

void ExceptionHandlers::GetHandlerInfo(
    intptr_t try_index,
    RawExceptionHandlers::HandlerInfo* info) const {
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


bool ExceptionHandlers::NeedsStacktrace(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].needs_stacktrace;
}


bool ExceptionHandlers::HasCatchAll(intptr_t try_index) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
  return raw_ptr()->data()[try_index].has_catch_all;
}


void ExceptionHandlers::SetHandledTypes(intptr_t try_index,
                                        const Array& handled_types) const {
  ASSERT((try_index >= 0) && (try_index < num_entries()));
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
    FATAL1("Fatal error in ExceptionHandlers::New(): "
           "invalid num_handlers %" Pd "\n",
           num_handlers);
  }
  ExceptionHandlers& result = ExceptionHandlers::Handle();
  {
    uword size = ExceptionHandlers::InstanceSize(num_handlers);
    RawObject* raw = Object::Allocate(ExceptionHandlers::kClassId,
                                      size,
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->num_entries_, num_handlers);
  }
  const Array& handled_types_data = (num_handlers == 0) ?
      Object::empty_array() :
      Array::Handle(Array::New(num_handlers, Heap::kOld));
  result.set_handled_types_data(handled_types_data);
  return result.raw();
}


RawExceptionHandlers* ExceptionHandlers::New(const Array& handled_types_data) {
  ASSERT(Object::exception_handlers_class() != Class::null());
  const intptr_t num_handlers = handled_types_data.Length();
  if ((num_handlers < 0) || (num_handlers >= kMaxHandlers)) {
    FATAL1("Fatal error in ExceptionHandlers::New(): "
           "invalid num_handlers %" Pd "\n",
           num_handlers);
  }
  ExceptionHandlers& result = ExceptionHandlers::Handle();
  {
    uword size = ExceptionHandlers::InstanceSize(num_handlers);
    RawObject* raw = Object::Allocate(ExceptionHandlers::kClassId,
                                      size,
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->num_entries_, num_handlers);
  }
  result.set_handled_types_data(handled_types_data);
  return result.raw();
}


const char* ExceptionHandlers::ToCString() const {
#define FORMAT1 "%" Pd " => %#x  (%" Pd " types) (outer %d)\n"
#define FORMAT2 "  %d. %s\n"
  if (num_entries() == 0) {
    return "empty ExceptionHandlers\n";
  }
  Array& handled_types = Array::Handle();
  Type& type = Type::Handle();
  RawExceptionHandlers::HandlerInfo info;
  // First compute the buffer size required.
  intptr_t len = 1;  // Trailing '\0'.
  for (intptr_t i = 0; i < num_entries(); i++) {
    GetHandlerInfo(i, &info);
    handled_types = GetHandledTypes(i);
    const intptr_t num_types =
        handled_types.IsNull() ? 0 : handled_types.Length();
    len += OS::SNPrint(NULL, 0, FORMAT1,
                       i,
                       info.handler_pc_offset,
                       num_types,
                       info.outer_try_index);
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
    num_chars += OS::SNPrint((buffer + num_chars),
                             (len - num_chars),
                             FORMAT1,
                             i,
                             info.handler_pc_offset,
                             num_types,
                             info.outer_try_index);
    for (int k = 0; k < num_types; k++) {
      type ^= handled_types.At(k);
      num_chars += OS::SNPrint((buffer + num_chars),
                               (len - num_chars),
                               FORMAT2, k, type.ToCString());
    }
  }
  return buffer;
#undef FORMAT1
#undef FORMAT2
}


void ExceptionHandlers::PrintJSONImpl(JSONStream* stream,
                                      bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


intptr_t DeoptInfo::FrameSize(const TypedData& packed) {
  NoSafepointScope no_safepoint;
  typedef ReadStream::Raw<sizeof(intptr_t), intptr_t> Reader;
  ReadStream read_stream(reinterpret_cast<uint8_t*>(packed.DataAddr(0)),
                         packed.LengthInBytes());
  return Reader::Read(&read_stream);
}


intptr_t DeoptInfo::NumMaterializations(
    const GrowableArray<DeoptInstr*>& unpacked) {
  intptr_t num = 0;
  while (unpacked[num]->kind() == DeoptInstr::kMaterializeObject) {
    num++;
  }
  return num;
}


void DeoptInfo::UnpackInto(const Array& table,
                           const TypedData& packed,
                           GrowableArray<DeoptInstr*>* unpacked,
                           intptr_t length) {
  NoSafepointScope no_safepoint;
  typedef ReadStream::Raw<sizeof(intptr_t), intptr_t> Reader;
  ReadStream read_stream(reinterpret_cast<uint8_t*>(packed.DataAddr(0)),
                         packed.LengthInBytes());
  const intptr_t frame_size = Reader::Read(&read_stream);  // Skip frame size.
  USE(frame_size);

  const intptr_t suffix_length = Reader::Read(&read_stream);
  if (suffix_length != 0) {
    ASSERT(suffix_length > 1);
    const intptr_t info_number = Reader::Read(&read_stream);

    TypedData& suffix = TypedData::Handle();
    Smi& offset = Smi::Handle();
    Smi& reason_and_flags = Smi::Handle();
    DeoptTable::GetEntry(
      table, info_number, &offset, &suffix, &reason_and_flags);
    UnpackInto(table, suffix, unpacked, suffix_length);
  }

  while ((read_stream.PendingBytes() > 0) &&
         (unpacked->length() < length)) {
    const intptr_t instruction = Reader::Read(&read_stream);
    const intptr_t from_index = Reader::Read(&read_stream);
    unpacked->Add(DeoptInstr::Create(instruction, from_index));
  }
}


void DeoptInfo::Unpack(const Array& table,
                       const TypedData& packed,
                       GrowableArray<DeoptInstr*>* unpacked) {
  ASSERT(unpacked->is_empty());

  // Pass kMaxInt32 as the length to unpack all instructions from the
  // packed stream.
  UnpackInto(table, packed, unpacked, kMaxInt32);

  unpacked->Reverse();
}


const char* DeoptInfo::ToCString(const Array& deopt_table,
                                 const TypedData& packed) {
#define FORMAT "[%s]"
  GrowableArray<DeoptInstr*> deopt_instrs;
  Unpack(deopt_table, packed, &deopt_instrs);

  // Compute the buffer size required.
  intptr_t len = 1;  // Trailing '\0'.
  for (intptr_t i = 0; i < deopt_instrs.length(); i++) {
    len += OS::SNPrint(NULL, 0, FORMAT, deopt_instrs[i]->ToCString());
  }

  // Allocate the buffer.
  char* buffer = Thread::Current()->zone()->Alloc<char>(len);

  // Layout the fields in the buffer.
  intptr_t index = 0;
  for (intptr_t i = 0; i < deopt_instrs.length(); i++) {
    index += OS::SNPrint((buffer + index),
                         (len - index),
                         FORMAT,
                         deopt_instrs[i]->ToCString());
  }

  return buffer;
#undef FORMAT
}


// Returns a bool so it can be asserted.
bool DeoptInfo::VerifyDecompression(const GrowableArray<DeoptInstr*>& original,
                                    const Array& deopt_table,
                                    const TypedData& packed) {
  GrowableArray<DeoptInstr*> unpacked;
  Unpack(deopt_table, packed, &unpacked);
  ASSERT(unpacked.length() == original.length());
  for (intptr_t i = 0; i < unpacked.length(); ++i) {
    ASSERT(unpacked[i]->Equals(*original[i]));
  }
  return true;
}


const char* ICData::ToCString() const {
  const String& name = String::Handle(target_name());
  const intptr_t num_args = NumArgsTested();
  const intptr_t num_checks = NumberOfChecks();
  return OS::SCreate(Thread::Current()->zone(),
      "ICData target:'%s' num-args: %" Pd " num-checks: %" Pd "",
      name.ToCString(), num_args, num_checks);
}


void ICData::set_owner(const Function& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->owner_, value.raw());
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
  ASSERT(value <= kMaxInt32);
  StoreNonPointer(&raw_ptr()->deopt_id_, value);
}


void ICData::set_ic_data(const Array& value) const {
  ASSERT(!value.IsNull());
  StorePointer(&raw_ptr()->ic_data_, value.raw());
}


intptr_t ICData::NumArgsTested() const {
  return NumArgsTestedBits::decode(raw_ptr()->state_bits_);
}


void ICData::SetNumArgsTested(intptr_t value) const {
  ASSERT(Utils::IsUint(2, value));
  StoreNonPointer(&raw_ptr()->state_bits_,
                  NumArgsTestedBits::update(value, raw_ptr()->state_bits_));
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


bool ICData::IssuedJSWarning() const {
  return IssuedJSWarningBit::decode(raw_ptr()->state_bits_);
}


void ICData::SetIssuedJSWarning() const {
  StoreNonPointer(&raw_ptr()->state_bits_,
                  IssuedJSWarningBit::update(true, raw_ptr()->state_bits_));
}


bool ICData::MayCheckForJSWarning() const {
  const String& name = String::Handle(target_name());
  // Warning issued from native code.
  // Calling sequence is decoded to obtain ic data in order to check if a
  // warning has already been issued.
  if (name.Equals(Library::PrivateCoreLibName(Symbols::_instanceOf())) ||
      name.Equals(Library::PrivateCoreLibName(Symbols::_as()))) {
    return true;
  }
  // Warning issued in ic miss handler.
  // No decoding necessary, so allow optimization if warning already issued.
  if (name.Equals(Symbols::toString()) && !IssuedJSWarning()) {
    return true;
  }
  return false;
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


intptr_t ICData::NumberOfChecks() const {
  // Do not count the sentinel;
  return (Smi::Value(ic_data()->ptr()->length_) / TestEntryLength()) - 1;
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


void ICData::WriteSentinel(const Array& data) const {
  ASSERT(!data.IsNull());
  for (intptr_t i = 1; i <= TestEntryLength(); i++) {
    data.SetAt(data.Length() - i, smi_illegal_cid());
  }
}


#if defined(DEBUG)
// Used in asserts to verify that a check is not added twice.
bool ICData::HasCheck(const GrowableArray<intptr_t>& cids) const {
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    GrowableArray<intptr_t> class_ids;
    Function& target = Function::Handle();
    GetCheckAt(i, &class_ids, &target);
    bool matches = true;
    for (intptr_t k = 0; k < class_ids.length(); k++) {
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
  set_ic_data(data);
  WriteSentinel(data);
  intptr_t data_pos = old_num * TestEntryLength();
  ASSERT(!target.IsNull());
  data.SetAt(data_pos++, target);
  // Set count to 0 as this is called during compilation, before the
  // call has been executed.
  const Smi& value = Smi::Handle(Smi::New(0));
  data.SetAt(data_pos, value);
}


void ICData::AddCheck(const GrowableArray<intptr_t>& class_ids,
                      const Function& target) const {
  ASSERT(!target.IsNull());
  ASSERT(target.name() == target_name());
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
  const intptr_t new_len = data.Length() + TestEntryLength();
  data = Array::Grow(data, new_len, Heap::kOld);
  set_ic_data(data);
  WriteSentinel(data);
  intptr_t data_pos = old_num * TestEntryLength();
  Smi& value = Smi::Handle();
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    // kIllegalCid is used as terminating value, do not add it.
    ASSERT(class_ids[i] != kIllegalCid);
    value = Smi::New(class_ids[i]);
    data.SetAt(data_pos++, value);
  }
  ASSERT(!target.IsNull());
  data.SetAt(data_pos++, target);
  value = Smi::New(1);
  data.SetAt(data_pos, value);
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

  const intptr_t old_num = NumberOfChecks();
  Array& data = Array::Handle(ic_data());
  const intptr_t new_len = data.Length() + TestEntryLength();
  data = Array::Grow(data, new_len, Heap::kOld);
  set_ic_data(data);
  WriteSentinel(data);
  intptr_t data_pos = old_num * TestEntryLength();
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
  data.SetAt(data_pos + 1, target);
  data.SetAt(data_pos + 2, Smi::Handle(Smi::New(count)));
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
  Function& target = Function::Handle();
  GetCheckAt(index, &class_ids, &target);
  return class_ids[arg_nr];
}


intptr_t ICData::GetReceiverClassIdAt(intptr_t index) const {
  ASSERT(index < NumberOfChecks());
  const intptr_t data_pos = index * TestEntryLength();
  NoSafepointScope no_safepoint;
  RawArray* raw_data = ic_data();
  return Smi::Value(Smi::RawCast(raw_data->ptr()->data()[data_pos]));
}


RawFunction* ICData::GetTargetAt(intptr_t index) const {
  const intptr_t data_pos = index * TestEntryLength() + NumArgsTested();
  ASSERT(Object::Handle(Array::Handle(ic_data()).At(data_pos)).IsFunction());

  NoSafepointScope no_safepoint;
  RawArray* raw_data = ic_data();
  return reinterpret_cast<RawFunction*>(raw_data->ptr()->data()[data_pos]);
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
  const intptr_t data_pos = index * TestEntryLength() +
      CountIndexFor(NumArgsTested());
  data.SetAt(data_pos, Smi::Handle(Smi::New(value)));
}


intptr_t ICData::GetCountAt(intptr_t index) const {
  const Array& data = Array::Handle(ic_data());
  const intptr_t data_pos = index * TestEntryLength() +
      CountIndexFor(NumArgsTested());
  return Smi::Value(Smi::RawCast(data.At(data_pos)));
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


RawFunction* ICData::GetTargetForReceiverClassId(intptr_t class_id) const {
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (GetReceiverClassIdAt(i) == class_id) {
      return GetTargetAt(i);
    }
  }
  return Function::null();
}


RawICData* ICData::AsUnaryClassChecksForCid(
    intptr_t cid, const Function& target) const {
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
      result.AddReceiverCheck(class_id,
                              Function::Handle(GetTargetAt(i)),
                              count);
    }
  }

  return result.raw();
}


bool ICData::AllTargetsHaveSameOwner(intptr_t owner_cid) const {
  if (NumberOfChecks() == 0) return false;
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
  ASSERT(NumberOfChecks() > 0);
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
  Function& target = Function::Handle();
  GrowableArray<intptr_t> class_ids;
  const intptr_t len = NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (GetCountAt(i) > 0) {
      GetCheckAt(i, &class_ids, &target);
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


RawICData* ICData::New() {
  ICData& result = ICData::Handle();
  {
    // IC data objects are long living objects, allocate them in old generation.
    RawObject* raw = Object::Allocate(ICData::kClassId,
                                      ICData::InstanceSize(),
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_deopt_id(Isolate::kNoDeoptId);
  result.set_state_bits(0);
  return result.raw();
}


RawICData* ICData::New(const Function& owner,
                       const String& target_name,
                       const Array& arguments_descriptor,
                       intptr_t deopt_id,
                       intptr_t num_args_tested) {
  ASSERT(!owner.IsNull());
  ASSERT(!target_name.IsNull());
  ASSERT(!arguments_descriptor.IsNull());
  ASSERT(Object::icdata_class() != Class::null());
  ASSERT(num_args_tested >= 0);
  ICData& result = ICData::Handle();
  {
    // IC data objects are long living objects, allocate them in old generation.
    RawObject* raw = Object::Allocate(ICData::kClassId,
                                      ICData::InstanceSize(),
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_owner(owner);
  result.set_target_name(target_name);
  result.set_arguments_descriptor(arguments_descriptor);
  result.set_deopt_id(deopt_id);
  result.set_state_bits(0);
  result.SetNumArgsTested(num_args_tested);
  // Number of array elements in one test entry.
  intptr_t len = result.TestEntryLength();
  // IC data array must be null terminated (sentinel entry).
  const Array& ic_data = Array::Handle(Array::New(len, Heap::kOld));
  result.set_ic_data(ic_data);
  result.WriteSentinel(ic_data);
  return result.raw();
}


RawICData* ICData::NewFrom(const ICData& from, intptr_t num_args_tested) {
  const ICData& result = ICData::Handle(ICData::New(
      Function::Handle(from.owner()),
      String::Handle(from.target_name()),
      Array::Handle(from.arguments_descriptor()),
      from.deopt_id(),
      num_args_tested));
  // Copy deoptimization reasons.
  result.SetDeoptReasons(from.DeoptReasons());
  return result.raw();
}


void ICData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Object", ref);
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("_owner", Object::Handle(owner()));
  jsobj.AddProperty("_selector", String::Handle(target_name()).ToCString());
  if (ref) {
    return;
  }
  jsobj.AddProperty("_argumentsDescriptor",
                    Object::Handle(arguments_descriptor()));
  jsobj.AddProperty("_entries", Object::Handle(ic_data()));
}


void ICData::PrintToJSONArray(const JSONArray& jsarray,
                              intptr_t token_pos,
                              bool is_static_call) const {
  Isolate* isolate = Isolate::Current();
  Class& cls = Class::Handle();
  Function& func = Function::Handle();

  JSONObject jsobj(&jsarray);
  jsobj.AddProperty("name", String::Handle(target_name()).ToCString());
  // TODO(turnidge): Use AddLocation instead.
  jsobj.AddProperty("tokenPos", token_pos);
  // TODO(rmacnak): Figure out how to stringify DeoptReasons().
  // jsobj.AddProperty("deoptReasons", ...);

  JSONArray cache_entries(&jsobj, "cacheEntries");
  for (intptr_t i = 0; i < NumberOfChecks(); i++) {
    func = GetTargetAt(i);
    if (is_static_call) {
      cls ^= func.Owner();
    } else {
      intptr_t cid = GetReceiverClassIdAt(i);
      cls ^= isolate->class_table()->At(cid);
    }
    intptr_t count = GetCountAt(i);
    JSONObject cache_entry(&cache_entries);
    if (cls.IsTopLevel()) {
      cache_entry.AddProperty("receiverContainer",
                              Library::Handle(cls.library()));
    } else {
      cache_entry.AddProperty("receiverContainer", cls);
    }
    cache_entry.AddProperty("count", count);
    cache_entry.AddProperty("target", func);
  }
}


static Token::Kind RecognizeArithmeticOp(const String& name) {
  ASSERT(name.IsSymbol());
  if (name.raw() == Symbols::Plus().raw()) {
    return Token::kADD;
  } else if (name.raw() == Symbols::Minus().raw()) {
    return Token::kSUB;
  } else if (name.raw() == Symbols::Star().raw()) {
    return Token::kMUL;
  } else if (name.raw() == Symbols::Slash().raw()) {
    return Token::kDIV;
  } else if (name.raw() == Symbols::TruncDivOperator().raw()) {
    return Token::kTRUNCDIV;
  } else if (name.raw() == Symbols::Percent().raw()) {
    return Token::kMOD;
  } else if (name.raw() == Symbols::BitOr().raw()) {
    return Token::kBIT_OR;
  } else if (name.raw() == Symbols::Ampersand().raw()) {
    return Token::kBIT_AND;
  } else if (name.raw() == Symbols::Caret().raw()) {
    return Token::kBIT_XOR;
  } else if (name.raw() == Symbols::LeftShiftOperator().raw()) {
    return Token::kSHL;
  } else if (name.raw() == Symbols::RightShiftOperator().raw()) {
    return Token::kSHR;
  } else if (name.raw() == Symbols::Tilde().raw()) {
    return Token::kBIT_NOT;
  } else if (name.raw() == Symbols::UnaryMinus().raw()) {
    return Token::kNEGATE;
  }
  return Token::kILLEGAL;
}


bool ICData::HasRangeFeedback() const {
  const String& target = String::Handle(target_name());
  const Token::Kind token_kind = RecognizeArithmeticOp(target);
  if (!Token::IsBinaryArithmeticOperator(token_kind) &&
      !Token::IsUnaryArithmeticOperator(token_kind)) {
    return false;
  }

  bool initialized = false;
  Function& t = Function::Handle();
  const intptr_t len = NumberOfChecks();
  GrowableArray<intptr_t> class_ids;
  for (intptr_t i = 0; i < len; i++) {
    if (IsUsedAt(i)) {
      initialized = true;
      GetCheckAt(i, &class_ids, &t);
      for (intptr_t j = 0; j < class_ids.length(); j++) {
        const intptr_t cid = class_ids[j];
        if ((cid != kSmiCid) && (cid != kMintCid)) {
          return false;
        }
      }
    }
  }

  return initialized;
}


ICData::RangeFeedback ICData::DecodeRangeFeedbackAt(intptr_t idx) const {
  ASSERT((0 <= idx) && (idx < 3));
  const uint32_t raw_feedback =
      RangeFeedbackBits::decode(raw_ptr()->state_bits_);
  const uint32_t feedback =
      (raw_feedback >> (idx * kBitsPerRangeFeedback)) & kRangeFeedbackMask;
  if ((feedback & kInt64RangeBit) != 0) {
    return kInt64Range;
  }

  if ((feedback & kUint32RangeBit) != 0) {
    if ((feedback & kSignedRangeBit) == 0) {
      return kUint32Range;
    }

    // Check if Smi is large enough to accomodate Int33: a mixture of Uint32
    // and negative Int32 values.
    return (kSmiBits < 33) ? kInt64Range : kSmiRange;
  }

  if ((feedback & kInt32RangeBit) != 0) {
    return kInt32Range;
  }

  return kSmiRange;
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
  return Smi::Value(Smi::RawCast(
      comments_.At(idx * kNumberOfEntries + kPCOffsetEntry)));
}


void Code::Comments::SetPCOffsetAt(intptr_t idx, intptr_t pc)  {
  comments_.SetAt(idx * kNumberOfEntries + kPCOffsetEntry,
                  Smi::Handle(Smi::New(pc)));
}


RawString* Code::Comments::CommentAt(intptr_t idx) const {
  return String::RawCast(comments_.At(idx * kNumberOfEntries + kCommentEntry));
}


void Code::Comments::SetCommentAt(intptr_t idx, const String& comment) {
  comments_.SetAt(idx * kNumberOfEntries + kCommentEntry, comment);
}


Code::Comments::Comments(const Array& comments)
    : comments_(comments) {
}


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
  INC_STAT(Thread::Current(),
           total_code_size,
           maps.IsNull() ? 0 : maps.Length() * sizeof(uword));
}


void Code::set_deopt_info_array(const Array& array) const {
  ASSERT(array.IsOld());
  StorePointer(&raw_ptr()->deopt_info_array_, array.raw());
}


void Code::set_static_calls_target_table(const Array& value) const {
  StorePointer(&raw_ptr()->static_calls_target_table_, value.raw());
#if defined(DEBUG)
  // Check that the table is sorted by pc offsets.
  // FlowGraphCompiler::AddStaticCallTarget adds pc-offsets to the table while
  // emitting assembly. This guarantees that every succeeding pc-offset is
  // larger than the previously added one.
  for (intptr_t i = kSCallTableEntryLength;
      i < value.Length();
      i += kSCallTableEntryLength) {
    ASSERT(value.At(i - kSCallTableEntryLength) < value.At(i));
  }
#endif  // DEBUG
}


bool Code::HasBreakpoint() const {
  return Isolate::Current()->debugger()->HasBreakpoint(*this);
}


RawTypedData* Code::GetDeoptInfoAtPc(uword pc,
                                     ICData::DeoptReasonId* deopt_reason,
                                     uint32_t* deopt_flags) const {
  ASSERT(is_optimized());
  const Instructions& instrs = Instructions::Handle(instructions());
  uword code_entry = instrs.EntryPoint();
  const Array& table = Array::Handle(deopt_info_array());
  ASSERT(!table.IsNull());
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
}


intptr_t Code::BinarySearchInSCallTable(uword pc) const {
  NoSafepointScope no_safepoint;
  const Array& table = Array::Handle(raw_ptr()->static_calls_target_table_);
  RawObject* key = reinterpret_cast<RawObject*>(Smi::New(pc - EntryPoint()));
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
  return -1;
}


RawFunction* Code::GetStaticCallTargetFunctionAt(uword pc) const {
  const intptr_t i = BinarySearchInSCallTable(pc);
  if (i < 0) {
    return Function::null();
  }
  const Array& array =
      Array::Handle(raw_ptr()->static_calls_target_table_);
  Function& function = Function::Handle();
  function ^= array.At(i + kSCallTableFunctionEntry);
  return function.raw();
}


RawCode* Code::GetStaticCallTargetCodeAt(uword pc) const {
  const intptr_t i = BinarySearchInSCallTable(pc);
  if (i < 0) {
    return Code::null();
  }
  const Array& array =
      Array::Handle(raw_ptr()->static_calls_target_table_);
  Code& code = Code::Handle();
  code ^= array.At(i + kSCallTableCodeEntry);
  return code.raw();
}


void Code::SetStaticCallTargetCodeAt(uword pc, const Code& code) const {
  const intptr_t i = BinarySearchInSCallTable(pc);
  ASSERT(i >= 0);
  const Array& array =
      Array::Handle(raw_ptr()->static_calls_target_table_);
  ASSERT(code.IsNull() ||
         (code.function() == array.At(i + kSCallTableFunctionEntry)));
  array.SetAt(i + kSCallTableCodeEntry, code);
}


void Code::SetStubCallTargetCodeAt(uword pc, const Code& code) const {
  const intptr_t i = BinarySearchInSCallTable(pc);
  ASSERT(i >= 0);
  const Array& array =
      Array::Handle(raw_ptr()->static_calls_target_table_);
#if defined(DEBUG)
  if (array.At(i + kSCallTableFunctionEntry) == Function::null()) {
    ASSERT(!code.IsNull() && Object::Handle(code.owner()).IsClass());
  } else {
    ASSERT(code.IsNull() ||
           (code.function() == array.At(i + kSCallTableFunctionEntry)));
  }
#endif
  array.SetAt(i + kSCallTableCodeEntry, code);
}


void Code::Disassemble(DisassemblyFormatter* formatter) const {
  const bool fix_patch = CodePatcher::CodeIsPatchable(*this) &&
                         CodePatcher::IsEntryPatched(*this);
  if (fix_patch) {
    // The disassembler may choke on illegal instructions if the code has been
    // patched, un-patch the code before disassembling and re-patch after.
    CodePatcher::RestoreEntry(*this);
  }
  const Instructions& instr = Instructions::Handle(instructions());
  uword start = instr.EntryPoint();
  if (formatter == NULL) {
    Disassembler::Disassemble(start, start + instr.size(), *this);
  } else {
    Disassembler::Disassemble(start, start + instr.size(), formatter, *this);
  }
  if (fix_patch) {
    // Redo the patch.
    CodePatcher::PatchEntry(*this);
  }
}


const Code::Comments& Code::comments() const  {
  Comments* comments = new Code::Comments(Array::Handle(raw_ptr()->comments_));
  return *comments;
}


void Code::set_comments(const Code::Comments& comments) const {
  ASSERT(comments.comments_.IsOld());
  StorePointer(&raw_ptr()->comments_, comments.comments_.raw());
}


void Code::SetPrologueOffset(intptr_t offset) const {
  ASSERT(offset >= 0);
  StoreSmi(
      reinterpret_cast<RawSmi* const *>(&raw_ptr()->return_address_metadata_),
      Smi::New(offset));
}


intptr_t Code::GetPrologueOffset() const {
  const Object& object = Object::Handle(raw_ptr()->return_address_metadata_);
  // In the future we may put something other than a smi in
  // |return_address_metadata_|.
  if (object.IsNull() || !object.IsSmi()) {
    return -1;
  }
  return Smi::Cast(object).Value();
}


RawArray* Code::GetInlinedIntervals() const {
  const Array& metadata = Array::Handle(raw_ptr()->inlined_metadata_);
  if (metadata.IsNull()) {
    return metadata.raw();
  }
  return reinterpret_cast<RawArray*>(
      metadata.At(RawCode::kInlinedIntervalsIndex));
}


void Code::SetInlinedIntervals(const Array& value) const {
  if (raw_ptr()->inlined_metadata_ == Array::null()) {
    StorePointer(&raw_ptr()->inlined_metadata_,
                 Array::New(RawCode::kInlinedMetadataSize, Heap::kOld));
  }
  const Array& metadata = Array::Handle(raw_ptr()->inlined_metadata_);
  ASSERT(!metadata.IsNull());
  ASSERT(metadata.IsOld());
  ASSERT(value.IsOld());
  metadata.SetAt(RawCode::kInlinedIntervalsIndex, value);
}


RawArray* Code::GetInlinedIdToFunction() const {
  const Array& metadata = Array::Handle(raw_ptr()->inlined_metadata_);
  if (metadata.IsNull()) {
    return metadata.raw();
  }
  return reinterpret_cast<RawArray*>(
      metadata.At(RawCode::kInlinedIdToFunctionIndex));
}


void Code::SetInlinedIdToFunction(const Array& value) const {
  if (raw_ptr()->inlined_metadata_ == Array::null()) {
    StorePointer(&raw_ptr()->inlined_metadata_,
                 Array::New(RawCode::kInlinedMetadataSize, Heap::kOld));
  }
  const Array& metadata = Array::Handle(raw_ptr()->inlined_metadata_);
  ASSERT(!metadata.IsNull());
  ASSERT(metadata.IsOld());
  ASSERT(value.IsOld());
  metadata.SetAt(RawCode::kInlinedIdToFunctionIndex, value);
}


RawArray* Code::GetInlinedCallerIdMap() const {
  const Array& metadata = Array::Handle(raw_ptr()->inlined_metadata_);
  if (metadata.IsNull()) {
    return metadata.raw();
  }
  return reinterpret_cast<RawArray*>(
      metadata.At(RawCode::kInlinedCallerIdMapIndex));
}


void Code::SetInlinedCallerIdMap(const Array& value) const {
  if (raw_ptr()->inlined_metadata_ == Array::null()) {
    StorePointer(&raw_ptr()->inlined_metadata_,
                 Array::New(RawCode::kInlinedMetadataSize, Heap::kOld));
  }
  const Array& metadata = Array::Handle(raw_ptr()->inlined_metadata_);
  ASSERT(!metadata.IsNull());
  ASSERT(metadata.IsOld());
  ASSERT(value.IsOld());
  metadata.SetAt(RawCode::kInlinedCallerIdMapIndex, value);
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
    result.set_entry_patch_pc_offset(kInvalidPc);
    result.set_patch_code_pc_offset(kInvalidPc);
    result.set_lazy_deopt_pc_offset(kInvalidPc);
    result.set_pc_descriptors(Object::empty_descriptors());
  }
  return result.raw();
}


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
  Instructions& instrs =
      Instructions::ZoneHandle(Instructions::New(assembler->CodeSize()));
  INC_STAT(Thread::Current(), total_instr_size, assembler->CodeSize());
  INC_STAT(Thread::Current(), total_code_size, assembler->CodeSize());

  // Copy the instructions into the instruction area and apply all fixups.
  // Embedded pointers are still in handles at this point.
  MemoryRegion region(reinterpret_cast<void*>(instrs.EntryPoint()),
                      instrs.size());
  assembler->FinalizeInstructions(region);
  VerifiedMemory::Accept(region.start(), region.size());
  CPU::FlushICache(instrs.EntryPoint(), instrs.size());

  code.set_compile_timestamp(OS::GetCurrentTimeMicros());
  CodeObservers::NotifyAll(name,
                           instrs.EntryPoint(),
                           assembler->prologue_offset(),
                           instrs.size(),
                           optimized);
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
    instrs.set_code(code.raw());
    code.set_instructions(instrs.raw());
    code.set_is_alive(true);

    // Set object pool in Instructions object.
    INC_STAT(Thread::Current(),
             total_code_size, object_pool.Length() * sizeof(uintptr_t));
    instrs.set_object_pool(object_pool.raw());

    if (FLAG_write_protect_code) {
      uword address = RawObject::ToAddr(instrs.raw());
      bool status = VirtualMemory::Protect(
          reinterpret_cast<void*>(address),
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
  INC_STAT(Thread::Current(),
           total_code_size, code.comments().comments_.Length());
  return code.raw();
}


RawCode* Code::FinalizeCode(const Function& function,
                            Assembler* assembler,
                            bool optimized) {
  // Calling ToLibNamePrefixedQualifiedCString is very expensive,
  // try to avoid it.
  if (CodeObservers::AreActive()) {
    return FinalizeCode(function.ToLibNamePrefixedQualifiedCString(),
                        assembler,
                        optimized);
  } else {
    return FinalizeCode("", assembler);
  }
}


// Check if object matches find condition.
bool Code::FindRawCodeVisitor::FindObject(RawObject* obj) const {
  return RawInstructions::ContainsPC(obj, pc_);
}


RawCode* Code::LookupCodeInIsolate(Isolate* isolate, uword pc) {
  ASSERT((isolate == Isolate::Current()) || (isolate == Dart::vm_isolate()));
  NoSafepointScope no_safepoint;
  FindRawCodeVisitor visitor(pc);
  RawInstructions* instr;
  if (isolate->heap() == NULL) {
    return Code::null();
  }
  instr = isolate->heap()->FindObjectInCodeSpace(&visitor);
  if (instr != Instructions::null()) {
    return instr->ptr()->code_;
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
      (code.EntryPoint() == pc)) {
    // Found code in isolate.
    return code.raw();
  }
  code ^= Code::LookupCodeInVmIsolate(pc);
  if (!code.IsNull() && (code.compile_timestamp() == timestamp) &&
      (code.EntryPoint() == pc)) {
    // Found code in VM isolate.
    return code.raw();
  }
  return Code::null();
}


intptr_t Code::GetTokenIndexOfPC(uword pc) const {
  uword pc_offset = pc - EntryPoint();
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return iter.TokenPos();
    }
  }
  return -1;
}


uword Code::GetPcForDeoptId(intptr_t deopt_id,
                            RawPcDescriptors::Kind kind) const {
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, kind);
  while (iter.MoveNext()) {
    if (iter.DeoptId() == deopt_id) {
      uword pc_offset = iter.PcOffset();
      uword pc = EntryPoint() + pc_offset;
      ASSERT(ContainsInstructionAt(pc));
      return pc;
    }
  }
  return 0;
}


intptr_t Code::GetDeoptIdForOsr(uword pc) const {
  uword pc_offset = pc - EntryPoint();
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kOsrEntry);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return iter.DeoptId();
    }
  }
  return Isolate::kNoDeoptId;
}


const char* Code::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  if (IsStubCode()) {
    const char* name = StubCode::NameOfStub(EntryPoint());
    return zone->PrintToString("[stub: %s]", name);
  } else {
    return zone->PrintToString("Code entry:%" Px, EntryPoint());
  }
}


RawString* Code::Name() const {
  const Object& obj = Object::Handle(owner());
  if (obj.IsNull()) {
    // Regular stub.
    const char* name = StubCode::NameOfStub(EntryPoint());
    ASSERT(name != NULL);
    const String& stub_name = String::Handle(String::New(name));
    return String::Concat(Symbols::StubPrefix(), stub_name);
  } else if (obj.IsClass()) {
    // Allocation stub.
    const Class& cls = Class::Cast(obj);
    String& cls_name = String::Handle(cls.Name());
    ASSERT(!cls_name.IsNull());
    return String::Concat(Symbols::AllocationStubFor(), cls_name);
  } else {
    ASSERT(obj.IsFunction());
    // Dart function.
    return Function::Cast(obj).name();
  }
}


RawString* Code::PrettyName() const {
  const Object& obj = Object::Handle(owner());
  if (obj.IsNull()) {
    // Regular stub.
    const char* name = StubCode::NameOfStub(EntryPoint());
    ASSERT(name != NULL);
    const String& stub_name = String::Handle(String::New(name));
    return String::Concat(Symbols::StubPrefix(), stub_name);
  } else if (obj.IsClass()) {
    // Allocation stub.
    const Class& cls = Class::Cast(obj);
    String& cls_name = String::Handle(cls.Name());
    ASSERT(!cls_name.IsNull());
    return String::Concat(Symbols::AllocationStubFor(), cls_name);
  } else {
    ASSERT(obj.IsFunction());
    // Dart function.
    return Function::Cast(obj).QualifiedPrettyName();
  }
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


void Code::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Code", ref);
  jsobj.AddFixedServiceId("code/%" Px64"-%" Px "",
                          compile_timestamp(),
                          EntryPoint());
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name, vm_name);
  const bool is_stub = IsStubCode() || IsAllocationStubCode();
  if (is_stub) {
    jsobj.AddProperty("kind", "Stub");
  } else {
    jsobj.AddProperty("kind", "Dart");
  }
  jsobj.AddProperty("_optimized", is_optimized());
  if (ref) {
    return;
  }
  const Object& obj = Object::Handle(owner());
  if (obj.IsFunction()) {
    jsobj.AddProperty("function", obj);
  } else {
    // Generate a fake function reference.
    JSONObject func(&jsobj, "function");
    func.AddProperty("type", "@Function");
    func.AddProperty("_kind", "Stub");
    func.AddProperty("name", user_name.ToCString());
    AddNameProperties(&func, user_name, vm_name);
  }
  jsobj.AddPropertyF("_startAddress", "%" Px "", EntryPoint());
  jsobj.AddPropertyF("_endAddress", "%" Px "", EntryPoint() + Size());
  jsobj.AddProperty("_alive", is_alive());
  const ObjectPool& object_pool = ObjectPool::Handle(GetObjectPool());
  jsobj.AddProperty("_objectPool", object_pool);
  {
    JSONArray jsarr(&jsobj, "_disassembly");
    if (is_alive()) {
      // Only disassemble alive code objects.
      DisassembleToJSONStream formatter(jsarr);
      Disassemble(&formatter);
    }
  }
  const PcDescriptors& descriptors = PcDescriptors::Handle(pc_descriptors());
  if (!descriptors.IsNull()) {
    JSONObject desc(&jsobj, "_descriptors");
    descriptors.PrintToJSONObject(&desc, false);
  }
  const Array& inlined_function_table = Array::Handle(GetInlinedIdToFunction());
  if (!inlined_function_table.IsNull() &&
      (inlined_function_table.Length() > 0)) {
    JSONArray inlined_functions(&jsobj, "_inlinedFunctions");
    Function& function = Function::Handle();
    for (intptr_t i = 0; i < inlined_function_table.Length(); i++) {
      function ^= inlined_function_table.At(i);
      ASSERT(!function.IsNull());
      inlined_functions.AddValue(function);
    }
  }
  const Array& intervals = Array::Handle(GetInlinedIntervals());
  if (!intervals.IsNull() && (intervals.Length() > 0)) {
    Smi& start = Smi::Handle();
    Smi& end = Smi::Handle();
    Smi& temp_smi = Smi::Handle();
    JSONArray inline_intervals(&jsobj, "_inlinedIntervals");
    for (intptr_t i = 0; i < intervals.Length() - Code::kInlIntNumEntries;
         i += Code::kInlIntNumEntries) {
      start ^= intervals.At(i + Code::kInlIntStart);
      if (start.IsNull()) {
        continue;
      }
      end ^= intervals.At(i + Code::kInlIntNumEntries + Code::kInlIntStart);

      // Format: [start, end, inline functions...]
      JSONArray inline_interval(&inline_intervals);
      inline_interval.AddValue(start.Value());
      inline_interval.AddValue(end.Value());

      temp_smi ^= intervals.At(i + Code::kInlIntInliningId);
      intptr_t inlining_id = temp_smi.Value();
      ASSERT(inlining_id >= 0);
      intptr_t caller_id = GetCallerId(inlining_id);
      while (inlining_id >= 0) {
        inline_interval.AddValue(inlining_id);
        inlining_id = caller_id;
        caller_id = GetCallerId(inlining_id);
      }
    }
  }
}


uword Code::GetEntryPatchPc() const {
  return (entry_patch_pc_offset() != kInvalidPc)
      ? EntryPoint() + entry_patch_pc_offset() : 0;
}


uword Code::GetPatchCodePc() const {
  return (patch_code_pc_offset() != kInvalidPc)
      ? EntryPoint() + patch_code_pc_offset() : 0;
}


uword Code::GetLazyDeoptPc() const {
  return (lazy_deopt_pc_offset() != kInvalidPc)
      ? EntryPoint() + lazy_deopt_pc_offset() : 0;
}


RawStackmap* Code::GetStackmap(
    uint32_t pc_offset, Array* maps, Stackmap* map) const {
  // This code is used during iterating frames during a GC and hence it
  // should not in turn start a GC.
  NoSafepointScope no_safepoint;
  if (stackmaps() == Array::null()) {
    // No stack maps are present in the code object which means this
    // frame relies on tagged pointers.
    return Stackmap::null();
  }
  // A stack map is present in the code object, use the stack map to visit
  // frame slots which are marked as having objects.
  *maps = stackmaps();
  *map = Stackmap::null();
  for (intptr_t i = 0; i < maps->Length(); i++) {
    *map ^= maps->At(i);
    ASSERT(!map->IsNull());
    if (map->PcOffset() == pc_offset) {
      return map->raw();  // We found a stack map for this frame.
    }
  }
  ASSERT(!is_optimized());
  return Stackmap::null();
}


intptr_t Code::GetCallerId(intptr_t inlined_id) const {
  if (inlined_id < 0) {
    return -1;
  }
  const Array& map = Array::Handle(GetInlinedCallerIdMap());
  if (map.IsNull() || (map.Length() == 0)) {
    return -1;
  }
  Smi& smi = Smi::Handle();
  smi ^= map.At(inlined_id);
  return smi.Value();
}


void Code::GetInlinedFunctionsAt(
    intptr_t offset, GrowableArray<Function*>* fs) const {
  fs->Clear();
  const Array& intervals = Array::Handle(GetInlinedIntervals());
  if (intervals.IsNull() || (intervals.Length() == 0)) {
    // E.g., for code stubs.
    return;
  }
  // First find the right interval. TODO(srdjan): use binary search since
  // intervals are sorted.
  Smi& start = Smi::Handle();
  Smi& end = Smi::Handle();
  intptr_t found_interval_ix = intervals.Length() - Code::kInlIntNumEntries;
  for (intptr_t i = 0; i < intervals.Length() - Code::kInlIntNumEntries;
       i += Code::kInlIntNumEntries) {
    start ^= intervals.At(i + Code::kInlIntStart);
    if (!start.IsNull()) {
      end ^= intervals.At(i + Code::kInlIntNumEntries + Code::kInlIntStart);
      if ((start.Value() <= offset) && (offset < end.Value())) {
        found_interval_ix = i;
        break;
      }
    }
  }

  // Find all functions.
  const Array& id_map = Array::Handle(GetInlinedIdToFunction());
  Smi& temp_smi = Smi::Handle();
  temp_smi ^= intervals.At(found_interval_ix + Code::kInlIntInliningId);
  intptr_t inlining_id = temp_smi.Value();
  ASSERT(inlining_id >= 0);
  intptr_t caller_id = GetCallerId(inlining_id);
  while (inlining_id >= 0) {
    Function& function = Function::ZoneHandle();
    function  ^= id_map.At(inlining_id);
    fs->Add(&function);
    inlining_id = caller_id;
    caller_id = GetCallerId(inlining_id);
  }
}


void Code::DumpInlinedIntervals() const {
  LogBlock lb;
  THR_Print("Inlined intervals:\n");
  const Array& intervals = Array::Handle(GetInlinedIntervals());
  if (intervals.IsNull() || (intervals.Length() == 0)) return;
  Smi& start = Smi::Handle();
  Smi& inlining_id = Smi::Handle();
  GrowableArray<Function*> inlined_functions;
  const Function& inliner = Function::Handle(function());
  for (intptr_t i = 0; i < intervals.Length(); i += Code::kInlIntNumEntries) {
    start ^= intervals.At(i + Code::kInlIntStart);
    ASSERT(!start.IsNull());
    if (start.IsNull()) continue;
    inlining_id ^= intervals.At(i + Code::kInlIntInliningId);
    THR_Print("  %" Px " iid: %" Pd " ; ", start.Value(), inlining_id.Value());
    inlined_functions.Clear();

    THR_Print("inlined: ");
    GetInlinedFunctionsAt(start.Value(), &inlined_functions);

    for (intptr_t j = 0; j < inlined_functions.length(); j++) {
      const char* name = inlined_functions[j]->ToQualifiedCString();
      THR_Print("  %s <-", name);
    }
    if (inlined_functions[inlined_functions.length() - 1]->raw() !=
           inliner.raw()) {
      THR_Print(" (ERROR, missing inliner)\n");
    } else {
      THR_Print("\n");
    }
  }
  THR_Print("Inlined ids:\n");
  const Array& id_map = Array::Handle(GetInlinedIdToFunction());
  Function& function = Function::Handle();
  for (intptr_t i = 0; i < id_map.Length(); i++) {
    function ^= id_map.At(i);
    if (!function.IsNull()) {
      THR_Print("  %" Pd ": %s\n", i, function.ToQualifiedCString());
    }
  }
  THR_Print("Caller Inlining Ids:\n");
  const Array& caller_map = Array::Handle(GetInlinedCallerIdMap());
  Smi& smi = Smi::Handle();
  for (intptr_t i = 0; i < caller_map.Length(); i++) {
    smi ^= caller_map.At(i);
    THR_Print("  iid: %" Pd " caller iid: %" Pd "\n", i, smi.Value());
  }
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
    RawObject* raw = Object::Allocate(Context::kClassId,
                                      Context::InstanceSize(num_variables),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_num_variables(num_variables);
  }
  return result.raw();
}


const char* Context::ToCString() const {
  if (IsNull()) {
    return "Context (Null)";
  }
  Zone* zone = Thread::Current()->zone();
  const Context& parent_ctx = Context::Handle(parent());
  if (parent_ctx.IsNull()) {
    return zone->PrintToString("Context@%p num_variables:% " Pd "",
                               this->raw(), num_variables());
  } else {
    const char* parent_str = parent_ctx.ToCString();
    return zone->PrintToString(
        "Context@%p num_variables:% " Pd " parent:{ %s }",
        this->raw(), num_variables(), parent_str);
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
    THR_Print("[%" Pd "] = %s\n", i, obj.ToCString());
  }

  const Context& parent_ctx = Context::Handle(parent());
  if (!parent_ctx.IsNull()) {
    parent_ctx.Dump(indent + 2);
  }
  IndentN(indent);
  THR_Print("}\n");
}


void Context::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  // TODO(turnidge): Should the user level type for Context be Context
  // or Object?
  AddCommonObjectProperties(&jsobj, "Context", ref);
  jsobj.AddServiceId(*this);

  jsobj.AddProperty("length", num_variables());

  if (ref) {
    return;
  }

  const Context& parent_context = Context::Handle(parent());
  if (!parent_context.IsNull()) {
    jsobj.AddProperty("parent", parent_context);
  }

  JSONArray jsarr(&jsobj, "variables");
  Object& var = Object::Handle();
  for (intptr_t index = 0; index < num_variables(); index++) {
    var = At(index);
    JSONObject jselement(&jsarr);
    jselement.AddProperty("value", var);
  }
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
    RawObject* raw = Object::Allocate(ContextScope::kClassId,
                                      size,
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_num_variables(num_variables);
    result.set_is_implicit(is_implicit);
  }
  return result.raw();
}


intptr_t ContextScope::TokenIndexAt(intptr_t scope_index) const {
  return Smi::Value(VariableDescAddr(scope_index)->token_pos);
}


void ContextScope::SetTokenIndexAt(intptr_t scope_index,
                                   intptr_t token_pos) const {
  StoreSmi(&VariableDescAddr(scope_index)->token_pos,
           Smi::New(token_pos));
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


void ContextScope::SetTypeAt(
    intptr_t scope_index, const AbstractType& type) const {
  StorePointer(&(VariableDescAddr(scope_index)->type), type.raw());
}


RawInstance* ContextScope::ConstValueAt(intptr_t scope_index) const {
  ASSERT(IsConstAt(scope_index));
  return VariableDescAddr(scope_index)->value;
}


void ContextScope::SetConstValueAt(
    intptr_t scope_index, const Instance& value) const {
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
    intptr_t pos = TokenIndexAt(i);
    intptr_t idx = ContextIndexAt(i);
    intptr_t lvl = ContextLevelAt(i);
    char* chars = OS::SCreate(Thread::Current()->zone(),
        "%s\nvar %s  token-pos %" Pd "  ctx lvl %" Pd "  index %" Pd "",
        prev_cstr, cname, pos, lvl, idx);
    prev_cstr = chars;
  }
  return prev_cstr;
}


void ContextScope::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
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


RawMegamorphicCache* MegamorphicCache::New() {
  MegamorphicCache& result = MegamorphicCache::Handle();
  { RawObject* raw = Object::Allocate(MegamorphicCache::kClassId,
                                      MegamorphicCache::InstanceSize(),
                                      Heap::kOld);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  const intptr_t capacity = kInitialCapacity;
  const Array& buckets = Array::Handle(
      Array::New(kEntryLength * capacity, Heap::kOld));
  ASSERT(Isolate::Current()->megamorphic_cache_table()->miss_handler() != NULL);
  const Function& handler = Function::Handle(
      Isolate::Current()->megamorphic_cache_table()->miss_handler());
  for (intptr_t i = 0; i < capacity; ++i) {
    SetEntry(buckets, i, smi_illegal_cid(), handler);
  }
  result.set_buckets(buckets);
  result.set_mask(capacity - 1);
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
        Isolate::Current()->megamorphic_cache_table()->miss_handler());
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
  intptr_t index = class_id.Value() & id_mask;
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
  return "MegamorphicCache";
}


void MegamorphicCache::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


RawSubtypeTestCache* SubtypeTestCache::New() {
  ASSERT(Object::subtypetestcache_class() != Class::null());
  SubtypeTestCache& result = SubtypeTestCache::Handle();
  {
    // SubtypeTestCache objects are long living objects, allocate them in the
    // old generation.
    RawObject* raw = Object::Allocate(SubtypeTestCache::kClassId,
                                      SubtypeTestCache::InstanceSize(),
                                      Heap::kOld);
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
    intptr_t instance_class_id,
    const TypeArguments& instance_type_arguments,
    const TypeArguments& instantiator_type_arguments,
    const Bool& test_result) const {
  intptr_t old_num = NumberOfChecks();
  Array& data = Array::Handle(cache());
  intptr_t new_len = data.Length() + kTestEntryLength;
  data = Array::Grow(data, new_len);
  set_cache(data);
  intptr_t data_pos = old_num * kTestEntryLength;
  data.SetAt(data_pos + kInstanceClassId,
      Smi::Handle(Smi::New(instance_class_id)));
  data.SetAt(data_pos + kInstanceTypeArguments, instance_type_arguments);
  data.SetAt(data_pos + kInstantiatorTypeArguments,
      instantiator_type_arguments);
  data.SetAt(data_pos + kTestResult, test_result);
}


void SubtypeTestCache::GetCheck(intptr_t ix,
                                intptr_t* instance_class_id,
                                TypeArguments* instance_type_arguments,
                                TypeArguments* instantiator_type_arguments,
                                Bool* test_result) const {
  Array& data = Array::Handle(cache());
  intptr_t data_pos = ix * kTestEntryLength;
  *instance_class_id =
      Smi::Value(Smi::RawCast(data.At(data_pos + kInstanceClassId)));
  *instance_type_arguments ^= data.At(data_pos + kInstanceTypeArguments);
  *instantiator_type_arguments ^=
      data.At(data_pos + kInstantiatorTypeArguments);
  *test_result ^= data.At(data_pos + kTestResult);
}


const char* SubtypeTestCache::ToCString() const {
  return "SubtypeTestCache";
}


void SubtypeTestCache::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Object::PrintJSONImpl(stream, ref);
}


const char* Error::ToErrorCString() const {
  UNREACHABLE();
  return "Internal Error";
}


const char* Error::ToCString() const {
  // Error is an abstract class.  We should never reach here.
  UNREACHABLE();
  return "Error";
}


void Error::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}


RawApiError* ApiError::New() {
  ASSERT(Object::api_error_class() != Class::null());
  RawObject* raw = Object::Allocate(ApiError::kClassId,
                                    ApiError::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawApiError*>(raw);
}


RawApiError* ApiError::New(const String& message, Heap::Space space) {
  ASSERT(Object::api_error_class() != Class::null());
  ApiError& result = ApiError::Handle();
  {
    RawObject* raw = Object::Allocate(ApiError::kClassId,
                                      ApiError::InstanceSize(),
                                      space);
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


void ApiError::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "InternalError");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
}


RawLanguageError* LanguageError::New() {
  ASSERT(Object::language_error_class() != Class::null());
  RawObject* raw = Object::Allocate(LanguageError::kClassId,
                                    LanguageError::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawLanguageError*>(raw);
}


RawLanguageError* LanguageError::NewFormattedV(const Error& prev_error,
                                               const Script& script,
                                               intptr_t token_pos,
                                               Report::Kind kind,
                                               Heap::Space space,
                                               const char* format,
                                               va_list args) {
  ASSERT(Object::language_error_class() != Class::null());
  LanguageError& result = LanguageError::Handle();
  {
    RawObject* raw = Object::Allocate(LanguageError::kClassId,
                                      LanguageError::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_previous_error(prev_error);
  result.set_script(script);
  result.set_token_pos(token_pos);
  result.set_kind(kind);
  result.set_message(String::Handle(String::NewFormattedV(format, args)));
  return result.raw();
}


RawLanguageError* LanguageError::NewFormatted(const Error& prev_error,
                                              const Script& script,
                                              intptr_t token_pos,
                                              Report::Kind kind,
                                              Heap::Space space,
                                              const char* format, ...) {
  va_list args;
  va_start(args, format);
  RawLanguageError* result = LanguageError::NewFormattedV(
      prev_error, script, token_pos, kind, space, format, args);
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
                                      LanguageError::InstanceSize(),
                                      space);
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


void LanguageError::set_token_pos(intptr_t value) const {
  ASSERT(value >= 0);
  StoreNonPointer(&raw_ptr()->token_pos_, value);
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
      Report::PrependSnippet(kind(),
                             Script::Handle(script()),
                             token_pos(),
                             String::Handle(message())));
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
  const String& msg_str = String::Handle(FormatMessage());
  return msg_str.ToCString();
}


const char* LanguageError::ToCString() const {
  return "LanguageError";
}


void LanguageError::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "LanguageError");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
}


RawUnhandledException* UnhandledException::New(const Instance& exception,
                                               const Instance& stacktrace,
                                               Heap::Space space) {
  ASSERT(Object::unhandled_exception_class() != Class::null());
  UnhandledException& result = UnhandledException::Handle();
  {
    RawObject* raw = Object::Allocate(UnhandledException::kClassId,
                                      UnhandledException::InstanceSize(),
                                      space);
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
    RawObject* raw = Object::Allocate(UnhandledException::kClassId,
                                      UnhandledException::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_exception(Object::null_instance());
  result.set_stacktrace(Stacktrace::Handle());
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
  return OS::SCreate(thread->zone(),
      "Unhandled exception:\n%s\n%s", exc_str, stack_str);
}


const char* UnhandledException::ToCString() const {
  return "UnhandledException";
}



void UnhandledException::PrintJSONImpl(JSONStream* stream,
                                       bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "UnhandledException");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
  if (ref) {
    return;
  }
  Instance& instance = Instance::Handle();
  instance = exception();
  jsobj.AddProperty("exception", instance);
  instance = stacktrace();
  jsobj.AddProperty("stacktrace", instance);
}


RawUnwindError* UnwindError::New(const String& message, Heap::Space space) {
  ASSERT(Object::unwind_error_class() != Class::null());
  UnwindError& result = UnwindError::Handle();
  {
    RawObject* raw = Object::Allocate(UnwindError::kClassId,
                                      UnwindError::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_message(message);
  return result.raw();
}


void UnwindError::set_message(const String& message) const {
  StorePointer(&raw_ptr()->message_, message.raw());
}


const char* UnwindError::ToErrorCString() const {
  const String& msg_str = String::Handle(message());
  return msg_str.ToCString();
}


const char* UnwindError::ToCString() const {
  return "UnwindError";
}


void UnwindError::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  AddCommonObjectProperties(&jsobj, "Error", ref);
  jsobj.AddProperty("kind", "TerminationError");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("message", ToErrorCString());
}


RawObject* Instance::Evaluate(const String& expr,
                              const Array& param_names,
                              const Array& param_values) const {
  const Class& cls = Class::Handle(clazz());
  const Function& eval_func =
      Function::Handle(EvaluateHelper(cls, expr, param_names, false));
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
    const intptr_t instance_size = Class::Handle(this->clazz()).instance_size();
    ASSERT(instance_size != 0);
    uword this_addr = reinterpret_cast<uword>(this->raw_ptr());
    uword other_addr = reinterpret_cast<uword>(other.raw_ptr());
    for (intptr_t offset = Instance::NextFieldOffset();
         offset < instance_size;
         offset += kWordSize) {
      if ((*reinterpret_cast<RawObject**>(this_addr + offset)) !=
          (*reinterpret_cast<RawObject**>(other_addr + offset))) {
        return false;
      }
    }
  }
  return true;
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


bool Instance::CheckAndCanonicalizeFields(const char** error_str) const {
  const Class& cls = Class::Handle(this->clazz());
  if (cls.id() >= kNumPredefinedCids) {
    // Iterate over all fields, canonicalize numbers and strings, expect all
    // other instances to be canonical otherwise report error (return false).
    Object& obj = Object::Handle();
    intptr_t end_field_offset = cls.instance_size() - kWordSize;
    for (intptr_t field_offset = 0;
         field_offset <= end_field_offset;
         field_offset += kWordSize) {
      obj = *this->FieldAddrAtOffset(field_offset);
      if (obj.IsInstance() && !obj.IsSmi() && !obj.IsCanonical()) {
        if (obj.IsNumber() || obj.IsString()) {
          obj = Instance::Cast(obj).CheckAndCanonicalize(NULL);
          ASSERT(!obj.IsNull());
          this->SetFieldAtOffset(field_offset, obj);
        } else {
          ASSERT(error_str != NULL);
          char* chars = OS::SCreate(Thread::Current()->zone(),
              "field: %s\n", obj.ToCString());
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


RawInstance* Instance::CheckAndCanonicalize(const char** error_str) const {
  ASSERT(!IsNull());
  if (this->IsCanonical()) {
    return this->raw();
  }
  if (!CheckAndCanonicalizeFields(error_str)) {
    return Instance::null();
  }
  Instance& result = Instance::Handle();
  const Class& cls = Class::Handle(this->clazz());
  Array& constants = Array::Handle(cls.constants());
  const intptr_t constants_len = constants.Length();
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  intptr_t index = 0;
  while (index < constants_len) {
    result ^= constants.At(index);
    if (result.IsNull()) {
      break;
    }
    if (this->CanonicalizeEquals(result)) {
      ASSERT(result.IsCanonical());
      return result.raw();
    }
    index++;
  }
  // The value needs to be added to the list. Grow the list if
  // it is full.
  result ^= this->raw();
  if (result.IsNew()) {
    // Create a canonical object in old space.
    result ^= Object::Clone(result, Heap::kOld);
  }
  ASSERT(result.IsOld());
  cls.InsertCanonicalConstant(index, result);
  result.SetCanonical();
  return result.raw();
}


RawType* Instance::GetType() const {
  if (IsNull()) {
    return Type::NullType();
  }
  const Class& cls = Class::Handle(clazz());
  Type& type = Type::Handle();
  if (cls.NumTypeArguments() == 0) {
    type = cls.CanonicalType();
  }
  if (type.IsNull()) {
    TypeArguments& type_arguments = TypeArguments::Handle();
    if (cls.NumTypeArguments() > 0) {
      type_arguments = GetTypeArguments();
    }
    type = Type::New(cls, type_arguments, Scanner::kNoSourcePos);
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


bool Instance::IsInstanceOf(const AbstractType& other,
                            const TypeArguments& other_instantiator,
                            Error* bound_error) const {
  ASSERT(other.IsFinalized());
  ASSERT(!other.IsDynamicType());
  ASSERT(!other.IsMalformed());
  ASSERT(!other.IsMalbounded());
  if (other.IsVoidType()) {
    return false;
  }
  Isolate* isolate = Isolate::Current();
  const Class& cls = Class::Handle(isolate, clazz());
  TypeArguments& type_arguments =
      TypeArguments::Handle(isolate);
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
  Class& other_class = Class::Handle(isolate);
  TypeArguments& other_type_arguments = TypeArguments::Handle(isolate);
  // Note that we may encounter a bound error in checked mode.
  if (!other.IsInstantiated()) {
    const AbstractType& instantiated_other = AbstractType::Handle(
        isolate, other.InstantiateFrom(other_instantiator, bound_error));
    if ((bound_error != NULL) && !bound_error->IsNull()) {
      ASSERT(Isolate::Current()->flags().type_checks());
      return false;
    }
    other_class = instantiated_other.type_class();
    other_type_arguments = instantiated_other.arguments();
  } else {
    other_class = other.type_class();
    other_type_arguments = other.arguments();
  }
  return cls.IsSubtypeOf(type_arguments, other_class, other_type_arguments,
                         bound_error, Heap::kOld);
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
    return Double::Cast(*this).CanonicalizeEquals(other);
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


bool Instance::IsClosure() const {
  return Class::IsSignatureClass(clazz());
}


bool Instance::IsCallable(Function* function) const {
  Class& cls = Class::Handle(clazz());
  if (cls.IsSignatureClass()) {
    if (function != NULL) {
      *function = Closure::function(*this);
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
  Isolate* isolate = Isolate::Current();
  if (cls.EnsureIsFinalized(isolate) != Error::null()) {
    return Instance::null();
  }
  intptr_t instance_size = cls.instance_size();
  ASSERT(instance_size > 0);
  RawObject* raw = Object::Allocate(cls.id(), instance_size, space);
  return reinterpret_cast<RawInstance*>(raw);
}


bool Instance::IsValidFieldOffset(intptr_t offset) const {
  Isolate* isolate = Isolate::Current();
  REUSABLE_CLASS_HANDLESCOPE(isolate);
  Class& cls = isolate->ClassHandle();
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
  if (RawObject::IsExternalTypedDataClassId(cid)) {
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
      return Closure::ToCString(*this);
    }
    const Class& cls = Class::Handle(clazz());
    TypeArguments& type_arguments = TypeArguments::Handle();
    const intptr_t num_type_arguments = cls.NumTypeArguments();
    if (num_type_arguments > 0) {
      type_arguments = GetTypeArguments();
    }
    const Type& type =
        Type::Handle(Type::New(cls, type_arguments, Scanner::kNoSourcePos));
    const String& type_name = String::Handle(type.UserVisibleName());
    return OS::SCreate(Thread::Current()->zone(),
        "Instance of '%s'", type_name.ToCString());
  }
}


void Instance::PrintSharedInstanceJSON(JSONObject* jsobj,
                                       bool ref) const {
  AddCommonObjectProperties(jsobj, "Instance", ref);
  if (ref) {
    return;
  }

  // Walk the superclass chain, adding all instance fields.
  Class& cls = Class::Handle(this->clazz());
  {
    Instance& fieldValue = Instance::Handle();
    JSONArray jsarr(jsobj, "fields");
    while (!cls.IsNull()) {
      const Array& field_array = Array::Handle(cls.fields());
      Field& field = Field::Handle();
      if (!field_array.IsNull()) {
        for (intptr_t i = 0; i < field_array.Length(); i++) {
          field ^= field_array.At(i);
          if (!field.is_static()) {
            fieldValue ^= GetField(field);
            JSONObject jsfield(&jsarr);
            jsfield.AddProperty("decl", field);
            jsfield.AddProperty("value", fieldValue);
          }
        }
      }
      cls = cls.SuperClass();
    }
  }

  if (NumNativeFields() > 0) {
    JSONArray jsarr(jsobj, "_nativeFields");
    for (intptr_t i = 0; i < NumNativeFields(); i++) {
      intptr_t value = GetNativeField(i);
      JSONObject jsfield(&jsarr);
      jsfield.AddProperty("index", i);
      jsfield.AddProperty("value", value);
    }
  }
}


void Instance::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);

  // Handle certain special instance values.
  if (raw() == Object::sentinel().raw()) {
    jsobj.AddProperty("type", "Sentinel");
    jsobj.AddProperty("kind", "NotInitialized");
    jsobj.AddProperty("valueAsString", "<not initialized>");
    return;
  } else if (raw() == Object::transition_sentinel().raw()) {
    jsobj.AddProperty("type", "Sentinel");
    jsobj.AddProperty("kind", "BeingInitialized");
    jsobj.AddProperty("valueAsString", "<being initialized>");
    return;
  }

  PrintSharedInstanceJSON(&jsobj, ref);
  if (IsClosure()) {
    jsobj.AddProperty("kind", "Closure");
  } else {
    jsobj.AddProperty("kind", "PlainInstance");
  }
  jsobj.AddServiceId(*this);
  if (IsClosure()) {
    jsobj.AddProperty("closureFunction",
                      Function::Handle(Closure::function(*this)));
    jsobj.AddProperty("closureContext",
                      Context::Handle(Closure::context(*this)));
  }
  if (ref) {
    return;
  }
  if (IsClosure()) {
    Debugger* debugger = Isolate::Current()->debugger();
    Breakpoint* bpt = debugger->BreakpointAtActivation(*this);
    if (bpt != NULL) {
      jsobj.AddProperty("_activationBreakpoint", bpt);
    }
  }
}


bool AbstractType::IsResolved() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}


bool AbstractType::HasResolvedTypeClass() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
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


RawTypeArguments* AbstractType::arguments() const  {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}


intptr_t AbstractType::token_pos() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return -1;
}


bool AbstractType::IsInstantiated(TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}


bool AbstractType::IsFinalized() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
}


bool AbstractType::IsBeingFinalized() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return false;
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


RawAbstractType* AbstractType::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    Error* bound_error,
    TrailPtr trail,
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


RawAbstractType* AbstractType::CloneUninstantiated(
    const Class& new_owner, TrailPtr trail) const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return NULL;
}


RawAbstractType* AbstractType::Canonicalize(TrailPtr trail) const {
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


RawString* AbstractType::BuildName(NameVisibility name_visibility) const {
  Zone* zone = Thread::Current()->zone();
  if (IsBoundedType()) {
    const AbstractType& type = AbstractType::Handle(
        BoundedType::Cast(*this).type());
    if (name_visibility == kPrettyName) {
      return type.BuildName(kPrettyName);
    } else if (name_visibility == kUserVisibleName) {
      return type.BuildName(kUserVisibleName);
    }
    GrowableHandlePtrArray<const String> pieces(zone, 5);
    String& type_name = String::Handle(zone, type.BuildName(kInternalName));
    pieces.Add(type_name);
    pieces.Add(Symbols::SpaceExtendsSpace());
    // Build the bound name without causing divergence.
    const AbstractType& bound = AbstractType::Handle(
        zone, BoundedType::Cast(*this).bound());
    String& bound_name = String::Handle(zone);
    if (bound.IsTypeParameter()) {
      bound_name = TypeParameter::Cast(bound).name();
      pieces.Add(bound_name);
    } else if (bound.IsType()) {
      const Class& cls = Class::Handle(zone, Type::Cast(bound).type_class());
      bound_name = cls.Name();
      if (Type::Cast(bound).arguments() != TypeArguments::null()) {
        pieces.Add(bound_name);
        pieces.Add(Symbols::OptimizedOut());
      }
    } else {
      pieces.Add(Symbols::OptimizedOut());
    }
    return Symbols::FromConcatAll(pieces);
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
  if (HasResolvedTypeClass()) {
    const Class& cls = Class::Handle(zone, type_class());
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
    } else if (name_visibility == kPrettyName) {
      class_name = cls.PrettyName();
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
    if (cls.IsSignatureClass()) {
      // We may be reporting an error about a malformed function type. In that
      // case, avoid instantiating the signature, since it may cause divergence.
      if (!IsFinalized() || IsBeingFinalized() || IsMalformed()) {
        return class_name.raw();
      }
      // To avoid divergence, print the name of a typedef (non-canonical
      // signature class) as a regular, possibly parameterized, class.
      if (cls.IsCanonicalSignatureClass()) {
        const Function& signature_function = Function::Handle(
            zone, cls.signature_function());
        // Signature classes have no super type, however, they take as many
        // type arguments as the owner class of their signature function (if it
        // is non static and generic, see Class::NumTypeArguments()). Therefore,
        // first_type_param_index may be greater than 0 here.
        return signature_function.InstantiatedSignatureFrom(args,
                                                            name_visibility);
      }
    }
  } else {
    const UnresolvedClass& cls =
        UnresolvedClass::Handle(zone, unresolved_class());
    class_name = cls.Name();
    num_type_params = num_args;
    first_type_param_index = 0;
  }
  GrowableHandlePtrArray<const String> pieces(zone, 4);
  pieces.Add(class_name);
  if ((num_type_params == 0) ||
      args.IsRaw(first_type_param_index, num_type_params)) {
    // Do nothing.
  } else {
    const String& args_name = String::Handle(zone,
        args.SubvectorName(first_type_param_index,
                           num_type_params,
                           name_visibility));
    pieces.Add(args_name);
  }
  // The name is only used for type checking and debugging purposes.
  // Unless profiling data shows otherwise, it is not worth caching the name in
  // the type.
  return Symbols::FromConcatAll(pieces);
}


RawString* AbstractType::ClassName() const {
  if (HasResolvedTypeClass()) {
    return Class::Handle(type_class()).Name();
  } else {
    return UnresolvedClass::Handle(unresolved_class()).Name();
  }
}


bool AbstractType::IsNullType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Isolate::Current()->object_store()->null_class());
}


bool AbstractType::IsBoolType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Isolate::Current()->object_store()->bool_class());
}


bool AbstractType::IsIntType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::IntType()).type_class());
}


bool AbstractType::IsDoubleType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::Double()).type_class());
}


bool AbstractType::IsFloat32x4Type() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::Float32x4()).type_class());
}


bool AbstractType::IsFloat64x2Type() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::Float64x2()).type_class());
}


bool AbstractType::IsInt32x4Type() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::Int32x4()).type_class());
}


bool AbstractType::IsNumberType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::Number()).type_class());
}


bool AbstractType::IsSmiType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::SmiType()).type_class());
}


bool AbstractType::IsStringType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::StringType()).type_class());
}


bool AbstractType::IsFunctionType() const {
  return HasResolvedTypeClass() &&
      (type_class() == Type::Handle(Type::Function()).type_class());
}


bool AbstractType::TypeTest(TypeTestKind test_kind,
                            const AbstractType& other,
                            Error* bound_error,
                            Heap::Space space) const {
  ASSERT(IsResolved());
  ASSERT(other.IsResolved());
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
    ASSERT(Isolate::Current()->flags().type_checks());
    if ((bound_error != NULL) && bound_error->IsNull()) {
      *bound_error = error();
    }
    return false;
  }
  if (other.IsMalbounded()) {
    ASSERT(Isolate::Current()->flags().type_checks());
    if ((bound_error != NULL) && bound_error->IsNull()) {
      *bound_error = other.error();
    }
    return false;
  }
  if (IsBoundedType() || other.IsBoundedType()) {
    if (Equals(other)) {
      return true;
    }
    return false;  // TODO(regis): We should return "maybe after instantiation".
  }
  // Type parameters cannot be handled by Class::TypeTest().
  // When comparing two uninstantiated function types, one returning type
  // parameter K, the other returning type parameter V, we cannot assume that K
  // is a subtype of V, or vice versa. We only return true if K equals V, as
  // defined by TypeParameter::Equals.
  // The same rule applies when checking the upper bound of a still
  // uninstantiated type at compile time. Returning false will defer the test
  // to run time.
  // There are however some cases can be decided at compile time.
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
    }
    const AbstractType& bound = AbstractType::Handle(type_param.bound());
    if (bound.IsMoreSpecificThan(other, bound_error)) {
      return true;
    }
    return false;  // TODO(regis): We should return "maybe after instantiation".
  }
  if (other.IsTypeParameter()) {
    return false;  // TODO(regis): We should return "maybe after instantiation".
  }
  const Class& cls = Class::Handle(type_class());
  return cls.TypeTest(test_kind,
                      TypeArguments::Handle(arguments()),
                      Class::Handle(other.type_class()),
                      TypeArguments::Handle(other.arguments()),
                      bound_error,
                      space);
}


intptr_t AbstractType::Hash() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return 0;
}


const char* AbstractType::ToCString() const {
  // AbstractType is an abstract class.
  UNREACHABLE();
  return "AbstractType";
}


void AbstractType::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}


RawType* Type::NullType() {
  return Isolate::Current()->object_store()->null_type();
}


RawType* Type::DynamicType() {
  return Object::dynamic_type();
}


RawType* Type::VoidType() {
  return Object::void_type();
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


RawType* Type::Function() {
  return Isolate::Current()->object_store()->function_type();
}


RawType* Type::NewNonParameterizedType(const Class& type_class) {
  ASSERT(type_class.NumTypeArguments() == 0);
  if (type_class.raw() == Object::dynamic_class()) {
    // If the dynamic type has not been setup in the VM isolate, then we need
    // to allocate it here.
    if (Object::dynamic_type() != reinterpret_cast<RawType*>(RAW_NULL)) {
      ASSERT(Type::Handle(Object::dynamic_type()).IsFinalized());
      return Object::dynamic_type();
    }
    ASSERT(Isolate::Current() == Dart::vm_isolate());
  }
  Type& type = Type::Handle(type_class.CanonicalType());
  if (type.IsNull()) {
    const TypeArguments& no_type_arguments = TypeArguments::Handle();
    type ^= Type::New(Object::Handle(type_class.raw()),
                      no_type_arguments,
                      Scanner::kNoSourcePos);
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


void Type::set_is_being_finalized() const {
  ASSERT(IsResolved() && !IsFinalized() && !IsBeingFinalized());
  set_type_state(RawType::kBeingFinalized);
}


bool Type::IsMalformed() const {
  if (raw_ptr()->error_ == LanguageError::null()) {
    return false;
  }
  const LanguageError& type_error = LanguageError::Handle(error());
  return type_error.kind() == Report::kMalformedType;
}


bool Type::IsMalbounded() const {
  if (!Isolate::Current()->flags().type_checks()) {
    return false;
  }
  if (raw_ptr()->error_ == LanguageError::null()) {
    return false;
  }
  const LanguageError& type_error = LanguageError::Handle(error());
  return type_error.kind() == Report::kMalboundedType;
}


bool Type::IsMalformedOrMalbounded() const {
  if (raw_ptr()->error_ == LanguageError::null()) {
    return false;
  }
  const LanguageError& type_error = LanguageError::Handle(error());
  if (type_error.kind() == Report::kMalformedType) {
    return true;
  }
  ASSERT(type_error.kind() == Report::kMalboundedType);
  return Isolate::Current()->flags().type_checks();
}


void Type::set_error(const LanguageError& value) const {
  StorePointer(&raw_ptr()->error_, value.raw());
}


void Type::set_is_resolved() const {
  ASSERT(!IsResolved());
  set_type_state(RawType::kResolved);
}


bool Type::HasResolvedTypeClass() const {
  const Object& type_class = Object::Handle(raw_ptr()->type_class_);
  return !type_class.IsNull() && type_class.IsClass();
}


RawClass* Type::type_class() const {
  ASSERT(HasResolvedTypeClass());
#ifdef DEBUG
  Class& type_class = Class::Handle();
  type_class ^= raw_ptr()->type_class_;
  return type_class.raw();
#else
  return reinterpret_cast<RawClass*>(raw_ptr()->type_class_);
#endif
}


RawUnresolvedClass* Type::unresolved_class() const {
  ASSERT(!HasResolvedTypeClass());
#ifdef DEBUG
  UnresolvedClass& unresolved_class = UnresolvedClass::Handle();
  unresolved_class ^= raw_ptr()->type_class_;
  ASSERT(!unresolved_class.IsNull());
  return unresolved_class.raw();
#else
  ASSERT(!Object::Handle(raw_ptr()->type_class_).IsNull());
  ASSERT(Object::Handle(raw_ptr()->type_class_).IsUnresolvedClass());
  return reinterpret_cast<RawUnresolvedClass*>(raw_ptr()->type_class_);
#endif
}


RawTypeArguments* Type::arguments() const {
  return raw_ptr()->arguments_;
}


bool Type::IsInstantiated(TrailPtr trail) const {
  if (raw_ptr()->type_state_ == RawType::kFinalizedInstantiated) {
    return true;
  }
  if (raw_ptr()->type_state_ == RawType::kFinalizedUninstantiated) {
    return false;
  }
  if (arguments() == TypeArguments::null()) {
    return true;
  }
  const TypeArguments& args = TypeArguments::Handle(arguments());
  intptr_t num_type_args = args.Length();
  intptr_t len = num_type_args;  // Check the full vector of type args.
  ASSERT(num_type_args > 0);
  // This type is not instantiated if it refers to type parameters.
  // This IsInstantiated() call may be invoked on an unresolved signature type.
  // Although this type may still be unresolved, the type parameters it may
  // refer to are resolved by definition. We can therefore return the correct
  // result even for an unresolved type. We just need to look at all type
  // arguments and not just at the type parameters.
  if (HasResolvedTypeClass()) {
    const Class& cls = Class::Handle(type_class());
    len = cls.NumTypeArguments();
    ASSERT(num_type_args >= len);  // The vector may be longer than necessary.
    num_type_args = len;
    len = cls.NumTypeParameters();  // Check the type parameters only.
  }
  return (len == 0) || args.IsSubvectorInstantiated(num_type_args - len, len);
}


RawAbstractType* Type::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    Error* bound_error,
    TrailPtr trail,
    Heap::Space space) const {
  Zone* zone = Thread::Current()->zone();
  ASSERT(IsFinalized() || IsBeingFinalized());
  ASSERT(!IsInstantiated());
  // Return the uninstantiated type unchanged if malformed. No copy needed.
  if (IsMalformed()) {
    return raw();
  }
  // Instantiating this type with its own type arguments as instantiator can
  // occur during finalization and bounds checking. Return the type unchanged.
  if (arguments() == instantiator_type_arguments.raw()) {
    return raw();
  }
  // If this type is recursive, we may already be instantiating it.
  Type& instantiated_type = Type::Handle(zone);
  instantiated_type ^= OnlyBuddyInTrail(trail);
  if (!instantiated_type.IsNull()) {
    ASSERT(IsRecursive());
    return instantiated_type.raw();
  }
  // Note that the type class has to be resolved at this time, but not
  // necessarily finalized yet. We may be checking bounds at compile time or
  // finalizing the type argument vector of a recursive type.
  const Class& cls = Class::Handle(zone, type_class());

  // This uninstantiated type is not modified, as it can be instantiated
  // with different instantiators. Allocate a new instantiated version of it.
  instantiated_type = Type::New(cls, TypeArguments::Handle(zone), token_pos());
  TypeArguments& type_arguments = TypeArguments::Handle(zone, arguments());
  ASSERT(type_arguments.Length() == cls.NumTypeArguments());
  if (type_arguments.IsRecursive()) {
    AddOnlyBuddyToTrail(&trail, instantiated_type);
  }
  type_arguments = type_arguments.InstantiateFrom(instantiator_type_arguments,
                                                  bound_error,
                                                  trail,
                                                  space);
  instantiated_type.set_arguments(type_arguments);
  if (IsFinalized()) {
    instantiated_type.SetIsFinalized();
  } else {
    instantiated_type.set_is_resolved();
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
    const AbstractType& other_ref_type = AbstractType::Handle(
        TypeRef::Cast(other).type());
    ASSERT(!other_ref_type.IsTypeRef());
    return IsEquivalent(other_ref_type, trail);
  }
  if (!other.IsType()) {
    return false;
  }
  const Type& other_type = Type::Cast(other);
  ASSERT(IsResolved() && other_type.IsResolved());
  if (IsMalformed() || other_type.IsMalformed()) {
    return false;
  }
  if (type_class() != other_type.type_class()) {
    return false;
  }
  if (!IsFinalized() || !other_type.IsFinalized()) {
    return false;
  }
  if (arguments() == other_type.arguments()) {
    return true;
  }
  Isolate* isolate = Isolate::Current();
  const Class& cls = Class::Handle(isolate, type_class());
  const intptr_t num_type_params = cls.NumTypeParameters(isolate);
  if (num_type_params == 0) {
    // Shortcut unnecessary handle allocation below.
    return true;
  }
  const intptr_t num_type_args = cls.NumTypeArguments();
  const intptr_t from_index = num_type_args - num_type_params;
  const TypeArguments& type_args = TypeArguments::Handle(isolate, arguments());
  const TypeArguments& other_type_args = TypeArguments::Handle(
      isolate, other_type.arguments());
  if (type_args.IsNull()) {
    // Ignore from_index.
    return other_type_args.IsRaw(0, num_type_args);
  }
  if (other_type_args.IsNull()) {
    // Ignore from_index.
    return type_args.IsRaw(0, num_type_args);
  }
  if (!type_args.IsSubvectorEquivalent(other_type_args,
                                       from_index,
                                       num_type_params)) {
    return false;
  }
#ifdef DEBUG
  if (from_index > 0) {
    // Verify that the type arguments of the super class match, since they
    // depend solely on the type parameters that were just verified to match.
    ASSERT(type_args.Length() >= (from_index + num_type_params));
    ASSERT(other_type_args.Length() >= (from_index + num_type_params));
    AbstractType& type_arg = AbstractType::Handle(isolate);
    AbstractType& other_type_arg = AbstractType::Handle(isolate);
    for (intptr_t i = 0; i < from_index; i++) {
      type_arg = type_args.TypeAt(i);
      other_type_arg = other_type_args.TypeAt(i);
      ASSERT(type_arg.IsEquivalent(other_type_arg, trail));
    }
  }
#endif
  return true;
}


bool Type::IsRecursive() const {
  return TypeArguments::Handle(arguments()).IsRecursive();
}


RawAbstractType* Type::CloneUnfinalized() const {
  ASSERT(IsResolved());
  if (IsFinalized()) {
    return raw();
  }
  ASSERT(!IsMalformed());  // Malformed types are finalized.
  ASSERT(!IsBeingFinalized());  // Cloning must occur prior to finalization.
  TypeArguments& type_args = TypeArguments::Handle(arguments());
  type_args = type_args.CloneUnfinalized();
  const Class& type_cls = Class::Handle(type_class());
  const Type& clone = Type::Handle(Type::New(type_cls, type_args, token_pos()));
  clone.set_is_resolved();
  return clone.raw();
}


RawAbstractType* Type::CloneUninstantiated(const Class& new_owner,
                                           TrailPtr trail) const {
  ASSERT(IsFinalized());
  ASSERT(!IsMalformed());
  if (IsInstantiated()) {
    return raw();
  }
  // We may recursively encounter a type already being cloned, because we clone
  // the upper bounds of its uninstantiated type arguments in the same pass.
  Type& clone = Type::Handle();
  clone ^= OnlyBuddyInTrail(trail);
  if (!clone.IsNull()) {
    return clone.raw();
  }
  const Class& type_cls = Class::Handle(type_class());
  clone = Type::New(type_cls, TypeArguments::Handle(), token_pos());
  TypeArguments& type_args = TypeArguments::Handle(arguments());
  // Upper bounds of uninstantiated type arguments may form a cycle.
  if (type_args.IsRecursive() || !type_args.IsInstantiated()) {
    AddOnlyBuddyToTrail(&trail, clone);
  }
  type_args = type_args.CloneUninstantiated(new_owner, trail);
  clone.set_arguments(type_args);
  clone.SetIsFinalized();
  return clone.raw();
}


RawAbstractType* Type::Canonicalize(TrailPtr trail) const {
  ASSERT(IsFinalized());
  if (IsCanonical() || IsMalformed()) {
    ASSERT(IsMalformed() || TypeArguments::Handle(arguments()).IsOld());
    return this->raw();
  }
  Isolate* isolate = Isolate::Current();
  Type& type = Type::Handle(isolate);
  const Class& cls = Class::Handle(isolate, type_class());
  if (cls.raw() == Object::dynamic_class() && (isolate != Dart::vm_isolate())) {
    return Object::dynamic_type();
  }
  // Fast canonical lookup/registry for simple types.
  if (cls.NumTypeArguments() == 0) {
    type = cls.CanonicalType();
    if (type.IsNull()) {
      ASSERT(!cls.raw()->IsVMHeapObject() || (isolate == Dart::vm_isolate()));
      cls.set_canonical_types(*this);
      SetCanonical();
      return this->raw();
    }
    ASSERT(this->Equals(type));
    ASSERT(type.IsCanonical());
    return type.raw();
  }

  Array& canonical_types = Array::Handle(isolate);
  canonical_types ^= cls.canonical_types();
  if (canonical_types.IsNull()) {
    canonical_types = empty_array().raw();
  }
  intptr_t length = canonical_types.Length();
  // Linear search to see whether this type is already present in the
  // list of canonicalized types.
  // TODO(asiva): Try to re-factor this lookup code to make sharing
  // easy between the 4 versions of this loop.
  intptr_t index = 1;  // Slot 0 is reserved for CanonicalType().
  while (index < length) {
    type ^= canonical_types.At(index);
    if (type.IsNull()) {
      break;
    }
    ASSERT(type.IsFinalized());
    if (this->Equals(type)) {
      ASSERT(type.IsCanonical());
      return type.raw();
    }
    index++;
  }
  // The type was not found in the table. It is not canonical yet.

  // Canonicalize the type arguments.
  TypeArguments& type_args = TypeArguments::Handle(isolate, arguments());
  // In case the type is first canonicalized at runtime, its type argument
  // vector may be longer than necessary. This is not an issue.
  ASSERT(type_args.IsNull() || (type_args.Length() >= cls.NumTypeArguments()));
  type_args = type_args.Canonicalize(trail);
  set_arguments(type_args);

  // Canonicalizing the type arguments may have changed the index, may have
  // grown the table, or may even have canonicalized this type.
  canonical_types ^= cls.canonical_types();
  if (canonical_types.IsNull()) {
    canonical_types = empty_array().raw();
  }
  length = canonical_types.Length();
  while (index < length) {
    type ^= canonical_types.At(index);
    if (type.IsNull()) {
      break;
    }
    ASSERT(type.IsFinalized());
    if (this->Equals(type)) {
      ASSERT(type.IsCanonical());
      return type.raw();
    }
    index++;
  }

  // The type needs to be added to the list. Grow the list if it is full.
  if (index >= length) {
    ASSERT((index == length) || ((index == 1) && (length == 0)));
    const intptr_t new_length = (length > 64) ?
        (length + 64) :
        ((length == 0) ? 2 : (length * 2));
    const Array& new_canonical_types = Array::Handle(
        isolate, Array::Grow(canonical_types, new_length, Heap::kOld));
    cls.set_canonical_types(new_canonical_types);
    canonical_types = new_canonical_types.raw();
  }
  canonical_types.SetAt(index, *this);
  if ((index == 1) && cls.IsCanonicalSignatureClass()) {
    canonical_types.SetAt(0, *this);  // Also set canonical signature type at 0.
#ifdef DEBUG
    // Verify that the first canonical type is the signature type by checking
    // that the type argument vector of the canonical type ends with the
    // uninstantiated type parameters of the signature class. Note that these
    // type parameters may be bounded if the super class of the owner class
    // declares bounds.
    // The signature type is finalized during class finalization, before the
    // optimizer may canonicalize instantiated function types of the same
    // signature class.
    // Although the signature class extends class Instance, the type arguments
    // of the super class of the owner class of its signature function will be
    // prepended to the type argument vector during class finalization.
    const TypeArguments& type_params =
      TypeArguments::Handle(isolate, cls.type_parameters());
    const intptr_t num_type_params = cls.NumTypeParameters();
    const intptr_t num_type_args = cls.NumTypeArguments();
    AbstractType& type_arg = AbstractType::Handle(isolate);
    TypeParameter& type_param = TypeParameter::Handle(isolate);
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_arg = type_args.TypeAt(num_type_args - num_type_params + i);
      while (type_arg.IsBoundedType()) {
        type_arg = BoundedType::Cast(type_arg).type();
      }
      type_param ^= type_params.TypeAt(i);
      ASSERT(type_arg.Equals(type_param));
    }
#endif
  }
  ASSERT(IsOld());
  ASSERT(type_args.IsNull() || type_args.IsOld());
  SetCanonical();
  return this->raw();
}


intptr_t Type::Hash() const {
  ASSERT(IsFinalized());
  uint32_t result = 1;
  if (IsMalformed()) return result;
  result = CombineHashes(result, Class::Handle(type_class()).id());
  result = CombineHashes(result, TypeArguments::Handle(arguments()).Hash());
  return FinalizeHash(result);
}


void Type::set_type_class(const Object& value) const {
  ASSERT(!value.IsNull() && (value.IsClass() || value.IsUnresolvedClass()));
  StorePointer(&raw_ptr()->type_class_, value.raw());
}


void Type::set_arguments(const TypeArguments& value) const {
  StorePointer(&raw_ptr()->arguments_, value.raw());
}


RawType* Type::New(Heap::Space space) {
  RawObject* raw = Object::Allocate(Type::kClassId,
                                    Type::InstanceSize(),
                                    space);
  return reinterpret_cast<RawType*>(raw);
}


RawType* Type::New(const Object& clazz,
                   const TypeArguments& arguments,
                   intptr_t token_pos,
                   Heap::Space space) {
  const Type& result = Type::Handle(Type::New(space));
  result.set_type_class(clazz);
  result.set_arguments(arguments);
  result.set_token_pos(token_pos);
  result.StoreNonPointer(&result.raw_ptr()->type_state_, RawType::kAllocated);
  return result.raw();
}


void Type::set_token_pos(intptr_t token_pos) const {
  ASSERT(token_pos >= 0);
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}


void Type::set_type_state(int8_t state) const {
  ASSERT((state >= RawType::kAllocated) &&
         (state <= RawType::kFinalizedUninstantiated));
  StoreNonPointer(&raw_ptr()->type_state_, state);
}


const char* Type::ToCString() const {
  const char* unresolved = IsResolved() ? "" : "Unresolved ";
  const TypeArguments& type_arguments = TypeArguments::Handle(arguments());
  const char* class_name;
  if (HasResolvedTypeClass()) {
    class_name = String::Handle(
        Class::Handle(type_class()).Name()).ToCString();
  } else {
    class_name = UnresolvedClass::Handle(unresolved_class()).ToCString();
  }
  if (type_arguments.IsNull()) {
    return OS::SCreate(Thread::Current()->zone(),
        "%sType: class '%s'", unresolved, class_name);
  } else if (IsResolved() && IsFinalized() && IsRecursive()) {
    const intptr_t hash = Hash();
    const char* args_cstr = TypeArguments::Handle(arguments()).ToCString();
    return OS::SCreate(Thread::Current()->zone(),
        "Type: (@%p H%" Px ") class '%s', args:[%s]",
        raw(), hash, class_name, args_cstr);
  } else {
    const char* args_cstr = TypeArguments::Handle(arguments()).ToCString();
    return OS::SCreate(Thread::Current()->zone(),
        "%sType: class '%s', args:[%s]", unresolved, class_name, args_cstr);
  }
}


void Type::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Type");
  if (IsCanonical()) {
    const Class& type_cls = Class::Handle(type_class());
    intptr_t id = type_cls.FindCanonicalTypeIndex(*this);
    ASSERT(id >= 0);
    intptr_t cid = type_cls.id();
    jsobj.AddFixedServiceId("classes/%" Pd "/types/%" Pd "", cid, id);
    jsobj.AddProperty("typeClass", type_cls);
  } else {
    jsobj.AddServiceId(*this);
  }
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name, vm_name);
  if (ref) {
    return;
  }
  const TypeArguments& typeArgs = TypeArguments::Handle(arguments());
  if (!typeArgs.IsNull()) {
    jsobj.AddProperty("typeArguments", typeArgs);
  }
}


bool TypeRef::IsInstantiated(TrailPtr trail) const {
  if (TestAndAddToTrail(&trail)) {
    return true;
  }
  return AbstractType::Handle(type()).IsInstantiated(trail);
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
  return AbstractType::Handle(type()).IsEquivalent(other, trail);
}


RawTypeRef* TypeRef::InstantiateFrom(
    const TypeArguments& instantiator_type_arguments,
    Error* bound_error,
    TrailPtr trail,
    Heap::Space space) const {
  TypeRef& instantiated_type_ref = TypeRef::Handle();
  instantiated_type_ref ^= OnlyBuddyInTrail(trail);
  if (!instantiated_type_ref.IsNull()) {
    return instantiated_type_ref.raw();
  }
  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsTypeRef());
  AbstractType& instantiated_ref_type = AbstractType::Handle();
  instantiated_ref_type = ref_type.InstantiateFrom(
      instantiator_type_arguments, bound_error, trail, space);
  ASSERT(!instantiated_ref_type.IsTypeRef());
  instantiated_type_ref = TypeRef::New(instantiated_ref_type);
  AddOnlyBuddyToTrail(&trail, instantiated_type_ref);
  return instantiated_type_ref.raw();
}


RawTypeRef* TypeRef::CloneUninstantiated(const Class& new_owner,
                                         TrailPtr trail) const {
  TypeRef& cloned_type_ref = TypeRef::Handle();
  cloned_type_ref ^= OnlyBuddyInTrail(trail);
  if (!cloned_type_ref.IsNull()) {
    return cloned_type_ref.raw();
  }
  AbstractType& ref_type = AbstractType::Handle(type());
  ASSERT(!ref_type.IsTypeRef());
  AbstractType& cloned_ref_type = AbstractType::Handle();
  cloned_ref_type = ref_type.CloneUninstantiated(new_owner, trail);
  ASSERT(!cloned_ref_type.IsTypeRef());
  cloned_type_ref = TypeRef::New(cloned_ref_type);
  AddOnlyBuddyToTrail(&trail, cloned_type_ref);
  return cloned_type_ref.raw();
}


void TypeRef::set_type(const AbstractType& value) const {
  ASSERT(value.HasResolvedTypeClass());
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
  ref_type = ref_type.Canonicalize(trail);
  set_type(ref_type);
  return raw();
}


intptr_t TypeRef::Hash() const {
  // Do not calculate the hash of the referenced type to avoid divergence.
  const uint32_t result =
      Class::Handle(AbstractType::Handle(type()).type_class()).id();
  return FinalizeHash(result);
}


bool TypeRef::TestAndAddToTrail(TrailPtr* trail) const {
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


bool TypeRef::TestAndAddBuddyToTrail(TrailPtr* trail,
                                     const AbstractType& buddy) const {
  if (*trail == NULL) {
    *trail = new Trail(Thread::Current()->zone(), 4);
  } else {
    const intptr_t len = (*trail)->length();
    ASSERT((len % 2) == 0);
    for (intptr_t i = 0; i < len; i += 2) {
      if (((*trail)->At(i).raw() == this->raw()) &&
          ((*trail)->At(i + 1).raw() == buddy.raw())) {
        return true;
      }
    }
  }
  (*trail)->Add(*this);
  (*trail)->Add(buddy);
  return false;
}


RawTypeRef* TypeRef::New() {
  RawObject* raw = Object::Allocate(TypeRef::kClassId,
                                    TypeRef::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawTypeRef*>(raw);
}


RawTypeRef* TypeRef::New(const AbstractType& type) {
  const TypeRef& result = TypeRef::Handle(TypeRef::New());
  result.set_type(type);
  return result.raw();
}


const char* TypeRef::ToCString() const {
  const char* type_cstr = String::Handle(Class::Handle(
      type_class()).Name()).ToCString();
  AbstractType& ref_type = AbstractType::Handle(type());
  if (ref_type.IsFinalized()) {
    const intptr_t hash = ref_type.Hash();
    return OS::SCreate(Thread::Current()->zone(),
        "TypeRef: %s<...> (@%p H%" Px ")", type_cstr, ref_type.raw(), hash);
  } else {
    return OS::SCreate(Thread::Current()->zone(),
        "TypeRef: %s<...>", type_cstr);
  }
}


void TypeRef::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "TypeRef");
  jsobj.AddServiceId(*this);
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name, vm_name);
  if (ref) {
    return;
  }
  jsobj.AddProperty("targetType", AbstractType::Handle(type()));
}


void TypeParameter::set_is_finalized() const {
  ASSERT(!IsFinalized());
  set_type_state(RawTypeParameter::kFinalizedUninstantiated);
}


bool TypeParameter::IsEquivalent(const Instance& other, TrailPtr trail) const {
  if (raw() == other.raw()) {
    return true;
  }
  if (other.IsTypeRef()) {
    // Unfold right hand type. Divergence is controlled by left hand type.
    const AbstractType& other_ref_type = AbstractType::Handle(
        TypeRef::Cast(other).type());
    ASSERT(!other_ref_type.IsTypeRef());
    return IsEquivalent(other_ref_type, trail);
  }
  if (!other.IsTypeParameter()) {
    return false;
  }
  const TypeParameter& other_type_param = TypeParameter::Cast(other);
  if (parameterized_class() != other_type_param.parameterized_class()) {
    return false;
  }
  if (IsFinalized() == other_type_param.IsFinalized()) {
    return index() == other_type_param.index();
  }
  return name() == other_type_param.name();
}


void TypeParameter::set_parameterized_class(const Class& value) const {
  // Set value may be null.
  StorePointer(&raw_ptr()->parameterized_class_, value.raw());
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
    Error* bound_error,
    TrailPtr trail,
    Heap::Space space) const {
  ASSERT(IsFinalized());
  if (instantiator_type_arguments.IsNull()) {
    return Type::DynamicType();
  }
  const AbstractType& type_arg = AbstractType::Handle(
      instantiator_type_arguments.TypeAt(index()));
  // There is no need to canonicalize the instantiated type parameter, since all
  // type arguments are canonicalized at type finalization time. It would be too
  // early to canonicalize the returned type argument here, since instantiation
  // not only happens at run time, but also during type finalization.
  return type_arg.raw();
}


bool TypeParameter::CheckBound(const AbstractType& bounded_type,
                               const AbstractType& upper_bound,
                               Error* bound_error) const {
  ASSERT((bound_error != NULL) && bound_error->IsNull());
  ASSERT(bounded_type.IsFinalized());
  ASSERT(upper_bound.IsFinalized());
  ASSERT(!bounded_type.IsMalformed());
  if (bounded_type.IsSubtypeOf(upper_bound, bound_error)) {
    return true;
  }
  // Set bound_error if the caller is interested and if this is the first error.
  if ((bound_error != NULL) && bound_error->IsNull()) {
    // Report the bound error only if both the bounded type and the upper bound
    // are instantiated. Otherwise, we cannot tell yet it is a bound error.
    if (bounded_type.IsInstantiated() && upper_bound.IsInstantiated()) {
      const String& bounded_type_name = String::Handle(
          bounded_type.UserVisibleName());
      const String& upper_bound_name = String::Handle(
          upper_bound.UserVisibleName());
      const AbstractType& declared_bound = AbstractType::Handle(bound());
      const String& declared_bound_name = String::Handle(
          declared_bound.UserVisibleName());
      const String& type_param_name = String::Handle(UserVisibleName());
      const Class& cls = Class::Handle(parameterized_class());
      const String& class_name = String::Handle(cls.Name());
      const Script& script = Script::Handle(cls.script());
      // Since the bound may have been canonicalized, its token index is
      // meaningless, therefore use the token index of this type parameter.
      *bound_error = LanguageError::NewFormatted(
          *bound_error,
          script,
          token_pos(),
          Report::kMalboundedType,
          Heap::kNew,
          "type parameter '%s' of class '%s' must extend bound '%s', "
          "but type argument '%s' is not a subtype of '%s'\n",
          type_param_name.ToCString(),
          class_name.ToCString(),
          declared_bound_name.ToCString(),
          bounded_type_name.ToCString(),
          upper_bound_name.ToCString());
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
                            index(),
                            String::Handle(name()),
                            AbstractType::Handle(bound()),
                            token_pos());
}


RawAbstractType* TypeParameter::CloneUninstantiated(
    const Class& new_owner, TrailPtr trail) const {
  ASSERT(IsFinalized());
  AbstractType& upper_bound = AbstractType::Handle(bound());
  upper_bound = upper_bound.CloneUninstantiated(new_owner, trail);
  const Class& old_owner = Class::Handle(parameterized_class());
  const intptr_t new_index = index() +
      new_owner.NumTypeArguments() - old_owner.NumTypeArguments();
  const TypeParameter& clone = TypeParameter::Handle(
      TypeParameter::New(new_owner,
                         new_index,
                         String::Handle(name()),
                         upper_bound,
                         token_pos()));
  clone.set_is_finalized();
  return clone.raw();
}


intptr_t TypeParameter::Hash() const {
  ASSERT(IsFinalized());
  uint32_t result = Class::Handle(parameterized_class()).id();
  // No need to include the hash of the bound, since the type parameter is fully
  // identified by its class and index.
  result = CombineHashes(result, index());
  return FinalizeHash(result);
}


RawTypeParameter* TypeParameter::New() {
  RawObject* raw = Object::Allocate(TypeParameter::kClassId,
                                    TypeParameter::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawTypeParameter*>(raw);
}


RawTypeParameter* TypeParameter::New(const Class& parameterized_class,
                                     intptr_t index,
                                     const String& name,
                                     const AbstractType& bound,
                                     intptr_t token_pos) {
  const TypeParameter& result = TypeParameter::Handle(TypeParameter::New());
  result.set_parameterized_class(parameterized_class);
  result.set_index(index);
  result.set_name(name);
  result.set_bound(bound);
  result.set_token_pos(token_pos);
  result.StoreNonPointer(&result.raw_ptr()->type_state_,
                         RawTypeParameter::kAllocated);
  return result.raw();
}


void TypeParameter::set_token_pos(intptr_t token_pos) const {
  ASSERT(token_pos >= 0);
  StoreNonPointer(&raw_ptr()->token_pos_, token_pos);
}


void TypeParameter::set_type_state(int8_t state) const {
  ASSERT((state == RawTypeParameter::kAllocated) ||
         (state == RawTypeParameter::kBeingFinalized) ||
         (state == RawTypeParameter::kFinalizedUninstantiated));
  StoreNonPointer(&raw_ptr()->type_state_, state);
}


const char* TypeParameter::ToCString() const {
  const char* format =
      "TypeParameter: name %s; index: %d; class: %s; bound: %s";
  const char* name_cstr = String::Handle(Name()).ToCString();
  const Class& cls = Class::Handle(parameterized_class());
  const char* cls_cstr =
      cls.IsNull() ? " null" : String::Handle(cls.Name()).ToCString();
  const AbstractType& upper_bound = AbstractType::Handle(bound());
  const char* bound_cstr = String::Handle(upper_bound.Name()).ToCString();
  intptr_t len = OS::SNPrint(
      NULL, 0, format, name_cstr, index(), cls_cstr, bound_cstr) + 1;
  char* chars = Thread::Current()->zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, format, name_cstr, index(), cls_cstr, bound_cstr);
  return chars;
}


void TypeParameter::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "TypeParameter");
  jsobj.AddServiceId(*this);
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name, vm_name);
  const Class& param_cls = Class::Handle(parameterized_class());
  jsobj.AddProperty("parameterizedClass", param_cls);
  if (ref) {
    return;
  }
  jsobj.AddProperty("parameterIndex", index());
  const AbstractType& upper_bound = AbstractType::Handle(bound());
  jsobj.AddProperty("bound", upper_bound);
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
    const AbstractType& other_ref_type = AbstractType::Handle(
        TypeRef::Cast(other).type());
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
  return this_bound.IsFinalized() &&
         other_bound.IsFinalized() &&
         this_bound.Equals(other_bound);  // Different graph, do not pass trail.
}


bool BoundedType::IsRecursive() const {
  return AbstractType::Handle(type()).IsRecursive();
}


void BoundedType::set_type(const AbstractType& value) const {
  ASSERT(value.IsFinalized() || value.IsBeingFinalized());
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
    Error* bound_error,
    TrailPtr trail,
    Heap::Space space) const {
  ASSERT(IsFinalized());
  AbstractType& bounded_type = AbstractType::Handle(type());
  ASSERT(bounded_type.IsFinalized());
  if (!bounded_type.IsInstantiated()) {
    bounded_type = bounded_type.InstantiateFrom(instantiator_type_arguments,
                                                bound_error,
                                                trail,
                                                space);
    // In case types of instantiator_type_arguments are not finalized, then
    // the instantiated bounded_type is not finalized either.
    // Note that instantiator_type_arguments must have the final length, though.
  }
  if ((Isolate::Current()->flags().type_checks()) &&
      (bound_error != NULL) && bound_error->IsNull()) {
    AbstractType& upper_bound = AbstractType::Handle(bound());
    ASSERT(upper_bound.IsFinalized());
    ASSERT(!upper_bound.IsObjectType() && !upper_bound.IsDynamicType());
    const TypeParameter& type_param = TypeParameter::Handle(type_parameter());
    if (!upper_bound.IsInstantiated()) {
      upper_bound = upper_bound.InstantiateFrom(instantiator_type_arguments,
                                                bound_error,
                                                trail,
                                                space);
      // Instantiated upper_bound may not be finalized. See comment above.
    }
    if (bound_error->IsNull()) {
      if (!type_param.CheckBound(bounded_type, upper_bound, bound_error) &&
          bound_error->IsNull()) {
        // We cannot determine yet whether the bounded_type is below the
        // upper_bound, because one or both of them is still uninstantiated.
        ASSERT(!bounded_type.IsInstantiated() || !upper_bound.IsInstantiated());
        // Postpone bound check by returning a new BoundedType with partially
        // instantiated bounded_type and upper_bound, but keeping type_param.
        bounded_type = BoundedType::New(bounded_type, upper_bound, type_param);
      }
    }
  }
  return bounded_type.raw();
}


RawAbstractType* BoundedType::CloneUnfinalized() const {
  if (IsFinalized()) {
    return raw();
  }
  AbstractType& bounded_type = AbstractType::Handle(type());

  bounded_type = bounded_type.CloneUnfinalized();
  // No need to clone bound or type parameter, as they are not part of the
  // finalization state of this bounded type.
  return BoundedType::New(bounded_type,
                          AbstractType::Handle(bound()),
                          TypeParameter::Handle(type_parameter()));
}


RawAbstractType* BoundedType::CloneUninstantiated(
    const Class& new_owner, TrailPtr trail) const {
  if (IsInstantiated()) {
    return raw();
  }
  AbstractType& bounded_type = AbstractType::Handle(type());
  bounded_type = bounded_type.CloneUninstantiated(new_owner, trail);
  AbstractType& upper_bound = AbstractType::Handle(bound());
  upper_bound = upper_bound.CloneUninstantiated(new_owner, trail);
  TypeParameter& type_param =  TypeParameter::Handle(type_parameter());
  type_param ^= type_param.CloneUninstantiated(new_owner, trail);
  return BoundedType::New(bounded_type, upper_bound, type_param);
}


intptr_t BoundedType::Hash() const {
  uint32_t result = AbstractType::Handle(type()).Hash();
  // No need to include the hash of the bound, since the bound is defined by the
  // type parameter (modulo instantiation state).
  result = CombineHashes(result,
                         TypeParameter::Handle(type_parameter()).Hash());
  return FinalizeHash(result);
}


RawBoundedType* BoundedType::New() {
  RawObject* raw = Object::Allocate(BoundedType::kClassId,
                                    BoundedType::InstanceSize(),
                                    Heap::kOld);
  return reinterpret_cast<RawBoundedType*>(raw);
}


RawBoundedType* BoundedType::New(const AbstractType& type,
                                 const AbstractType& bound,
                                 const TypeParameter& type_parameter) {
  const BoundedType& result = BoundedType::Handle(BoundedType::New());
  result.set_type(type);
  result.set_bound(bound);
  result.set_type_parameter(type_parameter);
  return result.raw();
}


const char* BoundedType::ToCString() const {
  const char* format = "BoundedType: type %s; bound: %s; type param: %s of %s";
  const char* type_cstr = String::Handle(AbstractType::Handle(
      type()).Name()).ToCString();
  const char* bound_cstr = String::Handle(AbstractType::Handle(
      bound()).Name()).ToCString();
  const TypeParameter& type_param = TypeParameter::Handle(type_parameter());
  const char* type_param_cstr = String::Handle(type_param.name()).ToCString();
  const Class& cls = Class::Handle(type_param.parameterized_class());
  const char* cls_cstr = String::Handle(cls.Name()).ToCString();
  intptr_t len = OS::SNPrint(
      NULL, 0, format, type_cstr, bound_cstr, type_param_cstr, cls_cstr) + 1;
  char* chars = Thread::Current()->zone()->Alloc<char>(len);
  OS::SNPrint(
      chars, len, format, type_cstr, bound_cstr, type_param_cstr, cls_cstr);
  return chars;
}


void BoundedType::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "BoundedType");
  jsobj.AddServiceId(*this);
  const String& user_name = String::Handle(PrettyName());
  const String& vm_name = String::Handle(Name());
  AddNameProperties(&jsobj, user_name, vm_name);
  if (ref) {
    return;
  }
  jsobj.AddProperty("targetType", AbstractType::Handle(type()));
  jsobj.AddProperty("bound", AbstractType::Handle(bound()));
}


intptr_t MixinAppType::token_pos() const {
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
  const char* super_type_cstr = String::Handle(AbstractType::Handle(
      super_type()).Name()).ToCString();
  const char* first_mixin_type_cstr = String::Handle(AbstractType::Handle(
      MixinTypeAt(0)).Name()).ToCString();
  intptr_t len = OS::SNPrint(
      NULL, 0, format, super_type_cstr, first_mixin_type_cstr) + 1;
  char* chars = Thread::Current()->zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, format, super_type_cstr, first_mixin_type_cstr);
  return chars;
}


void MixinAppType::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
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
                                    MixinAppType::InstanceSize(),
                                    Heap::kNew);
  return reinterpret_cast<RawMixinAppType*>(raw);
}


RawMixinAppType* MixinAppType::New(const AbstractType& super_type,
                                   const Array& mixin_types) {
  const MixinAppType& result = MixinAppType::Handle(MixinAppType::New());
  result.set_super_type(super_type);
  result.set_mixin_types(mixin_types);
  return result.raw();
}


const char* Number::ToCString() const {
  // Number is an interface. No instances of Number should exist.
  UNREACHABLE();
  return "Number";
}


void Number::PrintJSONImpl(JSONStream* stream, bool ref) const {
  UNREACHABLE();
}


const char* Integer::ToCString() const {
  // Integer is an interface. No instances of Integer should exist.
  UNREACHABLE();
  return "Integer";
}


void Integer::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Int");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}


// Throw JavascriptIntegerOverflow exception.
static void ThrowJavascriptIntegerOverflow(const Integer& i) {
  const Array& exc_args = Array::Handle(Array::New(1));
  const String& i_str = String::Handle(String::New(i.ToCString()));
  exc_args.SetAt(0, i_str);
  Exceptions::ThrowByType(Exceptions::kJavascriptIntegerOverflowError,
      exc_args);
}


RawInteger* Integer::New(const String& str, Heap::Space space) {
  // We are not supposed to have integers represented as two byte strings.
  ASSERT(str.IsOneByteString());
  int64_t value;
  if (!OS::StringToInt64(str.ToCString(), &value)) {
    const Bigint& big = Bigint::Handle(
        Bigint::NewFromCString(str.ToCString(), space));
    ASSERT(!big.FitsIntoSmi());
    ASSERT(!big.FitsIntoInt64());
    if (FLAG_throw_on_javascript_int_overflow) {
      ThrowJavascriptIntegerOverflow(big);
    }
    return big.raw();
  }
  return Integer::New(value, space);
}


// This is called from LiteralToken::New() in the parser, so we can't
// raise an exception for javascript overflow here. Instead we do it in
// Parser::CurrentIntegerLiteral(), which is the point in the parser where
// integer literals escape, so we can call Parser::ErrorMsg().
RawInteger* Integer::NewCanonical(const String& str) {
  // We are not supposed to have integers represented as two byte strings.
  ASSERT(str.IsOneByteString());
  int64_t value;
  if (!OS::StringToInt64(str.ToCString(), &value)) {
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


RawInteger* Integer::New(int64_t value, Heap::Space space, const bool silent) {
  const bool is_smi = Smi::IsValid(value);
  if (!silent &&
      FLAG_throw_on_javascript_int_overflow &&
      !Utils::IsJavascriptInt64(value)) {
    const Integer& i = is_smi ?
        Integer::Handle(Smi::New(static_cast<intptr_t>(value))) :
        Integer::Handle(Mint::New(value, space));
    ThrowJavascriptIntegerOverflow(i);
  }
  if (is_smi) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  return Mint::New(value, space);
}


RawInteger* Integer::NewFromUint64(uint64_t value, Heap::Space space) {
  if (value > static_cast<uint64_t>(Mint::kMaxValue)) {
    if (FLAG_throw_on_javascript_int_overflow) {
      const Integer &i = Integer::Handle(Bigint::NewFromUint64(value, space));
      ThrowJavascriptIntegerOverflow(i);
    }
    return Bigint::NewFromUint64(value, space);
  } else {
    return Integer::New(value, space);
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


// Returns true if the signed Integer does not fit into a
// Javascript integer.
bool Integer::CheckJavascriptIntegerOverflow() const {
  // Always overflow if the value doesn't fit into an int64_t.
  int64_t value = 1ULL << 63;
  if (IsSmi()) {
    value = AsInt64Value();
  } else if (IsMint()) {
    Mint& mint = Mint::Handle();
    mint ^= raw();
    value = mint.value();
  } else {
    if (Bigint::Cast(*this).FitsIntoInt64()) {
      value = AsInt64Value();
    }
  }
  return !Utils::IsJavascriptInt64(value);
}


RawInteger* Integer::AsValidInteger() const {
  if (FLAG_throw_on_javascript_int_overflow &&
      CheckJavascriptIntegerOverflow()) {
    ThrowJavascriptIntegerOverflow(*this);
  }
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
      return Smi::New(value);
    }
    return Mint::New(value);
  }
  return raw();
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
          // In 64-bit mode, the product of two signed integers fits in a
          // 64-bit result if the sum of the highest bits of their absolute
          // values is smaller than 62.
          ASSERT(sizeof(intptr_t) == sizeof(int64_t));
          if ((Utils::HighestBit(left_value) +
               Utils::HighestBit(right_value)) < 62) {
            return Integer::New(left_value * right_value, space);
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
        if (((left_value < 0) != (right_value < 0)) ||
            ((left_value + right_value) < 0) == (left_value < 0)) {
          return Integer::New(left_value + right_value, space);
        }
        break;
      }
      case Token::kSUB: {
        if (((left_value < 0) == (right_value < 0)) ||
            ((left_value - right_value) < 0) == (left_value < 0)) {
          return Integer::New(left_value - right_value, space);
        }
        break;
      }
      case Token::kMUL: {
        if ((Utils::HighestBit(left_value) +
             Utils::HighestBit(right_value)) < 62) {
          return Integer::New(left_value * right_value, space);
        }
        break;
      }
      case Token::kTRUNCDIV: {
        if ((left_value != Mint::kMinValue) || (right_value != -1)) {
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
  return Integer::null();  // Notify caller that a bigint operation is required.
}


static bool Are64bitOperands(const Integer& op1, const Integer& op2) {
  return !op1.IsBigint() && !op2.IsBigint();
}


RawInteger* Integer::BitOp(
    Token::Kind kind, const Integer& other, Heap::Space space) const {
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
  return Integer::null();  // Notify caller that a bigint operation is required.
}


// TODO(srdjan): Clarify handling of negative right operand in a shift op.
RawInteger* Smi::ShiftOp(Token::Kind kind,
                         const Smi& other,
                         Heap::Space space,
                         const bool silent) const {
  intptr_t result = 0;
  const intptr_t left_value = Value();
  const intptr_t right_value = other.Value();
  ASSERT(right_value >= 0);
  switch (kind) {
    case Token::kSHL: {
      if ((left_value == 0) || (right_value == 0)) {
        return raw();
      }
      { // Check for overflow.
        int cnt = Utils::BitLength(left_value);
        if ((cnt + right_value) > Smi::kBits) {
          if ((cnt + right_value) > Mint::kBits) {
            return Bigint::NewFromShiftedInt64(left_value, right_value, space);
          } else {
            int64_t left_64 = left_value;
            return Integer::New(left_64 << right_value, space, silent);
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


void Smi::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Int");
  jsobj.AddFixedServiceId("objects/int-%" Pd "", Value());
  jsobj.AddPropertyF("valueAsString", "%" Pd "", Value());
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
    RawObject* raw = Object::Allocate(Mint::kClassId,
                                      Mint::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(val);
  return result.raw();
}


RawMint* Mint::NewCanonical(int64_t value) {
  // Do not allocate a Mint if Smi would do.
  ASSERT(!Smi::IsValid(value));
  const Class& cls =
      Class::Handle(Isolate::Current()->object_store()->mint_class());
  const Array& constants = Array::Handle(cls.constants());
  const intptr_t constants_len = constants.Length();
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Mint& canonical_value = Mint::Handle();
  intptr_t index = 0;
  while (index < constants_len) {
    canonical_value ^= constants.At(index);
    if (canonical_value.IsNull()) {
      break;
    }
    if (canonical_value.value() == value) {
      ASSERT(canonical_value.IsCanonical());
      return canonical_value.raw();
    }
    index++;
  }
  // The value needs to be added to the constants list. Grow the list if
  // it is full.
  canonical_value = Mint::New(value, Heap::kOld);
  cls.InsertCanonicalConstant(index, canonical_value);
  canonical_value.SetCanonical();
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


void Mint::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Integer::PrintJSONImpl(stream, ref);
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
    RawObject* raw = Object::Allocate(Double::kClassId,
                                      Double::InstanceSize(),
                                      space);
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
  const Class& cls =
      Class::Handle(Isolate::Current()->object_store()->double_class());
  const Array& constants = Array::Handle(cls.constants());
  const intptr_t constants_len = constants.Length();
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Double& canonical_value = Double::Handle();
  intptr_t index = 0;
  while (index < constants_len) {
    canonical_value ^= constants.At(index);
    if (canonical_value.IsNull()) {
      break;
    }
    if (canonical_value.BitwiseEqualsToDouble(value)) {
      return canonical_value.raw();
    }
    index++;
  }
  // The value needs to be added to the constants list. Grow the list if
  // it is full.
  canonical_value = Double::New(value, Heap::kOld);
  cls.InsertCanonicalConstant(index, canonical_value);
  canonical_value.SetCanonical();
  return canonical_value.raw();
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


void Double::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Double");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
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


bool Bigint::CheckAndCanonicalizeFields(const char** error_str) const {
  // Bool field neg should always be canonical.
  ASSERT(Bool::Handle(neg()).IsCanonical());
  // Smi field used is canonical by definition.
  if (Used() > 0) {
    // Canonicalize TypedData field digits.
    TypedData& digits_ = TypedData::Handle(digits());
    digits_ ^= digits_.CheckAndCanonicalize(NULL);
    ASSERT(!digits_.IsNull());
    set_digits(digits_);
  } else {
    ASSERT(digits() == TypedData::EmptyUint32Array(Isolate::Current()));
  }
  return true;
}


RawBigint* Bigint::New(Heap::Space space) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate->object_store()->bigint_class() != Class::null());
  Bigint& result = Bigint::Handle(isolate);
  {
    RawObject* raw = Object::Allocate(Bigint::kClassId,
                                      Bigint::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.SetNeg(false);
  result.SetUsed(0);
  result.set_digits(
      TypedData::Handle(isolate, TypedData::EmptyUint32Array(isolate)));
  return result.raw();
}


RawBigint* Bigint::New(bool neg, intptr_t used, const TypedData& digits,
                       Heap::Space space) {
  ASSERT((used == 0) ||
         (!digits.IsNull() && (digits.Length() >= (used + (used & 1)))));
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate->object_store()->bigint_class() != Class::null());
  Bigint& result = Bigint::Handle(isolate);
  {
    RawObject* raw = Object::Allocate(Bigint::kClassId,
                                      Bigint::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  // Clamp the digits array.
  while ((used > 0) && (digits.GetUint32((used - 1) << 2) == 0)) {
    --used;
  }
  if (used > 0) {
    if ((used & 1) != 0) {
      // Set leading zero for 64-bit processing of digit pairs.
      digits.SetUint32(used << 2, 0);
    }
    result.set_digits(digits);
  } else {
    neg = false;
    result.set_digits(
        TypedData::Handle(isolate, TypedData::EmptyUint32Array(isolate)));
  }
  result.SetNeg(neg);
  result.SetUsed(used);
  return result.raw();
}


RawBigint* Bigint::NewFromInt64(int64_t value, Heap::Space space) {
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
  const TypedData& digits = TypedData::Handle(NewDigits(2, space));
  SetDigitAt(digits, 0, static_cast<uint32_t>(value));
  SetDigitAt(digits, 1, static_cast<uint32_t>(value >> 32));
  return New(false, 2, digits, space);
}


RawBigint* Bigint::NewFromShiftedInt64(int64_t value, intptr_t shift,
                                       Heap::Space space) {
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
      (bit_shift == 0) ? 0
                       : static_cast<uint32_t>(abs_value >> (64 - bit_shift)));
  return New(neg, used, digits, space);
}


RawBigint* Bigint::NewFromCString(const char* str, Heap::Space space) {
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
  if ((str_length >= 2) &&
      (str[0] == '0') &&
      ((str[1] == 'x') || (str[1] == 'X'))) {
    digits = NewDigitsFromHexCString(&str[2], &used, space);
  } else {
    digits = NewDigitsFromDecCString(str, &used, space);
  }
  return New(neg, used, digits, space);
}


RawBigint* Bigint::NewCanonical(const String& str) {
  const Bigint& value = Bigint::Handle(
      Bigint::NewFromCString(str.ToCString(), Heap::kOld));
  const Class& cls =
      Class::Handle(Isolate::Current()->object_store()->bigint_class());
  const Array& constants = Array::Handle(cls.constants());
  const intptr_t constants_len = constants.Length();
  // Linear search to see whether this value is already present in the
  // list of canonicalized constants.
  Bigint& canonical_value = Bigint::Handle();
  intptr_t index = 0;
  while (index < constants_len) {
    canonical_value ^= constants.At(index);
    if (canonical_value.IsNull()) {
      break;
    }
    if (canonical_value.Equals(value)) {
      return canonical_value.raw();
    }
    index++;
  }
  // The value needs to be added to the constants list. Grow the list if
  // it is full.
  cls.InsertCanonicalConstant(index, value);
  value.SetCanonical();
  return value.raw();
}


RawTypedData* Bigint::NewDigitsFromHexCString(const char* str, intptr_t* used,
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


RawTypedData* Bigint::NewDigitsFromDecCString(const char* str, intptr_t* used,
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
  const intptr_t length = (kLog10Dividend * str_length) /
                          (kLog10Divisor * kBitsPerDigit) + 5;
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
  // For consistency between platforms fallback to GCC style converstion
  // on Win64.
  //
  const int64_t y = static_cast<int64_t>(x);
  if (y > 0) {
    return static_cast<double>(y);
  } else {
    const double half = static_cast<double>(
        static_cast<int64_t>(x >> 1) | (y & 1));
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
      for (intptr_t i = Used(); --i >= 0; ) {
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


const char* Bigint::ToDecCString(uword (*allocator)(intptr_t size)) const {
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
  char* chars = reinterpret_cast<char*>(allocator(len));
  intptr_t pos = 0;
  const intptr_t kDivisor = 100000000;
  const intptr_t kDigits = 8;
  ASSERT(pow(10.0, 1.0 * kDigits) == kDivisor);
  ASSERT(kDivisor < kDigitBase);
  ASSERT(Smi::IsValid(kDivisor));
  // Allocate a copy of the digits.
  const TypedData& rest_digits = TypedData::Handle(
      TypedData::New(kTypedDataUint32ArrayCid, used));
  for (intptr_t i = 0; i < used; i++) {
    rest_digits.SetUint32(i << 2, DigitAt(i));
  }
  if (used == 0) {
    chars[pos++] = '0';
  }
  while (used > 0) {
    uint32_t remainder = 0;
    for (intptr_t i = used - 1; i >= 0; i--) {
      uint64_t dividend = (static_cast<uint64_t>(remainder) << kBitsPerDigit) +
          rest_digits.GetUint32(i << 2);
      uint32_t quotient = static_cast<uint32_t>(dividend / kDivisor);
      remainder = static_cast<uint32_t>(
          dividend - static_cast<uint64_t>(quotient) * kDivisor);
      rest_digits.SetUint32(i << 2, quotient);
    }
    // Clamp rest_digits.
    while ((used > 0) && (rest_digits.GetUint32((used - 1) << 2) == 0)) {
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


const char* Bigint::ToHexCString(uword (*allocator)(intptr_t size)) const {
  const intptr_t used = Used();
  if (used == 0) {
    const char* zero = "0x0";
    const size_t len = strlen(zero) + 1;
    char* chars = reinterpret_cast<char*>(allocator(len));
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
  char* chars = reinterpret_cast<char*>(allocator(len));
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


static uword BigintAllocator(intptr_t size) {
  Zone* zone = Thread::Current()->zone();
  return zone->AllocUnsafe(size);
}


const char* Bigint::ToCString() const {
  return ToDecCString(&BigintAllocator);
}


void Bigint::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Integer::PrintJSONImpl(stream, ref);
}


// Synchronize with implementation in compiler (intrinsifier).
class StringHasher : ValueObject {
 public:
  StringHasher() : hash_(0) {}
  void Add(int32_t ch) {
    hash_ = CombineHashes(hash_, ch);
  }
  void Add(const String& str, intptr_t begin_index, intptr_t len);

  // Return a non-zero hash of at most 'bits' bits.
  intptr_t Finalize(int bits) {
    ASSERT(1 <= bits && bits <= (kBitsPerWord - 1));
    hash_ = FinalizeHash(hash_);
    hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
    ASSERT(hash_ <= static_cast<uint32_t>(kMaxInt32));
    return hash_ == 0 ? 1 : hash_;
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
  return hasher.Finalize(String::kHashBits);
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
    return hasher.Finalize(String::kHashBits);
  }
}


template<typename T>
static intptr_t HashImpl(const T* characters, intptr_t len) {
  ASSERT(len >= 0);
  StringHasher hasher;
  for (intptr_t i = 0; i < len; i++) {
    hasher.Add(characters[i]);
  }
  return hasher.Finalize(String::kHashBits);
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
  return hasher.Finalize(String::kHashBits);
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

  if (!other.IsString() || other.IsNull()) {
    return false;
  }

  const String& other_string = String::Cast(other);
  if (this->HasHash() && other_string.HasHash() &&
      (this->Hash() != other_string.Hash())) {
    return false;  // Both sides have a hash code and it does not match.
  }
  return Equals(other_string, 0, other_string.Length());
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
    intptr_t consumed = Utf8::Decode(reinterpret_cast<const uint8_t*>(cstr),
                                     len,
                                     &ch);
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
  CodePointIterator it(*this);
  intptr_t i = 0;
  bool has_more = it.Next();
  while (has_more && (i < len)) {
    if ((it.Current() != static_cast<int32_t>(utf32_array[i]))) {
      return false;
    }
    // Advance both streams forward.
    ++i;
    has_more = it.Next();
  }
  // Strings are only true iff we reached the end in both streams.
  return (i == len) && !has_more;
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


RawInstance* String::CheckAndCanonicalize(const char** error_str) const {
  if (IsCanonical()) {
    return this->raw();
  }
  return Symbols::New(*this);
}


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
  Utf8::DecodeToUTF16(utf8_array, array_len,
                      TwoByteString::CharAddr(strobj, 0), len);
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


void String::Copy(const String& dst, intptr_t dst_offset,
                  const uint8_t* characters,
                  intptr_t len) {
  ASSERT(dst_offset >= 0);
  ASSERT(len >= 0);
  ASSERT(len <= (dst.Length() - dst_offset));
  if (dst.IsOneByteString()) {
    NoSafepointScope no_safepoint;
    if (len > 0) {
      memmove(OneByteString::CharAddr(dst, dst_offset),
              characters,
              len);
    }
  } else if (dst.IsTwoByteString()) {
    for (intptr_t i = 0; i < len; ++i) {
      *TwoByteString::CharAddr(dst, i + dst_offset) = characters[i];
    }
  }
}


void String::Copy(const String& dst, intptr_t dst_offset,
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
      memmove(TwoByteString::CharAddr(dst, dst_offset),
              utf16_array,
              array_len * 2);
    }
  }
}


void String::Copy(const String& dst, intptr_t dst_offset,
                  const String& src, intptr_t src_offset,
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
        String::Copy(dst,
                     dst_offset,
                     OneByteString::CharAddr(src, src_offset),
                     len);
      } else {
        ASSERT(src.IsExternalOneByteString());
        NoSafepointScope no_safepoint;
        String::Copy(dst,
                     dst_offset,
                     ExternalOneByteString::CharAddr(src, src_offset),
                     len);
      }
    } else {
      ASSERT(char_size == kTwoByteChar);
      if (src.IsTwoByteString()) {
        NoSafepointScope no_safepoint;
        String::Copy(dst,
                     dst_offset,
                     TwoByteString::CharAddr(src, src_offset),
                     len);
      } else {
        ASSERT(src.IsExternalTwoByteString());
        NoSafepointScope no_safepoint;
        String::Copy(dst,
                     dst_offset,
                     ExternalTwoByteString::CharAddr(src, src_offset),
                     len);
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


RawString* String::EncodeIRI(const String& str) {
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
  const String& dststr = String::Handle(
      OneByteString::New(len + num_escapes, Heap::kNew));
  {
    intptr_t index = 0;
    for (int i = 0; i < len; ++i) {
      uint8_t byte = utf8[i];
      if (!IsURISafeCharacter(byte)) {
        OneByteString::SetCharAt(dststr, index, '%');
        OneByteString::SetCharAt(dststr, index + 1,
                                 GetHexCharacter(byte >> 4));
        OneByteString::SetCharAt(dststr, index + 2,
                                 GetHexCharacter(byte & 0xF));
        index += 3;
      } else {
        ASSERT(byte <= 127);
        OneByteString::SetCharAt(dststr, index, byte);
        index += 1;
      }
    }
  }
  return dststr.raw();
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


RawString* String::NewFormattedV(const char* format, va_list args) {
  va_list args_copy;
  va_copy(args_copy, args);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args_copy);
  va_end(args_copy);

  Zone* zone = Thread::Current()->zone();
  char* buffer = zone->Alloc<char>(len + 1);
  OS::VSNPrint(buffer, (len + 1), format, args);

  return String::New(buffer);
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


RawString* String::ConcatAll(const Array& strings,
                             Heap::Space space) {
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
  return String::SubString(str,
                           begin_index,
                           (str.Length() - begin_index),
                           space);
}


RawString* String::SubString(const String& str,
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
  String& result = String::Handle();
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


void String::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  if (raw() == Symbols::OptimizedOut().raw()) {
    // TODO(turnidge): This is a hack.  The user could have this
    // special string in their program.  Fixing this involves updating
    // the debugging api a bit.
    jsobj.AddProperty("type", "Sentinel");
    jsobj.AddProperty("kind", "OptimizedOut");
    jsobj.AddProperty("valueAsString", "<optimized out>");
    return;
  }
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "String");
  jsobj.AddServiceId(*this);
  if (ref) {
    bool did_truncate = jsobj.AddPropertyStr("valueAsString", *this, 128);
    if (did_truncate) {
      jsobj.AddProperty("valueAsStringIsTruncated", did_truncate);
    }
  } else {
    bool did_truncate = jsobj.AddPropertyStr("valueAsString", *this);
    ASSERT(!did_truncate);
  }
}


void String::ToUTF8(uint8_t* utf8_array, intptr_t array_len) const {
  ASSERT(array_len >= Utf8::Length(*this));
  Utf8::Encode(*this, reinterpret_cast<char*>(utf8_array), array_len);
}


static FinalizablePersistentHandle* AddFinalizer(
    const Object& referent,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback) {
  ASSERT((callback != NULL && peer != NULL) ||
         (callback == NULL && peer == NULL));
  const bool is_prologue = false;
  // TODO(19482): Make API consistent for external size of strings/typed data.
  const intptr_t external_size = 0;
  return FinalizablePersistentHandle::New(Isolate::Current(),
                                          is_prologue,
                                          referent,
                                          peer,
                                          callback,
                                          external_size);
}


RawString* String::MakeExternal(void* array,
                                intptr_t length,
                                void* peer,
                                Dart_PeerFinalizer cback) const {
  String& result = String::Handle();
  void* external_data;
  Dart_WeakPersistentHandleFinalizer finalizer;
  {
    NoSafepointScope no_safepoint;
    ASSERT(array != NULL);
    intptr_t str_length = this->Length();
    ASSERT(length >= (str_length * this->CharSize()));
    intptr_t class_id = raw()->GetClassId();

    ASSERT(!InVMHeap());
    if (class_id == kOneByteStringCid) {
      intptr_t used_size = ExternalOneByteString::InstanceSize();
      intptr_t original_size = OneByteString::InstanceSize(str_length);
      ASSERT(original_size >= used_size);

      // Copy the data into the external array.
      if (str_length > 0) {
        memmove(array, OneByteString::CharAddr(*this, 0), str_length);
      }

      // If there is any left over space fill it with either an Array object or
      // just a plain object (depending on the amount of left over space) so
      // that it can be traversed over successfully during garbage collection.
      Object::MakeUnusedSpaceTraversable(*this, original_size, used_size);

      // Update the class information of the object.
      const intptr_t class_id = kExternalOneByteStringCid;
      uword tags = raw_ptr()->tags_;
      uword old_tags;
      do {
        old_tags = tags;
        uword new_tags = RawObject::SizeTag::update(used_size, old_tags);
        new_tags = RawObject::ClassIdTag::update(class_id, new_tags);
        tags = CompareAndSwapTags(old_tags, new_tags);
      } while (tags != old_tags);
      result = this->raw();
      const uint8_t* ext_array = reinterpret_cast<const uint8_t*>(array);
      ExternalStringData<uint8_t>* ext_data = new ExternalStringData<uint8_t>(
          ext_array, peer, cback);
      ASSERT(result.Length() == str_length);
      ASSERT(!result.HasHash() ||
             (result.Hash() == String::Hash(ext_array, str_length)));
      ExternalOneByteString::SetExternalData(result, ext_data);
      external_data = ext_data;
      finalizer = ExternalOneByteString::Finalize;
    } else {
      ASSERT(class_id == kTwoByteStringCid);
      intptr_t used_size = ExternalTwoByteString::InstanceSize();
      intptr_t original_size = TwoByteString::InstanceSize(str_length);
      ASSERT(original_size >= used_size);

      // Copy the data into the external array.
      if (str_length > 0) {
        memmove(array,
                TwoByteString::CharAddr(*this, 0),
                (str_length * kTwoByteChar));
      }

      // If there is any left over space fill it with either an Array object or
      // just a plain object (depending on the amount of left over space) so
      // that it can be traversed over successfully during garbage collection.
      Object::MakeUnusedSpaceTraversable(*this, original_size, used_size);

      // Update the class information of the object.
      const intptr_t class_id = kExternalTwoByteStringCid;
      uword tags = raw_ptr()->tags_;
      uword old_tags;
      do {
        old_tags = tags;
        uword new_tags = RawObject::SizeTag::update(used_size, old_tags);
        new_tags = RawObject::ClassIdTag::update(class_id, new_tags);
        tags = CompareAndSwapTags(old_tags, new_tags);
      } while (tags != old_tags);
      result = this->raw();
      const uint16_t* ext_array = reinterpret_cast<const uint16_t*>(array);
      ExternalStringData<uint16_t>* ext_data = new ExternalStringData<uint16_t>(
          ext_array, peer, cback);
      ASSERT(result.Length() == str_length);
      ASSERT(!result.HasHash() ||
             (result.Hash() == String::Hash(ext_array, str_length)));
      ExternalTwoByteString::SetExternalData(result, ext_data);
      external_data = ext_data;
      finalizer = ExternalTwoByteString::Finalize;
    }
  }  // NoSafepointScope
  AddFinalizer(result, external_data, finalizer);
  return this->raw();
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
                         intptr_t start, intptr_t end,
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
  return CStringToDouble(reinterpret_cast<const char*>(startChar),
                         length, result);
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
template<typename T1, typename T2>
static bool EqualsIgnoringPrivateKey(const String& str1,
                                     const String& str2) {
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
      while ((pos < len) && (T1::CharAt(str1, pos) != '.')) {
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
    case kOneByteStringCid :                                                   \
      return dart::EqualsIgnoringPrivateKey<type, OneByteString>(str1, str2);  \
    case kTwoByteStringCid :                                                   \
      return dart::EqualsIgnoringPrivateKey<type, TwoByteString>(str1, str2);  \
    case kExternalOneByteStringCid :                                           \
      return dart::EqualsIgnoringPrivateKey<type, ExternalOneByteString>(str1, \
                                                                         str2);\
    case kExternalTwoByteStringCid :                                           \
      return dart::EqualsIgnoringPrivateKey<type, ExternalTwoByteString>(str1, \
                                                                         str2);\
  }                                                                            \
  UNREACHABLE();                                                               \


bool String::EqualsIgnoringPrivateKey(const String& str1,
                                      const String& str2) {
  if (str1.raw() == str2.raw()) {
    return true;  // Both handles point to the same raw instance.
  }
  NoSafepointScope no_safepoint;
  intptr_t str1_class_id = str1.raw()->GetClassId();
  intptr_t str2_class_id = str2.raw()->GetClassId();
  switch (str1_class_id) {
    case kOneByteStringCid :
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id, OneByteString, str1, str2);
      break;
    case kTwoByteStringCid :
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id, TwoByteString, str1, str2);
      break;
    case kExternalOneByteStringCid :
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id,
                                  ExternalOneByteString, str1, str2);
      break;
    case kExternalTwoByteStringCid :
      EQUALS_IGNORING_PRIVATE_KEY(str2_class_id,
                                  ExternalTwoByteString, str1, str2);
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
    const String& dststr = String::Handle(
        OneByteString::New(len + num_escapes, Heap::kNew));
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
    const String& dststr = String::Handle(
        OneByteString::New(len + num_escapes, Heap::kNew));
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


RawOneByteString* OneByteString::New(intptr_t len,
                                     Heap::Space space) {
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
                                      OneByteString::InstanceSize(len),
                                      space);
    NoSafepointScope no_safepoint;
    RawOneByteString* result = reinterpret_cast<RawOneByteString*>(raw);
    result->StoreSmi(&(result->ptr()->length_), Smi::New(len));
    result->StoreSmi(&(result->ptr()->hash_), Smi::New(0));
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


RawOneByteString* OneByteString::New(const String& str,
                                     Heap::Space space) {
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
            other_typed_data.DataAddr(other_start_index),
            other_len);
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
            other_typed_data.DataAddr(other_start_index),
            other_len);
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
    const uint8_t* src =  &raw_ptr(str)->data()[begin_index];
    memmove(dest, src, length);
  }
  return result;
}


void OneByteString::SetPeer(const String& str,
                            void* peer,
                            Dart_PeerFinalizer cback) {
  ASSERT(!str.IsNull() && str.IsOneByteString());
  ASSERT(peer != NULL);
  ExternalStringData<uint8_t>* ext_data =
      new ExternalStringData<uint8_t>(NULL, peer, cback);
  AddFinalizer(str, ext_data, OneByteString::Finalize);
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
    const String& dststr = String::Handle(
        TwoByteString::New(len + num_escapes, Heap::kNew));
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


RawTwoByteString* TwoByteString::New(intptr_t len,
                                     Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->two_byte_string_class());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in TwoByteString::New: invalid len %" Pd "\n", len);
  }
  String& result = String::Handle();
  {
    RawObject* raw = Object::Allocate(TwoByteString::kClassId,
                                      TwoByteString::InstanceSize(len),
                                      space);
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


RawTwoByteString* TwoByteString::New(const String& str,
                                     Heap::Space space) {
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
                            void* peer,
                            Dart_PeerFinalizer cback) {
  ASSERT(!str.IsNull() && str.IsTwoByteString());
  ASSERT(peer != NULL);
  ExternalStringData<uint16_t>* ext_data =
      new ExternalStringData<uint16_t>(NULL, peer, cback);
  AddFinalizer(str, ext_data, TwoByteString::Finalize);
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
  ASSERT(Isolate::Current()->object_store()->
         external_one_byte_string_class() != Class::null());
  if (len < 0 || len > kMaxElements) {
    // This should be caught before we reach here.
    FATAL1("Fatal error in ExternalOneByteString::New: invalid len %" Pd "\n",
           len);
  }
  String& result = String::Handle();
  ExternalStringData<uint8_t>* external_data =
      new ExternalStringData<uint8_t>(data, peer, callback);
  {
    RawObject* raw = Object::Allocate(ExternalOneByteString::kClassId,
                                      ExternalOneByteString::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
    SetExternalData(result, external_data);
  }
  AddFinalizer(result, external_data, ExternalOneByteString::Finalize);
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
    RawObject* raw = Object::Allocate(ExternalTwoByteString::kClassId,
                                      ExternalTwoByteString::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    result.SetHash(0);
    SetExternalData(result, external_data);
  }
  AddFinalizer(result, external_data, ExternalTwoByteString::Finalize);
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
    RawObject* raw = Object::Allocate(Bool::kClassId,
                                      Bool::InstanceSize(),
                                      Heap::kOld);
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


void Bool::PrintJSONImpl(JSONStream* stream, bool ref) const {
  const char* str = ToCString();
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Bool");
  jsobj.AddFixedServiceId("objects/bool-%s", str);
  jsobj.AddPropertyF("valueAsString", "%s", str);
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

  // Both arrays must have the same type arguments.
  const TypeArguments& type_args = TypeArguments::Handle(GetTypeArguments());
  const TypeArguments& other_type_args = TypeArguments::Handle(
      other.GetTypeArguments());
  if (!type_args.Equals(other_type_args)) {
    return false;
  }

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
  return true;
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
        Object::Allocate(class_id,
                         Array::InstanceSize(len),
                         space));
    NoSafepointScope no_safepoint;
    raw->StoreSmi(&(raw->ptr()->length_), Smi::New(len));
    VerifiedMemory::Accept(reinterpret_cast<uword>(raw->ptr()),
                           Array::InstanceSize(len));
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
  NoSafepointScope no_safepoint;
  uword tags = raw_ptr()->tags_;
  uword old_tags;
  do {
    old_tags = tags;
    uword new_tags = RawObject::ClassIdTag::update(kImmutableArrayCid,
                                                   old_tags);
    tags = CompareAndSwapTags(old_tags, new_tags);
  } while (tags != old_tags);
}


const char* Array::ToCString() const {
  if (IsNull()) {
    return IsImmutable() ? "_ImmutableList NULL" : "_List NULL";
  }
  Zone* zone = Thread::Current()->zone();
  const char* format = IsImmutable() ? "_ImmutableList len:%" Pd
                                     : "_List len:%" Pd;
  return zone->PrintToString(format, Length());
}


void Array::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "List");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  {
    JSONArray jsarr(&jsobj, "elements");
    Object& element = Object::Handle();
    for (intptr_t index = 0; index < Length(); index++) {
      element = At(index);
      jsarr.AddValue(element);
    }
  }
}


RawArray* Array::Grow(const Array& source,
                      intptr_t new_length,
                      Heap::Space space) {
  Isolate* isolate = Isolate::Current();
  const Array& result = Array::Handle(isolate, Array::New(new_length, space));
  intptr_t len = 0;
  if (!source.IsNull()) {
    len = source.Length();
    result.SetTypeArguments(
        TypeArguments::Handle(isolate, source.GetTypeArguments()));
  }
  ASSERT(new_length >= len);  // Cannot copy 'source' into new array.
  ASSERT(new_length != len);  // Unnecessary copying of array.
  PassiveObject& obj = PassiveObject::Handle(isolate);
  for (int i = 0; i < len; i++) {
    obj = source.At(i);
    result.SetAt(i, obj);
  }
  return result.raw();
}


RawArray* Array::MakeArray(const GrowableObjectArray& growable_array) {
  ASSERT(!growable_array.IsNull());
  intptr_t used_len = growable_array.Length();
  // Get the type arguments and prepare to copy them.
  const TypeArguments& type_arguments =
      TypeArguments::Handle(growable_array.GetTypeArguments());
  if ((used_len == 0) && (type_arguments.IsNull())) {
    // This is a raw List (as in no type arguments), so we can return the
    // simple empty array.
    return Object::empty_array().raw();
  }
  intptr_t capacity_len = growable_array.Capacity();
  Isolate* isolate = Isolate::Current();
  const Array& array = Array::Handle(isolate, growable_array.data());
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
  uword old_tags;
  do {
    old_tags = tags;
    uword new_tags = RawObject::SizeTag::update(used_size, old_tags);
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


bool Array::CheckAndCanonicalizeFields(const char** error_str) const {
  Object& obj = Object::Handle();
  // Iterate over all elements, canonicalize numbers and strings, expect all
  // other instances to be canonical otherwise report error (return false).
  for (intptr_t i = 0; i < Length(); i++) {
    obj = At(i);
    if (obj.IsInstance() && !obj.IsSmi() && !obj.IsCanonical()) {
      if (obj.IsNumber() || obj.IsString()) {
        obj = Instance::Cast(obj).CheckAndCanonicalize(NULL);
        ASSERT(!obj.IsNull());
        this->SetAt(i, obj);
      } else {
        ASSERT(error_str != NULL);
        char* chars = OS::SCreate(Thread::Current()->zone(),
            "element at index %" Pd ": %s\n", i, obj.ToCString());
        *error_str = chars;
        return false;
      }
    }
  }
  return true;
}


RawImmutableArray* ImmutableArray::New(intptr_t len,
                                       Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->immutable_array_class() !=
         Class::null());
  return reinterpret_cast<RawImmutableArray*>(Array::New(kClassId, len, space));
}


void GrowableObjectArray::Add(const Object& value, Heap::Space space) const {
  ASSERT(!IsNull());
  if (Length() == Capacity()) {
    // TODO(Issue 2500): Need a better growth strategy.
    intptr_t new_capacity = (Capacity() == 0) ? 4 : Capacity() * 2;
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


bool GrowableObjectArray::CanonicalizeEquals(const Instance& other) const {
  // If both handles point to the same raw instance they are equal.
  if (this->raw() == other.raw()) {
    return true;
  }

  // Other instance must be non null and a GrowableObjectArray.
  if (!other.IsGrowableObjectArray() || other.IsNull()) {
    return false;
  }

  const GrowableObjectArray& other_arr = GrowableObjectArray::Cast(other);

  // The capacity and length of both objects must be equal.
  if (Capacity() != other_arr.Capacity() || Length() != other_arr.Length()) {
    return false;
  }

  // Both arrays must have the same type arguments.
  const TypeArguments& type_args = TypeArguments::Handle(GetTypeArguments());
  const TypeArguments& other_type_args = TypeArguments::Handle(
      other.GetTypeArguments());
  if (!type_args.Equals(other_type_args)) {
    return false;
  }

  // The data part in both arrays must be identical.
  const Array& contents = Array::Handle(data());
  const Array& other_contents = Array::Handle(other_arr.data());
  for (intptr_t i = 0; i < Length(); i++) {
    if (contents.At(i) != other_contents.At(i)) {
      return false;
    }
  }
  return true;
}


RawGrowableObjectArray* GrowableObjectArray::New(intptr_t capacity,
                                                 Heap::Space space) {
  const Array& data = Array::Handle(Array::New(capacity, space));
  return New(data, space);
}


RawGrowableObjectArray* GrowableObjectArray::New(const Array& array,
                                                 Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->growable_object_array_class()
         != Class::null());
  GrowableObjectArray& result = GrowableObjectArray::Handle();
  {
    RawObject* raw = Object::Allocate(GrowableObjectArray::kClassId,
                                      GrowableObjectArray::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(0);
    result.SetData(array);
  }
  return result.raw();
}


const char* GrowableObjectArray::ToCString() const {
  if (IsNull()) {
    return "_GrowableList NULL";
  }
  return OS::SCreate(Thread::Current()->zone(),
      "Instance(length:%" Pd ") of '_GrowableList'", Length());
}


void GrowableObjectArray::PrintJSONImpl(JSONStream* stream,
                                        bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "List");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  {
    JSONArray jsarr(&jsobj, "elements");
    Object& element = Object::Handle();
    for (intptr_t index = 0; index < Length(); index++) {
      element = At(index);
      jsarr.AddValue(element);
    }
  }
}


// Equivalent to Dart's operator "==" and hashCode.
class DefaultHashTraits {
 public:
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
    Isolate* isolate = Isolate::Current();
    REUSABLE_INSTANCE_HANDLESCOPE(isolate);
    Instance& hash_code = isolate->InstanceHandle();
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
typedef EnumIndexHashMap<DefaultHashTraits> EnumIndexDefaultMap;


RawLinkedHashMap* LinkedHashMap::NewDefault(Heap::Space space) {
  const Array& data = Array::Handle(Array::New(kInitialIndexSize, space));
  const TypedData& index = TypedData::Handle(TypedData::New(
      kTypedDataUint32ArrayCid, kInitialIndexSize, space));
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
  ASSERT(Isolate::Current()->object_store()->linked_hash_map_class()
         != Class::null());
  LinkedHashMap& result = LinkedHashMap::Handle(
      LinkedHashMap::NewUninitialized(space));
  result.SetData(data);
  result.SetIndex(index);
  result.SetHashMask(hash_mask);
  result.SetUsedData(used_data);
  result.SetDeletedKeys(deleted_keys);
  return result.raw();
}


RawLinkedHashMap* LinkedHashMap::NewUninitialized(Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->linked_hash_map_class()
         != Class::null());
  LinkedHashMap& result = LinkedHashMap::Handle();
  {
    RawObject* raw = Object::Allocate(LinkedHashMap::kClassId,
                                      LinkedHashMap::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  return result.raw();
}


const char* LinkedHashMap::ToCString() const {
  Zone* zone = Thread::Current()->zone();
  return zone->PrintToString("_LinkedHashMap len:%" Pd, Length());
}


void LinkedHashMap::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Map");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }
  {
    JSONArray jsarr(&jsobj, "associations");
    Object& object = Object::Handle();
    LinkedHashMap::Iterator iterator(*this);
    while (iterator.MoveNext()) {
      JSONObject jsassoc(&jsarr);
      object = iterator.CurrentKey();
      jsassoc.AddProperty("key", object);
      object = iterator.CurrentValue();
      jsassoc.AddProperty("value", object);
    }
  }
}


RawFloat32x4* Float32x4::New(float v0, float v1, float v2, float v3,
                             Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float32x4_class() !=
         Class::null());
  Float32x4& result = Float32x4::Handle();
  {
    RawObject* raw = Object::Allocate(Float32x4::kClassId,
                                      Float32x4::InstanceSize(),
                                      space);
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
    RawObject* raw = Object::Allocate(Float32x4::kClassId,
                                      Float32x4::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_value(value);
  return result.raw();
}


simd128_value_t Float32x4::value() const {
  return simd128_value_t().readFrom(&raw_ptr()->value_[0]);
}


void Float32x4::set_value(simd128_value_t value) const {
  StoreSimd128(&raw_ptr()->value_[0], value);
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
  return OS::SCreate(Thread::Current()->zone(),
      "[%f, %f, %f, %f]", _x, _y, _z, _w);
}


void Float32x4::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Float32x4");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}


RawInt32x4* Int32x4::New(int32_t v0, int32_t v1, int32_t v2, int32_t v3,
                         Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->int32x4_class() !=
         Class::null());
  Int32x4& result = Int32x4::Handle();
  {
    RawObject* raw = Object::Allocate(Int32x4::kClassId,
                                      Int32x4::InstanceSize(),
                                      space);
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
  ASSERT(Isolate::Current()->object_store()->int32x4_class() !=
         Class::null());
  Int32x4& result = Int32x4::Handle();
  {
    RawObject* raw = Object::Allocate(Int32x4::kClassId,
                                      Int32x4::InstanceSize(),
                                      space);
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
  return simd128_value_t().readFrom(&raw_ptr()->value_[0]);
}


void Int32x4::set_value(simd128_value_t value) const {
  StoreSimd128(&raw_ptr()->value_[0], value);
}


const char* Int32x4::ToCString() const {
  int32_t _x = x();
  int32_t _y = y();
  int32_t _z = z();
  int32_t _w = w();
  return OS::SCreate(Thread::Current()->zone(),
      "[%08x, %08x, %08x, %08x]", _x, _y, _z, _w);
}


void Int32x4::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Int32x4");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
}


RawFloat64x2* Float64x2::New(double value0, double value1, Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->float64x2_class() !=
         Class::null());
  Float64x2& result = Float64x2::Handle();
  {
    RawObject* raw = Object::Allocate(Float64x2::kClassId,
                                      Float64x2::InstanceSize(),
                                      space);
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
    RawObject* raw = Object::Allocate(Float64x2::kClassId,
                                      Float64x2::InstanceSize(),
                                      space);
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


void Float64x2::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "Float64x2");
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("valueAsString", ToCString());
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


RawTypedData* TypedData::New(intptr_t class_id,
                             intptr_t len,
                             Heap::Space space) {
  if (len < 0 || len > TypedData::MaxElements(class_id)) {
    FATAL1("Fatal error in TypedData::New: invalid len %" Pd "\n", len);
  }
  TypedData& result = TypedData::Handle();
  {
    const intptr_t lengthInBytes = len * ElementSizeInBytes(class_id);
    RawObject* raw = Object::Allocate(class_id,
                                      TypedData::InstanceSize(lengthInBytes),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.SetLength(len);
    if (len > 0) {
      memset(result.DataAddr(0), 0, lengthInBytes);
    }
  }
  return result.raw();
}


RawTypedData* TypedData::EmptyUint32Array(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ASSERT(isolate->object_store() != NULL);
  if (isolate->object_store()->empty_uint32_array() != TypedData::null()) {
    // Already created.
    return isolate->object_store()->empty_uint32_array();
  }
  const TypedData& array = TypedData::Handle(isolate,
      TypedData::New(kTypedDataUint32ArrayCid, 0, Heap::kOld));
  isolate->object_store()->set_empty_uint32_array(array);
  return array.raw();
}


const char* TypedData::ToCString() const {
  return "TypedData";
}


void TypedData::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  const Class& cls = Class::Handle(clazz());
  const String& kind = String::Handle(cls.UserVisibleName());
  jsobj.AddProperty("kind", kind.ToCString());
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }

  {
    NoSafepointScope no_safepoint;
    jsobj.AddPropertyBase64("bytes",
                            reinterpret_cast<const uint8_t*>(DataAddr(0)),
                            LengthInBytes());
  }
}


FinalizablePersistentHandle* ExternalTypedData::AddFinalizer(
    void* peer, Dart_WeakPersistentHandleFinalizer callback) const {
  return dart::AddFinalizer(*this, peer, callback);
}


RawExternalTypedData* ExternalTypedData::New(intptr_t class_id,
                                             uint8_t* data,
                                             intptr_t len,
                                             Heap::Space space) {
  ExternalTypedData& result = ExternalTypedData::Handle();
  {
    RawObject* raw = Object::Allocate(class_id,
                                      ExternalTypedData::InstanceSize(),
                                      space);
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


void ExternalTypedData::PrintJSONImpl(JSONStream* stream,
                                      bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  const Class& cls = Class::Handle(clazz());
  const String& kind = String::Handle(cls.UserVisibleName());
  jsobj.AddProperty("kind", kind.ToCString());
  jsobj.AddServiceId(*this);
  jsobj.AddProperty("length", Length());
  if (ref) {
    return;
  }

  {
    NoSafepointScope no_safepoint;
    jsobj.AddPropertyBase64("bytes",
                            reinterpret_cast<const uint8_t*>(DataAddr(0)),
                            LengthInBytes());
  }
}


RawCapability* Capability::New(uint64_t id, Heap::Space space) {
  Capability& result = Capability::Handle();
  {
    RawObject* raw = Object::Allocate(Capability::kClassId,
                                      Capability::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.StoreNonPointer(&result.raw_ptr()->id_, id);
  }
  return result.raw();
}


const char* Capability::ToCString() const {
  return "Capability";
}


void Capability::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}


RawReceivePort* ReceivePort::New(Dart_Port id,
                                 bool is_control_port,
                                 Heap::Space space) {
  ASSERT(id != ILLEGAL_PORT);
  Isolate* isolate = Isolate::Current();
  const SendPort& send_port =
      SendPort::Handle(isolate, SendPort::New(id, isolate->origin_id()));

  ReceivePort& result = ReceivePort::Handle(isolate);
  {
    RawObject* raw = Object::Allocate(ReceivePort::kClassId,
                                      ReceivePort::InstanceSize(),
                                      space);
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


void ReceivePort::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
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
    RawObject* raw = Object::Allocate(SendPort::kClassId,
                                      SendPort::InstanceSize(),
                                      space);
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


void SendPort::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}


const char* Closure::ToCString(const Instance& closure) {
  const Function& fun = Function::Handle(Closure::function(closure));
  const bool is_implicit_closure = fun.IsImplicitClosureFunction();
  const char* fun_sig = String::Handle(fun.UserVisibleSignature()).ToCString();
  const char* from = is_implicit_closure ? " from " : "";
  const char* fun_desc = is_implicit_closure ? fun.ToCString() : "";
  return OS::SCreate(Thread::Current()->zone(),
      "Closure: %s%s%s", fun_sig, from, fun_desc);
}


RawInstance* Closure::New(const Function& function,
                          const Context& context,
                          Heap::Space space) {
  const Class& cls = Class::Handle(function.signature_class());
  ASSERT(cls.instance_size() == Closure::InstanceSize());
  Instance& result = Instance::Handle();
  {
    RawObject* raw = Object::Allocate(cls.id(), Closure::InstanceSize(), space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  Closure::set_function(result, function);
  Closure::set_context(result, context);
  return result.raw();
}


intptr_t Stacktrace::Length() const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array_);
  return code_array.Length();
}


RawFunction* Stacktrace::FunctionAtFrame(intptr_t frame_index) const {
  const Code& code = Code::Handle(CodeAtFrame(frame_index));
  return code.IsNull() ? Function::null() : code.function();
}


RawCode* Stacktrace::CodeAtFrame(intptr_t frame_index) const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array_);
  return reinterpret_cast<RawCode*>(code_array.At(frame_index));
}


void Stacktrace::SetCodeAtFrame(intptr_t frame_index,
                                const Code& code) const {
  const Array& code_array = Array::Handle(raw_ptr()->code_array_);
  code_array.SetAt(frame_index, code);
}


RawSmi* Stacktrace::PcOffsetAtFrame(intptr_t frame_index) const {
  const Array& pc_offset_array = Array::Handle(raw_ptr()->pc_offset_array_);
  return reinterpret_cast<RawSmi*>(pc_offset_array.At(frame_index));
}


void Stacktrace::SetPcOffsetAtFrame(intptr_t frame_index,
                                    const Smi& pc_offset) const {
  const Array& pc_offset_array = Array::Handle(raw_ptr()->pc_offset_array_);
  pc_offset_array.SetAt(frame_index, pc_offset);
}


void Stacktrace::set_code_array(const Array& code_array) const {
  StorePointer(&raw_ptr()->code_array_, code_array.raw());
}


void Stacktrace::set_pc_offset_array(const Array& pc_offset_array) const {
  StorePointer(&raw_ptr()->pc_offset_array_, pc_offset_array.raw());
}


void Stacktrace::set_expand_inlined(bool value) const {
  StoreNonPointer(&raw_ptr()->expand_inlined_, value);
}


bool Stacktrace::expand_inlined() const {
  return raw_ptr()->expand_inlined_;
}


RawStacktrace* Stacktrace::New(const Array& code_array,
                               const Array& pc_offset_array,
                               Heap::Space space) {
  Stacktrace& result = Stacktrace::Handle();
  {
    RawObject* raw = Object::Allocate(Stacktrace::kClassId,
                                      Stacktrace::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_code_array(code_array);
  result.set_pc_offset_array(pc_offset_array);
  result.set_expand_inlined(true);  // default.
  return result.raw();
}


const char* Stacktrace::ToCString() const {
  intptr_t idx = 0;
  return ToCStringInternal(&idx);
}


void Stacktrace::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "StackTrace");
  jsobj.AddServiceId(*this);
  intptr_t idx = 0;
  jsobj.AddProperty("valueAsString", ToCStringInternal(&idx));
}


static intptr_t PrintOneStacktrace(Zone* zone,
                                   GrowableArray<char*>* frame_strings,
                                   uword pc,
                                   const Function& function,
                                   const Code& code,
                                   intptr_t frame_index) {
  const intptr_t token_pos = code.GetTokenIndexOfPC(pc);
  const Script& script = Script::Handle(zone, function.script());
  const String& function_name =
      String::Handle(zone, function.QualifiedUserVisibleName());
  const String& url = String::Handle(zone, script.url());
  intptr_t line = -1;
  intptr_t column = -1;
  if (token_pos > 0) {
    if (script.HasSource()) {
      script.GetTokenLocation(token_pos, &line, &column);
    } else {
      script.GetTokenLocation(token_pos, &line, NULL);
    }
  }
  char* chars = NULL;
  if (column >= 0) {
    chars = OS::SCreate(zone,
        "#%-6" Pd " %s (%s:%" Pd ":%" Pd ")\n",
        frame_index, function_name.ToCString(), url.ToCString(), line, column);
  } else if (line >= 0) {
    chars = OS::SCreate(zone,
        "#%-6" Pd " %s (%s:%" Pd ")\n",
        frame_index, function_name.ToCString(), url.ToCString(), line);
  } else {
    chars = OS::SCreate(zone,
        "#%-6" Pd " %s (%s)\n",
        frame_index, function_name.ToCString(), url.ToCString());
  }
  frame_strings->Add(chars);
  return strlen(chars);
}


const char* Stacktrace::ToCStringInternal(intptr_t* frame_index,
                                          intptr_t max_frames) const {
  Zone* zone = Thread::Current()->zone();
  Function& function = Function::Handle();
  Code& code = Code::Handle();
  // Iterate through the stack frames and create C string description
  // for each frame.
  intptr_t total_len = 0;
  GrowableArray<char*> frame_strings;
  for (intptr_t i = 0; (i < Length()) && (*frame_index < max_frames); i++) {
    function = FunctionAtFrame(i);
    if (function.IsNull()) {
      // Check if null function object indicates a stack trace overflow.
      if ((i < (Length() - 1)) &&
          (FunctionAtFrame(i + 1) != Function::null())) {
        const char* kTruncated = "...\n...\n";
        intptr_t truncated_len = strlen(kTruncated) + 1;
        char* chars = zone->Alloc<char>(truncated_len);
        OS::SNPrint(chars, truncated_len, "%s", kTruncated);
        frame_strings.Add(chars);
        total_len += truncated_len;
      }
    } else if (function.is_visible() || FLAG_show_invisible_frames) {
      code = CodeAtFrame(i);
      ASSERT(function.raw() == code.function());
      uword pc = code.EntryPoint() + Smi::Value(PcOffsetAtFrame(i));
      if (code.is_optimized() && expand_inlined()) {
        // Traverse inlined frames.
        for (InlinedFunctionsIterator it(code, pc);
             !it.Done() && (*frame_index < max_frames); it.Advance()) {
          function = it.function();
          if (function.is_visible() || FLAG_show_invisible_frames) {
            code = it.code();
            ASSERT(function.raw() == code.function());
            uword pc = it.pc();
            ASSERT(pc != 0);
            ASSERT(code.EntryPoint() <= pc);
            ASSERT(pc < (code.EntryPoint() + code.Size()));
            total_len += PrintOneStacktrace(
                zone, &frame_strings, pc, function, code, *frame_index);
            (*frame_index)++;  // To account for inlined frames.
          }
        }
      } else {
        total_len += PrintOneStacktrace(
            zone, &frame_strings, pc, function, code, *frame_index);
        (*frame_index)++;
      }
    }
  }

  // Now concatenate the frame descriptions into a single C string.
  char* chars = zone->Alloc<char>(total_len + 1);
  intptr_t index = 0;
  for (intptr_t i = 0; i < frame_strings.length(); i++) {
    index += OS::SNPrint((chars + index),
                         (total_len + 1 - index),
                         "%s",
                         frame_strings[i]);
  }
  chars[total_len] = '\0';
  return chars;
}


void JSRegExp::set_pattern(const String& pattern) const {
  StorePointer(&raw_ptr()->pattern_, pattern.raw());
}


void JSRegExp::set_function(intptr_t cid, const Function& value) const {
  StorePointer(FunctionAddr(cid), value.raw());
}


void JSRegExp::set_bytecode(bool is_one_byte, const TypedData& bytecode) const {
  if (is_one_byte) {
    StorePointer(&raw_ptr()->one_byte_bytecode_, bytecode.raw());
  } else {
    StorePointer(&raw_ptr()->two_byte_bytecode_, bytecode.raw());
  }
}


void JSRegExp::set_num_bracket_expressions(intptr_t value) const {
  StoreSmi(&raw_ptr()->num_bracket_expressions_, Smi::New(value));
}


RawJSRegExp* JSRegExp::New(Heap::Space space) {
  JSRegExp& result = JSRegExp::Handle();
  {
    RawObject* raw = Object::Allocate(JSRegExp::kClassId,
                                      JSRegExp::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
    result.set_type(kUnitialized);
    result.set_flags(0);
    result.set_num_registers(-1);
  }
  return result.raw();
}


void* JSRegExp::GetDataStartAddress() const {
  intptr_t addr = reinterpret_cast<intptr_t>(raw_ptr());
  return reinterpret_cast<void*>(addr + sizeof(RawJSRegExp));
}


RawJSRegExp* JSRegExp::FromDataStartAddress(void* data) {
  JSRegExp& regexp = JSRegExp::Handle();
  intptr_t addr = reinterpret_cast<intptr_t>(data) - sizeof(RawJSRegExp);
  regexp ^= RawObject::FromAddr(addr);
  return regexp.raw();
}


const char* JSRegExp::Flags() const {
  switch (flags()) {
    case kGlobal | kIgnoreCase | kMultiLine :
    case kIgnoreCase | kMultiLine :
      return "im";
    case kGlobal | kIgnoreCase :
    case kIgnoreCase:
      return "i";
    case kGlobal | kMultiLine :
    case kMultiLine:
      return "m";
    default:
      break;
  }
  return "";
}


bool JSRegExp::CanonicalizeEquals(const Instance& other) const {
  if (this->raw() == other.raw()) {
    return true;  // "===".
  }
  if (other.IsNull() || !other.IsJSRegExp()) {
    return false;
  }
  const JSRegExp& other_js = JSRegExp::Cast(other);
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


const char* JSRegExp::ToCString() const {
  const String& str = String::Handle(pattern());
  return OS::SCreate(Thread::Current()->zone(),
      "JSRegExp: pattern=%s flags=%s", str.ToCString(), Flags());
}


void JSRegExp::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "RegExp");
  jsobj.AddServiceId(*this);

  jsobj.AddProperty("pattern", String::Handle(pattern()));

  if (ref) {
    return;
  }

  jsobj.AddProperty("isCaseSensitive", !is_ignore_case());
  jsobj.AddProperty("isMultiLine", is_multi_line());

  Function& func = Function::Handle();
  func = function(kOneByteStringCid);
  jsobj.AddProperty("_oneByteFunction", func);
  func = function(kTwoByteStringCid);
  jsobj.AddProperty("_twoByteFunction", func);
  func = function(kExternalOneByteStringCid);
  jsobj.AddProperty("_externalOneByteFunction", func);
  func = function(kExternalTwoByteStringCid);
  jsobj.AddProperty("_externalTwoByteFunction", func);
}


RawWeakProperty* WeakProperty::New(Heap::Space space) {
  ASSERT(Isolate::Current()->object_store()->weak_property_class()
         != Class::null());
  RawObject* raw = Object::Allocate(WeakProperty::kClassId,
                                    WeakProperty::InstanceSize(),
                                    space);
  return reinterpret_cast<RawWeakProperty*>(raw);
}


const char* WeakProperty::ToCString() const {
  return "_WeakProperty";
}


void WeakProperty::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "WeakProperty");
  jsobj.AddServiceId(*this);
  if (ref) {
    return;
  }

  const Object& key_handle = Object::Handle(key());
  jsobj.AddProperty("propertyKey", key_handle);
  const Object& value_handle = Object::Handle(value());
  jsobj.AddProperty("propertyValue", value_handle);
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
                                      MirrorReference::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_referent(referent);
  return result.raw();
}


const char* MirrorReference::ToCString() const {
  return "_MirrorReference";
}


void MirrorReference::PrintJSONImpl(JSONStream* stream, bool ref) const {
  JSONObject jsobj(stream);
  PrintSharedInstanceJSON(&jsobj, ref);
  jsobj.AddProperty("kind", "MirrorReference");
  jsobj.AddServiceId(*this);

  if (ref) {
    return;
  }

  const Object& referent_handle = Object::Handle(referent());
  jsobj.AddProperty("mirrorReferent", referent_handle);
}


void UserTag::MakeActive() const {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  isolate->set_current_tag(*this);
}


RawUserTag* UserTag::New(const String& label, Heap::Space space) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  // Canonicalize by name.
  UserTag& result = UserTag::Handle(FindTagInIsolate(isolate, label));
  if (!result.IsNull()) {
    // Tag already exists, return existing instance.
    return result.raw();
  }
  if (TagTableIsFull(isolate)) {
    const String& error = String::Handle(
        String::NewFormatted("UserTag instance limit (%" Pd ") reached.",
                             UserTags::kMaxUserTags));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, error);
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
  }
  // No tag with label exists, create and register with isolate tag table.
  {
    RawObject* raw = Object::Allocate(UserTag::kClassId,
                                      UserTag::InstanceSize(),
                                      space);
    NoSafepointScope no_safepoint;
    result ^= raw;
  }
  result.set_label(label);
  AddTagToIsolate(isolate, result);
  return result.raw();
}


RawUserTag* UserTag::DefaultTag() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  if (isolate->default_tag() != UserTag::null()) {
    // Already created.
    return isolate->default_tag();
  }
  // Create default tag.
  const UserTag& result = UserTag::Handle(isolate,
                                          UserTag::New(Symbols::Default()));
  ASSERT(result.tag() == UserTags::kDefaultUserTag);
  isolate->set_default_tag(result);
  return result.raw();
}


RawUserTag* UserTag::FindTagInIsolate(Isolate* isolate, const String& label) {
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table = GrowableObjectArray::Handle(
      isolate, isolate->tag_table());
  UserTag& other = UserTag::Handle(isolate);
  String& tag_label = String::Handle(isolate);
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


void UserTag::AddTagToIsolate(Isolate* isolate, const UserTag& tag) {
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table = GrowableObjectArray::Handle(
      isolate, isolate->tag_table());
  ASSERT(!TagTableIsFull(isolate));
#if defined(DEBUG)
  // Verify that no existing tag has the same tag id.
  UserTag& other = UserTag::Handle(isolate);
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


bool UserTag::TagTableIsFull(Isolate* isolate) {
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table = GrowableObjectArray::Handle(
      isolate, isolate->tag_table());
  ASSERT(tag_table.Length() <= UserTags::kMaxUserTags);
  return tag_table.Length() == UserTags::kMaxUserTags;
}


RawUserTag* UserTag::FindTagById(uword tag_id) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate->tag_table() != GrowableObjectArray::null());
  const GrowableObjectArray& tag_table = GrowableObjectArray::Handle(
      isolate, isolate->tag_table());
  UserTag& tag = UserTag::Handle(isolate);
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


void UserTag::PrintJSONImpl(JSONStream* stream, bool ref) const {
  Instance::PrintJSONImpl(stream, ref);
}


}  // namespace dart
