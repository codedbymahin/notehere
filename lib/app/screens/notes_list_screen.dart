import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../routes/app_routes.dart';
import '../utils/date_format.dart';
import '../widgets/centered_max_width.dart';
import '../widgets/delete_note_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/note_card.dart';

/// Main screen: lists every note stored in Firestore and lets the user
/// create, edit, delete or search for notes.
///
/// The screen is composed of three slivers:
///   * a sticky AppBar (sort menu, theme-friendly title)
///   * a custom header sliver with greeting + 3 stat tiles
///   * the actual list (or empty state)
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<NoteProvider>().searchQuery,
    );
    _searchController.addListener(() {
      context.read<NoteProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor(BuildContext context, {String? noteId}) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.addEditNote, arguments: {'id': noteId});
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteNote(BuildContext context, Note note) async {
    final provider = context.read<NoteProvider>();
    final deletedSnapshot = note.copyWith();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.deleteNote(note.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Note deleted'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await provider.restoreNote(deletedSnapshot);
                } catch (_) {
                  if (!mounted) return;
                  _showSnackBar(
                    provider.errorMessage ?? 'Could not restore the note.',
                  );
                  provider.clearError();
                }
              },
            ),
          ),
        );
    } catch (_) {
      _showSnackBar(provider.errorMessage ?? 'Could not delete the note.');
      provider.clearError();
    }
  }

  Future<void> _handleDelete(BuildContext context, Note note) async {
    if (!await _confirmDelete()) return;
    if (!context.mounted) return;
    await _deleteNote(context, note);
  }

  Future<bool> _confirmDelete() async {
    return showDeleteNoteDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<NoteProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _AppBarHeader(sortOrder: provider.sortOrder),
                _HomeHeader(notes: provider.notes),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadingState(),
                  )
                else if (provider.errorMessage != null &&
                    provider.notes.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView.error(
                      message: provider.errorMessage!,
                      onAction: () => provider.clearError(),
                    ),
                  )
                else
                  ..._buildContent(provider),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  List<Widget> _buildContent(NoteProvider provider) {
    final visible = provider.visibleNotes;
    final hasAnyNotes = provider.notes.isNotEmpty;
    final isSearching = provider.searchQuery.trim().isNotEmpty;

    if (!hasAnyNotes) {
      return [
        SliverToBoxAdapter(
          child: CenteredMaxWidth(
            child: EmptyStateView.noNotes(onAction: () => _openEditor(context)),
          ),
        ),
      ];
    }

    if (visible.isEmpty && isSearching) {
      return [
        SliverToBoxAdapter(
          child: CenteredMaxWidth(
            child: _SearchField(controller: _searchController),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: CenteredMaxWidth(
            child: EmptyStateView.noResults(
              onAction: () {
                _searchController.clear();
                context.read<NoteProvider>().setSearchQuery('');
              },
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: CenteredMaxWidth(
          child: _SearchField(controller: _searchController),
        ),
      ),
      if (visible.isNotEmpty)
        SliverToBoxAdapter(
          child: CenteredMaxWidth(
            child: Column(
              children: [
                const SizedBox(height: 8),
                for (final note in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoteCard(
                      key: ValueKey(note.id),
                      note: note,
                      onEdit: () => _openEditor(context, noteId: note.id),
                      onDelete: () => _handleDelete(context, note),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];
  }
}

// ────────────────────────────────────────────────────────────────────
// AppBar — small, pinned, hosts the sort menu.
// ────────────────────────────────────────────────────────────────────

class _AppBarHeader extends StatelessWidget {
  const _AppBarHeader({required this.sortOrder});

  final NoteSortOrder sortOrder;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      title: const Text('NoteHere'),
      actions: [
        PopupMenuButton<NoteSortOrder>(
          tooltip: 'Sort notes',
          icon: const Icon(Icons.sort),
          initialValue: sortOrder,
          onSelected: (order) =>
              context.read<NoteProvider>().setSortOrder(order),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: NoteSortOrder.newestFirst,
              child: Row(
                children: [
                  Icon(Icons.arrow_downward, size: 18),
                  SizedBox(width: 12),
                  Text('Newest first'),
                ],
              ),
            ),
            PopupMenuItem(
              value: NoteSortOrder.oldestFirst,
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, size: 18),
                  SizedBox(width: 12),
                  Text('Oldest first'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Greeting header with three stat tiles.
// ────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final greeting = DateFormatter.greetingFor();
    final now = DateTime.now();
    final today =
        '${DateFormatter.weekdayLong(now)}, '
        '${DateFormatter.absolute(now)}';
    final totalNotes = notes.length;
    final lastUpdated = _lastUpdated(notes);

    return SliverToBoxAdapter(
      child: CenteredMaxWidth(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'NoteHere',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your thoughts before they are forgotten.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _StatsRow(
              tiles: [
                _StatTile(
                  label: 'Total notes',
                  value: totalNotes.toString(),
                  icon: Icons.sticky_note_2_outlined,
                ),
                _StatTile(
                  label: 'Last updated',
                  value: lastUpdated,
                  icon: Icons.history_toggle_off_outlined,
                ),
                _StatTile(
                  label: 'Today',
                  value: today,
                  icon: Icons.today_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _lastUpdated(List<Note> notes) {
    if (notes.isEmpty) return '—';
    Note? latest;
    for (final note in notes) {
      final ts = note.updatedAt ?? note.createdAt;
      if (latest == null) {
        latest = note;
        continue;
      }
      final latestTs = latest.updatedAt ?? latest.createdAt;
      if (ts.isAfter(latestTs)) latest = note;
    }
    if (latest == null) return '—';
    final ts = latest.updatedAt ?? latest.createdAt;
    return DateFormatter.relativeDay(ts);
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.tiles});

  final List<_StatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              tiles[i],
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Modern search field with rounded shape + clear button.
// ────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search title or description…',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  context.read<NoteProvider>().setSearchQuery('');
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Loading + Error states — small, calm, premium.
// ────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your notes…',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
