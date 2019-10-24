// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

.data

.type _threadObject,@object
.size _threadObject,1400
_threadObject:
  .fill 1400

.text
.file "runtime.S"

.globl main
.type main,@function

.globl "dart:core::print"
.type "dart:core::print",@function

.globl arch_prctl
.type arch_prctl,@function

main:
  movq %rsp, %rax
  subq $0x1000, %rax
  movq %rax, [_threadObject + 72]
  # Pass ARCH_SET_GS
  movq $0x1001, %rdi
  # Pass $_threadObject
  movq $_threadObject, %rsi
  callq arch_prctl
  callq "hello.dart::main"
  ret

"dart:core::print":
  callq puts
  ret
