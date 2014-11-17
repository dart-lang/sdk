// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.manager;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:matcher/matcher.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/channel/byte_stream_channel.dart';

part 'logging_client_channel.dart';

/**
 * The results returned by [ServerManager].analyze(...) once analysis
 * has finished.
 */
class AnalysisResults {
  Duration elapsed;
  int errorCount = 0;
  int hintCount = 0;
  int warningCount = 0;
}


/**
 * [CompletionResults] contains the completion results returned by the server
 * along with the elapse time to receive those completions.
 */
class CompletionResults {
  final Duration elapsed;
  final CompletionResultsParams params;

  CompletionResults(this.elapsed, this.params);

  int get suggestionCount => params.results.length;
}

/**
 * [Editor] is a virtual editor for inspecting and modifying a file's content
 * and updating the server with those modifications.
 */
class Editor {
  final ServerManager manager;
  final File file;
  int offset = 0;
  String _content = null;

  Editor(this.manager, this.file);

  /// Return a future that returns the file content
  Future<String> get content {
    if (_content != null) {
      return new Future.value(_content);
    }
    return file.readAsString().then((String content) {
      _content = content;
      return _content;
    });
  }

  /**
   * Request completion suggestions from the server.
   * Return a future that completes with the completions sent.
   */
  Future<List<CompletionResults>> getSuggestions() {
    Request request = new CompletionGetSuggestionsParams(
        file.path,
        offset).toRequest(manager._nextRequestId);
    Stopwatch stopwatch = new Stopwatch()..start();
    return manager.channel.sendRequest(request).then((Response response) {
      String completionId =
          new CompletionGetSuggestionsResult.fromResponse(response).id;
      var completer = new Completer<List<CompletionResults>>();
      List<CompletionResults> results = [];

      // Listen for completion suggestions
      StreamSubscription<Notification> subscription;
      subscription =
          manager.channel.notificationStream.listen((Notification notification) {
        if (notification.event == 'completion.results') {
          CompletionResultsParams params =
              new CompletionResultsParams.fromNotification(notification);
          if (params.id == completionId) {
            results.add(new CompletionResults(stopwatch.elapsed, params));
            if (params.isLast) {
              stopwatch.stop();
              subscription.cancel();
              completer.complete(results);
            }
          }
        }
      });

      return completer.future;
    });
  }

  /**
   * Move the virtual cursor after the given pattern in the source.
   * Return a future that completes once the cursor has been moved.
   */
  Future<Editor> moveAfter(String pattern) {
    return content.then((String content) {
      offset = content.indexOf(pattern);
      return this;
    });
  }

  /**
   * Replace the specified number of characters at the current cursor location
   * with the given text, but do not save that content to disk.
   * Return a future that completes once the server has been notified.
   */
  Future<Editor> replace(int replacementLength, String text) {
    return content.then((String oldContent) {
      StringBuffer sb = new StringBuffer();
      sb.write(oldContent.substring(0, offset));
      sb.write(text);
      sb.write(oldContent.substring(offset));
      _content = sb.toString();
      SourceEdit sourceEdit = new SourceEdit(offset, replacementLength, text);
      Request request = new AnalysisUpdateContentParams({
        file.path: new ChangeContentOverlay([sourceEdit])
      }).toRequest(manager._nextRequestId);
      offset += text.length;
      return manager.channel.sendRequest(request).then((Response response) {
        return this;
      });
    });
  }
}

/**
 * [ServerManager] is used to launch and manage an analysis server
 * running in a separate process.
 */
class ServerManager {

  /**
   * The analysis server process being managed or `null` if not started.
   */
  Process process;

  /**
   * The root directory containing the Dart source files to be analyzed.
   */
  Directory appDir;

  /**
   * The channel used to communicate with the analysis server.
   */
  LoggingClientChannel _channel;

  /**
   * The identifier used in the most recent request to the server.
   * See [_nextRequestId].
   */
  int _lastRequestId = 0;

  /**
   * `true` if a server exception was detected on stderr as opposed to an
   * exception that the server reported via the server.error notification.
   */
  bool _unreportedServerException = false;

  /**
   * `true` if the [stop] method has been called.
   */
  bool _stopRequested = false;

  /**
   * Return the channel used to communicate with the analysis server.
   */
  ClientCommunicationChannel get channel => _channel;

  /**
   * Return `true` if a server error occurred.
   */
  bool get errorOccurred =>
      _unreportedServerException || (_channel.serverErrorCount > 0);

  String get _nextRequestId => (++_lastRequestId).toString();

  /**
   * Direct the server to analyze all sources in the given directory,
   * all sub directories recursively, and any source referenced sources
   * outside this directory hierarch such as referenced packages.
   * Return a future that completes when the analysis is finished.
   */
  Future<AnalysisResults> analyze(Directory appDir) {
    this.appDir = appDir;
    Stopwatch stopwatch = new Stopwatch()..start();
    Request request = new AnalysisSetAnalysisRootsParams(
        [appDir.path],
        []).toRequest(_nextRequestId);

    // Request analysis
    return channel.sendRequest(request).then((Response response) {
      AnalysisResults results = new AnalysisResults();
      StreamSubscription<Notification> subscription;
      Completer<AnalysisResults> completer = new Completer<AnalysisResults>();
      subscription =
          channel.notificationStream.listen((Notification notification) {

        // Gather analysis results
        if (notification.event == 'analysis.errors') {
          AnalysisErrorsParams params =
              new AnalysisErrorsParams.fromNotification(notification);
          params.errors.forEach((AnalysisError error) {
            AnalysisErrorSeverity severity = error.severity;
            if (severity == AnalysisErrorSeverity.ERROR) {
              results.errorCount += 1;
            } else if (severity == AnalysisErrorSeverity.WARNING) {
              results.warningCount += 1;
            } else if (severity == AnalysisErrorSeverity.INFO) {
              results.hintCount += 1;
            } else {
              print('Unknown error severity: ${severity.name}');
            }
          });
        }

        // Stop gathering once analysis is complete
        if (notification.event == 'server.status') {
          ServerStatusParams status =
              new ServerStatusParams.fromNotification(notification);
          AnalysisStatus analysis = status.analysis;
          if (analysis != null && !analysis.isAnalyzing) {
            stopwatch.stop();
            results.elapsed = stopwatch.elapsed;
            subscription.cancel();
            completer.complete(results);
          }
        }
      });
      return completer.future;
    });
  }

  /**
   * Send a request to the server for its version information
   * and return a future that completes with the result.
   */
  Future<ServerGetVersionResult> getVersion() {
    Request request = new ServerGetVersionParams().toRequest(_nextRequestId);
    return channel.sendRequest(request).then((Response response) {
      return new ServerGetVersionResult.fromResponse(response);
    });
  }

  /**
   * Notify the server that the given file will be edited.
   * Return a virtual editor for inspecting and modifying the file's content.
   */
  Future<Editor> openFileNamed(String fileName) {
    return _findFile(fileName, appDir).then((File file) {
      if (file == null) {
        throw 'Failed to find file named $fileName in ${appDir.path}';
      }
      file = file.absolute;
      Request request =
          new AnalysisSetPriorityFilesParams([file.path]).toRequest(_nextRequestId);
      return channel.sendRequest(request).then((Response response) {
        return new Editor(this, file);
      });
    });
  }

  /**
   * Send a request for notifications.
   * Return when the server has acknowledged that request.
   */
  Future setSubscriptions() {
    Request request = new ServerSetSubscriptionsParams(
        [ServerService.STATUS]).toRequest(_nextRequestId);
    return channel.sendRequest(request);
  }

  /**
   * Stop the analysis server.
   * Return a future that completes when the server is terminated.
   */
  Future stop([_]) {
    _stopRequested = true;
    print("Requesting server shutdown");
    Request request = new ServerShutdownParams().toRequest(_nextRequestId);
    Duration waitTime = new Duration(seconds: 5);
    return channel.sendRequest(request).timeout(waitTime, onTimeout: () {
      print('Expected shutdown response');
    }).then((Response response) {
      return channel.close().then((_) => process.exitCode);
    }).timeout(new Duration(seconds: 2), onTimeout: () {
      print('Expected server to shutdown');
      process.kill();
    });
  }

  /**
   * Locate the given file in the directory tree.
   */
  Future<File> _findFile(String fileName, Directory appDir) {
    return appDir.list(recursive: true).firstWhere((FileSystemEntity entity) {
      return entity is File && entity.path.endsWith(fileName);
    });
  }

  /**
   * Launch an analysis server and open a connection to that server.
   */
  Future<ServerManager> _launchServer(String pathToServer) {
    List<String> serverArgs = [pathToServer];
    return Process.start(Platform.executable, serverArgs).catchError((error) {
      exitCode = 21;
      throw 'Failed to launch analysis server: $error';
    }).then((Process process) {
      this.process = process;
      _channel = new LoggingClientChannel(
          new ByteStreamClientChannel(process.stdout, process.stdin));

      // simple out of band exception handling
      process.stderr.transform(
          new Utf8Codec().decoder).transform(new LineSplitter()).listen((String line) {
        if (!_unreportedServerException) {
          _unreportedServerException = true;
          stderr.writeln('>>> Unreported server exception');
        }
        stderr.writeln('server.stderr: $line');
      });

      // watch for unexpected process termination and catch the exit code
      process.exitCode.then((int code) {
        if (!_stopRequested) {
          fail('Unexpected server termination: $code');
        }
        if (code != null && code != 0) {
          exitCode = code;
        }
        print('Server stopped: $code');
      });

      return channel.notificationStream.first.then((Notification notification) {
        print('Server connection established');
        return setSubscriptions().then((_) {
          return getVersion().then((ServerGetVersionResult result) {
            print('Server version ${result.version}');
            return this;
          });
        });
      });
    });
  }

  /**
   * Launch analysis server in a separate process
   * and return a future with a manager for that analysis server.
   */
  static Future<ServerManager> start(String serverPath) {
    return new ServerManager()._launchServer(serverPath);
  }
}
