dart_library.library('language/regress_23089_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_23089_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_23089_test = Object.create(null);
  let IPeer = () => (IPeer = dart.constFn(regress_23089_test.IPeer$()))();
  let IPeerRoom = () => (IPeerRoom = dart.constFn(regress_23089_test.IPeerRoom$()))();
  let IP2PClient = () => (IP2PClient = dart.constFn(regress_23089_test.IP2PClient$()))();
  let _Peer = () => (_Peer = dart.constFn(regress_23089_test._Peer$()))();
  let _PeerRoom = () => (_PeerRoom = dart.constFn(regress_23089_test._PeerRoom$()))();
  let _P2PClient = () => (_P2PClient = dart.constFn(regress_23089_test._P2PClient$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  regress_23089_test.IPeer$ = dart.generic(C => {
    class IPeer extends core.Object {}
    dart.addTypeTests(IPeer);
    return IPeer;
  });
  regress_23089_test.IPeer = IPeer();
  regress_23089_test.IPeerRoom$ = dart.generic((P, C) => {
    class IPeerRoom extends core.Object {}
    dart.addTypeTests(IPeerRoom);
    return IPeerRoom;
  });
  regress_23089_test.IPeerRoom = IPeerRoom();
  regress_23089_test.IP2PClient$ = dart.generic(R => {
    class IP2PClient extends core.Object {}
    dart.addTypeTests(IP2PClient);
    return IP2PClient;
  });
  regress_23089_test.IP2PClient = IP2PClient();
  regress_23089_test._Peer$ = dart.generic(C => {
    let IPeerOfC = () => (IPeerOfC = dart.constFn(regress_23089_test.IPeer$(C)))();
    class _Peer extends core.Object {}
    dart.addTypeTests(_Peer);
    _Peer[dart.implements] = () => [IPeerOfC()];
    return _Peer;
  });
  regress_23089_test._Peer = _Peer();
  regress_23089_test._PeerRoom$ = dart.generic((P, C) => {
    let IPeerRoomOfP$C = () => (IPeerRoomOfP$C = dart.constFn(regress_23089_test.IPeerRoom$(P, C)))();
    class _PeerRoom extends core.Object {}
    dart.addTypeTests(_PeerRoom);
    _PeerRoom[dart.implements] = () => [IPeerRoomOfP$C()];
    return _PeerRoom;
  });
  regress_23089_test._PeerRoom = _PeerRoom();
  regress_23089_test._P2PClient$ = dart.generic((R, P) => {
    let IP2PClientOfR = () => (IP2PClientOfR = dart.constFn(regress_23089_test.IP2PClient$(R)))();
    class _P2PClient extends core.Object {}
    dart.addTypeTests(_P2PClient);
    _P2PClient[dart.implements] = () => [IP2PClientOfR()];
    return _P2PClient;
  });
  regress_23089_test._P2PClient = _P2PClient();
  regress_23089_test.main = function() {
  };
  dart.fn(regress_23089_test.main, VoidTovoid());
  // Exports:
  exports.regress_23089_test = regress_23089_test;
});
