// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "vm/class_finalizer.h"

#include "vm/canonical_tables.h"
#include "vm/closure_functions_cache.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/flags.h"
#include "vm/hash_table.h"
#include "vm/heap/heap.h"
#include "vm/isolate.h"
#include "vm/kernel_loader.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/program_visitor.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"

namespace dart {

DEFINE_FLAG(bool, print_classes, false, "Prints details about loaded classes.");
DEFINE_FLAG(bool, trace_class_finalization, false, "Trace class finalization.");
DEFINE_FLAG(bool, trace_type_finalization, false, "Trace type finalization.");

bool ClassFinalizer::AllClassesFinalized() {
  ObjectStore* object_store = IsolateGroup::Current()->object_store();
  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(object_store->pending_classes());
  return classes.Length() == 0;
}

#if defined(DART_PRECOMPILED_RUNTIME)

bool ClassFinalizer::ProcessPendingClasses() {
  ASSERT(AllClassesFinalized());
  return true;
}

#else

// Removes optimized code once we load more classes, since CHA based
// optimizations may have become invalid.
// Only methods which owner classes where subclasses can be invalid.
// TODO(srdjan): Be even more precise by recording the exact CHA optimization.
static void RemoveCHAOptimizedCode(
    const Class& subclass,
    const GrowableArray<intptr_t>& added_subclass_to_cids) {
  ASSERT(FLAG_use_cha_deopt);
  if (added_subclass_to_cids.is_empty()) {
    return;
  }
  // Switch all functions' code to unoptimized.
  const ClassTable& class_table = *IsolateGroup::Current()->class_table();
  Class& cls = Class::Handle();
  for (intptr_t i = 0; i < added_subclass_to_cids.length(); i++) {
    intptr_t cid = added_subclass_to_cids[i];
    cls = class_table.At(cid);
    ASSERT(!cls.IsNull());
    cls.DisableCHAOptimizedCode(subclass);
  }
}

static void AddSuperType(const AbstractType& type,
                         GrowableArray<intptr_t>* finalized_super_classes) {
  ASSERT(type.HasTypeClass());
  ASSERT(!type.IsDynamicType());
  if (type.IsObjectType()) {
    return;
  }
  const Class& cls = Class::Handle(type.type_class());
  ASSERT(cls.is_finalized());
  const intptr_t cid = cls.id();
  for (intptr_t i = 0; i < finalized_super_classes->length(); i++) {
    if ((*finalized_super_classes)[i] == cid) {
      // Already added.
      return;
    }
  }
  finalized_super_classes->Add(cid);
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  AddSuperType(super_type, finalized_super_classes);
}

// Use array instead of set since we expect very few subclassed classes
// to occur.
static void CollectFinalizedSuperClasses(
    const Class& cls_,
    GrowableArray<intptr_t>* finalized_super_classes) {
  Class& cls = Class::Handle(cls_.ptr());
  AbstractType& super_type = Type::Handle();
  super_type = cls.super_type();
  if (!super_type.IsNull()) {
    if (super_type.HasTypeClass()) {
      cls = super_type.type_class();
      if (cls.is_finalized()) {
        AddSuperType(super_type, finalized_super_classes);
      }
    }
  }
}

class InterfaceFinder {
 public:
  InterfaceFinder(Zone* zone,
                  ClassTable* class_table,
                  GrowableArray<intptr_t>* cids)
      : class_table_(class_table),
        array_handles_(zone),
        class_handles_(zone),
        type_handles_(zone),
        cids_(cids) {}

  void FindAllInterfaces(const Class& klass) {
    // The class is implementing its own interface.
    cids_->Add(klass.id());

    ScopedHandle<Array> array(&array_handles_);
    ScopedHandle<Class> interface_class(&class_handles_);
    ScopedHandle<Class> current_class(&class_handles_);
    ScopedHandle<AbstractType> type(&type_handles_);

    *current_class = klass.ptr();
    while (true) {
      // We don't care about top types.
      const intptr_t cid = current_class->id();
      if (cid == kObjectCid || cid == kDynamicCid || cid == kVoidCid) {
        break;
      }

      // The class is implementing its directly declared implemented interfaces.
      *array = klass.interfaces();
      if (!array->IsNull()) {
        for (intptr_t i = 0; i < array->Length(); ++i) {
          *type ^= array->At(i);
          *interface_class = class_table_->At(type->type_class_id());
          FindAllInterfaces(*interface_class);
        }
      }

      // The class is implementing its super type's interfaces.
      *type = current_class->super_type();
      if (type->IsNull()) break;
      *current_class = class_table_->At(type->type_class_id());
    }
  }

 private:
  ClassTable* class_table_;
  ReusableHandleStack<Array> array_handles_;
  ReusableHandleStack<Class> class_handles_;
  ReusableHandleStack<AbstractType> type_handles_;
  GrowableArray<intptr_t>* cids_;
};

static void CollectImmediateSuperInterfaces(const Class& cls,
                                            GrowableArray<intptr_t>* cids) {
  const Array& interfaces = Array::Handle(cls.interfaces());
  Class& ifc = Class::Handle();
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    if (!type.HasTypeClass()) continue;
    ifc = type.type_class();
    for (intptr_t j = 0; j < cids->length(); ++j) {
      if ((*cids)[j] == ifc.id()) {
        // Already added.
        return;
      }
    }
    cids->Add(ifc.id());
  }
}

// Processing ObjectStore::pending_classes_ occurs:
// a) when bootstrap process completes (VerifyBootstrapClasses).
// b) after the user classes are loaded (dart_api).
bool ClassFinalizer::ProcessPendingClasses() {
  Thread* thread = Thread::Current();
  TIMELINE_DURATION(thread, Isolate, "ProcessPendingClasses");
  auto isolate_group = thread->isolate_group();
  ASSERT(isolate_group != nullptr);
  HANDLESCOPE(thread);
  ObjectStore* object_store = isolate_group->object_store();
  const Error& error = Error::Handle(thread->zone(), thread->sticky_error());
  if (!error.IsNull()) {
    return false;
  }
  if (AllClassesFinalized()) {
    return true;
  }

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    GrowableObjectArray& class_array = GrowableObjectArray::Handle();
    class_array = object_store->pending_classes();
    ASSERT(!class_array.IsNull());
    Class& cls = Class::Handle();

#if defined(DEBUG)
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      // Recognized a new class, but forgot to add @pragma('vm:entrypoint')?
      ASSERT(cls.is_declaration_loaded());
    }
#endif

    // Finalize types in all classes.
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      FinalizeTypesInClass(cls);
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
      cls.SetUserVisibleNameInClassTable();
#endif
    }

    // Clear pending classes array.
    class_array = GrowableObjectArray::New();
    object_store->set_pending_classes(class_array);
    VerifyImplicitFieldOffsets();  // Verification after an error may fail.

    return true;
  } else {
    return false;
  }
  UNREACHABLE();
  return true;
}

void ClassFinalizer::VerifyBootstrapClasses() {
  if (FLAG_trace_class_finalization) {
    OS::PrintErr("VerifyBootstrapClasses START.\n");
  }
  ObjectStore* object_store = IsolateGroup::Current()->object_store();

  Class& cls = Class::Handle();
#if defined(DEBUG)
  // Basic checking.
  cls = object_store->object_class();
  ASSERT_EQUAL(Instance::InstanceSize(), cls.host_instance_size());
  cls = object_store->integer_implementation_class();
  ASSERT_EQUAL(Integer::InstanceSize(), cls.host_instance_size());
  cls = object_store->smi_class();
  ASSERT_EQUAL(Smi::InstanceSize(), cls.host_instance_size());
  cls = object_store->mint_class();
  ASSERT_EQUAL(Mint::InstanceSize(), cls.host_instance_size());
  cls = object_store->one_byte_string_class();
  ASSERT_EQUAL(OneByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->two_byte_string_class();
  ASSERT_EQUAL(TwoByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->external_one_byte_string_class();
  ASSERT_EQUAL(ExternalOneByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->external_two_byte_string_class();
  ASSERT_EQUAL(ExternalTwoByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->double_class();
  ASSERT_EQUAL(Double::InstanceSize(), cls.host_instance_size());
  cls = object_store->bool_class();
  ASSERT_EQUAL(Bool::InstanceSize(), cls.host_instance_size());
  cls = object_store->array_class();
  ASSERT_EQUAL(Array::InstanceSize(), cls.host_instance_size());
  cls = object_store->immutable_array_class();
  ASSERT_EQUAL(ImmutableArray::InstanceSize(), cls.host_instance_size());
  cls = object_store->weak_property_class();
  ASSERT_EQUAL(WeakProperty::InstanceSize(), cls.host_instance_size());
  cls = object_store->weak_reference_class();
  ASSERT_EQUAL(WeakReference::InstanceSize(), cls.host_instance_size());
  cls = object_store->finalizer_class();
  ASSERT_EQUAL(Finalizer::InstanceSize(), cls.host_instance_size());
  cls = object_store->finalizer_entry_class();
  ASSERT_EQUAL(FinalizerEntry::InstanceSize(), cls.host_instance_size());
  cls = object_store->map_impl_class();
  ASSERT_EQUAL(Map::InstanceSize(), cls.host_instance_size());
  cls = object_store->const_map_impl_class();
  ASSERT_EQUAL(Map::InstanceSize(), cls.host_instance_size());
  cls = object_store->set_impl_class();
  ASSERT_EQUAL(Set::InstanceSize(), cls.host_instance_size());
  cls = object_store->const_set_impl_class();
  ASSERT_EQUAL(Set::InstanceSize(), cls.host_instance_size());
#endif  // defined(DEBUG)

  // Remember the currently pending classes.
  const GrowableObjectArray& class_array =
      GrowableObjectArray::Handle(object_store->pending_classes());
  for (intptr_t i = 0; i < class_array.Length(); i++) {
    // TODO(iposva): Add real checks.
    cls ^= class_array.At(i);
    if (cls.is_finalized() || cls.is_prefinalized()) {
      // Pre-finalized bootstrap classes must not define any fields.
      ASSERT(!cls.HasInstanceFields());
    }
  }

  // Finalize type hierarchy for types that aren't pre-finalized
  // by Object::Init().
  if (!ProcessPendingClasses()) {
    // TODO(srdjan): Exit like a real VM instead.
    const Error& err = Error::Handle(Thread::Current()->sticky_error());
    OS::PrintErr("Could not verify bootstrap classes : %s\n",
                 err.ToErrorCString());
    OS::Exit(255);
  }

  if (FLAG_trace_class_finalization) {
    OS::PrintErr("VerifyBootstrapClasses END.\n");
  }
  IsolateGroup::Current()->heap()->Verify("VerifyBootstrapClasses END");
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::FinalizeTypeParameters(Zone* zone,
                                            const TypeParameters& type_params,
                                            FinalizationKind finalization) {
  if (!type_params.IsNull()) {
    TypeArguments& type_args = TypeArguments::Handle(zone);

    type_args = type_params.bounds();
    type_args = FinalizeTypeArguments(zone, type_args, finalization);
    type_params.set_bounds(type_args);

    type_args = type_params.defaults();
    type_args = FinalizeTypeArguments(zone, type_args, finalization);
    type_params.set_defaults(type_args);

    type_params.OptimizeFlags();
  }
}

TypeArgumentsPtr ClassFinalizer::FinalizeTypeArguments(
    Zone* zone,
    const TypeArguments& type_args,
    FinalizationKind finalization) {
  if (type_args.IsNull()) {
    return TypeArguments::null();
  }
  ASSERT(type_args.ptr() != Object::empty_type_arguments().ptr());
  AbstractType& type = AbstractType::Handle(zone);
  for (intptr_t i = 0, n = type_args.Length(); i < n; ++i) {
    type = type_args.TypeAt(i);
    FinalizeType(type, kFinalize);
  }
  if (finalization >= kCanonicalize) {
    return type_args.Canonicalize(Thread::Current());
  }
  return type_args.ptr();
}

AbstractTypePtr ClassFinalizer::FinalizeType(const AbstractType& type,
                                             FinalizationKind finalization) {
  if (type.IsFinalized()) {
    if ((finalization >= kCanonicalize) && !type.IsCanonical()) {
      return type.Canonicalize(Thread::Current());
    }
    return type.ptr();
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  if (FLAG_trace_type_finalization) {
    THR_Print("Finalizing type '%s'\n", type.ToCString());
  }

  if (type.IsType()) {
    const auto& t = Type::Cast(type);
    const auto& type_args = TypeArguments::Handle(zone, t.arguments());
    ASSERT(type_args.IsNull() ||
           type_args.Length() ==
               Class::Handle(zone, t.type_class()).NumTypeParameters(thread));
    FinalizeTypeArguments(zone, type_args, kFinalize);

  } else if (type.IsTypeParameter()) {
    const TypeParameter& type_parameter = TypeParameter::Cast(type);
    // The base and index of a function type parameter are eagerly calculated
    // upon loading and do not require adjustment here.
    if (type_parameter.IsClassTypeParameter()) {
      const Class& parameterized_class = Class::Cast(
          Object::Handle(zone, type_parameter.parameterized_class()));
      ASSERT(!parameterized_class.IsNull());
      // The index must reflect the position of this type parameter in the type
      // arguments vector of its parameterized class. The offset to add is the
      // number of type arguments in the super type, which is equal to the
      // difference in number of type arguments and type parameters of the
      // parameterized class.
      const intptr_t offset = parameterized_class.NumTypeArguments() -
                              parameterized_class.NumTypeParameters();
      const intptr_t index = type_parameter.index() + offset;
      if (!Utils::IsUint(16, index)) {
        FATAL("Too many type parameters in %s",
              parameterized_class.UserVisibleNameCString());
      }
      type_parameter.set_base(offset);  // Informative, but not needed.
      type_parameter.set_index(index);

      if (AbstractType::Handle(zone, type_parameter.bound())
              .IsNullableObjectType()) {
        // Remove the reference to the parameterized class to
        // canonicalize common class type parameters
        // with 'Object?' bound and same indices to the same
        // instances.
        type_parameter.set_parameterized_class_id(kIllegalCid);
      }
    }
  } else if (type.IsFunctionType()) {
    const auto& signature = FunctionType::Cast(type);
    FinalizeTypeParameters(
        zone, TypeParameters::Handle(zone, signature.type_parameters()),
        kFinalize);

    AbstractType& type = AbstractType::Handle(zone);
    type = signature.result_type();
    FinalizeType(type, kFinalize);

    for (intptr_t i = 0, n = signature.NumParameters(); i < n; ++i) {
      type = signature.ParameterTypeAt(i);
      FinalizeType(type, kFinalize);
    }

  } else if (type.IsRecordType()) {
    const auto& record = RecordType::Cast(type);
    AbstractType& type = AbstractType::Handle(zone);
    for (intptr_t i = 0, n = record.NumFields(); i < n; ++i) {
      type = record.FieldTypeAt(i);
      FinalizeType(type, kFinalize);
    }
  }

  type.SetIsFinalized();

  if (finalization >= kCanonicalize) {
    return type.Canonicalize(thread);
  } else {
    return type.ptr();
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)

#if defined(TARGET_ARCH_X64)
static bool IsPotentialExactGeneric(const AbstractType& type) {
  // TODO(dartbug.com/34170) Investigate supporting this for fields with types
  // that depend on type parameters of the enclosing class.
  if (type.IsType() && !type.IsDartFunctionType() && type.IsInstantiated() &&
      !type.IsFutureOrType()) {
    const Class& cls = Class::Handle(type.type_class());
    return cls.IsGeneric();
  }

  return false;
}
#else
// TODO(dartbug.com/34170) Support other architectures.
static bool IsPotentialExactGeneric(const AbstractType& type) {
  return false;
}
#endif

void ClassFinalizer::FinalizeMemberTypes(const Class& cls) {
  // Note that getters and setters are explicitly listed as such in the list of
  // functions of a class, so we do not need to consider fields as implicitly
  // generating getters and setters.
  // Most overriding conflicts are only static warnings, i.e. they are not
  // reported as compile-time errors by the vm.
  // Static warning examples are:
  // - a static getter 'v' conflicting with an inherited instance setter 'v='.
  // - a static setter 'v=' conflicting with an inherited instance member 'v'.
  // - an instance member 'v' conflicting with an accessible static member 'v'
  //   or 'v=' of a super class (except that an instance method 'v' does not
  //   conflict with an accessible static setter 'v=' of a super class).
  // The compile-time errors we report are:
  // - a static member 'v' conflicting with an inherited instance member 'v'.
  // - a static setter 'v=' conflicting with an inherited instance setter 'v='.
  // - an instance method conflicting with an inherited instance field or
  //   instance getter.
  // - an instance field or instance getter conflicting with an inherited
  //   instance method.

  // Finalize type of fields and check for conflicts in super classes.
  auto isolate_group = IsolateGroup::Current();
  Zone* zone = Thread::Current()->zone();
  Array& array = Array::Handle(zone, cls.fields());
  Field& field = Field::Handle(zone);
  AbstractType& type = AbstractType::Handle(zone);
  Function& function = Function::Handle(zone);
  FunctionType& signature = FunctionType::Handle(zone);
  const intptr_t num_fields = array.Length();
  const bool track_exactness = isolate_group->use_field_guards();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= array.At(i);
    type = field.type();
    type = FinalizeType(type);
    field.SetFieldType(type);
    if (track_exactness && IsPotentialExactGeneric(type)) {
      field.set_static_type_exactness_state(
          StaticTypeExactnessState::Uninitialized());
    }
    function = field.InitializerFunction();
    if (!function.IsNull()) {
      // TODO(regis): It looks like the initializer is never set at this point.
      // Remove this finalization code?
      signature = function.signature();
      signature ^= FinalizeType(signature);
      function.SetSignature(signature);
    }
  }
  // Finalize function signatures and check for conflicts in super classes and
  // interfaces.
  array = cls.current_functions();
  const intptr_t num_functions = array.Length();
  for (intptr_t i = 0; i < num_functions; i++) {
    function ^= array.At(i);
    signature = function.signature();
    signature ^= FinalizeType(signature);
    function.SetSignature(signature);
    if (function.IsSetterFunction() || function.IsImplicitSetterFunction()) {
      continue;
    }
  }
}

// For a class used as an interface marks this class and all its superclasses
// implemented.
//
// Does not mark its interfaces implemented because those would already be
// marked as such.
static void MarkImplemented(Zone* zone, const Class& iface) {
  if (iface.is_implemented()) {
    return;
  }

  Class& cls = Class::Handle(zone, iface.ptr());
  AbstractType& type = AbstractType::Handle(zone);

  while (!cls.is_implemented()) {
    cls.set_is_implemented();

    type = cls.super_type();
    if (type.IsNull() || type.IsObjectType()) {
      break;
    }
    cls = type.type_class();
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::FinalizeTypesInClass(const Class& cls) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  cls.EnsureDeclarationLoaded();
  if (cls.is_type_finalized()) {
    return;
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  Zone* zone = thread->zone();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if (cls.is_type_finalized()) {
    return;
  }

  if (FLAG_trace_class_finalization) {
    THR_Print("Finalize types in %s\n", cls.ToCString());
  }

  bool has_isolate_unsendable_pragma =
      cls.is_isolate_unsendable_due_to_pragma();
  bool is_future_subtype = cls.IsFutureClass();

  // Finalize super class.
  Class& super_class = Class::Handle(zone, cls.SuperClass());
  if (!super_class.IsNull()) {
    FinalizeTypesInClass(super_class);
  }
  // Finalize type parameters before finalizing the super type.
  FinalizeTypeParameters(
      zone, TypeParameters::Handle(zone, cls.type_parameters()), kCanonicalize);
  ASSERT(super_class.ptr() == cls.SuperClass());  // Not modified.
  ASSERT(super_class.IsNull() || super_class.is_type_finalized());
  // Finalize super type.
  Type& super_type = Type::Handle(zone, cls.super_type());
  if (!super_type.IsNull()) {
    super_type ^= FinalizeType(super_type);
    cls.set_super_type(super_type);
    has_isolate_unsendable_pragma |=
        super_class.is_isolate_unsendable_due_to_pragma();
    is_future_subtype |= super_class.is_future_subtype();
  }
  // Finalize interface types (but not necessarily interface classes).
  const auto& interface_types = Array::Handle(zone, cls.interfaces());
  auto& interface_type = AbstractType::Handle(zone);
  auto& interface_class = Class::Handle(zone);
  for (intptr_t i = 0; i < interface_types.Length(); i++) {
    interface_type ^= interface_types.At(i);
    interface_type = FinalizeType(interface_type);
    interface_class = interface_type.type_class();
    ASSERT(!interface_class.IsNull());
    FinalizeTypesInClass(interface_class);
    interface_types.SetAt(i, interface_type);
    has_isolate_unsendable_pragma |=
        interface_class.is_isolate_unsendable_due_to_pragma();
    is_future_subtype |= interface_class.is_future_subtype();
  }
  cls.set_is_type_finalized();
  cls.set_is_isolate_unsendable_due_to_pragma(has_isolate_unsendable_pragma);
  cls.set_is_future_subtype(is_future_subtype);
  if (is_future_subtype && !cls.is_abstract()) {
    MarkClassCanBeFuture(zone, cls);
  }

  RegisterClassInHierarchy(zone, cls);
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void ClassFinalizer::RegisterClassInHierarchy(Zone* zone, const Class& cls) {
  auto& type = AbstractType::Handle(zone, cls.super_type());
  auto& other_cls = Class::Handle(zone);
  // Add this class to the direct subclasses of the superclass, unless the
  // superclass is Object.
  if (!type.IsNull() && !type.IsObjectType()) {
    other_cls = cls.SuperClass();
    ASSERT(!other_cls.IsNull());
    other_cls.AddDirectSubclass(cls);
  }

  // Add this class as an implementor to the implemented interface's type
  // classes.
  auto& interfaces = Array::Handle(zone, cls.interfaces());
  const intptr_t mixin_index =
      cls.is_transformed_mixin_application() ? interfaces.Length() - 1 : -1;
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    other_cls = type.type_class();
    MarkImplemented(zone, other_cls);
    other_cls.AddDirectImplementor(cls, /* is_mixin = */ i == mixin_index);
  }

  // Propagate known concrete implementors to interfaces.
  if (!cls.is_abstract()) {
    GrowableArray<const Class*> worklist;
    worklist.Add(&cls);
    while (!worklist.is_empty()) {
      const Class& implemented = *worklist.RemoveLast();
      if (!implemented.NoteImplementor(cls)) continue;
      type = implemented.super_type();
      if (!type.IsNull()) {
        worklist.Add(&Class::Handle(zone, implemented.SuperClass()));
      }
      interfaces = implemented.interfaces();
      for (intptr_t i = 0; i < interfaces.Length(); i++) {
        type ^= interfaces.At(i);
        worklist.Add(&Class::Handle(zone, type.type_class()));
      }
    }
  }
}

void ClassFinalizer::MarkClassCanBeFuture(Zone* zone, const Class& cls) {
  if (cls.can_be_future()) return;

  cls.set_can_be_future(true);

  Class& base = Class::Handle(zone, cls.SuperClass());
  if (!base.IsNull()) {
    MarkClassCanBeFuture(zone, base);
  }
  auto& interfaces = Array::Handle(zone, cls.interfaces());
  auto& type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    base = type.type_class();
    MarkClassCanBeFuture(zone, base);
  }
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::FinalizeClass(const Class& cls) {
  ASSERT(cls.is_type_finalized());
  if (cls.is_finalized()) {
    return;
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);

  if (FLAG_trace_class_finalization) {
    THR_Print("Finalize %s\n", cls.ToCString());
  }

#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(thread, Timeline::GetCompilerStream(),
                             "FinalizeClass");
  if (tbes.enabled()) {
    tbes.SetNumArguments(1);
    tbes.CopyArgument(0, "class", cls.ToCString());
  }
#endif  // defined(SUPPORT_TIMELINE)

  // If loading from a kernel, make sure that the class is fully loaded.
  ASSERT(cls.IsTopLevel() || (cls.kernel_offset() > 0));
  if (!cls.is_loaded()) {
    kernel::KernelLoader::FinishLoading(cls);
    if (cls.is_finalized()) {
      return;
    }
  }

  // Ensure super class is finalized.
  const Class& super = Class::Handle(cls.SuperClass());
  if (!super.IsNull()) {
    FinalizeClass(super);
    if (cls.is_finalized()) {
      return;
    }
  }
  // Mark as loaded and finalized.
  cls.Finalize();
  if (FLAG_print_classes) {
    PrintClassInformation(cls);
  }
  FinalizeMemberTypes(cls);

  // The rest of finalization for non-top-level class has to be done with
  // stopped mutators. It will be done by AllocateFinalizeClass. before new
  // instance of a class is created in GetAllocationStubForClass.
  if (cls.IsTopLevel()) {
    cls.set_is_allocate_finalized();
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

#if !defined(DART_PRECOMPILED_RUNTIME)

ErrorPtr ClassFinalizer::AllocateFinalizeClass(const Class& cls) {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(cls.is_finalized());
  ASSERT(!cls.is_allocate_finalized());

  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);

  if (FLAG_trace_class_finalization) {
    THR_Print("Allocate finalize %s\n", cls.ToCString());
  }

#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(thread, Timeline::GetCompilerStream(),
                             "AllocateFinalizeClass");
  if (tbes.enabled()) {
    tbes.SetNumArguments(1);
    tbes.CopyArgument(0, "class", cls.ToCString());
  }
#endif  // defined(SUPPORT_TIMELINE)

  // Run additional checks after all types are finalized.
  if (FLAG_use_cha_deopt && !cls.IsTopLevel()) {
    {
      GrowableArray<intptr_t> cids;
      CollectFinalizedSuperClasses(cls, &cids);
      CollectImmediateSuperInterfaces(cls, &cids);
      RemoveCHAOptimizedCode(cls, cids);
    }

    Zone* zone = thread->zone();
    ClassTable* class_table = thread->isolate_group()->class_table();
    auto& interface_class = Class::Handle(zone);

    // We scan every interface this [cls] implements and invalidate all CHA
    // code which depends on knowing the implementors of that interface.
    {
      GrowableArray<intptr_t> cids;
      InterfaceFinder finder(zone, class_table, &cids);
      finder.FindAllInterfaces(cls);
      for (intptr_t j = 0; j < cids.length(); ++j) {
        interface_class = class_table->At(cids[j]);
        interface_class.DisableCHAImplementorUsers();
      }
    }
  }

  cls.set_is_allocate_finalized();
  return Error::null();
}

ErrorPtr ClassFinalizer::LoadClassMembers(const Class& cls) {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(!cls.is_finalized());

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    cls.EnsureDeclarationLoaded();
#endif
    ASSERT(cls.is_type_finalized());
    ClassFinalizer::FinalizeClass(cls);
    return Error::null();
  } else {
    return Thread::Current()->StealStickyError();
  }
}

void ClassFinalizer::PrintClassInformation(const Class& cls) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  const String& class_name = String::Handle(cls.Name());
  THR_Print("class '%s'", class_name.ToCString());
  const Library& library = Library::Handle(cls.library());
  if (!library.IsNull()) {
    THR_Print(" library '%s%s':\n", String::Handle(library.url()).ToCString(),
              String::Handle(library.private_key()).ToCString());
  } else {
    THR_Print(" (null library):\n");
  }
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (super_type.IsNull()) {
    THR_Print("  Super: nullptr");
  } else {
    const String& super_name = String::Handle(super_type.Name());
    THR_Print("  Super: %s", super_name.ToCString());
  }
  const Array& interfaces_array = Array::Handle(cls.interfaces());
  if (interfaces_array.Length() > 0) {
    THR_Print("; interfaces: ");
    AbstractType& interface = AbstractType::Handle();
    intptr_t len = interfaces_array.Length();
    for (intptr_t i = 0; i < len; i++) {
      interface ^= interfaces_array.At(i);
      THR_Print("  %s ", interface.ToCString());
    }
  }
  THR_Print("\n");
  const Array& functions_array = Array::Handle(cls.current_functions());
  Function& function = Function::Handle();
  intptr_t len = functions_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    function ^= functions_array.At(i);
    THR_Print("  %s\n", function.ToCString());
  }
  const Array& fields_array = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  len = fields_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    field ^= fields_array.At(i);
    THR_Print("  %s\n", field.ToCString());
  }
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::ReportError(const Error& error) {
  Report::LongJump(error);
  UNREACHABLE();
}

void ClassFinalizer::ReportError(const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Script& null_script = Script::Handle();
  Report::MessageV(Report::kError, null_script, TokenPosition::kNoSource,
                   Report::AtLocation, format, args);
  va_end(args);
  UNREACHABLE();
}

#if !defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::VerifyImplicitFieldOffsets() {
#ifdef DEBUG
  Thread* thread = Thread::Current();
  auto isolate_group = thread->isolate_group();

  if (isolate_group->obfuscate()) {
    // Field names are obfuscated.
    return;
  }

  Zone* zone = thread->zone();
  const ClassTable& class_table = *(isolate_group->class_table());
  Class& cls = Class::Handle(zone);
  Array& fields_array = Array::Handle(zone);
  Field& field = Field::Handle(zone);
  String& name = String::Handle(zone);
  String& expected_name = String::Handle(zone);
  Error& error = Error::Handle(zone);
  TypeParameter& type_param = TypeParameter::Handle(zone);

  // Now verify field offsets of '_ByteBuffer' class.
  cls = class_table.At(kByteBufferCid);
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());
  fields_array ^= cls.fields();
  ASSERT(fields_array.Length() == ByteBuffer::NumberOfFields());
  field ^= fields_array.At(0);
  ASSERT(field.HostOffset() == ByteBuffer::data_offset());
  name ^= field.name();
  expected_name ^= String::New("_data");
  ASSERT(String::EqualsIgnoringPrivateKey(name, expected_name));

  // Now verify field offsets of 'Pointer' class.
  cls = class_table.At(kPointerCid);
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());
  ASSERT(cls.NumTypeParameters() == 1);
  type_param = cls.TypeParameterAt(0);
  ASSERT(Pointer::kNativeTypeArgPos == type_param.index());
#endif
}

void ClassFinalizer::SortClasses() {
  auto T = Thread::Current();
  StackZone stack_zone(T);
  auto Z = T->zone();
  auto IG = T->isolate_group();

  // Prevent background compiler from adding deferred classes or canonicalizing
  // new types while classes are being sorted and type hashes are modified.
  NoBackgroundCompilerScope no_bg_compiler(T);
  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());

  ClassTable* table = IG->class_table();
  intptr_t num_cids = table->NumCids();

  std::unique_ptr<intptr_t[]> old_to_new_cid(new intptr_t[num_cids]);

  for (intptr_t cid = 0; cid < kNumPredefinedCids; cid++) {
    old_to_new_cid[cid] = cid;  // The predefined classes cannot change cids.
  }
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    old_to_new_cid[cid] = -1;
  }

  intptr_t next_new_cid = kNumPredefinedCids;
  GrowableArray<intptr_t> dfs_stack;
  Class& cls = Class::Handle(Z);
  GrowableObjectArray& subclasses = GrowableObjectArray::Handle(Z);

  // Object doesn't use its subclasses list.
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    if (!table->HasValidClassAt(cid)) {
      continue;
    }
    cls = table->At(cid);
    if (!cls.is_declaration_loaded()) {
      continue;
    }
    if (cls.SuperClass() == IG->object_store()->object_class()) {
      dfs_stack.Add(cid);
    }
  }

  while (dfs_stack.length() > 0) {
    intptr_t cid = dfs_stack.RemoveLast();
    ASSERT(table->HasValidClassAt(cid));
    cls = table->At(cid);
    ASSERT(!cls.IsNull());
    if (old_to_new_cid[cid] == -1) {
      old_to_new_cid[cid] = next_new_cid++;
      if (FLAG_trace_class_finalization) {
        THR_Print("%" Pd ": %s, was %" Pd "\n", old_to_new_cid[cid],
                  cls.ToCString(), cid);
      }
    }
    subclasses = cls.direct_subclasses();
    if (!subclasses.IsNull()) {
      for (intptr_t i = 0; i < subclasses.Length(); i++) {
        cls ^= subclasses.At(i);
        ASSERT(!cls.IsNull());
        dfs_stack.Add(cls.id());
      }
    }
  }

  // Top-level classes, typedefs, patch classes, etc.
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    if (old_to_new_cid[cid] == -1) {
      old_to_new_cid[cid] = next_new_cid++;
      if (FLAG_trace_class_finalization && table->HasValidClassAt(cid)) {
        cls = table->At(cid);
        THR_Print("%" Pd ": %s, was %" Pd "\n", old_to_new_cid[cid],
                  cls.ToCString(), cid);
      }
    }
  }
  ASSERT(next_new_cid == num_cids);
  RemapClassIds(old_to_new_cid.get());
  RehashTypes();          // Types use cid's as part of their hashes.
  IG->RehashConstants();  // Const objects use cid's as part of their hashes.
}

class CidRewriteVisitor : public ObjectVisitor {
 public:
  explicit CidRewriteVisitor(intptr_t* old_to_new_cids)
      : old_to_new_cids_(old_to_new_cids) {}

  intptr_t Map(intptr_t cid) {
    ASSERT(cid != -1);
    return old_to_new_cids_[cid];
  }

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsClass()) {
      ClassPtr cls = Class::RawCast(obj);
      const classid_t old_cid = cls->untag()->id_;
      if (ClassTable::IsTopLevelCid(old_cid)) {
        // We don't remap cids of top level classes.
        return;
      }
      cls->untag()->id_ = Map(old_cid);
      cls->untag()->implementor_cid_ = Map(cls->untag()->implementor_cid_);
    } else if (obj->IsField()) {
      FieldPtr field = Field::RawCast(obj);
      field->untag()->guarded_cid_ = Map(field->untag()->guarded_cid_);
      field->untag()->is_nullable_ = Map(field->untag()->is_nullable_);
    } else if (obj->IsTypeParameter()) {
      TypeParameterPtr param = TypeParameter::RawCast(obj);
      if (!UntaggedTypeParameter::IsFunctionTypeParameter::decode(
              param->untag()->flags())) {
        param->untag()->set_owner(
            Smi::New(Map(Smi::Value(Smi::RawCast(param->untag()->owner())))));
      }
    } else if (obj->IsType()) {
      TypePtr type = Type::RawCast(obj);
      type->untag()->set_type_class_id(Map(type->untag()->type_class_id()));
    } else {
      intptr_t old_cid = obj->GetClassId();
      intptr_t new_cid = Map(old_cid);
      if (old_cid != new_cid) {
        // Don't touch objects that are unchanged. In particular, Instructions,
        // which are write-protected.
        obj->untag()->SetClassIdUnsynchronized(new_cid);
      }
    }
  }

 private:
  intptr_t* old_to_new_cids_;
};

void ClassFinalizer::RemapClassIds(intptr_t* old_to_new_cid) {
  Thread* T = Thread::Current();
  IsolateGroup* IG = T->isolate_group();

  // Code, ICData, allocation stubs have now-invalid cids.
  ClearAllCode();

  {
    // The [HeapIterationScope] also safepoints all threads.
    HeapIterationScope his(T);

    // Update the class table. Do it before rewriting cids in headers, as
    // the heap walkers load an object's size *after* calling the visitor.
    IG->class_table()->Remap(old_to_new_cid);
    IG->set_remapping_cids(true);

    // Rewrite cids in headers and cids in Classes, Fields, Types and
    // TypeParameters.
    {
      CidRewriteVisitor visitor(old_to_new_cid);
      IG->heap()->VisitObjects(&visitor);
    }

    IG->set_remapping_cids(false);
#if defined(DEBUG)
    IG->class_table()->Validate();
#endif
  }

#if defined(DEBUG)
  IG->heap()->Verify("RemapClassIds");
#endif
}

// Clears the cached canonicalized hash codes for all instances which directly
// (or indirectly) depend on class ids.
//
// In the Dart VM heap the following instances directly use cids for the
// computation of canonical hash codes:
//
//    * TypePtr (due to UntaggedType::type_class_id)
//    * TypeParameterPtr (due to UntaggedTypeParameter::owner_)
//
// The following instances use cids for the computation of canonical hash codes
// indirectly:
//
//    * TypePtr (due to type arguments)
//    * FunctionTypePtr (due to the result and parameter types)
//    * RecordTypePtr (due to field types)
//    * TypeArgumentsPtr (due to type references)
//    * InstancePtr (due to instance fields)
//    * ArrayPtr (due to type arguments & array entries)
//
// Caching of the canonical hash codes happens for:
//
//    * UntaggedAbstractType::hash_
//    * UntaggedTypeArguments::hash_
//    * InstancePtr (weak table)
//    * ArrayPtr (weak table)
//
// Usages of canonical hash codes are:
//
//   * ObjectStore::canonical_types()
//   * ObjectStore::canonical_function_types()
//   * ObjectStore::canonical_record_types()
//   * ObjectStore::canonical_type_parameters()
//   * ObjectStore::canonical_type_arguments()
//   * Class::constants()
//
class ClearTypeHashVisitor : public ObjectVisitor {
 public:
  explicit ClearTypeHashVisitor(Zone* zone)
      : type_(AbstractType::Handle(zone)),
        type_args_(TypeArguments::Handle(zone)) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsType() || obj->IsTypeParameter() || obj->IsFunctionType() ||
        obj->IsRecordType()) {
      type_ ^= obj;
      type_.SetHash(0);
    } else if (obj->IsTypeArguments()) {
      type_args_ ^= obj;
      type_args_.SetHash(0);
    }
  }

 private:
  AbstractType& type_;
  TypeArguments& type_args_;
};

void ClassFinalizer::RehashTypes() {
  auto T = Thread::Current();
  auto Z = T->zone();
  auto IG = T->isolate_group();

  // Clear all cached hash values.
  {
    HeapIterationScope his(T);
    ClearTypeHashVisitor visitor(Z);
    IG->heap()->VisitObjects(&visitor);
  }

  // Rehash the canonical Types table.
  ObjectStore* object_store = IG->object_store();
  Array& types = Array::Handle(Z);
  Type& type = Type::Handle(Z);
  {
    CanonicalTypeSet types_table(Z, object_store->canonical_types());
    types = HashTables::ToArray(types_table, false);
    types_table.Release();
  }

  intptr_t dict_size = Utils::RoundUpToPowerOfTwo(types.Length() * 4 / 3);
  CanonicalTypeSet types_table(
      Z, HashTables::New<CanonicalTypeSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < types.Length(); i++) {
    type ^= types.At(i);
    bool present = types_table.Insert(type);
    ASSERT(!present);
  }
  object_store->set_canonical_types(types_table.Release());

  // Rehash the canonical FunctionTypes table.
  Array& function_types = Array::Handle(Z);
  FunctionType& function_type = FunctionType::Handle(Z);
  {
    CanonicalFunctionTypeSet function_types_table(
        Z, object_store->canonical_function_types());
    function_types = HashTables::ToArray(function_types_table, false);
    function_types_table.Release();
  }

  dict_size = Utils::RoundUpToPowerOfTwo(function_types.Length() * 4 / 3);
  CanonicalFunctionTypeSet function_types_table(
      Z, HashTables::New<CanonicalFunctionTypeSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < function_types.Length(); i++) {
    function_type ^= function_types.At(i);
    bool present = function_types_table.Insert(function_type);
    ASSERT(!present);
  }
  object_store->set_canonical_function_types(function_types_table.Release());

  // Rehash the canonical RecordTypes table.
  Array& record_types = Array::Handle(Z);
  RecordType& record_type = RecordType::Handle(Z);
  {
    CanonicalRecordTypeSet record_types_table(
        Z, object_store->canonical_record_types());
    record_types = HashTables::ToArray(record_types_table, false);
    record_types_table.Release();
  }

  dict_size = Utils::RoundUpToPowerOfTwo(record_types.Length() * 4 / 3);
  CanonicalRecordTypeSet record_types_table(
      Z, HashTables::New<CanonicalRecordTypeSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < record_types.Length(); i++) {
    record_type ^= record_types.At(i);
    bool present = record_types_table.Insert(record_type);
    ASSERT(!present);
  }
  object_store->set_canonical_record_types(record_types_table.Release());

  // Rehash the canonical TypeParameters table.
  Array& typeparams = Array::Handle(Z);
  TypeParameter& typeparam = TypeParameter::Handle(Z);
  {
    CanonicalTypeParameterSet typeparams_table(
        Z, object_store->canonical_type_parameters());
    typeparams = HashTables::ToArray(typeparams_table, false);
    typeparams_table.Release();
  }

  dict_size = Utils::RoundUpToPowerOfTwo(typeparams.Length() * 4 / 3);
  CanonicalTypeParameterSet typeparams_table(
      Z, HashTables::New<CanonicalTypeParameterSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < typeparams.Length(); i++) {
    typeparam ^= typeparams.At(i);
    bool present = typeparams_table.Insert(typeparam);
    ASSERT(!present);
  }
  object_store->set_canonical_type_parameters(typeparams_table.Release());

  // Rehash the canonical TypeArguments table.
  Array& typeargs = Array::Handle(Z);
  TypeArguments& typearg = TypeArguments::Handle(Z);
  {
    CanonicalTypeArgumentsSet typeargs_table(
        Z, object_store->canonical_type_arguments());
    typeargs = HashTables::ToArray(typeargs_table, false);
    typeargs_table.Release();
  }

  // The canonical constant tables use canonical hashcodes which can change
  // due to cid-renumbering.
  IG->RehashConstants();

  dict_size = Utils::RoundUpToPowerOfTwo(typeargs.Length() * 4 / 3);
  CanonicalTypeArgumentsSet typeargs_table(
      Z, HashTables::New<CanonicalTypeArgumentsSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < typeargs.Length(); i++) {
    typearg ^= typeargs.At(i);
    bool present = typeargs_table.Insert(typearg);
    ASSERT(!present);
  }
  object_store->set_canonical_type_arguments(typeargs_table.Release());
}

void ClassFinalizer::ClearAllCode(bool including_nonchanging_cids) {
  auto const thread = Thread::Current();
  auto const isolate_group = thread->isolate_group();
  SafepointWriteRwLocker ml(thread, isolate_group->program_lock());
  StackZone stack_zone(thread);
  auto const zone = thread->zone();

  class ClearCodeVisitor : public FunctionVisitor {
   public:
    ClearCodeVisitor(Zone* zone, bool force)
        : force_(force),
          pool_(ObjectPool::Handle(zone)),
          entry_(Object::Handle(zone)) {}

    void VisitClass(const Class& cls) {
      if (force_ || cls.id() >= kNumPredefinedCids) {
        cls.DisableAllocationStub();
      }
    }

    void VisitFunction(const Function& function) {
      function.ClearCode();
      function.ClearICDataArray();
    }

   private:
    const bool force_;
    ObjectPool& pool_;
    Object& entry_;
  };

  ClearCodeVisitor visitor(zone, including_nonchanging_cids);
  ProgramVisitor::WalkProgram(zone, isolate_group, &visitor);

  // Apart from normal function code and allocation stubs we have two global
  // code objects to clear.
  if (including_nonchanging_cids) {
    auto object_store = isolate_group->object_store();
    auto& null_code = Code::Handle(zone);
    object_store->set_build_generic_method_extractor_code(null_code);
    object_store->set_build_nongeneric_method_extractor_code(null_code);
  }
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
