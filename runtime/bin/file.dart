// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface FileInputStream extends InputStream factory _FileInputStream {
  FileInputStream(File file);
}

interface FileOutputStream extends OutputStream factory _FileOutputStream {
  FileOutputStream(File file);
}

interface File factory _File {
  // Open a file.
  File(String name, bool writable);

  // Close the file.
  void close();

  // Synchronously read a single byte from the file.
  // TODO(jrgfogh): Remove this call.
  int readByte();

  // Synchronously write a single byte to the file.
  // TODO(jrgfogh): Remove this call.
  int writeByte(int value);

  // Synchronously write a single string to the file.
  // TODO(jrgfogh): Remove this call.
  int writeString(String string);

  // Synchronously read a List<int> from the file.
  // TODO(jrgfogh): Remove this call.
  int readList(List<int> buffer, int offset, int bytes);

  // Synchronously write a List<int> to the file.
  // TODO(jrgfogh): Remove this call.
  int writeList(List<int> buffer, int offset, int bytes);

  // The current position of the file handle.
  int get position();

  // The length of the file.
  int get length();

  // Flush the contents of the file to disk.
  void flush();

  // Each file has an unique InputStream.
  InputStream get inputStream();

  // Each file has an unique OutputStream.
  OutputStream get outputStream();
}


class FileUtil {
  static bool fileExists(String name) native "File_Exists";
}


class FileIOException implements Exception {
  const FileIOException([String this.message = ""]);
  String toString() => "FileIOException: $message";

  /*
   * Contains the exception message.
   */
  final String message;
}
