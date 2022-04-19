import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:tool/src/base/platform.dart';
import 'package:tool/src/template/template_render/mustache_template.dart';
import 'package:tool/src/template/template_render/template.dart';

String marketplaceRoot = platform.environment["AGORA_MARKETPLACE_ROOT"] ??
    fs.directory(platform.script.path).parent.parent.path;

/// Currently active implementation of the file system.
///
/// By default it uses local disk-based implementation. Override this in tests
/// with [MemoryFileSystem].
FileSystem get fs => localFileSystem;

const Platform _kLocalPlatform = LocalPlatform();

Platform get platform => _kLocalPlatform;

/// The global template renderer.
TemplateRenderer get templateRenderer => MustacheTemplateRenderer();

// Unless we're in a test of this class's signal handling features, we must
// have only one instance created with the singleton LocalSignals instance
// and the catchable signals it considers to be fatal.
LocalFileSystem? _instance;

LocalFileSystem get localFileSystem => _instance ??= LocalFileSystem();
