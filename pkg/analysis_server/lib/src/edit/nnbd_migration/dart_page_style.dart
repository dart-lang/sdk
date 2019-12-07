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
  margin-bottom; 100px;
  padding: 0.5em;
}

h1 {
  font-size: 2.4em;
  font-weight: 600;
  margin: 0;
}

h2 {
  font-size: 1.2em;
  font-weight: 600;
  margin: 0;
}

.horizontal {
  display: flex;
  flex-wrap: wrap-reverse;
}

.content {
  flex: 1;
  font-family: monospace;
  /* Vertical margin around content. */
  margin: 10px 0;
  /* Offset the margin introduced by the absolutely positioned child div. */
  margin-left: -0.5em;
  min-width: 900px;
  position: relative;
  white-space: pre;
}

.code {
  left: 0.5em;
  /* Increase line height to make room for borders in non-nullable type
   * regions.
   */
  line-height: 1.3;
  padding-left: 60px;
  position: inherit;
}

.code a:link {
  color: inherit;
  text-decoration-line: none;
}

.code a:visited {
  color: inherit;
  text-decoration-line: none;
}

.code a:hover {
  text-decoration-line: underline;
  font-weight: 600;
}

.regions {
  padding: 0.5em;
  position: absolute;
  left: 0.5em;
  top: 0;
  /* The content of the regions is not visible; the user instead will see the
   * highlighted copy of the content. */
  visibility: hidden;
}

.regions table {
  border-spacing: 0;
}

.regions td {
  border: none;
  line-height: 1.3;
  padding: 0;
  white-space: pre;
}

.regions td:empty:after {
  content: "\00a0";
}

.regions td.line-no {
  color: #999999;
  display: inline-block;
  padding-right: 4px;
  text-align: right;
  visibility: visible;
  width: 50px;
}

.region {
  cursor: default;
  display: inline-block;
  position: relative;
  visibility: visible;
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

.nav {
  background-color: #282b2e;
  flex-basis: 0;
  flex-grow: 1;
  font-size: 14px;
  /* 10px to match exact top margin of .content.
   * 0.8em to pair with the -0.5em margin of .content, producing a net margin
   * between the two of 0.3em.
   */
  margin: 10px 0.8em;
  padding: 0.5em;
}

.nav :first-child {
  margin-top: 0;
}

.nav .root {
  margin: 0;
}

.nav .file-name {
  margin-left: 1em;
}

.nav a:link {
  color: #33ccff;
}

.nav a:visited {
  color: #33ccff;
}

.nav .selected-file {
  font-weight: 600;
}

.target {
  background-color: #FFFF99;
  position: relative;
  visibility: visible;
}
''';
