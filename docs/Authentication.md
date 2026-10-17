# Flussi di Autenticazione

Feditok supporta due percorsi primari di autenticazione:

---

## 1. Login e Registrazione via Email
- Gestito direttamente tramite il servizio Supabase Auth (`signUp`, `signInWithPassword`, reset password).
- **Controllo di sicurezza delle password:** Le password in fase di registrazione devono soddisfare i requisiti minimi di sicurezza (almeno 6 caratteri, lettere maiuscole, minuscole, numeri e caratteri speciali).
- Verifica via email con schermata dedicata di avviso prima dell'onboarding.

---

## 2. Autenticazione Dinamica ActivityPub (Fediverso)
L'app permette agli utenti di autenticarsi utilizzando il proprio account Mastodon o compatibile con il Fediverso (`@username@istanza.social` o `istanza.social`):

1. **Registrazione Client Dinamica:** L'applicazione contatta l'endpoint `/api/v1/apps` dell'istanza dell'utente registrando l'applicazione client con redirect URI `feditok://login-callback`.
2. **Autorizzazione Browser:** L'utente autorizza l'applicazione nel proprio browser web.
3. **Deep Link Callback:** L'istanza reindirizza a `feditok://login-callback?code=...`, intercettato da Android (`intent-filter`) e iOS (`CFBundleURLTypes`).
4. **Resilienza e Timeout:** Il flusso include un timer di timeout (90s), pulsante di annullamento e una casella di fallback per inserire manualmente il codice di verifica qualora il browser non reindirizzi l'utente.
5. **Sincronizzazione Supabase:** Al termine del token exchange, i dati del profilo federato vengono sincronizzati con la tabella `profiles` su Supabase.
