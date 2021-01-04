// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compilation_trace.h"

#include "vm/compiler/jit/compiler.h"
#include "vm/globals.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/symbols.h"
#include "vm/version.h"

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)

DEFINE_FLAG(bool, trace_compilation_trace, false, "Trace compilation trace.");

CompilationTraceSaver::CompilationTraceSaver(Zone* zone)
    : buf_(zone, 1 * MB),
      func_name_(String::Handle(zone)),
      cls_(Class::Handle(zone)),
      cls_name_(String::Handle(zone)),
      lib_(Library::Handle(zone)),
      uri_(String::Handle(zone)) {}

void CompilationTraceSaver::VisitFunction(const Function& function) {
  if (!function.HasCode()) {
    return;  // Not compiled.
  }
  if (function.parent_function() != Function::null()) {
    // Lookup works poorly for local functions. We compile all local functions
    // in a compiled function instead.
    return;
  }

  func_name_ = function.name();
  func_name_ = String::RemovePrivateKey(func_name_);
  cls_ = function.Owner();
  cls_name_ = cls_.Name();
  cls_name_ = String::RemovePrivateKey(cls_name_);
  lib_ = cls_.library();
  uri_ = lib_.url();
  buf_.Printf("%s,%s,%s\n", uri_.ToCString(), cls_name_.ToCString(),
              func_name_.ToCString());
}

CompilationTraceLoader::CompilationTraceLoader(Thread* thread)
    : thread_(thread),
      zone_(thread->zone()),
      uri_(String::Handle(zone_)),
      class_name_(String::Handle(zone_)),
      function_name_(String::Handle(zone_)),
      function_name2_(String::Handle(zone_)),
      lib_(Library::Handle(zone_)),
      cls_(Class::Handle(zone_)),
      function_(Function::Handle(zone_)),
      function2_(Function::Handle(zone_)),
      field_(Field::Handle(zone_)),
      sites_(Array::Handle(zone_)),
      site_(ICData::Handle(zone_)),
      static_type_(AbstractType::Handle(zone_)),
      receiver_cls_(Class::Handle(zone_)),
      target_(Function::Handle(zone_)),
      selector_(String::Handle(zone_)),
      args_desc_(Array::Handle(zone_)),
      error_(Object::Handle(zone_)) {}

static char* FindCharacter(char* str, char goal, char* limit) {
  while (str < limit) {
    if (*str == goal) {
      return str;
    }
    str++;
  }
  return NULL;
}

ObjectPtr CompilationTraceLoader::CompileTrace(uint8_t* buffer, intptr_t size) {
  // First compile functions named in the trace.
  char* cursor = reinterpret_cast<char*>(buffer);
  char* limit = cursor + size;
  while (cursor < limit) {
    char* uri = cursor;
    char* comma1 = FindCharacter(uri, ',', limit);
    if (comma1 == NULL) {
      break;
    }
    *comma1 = 0;
    char* cls_name = comma1 + 1;
    char* comma2 = FindCharacter(cls_name, ',', limit);
    if (comma2 == NULL) {
      break;
    }
    *comma2 = 0;
    char* func_name = comma2 + 1;
    char* newline = FindCharacter(func_name, '\n', limit);
    if (newline == NULL) {
      break;
    }
    *newline = 0;
    error_ = CompileTriple(uri, cls_name, func_name);
    if (error_.IsError()) {
      return error_.raw();
    }
    cursor = newline + 1;
  }

  // Next, compile common dispatchers. These aren't found with the normal
  // lookup above because they have irregular lookup that depends on the
  // arguments descriptor (e.g. call() versus call(x)).
  const Class& closure_class =
      Class::Handle(zone_, thread_->isolate()->object_store()->closure_class());
  Array& arguments_descriptor = Array::Handle(zone_);
  Function& dispatcher = Function::Handle(zone_);
  for (intptr_t argc = 1; argc <= 4; argc++) {
    const intptr_t kTypeArgsLen = 0;

    // TODO(dartbug.com/33549): Update this code to use the size of the
    // parameters when supporting calls to closures with unboxed parameters.
    arguments_descriptor = ArgumentsDescriptor::NewBoxed(kTypeArgsLen, argc);
    dispatcher = closure_class.GetInvocationDispatcher(
        Symbols::Call(), arguments_descriptor,
        FunctionLayout::kInvokeFieldDispatcher, true /* create_if_absent */);
    error_ = CompileFunction(dispatcher);
    if (error_.IsError()) {
      return error_.raw();
    }
  }

  // Finally, compile closures in all compiled functions. Don't cache the
  // length since compiling may append to this list.
  const GrowableObjectArray& closure_functions = GrowableObjectArray::Handle(
      zone_, thread_->isolate()->object_store()->closure_functions());
  for (intptr_t i = 0; i < closure_functions.Length(); i++) {
    function_ ^= closure_functions.At(i);
    function2_ = function_.parent_function();
    if (function2_.HasCode()) {
      error_ = CompileFunction(function_);
      if (error_.IsError()) {
        return error_.raw();
      }
    }
  }

  return Object::null();
}

// Use a fuzzy match to find the right function to compile. This allows a
// compilation trace to remain mostly valid in the face of program changes, and
// deals with implicit/dispatcher functions that don't have proper names.
//  - Ignore private name mangling
//  - If looking for a getter and we only have the corresponding regular method,
//    compile the regular method, create its implicit closure and compile that.
//  - If looking for a regular method and we only have the corresponding getter,
//    compile the getter, create its method extractor and compile that.
//  - If looking for a getter and we only have a const field, evaluate the const
//    field.
ObjectPtr CompilationTraceLoader::CompileTriple(const char* uri_cstr,
                                                const char* cls_cstr,
                                                const char* func_cstr) {
  uri_ = Symbols::New(thread_, uri_cstr);
  class_name_ = Symbols::New(thread_, cls_cstr);
  function_name_ = Symbols::New(thread_, func_cstr);

  if (function_name_.Equals("_getMainClosure")) {
    // The scheme for invoking main relies on compiling _getMainClosure after
    // synthetically importing the root library.
    if (FLAG_trace_compilation_trace) {
      THR_Print("Compilation trace: skip %s,%s,%s\n", uri_.ToCString(),
                class_name_.ToCString(), function_name_.ToCString());
    }
    return Object::null();
  }

  lib_ = Library::LookupLibrary(thread_, uri_);
  if (lib_.IsNull()) {
    // Missing library.
    if (FLAG_trace_compilation_trace) {
      THR_Print("Compilation trace: missing library %s,%s,%s\n",
                uri_.ToCString(), class_name_.ToCString(),
                function_name_.ToCString());
    }
    return Object::null();
  }

  bool is_dyn = Function::IsDynamicInvocationForwarderName(function_name_);
  if (is_dyn) {
    function_name_ =
        Function::DemangleDynamicInvocationForwarderName(function_name_);
  }

  bool is_getter = Field::IsGetterName(function_name_);
  bool is_init = Field::IsInitName(function_name_);
  bool add_closure = false;
  bool processed = false;

  if (class_name_.Equals(Symbols::TopLevel())) {
    function_ = lib_.LookupFunctionAllowPrivate(function_name_);
    field_ = lib_.LookupFieldAllowPrivate(function_name_);
    if (function_.IsNull() && is_getter) {
      // Maybe this was a tear off.
      add_closure = true;
      function_name2_ = Field::NameFromGetter(function_name_);
      function_ = lib_.LookupFunctionAllowPrivate(function_name2_);
      field_ = lib_.LookupFieldAllowPrivate(function_name2_);
    }
    if (field_.IsNull() && is_getter) {
      function_name2_ = Field::NameFromGetter(function_name_);
      field_ = lib_.LookupFieldAllowPrivate(function_name2_);
    }
    if (field_.IsNull() && is_init) {
      function_name2_ = Field::NameFromInit(function_name_);
      field_ = lib_.LookupFieldAllowPrivate(function_name2_);
    }
  } else {
    cls_ = lib_.SlowLookupClassAllowMultiPartPrivate(class_name_);
    if (cls_.IsNull()) {
      // Missing class.
      if (FLAG_trace_compilation_trace) {
        THR_Print("Compilation trace: missing class %s,%s,%s\n",
                  uri_.ToCString(), class_name_.ToCString(),
                  function_name_.ToCString());
      }
      return Object::null();
    }

    error_ = cls_.EnsureIsFinalized(thread_);
    if (error_.IsError()) {
      // Non-finalized class.
      if (FLAG_trace_compilation_trace) {
        THR_Print("Compilation trace: non-finalized class %s,%s,%s (%s)\n",
                  uri_.ToCString(), class_name_.ToCString(),
                  function_name_.ToCString(),
                  Error::Cast(error_).ToErrorCString());
      }
      return error_.raw();
    }

    function_ = cls_.LookupFunctionAllowPrivate(function_name_);
    field_ = cls_.LookupFieldAllowPrivate(function_name_);
    if (function_.IsNull() && is_getter) {
      // Maybe this was a tear off.
      add_closure = true;
      function_name2_ = Field::NameFromGetter(function_name_);
      function_ = cls_.LookupFunctionAllowPrivate(function_name2_);
      field_ = cls_.LookupFieldAllowPrivate(function_name2_);
      if (!function_.IsNull() && !function_.is_static()) {
        // Maybe this was a method extractor.
        function2_ =
            Resolver::ResolveDynamicAnyArgs(zone_, cls_, function_name_);
        if (!function2_.IsNull()) {
          error_ = CompileFunction(function2_);
          if (error_.IsError()) {
            if (FLAG_trace_compilation_trace) {
              THR_Print(
                  "Compilation trace: error compiling extractor %s for "
                  "%s,%s,%s (%s)\n",
                  function2_.ToCString(), uri_.ToCString(),
                  class_name_.ToCString(), function_name_.ToCString(),
                  Error::Cast(error_).ToErrorCString());
            }
            return error_.raw();
          }
        }
      }
    }
    if (field_.IsNull() && is_getter) {
      function_name2_ = Field::NameFromGetter(function_name_);
      field_ = cls_.LookupFieldAllowPrivate(function_name2_);
    }
    if (field_.IsNull() && is_init) {
      function_name2_ = Field::NameFromInit(function_name_);
      field_ = cls_.LookupFieldAllowPrivate(function_name2_);
    }
  }

  if (!field_.IsNull() && field_.is_const() && field_.is_static() &&
      (field_.StaticValue() == Object::sentinel().raw())) {
    processed = true;
    error_ = field_.InitializeStatic();
    if (error_.IsError()) {
      if (FLAG_trace_compilation_trace) {
        THR_Print(
            "Compilation trace: error initializing field %s for %s,%s,%s "
            "(%s)\n",
            field_.ToCString(), uri_.ToCString(), class_name_.ToCString(),
            function_name_.ToCString(), Error::Cast(error_).ToErrorCString());
      }
      return error_.raw();
    }
  }

  if (!function_.IsNull()) {
    processed = true;
    error_ = CompileFunction(function_);
    if (error_.IsError()) {
      if (FLAG_trace_compilation_trace) {
        THR_Print("Compilation trace: error compiling %s,%s,%s (%s)\n",
                  uri_.ToCString(), class_name_.ToCString(),
                  function_name_.ToCString(),
                  Error::Cast(error_).ToErrorCString());
      }
      return error_.raw();
    }
    if (add_closure) {
      function_ = function_.ImplicitClosureFunction();
      error_ = CompileFunction(function_);
      if (error_.IsError()) {
        if (FLAG_trace_compilation_trace) {
          THR_Print(
              "Compilation trace: error compiling closure %s,%s,%s (%s)\n",
              uri_.ToCString(), class_name_.ToCString(),
              function_name_.ToCString(), Error::Cast(error_).ToErrorCString());
        }
        return error_.raw();
      }
    } else if (is_dyn) {
      function_name_ = function_.name();  // With private mangling.
      function_name_ =
          Function::CreateDynamicInvocationForwarderName(function_name_);
      function_ = function_.GetDynamicInvocationForwarder(function_name_);
      error_ = CompileFunction(function_);
      if (error_.IsError()) {
        if (FLAG_trace_compilation_trace) {
          THR_Print(
              "Compilation trace: error compiling dynamic forwarder %s,%s,%s "
              "(%s)\n",
              uri_.ToCString(), class_name_.ToCString(),
              function_name_.ToCString(), Error::Cast(error_).ToErrorCString());
        }
        return error_.raw();
      }
    }
  }

  if (!field_.IsNull() && field_.is_static() && !field_.is_const() &&
      field_.has_nontrivial_initializer()) {
    processed = true;
    function_ = field_.EnsureInitializerFunction();
    error_ = CompileFunction(function_);
    if (error_.IsError()) {
      if (FLAG_trace_compilation_trace) {
        THR_Print(
            "Compilation trace: error compiling initializer %s,%s,%s (%s)\n",
            uri_.ToCString(), class_name_.ToCString(),
            function_name_.ToCString(), Error::Cast(error_).ToErrorCString());
      }
      return error_.raw();
    }
  }

  if (FLAG_trace_compilation_trace) {
    if (!processed) {
      THR_Print("Compilation trace: ignored %s,%s,%s\n", uri_.ToCString(),
                class_name_.ToCString(), function_name_.ToCString());
    }
  }
  return Object::null();
}

ObjectPtr CompilationTraceLoader::CompileFunction(const Function& function) {
  if (function.is_abstract() || function.HasCode()) {
    return Object::null();
  }

  error_ = Compiler::CompileFunction(thread_, function);
  if (error_.IsError()) {
    return error_.raw();
  }

  SpeculateInstanceCallTargets(function);

  return error_.raw();
}

// For instance calls, if the receiver's static type has one concrete
// implementation, lookup the target for that implementation and add it
// to the ICData's entries.
// For some well-known interfaces, do the same for the most common concrete
// implementation (e.g., int -> _Smi).
void CompilationTraceLoader::SpeculateInstanceCallTargets(
    const Function& function) {
  sites_ = function.ic_data_array();
  if (sites_.IsNull()) {
    return;
  }
  for (intptr_t i = 1; i < sites_.Length(); i++) {
    site_ ^= sites_.At(i);
    if (site_.rebind_rule() != ICData::kInstance) {
      continue;
    }
    if (site_.NumArgsTested() != 1) {
      continue;
    }

    static_type_ = site_.receivers_static_type();
    if (static_type_.IsNull()) {
      continue;
    } else if (static_type_.IsDoubleType()) {
      receiver_cls_ = Isolate::Current()->class_table()->At(kDoubleCid);
    } else if (static_type_.IsIntType()) {
      receiver_cls_ = Isolate::Current()->class_table()->At(kSmiCid);
    } else if (static_type_.IsStringType()) {
      receiver_cls_ = Isolate::Current()->class_table()->At(kOneByteStringCid);
    } else if (static_type_.IsDartFunctionType() ||
               static_type_.IsDartClosureType()) {
      receiver_cls_ = Isolate::Current()->class_table()->At(kClosureCid);
    } else if (static_type_.HasTypeClass()) {
      receiver_cls_ = static_type_.type_class();
      if (receiver_cls_.is_implemented() || receiver_cls_.is_abstract()) {
        continue;
      }
    } else {
      continue;
    }

    selector_ = site_.target_name();
    args_desc_ = site_.arguments_descriptor();
    target_ = Resolver::ResolveDynamicForReceiverClass(
        receiver_cls_, selector_, ArgumentsDescriptor(args_desc_));
    if (!target_.IsNull() && !site_.HasReceiverClassId(receiver_cls_.id())) {
      intptr_t count = 0;  // Don't pollute type feedback and coverage data.
      site_.AddReceiverCheck(receiver_cls_.id(), target_, count);
    }
  }
}

TypeFeedbackSaver::TypeFeedbackSaver(BaseWriteStream* stream)
    : stream_(stream),
      cls_(Class::Handle()),
      lib_(Library::Handle()),
      str_(String::Handle()),
      fields_(Array::Handle()),
      field_(Field::Handle()),
      code_(Code::Handle()),
      call_sites_(Array::Handle()),
      call_site_(ICData::Handle()) {}

// These flags affect deopt ids.
static char* CompilerFlags() {
  TextBuffer buffer(64);

#define ADD_FLAG(flag) buffer.AddString(FLAG_##flag ? " " #flag : " no-" #flag)
  ADD_FLAG(enable_asserts);
  ADD_FLAG(use_field_guards);
  ADD_FLAG(use_osr);
  ADD_FLAG(fields_may_be_reset);
#undef ADD_FLAG

  return buffer.Steal();
}

void TypeFeedbackSaver::WriteHeader() {
  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  stream_->WriteBytes(reinterpret_cast<const uint8_t*>(expected_version),
                      version_len);

  char* expected_features = CompilerFlags();
  ASSERT(expected_features != NULL);
  const intptr_t features_len = strlen(expected_features);
  stream_->WriteBytes(reinterpret_cast<const uint8_t*>(expected_features),
                      features_len + 1);
  free(expected_features);
}

void TypeFeedbackSaver::SaveClasses() {
  ClassTable* table = Isolate::Current()->class_table();

  intptr_t num_cids = table->NumCids();
  WriteInt(num_cids);

  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    cls_ = table->At(cid);
    WriteClassByName(cls_);
  }
}

void TypeFeedbackSaver::SaveFields() {
  ClassTable* table = Isolate::Current()->class_table();
  intptr_t num_cids = table->NumCids();
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    cls_ = table->At(cid);
    WriteClassByName(cls_);

    fields_ = cls_.fields();
    WriteInt(fields_.Length());
    for (intptr_t i = 0; i < fields_.Length(); i++) {
      field_ ^= fields_.At(i);

      str_ = field_.name();
      str_ = String::RemovePrivateKey(str_);
      WriteString(str_);

      WriteInt(field_.guarded_cid());
      WriteInt(static_cast<intptr_t>(field_.is_nullable()));
    }
  }
}

void TypeFeedbackSaver::VisitFunction(const Function& function) {
  if (!function.HasCode()) {
    return;  // Not compiled.
  }

  cls_ = function.Owner();
  WriteClassByName(cls_);

  str_ = function.name();
  str_ = String::RemovePrivateKey(str_);
  WriteString(str_);

  WriteInt(function.kind());
  WriteInt(function.token_pos().Serialize());

  code_ = function.CurrentCode();
  intptr_t usage = function.usage_counter();
  if (usage < 0) {
    // Usage is set to INT32_MIN while in the background compilation queue ...
    usage = (usage - INT32_MIN) + FLAG_optimization_counter_threshold;
  } else if (code_.is_optimized()) {
    // ... and set to 0 when an optimizing compile completes.
    usage = usage + FLAG_optimization_counter_threshold;
  }
  WriteInt(usage);

  WriteInt(function.inlining_depth());

  call_sites_ = function.ic_data_array();
  if (call_sites_.IsNull()) {
    call_sites_ = Object::empty_array().raw();  // Remove edge case.
  }

  // First element is edge counters.
  WriteInt(call_sites_.Length() - 1);
  for (intptr_t i = 1; i < call_sites_.Length(); i++) {
    call_site_ ^= call_sites_.At(i);

    WriteInt(call_site_.deopt_id());
    WriteInt(call_site_.rebind_rule());

    str_ = call_site_.target_name();
    str_ = String::RemovePrivateKey(str_);
    WriteString(str_);

    intptr_t num_checked_arguments = call_site_.NumArgsTested();
    WriteInt(num_checked_arguments);

    intptr_t num_entries = call_site_.NumberOfChecks();
    WriteInt(num_entries);

    for (intptr_t entry_index = 0; entry_index < num_entries; entry_index++) {
      WriteInt(call_site_.GetCountAt(entry_index));

      for (intptr_t argument_index = 0; argument_index < num_checked_arguments;
           argument_index++) {
        WriteInt(call_site_.GetClassIdAt(entry_index, argument_index));
      }
    }
  }
}

void TypeFeedbackSaver::WriteClassByName(const Class& cls) {
  lib_ = cls.library();

  str_ = lib_.url();
  WriteString(str_);

  str_ = cls_.Name();
  str_ = String::RemovePrivateKey(str_);
  WriteString(str_);
}

void TypeFeedbackSaver::WriteString(const String& value) {
  const char* cstr = value.ToCString();
  intptr_t len = strlen(cstr);
  stream_->WriteUnsigned(len);
  stream_->WriteBytes(cstr, len);
}

TypeFeedbackLoader::TypeFeedbackLoader(Thread* thread)
    : thread_(thread),
      zone_(thread->zone()),
      stream_(nullptr),
      cid_map_(nullptr),
      uri_(String::Handle(zone_)),
      lib_(Library::Handle(zone_)),
      cls_name_(String::Handle(zone_)),
      cls_(Class::Handle(zone_)),
      field_name_(String::Handle(zone_)),
      fields_(Array::Handle(zone_)),
      field_(Field::Handle(zone_)),
      func_name_(String::Handle(zone_)),
      func_(Function::Handle(zone_)),
      call_sites_(Array::Handle(zone_)),
      call_site_(ICData::Handle(zone_)),
      target_name_(String::Handle(zone_)),
      target_(Function::Handle(zone_)),
      args_desc_(Array::Handle(zone_)),
      functions_to_compile_(
          GrowableObjectArray::Handle(zone_, GrowableObjectArray::New())),
      error_(Error::Handle(zone_)) {}

TypeFeedbackLoader::~TypeFeedbackLoader() {
  delete[] cid_map_;
}

ObjectPtr TypeFeedbackLoader::LoadFeedback(ReadStream* stream) {
  stream_ = stream;

  error_ = CheckHeader();
  if (error_.IsError()) {
    return error_.raw();
  }

  error_ = LoadClasses();
  if (error_.IsError()) {
    return error_.raw();
  }

  error_ = LoadFields();
  if (error_.IsError()) {
    return error_.raw();
  }

  while (stream_->PendingBytes() > 0) {
    error_ = LoadFunction();
    if (error_.IsError()) {
      return error_.raw();
    }
  }

  while (functions_to_compile_.Length() > 0) {
    func_ ^= functions_to_compile_.RemoveLast();

    if (Compiler::CanOptimizeFunction(thread_, func_) &&
        (func_.usage_counter() >= FLAG_optimization_counter_threshold)) {
      error_ = Compiler::CompileOptimizedFunction(thread_, func_);
      if (error_.IsError()) {
        return error_.raw();
      }
    }
  }

  if (FLAG_trace_compilation_trace) {
    THR_Print("Done loading feedback\n");
  }

  return Error::null();
}

ObjectPtr TypeFeedbackLoader::CheckHeader() {
  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  if (stream_->PendingBytes() < version_len) {
    const intptr_t kMessageBufferSize = 128;
    char message_buffer[kMessageBufferSize];
    Utils::SNPrint(message_buffer, kMessageBufferSize,
                   "No snapshot version found, expected '%s'",
                   expected_version);
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }

  const char* version =
      reinterpret_cast<const char*>(stream_->AddressOfCurrentPosition());
  ASSERT(version != NULL);
  if (strncmp(version, expected_version, version_len) != 0) {
    const intptr_t kMessageBufferSize = 256;
    char message_buffer[kMessageBufferSize];
    char* actual_version = Utils::StrNDup(version, version_len);
    Utils::SNPrint(message_buffer, kMessageBufferSize,
                   "Wrong snapshot version, expected '%s' found '%s'",
                   expected_version, actual_version);
    free(actual_version);
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }
  stream_->Advance(version_len);

  char* expected_features = CompilerFlags();
  ASSERT(expected_features != NULL);
  const intptr_t expected_len = strlen(expected_features);

  const char* features =
      reinterpret_cast<const char*>(stream_->AddressOfCurrentPosition());
  ASSERT(features != NULL);
  intptr_t buffer_len = Utils::StrNLen(features, stream_->PendingBytes());
  if ((buffer_len != expected_len) ||
      (strncmp(features, expected_features, expected_len) != 0)) {
    const String& msg = String::Handle(String::NewFormatted(
        Heap::kOld,
        "Feedback not compatible with the current VM configuration: "
        "the feedback requires '%.*s' but the VM has '%s'",
        static_cast<int>(buffer_len > 1024 ? 1024 : buffer_len), features,
        expected_features));
    free(expected_features);
    return ApiError::New(msg, Heap::kOld);
  }
  free(expected_features);
  stream_->Advance(expected_len + 1);
  return Error::null();
}

ObjectPtr TypeFeedbackLoader::LoadClasses() {
  num_cids_ = ReadInt();

  cid_map_ = new intptr_t[num_cids_];
  for (intptr_t cid = 0; cid < num_cids_; cid++) {
    cid_map_[cid] = kIllegalCid;
  }
  for (intptr_t cid = kInstanceCid; cid < kNumPredefinedCids; cid++) {
    cid_map_[cid] = cid;
  }

  for (intptr_t cid = kNumPredefinedCids; cid < num_cids_; cid++) {
    cls_ = ReadClassByName();
    if (!cls_.IsNull()) {
      cid_map_[cid] = cls_.id();
    }
  }

  return Error::null();
}

ObjectPtr TypeFeedbackLoader::LoadFields() {
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids_; cid++) {
    cls_ = ReadClassByName();
    bool skip = cls_.IsNull();

    intptr_t num_fields = ReadInt();
    if (!skip && (num_fields > 0)) {
      error_ = cls_.EnsureIsFinalized(thread_);
      if (error_.IsError()) {
        return error_.raw();
      }
      fields_ = cls_.fields();
    }

    SafepointWriteRwLocker ml(thread_,
                              thread_->isolate_group()->program_lock());
    for (intptr_t i = 0; i < num_fields; i++) {
      field_name_ = ReadString();
      intptr_t guarded_cid = cid_map_[ReadInt()];
      intptr_t is_nullable = ReadInt();

      if (skip) {
        continue;
      }

      if (i >= fields_.Length()) {
        if (FLAG_trace_compilation_trace) {
          THR_Print("Missing field %s\n", field_name_.ToCString());
        }
        continue;
      }

      field_ ^= fields_.At(i);
      if (!String::EqualsIgnoringPrivateKey(String::Handle(field_.name()),
                                            field_name_)) {
        if (FLAG_trace_compilation_trace) {
          THR_Print("Missing field %s\n", field_name_.ToCString());
        }
        continue;
      }

      if (guarded_cid == kIllegalCid) {
        // Guarded CID from feedback is not in current program: assume the field
        // will become polymorphic.
        field_.set_guarded_cid(kDynamicCid);
        field_.set_is_nullable(true);
      } else if ((field_.guarded_cid() != kIllegalCid) &&
                 (field_.guarded_cid() == guarded_cid)) {
        // Guarded CID from feedback is different from initialized guarded CID
        // in the current program: assume the field will become polymorphic.
        field_.set_guarded_cid(kDynamicCid);
        field_.set_is_nullable(true);
      } else {
        field_.set_guarded_cid(guarded_cid);
        field_.set_is_nullable((is_nullable != 0) || field_.is_nullable());
      }

      // TODO(rmacnak): Merge other field type feedback.
      field_.set_guarded_list_length(Field::kNoFixedLength);
      field_.set_guarded_list_length_in_object_offset(
          Field::kUnknownLengthOffset);
      field_.set_static_type_exactness_state(
          StaticTypeExactnessState::NotTracking());
      field_.DeoptimizeDependentCode();
    }
  }

  return Error::null();
}

ObjectPtr TypeFeedbackLoader::LoadFunction() {
  bool skip = false;

  cls_ = ReadClassByName();
  if (!cls_.IsNull()) {
    error_ = cls_.EnsureIsFinalized(thread_);
    if (error_.IsError()) {
      return error_.raw();
    }
  } else {
    skip = true;
  }

  func_name_ = ReadString();  // Without private mangling.
  FunctionLayout::Kind kind = static_cast<FunctionLayout::Kind>(ReadInt());
  const TokenPosition& token_pos = TokenPosition::Deserialize(ReadInt());
  intptr_t usage = ReadInt();
  intptr_t inlining_depth = ReadInt();
  intptr_t num_call_sites = ReadInt();

  if (!skip) {
    func_ = FindFunction(kind, token_pos);
    if (func_.IsNull()) {
      skip = true;
      if (FLAG_trace_compilation_trace) {
        THR_Print("Missing function %s %s\n", func_name_.ToCString(),
                  Function::KindToCString(kind));
      }
    }
  }

  if (!skip) {
    error_ = Compiler::CompileFunction(thread_, func_);
    if (error_.IsError()) {
      return error_.raw();
    }
    call_sites_ = func_.ic_data_array();
    if (call_sites_.IsNull()) {
      call_sites_ = Object::empty_array().raw();  // Remove edge case.
    }
    if (call_sites_.Length() != num_call_sites + 1) {
      skip = true;
      if (FLAG_trace_compilation_trace) {
        THR_Print("Mismatched call site count %s %" Pd " %" Pd "\n",
                  func_name_.ToCString(), call_sites_.Length(), num_call_sites);
      }
    }
  }

  // First element is edge counters.
  for (intptr_t i = 1; i <= num_call_sites; i++) {
    intptr_t deopt_id = ReadInt();
    intptr_t rebind_rule = ReadInt();
    target_name_ = ReadString();
    intptr_t num_checked_arguments = ReadInt();
    intptr_t num_entries = ReadInt();

    if (!skip) {
      call_site_ ^= call_sites_.At(i);
      if ((call_site_.deopt_id() != deopt_id) ||
          (call_site_.rebind_rule() != rebind_rule) ||
          (call_site_.NumArgsTested() != num_checked_arguments)) {
        skip = true;
        if (FLAG_trace_compilation_trace) {
          THR_Print("Mismatched call site %s\n", call_site_.ToCString());
        }
      }
    }

    for (intptr_t entry_index = 0; entry_index < num_entries; entry_index++) {
      intptr_t entry_usage = ReadInt();
      bool skip_entry = skip;
      GrowableArray<intptr_t> cids(num_checked_arguments);

      for (intptr_t argument_index = 0; argument_index < num_checked_arguments;
           argument_index++) {
        intptr_t cid = cid_map_[ReadInt()];
        cids.Add(cid);
        if (cid == kIllegalCid) {
          // Alternative: switch to a sentinel value such as kDynamicCid and
          // have the optimizer generate a megamorphic call.
          skip_entry = true;
        }
      }

      if (skip_entry) {
        continue;
      }

      intptr_t reuse_index = call_site_.FindCheck(cids);
      if (reuse_index == -1) {
        cls_ = thread_->isolate()->class_table()->At(cids[0]);
        // Use target name and args descriptor from the current program
        // instead of saved feedback to get the correct private mangling and
        // ensure no arity mismatch crashes.
        target_name_ = call_site_.target_name();
        args_desc_ = call_site_.arguments_descriptor();
        if (cls_.EnsureIsFinalized(thread_) == Error::null()) {
          target_ = Resolver::ResolveDynamicForReceiverClass(
              cls_, target_name_, ArgumentsDescriptor(args_desc_));
        }
        if (!target_.IsNull()) {
          if (num_checked_arguments == 1) {
            call_site_.AddReceiverCheck(cids[0], target_, entry_usage);
          } else {
            call_site_.AddCheck(cids, target_, entry_usage);
          }
        }
      } else {
        call_site_.IncrementCountAt(reuse_index, entry_usage);
      }
    }
  }

  if (!skip) {
    func_.set_usage_counter(usage);
    func_.set_inlining_depth(inlining_depth);

    // Delay compilation until all feedback is loaded so feedback is available
    // for inlined functions.
    functions_to_compile_.Add(func_);
  }

  return Error::null();
}

FunctionPtr TypeFeedbackLoader::FindFunction(FunctionLayout::Kind kind,
                                             const TokenPosition& token_pos) {
  if (cls_name_.Equals(Symbols::TopLevel())) {
    func_ = lib_.LookupFunctionAllowPrivate(func_name_);
  } else {
    func_ = cls_.LookupFunctionAllowPrivate(func_name_);
  }

  if (!func_.IsNull()) {
    // Found regular method.
  } else if (kind == FunctionLayout::kMethodExtractor) {
    ASSERT(Field::IsGetterName(func_name_));
    // Without private mangling:
    String& name = String::Handle(zone_, Field::NameFromGetter(func_name_));
    func_ = cls_.LookupFunctionAllowPrivate(name);
    if (!func_.IsNull() && func_.IsDynamicFunction()) {
      name = func_.name();  // With private mangling.
      name = Field::GetterName(name);
      func_ = func_.GetMethodExtractor(name);
    } else {
      func_ = Function::null();
    }
  } else if (kind == FunctionLayout::kDynamicInvocationForwarder) {
    // Without private mangling:
    String& name = String::Handle(
        zone_, Function::DemangleDynamicInvocationForwarderName(func_name_));
    func_ = cls_.LookupFunctionAllowPrivate(name);
    if (!func_.IsNull() && func_.IsDynamicFunction()) {
      name = func_.name();  // With private mangling.
      name = Function::CreateDynamicInvocationForwarderName(name);
      func_ = func_.CreateDynamicInvocationForwarder(name);
    } else {
      func_ = Function::null();
    }
  } else if (kind == FunctionLayout::kClosureFunction) {
    // Note this lookup relies on parent functions appearing before child
    // functions in the serialized feedback, so the parent will have already
    // been unoptimized compilated and the child function created and added to
    // ObjectStore::closure_functions_.
    const GrowableObjectArray& closure_functions = GrowableObjectArray::Handle(
        zone_, thread_->isolate()->object_store()->closure_functions());
    bool found = false;
    for (intptr_t i = 0; i < closure_functions.Length(); i++) {
      func_ ^= closure_functions.At(i);
      if (func_.Owner() == cls_.raw() && func_.token_pos() == token_pos) {
        found = true;
        break;
      }
    }
    if (!found) {
      func_ = Function::null();
    }
  } else {
    // This leaves unhandled:
    // - kInvokeFieldDispatcher (how to get a valid args descriptor?)
    // - static field getters
    // - static field initializers (not retained by the field object)
  }

  if (!func_.IsNull()) {
    if (kind == FunctionLayout::kImplicitClosureFunction) {
      func_ = func_.ImplicitClosureFunction();
    }
    if (func_.is_abstract() || (func_.kind() != kind)) {
      func_ = Function::null();
    }
  }

  return func_.raw();
}

ClassPtr TypeFeedbackLoader::ReadClassByName() {
  uri_ = ReadString();
  cls_name_ = ReadString();

  lib_ = Library::LookupLibrary(thread_, uri_);
  if (lib_.IsNull()) {
    if (FLAG_trace_compilation_trace) {
      THR_Print("Missing library %s\n", uri_.ToCString());
    }
    return Class::null();
  }

  if (cls_name_.Equals(Symbols::TopLevel())) {
    cls_ = lib_.toplevel_class();
  } else {
    cls_ = lib_.SlowLookupClassAllowMultiPartPrivate(cls_name_);
    if (cls_.IsNull()) {
      if (FLAG_trace_compilation_trace) {
        THR_Print("Missing class %s %s\n", uri_.ToCString(),
                  cls_name_.ToCString());
      }
    }
  }
  return cls_.raw();
}

StringPtr TypeFeedbackLoader::ReadString() {
  intptr_t len = stream_->ReadUnsigned();
  const char* cstr =
      reinterpret_cast<const char*>(stream_->AddressOfCurrentPosition());
  stream_->Advance(len);
  return Symbols::New(thread_, cstr, len);
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
