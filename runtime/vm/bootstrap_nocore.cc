// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap.h"

#include "include/dart_api.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/kernel_reader.h"
#endif
#include "vm/object.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/object_store.h"
#endif

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)
#define MAKE_PROPERTIES(CamelName, name)                                       \
  {ObjectStore::k##CamelName, "dart:" #name},

struct BootstrapLibProps {
  ObjectStore::BootstrapLibraryId index;
  const char* uri;
};

static BootstrapLibProps bootstrap_libraries[] = {
    FOR_EACH_BOOTSTRAP_LIBRARY(MAKE_PROPERTIES)};

#undef MAKE_PROPERTIES

static const intptr_t bootstrap_library_count = ARRAY_SIZE(bootstrap_libraries);

void Finish(Thread* thread, bool from_kernel) {
  Bootstrap::SetupNativeResolver();
  ClassFinalizer::ProcessPendingClasses(from_kernel);

  // Eagerly compile the _Closure class as it is the class of all closure
  // instances. This allows us to just finalize function types without going
  // through the hoops of trying to compile their scope class.
  ObjectStore* object_store = thread->isolate()->object_store();
  Zone* zone = thread->zone();
  Class& cls = Class::Handle(zone, object_store->closure_class());
  Compiler::CompileClass(cls);

#if defined(DEBUG)
  // Verify that closure field offsets are identical in Dart and C++.
  const Array& fields = Array::Handle(zone, cls.fields());
  ASSERT(fields.Length() == 5);
  Field& field = Field::Handle(zone);
  field ^= fields.At(0);
  ASSERT(field.Offset() == Closure::instantiator_type_arguments_offset());
  field ^= fields.At(1);
  ASSERT(field.Offset() == Closure::function_type_arguments_offset());
  field ^= fields.At(2);
  ASSERT(field.Offset() == Closure::function_offset());
  field ^= fields.At(3);
  ASSERT(field.Offset() == Closure::context_offset());
  field ^= fields.At(4);
  ASSERT(field.Offset() == Closure::hash_offset());
#endif  // defined(DEBUG)

  // Eagerly compile Bool class, bool constants are used from within compiler.
  cls = object_store->bool_class();
  Compiler::CompileClass(cls);
}

RawError* BootstrapFromKernel(Thread* thread, kernel::Program* program) {
  Zone* zone = thread->zone();
  kernel::KernelReader reader(program);
  Isolate* isolate = thread->isolate();
  // Mark the already-pending classes.  This mark bit will be used to avoid
  // adding classes to the list more than once.
  GrowableObjectArray& pending_classes = GrowableObjectArray::Handle(
      zone, isolate->object_store()->pending_classes());
  dart::Class& pending = dart::Class::Handle(zone);
  for (intptr_t i = 0; i < pending_classes.Length(); ++i) {
    pending ^= pending_classes.At(i);
    pending.set_is_marked_for_parsing();
  }

  // Load the bootstrap libraries in order (see object_store.h).
  Library& library = Library::Handle(zone);
  String& dart_name = String::Handle(zone);
  for (intptr_t i = 0; i < bootstrap_library_count; ++i) {
    ObjectStore::BootstrapLibraryId id = bootstrap_libraries[i].index;
    library = isolate->object_store()->bootstrap_library(id);
    dart_name = library.url();
    for (intptr_t j = 0; j < program->library_count(); ++j) {
      const String& kernel_name = reader.LibraryUri(j);
      if (kernel_name.Equals(dart_name)) {
        reader.ReadLibrary(reader.library_offset(j));
        library.SetLoaded();
        break;
      }
    }
  }

  // Finish bootstrapping, including class finalization.
  Finish(thread, /*from_kernel=*/true);

  // The platform binary may contain other libraries (e.g., dart:_builtin or
  // dart:io) that will not be bundled with application.  Load them now.
  reader.ReadProgram();

  // The builtin library should be registered with the VM.
  dart_name = String::New("dart:_builtin");
  library = Library::LookupLibrary(thread, dart_name);
  isolate->object_store()->set_builtin_library(library);

  return Error::null();
}

RawError* Bootstrap::DoBootstrapping(kernel::Program* program) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  String& uri = String::Handle(zone);
  Library& lib = Library::Handle(zone);

  HANDLESCOPE(thread);

  // Ensure there are library objects for all the bootstrap libraries.
  for (intptr_t i = 0; i < bootstrap_library_count; ++i) {
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

  return BootstrapFromKernel(thread, program);
}
#else
RawError* Bootstrap::DoBootstrapping(kernel::Program* program) {
  UNREACHABLE();
  return Error::null();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
