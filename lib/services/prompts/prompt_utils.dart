class PromptUtils {
  static String safeText(String text) {
    return text.trim();
  }

  static String shortContext(String text, {int maxChars = 400}) {
    final cleaned = text.trim();
    if (cleaned.length <= maxChars) return cleaned;
    return cleaned.substring(cleaned.length - maxChars);
  }
}