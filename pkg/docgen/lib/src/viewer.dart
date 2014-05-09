// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Convenience methods wrapped up in a class to pull down the docgen viewer for
/// a viewable website, and start up a server for viewing.
library docgen.viewer;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'generator.dart' as gen;
import 'package_helpers.dart' show rootDirectory;

final String _dartdocViewerString =
    path.join(Directory.current.path, 'dartdoc-viewer');

final Directory _dartdocViewerDir = new Directory(_dartdocViewerString);

Directory _topLevelTempDir;
Directory _webDocsDir;
bool _movedViewerCode = false;

void createViewer(bool serve) {
  _clone();
  _compile();
  if (serve) {
    _runServer();
  }
}

/*
 * dartdoc-viewer currently has the web app code under a 'client' directory
 *
 * This is confusing for folks that want to clone and modify the code.
 * It also includes a number of python files and other content related to
 * app engine hosting that are not needed.
 *
 * This logic exists to support the current model and a (future) updated
 * dartdoc-viewer repo where the 'client' content exists at the root of the
 * project and the other content is removed.
 */
String get _viewerCodePath {
  if (_viewerCodePathCache == null) {
    var pubspecFileName = 'pubspec.yaml';

    var thePath = _dartdocViewerDir.path;

    if (!FileSystemEntity.isFileSync(path.join(thePath, pubspecFileName))) {
      thePath = path.join(thePath, 'client');
      if (!FileSystemEntity.isFileSync(path.join(thePath, pubspecFileName))) {
        throw new StateError('Could not find a pubspec file');
      }
    }

    _viewerCodePathCache = thePath;
  }
  return _viewerCodePathCache;
}
String _viewerCodePathCache;

/// If our dartdoc-viewer code is already checked out, move it to a temporary
/// directory outside of the package directory, so we don't try to process it
/// for documentation.
void ensureMovedViewerCode() {
  // TODO(efortuna): This will need to be modified to run on anyone's package
  // outside of the checkout!
  if (_dartdocViewerDir.existsSync()) {
    _topLevelTempDir = new Directory(rootDirectory).createTempSync();
    _dartdocViewerDir.renameSync(_topLevelTempDir.path);
  }
}

/// Move the dartdoc-viewer code back into place for "webpage deployment."
void addBackViewerCode() {
  if (_movedViewerCode) _dartdocViewerDir.renameSync(_dartdocViewerString);
}

/// Serve up our generated documentation for viewing in a browser.
void _clone() {
  // If the viewer code is already there, then don't clone again.
  if (_dartdocViewerDir.existsSync()) {
    _moveDirectoryAndServe();
  } else {
    var processResult = Process.runSync('git', ['clone', '-b', 'master',
        'https://github.com/dart-lang/dartdoc-viewer.git'], runInShell: true);

    if (processResult.exitCode == 0) {
      /// Move the generated json/yaml docs directory to the dartdoc-viewer
      /// directory, to run as a webpage.
      var processResult = Process.runSync(gen.pubScript, ['upgrade'],
          runInShell: true, workingDirectory: _viewerCodePath);
      print('process output: ${processResult.stdout}');
      print('process stderr: ${processResult.stderr}');

      var dir = new Directory(gen.outputDirectory == null ? 'docs' :
          gen.outputDirectory);
      _webDocsDir = new Directory(path.join(_viewerCodePath, 'web', 'docs'));
      if (dir.existsSync()) {
        // Move the docs folder to dartdoc-viewer/client/web/docs
        dir.renameSync(_webDocsDir.path);
      }
    } else {
      print('Error cloning git repository:');
      print('process output: ${processResult.stdout}');
      print('process stderr: ${processResult.stderr}');
    }
  }
}

/// Move the generated json/yaml docs directory to the dartdoc-viewer
/// directory, to run as a webpage.
void _moveDirectoryAndServe() {
  var processResult = Process.runSync(gen.pubScript, ['upgrade'], runInShell:
      true, workingDirectory: path.join(_dartdocViewerDir.path, 'client'));
  print('process output: ${processResult.stdout}');
  print('process stderr: ${processResult.stderr}');

  var dir = new Directory(gen.outputDirectory == null ? 'docs' :
      gen.outputDirectory);
  var webDocsDir = new Directory(path.join(_dartdocViewerDir.path, 'client',
      'web', 'docs'));
  if (dir.existsSync()) {
    // Move the docs folder to dartdoc-viewer/client/web/docs
    dir.renameSync(webDocsDir.path);
  }

  if (webDocsDir.existsSync()) {
    // Compile the code to JavaScript so we can run on any browser.
    print('Compiling the app to JavaScript.');
    var processResult = Process.runSync(gen.dartBinary, ['deploy.dart'],
        workingDirectory: path.join(_dartdocViewerDir.path, 'client'),
        runInShell: true);
    print('process output: ${processResult.stdout}');
    print('process stderr: ${processResult.stderr}');
    _runServer();
  }
}

void _compile() {
  if (_webDocsDir.existsSync()) {
    // Compile the code to JavaScript so we can run on any browser.
    print('Compiling the app to JavaScript.');
    var processResult = Process.runSync(gen.dartBinary, ['deploy.dart'],
        workingDirectory: _viewerCodePath, runInShell: true);
    print('process output: ${processResult.stdout}');
    print('process stderr: ${processResult.stderr}');
    var outputDir = path.join(_viewerCodePath, 'out', 'web');
    print('Docs are available at $outputDir');
  }
}

/// A simple HTTP server. Implemented here because this is part of the SDK,
/// so it shouldn't have any external dependencies.
void _runServer() {
  // Launch a server to serve out of the directory dartdoc-viewer/client/web.
  HttpServer.bind(InternetAddress.ANY_IP_V6, 8080).then((HttpServer httpServer)
      {
    print('Server launched. Navigate your browser to: '
        'http://localhost:${httpServer.port}');
    httpServer.listen((HttpRequest request) {
      var response = request.response;
      var basePath = path.join(_viewerCodePath, 'out', 'web');
      var requestPath = path.join(basePath, request.uri.path.substring(1));
      bool found = true;
      var file = new File(requestPath);
      if (file.existsSync()) {
        // Set the correct header type.
        if (requestPath.endsWith('.html')) {
          response.headers.set('Content-Type', 'text/html');
        } else if (requestPath.endsWith('.js')) {
          response.headers.set('Content-Type', 'application/javascript');
        } else if (requestPath.endsWith('.dart')) {
          response.headers.set('Content-Type', 'application/dart');
        } else if (requestPath.endsWith('.css')) {
          response.headers.set('Content-Type', 'text/css');
        }
      } else {
        if (requestPath == basePath) {
          response.headers.set('Content-Type', 'text/html');
          file = new File(path.join(basePath, 'index.html'));
        } else {
          print('Path not found: $requestPath');
          found = false;
          response.statusCode = HttpStatus.NOT_FOUND;
          response.close();
        }
      }

      if (found) {
        // Serve up file contents.
        file.openRead().pipe(response).catchError((e) {
          print('HttpServer: error while closing the response stream $e');
        });
      }
    }, onError: (e) {
      print('HttpServer: an error occured $e');
    });
  });
}
