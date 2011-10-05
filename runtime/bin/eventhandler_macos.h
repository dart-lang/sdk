// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_EVENTHANDLER_MACOS_H_
#define BIN_EVENTHANDLER_MACOS_H_


typedef struct {
  intptr_t id;
  Dart_Port dart_port;
  int64_t data;
} InterruptMessage;


typedef struct {
  Dart_Port dart_port;
  intptr_t mask;
} PortData;


class EventHandlerImplementation {
 public:
  EventHandlerImplementation();
  ~EventHandlerImplementation();

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
  Dart_Port PortFor(intptr_t fd);
  intptr_t GetPollEvents(struct pollfd* pollfd);
  void SetPollEvents(struct pollfd* pollfds, intptr_t mask);

  PortData* port_map_;
  intptr_t port_map_entries_;
  intptr_t port_map_size_;
  int64_t timeout_;  // Time for next timeout.
  Dart_Port timeout_port_;
  int interrupt_fds_[2];
};


#endif  // BIN_EVENTHANDLER_MACOS_H_
