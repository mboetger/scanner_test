import 'package:flutter/material.dart';
import '../../services/service_types.dart';
import '../../viewmodels/scanner_viewmodel.dart';

/// Leaf widget providing search query filtering and service type filter chips.
class ServiceSearchBar extends StatefulWidget {
  /// Creates a [ServiceSearchBar] hooked up to [ScannerViewModel].
  const ServiceSearchBar({
    super.key,
    required this.viewModel,
  });

  /// The ViewModel providing search and filter state.
  final ScannerViewModel viewModel;

  @override
  State<ServiceSearchBar> createState() => _ServiceSearchBarState();
}

class _ServiceSearchBarState extends State<ServiceSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.viewModel.searchQueryNotifier.value,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0, // 12dp horizontal edge padding
        vertical: 6.0, // 6dp vertical padding
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input Field
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search by name, host, IP, or port...',
              prefixIcon: const Icon(
                Icons.search,
                size: 20.0, // 20dp search icon size
              ),
              suffixIcon: ValueListenableBuilder<String>(
                valueListenable: widget.viewModel.searchQueryNotifier,
                builder: (context, query, _) {
                  if (query.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 18.0, // 18dp clear icon size
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.viewModel.setSearchQuery('');
                    },
                  );
                },
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0, // 12dp internal text field padding
                vertical: 6.0, // 6dp vertical padding
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  24.0, // 24dp pill shape rounded search bar radius
                ),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.0, // 1dp subtle border
                ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
            ),
            onChanged: (text) {
              widget.viewModel.setSearchQuery(text);
            },
          ),

          const SizedBox(
            height: 6.0, // 6dp spacing before chips
          ),

          // Horizontal Filter Chips
          SizedBox(
            height: 34.0, // 34dp fixed height for horizontal scrollable chips
            child: ValueListenableBuilder<String>(
              valueListenable: widget.viewModel.selectedTypeFilterNotifier,
              builder: (context, selectedFilter, _) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      context,
                      label: 'All',
                      typeKey: 'All',
                      isSelected: selectedFilter == 'All',
                    ),
                    ...ServiceTypes.catalog
                        .where(
                          (d) => d.serviceType != ServiceTypes.dnsSdMetaQuery,
                        )
                        .map(
                          (desc) => _buildFilterChip(
                            context,
                            label: desc.name.replaceAll(RegExp(r'\(.*\)'), '').trim(),
                            typeKey: desc.serviceType,
                            isSelected: selectedFilter == desc.serviceType,
                            icon: desc.icon,
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String typeKey,
    required bool isSelected,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 6.0, // 6dp right margin between adjacent chips
      ),
      child: FilterChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 14.0, // 14dp compact chip icon size
              )
            : null,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12.0, // 12sp compact chip label font size
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selected: isSelected,
        padding: const EdgeInsets.symmetric(
          horizontal: 4.0, // 4dp internal chip padding
          vertical: 0.0, // 0dp vertical padding
        ),
        onSelected: (selected) {
          widget.viewModel.setTypeFilter(selected ? typeKey : 'All');
        },
      ),
    );
  }
}
