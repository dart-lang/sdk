// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/port.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Port) {
  const char* msg_data = "Hallo Velo!";

  intptr_t port1 = PortMap::CreatePort();
  intptr_t port2 = PortMap::CreatePort();
  EXPECT(port1 != port2);

  PortMessage* msg1 = new PortMessage(port1, 0, strdup(msg_data));
  EXPECT_EQ(true, PortMap::PostMessage(msg1));
  PortMessage* msg = PortMap::ReceiveMessage(10);
  EXPECT_EQ(port1, msg->dest_id());
  EXPECT_EQ(msg1, msg);
  delete msg1;

  msg1 = new PortMessage(port2, 0, strdup(msg_data));
  EXPECT_EQ(true, PortMap::PostMessage(msg1));
  msg = PortMap::ReceiveMessage(10);
  EXPECT_EQ(port2, msg->dest_id());
  EXPECT_EQ(msg1, msg);
  delete msg1;

  PortMap::ClosePort(port1);
  EXPECT_EQ(false, PortMap::IsActivePort(port1));
  msg1 = new PortMessage(port1, 0, strdup(msg_data));
  EXPECT_EQ(false, PortMap::PostMessage(msg1));
  delete msg1;
  EXPECT(PortMap::ReceiveMessage(10) == NULL);

  EXPECT_EQ(true, PortMap::IsActivePort(port2));
  msg1 = new PortMessage(port2, 0, strdup(msg_data));
  EXPECT_EQ(true, PortMap::PostMessage(msg1));
  PortMap::ClosePort(port2);
  EXPECT(PortMap::ReceiveMessage(10) == NULL);

  for (int i = 0; i < 32; i++) {
    intptr_t port = PortMap::CreatePort();
    PortMap::ClosePort(port);
  }
}


// End-of-test marker.
static const intptr_t kEOT = 0xFFFF;

void* AllocIntData(intptr_t payload) {
  intptr_t* result = reinterpret_cast<intptr_t*>(malloc(sizeof(payload)));
  *result = payload;
  return result;
}


intptr_t GetIntData(void* data) {
  return *reinterpret_cast<intptr_t*>(data);
}


void ThreadedPort_start(uword parameter) {
  Dart::CreateIsolate(NULL, NULL);

  intptr_t remote = parameter;
  intptr_t local = PortMap::CreatePort();

  PortMap::PostMessage(new PortMessage(remote, 0, AllocIntData(local)));

  intptr_t count = 0;
  while (true) {
    PortMessage* msg = PortMap::ReceiveMessage(0);
    EXPECT_EQ(local, msg->dest_id());
    EXPECT(msg != NULL);
    if (GetIntData(msg->data()) == kEOT) {
      break;
    }
    EXPECT(GetIntData(msg->data()) == count);
    delete msg;
    PortMap::PostMessage(new PortMessage(remote, 0, AllocIntData(count * 2)));
    count++;
  }
  PortMap::PostMessage(new PortMessage(remote, 0, AllocIntData(kEOT)));

  Dart::ShutdownIsolate();
}


TEST_CASE(ThreadedPort) {
  intptr_t local = PortMap::CreatePort();

  Thread* thr = new Thread(ThreadedPort_start, local);
  EXPECT(thr != NULL);

  PortMessage* msg = PortMap::ReceiveMessage(0);
  EXPECT_EQ(local, msg->dest_id());
  EXPECT(msg != NULL);
  intptr_t remote = GetIntData(msg->data());  // Get the remote port.
  delete msg;

  for (intptr_t i = 0; i < 10; i++) {
    PortMap::PostMessage(new PortMessage(remote, 0, AllocIntData(i)));
    PortMessage* msg = PortMap::ReceiveMessage(0);
    EXPECT_EQ(local, msg->dest_id());
    EXPECT(msg != NULL);
    EXPECT_EQ(i * 2, GetIntData(msg->data()));
    delete msg;
  }

  PortMap::PostMessage(new PortMessage(remote, 0, AllocIntData(kEOT)));
  msg = PortMap::ReceiveMessage(0);
  EXPECT_EQ(local, msg->dest_id());
  EXPECT(msg != NULL);
  EXPECT_EQ(kEOT, GetIntData(msg->data()));
  delete msg;

  // Give the spawned thread enough time to properly exit.
  Monitor* waiter = new Monitor();
  {
    MonitorLocker ml(waiter);
    ml.Wait(20);
  }
  delete waiter;
}

}  // namespace dart
