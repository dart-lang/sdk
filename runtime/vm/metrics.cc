// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/metrics.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/native_entry.h"
#include "vm/runtime_entry.h"
#include "vm/object.h"

namespace dart {

Metric* Metric::vm_list_head_ = NULL;

Metric::Metric()
    : isolate_(NULL),
      name_(NULL),
      description_(NULL),
      unit_(kCounter),
      value_(0),
      next_(NULL) {
}


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
  if (isolate_ == NULL) {
    DeregisterWithVM();
  } else {
    DeregisterWithIsolate();
  }
}


static const char* UnitString(intptr_t unit) {
  switch (unit) {
    case Metric::kCounter: return "counter";
    case Metric::kByte: return "byte";
    default:
      UNREACHABLE();
  }
  UNREACHABLE();
  return NULL;
}


void Metric::PrintJSON(JSONStream* stream) {
  JSONObject obj(stream);
  obj.AddProperty("type", "Counter");
  obj.AddProperty("name", name_);
  obj.AddProperty("description", description_);
  obj.AddProperty("unit", UnitString(unit()));
  obj.AddPropertyF("id", "metrics/vm/%s", name_);
  // TODO(johnmccutchan): Overflow?
  double value_as_double = static_cast<double>(Value());
  obj.AddProperty("value", value_as_double);
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


int64_t MetricIsolateCount::Value() const {
  return Isolate::IsolateListLength();
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

}  // namespace dart
