import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/note_card.dart';

/// Main screen: lists every note stored in Firestore and lets the user
/// create, edit, delete or search for notes.
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await provider.restoreNote(deletedSnapshot);
                } catch (_) {
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

  Future<bool> _confirmDelete(Note note) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text(
          'Are you sure you want to delete "${note.title}"? '
          'You can undo this from the snackbar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Consumer<NoteProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar.large(
                  centerTitle: false,
                  pinned: true,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NoteHere',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Your private note collection',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    PopupMenuButton<NoteSortOrder>(
                      tooltip: 'Sort notes',
                      icon: const Icon(Icons.sort),
                      initialValue: provider.sortOrder,
                      onSelected: provider.setSortOrder,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: NoteSortOrder.newestFirst,
                          child: Text('Newest first'),
                        ),
                        PopupMenuItem(
                          value: NoteSortOrder.oldestFirst,
                          child: Text('Oldest first'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoadingIndicator(message: 'Loading notes…'),
                  )
                else if (provider.errorMessage != null &&
                    provider.notes.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorView(message: provider.errorMessage!),
                  )
                else
                  ..._buildContent(provider, theme),
                const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
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

  List<Widget> _buildContent(NoteProvider provider, ThemeData theme) {
    final visible = provider.visibleNotes;
    final hasAnyNotes = provider.notes.isNotEmpty;
    final isSearching = provider.searchQuery.trim().isNotEmpty;

    if (!hasAnyNotes) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            iconData: Icons.notes_outlined,
            title: 'No notes yet',
            message: 'Create your first note to get started.',
            actionLabel: 'Create your first note',
            onAction: () => _openEditor(context),
          ),
        ),
      ];
    }

    if (visible.isEmpty && isSearching) {
      return [
        SliverToBoxAdapter(child: _SearchField(controller: _searchController)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            iconData: Icons.search_off,
            title: 'No matching notes',
            message: 'No matching notes found.',
            actionLabel: 'Clear search',
            onAction: () {
              _searchController.clear();
              context.read<NoteProvider>().setSearchQuery('');
            },
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(child: _SearchField(controller: _searchController)),
      if (visible.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.only(top: 4),
          sliver: SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final note = visible[index];
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: NoteCard(
                  key: ValueKey(note.id),
                  note: note,
                  onEdit: () => _openEditor(context, noteId: note.id),
                  onDelete: () async {
                    if (await _confirmDelete(note)) {
                      if (context.mounted) {
                        await _deleteNote(context, note);
                      }
                    }
                  },
                ),
              );
            },
          ),
        ),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search notes…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    context.read<NoteProvider>().setSearchQuery('');
                  },
                ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHigh,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      iconData: Icons.error_outline,
      title: 'Something went wrong',
      message: message,
      actionLabel: 'Dismiss',
      onAction: () => context.read<NoteProvider>().clearError(),
    );
  }
}
