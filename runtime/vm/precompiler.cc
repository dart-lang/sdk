// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/precompiler.h"

#include "vm/compiler.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/symbols.h"

namespace dart {


#define I (isolate())
#define Z (zone())


DEFINE_FLAG(bool, trace_precompiler, false, "Trace precompiler.");


static void Jump(const Error& error) {
  Thread::Current()->long_jump_base()->Jump(1, error);
}


RawError* Precompiler::CompileAll() {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Precompiler precompiler(Thread::Current());
    precompiler.DoCompileAll();
    return Error::null();
  } else {
    Isolate* isolate = Isolate::Current();
    const Error& error = Error::Handle(isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
}


Precompiler::Precompiler(Thread* thread) :
  thread_(thread),
  zone_(thread->zone()),
  isolate_(thread->isolate()),
  changed_(false),
  function_count_(0),
  class_count_(0),
  selector_count_(0),
  dropped_function_count_(0),
  libraries_(GrowableObjectArray::Handle(Z, I->object_store()->libraries())),
  pending_functions_(GrowableObjectArray::Handle(Z,
                                                 GrowableObjectArray::New())),
  collected_closures_(GrowableObjectArray::Handle(Z, I->collected_closures())),
  sent_selectors_(Z),
  error_(Error::Handle(Z)) {
}


void Precompiler::DoCompileAll() {
  LogBlock lb(thread_);

  // Drop all existing code so we can use the presence of code as an indicator
  // that we have already looked for the function's callees.
  ClearAllCode();

  // Start with the allocations and invocations that happen from C++.
  AddRoots();

  // TODO(rmacnak): Eagerly add field-invocation functions to all signature
  // classes so closure calls don't go through the runtime.

  // Compile newly found targets and add their callees until we reach a fixed
  // point.
  Iterate();

  CleanUp();

  if (FLAG_trace_precompiler) {
    ISL_Print("Precompiled %" Pd " functions, %" Pd " dynamic types,"
              " %" Pd " dynamic selectors.\n Dropped %" Pd " functions.\n",
              function_count_,
              class_count_,
              selector_count_,
              dropped_function_count_);
  }

  I->set_compilation_allowed(false);
}


void Precompiler::ClearAllCode() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      error_ = cls.EnsureIsFinalized(I);
      if (!error_.IsNull()) {
        Jump(error_);
      }
    }
  }

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      functions = cls.functions();
      for (intptr_t i = 0; i < functions.Length(); i++) {
        function ^= functions.At(i);
        function.ClearCode();
      }
    }
  }
}


void Precompiler::AddRoots() {
  // Note that <rootlibrary>.main is not a root. The appropriate main will be
  // discovered through _getMainClosure.

  AddSelector(Symbols::NoSuchMethod());

  AddSelector(Symbols::Call());  // For speed, not correctness.

  // Allocated from C++.
  static const intptr_t kExternallyAllocatedCids[] = {
    kBoolCid,
    kNullCid,

    kSmiCid,
    kMintCid,
    kBigintCid,
    kDoubleCid,

    kOneByteStringCid,
    kTwoByteStringCid,
    kExternalOneByteStringCid,
    kExternalTwoByteStringCid,

    kArrayCid,
    kImmutableArrayCid,
    kGrowableObjectArrayCid,
    kLinkedHashMapCid,

    kTypedDataUint8ClampedArrayCid,
    kTypedDataUint8ArrayCid,
    kTypedDataUint16ArrayCid,
    kTypedDataUint32ArrayCid,
    kTypedDataUint64ArrayCid,

    kTypedDataInt8ArrayCid,
    kTypedDataInt16ArrayCid,
    kTypedDataInt32ArrayCid,
    kTypedDataInt64ArrayCid,

    kExternalTypedDataUint8ArrayCid,

    kTypedDataFloat32ArrayCid,
    kTypedDataFloat64ArrayCid,

    kTypedDataFloat32x4ArrayCid,
    kTypedDataInt32x4ArrayCid,
    kTypedDataFloat64x2ArrayCid,

    kInt32x4Cid,
    kFloat32x4Cid,
    kFloat64x2Cid,

    kTypeCid,
    kTypeRefCid,
    kTypeParameterCid,
    kBoundedTypeCid,
    kLibraryPrefixCid,

    kJSRegExpCid,
    kUserTagCid,
    kStacktraceCid,
    kWeakPropertyCid,
    kCapabilityCid,
    ReceivePort::kClassId,
    SendPort::kClassId,

    kIllegalCid
  };

  Class& cls = Class::Handle(Z);
  for (intptr_t i = 0; kExternallyAllocatedCids[i] != kIllegalCid; i++) {
    cls = isolate()->class_table()->At(kExternallyAllocatedCids[i]);
    AddClass(cls);
  }

  static const struct {
    const char* library_;
    const char* class_;
    const char* function_;
  } kExternallyCalled[] = {
    { "dart:_builtin", "::", "_getMainClosure" },
    { "dart:_builtin", "::", "_getPrintClosure" },
    { "dart:_builtin", "::", "_getUriBaseClosure" },
    { "dart:_builtin", "::", "_resolveUri" },
    { "dart:_builtin", "::", "_setWorkingDirectory" },
    { "dart:async", "::", "_setScheduleImmediateClosure" },
    { "dart:core", "_InternalError", "_InternalError." },
    { "dart:core", "_InvocationMirror", "_allocateInvocationMirror" },
    { "dart:io", "::", "_makeUint8ListView" },
    { "dart:io", "::", "_makeDatagram" },
    { "dart:io", "CertificateException", "CertificateException." },
    { "dart:io", "HandshakeException", "HandshakeException." },
    { "dart:io", "TlsException", "TlsException." },
    { "dart:io", "X509Certificate", "X509Certificate." },
    { "dart:io", "_ExternalBuffer", "set:data" },
    { "dart:io", "_Platform", "set:_nativeScript" },
    { "dart:io", "_ProcessStartStatus", "set:_errorCode" },
    { "dart:io", "_ProcessStartStatus", "set:_errorMessage" },
    { "dart:io", "_SecureFilterImpl", "get:ENCRYPTED_SIZE" },
    { "dart:io", "_SecureFilterImpl", "get:SIZE" },
    { "dart:isolate", "::", "_getIsolateScheduleImmediateClosure" },
    { "dart:isolate", "::", "_startMainIsolate" },
    { "dart:isolate", "_RawReceivePortImpl", "_handleMessage" },
    { "dart:isolate", "_RawReceivePortImpl", "_lookupHandler" },
    { "dart:vmservice", "::", "_registerIsolate" },
    { "dart:vmservice", "::", "boot" },
    { "dart:vmservice_io", "::", "_addResource" },
    { "dart:vmservice_io", "::", "main" },

    // Cf. Exceptions::Create
    { "dart:core", "RangeError", "RangeError." },
    { "dart:core", "RangeError", "RangeError.range" },
    { "dart:core", "ArgumentError", "ArgumentError." },
    { "dart:core", "NoSuchMethodError", "NoSuchMethodError._withType" },
    { "dart:core", "FormatException", "FormatException." },
    { "dart:core", "UnsupportedError", "UnsupportedError." },
    { "dart:core", "NullThrownError", "NullThrownError." },
    { "dart:isolate", "IsolateSpawnException", "IsolateSpawnException." },
    { "dart:isolate", "_IsolateUnhandledException",
                      "_IsolateUnhandledException." },
    { "dart:core", "_JavascriptIntegerOverflowError",
                   "_JavascriptIntegerOverflowError." },
    { "dart:core", "_JavascriptCompatibilityError",
                   "_JavascriptCompatibilityError." },
    { "dart:core", "AssertionError", "AssertionError." },
    { "dart:core", "_CastError", "_CastError._create" },
    { "dart:core", "_TypeError", "_TypeError._create" },
    { "dart:core", "FallThroughError", "FallThroughError._create" },
    { "dart:core", "AbstractClassInstantiationError",
                   "AbstractClassInstantiationError._create" },
    { "dart:core", "CyclicInitializationError",
                   "CyclicInitializationError." },
    { "dart:core", "StackOverflowError", "StackOverflowError." },
    { "dart:core", "OutOfMemoryError", "OutOfMemoryError." },
    { NULL, NULL, NULL }
  };

  Library& lib = Library::Handle(Z);
  Function& func = Function::Handle(Z);
  String& library_name = String::Handle(Z);
  String& class_name = String::Handle(Z);
  String& function_name = String::Handle(Z);
  for (intptr_t i = 0; kExternallyCalled[i].library_ != NULL; i++) {
    library_name = Symbols::New(kExternallyCalled[i].library_);
    class_name = Symbols::New(kExternallyCalled[i].class_);
    function_name = Symbols::New(kExternallyCalled[i].function_);

    lib = Library::LookupLibrary(library_name);
    if (lib.IsNull()) {
      if (FLAG_trace_precompiler) {
        ISL_Print("WARNING: Missing %s\n", kExternallyCalled[i].library_);
      }
      continue;
    }

    if (class_name.raw() == Symbols::TopLevel().raw()) {
      func = lib.LookupFunctionAllowPrivate(function_name);
    } else {
      cls = lib.LookupClassAllowPrivate(class_name);
      if (cls.IsNull()) {
        if (FLAG_trace_precompiler) {
          ISL_Print("WARNING: Missing %s %s\n",
                    kExternallyCalled[i].library_,
                    kExternallyCalled[i].class_);
        }
        continue;
      }

      ASSERT(!cls.IsNull());
      func = cls.LookupFunctionAllowPrivate(function_name);
    }

    if (func.IsNull()) {
      if (FLAG_trace_precompiler) {
        ISL_Print("WARNING: Missing %s %s %s\n",
                  kExternallyCalled[i].library_,
                  kExternallyCalled[i].class_,
                  kExternallyCalled[i].function_);
      }
      continue;
    }

    AddFunction(func);
  }
}


void Precompiler::Iterate() {
  Function& function = Function::Handle(Z);

  while (changed_) {
    changed_ = false;

    while (pending_functions_.Length() > 0) {
      function ^= pending_functions_.RemoveLast();
      ProcessFunction(function);
    }

    CheckForNewDynamicFunctions();

    // Drain collected_closures last because additions to this list come from
    // outside the Precompiler and so do not flip our changed_ flag.
    while (collected_closures_.Length() > 0) {
      function ^= collected_closures_.RemoveLast();
      ProcessFunction(function);
    }
  }
}


void Precompiler::CleanUp() {
  I->set_collected_closures(GrowableObjectArray::Handle(Z));

  DropUncompiledFunctions();

  // TODO(rmacnak): DropEmptyClasses();
}


void Precompiler::ProcessFunction(const Function& function) {
  if (!function.HasCode()) {
    function_count_++;

    if (FLAG_trace_precompiler) {
      ISL_Print("Precompiling %" Pd " %s (%" Pd ", %s)\n",
                function_count_,
                function.ToLibNamePrefixedQualifiedCString(),
                function.token_pos(),
                Function::KindToCString(function.kind()));
    }

    ASSERT(!function.is_abstract());
    ASSERT(!function.IsRedirectingFactory());

    error_ = Compiler::CompileFunction(thread_, function);
    if (!error_.IsNull()) {
      Jump(error_);
    }
  }

  ASSERT(function.HasCode());
  AddCalleesOf(function);
}


void Precompiler::AddCalleesOf(const Function& function) {
  ASSERT(function.HasCode());

  const Code& code = Code::Handle(Z, function.CurrentCode());

  const Array& table = Array::Handle(Z, code.static_calls_target_table());
  Object& entry = Object::Handle(Z);
  Function& target = Function::Handle(Z);
  for (intptr_t i = 0; i < table.Length(); i++) {
    entry = table.At(i);
    if (entry.IsFunction()) {
      target ^= table.At(i);
      AddFunction(target);
    }
  }

#if defined(TARGET_ARCH_IA32)
  FATAL("Callee scanning unimplemented for IA32");
#endif

  const ObjectPool& pool = ObjectPool::Handle(Z, code.GetObjectPool());
  ICData& call_site = ICData::Handle(Z);
  String& selector = String::Handle(Z);
  Field& field = Field::Handle(Z);
  Class& cls = Class::Handle(Z);
  for (intptr_t i = 0; i < pool.Length(); i++) {
    if (pool.InfoAt(i) == ObjectPool::kTaggedObject) {
      entry = pool.ObjectAt(i);
      if (entry.IsICData()) {
        call_site ^= entry.raw();
        if (call_site.NumberOfChecks() == 1) {
          // Probably a static call.
          target = call_site.GetTargetAt(0);
          AddFunction(target);
          if (!target.is_static()) {
            // Super call (should not enqueue selector) or dynamic call with a
            // CHA prediction (should enqueue selector).
            selector = call_site.target_name();
            AddSelector(selector);
          }
        } else {
          // A dynamic call.
          selector = call_site.target_name();
          AddSelector(selector);
        }
      } else if (entry.IsField()) {
        // Potential need for field initializer.
        field ^= entry.raw();
        AddField(field);
      } else if (entry.IsInstance()) {
        // Potential const object.
        cls = entry.clazz();
        AddClass(cls);
      }
    }
  }
}


void Precompiler::AddField(const Field& field) {
  if (field.is_static()) {
    // Potential const object. Uninitialized field will harmlessly do a
    // redundant add of the Null class.
    const Object& value = Object::Handle(Z, field.value());
    const Class& cls = Class::Handle(Z, value.clazz());
    AddClass(cls);

    if (field.has_initializer()) {
      if (field.initializer() != Function::null()) return;

      if (FLAG_trace_precompiler) {
        ISL_Print("Precompiling initializer for %s\n", field.ToCString());
      }
      Compiler::CompileStaticInitializer(field);

      const Function& function = Function::Handle(Z, field.initializer());
      AddCalleesOf(function);
    }
  }
}


void Precompiler::AddFunction(const Function& function) {
  if (function.HasCode()) return;

  pending_functions_.Add(function);
  changed_ = true;
}


bool Precompiler::IsSent(const String& selector) {
  return sent_selectors_.Includes(selector);
}


void Precompiler::AddSelector(const String& selector) {
  if (!IsSent(selector)) {
    sent_selectors_.Add(selector);
    selector_count_++;
    changed_ = true;

    if (FLAG_trace_precompiler) {
      ISL_Print("Enqueueing selector %" Pd " %s\n",
                selector_count_,
                selector.ToCString());
    }

    if (!Field::IsGetterName(selector) &&
        !Field::IsSetterName(selector)) {
      // Regular method may be call-through-getter.
      const String& getter = String::Handle(Field::GetterSymbol(selector));
      AddSelector(getter);
    }
  }
}


void Precompiler::AddClass(const Class& cls) {
  if (cls.is_allocated()) return;

  class_count_++;
  cls.set_is_allocated();
  changed_ = true;

  if (FLAG_trace_precompiler) {
    ISL_Print("Allocation %" Pd " %s\n", class_count_, cls.ToCString());
  }

  const Class& superclass = Class::Handle(cls.SuperClass());
  if (!superclass.IsNull()) {
    AddClass(superclass);
  }
}


void Precompiler::CheckForNewDynamicFunctions() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  String& selector = String::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      if (!cls.is_allocated()) {
        bool has_compiled_constructor = false;
        if (cls.allocation_stub() != Code::null()) {
          // Regular objects.
          has_compiled_constructor = true;
        } else if (cls.is_synthesized_class()) {
          // Enums.
          has_compiled_constructor = true;
        } else {
          // Objects only allocated via const constructors, and not stored in a
          // static field or code.
          // E.g. A in
          //   class A {
          //     const A();
          //     toString() => "Don't drop me!";
          //   }
          //   class B {
          //     const a = const A();
          //     const B();
          //     static const theB = const B();
          //   }
          //   main() => print(B.theB.a);
          functions = cls.functions();
          for (intptr_t k = 0; k < functions.Length(); k++) {
            function ^= functions.At(k);
            if (function.IsGenerativeConstructor() &&
                function.HasCode()) {
              has_compiled_constructor = true;
              break;
            }
          }
        }
        if (!has_compiled_constructor) {
          continue;
        }
        AddClass(cls);
      }

      functions = cls.functions();
      for (intptr_t k = 0; k < functions.Length(); k++) {
        function ^= functions.At(k);

        if (function.is_static() || function.is_abstract()) continue;

        // Don't bail out early if there is already code because we may discover
        // the corresponding getter selector is sent in some later iteration.
        // if (function.HasCode()) continue;

        selector = function.name();
        if (IsSent(selector)) {
          AddFunction(function);
        }

        if (function.kind() == RawFunction::kRegularFunction &&
            !Field::IsGetterName(selector) &&
            !Field::IsSetterName(selector)) {
          selector = Field::GetterSymbol(selector);
          if (IsSent(selector)) {
            function = function.ImplicitClosureFunction();
            AddFunction(function);
          }
        }
      }
    }
  }
}


void Precompiler::DropUncompiledFunctions() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  GrowableObjectArray& retained_functions = GrowableObjectArray::Handle(Z);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }

      functions = cls.functions();
      retained_functions = GrowableObjectArray::New();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        if (function.HasCode()) {
          retained_functions.Add(function);
        } else {
          dropped_function_count_++;
          if (FLAG_trace_precompiler) {
            ISL_Print("Precompilation dropping %s\n",
                      function.ToLibNamePrefixedQualifiedCString());
          }
        }
      }

      functions = Array::New(retained_functions.Length(), Heap::kOld);
      for (intptr_t j = 0; j < retained_functions.Length(); j++) {
        function ^= retained_functions.At(j);
        functions.SetAt(j, function);
      }
      cls.SetFunctions(functions);

      closures = cls.closures();
      if (!closures.IsNull()) {
        for (intptr_t j = 0; j < closures.Length(); j++) {
          function ^= closures.At(j);
          ASSERT(function.HasCode());
        }
      }
    }
  }
}

}  // namespace dart
