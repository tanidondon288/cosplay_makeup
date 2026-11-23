import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/character.dart';
import '../widgets/dialogs.dart';
import '../widgets/palette_grid.dart';
import 'step_edit_screen.dart';

/// メイク1つ(フォルダ)の中身。工程を番号順に表示する。
///
/// 「編集」で並べ替えと削除ができ、「保存」を押したときだけ反映する。
class LookScreen extends StatefulWidget {
  const LookScreen({
    super.key,
    required this.store,
    required this.characterId,
    required this.lookId,
  });

  final AppStore store;
  final String characterId;
  final String lookId;

  @override
  State<LookScreen> createState() => _LookScreenState();
}

class _LookScreenState extends State<LookScreen> {
  /// 編集中の工程の並び。編集していないときは null。
  List<MakeupStep>? _draft;

  AppStore get _store => widget.store;

  void _openStep(MakeupLook look, [MakeupStep? step]) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StepEditScreen(store: _store, look: look, step: step),
      ),
    );
  }

  void _saveDraft(MakeupLook look) {
    look.steps
      ..clear()
      ..addAll(_draft!);
    _store.touchLook(look);
    setState(() => _draft = null);
  }

  Future<void> _onMenu(
    String value,
    Character character,
    MakeupLook look,
  ) async {
    switch (value) {
      case 'rename':
        final title = await showDialog<String>(
          context: context,
          builder: (_) => TextInputDialog(
            title: 'メイクのタイトル',
            initial: look.title,
            label: 'タイトル',
          ),
        );
        if (title == null || title.isEmpty) return;
        look.title = title;
        _store.touchLook(look);
      case 'delete':
        final ok = await showConfirmDialog(
          context,
          title: 'メイクを削除',
          message: '「${look.title}」と、その中の工程をすべて削除しますか?',
          okLabel: '削除する',
        );
        if (!ok || !mounted) return;
        Navigator.pop(context);
        _store.deleteLook(character, look.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final character = _store.characterById(widget.characterId);
        final look = character?.lookById(widget.lookId);
        if (character == null || look == null) return const Scaffold();
        final draft = _draft;
        return draft == null
            ? _buildView(context, character, look)
            : _buildEditor(context, look, draft);
      },
    );
  }

  Widget _buildView(
    BuildContext context,
    Character character,
    MakeupLook look,
  ) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(look.title),
        actions: [
          IconButton(
            tooltip: look.pinned ? 'お気に入りから外す' : 'お気に入りにする',
            icon: Icon(
              look.pinned ? Icons.star : Icons.star_border,
              color: look.pinned ? Colors.amber.shade600 : null,
            ),
            onPressed: () {
              look.pinned = !look.pinned;
              _store.changed();
            },
          ),
          if (look.steps.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _draft = List.of(look.steps)),
              child: const Text('編集'),
            ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(v, character, look),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('タイトルを変更')),
              PopupMenuItem(value: 'delete', child: Text('メイクを削除')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              character.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (look.steps.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'まだ工程がありません。\n右下の「工程を追加」から、1工程ずつ記録できます。',
                textAlign: TextAlign.center,
              ),
            ),
          for (final (i, step) in look.steps.indexed)
            _StepCard(
              number: i + 1,
              step: step,
              cosmetic: _store.resolveStep(step),
              onTap: () => _openStep(look, step),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStep(look),
        icon: const Icon(Icons.add),
        label: const Text('工程を追加'),
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    MakeupLook look,
    List<MakeupStep> draft,
  ) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('並べ替え・削除'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '右の ≡ を押したまま動かすと、順番を変えられます。\n「保存」を押すまで、元の記録は変わりません。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              buildDefaultDragHandles: false,
              itemCount: draft.length,
              onReorder: (oldIndex, newIndex) => setState(() {
                if (newIndex > oldIndex) newIndex--;
                draft.insert(newIndex, draft.removeAt(oldIndex));
              }),
              itemBuilder: (context, i) {
                final step = draft[i];
                final cosmetic = _store.resolveStep(step);
                return Card(
                  key: ValueKey(step.id),
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: '削除',
                      onPressed: () => setState(() => draft.removeAt(i)),
                    ),
                    title: Text(
                      '${i + 1}. ${step.part.isEmpty ? '(場所なし)' : step.part}',
                    ),
                    subtitle: cosmetic == null
                        ? null
                        : Text(
                            cosmetic.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _draft = null),
                  child: const Text('キャンセル'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _saveDraft(look),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 工程1つのカード。
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.step,
    required this.cosmetic,
    required this.onTap,
  });

  final int number;
  final MakeupStep step;
  final StepCosmetic? cosmetic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cosmetic = this.cosmetic;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 14, child: Text('$number')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.part.isEmpty ? '(場所なし)' : step.part,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (cosmetic != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (cosmetic.isItem)
                            Icon(
                              Icons.auto_awesome,
                              size: 24,
                              color: theme.colorScheme.primary,
                            )
                          else
                            ColorSwatchBox(color: cosmetic.color, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cosmetic.title),
                                Text(
                                  cosmetic.detail,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (cosmetic.isLost)
                        Text('※元のコスメは削除済み', style: theme.textTheme.bodySmall),
                    ],
                    if (step.memo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(step.memo),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
