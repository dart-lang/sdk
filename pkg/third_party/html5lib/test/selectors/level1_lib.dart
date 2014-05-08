/// Test for the Selectors API ported from
/// <https://github.com/w3c/web-platform-tests/tree/master/selectors-api>
///
/// Note: tried to make minimal changes possible here. Hence some oddities such
/// as [test] arguments having a different order, long lines, etc.
///
/// As usual with ports: being faithful to the original style is more important
/// than other style goals, as it reduces friction to integrating changes
/// from upstream.
library html5lib.test.selectors.level1_lib;

import 'package:html5lib/dom.dart';
import 'package:unittest/unittest.dart' as unittest;

Document doc;

/*
 * Create and append special elements that cannot be created correctly with HTML markup alone.
 */
setupSpecialElements(parent) {
  // Setup null and undefined tests
  parent.append(doc.createElement("null"));
  parent.append(doc.createElement("undefined"));

  // Setup namespace tests
  var anyNS = doc.createElement("div");
  var noNS = doc.createElement("div");
  anyNS.id = "any-namespace";
  noNS.id = "no-namespace";

  var div;
  div = [doc.createElement("div"),
         doc.createElementNS("http://www.w3.org/1999/xhtml", "div"),
         doc.createElementNS("", "div"),
         doc.createElementNS("http://www.example.org/ns", "div")];

  div[0].id = "any-namespace-div1";
  div[1].id = "any-namespace-div2";
  div[2].attributes["id"] = "any-namespace-div3"; // Non-HTML elements can't use .id property
  div[3].attributes["id"] = "any-namespace-div4";

  for (var i = 0; i < div.length; i++) {
    anyNS.append(div[i]);
  }

  div = [doc.createElement("div"),
         doc.createElementNS("http://www.w3.org/1999/xhtml", "div"),
         doc.createElementNS("", "div"),
         doc.createElementNS("http://www.example.org/ns", "div")];

  div[0].id = "no-namespace-div1";
  div[1].id = "no-namespace-div2";
  div[2].attributes["id"] = "no-namespace-div3"; // Non-HTML elements can't use .id property
  div[3].attributes["id"] = "no-namespace-div4";

  for (var i = 0; i < div.length; i++) {
    noNS.append(div[i]);
  }

  parent.append(anyNS);
  parent.append(noNS);
}

/*
 * Check that the querySelector and querySelectorAll methods exist on the given Node
 */
interfaceCheck(type, obj) {
  test(() {
    var q = obj.querySelector is Function;
    assert_true(q, type + " supports querySelector.");
  }, type + " supports querySelector");

  test(() {
    var qa = obj.querySelectorAll is Function;
    assert_true( qa, type + " supports querySelectorAll.");
  }, type + " supports querySelectorAll");

  test(() {
    var list = obj.querySelectorAll("div");
    // TODO(jmesserly): testing List<Element> for now. It should return an
    // ElementList which has extra properties. Needed for dart:html compat.
    assert_true(list is List<Element>, "The result should be an instance of a NodeList");
  }, type + ".querySelectorAll returns NodeList instance");
}

/*
 * Verify that the NodeList returned by querySelectorAll is static and and that a new list is created after
 * each call. A static list should not be affected by subsequent changes to the DOM.
 */
verifyStaticList(type, root) {
  var pre, post, preLength;

  test(() {
    pre = root.querySelectorAll("div");
    preLength = pre.length;

    var div = doc.createElement("div");
    (root is Document ? root.body : root).append(div);

    assert_equals(pre.length, preLength, "The length of the NodeList should not change.");
  }, type + ": static NodeList");

  test(() {
    post = root.querySelectorAll("div");
    assert_equals(post.length, preLength + 1, "The length of the new NodeList should be 1 more than the previous list.");
  }, type + ": new NodeList");
}

/*
 * Verify handling of special values for the selector parameter, including stringification of
 * null and undefined, and the handling of the empty string.
 */
runSpecialSelectorTests(type, root) {
  // Dart note: changed these tests because we don't have auto conversion to
  // String like JavaScript does.
  test(() { // 1
    assert_equals(root.querySelectorAll('null').length, 1, "This should find one element with the tag name 'NULL'.");
  }, type + ".querySelectorAll null");

  test(() { // 2
    assert_equals(root.querySelectorAll('undefined').length, 1, "This should find one element with the tag name 'UNDEFINED'.");
  }, type + ".querySelectorAll undefined");

  test(() { // 3
    assert_throws((e) => e is NoSuchMethodError, () {
      root.querySelectorAll();
    }, "This should throw a TypeError.");
  }, type + ".querySelectorAll no parameter");

  test(() { // 4
    var elm = root.querySelector('null');
    assert_not_equals(elm, null, "This should find an element.");
    // TODO(jmesserly): change "localName" back to "tagName" once implemented.
    assert_equals(elm.localName.toUpperCase(), "NULL", "The tag name should be 'NULL'.");
  }, type + ".querySelector null");

  test(() { // 5
    var elm = root.querySelector('undefined');
    assert_not_equals(elm, 'undefined', "This should find an element.");
    // TODO(jmesserly): change "localName" back to "tagName" once implemented.
    assert_equals(elm.localName.toUpperCase(), "UNDEFINED", "The tag name should be 'UNDEFINED'.");
  }, type + ".querySelector undefined");

  test(() { // 6
    assert_throws((e) => e is NoSuchMethodError, () {
      root.querySelector();
    }, "This should throw a TypeError.");
  }, type + ".querySelector no parameter");

  test(() { // 7
    var result = root.querySelectorAll("*");
    var i = 0;
    traverse(root, (elem) {
      if (!identical(elem, root)) {
        assert_equals(elem, result[i], "The result in index $i should be in tree order.");
        i++;
      }
    });
  }, type + ".querySelectorAll tree order");
}

/*
 * Execute queries with the specified valid selectors for both querySelector() and querySelectorAll()
 * Only run these tests when results are expected. Don't run for syntax error tests.
 */
 runValidSelectorTest(type, root, selectors, testType, docType) {
  var nodeType = "";
  switch (root.nodeType) {
    case Node.DOCUMENT_NODE:
      nodeType = "document";
      break;
    case Node.ELEMENT_NODE:
      nodeType = root.parentNode != null ? "element" : "detached";
      break;
    case Node.DOCUMENT_FRAGMENT_NODE:
      nodeType = "fragment";
      break;
    default:
      throw new StateError("Reached unreachable code path.");
  }

  for (var i = 0; i < selectors.length; i++) {
    var s = selectors[i];
    var n = s["name"];
    var q = s["selector"];
    var e = s["expect"];

    if ((s["exclude"] is! List || (s["exclude"].indexOf(nodeType) == -1 && s["exclude"].indexOf(docType) == -1))
     && (s["testType"] & testType != 0) ) {
      //console.log("Running tests " + nodeType + ": " + s["testType"] + "&" + testType + "=" + (s["testType"] & testType) + ": " + JSON.stringify(s))
      var foundall, found;

      test(() {
        foundall = root.querySelectorAll(q);
        assert_not_equals(foundall, null, "The method should not return null.");
        assert_equals(foundall.length, e.length, "The method should return the expected number of matches.");

        for (var i = 0; i < e.length; i++) {
          assert_not_equals(foundall[i], null, "The item in index $i should not be null.");
          assert_equals(foundall[i].attributes["id"], e[i], "The item in index $i should have the expected ID.");
          assert_false(foundall[i].attributes.containsKey("data-clone"), "This should not be a cloned element.");
        }
      }, type + ".querySelectorAll: " + n + ": " + q);

      test(() {
        found = root.querySelector(q);

        if (e.length > 0) {
          assert_not_equals(found, null, "The method should return a match.");
          assert_equals(found.attributes["id"], e[0], "The method should return the first match.");
          assert_equals(found, foundall[0], "The result should match the first item from querySelectorAll.");
          assert_false(found.attributes.containsKey("data-clone"), "This should not be annotated as a cloned element.");
        } else {
          assert_equals(found, null, "The method should not match anything.");
        }
      }, type + ".querySelector: " + n + ": " + q);
    } else {
      //console.log("Excluding for " + nodeType + ": " + s["testType"] + "&" + testType + "=" + (s["testType"] & testType) + ": " + JSON.stringify(s))
    }
  }
}

/*
 * Execute queries with the specified invalid selectors for both querySelector() and querySelectorAll()
 * Only run these tests when errors are expected. Don't run for valid selector tests.
 */
 runInvalidSelectorTest(type, root, selectors) {
  for (var i = 0; i < selectors.length; i++) {
    var s = selectors[i];
    var n = s["name"];
    var q = s["selector"];

    // Dart note: FormatException seems a reasonable mapping of SyntaxError
    test(() {
      assert_throws((e) => e is FormatException, () {
        root.querySelector(q);
      });
    }, type + ".querySelector: " + n + ": " + q);

    test(() {
      assert_throws((e) => e is FormatException, () {
        root.querySelectorAll(q);
      });
    }, type + ".querySelectorAll: " + n + ": " + q);
  }
}

 traverse(Node elem, fn) {
  if (elem.nodeType == Node.ELEMENT_NODE) {
    fn(elem);
  }

  // Dart note: changed this since html5lib doens't support nextNode yet.
  for (var node in elem.nodes) {
    traverse(node, fn);
  }
}


test(Function body, String name) => unittest.test(name, body);

assert_true(value, String reason) =>
    unittest.expect(value, true, reason: reason);

assert_false(value, String reason) =>
    unittest.expect(value, false, reason: reason);

assert_equals(x, y, reason) =>
    unittest.expect(x, y, reason: reason);

assert_not_equals(x, y, reason) =>
    unittest.expect(x, unittest.isNot(y), reason: reason);

assert_throws(exception, body, [reason]) =>
    unittest.expect(body, unittest.throwsA(exception), reason: reason);
