// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

static void ThrowMaskRangeException(int64_t m) {
  if ((m < 0) || (m > 255)) {
    Exceptions::ThrowRangeError("mask", Integer::Handle(Integer::New(m)), 0,
                                255);
  }
}

DEFINE_NATIVE_ENTRY(Float32x4_fromDoubles, 5) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Double, x, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, y, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, z, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, w, arguments->NativeArgAt(4));
  float _x = static_cast<float>(x.value());
  float _y = static_cast<float>(y.value());
  float _z = static_cast<float>(z.value());
  float _w = static_cast<float>(w.value());
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_splat, 2) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Double, v, arguments->NativeArgAt(1));
  float _v = v.value();
  return Float32x4::New(_v, _v, _v, _v);
}

DEFINE_NATIVE_ENTRY(Float32x4_zero, 1) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  return Float32x4::New(0.0f, 0.0f, 0.0f, 0.0f);
}

DEFINE_NATIVE_ENTRY(Float32x4_fromInt32x4Bits, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, v, arguments->NativeArgAt(1));
  return Float32x4::New(v.value());
}

DEFINE_NATIVE_ENTRY(Float32x4_fromFloat64x2, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, v, arguments->NativeArgAt(1));
  float _x = static_cast<float>(v.x());
  float _y = static_cast<float>(v.y());
  return Float32x4::New(_x, _y, 0.0f, 0.0f);
}

DEFINE_NATIVE_ENTRY(Float32x4_add, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other, arguments->NativeArgAt(1));
  float _x = self.x() + other.x();
  float _y = self.y() + other.y();
  float _z = self.z() + other.z();
  float _w = self.w() + other.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_negate, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float _x = -self.x();
  float _y = -self.y();
  float _z = -self.z();
  float _w = -self.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_sub, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other, arguments->NativeArgAt(1));
  float _x = self.x() - other.x();
  float _y = self.y() - other.y();
  float _z = self.z() - other.z();
  float _w = self.w() - other.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_mul, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other, arguments->NativeArgAt(1));
  float _x = self.x() * other.x();
  float _y = self.y() * other.y();
  float _z = self.z() * other.z();
  float _w = self.w() * other.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_div, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other, arguments->NativeArgAt(1));
  float _x = self.x() / other.x();
  float _y = self.y() / other.y();
  float _z = self.z() / other.z();
  float _w = self.w() / other.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_cmplt, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() < b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() < b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() < b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() < b.w() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_cmplte, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() <= b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() <= b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() <= b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() <= b.w() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_cmpgt, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() > b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() > b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() > b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() > b.w() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_cmpgte, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() >= b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() >= b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() >= b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() >= b.w() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_cmpequal, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() == b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() == b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() == b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() == b.w() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_cmpnequal, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() != b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() != b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() != b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() != b.w() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_scale, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, scale, arguments->NativeArgAt(1));
  float _s = static_cast<float>(scale.value());
  float _x = self.x() * _s;
  float _y = self.y() * _s;
  float _z = self.z() * _s;
  float _w = self.w() * _s;
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_abs, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float _x = fabsf(self.x());
  float _y = fabsf(self.y());
  float _z = fabsf(self.z());
  float _w = fabsf(self.w());
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_clamp, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, lo, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, hi, arguments->NativeArgAt(2));
  // The order of the clamping must match the order of the optimized code:
  // MAX(MIN(self, hi), lo).
  float _x = self.x() < hi.x() ? self.x() : hi.x();
  float _y = self.y() < hi.y() ? self.y() : hi.y();
  float _z = self.z() < hi.z() ? self.z() : hi.z();
  float _w = self.w() < hi.w() ? self.w() : hi.w();
  _x = _x < lo.x() ? lo.x() : _x;
  _y = _y < lo.y() ? lo.y() : _y;
  _z = _z < lo.z() ? lo.z() : _z;
  _w = _w < lo.w() ? lo.w() : _w;
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_getX, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  double value = static_cast<double>(self.x());
  return Double::New(value);
}

DEFINE_NATIVE_ENTRY(Float32x4_getY, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  double value = static_cast<double>(self.y());
  return Double::New(value);
}

DEFINE_NATIVE_ENTRY(Float32x4_getZ, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  double value = static_cast<double>(self.z());
  return Double::New(value);
}

DEFINE_NATIVE_ENTRY(Float32x4_getW, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  double value = static_cast<double>(self.w());
  return Double::New(value);
}

DEFINE_NATIVE_ENTRY(Float32x4_getSignMask, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  uint32_t mx = (bit_cast<uint32_t>(self.x()) & 0x80000000) >> 31;
  uint32_t my = (bit_cast<uint32_t>(self.y()) & 0x80000000) >> 31;
  uint32_t mz = (bit_cast<uint32_t>(self.z()) & 0x80000000) >> 31;
  uint32_t mw = (bit_cast<uint32_t>(self.w()) & 0x80000000) >> 31;
  uint32_t value = mx | (my << 1) | (mz << 2) | (mw << 3);
  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Int32x4_getSignMask, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  uint32_t mx = (self.x() & 0x80000000) >> 31;
  uint32_t my = (self.y() & 0x80000000) >> 31;
  uint32_t mz = (self.z() & 0x80000000) >> 31;
  uint32_t mw = (self.w() & 0x80000000) >> 31;
  uint32_t value = mx | (my << 1) | (mz << 2) | (mw << 3);
  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Float32x4_shuffle, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, mask, arguments->NativeArgAt(1));
  int64_t m = mask.AsInt64Value();
  ThrowMaskRangeException(m);
  float data[4] = {self.x(), self.y(), self.z(), self.w()};
  float _x = data[m & 0x3];
  float _y = data[(m >> 2) & 0x3];
  float _z = data[(m >> 4) & 0x3];
  float _w = data[(m >> 6) & 0x3];
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_shuffleMix, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, mask, arguments->NativeArgAt(2));
  int64_t m = mask.AsInt64Value();
  ThrowMaskRangeException(m);
  float data[4] = {self.x(), self.y(), self.z(), self.w()};
  float other_data[4] = {other.x(), other.y(), other.z(), other.w()};
  float _x = data[m & 0x3];
  float _y = data[(m >> 2) & 0x3];
  float _z = other_data[(m >> 4) & 0x3];
  float _w = other_data[(m >> 6) & 0x3];
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_setX, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, x, arguments->NativeArgAt(1));
  float _x = static_cast<float>(x.value());
  float _y = self.y();
  float _z = self.z();
  float _w = self.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_setY, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, y, arguments->NativeArgAt(1));
  float _x = self.x();
  float _y = static_cast<float>(y.value());
  float _z = self.z();
  float _w = self.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_setZ, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, z, arguments->NativeArgAt(1));
  float _x = self.x();
  float _y = self.y();
  float _z = static_cast<float>(z.value());
  float _w = self.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_setW, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, w, arguments->NativeArgAt(1));
  float _x = self.x();
  float _y = self.y();
  float _z = self.z();
  float _w = static_cast<float>(w.value());
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_min, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other, arguments->NativeArgAt(1));
  float _x = self.x() < other.x() ? self.x() : other.x();
  float _y = self.y() < other.y() ? self.y() : other.y();
  float _z = self.z() < other.z() ? self.z() : other.z();
  float _w = self.w() < other.w() ? self.w() : other.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_max, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other, arguments->NativeArgAt(1));
  float _x = self.x() > other.x() ? self.x() : other.x();
  float _y = self.y() > other.y() ? self.y() : other.y();
  float _z = self.z() > other.z() ? self.z() : other.z();
  float _w = self.w() > other.w() ? self.w() : other.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_sqrt, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float _x = sqrtf(self.x());
  float _y = sqrtf(self.y());
  float _z = sqrtf(self.z());
  float _w = sqrtf(self.w());
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_reciprocal, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float _x = 1.0f / self.x();
  float _y = 1.0f / self.y();
  float _z = 1.0f / self.z();
  float _w = 1.0f / self.w();
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Float32x4_reciprocalSqrt, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float _x = sqrtf(1.0f / self.x());
  float _y = sqrtf(1.0f / self.y());
  float _z = sqrtf(1.0f / self.z());
  float _w = sqrtf(1.0f / self.w());
  return Float32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_fromInts, 5) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, x, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, y, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, z, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, w, arguments->NativeArgAt(4));
  int32_t _x = static_cast<int32_t>(x.AsTruncatedUint32Value());
  int32_t _y = static_cast<int32_t>(y.AsTruncatedUint32Value());
  int32_t _z = static_cast<int32_t>(z.AsTruncatedUint32Value());
  int32_t _w = static_cast<int32_t>(w.AsTruncatedUint32Value());
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_fromBools, 5) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, x, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, y, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, z, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, w, arguments->NativeArgAt(4));
  int32_t _x = x.value() ? 0xFFFFFFFF : 0x0;
  int32_t _y = y.value() ? 0xFFFFFFFF : 0x0;
  int32_t _z = z.value() ? 0xFFFFFFFF : 0x0;
  int32_t _w = w.value() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_fromFloat32x4Bits, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, v, arguments->NativeArgAt(1));
  return Int32x4::New(v.value());
}

DEFINE_NATIVE_ENTRY(Int32x4_or, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, other, arguments->NativeArgAt(1));
  int32_t _x = self.x() | other.x();
  int32_t _y = self.y() | other.y();
  int32_t _z = self.z() | other.z();
  int32_t _w = self.w() | other.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_and, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, other, arguments->NativeArgAt(1));
  int32_t _x = self.x() & other.x();
  int32_t _y = self.y() & other.y();
  int32_t _z = self.z() & other.z();
  int32_t _w = self.w() & other.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_xor, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, other, arguments->NativeArgAt(1));
  int32_t _x = self.x() ^ other.x();
  int32_t _y = self.y() ^ other.y();
  int32_t _z = self.z() ^ other.z();
  int32_t _w = self.w() ^ other.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_add, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, other, arguments->NativeArgAt(1));
  int32_t _x = self.x() + other.x();
  int32_t _y = self.y() + other.y();
  int32_t _z = self.z() + other.z();
  int32_t _w = self.w() + other.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_sub, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, other, arguments->NativeArgAt(1));
  int32_t _x = self.x() - other.x();
  int32_t _y = self.y() - other.y();
  int32_t _z = self.z() - other.z();
  int32_t _w = self.w() - other.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_getX, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.x();
  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Int32x4_getY, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.y();
  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Int32x4_getZ, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.z();
  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Int32x4_getW, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.w();
  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Int32x4_shuffle, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, mask, arguments->NativeArgAt(1));
  int64_t m = mask.AsInt64Value();
  ThrowMaskRangeException(m);
  int32_t data[4] = {self.x(), self.y(), self.z(), self.w()};
  int32_t _x = data[m & 0x3];
  int32_t _y = data[(m >> 2) & 0x3];
  int32_t _z = data[(m >> 4) & 0x3];
  int32_t _w = data[(m >> 6) & 0x3];
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_shuffleMix, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, zw, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, mask, arguments->NativeArgAt(2));
  int64_t m = mask.AsInt64Value();
  ThrowMaskRangeException(m);
  int32_t data[4] = {self.x(), self.y(), self.z(), self.w()};
  int32_t zw_data[4] = {zw.x(), zw.y(), zw.z(), zw.w()};
  int32_t _x = data[m & 0x3];
  int32_t _y = data[(m >> 2) & 0x3];
  int32_t _z = zw_data[(m >> 4) & 0x3];
  int32_t _w = zw_data[(m >> 6) & 0x3];
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_setX, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, x, arguments->NativeArgAt(1));
  int32_t _x = static_cast<int32_t>(x.AsInt64Value() & 0xFFFFFFFF);
  int32_t _y = self.y();
  int32_t _z = self.z();
  int32_t _w = self.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_setY, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, y, arguments->NativeArgAt(1));
  int32_t _x = self.x();
  int32_t _y = static_cast<int32_t>(y.AsInt64Value() & 0xFFFFFFFF);
  int32_t _z = self.z();
  int32_t _w = self.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_setZ, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, z, arguments->NativeArgAt(1));
  int32_t _x = self.x();
  int32_t _y = self.y();
  int32_t _z = static_cast<int32_t>(z.AsInt64Value() & 0xFFFFFFFF);
  int32_t _w = self.w();
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_setW, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, w, arguments->NativeArgAt(1));
  int32_t _x = self.x();
  int32_t _y = self.y();
  int32_t _z = self.z();
  int32_t _w = static_cast<int32_t>(w.AsInt64Value() & 0xFFFFFFFF);
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_getFlagX, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.x();
  return Bool::Get(value != 0).raw();
}

DEFINE_NATIVE_ENTRY(Int32x4_getFlagY, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.y();
  return Bool::Get(value != 0).raw();
}

DEFINE_NATIVE_ENTRY(Int32x4_getFlagZ, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.z();
  return Bool::Get(value != 0).raw();
}

DEFINE_NATIVE_ENTRY(Int32x4_getFlagW, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  int32_t value = self.w();
  return Bool::Get(value != 0).raw();
}

DEFINE_NATIVE_ENTRY(Int32x4_setFlagX, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagX, arguments->NativeArgAt(1));
  int32_t _x = self.x();
  int32_t _y = self.y();
  int32_t _z = self.z();
  int32_t _w = self.w();
  _x = flagX.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_setFlagY, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagY, arguments->NativeArgAt(1));
  int32_t _x = self.x();
  int32_t _y = self.y();
  int32_t _z = self.z();
  int32_t _w = self.w();
  _y = flagY.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_setFlagZ, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagZ, arguments->NativeArgAt(1));
  int32_t _x = self.x();
  int32_t _y = self.y();
  int32_t _z = self.z();
  int32_t _w = self.w();
  _z = flagZ.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

DEFINE_NATIVE_ENTRY(Int32x4_setFlagW, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagW, arguments->NativeArgAt(1));
  int32_t _x = self.x();
  int32_t _y = self.y();
  int32_t _z = self.z();
  int32_t _w = self.w();
  _w = flagW.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Int32x4::New(_x, _y, _z, _w);
}

// Used to convert between int32_t and float32 without breaking strict
// aliasing rules.
union float32_int32 {
  float f;
  int32_t u;
  float32_int32(float v) { f = v; }
  float32_int32(int32_t v) { u = v; }
};

DEFINE_NATIVE_ENTRY(Int32x4_select, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Int32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, tv, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, fv, arguments->NativeArgAt(2));
  int32_t _maskX = self.x();
  int32_t _maskY = self.y();
  int32_t _maskZ = self.z();
  int32_t _maskW = self.w();
  // Extract floats and interpret them as masks.
  float32_int32 tvx(tv.x());
  float32_int32 tvy(tv.y());
  float32_int32 tvz(tv.z());
  float32_int32 tvw(tv.w());
  float32_int32 fvx(fv.x());
  float32_int32 fvy(fv.y());
  float32_int32 fvz(fv.z());
  float32_int32 fvw(fv.w());
  // Perform select.
  float32_int32 tempX((_maskX & tvx.u) | (~_maskX & fvx.u));
  float32_int32 tempY((_maskY & tvy.u) | (~_maskY & fvy.u));
  float32_int32 tempZ((_maskZ & tvz.u) | (~_maskZ & fvz.u));
  float32_int32 tempW((_maskW & tvw.u) | (~_maskW & fvw.u));
  return Float32x4::New(tempX.f, tempY.f, tempZ.f, tempW.f);
}

DEFINE_NATIVE_ENTRY(Float64x2_fromDoubles, 3) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Double, x, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, y, arguments->NativeArgAt(2));
  return Float64x2::New(x.value(), y.value());
}

DEFINE_NATIVE_ENTRY(Float64x2_splat, 2) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Double, v, arguments->NativeArgAt(1));
  return Float64x2::New(v.value(), v.value());
}

DEFINE_NATIVE_ENTRY(Float64x2_zero, 1) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  return Float64x2::New(0.0, 0.0);
}

DEFINE_NATIVE_ENTRY(Float64x2_fromFloat32x4, 2) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, v, arguments->NativeArgAt(1));
  double _x = v.x();
  double _y = v.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_add, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, other, arguments->NativeArgAt(1));
  double _x = self.x() + other.x();
  double _y = self.y() + other.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_negate, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  double _x = -self.x();
  double _y = -self.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_sub, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, other, arguments->NativeArgAt(1));
  double _x = self.x() - other.x();
  double _y = self.y() - other.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_mul, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, other, arguments->NativeArgAt(1));
  double _x = self.x() * other.x();
  double _y = self.y() * other.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_div, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, other, arguments->NativeArgAt(1));
  double _x = self.x() / other.x();
  double _y = self.y() / other.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_scale, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, scale, arguments->NativeArgAt(1));
  double _s = scale.value();
  double _x = self.x() * _s;
  double _y = self.y() * _s;
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_abs, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  double _x = fabs(self.x());
  double _y = fabs(self.y());
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_clamp, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, lo, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, hi, arguments->NativeArgAt(2));
  // The order of the clamping must match the order of the optimized code:
  // MAX(MIN(self, hi), lo).
  double _x = self.x() < hi.x() ? self.x() : hi.x();
  double _y = self.y() < hi.y() ? self.y() : hi.y();
  _x = _x < lo.x() ? lo.x() : _x;
  _y = _y < lo.y() ? lo.y() : _y;
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_getX, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  return Double::New(self.x());
}

DEFINE_NATIVE_ENTRY(Float64x2_getY, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  return Double::New(self.y());
}

DEFINE_NATIVE_ENTRY(Float64x2_getSignMask, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  uint32_t mx = (bit_cast<uint64_t>(self.x()) & 0x8000000000000000LL) >> 63;
  uint32_t my = (bit_cast<uint64_t>(self.y()) & 0x8000000000000000LL) >> 63;
  uint32_t value = mx | (my << 1);
  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Float64x2_setX, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, x, arguments->NativeArgAt(1));
  double _x = x.value();
  double _y = self.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_setY, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, y, arguments->NativeArgAt(1));
  double _x = self.x();
  double _y = y.value();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_min, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, other, arguments->NativeArgAt(1));
  double _x = self.x() < other.x() ? self.x() : other.x();
  double _y = self.y() < other.y() ? self.y() : other.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_max, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, other, arguments->NativeArgAt(1));
  double _x = self.x() > other.x() ? self.x() : other.x();
  double _y = self.y() > other.y() ? self.y() : other.y();
  return Float64x2::New(_x, _y);
}

DEFINE_NATIVE_ENTRY(Float64x2_sqrt, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float64x2, self, arguments->NativeArgAt(0));
  double _x = sqrt(self.x());
  double _y = sqrt(self.y());
  return Float64x2::New(_x, _y);
}

}  // namespace dart
