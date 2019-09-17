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

static void ThrowWasmerError() {
  TransitionNativeToVM transition(Thread::Current());
  String& error = String::Handle();
  {
    int len = wasmer_last_error_length();
    auto raw_error = std::unique_ptr<char[]>(new char[len]);
    int read_len = wasmer_last_error_message(raw_error.get(), len);
    ASSERT(read_len == len);
    error = String::NewFormatted("Wasmer error: %s", raw_error.get());
  }
  Exceptions::ThrowArgumentError(error);
}

template <typename T>
static void Finalize(void* isolate_callback_data,
                     Dart_WeakPersistentHandle handle,
                     void* peer) {
  delete reinterpret_cast<T*>(peer);
}

static void FinalizeWasmModule(void* isolate_callback_data,
                               Dart_WeakPersistentHandle handle,
                               void* module) {
  wasmer_module_destroy(reinterpret_cast<wasmer_module_t*>(module));
}

static void FinalizeWasmMemory(void* isolate_callback_data,
                               Dart_WeakPersistentHandle handle,
                               void* memory) {
  wasmer_memory_destroy(reinterpret_cast<wasmer_memory_t*>(memory));
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
    case kWasmInt32Cid:
      if (!value.IsInteger()) return false;
      out->tag = wasmer_value_tag::WASM_I32;
      out->value.I32 = Integer::Cast(value).AsInt64Value();
      return true;
    case kWasmInt64Cid:
      if (!value.IsInteger()) return false;
      out->tag = wasmer_value_tag::WASM_I64;
      out->value.I64 = Integer::Cast(value).AsInt64Value();
      return true;
    case kWasmFloatCid:
      if (!value.IsDouble()) return false;
      out->tag = wasmer_value_tag::WASM_F32;
      out->value.F32 = Double::Cast(value).value();
      return true;
    case kWasmDoubleCid:
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

RawExternalTypedData* WasmMemoryToExternalTypedData(wasmer_memory_t* memory) {
  uint8_t* data = wasmer_memory_data(memory);
  uint32_t size = wasmer_memory_data_length(memory);
  return ExternalTypedData::New(kExternalTypedDataUint8ArrayCid, data, size);
}

class WasmImports {
 public:
  explicit WasmImports(std::unique_ptr<char[]> module_name)
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

  void AddMemory(std::unique_ptr<char[]> name, wasmer_memory_t* memory) {
    AddImport(std::move(name), wasmer_import_export_kind::WASM_MEMORY)->memory =
        memory;
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
  bool IsVoid() const { return _ret == kWasmVoidCid; }
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

  bool Call(const wasmer_value_t* params, wasmer_value_t* result) {
    return wasmer_export_func_call(_fn, params, _args.length(), result,
                                   IsVoid() ? 0 : 1) ==
           wasmer_result_t::WASMER_OK;
  }

  void Print(std::ostream& o, const char* name) const {
    PrintDartType(o, _ret);
    o << ' ' << name << '(';
    for (intptr_t i = 0; i < _args.length(); ++i) {
      if (i > 0) o << ", ";
      PrintDartType(o, _args[i]);
    }
    o << ')';
  }

 private:
  MallocGrowableArray<classid_t> _args;
  const classid_t _ret;
  const wasmer_export_func_t* _fn;

  static void PrintDartType(std::ostream& o, classid_t type) {
    switch (type) {
      case kWasmInt32Cid:
        o << "i32";
        break;
      case kWasmInt64Cid:
        o << "i64";
        break;
      case kWasmFloatCid:
        o << "f32";
        break;
      case kWasmDoubleCid:
        o << "f64";
        break;
      case kWasmVoidCid:
        o << "void";
        break;
    }
  }
};

class WasmInstance {
 public:
  WasmInstance() : _instance(nullptr), _exports(nullptr) {}

  bool Instantiate(wasmer_module_t* module, WasmImports* imports) {
    // Instantiate module.
    if (wasmer_module_instantiate(module, &_instance, imports->RawImports(),
                                  imports->NumImports()) !=
        wasmer_result_t::WASMER_OK) {
      return false;
    }

    // Load all functions.
    wasmer_instance_exports(_instance, &_exports);
    intptr_t num_exports = wasmer_exports_len(_exports);
    for (intptr_t i = 0; i < num_exports; ++i) {
      wasmer_export_t* exp = wasmer_exports_get(_exports, i);
      if (wasmer_export_kind(exp) == wasmer_import_export_kind::WASM_FUNCTION) {
        if (!AddFunction(exp)) {
          return false;
        }
      }
    }

    return true;
  }

  ~WasmInstance() {
    auto it = _functions.GetIterator();
    for (auto* kv = it.Next(); kv; kv = it.Next()) {
      delete[] kv->key;
      delete kv->value;
    }
    if (_exports != nullptr) {
      wasmer_exports_destroy(_exports);
    }
    if (_instance != nullptr) {
      wasmer_instance_destroy(_instance);
    }
  }

  WasmFunction* GetFunction(const char* name,
                            const MallocGrowableArray<classid_t>& dart_args,
                            classid_t dart_ret,
                            String* error) {
    WasmFunction* fn = _functions.LookupValue(name);
    if (fn == nullptr) {
      *error = String::NewFormatted(
          "Couldn't find a function called %s in the WASM module's exports",
          name);
      return nullptr;
    }
    if (!fn->SignatureMatches(dart_args, dart_ret)) {
      std::stringstream sig;
      fn->Print(sig, name);
      *error = String::NewFormatted("Function signature doesn't match: %s",
                                    sig.str().c_str());
      return nullptr;
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

  static classid_t ToDartType(wasmer_value_tag wasm_type) {
    switch (wasm_type) {
      case wasmer_value_tag::WASM_I32:
        return kWasmInt32Cid;
      case wasmer_value_tag::WASM_I64:
        return kWasmInt64Cid;
      case wasmer_value_tag::WASM_F32:
        return kWasmFloatCid;
      case wasmer_value_tag::WASM_F64:
        return kWasmDoubleCid;
    }
    FATAL("Unknown WASM type");
    return 0;
  }

  bool AddFunction(wasmer_export_t* exp) {
    const wasmer_export_func_t* fn = wasmer_export_to_func(exp);

    uint32_t num_rets;
    if (wasmer_export_func_returns_arity(fn, &num_rets) !=
        wasmer_result_t::WASMER_OK) {
      return false;
    }
    ASSERT(num_rets <= 1);
    wasmer_value_tag wasm_ret;
    if (wasmer_export_func_returns(fn, &wasm_ret, num_rets) !=
        wasmer_result_t::WASMER_OK) {
      return false;
    }
    classid_t ret = num_rets == 0 ? kWasmVoidCid : ToDartType(wasm_ret);

    uint32_t num_args;
    if (wasmer_export_func_params_arity(fn, &num_args) !=
        wasmer_result_t::WASMER_OK) {
      return false;
    }
    auto wasm_args =
        std::unique_ptr<wasmer_value_tag[]>(new wasmer_value_tag[num_args]);
    if (wasmer_export_func_params(fn, wasm_args.get(), num_args) !=
        wasmer_result_t::WASMER_OK) {
      return false;
    }
    MallocGrowableArray<classid_t> args;
    for (intptr_t i = 0; i < num_args; ++i) {
      args.Add(ToDartType(wasm_args[i]));
    }

    wasmer_byte_array name_bytes = wasmer_export_name(exp);
    char* name = new char[name_bytes.bytes_len + 1];
    for (size_t i = 0; i < name_bytes.bytes_len; ++i) {
      name[i] = name_bytes.bytes[i];
    }
    name[name_bytes.bytes_len] = '\0';

    _functions.Insert({name, new WasmFunction(std::move(args), ret, fn)});
    return true;
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

  wasmer_module_t* module;
  {
    TransitionVMToNative transition(thread);
    if (wasmer_compile(&module, data_copy.get(), len) !=
        wasmer_result_t::WASMER_OK) {
      data_copy.reset();
      ThrowWasmerError();
    }
  }

  mod_wrap.SetNativeField(0, reinterpret_cast<intptr_t>(module));
  FinalizablePersistentHandle::New(thread->isolate(), mod_wrap, module,
                                   FinalizeWasmModule, len);

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
  wasmer_memory_t* memory =
      reinterpret_cast<wasmer_memory_t*>(mem_wrap.GetNativeField(0));

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
  const int64_t init_size = init.AsInt64Value();
  const int64_t max_size = max.AsInt64Value();

  wasmer_memory_t* memory;
  wasmer_limits_t descriptor;
  descriptor.min = init_size;
  if (max_size < 0) {
    descriptor.max.has_some = false;
  } else {
    descriptor.max.has_some = true;
    descriptor.max.some = max_size;
  }
  if (wasmer_memory_new(&memory, descriptor) != wasmer_result_t::WASMER_OK) {
    ThrowWasmerError();
  }
  mem_wrap.SetNativeField(0, reinterpret_cast<intptr_t>(memory));
  FinalizablePersistentHandle::New(thread->isolate(), mem_wrap, memory,
                                   FinalizeWasmMemory, init_size);
  return WasmMemoryToExternalTypedData(memory);
}

DEFINE_NATIVE_ENTRY(Wasm_growMemory, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, mem_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, delta, arguments->NativeArgAt(1));

  ASSERT(mem_wrap.NumNativeFields() == 1);

  wasmer_memory_t* memory =
      reinterpret_cast<wasmer_memory_t*>(mem_wrap.GetNativeField(0));
  if (wasmer_memory_grow(memory, delta.AsInt64Value()) !=
      wasmer_result_t::WASMER_OK) {
    ThrowWasmerError();
  }
  return WasmMemoryToExternalTypedData(memory);
}

DEFINE_NATIVE_ENTRY(Wasm_initInstance, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, inst_wrap, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, mod_wrap, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, imp_wrap, arguments->NativeArgAt(2));

  ASSERT(inst_wrap.NumNativeFields() == 1);
  ASSERT(mod_wrap.NumNativeFields() == 1);
  ASSERT(imp_wrap.NumNativeFields() == 1);

  wasmer_module_t* module =
      reinterpret_cast<wasmer_module_t*>(mod_wrap.GetNativeField(0));
  WasmImports* imports =
      reinterpret_cast<WasmImports*>(imp_wrap.GetNativeField(0));

  WasmInstance* inst = nullptr;
  {
    TransitionVMToNative transition(thread);
    inst = new WasmInstance();
    if (!inst->Instantiate(module, imports)) {
      delete inst;
      inst = nullptr;
    }
  }
  if (inst == nullptr) {
    ThrowWasmerError();
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

  WasmFunction* fn;
  String& error = String::Handle(zone);

  {
    Function& sig = Function::Handle(fn_type.signature());
    Array& args = Array::Handle(sig.parameter_types());
    MallocGrowableArray<classid_t> dart_args;
    for (intptr_t i = sig.NumImplicitParameters(); i < args.Length(); ++i) {
      dart_args.Add(
          AbstractType::Cast(Object::Handle(args.At(i))).type_class_id());
    }
    classid_t dart_ret =
        AbstractType::Handle(sig.result_type()).type_class_id();

    std::unique_ptr<char[]> name_raw = ToUTF8(name);
    fn = inst->GetFunction(name_raw.get(), dart_args, dart_ret, &error);
  }

  if (fn == nullptr) {
    Exceptions::ThrowArgumentError(error);
  }

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
      params.reset();
      Exceptions::ThrowArgumentError(String::Handle(
          String::NewFormatted("Arg %" Pd " is the wrong type.", i)));
    }
  }

  wasmer_value_t ret;
  {
    TransitionVMToNative transition(thread);
    if (!fn->Call(params.get(), &ret)) {
      params.reset();
      ThrowWasmerError();
    }
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
