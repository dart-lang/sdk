// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/metrics.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/log.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_FLAG(bool,
            print_metrics,
            false,
            "Print metrics when isolates (and the VM) are shutdown.");

Metric* Metric::vm_list_head_ = NULL;

Metric::Metric()
    : isolate_(NULL),
      name_(NULL),
      description_(NULL),
      unit_(kCounter),
      value_(0),
      next_(NULL) {}

void Metric::Init(Isolate* isolate,
                  const char* name,
                  const char* description,
                  Unit unit) {
  // Only called once.
  ASSERT(next_ == NULL);
  ASSERT(name != NULL);
  isolate_ = isolate;
  name_ = name;
  description_ = description;
  unit_ = unit;
  RegisterWithIsolate();
}

void Metric::Init(const char* name, const char* description, Unit unit) {
  // Only called once.
  ASSERT(next_ == NULL);
  ASSERT(name != NULL);
  name_ = name;
  description_ = description;
  unit_ = unit;
  RegisterWithVM();
}

Metric::~Metric() {
  // Only deregister metrics which had been registered. Metrics without a name
  // are from shallow copy isolates.
  if (name_ != NULL) {
    if (isolate_ == NULL) {
      DeregisterWithVM();
    } else {
      DeregisterWithIsolate();
    }
  }
}

#ifndef PRODUCT
static const char* UnitString(intptr_t unit) {
  switch (unit) {
    case Metric::kCounter:
      return "counter";
    case Metric::kByte:
      return "byte";
    case Metric::kMicrosecond:
      return "us";
    default:
      UNREACHABLE();
  }
  UNREACHABLE();
  return NULL;
}

void Metric::PrintJSON(JSONStream* stream) {
  if (!FLAG_support_service) {
    return;
  }
  JSONObject obj(stream);
  obj.AddProperty("type", "Counter");
  obj.AddProperty("name", name_);
  obj.AddProperty("description", description_);
  obj.AddProperty("unit", UnitString(unit()));
  if (isolate_ == NULL) {
    obj.AddFixedServiceId("vm/metrics/%s", name_);
  } else {
    obj.AddFixedServiceId("metrics/native/%s", name_);
  }
  // TODO(johnmccutchan): Overflow?
  double value_as_double = static_cast<double>(Value());
  obj.AddProperty("value", value_as_double);
}
#endif  // !PRODUCT

char* Metric::ValueToString(int64_t value, Unit unit) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  Zone* zone = thread->zone();
  ASSERT(zone != NULL);
  switch (unit) {
    case kCounter:
      return zone->PrintToString("%" Pd64 "", value);
    case kByte: {
      const char* scaled_suffix = "B";
      double scaled_value = static_cast<double>(value);
      if (value > GB) {
        scaled_suffix = "GB";
        scaled_value /= GB;
      } else if (value > MB) {
        scaled_suffix = "MB";
        scaled_value /= MB;
      } else if (value > KB) {
        scaled_suffix = "kB";
        scaled_value /= KB;
      }
      return zone->PrintToString("%.3f %s (%" Pd64 " B)", scaled_value,
                                 scaled_suffix, value);
    }
    case kMicrosecond: {
      const char* scaled_suffix = "us";
      double scaled_value = static_cast<double>(value);
      if (value > kMicrosecondsPerSecond) {
        scaled_suffix = "s";
        scaled_value /= kMicrosecondsPerSecond;
      } else if (value > kMicrosecondsPerMillisecond) {
        scaled_suffix = "ms";
        scaled_value /= kMicrosecondsPerMillisecond;
      }
      return zone->PrintToString("%.3f %s (%" Pd64 " us)", scaled_value,
                                 scaled_suffix, value);
    }
    default:
      UNREACHABLE();
      return NULL;
  }
}

char* Metric::ToString() {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  Zone* zone = thread->zone();
  ASSERT(zone != NULL);
  return zone->PrintToString("%s %s", name(), ValueToString(Value(), unit()));
}

bool Metric::NameExists(Metric* head, const char* name) {
  ASSERT(name != NULL);
  while (head != NULL) {
    const char* metric_name = head->name();
    ASSERT(metric_name != NULL);
    if (strcmp(metric_name, name) == 0) {
      return true;
    }
    head = head->next();
  }
  return false;
}

void Metric::RegisterWithIsolate() {
  ASSERT(isolate_ != NULL);
  ASSERT(next_ == NULL);
  // No duplicate names allowed.
  ASSERT(!NameExists(isolate_->metrics_list_head(), name()));
  Metric* head = isolate_->metrics_list_head();
  if (head != NULL) {
    set_next(head);
  }
  isolate_->set_metrics_list_head(this);
}

void Metric::DeregisterWithIsolate() {
  Metric* head = isolate_->metrics_list_head();
  ASSERT(head != NULL);
  // Handle head of list case.
  if (head == this) {
    isolate_->set_metrics_list_head(next());
    set_next(NULL);
    return;
  }
  Metric* previous = NULL;
  while (true) {
    previous = head;
    ASSERT(previous != NULL);
    head = head->next();
    if (head == NULL) {
      break;
    }
    if (head == this) {
      // Remove this from list.
      previous->set_next(head->next());
      set_next(NULL);
      return;
    }
    ASSERT(head != NULL);
  }
  UNREACHABLE();
}

void Metric::RegisterWithVM() {
  ASSERT(isolate_ == NULL);
  ASSERT(next_ == NULL);
  // No duplicate names allowed.
  ASSERT(!NameExists(vm_list_head_, name()));
  Metric* head = vm_list_head_;
  if (head != NULL) {
    set_next(head);
  }
  vm_list_head_ = this;
}

void Metric::DeregisterWithVM() {
  ASSERT(isolate_ == NULL);
  Metric* head = vm_list_head_;
  if (head == NULL) {
    return;
  }
  // Handle head of list case.
  if (head == this) {
    vm_list_head_ = next();
    set_next(NULL);
    return;
  }
  Metric* previous = NULL;
  while (true) {
    previous = head;
    ASSERT(previous != NULL);
    head = head->next();
    if (head == NULL) {
      break;
    }
    if (head == this) {
      // Remove this from list.
      previous->set_next(head->next());
      set_next(NULL);
      return;
    }
    ASSERT(head != NULL);
  }
  UNREACHABLE();
}

int64_t MetricHeapOldUsed::Value() const {
  ASSERT(isolate() == Isolate::Current());
  return isolate()->heap()->UsedInWords(Heap::kOld) * kWordSize;
}

int64_t MetricHeapOldCapacity::Value() const {
  ASSERT(isolate() == Isolate::Current());
  return isolate()->heap()->CapacityInWords(Heap::kOld) * kWordSize;
}

int64_t MetricHeapOldExternal::Value() const {
  ASSERT(isolate() == Isolate::Current());
  return isolate()->heap()->ExternalInWords(Heap::kOld) * kWordSize;
}

int64_t MetricHeapNewUsed::Value() const {
  ASSERT(isolate() == Isolate::Current());
  return isolate()->heap()->UsedInWords(Heap::kNew) * kWordSize;
}

int64_t MetricHeapNewCapacity::Value() const {
  ASSERT(isolate() == Isolate::Current());
  return isolate()->heap()->CapacityInWords(Heap::kNew) * kWordSize;
}

int64_t MetricHeapNewExternal::Value() const {
  ASSERT(isolate() == Isolate::Current());
  return isolate()->heap()->ExternalInWords(Heap::kNew) * kWordSize;
}

int64_t MetricHeapUsed::Value() const {
  ASSERT(isolate() == Isolate::Current());
  return isolate()->heap()->UsedInWords(Heap::kNew) * kWordSize +
         isolate()->heap()->UsedInWords(Heap::kOld) * kWordSize;
}

int64_t MetricIsolateCount::Value() const {
  return Isolate::IsolateListLength();
}

int64_t MetricPeakRSS::Value() const {
  return OS::MaxRSS();
}

#define VM_METRIC_VARIABLE(type, variable, name, unit)                         \
  static type vm_metric_##variable##_;
VM_METRIC_LIST(VM_METRIC_VARIABLE);
#undef VM_METRIC_VARIABLE

void Metric::InitOnce() {
#define VM_METRIC_INIT(type, variable, name, unit)                             \
  vm_metric_##variable##_.Init(name, NULL, Metric::unit);
  VM_METRIC_LIST(VM_METRIC_INIT);
#undef VM_METRIC_INIT
}

void Metric::Cleanup() {
  if (FLAG_print_metrics || FLAG_print_benchmarking_metrics) {
    // Create a zone to allocate temporary strings in.
    StackZone sz(Thread::Current());
    OS::PrintErr("Printing metrics for VM\n");
    Metric* current = Metric::vm_head();
    while (current != NULL) {
      OS::PrintErr("%s\n", current->ToString());
      current = current->next();
    }
    OS::PrintErr("\n");
  }
}

MaxMetric::MaxMetric() : Metric() {
  set_value(kMinInt64);
}

void MaxMetric::SetValue(int64_t new_value) {
  if (new_value > value()) {
    set_value(new_value);
  }
}

MinMetric::MinMetric() : Metric() {
  set_value(kMaxInt64);
}

void MinMetric::SetValue(int64_t new_value) {
  if (new_value < value()) {
    set_value(new_value);
  }
}

}  // namespace dart
