// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(ANDROID) && __ANDROID_API__ < 24

#include "bin/ifaddrs-android.h"

#include <errno.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <net/if.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>

#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

const int kMaxReadSize = 2048;

static bool SetIfName(struct ifaddrs* ifaddr, int interface) {
  char buf[IFNAMSIZ] = {0};
  char* name = if_indextoname(interface, buf);
  if (name == NULL) {
    return false;
  }
  ifaddr->ifa_name = new char[strlen(name) + 1];
  strncpy(ifaddr->ifa_name, name, strlen(name) + 1);
  return true;
}

static void SetFlags(struct ifaddrs* ifaddr, int flag) {
  ifaddr->ifa_flags = flag;
}

static void SetAddresses(struct ifaddrs* ifaddr,
                         int family,
                         int index,
                         void* data,
                         size_t len) {
  if (family == AF_INET6) {
    sockaddr_in6* socketaddr = new sockaddr_in6;
    socketaddr->sin6_family = AF_INET6;
    socketaddr->sin6_scope_id = index;
    memmove(&socketaddr->sin6_addr, data, len);
    ifaddr->ifa_addr = reinterpret_cast<sockaddr*>(socketaddr);
    return;
  }
  ASSERT(family == AF_INET);
  sockaddr_in* socketaddr = new sockaddr_in;
  socketaddr->sin_family = AF_INET;
  memmove(&socketaddr->sin_addr, data, len);
  ifaddr->ifa_addr = reinterpret_cast<sockaddr*>(socketaddr);
}

static void SetNetmask(struct ifaddrs* ifaddr, int family) {
  if (family == AF_INET6) {
    sockaddr_in6* mask = new sockaddr_in6;
    mask->sin6_family = AF_INET6;
    memset(&mask->sin6_addr, 0, sizeof(mask->sin6_addr));
    ifaddr->ifa_netmask = reinterpret_cast<sockaddr*>(mask);
    return;
  }
  ASSERT(family == AF_INET);
  sockaddr_in* mask = new sockaddr_in;
  mask->sin_family = AF_INET;
  memset(&mask->sin_addr, 0, sizeof(mask->sin_addr));
  ifaddr->ifa_netmask = reinterpret_cast<sockaddr*>(mask);
}

static bool SetIfAddrsFromAddrMsg(struct ifaddrs* ifaddr,
                                  ifaddrmsg* msg,
                                  void* bytes,
                                  size_t len,
                                  nlmsghdr* header) {
  SetAddresses(ifaddr, msg->ifa_family, msg->ifa_index, bytes, len);
  SetNetmask(ifaddr, msg->ifa_family);
  SetFlags(ifaddr, msg->ifa_flags);
  return SetIfName(ifaddr, msg->ifa_index);
}

static bool SetIfAddrsFromInfoMsg(struct ifaddrs* ifaddr,
                                  ifinfomsg* ifi,
                                  void* bytes,
                                  size_t len,
                                  nlmsghdr* header) {
  SetAddresses(ifaddr, ifi->ifi_family, ifi->ifi_index, bytes, len);
  SetNetmask(ifaddr, ifi->ifi_family);
  SetFlags(ifaddr, ifi->ifi_flags);
  return SetIfName(ifaddr, ifi->ifi_index);
}

static int SendRequest() {
  int file_descriptor =
      NO_RETRY_EXPECTED(socket(PF_NETLINK, SOCK_RAW, NETLINK_ROUTE));
  if (file_descriptor < 0) {
    return -1;
  }
  nlmsghdr header;
  memset(&header, 0, sizeof(header));
  header.nlmsg_flags = NLM_F_ROOT | NLM_F_REQUEST;
  header.nlmsg_type = RTM_GETADDR;
  header.nlmsg_len = NLMSG_LENGTH(sizeof(ifaddrmsg));
  ssize_t num =
      TEMP_FAILURE_RETRY(send(file_descriptor, &header, header.nlmsg_len, 0));
  if (static_cast<size_t>(num) != header.nlmsg_len) {
    FDUtils::SaveErrorAndClose(file_descriptor);
    return -1;
  }
  return file_descriptor;
}

static int FailAndExit(int fd, ifaddrs* head) {
  FDUtils::SaveErrorAndClose(fd);
  freeifaddrs(head);
  return -1;
}

int getifaddrs(struct ifaddrs** result) {
  int file_descriptor = SendRequest();
  if (file_descriptor < 0) {
    return -1;
  }
  struct ifaddrs* head = NULL;
  struct ifaddrs* cur = NULL;
  char buf[kMaxReadSize];
  ssize_t amount_read;
  while (true) {
    amount_read =
        TEMP_FAILURE_RETRY(recv(file_descriptor, &buf, kMaxReadSize, 0));
    if (amount_read <= 0) {
      break;
    }
    nlmsghdr* header = reinterpret_cast<nlmsghdr*>(&buf[0]);
    size_t header_size = static_cast<size_t>(amount_read);
    for (; NLMSG_OK(header, header_size);
         header = NLMSG_NEXT(header, header_size)) {
      switch (header->nlmsg_type) {
        case RTM_NEWADDR: {
          ifaddrmsg* address_msg =
              reinterpret_cast<ifaddrmsg*>(NLMSG_DATA(header));
          ssize_t payload_len = IFA_PAYLOAD(header);
          for (rtattr* rta = IFA_RTA(address_msg); RTA_OK(rta, payload_len);
               rta = RTA_NEXT(rta, payload_len)) {
            if (rta->rta_type != IFA_ADDRESS) {
              continue;
            }
            int family = address_msg->ifa_family;
            if (family != AF_INET && family != AF_INET6) {
              continue;
            }
            ifaddrs* next = new ifaddrs;
            memset(next, 0, sizeof(*next));
            if (cur != NULL) {
              cur->ifa_next = next;
            } else {
              head = next;
            }
            if (!SetIfAddrsFromAddrMsg(next, address_msg, RTA_DATA(rta),
                                       RTA_PAYLOAD(rta), header)) {
              return FailAndExit(file_descriptor, head);
            }
            cur = next;
          }
          break;
        }
        case RTM_NEWLINK: {
          ifinfomsg* ifi = reinterpret_cast<ifinfomsg*>(NLMSG_DATA(header));
          ssize_t payload_len = IFLA_PAYLOAD(header);
          for (rtattr* rta = IFLA_RTA(ifi); RTA_OK(rta, payload_len);
               rta = RTA_NEXT(rta, payload_len)) {
            if (rta->rta_type != IFA_ADDRESS) {
              continue;
            }
            int family = ifi->ifi_family;
            if (family != AF_INET && family != AF_INET6) {
              continue;
            }
            ifaddrs* next = new ifaddrs;
            memset(next, 0, sizeof(*next));
            if (cur != NULL) {
              cur->ifa_next = next;
            } else {
              head = next;
            }
            if (!SetIfAddrsFromInfoMsg(next, ifi, RTA_DATA(rta),
                                       RTA_PAYLOAD(rta), header)) {
              return FailAndExit(file_descriptor, head);
            }
            cur = next;
          }
          break;
        }
        case NLMSG_DONE:
          *result = head;
          FDUtils::SaveErrorAndClose(file_descriptor);
          return 0;
        case NLMSG_ERROR:
          return FailAndExit(file_descriptor, head);
      }
    }
  }
  return FailAndExit(file_descriptor, head);
}

void freeifaddrs(struct ifaddrs* addrs) {
  int err = errno;
  struct ifaddrs* previous = NULL;
  while (addrs != NULL) {
    delete[] addrs->ifa_name;
    delete addrs->ifa_addr;
    delete addrs->ifa_netmask;
    previous = addrs;
    addrs = addrs->ifa_next;
    delete previous;
  }
  errno = err;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(ANDROID) && __ANDROID_API__ < 24
