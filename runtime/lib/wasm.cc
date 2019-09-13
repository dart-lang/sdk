// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifdef DART_ENABLE_WASM

#include <memory>
#include <sstream>

#include "platform/unicode.h"
#include "third_party/wasmer/wasmer.hh"
#include "vm/bootstrap_natives.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"

namespace dart {

static void ThrowIfFailed(wasmer_result_t status) {
  if (status == wasmer_result_t::WASMER_OK) return;
  int len = wasmer_last_error_length();
  auto error = std::unique_ptr<char[]>(new char[len]);
  int read_len = wasmer_last_error_message(error.get(), len);
  ASSERT(read_len == len);
  TransitionNativeToVM transition(Thread::Current());
  Exceptions::ThrowArgumentError(
      String::Handle(String::NewFormatted("Wasmer error: %s", error.get())));
}

template <typename T>
static void Finalize(void* isolate_callback_data,
                     Dart_WeakPersistentHandle handle,
                     void* peer) {
  delete reinterpret_cast<T*>(peer);
}

static std::unique_ptr<char[]> ToUTF8(const String& str) {
  const intptr_t str_size = Utf8::Length(str);
  auto str_raw = std::unique_ptr<char[]>(new char[str_size + 1]);
  str.ToUTF8(reinterpret_cast<uint8_t*>(str_raw.get()), str_size);
  str_raw[str_size] = '\0';
  return str_raw;
}

static bool ToWasmValue(const Number& value,
                        classid_t type,
                        wasmer_value_t* out) {
  switch (type) {
    case kFfiInt32Cid:
      if (!value.IsInteger()) return false;
      out->tag = wasmer_value_tag::WASM_I32;
      out->value.I32 = Integer::Cast(value).AsInt64Value();
      return true;
    case kFfiInt64Cid:
      if (!value.IsInteger()) return false;
      out->tag = wasmer_value_tag::WASM_I64;
      out->value.I64 = Integer::Cast(value).AsInt64Value();
      return true;
    case kFfiFloatCid:
      if (!value.IsDouble()) return false;
      out->tag = wasmer_value_tag::WASM_F32;
      out->value.F32 = Double::Cast(value).value();
      return true;
    case kFfiDoubleCid:
      if (!value.IsDouble()) return false;
      out->tag = wasmer_value_tag::WASM_F64;
      out->value.F64 = Double::Cast(value).value();
      return true;
    default:
      return false;
  }
}

static RawObject* ToDartObject(wasmer_value_t ret) {
  switch (ret.tag) {
    case wasmer_value_tag::WASM_I32:
      return Integer::New(ret.value.I32);
    case wasmer_value_tag::WASM_I64:
      return Integer::New(ret.value.I64);
    case wasmer_value_tag::WASM_F32:
      return Double::New(ret.value.F32);
    case wasmer_value_tag::WASM_F64:
      return Double::New(ret.value.F64);
    default:
      FATAL("Unknown WASM type");
      return nullptr;
  }
}

class WasmModule {
 public:
  WasmModule(uint8_t* data, intptr_t len) {
    ThrowIfFailed(wasmer_compile(&_module, data, len));
  }

  ~WasmModule() { wasmer_module_destroy(_module); }
  wasmer_module_t* module() { return _module; }

 private:
  wasmer_module_t* _module;

  DISALLOW_COPY_AND_ASSIGN(WasmModule);
};

class WasmMemory {
 public:
  WasmMemory(uint32_t init, int64_t max) {
    wasmer_limits_t descriptor;
    descriptor.min = init;
    if (max < 0) {
      descriptor.max.has_some = false;
    } else {
      descriptor.max.has_some = true;
      descriptor.max.some = max;
    }
    ThrowIfFailed(wasmer_memory_new(&_memory, descriptor));
  }

  ~WasmMemory() { wasmer_memory_destroy(_memory); }
  wasmer_memory_t* memory() { return _memory; }

  void Grow(intptr_t delta) {
    ThrowIfFailed(wasmer_memory_grow(_memory, delta));
  }

  RawExternalTypedData* ToExternalTypedData() {
    uint8_t* data = wasmer_memory_data(_memory);
    uint32_t size = wasmer_memory_data_length(_memory);
    return ExternalTypedData::New(kExternalTypedDataUint8ArrayCid, data, size);
  }

 private:
  wasmer_memory_t* _memory;

  DISALLOW_COPY_AND_ASSIGN(WasmMemory);
};

class WasmImports {
 public:
  WasmImports(std::unique_ptr<char[]> module_name)
      : _module_name(std::move(module_name)) {}

  ~WasmImports() {
    for (wasmer_global_t* global : _globals) {
      wasmer_global_destroy(global);
    }
    for (const char* name : _import_names) {
      delete[] name;
    }
  }

  size_t NumImports() const { return _imports.length(); }
  wasmer_import_t* RawImports() { return _imports.data(); }

  void AddMemory(std::unique_ptr<char[]> name, WasmMemory* memory) {
    AddImport(std::move(name), wasmer_import_export_kind::WASM_MEMORY)->memory =
        memory->memory();
  }

  void AddGlobal(std::unique_ptr<char[]> name,
                 wasmer_value_t value,
                 bool mutable_) {
    wasmer_global_t* global = wasmer_global_new(value, mutable_);
    _globals.Add(global);
    AddImport(std::move(name), wasmer_import_export_kind::WASM_GLOBAL)->global =
        global;
  }

 private:
  std::unique_ptr<char[]> _module_name;
  MallocGrowableArray<const char*> _import_names;
  MallocGrowableArray<wasmer_global_t*> _globals;
  MallocGrowableArray<wasmer_import_t> _imports;

  wasmer_import_export_value* AddImport(std::unique_ptr<char[]> name,
                                        wasmer_import_export_kind tag) {
    wasmer_import_t import;
    import.module_name.bytes =
        reinterpret_cast<const uint8_t*>(_module_name.get());
    import.module_name.bytes_len = (uint32_t)strlen(_module_name.get());
    import.import_name.bytes = reinterpret_cast<const uint8_t*>(name.get());
    import.import_name.bytes_len = (uint32_t)strlen(name.get());
    import.tag = tag;
    _import_names.Add(name.release());
    _imports.Add(import);
    return &_imports.Last().value;
  }

  DISALLOW_COPY_AND_ASSIGN(WasmImports);
};

class WasmFunction {
 public:
  WasmFunction(MallocGrowableArray<classid_t> args,
               classid_t ret,
               const wasmer_export_func_t* fn)
      : _args(std::move(args)), _ret(ret), _fn(fn) {}
  bool IsVoid() const { return _ret == kFfiVoidCid; }
  const MallocGrowableArray<classid_t>& args() const { return _args; }

  bool SignatureMatches(const MallocGrowableArray<classid_t>& dart_args,
                        classid_t dart_ret) {
    if (dart_args.length() != _args.length()) {
      return false;
    }
    for (intptr_t i = 0; i < dart_args.length(); ++i) {
      if (dart_args[i] != _args[i]) {
        return false;
      }
    }
    return dart_ret == _ret;
  }

  wasmer_value_t Call(const wasmer_value_t* params) {
    wasmer_value_t result;
    ThrowIfFailed(wasmer_export_func_call(_fn, params, _args.length(), &result,
                                          IsVoid() ? 0 : 1));
    return result;
  }

  void Print(std::ostream& o, const char* name) const {
    PrintFfiType(o, _ret);
    o << ' ' << name << '(';
    for (intptr_t i = 0; i < _args.length(); ++i) {
      if (i > 0) o << ", ";
      PrintFfiType(o, _args[i]);
    }
    o << ')';
  }

 private:
  MallocGrowableArray<classid_t> _args;
  const classid_t _ret;
  const wasmer_export_func_t* _fn;

  static void PrintFfiType(std::ostream& o, classid_t type) {
    switch (type) {
      case kFfiInt32Cid:
        o << "i32";
        break;
      case kFfiInt64Cid:
        o << "i64";
        break;
      case kFfiFloatCid:
        o << "f32";
        break;
      case kFfiDoubleCid:
        o << "f64";
        break;
      case kFfiVoidCid:
        o << "void";
        break;
    }
  }
};

class WasmInstance {
 public:
  explicit WasmInstance(WasmModule* module, WasmImports* imports) {
    // Instantiate module.
    ThrowIfFailed(wasmer_module_instantiate(module->module(), &_instance,
                                            imports->RawImports(),
                                            imports->NumImports()));

    // Load all functions.
    wasmer_instance_exports(_instance, &_exports);
    intptr_t num_exports = wasmer_exports_len(_exports);
    for (intptr_t i = 0; i < num_exports; ++i) {
      wasmer_export_t* exp = wasmer_exports_get(_exports, i);
      if (wasmer_export_kind(exp) == wasmer_import_export_kind::WASM_FUNCTION) {
        AddFunction(exp);
      }
    }
  }

  ~WasmInstance() {
    auto it = _functions.GetIterator();
    for (auto* kv = it.Next(); kv; kv = it.Next()) {
      delete[] kv->key;
      delete kv->value;
    }
    wasmer_exports_destroy(_exports);
    wasmer_instance_destroy(_instance);
  }

  WasmFunction* GetFunction(const char* name,
                            const MallocGrowableArray<classid_t>& dart_args,
                            classid_t dart_ret) {
    WasmFunction* fn = _functions.LookupValue(name);
    if (fn == nullptr) {
      Exceptions::ThrowArgumentError(String::Handle(String::NewFormatted(
          "Couldn't find a function called %s in the WASM module's exports",
          name)));
      return nullptr;
    }
    if (!fn->SignatureMatches(dart_args, dart_ret)) {
      std::stringstream sig;
      fn->Print(sig, name);
      Exceptions::ThrowArgumentError(String::Handle(String::NewFormatted(
          "Function signature doesn't match: %s", sig.str().c_str())));
    }
    return fn;
  }

  void PrintFunctions(std::ostream& o) const {
    o << '{' << std::endl;
    auto it = _functions.GetIterator();
    for (auto* kv = it.Next(); kv; kv = it.Next()) {
      kv->value->Print(o, kv->key);
      o << std::endl;
    }
    o << '}' << std::endl;
  }

 private:
  wasmer_instance_t* _instance;
  wasmer_exports_t* _exports;
  MallocDirectChainedHashMap<CStringKeyValueTrait<WasmFunction*>> _functions;

  static classid_t ToFfiType(wasmer_value_tag wasm_type) {
    switch (wasm_type) {
      case wasmer_value_tag::WASM_I32:
        return kFfiInt32Cid;
      case wasmer_value_tag::WASM_I64:
        return kFfiInt64Cid;
      case wasmer_value_tag::WASM_F32:
        return kFfiFloatCid;
      case wasmer_value_tag::WASM_F64:
        return kFfiDoubleCid;
    }
    FATAL("Unknown WASM type");
    return 0;
  }

  void AddFunction(wasmer_export_t* exp) {
    const wasmer_export_func_t* fn = wasmer_export_to_func(exp);

    uint32_t num_rets;
    ThrowIfFailed(wasmer_export_func_returns_arity(fn, &num_rets));
    ASSERT(num_rets <= 1);
    wasmer_value_tag wasm_ret;
    ThrowIfFailed(wasmer_export_func_returns(fn, &wasm_ret, num_rets));
    classid_t ret = num_rets == 0 ? kFfiVoidCid : ToFfiType(wasm_ret);

    uint32_t num_args;
    ThrowIfFailed(wasmer_export_func_params_arity(fn, &num_args));
    auto wasm_args =
        std::unique_ptr<wasmer_value_tag[]>(new wasmer_value_tag[num_args]);
    ThrowIfFailed(wasmer_export_func_params(fn, wasm_args.get(), num_args));
    MallocGrowableArray<classid_t> args;
    for (intptr_t i = 0; i < num_args; ++i) {
      args.Add(ToFfiType(wasm_args[i]));
    }

    wasmer_byte_array name_bytes = wasmer_export_name(exp);
    char* name = new char[name_bytes.bytes_len + 1];
    for (size_t i = 0; i < name_bytes.bytes_len; ++i) {
      name[i] = name_bytes.bytes[i];
    }
    name[name_bytes.bytes_len] = '\0';

    _functions.Insert({name, new WasmFunction(std::move(args), ret, fn)});
  }

  DISALLOW_COPY_AND_ASSIGN(WasmInstance);
};

DEFINE_NATIVE_ENTRY(Wasm_initModule, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, mod_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, data, arguments->NativeArgAt(1));

  ASSERT(mod_wrap.NumNativeFields() == 1);

  std::unique_ptr<uint8_t[]> data_copy;
  intptr_t len;
  {
    NoSafepointScope scope(thread);
    len = data.LengthInBytes();
    data_copy = std::unique_ptr<uint8_t[]>(new uint8_t[len]);
    // The memory does not overlap.
    memcpy(data_copy.get(), data.DataAddr(0), len);  // NOLINT
  }

  WasmModule* module;
  {
    TransitionVMToNative transition(thread);
    module = new WasmModule(data_copy.get(), len);
  }

  mod_wrap.SetNativeField(0, reinterpret_cast<intptr_t>(module));
  FinalizablePersistentHandle::New(thread->isolate(), mod_wrap, module,
                                   Finalize<WasmModule>, sizeof(WasmModule));

  return Object::null();
}

DEFINE_NATIVE_ENTRY(Wasm_initImports, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, imp_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, module_name, arguments->NativeArgAt(1));

  ASSERT(imp_wrap.NumNativeFields() == 1);

  WasmImports* imports = new WasmImports(ToUTF8(module_name));

  imp_wrap.SetNativeField(0, reinterpret_cast<intptr_t>(imports));
  FinalizablePersistentHandle::New(thread->isolate(), imp_wrap, imports,
                                   Finalize<WasmImports>, sizeof(WasmImports));

  return Object::null();
}

DEFINE_NATIVE_ENTRY(Wasm_addMemoryImport, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, imp_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, mem_wrap, arguments->NativeArgAt(2));

  ASSERT(imp_wrap.NumNativeFields() == 1);
  ASSERT(mem_wrap.NumNativeFields() == 1);

  WasmImports* imports =
      reinterpret_cast<WasmImports*>(imp_wrap.GetNativeField(0));
  WasmMemory* memory =
      reinterpret_cast<WasmMemory*>(mem_wrap.GetNativeField(0));

  imports->AddMemory(ToUTF8(name), memory);

  return Object::null();
}

DEFINE_NATIVE_ENTRY(Wasm_addGlobalImport, 0, 5) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, imp_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Number, value, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Type, type, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, mutable_, arguments->NativeArgAt(4));

  ASSERT(imp_wrap.NumNativeFields() == 1);

  WasmImports* imports =
      reinterpret_cast<WasmImports*>(imp_wrap.GetNativeField(0));
  wasmer_value_t wasm_value;
  if (!ToWasmValue(value, type.type_class_id(), &wasm_value)) {
    Exceptions::ThrowArgumentError(String::Handle(String::NewFormatted(
        "Can't convert dart value to WASM global variable")));
  }

  imports->AddGlobal(ToUTF8(name), wasm_value, mutable_.value());

  return Object::null();
}

DEFINE_NATIVE_ENTRY(Wasm_initMemory, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, mem_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, init, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(Integer, max, arguments->NativeArgAt(2));

  ASSERT(mem_wrap.NumNativeFields() == 1);

  WasmMemory* memory = new WasmMemory(init.AsInt64Value(),
                                      max.IsNull() ? -1 : max.AsInt64Value());
  mem_wrap.SetNativeField(0, reinterpret_cast<intptr_t>(memory));
  FinalizablePersistentHandle::New(thread->isolate(), mem_wrap, memory,
                                   Finalize<WasmMemory>, sizeof(WasmMemory));
  return memory->ToExternalTypedData();
}

DEFINE_NATIVE_ENTRY(Wasm_growMemory, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, mem_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, delta, arguments->NativeArgAt(1));

  ASSERT(mem_wrap.NumNativeFields() == 1);

  WasmMemory* memory =
      reinterpret_cast<WasmMemory*>(mem_wrap.GetNativeField(0));
  memory->Grow(delta.AsInt64Value());
  return memory->ToExternalTypedData();
}

DEFINE_NATIVE_ENTRY(Wasm_initInstance, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, inst_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, mod_wrap, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, imp_wrap, arguments->NativeArgAt(2));

  ASSERT(inst_wrap.NumNativeFields() == 1);
  ASSERT(mod_wrap.NumNativeFields() == 1);
  ASSERT(imp_wrap.NumNativeFields() == 1);

  WasmModule* module =
      reinterpret_cast<WasmModule*>(mod_wrap.GetNativeField(0));
  WasmImports* imports =
      reinterpret_cast<WasmImports*>(imp_wrap.GetNativeField(0));

  WasmInstance* inst;
  {
    TransitionVMToNative transition(thread);
    inst = new WasmInstance(module, imports);
  }

  inst_wrap.SetNativeField(0, reinterpret_cast<intptr_t>(inst));
  FinalizablePersistentHandle::New(thread->isolate(), inst_wrap, inst,
                                   Finalize<WasmInstance>,
                                   sizeof(WasmInstance));

  return Object::null();
}

DEFINE_NATIVE_ENTRY(Wasm_initFunction, 0, 4) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, fn_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, inst_wrap, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Type, fn_type, arguments->NativeArgAt(3));

  ASSERT(fn_wrap.NumNativeFields() == 1);
  ASSERT(inst_wrap.NumNativeFields() == 1);

  WasmInstance* inst =
      reinterpret_cast<WasmInstance*>(inst_wrap.GetNativeField(0));

  Function& sig = Function::Handle(fn_type.signature());
  Array& args = Array::Handle(sig.parameter_types());
  MallocGrowableArray<classid_t> dart_args;
  for (intptr_t i = sig.NumImplicitParameters(); i < args.Length(); ++i) {
    dart_args.Add(
        AbstractType::Cast(Object::Handle(args.At(i))).type_class_id());
  }
  classid_t dart_ret = AbstractType::Handle(sig.result_type()).type_class_id();

  std::unique_ptr<char[]> name_raw = ToUTF8(name);
  WasmFunction* fn = inst->GetFunction(name_raw.get(), dart_args, dart_ret);

  fn_wrap.SetNativeField(0, reinterpret_cast<intptr_t>(fn));
  // Don't need a finalizer because WasmFunctions are owned their WasmInstance.

  return Object::null();
}

DEFINE_NATIVE_ENTRY(Wasm_callFunction, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, fn_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(1));

  ASSERT(fn_wrap.NumNativeFields() == 1);
  WasmFunction* fn = reinterpret_cast<WasmFunction*>(fn_wrap.GetNativeField(0));

  if (args.Length() != fn->args().length()) {
    Exceptions::ThrowArgumentError(String::Handle(String::NewFormatted(
        "Wrong number of args. Expected %" Pu " but found %" Pd ".",
        fn->args().length(), args.Length())));
  }
  intptr_t length = fn->args().length();
  if (length == 0) {
    // Wasmer requires that our params ptr is valid, even if params_len is 0.
    // TODO(liama): Remove after https://github.com/wasmerio/wasmer/issues/753
    length = 1;
  }
  auto params = std::unique_ptr<wasmer_value_t[]>(new wasmer_value_t[length]);
  for (intptr_t i = 0; i < args.Length(); ++i) {
    if (!ToWasmValue(Number::Cast(Object::Handle(args.At(i))), fn->args()[i],
                     &params[i])) {
      Exceptions::ThrowArgumentError(String::Handle(
          String::NewFormatted("Arg %" Pd " is the wrong type.", i)));
    }
  }

  wasmer_value_t ret;
  {
    TransitionVMToNative transition(Thread::Current());
    ret = fn->Call(params.get());
  }
  return fn->IsVoid() ? Object::null() : ToDartObject(ret);
}

}  // namespace dart

#else  // DART_ENABLE_WASM

#include "vm/bootstrap_natives.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Wasm_initModule, 0, 2) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_initImports, 0, 2) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_addMemoryImport, 0, 3) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_addGlobalImport, 0, 5) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_initMemory, 0, 3) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_growMemory, 0, 3) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_initInstance, 0, 3) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_initFunction, 0, 4) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

DEFINE_NATIVE_ENTRY(Wasm_callFunction, 0, 2) {
  Exceptions::ThrowUnsupportedError("WASM is disabled");
  return nullptr;
}

}  // namespace dart

#endif  // DART_ENABLE_WASM
