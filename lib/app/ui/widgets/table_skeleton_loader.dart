import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Skeleton loader elegante para simular o carregamento das linhas da tabela
/// durante a latência de rede ou processamento assíncrono de IA.
class TableSkeletonLoader extends StatefulWidget {
  final int rowCount;

  const TableSkeletonLoader({super.key, this.rowCount = 6});

  @override
  State<TableSkeletonLoader> createState() => _TableSkeletonLoaderState();
}

class _TableSkeletonLoaderState extends State<TableSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(650.0, constraints.maxWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    children: List.generate(
                      widget.rowCount,
                      (index) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Coluna Nome
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.border,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildShimmerBox(width: 140, height: 14),
                                      const SizedBox(height: 6),
                                      _buildShimmerBox(width: 90, height: 10),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Coluna Cidade
                            Expanded(
                              flex: 3,
                              child: _buildShimmerBox(width: 120, height: 12),
                            ),
                            // Coluna Documentos
                            Expanded(
                              flex: 2,
                              child: _buildShimmerBox(width: 80, height: 22, radius: 12),
                            ),
                            // Coluna Ações
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildShimmerBox(width: 60, height: 28, radius: 6),
                                  const SizedBox(width: 8),
                                  _buildShimmerBox(width: 32, height: 32, radius: 6),
                                  const SizedBox(width: 8),
                                  _buildShimmerBox(width: 32, height: 32, radius: 6),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
