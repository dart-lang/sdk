// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/vmstats_impl.h"

#include "bin/file.h"
#include "bin/log.h"
#include "bin/platform.h"
#include "bin/resources.h"
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
dart::Monitor* VmStats::instance_monitor_;
dart::Mutex* VmStatusService::mutex_;


void VmStats::Start(int port, const char* root_dir, bool verbose) {
  if (instance_ != NULL) {
    FATAL("VmStats already started.");
  }
  instance_ = new VmStats(verbose);
  instance_monitor_ = new dart::Monitor();
  Initialize();
  VmStatusService::InitOnce();

  if (port >= 0) {
    StartServer(port, root_dir);
  }
}


void VmStats::StartServer(int port, const char* root_dir) {
  ASSERT(port >= 0);
  ASSERT(instance_ != NULL);
  ASSERT(instance_monitor_ != NULL);
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

  MonitorLocker ml(instance_monitor_);
  instance_->running_ = true;
  int err = dart::Thread::Start(WebServer, address);
  if (err != 0) {
    Log::PrintErr("Failed starting VmStats thread: %d\n", err);
    Shutdown();
  }
}

void VmStats::Stop() {
  ASSERT(instance_ != NULL);
  MonitorLocker ml(instance_monitor_);
  instance_->running_ = false;
}


void VmStats::Shutdown() {
  ASSERT(instance_ != NULL);
  MonitorLocker ml(instance_monitor_);
  Socket::Close(instance_->bind_address_);
  delete instance_;
  instance_ = NULL;
}


void VmStats::AddIsolate(IsolateData* isolate_data,
                         Dart_Isolate isolate) {
  MonitorLocker ml(instance_monitor_);
  instance_->isolate_table_[isolate_data] = isolate;
}


void VmStats::RemoveIsolate(IsolateData* isolate_data) {
  MonitorLocker ml(instance_monitor_);
  instance_->isolate_table_.erase(isolate_data);
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


// Return a malloc'd string from a format string and arguments.
intptr_t alloc_printf(char** result, const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = vsnprintf(NULL, 0, format, args) + 1;
  *result = reinterpret_cast<char*>(malloc(len));
  return vsnprintf(*result, len, format, args);
}


void writeResponse(intptr_t socket, const char* content_type,
                   const char* data, size_t length) {
  char* header;
  intptr_t len = alloc_printf(&header,
      "HTTP/1.1 200 OK\nContent-Type: %s\nContent-Length: %"Pu"\n\n",
      content_type, length);
  Socket::Write(socket, header, len);
  Socket::Write(socket, data, length);
  Socket::Write(socket, "\n", 1);
  free(header);
}


void writeErrorResponse(intptr_t socket, intptr_t error_num, const char* error,
                        const char* description) {
  if (description != NULL) {
    // Create body first, so its length is known when creating the header.
    char* body;
    intptr_t body_len = alloc_printf(&body,
        "<html><head><title>%d %s</title></head>\n"
        "<body>\n<h1>%s</h1>\n%s\n</body></html>\n",
        error_num, error, error, description);
    char* header;
    intptr_t header_len = alloc_printf(&header,
        "HTTP/1.1 %d %s\n"
        "Content-Length: %d\n"
        "Connection: close\n"
        "Content-Type: text/html\n\n",
        error_num, error, body_len);
    Socket::Write(socket, header, header_len);
    Socket::Write(socket, body, body_len);
    free(header);
    free(body);
  } else {
    char* response;
    intptr_t len =
        alloc_printf(&response, "HTTP/1.1 %d %s\n\n", error_num, error);
    Socket::Write(socket, response, len);
    free(response);
  }
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
    Socket::SetBlocking(socket);

    // TODO(tball): rewrite this to use STL, so as to eliminate the static
    // buffer and support resource URLs that are longer than BUFSIZE.

    // Read request.
    char buffer[BUFSIZE + 1];
    intptr_t len = Socket::Read(socket, buffer, BUFSIZE);
    if (len <= 0) {
      // Invalid HTTP request, ignore.
      continue;
    }
    buffer[len] = '\0';

    // Verify it's a GET request.
    // TODO(tball): support POST requests.
    if (strncmp("GET ", buffer, 4) != 0 && strncmp("get ", buffer, 4) != 0) {
      Log::PrintErr("Unsupported HTTP request type");
      writeErrorResponse(socket, 403, "Forbidden",
                         "Unsupported HTTP request type");
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
    char* url = strdup(&buffer[4]);

    if (instance_->verbose_) {
      Log::Print("vmstats: %s requested\n", url);
    }
    char* content = NULL;

    // Check for VmStats-specific URLs.
    if (strcmp(url, "/isolates") == 0) {
      content = instance_->IsolatesStatus();
    } else {
      // Check plug-ins.
      content = VmStatusService::GetVmStatus(url);
    }

    if (content != NULL) {
      writeResponse(socket, "application/json", content, strlen(content));
      free(content);
    } else {
      // No status content with this URL, return file or resource content.
      dart::TextBuffer path(strlen(instance_->root_directory_) + strlen(url));
      path.AddString(instance_->root_directory_);
      path.AddString(url);

      // Expand directory URLs.
      if (strcmp(url, "/") == 0) {
        path.AddString(VMSTATS_HTML);
      } else if (url[strlen(url) - 1] == '/') {
        path.AddString(INDEX_HTML);
      }

      bool success = false;
      char* text_buffer = NULL;
      const char* content_type = ContentType(path.buf());
      if (File::Exists(path.buf())) {
        File* f = File::Open(path.buf(), File::kRead);
        if (f != NULL) {
          intptr_t len = f->Length();
          text_buffer = reinterpret_cast<char*>(malloc(len));
          if (f->ReadFully(text_buffer, len)) {
            writeResponse(socket, content_type, text_buffer, len);
            success = true;
          }
          free(text_buffer);
          delete f;
        }
      } else {
        const char* resource;
        intptr_t len = Resources::ResourceLookup(path.buf(), &resource);
        if (len != Resources::kNoSuchInstance) {
          ASSERT(len >= 0);
          writeResponse(socket, content_type, resource, len);
          success = true;
        }
      }
      if (!success) {
        char* description;
        alloc_printf(
            &description, "URL <a href=\"%s\">%s</a> not found.", url, url);
        writeErrorResponse(socket, 404, "Not Found", description);
        free(description);
      }
    }
    Socket::Close(socket);
    free(url);
  }

  Shutdown();
}


char* VmStats::IsolatesStatus() {
  dart::TextBuffer text(64);
  text.Printf("{\n\"isolates\": [\n");
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
      if (!first) {
        text.AddString(",\n");
      }
      text.AddString(status);
      first = false;
      free(status);
    }
  }
  text.AddString("\n]\n}\n");
  return strdup(text.buf());
}


// Advance the scanner to the value token of a specified name-value pair.
void SeekNamedValue(const char* name, dart::JSONScanner* scanner) {
  while (!scanner->EOM()) {
    scanner->Scan();
    if (scanner->IsStringLiteral(name)) {
      scanner->Scan();
      ASSERT(scanner->CurrentToken() == dart::JSONScanner::TokenColon);
      scanner->Scan();
     return;
    }
  }
}


// Windows doesn't have strndup(), so this is a simple, private version.
static char* StrNDup(const char* s, uword len) {
  if (strlen(s) < len) {
    len = strlen(s);
  }
  char* result = reinterpret_cast<char*>(malloc(len + 1));
  memmove(result, s, len);
  result[len + 1] = '\0';
  return result;
}


void VmStats::DumpStackThread(uword unused) {
  Log::Print("Isolate dump:\n");
  IsolateTable::iterator itr;
  MonitorLocker ml(instance_monitor_);
  for (itr = instance_->isolate_table_.begin();
       itr != instance_->isolate_table_.end(); ++itr) {
    Dart_Isolate isolate = itr->second;

    // Print isolate name and details.
    static char buffer[512];
    snprintf(buffer, sizeof(buffer),
             "/isolate/0x%"Px, reinterpret_cast<intptr_t>(isolate));
    char* isolate_details = VmStatusService::GetVmStatus(buffer);
    if (isolate_details != NULL) {
      dart::JSONScanner scanner(isolate_details);
      SeekNamedValue("name", &scanner);
      char* name = StrNDup(scanner.TokenChars(), scanner.TokenLen());
      SeekNamedValue("port", &scanner);
      char* port = StrNDup(scanner.TokenChars(), scanner.TokenLen());
      Log::Print("\"%s\" port=%s\n", name, port);
      free(isolate_details);
      free(port);
      free(name);
    }

    // Print stack trace.
    snprintf(buffer, sizeof(buffer),
             "/isolate/0x%"Px"/stacktrace",
             reinterpret_cast<intptr_t>(isolate));
    char* trace = VmStatusService::GetVmStatus(buffer);
    if (trace != NULL) {
      dart::JSONScanner scanner(trace);
      while (true) {
        SeekNamedValue("url", &scanner);
        if (scanner.CurrentToken() == dart::JSONScanner::TokenEOM) {
          break;
        }
        char* url = StrNDup(scanner.TokenChars(), scanner.TokenLen());
        SeekNamedValue("line", &scanner);
        char* line = StrNDup(scanner.TokenChars(), scanner.TokenLen());
        SeekNamedValue("function", &scanner);
        char* function = StrNDup(scanner.TokenChars(), scanner.TokenLen());
        Log::Print("  at %s(%s:%s)\n", function, url, line);
        free(url);
        free(line);
        free(function);
      }
      free(trace);
    }
  }
}


void VmStats::DumpStack() {
  int err = dart::Thread::Start(DumpStackThread, 0);
  if (err != 0) {
    Log::PrintErr("Failed starting VmStats stackdump thread: %d\n", err);
    Shutdown();
  }
}


// Global static pointer used to ensure a single instance of the class.
VmStatusService* VmStatusService::instance_ = NULL;


void VmStatusService::InitOnce() {
  ASSERT(VmStatusService::instance_ == NULL);
  VmStatusService::instance_ = new VmStatusService();
  VmStatusService::mutex_ = new dart::Mutex();

  // Register built-in status plug-ins. RegisterPlugin is not used because
  // this isn't called within an isolate, and because parameter checking
  // isn't necessary.
  instance_->RegisterPlugin(&Dart_GetVmStatus);

  // TODO(tball): dynamically load any additional plug-ins.
}


int VmStatusService::RegisterPlugin(Dart_VmStatusCallback callback) {
  ASSERT(VmStatusService::instance_ != NULL);
  ASSERT(VmStatusService::mutex_ != NULL);
  MutexLocker ml(mutex_);
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
  ASSERT(VmStatusService::instance_ != NULL);
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
