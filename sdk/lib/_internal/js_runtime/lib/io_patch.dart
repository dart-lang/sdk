// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_helper' show patch;

@patch
class _Directory {
  @patch
  static _current() {
    throw new UnsupportedError("Directory._current");
  }
  @patch
  static _setCurrent(path) {
    throw new UnsupportedError("Directory_SetCurrent");
  }
  @patch
  static _createTemp(String path) {
    throw new UnsupportedError("Directory._createTemp");
  }
  @patch
  static String _systemTemp() {
    throw new UnsupportedError("Directory._systemTemp");
  }
  @patch
  static _exists(String path) {
    throw new UnsupportedError("Directory._exists");
  }
  @patch
  static _create(String path) {
    throw new UnsupportedError("Directory._create");
  }
  @patch
  static _deleteNative(String path, bool recursive) {
    throw new UnsupportedError("Directory._deleteNative");
  }
  @patch
  static _rename(String path, String newPath) {
    throw new UnsupportedError("Directory._rename");
  }
  @patch
  static void _fillWithDirectoryListing(
      List<FileSystemEntity> list, String path, bool recursive,
      bool followLinks) {
    throw new UnsupportedError("Directory._fillWithDirectoryListing");
  }
}

@patch
class _AsyncDirectoryListerOps {
  @patch
  factory _AsyncDirectoryListerOps(int pointer) {
    throw new UnsupportedError("Directory._list");
  }
}

@patch
class _EventHandler {
  @patch
  static void _sendData(Object sender,
                        SendPort sendPort,
                        int data) {
    throw new UnsupportedError("EventHandler._sendData");
  }
}

@patch
class FileStat {
  @patch
  static _statSync(String path) {
    throw new UnsupportedError("FileStat.stat");
  }
}

@patch
class FileSystemEntity {
  @patch
  static _getType(String path, bool followLinks) {
    throw new UnsupportedError("FileSystemEntity._getType");
  }
  @patch
  static _identical(String path1, String path2) {
    throw new UnsupportedError("FileSystemEntity._identical");
  }
  @patch
  static _resolveSymbolicLinks(String path) {
    throw new UnsupportedError("FileSystemEntity._resolveSymbolicLinks");
  }
}

@patch
class _File {
  @patch
  static _exists(String path) {
    throw new UnsupportedError("File._exists");
  }
  @patch
  static _create(String path) {
    throw new UnsupportedError("File._create");
  }
  @patch
  static _createLink(String path, String target) {
    throw new UnsupportedError("File._createLink");
  }
  @patch
  static _linkTarget(String path) {
    throw new UnsupportedError("File._linkTarget");
  }
  @patch
  static _deleteNative(String path) {
    throw new UnsupportedError("File._deleteNative");
  }
  @patch
  static _deleteLinkNative(String path) {
    throw new UnsupportedError("File._deleteLinkNative");
  }
  @patch
  static _rename(String oldPath, String newPath) {
    throw new UnsupportedError("File._rename");
  }
  @patch
  static _renameLink(String oldPath, String newPath) {
    throw new UnsupportedError("File._renameLink");
  }
  @patch
  static _copy(String oldPath, String newPath) {
    throw new UnsupportedError("File._copy");
  }
  @patch
  static _lengthFromPath(String path) {
    throw new UnsupportedError("File._lengthFromPath");
  }
  @patch
  static _lastModified(String path) {
    throw new UnsupportedError("File._lastModified");
  }
  @patch
  static _open(String path, int mode) {
    throw new UnsupportedError("File._open");
  }
  @patch
  static int _openStdio(int fd) {
    throw new UnsupportedError("File._openStdio");
  }
}

@patch
class _RandomAccessFileOps {
  @patch
  factory _RandomAccessFileOps(int pointer) {
    throw new UnsupportedError("RandomAccessFile");
  }
}

@patch
class _IOCrypto {
  @patch
  static Uint8List getRandomBytes(int count) {
    throw new UnsupportedError("_IOCrypto.getRandomBytes");
  }
}

@patch
class _Platform {
  @patch
  static int _numberOfProcessors() {
    throw new UnsupportedError("Platform._numberOfProcessors");
  }
  @patch
  static String _pathSeparator() {
    throw new UnsupportedError("Platform._pathSeparator");
  }
  @patch
  static String _operatingSystem() {
    throw new UnsupportedError("Platform._operatingSystem");
  }
  @patch
  static _localHostname() {
    throw new UnsupportedError("Platform._localHostname");
  }
  @patch
  static _executable() {
    throw new UnsupportedError("Platform._executable");
  }
  @patch
  static _resolvedExecutable() {
    throw new UnsupportedError("Platform._resolvedExecutable");
  }
  @patch
  static List<String> _executableArguments() {
    throw new UnsupportedError("Platform._executableArguments");
  }
  @patch
  static String _packageRoot() {
    throw new UnsupportedError("Platform._packageRoot");
  }
  @patch
  static String _packageConfig() {
    throw new UnsupportedError("Platform._packageConfig");
  }
  @patch
  static _environment() {
    throw new UnsupportedError("Platform._environment");
  }
  @patch
  static String _version() {
    throw new UnsupportedError("Platform._version");
  }
}

@patch
class _ProcessUtils {
  @patch
  static void _exit(int status) {
    throw new UnsupportedError("ProcessUtils._exit");
  }
  @patch
  static void _setExitCode(int status) {
    throw new UnsupportedError("ProcessUtils._setExitCode");
  }
  @patch
  static int _getExitCode() {
    throw new UnsupportedError("ProcessUtils._getExitCode");
  }
  @patch
  static void _sleep(int millis) {
    throw new UnsupportedError("ProcessUtils._sleep");
  }
  @patch
  static int _pid(Process process) {
    throw new UnsupportedError("ProcessUtils._pid");
  }
  @patch
  static Stream<ProcessSignal> _watchSignal(ProcessSignal signal) {
    throw new UnsupportedError("ProcessUtils._watchSignal");
  }
}

@patch
class Process {
  @patch
  static Future<Process> start(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       bool includeParentEnvironment: true,
       bool runInShell: false,
       ProcessStartMode mode: ProcessStartMode.NORMAL}) {
    throw new UnsupportedError("Process.start");
  }

  @patch
  static Future<ProcessResult> run(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       bool includeParentEnvironment: true,
       bool runInShell: false,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
    throw new UnsupportedError("Process.run");
  }

  @patch
  static ProcessResult runSync(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       bool includeParentEnvironment: true,
       bool runInShell: false,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
    throw new UnsupportedError("Process.runSync");
  }

  @patch
  static bool killPid(
      int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    throw new UnsupportedError("Process.killPid");
  }
}

@patch
class InternetAddress {
  @patch
  static InternetAddress get LOOPBACK_IP_V4 {
    throw new UnsupportedError("InternetAddress.LOOPBACK_IP_V4");
  }
  @patch
  static InternetAddress get LOOPBACK_IP_V6 {
    throw new UnsupportedError("InternetAddress.LOOPBACK_IP_V6");
  }
  @patch
  static InternetAddress get ANY_IP_V4 {
    throw new UnsupportedError("InternetAddress.ANY_IP_V4");
  }
  @patch
  static InternetAddress get ANY_IP_V6 {
    throw new UnsupportedError("InternetAddress.ANY_IP_V6");
  }
  @patch
  factory InternetAddress(String address) {
    throw new UnsupportedError("InternetAddress");
  }
  @patch
  static Future<List<InternetAddress>> lookup(
      String host, {InternetAddressType type: InternetAddressType.ANY}) {
    throw new UnsupportedError("InternetAddress.lookup");
  }
  @patch
  static InternetAddress _cloneWithNewHost(
      InternetAddress address, String host) {
    throw new UnsupportedError("InternetAddress._cloneWithNewHost");
  }
}

@patch
class NetworkInterface {
  @patch
  static bool get listSupported {
    throw new UnsupportedError("NetworkInterface.listSupported");
  }
  @patch
  static Future<List<NetworkInterface>> list({
      bool includeLoopback: false,
      bool includeLinkLocal: false,
      InternetAddressType type: InternetAddressType.ANY}) {
    throw new UnsupportedError("NetworkInterface.list");
  }
}

@patch
class RawServerSocket {
  @patch
  static Future<RawServerSocket> bind(address,
                                      int port,
                                      {int backlog: 0,
                                       bool v6Only: false,
                                       bool shared: false}) {
    throw new UnsupportedError("RawServerSocket.bind");
  }
}

@patch
class ServerSocket {
  @patch
  static Future<ServerSocket> bind(address,
                                   int port,
                                   {int backlog: 0,
                                    bool v6Only: false,
                                    bool shared: false}) {
    throw new UnsupportedError("ServerSocket.bind");
  }
}

@patch
class RawSocket {
  @patch
  static Future<RawSocket> connect(host, int port, {sourceAddress}) {
    throw new UnsupportedError("RawSocket constructor");
  }
}

@patch
class Socket {
  @patch
  static Future<Socket> connect(host, int port, {sourceAddress}) {
    throw new UnsupportedError("Socket constructor");
  }
}

@patch
class SecureSocket {
  @patch
  factory SecureSocket._(RawSecureSocket rawSocket) {
    throw new UnsupportedError("SecureSocket constructor");
  }
}

@patch
class SecurityContext {
  @patch
  factory SecurityContext() {
    throw new UnsupportedError("SecurityContext constructor");
  }

  @patch
  static SecurityContext get defaultContext {
    throw new UnsupportedError("default SecurityContext getter");
  }

  @patch
  static bool get alpnSupported {
    throw new UnsupportedError("SecurityContext alpnSupported getter");
  }
}

@patch
class X509Certificate {
  @patch
  factory X509Certificate._() {
    throw new UnsupportedError("X509Certificate constructor");
  }
}

@patch
class RawDatagramSocket {
  @patch
  static Future<RawDatagramSocket> bind(
      host, int port, {bool reuseAddress: true}) {
    throw new UnsupportedError("RawDatagramSocket.bind");
  }
}

@patch
class _SecureFilter {
  @patch
  factory _SecureFilter() {
    throw new UnsupportedError("_SecureFilter._SecureFilter");
  }
}

@patch
class _StdIOUtils {
  @patch
  static Stdin _getStdioInputStream() {
    throw new UnsupportedError("StdIOUtils._getStdioInputStream");
  }
  @patch
  static _getStdioOutputStream(int fd) {
    throw new UnsupportedError("StdIOUtils._getStdioOutputStream");
  }
  @patch
  static int _socketType(Socket socket) {
    throw new UnsupportedError("StdIOUtils._socketType");
  }
  @patch
  static _getStdioHandleType(int fd) {
    throw new UnsupportedError("StdIOUtils._getStdioHandleType");
  }
}

@patch
class _WindowsCodePageDecoder {
  @patch
  static String _decodeBytes(List<int> bytes) {
    throw new UnsupportedError("_WindowsCodePageDecoder._decodeBytes");
  }
}

@patch
class _WindowsCodePageEncoder {
  @patch
  static List<int> _encodeString(String string) {
    throw new UnsupportedError("_WindowsCodePageEncoder._encodeString");
  }
}

@patch
class _Filter {
  @patch
  static _Filter _newZLibDeflateFilter(bool gzip, int level,
                                       int windowBits, int memLevel,
                                       int strategy,
                                       List<int> dictionary, bool raw) {
    throw new UnsupportedError("_newZLibDeflateFilter");
  }
  @patch
  static _Filter _newZLibInflateFilter(int windowBits,
                                       List<int> dictionary, bool raw) {
    throw new UnsupportedError("_newZLibInflateFilter");
  }
}

@patch
class Stdin {
  @patch
  int readByteSync() {
    throw new UnsupportedError("Stdin.readByteSync");
  }
  @patch
  bool get echoMode {
    throw new UnsupportedError("Stdin.echoMode");
  }
  @patch
  void set echoMode(bool enabled) {
    throw new UnsupportedError("Stdin.echoMode");
  }
  @patch
  bool get lineMode {
    throw new UnsupportedError("Stdin.lineMode");
  }
  @patch
  void set lineMode(bool enabled) {
    throw new UnsupportedError("Stdin.lineMode");
  }
}

@patch
class Stdout {
  @patch
  bool _hasTerminal(int fd) {
    throw new UnsupportedError("Stdout.hasTerminal");
  }
  @patch
  int _terminalColumns(int fd) {
    throw new UnsupportedError("Stdout.terminalColumns");
  }
  @patch
  int _terminalLines(int fd) {
    throw new UnsupportedError("Stdout.terminalLines");
  }
}

@patch
class _FileSystemWatcher {
  @patch
  static Stream<FileSystemEvent> _watch(
      String path, int events, bool recursive) {
    throw new UnsupportedError("_FileSystemWatcher.watch");
  }
  @patch
  static bool get isSupported {
    throw new UnsupportedError("_FileSystemWatcher.isSupported");
  }
}

@patch
class _IOService {
  @patch
  static Future _dispatch(int request, List data) {
    throw new UnsupportedError("_IOService._dispatch");
  }
}
