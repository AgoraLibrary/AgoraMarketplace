import 'package:mustache_template/mustache.dart' as mustache;

import 'template.dart';

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
