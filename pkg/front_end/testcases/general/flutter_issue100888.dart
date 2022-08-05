// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class ChannelA {
  ChannelB? get channel;
}

abstract class ChannelB {
  ActiveFrom? get activeFrom;
}

abstract class ActiveFrom {
  DateTime toLocal();
}

void method(ChannelA channel) {
  DateTime? af = channel.channel?.activeFrom != null ? DateTime(
      channel.channel!.activeFrom!.toLocal().year,
      channel.channel!.activeFrom!.toLocal().month,
      channel.channel!.activeFrom!.toLocal().day);
}