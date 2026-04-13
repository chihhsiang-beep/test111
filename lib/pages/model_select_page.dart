import 'package:flutter/material.dart';
import '../models/ai_provider.dart';
import '../services/ai_service.dart';

class ModelSelectPage extends StatefulWidget {
  const ModelSelectPage({super.key});

  @override
  State<ModelSelectPage> createState() => _ModelSelectPageState();
}

class _ModelSelectPageState extends State<ModelSelectPage> {
  AiProvider? _selectedProvider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final provider = await AIService.getCurrentProvider();

    if (!mounted) return;
    setState(() {
      _selectedProvider = provider;
      _isLoading = false;
    });
  }

  Future<void> _selectProvider(AiProvider provider) async {
    await AIService.setCurrentProvider(provider);

    if (!mounted) return;
    setState(() {
      _selectedProvider = provider;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切換為：${provider.label}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildProviderCard(AiProvider provider) {
    final selected = _selectedProvider == provider;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _selectProvider(provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選擇 AI 模式',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '本地模式會使用多模型協作（聊天、翻譯、更多）。雲端模式保留給未來高品質模型使用。',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          '模型選擇',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIntroCard(),
            _buildProviderCard(AiProvider.local),
            _buildProviderCard(AiProvider.cloud),
          ],
        ),
      ),
    );
  }
}