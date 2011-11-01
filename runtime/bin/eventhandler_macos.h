// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_MACOS_H_
#define BIN_EVENTHANDLER_MACOS_H_


class InterruptMessage {
 public:
  intptr_t id;
  Dart_Port dart_port;
  int64_t data;
};


class SocketData {
 public:
  void FillPollEvents(struct pollfd* pollfds);
  bool IsListeningSocket() { return (_mask & (1 << kListeningSocket)) != 0; }

  Dart_Port port() { return _port; }
  void set_port(Dart_Port port) { _port = port; }
  intptr_t mask() { return _mask; }
  void set_mask(intptr_t mask) { _mask = mask; }

 private:
  Dart_Port _port;
  intptr_t _mask;
};


class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

  SocketData* GetSocketData(intptr_t fd);
  void SendData(intptr_t id, Dart_Port dart_port, intptr_t data);
  void StartEventHandler();

 private:
  intptr_t GetTimeout();
  bool GetInterruptMessage(InterruptMessage* msg);
  struct pollfd* GetPollFds(intptr_t* size);
  void RegisterFdWakeup(intptr_t id, Dart_Port dart_port, intptr_t data);
  void UnregisterFdWakeup(intptr_t id);
  void CloseFd(intptr_t id);
  void UnregisterFd(intptr_t id);
  void HandleEvents(struct pollfd* pollfds, int pollfds_size, int result_size);
  void HandleTimeout();
  static void* Poll(void* args);
  void WakeupHandler(intptr_t id, Dart_Port dart_port, int64_t data);
  void HandleInterruptFd();
  void SetPort(intptr_t fd, Dart_Port dart_port, intptr_t mask);
  intptr_t GetPollEvents(struct pollfd* pollfd);

  SocketData* socket_map_;
  intptr_t socket_map_entries_;
  intptr_t socket_map_size_;
  int64_t timeout_;  // Time for next timeout.
  Dart_Port timeout_port_;
  int interrupt_fds_[2];
};


#endif  // BIN_EVENTHANDLER_MACOS_H_
