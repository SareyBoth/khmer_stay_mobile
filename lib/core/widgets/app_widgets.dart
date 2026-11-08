import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

ImageProvider stayImageProvider(String source) =>
    source.startsWith('http') ? NetworkImage(source) : AssetImage(source);

Widget stayImage(
  String source, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  String? semanticLabel,
}) => source.startsWith('http')
    ? Image.network(
        source,
        fit: fit,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: AppColors.sandstone,
          child: Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      )
    : Image.asset(
        source,
        fit: fit,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
      );

class KhmerStayLogo extends StatelessWidget {
  const KhmerStayLogo({super.key, this.light = false, this.compact = false});

  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = light ? AppColors.ivory : AppColors.brown;
    return Semantics(
      label: 'KhmerStay',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/branding/khmerstay_mark.png',
            width: compact ? 36 : 48,
            height: compact ? 36 : 48,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          Text(
            'KhmerStay',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontFamily: 'Inter',
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.propertyId,
    this.onImage = false,
  });

  final String propertyId;
  final bool onImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      appControllerProvider.select(
        (state) => state.favorites.contains(propertyId),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? AppLocalizations.of(context).unsaved
          : AppLocalizations.of(context).saved,
      child: IconButton.filledTonal(
        tooltip: selected
            ? AppLocalizations.of(context).unsaved
            : AppLocalizations.of(context).saved,
        onPressed: () async {
          if (ref.read(apiClientProvider).token == null) {
            context.push('/signin');
            return;
          }
          try {
            await ref
                .read(appControllerProvider.notifier)
                .toggleFavorite(propertyId);
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error.toString())));
            }
            return;
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 900),
              content: Text(
                selected
                    ? AppLocalizations.of(context).unsaved
                    : AppLocalizations.of(context).saved,
              ),
            ),
          );
        },
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: onImage
              ? Theme.of(context).colorScheme.surface.withValues(alpha: .92)
              : null,
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(selected),
            color: selected
                ? AppColors.terracotta
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class PropertyCard extends ConsumerWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.width = 286,
    this.onTap,
  });

  final Property property;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final state = ref.watch(appControllerProvider);
    final s = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label:
          '${property.name.resolve(locale)}, ${property.location.resolve(locale)}',
      child: SizedBox(
        width: width,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              onTap ??
              () {
                ref
                    .read(appControllerProvider.notifier)
                    .trackPropertyView(property.id)
                    .ignore();
                context.push('/property/${property.id}');
              },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'property-${property.id}',
                child: AspectRatio(
                  aspectRatio: 1.28,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        stayImage(
                          property.image,
                          fit: BoxFit.cover,
                          semanticLabel: property.name.resolve(locale),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: FavoriteButton(
                            propertyId: property.id,
                            onImage: true,
                          ),
                        ),
                        if (property.isGuestFavorite)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _Pill(label: s.guestFavorite),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      property.name.resolve(locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: AppColors.gold,
                  ),
                  Text(property.rating.toStringAsFixed(2)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${property.type.resolve(locale)} · ${property.location.resolve(locale)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatPrice(property.priceUsd, state),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' / ${s.perNight}'),
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

class CompactPropertyCard extends ConsumerWidget {
  const CompactPropertyCard({super.key, required this.property, this.trailing});

  final Property property;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final state = ref.watch(appControllerProvider);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ref
              .read(appControllerProvider.notifier)
              .trackPropertyView(property.id)
              .ignore();
          context.push('/property/${property.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: stayImage(
                  property.image,
                  width: 94,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name.resolve(locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(property.location.resolve(locale)),
                    const SizedBox(height: 6),
                    Text(
                      formatPrice(property.priceUsd, state),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              trailing ?? FavoriteButton(propertyId: property.id),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) =>
      _SimpleState(icon: icon, title: title, body: body);
}

class _SimpleState extends StatelessWidget {
  const _SimpleState({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class GuestStepper extends StatelessWidget {
  const GuestStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center)),
        IconButton.outlined(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 310),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.fromMe
            ? AppColors.gold
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.fromMe ? 18 : 4),
          bottomRight: Radius.circular(message.fromMe ? 4 : 18),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(color: message.fromMe ? Colors.white : null),
      ),
    ),
  );
}

class LotusDivider extends StatelessWidget {
  const LotusDivider({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          Icons.spa_outlined,
          color: AppColors.gold.withValues(alpha: .7),
          size: 20,
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}
