// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Tools for loading and parsing platform-configuration files.
library platform_configuration;

import "dart:async";

import "package:charcode/ascii.dart";

import "../compiler_new.dart" as api;

/// Parses an Ini-like format.
///
/// Sections are initialized with a name enclosed in brackets.
/// Each section contain zero or more properties of the form "name:value".
/// Empty lines are ignored.
/// Lines starting with # are ignored.
/// Duplicate names are not allowed.
/// All keys and values will be passed through [String.trim].
///
/// If an error is found, a [FormatException] is thrown, using [sourceUri] in
/// the error message.
///
/// Example
/// ```
/// [a]
/// b:c
///
/// [d]
/// e:file:///tmp/bla
/// ```
/// Will parse to {"a": {"b":"c"}, "d": {"e": "file:///tmp/bla"}}.

Map<String, Map<String, String>> parseIni(List<int> source,
    {Set<String> allowedSections, Uri sourceUri}) {
  int startOfLine = 0;
  int currentLine = 0;

  error(String message, int index) {
    int column = index - startOfLine + 1;
    throw new FormatException(
        "$sourceUri:$currentLine:$column: $message", sourceUri, index);
  }

  Map<String, Map<String, String>> result =
      new Map<String, Map<String, String>>();
  Map<String, String> currentSection = null;

  if (source.length == 0) return result;
  bool endOfFile = false;

  // Iterate once per $lf in file.
  while (!endOfFile) {
    currentLine += 1;
    int endOfLine = source.indexOf($lf, startOfLine);
    if (endOfLine == -1) {
      // The dart2js provider adds a final 0 to the file.
      endOfLine = source.last == 0 ? source.length - 1 : source.length;
      endOfFile = true;
    }
    if (startOfLine != endOfLine) {
      int firstChar = source[startOfLine];
      if (firstChar == $hash) {
        // Comment, do nothing.
      } else if (firstChar == $open_bracket) {
        // Section header
        int endOfHeader = source.indexOf($close_bracket, startOfLine);
        if (endOfHeader == -1) {
          error("'[' must be matched by ']' on the same line.", startOfLine);
        }
        if (endOfHeader == startOfLine + 1) {
          error("Empty header name", startOfLine + 1);
        }
        if (endOfHeader != endOfLine - 1) {
          error("Section heading lines must end with ']'", endOfHeader + 1);
        }
        int startOfSectionName = startOfLine + 1;
        String sectionName =
            new String.fromCharCodes(source, startOfSectionName, endOfHeader)
                .trim();
        currentSection = new Map<String, String>();
        if (result.containsKey(sectionName)) {
          error("Duplicate section name '$sectionName'", startOfSectionName);
        }
        if (allowedSections != null && !allowedSections.contains(sectionName)) {
          error("Unrecognized section name '$sectionName'", startOfSectionName);
        }
        result[sectionName] = currentSection;
      } else {
        // Property line
        if (currentSection == null) {
          error("Property outside section", startOfLine);
        }
        int separator = source.indexOf($colon, startOfLine);
        if (separator == startOfLine) {
          error("Empty property name", startOfLine);
        }
        if (separator == -1 || separator > endOfLine) {
          error("Property line without ':'", startOfLine);
        }
        String propertyName =
            new String.fromCharCodes(source, startOfLine, separator).trim();
        if (currentSection.containsKey(propertyName)) {
          error("Duplicate property name '$propertyName'", startOfLine);
        }
        String propertyValue =
            new String.fromCharCodes(source, separator + 1, endOfLine).trim();
        currentSection[propertyName] = propertyValue;
      }
    }
    startOfLine = endOfLine + 1;
  }
  return result;
}

const String librariesSection = "libraries";
const String dartSpecSection = "dart-spec";
const String featuresSection = "features";

Map<String, Uri> libraryMappings(
    Map<String, Map<String, String>> sections, Uri baseLocation) {
  assert(sections.containsKey(librariesSection));
  Map<String, Uri> result = new Map<String, Uri>();
  sections[librariesSection].forEach((String name, String value) {
    result[name] = baseLocation.resolve(value);
  });
  return result;
}

final Set<String> allowedSections =
    new Set.from([librariesSection, dartSpecSection, featuresSection]);

Future<Map<String, Uri>> load(Uri location, api.CompilerInput provider) {
  return provider
      .readFromUri(location, inputKind: api.InputKind.binary)
      .then((api.Input input) {
    return libraryMappings(
        parseIni(input.data,
            allowedSections: allowedSections, sourceUri: location),
        location);
  });
}
