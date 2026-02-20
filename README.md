# qr_native_bridge

Plugin Flutter para **leitura** e **geração** de QR code usando implementação nativa (iOS implementado; Android em stub).

## Uso

### 1. Dependência

No `pubspec.yaml` do seu app:

```yaml
dependencies:
  qr_native_bridge:
    path: ../qr-native-bridge   # ou o caminho do pacote
    # Se publicar: qr_native_bridge: ^0.0.1
```

Depois: `flutter pub get`.

### 2. Código

```dart
import 'package:qr_native_bridge/qr_native_bridge.dart';

final bridge = QrNativeBridge();

// Escanear QR (abre a câmera nativa)
final String? valor = await bridge.scanQr();
// valor == null se o usuário cancelar

// Gerar QR (retorna bytes PNG)
final Uint8List pngBytes = await bridge.generateQr('https://meusite.com/abc');
// use Image.memory(pngBytes) ou salve em arquivo
```

### 3. iOS

- **Câmera:** adicione no `Info.plist` do app (Runner):

```xml
<key>NSCameraUsageDescription</key>
<string>Sua mensagem de uso da câmera para QR.</string>
```

- O plugin já inclui a tela nativa de scanner (com botão Cancelar) e a geração via `CoreImage`.

### 4. Android

- `scanQr` e `generateQr` retornam `notImplemented` por enquanto. Você pode implementar no `QrNativeBridgePlugin.kt` ou tratar no app (ex.: esconder botões de QR no Android até haver implementação).

## Usar no Jogo-da-velha (ou outro app)

1. No projeto (ex.: Jogo-da-velha), adicione o pacote com `path` apontando para a pasta do `qr-native-bridge`.
2. Troque as chamadas que usam `NativeQrScannerChannel` / `NativeQrGeneratorChannel` por:

```dart
final bridge = QrNativeBridge();
// Em vez de NativeQrScannerChannel.scan():
final value = await bridge.scanQr();
// Em vez de NativeQrGeneratorChannel.generate(data):
final bytes = await bridge.generateQr(data);
```

3. No **Jogo-da-velha**, você pode remover do `AppDelegate.swift` os blocos dos channels `br.com.kalebemisael.jogodavelha/qr` e `br.com.kalebemisael.jogodavelha/qr_scanner` (e a lógica de `generateQrPng` e `presentQrScanner`), pois isso passa a ser responsabilidade do plugin.
4. Mantenha no app apenas o que for específico do jogo (ex.: deeplink).

## API

| Método | Retorno | Descrição |
|--------|---------|-----------|
| `getPlatformVersion()` | `Future<String?>` | Versão da plataforma (ex.: "iOS 17.0"). |
| `scanQr()` | `Future<String?>` | Abre o scanner nativo; retorna o valor ou `null` se cancelar. |
| `generateQr(String data)` | `Future<Uint8List>` | Gera QR em PNG; lança exceção em erro. |

## Exemplo

O app em `example/` demonstra os três métodos. Rode no iOS:

```bash
cd example && flutter run
```

## Estrutura do plugin

- **Dart:** `lib/qr_native_bridge.dart` (API), `qr_native_bridge_platform_interface.dart`, `qr_native_bridge_method_channel.dart`.
- **iOS:** `ios/Classes/QrNativeBridgePlugin.swift` (channel único `qr_native_bridge`), `QrScannerViewController.swift` (tela de scanner).
- **Android:** `android/.../QrNativeBridgePlugin.kt` (responde `getPlatformVersion`; `scanQr`/`generateQr` retornam `notImplemented`).
