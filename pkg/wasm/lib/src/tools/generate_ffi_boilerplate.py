#!/usr/bin/env python3
#
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This is an ad-hoc script that generates FFI boilderplate for the Wasmer API.
# The relevant functions from wasm.h have been copied below, and are parsed to
# figure out the FFI boilerplate. The results are inserted into
# wasmer_api_template.dart and runtime_template.dart to generate wasmer_api.dart
# and runtime.dart.

# Usage:
# generate_ffi_boilerplate.py && dartfmt -w ../runtime.dart ../wasmer_api.dart

import os
import re

predefTypes = {}
opaqueTypes = set()
vecTypes = {}
fns = []
unusedFns = set()


def camel(t):
    return ''.join([s[0].upper() + s[1:] for s in t.split('_')])


def ptrWrap(t, n):
    for i in range(n):
        t = 'Pointer<%s>' % t
    return t


def removePrefix(t):
    assert (t.startswith('wasm_') or t.startswith('wasi_') or
            t.startswith('wasmer_') or t.startswith('Dart_') or
            t.startswith('set_finalizer_'))
    return t[(5 if t.startswith('wasm_') else 0):]


def addPrefix(t):
    if t.startswith('wasi_') or t.startswith('wasmer_') or t.startswith(
            'Dart_') or t.startswith('set_finalizer_'):
        return t
    return 'wasm_' + t


def getDartType(t, i):
    if t in predefTypes:
        return predefTypes[t][i]
    assert (t.endswith('_t'))
    return 'Wasmer' + camel(removePrefix(t[:-2]))


def dartArgType(a, i):
    n, t = a
    j = i if n == 0 else 0
    return ptrWrap(getDartType(t, j), n)


def dartFnType(r, a, i):
    return '%s Function(%s)' % (dartArgType(r, i), ', '.join(
        [dartArgType(t, i) for t in a]))


def dartFnTypeName(n):
    return camel(removePrefix(n))


def dartFnMembName(n):
    return '_' + removePrefix(n)


def nativeTypeToFfi(n):
    return getDartType(n, 0)


def nativeTypeToDart(n):
    return getDartType(n, 1)


def getFns():
    for name, retType, args in sorted(fns):
        if name not in unusedFns:
            yield name, retType, args


opaqueTypeTemplate = '''// %s_t
class Wasmer%s extends Struct {}'''

vecTypeTemplate = '''// %s_vec_t
class Wasmer%sVec extends Struct {
  @Uint64()
  external int length;

  external Pointer<%s> data;

  %s
}'''

byteVecToStringTemplate = '''
  Uint8List get list => data.asTypedList(length);
  String toString() => utf8.decode(list);
'''

fnApiTemplate = '''
// %s
typedef NativeWasmer%sFn = %s;
typedef Wasmer%sFn = %s;'''


def getWasmerApi():
    return ('\n\n'.join([
        opaqueTypeTemplate % (addPrefix(t), camel(t))
        for t in sorted(opaqueTypes)
    ]) + '\n\n' + '\n\n'.join([
        vecTypeTemplate % (addPrefix(t), camel(t),
                           ('Pointer<%s>' if ptr else '%s') % nativeTypeToFfi(
                               '%s_t' % addPrefix(t)),
                           (byteVecToStringTemplate if t == 'byte' else ''))
        for t, ptr in sorted(vecTypes.items())
    ]) + '\n' + '\n'.join([
        fnApiTemplate %
        (name, dartFnTypeName(name), dartFnType(retType, args, 0),
         dartFnTypeName(name), dartFnType(retType, args, 1))
        for name, retType, args in getFns()
    ]))


def getRuntimeMemb():
    return '\n'.join([
        "  late Wasmer%sFn %s;" % (dartFnTypeName(name), dartFnMembName(name))
        for name, _, _ in getFns()
    ])


def getRuntimeLoad():
    return '\n'.join([
        "    %s = _lib.lookupFunction<NativeWasmer%sFn, Wasmer%sFn>('%s');" %
        (dartFnMembName(name), dartFnTypeName(name), dartFnTypeName(name), name)
        for name, _, _ in getFns()
    ])


def predefinedType(nativeType, ffiType, dartType):
    predefTypes[nativeType] = (ffiType, dartType)


def match(r, s):
    return r.fullmatch(s).groups()


reReplace = [(re.compile('\\b%s\\b' % k), v) for k, v in [
    ('const', ''),
    ('own', ''),
    ('WASM_API_EXTERN', ''),
    ('wasm_name_t', 'wasm_byte_vec_t'),
    ('wasm_message_t', 'wasm_byte_vec_t'),
    ('wasm_memory_pages_t', 'uint32_t'),
    ('wasm_externkind_t', 'uint8_t'),
    ('wasm_valkind_t', 'uint8_t'),
]]
reWord = re.compile(r'\b\w+\b')


def parseType(s):
    for r, t in reReplace:
        s = r.sub(t, s)
    s = s.strip()
    numWords = len(reWord.findall(s))
    assert (numWords == 1 or numWords == 2)
    if numWords == 2:
        i = 0

        def lastWordRepl(m):
            nonlocal i
            i += 1
            return '' if i == numWords else m.group(0)

        s = reWord.sub(lastWordRepl, s)
    numPtr = 0
    while True:
        s = s.strip()
        if s.endswith('*'):
            s = s[:-1]
        elif s.endswith('[]'):
            s = s[:-2]
        else:
            break
        numPtr += 1
    return (numPtr, s)


reFnSig = re.compile(r'(.*) ([^ ]*)\((.*)\);?')


def addFn(sig):
    ret, name, argpack = match(reFnSig, sig)
    retType = parseType(ret)
    args = [parseType(a) for a in argpack.split(',') if len(a.strip()) > 0]
    for _, t in args + [retType]:
        if t not in predefTypes and removePrefix(
                t[:-2]) not in opaqueTypes and removePrefix(
                    t[:-6]) not in vecTypes:
            print('Missing type: ' + t)
    fns.append((name, retType, args))


def declareOwn(name):
    opaqueTypes.add(name)
    n = addPrefix(name)
    addFn('void %s_delete(%s_t*)' % (n, n))


def declareVec(name, storePtr):
    vecTypes[name] = storePtr
    n = addPrefix(name)
    addFn('void %s_vec_new_empty(%s_vec_t* out)' % (n, n))
    addFn('void %s_vec_new_uninitialized(%s_vec_t* out, size_t)' % (n, n))
    addFn('void %s_vec_new(%s_vec_t* out, size_t, %s_t %s[])' %
          (n, n, n, '*' if storePtr else ''))
    addFn('void %s_vec_copy(%s_vec_t* out, const %s_vec_t*)' % (n, n, n))
    addFn('void %s_vec_delete(%s_vec_t*)' % (n, n))


def declareType(name, withCopy=True):
    declareOwn(name)
    declareVec(name, True)
    if withCopy:
        n = addPrefix(name)
        addFn('%s_t* %s_copy(%s_t*)' % (n, n, n))


predefinedType('void', 'Void', 'void')
predefinedType('bool', 'Uint8', 'int')
predefinedType('int', 'Int64', 'int')
predefinedType('byte_t', 'Uint8', 'int')
predefinedType('wasm_byte_t', 'Uint8', 'int')
predefinedType('uint8_t', 'Uint8', 'int')
predefinedType('uint16_t', 'Uint16', 'int')
predefinedType('uint32_t', 'Uint32', 'int')
predefinedType('uint64_t', 'Uint64', 'int')
predefinedType('size_t', 'Uint64', 'int')
predefinedType('uintptr_t', 'Uint64', 'int')
predefinedType('intptr_t', 'Int64', 'int')
predefinedType('int8_t', 'Int8', 'int')
predefinedType('int16_t', 'Int16', 'int')
predefinedType('int32_t', 'Int32', 'int')
predefinedType('int64_t', 'Int64', 'int')
predefinedType('float32_t', 'Float32', 'double')
predefinedType('float64_t', 'Float64', 'double')
predefinedType('wasm_limits_t', 'WasmerLimits', 'WasmerLimits')
predefinedType('wasm_val_t', 'WasmerVal', 'WasmerVal')
predefinedType('Dart_Handle', 'Handle', 'Object')

declareOwn('engine')
declareOwn('store')
declareOwn('wasi_config')
declareOwn('wasi_env')
declareVec('byte', False)
declareVec('val', False)
declareType('importtype')
declareType('exporttype')
declareType('valtype')
declareType('extern', False)

# These are actually DECLARE_TYPE, but we don't need the vec or copy stuff.
declareOwn('memorytype')
declareOwn('externtype')
declareOwn('functype')

# These are actually DECLARE_SHARABLE_REF, but we don't need the ref stuff.
declareOwn('module')

# These are actually DECLARE_REF, but we don't need the ref stuff.
declareOwn('memory')
declareOwn('trap')
declareOwn('instance')
declareOwn('func')

rawFns = '''
WASM_API_EXTERN own wasm_engine_t* wasm_engine_new();
WASM_API_EXTERN own wasm_store_t* wasm_store_new(wasm_engine_t*);
WASM_API_EXTERN own wasm_memorytype_t* wasm_memorytype_new(const wasm_limits_t*);
WASM_API_EXTERN own wasm_module_t* wasm_module_new(wasm_store_t*, const wasm_byte_vec_t* binary);
WASM_API_EXTERN void wasm_module_imports(const wasm_module_t*, own wasm_importtype_vec_t* out);
WASM_API_EXTERN const wasm_name_t* wasm_importtype_module(const wasm_importtype_t*);
WASM_API_EXTERN const wasm_name_t* wasm_importtype_name(const wasm_importtype_t*);
WASM_API_EXTERN const wasm_externtype_t* wasm_importtype_type(const wasm_importtype_t*);
WASM_API_EXTERN wasm_functype_t* wasm_externtype_as_functype(wasm_externtype_t*);
WASM_API_EXTERN void wasm_module_exports(const wasm_module_t*, own wasm_exporttype_vec_t* out);
WASM_API_EXTERN const wasm_name_t* wasm_exporttype_name(const wasm_exporttype_t*);
WASM_API_EXTERN const wasm_externtype_t* wasm_exporttype_type(const wasm_exporttype_t*);
WASM_API_EXTERN wasm_externkind_t wasm_externtype_kind(const wasm_externtype_t*);
WASM_API_EXTERN own wasm_instance_t* wasm_instance_new(wasm_store_t*, const wasm_module_t*, const wasm_extern_vec_t* imports, own wasm_trap_t**);
WASM_API_EXTERN void wasm_instance_exports(const wasm_instance_t*, own wasm_extern_vec_t* out);
WASM_API_EXTERN own wasm_memory_t* wasm_memory_new(wasm_store_t*, const wasm_memorytype_t*);
WASM_API_EXTERN byte_t* wasm_memory_data(wasm_memory_t*);
WASM_API_EXTERN size_t wasm_memory_data_size(const wasm_memory_t*);
WASM_API_EXTERN wasm_memory_pages_t wasm_memory_size(const wasm_memory_t*);
WASM_API_EXTERN bool wasm_memory_grow(wasm_memory_t*, wasm_memory_pages_t delta);
WASM_API_EXTERN wasm_externkind_t wasm_extern_kind(const wasm_extern_t*);
WASM_API_EXTERN wasm_func_t* wasm_extern_as_func(wasm_extern_t*);
WASM_API_EXTERN wasm_extern_t* wasm_func_as_extern(wasm_func_t*);
WASM_API_EXTERN wasm_memory_t* wasm_extern_as_memory(wasm_extern_t*);
WASM_API_EXTERN wasm_extern_t* wasm_memory_as_extern(wasm_memory_t*);
WASM_API_EXTERN const wasm_valtype_vec_t* wasm_functype_params(const wasm_functype_t*);
WASM_API_EXTERN const wasm_valtype_vec_t* wasm_functype_results(const wasm_functype_t*);
WASM_API_EXTERN own wasm_func_t* wasm_func_new_with_env( wasm_store_t*, const wasm_functype_t* type, void* fn, void* env, void *finalizer);
WASM_API_EXTERN own wasm_trap_t* wasm_func_call(const wasm_func_t*, const wasm_val_vec_t* args, wasm_val_vec_t* results);
WASM_API_EXTERN own wasm_trap_t* wasm_trap_new(wasm_store_t* store, const wasm_message_t*);
WASM_API_EXTERN void wasm_trap_message(const wasm_trap_t*, own wasm_message_t* out);
WASM_API_EXTERN wasm_valkind_t wasm_valtype_kind(const wasm_valtype_t*);

wasi_config_t* wasi_config_new(const uint8_t* program_name);
wasi_env_t* wasi_env_new(wasi_config_t* config);
bool wasi_get_imports(const wasm_store_t* store, const wasm_module_t* module, const wasi_env_t* wasi_env, wasm_extern_vec_t* imports);
int wasmer_last_error_message(uint8_t* buffer, int length);
int wasmer_last_error_length();
void wasi_env_set_memory(wasi_env_t* env, const wasm_memory_t* memory);
void wasi_config_inherit_stdout(wasi_config_t* config);
void wasi_config_inherit_stderr(wasi_config_t* config);
intptr_t wasi_env_read_stderr(wasi_env_t* env, uint8_t* buffer, uintptr_t buffer_len);
intptr_t wasi_env_read_stdout(wasi_env_t* env, uint8_t* buffer, uintptr_t buffer_len);

intptr_t Dart_InitializeApiDL(void* data);
void set_finalizer_for_engine(Dart_Handle, wasm_engine_t*);
void set_finalizer_for_store(Dart_Handle, wasm_store_t*);
void set_finalizer_for_module(Dart_Handle, wasm_module_t*);
void set_finalizer_for_instance(Dart_Handle, wasm_instance_t*);
void set_finalizer_for_trap(Dart_Handle, wasm_trap_t*);
void set_finalizer_for_memorytype(Dart_Handle, wasm_memorytype_t*);
void set_finalizer_for_memory(Dart_Handle, wasm_memory_t*);
void set_finalizer_for_func(Dart_Handle, wasm_func_t*);
'''
for f in rawFns.split('\n'):
    if len(f.strip()) > 0:
        addFn(f)

unusedFns = {
    'wasm_byte_vec_copy',
    'wasm_exporttype_delete',
    'wasm_exporttype_copy',
    'wasm_exporttype_vec_copy',
    'wasm_extern_vec_copy',
    'wasm_importtype_delete',
    'wasm_importtype_copy',
    'wasm_importtype_vec_copy',
    'wasm_val_vec_copy',
    'wasm_val_vec_delete',
    'wasm_val_vec_new',
    'wasm_val_vec_new_empty',
    'wasm_val_vec_new_uninitialized',
    'wasm_valtype_copy',
    'wasm_valtype_vec_copy',
    'wasi_config_delete',
}

genDoc = '''// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the following command
// "generate_ffi_boilerplate.py".'''

thisDir = os.path.dirname(os.path.abspath(__file__))


def readFile(filename):
    with open(os.path.abspath(os.path.join(thisDir, filename)), 'r') as f:
        return f.read()


def writeFile(filename, content):
    with open(os.path.abspath(os.path.join(thisDir, '..', filename)), 'w') as f:
        f.write(content)


wasmerApiText = readFile('wasmer_api_template.dart')
wasmerApiText = wasmerApiText.replace('/* <WASMER_API> */', getWasmerApi())
wasmerApiText = wasmerApiText.replace('/* <GEN_DOC> */', genDoc)
writeFile('wasmer_api.dart', wasmerApiText)

runtimeText = readFile('runtime_template.dart')
runtimeText = runtimeText.replace('/* <RUNTIME_MEMB> */', getRuntimeMemb())
runtimeText = runtimeText.replace('/* <RUNTIME_LOAD> */', getRuntimeLoad())
runtimeText = runtimeText.replace('/* <GEN_DOC> */', genDoc)
writeFile('runtime.dart', runtimeText)
