// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DARTUTILS_H_
#define BIN_DARTUTILS_H_

#include "bin/builtin.h"
#include "bin/utils.h"
#include "include/dart_api.h"
#include "platform/globals.h"

class CommandLineOptions {
 public:
  explicit CommandLineOptions(int max_count)
      : count_(0), max_count_(max_count), arguments_(NULL) {
    static const int kWordSize = sizeof(intptr_t);
    arguments_ = reinterpret_cast<const char **>(malloc(max_count * kWordSize));
    if (arguments_ == NULL) {
      max_count_ = 0;
    }
  }
  ~CommandLineOptions() {
    free(arguments_);
    count_ = 0;
    max_count_ = 0;
    arguments_ = NULL;
  }

  int count() const { return count_; }
  const char** arguments() const { return arguments_; }

  const char* GetArgument(int index) const {
    return (index >= 0 && index < count_) ? arguments_[index] : NULL;
  }
  void AddArgument(const char* argument) {
    if (count_ < max_count_) {
      arguments_[count_] = argument;
      count_ += 1;
    } else {
      abort();  // We should never get into this situation.
    }
  }

  void operator delete(void* pointer) { abort(); }

 private:
  void* operator new(size_t size);
  CommandLineOptions(const CommandLineOptions&);
  void operator=(const CommandLineOptions&);

  int count_;
  int max_count_;
  const char** arguments_;
};


class DartUtils {
 public:
  // TODO(turnidge): Clean up the implementations of these so that
  // they allow for proper error propagation.
  static int64_t GetIntegerValue(Dart_Handle value_obj);
  static bool GetInt64Value(Dart_Handle value_obj, int64_t* value);
  static const char* GetStringValue(Dart_Handle str_obj);
  static bool GetBooleanValue(Dart_Handle bool_obj);
  static void SetIntegerField(Dart_Handle handle,
                              const char* name,
                              intptr_t val);
  static intptr_t GetIntegerField(Dart_Handle handle,
                                  const char* name);
  static void SetStringField(Dart_Handle handle,
                             const char* name,
                             const char* val);
  static bool IsDartSchemeURL(const char* url_name);
  static bool IsDartExtensionSchemeURL(const char* url_name);
  static bool IsDartCryptoLibURL(const char* url_name);
  static bool IsDartIOLibURL(const char* url_name);
  static bool IsDartJsonLibURL(const char* url_name);
  static bool IsDartUriLibURL(const char* url_name);
  static bool IsDartUtfLibURL(const char* url_name);
  static Dart_Handle CanonicalizeURL(CommandLineOptions* url_mapping,
                                     Dart_Handle library,
                                     const char* url_str);
  static Dart_Handle ReadStringFromFile(const char* filename);
  static Dart_Handle LoadSource(CommandLineOptions* url_mapping,
                                Dart_Handle library,
                                Dart_Handle url,
                                Dart_LibraryTag tag,
                                const char* filename,
                                Dart_Handle import_map);
  static bool PostNull(Dart_Port port_id);
  static bool PostInt32(Dart_Port port_id, int32_t value);

  // Create a new Dart OSError object with the current OS error.
  static Dart_Handle NewDartOSError();
  // Create a new Dart OSError object with the provided OS error.
  static Dart_Handle NewDartOSError(OSError* os_error);

  static const char* kDartScheme;
  static const char* kDartExtensionScheme;
  static const char* kBuiltinLibURL;
  static const char* kCoreLibURL;
  static const char* kCoreImplLibURL;
  static const char* kCryptoLibURL;
  static const char* kIOLibURL;
  static const char* kJsonLibURL;
  static const char* kUriLibURL;
  static const char* kUtfLibURL;
  static const char* kIsolateLibURL;

  static const char* kIdFieldName;

 private:
  static const char* GetCanonicalPath(const char* reference_dir,
                                      const char* filename);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(DartUtils);
};


class CObject {
 public:
  explicit CObject(Dart_CObject *cobject) : cobject_(cobject) {}
  Dart_CObject::Type type() { return cobject_->type; }

  bool IsNull() { return type() == Dart_CObject::kNull; }
  bool IsBool() { return type() == Dart_CObject::kBool; }
  bool IsInt32() { return type() == Dart_CObject::kInt32; }
  bool IsInt64() { return type() == Dart_CObject::kInt64; }
  bool IsInt32OrInt64() { return IsInt32() || IsInt64(); }
  bool IsIntptr() { return IsInt32OrInt64(); }
  bool IsBigint() { return type() == Dart_CObject::kBigint; }
  bool IsDouble() { return type() == Dart_CObject::kDouble; }
  bool IsString() { return type() == Dart_CObject::kString; }
  bool IsArray() { return type() == Dart_CObject::kArray; }
  bool IsUint8Array() { return type() == Dart_CObject::kUint8Array; }

  bool IsTrue() {
    return type() == Dart_CObject::kBool && cobject_->value.as_bool;
  }

  bool IsFalse() {
    return type() == Dart_CObject::kBool && !cobject_->value.as_bool;
  }

  void* operator new(size_t size) {
    return Dart_ScopeAllocate(size);
  }

  static CObject* Null();
  static CObject* True();
  static CObject* False();
  static CObject* Bool(bool value);
  static Dart_CObject* NewInt32(int32_t value);
  static Dart_CObject* NewInt64(int64_t value);
  static Dart_CObject* NewIntptr(intptr_t value);
  // TODO(sgjesse): Add support for kBigint.
  static Dart_CObject* NewDouble(double value);
  static Dart_CObject* NewString(int length);
  static Dart_CObject* NewString(const char* str);
  static Dart_CObject* NewArray(int length);
  static Dart_CObject* NewUint8Array(int length);

  Dart_CObject* AsApiCObject() { return cobject_; }

  // Create a new CObject array with an illegal arguments error.
  static CObject* IllegalArgumentError();
  // Create a new CObject array with a file closed error.
  static CObject* FileClosedError();
  // Create a new CObject array with the current OS error.
  static CObject* NewOSError();
  // Create a new CObject array with the specified OS error.
  static CObject* NewOSError(OSError* os_error);

 protected:
  CObject() : cobject_(NULL) {}
  Dart_CObject* cobject_;

 private:
  static Dart_CObject* New(Dart_CObject::Type type, int additional_bytes = 0);

  static Dart_CObject api_null_;
  static Dart_CObject api_true_;
  static Dart_CObject api_false_;
  static CObject null_;
  static CObject true_;
  static CObject false_;
};


#define DECLARE_COBJECT_CONSTRUCTORS(t)                                        \
  explicit CObject##t(Dart_CObject *cobject) : CObject(cobject) {              \
    ASSERT(type() == Dart_CObject::k##t);                                      \
    cobject_ = cobject;                                                        \
  }                                                                            \
  explicit CObject##t(CObject* cobject) : CObject() {                          \
    ASSERT(cobject != NULL);                                                   \
    ASSERT(cobject->type() == Dart_CObject::k##t);                             \
    cobject_ = cobject->AsApiCObject();                                        \
  }


class CObjectBool : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(Bool)

  bool Value() const { return cobject_->value.as_bool; }
};


class CObjectInt32 : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(Int32)

  int32_t Value() const { return cobject_->value.as_int32; }
};


class CObjectInt64 : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(Int64)

  int64_t Value() const { return cobject_->value.as_int64; }
};


class CObjectIntptr : public CObject {
 public:
  explicit CObjectIntptr(Dart_CObject *cobject) : CObject(cobject) {
    ASSERT(type() == Dart_CObject::kInt32 || type() == Dart_CObject::kInt64);
    cobject_ = cobject;
  }
  explicit CObjectIntptr(CObject* cobject) : CObject() {
    ASSERT(cobject != NULL);
    ASSERT(cobject->type() == Dart_CObject::kInt64 ||
           cobject->type() == Dart_CObject::kInt32);
    cobject_ = cobject->AsApiCObject();
  }

  intptr_t Value()  {
    intptr_t result;
    if (type() == Dart_CObject::kInt32) {
      result = cobject_->value.as_int32;
    } else {
      result = cobject_->value.as_int64;
    }
    return result;
  }
};


class CObjectBigint : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(Bigint)

  char* Value() const { return cobject_->value.as_bigint; }
};


class CObjectDouble : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(Double)

  double Value() const { return cobject_->value.as_double; }
};


class CObjectString : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(String)

  int Length() const { return strlen(cobject_->value.as_string); }
  char* CString() const { return cobject_->value.as_string; }
};


class CObjectArray : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(Array)

  int Length() const { return cobject_->value.as_array.length; }
  CObject* operator[](int index) const {
    return new CObject(cobject_->value.as_array.values[index]);
  }
  void SetAt(int index, CObject* value) {
    cobject_->value.as_array.values[index] = value->AsApiCObject();
  }
};


class CObjectUint8Array : public CObject {
 public:
  DECLARE_COBJECT_CONSTRUCTORS(Uint8Array)

  int Length() const { return cobject_->value.as_byte_array.length; }
  uint8_t* Buffer() const { return cobject_->value.as_byte_array.values; }
};

#endif  // BIN_DARTUTILS_H_
