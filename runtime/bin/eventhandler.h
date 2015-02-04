// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_H_
#define BIN_EVENTHANDLER_H_

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
  kListeningSocket = 16,
  kPipe = 17,
};

#define EVENT_MASK ((1 << kInEvent) | \
                    (1 << kOutEvent) | \
                    (1 << kErrorEvent) | \
                    (1 << kCloseEvent) | \
                    (1 << kDestroyedEvent))
#define COMMAND_MASK ((1 << kCloseCommand) | \
                      (1 << kShutdownReadCommand) | \
                      (1 << kShutdownWriteCommand) | \
                      (1 << kReturnTokenCommand))
#define IS_COMMAND(data, command_bit) \
    ((data & COMMAND_MASK) == (1 << command_bit))  // NOLINT
#define ASSERT_NO_COMMAND(data) ASSERT((data & COMMAND_MASK) == 0)  // NOLINT
#define TOKEN_COUNT(data) (data & ((1 << kCloseCommand) - 1))

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
    void set_next(Timeout* next) {
      next_ = next;
    }

   private:
    Dart_Port port_;
    int64_t timeout_;
    Timeout* next_;
  };

 public:
  TimeoutQueue() : next_timeout_(NULL), timeouts_(NULL) {}

  ~TimeoutQueue() {
    while (HasTimeout()) RemoveCurrent();
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

  void RemoveCurrent() {
    UpdateTimeout(CurrentPort(), -1);
  }

  void UpdateTimeout(Dart_Port port, int64_t timeout);

 private:
  Timeout* next_timeout_;
  Timeout* timeouts_;
};


template<typename T>
class CircularLinkedList {
 public:
  CircularLinkedList() : head_(NULL) {}

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

  void RemoveHead() {
    Entry* e = head_;
    if (e->next_ == e) {
      head_ = NULL;
    } else {
      e->prev_->next_ = e->next_;
      e->next_->prev_ = e->prev_;
      head_ = e->next_;
    }
    delete e;
  }

  void Remove(T item) {
    if (head_ == NULL) {
      return;
    } else if (head_ == head_->next_) {
      if (head_->t == item) {
        head_ = NULL;
        return;
      }
    } else {
      Entry *current = head_;
      do {
        if (current->t == item) {
          Entry *next = current->next_;
          Entry *prev = current->prev_;
          prev->next_ = next;
          next->prev_ = prev;
          delete current;
          return;
        }
      } while (current != head_);
    }
  }

  T head() const { return head_->t; }

  bool HasHead() const {
    return head_ != NULL;
  }

  void Rotate() {
    head_ = head_->next_;
  }

 private:
  struct Entry {
    explicit Entry(const T& t) : t(t) {}
    const T t;
    Entry* next_;
    Entry* prev_;
  };

  Entry* head_;
};


class DescriptorInfoBase {
 public:
  explicit DescriptorInfoBase(intptr_t fd) : fd_(fd) {
    ASSERT(fd_ != -1);
  }

  virtual ~DescriptorInfoBase() {}

  intptr_t fd() { return fd_; }


  // Type of socket.

  virtual bool IsListeningSocket() const = 0;


  // Ports.

  virtual bool SetPortAndMask(Dart_Port port, intptr_t mask) = 0;

  virtual bool RemovePort(Dart_Port port) = 0;

  // Returns the next port which should be used for sending events to.
  virtual Dart_Port NextPort() = 0;

  virtual bool HasNextPort() = 0;

  // Will post `data` to all known Dart_Ports.
  virtual void SendToAll(uintptr_t data) = 0;


  // Tokens.

  // Returns true if the last token was taken.
  virtual bool TakeToken() = 0;

  // Returns true if the tokens was 0 before adding.
  virtual bool ReturnTokens(Dart_Port port, int count) = 0;

  // Returns true if for any registired Dart_port tokens are available.
  virtual bool HasTokens() const = 0;


  // Other.

  virtual intptr_t Mask() = 0;

  virtual void Close() = 0;

 protected:
  intptr_t fd_;
};


// Describes a OS descriptor (e.g. file descriptor on linux or HANDLE on
// windows) which is connected to a single Dart_Port.
//
// Subclasses of this class can be e.g. connected tcp sockets
template<typename SI>
class DescriptorInfoSingleMixin : public SI {
 public:
  explicit DescriptorInfoSingleMixin(intptr_t fd)
      : SI(fd), port_(0), tokens_(16), mask_(0) {}

  virtual ~DescriptorInfoSingleMixin() { }

  virtual bool IsListeningSocket() const { return false; }

  virtual bool SetPortAndMask(Dart_Port port, intptr_t mask) {
    ASSERT(port_ == 0 || port == port_);
    port_ = port;
    mask_ = mask;
    return true;
  }

  virtual bool RemovePort(Dart_Port port) {
    // TODO(kustermann): Find out where we call RemovePort() with the invalid
    // port. Afterwards remove the part in the ASSERT here.
    ASSERT(port_ == 0 || port_ == port);
    port_ = 0;
    return true;
  }

  virtual Dart_Port NextPort() {
    ASSERT(port_ != 0);
    return port_;
  }

  virtual bool HasNextPort() {
    return port_ != 0;
  }

  virtual void SendToAll(uintptr_t data) {
    if (port_ != 0) {
      DartUtils::PostInt32(port_, data);
    }
  }

  virtual bool TakeToken() {
    ASSERT(tokens_ > 0);
    tokens_--;
    return tokens_ == 0;
  }

  virtual bool ReturnTokens(Dart_Port port, int count) {
    ASSERT(port_ == port);
    ASSERT(tokens_ >= 0);
    bool was_empty = tokens_ == 0;
    tokens_ += count;
    return was_empty;
  }

  virtual bool HasTokens() const { return tokens_ > 0; }

  virtual intptr_t Mask() {
    return mask_;
  }

  virtual void Close() {
    SI::Close();
  }

 private:
  Dart_Port port_;
  int tokens_;
  intptr_t mask_;
};


// Describes a OS descriptor (e.g. file descriptor on linux or HANDLE on
// windows) which is connected to multiple Dart_Port's.
//
// Subclasses of this class can be e.g. a listening socket which multiple
// isolates are listening on.
template<typename SI>
class DescriptorInfoMultipleMixin : public SI {
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
  explicit DescriptorInfoMultipleMixin(intptr_t fd)
      : SI(fd), tokens_map_(&SamePortValue, 4) {}

  virtual ~DescriptorInfoMultipleMixin() {}

  virtual bool IsListeningSocket() const { return true; }

  virtual bool SetPortAndMask(Dart_Port port, intptr_t mask) {
    bool was_empty = !active_readers_.HasHead();
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
    PortEntry* root = reinterpret_cast<PortEntry*>(active_readers_.head());

    int ready_count = 0;
    if (root != NULL) {
      PortEntry* current = root;
      do {
        ASSERT(current->IsReady());
        ready_count++;
        active_readers_.Rotate();
        current = active_readers_.head();
      } while (current != root);
    }
    for (HashMap::Entry *entry = tokens_map_.Start();
         entry != NULL;
         entry = tokens_map_.Next(entry)) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
      if (pentry->IsReady()) {
        ready_count--;
      }
    }
    // Ensure all ready items are in `active_readers_`.
    ASSERT(ready_count == 0);
#endif

    return was_empty && active_readers_.HasHead();
  }

  virtual bool RemovePort(Dart_Port port) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), false);
    if (entry != NULL) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
      if (pentry->IsReady()) {
        active_readers_.Remove(pentry);
      }
      tokens_map_.Remove(
          GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port));
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
    return !active_readers_.HasHead();
  }

  virtual Dart_Port NextPort() {
    ASSERT(active_readers_.HasHead());
    PortEntry* pentry = reinterpret_cast<PortEntry*>(active_readers_.head());
    return pentry->dart_port;
  }

  virtual bool HasNextPort() {
    return active_readers_.HasHead();
  }

  virtual void SendToAll(uintptr_t data) {
    for (HashMap::Entry *entry = tokens_map_.Start();
         entry != NULL;
         entry = tokens_map_.Next(entry)) {
      PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
      DartUtils::PostInt32(pentry->dart_port, data);
    }
  }


  virtual bool TakeToken() {
    ASSERT(active_readers_.HasHead());
    PortEntry* pentry = reinterpret_cast<PortEntry*>(active_readers_.head());
    ASSERT(pentry->token_count > 0);
    pentry->token_count--;
    if (pentry->token_count == 0) {
      active_readers_.RemoveHead();
      return !active_readers_.HasHead();
    } else {
      active_readers_.Rotate();
      return false;
    }
  }

  virtual bool ReturnTokens(Dart_Port port, int count) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), false);
    ASSERT(entry != NULL);

    PortEntry* pentry = reinterpret_cast<PortEntry*>(entry->value);
    pentry->token_count += count;
    if (pentry->token_count == count && pentry->IsReady()) {
      bool was_empty = !active_readers_.HasHead();
      active_readers_.Add(pentry);
      return was_empty;
    }
    return false;
  }

  virtual bool HasTokens() const {
    return active_readers_.HasHead();
  }

  virtual intptr_t Mask() {
    if (active_readers_.HasHead()) {
      return 1 << kInEvent;
    }
    return 0;
  }

  virtual void Close() {
    SI::Close();
  }

 private:
  // The [Dart_Port]s which are not paused (i.e. are interested in read events,
  // i.e. `mask == (1 << kInEvent)`) and we have enough tokens to communicate
  // with them.
  CircularLinkedList<PortEntry *> active_readers_;

  // A convenience mapping:
  //   Dart_Port -> struct PortEntry { dart_port, mask, token_count }
  HashMap tokens_map_;
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

}  // namespace bin
}  // namespace dart

// The event handler delegation class is OS specific.
#if defined(TARGET_OS_ANDROID)
#include "bin/eventhandler_android.h"
#elif defined(TARGET_OS_LINUX)
#include "bin/eventhandler_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "bin/eventhandler_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "bin/eventhandler_win.h"
#else
#error Unknown target os.
#endif

namespace dart {
namespace bin {

class EventHandler {
 public:
  void SendData(intptr_t id, Dart_Port dart_port, int64_t data) {
    delegate_.SendData(id, dart_port, data);
  }

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

 private:
  friend class EventHandlerImplementation;
  EventHandlerImplementation delegate_;
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_EVENTHANDLER_H_
