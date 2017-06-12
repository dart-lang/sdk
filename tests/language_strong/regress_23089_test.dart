// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class IPeer<C extends IP2PClient> {}

abstract class IPeerRoom<P extends IPeer, C extends IP2PClient> {}

abstract class IP2PClient<R extends IPeerRoom> {}

class _Peer<C extends _P2PClient> implements IPeer<C> {}

class _PeerRoom<P extends _Peer, C extends _P2PClient>
    implements IPeerRoom<P, C> {}

abstract class _P2PClient<R extends _PeerRoom, P extends _Peer>
    implements IP2PClient<R> {}

void main() {}
