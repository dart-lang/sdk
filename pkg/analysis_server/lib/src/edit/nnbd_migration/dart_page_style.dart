// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const dartPageStyle = r'''
body {
  background-color: black;
  color: white;
  font-family: 'Open Sans', sans-serif;
  /* This allows very small files to be displayed lower than the very top of the
   * screen.
   */
  margin: 8px;
  padding: 0.5em;
}

h1 {
  font-size: 2.4em;
  font-weight: 600;
  margin: 0;
}

h2#unit-name {
  font-size: 1.2em;
  font-weight: 600;
  margin: 0;
}

.horizontal {
  display: flex;
  flex-wrap: wrap;
}

.nav-link {
  cursor: pointer;
}

.nav {
  background-color: #282b2e;
  flex-basis: 0;
  flex: 0 1 auto;
  font-size: 14px;
  /* 10px to match exact top margin of .content.
   * 0.8em to pair with the -0.5em margin of .content, producing a net margin
   * between the two of 0.3em.
   */
  margin: 10px 0.8em 0 0;
}

.nav :first-child {
  margin-top: 0;
}

.nav-inner {
  background-color: #282b2e;
  overflow: auto;
  padding: 7px 0 7px 7px;
}

.nav-inner.fixed {
  position: fixed;
  top: 0;
}

.nav-inner .root {
  margin: 0;
}

.nav-inner .nav-link {
  color: #33ccff;
  margin-left: 1em;
}

.nav-inner .selected-file {
  color: white;
  cursor: inherit;
  font-weight: 600;
  text-decoration: none;
}

.content {
  flex: 1 1 700px;
  font-family: monospace;
  /* Vertical margin around content. */
  margin: 10px 0;
  /* Offset the margin introduced by the absolutely positioned child div. */
  margin-left: -0.5em;
  position: relative;
  white-space: pre;
}

.code {
  left: 0.5em;
  /* Increase line height to make room for borders in non-nullable type
   * regions.
   */
  line-height: 1.3;
  min-height: 600px;
  padding-left: 62px;
  position: inherit;
  z-index: 100;
}

.code.hljs {
  background-color: inherit;
}

.code .nav-link {
  color: inherit;
  text-decoration-line: none;
}

.code .nav-link:visited {
  color: inherit;
  text-decoration-line: none;
}

.code .nav-link:hover {
  text-decoration-line: underline;
  font-weight: 600;
}

.regions {
  background-color: #282b2e;
  padding: 0.5em 0 0.5em 0.5em;
  position: absolute;
  left: 0.5em;
  top: 0;
}

.regions table {
  border-spacing: 0;
}

.regions td {
  border: none;
  /* The content of the regions is not visible; the user instead will see the
   * highlighted copy of the content. */
  color: rgba(255, 255, 255, 0);
  line-height: 1.3;
  padding: 0;
  white-space: pre;
}

.regions td:empty:after {
  content: "\00a0";
}

.regions tr.highlight td:last-child {
  background-color: rgba(0, 0, 128, 0.5);
}

.regions td.line-no {
  border-right: solid #282b2e 2px;
  color: #999999;
  display: inline-block;
  padding-right: 4px;
  text-align: right;
  visibility: visible;
  width: 50px;
}

.regions tr.highlight td.line-no {
  border-right: solid #0000ff 2px;
}

.region {
  cursor: default;
  display: inline-block;
  position: relative;
  visibility: visible;
  z-index: 200;
}

.region.fix-region {
  /* Green means this region was added. */
  background-color: #ccffcc;
  color: #003300;
}

.region.non-nullable-type-region {
  background-color: rgba(0, 0, 0, 0.3);
  border-bottom: solid 2px #cccccc;
  /* Invisible text; use underlying highlighting. */
  color: rgba(0, 0, 0, 0);
  /* Reduce line height to make room for border. */
  line-height: 1;
}

.region .tooltip {
  background-color: #EEE;
  border: solid 2px #999;
  color: #333;
  cursor: auto;
  font-family: sans-serif;
  font-size: 0.8em;
  left: 0;
  margin-left: 0;
  opacity: 0%;
  padding: 1px;
  position: absolute;
  top: 100%;
  transition: visibility 0s linear 500ms, opacity 200ms ease 300ms;
  visibility: hidden;
  white-space: normal;
  width: 400px;
  z-index: 1;
}

.region .tooltip > * {
  margin: 1em;
}

.region:hover .tooltip {
  opacity: 100%;
  transition: opacity 150ms;
  visibility: visible;
}

.target {
  background-color: #FFFF99;
  color: black;
  position: relative;
  visibility: visible;
}

.footer {
  padding: 8px 8px 100px 8px;
}
''';
