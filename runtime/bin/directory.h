// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DIRECTORY_H_
#define BIN_DIRECTORY_H_

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "platform/globals.h"


namespace dart {
namespace bin {

enum ListType {
  kListFile = 0,
  kListDirectory = 1,
  kListLink = 2,
  kListError = 3,
  kListDone = 4
};

class PathBuffer {
 public:
  PathBuffer();
  ~PathBuffer() {
    free(data_);
  }

  bool Add(const char* name);
  bool AddW(const wchar_t* name);

  char* AsString() const;
  wchar_t* AsStringW() const;

  void Reset(int new_length);

  int length() const {
    return length_;
  }

 private:
  void* data_;
  int length_;

  DISALLOW_COPY_AND_ASSIGN(PathBuffer);
};

class DirectoryListing;

struct LinkList;

// DirectoryListingEntry is used as a stack item, when performing recursive
// directory listing. By using DirectoryListingEntry as stack elements, a
// directory listing can be paused e.g. when a buffer is full, and resumed
// later on.
//
// The stack is managed by the DirectoryListing's PathBuffer. Each
// DirectoryListingEntry stored a entry-length, that it'll reset the PathBuffer
// to on each call to Next.
class DirectoryListingEntry {
 public:
  explicit DirectoryListingEntry(DirectoryListingEntry* parent)
    : parent_(parent), lister_(0), done_(false), link_(NULL) {}

  ~DirectoryListingEntry();

  ListType Next(DirectoryListing* listing);

  DirectoryListingEntry* parent() const {
    return parent_;
  }

  LinkList* link() {
    return link_;
  }

  void set_link(LinkList* link) {
    link_ = link;
  }

  void ResetLink();

 private:
  DirectoryListingEntry* parent_;
  intptr_t lister_;
  bool done_;
  int path_length_;
  LinkList* link_;

  DISALLOW_COPY_AND_ASSIGN(DirectoryListingEntry);
};

class DirectoryListing {
 public:
  DirectoryListing(const char* dir_name, bool recursive, bool follow_links)
    : top_(NULL),
      error_(false),
      recursive_(recursive),
      follow_links_(follow_links) {
    if (!path_buffer_.Add(dir_name)) {
      error_ = true;
    }
    Push(new DirectoryListingEntry(NULL));
  }

  virtual ~DirectoryListing() {
    while (!IsEmpty()) {
      Pop();
    }
  }

  virtual bool HandleDirectory(char* dir_name) = 0;
  virtual bool HandleFile(char* file_name) = 0;
  virtual bool HandleLink(char* link_name) = 0;
  virtual bool HandleError(const char* dir_name) = 0;
  virtual void HandleDone() {}

  void Push(DirectoryListingEntry* directory) {
    top_ = directory;
  }

  void Pop() {
    ASSERT(!IsEmpty());
    DirectoryListingEntry* current = top_;
    top_ = top_->parent();
    delete current;
  }

  bool IsEmpty() const {
    return top_ == NULL;
  }

  DirectoryListingEntry* top() const {
    return top_;
  }

  bool recursive() const {
    return recursive_;
  }

  bool follow_links() const {
    return follow_links_;
  }

  char* CurrentPath() {
    return path_buffer_.AsString();
  }

  PathBuffer& path_buffer() {
    return path_buffer_;
  }

  bool error() const {
    return error_;
  }

 private:
  PathBuffer path_buffer_;
  DirectoryListingEntry* top_;
  bool error_;
  bool recursive_;
  bool follow_links_;
};


class AsyncDirectoryListing : public DirectoryListing {
 public:
  enum Response {
    kListFile = 0,
    kListDirectory = 1,
    kListLink = 2,
    kListError = 3,
    kListDone = 4
  };

  AsyncDirectoryListing(const char* dir_name,
                        bool recursive,
                        bool follow_links)
      : DirectoryListing(dir_name, recursive, follow_links) {}

  virtual ~AsyncDirectoryListing() {}
  virtual bool HandleDirectory(char* dir_name);
  virtual bool HandleFile(char* file_name);
  virtual bool HandleLink(char* file_name);
  virtual bool HandleError(const char* dir_name);
  virtual void HandleDone();

  void SetArray(CObjectArray* array, intptr_t length) {
    ASSERT(length % 2 == 0);
    array_ = array;
    index_ = 0;
    length_ = length;
  }

  intptr_t index() const {
    return index_;
  }

 private:
  bool AddFileSystemEntityToResponse(Response response, char* arg);
  CObjectArray* array_;
  intptr_t index_;
  intptr_t length_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(AsyncDirectoryListing);
};


class SyncDirectoryListing: public DirectoryListing {
 public:
  SyncDirectoryListing(Dart_Handle results,
                       const char* dir_name,
                       bool recursive,
                       bool follow_links)
      : DirectoryListing(dir_name, recursive, follow_links),
        results_(results) {
    add_string_ = DartUtils::NewString("add");
    directory_type_ =
        DartUtils::GetDartType(DartUtils::kIOLibURL, "Directory");
    file_type_ =
        DartUtils::GetDartType(DartUtils::kIOLibURL, "File");
    link_type_ =
        DartUtils::GetDartType(DartUtils::kIOLibURL, "Link");
  }
  virtual ~SyncDirectoryListing() {}
  virtual bool HandleDirectory(char* dir_name);
  virtual bool HandleFile(char* file_name);
  virtual bool HandleLink(char* file_name);
  virtual bool HandleError(const char* dir_name);

 private:
  Dart_Handle results_;
  Dart_Handle add_string_;
  Dart_Handle directory_type_;
  Dart_Handle file_type_;
  Dart_Handle link_type_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(SyncDirectoryListing);
};


class Directory {
 public:
  enum ExistsResult {
    UNKNOWN,
    EXISTS,
    DOES_NOT_EXIST
  };

  static void List(DirectoryListing* listing);
  static ExistsResult Exists(const char* path);
  static char* Current();
  static bool SetCurrent(const char* path);
  static bool Create(const char* path);
  static char* SystemTemp();
  static char* CreateTemp(const char* path);
  static bool Delete(const char* path, bool recursive);
  static bool Rename(const char* path, const char* new_path);

  static CObject* CreateRequest(const CObjectArray& request);
  static CObject* DeleteRequest(const CObjectArray& request);
  static CObject* ExistsRequest(const CObjectArray& request);
  static CObject* CreateTempRequest(const CObjectArray& request);
  static CObject* CreateSystemTempRequest(const CObjectArray& request);
  static CObject* ListStartRequest(const CObjectArray& request);
  static CObject* ListNextRequest(const CObjectArray& request);
  static CObject* ListStopRequest(const CObjectArray& request);
  static CObject* RenameRequest(const CObjectArray& request);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Directory);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_DIRECTORY_H_
