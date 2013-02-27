// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/vmstats_impl.h"

#include <sstream>

#include "bin/file.h"
#include "bin/log.h"
#include "bin/platform.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "include/dart_debugger_api.h"
#include "platform/json.h"

#define BUFSIZE 8192
#define RETRY_PAUSE 100  // milliseconds

static const char* INDEX_HTML = "index.html";
static const char* VMSTATS_HTML = "vmstats.html";
static const char* DEFAULT_HOST = "localhost";

// Global static pointer used to ensure a single instance of the class.
VmStats* VmStats::instance_ = NULL;
dart::Monitor VmStats::instance_monitor_;
dart::Mutex VmStatusService::mutex_;


void VmStats::Start(int port, const char* root_dir) {
  if (instance_ != NULL) {
    FATAL("VmStats already started.");
  }
  MonitorLocker ml(&instance_monitor_);
  instance_ = new VmStats();
  VmStatusService::InitOnce();
  Socket::Initialize();

  if (root_dir != NULL) {
    instance_->root_directory_ = root_dir;
  }

  // TODO(tball): allow host to be specified.
  char* host = const_cast<char*>(DEFAULT_HOST);
  OSError* os_error;
  const char* host_ip = Socket::LookupIPv4Address(host, &os_error);
  if (host_ip == NULL) {
    Log::PrintErr("Failed IP lookup of VmStats host %s: %s\n",
                  host, os_error->message());
    return;
  }

  const intptr_t BACKLOG = 128;  // Default value from HttpServer.dart
  int64_t address = ServerSocket::CreateBindListen(host_ip, port, BACKLOG);
  if (address < 0) {
    Log::PrintErr("Failed binding VmStats socket: %s:%d\n", host, port);
    return;
  }
  instance_->bind_address_ = address;
  Log::Print("VmStats URL: http://%s:%"Pd"/\n", host, Socket::GetPort(address));

  instance_->running_ = true;
  int err = dart::Thread::Start(WebServer, address);
  if (err != 0) {
    Log::PrintErr("Failed starting VmStats thread: %d\n", err);
    Shutdown();
  }
}


void VmStats::Stop() {
  MonitorLocker ml(&instance_monitor_);
  if (instance_ != NULL) {
    instance_->running_ = false;
  }
}


void VmStats::Shutdown() {
  MonitorLocker ml(&instance_monitor_);
  Socket::Close(instance_->bind_address_);
  delete instance_;
  instance_ = NULL;
}


void VmStats::AddIsolate(IsolateData* isolate_data,
                         Dart_Isolate isolate) {
  MonitorLocker ml(&instance_monitor_);
  if (instance_ != NULL) {
    instance_->isolate_table_[isolate_data] = isolate;
  }
}


void VmStats::RemoveIsolate(IsolateData* isolate_data) {
  MonitorLocker ml(&instance_monitor_);
  if (instance_ != NULL) {
    instance_->isolate_table_.erase(isolate_data);
  }
}


static const char* ContentType(const char* url) {
  const char* suffix = strrchr(url, '.');
  if (suffix != NULL) {
    if (!strcmp(suffix, ".html")) {
      return "text/html; charset=UTF-8";
    }
    if (!strcmp(suffix, ".dart")) {
      return "application/dart; charset=UTF-8";
    }
    if (!strcmp(suffix, ".js")) {
      return "application/javascript; charset=UTF-8";
    }
    if (!strcmp(suffix, ".css")) {
      return "text/css; charset=UTF-8";
    }
    if (!strcmp(suffix, ".gif")) {
      return "image/gif";
    }
    if (!strcmp(suffix, ".png")) {
      return "image/png";
    }
    if (!strcmp(suffix, ".jpg") || !strcmp(suffix, ".jpeg")) {
      return "image/jpeg";
    }
  }
  return "text/plain";
}


void VmStats::WebServer(uword bind_address) {
  while (true) {
    intptr_t socket = ServerSocket::Accept(bind_address);
    if (socket == ServerSocket::kTemporaryFailure) {
      // Not a real failure, woke up but no connection available.

      // Use MonitorLocker.Wait(), since it has finer granularity than sleep().
      dart::Monitor m;
      MonitorLocker ml(&m);
      ml.Wait(RETRY_PAUSE);

      continue;
    }
    if (socket < 0) {
      // Stop() closed the socket.
      return;
    }

    // TODO(tball): rewrite this to use STL, so as to eliminate the static
    // buffer and support resource URLs that are longer than BUFSIZE.

    // Read request.
    char buffer[BUFSIZE + 1];
    intptr_t len = Socket::Read(socket, buffer, BUFSIZE);
    if (len <= 0) {
      // Invalid HTTP request, ignore.
      continue;
    }
    intptr_t n;
    while ((n = Socket::Read(socket, buffer + len, BUFSIZE - len)) > 0) {
      len += n;
    }
    buffer[len] = '\0';

    // Verify it's a GET request.
    // TODO(tball): support POST requests.
    if (strncmp("GET ", buffer, 4) != 0 && strncmp("get ", buffer, 4) != 0) {
      Log::PrintErr("Unsupported HTTP request type");
      const char* response = "HTTP/1.1 403 Forbidden\n"
          "Content-Length: 120\n"
          "Connection: close\n"
          "Content-Type: text/html\n\n"
          "<html><head>\n<title>403 Forbidden</title>\n</head>"
          "<body>\n<h1>Forbidden</h1>\nUnsupported HTTP request type\n</body>"
          "</html>\n";
      Socket::Write(socket, response, strlen(response));
      Socket::Close(socket);
      continue;
    }

    // Extract GET URL, and null-terminate URL in case request line has
    // HTTP version.
    for (int i = 4; i < len; i++) {
      if (buffer[i] == ' ') {
        buffer[i] = '\0';
      }
    }
    char* url = &buffer[4];

    Log::Print("vmstats: %s requested\n", url);
    char* content = NULL;

    // Check for VmStats-specific URLs.
    if (strcmp(url, "/isolates") == 0) {
      content = instance_->IsolatesStatus();
    } else {
      // Check plug-ins.
      content = VmStatusService::GetVmStatus(url);
    }

    if (content != NULL) {
      size_t content_len = strlen(content);
      len = snprintf(buffer, BUFSIZE,
          "HTTP/1.1 200 OK\nContent-Type: application/json; charset=UTF-8\n"
          "Content-Length: %"Pu"\n\n",
          content_len);
      Socket::Write(socket, buffer, strlen(buffer));
      Socket::Write(socket, content, content_len);
      Socket::Write(socket, "\n", 1);
      Socket::Write(socket, buffer, strlen(buffer));
      free(content);
    } else {
      // No status content with this URL, return file or resource content.
      std::string path(instance_->root_directory_);
      path.append(url);

      // Expand directory URLs.
      if (strcmp(url, "/") == 0) {
        path.append(VMSTATS_HTML);
      } else if (url[strlen(url) - 1] == '/') {
        path.append(INDEX_HTML);
      }

      bool success = false;
      if (File::Exists(path.c_str())) {
        File* f = File::Open(path.c_str(), File::kRead);
        if (f != NULL) {
          intptr_t len = f->Length();
          char* text_buffer = reinterpret_cast<char*>(malloc(len));
          if (f->ReadFully(text_buffer, len)) {
            const char* content_type = ContentType(path.c_str());
            snprintf(buffer, BUFSIZE,
                "HTTP/1.1 200 OK\nContent-Type: %s\n"
                "Content-Length: %"Pu"\n\n",
                content_type, len);
            Socket::Write(socket, buffer, strlen(buffer));
            Socket::Write(socket, text_buffer, len);
            Socket::Write(socket, "\n", 1);
            success = true;
          }
          free(text_buffer);
          delete f;
        }
      } else {
        // TODO(tball): look up linked in resource.
      }
      if (!success) {
        const char* response = "HTTP/1.1 404 Not Found\n\n";
        Socket::Write(socket, response, strlen(response));
      }
    }
    Socket::Close(socket);
  }

  Shutdown();
}


char* VmStats::IsolatesStatus() {
  std::ostringstream stream;
  stream << '{' << std::endl;
  stream << "\"isolates\": [" << std::endl;
  IsolateTable::iterator itr;
  bool first = true;
  for (itr = isolate_table_.begin(); itr != isolate_table_.end(); ++itr) {
    Dart_Isolate isolate = itr->second;
    static char request[512];
    snprintf(request, sizeof(request),
             "/isolate/0x%"Px,
             reinterpret_cast<intptr_t>(isolate));
    char* status = VmStatusService::GetVmStatus(request);
    if (status != NULL) {
      stream << status;
      if (!first) {
        stream << "," << std::endl;
      }
      first = false;
    }
    free(status);
  }
  stream << std::endl << "]";
  stream << std::endl << '}' << std::endl;
  return strdup(stream.str().c_str());
}


// Global static pointer used to ensure a single instance of the class.
VmStatusService* VmStatusService::instance_ = NULL;


void VmStatusService::InitOnce() {
  ASSERT(VmStatusService::instance_ == NULL);
  VmStatusService::instance_ = new VmStatusService();

  // Register built-in status plug-ins. RegisterPlugin is not used because
  // this isn't called within an isolate, and because parameter checking
  // isn't necessary.
  instance_->RegisterPlugin(&Dart_GetVmStatus);

  // TODO(tball): dynamically load any additional plug-ins.
}


int VmStatusService::RegisterPlugin(Dart_VmStatusCallback callback) {
  MutexLocker ml(&mutex_);
  if (callback == NULL) {
    return -1;
  }
  VmStatusPlugin* plugin = new VmStatusPlugin(callback);
  VmStatusPlugin* list = instance_->registered_plugin_list_;
  if (list == NULL) {
    instance_->registered_plugin_list_ = plugin;
  } else {
    list->Append(plugin);
  }
  return 0;
}


char* VmStatusService::GetVmStatus(const char* request) {
  VmStatusPlugin* plugin = instance_->registered_plugin_list_;
  while (plugin != NULL) {
    char* result = (plugin->callback())(request);
    if (result != NULL) {
      return result;
    }
    plugin = plugin->next();
  }
  return NULL;
}
