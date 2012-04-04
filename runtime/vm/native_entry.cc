// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_entry.h"

#include "include/dart_api.h"

#include "vm/dart_api_impl.h"

namespace dart {

DEFINE_FLAG(bool, trace_natives, false, "Trace invocation of natives");

NativeFunction NativeEntry::ResolveNative(const Class& cls,
                                          const String& function_name,
                                          int number_of_arguments) {
  // Now resolve the native function to the corresponding native entrypoint.
  const Library& library = Library::Handle(cls.library());
  if (library.native_entry_resolver() == 0) {
    // Native methods are not allowed in the library to which this
    // class belongs in.
    return NULL;
  }
  Dart_EnterScope();  // Enter a new Dart API scope as we invoke API entries.
  Dart_NativeEntryResolver resolver = library.native_entry_resolver();
  Dart_NativeFunction native_function =
      resolver(Api::NewLocalHandle(Isolate::Current(), function_name),
               number_of_arguments);
  Dart_ExitScope();  // Exit the Dart API scope.
  return reinterpret_cast<NativeFunction>(native_function);
}

}  // namespace dart
