# 🧮 Calculatrice + 🎥 Enregistrement Vidéo

Application Flutter qui combine une **calculatrice fonctionnelle** avec un **enregistrement vidéo en arrière-plan**.

## Fonctionnalités

- ✅ Calculatrice complète (addition, soustraction, multiplication, division)
- ✅ Enregistrement vidéo via la caméra arrière
- ✅ Utiliser la calculatrice pendant que la vidéo s'enregistre
- ✅ Compatible iOS et Android
- ✅ Sauvegarde automatique des vidéos

## Installation

```bash
git clone https://github.com/djenadimohamedamine-code/calculatrice.git
cd calculatrice
flutter pub get
flutter run
```

## Permissions requises

- **Caméra** : pour l'enregistrement vidéo
- **Microphone** : pour l'audio de la vidéo
- **Stockage** : pour sauvegarder les fichiers vidéo

## Structure du projet

```
lib/
├── main.dart
├── screens/
│   └── home_screen.dart
├── widgets/
│   └── calculator_widget.dart
└── services/
    └── camera_service.dart
```

## Construit avec

- Flutter SDK >=3.0.0
- Plugin `camera` pour l'enregistrement vidéo
- Plugin `permission_handler` pour les permissions
- Plugin `wakelock_plus` pour garder l'écran actif
