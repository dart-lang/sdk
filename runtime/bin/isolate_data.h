// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_ISOLATE_DATA_H_
#define BIN_ISOLATE_DATA_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"


namespace dart {
namespace bin {

// Forward declaration.
class EventHandler;

// Data associated with every isolate in the standalone VM
// embedding. This is used to free external resources for each isolate
// when the isolate shuts down.
class IsolateData {
 public:
  explicit IsolateData(const char* url,
                       const char* package_root,
                       const char* packages_file)
      : script_url(strdup(url)),
        package_root(NULL),
        packages_file(NULL),
        udp_receive_buffer(NULL),
        load_async_id(-1) {
    if (package_root != NULL) {
      ASSERT(packages_file == NULL);
      this->package_root = strdup(package_root);
    } else if (packages_file != NULL) {
      this->packages_file = strdup(packages_file);
    }
  }
  ~IsolateData() {
    free(script_url);
    free(package_root);
    free(packages_file);
    free(udp_receive_buffer);
  }

  char* script_url;
  char* package_root;
  char* packages_file;
  uint8_t* udp_receive_buffer;
  int64_t load_async_id;

 private:
  DISALLOW_COPY_AND_ASSIGN(IsolateData);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_ISOLATE_DATA_H_
