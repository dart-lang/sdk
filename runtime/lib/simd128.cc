// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Float32x4_fromDoubles, 5) {
  ASSERT(AbstractTypeArguments::CheckedHandle(
      arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Double, x, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, y, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, z, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, w, arguments->NativeArgAt(4));
  float _x = x.value();
  float _y = y.value();
  float _z = z.value();
  float _w = w.value();
  return Float32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Float32x4_zero, 1) {
  ASSERT(AbstractTypeArguments::CheckedHandle(
      arguments->NativeArgAt(0)).IsNull());
  return Float32x4::New(0.0f, 0.0f, 0.0f, 0.0f);
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
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other,
                               arguments->NativeArgAt(1));
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
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Float32x4_cmplte, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() <= b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() <= b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() <= b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() <= b.w() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Float32x4_cmpgt, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() > b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() > b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() > b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() > b.w() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Float32x4_cmpgte, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() >= b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() >= b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() >= b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() >= b.w() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Float32x4_cmpequal, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() == b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() == b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() == b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() == b.w() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Float32x4_cmpnequal, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, b, arguments->NativeArgAt(1));
  uint32_t _x = a.x() != b.x() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = a.y() != b.y() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = a.z() != b.z() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = a.w() != b.w() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
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
  float _x = self.x() > lo.x() ? self.x() : lo.x();
  float _y = self.y() > lo.y() ? self.y() : lo.y();
  float _z = self.z() > lo.z() ? self.z() : lo.z();
  float _w = self.w() > lo.w() ? self.w() : lo.w();
  _x = _x > hi.x() ? hi.x() : _x;
  _y = _y > hi.y() ? hi.y() : _y;
  _z = _z > hi.z() ? hi.z() : _z;
  _w = _w > hi.w() ? hi.w() : _w;
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


DEFINE_NATIVE_ENTRY(Float32x4_getXXXX, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float value = self.x();
  return Float32x4::New(value, value, value, value);
}


DEFINE_NATIVE_ENTRY(Float32x4_getYYYY, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float value = self.y();
  return Float32x4::New(value, value, value, value);
}


DEFINE_NATIVE_ENTRY(Float32x4_getZZZZ, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float value = self.z();
  return Float32x4::New(value, value, value, value);
}


DEFINE_NATIVE_ENTRY(Float32x4_getWWWW, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  float value = self.w();
  return Float32x4::New(value, value, value, value);
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
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other,
                               arguments->NativeArgAt(1));
  float _x = self.x() < other.x() ? self.x() : other.x();
  float _y = self.y() < other.y() ? self.y() : other.y();
  float _z = self.z() < other.z() ? self.z() : other.z();
  float _w = self.w() < other.w() ? self.w() : other.w();
  return Float32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Float32x4_max, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, other,
                               arguments->NativeArgAt(1));
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


DEFINE_NATIVE_ENTRY(Float32x4_toUint32x4, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, v, arguments->NativeArgAt(0));
  return Uint32x4::New(v.value());
}


DEFINE_NATIVE_ENTRY(Uint32x4_fromInts, 5) {
  ASSERT(AbstractTypeArguments::CheckedHandle(
      arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, x, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, y, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, z, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, w, arguments->NativeArgAt(4));
  uint32_t _x = static_cast<uint32_t>(x.AsInt64Value() & 0xFFFFFFFF);
  uint32_t _y = static_cast<uint32_t>(y.AsInt64Value() & 0xFFFFFFFF);
  uint32_t _z = static_cast<uint32_t>(z.AsInt64Value() & 0xFFFFFFFF);
  uint32_t _w = static_cast<uint32_t>(w.AsInt64Value() & 0xFFFFFFFF);
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_fromBools, 5) {
  ASSERT(AbstractTypeArguments::CheckedHandle(
      arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, x, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, y, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, z, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, w, arguments->NativeArgAt(4));
  uint32_t _x = x.value() ? 0xFFFFFFFF : 0x0;
  uint32_t _y = y.value() ? 0xFFFFFFFF : 0x0;
  uint32_t _z = z.value() ? 0xFFFFFFFF : 0x0;
  uint32_t _w = w.value() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_or, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, other, arguments->NativeArgAt(1));
  uint32_t _x = self.x() | other.x();
  uint32_t _y = self.y() | other.y();
  uint32_t _z = self.z() | other.z();
  uint32_t _w = self.w() | other.w();
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_and, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, other, arguments->NativeArgAt(1));
  uint32_t _x = self.x() & other.x();
  uint32_t _y = self.y() & other.y();
  uint32_t _z = self.z() & other.z();
  uint32_t _w = self.w() & other.w();
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_xor, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, other, arguments->NativeArgAt(1));
  uint32_t _x = self.x() ^ other.x();
  uint32_t _y = self.y() ^ other.y();
  uint32_t _z = self.z() ^ other.z();
  uint32_t _w = self.w() ^ other.w();
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_getX, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.x();
  return Integer::New(value);
}


DEFINE_NATIVE_ENTRY(Uint32x4_getY, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.y();
  return Integer::New(value);
}


DEFINE_NATIVE_ENTRY(Uint32x4_getZ, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.z();
  return Integer::New(value);
}


DEFINE_NATIVE_ENTRY(Uint32x4_getW, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.w();
  return Integer::New(value);
}


DEFINE_NATIVE_ENTRY(Uint32x4_setX, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, x, arguments->NativeArgAt(1));
  uint32_t _x = static_cast<uint32_t>(x.AsInt64Value() & 0xFFFFFFFF);
  uint32_t _y = self.y();
  uint32_t _z = self.z();
  uint32_t _w = self.w();
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_setY, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, y, arguments->NativeArgAt(1));
  uint32_t _x = self.x();
  uint32_t _y = static_cast<uint32_t>(y.AsInt64Value() & 0xFFFFFFFF);
  uint32_t _z = self.z();
  uint32_t _w = self.w();
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_setZ, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, z, arguments->NativeArgAt(1));
  uint32_t _x = self.x();
  uint32_t _y = self.y();
  uint32_t _z = static_cast<uint32_t>(z.AsInt64Value() & 0xFFFFFFFF);
  uint32_t _w = self.w();
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_setW, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, w, arguments->NativeArgAt(1));
  uint32_t _x = self.x();
  uint32_t _y = self.y();
  uint32_t _z = self.z();
  uint32_t _w = static_cast<uint32_t>(w.AsInt64Value() & 0xFFFFFFFF);
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_getFlagX, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.x();
  return value != 0 ? Bool::True().raw() : Bool::False().raw();
}


DEFINE_NATIVE_ENTRY(Uint32x4_getFlagY, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.y();
  return value != 0 ? Bool::True().raw() : Bool::False().raw();
}


DEFINE_NATIVE_ENTRY(Uint32x4_getFlagZ, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.z();
  return value != 0 ? Bool::True().raw() : Bool::False().raw();
}


DEFINE_NATIVE_ENTRY(Uint32x4_getFlagW, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  uint32_t value = self.w();
  return value != 0 ? Bool::True().raw() : Bool::False().raw();
}


DEFINE_NATIVE_ENTRY(Uint32x4_setFlagX, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagX, arguments->NativeArgAt(1));
  uint32_t _x = self.x();
  uint32_t _y = self.y();
  uint32_t _z = self.z();
  uint32_t _w = self.w();
  _x = flagX.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_setFlagY, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagY, arguments->NativeArgAt(1));
  uint32_t _x = self.x();
  uint32_t _y = self.y();
  uint32_t _z = self.z();
  uint32_t _w = self.w();
  _y = flagY.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_setFlagZ, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagZ, arguments->NativeArgAt(1));
  uint32_t _x = self.x();
  uint32_t _y = self.y();
  uint32_t _z = self.z();
  uint32_t _w = self.w();
  _z = flagZ.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


DEFINE_NATIVE_ENTRY(Uint32x4_setFlagW, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, flagW, arguments->NativeArgAt(1));
  uint32_t _x = self.x();
  uint32_t _y = self.y();
  uint32_t _z = self.z();
  uint32_t _w = self.w();
  _w = flagW.raw() == Bool::True().raw() ? 0xFFFFFFFF : 0x0;
  return Uint32x4::New(_x, _y, _z, _w);
}


// Used to convert between uint32_t and float32 without breaking strict
// aliasing rules.
union float32_uint32 {
  float f;
  uint32_t u;
  float32_uint32(float v) {
    f = v;
  }
  float32_uint32(uint32_t v) {
    u = v;
  }
};


DEFINE_NATIVE_ENTRY(Uint32x4_select, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, self, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, tv, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Float32x4, fv, arguments->NativeArgAt(2));
  uint32_t _maskX = self.x();
  uint32_t _maskY = self.y();
  uint32_t _maskZ = self.z();
  uint32_t _maskW = self.w();
  // Extract floats and interpret them as masks.
  float32_uint32 tvx(tv.x());
  float32_uint32 tvy(tv.y());
  float32_uint32 tvz(tv.z());
  float32_uint32 tvw(tv.w());
  float32_uint32 fvx(fv.x());
  float32_uint32 fvy(fv.y());
  float32_uint32 fvz(fv.z());
  float32_uint32 fvw(fv.w());
  // Perform select.
  float32_uint32 tempX((_maskX & tvx.u) | (~_maskX & fvx.u));
  float32_uint32 tempY((_maskY & tvy.u) | (~_maskY & fvy.u));
  float32_uint32 tempZ((_maskZ & tvz.u) | (~_maskZ & fvz.u));
  float32_uint32 tempW((_maskW & tvw.u) | (~_maskW & fvw.u));
  return Float32x4::New(tempX.f, tempY.f, tempZ.f, tempW.f);
}


DEFINE_NATIVE_ENTRY(Uint32x4_toFloat32x4, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Uint32x4, v, arguments->NativeArgAt(0));
  return Float32x4::New(v.value());
}


}  // namespace dart
