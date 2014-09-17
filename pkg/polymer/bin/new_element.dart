/// 
/// Script to create boilerplate for a Polymer element.
/// Produces .dart and .html files for the element.
/// 
/// Run this script with pub run:
/// 
///     pub run polymer:new_element element-name [-o output_dir]
/// 
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path show absolute, dirname, join, split;
import 'package:polymer/html_element_names.dart';

void printUsage(ArgParser parser) {
  print('pub run polymer:new_element [-o output_dir] [-e super-element] '
        'element-name');
  print(parser.getUsage());
}

void main(List<String> args) {
  var parser = new ArgParser(allowTrailingOptions: true);
  
  parser.addOption('output-dir', abbr: 'o', help: 'Output directory');
  parser.addOption('extends', abbr: 'e', 
      help: 'Extends polymer-element or DOM element (e.g., div, span)');
  parser.addFlag('help', abbr: 'h');
  
  var options, element;
  try {
    options = parser.parse(args);
    if (options['help']) {
      printUsage(parser);
      return;
    }
    if (options.rest == null || options.rest.isEmpty) {
      throw new FormatException('No element specified');
    }
    element = options.rest[0];
    if (!_isPolymerElement(element)) {
      throw new FormatException('Must specify polymer-element to create.\n'
          'polymer-element must be all lowercase with at least 1 hyphen.');
    }
  } catch(e) {
    print('$e\n');
    printUsage(parser);
    exitCode = 1;
    return;
  } 
  
  var outputDir, startDir;
  
  var outputPath = options['output-dir'];
  
  if (outputPath == null) {
    if ((new File('pubspec.yaml')).existsSync()) {
      print('When creating elements in root directory of package, '
          '-o <dir> must be specified');
        exitCode = 1;
        return;
    }
    outputDir = (new Directory('.')).resolveSymbolicLinksSync();
  } else {
    var outputDirLocation = new Directory(outputPath);
    if (!outputDirLocation.existsSync()) {
      outputDirLocation.createSync(recursive: true);
    }
    outputDir = (new Directory(outputPath)).resolveSymbolicLinksSync();
  }

  var pubspecDir = _findDirWithFile(outputDir, 'pubspec.yaml');
  
  if (pubspecDir == null) {
    print('Could not find pubspec.yaml when walking up from $outputDir');
    exitCode = 1;
    return;
  }

  var length = path.split(pubspecDir).length;
  var distanceToPackageRoot =
      path.split(outputDir).length - length;

  // See dartbug.com/20076 for the algorithm used here.
  if (distanceToPackageRoot > 0) {
    if (path.split(outputDir)[length] == 'lib') {
      distanceToPackageRoot++;
    } else {
      distanceToPackageRoot--;
    }
  }
  
  var superElement = options['extends'];
  
  if ((superElement == null ) || 
      _isDOMElement(superElement) ||
      _isPolymerElement(superElement)) {
    try {
      _createBoilerPlate(element, options['extends'], outputDir, 
          distanceToPackageRoot);
    } on Exception catch(e, t) {
      print('Error creating files in $outputDir');
      print('$e $t');
      exitCode = 1;
      return;
    }
  } else {
    if (superElement.contains('-')) {
      print('Extending invalid element "$superElement". Polymer elements '
          'may contain only lowercase letters at least one hyphen.');
    } else {
      print('Extending invalid element "$superElement". $superElement is not '
          ' a builtin DOM type.');
    }
    exitCode = 1;
    return;
  }
 
  return;
}

String _findDirWithFile(String dir, String filename) {
  while (!new File(path.join(dir, filename)).existsSync()) {
    var parentDir = path.dirname(dir);
    // If we reached root and failed to find it, bail.
    if (parentDir == dir) return null;
    dir = parentDir;
  }
  return dir;
}

bool _isDOMElement(String element) => (HTML_ELEMENT_NAMES[element] != null);

bool _isPolymerElement(String element) {
  return element.contains('-') && (element.toLowerCase() == element);
}

String _toCamelCase(String s) {
  return s[0].toUpperCase() + s.substring(1);
}

void _createBoilerPlate(String element, String superClass, String directory,
                        int distanceToPackageRoot) {
  var segments = element.split('-');
  var capitalizedName = segments.map((e) => _toCamelCase(e)).join('');
  var underscoreName = element.replaceAll('-', '_'); 
  var pathToPackages = '../' * distanceToPackageRoot;
  
  bool superClassIsPolymer = 
      (superClass == null ? false : _isPolymerElement(superClass));

  var classDeclaration = '';
  var importDartHtml = '';
  var polymerCreatedString = '';
  var extendsElementString = '';
  var shadowString = '';
  
  if (superClass == null) {
    classDeclaration = '\nclass $capitalizedName extends PolymerElement {';
  } else if (superClassIsPolymer) {
    // The element being extended is a PolymerElement.
    var camelSuperClass =
        superClass.split('-').map((e) => _toCamelCase(e)).join('');
    classDeclaration = 'class $capitalizedName extends $camelSuperClass {';
    extendsElementString = ' extends="$superClass"';
    shadowString = 
        '\n    <!-- Render extended element\'s Shadow DOM here -->\n'
        '    <shadow>\n    </shadow>';
  } else {
    // The element being extended is a DOM Class.
    importDartHtml = "import 'dart:html';\n";
    classDeclaration = 
        'class $capitalizedName extends ${HTML_ELEMENT_NAMES[superClass]} '
        'with Polymer, Observable {';
    polymerCreatedString = '\n    polymerCreated();';
    extendsElementString = ' extends="$superClass"';
  }

  String html = '''  
<!-- import polymer-element's definition -->
<link rel="import" href="${pathToPackages}packages/polymer/polymer.html">

<polymer-element name="$element"$extendsElementString>
  <template>
    <style>
      :host {
        display: block;
      }
    </style>$shadowString
    <!-- Template content here -->
  </template>
  <script type="application/dart" src="${underscoreName}.dart"></script>
</polymer-element>
''';

  String htmlFile = path.join(directory, underscoreName + '.html');
  new File(htmlFile).writeAsStringSync(html);

  String dart = '''
${importDartHtml}import 'package:polymer/polymer.dart';

/**
 * A Polymer $element element.
 */
@CustomTag('$element')
$classDeclaration

  /// Constructor used to create instance of ${capitalizedName}.
  ${capitalizedName}.created() : super.created() {$polymerCreatedString
  }

  /*
   * Optional lifecycle methods - uncomment if needed.
   *

  /// Called when an instance of $element is inserted into the DOM.
  attached() {
    super.attached();
  }

  /// Called when an instance of $element is removed from the DOM.
  detached() {
    super.detached();
  }

  /// Called when an attribute (such as  a class) of an instance of
  /// $element is added, changed, or removed.
  attributeChanged(String name, String oldValue, String newValue) {
  }

  /// Called when $element has been fully prepared (Shadow DOM created,
  /// property observers set up, event listeners attached).
  ready() {
  }
   
  */
  
}
''';

  String dartFile = path.join(directory, underscoreName + '.dart');
  new File(dartFile).writeAsStringSync(dart);
  
  print('Successfully created:');
  print('  ' + path.absolute(path.join(directory, underscoreName + '.dart')));
  print('  ' + path.absolute(path.join(directory, underscoreName + '.html')));
}
