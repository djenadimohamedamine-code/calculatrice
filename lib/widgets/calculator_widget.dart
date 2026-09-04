import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorWidget extends StatefulWidget {
  /// Callback appelé quand l'utilisateur fait un appui long sur "="
  final VoidCallback? onSecretTrigger;

  const CalculatorWidget({super.key, this.onSecretTrigger});

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onNumberPressed(String number) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = number;
        _shouldResetDisplay = false;
      } else {
        if (_display.length < 12) {
          _display += number;
        }
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperatorPressed(String op) {
    setState(() {
      if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
        _calculate();
      }
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _expression = '${_formatNumber(_firstOperand!)} $op';
      _shouldResetDisplay = true;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;

    final secondOperand = double.tryParse(_display);
    if (secondOperand == null) return;

    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case 'x':
        result = _firstOperand! * secondOperand;
        break;
      case '/':
        if (secondOperand == 0) {
          setState(() {
            _display = 'Erreur';
            _expression = '';
            _firstOperand = null;
            _operator = null;
            _shouldResetDisplay = true;
          });
          return;
        }
        result = _firstOperand! / secondOperand;
        break;
      default:
        return;
    }

    setState(() {
      _expression = '';
      _display = _formatNumber(result);
      _firstOperand = result;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  void _onEqualsPressed() {
    _calculate();
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1 && _display != '0') {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onPercentPressed() {
    setState(() {
      final value = double.tryParse(_display);
      if (value != null) {
        _display = _formatNumber(value / 100);
        _shouldResetDisplay = true;
      }
    });
  }

  void _onToggleSignPressed() {
    setState(() {
      if (_display != '0') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      }
    });
  }

  String _formatNumber(double number) {
    if (number == number.toInt().toDouble()) {
      return number.toInt().toString();
    }
    String result = number.toStringAsFixed(8);
    result = result.replaceAll(RegExp(r'0+$'), '');
    result = result.replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDisplay(),
        Expanded(
          child: _buildButtonGrid(),
        ),
      ],
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_expression.isNotEmpty)
            Text(
              _expression,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 18,
              ),
              textAlign: TextAlign.right,
            ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _display,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildButtonRow([
            _CalcButton('C', _onClearPressed, type: _ButtonType.function),
            _CalcButton('+/-', () => _onToggleSignPressed(), type: _ButtonType.function),
            _CalcButton('%', () => _onPercentPressed(), type: _ButtonType.function),
            _CalcButton('/', () => _onOperatorPressed('/'), type: _ButtonType.operator),
          ]),
          _buildButtonRow([
            _CalcButton('7', () => _onNumberPressed('7')),
            _CalcButton('8', () => _onNumberPressed('8')),
            _CalcButton('9', () => _onNumberPressed('9')),
            _CalcButton('x', () => _onOperatorPressed('x'), type: _ButtonType.operator),
          ]),
          _buildButtonRow([
            _CalcButton('4', () => _onNumberPressed('4')),
            _CalcButton('5', () => _onNumberPressed('5')),
            _CalcButton('6', () => _onNumberPressed('6')),
            _CalcButton('-', () => _onOperatorPressed('-'), type: _ButtonType.operator),
          ]),
          _buildButtonRow([
            _CalcButton('1', () => _onNumberPressed('1')),
            _CalcButton('2', () => _onNumberPressed('2')),
            _CalcButton('3', () => _onNumberPressed('3')),
            _CalcButton('+', () => _onOperatorPressed('+'), type: _ButtonType.operator),
          ]),
          _buildButtonRow([
            _CalcButton('Del', _onBackspacePressed),
            _CalcButton('0', () => _onNumberPressed('0')),
            _CalcButton('.', _onDecimalPressed),
            // Le bouton "=" a un appui long secret pour déclencher la caméra
            _CalcButton('=', _onEqualsPressed, type: _ButtonType.equals, isSecret: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<_CalcButton> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((btn) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _buildButton(btn),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(_CalcButton button) {
    Color bgColor;
    Color textColor;
    double fontSize;

    switch (button.type) {
      case _ButtonType.function:
        bgColor = const Color(0xFF505050);
        textColor = Colors.white;
        fontSize = 20;
        break;
      case _ButtonType.operator:
        bgColor = Colors.orange;
        textColor = Colors.white;
        fontSize = 26;
        break;
      case _ButtonType.equals:
        bgColor = Colors.orange;
        textColor = Colors.white;
        fontSize = 26;
        break;
      case _ButtonType.number:
      default:
        bgColor = const Color(0xFF333333);
        textColor = Colors.white;
        fontSize = 24;
        break;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: button.onPressed,
        // Appui long secret sur le bouton "="
        onLongPress: button.isSecret ? widget.onSecretTrigger : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white24,
        child: Center(
          child: Text(
            button.label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

enum _ButtonType { number, operator, function, equals }

class _CalcButton {
  final String label;
  final VoidCallback onPressed;
  final _ButtonType type;
  final bool isSecret;

  _CalcButton(this.label, this.onPressed, {this.type = _ButtonType.number, this.isSecret = false});
}
