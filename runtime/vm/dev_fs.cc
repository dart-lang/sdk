// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <map>
#include <string>
#include <vector>

#include "vm/dev_fs.h"

#include "vm/hash_table.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/unicode.h"

namespace dart {

static const uint8_t decode_table[256] = {
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
  52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
  64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
  64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
  41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
};

class Base64 {
 public:
  static void decode(const char* base64,
                     std::vector<uint8_t>* output) {
    ASSERT(output != NULL);
    ASSERT(base64 != NULL);
    const intptr_t base64_len = strlen(base64);
    int b[4];
    for (intptr_t i = 0; i < base64_len; i += 4) {
      b[0] = decode_table[static_cast<uint8_t>(base64[i])];
      b[1] = decode_table[static_cast<uint8_t>(base64[i + 1])];
      b[2] = decode_table[static_cast<uint8_t>(base64[i + 2])];
      b[3] = decode_table[static_cast<uint8_t>(base64[i + 3])];
      output->push_back((b[0] << 2) | (b[1] >> 4));
      if (b[2] < 64) {
        output->push_back((b[1] << 4) | (b[2] >> 2));
        if (b[3] < 64)  {
          output->push_back((b[2] << 6) | b[3]);
        }
      }
    }
  }
};


class FileSystem {
 public:
  explicit FileSystem(const std::string& name)
    : name_(name) {
  }

  ~FileSystem() {
  }

  bool ReadFile(const std::string& path,
                std::vector<uint8_t>** file_contents) {
    *file_contents = NULL;
    std::map<std::string, std::vector<uint8_t>*>::iterator iter;
    iter = files_.find(path);
    if (iter == files_.end()) {
      return false;
    }
    *file_contents = iter->second;
    return true;
  }

  void DeleteFile(const std::string& path) {
    std::map<std::string, std::vector<uint8_t>*>::iterator iter;
    iter = files_.find(path);
    if (iter == files_.end()) {
      return;
    }
    std::vector<uint8_t>* contents = iter->second;
    files_.erase(iter);
    delete contents;
  }

  void WriteFile(const std::string& path,
                 const char* file_contents) {
    DeleteFile(path);
    std::vector<uint8_t>* data = new std::vector<uint8_t>();
    Base64::decode(file_contents, data);
    files_[path] = data;
  }

  void ListFiles(JSONStream* js) {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "FSFilesList");
    JSONArray jsarr(&jsobj, "files");
    std::map<std::string, std::vector<uint8_t>*>::iterator iter;
    for (iter = files_.begin(); iter != files_.end(); iter++) {
      JSONObject file_info(&jsarr);
      file_info.AddProperty("name", iter->first.c_str());
      file_info.AddProperty64("size",
                              static_cast<int64_t>(iter->second->size()));
    }
  }

 private:
  std::string name_;

  std::map<std::string, std::vector<uint8_t>*> files_;
};

// Some static state is held outside of the DevFS class so that we don't
// have to include stl headers in our vm/ headers.
static std::map<std::string, FileSystem*>* file_systems_;

Mutex* DevFS::mutex_ = NULL;


void DevFS::Init() {
  if (mutex_ != NULL) {
    // Already initialized.
    ASSERT(file_systems_ != NULL);
    return;
  }
  mutex_ = new Mutex();
  file_systems_ = new std::map<std::string, FileSystem*>();
  ASSERT(mutex_ != NULL);
  ASSERT(file_systems_ != NULL);
}


void DevFS::Cleanup() {
  delete mutex_;
  mutex_ = NULL;
  std::map<std::string, FileSystem*>::iterator iter;
  for (iter = file_systems_->begin(); iter != file_systems_->end(); iter++) {
    FileSystem* fs = iter->second;
    delete fs;
  }
  delete file_systems_;
  file_systems_ = NULL;
}


void DevFS::ListFileSystems(JSONStream* js) {
  SafepointMutexLocker ml(mutex_);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "FSList");
  JSONArray jsarr(&jsobj, "fsNames");

  std::map<std::string, FileSystem*>::iterator iter;
  for (iter = file_systems_->begin(); iter != file_systems_->end(); iter++) {
    const std::string& key = iter->first;
    jsarr.AddValue(key.c_str());
  }
}


FileSystem* DevFS::LookupFileSystem(const char* fs_name) {
  std::string key = std::string(fs_name);
  std::map<std::string, FileSystem*>::iterator iter;
  iter = file_systems_->find(key);
  if (iter != file_systems_->end()) {
    return iter->second;
  }
  return NULL;
}


FileSystem* DevFS::LookupFileSystem(const String& fs_name) {
  return LookupFileSystem(fs_name.ToCString());
}


void DevFS::CreateFileSystem(JSONStream* js, const String& fs_name) {
  SafepointMutexLocker ml(mutex_);
  // TODO(turnidge): Ensure that fs_name is a legal URI host value, i.e. ascii.
  if (LookupFileSystem(fs_name) != NULL) {
    js->PrintError(kFileSystemAlreadyExists,
                   "%s: file system '%s' already exists",
                   js->method(), fs_name.ToCString());
    return;
  }

  std::string key = std::string(fs_name.ToCString());
  FileSystem* file_system = new FileSystem(key);
  (*file_systems_)[key] = file_system;

  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
}


void DevFS::DeleteFileSystem(JSONStream* js, const String& fs_name) {
  SafepointMutexLocker ml(mutex_);
  FileSystem* file_system = LookupFileSystem(fs_name);
  if (file_system == NULL) {
    js->PrintError(kFileSystemDoesNotExist,
                   "%s: file system '%s' does not exist",
                   js->method(), fs_name.ToCString());
    return;
  }
  std::string key = std::string(fs_name.ToCString());
  file_systems_->erase(key);
  delete file_system;
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
}


void DevFS::ListFiles(JSONStream* js, const String& fs_name) {
  SafepointMutexLocker ml(mutex_);
  FileSystem* file_system = LookupFileSystem(fs_name);
  if (file_system == NULL) {
    js->PrintError(kFileSystemDoesNotExist,
                   "%s: file system '%s' does not exist",
                   js->method(), fs_name.ToCString());
    return;
  }

  file_system->ListFiles(js);
}


static void PrintWriteFilesError(JSONStream* js,
                                 intptr_t i) {
  js->PrintError(kInvalidParams,
                 "%s: files array invalid at index '%" Pd "'",
                 js->method(), i);
}


void DevFS::WriteFiles(JSONStream* js,
                       const String& fs_name,
                       const Array& files) {
  SafepointMutexLocker ml(mutex_);
  FileSystem* file_system = LookupFileSystem(fs_name);
  if (file_system == NULL) {
    js->PrintError(kFileSystemDoesNotExist,
                   "%s: file system '%s' does not exist",
                   js->method(), fs_name.ToCString());
    return;
  }

  Object& test = Object::Handle();
  GrowableObjectArray& file_info = GrowableObjectArray::Handle();
  String& path = String::Handle();
  String& file_contents = String::Handle();

  // First, validate the array of files is properly formed.
  for (intptr_t i = 0; i < files.Length(); i++) {
    test = files.At(i);
    if (!test.IsGrowableObjectArray()) {
      PrintWriteFilesError(js, i);
      return;
    }
    file_info ^= test.raw();
    if (file_info.Length() != 2) {
      PrintWriteFilesError(js, i);
      return;
    }
    test = file_info.At(0);
    if (!test.IsString()) {
      PrintWriteFilesError(js, i);
      return;
    }
    std::string key = std::string(String::Cast(test).ToCString());
    if ((key.size() == 0) || (key[0] != '/')) {
      js->PrintError(kInvalidParams,
                     "%s: file system path '%s' must begin with a /",
                     js->method(), String::Cast(test).ToCString());
      return;
    }
    test = file_info.At(1);
    if (!test.IsString()) {
      PrintWriteFilesError(js, i);
      return;
    }
  }

  // Now atomically update the file system.
  for (intptr_t i = 0; i < files.Length(); i++) {
    file_info = GrowableObjectArray::RawCast(files.At(i));
    path = String::RawCast(file_info.At(0));
    file_contents = String::RawCast(file_info.At(1));
    file_system->WriteFile(path.ToCString(),
                           file_contents.ToCString());
  }

  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
}


void DevFS::WriteFile(JSONStream* js,
                      const String& fs_name,
                      const String& path,
                      const String& file_contents) {
  SafepointMutexLocker ml(mutex_);
  FileSystem* file_system = LookupFileSystem(fs_name);
  if (file_system == NULL) {
    js->PrintError(kFileSystemDoesNotExist,
                   "%s: file system '%s' does not exist",
                   js->method(), fs_name.ToCString());
    return;
  }

  std::string key = std::string(path.ToCString());
  if ((key.size() == 0) || (key[0] != '/')) {
    js->PrintError(kInvalidParams,
                   "%s: file system path '%s' must begin with a /",
                   js->method(), path.ToCString());
    return;
  }

  file_system->WriteFile(path.ToCString(),
                         file_contents.ToCString());

  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
}


void DevFS::ReadFile(JSONStream* js,
                     const String& fs_name,
                     const String& path) {
  SafepointMutexLocker ml(mutex_);
  FileSystem* file_system = LookupFileSystem(fs_name);
  if (file_system == NULL) {
    js->PrintError(kFileSystemDoesNotExist,
                   "%s: file system '%s' does not exist",
                   js->method(), fs_name.ToCString());
    return;
  }

  std::string key = std::string(path.ToCString());
  if ((key.size() == 0) || (key[0] != '/')) {
    js->PrintError(kInvalidParams,
                   "%s: file system path '%s' must begin with a /",
                   js->method(), path.ToCString());
    return;
  }
  std::vector<uint8_t>* file_contents;

  bool success = file_system->ReadFile(key, &file_contents);

  if (!success) {
    js->PrintError(kFileDoesNotExist,
                   "%s: file 'dart-devfs://%s/%s' does not exist",
                   js->method(), fs_name.ToCString(), path.ToCString());
    return;
  }

  JSONObject jsobj(js);
  jsobj.AddProperty("type", "FSFile");
  jsobj.AddPropertyBase64("fileContents",
                          &((*file_contents)[0]),
                          file_contents->size());
}

}  // namespace dart
