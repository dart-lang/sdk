// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CLASS_FINALIZER_H_
#define VM_CLASS_FINALIZER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

class Class;
class Function;
class RawClass;
class RawType;
class Script;
class String;
class Type;
class TypeArguments;
class UnresolvedClass;

// Traverses all pending, unfinalized classes, validates and marks them as
// finalized.
class ClassFinalizer : public AllStatic {
 public:
  // Add 'interface' to 'interface_list' if it is not already in the list and
  // return true. Also return true if 'interface' is not added, because it is
  // not unique, i.e. it is already in the list.
  // Return false if 'interface' conflicts with an interface already in the list
  // with the same class, but different type arguments.
  // In the case of a conflict, set 'conflicting' to the existing interface.
  static bool AddInterfaceIfUnique(GrowableArray<Type*>* interface_list,
                                   Type* interface,
                                   Type* conflicting);

  // Finalize and canonicalize type while parsing.
  // Set the error message on failure (to String::null() if no error).
  static RawType* FinalizeAndCanonicalizeType(const Type& type, String* errmsg);

  // Pending classes are classes that need to be finalized.
  static void AddPendingClasses(const GrowableArray<const Class*>& classes);

  // Return false if we still have classes pending to be finalized.
  static bool AllClassesFinalized();

  // Return whether class finalization failed.
  // The function returns true if the finalization was successful.
  // If finalization fails, an error message is set in the sticky error field
  // in the object store.
  static bool FinalizePendingClasses();

  // Verify that the pending classes have been properly prefinalized. This is
  // needed during bootstrapping where the classes have been preloaded.
  static void VerifyBootstrapClasses();

 private:
  static void FinalizeClass(const Class& cls);
  static bool IsSuperCycleFree(const Class& cls);
  static void CheckForLegalConstClass(const Class& cls);
  static RawClass* ResolveClass(const Class& cls,
                                const UnresolvedClass& unresolved_class);
  static void ResolveSuperClass(const Class& cls);
  static void ResolveDefaultClass(const Class& cls);
  static void ResolveInterfaces(const Class& cls,
                                GrowableArray<const Class*>* visited);
  static void FinalizeTypeArguments(const Class& cls,
                                    const TypeArguments& arguments);
  static RawType* ResolveType(const Class& cls, const Type& type);
  static RawType* FinalizeType(const Type& type);
  static void ResolveAndFinalizeUpperBounds(const Class& cls);
  static void VerifyUpperBounds(const Class& cls,
                                const TypeArguments& arguments);
  static void ResolveAndFinalizeSignature(const Class& cls,
                                          const Function& function);
  static void ResolveAndFinalizeMemberTypes(const Class& cls);
  static void PrintClassInformation(const Class& cls);
  static void VerifyClassImplements(const Class& cls);
  static void CollectInterfaces(const Class& cls,
                                GrowableArray<const Class*>* interfaces);
  static void ReportError(const Script& script,
                          intptr_t token_index,
                          const char* format, ...);
  static void ReportError(const char* format, ...);
};

}  // namespace dart

#endif  // VM_CLASS_FINALIZER_H_
