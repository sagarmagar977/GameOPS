import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/game.dart';
import '../widgets/page_frame.dart';
import '../widgets/section_card.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final api = const ApiClient();
  final nameController = TextEditingController();
  final slugController = TextEditingController();
  final urlController = TextEditingController();
  final notesController = TextEditingController();

  List<Game> games = const [];
  bool isLoading = true;
  bool isSaving = false;
  bool isToggling = false;
  bool isActive = true;
  bool isHighlighted = false;
  String? editingId;
  String? errorText;
  String? websiteUrlError;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void dispose() {
    nameController.dispose();
    slugController.dispose();
    urlController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    setState(() {
      isLoading = true;
      errorText = null;
      websiteUrlError = null;
    });

    try {
      final json = await api.getList('/games');
      setState(() {
        games = json.map((item) => Game.fromJson(item as Map<String, dynamic>)).toList();
      });
    } catch (error) {
      setState(() => errorText = '$error');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveGame() async {
    if (nameController.text.trim().isEmpty || slugController.text.trim().isEmpty) {
      setState(() {
        errorText = 'Game name and slug are required.';
        websiteUrlError = null;
      });
      return;
    }

    setState(() {
      isSaving = true;
      errorText = null;
      websiteUrlError = null;
    });

    final payload = {
      'name': nameController.text.trim(),
      'slug': slugController.text.trim(),
      'website_url': _normalizeWebsiteUrl(urlController.text),
      'notes': notesController.text.trim(),
      'is_active': isActive,
      'is_highlighted': isHighlighted,
    };

    try {
      if (editingId == null) {
        await api.post('/games', payload);
      } else {
        await api.put('/games/$editingId', payload);
      }

      _resetForm();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await _loadGames();
    } catch (error) {
      final message = '$error';
      setState(() {
        if (message.contains('website_url')) {
          websiteUrlError = 'Enter a valid http:// or https:// URL';
          errorText = null;
        } else {
          websiteUrlError = null;
          errorText = message;
        }
      });
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _toggleAvailability(Game game, bool value) async {
    setState(() {
      isToggling = true;
      errorText = null;
    });

    try {
      await api.put('/games/${game.id}', {
        'name': game.name,
        'slug': game.slug,
        'website_url': game.websiteUrl,
        'notes': game.notes,
        'is_active': value,
        'is_highlighted': game.isHighlighted,
      });
      await _loadGames();
    } catch (error) {
      setState(() => errorText = '$error');
    } finally {
      if (mounted) {
        setState(() => isToggling = false);
      }
    }
  }

  Future<void> _deleteGame(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete game?'),
        content: Text('Remove ${game.name} from the panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await api.delete('/games/${game.id}');
      if (editingId == game.id) {
        _resetForm();
      }
      await _loadGames();
    } catch (error) {
      setState(() => errorText = '$error');
    }
  }

  void _startEdit(Game game) {
    setState(() {
      editingId = game.id;
      nameController.text = game.name;
      slugController.text = game.slug;
      urlController.text = game.websiteUrl;
      notesController.text = game.notes;
      isActive = game.isActive;
      isHighlighted = game.isHighlighted;
      errorText = null;
      websiteUrlError = null;
    });
  }

  void _resetForm() {
    setState(() {
      editingId = null;
      nameController.clear();
      slugController.clear();
      urlController.clear();
      notesController.clear();
      isActive = true;
      isHighlighted = false;
      errorText = null;
      websiteUrlError = null;
    });
  }

  String _normalizeWebsiteUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final hasScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    return hasScheme ? trimmed : 'https://$trimmed';
  }

  Future<void> _openGameEditor({Game? game}) async {
    if (game == null) {
      _resetForm();
    } else {
      _startEdit(game);
    }

    await showModalBottomSheet<void>(
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
              child: _buildFormSheet(),
            ),
          ),
        );
      },
    );

    if (mounted) {
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: widget.isAdmin ? 'Games Admin' : 'Games Library',
      subtitle: widget.isAdmin
          ? 'Manage games in a tight mobile-friendly list.'
          : 'Browse the currently configured games and their availability status.',
      child: SectionCard(
        title: widget.isAdmin ? 'Added Games' : 'Available Games',
        expandChild: true,
        child: widget.isAdmin ? _buildAdminList() : _buildViewerList(),
      ),
    );
  }

  Widget _buildAdminList() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${games.length} game${games.length == 1 ? '' : 's'} added',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: isSaving ? null : () => _openGameEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
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
        const SizedBox(height: 16),
        Expanded(child: _buildListRows(adminMode: true)),
      ],
    );
  }

  Widget _buildViewerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null) ...[
          Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
        ],
        Expanded(child: _buildListRows(adminMode: false)),
      ],
    );
  }

  Widget _buildListRows({required bool adminMode}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorText != null && games.isEmpty) {
      return Text('Failed to load games: $errorText');
    }
    if (games.isEmpty) {
      return _emptyState('No games added yet.');
    }

    return ListView.separated(
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildGameRow(games[index], adminMode: adminMode),
    );
  }

  Widget _buildGameRow(Game game, {required bool adminMode}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildGameInfo(game)),
          const SizedBox(width: 12),
          _availabilitySwitch(game, enabled: adminMode),
          if (adminMode) ...[
            const SizedBox(width: 8),
            _menuButton(game),
          ],
        ],
      ),
    );
  }

  Widget _buildGameInfo(Game game) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          game.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          game.websiteUrl.isEmpty ? game.slug : game.websiteUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.62)),
        ),
      ],
    );
  }

  Widget _availabilitySwitch(Game game, {required bool enabled}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          game.isActive ? 'On' : 'Off',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 42,
          child: Switch(
            value: game.isActive,
            onChanged: !enabled || isToggling ? null : (value) => _toggleAvailability(game, value),
          ),
        ),
      ],
    );
  }

  Widget _menuButton(Game game) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _openGameEditor(game: game);
        } else if (value == 'delete') {
          _deleteGame(game);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCE4E8)),
        ),
        child: const Icon(Icons.more_horiz, size: 18),
      ),
    );
  }

  Widget _buildFormSheet() {
    final isEditing = editingId != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Edit Game' : 'Add Game', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    isEditing ? 'Update the selected game details.' : 'Create a new game entry.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Game name')),
        const SizedBox(height: 12),
        TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
        const SizedBox(height: 12),
        TextField(
          controller: urlController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Website URL',
            hintText: 'https://example.com',
            errorText: websiteUrlError,
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: notesController, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes')),
        const SizedBox(height: 12),
        SwitchListTile(
          value: isActive,
          onChanged: (value) => setState(() => isActive = value),
          title: const Text('Available right now'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: isHighlighted,
          onChanged: (value) => setState(() => isHighlighted = value),
          title: const Text('Highlight in dashboard'),
          contentPadding: EdgeInsets.zero,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSaving ? null : _saveGame,
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Update Game' : 'Create Game'),
          ),
        ),
      ],
    );
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
