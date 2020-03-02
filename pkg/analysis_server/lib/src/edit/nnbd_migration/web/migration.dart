// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

import 'package:path/path.dart' as _p;

import 'highlight_js.dart';

// TODO(devoncarew): Fix the issue where we can't load source maps.

// TODO(devoncarew): Include a favicon.

void main() {
  document.addEventListener('DOMContentLoaded', (event) {
    String path = window.location.pathname;
    int offset = getOffset(window.location.href);
    int lineNumber = getLine(window.location.href);
    loadNavigationTree();
    if (path != '/' && path != rootPath) {
      // TODO(srawlins): replaceState?
      loadFile(path, offset, lineNumber, callback: () {
        pushState(path, offset, lineNumber);
      });
    }
  });

  window.addEventListener('popstate', (event) {
    String path = window.location.pathname;
    int offset = getOffset(window.location.href);
    int lineNumber = getLine(window.location.href);
    if (path.length > 1) {
      loadFile(path, offset, lineNumber);
    } else {
      // Blank out the page, for the index screen.
      writeCodeAndRegions(path, {
        'regions': '',
        'navigationContent': '',
        'edits': [],
      });
      updatePage('&nbsp;', null);
    }
  });
}

String get rootPath => querySelector('.root').text.trim();

/// Return the absolute path of [path], assuming [path] is relative to [root].
String absolutePath(String path) {
  if (path[0] != '/') {
    return '$rootPath/$path';
  } else {
    return path;
  }
}

void addArrowClickHandler(Element arrow) {
  Element childList =
      (arrow.parentNode as Element).querySelector(':scope > ul');
  // Animating height from "auto" to "0" is not supported by CSS [1], so all we
  // have are hacks. The `* 2` allows for events in which the list grows in
  // height when resized, with additional text wrapping.
  // [1] https://css-tricks.com/using-css-transitions-auto-dimensions/
  childList.style.maxHeight = '${childList.offsetHeight * 2}px';
  arrow.onClick.listen((MouseEvent event) {
    if (!childList.classes.contains('collapsed')) {
      childList.classes.add('collapsed');
      arrow.classes.add('collapsed');
    } else {
      childList.classes.remove('collapsed');
      arrow.classes.remove('collapsed');
    }
  });
}

void addClickHandlers(String selector) {
  Element parentElement = document.querySelector(selector);

  // Add navigation handlers for navigation links in the source code.
  List<Element> navLinks = parentElement.querySelectorAll('.nav-link');
  navLinks.forEach((link) {
    link.onClick.listen((event) {
      Element tableElement = document.querySelector('table[data-path]');
      String parentPath = tableElement.dataset['path'];
      handleNavLinkClick(event, relativeTo: parentPath);
    });
  });

  List<Element> regions = parentElement.querySelectorAll('.region');
  if (regions.isNotEmpty) {
    Element table = parentElement.querySelector('table[data-path]');
    String path = table.dataset['path'];
    regions.forEach((Element anchor) {
      anchor.onClick.listen((event) {
        int offset = int.parse(anchor.dataset['offset']);
        loadAndPopulateEditDetails(path, offset);
      });
    });
  }

  List<Element> postLinks = parentElement.querySelectorAll('.post-link');
  postLinks.forEach((link) {
    link.onClick.listen(handlePostLinkClick);
  });
}

int getLine(String location) {
  String str = Uri.parse(location).queryParameters['line'];
  return str == null ? null : int.tryParse(str);
}

int getOffset(String location) {
  String str = Uri.parse(location).queryParameters['offset'];
  return str == null ? null : int.tryParse(str);
}

void handleNavLinkClick(
  MouseEvent event, {
  String relativeTo,
}) {
  Element target = event.currentTarget;

  String location = target.getAttribute('href');
  String path = location;
  if (path.contains('?')) {
    path = path.substring(0, path.indexOf('?'));
  }
  // Fix-up the path - it might be relative.
  if (relativeTo != null) {
    path = _p.normalize(_p.join(_p.dirname(relativeTo), path));
  }

  int offset = getOffset(location);
  int lineNumber = getLine(location);

  if (offset != null) {
    navigate(path, offset, lineNumber, callback: () {
      pushState(path, offset, lineNumber);
    });
  } else {
    navigate(path, null, null, callback: () {
      pushState(path, null, null);
    });
  }
  event.preventDefault();
}

void handlePostLinkClick(MouseEvent event) {
  String path = (event.currentTarget as Element).getAttribute('href');
  // TODO(devoncarew): Validate that this path logic is correct.
  // This is only called by .post-link elements - the 'edits' / incremental
  // workflow code path.
  path = absolutePath(path);

  // Directing the server to produce an edit; request it, then do work with the
  // response.
  HttpRequest.request(
    path,
    method: 'POST',
    requestHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
  ).then((HttpRequest xhr) {
    if (xhr.status == 200) {
      // Likely request new navigation and file content.
    } else {
      window.alert('Request failed; status of ${xhr.status}');
    }
  }).catchError((e, st) {
    logError('handlePostLinkClick: $e', st);

    window.alert('Could not load $path ($e).');
  });
}

void highlightAllCode() {
  document.querySelectorAll('.code').forEach((Element block) {
    hljs.highlightBlock(block);
  });
}

/// Load the explanation for [region], into the ".panel-content" div.
void loadAndPopulateEditDetails(String path, int offset) {
  // Request the region, then do work with the response.
  HttpRequest.request(
    '$path?region=region&offset=$offset',
    requestHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
  ).then((HttpRequest xhr) {
    if (xhr.status == 200) {
      // TODO(devoncarew): Parse this response into an object model (see
      // RegionRenderer for the schema).
      Map<String, dynamic> response = jsonDecode(xhr.responseText);
      populateEditDetails(response);
      addClickHandlers('.edit-panel .panel-content');
    } else {
      window.alert('Request failed; status of ${xhr.status}');
    }
  }).catchError((e, st) {
    logError('loadRegionExplanation: $e', st);

    window.alert('Could not load $path ($e).');
  });
}

/// Load the file at [path] from the server, optionally scrolling [offset] into
/// view.
void loadFile(
  String path,
  int offset,
  int line, {
  VoidCallback callback,
}) {
  // Handle the case where we're requesting a directory.
  if (!path.endsWith('.dart')) {
    writeCodeAndRegions(path, {
      'regions': '',
      'navigationContent': '',
      'edits': [],
    });
    updatePage(path);
    if (callback != null) {
      callback();
    }

    return;
  }

  // Navigating to another file; request it, then do work with the response.
  HttpRequest.request(
    path.contains('?') ? '$path&inline=true' : '$path?inline=true',
    requestHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
  ).then((HttpRequest xhr) {
    if (xhr.status == 200) {
      Map<String, dynamic> response = jsonDecode(xhr.responseText);
      writeCodeAndRegions(path, response);
      maybeScrollToAndHighlight(offset, line);
      String filePathPart =
          path.contains('?') ? path.substring(0, path.indexOf('?')) : path;
      updatePage(filePathPart, offset);
      if (callback != null) {
        callback();
      }
    } else {
      window.alert('Request failed; status of ${xhr.status}');
    }
  }).catchError((e, st) {
    logError('loadFile: $e', st);

    window.alert('Could not load $path ($e).');
  });
}

/// Load the navigation tree into the ".nav-tree" div.
void loadNavigationTree() {
  String path = '/_preview/navigationTree.json';

  // Request the navigation tree, then do work with the response.
  HttpRequest.request(
    path,
    requestHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
  ).then((HttpRequest xhr) {
    if (xhr.status == 200) {
      dynamic response = jsonDecode(xhr.responseText);
      var navTree = document.querySelector('.nav-tree');
      navTree.innerHtml = '';
      writeNavigationSubtree(navTree, response);
    } else {
      window.alert('Request failed; status of ${xhr.status}');
    }
  }).catchError((e, st) {
    logError('loadNavigationTree: $e', st);

    window.alert('Could not load $path ($e).');
  });
}

void logError(e, st) {
  window.console.error('$e');
  window.console.error('$st');
}

void maybeScrollIntoView(Element element) {
  Rectangle rect = element.getBoundingClientRect();
  if (rect.bottom > window.innerHeight) {
    element.scrollIntoView();
  } else if (rect.top < 0) {
    element.scrollIntoView();
  }
}

/// Scroll target with id [offset] into view if it is not currently in view.
///
/// If [offset] is null, instead scroll the "unit-name" header, at the top of the
/// page, into view.
///
/// Also add the "target" class, highlighting the target. Also add the
/// "highlight" class to the entire line on which the target lies.
void maybeScrollToAndHighlight(int offset, int lineNumber) {
  Element target;
  Element line;

  if (offset != null) {
    target = document.getElementById('o$offset');
    line = document.querySelector('.line-$lineNumber');
    if (target != null) {
      maybeScrollIntoView(target);
      target.classes.add('target');
    } else if (line != null) {
      // If the target doesn't exist, but the line does, scroll that into view
      // instead.
      maybeScrollIntoView(line.parent);
    }
    if (line != null) {
      (line.parentNode as Element).classes.add('highlight');
    }
  } else {
    // If no offset is given, this is likely a navigation link, and we need to
    // scroll back to the top of the page.
    target = document.getElementById('unit-name');
    maybeScrollIntoView(target);
  }
}

/// Navigate to [path] and optionally scroll [offset] into view.
///
/// If [callback] is present, it will be called after the server response has
/// been processed, and the content has been updated on the page.
void navigate(
  String path,
  int offset,
  int lineNumber, {
  VoidCallback callback,
}) {
  int currentOffset = getOffset(window.location.href);
  int currentLineNumber = getLine(window.location.href);
  removeHighlight(currentOffset, currentLineNumber);
  if (path == window.location.pathname) {
    // Navigating to same file; just scroll into view.
    maybeScrollToAndHighlight(offset, lineNumber);
    if (callback != null) {
      callback();
    }
  } else {
    loadFile(path, offset, lineNumber, callback: callback);
  }
}

String pluralize(int count, String single, {String multiple}) {
  return count == 1 ? single : (multiple ?? '${single}s');
}

void populateEditDetails([Map<String, dynamic> response]) {
  var editPanel = document.querySelector('.edit-panel .panel-content');
  editPanel.innerHtml = '';

  if (response == null) {
    // Clear out any current edit details.
    editPanel.append(ParagraphElement()
      ..text = 'See details about a proposed edit.'
      ..classes = ['placeholder']);
    return;
  }

  String filePath = response['path'];
  String parentDirectory = _p.dirname(filePath);

  // 'Changed ... at foo.dart:12.'
  String explanationMessage = response['explanation'];
  String relPath = _p.relative(filePath, from: rootPath);
  int line = response['line'];
  Element explanation = editPanel.append(document.createElement('p'));
  explanation.append(Text('$explanationMessage at $relPath:$line.'));
  int detailCount = response['details'].length;
  if (detailCount == 0) {
    // Having 0 details is not necessarily an expected possibility, but handling
    // the possibility prevents awkward text, "for 0 reasons:".
  } else {
    editPanel.append(ParagraphElement()..text = 'Edit rationale:');

    Element detailList = editPanel.append(document.createElement('ul'));
    for (var detail in response['details']) {
      var detailItem = detailList.append(document.createElement('li'));
      detailItem.append(Text(detail['description']));
      if (detail['link'] != null) {
        int targetLine = detail['link']['line'];

        detailItem.append(Text(' ('));
        AnchorElement a = detailItem.append(document.createElement('a'));
        a.append(Text("${detail['link']['text']}:$targetLine"));

        String relLink = detail['link']['href'];
        String fullPath = _p.normalize(_p.join(parentDirectory, relLink));

        a.setAttribute('href', fullPath);
        a.classes.add('nav-link');
        detailItem.append(Text(')'));
      }
    }
  }

  if (response['edits'] != null) {
    for (var edit in response['edits']) {
      Element editParagraph = editPanel.append(document.createElement('p'));
      Element a = editParagraph.append(document.createElement('a'));
      a.append(Text(edit['text']));
      a.setAttribute('href', edit['href']);
      a.classes.add('post-link');
    }
  }
}

/// Write the contents of the Edit List, from JSON data [editListData].
void populateProposedEdits(String path, List<dynamic> edits) {
  Element editListElement = document.querySelector('.edit-list .panel-content');
  editListElement.innerHtml = '';

  Element p = editListElement.append(document.createElement('p'));
  int editCount = edits.length;
  if (editCount == 0) {
    p.append(Text('No proposed edits'));
  } else {
    p.append(Text('$editCount proposed ${pluralize(editCount, 'edit')}:'));
  }

  Element list = editListElement.append(document.createElement('ul'));
  for (Map<String, dynamic> edit in edits) {
    Element item = list.append(document.createElement('li'));
    item.classes.add('edit');
    AnchorElement anchor = item.append(document.createElement('a'));
    anchor.classes.add('edit-link');
    int offset = edit['offset'];
    anchor.dataset['offset'] = '$offset';
    int line = edit['line'];
    anchor.dataset['line'] = '$line';
    anchor.append(Text('line $line'));
    anchor.onClick.listen((MouseEvent event) {
      navigate(window.location.pathname, offset, line, callback: () {
        pushState(window.location.pathname, offset, line);
      });
      loadAndPopulateEditDetails(path, offset);
    });
    item.append(Text(': ${edit['explanation']}'));
  }

  // Clear out any existing edit details.
  populateEditDetails();
}

void pushState(String path, int offset, int line) {
  Uri uri = Uri.parse('${window.location.origin}$path');

  Map<String, dynamic> params = {};
  if (offset != null) params['offset'] = '$offset';
  if (line != null) params['line'] = '$line';

  uri = uri.replace(queryParameters: params.isEmpty ? null : params);
  window.history.pushState({}, '', uri.toString());
}

/// If [path] lies within [root], return the relative path of [path] from [root].
/// Otherwise, return [path].
String relativePath(String path) {
  var root = querySelector('.root').text + '/';
  if (path.startsWith(root)) {
    return path.substring(root.length);
  } else {
    return path;
  }
}

/// Remove highlighting from [offset].
void removeHighlight(int offset, int lineNumber) {
  if (offset != null) {
    var anchor = document.getElementById('o$offset');
    if (anchor != null) {
      anchor.classes.remove('target');
    }
  }
  if (lineNumber != null) {
    var line = document.querySelector('.line-$lineNumber');
    if (line != null) {
      line.parent.classes.remove('highlight');
    }
  }
}

/// Update the heading and navigation links.
///
/// Call this after updating page content on a navigation.
void updatePage(String path, [int offset]) {
  path = relativePath(path);
  // Update page heading.
  Element unitName = document.querySelector('#unit-name');
  unitName.text = path;
  // Update navigation styles.
  document.querySelectorAll('.nav-panel .nav-link').forEach((Element link) {
    var name = link.dataset['name'];
    if (name == path) {
      link.classes.add('selected-file');
    } else {
      link.classes.remove('selected-file');
    }
  });
}

/// Load data from [data] into the .code and the .regions divs.
void writeCodeAndRegions(String path, Map<String, dynamic> data) {
  Element regionsElement = document.querySelector('.regions');
  Element codeElement = document.querySelector('.code');

  _PermissiveNodeValidator.setInnerHtml(regionsElement, data['regions']);
  _PermissiveNodeValidator.setInnerHtml(codeElement, data['navigationContent']);
  populateProposedEdits(path, data['edits']);

  highlightAllCode();
  addClickHandlers('.code');
  addClickHandlers('.regions');
}

void writeNavigationSubtree(Element parentElement, dynamic tree) {
  Element ul = parentElement.append(document.createElement('ul'));
  for (var entity in tree) {
    Element li = ul.append(document.createElement('li'));
    if (entity['type'] == 'directory') {
      li.classes.add('dir');
      Element arrow = li.append(document.createElement('span'));
      arrow.classes.add('arrow');
      arrow.innerHtml = '&#x25BC;';
      Element icon = li.append(document.createElement('span'));
      icon.innerHtml = '&#x1F4C1;';
      li.append(Text(entity['name']));
      writeNavigationSubtree(li, entity['subtree']);
      addArrowClickHandler(arrow);
    } else {
      li.innerHtml = '&#x1F4C4;';
      Element a = li.append(document.createElement('a'));
      a.classes.add('nav-link');
      a.dataset['name'] = entity['path'];
      a.setAttribute('href', entity['href']);
      a.append(Text(entity['name']));
      a.onClick.listen(handleNavLinkClick);
      int editCount = entity['editCount'];
      if (editCount > 0) {
        Element editsBadge = li.append(document.createElement('span'));
        editsBadge.classes.add('edit-count');
        editsBadge.setAttribute(
            'title', '$editCount ${pluralize(editCount, 'edit')}');
        editsBadge.append(Text(editCount.toString()));
      }
    }
  }
}

class _PermissiveNodeValidator implements NodeValidator {
  static _PermissiveNodeValidator instance = _PermissiveNodeValidator();

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    return true;
  }

  @override
  bool allowsElement(Element element) {
    return true;
  }

  static void setInnerHtml(Element element, String html) {
    element.setInnerHtml(html, validator: instance);
  }
}
