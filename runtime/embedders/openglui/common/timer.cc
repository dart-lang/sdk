// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/timer.h"

#define NANO (+1.0E-9)

#ifdef __MACH__
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <sys/time.h>

#define GIGA UINT64_C(1000000000)

#define CLOCK_REALTIME    0
#define CLOCK_MONOTONIC   1

double timebase = 0.0;
uint64_t timestart = 0;

void clock_gettime(int type, timespec* t) {
  if (!timestart) {
    mach_timebase_info_data_t tb = { 0, 1 };
    mach_timebase_info(&tb);
    timebase = tb.numer;
    timebase /= tb.denom;
    timestart = mach_absolute_time();
  }
  if (type == CLOCK_MONOTONIC) {
    double diff = (mach_absolute_time() - timestart) * timebase;
    t->tv_sec = diff * NANO;
    t->tv_nsec = diff - (t->tv_sec * GIGA);
  } else {  // type == CLOCK_REALTIME
    struct timeval now;
    gettimeofday(&now, NULL);
    t->tv_sec  = now.tv_sec;
    t->tv_nsec = now.tv_usec * 1000;
  }
}
#endif

Timer::Timer() : elapsed_(0.0f), last_time_(0.0) {
}

void Timer::Reset() {
  elapsed_ = 0.0f;
  last_time_ = Now();
}

void Timer::Update() {
  double current = Now();
  elapsed_ = (current - last_time_);
  last_time_ = current;
}

double Timer::Now() {
  timespec timeval;
  clock_gettime(CLOCK_MONOTONIC, &timeval);
  return timeval.tv_sec + (timeval.tv_nsec * NANO);
}

float Timer::Elapsed() {
  return elapsed_;
}

