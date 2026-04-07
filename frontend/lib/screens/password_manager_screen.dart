import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/credential.dart';
import '../models/game.dart';
import '../widgets/page_frame.dart';
import '../widgets/section_card.dart';

class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final api = const ApiClient();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final labelController = TextEditingController();
  final notesController = TextEditingController();

  List<Game> games = const [];
  List<Credential> credentials = const [];
  bool isLoading = true;
  bool isSaving = false;
  bool isPrimary = true;
  bool revealPasswords = false;
  bool revealPasswordsInDetails = false;
  String? selectedGameId;
  String? editingId;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    labelController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final gamesJson = await api.getList('/games');
      final credentialsJson = await api.getList('/credentials');
      final loadedGames = gamesJson.map((item) => Game.fromJson(item as Map<String, dynamic>)).toList();
      final loadedCredentials =
          credentialsJson.map((item) => Credential.fromJson(item as Map<String, dynamic>)).toList();

      setState(() {
        games = loadedGames;
        credentials = loadedCredentials;

        final hasSelectedGame = loadedGames.any((game) => game.id == selectedGameId);
        selectedGameId = hasSelectedGame ? selectedGameId : (loadedGames.isNotEmpty ? loadedGames.first.id : null);
      });
    } catch (error) {
      setState(() => errorText = '$error');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveCredential() async {
    if (selectedGameId == null) {
      setState(() => errorText = 'Choose a game first.');
      return;
    }

    if (usernameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      setState(() => errorText = 'Username and password are required.');
      return;
    }

    setState(() {
      isSaving = true;
      errorText = null;
    });

    final payload = {
      'game_id': selectedGameId,
      'username': usernameController.text.trim(),
      'password': passwordController.text.trim(),
      'label': labelController.text.trim(),
      'notes': notesController.text.trim(),
      'is_primary': isPrimary,
    };

    try {
      if (editingId == null) {
        await api.post('/credentials', payload);
      } else {
        await api.put('/credentials/$editingId', payload);
      }
      final savedGameId = selectedGameId;
      _resetForm(clearSelectedGame: false);
      selectedGameId = savedGameId;
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await _loadData();
    } catch (error) {
      setState(() => errorText = '$error');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _deleteCredential(Credential credential) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete credential?'),
        content: Text('Remove ${credential.username} from ${credential.gameName}?'),
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
      await api.delete('/credentials/${credential.id}');
      if (editingId == credential.id) {
        _resetForm(clearSelectedGame: false);
      }
      await _loadData();
    } catch (error) {
      setState(() => errorText = '$error');
    }
  }

  void _startEdit(Credential credential) {
    setState(() {
      editingId = credential.id;
      selectedGameId = credential.gameId;
      usernameController.text = credential.username;
      passwordController.text = credential.password;
      labelController.text = credential.label;
      notesController.text = credential.notes;
      isPrimary = credential.isPrimary;
      errorText = null;
    });
  }

  void _resetForm({bool clearSelectedGame = false}) {
    setState(() {
      editingId = null;
      usernameController.clear();
      passwordController.clear();
      labelController.clear();
      notesController.clear();
      isPrimary = true;
      errorText = null;
      if (clearSelectedGame) {
        selectedGameId = games.isNotEmpty ? games.first.id : null;
      } else {
        selectedGameId ??= games.isNotEmpty ? games.first.id : null;
      }
    });
  }

  Future<void> _openEditor({Credential? credential}) async {
    if (credential == null) {
      _resetForm(clearSelectedGame: false);
    } else {
      _startEdit(credential);
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
      _resetForm(clearSelectedGame: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: widget.isAdmin ? 'Password Manager' : 'Credentials View',
      subtitle: widget.isAdmin
          ? 'Manage platform logins game by game.'
          : 'Browse platform logins grouped by game.',
      child: SectionCard(
        title: 'Game Credentials',
        expandChild: true,
        child: _buildGameFocusedView(),
      ),
    );
  }

  Widget _buildGameFocusedView() {
    final selectedGame = _selectedGame;
    final selectedCredentials = _credentialsForGame(selectedGameId);

    return Column(
      children: [
        _buildGameSelector(),
        const SizedBox(height: 16),
        _buildSelectedGamePanel(selectedGame, selectedCredentials),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '${games.length} game${games.length == 1 ? '' : 's'} tracked',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
        Expanded(child: _buildGameRows()),
      ],
    );
  }

  Widget _buildGameSelector() {
    return DropdownButtonFormField<String>(
      value: selectedGameId,
      items: games.map((game) => DropdownMenuItem(value: game.id, child: Text(game.name))).toList(),
      onChanged: games.isEmpty ? null : (value) => setState(() => selectedGameId = value),
      decoration: const InputDecoration(
        labelText: 'Selected Game',
        helperText: 'Choose which game you are saving credentials for.',
      ),
    );
  }

  Widget _buildSelectedGamePanel(Game? game, List<Credential> selectedCredentials) {
    if (isLoading) {
      return _emptyState('Loading selected game...');
    }

    if (game == null) {
      return _emptyState('Add a game first, then you can store logins under it.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedCredentials.length} credential${selectedCredentials.length == 1 ? '' : 's'} saved for this game',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (widget.isAdmin)
                FilledButton.icon(
                  onPressed: isSaving ? null : () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (selectedCredentials.isEmpty)
            Text(
              widget.isAdmin
                  ? 'No login saved for this game yet. Use Add to create one.'
                  : 'No login is available for this game yet.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedCredentials.take(4).map((credential) {
                final label = credential.label.trim().isEmpty ? credential.username : credential.label.trim();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDCE4E8)),
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGameRows() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorText != null && credentials.isEmpty) {
      return Text('Failed to load credentials: $errorText');
    }
    if (games.isEmpty) {
      return _emptyState('No games added yet.');
    }

    return ListView.separated(
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildGameRow(games[index]),
    );
  }

  Widget _buildGameRow(Game game) {
    final gameCredentials = _credentialsForGame(game.id);
    final isSelected = game.id == selectedGameId;
    final primaryCredential = gameCredentials.cast<Credential?>().firstWhere(
      (credential) => credential?.isPrimary ?? false,
      orElse: () => gameCredentials.isNotEmpty ? gameCredentials.first : null,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() => selectedGameId = game.id);
        _openGameCredentialsSheet(game);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF8F5) : const Color(0xFFF9FBFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? const Color(0xFF0E7C66) : const Color(0xFFDCE4E8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gameCredentials.isEmpty
                        ? 'No credentials saved'
                        : '${gameCredentials.length} credential${gameCredentials.length == 1 ? '' : 's'} - ${primaryCredential == null ? 'No primary set' : 'Primary: ${primaryCredential.username}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.62)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFDCE4E8)),
              ),
              child: Text(
                '${gameCredentials.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _openGameCredentialsSheet(Game game) async {
    setState(() {
      selectedGameId = game.id;
      revealPasswordsInDetails = false;
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.76,
          minChildSize: 0.52,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildGameDetailsSheet(game, scrollController),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGameDetailsSheet(Game game, ScrollController scrollController) {
    final gameCredentials = _credentialsForGame(game.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Username and password list for this game.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: revealPasswordsInDetails ? 'Hide passwords' : 'Show passwords',
              onPressed: () => setState(() => revealPasswordsInDetails = !revealPasswordsInDetails),
              icon: Icon(revealPasswordsInDetails ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.isAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _openEditor();
                    },
              icon: const Icon(Icons.add),
              label: Text('Add credential for ${game.name}'),
            ),
          ),
        if (gameCredentials.isEmpty)
          _emptyState('No credentials saved for ${game.name} yet.')
        else
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: gameCredentials.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildCredentialCard(gameCredentials[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildCredentialCard(Credential credential) {
    final title = credential.label.trim().isEmpty ? credential.username : credential.label.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      credential.username,
                      style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.68)),
                    ),
                  ],
                ),
              ),
              if (credential.isPrimary) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF4E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Primary', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.isAdmin) _menuButton(credential),
            ],
          ),
          const SizedBox(height: 14),
          _detailLine('Username', credential.username),
          const SizedBox(height: 8),
          _detailLine('Password', revealPasswordsInDetails ? credential.password : '********'),
          if (credential.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailLine('Notes', credential.notes.trim()),
          ],
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.54))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _menuButton(Credential credential) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _openEditor(credential: credential);
        } else if (value == 'delete') {
          _deleteCredential(credential);
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
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Edit Credential' : 'Add Credential', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Save one platform login under a game.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedGameId,
          items: games.map((game) => DropdownMenuItem(value: game.id, child: Text(game.name))).toList(),
          onChanged: (value) => setState(() => selectedGameId = value),
          decoration: const InputDecoration(labelText: 'Game'),
        ),
        const SizedBox(height: 12),
        TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: !revealPasswords,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              onPressed: () => setState(() => revealPasswords = !revealPasswords),
              icon: Icon(revealPasswords ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label')),
        const SizedBox(height: 12),
        TextField(controller: notesController, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes')),
        CheckboxListTile(
          value: isPrimary,
          onChanged: (value) => setState(() => isPrimary = value ?? false),
          title: const Text('Primary account for this game'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSaving ? null : _saveCredential,
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Update Credential' : 'Create Credential'),
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

  Game? get _selectedGame {
    if (selectedGameId == null) return null;
    for (final game in games) {
      if (game.id == selectedGameId) {
        return game;
      }
    }
    return null;
  }

  List<Credential> _credentialsForGame(String? gameId) {
    if (gameId == null) return const [];

    final filtered = credentials.where((credential) => credential.gameId == gameId).toList();
    filtered.sort((a, b) {
      if (a.isPrimary != b.isPrimary) {
        return a.isPrimary ? -1 : 1;
      }
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });
    return filtered;
  }
}
