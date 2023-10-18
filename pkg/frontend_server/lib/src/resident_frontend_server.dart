// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

// front_end/src imports below that require lint `ignore_for_file` are a
// temporary state of things until frontend team builds better api that would
// replace api used below. This api was made private in an effort to discourage
// further use.

import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show exit, File, InternetAddress, ProcessSignal, ServerSocket, Socket;
import 'dart:typed_data' show Uint8List;

import 'package:args/args.dart';
import 'package:front_end/src/api_unstable/vm.dart';

import '../frontend_server.dart';

/// Floor the system time by this amount in order to correctly detect modified
/// source files on all platforms. This has no effect on correctness,
/// but may result in more files being marked as modified than strictly
/// required.
const _stateGranularity = Duration(seconds: 1);

/// Ensures the info file is removed if Ctrl-C is sent to the server.
/// Mostly used when debugging.
StreamSubscription<ProcessSignal>? _cleanupHandler;

extension on DateTime {
  /// Truncates by [amount].
  ///
  /// This is needed because the 1 second granularity on DateTime objects
  /// returned by file stat on Windows is different than the system time's
  /// granularity. We must floor the system time
  /// by 1 second so that if a file is modified within the same second of
  /// the last compile time, it will be correctly detected as being modified.
  DateTime floorTime({Duration amount = _stateGranularity}) {
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch -
        millisecondsSinceEpoch % amount.inMilliseconds);
  }
}

enum _ResidentState {
  waitingForFirstCompile,
  compiling,
  waitingForRecompile,
}

/// A wrapper around the FrontendCompiler, along with all the state needed
/// to perform incremental compilations
///
/// TODO: Fix the race condition that occurs when the ResidentCompiler returns
///   a kernel file to the CLI and another compilation request is given before
///   the VM is able to launch from the kernel that was returned in the first
///   compile request. The ResidentCompiler will be in the state of waiting for
///   a recompile request and will subsequently process the request and modify
///   the kernel file. However, it should be waiting for the VM to finish
///   launching itself from this kernel until it modifies the kernel.
///   As far as I can tell this race also exists in the current CLI run
///   command when using pub's precompile pipeline.
///
/// TODO Fix the race condition that occurs when the same entry point is
///   compiled concurrently.
class ResidentCompiler {
  final File _entryPoint;
  final File _outputDill;
  File? _currentPackage;
  ArgResults _compileOptions;
  late FrontendCompiler _compiler;
  DateTime _lastCompileStartTime = DateTime.now().floorTime();
  _ResidentState _state = _ResidentState.waitingForFirstCompile;
  final StringBuffer _compilerOutput = StringBuffer();
  final Set<Uri> trackedSources = <Uri>{};
  final List<String> _formattedOutput = <String>[];
  var incrementalMode = false;

  ResidentCompiler(this._entryPoint, this._outputDill, this._compileOptions) {
    _compiler = FrontendCompiler(_compilerOutput);
    updateState(_compileOptions);
  }

  /// The [ResidentCompiler] will use the [newOptions] for future compilation
  /// requests.
  void updateState(ArgResults newOptions) {
    final packages = newOptions['packages'];
    incrementalMode = newOptions['incremental'] == true;
    _compileOptions = newOptions;
    _currentPackage = packages == null ? null : File(packages);
    // Refresh the compiler's output for the next compile
    _compilerOutput.clear();
    _formattedOutput.clear();
    _state = _ResidentState.waitingForFirstCompile;
  }

  /// The current compiler options are outdated when any option has changed
  /// since the last compile, or when the packages file has been modified
  bool areOptionsOutdated(ArgResults newOptions) {
    if (newOptions.arguments.length != _compileOptions.arguments.length) {
      return true;
    }
    if (!newOptions.arguments
        .toSet()
        .containsAll(_compileOptions.arguments.toSet())) {
      return true;
    }
    return _currentPackage != null &&
        !_lastCompileStartTime
            .isAfter(_currentPackage!.statSync().modified.floorTime());
  }

  /// Compiles the entry point that this ResidentCompiler is hooked to.
  /// Will perform incremental compilations when possible.
  /// If the options are outdated, must use updateState to get a correct
  /// compile.
  Future<String> compile() async {
    var incremental = false;

    // If this entrypoint was previously compiled on this compiler instance,
    // check which source files need to be recompiled in the incremental
    // compilation request. If no files have been modified, we can return
    // the cached kernel. Otherwise, perform an incremental compilation.
    if (_state == _ResidentState.waitingForRecompile) {
      var invalidatedUris =
          await _getSourceFilesToRecompile(_lastCompileStartTime);
      // No changes to source files detected and cached kernel file exists
      // If a kernel file is removed in between compilation requests,
      // fall through to produce the kernel in recompileDelta.
      if (invalidatedUris.isEmpty && _outputDill.existsSync()) {
        return _encodeCompilerOutput(
            _outputDill.path, _formattedOutput, _compiler.errors.length,
            usingCachedKernel: true);
      }
      _state = _ResidentState.compiling;
      incremental = true;
      for (var invalidatedUri in invalidatedUris) {
        _compiler.invalidate(invalidatedUri);
      }
      _compiler.errors.clear();
      _lastCompileStartTime = DateTime.now().floorTime();
      await _compiler.recompileDelta(entryPoint: _entryPoint.path);
    } else {
      _state = _ResidentState.compiling;
      _lastCompileStartTime = DateTime.now().floorTime();
      _compiler.errors.clear();
      await _compiler.compile(_entryPoint.path, _compileOptions);
    }

    _interpretCompilerOutput(LineSplitter()
        .convert(_compilerOutput.toString())
        .where((line) => line.isNotEmpty)
        .toList());
    _compilerOutput.clear();

    if (incrementalMode) {
      // forces the compiler to produce complete kernel files on each
      // request, even when incrementally compiled.
      _compiler
        ..acceptLastDelta()
        ..resetIncrementalCompiler();
      _state = _ResidentState.waitingForRecompile;
    } else {
      _state = _ResidentState.waitingForFirstCompile;
    }
    return _encodeCompilerOutput(
        _outputDill.path, _formattedOutput, _compiler.errors.length,
        incrementalCompile: incremental);
  }

  /// Reads the compiler's [outputLines] to keep track of which files
  /// need to be tracked. Adds correctly ANSI formatted output to
  /// the [_formattedOutput] list.
  void _interpretCompilerOutput(List<String> outputLines) {
    _formattedOutput.clear();
    var outputLineIndex = 0;
    var acceptingErrorsOrVerboseOutput = true;
    final boundaryKey = outputLines[outputLineIndex]
        .substring(outputLines[outputLineIndex++].indexOf(' ') + 1);
    var line = outputLines[outputLineIndex++];

    while (acceptingErrorsOrVerboseOutput || !line.startsWith(boundaryKey)) {
      if (acceptingErrorsOrVerboseOutput) {
        if (line == boundaryKey) {
          acceptingErrorsOrVerboseOutput = false;
        } else {
          _formattedOutput.add(line);
        }
      } else {
        final diffUri = line.substring(1);
        if (line.startsWith('+')) {
          trackedSources.add(Uri.parse(diffUri));
        } else if (line.startsWith('-')) {
          trackedSources.remove(Uri.parse(diffUri));
        }
      }
      line = outputLines[outputLineIndex++];
    }
  }

  /// Returns a list of uris that need to be recompiled, based on the
  /// [lastkernelCompileTime] timestamp.
  /// Due to Windows timestamp granularity, all timestamps are truncated by
  /// the second. This has no effect on correctness but may result in more
  /// files being marked as invalid than are strictly required.
  Future<List<Uri>> _getSourceFilesToRecompile(
      DateTime lastKernelCompileTime) async {
    final sourcesToRecompile = <Uri>[];
    for (Uri uri in trackedSources) {
      final sourceModifiedTime =
          File(uri.toFilePath()).statSync().modified.floorTime();
      if (!lastKernelCompileTime.isAfter(sourceModifiedTime)) {
        sourcesToRecompile.add(uri);
      }
    }
    return sourcesToRecompile;
  }

  /// Encodes [outputDillPath] and any [formattedErrors] in JSON to
  /// be sent over the socket.
  static String _encodeCompilerOutput(
    String outputDillPath,
    List<String> formattedErrors,
    int errorCount, {
    bool usingCachedKernel = false,
    bool incrementalCompile = false,
  }) {
    return jsonEncode(<String, Object>{
      "success": errorCount == 0,
      "errorCount": errorCount,
      "compilerOutputLines": formattedErrors,
      "output-dill": outputDillPath,
      if (usingCachedKernel) "returnedStoredKernel": true, // used for testing
      if (incrementalCompile) "incremental": true, // used for testing
    });
  }
}

/// Maintains [FrontendCompiler] instances for kernel compilations, meant to be
/// used by the Dart CLI via sockets.
///
/// The [ResidentFrontendServer] manages compilation requests for VM targets
/// between any number of dart entrypoints, and utilizes incremental
/// compilation and existing kernel files for faster compile times.
///
/// Communication is handled on the socket set up by the
/// residentListenAndCompile method.
class ResidentFrontendServer {
  static const _commandString = 'command';
  static const _executableString = 'executable';
  static const _packageString = 'packages';
  static const _outputString = 'output-dill';
  static const _shutdownString = 'shutdown';
  static const _compilerLimit = 3;

  static final shutdownCommand =
      jsonEncode(<String, Object>{_commandString: _shutdownString});
  static final _shutdownJsonResponse =
      jsonEncode(<String, Object>{_shutdownString: true});
  static final _sdkBinariesUri = computePlatformBinariesLocation();
  static final _sdkUri = _sdkBinariesUri.resolve('../../');
  static final _platformKernelUri =
      _sdkBinariesUri.resolve('vm_platform_strong.dill');
  static final Map<String, ResidentCompiler> compilers = {};

  /// Takes in JSON [input] from the socket and compiles the request,
  /// using incremental compilation if possible. Returns a JSON string to be
  /// sent back to the client socket containing either an error message or the
  /// kernel file to be used.
  ///
  /// If the command is compile, paths the source file, package_config.json,
  /// and the output-dill file must be provided via "executable", "packages",
  /// and "output-dill".
  static Future<String> handleRequest(String input) async {
    Map<String, dynamic> request;
    try {
      request = jsonDecode(input);
    } on FormatException {
      return _encodeErrorMessage('$input is not valid JSON.');
    }

    switch (request[_commandString]) {
      case 'compile':
        if (request[_executableString] == null ||
            request[_outputString] == null) {
          return _encodeErrorMessage(
              'compilation requests must include an $_executableString '
              'and an $_outputString path.');
        }
        final executablePath = request[_executableString];
        final cachedDillPath = request[_outputString];
        final options = _generateCompilerOptions(request);

        var residentCompiler = compilers[executablePath];
        if (residentCompiler == null) {
          // Avoids using too much memory
          if (compilers.length >= ResidentFrontendServer._compilerLimit) {
            compilers.remove(compilers.keys.first);
          }
          residentCompiler = ResidentCompiler(
              File(executablePath), File(cachedDillPath), options);
          compilers[executablePath] = residentCompiler;
        } else if (residentCompiler.areOptionsOutdated(options)) {
          residentCompiler.updateState(options);
        }

        return await residentCompiler.compile();
      case 'shutdown':
        return _shutdownJsonResponse;
      default:
        return _encodeErrorMessage(
            'Unsupported command: ${request[_commandString]}.');
    }
  }

  /// Generates the compiler options needed to satisfy the [request]
  static ArgResults _generateCompilerOptions(Map<String, dynamic> request) {
    return argParser.parse(<String>[
      '--sdk-root=${_sdkUri.toFilePath()}',
      if (!request.containsKey('aot')) '--incremental',
      '--platform=${_platformKernelUri.path}',
      '--output-dill=${request[_outputString]}',
      '--target=vm',
      '--filesystem-scheme',
      'org-dartlang-root',
      if (request.containsKey(_packageString))
        '--packages=${request[_packageString]}',
      if (request['support-mirrors'] ?? false) '--support-mirrors',
      if (request['enable-asserts'] ?? false) '--enable-asserts',
      if (request['sound-null-safety'] ?? false) '--sound-null-safety',
      if (request['verbosity'] != null) '--verbosity=${request["verbosity"]}',
      if (request['verbose'] ?? false) '--verbose',
      if (request['aot'] ?? false) '--aot',
      if (request['tfa'] ?? false) '--tfa',
      if (request['rta'] ?? false) '--rta',
      if (request['tree-shake-write-only-fields'] ?? false)
        '--tree-shake-write-only-fields',
      if (request['protobuf-tree-shaker-v2'] ?? false)
        '--protobuf-tree-shaker-v2',
      if (request['define'] != null)
        for (var define in request['define']) define,
      if (request['enable-experiment'] != null)
        for (var experiment in request['enable-experiment']) experiment,
    ]);
  }

  /// Encodes the [message] in JSON to be sent over the socket.
  static String _encodeErrorMessage(String message) =>
      jsonEncode(<String, Object>{"success": false, "errorMessage": message});

  /// Used to create compile requests for the ResidentFrontendServer.
  /// Returns a JSON string that the resident compiler will be able to
  /// interpret.
  static String createCompileJSON(
      {required String executable,
      String? packages,
      required String outputDill,
      bool? supportMirrors,
      bool? enableAsserts,
      bool? soundNullSafety,
      String? verbosity,
      bool? aot,
      bool? tfa,
      bool? rta,
      bool? treeShakeWriteOnlyFields,
      bool? protobufTreeShakerV2,
      List<String>? define,
      List<String>? enableExperiment,
      bool verbose = false}) {
    return jsonEncode(<String, Object>{
      "command": "compile",
      "executable": executable,
      "output-dill": outputDill,
      if (aot != null) "aot": true,
      if (define != null) "define": define,
      if (enableAsserts != null) "enable-asserts": true,
      if (enableExperiment != null) "enable-experiment": enableExperiment,
      if (packages != null) "packages": packages,
      if (protobufTreeShakerV2 != null) "protobuf-tree-shaker-v2": true,
      if (rta != null) "rta": true,
      if (soundNullSafety != null) "sound-null-safety": soundNullSafety,
      if (supportMirrors != null) "support-mirrors": true,
      if (tfa != null) "tfa": true,
      if (treeShakeWriteOnlyFields != null)
        "tree-shaker-write-only-fields": true,
      if (verbosity != null) "verbosity": verbosity,
      "verbose": verbose,
    });
  }
}

/// Sends the JSON string [request] to the resident frontend server
/// and returns server's response in JSON
///
/// Clients must use this function when wanting to interact with a
/// ResidentFrontendServer instance.
Future<Map<String, dynamic>> sendAndReceiveResponse(
    InternetAddress address, int port, String request) async {
  Socket? client;
  Map<String, dynamic> jsonResponse;
  try {
    client = await Socket.connect(address, port);
    client.write(request);
    final data = String.fromCharCodes(await client.first);
    jsonResponse = jsonDecode(data);
  } catch (e) {
    jsonResponse = <String, Object>{
      'success': false,
      'errorMessage': e.toString(),
    };
  }
  if (client != null) {
    client.destroy();
  }
  return jsonResponse;
}

/// Closes the ServerSocket and removes the [serverInfoFile] that is used
/// to access this instance of the Resident Frontend Server.
Future<void> residentServerCleanup(
    ServerSocket server, File serverInfoFile) async {
  try {
    if (_cleanupHandler != null) {
      await _cleanupHandler!.cancel();
    }
  } catch (_) {
  } finally {
    try {
      if (serverInfoFile.existsSync()) {
        serverInfoFile.deleteSync();
      }
    } catch (_) {}
  }

  await server.close();
}

/// Starts a timer that will shut down the resident frontend server in
/// the amount of time specified by [timerDuration], if it is not cancelled.
Timer startShutdownTimer(
    Duration timerDuration, ServerSocket server, File serverInfoFile) {
  return Timer(timerDuration, () async {
    await residentServerCleanup(server, serverInfoFile);
  });
}

/// Listens for compilation commands from socket connections on the
/// provided [address] and [port].
/// If the last request exceeds the amount of time specified by
/// [inactivityTimeout], the server will bring itself down
Future<StreamSubscription<Socket>?> residentListenAndCompile(
    InternetAddress address, int port, File serverInfoFile,
    {Duration inactivityTimeout = const Duration(minutes: 30)}) async {
  ServerSocket server;
  try {
    try {
      serverInfoFile.createSync(exclusive: true);
    } catch (e) {
      throw StateError('A server is already running.');
    }
    server = await ServerSocket.bind(address, port);
    serverInfoFile.writeAsStringSync(
        'address:${server.address.address} port:${server.port}');
  } on StateError catch (e) {
    print('Error: $e\n');
    return null;
  } catch (e) {
    // If we created a file, but bind or writing failed, clean up.
    try {
      serverInfoFile.deleteSync();
    } catch (_) {}
    print('Error: $e\n');
    return null;
  }

  _cleanupHandler = ProcessSignal.sigint.watch().listen((signal) async {
    await residentServerCleanup(server, serverInfoFile);
    exit(1);
  });
  var shutdownTimer =
      startShutdownTimer(inactivityTimeout, server, serverInfoFile);
  // TODO: This should be changed to print to stderr so we don't change the
  // stdout text for regular apps.
  print('The Resident Frontend Compiler is listening at '
      '${server.address.address}:${server.port}');

  return server.listen((client) {
    client.listen((Uint8List data) async {
      String result = await ResidentFrontendServer.handleRequest(
          String.fromCharCodes(data));
      client.write(result);
      shutdownTimer.cancel();
      if (result == ResidentFrontendServer._shutdownJsonResponse) {
        await residentServerCleanup(server, serverInfoFile);
      } else {
        shutdownTimer =
            startShutdownTimer(inactivityTimeout, server, serverInfoFile);
      }
    }, onError: (error) {
      client.close();
    }, onDone: () {
      client.close();
    });
  }, onError: (_) async {
    shutdownTimer.cancel();
    await residentServerCleanup(server, serverInfoFile);
  });
}
