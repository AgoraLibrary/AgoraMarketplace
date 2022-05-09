import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:file/file.dart';
import 'package:tool/src/android/android.dart' as android_common;
import 'package:tool/src/base/utils.dart';
import 'package:tool/src/commands/command.dart';
import 'package:tool/src/commands/create/create_command_options.dart';
import 'package:tool/src/globals.dart' as globals;
import 'package:tool/src/template/template.dart';
import 'package:uuid/uuid.dart';

/// A list of all possible create platforms, even those that may not be enabled
/// with the current config.
const List<String> kAllCreatePlatforms = <String>[
  'ios',
  'android',
  'windows',
  'linux',
  'macos',
  'web',
  'winuwp',
];

class CreateCommand extends Command<CreateCommandOptions> {
  @override
  ArgResults parse(List<String> args) {
    commandOptions = parseCreateCommandOptions(args);

    if (commandOptions.help) {
      printUsage();
      exit(0);
    }

    return commandOptions.getArgParser().parse(args);
  }

  /// The output directory of the command.
  Directory get projectDir {
    return globals.fs.directory(argResults?.rest.first);
  }

  /// The normalized absolute path of [projectDir].
  String get projectDirPath {
    return globals.fs.path.normalize(projectDir.absolute.path);
  }

  /// Gets the flutter root directory.
  String get marketplaceRoot => globals.marketplaceRoot;

  /// Throw with exit code 2 if the output directory is invalid.
  void validateOutputDirectoryArg() {
    if (argResults?.rest.isEmpty ?? true) {
      throw ('No option specified for the output directory.\n$usage');
    }

    if ((argResults?.rest.length ?? 0) > 1) {
      String message = 'Multiple output directories specified.';
      for (final String arg in argResults?.rest ?? []) {
        if (arg.startsWith('-')) {
          message += '\nTry moving $arg to be immediately following $name';
          break;
        }
      }
      throw (message);
    }
  }

  /// Determines the organization.
  ///
  /// If `--org` is specified in the command, returns that directly.
  /// If `--org` is not specified, returns the organization from the existing project.
  Future<String> getOrganization() async {
    String organization = commandOptions.organization;
    if (!(argResults?.wasParsed('org') ?? false)) {
      final Set<String> existingOrganizations = {};
      if (existingOrganizations.length == 1) {
        organization = existingOrganizations.first;
      } else if (existingOrganizations.length > 1) {
        throw ('Ambiguous organization in existing files: $existingOrganizations. '
            'The --org command line argument must be specified to recreate project.');
      }
    }
    return organization;
  }

  /// Throws with exit 2 if the project directory is illegal.
  void validateProjectDir({bool overwrite = false}) {
    if (globals.fs.path.isWithin(marketplaceRoot, projectDirPath)) {
      // Make exception for dev and examples to facilitate example project development.
      final String examplesDirectory =
          globals.fs.path.join(marketplaceRoot, 'examples');
      final String devDirectory = globals.fs.path.join(marketplaceRoot, 'dev');
      if (!globals.fs.path.isWithin(examplesDirectory, projectDirPath) &&
          !globals.fs.path.isWithin(devDirectory, projectDirPath)) {
        throw ('Cannot create a project within the AgoraMarketplace SDK. '
            "Target directory '$projectDirPath' is within the AgoraMarketplace SDK at '$marketplaceRoot'.");
      }
    }

    // If the destination directory is actually a file, then we refuse to
    // overwrite, on the theory that the user probably didn't expect it to exist.
    if (globals.fs.isFileSync(projectDirPath)) {
      final String message =
          "Invalid project name: '$projectDirPath' - refers to an existing file.";
      throw (overwrite
          ? '$message Refusing to overwrite a file with a directory.'
          : message);
    }

    if (overwrite) {
      return;
    }

    final FileSystemEntityType type = globals.fs.typeSync(projectDirPath);

    switch (type) {
      case FileSystemEntityType.file:
        // Do not overwrite files.
        throw ("Invalid project name: '$projectDirPath' - file exists.");
        break;
      case FileSystemEntityType.link:
        // Do not overwrite links.
        throw ("Invalid project name: '$projectDirPath' - refers to a link.");
        break;
      default:
    }
  }

  /// Gets the project name based.
  ///
  /// Use the current directory path name if the `--project-name` is not specified explicitly.
  String get projectName {
    final String projectName =
        commandOptions.projectName ?? globals.fs.path.basename(projectDirPath);
    // if (!boolArg('skip-name-checks')) {
    if (!false) {
      final String? error = _validateProjectName(projectName);
      if (error != null) {
        throw (error);
      }
    }
    return projectName;
  }

  /// Creates a template to use for [renderTemplate].
  Map<String, Object> createTemplateContext({
    required String organization,
    required String projectName,
    required String projectDescription,
    required String androidLanguage,
    required String iosLanguage,
    bool withPluginHook = false,
    bool ios = false,
    bool android = false,
    bool web = false,
    bool linux = false,
    bool macos = false,
    bool windows = false,
    bool windowsUwp = false,
  }) {
    final String pluginDartClass = _createPluginClassName(projectName);
    final String pluginClass = pluginDartClass.endsWith('Plugin')
        ? pluginDartClass
        : '${pluginDartClass}Plugin';
    final String pluginClassSnakeCase = snakeCase(pluginClass);
    final String pluginClassCapitalSnakeCase =
        pluginClassSnakeCase.toUpperCase();
    final String appleIdentifier =
        createUTIIdentifier(organization, projectName);
    final String androidIdentifier =
        createAndroidIdentifier(organization, projectName);
    final String windowsIdentifier =
        createWindowsIdentifier(organization, projectName);
    // Linux uses the same scheme as the Android identifier.
    // https://developer.gnome.org/gio/stable/GApplication.html#g-application-id-is-valid
    final String linuxIdentifier = androidIdentifier;

    return <String, Object>{
      'organization': organization,
      'projectName': projectName,
      'androidIdentifier': androidIdentifier,
      'iosIdentifier': appleIdentifier,
      'macosIdentifier': appleIdentifier,
      'linuxIdentifier': linuxIdentifier,
      'windowsIdentifier': windowsIdentifier,
      'description': projectDescription,
      'androidMinApiLevel': android_common.minApiLevel,
      'androidSdkVersion': android_common.sdkVersion,
      'androidNdkVersion': android_common.ndkVersion,
      'pluginClass': pluginClass,
      'pluginClassSnakeCase': pluginClassSnakeCase,
      'pluginClassCapitalSnakeCase': pluginClassCapitalSnakeCase,
      'withPluginHook': withPluginHook,
      'androidLanguage': androidLanguage,
      'iosLanguage': iosLanguage,
      'ios': ios,
      'android': android,
      'web': web,
      'linux': linux,
      'macos': macos,
      'windows': windows,
      'winuwp': windowsUwp,
      'year': DateTime.now().year,
    };
  }

  /// Renders the template, generate files into `directory`.
  ///
  /// `templateName` should match one of directory names under flutter_tools/template/.
  /// If `overwrite` is true, overwrites existing files, `overwrite` defaults to `false`.
  Future<int> renderTemplate(
      String templateName, Directory directory, Map<String, Object> context,
      {bool overwrite = false}) async {
    final Template template = await Template.fromName(
      templateName,
      fileSystem: globals.fs,
      templateRenderer: globals.templateRenderer,
    );
    return template.render(directory, context, overwriteExisting: overwrite);
  }

  /// Merges named templates into a single template, output to `directory`.
  ///
  /// `names` should match directory names under flutter_tools/template/.
  ///
  /// If `overwrite` is true, overwrites existing files, `overwrite` defaults to `false`.
  Future<int> renderMerged(
      List<String> names, Directory directory, Map<String, Object> context,
      {bool overwrite = false}) async {
    final Template template = await Template.merged(
      names,
      directory,
      fileSystem: globals.fs,
      templateRenderer: globals.templateRenderer,
    );
    return template.render(directory, context, overwriteExisting: overwrite);
  }

  Future<int> _generatePlugin(
      Directory directory, Map<String, Object> templateContext,
      {bool overwrite = false}) async {
    // Plugins only add a platform if it was requested explicitly by the user.
    if (!(argResults?.wasParsed('platforms') ?? false)) {
      for (final String platform in kAllCreatePlatforms) {
        templateContext[platform] = false;
      }
    }
    final List<String> platformsToAdd =
        _getSupportedPlatformsFromTemplateContext(templateContext);

    final List<String> existingPlatforms =
        _getSupportedPlatformsInPlugin(directory);
    for (final String existingPlatform in existingPlatforms) {
      // re-generate files for existing platforms
      templateContext[existingPlatform] = true;
    }

    final bool willAddPlatforms = platformsToAdd.isNotEmpty;
    templateContext['no_platforms'] = !willAddPlatforms;
    int generatedCount = 0;
    final String description = argResults?.wasParsed('description') ?? false
        ? commandOptions.description
        : 'A new AgoraMarketplace plugin project.';
    templateContext['description'] = description;
    generatedCount += await renderTemplate('plugin', directory, templateContext,
        overwrite: overwrite);

    final String projectName = templateContext['projectName'] as String;
    final String organization = templateContext['organization'] as String;
    final String androidPluginIdentifier =
        templateContext['androidIdentifier'] as String;
    final String exampleProjectName = '${projectName}_example';
    templateContext['projectName'] = exampleProjectName;
    templateContext['androidIdentifier'] =
        createAndroidIdentifier(organization, exampleProjectName);
    templateContext['iosIdentifier'] =
        createUTIIdentifier(organization, exampleProjectName);
    templateContext['macosIdentifier'] =
        createUTIIdentifier(organization, exampleProjectName);
    templateContext['windowsIdentifier'] =
        createWindowsIdentifier(organization, exampleProjectName);
    templateContext['description'] =
        'Demonstrates how to use the $projectName plugin.';
    templateContext['pluginProjectName'] = projectName;
    templateContext['androidPluginIdentifier'] = androidPluginIdentifier;

    generatedCount += await generateApp(
        'app', projectDir.childDirectory('example'), templateContext,
        overwrite: overwrite, pluginExampleApp: true);
    return generatedCount;
  }

  List<String> _getSupportedPlatformsFromTemplateContext(
      Map<String, dynamic> templateContext) {
    return <String>[
      for (String platform in kAllCreatePlatforms)
        if (templateContext[platform] == true) platform
    ];
  }

  // Determine what platforms are supported based on generated files.
  List<String> _getSupportedPlatformsInPlugin(Directory projectDir) {
    return ['android', 'ios'];
  }

  /// Generate application project in the `directory` using `templateContext`.
  ///
  /// If `overwrite` is true, overwrites existing files, `overwrite` defaults to `false`.
  Future<int> generateApp(String templateName, Directory directory,
      Map<String, Object> templateContext,
      {bool overwrite = false, bool pluginExampleApp = false}) async {
    int generatedCount = 0;
    generatedCount += await renderMerged(
      <String>[templateName],
      directory,
      templateContext,
      overwrite: overwrite,
    );
    return generatedCount;
  }

  /// Creates an android identifier.
  ///
  /// Android application ID is specified in: https://developer.android.com/studio/build/application-id
  /// All characters must be alphanumeric or an underscore [a-zA-Z0-9_].
  static String createAndroidIdentifier(String organization, String name) {
    String tmpIdentifier = '$organization.$name';
    final RegExp disallowed = RegExp(r'[^\w\.]');
    tmpIdentifier = tmpIdentifier.replaceAll(disallowed, '');

    // It must have at least two segments (one or more dots).
    final List<String> segments = tmpIdentifier
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    while (segments.length < 2) {
      segments.add('untitled');
    }

    // Each segment must start with a letter.
    final RegExp segmentPatternRegex = RegExp(r'^[a-zA-Z][\w]*$');
    final List<String> prefixedSegments = segments.map((String segment) {
      if (!segmentPatternRegex.hasMatch(segment)) {
        return 'u$segment';
      }
      return segment;
    }).toList();
    return prefixedSegments.join('.');
  }

  /// Creates a Windows package name.
  ///
  /// Package names must be a globally unique, commonly a GUID.
  static String createWindowsIdentifier(String organization, String name) {
    return const Uuid().v4().toUpperCase();
  }

  String _createPluginClassName(String name) {
    final String camelizedName = camelCase(name);
    return camelizedName[0].toUpperCase() + camelizedName.substring(1);
  }

  /// Create a UTI (https://en.wikipedia.org/wiki/Uniform_Type_Identifier) from a base name
  static String createUTIIdentifier(String organization, String name) {
    name = camelCase(name);
    String tmpIdentifier = '$organization.$name';
    final RegExp disallowed = RegExp(r'[^a-zA-Z0-9\-\.\u0080-\uffff]+');
    tmpIdentifier = tmpIdentifier.replaceAll(disallowed, '');

    // It must have at least two segments (one or more dots).
    final List<String> segments = tmpIdentifier
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    while (segments.length < 2) {
      segments.add('untitled');
    }

    return segments.join('.');
  }

  @override
  String get description => '';

  @override
  String get name => 'create';

  @override
  Future<void> runCommand() async {
    validateOutputDirectoryArg();

    final String organization = await getOrganization();

    final bool overwrite = commandOptions.overwrite;
    validateProjectDir(overwrite: overwrite);

    final Map<String, Object> templateContext = createTemplateContext(
      organization: organization,
      projectName: projectName,
      projectDescription: commandOptions.description,
      withPluginHook: true,
      androidLanguage: 'java',
      iosLanguage: 'oc',
      ios: commandOptions.platforms?.contains('ios') ?? false,
      android: commandOptions.platforms?.contains('android') ?? false,
      web: commandOptions.platforms?.contains('web') ?? false,
      linux: commandOptions.platforms?.contains('linux') ?? false,
      macos: commandOptions.platforms?.contains('macos') ?? false,
      windows: commandOptions.platforms?.contains('windows') ?? false,
      windowsUwp: commandOptions.platforms?.contains('winuwp') ?? false,
    );

    final String relativeDirPath = globals.fs.path.relative(projectDirPath);
    final bool creatingNewProject =
        !projectDir.existsSync() || projectDir.listSync().isEmpty;
    if (creatingNewProject) {
      print('Creating project $relativeDirPath...');
    } else {
      if (!overwrite) {
        throw ('Will not overwrite existing project in $relativeDirPath: '
            'must specify --overwrite for samples to overwrite.');
      }
      print('Recreating project $relativeDirPath...');
    }

    final Directory relativeDir = globals.fs.directory(projectDirPath);
    int generatedFileCount = 0;
    generatedFileCount += await _generatePlugin(relativeDir, templateContext,
        overwrite: commandOptions.overwrite);

    print('Wrote $generatedFileCount files.');
    print('\nAll done!');
  }
}

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-zA-Z_][a-zA-Z0-9_]*');

// non-contextual dart keywords.
//' https://dart.dev/guides/language/language-tour#keywords
const Set<String> _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'inout',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'native',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'out',
  'part',
  'patch',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'source',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

const Set<String> _packageDependencies = <String>{
  'collection',
  'flutter',
  'flutter_test',
  'meta',
};

/// Whether [name] is a valid Pub package.
bool isValidPackageName(String name) {
  final Match? match = _identifierRegExp.matchAsPrefix(name);
  return match != null && match.end == name.length && !_keywords.contains(name);
}

// Return null if the project name is legal. Return a validation message if
// we should disallow the project name.
String? _validateProjectName(String projectName) {
  if (!isValidPackageName(projectName)) {
    return '"$projectName" is not a valid Dart package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.';
  }
  if (_packageDependencies.contains(projectName)) {
    return "Invalid project name: '$projectName' - this will conflict with AgoraMarketplace "
        'package dependencies.';
  }
  return null;
}
