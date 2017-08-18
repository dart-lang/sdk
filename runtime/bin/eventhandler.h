// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_EVENTHANDLER_H_
#define RUNTIME_BIN_EVENTHANDLER_H_

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/isolate_data.h"

#include "platform/hashmap.h"

namespace dart {
namespace bin {

// Flags used to provide information and actions to the eventhandler
// when sending a message about a file descriptor. These flags should
// be kept in sync with the constants in socket_impl.dart. For more
// information see the comments in socket_impl.dart
enum MessageFlags {
  kInEvent = 0,
  kOutEvent = 1,
  kErrorEvent = 2,
  kCloseEvent = 3,
  kDestroyedEvent = 4,
  kCloseCommand = 8,
  kShutdownReadCommand = 9,
  kShutdownWriteCommand = 10,
  kReturnTokenCommand = 11,
  kSetEventMaskCommand = 12,
  kListeningSocket = 16,
  kPipe = 17,
};

// clang-format off
#define COMMAND_MASK ((1 << kCloseCommand) |                                   \
                      (1 << kShutdownReadCommand) |                            \
                      (1 << kShutdownWriteCommand) |                           \
                      (1 << kReturnTokenCommand) |                             \
                      (1 << kSetEventMaskCommand))
#define EVENT_MASK ((1 << kInEvent) |                                          \
                    (1 << kOutEvent) |                                         \
                    (1 << kErrorEvent) |                                       \
                    (1 << kCloseEvent) |                                       \
                    (1 << kDestroyedEvent))
#define IS_COMMAND(data, command_bit)                                          \
    ((data & COMMAND_MASK) == (1 << command_bit))  // NOLINT
#define IS_EVENT(data, event_bit)                                              \
    ((data & EVENT_MASK) == (1 << event_bit))  // NOLINT
#define IS_IO_EVENT(data)                                                      \
    ((data & (1 << kInEvent | 1 << kOutEvent | 1 << kCloseEvent)) != 0 &&      \
     (data & ~(1 << kInEvent | 1 << kOutEvent | 1 << kCloseEvent)) == 0)
#define IS_LISTENING_SOCKET(data)                                              \
    ((data & (1 << kListeningSocket)) != 0)  // NOLINT
#define TOKEN_COUNT(data) (data & ((1 << kCloseCommand) - 1))
// clang-format on

class TimeoutQueue {
 private:
  class Timeout {
   public:
    Timeout(Dart_Port port, int64_t timeout, Timeout* next)
        : port_(port), timeout_(timeout), next_(next) {}

    Dart_Port port() const { return port_; }

    int64_t timeout() const { return timeout_; }
    void set_timeout(int64_t timeout) {
      ASSERT(timeout >= 0);
      timeout_ = timeout;
    }

    Timeout* next() const { return next_; }
    void set_next(Timeout* next) { next_ = next; }

   private:
    Dart_Port port_;
    int64_t timeout_;
    Timeout* next_;
  };

 public:
  TimeoutQueue() : next_timeout_(NULL), timeouts_(NULL) {}

  ~TimeoutQueue() {
    while (HasTimeout())
      RemoveCurrent();
  }

  bool HasTimeout() const { return next_timeout_ != NULL; }

  int64_t CurrentTimeout() const {
    ASSERT(next_timeout_ != NULL);
    return next_timeout_->timeout();
  }

  Dart_Port CurrentPort() const {
    ASSERT(next_timeout_ != NULL);
    return next_timeout_->port();
  }

  void RemoveCurrent() { UpdateTimeout(CurrentPort(), -1); }

  void UpdateTimeout(Dart_Port port, int64_t timeout);

 private:
  Timeout* next_timeout_;
  Timeout* timeouts_;

  DISALLOW_COPY_AND_ASSIGN(TimeoutQueue);
};

class InterruptMessage {
 public:
  intptr_t id;
  Dart_Port dart_port;
  int64_t data;
};

static const int kInterruptMessageSize = sizeof(InterruptMessage);
static const int kInfinityTimeout = -1;
static const int kTimerId = -1;
static const int kShutdownId = -2;

template <typename T>
class CircularLinkedList {
 public:
  CircularLinkedList() : head_(NULL) {}

  typedef void (*ClearFun)(void* value);

  // Returns true if the list was empty.
  bool Add(T t) {
    Entry* e = new Entry(t);
    if (head_ == NULL) {
      // Empty list, make e head, and point to itself.
      e->next_ = e;
      e->prev_ = e;
      head_ = e;
      return true;
    } else {
      // Insert e as the last element in the list.
      e->prev_ = head_->prev_;
      e->next_ = head_;
      e->prev_->next_ = e;
      head_->prev_ = e;
      return false;
    }
  }

  void RemoveHead(ClearFun clear = NULL) {
    ASSERT(head_ != NULL);

    Entry* e = head_;
    if (e->next_ == e) {
      head_ = NULL;
    } else {
      e->prev_->next_ = e->next_;
      e->next_->prev_ = e->prev_;
      head_ = e->next_;
    }
    if (clear != NULL) {
      clear(reinterpret_cast<void*>(e->t));
    }
    delete e;
  }

  void Remove(T item) {
    if (head_ == NULL) {
      return;
    } else if (head_ == head_->next_) {
      if (head_->t == item) {
        delete head_;
        head_ = NULL;
        return;
      }
    } else {
      Entry* current = head_;
      do {
        if (current->t == item) {
          Entry* next = current->next_;
          Entry* prev = current->prev_;
          prev->next_ = next;
          next->prev_ = prev;

          if (current == head_) {
            head_ = head_->next_;
          }

          delete current;
          return;
        }
        current = current->next_;
      } while (current != head_);
    }
  }

  void RemoveAll(ClearFun clear = NULL) {
    while (HasHead()) {
      RemoveHead(clear);
    }
  }

  T head() const { return head_->t; }

  bool HasHead() const { return head_ != NULL; }

  void Rotate() {
    if (head_ != NULL) {
      ASSERT(head_->next_ != NULL);
      head_ = head_->next_;
    }
  }

 private:
  struct Entry {
    explicit Entry(const T& t) : t(t), next_(NULL), prev_(NULL) {}
    const T t;
    Entry* next_;
    Entry* prev_;
  };

  Entry* head_;

  DISALLOW_COPY_AND_ASSIGN(CircularLinkedList);
};

class DescriptorInfoBase {
 public:
  explicit DescriptorInfoBase(intptr_t fd) : fd_(fd) { ASSERT(fd_ != -1); }

  virtual ~DescriptorInfoBase() {}

  // The OS descriptor.
  intptr_t fd() { return fd_; }

  // Whether this descriptor refers to an underlying listening OS socket.
  virtual bool IsListeningSocket() const = 0;

  // Inserts or updates a new Dart_Port which is interested in events specified
  // in `mask`.
  virtual void SetPortAndMask(Dart_Port port, intptr_t mask) = 0;

  // Removes a port from the interested listeners.
  virtual void RemovePort(Dart_Port port) = 0;

  // Removes all ports from the interested listeners.
  virtual void RemoveAllPorts() = 0;

  // Returns a port to which `events_ready` can be sent to. It will also
  // decrease the token count by 1 for this port.
  virtual Dart_Port NextNotifyDartPort(intptr_t events_ready) = 0;

  // Will post `data` to all known Dart_Ports. It will also decrease the token
  // count by 1 for all ports.
  virtual void NotifyAllDartPorts(uintptr_t events) = 0;

  // Returns `count` tokens for the given port.
  virtual void ReturnTokens(Dart_Port port, int count) = 0;

  // Returns the union of event masks of all ports. If a port has a non-positive
  // token count it's mask is assumed to be 0.
  virtual intptr_t Mask() = 0;

  // Closes this descriptor.
  virtual void Close() = 0;

 protected:
  intptr_t fd_;

 private:
  DISALLOW_COPY_AND_ASSIGN(DescriptorInfoBase);
};

// Describes a OS descriptor (e.g. file descriptor on linux or HANDLE on
// windows) which is connected to a single Dart_Port.
//
// Subclasses of this class can be e.g. connected tcp sockets.
template <typename DI>
class DescriptorInfoSingleMixin : public DI {
 private:
  static const int kTokenCount = 16;

 public:
  DescriptorInfoSingleMixin(intptr_t fd, bool disable_tokens)
      : DI(fd),
        port_(0),
        tokens_(kTokenCount),
        mask_(0),
        disable_tokens_(disable_tokens) {}

  virtual ~DescriptorInfoSingleMixin() {}

  virtual bool IsListeningSocket() const { return false; }

  virtual void SetPortAndMask(Dart_Port port, intptr_t mask) {
    ASSERT(port_ == 0 || port == port_);
    port_ = port;
    mask_ = mask;
  }

  virtual void RemovePort(Dart_Port port) {
    // TODO(dart:io): Find out where we call RemovePort() with the invalid
    // port. Afterwards remove the part in the ASSERT here.
    ASSERT(port_ == 0 || port_ == port);
    port_ = 0;
    mask_ = 0;
  }

  virtual void RemoveAllPorts() {
    port_ = 0;
    mask_ = 0;
  }

  virtual Dart_Port NextNotifyDartPort(intptr_t events_ready) {
    ASSERT(IS_IO_EVENT(events_ready) ||
           IS_EVENT(events_ready, kDestroyedEvent));
    if (!disable_tokens_) {
      tokens_--;
    }
    return port_;
  }

  virtual void NotifyAllDartPorts(uintptr_t events) {
    // Unexpected close, asynchronous destroy or error events are the only
    // ones we broadcast to all listeners.
    ASSERT(IS_EVENT(events, kCloseEvent) || IS_EVENT(events, kErrorEvent) ||
           IS_EVENT(events, kDestroyedEvent));

    if (port_ != 0) {
      DartUtils::PostInt32(port_, events);
    }
    if (!disable_tokens_) {
      tokens_--;
    }
  }

  virtual void ReturnTokens(Dart_Port port, int count) {
    ASSERT(port_ == port);
    if (!disable_tokens_) {
      tokens_ += count;
    }
    ASSERT(tokens_ <= kTokenCount);
  }

  virtual intptr_t Mask() {
    if (tokens_ <= 0) {
      return 0;
    }
    return mask_;
  }

  virtual void Close() { DI::Close(); }

 private:
  Dart_Port port_;
  int tokens_;
  intptr_t mask_;
  bool disable_tokens_;

  DISALLOW_COPY_AND_ASSIGN(DescriptorInfoSingleMixin);
};

// Describes a OS descriptor (e.g. file descriptor on linux or HANDLE on
// windows) which is connected to multiple Dart_Port's.
//
// Subclasses of this class can be e.g. a listening socket which multiple
// isolates are listening on.
template <typename DI>
class DescriptorInfoMultipleMixin : public DI {
 private:
  static const int kTokenCount = 4;

  static bool SamePortValue(void* key1, void* key2) {
    return reinterpret_cast<Dart_Port>(key1) ==
           reinterpret_cast<Dart_Port>(key2);
  }

  static uint32_t GetHashmapHashFromPort(Dart_Port port) {
    return static_cast<uint32_t>(port & 0xFFFFFFFF);
  }

  static void* GetHashmapKeyFromPort(Dart_Port port) {
    return reinterpret_cast<void*>(port);
  }

  static bool IsReadingMask(intptr_t mask) {
    if (mask == (1 << kInEvent)) {
      return true;
    } else {
      ASSERT(mask == 0);
      return false;
    }
  }

  struct PortEntry {
    Dart_Port dart_port;
    intptr_t is_reading;
    intptr_t token_count;

    bool IsReady() { return token_count > 0 && is_reading; }
  };

 public:
  DescriptorInfoMultipleMixin(intptr_t fd, bool disable_tokens)
      : DI(fd),
        tokens_map_(&SamePortValue, kTokenCount),
        disable_tokens_(disable_tokens) {}

  virtual ~DescriptorInfoMultipleMixin() { RemoveAllPorts(); }

  virtual bool IsListeningSocket() const { return true; }

  virtual void SetPortAndMask(Dart_Port port, intptr_t mask) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), true);
    PortEntry* pentry;
    if (entry->value == NULL) {
      pentry = new PortEntry();
      pentry->dart_port = port;
      pentry->token_count = kTokenCount;
      pentry->is_reading = IsReadingMask(mask);
      entry->value = reinterpret_cast<void*>(pentry);

      if (pentry->IsReady()) {
        active_readers_.Add(pentry);
      }
    } else {
      pentry = reinterpret_cast<PortEntry*>(entry->value);
      bool was_ready = pentry->IsReady();
      pentry->is_reading = IsReadingMask(mask);
      bool is_ready = pentry->IsReady();

      if (was_ready && !is_ready) {
        active_readers_.Remove(pentry);
      } else if (!was_ready && is_ready) {
        active_readers_.Add(pentry);
      }
    }

#ifdef DEBUG
    // To ensure that all readers are ready.
    int ready_count = 0;

    if (active_readers_.HasHead()) {
      PortEntry* root = reinterpret_cast<PortEntry*>(active_readers_.head());
      PortEntry* current = root;
      do {
        ASSERT(current->IsReady());
        ready_count++;
        active_readers_.Rotate();
        current = active_readers_.head();
      } while (current != root);
    }

    for (HashMap::Entry* entry = tokens_map_.Start(); entry != NULL;
         entry = tokens_map_.Next(entry)) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
      if (pentry->IsReady()) {
        ready_count--;
      }
    }
    // Ensure all ready items are in `active_readers_`.
    ASSERT(ready_count == 0);
#endif
  }

  virtual void RemovePort(Dart_Port port) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), false);
    if (entry != NULL) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
      if (pentry->IsReady()) {
        active_readers_.Remove(pentry);
      }
      tokens_map_.Remove(GetHashmapKeyFromPort(port),
                         GetHashmapHashFromPort(port));
      delete pentry;
    } else {
      // NOTE: This is a listening socket which has been immediately closed.
      //
      // If a listening socket is not listened on, the event handler does not
      // know about it beforehand. So the first time the event handler knows
      // about it, is when it is supposed to be closed. We therefore do nothing
      // here.
      //
      // But whether to close it, depends on whether other isolates have it open
      // as well or not.
    }
  }

  virtual void RemoveAllPorts() {
    for (HashMap::Entry* entry = tokens_map_.Start(); entry != NULL;
         entry = tokens_map_.Next(entry)) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
      entry->value = NULL;
      active_readers_.Remove(pentry);
      delete pentry;
    }
    tokens_map_.Clear();
    active_readers_.RemoveAll(DeletePortEntry);
  }

  virtual Dart_Port NextNotifyDartPort(intptr_t events_ready) {
    // We're only sending `kInEvents` if there are multiple listeners (which is
    // listening socktes).
    ASSERT(IS_EVENT(events_ready, kInEvent) ||
           IS_EVENT(events_ready, kDestroyedEvent));

    if (active_readers_.HasHead()) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(active_readers_.head());

      // Update token count.
      if (!disable_tokens_) {
        pentry->token_count--;
      }
      if (pentry->token_count <= 0) {
        active_readers_.RemoveHead();
      } else {
        active_readers_.Rotate();
      }

      return pentry->dart_port;
    }
    return 0;
  }

  virtual void NotifyAllDartPorts(uintptr_t events) {
    // Unexpected close, asynchronous destroy or error events are the only
    // ones we broadcast to all listeners.
    ASSERT(IS_EVENT(events, kCloseEvent) || IS_EVENT(events, kErrorEvent) ||
           IS_EVENT(events, kDestroyedEvent));

    for (HashMap::Entry* entry = tokens_map_.Start(); entry != NULL;
         entry = tokens_map_.Next(entry)) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
      DartUtils::PostInt32(pentry->dart_port, events);

      // Update token count.
      bool was_ready = pentry->IsReady();
      if (!disable_tokens_) {
        pentry->token_count--;
      }

      if (was_ready && (pentry->token_count <= 0)) {
        active_readers_.Remove(pentry);
      }
    }
  }

  virtual void ReturnTokens(Dart_Port port, int count) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), false);
    ASSERT(entry != NULL);

    PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
    bool was_ready = pentry->IsReady();
    if (!disable_tokens_) {
      pentry->token_count += count;
    }
    ASSERT(pentry->token_count <= kTokenCount);
    bool is_ready = pentry->token_count > 0 && pentry->IsReady();
    if (!was_ready && is_ready) {
      active_readers_.Add(pentry);
    }
  }

  virtual intptr_t Mask() {
    if (active_readers_.HasHead()) {
      return 1 << kInEvent;
    }
    return 0;
  }

  virtual void Close() { DI::Close(); }

 private:
  static void DeletePortEntry(void* data) {
    PortEntry* entry = reinterpret_cast<PortEntry*>(data);
    delete entry;
  }

  // The [Dart_Port]s which are not paused (i.e. are interested in read events,
  // i.e. `mask == (1 << kInEvent)`) and we have enough tokens to communicate
  // with them.
  CircularLinkedList<PortEntry*> active_readers_;

  // A convenience mapping:
  //   Dart_Port -> struct PortEntry { dart_port, mask, token_count }
  HashMap tokens_map_;

  bool disable_tokens_;

  DISALLOW_COPY_AND_ASSIGN(DescriptorInfoMultipleMixin);
};

}  // namespace bin
}  // namespace dart

// The event handler delegation class is OS specific.
#if defined(HOST_OS_ANDROID)
#include "bin/eventhandler_android.h"
#elif defined(HOST_OS_FUCHSIA)
#include "bin/eventhandler_fuchsia.h"
#elif defined(HOST_OS_LINUX)
#include "bin/eventhandler_linux.h"
#elif defined(HOST_OS_MACOS)
#include "bin/eventhandler_macos.h"
#elif defined(HOST_OS_WINDOWS)
#include "bin/eventhandler_win.h"
#else
#error Unknown target os.
#endif

namespace dart {
namespace bin {

class EventHandler {
 public:
  EventHandler() {}
  void SendData(intptr_t id, Dart_Port dart_port, int64_t data) {
    delegate_.SendData(id, dart_port, data);
  }

  /**
   * Signal to main thread that event handler is done.
   */
  void NotifyShutdownDone();

  /**
   * Start the event-handler.
   */
  static void Start();

  /**
   * Stop the event-handler. It's expected that there will be no further calls
   * to SendData after a call to Stop.
   */
  static void Stop();

  static EventHandlerImplementation* delegate();

  static void SendFromNative(intptr_t id, Dart_Port port, int64_t data);

 private:
  friend class EventHandlerImplementation;
  EventHandlerImplementation delegate_;

  DISALLOW_COPY_AND_ASSIGN(EventHandler);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EVENTHANDLER_H_
