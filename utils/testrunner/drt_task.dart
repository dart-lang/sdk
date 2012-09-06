// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A pipeline task for running DumpRenderTree. */
class DrtTask extends RunProcessTask {

  String _testFileTemplate;

  DrtTask(this._testFileTemplate, String htmlFileTemplate) {
    init(config.drtPath, ['--no-timeout', htmlFileTemplate], config.timeout);
  }

  // In order to extract the relevant parts of the DRT render text
  // output we use a somewhat kludgy approach, but it should be robust.
  // DRT formats output with indentation, and we know that the test title
  // is on a line with 12 spaces indent followed by 'text run', while the
  // IFrame body elements are all indented at least 18 spaces.
  const TEST_LABEL_LINE_PREFIX = '            text run';
  const BODY_LINE_PREFIX = '                  ';

  void execute(Path testfile, List stdout, List stderr, bool logging,
               Function exitHandler) {

    var testname = expandMacros(_testFileTemplate, testfile);
    var isLayout = isLayoutRenderTest(testname) || config.generateRenders;

    if (!isLayout) {
      super.execute(testfile, stdout, stderr, logging, exitHandler);
    } else {
      var tmpLog = new List<String>();
      super.execute(testfile, tmpLog, tmpLog, true,
          (code) {
            var layoutFile = layoutFileName(testname);
            var layouts = getFileContents(layoutFile, false);
            var i = 0;
            StringBuffer sbuf = null;
            if (config.generateRenders) {
              sbuf = new StringBuffer();
            }
            while ( i < tmpLog.length) {
              var line = tmpLog[i];
              if (logging) {
                stdout.add(line);
              }
              if (line.startsWith(TEST_LABEL_LINE_PREFIX)) {
                var j = i+1;
                var start = -1, end = -1;
                // Walk forward to the next label or end of log.
                while (j < tmpLog.length &&
                    !tmpLog[j].startsWith(TEST_LABEL_LINE_PREFIX)) {
                  // Is this a body render line?
                  if (tmpLog[j].startsWith(BODY_LINE_PREFIX)) {
                    if (start < 0) { // Is it the first?
                      start = j;
                    }
                  } else { // Not a render line.
                    if (start >= 0 && end < 0) {
                      // We were just in a set of render lines, so this
                      // line is the first non-member.
                      end = j;
                    }
                  }
                  j++;
                }
                if (start >= 0) { // We have some render lines.
                  if (end < 0) {
                    end = tmpLog.length; // Sanity.
                  }
                  var actualLayout = new List<String>();
                  while (start < end) {
                    actualLayout.add(
                        tmpLog[start++].substring(BODY_LINE_PREFIX.length));
                  }
                  var testName = checkTest(testfile, line, layouts,
                                            actualLayout, stdout);
                  if (testName == null) {
                    code = -1;
                  } else if (config.generateRenders) {
                    sbuf.add(testName);
                    sbuf.add('\n');
                    for (var renderLine in actualLayout) {
                      sbuf.add(renderLine);
                      sbuf.add('\n');
                    }
                  }
                }
                i = j;
              } else {
                i++;
              }
            }
            if (config.generateRenders) {
              createFile(layoutFile, sbuf.toString());
            }
            exitHandler(code);
          });
    }
  }

  /**
   * Verify whether a test passed - it must pass the code expectations,
   * and have validated layout. Report success or failure in a test
   * result message. Upon success the render section name is returned
   * (useful for `config.generateRenders`); otherwise null is returned.
   */
  String checkTest(Path testfile, String label, List layouts,
                 List actual, List out) {
    var testGroup = null;
    var testName = null;

    // The label line has the form:
    // "result:duration:<test>//message"
    // where <test> is a test name or series of one or more group names
    // followed by a test name, separated by ###.

    // First extract test state, duration, name and message. If the test
    // passed we can ignore these and continue to layout verification, but
    // if the test failed we want to know that so we can report failure.
    //
    // TODO(gram) - currently we lose the stack trace although the user
    // will get it in the overall output if they used --verbose. We may
    // want to fix this properly at some point.
    var labelParser = const RegExp('\"\([a-z]*\):\([0-9]*\):\(.*\)//\(.*\)\"');
    Match match = labelParser.firstMatch(label);
    var result = match.group(1);
    var duration = parseDouble(match.group(2)) / 1000;
    var test = match.group(3);
    var message = match.group(4);

    // Split name up with group.
    var idx = test.lastIndexOf('###');
    if (idx >= 0) {
      testGroup = test.substring(0, idx).replaceAll('###', ' ');
      testName = test.substring(idx+3);
    } else {
      testGroup = '';
      testName = test;
    }
    var section = '[${_pad(testGroup)}$testName]';

    if (config.generateRenders) {
      // Do nothing; fake a pass.
      out.add(_formatMessage(config.passFormat,
                             testfile, testGroup, testName, duration, ''));
    } else if (result != 'pass') {
      // The test failed separately from layout; just report that
      // failure.
      out.add(_formatMessage(
          (result == 'fail' ? config.failFormat : config.errorFormat),
              testfile, testGroup, testName, duration, message));
      return null;
    } else {
      // The test passed, at least the expectations. So check the layout.
      var expected = _getLayout(layouts, section);
      var failMessage = null;
      var lineNum = 0;
      if (expected != null) {
        while (lineNum < expected.length) {
          if (lineNum >= actual.length) {
            failMessage = 'expected "${expected[lineNum]}" but got nothing';
            break;
          } else {
            if (expected[lineNum] != actual[lineNum]) {
              failMessage = 'expected "${expected[lineNum]}" '
                            'but got "${actual[lineNum]}"';
              break;
            }
          }
          lineNum++;
        }
        if (failMessage == null && lineNum < actual.length) {
          failMessage = 'expected nothing but got "${actual[lineNum]}"';
        }
      }
      if (failMessage != null) {
        out.add(_formatMessage(config.failFormat,
                               testfile, testGroup, testName, duration,
                               'Layout content mismatch at line $lineNum: '
                               '$failMessage'));
        return null;
      } else {
        out.add(_formatMessage(config.passFormat,
                               testfile, testGroup, testName, duration, ''));
      }
    }
    return section;
  }

  /** Get the expected layout for a test. */
  List _getLayout(List layouts, String section) {
    List layout = new List();
    for (var i = 0; i < layouts.length; i++) {
      if (layouts[i] == section) {
        ++i;
        while (i < layouts.length && !layouts[i].startsWith('[')) {
          layout.add(layouts[i++]);
        }
        break;
      }
    }
    return layout;
  }

  /** Pad a string with a rightmost space unless it is empty. */
  static String _pad(s) => (s.length > 0) ? '$s ' : s;

  /** Format a test result message. */
  String _formatMessage(String format,
                        Path testfile, String testGroup, String testName,
                        double duration, String message) {
    String fname = makePathAbsolute(testfile.directoryPath.toString());
    return "###${format.
      replaceAll(Macros.testTime, '${duration.toStringAsFixed(3)}s ').
      replaceAll(Macros.testfile, _pad(fname)).
      replaceAll(Macros.testGroup, _pad(testGroup)).
      replaceAll(Macros.testDescription, _pad(testName)).
      replaceAll(Macros.testMessage, _pad(message))}";
  }
}
