import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class E2EE {
  static const _privateKeyPref = 'e2ee_private_key';
  static const _publicKeyPref = 'e2ee_public_key';

  static final _algorithm = X25519();
  static SimpleKeyPair? _myKeyPair;

  /// Загрузить или создать пару ключей.
  /// Вызывается при первом входе/регистрации.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final privB64 = prefs.getString(_privateKeyPref);
    final pubB64 = prefs.getString(_publicKeyPref);

    if (privB64 != null && pubB64 != null) {
      try {
        final privBytes = base64Decode(privB64);
        final pubBytes = base64Decode(pubB64);
        final pubKey = SimplePublicKey(pubBytes, type: KeyPairType.x25519);
        _myKeyPair = SimpleKeyPairData(
          privBytes,
          publicKey: pubKey,
          type: KeyPairType.x25519,
        );
        return;
      } catch (e) {
        print('E2EE load error: $e');
      }
    }

    // Генерируем новую пару
    final keyPair = await _algorithm.newKeyPair();
    final privBytes = await keyPair.extractPrivateKeyBytes();
    final pubKey = await keyPair.extractPublicKey();

    await prefs.setString(_privateKeyPref, base64Encode(privBytes));
    await prefs.setString(_publicKeyPref, base64Encode(pubKey.bytes));

    _myKeyPair = SimpleKeyPairData(
      privBytes,
      publicKey: pubKey,
      type: KeyPairType.x25519,
    );
  }

  /// Публичный ключ (можно показывать всем).
  static Future<String?> getMyPublicKeyBase64() async {
    if (_myKeyPair == null) await init();
    final pub = await _myKeyPair!.extractPublicKey();
    return base64Encode(pub.bytes);
  }

  /// Зашифровать текст для получателя.
  /// recipientPublicKeyB64 — публичный ключ получателя (из /users).
  static Future<String?> encrypt(
    String text,
    String recipientPublicKeyB64,
  ) async {
    if (_myKeyPair == null) await init();

    try {
      final recipientPubBytes = base64Decode(recipientPublicKeyB64);
      final recipientPub = SimplePublicKey(
        recipientPubBytes,
        type: KeyPairType.x25519,
      );

      // Общий секрет: только у тебя и у получателя
      final sharedSecret = await _algorithm.sharedSecretKey(
        keyPair: _myKeyPair!,
        remotePublicKey: recipientPub,
      );

      final rawSecret = await sharedSecret.extractBytes();
      final chachaKey = SecretKey(rawSecret.sublist(0, 32));

      // Шифруем через ChaCha20-Poly1305
      final chacha = Chacha20.poly1305Aead();
      final nonce = chacha.newNonce();
      final secretBox = await chacha.encrypt(
        utf8.encode(text),
        secretKey: chachaKey,
        nonce: nonce,
      );

      // Упаковка: [12 байт nonce][ciphertext][16 байт MAC]
      final packed = <int>[];
      packed.addAll(secretBox.nonce);
      packed.addAll(secretBox.cipherText);
      packed.addAll(secretBox.mac.bytes);

      return base64Encode(packed);
    } catch (e) {
      print('E2EE encrypt error: $e');
      return null;
    }
  }

  /// Расшифровать сообщение.
  /// senderPublicKeyB64 — публичный ключ отправителя.
  static Future<String?> decrypt(
    String encryptedB64,
    String senderPublicKeyB64,
  ) async {
    if (_myKeyPair == null) await init();

    try {
      final packed = base64Decode(encryptedB64);
      if (packed.length < 12 + 16) return null;

      final nonce = packed.sublist(0, 12);
      final cipherText = packed.sublist(12, packed.length - 16);
      final macBytes = packed.sublist(packed.length - 16);

      final senderPubBytes = base64Decode(senderPublicKeyB64);
      final senderPub = SimplePublicKey(
        senderPubBytes,
        type: KeyPairType.x25519,
      );

      final sharedSecret = await _algorithm.sharedSecretKey(
        keyPair: _myKeyPair!,
        remotePublicKey: senderPub,
      );

      final rawSecret = await sharedSecret.extractBytes();
      final chachaKey = SecretKey(rawSecret.sublist(0, 32));

      final chacha = Chacha20.poly1305Aead();
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final clear = await chacha.decrypt(
        secretBox,
        secretKey: chachaKey,
      );

      return utf8.decode(clear);
    } catch (e) {
      print('E2EE decrypt error: $e');
      return null;
    }
  }
}