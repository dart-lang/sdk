/**
 * Creates database.html, examples.html, and obsolete.html.
 */

library prettyPrint;

import 'dart:io';
import 'dart:json';
import 'util.dart';

String orEmpty(String str) {
  return str == null ? "" : str;
}

List<String> sortStringCollection(Collection<String> collection) {
  final out = <String>[];
  out.addAll(collection);
  out.sort((String a, String b) => a.compareTo(b));
  return out;
}

int addMissing(StringBuffer sb, String type, Map members) {
  int total = 0;
  /**
   * Add all missing members to the string output and return the number of
   * missing members.
   */
  void addMissingHelper(String propType) {
    Map expected = allProps[type][propType];
    if (expected != null) {
      for(final name in sortStringCollection(expected.keys)) {
        if (!members.containsKey(name)) {
          total++;
        sb.add("""
                <tr class="missing">
                  <td>$name</td>
                  <td></td>
                  <td>Could not find documentation for $propType</td>
                </tr>
    """);
        }
      }
    }
  }

  addMissingHelper('properties');
  addMissingHelper('methods');
  addMissingHelper('constants');
  return total;
}

void main() {
  // Database of code documentation.
  final Map<String, Map> database = JSON.parse(
      new File('output/database.filtered.json').readAsStringSync());

  // Types we have documentation for.
  matchedTypes = new Set<String>();
  int numMissingMethods = 0;
  int numFoundMethods = 0;
  int numExtraMethods = 0;
  int numGen = 0;
  int numSkipped = 0;
  final sbSkipped = new StringBuffer();
  final sbAllExamples = new StringBuffer();

  // Table rows for all obsolete members.
  final sbObsolete = new StringBuffer();
  // Main documentation file.
  final sb = new StringBuffer();

  // TODO(jacobr): switch to using a real template system instead of string
  // interpolation combined with StringBuffers.
  sb.add("""
<html>
  <head>
    <style type="text/css">
      body {
      	background-color: #eee;
      	margin: 10px;
      	font: 14px/1.428 "Lucida Grande", "Lucida Sans Unicode", Lucida,
            Arial, Helvetica, sans-serif;
      }

      .debug {
      	color: #888;
      }

      .compatibility, .links, .see-also, .summary, .members, .example {
      	border: 1px solid #CCC;
        margin: 5px;
        padding: 5px;
      }

      .type, #dart_summary {
        border: 1px solid;
        margin-top: 10px;
        margin-bottom: 10px;
        padding: 10px;
        overflow: hidden;
        background-color: white;
        -moz-box-shadow: 5px 5px 5px #888;
        -webkit-box-shadow: 5px 5px 5px #888;
        box-shadow: 5px 5px 5px #888;
      }

      #dart_summary {
      	border: 2px solid #00F;
        margin: 5px;
        padding: 5px;
      }

      th {
        background-color:#ccc;
        font-weight: bold;
      }

      tr:nth-child(odd) {
        background-color:#eee;
      }
      tr:nth-child(even) {
	      background-color:#fff;
	    }

      tr:nth-child(odd).unknown {
        background-color:#dd0;
      }
      tr:nth-child(even).unknown {
	      background-color:#ff0;
	    }

      tr:nth-child(odd).missing {
        background-color:#d88;
      }
      tr:nth-child(even).missing {
	      background-color:#faa;
	    }

	    li.unknown {
        color: #f00;
	    }

	    td, th {
	    	vertical-align: top;
	    }
    </style>
    <title>Doc Dump</title>
  </head>
  <body>
    <h1>Doc Dump</h1>
    <ul>
      <li><a href="#dart_summary">Summary</a></li>
    </li>
""");
  for (String type in sortStringCollection(database.keys)) {
  	final entry = database[type];
    if (entry == null || entry.containsKey('skipped')) {
      numSkipped++;
      sbSkipped.add("""
    <li id="$type">
      <a target="_blank" href="http://www.google.com/cse?cx=017193972565947830266%3Awpqsk6dy6ee&ie=UTF-8&q=$type">
        $type
      </a>
      --
      Title: ${entry == null ? "???" : entry["title"]} -- Issue:
      ${entry == null ? "???" : entry['cause']}
      --
      <a target="_blank" href="${entry == null ? "???" : entry["srcUrl"]}">
        scraped url
      </a>
    </li>""");
      continue;
    }
    matchedTypes.add(type);
    numGen++;
    StringBuffer sbSections = new StringBuffer();
    StringBuffer sbMembers = new StringBuffer();
    StringBuffer sbExamples = new StringBuffer();
    if (entry.containsKey("members")) {
      Map members = getMembersMap(entry);
      sbMembers.add("""
  	    <div class="members">
          <h3><span class="debug">[dart]</span> Members</h3>
          <table>
            <tbody>
              <tr>
                <th>Name</th><th>Description</th><th>IDL</th><th>Status</th>
              </tr>
""");
      for (String name in sortStringCollection(members.keys)) {
        Map memberData = members[name];
        bool unknown = !hasAny(type, name);
        StringBuffer classes = new StringBuffer();
        if (unknown) classes.add("unknown ");
        if (unknown) {
          numExtraMethods++;
        } else {
          numFoundMethods++;
        }

        final sbMember = new StringBuffer();

        if (memberData.containsKey('url')) {
          sbMember.add("""
		         <td><a href="${memberData['url']}">$name</a></td>
""");
        } else {
          sbMember.add("""
		         <td>$name</td>
""");
        }
        sbMember.add("""
		  	     <td>${memberData['help']}</td>
             <td>
               <pre>${orEmpty(memberData['idl'])}</pre>
             </td>
             <td>${memberData['obsolete'] == true ? "Obsolete" : ""}</td>
""");
        if (memberData['obsolete'] == true) {
          sbObsolete.add("<tr class='$classes'><td>$type</td>$sbMember</tr>");
        }
        sbMembers.add("<tr class='$classes'>$sbMember</tr>");
    	}

      numMissingMethods += addMissing(sbMembers, type, members);

      sbMembers.add("""
            </tbody>
          </table>
        </div>
""");
    }
    for (String sectionName in
        ["summary", "constructor", "compatibility", "specification",
         "seeAlso"]) {
      if (entry.containsKey(sectionName)) {
        sbSections.add("""
      <div class="$sectionName">
        <h3><span class="debug">[Dart]</span> $sectionName</h3>
        ${entry[sectionName]}
      </div>
""");
      }
    }
    if (entry.containsKey("links")) {
      sbSections.add("""
      <div class="links">
        <h3><span class="debug">[Dart]</span> Specification</h3>
        <ul>
""");
    	List links = entry["links"];
    	for (Map link in links) {
    	  sbSections.add("""
      <li><a href="${link['href']}">${link['title']}</a></li>
""");
      }
      sbSections.add("""
        </ul>
      </div>
""");
    }
    if (entry.containsKey("examples")) {
    	for (String example in entry["examples"]) {
  	  sbExamples.add("""
	    <div class="example">
	  	  <h3><span class="debug">[Dart]</span> Example</h3>
	  	  $example
	  	</div>
""");
      }
    }

    String title = entry['title'];
    if (title != type) {
      title = '<h4>Dart type: $type</h4><h2>$title</h2>';
    } else {
      title = '<h2>$title</h2>';
    }
    sb.add("""
    <div class='type' id="$type">
      <a href='${entry['srcUrl']}'>$title</a>
$sbSections
$sbExamples
$sbMembers
    </div>
""");
    if (sbExamples.length > 0) {
      sbAllExamples.add("""
    <div class='type' id="$type">
      <a href='${entry['srcUrl']}'>$title</a>
      $sbExamples
    </div>
""");
    }
  }

  for (String type in sortStringCollection(allProps.keys)) {
    if (!matchedTypes.contains(type) &&
        !database.containsKey(type)) {
      numSkipped++;
      sbSkipped.add("""
    <li class="unknown" id="$type">
      <a target="_blank" href="http://www.google.com/cse?cx=017193972565947830266%3Awpqsk6dy6ee&ie=UTF-8&q=$type">
        $type
      </a>
    </li>
""");
    }
  }

  sb.add("""
<div id="#dart_summary">
  <h2>Summary</h2>
  <h3>
    Generated docs for $numGen classes out of a possible
    ${allProps.keys.length}
  </h3>
  <h3>Found documentation for $numFoundMethods methods listed in WebKit</h3>
  <h3>
    Found documentation for $numExtraMethods methods not listed in WebKit
  </h3>
  <h3>
    Unable to find documentation for $numMissingMethods methods present in
    WebKit
  </h3>
  <h3>
    Skipped generating documentation for $numSkipped classes due to no
    plausible matching files
  </h3>
  <ul>
$sbSkipped
  </ul>
</div>
""");
  sb.add("""
  </body>
</html>
""");

  writeFileSync("output/database.html", sb.toString());

  writeFileSync("output/examples.html", """
<html>
  <head>
    <style type="text/css">
      body {
      	background-color: #eee;
      	margin: 10px;
      	font: 14px/1.428 "Lucida Grande", "Lucida Sans Unicode", Lucida, Arial,
            Helvetica, sans-serif;
      }

      .debug {
      	color: #888;
      }

      .example {
      	border: 1px solid #CCC;
        margin: 5px;
        padding: 5px;
      }

      .type {
        border: 1px solid;
        margin-top: 10px;
        margin-bottom: 10px;
        padding: 10px;
        overflow: hidden;
        background-color: white;
        -moz-box-shadow: 5px 5px 5px #888;
        -webkit-box-shadow: 5px 5px 5px #888;
        box-shadow: 5px 5px 5px #888;
      }
    </style>
    <title>All examples</title>
  </head>
  <body>
    <h1>All examples</h1>
$sbAllExamples
  </body>
 </html>
""");

  writeFileSync("output/obsolete.html", """
<html>
  <head>
    <style type="text/css">
      body {
        background-color: #eee;
        margin: 10px;
        font: 14px/1.428 "Lucida Grande", "Lucida Sans Unicode", Lucida,
            Arial, Helvetica, sans-serif;
      }

      .debug {
        color: #888;
      }

      .type {
        border: 1px solid;
        margin-top: 10px;
        margin-bottom: 10px;
        padding: 10px;
        overflow: hidden;
        background-color: white;
        -moz-box-shadow: 5px 5px 5px #888;
        -webkit-box-shadow: 5px 5px 5px #888;
        box-shadow: 5px 5px 5px #888;
      }
    </style>
    <title>Methods marked as obsolete</title>
  </head>
  <body>
    <h1>Methods marked as obsolete</h1>
    <table>
      <tbody>
        <tr>
          <th>Type</th>
          <th>Name</th>
          <th>Description</th>
          <th>IDL</th>
          <th>Status</th>
        </tr>
$sbObsolete
    </tbody>
   </table>
  </body>
 </html>
 """);
}
