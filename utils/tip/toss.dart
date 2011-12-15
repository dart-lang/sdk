// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('../../frog/lib/node/node.dart');
#import('../../frog/file_system_node.dart');
#import('../../frog/lang.dart');

String compileDart(String basename, String filename) {
  final basedir = path.dirname(basename);
  final fullname = '$basedir/$filename';

  world.reset();
  options.dartScript = fullname;
  if (world.compile()) {
    return world.getGeneratedCode();
  } else {
    return 'alert("compilation of $filename failed, see console for errors");';
  }
}


String frogify(String filename) {
  final s = @'<script\s+type="application/dart"(?:\s+src="(\w+.dart)")?>([\s\S]*)</script>';

  final text = fs.readFileSync(filename, 'utf8');
  final re = new RegExp(s, true, false);
  var m = re.firstMatch(text);
  if (m === null) return text;

  var dname = m.group(1);
  var contents = m.group(2);

  print('compiling $dname');

  var compiled = compileDart(filename, dname);

  return text.substring(0, m.start()) +
    '<script type="application/javascript">${compiled}</script>' +
    text.substring(m.start() + m.group(0).length);
}

void initializeCompiler(String homedir) {
  final filesystem = new NodeFileSystem();

  parseOptions(homedir, [null, null], filesystem);
  initializeWorld(filesystem);
}

String dirToHtml(String url, String dirname) {
  var names = new StringBuffer();
  for (var name in fs.readdirSync(dirname)) {
    var link = '$url/$name';
    names.add('<li><a href=$link>$name</a></li>\n');
  }

  return '''
  <html><head><title>$dirname</title></head>
    <h3>$dirname</h3>
    <ul>
      $names
    </ul>
  </html>
  ''';
}


void main() {
  final homedir = path.dirname(fs.realpathSync(process.argv[1]));
  final dartdir = path.dirname(homedir);
  print('running with dart root at ${dartdir}');

  initializeCompiler(homedir);

  http.createServer((ServerRequest req, ServerResponse res) {
    var filename;
    if (req.url.endsWith('.html')) {
      res.setHeader('Content-Type', 'text/html');
    } else if (req.url.endsWith('.css')) {
      res.setHeader('Content-Type', 'text/css');
    } else if (req.url.endsWith('.svg')) {
      res.setHeader('Content-Type', 'image/svg+xml');
    } else {
      res.setHeader('Content-Type', 'text/plain');
    }

    filename = '$dartdir/${req.url}';

    if (path.existsSync(filename)) {
      var stat = fs.statSync(filename);
      if (stat.isFile()) {
        res.statusCode = 200;
        String data;
        if (filename.endsWith('.html')) {
          res.end(frogify(filename));
        } else {
          res.end(fs.readFileSync(filename, 'utf8'));
        }
        return;
      } else {
        res.setHeader('Content-Type', 'text/html');
        res.end(dirToHtml(req.url, filename));
      }
    }


    res.statusCode = 404;
    res.end('');
  }).listen(1337, "localhost");
  print('Server running at http://localhost:1337/');
}
