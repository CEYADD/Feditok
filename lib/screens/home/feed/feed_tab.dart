import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../models/models.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final PageController _feedController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedProvider>(context, listen: false).fetchChronologicalFeed();
    });
  }

  @override
  void dispose() {
    _feedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);

    if (feedProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final videos = feedProvider.feedVideos;

    // Se non ci sono video o siamo arrivati in fondo
    final totalCount = videos.length + 1; // +1 per la schermata "Sei arrivato alla fine!"

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _feedController,
        scrollDirection: Axis.vertical,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < videos.length) {
            final video = videos[index];
            return _VideoFeedItem(video: video);
          } else {
            // Fine del feed: "Sei arrivato alla fine!"
            return _EndFeedScreen();
          }
        },
      ),
    );
  }
}

class _VideoFeedItem extends StatelessWidget {
  final VideoItem video;

  const _VideoFeedItem({required this.video});

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);

    return Stack(
      children: [
        // Sfondo/Player video
        Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
                const SizedBox(height: 12),
                Text(
                  'Video Player Stub (${video.videoUrl})',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Info Autore e Caption in basso a sinistra
        Positioned(
          left: 16,
          bottom: 24,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: video.author?.avatarUrl != null
                        ? NetworkImage(video.author!.avatarUrl!)
                        : null,
                    child: video.author?.avatarUrl == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '@${video.author?.username ?? "user"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (video.caption != null)
                Text(
                  video.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
            ],
          ),
        ),

        // Colonna Azioni in basso a destra (Mi piace, commenta, salva in locale, condividi)
        Positioned(
          right: 16,
          bottom: 40,
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  video.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: video.isLikedByMe ? Colors.red : Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  feedProvider.toggleLike(video.id);
                },
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 32),
                onPressed: () {
                  _showCommentsModal(context, video.id);
                },
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white, size: 32),
                onPressed: () {
                  feedProvider.saveVideoLocally(video.videoUrl, video.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video salvato nella memoria locale!')),
                  );
                },
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 32),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link di condivisione copiato!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCommentsModal(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Commenti',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              const Expanded(
                child: Center(
                  child: Text('Nessun commento presente. Sii il primo!'),
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Aggiungi un commento...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EndFeedScreen extends StatelessWidget {
  final List<String> stubMessages = [
    "Prenditi una pausa! Hai visto tutti i video dei tuoi amici.",
    "Il feed è finito. È l'ora di fare due passi all'aperto! 🌿",
    "Nessun altro video per ora. Torna più tardi o invia un messaggio ad un amico.",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          const Text(
            'Sei arrivato alla fine!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun infinito doomscrolling. Ecco alcune riflessioni per te:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: stubMessages.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      stubMessages[index],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
