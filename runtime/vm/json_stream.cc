// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/object.h"
#include "vm/json_stream.h"


namespace dart {

JSONStream::JSONStream(TextBuffer* buffer) {
  ASSERT(buffer != NULL);
  buffer_ = buffer;
  open_objects_ = 0;
}


JSONStream::~JSONStream() {
}


void JSONStream::Clear() {
  buffer_->Clear();
  open_objects_ = 0;
}


void JSONStream::OpenObject(const char* property_name) {
  PrintCommaIfNeeded();
  open_objects_++;
  if (property_name != NULL) {
    PrintPropertyName(property_name);
  }
  buffer_->AddChar('{');
}


void JSONStream::CloseObject() {
  ASSERT(open_objects_ > 0);
  open_objects_--;
  buffer_->AddChar('}');
}


void JSONStream::OpenArray(const char* property_name) {
  PrintCommaIfNeeded();
  if (property_name != NULL) {
    PrintPropertyName(property_name);
  }
  open_objects_++;
  buffer_->AddChar('[');
}


void JSONStream::CloseArray() {
  ASSERT(open_objects_ > 0);
  open_objects_--;
  buffer_->AddChar(']');
}


void JSONStream::PrintValueBool(bool b) {
  PrintCommaIfNeeded();
  buffer_->Printf("%s", b ? "true" : "false");
}


void JSONStream::PrintValue(intptr_t i) {
  PrintCommaIfNeeded();
  buffer_->Printf("%"Pd"", i);
}


void JSONStream::PrintValue(double d) {
  PrintCommaIfNeeded();
  buffer_->Printf("%f", d);
}


void JSONStream::PrintValue(const char* s) {
  PrintCommaIfNeeded();
  buffer_->Printf("\"%s\"", s);
}


void JSONStream::PrintValue(const Object& o, bool ref) {
  PrintCommaIfNeeded();
  o.PrintToJSONStream(this, ref);
}


void JSONStream::PrintPropertyBool(const char* name, bool b) {
  PrintPropertyName(name);
  PrintValueBool(b);
}


void JSONStream::PrintProperty(const char* name, intptr_t i) {
  PrintPropertyName(name);
  PrintValue(i);
}


void JSONStream::PrintProperty(const char* name, double d) {
  PrintPropertyName(name);
  PrintValue(d);
}


void JSONStream::PrintProperty(const char* name, const char* s) {
  PrintPropertyName(name);
  PrintValue(s);
}


void JSONStream::PrintProperty(const char* name, const Object& o, bool ref) {
  PrintPropertyName(name);
  PrintValue(o, ref);
}


void JSONStream::PrintPropertyName(const char* name) {
  ASSERT(name != NULL);
  PrintCommaIfNeeded();
  buffer_->Printf("\"%s\":", name);
}


void JSONStream::PrintCommaIfNeeded() {
  if (NeedComma()) {
    buffer_->AddChar(',');
  }
}


bool JSONStream::NeedComma() {
  const char* buffer = buffer_->buf();
  intptr_t length = buffer_->length();
  if (length == 0) {
    return false;
  }
  char ch = buffer[length-1];
  return ch != '[' && ch != '{' && ch != ':' && ch != ',';
}

}  // namespace dart

