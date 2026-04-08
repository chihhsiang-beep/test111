import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider.dart';

class AISettingsService {
  static const String _providerKey = 'selected_ai_provider';

  static Future<AiProvider> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_providerKey);
    return AiProviderX.fromStorageValue(value);
  }

  static Future<void> setSelectedProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.storageValue);
  }
}