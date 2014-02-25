library tokenizer_test;

// Note: mirrors used to match the getattr usage in the original test
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart';
import 'package:html5lib/src/char_encodings.dart';
import 'package:html5lib/src/token.dart';
import 'package:html5lib/src/tokenizer.dart';
import 'package:utf/utf.dart';
import 'support.dart';

class TokenizerTestParser {
  String _state;
  var _lastStartTag;
  List outputTokens;

  TokenizerTestParser(String initialState, [lastStartTag])
      : _state = initialState,
        _lastStartTag = lastStartTag;

  List parse(String str) {
    // Note: we need to pass bytes to the tokenizer if we want it to handle BOM.
    var bytes = codepointsToUtf8(toCodepoints(str));
    var tokenizer = new HtmlTokenizer(bytes, encoding: 'utf-8');
    outputTokens = [];

    // Note: we can't get a closure of the state method. However, we can
    // create a new closure to invoke it via mirrors.
    var mtok = reflect(tokenizer);
    tokenizer.state = () =>
        mtok.invoke(new Symbol(_state), const []).reflectee;

    if (_lastStartTag != null) {
      tokenizer.currentToken = new StartTagToken(_lastStartTag);
    }

    while (tokenizer.moveNext()) {
      var token = tokenizer.current;
      switch (token.kind) {
        case TokenKind.characters:
          processCharacters(token);
          break;
        case TokenKind.spaceCharacters:
          processSpaceCharacters(token);
          break;
        case TokenKind.startTag:
          processStartTag(token);
          break;
        case TokenKind.endTag:
          processEndTag(token);
          break;
        case TokenKind.comment:
          processComment(token);
          break;
        case TokenKind.doctype:
          processDoctype(token);
          break;
        case TokenKind.parseError:
          processParseError(token);
          break;
      }
    }

    return outputTokens;
  }

  void processDoctype(DoctypeToken token) {
    outputTokens.add(["DOCTYPE", token.name, token.publicId,
        token.systemId, token.correct]);
  }

  void processStartTag(StartTagToken token) {
    outputTokens.add(["StartTag", token.name, token.data, token.selfClosing]);
  }

  void processEndTag(EndTagToken token) {
    outputTokens.add(["EndTag", token.name, token.selfClosing]);
  }

  void processComment(StringToken token) {
    outputTokens.add(["Comment", token.data]);
  }

  void processSpaceCharacters(StringToken token) {
    processCharacters(token);
  }

  void processCharacters(StringToken token) {
    outputTokens.add(["Character", token.data]);
  }

  void processEOF(token) {
  }

  void processParseError(StringToken token) {
    // TODO(jmesserly): when debugging test failures it can be useful to add
    // logging here like `print('ParseError $token');`. It would be nice to
    // use the actual logging library.
    outputTokens.add(["ParseError", token.data]);
  }
}

List concatenateCharacterTokens(List tokens) {
  var outputTokens = [];
  for (var token in tokens) {
    if (token.indexOf("ParseError") == -1 && token[0] == "Character") {
      if (outputTokens.length > 0 &&
          outputTokens.last.indexOf("ParseError") == -1 &&
          outputTokens.last[0] == "Character") {

        outputTokens.last[1] = '${outputTokens.last[1]}${token[1]}';
      } else {
        outputTokens.add(token);
      }
    } else {
      outputTokens.add(token);
    }
  }
  return outputTokens;
}

List normalizeTokens(List tokens) {
  // TODO: convert tests to reflect arrays
  for (int i = 0; i < tokens.length; i++) {
    var token = tokens[i];
    if (token[0] == 'ParseError') {
      tokens[i] = token[0];
    }
  }
  return tokens;
}


/// Test whether the test has passed or failed
///
/// If the ignoreErrorOrder flag is set to true we don't test the relative
/// positions of parse errors and non parse errors.
void expectTokensMatch(List expectedTokens, List receivedTokens,
    bool ignoreErrorOrder, [bool ignoreErrors = false, String message]) {

  var checkSelfClosing = false;
  for (var token in expectedTokens) {
    if (token[0] == "StartTag" && token.length == 4
        || token[0] == "EndTag" && token.length == 3) {
      checkSelfClosing = true;
      break;
    }
  }

  if (!checkSelfClosing) {
    for (var token in receivedTokens) {
      if (token[0] == "StartTag" || token[0] == "EndTag") {
        token.removeLast();
      }
    }
  }

  if (!ignoreErrorOrder && !ignoreErrors) {
    expect(receivedTokens, equals(expectedTokens), reason: message);
  } else {
    // Sort the tokens into two groups; non-parse errors and parse errors
    var expectedNonErrors = expectedTokens.where((t) => t != "ParseError");
    var receivedNonErrors = receivedTokens.where((t) => t != "ParseError");

    expect(receivedNonErrors, equals(expectedNonErrors), reason: message);
    if (!ignoreErrors) {
      var expectedParseErrors = expectedTokens.where((t) => t == "ParseError");
      var receivedParseErrors = receivedTokens.where((t) => t == "ParseError");
      expect(receivedParseErrors, equals(expectedParseErrors), reason: message);
    }
  }
}

void runTokenizerTest(Map testInfo) {
  // XXX - move this out into the setup function
  // concatenate all consecutive character tokens into a single token
  if (testInfo.containsKey('doubleEscaped')) {
    testInfo = unescape(testInfo);
  }

  var expected = concatenateCharacterTokens(testInfo['output']);
  if (!testInfo.containsKey('lastStartTag')) {
    testInfo['lastStartTag'] = null;
  }
  var parser = new TokenizerTestParser(testInfo['initialState'],
      testInfo['lastStartTag']);
  var tokens = parser.parse(testInfo['input']);
  tokens = concatenateCharacterTokens(tokens);
  var received = normalizeTokens(tokens);
  var errorMsg = ["\n\nInitial state:",
              testInfo['initialState'],
              "\nInput:", testInfo['input'],
              "\nExpected:", expected,
              "\nreceived:", tokens].map((s) => '$s').join('\n');
  var ignoreErrorOrder = testInfo['ignoreErrorOrder'];
  if (ignoreErrorOrder == null) ignoreErrorOrder = false;

  expectTokensMatch(expected, received, ignoreErrorOrder, true, errorMsg);
}

Map unescape(Map testInfo) {
  // TODO(sigmundch,jmesserly): we currently use JSON.decode to unescape the
  // unicode characters in the string, we should use a decoding that works with
  // any control characters.
  decode(inp) => inp == '\u0000' ? inp : JSON.decode('"$inp"');

  testInfo["input"] = decode(testInfo["input"]);
  for (var token in testInfo["output"]) {
    if (token == "ParseError") {
      continue;
    } else {
      token[1] = decode(token[1]);
      if (token.length > 2) {
        for (var pair in token[2]) {
          var key = pair[0];
          var value = pair[1];
          token[2].remove(key);
          token[2][decode(key)] = decode(value);
        }
      }
    }
  }
  return testInfo;
}


String camelCase(String s) {
  s = s.toLowerCase();
  var result = new StringBuffer();
  for (var match in new RegExp(r"\W+(\w)(\w+)").allMatches(s)) {
    if (result.length == 0) result.write(s.substring(0, match.start));
    result.write(match.group(1).toUpperCase());
    result.write(match.group(2));
  }
  return result.toString();
}

void main() {
  for (var path in getDataFiles('tokenizer')) {
    if (!path.endsWith('.test')) continue;

    var text = new File(path).readAsStringSync();
    var tests = JSON.decode(text);
    var testName = pathos.basenameWithoutExtension(path);
    var testList = tests['tests'];
    if (testList == null) continue;

    group(testName, () {
      for (int index = 0; index < testList.length; index++) {
        final testInfo = testList[index];

        testInfo.putIfAbsent("initialStates", () => ["Data state"]);
        for (var initialState in testInfo["initialStates"]) {
          test(testInfo["description"], () {
            testInfo["initialState"] = camelCase(initialState);
            runTokenizerTest(testInfo);
          });
        }
      }
    });
  }
}
