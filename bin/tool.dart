import 'dart:developer';
import 'dart:io';

import 'package:file/local.dart';
import 'package:mustache_template/mustache.dart' as mustache;
import 'package:path/path.dart';
import 'package:file/file.dart';

/// An indirection around our mustache templating system to avoid a
/// dependency on mustache..
abstract class TemplateRenderer {
  const TemplateRenderer();

  String renderString(String template, dynamic context,
      {bool htmlEscapeValues = false});
}

/// An indirection around mustache use to allow google3 to use a different dependency.
class MustacheTemplateRenderer extends TemplateRenderer {
  const MustacheTemplateRenderer();

  @override
  String renderString(String template, dynamic context,
      {bool htmlEscapeValues = false}) {
    return mustache.Template(template, htmlEscapeValues: htmlEscapeValues)
        .renderString(context);
  }
}

/// Expands templates in a directory to a destination. All files that must
/// undergo template expansion should end with the '.tmpl' extension. All files
/// that should be replaced with the corresponding image from
/// flutter_template_images should end with the '.img.tmpl' extension. All other
/// files are ignored. In case the contents of entire directories must be copied
/// as is, the directory itself can end with '.tmpl' extension. Files within
/// such a directory may also contain the '.tmpl' or '.img.tmpl' extensions and
/// will be considered for expansion. In case certain files need to be copied
/// but without template expansion (data files, etc.), the '.copy.tmpl'
/// extension may be used. Furthermore, templates may contain additional
/// test files intended to run on the CI. Test files must end in `.test.tmpl`
/// and are only included when the --implementation-tests flag is enabled.
///
/// Folders with platform/language-specific content must be named
/// '<platform>-<language>.tmpl'.
///
/// Files in the destination will contain none of the '.tmpl', '.copy.tmpl',
/// 'img.tmpl', or '-<language>.tmpl' extensions.
class Template {
  factory Template(
    Directory templateSource, {
    required FileSystem fileSystem,
    required TemplateRenderer templateRenderer,
  }) {
    return Template._(
      <Directory>[templateSource],
      fileSystem: fileSystem,
      templateRenderer: templateRenderer,
    );
  }

  Template._(
    List<Directory> templateSources, {
    required FileSystem fileSystem,
    required TemplateRenderer templateRenderer,
  })  : _fileSystem = fileSystem,
        _templateRenderer = templateRenderer {
    for (final Directory sourceDirectory in templateSources) {
      if (!sourceDirectory.existsSync()) {
        throw 'Template source directory does not exist: ${sourceDirectory.absolute.path}';
      }
    }

    final Map<FileSystemEntity, Directory> templateFiles =
        <FileSystemEntity, Directory>{
      for (final Directory sourceDirectory in templateSources)
        for (final FileSystemEntity entity
            in sourceDirectory.listSync(recursive: true))
          entity: sourceDirectory,
    };
    for (final FileSystemEntity entity
        in templateFiles.keys.whereType<File>()) {
      final String relativePath = fileSystem.path
          .relative(entity.path, from: templateFiles[entity]!.absolute.path);
      if (relativePath.contains(templateExtension)) {
        // If '.tmpl' appears anywhere within the path of this entity, it is
        // is a candidate for rendering. This catches cases where the folder
        // itself is a template.
        _templateFilePaths[relativePath] =
            fileSystem.path.absolute(entity.path);
      }
    }
  }

  final FileSystem _fileSystem;
  final TemplateRenderer _templateRenderer;

  static const String templateExtension = '.tmpl';
  static const String copyTemplateExtension = '.copy.tmpl';
  final Pattern _kTemplateLanguageVariant = RegExp(r'(\w+)-(\w+)\.tmpl.*');

  final Map<String /* relative */, String /* absolute source */ >
      _templateFilePaths = <String, String>{};

  /// Render the template into [directory].
  ///
  /// May throw a [ToolExit] if the directory is not writable.
  int render(
    Directory destination,
    Map<String, Object> context, {
    bool overwriteExisting = true,
    bool printStatusWhenWriting = true,
  }) {
    try {
      destination.createSync(recursive: true);
    } on FileSystemException catch (err) {
      log(err.toString());
      throw 'Failed to flutter create at ${destination.path}.';
    }
    int fileCount = 0;

    /// Returns the resolved destination path corresponding to the specified
    /// raw destination path, after performing language filtering and template
    /// expansion on the path itself.
    ///
    /// Returns null if the given raw destination path has been filtered.
    String? renderPath(String relativeDestinationPath) {
      final Match? match =
          _kTemplateLanguageVariant.matchAsPrefix(relativeDestinationPath);
      if (match != null) {
        final String platform = match.group(1)!;
        final String? language = context['${platform}Language'] as String?;
        if (language != match.group(2)) {
          return null;
        }
        relativeDestinationPath = relativeDestinationPath.replaceAll(
            '$platform-$language.tmpl', platform);
      }

      final bool android = (context['android'] as bool?) == true;
      if (relativeDestinationPath.contains('android') && !android) {
        return null;
      }

      final bool ios = (context['ios'] as bool?) == true;
      if (relativeDestinationPath.contains('ios') && !ios) {
        return null;
      }

      // Only build a web project if explicitly asked.
      final bool web = (context['web'] as bool?) == true;
      if (relativeDestinationPath.contains('web') && !web) {
        return null;
      }
      // Only build a Linux project if explicitly asked.
      final bool linux = (context['linux'] as bool?) == true;
      if (relativeDestinationPath.startsWith('linux.tmpl') && !linux) {
        return null;
      }
      // Only build a macOS project if explicitly asked.
      final bool macOS = (context['macos'] as bool?) == true;
      if (relativeDestinationPath.startsWith('macos.tmpl') && !macOS) {
        return null;
      }
      // Only build a Windows project if explicitly asked.
      final bool windows = (context['windows'] as bool?) == true;
      if (relativeDestinationPath.startsWith('windows.tmpl') && !windows) {
        return null;
      }
      // Only build a Windows UWP project if explicitly asked.
      final bool windowsUwp = (context['winuwp'] as bool?) == true;
      if (relativeDestinationPath.startsWith('winuwp.tmpl') && !windowsUwp) {
        return null;
      }

      final String? projectName = context['projectName'] as String?;
      final String? androidIdentifier = context['androidIdentifier'] as String?;
      final String? pluginClassSnakeCase =
          context['pluginClassSnakeCase'] as String?;
      final String destinationDirPath = destination.absolute.path;
      final String pathSeparator = _fileSystem.path.separator;
      String finalDestinationPath = _fileSystem.path
          .join(destinationDirPath, relativeDestinationPath)
          .replaceAll(copyTemplateExtension, '')
          .replaceAll(templateExtension, '');

      if (android != null && android && androidIdentifier != null) {
        finalDestinationPath = finalDestinationPath.replaceAll(
            'androidIdentifier',
            androidIdentifier.replaceAll('.', pathSeparator));
      }
      if (projectName != null) {
        finalDestinationPath =
            finalDestinationPath.replaceAll('projectName', projectName);
      }
      // This must be before the pluginClass replacement step.
      if (pluginClassSnakeCase != null) {
        finalDestinationPath = finalDestinationPath.replaceAll(
            'pluginClassSnakeCase', pluginClassSnakeCase);
      }
      return finalDestinationPath;
    }

    _templateFilePaths
        .forEach((String relativeDestinationPath, String absoluteSourcePath) {
      final bool withRootModule = context['withRootModule'] as bool? ?? false;
      if (!withRootModule && absoluteSourcePath.contains('flutter_root')) {
        return;
      }

      final String? finalDestinationPath = renderPath(relativeDestinationPath);
      if (finalDestinationPath == null) {
        return;
      }
      final File finalDestinationFile = _fileSystem.file(finalDestinationPath);
      final String relativePathForLogging =
          _fileSystem.path.relative(finalDestinationFile.path);

      // Step 1: Check if the file needs to be overwritten.

      if (finalDestinationFile.existsSync()) {
        if (overwriteExisting) {
          finalDestinationFile.deleteSync(recursive: true);
          if (printStatusWhenWriting) {
            log('  $relativePathForLogging (overwritten)');
          }
        } else {
          // The file exists but we cannot overwrite it, move on.
          if (printStatusWhenWriting) {
            log('  $relativePathForLogging (existing - skipped)');
          }
          return;
        }
      } else {
        if (printStatusWhenWriting) {
          log('  $relativePathForLogging (created)');
        }
      }

      fileCount += 1;

      finalDestinationFile.createSync(recursive: true);
      final File sourceFile = _fileSystem.file(absoluteSourcePath);

      // Step 2: If the absolute paths ends with a '.copy.tmpl', this file does
      //         not need mustache rendering but needs to be directly copied.

      if (sourceFile.path.endsWith(copyTemplateExtension)) {
        sourceFile.copySync(finalDestinationFile.path);

        return;
      }

      // Step 4: If the absolute path ends with a '.tmpl', this file needs
      //         rendering via mustache.

      if (sourceFile.path.endsWith(templateExtension)) {
        final String templateContents = sourceFile.readAsStringSync();
        final String renderedContents =
            _templateRenderer.renderString(templateContents, context);

        finalDestinationFile.writeAsStringSync(renderedContents);

        return;
      }

      // Step 5: This file does not end in .tmpl but is in a directory that
      //         does. Directly copy the file to the destination.
      sourceFile.copySync(finalDestinationFile.path);
    });

    return fileCount;
  }
}

void main(List<String> arguments) {
  print('Hello world!');
  const fileSystem = LocalFileSystem();
  print(fileSystem.currentDirectory);
  Template(fileSystem.directory("template"),
          fileSystem: fileSystem, templateRenderer: MustacheTemplateRenderer())
      .render(
    fileSystem.directory("output"),
    {
      "android": true,
      "ios": true,
      "androidIdentifier": "io.agora.rte.extension.yitu",
      "projectName": "YituExtension",
      "extensionName": "YituExtension",
      "vendorName": "Yitu",
    },
  );
}
