import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';

/// Full-screen viewer for a submitted KYC or property document.
///
/// PDFs are opened in a new tab rather than rendered in-app, which is the only
/// reliable option without adding a PDF rendering dependency. Images are shown
/// zoomable, with decode constraints so a high-resolution scan cannot exhaust
/// memory on a phone.
class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.url,
    required this.title,
    required this.isPdf,
  });

  final String url;
  final String title;
  final bool isPdf;

  Future<void> _openExternally(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Open in new tab',
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () => _openExternally(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isPdf ? _buildPdfNotice(context, theme) : _buildImage(context),
    );
  }

  Widget _buildPdfNotice(BuildContext context, ThemeData theme) {
    return AdminStateView(
      icon: Icons.picture_as_pdf_rounded,
      title: 'PDF document',
      message: 'PDFs open in a new browser tab so you can zoom and download '
          'the original file.',
      actionLabel: 'Open PDF',
      actionIcon: Icons.open_in_new_rounded,
      onAction: () => _openExternally(context),
      isBusy: false,
    );
  }

  Widget _buildImage(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          // Cap the decoded size. Without this a 4000px document scan is
          // decoded at full resolution and can crash the app on a phone.
          cacheWidth: 1600,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            // A page-shaped skeleton rather than a spinner: it occupies the
            // same footprint the document will, so nothing jumps when the
            // image resolves.
            return const _DocumentSkeleton();
          },
          errorBuilder: (context, error, stackTrace) {
            return AdminStateView(
              icon: Icons.broken_image_rounded,
              title: 'Could not load document',
              message: 'The image may have been removed, or the link may be '
                  'incomplete.',
              actionLabel: 'Open in new tab',
              actionIcon: Icons.open_in_new_rounded,
              onAction: () => _openExternally(context),
              tone: AdminStateTone.error,
            );
          },
        ),
      ),
    );
  }
}

/// Page-shaped placeholder for a document still downloading.
class _DocumentSkeleton extends StatelessWidget {
  const _DocumentSkeleton();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // A sheet at roughly A4 proportions, capped so it does not fill a desktop
    // window edge to edge.
    final pageHeight = (size.width * 1.414).clamp(200.0, size.height - 80.0);
    final pageWidth = pageHeight / 1.414;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppShimmer(
          child: Container(
            width: pageWidth,
            height: pageHeight,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A header block, then body lines of varying length so the
                // skeleton reads as a document rather than a blank panel.
                const ShimmerBox(width: 120, height: 16),
                const SizedBox(height: 26),
                for (var i = 0; i < 9; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  FractionallySizedBox(
                    widthFactor: i == 8 ? 0.45 : (i.isEven ? 1.0 : 0.92),
                    alignment: Alignment.centerLeft,
                    child: const ShimmerLine(height: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
