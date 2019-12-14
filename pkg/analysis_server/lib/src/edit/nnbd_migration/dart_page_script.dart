// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const dartPageScript = r'''
function getOffset(location) {
  const root = document.querySelector(".root").textContent;
  return new URL(location, "file://" + root + "/dummy.txt")
      .searchParams.get("offset");
}

function getLine(location) {
  const root = document.querySelector(".root").textContent;
  return new URL(location, "file://" + root + "/dummy.txt")
      .searchParams.get("line");
}

// Remove highlighting from [offset].
function removeHighlight(offset) {
  if (offset != null) {
    const anchor = document.getElementById("o" + offset);
    if (anchor != null) {
      anchor.classList.remove("target");
    }
  }
}

// Return the absolute path of [path], assuming [path] is relative to [root].
function absolutePath(path) {
  if (path[0] != "/") {
      const root = document.querySelector(".root").textContent;
      return new URL(path, window.location.href).pathname;
  } else {
    return path;
  }
}

// If [path] lies within [root], return the relative path of [path] from [root].
// Otherwise, return [path].
function relativePath(path) {
  const root = document.querySelector(".root").textContent + "/";
  if (path.startsWith(root)) {
    return path.substring(root.length);
  } else {
    return path;
  }
}

// Load data from [data] into the .code and the .regions divs.
function writeCodeAndRegions(data) {
  const regions = document.querySelector(".regions");
  const code = document.querySelector(".code");
  regions.innerHTML = data["regions"];
  code.innerHTML = data["navContent"];
  highlightAllCode();
  addClickHandlers(".code");
  addClickHandlers(".regions");
}

// Navigate to [path] and optionally scroll [offset] into view.
//
// If [callback] is present, it will be called after the server response has
// been processed, and the content has been updated on the page.
function navigate(path, offset, lineNumber, callback) {
  removeHighlight(offset);
  if (path == window.location.pathname) {
    // Navigating to same file; just scroll into view.
    maybeScrollIntoView(offset, lineNumber);
  } else {
    loadFile(path, offset, lineNumber, callback);
  }
}

// Scroll [target] into view if it is not currently in view.
//
// Also add the "target" class, highlighting the target.
function maybeScrollIntoView(offset, lineNumber) {
  if (offset !== null) {
    const target = document.getElementById("o" + offset);
    if (target != null) {
      const rect = target.getBoundingClientRect();
      // TODO(srawlins): Only scroll smoothly when on the same page.
      if (rect.bottom > window.innerHeight) {
        target.scrollIntoView({behavior: "smooth", block: "end"});
      }
      if (rect.top < 0) {
        target.scrollIntoView({behavior: "smooth"});
      }
      target.classList.add("target");
      if (lineNumber != null) {
        const line = document.querySelector(".line-" + lineNumber);
        line.parentNode.classList.add("highlight");
      }
    }
  }
}

// Load the file at [path] from the server, optionally scrolling [offset] into
// view.
function loadFile(path, offset, lineNumber, callback) {
  // Navigating to another file; request it, then do work with the response.
  const xhr = new XMLHttpRequest();
  xhr.open("GET", path + "?inline=true");
  xhr.setRequestHeader("Content-Type", "application/json");
  xhr.onload = function() {
    if (xhr.status === 200) {
      const response = JSON.parse(xhr.responseText);
      writeCodeAndRegions(response);
      maybeScrollIntoView(offset, lineNumber);
      updatePage(path, offset);
      if (callback !== undefined) {
        callback();
      }
    } else {
      alert("Request failed; status of " + xhr.status);
    }
  };
  xhr.send();
}

function pushState(path, offset, lineNumber) {
  let newLocation = window.location.origin + path + "?";
  if (offset !== null) {
    newLocation = newLocation + "offset=" + offset + "&";
  }
  if (lineNumber !== null) {
    newLocation = newLocation + "line=" + lineNumber;
  }
  history.pushState({}, "", newLocation);
}

// Update the heading and navigation links.
//
// Call this after updating page content on a navigation.
function updatePage(path, offset) {
  path = relativePath(path);
  // Update page heading.
  const unitName = document.querySelector("#unit-name");
  unitName.textContent = path;
  // Update navigation styles.
  document.querySelectorAll(".nav .nav-link").forEach((link) => {
    const name = link.dataset.name;
    if (name == path) {
      link.classList.add("selected-file");
    } else {
      link.classList.remove("selected-file");
    }
  });
}

function highlightAllCode(_) {
  document.querySelectorAll(".code").forEach((block) => {
    hljs.highlightBlock(block);
  });
}

function addClickHandlers(parentSelector) {
  const parentElement = document.querySelector(parentSelector);
  const links = parentElement.querySelectorAll(".nav-link");
  links.forEach(function(link) {
    link.onclick = (event) => {
      const path = absolutePath(event.currentTarget.getAttribute("href"));
      const offset = getOffset(event.currentTarget.getAttribute("href"));
      const lineNumber = getLine(event.currentTarget.getAttribute("href"));
      if (offset !== null) {
        navigate(path, offset, lineNumber,
            () => { pushState(path, offset, lineNumber) });
      } else {
        navigate(path, null, null, () => { pushState(path, null, null) });
      }
      event.preventDefault();
    };
  });
}

document.addEventListener("DOMContentLoaded", (event) => {
  const path = window.location.pathname;
  const offset = getOffset(window.location.href);
  const lineNumber = getLine(window.location.href);
  if (path.length > 1) {
    // TODO(srawlins): replaceState?
    loadFile(path, offset, lineNumber,
        () => { pushState(path, offset, lineNumber) });
  }
  addClickHandlers(".nav");
});

window.addEventListener("popstate", (event) => {
  const path = window.location.pathname;
  const offset = getOffset(window.location.href);
  const lineNumber = getLine(window.location.href);
  if (path.length > 1) {
    loadFile(path, offset, lineNumber);
  } else {
    // Blank out the page, for the index screen.
    writeCodeAndRegions({"regions": "", "navContent": ""});
    updatePage("&nbsp;", null);
  }
});
''';
