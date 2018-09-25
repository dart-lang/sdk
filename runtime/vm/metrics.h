// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_METRICS_H_
#define RUNTIME_VM_METRICS_H_

#include "vm/allocation.h"

namespace dart {

class Isolate;
class JSONStream;

// Metrics for each isolate.
#define ISOLATE_METRIC_LIST(V)                                                 \
  V(MetricHeapOldUsed, HeapOldUsed, "heap.old.used", kByte)                    \
  V(MaxMetric, HeapOldUsedMax, "heap.old.used.max", kByte)                     \
  V(MetricHeapOldCapacity, HeapOldCapacity, "heap.old.capacity", kByte)        \
  V(MaxMetric, HeapOldCapacityMax, "heap.old.capacity.max", kByte)             \
  V(MetricHeapOldExternal, HeapOldExternal, "heap.old.external", kByte)        \
  V(MetricHeapNewUsed, HeapNewUsed, "heap.new.used", kByte)                    \
  V(MaxMetric, HeapNewUsedMax, "heap.new.used.max", kByte)                     \
  V(MetricHeapNewCapacity, HeapNewCapacity, "heap.new.capacity", kByte)        \
  V(MaxMetric, HeapNewCapacityMax, "heap.new.capacity.max", kByte)             \
  V(MetricHeapNewExternal, HeapNewExternal, "heap.new.external", kByte)        \
  V(MetricHeapUsed, HeapGlobalUsed, "heap.global.used", kByte)                 \
  V(MaxMetric, HeapGlobalUsedMax, "heap.global.used.max", kByte)               \
  V(Metric, RunnableLatency, "isolate.runnable.latency", kMicrosecond)         \
  V(Metric, RunnableHeapSize, "isolate.runnable.heap", kByte)

#define VM_METRIC_LIST(V)                                                      \
  V(MetricIsolateCount, IsolateCount, "vm.isolate.count", kCounter)            \
  V(MetricCurrentRSS, CurrentRSS, "vm.memory.current", kByte)                  \
  V(MetricPeakRSS, PeakRSS, "vm.memory.max", kByte)

class Metric {
 public:
  enum Unit {
    kCounter,
    kByte,
    kMicrosecond,
  };

  Metric();

  static void InitOnce();

  static void Cleanup();

  // Initialize and register a metric for an isolate.
  void Init(Isolate* isolate,
            const char* name,
            const char* description,
            Unit unit);

  // Initialize and register a metric for the VM.
  void Init(const char* name, const char* description, Unit unit);

  virtual ~Metric();

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream);
#endif  // !PRODUCT

  // Returns a zone allocated string.
  static char* ValueToString(int64_t value, Unit unit);

  // Returns a zone allocated string.
  char* ToString();

  int64_t value() const { return value_; }
  void set_value(int64_t value) { value_ = value; }

  void increment() { value_++; }

  Metric* next() const { return next_; }
  void set_next(Metric* next) { next_ = next; }

  const char* name() const { return name_; }
  const char* description() const { return description_; }
  Unit unit() const { return unit_; }

  // Will be NULL for Metric that is VM-global.
  Isolate* isolate() const { return isolate_; }

  static Metric* vm_head() { return vm_list_head_; }

 protected:
  // Override to get a callback when value is serialized to JSON.
  // Use this for metrics that produce their value on demand.
  virtual int64_t Value() const { return value(); }

 private:
  Isolate* isolate_;
  const char* name_;
  const char* description_;
  Unit unit_;
  int64_t value_;
  Metric* next_;

  static bool NameExists(Metric* head, const char* name);

  void RegisterWithIsolate();
  void DeregisterWithIsolate();
  void RegisterWithVM();
  void DeregisterWithVM();

  static Metric* vm_list_head_;
  DISALLOW_COPY_AND_ASSIGN(Metric);
};

// A Metric class that reports the maximum value observed.
// Initial maximum is kMinInt64.
class MaxMetric : public Metric {
 public:
  MaxMetric();

  void SetValue(int64_t new_value);
};

// A Metric class that reports the minimum value observed.
// Initial minimum is kMaxInt64.
class MinMetric : public Metric {
 public:
  MinMetric();

  void SetValue(int64_t new_value);
};

class MetricHeapOldUsed : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricHeapOldCapacity : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricHeapOldExternal : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricHeapNewUsed : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricHeapNewCapacity : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricHeapNewExternal : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricIsolateCount : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricCurrentRSS : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricPeakRSS : public Metric {
 protected:
  virtual int64_t Value() const;
};

class MetricHeapUsed : public Metric {
 protected:
  virtual int64_t Value() const;
};

}  // namespace dart

#endif  // RUNTIME_VM_METRICS_H_
