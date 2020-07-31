// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/bytecode_fingerprints.h"

#include "vm/compiler/frontend/bytecode_reader.h"
#include "vm/constants_kbc.h"
#include "vm/hash.h"

namespace dart {
namespace kernel {

static uint32_t CombineObject(uint32_t hash, const Object& obj) {
  if (obj.IsAbstractType()) {
    return CombineHashes(hash, AbstractType::Cast(obj).Hash());
  } else if (obj.IsClass()) {
    return CombineHashes(hash, Class::Cast(obj).id());
  } else if (obj.IsFunction()) {
    return CombineHashes(
        hash, AbstractType::Handle(Function::Cast(obj).result_type()).Hash());
  } else if (obj.IsField()) {
    return CombineHashes(hash,
                         AbstractType::Handle(Field::Cast(obj).type()).Hash());
  } else {
    return CombineHashes(hash, static_cast<uint32_t>(obj.GetClassId()));
  }
}

typedef uint32_t (*Fp)(uint32_t fp,
                       const KBCInstr* instr,
                       const ObjectPool& pool,
                       int32_t value);

static uint32_t Fp___(uint32_t fp,
                      const KBCInstr* instr,
                      const ObjectPool& pool,
                      int32_t value) {
  return fp;
}

static uint32_t Fptgt(uint32_t fp,
                      const KBCInstr* instr,
                      const ObjectPool& pool,
                      int32_t value) {
  return CombineHashes(fp, value);
}

static uint32_t Fplit(uint32_t fp,
                      const KBCInstr* instr,
                      const ObjectPool& pool,
                      int32_t value) {
  return CombineObject(fp, Object::Handle(pool.ObjectAt(value)));
}

static uint32_t Fpreg(uint32_t fp,
                      const KBCInstr* instr,
                      const ObjectPool& pool,
                      int32_t value) {
  return CombineHashes(fp, value);
}

static uint32_t Fpxeg(uint32_t fp,
                      const KBCInstr* instr,
                      const ObjectPool& pool,
                      int32_t value) {
  return CombineHashes(fp, value);
}

static uint32_t Fpnum(uint32_t fp,
                      const KBCInstr* instr,
                      const ObjectPool& pool,
                      int32_t value) {
  return CombineHashes(fp, value);
}

static uint32_t Fingerprint0(uint32_t fp,
                             const KBCInstr* instr,
                             const ObjectPool& pool,
                             Fp op1,
                             Fp op2,
                             Fp op3) {
  return fp;
}

static uint32_t FingerprintA(uint32_t fp,
                             const KBCInstr* instr,
                             const ObjectPool& pool,
                             Fp op1,
                             Fp op2,
                             Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeA(instr));
  return fp;
}

static uint32_t FingerprintD(uint32_t fp,
                             const KBCInstr* instr,
                             const ObjectPool& pool,
                             Fp op1,
                             Fp op2,
                             Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeD(instr));
  return fp;
}

static uint32_t FingerprintX(uint32_t fp,
                             const KBCInstr* instr,
                             const ObjectPool& pool,
                             Fp op1,
                             Fp op2,
                             Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeX(instr));
  return fp;
}

static uint32_t FingerprintT(uint32_t fp,
                             const KBCInstr* instr,
                             const ObjectPool& pool,
                             Fp op1,
                             Fp op2,
                             Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeT(instr));
  return fp;
}

static uint32_t FingerprintA_E(uint32_t fp,
                               const KBCInstr* instr,
                               const ObjectPool& pool,
                               Fp op1,
                               Fp op2,
                               Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeA(instr));
  fp = op2(fp, instr, pool, KernelBytecode::DecodeE(instr));
  return fp;
}

static uint32_t FingerprintA_Y(uint32_t fp,
                               const KBCInstr* instr,
                               const ObjectPool& pool,
                               Fp op1,
                               Fp op2,
                               Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeA(instr));
  fp = op2(fp, instr, pool, KernelBytecode::DecodeY(instr));
  return fp;
}

static uint32_t FingerprintD_F(uint32_t fp,
                               const KBCInstr* instr,
                               const ObjectPool& pool,
                               Fp op1,
                               Fp op2,
                               Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeD(instr));
  fp = op2(fp, instr, pool, KernelBytecode::DecodeF(instr));
  return fp;
}

static uint32_t FingerprintA_B_C(uint32_t fp,
                                 const KBCInstr* instr,
                                 const ObjectPool& pool,
                                 Fp op1,
                                 Fp op2,
                                 Fp op3) {
  fp = op1(fp, instr, pool, KernelBytecode::DecodeA(instr));
  fp = op2(fp, instr, pool, KernelBytecode::DecodeB(instr));
  fp = op3(fp, instr, pool, KernelBytecode::DecodeC(instr));
  return fp;
}

uint32_t BytecodeFingerprintHelper::CalculateFunctionFingerprint(
    const Function& function) {
  ASSERT(function.is_declared_in_bytecode());
  const intptr_t kHashBits = 30;
  uint32_t fp = 0;
  fp = CombineHashes(fp, String::Handle(function.UserVisibleName()).Hash());
  if (function.is_abstract()) {
    return FinalizeHash(fp, kHashBits);
  }
  if (!function.HasBytecode()) {
    kernel::BytecodeReader::ReadFunctionBytecode(Thread::Current(), function);
  }
  const Bytecode& code = Bytecode::Handle(function.bytecode());
  const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
  const KBCInstr* const start =
      reinterpret_cast<const KBCInstr*>(code.instructions());
  for (const KBCInstr* instr = start; (instr - start) < code.Size();
       instr = KernelBytecode::Next(instr)) {
    const KernelBytecode::Opcode opcode = KernelBytecode::DecodeOpcode(instr);
    fp = CombineHashes(fp, opcode);
    switch (opcode) {
#define FINGERPRINT_BYTECODE(name, encoding, kind, op1, op2, op3)              \
  case KernelBytecode::k##name:                                                \
    fp = Fingerprint##encoding(fp, instr, pool, Fp##op1, Fp##op2, Fp##op3);    \
    break;
      KERNEL_BYTECODES_LIST(FINGERPRINT_BYTECODE)
#undef FINGERPRINT_BYTECODE
      default:
        UNREACHABLE();
    }
  }

  return FinalizeHash(fp, kHashBits);
}

}  // namespace kernel
}  // namespace dart
