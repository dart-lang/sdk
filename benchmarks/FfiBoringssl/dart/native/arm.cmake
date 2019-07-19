# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(37531): Remove this cmake file and build with sdk instead when
# benchmark runner gets support for that.

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR "arm")
set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)
set(CMAKE_AS_COMPILER arm-linux-gnueabihf-as)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=attributes" CACHE STRING "c++ flags")
set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -Wno-error=attributes" CACHE STRING "c flags")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} " CACHE STRING "asm flags")
