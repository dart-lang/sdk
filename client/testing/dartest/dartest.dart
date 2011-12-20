// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dartest');

#import('dart:dom');
#import('../unittest/unittest_dartest.dart');

#source('css.dart');

interface Elements {
  Element get containerDiv();
  Element get mainElem();
  Element get testBody();
  Element get testsRunElem();
  Element get testsFailedElem();
  Element get testsErrorsElem();
  Element get orange();
  Element get red();
  Element get green();
  Element get coverageBody();
  Element get covPreElem();
  HTMLElement get covTableBody();
}

class AppElements implements Elements {
  Element containerDiv;
  Element mainElem;
  Element testBody;
  Element testsRunElem;
  Element testsFailedElem;
  Element testsErrorsElem;
  Element orange;
  Element red;
  Element green;
  Element coverageBody;
  Element covPreElem;
  HTMLElement covTableBody;
}


/** DARTest provides a library to run tests in the app. */
class DARTest{
  AppElements _inAppElements, _fullAppElements, _appElements;
  DOMWindow _runnerWindow;

  DARTest() { 
    _runnerWindow = window;
    dartestLogger = _log;
    _inAppElements = new AppElements();
    _appElements = _inAppElements;
    DARTestCss.inject(document, true);
  }
  
  void run() {
    _renderMain();
    _createResultsTable();
  }

  void _log(String message) {
    _runnerWindow.console.log(message);
  }
  
  /** Create the results table after loading tests. */
  void _createResultsTable() {
    _log('Creating results table');
    HTMLTableElement table = _runnerWindow.document.createElement('table');
    table.className = 'dt-results';
    HTMLTableSectionElement head = _runnerWindow.document.createElement('thead');
    head.innerHTML = '<tr><th>ID <th>Description <th>Result';
    table.appendChild(head);
    
    HTMLTableSectionElement body = _runnerWindow.document.createElement('tbody');
    body.id = 'dt-results-body';
    tests.forEach((final t) {
      HTMLTableRowElement testDetailRow = 
        _runnerWindow.document.createElement('tr');
      testDetailRow.id = 'dt-test-${t.id}';
      _addTestDetails(t, testDetailRow);
      body.appendChild(testDetailRow);
      
      HTMLTableRowElement testMessageRow = 
        _runnerWindow.document.createElement('tr');
      testMessageRow.id = 'dt-detail-${t.id}';
      testMessageRow.className = 'dt-hide';
      body.appendChild(testMessageRow);
    });
    
    table.appendChild(body);
    
    if(_appElements.testBody != null) {
      _appElements.testBody.appendChild(table);
    }
  }

  /** Update the results table for test. */
  void _updateResultsTable(TestCase t, DOMWindow domWin) {
    HTMLTableRowElement row = domWin.document.getElementById('dt-test-${t.id}');
    row.className = 'dt-result-row';
    row.innerHTML = ''; // Remove all children as we will re-populate them
    _addTestDetails(t, row);
    
    HTMLTableRowElement details = 
      domWin.document.getElementById('dt-detail-${t.id}');
    details.appendChild(_getTestStats(t, domWin));
    
    row.addEventListener('click', (Event e) {
        if(details.className == 'dt-hide') {
          details.className = '';
        } else {
          details.className = 'dt-hide';
        }
      }, true);
  }
  
  /** Escape HTML special chars. */
  String _escape(String str) {
    str = str.replaceAll('&','&amp;');
    str = str.replaceAll('<','&lt;');
    str = str.replaceAll('>','&gt;');
    str = str.replaceAll('"','&quot;');
    str = str.replaceAll("'",'&#x27;');
    str = str.replaceAll('/','&#x2F;');
    return str;
  }
  
  /** Get test results as table cells. */
  void _addTestDetails(TestCase t, HTMLTableRowElement row) {
    HTMLTableCellElement testId = _runnerWindow.document.createElement('td');
    testId.textContent = t.id;
    row.appendChild(testId);
    
    HTMLTableCellElement testDesc = _runnerWindow.document.createElement('td');
    testDesc.textContent = t.description;
    row.appendChild(testDesc);
    
    HTMLTableCellElement testResult = _runnerWindow.document.createElement('td');
    String result = (t.result == null) ? 'none' : _escape(t.result);
    testResult.className = 'dt-$result';
    testResult.title = '${_escape(t.message)}';
    testResult.textContent = result.toUpperCase();
    row.appendChild(testResult);
  }
  
  HTMLTableCellElement _getTestStats(TestCase t, DOMWindow domWin) {
    HTMLTableCellElement tableCell = domWin.document.createElement('td');
    tableCell.colSpan = 3;
    
    if(t.message != '') {
      HTMLSpanElement messageSpan = domWin.document.createElement('span');
      messageSpan.textContent = t.message;
      tableCell.appendChild(messageSpan);
      tableCell.appendChild(domWin.document.createElement('br'));
    }
    if(t.stackTrace != null) {
      HTMLPreElement stackTacePre = domWin.document.createElement('pre');
      stackTacePre.textContent = t.stackTrace;
    }
    
    HTMLSpanElement durationSpan = domWin.document.createElement('span');
    durationSpan.textContent = 'took ${_printDuration(t.runningTime)}';
    tableCell.appendChild(durationSpan);
    
    return tableCell;
  }
  
  /** Update the UI after running test. */
  void _updateDARTestUI(TestCase test) {
    _updateResultsTable(test, window);
    if(_runnerWindow != window) {
      _updateResultsTable(test, _runnerWindow);
    }
    
    if(test.result != null) {
      _log('  Result: ${test.result.toUpperCase()} ${test.message}');
    }
    if(test.runningTime != null) {
      _log('  took ${_printDuration(test.runningTime)}');
    }
    _updateStatusProgress(_appElements);
    if(_runnerWindow != window) {
      _updateStatusProgress(_inAppElements);
    }
  }
  
  void _updateStatusProgress(AppElements elements) {
    // Update progressbar
    var pPass = 
      ((testsRun - testsFailed - testsErrors) / tests.length) * 100;
    elements.green.setAttribute('style', 'width:$pPass%');
    var pFailed = pPass + (testsFailed / tests.length) * 100;
    elements.red.setAttribute('style', 'width:$pFailed%');
    var pErrors = pFailed + (testsErrors / tests.length) * 100;
    elements.orange.setAttribute('style', 'width:$pErrors%');

    // Update status
    elements.testsRunElem.textContent = testsRun.toString();
    elements.testsFailedElem.textContent = testsFailed.toString();
    elements.testsErrorsElem.textContent = testsErrors.toString();
  }
  
  String _printDuration(Duration timeDuration) {
    StringBuffer out = new StringBuffer();
    if(timeDuration.inDays > 0) {
      out.add('${timeDuration.inDays} days ');
    }
    if(timeDuration.inHours > 0) {
      out.add('${timeDuration.inHours} hrs ');
    }
    if(timeDuration.inMinutes > 0) {
      out.add('${timeDuration.inMinutes} mins ');
    }
    if(timeDuration.inSeconds > 0) {
      out.add('${timeDuration.inSeconds} s ');
    }
    if(timeDuration.inMilliseconds > 0 || out.length == 0) {
      out.add('${timeDuration.inMilliseconds} ms');
    }
    return out.toString();
  }

  /** Populates the floating div with controls and toolbar. */
  HTMLDivElement _renderMain() {
    HTMLDivElement containerDiv = _runnerWindow.document.createElement('div');
    containerDiv.className = 'dt-container';
    _appElements.containerDiv = containerDiv;
    
    // Add the test controls
    HTMLDivElement mainElem = _runnerWindow.document.createElement('div');
    mainElem.className = 'dt-main';
    _appElements.mainElem = mainElem;
    
    _showTestControls();
    
    // Create header to hold window controls
    if(_runnerWindow == window) {
      HTMLDivElement headDiv = _runnerWindow.document.createElement('div');
      headDiv.className = 'dt-header';
      headDiv.innerHTML = 'DARTest: In-App View';
      HTMLImageElement close = _runnerWindow.document.createElement('img');
      close.className = 'dt-header-close';
      close.addEventListener('click', (Event) {
        containerDiv.className = 'dt-hide';
      }, true);
      HTMLImageElement pop = _runnerWindow.document.createElement('img');
      pop.className = 'dt-header-pop';
      pop.addEventListener('click', (Event) => _dartestMaximize(), true);
      HTMLImageElement minMax = _runnerWindow.document.createElement('img');
      minMax.className = 'dt-header-min';
      minMax.addEventListener('click', (Event) {
        if (mainElem.classList.contains('dt-hide')) {
          mainElem.classList.remove('dt-hide');
          mainElem.classList.add('dt-show');
          minMax.className = 'dt-header-min';
        } else {
          if (mainElem.classList.contains('dt-show')) {
            mainElem.classList.remove('dt-show');
          }
          mainElem.classList.add('dt-hide');
          minMax.className = 'dt-header-max';
        }
      }, true);
      headDiv.appendChild(close);
      headDiv.appendChild(pop);
      headDiv.appendChild(minMax);
      
      containerDiv.appendChild(headDiv);
    }

    HTMLDivElement tabDiv = _runnerWindow.document.createElement('div');
    tabDiv.className = 'dt-tab';
    HTMLUListElement tabList = _runnerWindow.document.createElement('ul');
    HTMLLIElement testingTab = _runnerWindow.document.createElement('li');
    HTMLLIElement coverageTab = _runnerWindow.document.createElement('li');
    testingTab.className = 'dt-tab-selected';
    testingTab.textContent = 'Testing';
    testingTab.addEventListener('click', (Event) {
      _showTestControls();
      _changeTabs(testingTab, coverageTab);
    }, true);
    tabList.appendChild(testingTab);
    coverageTab.textContent = 'Coverage';
    coverageTab.addEventListener('click', (Event) {
      _showCoverageControls();
      _changeTabs(coverageTab, testingTab);
    }, true);
    tabList.appendChild(coverageTab); 
    tabDiv.appendChild(tabList);
    containerDiv.appendChild(tabDiv);
    
    if(_runnerWindow != window) {
      HTMLDivElement popIn = _runnerWindow.document.createElement('div');
      popIn.className = 'dt-minimize';
      popIn.innerHTML = 'Pop In &#8690;';
      popIn.addEventListener('click', (Event) => _dartestMinimize(), true);
      containerDiv.appendChild(popIn);
    }  
    
    containerDiv.appendChild(mainElem);
    _runnerWindow.document.body.appendChild(containerDiv);
  }
  
  void _changeTabs(HTMLLIElement clickedTab, HTMLLIElement oldTab) {
    oldTab.className = '';
    clickedTab.className = 'dt-tab-selected';
  }
  
  void _showTestControls() {
    HTMLDivElement testBody = _appElements.testBody;
    if(testBody == null) {
      testBody = _runnerWindow.document.createElement('div');
      _appElements.testBody = testBody;
    
      // Create a toolbar to hold action buttons
      HTMLDivElement toolDiv = _runnerWindow.document.createElement('div');
      toolDiv.className = 'dt-toolbar';
      HTMLButtonElement runBtn = _runnerWindow.document.createElement('button');
      runBtn.innerHTML = '&#9658;';
      runBtn.title = 'Run Tests';
      runBtn.className = 'dt-button dt-run';
      runBtn.addEventListener('click', (Event) {
        _log('Running tests');
        updateUI = _updateDARTestUI;
        runDartests();
      }, true);
      toolDiv.appendChild(runBtn);
      HTMLButtonElement exportBtn = 
        _runnerWindow.document.createElement('button');
      exportBtn.innerHTML = '&#8631;';
      exportBtn.title = 'Export Results';
      exportBtn.className = 'dt-button dt-run';
      exportBtn.addEventListener('click', (Event e) {
        _log('Exporting results');
        _exportTestResults();
      }, true);
      toolDiv.appendChild(exportBtn);
      testBody.appendChild(toolDiv);
      
      // Create a datalist element for showing test status
      HTMLDListElement statList = _runnerWindow.document.createElement('dl');
      statList.className = 'dt-status';
      HTMLElement runsDt = _runnerWindow.document.createElement('dt');
      runsDt.textContent = 'Runs:';
      statList.appendChild(runsDt);
      HTMLElement testsRunElem = _runnerWindow.document.createElement('dd');
      _appElements.testsRunElem = testsRunElem;
      testsRunElem.textContent = testsRun.toString();
      statList.appendChild(testsRunElem);
  
      HTMLElement failDt = _runnerWindow.document.createElement('dt');
      failDt.textContent = 'Failed:';
      statList.appendChild(failDt);
      HTMLElement testsFailedElem = _runnerWindow.document.createElement('dd');
      _appElements.testsFailedElem = testsFailedElem;
      testsFailedElem.textContent = testsFailed.toString();
      statList.appendChild(testsFailedElem);
  
      HTMLElement errDt = _runnerWindow.document.createElement('dt');
      errDt.textContent = 'Errors:';
      statList.appendChild(errDt);
      HTMLElement testsErrorsElem = _runnerWindow.document.createElement('dd');
      _appElements.testsErrorsElem = testsErrorsElem;
      testsErrorsElem.textContent = testsErrors.toString();
      statList.appendChild(testsErrorsElem);  
      testBody.appendChild(statList);
      
      // Create progressbar and add red, green, orange bars
      HTMLDivElement progressDiv = _runnerWindow.document.createElement('div');
      progressDiv.className = 'dt-progressbar';
      progressDiv.innerHTML = "<span style='width:100%'></span>";
      
      HTMLSpanElement orange = _runnerWindow.document.createElement('span');
      _appElements.orange = orange;
      orange.className = 'orange';
      progressDiv.appendChild(orange);
  
      HTMLSpanElement red = _runnerWindow.document.createElement('span');
      _appElements.red = red;
      red.className = 'red';
      progressDiv.appendChild(red);
      
      HTMLSpanElement green = _runnerWindow.document.createElement('span');
      _appElements.green = green;
      green.className = 'green';
  
      progressDiv.appendChild(green);
      testBody.appendChild(progressDiv);
      
      HTMLDivElement hiddenElem = _runnerWindow.document.createElement('div');
      hiddenElem.className = 'dt-hide';
      hiddenElem.innerHTML = 
        "<a id='dt-export' download='test_results.csv' href='#' />";
      testBody.appendChild(hiddenElem);
      
      if(_appElements.mainElem != null) {
        _appElements.mainElem.appendChild(testBody);
      }
    }
    
    // Show hide divs
    _show(_appElements.testBody);
    _hide(_appElements.coverageBody);
  } 
  
  void _showCoverageControls() {
    HTMLDivElement coverageBody = _appElements.coverageBody;
    if(coverageBody == null) {
      coverageBody = _runnerWindow.document.createElement('div');
      _appElements.coverageBody = coverageBody;
      
      HTMLPreElement covPreElem = _runnerWindow.document.createElement('pre');
      _appElements.covPreElem = covPreElem;
      coverageBody.appendChild(covPreElem);
      
      HTMLTableElement covTable = _runnerWindow.document.createElement('table');
      covTable.className = 'dt-results';
      HTMLTableSectionElement head = 
        _runnerWindow.document.createElement('thead');
      head.innerHTML = '<tr><th>Unit <th>Function <th>Statement <th>Branch';
      covTable.appendChild(head);
      HTMLTableSectionElement covTableBody = 
        _runnerWindow.document.createElement('tbody');
      _appElements.covTableBody = covTableBody;
      covTableBody.id = 'dt-results-body';
      covTable.appendChild(covTableBody);
      coverageBody.appendChild(covTable);
      
      if(_appElements.mainElem != null) {
        _appElements.mainElem.appendChild(coverageBody);
      }
    }
    _show(_appElements.coverageBody);
    _hide(_appElements.testBody);

    _appElements.covPreElem.textContent = getCoverageSummary();
    
    // Coverage table has unit names and integers and won't have special chars
    _appElements.covTableBody.innerHTML = getCoverageDetails();
  }
  
  void _show(HTMLElement show) {
    if(show != null) {
      if(show.classList.contains('dt-hide')) {
        show.classList.remove('dt-hide');
      }
      show.classList.add('dt-show');
    }
  }
  
  void _hide(HTMLElement hide) {
    if(hide != null) {
      if(hide.classList.contains('dt-show')) {
        hide.classList.remove('dt-show');
      }
      hide.classList.add('dt-hide');
    }
  }

  void _dartestMaximize() {
    _hide(_appElements.containerDiv);
    _runnerWindow = window.open('', 'dartest-window', 
      DARTestCss._fullAppWindowFeatures);
    _runnerWindow.document.title = 'Dartest';
    _fullAppElements = new AppElements();
    _appElements = _fullAppElements;
    DARTestCss.inject(_runnerWindow.document, false);
    run();
    if(testsRun > 0) {
      tests.forEach((final t) => _updateDARTestUI(t));
    }
  }
  
  void _dartestMinimize() {
    _runnerWindow.close();
    _runnerWindow = window;
    _appElements = _inAppElements;
    _show(_appElements.containerDiv);
  }

  void _exportTestResults() {
    String csvData = getTestResultsCsv();
    _log(csvData);
    HTMLAnchorElement exportLink = 
      _runnerWindow.document.getElementById('dt-export');
    
    /** Bug: Can't instantiate WebKitBlobBuilder
     *  If this bug is fixed, we can remove the urlencode and lpad function.
     *
     *  WebKitBlobBuilder bb = new WebKitBlobBuilder();
     *  bb.append(csvData);
     *  Blob blob = bb.getBlob('text/plain;charset=${document.characterSet}');
     *  exportLink.href = window.webkitURL.createObjectURL(blob);
     **/
    
    exportLink.href = 'data:text/csv,' + _urlencode(csvData);
    
    MouseEvent ev = document.createEvent("MouseEvents");
    ev.initMouseEvent("click", true, false, window, 0, 0, 0, 0, 0
        , false, false, false, false, 0, null);
    exportLink.dispatchEvent(ev);
    
  }

  static String _urlencode(String s) {
    StringBuffer out = new StringBuffer();
    for(int i = 0; i < s.length; i++) {
      int cc = s.charCodeAt(i);
      if((cc >= 48 && cc <= 57) || (cc >= 65 && cc <= 90) || 
          (cc >= 97 && cc <= 122)) {
        out.add(s[i]);
      } else {
        out.add('%${_lpad(cc.toRadixString(16),2).toUpperCase()}');
      }
    }
    return out.toString();
  }

  static String _lpad(String s, int n) {
    if(s.length < n) {
      for(int i = 0; i < n - s.length; i++) {
        s = '0'+s;
      }
    }
    return s;
  }
}
