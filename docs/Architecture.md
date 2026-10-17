# Architettura dell'Applicazione

Feditok adotta un'architettura modulare a livelli basata sulle best practices raccomandate per Flutter:

```
lib/
├── main.dart               # Entrypoint dell'applicazione e configurazione dei Provider
├── models/                 # Modelli di dominio (UserProfile, VideoItem, AppNotification, etc.)
├── providers/              # State management con Provider / ChangeNotifier
│   ├── auth_provider.dart    # Gestione sessione, profili utente, login email/Fediverso
│   ├── feed_provider.dart    # Feed video, like, commenti, salvataggio locale
│   └── friends_provider.dart # Relazioni di amicizia e messaggistica
├── services/               # Servizi esterni e API
│   └── activity_pub_oauth.dart # OAuth dinamico per istanze Mastodon / ActivityPub
├── screens/                # UI Screens e Tabs
│   ├── auth/                 # Schermate di login/signup (Email & ActivityPub)
│   ├── onboarding/           # Wizard di completamento profilo
│   └── home/                 # Schermata principale (Feed, Friends, Profile, Camera)
└── widgets/                # Widget riutilizzabili (video player, pulsanti di interazione)
```

## Backend e Database (Supabase)
- **Database:** PostgreSQL con Row Level Security (RLS) attiva su tutte le tabelle esposte (`profiles`, `videos`, `video_likes`, `video_comments`, `friends`, `messages`).
- **Storage:** Bucket `Videos` e `ProfilePic` configurati per il caricamento e la fruizione ottimizzata di media.
- **Triggers & Security:** Funzioni `SECURITY DEFINER` rigorosamente limitate a ruoli amministrativi con trigger automatici di gestione utente.
