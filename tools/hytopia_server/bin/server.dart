import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  // CLI: `hytopia init`
  if (args.isNotEmpty && args.first == 'init') {
    await _performInit();
    return;
  }

  final ip = InternetAddress.anyIPv4;
  final port = int.tryParse(Platform.environment['HYTOPIA_PORT'] ?? '8080') ?? 8080;

  final server = await HttpServer.bind(ip, port);
  print('Hytopia server running on http://$ip:$port');

  await for (HttpRequest request in server) {
    try {
      _setDefaultHeaders(request);

      final path = request.uri.path;

      if (path == '/' || path == '/index.html') {
        _serveStaticFile(request, 'public/index.html');
      } else if (path == '/health') {
        _handleHealth(request);
      } else if (path == '/echo' && request.method == 'POST') {
        await _handleEcho(request);
      } else if (path.startsWith('/static/')) {
        final filePath = 'public' + path.substring('/static'.length);
        _serveStaticFile(request, filePath);
      } else {
        _notFound(request);
      }
    } catch (e, st) {
      stderr.writeln('Error handling request: $e\n$st');
      _internalError(request, e.toString());
    }
  }
}

Future<void> _performInit() async {
  final baseDir = Directory('tools/hytopia_server/.hytopia');
  if (!baseDir.existsSync()) {
    baseDir.createSync(recursive: true);
  }

  final configFile = File('${baseDir.path}/config.json');
  if (configFile.existsSync()) {
    print('Hytopia already initialized at ${baseDir.path}');
    return;
  }

  final defaultConfig = {
    'port': 8080,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'welcomeMessage': 'Welcome Shadow Army!'
  };

  await configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(defaultConfig));
  print('Initialized Hytopia config at ${configFile.path}');
}

void _setDefaultHeaders(HttpRequest request) {
  request.response.headers.set('content-type', 'application/json; charset=utf-8');
  request.response.headers.set('access-control-allow-origin', '*');
  request.response.headers.set('access-control-allow-methods', 'GET,POST,OPTIONS');
  request.response.headers.set('access-control-allow-headers', 'content-type');
  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    request.response.close();
  }
}

void _handleHealth(HttpRequest request) {
  request.response.statusCode = HttpStatus.ok;
  request.response.write(jsonEncode({'status': 'ok'}));
  request.response.close();
}

Future<void> _handleEcho(HttpRequest request) async {
  final body = await utf8.decoder.bind(request).join();
  dynamic decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    decoded = {'raw': body};
  }

  request.response.statusCode = HttpStatus.ok;
  request.response.write(jsonEncode({'echo': decoded}));
  await request.response.close();
}

void _serveStaticFile(HttpRequest request, String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    _notFound(request);
    return;
  }

  final ext = filePath.split('.').last.toLowerCase();
  final contentType = _contentTypeForExt(ext);
  request.response.headers.set('content-type', contentType);
  request.response.addStream(file.openRead()).whenComplete(() => request.response.close());
}

String _contentTypeForExt(String ext) {
  switch (ext) {
    case 'html':
      return 'text/html; charset=utf-8';
    case 'css':
      return 'text/css; charset=utf-8';
    case 'js':
      return 'application/javascript; charset=utf-8';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'svg':
      return 'image/svg+xml';
    case 'json':
      return 'application/json; charset=utf-8';
    default:
      return 'application/octet-stream';
  }
}

void _notFound(HttpRequest request) {
  request.response.statusCode = HttpStatus.notFound;
  request.response.write(jsonEncode({'error': 'Not found'}));
  request.response.close();
}

void _internalError(HttpRequest request, String message) {
  request.response.statusCode = HttpStatus.internalServerError;
  request.response.write(jsonEncode({'error': 'Internal server error', 'message': message}));
  request.response.close();
}
