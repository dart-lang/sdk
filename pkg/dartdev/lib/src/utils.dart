// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

/// The directory used to store per-user settings for Dart tooling.
Directory getDartPrefsDirectory() {
  return Directory(path.join(getUserHomeDir(), '.dart'));
}

/// Return the user's home directory.
String getUserHomeDir() {
  String envKey = Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  String value = Platform.environment[envKey];
  return value == null ? '.' : value;
}

/// A typedef to represent a function taking no arguments and with no return
/// value.
typedef void VoidFunction();

final NumberFormat _numberFormat = NumberFormat.decimalPattern();

/// Whether today is April Fools' day.
bool get isAprilFools {
  var date = DateTime.now();
  return date.month == 4 && date.day == 1;
}

/// Convert the given number to a string using the current locale.
String formatNumber(int i) => _numberFormat.format(i);

/// Emit the given word with the correct pluralization.
String pluralize(String word, int count) => count == 1 ? word : '${word}s';

/// String utility to trim some suffix from the end of a [String].
String trimEnd(String s, String suffix) {
  if (s != null && suffix != null && suffix.isNotEmpty && s.endsWith(suffix)) {
    return s.substring(0, s.length - suffix.length);
  }
  return s;
}
