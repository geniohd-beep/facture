Future<void> downloadFile(String content, String filename, String mimeType) async {
  throw UnsupportedError('downloadFile is only supported on web');
}

Future<String?> uploadFile(String accept) async {
  throw UnsupportedError('uploadFile is only supported on web');
}
