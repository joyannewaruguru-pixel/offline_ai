import '../../db_service.dart';
import 'db_service.dart';

class InputEvent {
  final String   type;
  final String   message;
  final DateTime time;

  InputEvent({required this.type, required this.message, required this.time});
}

class EventLogger {
  final List<InputEvent> _history = [];

  List<InputEvent> getHistory() =>
      List.unmodifiable(_history.reversed.toList());

  Future<void> log(String type, String message, String userEmail) async {
    _history.add(InputEvent(type: type, message: message, time: DateTime.now()));
    await DBService.instance.logActivity(userEmail, type, message);
  }

  void clear() => _history.clear();
}

class GestureHandler {
  final EventLogger _logger;
  final String      _userEmail;

  GestureHandler({required EventLogger logger, required String userEmail})
      : _logger    = logger,
        _userEmail = userEmail;

  Future<String> onTap(String target) async {
    final msg = 'Tap detected on: $target';
    await _logger.log('TAP', msg, _userEmail);
    return msg;
  }

  Future<String> onSwipeLeft(String target) async {
    final msg = 'Swipe left on: $target';
    await _logger.log('SWIPE_LEFT', msg, _userEmail);
    return msg;
  }

  Future<String> onSwipeRight(String target) async {
    final msg = 'Swipe right on: $target';
    await _logger.log('SWIPE_RIGHT', msg, _userEmail);
    return msg;
  }

  Future<String> onLongPress(String target) async {
    final msg = 'Long press on: $target';
    await _logger.log('LONG_PRESS', msg, _userEmail);
    return msg;
  }
}

class KeyboardController {
  final EventLogger _logger;
  final String      _userEmail;

  KeyboardController({required EventLogger logger, required String userEmail})
      : _logger    = logger,
        _userEmail = userEmail;

  Future<void> onKeyInput(String text) async {
    if (text.isEmpty) return;
    await _logger.log('KEY_INPUT', 'Input: "$text"', _userEmail);
  }

  String? validateInput(String value) {
    if (value.trim().isEmpty)   return 'Input cannot be empty';
    if (value.trim().length < 3) return 'Input too short (min 3 characters)';
    if (value.trim().length > 100) return 'Input too long (max 100 characters)';
    return null;
  }

  Future<String> onSubmit(String text) async {
    final error = validateInput(text);
    if (error != null) {
      await _logger.log('VALIDATION_FAIL', 'Submit failed: $error', _userEmail);
      return 'Error: $error';
    }
    await _logger.log('FORM_SUBMIT', 'Submitted: "$text"', _userEmail);
    return 'Form submitted successfully: "$text"';
  }
}

class MobileApp {
  final EventLogger        logger;
  final GestureHandler     gestureHandler;
  final KeyboardController keyboardController;

  MobileApp({required String userEmail})
      : logger             = EventLogger(),
        gestureHandler     = GestureHandler(
            logger: EventLogger(), userEmail: userEmail),
        keyboardController = KeyboardController(
            logger: EventLogger(), userEmail: userEmail);

  static MobileApp? _instance;

  static MobileApp getInstance(String userEmail) {
    _instance ??= MobileApp(userEmail: userEmail);
    return _instance!;
  }

  static void reset() => _instance = null;
}