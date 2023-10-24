import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/util.dart';

class CommonElement {
  final BasicInfo oldInfo;
  final BasicInfo newInfo;

  CommonElement(this.oldInfo, this.newInfo);

  String get name => longName(oldInfo, useLibraryUri: true);
}

List<CommonElement> findCommonalities(AllInfo oldInfo, AllInfo newInfo,
    {bool mainOnly = false}) {
  var finder = _InfoCommonElementFinder(oldInfo, newInfo, mainOnly: mainOnly);
  finder.run();
  return finder.commonElements;
}

class _InfoCommonElementFinder extends InfoVisitor<void> {
  final AllInfo _old;
  final AllInfo _new;
  final bool mainOnly;

  late BasicInfo _other;

  List<CommonElement> commonElements = <CommonElement>[];

  _InfoCommonElementFinder(this._old, this._new, {required this.mainOnly});

  void run() {
    _commonList(_old.libraries, _new.libraries);
  }

  @override
  void visitAll(AllInfo info) {
    throw StateError('should not run common on AllInfo');
  }

  @override
  void visitProgram(ProgramInfo info) {
    throw StateError('should not run common on ProgramInfo');
  }

  @override
  void visitOutput(OutputUnitInfo info) {
    throw StateError('should not run common on OutputUnitInfo');
  }

  @override
  void visitConstant(ConstantInfo info) {
    throw StateError('should not run common on ConstantInfo');
  }

  @override
  void visitLibrary(LibraryInfo info) {
    var other = _other as LibraryInfo;
    _addElement(info, other);
    _commonList(info.topLevelVariables, other.topLevelVariables);
    _commonList(info.topLevelFunctions, other.topLevelFunctions);
    _commonList(info.classes, other.classes);
  }

  @override
  void visitClass(ClassInfo info) {
    var other = _other as ClassInfo;
    _addElement(info, other);
    _commonList(info.fields, other.fields);
    _commonList(info.functions, other.functions);
  }

  @override
  void visitClassType(ClassTypeInfo info) {
    var other = _other as ClassInfo;
    _addElement(info, other);
  }

  @override
  void visitClosure(ClosureInfo info) {
    var other = _other as ClosureInfo;
    _addElement(info, other);
    _commonList([info.function], [other.function]);
  }

  @override
  void visitField(FieldInfo info) {
    var other = _other as FieldInfo;
    _addElement(info, other);
    _commonList(info.closures, other.closures);
  }

  @override
  void visitFunction(FunctionInfo info) {
    var other = _other as FunctionInfo;
    _addElement(info, other);
    _commonList(info.closures, other.closures);
  }

  @override
  void visitTypedef(TypedefInfo info) {
    var other = _other as ClassInfo;
    _addElement(info, other);
  }

  void _addElement(BasicInfo info, BasicInfo other) {
    if (!mainOnly || (info.outputUnit?.name) == 'main') {
      commonElements.add(CommonElement(info, other));
    }
  }

  void _commonList(List<BasicInfo> oldInfos, List<BasicInfo> newInfos) {
    var newNames = <String, BasicInfo>{};
    for (var newInfo in newInfos) {
      newNames[longName(newInfo, useLibraryUri: true)] = newInfo;
    }
    for (var oldInfo in oldInfos) {
      var oldName = longName(oldInfo, useLibraryUri: true);
      if (newNames.containsKey(oldName)) {
        _other = newNames[oldName]!;
        oldInfo.accept(this);
      }
    }
  }
}
