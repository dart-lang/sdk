// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_JSON_PARSER_H_
#define RUNTIME_VM_JSON_PARSER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/zone.h"

namespace dart {

class ParsedJSONArray;

class ParsedJSONValue : public ZoneAllocated {
 public:
  virtual ~ParsedJSONValue() {}

  virtual bool IsObject() const { return false; }
  virtual bool IsArray() const { return false; }
  virtual bool IsString() const { return false; }
  virtual bool IsNumber() const { return false; }
  virtual bool IsBoolean() const { return false; }
  virtual bool IsError() const { return false; }
};

class ParsedJSONString : public ParsedJSONValue {
 public:
  explicit ParsedJSONString(const char* value) : value_(value) {}
  bool Equals(const char* other) { return strcmp(value_, other) == 0; }
  const char* value() { return value_; }
  virtual bool IsString() const { return true; }

 private:
  const char* value_;
};

class ParsedJSONNumber : public ParsedJSONValue {
 public:
  explicit ParsedJSONNumber(int64_t value) : value_(value) {}

  int64_t value() { return value_; }
  virtual bool IsNumber() const { return true; }

 private:
  int64_t value_;
};

class ParsedJSONBoolean : public ParsedJSONValue {
 public:
  explicit ParsedJSONBoolean(bool value) : value_(value) {}

  bool value() { return value_; }
  virtual bool IsBoolean() const { return true; }

 private:
  bool value_;
};

class ParsedJSONNull : public ParsedJSONValue {
 public:
  virtual bool IsNull() const { return true; }
};

class ParsedJSONObject : public ParsedJSONValue {
 public:
  ParsedJSONObject(intptr_t length, ParsedJSONValue** keys_and_values)
      : length_(length), keys_and_values_(keys_and_values) {}

  ParsedJSONValue* At(const char* key) const {
    for (intptr_t i = 0; i < length_; i += 2) {
      ASSERT(keys_and_values_[i]->IsString());
      ParsedJSONString* jskey =
          static_cast<ParsedJSONString*>(keys_and_values_[i]);
      if (jskey->Equals(key)) {
        return keys_and_values_[i + 1];
      }
    }
    return NULL;
  }

  virtual bool IsObject() const { return true; }

  ParsedJSONNumber* NumberAt(const char* key) {
    ParsedJSONValue* member = At(key);
    if ((member == NULL) || !member->IsNumber()) {
      return NULL;
    }
    return static_cast<ParsedJSONNumber*>(member);
  }

  ParsedJSONString* StringAt(const char* key) {
    ParsedJSONValue* member = At(key);
    if ((member == NULL) || !member->IsString()) {
      return NULL;
    }
    return static_cast<ParsedJSONString*>(member);
  }

  ParsedJSONBoolean* BooleanAt(const char* key) {
    ParsedJSONValue* member = At(key);
    if ((member == NULL) || !member->IsBoolean()) {
      return NULL;
    }
    return static_cast<ParsedJSONBoolean*>(member);
  }

  inline ParsedJSONArray* ArrayAt(const char* key);

 private:
  intptr_t length_;
  ParsedJSONValue** keys_and_values_;
};

class ParsedJSONArray : public ParsedJSONValue {
 public:
  ParsedJSONArray(intptr_t length, ParsedJSONValue** elements)
      : length_(length), elements_(elements) {}

  ParsedJSONValue* At(intptr_t index) const {
    ASSERT(index < length_);
    return elements_[index];
  }

  intptr_t Length() const { return length_; }

  virtual bool IsArray() const { return true; }

  ParsedJSONObject* ObjectAt(intptr_t index) {
    ParsedJSONValue* element = At(index);
    if ((element == NULL) || !element->IsObject()) {
      return NULL;
    }
    return static_cast<ParsedJSONObject*>(element);
  }

  ParsedJSONNumber* NumberAt(intptr_t index) {
    ParsedJSONValue* element = At(index);
    if ((element == NULL) || !element->IsNumber()) {
      return NULL;
    }
    return static_cast<ParsedJSONNumber*>(element);
  }

 private:
  intptr_t length_;
  ParsedJSONValue** elements_;
};

class ParsedJSONError : public ParsedJSONValue {
 public:
  explicit ParsedJSONError(const char* message, intptr_t position)
      : message_(message), position_(position) {}

  virtual bool IsError() const { return true; }

  const char* message() const { return message_; }
  intptr_t position() const { return position_; }

 private:
  const char* message_;
  intptr_t position_;
};

class JSONParser {
 public:
  JSONParser(const char* buffer, intptr_t length, Zone* zone)
      : buffer_(buffer), position_(0), length_(length), zone_(zone) {}

  ParsedJSONValue* ParseValue() {
    ConsumeWhitespace();
    if (Peek() == '\"') return ParseString();
    if (IsDigitOrMinus(Peek())) return ParseNumber();
    if (Peek() == '{') return ParseObject();
    if (Peek() == '[') return ParseArray();
    if (PeekAndConsume("true")) return new (zone_) ParsedJSONBoolean(true);
    if (PeekAndConsume("false")) return new (zone_) ParsedJSONBoolean(false);
    if (PeekAndConsume("null")) return new (zone_) ParsedJSONNull();
    return Error("value expected");
  }

 private:
  intptr_t Available() const { return length_ - position_; }
  char Peek() const {
    if (position_ < length_) return buffer_[position_];
    return 0;
  }
  char Consume() {
    ASSERT(position_ < length_);
    return buffer_[position_++];
  }
  bool PeekAndConsume(const char* expected) {
    intptr_t n = strlen(expected);
    if (Available() < n) return false;
    if (strncmp(&buffer_[position_], expected, n) != 0) return false;
    position_ += n;
    return true;
  }
  void ConsumeWhitespace() {
    while ((Available() > 0) && (buffer_[position_] < ' '))
      position_++;
  }
  bool IsDigit(char c) { return c >= '0' && c <= '9'; }
  bool IsDigitOrMinus(char c) { return (c == '-') || (c >= '0' && c <= '9'); }

  ParsedJSONValue* ParseString() {
    ConsumeWhitespace();
    if (Peek() != '\"') return Error("string expected");
    Consume();
    intptr_t start = position_;
    for (;;) {
      if (Available() == 0) return Error("unterminated string");
      if (Consume() == '\"') break;
    }
    intptr_t end = position_ - 1;

    char* cstr = zone_->Alloc<char>(end - start + 1);
    intptr_t dst_pos = 0;
    for (intptr_t src_pos = start; src_pos < end; src_pos++) {
      if (buffer_[src_pos] == '\\') {
        src_pos++;
      }
      cstr[dst_pos++] = buffer_[src_pos];
    }
    cstr[dst_pos] = '\0';

    return new (zone_) ParsedJSONString(cstr);
  }

  ParsedJSONValue* ParseNumber() {
    ConsumeWhitespace();
    bool negate = false;
    if (Peek() == '-') {
      Consume();
      negate = true;
    }
    if (!IsDigit(Peek())) return Error("number expected");
    int64_t value = 0;
    for (;;) {
      if (!IsDigit(Peek())) break;
      char c = Consume();
      value *= 10;
      value += (c - '0');
    }
    if (negate) {
      value = -value;
    }
    return new (zone_) ParsedJSONNumber(value);
  }

  ParsedJSONValue* ParseObject() {
    ConsumeWhitespace();
    if (Peek() != '{') return Error("object expected");
    Consume();
    ConsumeWhitespace();
    if (Peek() == '}') return new (zone_) ParsedJSONObject(0, NULL);
    ZoneGrowableArray<ParsedJSONValue*>* keys_and_values =
        new (zone_) ZoneGrowableArray<ParsedJSONValue*>(zone_, 6);
    for (;;) {
      ParsedJSONValue* key = ParseString();
      if (key->IsError()) return key;
      ConsumeWhitespace();
      if (Consume() != ':') return Error(": expected");
      ConsumeWhitespace();
      ParsedJSONValue* value = ParseValue();
      if (value->IsError()) return value;
      ConsumeWhitespace();

      keys_and_values->Add(key);
      keys_and_values->Add(value);

      char c = Consume();
      if (c == '}') break;
      if (c != ',') return Error(", expected (object)");
      ConsumeWhitespace();
    }

    return new (zone_)
        ParsedJSONObject(keys_and_values->length(), keys_and_values->data());
  }

  ParsedJSONValue* ParseArray() {
    ConsumeWhitespace();
    if (Peek() != '[') return Error("array expected");
    Consume();
    ConsumeWhitespace();
    if (Peek() == ']') {
      Consume();
      return new (zone_) ParsedJSONArray(0, NULL);
    }
    ZoneGrowableArray<ParsedJSONValue*>* elements =
        new (zone_) ZoneGrowableArray<ParsedJSONValue*>(zone_, 6);
    for (;;) {
      ParsedJSONValue* element = ParseValue();
      if (element->IsError()) return element;
      ConsumeWhitespace();

      elements->Add(element);

      char c = Consume();
      if (c == ']') break;
      if (c != ',') return Error(", expected (array)");
      ConsumeWhitespace();
    }

    return new (zone_) ParsedJSONArray(elements->length(), elements->data());
  }

 private:
  ParsedJSONError* Error(const char* message) {
    return new (zone_) ParsedJSONError(message, position_);
  }

  const char* const buffer_;
  intptr_t position_;
  intptr_t length_;
  Zone* zone_;
};

ParsedJSONArray* ParsedJSONObject::ArrayAt(const char* key) {
  ParsedJSONValue* member = At(key);
  if ((member == NULL) || !member->IsArray()) {
    return NULL;
  }
  return static_cast<ParsedJSONArray*>(member);
}

}  // namespace dart

#endif  // RUNTIME_VM_JSON_PARSER_H_
