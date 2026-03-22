/// Health Tips Screen - REQ-3.x
/// REQ-3.1: Breathing exercise animations, REQ-3.2: Categories
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/health_tips_repository.dart';
import '../../../domain/providers/app_providers.dart';

class HealthTipsScreen extends ConsumerStatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  ConsumerState<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends ConsumerState<HealthTipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(healthTipsRepoProvider);
    final categories = repo.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tips'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF69F6B8),
          labelColor: const Color(0xFF69F6B8),
          unselectedLabelColor: Colors.white60,
          dividerColor: Colors.transparent,
          tabs: categories.map((c) => Tab(text: c[0].toUpperCase() + c.substring(1))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: categories.map((cat) {
          final tips = repo.getByCategory(cat);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            itemBuilder: (_, i) {
              final t = tips[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _openTipDetail(context, t),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              t.hasAnimation ? Icons.animation : Icons.fitness_center,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(t.description),
                        if (t.duration != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Chip(
                              label: Text(t.duration!),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _openTipDetail(BuildContext context, HealthTip tip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TipDetailScreen(tip: tip),
      ),
    );
  }
}

class _TipDetailScreen extends StatefulWidget {
  final HealthTip tip;

  const _TipDetailScreen({required this.tip});

  @override
  State<_TipDetailScreen> createState() => _TipDetailScreenState();
}

class _TipDetailScreenState extends State<_TipDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tip;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.hasAnimation) ...[
              Center(
                child: _BreathingAnimation(controller: _animCtrl),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              t.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (t.duration != null) ...[
              const SizedBox(height: 12),
              Chip(label: Text(t.duration!)),
            ],
            const SizedBox(height: 16),
            const Text('Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...t.steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.value)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _BreathingAnimation extends AnimatedWidget {
  const _BreathingAnimation({required AnimationController controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final ctrl = listenable as AnimationController;
    final breath = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );
    return AnimatedBuilder(
      animation: breath,
      builder: (_, child) {
        return Container(
          width: 120 * breath.value,
          height: 120 * breath.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF69F6B8).withValues(alpha: 0.15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF69F6B8).withValues(alpha: 0.2),
                blurRadius: 40 * ctrl.value,
                spreadRadius: 20 * ctrl.value,
              ),
            ],
            border: Border.all(color: const Color(0xFF69F6B8).withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              ctrl.value < 0.5 ? 'Breathe In' : 'Breathe Out',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF69F6B8)),
            ),
          ),
        );
      },
    );
  }
}
