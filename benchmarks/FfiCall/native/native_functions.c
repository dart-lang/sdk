// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdint.h>

uint8_t Function1Uint8(uint8_t x) { return x + 42; }

uint16_t Function1Uint16(uint16_t x) { return x + 42; }

uint32_t Function1Uint32(uint32_t x) { return x + 42; }

uint64_t Function1Uint64(uint64_t x) { return x + 42; }

int8_t Function1Int8(int8_t x) { return x + 42; }

int16_t Function1Int16(int16_t x) { return x + 42; }

int32_t Function1Int32(int32_t x) { return x + 42; }

int32_t Function2Int32(int32_t a, int32_t b) {
  return a + b;
}

int32_t Function4Int32(int32_t a, int32_t b, int32_t c, int32_t d) {
  return a + b + c + d;
}

int32_t Function10Int32(int32_t a, int32_t b, int32_t c, int32_t d, int32_t e,
                        int32_t f, int32_t g, int32_t h, int32_t i, int32_t j) {
  return a + b + c + d + e + f + g + h + i + j;
}

int32_t Function20Int32(int32_t a, int32_t b, int32_t c, int32_t d, int32_t e,
                        int32_t f, int32_t g, int32_t h, int32_t i, int32_t j,
                        int32_t k, int32_t l, int32_t m, int32_t n, int32_t o,
                        int32_t p, int32_t q, int32_t r, int32_t s, int32_t t) {
  return a + b + c + d + e + f + g + h + i + j + k + l + m + n + o +
                   p + q + r + s + t;
}

int64_t Function1Int64(int64_t x) { return x + 42; }

int64_t Function2Int64(int64_t a, int64_t b) {
  return a + b;
}

int64_t Function4Int64(int64_t a, int64_t b, int64_t c, int64_t d) {
  return a + b + c + d;
}

int64_t Function10Int64(int64_t a, int64_t b, int64_t c, int64_t d, int64_t e,
                        int64_t f, int64_t g, int64_t h, int64_t i, int64_t j) {
  return a + b + c + d + e + f + g + h + i + j;
}

int64_t Function20Int64(int64_t a, int64_t b, int64_t c, int64_t d, int64_t e,
                        int64_t f, int64_t g, int64_t h, int64_t i, int64_t j,
                        int64_t k, int64_t l, int64_t m, int64_t n, int64_t o,
                        int64_t p, int64_t q, int64_t r, int64_t s, int64_t t) {
  return a + b + c + d + e + f + g + h + i + j + k + l + m + n + o +
                   p + q + r + s + t;
}

float Function1Float(float x) { return x + 42.0f; }

float Function2Float(float a, float b) {
  return a + b;
}

float Function4Float(float a, float b, float c, float d) {
  return a + b + c + d;
}

float Function10Float(float a, float b, float c, float d, float e, float f,
                      float g, float h, float i, float j) {
  return a + b + c + d + e + f + g + h + i + j;
}

float Function20Float(float a, float b, float c, float d, float e, float f,
                      float g, float h, float i, float j, float k, float l,
                      float m, float n, float o, float p, float q, float r,
                      float s, float t) {
  return a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p +
                 q + r + s + t;
}

double Function1Double(double x) { return x + 42.0; }

double Function2Double(double a, double b) {
  return a + b;
}

double Function4Double(double a, double b, double c, double d) {
  return a + b + c + d;
}

double Function10Double(double a, double b, double c, double d, double e,
                        double f, double g, double h, double i, double j) {
  return a + b + c + d + e + f + g + h + i + j;
}

double Function20Double(double a, double b, double c, double d, double e,
                        double f, double g, double h, double i, double j,
                        double k, double l, double m, double n, double o,
                        double p, double q, double r, double s, double t) {
  return a + b + c + d + e + f + g + h + i + j + k + l + m + n + o +
                  p + q + r + s + t;
}

uint8_t *Function1PointerUint8(uint8_t *a) { return a + 1; }

uint8_t *Function2PointerUint8(uint8_t *a, uint8_t *b) { return a + 1; }

uint8_t *Function4PointerUint8(uint8_t *a, uint8_t *b, uint8_t *c, uint8_t *d) {
  return a + 1;
}

uint8_t *Function10PointerUint8(uint8_t *a, uint8_t *b, uint8_t *c, uint8_t *d,
                                uint8_t *e, uint8_t *f, uint8_t *g, uint8_t *h,
                                uint8_t *i, uint8_t *j) {
  return a + 1;
}

uint8_t *Function20PointerUint8(uint8_t *a, uint8_t *b, uint8_t *c, uint8_t *d,
                                uint8_t *e, uint8_t *f, uint8_t *g, uint8_t *h,
                                uint8_t *i, uint8_t *j, uint8_t *k, uint8_t *l,
                                uint8_t *m, uint8_t *n, uint8_t *o, uint8_t *p,
                                uint8_t *q, uint8_t *r, uint8_t *s,
                                uint8_t *t) {
  return a + 1;
}

void* Function1Handle(void* a) {
  return a;
}

void* Function2Handle(void* a, void* b) {
  return a;
}

void* Function4Handle(void* a, void* b, void* c, void* d) {
  return a;
}

void* Function10Handle(void* a,
                       void* b,
                       void* c,
                       void* d,
                       void* e,
                       void* f,
                       void* g,
                       void* h,
                       void* i,
                       void* j) {
  return a;
}

void* Function20Handle(void* a,
                       void* b,
                       void* c,
                       void* d,
                       void* e,
                       void* f,
                       void* g,
                       void* h,
                       void* i,
                       void* j,
                       void* k,
                       void* l,
                       void* m,
                       void* n,
                       void* o,
                       void* p,
                       void* q,
                       void* r,
                       void* s,
                       void* t) {
  return a;
}
