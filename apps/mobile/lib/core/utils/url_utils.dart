class UrlUtils {
  /// Fixes double-encoding issues like `%2520` (which is `%20` encoded again)
  /// and returns a clean URL safe to load in WebView.
  static String normalizeUrl(String input, {required String siteOrigin}) {
    var url = input.trim();

    // Fix the most common bug directly
    url = url.replaceAll('%2520', '%20');

    // If it still contains encoded percent (%25), decode once
    // Example: Semester%25201 -> decode -> Semester%201
    if (url.contains('%25')) {
      url = Uri.decodeFull(url);
    }

    // Remove accidental double-encoding again (just in case)
    url = url.replaceAll('%2520', '%20');

    // If it's relative, make absolute using siteOrigin
    if (url.startsWith('/')) {
      url = '$siteOrigin$url';
    }

    // Encode ONLY once at the end
    return Uri.encodeFull(url);
  }

  /// Resolves relative hrefs against a current URL
  static String resolveHref({
    required String currentUrl,
    required String href,
    required String siteOrigin,
  }) {
    var cleanHref = href.trim();

    cleanHref = cleanHref.replaceAll('%2520', '%20');
    if (cleanHref.contains('%25')) {
      cleanHref = Uri.decodeFull(cleanHref);
    }
    cleanHref = cleanHref.replaceAll('%2520', '%20');

    final base = Uri.parse(currentUrl);
    final resolved = base.resolve(cleanHref).toString();

    return normalizeUrl(resolved, siteOrigin: siteOrigin);
  }
}
