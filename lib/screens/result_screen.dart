import 'package:flutter/material.dart';

import '../models/level_result.dart';
import '../widgets/piece_gallery.dart';

/// Post-cut screen — shows every piece's percentage and the final accuracy.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.assetPath,
    required this.result,
    this.title = 'Result',
  });

  final String assetPath;
  final LevelResult result;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: result.objectiveMet
                          ? const Color(0xFF000000)
                          : const Color(0xFFCC0000),
                      height: 0.9,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'accuracy',
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${result.points} pts',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (!result.objectiveMet && result.objectiveMessage != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFFCEAEA),
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Text(
                        'Objective failed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCC0000),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'You did not meet the objective: '
                        '${result.objectiveMessage}. '
                        'Accuracy is recorded as 0%.',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFFB33333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, color: Color(0xFF000000)),
            Expanded(
              child: PieceGallery(
                assetPath: assetPath,
                pieces: result.pieces,
              ),
            ),
            const Divider(height: 1, color: Color(0xFF000000)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
