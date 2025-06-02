import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';

class TvNavigationBar extends StatefulWidget {
  final List<NavigationBarType> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget Function(NavigationBarType, bool) iconBuilder;

  const TvNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.iconBuilder,
  });

  @override
  State<TvNavigationBar> createState() => _TvNavigationBarState();
}

class _TvNavigationBarState extends State<TvNavigationBar> {
  late int _focusedIndex;
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _focusedIndex = widget.selectedIndex;
    _initializeFocusNodes();
  }

  void _initializeFocusNodes() {
    _focusNodes.clear();
    for (int i = 0; i < widget.destinations.length; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          if (index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          if (index < widget.destinations.length - 1) {
            _focusNodes[index + 1].requestFocus();
          }
          break;
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          widget.onDestinationSelected?.call(index);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.destinations.asMap().entries.map((entry) {
          final index = entry.key;
          final destination = entry.value;
          final isSelected = index == widget.selectedIndex;
          
          return Expanded(
            child: Focus(
              focusNode: _focusNodes[index],
              onKeyEvent: (node, event) {
                _handleKeyEvent(event, index);
                return KeyEventResult.handled;
              },
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return GestureDetector(
                    onTap: () => widget.onDestinationSelected?.call(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isFocused 
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isFocused 
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.iconBuilder(destination, isSelected),
                          const SizedBox(height: 4),
                          Text(
                            destination.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected 
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}