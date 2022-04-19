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

    if (commandOptions.projectName?.isEmpty ?? true) {
      printUsage();
      exit(0);
    }

    if (commandOptions.platforms?.isEmpty ?? true) {
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
    if (!argResults!.wasParsed('platforms')) {
      for (final String platform in kAllCreatePlatforms) {
        templateContext[platform] = false;
      }
    }
    final List<String> platformsToAdd =
        _getSupportedPlatformsFromTemplateContext(templateContext);

    final bool willAddPlatforms = platformsToAdd.isNotEmpty;
    templateContext['no_platforms'] = !willAddPlatforms;
    int generatedCount = 0;
    final String description = commandOptions.description;
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
    };
  }

  @override
  String get description => '';

  @override
  String get name => 'create';

  @override
  Future<void> runCommand() async {
    final Map<String, Object> templateContext = createTemplateContext(
      organization: commandOptions.organization,
      projectName: commandOptions.projectName!,
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
      if (!commandOptions.overwrite) {
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
