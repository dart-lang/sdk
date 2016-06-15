// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DEV_FS_H_
#define VM_DEV_FS_H_

#include "vm/globals.h"

#include "vm/dart_api_impl.h"

namespace dart {

class Array;
class FileSystem;
class JSONStream;
class Mutex;
class ObjectPointerVisitor;
class RawArray;
class RawObject;
class String;


// Manages dart-devfs:// file systems. These file systems are "virtual"
// and accessed via the service protocol.
class DevFS {
 public:
  static void Init();
  static void Cleanup();

  static void ListFileSystems(JSONStream* js);
  static void CreateFileSystem(JSONStream* js, const String& fs_name);
  static void DeleteFileSystem(JSONStream* js, const String& fs_name);
  static void ListFiles(JSONStream* js,
                        const String& fs_name);
  static void WriteFiles(JSONStream* js,
                         const String& fs_name,
                         const Array& files);
  static void WriteFile(JSONStream* js,
                        const String& fs_name,
                        const String& path,
                        const String& file_contents);
  static void ReadFile(JSONStream* js,
                       const String& fs_name,
                       const String& path);

 private:
  static Mutex* mutex_;
  static FileSystem* LookupFileSystem(const String& fs_name);
  static FileSystem* LookupFileSystem(const char* fs_name);
};

}  // namespace dart

#endif  // VM_DEV_FS_H_
