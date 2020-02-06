// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

import 'package:path/path.dart' as _p;

import 'highlight_js.dart';

// TODO(devoncarew): Fix the issue where we can't load source maps.

// TODO(devoncarew): Include a favicon.

String get rootPath => querySelector('.root').text.trim();

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
    var path = window.location.pathname;
    int offset = getOffset(window.location.href);
    var lineNumber = getLine(window.location.href);
    if (path.length > 1) {
      loadFile(path, offset, lineNumber);
    } else {
      // Blank out the page, for the index screen.
      writeCodeAndRegions({'regions': '', 'navContent': ''});
      updatePage('&nbsp;', null);
    }
  });
}

int getOffset(String location) {
  String str = Uri.parse(location).queryParameters['offset'];
  return str == null ? null : int.tryParse(str);
}

int getLine(String location) {
  String str = Uri.parse(location).queryParameters['line'];
  return str == null ? null : int.tryParse(str);
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

/// Return the absolute path of [path], assuming [path] is relative to [root].
String absolutePath(String path) {
  if (path[0] != '/') {
    return '$rootPath/$path';
  } else {
    return path;
  }
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

/// Write the contents of the Edit List, from JSON data [editListData].
void writeEditList(dynamic editListData) {
  var editList = document.querySelector('.edit-list .panel-content');
  editList.innerHtml = '';
  var p = editList.append(document.createElement('p'));
  var countElement = p.append(document.createElement('strong'));
  int editCount = editListData['editCount'];
  countElement.append(Text(editCount.toString()));
  if (editCount == 1) {
    p.append(
        Text(" edit was made to this file. Click the edit's checkbox to toggle "
            'its reviewed state.'));
  } else {
    p.append(Text(
        " edits were made to this file. Click an edit's checkbox to toggle "
        'its reviewed state.'));
  }

  for (var edit in editListData['edits']) {
    ParagraphElement editP = editList.append(document.createElement('p'));
    editP.classes.add('edit');
    Element checkbox = editP.append(document.createElement('input'));
    checkbox.setAttribute('type', 'checkbox');
    checkbox.setAttribute('title', 'Click to mark reviewed');
    checkbox.setAttribute('disabled', 'disabled');
    editP.append(Text('line ${edit["line"]}: ${edit["explanation"]}.'));
    AnchorElement a = editP.append(document.createElement('a'));
    a.classes.add('edit-link');
    int offset = edit['offset'];
    a.dataset['offset'] = '$offset';
    int line = edit['line'];
    a.dataset['line'] = '$line';
    a.append(Text(' [view]'));
    a.onClick.listen((MouseEvent event) {
      navigate(window.location.pathname, offset, line, callback: () {
        pushState(window.location.pathname, offset, line);
      });
      loadRegionExplanation(a);
    });
  }
}

/// Load data from [data] into the .code and the .regions divs.
void writeCodeAndRegions(dynamic data) {
  var regions = document.querySelector('.regions');
  var code = document.querySelector('.code');
  _PermissiveNodeValidator.setInnerHtml(regions, data['regions']);
  _PermissiveNodeValidator.setInnerHtml(code, data['navContent']);
  writeEditList(data['editList']);
  highlightAllCode();
  addClickHandlers('.code');
  addClickHandlers('.regions');
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
      maybeScrollIntoView(line);
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

/// Load the file at [path] from the server, optionally scrolling [offset] into
/// view.
void loadFile(
  String path,
  int offset,
  int lineNumber, {
  VoidCallback callback,
}) {
  // Navigating to another file; request it, then do work with the response.
  HttpRequest.request(
    path.contains('?') ? '$path&inline=true' : '$path?inline=true',
    requestHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
  ).then((HttpRequest xhr) {
    if (xhr.status == 200) {
      var response = jsonDecode(xhr.responseText);
      writeCodeAndRegions(response);
      maybeScrollToAndHighlight(offset, lineNumber);
      updatePage(path, offset);
      if (callback != null) {
        callback();
      }
    } else {
      window.alert('Request failed; status of ${xhr.status}');
    }
  }).catchError((e, st) {
    logError('loadFile: $e', st);

    window.alert('Could not load $path; preview server might be disconnected.');
  });
}

void pushState(String path, int offset, int lineNumber) {
  var newLocation = window.location.origin + path + '?';
  if (offset != null) {
    newLocation = newLocation + 'offset=$offset&';
  }
  if (lineNumber != null) {
    newLocation = newLocation + 'line=$lineNumber';
  }
  window.history.pushState({}, '', newLocation);
}

/// Update the heading and navigation links.
///
/// Call this after updating page content on a navigation.
void updatePage(String path, int offset) {
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

void highlightAllCode() {
  document.querySelectorAll('.code').forEach((Element block) {
    hljs.highlightBlock(block);
  });
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

void handleNavLinkClick(MouseEvent event) {
  Element target = event.currentTarget;

  var path = absolutePath(target.getAttribute('href'));
  int offset = getOffset(target.getAttribute('href'));
  int lineNumber = getLine(target.getAttribute('href'));

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

    window.alert('Could not load $path; preview server might be disconnected.');
  });
}

void addClickHandlers(String parentSelector) {
  Element parentElement = document.querySelector(parentSelector);

  var navLinks = parentElement.querySelectorAll('.nav-link');
  navLinks.forEach((link) {
    link.onClick.listen(handleNavLinkClick);
  });

  var regions = parentElement.querySelectorAll('.region');
  regions.forEach((Element region) {
    region.onClick.listen((event) {
      loadRegionExplanation(region);
    });
  });

  var postLinks = parentElement.querySelectorAll('.post-link');
  postLinks.forEach((link) {
    link.onClick.listen(handlePostLinkClick);
  });
}

void writeNavigationSubtree(Element parentElement, dynamic tree) {
  var ul = parentElement.append(document.createElement('ul'));
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
        var edits = editCount == 1 ? 'edit' : 'edits';
        editsBadge.setAttribute('title', '$editCount $edits');
        editsBadge.append(Text(editCount.toString()));
      }
    }
  }
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

    window.alert('Could not load $path; preview server might be disconnected.');
  });
}

void logError(e, st) {
  window.console.error('$e');
  window.console.error('$st');
}

void writeRegionExplanation(dynamic response) {
  var editPanel = document.querySelector('.edit-panel .panel-content');
  editPanel.innerHtml = '';
  var regionLocation = document.createElement('p');
  regionLocation.classes.add('region-location');

  String filePath = response['path'];
  String parentDirectory = _p.dirname(filePath);

  regionLocation.append(Text('$filePath '));
  Element regionLine = regionLocation.append(document.createElement('span'));
  regionLine.append(Text('line ${response['line']}'));
  regionLine.classes.add('nowrap');
  editPanel.append(regionLocation);
  var explanation = editPanel.append(document.createElement('p'));
  explanation.append(Text(response['explanation']));
  var detailCount = response['details'].length;
  if (detailCount == 0) {
    // Having 0 details is not necessarily an expected possibility, but handling
    // the possibility prevents awkward text, "for 0 reasons:".
    explanation.append(Text('.'));
  } else {
    explanation.append(Text(detailCount == 1
        ? ' for $detailCount reason:'
        : ' for $detailCount reasons:'));

    var detailList = editPanel.append(document.createElement('ol'));
    for (var detail in response['details']) {
      var detailItem = detailList.append(document.createElement('li'));
      detailItem.append(Text(detail['description']));
      if (detail['link'] != null) {
        detailItem.append(Text(' ('));
        AnchorElement a = detailItem.append(document.createElement('a'));
        a.append(Text(detail['link']['text']));

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

/// Load the explanation for [region], into the ".panel-content" div.
void loadRegionExplanation(Element region) {
  String path = window.location.pathname;
  String offset = region.dataset['offset'];

  // Request the region, then do work with the response.
  HttpRequest.request(
    '$path?region=region&offset=$offset',
    requestHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
  ).then((HttpRequest xhr) {
    if (xhr.status == 200) {
      var response = jsonDecode(xhr.responseText);
      writeRegionExplanation(response);
      addClickHandlers('.edit-panel .panel-content');
    } else {
      window.alert('Request failed; status of ${xhr.status}');
    }
  }).catchError((e, st) {
    logError('loadRegionExplanation: $e', st);

    window.alert('Could not load $path; preview server might be disconnected.');
  });
}

class _PermissiveNodeValidator implements NodeValidator {
  static _PermissiveNodeValidator instance = _PermissiveNodeValidator();

  static void setInnerHtml(Element element, String html) {
    element.setInnerHtml(html, validator: instance);
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    return true;
  }

  @override
  bool allowsElement(Element element) {
    return true;
  }
}
