import 'dart:async';
import 'dart:html' as html;

Future<void> downloadFile(String content, String filename, String mimeType) async {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<String?> uploadFile(String accept) async {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()..accept = accept;
  input.click();
  input.onChange.listen((_) async {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsText(file);
    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result as String);
    });
  });
  return completer.future;
}
