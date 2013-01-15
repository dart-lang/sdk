// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/android/timer.h"

Timer::Timer() : elapsed_(0.0f), last_time_(0.0) {
}

void Timer::reset() {
  elapsed_ = 0.0f;
  last_time_ = now();
}

void Timer::update() {
  double current = now();
  elapsed_ = (current - last_time_);
  last_time_ = current;
}

double Timer::now() {
  timespec timeval;
  clock_gettime(CLOCK_MONOTONIC, &timeval);
  return timeval.tv_sec + (timeval.tv_nsec * 1.0e-9);
}

float Timer::elapsed() {
  return elapsed_;
}
