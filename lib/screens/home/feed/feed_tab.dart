import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/feed_provider.dart';
import '../../../models/models.dart';
import 'camera_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> with SingleTickerProviderStateMixin {
  final PageController _feedController = PageController();

  bool _isFabOpen = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      value: _isFabOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedProvider>(
        context,
        listen: false,
      ).fetchChronologicalFeed();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _feedController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  Future<void> _pickFileFromGallery() async {
    _toggleFab();
    final picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery);

    if (file != null && file.path.isNotEmpty) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF1E1E1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => UploadDetailsModal(mediaPath: file.path),
        );
      }
    }
  }

  void _openCamera() {
    _toggleFab();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);

    if (feedProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final videos = feedProvider.feedVideos;
    final totalCount = videos.length + 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _feedController,
            scrollDirection: Axis.vertical,
            itemCount: totalCount,
            itemBuilder: (context, index) {
              if (index < videos.length) {
                final video = videos[index];
                return _VideoFeedItem(video: video);
              } else {
                return const _EndFeedScreen();
              }
            },
          ),

          // FAB Animato (+) con Fotocamera e Galleria
          Positioned(
            right: 20,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Pulsante Galleria Foto / Video
                ScaleTransition(
                  scale: _expandAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Galleria',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'gallery_btn',
                          backgroundColor: Colors.purpleAccent,
                          onPressed: _pickFileFromGallery,
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pulsante Fotocamera Integrata
                ScaleTransition(
                  scale: _expandAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Fotocamera',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'camera_btn',
                          backgroundColor: Colors.cyan,
                          onPressed: _openCamera,
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pulsante Principale (+)
                FloatingActionButton(
                  heroTag: 'main_plus_btn',
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: _toggleFab,
                  child: AnimatedRotation(
                    turns: _isFabOpen ? 0.125 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.add, size: 28, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: Colors.white54,
                ),
                const SizedBox(height: 12),
                Text(
                  video.title ?? 'Video Stub (${video.videoUrl})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

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

        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  video.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: video.isLikedByMe ? Colors.red : Colors.white,
                  size: 32,
                ),
                onPressed: () => feedProvider.toggleLike(video.id),
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(
                  Icons.comment_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => _showCommentsModal(context, video.id),
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(
                  Icons.download_for_offline_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  feedProvider.saveVideoLocally(video.videoUrl, video.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video salvato in locale!')),
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
              const Expanded(child: Center(child: Text('Nessun commento.'))),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Aggiungi un commento...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => Navigator.pop(context),
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

// 14. Schermata di fine feed con barra di caricamento fluida ogni 10 secondi e frase dinamica
class _EndFeedScreen extends StatefulWidget {
  const _EndFeedScreen();

  @override
  State<_EndFeedScreen> createState() => _EndFeedScreenState();
}

class _EndFeedScreenState extends State<_EndFeedScreen>
    with SingleTickerProviderStateMixin {
  // LISTA DELLE FRASE DI INCORAGGIAMENTO (Personalizzabile qui!)
  final List<String> stubMessages = [
    "Prenditi una pausa! Hai visto tutti i video dei tuoi amici.😊",
    "Il feed è finito. È l'ora di fare due passi all'aperto! 🌿",
    "Nessun altro video per ora. Torna più tardi o invia un messaggio ad un amico. 📩",
    "Ricordati di bere un bicchiere d'acqua e sgranchirti le gambe 💧",
    "La vita vera è fuori dallo schermo. Fai qualcosa che ami oggi! ✨",
    "Hai visto tutti i video. Perché non provi a creare il tuo? 🎬",
    "Il feed è vuoto. È il momento perfetto per leggere un libro o ascoltare della musica. 📚🎵",
    "Hai raggiunto la fine del feed. È il momento di fare una pausa e respirare profondamente. 🌬️",
    "Nessun altro video da guardare. Perché non invii un messaggio a un amico o fare una videochiamata? 📞",
    "Fuori è una bella giornata. Esci e goditi il sole! ☀️",
    "Copertina tattica e libro? 📖",
    "Lo sapevi che fare una passeggiata di 10 minuti può migliorare la tua creatività? 🚶‍♂️",
    "Niente da fare? Prova a scrivere un diario o a disegnare qualcosa. 📝🎨",
    "Hai visto tutti i video. Perché non provi a fare un po' di stretching o yoga? 🧘‍♂️",
    "Hai raggiunto il fondo del feed! Tempo di fare un bel respiro profondo. 🌬️",
    "Schermo in pausa, mente libera. Rilassa gli occhi per qualche minuto! 👀✨",
    "Nessun altro contenuto. Che ne dici di guardare fuori dalla finestra? 🪟🍃",
    "Stacca la spina! Una piccola pausa fa meraviglie per la mente. 🔋",
    "Feed completato! Bevi un sorso d'acqua e fai un po' di stretching. 💧🧘",
    "Hai visto tutto! È il momento perfetto per sgranchirti le spalle e il collo. 🙆‍♂️",
    "La natura ti sta aspettando là fuori. Fai due passi all'aria aperta! 🌲",
    "Tempo di fare un po' di decompressione. Rilassa i muscoli della testa e delle spalle! ✨",
    "Guardare fisso uno schermo stanca gli occhi. Fai una pausa visiva! 👁️",
    "È ora di una tazza di tè o di un buon caffè. Ricaricati! ☕",
    "La tua mente ti ringrazierà per questa piccola pausa offline. 🧠💚",
    "Prenditi un momento per stare nel presente. Nessun contenuto da rincorrere! 🛋️",
    "Nient'altro da scorrere! Chiudi gli occhi per 30 secondi e rilassati. 😌",
    "Hai completato il feed! Un po' di aria fresca è la miglior ricarica. 🌤️",
    "Fai una pausa e ascolta il tuo corpo: ha bisogno di muoversi o di riposare? 👣",
    "Nessun nuovo aggiornamento. Ottimo momento per fare un po' di meditazione! 🧘‍♀️",
    "Il feed può attendere, la tua salute mentale no. Prenditi del tempo per te. 💚",
    "Un bicchiere d'acqua e cinque minuti di riposo: la ricetta perfetta! 🥛",
    "Hai visto tutto per oggi! Fai fare un po' di pausa anche ai tuoi pollici. 👍",
    "Momento check-in: come ti senti? Fai un bel respiro ed esci dall'app! 🌬️",
    "La luce del sole è molto meglio di quella dello schermo. Esci a godertela! ☀️",
    "Tempo di fare un po' di mobilità per la schiena! Sgranchisciti un po'. 🤸‍♂️",
    "Nessun altro video. Che ne dici di fare una passeggiata rigenerante? 🚶‍♀️",
    "Il tuo feed è pulito e in ordine. Ora prenditi cura di te! ✨",
    "Hai finito i video! Tempo di sognare a occhi aperti per un po'. ☁️",
    "Feed vuoto! È il momento di accendere la tua creatività. 🎨",
    "Hai visto i contenuti degli altri, ora crea qualcosa di tuo! ✍️",
    "Niente più video per ora. Perché non prendi in mano quel libro che volevi leggere? 📚",
    "Tempo libero sbloccato! Impara qualcosa di nuovo o riprendi un tuo hobby. 🎸",
    "Il feed è finito. È l'ora perfetta per ascoltare il tuo album preferito! 🎧",
    "Nessun aggiornamento! Metti su della buona musica e rilassati. 🎶",
    "Che ne dici di mettere per iscritto tre cose belle successe oggi? 📝",
    "Nessun video rimasto. Tempo di cucinare qualcosa di delizioso! 🍳",
    "Hai visto tutto! Che ne dici di riordinare un piccolo angolo della tua stanza? 🧹",
    "Feed terminato! Ottima occasione per fare un po' di sketch o disegno. 🎨",
    "È ora di passare dall'essere spettatore all'essere creatore! 🎬",
    "Niente più contenuti. Perché non provi una nuova ricetta oggi? 🥗",
    "Hai raggiunto la fine! È il momento ideale per un podcast stimolante. 🎙️",
    "Feed vuoto! Prendi carta e penna e annota le tue idee. 💡",
    "Nessun altro video. Ora tocca a te fare un po' di magia! ✨",
    "Hai finito tutti i post. Che ne dici di fare un puzzle o un gioco di logica? 🧩",
    "Metti via lo smartphone e scopri cosa sa fare la tua fantasia! 💭",
    "Feed completato! Tempo di annaffiare le piante o curare il giardino. 🪴",
    "Hai visto tutto! Dedica del tempo ai tuoi progetti personali. 🚀",
    "Niente da scorrere. Il momento perfetto per leggere un capitolo in più! 📖",
    "Feed vuoto. Accendi la tua playlist preferita e balla un po'! 🕺",
    "Ottimo lavoro nel rimanere aggiornato. Ora crea la tua prossima storia! 📽️",
    "Tutti i video visti! È ora di fare un po' di brainstorming per le tue idee. 🧠",
    "Nessun nuovo contenuto. Metti alla prova le tue abilità in cucina! 🍕",
    "Feed esaurito! Riscopri la bellezza di fare le cose con calma. 🕯️",
    "Hai visto le novità di tutti. Ora invia un salutino a un amico! 💬",
    "Feed terminato! È il momento giusto per chiamare una persona cara. 📞",
    "Nessun altro post da guardare. Organizza un caffè con qualcuno! ☕",
    "Hai visto cosa fanno gli altri: perché non li incontri dal vivo? 🤝",
    "Niente più video! Manda un messaggio affettuoso a chi non senti da un po'. 📩",
    "I social sono belli, ma gli abbracci dal vivo sono meglio. Trova i tuoi amici! 🫂",
    "Feed finito! Sorprendi un amico con una foto o un bel ricordo insieme. 📸",
    "Hai visto tutti i contenuti. È l'ora di fare due chiacchiere reali! 🗣️",
    "Nessun nuovo aggiornamento. Che ne dici di fare una videochiamata? 📱",
    "Tempo di disconnettersi e connettersi con le persone intorno a te. ❤️",
    "Hai visto tutti i video. Organizza una serata giochi con gli amici! 🎲",
    "Feed vuoto! Fai un complimento spontaneo a un amico oggi. 🌟",
    "Nessun altro video. È il momento perfetto per una passeggiata in compagnia! 🚶‍♂️",
    "Hai completato il feed! Manda un vocale divertente alla chat di gruppo. 🎙️",
    "Niente più contenuti. Chiedi a un amico come sta andando la sua giornata! 😊",
    "I post sono finiti. Regala un sorriso a chi hai accanto! 😄",
    "Hai visto tutto. Tempo di pianificare la prossima uscita insieme! 🎟️",
    "Feed completato! Ricordati di dedicare del tempo di qualità a chi ami. 💖",
    "Nessun altro contenuto. Chiama i tuoi genitori o i tuoi nonni! 👵👨‍🦳",
    "Hai visto le storie degli altri. Ora vivi le tue storie dal vivo! 🌟",
    "Feed libero! Dedica attenzione completa a chi è con te in questo momento. 🛋️",
    "Nessun video rimasto. Proponi un'attività divertente al tuo migliore amico! 🚴",
    "Hai visto tutte le novità! Condividi un momento di gioia offline. 🎉",
    "Niente più post. È l'ora di godersi la compagnia di un animale domestico! 🐶🐱",
    "Hai finito il feed! Rendi speciale la giornata di qualcuno con un piccolo gesto. 🎁",
    "Congratulazioni, hai internet-finito per oggi! 🏆",
    "Ahi ahi, l'algoritmo ha finito le idee. Torna più tardi! 🤖",
    "Hai scatenato lo scroll supremo! Nessun altro video disponibile. ⚡",
    "Stop! Il tuo pollice merita una medaglia d'oro. 🥇",
    "Navigazione completata con successo. Ora torna sulla Terra! 🚀",
    "Nessun contenuto trovato. Perfetto, hai appena vinto del tempo libero! 🎁",
    "Hai visto tutto! Nemmeno l'algoritmo riesce a stare dietro al tuo ritmo. 💨",
    "Fine della corsa! Ora di riposare le dita e ricaricare le batterie. 🔌",
    "404: Contenuti finiti. È l'ora di scoprire il mondo reale! 🌍",
    "Hai esplorato ogni angolo del feed. Missione compiuta! 🎯",
    "Alt! Controllo del feed: tutto visto. Puoi procedere verso la vita vera! 🛑",
    "Niente più scroll per ora. Nemmeno se fai il refresh con insistenza! 🔄😉",
    "Sei arrivato alla fine dell'infinito. Risultato notevole! 🌌",
    "L'algoritmo ha bisogno di un pisolino. E anche tu forse! 😴",
    "Nessun video in vista! La tua app è ufficialmente in pausa ricreazione. 🔔",
    "Hai scrollato così veloce da superare i nostri server! ⚡",
    "Fine della maratona di video. È ora di tagliare il traguardo offline! 🏁",
    "Nient'altro da mostrare. Vai e conquista la giornata! 💪",
    "Feed vuoto! Il tuo telefono ti ringrazia per la pausa. 📱✨",
    "Nessun aggiornamento. È un ottimo segno per fare altro! 🌈",
    "Hai visto proprio tutto! Ora puoi dire con orgoglio di essere aggiornatissimo. 🎓",
    "Feed terminato! Niente panico, ci saranno nuovi video presto. 🕒",
    "Game over per il feed per ora! Inizia il livello 'Vita Reale'. 🎮",
    "Niente più contenuti. Ora vai e fai qualcosa di memorabile! 🚀",
    "Hai completato il feed! Ricordati: le cose migliori accadono fuori dagli schermi. ✨",
  ];

  int _currentIndex = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() {
                _currentIndex = (_currentIndex + 1) % stubMessages.length;
              });
              _progressController.forward(from: 0.0);
            }
          });
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            'Sei arrivato alla fine!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun infinito doomscrolling. Prossimo consiglio tra 10s:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Barra di caricamento fluida di 10 secondi
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressController.value,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Frase di incoraggiamento dinamica
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                stubMessages[_currentIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
