// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math" as math;

class BinaryMdDillReader {
  final String _binaryMdContent;

  /// The actual binary content.
  final List<int> _dillContent;

  String _currentlyUnparsed = "";
  Map<String, List<String>> _readingInstructions;
  Map<String, List<String>> _generics;
  Map<int, String> tagToName;
  Map<int, String> constantTagToName;
  int version;
  Map<String, String> _extends;
  int _binaryMdNestingDepth;
  String _binaryMdCurrentClass;

  /// The offset in the binary where we're supposed to read next.
  int _binaryOffset;

  int _depth;
  Map _dillStringsPointer;
  int verboseLevel = 0;
  bool _ranSetup = false;

  BinaryMdDillReader(this._binaryMdContent, this._dillContent);

  void setup() {
    if (!_ranSetup) {
      _setupFields();
      _readBinaryMd();
      _ranSetup = true;
    }
  }

  Map attemptRead() {
    setup();
    return _readDill();
  }

  /// Initialize the bare essentials, e.g. that a double is 8 bytes.
  void _setupFields() {
    _readingInstructions = {
      "Byte": ["byte"],
      "UInt32": ["byte", "byte", "byte", "byte"],
      "Double": ["byte", "byte", "byte", "byte", "byte", "byte", "byte", "byte"]
    };
    _generics = {};
    tagToName = {};
    constantTagToName = {};
    _extends = {};
    _binaryMdNestingDepth = 0;
    _binaryMdCurrentClass = "";
  }

  /// Read the binary.md text and put the data into the various tables.
  void _readBinaryMd() {
    List<String> lines = _binaryMdContent.split("\n");
    bool inComment = false;
    for (String s in lines) {
      if (s.trim().startsWith("//") || s.trim() == "") {
        continue;
      } else if (s.trim().startsWith("/*")) {
        inComment = true;
        continue;
      } else if (s.trim().startsWith("*/")) {
        inComment = false;
        continue;
      } else if (inComment) {
        continue;
      } else if (s.trim().startsWith("type ") ||
          s.trim().startsWith("abstract type ") ||
          s.trim().startsWith("enum ")) {
        _binaryMdHandlePossibleClassStart(s);
      } else if (s.trim() == "if name begins with '_' {" &&
          _binaryMdCurrentClass == "Name") {
        // Special-case if sentence in Name.
        _binaryMdNestingDepth++;
      } else if (s.trim().endsWith("{")) {
        throw "Unhandled case: $s";
      } else if (s.trim() == "}") {
        _binaryMdNestingDepth--;
        _binaryMdCurrentClass = "";
      } else if (_binaryMdNestingDepth > 0 && _binaryMdCurrentClass != "") {
        _binaryMdHandleContent(s);
      }
    }

    _binaryMdCheckHasAllTypes();
    if (verboseLevel > 0) {
      print("Seems to find all types.");
    }
  }

  int numLibs;
  int binaryOffsetForSourceTable;
  int binaryOffsetForCanonicalNames;
  int binaryOffsetForMetadataPayloads;
  int binaryOffsetForMetadataMappings;
  int binaryOffsetForStringTable;
  int binaryOffsetForConstantTable;
  int mainMethodReference;

  /// Read the dill file data, parsing it into a Map.
  Map _readDill() {
    _binaryOffset = 0;
    _depth = 0;

    // Hack start: Read ComponentIndex first.
    _binaryOffset = _dillContent.length - (4 * 2);
    numLibs = _peekUint32();

    // Skip to the start of the index.
    _binaryOffset = _dillContent.length -
        ((numLibs + 1) + 10 /* number of fixed fields */) * 4;

    // Read index.
    binaryOffsetForSourceTable = _peekUint32();
    _binaryOffset += 4;
    binaryOffsetForCanonicalNames = _peekUint32();
    _binaryOffset += 4;
    binaryOffsetForMetadataPayloads = _peekUint32();
    _binaryOffset += 4;
    binaryOffsetForMetadataMappings = _peekUint32();
    _binaryOffset += 4;
    binaryOffsetForStringTable = _peekUint32();
    _binaryOffset += 4;
    binaryOffsetForConstantTable = _peekUint32();
    _binaryOffset += 4;
    mainMethodReference = _peekUint32();
    _binaryOffset += 4;
    /*int compilationMode = */ _peekUint32();

    _binaryOffset = binaryOffsetForStringTable;
    var saved = _readingInstructions["ComponentFile"];
    _readingInstructions["ComponentFile"] = ["StringTable strings;"];
    _readBinary("ComponentFile");
    _readingInstructions["ComponentFile"] = saved;
    _binaryOffset = 0;
    _depth = 0;
    // Hack end.

    Map componentFile = _readBinary("ComponentFile");
    if (_binaryOffset != _dillContent.length) {
      throw "Didn't read the entire binary: "
          "Only read $_binaryOffset of ${_dillContent.length} bytes. "
          "($componentFile)";
    }
    if (verboseLevel > 0) {
      print("Successfully read the dill file.");
    }
    return componentFile;
  }

  /// Initial setup of a "class definition" in the binary.md file.
  /// This includes parsing the name, setting up any "extends"-relationship,
  /// generics etc.
  _binaryMdHandlePossibleClassStart(String s) {
    if (s.startsWith("type Byte =")) return;
    if (s.startsWith("type UInt32 =")) return;

    if (_binaryMdNestingDepth != 0 || _binaryMdCurrentClass != "") {
      throw "Cannot handle nesting: "
          "'$s', $_binaryMdNestingDepth, $_binaryMdCurrentClass";
    }

    if (s.contains("{")) _binaryMdNestingDepth++;
    if (s.contains("}")) _binaryMdNestingDepth--;

    String name = s.trim();
    if (name.startsWith("abstract ")) name = name.substring("abstract ".length);
    if (name.startsWith("type ")) name = name.substring("type ".length);
    bool isEnum = false;
    if (name.startsWith("enum ")) {
      name = name.substring("enum ".length);
      isEnum = true;
    }
    String nameExtends = null;
    Match extendsMatch = (new RegExp("extends (.+)[ \{]")).firstMatch(name);
    if (extendsMatch != null) {
      nameExtends = extendsMatch.group(1);
    }
    name = _getType(name);
    if (name.contains("<")) {
      List<String> types = _getGenerics(name);
      name = name.substring(0, name.indexOf("<")) + "<${types.length}>";
      _generics[name] ??= types;
    }
    if (_binaryMdNestingDepth != 0) _binaryMdCurrentClass = name;
    if (nameExtends != null) {
      _extends[name] = nameExtends.trim();
    }

    if (isEnum) {
      _readingInstructions[name] ??= ["byte"];
    } else {
      _readingInstructions[name] ??= [];
    }
  }

  Map<String, String> _typeCache = {};

  /// Extract the type/name of an input string, e.g. turns
  ///
  /// * "ClassLevel { Type = 0, [...], }" into "ClassLevel"
  /// * "Class extends Node {" into "Class"
  /// * "Byte tag = 97;" into "Byte"
  /// * "List<T> {" into "List<T>"
  String _getType(final String inputString) {
    String cached = _typeCache[inputString];
    if (cached != null) return cached;
    int end = math.max(
        math.max(inputString.indexOf(" "), inputString.lastIndexOf(">") + 1),
        inputString.lastIndexOf("]") + 1);
    if (end <= 0) end = inputString.length;
    String result = inputString.substring(0, end);
    if (result.contains(" extends")) {
      result = result.substring(0, result.indexOf(" extends "));
    }
    _typeCache[inputString] = result;

    return result;
  }

  /// Extract the generics used in an input type, e.g. turns
  ///
  /// * "Pair<A, B>" into ["A", "B"]
  /// * "List<Expression>" into ["Expression"]
  ///
  /// Note that the input string *has* to use generics, i.e. have '<' and '>'
  /// in it.
  /// Also note that nested generics isn't really supported
  /// (e.g. Foo<Bar<Baz>>).
  List<String> _getGenerics(String s) {
    s = s.substring(s.indexOf("<") + 1, s.lastIndexOf(">"));
    if (s.contains("<")) {
      if (s == "Pair<FileOffset, Expression>") {
        return ["Pair<FileOffset, Expression>"];
      } else if (s == "Pair<UInt32, UInt32>") {
        return ["Pair<UInt32, UInt32>"];
      } else if (s == "Pair<FieldReference, Expression>") {
        return ["Pair<FieldReference, Expression>"];
      } else if (s == "Pair<ConstantReference, ConstantReference>") {
        return ["Pair<ConstantReference, ConstantReference>"];
      } else if (s == "Pair<FieldReference, ConstantReference>") {
        return ["Pair<FieldReference, ConstantReference>"];
      }
      throw "Doesn't supported nested generics (input: $s).";
    }

    return s.split(",").map((untrimmed) => untrimmed.trim()).toList();
  }

  /// Parses a line of binary.md content for a "current class" into the
  /// reading-instructions for that class.
  /// There is special handling around tags, and around lines that are split,
  /// i.e. not yet finished (not ending in a semi-colon).
  void _binaryMdHandleContent(String s) {
    if (s.trim().startsWith("UInt32 formatVersion = ")) {
      String versionString =
          s.trim().substring("UInt32 formatVersion = ".length);
      if (versionString.endsWith(";")) {
        versionString = versionString.substring(0, versionString.length - 1);
      }
      if (version != null) {
        throw "Already have a version set ($version), "
            "now trying to set $versionString";
      }
      version = int.parse(versionString);
    }
    if (s.trim().startsWith("Byte tag = ")) {
      String tag = s.trim().substring("Byte tag = ".length);
      if (tag.endsWith(";")) tag = tag.substring(0, tag.length - 1);
      if (tag == "128 + N; // Where 0 <= N < 8.") {
        for (int n = 0; n < 8; ++n) {
          tagToName[128 + n] = _binaryMdCurrentClass;
        }
      } else if (tag == "136 + N; // Where 0 <= N < 8.") {
        for (int n = 0; n < 8; ++n) {
          tagToName[136 + n] = _binaryMdCurrentClass;
        }
      } else if (tag == "144 + N; // Where 0 <= N < 8.") {
        for (int n = 0; n < 8; ++n) {
          tagToName[144 + n] = _binaryMdCurrentClass;
        }
      } else {
        if (tag.contains("; // Note: tag is out of order")) {
          tag = tag.substring(0, tag.indexOf("; // Note: tag is out of order"));
        }
        Map<int, String> tagMap;
        if (_isA(_binaryMdCurrentClass, "Constant")) {
          tagMap = constantTagToName;
        } else {
          tagMap = tagToName;
        }
        if (tagMap[int.parse(tag)] != null) {
          throw "Two tags with same name!: "
              "$tag (${tagMap[int.parse(tag)]} and ${_binaryMdCurrentClass})";
        }
        tagMap[int.parse(tag)] = _binaryMdCurrentClass;
      }
    }

    {
      var line = _currentlyUnparsed + s.trim();
      if (line.contains("//")) line = line.substring(0, line.indexOf("//"));
      if (!line.trim().endsWith(";")) {
        _currentlyUnparsed = line;
        return;
      }
      s = line;
      _currentlyUnparsed = "";
    }

    _readingInstructions[_binaryMdCurrentClass].add(s.trim());
  }

  /// Check the all types referenced by reading instructions are types we know
  /// about.
  void _binaryMdCheckHasAllTypes() {
    for (String key in _readingInstructions.keys) {
      for (String s in _readingInstructions[key]) {
        String type = _getType(s);
        if (!_isKnownType(type, key)) {
          throw "Unknown type: $type (used in $key)";
        }
      }
    }
  }

  /// Check that we know about the specific type, i.e. know something about how
  /// to read it.
  bool _isKnownType(String type, String parent) {
    if (type == "byte") return true;
    if (_readingInstructions[type] != null) return true;
    if (type.contains("[") &&
        _readingInstructions[type.substring(0, type.indexOf("["))] != null) {
      return true;
    }

    if (parent.contains("<")) {
      Set<String> types = _generics[parent].toSet();
      if (types.contains(type)) return true;
      if (type.contains("[") &&
          types.contains(type.substring(0, type.indexOf("[")))) return true;
    }
    if (type.contains("<")) {
      List<String> types = _getGenerics(type);
      String renamedType =
          type.substring(0, type.indexOf("<")) + "<${types.length}>";
      if (_readingInstructions[renamedType] != null) {
        bool ok = true;
        for (String type in types) {
          if (!_isKnownType(type, renamedType)) {
            ok = false;
            break;
          }
        }
        if (ok) return true;
      }
    }

    return false;
  }

  /// Get a string from the string table after the string table has been read
  /// from the dill file.
  String getDillString(int num) {
    List<int> endOffsets =
        (_dillStringsPointer["endOffsets"]["items"] as List<dynamic>).cast();
    List<int> utf8 = (_dillStringsPointer["utf8Bytes"] as List<dynamic>).cast();
    return new String.fromCharCodes(
        utf8.sublist(num == 0 ? 0 : endOffsets[num - 1], endOffsets[num]));
  }

  RegExp regExpSplit = new RegExp(r"[\. ]");

  /// Actually read the binary dill file. Read type [what] at the current
  /// binary position as specified by field [_binaryOffset].
  dynamic _readBinary(String what) {
    ++_depth;
    what = _remapWhat(what);

    // Read any 'base types'.
    if (what == "UInt") {
      return _readUint();
    }
    if (what == "UInt32") {
      return _readUint32();
    }
    if (what == "byte" || what == "Byte") {
      int value = _dillContent[_binaryOffset];
      ++_binaryOffset;
      --_depth;
      return value;
    }

    // Not a 'base type'. Read according to [_readingInstructions] field.
    List<String> types = [];
    List<String> typeNames = [];
    String orgWhat = what;
    int orgPosition = _binaryOffset;
    if (what.contains("<")) {
      types = _getGenerics(what);
      what = what.substring(0, what.indexOf("<")) + "<${types.length}>";
      typeNames = _generics[what];
    }

    if (_readingInstructions[what] == null) {
      throw "Didn't find instructions for '$what'";
    }

    Map<String, dynamic> vars = {};
    if (verboseLevel > 1) {
      print("".padLeft(_depth * 2) + " -> $what ($orgWhat @ $orgPosition)");
    }

    for (String instruction in _readingInstructions[what]) {
      // Special-case a few things that aren't (easily) described in the
      // binary.md file.
      if (what == "Name" && instruction == "LibraryReference library;") {
        // Special-case if sentence in Name.
        String name = getDillString(vars["name"]["index"]);
        if (!name.startsWith("_")) continue;
      } else if (what == "ComponentFile" &&
          instruction == "MetadataPayload[] metadataPayloads;") {
        // Special-case skipping metadata payloads.
        _binaryOffset = binaryOffsetForMetadataMappings;
        continue;
      } else if (what == "ComponentFile" &&
          instruction == "RList<MetadataMapping> metadataMappings;") {
        // Special-case skipping metadata mappings.
        _binaryOffset = binaryOffsetForStringTable;
        continue;
      } else if (what == "ComponentIndex" &&
          instruction == "Byte[] 8bitAlignment;") {
        // Special-case 8-byte alignment.
        int sizeWithoutPadding = _binaryOffset +
            ((numLibs + 1) + 10 /* number of fixed fields */) * 4;
        int padding = 8 - sizeWithoutPadding % 8;
        if (padding == 8) padding = 0;
        _binaryOffset += padding;
        continue;
      }

      String type = _getType(instruction);
      String name = instruction.substring(type.length).trim();
      if (name.contains("//")) {
        name = name.substring(0, name.indexOf("//")).trim();
      }
      if (name.contains("=")) {
        name = name.substring(0, name.indexOf("=")).trim();
      }
      if (name.endsWith(";")) name = name.substring(0, name.length - 1);
      int oldOffset = _binaryOffset;

      if (verboseLevel > 1) {
        print("".padLeft(_depth * 2 + 1) +
            " -> $instruction ($type) (@ $_binaryOffset) "
                "($orgWhat @ $orgPosition)");
      }

      bool readNothingIsOk = false;
      if (type.contains("[")) {
        // The type is an array. Read into a List.
        // Note that we need to know the length of that list.
        String count = type.substring(type.indexOf("[") + 1, type.indexOf("]"));
        type = type.substring(0, type.indexOf("["));
        type = _lookupGenericType(typeNames, type, types);

        int intCount = int.tryParse(count) ?? -1;
        if (intCount == -1) {
          if (vars[count] != null && vars[count] is int) {
            intCount = vars[count];
          } else if (count.contains(".")) {
            List<String> countData =
                count.split(regExpSplit).map((s) => s.trim()).toList();
            if (vars[countData[0]] != null) {
              dynamic v = vars[countData[0]];
              if (v is Map &&
                  countData[1] == "last" &&
                  v["items"] is List &&
                  v["items"].last is int) {
                intCount = v["items"].last;
              } else if (v is Map && v[countData[1]] != null) {
                v = v[countData[1]];
                if (v is Map && v[countData[2]] != null) {
                  v = v[countData[2]];
                  if (v is int) intCount = v;
                } else if (v is int &&
                    countData.length == 4 &&
                    countData[2] == "+") {
                  intCount = v + int.parse(countData[3]);
                }
              } else {
                throw "Unknown dot to int ($count)";
              }
            }
          }
        }

        // Special-case that we know how many libraries we have.
        if (intCount < 0 && type == "Library" && _depth == 1) {
          intCount = numLibs;
        }
        if (intCount < 0 &&
            type == "UInt32" &&
            _depth == 2 &&
            count == "libraryCount + 1") {
          intCount = numLibs + 1;
        }

        if (intCount >= 0) {
          readNothingIsOk = intCount == 0;
          List<dynamic> value = new List.filled(intCount, null);
          for (int i = 0; i < intCount; ++i) {
            int oldOffset2 = _binaryOffset;
            value[i] = _readBinary(type);
            if (_binaryOffset <= oldOffset2) {
              throw "Didn't read anything for $type @ $_binaryOffset";
            }
          }
          vars[name] = value;
        } else {
          throw "Array of unknown size ($count)";
        }
      } else {
        // Not an array, read the single field recursively.
        type = _lookupGenericType(typeNames, type, types);
        dynamic value = _readBinary(type);
        vars[name] = value;
        _checkTag(instruction, value);
      }
      if (_binaryOffset <= oldOffset && !readNothingIsOk) {
        throw "Didn't read anything for $type @ $_binaryOffset";
      }

      // Special case that when we read the string table we need to remember it
      // to be able to lookup strings to read names properly later
      // (private names has a library, public names does not).
      if (what == "ComponentFile") {
        if (name == "strings") _dillStringsPointer = vars[name];
      }
    }

    --_depth;
    return vars;
  }

  /// Verify, that if the instruction was a tag with a value
  /// (e.g. "Byte tag = 5;"), then the value read was indeed the expected value
  /// (5 in this example).
  void _checkTag(String instruction, dynamic value) {
    if (instruction.trim().startsWith("Byte tag = ")) {
      String tag = instruction.trim().substring("Byte tag = ".length);
      if (tag.contains("//")) {
        tag = tag.substring(0, tag.indexOf("//")).trim();
      }
      if (tag.endsWith(";")) tag = tag.substring(0, tag.length - 1).trim();
      int tagAsInt = int.tryParse(tag) ?? -1;
      if (tagAsInt >= 0) {
        if (tagAsInt != value) {
          throw "Unexpected tag. "
              "Expected $tagAsInt but got $value (around $_binaryOffset).";
        }
      }
    }
  }

  /// Looks up any generics used, replacing the generic-name (if any) with the
  /// actual type, e.g.
  /// * ([], "UInt", []) into "UInt"
  /// * (["T"], "T", ["Expression"]) into "Expression"
  /// * (["T0", "T1"], "T0", ["FileOffset", "Expression"]) into "FileOffset"
  String _lookupGenericType(
      List<String> typeNames, String type, List<String> types) {
    for (int i = 0; i < typeNames.length; ++i) {
      if (typeNames[i] == type) {
        type = types[i];
        break;
      }
    }
    return type;
  }

  /// Check if [what] is an [a], i.e. if [what] extends [a].
  /// This method uses the [_extends] map and it is thus risky to use it before
  /// the binary.md file has been read in entirety (because the field isn't
  /// completely filled out yet).
  bool _isA(String what, String a) {
    String parent = what;
    while (parent != null) {
      if (parent == a) return true;
      parent = _extends[parent];
    }
    return false;
  }

  /// Remaps the type by looking at tags, e.g. if asked to read an "Expression"
  /// and the tag actually says "Block", return "Block" after checking that a
  /// "Block" is actually an "Expression".
  String _remapWhat(String what) {
    Map<int, String> tagMap;
    if (_isA(what, "Constant")) {
      tagMap = constantTagToName;
    } else {
      tagMap = tagToName;
    }

    if (what == "Expression") {
      if (tagMap[_dillContent[_binaryOffset]] != null) {
        what = tagMap[_dillContent[_binaryOffset]];
        if (!_isA(what, "Expression")) {
          throw "Expected Expression but found $what";
        }
      } else {
        throw "Unknown expression";
      }
    }
    if (what == "IntegerLiteral") {
      if (tagMap[_dillContent[_binaryOffset]] != null) {
        what = tagMap[_dillContent[_binaryOffset]];
        if (!_isA(what, "IntegerLiteral")) {
          throw "Expected IntegerLiteral but found $what";
        }
      } else {
        throw "Unknown IntegerLiteral";
      }
    }
    if (what == "Statement") {
      if (tagMap[_dillContent[_binaryOffset]] != null) {
        what = tagMap[_dillContent[_binaryOffset]];
        if (!_isA(what, "Statement")) {
          throw "Expected Statement but found $what";
        }
      } else {
        throw "Unknown Statement";
      }
    }
    if (what == "Initializer") {
      if (tagMap[_dillContent[_binaryOffset]] != null) {
        what = tagMap[_dillContent[_binaryOffset]];
        if (!_isA(what, "Initializer")) {
          throw "Expected Initializer but found $what";
        }
      } else {
        throw "Unknown Initializer";
      }
    }
    if (what == "DartType") {
      if (tagMap[_dillContent[_binaryOffset]] != null) {
        what = tagMap[_dillContent[_binaryOffset]];
        if (!_isA(what, "DartType")) {
          throw "Expected DartType but found $what";
        }
      } else {
        throw "Unknown DartType at $_binaryOffset "
            "(${_dillContent[_binaryOffset]})";
      }
    }
    if (what.startsWith("Option<")) {
      if (tagMap[_dillContent[_binaryOffset]] != null &&
          tagMap[_dillContent[_binaryOffset]].startsWith("Something<")) {
        what = what.replaceFirst("Option<", "Something<");
      }
    }
    if (what == "Constant") {
      if (tagMap[_dillContent[_binaryOffset]] != null) {
        what = tagMap[_dillContent[_binaryOffset]];
        if (!_isA(what, "Constant")) {
          throw "Expected Constant but found $what";
        }
      } else {
        throw "Unknown Constant";
      }
    }

    return what;
  }

  /// Read the "UInt" type as used in kernel. This is hard-coded.
  /// Note that this decrements the [_depth] and increments the
  /// [_binaryOffset] correctly.
  int _readUint() {
    int b = _dillContent[_binaryOffset];
    if (b & 128 == 0) {
      ++_binaryOffset;
      --_depth;
      return b;
    }
    if (b & 192 == 128) {
      int value = (_dillContent[_binaryOffset] & 63) << 8 |
          _dillContent[_binaryOffset + 1];
      _binaryOffset += 2;
      --_depth;
      return value;
    }
    if (b & 192 == 192) {
      int value = (_dillContent[_binaryOffset] & 63) << 24 |
          _dillContent[_binaryOffset + 1] << 16 |
          _dillContent[_binaryOffset + 2] << 8 |
          _dillContent[_binaryOffset + 3];
      _binaryOffset += 4;
      --_depth;
      return value;
    }
    throw "Unexpected UInt";
  }

  /// Read the "UInt43" type as used in kernel. This is hard-coded.
  /// Note that this decrements the [_depth] and increments the
  /// [_binaryOffset] correctly.
  int _readUint32() {
    int value = (_dillContent[_binaryOffset] & 63) << 24 |
        _dillContent[_binaryOffset + 1] << 16 |
        _dillContent[_binaryOffset + 2] << 8 |
        _dillContent[_binaryOffset + 3];
    _binaryOffset += 4;
    --_depth;
    return value;
  }

  /// Read the "UInt32" type as used in kernel. This is hard-coded.
  /// This does not change any state.
  int _peekUint32() {
    return (_dillContent[_binaryOffset] & 63) << 24 |
        _dillContent[_binaryOffset + 1] << 16 |
        _dillContent[_binaryOffset + 2] << 8 |
        _dillContent[_binaryOffset + 3];
  }
}

class DillComparer {
  Map<int, String> tagToName;
  StringBuffer outputTo;

  bool compare(List<int> a, List<int> b, String binaryMd,
      [StringBuffer outputTo]) {
    this.outputTo = outputTo;
    bool printOnExit = false;
    if (this.outputTo == null) {
      this.outputTo = new StringBuffer();
      printOnExit = true;
    }
    BinaryMdDillReader readerA = new BinaryMdDillReader(binaryMd, a);
    dynamic aResult = readerA.attemptRead();
    tagToName = readerA.tagToName;

    BinaryMdDillReader readerB = new BinaryMdDillReader(binaryMd, b);
    dynamic bResult = readerB.attemptRead();

    bool result = _compareInternal(aResult, bResult);
    if (printOnExit) print(outputTo);
    return result;
  }

  List<String> stack = [];

  int outputLines = 0;

  void printDifference(String s) {
    outputTo.writeln("----------");
    outputTo.writeln(s);
    outputTo.writeln("'Stacktrace':");
    stack.forEach(outputTo.writeln);
    outputLines += 3 + stack.length;
  }

  bool _compareInternal(dynamic a, dynamic b) {
    if (a.runtimeType != b.runtimeType) {
      printDifference(
          "Different runtime types (${a.runtimeType} and ${b.runtimeType})");
      return false;
    }

    bool result = true;
    if (a is List) {
      List listA = a;
      List listB = b;
      int length = listA.length;
      if (listA.length != listB.length) {
        printDifference(
            "Lists have different length (${listA.length} vs ${listB.length})");
        result = false;
        if (listB.length < listA.length) length = listB.length;
      }
      for (int i = 0; i < length; i++) {
        stack.add("Lists at index $i ${_getTag(a)}");
        if (!_compareInternal(listA[i], listB[i])) {
          result = false;
        }
        stack.removeLast();
        if (outputLines > 1000) return result;
      }
      return result;
    }

    if (a is Map<String, dynamic>) {
      Map<String, dynamic> mapA = a;
      Map<String, dynamic> mapB = b;
      for (String key in mapA.keys) {
        dynamic valueA = mapA[key];
        dynamic valueB = mapB[key];
        stack.add("Map with key '$key' ${_getTag(a)}");
        if (!_compareInternal(valueA, valueB)) {
          result = false;
        }
        stack.removeLast();
        if (outputLines > 1000) return result;
      }
      if (mapA.length != mapB.length) {
        printDifference("Maps have different number of entries "
            "(${mapA.length} vs ${mapB.length}). ${_getTag(a)}");
        result = false;
      }
      return result;
    }

    if (a is int) {
      if (a != b) {
        printDifference("Integers differ: $a vs $b");
        return false;
      }
      return true;
    }

    throw "Unsupported: ${a.runtimeType}";
  }

  String _getTag(dynamic input) {
    if (input is Map) {
      dynamic tag = input["tag"];
      if (tag != null) {
        if (tagToName[tag] != null) {
          return "(tag $tag, likely '${tagToName[tag]}')";
        }
        return "(tag $tag)";
      }
    }
    return "";
  }
}
