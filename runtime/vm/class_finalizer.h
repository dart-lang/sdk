// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CLASS_FINALIZER_H_
#define VM_CLASS_FINALIZER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"

namespace dart {

class AbstractType;
class Class;
class Error;
class Function;
class GrowableObjectArray;
class MixinAppType;
class RawAbstractType;
class RawClass;
class RawType;
class Script;
class Type;
class TypeArguments;
class UnresolvedClass;

// Traverses all pending, unfinalized classes, validates and marks them as
// finalized.
class ClassFinalizer : public AllStatic {
 public:
  // Modes for type resolution and finalization. The ordering is relevant.
  enum FinalizationKind {
    kIgnore,                   // Type is ignored and replaced by dynamic.
    kDoNotResolve,             // Type resolution is postponed.
    kResolveTypeParameters,    // Resolve type parameters only.
    kFinalize,                 // Type resolution and finalization are required.
    kCanonicalize,             // Same as kFinalize, but with canonicalization.
    kCanonicalizeWellFormed    // Error-free resolution, finalization, and
                               // canonicalization are required.
  };

  // Finalize given type while parsing class cls.
  // Also canonicalize type if applicable.
  static RawAbstractType* FinalizeType(
      const Class& cls,
      const AbstractType& type,
      FinalizationKind finalization,
      GrowableObjectArray* pending_types = NULL);

  // Allocate, finalize, and return a new malformed type as if it was declared
  // in class cls at the given token position.
  // If not null, prepend prev_error to the error message built from the format
  // string and its arguments.
  static RawType* NewFinalizedMalformedType(const Error& prev_error,
                                            const Script& script,
                                            intptr_t type_pos,
                                            const char* format, ...)
       PRINTF_ATTRIBUTE(4, 5);

  // Mark the given type as malformed.
  // If not null, prepend prev_error to the error message built from the format
  // string and its arguments.
  static void FinalizeMalformedType(const Error& prev_error,
                                    const Script& script,
                                    const Type& type,
                                    const char* format, ...)
       PRINTF_ATTRIBUTE(4, 5);

  // Mark the given type as malbounded.
  // If not null, prepend prev_error to the error message built from the format
  // string and its arguments.
  static void FinalizeMalboundedType(const Error& prev_error,
                                     const Script& script,
                                     const Type& type,
                                     const char* format, ...)
       PRINTF_ATTRIBUTE(4, 5);

  // Return false if we still have classes pending to be finalized.
  static bool AllClassesFinalized();

  // Return whether processing pending classes (ObjectStore::pending_classes_)
  // failed. The function returns true if the processing was successful.
  // If processin fails, an error message is set in the sticky error field
  // in the object store.
  static bool ProcessPendingClasses();

  // Finalize the types appearing in the declaration of class 'cls', i.e. its
  // type parameters and their upper bounds, its super type and interfaces.
  // Note that the fields and functions have not been parsed yet (unless cls
  // is an anonymous top level class).
  static void FinalizeTypesInClass(const Class& cls);

  // Finalize the class including its fields and functions.
  static void FinalizeClass(const Class& cls);

  // Verify that the classes have been properly prefinalized. This is
  // needed during bootstrapping where the classes have been preloaded.
  static void VerifyBootstrapClasses();

  // Resolve the class of the type, but not the type's type arguments.
  static void ResolveTypeClass(const Class& cls, const AbstractType& type);

  // Resolve the type and target of the redirecting factory.
  static void ResolveRedirectingFactory(const Class& cls,
                                        const Function& factory);

  // Apply the mixin type to the mixin application class.
  static void ApplyMixinType(const Class& mixin_app_class,
                             GrowableObjectArray* pending_types = NULL);

 private:
  static bool IsSuperCycleFree(const Class& cls);
  static bool IsTypeCycleFree(const Class& cls,
                              const AbstractType& type,
                              GrowableArray<intptr_t>* visited);
  static bool IsAliasCycleFree(const Class& cls,
                               GrowableArray<intptr_t>* visited);
  static bool IsMixinCycleFree(const Class& cls,
                               GrowableArray<intptr_t>* visited);
  static void CheckForLegalConstClass(const Class& cls);
  static RawClass* ResolveClass(const Class& cls,
                                const UnresolvedClass& unresolved_class);
  static void ResolveType(const Class& cls, const AbstractType& type);
  static void ResolveRedirectingFactoryTarget(
      const Class& cls,
      const Function& factory,
      const GrowableObjectArray& visited_factories);
  static void CloneMixinAppTypeParameters(const Class& mixin_app_class);
  static void ApplyMixinAppAlias(const Class& mixin_app_class,
                                 bool has_uninstantiated_bounds);
  static void ApplyMixinMembers(const Class& cls);
  static void CreateForwardingConstructors(
      const Class& mixin_app,
      const GrowableObjectArray& cloned_funcs);
  static void CollectTypeArguments(const Class& cls,
                                   const Type& type,
                                   const GrowableObjectArray& collected_args);
  static RawType* ResolveMixinAppType(const Class& cls,
                                      const MixinAppType& mixin_app_type);
  static void ResolveSuperTypeAndInterfaces(const Class& cls,
                                            GrowableArray<intptr_t>* visited);
  static void FinalizeTypeParameters(const Class& cls,
                                     GrowableObjectArray* pending_types = NULL);
  static void FinalizeTypeArguments(const Class& cls,
                                    const TypeArguments& arguments,
                                    intptr_t num_uninitialized_arguments,
                                    Error* bound_error,
                                    GrowableObjectArray* pending_types,
                                    GrowableObjectArray* trail);
  static void CheckRecursiveType(const Class& cls,
                                 const Type& type,
                                 GrowableObjectArray* pending_types);
  static void CheckTypeBounds(const Class& cls, const Type& type);
  static void CheckTypeArgumentBounds(const Class& cls,
                                      const TypeArguments& arguments,
                                      Error* bound_error);
  static void ResolveUpperBounds(const Class& cls);
  static void FinalizeUpperBounds(const Class& cls);
  static void ResolveAndFinalizeSignature(const Class& cls,
                                          const Function& function);
  static void ResolveAndFinalizeMemberTypes(const Class& cls);
  static void PrintClassInformation(const Class& cls);
  static void CollectInterfaces(const Class& cls,
                                const GrowableObjectArray& interfaces);
  static void MarkTypeMalformed(const Error& prev_error,
                                const Script& script,
                                const Type& type,
                                const char* format,
                                va_list args);
  static void ReportError(const Error& error);
  static void ReportError(const Class& cls,
                          intptr_t token_pos,
                          const char* format, ...) PRINTF_ATTRIBUTE(3, 4);
  static void ReportErrors(const Error& prev_error,
                           const Class& cls,
                           intptr_t token_pos,
                           const char* format, ...) PRINTF_ATTRIBUTE(4, 5);

  // Verify implicit offsets recorded in the VM for direct access to fields of
  // Dart instances (e.g: _TypedListView, _ByteDataView).
  static void VerifyImplicitFieldOffsets();
};

}  // namespace dart

#endif  // VM_CLASS_FINALIZER_H_
