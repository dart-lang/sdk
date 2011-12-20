// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Dynamic stylesheet injector with inline resources */
class DARTestCss {

  /** This fuction injects the stylesheet text in the document */
  static void inject(Document doc, bool inAppMode){
    HTMLStyleElement style = doc.createElement('style');
    style.type = 'text/css';
    if(inAppMode) {
      style.textContent = _commonStyles + _inAppStyles;
    } else {
      style.textContent = _commonStyles + _fullAppStyles;
    }
    doc.head.appendChild(style);
  }
  
  static String _commonStyles = '''
  
  /* Dartest Common Styles */
  
    .dt-hide {
      display: none;
    }
  
    .dt-show {
      display: block;
    }
    
    .dt-tab ul {
      list-style: none;
      padding: 5px 0;
      margin: 0;
      background-color: #EEE;
    }

    .dt-tab li {
      display: inline;
      border: solid #BBB;
      border-width: 1px 1px 0 1px;
      margin: 0 -1px 0 0;
      padding: 5px 10px;
      cursor: pointer;
    }

    .dt-tab li:hover {
      background-color: #BBB;
    }

    .dt-tab-selected {
      background-color: #FFF;
    }
    
    .dt-results {
      width: 100%;
      border-collapse: collapse;
      border: solid 1px #777;
      margin: 25px 0px 0px 0px;
    }
    
    .dt-results th,td {
      border: solid 1px #777;
      padding: 2px;
      font-size: 12px;
    }
    
    .dt-results thead {
      background-color: #DDD;
    }
    
    .dt-result-row {
      background-color: #EEE;
      cursor: pointer;
    }
    
    .dt-result-row:hover {
      text-decoration: underline;
      font-weight: bold;
    }
    
    .dt-main::-webkit-scrollbar {
      width: 8px;
      height: 8px;
    }
    
    .dt-main::-webkit-scrollbar-track {
      -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.3); 
      -webkit-border-radius: 10px;
      border-radius: 10px;
    }
    
    .dt-main::-webkit-scrollbar-thumb {
      -webkit-border-radius: 10px;
      border-radius: 10px;
      background: #888; 
      -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.5); 
    }
    
    .dt-toolbar {
      width: 150px;
      padding: 5px;
      float: left;
    }
    
    .dt-button {
      width: 24px;
      height: 24px;
      border-radius: 12px;
      -moz-border-radius: 12px;
      -webkit-border-radius: 12px;
      -o-border-radius: 12px;
      background-color: #777;
      border: 1px solid #ABB;
      cursor: pointer;
      margin-right: 5px;
      color: white;
      font-weight: bold;
    }

    .dt-button-disabled {
      width: 24px;
      height: 24px;
      border-radius: 12px;
      -moz-border-radius: 12px;
      -webkit-border-radius: 12px;
      -o-border-radius: 12px;
      background-color: #AAA;
      border: 1px solid #ABB;
      cursor: pointer;
      margin-right: 5px;
      color: white;
    }

    .dt-button:hover {
      background-color: #555;
    }
    
    .dt-load {
      text-indent: -2px;
      padding-bottom: 2px;
      vertical-align: 2px;
    }

    .dt-progressbar { 
      position: relative;
      margin: 0px;
      clear: both;
    }

    .dt-progressbar span {
      display: block;
      height: 20px;
      position: absolute;
      overflow: hidden;
      background-color: #eee;
      -moz-border-radius: 4px;
      -webkit-border-radius: 4px;
      border-radius: 4px;
      -webkit-box-shadow: 
          inset 0 2px 9px  rgba(255,255,255,0.3),
          inset 0 -2px 6px rgba(0,0,0,0.4);
      -moz-box-shadow: 
          inset 0 2px 9px  rgba(255,255,255,0.3),
          inset 0 -2px 6px rgba(0,0,0,0.4);
      box-shadow: 
          inset 0 2px 9px  rgba(255,255,255,0.3),
          inset 0 -2px 6px rgba(0,0,0,0.4);
    }

    .dt-progressbar span.green {
      background-color: #2bc253;
    }

    .dt-progressbar span.orange {
      background-color: #f1a165;
    }

    .dt-progressbar span.red {
      background-color: #ff5555;
    }

    .dt-status {
      margin: 10px 0; 
      padding: 0;
      font-weight: bold;
    }
    .dt-status dt {
      float: left;
    }

    .dt-status dd {
      float: left;
      width: 20px;
      margin-left: 2px;
    }
    
    .dt-pass {
      background-color: green;
    }
    
    .dt-fail {
      background-color: red;
    }
    
    .dt-error {
      background-color: orange;
    }
    
  ''';
  
  static String _inAppStyles = '''
  /* Dartest InApp Styles */
    .dt-container {
      font-family: Sans-serif,Verdana;
      background: #111;
      position: fixed;
      bottom: 0px;
      right: 0px;
      border: 1px solid black;
      z-index: 999;
    }
  
    .dt-main {
      background: #FCFCFC;
      width: 355px;
      height: 350px;
      overflow-y: auto;
      padding: 0 5px;
      font-size: 12px;
    }
    
    .dt-header {
      background: #777;
      height: 20px;
      width: 361px;
      padding: 2px;
      color: white;
      font-weight: bold;
    }

    .dt-header img {
      float: right;
      padding: 2px;
      cursor: pointer;
      height: 16px;
      width: 16px;
    }

    .dt-header img:hover { 
      background-color: #555;
    }

    .dt-header-close {
      background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB9sKBhQGEmU63FMAAABrSURBVCjPnZGxEcAgDAN9uZSUKdgxA1BmAMZiCMb5FKEAnziSqLMl2SCb/QGwAxmIgotA8s3Mg9qbmrg27rQJUVvd9woQ1OreNBdPTFK8LfI4zOzV9OL/tBIHFYSKdXizMyV/uEulIQ/3BTexxvELK3jXZwAAAABJRU5ErkJggg==) center no-repeat;
    }

    .dt-header-pop {
      background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB9sKBhQFLmF48xcAAABkSURBVCjPY2CgFPz//1/j////z/9jASRrImSTP21sQFN8/f///w4wPjGKJZDF0RWbICk+/P//fx50w5A5Nv////+MSzG6ycQrZmBgYEJiH2FgYPBkZGT8Qkzsmvz//5+DmJQAAEk50CjzCaicAAAAAElFTkSuQmCC) center no-repeat;
    }

    .dt-header-min {
      background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB9sKBhQ6F2ajUSMAAAAgSURBVCjPY2AYBYMBMDIwMDD8////P1GKGRkZmQafHwD5tAQE/3DfbwAAAABJRU5ErkJggg==) center no-repeat;
    }

    .dt-header-max {
      background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB9sKBhQ7EOHc9cEAAAAgSURBVCjPY2AgETAyMDAw/P///z9RihkZGZkYRsHIAABaEwQEd0uv8QAAAABJRU5ErkJggg==) center no-repeat;
    }
  ''';
  
  static String _fullAppStyles = '''
    body {
      margin: 0;
    }
  
   .dt-container {
      font-family: Sans-serif,Verdana;
      background: #111;
      border: 1px solid black;
      z-index: 999;
    }
  
    .dt-main {
      background: #FCFCFC;
      overflow-y: auto;
      padding: 0 5px;
      font-size: 12px;
      position: absolute;
      top: 29px;
      bottom: 0;
      left: 0;
      right: 0;
    }
    
    .dt-minimize {
      position: absolute;
      top: 5px;
      right: 5px;
      cursor: pointer;
    }
  ''';
  
  static String _fullAppWindowFeatures = 'width=600,height=750';
  
 }
