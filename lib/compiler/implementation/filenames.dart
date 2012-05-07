// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('filenames');

#import('dart:io');
#import('dart:uri');

// TODO(ahe): This library should be replaced by a general
// path-munging library.
//
// See also:
// http://blogs.msdn.com/b/ie/archive/2006/12/06/file-uris-in-windows.aspx

String nativeToUriPath(String filename) {
  if (Platform.operatingSystem != 'windows') return filename;
  filename = filename.toLowerCase();
  filename = filename.replaceAll('\\', '/');
  if (filename.length > 2 && filename[1] == ':') {
    filename = "/$filename";
  }
  return filename;
}

String uriPathToNative(String path) {
  if (Platform.operatingSystem != 'windows') return path;
  path = path.toLowerCase();
  if (path.length > 3 && path[0] == '/' && path[2] == ':') {
    return path.substring(1).replaceAll('/', '\\');
  } else {
    return path.replaceAll('/', '\\');
  }
}

Uri getCurrentDirectory() {
  final String dir = nativeToUriPath(new File('.').fullPathSync());
  return new Uri(scheme: 'file', path: appendSlash(dir));
}

String appendSlash(String path) => path.endsWith('/') ? path : '$path/';
