import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../models/faq.dart';
import '../models/game.dart';
import '../widgets/page_frame.dart';
import '../widgets/section_card.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final api = const ApiClient();
  final searchController = TextEditingController();
  final faqQuestionController = TextEditingController();
  final faqAnswerController = TextEditingController();
  final faqTagsController = TextEditingController();

  List<Game> games = const [];
  List<Faq> faqs = const [];
  bool isLoading = true;
  bool faqApproved = true;
  String? selectedFaqGameId;
  String? editingFaqId;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    faqQuestionController.dispose();
    faqAnswerController.dispose();
    faqTagsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final query = searchController.text.trim();
      final gamesJson = await api.getList('/games');
      final faqsJson = await api.getList('/faqs', query: query.isEmpty ? null : {'q': query});

      final loadedGames = gamesJson.map((item) => Game.fromJson(item as Map<String, dynamic>)).toList();
      setState(() {
        games = loadedGames;
        faqs = faqsJson.map((item) => Faq.fromJson(item as Map<String, dynamic>)).toList();
        selectedFaqGameId ??= loadedGames.isNotEmpty ? loadedGames.first.id : null;
      });
    } catch (error) {
      setState(() => errorText = '$error');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveFaq() async {
    if (faqQuestionController.text.trim().isEmpty || faqAnswerController.text.trim().isEmpty) {
      setState(() => errorText = 'FAQ question and answer are required.');
      return;
    }

    final payload = {
      'game_id': selectedFaqGameId,
      'question': faqQuestionController.text.trim(),
      'answer': faqAnswerController.text.trim(),
      'tags': faqTagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      'approved': faqApproved,
    };

    try {
      if (editingFaqId == null) {
        await api.post('/faqs', payload);
      } else {
        await api.put('/faqs/$editingFaqId', payload);
      }
      _resetFaqForm();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await _load();
    } catch (error) {
      setState(() => errorText = '$error');
    }
  }

  Future<void> _deleteFaq(Faq faq) async {
    final confirmed = await _confirmDelete('Delete FAQ?', faq.question);
    if (confirmed != true) return;

    try {
      await api.delete('/faqs/${faq.id}');
      if (editingFaqId == faq.id) {
        _resetFaqForm();
      }
      await _load();
    } catch (error) {
      setState(() => errorText = '$error');
    }
  }

  Future<bool?> _confirmDelete(String title, String label) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(label),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
  }

  void _startFaqEdit(Faq faq) {
    final game = _findGameByName(faq.gameName);
    setState(() {
      editingFaqId = faq.id;
      selectedFaqGameId = game?.id ?? selectedFaqGameId;
      faqQuestionController.text = faq.question;
      faqAnswerController.text = faq.answer;
      faqTagsController.text = faq.tags.join(', ');
      faqApproved = faq.approved;
      errorText = null;
    });
  }

  void _resetFaqForm() {
    setState(() {
      editingFaqId = null;
      faqQuestionController.clear();
      faqAnswerController.clear();
      faqTagsController.clear();
      faqApproved = true;
      errorText = null;
    });
  }

  Future<void> _openFaqEditor({Faq? faq}) async {
    if (faq == null) {
      _resetFaqForm();
    } else {
      _startFaqEdit(faq);
    }
    await _showSheet(_buildFaqFormSheet());
    if (mounted) {
      _resetFaqForm();
    }
  }

  Future<void> _showSheet(Widget child) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: widget.isAdmin ? 'Knowledge Base' : 'Knowledge View',
      subtitle: widget.isAdmin
          ? 'Keep FAQs in compact rows with quick actions.'
          : 'Search approved answers for operators.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search keywords',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
          const SizedBox(height: 20),
          Expanded(child: _buildFaqSection()),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return SectionCard(
      title: 'FAQs',
      expandChild: true,
      child: Column(
        children: [
          if (widget.isAdmin)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${faqs.length} item${faqs.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openFaqEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          if (widget.isAdmin) const SizedBox(height: 14),
          Expanded(child: _buildFaqList()),
        ],
      ),
    );
  }

  Widget _buildFaqList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (faqs.isEmpty) {
      return _emptyState('No FAQs found.');
    }

    return ListView.separated(
      itemCount: faqs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE4E8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faq.question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      faq.gameName.isEmpty ? faq.answer : faq.gameName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.62)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () => Clipboard.setData(ClipboardData(text: faq.answer)),
              ),
              if (widget.isAdmin) _faqMenuButton(faq),
            ],
          ),
        );
      },
    );
  }

  Widget _faqMenuButton(Faq faq) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _openFaqEditor(faq: faq);
        } else if (value == 'delete') {
          _deleteFaq(faq);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
      child: _menuShell(),
    );
  }

  Widget _menuShell() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: const Icon(Icons.more_horiz, size: 18),
    );
  }

  Widget _buildFaqFormSheet() {
    final isEditing = editingFaqId != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Edit FAQ' : 'Add FAQ', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Create one FAQ entry at a time.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 16),
        _gameDropdown(value: selectedFaqGameId, onChanged: (value) => setState(() => selectedFaqGameId = value)),
        const SizedBox(height: 12),
        TextField(controller: faqQuestionController, decoration: const InputDecoration(labelText: 'Question')),
        const SizedBox(height: 12),
        TextField(
          controller: faqAnswerController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Answer'),
        ),
        const SizedBox(height: 12),
        TextField(controller: faqTagsController, decoration: const InputDecoration(labelText: 'Tags, comma separated')),
        SwitchListTile(
          value: faqApproved,
          onChanged: (value) => setState(() => faqApproved = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('Approved for operators'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saveFaq,
            child: Text(isEditing ? 'Update FAQ' : 'Create FAQ'),
          ),
        ),
      ],
    );
  }

  Widget _gameDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('No game link')),
        ...games.map((game) => DropdownMenuItem<String?>(value: game.id, child: Text(game.name))),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(labelText: 'Game'),
    );
  }

  Game? _findGameByName(String name) {
    for (final game in games) {
      if (game.name == name) {
        return game;
      }
    }
    return null;
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Text(text),
    );
  }
}
