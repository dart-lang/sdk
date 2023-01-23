#!/usr/bin/env python3
#
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Generates CssStyleDeclaration extension with all property getters and setters
from css property definitions defined in WebKit."""

import tempfile, os, re

COMMENT_LINE_PREFIX = '   * '
SOURCE_PATH = 'CSSPropertyNames.in'
OUTPUT_FILE = 'prototype_css_properties.dart'

# These are the properties that are supported on all Dart project supported
# browsers as camelCased names on the CssStyleDeclaration.
# Note that we do not use the MDN for compatibility info here.
BROWSER_PATHS = [
    'cssProperties.CSS21.txt',  # Remove when we have samples from all browsers.
    'cssProperties.ie9.txt',
    'cssProperties.ie10.txt',
    'cssProperties.ie11.txt',
    'cssProperties.ff36.txt',
    'cssProperties.chrome40.txt',
    'cssProperties.safari-7.1.3.txt',
    'cssProperties.mobileSafari-8.2.txt',
    'cssProperties.iPad4Air.onGoogleSites.txt',
]

# Supported annotations for any specific CSS properties.
annotated = {
    'transition':
    '''
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)'''
}


class Error:

    def __init__(self, message):
        self.message = message

    def __repr__(self):
        return self.message


def camelCaseName(name):
    """Convert a CSS property name to a lowerCamelCase name."""
    name = name.replace('-webkit-', '')
    words = []
    for word in name.split('-'):
        if words:
            words.append(word.title())
        else:
            words.append(word)
    return ''.join(words)


def dashifyName(camelName):

    def fix(match):
        return '-' + match.group(0).lower()

    return re.sub(r'[A-Z]', fix, camelName)


def isCommentLine(line):
    return line.strip() == '' or line.startswith('#') or line.startswith('//')


def readCssProperties(filename):
    data = open(filename).readlines()
    data = sorted([d.strip() for d in set(data) if not isCommentLine(d)])
    return data


def main():
    data = open(SOURCE_PATH).readlines()
    data = [d.strip() for d in data if not isCommentLine(d) and not '=' in d]

    browser_props = [set(readCssProperties(file)) for file in BROWSER_PATHS]
    universal_properties = set.intersection(*browser_props)
    universal_properties = universal_properties.difference(['cssText'])
    universal_properties = universal_properties.intersection(
        list(map(camelCaseName, data)))

    output_file = open(OUTPUT_FILE, 'w')
    output_file.write("""
/// Exposing all the extra CSS property getters and setters.
@JS()
library dart.css_properties;

import 'dart:_js_annotations';
import 'dart:_js_bindings' as js_bindings;
import 'dart:html_common';

@JS()
@staticInterop
class CssStyleDeclaration implements js_bindings.CSSStyleDeclaration {}

extension CssStyleDeclarationView on CssStyleDeclaration {
  // dart:html requires a `String?` type for `value`.
  external Object setProperty(String property, String? value,
      [String? priority = '']);

  // ##### Universal property getters and setters #####
  """)

    for camelName in sorted(universal_properties):
        property = dashifyName(camelName)
        output_file.write("""
  /** Gets the value of "%s" */
  String get %s => this._%s;

  /** Sets the value of "%s" */
  set %s(String? value) {
    _%s = value == null ? '' : value;
  }

  @JS('%s')
  external String get _%s;

  @JS('%s')
  external set _%s(String value);
    """ % (property, camelName, camelName, property, camelName, camelName,
           camelName, camelName, camelName, camelName))

    output_file.write("""

  // ##### Non-universal property getters and setters #####

""")

    property_lines = []

    seen = set()
    for prop in sorted(data, key=camelCaseName):
        camel_case_name = camelCaseName(prop)
        upper_camel_case_name = camel_case_name[0].upper() + camel_case_name[1:]
        css_name = prop.replace('-webkit-', '')
        base_css_name = prop.replace('-webkit-', '')

        if base_css_name in seen or base_css_name.startswith(
                '-internal') or camel_case_name in universal_properties:
            continue
        seen.add(base_css_name)

        comment = '  /** %s the value of "' + base_css_name + '" */'
        property_lines.append('\n')
        property_lines.append(comment % 'Gets')
        if base_css_name in annotated:
            property_lines.append(annotated[base_css_name])
        property_lines.append("""
  String get %s =>
    getPropertyValue('%s');

""" % (camel_case_name, css_name))

        property_lines.append(comment % 'Sets')
        if base_css_name in annotated:
            property_lines.append(annotated[base_css_name])
        property_lines.append("""
  set %s(String value) {
    setProperty('%s', value, '');
  }
""" % (camel_case_name, css_name))

    output_file.write(''.join(property_lines))
    output_file.write('}\n')
    output_file.close()


if __name__ == '__main__':
    main()
