// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.mdn;

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

// TODO(janicejl): Make MDN content generic or pluggable.

/// Map of all the comments for dom elements from MDN.
Map<String, dynamic> _mdn;

/// Generates MDN comments from database.json.
String mdnComment(String root, Logger logger, String domName) {
  //Check if MDN is loaded.
  if (_mdn == null) {
    // Reading in MDN related json file.
    var mdnPath = p.join(root, 'utils/apidoc/mdn/database.json');
    var mdnFile = new File(mdnPath);
    if (mdnFile.existsSync()) {
      _mdn = JSON.decode(mdnFile.readAsStringSync());
    } else {
      logger.warning("Cannot find MDN docs expected at $mdnPath");
      _mdn = {};
    }
  }

  var parts = domName.split('.');
  if (parts.length == 2) return _mdnMemberComment(parts[0], parts[1]);
  if (parts.length == 1) return _mdnTypeComment(parts[0]);

  throw new StateError('More than two items is not supported: $parts');
}

/// Generates the MDN Comment for variables and method DOM elements.
String _mdnMemberComment(String type, String member) {
  var mdnType = _mdn[type];
  if (mdnType == null) return '';
  var mdnMember = mdnType['members'].firstWhere((e) => e['name'] == member,
      orElse: () => null);
  if (mdnMember == null) return '';
  if (mdnMember['help'] == null || mdnMember['help'] == '') return '';
  if (mdnMember['url'] == null) return '';
  return _htmlifyMdn(mdnMember['help'], mdnMember['url']);
}

/// Generates the MDN Comment for class DOM elements.
String _mdnTypeComment(String type) {
  var mdnType = _mdn[type];
  if (mdnType == null) return '';
  if (mdnType['summary'] == null || mdnType['summary'] == "") return '';
  if (mdnType['srcUrl'] == null) return '';
  return _htmlifyMdn(mdnType['summary'], mdnType['srcUrl']);
}

/// Encloses the given content in an MDN div and the original source link.
String _htmlifyMdn(String content, String url) {
  return '<div class="mdn">' + content.trim() + '<p class="mdn-note">'
      '<a href="' + url.trim() + '">from Mdn</a></p></div>';
}
