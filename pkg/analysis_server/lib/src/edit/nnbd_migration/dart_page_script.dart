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

// Scroll target with id [offset] into view if it is not currently in view.
//
// If [offset] is null, instead scroll the "unit-name" header, at the top of the
// page, into view.
//
// Also add the "target" class, highlighting the target.
function maybeScrollIntoView(offset, lineNumber) {
  var target;
  if (offset !== null) {
    target = document.getElementById("o" + offset);
  } else {
    // If no offset is given, this is likely a navigation link, and we need to
    // scroll back to the top of the page.
    target = document.getElementById("unit-name");
  }
  if (target != null) {
    const rect = target.getBoundingClientRect();
    // TODO(srawlins): Only scroll smoothly when on the same page.
    if (rect.bottom > window.innerHeight) {
      target.scrollIntoView({behavior: "smooth", block: "end"});
    }
    if (rect.top < 0) {
      target.scrollIntoView({behavior: "smooth"});
    }
    if (target !== document.getElementById("unit-name")) {
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
  xhr.onerror = function(e) {
    alert(`Could not load ${path}; preview server might be disconnected.`);
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
  document.querySelectorAll(".nav-panel .nav-link").forEach((link) => {
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
  const navLinks = parentElement.querySelectorAll(".nav-link");
  navLinks.forEach((link) => {
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
  const regions = parentElement.querySelectorAll(".region");
  const infoPanel = document.querySelector(".info-panel-inner");
  regions.forEach((region) => {
    const tooltip = region.querySelector(".tooltip");
    if (tooltip !== null) {
      region.onclick = (event) => {
        const tooltip = event.currentTarget.querySelector(".tooltip");
        const newTooltip = tooltip.cloneNode(true);
        const info = infoPanel.querySelector(".info");
        infoPanel.replaceChild(newTooltip, info);
        newTooltip.classList.add("info");
        addClickHandlers(".info-panel .info");
        // TODO(srawlins): Add summary info to the top of this panel, so that
        //  users know what is being displayed.
      };
    }
  });
}

function debounce(fn, delay) {
  var timeout;
  return function() {
    var later = function() {
      timeout = null;
    };
    var callNow = !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, delay);
    if (callNow) fn.apply(this);
	};
};

// Resize the fixed-size and fixed-position navigation and information panels.
function resizePanels() {
  const navInner = document.querySelector(".nav-inner");
  // TODO(srawlins): I'm honestly not sure where 8 comes from; but without
  // `- 8`, the navigation is too tall and the bottom cannot be seen.
  const height = window.innerHeight - 8;
  navInner.style.height = height + "px";

  const infoInner = document.querySelector(".info-panel-inner");
  infoInner.style.height = height + "px";
}

document.addEventListener("DOMContentLoaded", (event) => {
  const path = window.location.pathname;
  const offset = getOffset(window.location.href);
  const lineNumber = getLine(window.location.href);
  const root = document.querySelector(".root").textContent;
  if (path !== "/" && path !== root) {
    // TODO(srawlins): replaceState?
    loadFile(path, offset, lineNumber,
        () => { pushState(path, offset, lineNumber) });
  }
  resizePanels();
  addClickHandlers(".nav-panel");
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

window.addEventListener("resize", (event) => {
  debounce(resizePanels, 200)();
});

// When scrolling the page, determine whether the navigation and information
// panels need to be fixed in place, or allowed to scroll.
window.addEventListener("scroll", (event) => {
  const navPanel = document.querySelector(".nav-panel");
  const navInner = navPanel.querySelector(".nav-inner");
  const infoPanel = document.querySelector(".info-panel");
  const infoInner = infoPanel.querySelector(".info-panel-inner");
  const innerTopOffset = navPanel.offsetTop;
  if (window.pageYOffset > innerTopOffset) {
    if (!navInner.classList.contains("fixed")) {
      navPanel.style.width = navPanel.offsetWidth + "px";
      // Subtract 6px for nav-inner's padding.
      navInner.style.width = (navInner.offsetWidth - 6) + "px";
      navInner.classList.add("fixed");
    }
    if (!infoInner.classList.contains("fixed")) {
      infoPanel.style.width = infoPanel.offsetWidth + "px";
      // Subtract 6px for info-panel-inner's padding.
      infoInner.style.width = (infoInner.offsetWidth - 6) + "px";
      infoInner.classList.add("fixed");
    }
  } else {
    if (navInner.classList.contains("fixed")) {
      navPanel.style.width = "";
      navInner.style.width = "";
      navInner.classList.remove("fixed");
    }
    if (infoInner.classList.contains("fixed")) {
      infoPanel.style.width = "";
      infoInner.style.width = "";
      infoInner.classList.remove("fixed");
    }
  }
  debounce(resizePanels, 200)();
});
''';
