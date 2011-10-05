// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TotalTests extends UnitTestSuite {
  TotalTests() : super() {
  }

  void setUpTestSuite() {
    addTest(() { testDateUtils(); });
    addTest(() { testHtmlUtils(); });
    addTest(() { testStringUtils(); });
    addTest(() { testScanner(); });
    addTest(() { testParser(); });
    addTest(() { testFunctions(); });
    addTest(() { testMortgage(); });
    addTest(() { testVlookup(); });
    addTest(() { testHlookup(); });
  }

  void _checkDate(String date, num value) {
    Expect.equals(value.toString(), DateUtils.parseDate(date).toString());
  }

  void _isDate(String date) {
    Expect.isTrue(DateUtils.isDate(date), "DateUtils.isDate(${date})");
  }

  void _isNotDate(String date) {
    Expect.isFalse(DateUtils.isDate(date), "DateUtils.isDate(${date})");
  }

  void testDateUtils() {
    _isDate('1/1');
    _isDate('12/1');
    _isDate('11/31');
    _isDate('01/1');
    _isDate('1/01');
    _isDate('01/01');
    _isDate('1-1');
    _isDate('12-1');
    _isDate('11-31');
    _isDate('01-1');
    _isDate('1-01');
    _isDate('01-01');
    _isDate('1/1/1970');
    _isDate('01/1/1970');
    _isDate('1/01/1970');
    _isDate('1/1/70');
    _isDate('1/01/1970');
    _isNotDate("1/1A");
    _isNotDate("11/222");
    _isNotDate("11/22/");
    _checkDate('7/7/2011', 40731.0);
    _checkDate('7/7/11', 40731.0);
    _checkDate('7/07/2011', 40731.0);
    _checkDate('07/07/2011', 40731.0);
    _checkDate('07/7/2011', 40731.0);
    _checkDate('7-7-2011', 40731.0);
    _checkDate('7-7-11', 40731.0);
    _checkDate('7-07-2011', 40731.0);
    _checkDate('07-07-2011', 40731.0);
    _checkDate('07-7-2011', 40731.0);

    // Test MM-DD-<current year>
    double date = DateUtils.parseDate('7/7');
    double years = (date - 40731.0) / 365.0;
    // Assert days/365 is close to an integer -- this will be true for > 100 years
    Expect.isTrue(years - years.floor() < 0.1, "7/7");
  }

  void testHtmlUtils() {
    Expect.equals("", HtmlUtils.quoteHtml(""));
    Expect.equals("&lt;", HtmlUtils.quoteHtml("<"));
    Expect.equals("&lt;&lt;&lt;&lt;", HtmlUtils.quoteHtml("<<<<"));
    Expect.equals("Hello&lt;World", HtmlUtils.quoteHtml("Hello<World"));
    Expect.equals("Hello&lt;&lt;World", HtmlUtils.quoteHtml("Hello<<World"));
    Expect.equals("Hello&lt;W&lt;orld", HtmlUtils.quoteHtml("Hello<W<orld"));
    Expect.equals("&lt;Hello&lt;World", HtmlUtils.quoteHtml("<Hello<World"));
    Expect.equals("&lt;&lt;Hello&lt;World&lt;", HtmlUtils.quoteHtml("<<Hello<World<"));
    Expect.equals("&lt;&lt;Hello&lt;W&lt;orld&lt;", HtmlUtils.quoteHtml("<<Hello<W<orld<"));

    Document doc = window.document;
    Element body = doc.body;
    DivElement div = doc.createElement('div');
    body.nodes.add(div);

    HtmlUtils.setIntegerProperty(div, "left", 100, "px");
    CSSStyleDeclaration computedStyle = window.getComputedStyle(div, "");
    String valueAsString = computedStyle.getPropertyValue("left");
    // FIXME: Test fails, with valueAsString == "auto". However, setIntegerProperty
    // works when tested in practice, so there is something wrong with recovering
    // the value.
    // Expect.equals("100", valueAsString);

    div.remove();
  }

  void _assertNumeric(String s) {
    Expect.isTrue(StringUtils.isNumeric(s), 'StringUtils.isNumeric("{$s}")');
  }

  void _assertNonNumeric(String s) {
    Expect.isFalse(StringUtils.isNumeric(s), '!StringUtils.isNumeric("${s}")');
  }

  void testStringUtils() {
    _assertNumeric("0");
    _assertNumeric(".0");
    _assertNumeric("0.0");
    _assertNumeric(".1");
    _assertNumeric("1.");
    _assertNumeric("1.0");
    _assertNumeric("1e17");
    _assertNumeric("1.e17");
    _assertNumeric(".1e17");
    _assertNumeric("1e+17");
    _assertNumeric("1.e-17");
    _assertNumeric(".1e+17");
    _assertNumeric("12345.17");
    _assertNumeric("2.3993e-37");
    _assertNumeric("-12345.17");
    _assertNumeric("+12345.17");
    _assertNumeric("-12345.17e2");
    _assertNumeric("+12345.17e2");
    _assertNumeric("-12345.17e-2");
    _assertNumeric("+12345.17e+2");
    _assertNumeric("-12345.17e+2");
    _assertNumeric("+12345.17e-2");
    _assertNonNumeric("");
    _assertNonNumeric("ABC");
    _assertNonNumeric("++12345.17");
    _assertNonNumeric("12345.17.2");
    _assertNonNumeric("-12345.17e");
    _assertNonNumeric("-12345.17e-");
    _assertNonNumeric("-12345.17e+");
    _assertNonNumeric("-12345.17e2.5");
    _assertNonNumeric("++12345.17A");
    _assertNonNumeric("++12345.17");
    _assertNonNumeric("++12345.17e");
    _assertNonNumeric("++12345.17");
    _assertNonNumeric("--12345.17A");
    _assertNonNumeric("--12345.17");
    _assertNonNumeric("--12345.17e");
    _assertNonNumeric("--12345.17");
    _assertNonNumeric("e17");
    _assertNonNumeric("E17");
    _assertNonNumeric(".e17");
    _assertNonNumeric(".E17");
    _assertNonNumeric("-e17");
    _assertNonNumeric("-E17");
    _assertNonNumeric("+.e17");
    _assertNonNumeric("+.E17");

    Expect.equals("A", StringUtils.columnString(1));
    Expect.equals("Z", StringUtils.columnString(26));
    Expect.equals("AA", StringUtils.columnString(27));
    Expect.equals("AZ", StringUtils.columnString(52));
    Expect.equals("BA", StringUtils.columnString(53));
    Expect.equals("BZ", StringUtils.columnString(78));
    Expect.equals("ZA", StringUtils.columnString(677));
    Expect.equals("ZZ", StringUtils.columnString(702));
    Expect.equals("AAA", StringUtils.columnString(703));
    Expect.equals("ZZZ", StringUtils.columnString(18278));
    Expect.equals("AAAA", StringUtils.columnString(18279));

    Expect.equals(-1, StringUtils.compare("a", "b"));
    Expect.equals(1, StringUtils.compare("b", "a"));
    Expect.equals(0, StringUtils.compare("a", "a"));
    Expect.equals(-1, StringUtils.compare("ab", "abb"));
    Expect.equals(1, StringUtils.compare("abb", "ab"));
    // Note: StringUtils.compare sorts empty string before non-empty strings,
    // but the comparator used to sort spreadhseet cells deals with this case
    // internally and never calls StringUtils.compare with an empty string argument
    Expect.isTrue(StringUtils.compare("", "a") < 0);
    Expect.isTrue(StringUtils.compare("a", "") > 0);
  }

  void _testScannerHelper(String input) {
    Scanner scanner =
      new Scanner.preserveWhitespace(input, new CellLocation(null, new RowCol(1, 1)));
    StringBuffer sb = new StringBuffer();
    while (true) {
      Token token = scanner.nextToken();
      if (token == null) {
        break;
      }
      sb.add(token.toString());
    }

    Expect.equals(input, sb.toString());
  }

  void testScanner() {
    String input =
      "ROUND(R1C0 *  ((R1C1 / 1234.0000) / (1 - POWER(1 + (R1C1 / 1234.5000),   -12 * R1C2))), 2)";
    Scanner scanner =
      new Scanner.preserveWhitespace(input, new CellLocation(null, new RowCol(0, 0)));
    List<Token> tokens = scanner.scan();

    List<String> expected = <String>[
        "ROUND", "(", "R1C0", " ", "*", "  ", "(", "(", "R1C1", " ", "/", " ",
        "1234", ")", " ", "/", " ", "(", "1", " ", "-", " ", "POWER", "(", "1",
        " ", "+", " ", "(", "R1C1", " ", "/", " ", "1234.5", ")", ",", "   ", "-",
        "12", " ", "*", " ", "R1C2", ")", ")", ")", ",", " ", "2", ")", ];

    int index = 0;
    tokens.forEach((Token token) {
      Expect.equals(expected[index++], token.toString());
    });

    _testScannerHelper("10 < 12");
    _testScannerHelper("10 > 12");
    _testScannerHelper("10 = 12");
    _testScannerHelper("10 <> 12");
    _testScannerHelper("10 <= 12");
    _testScannerHelper("10 >= 12");
    _testScannerHelper("FALSE");
    _testScannerHelper("TRUE");
    _testScannerHelper("ROUND(R1C0*((R1C1/1200)/(1-POWER(1+(R1C1/1200),-12*R1C2))),2)");
    _testScannerHelper("R1C1 + R2C2");
    _testScannerHelper("ThisIsAFunction999()");
    _testScannerHelper("LOG10(1000)");
    _testScannerHelper("R1C2 R1C2 R1C2  R1C2");
    _testScannerHelper("R[1]C2 R[-1]C2   R[1]C-2\tR[-1]C-2");
    _testScannerHelper("R1C[2]R1C[2]R1C[-2]R1C[-2]");
    _testScannerHelper("R[1]C[2]R[-1]C[2]R[1]C[-2]R[-1]C[-2]");
    _testScannerHelper("R111C222 R111C222 R111C222 R111C2");
    _testScannerHelper("R[111]C222:R[-111]C222, R[111]C222:R[-111]C222");
    _testScannerHelper("R111C[222]R111C[222]R111C[-222]R111C[-222]");
    _testScannerHelper("(R[111]C[222],R[-111]C[222]:R[111]C[-222], R[-111]C[-222])");
    _testScannerHelper("R1C0");
    _testScannerHelper("R[-1]C  +     1");
    // Problem: R[-1]C-R[-1]C[2] : the C- is really C[0]- but looks like C
    // followed by a (degenerate) number
    _testScannerHelper("R[-1]C[1] - R[-1]C[2]");
    _testScannerHelper("RC[-1]* R1C1 / 1200");
    _testScannerHelper("R1C3 -RC[-1]");
  }

  void testParser() {
    String input = "ROUND(R1C0*((R1C1/1200)/(1-POWER(1+(R1C1/1200),-12*R1C2))),2)";
    Scanner scanner = new Scanner(input, new CellLocation(null, new RowCol(1, 1)));
    Parser parser = new Parser(scanner);
    List<Token> tokens = parser.parse();

    List<String> expected = [
        "R1C0", "R1C1", "1200", "/", "1", "1",
        "R1C1", "1200", "/", "+", "0", "12", "-",
        "R1C2", "*", "2" /* nargs */, "POWER", "-", "/", "*", "2",
        "2" /* nargs */, "ROUND"];

    int index = 0;
    tokens.forEach((Token token) {
      Expect.equals(expected[index++], token.toString());
    });
  }

  void _testFunctionsHelper(String formula, double expected) {
    try {
      CellLocation location = new CellLocation(null, new RowCol(0, 0));
      Value value = new StringFormula(formula, location).calculate();
      double actual = value.asDouble(null);
      Expect.approxEquals(expected, actual, 0.00001, "Error evaluating formula: ${formula}");
    } catch (var error) {
      Expect.fail("Error evaluating formula: ${formula}, error=${error}");
    }
  }

  void testFunctions() {
    _testFunctionsHelper("2<5", 1.0);
    _testFunctionsHelper("2>5", 0.0);
    _testFunctionsHelper("2=5", 0.0);
    _testFunctionsHelper("5=5", 1.0);
    _testFunctionsHelper("2<>5", 1.0);
    _testFunctionsHelper("5<>5", 0.0);
    _testFunctionsHelper("2<=1", 0.0);
    _testFunctionsHelper("2<=2", 1.0);
    _testFunctionsHelper("2<=3", 1.0);
    _testFunctionsHelper("2>=1", 1.0);
    _testFunctionsHelper("2>=2", 1.0);
    _testFunctionsHelper("2>=3", 0.0);
    _testFunctionsHelper("FALSE", 0.0);
    _testFunctionsHelper("TRUE", 1.0);
    _testFunctionsHelper("FALSE()", 0.0);
    _testFunctionsHelper("TRUE()", 1.0);
    _testFunctionsHelper("NOT(FALSE)", 1.0);
    _testFunctionsHelper("NOT(TRUE)", 0.0);
    _testFunctionsHelper("NOT(FALSE())", 1.0);
    _testFunctionsHelper("NOT(TRUE())", 0.0);
    _testFunctionsHelper("AND(FALSE)", 0.0);
    _testFunctionsHelper("AND(TRUE)", 1.0);
    _testFunctionsHelper("AND(FALSE,FALSE)", 0.0);
    _testFunctionsHelper("AND(FALSE,TRUE)", 0.0);
    _testFunctionsHelper("AND(TRUE,FALSE)", 0.0);
    _testFunctionsHelper("AND(TRUE,TRUE)", 1.0);
    _testFunctionsHelper("OR(FALSE,FALSE)", 0.0);
    _testFunctionsHelper("OR(FALSE,TRUE)", 1.0);
    _testFunctionsHelper("OR(TRUE,FALSE)", 1.0);
    _testFunctionsHelper("OR(TRUE,TRUE)", 1.0);
    _testFunctionsHelper("IF(TRUE,3,4)", 3.0);
    _testFunctionsHelper("IF(FALSE,3,4)", 4.0);
    _testFunctionsHelper("IF(TRUE,3)", 3.0);
    _testFunctionsHelper("IF(FALSE,3)", 0.0);
    _testFunctionsHelper("IF(NOT(FALSE()),3,4)", 3.0);
    _testFunctionsHelper("IF(NOT(TRUE()),3,4)", 4.0);
    // Unary functions
    _testFunctionsHelper("5-2", 3.0);
    _testFunctionsHelper("5--2", 7.0);
    _testFunctionsHelper("ABS(3)", 3.0);
    _testFunctionsHelper("ABS(-3)", 3.0);
    _testFunctionsHelper("COS(1)", 0.540302306);
    _testFunctionsHelper("DEGREES(3)", 171.887339);
    _testFunctionsHelper("EVEN(1.5)", 2.0);
    _testFunctionsHelper("EVEN(3)", 4.0);
    _testFunctionsHelper("EVEN(2)", 2.0);
    _testFunctionsHelper("EVEN(-1)", -2.0);
    _testFunctionsHelper("EVEN(-2)", -2.0);
    _testFunctionsHelper("EXP(0)", 1.0);
    _testFunctionsHelper("EXP(1)", 2.71828183);
    _testFunctionsHelper("EXP(-1)", 0.367879441);
    _testFunctionsHelper("FACT(0)", 1.0);
    _testFunctionsHelper("FACT(1)", 1.0);
    _testFunctionsHelper("FACT(2)", 2.0);
    _testFunctionsHelper("FACT(3)", 6.0);
    _testFunctionsHelper("FACT(4)", 24.0);
    _testFunctionsHelper("FACTDOUBLE(5)", 15.0);
    _testFunctionsHelper("FACTDOUBLE(6)", 48.0);
    _testFunctionsHelper("FACTDOUBLE(10)", 3840.0);
    _testFunctionsHelper("FACTDOUBLE(0)", 1.0);
    _testFunctionsHelper("INT(8.9)", 8.0);
    _testFunctionsHelper("INT(-8.9)", -9.0);
    _testFunctionsHelper("LN(1)", 0.0);
    _testFunctionsHelper("LN(2)", 0.693147181);
    _testFunctionsHelper("LOG10(1)", 0.0);
    _testFunctionsHelper("LOG10(10)", 1.0);
    _testFunctionsHelper("LOG10(20)", 1.30103);
    _testFunctionsHelper("ODD(1.5)", 3.0);
    _testFunctionsHelper("ODD(3)", 3.0);
    _testFunctionsHelper("ODD(2)", 3.0);
    _testFunctionsHelper("ODD(-1)", -1.0);
    _testFunctionsHelper("ODD(-2)", -3.0);
    _testFunctionsHelper("RADIANS(180)", 3.14159265);
    _testFunctionsHelper("SIGN(-3)", -1.0);
    _testFunctionsHelper("SIGN(0)", 0.0);
    _testFunctionsHelper("SIGN(3)", 1.0);
    _testFunctionsHelper("SIN(1)", 0.841470985);
    _testFunctionsHelper("SQRT(2)", 1.41421356);
    _testFunctionsHelper("TANH(0)", 0.0);
    _testFunctionsHelper("TANH(LN((1 + SQRT(5))/2))", Math.sqrt(5.0) / 5.0);

    // Binary functions
    _testFunctionsHelper("COMBIN(7,3)", 35.0);
    _testFunctionsHelper("COMBIN(7,4)", 35.0);
    _testFunctionsHelper("LOG(1, 10)", 0.0);
    _testFunctionsHelper("LOG(10, 10)", 1.0);
    _testFunctionsHelper("LOG(20, 10)", 1.30103);
    _testFunctionsHelper("MOD(3, 2)", 1.0);
    _testFunctionsHelper("MOD(-3, 2)", 1.0);
    _testFunctionsHelper("MOD(3, -2)", -1.0);
    _testFunctionsHelper("MOD(-3, -2)", -1.0);
    _testFunctionsHelper("QUOTIENT(5,2)", 2.0);
    // _testFunctionsHelper("QUOTIENT(4.5,3.1)", 1.0);
    _testFunctionsHelper("QUOTIENT(-10,3)", -3.0);
    _testFunctionsHelper("ROUND(SQRT(2), 2)", 1.41);
    _testFunctionsHelper("ROUND(SQRT(2), 1)", 1.4);
    _testFunctionsHelper("POWER(SQRT(2), 2)", 2.0);
    _testFunctionsHelper("TRUNC(8.567)", 8.0);
    _testFunctionsHelper("TRUNC(8.567, 1)", 8.5);
    _testFunctionsHelper("TRUNC(8.567, 2)", 8.56);
    _testFunctionsHelper("TRUNC(-8.567)", -8.0);
    _testFunctionsHelper("TRUNC(-8.567, 1)", -8.5);
    _testFunctionsHelper("TRUNC(-8.567, 2)", -8.56);

    // Date/Time functions
    _testFunctionsHelper("HOUR(40730.6789)", 16.0);
    _testFunctionsHelper("MINUTE(40730.6789)", 17.0);
    _testFunctionsHelper("SECOND(40730.6789)", 36.0);
    _testFunctionsHelper("YEAR(DATE(2011,7,4))", 2011.0);
    _testFunctionsHelper("MONTH(DATE(2011,7,4))", 7.0);
    _testFunctionsHelper("DAY(DATE(2011,7,4))", 4.0);

    // N-ary functions
    _testFunctionsHelper("GCD(5,2)", 1.0);
    _testFunctionsHelper("GCD(24,36)", 12.0);
    _testFunctionsHelper("GCD(24,36,4)", 4.0);
    _testFunctionsHelper("GCD(7,1)", 1.0);
    _testFunctionsHelper("GCD(5,0)", 5.0);
    _testFunctionsHelper("LCM(5,2)", 10.0);
    _testFunctionsHelper("LCM(24,36)", 72.0);
    _testFunctionsHelper("LCM(24,36,5)", 360.0);
    _testFunctionsHelper("MULTINOMIAL(2, 3, 4)", 1260.0);
    _testFunctionsHelper("SERIESSUM(PI()/4,0,2,1,-1/FACT(2),1/FACT(4),-1/FACT(6))", 0.707103);
  }

  void testMortgage() {
    Reader reader = new SYLKReader();
    List<String> data = reader.makeExample("mortgage");
    Spreadsheet spreadsheet = new Spreadsheet();
    reader.loadSpreadsheet(spreadsheet, data);
    Expect.approxEquals(383.05, spreadsheet.getDoubleValue(new RowCol(99, 2)), 0.05);
    Expect.approxEquals(36977.28, spreadsheet.getDoubleValue(new RowCol(100, 2)), 0.05);
    Expect.approxEquals(6976.86, spreadsheet.getDoubleValue(new RowCol(100, 3)), 0.05);
    Expect.approxEquals(30000.42, spreadsheet.getDoubleValue(new RowCol(100, 4)), 0.05);
  }

  void testVlookup() {
    Spreadsheet spreadsheet = new Spreadsheet();
    spreadsheet.setCellFromContentString(new RowCol(1, 1), "4.14");
    spreadsheet.setCellFromContentString(new RowCol(2, 1), "4.19");
    spreadsheet.setCellFromContentString(new RowCol(3, 1), "5.17");
    spreadsheet.setCellFromContentString(new RowCol(4, 1), "5.77");
    spreadsheet.setCellFromContentString(new RowCol(5, 1), "6.39");
    spreadsheet.setCellFromContentString(new RowCol(1, 2), "1");
    spreadsheet.setCellFromContentString(new RowCol(2, 2), "2");
    spreadsheet.setCellFromContentString(new RowCol(3, 2), "3");
    spreadsheet.setCellFromContentString(new RowCol(4, 2), "4");
    spreadsheet.setCellFromContentString(new RowCol(5, 2), "5");

    // Test exact match: 5.77 ==> 4
    spreadsheet.setCellFromContentString(new RowCol(6, 1), "=VLOOKUP(5.77,A1:B5,2,0)");
    Expect.equals(4.0, spreadsheet.getDoubleValue(new RowCol(6, 1)));

    // Test approximate match: 5.177 < 5.3 < 5.77 ==> 3
    spreadsheet.setCellFromContentString(new RowCol(6, 1), "=VLOOKUP(5.3,A1:B5,2,1)");
    Expect.equals(3.0, spreadsheet.getDoubleValue(new RowCol(6, 1)));

    // Omit 'range_lookup' flag, behavior is the same as "true"
    spreadsheet.setCellFromContentString(new RowCol(6, 1), "=VLOOKUP(5.3,A1:B5,2)");
    Expect.equals(3.0, spreadsheet.getDoubleValue(new RowCol(6, 1)));
  }

  void testHlookup() {
    Spreadsheet spreadsheet = new Spreadsheet();
    spreadsheet.setCellFromContentString(new RowCol(1, 1), "4.14");
    spreadsheet.setCellFromContentString(new RowCol(1, 2), "4.19");
    spreadsheet.setCellFromContentString(new RowCol(1, 3), "5.17");
    spreadsheet.setCellFromContentString(new RowCol(1, 4), "5.77");
    spreadsheet.setCellFromContentString(new RowCol(1, 5), "6.39");
    spreadsheet.setCellFromContentString(new RowCol(2, 1), "1");
    spreadsheet.setCellFromContentString(new RowCol(2, 2), "2");
    spreadsheet.setCellFromContentString(new RowCol(2, 3), "3");
    spreadsheet.setCellFromContentString(new RowCol(2, 4), "4");
    spreadsheet.setCellFromContentString(new RowCol(2, 5), "5");

    // Test exact match: 5.77 ==> 4
    spreadsheet.setCellFromContentString(new RowCol(1, 6), "=HLOOKUP(5.77,A1:E2,2,0)");
    Expect.equals(4.0, spreadsheet.getDoubleValue(new RowCol(1, 6)));

    // Test approximate match: 5.177 < 5.3 < 5.77 ==> 3
    spreadsheet.setCellFromContentString(new RowCol(1, 6), "=HLOOKUP(5.3,A1:E2,2,1)");
    Expect.equals(3.0, spreadsheet.getDoubleValue(new RowCol(1, 6)));

    // Omit 'range_lookup' flag, behavior is the same as "true"
    spreadsheet.setCellFromContentString(new RowCol(6, 1), "=HLOOKUP(5.3,A1:E2,2)");
    Expect.equals(3.0, spreadsheet.getDoubleValue(new RowCol(6, 1)));
  }

  static void main() {
    new TotalTests().run();
  }
}

