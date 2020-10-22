// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include <memory>

#include "include/dart_api.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/kernel.h"
#include "vm/kernel_loader.h"
#endif
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

struct BootstrapLibProps {
  ObjectStore::BootstrapLibraryId index;
  const char* uri;
};

enum { kPathsUriOffset = 0, kPathsSourceOffset = 1, kPathsEntryLength = 2 };

#if !defined(DART_PRECOMPILED_RUNTIME)
#define MAKE_PROPERTIES(CamelName, name)                                       \
  {ObjectStore::k##CamelName, "dart:" #name},

static const BootstrapLibProps bootstrap_libraries[] = {
    FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_PROPERTIES)};

#undef MAKE_PROPERTIES

static const intptr_t kBootstrapLibraryCount = ARRAY_SIZE(bootstrap_libraries);
static void Finish(Thread* thread) {
  Bootstrap::SetupNativeResolver();
  if (!ClassFinalizer::ProcessPendingClasses()) {
    FATAL("Error in class finalization during bootstrapping.");
  }

  // Eagerly compile the _Closure class as it is the class of all closure
  // instances. This allows us to just finalize function types without going
  // through the hoops of trying to compile their scope class.
  ObjectStore* object_store = thread->isolate()->object_store();
  Zone* zone = thread->zone();
  Class& cls = Class::Handle(zone, object_store->closure_class());
  cls.EnsureIsFinalized(thread);

  // Make sure _Closure fields are not marked as unboxing candidates
  // as they are accessed with plain loads.
  const Array& fields = Array::Handle(zone, cls.fields());
  Field& field = Field::Handle(zone);
  for (intptr_t i = 0; i < fields.Length(); ++i) {
    field ^= fields.At(i);
    field.set_is_unboxing_candidate(false);
  }
  // _Closure._hash field should be explicitly marked as nullable because
  // VM creates instances of _Closure without compiling its constructors,
  // so it won't get nullability info from a constructor.
  field ^= fields.At(fields.Length() - 1);
  // Note that UserVisibleName depends on --show-internal-names.
  ASSERT(strncmp(field.UserVisibleNameCString(), "_hash", 5) == 0);
  field.RecordStore(Object::null_object());

#if defined(DEBUG)
  // Verify that closure field offsets are identical in Dart and C++.
  ASSERT(fields.Length() == 6);
  field ^= fields.At(0);
  ASSERT(field.HostOffset() == Closure::instantiator_type_arguments_offset());
  field ^= fields.At(1);
  ASSERT(field.HostOffset() == Closure::function_type_arguments_offset());
  field ^= fields.At(2);
  ASSERT(field.HostOffset() == Closure::delayed_type_arguments_offset());
  field ^= fields.At(3);
  ASSERT(field.HostOffset() == Closure::function_offset());
  field ^= fields.At(4);
  ASSERT(field.HostOffset() == Closure::context_offset());
  field ^= fields.At(5);
  ASSERT(field.HostOffset() == Closure::hash_offset());
#endif  // defined(DEBUG)

  // Eagerly compile Bool class, bool constants are used from within compiler.
  cls = object_store->bool_class();
  cls.EnsureIsFinalized(thread);
}

static ErrorPtr BootstrapFromKernel(Thread* thread,
                                    const uint8_t* kernel_buffer,
                                    intptr_t kernel_buffer_size) {
  Zone* zone = thread->zone();
  const char* error = nullptr;
  std::unique_ptr<kernel::Program> program = kernel::Program::ReadFromBuffer(
      kernel_buffer, kernel_buffer_size, &error);
  if (program == nullptr) {
    const intptr_t kMessageBufferSize = 512;
    char message_buffer[kMessageBufferSize];
    Utils::SNPrint(message_buffer, kMessageBufferSize,
                   "Can't load Kernel binary: %s.", error);
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    kernel::KernelLoader loader(program.get(), /*uri_to_source_table=*/nullptr);

    Isolate* isolate = thread->isolate();

    if (isolate->obfuscate()) {
      loader.ReadObfuscationProhibitions();
    }

    // Load the bootstrap libraries in order (see object_store.h).
    Library& library = Library::Handle(zone);
    for (intptr_t i = 0; i < kBootstrapLibraryCount; ++i) {
      ObjectStore::BootstrapLibraryId id = bootstrap_libraries[i].index;
      library = isolate->object_store()->bootstrap_library(id);
      loader.LoadLibrary(library);
    }

    // Finish bootstrapping, including class finalization.
    Finish(thread);

    // The platform binary may contain other libraries (e.g., dart:_builtin or
    // dart:io) that will not be bundled with application.  Load them now.
    const Object& result = Object::Handle(zone, loader.LoadProgram());
    program.reset();
    if (result.IsError()) {
      return Error::Cast(result).raw();
    }

    // The builtin library should be registered with the VM.
    const auto& dart_builtin =
        String::Handle(zone, String::New("dart:_builtin"));
    library = Library::LookupLibrary(thread, dart_builtin);
    isolate->object_store()->set_builtin_library(library);

    if (FLAG_precompiled_mode) {
      loader.ReadLoadingUnits();
    }

    return Error::null();
  }

  // Either class finalization failed or we caught a compile-time error.
  // In both cases sticky error would be set.
  return Thread::Current()->StealStickyError();
}

ErrorPtr Bootstrap::DoBootstrapping(const uint8_t* kernel_buffer,
                                    intptr_t kernel_buffer_size) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  String& uri = String::Handle(zone);
  Library& lib = Library::Handle(zone);

  HANDLESCOPE(thread);

  // Ensure there are library objects for all the bootstrap libraries.
  for (intptr_t i = 0; i < kBootstrapLibraryCount; ++i) {
    ObjectStore::BootstrapLibraryId id = bootstrap_libraries[i].index;
    uri = Symbols::New(thread, bootstrap_libraries[i].uri);
    lib = isolate->object_store()->bootstrap_library(id);
    ASSERT(lib.raw() == Library::LookupLibrary(thread, uri));
    if (lib.IsNull()) {
      lib = Library::NewLibraryHelper(uri, false);
      lib.SetLoadRequested();
      lib.Register(thread);
      isolate->object_store()->set_bootstrap_library(id, lib);
    }
  }

  return BootstrapFromKernel(thread, kernel_buffer, kernel_buffer_size);
}
#else
ErrorPtr Bootstrap::DoBootstrapping(const uint8_t* kernel_buffer,
                                    intptr_t kernel_buffer_size) {
  UNREACHABLE();
  return Error::null();
}
#endif

}  // namespace dart
