// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple application that renders coverage results in a page. It sorts data
 * by file name, shows a summary table including coverage statistics per
 * package, and implements the necessary behaviour to select a file and view
 * line-by-line coverage information.
 */

var files_;
var code_;
var summary_;
var selectedDiv_;
var file_percent_ = {};
var package_lines_ = {};
var package_covered_ = {};
var package_rec_lines_ = {};
var package_rec_covered_ = {};

// handle a click event anywhere on the screen
function clickListener(e) {
  var elem = e.target;
  // determine if a file or a close link was clicked on:
  while (elem != null) {
    if (elem.classList) {
      if (elem.classList.contains("file")) {
        fileSelected(elem);
        return;
      } else if (elem.classList.contains("close")) {
        closeDetails();
      }
    }
    elem = elem.parentNode;
  }
}

// handle when a row in the list of files is selected
function fileSelected(elem) {
  if (selectedDiv_ != null) {
    selectedDiv_.classList.remove("file-selected");
  }
  if (selectedDiv_ == elem) {
    closeDetails();
    return;
  }
  selectedDiv_ = elem;
  elem.classList.add("file-selected");
  var file = elem.getAttribute("data-field");
  var code_with_coverage = "";
  var lines = code_[file];
  var coverage = summary_[file];
  for (var lineNum = 0; lineNum < lines.length; lineNum++) {
    var covered = coverage[lineNum] == 1;
    var currentLine = lines[lineNum].
        replace(/</g, "&lt;").
        replace(/>/g, "&gt;").
        replace(/\n/g, "\\n");
    var iscode = coverage[lineNum] == 0 || coverage[lineNum] == 1;
    code_with_coverage +=
        "<span class='linenum'><span class='" +
        (covered && iscode ? "yes" : (iscode ? "no" : "")) + "'>" +
        (lineNum + 1)+ "</span>" +
        "<span>" + currentLine + "</span>" +
        "</div>";
  }

  var detailsDiv = document.getElementById("details-body");
  detailsDiv.innerHTML = code_with_coverage;
  var outerDiv = detailsDiv.parentNode;
  outerDiv.classList.remove("hidden");
}

// closes the detail view that displays line-by-line coverage info
function closeDetails() {
  if (selectedDiv_ != null) {
    selectedDiv_.classList.remove("file-selected");
    selectedDiv_ = null;
  }
  var detailsDiv = document.getElementById("details-body");
  detailsDiv.parentNode.classList.add("hidden");
}

// generates an HTML string segment for a coverage-bar
function generatePercentBar(percent) {
  return "<span class='coverage-bar'>" +
      "<span class='coverage-bar-inner' style='width:" + percent + "px'>" +
      "</span></span>";
}

// extracts the top-level directory from a path
function getRootDir(path) {
  if (path == null) {
    return null;
  }
  var index = path.indexOf("/");
  return index == -1 ? null : path.substring(0, index);
}

// extracts the directory portion of a path
function getDirName(path) {
  if (path == null) {
    return null;
  }
  var index = path.lastIndexOf("/");
  return index == -1 ? null : path.substring(0, index);
}

// extracts the file name portion of a path
function getFileName(path) {
  if (path == null) {
    return null;
  }
  var index = path.lastIndexOf("/");
  return index == -1 ? path : path.substring(index + 1);
}

// generates an HTML string segment with the summary stats for a package which
// doesn't include sub-packages statistics.
function generatePackageLine(pkg) {
  var percent = ((package_covered_[pkg] * 100) / package_lines_[pkg]).
      toFixed(1);
  return "<tr class='package'><td colspan='2' class='package'>" +
      pkg +
      "<td class='file-percent'>" + percent + "%</td>" +
      "<td class='file-percent'>" + generatePercentBar(percent) +
      "</td> </tr>";
}

// generates an HTML string segment with the summary stats for a package which
// includes sub-packages statistics
function generatePackageLineRec(pkg) {
  var percent = ((package_rec_covered_[pkg] * 100) /
                  package_rec_lines_[pkg]).toFixed(1);
  return "<tr class='package'><td colspan='2' class='package'>" +
      pkg + " (with subpackages)" +
      "<td class='file-percent'>" + percent + "%</td>" +
      "<td class='file-percent'>" + generatePercentBar(percent) +
      "</td> </tr>";
}

// generates an hTML string segment with the summary stats for a single file
function generateFileLine(file) {
  var filename = getFileName(file);
  var percent = file_percent_[file].toFixed(1)
  return "<tr class='file' data-field='" + file + "'>" +
      "<td></td>" +
      "<td class='file-name'>" +
      filename +
      "</td>" +
      "<td class='file-percent'>" + percent + "%</td>" +
      "<td class='file-percent'>" + generatePercentBar(percent) +
      "</td>" +
    "</tr>";
}

// Updates coverage information in a package given the coverage data from a file
// that is directly on that package or on some sub-package
function recordPackageLinesRec(pkg, totalcode, covered) {
  if (package_rec_lines_[pkg] == null) {
    package_rec_lines_[pkg] = totalcode;
    package_rec_covered_[pkg] = covered;
  } else {
    package_rec_lines_[pkg] += totalcode;
    package_rec_covered_[pkg] += covered;
  }
}

// Updates coverage information in a package given the coverage data from a file
// directly on that package
function recordPackageLines(pkg, totalcode, covered) {
  if (package_lines_[pkg] == null) {
    package_lines_[pkg] = totalcode;
    package_covered_[pkg] = covered;
  } else {
    package_lines_[pkg] += totalcode;
    package_covered_[pkg] += covered;
  }
}

var EMPTY_ROW = "<tr><td>&nbsp;</td></tr>";

// renders the page with a list of files and an area to display more details.
function render(files, code, summary) {
  files.sort()
  files_ = files;
  code_ = code;
  summary_ = summary;
  var buffer = "";
  var last_pkg = null;

  // compute percent for files and packages. Tally information per package, by
  // tracking total lines covered on any file in the package

  for (var i = 0; i < files.length; i++) {
    var file = files[i];
    var coverage = summary[file];
    var covered = 0;
    var totalcode = 0;
    for (var j = 0; j < coverage.length; j++) {
      if (coverage[j] == 1 || coverage[j] == 0) {
        totalcode += 1;
      }
      if (coverage[j] == 1) {
        covered += 1;
      }
    }
    file_percent_[file] = (covered * 100) / totalcode;
    var pkg = getDirName(file);

    // summary for this package alone
    recordPackageLines(pkg, totalcode, covered);

    // summary for each package including subpackages
    while (pkg != null) {
      recordPackageLinesRec(pkg, totalcode, covered);
      pkg = getDirName(pkg)
    }
    recordPackageLinesRec("** everything **", totalcode, covered);
  }

  // create UI for the results...
  buffer += generatePackageLineRec("** everything **");
  for (var i = 0; i < files.length; i++) {
    var file = files[i];

    var pkg = getDirName(file)
    if (pkg != last_pkg) {
      var prefix = getRootDir(last_pkg);
      var rec_summary = "";
      if (pkg.indexOf(prefix) != 0) {
        var current = getDirName(pkg);
        while (current != null) {
          rec_summary = EMPTY_ROW + generatePackageLineRec(current) +
              rec_summary;
          current = getDirName(current);
        }
      }
      buffer += rec_summary + EMPTY_ROW + generatePackageLineRec(pkg);
      last_pkg = pkg;
    }
    buffer += generateFileLine(file);
  }

  var menu = "<div class='menu'><table class='menu-table'><tbody>" +
      buffer + "</tbody></table></div>"

  // single file details
  var details = "<div class='details hidden'><div class='close'>X Close</div>" +
      "<div id='details-body' class='details-body'></div></div>";

  var div = document.createElement("div");
  div.innerHTML = "<div class='all'>" +
      "<div>Select a file to display its details:</div> "
      + menu + details + "</div>";
  document.body.appendChild(div);
  document.body.addEventListener("click", clickListener, true);
}
