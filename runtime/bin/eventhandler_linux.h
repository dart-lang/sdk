// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_LINUX_H_
#define BIN_EVENTHANDLER_LINUX_H_

#if !defined(BIN_EVENTHANDLER_H_)
#error Do not include eventhandler_linux.h directly; use eventhandler.h instead.
#endif

#include <errno.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#include "platform/hashmap.h"
#include "platform/signal_blocker.h"


namespace dart {
namespace bin {

class InterruptMessage {
 public:
  intptr_t id;
  Dart_Port dart_port;
  int64_t data;
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

  T head() const { return head_->t; }

  bool HasHead() {
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


class ListeningSocketData;
class SocketData {
 public:
  explicit SocketData(intptr_t fd)
      : fd_(fd), port_(0), mask_(0), tokens_(16) {
    ASSERT(fd_ != -1);
  }

  virtual ~SocketData() {
  }

  intptr_t GetPollEvents();

  void Close() {
    port_ = 0;
    mask_ = 0;
    VOID_TEMP_FAILURE_RETRY(close(fd_));
    fd_ = -1;
  }

  void SetMask(intptr_t mask) {
    ASSERT(fd_ != -1);
    mask_ = mask;
  }

  intptr_t fd() { return fd_; }
  virtual Dart_Port port() { return port_; }

  virtual bool IsListeningSocket() const { return false; }

  virtual bool AddPort(Dart_Port port) {
    ASSERT(port_ == 0);
    port_ = port;
    return true;
  }

  virtual bool RemovePort(Dart_Port port) {
    ASSERT(port_ == 0 || port_ == port);
    return true;
  }

  // Returns true if the last token was taken.
  virtual bool TakeToken() {
    ASSERT(tokens_ > 0);
    tokens_--;
    return tokens_ == 0;
  }

  // Returns true if the tokens was 0 before adding.
  virtual bool ReturnToken(Dart_Port port, int count) {
    ASSERT(port_ == port);
    ASSERT(tokens_ >= 0);
    bool was_empty = tokens_ == 0;
    tokens_ += count;
    return was_empty;
  }

  bool HasTokens() const { return tokens_ > 0; }

 protected:
  intptr_t fd_;
  Dart_Port port_;
  intptr_t mask_;
  int tokens_;
};


class ListeningSocketData : public SocketData {
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

 public:
  explicit ListeningSocketData(intptr_t fd)
      : SocketData(fd),
        tokens_map_(&SamePortValue, 4) {}

  bool IsListeningSocket() const { return true; }

  bool AddPort(Dart_Port port) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), true);
    entry->value = reinterpret_cast<void*>(kTokenCount);
    return live_ports_.Add(port);
  }

  virtual bool RemovePort(Dart_Port port) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), false);
    if (entry != NULL) {
      intptr_t tokens = reinterpret_cast<intptr_t>(entry->value);
      if (tokens == 0) {
        while (idle_ports_.head() != port) {
          idle_ports_.Rotate();
        }
        idle_ports_.RemoveHead();
      } else {
        while (live_ports_.head() != port) {
          live_ports_.Rotate();
        }
        live_ports_.RemoveHead();
      }
      tokens_map_.Remove(
          GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port));
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
    return !live_ports_.HasHead();
  }

  bool TakeToken() {
    ASSERT(live_ports_.HasHead());
    Dart_Port port = live_ports_.head();
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), false);
    ASSERT(entry != NULL);
    intptr_t tokens = reinterpret_cast<intptr_t>(entry->value);
    tokens--;
    entry->value = reinterpret_cast<void*>(tokens);
    if (tokens == 0) {
      live_ports_.RemoveHead();
      idle_ports_.Add(port);
      if (!live_ports_.HasHead()) {
        return true;
      }
    } else {
      live_ports_.Rotate();
    }
    return false;
  }

  Dart_Port port() { return live_ports_.head(); }

  bool ReturnToken(Dart_Port port, int count) {
    HashMap::Entry* entry = tokens_map_.Lookup(
        GetHashmapKeyFromPort(port), GetHashmapHashFromPort(port), false);
    ASSERT(entry != NULL);
    intptr_t tokens = reinterpret_cast<intptr_t>(entry->value);
    tokens += count;
    entry->value = reinterpret_cast<void*>(tokens);
    if (tokens == count) {
      // Return to live_ports_.
      while (idle_ports_.head() != port) {
        idle_ports_.Rotate();
      }
      idle_ports_.RemoveHead();
      bool was_empty = !live_ports_.HasHead();
      live_ports_.Add(port);
      return was_empty;
    }
    return false;
  }

 private:
  CircularLinkedList<Dart_Port> live_ports_;
  CircularLinkedList<Dart_Port> idle_ports_;
  HashMap tokens_map_;
};


class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  // Gets the socket data structure for a given file
  // descriptor. Creates a new one if one is not found.
  SocketData* GetSocketData(intptr_t fd, bool is_listening);
  void SendData(intptr_t id, Dart_Port dart_port, int64_t data);
  void Start(EventHandler* handler);
  void Shutdown();

 private:
  void HandleEvents(struct epoll_event* events, int size);
  static void Poll(uword args);
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  void SetPort(intptr_t fd, Dart_Port dart_port, intptr_t mask);
  intptr_t GetPollEvents(intptr_t events, SocketData* sd);
  static void* GetHashmapKeyFromFd(intptr_t fd);
  static uint32_t GetHashmapHashFromFd(intptr_t fd);

  HashMap socket_map_;
  TimeoutQueue timeout_queue_;
  bool shutdown_;
  int interrupt_fds_[2];
  int epoll_fd_;
  int timer_fd_;
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_EVENTHANDLER_LINUX_H_
