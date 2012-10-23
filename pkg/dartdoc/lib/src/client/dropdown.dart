part of client_static;

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List libraryList;
InputElement searchInput;
DivElement dropdown;

/**
 * Update the search drop down based on the current search text.
 */
updateDropDown(Event event) {
  if (libraryList == null) return;
  if (searchInput == null) return;
  if (dropdown == null) return;

  var results = <Result>[];
  String text = searchInput.value;
  if (text == currentSearchText) {
    return;
  }
  if (text.isEmpty()) {
    updateResults(text, results);
    hideDropDown();
    return;
  }
  if (text.contains('.')) {
    // Search type members.
    String typeText = text.substring(0, text.indexOf('.'));
    String memberText = text.substring(text.indexOf('.') + 1);

    if (typeText.isEmpty() && memberText.isEmpty()) {
      // Don't search on '.'.
    } else if (typeText.isEmpty()) {
      // Search text is of the form '.id' => Look up members.
      matchAllMembers(results, memberText);
    } else if (memberText.isEmpty()) {
      // Search text is of the form 'Type.' => Look up members in 'Type'.
      matchAllMembersInType(results, typeText, memberText);
    } else {
      // Search text is of the form 'Type.id' => Look up member 'id' in 'Type'.
      matchMembersInType(results, text, typeText, memberText);
    }
  } else {
    // Search all entities.
    var searchText = new SearchText(text);
    for (Map<String,Dynamic> library in libraryList)  {
      matchLibrary(results, searchText, library);
      matchLibraryMembers(results, searchText, library);
      matchTypes(results, searchText, library);
    }
  }
  var elements = <Element>[];
  var table = new TableElement();
  table.classes.add('drop-down-table');
  elements.add(table);

  if (results.isEmpty()) {
    var row = table.insertRow(0);
    row.innerHTML = "<tr><td>No matches found for '$text'.</td></tr>";
  } else {
    results.sort(resultComparator);

    var count = 0;
    for (Result result in results) {
      result.addRow(table);
      if (++count >= 10) {
        break;
      }
    }
    if (results.length >= 10) {
      var row = table.insertRow(table.rows.length);
      row.innerHTML = '<tr><td>+ ${results.length-10} more.</td></tr>';
      results = results.getRange(0, 10);
    }
  }
  dropdown.elements = elements;
  updateResults(text, results);
  showDropDown();
}

void matchAllMembers(List<Result> results, String memberText) {
  var searchText = new SearchText(memberText);
  for (Map<String,Dynamic> library in libraryList)  {
    String libraryName = library[NAME];
    if (library.containsKey(TYPES)) {
      for (Map<String,Dynamic> type in library[TYPES]) {
        String typeName = type[NAME];
        if (type.containsKey(MEMBERS)) {
          for (Map<String,Dynamic> member in type[MEMBERS]) {
            StringMatch memberMatch = obtainMatch(searchText, member[NAME]);
            if (memberMatch != null) {
              results.add(new Result(memberMatch, member[KIND],
                  getTypeMemberUrl(libraryName, typeName, member),
                  library: libraryName, type: typeName, args: type[ARGS],
                  noargs: member[NO_PARAMS]));
            }
          }
        }
      }
    }
  }
}

void matchAllMembersInType(List<Result> results,
                           String typeText, String memberText) {
  var searchText = new SearchText(typeText);
  var emptyText = new SearchText(memberText);
  for (Map<String,Dynamic> library in libraryList)  {
    String libraryName = library[NAME];
    if (library.containsKey(TYPES)) {
      for (Map<String,Dynamic> type in library[TYPES]) {
        String typeName = type[NAME];
        StringMatch typeMatch = obtainMatch(searchText, typeName);
        if (typeMatch != null) {
          if (type.containsKey(MEMBERS)) {
            for (Map<String,Dynamic> member in type[MEMBERS]) {
              StringMatch memberMatch = obtainMatch(emptyText,
                  member[NAME]);
              results.add(new Result(memberMatch, member[KIND],
                  getTypeMemberUrl(libraryName, typeName, member),
                  library: libraryName, prefix: typeMatch,
                  noargs: member[NO_PARAMS]));
            }
          }
        }
      }
    }
  }
}

void matchMembersInType(List<Result> results,
                        String text, String typeText, String memberText) {
  var searchText = new SearchText(text);
  var typeSearchText = new SearchText(typeText);
  var memberSearchText = new SearchText(memberText);
  for (Map<String,Dynamic> library in libraryList)  {
    String libraryName = library[NAME];
    if (library.containsKey(TYPES)) {
      for (Map<String,Dynamic> type in library[TYPES]) {
        String typeName = type[NAME];
        StringMatch typeMatch = obtainMatch(typeSearchText, typeName);
        if (typeMatch != null) {
          if (type.containsKey(MEMBERS)) {
            for (Map<String,Dynamic> member in type[MEMBERS]) {
              // Check for constructor match.
              StringMatch constructorMatch = obtainMatch(searchText,
                  member[NAME]);
              if (constructorMatch != null) {
                results.add(new Result(constructorMatch, member[KIND],
                    getTypeMemberUrl(libraryName, typeName, member),
                    library: libraryName, noargs: member[NO_PARAMS]));
              } else {
                // Try member match.
                StringMatch memberMatch = obtainMatch(memberSearchText,
                    member[NAME]);
                if (memberMatch != null) {
                  results.add(new Result(memberMatch, member[KIND],
                      getTypeMemberUrl(libraryName, typeName, member),
                      library: libraryName, prefix: typeMatch,
                      args: type[ARGS], noargs: member[NO_PARAMS]));
                }
              }
            }
          }
        }
      }
    }
  }
}

void matchLibrary(List<Result> results, SearchText searchText, Map library) {
  String libraryName = library[NAME];
  StringMatch libraryMatch = obtainMatch(searchText, libraryName);
  if (libraryMatch != null) {
    results.add(new Result(libraryMatch, LIBRARY,
                           getLibraryUrl(libraryName)));
  }
}

void matchLibraryMembers(List<Result> results, SearchText searchText,
                          Map library) {
  if (library.containsKey(MEMBERS)) {
    String libraryName = library[NAME];
    for (Map<String,Dynamic> member in library[MEMBERS]) {
      StringMatch memberMatch = obtainMatch(searchText, member[NAME]);
      if (memberMatch != null) {
        results.add(new Result(memberMatch, member[KIND],
                               getLibraryMemberUrl(libraryName, member),
                               library: libraryName, noargs: member[NO_PARAMS]));
      }
    }
  }
}

void matchTypes(List<Result> results, SearchText searchText,
                Map library) {
  if (library.containsKey(TYPES)) {
    String libraryName = library[NAME];
    for (Map<String,Dynamic> type in library[TYPES]) {
      String typeName = type[NAME];
      matchType(results, searchText, libraryName, type);
      matchTypeMembers(results, searchText, libraryName, type);
    }
  }
}

void matchType(List<Result> results, SearchText searchText,
               String libraryName, Map type) {
  String typeName = type[NAME];
  StringMatch typeMatch = obtainMatch(searchText, typeName);
  if (typeMatch != null) {
    results.add(new Result(typeMatch, type[KIND],
                           getTypeUrl(libraryName, type),
                           library: libraryName, args: type[ARGS]));
  }
}

void matchTypeMembers(List<Result> results, SearchText searchText,
                      String libraryName, Map type) {
  if (type.containsKey(MEMBERS)) {
    String typeName = type[NAME];
    for (Map<String,Dynamic> member in type[MEMBERS]) {
      StringMatch memberMatch = obtainMatch(searchText, member[NAME]);
      if (memberMatch != null) {
        results.add(new Result(memberMatch, member[KIND],
            getTypeMemberUrl(libraryName, typeName, member),
            library: libraryName, type: typeName, args: type[ARGS],
            noargs: member[NO_PARAMS]));
      }
    }
  }
}

String currentSearchText;
Result _currentResult;
List<Result> currentResults = const <Result>[];

void updateResults(String searchText, List<Result> results) {
  currentSearchText = searchText;
  currentResults = results;
  if (currentResults.isEmpty()) {
    _currentResultIndex = -1;
    currentResult = null;
  } else {
    _currentResultIndex = 0;
    currentResult = currentResults[0];
  }
}

int _currentResultIndex;

void set currentResultIndex(int index) {
  if (index < -1) {
    return;
  }
  if (index >= currentResults.length) {
    return;
  }
  if (index != _currentResultIndex) {
    _currentResultIndex = index;
    if (index >= 0) {
      currentResult = currentResults[_currentResultIndex];
    } else {
      currentResult = null;
    }
  }
}

int get currentResultIndex => _currentResultIndex;

void set currentResult(Result result) {
  if (_currentResult != result) {
    if (_currentResult != null) {
      _currentResult.row.classes.remove('drop-down-link-select');
    }
    _currentResult = result;
    if (_currentResult != null) {
      _currentResult.row.classes.add('drop-down-link-select');
    }
  }
}

Result get currentResult => _currentResult;

/**
 * Navigate the search drop down using up/down inside the search field. Follow
 * the result link on enter.
 */
void handleUpDown(KeyboardEvent event) {
  if (event.keyIdentifier == KeyName.UP) {
    currentResultIndex--;
    event.preventDefault();
  } else if (event.keyIdentifier == KeyName.DOWN) {
    currentResultIndex++;
    event.preventDefault();
  } else if (event.keyIdentifier == KeyName.ENTER) {
    if (currentResult != null) {
      window.location.href = currentResult.url;
      event.preventDefault();
      hideDropDown();
    }
  }
}

/** Show the search drop down unless there are no current results. */
void showDropDown() {
  if (currentResults.isEmpty()) {
    hideDropDown();
  } else {
    dropdown.style.visibility = 'visible';
  }
}

/** Used to prevent hiding the drop down when it is clicked. */
bool hideDropDownSuspend = false;

/** Hide the search drop down unless suspended. */
void hideDropDown() {
  if (hideDropDownSuspend) return;

  dropdown.style.visibility = 'hidden';
}

/** Activate search on Ctrl+3 and S. */
void shortcutHandler(KeyboardEvent event) {
  if (event.keyCode == 0x33/* 3 */ && event.ctrlKey) {
    searchInput.focus();
    event.preventDefault();
  } else if (event.target != searchInput && event.keyCode == 0x53/* S */) {
    // Allow writing 's' in the search input.
    searchInput.focus();
    event.preventDefault();
  }
}

/**
 * Setup window shortcuts.
 */
void setupShortcuts() {
  window.on.keyDown.add(shortcutHandler);
}

/** Setup search hooks. */
void setupSearch(var libraries) {
  libraryList = libraries;
  searchInput = query('#q');
  dropdown = query('#drop-down');

  searchInput.on.keyDown.add(handleUpDown);
  searchInput.on.keyUp.add(updateDropDown);
  searchInput.on.change.add(updateDropDown);
  searchInput.on.reset.add(updateDropDown);
  searchInput.on.focus.add((event) => showDropDown());
  searchInput.on.blur.add((event) => hideDropDown());
}