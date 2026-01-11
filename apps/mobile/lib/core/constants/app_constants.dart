class AppConstants {
  static const String siteOrigin = 'https://referencelibrary.vercel.app';
  static const String indexUrl = '$siteOrigin/app/index.json';

  static String normalizeDocUrl(String url) {
    // if url already contains %25 (encoded percent), decode once
    if (url.contains('%25')) {
      url = Uri.decodeFull(url);
    }
    // remove accidental double encoding
    url = url.replaceAll('%2520', '%20');

    // if starts with / then build absolute
    if (url.startsWith('/')) {
      url = '$siteOrigin$url';
    }
    return Uri.encodeFull(url);
  }
}
