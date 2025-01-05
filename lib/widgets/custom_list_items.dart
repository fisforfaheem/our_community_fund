import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final double elevation;

  const CustomListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.contentPadding,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: backgroundColor ?? colorScheme.surface,
      elevation: elevation,
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled
                ? selected
                    ? colorScheme.primary
                    : colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.38),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withOpacity(0.38),
                ),
              )
            : null,
        leading: leading,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        selected: selected,
        enabled: enabled,
        contentPadding: contentPadding,
      ),
    );
  }
}

class CustomExpansionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;
  final Color? collapsedBackgroundColor;
  final bool enabled;

  const CustomExpansionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.backgroundColor,
    this.contentPadding,
    this.collapsedBackgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildExpansionTile() {
      return ExpansionTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        leading: leading,
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        collapsedBackgroundColor:
            collapsedBackgroundColor ?? colorScheme.surface,
        textColor: colorScheme.primary,
        iconColor: colorScheme.primary,
        collapsedTextColor: colorScheme.onSurface,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        tilePadding: contentPadding,
        maintainState: true,
        children: children,
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: Material(
        color: backgroundColor ?? colorScheme.surface,
        child: enabled
            ? buildExpansionTile()
            : Opacity(
                opacity: 0.38,
                child: AbsorbPointer(
                  child: buildExpansionTile(),
                ),
              ),
      ),
    );
  }
}

class CustomSwipeableListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final List<CustomSwipeAction> actions;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final double elevation;

  const CustomSwipeableListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    required this.actions,
    this.enabled = true,
    this.contentPadding,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey(title),
      background: Row(
        children: [
          for (final action in actions)
            if (action.position == SwipeActionPosition.start)
              Container(
                color: action.backgroundColor ?? colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Icon(
                  action.icon,
                  color: action.iconColor ?? colorScheme.onPrimary,
                ),
              ),
          const Spacer(),
          for (final action in actions)
            if (action.position == SwipeActionPosition.end)
              Container(
                color: action.backgroundColor ?? colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                child: Icon(
                  action.icon,
                  color: action.iconColor ?? colorScheme.onPrimary,
                ),
              ),
        ],
      ),
      onDismissed: (direction) {
        final action = actions.firstWhere(
          (action) =>
              action.position ==
              (direction == DismissDirection.startToEnd
                  ? SwipeActionPosition.start
                  : SwipeActionPosition.end),
        );
        action.onTap?.call();
      },
      child: Material(
        color: backgroundColor ?? colorScheme.surface,
        elevation: elevation,
        child: ListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: enabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withOpacity(0.38),
                  ),
                )
              : null,
          leading: leading,
          trailing: trailing,
          onTap: enabled ? onTap : null,
          enabled: enabled,
          contentPadding: contentPadding,
        ),
      ),
    );
  }
}

enum SwipeActionPosition {
  start,
  end,
}

class CustomSwipeAction {
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final SwipeActionPosition position;

  const CustomSwipeAction({
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
    required this.position,
  });
}

class CustomCheckboxListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final double elevation;

  const CustomCheckboxListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.contentPadding,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: backgroundColor ?? colorScheme.surface,
      elevation: elevation,
      child: CheckboxListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.38),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withOpacity(0.38),
                ),
              )
            : null,
        value: value,
        onChanged: enabled ? onChanged : null,
        enabled: enabled,
        contentPadding: contentPadding,
        activeColor: colorScheme.primary,
        checkColor: colorScheme.onPrimary,
      ),
    );
  }
}

class CustomSwitchListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final double elevation;

  const CustomSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.contentPadding,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: backgroundColor ?? colorScheme.surface,
      elevation: elevation,
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.38),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withOpacity(0.38),
                ),
              )
            : null,
        value: value,
        onChanged: enabled ? onChanged : null,
        // enabled: enabled,
        contentPadding: contentPadding,
        activeColor: colorScheme.primary,
        activeTrackColor: colorScheme.primaryContainer,
        inactiveThumbColor: colorScheme.outline,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
