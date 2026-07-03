import 'package:flutter/material.dart';

import '../models/note.dart';
import '../utils/date_format.dart';

/// A polished card representation of a [Note].
///
/// The card surfaces a clear visual hierarchy:
///   * A large, bold title.
///   * A 3-line muted description preview.
///   * A footer with date chips (Created / Updated) and a single
///     overflow menu in the top-right for actions.
///
/// Tapping anywhere on the card opens the editor. Edit and Delete
/// live inside the overflow menu so the card surface stays calm.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final updated = note.updatedAt;
    final showUpdated = updated != null && updated != note.createdAt;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: title + overflow menu ──────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, right: 8),
                      child: Text(
                        note.title,
                        style: textTheme.titleLarge?.copyWith(height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  _CardMenu(onEdit: onEdit, onDelete: onDelete),
                ],
              ),

              // ─── Body: description preview ──────────────────────────
              if (note.description.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  note.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],

              // ─── Footer: date chips ─────────────────────────────────
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DateChip(
                    icon: Icons.edit_calendar_outlined,
                    label:
                        'Created ${DateFormatter.relativeDay(note.createdAt)}',
                  ),
                  if (showUpdated)
                    _DateChip(
                      icon: Icons.update_outlined,
                      label: 'Updated ${DateFormatter.relativeDay(updated)}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CardMenuAction>(
      tooltip: 'Note actions',
      icon: const Icon(Icons.more_vert),
      iconSize: 22,
      onSelected: (action) {
        switch (action) {
          case _CardMenuAction.edit:
            onEdit();
          case _CardMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _CardMenuAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: _CardMenuAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }
}

enum _CardMenuAction { edit, delete }

class _DateChip extends StatelessWidget {
  const _DateChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
