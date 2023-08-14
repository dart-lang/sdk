// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test doesn't cover http://dartbug.com/23089 anymore.
// Generic bounds now must be fully instantiated. This means that the
// cycle is not possible anymore.

abstract class IPeer<C extends IP2PClient> {}
//                             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

abstract class IPeerRoom<P extends IPeer, C extends IP2PClient> {}
//                                 ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND
//                                                  ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

abstract class IP2PClient<R extends IPeerRoom> {}
//             ^
// [cfe] Generic type 'IP2PClient' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through 'IPeerRoom'.
//                                  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

class _Peer<C extends _P2PClient> implements IPeer<C> {}
//                    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

class _PeerRoom<P extends _Peer, C extends _P2PClient>
//                        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND
//                                         ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND
    implements
        IPeerRoom<P, C> {}

abstract class _P2PClient<R extends _PeerRoom, P extends _Peer>
//             ^
// [cfe] Generic type '_P2PClient' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '_Peer'.
// [cfe] Generic type '_P2PClient' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through '_PeerRoom'.
//                                  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND
//                                                       ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND
    implements
        IP2PClient<R> {}

void main() {}
