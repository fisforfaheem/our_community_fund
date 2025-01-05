import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<CustomNavigationBarItem> items;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final double elevation;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor,
    this.elevation = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      elevation: elevation,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon ?? item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class CustomNavigationBarItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const CustomNavigationBarItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

class CustomNavigationRail extends StatelessWidget {
  final int currentIndex;
  final List<CustomNavigationRailItem> items;
  final ValueChanged<int> onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool extended;
  final Color? backgroundColor;
  final double elevation;

  const CustomNavigationRail({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.leading,
    this.trailing,
    this.extended = false,
    this.backgroundColor,
    this.elevation = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      extended: extended,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      elevation: elevation,
      leading: leading != null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: leading,
            )
          : null,
      trailing: trailing != null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: trailing,
            )
          : null,
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon ?? item.icon),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }
}

class CustomNavigationRailItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const CustomNavigationRailItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

class CustomDrawer extends StatelessWidget {
  final Widget? header;
  final List<CustomDrawerItem> items;
  final ValueChanged<int>? onTap;
  final int? selectedIndex;
  final Widget? footer;
  final Color? backgroundColor;
  final double elevation;

  const CustomDrawer({
    super.key,
    this.header,
    required this.items,
    this.onTap,
    this.selectedIndex,
    this.footer,
    this.backgroundColor,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      elevation: elevation,
      child: Column(
        children: [
          if (header != null) header!,
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                if (item is CustomDrawerDividerItem) {
                  return const Divider();
                }

                if (item is CustomDrawerTileItem) {
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      item.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: item.trailing,
                    selected: isSelected,
                    onTap: () => onTap?.call(index),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

abstract class CustomDrawerItem {
  const CustomDrawerItem();
}

class CustomDrawerTileItem extends CustomDrawerItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;

  const CustomDrawerTileItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
  });
}

class CustomDrawerDividerItem extends CustomDrawerItem {
  const CustomDrawerDividerItem();
}

class CustomNavigationScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? navigationRail;
  final Widget? drawer;
  final Widget? endDrawer;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;

  const CustomNavigationScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.navigationRail,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (navigationRail != null) {
      return Scaffold(
        backgroundColor: backgroundColor ?? colorScheme.surface,
        body: Row(
          children: [
            navigationRail!,
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor ?? colorScheme.surface,
    );
  }
}
