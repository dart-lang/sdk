// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/web/edit_details.dart';
import 'package:nnbd_migration/src/front_end/web/file_details.dart';
import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';
import 'package:path/path.dart' as _p;

import 'highlight_js.dart';

// TODO(devoncarew): Fix the issue where we can't load source maps.

// TODO(devoncarew): Include a favicon.

void main() {
  document.addEventListener('DOMContentLoaded', (event) {
    var path = window.location.pathname;
    var offset = getOffset(window.location.href);
    var lineNumber = getLine(window.location.href);
    loadNavigationTree();
    if (path != '/' && path != rootPath) {
      // TODO(srawlins): replaceState?
      loadFile(path, offset, lineNumber, true, callback: () {
        pushState(path, offset, lineNumber);
      });
    }

    final applyMigrationButton = document.querySelector('.apply-migration');
    applyMigrationButton.onClick.listen((event) {
      if (window.confirm(
          "This will apply the changes you've previewed to your working "
          'directory. It is recommended you commit any changes you made before '
          'doing this.')) {
        var navigationTreeJson = [
          for (var entity in navigationTree) entity.toJson()
        ];
        doPost('/apply-migration', {'navigationTree': navigationTreeJson})
            .then((xhr) {
          document.body.classes
            ..remove('proposed')
            ..add('applied');
        }).catchError((e, st) {
          handleError('Could not apply migration', e, st);
        });
      }
    });

    final rerunMigrationButton = document.querySelector('.rerun-migration');
    rerunMigrationButton.onClick.listen((event) async {
      try {
        document.body.classes..add('rerunning');
        var response = await doPost('/rerun-migration');
        if (response['success'] as bool) {
          window.location.reload();
        } else {
          handleRerunFailure(response['errors'] as List<Object>);
        }
      } catch (e, st) {
        handleError('Failed to rerun migration', e, st);
      } finally {
        document.body.classes.remove('rerunning');
      }
    });

    final reportProblemButton = document.querySelector('.report-problem');
    reportProblemButton.onClick.listen((_) {
      window.open(getGitHubProblemUri().toString(), 'report-problem');
    });

    document.querySelector('.popup-pane .close').onClick.listen(
        (_) => document.querySelector('.popup-pane').style.display = 'none');

    migrateUnitStatusIcon.onClick.listen((MouseEvent event) {
      var unitPath = unitName.innerText;
      var unitNavItem = document
          .querySelector('.nav-panel [data-name*="$unitPath"]')
          .parentNode as Element;
      var statusIcon = unitNavItem.querySelector('.status-icon');
      var entity = navigationTree.find(unitPath);
      if (entity is NavigationTreeFileNode) {
        toggleFileMigrationStatus(entity);
        updateIconsForNode(statusIcon, entity);
        updateParentIcons(unitNavItem, entity);
      }
    });
  });

  window.addEventListener('popstate', (event) {
    var path = window.location.pathname;
    var offset = getOffset(window.location.href);
    var lineNumber = getLine(window.location.href);
    if (path.length > 1) {
      loadFile(path, offset, lineNumber, false);
    } else {
      // Blank out the page, for the index screen.
      writeCodeAndRegions(path, FileDetails.empty(), true);
      updatePage('&nbsp;', null);
    }
  });
}

/// Returns the "authToken" query parameter value of the current location.
// TODO(srawlins): This feels a little fragile, as the user can accidentally
//  change/remove this text, and break their session. Normally auth tokens are
//  stored in cookies, but there is no authentication step during which the
//  server would attach such a token to cookies. We could do a little step where
//  the first request to the server with the token is considered
//  "authentication", and we subsequently store the token in cookies thereafter.
final String authToken =
    Uri.parse(window.location.href).queryParameters['authToken'];

final Element editListElement =
    document.querySelector('.edit-list .panel-content');

final Element editPanel = document.querySelector('.edit-panel .panel-content');

final Element footerPanel = document.querySelector('footer');

final Element headerPanel = document.querySelector('header');

final Element unitName = document.querySelector('#unit-name');

final Element migrateUnitStatusIconLabel =
    document.querySelector('#migrate-unit-status-icon-label');

final Element migrateUnitStatusIcon =
    document.querySelector('#migrate-unit-status-icon');

String get rootPath => querySelector('.root').text.trim();

String get sdkVersion => document.getElementById('sdk-version').text;

/*late final*/ List<NavigationTreeNode> navigationTree;

void addArrowClickHandler(Element arrow) {
  var childList = (arrow.parentNode as Element).querySelector(':scope > ul');
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

void addClickHandlers(String selector, bool clearEditDetails) {
  var parentElement = document.querySelector(selector);

  // Add navigation handlers for navigation links in the source code.
  List<Element> navLinks = parentElement.querySelectorAll('.nav-link');
  navLinks.forEach((link) {
    link.onClick.listen((event) {
      var tableElement = document.querySelector('table[data-path]');
      var parentPath = tableElement.dataset['path'];
      handleNavLinkClick(event, clearEditDetails, relativeTo: parentPath);
    });
  });

  List<Element> regions = parentElement.querySelectorAll('.region');
  if (regions.isNotEmpty) {
    var table = parentElement.querySelector('table[data-path]');
    var path = table.dataset['path'];
    regions.forEach((Element anchor) {
      anchor.onClick.listen((event) {
        var offset = int.parse(anchor.dataset['offset']);
        var line = int.parse(anchor.dataset['line']);
        loadAndPopulateEditDetails(path, offset, line);
      });
    });
  }

  List<Element> addHintLinks = parentElement.querySelectorAll('.add-hint-link');
  addHintLinks.forEach((link) {
    link.onClick.listen(handleAddHintLinkClick);
  });
}

/// Creates an icon using a `<span>` element and the Material Icons font.
Element createIcon([String name = '']) {
  return document.createElement('span')
    ..classes.add('material-icons')
    ..innerText = name;
}

/// Perform a GET request on the path, return the json decoded response.
///
/// Returns a T so that the various json objects can be requested (lists, maps,
/// etc.).
Future<T> doGet<T>(String path,
        {Map<String, String> queryParameters = const {}}) =>
    doRequest(HttpRequest()
      ..open('GET', pathWithQueryParameters(path, queryParameters), async: true)
      ..setRequestHeader('Content-Type', 'application/json; charset=UTF-8'));

/// Perform a POST request on the path, return the JSON-decoded response.
Future<Map<String, Object>> doPost(String path, [Object body]) => doRequest(
    HttpRequest()
      ..open('POST', pathWithQueryParameters(path, {}), async: true)
      ..setRequestHeader('Content-Type', 'application/json; charset=UTF-8'),
    body);

/// Execute the [HttpRequest], handle its error codes, and return or throw the
/// response.
///
/// This is preferable over helper methods on [HttpRequest] because they ignore
/// the response body on a non-200 code. We want to get that response body in
/// that case, though, because it may be an error response from the server with
/// useful debugging information (stack trace etc).
Future<T> doRequest<T>(HttpRequest xhr, [Object body]) async {
  var completer = Completer<HttpRequest>();
  xhr.onLoad.listen((e) {
    completer.complete(xhr);
  });

  xhr.onError.listen(completer.completeError);

  xhr.send(body == null ? null : jsonEncode(body));

  try {
    await completer.future;
  } catch (e, st) {
    // Handle refused connection and make it user-presentable.
    throw AsyncError('Error reaching migration preview server.', st);
  }

  final json = jsonDecode(xhr.responseText);
  if (xhr.status == 200) {
    // Request OK.
    return json as T;
  } else {
    throw json;
  }
}

/// Returns the URL of the "new issue" form for the SDK repository,
/// pre-populating the title, some labels, using [description], [exception], and
/// [stackTrace] in the body.
Uri getGitHubErrorUri(
        String description, Object exception, Object stackTrace) =>
    Uri.https('github.com', 'dart-lang/sdk/issues/new', {
      'title': 'Customer-reported issue with NNBD migration tool: $description',
      'labels': 'area-analyzer,analyzer-nnbd-migration,type-bug',
      'body': '''
$description

Error: $exception

Please fill in the following:

**Name of package being migrated (if public)**:
**What I was doing when this issue occurred**:
**Is it possible to work around this issue**:
**Has this issue happened before, and if so, how often**:
**Dart SDK version**: $sdkVersion
**Additional details**:

Thanks for filing!

Stacktrace: _auto populated by migration preview tool._

```
$stackTrace
```
''',
    });

/// Returns the URL of the "new issue" form for the SDK repository,
/// pre-populating some labels and a body template.
Uri getGitHubProblemUri() =>
    Uri.https('github.com', 'dart-lang/sdk/issues/new', {
      'title': 'Customer-reported issue with NNBD migration tool',
      'labels': 'area-analyzer,analyzer-nnbd-migration,type-bug',
      'body': '''
#### Steps to reproduce

#### What did you expect to happen?

#### What actually happened?

_Screenshots are appreciated_

**Dart SDK version**: $sdkVersion

Thanks for filing!
''',
    });

int getLine(String location) {
  var str = Uri.parse(location).queryParameters['line'];
  return str == null ? null : int.tryParse(str);
}

int getOffset(String location) {
  var str = Uri.parse(location).queryParameters['offset'];
  return str == null ? null : int.tryParse(str);
}

void handleAddHintLinkClick(MouseEvent event) async {
  var path = (event.currentTarget as Element).getAttribute('href');

  // Don't navigate on link click.
  event.preventDefault();

  try {
    var previousScrollPosition = _getCurrentScrollPosition();
    // Directing the server to produce an edit; request it, then do work with
    // the response.
    await doPost(path);
    await loadFile(window.location.pathname, null, null, false);
    _scrollContentTo(previousScrollPosition);
  } catch (e, st) {
    handleError('Could not add/remove hint', e, st);
  }
}

void handleError(String header, Object exception, Object stackTrace) {
  String subheader;
  if (exception is Map<String, Object> &&
      exception['success'] == false &&
      exception.containsKey('exception') &&
      exception.containsKey('stackTrace')) {
    subheader = exception['exception'] as String;
    stackTrace = exception['stackTrace'];
  } else {
    subheader = exception.toString();
  }
  final popupPane = document.querySelector('.popup-pane');
  popupPane.querySelector('h2').innerText = header;
  popupPane.querySelector('p').innerText = subheader;
  popupPane.querySelector('pre').innerText = stackTrace.toString();
  var bottom = popupPane.querySelector('a.bottom') as AnchorElement;
  bottom
    ..href = getGitHubErrorUri(header, subheader, stackTrace).toString()
    ..style.display = 'initial';
  popupPane..style.display = 'initial';
  logError('$header: $exception', stackTrace);
}

void handleNavLinkClick(
  MouseEvent event,
  bool clearEditDetails, {
  String relativeTo,
}) {
  Element target = event.currentTarget as Element;
  event.preventDefault();

  var location = target.getAttribute('href');
  var path = _stripQuery(location);

  var offset = getOffset(location);
  var lineNumber = getLine(location);

  if (offset != null) {
    navigate(path, offset, lineNumber, clearEditDetails, callback: () {
      pushState(path, offset, lineNumber);
    });
  } else {
    navigate(path, null, null, clearEditDetails, callback: () {
      pushState(path, null, null);
    });
  }
}

void handleRerunFailure(List<Object> errors) {
  final popupPane = document.querySelector('.popup-pane');
  popupPane.querySelector('h2').innerText = 'Failed to rerun from sources';
  popupPane.querySelector('p').innerText =
      'Sources contain static analysis errors:';
  popupPane.querySelector('pre').innerText = errors.cast<Map>().map((error) {
    return '${error['severity']} - ${error['message']} '
        'at ${error['location']} - (${error['code']})';
  }).join('\n');
  popupPane.querySelector('a.bottom').style.display = 'none';
  popupPane.style.display = 'initial';

  // TODO(srawlins): I think we should lock down the entire web UI, except for
  //  the "Rerun from source" button.
}

void highlightAllCode() {
  document.querySelectorAll('.code').forEach((Element block) {
    hljs.highlightBlock(block);
  });
}

/// Loads the explanation for [region], into the ".panel-content" div.
void loadAndPopulateEditDetails(String path, int offset, int line) async {
  try {
    final responseJson = await doGet<Map<String, Object>>(path,
        queryParameters: {'region': 'region', 'offset': '$offset'});
    var response = EditDetails.fromJson(responseJson);
    populateEditDetails(response);
    pushState(path, offset, line);
    addClickHandlers('.edit-panel .panel-content', false);
  } catch (e, st) {
    handleError('Could not load edit details', e, st);
  }
}

/// Loads the file at [path] from the server, optionally scrolling [offset] into
/// view.
Future<void> loadFile(
  String path,
  int offset,
  int line,
  bool clearEditDetails, {
  VoidCallback callback,
}) async {
  // Handle the case where we're requesting a directory.
  if (!path.endsWith('.dart')) {
    writeCodeAndRegions(path, FileDetails.empty(), clearEditDetails);
    updatePage(path);
    if (callback != null) {
      callback();
    }

    return;
  }

  try {
    // Navigating to another file; request it, then do work with the response.
    final response = await doGet<Map<String, Object>>(path,
        queryParameters: {'inline': 'true'});
    writeCodeAndRegions(path, FileDetails.fromJson(response), clearEditDetails);
    maybeScrollToAndHighlight(offset, line);
    var filePathPart = _stripQuery(path);
    updatePage(filePathPart, offset);
    if (callback != null) {
      callback();
    }
  } catch (e, st) {
    handleError('Could not load dart file $path', e, st);
  }
}

/// Load the navigation tree into the ".nav-tree" div.
void loadNavigationTree() async {
  var path = '/_preview/navigationTree.json';

  // Request the navigation tree, then do work with the response.
  try {
    final response = await doGet<List<Object>>(path);
    var navTree = document.querySelector('.nav-tree');
    navTree.innerHtml = '';
    navigationTree = NavigationTreeNode.listFromJson(response);
    writeNavigationSubtree(navTree, navigationTree,
        enablePartialMigration: true);
  } catch (e, st) {
    handleError('Could not load navigation tree', e, st);
  }
}

void logError(Object e, Object st) {
  window.console.error('$e');
  window.console.error('$st');
}

/// Scroll an element into view if it is not visible.
void maybeScrollIntoView(Element element) {
  var rect = element.getBoundingClientRect();
  // A line of text in the code view is 14px high. Including it here means we
  // only choose to _not_ scroll a line of code into view if the entire line is
  // visible.
  var lineHeight = 14;
  var visibleCeiling = headerPanel.offsetHeight + lineHeight;
  var visibleFloor =
      window.innerHeight - (footerPanel.offsetHeight + lineHeight);
  if (rect.bottom > visibleFloor) {
    element.scrollIntoView();
  } else if (rect.top < visibleCeiling) {
    element.scrollIntoView();
  }
}

/// Scrolls target with id [offset] into view if it is not currently in view.
///
/// Falls back to [lineNumber] if a target with id "o$offset" does not exist.
///
/// Also adds the "target" class, highlighting the target, and the "highlight"
/// class to the entire line on which the target lies.
///
/// If [offset] is null, instead scrolls to the top of the file.
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
    var lines = document.querySelectorAll('.line-no');
    if (lines.isEmpty) {
      // I don't see how this could happen, but return anyhow.
      return;
    }
    maybeScrollIntoView(lines.first);
  }
}

/// Navigate to [path] and optionally scroll [offset] into view.
///
/// If [callback] is present, it will be called after the server response has
/// been processed, and the content has been updated on the page.
void navigate(
  String path,
  int offset,
  int lineNumber,
  bool clearEditDetails, {
  VoidCallback callback,
}) {
  var currentOffset = getOffset(window.location.href);
  var currentLineNumber = getLine(window.location.href);
  removeHighlight(currentOffset, currentLineNumber);
  if (path == window.location.pathname) {
    // Navigating to same file; just scroll into view.
    maybeScrollToAndHighlight(offset, lineNumber);
    if (callback != null) {
      callback();
    }
  } else {
    loadFile(path, offset, lineNumber, clearEditDetails, callback: callback);
  }
}

/// Returns [path], which may include query parameters, with a new path which
/// adds (or replaces) parameters from [queryParameters].
///
/// Additionally, the "authToken" parameter will be added with the authToken
/// found in the current location.
String pathWithQueryParameters(
    String path, Map<String, String> queryParameters) {
  var uri = Uri.parse(path);
  var mergedQueryParameters = {
    ...uri.queryParameters,
    ...queryParameters,
    'authToken': authToken
  };
  return uri.replace(queryParameters: mergedQueryParameters).toString();
}

String pluralize(int count, String single, {String multiple}) {
  return count == 1 ? single : (multiple ?? '${single}s');
}

void populateEditDetails([EditDetails response]) {
  // Clear out any current edit details.
  editPanel.innerHtml = '';
  if (response == null) {
    Element p = ParagraphElement()
      ..text = 'See details about a proposed edit.'
      ..classes = ['placeholder'];
    editPanel.append(p);
    p.scrollIntoView();
    return;
  }

  var fileDisplayPath = response.displayPath;
  var parentDirectory = _p.dirname(fileDisplayPath);

  // 'Changed ... at foo.dart:12.'
  var explanationMessage = response.explanation;
  var relPath = _p.relative(fileDisplayPath, from: rootPath);
  var line = response.line;
  Element explanation = document.createElement('p');
  editPanel.append(explanation);
  explanation
    ..appendText('$explanationMessage at ')
    ..append(AnchorElement(
        href: pathWithQueryParameters(
            response.uriPath, {'line': line.toString()}))
      ..appendText('$relPath:$line.'));
  explanation.scrollIntoView();
  _populateEditTraces(response, editPanel, parentDirectory);
  _populateEditLinks(response, editPanel);
}

/// Write the contents of the Edit List, from JSON data [editListData].
void populateProposedEdits(
    String path, Map<String, List<EditListItem>> edits, bool clearEditDetails) {
  editListElement.innerHtml = '';

  var editCount = edits.length;
  if (editCount == 0) {
    Element p = document.createElement('p');
    editListElement.append(p);
    p.append(Text('No proposed edits'));
  } else {
    for (var entry in edits.entries) {
      Element p = document.createElement('p');
      editListElement.append(p);
      p.append(Text('${entry.key}:'));

      Element list = document.createElement('ul');
      editListElement.append(list);
      for (var edit in entry.value) {
        Element item = document.createElement('li');
        list.append(item);
        item.classes.add('edit');
        AnchorElement anchor = AnchorElement();
        item.append(anchor);
        anchor.classes.add('edit-link');
        var offset = edit.offset;
        anchor.dataset['offset'] = '$offset';
        var line = edit.line;
        anchor.dataset['line'] = '$line';
        anchor.append(Text('line $line'));
        anchor.setAttribute(
            'href',
            pathWithQueryParameters(window.location.pathname, {
              'line': '$line',
              'offset': '$offset',
            }));
        anchor.onClick.listen((MouseEvent event) {
          event.preventDefault();
          navigate(window.location.pathname, offset, line, true, callback: () {
            pushState(window.location.pathname, offset, line);
          });
          loadAndPopulateEditDetails(path, offset, line);
        });
        item.append(Text(': ${edit.explanation}'));
      }
    }
  }

  if (clearEditDetails) {
    populateEditDetails();
  }
}

void pushState(String path, int offset, int line) {
  var uri = Uri.parse('${window.location.origin}$path');

  var params = {
    if (offset != null) 'offset': '$offset',
    if (line != null) 'line': '$line',
    'authToken': authToken,
  };

  uri = uri.replace(queryParameters: params);
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

void toggleDirectoryMigrationStatus(NavigationTreeDirectoryNode entity) {
  switch (entity.migrationStatus) {
    case UnitMigrationStatus.alreadyMigrated:
      // This tree cannot be toggled.
      break;
    case UnitMigrationStatus.migrating:
      // At least one child file is 'migrating' (some may be 'already
      // migrated'). Toggle all 'migrating' children to opt out.
      entity.toggleChildrenToOptOut();
      break;
    case UnitMigrationStatus.optingOut:
      // At least one child file is 'opting out' (some may be 'already
      // migrated'). Toggle all 'migrating' children to migrate.
      entity.toggleChildrenToMigrate();
      break;
    case UnitMigrationStatus.indeterminate:
      // At least one child file is 'migrating' and at least one child file is
      // 'opting out' (some may be 'already migrated'). Toggle all 'migrating'
      // children to migrate.
      entity.toggleChildrenToMigrate();
  }
}

void toggleFileMigrationStatus(NavigationTreeFileNode entity) {
  switch (entity.migrationStatus) {
    case UnitMigrationStatus.alreadyMigrated:
      // This file cannot be toggled.
      break;
    case UnitMigrationStatus.migrating:
      entity.migrationStatus = UnitMigrationStatus.optingOut;
      break;
    case UnitMigrationStatus.optingOut:
      entity.migrationStatus = UnitMigrationStatus.migrating;
      break;
    case UnitMigrationStatus.indeterminate:
      throw StateError('File ${entity.path} should not have '
          'indeterminate migration status');
  }
}

/// Updates the navigation [icon] and current file icon according to the current
/// migration status of [entity].
void updateIconsForNode(Element icon, NavigationTreeNode entity) {
  updateIconForStatus(icon, entity.migrationStatus);
  // Update the status at the top of the file view if [entity] represents the
  // current file.
  var unitPath = unitName.innerText;
  if (entity.path == unitPath) {
    updateIconForStatus(migrateUnitStatusIcon, entity.migrationStatus);
  }
}

/// Updates [icon] according to [status].
void updateIconForStatus(Element icon, UnitMigrationStatus status) {
  switch (status) {
    case UnitMigrationStatus.alreadyMigrated:
      icon.innerText = 'check_box';
      icon.classes.add('already-migrated');
      icon.setAttribute('title', 'Already migrated');
      break;
    case UnitMigrationStatus.migrating:
      icon.innerText = 'check_box';
      icon.classes.remove('opted-out');
      icon.classes.add('migrating');
      icon.setAttribute('title', 'Migrating to null safety');
      break;
    case UnitMigrationStatus.optingOut:
      icon.innerText = 'check_box_outline_blank';
      icon.classes.remove('migrating');
      icon.classes.add('opted-out');
      icon.setAttribute('title', 'Opting out of null safety');
      break;
    default:
      icon.innerText = 'indeterminate_check_box';
      icon.classes.remove('migrating');
      // 'opted-out' is the same style as 'indeterminate'.
      icon.classes.add('opted-out');
      icon.setAttribute(
          'title', "Mixed statuses of 'migrating' and 'opting out'");
      break;
  }
}

/// Update the heading and navigation links.
///
/// Call this after updating page content on a navigation.
void updatePage(String path, [int offset]) {
  path = relativePath(path);
  // Update page heading.
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
  migrateUnitStatusIconLabel.classes.add('visible');
}

/// Updates the parent icons of [entity] with list item [element] in the
/// navigation tree.
void updateParentIcons(Element element, NavigationTreeNode entity) {
  var parent = entity.parent;
  if (parent != null) {
    var parentElement = (element.parentNode as Element).parentNode as Element;
    var statusIcon = parentElement.querySelector(':scope > .status-icon');
    updateIconsForNode(statusIcon, parent);
    updateParentIcons(parentElement, parent);
  }
}

/// Updates subtree icons for the children [entity] with list item [element].
void updateSubtreeIcons(Element element, NavigationTreeDirectoryNode entity) {
  for (var child in entity.subtree) {
    var childNode = element.querySelector('[data-name*="${child.path}"]');
    if (child is NavigationTreeDirectoryNode) {
      updateSubtreeIcons(childNode, child);
      var childIcon = childNode.querySelector(':scope > .status-icon');
      updateIconsForNode(childIcon, entity);
    } else {
      var childIcon = (childNode.parentNode as Element)
          .querySelector(':scope > .status-icon');
      updateIconsForNode(childIcon, child);
    }
  }
}

/// Load data from [data] into the .code and the .regions divs.
void writeCodeAndRegions(String path, FileDetails data, bool clearEditDetails) {
  var regionsElement = document.querySelector('.regions');
  var codeElement = document.querySelector('.code');

  _PermissiveNodeValidator.setInnerHtml(regionsElement, data.regions);
  _PermissiveNodeValidator.setInnerHtml(codeElement, data.navigationContent);
  populateProposedEdits(path, data.edits, clearEditDetails);

  // highlightAllCode is remarkably slow (about 4 seconds to handle a 300k file
  // on a Pixelbook), so skip it for large files.
  if (data.sourceCode.length < 200000) {
    highlightAllCode();
  }
  addClickHandlers('.code', true);
  addClickHandlers('.regions', true);
}

void writeNavigationSubtree(
    Element parentElement, List<NavigationTreeNode> tree,
    {bool enablePartialMigration = false}) {
  Element ul = document.createElement('ul');
  parentElement.append(ul);
  for (var entity in tree) {
    Element li = document.createElement('li');
    ul.append(li);
    if (entity is NavigationTreeDirectoryNode) {
      li.classes.add('dir');
      li.dataset['name'] = entity.path;
      Element arrow = document.createElement('span');
      li.append(arrow);
      arrow.classes.add('arrow');
      arrow.innerHtml = '&#x25BC;';
      var folderIcon = createIcon('folder_open');
      li.append(folderIcon);
      li.append(Text(entity.name));
      writeNavigationSubtree(li, entity.subtree,
          enablePartialMigration: enablePartialMigration);
      if (enablePartialMigration) {
        var statusIcon = createIcon('indeterminate_check_box')
          ..classes.add('status-icon');
        updateIconsForNode(statusIcon, entity);
        statusIcon.onClick.listen((MouseEvent event) {
          toggleDirectoryMigrationStatus(entity);
          updateSubtreeIcons(li, entity);
          updateIconsForNode(statusIcon, entity);
          updateParentIcons(li, entity);
        });
        li.insertBefore(statusIcon, folderIcon);
      }
      addArrowClickHandler(arrow);
    } else if (entity is NavigationTreeFileNode) {
      if (enablePartialMigration) {
        var statusIcon = createIcon()..classes.add('status-icon');
        updateIconsForNode(statusIcon, entity);
        statusIcon.onClick.listen((MouseEvent event) {
          toggleFileMigrationStatus(entity);
          updateIconsForNode(statusIcon, entity);
          updateParentIcons(li, entity);
        });
        li.append(statusIcon);
      }
      li.append(createIcon('insert_drive_file'));
      Element a = document.createElement('a');
      li.append(a);
      a.classes.add('nav-link');
      a.dataset['name'] = entity.path;
      a.setAttribute('href', pathWithQueryParameters(entity.href, {}));
      a.append(Text(entity.name));
      a.onClick.listen((MouseEvent event) => handleNavLinkClick(event, true));
      var editCount = entity.editCount;
      if (editCount > 0) {
        Element editsBadge = document.createElement('span');
        li.append(editsBadge);
        editsBadge.classes.add('edit-count');
        editsBadge.setAttribute(
            'title', '$editCount ${pluralize(editCount, 'proposed edit')}');
        editsBadge.append(Text(editCount.toString()));
      }
    }
  }
}

void _addHintAction(HintAction hintAction, Node drawer, TargetLink link) {
  drawer.append(ButtonElement()
    ..onClick.listen((event) async {
      try {
        var previousScrollPosition = _getCurrentScrollPosition();
        await doPost(
            pathWithQueryParameters('/apply-hint', {}), hintAction.toJson());
        var path = _stripQuery(link.href);
        await loadFile(path, null, link.line, false);
        document.body.classes.add('needs-rerun');
        _scrollContentTo(previousScrollPosition);
      } catch (e, st) {
        handleError('Could not apply hint', e, st);
      }
    })
    ..appendText(hintAction.kind.description));
}

AnchorElement _aElementForLink(TargetLink link) {
  var targetLine = link.line;
  AnchorElement a = AnchorElement();
  a.append(Text('${link.path}:$targetLine'));
  a.setAttribute('href', link.href);
  a.classes.add('nav-link');
  return a;
}

int _getCurrentScrollPosition() => document.querySelector('.content').scrollTop;

void _populateEditLinks(EditDetails response, Element editPanel) {
  if (response.edits == null) {
    return;
  }

  var subheading = editPanel.append(document.createElement('p'));
  subheading.append(document.createElement('span')
    ..classes = ['type-description']
    ..append(Text('Actions')));
  subheading.append(Text(':'));

  Element editParagraph = document.createElement('p');
  editPanel.append(editParagraph);
  for (var edit in response.edits) {
    Element a = document.createElement('a');
    editParagraph.append(a);
    a.append(Text(edit.description));
    a.setAttribute('href', edit.href);
    a.classes = ['add-hint-link', 'before-apply', 'button'];
  }
}

void _populateEditTraces(
    EditDetails response, Element editPanel, String parentDirectory) {
  for (var trace in response.traces) {
    var traceParagraph =
        editPanel.append(document.createElement('p')..classes = ['trace']);
    traceParagraph.append(document.createElement('span')
      ..classes = ['type-description']
      ..append(Text(trace.description)));
    traceParagraph.append(Text(':'));
    var ul = traceParagraph
        .append(document.createElement('ul')..classes = ['trace']);
    for (var entry in trace.entries) {
      Element li = document.createElement('li');
      ul.append(li);
      li.append(document.createElement('span')
        ..classes = ['function']
        ..appendTextWithBreaks(entry.function ?? 'unknown'));
      var link = entry.link;
      if (link != null) {
        li.append(Text(' ('));
        li.append(_aElementForLink(link));
        li.append(Text(')'));
      }
      li.append(Text(': '));
      li.appendTextWithBreaks(entry.description ?? 'unknown');

      if (entry.hintActions.isNotEmpty) {
        var drawer = li.append(
            document.createElement('p')..classes = ['drawer', 'before-apply']);
        for (final hintAction in entry.hintActions) {
          _addHintAction(hintAction, drawer, link);
        }
      }
    }
  }
}

void _scrollContentTo(int top) =>
    document.querySelector('.content').scrollTop = top;

String _stripQuery(String path) =>
    path.contains('?') ? path.substring(0, path.indexOf('?')) : path;

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

/// An extension on Element that fits into cascades.
extension on Element {
  /// Append [text] to this, inserting a word break before each '.' character.
  void appendTextWithBreaks(String text) {
    var textParts = text.split('.');
    append(Text(textParts.first));
    for (var substring in textParts.skip(1)) {
      // Replace the '.' with a zero-width space and a '.'.
      appendHtml('&#8203;.');
      append(Text(substring));
    }
  }
}

extension on List<NavigationTreeNode> {
  /// Finds the node with path equal to [path], recursively, or `null`.
  NavigationTreeNode find(String path) {
    for (var node in this) {
      if (node is NavigationTreeDirectoryNode) {
        var foundInSubtree = node.subtree.find(path);
        if (foundInSubtree != null) return foundInSubtree;
      } else {
        assert(node is NavigationTreeFileNode);
        if (node.path == path) return node;
      }
    }
    return null;
  }
}
