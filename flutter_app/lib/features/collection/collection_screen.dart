import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'collection_providers.dart';
import 'widgets/artwork_card.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(collectionFilterProvider);
    final artworksAsync = ref.watch(filteredArtworksProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search artworks…',
                  border: InputBorder.none,
                ),
                onChanged: (q) => ref
                    .read(collectionFilterProvider.notifier)
                    .update((s) => s.copyWith(search: q)),
              )
            : const Text('Collection'),
        actions: [
          if (_searchActive)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear search',
              onPressed: _clearSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () => setState(() => _searchActive = true),
            ),
          IconButton(
            icon: Icon(filter.isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: filter.isGrid ? 'List view' : 'Grid view',
            onPressed: () => ref
                .read(collectionFilterProvider.notifier)
                .update((s) => s.copyWith(isGrid: !s.isGrid)),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (filter.medium.isNotEmpty || filter.sortBy != SortBy.dateAdded)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter & sort',
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: artworksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (artworks) {
          if (artworks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    filter.search.isNotEmpty || filter.medium.isNotEmpty
                        ? 'No artworks match your filter'
                        : 'No artworks yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return filter.isGrid ? _buildGrid(artworks) : _buildList(artworks);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/collection/add'),
        tooltip: 'Add artwork',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGrid(List artworks) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.72,
        ),
        itemCount: artworks.length,
        itemBuilder: (_, i) => ArtworkCard(
          artwork: artworks[i],
          isGrid: true,
          onTap: () => context.go('/collection/artwork/${artworks[i].id}'),
        ),
      );

  Widget _buildList(List artworks) => ListView.builder(
        itemCount: artworks.length,
        itemBuilder: (_, i) => ArtworkCard(
          artwork: artworks[i],
          isGrid: false,
          onTap: () => context.go('/collection/artwork/${artworks[i].id}'),
        ),
      );

  void _clearSearch() {
    _searchController.clear();
    ref.read(collectionFilterProvider.notifier).update((s) => s.copyWith(search: ''));
    setState(() => _searchActive = false);
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(parentRef: ref),
    );
  }
}

// ── Filter / sort bottom sheet ────────────────────────────────────────────────

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({required this.parentRef});

  final WidgetRef parentRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(collectionFilterProvider);
    final mediumsAsync = ref.watch(distinctMediumsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter & Sort', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () {
                  parentRef
                      .read(collectionFilterProvider.notifier)
                      .update((s) => s.copyWith(medium: '', sortBy: SortBy.dateAdded));
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Medium', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          mediumsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (mediums) => Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter.medium.isEmpty,
                  onSelected: (_) => parentRef
                      .read(collectionFilterProvider.notifier)
                      .update((s) => s.copyWith(medium: '')),
                ),
                ...mediums.map((m) => FilterChip(
                      label: Text(m),
                      selected: filter.medium == m,
                      onSelected: (_) => parentRef
                          .read(collectionFilterProvider.notifier)
                          .update((s) => s.copyWith(medium: m)),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Sort by', style: Theme.of(context).textTheme.labelLarge),
          ...SortBy.values.map((s) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_sortLabel(s)),
                leading: Radio<SortBy>(
                  value: s,
                  groupValue: filter.sortBy,
                  onChanged: (_) => parentRef
                      .read(collectionFilterProvider.notifier)
                      .update((f) => f.copyWith(sortBy: s)),
                ),
                onTap: () => parentRef
                    .read(collectionFilterProvider.notifier)
                    .update((f) => f.copyWith(sortBy: s)),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(SortBy s) => switch (s) {
        SortBy.dateAdded => 'Date added',
        SortBy.title => 'Title',
        SortBy.artist => 'Artist',
        SortBy.year => 'Year',
      };
}
