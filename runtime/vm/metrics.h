// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_METRICS_H_
#define RUNTIME_VM_METRICS_H_

#include "vm/allocation.h"

namespace dart {

class Isolate;
class IsolateGroup;
class JSONStream;

// Metrics for each isolate group.
//
// Golem uses `--print-metrics` and relies on
//
//   heap.old.capacity.max
//   heap.new.capacity.max
//
// g3 uses metrics via Dart API:
//
//   Dart_Heap{Old,New}{Used,Capacity,External}
//
// All metrics are exposed via vm-service protocol.
//
#define DART_API_ISOLATE_GROUP_METRIC_LIST(V)                                  \
  V(MetricHeapOldUsed, HeapOldUsed, "heap.old.used", kByte)                    \
  V(MetricHeapOldCapacity, HeapOldCapacity, "heap.old.capacity", kByte)        \
  V(MetricHeapOldExternal, HeapOldExternal, "heap.old.external", kByte)        \
  V(MetricHeapNewUsed, HeapNewUsed, "heap.new.used", kByte)                    \
  V(MetricHeapNewCapacity, HeapNewCapacity, "heap.new.capacity", kByte)        \
  V(MetricHeapNewExternal, HeapNewExternal, "heap.new.external", kByte)

#define ISOLATE_GROUP_METRIC_LIST(V)                                           \
  DART_API_ISOLATE_GROUP_METRIC_LIST(V)                                        \
  V(MaxMetric, HeapOldUsedMax, "heap.old.used.max", kByte)                     \
  V(MaxMetric, HeapOldCapacityMax, "heap.old.capacity.max", kByte)             \
  V(MaxMetric, HeapNewUsedMax, "heap.new.used.max", kByte)                     \
  V(MaxMetric, HeapNewCapacityMax, "heap.new.capacity.max", kByte)             \
  V(MetricHeapUsed, HeapGlobalUsed, "heap.global.used", kByte)                 \
  V(MaxMetric, HeapGlobalUsedMax, "heap.global.used.max", kByte)

// Metrics for each isolate.
//
// All metrics are exposed via vm-service protocol.
#define ISOLATE_METRIC_LIST(V)                                                 \
  V(Metric, RunnableLatency, "isolate.runnable.latency", kMicrosecond)         \
  V(Metric, RunnableHeapSize, "isolate.runnable.heap", kByte)

class Metric {
 public:
  enum Unit {
    kCounter,
    kByte,
    kMicrosecond,
  };

  Metric();

#if !defined(PRODUCT)
  static void Init();
  static void Cleanup();
#endif  // !defined(PRODUCT)

  // Initialize a metric for an isolate.
  void InitInstance(Isolate* isolate,
                    const char* name,
                    const char* description,
                    Unit unit);

  // Initialize a metric for an isolate group.
  void InitInstance(IsolateGroup* isolate_group,
                    const char* name,
                    const char* description,
                    Unit unit);

  // Initialize a metric for the VM.
  void InitInstance(const char* name, const char* description, Unit unit);

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

  const char* name() const { return name_; }
  const char* description() const { return description_; }
  Unit unit() const { return unit_; }

  // Only non-null for isolate specific metrics.
  Isolate* isolate() const { return isolate_; }

  // Only non-null for isolate group specific metrics.
  IsolateGroup* isolate_group() const { return isolate_group_; }

  static Metric* vm_head() { return vm_list_head_; }

  // Override to get a callback when value is serialized to JSON.
  // Use this for metrics that produce their value on demand.
  virtual int64_t Value() const { return value(); }

 private:
  Isolate* isolate_ = nullptr;
  IsolateGroup* isolate_group_ = nullptr;
  const char* name_ = nullptr;
  const char* description_ = nullptr;
  Unit unit_;
  int64_t value_;

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
 public:
  virtual int64_t Value() const;
};

class MetricHeapOldCapacity : public Metric {
 public:
  virtual int64_t Value() const;
};

class MetricHeapOldExternal : public Metric {
 public:
  virtual int64_t Value() const;
};

class MetricHeapNewUsed : public Metric {
 public:
  virtual int64_t Value() const;
};

class MetricHeapNewCapacity : public Metric {
 public:
  virtual int64_t Value() const;
};

class MetricHeapNewExternal : public Metric {
 public:
  virtual int64_t Value() const;
};

#if !defined(PRODUCT)
class MetricIsolateCount : public Metric {
 public:
  virtual int64_t Value() const;
};

class MetricCurrentRSS : public Metric {
 public:
  virtual int64_t Value() const;
};

class MetricPeakRSS : public Metric {
 public:
  virtual int64_t Value() const;
};
#endif  // !defined(PRODUCT)

class MetricHeapUsed : public Metric {
 public:
  virtual int64_t Value() const;
};

}  // namespace dart

#endif  // RUNTIME_VM_METRICS_H_
