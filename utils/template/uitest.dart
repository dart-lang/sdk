// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:html');
#import('template.dart');
#import('../lib/file_system_memory.dart');

String currSampleTemplate;

void changeTemplate() {
  final Document doc = window.document;
  final SelectElement samples = doc.query('#templateSamples');
  final TextAreaElement template = doc.query('#template');
  template.value = sample(samples.value);
}

String sample(String sampleName) {
  final String each = '\${#each';
  final String endEach = '\${/each}';
  final String with = '\${#with';
  final String endWith = '\${/with}';

  final String simpleTemplate = @'''
template NameEntry(String name, int age) {
  <div var=topDiv attr="test" attr1=test1 attr2='test2' attr3=test3>
    <span var=spanElem>${name}</span>
    <span>-</span>
    <span>${age}</span>
  </div>
}
  ''';

  final String simpleTemplate2 = @'''
template NameEntry(String name, int age) {
  <div var=topDiv attr="test" attr1=test1 attr2='test2' attr3=test3>
    <h1>
      <h2>
        <h3>
          <span var=spanElem>${name}</span>
          <span>-</span>
          <span>${age}</span>
        </h3>
      </h2>
    </h1>
  </div>
}
  ''';

  final String simpleTemplateCSS = @'''
template NameEntry(String name, int age) {
  css {
    .foo {
      left: 10px;
    }
  }
  <div var=topDiv attr="test" attr1=test1 attr2='test2' attr3=test3>
    <span var=spanElem>${name}</span>
    <span>-</span>
    <span>${age}</span>
  </div>
}
  ''';


  final String eachTemplate = @'''
template Applications(var products) {
  <div>
    ${each} products
      <div>
        <span>${name}</span>
        <span>-</span>
        <span>${users}</span>
      </div>
    ${endEach}
  </div>
}
  ''';

  final String withTemplate = @'''
template Product(Person person) {
  <div>
    ${with} person
      <div>
        <span>${name}</span>
        <span>-</span>
        <span>${age}</span>
      </div>
    ${endWith}
  </div>
}
  ''';

  final String withTemplate2 = @'''
template Product(Person person) {
  <div>
    <span var=a1>
      <h1>
        ${with} person
          <div>
            <span>${name}</span>
            <span>-</span>
            <span>${age}</span>
          </div>
        ${endWith}
      </h1>
    </span>
  </div>
}
  ''';

  final String complexTemplate = @'''
template ProductsForPerson(Person person, var products) {
  <div>
    ${with} person person
      <div>
        <span>${person.name}</span>
        <span>-</span>
        <span>${person.age}</span>
      </div>
      ${each} products product
        <div>
          <span>product=${product.name},users=${product.users}</span>
        </div>
      ${endEach}
    ${endWith}
  </div>
}
  ''';

  final String complexTemplate2 = @'''
template ProductsForPerson(Person person, var products) {
  <div>
    ${with} person person
      <div>
        <span>${person.name}</span>
        <span>-</span>
        <span>${person.age}</span>
      </div>
      <div>
        ${each} products product
          <span>product=${product.name},users=${product.users}</span>
        ${endEach}
      </div>
    ${endWith}
  </div>
}
  ''';

  final String complexTemplate3 = @'''
template ProductsForPerson(Person person, var products) {
  css {
    .sales-item {
      font-family: arial;
      background-color: lightgray;
      margin-left: 10px;
      border-bottom: 1px solid white;
    }
    .ytd-sales {
      position: absolute;
      left: 100px;
    }
  }
  <div>
    ${with} person person
      <div>
        <span>${person.name}</span>
        <span>-</span>
        <span>${person.age}</span>
      </div>
      <div>
        ${each} products product
          <div>product=${product.name},users=${product.users}</div>
          ${each} products.sales sale
            <div class="sales-item">
              <span>${sale.country}</span>
              <span class="ytd-sales">\$${sale.yearly}</span>
            </div>
          ${endEach}
        ${endEach}
      </div>
    ${endWith}
  </div>
}


template NameEntry(String name, int age) {
  css {
    .name-item {
      font-size: 18pt;
      font-weight: bold;
    }
  }
  <div var=topDiv class="name-item" attr="test" attr1=test1 attr2='test2' attr3=test3>
    <span var=spanElem>${name}</span>
    <span> - </span>
    <span>${age}</span>
  </div>
}
''';

  // Test #each in a #each where the nested #each is a top-level child of the
  // outer #each.
  final String complexTemplate4 = @'''
template DivisionSales(var divisions) {
  <div>
    ${each} divisions division
      <div>
        <span>${division.name}</span>
        <span>-</span>
        <span>${division.id}</span>
      </div>
      <div>
        ${each} divisions.products divProduct
          <div>
            <span var=productItem>&#9654;</span>
            <span>Product</span>
            <span>${divProduct.name}</span>
            <span>${divProduct.users}&nbsp;users</span>
          </div>
          ${each} products.sales sale
            <div>
              <span>${sale.country}</span>
              <span>\$${sale.yearly}</span>
            </div>
          ${endEach}
        ${endEach}
      </div>
    ${endEach}
  </div>
}
''';


  final String realWorldList = @'''
template DivisionSales(var divisions) {
  css {
    .division-item {
      background-color: #bbb;
      border-top: 2px solid white;
      line-height: 20pt;
      padding-left: 5px;
    }
    .product-item {
      background-color: lightgray;
      margin-left: 10px;
      border-top: 2px solid white;
      line-height: 20pt;
    }
    .product-title {
      position: absolute;
      left: 45px;
    }
    .product-name {
      font-weight: bold;
      position: absolute;
      left: 100px;
    }
    .product-users {
      position: absolute;
      left: 150px;
      font-style: italic;
      color: gray;
      width: 110px;
    }
    .expand-collapse {
      margin-left: 5px;
      margin-right: 5px;
      vertical-align: top;
      cursor: pointer;
    }
    .expand {
      font-size: 9pt;
    }
    .collapse {
      font-size: 8pt;
    }
    .show-sales {
      display: inherit;
    }
    .hide-sales {
      display: none;
    }
    .sales-item {
      font-family: arial;
      background-color: lightgray;
      margin-left: 10px;
      border-top: 1px solid white;
      line-height: 18pt;
      padding-left: 5px;
    }
    .ytd-sales {
      position: absolute;
      left: 100px;
    }
  }
  <div>
    ${each} divisions division
      <div class="division-item">
        <span>${division.name}</span>
        <span>-</span>
        <span>${division.id}</span>
      </div>
      <div>
        ${each} divisions.products divProduct
          <div class="product-item">
            <span var=productZippy class="expand-collapse expand">&#9660;</span>
            <span class='product-title'>Product</span>
            <span class="product-name">${divProduct.name}</span>
            <span class="product-users" align=right>${divProduct.users
              }&nbsp;users</span>
            <div class="show-sales">
              ${each} products.sales sale
                <div class="sales-item">
                  <span>${sale.country}</span>
                  <span class="ytd-sales">\$${sale.yearly}</span>
                </div>
              ${endEach}
            </div>
          </div>
        ${endEach}
      </div>
    ${endEach}
  </div>
}

template Header(String company, Date date) {
  css {
    .header {
      background-color: slateGray;
      font-family: arial;
      color: lightgray;
      font-weight: bold;
      padding-top: 20px;
    }
  }
  <div class='header' align=center>
    <h2>${company}</h2>
    <div align=right>${date}</div>
  </div>
}
''';

  switch (sampleName) {
    case "simple":
      return simpleTemplate;
    case "simple2":
      return simpleTemplate2;
    case "simpleCSS":
      return simpleTemplateCSS;
    case "with":
      return withTemplate;
    case "with2":
      return withTemplate2;
    case "list":
      return eachTemplate;
    case "complex":
      return complexTemplate;
    case "complex2":
      return complexTemplate2;
    case "complex3":
      return complexTemplate3;
    case "complex4":
      return complexTemplate4;
    case "realWorldList":
      return realWorldList;
    default:
      print("ERROR: Unknown sample template");
  }
}

void runTemplate([bool debug = false, bool parseOnly = false]) {
  final Document doc = window.document;
  final TextAreaElement dartClass = doc.query("#dart");
  final TextAreaElement template = doc.query('#template');
  final TableCellElement validity = doc.query('#validity');
  final TableCellElement result = doc.query('#result');

  bool templateValid = true;
  StringBuffer dumpTree = new StringBuffer();
  StringBuffer code = new StringBuffer();
  String htmlTemplate = template.value;

  if (debug) {
    try {
      List<Template> templates = templateParseAndValidate(htmlTemplate);
      for (var tmpl in templates) {
        dumpTree.add(tmpl.toDebugString());
      }

      // Generate the Dart class(es) for all template(s).
      // Pass in filename of 'foo' for testing in UITest.
      code.add(Codegen.generate(templates, 'foo'));
    } catch (htmlException) {
      // TODO(terry): TBD
      print("ERROR unhandled EXCEPTION");
    }
  }

/*
  if (!debug) {
    try {
      cssParseAndValidate(cssExpr, cssWorld);
    } catch (cssException) {
      templateValid = false;
      dumpTree = cssException.toString();
    }
  } else if (parseOnly) {
    try {
      Parser parser = new Parser(new lang.SourceFile(
          lang.SourceFile.IN_MEMORY_FILE, cssExpr));
      Stylesheet stylesheet = parser.parse();
      StringBuffer stylesheetTree = new StringBuffer();
      String prettyStylesheet = stylesheet.toString();
      stylesheetTree.add("${prettyStylesheet}\n");
      stylesheetTree.add("\n============>Tree Dump<============\n");
      stylesheetTree.add(stylesheet.toDebugString());
      dumpTree = stylesheetTree.toString();
    } catch (cssParseException) {
      templateValid = false;
      dumpTree = cssParseException.toString();
    }
  } else {
    try {
      dumpTree = cssParseAndValidateDebug(cssExpr, cssWorld);
    } catch (cssException) {
      templateValid = false;
      dumpTree = cssException.toString();
    }
  }
*/

  final bgcolor = templateValid ? "white" : "red";
  final color = templateValid ? "black" : "white";
  final valid = templateValid ? "VALID" : "NOT VALID";
  String resultStyle = "resize: none; margin: 0; height: 100%; width: 100%;"
    "padding: 5px 7px;";

  result.innerHTML = '''
    <textarea style="${resultStyle}">${dumpTree.toString()}</textarea>
  ''';

  dartClass.value = code.toString();
}

void main() {
  final element = new Element.tag('div');

  element.innerHTML = '''
    <table style="width: 100%; height: 100%;">
      <tbody>
        <tr>
          <td style="vertical-align: top; width: 50%; padding-right: 7px;">
            <table style="height: 100%; width: 100%;" cellspacing=0 cellpadding=0 border=0>
              <tbody>
                <tr style="vertical-align: top; height: 1em;">
                  <td>
                    <span style="font-weight:bold;">Generated Dart</span>
                  </td>
                </tr>
                <tr>
                  <td>
                    <textarea id="dart" style="resize: none; width: 100%; height: 100%; padding: 5px 7px;"></textarea>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
          <td>
            <table style="width: 100%; height: 100%;" cellspacing=0 cellpadding=0 border=0>
              <tbody>
                <tr style="vertical-align: top; height: 50%;">
                  <td>
                    <table style="width: 100%; height: 100%;" cellspacing=0 cellpadding=0 border=0>
                      <tbody>
                        <tr>
                          <td>
                            <span style="font-weight:bold;">HTML Template</span>
                          </td>
                        </tr>
                        <tr style="height: 100%;">
                          <td>
                            <textarea id="template" style="resize: none; width: 100%; height: 100%; padding: 5px 7px;">${sample("simple")}</textarea>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>

                <tr style="vertical-align: top; height: 50px;">
                  <td>
                    <table>
                      <tbody>
                        <tr>
                          <td>
                            <button id=generate>Generate</button>
                          </td>
                          <td align="right">
                            <select id=templateSamples>
                              <option value="simple">Simple Template</option>
                              <option value="simple2">Simple Template #2</option>
                              <option value="simpleCSS">Simple Template w/ CSS</option>
                              <option value="with">With Template</option>
                              <option value="with2">With Template #2</option>
                              <option value="list">List Template</option>
                              <option value="complex">Complex Template</option>
                              <option value="complex2">Complex Template #2</option>
                              <option value="complex3">Complex Template #3 w/ CSS</option>
                              <option value="complex4">Complex Template #4</option>
                              <option value="realWorldList">Real world</option>
                            </select>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>

                <tr style="vertical-align: top;">
                  <td>
                    <table style="width: 100%; height: 100%;" border="0" cellpadding="0" cellspacing="0">
                      <tbody>
                        <tr style="vertical-align: top; height: 1em;">
                          <td>
                            <span style="font-weight:bold;">Parse Tree</span>
                          </td>
                        </tr>
                        <tr style="vertical-align: top; height: 1em;">
                          <td id="validity">
                          </td>
                        </tr>
                        <tr>
                          <td id="result">
                            <textarea style="resize: none; width: 100%; height: 100%; border: black solid 1px; padding: 5px 7px;"></textarea>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  ''';

  document.body.style.setProperty("background-color", "lightgray");
  document.body.elements.add(element);

  ButtonElement genElem = window.document.query('#generate');
  genElem.on.click.add((MouseEvent e) {
    runTemplate(true, true);
  });

  SelectElement cannedTemplates = window.document.query('#templateSamples');
  cannedTemplates.on.change.add((e) {
    changeTemplate();
  });

  parseOptions([], null);
  initHtmlWorld(false);

  // Don't display any colors in the UI.
  options.useColors = false;

  // Replace error handler bring up alert for any problems.
  world.printHandler = (String msg) {
    window.alert(msg);
  };
}
